--[[
	This controller handles the tweening of border-related Components. For the signalling behind these events, look to ServerScriptService.Components.BorderBooth
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Border = {
	Name = "Border",
	Client = {}
}

function Border:KnitInit()
	
end

function Border:KnitStart()
	local Border
end

return Border
