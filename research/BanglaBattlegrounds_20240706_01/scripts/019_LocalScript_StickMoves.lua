-- StarterPack/Tool/StickMoves
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
				playAnimation("Swing1")
				sendRemoteEvent("Swing", "BasicPunch", "Heavy Melee")
			elseif comboCount == 2 then
				playAnimation("Swing2")
				sendRemoteEvent("Swing", "BasicPunch", "Light Blunt")
			end

			wait(comboDelay)
			debounce = false
		end

	elseif input.KeyCode == Enum.KeyCode.E then
		if debounce then return end

		debounce = true
		playAnimation("Parry")
		sendRemoteEvent("Parry", "RadialPulse")
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

		-- Touch button for left click action
		local leftClickButton = Instance.new("TextButton")
		leftClickButton.Size = UDim2.new(0, 100, 0, 50)
		leftClickButton.Position = UDim2.new(0.1, 0, 0.8, 0)
		leftClickButton.Text = "Attack"
		leftClickButton.TextScaled = true
		leftClickButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		leftClickButton.Parent = playerGui

		leftClickButton.MouseButton1Click:Connect(function()
			handleInput({ UserInputType = Enum.UserInputType.Touch })
		end)

		-- Touch button for E key action
		local eKeyButton = Instance.new("TextButton")
		eKeyButton.Size = UDim2.new(0, 100, 0, 50)
		eKeyButton.Position = UDim2.new(0.2, 0, 0.8, 0)
		eKeyButton.Text = "Parry"
		eKeyButton.TextScaled = true
		eKeyButton.BackgroundColor3 = Color3.fromRGB(0, 0, 255)
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
