-- StarterPack/Tool/AxeMoves
local player = game.Players.LocalPlayer
local inpserv = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local debounce = false
local comboDelay = 0.5   -- Adjust as needed for the delay between combo inputs
local holdDelay = 1      -- Adjust as needed for the hold delay before MegaPunch
local tool = script.Parent  -- Assuming the script is directly under the Tool
local toolEquipped = false
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
			playAnimation("Swing")
			sendRemoteEvent("AxeSwing", "RedFlash", "Light Blade")
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
		end
	end)


	-- Create touch buttons for mobile users
	if inpserv.TouchEnabled then
		local playerGui = player:WaitForChild("PlayerGui")

		-- Touch button for left click action
		local leftClickButton = Instance.new("TextButton")
		leftClickButton.Size = UDim2.new(0, 100, 0, 50)
		leftClickButton.Position = UDim2.new(0.1, 0, 0.8, 0)
		leftClickButton.Text = "Swing"
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
