-- StarterGui/SoulsGui/Frame/Souls
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local RunService = game:GetService("RunService")
local closeButton = script.Parent.Close
local SwordsPanel = script.Parent.SwordsPanel
local Template = script.Parent.Template
local ToolTipTemplate = script.Parent.ToolTipTemplate -- Assuming ToolTipTemplate is in the same directory

-- Function to set up the model in the ViewportFrame
local function setupViewportModel(viewportFrame, model)
	local camera = Instance.new("Camera")
	camera.Parent = viewportFrame
	viewportFrame.CurrentCamera = camera

	local modelClone = model:Clone()
	modelClone.Parent = viewportFrame

	local primaryPart = modelClone.PrimaryPart or modelClone:FindFirstChildWhichIsA("BasePart")
	if primaryPart then
		local radius = 2.85 -- Distance from the primary part
		local angle = 0 -- Initial angle

		-- Initial camera position
		camera.CFrame = CFrame.new(primaryPart.Position) * CFrame.new(0, 0, radius) * CFrame.Angles(0, math.rad(angle), 0)

		-- Rotate the camera around the primaryPart 360 degrees continuously using RenderStepped
		RunService.RenderStepped:Connect(function()
			angle = angle + 1
			camera.CFrame = CFrame.new(primaryPart.Position) * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, radius)
		end)
	end
end

-- Function to populate the panel with items
local function populatePanel()
	if SwordsPanel.Parent.EmptyPanel.Visible then
		SwordsPanel.Parent.EmptyPanel.Visible = false
	end
	SwordsPanel.Visible = true

	-- Clear existing items if any
	for _, child in ipairs(SwordsPanel:GetChildren()) do
		if not child:IsA("UIGridLayout") then
			child:Destroy()
		end
	end

	-- Fetch items from ReplicatedStorage
	local weaponsFolder = ReplicatedStorage:FindFirstChild("Souls")
	if weaponsFolder then
		local swordsFolder = weaponsFolder
		if swordsFolder then
			-- Iterate through items in Swords folder
			for _, tool in ipairs(swordsFolder:GetChildren()) do
				-- Clone the template and populate it
				local newItem = Template:Clone()
				newItem.Visible = true
				newItem.Parent = SwordsPanel
				newItem.TextLabel.Text = tool:FindFirstChild("SOUL_NAME").Value -- Assuming WEAPON_NAME is a StringValue in each tool

				-- Set up the model in the ViewportFrame
				local viewportFrame = newItem:FindFirstChild("ViewportFrame")
				if viewportFrame then
					local model = tool:FindFirstChildOfClass("Model")
					if model then
						setupViewportModel(viewportFrame, model)
					end
				end

				-- Mouse click event for showing tooltip
				newItem.ItemButton.MouseButton1Click:Connect(function()
					-- Clone and show tooltip
					local tooltip = ToolTipTemplate:Clone()
					tooltip.Visible = true
					tooltip.Parent = newItem

					-- Auto-hide tooltip after 5 seconds
					wait(5)
					tooltip:Destroy()
				end)
			end
		else
			warn("Swords folder not found in Weapons")
		end
	else
		warn("Weapons folder not found in ReplicatedStorage")
	end
end

-- Connect the button click to populate the panel
populatePanel()
closeButton.MouseButton1Click:Connect(function()
	script.Parent.Parent.Enabled = false
end)