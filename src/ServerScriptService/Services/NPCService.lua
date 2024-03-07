--[[
	Set up all NPCs to ensure they work for the client to access via NonPlayerCharacter component
]]

local NPC_TAG = "NonPlayerCharacter" -- should resemble Components.NonPlayerCharacter

local CollectionService = game:GetService("CollectionService")

local NPCService = {
	Name = "NPCService",
	Client = {},
}

function setupNPC(npc: Model)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Talk to"
	prompt.ObjectText = npc.Name
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Parent = npc

	local ikControl = Instance.new("IKControl")
	ikControl.SmoothTime = 0.5
	ikControl.Type = Enum.IKControlType.LookAt
	ikControl.EndEffector = npc.Head.FaceFrontAttachment
	ikControl.ChainRoot = npc.Head.FaceCenterAttachment
	ikControl.Parent = npc
end

function NPCService:KnitInit()
	for _, npc: Model in CollectionService:GetTagged(NPC_TAG) do
		setupNPC(npc)
	end
end

return NPCService
