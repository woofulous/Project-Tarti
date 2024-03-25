--[[
	Include a variety of functions which will be used to pan cameras around, Spring them, etc
	Lucereus 03/13/2024
]]

export type CameraSequence = any & {
	Start: BasePart,
	End: BasePart,
}

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local CurrentTween: Tween

local CameraMover = {}
CameraMover.camera = game:GetService("Workspace").CurrentCamera

function ClearCurrentTween()
	if CurrentTween then
		CurrentTween:Cancel()
	end
end

-- Pass a Model which includes a Start and End BasePart to tween between
function CameraMover:PanToCameraSequence(
	cameraSequence: CameraSequence,
	cameraInfo: TweenInfo,
	replication_yield: boolean?,
	yield_timeout: number?
)
	ClearCurrentTween()
	self:CFrameCameraToPart(cameraSequence.Start)
	CurrentTween = self:TweenCameraToPart(cameraSequence.End, cameraInfo, replication_yield, yield_timeout)
	return CurrentTween
end

-- You can pass :GetChildren() and it will work as intended. if replication yield, will async stream around point
function CameraMover:TweenCameraToPart(
	desiredPart: BasePart,
	tweenInfo: TweenInfo,
	replication_yield: boolean?,
	yield_timeout: number?
): Tween
	if replication_yield then
		Players.LocalPlayer:RequestStreamAroundAsync(desiredPart.Position, yield_timeout)
	end

	local tween = TweenService:Create(self.camera, tweenInfo, { CFrame = desiredPart.CFrame })
	ClearCurrentTween()
	tween:Play()

	return tween
end

-- sets camera.cframe to the part's, if replication yield, will yield to stream around point
function CameraMover:CFrameCameraToPart(desiredPart: BasePart, replication_yield: boolean?, yield_timeout: number?)
	if replication_yield then
		Players.LocalPlayer:RequestStreamAroundAsync(desiredPart.Position, yield_timeout)
	end

	self.camera.CFrame = desiredPart.CFrame
end

return CameraMover
