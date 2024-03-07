--[[
	This listens for events from the NPCService to start talking to an NPC and prepares then fires events back to the server through ModuleScripts located in the DialogTree
]]

local TweenService = game:GetService("TweenService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local choicePrefab = script.DialogChoiceButton
local slideInfo = TweenInfo.new()

local currentNPC = nil
local root = nil -- set to Interface.root

local DialogController = {
	Name = "DialogController",
}
DialogController.instance = script.DialogFrame

function CreateChoiceButton(text: string, callback: () -> ()) end

-- Hides all prompts & springs the camera to the set NPC
function DialogController.speakToNPCAsync(
	npc: Model,
	dialogTree: { response: string, goodbye: string, user: string, userChoices: {} }
)
	print("speak to npc:", npc)
	currentNPC = npc
	DialogController:OpenScreenAsync()
end

-- Spring the camera to the currentNPC. Yields until completion
function DialogController:OpenScreenAsync()
	print("opening screen while currentNPC is:", currentNPC)
end

function DialogController:CloseDialogScreen()
	Fusion.Spring(Fusion.Value(0), )
	task.wait(5)
	-- apply an impulse
	smoothPosition:addVelocity(UDim2.fromOffset(-10, 10))
end

function DialogController:KnitStart()
	local Interface = Knit.GetController("Interface")
	root = Interface.root
end

return DialogController
