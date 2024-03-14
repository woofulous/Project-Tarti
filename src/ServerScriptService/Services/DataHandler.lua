--[[
    Player data is managed solely on the server, any passing data to the client is done on a case-by-case basis.
	The client should never have the full list of data.
]]

local SAVE_INCREMENT = 5 * 60
local DATA_TEMPLATE = {
	ProfileVersion = 1,
	Marks = 50,
	Uniform = {
		["EyeWear"] = {},
		["CuffTitle"] = {},
		["Hair"] = {},
		["Helmet"] = {},
		["Uniform"] = {},
		["Webbing"] = {},
	},
	Guns = {},

	FirstTimePlayer = true,
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Signal = require(ReplicatedStorage.Packages.Signal)
local safePlayerAdded = require(ReplicatedStorage.Utility.safePlayerAdded)

local experienceStore = game:GetService("DataStoreService"):GetDataStore("ExperienceData")

local isStudio = game:GetService("RunService"):IsStudio()

export type PlayerStore = { UserId: number, Data: {} }
export type GameData = { { PlayerStore } }

local DataHandler = {
	Name = "DataHandler",
	Client = {},
}
DataHandler.GameData = {} :: GameData
DataHandler.SaveReady = false
DataHandler._onSaveReady = Signal.new()

-- Returns a Promise to GetAsync of player's data
function GetPlayerData(player: Player)
	return Promise.new(function(resolve, reject)
		local success, playerStore = pcall(function()
			return experienceStore:GetAsync(player.UserId)
		end)

		if success then
			print("get resolved")
			resolve(playerStore)
		else
			print("get rejected")
			reject("Data does not exist!")
		end
	end)
end

-- Return a Promise which calls SetAsync on the player to save data
function SavePlayerData(player: Player)
	if isStudio then
		return warn("Tried to SavePlayerData, but cannot in Studio!")
	end

	local playerStore = DataHandler.GameData[player.UserId]

	if playerStore then
		return Promise.new(function(resolve, reject)
			local success, failure = pcall(function()
				experienceStore:SetAsync(player.UserId, playerStore.Data)
			end)

			if success then
				print("save resolved")
				resolve()
			else
				warn(failure)
				reject(failure)
			end
		end)
	else
		return warn("Data failed to save, either due to no player data or save not ready")
	end
end

-- client methods

function DataHandler.Client:Get(player: Player, scope: any)
	print(player, scope)
	if typeof(scope) ~= "string" or not DATA_TEMPLATE[scope] then
		error(player.UserId .. " tried to Get with incorrect arguments. Suspicious behavior")
	end

	return DataHandler:Get(player, scope)
end

-- Fetch the player's data, reconcile "out of line" data and add player to GameData to be used
function DataHandler.initializePlayerAsync(player: Player)
	assert(DataHandler.SaveReady, "Save not ready!")
	assert(not DataHandler.GameData[player.UserId], "PlayerData already loaded!")

	local playerStore = {} :: PlayerStore
	playerStore.UserId = player.UserId
	playerStore.Data = {} -- initiate as a blank table

	local hadToCorrectData = false
	GetPlayerData(player)
		:andThen(function(gotData: {})
			print("set data to:", gotData)
			if gotData == nil then
				print("PlayerData empty, setting to default")
				hadToCorrectData = true
				playerStore.Data = DATA_TEMPLATE
			else
				--[[Ensure PlayerData is correct]]
				if type(playerStore.Data) ~= "table" then
					warn("Unexpected data type retrieved from DataStore:", playerStore.Data)
					hadToCorrectData = true
					playerStore.Data = DATA_TEMPLATE
					return
				end

				for dataKey: string, _ in playerStore.Data do
					if not DATA_TEMPLATE[dataKey] then
						warn("Unexpected key in PlayerStore:", dataKey, "- removing unwanted data")
						hadToCorrectData = true
						playerStore.Data[dataKey] = nil
					end
				end
				print(playerStore.Data)
				for templateKey, templateValue: any in DATA_TEMPLATE do
					if not playerStore.Data[templateKey] then
						print("Filling PlayerStore data with DATA_TEMPLATE gap:", templateKey)
						hadToCorrectData = true
						playerStore.Data[templateKey] = templateValue
					end
				end
				--[[]]
			end
		end)
		:andThen(function()
			DataHandler.GameData[player.UserId] = playerStore
			print("Initialized PlayerStore for", player)

			if hadToCorrectData then
				print("Saving corrected data")
				SavePlayerData(player)
			end
		end)
		:catch(function(err)
			warn("Error in GetPlayerData: (" .. err .. ") Setting to default")
			playerStore.Data = DATA_TEMPLATE
		end)
end

-- Returns promise to save player's data
function DataHandler.promiseSaveData(player: Player)
	return SavePlayerData(player)
end

-- Save player data then remove them from GameData
function DataHandler.closePlayerData(player: Player)
	if not DataHandler.GameData[player.UserId] then
		return warn("Game data does not exist for", player.Name)
	end

	DataHandler.promiseSaveData(player):andThen(function()
		DataHandler.GameData[player.UserId] = nil
	end)
end

-- Return the player's data based on the scope. If no scope is specified, return the entire Data table.
function DataHandler:Get(player: Player, scope: string)
	assert(self.SaveReady, "Trying to :Get while not SaveReady")

	local playerData: PlayerStore = self.GameData[player.UserId].Data

	if playerData then
		if scope then
			return playerData[scope] or warn("Could not find PlayerData scope:", scope)
		end

		return playerData
	else
		warn("Could not Get PlayerData:", player)
	end -- if not, no data to get
end

--[[
	Based on the scope, use an updating function which passes the current data, in which new data is returned to be set. In essence, this is simply :Get then :Set
	Example use case:
	function(money: number)
		return money + 1
	end
	This function gets the current money of the player, then returns the current money plus 1, effectively updating the player's data
]]
function DataHandler:Update(player: Player, scope: string, returnFn: (oldValue: any) -> (newValue: any) -> ())
	assert(self.SaveReady, "Trying to :Update while not SaveReady")

	local currentStore = self:Get(player, scope)
	self.GameData[player.UserId].Data[scope] = returnFn(currentStore)

	return false -- failed to update
end

-- Directly Set the data to a new value. Different from update, there is no current data passed.
function DataHandler:Set(player: Player, scope: string, value: any?)
	assert(self.SaveReady, "Trying to :Set while not SaveReady")

	if self:Get(player, scope) then
		self.GameData[player.UserId].Data[scope] = value

		return true
	end
end

-- a promise which awaits until it has started
function DataHandler:WaitForSaveReady()
	if self.SaveReady then
		return
	else
		self._onSaveReady:Wait()
	end
end

function DataHandler:KnitInit()
	if isStudio then
		warn("DataHandler will not save in Studio. Session data will be lost.")
	else
		warn("DataHandler ready to start saving!")
	end

	local Players = game:GetService("Players")

	-- initialize players
	safePlayerAdded(self.initializePlayerAsync, self.closePlayerDataAsync)

	-- Start saving
	task.spawn(function()
		while self.SaveReady and task.wait(SAVE_INCREMENT) do
			for _, player in Players:GetPlayers() do
				task.defer(SavePlayerData, player)
			end
		end
	end)

	game:BindToClose(function()
		print("closing game, saving any remaining player data")
		for _, player in Players:GetPlayers() do
			SavePlayerData(player)
		end
	end)

	self._onSaveReady:Once(function()
		self.SaveReady = true
	end)

	self._onSaveReady:Fire()
end

return DataHandler
