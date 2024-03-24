--[[
	help create tweens faster by having functions premade for basic operations
	lucereus 03/17/2024
]]

local TweenService = game:GetService("TweenService")

local Promise = require(game:GetService("ReplicatedStorage").Packages.Promise)

local TweenCreator = {}

-- tween the object in a promise. resolves on completion
function TweenCreator.TweenTo(instance: Instance, goalInfo: TweenInfo, goal: {})
	return Promise.new(function(resolve, _, onCancel)
		local resolveScriptConnection: RBXScriptConnection
		local tween: Tween

		onCancel(function()
			resolveScriptConnection:Disconnect()
			tween:Cancel()
		end)

		tween = TweenService:Create(instance, goalInfo, goal)
		resolveScriptConnection = tween.Completed:Once(resolve)
		tween:Play()
	end)
end

return TweenCreator
