-- ServerScriptService/Main/ItemCheat
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local updateStatus = ReplicatedStorage:FindFirstChild("UpdateStatus")
local hideStatus = ReplicatedStorage:FindFirstChild("HideStatus")

-- Configuration: Define the chat commands and their corresponding tool names
local items = {
	["airstrike"] = "Airstrike",
	["rocket"] = "Rocket Launcher",
	["flash"] = "Flashbang",
	["bodyswap"] = "Bodyswap",
	["invisible"] = "InvisibleCloak",
	["magiccarpet"] = "MagicCarpet",
	["radar"] = "Radar",
	["satellite"] = "Satellite",
	["skele"] = "SkeleScythe",
	["spear"] = "Spear",
}

-- Reference to the folder containing the extra items
local extraItemsFolder = game.ReplicatedStorage:WaitForChild("Items") -- Adjust folder name as per your actual setup

-- Event: Listen for player joining
game.Players.PlayerAdded:Connect(function(player)
	-- Event: Listen for player chatting
	player.Chatted:Connect(function(message)
		-- Check if message starts with "/item"
		if string.sub(message, 1, 5):lower() == "/item" then
			-- Extract command
			local command = string.match(message, "/item%s+(%w+)")
			if command then
				command = command:lower()
				-- Check if command is valid
				if items[command] then
					-- Find corresponding tool in extraItemsFolder
					local toolName = items[command]
					local gearItem = extraItemsFolder:FindFirstChild(toolName)
					if gearItem then
						-- Clone and give tool to player
						local clonedGear = gearItem:Clone()
						clonedGear.Parent = player.Backpack
						updateStatus:FireAllClients(clonedGear.Name .. " has been added!")
						wait(2)
						hideStatus:FireAllClients("")
					else
						warn("Gear item not found:", toolName)
						updateStatus:FireAllClients("Could not find the item!")
						wait(2)
						hideStatus:FireAllClients("")
					end
				end
			end
		end
	end)
end)
