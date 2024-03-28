--[[
	When a player is in certain zones, tween the lighting and set new audio themes for immersion
	this has been a dream of mine for a long, long time. since alemannia. im so glad that its a possibility :`3 - Lucereus (woofulous) 03/25/2024
]]

local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)

local TweenCreator = require(ReplicatedStorage.Modules.TweenCreator)
local SoundPlayer = require(ReplicatedStorage.Modules.SoundPlayer)

local occupiedZones = 0 -- used to ensure that if a player crosses into another zone, the left doesnt reset lighting
local TransitionInfo = TweenInfo.new() -- the info passed when entering/leaving ambient zones
local defaultLightingValues = {
	Ambient = Lighting.Ambient,
	ColorShift_Top = Lighting.ColorShift_Top,
	ExposureCompensation = Lighting.ExposureCompensation,
}

local AmbientZone = Component.new({
	Tag = "AmbientZone",
	Ancestors = { game:GetService("Workspace").Studio.AmbientZones },
	Extensions = {},
})

function AmbientZone:Start()
	local configuration = self.Instance:FindFirstChildOfClass("Configuration")

	local music_theme = configuration:GetAttribute("MusicTheme")
	if music_theme == "" then
		music_theme = nil -- because string attributes are naturally ""
	end

	local configValues = {
		Ambient = configuration:GetAttribute("Ambience"),
		ColorShift_Top = configuration:GetAttribute("Color"),
		ExposureCompensation = configuration:GetAttribute("Exposure"),
	}

	local ZoneSystem = Knit.GetController("ZoneSystem")
	local zone = ZoneSystem.new({
		Part = self.Instance,
		Type = "Part",
	})

	zone.PlayerEntered:Connect(function()
		print(occupiedZones)
		occupiedZones += 1

		TweenCreator.TweenTo(Lighting, TransitionInfo, configValues)
		task.defer(SoundPlayer.TransitionMusicTheme, music_theme)
	end)

	zone.PlayerLeft:Connect(function()
		print(occupiedZones)
		occupiedZones -= 1

		if occupiedZones <= 0 then
			TweenCreator.TweenTo(Lighting, TransitionInfo, defaultLightingValues)
			task.defer(SoundPlayer.TransitionMusicTheme, SoundPlayer.DefaultTheme)
		end
	end)
end

return AmbientZone
