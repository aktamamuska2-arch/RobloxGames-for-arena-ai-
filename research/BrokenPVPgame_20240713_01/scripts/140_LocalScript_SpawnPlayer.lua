-- StarterPlayer/StarterPlayerScripts/SpawnPlayer
-- Script in ServerScriptService
local replicatedStorage = game:GetService("ReplicatedStorage")
local spawnPlayer = replicatedStorage:WaitForChild("SpawnPlayer")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")

local lobbyPart = workspace:WaitForChild("LobbyPart")

local function onPlayerAdded(player)
	-- Prevent the player from auto-spawning
	player.CharacterAdded:Connect(function(character)
		-- Move the character to the LobbyPart position
		character:WaitForChild("HumanoidRootPart").CFrame = lobbyPart.CFrame
	end)
end

-- Function to find the 'Spawns' folder within a variable parent folder
local function findSpawnsFolder(parent)
	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Folder") and child.Name == "Spawns" then
			return child
		elseif child:IsA("Folder") then
			local foundFolder = findSpawnsFolder(child)
			if foundFolder then
				return foundFolder
			end
		end
	end
	return nil
end

-- Find the 'Spawns' folder within the Workspace
local spawnsFolder = findSpawnsFolder(workspace)

if not spawnsFolder then
	warn("Spawns folder not found in Workspace.")
	return
end

-- Get all spawn locations from the 'Spawns' folder
local spawnLocations = spawnsFolder:GetChildren()

local function onSpawnPlayerEventFired(player)
	player:LoadCharacter()
	local randomIndex = math.random(1, #spawnLocations)
	local randomSpawn = spawnLocations[randomIndex]
	-- Delay teleport to ensure character is fully loaded
	wait(1)
	if player.Character then
		player.Character:WaitForChild("HumanoidRootPart").CFrame = randomSpawn.CFrame
	end
end

players.PlayerAdded:Connect(onPlayerAdded)
spawnPlayer.OnServerEvent:Connect(onSpawnPlayerEventFired)