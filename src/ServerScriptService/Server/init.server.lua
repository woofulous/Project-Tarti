--[[
	Server boostrapper
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local ServiceFolder = game:GetService("ServerScriptService").Services

function SafeAddService(service: ModuleScript)
	local success, result = pcall(function()
		return require(service)
	end)
	assert(success, result)

	Knit.CreateService(result)
end

for _, module in ServiceFolder:GetDescendants() do
	if module:IsA("ModuleScript") then
		SafeAddService(module)
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
