-- StarterPlayer/StarterPlayerScripts/DisableControls
-- LocalScript in StarterPlayerScripts

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- Disable default controls
local function disableControls()
	local function disableAction(actionName, inputState, inputObject)
		return Enum.ContextActionResult.Sink
	end

	ContextActionService:BindAction("disableMovement", disableAction, false,
		Enum.PlayerActions.CharacterForward,
		Enum.PlayerActions.CharacterBackward,
		Enum.PlayerActions.CharacterLeft,
		Enum.PlayerActions.CharacterRight,
		Enum.PlayerActions.CharacterJump
	)
end

-- Set fixed camera
local function setFixedCamera()
	local cameraPart = workspace:WaitForChild("Cam1")
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = cameraPart.CFrame
end

-- Initialize
disableControls()
setFixedCamera()
