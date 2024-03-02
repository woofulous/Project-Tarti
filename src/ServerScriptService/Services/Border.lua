--[[
	This is the middleware between the BorderBooth component and BorderHandler
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Border = {
	Name = "Border",
	Client = {},
}

function Border:Open() end

function Border:KnitInit() end

function Border:KnitStart() end

return Border
