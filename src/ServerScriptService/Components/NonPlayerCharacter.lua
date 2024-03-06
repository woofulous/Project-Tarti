--[[
	This is the server setup for NPCs.
	When the player interacts, it fires a signal to the client from NPCService to begin conversation with the NPC.
	Primarily makes the prompts and anything else the client may need
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)
local Component = require(ReplicatedStorage.Packages.Component)

local NPCFolder = game:GetService("Workspace").Studio.NPCs

local NonPlayerCharacter = Component.new({
	Tag = "NonPlayerCharacter",
	Ancestors = { NPCFolder },
	Extensions = {},
})

function NonPlayerCharacter:Construct()
	self.troveObject = Trove.new()
	self.troveObject:AttachToInstance(self.Instance)

	self.prompt = Instance.new("ProximityPrompt")
	self.prompt.ActionText = "Talk to"
	self.prompt.ObjectText = self.Instance.Name
	self.prompt.Style = Enum.ProximityPromptStyle.Custom
	self.prompt.Parent = self.Instance
	self.troveObject:Add(self.prompt)

	self.ikControl = Instance.new("IKControl")
	self.ikControl.Type = Enum.IKControlType.LookAt
	self.ikControl.ChainRoot = self.Instance.Head.FaceCenterAttachment
	self.ikControl.EndEffector = self.Instance.Head.FaceFrontAttachment
	self.ikControl.Parent = self.Instance
	self.troveObject:Add(self.ikControl)
end

function NonPlayerCharacter:Start()
	local NPCService = require(game:GetService("ServerScriptService").Services.NPCService)

	self.prompt.Triggered:Connect(function(playerWhoTriggered)
		NPCService:PlayerTriggeredNPC(playerWhoTriggered, self.Instance)
	end)
end

function NonPlayerCharacter:Stop() end

return NonPlayerCharacter
