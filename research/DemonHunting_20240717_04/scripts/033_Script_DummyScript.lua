-- Workspace/Dummies/Boss/DummyScript
local npc = script.Parent
local humanoid = npc:FindFirstChildOfClass("Humanoid")
local respawnTime = 5
local originalPosition = npc.HumanoidRootPart.Position

local function respawnNPC()
	local npcClone = npc:Clone()
	npcClone.Parent = npc.Parent
	npcClone.HumanoidRootPart.Position = originalPosition
	npc:Destroy() -- Destroy the old NPC
	print("NPC respawned at position: " .. tostring(originalPosition))
	npcClone.Humanoid.Health = npcClone.Humanoid.MaxHealth
end

local function dropGoldCoin()
	local coinTemplate = game.ReplicatedStorage.Models:FindFirstChild("GoldCoin") -- Ensure you have a GoldCoin model in ReplicatedStorage
	if coinTemplate then
		local coinClone = coinTemplate:Clone()
		coinClone.Parent = workspace

		-- Set the position of the PrimaryPart of the coinClone
		local primaryPart = coinClone.PrimaryPart
		if primaryPart then
			primaryPart.CFrame = npc.PrimaryPart.CFrame
		else
			warn("GoldCoin does not have a PrimaryPart set")
			coinClone:Destroy() -- Destroy the coinClone if it doesn't have a PrimaryPart
			return
		end

		local textLabel = coinClone:FindFirstChild("Display"):FindFirstChild("BillboardGui"):FindFirstChild("TextLabel")
		if textLabel then
			local randomValue = math.random(1000, 10000)
			textLabel.Text = "GT " .. tostring(randomValue)
			print("Dropped GoldCoin with value: " .. textLabel.Text)
		end
	else
		warn("GoldCoin template not found in ReplicatedStorage")
	end
end

humanoid.Died:Connect(function()
	dropGoldCoin()
	wait(respawnTime)
	respawnNPC()
end)
