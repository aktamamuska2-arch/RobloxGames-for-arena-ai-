-- StarterPlayer/StarterPlayerScripts/Death
local Players = game:GetService("Players")

-- Get the local player
local player = Players.LocalPlayer

-- Wait for the character to load
player.CharacterAdded:Connect(function(character)
	-- Get the Humanoid
	local humanoid = character:WaitForChild("Humanoid")

	-- Connect to the Died event
	humanoid.Died:Connect(function()
		--player.PlayerGui.ScreenGui.Died.ImageLabel.Visible = true

		-- Create and play the loud scary sound
		--local sound = Instance.new("Sound")
		--sound.SoundId = "rbxassetid://5681392074" -- Your sound ID
		--sound.Volume = 1 -- Set the volume (1 is the max volume)
		--sound.Parent = player.PlayerGui
		--sound:Play()

		-- Disable respawn
		player.CharacterAdded:Connect(function(newCharacter)
			newCharacter:Destroy()
		end)

		--wait(3)

		-- Stop the sound and make the ImageLabel invisible
		--sound:Stop()
		--sound:Destroy() -- Clean up the sound instance
		--player.PlayerGui.ScreenGui.Died.ImageLabel.Visible = false
	end)
end)
