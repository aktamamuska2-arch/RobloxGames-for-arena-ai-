-- Workspace/ExteriorArea01/Campfire/TrashPromptScript
local model = script.Parent
local part = model:FindFirstChild("PromptPart")

if part then
	local attachment = part:FindFirstChildWhichIsA("Attachment")
	if attachment then
		local proximityPrompt = attachment:FindFirstChild("ProximityPrompt")
		if proximityPrompt then
			proximityPrompt.Enabled = false  -- Initially disable the prompt

			local function updateProximityPrompt(player)
				local character = player.Character
				if character then
					local tool = character:FindFirstChildOfClass("Tool")
					if tool and tool.Name ~= "Martial" and tool.Name ~= "Wallet" then
						proximityPrompt.Enabled = true
					else
						proximityPrompt.Enabled = false
					end
				else
					proximityPrompt.Enabled = false
				end
			end

			game.Players.PlayerAdded:Connect(function(player)
				player.CharacterAdded:Connect(function(character)
					character.ChildAdded:Connect(function(child)
						if child:IsA("Tool") then
							updateProximityPrompt(player)
						end
					end)

					character.ChildRemoved:Connect(function(child)
						if child:IsA("Tool") then
							updateProximityPrompt(player)
						end
					end)

					-- Initial check when the character is added
					updateProximityPrompt(player)
				end)

				-- Initial check when the player is added
				updateProximityPrompt(player)
			end)

			proximityPrompt.Triggered:Connect(function(player)
				-- Check if the player has a character and a humanoid
				local character = player.Character
				if character then
					-- Find the equipped tool in the character
					local tool = character:FindFirstChildOfClass("Tool")
					if tool and tool.Name ~= "Martial" and tool.Name ~= "Wallet" then
						-- Remove the tool from the character
						tool.Parent = nil
						-- Destroy the tool
						tool:Destroy()
						print(player.Name .. " had their equipped tool removed and destroyed.")
					else
						print(player.Name .. " does not have an appropriate tool equipped.")
					end
				else
					print(player.Name .. " does not have a character.")
				end
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
