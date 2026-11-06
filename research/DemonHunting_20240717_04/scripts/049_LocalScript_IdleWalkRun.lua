-- StarterGui/IdleWalkRun
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local energy = player:WaitForChild("Energy") -- Assuming Energy is an IntValue
local maxEnergy = player:WaitForChild("MaxEnergy").Value

-- Animations
local animFolder = ReplicatedStorage:WaitForChild("Animations")
local idleAnim = humanoid:LoadAnimation(animFolder:WaitForChild("IdleAnim"))
local walkAnim = humanoid:LoadAnimation(animFolder:WaitForChild("WalkAnim"))
local sprintAnim = humanoid:LoadAnimation(animFolder:WaitForChild("SprintAnim"))

-- Sounds
local soundsFolder = ReplicatedStorage:WaitForChild("Sounds")
local footstepSound = soundsFolder:WaitForChild("Footsteps"):Clone()
footstepSound.Looped = true
footstepSound.Parent = character:WaitForChild("HumanoidRootPart")

local function playFootstepSound(speed)
	footstepSound:Stop()
	footstepSound.PlaybackSpeed = speed
	footstepSound:Play()
end

local function stopFootstepSound()
	footstepSound:Stop()
end

local function playAnimation(anim)
	idleAnim:Stop()
	walkAnim:Stop()
	sprintAnim:Stop()
	anim:Play()
end

local sprinting = false
local lastEnergyTick = tick()
local energyReplenishDelay = 1.5
local energyDepleteRate = 5 -- Increase this value to deplete energy faster
local energyReplenishRate = 1 -- Energy replenishment per second

local function manageEnergy()
	while true do
		local now = tick()
		if sprinting then
			if now - lastEnergyTick >= 1 then
				energy.Value = math.max(0, energy.Value - energyDepleteRate)
				lastEnergyTick = now
				if energy.Value <= 0 then
					sprinting = false
				end
			end
		else
			if now - lastEnergyTick >= energyReplenishDelay then
				energy.Value = math.min(maxEnergy, energy.Value + energyReplenishRate)
				lastEnergyTick = now
			end
		end
		wait(0.1)
	end
end

coroutine.wrap(manageEnergy)()

local function onStateChanged()
	if humanoid.MoveDirection.Magnitude == 0 then
		playAnimation(idleAnim)
		sprinting = false
	elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) and energy.Value > 0 then
		humanoid.WalkSpeed = 45
		playAnimation(sprintAnim)
		sprinting = true
	else
		humanoid.WalkSpeed = 25
		playAnimation(walkAnim)
		sprinting = false
	end
end

humanoid.Running:Connect(onStateChanged)
UIS.InputBegan:Connect(onStateChanged)
UIS.InputEnded:Connect(onStateChanged)

-- Ensure the initial state is set correctly
onStateChanged()
