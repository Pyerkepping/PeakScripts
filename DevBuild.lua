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
local GeneralTab = DeepSploitWindow:CreateTab({
    Name = "General"
})

-- Create sections
local EspSection = GeneralTab:CreateSection({
    Name = "ESP"
})

local MovementSection = GeneralTab:CreateSection({
    Name = "Movement",
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

-- Movement controls
MovementSection:AddToggle({
    Name = "Toggle Flight",
    Flag = "MovementSection_ToggleFlight",
    Callback = function(Value)
        flying = Value
    end
})

MovementSection:AddToggle({
    Name = "Toggle Noclip",
    Flag = "MovementSection_ToggleNoclip",
    Callback = function(Value)
        isNoclipping = Value
        setCanCollideForCharacter(not isNoclipping)
    end
})

MovementSection:AddSlider({
    Name = "Walk Speed",
    Flag = "MovementSection_WalkSpeed",
    Value = walkSpeed,
    Min = 0,
    Max = 100,
    Callback = function(Value)
        walkSpeed = Value
    end
})

MovementSection:AddSlider({
    Name = "Fly Speed",
    Flag = "MovementSection_FlySpeed",
    Value = flySpeed,
    Min = 0,
    Max = 100,
    Callback = function(Value)
        flySpeed = Value
    end
})

MovementSection:AddSlider({
    Name = "Jump Power",
    Flag = "MovementSection_JumpPower",
    Value = jumpPower,
    Min = 0,
    Max = 250,
    Callback = function(Value)
        jumpPower = Value
    end
})

-- Functions (unchanged from your original script)
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

local function updateHighlights()
    local liveFolder = Workspace:FindFirstChild("Live")
    local shopsFolder = Workspace:FindFirstChild("Shops")
    local thrownFolder = Workspace:FindFirstChild("Thrown")

    local playerNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        playerNames[p.Name] = true
    end

    -- Highlight players
    if highlightPlayersEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                createHighlight(p.Character, highlightPlayerFillColor, highlightPlayerOutlineColor)
            end
        end
    else
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character then
                removeHighlight(p.Character)
            end
        end
    end

    -- Highlight mobs
    if highlightMobsEnabled and liveFolder then
        for _, mob in pairs(liveFolder:GetChildren()) do
            if not playerNames[mob.Name] then
                createHighlight(mob, highlightMobFillColor, highlightMobOutlineColor)
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
            createHighlight(item, highlightItemFillColor, highlightItemOutlineColor)
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
                createHighlight(model, highlightChestFillColor, highlightChestOutlineColor)
            end
        end
    else
        if thrownFolder then
            for _, model in pairs(thrownFolder:GetChildren()) do
                removeHighlight(model)
            end
        end
    end
end

local function updateMovementDirection()
    movementDirection = Vector3.new(0, 0, 0)
    
    local cameraLookVector = camera.CFrame.LookVector
    local cameraDirection = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit
    local cameraRight = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z).Unit

    if UserInputService:IsKeyDown(Enum.KeyCode.W) then
        movementDirection = movementDirection + cameraDirection
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then
        movementDirection = movementDirection - cameraDirection
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then
        movementDirection = movementDirection - cameraRight
    end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then
        movementDirection = movementDirection + cameraRight
    end

    if movementDirection.Magnitude > 0 then
        movementDirection = movementDirection.Unit
    end
end

local function moveCharacter(deltaTime)
    if movementDirection.Magnitude > 0 then
        local displacement = movementDirection * walkSpeed * deltaTime
        local newCFrame = humanoidRootPart.CFrame + displacement
        humanoidRootPart.CFrame = newCFrame
    end
end

local function setCanCollideForCharacter(canCollide)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = canCollide
        end
    end
end

local function createPlatform()
    platform = Instance.new("Part")
    platform.Size = Vector3.new(5, 1, 5)
    platform.Anchored = true
    platform.CanCollide = false
    platform.Transparency = 1
    platform.Parent = Workspace
end

local function stopMomentum()
    humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
end

local function onRenderStepped(deltaTime)
    updateMovementDirection()
    
    if flying then
        if movementDirection.Magnitude > 0 then
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + (movementDirection * flySpeed * deltaTime)
        end
        platform.Position = humanoidRootPart.Position - Vector3.new(0, 3.5, 0)
        stopMomentum()
    else
        moveCharacter(deltaTime)
    end

    if UserInputService:IsKeyDown(Enum.KeyCode.Space) and humanoidRootPart.Velocity.Y <= 0 then
        humanoidRootPart.Velocity = humanoidRootPart.Velocity + Vector3.new(0, jumpPower, 0)
    end

    updateHighlights()
end

local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    createPlatform()
    isNoclipping = false
    flying = false
end

-- Deleting each GUI element
local elementsToDelete = {
    "AgeInfo",
    "CharacterInfo",
    "WorldInfo"
}

for _, elementName in ipairs(elementsToDelete) do
    local element = infoFrame:FindFirstChild(elementName)
    if element then
        element:Destroy()
    end
end

if leaderboardGui then
    leaderboardGui:Destroy()
end

-- Connect events
player.CharacterAdded:Connect(onCharacterAdded)
RunService.RenderStepped:Connect(onRenderStepped)

-- Initialize for the first time
onCharacterAdded(player.Character or player.CharacterAdded:Wait())
