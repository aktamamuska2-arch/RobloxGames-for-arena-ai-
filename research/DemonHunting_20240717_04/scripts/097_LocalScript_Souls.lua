-- StarterGui/MainGui/Icons/Souls
local Players = game:GetService("Players")
local Button = script.Parent.SoulsButton
local CloseButton = script.Parent.Parent.Parent.SoulsGui.Frame.Close

Button.MouseButton1Click:Connect(function()
	Players.LocalPlayer.PlayerGui.SoulsGui.Enabled = true
end)
CloseButton.MouseButton1Click:Connect(function()
	Players.LocalPlayer.PlayerGui.SoulsGui.Enabled = false
end)
