--[[
	This is the player's HUD (Head-up Display) which governs visible recreation of properties related to the character's humanoid, like health, stamina, etcetera.
]]

local HeadUpDisplay = {
	Name = "HeadUpDisplay",
}
HeadUpDisplay.instance = script.HudScreen

function HeadUpDisplay:ToggleVisible(visible: true | false)
	if visible then
		self.instance.Parent = self.root
	else
		self.instance.Parent = script
	end
end

function HeadUpDisplay.ConnectToHumanoid(humanoid: Humanoid)
	HeadUpDisplay:ToggleVisible(true)

	humanoid.HealthChanged:Connect(function(health: number)
		HeadUpDisplay.instance.StatLabel.Health.Size = UDim2.fromScale(health / 100, 1)
	end)
end

return HeadUpDisplay
