local esplib = {};
esplib.enabled = false;
esplib.objs = {};

local cam = workspace.CurrentCamera;
local rs = game:GetService("RunService");
local lp = game:GetService("Players").LocalPlayer;
local chars = workspace:FindFirstChild("Characters");

local function create()
    local t = {};
    t.box = Drawing.new("Square");
    t.box.Thickness = 1;
    t.box.Filled = false;
    t.box.Color = Color3.new(1, 0.08, 0.08);
    
    t.name = Drawing.new("Text");
    t.name.Size = 13;
    t.name.Center = true;
    t.name.Outline = true;
    t.name.Color = Color3.new(1, 1, 1);
    
    t.hp = Drawing.new("Text");
    t.hp.Size = 12;
    t.hp.Center = true;
    t.hp.Outline = true;
    
    t.dist = Drawing.new("Text");
    t.dist.Size = 12;
    t.dist.Center = true;
    t.dist.Outline = true;
    t.dist.Color = Color3.new(1, 1, 1);
    
    t.ult = Drawing.new("Text");
    t.ult.Size = 12;
    t.ult.Center = true;
    t.ult.Outline = true;
    t.ult.Color = Color3.new(0, 0.5, 1);
    
    t.char = Drawing.new("Text");
    t.char.Size = 12;
    t.char.Center = true;
    t.char.Outline = true;
    t.char.Color = Color3.new(1, 0.5, 0);
    
    return t;
end;

local function hide(t)
    for _, d in t do d.Visible = false; end;
end;

local function remove(t)
    for _, d in t do d:Remove(); end;
end;

local function getbox(char)
    local hrp = char:FindFirstChild("HumanoidRootPart");
    if not hrp then return; end;
    local pos, vis = cam:WorldToViewportPoint(hrp.Position);
    if not vis then return; end;
    local dist = (cam.CFrame.Position - hrp.Position).Magnitude;
    local sz = 1800 / dist;
    local h = sz * 2;
    local w = sz;
    return Vector2.new(pos.X - w/2, pos.Y - h/2), Vector2.new(w, h), pos;
end;

local conn;
local lastupd = 0;

local function update()
    if not esplib.enabled then
        for _, t in esplib.objs do hide(t); end;
        return;
    end;
    
    local now = tick();
    if now - lastupd < 0.05 then return; end;
    lastupd = now;
    
    local lpc = lp.Character;
    local lphrp = lpc and lpc:FindFirstChild("HumanoidRootPart");
    local plrs = game:GetService("Players");
    
    local active = {};
    if chars then
        for _, char in chars:GetChildren() do
            if char ~= lpc then active[char] = true; end;
        end;
    end;
    
    for char, t in esplib.objs do
        if not active[char] then
            remove(t);
            esplib.objs[char] = nil;
        end;
    end;
    
    for char in active do
        if not esplib.objs[char] then
            esplib.objs[char] = create();
        end;
        
        local t = esplib.objs[char];
        local hum = char:FindFirstChild("Humanoid");
        local pos, sz, spos = getbox(char);
        
        if not pos or not hum then
            hide(t);
            continue;
        end;
        
        local boxen = Toggles.BoxESP and Toggles.BoxESP.Value;
        local nameen = Toggles.NameESP and Toggles.NameESP.Value;
        local hpen = Toggles.HealthESP and Toggles.HealthESP.Value;
        local disten = Toggles.DistESP and Toggles.DistESP.Value;
        local ulten = Toggles.UltESP and Toggles.UltESP.Value;
        local charen = Toggles.CharESP and Toggles.CharESP.Value;
        
        t.box.Visible = boxen;
        if boxen then
            t.box.Position = pos;
            t.box.Size = sz;
        end;
        
        local yoff = pos.Y - 16;
        
        t.name.Visible = nameen;
        if nameen then
            t.name.Text = char.Name;
            t.name.Position = Vector2.new(pos.X + sz.X/2, yoff);
            yoff = yoff - 14;
        end;
        
        t.hp.Visible = hpen;
        if hpen then
            local pct = hum.Health / hum.MaxHealth;
            t.hp.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth);
            t.hp.Color = Color3.new(1 - pct, pct, 0);
            t.hp.Position = Vector2.new(pos.X + sz.X/2, pos.Y + sz.Y + 2);
        end;
        
        t.dist.Visible = disten;
        if disten and lphrp then
            local hrp = char:FindFirstChild("HumanoidRootPart");
            if hrp then
                t.dist.Text = math.floor((lphrp.Position - hrp.Position).Magnitude) .. "m";
                t.dist.Position = Vector2.new(pos.X + sz.X/2, pos.Y + sz.Y + (hpen and 16 or 2));
            end;
        end;
        
        t.ult.Visible = ulten;
        if ulten then
            local plr = plrs:FindFirstChild(char.Name);
            local ultval = plr and plr:GetAttribute("Ultimate") or 0;
            t.ult.Text = "Ult: " .. math.floor(ultval) .. "%";
            t.ult.Position = Vector2.new(pos.X + sz.X/2, yoff);
            yoff = yoff - 14;
        end;
        
        t.char.Visible = charen;
        if charen then
            t.char.Text = char:GetAttribute("Moveset") or "?";
            t.char.Position = Vector2.new(pos.X + sz.X/2, yoff);
        end;
    end;
end;

function esplib:start()
    if conn then return; end;
    self.enabled = true;
    conn = rs.Heartbeat:Connect(update);
end;

function esplib:stop()
    self.enabled = false;
    if conn then conn:Disconnect(); conn = nil; end;
    for _, t in self.objs do remove(t); end;
    self.objs = {};
end;

getgenv().esplib = esplib;
