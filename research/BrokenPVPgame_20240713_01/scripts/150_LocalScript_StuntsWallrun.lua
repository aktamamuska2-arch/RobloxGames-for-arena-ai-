-- StarterPlayer/StarterPlayerScripts/StuntsWallrun
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local isWallRunning = false
local wallRunSpeed = 10 -- Adjust speed as needed
local wallRunDuration = 2 -- Duration in seconds

local function findWall()
	local origin = humanoidRootPart.Position
	local direction = humanoidRootPart.CFrame.LookVector
	local ray = Ray.new(origin, direction * 5)
	local hit, position = workspace:FindPartOnRay(ray, character)
	return hit
end

local function startWallRun()
	if not isWallRunning then
		isWallRunning = true
		local startTime = tick()
		while isWallRunning and (tick() - startTime) < wallRunDuration do
			local hit = findWall()
			if hit then
				local initialCFrame = humanoidRootPart.CFrame
				local targetCFrame = initialCFrame * CFrame.new(0, 0, -wallRunSpeed * 0.1)
				humanoidRootPart.CFrame = initialCFrame:lerp(targetCFrame, 0.1)
				wait(0.05)
			else
				isWallRunning = false
			end
		end
		isWallRunning = false
	end
end

humanoidRootPart.Touched:Connect(function(hit)
	if hit and not isWallRunning then
		local moveDirection = humanoid.MoveDirection
		if moveDirection.Magnitude > 0 then
			startWallRun()
		end
	end
end)
