local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)

local BorderBooth = Component.new({
	Tag = "BorderBooth",
	Ancestors = { game:GetService("Workspace").Studio },
})

function BorderBooth:Construct()
	print("Booth constructed")
end

function BorderBooth:Start()
	print("Booth started")
end

function BorderBooth:Stop()
	print("Booth stopped")
end

return BorderBooth
