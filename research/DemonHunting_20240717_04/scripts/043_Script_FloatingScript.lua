-- ServerStorage/Landscaping Pack/Rocks|Bricks/Rock_Pillars_Medium_floating/Rock_Pillars_Medium/FloatingScript
while true do
	wait(0.4)
	local v = script.Parent.Position
	for i = 2,10 do
		wait(0.1)
		script.Parent.Position = script.Parent.Position + Vector3.new (0,i/140,0)
	end
	for i = 8,2,-2 do
		wait(0.2)
		script.Parent.Position = script.Parent.Position + Vector3.new(0,i/140,0)
	end
	for i = 2,10 do
		wait(0.1)
		script.Parent.Position = script.Parent.Position + Vector3.new(0,-i/140,0)
	end
	for i = 8,2,-2 do
		wait(0.2)
		script.Parent.Position = script.Parent.Position + Vector3.new(0,-i/140,0)
	end
	script.Parent.Position = v
end