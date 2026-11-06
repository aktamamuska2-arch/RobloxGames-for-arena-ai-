-- StarterPlayer/StarterPlayerScripts/DisableNames
-- Get the player
local player = game.Players.LocalPlayer

-- Function to handle when the "Tab" key is pressed
local function onTabPressed(input)
	if input.KeyCode == Enum.KeyCode.Tab then
		-- Prevent default behavior of showing leaderboard
		return Enum.ContextActionResult.Sink
	end
end

-- Connect the function to the InputBegan event
game:GetService("UserInputService").InputBegan:Connect(onTabPressed)

-- Function to disable player names above heads
local function disablePlayerNames()
	-- Get all players
	local players = game.Players:GetPlayers()

	-- Loop through each player
	for _, player in ipairs(players) do
		-- Get the character and humanoid of the player
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
			end
		end
	end
end

-- Call the function once when the LocalScript runs
disablePlayerNames()
