-- StarterGui/FPVCamera
---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 
								-- StarterGui -- 					
--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--
--	Place this into StarterGui or StarterPack							--
--	CREDIT																--
--	WhoBloxxedWho; for the initial script								--
--	DoogleFox; some stuff ripped from his panner script					--
--	DuruTeru; shoving it all into this script and then some :)			--
--	UPDATE: turned it into r15, made it so you can swim right in water	--
--  Jan 07, 2017														--
--  UPDATE: added walkspeed easing directionally, also adding running   --	
--  Nov 13, 2020														--
--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--	--
local players = game:GetService("Players")
local player = players.LocalPlayer

---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 
local userInputService = game:GetService("UserInputService")

function firstpersonview(enabled)
	if enabled then
		repeat wait() until game:GetService("Players").LocalPlayer.Character ~= nil
		local runService = game:GetService("RunService")
		local input = game:GetService("UserInputService")

		-- you can mess with these settings
		CanToggleMouse = {allowed = true; activationkey = Enum.KeyCode.F;} -- lets you move your mouse around in firstperson
		CanViewBody = false 		-- whether you see your body
		Sensitivity = 0.6		-- anything higher would make looking up and down harder; recommend anything between 0~1
		Smoothness = 0.05		-- recommend anything between 0~1
		FieldOfView = 85		-- fov
		HeadOffset = CFrame.new(0,0.7,0) -- how far your camera is from your head

		local cam = game.Workspace.CurrentCamera
		local player = players.LocalPlayer
		local m = player:GetMouse()
		m.Icon = "http://www.roblox.com/asset/?id=569021388" -- replaces mouse icon
		local character = player.Character or player.CharacterAdded:wait()
		local human = character.Humanoid
		local humanoidpart = character.HumanoidRootPart

		local head = character:WaitForChild("Head")
		local CamPos,TargetCamPos = cam.CoordinateFrame.p,cam.CoordinateFrame.p 
		local AngleX,TargetAngleX = 0,0
		local AngleY,TargetAngleY = 0,0

		local running = true
		local freemouse = false
		local defFOV = FieldOfView

		local w, a, s, d, lshift = false, false, false, false, false

		-- you can mess with these settings
		local easingtime = 0.1 --0~1
		local walkspeeds = {
			enabled =		  true;
			walkingspeed =		16;
			backwardsspeed =	10;
			sidewaysspeed =		15;
			diagonalspeed =		16;
			runningspeed =		25;
			runningFOV=			85;
		}

		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

		function updatechar()

			for _, v in pairs(character:GetChildren())do
				if CanViewBody then
					if v.Name == 'Head' then
						v.LocalTransparencyModifier = 1
						v.CanCollide = false
						v.face.LocalTransparencyModifier = 1
					end
				else
					if v:IsA'Part' or v:IsA'UnionOperation' or v:IsA'MeshPart' then
						v.LocalTransparencyModifier = 1
						v.CanCollide = false
					end
				end
				if v:IsA'Accessory' then
					v:FindFirstChild('Handle').LocalTransparencyModifier = 1
					v:FindFirstChild('Handle').CanCollide = false
				end
				if v:IsA'Hat' then
					v:FindFirstChild('Handle').LocalTransparencyModifier = 1
					v:FindFirstChild('Handle').CanCollide = false
				end

			end

		end

		-- math, thx roblox wiki
		function lerp(a, b, t)
			return a * (1-t) + (b*t)
		end


		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

		input.InputChanged:connect(function(inputObject)

			if inputObject.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = Vector2.new(inputObject.Delta.x/Sensitivity,inputObject.Delta.y/Sensitivity) * Smoothness

				local X = TargetAngleX - delta.y 
				TargetAngleX = (X >= 80 and 80) or (X <= -80 and -80) or X 
				TargetAngleY = (TargetAngleY - delta.x) %360 
			end	

		end)

		input.InputBegan:connect(function(inputObject)

			if inputObject.UserInputType == Enum.UserInputType.Keyboard then
				if inputObject.KeyCode == CanToggleMouse.activationkey then
					if CanToggleMouse.allowed and freemouse == false then
						freemouse = true
					else
						freemouse = false
					end
				end
			end

			if inputObject.UserInputType == Enum.UserInputType.Keyboard then
				if inputObject.KeyCode == Enum.KeyCode.W then
					w = true
				end

				if inputObject.KeyCode == Enum.KeyCode.A then
					a = true
				end

				if inputObject.KeyCode == Enum.KeyCode.S then
					s = true
				end

				if inputObject.KeyCode == Enum.KeyCode.D then
					d = true
				end

				if inputObject.KeyCode == Enum.KeyCode.LeftShift then
					lshift = true
				end
			end
		end)

		input.InputEnded:connect(function(inputObject)
			if inputObject.UserInputType == Enum.UserInputType.Keyboard then
				if inputObject.KeyCode == Enum.KeyCode.W then
					w = false
				end

				if inputObject.KeyCode == Enum.KeyCode.A then
					a = false
				end

				if inputObject.KeyCode == Enum.KeyCode.S then
					s = false
				end

				if inputObject.KeyCode == Enum.KeyCode.D then
					d = false
				end

				if inputObject.KeyCode == Enum.KeyCode.LeftShift then
					lshift = false
				end
			end
		end)

		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 

		runService.RenderStepped:connect(function()

			if running then
				updatechar()

				CamPos = CamPos + (TargetCamPos - CamPos) *0.28 
				AngleX = AngleX + (TargetAngleX - AngleX) *0.35 
				local dist = TargetAngleY - AngleY 
				dist = math.abs(dist) > 180 and dist - (dist / math.abs(dist)) * 360 or dist 
				AngleY = (AngleY + dist *0.35) %360
				cam.CameraType = Enum.CameraType.Scriptable

				cam.CoordinateFrame = CFrame.new(head.Position) 
					* CFrame.Angles(0,math.rad(AngleY),0) 
					* CFrame.Angles(math.rad(AngleX),0,0)
					* HeadOffset -- offset

				humanoidpart.CFrame=CFrame.new(humanoidpart.Position)*CFrame.Angles(0,math.rad(AngleY),0)
			else game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
			end

			if (cam.Focus.p-cam.CoordinateFrame.p).magnitude < 1 then
				running = false
			else
				running = true
				if freemouse == true then
					game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
				else
					game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.LockCenter
				end
			end

			if not CanToggleMouse.allowed then
				freemouse = false
			end

			cam.FieldOfView = FieldOfView

			if walkspeeds.enabled then
				if w and s then return end

				if w and not lshift then
					FieldOfView = lerp(FieldOfView, defFOV,easingtime)
					human.WalkSpeed = lerp(human.WalkSpeed,walkspeeds.walkingspeed,easingtime)
				elseif w and a then
					human.WalkSpeed = lerp(human.WalkSpeed,walkspeeds.diagonalspeed,easingtime)
				elseif w and d then
					human.WalkSpeed = lerp(human.WalkSpeed,walkspeeds.diagonalspeed,easingtime)
				elseif s then
					human.WalkSpeed = lerp(human.WalkSpeed,walkspeeds.backwardsspeed,easingtime)
				elseif s and a then
					human.WalkSpeed = lerp(human.WalkSpeed,walkspeeds.backwardsspeed - (walkspeeds.diagonalspeed - walkspeeds.backwardsspeed),easingtime)
				elseif s and d then
					human.WalkSpeed = lerp(human.WalkSpeed,walkspeeds.backwardsspeed - (walkspeeds.diagonalspeed - walkspeeds.backwardsspeed),easingtime)
				elseif d then
					human.WalkSpeed = lerp(human.WalkSpeed,walkspeeds.sidewaysspeed,easingtime)
				elseif a then
					human.WalkSpeed = lerp(human.WalkSpeed,walkspeeds.sidewaysspeed,easingtime)
				end	

				if lshift and w then
					FieldOfView = lerp(FieldOfView, walkspeeds.runningFOV,easingtime)
					human.WalkSpeed = lerp(human.WalkSpeed,human.WalkSpeed + (walkspeeds.runningspeed - human.WalkSpeed),easingtime)
				end
			end

		end)
	else
		print("FPV disabled")
	end
	---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ---- 
end

local function onCharacterAdded(character)
	local humanoid = character:WaitForChild("Humanoid")
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
	local enabled = false
	userInputService.InputBegan:Connect(function(input)
		if input.KeyCode == Enum.KeyCode.V then
			if not enabled then
				enabled = true
				-- Remove the "VIPAura" from the "Head"
				local head = player.Character:FindFirstChild("Head")
				if head then
					for _, child in ipairs(head:GetChildren()) do
						if child:IsA("ParticleEmitter") then
							child:Destroy()
						end
					end
				end
				firstpersonview(enabled)
			elseif enabled then
				enabled = false
				firstpersonview(enabled)
			end
		end
	end)
end

-- Connect onCharacterAdded function to CharacterAdded event
game.Players.LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Check if character exists initially (in case the player is already spawned)
if game.Players.LocalPlayer.Character then
	onCharacterAdded(game.Players.LocalPlayer.Character)
end
