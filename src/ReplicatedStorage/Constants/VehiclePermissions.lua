-- A table of all the permissions related to vehicles, such as what team gets what and which groups can enter cars

return {
	-- [Team name] = { table of car names }
	TEAM_CARS = {
		["Defenders"] = {
			"Car",
		},
		["Raiders"] = {},
	},
	-- [GroupId] = { table of cars, separated }
	GROUP_CARS = {},
}
