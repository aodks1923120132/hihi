-- =============================================================================
-- Sqays Hub - Full Automation Suite
-- Features: Mining, Combat, Trials, Realm3 Upgrades, Enchants, Ritual, Boss
-- =============================================================================
local env = _G

-- =============================================================================
-- TASK LIBRARY POLYFILL (for executors without task: Delta, etc.)
-- =============================================================================
if not task then
    local hb = game:GetService("RunService").Heartbeat
    task = {
        spawn = function(f) local co = coroutine.create(f); coroutine.resume(co) end,
        wait = function(t)
            if not t or t <= 0 then hb:Wait(); return end
            local deadline = os.clock() + t
            repeat hb:Wait() until os.clock() >= deadline
        end,
        delay = function(t, f)
            local co = coroutine.create(function()
                if t and t > 0 then
                    local deadline = os.clock() + t
                    repeat hb:Wait() until os.clock() >= deadline
                end
                f()
            end)
            coroutine.resume(co)
        end,
        cancel = function() end
    }
end

-- =============================================================================
-- CLEANUP: Kill all previous loops and UI on re-execute
-- =============================================================================
env.NIStop = true  -- Signal old threads to stop
if env.SqaysRayfield then
    pcall(function() env.SqaysRayfield:Destroy() end)
    env.SqaysRayfield = nil
end
env.NILoaded = false
task.wait(0.1)  -- Give old threads time to die
env.NIStop = false

-- =============================================================================
-- EXECUTOR DETECTION
-- =============================================================================
local execName = "Unknown"
if identifyexecutor then execName = identifyexecutor() end
if execName == "Unknown" then
    if syn then execName = "Synapse Z"
    elseif KRNL then execName = "KRNL"
    elseif Fluxus then execName = "Fluxus"
    elseif Wave then execName = "Wave"
    elseif Solara then execName = "Solara"
    elseif Seliware then execName = "Seliware"
    elseif Xeno then execName = "Xeno"
    elseif Volt then execName = "Volt"
    elseif Potassium then execName = "Potassium"
    elseif Madium then execName = "Madium"
    elseif Cosmic then execName = "Cosmic"
    elseif Velocity then execName = "Velocity"
    elseif SirHurt then execName = "SirHurt"
    elseif Serotonin then execName = "Serotonin"
    elseif Severe then execName = "Severe"
    elseif RbxCli then execName = "RbxCli"
    elseif Lumen then execName = "Lumen"
    elseif Ronin then execName = "Ronin"
    elseif Matcha then execName = "Matcha"
    elseif MatrixHub then execName = "Matrix Hub"
    elseif Photon then execName = "Photon"
    elseif DX9WARE then execName = "DX9WARE V2"
    elseif getgenv and getgenv().SeliwareLoaded then execName = "Seliware"
    elseif getgenv and getgenv().NihonLoaded then execName = "Nihon"
    elseif MacSploit then execName = "MacSploit"
    elseif Opiumware then execName = "Opiumware"
    elseif Delta then execName = "Delta"
    elseif Codex then execName = "Codex"
    elseif VegaX then execName = "Vega X"
    elseif Electron then execName = "Electron"
    elseif SW then execName = "ScriptWare"
    elseif AWP then execName = "AWP"
    elseif Cryptic then execName = "Cryptic"
    elseif Evon then execName = "Evon"
    elseif Argon then execName = "Argon"
    end
end
local gameName = "Unknown"
pcall(function() gameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name end)
warn("[Sqays Hub] Executor: " .. execName)
warn("[Sqays Hub] Game: " .. gameName)

-- =============================================================================
-- ANTI-CHEAT BYPASS
-- =============================================================================
pcall(function()
    local net = ReplicatedStorage:FindFirstChild("__Net")
    if net then
        for _, remoteName in ipairs({"AutoKick", "FlagPlayer", "ReportExploit", "AntiCheat"}) do
            local r = net:FindFirstChild(remoteName)
            if r and r:IsA("RemoteEvent") then r.OnClientEvent:Connect(function() end) end
        end
    end
end)
pcall(function()
    if getconnections then for _, c in ipairs(getconnections(game:GetService("ScriptContext").Error)) do c:Disable() end end
end)
-- Anti-cheat handling is done passively above (remote swallowing + ScriptContext.Error disable).
-- NOTE: We do NOT hook __namecall / kick functions. A __namecall hook intercepts EVERY
-- method call in the game and caused massive lag + extra errors. Removed for performance.

-- =============================================================================
-- SERVICES & CONSTANTS
-- =============================================================================
local P = game:GetService("Players")
local WS = game:GetService("Workspace")
local RS = game:GetService("RunService")
local TS = game:GetService("TweenService")
local VU = game:GetService("VirtualUser")
local LP = P.LocalPlayer
local ORES = {"Stone","Coal","Copper","Iron","Silver","Gold","Platinum","Titanium","Uranium","Cobalt","Palladium","Ruby","Aetherite","Celestium","Voidsteel","Infinity"}
local MOBS = {"Goblin","Skeleton","Orc","Pirate","Ninja","Warrior","Pirate Captain","Samurai","Pirate Admiral","Samurai Master","Dark Knight","Dark Commander","Ancient Boss"}
local Noobs = {"Starter", "Cooker", "Farmer", "Archer", "Soldier", "Fisherman", "Knight", "Explorer", "Magician", "Merchant", "Mummy", "Pharaoh", "Alien", "Demon", "Astronaut"}
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- =============================================================================
-- GLOBAL STATE
-- =============================================================================
local S = {
    -- Mining
    running = false,
    tweenSpeed = 0.6,

    -- Combat
    combatRunning = false,
    combatTweenSpeed = 0.3,

    -- Ancient Boss
    abossRunning = false,
    abossStatus = "Idle",

    -- Ritual
    ritualRunning = false,
    ritualStatus = "Not Running",
    ritualCooldown = 62,
    ritualActive = false,

    -- Realm 3: Noob Upgrades
    autoNoobPharaoh = false,
    autoNoobMummy = false,
    autoNoobMerchant = false,
    autoNoobAlien = false,
    autoNoobDemon = false,
    autoNoobAstronaut = false,
    noobTweenMinutes = 5,
    _lastNoobTween = 0,
    _noobTweening = false,

    -- Realm 3: Sand Upgrades
    autoStrongerShovels = false,
    autoMoreSand = false,
    autoAlotSand = false,
    autoEvenMoreSand = false,
    autoMultiSand = false,
    autoSandMoreOof = false,
    autoFasterShovels = false,
    autoLevelUpShovel = false,
    shovelLevelUpInterval = 5,
    autoBackToSurface = false,
    backToSurfaceLayer = 50,

    -- Realm 3: Souls Upgrades
    autoMoreSouls = false,
    autoMoreBones = false,
    autoMoreOof = false,
    autoLuckierSwords = false,
    autoSoulsRuneBulk = false,

    -- Realm 3: Meat & Bones Special Upgrades
    autoMeatToBones = false,
    autoBonesToHacker = false,
    autoBonesFasterMeatConversion = false,
    autoBonesMoreOof = false,
    autoBonesMoreBones_ = false,
    autoBonesBiggerMeatDeposit = false,
    autoBonesEvenMoreBones = false,
    autoBonesFasterSwords = false,
    autoStrongerSwords = false,
    autoMoreMeat = false,
    autoMeatMoreOof = false,

    -- Hacker Upgrades
    autoHackPoints = false,
    autoRuneLuck = false,
    autoMoreRuneSpeed = false,
    autoMoreRuneLuck = false,
    autoMoreHackPoints = false,
    autoConnorBalancedItt = false,
    autoAutoHackPointsCollector = false,
    autoMoreRuneBulk = false,

    -- Realm 3: Auto Deposit Meat
    autoDepositMeat = false,
    depositMeatHours = 1,
    depositMeatPercent = 0,

    -- Realm 3: Trial Chests
    autoTrialChests = false,

    -- Trials
    trialActive = false,
    selectedTrialDiff = "Hard",
    trialMonitor_Hard = false,
    trialMonitor_Medium = false,
    trialMonitor_Easy = false,

    -- Enchant
    enchantInterval = 0.01,
    autoRoll = {},
    skipAlmighty = {},

    -- Capsule
    autoOpenCapsule = false,
    capsuleInterval = 3,
    selectedCapsule = "Ancient",

    -- Auto Rune
    autoRune = false,
    selectedRune = "Basic",

    -- Movement
    nearestSpeed = 0.3,

    -- Performance
    fpsCap = 60,

    -- Animation Hider
    hideCapsuleAnim = false,
    hideChestAnim = false,
    hideAnimations = false,
    protectGUIs = false,
    animMonitorRunning = false,
    animationConnection = nil,
    lastUpdate = 0,
    updateInterval = 0.1,

    -- Realm 4: Stars Collection
    starCollection = {
        enabled = false,
        tweenSpeed = 25,
        delay = 0.5,
        collected = 0,
        lastCollected = 0,
        rate = 0,
    },
    -- Realm 4: Stars Upgrades
    autoStarEvenMoreStars = false,
    autoStarMoreStars = false,
    autoStarFasterRespawn = false,
    autoStarOof = false,
    autoStarBoostMutationLuck = false,
    autoStarMoreSpacePoints = false,
    -- Realm 4: SpacePoints Upgrades
    autoSpMultiStar = false,
    autoSpMoreSpacePoints = false,
    autoSpMoreMoon = false,
    autoSpBlackholes = false,
    autoSpBoostCollectRadius = false,
    -- Planets Upgrades
    autoPlanetsMorePlanets = false,
    autoPlanetsMoreStars = false,
    autoPlanetsHeatThePlanet = false,
    autoPlanetsMorePoints = false,
    autoPlanetsOofs = false,
    autoPlanetsBlackholes = false,
    -- Knowledge Upgrades
    autoKnowledgeMoreKnowledge = false,
    autoKnowledgeMoreAlienCash = false,
    autoKnowledgeBoostSpaceXP = false,
    -- Research
    autoResearch = false,
    _researchLoopRunning = false,
    _researchLoopThread = nil,
    _researchStatusText = nil,
    -- UFO
    autoUpgradeUFO = false,
    _ufoLoopRunning = false,
    _ufoLoopThread = nil,
    -- Individual Planets
    autoUpgradePlanets = false,  -- Master toggle for planet upgrade dropdown
    -- Moon Upgrades
    autoMoonMoreMoon = false,
    autoMoonBoostStars = false,
    autoMoonMoreSpaceXP = false,
    autoMoonMorePlanets = false,
    autoMoonEvenMoreStars = false,
    -- Blackhole Upgrades
    autoBholeMoreBlackholes = false,
    autoBholePlanet = false,
    autoBholeFasterRespawn = false,
    autoBholeAliencash = false,
    autoBholeOofs = false,
    -- AlienCash Upgrades
    autoAlienMoreCash = false,
    autoAlienMoreXP = false,
    autoAlienBoostMutation = false,
    autoAlienVeryBadHoles = false,

    -- Realm 4: Board Tweening (visit boards when upgrades are affordable)
    realm4BoardMultiplier = 5,  -- Only visit when balance ≥ cost * multiplier
    _realm4BoardLastCycle = 0,  -- Cooldown timestamp between cycles
    _realm4BoardPositions = {},  -- {Stars=Vector3, SpacePoints=Vector3, ...} cached positions
    _realm4BoardRunning = false,
}

-- =============================================================================
-- TRIAL DATA
-- =============================================================================
local Trials = {
    Hard = {
        coord = Vector3.new(770.3533325195312, 10.54693603515625, 13762.26171875),
        portal = Vector3.new(907.804443359375, 9.118680953979492, 13443.4150390625),
        room = "HardTrialRoom",
        path = {"__GAME_CONTENT","Trials","HardTrialRoom","__TrialHardRoom","TouchPart","BillboardGui","Timer1"}
    },
    Medium = {
        coord = Vector3.new(761.0078735351562, 10.39693546295166, 13619.4267578125),
        portal = Vector3.new(879.0701293945312, 9.122308731079102, 13417.6103515625),
        room = "MediumTrialRoom",
        path = {"__GAME_CONTENT","Trials","MediumTrialRoom","__TrialMediumRoom","TouchPart","BillboardGui","Timer1"}
    },
    Easy = {
        coord = Vector3.new(750.042236328125, 10.428903579711914, 13485.44140625),
        portal = Vector3.new(851.4986572265625, 9.29580307006836, 13443.357421875),
        room = "EasyTrialRoom",
        path = {"__GAME_CONTENT","Trials","EasyTrialRoom","__TrialEasyRoom","TouchPart","BillboardGui","Timer1"}
    }
}

-- =============================================================================
-- TRIAL STATE (per-difficulty)
-- =============================================================================
local TRIAL_CAPTURE_DEFAULT = Vector3.new(836.826171875, 3.7000153064727783, 7674.1259765625)
local TrialState = {}
for diff in pairs(Trials) do
    TrialState[diff] = {
        autoJoin = false, autoLeave = false, wave = 1, leaveWave = 5,
        capturedPos = TRIAL_CAPTURE_DEFAULT, autoReturn = true,
        teleported = false, lastLog = 0, listening = false, inTrial = false,
        hasJoinedTrial = false,  -- Persistent flag: only cleared on explicit leave
        nearestMobFarm = false, walk = false, prevCount = -1,
        visitedMobs = {},
        mobCount = 0,
        nearestLoopThread = nil,
        nearestStopFlag = false,
        lastWave = 0,
        justLeft = false
    }
end

for _, noob in ipairs(Noobs) do
    S.autoRoll[noob] = false
    S.skipAlmighty[noob] = false
end

-- =============================================================================

-- =============================================================================
-- NO CLIP
-- =============================================================================
local nc1, nc2, nc3, fixedY
local function noclip(on)
    local c = LP.Character or LP.CharacterAdded:Wait()
    local hrp = c:WaitForChild("HumanoidRootPart", 5)
    local hum = c:WaitForChild("Humanoid", 5)
    if not hrp or not hum then return end
    if on then
        fixedY = hrp.Position.Y
        hum.JumpPower = 0; hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        -- Initial pass: disable collision on all existing parts
        for _, v in ipairs(c:GetDescendants()) do
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end
        -- Watch for new parts added to character (more efficient than per-frame scan)
        if not nc1 then nc1 = c.DescendantAdded:Connect(function(v)
            if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
        end) end
        -- Re-apply on character respawn
        if not nc3 then nc3 = LP.CharacterAdded:Connect(function(newChar)
            local newHrp = newChar:WaitForChild("HumanoidRootPart", 5)
            if newHrp then fixedY = newHrp.Position.Y end
            for _, v in ipairs(newChar:GetDescendants()) do
                if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
            end
            if nc1 then nc1:Disconnect() end
            nc1 = newChar.DescendantAdded:Connect(function(v)
                if v:IsA("BasePart") and v.CanCollide then v.CanCollide = false end
            end)
        end) end
        if not nc2 then nc2 = RS.Heartbeat:Connect(function()
            if not S.noclip then return end
            pcall(function()
                local char = LP.Character; if not char then return end
                local root = char:FindFirstChild("HumanoidRootPart"); local h = char:FindFirstChildOfClass("Humanoid")
                if not root or not h then return end
                h.Jump = false
                if math.abs(root.Position.Y - fixedY) > 0.5 then root.CFrame = CFrame.new(Vector3.new(root.Position.X, fixedY, root.Position.Z)) * root.CFrame.Rotation end
                root.AssemblyLinearVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
            end)
        end) end
    else
        if nc1 then nc1:Disconnect(); nc1 = nil end
        if nc2 then nc2:Disconnect(); nc2 = nil end
        if nc3 then nc3:Disconnect(); nc3 = nil end
        hum.JumpPower = 50; hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
    end
end

-- =============================================================================
-- ANTI-AFK
-- =============================================================================
local afkConn, afkHB
local function antiAFK(on)
    if afkConn then afkConn:Disconnect(); afkConn = nil end
    if afkHB then afkHB:Disconnect(); afkHB = nil end
    if not on then return end
    
    local VU = game:GetService("VirtualUser")
    
    -- Handle Roblox built-in idle detection
    afkConn = LP.Idled:Connect(function()
        pcall(function()
            VU:CaptureController()
            VU:ClickButton2(Vector2.new(10, 10))
        end)
    end)
    
    -- Periodic keep-alive ping every 60s (prevents custom server-side AFK)
    local lastPing = tick()
    afkHB = RS.Heartbeat:Connect(function()
        if tick() - lastPing > 60 then
            lastPing = tick()
            pcall(function()
                VU:CaptureController()
                VU:ClickButton2(Vector2.new(10, 10))
            end)
        end
    end)
end

-- =============================================================================
-- MOVEMENT
-- =============================================================================
local activeTween = nil
local function isCloseEnough(hrp, pos, threshold)
    if not hrp then return false end
    local dx, dz = pos.X - hrp.Position.X, pos.Z - hrp.Position.Z
    return dx*dx + dz*dz <= threshold*threshold
end
local function tweenTo(pos, customSpeed)
    local char = LP.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
    if not hrp then return end
    if isCloseEnough(hrp, pos, 3) then return end
    if activeTween then pcall(function() activeTween:Cancel() end); activeTween = nil end
    local speed = customSpeed or S.tweenSpeed
    local tw = TS:Create(hrp, TweenInfo.new(speed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = CFrame.new(pos.X, pos.Y, pos.Z)})
    activeTween = tw; tw:Play()
    -- Timeout guard: never wait longer than speed*3 + 5 seconds
    local waited, maxWait = 0, math.max(speed * 3, 5)
    while waited < maxWait do
        if tw.PlaybackState == Enum.PlaybackState.Completed or tw.PlaybackState == Enum.PlaybackState.Cancelled then break end
        if not hrp or not hrp.Parent then break end
        task.wait(0.1)
        waited = waited + 0.1
    end
    -- Force cleanup if tween didn't complete
    if tw.PlaybackState ~= Enum.PlaybackState.Completed then
        pcall(function() tw:Cancel() end)
    end
    activeTween = nil
    pcall(function() hrp.AssemblyLinearVelocity = Vector3.new() end)
    if hum then hum.PlatformStand = false; hum.Sit = false end
end
local function glideTo(pos, speed)
    local char = LP.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if activeTween then pcall(function() activeTween:Cancel() end); activeTween = nil end
    local tw = TS:Create(hrp, TweenInfo.new(speed or S.tweenSpeed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos.X, pos.Y, pos.Z)})
    activeTween = tw
    tw:Play()
    -- Safety timeout: auto-cancel after speed*3 + 10 seconds
    local myTween = tw
    task.spawn(function()
        local start = tick()
        local maxWait = math.max((speed or S.tweenSpeed) * 3, 10)
        while tick() - start < maxWait do
            if myTween.PlaybackState == Enum.PlaybackState.Completed or myTween.PlaybackState == Enum.PlaybackState.Cancelled then break end
            task.wait(0.1)
        end
        if myTween.PlaybackState ~= Enum.PlaybackState.Completed then
            pcall(function() myTween:Cancel() end)
        end
        if activeTween == myTween then activeTween = nil end
    end)
end

-- =============================================================================
-- TRIAL DETECTION (with caching for performance)
-- Method 1: TrialUI.Visible (most reliable, only true inside trial room)
-- Method 2: Distance check (fallback, smaller radius so nearby portal doesn't pause)
-- =============================================================================
local _trialCheckCache = {result = false, time = 0, pos = nil}
local function isPlayerInTrial()
    -- Method 1: PlayerGui TrialUI check (only true when inside trial room)
    local playerGui = LP:FindFirstChild("PlayerGui")
    if playerGui then
        local trialUI = playerGui:FindFirstChild("FullScreen") and
                       playerGui.FullScreen:FindFirstChild("Popups") and
                       playerGui.FullScreen.Popups:FindFirstChild("TrialUI")
        if trialUI and trialUI.Visible then
            return true
        end
    end

    -- Method 2: Distance-based check (inside trial room only, not portal area)
    local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    local pos = hrp.Position
    if _trialCheckCache.pos and tick() - _trialCheckCache.time < 0.5 then
        if math.abs(pos.X - _trialCheckCache.pos.X) < 2 and math.abs(pos.Z - _trialCheckCache.pos.Z) < 2 then
            return _trialCheckCache.result
        end
    end
    _trialCheckCache.pos = pos
    _trialCheckCache.time = tick()
    for _, tData in pairs(Trials) do
        if (pos - tData.coord).Magnitude < 200 then
            _trialCheckCache.result = true
            return true
        end
    end
    _trialCheckCache.result = false
    return false
end

-- Shared pause check: returns true if movement should be suspended (trial/ritual active)
-- Optionally waits a short time before returning so loops don't busy-spin
local function shouldPauseMovement(waitTime)
    if isPlayerInTrial() then
        if waitTime then task.wait(waitTime) end
        return true
    end
    if S.trialActive then
        if waitTime then task.wait(waitTime) end
        return true
    end
    if S.ritualActive then
        if waitTime then task.wait(waitTime) end
        return true
    end
    return false
end

-- =============================================================================
-- ORE / MINING SYSTEM
-- =============================================================================
local function isOreReady(ore)
    if not ore or not ore.Parent then return false end
    if not ore:FindFirstChild("Rock") then return false end
    local ui = ore:FindFirstChild("OresTopUI")
    if ui then local bar = ui:FindFirstChild("Bar")
        if bar then local hp = bar:FindFirstChild("Health")
            if hp and hp.Text == "Respawning..." then return false end
        end
    end
    return true
end
local function getOrePosition(ore)
    local rock = ore:FindFirstChild("Rock"); if rock and rock:IsA("BasePart") then return rock.Position end
    for _, child in ipairs(ore:GetChildren()) do if child:IsA("BasePart") then return child.Position end end
    local ok, pivot = pcall(function() return ore:GetPivot() end); if ok and pivot then return pivot.Position end
    return nil
end
local function findBestOre()
    local gc = WS:FindFirstChild("__GAME_CONTENT")
    local of = gc and gc:FindFirstChild("Ores")
    if not of then return nil end

    -- Fetch children once, then scan tiers
    local children
    pcall(function() children = of:GetChildren() end)
    if not children then return nil end

    -- Search from highest-tier ore down to lowest
    for i = #ORES, 1, -1 do
        if S["m" .. ORES[i]] then
        for _, o in ipairs(children) do
            if o.Name == ORES[i] and isOreReady(o) then
                return o
            end
        end
        end
    end
    return nil
end
local function isInMine()
    local gc = WS:FindFirstChild("__GAME_CONTENT"); if not gc then return false end
    local of = gc:FindFirstChild("Ores"); if not of then return false end
    return of:FindFirstChildWhichIsA("Model") ~= nil
end
local function loop()
    S._mineGen = (S._mineGen or 0) + 1
    local myGen = S._mineGen
    while S.running and not env.NIStop and S._mineGen == myGen do
        repeat
            if shouldPauseMovement(0.5) then break end

            if not isInMine() then task.wait(0.3); break end
            local any = false
            for _, n in ipairs(ORES) do
                if S["m" .. n] then any = true; break end
            end
            if not any then task.wait(0.1); break end

            local ore = findBestOre()
            if not ore then task.wait(0.1); break end

            local c = LP.Character
            local hrp = c and c:FindFirstChild("HumanoidRootPart")
            local hum = c and c:FindFirstChild("Humanoid")
            if not hrp or not hum or hum.Health <= 0 then task.wait(0.1); break end

            local orePos = getOrePosition(ore)
            if not orePos then task.wait(0.1); break end

            -- Check gen before tween (which blocks)
            if S._mineGen ~= myGen then break end
            tweenTo(orePos)
            if not S.running or env.NIStop or S._mineGen ~= myGen then break end

            local waitStart = tick()
            while S.running and not env.NIStop and S._mineGen == myGen do
                local ready = false
                pcall(function() ready = isOreReady(ore) end)
                if not ready then break end
                if tick() - waitStart > 40 then break end
                task.wait(0.05)
            end
        until true
    end
end

-- =============================================================================
-- COMBAT SYSTEM
-- =============================================================================
local function isRespawning(mob)
    local ok, result = pcall(function()
        for _, child in ipairs(mob:GetDescendants()) do
            if child:IsA("TextLabel") or child:IsA("TextButton") then
                local txt = child.Text or ""
                if txt:find("Respawning") or txt:find("Dead") or txt:find("DEAD") then return true end
            end
        end
        return false
    end)
    return ok and result
end
local function isRealMob(m)
    if not m or not m:IsA("Model") then return false end
    if m:FindFirstChildOfClass("Humanoid") then return true end
    if m:FindFirstChild("MobCharacter") then return true end
    for _, d in ipairs(m:GetDescendants()) do
        if d:IsA("Humanoid") then return true end
        if d.Name == "MobCharacter" then return true end
    end
    return false
end
local function isMobAlive(mob)
    if not mob or not mob.Parent then return false end
    if not isRealMob(mob) then return false end
    local hum = mob:FindFirstChildOfClass("Humanoid")
    if not hum then
        for _, d in ipairs(mob:GetDescendants()) do
            if d:IsA("Humanoid") then hum = d; break end
        end
    end
    if hum then return hum.Health > 0 end
    return not isRespawning(mob)
end
local function getMobPosition(mob)
    local hrp = mob:FindFirstChild("HumanoidRootPart"); if hrp then return hrp.Position end
    for _, child in ipairs(mob:GetDescendants()) do
        if child:IsA("BasePart") and child.Name == "HumanoidRootPart" then return child.Position end
    end
    if mob.PrimaryPart then return mob.PrimaryPart.Position end
    for _, child in ipairs(mob:GetChildren()) do if child:IsA("BasePart") then return child.Position end end
    local ok, pivot = pcall(function() return mob:GetPivot() end); if ok and pivot then return pivot.Position end
    return nil
end
-- Pre-built mob priority map for O(1) lookups (avoids linear scan of MOBS table)
local _mobPriorityMap = {}
for i, name in ipairs(MOBS) do _mobPriorityMap[name] = i end

-- findBestMob: cached scan ? only rescans the mobs folder at most every 0.4s.
-- This is a major lag saver when auto-combat is on with many mobs loaded.
local _mobCache = {m = nil, hrp = nil, hum = nil, time = 0}
local function findBestMob()
    -- Serve cached result if it's fresh and the mob is still alive
    if _mobCache.m and tick() - _mobCache.time < 0.4 then
        local alive = false
        pcall(function()
            if _mobCache.hum and _mobCache.hum.Parent and _mobCache.hum.Health > 0 then
                alive = true
            end
        end)
        if alive then return _mobCache.m, _mobCache.hrp, _mobCache.hum end
        _mobCache.m = nil
    end
    local ok, m, hrp, hum = pcall(function()
        local mf = WS:FindFirstChild("__GAME_CONTENT")
        mf = mf and mf:FindFirstChild("Mobs")
        if not mf then return nil, nil, nil end

        local children = mf:GetChildren()
        local best, bestHRP, bestHum, bestPri = nil, nil, nil, 0

        for _, mob in ipairs(children) do
            -- O(1) priority lookup instead of linear scan
            local pri = _mobPriorityMap[mob.Name] or 0
            if pri == 0 or pri <= bestPri or not S["c" .. mob.Name] then -- skip
            else
                -- Single GetDescendants pass: find Humanoid, HRP, and check respawn state
                local h, hr, respawning = nil, nil, false
                -- Try direct children first (fast path)
                h = mob:FindFirstChildOfClass("Humanoid")
                hr = mob:FindFirstChild("HumanoidRootPart")
                if not h or not hr then
                    for _, d in ipairs(mob:GetDescendants()) do
                        if not h and d:IsA("Humanoid") then h = d end
                        if not hr and d:IsA("BasePart") and d.Name == "HumanoidRootPart" then hr = d end
                        if not respawning and (d:IsA("TextLabel") or d:IsA("TextButton")) then
                            local txt = d.Text or ""
                            if txt:find("Respawning") or txt:find("Dead") or txt:find("DEAD") then respawning = true end
                        end
                        if h and hr and respawning then break end
                    end
                end
                if h and not respawning then
                    local alive = false
                    pcall(function() if h.Health > 0 then alive = true end end)
                    if alive then
                        best, bestHRP, bestHum, bestPri = mob, hr, h, pri
                    end
                end
            end
        end
        return best, bestHRP, bestHum
    end)
    if not ok then return nil, nil, nil end
    if m then _mobCache = {m = m, hrp = hrp, hum = hum, time = tick()} end
    return m, hrp, hum
end
local function combatLoop()
    S._combatGen = (S._combatGen or 0) + 1
    local myGen = S._combatGen
    while S.combatRunning and not env.NIStop and S._combatGen == myGen do
        repeat
            if shouldPauseMovement(0.5) then break end

            -- Also check TrialState teleported flag
            local pauseCombat = false
            for _, st in pairs(TrialState) do
                if type(st) == "table" and st.inTrial and st.teleported then
                    pauseCombat = true; break
                end
            end
            if pauseCombat then task.wait(0.5); break end

            local char = LP.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then task.wait(0.3); break end

            local any = false
            for _, n in ipairs(MOBS) do
                if S["c" .. n] then any = true; break end
            end
            if not any then task.wait(0.3); break end

            local mob, mobHRP, mobHum
            local ok = pcall(function() mob, mobHRP, mobHum = findBestMob() end)
            if not ok or not mob then task.wait(0.3); break end

            while mob and S.combatRunning and not env.NIStop do
                if shouldPauseMovement() then break end

                local mobPos = mobHRP and mobHRP.Position
                if not mobPos then mobPos = getMobPosition(mob) end
                if mobPos and not isCloseEnough(hrp, mobPos, 5) then
                    glideTo(mobPos, S.combatTweenSpeed)
                end

                local lastScan, deathStart = 0, tick()
                while S.combatRunning and mob and not env.NIStop do
                    if shouldPauseMovement() then break end

                    -- Health check
                    local dead = false
                    pcall(function()
                        if mobHum and mobHum.Health <= 0 then dead = true end
                    end)
                    if dead then break end

                    -- Periodic respawn check
                    if tick() - lastScan > 0.15 then
                        lastScan = tick()
                        local respawning = false
                        pcall(function() respawning = isRespawning(mob) end)
                        if respawning then break end
                        if not mob.Parent then break end
                    end
                    if tick() - deathStart > 8 then break end
                    task.wait(0.05)
                end
                pcall(function() mob, mobHRP, mobHum = findBestMob() end)
            end
        until true
    end
end

-- =============================================================================
-- ANCIENT BOSS SYSTEM
-- =============================================================================
local function findAncientBossInstance()
    local mf = WS:FindFirstChild("__GAME_CONTENT")
    if not mf then return nil, nil end
    -- Check main Mobs folder
    local mobsFolder = mf:FindFirstChild("Mobs")
    if mobsFolder then
        for _, m in ipairs(mobsFolder:GetChildren()) do
            if m:IsA("Model") and (m.Name:lower():find("ancient") or m.Name:lower():find("shadow") or m.Name:lower():find("supreme") or m.Name:lower():find("lord")) then
                local alive = false
                pcall(function()
                    local hum = m:FindFirstChildOfClass("Humanoid")
                    if not hum then
                        for _, d in ipairs(m:GetDescendants()) do
                            if d:IsA("Humanoid") then hum = d; break end
                        end
                    end
                    if hum and hum.Health > 0 then alive = true end
                end)
                if alive then return m, getMobPosition(m) end
            end
        end
    end
    -- Also check Trials folders for ancient bosses
    local trialsFolder = mf:FindFirstChild("Trials")
    if trialsFolder then
        for _, child in ipairs(trialsFolder:GetDescendants()) do
            if child:IsA("Humanoid") and child.Health > 0 and child.Parent ~= LP.Character then
                local mob = child.Parent
                if mob and mob:IsA("Model") and mob.Name:lower():find("ancient") then
                    local pos = getMobPosition(mob)
                    if pos then return mob, pos end
                end
            end
        end
    end
    return nil, nil
end
local BOSS_SPAWN_POS = Vector3.new(626.5310668945312, 4.572474956512451, 7857.5615234375)
local function ancientBossLoop()
    while S.abossRunning and not env.NIStop do
        if not shouldPauseMovement(0.5) then

        -- Move to spawn area if far
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - BOSS_SPAWN_POS).Magnitude > 10 then
            S.abossStatus = "Moving to boss area..."
            tweenTo(BOSS_SPAWN_POS, 1)
        end

        -- Fire spawn every cycle
        S.abossStatus = "Summoning..."
        pcall(function()
            game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer(
                "SpawnAncientMob", "Supreme Shadow Lord"
            )
        end)

        -- Wait 5s while checking for boss
        local waitStart = tick()
        while S.abossRunning and tick() - waitStart < 5 do
            local boss, bossPos = findAncientBossInstance()
            if boss then
                S.abossStatus = "Attacking..."
                local char = LP.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and bossPos and (hrp.Position - bossPos).Magnitude > 6 then
                    glideTo(bossPos, S.combatTweenSpeed)
                end
                -- Attack until dead or 120s timeout
                local killStart = tick()
                while S.abossRunning and tick() - killStart < 120 do
                    local dead = false
                    pcall(function()
                        local hum = boss:FindFirstChildOfClass("Humanoid")
                        if not hum then
                            for _, d in ipairs(boss:GetDescendants()) do
                                if d:IsA("Humanoid") then hum = d; break end
                            end
                        end
                        if not hum or hum.Health <= 0 or not hum.Parent then
                            dead = true
                        end
                    end)
                    if dead then S.abossStatus = "Defeated!"; break end
                    -- Re-glide if boss moved
                    local curPos = getMobPosition(boss)
                    if curPos and (hrp.Position - curPos).Magnitude > 6 then
                        glideTo(curPos, S.combatTweenSpeed)
                    end
                    task.wait()
                end
            end
            task.wait(0.5)
        end
        end  -- not shouldPauseMovement
    end
    S.abossStatus = "Stopped"
end

-- =============================================================================
-- RITUAL SYSTEM
-- =============================================================================
local function startRitual()
    pcall(function() game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("StartRitual") end)
end
local function ritualLoop()
    local RITUAL_POS = Vector3.new(838.05, 3.70, 7903.46)
    while S.ritualRunning and not env.NIStop do
        repeat
            if isPlayerInTrial() then task.wait(0.5); break end

            -- Pause combat/mining briefly for teleport + summon
            S.ritualActive = true

            -- Tween to altar
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if not hrp then S.ritualActive = false; task.wait(0.5); break end

            local dist = (hrp.Position - RITUAL_POS).Magnitude
            if dist > 5 then
                S.ritualStatus = "Moving to altar..."
                for attempt = 1, 5 do
                    if not S.ritualRunning or env.NIStop then break end
                    tweenTo(RITUAL_POS, 0.3)
                    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                    if h then dist = (h.Position - RITUAL_POS).Magnitude end
                    if dist <= 5 then break end
                end
                if not S.ritualRunning or env.NIStop then break end
                if dist > 5 then
                    S.ritualStatus = "Failed to reach altar, retrying..."
                    S.ritualActive = false
                    task.wait(1)
                    break  -- retry outer loop
                end
            end

            -- Fire ritual remote multiple times to ensure activation
            S.ritualStatus = "Summoning..."
            for i = 1, 5 do
                if not S.ritualRunning or env.NIStop then break end
                startRitual()
                task.wait(0.5)
            end

            -- Release combat/mining so they can fight ritual mobs
            S.ritualActive = false

            if not S.ritualRunning or env.NIStop then break end

        -- Fight phase (combat runs freely against ritual mobs)
        S.ritualStatus = "Ritual active - fighting (120s)"
        for i = 1, 120 do
            if not S.ritualRunning or env.NIStop then break end
            task.wait(1)
        end

        if not S.ritualRunning or env.NIStop then break end

        -- Cooldown phase
        S.ritualStatus = "Cooldown - other loops active..."
        for i = 1, S.ritualCooldown do
            if not S.ritualRunning or env.NIStop then break end
            task.wait(1)
        end
        until true
    end
    S.ritualActive = false
    S.ritualStatus = "Not Running"
end

-- =============================================================================
-- REALM 3 UPGRADE SYSTEM (Unified Upgrade Manager)
-- =============================================================================
-- =============================================================================
-- UPGRADE MANAGER — centralized rate limiting, cost cache, and fire tracking
-- =============================================================================
local UpgradeManager = {
    -- Global throttle: max 15 remote fires/sec across ALL upgrades
    _fireCount = 0,
    _fireTimer = 0,
    _fireLimit = 15,

    -- Per-upgrade rate limiting: {[key] = lastFireTime}
    _lastFire = {},
    -- Minimum 0.8s between fires for same upgrade (prevents spam)
    _perUpgradeCooldown = 0.8,

    -- Exponential backoff for unaffordable upgrades: {[key] = nextRetryTime}
    _backoff = {},
    _backoffBase = 1,      -- start at 1s
    _backoffMax = 16,       -- cap at 16s

    -- Maxed upgrades with TTL (5 min — resets on prestige naturally): {[key] = tick()}
    _maxed = {},
    _maxedTTL = 300,

    -- Recently bought tracking (for visual feedback): {[key] = tick()}
    _recentlyBought = {},

    -- Loop state
    _loopRunning = false,
    _loopThread = nil,
    _loopGen = 0,           -- generation counter for restart detection
    _loopHealthCheck = 0,   -- last successful cycle tick

    -- Cycle timing: varies between 0.25-0.45s for anti-detection
    _cycleMin = 0.25,
    _cycleMax = 0.45,
    _cycleDelay = 0.3,      -- current (changes each cycle with jitter)
}

-- Check if global throttle allows a fire; if so, consume one slot
local function _canFireGlobal()
    local now = tick()
    if now - UpgradeManager._fireTimer > 1 then
        UpgradeManager._fireCount = 0
        UpgradeManager._fireTimer = now
    end
    if UpgradeManager._fireCount >= UpgradeManager._fireLimit then return false end
    UpgradeManager._fireCount = UpgradeManager._fireCount + 1
    return true
end

-- Check per-upgrade cooldown
local function _canFireUpgrade(key)
    local last = UpgradeManager._lastFire[key] or 0
    return (tick() - last) >= UpgradeManager._perUpgradeCooldown
end

-- Check exponential backoff
local function _isBackedOff(key)
    local untilTime = UpgradeManager._backoff[key]
    return untilTime and tick() < untilTime
end

-- Apply exponential backoff (doubles each time, capped)
local function _applyBackoff(key)
    local current = UpgradeManager._backoff[key]
    if not current or current <= tick() then
        -- First backoff or expired: start at base
        UpgradeManager._backoff[key] = tick() + UpgradeManager._backoffBase
    else
        -- Already backed off: double remaining time, cap at max
        local remaining = current - tick()
        local doubled = math.min(remaining * 2, UpgradeManager._backoffMax)
        UpgradeManager._backoff[key] = tick() + doubled
    end
end

-- Clear backoff (upgrade became affordable)
local function _clearBackoff(key)
    UpgradeManager._backoff[key] = nil
end

-- Mark an upgrade as just fired (for rate limiting + visual feedback)
local function _markFired(key)
    UpgradeManager._lastFire[key] = tick()
    UpgradeManager._recentlyBought[key] = tick()
end

-- Fire a remote to the server with throttle checks
local function _fireRemote(remoteName, ...)
    if not _canFireGlobal() then return false end
    pcall(function()
        game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer(remoteName, ...)
    end)
    return true
end

local _noobFireTimes = {}
local function fireUpgradeNoobMax(npc)
    local key = "Noob_" .. npc
    if not _canFireUpgrade(key) then return end
    if not _canFireGlobal() then return end
    _markFired(key)
    pcall(function() game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("UpgradeNoobMax", npc) end)
end

-- Forward declarations for functions defined later but used early
local scanUpgradeCost, getResourceBalance, tryBuyUpgrade

-- Smart buy checker for Noob NPC upgrades (with cost awareness)
local function shouldBuyNoob(npcName)
    local cost = scanUpgradeCost("Noob", npcName)
    if not cost then
        local lastFire = _noobFireTimes[npcName] or 0
        return (tick() - lastFire) >= 3.0
    end
    local balance = getResourceBalance("Oofs")
    if not balance then
        local lastFire = _noobFireTimes[npcName] or 0
        return (tick() - lastFire) >= 3.0
    end
    return balance >= cost
end

-- Find a noob NPC model by name and return its position
local function findNoobNPCPosition(name)
    local ok, result = pcall(function()
        local gc = WS:FindFirstChild("__GAME_CONTENT")
        if not gc then return nil end
        local noobsFolder = gc:FindFirstChild("Noobs")
        if noobsFolder then
            for _, child in ipairs(noobsFolder:GetChildren()) do
                if child.Name == name and child:IsA("Model") then
                    local hrp = child:FindFirstChild("HumanoidRootPart")
                    if hrp then return hrp.Position end
                    if child.PrimaryPart then return child.PrimaryPart.Position end
                    for _, d in ipairs(child:GetDescendants()) do
                        if d:IsA("BasePart") and d.Name == "HumanoidRootPart" then return d.Position end
                    end
                    local pvt = child:GetPivot()
                    if pvt then return pvt.Position end
                end
            end
        end
        for _, obj in ipairs(gc:GetDescendants()) do
            if obj.Name == name and obj:IsA("Model") then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then return hrp.Position end
                if obj.PrimaryPart then return obj.PrimaryPart.Position end
            end
        end
        return nil
    end)
    return ok and result or nil
end
local function fireShovelLevelUp() pcall(function() game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("ShovelLevelUp") end) end

-- =============================================================================
-- REALM 4: AUTO RESEARCH SYSTEM
-- Remote: MainRemote:FireServer("StartResearch", researchId)
-- Costs Knowledge currency. Max concurrent = MaxResearch. Completed = FEATURES.RESEARCH.Completed
-- =============================================================================
local RESEARCH_LIST = {
    -- {id, cost, duration_seconds}
    {"StarResearch", 1e10, 30},
    {"PlanetResearch", 2.5e11, 45},
    {"PointResearch", 4e12, 60},
    {"RuneLuckResearch", 7.5e13, 120},
    {"RuneBulkResearch", 2e14, 150},
    {"SuperStarResearch", 7.5e14, 75},
    {"BlackholeResearch", 2e17, 90},
    {"RuneSpeedResearch", 3e18, 180},
    {"PrismResearch", 1.5e19, 210},
    {"UltraStarResearch", 5e21, 150},
    {"AlienResearch", 5e24, 165},
    {"IQResearch", 2e25, 180},
    {"PlanetaryResearch", 3.5e26, 195},
    {"RuneBulkyResearch", 8.5e27, 240},
    {"StarMutationResearch", 3e29, 270},
    {"HyperStarResearch", 1.25e31, 210},
    {"DarkholeResearch", 2.5e53, 225},
    {"TierLuckResearch", 3e54, 300},
    {"AlienMutationResearch", 3.75e55, 330},
    {"SpaceXPResearch", 1e56, 240},
    {"CStarResearch", 9.99e56, 900},
    {"SpaceResearch", 5e65, 255},
    {"LevelResearch", 2e66, 270},
    {"KnowledgeResearch", 1e69, 285},
    {"BalancedPlanetResearch", 1e79, 600},
    {"VoidResearch", 3.5e80, 300},
    {"TierBulkResearch", 1e82, 300},
    {"LevelsResearch", 1e90, 900},
    {"RadiusResearch", 1e92, 1200},
    {"BulkResearch", 1e94, 1800},
    {"LuckResearch", 1e96, 3600},
    {"OofResearch", 1e98, 7200},
    {"RuneResearch", 1e100, 14400},
    {"NoobResearch", 1e102, 21600},
    {"PrismaticResearch", 1e104, 32400},
}
local _researchFireTimes = {}
local _researchSkipUntil = {}  -- skip researches that keep failing

-- Look up research duration by ID
local function getResearchDuration(id)
    for _, entry in ipairs(RESEARCH_LIST) do
        if entry[1] == id then return entry[3] or 60 end
    end
    return 60
end

local function isResearchCompleted(id)
    local c = LP:FindFirstChild("FEATURES")
    if not c then return false end
    local r = c:FindFirstChild("RESEARCH")
    if not r then return false end
    local comp = r:FindFirstChild("Completed")
    if not comp then return false end
    local bv = comp:FindFirstChild(id)
    return bv ~= nil and bv.Value == true
end

local function isResearchActive(id)
    local c = LP:FindFirstChild("FEATURES")
    if not c then return false end
    local r = c:FindFirstChild("RESEARCH")
    if not r then return false end
    local active = r:FindFirstChild("Active")
    if not active then return false end
    return active:FindFirstChild(id) ~= nil
end

local function getActiveResearchCount()
    local c = LP:FindFirstChild("FEATURES")
    if not c then return 0 end
    local r = c:FindFirstChild("RESEARCH")
    if not r then return 0 end
    local active = r:FindFirstChild("Active")
    if not active then return 0 end
    return #active:GetChildren()
end

local function getMaxResearch()
    local cur = LP:FindFirstChild("CURRENCIES")
    if not cur then return 1 end
    local mr = cur:FindFirstChild("MaxResearch")
    if not mr then return 1 end
    local amt = mr:FindFirstChild("Amount")
    if amt and (amt:IsA("IntValue") or amt:IsA("NumberValue")) then
        return math.floor(amt.Value)
    end
    return 1
end

local function startResearchLoop()
    if S._researchLoopRunning then return end
    S._researchLoopRunning = true
    S._researchStatusText = "Starting..."
    S._researchLoopThread = task.spawn(function()
        while S._researchLoopRunning and S.autoResearch and not env.NIStop do
            local ok, err = pcall(function()
                local activeCount = getActiveResearchCount()
                local maxR = getMaxResearch()
                if activeCount >= maxR then
                    -- Find active research to estimate remaining time
                    local activeNames = {}
                    local minDuration = 30
                    local c = LP:FindFirstChild("FEATURES")
                    if c then
                        local r = c:FindFirstChild("RESEARCH")
                        if r then
                            local active = r:FindFirstChild("Active")
                            if active then
                                for _, child in ipairs(active:GetChildren()) do
                                    activeNames[#activeNames + 1] = child.Name
                                    local dur = getResearchDuration(child.Name)
                                    if dur < minDuration then minDuration = dur end
                                end
                            end
                        end
                    end
                    -- Wait based on shortest active research (capped at 30s for polling, but show actual)
                    local waitTime = math.min(minDuration, 30)
                    S._researchStatusText = "Researching: " .. table.concat(activeNames, ", ") .. " (" .. activeCount .. "/" .. maxR .. " slots) ~" .. minDuration .. "s"
                    task.wait(waitTime)
                    return
                end
                local fired = false
                for _, entry in ipairs(RESEARCH_LIST) do
                    if not S._researchLoopRunning or not S.autoResearch then break end
                    local id = entry[1]
                    local skipUntil = _researchSkipUntil[id] or 0
                    if tick() < skipUntil then
                        -- still skipping this one
                    else
                        local completed = isResearchCompleted(id)
                        local active = isResearchActive(id)
                        local lastFire = _researchFireTimes[id] or 0
                        local recent = (tick() - lastFire < 10)
                        -- Stuck detection: fired but never became active or completed
                        if not completed and not active and not recent and lastFire > 0 and (tick() - lastFire > 30) then
                            S._researchStatusText = "Skipping stuck: " .. id .. " (retry in 60s)"
                            _researchSkipUntil[id] = tick() + 60
                            _researchFireTimes[id] = 0
                        end
                        if not completed and not active and not recent and tick() >= (_researchSkipUntil[id] or 0) then
                            if getActiveResearchCount() >= getMaxResearch() then break end
                            if not _canFireGlobal() then break end
                            _researchFireTimes[id] = now
                            local firedOk, firedErr = pcall(function()
                                game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("StartResearch", id)
                            end)
                            if not firedOk then
                                S._researchStatusText = "ERROR: " .. tostring(firedErr)
                            else
                                local dur = entry[3] or 60
                                S._researchStatusText = "Started: " .. id .. " (" .. dur .. "s)"
                            end
                            task.wait(0.05)
                            fired = true
                            break
                        end
                    end
                end
                if not fired then
                    if activeCount >= maxR then
                        -- handled above
                    else
                        local firstNotDone = nil
                        for _, entry in ipairs(RESEARCH_LIST) do
                            local id = entry[1]
                            if not isResearchCompleted(id) and not isResearchActive(id) and tick() >= (_researchSkipUntil[id] or 0) then
                                firstNotDone = id
                                break
                            end
                        end
                        if firstNotDone then
                            S._researchStatusText = "Next: " .. firstNotDone
                        else
                            S._researchStatusText = "All researches done or in progress!"
                        end
                    end
                end
            end)
            if not ok then
                S._researchStatusText = "ERROR: " .. tostring(err)
            end
            task.wait(1)
        end
        S._researchLoopRunning = false
        S._researchLoopThread = nil
        S._researchStatusText = "Stopped"
    end)
end

local function stopResearchLoop()
    S._researchLoopRunning = false
    S._researchStatusText = "Stopped"
end

-- =============================================================================
-- REALM 4: AUTO UFO UPGRADE
-- Remote: MainRemote:FireServer("UpgradeUFOMax")
-- =============================================================================
local function startUFOLoop()
    if S._ufoLoopRunning then return end
    S._ufoLoopRunning = true
    S._ufoLoopThread = task.spawn(function()
        while S._ufoLoopRunning and S.autoUpgradeUFO and not env.NIStop do
            if _canFireGlobal() then
                pcall(function()
                    game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("UpgradeUFOMax")
                end)
            end
            task.wait(1)
        end
        S._ufoLoopRunning = false
        S._ufoLoopThread = nil
    end)
end

local function stopUFOLoop()
    S._ufoLoopRunning = false
end

-- =============================================================================
-- REALM 4: STARS COLLECTION SYSTEM
-- =============================================================================
local _cachedClientStars = nil
local function findStars()
    -- Cache the folder reference
    if not _cachedClientStars or not _cachedClientStars.Parent then
        _cachedClientStars = WS:FindFirstChild("ClientStars")
    end
    if not _cachedClientStars then return {} end
    local stars = {}
    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return {} end
    local playerPos = hrp.Position
    pcall(function()
        for _, star in ipairs(_cachedClientStars:GetChildren()) do
            local starPos = nil
            if star:IsA("BasePart") then
                starPos = star.Position
            elseif star:IsA("Model") then
                if star.PrimaryPart then
                    starPos = star.PrimaryPart.Position
                else
                    local hrpStar = star:FindFirstChild("HumanoidRootPart")
                    if hrpStar then starPos = hrpStar.Position end
                end
            end
            if starPos then
                local dx, dy, dz = starPos.X - playerPos.X, starPos.Y - playerPos.Y, starPos.Z - playerPos.Z
                stars[#stars + 1] = {obj = star, pos = starPos, dist = dx*dx + dy*dy + dz*dz}
            end
        end
    end)
    -- Sort by distance (closest first)
    if #stars > 3 then
        table.sort(stars, function(a, b) return a.dist < b.dist end)
    end
    return stars
end

local _starGlide = nil
local function glideToStar(pos)
    local char = LP.Character; if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local speed = S.starCollection.tweenSpeed / 100
    if speed < 0.01 then speed = 0.01 end
    if _starGlide then pcall(function() _starGlide:Cancel() end) end
    local ok = pcall(function()
        _starGlide = TS:Create(hrp, TweenInfo.new(speed, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos.X, pos.Y, pos.Z)})
    end)
    if ok and _starGlide then
        _starGlide:Play()
    else
        _starGlide = nil
        pcall(function() hrp.CFrame = CFrame.new(pos.X, pos.Y, pos.Z) end)
    end
end

local function collectStar(starData)
    -- Skip if star was already collected (removed from workspace)
    if not starData or not starData.obj or not starData.obj.Parent then return false end

    -- Non-blocking glide: returns instantly, game auto-collects on touch
    glideToStar(starData.pos)
    task.wait(0.02)  -- tiny delay for touch to register, then next star

    S.starCollection.collected = S.starCollection.collected + 1
    if S.starCollection.lastCollected == 0 then
        S.starCollection.lastCollected = tick()
    end
    return true
end

local _starLoopRunning = false
local _starLoopThread = nil
local function starCollectionLoop()
    _starLoopRunning = true
    while _starLoopRunning and S.starCollection.enabled and not env.NIStop do
        -- Pause during trials, rituals, noob tweening, AND trial pending/joining (S.trialActive)
        while _starLoopRunning and S.starCollection.enabled and (isPlayerInTrial() or S.ritualActive or S._noobTweening or S.trialActive) and not env.NIStop do
            task.wait(0.5)
        end
        if not _starLoopRunning or not S.starCollection.enabled or env.NIStop then break end

        local ok, loopErr = pcall(function()
            local stars = findStars()
            if #stars == 0 then
                task.wait(S.starCollection.delay)
                return
            end

            for i = 1, #stars do
                if not _starLoopRunning or not S.starCollection.enabled or env.NIStop then break end
                if isPlayerInTrial() or S.ritualActive or S._noobTweening or S.trialActive then break end
                local starData = stars[i]
                if starData and starData.obj and starData.obj.Parent then
                    collectStar(starData)
                end
                task.wait(S.starCollection.delay)
            end

            -- Update collection rate (stars per minute)
            local batchCollected = 0
            for i = 1, #stars do
                local sd = stars[i]
                if sd and sd.obj and not sd.obj.Parent then
                    batchCollected = batchCollected + 1
                end
            end
            if batchCollected > 0 then
                local batchTime = #stars * S.starCollection.delay + 0.5
                S.starCollection.rate = math.floor((batchCollected / batchTime) * 60)
            end
        end)
        if not ok then
            warn("[STARS LOOP ERROR] " .. tostring(loopErr))
            task.wait(1)
        end
    end
    _starLoopRunning = false
    _starLoopThread = nil
end

local function startStarLoop()
    if _starLoopThread then
        local alive = false
        pcall(function()
            if coroutine and coroutine.status then
                alive = coroutine.status(_starLoopThread) ~= "dead"
            end
        end)
        if alive then return end
        _starLoopThread = nil
    end
    _starLoopThread = task.spawn(starCollectionLoop)
end

local function stopStarLoop()
    _starLoopRunning = false
    _starLoopThread = nil
end

-- =============================================================================
-- REALM 4 UPGRADE BOARD TWEENER
-- Scans upgrade costs, only visits boards when balance ≥ cost × multiplier
-- =============================================================================
local REALM4_BOARD_CATEGORIES = {"Stars", "SpacePoints", "Planets", "Moon", "Blackholes", "AlienCash", "Knowledge"}

-- Check if a Realm 4 upgrade category has ANY individual toggle active + Auto Buy ON
local function isRealm4CategoryActive(cat)
    if not S["autoBuy_" .. cat] then return false end
    if cat == "Stars" then
        return S.autoStarEvenMoreStars or S.autoStarMoreStars or S.autoStarMoreSpacePoints
            or S.autoStarFasterRespawn or S.autoStarOof or S.autoStarBoostMutationLuck
    elseif cat == "SpacePoints" then
        return S.autoSpMultiStar or S.autoSpMoreSpacePoints or S.autoSpMoreMoon
            or S.autoSpBlackholes or S.autoSpBoostCollectRadius
    elseif cat == "Planets" then
        return S.autoPlanetsMorePlanets or S.autoPlanetsMoreStars or S.autoPlanetsHeatThePlanet
            or S.autoPlanetsMorePoints or S.autoPlanetsOofs or S.autoPlanetsBlackholes
    elseif cat == "Moon" then
        return S.autoMoonMoreMoon or S.autoMoonBoostStars or S.autoMoonMoreSpaceXP
            or S.autoMoonMorePlanets or S.autoMoonEvenMoreStars
    elseif cat == "Blackholes" then
        return S.autoBholeMoreBlackholes or S.autoBholePlanet or S.autoBholeFasterRespawn
            or S.autoBholeAliencash or S.autoBholeOofs
    elseif cat == "AlienCash" then
        return S.autoAlienMoreCash or S.autoAlienMoreXP or S.autoAlienBoostMutation or S.autoAlienVeryBadHoles
    elseif cat == "Knowledge" then
        return S.autoKnowledgeMoreKnowledge or S.autoKnowledgeMoreAlienCash or S.autoKnowledgeBoostSpaceXP
    end
    return false
end

-- Fire upgrade remotes for all active individual toggles within a category (while near board)
local function fireUpgradesForCategory(cat)
    if not UPGRADES then return end
    for _, e in ipairs(UPGRADES) do
        if e[2] == cat and S[e[1]] and S[e[5]] then
            local ok = pcall(tryBuyUpgrade, e[2], e[3], e[4])
            if ok then task.wait(0.02) end  -- tiny gap between fires
        end
    end
end

-- Static Realm 4 board positions (clustered by proximity)
local STAR_CLUSTER   = Vector3.new(-4570.626953125, 4.141540050506592, 18795.830078125)
local KNOW_CLUSTER   = Vector3.new(-4560.24169921875, 6.0291218757629395, 18654.4375)
local PLANET_CLUSTER = Vector3.new(-4409.81494140625, 4.141458511352539, 18723.904296875)

local REALM4_BOARD_STATIC = {
    Stars = STAR_CLUSTER, SpacePoints = STAR_CLUSTER,
    Moon = KNOW_CLUSTER, AlienCash = KNOW_CLUSTER, Knowledge = KNOW_CLUSTER,
    Planets = PLANET_CLUSTER, Blackholes = PLANET_CLUSTER,
}

-- Find upgrade board position (hardcoded lookup — instant, no scanning)
local function findRealm4BoardPosition(category)
    return REALM4_BOARD_STATIC[category]
end

-- Execute one full cycle: tween to each AFFORDABLE board, fire remotes, return
local function realm4BoardTweenCycle(affordableCats, affordableNoobs)
    if S._noobTweening then return end
    S._noobTweening = true

    local char = LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local originalPos = hrp and hrp.Position

    -- Build visit list from affordable-only categories + noobs
    local visitList = {}
    for _, cat in ipairs(affordableCats) do
        visitList[#visitList + 1] = {name = cat, isNoob = false}
    end
    for _, noobName in ipairs(affordableNoobs) do
        visitList[#visitList + 1] = {name = noobName, isNoob = true}
    end

    for _, entry in ipairs(visitList) do
        if not S._realm4BoardRunning or env.NIStop then break end
        if isPlayerInTrial() or S.trialActive then break end

        local pos
        if entry.isNoob then
            pos = findNoobNPCPosition(entry.name)
        else
            pos = findRealm4BoardPosition(entry.name)
        end

        if pos then
            pcall(function() tweenTo(pos, 0.05) end)
            -- Fire the upgrade remotes now that we're in range (distance check satisfied)
            if entry.isNoob then
                local fireEnd = tick() + 0.4
                while tick() < fireEnd do
                    if isPlayerInTrial() or S.trialActive then break end
                    if shouldBuyNoob(entry.name) then
                        fireUpgradeNoobMax(entry.name)
                    end
                    task.wait(0.1)
                end
            else
                fireUpgradesForCategory(entry.name)
            end
            local stayUntil = tick() + 0.1
            while tick() < stayUntil do
                if isPlayerInTrial() or S.trialActive then break end
                task.wait(0.05)
            end
        end
    end

    -- Return to original position
    if originalPos and not isPlayerInTrial() and not S.trialActive then
        local curHrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if curHrp and (curHrp.Position - originalPos).Magnitude > 10 then
            pcall(function() tweenTo(originalPos, 0.05) end)
        end
    end

    S._noobTweening = false
end

-- Check if a specific upgrade is affordable with the multiplier: balance ≥ cost × multiplier
local function isUpgradeAffordable(cat, upgName)
    local cost = scanUpgradeCost(cat, upgName)
    if not cost then return false end
    local balance = getResourceBalance(cat)
    if not balance then return false end
    if balance == math.huge then return true end
    if cost == math.huge then return balance == math.huge end
    return balance >= cost * S.realm4BoardMultiplier
end

-- Scan all active Realm 4 upgrades and return affordable categories + noobs
local function findAffordableUpgrades()
    if not UPGRADES then return {}, {} end
    local affordableCats = {}
    local affordableNoobs = {}

    -- Check upgrade categories via UPGRADES table
    for _, e in ipairs(UPGRADES) do
        local cat = e[2]
        if cat == "Stars" or cat == "SpacePoints" or cat == "Planets" or cat == "Moon"
            or cat == "Blackholes" or cat == "AlienCash" or cat == "Knowledge" then
            if S[e[1]] and S[e[5]] then
                if isUpgradeAffordable(cat, e[3]) then
                    affordableCats[cat] = true
                end
            end
        end
    end

    -- Check Realm 4 Noobs
    if Rayfield.Flags.autoBuyNoobRealm4 then
        local noobChecks = {{"Alien", S.autoNoobAlien}, {"Demon", S.autoNoobDemon}, {"Astronaut", S.autoNoobAstronaut}}
        for _, nc in ipairs(noobChecks) do
            if nc[2] then
                local cost = scanUpgradeCost("Noob", nc[1])
                local balance = getResourceBalance("Oof")
                if cost and balance and (balance == math.huge or cost == math.huge or balance >= cost * S.realm4BoardMultiplier) then
                    affordableNoobs[#affordableNoobs + 1] = nc[1]
                end
            end
        end
    end

    -- Convert set to ordered list
    local catList = {}
    for cat in pairs(affordableCats) do
        catList[#catList + 1] = cat
    end
    return catList, affordableNoobs
end

-- Background loop: checks affordability every 5s, triggers visit when any upgrade is affordable
local function realm4BoardLoop()
    while S._realm4BoardRunning and not env.NIStop do
        -- Pause during trials/ritual
        while S._realm4BoardRunning and (isPlayerInTrial() or S.trialActive or S.ritualActive) and not env.NIStop do
            task.wait(3)
        end
        if not S._realm4BoardRunning or env.NIStop then break end

        -- Only check if 30s cooldown has elapsed since last cycle
        if tick() - S._realm4BoardLastCycle >= 30 then
            pcall(batchScanAllUpgradeCosts)
            local affordableCats, affordableNoobs = findAffordableUpgrades()

            if #affordableCats > 0 or #affordableNoobs > 0 then
                S._realm4BoardLastCycle = tick()
                pcall(realm4BoardTweenCycle, affordableCats, affordableNoobs)
            end
        end

        task.wait(5)
    end
    S._realm4BoardRunning = false
end

local function startRealm4BoardLoop()
    if S._realm4BoardRunning then return end
    S._realm4BoardRunning = true
    pcall(function() task.spawn(realm4BoardLoop) end)
end

local function stopRealm4BoardLoop()
    S._realm4BoardRunning = false
end

-- =============================================================================
-- UNIVERSAL NUMBER PARSER (handles game's custom format)
-- Examples: "6.4e7.070k", "58.2UVt", "13.3NoDe", "71.7TDe"
-- =============================================================================
local SUFFIX_TABLE = {
    -- Standard
    [""]=1, K=1e3, M=1e6, B=1e9, T=1e12,
    Qd=1e15, Qn=1e18, Sx=1e21, Sp=1e24, Oc=1e27, No=1e30,
    -- Decillions
    De=1e33, UDe=1e36, DDe=1e39, TDe=1e42, QdDe=1e45, QnDe=1e48,
    SxDe=1e51, SpDe=1e54, OcDe=1e57, NoDe=1e60,
    -- Vigintillions
    Vt=1e63, UVt=1e66, DVt=1e69, TVt=1e72, QdVt=1e75, QnVt=1e78,
    SxVt=1e81, SpVt=1e84, OcVt=1e87, NoVt=1e90,
    -- Trigintillions
    Tg=1e93, UTg=1e96, DTg=1e99, TTg=1e102, QdTg=1e105, QnTg=1e108,
    SxTg=1e111, SpTg=1e114, OcTg=1e117, NoTg=1e120,
}
local function parseGameNumber(str)
    if not str or str == "" or str == "?" then return nil end
    str = tostring(str):gsub("^%s+",""):gsub("%s+$",""):gsub(",","")
    -- Handle infinity (game shows "inf" for extremely large numbers)
    if str:lower():find("^inf") then return math.huge end
    -- Try plain number first
    local num = tonumber(str)
    if num then return num end
    -- Format: "6.4e7.070k" -> base * 10^exponent * suffix
    -- The "." in the exponent is just a visual thousands separator (e.g. "7.072" = exponent 7072)
    local base, expInt, expFrac, suffix = str:match("^([%d%.%-]+)e([%d%.%-]+)%.([%d]+)(%a*)$")
    if base then
        base = tonumber(base)
        local expIntStr = expInt:gsub("%.", "")  -- strip any dots from expInt part
        local exponent = tonumber(expIntStr .. expFrac)  -- concat: "7".."072" = 7072
        local mult = SUFFIX_TABLE[suffix] or 1
        if not mult and #suffix > 0 then
            -- Try compound suffix: "NoDe", "UVt", etc.
            for k, v in pairs(SUFFIX_TABLE) do
                if suffix:lower() == k:lower() then mult = v; break end
            end
        end
        mult = mult or 1
        return base * (10 ^ exponent) * mult
    end
    -- Format: "1.00e28DTg" -> base * 10^exponent * suffix (no dot in exponent, e.g. 5.28e27DTg = 5.28e126)
    local baseE, expE, suffixE = str:match("^([%d%.%-]+)e([%d%.%-]+)(%a+)$")
    if baseE and expE then
        baseE = tonumber(baseE)
        expE = tonumber(expE:gsub("%.", ""))
        local mult = SUFFIX_TABLE[suffixE] or 1
        if not mult then
            for k, v in pairs(SUFFIX_TABLE) do
                if suffixE:lower() == k:lower() then mult = v; break end
            end
        end
        mult = mult or 1
        return baseE * (10 ^ expE) * mult
    end
    -- Format: "58.2UVt" -> base * suffix
    local base2, suffix2 = str:match("^([%d%.%-]+)(%a+)$")
    if base2 then
        base2 = tonumber(base2)
        local mult = SUFFIX_TABLE[suffix2]
        if not mult then
            for k, v in pairs(SUFFIX_TABLE) do
                if suffix2:lower() == k:lower() then mult = v; break end
            end
        end
        mult = mult or 1
        return base2 * mult
    end
    -- Format: "7 / 10" (fraction)
    local num3 = str:match("^([%d%.]+)")
    return tonumber(num3)
end

-- =============================================================================
-- PLAYER STAT READER (reads from PlayerGui text labels)
-- =============================================================================
local _currencyLabelCache = {}
local _statCacheLastAccess = {} -- tracks last access time per stat for TTL cleanup
local _statCacheBuilt = false
local function buildStatCache()
    if _statCacheBuilt then return end
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    -- Scan FullScreen.Currencies.ScrollingFrame once
    local fs = pg:FindFirstChild("FullScreen")
    local sf = fs and fs:FindFirstChild("Currencies") and fs.Currencies:FindFirstChild("ScrollingFrame")
    if sf then
        for _, frame in ipairs(sf:GetChildren()) do
            if frame:IsA("Frame") then
                local lbl = frame:FindFirstChild("Text") or frame:FindFirstChild("Amount")
                if lbl and lbl:IsA("TextLabel") then
                    _currencyLabelCache[frame.Name] = lbl
                end
            end
        end
    end
    -- Also scan HUD for special ones (Prisms, HackerPoints, Goals)
    local hud = pg:FindFirstChild("HUD")
    if hud then
        for _, frame in ipairs(hud:GetChildren()) do
            if frame:IsA("Frame") then
                local lbl = frame:FindFirstChild("Amount") or frame:FindFirstChild("Text")
                if lbl and lbl:IsA("TextLabel") then
                    _currencyLabelCache[frame.Name] = lbl
                end
            end
        end
    end
    _statCacheBuilt = true
end

local function getPlayerStat(name)
    _statCacheLastAccess[name] = tick()
    -- Build cache on first call (one-time scan)
    buildStatCache()
    -- Check cache
    local cached = _currencyLabelCache[name]
    if cached then
        if cached.Parent then
            return parseGameNumber(cached.Text or "")
        end
        _currencyLabelCache[name] = nil
    end
    -- Direct lookup (missed by cache scan, try direct path)
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local fs = pg:FindFirstChild("FullScreen")
        if fs then
            local currencies = fs:FindFirstChild("Currencies")
            if currencies then
                local sf = currencies:FindFirstChild("ScrollingFrame")
                if sf then
                    local frame = sf:FindFirstChild(name)
                    if frame then
                        for _, childName in ipairs({"Text", "Amount"}) do
                            local lbl = frame:FindFirstChild(childName)
                            if lbl and lbl:IsA("TextLabel") then
                                _currencyLabelCache[name] = lbl
                                return parseGameNumber(lbl.Text or "")
                            end
                        end
                    end
                end
            end
        end
        -- HUD fallback
        local hud = pg:FindFirstChild("HUD")
        if hud then
            local frame = hud:FindFirstChild(name)
            if frame then
                for _, childName in ipairs({"Text", "Amount"}) do
                    local lbl = frame:FindFirstChild(childName)
                    if lbl and lbl:IsA("TextLabel") then
                        _currencyLabelCache[name] = lbl
                        return parseGameNumber(lbl.Text or "")
                    end
                end
            end
        end
    end
    -- Fallback: leaderstats (StringValue for Oof)
    local ls = LP:FindFirstChild("leaderstats")
    if ls then
        local stat = ls:FindFirstChild(name)
        if stat then
            if stat:IsA("IntValue") or stat:IsA("NumberValue") then return stat.Value end
            if stat:IsA("StringValue") then return parseGameNumber(stat.Value) end
        end
    end
    -- Label is gone ? force cache rebuild on next call
    if _statCacheBuilt then
        _statCacheBuilt = false
        task.spawn(function() task.wait(0.5); buildStatCache() end)
    end
    return nil
end

-- TTL cache cleanup: runs every 60s, removes entries not accessed in 5 mins
task.spawn(function()
    while not env.NIStop do
        task.wait(60)
        local cutoff = tick() - 300
        for name, time in pairs(_statCacheLastAccess) do
            if time < cutoff then
                _currencyLabelCache[name] = nil
                _statCacheLastAccess[name] = nil
            end
        end
    end
end)

-- Check meat storage percentage (for threshold-based deposit) — cached for 5s
local _meatStorageCache = {pct = nil, time = 0}
local function getMeatStoragePercent()
    if tick() - _meatStorageCache.time < 5 then
        return _meatStorageCache.pct
    end
    local result = nil
    -- Try to read meat storage UI or data
    local meat = getPlayerStat("Meat") or getPlayerStat("Meats")
    local maxMeat = getPlayerStat("MaxMeat") or getPlayerStat("MeatCapacity") or getPlayerStat("MeatMax")
    if meat and maxMeat and maxMeat > 0 then
        result = (meat / maxMeat) * 100
    else
    -- Try reading from PlayerGui
    pcall(function()
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            for _, obj in ipairs(pg:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Visible then
                    local txt = obj.Text or ""
                    local m, mx = txt:match("(%d+%.?%d*)[%s/]+(%d+%.?%d*)")
                    if m and mx then
                        local parent = obj.Parent
                        if parent and (parent.Name:lower():find("meat") or (parent.Parent and parent.Parent.Name:lower():find("meat"))) then
                            result = (tonumber(m) / tonumber(mx)) * 100
                            break
                        end
                    end
                end
            end
        end
    end)
    end
    _meatStorageCache = {pct = result, time = tick()}
    return result
end

-- Loop state now managed by UpgradeManager._loopRunning / UpgradeManager._loopThread

-- ========== DATA-DRIVEN UPGRADE TABLE ==========
-- {S.flag, category, upgradeName, isMax, autoBuyKey}
-- The loop checks S[flag] AND S[autoBuyKey] before firing.
local UPGRADES = {
    -- Sand
    {"autoStrongerShovels","Sand","StrongerShovels",true,"autoBuy_Sand"},
    {"autoMoreSand","Sand","MoreSand",true,"autoBuy_Sand"},
    {"autoAlotSand","Sand","AlotSand",true,"autoBuy_Sand"},
    {"autoEvenMoreSand","Sand","EvenMoreSand",true,"autoBuy_Sand"},
    {"autoMultiSand","Sand","MultiSand",true,"autoBuy_Sand"},
    {"autoSandMoreOof","Sand","MoreOof",true,"autoBuy_Sand"},
    {"autoFasterShovels","Sand","FasterShovels",true,"autoBuy_Sand"},
    -- Souls
    {"autoMoreSouls","Souls","MoreSouls",true,"autoBuy_Souls"},
    {"autoMoreBones","Souls","MoreBones",true,"autoBuy_Souls"},
    {"autoMoreOof","Souls","MoreOof",true,"autoBuy_Souls"},
    {"autoLuckierSwords","Souls","LuckierSwords",true,"autoBuy_Souls"},
    {"autoSoulsRuneBulk","Souls","RuneBulk",true,"autoBuy_Souls"},
    -- Meat
    {"autoMeatToBones","Meat","MoreBones",true,"autoBuy_Meat"},
    {"autoStrongerSwords","Meat","StrongerSwords",true,"autoBuy_Meat"},
    {"autoMoreMeat","Meat","MoreMeat",true,"autoBuy_Meat"},
    {"autoMeatMoreOof","Meat","MoreOof",true,"autoBuy_Meat"},
    -- Bones
    {"autoBonesToHacker","Bones","HackerPointMulti",true,"autoBuy_Bones"},
    {"autoBonesFasterMeatConversion","Bones","FasterMeatConversion",true,"autoBuy_Bones"},
    {"autoBonesMoreOof","Bones","More Oof",true,"autoBuy_Bones"},
    {"autoBonesMoreBones_","Bones","MoreBones",true,"autoBuy_Bones"},
    {"autoBonesBiggerMeatDeposit","Bones","BiggerMeatDeposit",true,"autoBuy_Bones"},
    {"autoBonesEvenMoreBones","Bones","evenMoreBones",true,"autoBuy_Bones"},
    {"autoBonesFasterSwords","Bones","FasterSwords",true,"autoBuy_Bones"},
    -- Stars
    {"autoStarEvenMoreStars","Stars","EvenMoreStars",true,"autoBuy_Stars"},
    {"autoStarMoreStars","Stars","MoreStars",true,"autoBuy_Stars"},
    {"autoStarMoreSpacePoints","Stars","MoreSpacePoints",true,"autoBuy_Stars"},
    {"autoStarFasterRespawn","Stars","FasterRespawn",true,"autoBuy_Stars"},
    {"autoStarOof","Stars","Oof",true,"autoBuy_Stars"},
    {"autoStarBoostMutationLuck","Stars","BoostStarsMutationLuck",true,"autoBuy_Stars"},
    -- SpacePoints
    {"autoSpMultiStar","SpacePoints","MultiStar",true,"autoBuy_SpacePoints"},
    {"autoSpMoreSpacePoints","SpacePoints","MoreSpacePoints",true,"autoBuy_SpacePoints"},
    {"autoSpMoreMoon","SpacePoints","MoreMoon",true,"autoBuy_SpacePoints"},
    {"autoSpBlackholes","SpacePoints","Blackholes",true,"autoBuy_SpacePoints"},
    {"autoSpBoostCollectRadius","SpacePoints","BoostStarsCollectRadius",true,"autoBuy_SpacePoints"},
    -- Planets
    {"autoPlanetsMorePlanets","Planets","MorePlanets",true,"autoBuy_Planets"},
    {"autoPlanetsMoreStars","Planets","MoreStars",true,"autoBuy_Planets"},
    {"autoPlanetsHeatThePlanet","Planets","HeateThePlanet",true,"autoBuy_Planets"},
    {"autoPlanetsMorePoints","Planets","MorePoints",true,"autoBuy_Planets"},
    {"autoPlanetsOofs","Planets","Oofs",true,"autoBuy_Planets"},
    {"autoPlanetsBlackholes","Planets","Blackholes",true,"autoBuy_Planets"},
    -- Moon
    {"autoMoonMoreMoon","Moon","MoreMoon",true,"autoBuy_Moon"},
    {"autoMoonBoostStars","Moon","BoostStars",true,"autoBuy_Moon"},
    {"autoMoonMoreSpaceXP","Moon","MoreSpaceXP",true,"autoBuy_Moon"},
    {"autoMoonMorePlanets","Moon","MorePlanets",true,"autoBuy_Moon"},
    {"autoMoonEvenMoreStars","Moon","EvenMoreStars",true,"autoBuy_Moon"},
    -- HackPoints
    {"autoHackPoints","HackPoints","EvenMoreHackPoints",true,"autoBuy_HackPoints"},
    {"autoRuneLuck","HackPoints","MoreRuneLuckkk",true,"autoBuy_HackPoints"},
    {"autoMoreRuneSpeed","HackPoints","MoreRuneSpeed",true,"autoBuy_HackPoints"},
    {"autoMoreRuneLuck","HackPoints","MoreRuneLuck",true,"autoBuy_HackPoints"},
    {"autoMoreHackPoints","HackPoints","MoreHackPoints",true,"autoBuy_HackPoints"},
    {"autoConnorBalancedItt","HackPoints","ConnorBalancedItt",true,"autoBuy_HackPoints"},
    {"autoAutoHackPointsCollector","HackPoints","AutoHackPointsCollector",true,"autoBuy_HackPoints"},
    {"autoMoreRuneBulk","HackPoints","MoreRuneBulk",true,"autoBuy_HackPoints"},
    -- Blackholes
    {"autoBholeMoreBlackholes","Blackholes","MoreBlackholes",true,"autoBuy_Blackholes"},
    {"autoBholePlanet","Blackholes","Planet",true,"autoBuy_Blackholes"},
    {"autoBholeFasterRespawn","Blackholes","FasterRespawn",true,"autoBuy_Blackholes"},
    {"autoBholeAliencash","Blackholes","Aliencash",true,"autoBuy_Blackholes"},
    {"autoBholeOofs","Blackholes","Oofs",true,"autoBuy_Blackholes"},
    -- AlienCash
    {"autoAlienMoreCash","AlienCash","MoreAlienCash",true,"autoBuy_AlienCash"},
    {"autoAlienMoreXP","AlienCash","MoreAlienXP",true,"autoBuy_AlienCash"},
    {"autoAlienBoostMutation","AlienCash","BoostAlienMutationLuck",true,"autoBuy_AlienCash"},
    {"autoAlienVeryBadHoles","AlienCash","VeryBadHoles",true,"autoBuy_AlienCash"},
    -- Knowledge
    {"autoKnowledgeMoreKnowledge","Knowledge","MoreKnowledge",true,"autoBuy_Knowledge"},
    {"autoKnowledgeMoreAlienCash","Knowledge","MoreAlienCash",true,"autoBuy_Knowledge"},
    {"autoKnowledgeBoostSpaceXP","Knowledge","BoostSpaceXP",true,"autoBuy_Knowledge"},
}

-- Helper: quick check if ANY upgrade or noob toggle is active
local function _anyUpgradeActive()
    -- Check noob flags (simple booleans)
    if S.autoNoobPharaoh or S.autoNoobMummy or S.autoNoobMerchant
        or S.autoNoobAlien or S.autoNoobDemon or S.autoNoobAstronaut then return true end
    if S.autoUpgradePlanets or S.autoLevelUpShovel then return true end
    -- Check autoBuy keys + individual flags from UPGRADES table
    for _, e in ipairs(UPGRADES) do
        if S[e[1]] and S[e[5]] then return true end
    end
    return false
end

local function startRealm3Loop()
    -- Check if existing thread is actually alive (not dead from a crash)
    if UpgradeManager._loopThread then
        local alive = false
        pcall(function()
            if coroutine and coroutine.status then
                alive = coroutine.status(UpgradeManager._loopThread) ~= "dead"
            end
        end)
        if alive then return end
        UpgradeManager._loopThread = nil
    end
    if not _anyUpgradeActive() then return end

    UpgradeManager._loopRunning = true
    UpgradeManager._loopGen = UpgradeManager._loopGen + 1
    local myGen = UpgradeManager._loopGen

    UpgradeManager._loopThread = task.spawn(function()
        local shovelTick = 0
        local cycleCount = 0

        while UpgradeManager._loopRunning and not env.NIStop and UpgradeManager._loopGen == myGen do
            -- NOTE: Upgrades now fire remotes even during trial (no movement required).
            -- Only the noob-tween portion is skipped when in trial.
            if not UpgradeManager._loopRunning or env.NIStop then break end

            -- Health check: update timestamp so external watcher knows loop is alive
            UpgradeManager._loopHealthCheck = tick()

            -- Periodic dead-man check: every 60 cycles, verify something is still toggled
            cycleCount = cycleCount + 1
            if cycleCount % 60 == 0 then
                if not _anyUpgradeActive() then
                    UpgradeManager._loopRunning = false; break
                end
            end

            local ok, loopErr = pcall(function()
                -- Batch-scan ALL upgrade costs once (makes individual lookups instant)
                pcall(batchScanAllUpgradeCosts)
                -- NOTE: No longer skipping entirely during trial - remotes still fire below

                -- Noob upgrades: fire remotely every cycle; tween to best-ratio Noob periodically
                local shouldTweenToNoob = (S.noobTweenMinutes > 0) and (tick() - S._lastNoobTween >= S.noobTweenMinutes * 60) and not isPlayerInTrial() and not S.trialActive
                local noobList = {{"Pharaoh", S.autoNoobPharaoh}, {"Mummy", S.autoNoobMummy}, {"Merchant", S.autoNoobMerchant}, {"Alien", S.autoNoobAlien}, {"Demon", S.autoNoobDemon}, {"Astronaut", S.autoNoobAstronaut}}

                -- Fire remote for all selected Noobs (no tween needed, works from anywhere)
                for _, nb in ipairs(noobList) do
                    if nb[2] and shouldBuyNoob(nb[1]) then
                        fireUpgradeNoobMax(nb[1])
                    end
                end

                -- Tween to highest-tier selected Noob periodically (SKIPPED during trial)
                if shouldTweenToNoob then
                    local targetNoob = nil
                    for i = #noobList, 1, -1 do
                        if noobList[i][2] then targetNoob = noobList[i][1]; break end
                    end
                    if targetNoob then
                        local npcPos = findNoobNPCPosition(targetNoob)
                        if npcPos then
                            S._noobTweening = true
                            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                            local originalPos = hrp and hrp.Position
                            local tweenOk = pcall(function()
                                tweenTo(npcPos, 0.3); task.wait(1)
                                local spamEnd = tick() + 3
                                while tick() < spamEnd do
                                    if isPlayerInTrial() or S.trialActive then break end
                                    local h = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                    if h and (h.Position - npcPos).Magnitude < 15 then
                                        fireUpgradeNoobMax(targetNoob)
                                    end
                                    task.wait(0.3)
                                end
                                if originalPos and not isPlayerInTrial() and not S.trialActive then tweenTo(originalPos, 0.3) end
                            end)
                            if not tweenOk then warn("[NOOB TWEEN] " .. targetNoob .. " tween failed") end
                            S._noobTweening = false
                        end
                        S._lastNoobTween = tick()
                    end
                end

                -- Data-driven upgrade table (rotated start for fair ordering)
                S._upgradeRotIdx = ((S._upgradeRotIdx or 0) % #UPGRADES) + 1
                for i = 1, #UPGRADES do
                    local idx = ((S._upgradeRotIdx + i - 2) % #UPGRADES) + 1
                    local e = UPGRADES[idx]
                    if S[e[1]] and S[e[5]] then
                        local skipByRayfield = false
                        if Rayfield and Rayfield.Flags then
                            local rf = Rayfield.Flags[e[5]]
                            if rf == false then skipByRayfield = true end
                        end
                        if not skipByRayfield then
                            tryBuyUpgrade(e[2], e[3], e[4])
                        end
                    end
                end

                -- Special planet upgrades (different remote: UpgradePlanetMax)
                if S.autoUpgradePlanets then
                    if not S._planetLastFire then S._planetLastFire = {} end
                    local planetFires = 0
                    local raw = S._planetDropdown and S._planetDropdown.CurrentOption
                    if not raw and Rayfield and Rayfield.Flags then
                        raw = Rayfield.Flags.planetUpgradeList
                        if type(raw) == "table" and raw.CurrentOption then raw = raw.CurrentOption end
                    end
                    if type(raw) == "string" then raw = {raw} end
                    if type(raw) == "table" then
                        for _, planet in ipairs(raw) do
                            if type(planet) == "string" and planetFires < 2 then
                                local last = S._planetLastFire[planet] or 0
                                if tick() - last >= 3.0 then
                                    if not _canFireGlobal() then break end
                                    pcall(function()
                                        game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("UpgradePlanetMax", planet)
                                    end)
                                    S._planetLastFire[planet] = tick()
                                    planetFires = planetFires + 1
                                end
                            end
                        end
                    end
                end

                -- Shovel level up (interval-based, not every cycle)
                shovelTick = shovelTick + 1
                if S.autoLevelUpShovel and shovelTick >= S.shovelLevelUpInterval then
                    fireShovelLevelUp()
                    shovelTick = 0
                end
            end)

            if not ok then
                warn("[REALM3 LOOP ERROR] " .. tostring(loopErr))
                S._noobTweening = false
                task.wait(1)
            end
            if not UpgradeManager._loopRunning then break end

            -- Dynamic cycle delay with jitter for anti-detection
            local jitter = (math.random() - 0.5) * 0.1  -- ±0.05s jitter
            local delay = math.max(0.2, UpgradeManager._cycleDelay + jitter)
            task.wait(delay)
        end

        S._noobTweening = false
        UpgradeManager._loopThread = nil
        UpgradeManager._loopRunning = false
    end)
end

local function stopRealm3Loop()
    if _anyUpgradeActive() then return end  -- Other toggles still active, keep running
    UpgradeManager._loopRunning = false
    UpgradeManager._loopThread = nil
end

-- =============================================================================
-- AUTO BACK TO SURFACE
-- =============================================================================
local function getCurrentSandLayer()
    local ok, result = pcall(function()
        local ctrl = LP.PlayerScripts.Client.Controllers.Ctrl_SandLayers
        local highest = 0
        for _, child in ipairs(ctrl:GetChildren()) do
            local num = tonumber(child.Name:match("SandLayer_(%d+)"))
            if num and num > highest then highest = num end
        end
        return highest
    end)
    return ok and result or 0
end
local function autoBackToSurfaceLoop()
    local RESET_POS = Vector3.new(557.5693969726562, 5.152187824249268, 7817.81103515625)
    local RETURN_POS = Vector3.new(551.451416015625, 1.554121494293213, 7825.39453125)
    while S.autoBackToSurface and not env.NIStop do
        if not shouldPauseMovement(0.5) then

        local layer = getCurrentSandLayer()
        if layer >= S.backToSurfaceLayer then
            -- Fast tween to reset position (resets layers)
            tweenTo(RESET_POS, 0.5)
            task.wait(2.5)
            -- Fast tween back to sand start
            tweenTo(RETURN_POS, 0.3)
            task.wait(1)
        end
        end  -- not shouldPauseMovement
        task.wait(0.5)
    end
end

-- =============================================================================
-- AUTO OPEN CAPSULE
-- Remote: ToggleMinionAutoOpen, <capsuleType>
-- Tweens to capsule, fires remote, pauses during trials/noob tweening
-- =============================================================================
local CAPSULE_POSITIONS = {
    Classic  = Vector3.new(-2586.46, 40.21, -657.27),
    Super    = Vector3.new(615.94, 9.36, 3174.05),
    Football = Vector3.new(-2600.17, 35.99, -29.77),
    Ancient  = Vector3.new(713.37, 4.57, 7813.12),
}
local function fireOpenCapsule(capsuleType)
    capsuleType = capsuleType or S.selectedCapsule or "Ancient"
    if isPlayerInTrial() or S.trialActive then return end

    -- Tween to capsule position (must be near capsule)
    local pos = CAPSULE_POSITIONS[capsuleType]
    if capsuleType == "Cosmic" and not pos then
        local model = WS:FindFirstChild("__GAME_CONTENT") and WS.__GAME_CONTENT:FindFirstChild("UIZones") and WS.__GAME_CONTENT.UIZones:FindFirstChild("__CapsuleCosmic")
        if model then pos = model:GetPivot().Position end
    end
    if pos then
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp and (hrp.Position - pos).Magnitude > 8 then
            if isPlayerInTrial() or S.trialActive or S._noobTweening then return end
            tweenTo(pos, 1.2)
            task.wait(0.3)
        end
    end

    pcall(function()
        game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("ToggleMinionAutoOpen", capsuleType)
    end)
end
local function autoOpenCapsuleLoop()
    while S.autoOpenCapsule and not env.NIStop do
        -- Pause during trials, trial pending, ritual, and noob tweening
        while S.autoOpenCapsule and (isPlayerInTrial() or S.trialActive or S.ritualActive or S._noobTweening) and not env.NIStop do
            task.wait(0.5)
        end
        if not S.autoOpenCapsule or env.NIStop then break end
        fireOpenCapsule(S.selectedCapsule)
        task.wait(S.capsuleInterval)
    end
end

-- =============================================================================
-- AUTO RUNE (sit at rune, no remotes, pauses during trials)
-- =============================================================================
local RUNE_POSITIONS = {
    -- Realm 1
    Basic    = Vector3.new(713.37, 4.57, 7813.12),
    Super    = Vector3.new(1079.82, 18.50, -782.48),
    Advanced = Vector3.new(1079.82, 18.50, -782.48),
    Hacker   = Vector3.new(-2609.27, 40.83, -598.01),
    Football = Vector3.new(-2711.58, 36.57, -14.44),
    -- Realm 2
    Deepcore = Vector3.new(690.10, 9.25, 3161.02),
    Snowy    = Vector3.new(1017.19, 5.52, 3262.41),
    -- Realm 3
    Dune    = Vector3.new(982.98, 4.52, 7768.06),
    Sunfire = Vector3.new(693.79, 4.45, 7732.35),
    -- Prism
    ["Cosmic Prism"]   = Vector3.new(690.10, 9.25, 3161.02),
    ["Sunstorm Prism"] = Vector3.new(679.98, 4.28, 7839.86),
}
local function autoRuneLoop()
    while S.autoRune and not env.NIStop do
        -- Pause during trials (don't leave trial room)
        while S.autoRune and isPlayerInTrial() and not env.NIStop do
            task.wait(1)
        end
        -- Yield to noob upgrades (don't steal movement while noob is tweening)
        while S.autoRune and S._noobTweening and not env.NIStop do
            task.wait(0.5)
        end
        if not S.autoRune or env.NIStop then break end
        local pos = RUNE_POSITIONS[S.selectedRune]
        if pos then
            local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - pos).Magnitude > 8 then
                tweenTo(pos, 1.2)
            end
        end
        task.wait(2)  -- Re-check position every 2s, stay put otherwise
    end
end

-- =============================================================================
-- AUTO DEPOSIT MEAT
-- =============================================================================
local function autoDepositMeatLoop()
    while S.autoDepositMeat and not env.NIStop do
        -- Pause during trials (avoid interfering with trial activity)
        while S.autoDepositMeat and isPlayerInTrial() and not env.NIStop do
            task.wait(1)
        end
        -- Pause during ritual
        while S.autoDepositMeat and S.ritualActive and not env.NIStop do
            task.wait(1)
        end
        if not S.autoDepositMeat or env.NIStop then break end

        local shouldDeposit = false

        -- Percentage-based deposit (if threshold set > 0)
        if S.depositMeatPercent > 0 then
            local pct = getMeatStoragePercent()
            if pct and pct >= S.depositMeatPercent then
                shouldDeposit = true
            end
        end

        -- If percentage check didn't trigger, fire on the hourly interval
        if not shouldDeposit then
            shouldDeposit = true  -- Fire at least once per interval cycle
        end

        if shouldDeposit then
            pcall(function()
                game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("DepositMeat")
            end)
        end

        -- Wait based on slider (hours converted to seconds)
        local waitTime = S.depositMeatHours * 3600
        -- Check every 5 seconds for the percentage-based trigger
        local waited = 0
        while S.autoDepositMeat and waited < waitTime and not env.NIStop do
            -- If percentage-based and threshold is set, check frequently
            if S.depositMeatPercent > 0 then
                local pct = getMeatStoragePercent()
                if pct and pct >= S.depositMeatPercent then
                    pcall(function()
                        game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("DepositMeat")
                    end)
                end
            end
            task.wait(5)
            waited = waited + 5
        end
    end
end

-- =============================================================================
-- TRIAL CHESTS
-- =============================================================================
local _chestEmpty = {T2 = false, T1 = false}  -- tracks which types are empty

-- Listen for "You don't have any" error notifications from the game
task.spawn(function()
    local okE, event = pcall(function()
        return game:GetService("ReplicatedStorage").__Net.PromptNotification
    end)
    if not okE or not event then return end
    event.OnClientEvent:Connect(function(msgType, msg)
        if msgType == "Error" then
            if msg:find("T2TrialChest") then
                _chestEmpty.T2 = true
            elseif msg:find("T1TrialChest") then
                _chestEmpty.T1 = true
            end
        end
    end)
end)

local function tryOpen(chest)
    pcall(function()
        game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("OpenChest", chest, 7)
    end)
end

local _chestLoopRunning = false
local function chestLoop()
    local current = "T2"  -- start with T2 (better loot)
    while S.autoTrialChests and not env.NIStop do
        -- Burn through current type until empty
        while not _chestEmpty[current] and S.autoTrialChests and not env.NIStop do
            tryOpen(current == "T2" and "T2TrialChest" or "T1TrialChest")
            task.wait(0.5)
        end

        -- Switch to other type, burn through it
        local other = (current == "T2") and "T1" or "T2"
        while not _chestEmpty[other] and S.autoTrialChests and not env.NIStop do
            tryOpen(other == "T2" and "T2TrialChest" or "T1TrialChest")
            task.wait(0.5)
        end

        -- Both empty: wait then retry
        task.wait(10)
        _chestEmpty.T2 = false
        _chestEmpty.T1 = false

        -- Alternate starting type next cycle for fairness
        current = other
    end
    _chestLoopRunning = false
end

-- =============================================================================
-- COUNTDOWN LABEL / TIMER
-- =============================================================================
local function getCountdownLabel(diff)
    if not diff or not Trials[diff] or not Trials[diff].path then return nil end
    local ok, result = pcall(function()
        local obj = WS
        for _, name in ipairs(Trials[diff].path) do
            if not obj then return nil end
            obj = obj:FindFirstChild(name)
        end
        if obj and obj:IsA("TextLabel") then return obj end
        return nil
    end)
    return ok and result or nil
end
local function parseCountdown(text)
    if not text then return 0 end
    local min = tonumber(text:match("(%d+)m")) or 0
    local sec = tonumber(text:match("(%d+)s")) or 0
    return min * 60 + sec
end

-- =============================================================================
-- NEAREST MOB FARM (Trial Room)
-- =============================================================================
local function isInTrial(diff)
    -- Method 1: PlayerGui TrialUI check (most reliable, only true inside trial)
    local playerGui = LP:FindFirstChild("PlayerGui")
    if playerGui then
        local trialUI = playerGui:FindFirstChild("FullScreen") and
                       playerGui.FullScreen:FindFirstChild("Popups") and
                       playerGui.FullScreen.Popups:FindFirstChild("TrialUI")
        if trialUI and trialUI.Visible then
            return true
        end
    end

    -- Method 2: Distance check (fallback for portal/trial room area)
    local char = LP.Character
    if not char then return false end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return false end
    return (hrp.Position - Trials[diff].coord).Magnitude < 200
end

-- Safely get wave count from trial room UI (BillboardGui path + PlayerGui fallback)
local function getWaveCount(diff)
    local ok, result = pcall(function()
        -- Method 1: BillboardGui timer path (original)
        local obj = WS
        for _, name in ipairs(Trials[diff].path) do
            if obj then obj = obj:FindFirstChild(name) end
        end
        if obj and obj:IsA("TextLabel") then
            local txt = obj.Text or ""
            local waveNum = tonumber(txt:match("[Ww]ave%s+(%d+)"))
            if waveNum then return waveNum end
            local bg = obj:FindFirstAncestorOfClass("BillboardGui")
            if bg then
                local waveLabel = bg:FindFirstChild("Wave") or bg:FindFirstChild("WaveNumber")
                if waveLabel and waveLabel:IsA("TextLabel") then
                    local w = tonumber(waveLabel.Text:match("(%d+)"))
                    if w then return w end
                end
            end
        end
        -- Method 2: PlayerGui TrialUI (more reliable in trials)
        local playerGui = LP:FindFirstChild("PlayerGui")
        if playerGui then
            local trialUI = playerGui:FindFirstChild("FullScreen") and
                           playerGui.FullScreen:FindFirstChild("Popups") and
                           playerGui.FullScreen.Popups:FindFirstChild("TrialUI")
            if trialUI then
                local info = trialUI:FindFirstChild("Info")
                if info then
                    local waveCount = info:FindFirstChild("WaveCount")
                    if waveCount and waveCount:IsA("TextLabel") then
                        local w = tonumber(waveCount.Text)
                        if w then return w end
                    end
                end
                -- Try direct Wave label on TrialUI
                local waveLabel = trialUI:FindFirstChild("Wave") or trialUI:FindFirstChild("WaveCount")
                if waveLabel and waveLabel:IsA("TextLabel") then
                    local w = tonumber(waveLabel.Text:match("(%d+)"))
                    if w then return w end
                end
            end
        end
        return 0
    end)
    return ok and result or 0
end

local function findNearestHumanoid(diff)
    local char = LP.Character
    if not char then return nil end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return nil end

    if not isInTrial(diff) then return nil end

    local st = TrialState[diff]
    local trialCoord = Trials[diff].coord
    local nearest = nil
    local nearestDist = math.huge
    local seen = {}

    -- Scan __GAME_CONTENT only (Mobs + Trials folders)
    local gc = WS:FindFirstChild("__GAME_CONTENT")
    if not gc then return nil end

    for _, folder in ipairs({"Mobs", "Trials"}) do
        local f = gc:FindFirstChild(folder)
        if not f then
            -- skip
        else
            local descendants
            local ok = pcall(function() descendants = f:GetDescendants() end)
            if ok and descendants then
                local count = 0
                pcall(function()
                    for _, obj in ipairs(descendants) do
                        count = count + 1
                        if count % 500 == 0 then task.wait() end
                        if obj:IsA("Humanoid") and obj.Health > 0 then
                            local mob = obj.Parent
                            if mob and mob:IsA("Model") and mob ~= char and not seen[mob] then
                                seen[mob] = true
                                if not st.visitedMobs[mob] then
                                    local mobHRP = mob:FindFirstChild("HumanoidRootPart")
                                    if mobHRP then
                                        local pos = mobHRP.Position
                                        if (pos.X - trialCoord.X)^2 + (pos.Z - trialCoord.Z)^2 <= 40000 then
                                            local d2 = (pos.X - hrp.Position.X)^2 + (pos.Z - hrp.Position.Z)^2
                                            if d2 < nearestDist and d2 > 25 then
                                                nearestDist = d2
                                                nearest = mob
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end)
            end
        end
    end
    return nearest
end

local function nearestMobFarmLoop(diff)
    local st = TrialState[diff]
    local lastMobFound = tick()
    local lastWave = 0
    local waveTick = 0
    local myTween = nil  -- Per-trial tween tracking to avoid race conditions

    while st.nearestMobFarm and not env.NIStop and not st.nearestStopFlag do
        local _exitLoop = false
        repeat
        -- Pause during ritual (avoid fighting over movement while ritual is active)
        while st.nearestMobFarm and S.ritualRunning and not env.NIStop and not st.nearestStopFlag do
            task.wait(1)
        end
        if not st.nearestMobFarm or env.NIStop or st.nearestStopFlag then _exitLoop = true; break end

        if not isInTrial(diff) then task.wait(0.5); break end

        waveTick = waveTick + 1
        if waveTick >= 2 then
            waveTick = 0
            local w = getWaveCount(diff)
            if w ~= lastWave and w > 0 then
                st.visitedMobs = {}; st.mobCount = 0
                lastWave = w; st.wave = w
                if myTween then pcall(function() myTween:Cancel() end); myTween = nil end
                if activeTween then pcall(function() activeTween:Cancel() end); activeTween = nil end
                task.wait(0.3); break
            end
            lastWave = w
            if w > 0 then st.wave = w end
        end

        if st.autoLeave and st.leaveWave > 0 and st.wave >= st.leaveWave then
            st.justLeft = true
            pcall(function() game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("LeaveTrial") end)
            st.wave = 1; st.mobCount = 0; st.visitedMobs = {}; st.inTrial = false
            st.hasJoinedTrial = false; st.teleported = false
            S.trialActive = false
            if myTween then pcall(function() myTween:Cancel() end); myTween = nil end
            if st.autoReturn and st.capturedPos then
                task.spawn(function()
                    task.wait(3)
                    for attempt = 1, 30 do
                        local c = LP.Character
                        local h = c and c:FindFirstChild("HumanoidRootPart")
                        if h and h.Position.Y > 0 then
                            if pcall(function() tweenTo(st.capturedPos, 0.1) end) then break end
                        end
                        task.wait(0.25)
                    end
                end)
            end
            task.delay(5, function() st.justLeft = false end)
            task.wait(1)
            break
        end

        local mob = findNearestHumanoid(diff)
        if not mob then
            if tick() - lastMobFound > 1 then
                st.visitedMobs = {}; st.mobCount = 0
                lastMobFound = tick()
                if myTween then pcall(function() myTween:Cancel() end); myTween = nil end
            end
            task.wait(0.3); break
        end
        lastMobFound = tick()

        st.visitedMobs[mob] = true
        st.mobCount = st.mobCount + 1
        if st.mobCount >= 7 then st.visitedMobs = {}; st.mobCount = 0 end

        local mobHRP = mob:FindFirstChild("HumanoidRootPart")
        if not mobHRP then
            for _, d in ipairs(mob:GetDescendants()) do
                if d:IsA("BasePart") and d.Name == "HumanoidRootPart" then mobHRP = d; break end
            end
        end
        if not mobHRP then task.wait(0.3); break end

        -- Tween to mob
        local char = LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp and not isCloseEnough(hrp, mobHRP.Position, 3) then
            if myTween then pcall(function() myTween:Cancel() end) end
            if activeTween then pcall(function() activeTween:Cancel() end); activeTween = nil end
            local tw
            local tweenOk = pcall(function()
                tw = TS:Create(hrp, TweenInfo.new(S.nearestSpeed, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {CFrame = CFrame.new(mobHRP.Position)})
            end)
            if tweenOk and tw then
                myTween = tw; tw:Play()
                tw.Completed:Wait()
            else
                pcall(function() hrp.CFrame = CFrame.new(mobHRP.Position) end)
                task.wait(0.3)
            end
            myTween = nil
            pcall(function() hrp.AssemblyLinearVelocity = Vector3.new() end)
        end

        -- Combat in this game is proximity-based (no tool swinging needed).
        -- Just stay near the mob and the game handles damage automatically.
        task.wait(0.3)
        until true
        if _exitLoop then break end
    end
    st.nearestLoopThread = nil
    -- Don't set st.nearestMobFarm = false here ? only user toggling off should disable it
end

local function startNearestMobFarm(diff)
    local st = TrialState[diff]
    if st.nearestLoopThread then
        -- Check if thread is still alive (might have crashed)
        -- coroutine.status not available on all executors, use pcall-safe check
        local alive = false
        pcall(function()
            if coroutine and coroutine.status then
                alive = coroutine.status(st.nearestLoopThread) ~= "dead"
            end
        end)
        if alive then return end
        st.nearestLoopThread = nil
    end
    st.nearestStopFlag = false
    st.nearestLoopThread = task.spawn(function()
        local ok, err = pcall(nearestMobFarmLoop, diff)
        if not ok then warn("[NEAREST "..diff.."] " .. tostring(err)) end
        st.nearestLoopThread = nil
        -- Don't auto-disable toggle on error/exit ? only user toggling off should set to false
    end)
end

local function stopNearestMobFarm(diff)
    local st = TrialState[diff]
    st.nearestStopFlag = true
    st.nearestMobFarm = false
    if st.nearestLoopThread then
        -- Cancel any active tweens to prevent hanging
        if activeTween then
            pcall(function() activeTween:Cancel() end)
            activeTween = nil
        end
        task.wait(0.2)
        st.nearestLoopThread = nil
    end
end

-- =============================================================================
-- ENCHANT ROLL SYSTEM
-- =============================================================================
local rollLoops = {}
local function startRollLoop(noob)
    if rollLoops[noob] then return end
    rollLoops[noob] = task.spawn(function()
        while S.autoRoll[noob] and not env.NIStop do
            pcall(function()
                ReplicatedStorage.__Net.MainRemote:FireServer("RollNoobEnchant", noob)
            end)
            task.wait(S.enchantInterval)
        end
        rollLoops[noob] = nil
    end)
end

local warningConnection = nil
local function setupWarningHandler()
    if warningConnection then warningConnection:Disconnect() end
    warningConnection = ReplicatedStorage.__Net.EnchantWarning.OnClientEvent:Connect(function(noob, enchant)
        if enchant == "Almighty" and S.skipAlmighty[noob] then
            pcall(function()
                ReplicatedStorage.__Net.MainRemote:FireServer("ConfirmRollEnchant", noob)
            end)
        end
    end)
end

-- =============================================================================
-- AUTO JOIN TRIAL (Countdown Monitor)
-- =============================================================================
task.spawn(function()
    while not env.NIStop do
        local success, err = pcall(function()
            -- Pause ALL trial activity while ritual is running (avoid pulling player away from ritual)
            if S.ritualRunning then S.trialActive = false; task.wait(1); return end

            -- Check if ANY trial is active (countdown <= 8s on any auto-join trial)
            local anyActive = false
            local anyInTrial = false
            for diff, st in pairs(TrialState) do
                -- Guard: skip invalid entries (some executors yield bad pairs keys)
                if diff and type(diff) == "string" and st and Trials[diff] then
                -- First: check if player is actually inside the trial room (reliable detection)
                if st.autoJoin and isInTrial(diff) then
                    st.inTrial = true
                    st.teleported = true
                    st.hasJoinedTrial = true  -- Persistent: stays true until explicit leave
                    anyInTrial = true
                end
                -- Also keep state alive via persistent hasJoinedTrial flag (survives detection flickers)
                if st.autoJoin and st.hasJoinedTrial then
                    anyInTrial = true
                end
                if st.autoJoin then
                    local lbl = getCountdownLabel(diff)
                    if lbl then
                        local text = lbl.Text
                        if text and text ~= "" then
                            if not st.listening then
                                print("[AUTO JOIN "..diff.."] Countdown listening started.")
                                st.listening = true
                            end
                            local sec = parseCountdown(text)
                            if os.time() - st.lastLog >= 60 then
                                print("[AUTO JOIN "..diff.."] "..sec.." seconds until trial opens.")
                                st.lastLog = os.time()
                            end
                            if sec <= 8 then
                                st.trialPending = true
                                st._trialPendingSince = st._trialPendingSince or tick()
                                anyActive = true
                                S.trialActive = true  -- Immediately pause ALL other systems
                            else
                                st.trialPending = false
                                st._trialPendingSince = nil
                            end
                            -- ONLY tween to portal if we haven't actually joined the trial yet
                            if sec <= 8 and not st.teleported and not st.hasJoinedTrial then
                                print("[AUTO JOIN "..diff.."] Countdown ="..sec.."s, moving to portal...")
                                -- Cancel any star glide that might be pulling us away
                                if _starGlide then pcall(function() _starGlide:Cancel() end); _starGlide = nil end
                                if activeTween then pcall(function() activeTween:Cancel() end); activeTween = nil end
                                tweenTo(Trials[diff].portal, 0.1)
                                -- Fallback: direct teleport in case tween didn't reach
                                local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
                                if hrp then hrp.CFrame = CFrame.new(Trials[diff].portal) end
                                st.teleported = true
                                st.inTrial = true
                                print("[AUTO JOIN "..diff.."] Arrived at portal!")
                            end
                            -- IMPORTANT: Do NOT reset teleported while player is inside trial room
                            -- (sec > 8 can happen when countdown label changes to wave timer after joining)
                            -- Also protect with hasJoinedTrial for persistence across UI flickers
                            if sec > 8 and not isInTrial(diff) and not st.hasJoinedTrial then
                                st.teleported = false
                            end
                        end
                    else
                        -- Label not found: if player is in trial room or has joined, keep state alive
                        if not isInTrial(diff) and not st.hasJoinedTrial then
                            if os.time() - st.lastLog >= 30 then
                                warn("[AUTO JOIN "..diff.."] Countdown label not found!")
                                st.lastLog = os.time()
                            end
                            st.trialPending = false
                        end
                    end
                else
                    st.listening = false
                    st.trialPending = false
                end
            end  -- st.autoJoin
            end  -- guard
            -- Keep trialActive true if ANY trial has player inside OR is pending
            S.trialActive = anyActive or anyInTrial
            -- Safety: auto-reset trialActive if no trial pending AND no player in trial for > 60s (crash recovery)
            if S.trialActive and not anyInTrial then
                local anyRecentlyPending = false
                for _, st in pairs(TrialState) do
                    if type(st) == "table" and st._trialPendingSince then
                        if tick() - st._trialPendingSince < 60 then
                            anyRecentlyPending = true
                            break
                        end
                    end
                end
                if not anyRecentlyPending then
                    S.trialActive = false
                    for diff2, st2 in pairs(TrialState) do
                        if type(st2) == "table" then
                            st2.trialPending = false
                            st2._trialPendingSince = nil
                            -- Only reset teleported if NOT in trial room AND hasn't joined
                            if diff2 and Trials[diff2] and not isInTrial(diff2) and not st2.hasJoinedTrial then
                                st2.teleported = false
                            end
                        end
                    end
                end
            end
        end)
        if not success then
            warn("[AUTO JOIN ERROR] " .. tostring(err))
            task.wait(5)
        else
            task.wait(1)  -- Check every 1s to never miss the countdown window
        end
    end
end)

-- =============================================================================
-- AUTO LEAVE + AUTO RETURN (Independent Monitor)
-- =============================================================================
task.spawn(function()
    while not env.NIStop do
        local success, err = pcall(function()
            for diff, st in pairs(TrialState) do
                -- Guard: skip invalid entries (some executors yield bad pairs keys)
                if diff and type(diff) == "string" and st and Trials[diff] then
                if st.autoLeave and st.leaveWave > 0 then
                    if isInTrial(diff) then
                        local w = getWaveCount(diff)
                        if w > 0 then st.wave = w end
                        if w > 0 and w >= st.leaveWave then
                            st.justLeft = true
                            print("[AUTO LEAVE "..diff.."] Wave "..w.." >= "..st.leaveWave..", leaving trial...")
                            pcall(function() game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("LeaveTrial") end)
                            st.wave = 1; st.mobCount = 0; st.visitedMobs = {}
                            st.inTrial = false; st.teleported = false; st.hasJoinedTrial = false; st.justLeft = false
                            S.trialActive = false
                            -- Handle auto return to captured position
                            if st.autoReturn and st.capturedPos then
                                print("[AUTO RETURN "..diff.."] Preparing to tween back...")
                                task.spawn(function()
                                    task.wait(3)
                                    for attempt = 1, 30 do
                                        local c = LP.Character
                                        local hrp = c and c:FindFirstChild("HumanoidRootPart")
                                        if hrp and hrp.Position.Y > 0 then
                                            pcall(function() tweenTo(st.capturedPos, 0.1) end)
                                            print("[AUTO RETURN "..diff.."] Tweens back to captured position!")
                                            break
                                        end
                                        task.wait(0.25)
                                    end
                                end)
                            end
                        end
                    end
                end
            end  -- st.autoLeave
            end  -- guard
        end)
        if not success then
            warn("[AUTO LEAVE ERROR] " .. tostring(err))
        end
        task.wait(0.5)
    end
end)

-- =============================================================================
-- ANIMATION HIDER (Capsule/Chest)
-- =============================================================================
local function hideAnimations()
    local playerGui = LP:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Hide ALL animation-related GUIs
    for _, child in ipairs(playerGui:GetChildren()) do
        local name = child.Name:lower()
        if name:find("animation") or name:find("anim") or child.Name == "Animations" then
            pcall(function()
                child.Enabled = false
                child.Visible = false
            end)
        end
    end
    
    -- Also check in StarterGui
    local starterGui = game:GetService("StarterGui")
    if starterGui then
        for _, child in ipairs(starterGui:GetChildren()) do
            local name = child.Name:lower()
            if name:find("animation") or name:find("anim") or child.Name == "Animations" then
                pcall(function()
                    child.Enabled = false
                    child.Visible = false
                end)
            end
        end
    end
end

local function showAnimations()
    local playerGui = LP:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Show ALL animation-related GUIs
    for _, child in ipairs(playerGui:GetChildren()) do
        local name = child.Name:lower()
        if name:find("animation") or name:find("anim") or child.Name == "Animations" then
            pcall(function()
                child.Enabled = true
                child.Visible = true
            end)
        end
    end
    
    -- Also check in StarterGui
    local starterGui = game:GetService("StarterGui")
    if starterGui then
        for _, child in ipairs(starterGui:GetChildren()) do
            local name = child.Name:lower()
            if name:find("animation") or name:find("anim") or child.Name == "Animations" then
                pcall(function()
                    child.Enabled = true
                    child.Visible = true
                end)
            end
        end
    end
end

local function protectPlayerGUIs()
    local playerGui = LP:FindFirstChild("PlayerGui")
    if not playerGui then return end
    
    -- Keep all GUIs enabled
    for _, child in ipairs(playerGui:GetChildren()) do
        if child:IsA("ScreenGui") or child:IsA("GuiObject") then
            pcall(function()
                child.Enabled = true
                child.Visible = true
            end)
        end
    end
end

local function startAnimationMonitor()
    if S.animationConnection then
        pcall(function() S.animationConnection:Disconnect() end)
        S.animationConnection = nil
    end
    
    S.animMonitorRunning = true
    S.animationConnection = RS.Heartbeat:Connect(function()
        local currentTime = tick()
        
        -- Only update at specified interval to reduce lag
        if currentTime - S.lastUpdate < S.updateInterval then
            return
        end
        S.lastUpdate = currentTime
        
        -- Run GUI protector first, then animation remover (animation remover has final say)
        if S.protectGUIs then
            protectPlayerGUIs()
        end
        
        if S.hideAnimations then
            hideAnimations()
        end
    end)
end

local function stopAnimationMonitor()
    S.animMonitorRunning = false
    if S.animationConnection then
        pcall(function() S.animationConnection:Disconnect() end)
        S.animationConnection = nil
    end
    showAnimations()
end

-- =============================================================================
-- SMART AUTO UPGRADE SYSTEM
-- Detects upgrade costs, caches available upgrades, and buys intelligently
-- =============================================================================

-- Cost cache: stores {cost, time} per upgrade key to avoid repeated scanning
local _upgradeCostCache = {}
local COST_SCAN_INTERVAL = 45  -- re-scan every 45s

-- Reverse formatter: parsed number ? game suffix notation
local function formatGameNum(n)
    if not n then return "?" end
    if n == math.huge then return "∞" end  -- overflow — caller should provide raw text
    if n < 1000 then return tostring(math.floor(n)) end
    local suffixes = {
        {1e99,"DTg"},{1e96,"UTg"},{1e93,"Tg"},
        {1e90,"NoVt"},{1e87,"OcVt"},{1e84,"SpVt"},{1e81,"SxVt"},{1e78,"QnVt"},{1e75,"QdVt"},
        {1e72,"TVt"},{1e69,"DVt"},{1e66,"UVt"},{1e63,"Vt"},
        {1e60,"NoDe"},{1e57,"OcDe"},{1e54,"SpDe"},{1e51,"SxDe"},{1e48,"QnDe"},{1e45,"QdDe"},
        {1e42,"TDe"},{1e39,"DDe"},{1e36,"UDe"},{1e33,"De"},
        {1e30,"No"},{1e27,"Oc"},{1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},
        {1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"},
    }
    for _, s in ipairs(suffixes) do
        if n >= s[1] then
            local v = n / s[1]
            local vStr
            if v >= 1e6 then
                -- Compact e-notation for large v to avoid 3300000000000-style bloat
                local vExp = math.floor(math.log10(v))
                local vMant = v / (10 ^ vExp)
                vStr = string.format("%.2fe%d", vMant, vExp)
            elseif v >= 100 then
                vStr = string.format("%.0f", v)
            else
                vStr = string.format("%.2f", v)
            end
            return vStr .. s[2]
        end
    end
    -- Above DTg (1e99): game uses e-notation like 1.4e100
    local exp = math.floor(math.log10(n))
    local mantissa = n / (10 ^ exp)
    return string.format("%.1fe%d", mantissa, exp)
end

-- =============================================================================
-- BATCH COST SCANNER ? scans ALL WorldUI upgrades in one pass, caches everything
-- Called once per cycle so individual scanUpgradeCost calls are pure cache hits.
-- =============================================================================
local _batchScanCooldown = 0
local function batchScanAllUpgradeCosts()
    local now = tick()
    if now - _batchScanCooldown < 2 then return end  -- max once per 2s
    _batchScanCooldown = now

    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return end
    local worldUI = pg:FindFirstChild("WorldUI")
    if not worldUI then return end

    for _, folder in ipairs(worldUI:GetChildren()) do
        local category = folder.Name:match("^Upgrades%.%.(.+)$")
        if category then
            local main = folder:FindFirstChild("Main")
            if main then
                for _, entry in ipairs(main:GetChildren()) do
                    local costFrame = entry:FindFirstChild("Cost")
                    if costFrame then
                        local amount = costFrame:FindFirstChild("Amount")
                        if amount and amount:IsA("TextLabel") then
                            local cacheKey = category .. "_" .. entry.Name
                            if amount.Text == "MAX" then
                                _upgradeCostCache[cacheKey] = {cost = nil, raw = "MAX", time = now}
                            else
                                local cost = parseGameNumber(amount.Text or "")
                                if cost then
                                    _upgradeCostCache[cacheKey] = {cost = cost, raw = amount.Text, time = now}
                                    -- Also cache under camelCase key: "Even More Stars" → "EvenMoreStars"
                                    local noSpace = entry.Name:gsub(" ", "")
                                    if noSpace ~= entry.Name then
                                        _upgradeCostCache[category .. "_" .. noSpace] = {cost = cost, raw = amount.Text, time = now}
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- =============================================================================
-- ROBUST COST SCANNER ? individual lookup with batch cache + fallbacks
-- =============================================================================
scanUpgradeCost = function(category, upgradeName)
    local cacheKey = category .. "_" .. upgradeName
    local cached = _upgradeCostCache[cacheKey]
    if cached and tick() - cached.time < COST_SCAN_INTERVAL then
        return cached.cost
    end

    local function cacheAndReturn(cost, rawText)
        _upgradeCostCache[cacheKey] = {cost = cost, raw = rawText, time = tick()}
        return cost
    end

    -- Throttle expensive METHOD C fallback (GetDescendants) to every 5 cycles
    if not S._methodCThrottle then S._methodCThrottle = {} end
    local mcCount = (S._methodCThrottle[cacheKey] or 0) + 1
    S._methodCThrottle[cacheKey] = mcCount

    -- Helper: extract all parseable numbers from a string, return largest
    local function extractLargestNumber(txt)
        if not txt or txt == "" then return nil end
        -- Try the whole string first
        local n = parseGameNumber(txt)
        if n then return n end
        -- Try space-delimited parts (e.g. "7.5e7.070k Oof" ? try "7.5e7.070k")
        local best = nil
        for part in txt:gmatch("%S+") do
            local pn = parseGameNumber(part)
            if pn and (not best or pn > best) then best = pn end
        end
        return best
    end

    -- ============================
    -- METHOD A: Noob NPC costs ? direct FEATURES path (fast, reliable)
    -- Path: LP.FEATURES.NOOBS.{Name}.OofGeneration or .OofCost or similar
    -- ============================
    if category == "Noob" then
        -- A0: Scan workspace NPC model for BillboardGuis with Upgrade.Cost (also broad fallback)
        local gc = WS:FindFirstChild("__GAME_CONTENT")
        local noobsFolder = gc and gc:FindFirstChild("Noobs")
        if noobsFolder then
            local npc = noobsFolder:FindFirstChild(upgradeName)
            if npc and npc:IsA("Model") then
                for _, obj in ipairs(npc:GetDescendants()) do
                    if (obj:IsA("BillboardGui") or obj:IsA("SurfaceGui")) and obj.Enabled then
                        for _, label in ipairs(obj:GetDescendants()) do
                            if label:IsA("TextLabel") and label.Visible then
                                -- Exact: Upgrade.Cost
                                if label.Parent and label.Parent.Name == "Upgrade" and label.Name == "Cost" then
                                    local cost = extractLargestNumber(label.Text or "")
                                    if cost and cost > 1000 then return cacheAndReturn(cost) end
                                -- Broad: any label in BillboardGui with a cost-like number > 1000
                                else
                                    local cost = extractLargestNumber(label.Text or "")
                                    if cost and cost > 1000 then return cacheAndReturn(cost) end
                                end
                            end
                        end
                    end
                end
            end
        end
        -- A0b: Scoped fallback ? search __GAME_CONTENT for NPC model and check BillboardGuis
        if not noobsFolder or not noobsFolder:FindFirstChild(upgradeName) then
            local gc2 = WS:FindFirstChild("__GAME_CONTENT")
            if gc2 then
                for _, obj in ipairs(gc2:GetDescendants()) do
                    if obj.Name == upgradeName and obj:IsA("Model") then
                        for _, gui in ipairs(obj:GetDescendants()) do
                            if (gui:IsA("BillboardGui") or gui:IsA("SurfaceGui")) and gui.Enabled then
                                for _, label in ipairs(gui:GetDescendants()) do
                                    if label:IsA("TextLabel") and label.Visible then
                                        local cost = extractLargestNumber(label.Text or "")
                                        if cost and cost > 1000 then return cacheAndReturn(cost) end
                                    end
                                end
                            end
                        end
                        break  -- Only check first matching model
                    end
                end
            end
        end
        -- A1: Unified PlayerGui scan (single pass ? covers A1, A1b, A3)
        local pg = LP:FindFirstChild("PlayerGui")
        if pg then
            local nameLower = upgradeName:lower()
            for _, obj in ipairs(pg:GetDescendants()) do
                if obj:IsA("TextLabel") and obj.Visible then
                    local txt = obj.Text or ""
                    local txtLower = txt:lower()
                    -- Match: label contains Noob name + "oof" OR is Upgrade.Cost with "oof" OR just contains Noob name
                    if (txtLower:find(nameLower, 1, true) and txtLower:find("oof", 1, true))
                       or (obj.Parent and obj.Parent.Name == "Upgrade" and obj.Name == "Cost" and txtLower:find("oof", 1, true))
                       or txtLower:find(nameLower, 1, true) then
                        local cost = extractLargestNumber(txt)
                        if cost and cost > 1000 then return cacheAndReturn(cost) end
                    end
                end
            end
        end
        -- A2: Direct FEATURES path (most reliable)
        local features = LP:FindFirstChild("FEATURES")
        if features then
            local noobs = features:FindFirstChild("NOOBS")
            if noobs then
                local npcData = noobs:FindFirstChild(upgradeName)
                if npcData then
                    -- Scan ALL numeric children for the upgrade cost
                    -- The cost is the smallest large number (not generation rate which is small)
                    local bestCost = nil
                    for _, child in ipairs(npcData:GetChildren()) do
                        local val = nil
                        if child:IsA("IntValue") or child:IsA("NumberValue") then
                            val = child.Value
                        elseif child:IsA("StringValue") then
                            val = parseGameNumber(child.Value)
                        elseif child:IsA("TextLabel") then
                            val = parseGameNumber(child.Text)
                        end
                        -- Skip small numbers (generation rates like 1-1000), keep large costs
                        if val and val > 1000 and (not bestCost or val < bestCost) then
                            bestCost = val
                        end
                    end
                    if bestCost then return cacheAndReturn(bestCost) end
                end
            end
        end
        return nil
    end

    -- ============================
    -- METHOD B: UpgradeUpgrade costs ? direct path
    -- ============================
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        local worldUI = pg:FindFirstChild("WorldUI")
        if worldUI then
            -- Try primary category folder, then singular form (e.g. "Planets" ? "Planet")
            for _, catTry in ipairs({category, category:gsub("s$", "")}) do
                if catTry == category and _ > 1 then break end  -- skip duplicate if no 's'
                local upgradeFolder = worldUI:FindFirstChild("Upgrades.." .. catTry)
                if upgradeFolder then
                    local main = upgradeFolder:FindFirstChild("Main")
                    if main then
                        local entry = main:FindFirstChild(upgradeName)
                        -- Fallback: game UI often uses spaced names ("Even More Stars")
                        -- while our table uses camelCase ("EvenMoreStars").
                        if not entry then
                            local spaced = upgradeName:gsub("(%l)(%u)", "%1 %2")
                            if spaced ~= upgradeName then
                                entry = main:FindFirstChild(spaced)
                            end
                        end
                        if entry then
                            local costFrame = entry:FindFirstChild("Cost")
                            if costFrame then
                                local amount = costFrame:FindFirstChild("Amount")
                                if amount and amount:IsA("TextLabel") then
                                    if amount.Text == "MAX" then
                                        UpgradeManager._maxed[cacheKey] = tick()  -- TTL cache
                                        return nil
                                    end
                                    local cost = parseGameNumber(amount.Text or "")
                                    if cost then return cacheAndReturn(cost) end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- ============================
    -- METHOD C: Fallback scan (GetDescendants) ? throttled to every 20th call
    -- ============================
    if pg and (mcCount == 1 or mcCount % 20 == 0) then
        local nameLower = upgradeName:lower()
        for _, obj in ipairs(pg:GetDescendants()) do
            if obj:IsA("TextLabel") and obj.Visible then
                local txt = obj.Text or ""
                if #txt > 5 and txt:lower():find(nameLower, 1, true) then
                    local cost = extractLargestNumber(txt)
                    if cost and cost > 1000 then
                        local parent = obj.Parent
                        if parent and (parent.Name == "Cost" or (parent.Parent and parent.Parent.Name == "Cost")) then
                            return cacheAndReturn(cost)
                        end
                    end
                end
            end
        end
    end

    -- Cache nil (MAXed / unknown) so we don't re-scan every cycle
    -- EXCEPT for Noob: NPC may not be loaded yet, so don't cache — retry next cycle
    if not cached and category ~= "Noob" then
        _upgradeCostCache[cacheKey] = {cost = nil, raw = nil, time = tick()}
    end
    return nil
end

-- =============================================================================
-- CURRENCIES DIRECT READER — reads from LP.CURRENCIES (IntValue/NumberValue)
-- Faster and more reliable than scanning PlayerGui labels for known currencies.
-- Global so both upgrade system and research loop can use it.
-- =============================================================================
function readCurrencyDirect(name)
    local c = LP:FindFirstChild("CURRENCIES")
    if not c then return nil end
    local container = c:FindFirstChild(name)
    if not container then return nil end
    -- Helper: search a folder's children for a value
    local function findValueIn(folder)
        if not folder then return nil end
        -- Direct value types on the folder itself
        if folder:IsA("IntValue") or folder:IsA("NumberValue") then return folder.Value end
        if folder:IsA("StringValue") then return tonumber(folder.Value) end
        -- Search children for value types
        for _, child in ipairs(folder:GetChildren()) do
            if child:IsA("IntValue") or child:IsA("NumberValue") then
                return child.Value
            elseif child:IsA("StringValue") then
                local n = tonumber(child.Value)
                if n then return n end
            end
        end
        return nil
    end
    -- Try .Amount child first (may be a value or a folder containing the value)
    local amt = container:FindFirstChild("Amount")
    local val = findValueIn(amt)
    if val then return val end
    -- Try container itself (may be a value or a folder)
    val = findValueIn(container)
    if val then return val end
    return nil
end

-- Clean raw number text: strip trailing zeros from scientific notation
-- "1.500000000000e315" → "1.5e315", "3.1400000e200" → "3.14e200"
local function cleanRawNumber(txt)
    if not txt then return nil end
    txt = txt:gsub("^%s+", ""):gsub("%s+$", ""):gsub(",", "")
    -- Only clean e-notation values
    local mantissa, exponent = txt:match("^([%d%.]+)[eE](.+)$")
    if not mantissa then return txt end
    -- Strip trailing zeros after decimal point
    mantissa = mantissa:gsub("%.?0+$", "")
    if mantissa == "" then mantissa = "0" end
    return mantissa .. "e" .. exponent
end

-- Read raw text from CURRENCIES (bypasses number parsing — for overflow values like 1.5e315)
local function readCurrencyRaw(name)
    local pg = LP:FindFirstChild("PlayerGui")
    if not pg then return nil end
    -- Try CURRENCIES folder first (TextLabel)
    local c = LP:FindFirstChild("CURRENCIES")
    if c then
        local container = c:FindFirstChild(name)
        if container then
            local amt = container:FindFirstChild("Amount")
            if amt then
                if amt:IsA("TextLabel") then return cleanRawNumber(amt.Text) end
                if amt:IsA("StringValue") then return cleanRawNumber(amt.Value) end
            end
        end
    end
    -- Try PlayerGui stat cache
    local val = getPlayerStat(name)
    if val == math.huge then
        -- Stat was parsed as inf — try to re-read the raw label text
        local cached = _currencyLabelCache[name]
        if cached and cached.Parent and cached:IsA("TextLabel") then
            return cleanRawNumber(cached.Text)
        end
    end
    return nil
end

-- =============================================================================
-- RESOURCE BALANCE READER (uses PlayerGui label parent names from diagnostic)
-- Actual parent names seen: Oofs, Sand, Bones, Souls, Meat, HackerPoints, etc.
-- Returns: parsedNumber, rawText (raw text is non-nil only when number overflowed)
-- =============================================================================
local UPGRADE_RESOURCE_MAP = {
    Sand = "Sand", Souls = "Souls", Bones = "Bones", Meat = "Meat",
    HackPoints = "HackerPoints",  -- parent name in PlayerGui
    Oof = "Oofs", Noob = "Oofs",
    Stars = "Stars", SpacePoints = "SpacePoints",
    Planets = "Planets", Moon = "Moon",
    Blackholes = "Blackholes", AlienCash = "AlienCash", Knowledge = "Knowledge",
    Goals = "Goals", Wood = "Wood", Planks = "Planks",
    Bread = "Bread", Cash = "Cash", Fire = "Fire", Water = "Water",
    Gems = "Gems", Ice = "Ice", Coins = "Coins", Ash = "Ash",
    Wheat = "Wheat", Blaze = "Blaze", Rebirth = "Rebirth",
}

getResourceBalance = function(resourceType)
    local labelName = UPGRADE_RESOURCE_MAP[resourceType] or resourceType
    -- Try LP.CURRENCIES direct read first (fast, reliable for known currencies)
    local direct = readCurrencyDirect(labelName)
    if direct then
        if direct == math.huge then
            -- Overflow: try to get raw text for display
            local raw = readCurrencyRaw(labelName) or readCurrencyRaw(resourceType)
            return direct, raw
        end
        return direct
    end
    -- Try PlayerGui label scan
    local val = getPlayerStat(labelName)
    if val then
        if val == math.huge then
            local raw = readCurrencyRaw(labelName)
            return val, raw
        end
        return val
    end
    -- Try common alternate names
    local alternates = {
        Oofs = {"Oofs", "Oof"},
        HackPoints = {"HackerPoints", "Hacker Points", "Hack Points"},
        Bones = {"Bones", "Bone"},
        Meat = {"Meat", "Meats"},
        Souls = {"Souls", "Soul"},
        Sand = {"Sand", "Sands"},
        Stars = {"Stars", "Star"},
        SpacePoints = {"SpacePoints", "Space Points", "SpacePoint"},
        Blackholes = {"Blackholes", "Blackhole"},
        AlienCash = {"AlienCash", "Alien Cash"},
        Knowledge = {"Knowledge", "KnowledgePoints", "Knowledge Points"},
        Planets = {"Planets", "Planet"},
        Moon = {"Moon", "Moons"},
    }
    for _, alt in ipairs(alternates[resourceType] or {}) do
        direct = readCurrencyDirect(alt)
        if direct then return direct end
        val = getPlayerStat(alt)
        if val then return val end
    end
    return nil
end

-- Rate-limited with exponential backoff, affordability skip, and retry
tryBuyUpgrade = function(category, upgradeName, isMax)
    local key = category .. "_" .. upgradeName

    -- Skip maxed upgrades (TTL-based, expires for prestige resets)
    local maxedAt = UpgradeManager._maxed[key]
    if maxedAt and (tick() - maxedAt) < UpgradeManager._maxedTTL then return false end

    -- Skip if backed off (exponential backoff for unaffordable)
    if _isBackedOff(key) then return false end

    -- Per-upgrade rate limiting
    if not _canFireUpgrade(key) then return false end

    -- Cost scan with cache
    local cost = scanUpgradeCost(category, upgradeName)
    if not cost then
        -- Cost unknown: mark as maxed if cache says MAX, otherwise backoff
        local cached = _upgradeCostCache[key]
        if cached and cached.raw == "MAX" then
            UpgradeManager._maxed[key] = tick()
        else
            _applyBackoff(key)
        end
        return false
    end

    -- Balance check
    local resourceType = (category == "Noob") and "Oof" or category
    local balance = getResourceBalance(resourceType)

    -- Overflow handling: if both cost and balance overflowed (math.huge), player has
    -- infinite resources — fire the upgrade. Otherwise do normal comparison.
    if cost == math.huge then
        if balance ~= math.huge then
            _applyBackoff(key)
            return false
        end
        -- Both overflowed — player can afford, proceed to fire
    elseif not balance or balance < cost then
        _applyBackoff(key)
        return false
    end

    -- Afford it — clear backoff, fire
    _clearBackoff(key)

    if not _canFireGlobal() then return false end

    _markFired(key)
    local remoteName = isMax and "UpgradeUpgradeMax" or "UpgradeUpgrade"
    pcall(function()
        game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer(remoteName, category, upgradeName)
    end)
    return true
end

-- Scan costs for currently toggled upgrades only, return formatted status lines
-- Now derived from UPGRADES table + noob entries (no more duplicate checks table)
local function scanToggledUpgradeCosts()
    local lines = {}
    local now = tick()

    -- Process UPGRADES table entries (all non-noob upgrades)
    for _, e in ipairs(UPGRADES) do
        local flagName, cat, upgName = e[1], e[2], e[3]
        if S[flagName] and S[e[5]] then
            -- Skip if marked maxed (TTL-based, expires after 5 min for prestige)
            local key = cat .. "_" .. upgName
            local maxedAt = UpgradeManager._maxed[key]
            local skipMaxed = maxedAt and (tick() - maxedAt) < UpgradeManager._maxedTTL

            if not skipMaxed then
                -- Check WorldUI for MAX status
                local isMaxed = false
                local pgCheck = LP:FindFirstChild("PlayerGui")
                local wui = pgCheck and pgCheck:FindFirstChild("WorldUI")
                if wui then
                    local folder = wui:FindFirstChild("Upgrades.." .. cat)
                    if folder then
                        local main = folder:FindFirstChild("Main")
                        if main then
                            local entry = main:FindFirstChild(upgName)
                            if not entry then
                                local spaced = upgName:gsub("(%l)(%u)", "%1 %2")
                                if spaced ~= upgName then entry = main:FindFirstChild(spaced) end
                            end
                            if entry then
                                local costFrame = entry:FindFirstChild("Cost")
                                if costFrame then
                                    local amt = costFrame:FindFirstChild("Amount")
                                if amt and amt:IsA("TextLabel") and amt.Text == "MAX" then
                                    UpgradeManager._maxed[key] = tick()
                                    isMaxed = true
                                end
                            end
                        end
                    end
                end
            end

            if not isMaxed then
                local cost = scanUpgradeCost(cat, upgName)
                if cost then
                    local balance, rawBalance = getResourceBalance(cat)
                    -- For overflowed costs, try to show raw game text from cache
                    local needStr
                    if cost == math.huge then
                        local cachedCost = _upgradeCostCache[cat .. "_" .. upgName]
                        if cachedCost and cachedCost.raw and cachedCost.raw ~= "MAX" then
                            needStr = cleanRawNumber(cachedCost.raw)
                        else
                            needStr = "∞"
                        end
                    else
                        needStr = formatGameNum(cost)
                    end
                    local haveStr
                    if balance == math.huge and rawBalance then
                        haveStr = rawBalance  -- show raw game text like "1.5e315"
                    else
                        haveStr = balance and formatGameNum(balance) or "?"
                    end
                    local canBuy = (balance == math.huge) or (cost == math.huge and balance == math.huge) or (balance and cost and balance >= cost)
                    local prefix = canBuy and "[OK]" or "[WAIT]"
                    -- Show backoff indicator only if can't afford
                    if not canBuy and _isBackedOff(key) then prefix = "[⏳]" end
                    lines[#lines + 1] = string.format("%s %s > %s | Need: %s | Have: %s",
                        prefix, cat, upgName, needStr, haveStr)
                end
            end
            end  -- not skipMaxed
        end
    end

    -- Process Noob upgrades (separate since they use different remote)
    local noobChecks = {
        {"Pharaoh", S.autoNoobPharaoh}, {"Mummy", S.autoNoobMummy}, {"Merchant", S.autoNoobMerchant},
        {"Alien", S.autoNoobAlien}, {"Demon", S.autoNoobDemon}, {"Astronaut", S.autoNoobAstronaut},
    }
    for _, nc in ipairs(noobChecks) do
        if nc[2] then
            local cost = scanUpgradeCost("Noob", nc[1])
            local balance, rawBalance = getResourceBalance("Oof")
            local needStr
            if cost == math.huge then
                local cachedCost = _upgradeCostCache["Noob_" .. nc[1]]
                if cachedCost and cachedCost.raw and cachedCost.raw ~= "MAX" then
                    needStr = cleanRawNumber(cachedCost.raw)
                else
                    needStr = "∞"
                end
            else
                needStr = cost and formatGameNum(cost) or "?"
            end
            local haveStr
            if balance == math.huge and rawBalance then
                haveStr = rawBalance
            else
                haveStr = balance and formatGameNum(balance) or "?"
            end
            local canBuy = (balance == math.huge) or (cost and balance and balance >= cost)
            local prefix = canBuy and "[OK]" or "[WAIT]"
            lines[#lines + 1] = string.format("%s Noob > %s | Need: %s | Have: %s",
                prefix, nc[1], needStr, haveStr)
        end
    end

    return lines
end

-- Filtered version: only show upgrades for specific categories
local function scanUpgradeCostsFor(categories)
    local allLines = scanToggledUpgradeCosts()
    if not categories or #categories == 0 then return allLines end
    local filtered = {}
    local catSet = {}
    for _, cat in ipairs(categories) do catSet[cat] = true end
    for _, line in ipairs(allLines) do
        for cat in pairs(catSet) do
            if line:find(cat, 1, true) then
                filtered[#filtered + 1] = line
                break
            end
        end
    end
    return filtered
end

-- =============================================================================
-- TOGGLE UI FUNCTIONS
-- =============================================================================
local function openUI(name)
    local event = game:GetService("ReplicatedStorage").__Net.ToggleUI
    firesignal(event.OnClientEvent, "Open", name)
end

-- =============================================================================
-- RAYFIELD UI SETUP
-- =============================================================================
-- Helper: Rayfield dropdowns may return table {"val"} or string "val"
local function dv(v, default) return (type(v) == "table" and v[1]) or v or default end

local Rayfield
for attempt = 1, 3 do
    local ok, err = pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
    end)
    if ok and Rayfield then break end
    if attempt < 3 then task.wait(2) end
end
if not Rayfield then
    warn("[SQAYS] Rayfield failed to load → UI unavailable. Check your internet or executor.")
    return
end
local win = Rayfield:CreateWindow({
    Name = "Sqays Hub - "..gameName,
    LoadingTitle = "Made by Sqays & Exotic",
    LoadingSubtitle = "Credits to Sqays & Exotic | "..execName,
    ConfigurationSaving = { Enabled = true, FolderName = "SqaysHub", FileName = "Config" },
    KeySystem = false
})
env.SqaysRayfield = win

local StarsTab = win:CreateTab("⭐ Realm 4")
local RuneTab = win:CreateTab("🔮 Runes")
local CapsuleTab = win:CreateTab("🎁 Capsules")
local TrialTab = win:CreateTab("⚔️ Trials")
local Realm3Tab = win:CreateTab("🏜️ Realm 3")
local HackerTab = win:CreateTab("💻 Hacker")
local CombatTab = win:CreateTab("⚔️ Combat")
local Main = win:CreateTab("⛏️ Mining")
local EnchantTab = win:CreateTab("✨ Enchants")
local SetTab = win:CreateTab("⚙️ Settings")

-- =============================================================================
-- DYNAMIC UPGRADE UI BUILDER (must be defined before any tab uses it)
-- =============================================================================
local function buildDynamicUpgradeTab(tab, categoryName, detectedUpgrades, tabType)
    local sectionTitle = "" .. categoryName .. " Upgrades"

    -- Always show ALL upgrades in dropdown (don't remove MAXed ones)
    -- If upgrades reset via prestige/rebirth, they'll still be there to re-enable.
    -- MAX auto-untoggle in scanUpgradeCost handles turning off individual flags.
    -- The 5s status paragraph refresh shows which are currently maxed.
    local fullList = detectedUpgrades
    local available = fullList

    tab:CreateSection(sectionTitle)

    -- Status paragraph: shows which upgrades are currently maxed vs available
    local statusPara = tab:CreateParagraph({
        Title = "📊 " .. categoryName .. " Status",
        Content = "Loading..."
    })

    -- Store references for periodic refresh (both paragraph + dropdown flag + full list)
    if not S._dynUpgradeParas then S._dynUpgradeParas = {} end
    S._dynUpgradeParas[categoryName] = {
        para = statusPara,
        flag = "dyn_" .. categoryName .. "_list",
        fullList = fullList,
    }

    tab:CreateDropdown({
        Name = categoryName .. " Upgrade List",
        Options = available,
        CurrentOption = {},
        MultipleOptions = true,
        Flag = "dyn_" .. categoryName .. "_list",
        Callback = function(v)
            local selected = {}
            if type(v) == "table" then
                for _, sel in ipairs(v) do
                    if type(sel) == "string" then selected[sel] = true end
                end
            end
            for _, upg in ipairs(available) do
                local isSelected = selected[upg] == true
                S["upg_" .. categoryName .. "_" .. upg] = isSelected
                -- Sync individual S flags if Auto Buy is currently ON,
                -- so changing dropdown while toggle is ON takes effect immediately.
                if S[autoBuyKey] then
                    local sel = isSelected
                    if categoryName == "Sand" then
                        if upg == "StrongerShovels" then S.autoStrongerShovels = sel
                        elseif upg == "MoreSand" then S.autoMoreSand = sel
                        elseif upg == "AlotSand" then S.autoAlotSand = sel
                        elseif upg == "EvenMoreSand" then S.autoEvenMoreSand = sel
                        elseif upg == "MultiSand" then S.autoMultiSand = sel
                        elseif upg == "MoreOof" then S.autoSandMoreOof = sel
                        elseif upg == "FasterShovels" then S.autoFasterShovels = sel end
                    elseif categoryName == "Souls" then
                        if upg == "MoreSouls" then S.autoMoreSouls = sel
                        elseif upg == "MoreBones" then S.autoMoreBones = sel
                        elseif upg == "MoreOof" then S.autoMoreOof = sel
                        elseif upg == "LuckierSwords" then S.autoLuckierSwords = sel
                        elseif upg == "RuneBulk" then S.autoSoulsRuneBulk = sel end
                    elseif categoryName == "Bones" then
                        if upg == "HackerPointMulti" then S.autoBonesToHacker = sel
                        elseif upg == "FasterMeatConversion" then S.autoBonesFasterMeatConversion = sel
                        elseif upg == "More Oof" then S.autoBonesMoreOof = sel
                        elseif upg == "MoreBones" then S.autoBonesMoreBones_ = sel
                        elseif upg == "BiggerMeatDeposit" then S.autoBonesBiggerMeatDeposit = sel
                        elseif upg == "evenMoreBones" then S.autoBonesEvenMoreBones = sel
                        elseif upg == "FasterSwords" then S.autoBonesFasterSwords = sel end
                    elseif categoryName == "Meat" then
                        if upg == "MoreBones" then S.autoMeatToBones = sel
                        elseif upg == "StrongerSwords" then S.autoStrongerSwords = sel
                        elseif upg == "MoreMeat" then S.autoMoreMeat = sel
                        elseif upg == "MoreOof" then S.autoMeatMoreOof = sel end
                    elseif categoryName == "HackPoints" then
                        if upg == "EvenMoreHackPoints" then S.autoHackPoints = sel
                        elseif upg == "MoreRuneLuckkk" then S.autoRuneLuck = sel
                        elseif upg == "MoreRuneSpeed" then S.autoMoreRuneSpeed = sel
                        elseif upg == "MoreRuneLuck" then S.autoMoreRuneLuck = sel
                        elseif upg == "MoreHackPoints" then S.autoMoreHackPoints = sel
                        elseif upg == "ConnorBalancedItt" then S.autoConnorBalancedItt = sel
                        elseif upg == "AutoHackPointsCollector" then S.autoAutoHackPointsCollector = sel
                        elseif upg == "MoreRuneBulk" then S.autoMoreRuneBulk = sel end
                    elseif categoryName == "Stars" then
                        if upg == "EvenMoreStars" then S.autoStarEvenMoreStars = sel
                        elseif upg == "MoreStars" then S.autoStarMoreStars = sel
                        elseif upg == "MoreSpacePoints" then S.autoStarMoreSpacePoints = sel
                        elseif upg == "FasterRespawn" then S.autoStarFasterRespawn = sel
                        elseif upg == "Oof" then S.autoStarOof = sel
                        elseif upg == "BoostStarsMutationLuck" then S.autoStarBoostMutationLuck = sel end
                    elseif categoryName == "SpacePoints" then
                        if upg == "MultiStar" then S.autoSpMultiStar = sel
                        elseif upg == "MoreSpacePoints" then S.autoSpMoreSpacePoints = sel
                        elseif upg == "MoreMoon" then S.autoSpMoreMoon = sel
                        elseif upg == "Blackholes" then S.autoSpBlackholes = sel
                        elseif upg == "BoostStarsCollectRadius" then S.autoSpBoostCollectRadius = sel end
                    elseif categoryName == "Planets" then
                        if upg == "MorePlanets" then S.autoPlanetsMorePlanets = sel
                        elseif upg == "MoreStars" then S.autoPlanetsMoreStars = sel
                        elseif upg == "HeateThePlanet" then S.autoPlanetsHeatThePlanet = sel
                        elseif upg == "MorePoints" then S.autoPlanetsMorePoints = sel
                        elseif upg == "Oofs" then S.autoPlanetsOofs = sel
                        elseif upg == "Blackholes" then S.autoPlanetsBlackholes = sel end
                    elseif categoryName == "Moon" then
                        if upg == "MoreMoon" then S.autoMoonMoreMoon = sel
                        elseif upg == "BoostStars" then S.autoMoonBoostStars = sel
                        elseif upg == "MoreSpaceXP" then S.autoMoonMoreSpaceXP = sel
                        elseif upg == "MorePlanets" then S.autoMoonMorePlanets = sel
                        elseif upg == "EvenMoreStars" then S.autoMoonEvenMoreStars = sel end
                    elseif categoryName == "Blackholes" then
                        if upg == "MoreBlackholes" then S.autoBholeMoreBlackholes = sel
                        elseif upg == "Planet" then S.autoBholePlanet = sel
                        elseif upg == "FasterRespawn" then S.autoBholeFasterRespawn = sel
                        elseif upg == "Aliencash" then S.autoBholeAliencash = sel
                        elseif upg == "Oofs" then S.autoBholeOofs = sel end
                    elseif categoryName == "AlienCash" then
                        if upg == "MoreAlienCash" then S.autoAlienMoreCash = sel
                        elseif upg == "MoreAlienXP" then S.autoAlienMoreXP = sel
                        elseif upg == "BoostAlienMutationLuck" then S.autoAlienBoostMutation = sel
                        elseif upg == "VeryBadHoles" then S.autoAlienVeryBadHoles = sel end
                    elseif categoryName == "Knowledge" then
                        if upg == "MoreKnowledge" then S.autoKnowledgeMoreKnowledge = sel
                        elseif upg == "MoreAlienCash" then S.autoKnowledgeMoreAlienCash = sel
                        elseif upg == "BoostSpaceXP" then S.autoKnowledgeBoostSpaceXP = sel end
                    end
                end
            end
        end
    })

    local autoBuyKey = "autoBuy_" .. categoryName
    S[autoBuyKey] = false
    tab:CreateToggle({
        Name = "Auto Buy " .. categoryName,
        Flag = "autoBuy_" .. categoryName,
        CurrentValue = false,
        Callback = function(v)
            S[autoBuyKey] = v
            if v then
                -- Read current dropdown selections (user picks what to buy)
                -- Rayfield may return raw value or wrapped in object; handle both
                local raw = Rayfield.Flags["dyn_" .. categoryName .. "_list"]
                local opts = raw
                if type(raw) == "table" and raw.CurrentOption ~= nil then
                    opts = raw.CurrentOption
                end
                -- Normalize: single string → table for uniform handling
                if type(opts) == "string" then opts = {opts} end
                local selected = {}
                if type(opts) == "table" then
                    for _, sel in ipairs(opts) do
                        if type(sel) == "string" then selected[sel] = true end
                    end
                end
                for _, upg in ipairs(available) do
                    local sel = selected[upg] == true
                    S["upg_" .. categoryName .. "_" .. upg] = sel
                    -- Map to individual state flags
                    if categoryName == "Sand" then
                        if upg == "StrongerShovels" then S.autoStrongerShovels = sel
                        elseif upg == "MoreSand" then S.autoMoreSand = sel
                        elseif upg == "AlotSand" then S.autoAlotSand = sel
                        elseif upg == "EvenMoreSand" then S.autoEvenMoreSand = sel
                        elseif upg == "MultiSand" then S.autoMultiSand = sel
                        elseif upg == "MoreOof" then S.autoSandMoreOof = sel
                        elseif upg == "FasterShovels" then S.autoFasterShovels = sel end
                    elseif categoryName == "Souls" then
                        if upg == "MoreSouls" then S.autoMoreSouls = sel
                        elseif upg == "MoreBones" then S.autoMoreBones = sel
                        elseif upg == "MoreOof" then S.autoMoreOof = sel
                        elseif upg == "LuckierSwords" then S.autoLuckierSwords = sel
                        elseif upg == "RuneBulk" then S.autoSoulsRuneBulk = sel end
                    elseif categoryName == "Bones" then
                        if upg == "HackerPointMulti" then S.autoBonesToHacker = sel
                        elseif upg == "FasterMeatConversion" then S.autoBonesFasterMeatConversion = sel
                        elseif upg == "More Oof" then S.autoBonesMoreOof = sel
                        elseif upg == "MoreBones" then S.autoBonesMoreBones_ = sel
                        elseif upg == "BiggerMeatDeposit" then S.autoBonesBiggerMeatDeposit = sel
                        elseif upg == "evenMoreBones" then S.autoBonesEvenMoreBones = sel
                        elseif upg == "FasterSwords" then S.autoBonesFasterSwords = sel end
                    elseif categoryName == "Meat" then
                        if upg == "MoreBones" then S.autoMeatToBones = sel
                        elseif upg == "StrongerSwords" then S.autoStrongerSwords = sel
                        elseif upg == "MoreMeat" then S.autoMoreMeat = sel
                        elseif upg == "MoreOof" then S.autoMeatMoreOof = sel end
                    elseif categoryName == "HackPoints" then
                        if upg == "EvenMoreHackPoints" then S.autoHackPoints = sel
                        elseif upg == "MoreRuneLuckkk" then S.autoRuneLuck = sel
                        elseif upg == "MoreRuneSpeed" then S.autoMoreRuneSpeed = sel
                        elseif upg == "MoreRuneLuck" then S.autoMoreRuneLuck = sel
                        elseif upg == "MoreHackPoints" then S.autoMoreHackPoints = sel
                        elseif upg == "ConnorBalancedItt" then S.autoConnorBalancedItt = sel
                        elseif upg == "AutoHackPointsCollector" then S.autoAutoHackPointsCollector = sel
                        elseif upg == "MoreRuneBulk" then S.autoMoreRuneBulk = sel end
                    elseif categoryName == "Stars" then
                        if upg == "EvenMoreStars" then S.autoStarEvenMoreStars = sel
                        elseif upg == "MoreStars" then S.autoStarMoreStars = sel
                        elseif upg == "MoreSpacePoints" then S.autoStarMoreSpacePoints = sel
                        elseif upg == "FasterRespawn" then S.autoStarFasterRespawn = sel
                        elseif upg == "Oof" then S.autoStarOof = sel
                        elseif upg == "BoostStarsMutationLuck" then S.autoStarBoostMutationLuck = sel end
                    elseif categoryName == "SpacePoints" then
                        if upg == "MultiStar" then S.autoSpMultiStar = sel
                        elseif upg == "MoreSpacePoints" then S.autoSpMoreSpacePoints = sel
                        elseif upg == "MoreMoon" then S.autoSpMoreMoon = sel
                        elseif upg == "Blackholes" then S.autoSpBlackholes = sel
                        elseif upg == "BoostStarsCollectRadius" then S.autoSpBoostCollectRadius = sel end
                    elseif categoryName == "Planets" then
                        if upg == "MorePlanets" then S.autoPlanetsMorePlanets = sel
                        elseif upg == "MoreStars" then S.autoPlanetsMoreStars = sel
                        elseif upg == "HeateThePlanet" then S.autoPlanetsHeatThePlanet = sel
                        elseif upg == "MorePoints" then S.autoPlanetsMorePoints = sel
                        elseif upg == "Oofs" then S.autoPlanetsOofs = sel
                        elseif upg == "Blackholes" then S.autoPlanetsBlackholes = sel end
                    elseif categoryName == "Moon" then
                        if upg == "MoreMoon" then S.autoMoonMoreMoon = sel
                        elseif upg == "BoostStars" then S.autoMoonBoostStars = sel
                        elseif upg == "MoreSpaceXP" then S.autoMoonMoreSpaceXP = sel
                        elseif upg == "MorePlanets" then S.autoMoonMorePlanets = sel
                        elseif upg == "EvenMoreStars" then S.autoMoonEvenMoreStars = sel end
                    elseif categoryName == "Blackholes" then
                        if upg == "MoreBlackholes" then S.autoBholeMoreBlackholes = sel
                        elseif upg == "Planet" then S.autoBholePlanet = sel
                        elseif upg == "FasterRespawn" then S.autoBholeFasterRespawn = sel
                        elseif upg == "Aliencash" then S.autoBholeAliencash = sel
                        elseif upg == "Oofs" then S.autoBholeOofs = sel end
                    elseif categoryName == "AlienCash" then
                        if upg == "MoreAlienCash" then S.autoAlienMoreCash = sel
                        elseif upg == "MoreAlienXP" then S.autoAlienMoreXP = sel
                        elseif upg == "BoostAlienMutationLuck" then S.autoAlienBoostMutation = sel
                        elseif upg == "VeryBadHoles" then S.autoAlienVeryBadHoles = sel end
                    elseif categoryName == "Knowledge" then
                        if upg == "MoreKnowledge" then S.autoKnowledgeMoreKnowledge = sel
                        elseif upg == "MoreAlienCash" then S.autoKnowledgeMoreAlienCash = sel
                        elseif upg == "BoostSpaceXP" then S.autoKnowledgeBoostSpaceXP = sel end
                    end
                end
                startRealm3Loop()
            else
                -- Clear all flags when Auto Buy is turned OFF
                for _, upg in ipairs(available) do
                    S["upg_" .. categoryName .. "_" .. upg] = false
                end
                if categoryName == "Sand" then
                    S.autoStrongerShovels = false; S.autoMoreSand = false; S.autoAlotSand = false
                    S.autoEvenMoreSand = false; S.autoMultiSand = false; S.autoSandMoreOof = false; S.autoFasterShovels = false
                elseif categoryName == "Souls" then
                    S.autoMoreSouls = false; S.autoMoreBones = false; S.autoMoreOof = false
                    S.autoLuckierSwords = false; S.autoSoulsRuneBulk = false
                elseif categoryName == "Bones" then
                    S.autoBonesToHacker = false; S.autoBonesFasterMeatConversion = false
                    S.autoBonesMoreOof = false; S.autoBonesMoreBones_ = false
                    S.autoBonesBiggerMeatDeposit = false; S.autoBonesEvenMoreBones = false; S.autoBonesFasterSwords = false
                elseif categoryName == "Meat" then
                    S.autoMeatToBones = false; S.autoStrongerSwords = false; S.autoMoreMeat = false; S.autoMeatMoreOof = false
                elseif categoryName == "HackPoints" then
                    S.autoHackPoints = false; S.autoRuneLuck = false
                    S.autoMoreRuneSpeed = false; S.autoMoreRuneLuck = false; S.autoMoreHackPoints = false
                    S.autoConnorBalancedItt = false; S.autoAutoHackPointsCollector = false; S.autoMoreRuneBulk = false
                elseif categoryName == "Stars" then
                    S.autoStarEvenMoreStars = false; S.autoStarMoreStars = false; S.autoStarMoreSpacePoints = false
                    S.autoStarFasterRespawn = false
                    S.autoStarOof = false; S.autoStarBoostMutationLuck = false
                elseif categoryName == "SpacePoints" then
                    S.autoSpMultiStar = false; S.autoSpMoreSpacePoints = false
                    S.autoSpMoreMoon = false; S.autoSpBlackholes = false; S.autoSpBoostCollectRadius = false
                elseif categoryName == "Planets" then
                    S.autoPlanetsMorePlanets = false; S.autoPlanetsMoreStars = false
                    S.autoPlanetsHeatThePlanet = false; S.autoPlanetsMorePoints = false
                    S.autoPlanetsOofs = false; S.autoPlanetsBlackholes = false
                elseif categoryName == "Moon" then
                    S.autoMoonMoreMoon = false; S.autoMoonBoostStars = false
                    S.autoMoonMoreSpaceXP = false; S.autoMoonMorePlanets = false
                    S.autoMoonEvenMoreStars = false
                elseif categoryName == "Blackholes" then
                    S.autoBholeMoreBlackholes = false; S.autoBholePlanet = false
                    S.autoBholeFasterRespawn = false; S.autoBholeAliencash = false
                    S.autoBholeOofs = false
                elseif categoryName == "AlienCash" then
                    S.autoAlienMoreCash = false; S.autoAlienMoreXP = false
                    S.autoAlienBoostMutation = false; S.autoAlienVeryBadHoles = false
                elseif categoryName == "Knowledge" then
                    S.autoKnowledgeMoreKnowledge = false
                    S.autoKnowledgeMoreAlienCash = false
                    S.autoKnowledgeBoostSpaceXP = false
                end
                stopRealm3Loop()
            end
        end
    })
end

-- =============================================================================
-- DYNAMIC UPGRADE PARAGRAPH REFRESHER (every 60s, for post-prestige detection)
-- =============================================================================
local function refreshDynUpgradeParas()
    if not S._dynUpgradeParas then return end
    local pg = LP:FindFirstChild("PlayerGui")
    local worldUI = pg and pg:FindFirstChild("WorldUI")
    if not worldUI then return end

    for catName, data in pairs(S._dynUpgradeParas) do
        local para = data.para
        local flagName = data.flag
        local fullList = data.fullList or {}

        -- Determine which upgrades are currently maxed vs available
        local maxedSet, availList = {}, {}
        local folder = worldUI:FindFirstChild("Upgrades.." .. catName)
        if folder then
            local main = folder:FindFirstChild("Main")
            if main then
                for _, entry in ipairs(main:GetChildren()) do
                    local costFrame = entry:FindFirstChild("Cost")
                    if costFrame then
                        local amt = costFrame:FindFirstChild("Amount")
                        if amt and amt:IsA("TextLabel") then
                            if amt.Text == "MAX" then
                                maxedSet[entry.Name] = true
                            else
                                table.insert(availList, entry.Name .. " (" .. (amt.Text or "?") .. ")")
                            end
                        end
                    end
                end
            end
        end

        -- Build status content ONLY (never remove upgrades from dropdown)
        local content
        if #availList == 0 then
            content = "All maxed ?"
        else
            local maxedNames = {}
            for _, upg in ipairs(fullList) do
                if maxedSet[upg] then table.insert(maxedNames, upg) end
            end
            content = "Available: " .. table.concat(availList, ", ") .. "\nMaxed: " .. (#maxedNames > 0 and table.concat(maxedNames, ", ") or "none")
        end
        pcall(function() para:Set({Title = "📊 " .. catName .. " Status", Content = content}) end)
    end
end

-- Initial refresh after UI is built (deferred so tabs exist)
task.spawn(function()
    task.wait(2)
    if not env.NIStop then pcall(refreshDynUpgradeParas) end
    while not env.NIStop do
        task.wait(5)
        if not env.NIStop then pcall(refreshDynUpgradeParas) end
    end
end)

-- Stars Tab
StarsTab:CreateSection("Live Upgrade Status")
local starsUpgradeParagraph = StarsTab:CreateParagraph({
    Title = "📊 Upgrade Costs",
    Content = "Enable upgrade toggles below to track costs..."
})

StarsTab:CreateSection("🗺️ Upgrade Board Visits")
StarsTab:CreateToggle({
    Name = "Auto Visit Upgrade Boards",
    Flag = "realm4BoardVisit",
    CurrentValue = false,
    Callback = function(v)
        if v then startRealm4BoardLoop() else stopRealm4BoardLoop() end
    end
})
StarsTab:CreateSlider({
    Name = "Afford Multiplier (x)",
    Range = {1, 50},
    Increment = 1,
    CurrentValue = S.realm4BoardMultiplier,
    Flag = "realm4BoardMultiplier",
    Callback = function(v) S.realm4BoardMultiplier = v end
})

StarsTab:CreateSection("🌟 Realm 4 Noob Upgrades")
StarsTab:CreateDropdown({
    Name = "Realm 4 Noob List",
    Options = {"Alien", "Demon", "Astronaut"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "realm4NoobList",
    Callback = function(v)
        -- Only store selection; do NOT set S flags or start loop here.
        -- The Auto Buy toggle is the master switch.
    end
})
StarsTab:CreateToggle({
    Name = "Auto Buy Realm 4 Noob",
    Flag = "autoBuyNoobRealm4",
    CurrentValue = false,
    Callback = function(v)
        if v then
            -- Read dropdown, apply only what's selected
            S.autoNoobAlien = false
            S.autoNoobDemon = false
            S.autoNoobAstronaut = false
            local raw = Rayfield.Flags.realm4NoobList
            local opts = (type(raw) == "table" and raw.CurrentOption) or raw
            if type(opts) == "string" then opts = {opts} end
            if type(opts) == "table" then
                for _, sel in ipairs(opts) do
                    if type(sel) == "string" and sel == "Alien" then
                        S.autoNoobAlien = true
                    elseif type(sel) == "string" and sel == "Demon" then
                        S.autoNoobDemon = true
                    elseif type(sel) == "string" and sel == "Astronaut" then
                        S.autoNoobAstronaut = true
                    end
                end
            end
            startRealm3Loop()
        else
            -- Clear flags but KEEP dropdown selection
            S.autoNoobAlien = false
            S.autoNoobDemon = false
            S.autoNoobAstronaut = false
            stopRealm3Loop()
        end
    end
})
StarsTab:CreateSlider({Name="Tween to Noob Every (min)", Range={1,30}, Increment=1, CurrentValue=S.noobTweenMinutes, Flag="realm4NoobTweenMins", Callback=function(v)S.noobTweenMinutes=v end})

StarsTab:CreateSection("Star Collection")
StarsTab:CreateToggle({
    Name = "Enable Star Collection",
    Flag = "starCollectionEnabled",
    CurrentValue = false,
    Callback = function(v)
        S.starCollection.enabled = v
        if v then startStarLoop() else stopStarLoop() end
    end
})
StarsTab:CreateSlider({
    Name = "Tween Speed",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = S.starCollection.tweenSpeed,
    Flag = "starTweenSpeed",
    Callback = function(v) S.starCollection.tweenSpeed = v end
})
StarsTab:CreateSlider({
    Name = "Collect Delay (s)",
    Range = {0.1, 3},
    Increment = 0.1,
    CurrentValue = S.starCollection.delay,
    Flag = "starDelay",
    Callback = function(v) S.starCollection.delay = v end
})

StarsTab:CreateSection("🔬 Auto Research")
StarsTab:CreateToggle({
    Name = "Auto Start Research",
    Flag = "autoResearch",
    CurrentValue = false,
    Callback = function(v)
        S.autoResearch = v
        if v then startResearchLoop() else stopResearchLoop() end
    end
})
local researchStatusParagraph = StarsTab:CreateParagraph({
    Title = "🔬 Research Status",
    Content = "Toggle Auto Start Research to begin..."
})

-- Periodic refresh for research status paragraph (same method as upgrade status)
task.spawn(function()
    while not env.NIStop do
        task.wait(1)
        pcall(function()
            if researchStatusParagraph then
                researchStatusParagraph:Set({
                    Title = "🔬 Research Status",
                    Content = S._researchStatusText or "Waiting..."
                })
            end
        end)
    end
end)

StarsTab:CreateSection("🛸 UFO Upgrade")
StarsTab:CreateToggle({
    Name = "Auto Upgrade UFO (Max)",
    Flag = "autoUpgradeUFO",
    CurrentValue = false,
    Callback = function(v)
        S.autoUpgradeUFO = v
        if v then startUFOLoop() else stopUFOLoop() end
    end
})

buildDynamicUpgradeTab(StarsTab, "Stars", {"EvenMoreStars", "MoreStars", "MoreSpacePoints", "FasterRespawn", "Oof", "BoostStarsMutationLuck"}, "Realm3")
buildDynamicUpgradeTab(StarsTab, "SpacePoints", {"MultiStar", "MoreSpacePoints", "MoreMoon", "Blackholes", "BoostStarsCollectRadius"}, "Realm3")
buildDynamicUpgradeTab(StarsTab, "Planets", {"MorePlanets", "MoreStars", "HeateThePlanet", "MorePoints", "Oofs", "Blackholes"}, "Realm3")
buildDynamicUpgradeTab(StarsTab, "Moon", {"MoreMoon", "BoostStars", "MoreSpaceXP", "MorePlanets", "EvenMoreStars"}, "Realm3")
buildDynamicUpgradeTab(StarsTab, "Blackholes", {"MoreBlackholes", "Planet", "FasterRespawn", "Aliencash", "Oofs"}, "Realm3")
buildDynamicUpgradeTab(StarsTab, "AlienCash", {"MoreAlienCash", "MoreAlienXP", "BoostAlienMutationLuck", "VeryBadHoles"}, "Realm3")
buildDynamicUpgradeTab(StarsTab, "Knowledge", {"MoreKnowledge", "MoreAlienCash", "BoostSpaceXP"}, "Realm3")

StarsTab:CreateSection("Individual Planets")
local planetDropdownHandle = StarsTab:CreateDropdown({
    Name = "Planet Upgrade List",
    Options = {"Mercury", "Venus", "Earth", "Mars", "Jupiter", "Saturn", "Uranus", "Neptune"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "planetUpgradeList",
    Callback = function(v)
        -- Only store selection; the Auto Buy toggle is the master switch.
    end
})
S._planetDropdown = planetDropdownHandle  -- Save handle for direct .CurrentOption access
StarsTab:CreateToggle({
    Name = "Auto Upgrade Planets",
    Flag = "autoUpgradePlanets",
    CurrentValue = false,
    Callback = function(v)
        S.autoUpgradePlanets = v
        if v then
            startRealm3Loop()
        else
            stopRealm3Loop()
        end
    end
})

-- Capsule Tab
CapsuleTab:CreateSection("Capsule Selection")
CapsuleTab:CreateDropdown({
    Name = "Select Capsule Type",
    Options = {"Ancient", "Classic", "Football", "Super", "Cosmic"},
    CurrentOption = {"Ancient"},
    Flag = "selectedCapsule",
    Callback = function(v)
        S.selectedCapsule = dv(v, "Ancient")
    end
})
CapsuleTab:CreateToggle({Name="Auto Open Capsule", Flag="autoCapsule", Callback=function(v)S.autoOpenCapsule=v;if v then task.spawn(autoOpenCapsuleLoop) end end})
CapsuleTab:CreateSlider({Name="Open Interval (s)", Range={0.1,5}, Increment=0.1, CurrentValue=0.5, Flag="capsuleInterval", Callback=function(v)S.capsuleInterval=v end})
CapsuleTab:CreateButton({Name="Open Selected Capsule Now", Callback=function() fireOpenCapsule(S.selectedCapsule) end})
CapsuleTab:CreateSection("Hide Animations")
CapsuleTab:CreateToggle({Name="Hide Capsule Animation", Flag="hideCapsuleAnim", Callback=function(v)S.hideCapsuleAnim=v; if v or S.hideChestAnim then S.hideAnimations=true; S.protectGUIs=true; if not S.animMonitorRunning then startAnimationMonitor() end else if not S.hideChestAnim then S.hideAnimations=false; S.protectGUIs=false; stopAnimationMonitor() end end end})

-- Rune Tab
RuneTab:CreateSection("Rune Selection")
RuneTab:CreateDropdown({
    Name = "Select Rune",
    Options = {
        "-- Realm 1 --",
        "Basic", "Super", "Advanced", "Hacker", "Football",
        "-- Realm 2 --",
        "Deepcore", "Snowy",
        "-- Realm 3 --",
        "Dune", "Sunfire",
        "-- Prism --",
        "Cosmic Prism", "Sunstorm Prism",
    },
    CurrentOption = {"Basic"},
    Flag = "selectedRune",
    Callback = function(v)
        local sel = dv(v, "Basic")
        if not sel:find("^%-%-") then  -- ignore separator entries
            S.selectedRune = sel
        end
    end
})
RuneTab:CreateToggle({Name="Auto Sit At Rune", Flag="autoRune", Callback=function(v)S.autoRune=v;if v then task.spawn(autoRuneLoop) end end})

-- Mine Tab
Main:CreateSection("Ore Selection")
Main:CreateDropdown({
    Name = "Select Ores to Mine",
    Options = ORES,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "miningOres",
    Callback = function(v)
        for _, n in ipairs(ORES) do S["m"..n] = false end
        if type(v) == "table" then
            for _, sel in ipairs(v) do
                if type(sel) == "string" then S["m"..sel] = true end
            end
        end
    end
})
Main:CreateToggle({
    Name = "Enable Auto Mine",
    Flag = "autoMineToggle",
    CurrentValue = false,
    Callback = function(v)
        if v then
            if not isInMine() then
                Rayfield:Notify({Title="Sqays Hub", Content="Enter the Mine realm first!"})
                pcall(function() Rayfield.Flags.autoMineToggle:Set(false) end)
                return
            end
            local any = false
            for _, n in ipairs(ORES) do if S["m"..n] then any = true; break end end
            if not any then
                Rayfield:Notify({Title="Sqays Hub", Content="Select at least one ore first!"})
                pcall(function() Rayfield.Flags.autoMineToggle:Set(false) end)
                return
            end
            S.running = true
            task.spawn(loop)
        else
            S.running = false
        end
    end
})

-- Combat Tab
CombatTab:CreateSection("Mob Selection")
CombatTab:CreateDropdown({
    Name = "Select Mobs to Farm",
    Options = MOBS,
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "combatMobs",
    Callback = function(v)
        for _, n in ipairs(MOBS) do S["c"..n] = false end
        if type(v) == "table" then
            for _, sel in ipairs(v) do
                if type(sel) == "string" then S["c"..sel] = true end
            end
        end
    end
})
CombatTab:CreateToggle({
    Name = "Enable Auto Combat",
    Flag = "autoCombatToggle",
    CurrentValue = false,
    Callback = function(v)
        if v then
            local any = false
            for _, n in ipairs(MOBS) do if S["c"..n] then any = true; break end end
            if not any then
                Rayfield:Notify({Title="Combat", Content="Select at least one mob first!"})
                pcall(function() Rayfield.Flags.autoCombatToggle:Set(false) end)
                return
            end
            S.combatRunning = true
            task.spawn(combatLoop)
        else
            S.combatRunning = false
        end
    end
})
CombatTab:CreateButton({Name="🔴 Toggle All Mobs OFF", Callback=function()
    for _, n in ipairs(MOBS) do S["c"..n] = false end
    S.combatRunning = false
    pcall(function()
        local flag = Rayfield.Flags.combatMobs
        if flag then
            if flag.Set then flag:Set({})
            elseif flag.Refresh then flag:Refresh({}) end
        end
    end)
    pcall(function()
        local flag = Rayfield.Flags.autoCombatToggle
        if flag and flag.Set then flag:Set(false) end
    end)
    Rayfield:Notify({Title="Combat", Content="All mobs toggled OFF!"})
end})
CombatTab:CreateButton({Name="⚔️ Ritual Farm (Dark Knight / Commander / Samurai Master)", Callback=function()
    local ritualMobs = {"Dark Knight","Dark Commander","Samurai Master"}
    for _, n in ipairs(MOBS) do S["c"..n] = false end
    for _, n in ipairs(ritualMobs) do S["c"..n] = true end
    pcall(function()
        local flag = Rayfield.Flags.combatMobs
        if flag then
            if flag.Set then flag:Set(ritualMobs)
            elseif flag.Refresh then flag:Refresh(ritualMobs) end
        end
    end)
    pcall(function()
        local flag = Rayfield.Flags.autoCombatToggle
        if flag and flag.Set then flag:Set(true) end
    end)
    S.combatRunning = true; task.spawn(combatLoop)
    Rayfield:Notify({Title="Combat", Content="Ritual farm mobs enabled!"})
end})
CombatTab:CreateSection("Combat Speed")
CombatTab:CreateSlider({Name="Glide Speed (s)", Range={0.01, 2}, Increment=0.01, CurrentValue=S.combatTweenSpeed, Flag="combatSpeed", Callback=function(v)S.combatTweenSpeed=v end})
CombatTab:CreateSection("Ancient Boss")
CombatTab:CreateToggle({Name="Auto Farm Ancient Boss", Flag="abossFarm", Callback=function(v)S.abossRunning=v;if v then task.spawn(ancientBossLoop) end end})
CombatTab:CreateParagraph({Title="👹 Boss Status", Content="Status: "..(S.abossStatus or "Idle")})
CombatTab:CreateSection("Ritual")
CombatTab:CreateToggle({Name="Auto Start Ritual", Flag="autoRitual", Callback=function(v)S.ritualRunning=v;if v then task.spawn(ritualLoop) end end})
CombatTab:CreateSlider({Name="Wait after ritual (s)", Range={10,300}, Increment=5, CurrentValue=S.ritualCooldown, Flag="ritualCooldown", Callback=function(v)S.ritualCooldown=v end})

-- =========================================================================
-- REALM 3 TAB
-- =========================================================================
Realm3Tab:CreateSection("Live Upgrade Status")
local realm3UpgradeParagraph = Realm3Tab:CreateParagraph({Title = "📊 Upgrade Costs", Content = "Enable toggles below to track..."})

Realm3Tab:CreateSection("Noob Upgrades")
Realm3Tab:CreateDropdown({
    Name = "Noob Upgrade List",
    Options = {"Pharaoh", "Mummy", "Merchant"},
    CurrentOption = {},
    MultipleOptions = true,
    Flag = "noobUpgradeList",
    Callback = function(v)
        -- Only store selection; do NOT set S flags or start loop here.
        -- The Auto Buy toggle is the master switch.
    end
})
Realm3Tab:CreateToggle({
    Name = "Auto Buy Noob",
    Flag = "autoBuyNoob",
    CurrentValue = false,
    Callback = function(v)
        if v then
            -- Read dropdown, apply only what's selected
            S.autoNoobPharaoh = false; S.autoNoobMummy = false; S.autoNoobMerchant = false
            local raw = Rayfield.Flags.noobUpgradeList
            local opts = (type(raw) == "table" and raw.CurrentOption) or raw
            if type(opts) == "string" then opts = {opts} end
            if type(opts) == "table" then
                for _, sel in ipairs(opts) do
                    if type(sel) == "string" then
                        if sel == "Pharaoh" then S.autoNoobPharaoh = true
                        elseif sel == "Mummy" then S.autoNoobMummy = true
                        elseif sel == "Merchant" then S.autoNoobMerchant = true end
                    end
                end
            end
            startRealm3Loop()
        else
            -- Clear flags but KEEP dropdown selection
            S.autoNoobPharaoh = false; S.autoNoobMummy = false; S.autoNoobMerchant = false
            stopRealm3Loop()
        end
    end
})
Realm3Tab:CreateSlider({Name="Tween to Noob Every (min)", Range={1,30}, Increment=1, CurrentValue=S.noobTweenMinutes, Flag="noobTweenMins", Callback=function(v)S.noobTweenMinutes=v end})

buildDynamicUpgradeTab(Realm3Tab, "Sand", {"StrongerShovels", "MoreSand", "AlotSand", "EvenMoreSand", "MultiSand", "MoreOof", "FasterShovels"}, "Realm3")
buildDynamicUpgradeTab(Realm3Tab, "Souls", {"MoreSouls", "MoreBones", "MoreOof", "LuckierSwords", "RuneBulk"}, "Realm3")
buildDynamicUpgradeTab(Realm3Tab, "Bones", {"HackerPointMulti", "FasterMeatConversion", "More Oof", "MoreBones", "BiggerMeatDeposit", "evenMoreBones", "FasterSwords"}, "Realm3")
buildDynamicUpgradeTab(Realm3Tab, "Meat", {"MoreBones", "StrongerSwords", "MoreMeat", "MoreOof"}, "Realm3")

Realm3Tab:CreateSection("Auto Deposit Meat")
Realm3Tab:CreateToggle({Name="Auto Deposit Meat", Flag="autoDepositMeat", Callback=function(v)S.autoDepositMeat=v;if v then task.spawn(autoDepositMeatLoop) end end})
Realm3Tab:CreateSlider({Name="Deposit Every (hours)", Range={1,24}, Increment=1, CurrentValue=S.depositMeatHours, Flag="depositHours", Callback=function(v)S.depositMeatHours=v end})
Realm3Tab:CreateSlider({Name="Deposit at % full (0=off)", Range={0,100}, Increment=5, CurrentValue=S.depositMeatPercent, Flag="depositPercent", Callback=function(v)S.depositMeatPercent=v end})
Realm3Tab:CreateSection("Auto Back to Surface")
Realm3Tab:CreateToggle({Name="Auto Back to Surface", Flag="backToSurface", Callback=function(v)S.autoBackToSurface=v;if v then task.spawn(autoBackToSurfaceLoop) end end})
Realm3Tab:CreateSlider({Name="Back at Layer", Range={1,500}, Increment=1, CurrentValue=S.backToSurfaceLayer, Flag="backToSurfaceLayer", Callback=function(v)S.backToSurfaceLayer=v end})
Realm3Tab:CreateSection("Auto Shovel Level Up")
Realm3Tab:CreateToggle({Name="Auto Level Up Shovel", Flag="levelUpShovel", Callback=function(v)S.autoLevelUpShovel=v;if v then startRealm3Loop() else stopRealm3Loop() end end})
Realm3Tab:CreateSlider({Name="Interval (s)", Range={1,30}, Increment=1, CurrentValue=S.shovelLevelUpInterval, Flag="shovelInterval", Callback=function(v)S.shovelLevelUpInterval=v end})
Realm3Tab:CreateSection("Trial Chests")
Realm3Tab:CreateToggle({
    Name = "Auto Open Trial Chests (T2 → T1)", CurrentValue = false, Flag = "autoTrialChests",
    Callback = function(v) S.autoTrialChests = v; if v and not _chestLoopRunning then _chestLoopRunning = true; task.spawn(chestLoop) end end
})
Realm3Tab:CreateToggle({Name="Hide Chest Animation", Flag="hideChestAnim", Callback=function(v)S.hideChestAnim=v; if v or S.hideCapsuleAnim then S.hideAnimations=true; S.protectGUIs=true; if not S.animMonitorRunning then startAnimationMonitor() end else if not S.hideCapsuleAnim then S.hideAnimations=false; S.protectGUIs=false; stopAnimationMonitor() end end end})

-- =========================================================================
-- ENCHANT TAB
-- =========================================================================
EnchantTab:CreateSection("Auto Roll")
for _, noob in ipairs(Noobs) do
    local eNoob = noob
    EnchantTab:CreateToggle({
        Name = "Auto Roll " .. eNoob,
        Flag = "roll_"..eNoob,
        CurrentValue = false,
        Callback = function(v)
            S.autoRoll[eNoob] = v
            if v then startRollLoop(eNoob) end
        end
    })
end
EnchantTab:CreateSection("Speed Settings")
EnchantTab:CreateSlider({
    Name = "Roll Interval (s)",
    Range = {0.01, 1},
    Increment = 0.01,
    CurrentValue = S.enchantInterval,
    Flag = "enchantInterval",
    Callback = function(v) S.enchantInterval = v end
})
EnchantTab:CreateSection("Skip Almighty")
for _, noob in ipairs(Noobs) do
    local sNoob = noob
    EnchantTab:CreateToggle({
        Name = "Skip Almighty " .. sNoob,
        Flag = "skip_"..sNoob,
        CurrentValue = false,
        Callback = function(v)
            S.skipAlmighty[sNoob] = v
            setupWarningHandler()
        end
    })
end

-- =========================================================================
-- COMBINED TRIALS TAB ? Single difficulty selector controls everything below
-- =========================================================================
TrialTab:CreateSection("Live Countdown")
local trialCountdownParagraph = TrialTab:CreateParagraph({Title = "⏱️ Trial Countdown", Content = "Select a difficulty and enable Auto-Join..."})

-- Background thread: updates the countdown paragraph every second + sends notifications
local _trialNotifyLast = {}
task.spawn(function()
    while not env.NIStop do
        pcall(function()
            local diff = (type(S.selectedTrialDiff) == "table" and S.selectedTrialDiff[1]) or S.selectedTrialDiff or "Hard"
            local lbl = getCountdownLabel(diff)
            if lbl and lbl:IsA("TextLabel") then
                local sec = parseCountdown(lbl.Text)
                if sec > 0 then
                    local min = math.floor(sec / 60)
                    local s = sec % 60
                    local emoji = sec <= 10 and "🔴" or sec <= 30 and "🟡" or "🟢"
                    pcall(function()
                        trialCountdownParagraph:Set({Title = "⏱️ " .. diff .. " Trial",
                            Content = emoji .. " Opens in " .. min .. "m " .. string.format("%02d", s) .. "s"})
                    end)
                    -- Notify at key milestones (once per countdown cycle)
                    if sec <= 10 and sec ~= _trialNotifyLast[diff] and sec > 0 then
                        Rayfield:Notify({Title = "⏱️ " .. diff .. " Trial", Content = "Opens in " .. sec .. " seconds!"})
                        _trialNotifyLast[diff] = sec
                    elseif sec > 10 then
                        _trialNotifyLast[diff] = 999
                    end
                else
                    pcall(function()
                        trialCountdownParagraph:Set({Title = "⏱️ " .. diff .. " Trial",
                            Content = "⏳ Waiting for countdown..."})
                    end)
                end
            else
                pcall(function()
                    trialCountdownParagraph:Set({Title = "⏱️ " .. diff .. " Trial",
                        Content = "🚫 Portal not active"})
                end)
            end
        end)
        task.wait(1)
    end
end)

TrialTab:CreateSection("Select Difficulty")
TrialTab:CreateDropdown({
    Name = "Trial Difficulty",
    Options = {"Hard", "Medium", "Easy"},
    CurrentOption = {"Hard"},
    Flag = "trialDifficulty",
    Callback = function(v)
        S.selectedTrialDiff = (type(v) == "table" and v[1]) or v or "Hard"
        -- Restart countdown monitor for newly selected difficulty
        for _, d in ipairs({"Hard","Medium","Easy"}) do
            if d == S.selectedTrialDiff then
                local st = TrialState[d]
                if st.autoJoin then
                    S["trialMonitor_" .. d] = true
                end
            else
                S["trialMonitor_" .. d] = false
            end
        end
    end
})

-- Helper to get current difficulty safely as a string
local function getSelectedDiff()
    local v = S.selectedTrialDiff or "Hard"
    return (type(v) == "table" and v[1]) or v or "Hard"
end

-- Live countdown (reads from selected difficulty)
TrialTab:CreateButton({
    Name = "Refresh Countdown",
    Callback = function()
        local diff = getSelectedDiff()
        local lbl = getCountdownLabel(diff)
        if lbl then
            local sec = parseCountdown(lbl.Text)
            local min = math.floor(sec / 60)
            local s = sec % 60
            Rayfield:Notify({Title = "⏱️ "..diff, Content = "Opens in "..min.."m "..s.."s"})
        else
            Rayfield:Notify({Title = "⏱️ "..diff, Content = "Countdown label not found"})
        end
    end
})

-- Auto-Join toggle (applies to selected difficulty)
TrialTab:CreateToggle({
    Name = "Enable Auto-Join Trial",
    Flag = "autoJoinCombined",
    CurrentValue = false,
    Callback = function(v)
        local diff = getSelectedDiff()
        local st = TrialState[diff]
        if not st then return end
        st.autoJoin = v
        if v then
            S["trialMonitor_" .. diff] = true
        else
            S["trialMonitor_" .. diff] = false
        end
    end
})

-- Test button
TrialTab:CreateButton({
    Name = "Force Join Selected Trial Now",
    Callback = function()
        local diff = getSelectedDiff()
        local lbl = getCountdownLabel(diff)
        if lbl then
            local sec = parseCountdown(lbl.Text)
            if sec <= 7 and sec > 0 then
                local st = TrialState[diff]
                if st then
                    st.autoJoin = true; st.teleported = false
                    S["trialMonitor_" .. diff] = true
                end
                Rayfield:Notify({Title = "🔥 "..diff, Content = "Force-joining at "..sec.."s countdown!"})
            else
                Rayfield:Notify({Title = "⏱️ "..diff, Content = "Countdown is "..sec.."s → needs ≤7s to join"})
            end
        else
            Rayfield:Notify({Title = "❓", Content = "Trial portal not active"})
        end
    end
})

-- Auto Leave
TrialTab:CreateToggle({
    Name = "Auto Leave Trial",
    Flag = "autoLeaveCombined",
    CurrentValue = false,
    Callback = function(v)
        local diff = getSelectedDiff()
        local st = TrialState[diff]
        if st then st.autoLeave = v end
    end
})
TrialTab:CreateSlider({
    Name = "Leave After Wave",
    Range = {1, 100},
    Increment = 1,
    CurrentValue = 5,
    Flag = "leaveWaveCombined",
    Callback = function(v)
        local diff = getSelectedDiff()
        local st = TrialState[diff]
        if st then st.leaveWave = v end
    end
})

-- Capture / Return
TrialTab:CreateButton({
    Name = "Capture Return Point",
    Callback = function()
        local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local diff = getSelectedDiff()
            local st = TrialState[diff]
            if st then
                st.capturedPos = hrp.Position
                Rayfield:Notify({Title = "Capture", Content = "Position saved for "..diff.."!"})
            end
        end
    end
})
TrialTab:CreateToggle({
    Name = "Auto Return After Leave",
    Flag = "autoReturnCombined",
    CurrentValue = true,
    Callback = function(v)
        local diff = getSelectedDiff()
        local st = TrialState[diff]
        if st then st.autoReturn = v end
    end
})

-- Nearest Mob Farm
TrialTab:CreateToggle({
    Name = "Nearest Mob Farm",
    Flag = "nearestMobCombined",
    CurrentValue = false,
    Callback = function(v)
        local diff = getSelectedDiff()
        local st = TrialState[diff]
        if not st then return end
        st.nearestMobFarm = v
        if v then startNearestMobFarm(diff) else stopNearestMobFarm(diff) end
    end
})
TrialTab:CreateSlider({
    Name = "Nearest Mob Speed (s)",
    Range = {0.1, 2},
    Increment = 0.1,
    CurrentValue = S.nearestSpeed,
    Flag = "nearestSpeed",
    Callback = function(v) S.nearestSpeed = v end
})
-- =============================================================================
-- CPU/GPU OPTIMIZATION
-- =============================================================================
-- Dual-layer FPS management: event-based (instant) + polling backup
-- Also kills particles/trails/beams/effects, lowers rendering quality, throttles physics
local _optApplied = false
local _optCache = {particles={}, trails={}, beams={}, effects={}}
local _focusEventConn = nil   -- Event-based listener (fast, immediate response)
local _focusPollThread = nil  -- Polling backup thread (ensures it always works)
local _lastFocusFps = nil     -- Tracks last applied FPS to avoid redundant re-sets

-- Sets FPS using every available method across all executors (Solara, Delta, Synapse, Wave, Codex, etc.)
local function setFpsCap(fps)
    if _optApplied and _lastFocusFps == fps then return end  -- Skip redundant calls
    _lastFocusFps = fps
    S.fpsCap = fps
    -- Method 1: setfpscap (Synapse, Script-Ware, older executors)
    pcall(function()
        if setfpscap then setfpscap(fps) end
    end)
    -- Method 2: set_fps_cap (some custom executors)
    pcall(function()
        if set_fps_cap then set_fps_cap(fps) end
    end)
    -- Method 3: Roblox Rendering settings (works on most modern executors)
    pcall(function()
        local s = settings()
        if s and s.Rendering then
            s.Rendering.FrameRateManager = false
            pcall(function() s.Rendering.FrameRateLimit = fps end)
        end
    end)
end

-- Stop both layers of the focus monitor
local function stopFocusMonitor()
    if _focusEventConn then
        pcall(function() _focusEventConn:Disconnect() end)
        _focusEventConn = nil
    end
    _focusPollThread = nil  -- Thread will die on next loop iteration
    _lastFocusFps = nil
end

-- Start the dual-layer focus monitor: event (instant) + polling (backup every 2s)
local function startFocusMonitor()
    stopFocusMonitor()
    _lastFocusFps = nil  -- Reset so first poll always applies

    -- Layer 1: Event-based ? responds instantly when window focus changes
    pcall(function()
        local UIS = game:GetService("UserInputService")
        _focusEventConn = UIS.WindowFocused:Connect(function(focused)
            if not _optApplied then return end
            if focused then setFpsCap(60) else setFpsCap(30) end
        end)
    end)

    -- Layer 2: Polling backup ? checks every 2 seconds to catch missed events
    _focusPollThread = task.spawn(function()
        while _optApplied and not env.NIStop do
            pcall(function()
                local UIS = game:GetService("UserInputService")
                if UIS.WindowFocused then
                    setFpsCap(60)
                else
                    setFpsCap(30)
                end
            end)
            task.wait(2)
        end
        _focusPollThread = nil
    end)
end

local function applyOptimizations()
    if _optApplied then
        Rayfield:Notify({Title="⚡ Optimization", Content="Already applied!"})
        return
    end
    _optApplied = true

    -- 1. FPS: 60 normally, auto 30 when tabbed (dual-layer: event + polling)
    setFpsCap(60)
    startFocusMonitor()

    -- 2. Rendering quality
    pcall(function()
        local s = settings().Rendering
        s.QualityLevel = 1
        s.MeshPartDetailLevel = Enum.MeshPartDetailLevel.Level01
    end)

    -- 3. Lighting ? keep bright, kill post-effects
    pcall(function()
        local L = game:GetService("Lighting")
        L.GlobalShadows = false
        L.Brightness = 2
        L.FogEnd = 1e9
        L.Technology = Enum.Technology.Compatibility
        L.Outlines = false
        for _, v in ipairs(L:GetChildren()) do
            if v:IsA("Bloom") or v:IsA("Blur") or v:IsA("SunRays") or v:IsA("ColorCorrection") or v:IsA("DepthOfField") then
                table.insert(_optCache.effects, {obj=v, enabled=v.Enabled})
                v.Enabled = false
            end
        end
    end)

    -- 4. Terrain ? kill decorations & water effects
    pcall(function() workspace.Terrain.Decoration = false end)
    pcall(function() workspace.Terrain.WaterReflectance = 0 end)
    pcall(function() workspace.Terrain.WaterTransparency = 1 end)
    pcall(function() workspace.Terrain.WaterWaveSize = 0 end)
    pcall(function() workspace.Terrain.WaterWaveSpeed = 0 end)
    pcall(function() workspace.Terrain.GrassLength = 0 end)

    -- 5. Physics throttle
    pcall(function()
        settings().Physics.PhysicsEnvironmentalThrottle = Enum.EnviromentalPhysicsThrottle.Disabled
        settings().Physics.AllowSleep = true
    end)

    -- 6. Kill particles/trails/beams/fire ONLY (fast scan, no material/texture/sound stripping)
    local count = 0
    pcall(function()
        for _, v in ipairs(workspace:GetDescendants()) do
            count = count + 1
            if count % 500 == 0 then task.wait() end

            if v:IsA("ParticleEmitter") then
                table.insert(_optCache.particles, {obj=v, enabled=v.Enabled})
                v.Enabled = false
            elseif v:IsA("Trail") then
                table.insert(_optCache.trails, {obj=v, enabled=v.Enabled})
                v.Enabled = false
            elseif v:IsA("Beam") then
                table.insert(_optCache.beams, {obj=v, enabled=v.Enabled})
                v.Enabled = false
            elseif v:IsA("Fire") or v:IsA("Smoke") or v:IsA("Sparkles") then
                v.Enabled = false
            end
        end
    end)

    Rayfield:Notify({Title="⚡ Optimization", Content="Applied! 60 FPS (30 when tabbed), "..count.." scanned."})
end

local function revertOptimizations()
    if not _optApplied then
        Rayfield:Notify({Title="⚡ Optimization", Content="Nothing to revert."})
        return
    end
    _optApplied = false
    stopFocusMonitor()
    _lastFocusFps = nil
    setFpsCap(60)

    pcall(function()
        for _, e in ipairs(_optCache.particles) do pcall(function() e.obj.Enabled = e.enabled end) end
        for _, e in ipairs(_optCache.trails)   do pcall(function() e.obj.Enabled = e.enabled end) end
        for _, e in ipairs(_optCache.beams)    do pcall(function() e.obj.Enabled = e.enabled end) end
        for _, e in ipairs(_optCache.effects)  do pcall(function() e.obj.Enabled = e.enabled end) end
    end)
    _optCache = {particles={}, trails={}, beams={}, effects={}}

    Rayfield:Notify({Title="⚡ Optimization", Content="Reverted."})
end

-- =========================================================================
-- SETTINGS TAB
-- =========================================================================
SetTab:CreateSection("Live Upgrade Status")
local upgradeStatusParagraph = SetTab:CreateParagraph({Title = "📊 Upgrade Costs", Content = "Enable upgrade toggles on other tabs to track..."})

-- Background auto-scanner: updates upgrade costs on all realm tabs
task.spawn(function()
    while not env.NIStop do
        task.wait(15)
        local anyActive = S.autoStrongerShovels or S.autoMoreSand or S.autoAlotSand
            or S.autoEvenMoreSand or S.autoMultiSand or S.autoSandMoreOof or S.autoFasterShovels
            or S.autoMoreSouls or S.autoMoreBones or S.autoMoreOof
            or S.autoLuckierSwords or S.autoSoulsRuneBulk
            or S.autoMeatToBones or S.autoBonesToHacker
            or S.autoStrongerSwords or S.autoMoreMeat or S.autoMeatMoreOof
            or S.autoBonesFasterMeatConversion or S.autoBonesMoreOof or S.autoBonesMoreBones_
            or S.autoBonesBiggerMeatDeposit or S.autoBonesEvenMoreBones or S.autoBonesFasterSwords
            or S.autoHackPoints or S.autoRuneLuck
            or S.autoMoreRuneSpeed or S.autoMoreRuneLuck or S.autoMoreHackPoints
            or S.autoConnorBalancedItt or S.autoAutoHackPointsCollector or S.autoMoreRuneBulk
            or S.autoNoobPharaoh or S.autoNoobMummy or S.autoNoobMerchant or S.autoNoobAlien or S.autoNoobDemon or S.autoNoobAstronaut
            or S.autoStarEvenMoreStars or S.autoStarMoreStars or S.autoStarMoreSpacePoints or S.autoStarFasterRespawn or S.autoStarOof or S.autoStarBoostMutationLuck
            or S.autoSpMultiStar or S.autoSpMoreSpacePoints or S.autoSpMoreMoon or S.autoSpBlackholes or S.autoSpBoostCollectRadius
            or S.autoPlanetsMorePlanets or S.autoPlanetsMoreStars or S.autoPlanetsHeatThePlanet
            or S.autoPlanetsMorePoints or S.autoPlanetsOofs or S.autoPlanetsBlackholes
            or S.autoUpgradePlanets
            or S.autoMoonMoreMoon or S.autoMoonBoostStars or S.autoMoonMoreSpaceXP or S.autoMoonMorePlanets or S.autoMoonEvenMoreStars
            or S.autoBholeMoreBlackholes or S.autoBholePlanet or S.autoBholeFasterRespawn or S.autoBholeAliencash or S.autoBholeOofs
            or S.autoAlienMoreCash or S.autoAlienMoreXP or S.autoAlienBoostMutation or S.autoAlienVeryBadHoles
            or S.autoKnowledgeMoreKnowledge or S.autoKnowledgeMoreAlienCash or S.autoKnowledgeBoostSpaceXP
            or S.autoHackPoints or S.autoRuneLuck or S.autoMoreRuneSpeed or S.autoMoreRuneLuck
            or S.autoMoreHackPoints or S.autoConnorBalancedItt or S.autoAutoHackPointsCollector or S.autoMoreRuneBulk
        if anyActive then
            -- Auto-recovery: restart loop if it died but toggles still on
            if not UpgradeManager._loopRunning then startRealm3Loop() end
            pcall(function()
                local allLines = scanToggledUpgradeCosts()
                local defaultContent = "No toggled upgrades to track"
                local allContent = (allLines and #allLines > 0) and table.concat(allLines, "\n") or defaultContent

                -- Settings tab: show everything
                if upgradeStatusParagraph then
                    pcall(function() upgradeStatusParagraph:Set({Title = "📊 Upgrade Costs", Content = allContent}) end)
                end
                -- Stars tab: Stars + SpacePoints + Blackholes + Planets
                if starsUpgradeParagraph then
                    local filtered = scanUpgradeCostsFor({"Stars", "SpacePoints", "Blackholes", "AlienCash", "Knowledge", "Noob"})
                    -- Add planet upgrade status (uses UpgradePlanetMax, not the UPGRADES table)
                    if S.autoUpgradePlanets then
                        local planets = {}
                        local raw = S._planetDropdown and S._planetDropdown.CurrentOption
                        if not raw and Rayfield and Rayfield.Flags then
                            raw = Rayfield.Flags.planetUpgradeList
                            if type(raw) == "table" and raw.CurrentOption then raw = raw.CurrentOption end
                        end
                        if type(raw) == "table" then planets = raw
                        elseif type(raw) == "string" then planets = {raw} end
                        if #planets > 0 then
                            filtered[#filtered + 1] = "[OK] Planets > " .. table.concat(planets, ", ")
                        else
                            filtered[#filtered + 1] = "[WAIT] Planets > no planets selected"
                        end
                    end
                    local content = (#filtered > 0) and table.concat(filtered, "\n") or "No Stars/SpacePoints upgrades toggled"
                    pcall(function() starsUpgradeParagraph:Set({Title = "📊 Upgrade Costs", Content = content}) end)
                end
                -- Realm3 tab: Sand, Souls, Bones, Meat, HackPoints, Noob
                if realm3UpgradeParagraph then
                    local filtered = scanUpgradeCostsFor({"Sand", "Souls", "Bones", "Meat", "HackPoints", "Noob"})
                    local content = (#filtered > 0) and table.concat(filtered, "\n") or "No upgrades toggled"
                    pcall(function() realm3UpgradeParagraph:Set({Title = "📊 Upgrade Costs", Content = content}) end)
                end
            end)
        else
            -- Nothing toggled ? clear all status paragraphs
            local emptyMsg = "No toggled upgrades to track"
            if upgradeStatusParagraph then
                pcall(function() upgradeStatusParagraph:Set({Title = "📊 Upgrade Costs", Content = emptyMsg}) end)
            end
            if starsUpgradeParagraph then
                pcall(function() starsUpgradeParagraph:Set({Title = "📊 Upgrade Costs", Content = emptyMsg}) end)
            end
            if realm3UpgradeParagraph then
                pcall(function() realm3UpgradeParagraph:Set({Title = "📊 Upgrade Costs", Content = emptyMsg}) end)
            end
        end
    end
end)

SetTab:CreateSection("System Status")
local systemStatusParagraph = SetTab:CreateParagraph({
    Title = "📊 System Status",
    Content = "Mining: OFF | Combat: OFF | Stars: OFF | Realm3: OFF"
})

-- Status updater
task.spawn(function()
    while not env.NIStop do
        task.wait(3)
        pcall(function()
            if systemStatusParagraph then
                systemStatusParagraph:Set({
                    Title = "📊 System Status",
                    Content = string.format("Mining: %s | Combat: %s | Stars: %s | Realm3: %s | Trials: %s",
                        S.running and "ON" or "OFF",
                        S.combatRunning and "ON" or "OFF",
                        S.starCollection.enabled and "ON" or "OFF",
                        UpgradeManager._loopRunning and "ON" or "OFF",
                        S.trialActive and "ACTIVE" or "IDLE")
                })
            end
        end)
    end
end)

SetTab:CreateSection("Performance")
SetTab:CreateButton({Name="⚡ Apply Optimizations (60 FPS, 30 tabbed)", Callback=function() applyOptimizations() end})
SetTab:CreateButton({Name="🔄 Revert Optimizations", Callback=function() pcall(revertOptimizations) end})
SetTab:CreateSlider({Name="FPS Cap", Range={15, 240}, Increment=5, CurrentValue=S.fpsCap, Flag="fpsCap", Callback=function(v) setFpsCap(v) end})
SetTab:CreateSection("Codes")
SetTab:CreateButton({Name="Redeem All Codes", Callback=function()
    local codes = {
        "RELEASE","LABUPDATE","8KCCU!!","9KCCU!!","10KCCU!!","11KCCU!!","12KCCU!!",
        "13KCCU!!","14KCCU!!","15KCCU!!","GetBetterSon","YouFoundMe","BAZALRIGHT",
        "SHUTDOWNBECAUSEOFNOOBS","35KCOMMUNITYMEMBERS!!","SORRYWEIRDANDANNOYINGBUGS!!",
        "HOPERUNESFIXEDONG!","VERYLITTLEUPDATE","BIGDELAYSORRY","SORRYSHUTDOWN69",
        "SORRYSHUTDOWN68","FOOTBALLEVENT","SORRYSHUTDOWN67","10MVISITS!","MINIUPDATE","JUSTALITTLEUPDATE"
    }
    task.spawn(function()
        for _, code in ipairs(codes) do
            pcall(function()
                game:GetService("ReplicatedStorage").__Net.MainRemote:FireServer("EnterCode", code)
            end)
            Rayfield:Notify({Title="Redeemed", Content=code})
            task.wait(0.5)
        end
        Rayfield:Notify({Title="Done", Content="All codes redeemed!"})
    end)
end})
SetTab:CreateSection("Open Game UIs")
SetTab:CreateButton({Name="Open Expedition", Callback=function() openUI("Expedition") end})
SetTab:CreateButton({Name="Open Enchants", Callback=function() openUI("Enchants") end})
SetTab:CreateButton({Name="Open Sword Enchants", Callback=function() openUI("SwordEnchants") end})
SetTab:CreateButton({Name="Open Rune Sacrifice", Callback=function() openUI("RuneSacrifice") end})
SetTab:CreateSection("Movement")
SetTab:CreateSlider({Name="Glide Speed", Range={0.05,2}, Increment=0.05, CurrentValue=S.tweenSpeed, Flag="tweenSpeed", Callback=function(v)S.tweenSpeed=v end})
SetTab:CreateToggle({Name="Anti AFK", Flag="antiAFK", CurrentValue=true, Callback=function(v)antiAFK(v)end})
SetTab:CreateButton({Name="Kill Script", Callback=function()env.NIStop=true;if activeTween then pcall(function()activeTween:Cancel()end)end;if _starGlide then pcall(function()_starGlide:Cancel()end)end;if nc1 then nc1:Disconnect()end;if nc2 then nc2:Disconnect()end;if nc3 then nc3:Disconnect()end;if afkConn then afkConn:Disconnect()end;if afkHB then afkHB:Disconnect()end;pcall(function()Rayfield:Destroy()end)end})

-- =========================================================================
-- HACKER TAB (HackPoints upgrades only, no Rune Farm)
-- =========================================================================
buildDynamicUpgradeTab(HackerTab, "HackPoints", {"EvenMoreHackPoints", "MoreRuneLuckkk", "MoreRuneSpeed", "MoreRuneLuck", "MoreHackPoints", "ConnorBalancedItt", "AutoHackPointsCollector", "MoreRuneBulk"}, "Hacker")


-- =============================================================================
-- AUTO-SAVE CONFIGURATION
-- =============================================================================
local function saveFullConfig()
    local data = {}
    -- Exclude ALL toggle/managed flags: Rayfield config handles these via Load/SaveConfiguration.
    -- Our custom config only saves things Rayfield doesn't manage (mob/ore selections, trial state, etc.)
    local exclude = {
        -- Noob toggles
        autoNoobPharaoh=true, autoNoobMummy=true, autoNoobMerchant=true, autoNoobAlien=true, autoNoobDemon=true, autoNoobAstronaut=true,
        -- Auto Buy toggles (managed by Rayfield)
        autoBuy_Sand=true, autoBuy_Souls=true, autoBuy_Bones=true, autoBuy_Meat=true,
        autoBuy_HackPoints=true, autoBuy_Stars=true, autoBuy_SpacePoints=true,
        autoBuy_Planets=true, autoBuy_Moon=true, autoBuy_Blackholes=true, autoBuy_AlienCash=true, autoBuy_Knowledge=true, autoBuyNoobRealm4=true, autoBuyNoob=true,
        -- Individual upgrade flags (managed by Rayfield toggle callbacks)
        autoStrongerShovels=true, autoMoreSand=true, autoAlotSand=true, autoEvenMoreSand=true,
        autoMultiSand=true, autoSandMoreOof=true, autoFasterShovels=true,
        autoMoreSouls=true, autoMoreBones=true, autoMoreOof=true, autoLuckierSwords=true, autoSoulsRuneBulk=true,
        autoMeatToBones=true, autoBonesToHacker=true, autoBonesFasterMeatConversion=true,
        autoBonesMoreOof=true, autoBonesMoreBones_=true, autoBonesBiggerMeatDeposit=true,
        autoBonesEvenMoreBones=true, autoBonesFasterSwords=true, autoStrongerSwords=true,
        autoMoreMeat=true, autoMeatMoreOof=true,
        autoHackPoints=true, autoRuneLuck=true, autoMoreRuneSpeed=true, autoMoreRuneLuck=true,
        autoMoreHackPoints=true, autoConnorBalancedItt=true, autoAutoHackPointsCollector=true, autoMoreRuneBulk=true,
        autoStarEvenMoreStars=true, autoStarMoreStars=true, autoStarFasterRespawn=true,
        autoStarOof=true, autoStarBoostMutationLuck=true, autoStarMoreSpacePoints=true,
        autoSpMultiStar=true, autoSpMoreSpacePoints=true, autoSpMoreMoon=true,
        autoSpBlackholes=true, autoSpBoostCollectRadius=true,
        autoPlanetsMorePlanets=true, autoPlanetsMoreStars=true, autoPlanetsHeatThePlanet=true,
        autoPlanetsMorePoints=true, autoPlanetsOofs=true, autoPlanetsBlackholes=true,
        autoUpgradePlanets=true, autoLevelUpShovel=true,
        autoMoonMoreMoon=true, autoMoonBoostStars=true, autoMoonMoreSpaceXP=true,
        autoMoonMorePlanets=true, autoMoonEvenMoreStars=true,
        autoBholeMoreBlackholes=true, autoBholePlanet=true,
        autoBholeFasterRespawn=true, autoBholeAliencash=true, autoBholeOofs=true,
        autoAlienMoreCash=true, autoAlienMoreXP=true,
        autoAlienBoostMutation=true, autoAlienVeryBadHoles=true,
        autoKnowledgeMoreKnowledge=true, autoKnowledgeMoreAlienCash=true, autoKnowledgeBoostSpaceXP=true,
        -- Internal state (not config)
        _noobTweening=true, trialActive=true, _realm4BoardRunning=true,
    }
    for k, v in pairs(S) do
        if not exclude[k] and type(v) ~= "function" and type(v) ~= "table" and type(v) ~= "userdata" and type(v) ~= "thread" then
            data[k] = v
        end
    end
    -- Mob combat toggles
    data.cToggles = {}
    for _, n in ipairs(MOBS) do data.cToggles[n] = S["c"..n] end
    -- Ore mining toggles
    data.mToggles = {}
    for _, n in ipairs(ORES) do data.mToggles[n] = S["m"..n] end
    -- Roll/skip toggles
    data.rollToggles = {}
    data.skipToggles = {}
    for _, n in ipairs(Noobs) do
        data.rollToggles[n] = S.autoRoll[n]
        data.skipToggles[n] = S.skipAlmighty[n]
    end
    -- Trial state
    data.TrialState = {}
    for diff, st in pairs(TrialState) do
        if diff and type(diff) == "string" and st then
            data.TrialState[diff] = {
                autoJoin = st.autoJoin, autoLeave = st.autoLeave,
                leaveWave = st.leaveWave, autoReturn = st.autoReturn,
                nearestMobFarm = st.nearestMobFarm,
                capturedPos = st.capturedPos,
            }
        end
    end
    -- Star collection state
    data.starCollection = {
        enabled = S.starCollection.enabled,
        tweenSpeed = S.starCollection.tweenSpeed,
        delay = S.starCollection.delay,
        collected = S.starCollection.collected,
    }
    -- Realm 4 board positions (manually captured)
    data.realm4BoardPositions = {}
    for cat, v in pairs(S._realm4BoardPositions) do
        if type(v) == "table" and v.pos then
            data.realm4BoardPositions[cat] = {pos = v.pos, time = v.time}
        end
    end
    -- Save dynamic upgrade dropdown selections
    data.dynUpgrades = {}
    local dynCategories = {"Sand","Souls","Bones","Meat","HackPoints","Stars","SpacePoints","Planets","Moon","Blackholes","AlienCash","Knowledge"}
    for _, cat in ipairs(dynCategories) do
        local raw = Rayfield.Flags["dyn_" .. cat .. "_list"]
        local opts = (type(raw) == "table" and raw.CurrentOption) or raw
        if type(opts) == "table" then
            data.dynUpgrades[cat] = opts
        end
    end
    env.SqaysSavedConfig = data
    pcall(function() Rayfield:SaveConfiguration() end)
end

-- Restore from _G on re-execute (skip flags managed by Rayfield config)
if env.SqaysSavedConfig then
    local data = env.SqaysSavedConfig
    local skip = {
        autoNoobPharaoh=true, autoNoobMummy=true, autoNoobMerchant=true, autoNoobAlien=true, autoNoobDemon=true, autoNoobAstronaut=true,
        autoBuy_Sand=true, autoBuy_Souls=true, autoBuy_Bones=true, autoBuy_Meat=true,
        autoBuy_HackPoints=true, autoBuy_Stars=true, autoBuy_SpacePoints=true,
        autoBuy_Planets=true, autoBuy_Moon=true, autoBuy_Blackholes=true, autoBuy_AlienCash=true, autoBuy_Knowledge=true, autoBuyNoobRealm4=true, autoBuyNoob=true,
        autoStrongerShovels=true, autoMoreSand=true, autoAlotSand=true, autoEvenMoreSand=true,
        autoMultiSand=true, autoSandMoreOof=true, autoFasterShovels=true,
        autoMoreSouls=true, autoMoreBones=true, autoMoreOof=true, autoLuckierSwords=true, autoSoulsRuneBulk=true,
        autoMeatToBones=true, autoBonesToHacker=true, autoBonesFasterMeatConversion=true,
        autoBonesMoreOof=true, autoBonesMoreBones_=true, autoBonesBiggerMeatDeposit=true,
        -- ^ first skip block in restore-from-_G
        autoBonesEvenMoreBones=true, autoBonesFasterSwords=true, autoStrongerSwords=true,
        autoMoreMeat=true, autoMeatMoreOof=true,
        autoHackPoints=true, autoRuneLuck=true, autoMoreRuneSpeed=true, autoMoreRuneLuck=true,
        autoMoreHackPoints=true, autoConnorBalancedItt=true, autoAutoHackPointsCollector=true, autoMoreRuneBulk=true,
        autoStarEvenMoreStars=true, autoStarMoreStars=true, autoStarFasterRespawn=true,
        autoStarOof=true, autoStarBoostMutationLuck=true, autoStarMoreSpacePoints=true,
        autoSpMultiStar=true, autoSpMoreSpacePoints=true, autoSpMoreMoon=true,
        autoSpBlackholes=true, autoSpBoostCollectRadius=true,
        autoPlanetsMorePlanets=true, autoPlanetsMoreStars=true, autoPlanetsHeatThePlanet=true,
        autoPlanetsMorePoints=true, autoPlanetsOofs=true, autoPlanetsBlackholes=true,
        autoUpgradePlanets=true, autoLevelUpShovel=true,
        autoMoonMoreMoon=true, autoMoonBoostStars=true, autoMoonMoreSpaceXP=true,
        autoMoonMorePlanets=true, autoMoonEvenMoreStars=true,
        autoBholeMoreBlackholes=true, autoBholePlanet=true,
        autoBholeFasterRespawn=true, autoBholeAliencash=true, autoBholeOofs=true,
        autoAlienMoreCash=true, autoAlienMoreXP=true,
        autoAlienBoostMutation=true, autoAlienVeryBadHoles=true,
        autoKnowledgeMoreKnowledge=true, autoKnowledgeMoreAlienCash=true, autoKnowledgeBoostSpaceXP=true,
        _noobTweening=true, trialActive=true, _realm4BoardRunning=true,
    }
    for k, v in pairs(data) do
        if not skip[k] and type(v) ~= "table" then S[k] = v end
    end
    if data.cToggles then for n, v in pairs(data.cToggles) do S["c"..n] = v end end
    if data.mToggles then for n, v in pairs(data.mToggles) do S["m"..n] = v end end
    if data.rollToggles then for n, v in pairs(data.rollToggles) do S.autoRoll[n] = v end end
    if data.skipToggles then for n, v in pairs(data.skipToggles) do S.skipAlmighty[n] = v end end
    if data.TrialState then
        for diff, st in pairs(data.TrialState) do
            if TrialState[diff] and st then
                for k, v in pairs(st) do TrialState[diff][k] = v end
            end
        end
    end
    if data.starCollection then
        for k, v in pairs(data.starCollection) do
            S.starCollection[k] = v
        end
    end
    -- Restore realm 4 board positions
    if data.realm4BoardPositions then
        for cat, v in pairs(data.realm4BoardPositions) do
            if type(v) == "table" and v.pos then
                S._realm4BoardPositions[cat] = v
            end
        end
    end
    -- Restore dynamic upgrade dropdown selections
    if data.dynUpgrades then
        for cat, selections in pairs(data.dynUpgrades) do
            if type(selections) == "table" then
                pcall(function()
                    local flag = Rayfield.Flags["dyn_" .. cat .. "_list"]
                    if flag and flag.Set then flag:Set(selections) end
                end)
            end
        end
    end
end

-- Auto-save every 10 seconds
task.spawn(function()
    while not env.NIStop do
        task.wait(10)
        pcall(saveFullConfig)
    end
end)

-- Load saved config (suppress stale-flag warnings from old save data)
local _oldWarn = warn
warn = function() end
Rayfield:LoadConfiguration()
warn = _oldWarn
pcall(function() Rayfield:SaveConfiguration() end)  -- overwrite old config immediately
-- Post-load sync: re-read all toggle states and dropdown selections.
-- LoadConfiguration fires callbacks but dropdowns may not be restored yet
-- when toggle callbacks run, so individual S flags might be stale.
-- This ensures every ON toggle has its dropdown selections applied.
local function syncFlagsFor(cat, flagFn)
    local rf = Rayfield.Flags["autoBuy_" .. cat]
    -- Handle both raw boolean and flag object with .CurrentValue
    local isOn = (rf == true) or (type(rf) == "table" and rf.CurrentValue == true)
    if isOn then
        local raw = Rayfield.Flags["dyn_" .. cat .. "_list"]
        if type(raw) == "table" and raw.CurrentOption ~= nil then raw = raw.CurrentOption end
        if type(raw) == "string" then raw = {raw} end
        if type(raw) == "table" then
            for _, upg in ipairs(raw) do flagFn(upg, true) end
            S["autoBuy_" .. cat] = true
        end
    end
end
local function setSand(upg, v)
    if upg == "StrongerShovels" then S.autoStrongerShovels = v
    elseif upg == "MoreSand" then S.autoMoreSand = v
    elseif upg == "AlotSand" then S.autoAlotSand = v
    elseif upg == "EvenMoreSand" then S.autoEvenMoreSand = v
    elseif upg == "MultiSand" then S.autoMultiSand = v
    elseif upg == "MoreOof" then S.autoSandMoreOof = v
    elseif upg == "FasterShovels" then S.autoFasterShovels = v end
end
local function setSouls(upg, v)
    if upg == "MoreSouls" then S.autoMoreSouls = v
    elseif upg == "MoreBones" then S.autoMoreBones = v
    elseif upg == "MoreOof" then S.autoMoreOof = v
    elseif upg == "LuckierSwords" then S.autoLuckierSwords = v
    elseif upg == "RuneBulk" then S.autoSoulsRuneBulk = v end
end
local function setBones(upg, v)
    if upg == "HackerPointMulti" then S.autoBonesToHacker = v
    elseif upg == "FasterMeatConversion" then S.autoBonesFasterMeatConversion = v
    elseif upg == "More Oof" then S.autoBonesMoreOof = v
    elseif upg == "MoreBones" then S.autoBonesMoreBones_ = v
    elseif upg == "BiggerMeatDeposit" then S.autoBonesBiggerMeatDeposit = v
    elseif upg == "evenMoreBones" then S.autoBonesEvenMoreBones = v
    elseif upg == "FasterSwords" then S.autoBonesFasterSwords = v end
end
local function setMeat(upg, v)
    if upg == "MoreBones" then S.autoMeatToBones = v
    elseif upg == "StrongerSwords" then S.autoStrongerSwords = v
    elseif upg == "MoreMeat" then S.autoMoreMeat = v
    elseif upg == "MoreOof" then S.autoMeatMoreOof = v end
end
local function setHack(upg, v)
    if upg == "EvenMoreHackPoints" then S.autoHackPoints = v
    elseif upg == "MoreRuneLuckkk" then S.autoRuneLuck = v
    elseif upg == "MoreRuneSpeed" then S.autoMoreRuneSpeed = v
    elseif upg == "MoreRuneLuck" then S.autoMoreRuneLuck = v
    elseif upg == "MoreHackPoints" then S.autoMoreHackPoints = v
    elseif upg == "ConnorBalancedItt" then S.autoConnorBalancedItt = v
    elseif upg == "AutoHackPointsCollector" then S.autoAutoHackPointsCollector = v
    elseif upg == "MoreRuneBulk" then S.autoMoreRuneBulk = v end
end
local function setStars(upg, v)
    if upg == "EvenMoreStars" then S.autoStarEvenMoreStars = v
    elseif upg == "MoreStars" then S.autoStarMoreStars = v
    elseif upg == "MoreSpacePoints" then S.autoStarMoreSpacePoints = v
    elseif upg == "FasterRespawn" then S.autoStarFasterRespawn = v
    elseif upg == "Oof" then S.autoStarOof = v
    elseif upg == "BoostStarsMutationLuck" then S.autoStarBoostMutationLuck = v end
end
local function setSp(upg, v)
    if upg == "MultiStar" then S.autoSpMultiStar = v
    elseif upg == "MoreSpacePoints" then S.autoSpMoreSpacePoints = v
    elseif upg == "MoreMoon" then S.autoSpMoreMoon = v
    elseif upg == "Blackholes" then S.autoSpBlackholes = v
    elseif upg == "BoostStarsCollectRadius" then S.autoSpBoostCollectRadius = v end
end
local function setPlanets(upg, v)
    if upg == "MorePlanets" then S.autoPlanetsMorePlanets = v
    elseif upg == "MoreStars" then S.autoPlanetsMoreStars = v
    elseif upg == "HeateThePlanet" then S.autoPlanetsHeatThePlanet = v
    elseif upg == "MorePoints" then S.autoPlanetsMorePoints = v
    elseif upg == "Oofs" then S.autoPlanetsOofs = v
    elseif upg == "Blackholes" then S.autoPlanetsBlackholes = v end
end
local function setMoon(upg, v)
    if upg == "MoreMoon" then S.autoMoonMoreMoon = v
    elseif upg == "BoostStars" then S.autoMoonBoostStars = v
    elseif upg == "MoreSpaceXP" then S.autoMoonMoreSpaceXP = v
    elseif upg == "MorePlanets" then S.autoMoonMorePlanets = v
    elseif upg == "EvenMoreStars" then S.autoMoonEvenMoreStars = v end
end
local function setBhole(upg, v)
    if upg == "MoreBlackholes" then S.autoBholeMoreBlackholes = v
    elseif upg == "Planet" then S.autoBholePlanet = v
    elseif upg == "FasterRespawn" then S.autoBholeFasterRespawn = v
    elseif upg == "Aliencash" then S.autoBholeAliencash = v
    elseif upg == "Oofs" then S.autoBholeOofs = v end
end
local function setAlienCash(upg, v)
    if upg == "MoreAlienCash" then S.autoAlienMoreCash = v
    elseif upg == "MoreAlienXP" then S.autoAlienMoreXP = v
    elseif upg == "BoostAlienMutationLuck" then S.autoAlienBoostMutation = v
    elseif upg == "VeryBadHoles" then S.autoAlienVeryBadHoles = v end
end
local function setKnowledge(upg, v)
    if upg == "MoreKnowledge" then S.autoKnowledgeMoreKnowledge = v
    elseif upg == "MoreAlienCash" then S.autoKnowledgeMoreAlienCash = v
    elseif upg == "BoostSpaceXP" then S.autoKnowledgeBoostSpaceXP = v end
end
-- Post-load sync with retry: Rayfield may need extra time to restore all flags.
-- First attempt immediately, then retry after 2s and 5s for any flags that weren't ready.
local function doAllSyncs()
    syncFlagsFor("Sand", setSand)
    syncFlagsFor("Souls", setSouls)
    syncFlagsFor("Bones", setBones)
    syncFlagsFor("Meat", setMeat)
    syncFlagsFor("HackPoints", setHack)
    syncFlagsFor("Stars", setStars)
    syncFlagsFor("SpacePoints", setSp)
    syncFlagsFor("Planets", setPlanets)
    syncFlagsFor("Moon", setMoon)
    syncFlagsFor("Blackholes", setBhole)
    syncFlagsFor("AlienCash", setAlienCash)
    syncFlagsFor("Knowledge", setKnowledge)
    -- Sync non-dynamic toggles: Realm 4 Noobs, Planets, UFO, Research, Star Collection
    if Rayfield.Flags.autoBuyNoobRealm4 == true then
        local raw = Rayfield.Flags.realm4NoobList
        if type(raw) == "table" and raw.CurrentOption ~= nil then raw = raw.CurrentOption end
        if type(raw) == "string" then raw = {raw} end
        if type(raw) == "table" then
            for _, sel in ipairs(raw) do
                if sel == "Alien" then S.autoNoobAlien = true
                elseif sel == "Demon" then S.autoNoobDemon = true
                elseif sel == "Astronaut" then S.autoNoobAstronaut = true
                end
            end
        end
    end
    if Rayfield.Flags.autoUpgradePlanets == true then S.autoUpgradePlanets = true end
    if Rayfield.Flags.autoUpgradeUFO == true then S.autoUpgradeUFO = true; startUFOLoop() end
    if Rayfield.Flags.autoResearch == true then S.autoResearch = true; startResearchLoop() end
    if Rayfield.Flags.starCollectionEnabled == true then S.starCollection.enabled = true; startStarLoop() end
    -- Start the loop if any toggle ended up ON
    if S.autoBuy_Sand or S.autoBuy_Souls or S.autoBuy_Bones or S.autoBuy_Meat
        or S.autoBuy_HackPoints or S.autoBuy_Stars or S.autoBuy_SpacePoints
        or S.autoBuy_Planets or S.autoBuy_Moon or S.autoBuy_Blackholes or S.autoBuy_AlienCash or S.autoBuy_Knowledge
        or S.autoNoobPharaoh or S.autoNoobMummy or S.autoNoobMerchant or S.autoNoobAlien or S.autoNoobDemon or S.autoNoobAstronaut
        or S.autoUpgradePlanets or S.autoLevelUpShovel then
        startRealm3Loop()
    end
end
-- Defer startup to avoid FPS drop: spread heavy init across frames
task.spawn(function()
    task.wait(0.5)  -- Let Rayfield UI finish rendering
    doAllSyncs()
end)
-- Retry after delays to catch flags not yet restored by Rayfield
task.spawn(function() task.wait(2); doAllSyncs() end)
task.spawn(function() task.wait(5); doAllSyncs() end)
-- Deferred save to avoid blocking startup
task.spawn(function() task.wait(1); pcall(saveFullConfig) end)
-- Deferred anti-AFK to avoid more startup work
task.spawn(function() task.wait(1); antiAFK(true) end)

-- Auto-restart dead upgrade loop (health check every 10s)
task.spawn(function()
    while not env.NIStop do
        task.wait(10)
        if _anyUpgradeActive() then
            local lastCheck = UpgradeManager._loopHealthCheck or 0
            -- If loop hasn't updated health check in 30s, it's probably dead
            if tick() - lastCheck > 30 then
                warn("[UPGRADE HEALTH] Loop appears dead, restarting...")
                UpgradeManager._loopRunning = false
                UpgradeManager._loopThread = nil
                task.wait(0.5)
                startRealm3Loop()
            elseif not UpgradeManager._loopRunning then
                -- Loop not running but should be
                startRealm3Loop()
            end
        end
    end
end)

-- Periodic memory cleanup: purge stale entries from rate-limit tables
task.spawn(function()
    while not env.NIStop do
        task.wait(60)
        local cutoff = tick() - 120  -- 2 min TTL
        -- Cleanup UpgradeManager backoff entries (stale entries > 2 min)
        if UpgradeManager._backoff then
            for k, v in pairs(UpgradeManager._backoff) do
                if v < cutoff then UpgradeManager._backoff[k] = nil end
            end
        end
        -- Cleanup recently bought tracking
        if UpgradeManager._recentlyBought then
            for k, v in pairs(UpgradeManager._recentlyBought) do
                if v < cutoff then UpgradeManager._recentlyBought[k] = nil end
            end
        end
        -- Cleanup maxed cache (entries beyond TTL — handles prestige resets)
        if UpgradeManager._maxed then
            local maxedCutoff = tick() - UpgradeManager._maxedTTL
            for k, v in pairs(UpgradeManager._maxed) do
                if v < maxedCutoff then UpgradeManager._maxed[k] = nil end
            end
        end
        if S._planetLastFire then
            for k, v in pairs(S._planetLastFire) do
                if v < cutoff then S._planetLastFire[k] = nil end
            end
        end
        if S._methodCThrottle then
            for k, v in pairs(S._methodCThrottle) do
                if v < cutoff then S._methodCThrottle[k] = nil end
            end
        end
    end
end)

print("[Sqays Hub] Ready - "..execName.." | "..gameName)
