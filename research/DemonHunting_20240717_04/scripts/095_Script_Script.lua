-- ReplicatedStorage/Martial/Script
local tool = script.Parent
local handle = tool:WaitForChild("Part")

local function onTouch(otherPart)
	local character = otherPart.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")

	if humanoid then
		-- Check if the player already has the tool in their backpack or equipped
		local player = game.Players:GetPlayerFromCharacter(character)
		if player and not player.Backpack:FindFirstChild(tool.Name) and not character:FindFirstChild(tool.Name) then
			-- Clone the tool and place it in the player's backpack
			local clonedTool = tool:Clone()
			clonedTool.Parent = player.Backpack
			-- Optionally, destroy the original tool in the workspace
			tool:Destroy()
		end
	end
end

handle.Touched:Connect(onTouch)