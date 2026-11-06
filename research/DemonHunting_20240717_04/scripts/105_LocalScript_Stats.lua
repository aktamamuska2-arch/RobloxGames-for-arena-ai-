-- StarterGui/MainGui/Icons/Stats
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local Button
local CloseButton
local playerLevel
local pointsAvailable

local function initialize()
	Button = player.PlayerGui:WaitForChild("MainGui"):WaitForChild("Icons"):WaitForChild("StatsButton")
	CloseButton = player.PlayerGui.StatsGui.UpgradeFrame.Close
	upgradeFrame = player.PlayerGui.StatsGui.UpgradeFrame

	handleUpgrade(upgradeFrame.UpgradeHealth, "MaxHealth")
	handleUpgrade(upgradeFrame.UpgradeEnergy, "MaxEnergy")
	handleUpgrade(upgradeFrame.UpgradeStrength, "Strength")
	handleUpgrade(upgradeFrame.UpgradeAgility, "Agility")
	handleUpgrade(upgradeFrame.UpgradeSoul, "Soul")

	Button.MouseButton1Click:Connect(function()
		upgradeFrame.Visible = true
		updateDisplays()
	end)

	CloseButton.MouseButton1Click:Connect(function()
		upgradeFrame.Visible = false
	end)
end

function updateDisplays()
	if not upgradeFrame then return end
	playerLevel = getPlayerLevel(player:FindFirstChild("XP").Value)
	pointsAvailable = 2 * playerLevel - player:FindFirstChild("PointsUsed").Value

	if not upgradeFrame:FindFirstChild("PointsAvailable") then return end
	upgradeFrame.PointsAvailable.Text = "Available Points: " .. tostring(pointsAvailable)
	upgradeFrame.PlayerHealth.Text = tostring(player:FindFirstChild("MaxHealth").Value)
	upgradeFrame.PlayerEnergy.Text = tostring(player:FindFirstChild("MaxEnergy").Value)
	upgradeFrame.PlayerStrength.Text = tostring(player:FindFirstChild("Strength").Value)
	upgradeFrame.PlayerAgility.Text = tostring(player:FindFirstChild("Agility").Value)
	upgradeFrame.PlayerSoul.Text = tostring(player:FindFirstChild("Soul").Value)

	if pointsAvailable > 0 then
		upgradeFrame.UpgradeHealth.Visible = true
		upgradeFrame.UpgradeEnergy.Visible = true
		upgradeFrame.UpgradeStrength.Visible = true
		upgradeFrame.UpgradeAgility.Visible = true
		upgradeFrame.UpgradeSoul.Visible = true
	else
		upgradeFrame.UpgradeHealth.Visible = false
		upgradeFrame.UpgradeEnergy.Visible = false
		upgradeFrame.UpgradeStrength.Visible = false
		upgradeFrame.UpgradeAgility.Visible = false
		upgradeFrame.UpgradeSoul.Visible = false
	end
end

function handleUpgrade(button, stat)
	local debounce = false
	button.MouseButton1Click:Connect(function()
		if not debounce then
			debounce = true
			game.ReplicatedStorage.Events.UpgradeStat:FireServer(stat)
			print(player.Name .. " upgraded their " .. stat)
			wait(0.1)  -- Small delay to ensure the server processes the change
			updateDisplays()
			debounce = false
		end
	end)
end

function getPlayerLevel(xp)
	local level = 0
	while xp >= 100 * ((level + 1) ^ 1.5) do
		level = level + 1
	end
	return level
end

-- Initialize the UI elements and connections
initialize()

-- Reinitialize when the player respawns
Players.LocalPlayer.CharacterAdded:Connect(function()
	wait(1) -- Give some time for the GUI to load
	initialize()
end)
