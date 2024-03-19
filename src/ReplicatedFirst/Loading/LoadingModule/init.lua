--[[
	Handle the LoadingScreen operations
]]

local BACKGROUND_CHANGE_TIME = 3 -- time between each time the loadingscreen background changes in seconds

local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage:WaitForChild("Packages").Knit) -- need to wait since we are doing this in replicatedfirst, so this may not be loaded yet
local Promise = require(ReplicatedStorage.Packages.Promise)

local PreloadList = require(script.Parent.PreloadList)
local LoadingContent = require(script.Parent.LoadingContent)

local changingDecorPromise --: promiseobject
local maxProgressIndex: number
local previousBackgroundIndex: number -- the last index of the background based on LoadingContent.Images
local previousTipIndex: number -- this is the same as above ^

local LoadingModule = {}
LoadingModule.instance = script.LoadingScreen
LoadingModule.running = false

local function setRandomBackgroundIndex()
	local pluckedIndex: number

	repeat
		pluckedIndex = math.random(1, #LoadingContent.Images)
	until previousBackgroundIndex ~= pluckedIndex

	previousBackgroundIndex = pluckedIndex
end

local function setRandomTipIndex()
	local pluckedIndex: number

	repeat
		pluckedIndex = math.random(1, #LoadingContent.Tips)
	until previousTipIndex ~= pluckedIndex

	previousTipIndex = pluckedIndex
end

-- start an asynchronous operation to loop through and apply random backgrounds to the instance. it also goes thru and gets random tip strings from LoadingContent and applies those too
local function startChangingDecor()
	LoadingModule.running = true
	local background = LoadingModule.instance.BackgroundImage :: ImageLabel
	local tipLabel = LoadingModule.instance.TipFrame.TipLabel :: TextLabel

	changingDecorPromise = Promise.new(function(_, _, onCancel)
		onCancel(function()
			LoadingModule.running = false
		end)

		while LoadingModule.running do
			setRandomBackgroundIndex() -- sets previousBackgroundIndex to a random number
			background.Image = LoadingContent.Images[previousBackgroundIndex]

			setRandomTipIndex()
			tipLabel.Text = LoadingContent.Tips[previousTipIndex]

			task.wait(BACKGROUND_CHANGE_TIME)
		end
	end)
end

-- syncronously preload the asset with no yield
local function promisePreloadAsset(asset: Instance)
	return Promise.new(function(resolve, reject)
		local success, _ = pcall(function()
			return ContentProvider:PreloadAsync(asset)
		end)

		if not success then
			reject()
		else
			resolve()
		end
	end)
end

-- Use .OnStart promise to await for knit to load
function LoadingModule.awaitForKnit()
	print("waiting for knit")
	Knit.OnStart():await() -- If Knit has already started, this will still complete itself
	print("Knit has started")
end

-- Loop thru PreloadList and PreloadAsync all of its contents
function LoadingModule.startPreloadingAsync()
	print("start preloading assets")
	for _, asset in PreloadList do
		promisePreloadAsset(asset):await() -- wait for the loading to finish
	end

	-- for _, backgroundImage in LoadingContent.Images do
	-- 	promisePreloadAsset(backgroundImage):await()
	-- end
end

-- Set a new max index which will be divided by when UpdateProgressIndex
function LoadingModule.setMaxProgressIndex(new_index: number)
	maxProgressIndex = new_index
end

-- Take maxProgressIndex and divide it by the given index. If status_text, update the Progress label with it
function LoadingModule:UpdateProgressIndex(index: number, status_text: string?)
	self.instance.ProgressFrame.FillerFrame.Size = UDim2.fromScale(index / maxProgressIndex, 1)
	self.instance.ProgressFrame.ProgressLabel.Text = status_text or ""
end

-- Enable or disable the loading screen
function LoadingModule:ToggleVisible(visible: boolean)
	local PlayerGui = Knit.Player:WaitForChild("PlayerGui")

	if visible then
		print("Parent loading screen to", Knit.Player)
		self.instance.Parent = PlayerGui

		startChangingDecor()
	else
		print("Remove loading screen from", Knit.Player)
		self.instance.Parent = script

		if changingDecorPromise.Status == "Running" then
			changingDecorPromise:cancel()
		end
	end
end

return LoadingModule
