-- ServerScriptService/MainScripts/InventoryData
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local INVENTORY_DATASTORE_KEY = "PlayerInventory" -- Don't touch!

-- ##################
-- INVENTORY LOAD/SAVE
-- ##################
local function loadPlayerInventory(player)
	local playerKey = "Player_" .. player.UserId
	local inventoryStore = DataStoreService:GetDataStore(INVENTORY_DATASTORE_KEY)
	local success, inventory = pcall(function()
		return inventoryStore:GetAsync(playerKey)
	end)
	if success then
		return inventory or false -- Return stored inventory or an empty table if none found
	else
		warn("Failed to retrieve inventory for player " .. player.Name .. ": " .. tostring(inventory))
		return {} -- Return empty inventory on failure
	end
end
local function savePlayerInventory(player, inventory)
	local playerKey = "Player_" .. player.UserId
	local inventoryStore = DataStoreService:GetDataStore(INVENTORY_DATASTORE_KEY)
	local success, err = pcall(function()
		inventoryStore:SetAsync(playerKey, inventory)
	end)
	if not success then
		warn("Failed to save inventory for " .. player.Name .. ": " .. tostring(err))
	end
end


-- USED BY "giveTool()" BELOW
function findToolInFolder(folder, toolName)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Tool") and child.Name == toolName then
			return child
		elseif child:IsA("Folder") then
			local foundTool = findToolInFolder(child, toolName)
			if foundTool then
				return foundTool
			end
		end
	end
	return nil
end
-- JUST LIKE "giveDefaultTools()" BUT DYNAMIC FOR FINDING ANY TOOL
function giveTool(player, toolName)
	local tool = findToolInFolder(game.ReplicatedStorage, toolName)
	if tool then
		local toolClone = tool:Clone()
		toolClone.Parent = player.Backpack
		print("Gave tool: " .. tool.Name .. " to " .. player.Name)
	else
		warn("Tool: " .. toolName .. " not found in ReplicatedStorage.Tools")
	end
end
-- Function to give tools to player's backpack based on inventory names
local function giveToolsFromInventory(player, inventory)
	for _, toolName in ipairs(inventory) do
		giveTool(player, toolName)
	end
end
function returnItems(player, inventory)
	giveToolsFromInventory(player, inventory) -- REPLACEMENT FUNCTION
	print("Added inventory data for " .. player.Name)
end

-- GIVES THE DEFAULT TOOLS
function giveDefaultTools(player)
	local defaultTools = {"Martial", "Wallet"}
	for _, toolName in ipairs(defaultTools) do
		giveTool(player, toolName)
	end
	print("Gave default tools: Martial, Wallet to " .. player.Name)
end

game.Players.PlayerAdded:Connect(function(player)
	local inventory = loadPlayerInventory(player) -- Load inventory from DataStore
	if not inventory then -- If inventory is false/empty, give default tools
		giveDefaultTools(player)
	end
	
	local function onCharacterAdded(character)
		local player = game.Players:GetPlayerFromCharacter(character)
		if player then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.Died:Connect(function()
					print(player.Name .. " died, haha")
					inventory = inventoryTable(player)
				end)
			end
			-- Player respawns
			print(player.Name .. " has respawned")
			returnItems(player, inventory) -- Add items to player's backpack upon joining
		else
			warn("Player not found for character:", character.Name)
		end
	end
	
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end)

game.Players.PlayerRemoving:Connect(function(player)
	local inventory = inventoryTable(player)
	savePlayerInventory(player, inventory)
end)

function inventoryTable(player)
	local inventoryNames = {}
	local character = player.Character
	-- Add equipped items (if any)
	if character then
		-- Find the equipped tool in the character
		local tool = character:FindFirstChildOfClass("Tool")
		if tool then
			table.insert(inventoryNames, tool.Name)
		end
	end
	-- Extract item names from player's backpack and save
	for _, item in ipairs(player.Backpack:GetChildren()) do
		if item:IsA("Tool") then
			table.insert(inventoryNames, item.Name)
		end
	end
	return inventoryNames
end