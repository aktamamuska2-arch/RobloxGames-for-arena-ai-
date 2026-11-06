-- ServerScriptService/MainScripts/PlayerStatsData
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Create or get the DataStore
local playerDataStore = DataStoreService:GetDataStore("PlayerData")

-- Function to save player data
local function savePlayerData(player)
	local data = {
		MaxHealth = player:FindFirstChild("MaxHealth").Value,
		MaxEnergy = player:FindFirstChild("MaxEnergy").Value,
		Strength = player:FindFirstChild("Strength").Value,
		Agility = player:FindFirstChild("Agility").Value,
		Soul = player:FindFirstChild("Soul").Value
	}

	local success, err = pcall(function()
		playerDataStore:SetAsync(player.UserId, data)
	end)

	if not success then
		warn("Failed to save data for player:", player.Name, err)
	end
end

-- Function to load player data
local function loadPlayerData(player)
	local success, data = pcall(function()
		return playerDataStore:GetAsync(player.UserId)
	end)

	if success and data then
		player:WaitForChild("MaxHealth").Value = data.MaxHealth
		player:WaitForChild("MaxEnergy").Value = data.MaxEnergy
		player:WaitForChild("Strength").Value = data.Strength
		player:WaitForChild("Agility").Value = data.Agility
		player:WaitForChild("Soul").Value = data.Soul

		-- Ensure Humanoid properties are updated
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.MaxHealth = data.MaxHealth
		humanoid.Health = data.MaxHealth
	else
		warn("Failed to load data for player:", player.Name, data)
		initializePlayerStats(player) -- Initialize stats if data load fails or data does not exist
	end
end

-- Function to initialize player stats
function initializePlayerStats(player)
	local maxHealth = Instance.new("IntValue")
	maxHealth.Name = "MaxHealth"
	maxHealth.Value = 100
	maxHealth.Parent = player

	local maxEnergy = Instance.new("IntValue")
	maxEnergy.Name = "MaxEnergy"
	maxEnergy.Value = 100
	maxEnergy.Parent = player

	local strength = Instance.new("IntValue")
	strength.Name = "Strength"
	strength.Value = 1
	strength.Parent = player

	local agility = Instance.new("IntValue")
	agility.Name = "Agility"
	agility.Value = 1
	agility.Parent = player

	local soul = Instance.new("IntValue")
	soul.Name = "Soul"
	soul.Value = 1
	soul.Parent = player
end

-- Function to set Humanoid properties
local function setHumanoidProperties(character)
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		local humanoid = character:WaitForChild("Humanoid")
		local maxHealth = player:FindFirstChild("MaxHealth").Value
		humanoid.MaxHealth = maxHealth
		humanoid.Health = maxHealth
	end
end

-- Connect to PlayerAdded event
Players.PlayerAdded:Connect(function(player)
	-- Ensure player's data is initialized
	local maxHealth = player:FindFirstChild("MaxHealth")
	if not maxHealth then
		initializePlayerStats(player)
	end

	loadPlayerData(player)
	
	local energy = Instance.new("IntValue")
	energy.Name = "Energy"
	energy.Value = player:WaitForChild("MaxEnergy").Value
	energy.Parent = player

	player.CharacterAdded:Connect(function(character)
		-- initialize Energy with the MaxEnergy value
		player:FindFirstChild("Energy").Value = player:FindFirstChild("MaxEnergy").Value
		setHumanoidProperties(character)
	end)
end)

-- Connect to PlayerRemoving event
Players.PlayerRemoving:Connect(function(player)
	savePlayerData(player)
end)

game.ReplicatedStorage.Events.UpgradeStat.OnServerEvent:Connect(function(player, stat)
	if stat == "MaxHealth" or stat == "MaxEnergy" then
		player:FindFirstChild(stat).Value = player:FindFirstChild(stat).Value + 10
		player:FindFirstChild("PointsUsed").Value = player:FindFirstChild("PointsUsed").Value + 1
	else
		player:FindFirstChild(stat).Value = player:FindFirstChild(stat).Value + 1
		player:FindFirstChild("PointsUsed").Value = player:FindFirstChild("PointsUsed").Value + 1
	end
end)