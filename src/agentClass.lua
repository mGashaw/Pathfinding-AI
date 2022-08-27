local AgentClass = {}
AgentClass.__index = AgentClass

function AgentClass.new(grid, startX, startY)
    
    local self = setmetatable({
        environment = grid;
        char = script.Larry:Clone();
    }, AgentClass)
    
    local part = grid:FindFirstChild(startX .. "," .. startY)
    self.char.HumanoidRootPart.CFrame = part.CFrame * CFrame.new(0, 1, 0)
    self.char.Parent = workspace

    return self
end

function AgentClass:MoveTo(x, y)
    local nextPart = self.environment:FindFirstChild(x .. "," .. y)
    self.char.Humanoid:MoveTo(nextPart.Position, nextPart)
    wait(.3)
end

function AgentClass:Destroy()
    self.char:Destroy()
    setmetatable(self, nil)
end

return AgentClass
