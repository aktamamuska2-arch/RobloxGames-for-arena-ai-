-- Workspace/NPCs/Konrad/NPCScript
-- NPCScript: Konrad
local model = script.Parent
local part = model:FindFirstChild("PromptPart")

local function dialogScript(player, playerConnections)
	-- NPC Dialog screen GUI
	local dialog = player.PlayerGui.DialogGui.Dialog
	local choices = dialog.Choices
	dialog.Speech.Text = "Heyyy buddy! Beautiful day today, eh?"
	choices.Choice1.Visible = true
	choices.Choice1.Text = "Who are you?"
	choices.Choice2.Visible = true
	choices.Choice2.Text = "Don't you have wings?"
	choices.Choice3.Visible = true
	choices.Choice3.Text = "What are my tasks?"
	choices.Choice4.Visible = true
	choices.Choice4.Text = "Goodbye"
	dialog.Visible = true
	
	local function connClean()
		-- Disconnect all connections after closing the dialog
		if playerConnections[player] then
			for _, connection in ipairs(playerConnections[player]) do
				connection:Disconnect()
			end
			playerConnections[player] = nil
		end
	end

	-- Disconnect previous connections if they exist
	if playerConnections[player] then
		for _, connection in ipairs(playerConnections[player]) do
			connection:Disconnect()
		end
	end

	playerConnections[player] = {}

	-- Dialogs
	table.insert(playerConnections[player], choices.Choice1.MouseButton1Click:Connect(function()
		dialog.Speech.Text = "My name's <font color='#00ff00'>Konrad Mickey</font>. <br />I'm just <font color='#ffff00'>a trainer</font> working for the kingdom... definitely not one of these cool demon hunters! Heheh."
	end))
	table.insert(playerConnections[player], choices.Choice2.MouseButton1Click:Connect(function()
		dialog.Speech.Text = "Wings? What do you mean? <br />Holy flowers of Heaven, you're right! A bit strange, ain't it? <br />Perhaps I'm <font color='#ffff00'>immune to the disease</font> brought on by the demons. Heheh."
	end))
	table.insert(playerConnections[player], choices.Choice3.MouseButton1Click:Connect(function()
		dialog.Speech.Text = "Glad you've asked! Since you're a new recruit for our <font color='#ffff00'>demon hunting regiment</font>, we need to make sure you really are 'worthy'. <br />Otherwise, we'd just have to demote you back to <font color='#ffff00'>civilian status</font>. Heheh. <br /><br /><font color='#ff0000'>My hands are empty at the moment, so come back later when I will have something to do for ya.</font>"
	end))
	table.insert(playerConnections[player], choices.Choice4.MouseButton1Click:Connect(function()
		dialog.Speech.Text = "Alright, pookie, see ya later then!"
		wait(2)
		choices.Choice1.Visible = false
		choices.Choice2.Visible = false
		choices.Choice3.Visible = false
		choices.Choice4.Visible = false
		dialog.Visible = false
		connClean()
	end))
end

if part then
	local attachment = part:FindFirstChildWhichIsA("Attachment")
	if attachment then
		local proximityPrompt = attachment:FindFirstChild("ProximityPrompt")
		if proximityPrompt then
			local playerConnections = {}
			proximityPrompt.Triggered:Connect(function(player)
				dialogScript(player, playerConnections)
			end)
		else
			warn("No ProximityPrompt found in attachment!")
		end
	else
		warn("No Attachment found in part!")
	end
else
	warn("No Part found in model!")
end
