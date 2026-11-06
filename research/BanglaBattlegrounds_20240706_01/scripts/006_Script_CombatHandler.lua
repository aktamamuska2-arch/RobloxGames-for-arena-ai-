-- ServerScriptService/CombatHandler
local replicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvent = replicatedStorage.Events:WaitForChild("Combat")

-- Function to apply force and damage
function applyForceAndDamage(player, part, forceMagnitude, damageAmount)
	local direction = player.Character.HumanoidRootPart.CFrame.LookVector
	local forceVector = direction * forceMagnitude
	-- Apply force to objects and damage to humanoids
	for _, obj in ipairs(part:GetTouchingParts()) do
		if obj:IsA("BasePart") then
			local humanoid = obj.Parent:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid ~= player.Character:FindFirstChildOfClass("Humanoid") then
				humanoid:TakeDamage(damageAmount)
				-- Play hit sound
				local hitSound = Instance.new("Sound")
				hitSound.SoundId = "rbxassetid://8595980577"
				hitSound.Volume = 0.5
				hitSound.Parent = humanoid.Parent:FindFirstChildWhichIsA("BasePart") or part
				hitSound:Play()
				game.Debris:AddItem(hitSound, 2) -- Ensure the sound is cleaned up after playing
			end
			obj.Velocity = obj.Velocity + forceVector
		end
	end
end



function combatMove(player, move, partTemplate, duration, force, damage, soundid, opacity)
	-- Display part
	local part = partTemplate:Clone()
	part.Position = player.Character.HumanoidRootPart.Position + player.Character.HumanoidRootPart.CFrame.LookVector * 2
	part.CFrame = CFrame.new(part.Position, part.Position + player.Character.HumanoidRootPart.CFrame.LookVector)
	part.Anchored = true
	part.Parent = game.Workspace

	-- Play sound
	local punchSound = Instance.new("Sound")
	punchSound.SoundId = "rbxassetid://" .. soundid  -- Replace with your punch sound ID
	punchSound.Volume = 0.5
	punchSound.Parent = player.Character.HumanoidRootPart
	punchSound:Play()

	-- Animate transparency and apply force/damage
	local steps = 5
	for t = 0, steps do
		part.Transparency = opacity
		part.Position = part.Position + player.Character.HumanoidRootPart.CFrame.LookVector * (2 / steps)  -- Move part forward
		applyForceAndDamage(player, part, force, damage)
		wait(duration / steps)
	end

	-- Destroy part after animation
	part:Destroy()
end


remoteEvent.OnServerEvent:Connect(function(player, actionName)
	-- Handle different actions
	if actionName == "Punch" then
		combatMove(player, "Punch", script.Part, 0.3, 0, 5, "5835032207", 0.999)

	elseif actionName == "Punch2" then
		combatMove(player, "Punch2", script.Part, 0.4, 0, 20, "7171591581", 0.99)

	elseif actionName == "MegaPunch" then
		combatMove(player, "MegaPunch", script.Wave, 0.5, 0, 50, "6241709963", 0.9)

	elseif actionName == "HardSmack" then
		combatMove(player, "HardSmack", script.Part, 0.5, 0, 25, "6241709963", 0.995)

	elseif actionName == "LeftKick" then
		combatMove(player, "LeftKick", script.Part, 0.5, 0, 15, "6241709963", 0.995)

	else
		warn("Unknown action: " .. actionName)
	end
end)
