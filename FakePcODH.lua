-- ============================================================
-- FAKE PC — Overdrive Hub Plugin
-- Supports: MM2 + MMV
-- ============================================================

-- ============================================================
-- 1. WAIT FOR OVERDRIVE
-- ============================================================
local shared
for i = 1, 200 do
    shared = odh_shared_plugins
    if shared then break end
    task.wait(0.1)
end

if not shared then
    warn("[Fake PC] Overdrive Hub not found.")
    return
end
if type(shared.CreateTab) ~= "function" then
    warn("[Fake PC] CreateTab missing in Overdrive Hub.")
    return
end

-- ============================================================
-- 2. MAID FRAMEWORK
-- ============================================================
local table_insert = table.insert
local maid = {}
maid.__index = maid

function maid.new()
    return setmetatable({_tasks = {}, _destroyed = false}, maid)
end
function maid:GiveTask(task)
    if self._destroyed then self:_cleanupTask(task) return end
    table_insert(self._tasks, task)
    return task
end
function maid:_cleanupTask(task)
    local t = typeof(task)
    if t == "RBXScriptConnection" then task:Disconnect()
    elseif t == "Instance" then task:Destroy()
    elseif t == "function" then task()
    elseif t == "table" and type(task.Destroy) == "function" then task:Destroy() end
end
function maid:DoCleaning()
    if self._destroyed then return end
    self._destroyed = true
    for _, task in ipairs(self._tasks) do self:_cleanupTask(task) end
    self._tasks = {}
end
function maid:Destroy() self:DoCleaning() end

local RootMaid = maid.new()

-- ============================================================
-- 3. SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer      = Players.LocalPlayer

local CoreGui
pcall(function() CoreGui = game:GetService("CoreGui") end)

-- ============================================================
-- 4. CREATE THE TAB
-- ============================================================
local myTab
local ok, err = pcall(function()
    myTab = shared.CreateTab("Fake PC", "https://raw.githubusercontent.com/emmettkyle102714-lab/FakePcODH/main/Black%20Cat.PNG.JPG")
end)

if not ok or not myTab then
    warn("[Fake PC] CreateTab failed:", err)
    return
end

print("[Fake PC] Tab created.")

-- ============================================================
-- 5. CURSOR ASSET IDS
-- ============================================================
local CURSOR_ASSETS = {
    Normal  = "rbxassetid://11703366223",
    Blue    = "rbxassetid://13337264113",
    Rainbow = "rbxassetid://78285585561050",
    Star    = "rbxassetid://107630759764794",
}

-- ============================================================
-- TAB 1: FAKE CURSORS
-- ============================================================
local cursorFeatures = {
    enabled = false,
    selected = "Normal",
    colors = {
        Normal  = Color3.fromRGB(255, 255, 255),
        Blue    = Color3.fromRGB(255, 255, 255),
        Rainbow = Color3.fromRGB(255, 255, 255),
        Star    = Color3.fromRGB(255, 255, 255),
    },
    size = 48,
}

local cursorMaid = nil
local cursorGui = nil
local cursorImage = nil
local shiftlockIcon = nil
local shiftlockGui = nil

local function buildCursorGui()
    local pg = LocalPlayer:WaitForChild("PlayerGui")

    local gui = Instance.new("ScreenGui")
    gui.Name = "FakeCursorGui"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = pg

    local img = Instance.new("ImageLabel")
    img.Name = "Cursor"
    img.BackgroundTransparency = 1
    img.Image = CURSOR_ASSETS[cursorFeatures.selected]
    img.ImageColor3 = cursorFeatures.colors[cursorFeatures.selected]
    img.Size = UDim2.new(0, cursorFeatures.size, 0, cursorFeatures.size)
    img.Position = UDim2.new(0.5, -cursorFeatures.size / 2, 0.5, -cursorFeatures.size / 2)
    img.Parent = gui

    cursorGui = gui
    cursorImage = img

    local sGui = Instance.new("ScreenGui")
    sGui.Name = "FakeShiftlockGui"
    sGui.ResetOnSpawn = false
    sGui.IgnoreGuiInset = true
    sGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sGui.Parent = pg

    local sIcon = Instance.new("ImageLabel")
    sIcon.Name = "ShiftlockIcon"
    sIcon.BackgroundTransparency = 1
    sIcon.Image = "rbxasset://textures/ui/mouseLock_on@2x.png"
    sIcon.ImageColor3 = cursorFeatures.colors[cursorFeatures.selected]
    sIcon.Size = UDim2.new(0, cursorFeatures.size, 0, cursorFeatures.size)
    sIcon.Position = UDim2.new(0.5, -cursorFeatures.size / 2, 0.5, -cursorFeatures.size / 2)
    sIcon.Visible = false
    sIcon.Parent = sGui

    shiftlockGui = sGui
    shiftlockIcon = sIcon
end

local function destroyCursorGui()
    if cursorGui then cursorGui:Destroy() cursorGui = nil end
    if shiftlockGui then shiftlockGui:Destroy() shiftlockGui = nil end
    cursorImage = nil
    shiftlockIcon = nil
end

local function refreshCursorVisual()
    if cursorImage then
        cursorImage.Image = CURSOR_ASSETS[cursorFeatures.selected]
        cursorImage.ImageColor3 = cursorFeatures.colors[cursorFeatures.selected]
        cursorImage.Size = UDim2.new(0, cursorFeatures.size, 0, cursorFeatures.size)
        cursorImage.Position = UDim2.new(0.5, -cursorFeatures.size / 2, 0.5, -cursorFeatures.size / 2)
    end
    if shiftlockIcon then
        shiftlockIcon.ImageColor3 = cursorFeatures.colors[cursorFeatures.selected]
        shiftlockIcon.Size = UDim2.new(0, cursorFeatures.size, 0, cursorFeatures.size)
        shiftlockIcon.Position = UDim2.new(0.5, -cursorFeatures.size / 2, 0.5, -cursorFeatures.size / 2)
    end
end

local function isShiftLocked()
    return UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter
end

local function updateCursorVisibility()
    if not cursorImage or not shiftlockIcon then return end
    local locked = isShiftLocked()
    cursorImage.Visible = not locked
    shiftlockIcon.Visible = locked
end

local function enableCursors()
    if cursorMaid then cursorMaid:DoCleaning() end
    cursorMaid = maid.new()
    buildCursorGui()
    cursorMaid:GiveTask(RunService.RenderStepped:Connect(updateCursorVisibility))
    cursorMaid:GiveTask(function() destroyCursorGui() end)
end

local function disableCursors()
    cursorFeatures.enabled = false
    if cursorMaid then cursorMaid:DoCleaning() cursorMaid = nil end
    destroyCursorGui()
end

local cursorSection = myTab:AddSection("Fake Cursors", "Fake mouse cursor, swaps to lock icon")
cursorSection:AddParagraph("Additional Info",
    "Shows a custom cursor in the middle of your screen.\n\n" ..
    "When you shift lock, the cursor hides and a matching shiftlock icon appears instead.\n\n" ..
    "Works in MM2 and MMV.\n\nCredits: @Emito")

cursorSection:AddToggle("Enable Fake Cursor", function(bool)
    cursorFeatures.enabled = bool
    if bool then enableCursors() else disableCursors() end
end)

cursorSection:AddDropdown("Cursor Style", {"Normal", "Blue", "Rainbow", "Star"}, "Normal", function(value)
    cursorFeatures.selected = value
    refreshCursorVisual()
end)

cursorSection:AddSlider("Cursor Size", 24, 120, 48, function(value)
    cursorFeatures.size = value
    refreshCursorVisual()
end)

cursorSection:AddColorpicker("Normal Color", Color3.fromRGB(255, 255, 255), function(color)
    cursorFeatures.colors.Normal = color
    if cursorFeatures.selected == "Normal" then refreshCursorVisual() end
end)

cursorSection:AddColorpicker("Blue Color", Color3.fromRGB(255, 255, 255), function(color)
    cursorFeatures.colors.Blue = color
    if cursorFeatures.selected == "Blue" then refreshCursorVisual() end
end)

cursorSection:AddColorpicker("Rainbow Color", Color3.fromRGB(255, 255, 255), function(color)
    cursorFeatures.colors.Rainbow = color
    if cursorFeatures.selected == "Rainbow" then refreshCursorVisual() end
end)

cursorSection:AddColorpicker("Star Color", Color3.fromRGB(255, 255, 255), function(color)
    cursorFeatures.colors.Star = color
    if cursorFeatures.selected == "Star" then refreshCursorVisual() end
end)

-- ============================================================
-- TAB 2: FAKE HOTBAR
-- ============================================================
local hotbarFeatures = { enabled = false, hideNumbers = true }
local hotbarMaid = nil
local hiddenLabels = {}

local function isNumberLabel(obj)
    if not obj:IsA("TextLabel") then return false end
    local text = obj.Text
    if not text or text == "" then return false end
    return text:match("^%d+$") ~= nil
end

local function hideLabel(label)
    if hiddenLabels[label] then return end
    hiddenLabels[label] = {
        Visible = label.Visible,
        TextTransparency = label.TextTransparency,
        TextStrokeTransparency = label.TextStrokeTransparency,
    }
    label.Visible = false
    label.TextTransparency = 1
    label.TextStrokeTransparency = 1
end

local function restoreLabel(label)
    local bak = hiddenLabels[label]
    if bak and label and label.Parent then
        label.Visible = bak.Visible
        label.TextTransparency = bak.TextTransparency
        label.TextStrokeTransparency = bak.TextStrokeTransparency
    end
    hiddenLabels[label] = nil
end

local function scanForNumbers()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return end
    local backpack = pg:FindFirstChild("Backpack")
    if not backpack then return end
    for _, obj in ipairs(backpack:GetDescendants()) do
        if isNumberLabel(obj) then hideLabel(obj) end
    end
end

local function enableHotbarFix()
    if hotbarMaid then hotbarMaid:DoCleaning() end
    hotbarMaid = maid.new()
    local pg = LocalPlayer:WaitForChild("PlayerGui")
    scanForNumbers()
    hotbarMaid:GiveTask(pg.DescendantAdded:Connect(function(obj)
        if not hotbarFeatures.enabled then return end
        if isNumberLabel(obj) then hideLabel(obj) end
    end))
    hotbarMaid:GiveTask(RunService.Heartbeat:Connect(function()
        if not hotbarFeatures.hideNumbers then return end
        scanForNumbers()
    end))
    hotbarMaid:GiveTask(function()
        for label, _ in pairs(hiddenLabels) do restoreLabel(label) end
        hiddenLabels = {}
    end)
end

local function disableHotbarFix()
    hotbarFeatures.enabled = false
    if hotbarMaid then hotbarMaid:DoCleaning() hotbarMaid = nil end
    for label, _ in pairs(hiddenLabels) do restoreLabel(label) end
    hiddenLabels = {}
end

local hotbarSection = myTab:AddSection("Fake Hotbar", "Looks like PC — no 1-9 numbers")
hotbarSection:AddParagraph("Additional Info",
    "Hides the number labels (1, 2, 3...) from your hotbar so it looks like you're on PC.\n\n" ..
    "You still tap tools to equip them normally.\n\nCredits: @Emito")

hotbarSection:AddToggle("Hide Hotbar Numbers", function(bool)
    hotbarFeatures.enabled = bool
    if bool then enableHotbarFix() else disableHotbarFix() end
end)

-- ============================================================
-- TAB 3: MOBILE FEATURES REMOVED
-- ============================================================
local mobileFeatures = {
    removeJoystick = false,
    hideJoystick = false,
    removeRun = false,
    hideRun = false,
}

local mobileMaid = nil
local joystickBackup = {}
local runBackup = {}

local function getTouchGui()
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if not pg then return nil end
    return pg:FindFirstChild("TouchGui")
end

local function getTouchControlFrame()
    local tg = getTouchGui()
    if not tg then return nil end
    return tg:FindFirstChild("TouchControlFrame")
end

local function getJoystick()
    local tcf = getTouchControlFrame()
    if not tcf then return nil end
    return tcf:FindFirstChild("Thumbstick")
        or tcf:FindFirstChild("DynamicThumbstick")
        or tcf:FindFirstChild("Joystick")
end

local function getRunButton()
    local tcf = getTouchControlFrame()
    if not tcf then return nil end
    for _, obj in ipairs(tcf:GetDescendants()) do
        if obj:IsA("GuiButton") or obj:IsA("ImageButton") then
            local n = obj.Name:lower()
            if n:find("sprint") or n:find("run") then return obj end
        end
    end
    return tcf:FindFirstChild("ButtonA")
end

local function applyJoystick()
    local joy = getJoystick()
    if not joy then return end
    if mobileFeatures.removeJoystick then
        joy:Destroy()
    elseif mobileFeatures.hideJoystick then
        if not joystickBackup[joy] then
            joystickBackup[joy] = {
                Visible = joy.Visible,
                ImageTransparency = joy:IsA("ImageLabel") and joy.ImageTransparency or nil,
                BackgroundTransparency = joy:IsA("GuiObject") and joy.BackgroundTransparency or nil,
            }
        end
        pcall(function() joy.Visible = false end)
        if joy:IsA("ImageLabel") then pcall(function() joy.ImageTransparency = 1 end) end
        if joy:IsA("GuiObject") then pcall(function() joy.BackgroundTransparency = 1 end) end
    end
end

local function restoreJoystick()
    for joy, bak in pairs(joystickBackup) do
        if bak and joy and joy.Parent then
            pcall(function() joy.Visible = bak.Visible end)
            if joy:IsA("ImageLabel") then pcall(function() joy.ImageTransparency = bak.ImageTransparency end) end
            if joy:IsA("GuiObject") then pcall(function() joy.BackgroundTransparency = bak.BackgroundTransparency end) end
        end
    end
    joystickBackup = {}
end

local function applyRunButton()
    local btn = getRunButton()
    if not btn then return end
    if mobileFeatures.removeRun then
        btn:Destroy()
    elseif mobileFeatures.hideRun then
        if not runBackup[btn] then
            runBackup[btn] = {
                Visible = btn.Visible,
                ImageTransparency = btn:IsA("ImageLabel") and btn.ImageTransparency or nil,
                BackgroundTransparency = btn:IsA("GuiObject") and btn.BackgroundTransparency or nil,
            }
        end
        pcall(function() btn.Visible = false end)
        if btn:IsA("ImageLabel") then pcall(function() btn.ImageTransparency = 1 end) end
        if btn:IsA("GuiObject") then pcall(function() btn.BackgroundTransparency = 1 end) end
    end
end

local function restoreRunButton()
    for btn, bak in pairs(runBackup) do
        if bak and btn and btn.Parent then
            pcall(function() btn.Visible = bak.Visible end)
            if btn:IsA("ImageLabel") then pcall(function() btn.ImageTransparency = bak.ImageTransparency end) end
            if btn:IsA("GuiObject") then pcall(function() btn.BackgroundTransparency = bak.BackgroundTransparency end) end
        end
    end
    runBackup = {}
end

local function enableMobileFeatures()
    if mobileMaid then mobileMaid:DoCleaning() end
    mobileMaid = maid.new()
    applyJoystick()
    applyRunButton()
    mobileMaid:GiveTask(RunService.Heartbeat:Connect(function()
        if mobileFeatures.removeJoystick or mobileFeatures.hideJoystick then applyJoystick() end
        if mobileFeatures.removeRun or mobileFeatures.hideRun then applyRunButton() end
    end))
end

local function disableMobileFeatures()
    mobileFeatures.removeJoystick = false
    mobileFeatures.hideJoystick = false
    mobileFeatures.removeRun = false
    mobileFeatures.hideRun = false
    if mobileMaid then mobileMaid:DoCleaning() mobileMaid = nil end
    restoreJoystick()
    restoreRunButton()
end

local mobileSection = myTab:AddSection("Mobile Features Removed", "Joystick + run button controls")
mobileSection:AddParagraph("Additional Info",
    "Remove or hide the mobile joystick and run button.\n\n" ..
    "Remove = fully gone (can't interact)\n" ..
    "Hide = invisible but still touchable\n\nCredits: @Emito")

mobileSection:AddToggle("Remove Joystick", function(bool)
    mobileFeatures.removeJoystick = bool
    if bool then mobileFeatures.hideJoystick = false end
    restoreJoystick()
    enableMobileFeatures()
end)

mobileSection:AddToggle("Hide Joystick", function(bool)
    mobileFeatures.hideJoystick = bool
    if bool then mobileFeatures.removeJoystick = false end
    restoreJoystick()
    enableMobileFeatures()
end)

mobileSection:AddToggle("Remove Run Button", function(bool)
    mobileFeatures.removeRun = bool
    if bool then mobileFeatures.hideRun = false end
    restoreRunButton()
    enableMobileFeatures()
end)

mobileSection:AddToggle("Hide Run Button", function(bool)
    mobileFeatures.hideRun = bool
    if bool then mobileFeatures.removeRun = false end
    restoreRunButton()
    enableMobileFeatures()
end)

-- ============================================================
-- TAB 4: STREAMER MODE
-- ============================================================
local streamerFeatures = {
    enabled = false,
    hideExecutor = true,
    hideHub = true,
    hideNotify = true,
}

local streamerMaid = nil
local hiddenStreamerGui = {}

local STREAMER_KEYWORDS = {
    "delta", "krnl", "fluxus", "hydrogen", "codex", "scriptware", "script-ware",
    "synapse", "wave", "swift", "argon", "electron", "sirhurt", "wearedevs",
    "watermark", "executor", "exploit", "cheat", "hyperion",
    "overdrivedev", "overdrive", "odh",
}

local function isStreamerTarget(obj)
    local n = obj.Name:lower()
    for _, kw in ipairs(STREAMER_KEYWORDS) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

local function getReachableContainers()
    local containers = {}
    local pg = LocalPlayer:FindFirstChild("PlayerGui")
    if pg then table.insert(containers, pg) end
    if CoreGui then pcall(function() table.insert(containers, CoreGui) end) end
    if gethui then
        pcall(function() table.insert(containers, gethui()) end)
    end
    return containers
end

local function hideStreamerGui(obj)
    if hiddenStreamerGui[obj] then return end
    hiddenStreamerGui[obj] = {
        Enabled = obj:IsA("ScreenGui") and obj.Enabled or nil,
        Visible = obj:IsA("GuiObject") and obj.Visible or nil,
    }
    pcall(function() obj.Enabled = false end)
    pcall(function() obj.Visible = false end)
end

local function showStreamerGui(obj)
    local bak = hiddenStreamerGui[obj]
    if bak and obj and obj.Parent then
        if bak.Enabled ~= nil then pcall(function() obj.Enabled = bak.Enabled end) end
        if bak.Visible ~= nil then pcall(function() obj.Visible = bak.Visible end) end
    end
    hiddenStreamerGui[obj] = nil
end

local function scanAndHide()
    if not streamerFeatures.enabled then return end
    for _, container in ipairs(getReachableContainers()) do
        for _, obj in ipairs(container:GetDescendants()) do
            if obj:IsA("ScreenGui") or obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("TextLabel") then
                if obj.Name ~= "FakeCursorGui" and obj.Name ~= "FakeShiftlockGui" then
                    if isStreamerTarget(obj) then hideStreamerGui(obj) end
                end
            end
        end
    end
end

local function enableStreamer()
    if streamerMaid then streamerMaid:DoCleaning() end
    streamerMaid = maid.new()
    scanAndHide()
    streamerMaid:GiveTask(RunService.Heartbeat:Connect(scanAndHide))
    if streamerFeatures.hideHub then
        pcall(function()
            if shared.SetTabVisible then shared.SetTabVisible(false)
            elseif shared.HideTab then shared.HideTab() end
        end)
    end
end

local function disableStreamer()
    streamerFeatures.enabled = false
    if streamerMaid then streamerMaid:DoCleaning() streamerMaid = nil end
    for obj, _ in pairs(hiddenStreamerGui) do showStreamerGui(obj) end
    hiddenStreamerGui = {}
    pcall(function()
        if shared.SetTabVisible then shared.SetTabVisible(true)
        elseif shared.ShowTab then shared.ShowTab() end
    end)
end

local function unhideEverything()
    streamerFeatures.enabled = false
    disableStreamer()
    if shared.Notify then shared.Notify("Streamer Mode: unhidden", 2) end
end

local streamerSection = myTab:AddSection("Streamer Mode", "Hide executor stuff while recording")
streamerSection:AddParagraph("Additional Info",
    "Hides executor watermarks (Delta, Krnl, Fluxus, etc.) and hub icons so your screen recording looks clean.\n\n" ..
    "Some executor watermarks are drawn natively on iOS and CANNOT be hidden by any script.\n\nCredits: @Emito")

streamerSection:AddToggle("Enable Streamer Mode", function(bool)
    streamerFeatures.enabled = bool
    if bool then enableStreamer() else disableStreamer() end
end)

streamerSection:AddToggle("Hide Executor Watermark", function(bool)
    streamerFeatures.hideExecutor = bool
end)

streamerSection:AddToggle("Hide Hub Icon", function(bool)
    streamerFeatures.hideHub = bool
    if streamerFeatures.enabled then
        if bool then
            pcall(function()
                if shared.SetTabVisible then shared.SetTabVisible(false)
                elseif shared.HideTab then shared.HideTab() end
            end)
        else
            pcall(function()
                if shared.SetTabVisible then shared.SetTabVisible(true)
                elseif shared.ShowTab then shared.ShowTab() end
            end)
        end
    end
end)

streamerSection:AddToggle("Hide Notifications", function(bool)
    streamerFeatures.hideNotify = bool
end)

streamerSection:AddButton("Unhide Everything", function()
    unhideEverything()
end)

-- ============================================================
-- CLEANUP
-- ============================================================
RootMaid:GiveTask(function()
    disableCursors()
    disableHotbarFix()
    disableMobileFeatures()
    disableStreamer()
end)

print("[Fake PC] Loaded successfully.")
