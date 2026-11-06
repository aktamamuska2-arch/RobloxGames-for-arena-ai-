-- StarterPlayer/StarterPlayerScripts/DoubleJump
-- Example: StarterPlayerScripts > DoubleJumpScript (LocalScript)

-- Function to handle double jump logic
local function setupDoubleJump(character)
	-- Ensure character and humanoid exist
	local humanoid = character:WaitForChild("Humanoid")
	local canDoubleJump = true
	local doubleJumpCount = 0

	-- Listen for user input to perform jump
	game:GetService("UserInputService").JumpRequest:Connect(function()
		if canDoubleJump then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			doubleJumpCount = doubleJumpCount + 1
			canDoubleJump = false
		end
	end)

	-- Handle character state changes if needed
	humanoid.StateChanged:Connect(function(oldState, newState)
		if newState == Enum.HumanoidStateType.Freefall then
			-- Enable double jump when falling (if desired)
			canDoubleJump = true
		elseif newState == Enum.HumanoidStateType.Seated or newState == Enum.HumanoidStateType.Swimming then
			-- Reset double jump count if character lands in a seat or starts swimming
			doubleJumpCount = 0
			canDoubleJump = true
		elseif newState == Enum.HumanoidStateType.Dead then
			-- Reset double jump count if character dies
			doubleJumpCount = 0
			canDoubleJump = true
		end
	end)
end

-- Function to connect setupDoubleJump on character added
local function onCharacterAdded(character)
	setupDoubleJump(character)
end

-- Connect onCharacterAdded function to CharacterAdded event
game.Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Check if character exists initially (in case the player is already spawned)
if game.Players.LocalPlayer.Character then
	onCharacterAdded(game.Players.LocalPlayer.Character)
end
