-- StarterPlayer/StarterPlayerScripts/RandomScarySound
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- List of sound IDs (replace with your own)
local soundIds = {
	"rbxassetid://5681392074", -- Sound 1
	"rbxassetid://1526192493", -- Sound 2
	--"rbxassetid://4737106301", -- Sound 3
	--"rbxassetid://9043347012", -- Sound 4
	--"rbxassetid://9043356686", -- Sound 5
	-- Add more sound IDs as needed
}

-- Function to play random sound with echo effect
local function playRandomSound()
	local echoSound = Instance.new("Sound")
	local randomSoundId = soundIds[math.random(1, #soundIds)]
	echoSound.SoundId = randomSoundId
	echoSound.Parent = game.Workspace -- You can parent it wherever appropriate
	echoSound.Looped = false
	echoSound.Volume = 1
	echoSound.PlaybackSpeed = 1

	-- Add echo effect
	local echo = Instance.new("ReverbSoundEffect")
	echo.DecayTime = 4 -- Duration of the echo
	echo.DryLevel = 0 -- Original sound volume
	echo.WetLevel = 0.8 -- Echo volume
	echo.Density = 1.5 -- Density of the echo effect
	echo.Parent = echoSound

	-- Play the sound
	echoSound:Play()

	-- Clean up the sound instance after it finishes playing
	echoSound.Ended:Connect(function()
		echoSound:Destroy()
	end)
end

-- Function to continuously play sounds at random intervals
local function playRandomSounds()
	while true do
		local waitTime = math.random(3, 10) -- Adjust interval between sounds as needed
		wait(waitTime)
		playRandomSound()
	end
end

-- Start playing random sounds
spawn(playRandomSounds)
