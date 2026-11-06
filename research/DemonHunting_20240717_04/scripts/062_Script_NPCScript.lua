-- Workspace/NPCs/Sieg/NPCScript
-- NPCScript: Sieg
local model = script.Parent
local part = model:FindFirstChild("PromptPart")

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
				dialog.Speech.Text = "Uh... hi"
				choices.Choice1.Visible = true
				choices.Choice1.Text = "Who are you?"
				choices.Choice2.Visible = true
				choices.Choice2.Text = "Why do you have wings?"
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
					dialog.Speech.Text = "Ah, hi. I am <font color='#01ee9f'>Siegfried Evan Voltaire</font>. You can call me Sieg. Not that it really matters. <br />*sigh* <br />I assume you're one of the new recruits? Better <font color='#ffff00'>get prepared</font> for a harsh reality check, my friend."
					print("Sieg choice 1")
				end))
				table.insert(playerConnections[player], choices.Choice2.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "Ha... Looks like my partner <font color='#01ee9f'>Drakas</font> is becoming more and more lazy. I'm gonna go pull a prank very soon to get him back to his... 'usual' sense of duty. <br />Anyways... during our recent invasion by the <font color='#ffff00'>Jinnic demons</font>, some of us have been afflicted by <font color='#ffff00'>a virus</font>. We are not sure what it is, and how it may affect us. <br />But so far, we have visible symptoms like <font color='#ffff00'>having wings and such</font>. <br />Makes us look like those freaks, sadly."
				end))
				table.insert(playerConnections[player], choices.Choice3.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "Well... nobody really knows their task until they find one. <font color='#ffff00'>Talk to the other people</font> around the courtyard. <br />Maybe they would be able to point out anything they'd need help with. And they'd <font color='#ffff00'>reward you</font> handsomely, too. <br />I don't know who you are, my friend, but atleast you are more curious than the rest of the bunch. Stay safe."
				end))
				table.insert(playerConnections[player], choices.Choice4.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "'Kay then, random friend. I'll be seeing you later."
					wait(2)
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
