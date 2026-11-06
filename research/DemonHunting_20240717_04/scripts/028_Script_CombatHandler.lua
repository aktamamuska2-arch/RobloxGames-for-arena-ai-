-- ServerScriptService/MainScripts/CombatHandler
-- Combat Handler for Demon Hunting Paradise, D. MUKTO

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

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

local function applyHitEffect(player, hitCount)
	local playerGui = player:FindFirstChild("PlayerGui")
	if playerGui then
		local mainGui = playerGui:FindFirstChild("MainGui")
		if mainGui then
			local hitFrame = mainGui:FindFirstChild("HitFrame")
			if hitFrame then
				hitFrame.Visible = true
				local hitCountLabel = hitFrame:FindFirstChild("HitCount")
				if hitCountLabel then
					-- Reset properties
					hitCountLabel.Text = tostring(hitCount)
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
					if shakingTweens[player.Name] then
						for _, tween in ipairs(shakingTweens[player.Name]) do
							tween:Cancel()
						end
						shakingTweens[player.Name] = nil
					end

					if shakeMagnitude > 0 then
						shakingTweens[player.Name] = {}

						local function shake()
							if hitCounters[player.Name] > 0 then
								local randomOffset = math.random(-shakeMagnitude, shakeMagnitude)
								local newPos = UDim2.new(0.5, randomOffset, 0.5, randomOffset)
								local newRot = math.random(-shakeMagnitude, shakeMagnitude)
								local shakeTween = TweenService:Create(hitCountLabel, TweenInfo.new(0.05, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut), {Position = newPos, Rotation = newRot})
								table.insert(shakingTweens[player.Name], shakeTween)
								shakeTween:Play()
								shakeTween.Completed:Connect(function()
									shake()
								end)
							end
						end

						shake()
					end
				end
			end
		end
	end
end

local function playAnimation(player, animName, speed)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local animations = game.ReplicatedStorage:WaitForChild("Animations")
		if humanoid and animations then
			local anim = animations:FindFirstChild(animName)
			if anim then
				local animTrack = humanoid:LoadAnimation(anim)
				animTrack:AdjustSpeed(speed)
				animTrack:Play()
			else
				warn("Animation "..animName.." not found!")
			end
		end
	end
end

local function playSound(player, soundName)
	local character = player.Character
	if character then
		local sounds = game.ReplicatedStorage:WaitForChild("Sounds")
		if sounds then
			local sound = sounds:FindFirstChild(soundName)
			if sound then
				local soundClone = sound:Clone()
				soundClone.Parent = character
				soundClone.Pitch = 1 + (math.random() * 0.2 - 0.1)
				soundClone:Play()
				soundClone.Ended:Connect(function()
					soundClone:Destroy()
				end)
			else
				warn("Sound "..soundName.." not found!")
			end
		end
	end
end

local function createVFX(position, vfxType)
	local vfx = game.ReplicatedStorage:WaitForChild("VFX"):FindFirstChild(vfxType)
	if vfx then
		local vfxClone = vfx:Clone()
		vfxClone.Position = position
		vfxClone.Parent = workspace
		game.Debris:AddItem(vfxClone, 0.35)
	else
		warn("VFX "..vfxType.." not found!")
	end
end

local function onCombatHitReceived(player, data)
	local isHeavy = data.isHeavy
	local damage = isHeavy and data.HEAVY_DAMAGE or data.LIGHT_DAMAGE
	local anims = isHeavy and data.heavyAnims or data.punchAnims
	local hitSound = isHeavy and data.HEAVY_SOUND or data.LIGHT_SOUND
	local animName = anims[math.random(1, #anims)]
	local animSpeed = data.ANIMSPEED or 1
	local swingSound = data.SWING_SOUND
	local vfxType = data.VFX_TYPE
	local raycastLength = data.HIT_RANGE or 5

	playAnimation(player, animName, animSpeed) -- Play the punch animation
	playSound(player, swingSound) 	-- Play the swing sound
	-- Raycast to detect hit
	local character = player.Character
	if character then
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local rayOrigin = humanoidRootPart.Position
			local rayDirection = humanoidRootPart.CFrame.LookVector * raycastLength  -- Adjust length as needed
			local raycastParams = RaycastParams.new()
			raycastParams.FilterDescendantsInstances = {character}
			raycastParams.FilterType = Enum.RaycastFilterType.Exclude
			local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

			if raycastResult then
				local hitPart = raycastResult.Instance
				local hitHumanoid = hitPart.Parent:FindFirstChildOfClass("Humanoid") or hitPart.Parent.Parent:FindFirstChildOfClass("Humanoid")

				if hitHumanoid then
					hitHumanoid:TakeDamage(damage) -- Apply damage
					if not hitCounters[player.Name] then
						hitCounters[player.Name] = 0 -- Start the hit counters
					end
					hitCounters[player.Name] = hitCounters[player.Name] + 1
					applyHitEffect(player, hitCounters[player.Name]) -- Apply hit effects and start/reset timer
					startHitTimer(player)
					createVFX(raycastResult.Position, vfxType) -- Create the VFX at the hit position
					playSound(player, hitSound) -- Play hit sound
				end
			end
		end
	end
end

game.ReplicatedStorage.Events.CombatHit.OnServerEvent:Connect(onCombatHitReceived)
