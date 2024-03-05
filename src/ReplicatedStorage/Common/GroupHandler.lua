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

-- Returns a promise which calls GetGroupsAsync on the player
function GroupHandler:GetGroups(player: Player)
	local success, result = pcall(function()
		return GroupService:GetGroupsAsync(player.UserId)
	end)

	if not success then
		return warn(result)
	end

	return result
end

return GroupHandler
