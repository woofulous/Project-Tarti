--[[
	This is the player's HUD (Head-up Display) which governs visible recreation of properties related to the character's humanoid, like health, stamina, etcetera.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local TweenCreator = require(ReplicatedStorage.Modules.TweenCreator)

local TransitionInfo = TweenInfo.new(0.25)
local inCaptureZone = false -- we use this to decide if the TweenVisible should make the CapturingGroup visible or not

local TerminalLayout = {
	Name = "TerminalLayout",
}
TerminalLayout.instance = script.TerminalBar

function TerminalLayout:UpdateCaptureGroup()
	if inCaptureZone then
		TweenCreator.TweenTo(self.instance.CapturingGroup, TransitionInfo, { GroupTransparency = 0 })
		return TweenCreator.TweenTo(self.instance.PointGroup, TransitionInfo, { GroupTransparency = 1 })
	else
		TweenCreator.TweenTo(self.instance.PointGroup, TransitionInfo, { GroupTransparency = 0 })
		return TweenCreator.TweenTo(self.instance.CapturingGroup, TransitionInfo, { GroupTransparency = 1 })
	end
end

local tweenPromise --: promise
function TerminalLayout:TweenVisible(visible: true | false)
	if tweenPromise then
		tweenPromise:cancel()
	end

	tweenPromise = self:UpdateCaptureGroup()

	if visible then
		self.instance.Parent = self.root
	else
		tweenPromise:finally(function()
			self.instance.Parent = script
		end)
	end
end

function TerminalLayout.RegisterCaptureZone(isInside: true | false)
	inCaptureZone = isInside
	TerminalLayout:UpdateCaptureGroup()
end

function TerminalLayout:KnitStart()
	local CaptureServer = Knit.GetService("CaptureServer")

	-- update the "point of contention"
end

return TerminalLayout
