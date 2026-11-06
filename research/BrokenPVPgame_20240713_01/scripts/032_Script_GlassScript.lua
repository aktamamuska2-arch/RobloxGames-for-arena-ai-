-- ReplicatedStorage/Maps/TestMap00/Map00 - DewanMukto/Barriers/Part/GlassScript
local part = script.Parent
local changeInterval = 5  -- Change interval in seconds

local function changeMaterial()
	while true do
		wait(changeInterval)
		if math.random(1, 10) == 1 then  -- 10% chance
			part.Material = Enum.Material.Glass
			part.Transparency = 0.8
		else
			part.Material = Enum.Material.Plastic
			part.Transparency = 0
		end
	end
end

changeMaterial()
