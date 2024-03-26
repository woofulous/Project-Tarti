--[[
	The local player's "CoreLoop"
	Contain all instances related to the player and character to be used throughout the experience
	This helps track instances to be deleted when the player encounters events like death, respawn, etc
	Lucereus 03/20/2024
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local Studio = game:GetService("Workspace").Studio

local PlayerCycle = {
	Name = "PlayerCycle",
}
PlayerCycle.trackedFn = {} -- these are called each task.wait second
PlayerCycle.TickRunning = false

function CallTrackedFunctions()
	for _, tickFn: () -> () in PlayerCycle.trackedFn do
		task.defer(tickFn) -- push each tick function to a new thread. this makes it so the script will not yield to fire each of these functions, running synchronously
	end
end

function PlayerCycle:KnitStart()
	local DataHandler = Knit.GetService("DataHandler")

	local isNewPlayer = DataHandler:Get("FirstTimePlayer")
	local TransitionFade = Knit.GetController("TransitionFade")
	if isNewPlayer then
		local CinematicCamera = Knit.GetController("CinematicCamera")
		local IntroCamera = Studio.Cinematics:WaitForChild("IntroCamera")

		print("player is new! cinematic starting")
		CinematicCamera:PlayCinematic(IntroCamera):await() -- returns promise
		TransitionFade:TweenVisible(true):await()
		CinematicCamera.hideScreen()
		TransitionFade:TweenVisible(false)
		print("cinematic over. all resolved. start menu")
	end

	local MenuScreen = Knit.GetController("MenuScreen")
	MenuScreen.startCameraPanningPromise()
	MenuScreen:ToggleVisible(true) -- this basically starts the whole thing. everything else is on an "oninvoke" basis

	local HeadUpDisplay = Knit.GetController("HeadUpDisplay")
	local ZoneSystem = Knit.GetController("ZoneSystem")
	local SoundPlayer = require(ReplicatedStorage.Modules.SoundPlayer)
	-- connect char events
	Knit.Player.CharacterAdded:Connect(function(character: Model)
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		HeadUpDisplay.ConnectToHumanoid(humanoid)
		ZoneSystem.StartRenderStep(humanoid.RootPart)

		humanoid.Died:Once(function()
			ZoneSystem.UnbindFromRender(humanoid.RootPart)

			SoundPlayer.TransitionMusicTheme("Death")
		end)

		SoundPlayer.TransitionMusicTheme("Ambient")
	end)

	-- start client tick
	self.TickRunning = true
	while self.TickRunning and task.wait(math.random(1, 2)) do -- 1, 2 is the random threshold between each tick
		task.defer(CallTrackedFunctions) -- push it to a separate thread
	end
end

function PlayerCycle:OnClientTick(fn: () -> ()) -- onCancel, cancels the tick from the loop
	table.insert(self.trackedFn, fn)
	local fnIndex = #self.trackedFn

	return function()
		self.trackedFn[fnIndex] = nil
	end
end

return PlayerCycle
