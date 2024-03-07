--[[
	This listens for events from the NPCService to start talking to an NPC and prepares then fires events back to the server through ModuleScripts located in the DialogTree
]]

local TweenService = game:GetService("TweenService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local choicePrefab = script.DialogChoiceButton :: TextButton
local slideInfo = TweenInfo.new()

local currentTree = nil
local root = nil -- set to Interface.root

local DialogController = {
	Name = "DialogController",
}
DialogController.instance = script.DialogFrame

function CreateChoiceButton(text: string, callback: () -> ())
	local button = choicePrefab:Clone()
	button.Text = text
	button.Activated:Connect(callback)
end

-- Hides all prompts & springs the camera to the set NPC. Yields until completion
function DialogController.speakToNPCAsync(
	npc: Model,
	dialogTree: { response: string, goodbye: string, user: string, userChoices: {} }
)
	print("speak to npc:", npc)
	currentTree = dialogTree
	DialogController:OpenScreen()
end

-- Tween open the interface
function DialogController:OpenScreen()
	print("opening screen while currentTree is:", currentTree)
	self.instance.Parent = root
	local slideIn = TweenService:Create(self.instance, slideInfo, { AnchorPoint = Vector2.new(0, 1) })
	slideIn:Play()
end

-- Tween close the interface
function DialogController:CloseDialogScreen()
	local slideOut = TweenService:Create(self.instance, slideInfo, { AnchorPoint = Vector2.new(0, 0) })
	slideOut.Completed:Connect(function()
		self.instance.Parent = script
	end)
	slideOut:Play()
	print("return camera to normal")
end

function DialogController:KnitStart()
	local Interface = Knit.GetController("Interface")
	root = Interface.root
end

return DialogController
