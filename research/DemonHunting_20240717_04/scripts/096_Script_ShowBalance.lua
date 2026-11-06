-- ReplicatedStorage/Tools/Wallet/ShowBalance
-- Reference to the tool
local tool = script.Parent

-- Function to update the Wallet tool's display
local function updateWalletDisplay(player)
	-- Find player's character and check if it exists
	local character = player.Character
	if not character then
		return
	end

	-- Display the player's GoldToken balance using BillboardGui
	local goldTokens = player:FindFirstChild("GoldTokens")
	if goldTokens then
		-- Update BillboardGui
		local billboard = tool.Wallet.Display:FindFirstChild("BillboardGui")
		local label = billboard:FindFirstChild("TextLabel")
		if label then
			label.Text = "GT " .. goldTokens.Value
		end
	end
end

-- Function to handle tool equipped state
local function onEquipped()
	local player = game.Players:GetPlayerFromCharacter(tool.Parent)
	if player then
		updateWalletDisplay(player)
	end
end

-- Function to handle tool unequipped state
local function onUnequipped()
	-- Destroy BillboardGui if it exists
	local billboard = tool:FindFirstChild("GoldTokensBillboard")
	if billboard then
		billboard:Destroy()
	end
end

-- Listen for equipped and unequipped events
tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)