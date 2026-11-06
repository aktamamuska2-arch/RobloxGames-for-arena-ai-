-- StarterGui/StatsGui/LevelScript
-- LocalScript inside StatsGui

-- Services
local Players = game:GetService("Players")

-- Player and GUI elements
local player = Players.LocalPlayer
local levelFrame = script.Parent:WaitForChild("LevelFrame")
local levelProgress = levelFrame:WaitForChild("LevelProgress")
local levelText = levelFrame:WaitForChild("TextLabel")

-- Variables
local baseXP = 100
local exponent = 1.5
local maxLevel = 20

-- Function to calculate XP required for the next level
local function calculateXPRequired(level)
	return baseXP * (level ^ exponent)
end

-- Function to determine level and progress based on XP
local function updateLevelAndProgress()
	local playerXP = player:FindFirstChild("XP")
	if playerXP then
		local xp = playerXP.Value
		local level = 0

		-- Determine the player's current level
		while level < maxLevel and xp >= calculateXPRequired(level + 1) do
			level = level + 1
		end

		-- Update level text
		if level == maxLevel then
			levelText.Text = "Lv " .. tostring(maxLevel) .. " (max)"
		else
			levelText.Text = "Lv " .. tostring(level)
		end

		-- Calculate progress towards the next level
		local currentLevelXP = calculateXPRequired(level)
		local nextLevelXP = calculateXPRequired(level + 1)
		local progress = (xp - currentLevelXP) / (nextLevelXP - currentLevelXP)

		-- Update progress bar
		levelProgress.Size = UDim2.new(progress, 0, 1, 0)
	end
end

-- Update when player's XP changes
local function onXPChanged()
	updateLevelAndProgress()
end

-- Wait for the XP value to be added to the player
local function onCharacterAdded(character)
	local playerXP = character:WaitForChild("XP")
	playerXP.Changed:Connect(onXPChanged)
	updateLevelAndProgress()
end

-- Connect to CharacterAdded event
player.CharacterAdded:Connect(onCharacterAdded)

-- Initial update if character is already loaded
if player.Character then
	onCharacterAdded(player.Character)
end