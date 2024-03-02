--[[
	Loading
	This applies a LoadingScreen to the player while loading all of the PreloadAssets stored
	It also waits for the Knit.OnStart promise to return to ensure the player cannot prematurely access the game
]]

local LoadingModule = require(script.LoadingModule) -- includes the LoadingScreen & functions to wait for loading to finish

function PreGameLoaded()
	game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
	LoadingModule:ToggleVisible(true)
	LoadingModule:UpdateStatusText("Waiting for game")

	task.wait(2)
	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	LoadingModule:UpdateStatusText("Waiting for framework")
	task.wait(2)
	LoadingModule.awaitForKnit()
end

function PostTasksComplete()
	LoadingModule:UpdateStatusText("Preloading assets")
	task.wait(2)
	LoadingModule.startPreloadingAsync() -- begin the skippable preload process

	print("Loading has completed!")
	LoadingModule:ToggleVisible(false)
end

PreGameLoaded()
-- All game services loaded, Knit is ready
PostTasksComplete()
