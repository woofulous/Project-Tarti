--[[
	The local player's "CoreLoop"
	Contain all instances related to the player and character to be used throughout the experience
	This helps track instances to be deleted when the player encounters events like death, respawn, etc
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Studio = game:GetService("Workspace").Studio

local PlayerCycle = {
	Name = "PlayerCycle",
}

function PlayerCycle:KnitStart()
	local DataHandler = Knit.GetService("DataHandler")

	local isNewPlayer = DataHandler:Get("FirstTimePlayer") -- cannot refer to self, on client
	if isNewPlayer then
		local IntroCinematic = Knit.GetController("IntroCinematic")
		local IntroCamera = Studio.Cinematics:WaitForChild("IntroCamera")

		print("player is new! cinematic starting")
		IntroCinematic:PlayCinematic(IntroCamera):await() -- returns promise
		print("cinematic over. all resolved. start menu")
	end

	local MenuScreen = Knit.GetController("MenuScreen")
	MenuScreen:ToggleVisible(true)
	MenuScreen.startCameraPanningPromise():finally(function()
		MenuScreen:ToggleVisible(false)
	end)
end

return PlayerCycle
