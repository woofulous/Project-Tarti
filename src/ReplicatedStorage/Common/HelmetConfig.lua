--[[
	handle automated application of decorations
	this wasnt made by me. there was no credit anywhere. not sure who made it. maybe wulfrath? or oxy. idk
]]

local Module = {}

local Values = {
	Piping = {
		Infantry = {
			Value = Color3.fromRGB(216, 216, 216),
			Groups = {
				16308038, --GT
				16314664, --FMH
				14763247, --33.RG Gren Div
				32056729, --67.RG Mech Div
				16803561, --RGD
				17216336, --BP
				17144992, --18RG Arm-Gren Div
			},
		},
		Arm_Gren = {
			Value = Color3.fromRGB(44, 101, 29),
			Groups = {
				32563272, --16.RG Arm-Gren Div
			},
		},
		Alpine = {
			Value = Color3.fromRGB(0, 139, 0),
			Groups = {
				17144992, --188.RG Alpine Div
				15980681, --12. Mountaineers
			},
		},
		FP = {
			Value = Color3.fromRGB(191, 112, 38),
			Groups = {
				16340586, --Paratroop FP
				17219562, --FP-GT
				32366596, --FP-RGD
				32989252, --4.RG Police Div
				16328385, -- FP-FmH
			},
		},
		MarineFP = {
			Value = Color3.fromRGB(202, 171, 92),
			Groups = {
				16340583, --Marine FP
			},
		},
		Armoured = {
			Value = Color3.fromRGB(255, 154, 205),
			Groups = {
				17191161, -- FMH Armoured Reg
				15408352, --1.RG Armoured Div
				16675902, -- 50.RG Armoured Reg
				16675951, --57.RG Tank Hunter Reg
				16313287, --Parachute Armoured Div
				32027316, --29.RG Armoured Div
				16315705, --21. Armoured Div
				33340702, --5. RG-Armoured
			},
		},
		Pioneers = {
			Value = Color3.fromRGB(51, 51, 51),
			Groups = {
				17191161, -- GT Pioneers
			},
		},
		Assault = {
			Value = Color3.fromRGB(136, 13, 13),
			Groups = {
				32586366, --36.RG Assault Reg
			},
		},
		Artillery = {
			Value = Color3.fromRGB(193, 43, 38),
			Groups = {
				16323028, -- GT Artillery Reg
				16313281, -- 5. Flak
				16314657, -- FMH Artillery Reg
			},
		},
		Airforce = {
			Value = Color3.fromRGB(255, 207, 15),
			Groups = {
				16313291, -- 1.PD
				16414714, -- 6.FW
			},
		},
		Military_Intel = {
			Value = Color3.fromRGB(3, 72, 54),
			Groups = {
				16328019, -- CMI
			},
		},
		Recon_Cav = {
			Value = Color3.fromRGB(216, 197, 86),
			Groups = {
				16083243, --3.CAV
				17191141, -- FMH Recon
				17034805, --45.RG
				33701879, -- Parachute Recon Bat (Airforce)
				33369277, -- Recon "Blitzen" (FTG- Army)
				17169194, -- Recon "Frisia" (Frankland- Army)
				33768368, -- 16. Signals
			},
		},
	},
	Camo = {
		Green = {
			Value = "rbxassetid://12824991030",
			Groups = {
				32447813, --XI corp
				14763247, --33.RG
				32056729, --67.RG
			},
		},
		OrangeIsTheNewBlack = {
			Value = "rbxassetid://12824982012",
			Groups = {
				32443734, --Icorp
				15408352, --1.RG
				32563272, --16.RG
			},
		},
	},
	Shield = {
		France = {
			Value = "http://www.roblox.com/asset/?id=12145281835",
			Groups = {
				14763247, --33.RG
			},
		},
		PCLeutgard = {
			Value = "rbxassetid://13076874171",
			Groups = {
				32682629,
				32682628,
			},
		},
		Leutgard = {
			Value = "rbxassetid://12200320303",
			Groups = {
				15408352, --1.RG
				16359774, --UG-STL
			},
		},
		GTGrenadier = {
			Value = "rbxassetid://14288487838",
			Groups = {
				16308038, --GT Grenadier
			},
		},
		GTArtillery = {
			Value = "rbxassetid://14288488174",
			Groups = {
				16323028, --GT Artillery
			},
		},
		GTPioneer = {
			Value = "rbxassetid://14288488481",
			Groups = {
				32628282, --GT Pioneer
			},
		},
		FP = {
			Value = "http://www.roblox.com/asset/?id=13335763232",
			Groups = {
				16340583, --Marine FP
				16340586, --Paratroop FP
			},
		},
		FPFMH = {
			Value = "rbxassetid://14291550500",
			Groups = {
				16328385,
			},
		},
		FPGT = {
			Value = "rbxassetid://14291549847",
			Groups = {
				17219562, --FP-GT
			},
		},
		FPRGD = {
			Value = "rbxassetid://14291550131",
			Groups = {
				32366596, --FP-RGD
			},
		},
		FW = {
			Value = "http://www.roblox.com/asset/?id=13444532469",
			Groups = {
				16313291,
			},
		},
		AssCompany = {
			Value = "rbxassetid://14069691674",
			Groups = {
				15222225,
			},
		},
		PD = {
			Value = "rbxassetid://14069691674",
			Groups = {
				16414714,
			},
		},
		CAD = {
			Value = "http://www.roblox.com/asset/?id=13745853978",
			Groups = {
				16317910,
			},
		},
		Marine = {
			Value = "http://www.roblox.com/asset/?id=12780383176",
			Groups = {
				16317912,
			},
		},
		ARBFMH = {
			Value = "rbxassetid://14291640679",
			Groups = {
				17191141,
			},
		},
		GRFMH = {
			Value = "rbxassetid://14291551918",
			Groups = {
				16314664,
			},
		},
		ARFMH = {
			Value = "rbxassetid://14291550799",
			Groups = {
				17191161,
			},
		},
		UGR = {
			Value = "rbxassetid://14291549435",
			Groups = {
				16460568,
			},
		},
		UGM = {
			Value = "rbxassetid://12085308747",
			Groups = {
				16303657,
			},
		},
		UGFMH = {
			Value = "rbxassetid://12085308747",
			Groups = {
				15924807,
			},
		},
		RLM = {
			Value = "rbxassetid://14211989689",
			Groups = {
				32563272, --16.RG
			},
		},
		Poland = {
			Value = "rbxassetid://13317915807",
			Groups = {
				32056729, --67.RG
			},
		},
		BlackPrince = {
			Value = "http://www.roblox.com/asset/?id=14518791433",
			Groups = {
				17216336, --BP.RG
			},
		},
		Lithuania = {
			Value = "rbxassetid://13317921205",
			Groups = {
				32056758, -- 75.RG
			},
		},
		Liferegiment = {
			Value = "rbxassetid://12200320303",
			Groups = {
				15408403, -- 1.lg
			},
		},
		lenset = {
			Value = "rbxassetid://14649781873",
			Groups = {
				15629676, -- lenset
			},
		},
		blackprince = {
			Value = "rbxassetid://14649790522",
			Groups = {
				17216336, -- blackprince
			},
		},
		RGFP = {
			Value = "rbxassetid://13064951282",
			Groups = {
				32989252, --4.rg
			},
		},
	},
}

function GetValue(Player, Type)
	for _, V in Values[Type] do
		for _, Group in V.Groups do
			if Player:IsInGroup(Group) then
				return V.Value
			end
		end
	end
end

function Module.Setup(Item, Player)
	local Piping = Item:FindFirstChild("Piping")
	local Camo = Item:FindFirstChild("Camo")
	local Shield = Item:FindFirstChild("Shield")
	if Piping then
		local Value = GetValue(Player, "Piping")
		if Value then
			Piping.Color = Value
		end
	end
	if Camo then
		local Value = GetValue(Player, "Camo")
		if Value then
			Camo.TextureID = Value
		end
	end
	if Shield then
		local Value = GetValue(Player, "Shield")
		if Value then
			Shield.Decal.Texture = Value
		end
	end
end

return Module
