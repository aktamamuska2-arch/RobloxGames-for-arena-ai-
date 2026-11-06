-- StarterGui/LocalSounds
local function playSound(soundName)
	local sounds = game.ReplicatedStorage:WaitForChild("Sounds")
	if sounds then
		local sound = sounds:FindFirstChild(soundName)
		if sound then
			sound:Play()
			print(soundName .. " sound played!")
		else
			warn("Sound "..soundName.." not found!")
		end
	end
end

game.ReplicatedStorage.Events.PlayLocalSound.OnClientEvent:Connect(function(sound)
	playSound(sound)
end)