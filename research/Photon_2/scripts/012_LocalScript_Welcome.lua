-- StarterPlayer/StarterPlayerScripts/Welcome
-- Define constants
local SCREENGUI_NAME = "ScreenGui"
local FRAME_NAME = "Frame"
local GREETINGS_NAME = "Greetings"
local WELCOME_TEXT = "Welcome to Photon"
local TYPING_SPEED = 0.05  -- Adjust typing speed as needed
local FADE_DURATION = 2  -- Duration for fade in and fade out (seconds)

-- Get necessary services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Locate the ScreenGui and its components
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild(SCREENGUI_NAME)
local frame = screenGui:WaitForChild(FRAME_NAME)
local greetingsLabel = frame:WaitForChild(GREETINGS_NAME)

-- Function to simulate typing effect
local function typeWriterEffect(textLabel, text, typingSpeed)
	for i = 1, #text do
		textLabel.Text = text:sub(1, i)
		wait(typingSpeed)
	end
	wait(1)  -- Wait a bit before starting the erase effect
	for i = #text, 1, -1 do
		textLabel.Text = text:sub(1, i - 1)
		wait(typingSpeed)
	end
end

-- Function to fade in and out the frame
local function fadeFrameInOut(frame, fadeInDuration, fadeOutDuration)
	-- Fade in
	local tweenInfoFadeIn = TweenInfo.new(fadeInDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In)
	local fadeIn = {
		BackgroundTransparency = 1
	}
	local tweenFadeIn = TweenService:Create(frame, tweenInfoFadeIn, fadeIn)

	-- Fade out
	local tweenInfoFadeOut = TweenInfo.new(fadeOutDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
	local fadeOut = {
		BackgroundTransparency = 1
	}
	local tweenFadeOut = TweenService:Create(frame, tweenInfoFadeOut, fadeOut)

	-- Play tweens
	tweenFadeIn:Play()
	wait(fadeInDuration)
	tweenFadeOut:Play()
end

-- Show greetings on player joined
local function showGreetings()
	if greetingsLabel and greetingsLabel:IsA("TextLabel") then
		greetingsLabel.Text = ""
		fadeFrameInOut(frame, FADE_DURATION, FADE_DURATION)
		typeWriterEffect(greetingsLabel, WELCOME_TEXT, TYPING_SPEED)
		fadeFrameInOut(frame, FADE_DURATION, FADE_DURATION)
		typeWriterEffect(greetingsLabel, "Explore or escape", TYPING_SPEED)
	end
end

-- Run showGreetings when player joins
showGreetings()
