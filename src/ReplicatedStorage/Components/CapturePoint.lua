--[[
	The localized version of capture points. events from here are sent to the terminal to be sent to captureserver
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)

local CapturePoint = Component.new({
	Tag = "CapturePoint",
	Ancestors = { game:GetService("Workspace").Studio.CapturePoints },
	Extensions = {},
})

function CapturePoint:Start()
	local ZoneSystem = Knit.GetController("ZoneSystem")
	local TerminalLayout = Knit.GetController("TerminalLayout")

	print(self.Instance, self.Instance.PointRadius)
	local zone = ZoneSystem.new({
		Part = self.Instance.PointRadius,
		Type = "Part",
	})

	zone.PlayerEntered:Connect(function()
		print("entered zone!")
		TerminalLayout.RegisterCaptureZone(true)
	end)

	zone.PlayerLeft:Connect(function()
		print("left zone!")
		TerminalLayout.RegisterCaptureZone(false)
	end)
end

return CapturePoint
