-- ServerScriptService/AnimScript
-- Script in ServerScriptService

local npc = workspace:WaitForChild("Narkuzu") -- Change "NPC" to the name of your NPC
local humanoid = npc:WaitForChild("Humanoid")

local animation = Instance.new("Animation")
animation.AnimationId = "rbxassetid://18535422188"

local animationTrack = humanoid:LoadAnimation(animation)

animationTrack:Play()
animationTrack.Looped = true
