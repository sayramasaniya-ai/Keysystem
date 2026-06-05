local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local LP = Players.LocalPlayer

local State = {
        infJumpEnabled = false,
        infJumpMode = "manual",
        autoTpDownEnabled = false,
        autoTpDownY = 20,
        antiRagdollEnabled = false,
        fpsBoostEnabled = false,
        medusaCounterEnabled = false,
        unwalkEnabled = false,
        batAimbotEnabled = false,
        medusaLastUsed = 0,
        medusaDebounce = false,
        guiVisible = true,
}

local Conns = {
        antiRag = nil,
        anchor = {},
        batAimbot = nil,
}

local h, hrp
local setInfJump, setAntiRag, setFps, setMedusaCounter, setAutoTpDown, setUnwalkToggle, setBatAimbot
local setupMedusaCounter, stopMedusaCounter, startAntiRagdoll, stopAntiRagdoll
local startBatAimbot, stopBatAimbot
local applyFPSBoost
local savedAnimate = nil

-- ================= AUTO-SAVE =================
local saveDebounce = false
local function autoSaveConfig()
        if saveDebounce then return end
        saveDebounce = true
        task.delay(0.5, function()
                local cfg = {
                        infJump          = State.infJumpEnabled,
                        infJumpMode      = State.infJumpMode,
                        autoTpDown       = State.autoTpDownEnabled,
                        autoTpDownY      = State.autoTpDownY,
                        antiRagdoll      = State.antiRagdollEnabled,
                        fpsBoost         = State.fpsBoostEnabled,
                        medusaCounter    = State.medusaCounterEnabled,
                        unwalkEnabled    = State.unwalkEnabled,
                        batAimbot        = State.batAimbotEnabled,
                }
                pcall(function() writefile("VexulHubConfig.json", HttpService:JSONEncode(cfg)) end)
                saveDebounce = false
        end)
end

-- ================= UNWALK =================
local function startUnwalk()
        if State.unwalkEnabled then return end
        State.unwalkEnabled = true
        local c = LP.Character
        if not c then return end
        local hum = c:FindFirstChildOfClass("Humanoid")
        if hum then for _, t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
        local anim = c:FindFirstChild("Animate")
        if anim then savedAnimate = anim:Clone(); anim:Destroy() end
end

local function stopUnwalk()
        if not State.unwalkEnabled then return end
        State.unwalkEnabled = false
        local c = LP.Character
        if c and savedAnimate then
                savedAnimate.Parent = c; savedAnimate.Disabled = false; savedAnimate = nil
        end
end

-- ================= BAT AIMBOT =================
local batAimbotConn = nil
local batAimbotAnchorConn = nil

local function getNearestPlayer()
        local char = LP.Character
        local hrpLocal = char and char:FindFirstChild("HumanoidRootPart")
        if not hrpLocal then return nil end
        local nearest, nearestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
                if p ~= LP and p.Character then
                        local targetHrp = p.Character:FindFirstChild("HumanoidRootPart")
                        local targetHum = p.Character:FindFirstChildOfClass("Humanoid")
                        if targetHrp and targetHum and targetHum.Health > 0 then
                                local dist = (targetHrp.Position - hrpLocal.Position).Magnitude
                                if dist < nearestDist then nearestDist = dist; nearest = p end
                        end
                end
        end
        return nearest
end

startBatAimbot = function()
        if batAimbotConn then return end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root then
                root.Anchored = true
        end
        batAimbotConn = RunService.Heartbeat:Connect(function()
                local c = LP.Character
                local r = c and c:FindFirstChild("HumanoidRootPart")
                if not r then return end
                r.Anchored = true
                local target = getNearestPlayer()
                if target and target.Character then
                        local tHrp = target.Character:FindFirstChild("HumanoidRootPart")
                        if tHrp then
                                r.CFrame = CFrame.new(r.Position, Vector3.new(tHrp.Position.X, r.Position.Y, tHrp.Position.Z))
                        end
                end
        end)
        -- Re-anchor on respawn
        batAimbotAnchorConn = LP.CharacterAdded:Connect(function(newChar)
                if not State.batAimbotEnabled then return end
                task.wait(0.5)
                local newRoot = newChar:FindFirstChild("HumanoidRootPart")
                if newRoot then newRoot.Anchored = true end
        end)
end

stopBatAimbot = function()
        if batAimbotConn then batAimbotConn:Disconnect(); batAimbotConn = nil end
        if batAimbotAnchorConn then batAimbotAnchorConn:Disconnect(); batAimbotAnchorConn = nil end
        local char = LP.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        -- Snap to nearest player on disable
        if root then
                local target = getNearestPlayer()
                if target and target.Character then
                        local tHrp = target.Character:FindFirstChild("HumanoidRootPart")
                        if tHrp then
                                root.CFrame = CFrame.new(tHrp.Position + Vector3.new(0, 0, 2.5))
                        end
                end
                root.Anchored = false
        end
end

-- ================= GUI CLEANUP =================
for _, name in pairs({"JispiHubGUI", "VexulHubGUI"}) do
        local old = game:GetService("CoreGui"):FindFirstChild(name)
        if old then old:Destroy() end
        local old2 = LP:FindFirstChild("PlayerGui") and LP.PlayerGui:FindFirstChild(name)
        if old2 then old2:Destroy() end
end

local closeBtnRef = nil
local miniBtn = nil

-- ================= COLORS =================
local C_BG      = Color3.fromRGB(10,10,10)
local C_PANEL   = Color3.fromRGB(18,18,18)
local C_ROW     = Color3.fromRGB(24,24,24)
local C_ROW_HOV = Color3.fromRGB(32,32,32)
local C_BORDER  = Color3.fromRGB(45,45,45)
local C_BORDER2 = Color3.fromRGB(60,60,60)
local C_HEADER  = Color3.fromRGB(14,14,14)
local C_ACCENT  = Color3.fromRGB(220,220,220)
local C_ACCENT2 = Color3.fromRGB(160,160,160)
local C_DIM     = Color3.fromRGB(90,90,90)
local C_WHITE   = Color3.fromRGB(255,255,255)
local C_ON_BG   = Color3.fromRGB(55,55,55)
local C_OFF_BG  = Color3.fromRGB(22,22,22)

-- ================= GUI SETUP =================
local gui = Instance.new("ScreenGui")
gui.Name = "VexulHubGUI"; gui.ResetOnSpawn = false; gui.DisplayOrder = 10
gui.IgnoreGuiInset = true; gui.Parent = LP:WaitForChild("PlayerGui")

local main = Instance.new("Frame", gui)
main.Name = "Main"; main.Size = UDim2.new(0,260,0,420)
main.Position = UDim2.new(0,20,0,20)
main.BackgroundColor3 = C_BG; main.BorderSizePixel = 0; main.Active = true; main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,16)
local mainStroke = Instance.new("UIStroke", main); mainStroke.Color = C_BORDER2; mainStroke.Thickness = 1

local function saveMainPosition()
        local pos = main.Position
        local str = string.format("%.3f,%.1f,%.3f,%.1f", pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset)
        pcall(function() writefile("VexulHubGUIPos.txt", str) end)
end

local function loadMainPosition()
        local savedPos = nil
        pcall(function() savedPos = readfile("VexulHubGUIPos.txt") end)
        if savedPos and savedPos ~= "" then
                local parts = {}
                for part in string.gmatch(savedPos, "[^,]+") do table.insert(parts, part) end
                if #parts >= 4 then
                        main.Position = UDim2.new(tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4]))
                end
        end
end

local function saveMiniPosition()
        if miniBtn then
                local pos = miniBtn.Position
                local str = string.format("%.3f,%.1f,%.3f,%.1f", pos.X.Scale, pos.X.Offset, pos.Y.Scale, pos.Y.Offset)
                pcall(function() writefile("VexulMiniPos.txt", str) end)
        end
end

local function loadMiniPosition()
        local savedPos = nil
        pcall(function() savedPos = readfile("VexulMiniPos.txt") end)
        if savedPos and savedPos ~= "" and miniBtn then
                local parts = {}
                for part in string.gmatch(savedPos, "[^,]+") do table.insert(parts, part) end
                if #parts >= 4 then
                        miniBtn.Position = UDim2.new(tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4]))
                end
        end
end

-- Draggable main panel
local function makeMainDraggable(frame)
        local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
        local startCloseBtnPos
        frame.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; dragStart = inp.Position; startPos = frame.Position
                        if closeBtnRef then startCloseBtnPos = closeBtnRef.Position end
                        inp.Changed:Connect(function()
                                if inp.UserInputState == Enum.UserInputState.End or inp.UserInputState == Enum.UserInputState.Cancelled then
                                        dragging = false
                                end
                        end)
                end
        end)
        frame.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        dragInput = inp
                end
        end)
        UIS.InputChanged:Connect(function(inp)
                if inp == dragInput and dragging then
                        local dx = inp.Position.X - dragStart.X
                        local dy = inp.Position.Y - dragStart.Y
                        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)
                        if closeBtnRef and startCloseBtnPos then
                                closeBtnRef.Position = UDim2.new(startCloseBtnPos.X.Scale, startCloseBtnPos.X.Offset + dx, startCloseBtnPos.Y.Scale, startCloseBtnPos.Y.Offset + dy)
                        end
                end
        end)
end

local function makeMiniDraggable(frame)
        local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
        frame.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; dragStart = inp.Position; startPos = frame.Position
                        inp.Changed:Connect(function()
                                if inp.UserInputState == Enum.UserInputState.End or inp.UserInputState == Enum.UserInputState.Cancelled then
                                        dragging = false
                                end
                        end)
                end
        end)
        frame.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                        dragInput = inp
                end
        end)
        UIS.InputChanged:Connect(function(inp)
                if inp == dragInput and dragging then
                        local dx = inp.Position.X - dragStart.X
                        local dy = inp.Position.Y - dragStart.Y
                        frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + dx, startPos.Y.Scale, startPos.Y.Offset + dy)
                end
        end)
end

-- Header
local header = Instance.new("Frame", main)
header.Size = UDim2.new(1,0,0,52); header.BackgroundColor3 = C_HEADER; header.BorderSizePixel = 0; header.ZIndex = 5
Instance.new("UICorner", header).CornerRadius = UDim.new(0,16)
local headerDiv = Instance.new("Frame", header)
headerDiv.Size = UDim2.new(1,0,0,1); headerDiv.Position = UDim2.new(0,0,1,-1)
headerDiv.BackgroundColor3 = C_BORDER; headerDiv.BorderSizePixel = 0; headerDiv.ZIndex = 6

local titleLbl = Instance.new("TextLabel", header)
titleLbl.Size = UDim2.new(1,-50,0,22); titleLbl.Position = UDim2.new(0,14,0.5,-11)
titleLbl.BackgroundTransparency = 1; titleLbl.Text = "VEXUL HUB"
titleLbl.TextColor3 = C_WHITE; titleLbl.Font = Enum.Font.GothamBlack; titleLbl.TextSize = 16
titleLbl.TextXAlignment = Enum.TextXAlignment.Left; titleLbl.ZIndex = 6

local closeBtn = Instance.new("TextButton", gui)
closeBtn.Size = UDim2.new(0,26,0,26)
closeBtn.BackgroundColor3 = Color3.fromRGB(35,35,35); closeBtn.BorderSizePixel = 0
closeBtn.Text = "X"; closeBtn.TextColor3 = Color3.fromRGB(160,160,160)
closeBtn.Font = Enum.Font.GothamBlack; closeBtn.TextSize = 12; closeBtn.ZIndex = 50
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(1,0)
local closeBtnStroke = Instance.new("UIStroke", closeBtn)
closeBtnStroke.Color = C_BORDER; closeBtnStroke.Thickness = 1
closeBtnRef = closeBtn

closeBtn.MouseEnter:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(180,40,40), TextColor3 = C_WHITE}):Play()
        TweenService:Create(closeBtnStroke, TweenInfo.new(0.12), {Color = Color3.fromRGB(220,60,60)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
        TweenService:Create(closeBtn, TweenInfo.new(0.12), {BackgroundColor3 = Color3.fromRGB(40,40,40), TextColor3 = Color3.fromRGB(200,200,200)}):Play()
        TweenService:Create(closeBtnStroke, TweenInfo.new(0.12), {Color = C_BORDER2}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false; closeBtn.Visible = false
        if miniBtn then miniBtn.Visible = true end
end)

miniBtn = Instance.new("TextButton", gui)
miniBtn.Name = "VexulMiniButton"
miniBtn.Size = UDim2.new(0,60,0,60); miniBtn.Position = UDim2.new(0,8,0,66)
miniBtn.BackgroundColor3 = Color3.fromRGB(0,0,0); miniBtn.BackgroundTransparency = 0
miniBtn.BorderSizePixel = 0; miniBtn.Text = "VEXUL\nHUB"
miniBtn.TextColor3 = Color3.fromRGB(255,255,255); miniBtn.Font = Enum.Font.GothamBlack
miniBtn.TextSize = 10; miniBtn.AutoButtonColor = false; miniBtn.Visible = false; miniBtn.ZIndex = 50
-- Square: no UICorner
local miniBtnStroke = Instance.new("UIStroke", miniBtn); miniBtnStroke.Color = C_BORDER2; miniBtnStroke.Thickness = 1
miniBtn.MouseButton1Click:Connect(function()
        main.Visible = true; closeBtn.Visible = true; miniBtn.Visible = false
end)
miniBtn.MouseEnter:Connect(function()
        TweenService:Create(miniBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(20,20,20)}):Play()
end)
miniBtn.MouseLeave:Connect(function()
        TweenService:Create(miniBtn, TweenInfo.new(0.1), {BackgroundColor3 = Color3.fromRGB(0,0,0)}):Play()
end)

makeMainDraggable(main)
makeMiniDraggable(miniBtn)

local lastSaveTime = 0
main:GetPropertyChangedSignal("Position"):Connect(function()
        if tick() - lastSaveTime > 0.5 then lastSaveTime = tick(); saveMainPosition() end
end)

local lastMiniSaveTime = 0
miniBtn:GetPropertyChangedSignal("Position"):Connect(function()
        if tick() - lastMiniSaveTime > 0.5 then lastMiniSaveTime = tick(); saveMiniPosition() end
end)

local function updateCloseButtonPosition()
        if main.Visible then
                local mainPos = main.Position
                closeBtn.Position = UDim2.new(mainPos.X.Scale, mainPos.X.Offset + 260 - 34, mainPos.Y.Scale, mainPos.Y.Offset + 13)
        end
end
main:GetPropertyChangedSignal("Position"):Connect(updateCloseButtonPosition)
main:GetPropertyChangedSignal("Visible"):Connect(updateCloseButtonPosition)

-- Scroll
local scroll = Instance.new("ScrollingFrame", main)
scroll.Size = UDim2.new(1,0,1,-52); scroll.Position = UDim2.new(0,0,0,52)
scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0; scroll.ScrollBarThickness = 2
scroll.ScrollBarImageColor3 = C_BORDER2; scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.CanvasSize = UDim2.new(0,0,0,0); scroll.ZIndex = 2
local listLayout = Instance.new("UIListLayout", scroll)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0,2)
local pad = Instance.new("UIPadding", scroll)
pad.PaddingLeft = UDim.new(0,8); pad.PaddingRight = UDim.new(0,8)
pad.PaddingTop = UDim.new(0,8); pad.PaddingBottom = UDim.new(0,10)

local lo = 0
local function LO() lo += 1; return lo end

local function makeGap(px)
        local f = Instance.new("Frame", scroll); f.Size = UDim2.new(1,0,0,px or 4)
        f.BackgroundTransparency = 1; f.BorderSizePixel = 0; f.LayoutOrder = LO()
end

local function makeSectionLabel(text)
        local row = Instance.new("Frame", scroll); row.Size = UDim2.new(1,0,0,22)
        row.BackgroundTransparency = 1; row.BorderSizePixel = 0; row.LayoutOrder = LO()
        local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(1,0,1,0)
        lbl.BackgroundTransparency = 1; lbl.Text = text:upper(); lbl.TextColor3 = C_DIM
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 10; lbl.TextXAlignment = Enum.TextXAlignment.Left
end

local function makeInputRow(label, default, onChange)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1,0,0,34); row.BackgroundColor3 = C_ROW
        row.BorderSizePixel = 0; row.LayoutOrder = LO()
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.55,0,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 2
        local box = Instance.new("TextBox", row)
        box.Size = UDim2.new(0,80,0,26); box.Position = UDim2.new(1,-86,0.5,-13)
        box.BackgroundColor3 = Color3.fromRGB(0,0,0); box.BorderSizePixel = 0
        box.Text = tostring(default); box.TextColor3 = C_ACCENT
        box.Font = Enum.Font.GothamBold; box.TextSize = 14; box.ClearTextOnFocus = true
        box.PlaceholderText = "0"; box.ZIndex = 3
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,6)
        local bs = Instance.new("UIStroke", box); bs.Color = C_BORDER2; bs.Thickness = 1
        box.InputBegan:Connect(function(input) input:StopPropagation() end)
        box.Focused:Connect(function()
                TweenService:Create(bs, TweenInfo.new(0.15), {Color = C_ACCENT2}):Play()
                box.BackgroundColor3 = Color3.fromRGB(8,8,8)
        end)
        box.FocusLost:Connect(function()
                TweenService:Create(bs, TweenInfo.new(0.15), {Color = C_BORDER2}):Play()
                box.BackgroundColor3 = Color3.fromRGB(0,0,0)
                local num = tonumber(box.Text)
                if num ~= nil then
                        local finalVal = math.floor(math.clamp(num, -9999, 9999))
                        box.Text = tostring(finalVal)
                        if onChange then onChange(tostring(finalVal)) end
                        autoSaveConfig()
                else
                        box.Text = tostring(default)
                end
        end)
        box.Active = true; box.Selectable = true
        row.MouseEnter:Connect(function() TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = C_ROW_HOV}):Play() end)
        row.MouseLeave:Connect(function() TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = C_ROW}):Play() end)
        return box
end

local function makeToggleRow(label, _, defaultOn, onToggle)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1,0,0,34); row.BackgroundColor3 = C_ROW
        row.BorderSizePixel = 0; row.LayoutOrder = LO()
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.75,0,1,0); lbl.Position = UDim2.new(0,12,0,0)
        lbl.BackgroundTransparency = 1; lbl.Text = label; lbl.TextColor3 = C_ACCENT
        lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 12; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 2
        local pillBg = Instance.new("Frame", row)
        pillBg.Size = UDim2.new(0,40,0,20); pillBg.Position = UDim2.new(1,-46,0.5,-10)
        pillBg.BackgroundColor3 = defaultOn and C_ON_BG or C_OFF_BG; pillBg.BorderSizePixel = 0; pillBg.ZIndex = 5
        Instance.new("UICorner", pillBg).CornerRadius = UDim.new(1,0)
        local pStroke = Instance.new("UIStroke", pillBg); pStroke.Color = defaultOn and C_ACCENT2 or C_BORDER; pStroke.Thickness = 1
        local dot = Instance.new("Frame", pillBg)
        dot.Size = UDim2.new(0,14,0,14)
        dot.Position = defaultOn and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)
        dot.BackgroundColor3 = defaultOn and C_WHITE or C_DIM; dot.BorderSizePixel = 0; dot.ZIndex = 6
        Instance.new("UICorner", dot).CornerRadius = UDim.new(1,0)
        local isOn = defaultOn or false
        local function setV(on)
                isOn = on
                TweenService:Create(pillBg, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {BackgroundColor3 = on and C_ON_BG or C_OFF_BG}):Play()
                TweenService:Create(pStroke, TweenInfo.new(0.2), {Color = on and C_ACCENT2 or C_BORDER}):Play()
                TweenService:Create(dot, TweenInfo.new(0.2, Enum.EasingStyle.Back), {
                        Position = on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
                        BackgroundColor3 = on and C_WHITE or C_DIM
                }):Play()
        end
        local clk = Instance.new("TextButton", row)
        clk.Size = UDim2.new(1,0,1,0); clk.BackgroundTransparency = 1; clk.Text = ""; clk.ZIndex = 3
        clk.MouseButton1Click:Connect(function()
                isOn = not isOn; setV(isOn)
                if onToggle then pcall(onToggle, isOn) end
                autoSaveConfig()
        end)
        pillBg.ZIndex = 5; dot.ZIndex = 6
        clk.MouseEnter:Connect(function() TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = C_ROW_HOV}):Play() end)
        clk.MouseLeave:Connect(function() TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = C_ROW}):Play() end)
        return setV
end

-- ================= MECHANICS SECTION =================
makeSectionLabel("Mechanics")

setInfJump = makeToggleRow("Infinite Jump", nil, false, function(on) State.infJumpEnabled = on end)

local jumpModeContainer = Instance.new("Frame", scroll)
jumpModeContainer.Size = UDim2.new(1,0,0,34)
jumpModeContainer.BackgroundTransparency = 1; jumpModeContainer.BorderSizePixel = 0; jumpModeContainer.LayoutOrder = LO()

local manuelBtn = Instance.new("TextButton", jumpModeContainer)
manuelBtn.Size = UDim2.new(0.5,-3,1,0); manuelBtn.Position = UDim2.new(0,0,0,0)
manuelBtn.BackgroundColor3 = C_ON_BG; manuelBtn.BorderSizePixel = 0
manuelBtn.Text = "Manual"; manuelBtn.TextColor3 = C_WHITE
manuelBtn.Font = Enum.Font.GothamBold; manuelBtn.TextSize = 12; manuelBtn.AutoButtonColor = false; manuelBtn.ZIndex = 5
Instance.new("UICorner", manuelBtn).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", manuelBtn).Color = C_BORDER2

local holdBtn = Instance.new("TextButton", jumpModeContainer)
holdBtn.Size = UDim2.new(0.5,-3,1,0); holdBtn.Position = UDim2.new(0.5,3,0,0)
holdBtn.BackgroundColor3 = C_OFF_BG; holdBtn.BorderSizePixel = 0
holdBtn.Text = "Hold"; holdBtn.TextColor3 = C_DIM
holdBtn.Font = Enum.Font.GothamBold; holdBtn.TextSize = 12; holdBtn.AutoButtonColor = false; holdBtn.ZIndex = 5
Instance.new("UICorner", holdBtn).CornerRadius = UDim.new(0,8)
Instance.new("UIStroke", holdBtn).Color = C_BORDER2

local function updateInfJumpModeUI()
        if State.infJumpMode == "manual" then
                manuelBtn.BackgroundColor3 = C_ON_BG; manuelBtn.TextColor3 = C_WHITE
                holdBtn.BackgroundColor3 = C_OFF_BG; holdBtn.TextColor3 = C_DIM
        else
                manuelBtn.BackgroundColor3 = C_OFF_BG; manuelBtn.TextColor3 = C_DIM
                holdBtn.BackgroundColor3 = C_ON_BG; holdBtn.TextColor3 = C_WHITE
        end
end

manuelBtn.MouseButton1Click:Connect(function()
        State.infJumpMode = "manual"; updateInfJumpModeUI(); autoSaveConfig()
end)
holdBtn.MouseButton1Click:Connect(function()
        State.infJumpMode = "hold"; updateInfJumpModeUI(); autoSaveConfig()
end)

setAutoTpDown = makeToggleRow("Auto Tp Down", nil, false, function(on)
        State.autoTpDownEnabled = on; autoSaveConfig()
end)

local autoTpDownYBox = makeInputRow("Y Trigger", State.autoTpDownY, function(v)
        local n = tonumber(v)
        if n then State.autoTpDownY = n; autoSaveConfig() end
end)

setAntiRag = makeToggleRow("Anti Ragdoll", nil, false, function(on)
        State.antiRagdollEnabled = on
        if on then startAntiRagdoll() else stopAntiRagdoll() end
end)

setFps = makeToggleRow("FPS Boost", nil, false, function(on)
        State.fpsBoostEnabled = on; if on then pcall(applyFPSBoost) end
end)

setMedusaCounter = makeToggleRow("Medusa Counter", nil, false, function(on)
        State.medusaCounterEnabled = on
        if on then setupMedusaCounter(LP.Character) else stopMedusaCounter() end
end)

setUnwalkToggle = makeToggleRow("Unwalk", nil, false, function(on)
        if on then startUnwalk() else stopUnwalk() end
end)

setBatAimbot = makeToggleRow("Bat Aimbot [F]", nil, false, function(on)
        State.batAimbotEnabled = on
        if on then startBatAimbot() else stopBatAimbot() end
        autoSaveConfig()
end)

makeGap(6)

-- ================= AUTO PLAY SECTION =================
makeSectionLabel("Auto Play")

-- SZG Auto Play config & state
local SZG = {
        GoingSpeed = 55,
        StealSpeed = 29,
        AutoLeft = false,
        AutoRight = false,
}

local szgSaveDebounce = false
local function saveSZGConfig()
        if szgSaveDebounce then return end
        szgSaveDebounce = true
        task.delay(0.5, function()
                pcall(function() writefile("SZG_AutoPlay_Speeds.json", HttpService:JSONEncode({GoingSpeed = SZG.GoingSpeed, StealSpeed = SZG.StealSpeed})) end)
                szgSaveDebounce = false
        end)
end
pcall(function()
        if isfile and isfile("SZG_AutoPlay_Speeds.json") then
                local data = HttpService:JSONDecode(readfile("SZG_AutoPlay_Speeds.json"))
                SZG.GoingSpeed = data.GoingSpeed or 55
                SZG.StealSpeed  = data.StealSpeed  or 29
        end
end)

-- Waypoints
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

-- Proxy
local szgProxy = nil
local function ensureSZGProxy()
        local char = LP.Character; if not char then return nil end
        local hrpP = char:FindFirstChild("HumanoidRootPart"); if not hrpP then return nil end
        if not szgProxy or szgProxy.Parent ~= char then
                if szgProxy then szgProxy:Destroy() end
                szgProxy = Instance.new("Part")
                szgProxy.Name = "SZG_AutoPlayProxy"
                szgProxy.Size = Vector3.new(1,1,1); szgProxy.Transparency = 1
                szgProxy.CanCollide = false; szgProxy.Massless = true; szgProxy.Parent = char
                local weld = Instance.new("Weld")
                weld.Part0 = hrpP; weld.Part1 = szgProxy
                weld.C0 = CFrame.new(0,0,0); weld.Parent = szgProxy
        end
        return szgProxy
end

local function szgMoveTo(target, speed)
        local char = LP.Character; if not char then return end
        local hrpP = char:FindFirstChild("HumanoidRootPart"); if not hrpP then return end
        local dir = (target - hrpP.Position)
        local moveDir = Vector3.new(dir.X, 0, dir.Z).Unit
        local humP = char:FindFirstChildOfClass("Humanoid")
        if humP then humP:Move(moveDir, false) end
        if szgProxy then
                local cv = szgProxy.AssemblyLinearVelocity
                szgProxy.AssemblyLinearVelocity = Vector3.new(moveDir.X * speed, cv.Y, moveDir.Z * speed)
        end
end

local function szgStopMoving()
        if szgProxy then szgProxy.AssemblyLinearVelocity = Vector3.new(0,0,0) end
        local humP = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
        if humP then humP:Move(Vector3.zero, false) end
end

-- Patrol
local szgConn = nil
local szgWaypoints = nil
local szgWpIndex = 1
local szgPhase = 1
local szgUpdateBtns = nil  -- forward ref

local function szgStartPatrol(waypoints)
        if szgConn then szgConn:Disconnect() end
        szgWaypoints = waypoints; szgWpIndex = 1; szgPhase = 1
        ensureSZGProxy()
        szgConn = RunService.Stepped:Connect(function()
                if not szgWaypoints then return end
                local char = LP.Character; if not char then return end
                local hrpP = char:FindFirstChild("HumanoidRootPart"); if not hrpP then return end
                local target = szgWaypoints[szgWpIndex]; if not target then return end
                local dist = (target - hrpP.Position).Magnitude
                local speed = (szgPhase <= 2) and SZG.GoingSpeed or SZG.StealSpeed
                if dist < 2.5 then
                        szgWpIndex = szgWpIndex + 1
                        if szgWpIndex > #szgWaypoints then
                                szgConn:Disconnect(); szgConn = nil; szgWaypoints = nil
                                if SZG.AutoLeft then SZG.AutoLeft = false
                                elseif SZG.AutoRight then SZG.AutoRight = false end
                                if szgUpdateBtns then szgUpdateBtns() end
                                szgStopMoving(); return
                        end
                        if szgWpIndex == 3 then szgPhase = 3 end
                else
                        szgMoveTo(target, speed)
                end
        end)
end

local function szgStopPatrol()
        if szgConn then szgConn:Disconnect(); szgConn = nil end
        szgWaypoints = nil; szgWpIndex = 1; szgStopMoving()
end

-- ===== SLIDER HELPER (styled to match Vexul) =====
local szgSliderDragging = {}

local function makeSZGSlider(labelText, key, minVal, maxVal)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1,0,0,42); row.BackgroundColor3 = C_ROW
        row.BorderSizePixel = 0; row.LayoutOrder = LO()
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
        row.MouseEnter:Connect(function() TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = C_ROW_HOV}):Play() end)
        row.MouseLeave:Connect(function() TweenService:Create(row, TweenInfo.new(0.1), {BackgroundColor3 = C_ROW}):Play() end)

        local lbl = Instance.new("TextLabel", row)
        lbl.Size = UDim2.new(0.65, -4, 0, 16)
        lbl.Position = UDim2.new(0, 12, 0, 6)
        lbl.BackgroundTransparency = 1; lbl.Text = labelText
        lbl.TextColor3 = C_ACCENT; lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.ZIndex = 2

        local valLbl = Instance.new("TextLabel", row)
        valLbl.Size = UDim2.new(0.35, -12, 0, 16)
        valLbl.Position = UDim2.new(0.65, 0, 0, 6)
        valLbl.BackgroundTransparency = 1; valLbl.Text = tostring(SZG[key])
        valLbl.TextColor3 = Color3.fromRGB(200, 200, 80)
        valLbl.Font = Enum.Font.GothamBold; valLbl.TextSize = 11
        valLbl.TextXAlignment = Enum.TextXAlignment.Right; valLbl.ZIndex = 2

        -- Track
        local track = Instance.new("Frame", row)
        track.Size = UDim2.new(1, -24, 0, 6)
        track.Position = UDim2.new(0, 12, 0, 28)
        track.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
        track.BorderSizePixel = 0; track.ZIndex = 3
        Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

        local fill = Instance.new("Frame", track)
        fill.Size = UDim2.new((SZG[key] - minVal) / (maxVal - minVal), 0, 1, 0)
        fill.BackgroundColor3 = Color3.fromRGB(100, 100, 180)
        fill.BorderSizePixel = 0; fill.ZIndex = 4
        Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

        local thumb = Instance.new("Frame", track)
        thumb.Size = UDim2.new(0, 12, 0, 12)
        thumb.AnchorPoint = Vector2.new(0.5, 0.5)
        local initPct = (SZG[key] - minVal) / (maxVal - minVal)
        thumb.Position = UDim2.new(initPct, 0, 0.5, 0)
        thumb.BackgroundColor3 = C_WHITE; thumb.BorderSizePixel = 0; thumb.ZIndex = 5
        Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

        local function updateVisual(pct)
                pct = math.clamp(pct, 0, 1)
                local val = math.round(minVal + pct * (maxVal - minVal))
                SZG[key] = val
                valLbl.Text = tostring(val)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                thumb.Position = UDim2.new(pct, 0, 0.5, 0)
                saveSZGConfig()
        end

        track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        szgSliderDragging[key] = true
                        local pct = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                        updateVisual(pct)
                end
        end)
        track.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        szgSliderDragging[key] = false
                end
        end)
        UIS.InputChanged:Connect(function(input)
                if szgSliderDragging[key] then
                        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                                local pct = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
                                updateVisual(pct)
                        end
                end
        end)
        UIS.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        szgSliderDragging[key] = false
                end
        end)
end

makeSZGSlider("Auto Play Speed", "GoingSpeed", 15, 60)
makeSZGSlider("Steal Speed",     "StealSpeed",  15, 31)

-- ===== AUTO LEFT / AUTO RIGHT BUTTONS =====
local btnContainer = Instance.new("Frame", scroll)
btnContainer.Size = UDim2.new(1, 0, 0, 34)
btnContainer.BackgroundTransparency = 1; btnContainer.BorderSizePixel = 0; btnContainer.LayoutOrder = LO()

local autoLeftBtn = Instance.new("TextButton", btnContainer)
autoLeftBtn.Size = UDim2.new(0.5, -3, 1, 0); autoLeftBtn.Position = UDim2.new(0, 0, 0, 0)
autoLeftBtn.BackgroundColor3 = C_OFF_BG; autoLeftBtn.BorderSizePixel = 0
autoLeftBtn.Text = "AUTO LEFT"; autoLeftBtn.TextColor3 = C_DIM
autoLeftBtn.Font = Enum.Font.GothamBold; autoLeftBtn.TextSize = 11
autoLeftBtn.AutoButtonColor = false; autoLeftBtn.ZIndex = 5
Instance.new("UICorner", autoLeftBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", autoLeftBtn).Color = C_BORDER2

local autoRightBtn = Instance.new("TextButton", btnContainer)
autoRightBtn.Size = UDim2.new(0.5, -3, 1, 0); autoRightBtn.Position = UDim2.new(0.5, 3, 0, 0)
autoRightBtn.BackgroundColor3 = C_OFF_BG; autoRightBtn.BorderSizePixel = 0
autoRightBtn.Text = "AUTO RIGHT"; autoRightBtn.TextColor3 = C_DIM
autoRightBtn.Font = Enum.Font.GothamBold; autoRightBtn.TextSize = 11
autoRightBtn.AutoButtonColor = false; autoRightBtn.ZIndex = 5
Instance.new("UICorner", autoRightBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", autoRightBtn).Color = C_BORDER2

szgUpdateBtns = function()
        -- Left button
        TweenService:Create(autoLeftBtn, TweenInfo.new(0.15), {
                BackgroundColor3 = SZG.AutoLeft and C_ON_BG or C_OFF_BG,
                TextColor3 = SZG.AutoLeft and C_WHITE or C_DIM,
        }):Play()
        -- Right button
        TweenService:Create(autoRightBtn, TweenInfo.new(0.15), {
                BackgroundColor3 = SZG.AutoRight and C_ON_BG or C_OFF_BG,
                TextColor3 = SZG.AutoRight and C_WHITE or C_DIM,
        }):Play()
end

autoLeftBtn.MouseButton1Click:Connect(function()
        if SZG.AutoLeft then
                szgStopPatrol(); SZG.AutoLeft = false; szgUpdateBtns()
        else
                szgStopPatrol(); SZG.AutoRight = false; SZG.AutoLeft = true
                szgUpdateBtns(); szgStartPatrol(leftWaypoints)
        end
end)

autoRightBtn.MouseButton1Click:Connect(function()
        if SZG.AutoRight then
                szgStopPatrol(); SZG.AutoRight = false; szgUpdateBtns()
        else
                szgStopPatrol(); SZG.AutoLeft = false; SZG.AutoRight = true
                szgUpdateBtns(); szgStartPatrol(rightWaypoints)
        end
end)

szgUpdateBtns()

-- Anti-drop
RunService.Stepped:Connect(function()
        local c = LP.Character; if not c then return end
        local hrpP = c:FindFirstChild("HumanoidRootPart")
        if hrpP and hrpP.Position.Y < -10 then
                hrpP.Position = Vector3.new(hrpP.Position.X, -6.5, hrpP.Position.Z)
        end
end)

makeGap(6)

-- ================= KEYBINDS SECTION =================
makeSectionLabel("Keybinds")

local function makeKeybindRow(keyName, description)
        local row = Instance.new("Frame", scroll)
        row.Size = UDim2.new(1,0,0,30); row.BackgroundColor3 = C_ROW
        row.BorderSizePixel = 0; row.LayoutOrder = LO()
        Instance.new("UICorner", row).CornerRadius = UDim.new(0,8)
        local keyLbl = Instance.new("TextLabel", row)
        keyLbl.Size = UDim2.new(0,34,1,0); keyLbl.Position = UDim2.new(0,8,0,0)
        keyLbl.BackgroundColor3 = Color3.fromRGB(30,30,30); keyLbl.BackgroundTransparency = 0
        keyLbl.Text = keyName; keyLbl.TextColor3 = Color3.fromRGB(220,220,80)
        keyLbl.Font = Enum.Font.GothamBold; keyLbl.TextSize = 11; keyLbl.ZIndex = 3
        Instance.new("UICorner", keyLbl).CornerRadius = UDim.new(0,4)
        Instance.new("UIStroke", keyLbl).Color = C_BORDER2
        local descLbl = Instance.new("TextLabel", row)
        descLbl.Size = UDim2.new(1,-54,1,0); descLbl.Position = UDim2.new(0,50,0,0)
        descLbl.BackgroundTransparency = 1; descLbl.Text = description; descLbl.TextColor3 = C_ACCENT2
        descLbl.Font = Enum.Font.Gotham; descLbl.TextSize = 11; descLbl.TextXAlignment = Enum.TextXAlignment.Left; descLbl.ZIndex = 2
end

makeKeybindRow("F",   "Toggle Bat Aimbot")
makeKeybindRow("H",   "Show/Hide GUI")
makeKeybindRow("K",   "Toggle Unwalk")
makeKeybindRow("J",   "Toggle Inf Jump")
makeKeybindRow("R",   "Toggle Anti Ragdoll")

makeGap(10)
local autoSaveLbl = Instance.new("TextLabel", scroll)
autoSaveLbl.Size = UDim2.new(1,0,0,18); autoSaveLbl.BackgroundTransparency = 1
autoSaveLbl.Text = "● Config Auto Save: ON"
autoSaveLbl.TextColor3 = Color3.fromRGB(100,200,100); autoSaveLbl.Font = Enum.Font.GothamBold
autoSaveLbl.TextSize = 10; autoSaveLbl.TextXAlignment = Enum.TextXAlignment.Center; autoSaveLbl.LayoutOrder = LO()

makeGap(2)

local footerLbl = Instance.new("TextLabel", scroll)
footerLbl.Size = UDim2.new(1,0,0,18); footerLbl.BackgroundTransparency = 1; footerLbl.LayoutOrder = LO()
footerLbl.Text = "vexul hub  ·  v2.0"; footerLbl.TextColor3 = Color3.fromRGB(50,50,50)
footerLbl.Font = Enum.Font.Gotham; footerLbl.TextSize = 10; footerLbl.TextXAlignment = Enum.TextXAlignment.Center

-- ================= IMPLEMENTATIONS =================
startAntiRagdoll = function()
        if Conns.antiRag then return end
        Conns.antiRag = RunService.Heartbeat:Connect(function()
                local char = LP.Character; if not char then return end
                local hum2 = char:FindFirstChildOfClass("Humanoid")
                local root = char:FindFirstChild("HumanoidRootPart")
                if hum2 then
                        local st = hum2:GetState()
                        if st == Enum.HumanoidStateType.Physics or st == Enum.HumanoidStateType.Ragdoll or st == Enum.HumanoidStateType.FallingDown then
                                hum2:ChangeState(Enum.HumanoidStateType.Running)
                                workspace.CurrentCamera.CameraSubject = hum2
                                if root then root.Velocity = Vector3.new(0,0,0); root.RotVelocity = Vector3.new(0,0,0) end
                        end
                end
                for _, obj in ipairs(char:GetDescendants()) do
                        if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled = true end
                end
        end)
end

stopAntiRagdoll = function()
        if Conns.antiRag then Conns.antiRag:Disconnect(); Conns.antiRag = nil end
end

applyFPSBoost = function()
        pcall(function() setfpscap(999999999) end)
        local function processObj(v)
                pcall(function()
                        if v:IsA("Model") then v.LevelOfDetail = Enum.ModelLevelOfDetail.Disabled; v.ModelStreamingMode = Enum.ModelStreamingMode.Nonatomic
                        elseif v:IsA("MeshPart") then v.CastShadow = false; v.DoubleSided = false; v.RenderFidelity = Enum.RenderFidelity.Performance
                        elseif v:IsA("BasePart") then v.CastShadow = false; v.Material = Enum.Material.Plastic; v.Reflectance = 0
                        elseif v:IsA("Decal") or v:IsA("Texture") then v.Transparency = 1
                        elseif v:IsA("SpecialMesh") then v.TextureId = ""
                        elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") or v:IsA("Sparkles") or v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Beam") then v.Enabled = false
                        elseif v:IsA("SurfaceAppearance") or v:IsA("MaterialVariant") then v:Destroy()
                        elseif v:IsA("Attachment") then v.Visible = false end
                end)
        end
        for _, v in pairs(workspace:GetDescendants()) do processObj(v) end
        pcall(function()
                local lighting = game:GetService("Lighting")
                for _, v in pairs(lighting:GetDescendants()) do
                        pcall(function()
                                if v:IsA("Sky") or v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Clouds") or v:IsA("PostEffect") or v:IsA("ColorCorrectionEffect") then v:Destroy() end
                        end)
                end
                pcall(function() sethiddenproperty(game:GetService("Lighting"), "Technology", Enum.Technology.Legacy) end)
                local lighting2 = game:GetService("Lighting")
                lighting2.GlobalShadows = false; lighting2.FogEnd = 9e9; lighting2.Brightness = 0
                local terrain = workspace:FindFirstChildOfClass("Terrain")
                if terrain then
                        pcall(function() sethiddenproperty(terrain, "Decoration", false) end)
                        terrain.WaterReflectance = 0; terrain.WaterTransparency = 0.7; terrain.WaterWaveSize = 0; terrain.WaterWaveSpeed = 0
                end
        end)
        workspace.DescendantAdded:Connect(function(v) if State.fpsBoostEnabled then task.spawn(processObj, v) end end)
end

local function findMedusa()
        local char = LP.Character; if not char then return nil end
        for _, tool in ipairs(char:GetChildren()) do
                if tool:IsA("Tool") then local tn = tool.Name:lower()
                        if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end
        end
        local bp2 = LP:FindFirstChild("Backpack")
        if bp2 then for _, tool in ipairs(bp2:GetChildren()) do
                if tool:IsA("Tool") then local tn = tool.Name:lower()
                        if tn:find("medusa") or tn:find("head") or tn:find("stone") then return tool end end
        end end
        return nil
end

local function useMedusaCounter()
        if State.medusaDebounce then return end
        if tick() - State.medusaLastUsed < 25 then return end
        local char = LP.Character; if not char then return end
        State.medusaDebounce = true
        local med = findMedusa(); if not med then State.medusaDebounce = false; return end
        if med.Parent ~= char then local hum2 = char:FindFirstChildOfClass("Humanoid"); if hum2 then hum2:EquipTool(med) end end
        pcall(function() med:Activate() end)
        State.medusaLastUsed = tick(); State.medusaDebounce = false
end

local function onAnchorChanged(part)
        return part:GetPropertyChangedSignal("Anchored"):Connect(function()
                if part.Anchored and part.Transparency == 1 then useMedusaCounter() end
        end)
end

setupMedusaCounter = function(char)
        stopMedusaCounter(); if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then table.insert(Conns.anchor, onAnchorChanged(part)) end
        end
        table.insert(Conns.anchor, char.DescendantAdded:Connect(function(part)
                if part:IsA("BasePart") then table.insert(Conns.anchor, onAnchorChanged(part)) end
        end))
end

stopMedusaCounter = function()
        for _, c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end
        Conns.anchor = {}
end

-- ================= LOAD CONFIG =================
local function loadConfig()
        local hasFile = false; pcall(function() hasFile = isfile("VexulHubConfig.json") end)
        if not hasFile then return end
        local ok, cfg = pcall(function() return HttpService:JSONDecode(readfile("VexulHubConfig.json")) end)
        if not ok or not cfg then return end

        if type(cfg.infJump) == "boolean" and cfg.infJump then
                State.infJumpEnabled = true; setInfJump(true)
        end
        if cfg.infJumpMode == "manual" or cfg.infJumpMode == "hold" then
                State.infJumpMode = cfg.infJumpMode; updateInfJumpModeUI()
        end
        if type(cfg.autoTpDown) == "boolean" then
                State.autoTpDownEnabled = cfg.autoTpDown
                if setAutoTpDown then setAutoTpDown(cfg.autoTpDown) end
        end
        if type(cfg.autoTpDownY) == "number" then
                State.autoTpDownY = cfg.autoTpDownY
                if autoTpDownYBox then autoTpDownYBox.Text = tostring(cfg.autoTpDownY) end
        end
        if type(cfg.antiRagdoll) == "boolean" and cfg.antiRagdoll then
                State.antiRagdollEnabled = true; setAntiRag(true); startAntiRagdoll()
        end
        if type(cfg.fpsBoost) == "boolean" and cfg.fpsBoost then
                State.fpsBoostEnabled = true; setFps(true); pcall(applyFPSBoost)
        end
        if type(cfg.medusaCounter) == "boolean" and cfg.medusaCounter then
                State.medusaCounterEnabled = true; setMedusaCounter(true)
                setupMedusaCounter(LP.Character)
        end
        if type(cfg.unwalkEnabled) == "boolean" and cfg.unwalkEnabled then
                setUnwalkToggle(true)
                task.spawn(function()
                        task.wait(0.5); State.unwalkEnabled = false; startUnwalk()
                end)
        end
        if type(cfg.batAimbot) == "boolean" and cfg.batAimbot then
                State.batAimbotEnabled = true; setBatAimbot(true); startBatAimbot()
        end
end

-- ================= CHARACTER SETUP =================
local function setupChar(char)
        task.wait(0.1)
        h = char:WaitForChild("Humanoid", 5)
        hrp = char:WaitForChild("HumanoidRootPart", 5)
        if not h or not hrp then return end
        if State.antiRagdollEnabled and not Conns.antiRag then task.wait(0.5); startAntiRagdoll() end
        if State.medusaCounterEnabled then setupMedusaCounter(char) end
        if State.unwalkEnabled then
                State.unwalkEnabled = false; task.wait(0.3); startUnwalk()
        end
        -- Resume SZG patrol on respawn
        task.wait(0.5)
        if SZG.AutoLeft then szgStopPatrol(); szgStartPatrol(leftWaypoints)
        elseif SZG.AutoRight then szgStopPatrol(); szgStartPatrol(rightWaypoints) end
end

LP.CharacterAdded:Connect(setupChar)
if LP.Character then task.spawn(function() setupChar(LP.Character) end) end

-- ================= KEYBIND LISTENER =================
UIS.InputBegan:Connect(function(inp, gp)
        if gp then return end
        if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
        local k = inp.KeyCode

        -- F: Toggle Bat Aimbot
        if k == Enum.KeyCode.F then
                State.batAimbotEnabled = not State.batAimbotEnabled
                setBatAimbot(State.batAimbotEnabled)
                if State.batAimbotEnabled then startBatAimbot() else stopBatAimbot() end
                autoSaveConfig()

        -- H: Show/Hide GUI
        elseif k == Enum.KeyCode.H then
                State.guiVisible = not State.guiVisible
                main.Visible = State.guiVisible
                closeBtn.Visible = State.guiVisible
                if miniBtn then miniBtn.Visible = not State.guiVisible end

        -- K: Toggle Unwalk
        elseif k == Enum.KeyCode.K then
                local newVal = not State.unwalkEnabled
                setUnwalkToggle(newVal)
                if newVal then startUnwalk() else stopUnwalk() end
                autoSaveConfig()

        -- J: Toggle Infinite Jump
        elseif k == Enum.KeyCode.J then
                State.infJumpEnabled = not State.infJumpEnabled
                setInfJump(State.infJumpEnabled)
                autoSaveConfig()

        -- R: Toggle Anti Ragdoll
        elseif k == Enum.KeyCode.R then
                State.antiRagdollEnabled = not State.antiRagdollEnabled
                setAntiRag(State.antiRagdollEnabled)
                if State.antiRagdollEnabled then startAntiRagdoll() else stopAntiRagdoll() end
                autoSaveConfig()
        end
end)

-- ================= RUNTIME LOOPS =================
UIS.JumpRequest:Connect(function()
        if not State.infJumpEnabled then return end
        if State.infJumpMode ~= "manual" then return end
        local char = LP.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z) end
end)

RunService.Heartbeat:Connect(function()
        if not State.infJumpEnabled and not State.autoTpDownEnabled then return end
        local char = LP.Character; if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then return end
        if State.infJumpEnabled then
                local hum2 = char:FindFirstChildOfClass("Humanoid")
                if State.infJumpMode == "hold" then
                        local jumpHeld = UIS:IsKeyDown(Enum.KeyCode.Space) or (hum2 and hum2.Jump == true)
                        if jumpHeld and root.Velocity.Y < 30 then
                                root.Velocity = Vector3.new(root.Velocity.X, 55, root.Velocity.Z)
                        end
                end
                if root.Velocity.Y < -120 then root.Velocity = Vector3.new(root.Velocity.X, -120, root.Velocity.Z) end
        end
        if State.autoTpDownEnabled then
                local curY = root.Position.Y
                if curY >= State.autoTpDownY then
                        local rot = root.CFrame.Rotation
                        root.CFrame = CFrame.new(root.Position.X, -8.80, root.Position.Z) * rot
                end
        end
end)

-- ================= INIT =================
loadMainPosition()
loadMiniPosition()
loadConfig()
updateCloseButtonPosition()

print("✅ Vexul Hub v2.0 + SZG Auto Play")
