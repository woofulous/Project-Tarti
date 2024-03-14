--[[
	This listens for events from the NPCService to start talking to an NPC and prepares then fires events back to the server through ModuleScripts located in the DialogTree
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

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local choicePrefab = script.DialogChoiceButton :: TextButton
local slideInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.InOut)

local npcBubblePart: BasePart

local NPCDialog = {
	Name = "NPCDialog",
}
NPCDialog.instance = script.DialogFrame
NPCDialog._buttons = {}

function CreateChoiceButton(text: string, callback: () -> ())
	local button = choicePrefab:Clone()
	button.Text = text
	button.Activated:Once(callback)

	table.insert(NPCDialog._buttons, button)
	button.Parent = NPCDialog.instance.ChoiceOptions
	return button
end

local function clearCurrentTree()
	for _, button: TextButton in NPCDialog._buttons do
		button:Destroy()
	end
end

local function fillChoiceTree(tree: dialogTree)
	print("speak for the npc:", tree.response)
	TextChatService:DisplayBubble(npcBubblePart, tree.response)
	clearCurrentTree()
	print(tree)

	for _, choice: dialogTree in tree.userChoices do
		print(choice)

		local button = CreateChoiceButton(choice.user, function()
			print("speak for the user:", choice.user)
			TextChatService:DisplayBubble(Knit.Player.Character, choice.user)

			if choice.action == "Close" then
				NPCDialog:CloseDialogScreen()
			elseif choice.action == "Continue" then
				clearCurrentTree()
				fillChoiceTree(choice)
			else
				print("unk actionType:", choice.action, choice)
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

		NPCDialog:CloseDialogScreen()
	end)
end

-- Hides all prompts & springs the camera to the set NPC. Yields until completion
function NPCDialog.speakToNPCAsync(npc: Model, dialogTree: dialogTree)
	print("speak to npc:", npc)
	assert(npc.PrimaryPart, "THIS NPC **NEEDS** A PRIMARY PART")
	npcBubblePart = npc.PrimaryPart

	NPCDialog:OpenScreen(dialogTree)
end

-- Tween open the interface
function NPCDialog:OpenScreen(dialogTree: dialogTree)
	print("opening screen while currentTree is:", dialogTree)
	self.instance.Parent = self.root

	local slideIn = TweenService:Create(self.instance, slideInfo, { AnchorPoint = Vector2.new(0, 1) })

	fillChoiceTree(dialogTree)
	slideIn:Play()
end

-- Tween close the interface
function NPCDialog:CloseDialogScreen()
	local slideOut = TweenService:Create(self.instance, slideInfo, { AnchorPoint = Vector2.new(0, 0) })

	slideOut.Completed:Connect(function()
		self.instance.Parent = script
		clearCurrentTree()
	end)

	slideOut:Play()
	print("return camera to normal")
end

return NPCDialog
