--[[
	Dictate if players are in or out of zones like capture points and ambient audio zones
	manifested by AugustusArrius  03/24/2024. audited then rewritten by Lucereus 03/25/2024
	the code augustusarrius wrote was great, and it inspired me make this :)
	this module uses promise for the entered events since it has built in functions and cleanup methods to ensure all is wrapped neatly
]]

export type ZoneType = "Sphere" | "Box" | "Part"
export type ZoneInfo = {
	Part: BasePart,
	ZoneType: ZoneType,
	Radius: number?,
}

local Promise = require(game:GetService("ReplicatedStorage").Packages.Promise)

local ZoneSystem = {}
ZoneSystem.zones = {} -- a table of all the zones
ZoneSystem.started = false

-- create a new class
local Zone = { __index = {} }

-- pass the character to the given function to be used via promise
function Zone:PromisePlayerEntered(fn: (character: Model) -> ()) --: promise
	return Promise.new(function(resolve, reject, onCancel) end)
end

-- use the class we just made
function ZoneSystem.new(zoneInfo: ZoneInfo)
	local self = {}
	setmetatable(self, Zone)

	self.Part = zoneInfo.Part
	self.Type = zoneInfo.ZoneType

	if zoneInfo.ZoneType ~= "Part" then
		self.Radius = zoneInfo.Radius
	end

	return self
end

return ZoneSystem
