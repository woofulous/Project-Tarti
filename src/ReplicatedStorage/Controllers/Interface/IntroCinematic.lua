--[[
	Show a skippable cinematic cutscene for the player using CameraHandler
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local CameraMover = require(ReplicatedStorage.Modules.CameraMover)

local CinematicCameraFolder = game:GetService("Workspace").Studio:WaitForChild("CinematicCamera")
local cameraInfo = TweenInfo.new(10)

local IntroCinematic = {
	Name = "IntroCinematic",
}
IntroCinematic.instance = script.CinematicBars
IntroCinematic.playing = false

function PanThroughFolder(folder: Folder)
	local cameraTween: Tween

	return Promise.new(function(resolve, _, onCancel)
		onCancel(function() -- if the promise is canceled, we close the tween
			cameraTween:Cancel()
		end)

		for _, cameraModel: Instance in folder:GetChildren() do -- while we are playing and the cinematic still has places to tween to
			if not IntroCinematic.playing then
				print("broke! skipped")
			end
			local startPart = cameraModel:FindFirstChild("Start")
			local endPart = cameraModel:FindFirstChild("End")
			print(cameraModel, "playing!")

			CameraMover.CFrameCameraToPart(startPart, true, 3) -- streams around start
			cameraTween = CameraMover.TweenCameraToPart(endPart, cameraInfo, true, 3) -- yields to stream around .end | we can put a faded screen here, then on the next line unfade it since it has loaded and is playing
			cameraTween.Completed:Wait() -- yield until the tween has completed
			print("completed!")
		end

		resolve() -- we've panned thru all the frames we need to, resolve
	end)
end

function IntroCinematic:PlayCinematic()
	workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable

	self.playing = true
	self.instance.Parent = self.root -- root is passed after interface is invoked

	CinematicCameraFolder.ChildAdded:Wait() -- wait for the folder to begin replicating

	local disconnectSkip: RBXScriptConnection
	local cameraPromise = PanThroughFolder(CinematicCameraFolder):andThen(function()
		print("promise has resolved, things have finished!")
		disconnectSkip:Disconnect() -- disconnect the opportunity to skip
	end)

	local skipButton = self.instance:FindFirstChild("SkipButton") :: TextButton
	disconnectSkip = skipButton.Activated:Once(function()
		self.playing = false
		cameraPromise:cancel() -- cancel the cinematic camera tween
	end)

	cameraPromise:await() -- they've skipped the cinematic, or theres no more to play.
	print("all resolved. start menu")
end

return IntroCinematic
