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

-- Fade the visibility of the instance based on the true | false given. Returns a Promise which is tied to the tween's completion. zindexoverride only applies if youre setting visibility to true
function TransitionFade:TweenVisible(visible: true | false, zindexOverride: number?) -- we need to set a new zindex just incase we want the fade to go over preexisting ui's. for instance, the overhead spawner
	CancelCurrentTween()

	if visible then
		if zindexOverride then
			self.instance.ZIndex = zindexOverride
		end

		self.instance.Parent = self.root -- root is passed when Interface is setup. check ClientStrap if you're interested as to how this is passed
		fadePromiseTween = TweenCreator.TweenTo(self.instance, FadeInfo, { BackgroundTransparency = 0 })
	else
		fadePromiseTween = TweenCreator.TweenTo(self.instance, FadeInfo, { BackgroundTransparency = 1 })
		fadePromiseTween:finally(function() -- if canceled or tween completed, parent to script
			self.instance.Parent = script
			self.instance.ZIndex = -1
			fadePromiseTween = nil
		end)
	end

	return fadePromiseTween
end

return TransitionFade
