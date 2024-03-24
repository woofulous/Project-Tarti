--[[
	Show a skippable cinematic cutscene for the player using CameraHandler
]]

local SKIP_BUTTON_AVAILABLE = 3 -- time until the skip button is made available

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local CameraMover = require(ReplicatedStorage.Modules.CameraMover)
local TweenCreator = require(ReplicatedStorage.Modules.TweenCreator)

local CinematicCamera = {
	Name = "CinematicCamera",
}
CinematicCamera.instance = script.CinematicBars
CinematicCamera.playing = false

function PanThroughFolder(folder: Folder)
	local cameraTween: Tween

	return Promise.new(function(resolve, _, onCancel)
		onCancel(function() -- if the promise is canceled, we close the tween
			cameraTween:Cancel()
		end)

		for _, cameraModel: Instance in folder:GetChildren() do -- while we are playing and the cinematic still has places to tween to
			if not CinematicCamera.playing then
				print("broke! skipped")
			end
			local cameraInfo = TweenInfo.new(
				cameraModel:GetAttribute("Duration") or 5, -- default time if no duration
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			)

			local startPart = cameraModel:FindFirstChild("Start")
			local endPart = cameraModel:FindFirstChild("End")
			print(cameraModel, "playing!")

			CameraMover:CFrameCameraToPart(startPart, true, 3) -- streams around start
			cameraTween = CameraMover:TweenCameraToPart(endPart, cameraInfo, true, 3) -- yields to stream around .end | we can put a faded screen here, then on the next line unfade it since it has loaded and is playing
			cameraTween.Completed:Wait() -- yield until the tween has completed
			print("completed!")
		end

		resolve() -- we've panned thru all the frames we need to, resolve
	end)
end

function CinematicCamera:PlayCinematic(cinematicCameraFolder: Folder)
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

	self.playing = true
	self.instance.Parent = self.root -- root is passed after interface is invoked

	-- CinematicCameraFolder.ChildAdded:Wait() -- wait for the folder to begin replicating. we dont need this as long as we ensure the model's streaming is set to "Persistent"

	-- local disconnectSkip: RBXScriptConnection
	local cameraPromise = PanThroughFolder(cinematicCameraFolder) --:andThen(function()
	-- print("promise has resolved, things have finished!")
	-- disconnectSkip:Disconnect() -- disconnect the opportunity to skip
	-- end)

	cameraPromise:finally(function() -- they've skipped the cinematic, or theres no more to play.
		self.playing = false
		self.instance.Parent = script -- remove screen
	end)

	-- tween the visibility of the button to be usable
	local skipTween = TweenCreator.TweenTo(
		self.instance.ButtonGroup, -- the instance
		TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, SKIP_BUTTON_AVAILABLE), -- the tweeninfo
		{ GroupTransparency = 0 } -- the goal
	)
	skipTween:andThen(function()
		print("I've completed!")
		self.instance.ButtonGroup.SkipButton.Active = true
	end)

	self.instance.ButtonGroup.SkipButton.Activated:Once(function()
		if self.playing then
			cameraPromise:cancel() -- cancel the cinematic camera tween
		end
	end)

	-- print("all resolved. start menu")
	return cameraPromise -- return promise to allow :await() to be used
end

return CinematicCamera
