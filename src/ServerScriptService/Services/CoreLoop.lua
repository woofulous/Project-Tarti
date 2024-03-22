--[[
	Handle all of the top-level game functionality
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local safePlayerAdded = require(ReplicatedStorage.Utility.safePlayerAdded)

local CoreLoop = {
	Name = "CoreLoop",
	Client = {
		PlayerAgreedToRules = Knit.CreateSignal(),
		LoadCharacter = Knit.CreateSignal(),
	},
}

local function playerAdded(player: Player)
	print(player, "has been added!")
end

local function playerRemoving(player: Player)
	print(player, "is being removed!")
end

function CoreLoop:KnitStart()
	local DataHandler = Knit.GetService("DataHandler")

	self.Client.PlayerAgreedToRules:Connect(function(player: Player)
		DataHandler:Set(player, "AgreedToRules", true)
	end)

	self.Client.LoadCharacter:Connect(function(player: Player)
		-- TODO* some checks like ensuring the player hasn't exceeding a certain call threshold, etc
		player:LoadCharacter()
	end)

	safePlayerAdded(playerAdded, playerRemoving)
end

return CoreLoop
