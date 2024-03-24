--[[
	Handle the transitioning elements of the black fade which is used when panning through camera sequences, entering new menus, etc
	as always, Lucereus 03/22/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TweenCreator = require(ReplicatedStorage.Modules.TweenCreator)

local FadeInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadePromiseTween: any --: promiseobject

local TransitionFade = {
	Name = "TransitionFade",
}
TransitionFade.instance = script.Transition

function CancelCurrentTween()
	if fadePromiseTween then
		fadePromiseTween:cancel()
		fadePromiseTween = nil
	end
end

-- Fade the visibility of the instance based on the true | false given. Returns a Promise which is tied to the tween's completion
function TransitionFade:TweenVisible(visible: true | false)
	CancelCurrentTween()

	if visible then
		self.instance.Parent = self.root -- root is passed when Interface is setup. check ClientStrap if you're interested as to how this is passed
		fadePromiseTween = TweenCreator.TweenTo(self.instance, FadeInfo, { BackgroundTransparency = 0 })
	else
		fadePromiseTween = TweenCreator.TweenTo(self.instance, FadeInfo, { BackgroundTransparency = 1 })
		fadePromiseTween:finally(function() -- if canceled or tween completed, parent to script
			self.instance.Parent = script
			fadePromiseTween = nil
		end)
	end

	return fadePromiseTween
end

return TransitionFade
