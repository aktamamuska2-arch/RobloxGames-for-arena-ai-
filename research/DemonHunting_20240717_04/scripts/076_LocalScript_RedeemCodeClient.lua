-- StarterGui/MainGui/CodesFrame/RedeemCodeClient
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RedeemCode = ReplicatedStorage.Events:WaitForChild("RedeemCode")
local RedeemCodeResult = ReplicatedStorage.Events:WaitForChild("RedeemCodeResult")

local ConfirmButton = script.Parent.Confirm
local TextBox = script.Parent.TextBox
local TextLabel = script.Parent.TextLabel

ConfirmButton.MouseButton1Click:Connect(function()
	local code = TextBox.Text:upper()
	RedeemCode:FireServer(code)
end)

RedeemCodeResult.OnClientEvent:Connect(function(result)
	TextLabel.Text = result
	wait(2) -- Display the result message for 2 seconds
	TextLabel.Text = "Redeem codes for rewards:" -- Reset the TextLabel
end)