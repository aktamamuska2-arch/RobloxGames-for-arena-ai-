-- ServerScriptService/MainScripts/RedeemCodes
-- Reference to DataStore
local DataStoreService = game:GetService("DataStoreService")
local redeemedCodesStore = DataStoreService:GetDataStore("RedeemedCodes")

-- Sample codes and their corresponding actions
local codeActions = {
	ANAKIN = function(player)
		game.ReplicatedStorage.Events.InvAddTool:FireClient(player, game.ReplicatedStorage.Weapons.Katana.FutureKatana)
		return "Received Future Katana!"
	end,
	BADGLITCH = function(player)
		game.ReplicatedStorage.Events.InvAddTool:FireClient(player, game.ReplicatedStorage.Tools.Wallet)
		game.ReplicatedStorage.Events.InvAddTool:FireClient(player, game.ReplicatedStorage.Tools.Martial)
		return "Received basic items!"
	end,
	DEWAN2 = function(player)
		game.ReplicatedStorage.Events.InvAddTool:FireClient(player, game.ReplicatedStorage.Weapons.Spear.CursedSpear)
		return "Received Cursed Spear!"
	end,
	DEWAN = function(player)
		game.ReplicatedStorage.Events.InvAddTool:FireClient(player, game.ReplicatedStorage.Weapons.Spear.CursedSpear)
		return "Received Cursed Spear!"
	end,
	OOGABOOGA = function(player)
		game.ReplicatedStorage.Events.InvAddTool:FireClient(player, game.ReplicatedStorage.Weapons.Spear.StoneSpear)
		return "Received Stone Spear!"
	end,
	DIVINITY = function(player)
		game.ReplicatedStorage.Events.InvAddTool:FireClient(player, game.ReplicatedStorage.Weapons.Sword.HolySword)
		return "Received Holy Sword!"
	end,
	["40VISITS"] = function(player)
		game.ReplicatedStorage.Events.MoneyUpdate:FireClient(player, "GT", 1000, "gain")
		return "Received GT 1000!"
	end,
	["HOWTHEHECK"] = function(player)
		game.ReplicatedStorage.Events.MoneyUpdate:FireClient(player, "GT", 1000000, "gain")
		return "Received GT 1000000!"
	end,
	["123ABC"] = function(player)
		-- Kill the player
		player:LoadCharacter()
		return "You have been killed!"
	end
}

-- Event to handle code redemption
local function redeemCode(player, code)
	-- Check if the code has already been redeemed by this player
	local success, alreadyRedeemed = pcall(function()
		return redeemedCodesStore:GetAsync(player.UserId .. "_" .. code)
	end)

	if success then
		if alreadyRedeemed then
			return "Already redeemed!"
		else
			-- Mark the code as redeemed for this player
			redeemedCodesStore:SetAsync(player.UserId .. "_" .. code, true)

			-- Execute the action associated with the code
			local action = codeActions[code]
			if action then
				return action(player)
			else
				return "Code redeemed, but no action specified!"
			end
		end
	else
		return "Code doesn't exist!"
	end
end

-- Event handler for redeeming codes
game:GetService("ReplicatedStorage").Events.RedeemCode.OnServerEvent:Connect(function(player, code)
	-- Check if the entered code is valid
	local isValidCode = codeActions[code] ~= nil

	if isValidCode then
		local result = redeemCode(player, code)
		game:GetService("ReplicatedStorage").Events.RedeemCodeResult:FireClient(player, result)
	else
		game:GetService("ReplicatedStorage").Events.RedeemCodeResult:FireClient(player, "Code doesn't exist!")
	end
end)
