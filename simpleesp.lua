local cam = workspace.CurrentCamera;
local rs = game:GetService("RunService");
local lp = game:GetService("Players").LocalPlayer;
local charFolder = workspace:WaitForChild("Characters");

local esps = {};
local tracked = {};
local conn;

local lib = {
    enabled = true,
    box = {enabled = true, color = Color3.new(1, 0, 0), thickness = 1},
    name = {enabled = true, color = Color3.new(1, 1, 1), size = 13},
    dist = {enabled = true, color = Color3.new(0.8, 0.8, 0.8), size = 12},
    hp = {enabled = true},
    tracer = {enabled = true, color = Color3.new(1, 0, 0), thickness = 1}
};

local function getBox(char)
    local hrp = char:FindFirstChild("HumanoidRootPart");
    if not hrp then return end;
    
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge;
    local onScr = false;
    
    for _, p in next, char:GetChildren() do
        if not p:IsA("BasePart") then continue end;
        local cf, sz = p.CFrame, p.Size;
        local hx, hy, hz = sz.X/2, sz.Y/2, sz.Z/2;
        for x = -1, 1, 2 do
            for y = -1, 1, 2 do
                for z = -1, 1, 2 do
                    local pos, vis = cam:WorldToViewportPoint((cf * CFrame.new(hx*x, hy*y, hz*z)).Position);
                    if vis then
                        onScr = true;
                        if pos.X < minX then minX = pos.X end;
                        if pos.Y < minY then minY = pos.Y end;
                        if pos.X > maxX then maxX = pos.X end;
                        if pos.Y > maxY then maxY = pos.Y end;
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
    t.box.Filled = false;
    
    t.name = Drawing.new("Text");
    t.name.Center = true;
    t.name.Outline = true;
    
    t.dist = Drawing.new("Text");
    t.dist.Center = true;
    t.dist.Outline = true;
    
    t.hpBg = Drawing.new("Square");
    t.hpBg.Filled = true;
    t.hpBg.Color = Color3.new(0, 0, 0);
    
    t.hp = Drawing.new("Square");
    t.hp.Filled = true;
    
    t.tracer = Drawing.new("Line");
    
    return t;
end

local function setVis(t, v)
    for _, d in next, t do d.Visible = v end;
end

local function removeEsp(t)
    for _, d in next, t do d:Remove() end;
end

local function trackChar(char)
    local hum = char:FindFirstChildOfClass("Humanoid");
    if not hum then return end;
    if lp and lp.Character and char == lp.Character then return end;
    tracked[char] = hum;
    esps[char] = createEsp();
end

local function untrackChar(char)
    tracked[char] = nil;
    if esps[char] then
        removeEsp(esps[char]);
        esps[char] = nil;
    end
end

local function update()
    if not lib.enabled then
        for _, t in next, esps do setVis(t, false) end;
        return;
    end
    
    local vps = cam.ViewportSize;
    local myRoot = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart");
    
    for char, hum in next, tracked do
        local t = esps[char];
        if not t then continue end;
        
        local hrp = char:FindFirstChild("HumanoidRootPart");
        if not hrp or not char.Parent or hum.Health <= 0 then
            setVis(t, false);
            continue;
        end
        
        local pos, size = getBox(char);
        if not pos then
            setVis(t, false);
            continue;
        end
        
        t.box.Visible = lib.box.enabled;
        t.box.Position = pos;
        t.box.Size = size;
        t.box.Color = lib.box.color;
        t.box.Thickness = lib.box.thickness;
        
        t.name.Visible = lib.name.enabled;
        t.name.Text = char.Name;
        t.name.Position = Vector2.new(pos.X + size.X/2, pos.Y - 16);
        t.name.Color = lib.name.color;
        t.name.Size = lib.name.size;
        
        local dst = myRoot and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0;
        t.dist.Visible = lib.dist.enabled;
        t.dist.Text = "["..dst.."m]";
        t.dist.Position = Vector2.new(pos.X + size.X/2, pos.Y + size.Y + 2);
        t.dist.Color = lib.dist.color;
        t.dist.Size = lib.dist.size;
        
        local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1);
        local hpH = size.Y * hp;
        t.hpBg.Visible = lib.hp.enabled;
        t.hpBg.Position = Vector2.new(pos.X - 5, pos.Y);
        t.hpBg.Size = Vector2.new(3, size.Y);
        t.hp.Visible = lib.hp.enabled;
        t.hp.Position = Vector2.new(pos.X - 5, pos.Y + size.Y - hpH);
        t.hp.Size = Vector2.new(3, hpH);
        t.hp.Color = Color3.new(1 - hp, hp, 0);
        
        t.tracer.Visible = lib.tracer.enabled;
        t.tracer.From = Vector2.new(vps.X/2, vps.Y);
        t.tracer.To = Vector2.new(pos.X + size.X/2, pos.Y + size.Y);
        t.tracer.Color = lib.tracer.color;
        t.tracer.Thickness = lib.tracer.thickness;
    end
end

for _, c in next, charFolder:GetChildren() do trackChar(c) end;
charFolder.ChildAdded:Connect(trackChar);
charFolder.ChildRemoved:Connect(untrackChar);

conn = rs.RenderStepped:Connect(update);

function lib:stop()
    conn:Disconnect();
    for _, t in next, esps do removeEsp(t) end;
    esps = {};
    tracked = {};
end

function lib:refresh()
    for _, c in next, charFolder:GetChildren() do
        if not tracked[c] then trackChar(c) end;
    end
end

return lib;
