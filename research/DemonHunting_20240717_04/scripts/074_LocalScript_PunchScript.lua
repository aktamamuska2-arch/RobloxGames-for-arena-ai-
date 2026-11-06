-- ReplicatedStorage/Tools/Martial/PunchScript
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local tool = script.Parent

-- Control Variables
local LIGHT_DAMAGE = script.LIGHT_DAMAGE.Value
local HEAVY_DAMAGE = script.HEAVY_DAMAGE.Value
local LIGHT_SOUND = script.LIGHT_SOUND.Value
local HEAVY_SOUND = script.HEAVY_SOUND.Value
local SWING_SOUND = script.SWING_SOUND.Value
local COOLDOWN = script.COOLDOWN.Value -- Cooldown time in seconds
local VFX_TYPE = "MartialStrike"
local punchAnims = {"Punch1", "Punch2", "Punch3"}
local heavyAnims = {"Swing1", "Swing3", "Sweep1"}

local lastPunchTime = 0
local holdingMouse = false

-- UI for Cooldown Progress Bar
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
local progressBarFrame = Instance.new("Frame", screenGui)
local progressBar = Instance.new("Frame", progressBarFrame)

progressBarFrame.Size = UDim2.new(0, 80, 0, 3)
progressBarFrame.BackgroundTransparency = 0.5
progressBarFrame.BackgroundColor3 = Color3.new(0, 0, 0)
progressBarFrame.BorderSizePixel = 0
progressBarFrame.Visible = false

progressBar.Size = UDim2.new(1, 0, 1, 0)
progressBar.BackgroundColor3 = Color3.new(0.5, 0.5, 0.5)

local function updateProgressBar()
	local elapsed = tick() - lastPunchTime
	local progress = math.min(elapsed / COOLDOWN, 1)
	progressBar.Size = UDim2.new(progress, 0, 1, 0)
end

local function performPunch(isHeavy)
	if tick() - lastPunchTime < COOLDOWN then return end
	lastPunchTime = tick()

	local data = {
		isHeavy = isHeavy,
		LIGHT_DAMAGE = LIGHT_DAMAGE,
		HEAVY_DAMAGE = HEAVY_DAMAGE,
		LIGHT_SOUND = LIGHT_SOUND,
		HEAVY_SOUND = HEAVY_SOUND,
		SWING_SOUND = SWING_SOUND,
		VFX_TYPE = VFX_TYPE,
		COOLDOWN = COOLDOWN,
		punchAnims = punchAnims,
		heavyAnims = heavyAnims,
	}

	game.ReplicatedStorage.Events.CombatHit:FireServer(data)
end

local function onEquipped()
	progressBarFrame.Visible = true

	local inputBeganConn
	local inputEndedConn
	local renderSteppedConn

	inputBeganConn = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingMouse = true
			while holdingMouse do
				local isHeavy = math.random() < 0.2 -- 20% chance to perform a heavy punch
				performPunch(isHeavy)
				wait(COOLDOWN)
			end
		end
	end)

	inputEndedConn = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			holdingMouse = false
		end
	end)

	renderSteppedConn = RunService.RenderStepped:Connect(function()
		local mouseLocation = UserInputService:GetMouseLocation()
		progressBarFrame.Position = UDim2.new(0, mouseLocation.X - 40, 0, mouseLocation.Y + 20)
		updateProgressBar()
	end)

	tool.Unequipped:Connect(function()
		holdingMouse = false
		progressBarFrame.Visible = false
		-- Disconnect input and render stepped events
		inputBeganConn:Disconnect()
		inputEndedConn:Disconnect()
		renderSteppedConn:Disconnect()
	end)
end

tool.Equipped:Connect(onEquipped)
