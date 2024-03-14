--[[
	Show a skippable cinematic cutscene for the player using CameraHandler
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local CameraMover = require(ReplicatedStorage.Modules.CameraMover)

local CinematicCamera = game:GetService("Workspace").Studio:WaitForChild("CinematicCamera")
local cameraInfo = TweenInfo.new(10)

local IntroCinematic = {
	Name = "IntroCinematic",
}
IntroCinematic.instance = script.CinematicBars
IntroCinematic.playing = false

function IntroCinematic:PlayCinematic()
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

	self.playing = true
	self.instance.Parent = self.root -- root is passed after interface is invoked

	local currentIndex = 0 -- we start from zero because we are adding 1 later on
	local currentTween: Tween
	local cinematicFolderGroups = CinematicCamera:GetChildren()
	print(cinematicFolderGroups)
	while self.playing do -- while we are playing and the cinematic still has places to tween to
		currentIndex += 1
		if currentIndex > #cinematicFolderGroups then
			break
		end

		print(currentIndex, "playing!")
		local cameraGroup = cinematicFolderGroups[currentIndex]
		print(cameraGroup)

		CameraMover.CFrameCameraToPart(cameraGroup.Start, true, 3) -- streams around start
		currentTween = CameraMover.TweenCameraToPart(cameraGroup.End, cameraInfo, true, 3) -- yields to stream around .end | we can put a faded screen here, then on the next line unfade it since it has loaded and is playing
		currentTween.Completed:Wait() -- yield until the tween has completed
	end

	-- they've skipped the cinematic, or theres no more to play.
	if currentTween then
		currentTween:Cancel()
	end

	print("Stopped cinematic")
end

return IntroCinematic
