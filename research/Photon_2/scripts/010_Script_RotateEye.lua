-- ServerScriptService/RotateEye
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Reference to Eye model in ReplicatedStorage
local EyeModel = ReplicatedStorage:WaitForChild("Eye")

-- Function to create and animate Eye models
local function createAndAnimateEye()
	-- Clone the Eye model
	local eyeClone = EyeModel:Clone()

	-- Generate random position within the workspace
	local randomX = math.random(-250, 250)
	local randomY = math.random(5, 50)
	local randomZ = math.random(-250, 250)
	local randomPosition = Vector3.new(randomX, randomY, randomZ)

	-- Set initial position and parent
	eyeClone:SetPrimaryPartCFrame(CFrame.new(randomPosition))
	eyeClone.Parent = Workspace

	-- Function to animate Eye movement
	local function animateEye()
		while eyeClone.Parent do
			-- Generate random destination within workspace
			local randomDestX = math.random(-250, 250)
			local randomDestY = math.random(5, 50)
			local randomDestZ = math.random(-250, 250)
			local randomDestination = Vector3.new(randomDestX, randomDestY, randomDestZ)

			-- Calculate distance and speed
			local distance = (randomDestination - eyeClone.PrimaryPart.Position).magnitude
			local speed = math.random(3, 8)

			-- Tween the Eye to the random destination
			local tweenInfo = TweenInfo.new(distance / speed, Enum.EasingStyle.Linear)
			local tween = TweenService:Create(eyeClone.PrimaryPart, tweenInfo, { Position = randomDestination })
			tween:Play()

			-- Wait for tween to complete or be interrupted
			tween.Completed:Wait()
		end
	end

	-- Start animating the Eye
	spawn(animateEye)
end

-- Function to spawn multiple Eye models
local function spawnMultipleEyes(count)
	for i = 1, count do
		createAndAnimateEye()
		wait(math.random(1, 3))  -- Adjust interval between eye creations
	end
end

-- Adjust the number of Eye models to spawn
spawnMultipleEyes(200)  -- Change the number as desired
