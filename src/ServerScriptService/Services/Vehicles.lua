--[[
    This is the server-side aspect of Vehicle cloning and positioning.
    DepotChecker ensures the player can spawn the correct cars.
    BEFORE USE; Make sure there is a CollisionGroup named based on the COLLISION_GROUP variable!
    Otherwise, listenForEvents will set it up for you (this is at cost of performance)
]]

export type Vehicle = Model & { DriverSeat: VehicleSeat }

local COLLISION_GROUP = "Vehicle_CollisionGroup"

local Workspace = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")

local VehicleFolder = game:GetService("ServerStorage").Instances.Vehicles :: { Vehicle }

local runtimeFolder = Instance.new("Folder")
runtimeFolder.Name = "_runtimeVehicles"
runtimeFolder.Parent = Workspace

local padParameters = OverlapParams.new()
padParameters.FilterType = Enum.RaycastFilterType.Include
padParameters.CollisionGroup = COLLISION_GROUP
padParameters.MaxParts = 1

local Vehicles = {
	Name = "Vehicles",
	Client = {},
	ActiveVehicles = {} :: { [number]: Vehicle }, -- [UserId] returns Vehicle
}

-- Get the closest possible spawnpad in the list
local function getSpawnPad(spawnPadFolder: Folder)
	local spawnPad: Part

	for _, pad: Instance in spawnPadFolder:GetChildren() do
		if not pad:IsA("Part") then
			continue
		end

		padParameters.FilterDescendantsInstances = runtimeFolder:GetChildren() -- update all of the vehicles to ignore
		if #Workspace:GetPartsInPart(pad, padParameters) > 0 then -- returns {table} of parts in the pad
			continue
		else
			spawnPad = pad
			break
		end
	end

	return spawnPad
end

-- Return a list of all the vehicles the player can use based on their team & Constants.VehiclePermissions
local function getPlayerVehicles(player: Player)
	return { "Car" }
end

-- Destroy the player's vehicle
function CleanPlayerVehicle(player: Player)
	local vehicle = Vehicles.ActiveVehicles[player.UserId]

	if vehicle then
		vehicle:Destroy()
		print("Destroyed player vehicle")
	end
end

-- Spawn the vehicle on a random pad located in spawnPadFolder
function Vehicles:SpawnCar(player: Player, vehicle_name: string, spawnPadFolder: Folder)
	local spawnPad = getSpawnPad(spawnPadFolder)

	if spawnPad then
		local vehicle = self:CreateVehicle(vehicle_name, player)

		vehicle:PivotTo(spawnPad.CFrame) -- instead of MoveTo (which does not change orientation based on SpawnPad)
		print("Moved vehicle to SpawnPad!", spawnPad)
	else
		print("Cannot find SpawnPad, all pads obstructed, or none to choose from")
	end
end

-- Create a game-ready vehicle and return it
function Vehicles:CreateVehicle(vehicle_name: string, tiedPlayer: Player)
	assert(
		VehicleFolder[vehicle_name],
		"Trying to CreateVehicle for a vehicle which does not exist, name: " .. vehicle_name
	)

	CleanPlayerVehicle(tiedPlayer)
	local vehicle = VehicleFolder[vehicle_name]:Clone() :: Vehicle
	vehicle.Parent = runtimeFolder

	self.ActiveVehicles[tiedPlayer.UserId] = vehicle
	return vehicle
end

-- Loops through and destroys all vehicles
function Vehicles:CleanAllVehicles()
	for _, vehicle: Vehicle in self.ActiveVehicles do
		vehicle:Destroy()
	end
end

-- Connect creation events and make sure there is a CollisionGroup for the vehicles, and apply the CollisionGroup to all of the cars in storage
function Vehicles:KnitInit()
	if not PhysicsService:IsCollisionGroupRegistered(COLLISION_GROUP) then
		PhysicsService:RegisterCollisionGroup(COLLISION_GROUP)
	end

	for _, storedVehicle in VehicleFolder:GetChildren() do
		for _, part: BasePart in storedVehicle:GetDescendants() do
			if part:IsA("BasePart") then
				part.CollisionGroup = COLLISION_GROUP
			end
		end
	end
end

-- Client methods
function Vehicles.Client:FetchVehicle(player: Player)
	return getPlayerVehicles(player)
end

function Vehicles.Client:SpawnVehicle(player: Player, desired_vehicle: string, spawnPadFolder: Folder)
	if getPlayerVehicles(player)[desired_vehicle] then
		self:SpawnVehicle(player, desired_vehicle, spawnPadFolder)
	end
end

return Vehicles
