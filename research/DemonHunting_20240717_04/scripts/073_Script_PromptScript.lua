-- Workspace/ExteriorArea01/Weapon Store/PromptScript
local model = script.Parent
local part = model:FindFirstChildWhichIsA("Part")
local shopMenu = model.ShopMenu

if part then
	local attachment = part:FindFirstChildWhichIsA("Attachment")
	if attachment then
		local proximityPrompt = attachment:FindFirstChild("ProximityPrompt")
		if proximityPrompt then
			proximityPrompt.Triggered:Connect(function(player)
				player.PlayerGui.ShopGui.Frame.Visible = true
				print("Shop prompt used!")
				local closeButton = player.PlayerGui.ShopGui.Frame.Close
				closeButton.MouseButton1Click:Connect(function()
					print("Shop GUI disabled")
					player.PlayerGui.ShopGui.Frame.Visible = false
				end)
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