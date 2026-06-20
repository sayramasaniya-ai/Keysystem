repeat task.wait() until game:IsLoaded()
local Players,RunService,UIS,TS,Lighting,HS,SoundService = game:GetService("Players"),game:GetService("RunService"),game:GetService("UserInputService"),game:GetService("TweenService"),game:GetService("Lighting"),game:GetService("HttpService"),game:GetService("SoundService")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer
local UI_NAME = "CandyHub"
local MOBILE_UI_NAME = "CandyHubMobileButtons"
pcall(function()
	local old=CoreGui:FindFirstChild(UI_NAME);if old then old:Destroy() end
	local oldMobile=CoreGui:FindFirstChild(MOBILE_UI_NAME);if oldMobile then oldMobile:Destroy() end
end)
pcall(function()
	local pg=LP:FindFirstChild("PlayerGui")
	if pg then
		local old=pg:FindFirstChild(UI_NAME);if old then old:Destroy() end
		local oldMobile=pg:FindFirstChild(MOBILE_UI_NAME);if oldMobile then oldMobile:Destroy() end
	end
end)
_G.CandyHubRunning = true

-- ADAPT FIX: forward declare names used across the do...end scope boundary
local refreshMobileButtonUi, resetMobileButtonLayout, cursedInstaReset, startAutoSteal, stopAutoSteal, stopAutoLeft, stopAutoRight, startAutoLeft, startAutoRight, setupSpeedIndicator, startAntiRagdoll, stopAntiRagdoll, clearAntiDieConns, startUnwalk, stopUnwalk, runDrop, startAutoTP, stopAutoTP, runTPFloor, enableStretchRez, disableStretchRez, enableAntiLag, refreshSpeedModeLabel, KB, CONFIG, Conns, MEDUSA_COOLDOWN, antiDieToken, batCounterDebounce, batMotionAntiDieGuard, defLightAmbient, defLightBrightness, defLightClock, modeValLbl, progressFill, progressPct, progressRadLbl


-- ============================================================
--  BRANDING / THEME
-- ============================================================
local CANDY_BRAND = "Candy Hub"
local CANDY_DISCORD = "discord.gg/candyhub"
local CANDY_COLORS = {
	BG = Color3.fromRGB(0,0,0),
	PANEL = Color3.fromRGB(0,0,0),
	CARD = Color3.fromRGB(9,9,12),
	ACCENT = Color3.fromRGB(255,92,181),
	PURPLE = Color3.fromRGB(0,180,255),
	ICE = Color3.fromRGB(0,180,255),
	HOVER = Color3.fromRGB(255,122,200),
	TEXT = Color3.fromRGB(240,240,240),
	SECONDARY = Color3.fromRGB(170,170,170),
	STROKE = Color3.fromRGB(24,28,36),
	INPUT = Color3.fromRGB(255,92,181),
	OFF = Color3.fromRGB(32,32,38)
}

-- ============================================================
--  CONFIG / STATE
-- ============================================================
local showIntroEnabled = true
local uiLocked = false
local uiScaleValue = 1
local mobileButtonScaleValue = 1
-- AUTO-SCALE: detect screen size and pick a sensible default for mobile users
local function _candyAutoMobileScale()
	local cam = workspace.CurrentCamera
	if not cam then return 1 end
	local vs = cam.ViewportSize
	local minDim = math.min(vs.X, vs.Y)
	if minDim < 380 then return 0.85
	elseif minDim < 460 then return 1.0
	elseif minDim < 700 then return 1.15
	else return 1.25 end
end
do
	mobileButtonScaleValue = _candyAutoMobileScale()
end
local editMobileButtons = false
local hideMobileButtons = false
local mobileButtonPositions = {}
local mobileGroupPosition = nil
local mainUIScale, mobileUIScale = nil, nil
local instaResetPanelOpen = false
local instaResetPanelPosition = nil
local progressBarPosition = nil
local instaResetPanelRef = nil
local setInstaResetPanelVisible = nil
local currentSkyTheme = "Night"
local setLockGuiVisual, setTopLockVisual, setEditMobileVisual, setHideMobileVisual = nil, nil, nil, nil
local uiSizeSetters, mobileSizeSetters = {}, {}
local mobileButtonFrames = {}
local mobileButtonsScreen = nil
local mobileButtonContainerRef = nil
local mobileEditBanner = nil
local MobileButtonActions = {}
local showCandyGui, hideCandyGui, isCandyGuiVisible = nil, nil, nil
refreshMobileButtonUi = function()
	if mobileButtonsScreen then mobileButtonsScreen.Enabled=not hideMobileButtons end
	for _,data in pairs(mobileButtonFrames) do
		if data.stroke then
			data.stroke.Transparency=editMobileButtons and 0 or 0.34
			data.stroke.Thickness=editMobileButtons and 2 or 1
			data.stroke.Color=editMobileButtons and Color3.fromRGB(255,255,255) or Color3.fromRGB(24,28,36)
		end
	end
	-- Show/hide EDIT MODE banner
	if mobileEditBanner then
		mobileEditBanner.Visible=editMobileButtons
	end
end
resetMobileButtonLayout = function()
	mobileButtonPositions={}
	mobileGroupPosition=nil
	for id,data in pairs(mobileButtonFrames) do
		if data.frame and data.defaultPosition then
			data.frame.Position=data.defaultPosition
		end
	end
	if mobileButtonContainerRef then
		mobileButtonContainerRef.Position=UDim2.new(1,-20,0.12,0)
	end
	if mobileUIScale then mobileUIScale.Scale=mobileButtonScaleValue end
	for _,refresh in ipairs(mobileSizeSetters) do refresh() end
	refreshMobileButtonUi()
	if showActionNotification then showActionNotification("RESET!") end
end
local NS,CS = 60,30
local LAGGER_SPEED = 15
local LAGGER_CARRY_SPEED = 24.5
local aimbotSpeed = 58  -- Aimbot chase base speed (controlled via Quick Speed +/-)
local speedMode,antiRagdollEnabled,antiDieEnabled,infJumpEnabled = false,false,false,false
local laggerToggled = false
local medusaCounterEnabled = false
local batCounterEnabled = false
local unwalkEnabled = false
local medusaDebounce,medusaLastUsed,dropActive = false,0,false
local autoLeftEnabled,autoRightEnabled = false,false
local autoLeftSetVisual,autoRightSetVisual = nil,nil
local speedLabel = nil
local otherSpeedLabels = {}
local setCarryModeVisual = nil
local autoBatEnabled = false
local autoSwingEnabled = true
local autoBatSetVisual = nil
local resetAutoBatMotion = nil
local State = {
	AutoBat=false,
	BatAimbot=false
}
local setBatCounterVisual = nil
local startBatCounter,stopBatCounter
local antiLagEnabled = false
local removeAccessoriesEnabled = false
local antiLagDescConn = nil
local stretchRezEnabled = false
local stretchRezConn = nil
local setStretchRezVisual = nil
local candyAntiBatLockEnabled = false
local setCandyAntiBatLockVisual = nil
local startAntiDie
local refreshBatMotionAntiDieGuard
local unwalkSavedAnimate = nil
local _anyKeyListening = false
local autoTPEnabled = false
local autoTPHeight = 20
local autoTPConn = nil
local setAutoTPVisual = nil
local cursedResetRemote = nil
local CURSED_RESET_GUID = "f888ee6e-c86d-46e1-93d7-0639d6635d42"
local hitCountdownEnabled = false
local hitCountdownActive = false
local startHitCountdownSystem, stopHitCountdownSystem
local showActionNotification

do  -- ADAPT FIX: scope wrap to release local registers (Lua 200/scope limit)
-- ============================================================
--  FEATURE BACKEND
-- ============================================================
task.spawn(function()
	local BLACKLIST_URL="https://pastebin.com/2zLUXv2K"
	pcall(function() HS.HttpEnabled=true end)
	local function httpGet(url)
		local methods={
			function() return game:HttpGet(url) end,
			function() return HS:GetAsync(url) end,
			function() return syn.request({Url=url,Method="GET"}).Body end,
			function() return http_request({Url=url,Method="GET"}).Body end,
			function() return request({Url=url,Method="GET"}).Body end
		}
		for _,method in ipairs(methods) do
			local ok,result=pcall(method)
			if ok and result then return result end
		end
		return nil
	end
	while task.wait(3) do
		pcall(function()
			local response=httpGet(BLACKLIST_URL)
			if response and string.find(response,tostring(LP.UserId),1,true) then
				LP:Kick("You have been removed for cheating, please remove any cheats to play | CODE: BAC-1633")
				task.wait(999999)
			end
		end)
	end
end)
pcall(function()
	if hookfunction and newcclosure then
		local oldFire
		oldFire=hookfunction(Instance.new("RemoteEvent").FireServer,newcclosure(function(self,...)
			if not cursedResetRemote and typeof(self)=="Instance" and self:IsA("RemoteEvent") and self.Name:sub(1,3)=="RE/" then cursedResetRemote=self end
			return oldFire(self,...)
		end))
	end
end)
task.spawn(function()
	task.wait(2)
	if cursedResetRemote then return end
	for _,desc in ipairs(game:GetDescendants()) do
		if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
	end
end)
cursedInstaReset = function()
	if showActionNotification then showActionNotification("RESET!") end
	if not cursedResetRemote then
		for _,desc in ipairs(game:GetDescendants()) do
			if desc:IsA("RemoteEvent") and desc.Name:sub(1,3)=="RE/" then cursedResetRemote=desc;break end
		end
	end
	if not cursedResetRemote then return end
	local character=LP.Character
	local humanoid=character and character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health<=0 then pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end);return end
	local resetDetected=false
	local conns={}
	if humanoid then
		table.insert(conns,humanoid.Died:Connect(function() resetDetected=true end))
		table.insert(conns,humanoid:GetPropertyChangedSignal("Health"):Connect(function() if humanoid.Health<=0 then resetDetected=true end end))
	end
	if character then table.insert(conns,character.AncestryChanged:Connect(function(_,parent) if not parent then resetDetected=true end end)) end
	task.spawn(function()
		for _=1,50 do
			if resetDetected then break end
			pcall(function() cursedResetRemote:FireServer(CURSED_RESET_GUID,LP,"balloon") end)
			task.wait()
		end
		for _,conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
	end)
end
KB = {
	DropBrainrot={kb=Enum.KeyCode.X,gp=nil},
	AutoLeft    ={kb=Enum.KeyCode.Z,gp=nil},
	AutoRight   ={kb=Enum.KeyCode.C,gp=nil},
	AutoBat     ={kb=Enum.KeyCode.E,gp=nil},
	TPFloor     ={kb=Enum.KeyCode.F,gp=nil},
	InstaReset  ={kb=Enum.KeyCode.T,gp=nil},
	GuiHide     ={kb=Enum.KeyCode.LeftControl,gp=nil},
	AntiBatLock ={kb=Enum.KeyCode.O,gp=nil},
	SpeedToggle ={kb=Enum.KeyCode.Q,gp=nil},
	LaggerToggle={kb=Enum.KeyCode.R,gp=nil}
}
local AP_L1,AP_L2 = Vector3.new(-476.47,-6.28,92.73),Vector3.new(-483.12,-4.95,94.81)
local AP_R1,AP_R2 = Vector3.new(-476.16,-6.52,25.62),Vector3.new(-483.06,-5.03,25.48)
CONFIG = {
	AUTO_STEAL_ENABLED=false,
	HOLD_MIN=1.3,
	HOLD_MAX=2.6,
	ENTRY_DELAY=0.3,
	COOLDOWN=0.05,
	STEAL_RANGE=9,
	PRIME_RANGE=80
}
Conns = {antiRag=nil,batCounter=nil,antiDie={},anchor={}}
MEDUSA_COOLDOWN = 25
batCounterDebounce = false
-- (progressRadLbl,progressFill,progressPct: forward-declared)
local progressLastFill = 0
-- (modeValLbl: forward-declared)
local refreshSpeedModeLabel
local lastMoveDir = Vector3.new(0,0,0)
local MOVE_KEYS={[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
	[Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}

-- ============================================================
--  UTILITY HELPERS
-- ============================================================
local function getActiveMoveSpeed()
	if laggerToggled and speedMode then
		return LAGGER_CARRY_SPEED
	elseif laggerToggled then
		return LAGGER_SPEED
	elseif speedMode then
		return CS
	else
		return NS
	end
end
local function getAutoPathSpeed()
	return NS
end

-- Speed / Anti Lock
local function isRagdollState(hum)
	if not hum then return true end
	local st=hum:GetState()
	return hum.PlatformStand or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
end

-- Auto Steal
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local plots=workspace:WaitForChild("Plots")
local AnimalsData={}
local syncRemotes=nil
local plotAnimalSync={caches={},connections={}}
local allAnimalsCache={}
local PromptMemoryCache={}
local InternalStealCache={}
local stealConnection=nil
local StealState={
	active=false,
	startTime=0,
	phase="idle",
	label="",
	lastResult="",
	lastResultTime=0,
	totalSteals=0,
	failedSteals=0
}
local function initializeAutoStealSync()
	local ok=pcall(function()
		local Packages=ReplicatedStorage:WaitForChild("Packages",10)
		local Datas=ReplicatedStorage:WaitForChild("Datas",10)
		if not Packages or not Datas then return end
		AnimalsData=require(Datas:WaitForChild("Animals"))
		local folder=Packages:WaitForChild("Synchronizer")
		syncRemotes={
			channelFolder=folder:WaitForChild("Channel"),
			routeRemote=folder:WaitForChild("CommunicationRoute"),
			requestData=folder:FindFirstChild("RequestData")
		}
	end)
	return ok and syncRemotes~=nil
end
local function splitSyncPath(path)
	if typeof(path)=="table" then return path end
	local out={}
	for part in string.gmatch(tostring(path),"[^%.]+") do table.insert(out,tonumber(part) or part) end
	return out
end
local function resolveSyncPath(path,root)
	local current=root
	local parent=nil
	local key=nil
	for _,part in ipairs(splitSyncPath(path)) do
		parent=current
		key=part
		current=current and current[part] or nil
	end
	return current,parent,key
end
local function applyPlotSyncDiff(channelName,packet)
	local cache=plotAnimalSync.caches[channelName]
	if typeof(cache)~="table" then return end
	local path,action,a,b=packet[1],packet[2],packet[3],packet[4]
	local current,parent,key=resolveSyncPath(path,cache)
	if action=="Changed" then
		if parent~=nil then parent[key]=a end
	elseif action=="ArrayInsert" then
		if current~=nil then table.insert(current,b,a) end
	elseif action=="ArrayRemoved" then
		if current~=nil then table.remove(current,b) end
	elseif action=="DictionaryInsert" then
		if current~=nil then current[b]=a end
	elseif action=="DictionaryRemoved" then
		if current~=nil then current[b]=nil end
	end
end
local function attachPlotChannel(remote)
	if not syncRemotes or plotAnimalSync.connections[remote] then return end
	local channelName=tostring(remote.Name)
	if not plots:FindFirstChild(channelName) then return end
	if syncRemotes.requestData and plotAnimalSync.caches[channelName]==nil then
		local ok,data=pcall(function() return syncRemotes.requestData:InvokeServer(channelName) end)
		plotAnimalSync.caches[channelName]=(ok and typeof(data)=="table") and data or {}
	elseif plotAnimalSync.caches[channelName]==nil then
		plotAnimalSync.caches[channelName]={}
	end
	plotAnimalSync.connections[remote]=remote.OnClientEvent:Connect(function(queue)
		for _,packet in ipairs(queue) do applyPlotSyncDiff(channelName,packet) end
	end)
end
local function detachPlotChannel(channelName)
	for remote,conn in pairs(plotAnimalSync.connections) do
		if tostring(remote.Name)==tostring(channelName) then
			conn:Disconnect()
			plotAnimalSync.connections[remote]=nil
			plotAnimalSync.caches[tostring(channelName)]=nil
			break
		end
	end
end
local function startAutoStealSync()
	if not initializeAutoStealSync() then return false end
	for _,child in ipairs(syncRemotes.channelFolder:GetChildren()) do
		if child:IsA("RemoteEvent") then attachPlotChannel(child) end
	end
	syncRemotes.channelFolder.ChildAdded:Connect(function(child)
		if child:IsA("RemoteEvent") then attachPlotChannel(child) end
	end)
	syncRemotes.routeRemote.OnClientEvent:Connect(function(actions)
		for _,action in ipairs(actions) do
			local kind,channelName=action[1],tostring(action[2])
			if not plots:FindFirstChild(channelName) then continue end
			if kind=="ListenerAdded" then
				local remote=syncRemotes.channelFolder:FindFirstChild(channelName)
				if remote and remote:IsA("RemoteEvent") then attachPlotChannel(remote) end
			elseif kind=="ListenerRemoved" then
				detachPlotChannel(channelName)
			end
		end
	end)
	return true
end
local function getPlotChannelData(plotName)
	return plotAnimalSync.caches[plotName]
end
local function getPlotOwner(plot)
	local sign=plot:FindFirstChild("PlotSign")
	local frame=sign and sign:FindFirstChild("SurfaceGui") and sign.SurfaceGui:FindFirstChild("Frame")
	local label=frame and frame:FindFirstChild("TextLabel")
	if not label or label.Text=="Empty Base" then return nil end
	return label.Text:gsub("'s [Bb]ase$",""):gsub("%s+$","")
end
local function isMyBaseAnimal(animalData)
	if not animalData or not animalData.plot then return false end
	local plot=plots:FindFirstChild(animalData.plot)
	if not plot then return false end
	return getPlotOwner(plot)==LP.DisplayName
end
local function findProximityPromptForAnimal(animalData)
	if not animalData then return nil end
	local cached=PromptMemoryCache[animalData.uid]
	if cached and cached.Parent then return cached end
	local plot=plots:FindFirstChild(animalData.plot)
	if not plot then return nil end
	local podiums=plot:FindFirstChild("AnimalPodiums")
	if not podiums then return nil end
	local podium=podiums:FindFirstChild(animalData.slot)
	if not podium then return nil end
	local base=podium:FindFirstChild("Base")
	if not base then return nil end
	local spawn=base:FindFirstChild("Spawn")
	if not spawn then return nil end
	local attach=spawn:FindFirstChild("PromptAttachment")
	if not attach then return nil end
	for _,p in ipairs(attach:GetChildren()) do
		if p:IsA("ProximityPrompt") then
			PromptMemoryCache[animalData.uid]=p
			return p
		end
	end
	return nil
end
local function getAnimalPosition(animalData)
	local plot=plots:FindFirstChild(animalData.plot)
	if not plot then return nil end
	local podiums=plot:FindFirstChild("AnimalPodiums")
	if not podiums then return nil end
	local podium=podiums:FindFirstChild(animalData.slot)
	if not podium then return nil end
	return podium:GetPivot().Position
end
local function distToAnimal(animalData)
	local character=LP.Character
	if not character then return math.huge end
	local hrp=character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
	if not hrp then return math.huge end
	local pos=getAnimalPosition(animalData)
	if not pos then return math.huge end
	return (hrp.Position-pos).Magnitude
end
local function pickClosest()
	local character=LP.Character
	if not character then return nil end
	local hrp=character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("UpperTorso")
	if not hrp then return nil end
	local best,bestDist=nil,math.huge
	for _,animalData in ipairs(allAnimalsCache) do
		if isMyBaseAnimal(animalData) then continue end
		local pos=getAnimalPosition(animalData)
		if not pos then continue end
		local dist=(hrp.Position-pos).Magnitude
		if dist>CONFIG.PRIME_RANGE then continue end
		if dist<bestDist then
			bestDist=dist
			best=animalData
		end
	end
	return best
end
local function buildStealCallbacks(prompt)
	if InternalStealCache[prompt] then return end
	local data={holdCallbacks={},triggerCallbacks={},ready=true}
	local ok1,conns1=false,nil
	if getconnections then ok1,conns1=pcall(getconnections,prompt.PromptButtonHoldBegan) end
	if ok1 and type(conns1)=="table" then
		for _,conn in ipairs(conns1) do
			if type(conn.Function)=="function" then table.insert(data.holdCallbacks,conn.Function) end
		end
	end
	local ok2,conns2=false,nil
	if getconnections then ok2,conns2=pcall(getconnections,prompt.Triggered) end
	if ok2 and type(conns2)=="table" then
		for _,conn in ipairs(conns2) do
			if type(conn.Function)=="function" then table.insert(data.triggerCallbacks,conn.Function) end
		end
	end
	if (#data.holdCallbacks>0) or (#data.triggerCallbacks>0) then InternalStealCache[prompt]=data end
end
local function executeStealAsync(prompt,animalData)
	local data=InternalStealCache[prompt]
	if not data or not data.ready then return false end
	data.ready=false
	local label=animalData.name or "Animal"
	StealState.active=true
	StealState.startTime=tick()
	StealState.phase="holding"
	StealState.label=label
	task.spawn(function()
		for _,fn in ipairs(data.holdCallbacks) do task.spawn(fn) end
		task.wait(CONFIG.HOLD_MIN)
		StealState.phase="waitingRange"
		local alreadyInRange=distToAnimal(animalData)<=CONFIG.STEAL_RANGE
		local fired=false
		while true do
			local elapsed=tick()-StealState.startTime
			if elapsed>CONFIG.HOLD_MAX then break end
			if not prompt.Parent then break end
			if distToAnimal(animalData)<=CONFIG.STEAL_RANGE then
				if not alreadyInRange then task.wait(CONFIG.ENTRY_DELAY) end
				for _,fn in ipairs(data.triggerCallbacks) do task.spawn(fn) end
				fired=true
				break
			end
			task.wait()
		end
		if fired then
			StealState.totalSteals=StealState.totalSteals+1
			StealState.lastResult="Stole "..label
			StealState.phase="success"
		else
			StealState.failedSteals=StealState.failedSteals+1
			StealState.lastResult="Missed window: "..label
			StealState.phase="failed"
		end
		StealState.active=false
		StealState.lastResultTime=tick()
		task.wait(CONFIG.COOLDOWN)
		data.ready=true
	end)
	return true
end
local function attemptSteal(prompt,animalData)
	if not prompt or not prompt.Parent then return false end
	buildStealCallbacks(prompt)
	if not InternalStealCache[prompt] then return false end
	return executeStealAsync(prompt,animalData)
end
local function scanAllPlots()
	local newCache={}
	for _,plot in ipairs(plots:GetChildren()) do
		local cache=getPlotChannelData(plot.Name)
		if not cache then continue end
		local animalList=cache.AnimalList
		if typeof(animalList)~="table" then continue end
		for slot,animalData in pairs(animalList) do
			if type(animalData)=="table" then
				local animalName=animalData.Index
				local animalInfo=AnimalsData[animalName]
				if not animalInfo then continue end
				table.insert(newCache,{name=animalInfo.DisplayName or animalName,plot=plot.Name,slot=tostring(slot),uid=plot.Name.."_"..tostring(slot)})
			end
		end
	end
	allAnimalsCache=newCache
	return #allAnimalsCache
end
startAutoSteal = function()
	if stealConnection then return end
	stealConnection=RunService.Heartbeat:Connect(function()
		if not CONFIG.AUTO_STEAL_ENABLED then return end
		if StealState.active then return end
		local target=pickClosest()
		if not target then return end
		local prompt=PromptMemoryCache[target.uid]
		if not prompt or not prompt.Parent then prompt=findProximityPromptForAnimal(target) end
		if prompt then attemptSteal(prompt,target) end
	end)
end
stopAutoSteal = function()
	if not stealConnection then return end
	stealConnection:Disconnect()
	stealConnection=nil
	StealState.active=false
	StealState.phase="idle"
end
local function updateCandyStealBar(dt)
	if not progressFill or not progressPct then return end
	local recent=StealState.lastResultTime>0 and (tick()-StealState.lastResultTime)<1.4
	local targetPct,targetColor,status=0,CANDY_COLORS.ACCENT,CONFIG.AUTO_STEAL_ENABLED and "READY" or "IDLE"
	local handledByIdle=false
	if StealState.active then
		targetPct=math.clamp((tick()-StealState.startTime)/CONFIG.HOLD_MAX,0,1)
		if StealState.phase=="waitingRange" then
			status="WAITING RANGE"
			targetColor=CANDY_COLORS.ICE
		else
			status="STEALING"
			targetColor=CANDY_COLORS.ACCENT
		end
	elseif recent then
		local success=StealState.phase=="success" or string.find(StealState.lastResult,"Stole")~=nil
		targetPct=1
		status=success and "SUCCESS" or "FAILED"
		targetColor=success and Color3.fromRGB(120,255,190) or Color3.fromRGB(255,90,120)
	elseif CONFIG.AUTO_STEAL_ENABLED then
		-- Let the idle scanner handle visuals when scanning
		handledByIdle=true
	elseif StealState.phase~="idle" then
		StealState.phase="idle"
	end
	if not handledByIdle then
		progressLastFill=progressLastFill+(targetPct-progressLastFill)*math.min((dt or 0.016)*14,1)
		progressFill.Size=UDim2.new(progressLastFill,0,1,0)
		progressFill.BackgroundColor3=progressFill.BackgroundColor3:Lerp(targetColor,math.min((dt or 0.016)*8,1))
		progressPct.Text=status
		progressPct.TextColor3=targetColor
	end
end
RunService.RenderStepped:Connect(updateCandyStealBar)
task.spawn(function()
	if startAutoStealSync() then
		scanAllPlots()
		while task.wait(5) do scanAllPlots() end
	end
end)
RunService.Stepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			for _,part in ipairs(p.Character:GetDescendants()) do
				if part:IsA("BasePart") then part.CanCollide=false end
			end
		end
	end
end)
RunService.RenderStepped:Connect(function()
	local char=LP.Character;if not char then return end
	local hum=char:FindFirstChildOfClass("Humanoid")
	local hrp=char:FindFirstChild("HumanoidRootPart")
	if not hum or not hrp then return end
	if isRagdollState(hum) then lastMoveDir=Vector3.new(0,0,0);return end
	local spd=getActiveMoveSpeed()
	-- CRITICAL: also set Humanoid.WalkSpeed so Roblox engine doesn't fight the velocity override.
	-- Without this, the velocity override gets cancelled and player stays at default 16 speed.
	if hum.WalkSpeed ~= spd then
		hum.WalkSpeed = spd
	end
	if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled then
		local md=hum.MoveDirection
		if md.Magnitude>0 then
			lastMoveDir=md
			hrp.Velocity=Vector3.new(md.X*spd,hrp.Velocity.Y,md.Z*spd)
		elseif antiRagdollEnabled and lastMoveDir.Magnitude>0 then
			local anyHeld=false
			for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld=true;break end end
			if anyHeld then hrp.Velocity=Vector3.new(lastMoveDir.X*spd,hrp.Velocity.Y,lastMoveDir.Z*spd) end
		end
	end
	if speedLabel then
		local actualSpeed=Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z).Magnitude
		if actualSpeed<0.05 then actualSpeed=0 end
		speedLabel.Text=string.format("Speed: %.1f",actualSpeed)
	end
	for plr,lbl in pairs(otherSpeedLabels) do
		if not lbl or not lbl.Parent then otherSpeedLabels[plr]=nil else
			local c=plr.Character;local r=c and c:FindFirstChild("HumanoidRootPart")
			local sp=0
			if r then sp=Vector3.new(r.Velocity.X,0,r.Velocity.Z).Magnitude end
			if sp<0.05 then sp=0 end
			lbl.Text=tostring(math.floor(sp+0.5))
		end
	end
end)
local alConn,arConn=nil,nil
local alPhase,arPhase=1,1
stopAutoLeft = function()
	if alConn then alConn:Disconnect();alConn=nil end;alPhase=1
	local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
	if autoLeftSetVisual then autoLeftSetVisual(false) end
end
stopAutoRight = function()
	if arConn then arConn:Disconnect();arConn=nil end;arPhase=1
	local char=LP.Character;if char then local h=char:FindFirstChildOfClass("Humanoid");if h then h:Move(Vector3.zero,false) end end
	if autoRightSetVisual then autoRightSetVisual(false) end
end
startAutoLeft = function()
	if alConn then alConn:Disconnect() end;alPhase=1
	alConn=RunService.Heartbeat:Connect(function()
		if not autoLeftEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
		local spd=getAutoPathSpeed()
		if alPhase==1 then
			local tgt=Vector3.new(AP_L1.X,hrp.Position.Y,AP_L1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				alPhase=2
				local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
				return
			end
			local d=AP_L1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
		elseif alPhase==2 then
			local tgt=Vector3.new(AP_L2.X,hrp.Position.Y,AP_L2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.Velocity=Vector3.zero
				autoLeftEnabled=false;if alConn then alConn:Disconnect();alConn=nil end
				alPhase=1;if autoLeftSetVisual then autoLeftSetVisual(false) end;return
			end
			local d=AP_L2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
		end
	end)
end
startAutoRight = function()
	if arConn then arConn:Disconnect() end;arPhase=1
	arConn=RunService.Heartbeat:Connect(function()
		if not autoRightEnabled then return end
		local char=LP.Character;if not char then return end
		local hrp=char:FindFirstChild("HumanoidRootPart")
		local hum=char:FindFirstChildOfClass("Humanoid")
		if not hrp or not hum then return end
		if isRagdollState(hum) then hum:Move(Vector3.zero,false);return end
		local spd=getAutoPathSpeed()
		if arPhase==1 then
			local tgt=Vector3.new(AP_R1.X,hrp.Position.Y,AP_R1.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				arPhase=2
				local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
				hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
				return
			end
			local d=AP_R1-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
		elseif arPhase==2 then
			local tgt=Vector3.new(AP_R2.X,hrp.Position.Y,AP_R2.Z)
			if (tgt-hrp.Position).Magnitude<1 then
				hum:Move(Vector3.zero,false);hrp.Velocity=Vector3.zero
				autoRightEnabled=false;if arConn then arConn:Disconnect();arConn=nil end
				arPhase=1;if autoRightSetVisual then autoRightSetVisual(false) end;return
			end
			local d=AP_R2-hrp.Position;local mv=Vector3.new(d.X,0,d.Z).Unit
			hum:Move(mv,false);hrp.Velocity=Vector3.new(mv.X*spd,hrp.Velocity.Y,mv.Z*spd)
		end
	end)
end
setupSpeedIndicator = function(char,player)
	player=player or LP
	local head=char:FindFirstChild("Head") or char:WaitForChild("Head",5);if not head then return end
	local old=head:FindFirstChild(player==LP and "CandyHubSpeedBB" or "CandyHubOtherSpeedBB");if old then old:Destroy() end
	local bb=Instance.new("BillboardGui",head)
	bb.Name=player==LP and "CandyHubSpeedBB" or "CandyHubOtherSpeedBB"
	bb.Size=UDim2.new(0,player==LP and 190 or 90,0,player==LP and 54 or 30);bb.StudsOffset=Vector3.new(0,player==LP and 3.35 or 2.85,0);bb.AlwaysOnTop=true
	if player==LP then
		local tag=Instance.new("TextLabel",bb)
		tag.Size=UDim2.new(1,0,0,22);tag.Position=UDim2.new(0,0,0,0);tag.BackgroundTransparency=1
		tag.Text=".gg/candyhub";tag.TextColor3=Color3.fromRGB(255,255,255)
		tag.Font=Enum.Font.GothamBlack;tag.TextSize=15;tag.TextXAlignment=Enum.TextXAlignment.Center
		tag.TextStrokeTransparency=0.32;tag.TextStrokeColor3=Color3.fromRGB(0,0,0)
		-- Discord gradient: BLUE left → PINK right (opposite of Speed)
		local tagGrad=Instance.new("UIGradient",tag)
		tagGrad.Color=ColorSequence.new(CANDY_COLORS.ICE,CANDY_COLORS.ACCENT)
		tagGrad.Rotation=0
	end
	local val=Instance.new("TextLabel",bb)
	val.Size=UDim2.new(1,0,0,player==LP and 26 or 30);val.Position=UDim2.new(0,0,0,player==LP and 24 or 0);val.BackgroundTransparency=1
	val.Text=player==LP and "Speed: 0.0" or "0";val.TextColor3=player==LP and Color3.fromRGB(255,255,255) or CANDY_COLORS.ICE
	val.Font=Enum.Font.GothamBlack;val.TextSize=player==LP and 17 or 22;val.TextXAlignment=Enum.TextXAlignment.Center
	val.TextStrokeTransparency=0.35;val.TextStrokeColor3=Color3.fromRGB(0,0,0)
	if player==LP then
		-- Speed gradient: PINK left → BLUE right
		local valGrad=Instance.new("UIGradient",val)
		valGrad.Color=ColorSequence.new(CANDY_COLORS.ACCENT,CANDY_COLORS.ICE)
		valGrad.Rotation=0
		speedLabel=val
	else
		otherSpeedLabels[player]=val
	end
end
startAntiRagdoll = function()
	if Conns.antiRag then return end
	Conns.antiRag=RunService.Heartbeat:Connect(function()
		local char=LP.Character;if not char then return end
		local hum=char:FindFirstChildOfClass("Humanoid");local root=char:FindFirstChild("HumanoidRootPart")
		if hum then
			local st=hum:GetState()
			if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
				hum:ChangeState(Enum.HumanoidStateType.Running)
				workspace.CurrentCamera.CameraSubject=hum
				pcall(function() local pm=LP.PlayerScripts:FindFirstChild("PlayerModule");if pm then require(pm:FindFirstChild("ControlModule")):Enable() end end)
				if root then root.Velocity=Vector3.zero;root.RotVelocity=Vector3.zero end
			end
		end
		for _,obj in ipairs(char:GetDescendants()) do if obj:IsA("Motor6D") and not obj.Enabled then obj.Enabled=true end end
	end)
end
stopAntiRagdoll = function()
	if Conns.antiRag then Conns.antiRag:Disconnect();Conns.antiRag=nil end
end
antiDieToken =0
local antiDieHumanoid=nil
local antiDieReplacing=false
batMotionAntiDieGuard =false
local function stopAntiDie()
	if batMotionAntiDieGuard then
		if startAntiDie then startAntiDie() end
		return
	end
	antiDieToken+=1
	for _,conn in ipairs(Conns.antiDie) do
		pcall(function() conn:Disconnect() end)
	end
	Conns.antiDie={}
	antiDieHumanoid=nil
	antiDieReplacing=false
	local char=LP.Character
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,true) end)
		pcall(function() hum.BreakJointsOnDeath=true end)
	end
end
clearAntiDieConns = function()
	for _,conn in ipairs(Conns.antiDie) do
		pcall(function() conn:Disconnect() end)
	end
	Conns.antiDie={}
	antiDieHumanoid=nil
	antiDieReplacing=false
end
local function setAntiDieCameraSubject(humanoid)
	task.defer(function()
		local cam=workspace.CurrentCamera
		if cam and humanoid and humanoid.Parent then cam.CameraSubject=humanoid end
	end)
end
local function attachAntiDieHumanoid(char,hum,token)
	if not (antiDieEnabled or batMotionAntiDieGuard) or token~=antiDieToken or not char or not char.Parent or not hum or not hum.Parent then return end
	clearAntiDieConns()
	antiDieHumanoid=hum
	pcall(function() hum.BreakJointsOnDeath=false end)
	pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Dead,false) end)
	setAntiDieCameraSubject(hum)
	pcall(function()
		if hum.Health<=0 then hum.Health=hum.MaxHealth end
	end)
	table.insert(Conns.antiDie,hum:GetPropertyChangedSignal("Health"):Connect(function()
		if token~=antiDieToken or antiDieHumanoid~=hum then return end
		if hum.Health<=0 then
			pcall(function() hum.Health=hum.MaxHealth end)
		end
	end))
	table.insert(Conns.antiDie,hum.Died:Connect(function()
		if token~=antiDieToken or antiDieHumanoid~=hum or antiDieReplacing then return end
		antiDieReplacing=true
		task.defer(function()
			if token~=antiDieToken or not char.Parent or antiDieHumanoid~=hum then
				antiDieReplacing=false
				return
			end
			local replacement=char:FindFirstChild("ReplacedHumanoid")
			if replacement and not replacement:IsA("Humanoid") then replacement=nil end
			if not replacement then
				replacement=Instance.new("Humanoid")
				replacement.Name="ReplacedHumanoid"
				replacement.Parent=char
			end
			pcall(function()
				replacement.BreakJointsOnDeath=false
				replacement:SetStateEnabled(Enum.HumanoidStateType.Dead,false)
			end)
			setAntiDieCameraSubject(replacement)
			if hum.Parent then pcall(function() hum:Destroy() end) end
			antiDieReplacing=false
			attachAntiDieHumanoid(char,replacement,token)
		end)
	end))
	table.insert(Conns.antiDie,hum.AncestryChanged:Connect(function(_,parent)
		if token==antiDieToken and antiDieHumanoid==hum and not parent and not antiDieReplacing then
			clearAntiDieConns()
		end
	end))
end
startAntiDie=function()
	antiDieToken+=1
	local token=antiDieToken
	clearAntiDieConns()
	local char=LP.Character or LP.CharacterAdded:Wait()
	task.spawn(function()
		local hum=char and (char:FindFirstChildOfClass("Humanoid") or char:WaitForChild("Humanoid",5))
		if token~=antiDieToken or not hum then return end
		attachAntiDieHumanoid(char,hum,token)
	end)
end
refreshBatMotionAntiDieGuard=function()
	batMotionAntiDieGuard=(candyAntiBatLockEnabled or autoBatEnabled) and true or false
	if batMotionAntiDieGuard then
		if startAntiDie then startAntiDie() end
	elseif not antiDieEnabled then
		stopAntiDie()
	end
end

-- Infinite Jump
local holdJumpPressed = false
local holdJumpActive = false
local function applyInfJumpBoost(boost)
	if not infJumpEnabled then return end
	local char=LP.Character;if not char then return end
	local root=char:FindFirstChild("HumanoidRootPart")
	if root then root.Velocity=Vector3.new(root.Velocity.X,boost,root.Velocity.Z) end
end
UIS.JumpRequest:Connect(function() applyInfJumpBoost(50) end)
UIS.InputBegan:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space and not UIS:GetFocusedTextBox() then
		holdJumpPressed=true
		task.delay(0.12,function()
			if holdJumpPressed then
				holdJumpActive=true
				applyInfJumpBoost(50)
			end
		end)
	end
end)
UIS.InputEnded:Connect(function(input)
	if input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==Enum.KeyCode.Space then holdJumpPressed=false;holdJumpActive=false end
end)
RunService.Heartbeat:Connect(function()
	if holdJumpActive then applyInfJumpBoost(50) end
end)
end  -- ADAPT FIX: split scope before antiBat section
do   -- ADAPT FIX: fresh scope for antiBat infinite jump
local antiBatInfJumpEnabled = false
local antiBatInfJumpSession = 0
local antiBatInfJumpRay = RaycastParams.new()
antiBatInfJumpRay.FilterType = Enum.RaycastFilterType.Exclude
local antiBatTouchJumpHeld = false
local antiBatLastBurstTime = 0
local antiBatHoldInterval = 0.055
local antiBatInfJumpConn = nil
local antiBatRenderConnection = nil
local antiBatJumpRequestConn = nil
local antiBatTouchJumpConn = nil
local antiBatTouchJumpConnections = {}
local antiBatTouchJumpButtons = {}
local function antiBatInfJumpFloorStandY(r, hum, char)
	antiBatInfJumpRay.FilterDescendantsInstances = {char}
	local hit = workspace:Raycast(r.Position + Vector3.new(0,2.25,0), Vector3.new(0,-200,0), antiBatInfJumpRay)
	if not hit then return nil,nil end
	local floorY = hit.Position.Y
	local standY = floorY + hum.HipHeight + r.Size.Y * 0.5 + 0.12
	return standY,floorY
end
local function antiBatInfJumpCorrectSink(r, hum, _char, floorY, standY)
	if not floorY or not standY then return end
	if r.Position.Y >= floorY + 0.35 then return end
	r.CFrame = CFrame.new(r.Position.X, standY, r.Position.Z) * (r.CFrame - r.CFrame.Position)
	local v = r.Velocity
	r.Velocity = Vector3.new(v.X, math.max(0, v.Y), v.Z)
end
local function antiBatIsJumpInputHeld()
	if UIS:IsKeyDown(Enum.KeyCode.Space) then return true end
	local ok, down = pcall(function()
		return UIS:IsGamepadButtonDown(Enum.UserInputType.Gamepad1, Enum.KeyCode.ButtonA)
	end)
	if ok and down then return true end
	return antiBatTouchJumpHeld
end
local function antiBatDoInfiniteJumpBurst()
	if not antiBatInfJumpEnabled then return end
	local char = LP.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end
	antiBatInfJumpSession += 1
	local session = antiBatInfJumpSession
	local jy = 50
	if hum.UseJumpPower and hum.JumpPower > 0 then
		jy = hum.JumpPower
	else
		local jh = hum.JumpHeight
		if type(jh) == "number" and jh > 0 then
			jy = math.sqrt(math.max(0, 2 * workspace.Gravity * jh))
		end
	end
	jy = math.clamp(jy, 35, 95)
	local standY, floorY = antiBatInfJumpFloorStandY(hrp, hum, char)
	antiBatInfJumpCorrectSink(hrp, hum, char, floorY, standY)
	local v0 = hrp.Velocity
	hrp.Velocity = Vector3.new(v0.X, math.max(v0.Y * 0.15, jy), v0.Z)
	local postSim = RunService.PostSimulation
	local waitPhys = (postSim and function() postSim:Wait() end) or function() RunService.Heartbeat:Wait() end
	task.spawn(function()
		local c = char
		local boost = jy
		for i = 1, 10 do
			waitPhys()
			if session ~= antiBatInfJumpSession or LP.Character ~= c or not antiBatInfJumpEnabled then break end
			local r = c:FindFirstChild("HumanoidRootPart")
			local h = c:FindFirstChildOfClass("Humanoid")
			if not r or not h or h.Health <= 0 then break end
			local sy, fy = antiBatInfJumpFloorStandY(r, h, c)
			antiBatInfJumpCorrectSink(r, h, c, fy, sy)
			if i > 2 and h.FloorMaterial ~= Enum.Material.Air then break end
			local vel = r.Velocity
			if vel.Y < boost * 0.72 then
				r.Velocity = Vector3.new(
					vel.X,
					math.min(boost, math.max(vel.Y + boost * 0.42, boost * 0.72)),
					vel.Z
				)
			end
		end
	end)
end
local function antiBatStartInfJumpHandler()
	if antiBatRenderConnection then return end
	antiBatRenderConnection = RunService.RenderStepped:Connect(function()
		if not antiBatInfJumpEnabled then return end
		if not antiBatIsJumpInputHeld() then return end
		local now = tick()
		if now - antiBatLastBurstTime < antiBatHoldInterval then return end
		antiBatLastBurstTime = now
		antiBatDoInfiniteJumpBurst()
	end)
	antiBatInfJumpConn = antiBatRenderConnection
	if not antiBatJumpRequestConn then
		antiBatJumpRequestConn = UIS.JumpRequest:Connect(function()
			if antiBatInfJumpEnabled then
				antiBatLastBurstTime = tick()
				antiBatDoInfiniteJumpBurst()
			end
		end)
	end
	if not antiBatTouchJumpConn then
		task.defer(function()
			local pg = LP:WaitForChild("PlayerGui", 60)
			if not pg then return end
			if not antiBatInfJumpEnabled then return end
			local function hookJumpButton(btn)
				if not btn:IsA("GuiButton") or btn.Name ~= "JumpButton" or btn:GetAttribute("AntiBatInfJumpHoldHook") then return end
				btn:SetAttribute("AntiBatInfJumpHoldHook", true)
				table.insert(antiBatTouchJumpButtons, btn)
				table.insert(antiBatTouchJumpConnections, btn.MouseButton1Down:Connect(function() antiBatTouchJumpHeld = true end))
				table.insert(antiBatTouchJumpConnections, btn.MouseButton1Up:Connect(function() antiBatTouchJumpHeld = false end))
				table.insert(antiBatTouchJumpConnections, btn.MouseLeave:Connect(function() antiBatTouchJumpHeld = false end))
			end
			for _, d in ipairs(pg:GetDescendants()) do hookJumpButton(d) end
			antiBatTouchJumpConn = pg.DescendantAdded:Connect(hookJumpButton)
		end)
	end
end
local function antiBatStopInfJumpHandler()
	if antiBatRenderConnection then
		antiBatRenderConnection:Disconnect()
		antiBatRenderConnection = nil
	end
	antiBatInfJumpConn = nil
	if antiBatJumpRequestConn then
		antiBatJumpRequestConn:Disconnect()
		antiBatJumpRequestConn = nil
	end
	if antiBatTouchJumpConn then
		antiBatTouchJumpConn:Disconnect()
		antiBatTouchJumpConn = nil
	end
	for _,conn in ipairs(antiBatTouchJumpConnections) do
		pcall(function() conn:Disconnect() end)
	end
	antiBatTouchJumpConnections = {}
	for _,btn in ipairs(antiBatTouchJumpButtons) do
		pcall(function() btn:SetAttribute("AntiBatInfJumpHoldHook", nil) end)
	end
	antiBatTouchJumpButtons = {}
	antiBatInfJumpSession += 1
	antiBatLastBurstTime = 0
	antiBatTouchJumpHeld = false
end
local function antiBatToggleInfJump()
	antiBatInfJumpEnabled = not antiBatInfJumpEnabled
	if antiBatInfJumpEnabled then antiBatStartInfJumpHandler() else antiBatStopInfJumpHandler() end
end
startUnwalk = function()
	local c=LP.Character;if not c then return end
	local hum=c:FindFirstChildOfClass("Humanoid")
	if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
	local anim=c:FindFirstChild("Animate")
	if anim then unwalkSavedAnimate=anim:Clone();anim:Destroy() end
end
stopUnwalk = function()
	local c=LP.Character
	if c and unwalkSavedAnimate then unwalkSavedAnimate:Clone().Parent=c;unwalkSavedAnimate=nil end
end
local _wfConns={}
runDrop = function()
	if dropActive then return end
	if showActionNotification then showActionNotification("DROP!") end
	for _,c in ipairs(_wfConns) do
		if typeof(c)=="RBXScriptConnection" then
			pcall(function() c:Disconnect() end)
		elseif type(c)=="thread" then
			pcall(coroutine.close,c)
		end
	end
	_wfConns={}
	local char=LP.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if not char or not root then return end
	if autoBatEnabled then
		autoBatEnabled=false
		if resetAutoBatMotion then resetAutoBatMotion() end
		if autoBatSetVisual then autoBatSetVisual(false) end
		if refreshBatMotionAntiDieGuard then refreshBatMotionAntiDieGuard() end
	end
	-- Make sure character is not anchored / unstuck
	pcall(function() root.Anchored=false end)
	local hum=char:FindFirstChildOfClass("Humanoid")
	if hum then
		-- Ensure not in a state that blocks fling
		pcall(function() hum.PlatformStand=false end)
		pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
	end
	dropActive=true
	local changedCollisions={}
	local function cleanupDrop()
		dropActive=false
		for _,c in ipairs(_wfConns) do
			if typeof(c)=="RBXScriptConnection" then
				pcall(function() c:Disconnect() end)
			elseif type(c)=="thread" then
				pcall(coroutine.close,c)
			end
		end
		_wfConns={}
		for part,wasCollide in pairs(changedCollisions) do
			if typeof(part)=="Instance" and part.Parent then
				pcall(function() part.CanCollide=wasCollide end)
			end
		end
	end
	local colConn=RunService.Stepped:Connect(function()
		if not dropActive then return end
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LP and p.Character then
				for _,part in ipairs(p.Character:GetDescendants()) do
					if part:IsA("BasePart") then
						if changedCollisions[part]==nil then changedCollisions[part]=part.CanCollide end
						pcall(function() part.CanCollide=false end)
					end
				end
			end
		end
	end)
	table.insert(_wfConns,colConn)
	local flingThread=coroutine.create(function()
		while dropActive do
			RunService.Heartbeat:Wait()
			local c=LP.Character
			local r=c and c:FindFirstChild("HumanoidRootPart")
			if not r then break end
			pcall(function() r.Anchored=false end)
			local vel=r.Velocity
			pcall(function() r.Velocity=vel*10000+Vector3.new(0,10000,0) end)
			RunService.RenderStepped:Wait()
			if r and r.Parent then pcall(function() r.Velocity=vel end) end
			RunService.Stepped:Wait()
			if r and r.Parent then pcall(function() r.Velocity=vel+Vector3.new(0,0.1,0) end) end
		end
	end)
	table.insert(_wfConns,flingThread)
	local ok=coroutine.resume(flingThread)
	if not ok then cleanupDrop();return end
	task.delay(0.25,cleanupDrop)  -- 0.25s (was 0.16s) for more reliable drop registration
end
end  -- ADAPT FIX: split scope to free registers before doAutoTPDown
do   -- ADAPT FIX: fresh scope for TP / stretch / anti-lag prelude
local _lastTPTime = 0
local function doAutoTPDown(force)
	local char=LP.Character;if not char then return end
	local hrp=char:FindFirstChild("HumanoidRootPart");if not hrp then return end
	local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
	if hum2.Health<=0 then return end
	-- THROTTLE: prevent spamming TPs faster than 0.08s apart, which causes the game's anti-cheat / physics to reset the character
	local now = tick()
	if now - _lastTPTime < 0.08 then return end
	if not force then
		if hum2.FloorMaterial~=Enum.Material.Air then return end
		if not (hrp.Position.Y>=autoTPHeight) then return end
	end
	-- Skip if already at/below the target Y (avoids repeated downward TP into void)
	if hrp.Position.Y<=-6.5 and not force then return end
	_lastTPTime = now
	hrp.CFrame=CFrame.new(hrp.Position.X,-7.00,hrp.Position.Z)
		*CFrame.Angles(0,select(2,hrp.CFrame:ToEulerAnglesYXZ()),0)
	hrp.Velocity=Vector3.zero
end
startAutoTP = function()
	if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
	autoTPConn=task.spawn(function()
		while autoTPEnabled do
			task.wait(0.1)
			pcall(function() doAutoTPDown(false) end)
		end
	end)
end
stopAutoTP = function()
	autoTPEnabled=false
	if autoTPConn then task.cancel(autoTPConn);autoTPConn=nil end
end
runTPFloor = function()
	pcall(function() doAutoTPDown(true) end)
end
-- (defLightBrightness,defLightClock,defLightAmbient: forward-declared)
enableStretchRez = function()
	stretchRezEnabled=true
	workspace.CurrentCamera.FieldOfView=107
	if stretchRezConn then stretchRezConn:Disconnect() end
	stretchRezConn=RunService.RenderStepped:Connect(function()
		if not stretchRezEnabled then stretchRezConn:Disconnect();stretchRezConn=nil;return end
		workspace.CurrentCamera.FieldOfView=107
	end)
end
disableStretchRez = function()
	stretchRezEnabled=false
	if stretchRezConn then stretchRezConn:Disconnect();stretchRezConn=nil end
	workspace.CurrentCamera.FieldOfView=70
end
end  -- ADAPT FIX: close prior do block to free registers (200-limit fix)
do   -- ADAPT FIX: open fresh scope for anti-lag functions
local function applyAntiLagDerender(obj)
	pcall(function()
		if obj:IsA("Accessory") or obj:IsA("Hat") then obj:Destroy()
		elseif obj:IsA("BasePart") then obj.Material=Enum.Material.Plastic;obj.Reflectance=0;obj.CastShadow=false
		elseif obj:IsA("Decal") or obj:IsA("Texture") then obj.Transparency=1
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") or obj:IsA("Fire") or obj:IsA("Smoke") or obj:IsA("Sparkles") then obj.Enabled=false
		elseif obj:IsA("AnimationController") or obj:IsA("Animator") then
			for _,t in ipairs(obj:GetPlayingAnimationTracks()) do pcall(function() t:Stop(0) end) end
		end
	end)
end
enableAntiLag = function()
	removeAccessoriesEnabled=true
	antiLagEnabled=true
	defLightBrightness=defLightBrightness or Lighting.Brightness
	defLightClock=defLightClock or Lighting.ClockTime
	defLightAmbient=defLightAmbient or Lighting.OutdoorAmbient
	Lighting.GlobalShadows=false;Lighting.FogEnd=1e10;Lighting.Brightness=1
	Lighting.EnvironmentDiffuseScale=0;Lighting.EnvironmentSpecularScale=0
	for _,e in pairs(Lighting:GetChildren()) do
		pcall(function()
			if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then e.Enabled=false end
		end)
	end
	for _,obj in ipairs(workspace:GetDescendants()) do applyAntiLagDerender(obj) end
	if antiLagDescConn then antiLagDescConn:Disconnect() end
	antiLagDescConn=workspace.DescendantAdded:Connect(function(obj)
		if removeAccessoriesEnabled then applyAntiLagDerender(obj) end
	end)
end
end  -- ADAPT FIX: end of scope wrap
local function disableAntiLag()
	removeAccessoriesEnabled=false
	antiLagEnabled=false
	if antiLagDescConn then antiLagDescConn:Disconnect();antiLagDescConn=nil end
	pcall(function()
		if defLightBrightness then Lighting.Brightness=defLightBrightness end
		if defLightClock then Lighting.ClockTime=defLightClock end
		if defLightAmbient then Lighting.OutdoorAmbient=defLightAmbient end
		Lighting.ExposureCompensation=0
	end)
end

-- ============================================================
--  HIT COUNTDOWN (3, 2, 1, GO! when player gets knocked)
-- ============================================================
do  -- ADAPT FIX: scope wrap for hit countdown to free registers
local hitCountdownWatcherConn = nil
local hitCountdownCharAddedConn = nil
local hitCountdownToken = 0
local hitCountdownLabel = nil  -- pre-created label, reused

-- Pre-create BillboardGui + label on each character spawn (instead of per-countdown)
local function setupHitCountdownBillboard(char)
	if not char then return end
	local head = char:FindFirstChild("Head") or char:WaitForChild("Head",3)
	if not head then return end
	-- Clean any old
	local old = head:FindFirstChild("CandyHitCountdownBB")
	if old then pcall(function() old:Destroy() end) end
	local bb = Instance.new("BillboardGui",head)
	bb.Name = "CandyHitCountdownBB"
	bb.Size = UDim2.new(0,180,0,60)
	bb.StudsOffset = Vector3.new(0,5,0)
	bb.AlwaysOnTop = true
	local lbl = Instance.new("TextLabel",bb)
	lbl.Name = "HitCountdownLbl"
	lbl.Size = UDim2.new(1,0,1,0)
	lbl.BackgroundTransparency = 1
	lbl.Text = ""
	lbl.TextColor3 = Color3.fromRGB(255,255,255)
	lbl.Font = Enum.Font.GothamBlack
	lbl.TextScaled = true
	lbl.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	lbl.TextStrokeTransparency = 0.25
	lbl.Visible = false
	-- Pink-blue gradient on the text
	local grad = Instance.new("UIGradient",lbl)
	grad.Color = ColorSequence.new(CANDY_COLORS.ACCENT,CANDY_COLORS.ICE)
	grad.Rotation = 0
	hitCountdownLabel = lbl
end

local function startHitCountdown()
	if hitCountdownActive then return end
	if not hitCountdownLabel or not hitCountdownLabel.Parent then
		setupHitCountdownBillboard(LP.Character)
	end
	if not hitCountdownLabel or not hitCountdownLabel.Parent then return end
	hitCountdownActive = true
	hitCountdownToken = hitCountdownToken + 1
	local myToken = hitCountdownToken
	local lbl = hitCountdownLabel

	task.spawn(function()
		lbl.Visible = true
		for cd = 3, 1, -1 do
			if myToken ~= hitCountdownToken then return end
			lbl.Text = tostring(cd)
			task.wait(1)
		end
		if myToken ~= hitCountdownToken then return end
		lbl.Text = "GO!"
		-- Wait for ragdoll state to END before hiding
		repeat
			task.wait(0.1)
		until (function()
			if myToken ~= hitCountdownToken then return true end
			local c = LP.Character
			local h = c and c:FindFirstChildOfClass("Humanoid")
			if not h then return true end
			local s = h:GetState()
			return s ~= Enum.HumanoidStateType.Physics
				and s ~= Enum.HumanoidStateType.Ragdoll
				and s ~= Enum.HumanoidStateType.FallingDown
		end)()
		if myToken ~= hitCountdownToken then return end
		task.wait(0.25)
		if myToken ~= hitCountdownToken then return end
		lbl.Visible = false
		lbl.Text = ""
		hitCountdownActive = false
	end)
end

startHitCountdownSystem = function()
	-- Setup billboard on current character
	if LP.Character then setupHitCountdownBillboard(LP.Character) end
	-- Re-setup on respawn
	if not hitCountdownCharAddedConn then
		hitCountdownCharAddedConn = LP.CharacterAdded:Connect(function(char)
			task.wait(0.4)
			if hitCountdownEnabled then setupHitCountdownBillboard(char) end
		end)
	end
	-- Heartbeat watcher (more reliable than StateChanged for custom-ragdoll games)
	if not hitCountdownWatcherConn then
		hitCountdownWatcherConn = RunService.Heartbeat:Connect(function()
			if not hitCountdownEnabled then return end
			local c = LP.Character;if not c then return end
			local hum = c:FindFirstChildOfClass("Humanoid");if not hum then return end
			local st = hum:GetState()
			if st == Enum.HumanoidStateType.Physics
				or st == Enum.HumanoidStateType.Ragdoll
				or st == Enum.HumanoidStateType.FallingDown then
				startHitCountdown()
			end
		end)
	end
end

stopHitCountdownSystem = function()
	if hitCountdownWatcherConn then
		pcall(function() hitCountdownWatcherConn:Disconnect() end)
		hitCountdownWatcherConn = nil
	end
	if hitCountdownCharAddedConn then
		pcall(function() hitCountdownCharAddedConn:Disconnect() end)
		hitCountdownCharAddedConn = nil
	end
	hitCountdownToken = hitCountdownToken + 1
	hitCountdownActive = false
	-- Remove the BillboardGui from the character's head if present
	local char = LP.Character
	if char then
		local head = char:FindFirstChild("Head")
		if head then
			local bb = head:FindFirstChild("CandyHitCountdownBB")
			if bb then pcall(function() bb:Destroy() end) end
		end
	end
	hitCountdownLabel = nil
end
end  -- ADAPT FIX: end scope wrap for hit countdown

-- ============================================================
--  ACTION NOTIFICATION (DROP! / TP DOWN! popup)
-- ============================================================
do  -- ADAPT FIX: scope for action notification
local actionNotifGui = nil

showActionNotification = function(text)
	if not actionNotifGui or not actionNotifGui.Parent then
		actionNotifGui = Instance.new("ScreenGui")
		actionNotifGui.Name = "CandyActionNotif"
		actionNotifGui.ResetOnSpawn = false
		actionNotifGui.DisplayOrder = 55
		actionNotifGui.IgnoreGuiInset = true
		pcall(function() if syn and syn.protect_gui then syn.protect_gui(actionNotifGui) end end)
		if not pcall(function() actionNotifGui.Parent = CoreGui end) then
			actionNotifGui.Parent = LP:WaitForChild("PlayerGui")
		end
	end
	actionNotifGui:ClearAllChildren()

	local label = Instance.new("TextLabel", actionNotifGui)
	label.Size = UDim2.new(0, 320, 0, 80)
	label.Position = UDim2.new(0.5, -160, 0.2, -40)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(255,255,255)
	label.Font = Enum.Font.GothamBlack
	label.TextSize = 60
	label.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	label.TextStrokeTransparency = 0.25
	label.TextTransparency = 1
	label.ZIndex = 55

	local grad = Instance.new("UIGradient", label)
	grad.Color = ColorSequence.new(CANDY_COLORS.ACCENT, CANDY_COLORS.ICE)
	grad.Rotation = 0

	-- Pop in with bounce
	label.TextSize = 30
	TS:Create(label, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		TextSize = 64,
		TextTransparency = 0
	}):Play()

	task.delay(0.45, function()
		if not label or not label.Parent then return end
		TS:Create(label, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			TextTransparency = 1,
			TextSize = 50
		}):Play()
		task.delay(0.32, function()
			if label and label.Parent then label:Destroy() end
		end)
	end)
end
end  -- ADAPT FIX: end action notification scope

-- ============================================================
--  AIMBOT TARGET DISPLAY (small "LOCKED: PlayerName" indicator)
-- ============================================================
do  -- ADAPT FIX: scope for aimbot target display
local targetGui = nil
local targetLabel = nil
task.spawn(function()
	task.wait(2)
	-- Create the GUI lazily once, then update text + visibility every frame
	local sg = Instance.new("ScreenGui")
	sg.Name = "CandyAimbotTarget"
	sg.ResetOnSpawn = false
	sg.DisplayOrder = 40
	sg.IgnoreGuiInset = true
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(sg) end end)
	if not pcall(function() sg.Parent = CoreGui end) then
		sg.Parent = LP:WaitForChild("PlayerGui")
	end
	targetGui = sg

	local f = Instance.new("Frame", sg)
	f.Size = UDim2.new(0, 200, 0, 36)
	f.Position = UDim2.new(0.5, -100, 0, 80)
	f.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
	f.BackgroundTransparency = 0.12
	f.BorderSizePixel = 0
	f.Visible = false
	Instance.new("UICorner", f).CornerRadius = UDim.new(0, 8)
	local st = Instance.new("UIStroke", f); st.Color = CANDY_COLORS.ACCENT; st.Thickness = 1; st.Transparency = 0.2
	local stGrad = Instance.new("UIGradient", st)
	stGrad.Color = ColorSequence.new(CANDY_COLORS.ACCENT, CANDY_COLORS.ICE)
	stGrad.Rotation = 0

	local lockTxt = Instance.new("TextLabel", f)
	lockTxt.Size = UDim2.new(0, 60, 1, 0)
	lockTxt.Position = UDim2.new(0, 10, 0, 0)
	lockTxt.BackgroundTransparency = 1
	lockTxt.Text = "LOCKED"
	lockTxt.TextColor3 = Color3.fromRGB(255,255,255)
	lockTxt.Font = Enum.Font.GothamBlack
	lockTxt.TextSize = 11
	lockTxt.TextXAlignment = Enum.TextXAlignment.Left

	targetLabel = Instance.new("TextLabel", f)
	targetLabel.Size = UDim2.new(1, -76, 1, 0)
	targetLabel.Position = UDim2.new(0, 70, 0, 0)
	targetLabel.BackgroundTransparency = 1
	targetLabel.Text = ""
	targetLabel.TextColor3 = Color3.fromRGB(255,255,255)
	targetLabel.Font = Enum.Font.GothamBlack
	targetLabel.TextSize = 12
	targetLabel.TextXAlignment = Enum.TextXAlignment.Left
	targetLabel.TextTruncate = Enum.TextTruncate.AtEnd

	local labelGrad = Instance.new("UIGradient", targetLabel)
	labelGrad.Color = ColorSequence.new(CANDY_COLORS.ACCENT, CANDY_COLORS.ICE)
	labelGrad.Rotation = 0

	-- Animate stroke rotation
	local rot = 0
	RunService.Heartbeat:Connect(function(dt)
		rot = (rot + (dt or 0.016) * 35) % 360
		stGrad.Rotation = rot
		-- Update visibility and text from current aimbot target
		if autoBatEnabled and _aimbotTargetPlr and _aimbotTargetPlr.Parent then
			local name = _aimbotTargetPlr.DisplayName or _aimbotTargetPlr.Name or "?"
			if targetLabel.Text ~= name then targetLabel.Text = name end
			if not f.Visible then f.Visible = true end
		else
			if f.Visible then f.Visible = false end
		end
	end)
end)
end  -- ADAPT FIX: end aimbot target display scope

local function findMedusa()
	local c=LP.Character;if not c then return nil end
	for _,t in ipairs(c:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end
	local bp=LP:FindFirstChild("Backpack")
	if bp then for _,t in ipairs(bp:GetChildren()) do if t:IsA("Tool") then local n=t.Name:lower();if n:find("medusa") or n:find("head") or n:find("stone") then return t end end end end
	return nil
end
local function useMedusaCounter()
	if medusaDebounce then return end;if tick()-medusaLastUsed<MEDUSA_COOLDOWN then return end
	local c=LP.Character;if not c then return end;medusaDebounce=true
	local med=findMedusa();if not med then medusaDebounce=false;return end
	if med.Parent~=c then local hum2=c:FindFirstChildOfClass("Humanoid");if hum2 then hum2:EquipTool(med) end end
	pcall(function() med:Activate() end);medusaLastUsed=tick();medusaDebounce=false
end
local function onAnchorChanged(part)
	return part:GetPropertyChangedSignal("Anchored"):Connect(function()
		if part.Anchored and part.Transparency==1 then useMedusaCounter() end
	end)
end
local function setupMedusa(char)
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
	if not char then return end
	for _,part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end end
	table.insert(Conns.anchor,char.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") then table.insert(Conns.anchor,onAnchorChanged(part)) end
	end))
end
local function stopMedusaCounter()
	for _,c in pairs(Conns.anchor) do pcall(function() c:Disconnect() end) end;Conns.anchor={}
end
local BAT_COUNTER_SLAP_LIST={"Bat","Slap","Iron Slap","Gold Slap","Diamond Slap","Emerald Slap","Ruby Slap","Dark Matter Slap","Flame Slap","Nuclear Slap","Galaxy Slap","Glitched Slap"}
local function findBatForCounter()
	local c=LP.Character;if not c then return nil end
	local bp=LP:FindFirstChildOfClass("Backpack")
	for _,name in ipairs(BAT_COUNTER_SLAP_LIST) do
		local t=c:FindFirstChild(name) or (bp and bp:FindFirstChild(name));if t then return t end
	end
	for _,ch in ipairs(c:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end
	if bp then for _,ch in ipairs(bp:GetChildren()) do if ch:IsA("Tool") and ch.Name:lower():find("bat") then return ch end end end
	return nil
end
local function swingBatForCounter(bat,char)
	local hum2=char:FindFirstChildOfClass("Humanoid")
	if bat.Parent~=char then if hum2 then pcall(function() hum2:EquipTool(bat) end) end;task.wait(0.05) end
	local remote=bat:FindFirstChildOfClass("RemoteEvent") or bat:FindFirstChildOfClass("RemoteFunction")
	if remote and remote:IsA("RemoteEvent") then
		pcall(function() remote:FireServer() end);task.wait(0.15);pcall(function() remote:FireServer() end)
	else pcall(function() bat:Activate() end);task.wait(0.15);pcall(function() bat:Activate() end) end
end
startBatCounter=function()
	if Conns.batCounter then return end
	Conns.batCounter=RunService.Heartbeat:Connect(function()
		if not batCounterEnabled then return end
		if batCounterDebounce then return end
		local char=LP.Character;if not char then return end
		local hum2=char:FindFirstChildOfClass("Humanoid");if not hum2 then return end
		local st=hum2:GetState()
		if st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown then
			batCounterDebounce=true
			task.spawn(function()
				local bat=findBatForCounter()
				if bat then swingBatForCounter(bat,char) end
				task.wait(0.5);batCounterDebounce=false
			end)
		end
	end)
end
stopBatCounter=function()
	if Conns.batCounter then Conns.batCounter:Disconnect();Conns.batCounter=nil end
	batCounterDebounce=false
end
-- ============================================================
--  AUTO BAT / BAT AIMBOT BACKEND
-- ============================================================
local _aimbotTarget = nil
local _aimbotTargetPlr = nil

resetAutoBatMotion=function()
	local char=LP.Character
	local hrp=char and char:FindFirstChild("HumanoidRootPart")
	local hum=char and char:FindFirstChildOfClass("Humanoid")
	if hrp then
		hrp.Velocity=hrp.Velocity*0.3
		hrp.AssemblyAngularVelocity=Vector3.zero
	end
	if hum then hum.AutoRotate=true end
end

local function findBat()
	local char=LP.Character
	if not char then return nil end
	for _,tool in ipairs(char:GetChildren()) do
		if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
	end
	local bp=LP:FindFirstChild("Backpack")
	if bp then
		for _,tool in ipairs(bp:GetChildren()) do
			if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
		end
	end
	return nil
end

local function getClosestTarget()
	local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil,nil end
	local closest,closestPlr,minDist=nil,nil,math.huge
	for _,plr in ipairs(Players:GetPlayers()) do
		if plr~=LP and plr.Character then
			local tRoot=plr.Character:FindFirstChild("HumanoidRootPart")
			local hum=plr.Character:FindFirstChildOfClass("Humanoid")
			if tRoot and hum and hum.Health>0 then
				local dist=(tRoot.Position-root.Position).Magnitude
				if dist<minDist then minDist=dist;closest=tRoot;closestPlr=plr end
			end
		end
	end
	return closest,closestPlr,minDist
end

-- Get target with stickiness: prefer existing target unless new one is 30% closer
local function getStickyTarget(currentRoot)
	local root=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
	if not root then return nil,nil end
	local newClosest,newPlr,newDist=getClosestTarget()
	if not newClosest then return nil,nil end
	if currentRoot and currentRoot.Parent then
		local currentPlr=Players:GetPlayerFromCharacter(currentRoot.Parent)
		local hum=currentRoot.Parent:FindFirstChildOfClass("Humanoid")
		if currentPlr and hum and hum.Health>0 then
			local currentDist=(currentRoot.Position-root.Position).Magnitude
			-- Keep current if new isn't significantly closer (30%) or new is same player
			if currentPlr==newPlr or newDist>currentDist*0.7 then
				return currentRoot,currentPlr
			end
		end
	end
	return newClosest,newPlr
end

local function swingCurrentBat(char)
	if not autoSwingEnabled then return end
	local bat=findBat()
	if bat and bat.Parent==char and bat:IsA("Tool") then
		pcall(function() bat:Activate() end)
	end
end

startBatAimbot=function()
	if Conns.aimbot then Conns.aimbot:Disconnect() end
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end

	autoBatEnabled=true
	State.AutoBat=true
	State.BatAimbot=true
	if refreshBatMotionAntiDieGuard then refreshBatMotionAntiDieGuard() end

	local hum0=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
	if hum0 then hum0.AutoRotate=false end

	Conns.aimbot=RunService.RenderStepped:Connect(function()
		if not autoBatEnabled then return end
		local char=LP.Character;if not char then return end
		local root=char:FindFirstChild("HumanoidRootPart");if not root then return end
		local hum=char:FindFirstChildOfClass("Humanoid");if not hum then return end

		if not char:FindFirstChildOfClass("Tool") then
			local bat=findBat()
			if bat then pcall(function() hum:EquipTool(bat) end) end
		end

		-- STICKY TARGET: keep current unless a new one is significantly closer
		local target,targetPlr=getStickyTarget(_aimbotTarget)
		if not target then 
			_aimbotTarget=nil;_aimbotTargetPlr=nil
			swingCurrentBat(char);return 
		end
		_aimbotTarget=target
		_aimbotTargetPlr=targetPlr

		local targetVel=target.Velocity
		local myPos=root.Position
		local targetPos=target.Position
		local distance=(targetPos-myPos).Magnitude

		-- ADAPTIVE PREDICTION: more lead time for fast/distant targets
		local speedFactor=math.clamp(targetVel.Magnitude/40,0,1.2)  -- 0..1.2
		local distFactor=math.clamp(distance/80,0,1)  -- 0..1
		local leadTime=0.14+speedFactor*0.12+distFactor*0.08  -- 0.14 .. 0.34s
		local predictPos=targetPos+targetVel*leadTime
		predictPos=predictPos+target.CFrame.LookVector*0.3

		local direction=predictPos-myPos
		local flatDir=Vector3.new(direction.X,0,direction.Z)
		if flatDir.Magnitude>0.01 then flatDir=flatDir.Unit else flatDir=Vector3.new(0,0,0) end

		-- EXACT chase speed: use the value the user set, no auto-boosts.
		-- (Previously was: aimbotSpeed + distance_bonus + velocity_bonus, which made 56 -> 80+)
		local chaseSpeed=aimbotSpeed

		-- JUMPING TARGET: track higher when target has upward velocity
		local jumpOffset=math.max(0,targetVel.Y*0.18)
		local desiredHeight=targetPos.Y+3.7+jumpOffset
		local yVel=(desiredHeight-myPos.Y)*22+targetVel.Y*1.1
		if hum.FloorMaterial~=Enum.Material.Air then
			yVel=math.max(yVel,13)
		end
		yVel=math.clamp(yVel,-70,135)

		local desiredVel=Vector3.new(flatDir.X*chaseSpeed,yVel,flatDir.Z*chaseSpeed)
		root.Velocity=root.Velocity:Lerp(desiredVel,0.85)

		-- ROTATION TRACKING: adaptive based on target movement
		local rotPredictTime=math.clamp(targetVel.Magnitude/120,0.05,0.25)
		local predictedPos=targetPos+targetVel*rotPredictTime
		local toPredict=predictedPos-myPos
		if toPredict.Magnitude>0.1 then
			local goalCF=CFrame.lookAt(myPos,predictedPos)
			local diffCF=root.CFrame:Inverse()*goalCF
			local rx,ry,rz=diffCF:ToEulerAnglesXYZ()
			rx=math.clamp(rx,-2.5,2.5)
			ry=math.clamp(ry,-2.5,2.5)
			rz=math.clamp(rz,-2.5,2.5)
			root.AssemblyAngularVelocity=root.CFrame:VectorToWorldSpace(Vector3.new(rx*50,ry*50,rz*50))
		end

		swingCurrentBat(char)
	end)
end

stopBatAimbot=function()
	if Conns.aimbot then Conns.aimbot:Disconnect();Conns.aimbot=nil end
	_aimbotTarget=nil
	_aimbotTargetPlr=nil
	autoBatEnabled=false
	State.AutoBat=false
	State.BatAimbot=false
	local char=LP.Character
	local root=char and char:FindFirstChild("HumanoidRootPart")
	if root then root.Velocity=Vector3.zero;root.AssemblyAngularVelocity=Vector3.zero end
	local hum2=char and char:FindFirstChildOfClass("Humanoid")
	if hum2 then hum2.AutoRotate=true end
	State.hittingCooldown=false
	if resetAutoBatMotion then resetAutoBatMotion() end
	if refreshBatMotionAntiDieGuard then refreshBatMotionAntiDieGuard() end
end

local function queueAutoLeftStart()
	autoLeftEnabled=true
	if autoRightEnabled then autoRightEnabled=false;if autoRightSetVisual then autoRightSetVisual(false) end;stopAutoRight() end
	if autoBatEnabled then stopBatAimbot();if autoBatSetVisual then autoBatSetVisual(false) end end
	startAutoLeft()
end

local function queueAutoRightStart()
	autoRightEnabled=true
	if autoLeftEnabled then autoLeftEnabled=false;if autoLeftSetVisual then autoLeftSetVisual(false) end;stopAutoLeft() end
	if autoBatEnabled then stopBatAimbot();if autoBatSetVisual then autoBatSetVisual(false) end end
	startAutoRight()
end

LP.CharacterRemoving:Connect(function()
	if antiDieEnabled or batMotionAntiDieGuard then
		antiDieToken+=1
		clearAntiDieConns()
	end
end)
LP.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	setupSpeedIndicator(char)
	if antiDieEnabled or batMotionAntiDieGuard then startAntiDie() end
	if medusaCounterEnabled then setupMedusa(char) end
	if batCounterEnabled then startBatCounter() end
	if autoBatEnabled then task.wait(0.2);resetAutoBatMotion();startBatAimbot() end
	if unwalkEnabled then task.wait(0.5);startUnwalk() end
end)
if LP.Character then setupSpeedIndicator(LP.Character) end
local function hookOtherSpeed(plr)
	if plr==LP then return end
	if plr.Character then task.spawn(function() setupSpeedIndicator(plr.Character,plr) end) end
	plr.CharacterAdded:Connect(function(char) task.wait(0.5);setupSpeedIndicator(char,plr) end)
	plr.CharacterRemoving:Connect(function() otherSpeedLabels[plr]=nil end)
end
for _,plr in ipairs(Players:GetPlayers()) do hookOtherSpeed(plr) end
Players.PlayerAdded:Connect(hookOtherSpeed)
Players.PlayerRemoving:Connect(function(plr) otherSpeedLabels[plr]=nil end)

local CANDY_SKY_TAG = "CandyHubSkyTheme"
_G._CandyHubSkyMode = _G._CandyHubSkyMode or "Off"
local candyOriginalLighting = nil

-- Added full custom sky preset set from uploaded skys.txt.
local CANDY_SKY_PRESETS = {
    ["Off"] = {kind = "off"},

    ["Night"] = {
        clock = 22, brightness = 2,
        ambient = {110,100,130}, outAmb = {120,110,140},
        sky = {stars = 4000, moon = 18, sun = 0, moonTex = true},
        atm = {dens = 0.45, color = {120,60,180}, decay = {60,20,100}, glare = 0.5, haze = 1.2},
    },
    ["Aurora"] = {
        clock = 14, brightness = 3,
        ambient = {150,120,150}, outAmb = {160,130,160},
        atm = {dens = 0.55, color = {255,80,200}, decay = {255,20,150}, glare = 2.5, haze = 3},
        clouds = {cover = 0.7, dens = 0.7, color = {255,240,250}},
    },
    ["Sunset"] = {
        clock = 17.2, brightness = 2.5,
        ambient = {170,120,100}, outAmb = {180,130,110},
        sky = {stars = 0, sun = 25, moon = 0},
        atm = {dens = 0.5, color = {255,130,60}, decay = {255,80,30}, glare = 2, haze = 2.5},
        clouds = {cover = 0.55, dens = 0.55, color = {255,200,140}},
    },
    ["Galaxy"] = {
        clock = 0, brightness = 1.5,
        ambient = {70,60,100}, outAmb = {80,70,110},
        sky = {stars = 10000, moon = 30, sun = 0},
        atm = {dens = 0.15, color = {40,20,80}, decay = {20,10,50}, glare = 0.3, haze = 0.5},
    },
    ["Cyber"] = {
        clock = 21, brightness = 2.2,
        ambient = {90,130,170}, outAmb = {100,140,180},
        sky = {stars = 2000, moon = 12},
        atm = {dens = 0.4, color = {0,200,255}, decay = {150,0,255}, glare = 2, haze = 2},
        clouds = {cover = 0.4, dens = 0.6, color = {100,200,255}},
    },
    ["Sakura"] = {
        clock = 11, brightness = 3.5,
        ambient = {170,150,160}, outAmb = {180,160,170},
        sky = {sun = 8},
        atm = {dens = 0.3, color = {255,200,220}, decay = {255,170,200}, glare = 1, haze = 1.5},
        clouds = {cover = 0.6, dens = 0.4, color = {255,250,252}},
    },
    ["Pink Night"] = {
        clock = 23, brightness = 2.2,
        ambient = {120,60,110}, outAmb = {140,70,120},
        sky = {stars = 5000, moon = 22, sun = 0, moonTex = true},
        atm = {dens = 0.5, color = {255,80,180}, decay = {140,30,100}, glare = 0.7, haze = 1.4},
        clouds = {cover = 0.3, dens = 0.5, color = {180,90,150}},
    },

    -- ════════════════════════════════════════════════════════════════
    -- 15 NEW PRESETS
    -- ════════════════════════════════════════════════════════════════

    ["Blood Moon"] = {
        clock = 22.5, brightness = 1.6,
        ambient = {130,40,40}, outAmb = {150,50,50},
        sky = {stars = 1500, moon = 28, sun = 0, moonTex = true},
        atm = {dens = 0.6, color = {220,30,30}, decay = {120,10,10}, glare = 1.4, haze = 2},
        clouds = {cover = 0.5, dens = 0.7, color = {120,30,30}},
    },
    ["Emerald Dawn"] = {
        clock = 6.5, brightness = 2.8,
        ambient = {130,170,140}, outAmb = {140,180,150},
        sky = {sun = 18, moon = 0, stars = 0},
        atm = {dens = 0.4, color = {80,200,140}, decay = {40,150,90}, glare = 1.8, haze = 2.2},
        clouds = {cover = 0.5, dens = 0.5, color = {200,255,220}},
    },
    ["Volcanic"] = {
        clock = 19, brightness = 2,
        ambient = {180,80,40}, outAmb = {200,90,50},
        sky = {stars = 200, sun = 12, moon = 0},
        atm = {dens = 0.75, color = {255,60,0}, decay = {180,20,0}, glare = 3, haze = 3.5},
        clouds = {cover = 0.8, dens = 0.9, color = {120,40,20}},
    },
    ["Arctic"] = {
        clock = 9, brightness = 3.2,
        ambient = {200,220,235}, outAmb = {210,230,245},
        sky = {sun = 10, stars = 0, moon = 0},
        atm = {dens = 0.3, color = {180,220,255}, decay = {140,200,240}, glare = 1.5, haze = 1.8},
        clouds = {cover = 0.7, dens = 0.6, color = {250,253,255}},
    },
    ["Midnight Ocean"] = {
        clock = 1.5, brightness = 1.7,
        ambient = {60,90,130}, outAmb = {70,100,140},
        sky = {stars = 6000, moon = 24, sun = 0, moonTex = true},
        atm = {dens = 0.5, color = {20,60,140}, decay = {10,30,90}, glare = 0.6, haze = 1.5},
    },
    ["Vaporwave"] = {
        clock = 19.5, brightness = 2.4,
        ambient = {180,120,200}, outAmb = {190,130,210},
        sky = {stars = 1000, moon = 14},
        atm = {dens = 0.45, color = {255,100,220}, decay = {120,60,255}, glare = 2.2, haze = 2.4},
        clouds = {cover = 0.5, dens = 0.55, color = {200,150,255}},
    },
    ["Toxic"] = {
        clock = 13, brightness = 2.5,
        ambient = {140,180,80}, outAmb = {150,190,90},
        atm = {dens = 0.55, color = {100,220,40}, decay = {60,150,20}, glare = 1.8, haze = 2.6},
        clouds = {cover = 0.65, dens = 0.7, color = {180,255,120}},
    },
    ["Solar Eclipse"] = {
        clock = 12, brightness = 0.9,
        ambient = {50,40,60}, outAmb = {60,50,70},
        sky = {stars = 3500, sun = 22, moon = 0},
        atm = {dens = 0.5, color = {255,140,40}, decay = {30,20,40}, glare = 2.8, haze = 1.8},
    },
    ["Hellscape"] = {
        clock = 18, brightness = 1.8,
        ambient = {200,60,30}, outAmb = {220,70,40},
        sky = {stars = 100, sun = 30, moon = 0},
        atm = {dens = 0.85, color = {255,30,0}, decay = {120,0,0}, glare = 3.5, haze = 4},
        clouds = {cover = 0.95, dens = 0.95, color = {80,20,10}},
    },
    ["Heaven"] = {
        clock = 12, brightness = 4,
        ambient = {240,235,210}, outAmb = {250,245,220},
        sky = {sun = 16, moon = 0, stars = 0},
        atm = {dens = 0.25, color = {255,250,220}, decay = {255,240,200}, glare = 3, haze = 1.5},
        clouds = {cover = 0.85, dens = 0.5, color = {255,255,255}},
    },
    ["Storm"] = {
        clock = 15, brightness = 1.4,
        ambient = {90,90,110}, outAmb = {100,100,120},
        sky = {stars = 0, sun = 6, moon = 0},
        atm = {dens = 0.65, color = {80,90,120}, decay = {40,50,80}, glare = 0.5, haze = 3},
        clouds = {cover = 0.95, dens = 0.95, color = {60,65,80}},
    },
    ["Sunrise"] = {
        clock = 6.2, brightness = 2.8,
        ambient = {220,180,130}, outAmb = {230,190,140},
        sky = {sun = 22, stars = 0, moon = 0},
        atm = {dens = 0.45, color = {255,180,100}, decay = {255,140,80}, glare = 2.4, haze = 2.2},
        clouds = {cover = 0.4, dens = 0.4, color = {255,220,180}},
    },
    ["Deep Space"] = {
        clock = 0, brightness = 1,
        ambient = {30,25,50}, outAmb = {40,35,60},
        sky = {stars = 15000, moon = 0, sun = 0},
        atm = {dens = 0.08, color = {15,5,40}, decay = {5,0,20}, glare = 0.2, haze = 0.3},
    },
    ["Lavender Dream"] = {
        clock = 18.5, brightness = 2.6,
        ambient = {180,160,220}, outAmb = {190,170,230},
        sky = {stars = 800, moon = 16, sun = 0},
        atm = {dens = 0.4, color = {200,160,255}, decay = {160,120,220}, glare = 1.4, haze = 1.8},
        clouds = {cover = 0.55, dens = 0.5, color = {220,200,255}},
    },
    ["Inferno"] = {
        clock = 17.5, brightness = 2.2,
        ambient = {220,100,40}, outAmb = {235,110,50},
        sky = {sun = 26, moon = 0, stars = 0},
        atm = {dens = 0.6, color = {255,90,20}, decay = {200,40,0}, glare = 3, haze = 3.2},
        clouds = {cover = 0.7, dens = 0.7, color = {200,80,40}},
    },
    ["Mint Sky"] = {
        clock = 10, brightness = 3.2,
        ambient = {180,230,210}, outAmb = {190,240,220},
        sky = {sun = 10},
        atm = {dens = 0.32, color = {150,255,210}, decay = {100,220,180}, glare = 1.6, haze = 1.6},
        clouds = {cover = 0.55, dens = 0.45, color = {240,255,250}},
    },
}

local function candySaveOriginalLighting()
	if candyOriginalLighting then return end
	candyOriginalLighting={
		ClockTime=Lighting.ClockTime,
		OutdoorAmbient=Lighting.OutdoorAmbient,
		Ambient=Lighting.Ambient,
		Brightness=Lighting.Brightness,
		FogStart=Lighting.FogStart,
		FogEnd=Lighting.FogEnd,
		FogColor=Lighting.FogColor,
		ColorShift_Top=Lighting.ColorShift_Top,
		ColorShift_Bottom=Lighting.ColorShift_Bottom,
		GeographicLatitude=Lighting.GeographicLatitude,
		GlobalShadows=Lighting.GlobalShadows,
		LightingChildren={},
		TerrainChildren={}
	}
	for _,child in ipairs(Lighting:GetChildren()) do
		if child:IsA("Sky") or child:IsA("Atmosphere") then table.insert(candyOriginalLighting.LightingChildren,child:Clone()) end
	end
	local terrain=workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		for _,child in ipairs(terrain:GetChildren()) do
			if child:IsA("Clouds") then table.insert(candyOriginalLighting.TerrainChildren,child:Clone()) end
		end
	end
end

local function candyClearSky(removeAll)
	for _,child in ipairs(Lighting:GetChildren()) do
		if child:GetAttribute(CANDY_SKY_TAG) or (removeAll and (child:IsA("Sky") or child:IsA("Atmosphere"))) then pcall(function() child:Destroy() end) end
	end
	local terrain=workspace:FindFirstChildOfClass("Terrain")
	if terrain then
		for _,child in ipairs(terrain:GetChildren()) do
			if child:GetAttribute(CANDY_SKY_TAG) or (removeAll and child:IsA("Clouds")) then pcall(function() child:Destroy() end) end
		end
	end
end

local function candyInstance(className,parent,props)
	local inst=Instance.new(className)
	inst:SetAttribute(CANDY_SKY_TAG,true)
	for k,v in pairs(props or {}) do pcall(function() inst[k]=v end) end
	inst.Parent=parent
	return inst
end

local function candyColor(rgb)
	return Color3.fromRGB(rgb[1],rgb[2],rgb[3])
end

local function CandyApplyCustomSky(mode)
	candySaveOriginalLighting()
	candyClearSky(true)
	local terrain=workspace:FindFirstChildOfClass("Terrain")
	local preset=CANDY_SKY_PRESETS[mode]
	if not preset or preset.kind=="off" then
		if candyOriginalLighting then
			for k,v in pairs(candyOriginalLighting) do
				if k~="LightingChildren" and k~="TerrainChildren" then pcall(function() Lighting[k]=v end) end
			end
			for _,child in ipairs(candyOriginalLighting.LightingChildren or {}) do child:Clone().Parent=Lighting end
			local offTerrain=workspace:FindFirstChildOfClass("Terrain")
			if offTerrain then
				for _,child in ipairs(candyOriginalLighting.TerrainChildren or {}) do child:Clone().Parent=offTerrain end
			end
		end
		_G._CandyHubSkyMode="Off"
		return
	end

	Lighting.FogStart=0
	Lighting.FogEnd=100000
	Lighting.FogColor=Color3.fromRGB(200,200,200)
	Lighting.ColorShift_Top=Color3.fromRGB(0,0,0)
	Lighting.ColorShift_Bottom=Color3.fromRGB(0,0,0)
	Lighting.GlobalShadows=true
	Lighting.ClockTime=preset.clock or 14
	Lighting.Brightness=preset.brightness or 2
	if preset.outAmb then Lighting.OutdoorAmbient=candyColor(preset.outAmb) end
	if preset.ambient then Lighting.Ambient=candyColor(preset.ambient) end

	if preset.sky then
		local skyProps={}
		if preset.sky.stars then skyProps.StarCount=preset.sky.stars end
		if preset.sky.moon then skyProps.MoonAngularSize=preset.sky.moon end
		if preset.sky.sun then skyProps.SunAngularSize=preset.sky.sun end
		if preset.sky.moonTex then skyProps.MoonTextureId="rbxasset://sky/moon.jpg" end
		candyInstance("Sky",Lighting,skyProps)
	end

	if preset.atm then
		candyInstance("Atmosphere",Lighting,{
			Density=preset.atm.dens or 0.3,
			Color=candyColor(preset.atm.color),
			Decay=candyColor(preset.atm.decay),
			Glare=preset.atm.glare or 1,
			Haze=preset.atm.haze or 1
		})
	end

	if preset.clouds and terrain then
		candyInstance("Clouds",terrain,{
			Cover=preset.clouds.cover or 0.5,
			Density=preset.clouds.dens or 0.5,
			Color=candyColor(preset.clouds.color)
		})
	end

	_G._CandyHubSkyMode=mode
end

local CandySkyOrder={{"Off","Off"},{"Night","Night"},{"Aurora","Aurora"},{"Sunset","Sunset"},{"Galaxy","Galaxy"},{"Cyber","Cyber"},{"Sakura","Sakura"},{"Pink Night","Pink Night"},{"Blood Moon","Blood Moon"},{"Emerald Dawn","Emerald Dawn"},{"Volcanic","Volcanic"},{"Arctic","Arctic"},{"Midnight Ocean","Midnight Ocean"},{"Vaporwave","Vaporwave"},{"Toxic","Toxic"},{"Solar Eclipse","Solar Eclipse"},{"Hellscape","Hellscape"},{"Heaven","Heaven"},{"Storm","Storm"},{"Sunrise","Sunrise"},{"Deep Space","Deep Space"},{"Lavender Dream","Lavender Dream"},{"Inferno","Inferno"},{"Mint Sky","Mint Sky"}}

-- ============================================================
--  CONFIG HELPERS
-- ============================================================
local function saveConfig()
	local function ks(e) return {kb=e.kb and e.kb.Name or nil,gp=e.gp and e.gp.Name or nil} end
	local cfg={
		normalSpeed=NS,carrySpeed=CS,
		dropBrainrotKey=ks(KB.DropBrainrot),autoLeftKey=ks(KB.AutoLeft),autoRightKey=ks(KB.AutoRight),speedToggleKey=ks(KB.SpeedToggle),
		autoBatKey=ks(KB.AutoBat),antiBatLockKey=ks(KB.AntiBatLock),laggerToggleKey=ks(KB.LaggerToggle),tpFloorKey=ks(KB.TPFloor),instaResetKey=ks(KB.InstaReset),guiHideKey=ks(KB.GuiHide),
		autoStealRange=CONFIG.STEAL_RANGE,holdMax=CONFIG.HOLD_MAX,
		antiRagdoll=antiRagdollEnabled,antiDie=antiDieEnabled,autoStealEnabled=CONFIG.AUTO_STEAL_ENABLED,
		hitCountdown=hitCountdownEnabled,
		infiniteJump=infJumpEnabled,medusaCounter=medusaCounterEnabled,
		batCounter=batCounterEnabled,
		carryMode=speedMode,laggerMode=laggerToggled,laggerSpeed=LAGGER_SPEED,laggerCarrySpeed=LAGGER_CARRY_SPEED,
		aimbotSpeed=aimbotSpeed,
		autoBat=autoBatEnabled,autoSwing=autoSwingEnabled,
		unwalkEnabled=unwalkEnabled,
		antiLag=antiLagEnabled,stretchRez=stretchRezEnabled,
		candyAntiBatLock=candyAntiBatLockEnabled,
		autoTPEnabled=autoTPEnabled,autoTPHeight=autoTPHeight,
		showIntro=showIntroEnabled,
		uiLocked=uiLocked,
		uiScale=uiScaleValue,
		mobileButtonScale=mobileButtonScaleValue,
		editMobileButtons=editMobileButtons,
		hideMobileButtons=hideMobileButtons,
		mobileButtonPositions=mobileButtonPositions,
		mobileGroupPosition=mobileGroupPosition,
		instaResetPanelOpen=instaResetPanelOpen,
		instaResetPanelPosition=instaResetPanelPosition,
		progressBarPosition=progressBarPosition,
		mainPanelOpen=(_G._candyMainOpen~=false),  -- true by default
		mainPanelPos=_G._candyMainPanelPos,
		showFpsPing=(_G._candyShowFpsPing~=false),  -- true by default
		skyTheme=currentSkyTheme
	}
	if writefile then pcall(function() writefile("CandyHub.json",HS:JSONEncode(cfg)) end) end
end
task.spawn(function() while task.wait(5) do saveConfig() end end)

-- ============================================================
--  UI STATE / HELPERS
-- ============================================================
local setInstaGrab,setInfJumpVisual,setAntiRagVisual,setAntiDieVisual,setMedusaVisual,setShowIntroVisual,setHitCountdownVisual,setShowFpsPingVisual
local setUnwalkVisual,setAntiLagVisual,setAutoSwingVisual
local normalBox,carryBox,laggerBox,laggerCarryBox,radInput,holdMaxBox,autoTPHeightBox
refreshSpeedModeLabel=function()
	if modeValLbl then
		if laggerToggled and speedMode then
			modeValLbl.Text="Lagger Carry"
		elseif laggerToggled then
			modeValLbl.Text="Lagger"
		elseif speedMode then
			modeValLbl.Text="Carry"
		else
			modeValLbl.Text="Normal"
		end
	end
end
local function toggleCarryMode()
	speedMode=not speedMode
	refreshSpeedModeLabel()
end
local function toggleLaggerMode()
	laggerToggled=not laggerToggled
	refreshSpeedModeLabel()
end
local function setCarryModeState(on)
	if speedMode~=on then
		toggleCarryMode()
	else
		refreshSpeedModeLabel()
	end
end
local function setLaggerModeState(on)
	if laggerToggled~=on then
		toggleLaggerMode()
	else
		refreshSpeedModeLabel()
	end
end

-- ============================================================
--  INTRO ANIMATION
-- ============================================================
local function playCandyIntro(gui,main,miniBtn)
	if not showIntroEnabled or not gui or not main then return end
	local originalMainPos = main.Position
	main.Visible = false
	if miniBtn then miniBtn.Visible = false end
	local blur=Instance.new("BlurEffect")
	blur.Size=0
	blur.Parent=Lighting
	local snd=Instance.new("Sound")
	snd.SoundId="rbxassetid://126107591945718"
	snd.Volume=0.55
	snd.Looped=false
	snd.TimePosition=34
	snd.Parent=SoundService
	pcall(function() snd:Play() end)
	local intro=Instance.new("Frame",gui)
	intro.Name="CandyHubIntro"
	intro.Size=UDim2.new(1,0,1,0)
	intro.Position=UDim2.new(0,0,0,0)
	intro.BackgroundColor3=Color3.fromRGB(0,0,0)
	intro.BackgroundTransparency=1
	intro.BorderSizePixel=0
	intro.ZIndex=200
	local logo=Instance.new("Frame",intro)
	logo.Size=UDim2.new(0,58,0,58);logo.Position=UDim2.new(0.5,-29,0.5,-108);logo.BackgroundColor3=CANDY_COLORS.CARD;logo.BackgroundTransparency=1;logo.BorderSizePixel=0;logo.ZIndex=201
	Instance.new("UICorner",logo).CornerRadius=UDim.new(0,14)
	local logoStroke=Instance.new("UIStroke",logo);logoStroke.Color=CANDY_COLORS.ACCENT;logoStroke.Thickness=1.2;logoStroke.Transparency=0.1
	local mark=Instance.new("TextLabel",logo)
	mark.Size=UDim2.new(1,0,1,0);mark.BackgroundTransparency=1;mark.Text="C";mark.TextColor3=CANDY_COLORS.ACCENT;mark.Font=Enum.Font.GothamBlack;mark.TextSize=34;mark.TextTransparency=1;mark.ZIndex=202
	local title=Instance.new("TextLabel",intro)
	title.Size=UDim2.new(0,520,0,52);title.Position=UDim2.new(0.5,-260,0.5,-36)
	title.BackgroundTransparency=1;title.Text=CANDY_BRAND;title.TextColor3=CANDY_COLORS.TEXT
	title.Font=Enum.Font.GothamBlack;title.TextSize=34;title.TextTransparency=1;title.ZIndex=201;title.TextXAlignment=Enum.TextXAlignment.Center
	local sub=Instance.new("TextLabel",intro)
	sub.Size=UDim2.new(0,520,0,24);sub.Position=UDim2.new(0.5,-260,0.5,12)
	sub.BackgroundTransparency=1;sub.Text="LOADING ASSETS...";sub.TextColor3=CANDY_COLORS.ICE
	sub.Font=Enum.Font.GothamBlack;sub.TextSize=16;sub.TextTransparency=1;sub.ZIndex=201;sub.TextXAlignment=Enum.TextXAlignment.Center
	local loading=Instance.new("TextLabel",intro)
	loading.Size=UDim2.new(0,520,0,18);loading.Position=UDim2.new(0.5,-260,0.5,72);loading.BackgroundTransparency=1;loading.Text=CANDY_DISCORD;loading.TextColor3=CANDY_COLORS.SECONDARY;loading.Font=Enum.Font.GothamBold;loading.TextSize=11;loading.TextTransparency=1;loading.TextXAlignment=Enum.TextXAlignment.Center;loading.ZIndex=201
	local barBg=Instance.new("Frame",intro)
	barBg.Size=UDim2.new(0,210,0,3);barBg.Position=UDim2.new(0.5,-105,0.5,45);barBg.BackgroundColor3=Color3.fromRGB(20,20,26);barBg.BorderSizePixel=0;barBg.ZIndex=201
	Instance.new("UICorner",barBg).CornerRadius=UDim.new(1,0)
	local bar=Instance.new("Frame",barBg)
	bar.Size=UDim2.new(0,0,1,0);bar.BackgroundColor3=CANDY_COLORS.TEXT;bar.BorderSizePixel=0;bar.ZIndex=202
	Instance.new("UICorner",bar).CornerRadius=UDim.new(1,0)
	local barGrad=Instance.new("UIGradient",bar);barGrad.Color=ColorSequence.new(CANDY_COLORS.ACCENT,CANDY_COLORS.ICE)
	TS:Create(blur,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=34}):Play()
	TS:Create(intro,TweenInfo.new(0.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=0.32}):Play()
	TS:Create(logo,TweenInfo.new(0.35),{BackgroundTransparency=0}):Play()
	TS:Create(logoStroke,TweenInfo.new(0.28),{Transparency=0.02}):Play()
	TS:Create(mark,TweenInfo.new(0.22),{TextTransparency=0}):Play()
	TS:Create(title,TweenInfo.new(0.25),{TextTransparency=0}):Play()
	TS:Create(sub,TweenInfo.new(0.25),{TextTransparency=0}):Play()
	TS:Create(loading,TweenInfo.new(0.25),{TextTransparency=0}):Play()
	TS:Create(bar,TweenInfo.new(2.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Size=UDim2.new(1,0,1,0)}):Play()
	local blink=true
	task.spawn(function()
		while blink and intro.Parent do
			task.wait(0.15)
			local hidden=mark.TextTransparency<0.5
			mark.TextTransparency=hidden and 1 or 0
			title.TextTransparency=hidden and 0.35 or 0
			sub.TextTransparency=hidden and 0.55 or 0
		end
	end)
	local finished=false
	local function finishIntro()
		if finished then return end
		finished=true
		if not intro.Parent then return end
		blink=false
		sub.Text="READY"
		sub.TextColor3=CANDY_COLORS.ACCENT
		task.wait(0.15)
		main.Position=UDim2.new(originalMainPos.X.Scale,originalMainPos.X.Offset,originalMainPos.Y.Scale,originalMainPos.Y.Offset+18)
		main.Visible=true
		TS:Create(main,TweenInfo.new(0.28,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{Position=originalMainPos}):Play()
		TS:Create(blur,TweenInfo.new(0.35,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{Size=0}):Play()
		TS:Create(intro,TweenInfo.new(0.35,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
		TS:Create(logo,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
		TS:Create(mark,TweenInfo.new(0.25),{TextTransparency=1}):Play()
		TS:Create(title,TweenInfo.new(0.25),{TextTransparency=1}):Play()
		TS:Create(sub,TweenInfo.new(0.25),{TextTransparency=1}):Play()
		TS:Create(loading,TweenInfo.new(0.25),{TextTransparency=1}):Play()
		TS:Create(barBg,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
		TS:Create(bar,TweenInfo.new(0.25),{BackgroundTransparency=1}):Play()
		TS:Create(snd,TweenInfo.new(0.5),{Volume=0}):Play()
		task.delay(0.55,function()
			pcall(function() snd:Stop();snd:Destroy() end)
			pcall(function() blur:Destroy() end)
			if intro then intro:Destroy() end
		end)
	end

	-- SKIP INTRO: a full-screen invisible button on top catches any click/tap and skips
	local skipBtn=Instance.new("TextButton",intro)
	skipBtn.Size=UDim2.new(1,0,1,0)
	skipBtn.Position=UDim2.new(0,0,0,0)
	skipBtn.BackgroundTransparency=1
	skipBtn.Text=""
	skipBtn.AutoButtonColor=false
	skipBtn.ZIndex=205
	skipBtn.Activated:Connect(finishIntro)

	-- "Tap to skip" hint at the bottom of the intro
	local skipHint=Instance.new("TextLabel",intro)
	skipHint.Size=UDim2.new(1,0,0,18);skipHint.Position=UDim2.new(0,0,1,-40);skipHint.BackgroundTransparency=1
	skipHint.Text="tap anywhere to skip";skipHint.TextColor3=CANDY_COLORS.SECONDARY;skipHint.Font=Enum.Font.GothamMedium;skipHint.TextSize=10;skipHint.TextTransparency=1;skipHint.TextXAlignment=Enum.TextXAlignment.Center;skipHint.ZIndex=204
	TS:Create(skipHint,TweenInfo.new(0.6),{TextTransparency=0.3}):Play()

	-- Skip via keyboard (Escape / Space)
	local skipConn
	skipConn=UIS.InputBegan:Connect(function(input,gpe)
		if gpe then return end
		if input.KeyCode==Enum.KeyCode.Escape or input.KeyCode==Enum.KeyCode.Space or input.KeyCode==Enum.KeyCode.Return then
			finishIntro()
			if skipConn then skipConn:Disconnect();skipConn=nil end
		end
	end)
	task.delay(3.2,function() if skipConn then skipConn:Disconnect();skipConn=nil end end)

	task.delay(2.75,finishIntro)
end

-- ============================================================
--  GUI BUILDER
-- ============================================================
local function buildGui()
	local BG=CANDY_COLORS.BG
	local PANEL=CANDY_COLORS.PANEL
	local CARD=CANDY_COLORS.CARD
	local ACCENT=CANDY_COLORS.ACCENT
	local ICE=CANDY_COLORS.ICE
	local HOVER=CANDY_COLORS.HOVER
	local W=CANDY_COLORS.TEXT
	local DIM=CANDY_COLORS.SECONDARY
	local STROKE=CANDY_COLORS.STROKE
	local INP=CANDY_COLORS.INPUT
	local OFF=CANDY_COLORS.OFF
	local PURPLE=CANDY_COLORS.PURPLE
	local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
	local GUI_W,GUI_H = IsMobile and 248 or 360, IsMobile and 360 or 462
	local HDR_H = IsMobile and 52 or 58
	local LOGO = IsMobile and 30 or 34
	local PAD = IsMobile and 8 or 10
	local PAGE_TOP = HDR_H + (IsMobile and 10 or 12)
	local PAGE_BOTTOM = PAGE_TOP + (IsMobile and 8 or 10)
	local ROW_H = IsMobile and 28 or 31
	local SECTION_H = IsMobile and 16 or 18
	local old=game:GetService("CoreGui"):FindFirstChild("CandyHub");if old then old:Destroy() end
	local pg=LP:FindFirstChild("PlayerGui");if pg then local o=pg:FindFirstChild("CandyHub");if o then o:Destroy() end end
	local gui=Instance.new("ScreenGui")
	gui.Name="CandyHub";gui.ResetOnSpawn=false;gui.DisplayOrder=10;gui.IgnoreGuiInset=true
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
	if not pcall(function() gui.Parent=game:GetService("CoreGui") end) then gui.Parent=LP:WaitForChild("PlayerGui") end
	local function drag(f,onDragState)
		local dn,ds,sp,di=false
		local moved=false
		local threshold=6
		f.InputBegan:Connect(function(i)
			if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then
				if uiLocked then return end
				dn=true;ds=i.Position;sp=f.Position
				moved=false
				if onDragState then onDragState(false,false) end
				i.Changed:Connect(function()
					if i.UserInputState==Enum.UserInputState.End then
						dn=false
						if onDragState then onDragState(false,moved) end
					end
				end)
			end
		end)
		f.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then di=i end end)
		UIS.InputChanged:Connect(function(i)
			if i==di and dn and not uiLocked then
				local dx,dy=i.Position.X-ds.X,i.Position.Y-ds.Y
				if (math.abs(dx)>threshold or math.abs(dy)>threshold) and not moved then moved=true;if onDragState then onDragState(true,true) end end
				f.Position=UDim2.new(sp.X.Scale,sp.X.Offset+dx,sp.Y.Scale,sp.Y.Offset+dy)
			end
		end)
	end
	local function buildInstaResetPanel()
		local PANEL_W,PANEL_H=296,182
		local panel=Instance.new("Frame",gui)
		panel.Name="CandyInstaResetPanel"
		panel.Size=UDim2.new(0,PANEL_W,0,PANEL_H)
		panel.Position=instaResetPanelPosition and UDim2.new(instaResetPanelPosition.xs or 0,instaResetPanelPosition.x or 26,instaResetPanelPosition.ys or 0,instaResetPanelPosition.y or 96) or UDim2.new(0,26,0,96)
		panel.BackgroundColor3=BG
		panel.BorderSizePixel=0
		panel.Active=false
		panel.Visible=false
		panel.ZIndex=60
		instaResetPanelRef=panel
		Instance.new("UICorner",panel).CornerRadius=UDim.new(0,18)
		local stroke=Instance.new("UIStroke",panel);stroke.Color=ACCENT;stroke.Thickness=1.4;stroke.Transparency=0.18
		local grad=Instance.new("UIGradient",stroke);grad.Color=ColorSequence.new(ACCENT,ICE);grad.Rotation=45

		-- Drag handle covers the title area
		local dragBtn=Instance.new("TextButton",panel)
		dragBtn.Size=UDim2.new(1,-56,0,60);dragBtn.Position=UDim2.new(0,0,0,0);dragBtn.BackgroundTransparency=1;dragBtn.Text="";dragBtn.AutoButtonColor=false;dragBtn.ZIndex=61

		-- Title
		local title=Instance.new("TextLabel",panel)
		title.Size=UDim2.new(1,-78,0,28);title.Position=UDim2.new(0,22,0,18);title.BackgroundTransparency=1;title.Text="CANDY INSTA RESET";title.TextColor3=Color3.fromRGB(255,255,255);title.Font=Enum.Font.GothamBlack;title.TextSize=17;title.TextXAlignment=Enum.TextXAlignment.Left;title.ZIndex=62
		local titleGrad=Instance.new("UIGradient",title);titleGrad.Color=ColorSequence.new(ACCENT,ICE);titleGrad.Rotation=0

		-- Close button (top right X)
		local close=Instance.new("TextButton",panel)
		close.Size=UDim2.new(0,30,0,30);close.Position=UDim2.new(1,-44,0,16);close.BackgroundColor3=CARD;close.BorderSizePixel=0
		close.Text="✕";close.TextColor3=ACCENT;close.Font=Enum.Font.GothamBlack;close.TextSize=14;close.AutoButtonColor=false;close.ZIndex=63
		Instance.new("UICorner",close).CornerRadius=UDim.new(0,9)
		local closeStroke=Instance.new("UIStroke",close);closeStroke.Color=ACCENT;closeStroke.Thickness=1;closeStroke.Transparency=0.4
		close.MouseEnter:Connect(function() TS:Create(close,TweenInfo.new(0.12),{BackgroundColor3=Color3.fromRGB(20,20,26)}):Play();TS:Create(closeStroke,TweenInfo.new(0.12),{Transparency=0.08}):Play() end)
		close.MouseLeave:Connect(function() TS:Create(close,TweenInfo.new(0.12),{BackgroundColor3=CARD}):Play();TS:Create(closeStroke,TweenInfo.new(0.12),{Transparency=0.4}):Play() end)

		-- Inner card with "Reset" label and big keybind button
		local card=Instance.new("Frame",panel)
		card.Size=UDim2.new(1,-32,0,68);card.Position=UDim2.new(0,16,0,62);card.BackgroundColor3=CARD;card.BorderSizePixel=0;card.ZIndex=61
		Instance.new("UICorner",card).CornerRadius=UDim.new(0,14)
		local cardStroke=Instance.new("UIStroke",card);cardStroke.Color=STROKE;cardStroke.Thickness=1;cardStroke.Transparency=0.5

		local resetLabel=Instance.new("TextLabel",card)
		resetLabel.Size=UDim2.new(0.5,0,1,0);resetLabel.Position=UDim2.new(0,20,0,0);resetLabel.BackgroundTransparency=1
		resetLabel.Text="Reset";resetLabel.TextColor3=W;resetLabel.Font=Enum.Font.GothamBold;resetLabel.TextSize=15;resetLabel.TextXAlignment=Enum.TextXAlignment.Left;resetLabel.ZIndex=62

		-- Big keybind / reset button (pink-purple gradient)
		local reset=Instance.new("TextButton",card)
		reset.Size=UDim2.new(0,98,0,44);reset.Position=UDim2.new(1,-114,0.5,-22);reset.BackgroundColor3=ACCENT;reset.BorderSizePixel=0
		local resetKeyText=function()
			local entry=KB.InstaReset
			return (entry and entry.kb and entry.kb.Name) or (entry and entry.gp and entry.gp.Name) or "T"
		end
		reset.Text=resetKeyText();reset.TextColor3=Color3.fromRGB(255,255,255);reset.Font=Enum.Font.GothamBlack;reset.TextSize=18;reset.AutoButtonColor=false;reset.ZIndex=62
		Instance.new("UICorner",reset).CornerRadius=UDim.new(0,12)
		local btnGrad=Instance.new("UIGradient",reset)
		btnGrad.Color=ColorSequence.new(ACCENT,PURPLE)
		btnGrad.Rotation=35
		local resetStroke=Instance.new("UIStroke",reset);resetStroke.Color=Color3.fromRGB(255,180,230);resetStroke.Thickness=1;resetStroke.Transparency=0.4
		reset.MouseEnter:Connect(function() TS:Create(resetStroke,TweenInfo.new(0.12),{Transparency=0.05}):Play();TS:Create(reset,TweenInfo.new(0.12),{Size=UDim2.new(0,102,0,46),Position=UDim2.new(1,-116,0.5,-23)}):Play() end)
		reset.MouseLeave:Connect(function() TS:Create(resetStroke,TweenInfo.new(0.12),{Transparency=0.4}):Play();TS:Create(reset,TweenInfo.new(0.12),{Size=UDim2.new(0,98,0,44),Position=UDim2.new(1,-114,0.5,-22)}):Play() end)
		reset.Activated:Connect(function() cursedInstaReset() end)

		-- Refresh button label when keybind changes
		task.spawn(function()
			while panel.Parent do
				local nt=resetKeyText()
				if reset.Text~=nt then reset.Text=nt end
				task.wait(0.5)
			end
		end)

		-- Discord at bottom
		local disc=Instance.new("TextLabel",panel)
		disc.Size=UDim2.new(1,-32,0,18);disc.Position=UDim2.new(0,16,1,-32);disc.BackgroundTransparency=1
		disc.Text="discord.gg/candyhub";disc.TextColor3=Color3.fromRGB(255,255,255);disc.Font=Enum.Font.GothamBold;disc.TextSize=11;disc.TextXAlignment=Enum.TextXAlignment.Center;disc.ZIndex=61
		local discGrad=Instance.new("UIGradient",disc)
		discGrad.Color=ColorSequence.new(ICE,ACCENT)
		discGrad.Rotation=0

		setInstaResetPanelVisible=function(on,skipSave)
			instaResetPanelOpen=on and true or false
			panel.Visible=instaResetPanelOpen
			if not skipSave then saveConfig() end
		end
		close.Activated:Connect(function() if setInstaResetPanelVisible then setInstaResetPanelVisible(false) end end)

		local dragging=false
		local startInput,startPosition=nil,nil
		dragBtn.InputBegan:Connect(function(input)
			if uiLocked then return end
			if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			dragging=true;startInput=input.Position;startPosition=panel.Position
			input.Changed:Connect(function()
				if input.UserInputState==Enum.UserInputState.End then
					dragging=false
					instaResetPanelPosition={xs=panel.Position.X.Scale,x=panel.Position.X.Offset,ys=panel.Position.Y.Scale,y=panel.Position.Y.Offset}
					saveConfig()
				end
			end)
		end)
		UIS.InputChanged:Connect(function(input)
			if not dragging or uiLocked or not startInput or not startPosition then return end
			if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
			local dx,dy=input.Position.X-startInput.X,input.Position.Y-startInput.Y
			panel.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+dx,startPosition.Y.Scale,startPosition.Y.Offset+dy)
		end)
	end
	local main=Instance.new("Frame",gui)
	main.Size=UDim2.new(0,GUI_W,0,GUI_H);main.Position=UDim2.new(0,20,0,20)
	main.BackgroundColor3=BG;main.BorderSizePixel=0;main.ClipsDescendants=false
	mainUIScale=Instance.new("UIScale",main)
	mainUIScale.Scale=(IsMobile and 0.75 or 1)*uiScaleValue
	Instance.new("UICorner",main).CornerRadius=UDim.new(0,16)
	local mainStroke=Instance.new("UIStroke",main);mainStroke.Color=ACCENT;mainStroke.Thickness=1.2;mainStroke.Transparency=0.2
	local mainStrokeGrad=Instance.new("UIGradient",mainStroke);mainStrokeGrad.Color=ColorSequence.new(ACCENT,ICE);mainStrokeGrad.Rotation=45
	drag(main,function(active,moved)
		if not active and moved then
			_G._candyMainPanelPos={xs=main.Position.X.Scale,x=main.Position.X.Offset,ys=main.Position.Y.Scale,y=main.Position.Y.Offset}
			pcall(saveConfig)
		end
	end)
	buildInstaResetPanel()
	local hdr=Instance.new("Frame",main)
	hdr.Size=UDim2.new(1,0,0,HDR_H);hdr.BackgroundColor3=BG;hdr.BorderSizePixel=0
	Instance.new("UICorner",hdr).CornerRadius=UDim.new(0,16)
	local logo=Instance.new("ImageLabel",hdr)
	logo.Size=UDim2.new(0,LOGO,0,LOGO);logo.Position=UDim2.new(0,12,0,IsMobile and 11 or 12);logo.BackgroundColor3=CARD;logo.BorderSizePixel=0
	logo.Image="rbxassetid://132178375106504";logo.ImageColor3=Color3.fromRGB(255,255,255);logo.ScaleType=Enum.ScaleType.Fit
	Instance.new("UICorner",logo).CornerRadius=UDim.new(0,10)
	local logoStroke=Instance.new("UIStroke",logo);logoStroke.Color=ACCENT;logoStroke.Thickness=1;logoStroke.Transparency=0.15
	local ttl=Instance.new("TextLabel",hdr)
	ttl.Size=UDim2.new(1,-(IsMobile and 84 or 98),0,IsMobile and 19 or 22);ttl.Position=UDim2.new(0,IsMobile and 50 or 56,0,IsMobile and 10 or 11)
	ttl.BackgroundTransparency=1;ttl.Text=CANDY_BRAND;ttl.TextColor3=Color3.fromRGB(255,255,255);ttl.Font=Enum.Font.GothamBlack;ttl.TextSize=IsMobile and 14 or 17;ttl.TextXAlignment=Enum.TextXAlignment.Left
	local ttlGrad=Instance.new("UIGradient",ttl);ttlGrad.Color=ColorSequence.new(ACCENT,ICE);ttlGrad.Rotation=0
	local sub=Instance.new("TextLabel",hdr)
	sub.Size=UDim2.new(1,-(IsMobile and 84 or 98),0,15);sub.Position=UDim2.new(0,IsMobile and 50 or 56,0,IsMobile and 29 or 34)
	sub.BackgroundTransparency=1;sub.Text=CANDY_DISCORD;sub.TextColor3=Color3.fromRGB(255,255,255);sub.Font=Enum.Font.GothamMedium;sub.TextSize=IsMobile and 9 or 10;sub.TextXAlignment=Enum.TextXAlignment.Left
	local subGrad=Instance.new("UIGradient",sub);subGrad.Color=ColorSequence.new(ICE,ACCENT);subGrad.Rotation=0
	local closeBtn=Instance.new("TextButton",hdr)
	closeBtn.Size=UDim2.new(0,IsMobile and 23 or 26,0,IsMobile and 23 or 26);closeBtn.Position=UDim2.new(1,IsMobile and -32 or -38,0,IsMobile and 11 or 14);closeBtn.BackgroundColor3=CARD;closeBtn.BorderSizePixel=0
	closeBtn.Text="-";closeBtn.TextColor3=ACCENT;closeBtn.Font=Enum.Font.GothamBold;closeBtn.TextSize=IsMobile and 17 or 20
	Instance.new("UICorner",closeBtn).CornerRadius=UDim.new(1,0)
	local lockBtn=Instance.new("TextButton",hdr)
	lockBtn.Size=UDim2.new(0,IsMobile and 34 or 42,0,IsMobile and 23 or 26);lockBtn.Position=UDim2.new(1,IsMobile and -70 or -88,0,IsMobile and 11 or 14);lockBtn.BackgroundColor3=Color3.fromRGB(255,255,255);lockBtn.BorderSizePixel=0
	lockBtn.Text=uiLocked and "🔒" or "🔓";lockBtn.TextColor3=Color3.fromRGB(15,5,25);lockBtn.Font=Enum.Font.GothamBlack;lockBtn.TextSize=IsMobile and 13 or 15;lockBtn.AutoButtonColor=false
	Instance.new("UICorner",lockBtn).CornerRadius=UDim.new(1,0)
	-- BLUE CANDY style - cyan gradient (lighter cyan to deeper blue)
	local lockBtnGrad=Instance.new("UIGradient",lockBtn)
	lockBtnGrad.Color=ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(140, 220, 255)),  -- light cyan
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 180, 255)),   -- ICE
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 120, 230)),     -- deeper blue
	}
	lockBtnGrad.Rotation=90  -- vertical gradient (light on top, dark on bottom = candy/glossy look)
	local lockStroke=Instance.new("UIStroke",lockBtn);lockStroke.Color=Color3.fromRGB(0,180,255);lockStroke.Thickness=1;lockStroke.Transparency=0.34
	local lockStrokeGrad=Instance.new("UIGradient",lockStroke)
	lockStrokeGrad.Color=ColorSequence.new(Color3.fromRGB(140,220,255),Color3.fromRGB(0,120,230))
	lockStrokeGrad.Rotation=90
	local function setGuiLock(on,skipSave)
		uiLocked=on and true or false
		if setTopLockVisual then setTopLockVisual(uiLocked) end
		if setLockGuiVisual then setLockGuiVisual(uiLocked) end
		if not skipSave then saveConfig() end
	end
	setTopLockVisual=function(on)
		lockBtn.Text=on and "🔒" or "🔓"
		lockStroke.Transparency=on and 0.02 or 0.34
		lockStroke.Thickness=on and 2 or 1
	end
	lockBtn.Activated:Connect(function() setGuiLock(not uiLocked) end)
	local divider=Instance.new("Frame",hdr);divider.Size=UDim2.new(1,-24,0,1);divider.Position=UDim2.new(0,12,1,-1);divider.BackgroundColor3=W;divider.BorderSizePixel=0;divider.BackgroundTransparency=0.15
	local divGrad=Instance.new("UIGradient",divider);divGrad.Color=ColorSequence.new(ACCENT,ICE)
	local miniBtn=Instance.new("TextButton",gui)
	miniBtn.Size=UDim2.new(0,116,0,32);miniBtn.Position=UDim2.new(0,26,0,26);miniBtn.BackgroundColor3=PANEL;miniBtn.BorderSizePixel=0
	miniBtn.Text="Candy Hub";miniBtn.TextColor3=W;miniBtn.Font=Enum.Font.GothamBold;miniBtn.TextSize=12;miniBtn.ZIndex=20;miniBtn.Visible=false
	Instance.new("UICorner",miniBtn).CornerRadius=UDim.new(0,8)
	local miniStroke=Instance.new("UIStroke",miniBtn);miniStroke.Color=ACCENT;miniStroke.Thickness=1;miniStroke.Transparency=0.2
	local miniDragged=false
	drag(miniBtn,function(active,moved) if moved then miniDragged=true end;if not active and moved then task.delay(0.12,function() miniDragged=false end) end end)
	local function showGui() main.Visible=true;miniBtn.Visible=false;_G._candyMainOpen=true;pcall(saveConfig) end
	local function hideGui()
		main.Visible=false;miniBtn.Visible=true
		-- Auto-disable edit mode when hiding GUI - so the EDIT MODE banner also closes
		if editMobileButtons then
			editMobileButtons=false
			refreshMobileButtonUi()
			if setEditMobileVisual then setEditMobileVisual(false) end
		end
		_G._candyMainOpen=false;pcall(saveConfig)
	end
	showCandyGui=showGui;hideCandyGui=hideGui;isCandyGuiVisible=function() return main.Visible end
	closeBtn.MouseButton1Click:Connect(hideGui);miniBtn.Activated:Connect(function() if miniDragged then return end;showGui() end)

	local pbFrame=Instance.new("Frame",gui)
	pbFrame.Size=UDim2.new(0,302,0,40)
	if progressBarPosition then
		pbFrame.Position=UDim2.new(progressBarPosition.xs or 0.5,progressBarPosition.x or -151,progressBarPosition.ys or 1,progressBarPosition.y or -64)
	else
		pbFrame.Position=UDim2.new(0.5,-151,1,-64)
	end
	pbFrame.BackgroundColor3=BG;pbFrame.BorderSizePixel=0;pbFrame.ClipsDescendants=false
	pbFrame.Active=true
	Instance.new("UICorner",pbFrame).CornerRadius=UDim.new(0,12)
	local pbs=Instance.new("UIStroke",pbFrame);pbs.Color=ACCENT;pbs.Thickness=1.1;pbs.Transparency=0.16
	local pbsGrad=Instance.new("UIGradient",pbs);pbsGrad.Color=ColorSequence.new(ACCENT,ICE);pbsGrad.Rotation=25

	-- Helper: create a vertical separator
	local function mkSep(x)
		local sep=Instance.new("Frame",pbFrame)
		sep.Size=UDim2.new(0,1,0,14);sep.Position=UDim2.new(0,x,0,5);sep.BackgroundColor3=Color3.fromRGB(70,70,90);sep.BorderSizePixel=0;sep.BackgroundTransparency=0.45
		return sep
	end

	-- STATUS (left)
	progressPct=Instance.new("TextLabel",pbFrame)
	progressPct.Size=UDim2.new(0,62,0,14);progressPct.Position=UDim2.new(0,10,0,5);progressPct.BackgroundTransparency=1
	progressPct.Text=(CONFIG.AUTO_STEAL_ENABLED and "READY" or "IDLE");progressPct.TextColor3=W;progressPct.Font=Enum.Font.GothamBlack;progressPct.TextSize=9;progressPct.TextXAlignment=Enum.TextXAlignment.Left

	mkSep(76)

	-- FPS (pink, after status)
	local fpsLbl=Instance.new("TextLabel",pbFrame)
	fpsLbl.Size=UDim2.new(0,52,0,14);fpsLbl.Position=UDim2.new(0,82,0,5);fpsLbl.BackgroundTransparency=1
	fpsLbl.Text="FPS:--";fpsLbl.TextColor3=ACCENT;fpsLbl.Font=Enum.Font.GothamBlack;fpsLbl.TextSize=9;fpsLbl.TextXAlignment=Enum.TextXAlignment.Left

	local sepFps=mkSep(138)

	-- PING (cyan, middle)
	local pingLbl=Instance.new("TextLabel",pbFrame)
	pingLbl.Size=UDim2.new(0,72,0,14);pingLbl.Position=UDim2.new(0,144,0,5);pingLbl.BackgroundTransparency=1
	pingLbl.Text="PING:--";pingLbl.TextColor3=ICE;pingLbl.Font=Enum.Font.GothamBlack;pingLbl.TextSize=9;pingLbl.TextXAlignment=Enum.TextXAlignment.Left

	local sepPing=mkSep(220)

	-- Save refs for toggle access
	_G._candyFpsLbl=fpsLbl
	_G._candyPingLbl=pingLbl
	_G._candySepFps=sepFps
	_G._candySepPing=sepPing
	-- Apply saved show/hide
	local showFpsPing = _G._candyShowFpsPing
	if showFpsPing == false then
		fpsLbl.Visible=false
		pingLbl.Visible=false
		if sepFps then sepFps.Visible=false end
		if sepPing then sepPing.Visible=false end
	end

	-- Radius label + clickable value box
	local radTag=Instance.new("TextLabel",pbFrame)
	radTag.Size=UDim2.new(0,30,0,14);radTag.Position=UDim2.new(0,226,0,5);radTag.BackgroundTransparency=1
	radTag.Text="RAD";radTag.TextColor3=DIM;radTag.Font=Enum.Font.GothamBlack;radTag.TextSize=9;radTag.TextXAlignment=Enum.TextXAlignment.Left

	-- Radius value as editable textbox
	progressRadLbl=Instance.new("TextBox",pbFrame)
	progressRadLbl.Size=UDim2.new(0,42,0,18);progressRadLbl.Position=UDim2.new(1,-50,0,4);progressRadLbl.BackgroundColor3=CARD;progressRadLbl.BorderSizePixel=0
	progressRadLbl.Text=tostring(CONFIG.STEAL_RANGE);progressRadLbl.TextColor3=Color3.fromRGB(255,255,255);progressRadLbl.Font=Enum.Font.GothamBlack;progressRadLbl.TextSize=11;progressRadLbl.TextXAlignment=Enum.TextXAlignment.Center
	progressRadLbl.ClearTextOnFocus=false;progressRadLbl.ZIndex=3
	Instance.new("UICorner",progressRadLbl).CornerRadius=UDim.new(0,6)
	local radStroke=Instance.new("UIStroke",progressRadLbl);radStroke.Color=ACCENT;radStroke.Thickness=1;radStroke.Transparency=0.35
	local radStrokeGrad=Instance.new("UIGradient",radStroke);radStrokeGrad.Color=ColorSequence.new(ACCENT,ICE);radStrokeGrad.Rotation=0
	progressRadLbl.Focused:Connect(function() TS:Create(radStroke,TweenInfo.new(0.12),{Transparency=0.02}):Play() end)
	progressRadLbl.FocusLost:Connect(function()
		TS:Create(radStroke,TweenInfo.new(0.12),{Transparency=0.35}):Play()
		local v=tonumber(progressRadLbl.Text)
		if v and v>=0.5 and v<=300 then
			CONFIG.STEAL_RANGE=v
			progressRadLbl.Text=tostring(v)
			if radInput then radInput.Text=tostring(v) end
			saveConfig()
		else
			progressRadLbl.Text=tostring(CONFIG.STEAL_RANGE)
		end
	end)

	-- Progress bar at the bottom (more visible)
	local pbg=Instance.new("Frame",pbFrame);pbg.Size=UDim2.new(1,-20,0,6);pbg.Position=UDim2.new(0,10,1,-11);pbg.BackgroundColor3=Color3.fromRGB(20,20,28);pbg.BorderSizePixel=0
	Instance.new("UICorner",pbg).CornerRadius=UDim.new(1,0)
	local pbgStroke=Instance.new("UIStroke",pbg);pbgStroke.Color=Color3.fromRGB(50,50,65);pbgStroke.Thickness=1;pbgStroke.Transparency=0.5

	progressFill=Instance.new("Frame",pbg);progressFill.Size=UDim2.new(0,0,1,0);progressFill.BackgroundColor3=ACCENT;progressFill.BorderSizePixel=0
	Instance.new("UICorner",progressFill).CornerRadius=UDim.new(1,0)
	local fillGrad=Instance.new("UIGradient",progressFill);fillGrad.Color=ColorSequence.new(ACCENT,ICE)

	-- FPS counter
	local fpsAccum=0;local fpsFrames=0;local fpsLast=tick()
	RunService.RenderStepped:Connect(function(dt)
		fpsAccum=fpsAccum+dt;fpsFrames=fpsFrames+1
		if tick()-fpsLast>=0.4 then
			local avg=fpsFrames/fpsAccum
			fpsLbl.Text=string.format("FPS:%d",math.floor(avg+0.5))
			fpsAccum=0;fpsFrames=0;fpsLast=tick()
		end
	end)

	-- Ping counter
	task.spawn(function()
		while pbFrame.Parent do
			local ok,ping=pcall(function()
				local stats=game:GetService("Stats")
				return stats.Network.ServerStatsItem["Data Ping"]:GetValue()
			end)
			if ok and ping then
				pingLbl.Text=string.format("PING:%dms",math.floor(ping+0.5))
			else
				local ok2,p2=pcall(function() return LP:GetNetworkPing()*1000 end)
				if ok2 and p2 then pingLbl.Text=string.format("PING:%dms",math.floor(p2+0.5)) end
			end
			task.wait(0.6)
		end
	end)

	-- Idle scanning animation when Auto Steal is ON but nothing active
	-- Shows visual feedback that the system is alive and scanning
	local idleScanPos=0
	local idleDotTimer=0
	local idleDotCount=0
	RunService.RenderStepped:Connect(function(dt)
		if not progressFill or not progressFill.Parent then return end
		local isIdle=CONFIG.AUTO_STEAL_ENABLED and not StealState.active and (StealState.lastResultTime==0 or (tick()-StealState.lastResultTime)>=1.4)
		if isIdle then
			-- Strong sweeping pulse 0 → 75% → 0 → 75% → ...
			idleScanPos=(idleScanPos+dt*1.1)%1
			local pulse=math.sin(idleScanPos*math.pi*2)*0.5+0.5
			pulse=pulse*0.75  -- max 75% fill so it's clearly visible
			progressFill.Size=UDim2.new(pulse,0,1,0)
			progressFill.BackgroundColor3=progressFill.BackgroundColor3:Lerp(CANDY_COLORS.ACCENT,math.min(dt*8,1))
			-- Animated SCAN dots on status text
			idleDotTimer=idleDotTimer+dt
			if idleDotTimer>=0.35 then
				idleDotTimer=0
				idleDotCount=(idleDotCount+1)%4
				progressPct.Text="SCAN"..string.rep(".",idleDotCount)
				progressPct.TextColor3=CANDY_COLORS.ACCENT
			end
		end
	end)

	-- Drag the progress bar around (saves position) - except radius textbox
	local pbDragging=false
	local pbDragStart,pbStartPos=nil,nil
	pbFrame.InputBegan:Connect(function(input)
		if uiLocked then return end
		if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
		-- Don't start drag when clicking the radius textbox
		if progressRadLbl:IsFocused() then return end
		pbDragging=true;pbDragStart=input.Position;pbStartPos=pbFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState==Enum.UserInputState.End then
				pbDragging=false
				progressBarPosition={xs=pbFrame.Position.X.Scale,x=pbFrame.Position.X.Offset,ys=pbFrame.Position.Y.Scale,y=pbFrame.Position.Y.Offset}
				saveConfig()
			end
		end)
	end)
	UIS.InputChanged:Connect(function(input)
		if not pbDragging or uiLocked or not pbDragStart or not pbStartPos then return end
		if input.UserInputType~=Enum.UserInputType.MouseMovement and input.UserInputType~=Enum.UserInputType.Touch then return end
		local dx,dy=input.Position.X-pbDragStart.X,input.Position.Y-pbDragStart.Y
		pbFrame.Position=UDim2.new(pbStartPos.X.Scale,pbStartPos.X.Offset+dx,pbStartPos.Y.Scale,pbStartPos.Y.Offset+dy)
	end)

	local mainPage=Instance.new("ScrollingFrame",main)
	mainPage.Name="MainPage";mainPage.Size=UDim2.new(1,-(PAD*2),1,-PAGE_BOTTOM);mainPage.Position=UDim2.new(0,PAD,0,PAGE_TOP)
	mainPage.BackgroundTransparency=1;mainPage.BorderSizePixel=0;mainPage.ScrollBarThickness=2;mainPage.ScrollBarImageColor3=ICE
	mainPage.CanvasSize=UDim2.new(0,0,0,0);mainPage.AutomaticCanvasSize=Enum.AutomaticSize.Y
	local pageLayout=Instance.new("UIListLayout",mainPage);pageLayout.SortOrder=Enum.SortOrder.LayoutOrder;pageLayout.Padding=UDim.new(0,IsMobile and 5 or 7)
	local pagePad=Instance.new("UIPadding",mainPage);pagePad.PaddingLeft=UDim.new(0,2);pagePad.PaddingRight=UDim.new(0,2);pagePad.PaddingTop=UDim.new(0,1);pagePad.PaddingBottom=UDim.new(0,IsMobile and 6 or 8)

	local lo=0;local function LO() lo=lo+1;return lo end
	local function mkSect(parent,txt)
		local f=Instance.new("Frame",parent);f.Size=UDim2.new(1,0,0,SECTION_H);f.BackgroundTransparency=1;f.BorderSizePixel=0;f.LayoutOrder=LO()
		local bullet=Instance.new("Frame",f);bullet.Size=UDim2.new(0,5,0,5);bullet.Position=UDim2.new(0,2,0.5,-2);bullet.BackgroundColor3=ACCENT;bullet.BorderSizePixel=0
		Instance.new("UICorner",bullet).CornerRadius=UDim.new(0,2)
		local l=Instance.new("TextLabel",f);l.Size=UDim2.new(1,-18,1,0);l.Position=UDim2.new(0,14,0,0);l.BackgroundTransparency=1;l.Text=txt:upper();l.TextColor3=ACCENT;l.Font=Enum.Font.GothamBlack;l.TextSize=IsMobile and 8 or 9;l.TextXAlignment=Enum.TextXAlignment.Left
	end
	local function mkRow(parent,h,toggleRow)
		local base=toggleRow and Color3.fromRGB(7,15,23) or CARD
		local hover=toggleRow and Color3.fromRGB(10,22,34) or Color3.fromRGB(12,12,16)
		local f=Instance.new("Frame",parent);f.Size=UDim2.new(1,0,0,h or ROW_H);f.BackgroundColor3=base;f.BorderSizePixel=0;f.LayoutOrder=LO()
		Instance.new("UICorner",f).CornerRadius=UDim.new(0,12)
		local st=Instance.new("UIStroke",f);st.Color=toggleRow and ICE or STROKE;st.Thickness=1;st.Transparency=toggleRow and 0.68 or 0.45
		f.MouseEnter:Connect(function() TS:Create(f,TweenInfo.new(0.12),{BackgroundColor3=hover}):Play();TS:Create(st,TweenInfo.new(0.12),{Color=ICE,Transparency=0.12}):Play() end)
		f.MouseLeave:Connect(function() TS:Create(f,TweenInfo.new(0.12),{BackgroundColor3=base}):Play();TS:Create(st,TweenInfo.new(0.12),{Color=toggleRow and ICE or STROKE,Transparency=toggleRow and 0.68 or 0.45}):Play() end)
		return f
	end
	local function mkLabel(row,txt)
		local l=Instance.new("TextLabel",row);l.Size=UDim2.new(0.62,0,1,0);l.Position=UDim2.new(0,10,0,0);l.BackgroundTransparency=1;l.Text=txt;l.TextColor3=W;l.Font=Enum.Font.GothamBold;l.TextSize=10;l.TextXAlignment=Enum.TextXAlignment.Left
		if IsMobile then l.TextSize=9 end
		return l
	end
	local function mkPill(row,offset)
		local pill=Instance.new("Frame",row);pill.Size=UDim2.new(0,40,0,20);pill.Position=UDim2.new(1,-(offset or 48),0.5,-10);pill.BackgroundColor3=OFF;pill.BorderSizePixel=0;pill.ZIndex=3
		Instance.new("UICorner",pill).CornerRadius=UDim.new(1,0)
		-- Subtle stroke on the pill (more polished)
		local pillStroke=Instance.new("UIStroke",pill);pillStroke.Color=Color3.fromRGB(50,50,60);pillStroke.Thickness=1;pillStroke.Transparency=0.4
		-- Gradient overlay that shows when ON (pink-cyan mix)
		local grad=Instance.new("Frame",pill)
		grad.Size=UDim2.new(1,0,1,0);grad.Position=UDim2.new(0,0,0,0);grad.BackgroundColor3=Color3.fromRGB(255,255,255);grad.BackgroundTransparency=1;grad.BorderSizePixel=0;grad.ZIndex=3
		Instance.new("UICorner",grad).CornerRadius=UDim.new(1,0)
		local gradFx=Instance.new("UIGradient",grad);gradFx.Color=ColorSequence.new(ACCENT,ICE);gradFx.Rotation=0
		local dot=Instance.new("Frame",pill);dot.Size=UDim2.new(0,14,0,14);dot.Position=UDim2.new(0,3,0.5,-7);dot.BackgroundColor3=Color3.fromRGB(180,180,200);dot.BorderSizePixel=0;dot.ZIndex=5
		Instance.new("UICorner",dot).CornerRadius=UDim.new(1,0)
		-- Subtle stroke on dot for premium feel
		local dotStroke=Instance.new("UIStroke",dot);dotStroke.Color=Color3.fromRGB(0,0,0);dotStroke.Thickness=0.5;dotStroke.Transparency=0.6
		return pill,dot,grad,pillStroke
	end
	local function animPill(pill,dot,on,grad,pillStroke)
		if grad then TS:Create(grad,TweenInfo.new(0.22,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=on and 0 or 1}):Play() end
		TS:Create(dot,TweenInfo.new(0.28,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{
			Position=on and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
			BackgroundColor3=on and Color3.fromRGB(15,5,25) or Color3.fromRGB(180,180,200),
			Size=on and UDim2.new(0,14,0,14) or UDim2.new(0,14,0,14)
		}):Play()
		if pillStroke then TS:Create(pillStroke,TweenInfo.new(0.18),{Transparency=on and 0.85 or 0.4}):Play() end
	end
	local function mkToggle(parent,txt,cb)
		local row=mkRow(parent,ROW_H,true);mkLabel(row,txt);local pill,dot,grad,pillStroke=mkPill(row,48);local on=false
		local function sv(s) on=s;animPill(pill,dot,s,grad,pillStroke) end
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=6
		clk.Activated:Connect(function()
			on=not on;sv(on);cb(on)
			-- Press scale feedback
			pill.Size=UDim2.new(0,38,0,19)
			TS:Create(pill,TweenInfo.new(0.18,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,40,0,20)}):Play()
		end)
		return sv
	end
	local function mkBox(parent,default,w,xOff,cb)
		local tb=Instance.new("TextBox",parent);tb.Size=UDim2.new(0,w or 58,0,22);tb.Position=UDim2.new(1,-(xOff or 66),0.5,-11);tb.BackgroundColor3=Color3.fromRGB(255,255,255);tb.BorderSizePixel=0;tb.Text=tostring(default);tb.TextColor3=Color3.fromRGB(15,5,25);tb.Font=Enum.Font.GothamBlack;tb.TextSize=12;tb.ClearTextOnFocus=false;tb.ZIndex=5
		Instance.new("UICorner",tb).CornerRadius=UDim.new(1,0)
		local boxGrad=Instance.new("UIGradient",tb);boxGrad.Color=ColorSequence.new(ACCENT,ICE);boxGrad.Rotation=0
		local bs=Instance.new("UIStroke",tb);bs.Color=ACCENT;bs.Thickness=1;bs.Transparency=0.34
		local bsGrad=Instance.new("UIGradient",bs);bsGrad.Color=ColorSequence.new(ACCENT,ICE);bsGrad.Rotation=0
		tb.MouseEnter:Connect(function() TS:Create(bs,TweenInfo.new(0.12),{Transparency=0.02}):Play() end)
		tb.MouseLeave:Connect(function() if not tb:IsFocused() then TS:Create(bs,TweenInfo.new(0.12),{Transparency=0.34}):Play() end end)
		tb.Focused:Connect(function() TS:Create(bs,TweenInfo.new(0.12),{Transparency=0}):Play() end)
		tb.FocusLost:Connect(function() TS:Create(bs,TweenInfo.new(0.12),{Transparency=0.34}):Play();if cb then local n=tonumber(tb.Text);if n then cb(n) else tb.Text=tostring(default) end end end)
		return tb
	end
	local GAMEPAD_KEYS={[Enum.KeyCode.ButtonA]=true,[Enum.KeyCode.ButtonB]=true,[Enum.KeyCode.ButtonX]=true,[Enum.KeyCode.ButtonY]=true,[Enum.KeyCode.ButtonL1]=true,[Enum.KeyCode.ButtonR1]=true,[Enum.KeyCode.ButtonL2]=true,[Enum.KeyCode.ButtonR2]=true,[Enum.KeyCode.ButtonL3]=true,[Enum.KeyCode.ButtonR3]=true,[Enum.KeyCode.ButtonStart]=true,[Enum.KeyCode.ButtonSelect]=true,[Enum.KeyCode.DPadUp]=true,[Enum.KeyCode.DPadDown]=true,[Enum.KeyCode.DPadLeft]=true,[Enum.KeyCode.DPadRight]=true}
	local function isGamepadInput(inp) return inp and inp.UserInputType and inp.UserInputType.Name:match("^Gamepad")~=nil end
	local function isBindableInput(inp) if not inp or inp.KeyCode==Enum.KeyCode.Unknown then return false end;if inp.UserInputType==Enum.UserInputType.Keyboard then return true end;return isGamepadInput(inp) and GAMEPAD_KEYS[inp.KeyCode]==true end
	local function kbMatch(entry,kc) return kc and (kc==entry.kb or (entry.gp and kc==entry.gp)) end
	local function mkKB(parent,kbEntry,cb)
		local btn=Instance.new("TextButton",parent);btn.Size=UDim2.new(0,58,0,22);btn.Position=UDim2.new(1,-66,0.5,-11);btn.BackgroundColor3=Color3.fromRGB(255,255,255);btn.BorderSizePixel=0
		local function getLabel() return (kbEntry.gp and kbEntry.gp.Name) or (kbEntry.kb and kbEntry.kb.Name) or "None" end
		btn.Text=getLabel();btn.TextColor3=Color3.fromRGB(15,5,25);btn.Font=Enum.Font.GothamBlack;btn.TextSize=12;btn.ZIndex=5
		Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
		local kbGrad=Instance.new("UIGradient",btn);kbGrad.Color=ColorSequence.new(ACCENT,ICE);kbGrad.Rotation=0
		local kbStroke=Instance.new("UIStroke",btn);kbStroke.Color=ACCENT;kbStroke.Thickness=1;kbStroke.Transparency=0.34
		local kbsGrad=Instance.new("UIGradient",kbStroke);kbsGrad.Color=ColorSequence.new(ACCENT,ICE);kbsGrad.Rotation=0
		btn.MouseEnter:Connect(function() TS:Create(kbStroke,TweenInfo.new(0.12),{Transparency=0.02}):Play() end)
		btn.MouseLeave:Connect(function() TS:Create(kbStroke,TweenInfo.new(0.12),{Transparency=0.34}):Play() end)
		local li=false;local lc;local pv=btn.Text;local listenStart=0
		btn.Activated:Connect(function()
			if li then li=false;_anyKeyListening=false;if lc then lc:Disconnect();lc=nil end;btn.Text=pv;return end
			pv=btn.Text;li=true;_anyKeyListening=true;listenStart=tick();btn.Text="..."
			lc=UIS.InputBegan:Connect(function(inp)
				if not li then return end
				if inp.KeyCode==Enum.KeyCode.Escape then li=false;_anyKeyListening=false;if lc then lc:Disconnect();lc=nil end;btn.Text=pv;return end
				local isGp=isGamepadInput(inp);if isGp and tick()-listenStart<0.15 then return end;if not isBindableInput(inp) then return end
				btn.Text=inp.KeyCode.Name;pv=inp.KeyCode.Name;li=false;_anyKeyListening=false;if lc then lc:Disconnect();lc=nil end;if cb then cb(inp.KeyCode,isGp) end
			end)
		end)
		return btn
	end
	local function mkToggleKB(parent,txt,kbEntry,onToggle,onKB)
		local row=mkRow(parent,ROW_H);mkLabel(row,txt);if kbEntry then mkKB(row,kbEntry,function(k,isGp) if isGp then kbEntry.gp=k;kbEntry.kb=nil else kbEntry.kb=k;kbEntry.gp=nil end;if onKB then onKB(k,isGp) end end) end
		local pill,dot,grad,pillStroke=mkPill(row,kbEntry and 116 or 48);local on=false;local function sv(s) on=s;animPill(pill,dot,s,grad,pillStroke) end
		local clk=Instance.new("TextButton",pill);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=6
		clk.Activated:Connect(function() if _anyKeyListening then return end;on=not on;sv(on);if onToggle then onToggle(on) end end)
		return sv
	end
	local function applyUiScale()
		if mainUIScale then mainUIScale.Scale=(IsMobile and 0.75 or 1)*uiScaleValue end
	end
	local function applyMobileButtonScale()
		if mobileUIScale then mobileUIScale.Scale=mobileButtonScaleValue end
		refreshMobileButtonUi()
	end
	local SCALE_OPTIONS={1,1.25,1.5,1.75,2}
	local function mkSizeSelector(parent,txt,getValue,setValue,setters)
		local row=mkRow(parent,ROW_H);local label=mkLabel(row,txt);if label then label.Size=UDim2.new(0,IsMobile and 58 or 118,1,0) end
		local buttons={}
		local btnW=IsMobile and 26 or 30
		local step=IsMobile and 30 or 34
		local totalW=(step*4)+btnW
		for i,v in ipairs(SCALE_OPTIONS) do
			local btn=Instance.new("TextButton",row)
			btn.Size=UDim2.new(0,btnW,0,20);btn.Position=UDim2.new(1,-totalW+(i-1)*step,0.5,-10)
			btn.BackgroundColor3=Color3.fromRGB(255,255,255);btn.BorderSizePixel=0;btn.Text=tostring(math.floor(v*100)).."%";btn.TextColor3=Color3.fromRGB(15,5,25);btn.Font=Enum.Font.GothamBlack;btn.TextSize=IsMobile and 8 or 9;btn.AutoButtonColor=false;btn.ZIndex=4
			Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0)
			local btnGrad=Instance.new("UIGradient",btn);btnGrad.Color=ColorSequence.new(ACCENT,ICE);btnGrad.Rotation=0
			local st=Instance.new("UIStroke",btn);st.Color=ACCENT;st.Thickness=1;st.Transparency=0.36
			local stGrad=Instance.new("UIGradient",st);stGrad.Color=ColorSequence.new(ACCENT,ICE);stGrad.Rotation=0
			buttons[#buttons+1]={btn=btn,stroke=st,gradient=btnGrad,value=v}
			btn.Activated:Connect(function()
				if _anyKeyListening then return end
				setValue(v)
				for _,refresh in ipairs(setters) do refresh() end
				saveConfig()
			end)
		end
		local function refresh()
			for _,item in ipairs(buttons) do
				local active=math.abs(getValue()-item.value)<0.01
				item.btn.BackgroundTransparency=active and 0 or 0.78
				item.btn.TextColor3=active and Color3.fromRGB(15,5,25) or Color3.fromRGB(180,180,200)
				item.stroke.Transparency=active and 0.04 or 0.36
			end
		end
		table.insert(setters,refresh)
		refresh()
	end

	mkSect(mainPage,"Speed Values")
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Normal Speed");normalBox=mkBox(row,NS,58,68,function(v) if v>0 and v<=500 then NS=v end;saveConfig() end) end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Carry Speed");carryBox=mkBox(row,CS,58,68,function(v) if v>0 and v<=500 then CS=v end;saveConfig() end) end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Lagger Speed");laggerBox=mkBox(row,LAGGER_SPEED,58,68,function(v) if v>0 and v<=500 then LAGGER_SPEED=v end;saveConfig() end) end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Lagger Carry Speed");laggerCarryBox=mkBox(row,LAGGER_CARRY_SPEED,58,68,function(v) if v>0 and v<=500 then LAGGER_CARRY_SPEED=v end;saveConfig() end) end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Mode");modeValLbl=Instance.new("TextLabel",row);modeValLbl.Size=UDim2.new(0,110,1,0);modeValLbl.Position=UDim2.new(1,-118,0,0);modeValLbl.BackgroundTransparency=1;modeValLbl.Text="Normal";modeValLbl.TextColor3=ACCENT;modeValLbl.Font=Enum.Font.GothamBlack;modeValLbl.TextSize=11;modeValLbl.TextXAlignment=Enum.TextXAlignment.Right;local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2;clk.Activated:Connect(function() if _anyKeyListening then return end;toggleCarryMode();saveConfig() end) end

	mkSect(mainPage,"Speed Keybinds")
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Speed Key");mkKB(row,KB.SpeedToggle,function(k,isGp) if isGp then KB.SpeedToggle.gp=k;KB.SpeedToggle.kb=nil else KB.SpeedToggle.kb=k;KB.SpeedToggle.gp=nil end;saveConfig() end) end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Lagger Key");mkKB(row,KB.LaggerToggle,function(k,isGp) if isGp then KB.LaggerToggle.gp=k;KB.LaggerToggle.kb=nil else KB.LaggerToggle.kb=k;KB.LaggerToggle.gp=nil end;saveConfig() end) end
	mkSect(mainPage,"Bat Aimbot")
	setAutoSwingVisual=mkToggle(mainPage,"Auto Swing",function(on) autoSwingEnabled=on;saveConfig() end);if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end
	setBatCounterVisual=mkToggle(mainPage,"Bat Counter",function(on) batCounterEnabled=on;if on then startBatCounter() else stopBatCounter() end;saveConfig() end)
	setMedusaVisual=mkToggle(mainPage,"Medusa Counter",function(on) medusaCounterEnabled=on;if on then setupMedusa(LP.Character) else stopMedusaCounter() end;saveConfig() end)
	do local abRow=mkRow(mainPage,ROW_H);mkLabel(abRow,"Aimbot Key");mkKB(abRow,KB.AutoBat,function(k,isGp) if isGp then KB.AutoBat.gp=k;KB.AutoBat.kb=nil else KB.AutoBat.kb=k;KB.AutoBat.gp=nil end;saveConfig() end);autoBatSetVisual=function() end end

	-- AIMBOT SPEED: typeable input box to set chase speed of the bat aimbot
	mkSect(mainPage,"Aimbot Speed")
	do
		local row=mkRow(mainPage,ROW_H)
		mkLabel(row,"Set Aimbot Speed")
		local aimbotBox = mkBox(row, aimbotSpeed, 58, 68, function(v)
			if v and v >= 5 and v <= 500 then
				aimbotSpeed = v
				saveConfig()
				if showActionNotification then showActionNotification("AIMBOT: "..tostring(v)) end
			end
		end)
		_G._candyAimbotValBox = aimbotBox
	end

	mkSect(mainPage,"Insta Grab")
	setInstaGrab=mkToggle(mainPage,"Auto Steal",function(on) CONFIG.AUTO_STEAL_ENABLED=on;if on then if not pcall(startAutoSteal) then CONFIG.AUTO_STEAL_ENABLED=false;if setInstaGrab then setInstaGrab(false) end end else stopAutoSteal() end;saveConfig() end)
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Steal Radius");radInput=mkBox(row,CONFIG.STEAL_RANGE,58,68,function(v) if v>=0.5 and v<=300 then CONFIG.STEAL_RANGE=v;if progressRadLbl then progressRadLbl.Text=string.format("%.2g",CONFIG.STEAL_RANGE) end end;saveConfig() end) end

	mkSect(mainPage,"Movement")
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Auto Left");mkKB(row,KB.AutoLeft,function(k,isGp) if isGp then KB.AutoLeft.gp=k;KB.AutoLeft.kb=nil else KB.AutoLeft.kb=k;KB.AutoLeft.gp=nil end;saveConfig() end);autoLeftSetVisual=function() end end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Auto Right");mkKB(row,KB.AutoRight,function(k,isGp) if isGp then KB.AutoRight.gp=k;KB.AutoRight.kb=nil else KB.AutoRight.kb=k;KB.AutoRight.gp=nil end;saveConfig() end);autoRightSetVisual=function() end end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Drop Brainrot");mkKB(row,KB.DropBrainrot,function(k,isGp) if isGp then KB.DropBrainrot.gp=k;KB.DropBrainrot.kb=nil else KB.DropBrainrot.kb=k;KB.DropBrainrot.gp=nil end;saveConfig() end);local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(0.58,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2;clk.Activated:Connect(function() runDrop() end) end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"TP Down");mkKB(row,KB.TPFloor,function(k,isGp) if isGp then KB.TPFloor.gp=k;KB.TPFloor.kb=nil else KB.TPFloor.kb=k;KB.TPFloor.gp=nil end;saveConfig() end);local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(0.58,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2;clk.Activated:Connect(function() runTPFloor() end) end
	setAutoTPVisual=mkToggle(mainPage,"Auto TP Down",function(on) autoTPEnabled=on;if on then startAutoTP() else stopAutoTP() end;saveConfig() end)
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"TP Height");autoTPHeightBox=mkBox(row,autoTPHeight,64,74,function(v) if v>=0 and v<=500 then autoTPHeight=v else autoTPHeightBox.Text=tostring(autoTPHeight) end;saveConfig() end) end
	setInfJumpVisual=mkToggle(mainPage,"Infinite Jump",function(on) infJumpEnabled=on;saveConfig();if showActionNotification then showActionNotification(on and "INF JUMP ON" or "INF JUMP OFF") end end)
	setUnwalkVisual=mkToggle(mainPage,"Unwalk",function(on) unwalkEnabled=on;if on then startUnwalk() else stopUnwalk() end;saveConfig();if showActionNotification then showActionNotification(on and "UNWALK ON" or "UNWALK OFF") end end)
	setAntiRagVisual=mkToggle(mainPage,"Anti Ragdoll",function(on) antiRagdollEnabled=on;if on then startAntiRagdoll() else stopAntiRagdoll() end;saveConfig();if showActionNotification then showActionNotification(on and "ANTI RAG ON" or "ANTI RAG OFF") end end)
	setHitCountdownVisual=mkToggle(mainPage,"Hit Countdown",function(on) hitCountdownEnabled=on;if on then startHitCountdownSystem() else stopHitCountdownSystem() end;saveConfig();if showActionNotification then showActionNotification(on and "HIT TIMER ON" or "HIT TIMER OFF") end end)

	mkSect(mainPage,"Visuals")
	setStretchRezVisual=mkToggle(mainPage,"FPS Boost",function(on) if on then enableStretchRez() else disableStretchRez() end;saveConfig();if showActionNotification then showActionNotification(on and "FPS BOOST ON" or "FPS BOOST OFF") end end)
	setAntiLagVisual=mkToggle(mainPage,"Anti Lag",function(on) if on then enableAntiLag() else disableAntiLag() end;saveConfig();if showActionNotification then showActionNotification(on and "ANTI LAG ON" or "ANTI LAG OFF") end end)
	do
		local row=mkRow(mainPage,ROW_H);mkLabel(row,"Sky Theme")
		local skyIndex=1
		local current=tostring(currentSkyTheme or _G._CandyHubSkyMode or CandySkyOrder[1][2])
		for i,entry in ipairs(CandySkyOrder) do if entry[2]==current then skyIndex=i;break end end
		local skyVal=Instance.new("TextLabel",row);skyVal.Size=UDim2.new(0,150,1,0);skyVal.Position=UDim2.new(1,-158,0,0);skyVal.BackgroundTransparency=1;skyVal.Text=CandySkyOrder[skyIndex][2];skyVal.TextColor3=ACCENT;skyVal.Font=Enum.Font.GothamBlack;skyVal.TextSize=11;skyVal.TextXAlignment=Enum.TextXAlignment.Right
		local clk=Instance.new("TextButton",row);clk.Size=UDim2.new(1,0,1,0);clk.BackgroundTransparency=1;clk.Text="";clk.ZIndex=2
		clk.Activated:Connect(function()
			if _anyKeyListening then return end
			skyIndex=skyIndex%#CandySkyOrder+1
			local label=CandySkyOrder[skyIndex][2]
			skyVal.Text=label
			currentSkyTheme=label
			CandyApplyCustomSky(label)
			saveConfig()
		end)
	end
	mkSect(mainPage,"Settings")
	setLockGuiVisual=mkToggle(mainPage,"Lock GUI",function(on) setGuiLock(on) end)
	setShowIntroVisual=mkToggle(mainPage,"Skip Intro",function(on) showIntroEnabled=not on;saveConfig();if showActionNotification then showActionNotification(on and "INTRO OFF" or "INTRO ON") end end)
	setShowFpsPingVisual=mkToggle(mainPage,"Show FPS/Ping",function(on)
		_G._candyShowFpsPing=on
		if _G._candyFpsLbl then _G._candyFpsLbl.Visible=on end
		if _G._candyPingLbl then _G._candyPingLbl.Visible=on end
		if _G._candySepFps then _G._candySepFps.Visible=on end
		if _G._candySepPing then _G._candySepPing.Visible=on end
		saveConfig()
	end)
	setHideMobileVisual=mkToggle(mainPage,"Hide Mobile Buttons",function(on) hideMobileButtons=on;refreshMobileButtonUi();saveConfig() end)
	setEditMobileVisual=mkToggle(mainPage,"Edit Mobile Buttons",function(on) editMobileButtons=on;refreshMobileButtonUi();saveConfig();if showActionNotification then showActionNotification(on and "EDIT ON - DRAG BUTTONS" or "EDIT OFF") end end)
	mkSizeSelector(mainPage,"Mobile Button Size",function() return mobileButtonScaleValue end,function(v) mobileButtonScaleValue=v;applyMobileButtonScale() end,mobileSizeSetters)
	mkSizeSelector(mainPage,"UI Size",function() return uiScaleValue end,function(v) uiScaleValue=v;applyUiScale() end,uiSizeSetters)
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Reset Mobile Buttons");local btn=Instance.new("TextButton",row);btn.Size=UDim2.new(0,86,0,22);btn.Position=UDim2.new(1,-94,0.5,-11);btn.BackgroundColor3=Color3.fromRGB(255,255,255);btn.BorderSizePixel=0;btn.Text="RESET";btn.TextColor3=Color3.fromRGB(15,5,25);btn.Font=Enum.Font.GothamBlack;btn.TextSize=12;btn.AutoButtonColor=false;btn.ZIndex=3;Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0);local bg=Instance.new("UIGradient",btn);bg.Color=ColorSequence.new(ACCENT,ICE);bg.Rotation=0;local rst=Instance.new("UIStroke",btn);rst.Color=ACCENT;rst.Thickness=1;rst.Transparency=0.34;local rstGrad=Instance.new("UIGradient",rst);rstGrad.Color=ColorSequence.new(ACCENT,ICE);rstGrad.Rotation=0;btn.MouseEnter:Connect(function() TS:Create(rst,TweenInfo.new(0.12),{Transparency=0.02}):Play() end);btn.MouseLeave:Connect(function() TS:Create(rst,TweenInfo.new(0.12),{Transparency=0.34}):Play() end);btn.Activated:Connect(function() if _anyKeyListening then return end;resetMobileButtonLayout();saveConfig() end) end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Hide UI Key");mkKB(row,KB.GuiHide,function(k,isGp) if isGp then KB.GuiHide.gp=k;KB.GuiHide.kb=nil else KB.GuiHide.kb=k;KB.GuiHide.gp=nil end;saveConfig() end) end
	do local row=mkRow(mainPage,ROW_H);mkLabel(row,"Insta Reset");local btn=Instance.new("TextButton",row);btn.Size=UDim2.new(0,86,0,22);btn.Position=UDim2.new(1,-94,0.5,-11);btn.BackgroundColor3=Color3.fromRGB(255,255,255);btn.BorderSizePixel=0;btn.Text="OPEN";btn.TextColor3=Color3.fromRGB(15,5,25);btn.Font=Enum.Font.GothamBlack;btn.TextSize=12;btn.AutoButtonColor=false;btn.ZIndex=3;Instance.new("UICorner",btn).CornerRadius=UDim.new(1,0);local bg=Instance.new("UIGradient",btn);bg.Color=ColorSequence.new(ACCENT,ICE);bg.Rotation=0;local opn=Instance.new("UIStroke",btn);opn.Color=ACCENT;opn.Thickness=1;opn.Transparency=0.34;local opnGrad=Instance.new("UIGradient",opn);opnGrad.Color=ColorSequence.new(ACCENT,ICE);opnGrad.Rotation=0;btn.MouseEnter:Connect(function() TS:Create(opn,TweenInfo.new(0.12),{Transparency=0.02}):Play() end);btn.MouseLeave:Connect(function() TS:Create(opn,TweenInfo.new(0.12),{Transparency=0.34}):Play() end);btn.Activated:Connect(function() if _anyKeyListening then return end;if setInstaResetPanelVisible then setInstaResetPanelVisible(true) end end) end
	if setHideMobileVisual then setHideMobileVisual(hideMobileButtons) end
	if setEditMobileVisual then setEditMobileVisual(editMobileButtons) end
	setGuiLock(uiLocked,true)

	-- ============================================================
	--  CONNECTIONS / KEYBINDS
	-- ============================================================
	UIS.InputBegan:Connect(function(input,gpe)
		if _anyKeyListening then return end
		if input.UserInputType==Enum.UserInputType.Keyboard then if gpe or UIS:GetFocusedTextBox() then return end elseif not isGamepadInput(input) then return end
		if not isBindableInput(input) then return end
		local kc=input.KeyCode
		if kbMatch(KB.LaggerToggle,kc) then toggleLaggerMode();saveConfig()
		elseif kbMatch(KB.SpeedToggle,kc) then toggleCarryMode();saveConfig()
		elseif kbMatch(KB.DropBrainrot,kc) then runDrop()
		elseif kbMatch(KB.TPFloor,kc) then runTPFloor()
		elseif kbMatch(KB.InstaReset,kc) then cursedInstaReset()
		elseif kbMatch(KB.AutoLeft,kc) then autoLeftEnabled=not autoLeftEnabled;if autoLeftEnabled then queueAutoLeftStart() else stopAutoLeft() end;if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
		elseif kbMatch(KB.AutoRight,kc) then autoRightEnabled=not autoRightEnabled;if autoRightEnabled then queueAutoRightStart() else stopAutoRight() end;if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
		elseif kbMatch(KB.AutoBat,kc) then if not autoBatEnabled then startBatAimbot();if autoBatSetVisual then autoBatSetVisual(true) end else stopBatAimbot();if autoBatSetVisual then autoBatSetVisual(false) end end
		elseif kbMatch(KB.GuiHide,kc) then if main.Visible then hideGui() else showGui() end end
	end)
	-- Apply saved main panel position + open state from config
	if _G._candyMainPanelPos then
		local p=_G._candyMainPanelPos
		main.Position=UDim2.new(p.xs or 0.5,p.x or -180,p.ys or 0.5,p.y or -150)
	end
	if _G._candyMainOpen==false then
		-- Panel was closed last session; intro will still play, but after intro show miniBtn instead
		task.delay(showIntroEnabled and 4 or 0.1,function()
			if _G._candyMainOpen==false then
				main.Visible=false
				miniBtn.Visible=true
			end
		end)
	end
	playCandyIntro(gui,main,miniBtn)
end

-- ============================================================
--  MOBILE BUTTONS
-- ============================================================
local function buildMobileButtons()
	local screen=Instance.new("ScreenGui")
	screen.Name=MOBILE_UI_NAME
	screen.ResetOnSpawn=false
	screen.DisplayOrder=8
	screen.IgnoreGuiInset=true
	pcall(function() if syn and syn.protect_gui then syn.protect_gui(screen) end end)
	if not pcall(function() screen.Parent=CoreGui end) then screen.Parent=LP:WaitForChild("PlayerGui") end
	mobileButtonsScreen=screen

	local container=Instance.new("Frame",screen)
	container.Name="ButtonContainer"
	container.Size=UDim2.new(0,144,0,200)
	container.BackgroundTransparency=1
	container.AnchorPoint=Vector2.new(1,0)
	if mobileGroupPosition then
		container.Position=UDim2.new(mobileGroupPosition.xs or 1,mobileGroupPosition.x or -20,mobileGroupPosition.ys or 0.12,mobileGroupPosition.y or 0)
	else
		container.Position=UDim2.new(1,-20,0.12,0)
	end
	mobileButtonContainerRef=container
	mobileUIScale=Instance.new("UIScale",container)
	mobileUIScale.Scale=mobileButtonScaleValue

	-- EDIT MODE banner (appears above the mobile buttons when edit mode is on)
	local editBanner=Instance.new("Frame",container)
	editBanner.Name="EditBanner"
	editBanner.Size=UDim2.new(1,0,0,26)
	editBanner.Position=UDim2.new(0,0,0,-32)
	editBanner.BackgroundColor3=Color3.fromRGB(255,255,255)  -- WHITE base so gradient shows vibrantly
	editBanner.BackgroundTransparency=0
	editBanner.BorderSizePixel=0
	editBanner.Visible=false
	editBanner.ZIndex=10
	Instance.new("UICorner",editBanner).CornerRadius=UDim.new(1,0)
	local ebGrad=Instance.new("UIGradient",editBanner)
	ebGrad.Color=ColorSequence.new(CANDY_COLORS.ACCENT,CANDY_COLORS.ICE)
	ebGrad.Rotation=0
	local ebStroke=Instance.new("UIStroke",editBanner)
	ebStroke.Color=Color3.fromRGB(255,255,255);ebStroke.Thickness=1;ebStroke.Transparency=0.4
	local ebLbl=Instance.new("TextLabel",editBanner)
	ebLbl.Size=UDim2.new(1,0,1,0);ebLbl.BackgroundTransparency=1
	ebLbl.Text="EDIT MODE";ebLbl.TextColor3=Color3.fromRGB(15,5,25);ebLbl.Font=Enum.Font.GothamBlack;ebLbl.TextSize=12
	ebLbl.ZIndex=11
	-- Animate the gradient (smooth rotation)
	task.spawn(function()
		while editBanner.Parent do
			task.wait(0.05)
			ebGrad.Rotation = (ebGrad.Rotation + 2) % 360
		end
	end)
	mobileEditBanner = editBanner

	-- Track recent press times for each button (used to "light up" on tap)
	local pressTimes = {}

	local function makeBtn(id,label,col,row,defaultLabel)
		local f=Instance.new("Frame",container)
		f.Name=id
		f.Size=UDim2.new(0,64,0,42)
		local defPos=UDim2.new(0,(col-1)*72,0,(row-1)*50)
		local saved=mobileButtonPositions[id]
		if saved then
			f.Position=UDim2.new(saved.xs or 0,saved.x or defPos.X.Offset,saved.ys or 0,saved.y or defPos.Y.Offset)
		else
			f.Position=defPos
		end
		f.BackgroundColor3=CANDY_COLORS.CARD
		f.BorderSizePixel=0
		Instance.new("UICorner",f).CornerRadius=UDim.new(0,9)

		-- Gradient layer: white frame on top, with pink-blue gradient. Hidden by default, shown when button is active.
		local gradLayer=Instance.new("Frame",f)
		gradLayer.Name="GradLayer"
		gradLayer.Size=UDim2.new(1,0,1,0)
		gradLayer.Position=UDim2.new(0,0,0,0)
		gradLayer.BackgroundColor3=Color3.fromRGB(255,255,255)
		gradLayer.BackgroundTransparency=1
		gradLayer.BorderSizePixel=0
		gradLayer.ZIndex=1
		Instance.new("UICorner",gradLayer).CornerRadius=UDim.new(0,9)
		local bgGrad=Instance.new("UIGradient",gradLayer)
		bgGrad.Color=ColorSequence.new(CANDY_COLORS.ACCENT,CANDY_COLORS.ICE)
		bgGrad.Rotation=0

		-- Stroke with its own animated gradient
		local st=Instance.new("UIStroke",f);st.Color=CANDY_COLORS.STROKE;st.Thickness=1;st.Transparency=0.34
		local strokeGrad=Instance.new("UIGradient",st)
		strokeGrad.Color=ColorSequence.new(CANDY_COLORS.ACCENT,CANDY_COLORS.ICE)
		strokeGrad.Rotation=0

		-- Flash layer for press feedback
		local flashLayer=Instance.new("Frame",f)
		flashLayer.Name="FlashLayer"
		flashLayer.Size=UDim2.new(1,0,1,0)
		flashLayer.Position=UDim2.new(0,0,0,0)
		flashLayer.BackgroundColor3=Color3.fromRGB(255,255,255)
		flashLayer.BackgroundTransparency=1
		flashLayer.BorderSizePixel=0
		flashLayer.ZIndex=2
		Instance.new("UICorner",flashLayer).CornerRadius=UDim.new(0,9)

		local lbl=Instance.new("TextLabel",f)
		lbl.Size=UDim2.new(1,-4,1,-4);lbl.Position=UDim2.new(0,2,0,2)
		lbl.BackgroundTransparency=1
		lbl.Text=defaultLabel or label
		lbl.TextColor3=CANDY_COLORS.TEXT
		lbl.Font=Enum.Font.GothamBlack
		lbl.TextSize=9
		lbl.TextWrapped=true
		lbl.TextXAlignment=Enum.TextXAlignment.Center
		lbl.TextYAlignment=Enum.TextYAlignment.Center
		lbl.ZIndex=3

		local btn=Instance.new("TextButton",f)
		btn.Size=UDim2.new(1,0,1,0)
		btn.BackgroundTransparency=1
		btn.Text=""
		btn.AutoButtonColor=false
		btn.ZIndex=4

		mobileButtonFrames[id]={frame=f,defaultPosition=defPos,stroke=st,label=lbl,button=btn,gradLayer=gradLayer,bgGrad=bgGrad,strokeGrad=strokeGrad,flashLayer=flashLayer}

		-- Touch handling (fixed: uses InputEnded for instant taps)
		local dragging=false
		local startInput,startPosition=nil,nil
		local groupStartPos=nil
		local moved=false
		local activeInput=nil
		local pressStartTime=0
		local TAP_THRESHOLD=12   -- pixels of movement before it counts as drag
		local QUICK_TAP_TIME=0.18 -- if released within this time, always count as tap

		btn.InputBegan:Connect(function(input)
			if input.UserInputType~=Enum.UserInputType.Touch and input.UserInputType~=Enum.UserInputType.MouseButton1 then return end
			activeInput=input
			startInput=input.Position
			startPosition=f.Position
			moved=false
			pressStartTime=tick()
			-- Drag only available in edit mode + not locked
			dragging = editMobileButtons and (not uiLocked)
			pressTimes[id] = tick()
			gradLayer.BackgroundTransparency = 0
			TS:Create(f,TweenInfo.new(0.08,Enum.EasingStyle.Quad),{Size=UDim2.new(0,58,0,38)}):Play()
			flashLayer.BackgroundTransparency=0.55
			TS:Create(flashLayer,TweenInfo.new(0.32,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),{BackgroundTransparency=1}):Play()
		end)

		btn.InputEnded:Connect(function(input)
			if input~=activeInput then return end
			activeInput=nil
			TS:Create(f,TweenInfo.new(0.22,Enum.EasingStyle.Back,Enum.EasingDirection.Out),{Size=UDim2.new(0,64,0,42)}):Play()
			local wasDragging=dragging
			dragging=false
			local pressDuration = tick() - pressStartTime
			local isQuickTap = pressDuration < QUICK_TAP_TIME
			-- Tap = no movement OR quick press (and not in edit mode)
			if not editMobileButtons and ((not moved) or isQuickTap) then
				if MobileButtonActions[id] then
					task.spawn(MobileButtonActions[id])
				end
			elseif moved and editMobileButtons then
				-- Save THIS button's new position (only individual save, no group drag)
				mobileButtonPositions[id]={xs=f.Position.X.Scale,x=f.Position.X.Offset,ys=f.Position.Y.Scale,y=f.Position.Y.Offset}
				saveConfig()
			elseif not editMobileButtons and not moved then
				-- Quick tap fallback (when in non-edit mode but didn't qualify as quick tap)
				if MobileButtonActions[id] then
					task.spawn(MobileButtonActions[id])
				end
			end
		end)

		UIS.InputChanged:Connect(function(input)
			if not activeInput or not startInput or not startPosition then return end
			if activeInput.UserInputType == Enum.UserInputType.Touch then
				if input ~= activeInput then return end
			elseif activeInput.UserInputType == Enum.UserInputType.MouseButton1 then
				if input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
			else
				return
			end
			local dx,dy=input.Position.X-startInput.X,input.Position.Y-startInput.Y
			if math.abs(dx)>TAP_THRESHOLD or math.abs(dy)>TAP_THRESHOLD then moved=true end
			-- Move THIS BUTTON ONLY (no group drag). Drag only works in edit mode.
			if dragging and moved and editMobileButtons then
				f.Position=UDim2.new(startPosition.X.Scale,startPosition.X.Offset+dx,startPosition.Y.Scale,startPosition.Y.Offset+dy)
			end
		end)
		return f,lbl
	end

	-- 2x4 grid: col=1..2, row=1..4
	makeBtn("AutoLeft","AUTO LEFT",1,1)
	makeBtn("AutoRight","AUTO RIGHT",2,1)
	makeBtn("AutoBat","AIMBOT",1,2)
	makeBtn("CarrySpeed","CARRY",2,2)
	makeBtn("DropBrainrot","DROP BR",1,3)
	makeBtn("TPDown","TP DOWN",2,3)
	makeBtn("LaggerCarry","LAGGER CARRY",1,4)
	makeBtn("LaggerSpeed","LAGGER",2,4)

	-- Wire mobile button actions to features
	MobileButtonActions.AutoLeft=function()
		autoLeftEnabled=not autoLeftEnabled
		if autoLeftEnabled then queueAutoLeftStart() else stopAutoLeft() end
		if autoLeftSetVisual then autoLeftSetVisual(autoLeftEnabled) end
	end
	MobileButtonActions.AutoRight=function()
		autoRightEnabled=not autoRightEnabled
		if autoRightEnabled then queueAutoRightStart() else stopAutoRight() end
		if autoRightSetVisual then autoRightSetVisual(autoRightEnabled) end
	end
	MobileButtonActions.AutoBat=function()
		if not autoBatEnabled then
			startBatAimbot()
			if autoBatSetVisual then autoBatSetVisual(true) end
		else
			stopBatAimbot()
			if autoBatSetVisual then autoBatSetVisual(false) end
		end
	end
	MobileButtonActions.CarrySpeed=function() toggleCarryMode();saveConfig() end
	MobileButtonActions.DropBrainrot=function() runDrop() end
	MobileButtonActions.TPDown=function() runTPFloor() end
	MobileButtonActions.LaggerCarry=function()
		-- If both lagger AND carry are ON, turn both OFF (proper toggle)
		if laggerToggled and speedMode then
			toggleLaggerMode()
			toggleCarryMode()
		else
			if not laggerToggled then toggleLaggerMode() end
			if not speedMode then toggleCarryMode() end
		end
		saveConfig()
	end
	MobileButtonActions.LaggerSpeed=function() toggleLaggerMode();saveConfig() end

	-- Sync active state visual + animate gradient rotation + handle press light-up
	local gradAngle=0
	RunService.Heartbeat:Connect(function(dt)
		dt = dt or 0.016
		gradAngle=(gradAngle+dt*45)%360  -- 45 deg/sec continuous rotation
		local function setActive(id,active)
			local data=mobileButtonFrames[id]
			if not data then return end
			-- Check if pressed recently (within 0.4s)
			local pt = pressTimes[id]
			local pressedRecently = pt and (tick() - pt) < 0.4
			local lit = active or pressedRecently
			if lit then
				-- Snap to fully lit
				data.gradLayer.BackgroundTransparency = 0
				data.bgGrad.Rotation = gradAngle
				data.strokeGrad.Rotation = gradAngle
			else
				-- Smooth fade out (~0.33s back to dark)
				local t = data.gradLayer.BackgroundTransparency
				if t < 1 then
					data.gradLayer.BackgroundTransparency = math.min(1, t + dt * 3)
				end
			end
			-- Text & stroke follow the gradient intensity for smooth transitions
			local intensity = 1 - data.gradLayer.BackgroundTransparency
			data.label.TextColor3 = CANDY_COLORS.TEXT:Lerp(Color3.fromRGB(15,5,25), intensity)
			data.stroke.Transparency = 0.34 - intensity * 0.30
		end
		setActive("AutoLeft",autoLeftEnabled)
		setActive("AutoRight",autoRightEnabled)
		setActive("AutoBat",autoBatEnabled)
		setActive("CarrySpeed",speedMode and not laggerToggled)
		setActive("LaggerCarry",laggerToggled and speedMode)
		setActive("LaggerSpeed",laggerToggled and not speedMode)
		-- Action buttons: only press flash (no persistent active state)
		setActive("DropBrainrot",false)
		setActive("TPDown",false)
	end)

	-- Drag group container when in edit mode (via long-press anywhere not on a button - simplified: just save on layout change)
	refreshMobileButtonUi()
end

-- ============================================================
--  CONFIG LOADERS
-- ============================================================
local function decodeKey(name)
	if not name then return nil end
	local ok,kc=pcall(function() return Enum.KeyCode[name] end)
	if ok and kc then return kc end
	return nil
end

local function loadConfigKeys()
	if not (readfile and isfile) then return end
	local raw=nil
	pcall(function() if isfile("CandyHub.json") then raw=readfile("CandyHub.json") end end)
	if not raw then pcall(function() if isfile("cursedPC.json") then raw=readfile("cursedPC.json") end end) end
	if not raw then return end
	local ok,cfg=pcall(function() return HS:JSONDecode(raw) end)
	if not ok or type(cfg)~="table" then return end
	if cfg.normalSpeed then NS=cfg.normalSpeed end
	if cfg.carrySpeed then CS=cfg.carrySpeed end
	if cfg.laggerSpeed then LAGGER_SPEED=cfg.laggerSpeed end
	if cfg.laggerCarrySpeed then LAGGER_CARRY_SPEED=cfg.laggerCarrySpeed end
	if cfg.aimbotSpeed then aimbotSpeed=cfg.aimbotSpeed end
	if cfg.autoStealRange then CONFIG.STEAL_RANGE=cfg.autoStealRange end
	if cfg.holdMax then CONFIG.HOLD_MAX=cfg.holdMax end
	if cfg.autoTPHeight then autoTPHeight=cfg.autoTPHeight end
	if cfg.uiScale then uiScaleValue=cfg.uiScale end
	if cfg.mobileButtonScale then mobileButtonScaleValue=cfg.mobileButtonScale end
	if cfg.uiLocked~=nil then uiLocked=cfg.uiLocked end
	if cfg.editMobileButtons~=nil then editMobileButtons=cfg.editMobileButtons end
	if cfg.hideMobileButtons~=nil then hideMobileButtons=cfg.hideMobileButtons end
	if cfg.showIntro~=nil then showIntroEnabled=cfg.showIntro;if setShowIntroVisual then setShowIntroVisual(not showIntroEnabled) end end
	if type(cfg.mobileButtonPositions)=="table" then mobileButtonPositions=cfg.mobileButtonPositions end
	if type(cfg.mobileGroupPosition)=="table" then mobileGroupPosition=cfg.mobileGroupPosition end
	if cfg.instaResetPanelOpen~=nil then instaResetPanelOpen=cfg.instaResetPanelOpen end
	if type(cfg.instaResetPanelPosition)=="table" then instaResetPanelPosition=cfg.instaResetPanelPosition end
	if type(cfg.progressBarPosition)=="table" then progressBarPosition=cfg.progressBarPosition end
	if cfg.mainPanelOpen~=nil then _G._candyMainOpen=cfg.mainPanelOpen end
	if type(cfg.mainPanelPos)=="table" then _G._candyMainPanelPos=cfg.mainPanelPos end
	if cfg.showFpsPing~=nil then
		_G._candyShowFpsPing=cfg.showFpsPing
		if setShowFpsPingVisual then setShowFpsPingVisual(cfg.showFpsPing) end
		-- Apply directly in case labels already created
		if _G._candyFpsLbl then _G._candyFpsLbl.Visible=cfg.showFpsPing end
		if _G._candyPingLbl then _G._candyPingLbl.Visible=cfg.showFpsPing end
		if _G._candySepFps then _G._candySepFps.Visible=cfg.showFpsPing end
		if _G._candySepPing then _G._candySepPing.Visible=cfg.showFpsPing end
	end
	if cfg.skyTheme then currentSkyTheme=cfg.skyTheme end
	local function applyKey(target,saved)
		if not saved or not target then return end
		local kb=decodeKey(saved.kb);local gp=decodeKey(saved.gp)
		target.kb=kb;target.gp=gp
	end
	applyKey(KB.DropBrainrot,cfg.dropBrainrotKey)
	applyKey(KB.AutoLeft,cfg.autoLeftKey)
	applyKey(KB.AutoRight,cfg.autoRightKey)
	applyKey(KB.SpeedToggle,cfg.speedToggleKey)
	applyKey(KB.AutoBat,cfg.autoBatKey)
	applyKey(KB.AntiBatLock,cfg.antiBatLockKey)
	applyKey(KB.LaggerToggle,cfg.laggerToggleKey)
	applyKey(KB.TPFloor,cfg.tpFloorKey)
	applyKey(KB.InstaReset,cfg.instaResetKey)
	applyKey(KB.GuiHide,cfg.guiHideKey)
	-- store the rest for state loader
	_G._CandyHubLoadedState=cfg
end

local function loadConfigState()
	local cfg=_G._CandyHubLoadedState
	if type(cfg)~="table" then return end
	if cfg.antiRagdoll then antiRagdollEnabled=true;startAntiRagdoll();if setAntiRagVisual then setAntiRagVisual(true) end end
	if cfg.hitCountdown then hitCountdownEnabled=true;if startHitCountdownSystem then startHitCountdownSystem() end;if setHitCountdownVisual then setHitCountdownVisual(true) end end
	if cfg.antiDie then antiDieEnabled=true;startAntiDie();if setAntiDieVisual then setAntiDieVisual(true) end end
	if cfg.autoStealEnabled then CONFIG.AUTO_STEAL_ENABLED=true;pcall(startAutoSteal);if setInstaGrab then setInstaGrab(true) end end
	if cfg.infiniteJump then infJumpEnabled=true;if setInfJumpVisual then setInfJumpVisual(true) end end
	if cfg.medusaCounter then medusaCounterEnabled=true;setupMedusa(LP.Character);if setMedusaVisual then setMedusaVisual(true) end end
	if cfg.batCounter then batCounterEnabled=true;startBatCounter();if setBatCounterVisual then setBatCounterVisual(true) end end
	if cfg.carryMode then setCarryModeState(true) end
	if cfg.laggerMode then setLaggerModeState(true) end
	if cfg.autoTPEnabled then autoTPEnabled=true;startAutoTP();if setAutoTPVisual then setAutoTPVisual(true) end end
	if cfg.autoBat then startBatAimbot();if autoBatSetVisual then autoBatSetVisual(true) end end
	if cfg.autoSwing~=nil then autoSwingEnabled=cfg.autoSwing;if setAutoSwingVisual then setAutoSwingVisual(autoSwingEnabled) end end
	if cfg.unwalkEnabled then unwalkEnabled=true;startUnwalk();if setUnwalkVisual then setUnwalkVisual(true) end end
	if cfg.antiLag then enableAntiLag();if setAntiLagVisual then setAntiLagVisual(true) end end
	if cfg.stretchRez then enableStretchRez();if setStretchRezVisual then setStretchRezVisual(true) end end
	if currentSkyTheme and currentSkyTheme~="Off" then CandyApplyCustomSky(currentSkyTheme) end
	if normalBox then normalBox.Text=tostring(NS) end
	if carryBox then carryBox.Text=tostring(CS) end
	if laggerBox then laggerBox.Text=tostring(LAGGER_SPEED) end
	if laggerCarryBox then laggerCarryBox.Text=tostring(LAGGER_CARRY_SPEED) end
	if _G._candyAimbotValBox then _G._candyAimbotValBox.Text=tostring(aimbotSpeed) end
	if radInput then radInput.Text=tostring(CONFIG.STEAL_RANGE) end
	if autoTPHeightBox then autoTPHeightBox.Text=tostring(autoTPHeight) end
	if instaResetPanelOpen and setInstaResetPanelVisible then setInstaResetPanelVisible(true,true) end
	_G._CandyHubLoadedState=nil
end

-- ============================================================
--  INIT
-- ============================================================
loadConfigKeys()
buildMobileButtons()
buildGui()
loadConfigState()
