-- Workspace/Dummies/DewanMukto/NPCTalk
local npc = script.Parent -- Assuming this script is placed inside the NPC model or part

local ChatService = game:GetService("Chat")

-- Messages to be said
local messages = {
	"Hey there!",
	"Have you tried my other games?",
	"Broken PvP is my first game!",
	"Go ahead, give it a try!"
}

-- Delay in seconds between each message
local messageDelay = 2

-- Delay in seconds before repeating the messages
local repeatDelay = 10

-- Function to make NPC say messages in sequence
local function sayMessages()
	for _, message in ipairs(messages) do
		ChatService:Chat(npc.Head, message)
		wait(messageDelay)
	end
	wait(repeatDelay)
	sayMessages() -- Repeat after the repeat delay
end

-- Start saying messages
sayMessages()
