-- ReplicatedStorage/Assistant/HurtScript
Humanoid = script.Parent:WaitForChild("Humanoid")
Sound = Humanoid.Parent.Head:WaitForChild("Hurt")
CurrentHealth = Humanoid.Health

function HealthChanged(Health)
	local Change = math.abs(CurrentHealth - Health)
	if CurrentHealth > Health then
		Sound.Pitch = 1 + (math.random()*0.1)
		Sound:Play()
		if CurrentHealth > 0 then
			if not (CurrentHealth <= 0) then
				--script.Parent.DelayToStealth.Value = 5
			end
		end
	end
	CurrentHealth = Humanoid.Health
end

Humanoid.HealthChanged:connect(HealthChanged)