--[[
    Handle the uniforms, webbing, etc for players
	it is important to make sure all the types match up with the folder names. simply, if you have no clue what youre doing, or are not confident, leave it to someone else.
	redone by woofulous (Lucereus) 03/04/2024 to 03/07
]]

local MIN_RANK_ATTRIBUTE = "MinRank"
local MAX_RANK_ATTRIBUTE = "MaxRank"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(game:GetService("ServerScriptService").Services.DataHandler)
local GroupHandler = require(ReplicatedStorage.Common.GroupHandler)
local HelmetConfig = require(ReplicatedStorage.Common.HelmetConfig)
local safePlayerAdded = require(ReplicatedStorage.Utility.safePlayerAdded)

local CustomizationFolder = game:GetService("ServerStorage").Customization

local branches = {} -- a list of all the groups that are used in customization

export type CustomizationKind = "Uniform" | "Webbing" | "Helmet" | "CuffTitle" | "Hair" | "EyeWear" -- these are the names of all the folders in the CustomizationFolder
export type AccessoryObject = { branch: number, name: string }
export type CustomAttributes = { min: number, max: number, kind: CustomizationKind }
export type UniformList = { Uniform: string, Webbing: string, Helmet: string }
export type CosmeticList = { Hair: string, CuffTitle: string, EyeWear: string }

local CustomService = {
	Name = "CustomService",
	Client = {},
}
CustomService.UniformBreakdown = {}

function GetCustomFolderObject(kind: CustomizationKind, branch: number, name: string)
	return CustomService.UniformBreakdown[kind][branch].Accessories[name].instance
end

function ApplyCustomObjectToCharacter(object: any, kind: CustomizationKind, player: Player) -- gotta pass player since we have to also pass that to the config setup
	local character = player.Character -- variablize to cutdown on pathing
	print(kind, object)

	if object:IsA("Accessory") then
		if kind == "Helmet" then
			HelmetConfig.Setup(object, player)
			print("apply decals to helm")
		end

		character.Humanoid:AddAccessory(object)
		if kind == "CuffTitle" then
			local OtherAccessory = object:FindFirstChildOfClass("ObjectValue")
			if OtherAccessory then
				character.Humanoid:AddAccessory(OtherAccessory.Value:Clone())
			end
		end

		if kind == "Webbing" then
			object.Handle:FindFirstChild("AccessoryWeld").Part1 = character.Torso
		end
	elseif object:IsA("Model") then
		if kind == "Webbing" then
			local weld = Instance.new("Weld")
			weld.Parent = object.Torso
			weld.Part0 = object.Torso
			weld.Part1 = character.Torso
		elseif kind == "Helmet" then
			local weld = Instance.new("Weld")
			weld.Parent = object.Head
			weld.Part0 = object.Head
			weld.Part1 = character.Head
		end

		object.Parent = character
		object.Name = kind
	elseif object:IsA("Shirt") then
		character.Shirt.ShirtTemplate = object.ShirtTemplate
		character.Pants.PantsTemplate = object.Pants.Value.PantsTemplate
	end
end

-- Return a list of possible uniforms the person can wear. Used to fill the client's cosmetic options
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
					customizationList[accessory_name] = {
						branch = groupInfo.Id,
						name = accessory_name,
					} -- add the accessory to the customization list
				end
			end
		end
	end

	return customizationList :: { [CustomizationKind]: { accessory_name: string } }
end

function CustomService.Client:SaveNewCustomization(
	player: Player,
	customizationList: { [UniformList | CosmeticList]: AccessoryObject }
)
	print("saving players customizationList:", player, customizationList)
	DataHandler:Set(player, "Uniform", customizationList)
end

function CustomService:GetSavedCustomization(player: Player)
	return DataHandler:Get(player, "Uniform") :: { CustomizationKind }
end

function CustomService:SetCustomization(player: Player)
	local character = player.Character
	if not character or not character.Torso then
		return -- cannot apply, character doesnt exist
	end

	local customizationList = self:GetSavedCustomization(player)
	print(customizationList)

	for custom_kind: CustomizationKind, object_info: AccessoryObject in customizationList do
		if object_info.name and object_info.name ~= "" then
			local object = GetCustomFolderObject(custom_kind, object_info.branch, object_info.name)
			print("applying custom_kind object:", object, "to:", player)
			ApplyCustomObjectToCharacter(object, custom_kind, player)
			print("applied")
		end
	end

	print("cloning & parenting all items in CustomizationList to the player:", player)
end

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

			self.Client:SaveNewCustomization(player, {
				["EyeWear"] = {},
				["CuffTitle"] = {},
				["Hair"] = {},
				["Helmet"] = {
					["branch"] = 15815551,
					["name"] = "Area League",
				},
				["Uniform"] = {
					["branch"] = 15294045,
					["name"] = "1",
				},
				["Webbing"] = {
					["branch"] = 15294045,
					["name"] = "Formal Belt",
				},
			})
			self:SetCustomization(player)
		end)
	end)

	-- Categorize all of the accessories in storage. Forewarning; CustomCategory should be the EXACT name as the export type CustomizationKind
	for _, customCategory: Folder in CustomizationFolder:GetChildren() do
		local customGroup = {} -- This is the "Hair" or "Helmet" folder, broken down

		for _, customFolder: Instance in customCategory:GetChildren() do
			if not customFolder:IsA("Folder") then
				warn("Folders inside of", customCategory.Name, "must be a folder type!")
				continue
			elseif self.UniformBreakdown[customCategory.Name] then
				warn("Overlap in folder naming conventions:", customFolder)
				continue
			end

			local groupId = customFolder:GetAttribute("GroupID")
			local customFile = {} -- will have all of the division's accessories & binds located inside of "Helmet" or "Accessories"
			customFile.Accessories = {}
			customFile.Color = customFolder:GetAttribute("Color")
			customFile.GroupId = groupId
			customFile.GroupRanks = customFolder:GetAttribute("GroupRanks")

			branches[customFile.GroupId] = {}

			for _, accessory in customFolder:GetChildren() do
				if accessory:IsA("Pants") then
					continue -- we dont need to categorize pants
				end

				local customSet = {} -- will be all of the accessory's attributes and instance itself
				customSet.instance = accessory

				if accessory:IsA("Shirt") then
					if not accessory.Pants then
						warn("Shirt does not have a 'Pants' ObjectValue:", accessory)
					end

					customSet.MinRank = accessory.Name -- the minrank is defined by the shirt's name
					customSet.MaxRank = 255 -- all shirts will naturally be accessible by the owner
				else
					customSet.MinRank = tonumber(accessory:GetAttribute(MIN_RANK_ATTRIBUTE)) -- tonumber is needed because attributes are natively strings
					customSet.MaxRank = tonumber(accessory:GetAttribute(MAX_RANK_ATTRIBUTE))

					if not customSet.MaxRank then
						customSet.MaxRank = 255
						warn(accessory, "doesnt have", MAX_RANK_ATTRIBUTE, "attribute")
					end

					if not customSet.MinRank then
						customSet.MinRank = 254
						warn(accessory, "doesnt have", MIN_RANK_ATTRIBUTE, "attribute")
					end
				end

				branches[customFile.GroupId][accessory.Name] =
					{ min = customSet.MinRank, max = customSet.MaxRank, kind = customCategory.Name }
				customFile.Accessories[accessory.Name] = customSet -- set to accessory name
			end

			customGroup[groupId] = customFile -- set to branch name
		end

		self.UniformBreakdown[customCategory.Name] = customGroup
	end

	print(self.UniformBreakdown)
end

return CustomService
