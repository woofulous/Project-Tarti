local Test = {
	Name = "Test",
	Client = {},
}

function Test:KnitInit()
	print("Test Service init")
end

function Test:KnitStart()
	print("Test Service start")
end

return Test
