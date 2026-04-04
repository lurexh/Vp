-- ╔══════════════════════════════════════════════════════╗
-- ║         Horizon v0.1.1 — Vape V4 Style              ║
-- ║         BedWars Edition  |  By: You (Legacy of 7GD) ║
-- ╚══════════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local UIS              = game:GetService("UserInputService")
local RS               = game:GetService("RunService")
local TS               = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local RunService       = game:GetService("RunService")

local LP      = Players.LocalPlayer
local Mouse   = LP:GetMouse()
local Cam     = workspace.CurrentCamera

-- ══════════════════════════════════════════
-- EXECUTOR DETECTION
-- ══════════════════════════════════════════
local Executor = "Unknown"
pcall(function()
    if KRNL_LOADED or krnl then Executor = "KRNL"
    elseif syn and syn.protect_gui then Executor = "Synapse X"
    elseif DELTA_LOADED or delta then Executor = "Delta"
    elseif FLUXUS_LOADED or fluxus then Executor = "Fluxus"
    elseif WAVE_LOADED or wave then Executor = "Wave"
    elseif ELECTRON_LOADED or electron then Executor = "Electron"
    elseif identifyexecutor then Executor = identifyexecutor()
    end
end)

-- ══════════════════════════════════════════
-- PROFILE SYSTEM (auto-save via writefile)
-- ══════════════════════════════════════════
local SAVE_PATH   = "horizon_profiles/"
local PROF_ACTIVE = "Default"

local function ensureFolder()
    pcall(function()
        if not isfolder(SAVE_PATH) then makefolder(SAVE_PATH) end
    end)
end

local function saveProfile(name, data)
    pcall(function()
        ensureFolder()
        writefile(SAVE_PATH .. name .. ".json", HttpService:JSONEncode(data))
    end)
end

local function loadProfile(name)
    local ok, result = pcall(function()
        if isfile(SAVE_PATH .. name .. ".json") then
            return HttpService:JSONDecode(readfile(SAVE_PATH .. name .. ".json"))
        end
    end)
    return ok and result or nil
end

local function listProfiles()
    local list = {"Default"}
    pcall(function()
        ensureFolder()
        for _, f in ipairs(listfiles(SAVE_PATH)) do
            local n = f:gsub(SAVE_PATH, ""):gsub(".json", "")
            if n ~= "Default" then table.insert(list, n) end
        end
    end)
    return list
end

-- ══════════════════════════════════════════
-- MODULE STATE
-- ══════════════════════════════════════════
local Modules = {
    -- Combat
    KillAura       = { enabled=false, bind=Enum.KeyCode.K, settings={ Range={v=6,min=2,max=15,step=0.5}, Speed={v=2,min=1,max=20,step=1}, Delay={v=0,min=0,max=500,step=10} }, desc="Attacks nearby players automatically" },
    AimAssist      = { enabled=false, bind=nil, settings={ FOV={v=90,min=10,max=360,step=5}, Strength={v=50,min=1,max=100,step=1}, Silent={v=false} }, desc="Helps aim toward players" },
    AutoClicker    = { enabled=false, bind=Enum.KeyCode.C, settings={ CPS={v=14,min=1,max=20,step=1}, RandCPS={v=true} }, desc="Auto clicks at set CPS" },
    Reach          = { enabled=false, bind=nil, settings={ Distance={v=3.5,min=3,max=8,step=0.1} }, desc="Extended hit range" },
    Velocity       = { enabled=false, bind=nil, settings={ Horizontal={v=80,min=0,max=100,step=1}, Vertical={v=80,min=0,max=100,step=1} }, desc="Reduce knockback taken" },
    Criticals      = { enabled=false, bind=nil, settings={ Mode={v="Jump",opts={"Jump","Packet","NoGround"}} }, desc="Always land critical hits" },
    AntiKB         = { enabled=false, bind=nil, settings={ Horizontal={v=100,min=0,max=100,step=1} }, desc="Reduces horizontal knockback" },
    -- Movement
    Fly            = { enabled=false, bind=Enum.KeyCode.F, settings={ Speed={v=40,min=5,max=200,step=5}, Mode={v="Normal",opts={"Normal","Glide","Boost"}} }, desc="Free flight movement" },
    Speed          = { enabled=false, bind=Enum.KeyCode.G, settings={ Multiplier={v=2,min=1,max=10,step=0.5} }, desc="Increases movement speed" },
    HighJump       = { enabled=false, bind=nil, settings={ Power={v=60,min=10,max=200,step=5} }, desc="Jump much higher" },
    NoFall         = { enabled=false, bind=nil, settings={}, desc="No fall damage" },
    Spider         = { enabled=false, bind=nil, settings={ Speed={v=16,min=5,max=50,step=1} }, desc="Climb walls" },
    Phase          = { enabled=false, bind=nil, settings={}, desc="Phase through blocks" },
    Blink          = { enabled=false, bind=Enum.KeyCode.V, settings={ Duration={v=2,min=0.5,max=5,step=0.5} }, desc="Teleport forward on release" },
    -- Visual
    ESP            = { enabled=false, bind=Enum.KeyCode.Z, settings={ Boxes={v=true}, Names={v=true}, Distance={v=true}, Health={v=true}, MaxDist={v=100,min=10,max=500,step=10} }, desc="See players through walls" },
    XRay           = { enabled=false, bind=nil, settings={ Transparency={v=0.6,min=0.1,max=0.9,step=0.1} }, desc="See players through walls (chams)" },
    FullBright     = { enabled=false, bind=nil, settings={}, desc="Max brightness always" },
    Chams          = { enabled=false, bind=nil, settings={ Color={v="Purple",opts={"Purple","Red","Green","Blue","White"}} }, desc="Colored player highlights" },
    BedESP         = { enabled=false, bind=nil, settings={}, desc="Highlight enemy beds" },
    NameTags       = { enabled=false, bind=nil, settings={ ShowHealth={v=true}, ShowDist={v=true} }, desc="Show info above players" },
    -- Misc
    AutoHeal       = { enabled=false, bind=nil, settings={ Threshold={v=50,min=10,max=99,step=5} }, desc="Auto heal when low HP" },
    FastConsume    = { enabled=false, bind=nil, settings={}, desc="Instantly consume items" },
    AutoLeave      = { enabled=false, bind=nil, settings={ Threshold={v=10,min=1,max=50,step=1} }, desc="Auto leave when HP low" },
    ChestStealer   = { enabled=false, bind=nil, settings={ Delay={v=50,min=0,max=500,step=10} }, desc="Auto loot chests" },
    AutoToxic      = { enabled=false, bind=nil, settings={ Msg={v="gg ez"} }, desc="Auto chat on kill" },
    NickHider      = { enabled=false, bind=nil, settings={}, desc="Hides your username in chat" },
    AutoSoul       = { enabled=false, bind=nil, settings={}, desc="Auto collect souls" },
    FastDrop       = { enabled=false, bind=nil, settings={}, desc="Faster item drops" },
    FPSBoost       = { enabled=false, bind=nil, settings={ Level={v=2,min=1,max=5,step=1} }, desc="Reduce render distance for FPS" },
}

-- Tab → modules mapping
local TabModules = {
    Combat   = { "KillAura","AimAssist","AutoClicker","Reach","Velocity","Criticals","AntiKB" },
    Movement = { "Fly","Speed","HighJump","NoFall","Spider","Phase","Blink" },
    Visual   = { "ESP","XRay","FullBright","Chams","BedESP","NameTags" },
    Misc     = { "AutoHeal","FastConsume","AutoLeave","ChestStealer","AutoToxic","NickHider","AutoSoul","FastDrop","FPSBoost" },
    Profiles = {},
    Settings = {},
}

local TABS = { "Combat", "Movement", "Visual", "Misc", "Profiles", "Settings" }

-- ══════════════════════════════════════════
-- LOAD SAVED PROFILE
-- ══════════════════════════════════════════
local function applyProfile(data)
    if not data then return end
    for name, saved in pairs(data.modules or {}) do
        if Modules[name] then
            Modules[name].enabled = saved.enabled or false
            for k, v in pairs(saved.settings or {}) do
                if Modules[name].settings[k] then
                    Modules[name].settings[k].v = v
                end
            end
        end
    end
end

local function buildSaveData()
    local d = { modules = {} }
    for name, mod in pairs(Modules) do
        d.modules[name] = { enabled = mod.enabled, settings = {} }
        for k, s in pairs(mod.settings) do
            d.modules[name].settings[k] = s.v
        end
    end
    return d
end

local saved = loadProfile(PROF_ACTIVE)
if saved then applyProfile(saved) end

-- ══════════════════════════════════════════
-- SCREEN GUI
-- ══════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name           = "HorizonGUI"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder   = 999
SG.IgnoreGuiInset = true
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = LP:WaitForChild("PlayerGui") end

-- ══════════════════════════════════════════
-- THEME  (Vape V4 exact palette)
-- ══════════════════════════════════════════
local T = {
    BG          = Color3.fromRGB(16,16,20),
    BGDark      = Color3.fromRGB(11,11,14),
    BGPanel     = Color3.fromRGB(20,20,26),
    BGHov       = Color3.fromRGB(26,26,34),
    Border      = Color3.fromRGB(42,42,56),
    Accent      = Color3.fromRGB(108,92,231),
    AccentBright= Color3.fromRGB(138,122,255),
    AccentDark  = Color3.fromRGB(68,56,160),
    NavBG       = Color3.fromRGB(13,13,17),
    TabAct      = Color3.fromRGB(108,92,231),
    TabActTxt   = Color3.fromRGB(255,255,255),
    TabInaTxt   = Color3.fromRGB(120,120,140),
    Text        = Color3.fromRGB(232,232,238),
    Dim         = Color3.fromRGB(130,130,150),
    VDim        = Color3.fromRGB(68,68,84),
    ModBG       = Color3.fromRGB(21,21,27),
    ModOn       = Color3.fromRGB(108,92,231),
    ModOff      = Color3.fromRGB(38,38,52),
    Strip       = Color3.fromRGB(108,92,231),
    StripOff    = Color3.fromRGB(38,38,52),
    White       = Color3.fromRGB(255,255,255),
    Red         = Color3.fromRGB(205,55,55),
    Yellow      = Color3.fromRGB(205,165,35),
    Green       = Color3.fromRGB(60,190,100),
    Slider      = Color3.fromRGB(108,92,231),
    SliderBG    = Color3.fromRGB(38,38,52),
}

-- ══════════════════════════════════════════
-- DIMENSIONS
-- ══════════════════════════════════════════
local GW = 560
local GH = 380
local TOPBAR_H = 36
local NAV_H    = 30
local MOD_H    = 48

-- ══════════════════════════════════════════
-- HELPERS
-- ══════════════════════════════════════════
local function Cr(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p; return c
end

local function St(p, col, th)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Border
    s.Thickness = th or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p; return s
end

local function Pad(p, t, l, r, b)
    local u = Instance.new("UIPadding")
    u.PaddingTop    = UDim.new(0, t or 0)
    u.PaddingLeft   = UDim.new(0, l or 0)
    u.PaddingRight  = UDim.new(0, r or 0)
    u.PaddingBottom = UDim.new(0, b or 0)
    u.Parent = p; return u
end

local function ListLayout(p, dir, pad, ha, va)
    local l = Instance.new("UIListLayout")
    l.FillDirection       = dir or Enum.FillDirection.Vertical
    l.SortOrder           = Enum.SortOrder.LayoutOrder
    l.Padding             = UDim.new(0, pad or 0)
    l.HorizontalAlignment = ha or Enum.HorizontalAlignment.Left
    l.VerticalAlignment   = va or Enum.VerticalAlignment.Top
    l.Parent = p; return l
end

local function NewFrame(parent, props)
    local f = Instance.new("Frame")
    for k,v in pairs(props or {}) do f[k]=v end
    f.BorderSizePixel = 0
    f.Parent = parent
    return f
end

local function NewBtn(parent, props)
    local b = Instance.new("TextButton")
    for k,v in pairs(props or {}) do b[k]=v end
    b.BorderSizePixel = 0
    b.AutoButtonColor = false
    b.Parent = parent
    return b
end

local function NewLabel(parent, props)
    local l = Instance.new("TextLabel")
    for k,v in pairs(props or {}) do l[k]=v end
    l.BorderSizePixel = 0
    l.BackgroundTransparency = 1
    l.Parent = parent
    return l
end

local TW = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
local TWS = TweenInfo.new(0.18, Enum.EasingStyle.Quad)

-- ══════════════════════════════════════════
-- ROOT FRAME
-- ══════════════════════════════════════════
local Root = NewFrame(SG, {
    Name="Root", Size=UDim2.new(0,GW,0,GH),
    Position=UDim2.new(0.5,-GW/2,0.5,-GH/2),
    BackgroundColor3=T.BG, ZIndex=1, ClipsDescendants=false
})
Cr(Root, 8)
St(Root, T.Border, 1)

-- Shadow
local Shad = Instance.new("ImageLabel")
Shad.Size=UDim2.new(1,70,1,70); Shad.Position=UDim2.new(0,-35,0,-28)
Shad.BackgroundTransparency=1; Shad.Image="rbxassetid://6014261993"
Shad.ImageColor3=Color3.new(0,0,0); Shad.ImageTransparency=0.35
Shad.ScaleType=Enum.ScaleType.Slice; Shad.SliceCenter=Rect.new(49,49,450,450)
Shad.ZIndex=0; Shad.Parent=Root

local Clip = NewFrame(Root, {
    Size=UDim2.new(1,0,1,0), BackgroundColor3=T.BG,
    ClipsDescendants=true, ZIndex=1
})
Cr(Clip, 8)

-- ══════════════════════════════════════════
-- TOP BAR
-- ══════════════════════════════════════════
local TopBar = NewFrame(Clip, {
    Size=UDim2.new(1,0,0,TOPBAR_H), BackgroundColor3=T.BGDark, ZIndex=4
})

-- Accent stripe
local AccStripe = NewFrame(TopBar, {
    Size=UDim2.new(1,0,0,2),
    Position=UDim2.new(0,0,1,-2),
    BackgroundColor3=T.Accent, ZIndex=6
})
local ag = Instance.new("UIGradient")
ag.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   T.AccentDark),
    ColorSequenceKeypoint.new(0.5, T.AccentBright),
    ColorSequenceKeypoint.new(1,   T.AccentDark),
})
ag.Parent = AccStripe

-- Logo
local LogoF = NewFrame(TopBar, {
    Size=UDim2.new(0,18,0,18),
    Position=UDim2.new(0,12,0.5,-9),
    BackgroundColor3=T.Accent, ZIndex=6
})
Cr(LogoF, 99)
local LogoInner = NewFrame(LogoF, {
    Size=UDim2.new(0,7,0,7),
    Position=UDim2.new(0.5,-3.5,0.5,-3.5),
    BackgroundColor3=T.White, ZIndex=7
})
Cr(LogoInner, 99)

-- Title
NewLabel(TopBar, {
    Size=UDim2.new(0,80,1,0), Position=UDim2.new(0,36,0,0),
    Text="Horizon", TextColor3=T.White,
    Font=Enum.Font.GothamBold, TextSize=15,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6
})

-- Version badge
local VBadge = NewFrame(TopBar, {
    Size=UDim2.new(0,44,0,18),
    Position=UDim2.new(0,112,0.5,-9),
    BackgroundColor3=T.AccentDark, ZIndex=6
})
Cr(VBadge, 4)
NewLabel(VBadge, {
    Size=UDim2.new(1,0,1,0), Text="v0.1.1",
    TextColor3=Color3.fromRGB(200,190,255),
    Font=Enum.Font.GothamBold, TextSize=9, ZIndex=7
})

-- Executor badge
local ExecBadge = NewFrame(TopBar, {
    Size=UDim2.new(0,90,0,18),
    Position=UDim2.new(0,162,0.5,-9),
    BackgroundColor3=T.BGPanel, ZIndex=6
})
Cr(ExecBadge, 4)
St(ExecBadge, T.Border, 1)
NewLabel(ExecBadge, {
    Size=UDim2.new(1,-8,1,0), Position=UDim2.new(0,4,0,0),
    Text="⚡ "..Executor,
    TextColor3=T.Dim,
    Font=Enum.Font.GothamSemibold, TextSize=9,
    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=7
})

-- Win buttons
local function WinBtn(xOff, bg, sym)
    local b = NewBtn(TopBar, {
        Size=UDim2.new(0,14,0,14),
        Position=UDim2.new(1,xOff,0.5,-7),
        BackgroundColor3=bg, ZIndex=7, Text=""
    })
    Cr(b, 99)
    local s = NewLabel(b, {
        Size=UDim2.new(1,0,1,0), Text=sym,
        TextColor3=Color3.fromRGB(80,30,30),
        Font=Enum.Font.GothamBold, TextSize=8,
        Visible=false, ZIndex=8
    })
    b.MouseEnter:Connect(function() s.Visible=true; TS:Create(b,TW,{BackgroundColor3=b.BackgroundColor3:Lerp(T.White,0.25)}):Play() end)
    b.MouseLeave:Connect(function() s.Visible=false; TS:Create(b,TW,{BackgroundColor3=bg}):Play() end)
    return b, s
end

local CloseBtn = WinBtn(-22, T.Red,    "✕")
local MinBtn   = WinBtn(-42, T.Yellow, "—")

-- ══════════════════════════════════════════
-- NAV / TAB BAR
-- ══════════════════════════════════════════
local NavBar = NewFrame(Clip, {
    Size=UDim2.new(1,0,0,NAV_H),
    Position=UDim2.new(0,0,0,TOPBAR_H),
    BackgroundColor3=T.NavBG, ZIndex=4
})
NewFrame(NavBar, {
    Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,0),
    BackgroundColor3=T.Border, ZIndex=5
})
ListLayout(NavBar, Enum.FillDirection.Horizontal, 0,
    Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center)
Pad(NavBar, 0, 8, 0, 0)

-- ══════════════════════════════════════════
-- CONTENT
-- ══════════════════════════════════════════
local CONT_Y = TOPBAR_H + NAV_H + 1
local Content = NewFrame(Clip, {
    Size=UDim2.new(1,0,1,-CONT_Y),
    Position=UDim2.new(0,0,0,CONT_Y),
    BackgroundTransparency=1,
    ClipsDescendants=true, ZIndex=2
})

-- ══════════════════════════════════════════
-- PAGE BUILDER
-- ══════════════════════════════════════════
local Pages     = {}
local TabBtns   = {}
local ActiveTab = TABS[1]

local function NewPage(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Name=name; sf.Size=UDim2.new(1,0,1,0)
    sf.BackgroundTransparency=1; sf.BorderSizePixel=0
    sf.ScrollBarThickness=3; sf.ScrollBarImageColor3=T.Accent
    sf.CanvasSize=UDim2.new(0,0,0,0)
    sf.AutomaticCanvasSize=Enum.AutomaticSize.Y
    sf.Visible=false; sf.ZIndex=3; sf.Parent=Content
    -- Two-column grid
    local grid = Instance.new("UIGridLayout")
    grid.CellSize     = UDim2.new(0.5,-9,0,MOD_H)
    grid.CellPaddingY = UDim.new(0,5)
    grid.CellPaddingX = UDim.new(0,5)
    grid.SortOrder    = Enum.SortOrder.LayoutOrder
    grid.FillDirection= Enum.FillDirection.Horizontal
    grid.Parent       = sf
    Pad(sf, 10, 10, 10, 10)
    Pages[name] = sf
    return sf, grid
end

-- ══════════════════════════════════════════
-- MODULE TILE
-- ══════════════════════════════════════════
local SettingsPanel = nil  -- forward ref
local function BuildSettingsPanel() end -- forward ref

-- store refs for toggling
local ModTileRefs = {}

local function UpdateTileVisuals(name)
    local r = ModTileRefs[name]
    if not r then return end
    local on = Modules[name].enabled
    TS:Create(r.strip, TW, {BackgroundColor3=on and T.Strip or T.StripOff}):Play()
    TS:Create(r.box, TW, {BackgroundColor3=on and T.ModOn or T.ModOff}):Play()
    r.nameLbl.TextColor3 = on and T.White or T.Dim
    r.check.Text = on and "✓" or ""
    r.tile.BackgroundColor3 = on and T.BGHov or T.ModBG
end

local function ToggleModule(name)
    Modules[name].enabled = not Modules[name].enabled
    UpdateTileVisuals(name)
    -- Save
    saveProfile(PROF_ACTIVE, buildSaveData())
    -- Callbacks below
end

local function ModTile(page, name, order)
    local mod = Modules[name]
    local on  = mod.enabled

    local tile = NewFrame(page, {
        Name=name, BackgroundColor3=on and T.BGHov or T.ModBG,
        LayoutOrder=order, ZIndex=4
    })
    Cr(tile, 5)
    St(tile, on and T.Accent or T.Border, 1)

    -- left strip
    local strip = NewFrame(tile, {
        Size=UDim2.new(0,3,1,0),
        BackgroundColor3=on and T.Strip or T.StripOff, ZIndex=5
    })
    Cr(strip, 3)

    -- name
    local nameLbl = NewLabel(tile, {
        Size=UDim2.new(1,-52,0,17),
        Position=UDim2.new(0,11,0,7),
        Text=name, TextColor3=on and T.White or T.Dim,
        Font=Enum.Font.GothamSemibold, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
    })

    -- desc
    NewLabel(tile, {
        Size=UDim2.new(1,-52,0,12),
        Position=UDim2.new(0,11,0,25),
        Text=mod.desc, TextColor3=T.VDim,
        Font=Enum.Font.Gotham, TextSize=9,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
    })

    -- bind label (top right)
    local bindLbl = NewLabel(tile, {
        Size=UDim2.new(0,34,0,12),
        Position=UDim2.new(1,-44,0,5),
        Text=mod.bind and ("["..mod.bind.Name.."]") or "",
        TextColor3=T.VDim, Font=Enum.Font.Gotham, TextSize=8,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=6
    })

    -- checkbox
    local box = NewFrame(tile, {
        Size=UDim2.new(0,17,0,17),
        Position=UDim2.new(1,-26,0.5,-8),
        BackgroundColor3=on and T.ModOn or T.ModOff, ZIndex=6
    })
    Cr(box, 4)
    St(box, on and T.Accent or T.Border, 1)

    local check = NewLabel(box, {
        Size=UDim2.new(1,0,1,0),
        Text=on and "✓" or "",
        TextColor3=T.White,
        Font=Enum.Font.GothamBold, TextSize=11, ZIndex=7
    })

    -- settings gear (if has settings)
    local hasSettings = next(mod.settings) ~= nil
    if hasSettings then
        local gear = NewBtn(tile, {
            Size=UDim2.new(0,14,0,14),
            Position=UDim2.new(1,-26,1,-18),
            BackgroundColor3=T.BGPanel, ZIndex=7,
            Text="⚙", TextColor3=T.VDim,
            Font=Enum.Font.GothamBold, TextSize=9
        })
        Cr(gear, 3)
        gear.MouseButton1Click:Connect(function()
            if SettingsPanel then SettingsPanel:Destroy() SettingsPanel=nil end
            SettingsPanel = BuildSettingsPanel(name)
        end)
        gear.MouseEnter:Connect(function()
            TS:Create(gear,TW,{BackgroundColor3=T.Border}):Play()
            gear.TextColor3=T.Dim
        end)
        gear.MouseLeave:Connect(function()
            TS:Create(gear,TW,{BackgroundColor3=T.BGPanel}):Play()
            gear.TextColor3=T.VDim
        end)
    end

    -- hover
    tile.MouseEnter:Connect(function()
        if not Modules[name].enabled then
            TS:Create(tile,TW,{BackgroundColor3=T.BGHov}):Play()
        end
    end)
    tile.MouseLeave:Connect(function()
        if not Modules[name].enabled then
            TS:Create(tile,TW,{BackgroundColor3=T.ModBG}):Play()
        end
    end)

    -- click to toggle
    local btn = NewBtn(tile, {
        Size=UDim2.new(1,-30,1,0),
        BackgroundTransparency=1, Text="", ZIndex=8
    })
    btn.MouseButton1Click:Connect(function()
        ToggleModule(name)
    end)

    -- right click = bind
    btn.MouseButton2Click:Connect(function()
        bindLbl.Text = "[...]"
        local conn
        conn = UIS.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType == Enum.UserInputType.Keyboard then
                Modules[name].bind = inp.KeyCode
                bindLbl.Text = "["..inp.KeyCode.Name.."]"
                conn:Disconnect()
                saveProfile(PROF_ACTIVE, buildSaveData())
            end
        end)
    end)

    ModTileRefs[name] = {tile=tile, strip=strip, box=box, nameLbl=nameLbl, check=check, bindLbl=bindLbl}
    return tile
end

-- ══════════════════════════════════════════
-- SETTINGS PANEL (popup)
-- ══════════════════════════════════════════
BuildSettingsPanel = function(modName)
    local mod = Modules[modName]
    local settings = mod.settings
    local count = 0
    for _ in pairs(settings) do count=count+1 end
    local PH = 44 + count * 44 + 16

    local panel = NewFrame(SG, {
        Name="SettingsPanel",
        Size=UDim2.new(0,240,0,PH),
        Position=UDim2.new(0.5,-120,0.5,-PH/2),
        BackgroundColor3=T.BGDark, ZIndex=20
    })
    Cr(panel, 8)
    St(panel, T.Accent, 1)

    -- shadow
    local ps = Instance.new("ImageLabel")
    ps.Size=UDim2.new(1,40,1,40); ps.Position=UDim2.new(0,-20,0,-15)
    ps.BackgroundTransparency=1; ps.Image="rbxassetid://6014261993"
    ps.ImageColor3=Color3.new(0,0,0); ps.ImageTransparency=0.3
    ps.ScaleType=Enum.ScaleType.Slice; ps.SliceCenter=Rect.new(49,49,450,450)
    ps.ZIndex=19; ps.Parent=panel

    -- header
    local hdr = NewFrame(panel, {
        Size=UDim2.new(1,0,0,36),
        BackgroundColor3=T.AccentDark, ZIndex=21
    })
    Cr(hdr, 8)
    NewLabel(hdr, {
        Size=UDim2.new(1,-40,1,0), Position=UDim2.new(0,12,0,0),
        Text=modName.." Settings",
        TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=22
    })
    local xbtn = NewBtn(hdr, {
        Size=UDim2.new(0,24,0,24), Position=UDim2.new(1,-30,0.5,-12),
        BackgroundColor3=T.Red, Text="✕",
        TextColor3=T.White, Font=Enum.Font.GothamBold, TextSize=10, ZIndex=23
    })
    Cr(xbtn, 5)
    xbtn.MouseButton1Click:Connect(function() panel:Destroy() SettingsPanel=nil end)

    local scroll = Instance.new("ScrollingFrame")
    scroll.Size=UDim2.new(1,0,1,-40); scroll.Position=UDim2.new(0,0,0,40)
    scroll.BackgroundTransparency=1; scroll.BorderSizePixel=0
    scroll.ScrollBarThickness=2; scroll.ScrollBarImageColor3=T.Accent
    scroll.CanvasSize=UDim2.new(0,0,0,0); scroll.AutomaticCanvasSize=Enum.AutomaticSize.Y
    scroll.ZIndex=21; scroll.Parent=panel
    ListLayout(scroll, Enum.FillDirection.Vertical, 8)
    Pad(scroll, 10, 12, 12, 10)

    for k, s in pairs(settings) do
        local row = NewFrame(scroll, {
            Size=UDim2.new(1,0,0,38),
            BackgroundColor3=T.BGPanel, ZIndex=22
        })
        Cr(row, 5)

        NewLabel(row, {
            Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,8,0,4),
            Text=k, TextColor3=T.Text,
            Font=Enum.Font.GothamSemibold, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=23
        })

        if type(s.v) == "boolean" then
            -- toggle
            local tog = NewFrame(row, {
                Size=UDim2.new(0,36,0,18),
                Position=UDim2.new(1,-46,1,-22),
                BackgroundColor3=s.v and T.ModOn or T.ModOff, ZIndex=23
            })
            Cr(tog, 99)
            local knob = NewFrame(tog, {
                Size=UDim2.new(0,14,0,14),
                Position=s.v and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
                BackgroundColor3=T.White, ZIndex=24
            })
            Cr(knob, 99)
            local tbtn = NewBtn(tog, {Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=25})
            tbtn.MouseButton1Click:Connect(function()
                s.v = not s.v
                TS:Create(tog,TW,{BackgroundColor3=s.v and T.ModOn or T.ModOff}):Play()
                TS:Create(knob,TW,{Position=s.v and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}):Play()
                saveProfile(PROF_ACTIVE, buildSaveData())
            end)
        elseif s.opts then
            -- dropdown-style cycle
            local valLbl = NewLabel(row, {
                Size=UDim2.new(1,-16,0,14),
                Position=UDim2.new(0,8,1,-18),
                Text="◀ "..tostring(s.v).." ▶",
                TextColor3=T.Accent, Font=Enum.Font.GothamSemibold, TextSize=10,
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=23
            })
            local clickable = NewBtn(row, {Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="",ZIndex=25})
            clickable.MouseButton1Click:Connect(function()
                local idx = table.find(s.opts, s.v) or 1
                idx = idx % #s.opts + 1
                s.v = s.opts[idx]
                valLbl.Text = "◀ "..s.v.." ▶"
                saveProfile(PROF_ACTIVE, buildSaveData())
            end)
        elseif type(s.v) == "number" and s.min then
            -- slider
            local pct = (s.v - s.min) / (s.max - s.min)
            local slBG = NewFrame(row, {
                Size=UDim2.new(1,-16,0,6),
                Position=UDim2.new(0,8,1,-12),
                BackgroundColor3=T.SliderBG, ZIndex=23
            })
            Cr(slBG, 3)
            local slFill = NewFrame(slBG, {
                Size=UDim2.new(pct,0,1,0),
                BackgroundColor3=T.Slider, ZIndex=24
            })
            Cr(slFill, 3)
            local valLbl = NewLabel(row, {
                Size=UDim2.new(0,40,0,14),
                Position=UDim2.new(1,-48,1,-18),
                Text=tostring(s.v),
                TextColor3=T.Accent, Font=Enum.Font.GothamBold, TextSize=10,
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=23
            })
            local dragging = false
            local function updateSlider(x)
                local rel = math.clamp((x - slBG.AbsolutePosition.X) / slBG.AbsoluteSize.X, 0, 1)
                local raw = s.min + rel*(s.max-s.min)
                local steps = math.round((raw - s.min)/s.step)
                s.v = math.clamp(s.min + steps*s.step, s.min, s.max)
                s.v = math.round(s.v*100)/100
                slFill.Size = UDim2.new(rel, 0, 1, 0)
                valLbl.Text = tostring(s.v)
                saveProfile(PROF_ACTIVE, buildSaveData())
            end
            local slBtn = NewBtn(slBG, {Size=UDim2.new(1,0,3,0),Position=UDim2.new(0,0,-1,0),BackgroundTransparency=1,Text="",ZIndex=26})
            slBtn.MouseButton1Down:Connect(function() dragging=true end)
            UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end end)
            UIS.InputChanged:Connect(function(i)
                if dragging and i.UserInputType==Enum.UserInputType.MouseMovement then
                    updateSlider(i.Position.X)
                end
            end)
            slBtn.MouseButton1Down:Connect(function(x,y) updateSlider(x) end)
        elseif type(s.v) == "string" and not s.opts then
            -- text input (for things like AutoToxic message)
            local box2 = Instance.new("TextBox")
            box2.Size=UDim2.new(1,-16,0,16); box2.Position=UDim2.new(0,8,1,-20)
            box2.BackgroundColor3=T.ModOff; box2.BorderSizePixel=0
            box2.Text=s.v; box2.TextColor3=T.Text
            box2.Font=Enum.Font.Gotham; box2.TextSize=10
            box2.PlaceholderColor3=T.VDim; box2.ZIndex=23
            Cr(box2, 3); box2.Parent=row
            box2.FocusLost:Connect(function() s.v=box2.Text; saveProfile(PROF_ACTIVE,buildSaveData()) end)
        end
    end

    -- Make draggable
    local pd, po = false, Vector2.zero
    hdr.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then
            pd=true; po=Vector2.new(i.Position.X,i.Position.Y)-Vector2.new(panel.AbsolutePosition.X,panel.AbsolutePosition.Y)
        end
    end)
    UIS.InputChanged:Connect(function(i)
        if pd and i.UserInputType==Enum.UserInputType.MouseMovement then
            local p=Vector2.new(i.Position.X,i.Position.Y)-po
            panel.Position=UDim2.new(0,p.X,0,p.Y)
        end
    end)
    UIS.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then pd=false end
    end)

    return panel
end

-- ══════════════════════════════════════════
-- BUILD ALL MODULE PAGES
-- ══════════════════════════════════════════
for _, tabName in ipairs(TABS) do
    local page = NewPage(tabName)
end

for tabName, mods in pairs(TabModules) do
    local page = Pages[tabName]
    if page then
        for i, modName in ipairs(mods) do
            if Modules[modName] then
                ModTile(page, modName, i)
            end
        end
    end
end

-- ══════════════════════════════════════════
-- PROFILES PAGE
-- ══════════════════════════════════════════
local function BuildProfilesPage()
    local page = Pages["Profiles"]
    -- remove grid, use list
    for _, c in ipairs(page:GetChildren()) do
        if c:IsA("UIGridLayout") then c:Destroy() end
    end
    ListLayout(page, Enum.FillDirection.Vertical, 8)
    Pad(page, 12, 14, 14, 12)

    -- clear existing
    for _, c in ipairs(page:GetChildren()) do
        if c:IsA("Frame") or c:IsA("TextButton") then c:Destroy() end
    end

    -- Active profile display
    local activeRow = NewFrame(page, {
        Size=UDim2.new(1,0,0,36),
        BackgroundColor3=T.BGPanel, ZIndex=4
    })
    Cr(activeRow, 6)
    NewLabel(activeRow, {
        Size=UDim2.new(1,-100,1,0), Position=UDim2.new(0,12,0,0),
        Text="Active: "..PROF_ACTIVE,
        TextColor3=T.Accent, Font=Enum.Font.GothamBold, TextSize=13,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
    })

    -- Profiles list
    local profileList = listProfiles()
    for _, pname in ipairs(profileList) do
        local row = NewFrame(page, {
            Size=UDim2.new(1,0,0,40),
            BackgroundColor3=T.ModBG, ZIndex=4
        })
        Cr(row, 6)
        St(row, pname==PROF_ACTIVE and T.Accent or T.Border, 1)

        local strip = NewFrame(row, {
            Size=UDim2.new(0,3,1,0),
            BackgroundColor3=pname==PROF_ACTIVE and T.Accent or T.StripOff, ZIndex=5
        })
        Cr(strip, 3)

        NewLabel(row, {
            Size=UDim2.new(1,-110,1,0), Position=UDim2.new(0,12,0,0),
            Text=pname, TextColor3=pname==PROF_ACTIVE and T.White or T.Dim,
            Font=Enum.Font.GothamSemibold, TextSize=13,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
        })

        -- Load btn
        local loadBtn = NewBtn(row, {
            Size=UDim2.new(0,52,0,24),
            Position=UDim2.new(1,-114,0.5,-12),
            BackgroundColor3=T.AccentDark, Text="Load",
            TextColor3=T.White, Font=Enum.Font.GothamSemibold, TextSize=11, ZIndex=6
        })
        Cr(loadBtn, 5)
        loadBtn.MouseButton1Click:Connect(function()
            PROF_ACTIVE = pname
            local d = loadProfile(pname)
            if d then applyProfile(d) end
            for mname, _ in pairs(Modules) do UpdateTileVisuals(mname) end
            BuildProfilesPage()
        end)

        -- Delete btn (not default)
        if pname ~= "Default" then
            local delBtn = NewBtn(row, {
                Size=UDim2.new(0,50,0,24),
                Position=UDim2.new(1,-58,0.5,-12),
                BackgroundColor3=T.Red, Text="Delete",
                TextColor3=T.White, Font=Enum.Font.GothamSemibold, TextSize=10, ZIndex=6
            })
            Cr(delBtn, 5)
            delBtn.MouseButton1Click:Connect(function()
                pcall(function()
                    if isfile(SAVE_PATH..pname..".json") then
                        delfile(SAVE_PATH..pname..".json")
                    end
                end)
                if PROF_ACTIVE == pname then PROF_ACTIVE = "Default" end
                BuildProfilesPage()
            end)
        end
    end

    -- New profile
    local newRow = NewFrame(page, {
        Size=UDim2.new(1,0,0,44),
        BackgroundColor3=T.BGPanel, ZIndex=4
    })
    Cr(newRow, 6)
    St(newRow, T.Border, 1)

    NewLabel(newRow, {
        Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,12,0,4),
        Text="Create New Profile",
        TextColor3=T.Dim, Font=Enum.Font.GothamBold, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
    })

    local nameBox = Instance.new("TextBox")
    nameBox.Size=UDim2.new(1,-80,0,20); nameBox.Position=UDim2.new(0,12,1,-26)
    nameBox.BackgroundColor3=T.ModOff; nameBox.BorderSizePixel=0
    nameBox.Text=""; nameBox.PlaceholderText="Profile name..."
    nameBox.TextColor3=T.Text; nameBox.PlaceholderColor3=T.VDim
    nameBox.Font=Enum.Font.Gotham; nameBox.TextSize=11; nameBox.ZIndex=5
    Cr(nameBox, 4); nameBox.Parent=newRow

    local createBtn = NewBtn(newRow, {
        Size=UDim2.new(0,56,0,20),
        Position=UDim2.new(1,-68,1,-26),
        BackgroundColor3=T.Accent, Text="Create",
        TextColor3=T.White, Font=Enum.Font.GothamSemibold, TextSize=11, ZIndex=6
    })
    Cr(createBtn, 4)
    createBtn.MouseButton1Click:Connect(function()
        local n = nameBox.Text:gsub("%s+","_")
        if n ~= "" then
            PROF_ACTIVE = n
            saveProfile(n, buildSaveData())
            nameBox.Text = ""
            BuildProfilesPage()
        end
    end)
end
BuildProfilesPage()

-- ══════════════════════════════════════════
-- SETTINGS PAGE
-- ══════════════════════════════════════════
local function BuildSettingsPage()
    local page = Pages["Settings"]
    for _, c in ipairs(page:GetChildren()) do
        if c:IsA("UIGridLayout") then c:Destroy() end
    end
    ListLayout(page, Enum.FillDirection.Vertical, 8)
    Pad(page, 12, 14, 14, 12)

    -- info rows
    local function InfoRow(lbl, val)
        local row = NewFrame(page, {
            Size=UDim2.new(1,0,0,36),
            BackgroundColor3=T.BGPanel, ZIndex=4
        })
        Cr(row, 5)
        NewLabel(row, {
            Size=UDim2.new(0.5,0,1,0), Position=UDim2.new(0,12,0,0),
            Text=lbl, TextColor3=T.Dim,
            Font=Enum.Font.GothamSemibold, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
        })
        NewLabel(row, {
            Size=UDim2.new(0.5,-12,1,0), Position=UDim2.new(0.5,0,0,0),
            Text=val, TextColor3=T.Accent,
            Font=Enum.Font.GothamBold, TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Right, ZIndex=5
        })
    end

    InfoRow("Executor",      Executor)
    InfoRow("Version",       "0.1.1")
    InfoRow("Game",          "BedWars")
    InfoRow("Profile",       PROF_ACTIVE)
    InfoRow("Player",        LP.Name)

    -- Skin preview row
    local skinRow = NewFrame(page, {
        Size=UDim2.new(1,0,0,72),
        BackgroundColor3=T.BGPanel, ZIndex=4
    })
    Cr(skinRow, 5)
    NewLabel(skinRow, {
        Size=UDim2.new(1,0,0,16), Position=UDim2.new(0,12,0,6),
        Text="Your Character", TextColor3=T.Dim,
        Font=Enum.Font.GothamBold, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
    })
    -- Skin avatar thumbnail
    local thumb = Instance.new("ImageLabel")
    thumb.Size=UDim2.new(0,52,0,52); thumb.Position=UDim2.new(0,12,0,18)
    thumb.BackgroundColor3=T.ModOff; thumb.BorderSizePixel=0
    thumb.Image="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=60&h=60"
    thumb.ZIndex=5; thumb.Parent=skinRow
    Cr(thumb, 6)

    NewLabel(skinRow, {
        Size=UDim2.new(1,-80,0,18), Position=UDim2.new(0,74,0,22),
        Text=LP.Name, TextColor3=T.White,
        Font=Enum.Font.GothamBold, TextSize=14,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
    })
    NewLabel(skinRow, {
        Size=UDim2.new(1,-80,0,14), Position=UDim2.new(0,74,0,42),
        Text="ID: "..LP.UserId, TextColor3=T.VDim,
        Font=Enum.Font.Gotham, TextSize=10,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
    })

    -- GUI Toggle keybind
    local guiRow = NewFrame(page, {
        Size=UDim2.new(1,0,0,40),
        BackgroundColor3=T.BGPanel, ZIndex=4
    })
    Cr(guiRow, 5)
    NewLabel(guiRow, {
        Size=UDim2.new(0.6,0,1,0), Position=UDim2.new(0,12,0,0),
        Text="GUI Toggle Keybind",
        TextColor3=T.Text, Font=Enum.Font.GothamSemibold, TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
    })
    local guiBindLbl = NewLabel(guiRow, {
        Size=UDim2.new(0,80,1,0),
        Position=UDim2.new(1,-90,0,0),
        Text="[RightShift]",
        TextColor3=T.Accent, Font=Enum.Font.GothamBold, TextSize=11,
        TextXAlignment=Enum.TextXAlignment.Right, ZIndex=5
    })
    local guiBindBtn = NewBtn(guiRow, {
        Size=UDim2.new(1,0,1,0), BackgroundTransparency=1, Text="", ZIndex=6
    })
    guiBindBtn.MouseButton2Click:Connect(function()
        guiBindLbl.Text = "[...]"
        local conn
        conn = UIS.InputBegan:Connect(function(inp, gp)
            if gp then return end
            if inp.UserInputType==Enum.UserInputType.Keyboard then
                GUI_TOGGLE_KEY = inp.KeyCode
                guiBindLbl.Text = "["..inp.KeyCode.Name.."]"
                conn:Disconnect()
            end
        end)
    end)
end
BuildSettingsPage()

-- ══════════════════════════════════════════
-- HUD / ACTIVE MODULE DISPLAY
-- ══════════════════════════════════════════
local HUD = NewFrame(SG, {
    Name="HUD",
    Size=UDim2.new(0,130,0,10),
    Position=UDim2.new(1,-144,0.5,-150),
    BackgroundTransparency=1, ZIndex=10
})
ListLayout(HUD, Enum.FillDirection.Vertical, 3)

local HudLabels = {}

local function UpdateHUD()
    for _, l in pairs(HudLabels) do l:Destroy() end
    HudLabels = {}
    for name, mod in pairs(Modules) do
        if mod.enabled then
            local lbl = NewLabel(HUD, {
                Size=UDim2.new(1,0,0,16),
                Text=name,
                TextColor3=T.Accent,
                Font=Enum.Font.GothamBold, TextSize=11,
                TextXAlignment=Enum.TextXAlignment.Right, ZIndex=11
            })
            table.insert(HudLabels, lbl)
        end
    end
end
UpdateHUD()

-- ══════════════════════════════════════════
-- TAB BUTTONS
-- ══════════════════════════════════════════
local function SetTab(name)
    ActiveTab = name
    for _, t in ipairs(TABS) do
        local b = TabBtns[t]
        local act = t == name
        if b then
            TS:Create(b, TW, {BackgroundColor3 = act and T.TabAct or Color3.new(0,0,0)}):Play()
            b.BackgroundTransparency = act and 0 or 1
            b.TextColor3 = act and T.TabActTxt or T.TabInaTxt
            -- bottom indicator
            local ind = b:FindFirstChild("Ind")
            if ind then ind.Visible = act end
        end
        if Pages[t] then Pages[t].Visible = act end
    end
end

for i, tabName in ipairs(TABS) do
    local isAct = i == 1
    local btn = NewBtn(NavBar, {
        Size=UDim2.new(0,75,1,0),
        BackgroundColor3 = isAct and T.TabAct or Color3.new(0,0,0),
        BackgroundTransparency = isAct and 0 or 1,
        Text=tabName,
        TextColor3 = isAct and T.TabActTxt or T.TabInaTxt,
        Font=Enum.Font.GothamSemibold, TextSize=11,
        LayoutOrder=i, ZIndex=5
    })
    -- underline indicator
    local ind = NewFrame(btn, {
        Name="Ind",
        Size=UDim2.new(0.65,0,0,2),
        Position=UDim2.new(0.175,0,1,-2),
        BackgroundColor3=T.White, ZIndex=6
    })
    ind.Visible = isAct

    btn.MouseEnter:Connect(function()
        if ActiveTab ~= tabName then
            TS:Create(btn,TW,{BackgroundColor3=T.BGHov}):Play()
            btn.BackgroundTransparency=0
        end
    end)
    btn.MouseLeave:Connect(function()
        if ActiveTab ~= tabName then
            TS:Create(btn,TW,{BackgroundColor3=Color3.new(0,0,0)}):Play()
            btn.BackgroundTransparency=1
        end
    end)
    btn.MouseButton1Click:Connect(function() SetTab(tabName) end)
    TabBtns[tabName] = btn
end

SetTab(TABS[1])

-- ══════════════════════════════════════════
-- MODULE LOGIC
-- ══════════════════════════════════════════
local ESPObjs = {}
local FlyConn = nil
local OrigBindToggle = {}  -- track old toggle function
local LastBlink = nil

-- override ToggleModule to run logic
local baseToggle = ToggleModule
ToggleModule = function(name)
    baseToggle(name)
    local on = Modules[name].enabled
    UpdateHUD()

    -- ── FLY ──
    if name == "Fly" then
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end
        if on then
            hum.PlatformStand = true
            local bg = Instance.new("BodyGyro")
            bg.MaxTorque=Vector3.new(1e5,1e5,1e5); bg.P=1e4; bg.Name="HFlyG"; bg.Parent=hrp
            local bv = Instance.new("BodyVelocity")
            bv.MaxForce=Vector3.new(1e5,1e5,1e5); bv.Velocity=Vector3.zero; bv.Name="HFlyV"; bv.Parent=hrp
            FlyConn = RS.Heartbeat:Connect(function()
                if not Modules.Fly.enabled then return end
                local spd = Modules.Fly.settings.Speed.v
                local dir = Vector3.zero
                if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=Cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=Cam.CFrame.LookVector end
                if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=Cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=Cam.CFrame.RightVector end
                if UIS:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.yAxis end
                if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.yAxis end
                if dir.Magnitude>0 then dir=dir.Unit end
                bv.Velocity=dir*spd; bg.CFrame=Cam.CFrame
            end)
        else
            if FlyConn then FlyConn:Disconnect(); FlyConn=nil end
            if hrp then
                local g=hrp:FindFirstChild("HFlyG"); if g then g:Destroy() end
                local v=hrp:FindFirstChild("HFlyV"); if v then v:Destroy() end
            end
            if hum then hum.PlatformStand=false end
        end

    -- ── SPEED ──
    elseif name == "Speed" then
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = on and (16*Modules.Speed.settings.Multiplier.v) or 16 end

    -- ── HIGH JUMP ──
    elseif name == "HighJump" then
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = on and Modules.HighJump.settings.Power.v or 50 end

    -- ── NO FALL ──
    elseif name == "NoFall" then
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = hum.WalkSpeed end  -- handled in heartbeat below

    -- ── FULLBRIGHT ──
    elseif name == "FullBright" then
        game:GetService("Lighting").Brightness       = on and 2 or 1
        game:GetService("Lighting").ClockTime        = on and 14 or 14
        game:GetService("Lighting").FogEnd           = on and 1e6 or 1000
        game:GetService("Lighting").GlobalShadows    = not on
        game:GetService("Lighting").Ambient          = on and Color3.new(1,1,1) or Color3.new(0.5,0.5,0.5)

    -- ── ESP ──
    elseif name == "ESP" then
        if on then
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local box = Instance.new("SelectionBox")
                    box.Adornee=p.Character; box.Color3=T.Accent
                    box.LineThickness=0.05; box.SurfaceTransparency=0.85
                    box.SurfaceColor3=T.Accent; box.Parent=workspace
                    ESPObjs[p.Name]=box
                end
            end
        else
            for _,o in pairs(ESPObjs) do o:Destroy() end; ESPObjs={}
        end

    -- ── CHAMS ──
    elseif name == "Chams" then
        local colors = {Purple=T.Accent, Red=T.Red, Green=T.Green, Blue=Color3.fromRGB(60,120,255), White=T.White}
        local col = colors[Modules.Chams.settings.Color.v] or T.Accent
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if on then
                            local h = Instance.new("SelectionSphere")
                            h.Name="HChams"; h.Adornee=part; h.Color3=col
                            h.SurfaceTransparency=0.5; h.Parent=part
                        else
                            local h=part:FindFirstChild("HChams"); if h then h:Destroy() end
                        end
                    end
                end
            end
        end

    -- ── XRAY ──
    elseif name == "XRay" then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                for _, part in ipairs(p.Character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name~="HumanoidRootPart" then
                        part.LocalTransparencyModifier = on and Modules.XRay.settings.Transparency.v or 0
                    end
                end
            end
        end

    -- ── FPS BOOST ──
    elseif name == "FPSBoost" then
        local levels = {50,100,200,400,1000}
        workspace.StreamingEnabled = false
        game:GetService("Lighting").FogEnd = on and levels[Modules.FPSBoost.settings.Level.v] or 1e5
    end
end

-- Heartbeat effects (continuous)
RS.Heartbeat:Connect(function()
    -- NoFall
    if Modules.NoFall.enabled then
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false) end
    end

    -- Kill Aura
    if Modules.KillAura.enabled then
        local char = LP.Character
        local hrp  = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local range = Modules.KillAura.settings.Range.v
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                    local ohrp = p.Character:FindFirstChild("HumanoidRootPart")
                    if ohrp and (ohrp.Position-hrp.Position).Magnitude <= range then
                        local tool = char:FindFirstChildOfClass("Tool")
                        if tool and tool:FindFirstChildOfClass("LocalScript") == nil then
                            local event = tool:FindFirstChild("RemoteEvent") or tool:FindFirstChild("ToolEvent")
                            -- fire generic hit
                            pcall(function()
                                local args = {p.Character:FindFirstChild("HumanoidRootPart")}
                                for _, v in ipairs(tool:GetDescendants()) do
                                    if v:IsA("RemoteEvent") then v:FireServer(unpack(args)) end
                                end
                            end)
                        end
                    end
                end
            end
        end
    end

    -- Auto Clicker
    if Modules.AutoClicker.enabled then
        -- Handled via mouse1click simulation – just fire tool activate
        local char = LP.Character
        if char then
            local tool = char:FindFirstChildOfClass("Tool")
            if tool then
                local cps  = Modules.AutoClicker.settings.CPS.v
                local rand = Modules.AutoClicker.settings.RandCPS.v
                local interval = 1/cps
                if rand then interval = interval * (0.8 + math.random()*0.4) end
                -- staggered click via task.delay to not flood
                if not tool:GetAttribute("ACTick") or tick()-tool:GetAttribute("ACTick") >= interval then
                    tool:GetAttributeChangedSignal("ACTick")  -- no-op, just timing
                    tool:SetAttribute("ACTick", tick())
                    pcall(function() tool:Activate() end)
                end
            end
        end
    end

    -- Speed (keep updating in case char respawns)
    if Modules.Speed.enabled then
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= 16*Modules.Speed.settings.Multiplier.v then
            hum.WalkSpeed = 16*Modules.Speed.settings.Multiplier.v
        end
    end

    -- HighJump
    if Modules.HighJump.enabled then
        local char = LP.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.JumpPower ~= Modules.HighJump.settings.Power.v then
            hum.JumpPower = Modules.HighJump.settings.Power.v
        end
    end
end)

-- ══════════════════════════════════════════
-- KEYBIND LISTENER
-- ══════════════════════════════════════════
local GUI_TOGGLE_KEY = Enum.KeyCode.RightShift
local guiVisible = true

UIS.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end

    -- GUI toggle
    if inp.KeyCode == GUI_TOGGLE_KEY then
        guiVisible = not guiVisible
        Root.Visible = guiVisible
        HUD.Visible  = true  -- HUD always visible
        return
    end

    -- Module keybinds
    for name, mod in pairs(Modules) do
        if mod.bind and inp.KeyCode == mod.bind then
            ToggleModule(name)
            UpdateTileVisuals(name)
        end
    end
end)

-- ══════════════════════════════════════════
-- DRAG (TopBar)
-- ══════════════════════════════════════════
local dragging, dragOff = false, Vector2.zero
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        dragging=true
        dragOff=Vector2.new(inp.Position.X,inp.Position.Y)
                -Vector2.new(Root.AbsolutePosition.X,Root.AbsolutePosition.Y)
    end
end)
UIS.InputChanged:Connect(function(inp)
    if not dragging then return end
    if inp.UserInputType==Enum.UserInputType.MouseMovement
    or inp.UserInputType==Enum.UserInputType.Touch then
        local p=Vector2.new(inp.Position.X,inp.Position.Y)-dragOff
        local vp=Cam.ViewportSize; local sz=Root.AbsoluteSize
        p=Vector2.new(math.clamp(p.X,0,vp.X-sz.X),math.clamp(p.Y,0,vp.Y-sz.Y))
        Root.Position=UDim2.new(0,p.X,0,p.Y)
    end
end)
UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType==Enum.UserInputType.MouseButton1
    or inp.UserInputType==Enum.UserInputType.Touch then
        dragging=false
    end
end)

-- ══════════════════════════════════════════
-- MINIMIZE / CLOSE
-- ══════════════════════════════════════════
local minimized = false
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    local tgt = minimized and (TOPBAR_H+NAV_H+1) or GH
    TS:Create(Root, TW, {Size=UDim2.new(0,GW,0,tgt)}):Play()
end)

CloseBtn.MouseButton1Click:Connect(function()
    -- cleanup
    if FlyConn then FlyConn:Disconnect() end
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local g=hrp:FindFirstChild("HFlyG"); if g then g:Destroy() end
            local v=hrp:FindFirstChild("HFlyV"); if v then v:Destroy() end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand=false; hum.WalkSpeed=16; hum.JumpPower=50 end
    end
    for _,o in pairs(ESPObjs) do o:Destroy() end
    SG:Destroy()
end)

-- ══════════════════════════════════════════
-- OPEN ANIMATION
-- ══════════════════════════════════════════
Root.Size = UDim2.new(0,GW,0,0)
Root.BackgroundTransparency = 1
TS:Create(Root, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    {Size=UDim2.new(0,GW,0,GH), BackgroundTransparency=0}):Play()

print("[Horizon] Loaded. Executor: "..Executor)
