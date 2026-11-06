-- StarterGui/MainGui/Icons/Codes
local Players = game:GetService("Players")
local Button = script.Parent.CodesButton
local CloseButton = script.Parent.Parent.CodesFrame.Close

Button.MouseButton1Click:Connect(function()
	Players.LocalPlayer.PlayerGui.MainGui.CodesFrame.Visible = true
end)
CloseButton.MouseButton1Click:Connect(function()
	Players.LocalPlayer.PlayerGui.MainGui.CodesFrame.Visible = false
end)
