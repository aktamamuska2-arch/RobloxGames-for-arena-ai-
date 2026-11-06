-- StarterPlayer/StarterPlayerScripts/RandomBeep
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local lastPosition = character.HumanoidRootPart.Position

-- Function to create and play the sound
local function playStepSound()
	local sound = Instance.new("Sound")
	sound.Parent = character.HumanoidRootPart
	sound.SoundId = "rbxassetid://136075117" -- Placeholder sound
	sound.Looped = false
	sound.Volume = 0.06
	sound.Pitch = math.random(40, 70) / 100 -- Randomize pitch for variety
	sound.PlaybackSpeed = math.random(50, 80) / 100 -- Randomize speed for variety

	-- Add echo effect
	local echo = Instance.new("ReverbSoundEffect")
	echo.DecayTime = 5 -- Duration of the echo
	echo.DryLevel = 0 -- Original sound volume
	echo.WetLevel = 0.8 -- Echo volume
	echo.Density = 1.8 -- Density of the echo effect
	echo.Parent = sound

	-- Play the sound
	sound:Play()

	-- Clean up the sound instance after it finishes playing
	sound.Ended:Connect(function()
		sound:Destroy()
	end)
end

-- Function to check for player steps
local function checkForSteps()
	local currentPosition = character.HumanoidRootPart.Position
	local distance = (currentPosition - lastPosition).Magnitude

	if distance > 2 then -- Adjust the threshold as needed
		playStepSound()
		lastPosition = currentPosition
	end
end

-- Connect to the RunService to check for steps every frame
RunService.RenderStepped:Connect(checkForSteps)
