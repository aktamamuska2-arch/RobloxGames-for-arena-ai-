-- StarterPlayer/StarterPlayerScripts/Outliner
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local function applyOutlineAndFill(part)
	-- Create a SelectionBox for the outline
	local selectionBox = Instance.new("SelectionBox")
	selectionBox.Parent = part
	selectionBox.Adornee = part
	selectionBox.LineThickness = 0.05 -- Adjust thickness as needed
	selectionBox.Color3 = Color3.new(1, 1, 1) -- Color of the outline

	-- Create SurfaceGuis for filling the surfaces with black
	for _, face in pairs(Enum.NormalId:GetEnumItems()) do
		local surfaceGui = Instance.new("SurfaceGui")
		surfaceGui.Parent = part
		surfaceGui.Adornee = part
		surfaceGui.Face = face
		surfaceGui.CanvasSize = Vector2.new(1024, 1024)

		local frame = Instance.new("Frame")
		frame.Parent = surfaceGui
		frame.Size = UDim2.new(1, 0, 1, 0)
		frame.BackgroundColor3 = Color3.new(0, 0, 0) -- Black color
		frame.BorderSizePixel = 0
	end
end

local function applyToAllParts()
	for _, part in pairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") then
			applyOutlineAndFill(part)
		end
	end
end

-- Apply outline and fill when the game starts
applyToAllParts()

-- Apply outline and fill to new parts when they are added to the game
workspace.DescendantAdded:Connect(function(part)
	if part:IsA("BasePart") then
		applyOutlineAndFill(part)
	end
end)

local function updateVisibility()
	local player = Players.LocalPlayer
	local camera = workspace.CurrentCamera

	while true do
		if player and camera then
			for _, part in pairs(workspace:GetDescendants()) do
				if part:IsA("BasePart") then
					local distance = (part.Position - camera.CFrame.Position).Magnitude
					local transparency = math.clamp(distance / 100, 0, 1)

					for _, child in pairs(part:GetChildren()) do
						if child:IsA("SelectionBox") then
							child.Transparency = transparency
						elseif child:IsA("SurfaceGui") then
							for _, guiChild in pairs(child:GetChildren()) do
								if guiChild:IsA("Frame") then
									guiChild.BackgroundTransparency = transparency
								end
							end
						end
					end
				end
			end
		end
		RunService.RenderStepped:Wait()
	end
end

-- Start the visibility update loop
spawn(updateVisibility)
