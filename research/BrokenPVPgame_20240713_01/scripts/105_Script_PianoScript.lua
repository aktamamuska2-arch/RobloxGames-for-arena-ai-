-- ServerStorage/Intro/Building/Upright Piano/PianoScript
local seat = script.Parent.Bench.Seat
local sheetMusic = script.Parent.Piano.SheetMusic
local occupant = nil
local tune = nil
local oldTune = nil
local animation = nil
local r6Anim = script.PlayingR6
local r15Anim = script.PlayingR15

tunes = {
	"rbxassetid://1835519330",
}

seat.ChildAdded:Connect(function(obj)
	if obj.Name == "SeatWeld" then
		local player = game.Players:GetPlayerFromCharacter(obj.Part1.Parent)
		if player then
			local hum = player.Character:FindFirstChild("Humanoid")
			occupant = obj.Part1.Parent
			if hum.RigType == Enum.HumanoidRigType.R6 then
				animation = hum:LoadAnimation(r6Anim)
			else
				animation = hum:LoadAnimation(r15Anim)
			end
			animation:Play()
		end
	end
end)

seat.ChildRemoved:Connect(function(obj)
	if obj.Name == "SeatWeld" then
		local player = game.Players:GetPlayerFromCharacter(obj.Part1.Parent)
		if player then
			animation:Stop()
			occupant = nil
			sheetMusic.Sound:Stop()
		end
	end
end)

while wait(0.1) do
	if occupant ~= nil then
		repeat
			tune = tunes[math.random(1, #tunes)]
		until tune ~= oldTune
		oldTune = tune
		sheetMusic.Sound.SoundId = tune	
		sheetMusic.Sound:Play()
		repeat
			wait()
		until not sheetMusic.Sound.Playing
	end
end