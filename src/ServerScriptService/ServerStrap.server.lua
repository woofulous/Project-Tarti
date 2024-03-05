--[[
	Server boostrapper
	redone by woofulous (Lucereus) 03/04/2024
]]

local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

function SafeRequireModule(module: ModuleScript)
	local success, result = pcall(function()
		return require(module)
	end)
	assert(success, result)

	return result
end

for _, module in ServerScriptService.Services:GetDescendants() do
	if module:IsA("ModuleScript") then
		local service = SafeRequireModule(module)
		assert(service.Name, "Service must have 'Name'!")
		Knit.CreateService(service)
	end
end

Knit.Start({
	Middleware = {
		Inbound = {
			function(player: Player, args)
				print(player, "is passing args to server:", args)
				return true
			end,
		},
	},
})
	:catch(warn)
	:await()

-- Start components
for _, component in ServerScriptService.Components:GetDescendants() do
	if component:IsA("ModuleScript") then
		SafeRequireModule(component)
		print(component)
	end
end
