-- ServerScriptService/OutlineLight
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

	-- Add PointLight to emit light from the part
	local pointLight = Instance.new("PointLight")
	pointLight.Parent = part
	pointLight.Color = Color3.new(1, 1, 1) -- Light color
	pointLight.Range = 10 -- Adjust range as needed
	pointLight.Brightness = 1 -- Adjust brightness as needed
	pointLight.Shadows = true -- Enable shadows if needed
end

local function applyToAllParts()
	for _, part in pairs(workspace:GetDescendants()) do
		if part:IsA("BasePart") then
			applyOutlineAndFill(part)
		end
	end
end

-- Apply outline, fill, and light when the game starts
applyToAllParts()

-- Apply outline, fill, and light to new parts when they are added to the game
workspace.DescendantAdded:Connect(function(part)
	if part:IsA("BasePart") then
		applyOutlineAndFill(part)
	end
end)
