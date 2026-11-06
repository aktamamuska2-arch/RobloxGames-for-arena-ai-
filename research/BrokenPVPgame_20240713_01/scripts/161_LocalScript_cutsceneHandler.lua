-- StarterPlayer/StarterPlayerScripts/cutsceneHandler
-- LocalScript placed in StarterPlayerScripts
local replicatedStorage = game:GetService("ReplicatedStorage")
local spawnPlayer = replicatedStorage:WaitForChild("SpawnPlayer")
local Workspace = game:GetService("Workspace")
local ts = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local camera = game.Workspace.CurrentCamera
local players = game:GetService("Players")
local player = players.LocalPlayer
local playerModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule"))
local controls = playerModule:GetControls()

local camFolder = game.Workspace:WaitForChild("introcameras")
local cam1 = camFolder:WaitForChild("cam1")
local cam2 = camFolder:WaitForChild("cam2")

camera.CFrame = cam1.CFrame

-- References to GUI elements
local gui = player.PlayerGui.CutsceneUI
local creditsgui = player.PlayerGui.Credits
local notifgui = player.PlayerGui.NotifGui
local shopgui = player.PlayerGui.ShopGui
local alwaysongui = player.PlayerGui.AlwaysOn
local blackFrame = gui:WaitForChild("blackFrame")
local playbutton = gui:WaitForChild("playButton")
local customHealthBar = player:WaitForChild("PlayerGui"):WaitForChild("CustomHealthBar")
local creditsbutton = creditsgui:WaitForChild("creditsButton")
local shopbutton = shopgui:WaitForChild("shopButton")

blackFrame.Visible = true -- start the game with a black screen


local function disablePlayerControls() -- Function to disable player controls
	controls:Disable()
end
local function enablePlayerControls() -- Function to enable player controls
	controls:Enable()
end

-- Initially disable player controls, inventory, and health bar
camera.CameraType = Enum.CameraType.Scriptable
customHealthBar.Enabled = false
creditsgui.Enabled = false

-- In case game gets stuck in gun equipped mode for PC:
function startAlready()
	spawnPlayer:FireServer()
	playbutton.Visible = false
	creditsbutton.Visible = false
	camera.CameraType = Enum.CameraType.Custom
	enablePlayerControls()  -- Enable player controls when button is clicked
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)  -- Enable inventory
	customHealthBar.Enabled = true  -- Enable custom health bar script
	creditsgui.InGameCredits.Visible = true -- Enable in-game credits panel
	alwaysongui.Enabled = true
	notifgui.Enabled = true
	showMusicCredits(Workspace.MusicNameNow.Value, Workspace.MusicCreatorNow.Value)
	showMapCredits(Workspace.MapNameNow.Value,Workspace.MapCreatorNow.Value)
	return
end

-- Button click functions
playbutton.MouseButton1Click:Connect(function()
	startAlready()
end)
creditsbutton.MouseButton1Click:Connect(function()
	creditsgui.GameCredits.Visible = true
	creditsbutton.Visible = false
	playbutton.Visible = false
	shopbutton.Visible = false
	return
end)
creditsgui.GameCredits.close.MouseButton1Click:Connect(function()
	creditsgui.GameCredits.Visible = false
	creditsbutton.Visible = true
	playbutton.Visible = true
	shopbutton.Visible = true
	return
end)
shopbutton.MouseButton1Click:Connect(function()
	shopgui.Frame.Visible = true
	creditsbutton.Visible = false
	playbutton.Visible = false
	shopbutton.Visible = false
	return
end)
shopgui.Frame.close.MouseButton1Click:Connect(function()
	shopgui.Frame.Visible = false
	creditsbutton.Visible = true
	playbutton.Visible = true
	shopbutton.Visible = true
	return
end)

local ti = TweenInfo.new(
	3,
	Enum.EasingStyle.Cubic,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

function showStartMenu()
	creditsgui.InGameCredits.Visible = false
	task.wait(2) -- animate the screen fading in from black
	ts:Create(blackFrame, ti, {BackgroundTransparency = 1}):Play()
	ts:Create(camera, ti, {CFrame = cam2.CFrame}):Play()
	task.wait(2) -- wait before showing the buttons
	playbutton.Visible = true
	playbutton.Transparency = 1
	creditsgui.Enabled = true
	creditsbutton.Visible = true
	creditsbutton.Transparency = 1
	shopbutton.Visible = true
	shopbutton.Transparency = 1
	-- Animate the button text fading in
	ts:Create(playbutton, ti, {Transparency = 0}):Play()
	ts:Create(creditsbutton, ti, {Transparency = 0}):Play()
	ts:Create(shopbutton, ti, {Transparency = 0}):Play()
end

-- Show the in-game credits for players just joining the session
function showMusicCredits(musicName, musicCreator)
	local gui = player.PlayerGui:WaitForChild("Credits")
	local musicframe = gui.InGameCredits.MusicCredits
	if musicframe.Visible == false then
		musicframe.Visible = true
	end
	musicframe.MusicName.Text = musicName
	musicframe.Creator.Text = musicCreator
end
function showMapCredits(mapName, mapCreator)
	local gui = player.PlayerGui:WaitForChild("Credits")
	local mapframe = gui.InGameCredits.MapCredits
	if mapframe.Visible == false then
		mapframe.Visible = true
	end
	mapframe.MapName.Text = mapName
	mapframe.Creator.Text = mapCreator
end

game.ReplicatedStorage.Events.MenuCutscene.OnClientEvent:Connect(showStartMenu)