-- StarterGui/LoadingScreenGui/LoadingScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local player = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local GuiService = game:GetService("GuiService")
-- UI Elements
local loadingScreenGui = script.Parent
local loadingScreenFrame = loadingScreenGui:WaitForChild("Frame")
local loadingMessage = loadingScreenFrame:WaitForChild("LoadingMessage")

-- List of assets to preload
local assetsToLoad = {
	game:WaitForChild("Workspace"),
	ReplicatedStorage:WaitForChild("Agents"),
	ReplicatedStorage:WaitForChild("Events"),
	ReplicatedStorage.Maps:WaitForChild("CityMap00"),
	ReplicatedStorage.Maps:WaitForChild("CityMap01"),
	ReplicatedStorage.Maps:WaitForChild("CityMap02"),
	ReplicatedStorage.Maps:WaitForChild("TestMap00"),
	ReplicatedStorage.Maps:WaitForChild("WarMap00"),
	ReplicatedStorage.Maps:WaitForChild("WarMap01"),
	ReplicatedStorage:WaitForChild("Assistant"),
	player:WaitForChild("PlayerGui"),
	ReplicatedStorage:WaitForChild("Items"),
	ReplicatedStorage:WaitForChild("WeaponsSystem"),
}

-- Function to preload assets
local function preloadAssets(assets)
	local totalAssets = #assets
	local loadedAssets = 0
	for _, asset in ipairs(assets) do
		ContentProvider:PreloadAsync({asset})
		loadedAssets = loadedAssets + 1
		-- Update loading message
		loadingMessage.Text = "Loading... " .. math.floor((loadedAssets / totalAssets) * 100) .. "%"
	end
end

-- Show the loading screen
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
script.Parent.Parent.CustomHealthGui.Enabled = false
script.Parent.Parent.AlwaysOn.Enabled = false
script.Parent.Parent.NotifGui.Enabled = false
loadingScreenFrame.Visible = true
loadingMessage.Text = "Loading... 0%"

-- Preload assets
preloadAssets(assetsToLoad)

-- Hide the loading screen once everything is loaded
wait(0.5)
loadingScreenFrame.Visible = false
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
game.ReplicatedStorage.Events.MenuCutscene:FireServer(player)