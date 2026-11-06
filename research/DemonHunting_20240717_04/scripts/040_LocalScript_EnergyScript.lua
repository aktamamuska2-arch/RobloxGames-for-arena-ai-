-- StarterGui/StatsGui/EnergyScript
-- LocalScript inside StatsFrame

-- Services
local Players = game:GetService("Players")

-- Player and GUI elements
local player = Players.LocalPlayer
local statsFrame = script.Parent:WaitForChild("StatsFrame")
local energyFrame = statsFrame:WaitForChild("BEnergy")
local energyLevel = energyFrame:WaitForChild("EnergyLevel")
local energyTextLabel = energyFrame:WaitForChild("TextLabel")

-- Variables
local blinking = false

-- Function to update the color based on energy percentage
local function updateEnergyColor(customEnergyBar, energyPercent)
	if energyPercent > 80 then
		customEnergyBar.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
	elseif energyPercent > 50 then
		customEnergyBar.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
	elseif energyPercent > 20 then
		customEnergyBar.BackgroundColor3 = Color3.fromRGB(0, 165, 255)
	else
		customEnergyBar.BackgroundColor3 = Color3.fromRGB(0, 0, 139)
	end
end

-- Function to handle blinking effect
local function startBlinking(customEnergyBar)
	if not blinking then
		blinking = true
		spawn(function()
			while blinking do
				customEnergyBar.Visible = not customEnergyBar.Visible
				wait(0.1)
			end
			customEnergyBar.Visible = true
		end)
	end
end

local function stopBlinking()
	blinking = false
end

-- Function to update energy UI
local function updateEnergyUI()
	local energy = player:FindFirstChild("Energy")
	local maxEnergy = player:FindFirstChild("MaxEnergy")
	if energy and maxEnergy then
		local currentEnergy = energy.Value
		local maxEnergyValue = maxEnergy.Value
		local energyPercent = (currentEnergy / maxEnergyValue) * 100

		-- Update the TextLabel
		energyTextLabel.Text = "Energy: " .. tostring(currentEnergy) .. "/" .. tostring(maxEnergyValue)

		-- Update the EnergyLevel frame size
		energyLevel.Size = UDim2.new(currentEnergy / maxEnergyValue, 0, 1, 0)

		-- Update the EnergyLevel frame color
		updateEnergyColor(energyLevel, energyPercent)

		-- Handle blinking effect
		if energyPercent < 10 then
			startBlinking(energyLevel)
		else
			stopBlinking()
		end
	end
end

-- Connect to energy value changes
local function onEnergyChanged()
	updateEnergyUI()
end

-- Connect to CharacterAdded event
local function onCharacterAdded(character)
	local energy = player:WaitForChild("Energy")
	local maxEnergy = player:WaitForChild("MaxEnergy")
	energy.Changed:Connect(onEnergyChanged)
	maxEnergy.Changed:Connect(onEnergyChanged)
	updateEnergyUI()
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Initial update if character is already loaded
if player.Character then
	onCharacterAdded(player.Character)
end