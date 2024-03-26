--[[
	Play randomized tracks, transition music audio, and help with ambient sounds
	Lucereus 03/24/2024
]]

local SoundService = game:GetService("SoundService")

local TweenCreator = require(game:GetService("ReplicatedStorage").Modules.TweenCreator)

local SoundPlayer = {}
SoundPlayer.DefaultTheme = "Ambient"

function GetRandomSound(tbl: {}): Sound
	return tbl[math.random(1, #tbl)]
end

local randomSpeed = Random.new()
function SoundPlayer.PlayRandomSound(group: string, sound_name: string)
	local SoundGroup = SoundService:FindFirstChild(group)

	if SoundGroup then
		local soundOrGroup = SoundGroup:FindFirstChild(sound_name)

		if soundOrGroup:IsA("SoundGroup") then
			soundOrGroup = GetRandomSound(soundOrGroup:GetChildren())
			soundOrGroup.PlaybackSpeed = randomSpeed:NextNumber(0.75, 1.25) -- this adds even more randomness, ontop of the random sounds
		end

		soundOrGroup:Play()
	else
		warn("SoundGroup doesnt exist:", group)
	end
end

local playingMusic: Sound
local musicLoopedConnection: RBXScriptConnection
local MusicInfo = TweenInfo.new(1)
-- pass nil if you want to fade out the music
function SoundPlayer.TransitionMusicTheme(new_theme: string | nil, target_volume: number?)
	if musicLoopedConnection then
		musicLoopedConnection:Disconnect()
	end

	if playingMusic then
		local previousMusic = playingMusic

		TweenCreator.TweenTo(previousMusic, MusicInfo, { Volume = 0 }):finally(function()
			previousMusic:Pause()
		end)
	end

	if new_theme then
		local musicGroupSounds = SoundService.Music[new_theme]:GetChildren() -- so we're not calling it so much

		playingMusic = GetRandomSound(musicGroupSounds)
		local defaultSoundVolume = playingMusic.Volume
		playingMusic.Volume = 0
		playingMusic:Resume()

		TweenCreator.TweenTo(playingMusic, MusicInfo, { Volume = target_volume or 0.5 })

		musicLoopedConnection = playingMusic.Ended:Once(function()
			SoundPlayer.TransitionMusicTheme(new_theme, defaultSoundVolume) -- an infinite loop
		end)
	end
end

return SoundPlayer
