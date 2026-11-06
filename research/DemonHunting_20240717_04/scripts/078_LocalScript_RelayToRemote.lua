-- StarterGui/RelayToRemote
game.ReplicatedStorage.Events.MoneyUpdate.OnClientEvent:Connect(function(player, currency, amount, reason)
	game.ReplicatedStorage.Events.MoneyUpdate:FireServer(player, currency, amount, reason)
end)
game.ReplicatedStorage.Events.InvAddTool.OnClientEvent:Connect(function(player, tool)
	game.ReplicatedStorage.Events.InvAddTool:FireServer(player, tool)
end)