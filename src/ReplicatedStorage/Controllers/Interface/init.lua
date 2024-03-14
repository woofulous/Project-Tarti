--[[
	Centralize all Interface Gui's under a single "RootGui"
]]

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local Interface = {
	Name = "Interface",
}
Interface.FrameInstances = {} -- this contains a list of all the invoked primary .instance properties that are invoked in ClientStrap. categorizing these makes it easier to use Interface's methods to manage large chunks of UI

function Interface:KnitInit()
	Interface.root = Instance.new("ScreenGui")
	Interface.root.Name = "RootGui"
	Interface.root.IgnoreGuiInset = true
	Interface.root.ScreenInsets = Enum.ScreenInsets.None
	Interface.root.SafeAreaCompatibility = Enum.SafeAreaCompatibility.None
	Interface.root.Parent = Knit.Player.PlayerGui
end

return Interface
