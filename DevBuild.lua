-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local playerGui = game:GetService("Players").LocalPlayer.PlayerGui
local infoFrame = playerGui:WaitForChild("WorldInfo"):WaitForChild("InfoFrame")
local leaderboardGui = playerGui:FindFirstChild("LeaderboardGui")

local player = Players.LocalPlayer
local character
local humanoidRootPart
local camera = Workspace.CurrentCamera

-- Variables for movement
local movementDirection = Vector3.new(0, 0, 0)
local walkSpeed = 0
local flySpeed = 50 
local jumpPower = 0
local flying = false
local platform
local isNoclipping = false

-- Highlight colors and toggles
local highlightPlayerFillColor = Color3.fromRGB(255, 101, 27)
local highlightPlayerOutlineColor = Color3.fromRGB(255, 255, 255)
local highlightMobFillColor = Color3.fromRGB(0, 255, 0)
local highlightMobOutlineColor = Color3.fromRGB(255, 255, 255)
local highlightItemFillColor = Color3.fromRGB(0, 0, 255)
local highlightItemOutlineColor = Color3.fromRGB(255, 255, 255)
local highlightChestFillColor = Color3.fromRGB(255, 165, 0)
local highlightChestOutlineColor = Color3.fromRGB(255, 255, 255)

local highlightPlayersEnabled = false
local highlightMobsEnabled = false
local highlightItemsEnabled = false
local chestHighlightEnabled = false
local highlightNPCsEnabled = false -- Added for NPC ESP toggle
local npcNameESPEnabled = false -- Toggle for NPC Name ESP
local nameVisible = false
local healthVisible = false

local npcNameDrawings = {}
local playerNameDrawings = {}
local playerHealthDrawings = {}


-- Load the new UI library
local library = loadstring(game:GetObjects("rbxassetid://7657867786")[1].Source)()
local Wait = library.subs.Wait

-- Create the main window
local DeepSploitWindow = library:CreateWindow({
    Name = "DeepSploit V1.2",
    Themeable = {
        Info = "Discord Server: VzYTJ7Y"
    }
})

-- Create tabs
local VisualsTab = DeepSploitWindow:CreateTab({
    Name = "Visuals"
})

local Exploits = DeepSploitWindow:CreateTab({
    Name = "Exploits"
})



-- Create sections
local ExploitSection = Exploits:CreateSection({
    Name = "Player Exploits"
})

local ExploitSection2 = Exploits:CreateSection({
    Name = "Game Exploits",
    Side = "Right"
})


-- Esp Section
local EspSection = VisualsTab:CreateSection({
    Name = "ESP"
})

local NameEspSection = VisualsTab:CreateSection({
    Name = "NameEsp",
    Side = "Right"
})


-- ESP Toggles
EspSection:AddToggle({
    Name = "Highlight Players",
    Flag = "EspSection_HighlightPlayers",
    Callback = function(Value)
        highlightPlayersEnabled = Value
    end
})

EspSection:AddToggle({
    Name = "Highlight Mobs",
    Flag = "EspSection_HighlightMobs",
    Callback = function(Value)
        highlightMobsEnabled = Value
    end
})

EspSection:AddToggle({
    Name = "Highlight Items",
    Flag = "EspSection_HighlightItems",
    Callback = function(Value)
        highlightItemsEnabled = Value
    end
})

EspSection:AddToggle({
    Name = "Highlight Chests",
    Flag = "EspSection_HighlightChests",
    Callback = function(Value)
        chestHighlightEnabled = Value
    end
})

EspSection:AddToggle({
    Name = "Highlight Npcs",
    Flag = "EspSection_NpcEsp",
    Callback = function(Value)
        highlightNPCsEnabled = Value
    end
})


-- Name Esp Section
NameEspSection:AddToggle({
    Name = "Npc Name ESP",
    Flag = "NameEspSection_NpcNameEsp",
    Callback = function(Value)
        npcNameESPEnabled = Value
    end
})

NameEspSection:AddToggle({
    Name = "Player Name ESP",
    Flag = "NameEspSection_PlayerNameEsp",
    Callback = function(Value)
        nameVisible = Value
    end
})

NameEspSection:AddToggle({
    Name = "Player Health ESP",
    Flag = "NameEspSection_Health",
    Callback = function(Value)
        healthVisible = Value
    end
})

-- Add Toggle for Mob Name ESP
NameEspSection:AddToggle({
    Name = "Mob Name ESP",
    Flag = "NameEspSection_MobNameEsp",
    Callback = function(Value)
        mobNameESPEnabled = Value
    end
})

-- Add Toggle for Item Name ESP
NameEspSection:AddToggle({
    Name = "Item Name ESP",
    Flag = "NameEspSection_ItemNameEsp",
    Callback = function(Value)
        itemNameESPEnabled = Value
    end
})

-- Add Toggle for Chest Name ESP
NameEspSection:AddToggle({
    Name = "Chest Name ESP",
    Flag = "NameEspSection_ChestNameEsp",
    Callback = function(Value)
        chestNameESPEnabled = Value
    end
})

-- Exploit Section
ExploitSection:AddToggle({
    Name = "Toggle Flight",
    Flag = "MovementSection_ToggleFlight",
    Callback = function(Value)
        flying = Value
    end
})

ExploitSection:AddToggle({
    Name = "Toggle Noclip",
    Flag = "MovementSection_ToggleNoclip",
    Callback = function(Value)
        isNoclipping = Value
        setCanCollideForCharacter(not isNoclipping)
    end
})

ExploitSection:AddSlider({
    Name = "Walk Speed",
    Flag = "MovementSection_WalkSpeed",
    Value = walkSpeed,
    Min = 0,
    Max = 100,
    Callback = function(Value)
        walkSpeed = Value
    end
})

ExploitSection:AddSlider({
    Name = "Fly Speed",
    Flag = "MovementSection_FlySpeed",
    Value = flySpeed,
    Min = 0,
    Max = 100,
    Callback = function(Value)
        flySpeed = Value
    end
})

ExploitSection:AddSlider({
    Name = "Jump Power",
    Flag = "MovementSection_JumpPower",
    Value = jumpPower,
    Min = 0,
    Max = 250,
    Callback = function(Value)
        jumpPower = Value
    end
})

-- Functions
local function createHighlight(object, fillColor, outlineColor)
    if not object:FindFirstChildOfClass("Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Parent = object
        highlight.Adornee = object
        highlight.FillColor = fillColor
        highlight.OutlineColor = outlineColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.5
    else
        local highlight = object:FindFirstChildOfClass("Highlight")
        highlight.FillColor = fillColor
        highlight.OutlineColor = outlineColor
    end
end

local function removeHighlight(object)
    local highlight = object:FindFirstChildOfClass("Highlight")
    if highlight then
        highlight:Destroy()
    end
end

local function createNpcNameDrawing(npc)
    if not npcNameDrawings[npc] then
        local drawing = Drawing.new("Text")
        drawing.Text = npc.Name
        drawing.Size = 18
        drawing.Font = 2
        drawing.Color = Color3.fromRGB(255, 255, 255)
        drawing.Center = true
        drawing.Outline = true
        drawing.Visible = npcNameESPEnabled
        npcNameDrawings[npc] = drawing
    end
end

local function updateNpcNameDrawing(npc)
    local drawing = npcNameDrawings[npc]
    if drawing then
        local rootPart = npc:FindFirstChild("HumanoidRootPart")
        if rootPart then
            local screenPosition, onScreen = camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
            if onScreen then
                drawing.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                drawing.Visible = npcNameESPEnabled
            else
                drawing.Visible = false
            end
        end
    end
end

local function removeNpcNameDrawing(npc)
    if npcNameDrawings[npc] then
        npcNameDrawings[npc]:Remove()
        npcNameDrawings[npc] = nil
    end
end

local function createPlayerNameDrawing(player)
    if not playerNameDrawings[player] then
        local drawing = Drawing.new("Text")
        drawing.Text = player.Name
        drawing.Size = 18
        drawing.Font = 2
        drawing.Color = Color3.fromRGB(255, 255, 255)
        drawing.Center = true
        drawing.Outline = true
        drawing.Visible = nameVisible
        playerNameDrawings[player] = drawing
    end
end

local function createPlayerHealthDrawing(player)
    if not playerHealthDrawings[player] then
        local drawing = Drawing.new("Text")
        drawing.Size = 18
        drawing.Font = 2
        drawing.Color = Color3.fromRGB(0, 255, 0) -- Green color for health
        drawing.Center = true
        drawing.Outline = true
        drawing.Visible = healthVisible
        playerHealthDrawings[player] = drawing
    end
end

local function updatePlayerDrawings(player)
    local character = player.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChild("Humanoid")
        
        local nameDrawing = playerNameDrawings[player]
        local healthDrawing = playerHealthDrawings[player]

        if rootPart and humanoid and nameDrawing and healthDrawing then
            local screenPosition, onScreen = camera:WorldToViewportPoint(rootPart.Position + Vector3.new(0, 3, 0))
            if onScreen then
                nameDrawing.Position = Vector2.new(screenPosition.X, screenPosition.Y)
                nameDrawing.Visible = nameVisible

                healthDrawing.Text = tostring(math.floor(humanoid.Health))
                healthDrawing.Position = Vector2.new(screenPosition.X, screenPosition.Y - 20)
                healthDrawing.Visible = healthVisible
            else
                nameDrawing.Visible = false
                healthDrawing.Visible = false
            end
        end
    end
end

local function updateHighlights()
    local liveFolder = Workspace:FindFirstChild("Live")
    local shopsFolder = Workspace:FindFirstChild("Shops")
    local thrownFolder = Workspace:FindFirstChild("Thrown")
    local npcsFolder = Workspace:FindFirstChild("NPCs") -- For NPC ESP

    local playerNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        playerNames[p.Name] = true
    end

    -- Highlight players
    if highlightPlayersEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                createHighlight(p.Character, Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 255, 255)) -- Default colors, adjust as needed
                createPlayerNameDrawing(p)
                createPlayerHealthDrawing(p)
                updatePlayerDrawings(p)
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                removeHighlight(p.Character)
            end
            if p ~= Players.LocalPlayer then
                if playerNameDrawings[p] then
                    playerNameDrawings[p]:Remove()
                    playerNameDrawings[p] = nil
                end
                if playerHealthDrawings[p] then
                    playerHealthDrawings[p]:Remove()
                    playerHealthDrawings[p] = nil
                end
            end
        end
    end

    -- Highlight mobs
    if highlightMobsEnabled and liveFolder then
        for _, mob in pairs(liveFolder:GetChildren()) do
            if not playerNames[mob.Name] then
                createHighlight(mob, Color3.fromRGB(255, 101, 27), Color3.fromRGB(255, 255, 255)) -- Default colors, adjust as needed
            end
        end
    else
        if liveFolder then
            for _, mob in pairs(liveFolder:GetChildren()) do
                removeHighlight(mob)
            end
        end
    end

    -- Highlight buyable items
    if highlightItemsEnabled and shopsFolder then
        for _, item in pairs(shopsFolder:GetChildren()) do
            createHighlight(item, Color3.fromRGB(0, 255, 0), Color3.fromRGB(255, 255, 255)) -- Default colors, adjust as needed
        end
    else
        if shopsFolder then
            for _, item in pairs(shopsFolder:GetChildren()) do
                removeHighlight(item)
            end
        end
    end

    -- Highlight chests
    if chestHighlightEnabled and thrownFolder then
        for _, model in pairs(thrownFolder:GetChildren()) do
            if model:IsA("Model") and model:FindFirstChild("Lid") then
                createHighlight(model, Color3.fromRGB(255, 255, 0), Color3.fromRGB(255, 255, 255)) -- Default colors, adjust as needed
            end
        end
    else
        if thrownFolder then
            for _, model in pairs(thrownFolder:GetChildren()) do
                if model:IsA("Model") then
                    removeHighlight(model)
                end
            end
        end
    end

    -- Highlight NPCs and update their names
    if highlightNPCsEnabled and npcsFolder then
        for _, npc in pairs(npcsFolder:GetChildren()) do
            if npc:IsA("Model") and npc:FindFirstChild("HumanoidRootPart") then
                createHighlight(npc, Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 255, 255)) -- Default colors, adjust as needed
                createNpcNameDrawing(npc)
                updateNpcNameDrawing(npc)
            end
        end
    else
        if npcsFolder then
            for _, npc in pairs(npcsFolder:GetChildren()) do
                removeHighlight(npc)
                removeNpcNameDrawing(npc)
            end
        end
    end
end

local function updateMovementDirection()
    movementDirection = Vector3.new(0, 0, 0)
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        movementDirection = movementDirection + camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        movementDirection = movementDirection - camera.CFrame.LookVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        movementDirection = movementDirection - camera.CFrame.RightVector
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        movementDirection = movementDirection + camera.CFrame.RightVector
    end
end

local function fly()
    if flying then
        player.Character.HumanoidRootPart.Velocity = movementDirection * flySpeed
    else
        player.Character.HumanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    end
end

local function onFlyToggle()
    flying = not flying
    if flying then
        flySpeed = 50
        isNoclipping = true
        while flying do
            updateMovementDirection()
            fly()
            RunService.RenderStepped:Wait()
        end
    else
        isNoclipping = false
    end
end

local function onNoClipToggle()
    isNoclipping = not isNoclipping
end

-- Main loop
RunService.RenderStepped:Connect(function()
    updateHighlights()
    if flying then
        fly()
    end
end)

-- Keybindings
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.G then
        onFlyToggle()
    elseif input.KeyCode == Enum.KeyCode.N then
        onNoClipToggle()
    end
end)

-- Cleanup drawings on removal
Players.PlayerRemoving:Connect(function(leavingPlayer)
    if playerNameDrawings[leavingPlayer] then
        playerNameDrawings[leavingPlayer]:Remove()
        playerNameDrawings[leavingPlayer] = nil
    end
    if playerHealthDrawings[leavingPlayer] then
        playerHealthDrawings[leavingPlayer]:Remove()
        playerHealthDrawings[leavingPlayer] = nil
    end
end)
print("DeepSploit V1.2 loaded successfully")
