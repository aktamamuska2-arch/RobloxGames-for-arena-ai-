-- Workspace/NPCs/Drakas/NPCScript
-- NPCScript: Drakas
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
				dialog.Speech.Text = "Greetings fellow demon hunter!"
				choices.Choice1.Visible = true
				choices.Choice1.Text = "Where am I?"
				choices.Choice2.Visible = true
				choices.Choice2.Text = "What am I doing here?"
				choices.Choice3.Visible = true
				choices.Choice3.Text = "What to do next?"
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
					dialog.Speech.Text = "Welcome to the southern reaches of <font color='#f1f100'>Gondelin</font>!"
					print("Drakas choice 1")
				end))
				table.insert(playerConnections[player], choices.Choice2.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "It seems like you've been chosen as a <font color='#f1f100'>demon hunter</font>.<br />Your task is to <font color='#f1f100'>defend our kingdom</font> against any and all kinds of harmful entities."
				end))
				table.insert(playerConnections[player], choices.Choice3.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "You may speak with my friend <font color='#01ee9f'>Sieg</font> out in the courtyard. He will teach you the basics."
				end))
				table.insert(playerConnections[player], choices.Choice4.MouseButton1Click:Connect(function()
					dialog.Speech.Text = "Until next time!"
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
