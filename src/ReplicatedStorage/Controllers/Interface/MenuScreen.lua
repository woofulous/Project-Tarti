--[[
	Show a skippable cinematic cutscene for the player using CameraHandler
]]

local MenuScreen = {
	Name = "MenuScreen",
}
MenuScreen.instance = script.MenuFrame

function MenuScreen:ParentToRoot()
	self.instance.Parent = self.root
end

function MenuScreen.startAsync()
	MenuScreen:ParentToRoot()
end

return MenuScreen
