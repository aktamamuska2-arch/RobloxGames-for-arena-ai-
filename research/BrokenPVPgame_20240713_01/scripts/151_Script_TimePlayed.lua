-- ServerScriptService/Main/TimePlayed
-- XP Ranks
local xpRanks = {
	{ 0, "Unranked" },
	{ 100, "Bronze I" },
	{ 1000, "Bronze II" },
	{ 4000, "Bronze III" },
	{ 8000, "Iron I" },
	{ 10000, "Iron II" },
	{ 20000, "Iron III" },
	{ 30000, "Silver I" },
	{ 50000, "Silver II" },
	{ 80000, "Silver III" },
	{ 100000, "Silver IV" },
	{ 170000, "Silver V" },
	{ 200000, "Titanium I" },
	{ 250000, "Titanium II" },
	{ 350000, "Titanium III" },
	{ 500000, "Titanium IV" },
	{ 600000, "Titanium V" },
	{ 800000, "Gold I" },
	{ 1000000, "Gold II" },
	{ 1100000, "Gold III" },
	{ 1500000, "Gold IV" },
	{ 1800000, "Gold V" },
	{ 2000000, "Platinum I" },
	{ 2500000, "Platinum II" },
	{ 3500000, "Platinum III" },
	{ 5000000, "Diamond I" },
	{ 5500000, "Diamond II" },
	{ 6500000, "Diamond III" },
	{ 7500000, "Diamond IV" },
	{ 9000000, "Diamond V" },
	{ 10000000, "Master I" },
	{ 11000000, "Master II" },
	{ 12000000, "Master III" },
	{ 13000000, "Veteran" },
	{ 15000000, "Conqueror" }
}

local DataStoreService = game:GetService("DataStoreService")
local PLAYTIME_DATASTORE_KEY = "PlayerPlaytime"
local XP_DATASTORE_KEY = "PlayerXP"
local MarketplaceService = game:GetService("MarketplaceService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local killEventXP = ReplicatedStorage:WaitForChild("KillEventXP")
local xpEvent = ReplicatedStorage:WaitForChild("XPEvent")

-- Function to retrieve playtime from DataStore with error handling
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


-- Function to save playtime to DataStore with error handling
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


-- Function to retrieve XP from DataStore with error handling
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

-- Function to save XP to DataStore with error handling
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

-- Function to update XP every minute
local function updateXP(player)
	local xp = getPlayerXP(player)
	xp = xp + 10  -- Increment XP by 10 every minute
	savePlayerXP(player, xp)
end

-- Function to determine rank based on XP
local function getPlayerRank(xp)
	for i = #xpRanks, 1, -1 do
		local xpRequirement = xpRanks[i][1]
		local rankName = xpRanks[i][2]
		if xp >= xpRequirement then
			return rankName
		end
	end
	return "Unranked"
end

-- Hook into PlayerAdded and PlayerRemoving events to handle DataStore and leaderboard
game.Players.PlayerAdded:Connect(function(player)
	-- Retrieve and initialize playtime for new players
	local initialPlaytime = getPlayerPlaytime(player)
	local initialXP = getPlayerXP(player)

	-- Create leaderboard for the player
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local timePlayedValue = Instance.new("IntValue")
	timePlayedValue.Name = "Time Played"
	timePlayedValue.Value = initialPlaytime
	timePlayedValue.Parent = leaderstats
	
	local xpValue = Instance.new("IntValue")
	xpValue.Name = "XP"
	xpValue.Value = initialXP
	xpValue.Parent = leaderstats

	local rankValue = Instance.new("StringValue")
	rankValue.Name = "Rank"
	rankValue.Value = getPlayerRank(initialXP)
	rankValue.Parent = leaderstats

	-- Set up periodic playtime update (every minute)
	local updateInterval = 60  -- in seconds (every 60 seconds = 1 minute)
	local elapsedTime = 0
	local updateTimer
	updateTimer = game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
		if player.Parent == nil then
			updateTimer:Disconnect()
			return
		end
		elapsedTime = elapsedTime + deltaTime
		if elapsedTime >= updateInterval then
			elapsedTime = 0
			timePlayedValue.Value = timePlayedValue.Value + 1
			if MarketplaceService:UserOwnsGamePassAsync(player.UserId,842348739) then
				xpValue.Value = xpValue.Value + 20
				xpEvent:FireClient(player, "+20 XP for playing")
			else
				xpValue.Value = xpValue.Value + 10
				xpEvent:FireClient(player,"+10 XP for playing")
			end
			rankValue.Value = getPlayerRank(xpValue.Value)
			updateXP(player)
		end
	end)
end)

game.Players.PlayerRemoving:Connect(function(player)
	-- Save final playtime when player leaves
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local timePlayedValue = leaderstats:FindFirstChild("Time Played")
		local xpValue = leaderstats:FindFirstChild("XP")
		if timePlayedValue then
			savePlayerPlaytime(player, timePlayedValue.Value)
		end
		if xpValue then
			savePlayerXP(player, xpValue.Value)
		end
	end
end)

-- Table to keep track of cooldowns for each player
local xpCooldowns = {}
-- Cooldown duration (in seconds)
local cooldownDuration = 2  -- Example: 60 seconds cooldown
killEventXP.OnServerEvent:Connect(function(player, victim)
	if player and victim and player ~= victim then
		local currentTime = tick()
		-- Check if the player's cooldown entry exists and is still active
		if xpCooldowns[player.UserId] and currentTime - xpCooldowns[player.UserId] < cooldownDuration then
			return  -- Skip XP addition if player is on cooldown
		end
		-- Update or set the cooldown timestamp for this player
		xpCooldowns[player.UserId] = currentTime
		-- Get current killer XP from leaderstats
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local xpValue = leaderstats:FindFirstChild("XP")
			if xpValue then
				if MarketplaceService:UserOwnsGamePassAsync(player.UserId,842348739) then
					xpValue.Value = xpValue.Value + 100
					xpEvent:FireClient(player, "+100 XP for kill")
				else
					xpValue.Value = xpValue.Value + 50
					xpEvent:FireClient(player, "+50 XP for kill")
				end
			else
				warn("XP Value not found for player: " .. player.Name)
			end
		else
			warn("Leaderstats not found for player: " .. player.Name)
		end
	end
end)
