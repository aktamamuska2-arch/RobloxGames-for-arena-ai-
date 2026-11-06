-- StarterGui/ShopGui/Frame/Swords
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

local RunService = game:GetService("RunService")
local closeButton = script.Parent.Close
local SwordsButton = script.Parent.SwordsButton
local SwordsPanel = script.Parent.SwordsPanel
local Template = script.Parent.Template
local ToolTipTemplate = script.Parent.ToolTipTemplate -- Assuming ToolTipTemplate is in the same directory

-- Function to set up the model in the ViewportFrame
local function setupViewportModel(viewportFrame, model)
	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	local modelClone = model:Clone()
	modelClone.Parent = viewportFrame

	local primaryPart = modelClone.PrimaryPart or modelClone:FindFirstChildWhichIsA("BasePart")
	if primaryPart then
		local radius = 2.85 -- Distance from the primary part
		local angle = math.rad(90) -- Initial angle

		-- Initial camera position
		camera.CFrame = CFrame.new(primaryPart.Position) * CFrame.new(0, 0, radius) * CFrame.Angles(0, math.rad(angle), 0)

		-- Rotate the camera around the primaryPart 360 degrees continuously using RenderStepped
		RunService.RenderStepped:Connect(function()
			angle = angle + 1
			camera.CFrame = CFrame.new(primaryPart.Position) * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, radius)
		end)
	end
end

-- Function to populate the panel with items
local function populatePanel()
	if SwordsPanel.Parent.EmptyPanel.Visible then
		SwordsPanel.Parent.EmptyPanel.Visible = false
	end
	SwordsPanel.Visible = true

	-- Clear existing items if any
	for _, child in ipairs(SwordsPanel:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Fetch items from ReplicatedStorage
	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")
	if weaponsFolder then
		local swordsFolder = weaponsFolder:FindFirstChild("Swords")
		if swordsFolder then
			-- Iterate through items in Swords folder
			for _, tool in ipairs(swordsFolder:GetChildren()) do
				-- Clone the template and populate it
				local newItem = Template:Clone()
				newItem.Visible = true
				newItem.Parent = SwordsPanel
				newItem.TextLabel.Text = tool:FindFirstChild("WEAPON_NAME").Value -- Assuming WEAPON_NAME is a StringValue in each tool

				-- Set up the model in the ViewportFrame
				local viewportFrame = newItem:FindFirstChild("ViewportFrame")
				if viewportFrame then
					local model = tool:FindFirstChildOfClass("Model")
					if model then
						setupViewportModel(viewportFrame, model)
					end
				end

				-- Mouse click event for showing tooltip
				newItem.ItemButton.MouseButton1Click:Connect(function()
					-- Clone and show tooltip
					local tooltip = ToolTipTemplate:Clone()
					tooltip.Visible = true
					tooltip.Parent = newItem

					-- Fetch details from the tool
					local weaponName = tool:FindFirstChild("WEAPON_NAME").Value
					local cooldown = tool:FindFirstChild("COOLDOWN").Value
					local price = tool:FindFirstChild("PRICE").Value
					local lightDamage = tool:FindFirstChild("LIGHT_DAMAGE").Value
					local heavyDamage = tool:FindFirstChild("HEAVY_DAMAGE").Value

					-- Update tooltip labels
					tooltip.NameLabel.Text = weaponName
					tooltip.CooldownLabel.Text = cooldown
					tooltip.PriceLabel.Text = price
					tooltip.DamageLabel.Text = lightDamage .. " - " .. heavyDamage

					tooltip.BuyButton.MouseButton1Click:Connect(function()
						-- when player buys the item
						tooltip.BuyButton.Visible = false
						local playerGold = player:FindFirstChild("GoldTokens") -- Assuming GoldTokens is an IntValue in the player's data
						-- Check if player can afford the item
						local playerDebounce = {}
						if playerGold then
							if not playerDebounce[player] then
								playerDebounce[player] = true
								local currentGold = playerGold.Value
								-- Check if player already owns the tool
								local toolOwned = player.Backpack:FindFirstChild(tool.Name)
								if toolOwned then
									tooltip.Status.Text = "Already owned!"
									tooltip.Status.Visible = true
									wait(1.25)
									tooltip.Status.Visible = false
									tooltip.BuyButton.Visible = true
									return
								end
								if currentGold >= price then
									-- Deduct the price from player's balance
									game.ReplicatedStorage.Events.MoneyUpdate:FireServer("GT", price, "spend")
									-- Perform item purchase actions (e.g., add to inventory)
									print(player.Name .. " attempted to buy a " .. tool.Name)
									game.ReplicatedStorage.Events.InvAddTool:FireServer(tool) -- Send the tool's name instead of the tool instance
									wait(0.5)
									print(player.Name .. " now has " .. tostring(player:FindFirstChild("GoldTokens").Value) .. " GT")
									tooltip.Status.Visible = true
									tooltip.Status.Text = "Success!"
									game.ReplicatedStorage.Sounds.Coins:Play() -- play the ka-ching sound
									wait(1.5)
									tooltip.Status.Visible = false
									playerDebounce[player] = nil
								else
									-- Player can't afford it, show message or handle as needed
									tooltip.Status.Visible = true
									tooltip.Status.Text = "Cannot afford!"
									wait(1.25)
									tooltip.Status.Visible = false
								end
							end
						else
							warn("GoldTokens not found for player.")
						end
					end)
					tooltip.BuyButton.Visible = true
					-- Auto-hide tooltip after 5 seconds
					wait(5)
					tooltip:Destroy()
				end)
			end
		else
			warn("Swords folder not found in Weapons")
		end
	else
		warn("Weapons folder not found in ReplicatedStorage")
	end
end

-- Connect the button click to populate the panel
SwordsButton.MouseButton1Click:Connect(populatePanel)