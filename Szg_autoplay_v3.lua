-- SZG Auto Play | discord.gg/MSJyWr49a
-- clean,lockable,Szg is ur daddy

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Player = Players.LocalPlayer

-- ========== WAYPOINTS ==========
local leftWaypoints = {
    Vector3.new(-476.85, -6.59, 94.91),
    Vector3.new(-485.55, -4.53, 100.61),
    Vector3.new(-475.60, -6.59, 92.80),
    Vector3.new(-475.26, -6.57, 21.54),
}
local rightWaypoints = {
    Vector3.new(-475.77, -6.57, 26.76),
    Vector3.new(-485.85, -4.48, 20.13),
    Vector3.new(-475.83, -6.59, 26.54),
    Vector3.new(-476.17, -6.09, 97.73),
}

-- ========== CONFIG ==========
local ConfigFileName = "SZG_AutoPlay_Speeds.json"
local Values = { GoingSpeed = 55, StealSpeed = 29 }

local function loadConfig()
    if not readfile or not isfile then return end
    pcall(function()
        if isfile(ConfigFileName) then
            local data = HttpService:JSONDecode(readfile(ConfigFileName))
            Values.GoingSpeed = data.GoingSpeed or 55
            Values.StealSpeed = data.StealSpeed or 29
        end
    end)
end

local function saveConfig()
    if not writefile then return end
    pcall(function()
        writefile(ConfigFileName, HttpService:JSONEncode(Values))
    end)
end
loadConfig()

-- ========== PROXY ==========
local proxy = nil
local function ensureProxy()
    local char = Player.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end
    if not proxy or proxy.Parent ~= char then
        if proxy then proxy:Destroy() end
        proxy = Instance.new("Part")
        proxy.Name = "SZG_AutoPlayProxy"
        proxy.Size = Vector3.new(1,1,1)
        proxy.Transparency = 1
        proxy.CanCollide = false
        proxy.Massless = true
        proxy.Parent = char
        local weld = Instance.new("Weld")
        weld.Part0 = hrp
        weld.Part1 = proxy
        weld.C0 = CFrame.new(0,0,0)
        weld.Parent = proxy
    end
    return proxy
end

-- ========== MOVEMENT HELPER ==========
local function moveTo(target, speed)
    local hrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local dir = (target - hrp.Position)
    local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
    local hum = Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:Move(moveDir, false) end
    if proxy then
        local currentVel = proxy.AssemblyLinearVelocity
        proxy.AssemblyLinearVelocity = Vector3.new(moveDir.X * speed, currentVel.Y, moveDir.Z * speed)
    end
end

local function stopMoving()
    if proxy then proxy.AssemblyLinearVelocity = Vector3.new(0,0,0) end
    local hum = Player.Character and Player.Character:FindFirstChildOfClass("Humanoid")
    if hum then hum:Move(Vector3.zero, false) end
end

-- ========== PATROL LOGIC (simple sequential) ==========
local activeConnection = nil
local activeWaypoints = nil
local waypointIndex = 1
local currentPhase = 1  -- 1-2 going speed, 3-4 steal speed

local function startPatrol(waypoints)
    if activeConnection then activeConnection:Disconnect() end
    activeWaypoints = waypoints
    waypointIndex = 1
    currentPhase = 1
    ensureProxy()
    activeConnection = RunService.Stepped:Connect(function()
        if not activeWaypoints then return end
        local char = Player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local target = activeWaypoints[waypointIndex]
        if not target then return end

        local dist = (target - hrp.Position).Magnitude
        local speed = (currentPhase <= 2) and Values.GoingSpeed or Values.StealSpeed
        if dist < 2.5 then
            waypointIndex = waypointIndex + 1
            if waypointIndex > #activeWaypoints then
                activeConnection:Disconnect()
                activeConnection = nil
                activeWaypoints = nil
                if Enabled.AutoLeft then
                    Enabled.AutoLeft = false
                    if updateButtonUI then updateButtonUI() end
                elseif Enabled.AutoRight then
                    Enabled.AutoRight = false
                    if updateButtonUI then updateButtonUI() end
                end
                stopMoving()
                return
            end
            if waypointIndex == 3 then
                currentPhase = 3
            end
        else
            moveTo(target, speed)
        end
    end)
end

local function stopPatrol()
    if activeConnection then activeConnection:Disconnect(); activeConnection = nil end
    activeWaypoints = nil
    waypointIndex = 1
    stopMoving()
end

-- ========== UI ==========
local Enabled = { AutoLeft = false, AutoRight = false }
local isLocked = false
local updateButtonUI = nil

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SZGAutoPlay"
screenGui.ResetOnSpawn = false
pcall(function()
    if gethui then screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(screenGui) screenGui.Parent = game:GetService("CoreGui")
    else screenGui.Parent = Player:WaitForChild("PlayerGui") end
end)

-- ===== PANEL =====
-- Total height: 26 (title) + 8 (pad) + 22 (going slider) + 6 + 22 (steal slider) + 8 + 24 (left btn) + 6 + 24 (right btn) + 8 = 154
local panelH = 158
local panelW = 180

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, panelW, 0, panelH)
panel.Position = UDim2.new(0.5, -panelW/2, 0.5, -panelH/2)
panel.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
panel.BackgroundTransparency = 0
panel.BorderSizePixel = 0
panel.Parent = screenGui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 6)
local stroke = Instance.new("UIStroke", panel)
stroke.Color = Color3.fromRGB(80, 80, 90)
stroke.Thickness = 1.5

-- ===== TITLE BAR =====
local titleBar = Instance.new("Frame", panel)
titleBar.Size = UDim2.new(1, 0, 0, 26)
titleBar.BackgroundTransparency = 1

local title = Instance.new("TextLabel", titleBar)
title.Size = UDim2.new(0.75, 0, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.BackgroundTransparency = 1
title.Text = "SZG Auto Play"
title.TextColor3 = Color3.fromRGB(220, 220, 230)
title.Font = Enum.Font.GothamBold
title.TextSize = 10
title.TextXAlignment = Enum.TextXAlignment.Left

local discordSub = Instance.new("TextLabel", titleBar)
discordSub.Size = UDim2.new(0.75, 0, 1, 0)
discordSub.Position = UDim2.new(0, 8, 0, 13)
discordSub.BackgroundTransparency = 1
discordSub.Text = "discord.gg/MSJyWr49a"
discordSub.TextColor3 = Color3.fromRGB(160, 160, 170)
discordSub.Font = Enum.Font.Gotham
discordSub.TextSize = 7

local lockBtn = Instance.new("TextButton", titleBar)
lockBtn.Size = UDim2.new(0, 20, 0, 20)
lockBtn.Position = UDim2.new(1, -26, 0, 3)
lockBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
lockBtn.Text = "🔓"
lockBtn.TextColor3 = Color3.fromRGB(220, 220, 230)
lockBtn.Font = Enum.Font.GothamBold
lockBtn.TextSize = 12
lockBtn.AutoButtonColor = false
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 4)

-- ===== DRAG =====
local dragging = false
local dragStart, startPos
titleBar.InputBegan:Connect(function(input)
    if isLocked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = panel.Position
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if not dragging or isLocked then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStart
        panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)
lockBtn.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    lockBtn.Text = isLocked and "🔒" or "🔓"
    lockBtn.BackgroundColor3 = isLocked and Color3.fromRGB(80, 80, 100) or Color3.fromRGB(45, 45, 55)
end)

-- ===== CONTENT AREA =====
local content = Instance.new("Frame", panel)
content.Size = UDim2.new(1, -16, 1, -34)
content.Position = UDim2.new(0, 8, 0, 30)
content.BackgroundTransparency = 1

-- ===== SLIDER HELPER =====
-- Creates a label row + slider bar. Returns the slider frame.
-- minVal/maxVal define the range, key = Values key to update.
local sliderDragging = {}

local function makeSlider(yPos, labelText, key, minVal, maxVal)
    -- Row label + value display
    local rowFrame = Instance.new("Frame", content)
    rowFrame.Size = UDim2.new(1, 0, 0, 22)
    rowFrame.Position = UDim2.new(0, 0, 0, yPos)
    rowFrame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", rowFrame)
    lbl.Size = UDim2.new(0.62, 0, 0, 13)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(200, 200, 210)
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 9
    lbl.TextXAlignment = Enum.TextXAlignment.Left

    local valLbl = Instance.new("TextLabel", rowFrame)
    valLbl.Size = UDim2.new(0.38, 0, 0, 13)
    valLbl.Position = UDim2.new(0.62, 0, 0, 0)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(Values[key])
    valLbl.TextColor3 = Color3.fromRGB(255, 215, 80)
    valLbl.Font = Enum.Font.GothamBold
    valLbl.TextSize = 9
    valLbl.TextXAlignment = Enum.TextXAlignment.Right

    -- Track background
    local track = Instance.new("Frame", rowFrame)
    track.Size = UDim2.new(1, 0, 0, 7)
    track.Position = UDim2.new(0, 0, 0, 15)
    track.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    track.BorderSizePixel = 0
    Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

    -- Fill bar
    local fill = Instance.new("Frame", track)
    fill.Size = UDim2.new((Values[key] - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(100, 100, 200)
    fill.BorderSizePixel = 0
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    -- Thumb
    local thumb = Instance.new("Frame", track)
    thumb.Size = UDim2.new(0, 11, 0, 11)
    thumb.AnchorPoint = Vector2.new(0.5, 0.5)
    local thumbPct = (Values[key] - minVal) / (maxVal - minVal)
    thumb.Position = UDim2.new(thumbPct, 0, 0.5, 0)
    thumb.BackgroundColor3 = Color3.fromRGB(220, 220, 255)
    thumb.BorderSizePixel = 0
    Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

    -- Update visuals
    local function updateVisual(pct)
        pct = math.clamp(pct, 0, 1)
        local val = math.round(minVal + pct * (maxVal - minVal))
        Values[key] = val
        valLbl.Text = tostring(val)
        fill.Size = UDim2.new(pct, 0, 1, 0)
        thumb.Position = UDim2.new(pct, 0, 0.5, 0)
        saveConfig()
    end

    -- Input handling on track
    local function onInput(input)
        if sliderDragging[key] then
            local trackAbsPos = track.AbsolutePosition.X
            local trackAbsSize = track.AbsoluteSize.X
            local pct = (input.Position.X - trackAbsPos) / trackAbsSize
            updateVisual(pct)
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging[key] = true
            local trackAbsPos = track.AbsolutePosition.X
            local trackAbsSize = track.AbsoluteSize.X
            local pct = (input.Position.X - trackAbsPos) / trackAbsSize
            updateVisual(pct)
        end
    end)
    track.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging[key] = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            onInput(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            sliderDragging[key] = false
        end
    end)
end

-- Going Speed: 15–60
makeSlider(0, "Auto Play Speed", "GoingSpeed", 15, 60)

-- Steal Speed: 15–31
makeSlider(30, "Steal Speed", "StealSpeed", 15, 31)

-- ===== BUTTONS =====
local leftBtn = Instance.new("TextButton", content)
leftBtn.Size = UDim2.new(1, 0, 0, 24)
leftBtn.Position = UDim2.new(0, 0, 0, 62)
leftBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
leftBtn.Text = "AUTO LEFT: OFF"
leftBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
leftBtn.Font = Enum.Font.GothamBold
leftBtn.TextSize = 10
leftBtn.AutoButtonColor = false
Instance.new("UICorner", leftBtn).CornerRadius = UDim.new(0, 4)

local rightBtn = Instance.new("TextButton", content)
rightBtn.Size = UDim2.new(1, 0, 0, 24)
rightBtn.Position = UDim2.new(0, 0, 0, 92)
rightBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
rightBtn.Text = "AUTO RIGHT: OFF"
rightBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
rightBtn.Font = Enum.Font.GothamBold
rightBtn.TextSize = 10
rightBtn.AutoButtonColor = false
Instance.new("UICorner", rightBtn).CornerRadius = UDim.new(0, 4)

updateButtonUI = function()
    leftBtn.BackgroundColor3 = Enabled.AutoLeft and Color3.fromRGB(80, 80, 100) or Color3.fromRGB(45, 45, 55)
    leftBtn.Text = Enabled.AutoLeft and "AUTO LEFT: ON" or "AUTO LEFT: OFF"
    rightBtn.BackgroundColor3 = Enabled.AutoRight and Color3.fromRGB(80, 80, 100) or Color3.fromRGB(45, 45, 55)
    rightBtn.Text = Enabled.AutoRight and "AUTO RIGHT: ON" or "AUTO RIGHT: OFF"
end

leftBtn.MouseButton1Click:Connect(function()
    if Enabled.AutoLeft then
        stopPatrol()
        Enabled.AutoLeft = false
        updateButtonUI()
    else
        stopPatrol()
        Enabled.AutoRight = false
        Enabled.AutoLeft = true
        updateButtonUI()
        startPatrol(leftWaypoints)
    end
end)

rightBtn.MouseButton1Click:Connect(function()
    if Enabled.AutoRight then
        stopPatrol()
        Enabled.AutoRight = false
        updateButtonUI()
    else
        stopPatrol()
        Enabled.AutoLeft = false
        Enabled.AutoRight = true
        updateButtonUI()
        startPatrol(rightWaypoints)
    end
end)

updateButtonUI()

-- Auto-anti drop
RunService.Stepped:Connect(function()
    local c = Player.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp and hrp.Position.Y < -10 then
            hrp.Position = Vector3.new(hrp.Position.X, -6.5, hrp.Position.Z)
        end
    end
end)

Player.CharacterAdded:Connect(function()
    task.wait(0.8)
    if Enabled.AutoLeft then
        stopPatrol()
        startPatrol(leftWaypoints)
    elseif Enabled.AutoRight then
        stopPatrol()
        startPatrol(rightWaypoints)
    end
end)

print("✅ SZG Auto Play v3")
