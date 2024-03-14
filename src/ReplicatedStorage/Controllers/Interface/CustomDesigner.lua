--[[
	This is the client-side of the CustomService
	It fetches possible uniforms from the server for the client to use, then passes those back via event firing to equip uniforms, etc
]]

local TweenService = game:GetService("TweenService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local slideInfo = TweenInfo.new(0.5)
local CategoryPrefab = script.CategoryTemplate :: TextButton
local OptionPrefab = script.OptionTemplate :: TextButton

local EquippedList = {} -- a list of all the currently equipped items
local currentSelected = {} -- it was either this, or attributes. chose this since it requires lil less overhead. give it a shot if you wanna try a diff way
local root = nil

local CustomDesigner = {
	Name = "CustomDesigner",
}
CustomDesigner.instance = script.CustomGui

function CreateCategoryOption(name: string)
	local category = CategoryPrefab:Clone()
	category.Text = name
	category.Parent = CustomDesigner.instance.CategoryFrame

	local openTween = TweenService:Create(category.ScrollingFrame, slideInfo, { Size = UDim2.new(1, 0, 4, 0) })

	category.Activated:Connect(function()
		category.ScrollingFrame.Visible = not category.ScrollingFrame.Visible

		if category.ScrollingFrame.Visible then
			openTween:Play()
		else
			if openTween.PlaybackState == Enum.PlaybackState.Playing then
				openTween:Cancel()
			end

			category.ScrollingFrame.Size = UDim2.new(1, 0, 0, 0)
		end
	end)

	return category
end

function CreateOption(name: string)
	local category = OptionPrefab:Clone()
	category.Text = name
	category.Parent = CustomDesigner.instance.CategoryFrame

	return category
end

function CustomDesigner.openFromNPC()
	print("open from npc")
	CustomDesigner:ToggleOpen(true)
end

function CustomDesigner:ToggleOpen(open: boolean)
	if open then
		self.instance.Parent = root
	else
		ProximityPromptService.Enabled = true
		self.instance.Parent = script
	end
end

function CustomDesigner:KnitStart()
	local Interface = Knit.GetController("Interface")
	root = Interface.root

	local CustomService = Knit.GetService("CustomService")

	local success, result = CustomService:GetCurrentCustomization():await()
	assert(success, result)

	EquippedList = result
	print("got current equipped:", result)

	CustomService:GetPossibleCustomization():andThen(function(list) -- wait for Promise to pass the CustomizationList
		print("Got CustomizationList:", list)

		-- fill category options
		for category_name, categoryDetails in list do -- category_name stands for the kind
			local category = CreateCategoryOption(category_name)

			for option_name, optionInfo: { branchId: number, name: string } in categoryDetails do
				local option = CreateOption(option_name)
				currentSelected[category_name] = false

				if EquippedList[category_name] == optionInfo then
					print("equipped!")
					currentSelected[category_name] = option
				end

				option.Activated:Connect(function()
					if currentSelected[category_name] == option then
						CustomService:RemoveAccessory(category_name)
						EquippedList[category_name] = {}
						currentSelected[category_name] = false
					else
						CustomService:ApplyAccessory(category_name, optionInfo)
						EquippedList[category_name] = optionInfo
						currentSelected[category_name] = option
					end
					print(EquippedList[category_name])
				end)

				option.Parent = category.ScrollingFrame
			end
		end
	end)

	self.instance.Close.Activated:Connect(function()
		self:ToggleOpen(false)
		CustomService:SaveNewCustomization(EquippedList)
	end)

	self.instance.Unequip.Activated:Connect(function()
		EquippedList = {}
		CustomService:UnequipAllAccessories()

		for category_name: string, _ in currentSelected do -- here is the aforementioned dilemna i was facing. we gotta make all these false since it is being deselected
			currentSelected[category_name] = false
		end
	end)
end

return CustomDesigner
