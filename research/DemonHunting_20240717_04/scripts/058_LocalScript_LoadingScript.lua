-- StarterGui/LoadingScreenGui/LoadingScript
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameSpace = game:GetService("Workspace")
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
	player:WaitForChild("PlayerGui"),
	ReplicatedStorage:WaitForChild("Animations"),
	ReplicatedStorage:WaitForChild("Events"),
	ReplicatedStorage:WaitForChild("Models"),
	ReplicatedStorage:WaitForChild("Sounds"),
	ReplicatedStorage:WaitForChild("VFX"),
	ReplicatedStorage:WaitForChild("Weapons"),
	ReplicatedStorage:WaitForChild("Tools"),
	GameSpace:WaitForChild("Buildings"),
	GameSpace:WaitForChild("Dummies"), -- Dummies (may have to remove later)
	GameSpace:WaitForChild("SpawnLocation"),
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
player.PlayerGui.StatsGui.LevelFrame.Visible = false
player.PlayerGui.StatsGui.StatsFrame.Visible = false
loadingScreenFrame.Visible = true
loadingMessage.Text = "Loading... 0%"

-- Preload assets
preloadAssets(assetsToLoad)

-- Hide the loading screen once everything is loaded
wait(0.5)
loadingScreenFrame.Visible = false
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, true)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, true)
player.PlayerGui.StatsGui.LevelFrame.Visible = true
player.PlayerGui.StatsGui.StatsFrame.Visible = true