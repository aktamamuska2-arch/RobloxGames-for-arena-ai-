-- Workspace/StarterScene/Road_Intersection_01_A/Traffic_Light_01/LightStateChanger
-- 
local _interval = script.Parent:GetAttribute("interval") or 30

local _states = {
	"Green",
	"Yellow",
	"Red",
}

local _onPeriod = _interval * 0.5

local _stateLengths = {
	Green = _onPeriod * 0.9,
	Yellow = _onPeriod * 0.1,
	Red = _interval - _onPeriod,
}

local _lights
local _currentState
local _changeEvent = script:FindFirstChild("LightChanged")

local function getLights()
	local lights = {}
	
	local lightContainer = script.Parent:FindFirstChild("Lights")
	if not lightContainer then
		return lights
	end
	
	for _, light in ipairs(lightContainer:GetChildren()) do
		local stateName = light.Name
		local stateLights = lights[stateName] or {}
		lights[stateName] = stateLights
		
		local data = {
			obj = light,
			color = light.Color,
		}
		
		table.insert(stateLights, data)
	end
	
	return lights
end

local function getSignage()
	local signage = {}
	
	local signageContainer = script.Parent:FindFirstChild("Signage")
	if not signageContainer then
		return signage
	end
	
	for _, obj in ipairs(signageContainer:GetDescendants()) do
		if obj:IsA("TextLabel") then
			local container = obj.Parent.Parent
			local data = signage[container] or {}
			signage[container] = data
			
			data[obj.Name] = obj
		end
	end
	
	return signage
end

local function timeOffsetFromFacing(forward)
	local timeOffset = 0	
	local dot = forward:Dot(Vector3.new(0, 0, 1))

	if math.abs(dot) < 0.25 then
		timeOffset = _interval * 0.5
	else
		timeOffset = 0
	end

	return timeOffset
end

local function stateFromTime(globalTime, offset)
	local currentState
	
	local deltaTime = (globalTime + offset) % _interval
	
	for _, name in pairs(_states) do
		currentState = name
		deltaTime -= _stateLengths[name]
		
		if deltaTime < 0 then
			break
		end
	end
	
	return currentState, deltaTime
end
local function updateLightColors(activeState, lightGroups)
	-- Loop through all of the lights.  Change color luminance based on whether they're in the active state
	for state, lights in pairs(lightGroups) do
		local activeValue = 95/255.0
		if state == activeState then
			activeValue = 1.0
		end
		
		for _, lightData in ipairs(lights) do
			local h, s = lightData.color:ToHSV()
			lightData.obj.Color = Color3.fromHSV(h, s, activeValue) 
		end
	end
end

local function updateSignVisibility(globalTime, signage)
	for container, sign in pairs(signage) do
		local timeOffset = timeOffsetFromFacing(container.CFrame.LookVector)
		local state = stateFromTime(globalTime, timeOffset)
		
		local stop = state == 'Red'
		
		sign.Stop.Visible = stop
		sign.Walk.Visible = not stop
	end
end

local function updateState(globalTime, lights, signage)
	-- Determine new state
	-- If different than current, update lights and emit signal
	
	local timeOffset = timeOffsetFromFacing(script.Parent.PrimaryPart.CFrame.LookVector)
	
	local state, timeRemaining = stateFromTime(globalTime, timeOffset)
	updateLightColors(state, lights)
	
	if state ~= _currentState then
		_currentState = state
		_changeEvent:Fire(state)
	end
	
	--
	updateSignVisibility(globalTime, signage)
	
	return timeRemaining
end

-----------------------------------
_lights = getLights()
_signage = getSignage()

while true do
	local timeRemaining = updateState(tick(), _lights, _signage)
	wait(timeRemaining)
end
