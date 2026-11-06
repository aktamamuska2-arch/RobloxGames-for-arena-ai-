-- StarterGui/SoulsGui/Frame/SoulsTemp
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local closeButton = script.Parent.Close

closeButton.MouseButton1Click:Connect(function()
	script.Parent.Parent.Enabled = false
end)