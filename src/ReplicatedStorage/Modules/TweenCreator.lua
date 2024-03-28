--[[
	help create tweens faster by having functions premade for basic operations
	lucereus 03/17/2024
]]

local TweenService = game:GetService("TweenService")

local Promise = require(game:GetService("ReplicatedStorage").Packages.Promise)

local TweenCreator = {}
TweenCreator.ongoingTweens = {} -- categorize tweens based on the instance's name and values tweened. if the same instance is being tweened, then cancel. this prevents flickering

-- tween the object in a promise. resolves on completion
function TweenCreator.TweenTo(instance: any, goalInfo: TweenInfo, goal: {})
	local tweenCategoryPromise = TweenCreator[instance.Name]

	if tweenCategoryPromise then
		tweenCategoryPromise:cancel()
	end

	local resolveScriptConnection: RBXScriptConnection
	local tweenPromise = Promise.new(function(resolve, _, onCancel)
		local tween: Tween

		onCancel(function()
			tween:Cancel()
		end)

		tween = TweenService:Create(instance, goalInfo, goal)
		resolveScriptConnection = tween.Completed:Once(resolve)
		tween:Play()
	end)

	tweenPromise:finally(function()
		TweenCreator[instance.Name] = nil
		resolveScriptConnection:Disconnect()
	end)

	TweenCreator[instance.Name] = tweenPromise
	return tweenPromise
end

return TweenCreator
