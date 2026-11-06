-- StarterPlayer/StarterPlayerScripts/NotifScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local updateGUIEvent = ReplicatedStorage:WaitForChild("UpdateGUIEvent")
local hideGUIEvent = ReplicatedStorage:WaitForChild("HideGUIEvent")
local killEvent = ReplicatedStorage:WaitForChild("KillEvent")
local killEventXP = ReplicatedStorage:WaitForChild("KillEventXP")
local updateStatus = ReplicatedStorage:WaitForChild("UpdateStatus")
local hideStatus = ReplicatedStorage:WaitForChild("HideStatus")
local mapChanged = ReplicatedStorage:WaitForChild("MapChanged")
local musicChanged = ReplicatedStorage:WaitForChild("MusicChanged")
local updateTime = ReplicatedStorage:WaitForChild("UpdateTime")
local changeMode = ReplicatedStorage:WaitForChild("ChangeMode")
local xpEvent = ReplicatedStorage:WaitForChild("XPEvent")
local showShop = ReplicatedStorage:WaitForChild("ShowShop")

local player = Players.LocalPlayer
local sound = game.Workspace.Alarm

-- Weapon image IDs
local weaponImages = {
	GrenadeLauncher = 18187639194,
	Railgun = 18187664818,
	SMG = 18187667014,
	AssaultRifle = 18187669179,
	Shotgun = 18187660933,
	SniperRifle = 18187671971,
	Arrow = 13364570588,
}

-- Kill Feed Notifs
killEvent.OnClientEvent:Connect(function(killer,weapon,target)
	local player = Players.LocalPlayer
	if player and player.PlayerGui then
		local gui = player.PlayerGui:WaitForChild("KillFeedGui")
		if gui then
			gui.Enabled = true
			local killFeedFrame = gui:WaitForChild("KillFeedFrame")
			local killFeedTemplate = killFeedFrame:WaitForChild("KillFeedTemplate")
			
			-- Function to create a new killfeed entry
			local function createKillFeedEntry(killerName, weaponType, diedName)
				-- Adjust all current entries downwards
				for _, entry in ipairs(killFeedFrame:GetChildren()) do
					if entry:IsA("Frame") and entry.Visible then
						local newPos = entry.Position + UDim2.new(0, 0, 0.1, 0)
						local moveDownTween = TweenService:Create(entry, TweenInfo.new(0.5), {Position = newPos})
						moveDownTween:Play()
					end
				end

				-- Create the new entry
				local newEntry = killFeedTemplate:Clone()
				newEntry.Visible = true
				newEntry.Parent = killFeedFrame

				newEntry:FindFirstChild("KillerUsername").Text = killerName
				newEntry:FindFirstChild("WeaponImage").Image = "rbxassetid://" .. weaponImages[weaponType]
				newEntry:FindFirstChild("DiedUsername").Text = diedName

				-- Animate the entry sliding in from the left
				newEntry.Position = UDim2.new(-1, 0, 0, 0)
				local slideInTween = TweenService:Create(newEntry, TweenInfo.new(0.5), {Position = UDim2.new(0, 0, 0, 0)})
				slideInTween:Play()

				-- Wait 2 seconds before fading out
				wait(2)

				-- Animate the entry fading out
				local fadeOutTween = TweenService:Create(newEntry, TweenInfo.new(0.5), {BackgroundTransparency = 1})
				for _, label in ipairs(newEntry:GetChildren()) do
					if label:IsA("TextLabel") then
						TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
					elseif label:IsA("ImageLabel") then
						TweenService:Create(label, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
					end
				end
				fadeOutTween:Play()
				fadeOutTween.Completed:Connect(function()
					newEntry:Destroy()
				end)
			end
			-- create killfeed notif
			createKillFeedEntry(killer,weapon,target)
			-- Fire the killEventXP only for the player who made the kill
			if player.Name == killer then
				killEventXP:FireServer(killer, target)
			end
		end
	end
end)

updateGUIEvent.OnClientEvent:Connect(function(message)
	local player = Players.LocalPlayer
	if player and player.PlayerGui then
		local gui = player.PlayerGui:WaitForChild("NotifGui")
		if gui then
			gui.Enabled = true
			local notifFrame = gui:WaitForChild("Frame")
			if notifFrame then
				notifFrame.Visible = true
				notifFrame.WarningText.TextTransparency = 0
				notifFrame.WarningType.TextTransparency = 0
				local warningType = notifFrame:WaitForChild("WarningType")
				if warningType then
					warningType.Text = message
				end
				-- Play sound
				if Players.LocalPlayer.PlayerGui then
					sound:Play()
				end
			end
			wait(2)
			-- Fade out the NotifGui
			local tweenInfo = TweenInfo.new(3,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,false,0)
			local tween = TweenService:Create(notifFrame, tweenInfo, {Transparency = 1})
			tween:Play()
			tween.Completed:Connect(function()
				notifFrame.Visible = false
				gui.Enabled = false
				-- Stop sound
				sound:Stop()
			end)
		end
	end
end)

hideGUIEvent.OnClientEvent:Connect(function()
	
end)

showShop.OnClientEvent:Connect(function()
	local player = Players.LocalPlayer
	if player and player.PlayerGui then
		local shopgui = player:WaitForChild("PlayerGui"):WaitForChild("ShopGui")
		local shopbutton = shopgui:WaitForChild("shopButton")
		shopgui.Frame.Visible = true
		shopbutton.Visible = false
		shopgui.Frame.close.MouseButton1Click:Connect(function()
			shopgui.Frame.Visible = false
			return
		end)
	end
end)

xpEvent.OnClientEvent:Connect(function(xpadded)
	local player = Players.LocalPlayer
	if player and player.PlayerGui then
		local gui = player.PlayerGui:WaitForChild("NotifGui")
		if gui then
			gui.Enabled = true
			local notifFrame = gui:WaitForChild("XPFrame")
			local tweenInfo = TweenInfo.new(2,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,false,0)
			if notifFrame then
				notifFrame.Visible = true
				local xpNotif = notifFrame:WaitForChild("TextLabel")
				if xpNotif then
					xpNotif.TextTransparency = 1
					xpNotif.Text = xpadded
					TweenService:Create(xpNotif, tweenInfo, {TextTransparency = 0}):Play()
				end
			end
			wait(1)
			-- Fade out the NotifGui
			local tween = TweenService:Create(notifFrame, tweenInfo, {Transparency = 1})
			tween:Play()
			tween.Completed:Connect(function()
				notifFrame.Visible = false
			end)
		end
	end
end)

updateTime.OnClientEvent:Connect(function()
	local player = Players.LocalPlayer
	if player and player.PlayerGui then
		local gui = player.PlayerGui:WaitForChild("AlwaysOn")
		if gui then
			local formattedTime = string.format("%02d:%02d", math.floor(workspace.TimeRemains.Value / 60), math.floor(workspace.TimeRemains.Value % 60))
			gui.TimeFrame.Time.Text = formattedTime
		end
	end
end)

changeMode.OnClientEvent:Connect(function(mode)
	local player = Players.LocalPlayer
	if player and player.PlayerGui then
		local gui = player.PlayerGui:WaitForChild("AlwaysOn")
		if gui then
			gui.TimeFrame.Mode.Text = mode
		end
	end
end)

updateStatus.OnClientEvent:Connect(function(status)
	local player = Players.LocalPlayer
	if player and player.PlayerGui then
		local gui = player.PlayerGui:WaitForChild("AlwaysOn")
		if gui then
			gui.StatusFrame.Visible = true
			gui.StatusFrame.StatusText.Text = status
			gui.StatusFrame.StatusText.Visible = true
			-- Animations
			local currentXScale, currentXOffset = gui.StatusFrame.StatusText.Position.X.Scale, gui.StatusFrame.StatusText.Position.X.Offset
			local fadeInTween = TweenService:Create(gui.StatusFrame.StatusText, TweenInfo.new(0.5), {TextTransparency = 0})
			local slideUpTween = TweenService:Create(gui.StatusFrame.StatusText, TweenInfo.new(0.5), {Position = UDim2.new(currentXScale, currentXOffset, 0.4, 0)})
			fadeInTween:Play()
			slideUpTween:Play()
		end
	end
end)

hideStatus.OnClientEvent:Connect(function()
	local player = Players.LocalPlayer
	if player and player.PlayerGui then
		local gui = player.PlayerGui:WaitForChild("AlwaysOn")
		if gui then
			-- Animations
			local currentXScale, currentXOffset = gui.StatusFrame.StatusText.Position.X.Scale, gui.StatusFrame.StatusText.Position.X.Offset
			local fadeOutTween = TweenService:Create(gui.StatusFrame.StatusText, TweenInfo.new(0.5), {TextTransparency = 1})
			local slideDownTween = TweenService:Create(gui.StatusFrame.StatusText, TweenInfo.new(0.5), {Position = UDim2.new(currentXScale, currentXOffset, 1, 0)})
			fadeOutTween:Play()
			slideDownTween:Play()
			fadeOutTween.Completed:Connect(function()
				gui.StatusFrame.StatusText.Visible = false
				gui.StatusFrame.Visible = false
			end)
		end
	end
end)

-- mapChanged() >> showMapCredits()
function showMapCredits(mapName, mapCreator)
	local gui = player.PlayerGui:WaitForChild("Credits")
	gui.InGameCredits.Visible = true
	local mapframe = gui.InGameCredits.MapCredits
	mapframe.Visible = true
	mapframe.MapName.Text = mapName
	mapframe.Creator.Text = mapCreator
end
mapChanged.OnClientEvent:Connect(function(mapName, mapCreator)
	showMapCredits(mapName, mapCreator)
end)

-- musicChanged() >> showMusicCredits()
local function showMusicCredits(musicName, musicCreator)
	local gui = player.PlayerGui:WaitForChild("Credits")
	gui.InGameCredits.Visible = true
	local musicframe = gui.InGameCredits.MusicCredits
	musicframe.Visible = true
	musicframe.MusicName.Text = musicName
	musicframe.Creator.Text = musicCreator
end
musicChanged.OnClientEvent:Connect(function(musicName,musicCreator)
	showMusicCredits(musicName, musicCreator)
end)

player.CharacterAdded:Connect(function()
	showMapCredits(workspace.MapNameNow.Value, workspace.MapCreatorNow.Value)
	showMusicCredits(workspace.MusicNameNow.Value, workspace.MusicCreatorNow.Value)
end)