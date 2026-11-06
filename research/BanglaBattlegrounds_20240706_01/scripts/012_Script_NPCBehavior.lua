-- Workspace/Dummies/Modon /NPCBehavior
-- NPC AI: Modon

local npc = script.Parent
local npchumanoid = npc.Humanoid

-- Load animations
local punchAnim = Instance.new("Animation")
punchAnim.AnimationId = "rbxassetid://18341956985"
local punchTrack = npchumanoid:LoadAnimation(punchAnim)

local walkAnim = Instance.new("Animation")
walkAnim.AnimationId = "rbxassetid://18341853673"
local walkTrack = npchumanoid:LoadAnimation(walkAnim)

local sight = 1200
local walking = false
local attacking = false
local canattack = true
local cansay = true
local saycooldown = 0

function walkanim(walkspeed)
	if walkspeed > 5 then
		walking = true
		if not walkTrack.IsPlaying then
			walkTrack:Play()
		end
	else
		walking = false
		walkTrack:Stop()
	end
end
npchumanoid.Running:Connect(walkanim)

function randomwalk()
	while wait(math.random(3,6)) do
		if not attacking and not walking then
			npchumanoid.WalkSpeed = 16
			local function createwalkpart()
				local walkpart = Instance.new("Part", npc)
				walkpart.Size = Vector3.new(1, 1, 1)
				walkpart.Anchored = true
				walkpart.Material = "Neon"
				walkpart.Transparency = 1
				walkpart.BrickColor = BrickColor.new("Maroon")
				walkpart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(math.random(-60,60),math.random(-30,30),math.random(-60,60))
				local path = game:GetService("PathfindingService"):FindPathAsync(npc.HumanoidRootPart.Position, walkpart.Position)
				local waypoints = path:GetWaypoints()
				if path.Status == Enum.PathStatus.Success then
					for _, waypoint in pairs(waypoints) do
						local pospart = Instance.new("Part", npc)
						pospart.Size = Vector3.new(1, 1, 1)
						pospart.Anchored = true
						pospart.Material = "Neon"
						pospart.Transparency = 1
						pospart.Position = waypoint.Position
						pospart.Name = "pospart"
						pospart.CanCollide = false
					end
					for _, waypoint in pairs(waypoints) do
						npchumanoid:MoveTo(waypoint.Position)
						local allow = 0
						while (npc.HumanoidRootPart.Position - waypoint.Position).magnitude > 4 and allow < 35 do
							allow = allow + 1
							wait()
						end
						if waypoint.Action == Enum.PathWaypointAction.Jump then
							npchumanoid.Jump = true
						end
					end
					for _, child in pairs(npc:GetChildren()) do
						if child.Name == "pospart" then
							child:Destroy()
						end
					end
				else
					createwalkpart()
					wait()
				end
				walkpart:Destroy()
			end
			createwalkpart()
		end
	end
end

function checkandattack()
	while wait() do
		saycooldown = saycooldown + 1
		if saycooldown == 500 then
			cansay = true
			saycooldown = 0
		end
		for _, model in pairs(workspace:GetChildren()) do
			if model:IsA("Model") then
				local victimhumanoid = model:FindFirstChildOfClass("Humanoid")
				local victimhead = model:FindFirstChild("Head")
				if victimhumanoid and victimhead and model.Name ~= npc.Name then
					if (victimhead.Position - npc.Head.Position).magnitude < sight then

						local shouldAttack = false
						if (victimhead.Position - npc.Head.Position).magnitude < 5 then
							shouldAttack = true
						end

						if shouldAttack and not attacking and victimhumanoid.Health > 0 and canattack then
							attacking = true
							walking = false
							local doattack = 0
							local hpnow = npchumanoid.Health
							local walk = 0
							npchumanoid.WalkSpeed = 0
							while attacking and (victimhead.Position - npc.Head.Position).magnitude < sight and victimhumanoid.Health > 0 and canattack do
								doattack = doattack + 1
								walk = walk + 1
								if not npchumanoid.PlatformStand then
									npc.HumanoidRootPart.CFrame = CFrame.new(npc.HumanoidRootPart.Position, Vector3.new(victimhead.Position.x, npc.HumanoidRootPart.Position.y, victimhead.Position.z))
								end
								if walk == 100 and not walking then
									local function createwalkpart()
										local walkpart = Instance.new("Part", npc)
										walkpart.Size = Vector3.new(1, 1, 1)
										walkpart.Anchored = true
										walkpart.Material = "Neon"
										walkpart.Transparency = 1
										walkpart.BrickColor = BrickColor.new("Maroon")
										walkpart.CFrame = npc.HumanoidRootPart.CFrame * CFrame.new(-math.random(20, 60), math.random(-40, 40), math.random(-10, 10))
										local path = game:GetService("PathfindingService"):FindPathAsync(npc.HumanoidRootPart.Position, walkpart.Position)
										local waypoints = path:GetWaypoints()
										if path.Status == Enum.PathStatus.Success then
											attacking = false
											canattack = false
											npchumanoid.WalkSpeed = 20
											for _, waypoint in pairs(waypoints) do
												local pospart = Instance.new("Part", npc)
												pospart.Size = Vector3.new(1, 1, 1)
												pospart.Anchored = true
												pospart.Material = "Neon"
												pospart.Transparency = 1
												pospart.Position = waypoint.Position
												pospart.Name = "pospart"
												pospart.CanCollide = false
											end
											for _, waypoint in pairs(waypoints) do
												npchumanoid:MoveTo(waypoint.Position)
												local allow = 0
												while (npc.HumanoidRootPart.Position - waypoint.Position).magnitude > 4 and allow < 35 do
													allow = allow + 1
													wait()
												end
												if waypoint.Action == Enum.PathWaypointAction.Jump then
													npchumanoid.Jump = true
												end
											end
											canattack = true
											npchumanoid.WalkSpeed = 16
											for _, child in pairs(npc:GetChildren()) do
												if child.Name == "pospart" then
													child:Destroy()
												end
											end
										else
											createwalkpart()
											wait()
										end
										walkpart:Destroy()
									end
									createwalkpart()
								end
								if doattack == 5 then
									doattack = 0
									punchTrack:Play()
									local hitbox = Instance.new("Part")
									hitbox.Size = Vector3.new(3.5, 3.5, 3.5)
									hitbox.Transparency = 1
									hitbox.Anchored = true
									hitbox.CFrame = npc["Right Arm"].CFrame * CFrame.new(0, 0, -4)
									hitbox.CanCollide = false
									hitbox.Parent = workspace

									hitbox.Touched:Connect(function(hit)
										local hum = hit.Parent:FindFirstChildOfClass("Humanoid")
										if hum and hum ~= npchumanoid then
											hum:TakeDamage(25)
										end
									end)

									game:GetService("Debris"):AddItem(hitbox, 0.2)
								end
								wait(0.1)
							end
							if hpnow == npchumanoid.Health then
								hpnow = npchumanoid.Health
								canattack = true
							else
								hpnow = npchumanoid.Health
								canattack = false
							end
							attacking = false
						end
					end
				end
			end
		end
	end
end

spawn(checkandattack)
spawn(randomwalk)
