-- ReplicatedStorage/Models/GoldCoinPileMed/GoldCoinPileMed/CoinScript
local coin = script.Parent
local display = coin.Parent:FindFirstChild("Display")
local textLabel = display:FindFirstChild("BillboardGui"):FindFirstChild("TextLabel")

local function onTouched(otherPart)
	local character = otherPart.Parent
	local player = game.Players:GetPlayerFromCharacter(character)
	if player then
		local gtValue = player:FindFirstChild("GoldTokens") -- Assuming GoldTokens is an IntValue in the player's data
		if gtValue then
			local coinValue = tonumber(string.sub(textLabel.Text, 4))
			game.ReplicatedStorage.Events.MoneyUpdate:FireClient(player,"GT", coinValue, "gain")
			game.ReplicatedStorage.Events.PlayLocalSound:FireClient(player,"Coins") -- play the ka-ching sound
			coin:Destroy()
		end
	end
end

coin.Touched:Connect(onTouched)