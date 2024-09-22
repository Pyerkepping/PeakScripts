-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local character
local humanoidRootPart
local camera = Workspace.CurrentCamera

-- Variables for movement
local movementDirection = Vector3.new(0, 0, 0)
local walkSpeed = 0
local flySpeed = 0
local jumpPower = 100
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

-- Spectate functionality variables
local spectatePlayerName = ""
local spectatePlayerEnabled = false

-- Function to create a highlight
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

-- Function to remove highlight
local function removeHighlight(object)
    local highlight = object:FindFirstChildOfClass("Highlight")
    if highlight then
        highlight:Destroy()
    end
end

-- Function to update highlights dynamically
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

-- Function to update movement direction based on key inputs
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

-- Function to move the character using CFrame with the adjusted speed
local function moveCharacter(deltaTime)
    if movementDirection.Magnitude > 0 then
        local displacement = movementDirection * walkSpeed * deltaTime
        local newCFrame = humanoidRootPart.CFrame + displacement
        humanoidRootPart.CFrame = newCFrame
    end
end

-- Function to toggle noclip mode
local function toggleNoclip()
    isNoclipping = not isNoclipping
    setCanCollideForCharacter(not isNoclipping)
end

-- Function to set CanCollide for all character parts
local function setCanCollideForCharacter(canCollide)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = canCollide
        end
    end
end

-- Create platform part for flying
local function createPlatform()
    platform = Instance.new("Part")
    platform.Size = Vector3.new(5, 1, 5)
    platform.Anchored = true
    platform.CanCollide = false
    platform.Transparency = 1
    platform.Parent = Workspace
end

-- Function to stop momentum
local function stopMomentum()
    humanoidRootPart.Velocity = Vector3.new(0, 0, 0)
    humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0)
end

-- Main flight control
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

    -- Jump height adjustment
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) and humanoidRootPart.Velocity.Y <= 0 then
        humanoidRootPart.Velocity = humanoidRootPart.Velocity + Vector3.new(0, jumpPower, 0)
    end

    updateHighlights()
end

-- Function to spectate a player
local function spectatePlayer(playerName)
    local targetPlayer = Players:FindFirstChild(playerName)
    if targetPlayer and targetPlayer.Character then
        camera.CameraSubject = targetPlayer.Character:FindFirstChildOfClass("Humanoid")
    else
        print("Spectate Error: Player not found or character not loaded.")
    end
end

-- Function to stop spectating
local function stopSpectating()
    camera.CameraSubject = character:FindFirstChildOfClass("Humanoid")
end

-- Cleanup and initialization when character is added
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    createPlatform()
    isNoclipping = false
    flying = false
    walkSpeed = 0
end

-- Functions to update the highlight colors
local function UpdatePlayerHighlightColor(newFillColor, newOutlineColor)
    highlightPlayerFillColor = newFillColor or highlightPlayerFillColor
    highlightPlayerOutlineColor = newOutlineColor or highlightPlayerOutlineColor
    updateHighlights()
end

local function UpdateMobHighlightColor(newFillColor, newOutlineColor)
    highlightMobFillColor = newFillColor or highlightMobFillColor
    highlightMobOutlineColor = newOutlineColor or highlightMobOutlineColor
    updateHighlights()
end

local function UpdateItemHighlightColor(newFillColor, newOutlineColor)
    highlightItemFillColor = newFillColor or highlightItemFillColor
    highlightItemOutlineColor = newOutlineColor or highlightItemOutlineColor
    updateHighlights()
end

local function UpdateChestHighlightColor(newFillColor, newOutlineColor)
    highlightChestFillColor = newFillColor or highlightChestFillColor
    highlightChestOutlineColor = newOutlineColor or highlightChestOutlineColor
    updateHighlights()
end

-- Connect events
player.CharacterAdded:Connect(onCharacterAdded)
RunService.RenderStepped:Connect(onRenderStepped)

-- Initialize for the first time
onCharacterAdded(player.Character or player.CharacterAdded:Wait())

-- UI Setup
local uiLoader = loadstring(game:HttpGet('https://raw.githubusercontent.com/topitbopit/dollarware/main/library.lua'))
local ui = uiLoader({
    rounding = false,
    theme = 'cherry',
    smoothDragging = false
})

ui.autoDisableToggles = true

-- Create the main window
local window = ui.newWindow({
    text = 'Deepwoven',
    resize = true,
    size = Vector2.new(550, 376)
})

-- Visuals Menu
local visualsMenu = window:addMenu({
    text = 'Visuals'
})

-- Consolidated Visuals Section
local visualsSection = visualsMenu:addSection({
    text = 'Visual Features',
    side = 'left',
    showMinButton = true
})

-- Highlight Players toggle
visualsSection:addToggle({
    text = 'Highlight Players',
    state = false
}, function(newState)
    highlightPlayersEnabled = newState
    ui.notify({
        title = 'Highlight Toggle',
        message = 'Highlight Players toggled to ' .. tostring(newState),
        duration = 3
    })
end)

-- Mob ESP toggle
visualsSection:addToggle({
    text = 'Mob ESP',
    state = false
}, function(newState)
    highlightMobsEnabled = newState
    ui.notify({
        title = 'Mob ESP Toggle',
        message = 'Mob ESP toggled to ' .. tostring(newState),
        duration = 3
    })
end)

-- Buyable Item ESP toggle
visualsSection:addToggle({
    text = 'Buyable Item ESP',
    state = false
}, function(newState)
    highlightItemsEnabled = newState
    ui.notify({
        title = 'Item ESP Toggle',
        message = 'Buyable Item ESP toggled to ' .. tostring(newState),
        duration = 3
    })
end)

-- Chest ESP toggle
visualsSection:addToggle({
    text = 'Chest ESP',
    state = false
}, function(newState)
    chestHighlightEnabled = newState
    updateHighlights()
    ui.notify({
        title = 'Chest ESP Toggle',
        message = 'Chest ESP toggled to ' .. tostring(newState),
        duration = 3
    })
end)

-- Color pickers for highlights
local colorSection = visualsMenu:addSection({
    text = 'Highlight Colors',
    side = 'right',
    showMinButton = true
})

colorSection:addColorPicker({
    text = 'Player Highlight Fill Color',
    color = highlightPlayerFillColor
}, function(newColor)
    UpdatePlayerHighlightColor(newColor, nil)
end)

colorSection:addColorPicker({
    text = 'Player Outline Color',
    color = highlightPlayerOutlineColor
}, function(newColor)
    UpdatePlayerHighlightColor(nil, newColor)
end)

colorSection:addColorPicker({
    text = 'Mob Highlight Fill Color',
    color = highlightMobFillColor
}, function(newColor)
    UpdateMobHighlightColor(newColor, nil)
end)

colorSection:addColorPicker({
    text = 'Mob Outline Color',
    color = highlightMobOutlineColor
}, function(newColor)
    UpdateMobHighlightColor(nil, newColor)
end)

colorSection:addColorPicker({
    text = 'Buyable Item Highlight Fill Color',
    color = highlightItemFillColor
}, function(newColor)
    UpdateItemHighlightColor(newColor, nil)
end)

colorSection:addColorPicker({
    text = 'Buyable Item Outline Color',
    color = highlightItemOutlineColor
}, function(newColor)
    UpdateItemHighlightColor(nil, newColor)
end)

colorSection:addColorPicker({
    text = 'Chest Highlight Fill Color',
    color = highlightChestFillColor
}, function(newColor)
    UpdateChestHighlightColor(newColor, nil)
end)

colorSection:addColorPicker({
    text = 'Chest Outline Color',
    color = highlightChestOutlineColor
}, function(newColor)
    UpdateChestHighlightColor(nil, newColor)
end)

-- Brightness adjustment slider
local brightnessSlider = visualsMenu:addSection({
    text = 'Brightness Adjustment',
    side = 'left',
    showMinButton = true
})

brightnessSlider:addSlider({
    text = 'Adjust Brightness',
    min = 0,
    max = 100,
    step = 1,
    val = 50
}, function(newValue)
    -- Adjust the lighting's brightness based on the slider value
    Lighting.Brightness = newValue / 100
    ui.notify({
        title = 'Brightness',
        message = 'Brightness set to ' .. tostring(newValue),
        duration = 3
    })
end)

-- Remove fog button
local fogButton = visualsMenu:addSection({
    text = 'Fog Removal',
    side = 'right',
    showMinButton = true
})

fogButton:addButton({
    text = 'Remove Fog',
    style = 'large'
}, function()
    -- Remove fog by adjusting lighting properties
    Lighting.FogEnd = 100000 -- Set to a high value to remove the fog effect
    ui.notify({
        title = 'Fog Removal',
        message = 'Fog has been removed!',
        duration = 3
    })
end)




-- Player Menu
local playerMenu = window:addMenu({
    text = 'Player'
})

do
    -- First section under Player
    local section1 = playerMenu:addSection({
        text = 'Player Settings ',
        side = 'left',
        showMinButton = true
    })
    

    -- Spectate Player toggle
    local spectatePlayerToggle = section1:addToggle({
        text = 'Spectate Player',
        state = false
    })

    -- Textbox for player name
    local playerNameTextbox = section1:addTextbox({
        text = 'Player Name'
    })

    spectatePlayerToggle:bindToEvent('onToggle', function(newState)
        spectatePlayerEnabled = newState -- Enable/disable player spectating
        if spectatePlayerEnabled then
            spectatePlayer(spectatePlayerName) -- Start spectating
        else
            stopSpectating() -- Stop spectating
        end
        ui.notify({
            title = 'Spectate Toggle',
            message = 'Spectate Player toggled to ' .. tostring(newState),
            duration = 3
        })
    end)

    playerNameTextbox:bindToEvent('onFocusLost', function(text)
        spectatePlayerName = text -- Update the spectate player name
        if spectatePlayerEnabled then
            spectatePlayer(spectatePlayerName) -- Update spectating if already enabled
        end
    end)

        -- Button to rejoin server
    section1:addButton({
        text = 'Rejoin Server',
        style = 'large'
    }, function()
        -- Rejoin the server
        local placeId = game.PlaceId
        local teleportService = game:GetService("TeleportService")
        teleportService:Teleport(placeId, player)
        ui.notify({
            title = 'Rejoin Server',
            message = 'Rejoining the server...',
            duration = 3
        })
    end)
end

-- Second section under Player
local section2 = playerMenu:addSection({
    text = 'Player Movement ',
    side = 'right',
    showMinButton = true
})

do
    section2:addSlider({
        text = 'Walk Speed',
        min = 0,
        max = 250,
        step = 1,
        val = 0
    }, function(value)
        walkSpeed = value -- Update the walkSpeed variable based on the slider value
        print("Speed set to:", value)
    end)

    section2:addSlider({
        text = 'Fly Speed',
        min = 0,
        max = 250,
        step = 1,
        val = 0
    }, function(value)
        flySpeed = value -- Update the flySpeed variable based on the slider value
        print("flySpeed set to:", value)
    end)
    
    -- Slider to adjust player jump power
    section2:addSlider({
        text = 'Jump Power',
        min = 0,
        max = 200,
        step = 1,
        val = 0
    }, function(newValue)
        -- Assuming a humanoid exists in the character
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.JumpPower = newValue
        end
        ui.notify({
            title = 'Jump Power',
            message = 'Jump Power set to ' .. tostring(newValue),
            duration = 3
        })
    end)
end

local section3 = playerMenu:addSection({
    text = 'Player Exploits ',
    side = 'left',
    showMinButton = true
})

do
    local FlyToggle = section3:addToggle({
        text = 'Fly Hack', 
        state = false -- Starting state of the toggle - doesn't automatically call the callback
    })
    
    FlyToggle:bindToEvent('onToggle', function(newState) -- Call a function when toggled
        flying = newState
        ui.notify({
            title = 'Fly Hack',
            message = 'Fly Hack was toggled to ' .. tostring(newState),
            duration = 3
        })
    end)
    
    local FlyHotkey = section3:addHotkey({
        text = 'Fly Keybind'
    })
    FlyHotkey:setHotkey(Enum.KeyCode.G)
    FlyHotkey:setTooltip('This is a hotkey linked to the FlyToggle!')
    FlyHotkey:linkToControl(FlyToggle)
end  -- Close the first do block

do  -- Start a new block for NoClipToggle
    local NoClipToggle = section3:addToggle({
        text = 'No Clip', 
        state = false -- Starting state of the toggle - doesn't automatically call the callback
    })
    
    NoClipToggle:bindToEvent('onToggle', function(newState) -- Call a function when toggled
        isNoclipping = newState -- Use the isNoclipping variable defined earlier
        ui.notify({
            title = 'No Clip',
            message = 'No Clip was toggled to ' .. tostring(newState),
            duration = 3
        })
    end)
    
    local NoClipHotKey = section3:addHotkey({
        text = 'NoClip Keybind'
    })
    NoClipHotKey:setHotkey(Enum.KeyCode.N)
    NoClipHotKey:setTooltip('This is a hotkey linked to the NoClipToggle!')
    NoClipHotKey:linkToControl(NoClipToggle)
end

-- Walking Stuff
local movementDirection = Vector3.new(0, 0, 0)

-- Function to update the movement direction based on key inputs
local function updateMovementDirection()
    movementDirection = Vector3.new(0, 0, 0)
    
    -- Get the camera's look vector
    local cameraLookVector = camera.CFrame.LookVector
    
    -- Break down the look vector into the XZ plane
    local cameraDirection = Vector3.new(cameraLookVector.X, 0, cameraLookVector.Z).Unit

    -- Right direction relative to the camera
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

    -- Normalize direction to ensure consistent speed
    if movementDirection.Magnitude > 0 then
        movementDirection = movementDirection.Unit
    end
end

-- Function to move the character using CFrame with increased speed
local function moveCharacter(deltaTime)
    if movementDirection.Magnitude > 0 then
        -- Calculate the new position using CFrame
        local displacement = movementDirection * walkSpeed * deltaTime
        local newCFrame = humanoidRootPart.CFrame + displacement
        humanoidRootPart.CFrame = newCFrame
    end
end

-- Input listeners to update the movement direction
UserInputService.InputBegan:Connect(updateMovementDirection)
UserInputService.InputEnded:Connect(updateMovementDirection)

-- Connect the moveCharacter function to RunService's RenderStepped for smooth movement
RunService.RenderStepped:Connect(function(deltaTime)
    updateMovementDirection()
    moveCharacter(deltaTime)
    updateHighlights() -- Update highlights dynamically
end)

-- Input listeners to update the movement direction
UserInputService.InputBegan:Connect(updateMovementDirection)
UserInputService.InputEnded:Connect(updateMovementDirection)

-- Connect the moveCharacter function to RunService's RenderStepped for smooth movement
RunService.RenderStepped:Connect(function(deltaTime)
    updateMovementDirection()
    moveCharacter(deltaTime)
    updateHighlights() -- Update highlights dynamically
end)
