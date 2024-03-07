--[[
	Centralize all Interface Gui's under a single "RootGui"
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Interface = {
	Name = "Interface",
}

function Interface:KnitInit()
	Interface.root = Instance.new("ScreenGui")
	Interface.root.Name = "RootGui"
	Interface.root.IgnoreGuiInset = true
	Interface.root.ScreenInsets = Enum.ScreenInsets.None
	Interface.root.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	Interface.root.Parent = Knit.Player.PlayerGui
end

return Interface
