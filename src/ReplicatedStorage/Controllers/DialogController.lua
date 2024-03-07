--[[
	This listens for events from the NPCService to start talking to an NPC and prepares then fires events back to the server through ModuleScripts located in the DialogTree
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Fusion = require(ReplicatedStorage.Packages.Fusion)

local choicePrefab = script.DialogChoiceButton

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

function DialogController:CloseDialogScreen() end

function DialogController:KnitStart()
	local Interface = Knit.GetController("Interface")
	root = Interface.root
end

return DialogController
