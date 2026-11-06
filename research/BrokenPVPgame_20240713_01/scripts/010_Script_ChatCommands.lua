-- ServerScriptService/Main/ChatCommands
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local mapTimer = Workspace:FindFirstChild("MapTimer")
local mapLoader = Workspace:WaitForChild("MapLoader")
local updateStatus = ReplicatedStorage:FindFirstChild("UpdateStatus")
local hideStatus = ReplicatedStorage:FindFirstChild("HideStatus")

local loadMapFunction = Workspace:WaitForChild("LoadMapFunction")

-- Function to handle player chat
local function onPlayerChatted(player, message)
	local command, argument = message:match("^/(%w+)%s*(.*)")

	-- /maploader [on/off]
	if command == "maploader" then
		local enabled = argument:lower()
		if enabled == "true" or enabled == "on" then
			mapLoader.Enabled = true
			updateStatus:FireAllClients("Automatic map loading turned ON")
			wait(2)
			hideStatus:FireAllClients()
		elseif enabled == "false" or enabled == "off" then
			mapLoader.Enabled = false
			updateStatus:FireAllClients("Automatic map loading turned OFF")
			wait(2)
			hideStatus:FireAllClients()
		end
	-- /changemap
	elseif command == "changemap" then
		-- Call loadRandomMap from MapLoader using the BindableFunction
		loadMapFunction:Invoke()
	-- /maptimer [123/default]
	elseif command == "maptimer" then
		if typeof(tonumber(argument)) == "number" then
			local newtime = math.floor(tonumber(argument))
			mapTimer.Value = newtime
			updateStatus:FireAllClients("Maps will change every " .. tostring(math.floor(mapTimer.Value / 60)) .. ":" .. tostring(mapTimer.Value % 60) .. " minutes.")
			wait(2)
			hideStatus:FireAllClients()
		elseif argument:lower() == "default" then
			mapTimer.Value = 300
			updateStatus:FireAllClients("Maps will change every " .. tostring(math.floor(mapTimer.Value / 60)) .. ":" .. tostring(mapTimer.Value % 60) .. " minutes.")
			wait(2)
			hideStatus:FireAllClients()
		else
			warn("No argument provided for /maptimer command.")
			updateStatus:FireClient("Please provide a valid number of seconds or 'default'.")
			wait(2)
			hideStatus:FireClient()
		end
		-- /doublejump [on/off]
	elseif command == "doublejump" then
		local enabled = argument:lower()
		if enabled == "true" or enabled == "on" then
			game.StarterPlayer.StarterPlayerScripts.DoubleJump.Enabled = true
			updateStatus:FireAllClients("Fly-jump mode turned ON")
			wait(2)
			hideStatus:FireAllClients()
		elseif enabled == "false" or enabled == "off" then
			game.StarterPlayer.StarterPlayerScripts.DoubleJump.Enabled = false
			updateStatus:FireAllClients("Fly-jump mode turned OFF")
			wait(2)
			hideStatus:FireAllClients()
		end
	end
end

-- Connect the chat event
Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end)
