-- ServerScriptService/MainScripts/LevelingSystem
-- DS keys
local DataStoreService = game:GetService("DataStoreService")
local XP_DATASTORE_KEY = "PlayerXP"
local PLAYTIME_DATASTORE_KEY = "PlayerPlaytime"
local LEVEL_POINTS_KEY = "PlayerLevelPoints"
-- RS variables
local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- control variables
local MAX_LEVEL = 20

-- ##################
-- XP LOAD/SAVE
-- ##################
local function getPlayerXP(player)
	local playerKey = "Player_" .. player.UserId
	local dataStore = DataStoreService:GetDataStore(XP_DATASTORE_KEY)
	local success, xp = pcall(function()
		return dataStore:GetAsync(playerKey)
	end)
	if success then
		return xp or 0
	else
		warn("Failed to retrieve XP for player " .. player.Name .. ": " .. tostring(xp))
		return 0
	end
end
local function savePlayerXP(player, xp)
	local playerKey = "Player_" .. player.UserId
	local dataStore = DataStoreService:GetDataStore(XP_DATASTORE_KEY)
	local success, err = pcall(function()
		dataStore:SetAsync(playerKey, xp)
	end)
	if not success then
		warn("Failed to save XP for player " .. player.Name .. ": " .. tostring(err))
	end
end
local function updatePlayerXP(player, xp)
	local charXP = player.Character:FindFirstChild("XP")
	if charXP then
		charXP.Value = charXP.Value + xp
		player:FindFirstChild("XP").Value = charXP.Value
	end
end

-- ##################
-- LEVEL POINTS LOAD/SAVE
-- ##################
local function getPlayerPoints(player)
	local playerKey = "Player_" .. player.UserId
	local dataStore = DataStoreService:GetDataStore(LEVEL_POINTS_KEY)
	local success, points = pcall(function()
		return dataStore:GetAsync(playerKey)
	end)
	if success then
		return points or 0
	else
		warn("Failed to retrieve level points for player " .. player.Name .. ": " .. tostring(points))
		return 0
	end
end
local function savePlayerPoints(player, points)
	local playerKey = "Player_" .. player.UserId
	local dataStore = DataStoreService:GetDataStore(LEVEL_POINTS_KEY)
	local success, err = pcall(function()
		dataStore:SetAsync(playerKey, points)
	end)
	if not success then
		warn("Failed to save XP for player " .. player.Name .. ": " .. tostring(err))
	end
end
local function updatePlayerPoints(player, points)
	local pointsUsed = player.Character:FindFirstChild("PointsUsed")
	if pointsUsed then
		pointsUsed.Value = pointsUsed.Value + points
		player:FindFirstChild("PointsUsed").Value = pointsUsed.Value
	end
end

-- ##################
-- PLAYTIME LOAD/SAVE
-- ##################
local function getPlayerPlaytime(player)
	local playerKey = "Player_" .. player.UserId
	local dataStore = DataStoreService:GetDataStore(PLAYTIME_DATASTORE_KEY)
	local success, playtime = pcall(function()
		return dataStore:GetAsync(playerKey)
	end)
	if success then
		return playtime or 0
	else
		warn("Failed to retrieve playtime for player " .. player.Name .. ": " .. tostring(playtime))
		return 0
	end
end
local function savePlayerPlaytime(player, playtime)
	local playerKey = "Player_" .. player.UserId
	local dataStore = DataStoreService:GetDataStore(PLAYTIME_DATASTORE_KEY)
	local success, err = pcall(function()
		dataStore:SetAsync(playerKey, playtime)
	end)
	if not success then
		warn("Failed to save playtime for player " .. player.Name .. ": " .. tostring(err))
	end
end

-- ######### Function to determine level based on XP #######
local function getPlayerLevel(xp)
	local level = 0
	while xp >= 100 * ((level + 1) ^ 1.5) do
		level = level + 1
	end
	if level == MAX_LEVEL then
		return "Lv " .. tostring(MAX_LEVEL) .. " (max)"
	else
		return "Lv " .. level
	end
end

local function onCharacterAdded(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		-- add XP to player
		local playerXP = player:FindFirstChild("XP")
		if not playerXP then
			playerXP = Instance.new("IntValue")
			playerXP.Name = "XP"
			playerXP.Value = getPlayerXP(player)
			playerXP.Parent = player
		end
		local charXP = Instance.new("IntValue")
		charXP.Name = "XP"
		charXP.Value = playerXP.Value
		charXP.Parent = character
		
		-- add PointsUsed to player
		local playerPoints = player:FindFirstChild("PointsUsed")
		if not playerPoints then
			playerPoints = Instance.new("IntValue")
			playerPoints.Name = "PointsUsed"
			playerPoints.Value = getPlayerPoints(player)
			playerPoints.Parent = player
		end
		local charPoints = Instance.new("IntValue")
		charPoints.Name = "PointsUsed"
		charPoints.Value = playerPoints.Value
		charPoints.Parent = character
	else
		warn("Player not found for character:", character.Name)
	end
end

-- ######## LEADERBOARD GUI #########
game.Players.PlayerAdded:Connect(function(player)
	local initialXP = getPlayerXP(player)
	local initialPlaytime = getPlayerPlaytime(player)
	local initialPoints = getPlayerPoints(player)
	
	-- Create leaderboard
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local levelValue = Instance.new("StringValue")
	levelValue.Name = "Level"
	levelValue.Value = getPlayerLevel(initialXP)
	levelValue.Parent = leaderstats
	
	local timeValue = Instance.new("IntValue")
	timeValue.Name = "Time Played"
	timeValue.Value = initialPlaytime
	timeValue.Parent = leaderstats
	
	local playerXP = Instance.new("IntValue")
	playerXP.Name = "XP"
	playerXP.Value = initialXP
	playerXP.Parent = player
	
	local playerPoints = Instance.new("IntValue")
	playerPoints.Name = "PointsUsed"
	playerPoints.Value = initialPoints
	playerPoints.Parent = player
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
	print(player.Name .. " has loaded with " .. tostring(player:FindFirstChild("XP").Value) .. " XP")
	
	-- Playtime update per minute
	local updateInterval = 60
	local timeElapsed = 0
	local updateTimer
	updateTimer = game:GetService("RunService").Heartbeat:Connect(function(deltatime)
		if player.Parent == nil then
			updateTimer:Disconnect()
			return
		end
		timeElapsed = timeElapsed + deltatime
		if timeElapsed >= updateInterval then
			timeElapsed = 0
			timeValue.Value = timeValue.Value + 1
			-- insert MarketplaceService code here if there are gamepasses for double time or xp
			updatePlayerXP(player, 10) -- add 10 xp per minute
			levelValue.Value = getPlayerLevel(player:FindFirstChild("XP").Value) -- update player level per minute
			print(player.Name .. " has " .. tostring(player:FindFirstChild("XP").Value) .. " XP")
		end
	end)
	
end)

-- when players leave the game
game.Players.PlayerRemoving:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local timeValue = leaderstats:FindFirstChild("Time Played")
		if timeValue then
			savePlayerPlaytime(player, timeValue.Value)
		end
		local playerXP = player:FindFirstChild("XP").Value
		if playerXP then
			savePlayerXP(player,playerXP)
		end
		local playerPoints = player:FindFirstChild("PointsUsed").Value
		if playerPoints then
			savePlayerPoints(player, playerPoints)
		end
	end
end)