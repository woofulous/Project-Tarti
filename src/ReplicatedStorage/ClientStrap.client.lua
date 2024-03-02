--[[
	Client boostrapper
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

function SafeRequireModule(module: ModuleScript)
	local success, result = pcall(function()
		return require(module)
	end)
	assert(success, result)

	return result
end

for _, module in ReplicatedStorage.Controllers:GetDescendants() do
	if module:IsA("ModuleScript") then
		local controller = SafeRequireModule(module)
		Knit.CreateController(controller)
	end
end

Knit.Start():catch(warn):await()

-- Start components
for _, component in ReplicatedStorage.Components:GetDescendants() do
	if component:IsA("ModuleScript") then
		SafeRequireModule(component)
		print(component)
	end
end
