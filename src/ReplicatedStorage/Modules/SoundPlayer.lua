--[[
	Play randomized tracks, transition music audio, and help with ambient sounds
	Lucereus 03/24/2024
]]

local SoundService = game:GetService("SoundService")

local randomSpeed = Random.new()

local SoundPlayer = {}

function GetRandomSound(tbl: {}): Sound
	return tbl[math.random(1, #tbl)]
end

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

return SoundPlayer
