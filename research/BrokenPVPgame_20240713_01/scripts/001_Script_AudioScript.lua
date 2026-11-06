-- Workspace/AudioScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")
local musicChanged = ReplicatedStorage:FindFirstChild("MusicChanged")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- List of sounds with additional information
local sounds = {
	{1845070869, "Eye Open", "APM Music"},
	{1843497734, "Chaos", "APM Music"},
	{1845149698, "Seek & Destroy", "APM Music"},
	{1845805363, "Fire Fight A", "APM Music"},
	{1837560230, "Classic Chase", "APM Music"},
	{9038254260, "Fight Through Adversity", "APM Music"},
	{1837278308, "Let's Fight", "APM Music"}
}

-- Create a sound object
local sound = Instance.new("Sound")
sound.Volume = 0.25
sound.Parent = game.Workspace

local previousIndex = nil

-- Function to get a random index that is not the same as the previous index
local function getRandomIndex()
	local index
	repeat
		index = math.random(1, #sounds)
	until index ~= previousIndex
	previousIndex = index
	return index
end

-- Function to play a random sound
local function playRandomSound()
	local index = getRandomIndex()
	local soundData = sounds[index]
	local AUDIO_ID = soundData[1]
	local musicName = soundData[2]
	local musicCreator = soundData[3]
	workspace.MusicNameNow.Value = soundData[2]
	workspace.MusicCreatorNow.Value = soundData[3]

	sound.SoundId = "rbxassetid://" .. AUDIO_ID

	-- Check if the sound is loaded before playing
	sound:Play()
	sound.Loaded:Wait()

	if player and player.PlayerGui then
		local gui = player.PlayerGui:WaitForChild("Credits")
		if gui then
			local musicframe = gui.InGameCredits.MusicCredits
			musicframe.MusicName.Text = musicName
			musicframe.Creator.Text = musicCreator
			musicframe.Visible = true
		end
	end

	-- Fire the musicChanged event with the sound information
	musicChanged:FireAllClients(musicName, musicCreator)
end

-- Connect the ended event once to play the next sound
sound.Ended:Connect(function()
	playRandomSound()
end)

-- Start playing the first random sound
playRandomSound()