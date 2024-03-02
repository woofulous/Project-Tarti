--[[
	Client boostrapper
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

function SafeAddController(controller: ModuleScript)
	local success, result = pcall(function()
		return require(controller)
	end)
	assert(success, result)

	Knit.CreateController(result)
end

for _, module in ReplicatedStorage.Controllers:GetDescendants() do
	if module:IsA("ModuleScript") then
		SafeAddController(module)
	end
end

Knit.Start():catch(warn):await()
