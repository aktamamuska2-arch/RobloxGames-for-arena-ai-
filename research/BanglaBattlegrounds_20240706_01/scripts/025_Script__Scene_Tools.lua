-- ServerScriptService/_Scene Tools
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local BadgeService = game:GetService("BadgeService")

local Allowed = {
	Hover = {}
}

local Connections = {
	["Hover"] = {},
	["Rainbow"] = {},
	["Spin"] = {},
	["Pulse"] = {},
	["Speed"] = {},
	["Bounce"] = {},
	["Kill"] = {},
	["Flicker"] = {},
	["Badge Giver"] = {},
	["Conveyor"] = {},
}

function SpinAxis(Axis: Vector3)
	return CFrame.Angles(
		math.rad(Axis.X),
		math.rad(Axis.Y),
		math.rad(Axis.Z)
	)
end

--Release
function AddHover(Inst: Instance, Data: {HoverSpeed: number, HoverDistance: number}?)
	if Inst:IsA("Model") then
		Data = Data or {
			HoverSpeed = Inst:GetAttribute("HoverSpeed") or 3,
			HoverDistance = Inst:GetAttribute("HoverDistance") or 3,
		}

		for i,v in Inst:GetChildren() do
			AddHover(v, Data)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Hover[Inst] = TweenService:Create(Inst, TweenInfo.new(Data and Data.HoverSpeed or Inst:GetAttribute("HoverSpeed") or 3, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true, 0.05), {CFrame = Inst.CFrame + Vector3.new(0,Data and Data.HoverDistance or Inst:GetAttribute("HoverDistance") or 3 ,0)})
		Connections.Hover[Inst]:Play()
	end
end

function RemoveHover(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveHover(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Hover[Inst]:Cancel()
		Connections.Hover[Inst]:Destroy()
	end
end

function AddRainbow(Inst: Instance, Data: {RainbowSpeed: number}?)
	if Inst:IsA("Model") then
		Data = Data or {
			RainbowSpeed = Inst:GetAttribute("RainbowSpeed") or 10,
		}

		for i,v in Inst:GetChildren() do
			AddRainbow(v, Data)
		end
	elseif Inst:IsA("BasePart") then
		local numvalue = Instance.new("NumberValue")
		Connections.Rainbow[Inst] = {}
		Connections.Rainbow[Inst].Tween = TweenService:Create(numvalue, TweenInfo.new(Data and Data.RainbowSpeed or Inst:GetAttribute("RainbowSpeed") or 10, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, false, 0), {Value = 1})
		Connections.Rainbow[Inst].Tween:Play()
		Connections.Rainbow[Inst].Completed = Connections.Rainbow[Inst].Tween.Completed:Connect(function(state)
			if state == Enum.PlaybackState.Cancelled then
				numvalue:Destroy()
			end
		end)
		Connections.Rainbow[Inst].Num = numvalue:GetPropertyChangedSignal("Value"):Connect(function()
			Inst.Color = Color3.fromHSV(numvalue.Value, 1, 1)
		end)
	end
end

function RemoveRainbow(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveRainbow(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Rainbow[Inst].Tween:Cancel()
		Connections.Rainbow[Inst].Completed:Disconnect()
		Connections.Rainbow[Inst].Num:Disconnect()
	end
end

function AddSpin(Inst: Instance)
	if Inst:IsA("Model") then
		Connections.Spin[Inst] = true
		spawn(function()
			while task.wait(Inst:GetAttribute("SpinSpeed") or .1) do
				Inst:PivotTo(Inst:GetPivot() * SpinAxis(Inst:GetAttribute("Axis") or Vector3.new(0, 1, 0)))
				if Connections.Spin[Inst] == false then
					break
				end
			end
		end)
	elseif Inst:IsA("BasePart") then
		Connections.Spin[Inst] = true
		spawn(function()
			while task.wait(Inst:GetAttribute("SpinSpeed") or .1) do
				Inst.CFrame *= SpinAxis(Inst:GetAttribute("Axis") or Vector3.new(0, 1, 0))
				if Connections.Spin[Inst] == false then
					break
				end
			end
		end)
	end
end

function RemoveSpin(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveSpin(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Spin[Inst] = false
	end
end

function AddPulse(Inst: Instance, Data: {PulseSpeed: number}?)
	if Inst:IsA("Model") then
		Data = Data or {
			PulseSpeed = Inst:GetAttribute("PulseSpeed") or 1,
		}

		for i,v in Inst:GetChildren() do
			AddPulse(v, Data)
		end
	elseif Inst:IsA("BasePart") then
		for _, Inst2 in Inst:GetDescendants() do
			if Inst2:IsA("Light") then
				Connections.Pulse[Inst2] = TweenService:Create(Inst2, TweenInfo.new(Data and Data.PulseSpeed or Inst:GetAttribute("PulseSpeed") or 1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1, true, 0), {Brightness = 0})
				Connections.Pulse[Inst2]:Play()
			end
		end
	end
end

function RemovePulse(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemovePulse(v)
		end
	elseif Inst:IsA("BasePart") then
		for _, Inst2 in Inst:GetDescendants() do
			if Inst2:IsA("Light") then
				Connections.Pulse[Inst2]:Cancel()
				Connections.Pulse[Inst2]:Destroy()
			end
		end
	end
end

--Update 1
local random = Random.new()
function RandomWaitFormVector2(vec: Vector2)
	task.wait(random:NextNumber(vec.X, vec.Y))
end

function RandomNumberFormVector2(vec: Vector2)
	return random:NextInteger(vec.X, vec.Y)
end

function AddSpeed(Inst: Instance, Data: {WalkSpeed: number}?)
	if Inst:IsA("Model") then
		Data = Data or {
			WalkSpeed = Inst:GetAttribute("WalkSpeed") or 1,
		}

		for i,v in Inst:GetChildren() do
			AddSpeed(v, Data)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Speed[Inst] = Inst.Touched:Connect(function(hit)
			local Player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if Player and Player.Character.Humanoid.Health > 0 then
				Player.Character.Humanoid.WalkSpeed = Data and Data.WalkSpeed or Inst:GetAttribute("WalkSpeed") or 16
			end
		end)
	end
end

function RemoveSpeed(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveSpeed(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Speed[Inst]:Disconnect()
	end
end

function AddBounce(Inst: Instance, Data: {BounceHeight: number, BounceSize: number}?)
	if Inst:IsA("Model") then
		Data = Data or {
			BounceHeight = Inst:GetAttribute("BounceHeight") or 1,
			BounceSize = Inst:GetAttribute("BounceSize") or 0.8,
		}

		for i,v in Inst:GetChildren() do
			AddBounce(v, Data)
		end
	elseif Inst:IsA("BasePart") then
		local deb = true
		local Size = Inst.Size * (Data and Data.BounceHeight or Inst:GetAttribute("BounceSize") or 0.8)
		Connections.Bounce[Inst] = Inst.Touched:Connect(function(hit)
			local Player = Players:GetPlayerFromCharacter(hit.Parent)
			if Player and Player.Character.Humanoid.Health > 0 and deb then
				deb = false
				Player.Character.Humanoid.JumpPower = Data and Data.BounceHeight or Inst:GetAttribute("BounceHeight") or 1
				Player.Character.Humanoid.JumpHeight = (Data and Data.BounceHeight or Inst:GetAttribute("BounceHeight") or 1) * 0.144
				Player.Character.Humanoid.Jump = true
				local tw = TweenService:Create(Inst, TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, 0, true), {Size = Size})
				tw:Play()
				spawn(function()
					task.wait(0.05)
					Player.Character.Humanoid.JumpHeight = game.StarterPlayer.CharacterJumpHeight
					Player.Character.Humanoid.JumpPower = game.StarterPlayer.CharacterJumpPower
				end)
				tw.Completed:Wait()
				deb = true
			end
		end)
	end
end

function RemoveBounce(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveBounce(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Bounce[Inst]:Disconnect()
	end
end

function AddKill(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			AddKill(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Kill[Inst] = Inst.Touched:Connect(function(hit)
			local Player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if Player and Player.Character.Humanoid.Health > 0 then
				Player.Character.Humanoid.Health = 0
			end
		end)
	end
end

function RemoveKill(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveKill(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Kill[Inst]:Disconnect()
	end
end

function AddFlicker(Inst: Instance, Data: {FlickerSpeed: number, RandomFlickerRepeatCount: Vector2, RandomFlickerWait: Vector2}?)
	if Inst:IsA("Model") then
		Data = Data or {
			FlickerSpeed = Inst:GetAttribute("FlickerSpeed") or 1,
			RandomFlickerRepeatCount = Inst:GetAttribute("RandomFlickerRepeatCount") or Vector2.new(1, 2),
			RandomFlickerWait = Inst:GetAttribute("RandomFlickerWait") or Vector2.new(1, 2),
		}

		for i,v in Inst:GetChildren() do
			AddFlicker(v, Data)
		end
	elseif Inst:IsA("BasePart") then
		for _, Inst2 in Inst:GetDescendants() do
			if Inst2:IsA("Light") then
				Connections.Flicker[Inst2] = true
				spawn(function()
					while Connections.Flicker[Inst2] == true do
						local tw = TweenService:Create(Inst2, TweenInfo.new(Data and Data.FlickerSpeed or Inst:GetAttribute("FlickerSpeed") or 1, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, RandomNumberFormVector2(Data and Data.RandomFlickerRepeatCount or Inst:GetAttribute("RandomFlickerRepeatCount") or Vector2.new(1,2)), true, 0), {Brightness = 0})
						tw:Play()
						tw.Completed:Wait()
						RandomWaitFormVector2(Data and Data.RandomFlickerRepeatCount or Inst:GetAttribute("RandomFlickerRepeatCount") or Vector2.new(1,2))
					end
				end)
			end
		end
	end
end

function RemoveFlicker(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveFlicker(v)
		end
	elseif Inst:IsA("BasePart") then
		for _, Inst2 in Inst:GetDescendants() do
			if Inst2:IsA("Light") then
				Connections.Flicker[Inst2] = false
			end
		end
	end
end

function AddBadge(Inst: Instance, Data: {BadgeId: number}?)
	if Inst:IsA("Model") then
		Data = Data or {
			BadgeId = Inst:GetAttribute("BadgeId") or 1,
		}
		for i,v in Inst:GetChildren() do
			AddBadge(v)
		end
	elseif Inst:IsA("BasePart") then
		local Id = (Data and Data.BadgeId or Inst:GetAttribute("BadgeId") or 0)
		Connections["Badge Giver"][Inst] = Inst.Touched:Connect(function(hit)
			local Player = game:GetService("Players"):GetPlayerFromCharacter(hit.Parent)
			if Player and Id > 0 and BadgeService:UserHasBadgeAsync(Player.UserId, Id) == false then
				BadgeService:AwardBadge(Player.UserId, Id)
			end
		end)
	end
end

function RemoveBadge(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveBadge(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections["Badge Giver"][Inst]:Disconnect()
	end
end

function AddConveyor(Inst: Instance, Data: {ConveyorSpeed: number}?)
	if Inst:IsA("Model") then
		Data = Data or {
			ConveyorSpeed = Inst:GetAttribute("ConveyorSpeed") or 5,
		}

		for i,v in Inst:GetChildren() do
			AddConveyor(v, Data)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Conveyor[Inst] = true
		spawn(function()
			while Connections.Conveyor[Inst] == true do
				task.wait()
				Inst.AssemblyLinearVelocity = Inst.CFrame.LookVector * (Data and Data.ConveyorSpeed or Inst:GetAttribute("ConveyorSpeed") or 5)
			end
		end)
	end
end

function RemoveConveyor(Inst: Instance)
	if Inst:IsA("Model") then
		for i,v in Inst:GetChildren() do
			RemoveConveyor(v)
		end
	elseif Inst:IsA("BasePart") then
		Connections.Conveyor[Inst] = false
		Inst.AssemblyLinearVelocity = Vector3.zero
	end
end

--

for _, inst in CollectionService:GetTagged("_Hover") do
	AddHover(inst)
end

for _, inst in CollectionService:GetTagged("_Rainbow") do
	AddRainbow(inst)
end

for _, inst in CollectionService:GetTagged("_Spin") do
	AddSpin(inst)
end

for _, inst in CollectionService:GetTagged("_Light Pulse") do
	AddPulse(inst)
end

for _, inst in CollectionService:GetTagged("_Speed") do
	AddSpeed(inst)
end

for _, inst in CollectionService:GetTagged("_Bounce") do
	AddBounce(inst)
end

for _, inst in CollectionService:GetTagged("_Kill") do
	AddKill(inst)
end

for _, inst in CollectionService:GetTagged("_Light Flicker") do
	AddFlicker(inst)
end

for _, inst in CollectionService:GetTagged("_Badge Giver") do
	AddBadge(inst)
end

for _, inst in CollectionService:GetTagged("_Conveyor") do
	AddConveyor(inst)
end

CollectionService:GetInstanceAddedSignal("_Hover"):Connect(AddHover)
CollectionService:GetInstanceRemovedSignal("_Hover"):Connect(RemoveHover)
CollectionService:GetInstanceAddedSignal("_Rainbow"):Connect(AddRainbow)
CollectionService:GetInstanceRemovedSignal("_Rainbow"):Connect(RemoveRainbow)
CollectionService:GetInstanceAddedSignal("_Spin"):Connect(AddSpin)
CollectionService:GetInstanceRemovedSignal("_Spin"):Connect(RemoveSpin)
CollectionService:GetInstanceAddedSignal("_Light Pulse"):Connect(AddPulse)
CollectionService:GetInstanceRemovedSignal("_Light Pulse"):Connect(RemovePulse)
CollectionService:GetInstanceAddedSignal("_Speed"):Connect(AddSpeed)
CollectionService:GetInstanceRemovedSignal("_Speed"):Connect(RemoveSpeed)
CollectionService:GetInstanceAddedSignal("_Bounce"):Connect(AddBounce)
CollectionService:GetInstanceRemovedSignal("_Bounce"):Connect(RemoveBounce)
CollectionService:GetInstanceAddedSignal("_Kill"):Connect(AddKill)
CollectionService:GetInstanceRemovedSignal("_Kill"):Connect(RemoveKill)
CollectionService:GetInstanceAddedSignal("_Light Flicker"):Connect(AddFlicker)
CollectionService:GetInstanceRemovedSignal("_Light Flicker"):Connect(RemoveFlicker)
CollectionService:GetInstanceAddedSignal("_Badge Giver"):Connect(AddBadge)
CollectionService:GetInstanceRemovedSignal("_Badge Giver"):Connect(RemoveBadge)
CollectionService:GetInstanceAddedSignal("_Conveyor"):Connect(AddConveyor)
CollectionService:GetInstanceRemovedSignal("_Conveyor"):Connect(RemoveConveyor)