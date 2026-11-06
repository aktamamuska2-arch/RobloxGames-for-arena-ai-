-- ServerScriptService/MainScripts/CurrencyData
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local GOLD_TOKENS_DATASTORE_KEY = "GoldTokensStore" -- Don't modify!

-- Function to load player's data
local function loadPlayerGold(player)
	local playerKey = "Player_" .. player.UserId
	local goldTokensStore = DataStoreService:GetDataStore(GOLD_TOKENS_DATASTORE_KEY)
	local success, gold = pcall(function()
		return goldTokensStore:GetAsync(playerKey)
	end)
	if success then
		print(player.Name .. " has loaded, with " .. tostring(gold) .. " GT")
		return gold or 10
	else
		warn("Failed to retrieve GoldTokens for player " .. player.Name .. ": " .. tostring(gold))
		return 10
	end
end

-- Function to save player's data
local function savePlayerGold(player)
	local playerKey = "Player_" .. player.UserId
	local goldTokensStore = DataStoreService:GetDataStore(GOLD_TOKENS_DATASTORE_KEY)
	local success, err = pcall(function()
		return goldTokensStore:SetAsync(playerKey, player:FindFirstChild("GoldTokens").Value)
	end)
	if not success then
		warn("Failed to save GoldTokens for " .. player.Name .. ": " .. err)
	end
end

local function onCharacterAdded(character)
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		local playerGold = player:FindFirstChild("GoldTokens")
		if not playerGold then
			playerGold = Instance.new("IntValue")
			playerGold.Name = "GoldTokens"
			playerGold.Value = loadPlayerGold(player)
			playerGold.Parent = player
		end
		local charGold = Instance.new("IntValue")
		charGold.Name = "GoldTokens"
		charGold.Value = playerGold.Value
		charGold.Parent = character
	else
		warn("Player not found for character:", character.Name)
	end
end

-- Currency handling
local function onMoneyUpdate(player, currency, amount, reason)
	if currency == "GT" then
		local charGold = player.Character:FindFirstChild("GoldTokens")
		if charGold then
			if reason == "gain" then
				charGold.Value = charGold.Value + amount
				print(player.Name .. " has gained " .. tostring(amount) .. " GT and now has " .. tostring(charGold.Value) .. " GT")
			elseif reason == "spend" then
				charGold.Value = charGold.Value - amount
				print(player.Name .. " has spent " .. tostring(amount) .. " GT and now has " .. tostring(charGold.Value) .. " GT")
			end
			-- Update money UI
			player:FindFirstChild("GoldTokens").Value = charGold.Value
			player.PlayerGui.MainGui.CurrencyInfo.GoldTokenInfo.Text = "GT " .. charGold.Value
		end
	end
end

game.ReplicatedStorage.Events.MoneyUpdate.OnServerEvent:Connect(onMoneyUpdate)

-- Player added event
game.Players.PlayerAdded:Connect(function(player)
	local playerGold = Instance.new("IntValue")
	playerGold.Name = "GoldTokens"
	playerGold.Value = loadPlayerGold(player)
	playerGold.Parent = player

	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.PlayerGui.MainGui.CurrencyInfo.GoldTokenInfo.Text = "GT " .. player.Character:FindFirstChild("GoldTokens").Value -- Initialize the currency GoldTokens GUI
end)

-- Player removing event
game.Players.PlayerRemoving:Connect(function(player)
	savePlayerGold(player)
end)