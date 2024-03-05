--[[
	Contain all instances related to the player and character to be used throughout the experience
	This helps track instances to be deleted when the player encounters events like death, respawn, etc
]]

local CharacterContainer = {
	Name = "CharacterContainer",
}

function CharacterContainer:KnitInit() end

function CharacterContainer:KnitStart() end

return CharacterContainer
