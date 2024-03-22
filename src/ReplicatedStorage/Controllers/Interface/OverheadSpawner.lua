--[[
	Handle the player spawning via an overhead style
	Zoom in when a player is deciding on a spot to spawn in
	Show icons of specific locations of interest, and also preview the current score between each team
]]

local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local CameraMover = require(ReplicatedStorage.Modules.CameraMover)

local SpawnFolder = Workspace.Studio.SpawnPoints
local PointPrefab = script.PointButton :: ImageButton & { ["PointName"]: TextLabel }

local PanInfo = TweenInfo.new(3, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)

local currentSequence: CameraMover.CameraSequence

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

function PanAwayFromCurrentAsync()
	local camTween = CameraMover:TweenCameraToPart(currentSequence.Start, PanInfo, true, 1)
	camTween.Completed:Wait()
end

function OverheadSpawner:OpenFromMenu()
	self.instance.Parent = self.root

	-- set current sequence to that player's "home spawn" for raiders this would be "raider spawn", teutonnians "teutonnia spawn"
	currentSequence = SpawnFolder["Castle"].CameraSequence

	CameraMover:PanToCameraSequence(currentSequence, PanInfo, true, 3)
end

function OverheadSpawner:KnitStart()
	local SpawnList = self.instance.SpawnGroup:FindFirstChildOfClass("ScrollingFrame") :: ScrollingFrame
	local pageLayout = SpawnList:FindFirstChildOfClass("UIPageLayout")

	-- setup pages
	print(SpawnFolder)
	for _, spawnPoint: PointModel in SpawnFolder:GetChildren() do
		print(spawnPoint)
		local spawnButton = CreatePointButton(spawnPoint.Name)

		spawnButton.Activated:Connect(function() -- transition the page to the selected one
			currentSequence = spawnPoint.CameraSequence
			pageLayout:JumpTo(spawnButton)
		end)

		self.SpawnPoints[spawnPoint.Name] = {
			sequence = spawnPoint.CameraSequence,
			button = spawnButton,
		}
		spawnButton.Parent = SpawnList
	end

	pageLayout:JumpTo(self.SpawnPoints["Castle"].button)

	pageLayout:GetPropertyChangedSignal("CurrentPage"):Connect(function()
		print(pageLayout.CurrentPage)
		CameraMover:PanToCameraSequence(currentSequence, PanInfo, true, 3)
	end)
end

return OverheadSpawner
