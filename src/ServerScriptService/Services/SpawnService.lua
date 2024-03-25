--[[
	Manage the spawning on points for players. This handles the SpawnPoint and CapturePoint randomized spawning.
	Lucereus 03/24/2024
]]

local Promise = require(game:GetService("ReplicatedStorage").Packages.Promise)

local SpawnFolder = game:GetService("Workspace").Studio["SpawnPoints"] -- this errors if you directly path? idk why. its server. should already be loaded /shrug

export type SpawnPoint = Model & { -- a model which contains this \/
	SpawnParts: Model & { Model & { BasePart } }, -- a model of models with baseparts
}

local SpawnService = {
	Name = "SpawnService",
	Client = {},
}
SpawnService.Points = {} :: { SpawnPoint } -- this encompasses both capture and spawn points. spawns are different from capture points, because they are completely independent and cannot be captured.

-- the player's character. promises are synchronous. so they're pushed to a new thread, with no yielding :)
function PromisePlayerCharacter(player: Player) --: promiseobject
	return Promise.new(function(resolve)
		player.CharacterAppearanceLoaded:Once(resolve) -- appearanceloaded passes character thru >:3 we yield the promise until the char is ready until the character is fully loaded, we pass it through resolve
		player:LoadCharacter() -- this readies for the appearanceloaded event
	end)
end

function GetRandomKeyFromIndex(tbl: {}): any
	return tbl[math.random(1, #tbl)]
end

function SpawnService:NewPoint(spawnPoint: SpawnPoint) -- we methodize this function because of the possibility that we want to have capture points which spawn out of nowhere. like mayb we have a temporary "capture the point!" thing
	self.Points[spawnPoint.Name] = spawnPoint -- this includes the point and all of the spawnparts for it.
end

function SpawnService.Client:RequestSpawnAtPoint(player: Player, desired_point_name: string)
	local spawnPoint = SpawnService.Points[desired_point_name]
	assert(spawnPoint, "Point does not exist:" .. desired_point_name)

	if not player.Character then
		PromisePlayerCharacter(player):andThen(function(character: Model)
			print(character)
			local randomSpawnPoint: BasePart = GetRandomKeyFromIndex(spawnPoint.SpawnParts:GetChildren())
			character:PivotTo(randomSpawnPoint.CFrame) -- set the cframe of the primary part
		end)
	else
		warn("trying to request spawn at point but the character exists. it needs to be deleted first")
	end
end

function SpawnService:KnitInit()
	-- setup all the default points. we setup the default capture points externally in captureserver, which runs in knitstart to call "newpoint" on each new point. see the "Studio" folder as default values.
	for _, spawnPoint in SpawnFolder:GetChildren() do
		self:NewPoint(spawnPoint)
	end
end

return SpawnService
