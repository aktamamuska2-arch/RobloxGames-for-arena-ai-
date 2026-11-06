-- StarterPack/Tool/PunchMoves
local player = game.Players.LocalPlayer
local inpserv = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local debounce = false
local comboTimer = 0
local comboCount = 0
local maxComboCount = 3  -- Adjust as needed for the maximum number of combos
local comboDelay = 0.5   -- Adjust as needed for the delay between combo inputs
local holdDelay = 1      -- Adjust as needed for the hold delay before MegaPunch
local tool = script.Parent  -- Assuming the script is directly under the Tool
local toolEquipped = false
local runServiceConnection
local mouseButtonDown = false


local function playAnimation(animationName)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local animation = humanoid:LoadAnimation(script[animationName])
		if animation then
			animation:Play()
		else
			print(animationName .. " animation not found!")
		end
	else
		print("Character or humanoid not found!")
	end
end

local function sendRemoteEvent(actionName, vfx, weaponType)
	game.ReplicatedStorage.Events.Combat:FireServer(actionName, vfx, weaponType)
end

local function handleInput(input)
	if not toolEquipped then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		mouseButtonDown = true
		while mouseButtonDown do
			if debounce then return end
			debounce = true

			-- Increase combo count and reset timer if within combo delay
			if comboTimer <= comboDelay then
				comboCount = comboCount + 1
				if comboCount > maxComboCount then
					comboCount = 1  -- Restart combo sequence
				end
			else
				comboCount = 1  -- Start new combo sequence
			end

			-- Reset timer for next input
			comboTimer = 0

			-- Determine which animation to play based on combo count
			if comboCount == 1 then
				playAnimation("Punch")
				sendRemoteEvent("Punch", "BasicPunch", "Light Melee")
			elseif comboCount == 2 then
				playAnimation("HardSmack")
				sendRemoteEvent("HardSmack", "BasicPunch", "Light Melee")
			elseif comboCount == 3 then
				playAnimation("MegaPunch")
				sendRemoteEvent("MegaPunch", "BasicPunch", "Heavy Melee")
			end

			wait(comboDelay)
			debounce = false
		end
	elseif input.KeyCode == Enum.KeyCode.E then
		if debounce then return end

		debounce = true
		playAnimation("Parry")
		sendRemoteEvent("Parry", "BasicPunch")
		wait(comboDelay)
		debounce = false
	end
end


local function onEquipped()
	toolEquipped = true
	inpserv.InputBegan:Connect(function(input, isProcessed)
		if isProcessed then return end
		handleInput(input)
	end)

	inpserv.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			mouseButtonDown = false
			comboTimer = 0
		end
	end)


	runServiceConnection = runService.Stepped:Connect(function(_, dt)
		comboTimer = comboTimer + dt
	end)

	-- Create touch buttons for mobile users
	if inpserv.TouchEnabled then
		local playerGui = player:WaitForChild("PlayerGui")

		-- Touch buttons for combo actions
		local punchButton = Instance.new("TextButton")
		punchButton.Size = UDim2.new(0, 100, 0, 50)
		punchButton.Position = UDim2.new(0.1, 0, 0.8, 0)
		punchButton.Text = "Punch"
		punchButton.TextScaled = true
		punchButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		punchButton.Parent = playerGui

		punchButton.MouseButton1Click:Connect(function()
			handleInput({ UserInputType = Enum.UserInputType.Touch })
		end)

		local hardSmackButton = Instance.new("TextButton")
		hardSmackButton.Size = UDim2.new(0, 100, 0, 50)
		hardSmackButton.Position = UDim2.new(0.3, 0, 0.8, 0)
		hardSmackButton.Text = "HardSmack"
		hardSmackButton.TextScaled = true
		hardSmackButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
		hardSmackButton.Parent = playerGui

		hardSmackButton.MouseButton1Click:Connect(function()
			handleInput({ UserInputType = Enum.UserInputType.Touch })
		end)

		local megaPunchButton = Instance.new("TextButton")
		megaPunchButton.Size = UDim2.new(0, 100, 0, 50)
		megaPunchButton.Position = UDim2.new(0.5, 0, 0.8, 0)
		megaPunchButton.Text = "MegaPunch"
		megaPunchButton.TextScaled = true
		megaPunchButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
		megaPunchButton.Parent = playerGui

		megaPunchButton.MouseButton1Click:Connect(function()
			handleInput({ UserInputType = Enum.UserInputType.Touch })
		end)

		-- Touch button for E key action
		local eKeyButton = Instance.new("TextButton")
		eKeyButton.Size = UDim2.new(0, 100, 0, 50)
		eKeyButton.Position = UDim2.new(0.7, 0, 0.8, 0)
		eKeyButton.Text = "Parry"
		eKeyButton.TextScaled = true
		eKeyButton.BackgroundColor3 = Color3.fromRGB(128, 128, 128)
		eKeyButton.Parent = playerGui

		eKeyButton.MouseButton1Click:Connect(function()
			handleInput({ KeyCode = Enum.KeyCode.E })
		end)
	end
end

local function onUnequipped()
	toolEquipped = false
	if runServiceConnection then
		runServiceConnection:Disconnect()
	end

	-- Clean up touch buttons for mobile users
	if inpserv.TouchEnabled then
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			for _, guiObject in ipairs(playerGui:GetChildren()) do
				if guiObject:IsA("TextButton") then
					guiObject:Destroy()
				end
			end
		end
	end
end

tool.Equipped:Connect(onEquipped)
tool.Unequipped:Connect(onUnequipped)
