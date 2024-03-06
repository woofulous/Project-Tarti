--[[
	This listens for events from the NPCService to start talking to an NPC and prepares then fires events back to the server through ModuleScripts located in the DialogTree
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local currentNPC = nil
local root = nil -- set to Interface.root

local DialogController = {
	Name = "DialogController",
}
DialogController.instance = script.DialogFrame

-- Hides all prompts & springs the camera to the set NPC
function DialogController.speakToNPCAsync(npc: Model)
	print("speak to npc:", npc)
	currentNPC = npc
	DialogController:OpenScreenAsync()
end

-- Spring the camera to the currentNPC. Yields until completion
function DialogController:OpenScreenAsync()
	print("opening screen while currentNPC is:", currentNPC)
end

function DialogController:KnitStart()
	local Interface = Knit.GetController("Interface")
	root = Interface.root

	local NPCService = Knit.GetService("NPCService")

	NPCService.SpeakToNPC:Connect(self.speakToNPCAsync)
end

return DialogController
