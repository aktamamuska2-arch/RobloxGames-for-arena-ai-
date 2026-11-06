-- StarterGui/MapVoting/LocalScript
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MapsFolder = ReplicatedStorage:WaitForChild("Maps")
local VotingEvent = ReplicatedStorage:WaitForChild("VotingEvent")

local player = Players.LocalPlayer
local screenGui = script.Parent -- Assuming the script is under the ScreenGui

function createVotingUI(mapChoices)
	screenGui:ClearAllChildren()

	local voteFrame = Instance.new("Frame")
	voteFrame.Size = UDim2.new(1, 0, 1, 0)
	voteFrame.Parent = screenGui

	for i, map in ipairs(mapChoices) do
		local button = Instance.new("TextButton")
		button.Size = UDim2.new(0.3, 0, 0.2, 0)
		button.Position = UDim2.new(0.1 * i, 0, 0.4, 0)
		button.Text = map:FindFirstChild("MapName").Value .. " by " .. map:FindFirstChild("MapCreator").Value
		button.Parent = voteFrame

		button.MouseButton1Click:Connect(function()
			VotingEvent:FireServer(map.Name)
		end)
	end
end

VotingEvent.OnClientEvent:Connect(createVotingUI)
