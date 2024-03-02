local Knit = require(game:GetService("ReplicatedStorage"):WaitForChild("Packages").Knit)

local LoadingModule = {}
LoadingModule.instance = script.LoadingScreen

function LoadingModule.awaitForKnit()
	print("waiting for knit")
	Knit.OnStart():await() -- If Knit has already started, this will still complete itself
	print("Knit has started")
end

function LoadingModule.startPreloadingAsync()
	print("start preloading assets")
end

function LoadingModule:ToggleVisible(visible: boolean)
	local PlayerGui = Knit.Player:WaitForChild("PlayerGui")

	if visible then
		print("Parent loading screen to", Knit.Player)
		self.instance.Parent = PlayerGui
	else
		print("Remove loading screen from", Knit.Player)
		self.instance.Parent = script
	end
end

function LoadingModule:UpdateStatusText(status: string)
	self.instance.StatusLabel.Text = status
end

return LoadingModule
