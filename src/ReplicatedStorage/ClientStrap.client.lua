--[[
	Client boostrapper
	recreated by woofulous (Lucereus) on 03/04/2024
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

for _, module in ReplicatedStorage.Controllers:GetChildren() do
	if module:IsA("ModuleScript") then
		local controller = SafeRequireModule(module)
		Knit.CreateController(controller)
	end
end

-- pass .root from Interface to UI modules, and create them as controllers. we pass them in the "init stage" after all the other modules have been invoked. UI should run completely independent of other UI. use the Interface module to bridge this gap.
local Interface = Knit.GetController("Interface")

for _, uiModule in ReplicatedStorage.Controllers.Interface:GetChildren() do
	if uiModule:IsA("ModuleScript") then
		local uiController = SafeRequireModule(uiModule)
		assert(
			uiController.instance,
			uiController.Name .. " must include a .instance property with the UI frame which it is using"
		) -- if you get this error, its because you need to assign .instance inside of the module. set it to the DialogFrame, CustomGui frame, or whatever else you may be using

		uiController.root = Interface.root
		Interface.FrameInstances[uiController.Name] = uiController.instance
		Knit.CreateController(uiController)
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
