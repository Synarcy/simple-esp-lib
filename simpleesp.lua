local cam = workspace.CurrentCamera;
local rs = game:GetService("RunService");
local plrs = game:GetService("Players");
local lp = plrs.LocalPlayer;
local charFolder = workspace:WaitForChild("Characters");

local esps = {};
local tracked = {};
local conn;

local lib = {
    enabled = true,
    box = {enabled = true, color = Color3.new(1, 0, 0), thickness = 1},
    name = {enabled = true, color = Color3.new(1, 1, 1), size = 13},
    health = {enabled = true, size = 12},
    dist = {enabled = true, color = Color3.new(0.8, 0.8, 0.8), size = 12},
    ult = {enabled = false, color = Color3.new(0, 0.5, 1), size = 12},
    moveset = {enabled = false, color = Color3.new(1, 0.5, 0), size = 12},
    tracer = {enabled = true, color = Color3.new(1, 0, 0), thickness = 1},
    lock = {enabled = false, color = Color3.new(0, 0.5, 1)},
    locktarget = nil,
};

local function getBox(char)
    local hrp = char:FindFirstChild("HumanoidRootPart");
    if not hrp then return end;
    local head = char:FindFirstChild("Head");

    local top = head and head.Position + Vector3.new(0, 0.5, 0) or hrp.Position + Vector3.new(0, 2.5, 0);
    local bot = hrp.Position - Vector3.new(0, 3, 0);

    local tpos, tvis = cam:WorldToViewportPoint(top);
    local bpos, bvis = cam:WorldToViewportPoint(bot);

    if not tvis and not bvis then return end;

    local h = math.abs(bpos.Y - tpos.Y);
    local w = h * 0.6;
    local cx = (tpos.X + bpos.X) / 2;

    return Vector2.new(cx - w/2, tpos.Y), Vector2.new(w, h);
end

local function createEsp()
    local t = {};
    t.box = Drawing.new("Square");
    t.box.Filled = false;

    t.name = Drawing.new("Text");
    t.name.Center = true;
    t.name.Outline = true;

    t.health = Drawing.new("Text");
    t.health.Center = true;
    t.health.Outline = true;

    t.dist = Drawing.new("Text");
    t.dist.Center = true;
    t.dist.Outline = true;

    t.ult = Drawing.new("Text");
    t.ult.Center = true;
    t.ult.Outline = true;

    t.moveset = Drawing.new("Text");
    t.moveset.Center = true;
    t.moveset.Outline = true;

    t.hpBg = Drawing.new("Square");
    t.hpBg.Filled = true;
    t.hpBg.Color = Color3.new(0, 0, 0);

    t.hp = Drawing.new("Square");
    t.hp.Filled = true;

    t.tracer = Drawing.new("Line");

    return t;
end

local function setVis(t, v)
    for _, d in next, t do d.Visible = v; end;
end

local function removeEsp(t)
    for _, d in next, t do d:Remove(); end;
end

local function trackChar(char)
    local hum = char:FindFirstChildOfClass("Humanoid");
    if not hum then return end;
    if lp and lp.Character and char == lp.Character then return end;
    tracked[char] = {hum = hum, plr = plrs:FindFirstChild(char.Name)};
    esps[char] = createEsp();
end

local function untrackChar(char)
    tracked[char] = nil;
    if esps[char] then
        removeEsp(esps[char]);
        esps[char] = nil;
    end;
end

local function update()
    if not lib.enabled then
        for _, t in next, esps do setVis(t, false) end;
        return;
    end

    local vps = cam.ViewportSize;
    local myRoot = lp and lp.Character and lp.Character:FindFirstChild("HumanoidRootPart");

    for char, data in next, tracked do
        local t = esps[char];
        if not t then continue end;

        local hum = data.hum;
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

        local islocked = lib.lock.enabled and lib.locktarget == char;
        local boxcol = islocked and lib.lock.color or lib.box.color;

        t.box.Visible = lib.box.enabled or islocked;
        t.box.Position = pos;
        t.box.Size = size;
        t.box.Color = boxcol;
        t.box.Thickness = lib.box.thickness;

        local yoff = pos.Y - 16;

        t.name.Visible = lib.name.enabled;
        t.name.Text = char.Name;
        t.name.Position = Vector2.new(pos.X + size.X/2, yoff);
        t.name.Color = lib.name.color;
        t.name.Size = lib.name.size;
        if lib.name.enabled then yoff = yoff - 14; end;

        if lib.moveset.enabled then
            local ms = char:GetAttribute("Moveset") or "Unknown";
            t.moveset.Visible = true;
            t.moveset.Text = ms;
            t.moveset.Position = Vector2.new(pos.X + size.X/2, yoff);
            t.moveset.Color = lib.moveset.color;
            t.moveset.Size = lib.moveset.size;
            yoff = yoff - 14;
        else
            t.moveset.Visible = false;
        end

        local botY = pos.Y + size.Y + 2;

        if lib.health.enabled then
            local hp = math.floor(hum.Health);
            local maxhp = math.floor(hum.MaxHealth);
            local pct = hum.Health / hum.MaxHealth;
            t.health.Visible = true;
            t.health.Text = hp .. "/" .. maxhp;
            t.health.Position = Vector2.new(pos.X + size.X/2, botY);
            t.health.Color = Color3.new(1 - pct, pct, 0);
            t.health.Size = lib.health.size;
            botY = botY + 14;
        else
            t.health.Visible = false;
        end

        local dst = myRoot and math.floor((myRoot.Position - hrp.Position).Magnitude) or 0;
        t.dist.Visible = lib.dist.enabled;
        t.dist.Text = dst .. " studs";
        t.dist.Position = Vector2.new(pos.X + size.X/2, botY);
        t.dist.Color = lib.dist.color;
        t.dist.Size = lib.dist.size;
        if lib.dist.enabled then botY = botY + 14; end;

        if lib.ult.enabled then
            local ultval = data.plr and data.plr:GetAttribute("Ultimate") or 0;
            t.ult.Visible = true;
            t.ult.Text = "Ult: " .. math.floor(ultval) .. "%";
            t.ult.Position = Vector2.new(pos.X + size.X/2, botY);
            t.ult.Color = lib.ult.color;
            t.ult.Size = lib.ult.size;
        else
            t.ult.Visible = false;
        end

        local hpPct = math.clamp(hum.Health / hum.MaxHealth, 0, 1);
        local hpH = size.Y * hpPct;
        t.hpBg.Visible = lib.health.enabled;
        t.hpBg.Position = Vector2.new(pos.X - 5, pos.Y);
        t.hpBg.Size = Vector2.new(3, size.Y);
        t.hp.Visible = lib.health.enabled;
        t.hp.Position = Vector2.new(pos.X - 5, pos.Y + size.Y - hpH);
        t.hp.Size = Vector2.new(3, hpH);
        t.hp.Color = Color3.new(1 - hpPct, hpPct, 0);

        t.tracer.Visible = lib.tracer.enabled;
        t.tracer.From = Vector2.new(vps.X/2, vps.Y);
        t.tracer.To = Vector2.new(pos.X + size.X/2, pos.Y + size.Y);
        t.tracer.Color = islocked and lib.lock.color or lib.tracer.color;
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

function lib:setLock(char)
    lib.locktarget = char;
end

return lib;
