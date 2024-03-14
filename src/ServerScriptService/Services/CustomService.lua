--[[
    Handle the uniforms, webbing, etc for players
	it is important to make sure all the types match up with the folder names. simply, if you have no clue what youre doing, or are not confident, leave it to someone else.
	redone by woofulous (Lucereus) 03/04/2024 to 03/07
]]

local MIN_RANK_ATTRIBUTE = "Rank"
local MAX_RANK_ATTRIBUTE = "MaxRank"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DataHandler = require(game:GetService("ServerScriptService").Services.DataHandler)
local HelmetConfig = require(ReplicatedStorage.Common.HelmetConfig)
local GroupHandler = require(ReplicatedStorage.Modules.GroupHandler)
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
CustomService.runtimeAccessories = {} -- a table of players : { where each returns a table of accessories they are previewing }
CustomService.initialAccessories = {} -- the accessories and other things the player joined with

local function reapplyInitialAppearance(player: Player)
	local character = player.Character

	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")

		if humanoid then
			for _, accessory in humanoid:GetAccessories() do
				accessory:Destroy()
			end

			for _, accessory in pairs(CustomService.initialAccessories[player.UserId].Accessories or {}) do
				humanoid:AddAccessory(accessory:Clone())
			end

			character.Shirt.ShirtTemplate = CustomService.initialAccessories[player.UserId].shirtTemplate
			character.Pants.PantsTemplate = CustomService.initialAccessories[player.UserId].pantsTemplate
		end
	end
end

-- remove & store accessories
local function removeAccessoryType(player: Player, humanoid: Humanoid, targetList: { string })
	local removedAccessories = CustomService.runtimeAccessories[player.UserId].InitialAccessories or {}
	local accessoryList = humanoid:GetAccessories()

	for _, accessory: Accessory in accessoryList do
		if table.find(targetList, accessory.AccessoryType.Name) then
			if not removedAccessories[accessory.AccessoryType.Name] then
				removedAccessories[accessory.AccessoryType.Name] = {}
			end

			table.insert(removedAccessories[accessory.AccessoryType.Name], accessory)
			accessory.Parent = ReplicatedStorage
		end
	end

	CustomService.runtimeAccessories[player.UserId].InitialAccessories = removedAccessories
end

-- clone then reapply the old accessories
function reapplyRemovedAccessories(player: Player, humanoid: Humanoid, targetList: { string })
	local removedAccessories = CustomService.runtimeAccessories[player.UserId].InitialAccessories or {}

	for _, accessoryType in pairs(targetList) do
		local accessories = removedAccessories[accessoryType]

		if accessories then
			for _, accessory in pairs(accessories) do
				humanoid:AddAccessory(accessory)
			end
		end
	end
end

function GetCustomFolderObject(kind: CustomizationKind, branch: number, name: string)
	local customGroup = CustomService.UniformBreakdown[kind][branch]
	assert(customGroup, "Cannot find CustomGroup")

	for _, customSet in pairs(customGroup) do
		if customSet.instance and customSet.instance.Name == name then
			return customSet.instance:Clone()
		end
	end
end

function ApplyCustomObjectToCharacter(object: any, kind: CustomizationKind, player: Player) -- gotta pass player since we have to also pass that to the config setup
	local character = player.Character -- variablize to cutdown on pathing
	print(kind, object)

	-- accessory removal
	if kind == "Helmet" then
		removeAccessoryType(player, character.Humanoid, { "Hat", "Neck" })
	elseif kind == "CuffTitle" then
		removeAccessoryType(player, character.Humanoid, { "Shoulder" })
	elseif kind == "Hair" then
		removeAccessoryType(player, character.Humanoid, { "Hair" })
	elseif kind == "EyeWear" then
		removeAccessoryType(player, character.Humanoid, { "Face" })
	elseif kind == "Webbing" then
		removeAccessoryType(player, character.Humanoid, { "Front", "Back", "Waist" })
	end

	-- object cloning & application
	if object:IsA("Accessory") then
		if kind == "Helmet" then
			HelmetConfig.Setup(object, player)
			print("apply decals to helm")
		elseif kind == "CuffTitle" then
			local OtherAccessory = object:FindFirstChildOfClass("ObjectValue")

			if OtherAccessory then
				character.Humanoid:AddAccessory(OtherAccessory.Value:Clone())
			end
			-- elseif kind == "Webbing" then
			-- object.Handle:FindFirstChild("AccessoryWeld").Part1 = character.Torso
		end

		character.Humanoid:AddAccessory(object)
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

	CustomService.runtimeAccessories[player.UserId][kind] = object
end

function CustomService.Client:UnequipAllAccessories(player: Player)
	-- for _, accessory in CustomService.runtimeAccessories[player.UserId] do
	-- accessory:Destroy()
	-- end

	reapplyInitialAppearance(player)
	return true
end

function CustomService.Client:RemoveAccessory(player: Player, kind: CustomizationKind)
	local character = player.Character
	if not character then
		return
	end

	local previewAccessory = CustomService.runtimeAccessories[player.UserId][kind]
	if previewAccessory then
		previewAccessory:Destroy()
		previewAccessory = nil

		if kind == "Helmet" then
			reapplyRemovedAccessories(player, character.Humanoid, { "Hat", "Hair" })
		elseif kind == "CuffTitle" then
			reapplyRemovedAccessories(player, character.Humanoid, { "Shoulder" })
		elseif kind == "Hair" then
			reapplyRemovedAccessories(player, character.Humanoid, { "Hair" })
		elseif kind == "EyeWear" then
			reapplyRemovedAccessories(player, character.Humanoid, { "Face" })
		elseif kind == "Webbing" then
			reapplyRemovedAccessories(player, character.Humanoid, { "Front", "Back", "Waist" })
		elseif kind == "Uniform" then
			character.Shirt.ShirtTemplate = CustomService.initialAccessories[player.UserId].shirtTemplate
			character.Pants.PantsTemplate = CustomService.initialAccessories[player.UserId].pantsTemplate
		end

		return true
	end
end

-- Called when a player equips a new item, allowing it to be previewed on the player before they Close and save it
function CustomService.Client:ApplyAccessory(player: Player, kind: CustomizationKind, objectInfo: AccessoryObject)
	local assetToPreview = GetCustomFolderObject(kind, objectInfo.branch, objectInfo.name)
	print(assetToPreview)
	print("previewing custom_kind object:", assetToPreview, "to:", player)
	ApplyCustomObjectToCharacter(assetToPreview, kind, player)
	print("applied")
	return true
end

-- Returns a table of the current player accessories which are equipped
function CustomService.Client:GetCurrentCustomization(player: Player)
	return CustomService:GetSavedCustomization(player)
end

-- Return a list of possible uniforms the person can wear. Used to fill the client's cosmetic options
function CustomService.Client:GetPossibleCustomization(player: Player)
	local groups = GroupHandler:GetGroupsAsync(player)
	local customizationList = { -- this is what we get from DataHandler template
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
			print(playerRank)

			print(branches)
			for accessory_name: string, attributes: CustomAttributes in branches[groupInfo.Id] do
				print(accessory_name, attributes.max, attributes.min, playerRank)
				if playerRank >= attributes.min and playerRank <= attributes.max then -- ensure the player is in the range to qualify for the accessory
					print("qualifies for check")
					customizationList[attributes.kind][accessory_name] = {
						branch = groupInfo.Id,
						name = accessory_name,
					} -- add the accessory to the customization list
				end
			end
		end
	end

	print(customizationList)
	return customizationList :: { [CustomizationKind]: { accessory_name: string } }
end

function CustomService.Client:SaveNewCustomization(
	player: Player,
	customizationList: { [UniformList | CosmeticList]: AccessoryObject }
)
	print("saving players customizationList:", player, customizationList)
	return DataHandler:Set(player, "Uniform", customizationList)
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
	-- Categorize all of the accessories in storage. Forewarning; CustomCategory should be the EXACT name as the export type CustomizationKind
	for _, customCategory in pairs(CustomizationFolder:GetChildren()) do
		local customGroup = {} -- This is the "Hair" or "Helmet" folder, broken down

		for _, customFolder in pairs(customCategory:GetChildren()) do
			if not customFolder:IsA("Folder") then
				warn("Folders inside of", customCategory.Name, "must be a folder type!")
				continue
			elseif self.UniformBreakdown[customCategory.Name] then
				warn("Overlap in folder naming conventions:", customFolder)
				continue
			end

			local groupId = customFolder:GetAttribute("GroupID")

			if not branches[groupId] then
				branches[groupId] = {}
			end

			if not customGroup[groupId] then
				customGroup[groupId] = {}
			end

			for _, accessory in pairs(customFolder:GetChildren()) do
				if accessory:IsA("Pants") then
					continue -- we don't need to categorize pants
				elseif accessory:IsA("Shirt") and not accessory.Pants then
					warn("Shirt does not have a 'Pants' ObjectValue:", accessory)
					continue
				end

				local customSet = {} -- will be all of the accessory's attributes and instance itself
				print(accessory)
				customSet.instance = accessory
				customSet.MinRank = tonumber(accessory:GetAttribute(MIN_RANK_ATTRIBUTE)) or 254
				customSet.MaxRank = tonumber(accessory:GetAttribute(MAX_RANK_ATTRIBUTE)) or 255

				branches[groupId][accessory.Name] = {
					min = customSet.MinRank,
					max = customSet.MaxRank,
					kind = customCategory.Name,
				}
				table.insert(customGroup[groupId], customSet)
			end
		end

		self.UniformBreakdown[customCategory.Name] = customGroup
	end

	print(self.UniformBreakdown)

	safePlayerAdded(function(player: Player)
		player.CharacterAppearanceLoaded:Connect(function(character: Model)
			local pants = character:WaitForChild("Pants", 3) -- should always return
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

			self.runtimeAccessories[player.UserId] = {}
			self.initialAccessories[player.UserId] = {
				Accessories = humanoid:GetAccessories(),
				shirtTemplate = shirt.ShirtTemplate,
				pantsTemplate = pants.PantsTemplate, -- pants will always exist
			}

			self:SetCustomization(player)
		end)
	end)
end

return CustomService
