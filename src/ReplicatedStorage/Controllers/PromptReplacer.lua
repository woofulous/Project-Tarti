--[[
	Use ProximityPromptService to replace & handle default prompts with custom ones.
	Since there can be a lot of prompts throughout the time the player is playing we cache our prompts after they've been cloned from .prefab, parenting them to the script.
	When we need a prompt, we check the script if we have any to spare and take them from there. If not, we make a new one and add it to the cache.
	So, if the player sees 5 different prompts that are constantly being shown and hidden, instead of calling 5 :Clone operations in rapid succession, they simply use 5 .Parent property changes.
	In this way, we avoid mass :Clone operations by limiting the amount of times we need to, instead using .Parent operations which are much faster and performant.
]]

local ProximityPromptService = game:GetService("ProximityPromptService")

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local PromptReplacer = {
	Name = "PromptReplacer",
}
PromptReplacer.prefab = script.Prompt

-- See if there is a spare prompt in the script, if not, clone from .prefab
local function getPromptGui()
	local prompt: BillboardGui = script:FindFirstChild(PromptReplacer.prefab.Name)
	do
		if not prompt then
			prompt = PromptReplacer.prefab:Clone()
		end
	end

	return prompt
end

function PromptReplacer:KnitStart()
	local Interface = Knit.GetController("Interface")

	ProximityPromptService.PromptShown:Connect(
		function(prompt: ProximityPrompt, inputType: Enum.ProximityPromptInputType)
			if prompt.Style ~= Enum.ProximityPromptStyle.Custom then -- Prompt is using the "Default" style. Avoid tampering
				return
			end

			print("Show the prompt")
			local promptGui = getPromptGui()
			promptGui.Adornee = prompt.Parent -- set the custom prompt Gui to the prompt's parent
			promptGui.Parent = Interface.root

			-- We can connect a .PromptHidden event internally to avoid using the service's event. This is a more direct way to hide the prompt, avoiding potential overfiring
			prompt.PromptHidden:Once(function()
				print("Hide the prompt")
				promptGui.Parent = script -- This adds it to the "cache" for future use
			end)
		end
	)
end

return PromptReplacer
