-- StarterPlayer/StarterPlayerScripts/StuntsRoll
-- Example: StarterPlayerScripts > RandomAxisCartwheelScript (LocalScript)

local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")

local jumpHeight = math.random(7, 30) -- Height of the jump
local rollDistance = 1 -- Horizontal distance covered during the roll
local canRoll = true

local function performRandomCartwheel(humanoidRootPart)
	if canRoll then
		canRoll = false
		humanoidRootPart.CFrame = humanoidRootPart.CFrame * CFrame.new(0, jumpHeight, 0) -- Jump

		wait(0.4) -- Wait for the jump height to be reached

		local initialPosition = humanoidRootPart.Position
		local targetPosition = initialPosition + Vector3.new(math.random(-1, 1) * rollDistance, 0, math.random(-1, 1) * rollDistance)
		local startTime = tick()

		-- Choose a random axis and direction for the cartwheel
		local axes = {"X", "Y", "Z"}
		local chosenAxis = axes[math.random(1, #axes)]
		local direction = math.random(-1, 1)

		-- Perform a 360-degree cartwheel on the chosen axis
		local duration = 0.5 -- Duration of the cartwheel animation (adjust as needed)
		local endTime = startTime + duration
		while tick() < endTime do
			local elapsedTime = tick() - startTime
			local progress = elapsedTime / duration
			local angle = math.pi * 2 * progress * direction

			if chosenAxis == "X" then
				humanoidRootPart.CFrame = CFrame.new(initialPosition) * CFrame.Angles(angle, 0, 0)
			elseif chosenAxis == "Y" then
				humanoidRootPart.CFrame = CFrame.new(initialPosition) * CFrame.Angles(0, angle, 0)
			elseif chosenAxis == "Z" then
				humanoidRootPart.CFrame = CFrame.new(initialPosition) * CFrame.Angles(0, 0, angle)
			end

			wait(0.03)  -- Adjust the speed of the cartwheel rotation
		end

		-- Ensure the character ends at the target position
		humanoidRootPart.CFrame = CFrame.new(targetPosition)
		canRoll = true
	end
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	userInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.RightControl then
			performRandomCartwheel(humanoidRootPart)
		end
	end)
end

-- Connect onCharacterAdded function to CharacterAdded event
game.Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Check if character exists initially (in case the player is already spawned)
if game.Players.LocalPlayer.Character then
	onCharacterAdded(game.Players.LocalPlayer.Character)
end
