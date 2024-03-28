--[[
	Handle all of the top-level game functionality
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local safePlayerAdded = require(ReplicatedStorage.Utility.safePlayerAdded)

local CoreLoop = {
	Name = "CoreLoop",
	Client = {
		PlayerAgreedToRules = Knit.CreateSignal(),
	},
}
CoreLoop.trackedFn = {} -- these are called each task.wait second
CoreLoop.TickRunning = false

local function playerAdded(player: Player)
	print(player, "has been added!")
end

local function playerRemoving(player: Player)
	print(player, "is being removed!")
end

function CallTrackedFunctions()
	for _, tickFn: () -> () in CoreLoop.trackedFn do
		task.defer(tickFn) -- push each tick function to a new thread. this makes it so the script will not yield to fire each of these functions, running synchronously
	end
end

function CoreLoop:OnServerTick(fn: () -> ()) -- onCancel, cancels the tick from the loop
	table.insert(self.trackedFn, fn)
	local fnIndex = #self.trackedFn

	return function()
		self.trackedFn[fnIndex] = nil
	end
end

function CoreLoop:KnitStart()
	local DataHandler = Knit.GetService("DataHandler")

	self.Client.PlayerAgreedToRules:Connect(function(player: Player)
		DataHandler:Set(player, "AgreedToRules", true)
	end)

	safePlayerAdded(playerAdded, playerRemoving)

	self.TickRunning = true
	while self.TickRunning and task.wait(2) do
		task.defer(CallTrackedFunctions) -- push it to a separate thread
	end
end

return CoreLoop
