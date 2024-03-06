--[[
	Centralize all Interface Gui's under a single "RootGui"
]]

local Interface = {
	Name = "Interface",
}

function Interface:KnitInit()
	Interface.root = Instance.new("ScreenGui")
	Interface.root.Name = "RootGui"
	Interface.root.IgnoreGuiInset = true
	Interface.root.ScreenInsets = Enum.ScreenInsets.None
	Interface.root.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
end

return Interface
