-- StarterGui/LoadingScreenGui/ShowStartMenu
game.ReplicatedStorage.Events.MenuCutscene.OnServerEvent:Connect(function(player)
	game.ReplicatedStorage.Events.MenuCutscene:FireClient(player)
end)