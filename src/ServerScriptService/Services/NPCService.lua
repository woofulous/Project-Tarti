--[[
	This is the middleman between NonPlayerCharacter components and the DialogController
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local NPCService = {
	Name = "NPCService",
	Client = {
		SpeakToNPC = Knit.CreateSignal(),
	},
}

-- The player has triggered the prompt tied to NonPlayerCharacter's
function NPCService:PlayerTriggeredNPC(player: Player, npc: Model)
	self.Client.SpeakToNPC:Fire(player, npc)
end

return NPCService
