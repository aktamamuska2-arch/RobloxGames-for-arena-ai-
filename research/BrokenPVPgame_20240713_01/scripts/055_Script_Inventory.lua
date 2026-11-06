-- ServerScriptService/Main/Inventory
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local StarterPack = game:GetService("StarterPack")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local inventoryDataStore = DataStoreService:GetDataStore("InventoryData")

-- Table to store inventory state for each player
local playerInventories = {}

-- Mapping of GamePass IDs to Item Names
local gamepassItems = {
	[842608271] = "Rocket Launcher",
	[842571373] = "Flashbang",
	[847597301] = "AS VAL",
	[848038634] = "SCAR",
	[847458575] = "InvisibleCloak",
	[842348739] = "Thompson"
}

-- Mapping of user IDs to items they should receive
local userItems = {
	[4335772435] = {"AS VAL", "SCAR"},
	[4088391617] = {"AS VAL", "SCAR"},
	[5230076480] = {"AS VAL", "SCAR"},
	[2559208996] = {"AS VAL", "SCAR"},
	[2249388741] = {"Rocket Launcher"}
}

-- Modify saveInventoryToTable to save items based on predefined positions
local function saveInventoryToTable(player)
	local inventory = player.Backpack:GetChildren()
	local inventoryTable = {}

	for slot = 1, #inventory do
		local item = inventory[slot]
		if item then
			table.insert(inventoryTable, {
				name = item.Name,
				class = item.ClassName,
				position = slot  -- Save the predefined position of each item
			})
		end
	end

	playerInventories[player.UserId] = inventoryTable
end

-- Modify restoreInventoryFromTable to restore items to their correct slots
local function restoreInventoryFromTable(player)
	local inventoryTable = playerInventories[player.UserId]
	if inventoryTable then
		player.Backpack:ClearAllChildren()

		-- Restore items to their correct slots based on saved positions
		for _, itemData in ipairs(inventoryTable) do
			local item = StarterPack:FindFirstChild(itemData.name) or ReplicatedStorage.Items:FindFirstChild(itemData.name)
			if item then
				local newItem = item:Clone()
				newItem.Parent = player.Backpack
				-- If the item is equipped, unequip it
				if player.Character and player.Character:FindFirstChild(itemData.name) then
					player.Character[itemData.name]:Destroy()
				end
			end
		end
	end
end

-- Function to ensure StarterPack items are added by default if not already in the inventory
local function ensureStarterPackItems(player)
	local inventory = player.Backpack:GetChildren()
	local currentItems = {}
	for _, item in ipairs(inventory) do
		currentItems[item.Name] = true
	end

	for _, item in ipairs(StarterPack:GetChildren()) do
		if not currentItems[item.Name] then
			local newItem = item:Clone()
			newItem.Parent = player.Backpack
		end
	end
end

-- Function to handle player death and save inventory
local function onPlayerDeath(player)
	saveInventoryToTable(player)
end

-- Function to handle player respawn and restore inventory
local function onPlayerRespawn(player)
	restoreInventoryFromTable(player)
	ensureStarterPackItems(player)  -- Ensure StarterPack items are added
	saveInventoryToTable(player)    -- Save the combined inventory state

	if player then
		-- Clear gamepass items from inventory to avoid duplicates
		for gamepassId, _ in pairs(gamepassItems) do
			local item = ReplicatedStorage.Items:FindFirstChild(gamepassItems[gamepassId])
			if item and player.Backpack:FindFirstChild(item.Name) then
				player.Backpack[item.Name]:Destroy()
			end
		end

		-- Check for gamepasses and grant corresponding items
		for gamepassId, itemName in pairs(gamepassItems) do
			if MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId) then
				local item = ReplicatedStorage.Items:FindFirstChild(itemName)
				if item then
					local newItem = item:Clone()
					newItem.Parent = player.Backpack
					saveInventoryToTable(player)  -- Save inventory state after adding new item
				end
			end
		end
		
		-- Add a "VIP" tag above the player's head
		if MarketplaceService:UserOwnsGamePassAsync(player.UserId,842348739) then
			local vipCrown = ReplicatedStorage:WaitForChild("Items"):WaitForChild("VIPCrown"):Clone()
			vipCrown.Parent = player.Character

			-- Position the crown 2 studs above the head
			local weld = Instance.new("Weld")
			weld.Part0 = vipCrown
			weld.Part1 = player.Character:FindFirstChild("Head")
			weld.C0 = CFrame.new(0, -2, 0)
			weld.Parent = vipCrown
			
			-- Apply the "VIPAura"
			local bodyParts = {
				"Head",
				"UpperTorso",
				"LowerTorso",
				"LeftUpperArm",
				"LeftLowerArm",
				"LeftHand",
				"RightUpperArm",
				"RightLowerArm",
				"RightHand",
				"LeftUpperLeg",
				"LeftLowerLeg",
				"LeftFoot",
				"RightUpperLeg",
				"RightLowerLeg",
				"RightFoot"
			}

			for _, partName in ipairs(bodyParts) do
				local bodyPart = player.Character:FindFirstChild(partName)
				if bodyPart then
					for _, aura in ipairs(ReplicatedStorage:WaitForChild("Auras"):WaitForChild("VIPAura"):GetChildren()) do
						if aura:IsA("ParticleEmitter") then
							local auraClone = aura:Clone()
							auraClone.Parent = bodyPart
						end
					end
				end
			end
		end

		-- Grant specific items to certain users
		local itemsToGrant = userItems[player.UserId]
		if itemsToGrant then
			for _, itemName in ipairs(itemsToGrant) do
				local item = ReplicatedStorage.Items:FindFirstChild(itemName)
				if item then
					local newItem = item:Clone()
					newItem.Parent = player.Backpack
				end
			end
			saveInventoryToTable(player)  -- Save inventory state after adding new items
		end
	end
end

-- Event handler for when a player joins
local function onPlayerAdded(player)
	local success, inventoryState = pcall(function()
		return inventoryDataStore:GetAsync(player.UserId)
	end)

	if success and inventoryState then
		playerInventories[player.UserId] = inventoryState
	else
		playerInventories[player.UserId] = {}
	end

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				onPlayerDeath(player)
			end)
		end
		onPlayerRespawn(player)
	end)
end

-- Event handler for when a player leaves
local function onPlayerRemoving(player)
	saveInventoryToTable(player)

	local success, err = pcall(function()
		inventoryDataStore:SetAsync(player.UserId, playerInventories[player.UserId])
	end)

	if not success then
		warn("Failed to save inventory data for player " .. player.Name .. ": " .. err)
	end

	playerInventories[player.UserId] = nil
end

-- Connect event handlers to player events
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Function to handle item pickup (example function to be called from elsewhere in your game)
local function onItemPickup(player, itemName)
	local item = ReplicatedStorage.Items:FindFirstChild(itemName)
	if item then
		local newItem = item:Clone()
		newItem.Parent = player.Backpack
		saveInventoryToTable(player)
	end
end

-- Function to handle item use (example function to be called from elsewhere in your game)
local function onItemUse(player, itemName)
	-- Handle the item use logic here without destroying the item
	saveInventoryToTable(player)
end

-- Example RemoteEvent for item pickup (if needed)
local PickupItemEvent = Instance.new("RemoteEvent")
PickupItemEvent.Name = "PickupItemEvent"
PickupItemEvent.Parent = game.ReplicatedStorage

PickupItemEvent.OnServerEvent:Connect(function(player, itemName)
	onItemPickup(player, itemName)
end)

-- Example RemoteEvent for item use (if needed)
local UseItemEvent = Instance.new("RemoteEvent")
UseItemEvent.Name = "UseItemEvent"
UseItemEvent.Parent = game.ReplicatedStorage

UseItemEvent.OnServerEvent:Connect(function(player, itemName)
	onItemUse(player, itemName)
end)
