-- ServerScriptService/StarterCombat
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")
local TweenService = game:GetService("TweenService")

local parryStates = {}
local damageValues = {
	["Punch"] = 5,
	["HardSmack"] = 10,
	["MegaPunch"] = 25,
	["Swing"] = 35,
	["AxeSwing"] = 50,
	["Parry"] = 1
}

local weaponSounds = {
	["Light Melee"] = "rbxassetid://8595980577",
	["Heavy Melee"] = "rbxassetid://9117969717",
	["Light Blade"] = "rbxassetid://7006581839",
	["Heavy Blade"] = "rbxassetid://7171761940",
	["Light Blunt"] = "rbxassetid://180163749",
	["Heavy Blunt"] = "rbxassetid://9117969584",
	["Light Magic"] = "rbxassetid://175024455",
	["Heavy Magic"] = "rbxassetid://8595975458",
	["Ranged"] = "rbxassetid://6603295565"
}

local hitCounters = {}  -- To keep track of players' hit counts
local hitTimers = {}  -- To manage reset timers for each player
local shakingTweens = {}  -- To keep track of ongoing shaking tweens

-- Function to reset hit count
local function resetHitCount(player)
	if hitCounters[player.Name] then
		hitCounters[player.Name] = 0
		local playerGui = player:FindFirstChild("PlayerGui")
		if playerGui then
			local mainGui = playerGui:FindFirstChild("MainGui")
			if mainGui then
				local hitFrame = mainGui:FindFirstChild("HitFrame")
				if hitFrame then
					hitFrame.Visible = false
					local hitCountLabel = hitFrame:FindFirstChild("HitCount")
					if hitCountLabel then
						hitCountLabel.Text = tostring(hitCounters[player.Name])
						hitCountLabel.TextColor3 = Color3.new(1, 1, 1) -- Reset color to white
						hitCountLabel.Position = UDim2.new(0.5, 0, 0.5, 0) -- Reset position
						hitCountLabel.Size = UDim2.new(1, 0, 1, 0) -- Reset size
						hitCountLabel.Rotation = 0 -- Reset rotation

						-- Stop any ongoing shaking tweens
						if shakingTweens[player.Name] then
							for _, tween in ipairs(shakingTweens[player.Name]) do
								tween:Cancel()
							end
							shakingTweens[player.Name] = nil
						end
					end
				end
			end
		end
	end
end

local function startHitTimer(player)
	if hitTimers[player.Name] then
		coroutine.close(hitTimers[player.Name])
	end
	hitTimers[player.Name] = coroutine.create(function()
		while true do
			wait(2)
			resetHitCount(player)
			break
		end
	end)
	coroutine.resume(hitTimers[player.Name])
end

local function applyHitEffects(hitCountLabel, hitCount, playerName)
	-- Reset properties
	hitCountLabel:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.2, true)
	hitCountLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
	hitCountLabel.Rotation = 0

	local color
	if hitCount > 50 then
		color = Color3.fromRGB(255, 165, 0) -- Orange
	elseif hitCount > 40 then
		color = Color3.fromRGB(255, 255, 0) -- Yellow
	elseif hitCount > 30 then
		color = Color3.fromRGB(255, 0, 0) -- Red
	else
		color = Color3.fromRGB(255, 255, 255) -- White
	end
	hitCountLabel.TextColor3 = color

	local shakeMagnitude = 0
	if hitCount > 30 then
		shakeMagnitude = 4 -- Violent shake
	elseif hitCount > 10 then
		shakeMagnitude = 2 -- Slight shake
	end

	-- Stop any ongoing shaking tweens
	if shakingTweens[playerName] then
		for _, tween in ipairs(shakingTweens[playerName]) do
			tween:Cancel()
		end
		shakingTweens[playerName] = nil
	end

	if shakeMagnitude > 0 then
		shakingTweens[playerName] = {}

		local function shake()
			if hitCounters[playerName] > 0 then
				local randomOffset = math.random(-shakeMagnitude, shakeMagnitude)
				local newPos = UDim2.new(0.5, randomOffset, 0.5, randomOffset)
				local newRot = math.random(-shakeMagnitude, shakeMagnitude)
				local shakeTween = TweenService:Create(hitCountLabel, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Position = newPos, Rotation = newRot})
				table.insert(shakingTweens[playerName], shakeTween)
				shakeTween:Play()
				shakeTween.Completed:Connect(function()
					shake()
				end)
			end
		end

		shake()
	end
end

game.ReplicatedStorage.Events.Combat.OnServerEvent:Connect(function(player, action, vfx, weaponType)
	local swingsfx = Instance.new("Sound")
	swingsfx.SoundId = "rbxassetid://5835032207"
	swingsfx.Parent = player.Character
	swingsfx.Pitch = 0.7 + math.random() * 0.6
	swingsfx:Play()
	Debris:AddItem(swingsfx, 0.5)

	if action == "Parry" then
		parryStates[player.Name] = true
		wait(1) -- Assuming the parry lasts for 1 second
		parryStates[player.Name] = false
		return
	end

	local hitbox = Instance.new("Part")
	hitbox.Parent = workspace
	hitbox.Anchored = true
	hitbox.CanCollide = false
	hitbox.Transparency = 0.995
	hitbox.Size = Vector3.new(5, 5, 2)
	hitbox.CFrame = player.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
	Debris:AddItem(hitbox, 1.5)
	local Hits = {}

	hitbox.Touched:Connect(function(hit)
		if hit.Parent:FindFirstChild("Humanoid") and hit.Parent.Name ~= player.Name then
			if not hit.Parent.Humanoid:FindFirstChild(player.Name) then
				if Hits[hit.Parent.Name] then return end
				Hits[hit.Parent.Name] = true

				local hitsound = Instance.new("Sound")
				hitsound.SoundId = weaponSounds[weaponType]
				hitsound.Parent = hit.Parent:FindFirstChild("Humanoid")
				hitsound:Play()
				Debris:AddItem(hitsound, 1.5)

				local basicPunch = game.ReplicatedStorage.VFX[vfx].Attachment:Clone()
				basicPunch.Parent = hit.Parent:FindFirstChild("HumanoidRootPart")
				for _, v in pairs(basicPunch:GetChildren()) do
					if v:IsA("ParticleEmitter") then
						v:Emit(v:GetAttribute("EmitCount"))
					end
				end
				Debris:AddItem(basicPunch, 0.25)

				if not parryStates[hit.Parent.Name] then
					local damage = damageValues[action] or 0
					hit.Parent:FindFirstChild("Humanoid"):TakeDamage(damage)
				else
					-- If parry is active, check weapon type
					if weaponType == "Light Magic" or weaponType == "Heavy Magic" or weaponType == "Ranged" then
						local damage = damageValues[action] or 0
						hit.Parent:FindFirstChild("Humanoid"):TakeDamage(damage)
					else
						-- Add a visual or sound effect for a successful parry
						local parrySound = Instance.new("Sound")
						parrySound.SoundId = "rbxassetid://9113449244" -- Replace with the actual sound ID
						parrySound.Parent = hit.Parent:FindFirstChild("Humanoid")
						parrySound:Play()
						Debris:AddItem(parrySound, 1.5)

						-- Stun the attacking player
						local humanoid = player.Character:FindFirstChild("Humanoid")
						if humanoid then
							humanoid.WalkSpeed = 0
							wait(2)
							humanoid.WalkSpeed = 16 -- Assuming the default walk speed is 16
						end
					end
				end

				-- Increment hit count and update the GUI
				hitCounters[player.Name] = (hitCounters[player.Name] or 0) + 1
				local playerGui = player:FindFirstChild("PlayerGui")
				if playerGui then
					local mainGui = playerGui:FindFirstChild("MainGui")
					if mainGui then
						local hitFrame = mainGui:FindFirstChild("HitFrame")
						if hitFrame then
							hitFrame.Visible = hitCounters[player.Name] >= 2
							local hitCountLabel = hitFrame:FindFirstChild("HitCount")
							if hitCountLabel then
								hitCountLabel.Text = tostring(hitCounters[player.Name])
								hitCountLabel:TweenSize(UDim2.new(1.1, 0, 1.1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.2, true, function()
									hitCountLabel:TweenSize(UDim2.new(1, 0, 1, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Bounce, 0.2, true)
								end)
								applyHitEffects(hitCountLabel, hitCounters[player.Name], player.Name)
							end
						end
					end
				end

				-- Start/reset the hit timer
				startHitTimer(player)

				wait(0.5)
				Hits[hit.Parent.Name] = false
			end
		end
	end)
end)
