local esp = {};
esp.enabled = false;
esp.settings = {
    box = true,
    name = true,
    dist = true,
    hp = true,
    tracer = true,
    boxColor = Color3.new(1, 0, 0),
    nameColor = Color3.new(1, 1, 1),
    distColor = Color3.new(0.8, 0.8, 0.8),
    tracerColor = Color3.new(1, 0, 0),
    textSize = 13
};

local cam = workspace.CurrentCamera;
local rs = game:GetService("RunService");
local lp = game:GetService("Players").LocalPlayer;
local vps = cam.ViewportSize;
local esps = {};
local conn;

local function getBox(char)
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge;
    local onScr = false;
    for _, p in next, char:GetDescendants() do
        if p:IsA("BasePart") then
            for x = -1, 1, 2 do
                for y = -1, 1, 2 do
                    for z = -1, 1, 2 do
                        local corner = (p.CFrame * CFrame.new(p.Size.X/2*x, p.Size.Y/2*y, p.Size.Z/2*z)).Position;
                        local pos, vis = cam:WorldToViewportPoint(corner);
                        if vis then
                            onScr = true;
                            minX, minY = math.min(minX, pos.X), math.min(minY, pos.Y);
                            maxX, maxY = math.max(maxX, pos.X), math.max(maxY, pos.Y);
                        end
                    end
                end
            end
        end
    end
    if onScr then return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY) end;
end

local function createEsp()
    local t = {};
    t.box = Drawing.new("Square");
    t.box.Thickness = 1;
    t.box.Filled = false;
    
    t.name = Drawing.new("Text");
    t.name.Size = esp.settings.textSize;
    t.name.Center = true;
    t.name.Outline = true;
    
    t.dist = Drawing.new("Text");
    t.dist.Size = esp.settings.textSize - 1;
    t.dist.Center = true;
    t.dist.Outline = true;
    
    t.hpBg = Drawing.new("Square");
    t.hpBg.Filled = true;
    t.hpBg.Color = Color3.new(0, 0, 0);
    
    t.hp = Drawing.new("Square");
    t.hp.Filled = true;
    
    t.tracer = Drawing.new("Line");
    t.tracer.Thickness = 1;
    
    return t;
end

local function removeEsp(t)
    for _, d in next, t do d:Remove() end;
end

local function update()
    if not esp.enabled then return end;
    vps = cam.ViewportSize;
    local chars = {};
    
    for _, v in next, workspace:GetDescendants() do
        if v:IsA("Humanoid") and v.Parent and v.Parent:FindFirstChild("HumanoidRootPart") then
            if v.Parent ~= (lp and lp.Character) then
                chars[v.Parent] = v;
            end
        end
    end
    
    for char, t in next, esps do
        if not chars[char] or not char.Parent then
            removeEsp(t);
            esps[char] = nil;
        end
    end
    
    local root = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart");
    local s = esp.settings;
    
    for char, hum in next, chars do
        if not esps[char] then esps[char] = createEsp() end;
        local t = esps[char];
        local hrp = char:FindFirstChild("HumanoidRootPart");
        local pos, size = getBox(char);
        
        if pos and hrp then
            t.box.Visible = s.box;
            t.box.Position = pos;
            t.box.Size = size;
            t.box.Color = s.boxColor;
            
            t.name.Visible = s.name;
            t.name.Text = char.Name;
            t.name.Position = Vector2.new(pos.X + size.X/2, pos.Y - 16);
            t.name.Color = s.nameColor;
            
            local dst = root and math.floor((root.Position - hrp.Position).Magnitude) or 0;
            t.dist.Visible = s.dist;
            t.dist.Text = "["..dst.."m]";
            t.dist.Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y + 2);
            t.dist.Color = s.distColor;
            
            local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1);
            local hpH = size.Y * hpPct;
            t.hpBg.Visible = s.hp;
            t.hpBg.Position = Vector2.new(pos.X - 5, pos.Y);
            t.hpBg.Size = Vector2.new(3, size.Y);
            t.hp.Visible = s.hp;
            t.hp.Position = Vector2.new(pos.X - 5, pos.Y + size.Y - hpH);
            t.hp.Size = Vector2.new(3, hpH);
            t.hp.Color = Color3.new(1 - hpPct, hpPct, 0);
            
            t.tracer.Visible = s.tracer;
            t.tracer.From = Vector2.new(vps.X/2, vps.Y);
            t.tracer.To = Vector2.new(pos.X + size.X/2, pos.Y + size.Y);
            t.tracer.Color = s.tracerColor;
        else
            for _, d in next, t do d.Visible = false end;
        end
    end
end

function esp:start()
    if conn then return end;
    self.enabled = true;
    conn = rs.RenderStepped:Connect(update);
end

function esp:stop()
    self.enabled = false;
    if conn then conn:Disconnect(); conn = nil end;
    for _, t in next, esps do removeEsp(t) end;
    esps = {};
end

function esp:toggle()
    if self.enabled then self:stop() else self:start() end;
end

function esp:setColor(element, color)
    local map = {box = "boxColor", name = "nameColor", dist = "distColor", tracer = "tracerColor"};
    if map[element] then self.settings[map[element]] = color end;
end

function esp:setEnabled(element, state)
    if self.settings[element] ~= nil then self.settings[element] = state end;
end

getgenv().esp = esp;
return esp;
