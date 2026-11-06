-- ServerStorage/Shop/Shopkeeper/NPCTalk
local npc = script.Parent
local ChatService = game:GetService("Chat")
local ProximityPart = script.Parent:FindFirstChild("Proximity")

local messages = {
	"Hi there!",
	"What would ya need?"
}

local messageDelay = 1

local function sayMessages()
	for _, message in ipairs(messages) do
		ChatService:Chat(npc.Head, message)
		wait(messageDelay)
	end
end

-- Check for players nearby
if ProximityPart then
	local playersNearby = {}
	local function isPlayerPart(part)
		local character = part.Parent
		if character and character:IsA("Model") then
			local player = game.Players:GetPlayerFromCharacter(character)
			if player and (part.Name == "HumanoidRootPart" or part.Name == "Torso") then
				return player
			end
		end
		return nil
	end
	local function onTouched(otherPart)
		local player = isPlayerPart(otherPart)
		if player and not playersNearby[player] then
			playersNearby[player] = true
			-- When entering the proximity
			if playersNearby[player] then
				-- While player is in proximity
				sayMessages()
			end
		end
	end
	local function onTouchEnded(otherPart)
		local player = isPlayerPart(otherPart)
		if player and playersNearby[player] then
			playersNearby[player] = nil
			-- When leaving the proximity
			ChatService:Chat(npc.Head, "Have a good day!")
		end
	end
	ProximityPart.Touched:Connect(onTouched)
	ProximityPart.TouchEnded:Connect(onTouchEnded)
else
	warn("Proximity part not found!")
end