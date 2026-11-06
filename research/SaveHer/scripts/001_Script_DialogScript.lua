-- ServerScriptService/DialogScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local messages = {
	"Uhm- hi there...",
	"It's really lonely in here...",
	"Do you think we'll ever get out?",
	"I wish I had more friends...",
	"Thank you for being here with me.",
	"I'm scared...",
	"Sometimes I hear strange noises...",
	"Uhm- are you okay?",
	"I miss my family...",
	"Do you know any good stories?",
	"I don't like being alone...",
	"Can we play a game?",
	"Why is it so dark in here?",
	"I wish I could see the sky again...",
	"What's your favorite color?",
	"Do you think anyone will find us?",
	"Uhm- I'm not very good at talking...",
	"I like to make things too...",
	"Do you have any hobbies?",
	"I feel so tired...",
	"Can you tell me a joke?",
	"I'm really hungry...",
	"I hope I don't get sick...",
	"Do you think it's safe here?",
	"I used to go to school...",
	"I wonder what time it is...",
	"Do you think there's a way out?",
	"I wish I could remember more...",
	"Uhm- can you stay with me?",
	"I don't want to be alone...",
	"Sometimes I dream of home...",
	"It's cold in here...",
	"Do you think there's anyone else?",
	"I hope we can leave soon...",
	"I don't like the dark...",
	"Uhm- are you afraid?",
	"Can you tell me about your family?",
	"I used to have a pet...",
	"I miss playing outside...",
	"Do you think it's daytime?",
	"I heard something again...",
	"Uhm- do you think we'll be okay?",
	"I want to go home...",
	"Why are we here?",
	"I don't understand...",
	"Can we sing a song?",
	"I feel so weak...",
	"Do you think it's safe to sleep?",
	"I hope tomorrow is better..."
}

local specialMessages = {
	"Please don't leave me alone...",
	"I will die if you go away...",
	"No- please stay! I'm scared...",
	"Don't leave me... I need you...",
	"I'm so afraid... don't go...",
	"If you leave, I'll be all alone...",
	"Please... I can't survive without you...",
	"Stay with me... I beg you...",
	"No- don't go... I'll die...",
	"I'm too scared to be alone..."
}

local pingSound = ReplicatedStorage:WaitForChild("Ping")
local screamSound = ReplicatedStorage:WaitForChild("Scream")

-- Keep track of messages shown to each player
local shownRegularMessages = {}
local shownSpecialMessages = {}

-- Function to simulate typing effect
local function typeWriterEffect(textLabel, text, typingSpeed)
	-- Create a clone of the ping sound
	local sound = pingSound:Clone()
	sound.Parent = textLabel

	-- Randomize pitch for natural effect
	local function adjustPitch()
		sound.Pitch = 1 + math.random(-0.2, 0.2)
	end

	-- Typing effect
	for i = 1, #text do
		textLabel.Text = text:sub(1, i)
		adjustPitch()
		sound:Play()
		wait(typingSpeed)
	end

	-- Stop the sound
	sound:Stop()
	sound:Destroy()

	wait(1)  -- Wait a bit before starting the erase effect

	-- Erase effect
	for i = #text, 1, -1 do
		textLabel.Text = text:sub(1, i - 1)
		wait(typingSpeed)
	end
end

-- Function to update message
local function updateMessage(player, message)
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local dialogGui = playerGui:FindFirstChild("DialogGui")
		if dialogGui then
			local frame = dialogGui:FindFirstChild("Frame")
			if frame then
				local textLabel = frame:FindFirstChild("TextLabel")
				if textLabel then
					typeWriterEffect(textLabel, message, 0.05)
				end
			end
		end
	end
end

-- Function to randomly wait between 5 to 20 seconds
local function randomWait()
	return math.random(5, 20)
end

-- Function to add echo effect to a sound
local function addEchoEffect(sound)
	local reverb = Instance.new("ReverbSoundEffect")
	reverb.DecayTime = 2.0
	reverb.DryLevel = -15
	reverb.WetLevel = 0
	reverb.Parent = sound
end

-- Function to handle showing special messages
local function showSpecialMessage(player)
	local unusedSpecialMessages = {}
	for _, msg in ipairs(specialMessages) do
		if not shownSpecialMessages[player.UserId] or not shownSpecialMessages[player.UserId][msg] then
			table.insert(unusedSpecialMessages, msg)
		end
	end

	if #unusedSpecialMessages > 0 then
		local randomIndex = math.random(1, #unusedSpecialMessages)
		local specialMessage = unusedSpecialMessages[randomIndex]
		updateMessage(player, specialMessage)

		-- Track shown special messages
		if not shownSpecialMessages[player.UserId] then
			shownSpecialMessages[player.UserId] = {}
		end
		shownSpecialMessages[player.UserId][specialMessage] = true

		-- Reset regular message timer for this player
		shownRegularMessages[player.UserId] = nil
	end
end

-- Main loop
while true do
	wait(randomWait())
	for _, player in ipairs(Players:GetPlayers()) do
		if not shownRegularMessages[player.UserId] then
			local randomMessage = messages[math.random(1, #messages)]
			updateMessage(player, randomMessage)

			-- Track shown regular messages
			if not shownRegularMessages[player.UserId] then
				shownRegularMessages[player.UserId] = {}
			end
			shownRegularMessages[player.UserId][randomMessage] = true
		end
	end

	-- Show a special message every 30 seconds
	if os.time() % 30 == 0 then
		for _, player in ipairs(Players:GetPlayers()) do
			showSpecialMessage(player)
		end
	end
end

-- Connect to MenuOpened event
GuiService.MenuOpened:Connect(function(player)
	showSpecialMessage(player)
end)
