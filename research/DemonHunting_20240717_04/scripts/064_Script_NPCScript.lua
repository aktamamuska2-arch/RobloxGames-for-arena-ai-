-- Workspace/NPCs/DewanMukto/NPCScript
-- NPCScript: DewanMukto
local model = script.Parent
local part = model:FindFirstChild("HumanoidRootPart")

if part then
	local attachment = part:FindFirstChildWhichIsA("Attachment")
	if attachment then
		local proximityPrompt = attachment:FindFirstChild("ProximityPrompt")
		if proximityPrompt then
			local playerConnections = {}

			proximityPrompt.Triggered:Connect(function(player)
				-- NPC Dialog screen GUI
				local dialog = player.PlayerGui.DialogGui.Dialog
				local choices = dialog.Choices
				dialog.Speech.Text = "'Ello! Thanks for playing my game!"
				choices.Choice1.Visible = true
				choices.Choice1.Text = "Who are you?"
				choices.Choice2.Visible = true
				choices.Choice2.Text = "Where are your wings?"
				choices.Choice3.Visible = true
				choices.Choice3.Text = "What are my tasks?"
				choices.Choice4.Visible = true
				choices.Choice4.Text = "Goodbye"
				dialog.Visible = true

				-- Disconnect previous connections if they exist
				if playerConnections[player] then
					for _, connection in ipairs(playerConnections[player]) do
						connection:Disconnect()
					end
				end

				playerConnections[player] = {}

				-- Actions
				table.insert(playerConnections[player], choices.Choice1.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "Good day to you, " .. "<font color='#01ee9f'>" .. player.Name .. "</font>! I'm the developer of this game. I hope you're excited about the final release. <br />The current version is  <font color='#ffff00'>" .. player.PlayerGui.MainGui.VersionInfo.TextLabel.Text ..  "</font><br /> Currently there aren't many things to do in this game, but <font color='#ffff00'>stay tuned</font> until the beta launch!"
				end))
				table.insert(playerConnections[player], choices.Choice2.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "Oh, you gotta be kidding me! Haha. <br />I'm not even part of this game! Only you can <font color='#ffff00'>see me</font>; the NPCs cannot. I hope you've spoken to <font color='#01ee9f'>Drakas</font>, <font color='#01ee9f'>Sieg</font>, and <font color='#01ee9f'>Konrad</font> already. They look forward to seeing how well you perform (when the quest system comes out!)"
				end))
				table.insert(playerConnections[player], choices.Choice3.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "Tasks? I don't know. See those <font color='#ffff00'>dummies behind me</font>? Maybe buy some <font color='#ffff00'>weapons</font> from the <font color='#ffff00'>shop</font> and start practicing a bit. <br /><br /><font color='#ff0000'>The quest system has not been implemented yet. Please wait until then!</font>"
				end))
				table.insert(playerConnections[player], choices.Choice4.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "Okay, dear player. Maybe we'll meet again, maybe not. <br />But I surely <font color='#ffff00'>am glad to have met ya</font>!"
					wait(3)
					choices.Choice1.Visible = false
					choices.Choice2.Visible = false
					choices.Choice3.Visible = false
					choices.Choice4.Visible = false
					dialog.Visible = false

					-- Disconnect all connections after closing the dialog
					if playerConnections[player] then
						for _, connection in ipairs(playerConnections[player]) do
							connection:Disconnect()
						end
						playerConnections[player] = nil
					end
				end))
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
