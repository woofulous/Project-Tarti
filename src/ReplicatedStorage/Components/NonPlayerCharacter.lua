--[[
	This component interacts with DialogController to chat with NPCs.
	NPCService ensures that all NPCs in the experience have the correct prompts and IKControl
	The DialogTree is passed to the DialogController to be used
]]

local DEFAULT_GOODBYE = "Goodbye!"

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Component = require(ReplicatedStorage.Packages.Component)

local NPCFolder = game:GetService("Workspace").Studio.NPCs

local NonPlayerCharacter = Component.new({
	Tag = "NonPlayerCharacter",
	Ancestors = { NPCFolder },
	Extensions = {},
})

-- create a table filled with all of the choice's properties for easy access
function CreateChoiceTree(choice: DialogChoice)
	local tree = {}
	tree.userChoices = { choice.UserDialog }
	tree.response = choice.ResponseDialog

	if choice.GoodbyeChoiceActive then
		if choice.GoodbyeDialog ~= "" then -- dialogchoices dont have a nil property if there is no text in the field
			tree.goodbye = choice.GoodbyeDialog
		else
			tree.goodbye = DEFAULT_GOODBYE
		end
	end

	return tree
end

-- recursively go through all descendants and construct the dialog tree
local function processChoice(choice)
	local choiceTree = CreateChoiceTree(choice)
	local choiceChildren = choice:GetChildren()

	if #choiceChildren > 0 then
		choiceTree.userChoices = {} -- reset userChoices for sub-choices

		for _, subChoice in ipairs(choiceChildren) do
			table.insert(choiceTree.userChoices, processChoice(subChoice))
		end
	end

	return choiceTree
end

function NonPlayerCharacter:Construct()
	self.prompt = self.Instance:FindFirstChildOfClass("ProximityPrompt") :: ProximityPrompt
	self.ikControl = self.Instance:FindFirstChildOfClass("IKControl") :: IKControl
	-- npc "looking" (when in range of the prompt, set IKControl target to the player)
	local fallbackTarget = Instance.new("Attachment") -- create a new target for the npc to fallback to when there is none
	fallbackTarget.CFrame = CFrame.new(0, 1.5, -1) -- 1 stud infront of the npc's head
	fallbackTarget.Parent = self.Instance:WaitForChild("HumanoidRootPart")
	self.ikControl.Target = fallbackTarget

	self.prompt.PromptShown:Connect(function() -- lookAtPlayer
		local character = Knit.Player.Character
		if not character or not character.Head then
			return -- cannot look, no character to look at, or the player head doesnt exist
		end

		self.ikControl.Target = character.Head

		-- internally disconnect the look event
		self.prompt.PromptHidden:Connect(function()
			self.ikControl.Target = fallbackTarget -- revert the look stance to normal
		end)
	end)
	-- construct convo tree (this one a lil tricky)
	local dialog = self.Instance:FindFirstChildOfClass("Dialog") :: Dialog
	self.prompt.MaxActivationDistance = dialog.ConversationDistance

	self.dialogTree = {}
	self.dialogTree.response = dialog.InitialPrompt
	self.dialogTree.userChoices = {}

	if dialog.GoodbyeDialog == "" then -- ensure the player can actually exit dialog
		self.dialogTree.goodbye = dialog.GoodbyeDialog
	else
		self.dialogTree.goodbye = DEFAULT_GOODBYE
	end

	for _, choice in ipairs(dialog:GetDescendants()) do -- go thru all descendants and create a new tree for each
		table.insert(self.dialogTree.userChoices, processChoice(choice))
	end

	print(self.dialogTree)
end

function NonPlayerCharacter:Start()
	local DialogController = Knit.GetController("DialogController")

	self.prompt.Triggered:Connect(function() -- main startup for npcs
		DialogController.speakToNPCAsync(self.Instance, self.dialogTree)
	end)
end

function NonPlayerCharacter:Stop() end

return NonPlayerCharacter