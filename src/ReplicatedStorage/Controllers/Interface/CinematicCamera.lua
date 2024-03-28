--[[
	Show a skippable cinematic cutscene for the player using CameraHandler
]]

local SKIP_BUTTON_AVAILABLE = 3 -- time until the skip button is made available

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local CameraMover = require(ReplicatedStorage.Modules.CameraMover)
local TweenCreator = require(ReplicatedStorage.Modules.TweenCreator)
local SoundPlayer = require(ReplicatedStorage.Modules.SoundPlayer)

local SubtitleFadeInfo = TweenInfo.new(3)

local CinematicCamera = {
	Name = "CinematicCamera",
}
CinematicCamera.instance = script.CinematicBars
CinematicCamera.playing = false

function PanThroughFolder(folder: Folder | any) -- we prefer folders. | any has to be used cause funky typechecking
	local cameraTween: Tween

	return Promise.new(function(resolve, _, onCancel)
		onCancel(function() -- if the promise is canceled, we close the tween
			cameraTween:Cancel()
			CinematicCamera.playing = false
		end)

		for _, cameraModel: CameraMover.CameraSequence in folder:GetChildren() do -- while we are playing and the cinematic still has places to tween to
			if not CinematicCamera.playing then
				print("broke! skipped")
				break
			end
			print(cameraModel, "playing!")

			CinematicCamera.instance.SubtitleGroup.SubtitleLabel.Text = cameraModel:GetAttribute("Subtitle")
			TweenCreator.TweenTo(CinematicCamera.instance.SubtitleGroup, SubtitleFadeInfo, { GroupTransparency = 0 })

			CameraMover:CFrameCameraToPart(cameraModel.Start, true, 3) -- streams around start
			cameraTween = CameraMover:TweenCameraToPart(
				cameraModel.End,
				TweenInfo.new(
					cameraModel:GetAttribute("Duration") or 5, -- default time if no duration
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out
				),
				true,
				3
			) -- yields to stream around .end | we can put a faded screen here, then on the next line unfade it since it has loaded and is playing
			cameraTween.Completed:Wait() -- yield until the tween has completed
			CinematicCamera.instance.SubtitleGroup.GroupTransparency = 1
			print("completed!")
		end

		resolve() -- we've panned thru all the frames we need to, resolve
	end)
end

function CinematicCamera:PlayCinematic(cinematicCameraFolder: Folder)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

	self.playing = true
	self.instance.Parent = self.root -- root is passed after interface is invoked

	local cameraPromise = PanThroughFolder(cinematicCameraFolder)

	-- tween the visibility of the button to be usable
	TweenCreator.TweenTo(
		self.instance.ButtonGroup,
		TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, SKIP_BUTTON_AVAILABLE),
		{ GroupTransparency = 0 }
	):andThen(function()
		self.instance.ButtonGroup.SkipButton.Active = true
	end)

	self.instance.ButtonGroup.SkipButton.Activated:Once(function()
		if self.playing then
			cameraPromise:cancel() -- cancel the cinematic camera tween
		end
	end)

	SoundPlayer.TransitionMusicTheme("Cinema")
	return cameraPromise -- return promise to allow :await() to be used
end

function CinematicCamera.hideScreen()
	CinematicCamera.instance.Parent = script
end

return CinematicCamera
