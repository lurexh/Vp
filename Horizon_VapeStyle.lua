-- Horizon 0.1.1 | Vape V4 Style
-- Paste into any Roblox executor

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local TweenService     = game:GetService("TweenService")

local LP  = Players.LocalPlayer
local BASE_SPEED = 16

-- ─── State ───────────────────────────────────────────────────────────────────
local Toggles = { Fly = false, Speed = false, ESP = false, XRay = false }
local ActiveTab = "Combat"
local Minimized = false
local Dragging, DragOff = false, Vector2.zero
local ESPObjs, FlyConn = {}, nil

-- ─── GUI Root ────────────────────────────────────────────────────────────────
local SG = Instance.new("ScreenGui")
SG.Name           = "HorizonGUI"
SG.ResetOnSpawn   = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder   = 999
SG.IgnoreGuiInset = true
pcall(function() SG.Parent = game:GetService("CoreGui") end)
if not SG.Parent then SG.Parent = LP:WaitForChild("PlayerGui") end

-- ─── Theme — Vape V4 ─────────────────────────────────────────────────────────
local T = {
    BG         = Color3.fromRGB(18, 18, 22),
    BGDark     = Color3.fromRGB(13, 13, 16),
    Border     = Color3.fromRGB(45, 45, 58),
    BorderHi   = Color3.fromRGB(70, 70, 90),
    Accent     = Color3.fromRGB(114, 95, 255),
    AccentDim  = Color3.fromRGB(70, 58, 160),
    NavBG      = Color3.fromRGB(14, 14, 18),
    NavAct     = Color3.fromRGB(114, 95, 255),
    NavIna     = Color3.fromRGB(14, 14, 18),
    TabTxtAct  = Color3.fromRGB(255, 255, 255),
    TabTxtIna  = Color3.fromRGB(130, 130, 150),
    Text       = Color3.fromRGB(230, 230, 235),
    Dim        = Color3.fromRGB(130, 130, 150),
    VDim       = Color3.fromRGB(65, 65, 80),
    ModBG      = Color3.fromRGB(22, 22, 28),
    ModBGHov   = Color3.fromRGB(28, 28, 36),
    ModEnabled = Color3.fromRGB(114, 95, 255),
    ModDis     = Color3.fromRGB(40, 40, 52),
    White      = Color3.fromRGB(255, 255, 255),
    Red        = Color3.fromRGB(210, 55, 55),
    Yellow     = Color3.fromRGB(210, 165, 35),
    Green      = Color3.fromRGB(55, 185, 100),
}

-- ─── Dimensions ──────────────────────────────────────────────────────────────
local GW, GH   = 520, 340
local TOPBAR_H = 34
local NAV_H    = 30
local COLS     = 2
local MOD_H    = 42

-- ─── Helpers ─────────────────────────────────────────────────────────────────
local function Cr(p, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = p
end

local function St(p, col, t)
    local s = Instance.new("UIStroke")
    s.Color = col or T.Border
    s.Thickness = t or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = p
end

local function Lbl(parent, text, size, color, font, xa)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text           = text or ""
    l.TextSize       = size or 12
    l.TextColor3     = color or T.Text
    l.Font           = font or Enum.Font.GothamSemibold
    l.TextXAlignment = xa or Enum.TextXAlignment.Left
    l.Size           = UDim2.new(1, 0, 1, 0)
    l.ZIndex         = 6
    l.Parent         = parent
    return l
end

-- ─── Root ─────────────────────────────────────────────────────────────────────
local Root = Instance.new("Frame")
Root.Name              = "Root"
Root.Size              = UDim2.new(0, GW, 0, GH)
Root.Position          = UDim2.new(0.5, -GW/2, 0.5, -GH/2)
Root.BackgroundColor3  = T.BG
Root.BorderSizePixel   = 0
Root.ClipsDescendants  = false
Root.Parent            = SG
Cr(Root, 8)
St(Root, T.Border, 1)

-- Shadow
local Shad = Instance.new("ImageLabel")
Shad.Size               = UDim2.new(1, 60, 1, 60)
Shad.Position           = UDim2.new(0, -30, 0, -20)
Shad.BackgroundTransparency = 1
Shad.Image              = "rbxassetid://6014261993"
Shad.ImageColor3        = Color3.new(0, 0, 0)
Shad.ImageTransparency  = 0.4
Shad.ScaleType          = Enum.ScaleType.Slice
Shad.SliceCenter        = Rect.new(49, 49, 450, 450)
Shad.ZIndex             = 0
Shad.Parent             = Root

-- Clip inner (so nothing bleeds out of rounded corners)
local Clip = Instance.new("Frame")
Clip.Size             = UDim2.new(1, 0, 1, 0)
Clip.BackgroundColor3 = T.BG
Clip.BorderSizePixel  = 0
Clip.ClipsDescendants = true
Clip.ZIndex           = 1
Clip.Parent           = Root
Cr(Clip, 8)

-- ─── Top Bar ──────────────────────────────────────────────────────────────────
local TopBar = Instance.new("Frame")
TopBar.Size             = UDim2.new(1, 0, 0, TOPBAR_H)
TopBar.BackgroundColor3 = T.BGDark
TopBar.BorderSizePixel  = 0
TopBar.ZIndex           = 4
TopBar.Parent           = Clip

-- bottom border line
local TBLine = Instance.new("Frame")
TBLine.Size             = UDim2.new(1, 0, 0, 1)
TBLine.Position         = UDim2.new(0, 0, 1, -1)
TBLine.BackgroundColor3 = T.Border
TBLine.BorderSizePixel  = 0
TBLine.ZIndex           = 5
TBLine.Parent           = TopBar

-- Accent gradient along very bottom of topbar (2px)
local AccBar = Instance.new("Frame")
AccBar.Size             = UDim2.new(1, 0, 0, 2)
AccBar.Position         = UDim2.new(0, 0, 1, -2)
AccBar.BackgroundColor3 = T.Accent
AccBar.BorderSizePixel  = 0
AccBar.ZIndex           = 6
AccBar.Parent           = TopBar
local ag = Instance.new("UIGradient")
ag.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   T.AccentDim),
    ColorSequenceKeypoint.new(0.5, T.Accent),
    ColorSequenceKeypoint.new(1,   T.AccentDim),
})
ag.Parent = AccBar

-- Logo circle
local Logo = Instance.new("Frame")
Logo.Size             = UDim2.new(0, 16, 0, 16)
Logo.Position         = UDim2.new(0, 12, 0.5, -8)
Logo.BackgroundColor3 = T.Accent
Logo.BorderSizePixel  = 0
Logo.ZIndex           = 6
Logo.Parent           = TopBar
Cr(Logo, 99)

local LogoInner = Instance.new("Frame")
LogoInner.Size             = UDim2.new(0, 6, 0, 6)
LogoInner.Position         = UDim2.new(0.5, -3, 0.5, -3)
LogoInner.BackgroundColor3 = T.White
LogoInner.BorderSizePixel  = 0
LogoInner.ZIndex           = 7
LogoInner.Parent           = Logo
Cr(LogoInner, 99)

-- Title
local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size             = UDim2.new(0, 120, 1, 0)
TitleLbl.Position         = UDim2.new(0, 34, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Text             = "Horizon"
TitleLbl.TextColor3       = T.White
TitleLbl.Font             = Enum.Font.GothamBold
TitleLbl.TextSize         = 14
TitleLbl.TextXAlignment   = Enum.TextXAlignment.Left
TitleLbl.ZIndex           = 6
TitleLbl.Parent           = TopBar

-- Version badge
local VerBadge = Instance.new("Frame")
VerBadge.Size             = UDim2.new(0, 42, 0, 17)
VerBadge.Position         = UDim2.new(0, 96, 0.5, -8)
VerBadge.BackgroundColor3 = T.AccentDim
VerBadge.BorderSizePixel  = 0
VerBadge.ZIndex           = 6
VerBadge.Parent           = TopBar
Cr(VerBadge, 4)
local VerLbl = Lbl(VerBadge, "0.1.1", 9, Color3.fromRGB(200, 190, 255), Enum.Font.GothamBold, Enum.TextXAlignment.Center)
VerLbl.ZIndex = 7

-- Window buttons (macOS dots)
local function MakeWinBtn(xOff, bg, sym, symColor)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 13, 0, 13)
    b.Position         = UDim2.new(1, xOff, 0.5, -6)
    b.BackgroundColor3 = bg
    b.BorderSizePixel  = 0
    b.Text             = ""
    b.ZIndex           = 7
    b.Parent           = TopBar
    Cr(b, 99)
    local sl = Instance.new("TextLabel")
    sl.Size             = UDim2.new(1, 0, 1, 0)
    sl.BackgroundTransparency = 1
    sl.Text             = sym
    sl.TextColor3       = symColor or Color3.fromRGB(90, 40, 40)
    sl.Font             = Enum.Font.GothamBold
    sl.TextSize         = 8
    sl.Visible          = false
    sl.ZIndex           = 8
    sl.Parent           = b
    b.MouseEnter:Connect(function() sl.Visible = true end)
    b.MouseLeave:Connect(function() sl.Visible = false end)
    return b
end

local CloseBtn = MakeWinBtn(-20, T.Red,    "✕", Color3.fromRGB(90,30,30))
local MinBtn   = MakeWinBtn(-38, T.Yellow, "–", Color3.fromRGB(90,60,20))

-- ─── Nav / Tab Bar ───────────────────────────────────────────────────────────
local NavBar = Instance.new("Frame")
NavBar.Size             = UDim2.new(1, 0, 0, NAV_H)
NavBar.Position         = UDim2.new(0, 0, 0, TOPBAR_H)
NavBar.BackgroundColor3 = T.NavBG
NavBar.BorderSizePixel  = 0
NavBar.ZIndex           = 4
NavBar.Parent           = Clip

local NavSep = Instance.new("Frame")
NavSep.Size             = UDim2.new(1, 0, 0, 1)
NavSep.Position         = UDim2.new(0, 0, 1, 0)
NavSep.BackgroundColor3 = T.Border
NavSep.BorderSizePixel  = 0
NavSep.ZIndex           = 5
NavSep.Parent           = NavBar

local NavList = Instance.new("UIListLayout")
NavList.FillDirection       = Enum.FillDirection.Horizontal
NavList.SortOrder           = Enum.SortOrder.LayoutOrder
NavList.VerticalAlignment   = Enum.VerticalAlignment.Center
NavList.HorizontalAlignment = Enum.HorizontalAlignment.Left
NavList.Padding             = UDim.new(0, 0)
NavList.Parent              = NavBar

local NavPad = Instance.new("UIPadding")
NavPad.PaddingLeft = UDim.new(0, 6)
NavPad.Parent      = NavBar

-- ─── Content ──────────────────────────────────────────────────────────────────
local CONT_TOP = TOPBAR_H + NAV_H + 1

local Content = Instance.new("Frame")
Content.Name             = "Content"
Content.Size             = UDim2.new(1, 0, 1, -CONT_TOP)
Content.Position         = UDim2.new(0, 0, 0, CONT_TOP)
Content.BackgroundTransparency = 1
Content.ClipsDescendants = true
Content.ZIndex           = 2
Content.Parent           = Clip

-- ─── Pages ───────────────────────────────────────────────────────────────────
local Pages = {}
local TabButtons = {}
local TABS = {"Combat", "Movement", "Misc", "Config", "GUI"}

local function NewPage(name)
    local sf = Instance.new("ScrollingFrame")
    sf.Name                = name
    sf.Size                = UDim2.new(1, 0, 1, 0)
    sf.BackgroundTransparency = 1
    sf.BorderSizePixel     = 0
    sf.ScrollBarThickness  = 2
    sf.ScrollBarImageColor3 = T.Accent
    sf.CanvasSize          = UDim2.new(0, 0, 0, 0)
    sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
    sf.Visible             = false
    sf.ZIndex              = 3
    sf.Parent              = Content

    -- Two-column grid layout
    local grid = Instance.new("UIGridLayout")
    grid.CellSize         = UDim2.new(0.5, -10, 0, MOD_H)
    grid.CellPaddingY     = UDim.new(0, 5)
    grid.CellPaddingX     = UDim.new(0, 5)
    grid.SortOrder        = Enum.SortOrder.LayoutOrder
    grid.FillDirection    = Enum.FillDirection.Horizontal
    grid.Parent           = sf

    local pad = Instance.new("UIPadding")
    pad.PaddingTop    = UDim.new(0, 10)
    pad.PaddingLeft   = UDim.new(0, 10)
    pad.PaddingRight  = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.Parent        = sf

    Pages[name] = sf
    return sf
end

-- ─── Module Tile (Vape V4 style) ─────────────────────────────────────────────
local function ModTile(page, name, desc, key, order, cb)
    local tile = Instance.new("Frame")
    tile.Name             = name
    tile.BackgroundColor3 = T.ModBG
    tile.BorderSizePixel  = 0
    tile.LayoutOrder      = order
    tile.ZIndex           = 4
    tile.Parent           = page
    Cr(tile, 5)
    St(tile, Toggles[key] and T.Accent or T.Border, 1)

    -- Left colour strip (on = accent, off = dark)
    local strip = Instance.new("Frame")
    strip.Size             = UDim2.new(0, 3, 1, 0)
    strip.Position         = UDim2.new(0, 0, 0, 0)
    strip.BackgroundColor3 = Toggles[key] and T.Accent or T.ModDis
    strip.BorderSizePixel  = 0
    strip.ZIndex           = 5
    strip.Parent           = tile
    Cr(strip, 3)

    -- Module name
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Size             = UDim2.new(1, -50, 0, 18)
    nameLbl.Position         = UDim2.new(0, 12, 0, 7)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = name
    nameLbl.TextColor3       = Toggles[key] and T.White or T.Dim
    nameLbl.Font             = Enum.Font.GothamSemibold
    nameLbl.TextSize         = 12
    nameLbl.TextXAlignment   = Enum.TextXAlignment.Left
    nameLbl.ZIndex           = 5
    nameLbl.Parent           = tile

    -- Desc
    local descLbl = Instance.new("TextLabel")
    descLbl.Size             = UDim2.new(1, -50, 0, 14)
    descLbl.Position         = UDim2.new(0, 12, 0, 24)
    descLbl.BackgroundTransparency = 1
    descLbl.Text             = desc
    descLbl.TextColor3       = T.VDim
    descLbl.Font             = Enum.Font.Gotham
    descLbl.TextSize         = 9
    descLbl.TextXAlignment   = Enum.TextXAlignment.Left
    descLbl.ZIndex           = 5
    descLbl.Parent           = tile

    -- Toggle checkbox (Vape-style small square)
    local box = Instance.new("Frame")
    box.Size             = UDim2.new(0, 16, 0, 16)
    box.Position         = UDim2.new(1, -26, 0.5, -8)
    box.BackgroundColor3 = Toggles[key] and T.Accent or T.ModDis
    box.BorderSizePixel  = 0
    box.ZIndex           = 6
    box.Parent           = tile
    Cr(box, 3)
    St(box, Toggles[key] and T.Accent or T.Border, 1)

    local checkLbl = Instance.new("TextLabel")
    checkLbl.Size             = UDim2.new(1, 0, 1, 0)
    checkLbl.BackgroundTransparency = 1
    checkLbl.Text             = Toggles[key] and "✓" or ""
    checkLbl.TextColor3       = T.White
    checkLbl.Font             = Enum.Font.GothamBold
    checkLbl.TextSize         = 10
    checkLbl.ZIndex           = 7
    checkLbl.Parent           = box

    -- Hover tween
    local tw = TweenInfo.new(0.12, Enum.EasingStyle.Quad)

    tile.MouseEnter:Connect(function()
        TweenService:Create(tile, tw, {BackgroundColor3 = T.ModBGHov}):Play()
    end)
    tile.MouseLeave:Connect(function()
        TweenService:Create(tile, tw, {BackgroundColor3 = T.ModBG}):Play()
    end)

    -- Click button
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text             = ""
    btn.ZIndex           = 8
    btn.Parent           = tile

    btn.MouseButton1Click:Connect(function()
        Toggles[key] = not Toggles[key]
        local on = Toggles[key]

        -- Animate toggle
        TweenService:Create(strip, tw, {BackgroundColor3 = on and T.Accent or T.ModDis}):Play()
        TweenService:Create(box, tw, {BackgroundColor3 = on and T.Accent or T.ModDis}):Play()
        St(tile, on and T.Accent or T.Border, 1)
        nameLbl.TextColor3 = on and T.White or T.Dim
        checkLbl.Text = on and "✓" or ""

        if cb then cb(on) end
    end)

    return tile
end

-- Empty hint
local function EmptyTile(page, text)
    local f = Instance.new("Frame")
    f.BackgroundTransparency = 1
    f.LayoutOrder = 1
    f.ZIndex = 4
    f.Parent = page

    local l = Instance.new("TextLabel")
    l.Size             = UDim2.new(1, 0, 1, 0)
    l.BackgroundTransparency = 1
    l.Text             = text
    l.TextColor3       = T.VDim
    l.Font             = Enum.Font.Gotham
    l.TextSize         = 11
    l.TextXAlignment   = Enum.TextXAlignment.Center
    l.ZIndex           = 5
    l.Parent           = f
end

-- ─── Build Pages ─────────────────────────────────────────────────────────────
local CombatPage   = NewPage("Combat")
local MovementPage = NewPage("Movement")
local MiscPage     = NewPage("Misc")
local ConfigPage   = NewPage("Config")
local GUIPage      = NewPage("GUI")

-- Combat — empty
EmptyTile(CombatPage, "No modules yet.")

-- Movement
ModTile(MovementPage, "Fly", "Free fly movement", "Fly", 1, function(on)
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if on then
        hum.PlatformStand = true
        local bg = Instance.new("BodyGyro")
        bg.MaxTorque = Vector3.new(1e5,1e5,1e5); bg.P = 1e4; bg.Name = "HFlyGyro"; bg.Parent = hrp
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.new(1e5,1e5,1e5); bv.Velocity = Vector3.zero; bv.Name = "HFlyVel"; bv.Parent = hrp
        FlyConn = RunService.Heartbeat:Connect(function()
            if not Toggles.Fly then return end
            local cam = workspace.CurrentCamera
            local dir = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W)         then dir += cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.S)         then dir -= cam.CFrame.LookVector  end
            if UserInputService:IsKeyDown(Enum.KeyCode.A)         then dir -= cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D)         then dir += cam.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space)     then dir += Vector3.yAxis          end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir -= Vector3.yAxis          end
            if dir.Magnitude > 0 then dir = dir.Unit end
            bv.Velocity = dir * 40
            bg.CFrame   = cam.CFrame
        end)
    else
        if FlyConn then FlyConn:Disconnect(); FlyConn = nil end
        local b1 = hrp and hrp:FindFirstChild("HFlyGyro")
        local b2 = hrp and hrp:FindFirstChild("HFlyVel")
        if b1 then b1:Destroy() end
        if b2 then b2:Destroy() end
        if hum then hum.PlatformStand = false end
    end
end)

ModTile(MovementPage, "Speed", "Increases walk speed", "Speed", 2, function(on)
    local char = LP.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then hum.WalkSpeed = on and 50 or BASE_SPEED end
end)

-- Misc
ModTile(MiscPage, "ESP", "Player highlight boxes", "ESP", 1, function(on)
    if on then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local sel = Instance.new("SelectionBox")
                sel.Adornee           = p.Character
                sel.Color3            = T.Accent
                sel.LineThickness     = 0.06
                sel.SurfaceTransparency = 0.82
                sel.SurfaceColor3     = T.Accent
                sel.Parent            = workspace
                ESPObjs[p.Name]       = sel
            end
        end
    else
        for _, o in pairs(ESPObjs) do o:Destroy() end
        ESPObjs = {}
    end
end)

ModTile(MiscPage, "XRay", "See players through walls", "XRay", 2, function(on)
    local function apply(char, flag)
        if not char then return end
        for _, p in ipairs(char:GetDescendants()) do
            if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
                p.LocalTransparencyModifier = flag and 0.55 or 0
            end
        end
    end
    for _, pl in ipairs(Players:GetPlayers()) do
        if pl ~= LP then apply(pl.Character, on) end
    end
end)

-- Config / GUI placeholders
EmptyTile(ConfigPage, "Settings coming soon.")
EmptyTile(GUIPage,    "UI options coming soon.")

-- ─── Tab Builder ─────────────────────────────────────────────────────────────
local function SetTab(name)
    ActiveTab = name
    for _, t in ipairs(TABS) do
        local b   = TabButtons[t]
        local act = t == name
        b.BackgroundColor3       = act and T.NavAct or T.NavIna
        b.BackgroundTransparency = act and 0 or 1
        if b:FindFirstChildOfClass("TextLabel") then
            b:FindFirstChildOfClass("TextLabel").TextColor3 = act and T.TabTxtAct or T.TabTxtIna
        end
        if Pages[t] then Pages[t].Visible = act end
    end
end

for i, tabName in ipairs(TABS) do
    local isFirst = i == 1
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, 78, 1, 0)
    btn.BackgroundColor3 = isFirst and T.NavAct or T.NavIna
    btn.BackgroundTransparency = isFirst and 0 or 1
    btn.BorderSizePixel  = 0
    btn.Text             = ""
    btn.LayoutOrder      = i
    btn.ZIndex           = 5
    btn.Parent           = NavBar
    Cr(btn, 0)

    local tl = Instance.new("TextLabel")
    tl.Size             = UDim2.new(1, 0, 1, 0)
    tl.BackgroundTransparency = 1
    tl.Text             = tabName
    tl.TextColor3       = isFirst and T.TabTxtAct or T.TabTxtIna
    tl.Font             = Enum.Font.GothamSemibold
    tl.TextSize         = 11
    tl.ZIndex           = 6
    tl.Parent           = btn

    -- bottom active indicator
    local ind = Instance.new("Frame")
    ind.Size             = UDim2.new(0.7, 0, 0, 2)
    ind.Position         = UDim2.new(0.15, 0, 1, -2)
    ind.BackgroundColor3 = T.White
    ind.BorderSizePixel  = 0
    ind.Visible          = isFirst
    ind.ZIndex           = 7
    ind.Parent           = btn

    btn.MouseButton1Click:Connect(function()
        SetTab(tabName)
        for _, tb in ipairs(TABS) do
            local ob = TabButtons[tb]
            local il = ob:FindFirstChild("Indicator") or ob:FindFirstChildOfClass("Frame")
            -- hide all indicators
        end
        ind.Visible = true
        for _, t2 in ipairs(TABS) do
            if t2 ~= tabName then
                local ob2 = TabButtons[t2]
                if ob2 then
                    local il2 = ob2:FindFirstChildOfClass("Frame")
                    if il2 then il2.Visible = false end
                end
            end
        end
    end)

    TabButtons[tabName] = btn
end

SetTab("Combat")

-- ─── Dragging ────────────────────────────────────────────────────────────────
TopBar.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        Dragging = true
        DragOff  = Vector2.new(inp.Position.X, inp.Position.Y)
                 - Vector2.new(Root.AbsolutePosition.X, Root.AbsolutePosition.Y)
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if not Dragging then return end
    if inp.UserInputType == Enum.UserInputType.MouseMovement
    or inp.UserInputType == Enum.UserInputType.Touch then
        local p   = Vector2.new(inp.Position.X, inp.Position.Y) - DragOff
        local vp  = workspace.CurrentCamera.ViewportSize
        local sz  = Root.AbsoluteSize
        p = Vector2.new(math.clamp(p.X, 0, vp.X - sz.X), math.clamp(p.Y, 0, vp.Y - sz.Y))
        Root.Position = UDim2.new(0, p.X, 0, p.Y)
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        Dragging = false
    end
end)

-- ─── Minimize ────────────────────────────────────────────────────────────────
MinBtn.MouseButton1Click:Connect(function()
    Minimized = not Minimized
    local target = Minimized and (TOPBAR_H + NAV_H) or GH
    TweenService:Create(Root, TweenInfo.new(0.18, Enum.EasingStyle.Quad),
        {Size = UDim2.new(0, GW, 0, target)}):Play()
end)

-- ─── Close ───────────────────────────────────────────────────────────────────
CloseBtn.MouseButton1Click:Connect(function()
    -- cleanup
    if FlyConn then FlyConn:Disconnect() end
    local char = LP.Character
    if char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then
            local g = hrp:FindFirstChild("HFlyGyro"); if g then g:Destroy() end
            local v = hrp:FindFirstChild("HFlyVel");  if v then v:Destroy() end
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false; hum.WalkSpeed = BASE_SPEED end
    end
    for _, o in pairs(ESPObjs) do o:Destroy() end
    SG:Destroy()
end)

print("[Horizon] Loaded.")
