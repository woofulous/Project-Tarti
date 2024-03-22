--[[
	Manage the teaming of players & other team-related instances
]]

local Teams = game:GetService("Teams")

local TeamService = {
	Name = "TeamService",
	Client = {},
}

function TeamPlayerTo(player: Player, desired_team: string)
	local realTeam = Teams[desired_team]

	if realTeam then
		player.Team = realTeam
		return true
	end

	print("trying to team a player to a team which does not exist:", desired_team)
end

function TeamService.Client:SwitchTeam(player: Player, desired_team)
	-- run some client checks
	return TeamPlayerTo(player, desired_team) or false -- if teamplayerto doesnt return true, make it return false instead
end

return TeamService
