--[[
    Manage all of the many, many group-related instances of the game via this ModuleScript
	redone by woofulous (Lucereus) 03/04/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")

local Promise = require(ReplicatedStorage.Packages.Promise)

local GroupHandler = {
	Name = "GroupHandler",
	Client = {},
}

-- If player is in Teutonnia group and on defenders team, return true
function GroupHandler.isDefender(player: Player) end

-- Uses promise which calls GetGroupsAsync on the player
function GroupHandler:GetGroupsAsync(player: Player)
	local worked, groupResult = Promise.try(function()
		return GroupService:GetGroupsAsync(player.UserId)
	end):await()

	if not worked then
		error(groupResult)
	end

	return groupResult
end

return GroupHandler
