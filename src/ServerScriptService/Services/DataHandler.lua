--[[
    Player data is managed solely on the server, any passing data to the client is done on a case-by-case basis.
	The client should never have the full list of data.
]]

local SAVE_INCREMENT = 5 * 60
local DATA_TEMPLATE = {
	ProfileVersion = 1,
	Marks = 50,
	Uniform = {
		["Accessories"] = {},
		["Cufftitles"] = {},
		["Hair"] = {},
		["Helmet"] = {},
		["Uniform"] = {},
		["Webbing"] = {},
	},
	Guns = {},

	Settings = {
		Group = 15294045,
		LocalNametag = true,
		KillFeed = true,
	},
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local safePlayerAdded = require(ReplicatedStorage.Utility.safePlayerAdded)

local experienceStore = game:GetService("DataStoreService"):GetDataStore("ExperienceData")

export type PlayerStore = { UserId: number, Data: {} }
export type GameData = { { PlayerStore } }

local DataHandler = {
	Name = "DataHandler",
	Client = {},
}
DataHandler.GameData = {} :: GameData
DataHandler.SaveReady = false

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

-- Fetch the player's data, reconcile "out of line" data and add player to GameData to be used
function DataHandler.initializePlayerAsync(player: Player)
	assert(DataHandler.SaveReady, "Save not ready!")
	assert(not DataHandler.GameData[player.UserId], "PlayerData already loaded!")

	local playerStore = {} :: PlayerStore
	playerStore.UserId = player.UserId
	playerStore.Data = {} -- initiate as a blank table

	GetPlayerData(player):andThen(function(gotData: {})
		print("set data to:", gotData)
		playerStore.Data = gotData
	end):catch(function(err)
		warn("Error in GetPlayerData: (", err, ") Setting to default")
		playerStore.Data = DATA_TEMPLATE
	end)

	if #playerStore.Data == 0 then
		print("PlayerData empty, setting to default")
		playerStore.Data = DATA_TEMPLATE
	end

	--[[Ensure PlayerData is correct]]
	local hadToCorrectData = false
	if type(playerStore.Data) ~= "table" then
		warn("Unexpected data type retrieved from DataStore:", playerStore.Data)
		hadToCorrectData = true
		playerStore.Data = DATA_TEMPLATE
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

	DataHandler.GameData[player.UserId] = playerStore
	print("Initialized PlayerStore for", player)

	if hadToCorrectData then
		print("Saving corrected data")
		SavePlayerData(player)
	end
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

	SavePlayerData(player)

	DataHandler.GameData[player.UserId] = nil
end

-- Return the player's data based on the scope. If no scope is specified, return the entire Data table.
function DataHandler:Get(player: Player, scope: string)
	assert(self.SaveReady, "Trying to :Get while not SaveReady")

	local playerStore: PlayerStore = self.GameData[player.UserId]
	do
		if scope then
			return playerStore.Data[scope] or warn("Could not find PlayerData scope:", scope)
		end

		return playerStore.Data
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
	do
		self.GameData[player.UserId].Data[scope] = returnFn(currentStore)
	end

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

function DataHandler:KnitInit()
	local Players = game:GetService("Players")

	-- initialize players
	safePlayerAdded(self.initializePlayerAsync, self.closePlayerDataAsync)

	-- Start saving
	self.SaveReady = true
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
end

return DataHandler