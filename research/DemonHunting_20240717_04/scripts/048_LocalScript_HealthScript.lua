-- StarterGui/StatsGui/HealthScript
-- LocalScript inside StatsFrame

-- Services
local Players = game:GetService("Players")

-- Player and GUI elements
local player = Players.LocalPlayer
local statsFrame = script.Parent:WaitForChild("StatsFrame")
local healthFrame = statsFrame:WaitForChild("AHealth")
local healthLevel = healthFrame:WaitForChild("HealthLevel")
local healthTextLabel = healthFrame:WaitForChild("TextLabel")

-- Variables
local baseXP = 100
local exponent = 1.5
local maxLevel = 20
local blinking = false

-- Function to update the color based on health percentage
local function updateHealthColor(customHealthBar, healthPercent)
	if healthPercent > 80 then
		customHealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	elseif healthPercent > 50 then
		customHealthBar.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
	elseif healthPercent > 20 then
		customHealthBar.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
	else
		customHealthBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	end
end

-- Function to handle blinking effect
local function startBlinking(customHealthBar)
	if not blinking then
		blinking = true
		spawn(function()
			while blinking do
				customHealthBar.Visible = not customHealthBar.Visible
				wait(0.1)
			end
			customHealthBar.Visible = true
		end)
	end
end

local function stopBlinking()
	blinking = false
end

-- Function to update health UI
local function updateHealthUI()
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local currentHealth = humanoid.Health
			local maxHealth = humanoid.MaxHealth
			local healthPercent = (currentHealth / maxHealth) * 100

			-- Update the TextLabel
			healthTextLabel.Text = "Health: " .. tostring(math.floor(currentHealth)) .. "/" .. tostring(math.floor(maxHealth))

			-- Update the HealthLevel frame size
			healthLevel.Size = UDim2.new(currentHealth / maxHealth, 0, 1, 0)

			-- Update the HealthLevel frame color
			updateHealthColor(healthLevel, healthPercent)

			-- Handle blinking effect
			if healthPercent < 10 then
				startBlinking(healthLevel)
			else
				stopBlinking()
			end
		end
	end
end

-- Function to connect to character and health changes
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(updateHealthUI)
	humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealthUI)
	updateHealthUI()
end

-- Connect to CharacterAdded event
player.CharacterAdded:Connect(onCharacterAdded)

-- Initial update if character is already loaded
if player.Character then
	onCharacterAdded(player.Character)
end
