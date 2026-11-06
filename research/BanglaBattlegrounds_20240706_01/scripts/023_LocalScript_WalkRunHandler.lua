-- StarterGui/WalkRunHandler
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local isSprinting = false
local isDashing = false
local isEvading = false
local sprintDuration = 0
local normalWalkSpeed = 16  -- Default walk speed
local sprintWalkSpeed = normalWalkSpeed * 2  -- Sprint walk speed
local dashWalkSpeed = sprintWalkSpeed * 2  -- Dash (maximum speed) walk speed
local evadeDistance = 4  -- Distance to evade
local evadeDuration = 0.2  -- Duration of evade move
local accelerationRate = 5  -- Speed increase per second
local decelerationRate = 8  -- Speed decrease per second
local dashThreshold = 2  -- Time in seconds to reach dash speed

local walkAnimationId = "rbxassetid://18341853673"
local sprintAnimationId = "rbxassetid://18341864859"
local dashAnimationId = "rbxassetid://18341871589"
local evadeAnimationId = "rbxassetid://18341871589"  -- Replace with your evade animation ID

local walkAnimation = Instance.new("Animation")
walkAnimation.AnimationId = walkAnimationId

local sprintAnimation = Instance.new("Animation")
sprintAnimation.AnimationId = sprintAnimationId

local dashAnimation = Instance.new("Animation")
dashAnimation.AnimationId = dashAnimationId

local evadeAnimation = Instance.new("Animation")
evadeAnimation.AnimationId = evadeAnimationId

local walkAnimTrack = humanoid:LoadAnimation(walkAnimation)
local sprintAnimTrack = humanoid:LoadAnimation(sprintAnimation)
local dashAnimTrack = humanoid:LoadAnimation(dashAnimation)
local evadeAnimTrack = humanoid:LoadAnimation(evadeAnimation)

-- Function to replace default walk animation
local function replaceWalkAnimation()
	if isSprinting or isDashing or isEvading then return end
	-- Stop all other animations
	for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
		track:Stop()
	end
	-- Play the custom walk animation
	walkAnimTrack:Play()
end

-- Function to start sprinting
local function startSprinting()
	if isSprinting then return end
	isSprinting = true
	isDashing = false
	sprintDuration = 0
	walkAnimTrack:Stop()
	sprintAnimTrack:Play()
end

-- Function to stop sprinting
local function stopSprinting()
	if not isSprinting then return end
	isSprinting = false
	isDashing = false
	sprintDuration = 0
	sprintAnimTrack:Stop()
	dashAnimTrack:Stop()
	replaceWalkAnimation()
end

-- Function to handle speed changes
local function updateSpeed(deltaTime)
	if isSprinting then
		sprintDuration = sprintDuration + deltaTime
		if sprintDuration >= dashThreshold then
			isDashing = true
		end

		if isDashing then
			humanoid.WalkSpeed = math.min(humanoid.WalkSpeed + accelerationRate * deltaTime, dashWalkSpeed)
			if not dashAnimTrack.IsPlaying then
				sprintAnimTrack:Stop()
				dashAnimTrack:Play()
			end
		else
			humanoid.WalkSpeed = math.min(humanoid.WalkSpeed + accelerationRate * deltaTime, sprintWalkSpeed)
		end
	else
		humanoid.WalkSpeed = math.max(humanoid.WalkSpeed - decelerationRate * deltaTime, normalWalkSpeed)
	end
end

-- Function to handle evade move
local function performEvade()
	if isEvading then return end
	isEvading = true
	isSprinting = false
	isDashing = false
	sprintAnimTrack:Stop()
	dashAnimTrack:Stop()
	evadeAnimTrack:Play()

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local direction = Vector3.new(0, 0, 0)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) or UserInputService:IsKeyDown(Enum.KeyCode.Up) then
		direction = rootPart.CFrame.LookVector
	elseif UserInputService:IsKeyDown(Enum.KeyCode.S) or UserInputService:IsKeyDown(Enum.KeyCode.Down) then
		direction = -rootPart.CFrame.LookVector
	elseif UserInputService:IsKeyDown(Enum.KeyCode.A) or UserInputService:IsKeyDown(Enum.KeyCode.Left) then
		direction = -rootPart.CFrame.RightVector
	elseif UserInputService:IsKeyDown(Enum.KeyCode.D) or UserInputService:IsKeyDown(Enum.KeyCode.Right) then
		direction = rootPart.CFrame.RightVector
	else
		direction = -rootPart.CFrame.LookVector
	end

	local targetPosition = rootPart.Position + direction * evadeDistance
	local originalGravity = workspace.Gravity
	workspace.Gravity = 0  -- Disable gravity during the evade

	local startTime = tick()
	RunService.RenderStepped:Connect(function()
		local elapsedTime = tick() - startTime
		if elapsedTime < evadeDuration then
			rootPart.CFrame = CFrame.new(rootPart.Position:Lerp(targetPosition, elapsedTime / evadeDuration))
		else
			workspace.Gravity = originalGravity  -- Restore gravity after the evade
			isEvading = false
		end
	end)
end

-- Create a touch button for mobile users
local function createTouchButtons()
	local touchGui = Instance.new("ScreenGui")
	touchGui.Name = "TouchGui"
	touchGui.ResetOnSpawn = false
	touchGui.Parent = player:WaitForChild("PlayerGui")

	-- Sprint button
	local sprintButton = Instance.new("TextButton")
	sprintButton.Size = UDim2.new(0, 100, 0, 50)
	sprintButton.Position = UDim2.new(0.1, 0, 0.8, 0)
	sprintButton.Text = "Sprint"
	sprintButton.TextScaled = true
	sprintButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	sprintButton.Parent = touchGui

	sprintButton.MouseButton1Click:Connect(function()
		startSprinting()
	end)

	-- Evade button
	local evadeButton = Instance.new("TextButton")
	evadeButton.Size = UDim2.new(0, 100, 0, 50)
	evadeButton.Position = UDim2.new(0.3, 0, 0.8, 0)
	evadeButton.Text = "Evade"
	evadeButton.TextScaled = true
	evadeButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
	evadeButton.Parent = touchGui

	evadeButton.MouseButton1Click:Connect(function()
		performEvade()
	end)
end

-- Key press event
UserInputService.InputBegan:Connect(function(input, isProcessed)
	if isProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		startSprinting()
	elseif input.KeyCode == Enum.KeyCode.Q then
		performEvade()
	end
end)

-- Key release event
UserInputService.InputEnded:Connect(function(input, isProcessed)
	if isProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		stopSprinting()
	end
end)

-- Ensure sprinting stops if the character dies
humanoid.Died:Connect(stopSprinting)

-- Connect to Humanoid.Running to detect when the player is walking
humanoid.Running:Connect(function(speed)
	if isSprinting or isDashing then return end
	if speed > 0 then
		replaceWalkAnimation()
	else
		walkAnimTrack:Stop()
	end
end)

-- Update speed smoothly
RunService.RenderStepped:Connect(function(deltaTime)
	updateSpeed(deltaTime)
end)

-- Create touch buttons if on a mobile device
if UserInputService.TouchEnabled then
	createTouchButtons()
end
