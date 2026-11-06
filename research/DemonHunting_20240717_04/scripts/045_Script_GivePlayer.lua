-- ServerScriptService/MainScripts/GivePlayer
local function findToolInFolder(folder, toolName)
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Tool") and child.Name == toolName then
			return child
		elseif child:IsA("Folder") then
			local foundTool = findToolInFolder(child, toolName)
			if foundTool then
				return foundTool
			end
		end
	end
	return nil
end

local function giveTool(player, toolName)
	local tool = findToolInFolder(game.ReplicatedStorage, toolName)
	if tool then
		local toolClone = tool:Clone()
		toolClone.Parent = player.Backpack
		print("Gave tool: " .. toolName .. " to " .. player.Name)
	else
		warn("Tool: " .. toolName .. " not found in ReplicatedStorage")
	end
end

local function onToolGiven(player, tool)
	local backpack = player.Backpack
	if backpack then
		giveTool(player,tool.Name)
	else
		warn("Player's backpack not found.")
	end
end

game.ReplicatedStorage.Events.InvAddTool.OnServerEvent:Connect(onToolGiven)