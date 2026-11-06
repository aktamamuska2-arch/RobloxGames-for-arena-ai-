-- Workspace/Portal/Door/TeleportScript
local TeleportPart = script.Parent  -- Assuming the script is directly inside the part

-- Function to handle player touches
local function onTouched(hit)
	local player = game.Players:GetPlayerFromCharacter(hit.Parent)
	if player then
		-- Teleport the player to another game
		local placeId = 18129807606
		game:GetService("TeleportService"):Teleport(placeId, player)
	end
end

-- Connect the function to the Touched event of the part
TeleportPart.Touched:Connect(onTouched)
