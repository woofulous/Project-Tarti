--[[
    Handle the uniforms, webbing, etc for players
	it is important to make sure all the types match up with the folder names. simply, if you have no clue what youre doing, or are not confident, leave it to someone else.
	redone by woofulous (Lucereus) 03/04/2024
]]

local MIN_RANK_ATTRIBUTE = "Rank"
local MAX_RANK_ATTRIBUTE = "MaxRank"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(game:GetService("ServerScriptService").Services.DataHandler)
local GroupHandler = require(ReplicatedStorage.Common.GroupHandler)
local safePlayerAdded = require(ReplicatedStorage.Utility.safePlayerAdded)

local CustomizationFolder = game:GetService("ServerStorage").Customization

local branches = {} -- a list of all the groups that are used in customization

export type CustomizationKind = "Uniform" | "Webbing" | "Helmet" | "CuffTitle" | "Hair" | "EyeWear" -- these are the names of all the folders in the CustomizationFolder
export type CustomAttributes = { min: number, max: number, kind: CustomizationKind }
export type UniformList = { Uniform: string, Webbing: string, Helmet: string }
export type CosmeticList = { Hair: string, CuffTitle: string, EyeWear: string }

local CustomService = {
	Name = "CustomService",
	Client = {},
}
CustomService.UniformBreakdown = {}

-- Return a list of possible uniforms the person can wear
function CustomService.Client:GetPossibleCustomization(player: Player)
	local groups = GroupHandler:GetGroups(player)
	local customizationList = {
		Uniform = {},
		Webbing = {},
		Helmet = {},
		-- cuffTitle = {}, -- Even though this is kind of right, the C isnt capital. it WILL error. Ensure you are using correct case
		CuffTitle = {},
		Hair = {},
		EyeWear = {},
	} -- list of all assets they can wear. should include ALL case-SENSITIVE CustomizationKind's, because they will be filled just below \/

	for _, groupInfo: { Id: number } in groups do
		if branches[groupInfo.Id] then
			print(player, "qualifies for:", groupInfo.Id, branches[groupInfo.Id])
			local playerRank = player:GetRankInGroup(groupInfo.Id)

			for accessory_name: string, attributes: CustomAttributes in branches[groupInfo.Id] do
				if playerRank >= attributes.min and playerRank <= attributes.max then -- ensure the player is in the range to qualify for the accessory
					table.insert(customizationList[attributes.kind], accessory_name) -- add the accessory to the customization list
				end
			end
		end
	end

	return customizationList :: { [CustomizationKind]: { accessory_name: string } }
end

function CustomService:SetCustomization(player: Player, kind: CustomizationKind, uniformList: UniformList) end

function CustomService:KnitInit()
	safePlayerAdded(function(player: Player)
		player.CharacterAppearanceLoaded:Connect(function(character: Model)
			local shirt = character:WaitForChild("Shirt", 3)

			if not shirt then -- no need to check if pants dont exist, roblox ensures they do
				shirt = Instance.new("Shirt")
				shirt.Name = "Shirt"
				shirt.Parent = character
			end

			local humanoid = character:FindFirstChildOfClass("Humanoid")
			local humanoidDescription = humanoid:GetAppliedDescription()

			if not table.find({ 4279033527, 31716920 }, player.UserId) then
				humanoidDescription.Head = 0
			end

			humanoidDescription.LeftArm = 0
			humanoidDescription.RightArm = 0
			humanoidDescription.LeftLeg = 0
			humanoidDescription.RightLeg = 0
			humanoidDescription.Torso = 0
			humanoid:ApplyDescription(humanoidDescription)

			local uniformList = DataHandler:Get(player, "Uniform")
			print(uniformList)
		end)
	end)

	-- Categorize all of the accessories in storage. Forewarning; CustomCategory should be the EXACT name as the export type CustomizationKind
	for _, customCategory: Folder in CustomizationFolder:GetChildren() do
		local customGroup = {} -- This is the "Hair" or "Helmet" folder, broken down

		for _, customFolder: Instance in customCategory:GetChildren() do
			if not customFolder:IsA("Folder") then
				warn("Folders inside of", customCategory.Name, "must be a folder type!")
				continue
			end

			local customFile = {} -- will have all of the division's accessories & binds located inside of "Helmet" or "Accessories"
			customFile.Accessories = {}
			customFile.Color = customFolder:GetAttribute("Color")
			customFile.GroupId = customFolder:GetAttribute("GroupID")
			customFile.GroupRanks = customFolder:GetAttribute("GroupRanks")

			branches[customFile.GroupId] = {}

			for _, accessory in customFolder:GetChildren() do
				local customSet = {} -- will be all of the accessory's attributes and instance itself
				customSet.MinRank = tonumber(accessory:GetAttribute(MIN_RANK_ATTRIBUTE)) -- tonumber is needed because attributes are natively strings
				customSet.MaxRank = tonumber(accessory:GetAttribute(MAX_RANK_ATTRIBUTE))
				customSet.instance = accessory

				branches[customFile.GroupId][accessory.Name] =
					{ min = customSet.MinRank, max = customSet.MaxRank, kind = customCategory.Name }
				table.insert(customFile.Accessories, customSet)
			end

			table.insert(customGroup, customFile)
		end

		self.UniformBreakdown[customCategory.Name] = customGroup
	end

	print(self.UniformBreakdown)
end

return CustomService
