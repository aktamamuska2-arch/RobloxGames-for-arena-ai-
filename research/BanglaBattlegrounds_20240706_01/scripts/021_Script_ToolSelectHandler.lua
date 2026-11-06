-- StarterGui/Inventory/Manager/Toolbar/ToolSelectHandler
local remote =  script.Parent

remote.OnServerEvent:Connect(function(plr,CurrentSlotEquipped,ToolForEquipping)
	local bp = plr.Backpack
	local char =  plr.Character


	if CurrentSlotEquipped == nil then
		for i,v in pairs(char:GetChildren())do
			if v:IsA("Tool")then
				v.Parent = bp
			end
		end
	else
		for i,v in pairs(char:GetChildren())do
			if v:IsA("Tool") and v~= ToolForEquipping then
				v.Parent = bp
			end
		end

		if ToolForEquipping ~= nil and ToolForEquipping ~= ""then
			if ToolForEquipping.Parent ==  bp then
				ToolForEquipping.Parent = char
			end
		end
	end	

end)