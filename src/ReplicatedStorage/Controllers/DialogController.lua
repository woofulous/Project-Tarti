--[[
	This listens for events from the NPCService to start talking to an NPC and prepares then fires events back to the server through ModuleScripts located in the DialogTree
	lucereus (03/11/2024)
]]

type dialogTree = {
	response: string,
	goodbye: string,
	user: string,
	userChoices: { dialogTree },
	action: string,
	callback: () -> ()?,
}

local TweenService = game:GetService("TweenService")
local TextChatService = game:GetService("TextChatService")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local choicePrefab = script.DialogChoiceButton :: TextButton
local slideInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

local npcBubblePart: BasePart | nil
local root: ScreenGui -- set to Interface.root

local DialogController = {
	Name = "DialogController",
}
DialogController.instance = script.DialogFrame
DialogController._buttons = {}

function CreateChoiceButton(text: string, callback: () -> ())
	local button = choicePrefab:Clone()
	button.Text = text
	button.Activated:Once(callback)

	table.insert(DialogController._buttons, button)
	button.Parent = DialogController.instance.ChoiceOptions
	return button
end

local function clearCurrentTree()
	for _, button: TextButton in DialogController._buttons do
		button:Destroy()
	end
end

local function fillChoiceTree(tree: dialogTree)
	print("speak for the npc:", tree.response)
	TextChatService:DisplayBubble(npcBubblePart, tree.response)
	clearCurrentTree()
	print(tree)

	if #tree.userChoices == 0 then -- similar to choice.action == "Close"
		DialogController:CloseDialogScreen()
	end

	for _, choice: dialogTree in tree.userChoices do
		print(choice)

		local button = CreateChoiceButton(choice.user, function()
			print("speak for the user:", choice.user)
			TextChatService:DisplayBubble(Knit.Player.Character, choice.user)

			if choice.action == "Close" then
				DialogController:CloseDialogScreen()
			elseif choice.action == "Continue" then
				clearCurrentTree()
				fillChoiceTree(choice)
			else
				print("unk actionType:", choice.action, choice)
				DialogController:CloseDialogScreen() -- so the player isnt caught in a broken dialog
			end
		end)

		if choice.callback then
			print("callback!")
			button.Activated:Once(choice.callback) -- this is for modulescripts
		end
	end

	CreateChoiceButton(tree.goodbye, function() -- no need to access this return
		print("say goodbye:", tree.goodbye)
		TextChatService:DisplayBubble(Knit.Player.Character, tree.goodbye)

		DialogController:CloseDialogScreen()
	end)
end

-- Hides all prompts & springs the camera to the set NPC. Yields until completion
function DialogController.speakToNPCAsync(npc: Model, dialogTree: dialogTree)
	print("speak to npc:", npc)
	npcBubblePart = npc.PrimaryPart

	DialogController:OpenScreen(dialogTree)
end

-- Tween open the interface
function DialogController:OpenScreen(dialogTree: dialogTree)
	print("opening screen while currentTree is:", dialogTree)
	self.instance.Parent = root
	ProximityPromptService.Enabled = false

	local slideIn = TweenService:Create(self.instance, slideInfo, { AnchorPoint = Vector2.new(0, 1) })

	fillChoiceTree(dialogTree)
	slideIn:Play()
end

-- Tween close the interface
function DialogController:CloseDialogScreen()
	local slideOut = TweenService:Create(self.instance, slideInfo, { AnchorPoint = Vector2.new(0, 0) })

	slideOut.Completed:Connect(function()
		clearCurrentTree()
	end)

	ProximityPromptService.Enabled = true
	npcBubblePart = nil
	slideOut:Play()
	print("return camera to normal")
end

function DialogController:KnitStart()
	local Interface = Knit.GetController("Interface")
	root = Interface.root
end

return DialogController
