-- Fox's ModCheck v2.1 – Axiom Edition (fixed)
-- Auto-detects mods, crown owners, shield owners, and watchlist players

local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- ==================== WATCHLIST (all lowercase) ====================
local WATCH_NAMES = {
    ["lui20102"]              = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["skylerosen140"]         = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["wtskae"]                = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["void6rs"]               = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["reavvvvvvvvvvvvvvvvv"]  = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["ryrycanhoop"]           = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["wwallets"]              = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["growagardencameron4"]   = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["al3x6z"]                = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
    ["stezzifl"]              = { label = "Watchlist", color = Color3.fromRGB(255,60,60) },
}

-- Crown/mod detection keywords in DisplayName or Name
-- Removed "mod" and "moderator" to stop false positives like "berrymodels"
-- Added shield emoji 🛡️
local MOD_KEYWORDS = {
    "👑", "🔰", "🛡️",
}

-- Track already warned so we dont double-alert
local warned = {}

-- ==================== SOUND ====================
local function playAlert(pitch)
    pitch = pitch or 1
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9125230493"
    sound.Volume = 1
    sound.PlaybackSpeed = pitch
    sound.Parent = SoundService
    sound:Play()
    Debris:AddItem(sound, 3)
end

-- ==================== GUI ====================
local C = {
    bg      = Color3.fromRGB(13,13,18),
    surface = Color3.fromRGB(20,20,28),
    border  = Color3.fromRGB(40,40,56),
    text    = Color3.fromRGB(215,215,225),
    subtext = Color3.fromRGB(130,130,150),
    dim     = Color3.fromRGB(70,70,90),
    accent  = Color3.fromRGB(110,85,255),
    red     = Color3.fromRGB(215,55,55),
    orange  = Color3.fromRGB(250,130,0),
    green   = Color3.fromRGB(45,195,95),
}

-- Notification queue
local notifQueue = {}
local notifActive = false

local function makeNotif(title, body, col)
    col = col or C.red

    local gui = Instance.new("ScreenGui")
    gui.Name = "FoxModCheckNotif"
    gui.ResetOnSpawn = false
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    pcall(function() gui.Parent = game:GetService("CoreGui") end)
    if not gui.Parent then gui.Parent = LocalPlayer.PlayerGui end

    local frame = Instance.new("Frame", gui)
    frame.Size = UDim2.new(0, 340, 0, 90)
    frame.Position = UDim2.new(1, 10, 0, 10) -- start off screen right
    frame.BackgroundColor3 = C.bg
    frame.BorderSizePixel = 0
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", frame)
    stroke.Color = col; stroke.Thickness = 1.5; stroke.Transparency = 0.3

    -- left accent bar
    local bar = Instance.new("Frame", frame)
    bar.Size = UDim2.new(0, 4, 1, 0)
    bar.BackgroundColor3 = col; bar.BorderSizePixel = 0
    Instance.new("UICorner", bar).CornerRadius = UDim.new(0, 10)

    -- icon
    local icon = Instance.new("TextLabel", frame)
    icon.Size = UDim2.new(0, 36, 0, 36)
    icon.Position = UDim2.new(0, 14, 0.5, -18)
    icon.BackgroundTransparency = 1
    icon.TextColor3 = col
    icon.Font = Enum.Font.GothamBold
    icon.TextSize = 24
    icon.Text = "⚠"

    -- title
    local titleLbl = Instance.new("TextLabel", frame)
    titleLbl.Size = UDim2.new(1, -70, 0, 28)
    titleLbl.Position = UDim2.new(0, 54, 0, 10)
    titleLbl.BackgroundTransparency = 1
    titleLbl.TextColor3 = col
    titleLbl.Font = Enum.Font.GothamBold
    titleLbl.TextSize = 13
    titleLbl.TextXAlignment = Enum.TextXAlignment.Left
    titleLbl.Text = title

    -- body
    local bodyLbl = Instance.new("TextLabel", frame)
    bodyLbl.Size = UDim2.new(1, -70, 0, 22)
    bodyLbl.Position = UDim2.new(0, 54, 0, 36)
    bodyLbl.BackgroundTransparency = 1
    bodyLbl.TextColor3 = C.subtext
    bodyLbl.Font = Enum.Font.Code
    bodyLbl.TextSize = 11
    bodyLbl.TextXAlignment = Enum.TextXAlignment.Left
    bodyLbl.TextWrapped = true
    bodyLbl.Text = body

    -- progress bar
    local prog = Instance.new("Frame", frame)
    prog.Size = UDim2.new(1, -8, 0, 3)
    prog.Position = UDim2.new(0, 4, 1, -5)
    prog.BackgroundColor3 = col; prog.BorderSizePixel = 0
    Instance.new("UICorner", prog).CornerRadius = UDim.new(0, 2)

    -- close btn
    local xBtn = Instance.new("TextButton", frame)
    xBtn.Size = UDim2.new(0, 22, 0, 22)
    xBtn.Position = UDim2.new(1, -26, 0, 4)
    xBtn.BackgroundTransparency = 1
    xBtn.TextColor3 = C.dim; xBtn.Font = Enum.Font.GothamBold
    xBtn.TextSize = 14; xBtn.Text = "×"
    xBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

    -- SLIDE IN
    local tween = game:GetService("TweenService")
    local tweenInfo = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
    tween:Create(frame, tweenInfo, {Position = UDim2.new(1,-350,0,10)}):Play()

    -- PROGRESS shrink then slide out
    task.spawn(function()
        local duration = 8
        local t0 = tick()
        while tick()-t0 < duration do
            local frac = 1 - (tick()-t0)/duration
            if prog and prog.Parent then
                prog.Size = UDim2.new(frac, -8, 0, 3)
            else break end
            task.wait(0.05)
        end
        if frame and frame.Parent then
            tween:Create(frame, tweenInfo, {Position = UDim2.new(1,10,0,10)}):Play()
            task.wait(0.4)
        end
        if gui and gui.Parent then gui:Destroy() end
    end)

    return gui
end

-- ==================== DETECTION ====================
local function isCrown(p)
    -- check display name and username for crown emoji and mod keywords
    local dn = (p.DisplayName or ""):lower()
    local un = (p.Name or ""):lower()
    for _, kw in ipairs(MOD_KEYWORDS) do
        if dn:find(kw, 1, true) or un:find(kw, 1, true) then
            return true, kw
        end
    end
    return false, nil
end

local function isVerifiedMod(p)
    -- check if they have a special badge/rank in the game's leaderboard data
    -- also check if they have admin tag in PlayerGui or character tags
    local char = p.Character
    if char then
        for _, desc in ipairs(char:GetDescendants()) do
            local n = tostring(desc.Name):lower()
            if n:find("admin") or n:find("mod") or n:find("staff") or n:find("crown") then
                return true, desc.Name
            end
            if desc:IsA("TextLabel") or desc:IsA("StringValue") then
                local v = tostring(desc.Value ~= "" and desc.Value or desc.Text):lower()
                if v:find("👑") or v:find("mod") or v:find("admin") then
                    return true, tostring(desc.Name) .. "=" .. v
                end
            end
        end
    end
    -- check PlayerGui tags
    local pg = p:FindFirstChild("PlayerGui")
    if pg then
        for _, desc in ipairs(pg:GetDescendants()) do
            local n = tostring(desc.Name):lower()
            if n:find("admin") or n:find("mod") or n:find("crown") then
                return true, desc.Name
            end
        end
    end
    return false, nil
end

local function checkPlayer(p)
    if p == LocalPlayer then return end
    local key = p.UserId

    -- WATCHLIST CHECK (fixed: always lowercase)
    local nameL = p.Name:lower()
    local watchEntry = WATCH_NAMES[nameL]
    if watchEntry and not warned[key .. "_watch"] then
        warned[key .. "_watch"] = true
        playAlert(1.1)
        makeNotif(
            "⚠ WATCHLIST — " .. watchEntry.label,
            p.Name .. " joined the server",
            watchEntry.color
        )
        warn("[ModCheck] WATCHLIST:", p.Name)
    end

    -- CROWN / MOD KEYWORD CHECK
    local hasCrown, keyword = isCrown(p)
    if hasCrown and not warned[key .. "_crown"] then
        warned[key .. "_crown"] = true
        playAlert(0.9)
        makeNotif(
            "👑 MOD/CROWN DETECTED",
            p.Name .. " | keyword: " .. tostring(keyword),
            C.orange
        )
        warn("[ModCheck] CROWN/MOD:", p.Name, "keyword:", keyword)
    end

    -- CHARACTER TAG CHECK (runs after char loads)
    if not warned[key .. "_tag"] then
        local function checkChar()
            task.wait(2) -- wait for char to fully load
            if not p or not p.Parent then return end
            local isMod, tag = isVerifiedMod(p)
            if isMod and not warned[key .. "_tag"] then
                warned[key .. "_tag"] = true
                playAlert(0.8)
                makeNotif(
                    "🔰 IN-GAME MOD TAG",
                    p.Name .. " has mod tag: " .. tostring(tag),
                    C.orange
                )
                warn("[ModCheck] IN-GAME TAG:", p.Name, tag)
            end
        end
        if p.Character then
            task.spawn(checkChar)
        end
        p.CharacterAdded:Connect(function() task.spawn(checkChar) end)
    end
end

-- INITIAL SCAN (catches anyone already in server when script runs)
for _, p in ipairs(Players:GetPlayers()) do
    task.spawn(checkPlayer, p)
end

-- NEW JOINS
Players.PlayerAdded:Connect(function(p)
    task.spawn(checkPlayer, p)
end)

-- RECHECK LOOP (every 10s — catches crown changes mid-game)
task.spawn(function()
    while true do
        task.wait(10)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                -- only recheck crown/tag, not watchlist (already warned)
                local key = p.UserId
                if not warned[key .. "_crown"] then
                    local hasCrown, keyword = isCrown(p)
                    if hasCrown then
                        warned[key .. "_crown"] = true
                        playAlert(0.9)
                        makeNotif(
                            "👑 MOD/CROWN DETECTED (late)",
                            p.Name .. " | " .. tostring(keyword),
                            C.orange
                        )
                    end
                end
                if not warned[key .. "_tag"] then
                    local isMod, tag = isVerifiedMod(p)
                    if isMod then
                        warned[key .. "_tag"] = true
                        playAlert(0.8)
                        makeNotif(
                            "🔰 MOD TAG (late detect)",
                            p.Name .. " | " .. tostring(tag),
                            C.orange
                        )
                    end
                end
            end
        end
    end
end)

print("[ModCheck v2.1] Running boss man — watching " .. tostring(#(function() local t={} for k in pairs(WATCH_NAMES) do table.insert(t,k) end return t end)()) .. " names.")
