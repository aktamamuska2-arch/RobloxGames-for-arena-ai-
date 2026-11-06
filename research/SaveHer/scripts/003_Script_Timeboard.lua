-- ServerScriptService/Timeboard
local DataStoreService = game:GetService("DataStoreService")
local PLAYTIME_DATASTORE_KEY = "PlayerPlaytime"

-- Function to retrieve player's playtime data
local function getPlayerPlaytime(player)
	local playerKey = "Player_" .. player.UserId
	local dataStore = DataStoreService:GetDataStore(PLAYTIME_DATASTORE_KEY)

	local success, result = pcall(function()
		return dataStore:GetAsync(playerKey)
	end)

	if success then
		return result or { LongestLifetime = 0, CurrentLifetime = 0 }
	else
		warn("Failed to retrieve playtime for player " .. player.Name .. ": " .. tostring(result))
		return { LongestLifetime = 0, CurrentLifetime = 0 }
	end
end

-- Function to save player's playtime data
local function savePlayerPlaytime(player, longestLifetime, currentLifetime)
	local playerKey = "Player_" .. player.UserId
	local dataStore = DataStoreService:GetDataStore(PLAYTIME_DATASTORE_KEY)

	local success, err = pcall(function()
		dataStore:SetAsync(playerKey, { LongestLifetime = longestLifetime, CurrentLifetime = currentLifetime })
	end)

	if not success then
		warn("Failed to save playtime for player " .. player.Name .. ": " .. tostring(err))
	end
end

-- Connect to player joining event
game.Players.PlayerAdded:Connect(function(player)
	local playtimeData = getPlayerPlaytime(player)

	-- Create leaderstats folder
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Longest Lifetime value
	local longestLifetimeValue = Instance.new("StringValue")
	longestLifetimeValue.Name = "Longest Lifetime"
	longestLifetimeValue.Value = formatTime(playtimeData.LongestLifetime)
	longestLifetimeValue.Parent = leaderstats

	-- Current Lifetime value
	local currentLifetimeValue = Instance.new("StringValue")
	currentLifetimeValue.Name = "Current Lifetime"
	currentLifetimeValue.Value = "00 S"
	currentLifetimeValue.Parent = leaderstats

	-- Update per second
	local updateInterval = 1
	local timeElapsed = 0
	local updateTimer

	updateTimer = game:GetService("RunService").Stepped:Connect(function(_, deltaTime)
		if player.Parent == nil then
			updateTimer:Disconnect()
			return
		end

		timeElapsed = timeElapsed + deltaTime

		if timeElapsed >= updateInterval then
			timeElapsed = 0
			local currentLifetimeInSeconds = currentLifetimeValue.Value:match("(%d+) S") or 0
			currentLifetimeInSeconds = currentLifetimeInSeconds + 1
			currentLifetimeValue.Value = formatTime(currentLifetimeInSeconds)

			-- Update longest lifetime if current lifetime exceeds it
			local currentLifetimeFormatted = currentLifetimeValue.Value
			local hours = tonumber(currentLifetimeFormatted:match("(%d+) H")) or 0
			local minutes = tonumber(currentLifetimeFormatted:match("(%d+) M")) or 0
			local seconds = tonumber(currentLifetimeFormatted:match("(%d+) S")) or 0
			local totalSeconds = hours * 3600 + minutes * 60 + seconds

			if totalSeconds > playtimeData.LongestLifetime then
				longestLifetimeValue.Value = currentLifetimeValue.Value
				savePlayerPlaytime(player, totalSeconds, totalSeconds)
			end
		end
	end)

end)

-- Connect to player leaving event
game.Players.PlayerRemoving:Connect(function(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local longestLifetimeValue = leaderstats:FindFirstChild("Longest Lifetime")
		local currentLifetimeValue = leaderstats:FindFirstChild("Current Lifetime")
		if longestLifetimeValue and currentLifetimeValue then
			local currentLifetimeFormatted = currentLifetimeValue.Value
			local hours = tonumber(currentLifetimeFormatted:match("(%d+) H")) or 0
			local minutes = tonumber(currentLifetimeFormatted:match("(%d+) M")) or 0
			local seconds = tonumber(currentLifetimeFormatted:match("(%d+) S")) or 0
			local totalSeconds = hours * 3600 + minutes * 60 + seconds
			savePlayerPlaytime(player, totalSeconds, totalSeconds)
		end
	end
end)

-- Function to format time in "00 H 00 M 00 S" format
function formatTime(seconds)
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local remainingSeconds = seconds % 60

	if hours > 0 then
		return string.format("%02d H %02d M %02d S", hours, minutes, remainingSeconds)
	elseif minutes > 0 then
		return string.format("%02d M %02d S", minutes, remainingSeconds)
	else
		return string.format("%02d S", remainingSeconds)
	end
end
