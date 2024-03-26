--[[
	Dictate if players are in or out of zones like capture points and ambient audio zones
	manifested by AugustusArrius  03/24/2024. audited then rewritten by Lucereus 03/25/2024
	the code augustusarrius wrote was great, and it inspired me make this :)
	this module uses promise for the entered events since it has built in functions and cleanup methods to ensure all is wrapped neatly
]]

local MIN_DISTANCE_MAGNITUDE = 150 -- how close the player has to be in .Magnitude to query
local CHECK_COOLDOWN = 0.5 -- in seconds, plus the total time it took to do all operations. this time is varied from the cooldown and will likely be numerically larger in runtime. only goes thru if deltaTime less than threshold
local DELTA_THRESHOLD = 0.015 -- this is the maximum the deltatime (time it took to render the frame) that the operations will run at, ontop of the check cooldown. higher means it will fire more often
local RUNSERVICE_NAME = "ZoneSystem_RenderStep"

export type ZoneType = "Sphere" | "Part" -- sphere = BoundsInRadius, part = BoundsInPart (wheres box? use part instead... save us the trouble)
export type ZoneInfo = {
	Type: ZoneType,
	Position: Vector3?,
	Part: BasePart?,
	Radius: number?,
}
export type RuntimeZone = {
	IsInZone: boolean, -- dictates if the player is currently in the zone. this also ensures that the signal isnt constantly firing if IsInZone is already true x3
	Position: Vector3,
	Type: ZoneType,
	Part: BasePart,
	Radius: number?,
	Connections: { entered: any, left: any }, -- two signals
}

local RunService = game:GetService("RunService") -- we use runservice to go through all of the zones and then tell if the player is in the zone or not
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local zones = {} :: { RuntimeZone } -- a table of all the zones

local overlapParams = OverlapParams.new()
overlapParams.FilterDescendantsInstances = {}
overlapParams.FilterType = Enum.RaycastFilterType.Include
overlapParams.MaxParts = 1 -- only 1, the root part :)
overlapParams.RespectCanCollide = false

local ZoneSystem = {
	Name = "ZoneSystem",
}

-- we check player's existence in the zone itself and also for the characters distance relative to the point
function UpdateZone(zone: RuntimeZone, playerDistance: number)
	if zone.Type == "Sphere" then -- we can check this with magnitude to save us the trouble
		zone.IsInZone = playerDistance <= zone.Radius or false
	elseif zone.Type == "Part" then
		local partsInBounds = workspace:GetPartBoundsInBox(zone.Part.CFrame, zone.Part.Size, overlapParams)

		zone.IsInZone = #partsInBounds > 0 or false
	end
end

function CheckAllZonesAsync(playerPosition: Vector3)
	for _, runtimeZone in zones do -- dw, if there are no zones this will return
		local playerDistance = (playerPosition - runtimeZone.Position).Magnitude

		if playerDistance > MIN_DISTANCE_MAGNITUDE then
			continue
		end

		local previousInZone = runtimeZone.IsInZone
		task.spawn(UpdateZone, runtimeZone, playerDistance)

		if runtimeZone.IsInZone ~= previousInZone then -- if not in zone, but was in zone before
			if not runtimeZone.IsInZone then
				runtimeZone.Connections.left:Fire()
			else
				runtimeZone.Connections.entered:Fire()
			end
		end
	end
end

-- create a new class
local Zone = { __index = {} }

-- use the class we just made
function ZoneSystem.new(zoneInfo: ZoneInfo)
	local self = {}
	setmetatable(self, Zone)
	local zoneTable = {} -- all of the recurring values

	if zoneInfo.Part then
		zoneTable.Position = zoneInfo.Part.Position
		zoneTable.Part = zoneInfo.Part
	else
		zoneTable.Position = zoneInfo.Position
		zoneTable.Radius = zoneInfo.Radius
	end

	self.PlayerEntered = Signal.new()
	self.PlayerLeft = Signal.new()

	zoneTable.IsInZone = false
	zoneTable.Type = zoneInfo.Type
	zoneTable.Connections = {
		entered = self.PlayerEntered,
		left = self.PlayerLeft,
	}

	table.insert(zones, zoneTable) -- construct runtimezone
	return self
end

-- if the player is in any zone at all. we use this with ambientzones to tell if the player went over to a new zone, or if they're not in any.
function ZoneSystem.IsInAnyZone(): boolean
	for _, runtimeZone in zones do
		if runtimeZone.IsInZone then
			return true
		end
	end

	return false
end

function ZoneSystem.UnbindFromRender()
	overlapParams.FilterDescendantsInstances = {} -- clear any possibility to cast more
	RunService:UnbindFromRenderStep(RUNSERVICE_NAME)
	-- loop thru and any zones the player was in, let them know they're no longer (cuz they ded)
	for _, runtimeZone in zones do
		if runtimeZone.IsInZone then
			runtimeZone.left:Fire()
		end
	end
end

-- we pass the root part cause we're gonna use this in the spatial query whitelist
function ZoneSystem.StartRenderStep(humanoidRootPart: BasePart)
	overlapParams:AddToFilter(humanoidRootPart) -- actually add the plr to the cycle
	local nextCheck = 0 -- we take this plus the elapsed time plus our value of accuracy to then add inside of the connection to decide if we should run it again. stealing off zone+'s heartbeat method B) :3 :p
	-- we want to use render step because it will actually throttle if the game is lagging for the client.
	RunService:BindToRenderStep(RUNSERVICE_NAME, Enum.RenderPriority.Last.Value, function(deltaTime)
		local clockTime = os.clock() -- because all the following operations will be async, we dont want a diff time

		if clockTime >= nextCheck and deltaTime < DELTA_THRESHOLD then -- we measure delta time as another way to cut down on the amount of operations we're doing. its silly, but really im trying to make this as least impactful.
			CheckAllZonesAsync(humanoidRootPart.Position)

			nextCheck = clockTime + CHECK_COOLDOWN
		end
	end)
end

return ZoneSystem
