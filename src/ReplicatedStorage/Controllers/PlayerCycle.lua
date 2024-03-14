--[[
	The local player's "CoreLoop"
	Contain all instances related to the player and character to be used throughout the experience
	This helps track instances to be deleted when the player encounters events like death, respawn, etc
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerCycle = {
	Name = "PlayerCycle",
}

function PlayerCycle:KnitStart()
	local DataHandler = Knit.GetService("DataHandler")

	local isNewPlayer = DataHandler:Get("FirstTimePlayer") -- cannot refer to self, on client
	if isNewPlayer then
		print("player is new! cinematic starting")
		local IntroCinematic = Knit.GetController("IntroCinematic")
		IntroCinematic:PlayCinematic():await() -- returns promise
		print("cinematic over. all resolved. start menu")
	end

	local MenuScreen = Knit.GetController("MenuScreen")
	MenuScreen.startAsync()
end

return PlayerCycle
