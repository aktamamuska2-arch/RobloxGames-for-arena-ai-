-- ServerScriptService/Main/SpawnPlayers
-- Script in ServerScriptService
local BadgeService = game:GetService("BadgeService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local spawnPlayer = replicatedStorage:WaitForChild("SpawnPlayer")
local players = game:GetService("Players")
local workspace = game:GetService("Workspace")

local lobbyPart = workspace:WaitForChild("LobbyPart")

-- Table to store whether each player has spawned
local spawnedPlayers = {}

local function onPlayerAdded(player)
	-- Prevent the player from auto-spawning
	player.CharacterAdded:Connect(function(character)
		if spawnedPlayers[player.UserId] then
			return  -- Exit if player has already spawned
		end
		if not BadgeService:UserHasBadgeAsync(player.UserId, 1828191644643261) then
			BadgeService:AwardBadge(player.UserId, 1828191644643261)
			print(player.Name .. " has been awarded the badge!")
		else
			print(player.Name .. " already has the badge.")
		end
		-- Move the character to the LobbyPart position
		character:WaitForChild("HumanoidRootPart").CFrame = lobbyPart.CFrame
		-- Mark player as spawned for this session
		spawnedPlayers[player.UserId] = true
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
	findSpawnsFolder(workspace)
end

-- Get all spawn locations from the 'Spawns' folder
if spawnsFolder then
	spawnLocations = spawnsFolder:GetChildren()
end

function onSpawnPlayerEventFired(player)
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