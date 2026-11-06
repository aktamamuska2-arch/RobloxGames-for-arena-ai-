-- ServerScriptService/Main/SpawnNPCs
-- Get necessary services
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Define the NPC model names
local npcModelNames = {}
for _, model in ipairs(ReplicatedStorage.Agents:GetChildren()) do
	table.insert(npcModelNames, model.Name)
end
local botCapacity = workspace:FindFirstChild("BotCapacity")

-- Create or get the RemoteEvents
local updateGUIEvent = ReplicatedStorage:FindFirstChild("UpdateGUIEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
updateGUIEvent.Name = "UpdateGUIEvent"
local hideGUIEvent = ReplicatedStorage:FindFirstChild("HideGUIEvent") or Instance.new("RemoteEvent", ReplicatedStorage)
hideGUIEvent.Name = "HideGUIEvent"
local updateStatus = ReplicatedStorage:FindFirstChild("UpdateStatus") or Instance.new("RemoteEvent", ReplicatedStorage)
updateStatus.Name = "UpdateStatus"
local hideStatus = ReplicatedStorage:FindFirstChild("HideStatus") or Instance.new("RemoteEvent", ReplicatedStorage)
hideStatus.Name = "HideStatus"

-- Function to get all spawn points
local function getAllSpawnPoints()
	local spawnPoints = {}
	for _, spawnPoint in pairs(game.Workspace:GetDescendants()) do
		if spawnPoint:IsA("SpawnLocation") then
			table.insert(spawnPoints, spawnPoint)
		end
	end
	return spawnPoints
end

-- Function to spawn a specific NPC at a random spawn point
local function spawnNPC(npcModelName)
	local botCount = workspace:FindFirstChild("BotCount")
	if botCount and botCount.Value >= botCapacity.Value then
		--warn("Maximum number of NPCs reached!")
		return
	end

	local npcModel = ReplicatedStorage.Agents:FindFirstChild(npcModelName)
	if npcModel then
		local npcClone = npcModel:Clone()
		local humanoid = npcClone:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.DisplayName = npcModelName
			humanoid.NameDisplayDistance = 50
		else
			--warn("No Humanoid found in NPC model!")
		end

		local spawnPoints = getAllSpawnPoints()
		if #spawnPoints > 0 then
			local randomSpawnPoint = spawnPoints[math.random(1, #spawnPoints)]
			npcClone:SetPrimaryPartCFrame(randomSpawnPoint.CFrame)
			npcClone.Parent = workspace
			print("NPC: " .. tostring(npcModelName) .. " spawned at random spawn point")
			if botCount then
				botCount.Value = botCount.Value + 1
			end
		else
			--warn("No spawn points found!")
		end
	else
		--warn("NPC model not found in ReplicatedStorage!")
	end
end

-- Function to spawn all NPCs at random spawn points
local function spawnAllNPCs()
	local botCount = workspace:FindFirstChild("BotCount")
	local remainingSpawns = botCapacity.Value - botCount.Value
	-- Create a table to keep track of NPCs that have been spawned
	local spawnedNPCs = {}
	while remainingSpawns > 0 and #spawnedNPCs < #npcModelNames do
		local randomIndex = math.random(1, #npcModelNames)
		local randomNPCModelName = npcModelNames[randomIndex]
		-- Check if the NPC has already been spawned
		if not table.find(spawnedNPCs, randomNPCModelName) then
			spawnNPC(randomNPCModelName)
			table.insert(spawnedNPCs, randomNPCModelName)
			remainingSpawns = remainingSpawns - 1
		end
	end
end

-- Function to check player count and spawn NPCs accordingly
local function checkPlayerCountAndSpawnNPCs()
	while true do
		local botCount = workspace:FindFirstChild("BotCount")
		local playerCount = #Players:GetPlayers()
		if playerCount < 2 then
			wait(60) -- Wait for the given number of seconds before spawning all NPCs
			if #Players:GetPlayers() < 2 then
				updateStatus:FireAllClients("NPCs will automatically arrive until more players join") -- if only 1 player, then make info text visible
				if not botCount or botCount.Value >= botCapacity.Value then
					--warn("Maximum number of NPCs reached or BotCount not found!")
					return
				end
				updateGUIEvent:FireAllClients("Agents have arrived!")
				spawnAllNPCs()
				print("All NPCs spawned at random spawn points")
				wait(3)
				hideGUIEvent:FireAllClients()
			end
		else
			hideStatus:FireAllClients() -- when more than 1 player, remove status text
			wait(10) -- Wait for 10 seconds
			if math.random() < 0.05 then -- 5% chance
				local npcName = npcModelNames[math.random(1, #npcModelNames)]
				local botCount = workspace:FindFirstChild("BotCount")
				if botCount and botCount.Value >= botCapacity.Value then
					--warn("Maximum number of NPCs reached!")
					return
				end
				spawnNPC(npcName)
				updateGUIEvent:FireAllClients(npcName .. " has arrived!")
				wait(3)
				hideGUIEvent:FireAllClients()
			end
		end
	end
end

-- Start the player count checking coroutine
spawn(function()
	checkPlayerCountAndSpawnNPCs()
end)

-- Function to handle player chat
local function onPlayerChatted(player, message)
	local command, argument = message:match("^/(%w+)%s*(.*)")

	if command == "npc" then
		local npcModelName = argument
		local botCount = workspace:FindFirstChild("BotCount")
		local botCapacity = workspace:FindFirstChild("BotCapacity")
		if botCount and botCapacity and botCount.Value >= botCapacity.Value then
			--warn("Maximum number of NPCs reached!")
			return
		end
		-- spawn all NPCs during a multiplayer session
		if argument == "all" then
			spawnAllNPCs()
		end
		-- useless feature for me feeling too lonely
		if npcModelName == "Assistant" then
			local npcModel = ReplicatedStorage:FindFirstChild("Assistant")
			if npcModel then
				local npcClone = npcModel:Clone()
				local humanoid = npcClone:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.DisplayName = npcModelName
					humanoid.NameDisplayDistance = 50
				else
					--warn("No Humanoid found in NPC model!")
				end
				npcClone:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame)
				npcClone.Parent = game.Workspace
				print("NPC: " .. tostring(npcModelName) .. " spawned at random spawn point")
				if botCount then
					botCount.Value = botCount.Value + 1
				end
			else
				--warn("NPC model not found in ReplicatedStorage!")
			end
		end
		spawnNPC(npcModelName)
		updateStatus:FireAllClients(tostring(ReplicatedStorage:FindFirstChild(npcModelName).Name) .. " has been spawned!")
		wait(2)
		hideStatus:FireAllClients("")
	end
end

-- Connect the chat event
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end)