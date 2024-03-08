--[[
	This is the client-side of the CustomService
	It fetches possible uniforms from the server for the client to use, then passes those back via event firing to equip uniforms, etc
]]

local ProximityPromptService = game:GetService("ProximityPromptService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local CustomizationList = {} -- a list of all possible accessories, uniforms, cosmetics, and all else the player can wear
local root = nil

local CustomController = {
	Name = "CustomController",
}
CustomController.instance = script.CustomGui

function CustomController:ToggleOpen(open: boolean)
	ProximityPromptService.Enabled = not open

	if open then
		self.instance.Parent = root
	else
		self.instance.Parent = script
	end
end

function CustomController:KnitStart()
	local Interface = Knit.GetController("Interface")
	root = Interface.root

	local CustomService = Knit.GetService("CustomService")

	CustomService:GetPossibleCustomization():andThen(function(list) -- wait for Promise to pass the CustomizationList
		print("Got CustomizationList:", list)
		CustomizationList = list
	end)
end

return CustomController
