--[[
	Create and manage player Nametags
]]

local NametagPrefab = game:GetService("ServerStorage").Instances.NametagPrefab :: BillboardGui

local Nametags = {
	Name = "Nametags",
	Client = {},
	TaggedPlayers = {} :: { [number]: BillboardGui }, -- UserId returns modified NametagPrefab
}

-- If exists, :Destroy() player's nametag
function Nametags:CleanupPlayerTag(player: Player)
	local playerTag = self.TaggedPlayers[player.UserId]

	if playerTag then
		playerTag:Destroy()
		print("Cleaned up player tag")
	else
		warn("Attempting to cleanup an untagged player (Name)", player.Name)
	end
end

-- Create a new nametag for the player's Character, storing it for later cleanup
function Nametags:TagPlayer(player: Player)
	assert(
		player.Character and player.Character.PrimaryPart,
		"Tagging too fast, Character or HumanoidRootPart not loaded"
	)

	local playerTag = NametagPrefab:Clone()

	playerTag.Adornee = player.Character.PrimaryPart
	playerTag.Parent = player.Character

	self.TaggedPlayers[player.UserId] = playerTag
	print("Added new player tag")
end

return Nametags
