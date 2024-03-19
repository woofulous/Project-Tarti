--[[
	Loading
	This applies a LoadingScreen to the player while loading all of the PreloadAssets stored
	It also waits for the Knit.OnStart promise to return to ensure the player cannot prematurely access the game
]]

local LoadingModule = require(script.LoadingModule) -- includes the LoadingScreen & functions to wait for loading to finish

function PreGameLoaded()
	game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
	LoadingModule.setMaxProgressIndex(3)
	LoadingModule:ToggleVisible(true)
	LoadingModule:UpdateProgressIndex(0, "Waiting for game")
	--task.wait(2)

	if not game:IsLoaded() then
		game.Loaded:Wait()
	end

	LoadingModule:UpdateProgressIndex(1, "Waiting for framework")
	LoadingModule.awaitForKnit()
	--task.wait(2)
end

function PostTasksComplete()
	LoadingModule:UpdateProgressIndex(2, "Preloading assets")
	LoadingModule.startPreloadingAsync() -- begin the skippable preload process
	--task.wait(2)

	print("Loading has completed!")
	LoadingModule:UpdateProgressIndex(3, "Finishing")
	--task.wait(2)
	LoadingModule:ToggleVisible(false)
end

PreGameLoaded()
-- All game services loaded, Knit is ready
PostTasksComplete()
