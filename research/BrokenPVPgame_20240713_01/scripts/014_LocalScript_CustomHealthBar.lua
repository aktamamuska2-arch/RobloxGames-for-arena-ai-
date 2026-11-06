-- StarterGui/CustomHealthBar
-- LocalScript in StarterPlayerScripts

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Function to create and setup the custom health bar UI
local function createHealthGui()
	-- Remove any existing custom health bar GUI
	if playerGui:FindFirstChild("CustomHealthGui") then
		playerGui.CustomHealthGui:Destroy()
	end

	-- Create a new ScreenGui for the custom health bar
	local customHealthGui = Instance.new("ScreenGui")
	customHealthGui.Name = "CustomHealthGui"
	customHealthGui.Parent = playerGui
	customHealthGui.ResetOnSpawn = true

	-- Create a new frame for the custom health bar
	local customHealthFrame = Instance.new("Frame")
	customHealthFrame.Name = "CustomHealthFrame"
	customHealthFrame.Size = UDim2.new(0.3, 0, 0.01, 0) -- Adjust the size as needed
	customHealthFrame.Position = UDim2.new(0.35, 0, 0.85, 0) -- Adjust the position as needed
	customHealthFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	customHealthFrame.BorderSizePixel = 2
	customHealthFrame.Parent = customHealthGui

	-- Create the health bar inside the custom frame
	local customHealthBar = Instance.new("Frame")
	customHealthBar.Name = "CustomHealthBar"
	customHealthBar.Size = UDim2.new(1, 0, 1, 0)
	customHealthBar.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	customHealthBar.BorderSizePixel = 0
	customHealthBar.Parent = customHealthFrame

	return customHealthBar
end

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
local blinking = false
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

-- Update the custom health bar based on the player's health
local function updateHealth(customHealthBar)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local health = humanoid.Health
			local maxHealth = humanoid.MaxHealth
			local healthPercent = (health / maxHealth) * 100
			customHealthBar.Size = UDim2.new(health / maxHealth, 0, 1, 0)
			updateHealthColor(customHealthBar, healthPercent)
			if healthPercent < 10 then
				startBlinking(customHealthBar)
			else
				stopBlinking()
			end
		end
	end
end

-- Connect the health changed event
local function onCharacterAdded(character)
	local customHealthBar = createHealthGui()
	local humanoid = character:WaitForChild("Humanoid")
	humanoid.HealthChanged:Connect(function()
		updateHealth(customHealthBar)
	end)
	updateHealth(customHealthBar)
end

player.CharacterAdded:Connect(onCharacterAdded)

-- Ensure the health bar updates if the script runs after the character has spawned
if player.Character then
	onCharacterAdded(player.Character)
end
