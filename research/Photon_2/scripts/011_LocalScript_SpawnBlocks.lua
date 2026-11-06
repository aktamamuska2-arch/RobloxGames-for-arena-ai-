-- StarterPlayer/StarterPlayerScripts/SpawnBlocks
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

-- Base part to clone
local basePart = ReplicatedStorage:WaitForChild("Part") -- Ensure Part exists in ReplicatedStorage

-- Function to create a random part with various behaviors
local function createRandomPart()
	local newPart = basePart:Clone()

	-- Set random properties
	newPart.Size = Vector3.new(math.random(1, 5), math.random(1, 5), math.random(1, 5))
	newPart.Position = Vector3.new(math.random(-100, 100), math.random(10, 50), math.random(-100, 100))
	newPart.Rotation = Vector3.new(math.random(0, 360), math.random(0, 360), math.random(0, 360))
	newPart.Anchored = false  -- Allow parts to move
	newPart.CanCollide = false  -- Ensure parts do not collide with players

	-- Random behaviors
	local behavior = math.random(1, 5)
	if behavior == 1 then
		-- Floating around (like Eyes)
		spawn(function()
			while newPart.Parent do
				newPart.CFrame = newPart.CFrame * CFrame.new(math.sin(tick()), 0, math.cos(tick()))
				wait(0.1)
			end
		end)
	elseif behavior == 2 then
		-- Falling from the sky
		newPart.Position = Vector3.new(math.random(-100, 100), 100, math.random(-100, 100))
		spawn(function()
			while newPart.Parent and newPart.Position.Y > 0 do
				newPart.Position = newPart.Position - Vector3.new(0, 1, 0)
				wait(0.1)
			end
			if newPart.Parent then
				newPart.Position = newPart.Position + Vector3.new(0, 1, 0)  -- Adjust position to ground level
			end
		end)
	elseif behavior == 3 then
		-- Become part of the ground
		newPart.Position = Vector3.new(math.random(-100, 100), 0, math.random(-100, 100))
		newPart.Anchored = true
	elseif behavior == 4 then
		-- Scaling up vertically
		spawn(function()
			while newPart.Parent do
				newPart.Size = newPart.Size + Vector3.new(0, 0.1, 0)
				wait(0.1)
			end
		end)
	elseif behavior == 5 then
		-- Moving away from the player
		spawn(function()
			local player = game.Players.LocalPlayer  -- Assuming this script runs on the client side
			while newPart.Parent and player.Character do
				if player.Character and player.Character:IsDescendantOf(workspace) then
					local direction = (newPart.Position - player.Character.HumanoidRootPart.Position).unit
					newPart.Position = newPart.Position + direction * 2
				end
				wait(0.1)
			end
		end)
	end

	-- Parent part to Workspace
	newPart.Parent = Workspace

	-- Function to decay and destroy the part over time
	spawn(function()
		wait(math.random(30, 60))  -- Adjust lifetime
		for i = 1, 100 do  -- Adjust fading steps
			if newPart and newPart.Parent then
				newPart.Transparency = i / 100
			else
				return
			end
			wait(0.1)  -- Adjust decay rate
		end
		if newPart and newPart.Parent then
			newPart:Destroy()
		end
	end)

	return newPart
end

-- Function to handle player added event
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(character)
		-- Call createRandomPart when player's character is added
		createRandomPart()
	end)
end

-- Listen for new players
Players.PlayerAdded:Connect(onPlayerAdded)

-- Function to continuously create and manage random parts
local function createAndManageRandomParts()
	for _ = 1, 1000000 do  -- Adjust number of parts
		createRandomPart()
		wait(0.1)  -- Adjust interval between part creations
	end
end

-- Start creating and managing random parts
spawn(createAndManageRandomParts)
