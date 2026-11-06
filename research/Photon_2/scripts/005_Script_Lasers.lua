-- Workspace/Lasers
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Settings for laser beams
local beamSpeed = 100 -- Speed of laser beam movement
local beamLength = 2047 -- Length of each laser beam
local beamThickness = 0.1 -- Thickness of each laser beam part
local beamColor = Color3.fromRGB(255, 0, 0) -- Red color for laser beams
local beamDamage = math.random(0,100) -- Damage applied to player if hit by a beam
local beamLifetime = 2 -- Time in seconds before beam fades away

-- Function to create a laser beam
local function createLaserBeam(player)
	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
	end

	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local beamOrigin = Vector3.new(math.random(-50, 50), math.random(10, 30), math.random(-50, 50)) -- Random origin point for beam

	-- Calculate direction towards player's position
	local direction = (humanoidRootPart.Position - beamOrigin).unit

	-- Create laser beam part
	local beamPart = Instance.new("Part")
	beamPart.Size = Vector3.new(beamThickness, beamThickness, beamLength)
	beamPart.Position = beamOrigin
	beamPart.BrickColor = BrickColor.new(beamColor)
	beamPart.Material = Enum.Material.Neon
	beamPart.CanCollide = true  -- Enable collision to detect hits
	beamPart.Anchored = true
	beamPart.Parent = Workspace

	-- Align beam towards player
	beamPart.CFrame = CFrame.new(beamOrigin, beamOrigin + direction) * CFrame.new(0, 0, -beamLength / 2)

	-- Function to move beam towards player
	local function moveBeam()
		if not humanoidRootPart.Parent then
			beamPart:Destroy()
			return
		end

		local currentPosition = beamPart.Position
		local playerPosition = humanoidRootPart.Position
		local distance = (playerPosition - currentPosition).magnitude

		-- Move beam towards player
		local newPosition = currentPosition + direction * beamSpeed * (1 + math.random(-1, 1) * 0.2)
		beamPart.Position = newPosition

		-- Update beam direction towards player
		local newDirection = (playerPosition - beamPart.Position).unit
		beamPart.CFrame = CFrame.new(beamPart.Position, beamPart.Position + newDirection) * CFrame.new(0, 0, -beamLength / 2)

		-- Check if beam collides with player's character
		if humanoidRootPart.Parent == character then
			-- Apply damage to player if they touch the beam
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and distance < beamLength / 2 then
				humanoid:TakeDamage(beamDamage)
			end
		end

		wait(0.1) -- Adjust movement frequency as needed
	end

	-- Function to fade out and destroy beam after lifetime expires
	local function decayBeam()
		wait(beamLifetime)
		if beamPart and beamPart.Parent then
			for i = 0, 1, 0.1 do
				beamPart.Transparency = i
				wait(0.1) -- Adjust the wait time for faster or slower fading
			end
			beamPart:Destroy()
		end
	end

	-- Start moving the beam towards player
	moveBeam()

	-- Start decaying the beam over time
	spawn(decayBeam)
end

-- Function to continuously create laser beams
local function createRandomLaserBeams()
	while true do
		for _, player in ipairs(Players:GetPlayers()) do
			if player.Character then
				createLaserBeam(player)
			end
		end
		wait(math.random(2, 30)) -- Adjust interval between beam creations
	end
end

-- Start creating random laser beams
spawn(createRandomLaserBeams)
