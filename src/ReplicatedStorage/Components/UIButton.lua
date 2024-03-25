--[[
	This component applies button sounds to any text or image button with the given tag
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SoundPlayer = require(ReplicatedStorage.Modules.SoundPlayer)
local Component = require(ReplicatedStorage.Packages.Component)

local UIButton = Component.new({
	Tag = "UIButton",
	Ancestors = { game:GetService("Players").LocalPlayer.PlayerGui },
	Extensions = {},
})

function UIButton:Start()
	self.Instance.MouseButton1Up:Connect(function()
		SoundPlayer.PlayRandomSound("Interface", "ButtonRelease")
	end)

	self.Instance.MouseButton1Down:Connect(function()
		SoundPlayer.PlayRandomSound("Interface", "ButtonDown")
	end)

	self.Instance.MouseEnter:Connect(function()
		SoundPlayer.PlayRandomSound("Interface", "ButtonHover")
	end)

	self.Instance.MouseLeave:Connect(function()
		SoundPlayer.PlayRandomSound("Interface", "ButtonLeave")
	end)
end

return UIButton
