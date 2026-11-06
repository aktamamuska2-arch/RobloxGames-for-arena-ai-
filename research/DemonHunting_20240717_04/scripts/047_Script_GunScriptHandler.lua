-- ReplicatedStorage/Weapons/Gun/UMP45/GunScriptHandler
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
		-- Tween to fade in (Transparency 1 to 0)
		local tweenInfo = TweenInfo.new(0.125, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut)
		local goal = {Transparency = 0.89}
		local tween = TweenService:Create(vfxClone, tweenInfo, goal)
		tween:Play()
		tween.Completed:Wait()
		-- Tween to fade out (Transparency 0 to 1)
		goal = {Transparency = 1}
		tween = TweenService:Create(vfxClone, tweenInfo, goal)
		tween:Play()
		game.Debris:AddItem(vfxClone, 0.1)
	else
		warn("VFX "..vfxType.." not found!")
	end
end

local function createBullet(player,data)
	local BULLET_SPEED = data.BULLET_SPEED
	local hitSound = data.HIT_SOUND
	local animName = data.GUN_ANIM
	local animSpeed = data.ANIMSPEED or 1
	local swingSound = data.SWING_SOUND
	local vfxType = data.VFX_TYPE
	local LOWEST_DAMAGE = data.LOWEST_DAMAGE
	local HIGHEST_DAMAGE = data.HIGHEST_DAMAGE

	local gun = player.Character:FindFirstChild("UMP45"):FindFirstChild("UMP45_SMG"):FindFirstChild("Muzzle")
	if not gun then return end

	local bullet = Instance.new("Part")
	bullet.Size = Vector3.new(0.3, 0.3, 3.5)
	bullet.Material = "Neon"
	bullet.CFrame = gun.CFrame * CFrame.new(0, 0, 0) * CFrame.Angles(0, math.rad(-90), 0)
	bullet.CanCollide = false
	bullet.Parent = workspace

	local velocity = Instance.new("BodyVelocity", bullet)
	velocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
	velocity.Velocity = bullet.CFrame.LookVector * BULLET_SPEED + Vector3.new(math.random(-5, 5), math.random(-5, 5), 0)

	local pointlight = Instance.new("PointLight", gun)
	game.Debris:AddItem(pointlight, 0.2)

	playAnimation(player, animName, animSpeed) -- Play the attack animation
	playSound(player, swingSound) 	-- Play the swing sound
	local function damage(part)
		local damage = math.random(LOWEST_DAMAGE, HIGHEST_DAMAGE)
		if part.Parent.ClassName ~= "Accessory" and part.Parent.Parent.ClassName ~= "Accessory" and part.ClassName ~= "Accessory" and part.Parent.Name ~= player.Name and part.CanCollide == true then
			bullet:Destroy()
			local victimHumanoid = part.Parent:FindFirstChildOfClass("Humanoid")
			if victimHumanoid then
				victimHumanoid:TakeDamage(damage)
				if not hitCounters[player.Name] then
					hitCounters[player.Name] = 0 -- Start the hit counters
				end
				hitCounters[player.Name] = hitCounters[player.Name] + 1
				applyHitEffect(player, hitCounters[player.Name]) -- Apply hit effects and start/reset timer
				startHitTimer(player)
				createVFX(bullet.Position, vfxType) -- Create the VFX at the hit position
				playSound(player, hitSound) -- Play hit sound
			end
		end
	end

	bullet.Touched:Connect(damage)
	game.Debris:AddItem(bullet, 5)
end


game.ReplicatedStorage.Events.CombatHitRanged.OnServerEvent:Connect(createBullet)