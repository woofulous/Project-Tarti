--[[
	Show a skippable cinematic cutscene for the player using CameraHandler
	Lucereus (03/14/2024) really anything with these sorta comments are me. nobody but me documents, really
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)

local CameraMover = require(ReplicatedStorage.Modules.CameraMover)

local MenuCameraFolder = game:GetService("Workspace").Studio.Cinematics:WaitForChild("MenuCamera")
local cameraPromise = nil --: promiseobject

local MenuScreen = {
	Name = "MenuScreen",
}
MenuScreen.instance = script.MenuFrame
MenuScreen.backgroundRunning = false

local function playGame()
	assert(cameraPromise, "No Promise started")

	cameraPromise:cancel() -- we close the background camera
	MenuScreen.instance.Parent = script -- hide the screen
end

function PromiseBackgroundPanning()
	local tipLabel = MenuScreen.instance:FindFirstChild("TipLabel") :: TextLabel
	local cameraTween: Tween
	MenuScreen.backgroundRunning = true -- start the loop

	cameraPromise = Promise.new(function(resolve, _, onCancel)
		onCancel(function() -- if the promise is canceled, we close the tween. this is cleanup
			MenuScreen.backgroundRunning = false -- break tha loop so we can resolve

			if cameraTween then
				cameraTween:Cancel()
			end
		end)

		while MenuScreen.backgroundRunning do
			for _, cameraFolder: Instance in MenuCameraFolder:GetChildren() do
				local cameraInfo = TweenInfo.new(cameraFolder:GetAttribute("Duration") or 10 --[[ default ]]) -- create a new tweeninfo for cameramover
				tipLabel.Text = cameraFolder:GetAttribute("Tip") or string.format("This is the %s", cameraFolder.Name) -- set the tip

				local startPart = cameraFolder:FindFirstChild("Start")
				local endPart = cameraFolder:FindFirstChild("End")
				print(cameraFolder, "playing!")

				CameraMover.CFrameCameraToPart(startPart)
				cameraTween = CameraMover.TweenCameraToPart(endPart, cameraInfo, true, 1) -- we decrease the streaming wait a lot in comparison to the introcinematic since we need these things to be playing 24/7
				cameraTween.Completed:Wait()
				print("completed!")
				task.wait(1) -- time between each background transition
			end
		end

		resolve() -- the screen has stopped running. resolve so :andThen will run. this isnt in cleanup just incase .backgroundRunning is resolved elsewhere
	end)

	return cameraPromise
end

-- Play the sliding tween for the UI after parenting instance to root
function MenuScreen:ToggleVisible(visible: boolean)
	if visible then
		self.instance.Parent = self.root
	else
		self.instance.Parent = script -- hide it
	end
end

-- return a promise of the background panning which can be tied with :finally to fire the callback when the panning has stopped
function MenuScreen.startCameraPanningPromise()
	assert(#MenuCameraFolder:GetChildren() > 0, "No menu cameras!!")
	assert(not MenuScreen.backgroundRunning, "Trying to start while already started")
	-- reason we dont localize :ParentToRoot here is because we may want to use it somewhere else without tampering with the camera.
	return PromiseBackgroundPanning() -- this is used also to detect the closure of the screen. so tying :andThen will fire once it has been resolved (GUI closed)
end

function MenuScreen:KnitInit() -- connect our connections
	local MainActions = self.instance:FindFirstChild("Main"):FindFirstChild("Actions") :: Frame

	local playButton = MainActions:FindFirstChild("Play") :: TextButton
	playButton.Activated:Connect(playGame)
end

return MenuScreen
