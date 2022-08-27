local environment = script.Parent
local grid = environment:WaitForChild("Grid")
local agentClass = require(script:WaitForChild("Agent"))

local directions = {"up", "right", "down", "left"}

local EPSILON_VALUE = 2 -- compares a random value between 0-1 and sees if it is below this value, managing rate of exploration vs exploitation
local DISCOUNT_FACTOR = 0.9
local LEARNING_RATE = 0.9

local MAX_X = 24 -- both 0 based
local MAX_Y = 24

--// Helper Funcs

function maxQ(x, y)
	local statePart = grid:FindFirstChild(x .. "," .. y)
	local maxQVal = -1000
	for i,v in pairs(statePart:GetChildren()) do
		if v:IsA("NumberValue") then
			if v.Value > maxQVal then
				maxQVal = v.Value
			end
		end
	end
	return maxQVal
end

---
-- Given two coords x and y returns whether or not the respective state
-- is an obstacle or the end goal (both terminal states).
-- @return boolean
function isTerminalState(x, y)
	local statePart = grid:FindFirstChild(x .. "," .. y)
	if not statePart then
		warn("Error: Out of bounds state called!")
	end
	
	local reward = statePart:GetAttribute("Reward")
	if reward == -100 or reward == 100 then -- uses the any given state's reward to determine if its a terminal state (goal = 100 | barrier = -100)
		return true
	end
	return false
end

---
-- Given a two numbers x and y, returns the action with the largest q value
-- with a small percent chance of choosing a random action.
-- @return number representing action to next take
function getNextAction(x, y)
	
	local statePart = grid:FindFirstChild(x .. "," .. y)
	if not statePart then
		warn("Error: Out of bounds state called!")
		return nil
	end
	
	local action
	local random = math.random(0, 1)
	
	if random < EPSILON_VALUE then -- exploitation vs exploration
		-- utilizing prior experience we are able to pick the "best" next move 
		local maxQVal = -1000
		for i,v in pairs(statePart:GetChildren()) do
			if v:IsA("NumberValue") then
				if v.Value > maxQVal then
					maxQVal = v.Value
					action = v:GetAttribute("Action") + 1 -- action index in part is 0-based while Lua tables are 1-based
				end
			end
		end
	else
		-- this still offers a way for us to go down an seemingly unfavorable route that may be the quickest
		action = math.random(1, 4)
	end
	
	return action
	
end

---
-- Takes in two numbers and an action and returns the point the player
-- would be on if said action was taken.
-- @returns two numbers
function getNextLocation(x, y, action)
	if action == 1 then
		x -= 1
	elseif action == 2 then
		y += 1
	elseif action == 3 then
		x += 1
	elseif action == 4 then
		y -= 1
	end
	return x, y
end

---
-- Given two numbers returns the shortest path on to the end goal of the maze. Assuming the environment has already
-- gone through its q learning episodes.
-- @return an array of parts
function calcShortestPath(x, y)
	if isTerminalState(x, y) then
		return {}
	end

	local shortestPath = {}
	local currX, currY = x, y

	table.insert(shortestPath, grid:FindFirstChild(x .. "," .. y))

	while not isTerminalState(currX, currY) do
		local action = getNextAction(currX, currY)
		currX, currY = getNextLocation(currX, currY, action)
		table.insert(shortestPath, grid:FindFirstChild(currX .. "," .. currY))
	end

	return shortestPath
end

--// Running 1000 Episodes

for i = 0, 1000 do
  
	local x,y = 23, 1
	local agent = agentClass.new(grid, x, y) -- initializes the NPC

	while(not isTerminalState(x, y)) do
		
		-- getting action to take
		local action = getNextAction(x, y)
		
		-- saving old location and moving to new location
		local oldX, oldY = x, y 	
		x,y = getNextLocation(x, y, action)
		
		-- get the part the player moved to and move to said part
		local statePart = grid:FindFirstChild(x .. "," .. y)
		agent:MoveTo(x, y)
		
		-- getting qVal from previous state
		local oldQ = grid:FindFirstChild(oldX .. "," .. oldY):FindFirstChild(directions[action])	
		
		-- get the reward we recieved for moving in said direction and calc new qVal to encourage or discourage use of said path
		local reward = statePart:GetAttribute("Reward")
		local temporalDifference = reward + (DISCOUNT_FACTOR * maxQ(x, y)) - oldQ.Value
		local newQVal = oldQ.Value + (LEARNING_RATE * temporalDifference) 
		oldQ.Value = newQVal
	end
	
	agent:Destroy()
	print("Episode #" .. i .. " completed.")
	wait(.5)
end

-- Getting shortest path
local shortestPath = calcShortestPath(23, 1)
-- Visualizing
for i,v in ipairs(shortestPath) do
	print(v.Name)
	v.Transparency = 0
	v.Color = Color3.fromRGB(255, 0, 4)
end
