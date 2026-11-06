-- StarterPlayer/StarterPlayerScripts/Camera
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Wait for the character to load
local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Variables for camera effects
	local bobbingFrequency = 2
	local bobbingAmplitude = 0.2
	local bobbingSpeed = 2

	local decaySpeed = 0.1
	local targetCFrame = camera.CFrame

	-- Function for camera bobbing
	local function getBobbingOffset()
		local speed = humanoid.MoveDirection.Magnitude * bobbingSpeed
		local offset = Vector3.new(
			0,
			math.sin(tick() * bobbingFrequency * speed) * bobbingAmplitude,
			0
		)
		return offset
	end

	-- Function to update the camera
	local function updateCamera(dt)
		-- Slow decay for turning
		local currentCFrame = camera.CFrame
		camera.CFrame = currentCFrame:Lerp(targetCFrame, decaySpeed * dt)

		-- Bobbing effect
		local bobbingOffset = getBobbingOffset()
		camera.CFrame = camera.CFrame * CFrame.new(bobbingOffset)
	end

	-- Update target CFrame on mouse movement
	UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Delta
			local cameraRot = CFrame.Angles(0, -math.rad(delta.X), 0)
			targetCFrame = targetCFrame * cameraRot
		end
	end)

	-- Update the camera every frame
	RunService.RenderStepped:Connect(function(dt)
		updateCamera(dt)
	end)
end

-- Connect character added event
player.CharacterAdded:Connect(onCharacterAdded)

-- If the character is already loaded
if player.Character then
	onCharacterAdded(player.Character)
end
