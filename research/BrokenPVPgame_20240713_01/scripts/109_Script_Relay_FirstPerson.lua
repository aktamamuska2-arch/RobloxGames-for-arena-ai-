-- ServerScriptService/Relays/Relay_FirstPerson
game.ReplicatedStorage.Events.FirstPerson.OnServerEvent:Connect(function(player)
	game.ReplicatedStorage.Events.FirstPerson:FireClient(player)
end)