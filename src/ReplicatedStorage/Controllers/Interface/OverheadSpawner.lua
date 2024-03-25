--[[
	Handle the player spawning via an overhead style
	Zoom in when a player is deciding on a spot to spawn in
	Show icons of specific locations of interest, and also preview the current score between each team
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local CameraMover = require(ReplicatedStorage.Modules.CameraMover)

local SpawnFolder = Workspace.Studio.SpawnPoints
local PointPrefab = script.PointButton :: ImageButton & { ["PointName"]: TextLabel }

local RiseInfo = TweenInfo.new(1) -- we need a separate cause we want the rising to be faster than the lowering
local PanInfo = TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local currentSequence: CameraMover.CameraSequence
local previousStartSequence: BasePart -- we cache this so we can rise away when the player selects a new sequence
local selected_point_name: string -- dont think this will work amazing, but just make sure the points all have separate names so they dont get mixed up. we pass this value to teamhandler to decide where the player should spawn

type PointModel = Model & {
	CameraSequence: CameraMover.CameraSequence,
	SpawnParts: Model & { BasePart? }, -- a table of baseparts to spawn on
}

local OverheadSpawner = {
	Name = "OverheadSpawner",
}
OverheadSpawner.instance = script.SpawnScreen
OverheadSpawner.SpawnPoints = {} -- a table of [point_name: string] = {camera sequence & point button} we send the point name to the server to use the random spawn parts

function CreatePointButton(name: string)
	local button = PointPrefab:Clone()
	button.PointName.Text = name
	button.Name = name

	return button
end

function OverheadSpawner:OpenFromMenu()
	self.instance.Parent = self.root

	-- set current sequence to that player's "home spawn" for raiders this would be "raider spawn", teutonnians "teutonnia spawn"
	currentSequence = SpawnFolder["Castle"].CameraSequence
	previousStartSequence = currentSequence.Start

	CameraMover:PanToCameraSequence(currentSequence, PanInfo, true, 3)
end

function OverheadSpawner:KnitStart()
	local SpawnService = Knit.GetService("SpawnService")
	local TransitionFade = Knit.GetController("TransitionFade")
	local SoundPlayer = Knit.GetController("SoundPlayer")

	local deployButton = self.instance:FindFirstChild("Deploy") :: ImageButton
	deployButton.Activated:Connect(function()
		SoundPlayer.PlayRandomSound("Interface", "ButtonClick")
		CameraMover:TweenCameraToPart(previousStartSequence, RiseInfo)

		TransitionFade:TweenVisible(true):andThen(function()
			SpawnService:RequestSpawnAtPoint(selected_point_name)
			TransitionFade:TweenVisible(false)
			self.instance.Parent = script -- hide the screen
		end)
	end)

	local SpawnList = self.instance.SpawnGroup:FindFirstChildOfClass("ScrollingFrame") :: ScrollingFrame
	local pageLayout = SpawnList:FindFirstChildOfClass("UIPageLayout")

	-- setup pages
	for _, spawnPoint: PointModel in SpawnFolder:GetChildren() do
		local spawnButton = CreatePointButton(spawnPoint.Name)
		spawnButton.Name = spawnPoint.Name

		spawnButton.Activated:Connect(function() -- transition the page to the selected one
			SoundPlayer.PlayRandomSound("Interface", "ButtonClick")

			if currentSequence == spawnPoint.CameraSequence then
				return -- this prevents player clicking the same option a bunch of times if its already selected :)
			end

			previousStartSequence = currentSequence.Start
			currentSequence = spawnPoint.CameraSequence
			pageLayout:JumpTo(spawnButton)
			selected_point_name = spawnPoint.Name
		end)

		self.SpawnPoints[spawnPoint.Name] = {
			sequence = spawnPoint.CameraSequence,
			button = spawnButton,
		}
		spawnButton.Parent = SpawnList
	end

	pageLayout:JumpTo(self.SpawnPoints["Castle"].button)
	selected_point_name = "Castle"

	local currentlyTweening = false
	pageLayout:GetPropertyChangedSignal("CurrentPage"):Connect(function()
		-- if is already rising, return
		if currentlyTweening then -- debounce
			return
		else
			currentlyTweening = true
		end

		-- play rise tween and fade
		local riseTween = CameraMover:TweenCameraToPart(currentSequence.Start, RiseInfo) -- rise the tween to the start position -- when the visibility has completely finished, start to pan down and get rid of the transition

		TransitionFade:TweenVisible(true):andThen(function()
			riseTween:Cancel() -- we dont really care if this actually finishes because you wont even be able to see it finish when your screen is blocked out by the fade
			CameraMover:PanToCameraSequence(currentSequence, PanInfo, true, 3)
			TransitionFade:TweenVisible(false)
			currentlyTweening = false
		end)
	end)
end

return OverheadSpawner
