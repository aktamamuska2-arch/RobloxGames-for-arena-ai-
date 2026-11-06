-- StarterPlayer/StarterPlayerScripts/BGM
-- Define the Sound ID of your background music
local backgroundMusicId = "rbxassetid://18305353292"  -- Replace with your sound ID

-- Create a Sound instance
local backgroundMusic = Instance.new("Sound")
backgroundMusic.SoundId = backgroundMusicId
backgroundMusic.Volume = 0.5  -- Adjust volume as needed
backgroundMusic.Looped = true  -- Loop the music

-- Parent the sound to the Workspace or another appropriate parent
backgroundMusic.Parent = game.Workspace  -- You can parent it wherever appropriate

-- Play the background music
backgroundMusic:Play()
