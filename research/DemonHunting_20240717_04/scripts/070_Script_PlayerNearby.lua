-- ServerStorage/Shop/ShopCrate/PlayerNearby
-- Script inside Proximity part of the giver crate
local ProximityPart = script.Parent:FindFirstChild("Proximity")
local tool = game.ReplicatedStorage.Weapons.Gun.UMP45

-- Check for players nearby
if ProximityPart then
	local playersNearby = {}
	local function isPlayerPart(part)
		local character = part.Parent
		if character and character:IsA("Model") then
			local player = game.Players:GetPlayerFromCharacter(character)
			if player and (part.Name == "HumanoidRootPart" or part.Name == "Torso") then
				return player
			end
		end
		return nil
	end
	local function onTouched(otherPart)
		local player = isPlayerPart(otherPart)
		if player and not playersNearby[player] then
			playersNearby[player] = true
			-- When entering the proximity
			if playersNearby[player] then
				-- While player is in proximity
				local character = otherPart.Parent -- Check if the otherPart's parent is a player character
				local player = game.Players:GetPlayerFromCharacter(character)
				if player then
					-- Access the player's PlayerGui
					local playerGui = player:FindFirstChild("PlayerGui")
					if playerGui then
						-- Fetch specific GUI elements from PlayerGui
						local mainGui = playerGui:FindFirstChild("MainGui")
						if mainGui then
							local buyPrompt = mainGui:FindFirstChild("BuyPrompt")
							if buyPrompt then
								local NameLabel = script.Parent.Display.BillboardGui.NameLabel.Text
								local PriceLabel = script.Parent.Display.BillboardGui.PriceLabel.Text
								local DisplayPrompt = "Buy <b>" .. NameLabel .."</b> for <font color='#00ff00'>" .. PriceLabel .. "</font> ?"
								buyPrompt.TextLabel.Text = DisplayPrompt
								buyPrompt.Visible = true
								buyPrompt.Cancel.MouseButton1Click:Connect(function()
									buyPrompt.Visible = false -- Cancel button
								end)
								buyPrompt.BuyButton.MouseButton1Click:Connect(function()
									-- when player buys the item
									buyPrompt.BuyButton.Visible = false
									local playerGold = player:FindFirstChild("GoldTokens") -- Assuming GoldTokens is an IntValue in the player's data
									local price = tonumber(string.sub(PriceLabel, 4))
									-- Check if player can afford the item
									local playerDebounce = {}
									if playerGold then
										if not playerDebounce[player] then
											playerDebounce[player] = true
											local currentGold = playerGold.Value
											-- Check if player already owns the tool
											local toolOwned = player.Backpack:FindFirstChild(tool.Name)
											if toolOwned then
												buyPrompt.TextLabel.Text = "You already own a " .. NameLabel
												wait(1.25)
												buyPrompt.TextLabel.Text = DisplayPrompt
												buyPrompt.BuyButton.Visible = true
												return
											end
											if currentGold >= price then
												-- Deduct the price from player's balance
												game.ReplicatedStorage.Events.MoneyUpdate:FireClient(player, "GT", price, "spend")
												-- Perform item purchase actions (e.g., add to inventory)
												game.ReplicatedStorage.Events.InvAddTool:FireClient(player, tool)
												wait(0.5)
												print(player.Name .. " now has " .. tostring(player:FindFirstChild("GoldTokens").Value) .. " GT")
												buyPrompt.Visible = false
												wait(1.5)
												playerDebounce[player] = nil
											else
												-- Player can't afford it, show message or handle as needed
												buyPrompt.TextLabel.Text = "You don't have enough Gold Tokens!"
												wait(1.25)
												buyPrompt.TextLabel.Text = DisplayPrompt
											end
										end
									else
										warn("GoldTokens not found for player.")
									end
									wait(0.5)
									playerDebounce[player] = nil
									wait(0.25)
									buyPrompt.BuyButton.Visible = true
								end)
							end
						end
					end
				end
			end
		end
	end
	local function onTouchEnded(otherPart)
		local player = isPlayerPart(otherPart)
		if player and playersNearby[player] then
			playersNearby[player] = nil
			-- When leaving the proximity
			player.PlayerGui.MainGui.BuyPrompt.Visible = false
		end
	end
	ProximityPart.Touched:Connect(onTouched)
	ProximityPart.TouchEnded:Connect(onTouchEnded)
else
	warn("Proximity part not found!")
end
