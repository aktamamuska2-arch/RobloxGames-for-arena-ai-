-- StarterGui/Inventory/Manager
if game:GetService("UserInputService").TouchEnabled ~= true then
	game:GetService('StarterGui'):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

	local CurrentSlotEquipped = ""

	--< variables >--
	local uis = game:GetService("UserInputService")
	local player = game.Players.LocalPlayer
	local char = workspace:WaitForChild(player.Name) -- added WaitForChild
	local bp = player.Backpack
	local hum = char:WaitForChild("Humanoid")

	local frame = script.Parent:WaitForChild("Frame")
	local inventory = script.Parent:WaitForChild("Inventory")
	local ScrollFrame =  inventory.ImageLabel.ScrollingFrame

	frame.Visible = true

	--<Properties>--
	local equippedTransparency = 0
	local unequippedTrnasparency = .2

	local Dragging = false

	local ItemDragged  =  nil
	local PasteItem = nil

	local mouse =  player:GetMouse()
	local MouseGui = script.Parent:WaitForChild("Template")


	local OwnedTools = {}

	table.insert(OwnedTools,1,"")
	for i = 1,9 do
		table.insert(OwnedTools,#OwnedTools+1,"")
	end
	local function SelectToolGui(except,reset,NewTool)
		for i,v in pairs(frame:GetChildren())do
			if v:IsA("ImageButton") then
				v:FindFirstChild("Selected").Visible = false
				v.Transparency = unequippedTrnasparency
			end
		end

		for i,v in pairs(ScrollFrame:GetChildren())do
			if v:IsA("ImageButton")then
				v:FindFirstChild("Selected").Visible = false
			end
		end

		if reset then
			CurrentSlotEquipped = ""
		else
			if CurrentSlotEquipped ~= except then
				if except <= 9 then
					CurrentSlotEquipped = except
					script.Select:Play()
					local selectedPart = frame:FindFirstChild(tostring(except))
					selectedPart:FindFirstChild("Selected").Visible = true
					selectedPart.Transparency = equippedTransparency
				else
					CurrentSlotEquipped = except
					script.Select:Play()
					local selectedPart = ScrollFrame:WaitForChild(tostring(except))
					selectedPart:FindFirstChild("Selected").Visible = true
				end
			elseif CurrentSlotEquipped == except then
				CurrentSlotEquipped = ""
			end
		end
		if  NewTool ==  nil then
			local ToolForEquipping = OwnedTools[CurrentSlotEquipped]
			script.Toolbar:FireServer(CurrentSlotEquipped,ToolForEquipping)
		end
	end

	local function ToolAdded(child,parent)
		if child:IsA("Tool") and table.find(OwnedTools,child) ==  nil then

			if table.find(OwnedTools,"")then
				local emptySpot = table.find(OwnedTools,"")
				table.remove(OwnedTools,emptySpot)
				table.insert(OwnedTools,emptySpot,child)
				if parent == char then
					SelectToolGui(emptySpot,nil,true)
				end
			else
				table.insert(OwnedTools,#OwnedTools+1,child)
				if parent == char then
					SelectToolGui(#OwnedTools,nil,true)
				end
			end
		end
	end

	local function CheckForTools()
		for i,v in pairs(bp:GetChildren())do
			ToolAdded(v,bp)
		end

		for i,v in pairs(char:GetChildren())do
			ToolAdded(v,char)
		end
	end

	local function ToolParentChanged()
		for i,v in pairs(OwnedTools)do
			if v ~= "" then
				if v.Parent ~= char and v.Parent ~= bp then
					table.remove(OwnedTools,i)
					if ScrollFrame:FindFirstChild(tostring(i))then
						ScrollFrame:FindFirstChild(tostring(i)):Destroy()
					end
					table.insert(OwnedTools,i,"")
				end
			end
		end
	end

	for i,v in pairs(frame:GetChildren())do
		if v:IsA("ImageButton") then
			if v.Item.Value ~= nil then
				v.ToolName.Text = tostring(v.Item.Value)
			else
				v.ToolName.Text = ""
			end
		end
	end
	CheckForTools()

	for i,v in pairs(frame:GetChildren())do
		if v:IsA("ImageButton") then
			v.Item.Changed:Connect(function()
				if v.Item.Value ~= nil then
					v.ToolName.Text = tostring(v.Item.Value)
				else
					v.ToolName.Text = ""
				end
			end)
			v.MouseButton1Down:Connect(function()
				if v.Item.Value ~= nil then
					if inventory.Visible ==  false then
						SelectToolGui(tonumber(v.Name))
					end
				end
			end)
		end
	end

	uis.InputBegan:Connect(function(Input,GP)
		if (GP) then return end
		if(Input.KeyCode == Enum.KeyCode.One) and frame["1"].Item.Value ~= nil then
			SelectToolGui(1)
		elseif(Input.KeyCode == Enum.KeyCode.Two) and frame["2"].Item.Value ~= nil then
			SelectToolGui(2)
		elseif(Input.KeyCode == Enum.KeyCode.Three) and frame["3"].Item.Value ~= nil then
			SelectToolGui(3)
		elseif(Input.KeyCode == Enum.KeyCode.Four) and frame["4"].Item.Value ~= nil then	
			SelectToolGui(4)
		elseif(Input.KeyCode == Enum.KeyCode.Five) and frame["5"].Item.Value ~= nil then
			SelectToolGui(5)
		elseif(Input.KeyCode == Enum.KeyCode.Six) and frame["6"].Item.Value ~= nil then
			SelectToolGui(6)
		elseif(Input.KeyCode == Enum.KeyCode.Seven) and frame["7"].Item.Value ~= nil then
			SelectToolGui(7)
		elseif(Input.KeyCode == Enum.KeyCode.Eight) and frame["8"].Item.Value ~= nil then
			SelectToolGui(8)
		elseif(Input.KeyCode == Enum.KeyCode.Nine) and frame["9"].Item.Value ~= nil then
			SelectToolGui(9)
		elseif (Input.KeyCode == Enum.KeyCode.Backquote) then

			inventory.Visible = not inventory.Visible

			if inventory.Visible ==  true then
				script.Open:Play()
			end
		elseif (Input.KeyCode == Enum.KeyCode.Backspace) then
			SelectToolGui(1,"true")
		end
	end)

	char.ChildAdded:Connect(function(child)
		ToolAdded(child,char)
	end)

	bp.ChildAdded:Connect(function(child)
		ToolAdded(child,bp)
	end)


	local function upDateToolBar()
		for i,v in pairs(OwnedTools)do
			for a,b in pairs(frame:GetChildren())do
				if b.Name == tostring(i) then
					if v ~= "" then
						b.Item.Value = v
						b.ToolName.Text = v.Name
					else
						b.ToolName.Text = ""
						b.Item.Value = nil
					end
				end
			end
		end
	end


	local function CreateButtonForTool(i,v)
		local template =   inventory.ImageLabel.ScrollingFrame.Template

		local NewButton =  template:Clone()
		NewButton.Parent = template.Parent
		NewButton.Visible =  true
		NewButton.ToolName.Text = tostring(v.Name)
		NewButton.Name = tostring(i) 
		
		

		NewButton.MouseButton2Click:Connect(function()
			if table.find(OwnedTools,"")then
				local NewEmptySpot = table.find(OwnedTools,"")

				if NewEmptySpot < 10 then
					script.Switch:Play()
					table.remove(OwnedTools,NewEmptySpot)
					table.insert(OwnedTools,NewEmptySpot,v)
					table.remove(OwnedTools,i)
					table.insert(OwnedTools,i,"")
					NewButton:Destroy()
				end
			end
		end)


		local gui =  NewButton	

		gui.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and inventory.Visible == true and ItemDragged == nil and Dragging == false  then
				Dragging =  true
				gui.Visible = false

				ItemDragged = tonumber(gui.Name)
				MouseGui.Number.Text = ""
				MouseGui.ToolName.Text = gui.ToolName.Text
				MouseGui.Visible = true
			end
		end)		
		gui.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 and Dragging == true and ItemDragged == tonumber(gui.Name) then
				Dragging =  false
				gui.Visible = true
				gui:FindFirstChild("Selected").Visible =  false
				gui.Transparency = unequippedTrnasparency
				MouseGui.Visible = false

				if PasteItem ~= nil then

					if PasteItem ~= inventory then
						local PasteItemIndex = tonumber(PasteItem.Name)
						table.insert(OwnedTools,PasteItemIndex,OwnedTools[ItemDragged])
						table.remove(OwnedTools,ItemDragged+1)
						table.insert(OwnedTools,ItemDragged+1,OwnedTools[PasteItemIndex+1])
						table.remove(OwnedTools,PasteItemIndex+1)
						gui:Destroy()
					end
				end

				ItemDragged = nil
			end
		end)
	end


	inventory.MouseEnter:Connect(function()
		PasteItem = inventory
	end)

	inventory.MouseLeave:Connect(function()
		PasteItem = nil
	end)

	for i,gui in pairs(frame:GetChildren()) do
		if gui:IsA("ImageButton")then

			gui.MouseEnter:Connect(function()
				PasteItem = gui
			end)
			gui.MouseLeave:Connect(function()
				if PasteItem == gui then
					PasteItem = nil
				end
			end)
			
			gui.MouseButton2Click:Connect(function()
				if gui.Item.Value ~= nil and inventory.Visible == true then
					local guiPlace = tonumber(gui.Name)
					
					if OwnedTools[10] == ""then
						table.remove(OwnedTools,10)
						table.insert(OwnedTools,10,OwnedTools[guiPlace])
						
						if CurrentSlotEquipped == tonumber(gui.Name) then
							SelectToolGui(true,true)
						end


					elseif OwnedTools[10] ~= "" then
						local Once =  false
						for i,v in pairs(OwnedTools)do
							if i > 10 and Once == false then
								if v == "" then
									Once = true
									table.remove(OwnedTools,i)
									table.insert(OwnedTools,i,OwnedTools[guiPlace])	
									if CurrentSlotEquipped == tonumber(gui.Name) then
										SelectToolGui(true,true)
									end

									break
								end

							end
						end

						if Once == false then
							table.insert(OwnedTools,#OwnedTools+1,OwnedTools[guiPlace])
						end
					end
					table.remove(OwnedTools,guiPlace)
					table.insert(OwnedTools,guiPlace,"")
				end
			end)

			gui.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and inventory.Visible == true and ItemDragged == nil and Dragging == false and gui.Item.Value ~= nil then
					Dragging =  true
					gui.Visible = false

					ItemDragged = tonumber(gui.Name)
					MouseGui.Number.Text = gui.Number.Text
					MouseGui.ToolName.Text = gui.ToolName.Text
					MouseGui.Visible = true
				end
			end)		
			gui.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 and Dragging == true and ItemDragged == tonumber(gui.Name) then
					Dragging =  false
					gui.Visible = true
					gui:FindFirstChild("Selected").Visible =  false
					gui.Transparency = unequippedTrnasparency
					MouseGui.Visible = false

					if PasteItem ~= nil then
						if PasteItem == inventory then
							if OwnedTools[10] == ""then
								table.remove(OwnedTools,10)
								table.insert(OwnedTools,10,OwnedTools[ItemDragged])
								
								if CurrentSlotEquipped == tonumber(gui.Name) then
									SelectToolGui(true,true)
								end

							elseif OwnedTools[10] ~= "" then
								local Once =  false
								for i,v in pairs(OwnedTools)do
									if i > 10 and Once == false then
										if v == "" then
											Once = true
											table.remove(OwnedTools,i)
											table.insert(OwnedTools,i,OwnedTools[ItemDragged])
											if CurrentSlotEquipped == tonumber(gui.Name) then
												SelectToolGui(true,true)
											end
											break
										end

									end
								end

								if Once == false then
									table.insert(OwnedTools,#OwnedTools+1,OwnedTools[ItemDragged])
								end
							end
							table.remove(OwnedTools,ItemDragged)
							table.insert(OwnedTools,ItemDragged,"")
						else
							local PasteItemIndex = tonumber(PasteItem.Name)

							if ItemDragged < PasteItemIndex then
								table.insert(OwnedTools,PasteItemIndex,OwnedTools[ItemDragged])
								table.remove(OwnedTools,ItemDragged)
								table.insert(OwnedTools,ItemDragged,OwnedTools[PasteItemIndex])
								table.remove(OwnedTools,PasteItemIndex+1)
								if CurrentSlotEquipped == ItemDragged then
									SelectToolGui(PasteItemIndex,nil,true)
								end

							else
								table.insert(OwnedTools,PasteItemIndex,OwnedTools[ItemDragged])
								table.remove(OwnedTools,ItemDragged+1)
								table.insert(OwnedTools,ItemDragged+1,OwnedTools[PasteItemIndex+1])
								table.remove(OwnedTools,PasteItemIndex+1)
								if CurrentSlotEquipped == ItemDragged then
									SelectToolGui(PasteItemIndex,nil,true)
								end


							end

						end
					end

					ItemDragged = nil
				end
			end)
		end
	end


	local function DragGui()		
		script.Parent.Template.Position = UDim2.new(0,mouse.X - 10,0,mouse.Y + 30)
	end

	local function upDateInventory()
		for i,v in pairs(OwnedTools)do
			if  ScrollFrame:FindFirstChild(tostring(i)) ==  nil then
				if i>9 and v ~= "" then
					CreateButtonForTool(i,v)
				end
			else
				if v ~= ""then
					ScrollFrame:FindFirstChild(tostring(i)).ToolName.Text = v.Name
				else
					ScrollFrame:FindFirstChild(tostring(i)).ToolName.Text = ""
				end
			end
		end
	end
	game:GetService('RunService').Heartbeat:Connect(function()
		DragGui()
		ToolParentChanged()
		upDateToolBar()
		upDateInventory()

	end)

end
