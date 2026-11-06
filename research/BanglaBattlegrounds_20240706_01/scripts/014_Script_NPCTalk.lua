-- Workspace/Dummies/Mulla Bhai/NPCTalk
local npc = script.Parent -- Assuming this script is placed inside the NPC model or part

local ChatService = game:GetService("Chat")

-- Messages to be said
local messages = {
	"আসসালামু আলাইকুম!",
	"ওই ঘরের ভিতর একটা জিন আছে!",
	"বাড়ির কাছে যেও না!"
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
