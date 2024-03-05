local Players = game:GetService("Players")

-- Loop through and call "added" on all current players, returns tuple of added and removing rbxscriptconnections
return function(added: (player: Player) -> (), removing: (player: Player) -> ()?)
	for _, player in Players:GetPlayers() do
		added(player)
	end

	local addedConnection: RBXScriptConnection
	if added then
		addedConnection = Players.PlayerAdded:Connect(added)
	end

	local removingConnection
	if removing then
		removingConnection = Players.PlayerRemoving:Connect(removing)
	end

	return addedConnection, removingConnection
end
