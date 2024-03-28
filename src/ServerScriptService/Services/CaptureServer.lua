--[[
	Manage the math behind capture points, such as progress tick and capture stages
	Lucereus 03/27/2024
]]

export type TeamStats = {
	contributors: number,
	progress: number,
}

local PROGRESS_THRESHOLD = 100 -- max amount of progress allowed by all team progression added together before there can be new progress added. consider this the "health" of each point
local INDIVIDUAL_CONTRIBUTION = 1 -- the amount of progress each individual on the point will give their team's progression towards capture, every servertick

local Knit = require(game:GetService("ReplicatedStorage").Packages.Knit)

local CapturePoints = game:GetService("Workspace").Studio.CapturePoints

local CaptureServer = {
	Name = "CaptureServer",
	Client = {
		PointOfContention = Knit.CreateProperty("Castle"), -- this is the default point of contention at the start of the game
		KingOfTheHill = Knit.CreateProperty(nil), -- no king
		ContributingTeams = Knit.CreateProperty({}), -- the list of teams contributing to capture
	},
}
CaptureServer.Progression = {
	KingOfTheHill = "", -- the team which holds the most amount of contributors. when the progress threshold is met, this team will begin to eat off the progression of other teams
	ContributingTeams = {}, -- a table of teams, which returns the number of contributers from said team, and the individual progress for that team
	OverallProgress = 0, -- the progress of all teams added together. this is used to ensure each team does not exceed the threshold at the top of the script.
} :: {
	KingOfTheHill: string,
	ContributingTeams: { TeamStats },
	OverallProgress: number,
}

-- Progress the "King of the Hill" to eat points from each point based on the individual contribution modifier. this is similar to AddProgressToAllTeams, but we are removing instead, and ignoring the King of the Hill
function ProgressKotH()
	for team_name: string, teamStats: TeamStats in CaptureServer.Progression.ContributingTeams do
		local kothContributors = CaptureServer.Progression.ContributingTeams[CaptureServer.Progression.KingOfTheHill]

		if team_name ~= CaptureServer.Progression.KingOfTheHill then
			teamStats.progress -= kothContributors * INDIVIDUAL_CONTRIBUTION
			CaptureServer.Progression.ContributingTeams[CaptureServer.Progression.KingOfTheHill].progress += kothContributors * INDIVIDUAL_CONTRIBUTION
		end
	end
end

function AddProgressToAllTeams()
	for _, teamStats: TeamStats in CaptureServer.Progression.ContributingTeams do
		if CaptureServer.Progression.OverallProgress >= PROGRESS_THRESHOLD then
			return
		end

		teamStats.progress += INDIVIDUAL_CONTRIBUTION
		CaptureServer.Progression.OverallProgress += teamStats.contributors * INDIVIDUAL_CONTRIBUTION
	end
end

-- update the current point's progression
function UpdatePointProgress()
	local currentKing: string -- the team which holds the most amount of contributors
	local currentContributors = 0 -- a rapid changing number of contributors, assigned here \/

	for team_name: string, teamStats: TeamStats in CaptureServer.Progression.ContributingTeams do
		if teamStats.contributors > currentContributors then
			currentKing = team_name
			currentContributors = teamStats.contributors
			CaptureServer.Client.KingOfTheHill:Set(currentKing)
		end
	end

	CaptureServer.Progression.KingOfTheHill = currentKing

	if CaptureServer.Progression.OverallProgress >= PROGRESS_THRESHOLD then
		CaptureServer.Progression.OverallProgress = PROGRESS_THRESHOLD -- ensure that it doesnt exceed, because this value will be used to add/remove progress now

		ProgressKotH()
	else
		AddProgressToAllTeams()
	end

	CaptureServer.Client.ContributingTeams:Set(CaptureServer.Progression.ContributingTeams)
end

-- The player is asking to enter the capture point. This is validated by the server by checking if the player is currently inside, among other checks. It also then categorizes the amount of opposing agents in a point.
function CaptureServer.Client:EnterCapturePoint(player: Player) end

function CaptureServer.Client:LeaveCapturePoint(player: Player) end

function CaptureServer:KnitStart()
	local CoreLoop = Knit.GetService("CoreLoop")

	CoreLoop:OnServerTick(UpdatePointProgress)
end

return CaptureServer
