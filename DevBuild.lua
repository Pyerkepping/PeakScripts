-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting") -- To adjust brightness and fog
local TeleportService = game:GetService("TeleportService") -- For rejoining the server

local player = Players.LocalPlayer
local character
local humanoidRootPart
local camera = Workspace.CurrentCamera

-- Variables for movement
local movementDirection = Vector3.new(0, 0, 0)
local walkSpeed = 0 -- Default speed
local flySpeed = 0 -- Default fly speed
local jumpPower = 100 -- Jump height adjustment
local flying = false
local platform
local isNoclipping = false -- Track the noclip state

-- Highlight functionality variables
local highlightFillColor = Color3.fromRGB(255, 101, 27) -- Default fill color
local outlineColor = Color3.fromRGB(255, 255, 255) -- Default outline color
local highlightPlayersEnabled = false -- Toggle for players
local highlightMobsEnabled = false -- Toggle for mobs
local highlightItemsEnabled = false -- Toggle for items
local chestHighlightEnabled = false -- Toggle for chests

-- Spectate functionality variables
local spectatePlayerName = "" -- Player name to spectate
local spectatePlayerEnabled = false -- Toggle state for spectating

-- Function to create a highlight
local function createHighlight(object, fillColor, outlineColor)
    if not object:FindFirstChildOfClass("Highlight") then
        local highlight = Instance.new("Highlight")
        highlight.Parent = object
        highlight.Adornee = object
        highlight.FillColor = fillColor or highlightFillColor
        highlight.OutlineColor = outlineColor or outlineColor
        highlight.FillTransparency = 0.5
        highlight.OutlineTransparency = 0.5
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

    -- Create a set of player names
    local playerNames = {}
    for _, p in pairs(Players:GetPlayers()) do
        playerNames[p.Name] = true
    end

    -- Highlight players
    if highlightPlayersEnabled then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                createHighlight(p.Character, highlightFillColor, outlineColor)
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
                createHighlight(mob, highlightFillColor, outlineColor)
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
            createHighlight(item, highlightFillColor, outlineColor)
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
                createHighlight(model, highlightFillColor, outlineColor)
            else
                removeHighlight(model)
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

    if isNoclipping then
        print("Noclip enabled")
        setCanCollideForCharacter(false)  -- Disable collision immediately when noclip is enabled
    else
        print("Noclip disabled")
        setCanCollideForCharacter(true)   -- Re-enable collision when noclip is disabled
    end
end

-- Function to set CanCollide for all character parts
local function setCanCollideForCharacter(canCollide)
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = canCollide
        end
    end
end

-- Noclip logic: maintain character's position and orientation
RunService.Stepped:Connect(function()
    if isNoclipping then
        humanoidRootPart.Velocity = Vector3.new(0, 0, 0)  -- Zero out velocity to prevent tilting
        humanoidRootPart.CFrame = CFrame.new(humanoidRootPart.Position) * CFrame.Angles(0, humanoidRootPart.Orientation.Y * math.rad(1), 0)  -- Maintain orientation
    end
end)

-- Create platform part for flying
local function createPlatform()
    platform = Instance.new("Part")
    platform.Size = Vector3.new(5, 1, 5) -- Adjust size if needed
    platform.Color = Color3.fromRGB(255, 255, 0) -- Can change color (doesn't affect invisibility)
    platform.Anchored = true
    platform.CanCollide = false -- Prevents collisions
    platform.Transparency = 0 -- Makes the platform fully invisible
    platform.Parent = Workspace
end

-- Initialize platform
createPlatform()

-- Function to change fly speed
local function changeFlySpeed(newSpeed)
    flySpeed = newSpeed
    print("Fly speed set to:", flySpeed)
end

-- Detect movement key press
local function isMoving()
    return UserInputService:IsKeyDown(Enum.KeyCode.W) or
           UserInputService:IsKeyDown(Enum.KeyCode.A) or
           UserInputService:IsKeyDown(Enum.KeyCode.S) or
           UserInputService:IsKeyDown(Enum.KeyCode.D)
end

-- Function to stop momentum
local function stopMomentum()
    humanoidRootPart.Velocity = Vector3.new(0, 0, 0) -- Zero out velocity
    humanoidRootPart.RotVelocity = Vector3.new(0, 0, 0) -- Stop any rotational velocity
end

-- Main flight control
local function onRenderStepped(deltaTime)
    updateMovementDirection()
    
    if flying then
        -- Only move if any key is pressed
        if isMoving() then
            local direction = Vector3.new(0, 0, 0)

            -- Movement directions based on camera
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

            -- Apply smooth movement using CFrame
            humanoidRootPart.CFrame = humanoidRootPart.CFrame + (direction.Unit * flySpeed * deltaTime)
        end

        -- Position platform under the player with a fixed offset
        platform.Position = humanoidRootPart.Position - Vector3.new(0, 3.5, 0)

        -- Stop any momentum or unwanted movement
        stopMomentum()
    else
        moveCharacter(deltaTime)
    end

    -- Jump height adjustment
    if UserInputService:IsKeyDown(Enum.KeyCode.Space) and humanoidRootPart.Velocity.Y <= 0 then
        humanoidRootPart.Velocity = humanoidRootPart.Velocity + Vector3.new(0, jumpPower, 0)
    end

    -- Update highlights dynamically
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

-- Cleanup platform when character is removed
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoidRootPart = character:WaitForChild("HumanoidRootPart")
    createPlatform() -- Recreate the platform for flying
    isNoclipping = false -- Reset noclip state
    flying = false -- Reset flying state
    walkSpeed = 50 -- Reset walk speed
end

-- Connect events
player.CharacterAdded:Connect(onCharacterAdded)
RunService.RenderStepped:Connect(onRenderStepped)

-- Initialize for the first time
onCharacterAdded(player.Character or player.CharacterAdded:Wait())



-- Example usage of changeFlySpeed function
-- You can call this function with a new speed value to change the fly speed, e.g., changeFlySpeed(150)



-- Dollarware example script

-- Snag the ui loader function (loadstring the link, but don't call it)
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

do 
    -- First section under Visuals
    local section1 = visualsMenu:addSection({
        text = 'Visuals Section 1',
        side = 'left',
        showMinButton = true
    })
    
    -- Highlight Players toggle
    local highlightPlayersToggle = section1:addToggle({
        text = 'Highlight Players',
        state = false
    })
    
    highlightPlayersToggle:bindToEvent('onToggle', function(newState)
        highlightPlayersEnabled = newState -- Enable/disable player highlighting
        ui.notify({
            title = 'Highlight Toggle',
            message = 'Highlight Players toggled to ' .. tostring(newState),
            duration = 3
        })
    end)

    -- Mob ESP toggle
    local mobESPToggle = section1:addToggle({
        text = 'Mob ESP',
        state = false
    })
    mobESPToggle:bindToEvent('onToggle', function(newState)
        highlightMobsEnabled = newState -- Enable/disable mob highlighting
        ui.notify({
            title = 'Mob ESP Toggle',
            message = 'Mob ESP toggled to ' .. tostring(newState),
            duration = 3
        })
    end)

    -- Buyable Item ESP toggle
    local itemESPToggle = section1:addToggle({
        text = 'Buyable Item ESP',
        state = false
    })
    itemESPToggle:bindToEvent('onToggle', function(newState)
        highlightItemsEnabled = newState -- Enable/disable item highlighting
        ui.notify({
            title = 'Item ESP Toggle',
            message = 'Buyable Item ESP toggled to ' .. tostring(newState),
            duration = 3
        })
    end)
end

-- Second section under Visuals
local section2 = visualsMenu:addSection({
    text = 'Visuals Section 2',
    side = 'right',
    showMinButton = true
})

do
    -- Brightness adjustment slider
    section2:addSlider({
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
    section2:addButton({
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

    -- Color picker for highlight fill color
    section2:addColorPicker({
        text = 'Highlight Fill Color',
        color = highlightFillColor
    }, function(newColor)
        updateHighlightColors(newColor, nil) -- Update fill color
    end)

    -- Color picker for outline color
    section2:addColorPicker({
        text = 'Outline Color',
        color = outlineColor
    }, function(newColor)
        updateHighlightColors(nil, newColor) -- Update outline color
    end)
end

-- Third section under Visuals (Loot ESP)
local lootESPSection = visualsMenu:addSection({
    text = 'Loot ESP',
    side = 'left',
    showMinButton = true
})

do
    -- Chest ESP toggle
    local chestESPToggle = lootESPSection:addToggle({
        text = 'Chest ESP',
        state = false
    })
    chestESPToggle:bindToEvent('onToggle', function(newState)
        chestHighlightEnabled = newState -- Enable/disable chest highlighting
        updateHighlights() -- Update the highlights immediately
        ui.notify({
            title = 'Chest ESP Toggle',
            message = 'Chest ESP toggled to ' .. tostring(newState),
            duration = 3
        })
    end)
end

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
