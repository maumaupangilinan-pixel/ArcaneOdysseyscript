-- Arcane Odyssey Script System - MODIFIED VERSION
-- Main loader

-- Configuration
local CONFIG = {
    REPO_URL = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/',
    UI_NAME = 'Arcane Odyssey Scripts',
    SAVE_FOLDER = 'ArcaneOdysseyHack',
    GAME_PLACE_IDS = {
        OLD_WORLD = 12604352060,
        NEW_WORLD = 15449776494,
        CURRENT = game.PlaceId
    }
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- Player references
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local PlayerGui = Player:WaitForChild("PlayerGui")
local Backpack = Player:WaitForChild("Backpack")

-- Character tracking
Player.CharacterAdded:Connect(function(char)
    Character = char
    Backpack = Player:WaitForChild("Backpack")
end)

-- Module loader
local Modules = {}
local function LoadModule(name)
    if Modules[name] then return Modules[name] end
    
    local module = {}
    
    if name == "UI" then
        -- Load Linoria Library
        local Library = loadstring(game:HttpGet(CONFIG.REPO_URL .. 'Library.lua'))()
        local ThemeManager = loadstring(game:HttpGet(CONFIG.REPO_URL .. 'addons/ThemeManager.lua'))()
        local SaveManager = loadstring(game:HttpGet(CONFIG.REPO_URL .. 'addons/SaveManager.lua'))()
        
        module.Library = Library
        module.ThemeManager = ThemeManager
        module.SaveManager = SaveManager
        
        -- Create main window
        module.Window = Library:CreateWindow({
            Title = CONFIG.UI_NAME,
            Center = false,
            AutoShow = true,
            TabPadding = 8,
            MenuFadeTime = 0.2
        })
        
        -- Create tabs (only Combat, World, Settings remain)
        module.Tabs = {
            Combat = module.Window:AddTab('Combat'),
            World = module.Window:AddTab('World'),
            Settings = module.Window:AddTab('Settings')
        }
        
        -- Setup theme and save managers
        ThemeManager:SetLibrary(Library)
        SaveManager:SetLibrary(Library)
        ThemeManager:SetFolder(CONFIG.SAVE_FOLDER)
        SaveManager:SetFolder(CONFIG.SAVE_FOLDER)
        
    elseif name == "Utilities" then
        module.ESP = {}
        module.Teleport = {}
        module.Checks = {}
        module.Vision = {}  -- NEW: Vision functions
        
        -- FIXED ESP Functions - SMALL TEXT ONLY
        module.ESP.createBillboard = function(text, color, object, distance)
            local folder = Workspace:FindFirstChild("ESP_Folder") or Instance.new("Folder", Workspace)
            folder.Name = "ESP_Folder"
            
            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.new(0, 100, 0, 25)  -- SMALLER SIZE
            billboard.AlwaysOnTop = true
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.MaxDistance = distance or 800
            billboard.LightInfluence = 0
            billboard.Parent = folder
            billboard.Adornee = object
            
            local label = Instance.new("TextLabel")
            label.Parent = billboard
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 0.8
            label.BackgroundColor3 = Color3.new(0, 0, 0)
            label.Text = text
            label.TextColor3 = color or Color3.new(1, 1, 1)
            label.TextStrokeTransparency = 0.5
            label.Font = Enum.Font.Gotham
            label.TextSize = 12  -- SMALL TEXT
            label.TextScaled = false
            label.TextYAlignment = Enum.TextYAlignment.Center
            
            return billboard
        end
        
        module.ESP.clearAll = function()
            local folder = Workspace:FindFirstChild("ESP_Folder")
            if folder then
                folder:ClearAllChildren()
            end
        end
        
        -- ========== NEW: CLEARVISION SYSTEM ==========
        module.Vision.enableClearVision = function()
            print("👁️ Enabling ClearVision for Dark Sea...")
            
            -- Remove all dark skies
            for _, obj in pairs(Workspace:GetDescendants()) do
                if obj:IsA("Sky") then
                    if string.find(obj.Name:lower(), "dark") or 
                       string.find(obj.Name:lower(), "night") or
                       string.find(obj.Name:lower(), "storm") then
                        obj:Destroy()
                        print("Removed dark sky: " .. obj.Name)
                    end
                end
            end
            
            -- Remove camera darkness effects
            if Workspace:FindFirstChild("Camera") then
                for _, effect in pairs(Workspace.Camera:GetChildren()) do
                    if effect:IsA("Sky") or effect:IsA("ColorCorrectionEffect") then
                        effect:Destroy()
                        print("Removed camera effect: " .. effect.Name)
                    end
                end
            end
            
            -- Apply lighting settings
            Lighting.FogEnd = 1000000  -- Remove fog completely
            Lighting.Brightness = 3     -- Increase brightness
            Lighting.GlobalShadows = false
            Lighting.Ambient = Color3.new(1, 1, 1)     -- White ambient
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            Lighting.ClockTime = 12      -- Force midday
            
            -- Remove atmosphere if exists
            local atmosphere = Lighting:FindFirstChild("Atmosphere")
            if atmosphere then 
                atmosphere:Destroy()
                print("Removed atmosphere")
            end
            
            -- Disable all post-processing effects
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect:IsA("PostEffect") then
                    effect.Enabled = false
                    print("Disabled effect: " .. effect.Name)
                end
            end
            
            -- Create bright sky if needed
            local existingSky = Lighting:FindFirstChildOfClass("Sky")
            if not existingSky then
                local newSky = Instance.new("Sky")
                newSky.SkyboxBk = "rbxassetid://449463403"
                newSky.SkyboxDn = "rbxassetid://449463427"
                newSky.SkyboxFt = "rbxassetid://449463403"
                newSky.SkyboxLf = "rbxassetid://449463403"
                newSky.SkyboxRt = "rbxassetid://449463403"
                newSky.SkyboxUp = "rbxassetid://449463425"
                newSky.Parent = Lighting
                print("Created bright sky")
            end
            
            -- Prevent dark skies from reappearing
            Workspace.Camera.ChildAdded:Connect(function(child)
                if child:IsA("Sky") and string.find(child.Name:lower(), "dark") then
                    child:Destroy()
                    print("Blocked dark sky from reappearing")
                end
            end)
            
            -- Force maintain brightness
            RunService.Heartbeat:Connect(function()
                Lighting.ClockTime = 12
                Lighting.FogEnd = 1000000
                Lighting.Brightness = 3
            end)
            
            print("✅ ClearVision enabled - Dark Sea should be visible!")
            return true
        end
        
        module.Vision.disableClearVision = function()
            -- Restore default lighting
            Lighting.FogEnd = 10000
            Lighting.Brightness = 1
            Lighting.GlobalShadows = true
            print("🌙 ClearVision disabled")
        end
        
        module.Vision.maxBrightness = function()
            -- Maximum brightness settings
            Lighting.Brightness = 5
            Lighting.FogEnd = 1000000
            Lighting.Ambient = Color3.new(1, 1, 1)
            Lighting.OutdoorAmbient = Color3.new(1, 1, 1)
            print("🔆 Maximum brightness activated")
        end
        
        module.Vision.removeFogOnly = function()
            -- Just remove fog
            Lighting.FogEnd = 1000000
            print("🌫️ Fog removed")
        end
        
        -- Teleport Functions
        module.Teleport.toPosition = function(position, cf)
            if Character and Character:FindFirstChild("HumanoidRootPart") then
                local hrp = Character.HumanoidRootPart
                if cf then
                    hrp.CFrame = cf
                else
                    hrp.CFrame = CFrame.new(position)
                end
            end
        end
        
        module.Teleport.toIsland = function(islandName)
            local island = Workspace.Map:FindFirstChild(islandName)
            if island and island:FindFirstChild("Center") then
                module.Teleport.toPosition(island.Center.Position)
            end
        end
        
        module.Teleport.toBoat = function()
            local boatName = Player.Name .. "Boat"
            local boat = Workspace.Boats:FindFirstChild(boatName)
            if boat then
                local tpPart = boat:FindFirstChild("Grate") or boat:FindFirstChild("WorldPivot")
                if tpPart then
                    module.Teleport.toPosition(nil, tpPart.CFrame)
                end
            end
        end
        
        -- NEW: Teleport to Player
        module.Teleport.toPlayer = function(playerName)
            local targetPlayer = Players:FindFirstChild(playerName)
            if targetPlayer and targetPlayer.Character then
                local targetChar = targetPlayer.Character
                local hrp = targetChar:FindFirstChild("HumanoidRootPart")
                if hrp and Character:FindFirstChild("HumanoidRootPart") then
                    Character.HumanoidRootPart.CFrame = hrp.CFrame
                    return true
                end
            end
            return false
        end
        
        -- Check Functions
        module.Checks.isEnemy = function(model)
            if model.Parent == Workspace.Enemies then
                return true
            end
            if model:IsA("Model") and model:FindFirstChild("Humanoid") then
                local player = Players:GetPlayerFromCharacter(model)
                if player and player ~= Player then
                    return true
                end
            end
            return false
        end
        
        module.Checks.isAlive = function(model)
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if humanoid then
                return humanoid.Health > 0
            end
            
            local attributes = model:FindFirstChild("Attributes")
            if attributes then
                local health = attributes:FindFirstChild("Health")
                if health then
                    return health.Value > 0
                end
            end
            
            return false
        end
        
        module.Checks.hasBoat = function()
            local boatName = Player.Name .. "Boat"
            return Workspace.Boats:FindFirstChild(boatName) ~= nil
        end
        
    elseif name == "Features" then
        module.Combat = {}
        module.World = {}
        
        -- Shared state
        module.State = {
            Connections = {},
            Toggles = {},
            Tasks = {},
            ESPs = {}
        }
        
        -- Cleanup function
        module.cleanup = function(category)
            if category then
                if module.State.Connections[category] then
                    for _, conn in pairs(module.State.Connections[category]) do
                        conn:Disconnect()
                    end
                    module.State.Connections[category] = {}
                end
                
                if module.State.Tasks[category] then
                    module.State.Tasks[category] = nil
                end
                
                if module.State.ESPs[category] then
                    for _, esp in pairs(module.State.ESPs[category]) do
                        esp:Destroy()
                    end
                    module.State.ESPs[category] = {}
                end
            else
                -- Cleanup everything
                for cat, conns in pairs(module.State.Connections) do
                    for _, conn in pairs(conns) do
                        conn:Disconnect()
                    end
                end
                module.State.Connections = {}
                
                for _, task in pairs(module.State.Tasks) do
                    task:Cancel()
                end
                module.State.Tasks = {}
                
                for _, esps in pairs(module.State.ESPs) do
                    for _, esp in pairs(esps) do
                        esp:Destroy()
                    end
                end
                module.State.ESPs = {}
            end
        end
        
        -- Register connection
        module.registerConnection = function(category, connection)
            if not module.State.Connections[category] then
                module.State.Connections[category] = {}
            end
            table.insert(module.State.Connections[category], connection)
        end
        
        -- Register ESP
        module.registerESP = function(category, esp)
            if not module.State.ESPs[category] then
                module.State.ESPs[category] = {}
            end
            table.insert(module.State.ESPs[category], esp)
        end
        
        -- Register task
        module.registerTask = function(category, task)
            module.State.Tasks[category] = task
        end
    end
    
    Modules[name] = module
    return module
end

-- Load core modules
local UI = LoadModule("UI")
local Utilities = LoadModule("Utilities")
local Features = LoadModule("Features")

-- Feature Implementations
do
    -- COMBAT FEATURES - MODIFIED (INCLUDES MOVEMENT AND PLAYER FEATURES)
    Features.Combat.setup = function()
        local Tab = UI.Tabs.Combat
        local Utils = Utilities
        
        -- Group boxes for ALL features
        local AuraGroup = Tab:AddLeftGroupbox('Void Kill Aura')
        local MovementGroup = Tab:AddRightGroupbox('Movement')
        local TeleportGroup = Tab:AddLeftGroupbox('Teleport')
        local StatsGroup = Tab:AddRightGroupbox('Stats & Boat')
        
        -- ========== VOID KILL AURA ==========
        AuraGroup:AddSlider('AuraRange', {
            Text = 'Aura Range',
            Default = 50,
            Min = 10,
            Max = 500,
            Rounding = 1
        })
        
        AuraGroup:AddToggle('AuraPlayers', {
            Text = 'Target Players',
            Default = false
        })
        
        AuraGroup:AddToggle('AuraNPCs', {
            Text = 'Target NPCs',
            Default = true
        })
        
        AuraGroup:AddToggle('KillAura', {
            Text = 'Enable Void Kill Aura',
            Default = false,
            Callback = function(Value)
                Features.cleanup("KillAura")
                
                if Value then
                    Features.registerTask("KillAura", task.spawn(function()
                        while Toggles.KillAura.Value do
                            local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
                            if hrp then
                                local range = Options.AuraRange.Value
                                
                                -- Check NPCs
                                if Toggles.AuraNPCs.Value then
                                    for _, enemy in pairs(Workspace.Enemies:GetChildren()) do
                                        if not Utils.Checks.isAlive(enemy) then continue end
                                        
                                        local enemyHrp = enemy:FindFirstChild("HumanoidRootPart")
                                        if enemyHrp then
                                            local dist = (enemyHrp.Position - hrp.Position).Magnitude
                                            if dist <= range then
                                                -- Deal small damage first
                                                local args = {
                                                    Character,
                                                    enemy,
                                                    "Metal Magic",
                                                    "3",
                                                    '["Pulsar",10,20,20,true,"Two Hands","25","Pulsar","Drill","Metal"]',
                                                    1,
                                                    1
                                                }
                                                ReplicatedStorage.RS.Remotes.Magic.DealAttackDamage:FireServer(unpack(args))
                                                
                                                -- Throw into void (far below)
                                                task.wait(0.1)
                                                if enemyHrp and enemyHrp.Parent then
                                                    enemyHrp.CFrame = CFrame.new(enemyHrp.Position.X, -10000, enemyHrp.Position.Z)
                                                end
                                            end
                                        end
                                    end
                                end
                                
                                -- Check Players
                                if Toggles.AuraPlayers.Value then
                                    for _, otherPlayer in pairs(Players:GetPlayers()) do
                                        if otherPlayer == Player then continue end
                                        local char = otherPlayer.Character
                                        if char and Utils.Checks.isAlive(char) then
                                            local enemyHrp = char:FindFirstChild("HumanoidRootPart")
                                            if enemyHrp then
                                                local dist = (enemyHrp.Position - hrp.Position).Magnitude
                                                if dist <= range then
                                                    -- Deal small damage first
                                                    local args = {
                                                        Character,
                                                        char,
                                                        "Metal Magic",
                                                        "3",
                                                        '["Pulsar",10,20,20,true,"Two Hands","25","Pulsar","Drill","Metal"]',
                                                        1,
                                                        1
                                                    }
                                                    ReplicatedStorage.RS.Remotes.Magic.DealAttackDamage:FireServer(unpack(args))
                                                    
                                                    -- Throw into void (far below)
                                                    task.wait(0.1)
                                                    if enemyHrp and enemyHrp.Parent then
                                                        enemyHrp.CFrame = CFrame.new(enemyHrp.Position.X, -10000, enemyHrp.Position.Z)
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                            task.wait(0.5)
                        end
                    end))
                end
            end
        })
        
        AuraGroup:AddLabel('Throws enemies into the void after damaging them')
        
        -- ========== MOVEMENT FEATURES ==========
        MovementGroup:AddInput('WalkSpeed', {
            Default = '100',
            Numeric = true,
            Text = 'Walk Speed'
        })
        
        MovementGroup:AddToggle('SpeedHack', {
            Text = 'Speed Hack',
            Default = false,
            Callback = function(Value)
                Features.cleanup("Speed")
                
                if Value then
                    local originalSpeed
                    local humanoid = Character:FindFirstChild("Humanoid")
                    if humanoid then
                        originalSpeed = humanoid.WalkSpeed
                    end
                    
                    local conn = RunService.RenderStepped:Connect(function()
                        local humanoid = Character and Character:FindFirstChild("Humanoid")
                        if humanoid then
                            humanoid.WalkSpeed = tonumber(Options.WalkSpeed.Value) or 100
                        end
                    end)
                    
                    Features.registerConnection("Speed", conn)
                    
                    -- Restore on disable
                    Features.State.Toggles.SpeedRestore = function()
                        local humanoid = Character and Character:FindFirstChild("Humanoid")
                        if humanoid and originalSpeed then
                            humanoid.WalkSpeed = originalSpeed
                        end
                    end
                else
                    if Features.State.Toggles.SpeedRestore then
                        Features.State.Toggles.SpeedRestore()
                    end
                end
            end
        })
        
        MovementGroup:AddInput('FlySpeed', {
            Default = '100',
            Numeric = true,
            Text = 'Fly Speed'
        })
        
        MovementGroup:AddToggle('Flight', {
            Text = 'Flight',
            Default = false,
            Callback = function(Value)
                Features.cleanup("Flight")
                
                if Value then
                    local humanoid = Character:FindFirstChild("Humanoid")
                    local hrp = Character:FindFirstChild("HumanoidRootPart")
                    
                    if humanoid and hrp then
                        humanoid.PlatformStand = true
                        
                        local conn = RunService.RenderStepped:Connect(function()
                            local flySpeed = tonumber(Options.FlySpeed.Value) or 100
                            local camera = Workspace.CurrentCamera
                            local direction = Vector3.new(0, 0, 0)
                            
                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                                direction = direction + camera.CFrame.LookVector
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.S) then
                                direction = direction - camera.CFrame.LookVector
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.A) then
                                direction = direction - camera.CFrame.RightVector
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.D) then
                                direction = direction + camera.CFrame.RightVector
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                                direction = direction + Vector3.new(0, 1, 0)
                            end
                            if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
                                direction = direction + Vector3.new(0, -1, 0)
                            end
                            
                            if direction.Magnitude > 0 then
                                direction = direction.Unit * flySpeed
                                hrp.Velocity = direction
                            else
                                hrp.Velocity = Vector3.new(0, 3.5, 0)
                            end
                        end)
                        
                        Features.registerConnection("Flight", conn)
                    end
                else
                    local humanoid = Character:FindFirstChild("Humanoid")
                    if humanoid then
                        humanoid.PlatformStand = false
                    end
                end
            end
        })
        
        MovementGroup:AddToggle('NoClip', {
            Text = 'No Clip',
            Default = false,
            Callback = function(Value)
                Features.cleanup("NoClip")
                
                if Value then
                    local conn = RunService.Stepped:Connect(function()
                        if Character then
                            for _, part in pairs(Character:GetDescendants()) do
                                if part:IsA("BasePart") then
                                    part.CanCollide = false
                                end
                            end
                        end
                    end)
                    
                    Features.registerConnection("NoClip", conn)
                else
                    if Character then
                        for _, part in pairs(Character:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = true
                            end
                        end
                    end
                end
            end
        })
        
        MovementGroup:AddToggle('InfiniteJump', {
            Text = 'Infinite Jump',
            Default = false,
            Callback = function(Value)
                Features.cleanup("InfiniteJump")
                
                if Value then
                    local conn = UserInputService.JumpRequest:Connect(function()
                        local hrp = Character and Character:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            hrp.Velocity = Vector3.new(hrp.Velocity.X, 50, hrp.Velocity.Z)
                        end
                    end)
                    
                    Features.registerConnection("InfiniteJump", conn)
                end
            end
        })
        
        -- ========== TELEPORT FEATURES ==========
        TeleportGroup:AddButton('To Boat', function()
            Utils.Teleport.toBoat()
        end)
        
        TeleportGroup:AddButton('To Quest', function()
            if Workspace.Camera:FindFirstChild("QuestMarker1") then
                Utils.Teleport.toPosition(nil, Workspace.Camera.QuestMarker1.CFrame)
            end
        end)
        
        TeleportGroup:AddButton('To Story', function()
            if Workspace.Camera:FindFirstChild("StoryMarker1") then
                Utils.Teleport.toPosition(nil, Workspace.Camera.StoryMarker1.CFrame)
            end
        end)
        
        TeleportGroup:AddInput('PlayerToTP', {
            Default = '',
            Text = 'Teleport to Player',
            Tooltip = 'Enter player username'
        })
        
        TeleportGroup:AddButton('TP to Player', function()
            local playerName = Options.PlayerToTP.Value
            if playerName and playerName ~= "" then
                local success = Utils.Teleport.toPlayer(playerName)
                if success then
                    UI.Library:Notify("Teleported to " .. playerName)
                else
                    UI.Library:Notify("Failed to teleport to " .. playerName)
                end
            end
        end)
        
        TeleportGroup:AddDropdown('PlayerList', {
            Values = {},
            Default = 1,
            Text = 'Select Player',
            Callback = function(Value)
                if Value and Value ~= "" then
                    Utils.Teleport.toPlayer(Value)
                end
            end
        })
        
        -- Update player list
        local function updatePlayerList()
            local playerNames = {}
            for _, player in pairs(Players:GetPlayers()) do
                if player ~= Player then
                    table.insert(playerNames, player.Name)
                end
            end
            Options.PlayerList.Values = playerNames
            Options.PlayerList:SetValues()
        end
        
        -- Initial update
        updatePlayerList()
        
        -- Auto-update player list
        Players.PlayerAdded:Connect(updatePlayerList)
        Players.PlayerRemoving:Connect(updatePlayerList)
        
        -- ========== STATS & BOAT FEATURES ==========
        StatsGroup:AddToggle('NoFallDamage', {
            Text = 'No Fall Damage',
            Default = false,
            Callback = function(Value)
                if Value then
                    local remote = ReplicatedStorage.RS.Remotes.Combat:FindFirstChild("FallDamage")
                    if remote then
                        remote:Destroy()
                    end
                end
            end
        })
        
        StatsGroup:AddToggle('InfiniteZoom', {
            Text = 'Infinite Zoom',
            Default = false,
            Callback = function(Value)
                if Value then
                    Player.CameraMaxZoomDistance = 100000
                else
                    Player.CameraMaxZoomDistance = 100
                end
            end
        })
        
        StatsGroup:AddInput('BoatSpeed', {
            Default = '10000',
            Numeric = true,
            Text = 'Boat Speed'
        })
        
        StatsGroup:AddToggle('FastBoat', {
            Text = 'Fast Boat',
            Default = false,
            Callback = function(Value)
                Features.cleanup("FastBoat")
                
                if Value and Utils.Checks.hasBoat() then
                    local boatName = Player.Name .. "Boat"
                    
                    local conn = RunService.RenderStepped:Connect(function()
                        local boat = Workspace.Boats:FindFirstChild(boatName)
                        local center = boat and boat:FindFirstChild("Center")
                        
                        if center then
                            local throttle = 0
                            if UserInputService:IsKeyDown(Enum.KeyCode.W) then
                                throttle = 1
                            elseif UserInputService:IsKeyDown(Enum.KeyCode.S) then
                                throttle = -1
                            end
                            
                            local speed = tonumber(Options.BoatSpeed.Value) or 10000
                            local desiredVel = center.CFrame.LookVector * throttle * speed
                            center.Velocity = center.Velocity:Lerp(desiredVel, 0.1)
                        end
                    end)
                    
                    Features.registerConnection("FastBoat", conn)
                end
            end
        })
        
        StatsGroup:AddButton('Remove Boat Damage', function()
            local boatName = Player.Name .. "Boat"
            local boat = Workspace.Boats:FindFirstChild(boatName)
            
            if boat then
                for _, transmitter in pairs(boat:GetDescendants()) do
                    if transmitter:IsA("TouchTransmitter") then
                        transmitter:Destroy()
                    end
                end
                UI.Library:Notify("Boat collision damage removed!")
            else
                UI.Library:Notify("No boat found!")
            end
        end)
        
        StatsGroup:AddButton('Wash Boat', function()
            ReplicatedStorage.RS.Remotes.Boats.Wash:FireServer()
            UI.Library:Notify("Boat washed!")
        end)
    end
    
    -- WORLD FEATURES - FIXED WITH PLAYER & CHEST ESP + CLEARVISION
    Features.World.setup = function()
        local Tab = UI.Tabs.World
        local Utils = Utilities
        
        -- Group boxes
        local ESPGroup = Tab:AddLeftGroupbox('ESP System')
        local IslandsGroup = Tab:AddRightGroupbox('Islands')
        local VisionGroup = Tab:AddLeftGroupbox('🌊 DARK SEA VISION')
        
        -- ========== CLEARVISION BUTTONS ==========
        VisionGroup:AddToggle('DarkSeaClearVision', {
            Text = 'Enable ClearVision',
            Default = false,
            Tooltip = 'Removes all darkness and fog from Dark Sea',
            Callback = function(Value)
                if Value then
                    local success = Utils.Vision.enableClearVision()
                    if success then
                        UI.Library:Notify("ClearVision enabled for Dark Sea!")
                    else
                        UI.Library:Notify("Failed to enable ClearVision")
                        Toggles.DarkSeaClearVision:SetValue(false)
                    end
                else
                    Utils.Vision.disableClearVision()
                    UI.Library:Notify("ClearVision disabled")
                end
            end
        })
        
        VisionGroup:AddButton('Maximum Brightness', function()
            Utils.Vision.maxBrightness()
            UI.Library:Notify("Maximum brightness activated!")
        end)
        
        VisionGroup:AddButton('Remove Fog Only', function()
            Utils.Vision.removeFogOnly()
            UI.Library:Notify("Fog removed from Dark Sea")
        end)
        
        VisionGroup:AddButton('Night Vision Mode', function()
            -- Green night vision effect
            Lighting.Ambient = Color3.fromRGB(0, 255, 0)
            Lighting.OutdoorAmbient = Color3.fromRGB(0, 255, 0)
            Lighting.FogEnd = 1000000
            UI.Library:Notify("Night vision activated!")
        end)
        
        -- ========== FIXED PLAYER ESP ==========
        ESPGroup:AddToggle('PlayerESP', {
            Text = 'Player ESP',
            Default = false,
            Tooltip = 'Show small ESP for other players',
            Callback = function(Value)
                Features.cleanup("PlayerESP")
                Utils.ESP.clearAll()
                
                if Value then
                    local function updatePlayerESP()
                        -- Clear existing
                        Utils.ESP.clearAll()
                        
                        -- Add ESP for players
                        for _, otherPlayer in pairs(Players:GetPlayers()) do
                            if otherPlayer ~= Player then
                                local char = otherPlayer.Character
                                if char and char:FindFirstChild("HumanoidRootPart") then
                                    local humanoid = char:FindFirstChild("Humanoid")
                                    local isAlive = humanoid and humanoid.Health > 0
                                    
                                    if isAlive then
                                        -- Small text: Just player name
                                        local esp = Utils.ESP.createBillboard(otherPlayer.Name, Color3.fromRGB(255, 50, 50), char.HumanoidRootPart, 1000)
                                        Features.registerESP("PlayerESP", esp)
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Initial update
                    updatePlayerESP()
                    
                    -- Continuous update
                    local conn = RunService.Heartbeat:Connect(function()
                        updatePlayerESP()
                    end)
                    
                    Features.registerConnection("PlayerESP", conn)
                end
            end
        })
        
        -- ========== FIXED CHEST ESP - SMALL TEXT ONLY ==========
        ESPGroup:AddToggle('ChestESP', {
            Text = 'Chest ESP',
            Default = false,
            Tooltip = 'Show small ESP for chests',
            Callback = function(Value)
                Features.cleanup("ChestESP")
                Utils.ESP.clearAll()
                
                if Value then
                    local function updateChestESP()
                        -- Clear existing
                        Utils.ESP.clearAll()
                        
                        -- Scan for chests
                        for _, island in pairs(Workspace.Map:GetChildren()) do
                            local chests = island:FindFirstChild("Chests")
                            if chests then
                                for _, chest in pairs(chests:GetChildren()) do
                                    if chest:IsA("Model") and chest.Name ~= "Private Storage" then
                                        local chestObj = chest:FindFirstChild("ChestObj")
                                        if chestObj then
                                            local primary = chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
                                            if primary then
                                                -- Small text: Chest name
                                                local color = Color3.fromRGB(255, 255, 255)
                                                if chest.Name == "Treasure Chest" then
                                                    color = Color3.fromRGB(255, 165, 0)
                                                elseif chest.Name == "Uncommon Chest" then
                                                    color = Color3.fromRGB(0, 255, 0)
                                                elseif chest.Name == "Rare Chest" then
                                                    color = Color3.fromRGB(0, 150, 255)
                                                end
                                                
                                                local esp = Utils.ESP.createBillboard(chest.Name, color, primary, 500)
                                                Features.registerESP("ChestESP", esp)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    
                    -- Initial update
                    updateChestESP()
                    
                    -- Continuous update
                    local conn = RunService.Heartbeat:Connect(function()
                        updateChestESP()
                    end)
                    
                    Features.registerConnection("ChestESP", conn)
                end
            end
        })
        
        ESPGroup:AddButton('Clear ESP', function()
            Utils.ESP.clearAll()
            Features.cleanup("PlayerESP")
            Features.cleanup("ChestESP")
            UI.Library:Notify("All ESP cleared")
        end)
        
        -- ========== ISLANDS ==========
        local islandList = {}
        for _, island in pairs(Workspace.Map:GetChildren()) do
            if island:FindFirstChild("Center") then
                table.insert(islandList, island.Name)
            end
        end
        
        IslandsGroup:AddDropdown('IslandTP', {
            Values = islandList,
            Default = 1,
            Text = 'Select Island',
            Callback = function(Value)
                Utils.Teleport.toIsland(Value)
                UI.Library:Notify("Teleported to " .. Value)
            end
        })
        
        IslandsGroup:AddButton('Refresh Islands', function()
            -- Refresh island list
            islandList = {}
            for _, island in pairs(Workspace.Map:GetChildren()) do
                if island:FindFirstChild("Center") then
                    table.insert(islandList, island.Name)
                end
            end
            Options.IslandTP.Values = islandList
            Options.IslandTP:SetValues()
            UI.Library:Notify("Island list refreshed!")
        end)
        
        IslandsGroup:AddButton('TP to Dark Sea', function()
            -- Try to find a Dark Sea island
            for _, island in pairs(Workspace.Map:GetChildren()) do
                if island.Name:lower():find("dark") or island.Name:lower():find("sea") then
                    if island:FindFirstChild("Center") then
                        Utils.Teleport.toIsland(island.Name)
                        UI.Library:Notify("Teleported to " .. island.Name)
                        return
                    end
                end
            end
            UI.Library:Notify("No Dark Sea island found")
        end)
    end
end

-- Initialize all features
Features.Combat.setup()
Features.World.setup()

-- Settings tab
do
    local Tab = UI.Tabs.Settings
    local MenuGroup = Tab:AddLeftGroupbox('Menu')
    
    MenuGroup:AddToggle('ShowKeybinds', {
        Text = 'Show Keybind Menu',
        Default = true,
        Callback = function(Value)
            UI.Library.KeybindFrame.Visible = Value
        end
    })
    
    MenuGroup:AddLabel('Menu Keybind'):AddKeyPicker('MenuKeybind', {
        Default = 'End',
        NoUI = true,
        Text = 'Menu Keybind'
    })
    
    MenuGroup:AddButton('Unload', function()
        Features.cleanup()
        Utilities.ESP.clearAll()
        UI.Library:Unload()
    end)
    
    MenuGroup:AddButton('Copy Discord', function()
        setclipboard("https://discord.gg/vHR8gXc4Ag")
        UI.Library:Notify("Discord link copied!")
    end)
    
    UI.ThemeManager:ApplyToTab(Tab)
    UI.SaveManager:BuildConfigSection(Tab)
    UI.SaveManager:LoadAutoloadConfig()
end

-- Set keybind
UI.Library.ToggleKeybind = Options.MenuKeybind

-- Unload handler
UI.Library:OnUnload(function()
    Features.cleanup()
    Utilities.ESP.clearAll()
    print('Arcane Odyssey Scripts Unloaded!')
end)

print('============================================')
print('✅ Arcane Odyssey Scripts Loaded!')
print('✅ NEW TAB LAYOUT:')
print('   • Combat Tab: All movement, teleport, and combat features')
print('   • World Tab: ESP, Islands, and Dark Sea Vision')
print('   • Settings Tab: Menu controls')
print('============================================')

-- Test ClearVision on load
task.spawn(function()
    task.wait(2)
    print("Testing ClearVision system...")
    if Utilities.Vision then
        print("ClearVision system ready!")
    end
end)
