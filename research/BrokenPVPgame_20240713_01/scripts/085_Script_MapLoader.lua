-- Workspace/MapLoader
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local MapsFolder = ReplicatedStorage:WaitForChild("Maps")
local Players = game:GetService("Players")
local updateStatus = ReplicatedStorage:FindFirstChild("UpdateStatus")
local hideStatus = ReplicatedStorage:FindFirstChild("HideStatus")
local mapChanged = ReplicatedStorage:FindFirstChild("MapChanged")
local updateTime = ReplicatedStorage:FindFirstChild("UpdateTime")
local changeMode = ReplicatedStorage:WaitForChild("ChangeMode")
--local showShop = ReplicatedStorage:WaitForChild("ShowShop")

local mapTimer = Workspace:WaitForChild("MapTimer")
local lobbyPart = Workspace:WaitForChild("LobbyPart")

-- Singleton check
if _G.MapLoaderRunning then
	return
end
_G.MapLoaderRunning = true

-- Create a BindableFunction to expose loadRandomMap
local loadMapFunction = Instance.new("BindableFunction", Workspace)
loadMapFunction.Name = "LoadMapFunction"

-- Global table to store votes
local votes = {}

function loadRandomMap()
	local currentMapName
	local currentMap = Workspace:FindFirstChild("MapName")
	if currentMap then
		currentMapName = currentMap.Value
	end

	-- Clear current map
	for _, obj in pairs(Workspace:GetChildren()) do
		if obj:FindFirstChild("MapName") then
			obj:Destroy()
		end
	end

	-- Select a random map
	local maps = MapsFolder:GetChildren()
	local randomMap
	repeat
		randomMap = maps[math.random(1, #maps)]
	until not currentMapName or randomMap:FindFirstChild("MapName").Value ~= currentMapName

	-- Clone the map to Workspace
	local clonedMap = randomMap:Clone()
	clonedMap.Parent = Workspace
	Workspace.MapNameNow.Value = clonedMap:FindFirstChild("MapName").Value
	Workspace.MapCreatorNow.Value = clonedMap:FindFirstChild("MapCreator").Value
	mapChanged:FireAllClients(Workspace.MapNameNow.Value, Workspace.MapCreatorNow.Value)

	return clonedMap
end

-- Bind the function to the BindableFunction
loadMapFunction.OnInvoke = loadRandomMap

local startTime = tick() -- Current time in seconds since game started
local nextLoadTime = startTime + mapTimer.Value

local function teleportPlayersToLobby()
	changeMode:FireAllClients("Break")
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			player.Character:SetPrimaryPartCFrame(lobbyPart.CFrame)
		end
	end
	for _, descendant in pairs(workspace:GetDescendants()) do
		if descendant:IsA("Humanoid") then
			local character = descendant.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if not player then
				descendant.Health = 0
			end
		end
	end
end

local function teleportPlayersToSpawns(clonedMap)
	changeMode:FireAllClients("Round")
	for _, descendant in pairs(workspace:GetDescendants()) do
		if descendant:IsA("Humanoid") then
			descendant.Health = 0
		end
	end
	local spawns = clonedMap:FindFirstChild("Spawns"):GetChildren()
	for _, player in pairs(Players:GetPlayers()) do
		local spawnLocation = spawns[math.random(1, #spawns)]
		if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
			local spawnCFrame = spawnLocation.CFrame + Vector3.new(0, 30, 0) -- Teleport 50 studs above spawn location
			player.Character:SetPrimaryPartCFrame(spawnCFrame)
		end
	end
	Workspace.BotCount.Value = 0
end

local function displayVotingGui(player, maps)
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local alwaysOnGui = playerGui:FindFirstChild("AlwaysOn")
	if not alwaysOnGui then return end

	mapFrame = alwaysOnGui:FindFirstChild("MapFrame")
	if not mapFrame then return end

	mapFrame.Visible = true
	mapFrame.Active = true
	mapFrame.Selectable = true

	for i = 1, 3 do
		local mapButton = mapFrame:FindFirstChild("Map"..i)
		if mapButton then
			local map = maps[i]
			mapButton.Image = map:FindFirstChild("Thumbnail").Texture
			mapButton.Active = true
			mapButton.Selectable = true
			mapButton.AutoButtonColor = true
		end
	end

	-- Connect buttons to vote function
	for i = 1, 3 do
		local mapButton = mapFrame:FindFirstChild("Map"..i)
		if mapButton then
			mapButton.MouseButton1Click:Connect(function()
				votes[player.UserId] = i
				mapFrame.Visible = false
				mapFrame.Active = false
				mapFrame.Selectable = false
			end)
		end
	end
end

local function showVotingGuiToAllPlayers(maps)
	changeMode:FireAllClients("Voting")
	for _, player in pairs(Players:GetPlayers()) do
		displayVotingGui(player, maps)
	end
end

local function getWinningMap(maps)
	local voteCounts = {0, 0, 0}

	for _, vote in pairs(votes) do
		voteCounts[vote] = voteCounts[vote] + 1
	end

	local maxVotes = -1
	local winningIndices = {}

	for index, count in ipairs(voteCounts) do
		if count > maxVotes then
			maxVotes = count
			winningIndices = {index}
		elseif count == maxVotes then
			table.insert(winningIndices, index)
		end
	end

	return maps[winningIndices[math.random(1, #winningIndices)]]
end

local function waitUntilMapLoad()
	while true do
		local currentTime = tick()
		if currentTime >= nextLoadTime then
			teleportPlayersToLobby()

			-- Calculate delay
			local delayTime = math.min(#Players:GetPlayers() * 10, 60)
			local halfDelayTime = delayTime / 2

			-- Wait for half of the delay time
			wait(halfDelayTime)

			-- Clear and load the new map
			local maps = MapsFolder:GetChildren()
			local mapChoices = {}
			while #mapChoices < 3 do
				local randomMap = maps[math.random(1, #maps)]
				if not table.find(mapChoices, randomMap) then
					table.insert(mapChoices, randomMap)
				end
			end
			showVotingGuiToAllPlayers(mapChoices)

			wait(halfDelayTime)

			mapFrame.Visible = false
			mapFrame.Active = false
			mapFrame.Selectable = false
			local winningMap = getWinningMap(mapChoices)
			for _, obj in pairs(Workspace:GetChildren()) do
				if obj:FindFirstChild("MapName") then
					obj:Destroy()
				end
			end

			local clonedMap = winningMap:Clone()
			clonedMap.Parent = Workspace

			-- Update map name and creator values
			Workspace.MapNameNow.Value = clonedMap:FindFirstChild("MapName").Value
			Workspace.MapCreatorNow.Value = clonedMap:FindFirstChild("MapCreator").Value
			mapChanged:FireAllClients(Workspace.MapNameNow.Value, Workspace.MapCreatorNow.Value)

			-- Teleport players to random spawn locations in the new map
			teleportPlayersToSpawns(clonedMap)

			startTime = tick()
			nextLoadTime = startTime + mapTimer.Value
		else
			-- Still waiting, display countdown or perform other actions
			Workspace.TimeRemains.Value = tostring(nextLoadTime - currentTime)
			updateTime:FireAllClients()
			wait(1)
		end
	end
end

-- Adjust next load time when mapTimer changes
mapTimer.Changed:Connect(function()
	local currentTime = tick()
	local elapsedTime = currentTime - startTime
	local remainingTime = mapTimer.Value - elapsedTime

	if remainingTime > 0 then
		nextLoadTime = currentTime + remainingTime
	else
		teleportPlayersToLobby()

		-- Calculate delay
		local delayTime = math.min(#Players:GetPlayers() * 10, 60)
		local halfDelayTime = delayTime / 2

		-- Wait for half of the delay time
		wait(halfDelayTime)

		-- Clear and load the new map
		local maps = MapsFolder:GetChildren()
		local mapChoices = {maps[math.random(1, #maps)], maps[math.random(1, #maps)], maps[math.random(1, #maps)]}
		showVotingGuiToAllPlayers(mapChoices)

		wait(halfDelayTime)

		local winningMap = getWinningMap(mapChoices)
		for _, obj in pairs(Workspace:GetChildren()) do
			if obj:FindFirstChild("MapName") then
				obj:Destroy()
			end
		end

		local clonedMap = winningMap:Clone()
		clonedMap.Parent = Workspace

		-- Update map name and creator values
		Workspace.MapNameNow.Value = clonedMap:FindFirstChild("MapName").Value
		Workspace.MapCreatorNow.Value = clonedMap:FindFirstChild("MapCreator").Value
		mapChanged:FireAllClients(Workspace.MapNameNow.Value, Workspace.MapCreatorNow.Value)

		-- Teleport players to random spawn locations in the new map
		teleportPlayersToSpawns(clonedMap)

		startTime = tick()
		nextLoadTime = startTime + mapTimer.Value
	end
end)

-- Initial map load
local initialMap = loadRandomMap()
teleportPlayersToSpawns(initialMap)

-- Start the waiting loop
waitUntilMapLoad()
