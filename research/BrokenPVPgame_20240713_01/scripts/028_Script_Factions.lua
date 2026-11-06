-- ServerScriptService/Main/Factions
-- Script placed in ServerScriptService

local Players = game:GetService("Players")

local function onCharacterAdded(character)
	local faction = Instance.new("StringValue")
	faction.Name = "Faction"
	faction.Value = "Criminals"
	faction.Parent = character
end

local function onPlayerAdded(player)
	-- Connect the CharacterAdded event to handle character respawns
	player.CharacterAdded:Connect(onCharacterAdded)

	-- If the player's character already exists (in case of player teleport), add the faction immediately
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

-- Connect the PlayerAdded event
Players.PlayerAdded:Connect(onPlayerAdded)

-- Handle any players that are already in the game (in case of script reloading)
for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end