-- StarterPlayer/StarterPlayerScripts/Shop
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
if player then
	local gui = player:WaitForChild("PlayerGui"):WaitForChild("ShopGui")
	local frame = gui.Frame.ShopFrame

	-- Ensure the elements are found in the GUI
	if frame then
		-- Gamepass Items
		frame.rocket.MouseButton1Click:Connect(function()
			print("Clicked on Rocket")
			local success, errorText = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, 842608271)
			end)
			if not success then
				warn("Error purchasing Rocket gamepass:", errorText)
			end
		end)

		frame.flashbang.MouseButton1Click:Connect(function()
			print("Clicked on Flashbang")
			local success, errorText = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, 842571373)
			end)
			if not success then
				warn("Error purchasing Flashbang gamepass:", errorText)
			end
		end)

		frame.car.MouseButton1Click:Connect(function()
			print("Clicked on Car")
			local success, errorText = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, 842368672)
			end)
			if not success then
				warn("Error purchasing Car gamepass:", errorText)
			end
		end)

		frame.helicopter.MouseButton1Click:Connect(function()
			print("Clicked on Helicopter")
			local success, errorText = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, 846687740)
			end)
			if not success then
				warn("Error purchasing Helicopter gamepass:", errorText)
			end
		end)

		frame.invisible.MouseButton1Click:Connect(function()
			print("Clicked on Invisible")
			local success, errorText = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, 847458575)
			end)
			if not success then
				warn("Error purchasing Invisible gamepass:", errorText)
			end
		end)

		frame.vip.MouseButton1Click:Connect(function()
			print("Clicked on VIP")
			local success, errorText = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, 842348739)
			end)
			if not success then
				warn("Error purchasing VIP gamepass:", errorText)
			end
		end)

		frame.asval.MouseButton1Click:Connect(function()
			print("Clicked on ASVAL")
			local success, errorText = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, 847597301)
			end)
			if not success then
				warn("Error purchasing ASVAL gamepass:", errorText)
			end
		end)
		
		frame.scar.MouseButton1Click:Connect(function()
			print("Clicked on SCAR")
			local success, errorText = pcall(function()
				MarketplaceService:PromptGamePassPurchase(player, 848038634)
			end)
			if not success then
				warn("Error purchasing SCAR gamepass:", errorText)
			end
		end)
	else
		warn("Frame or ShopFrame not found in ShopGui")
	end
else
	warn("LocalPlayer not found")
end
