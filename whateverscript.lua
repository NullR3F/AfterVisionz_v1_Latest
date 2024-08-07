-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Workspace = game.Workspace

-- Variables
local localPlayer = Players.LocalPlayer
local Plr = game.Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ESP Settings
local PlayerESPToggle = false
local boundingBoxEnabled = true
local fillBoxEnabled = true
local nameTextEnabled = true
local distanceTextEnabled = true
local heldItemTextEnabled = true
local MetricSystem = true
local maxDistance = 0
local textSize = 16
local fullBoxTransparency = 0.3
local olddist = 3000
local YPosToggleKey = Enum.KeyCode.X

--
-- TEM DEB
--[[
local cg = game:GetService("CoreGui")
local debugger = Instance.new("TextLabel",cg)
debugger.Size = UDim2.new(0,200,0,200)
debugger.Text = "f"
]]



local function studsToMeters(studs)
    if not MetricSystem then return tostring(math.floor(studs)).."st" end
    local studsPerMeter = 2.56
    local meters = studs / studsPerMeter
    return string.format("%.1fm", meters)
end

-- Colors
local boundingBoxColor = Color3.new(1, 0, 0)
local fillBoxColor = Color3.new(1, 0, 0)
local nameTextColor = Color3.new(1, 1, 1)
local distanceTextColor = Color3.new(1, 1, 1)
local heldItemTextColor = Color3.new(1, 0.5, 0)

-- Firemode Auto
local firemodeAutoEnabled = false
local showinv = false

local function GetSlotsNames(player)
    if not showinv then return "" end
    local invbuild = ""
    for i, v in pairs(player.GunInventory:GetChildren()) do
        if v.Value and v.Value.Name ~= "Fists" and v ~= player.CurrentSelectedObject.Value then
            invbuild = invbuild .. "\n" .. v.Value.Name
        end
    end
    return invbuild
end

-- Function to set slots to "Auto"
local function setSlotsToAuto()
    local gunInventory = localPlayer:FindFirstChild("GunInventory")
    if gunInventory then
        for i = 0, 5 do
            local slot = gunInventory:FindFirstChild("Slot" .. i)
            if slot then
                local fireMode = slot:FindFirstChild("Firemode")
                if fireMode then
                    fireMode.Value = "Auto"
                end
            end
        end
    end
end




local FullbrightEnabled = false
local yPosEnabled = false
local worldvisuals = false

-- WorldVisuals settings
local worldColor = Color3.new(1, 1, 1)
local contrast = 0
local brightness = 0
local saturation = 0

-- Create and configure ColorCorrectionEffect instances
local colorCorrectionSaturation = Instance.new("ColorCorrectionEffect")
colorCorrectionSaturation.Name = "HighSaturation"
colorCorrectionSaturation.Saturation = saturation
colorCorrectionSaturation.Parent = game:GetService("Lighting")

local colorCorrectionContrast = Instance.new("ColorCorrectionEffect")
colorCorrectionContrast.Name = "HighContrast"
colorCorrectionContrast.Contrast = contrast
colorCorrectionContrast.Parent = game:GetService("Lighting")

-- Functions to set WorldVisuals settings
local function SetWorldColor(color)
    worldColor = color
end

local function SetContrast(value)
    contrast = value
    colorCorrectionContrast.Contrast = value
end

local function SetBrightness(value)
    brightness = value
end

local function SetSaturation(value)
    saturation = value
    colorCorrectionSaturation.Saturation = value
end


-- ESP Elements Creation ----------------------------------------------------------------------------------------------------------------
local function createESPBox()
    local elements = {}

    elements.outline = Drawing.new("Square")
    elements.outline.Visible = false
    elements.outline.Color = Color3.new(0, 0, 0)
    elements.outline.Thickness = 1
    elements.outline.Transparency = 1
    elements.outline.ZIndex = 2

    elements.box = Drawing.new("Square")
    elements.box.Visible = false
    elements.box.Color = boundingBoxColor
    elements.box.Thickness = 1
    elements.box.Transparency = 1
    elements.box.ZIndex = 3

    elements.fullBox = Drawing.new("Square")
    elements.fullBox.Visible = false
    elements.fullBox.Color = fillBoxColor
    elements.fullBox.Thickness = 1
    elements.fullBox.Transparency = fullBoxTransparency
    elements.fullBox.Filled = true
    elements.fullBox.ZIndex = 1

    elements.innerOutline = Drawing.new("Square")
    elements.innerOutline.Visible = false
    elements.innerOutline.Color = Color3.new(0, 0, 0)
    elements.innerOutline.Thickness = 1
    elements.innerOutline.Transparency = 1
    elements.innerOutline.ZIndex = 2

    elements.nameTag = Drawing.new("Text")
    elements.nameTag.Visible = false
    elements.nameTag.Color = nameTextColor
    elements.nameTag.Size = textSize
    elements.nameTag.Center = true
    elements.nameTag.Outline = true
    elements.nameTag.Font = Drawing.Fonts.Monospace
    elements.nameTag.ZIndex = 5

    elements.distanceTag = Drawing.new("Text")
    elements.distanceTag.Visible = false
    elements.distanceTag.Color = distanceTextColor
    elements.distanceTag.Size = textSize
    elements.distanceTag.Center = true
    elements.distanceTag.Outline = true
    elements.distanceTag.Font = Drawing.Fonts.Monospace
    elements.distanceTag.ZIndex = 5

    elements.weaponTag = Drawing.new("Text")
    elements.weaponTag.Visible = false
    elements.weaponTag.Color = heldItemTextColor
    elements.weaponTag.Size = textSize
    elements.weaponTag.Center = true
    elements.weaponTag.Outline = true
    elements.weaponTag.Font = Drawing.Fonts.Monospace
    elements.weaponTag.ZIndex = 5

    return elements
end

-- ESP Box Update

local function setVisibility(elements, state)
    for _, element in pairs(elements) do
        element.Visible = state
    end
end

local function setPositionAndSize(element, pos, size)
    element.Position = pos
    element.Size = size
end

local function setColorAndTransparency(element, color, transparency)
    element.Color = color
    element.Transparency = transparency
end

local function updateBoxElements(elements, boxPos, boxSize)
    pcall(function()
    local box = elements.box
    local outline = elements.outline
    local fullBox = elements.fullBox
    local innerOutline = elements.innerOutline

    setPositionAndSize(box, boxPos, boxSize)

    setPositionAndSize(outline, boxPos - Vector2.new(1, 1), boxSize + Vector2.new(2, 2))

    setPositionAndSize(fullBox, boxPos + Vector2.new(1, 1), boxSize - Vector2.new(2, 2))
    setColorAndTransparency(fullBox, fillBoxColor, fullBoxTransparency)

    setPositionAndSize(innerOutline, fullBox.Position, fullBox.Size)
    end)
end

local function updateTextElements(elements, partPos, height, target, distance)
    local nameTag = elements.nameTag
    local weaponTag = elements.weaponTag
    local distanceTag = elements.distanceTag

    nameTag.Position = Vector2.new(partPos.X, partPos.Y - height / 2.5 - 20)
    nameTag.Text = target.Name

    pcall(function()
        weaponTag.Text = target.CurrentSelectedObject.Value.Value.Name .. GetSlotsNames(target)
    end)
    weaponTag.Position = Vector2.new(partPos.X, partPos.Y + height / 2.5 + 25)

    distanceTag.Text = studsToMeters(distance)
    distanceTag.Position = Vector2.new(partPos.X, partPos.Y + height / 2.5 + 10)
end

local function updateESPBox(elements, target)
    if not target or not target.Character then
        setVisibility(elements, false)
        return
    end

    local worldCharacter = target.Character:FindFirstChild("WorldCharacter")
    if not worldCharacter then
        setVisibility(elements, false)
        return
    end

    local part = worldCharacter:FindFirstChild("Torso") or worldCharacter:FindFirstChild("UpperTorso")
    local head = worldCharacter:FindFirstChild("Head")
    if not part or not head then
        setVisibility(elements, false)
        return
    end

    local partPos, onScreen = camera:WorldToViewportPoint(part.Position)
    local headPos = camera:WorldToViewportPoint(head.Position)
    if not onScreen then
        setVisibility(elements, false)
        return
    end

    local distance = (camera.CFrame.Position - part.Position).Magnitude
    if distance > maxDistance then
        setVisibility(elements, false)
        return
    end

    local height = (partPos.Y - headPos.Y) * 4
    local width = height / 2.2
    local boxPos = Vector2.new(partPos.X - width / 2.2, partPos.Y - height / 2.5)
    local boxSize = Vector2.new(width, height)

    if not elements.box.Visible then
        setVisibility(elements, true)
    end

    updateBoxElements(elements, boxPos, boxSize)
    updateTextElements(elements, partPos, height, target, distance)
end

-- Manage ESP for players
local espBoxes = {}

local function addPlayerESP(player)
    pcall(function()
        espBoxes[player] = createESPBox()
    end)
end

local function removePlayerESP(player)
    pcall(function()
        if espBoxes[player] then
            for _, element in pairs(espBoxes[player]) do
                element:Remove()
            end
        end
    end)
end

-- Player events
Players.PlayerAdded:Connect(addPlayerESP)
Players.PlayerRemoving:Connect(removePlayerESP)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= localPlayer then
        addPlayerESP(player)
    end
end

local frameRateCap = 60
local lastUpdate = 0

RunService.Heartbeat:Connect(function()
    --local timeInterval = 1 / frameRateCap
    --lastUpdate = lastUpdate + deltaTime
    --if lastUpdate >= timeInterval then
        for player, elements in pairs(espBoxes) do
            task.spawn(function()
                updateESPBox(elements, player)
            end)
        end
    --    lastUpdate = lastUpdate - timeInterval
    --end
end)

-- HI SANYYY !
-- Functions to toggle ESP elements ---------------------------------------------------------------------------------------------------------------
local function ToggleBoundingBox(state)
    boundingBoxEnabled = state
    if not PlayerESPToggle then
        boundingBoxEnabled = false
    end
    for _, boxes in pairs(espBoxes) do
        boxes[1].Visible = state
        boxes[2].Visible = state
        boxes[4].Visible = state
    end
end

local function ToggleFillBox(state)
    fillBoxEnabled = state
    if not PlayerESPToggle then
        fillBoxEnabled = false
    end
    for _, boxes in pairs(espBoxes) do
        boxes[3].Visible = state
    end
end

local function ToggleNameText(state)
    nameTextEnabled = state
    if not PlayerESPToggle then
        nameTextEnabled = false
    end
    for _, boxes in pairs(espBoxes) do
        boxes[5].Visible = state
    end
end

local function ToggleDistanceText(state)
    distanceTextEnabled = state
    if not PlayerESPToggle then
        distanceTextEnabled = false
    end
    for _, boxes in pairs(espBoxes) do
        boxes[6].Visible = state
    end
end

local function ToggleHeldItemText(state)
    heldItemTextEnabled = state
    if not PlayerESPToggle then
        heldItemTextEnabled = false
    end
    for _, boxes in pairs(espBoxes) do
        boxes[7].Visible = state
    end
end

-- ESP Settings functions
local function SetMaxDistance(value)
    maxDistance = value
end

local function SetTextSize(value)
    textSize = value
    for _, boxes in pairs(espBoxes) do
        boxes[5].Size = value
        boxes[6].Size = value
        boxes[7].Size = value
    end
end

local function SetFullBoxTransparency(value)
    fullBoxTransparency = value * 0.01
    for _, boxes in pairs(espBoxes) do
        boxes[3].Transparency = value
    end
end

local function SetBoundingBoxColor(color)
    boundingBoxColor = color
end

local function SetFillBoxColor(color)
    fillBoxColor = color
end

local function SetNameTextColor(color)
    nameTextColor = color
end

local function SetDistanceTextColor(color)
    distanceTextColor = color
end

local function SetHeldItemTextColor(color)
    heldItemTextColor = color
end

-- Connect to RenderStep

-- Functions to toggle Firemode Auto
function ToggleFiremodeAuto(state)
    firemodeAutoEnabled = state
end

-- Menu and UI
local textDisplays = {
    "AfterVisionz 1.535 (ypos enabled ! <3)",
    "Brought to you by Louve and Sany",
    "Expect Revamped Version soon !"
}

local MenuToggleKey = Enum.KeyCode.K  -- Default key for toggling menu
local DistancePlayerESP = 2000
local DistanceItemESP = 100

local ItemESPToggle = false
local ShowPlayerStuds = true
local ShowItemStuds = true
local TextSizeItemESP = 16

local ColorMisc = Color3.new(1, 1, 1)
local ColorAmmo = Color3.fromRGB(0, 255, 0)
local ColorWeaponry = Color3.fromRGB(255, 255, 0)
local ColorAttachments = Color3.fromRGB(255, 0, 255)

local esp_guns = true
local esp_ammo = true
local esp_misc = true
local esp_attachments = true
local low = {}
local itemLabels = {}

local colorTable = {
    Color3.fromRGB(255, 255, 255),Color3.fromRGB(255, 0, 0), Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 0, 255), Color3.fromRGB(255, 255, 0),
    Color3.fromRGB(0, 255, 255), Color3.fromRGB(255, 0, 255), Color3.fromRGB(192, 192, 192), Color3.fromRGB(128, 0, 0),
    Color3.fromRGB(128, 128, 0), Color3.fromRGB(0, 128, 0), Color3.fromRGB(128, 0, 128), Color3.fromRGB(0, 128, 128),
    Color3.fromRGB(0, 0, 128), Color3.fromRGB(255, 165, 0), Color3.fromRGB(255, 20, 147), Color3.fromRGB(75, 0, 130),
    Color3.fromRGB(139, 69, 19), Color3.fromRGB(255, 69, 0), Color3.fromRGB(173, 216, 230), Color3.fromRGB(0, 191, 255)
}

function playerguienabled(enabled)
    if enabled then
        for i, v in pairs(low) do
            if v:IsA("ScreenGui") then
                v.Enabled = enabled
            end
        end
        low = {}
    else
        for i, v in Players.LocalPlayer.PlayerGui:GetChildren() do
            if v:IsA("ScreenGui") and v.Enabled == true then
                v.Enabled = enabled
                table.insert(low, v)
            end
        end
    end
end

local function CreateMenu()
    local menu = {}

    local function createDrawing(type, properties)
        local drawing = Drawing.new(type)
        for prop, value in pairs(properties) do
            drawing[prop] = value
        end
        drawing.Visible = true
        return drawing
    end

    local viewportSize = Workspace.CurrentCamera.ViewportSize
    local centerX, centerY = viewportSize.X / 2, viewportSize.Y / 2
    local moresize = 60
    menu.Background1 = createDrawing("Square", {Position = Vector2.new(centerX - 270, centerY - 320), Size = Vector2.new(540, 640 + moresize), Color = Color3.fromRGB(17, 17, 17), Thickness = 0, Filled = true, ZIndex = 1})
    menu.Outline1 = createDrawing("Square", {Position = menu.Background1.Position, Size = menu.Background1.Size, Color = Color3.fromRGB(35, 35, 35), Thickness = 1, Filled = false, ZIndex = 2})
    menu.Background2 = createDrawing("Square", {Position = Vector2.new(centerX - 260, centerY - 290), Size = Vector2.new(520, 600 + moresize), Color = Color3.fromRGB(17, 17, 17), Thickness = 0, Filled = true, ZIndex = 3})
    menu.Outline2 = createDrawing("Square", {Position = menu.Background2.Position, Size = menu.Background2.Size, Color = Color3.fromRGB(35, 35, 35), Thickness = 1, Filled = false, ZIndex = 4})
    menu.Background3 = createDrawing("Square", {Position = Vector2.new(centerX - 250, centerY - 280), Size = Vector2.new(500, 580 + moresize), Color = Color3.fromRGB(17, 17, 17), Thickness = 0, Filled = true, ZIndex = 5})
    menu.Outline3 = createDrawing("Square", {Position = menu.Background3.Position, Size = menu.Background3.Size, Color = Color3.fromRGB(35, 35, 35), Thickness = 1, Filled = false, ZIndex = 6})

    menu.Title = createDrawing("Text", {Text = "IF YOU SEE THIS TEXT, SCRIPT DIDNT LOAD CORRECTLY!", Size = 20, Center = true, Outline = true, Font = Drawing.Fonts.Monospace, Color = Color3.fromRGB(0, 255, 255), ZIndex = 7, Position = Vector2.new(centerX, menu.Background3.Position.Y - 35)})

    local tabNames = {"VISUALS", "EXPLOITS", "SETTINGS"}
    menu.Tabs = {}
    menu.TabBackgrounds = {}
    for i, tabName in ipairs(tabNames) do
        local tabBg = createDrawing("Square", {Position = Vector2.new(menu.Background3.Position.X + (i - 0.5) * (menu.Background3.Size.X / #tabNames) - 40, menu.Background3.Position.Y + 25), Size = Vector2.new(80, 30), Color = Color3.fromRGB(50, 50, 50), Thickness = 1, Filled = true, ZIndex = 7})
        local tab = createDrawing("Text", {Text = tabName, Size = 14, Center = true, Outline = true, Font = Drawing.Fonts.Monospace, Color = Color3.fromRGB(0, 255, 255), ZIndex = 8, Position = Vector2.new(tabBg.Position.X + tabBg.Size.X / 2, tabBg.Position.Y + 5)})
        table.insert(menu.TabBackgrounds, tabBg)
        table.insert(menu.Tabs, tab)
    end

    local sections = {
        {name = "PLAYER ESP", type = "checkbox", tab = "VISUALS", callback = function(val) PlayerESPToggle = val; if val then maxDistance = olddist else olddist = maxDistance; maxDistance = 0 end end},
        {name = "Bounding Box", type = "listdropped", tab = "VISUALS", ischecked = true, callback = ToggleBoundingBox, colorCallback = SetBoundingBoxColor, defaultColor = boundingBoxColor},
        {name = "Fill Box", type = "listdropped", tab = "VISUALS", ischecked = true, callback = ToggleFillBox, colorCallback = SetFillBoxColor, defaultColor = fillBoxColor},
        {name = "Transparency", type = "slider", tab = "VISUALS", value = fullBoxTransparency, min = 0, max = 100, callback = SetFullBoxTransparency},
        {name = "Name Text", type = "listdropped", tab = "VISUALS", ischecked = true, callback = ToggleNameText, colorCallback = SetNameTextColor, defaultColor = nameTextColor},
        {name = "Distance Text", type = "listdropped", tab = "VISUALS", ischecked = true, callback = ToggleDistanceText, colorCallback = SetDistanceTextColor, defaultColor = distanceTextColor},
        {name = "Held Item Text", type = "listdropped", tab = "VISUALS", ischecked = true, callback = ToggleHeldItemText, colorCallback = SetHeldItemTextColor, defaultColor = heldItemTextColor},
        {name = "Inventory Text", type = "listdropped", tab = "VISUALS", ischecked = false, callback = function(val) showinv = val end, colorCallback = SetHeldItemTextColor, defaultColor = heldItemTextColor},
        {name = "Text Size", type = "slider", tab = "VISUALS", value = textSize, min = 10, max = 30, callback = SetTextSize},
        {name = "Max Distance", type = "slider", tab = "VISUALS", value = 3000, min = 0, max = 3000, callback = SetMaxDistance},
        {name = "ITEM ESP", type = "checkbox", tab = "VISUALS", callback = function(val) ItemESPToggle = val; REFRESH_ITEMS_ESP() end},
        {name = "Misc", type = "listdrop", tab = "VISUALS", callback = function(val) esp_misc = val end},
        {name = "Ammo", type = "listdrop", tab = "VISUALS", callback = function(val) esp_ammo = val end},
        {name = "Weaponry", type = "listdrop", tab = "VISUALS", callback = function(val) esp_guns = val end},
        {name = "Attachments", type = "listdrop", tab = "VISUALS", callback = function(val) esp_attachments = val end},
        {name = "Item Distance", type = "sliderwithcheckbox", tab = "VISUALS", value = 100, min = 0, max = 500, callback = function(val)
            if type(val) == "number" then
                DistanceItemESP = val
            end
            if type(val) == "boolean" then
                ShowItemStuds = val
            end
        end},
        {name = "Text Size", type = "slider", tab = "VISUALS", value = TextSizeItemESP, min = 10, max = 24, callback = function(val) TextSizeItemESP = val end},
        {name = "WORLDVISUALS", type = "checkbox", tab = "VISUALS", ischecked = false, callback = function(val) worldvisuals = val end},
        {name = "Full Bright", type = "listdropped", tab = "VISUALS", ischecked = false, callback = function(val) FullbrightEnabled = val end},
        {name = "Contrast", type = "slider", tab = "VISUALS", value = contrast, min = 0, max = 2, callback = SetContrast},
        {name = "Brightness", type = "slider", tab = "VISUALS", value = brightness, min = 0, max = 2, callback = SetBrightness},
        {name = "Saturation", type = "slider", tab = "VISUALS", value = saturation, min = 0, max = 2, callback = SetSaturation},
        {name = "Camera FOV", type = "slider", tab = "VISUALS", value = 100, min = 30, max = 120, callback = function(value)
            local fovValue = game.ReplicatedStorage.CustomCharacter.Configuration.Client.cl_default_fov
            fovValue.Value = value
        end},

        -- SETTINGS
        
        {name = "MENUBIND", type = "keybind", tab = "SETTINGS", value = Enum.KeyCode.K, callback = function() end},
        {name = "Metric Units", type = "checkbox", tab = "SETTINGS",ischecked = true, callback = function(val) MetricSystem = val end},
        {name = "ESP - FPS", type = "slider", tab = "SETTINGS", value = frameRateCap, min = 1, max = 240, callback = function(val) frameRateCap = val end},
        -- EXPLOITS
        {name = "Full Auto", type = "listdropped", tab = "EXPLOITS", callback = ToggleFiremodeAuto},
        {name = "Y Pos", type = "sliderwithcheckboxandbind", tab = "EXPLOITS", ischecked = false, value = 5, min = -5,bindvalue = YPosToggleKey, max = 10, callback = function(val)
            if type(val) == "number" then
                yPosValue = val
                setYPos(val)
            end
            if type(val) == "boolean" then
                yPosEnabled = val
            end
        end}
    }

    local sectionYStart = 70
    local sectionHeight = 23.333
    menu.Sections = {}
    local indent = 0
    local LABELCOLOR = Color3.new(1, 1, 1)
    local readjust_by = 0
    local i = 0
    for x, section in ipairs(sections) do
        local sec = {}
        i += 1
        if section.name == "MENUBIND" or section.name == "Full Auto" then
            i = 1
        end

        if section.type == "slider" then
            LABELCOLOR = Color3.new(0.913725, 0.882352, 0.439215)
        else
            LABELCOLOR = Color3.new(1, 1, 1)
        end

        if section.type == "colorpicker" then
            readjust_by = 8.5
        else
            readjust_by = 0
        end

        if section.name == "Bounding Box" then
            indent = 15
        elseif section.name == "Transparency" then
            indent = 15
        elseif section.name == "Name Text" then
            indent = 15
        elseif section.name == "ITEM ESP" then
            indent = 0
        elseif section.name == "Misc" then
            indent = 15
        elseif section.name == "Ammo" then
            indent = 15
        elseif section.name == "Weaponry" then
            indent = 15
        elseif section.name == "Attachments" then
            indent = 15
        elseif section.name == "ITEM DISTANCE" then
            indent = 15
        elseif section.name == "WORLDVISUALS" then
            indent = 0
        elseif section.name == "Full Bright" then
            indent = 15
        elseif section.name == "MENUBIND" or section.name == "Full Auto" then
            indent = 0
        end

        sec.Label = createDrawing("Text", {Text = section.name, Size = 14, Center = false, Outline = true, Font = Drawing.Fonts.Monospace, Color = LABELCOLOR, ZIndex = 7, Position = Vector2.new(menu.Background3.Position.X + 28 + indent + readjust_by, menu.Background3.Position.Y + sectionYStart + (i - 1) * sectionHeight)})

        if section.type == "listdrop" then
            sec.ColorIndex = 1
            sec.Checkbox = createDrawing("Square", {Color = Color3.fromRGB(0, 255, 255) or Color3.fromRGB(50, 50, 50), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(14, 14), Position = Vector2.new(menu.Background3.Position.X + 7 + indent, sec.Label.Position.Y - 2.75)})
            sec.Checked = true
            sec.Callback = section.callback
            sec.ColorPicker = createDrawing("Square", {Color = Color3.new(1, 1, 1), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(25, 14), Position = Vector2.new(menu.Background3.Position.X + 7 + indent + 110, sec.Label.Position.Y - 2.75)})
            if section.name == "Misc" then
                sec.ColorPicker.Color = ColorMisc
            elseif section.name == "Ammo" then
                sec.ColorPicker.Color = ColorAmmo
            elseif section.name == "Weaponry" then
                sec.ColorPicker.Color = ColorWeaponry
            elseif section.name == "Attachments" then
                sec.ColorPicker.Color = ColorAttachments
            end
            sec.CallbackColor = function()
                sec.ColorIndex += 1
                if sec.ColorIndex > #colorTable or sec.ColorIndex < 1 then
                    sec.ColorIndex = 1
                end
                sec.ColorPicker.Color = colorTable[sec.ColorIndex]
                if section.name == "Misc" then
                    ColorMisc = colorTable[sec.ColorIndex]
                elseif section.name == "Ammo" then
                    ColorAmmo = colorTable[sec.ColorIndex]
                elseif section.name == "Weaponry" then
                    ColorWeaponry = colorTable[sec.ColorIndex]
                elseif section.name == "Attachments" then
                    ColorAttachments = colorTable[sec.ColorIndex]
                end
                for _, label in pairs(itemLabels) do
                    if label then
                        label:Remove()
                    end
                end
                itemLabels = {}
                REFRESH_ITEMS_ESP()
            end
            sec.CallbackColorBack = function()
                sec.ColorIndex -= 1
                if sec.ColorIndex > #colorTable or sec.ColorIndex < 1 then
                    sec.ColorIndex = 1
                end
                sec.ColorPicker.Color = colorTable[sec.ColorIndex]
                if section.name == "Misc" then
                    ColorMisc = colorTable[sec.ColorIndex]
                elseif section.name == "Ammo" then
                    ColorAmmo = colorTable[sec.ColorIndex]
                elseif section.name == "Weaponry" then
                    ColorWeaponry = colorTable[sec.ColorIndex]
                elseif section.name == "Attachments" then
                    ColorAttachments = colorTable[sec.ColorIndex]
                end
                for _, label in pairs(itemLabels) do
                    if label then
                        label:Remove()
                    end
                end
                itemLabels = {}
                REFRESH_ITEMS_ESP()
            end

        elseif section.type == "listdropped" then
            sec.Checkbox = createDrawing("Square", {Color = section.ischecked and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(50, 50, 50), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(14, 14), Position = Vector2.new(menu.Background3.Position.X + 7 + indent, sec.Label.Position.Y - 2.75)})
            if section.ischecked == nil then
                section.ischecked = true
            end
            sec.Checked = section.ischecked
            sec.Callback = section.callback

        elseif section.type == "checkbox" then
            sec.Checkbox = createDrawing("Square", {Color = section.ischecked and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(50, 50, 50), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(14, 14), Position = Vector2.new(menu.Background3.Position.X + 7, sec.Label.Position.Y - 2.75)})
            sec.Checked = section.ischecked
            sec.Callback = section.callback
        elseif section.type == "slider" then
            sec.SliderLabel = createDrawing("Text", {Text = tostring(section.value), Size = 14, Center = false, Outline = true, Font = Drawing.Fonts.Monospace, Color = Color3.fromRGB(255, 255, 255), ZIndex = 7, Position = Vector2.new(menu.Background3.Position.X + 410, sec.Label.Position.Y - 1.25)})

            sec.SliderValue = section.value
            sec.SliderMin = section.min
            sec.SliderMax = section.max
            sec.SliderBar = createDrawing("Square", {Color = Color3.fromRGB(80, 78, 78), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(100, 5), Position = Vector2.new(menu.Background3.Position.X + 160, sec.Label.Position.Y + 5)})
            sec.SliderHandle = createDrawing("Square", {Color = Color3.fromRGB(0, 179, 255), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(10, 10), Position = Vector2.new(sec.SliderBar.Position.X + (section.value / section.max) * sec.SliderBar.Size.X - 5, sec.SliderBar.Position.Y - 2.5)})
            sec.Callback = section.callback

            elseif section.type == "sliderwithcheckbox" then
                sec.SliderLabel = createDrawing("Text", {Text = tostring(section.value), Size = 14, Center = false, Outline = true, Font = Drawing.Fonts.Monospace, Color = Color3.fromRGB(255, 255, 255), ZIndex = 7, Position = Vector2.new(menu.Background3.Position.X + 410, sec.Label.Position.Y - 1.25)})
                sec.SliderValue = section.value
                sec.SliderMin = section.min
                sec.SliderMax = section.max
                sec.SliderBar = createDrawing("Square", {Color = Color3.fromRGB(80, 78, 78), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(100, 5), Position = Vector2.new(menu.Background3.Position.X + 160, sec.Label.Position.Y + 5)})
                sec.SliderHandle = createDrawing("Square", {Color = Color3.fromRGB(0, 179, 255), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(10, 10), Position = Vector2.new(sec.SliderBar.Position.X + (section.value / section.max) * sec.SliderBar.Size.X - 5, sec.SliderBar.Position.Y - 2.5)})
                sec.Checkbox = createDrawing("Square", {Color = section.ischecked and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(50, 50, 50), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(14, 14), Position = Vector2.new(menu.Background3.Position.X + 7 + indent, sec.Label.Position.Y - 2.75)})
                sec.Checked = section.ischecked
                sec.Callback = section.callback
            elseif section.type == "sliderwithcheckboxandbind" then
                sec.SliderLabel = createDrawing("Text", {Text = tostring(section.value), Size = 14, Center = false, Outline = true, Font = Drawing.Fonts.Monospace, Color = Color3.fromRGB(255, 255, 255), ZIndex = 7, Position = Vector2.new(menu.Background3.Position.X + 410, sec.Label.Position.Y - 1.25)})
                sec.SliderValue = section.value
                sec.SliderMin = section.min
                sec.SliderMax = section.max
                sec.SliderBar = createDrawing("Square", {Color = Color3.fromRGB(80, 78, 78), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(100, 5), Position = Vector2.new(menu.Background3.Position.X + 160, sec.Label.Position.Y + 5)})
                sec.SliderHandle = createDrawing("Square", {Color = Color3.fromRGB(0, 179, 255), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(10, 10), Position = Vector2.new(sec.SliderBar.Position.X + (section.value / section.max) * sec.SliderBar.Size.X - 5, sec.SliderBar.Position.Y - 2.5)})
                if section.ischecked == nil then
                    section.ischecked = true
                end
                sec.Checkbox = createDrawing("Square", {Color = section.ischecked and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(50, 50, 50), Thickness = 1, Filled = true, ZIndex = 7, Size = Vector2.new(14, 14), Position = Vector2.new(menu.Background3.Position.X + 7 + indent, sec.Label.Position.Y - 2.75)})
                sec.Checked = section.ischecked
                sec.KeybindYP = createDrawing("Text", {Text =  "Bind: "..tostring(section.bindvalue):match("%w+$"), Size = 14, Center = false, Outline = true, Font = Drawing.Fonts.Monospace, Color = Color3.fromRGB(255, 255, 255), ZIndex = 7, Position = Vector2.new(menu.Background3.Position.X + 300, sec.Label.Position.Y)})
                sec.CurrentKey = section.bindvalue
                sec.Binding = false
                sec.Callback = section.callback
        elseif section.type == "keybind" then
            sec.Keybind = createDrawing("Text", {Text = tostring(section.value):match("%w+$"), Size = 14, Center = false, Outline = true, Font = Drawing.Fonts.Monospace, Color = Color3.fromRGB(255, 255, 255), ZIndex = 7, Position = Vector2.new(menu.Background3.Position.X + 300, sec.Label.Position.Y)})
            sec.CurrentKey = section.value
            sec.Binding = false
            sec.Callback = section.callback
        elseif section.type == "section" then
            sec.Label.Text = section.name
            sec.Label.Color = Color3.fromRGB(255, 0, 0)
        end

        sec.Tab = section.tab
        table.insert(menu.Sections, sec)
    end

    menu.CurrentTab = "VISUALS"
    menu.UpdateSections = function(tabName)
        for _, sec in ipairs(menu.Sections) do
            local visible = sec.Tab == tabName
            if sec.Label then sec.Label.Visible = visible end
            if sec.Checkbox then sec.Checkbox.Visible = visible end
            if sec.SliderLabel then sec.SliderLabel.Visible = visible end
            if sec.SliderBar then sec.SliderBar.Visible = visible end
            if sec.SliderHandle then sec.SliderHandle.Visible = visible end
            if sec.Keybind then sec.Keybind.Visible = visible end
            if sec.KeybindYP then sec.KeybindYP.Visible = visible end
            if sec.ColorPicker then sec.ColorPicker.Visible = visible end
        end
    end

    menu.UnloadSections = function(tabName)
        for _, sec in ipairs(menu.Sections) do
            local visible = sec.Tab == tabName
            if sec.Label then sec.Label.Visible = false end
            if sec.Checkbox then sec.Checkbox.Visible = false end
            if sec.SliderLabel then sec.SliderLabel.Visible = false end
            if sec.SliderBar then sec.SliderBar.Visible = false end
            if sec.SliderHandle then sec.SliderHandle.Visible = false end
            if sec.Keybind then sec.Keybind.Visible = false end
            if sec.KeybindYP then sec.KeybindYP.Visible = false end
            if sec.ColorPicker then sec.ColorPicker.Visible = false end
        end
    end

    menu.UpdateSections(menu.CurrentTab)
    return menu
end

local menu = CreateMenu()
local menuVisible = true
local draggingSlider = nil
local itemLabels = {}  -- Table to store item ESP labels

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == MenuToggleKey then
        menuVisible = not menuVisible
        playerguienabled(not menuVisible)
        menu.Background1.Visible = menuVisible
        menu.Outline1.Visible = menuVisible
        menu.Background2.Visible = menuVisible
        menu.Outline2.Visible = menuVisible
        menu.Background3.Visible = menuVisible
        menu.Outline3.Visible = menuVisible
        menu.Title.Visible = menuVisible
        for _, tabBg in ipairs(menu.TabBackgrounds) do
            tabBg.Visible = menuVisible
        end
        for _, tab in ipairs(menu.Tabs) do
            tab.Visible = menuVisible
        end
        if not menuVisible then
            menu.UnloadSections(menu.CurrentTab)
        else
            menu.UpdateSections(menu.CurrentTab)
        end

    elseif input.KeyCode == YPosToggleKey then
        yPosEnabled = not yPosEnabled
    end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local mousePos = UserInputService:GetMouseLocation()

        for i, tabBg in ipairs(menu.TabBackgrounds) do
            if mousePos.X >= tabBg.Position.X and mousePos.X <= tabBg.Position.X + tabBg.Size.X and mousePos.Y >= tabBg.Position.Y and mousePos.Y <= tabBg.Position.Y + tabBg.Size.Y then
                local selectedTab = menu.Tabs[i].Text
                menu.CurrentTab = selectedTab
                menu.UpdateSections(selectedTab)
            end
        end

        for _, sec in ipairs(menu.Sections) do
            if sec.Checkbox and sec.Checkbox.Visible then
                if mousePos.X >= sec.Checkbox.Position.X and mousePos.X <= sec.Checkbox.Position.X + sec.Checkbox.Size.X and mousePos.Y >= sec.Checkbox.Position.Y and mousePos.Y <= sec.Checkbox.Position.Y + sec.Checkbox.Size.Y then
                    sec.Checked = not sec.Checked
                    sec.Checkbox.Color = sec.Checked and Color3.fromRGB(0, 255, 255) or Color3.fromRGB(50, 50, 50)
                    if sec.Callback then sec.Callback(sec.Checked) end
                end
            end

            if sec.ColorPicker and sec.ColorPicker.Visible then
                if mousePos.X >= sec.ColorPicker.Position.X and mousePos.X <= sec.ColorPicker.Position.X + sec.ColorPicker.Size.X and mousePos.Y >= sec.ColorPicker.Position.Y and mousePos.Y <= sec.ColorPicker.Position.Y + sec.ColorPicker.Size.Y then
                    sec.CallbackColor()
                end
            end

            if sec.SliderBar and sec.SliderBar.Visible then
                if mousePos.X >= sec.SliderBar.Position.X and mousePos.X <= sec.SliderBar.Position.X + sec.SliderBar.Size.X and mousePos.Y >= sec.SliderBar.Position.Y and mousePos.Y <= sec.SliderBar.Position.Y + sec.SliderBar.Size.Y then
                    draggingSlider = sec
                end
            end
            -- Check for keybind clicks
            if sec.Keybind and sec.Keybind.Visible then
                if mousePos.X >= sec.Keybind.Position.X and mousePos.X <= sec.Keybind.Position.X + 50 and mousePos.Y >= sec.Keybind.Position.Y and mousePos.Y <= sec.Keybind.Position.Y + 20 then
                    sec.Binding = true
                    sec.Keybind.Text = "Listening..."
                    local function onInputBegan(input, gameProcessed)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            sec.Keybind.Text = input.KeyCode.Name
                            task.spawn(task.delay(1, function() MenuToggleKey = input.KeyCode end))
                            return true -- Breaks out of the function
                        end
                        return false -- Keeps the connection if not broken
                    end
                    UserInputService.InputBegan:Once(function(input, gameProcessed)
                        onInputBegan(input, gameProcessed)
                    end)
                end
            end

            if sec.KeybindYP and sec.KeybindYP.Visible then
                if mousePos.X >= sec.KeybindYP.Position.X and mousePos.X <= sec.KeybindYP.Position.X + 50 and mousePos.Y >= sec.KeybindYP.Position.Y and mousePos.Y <= sec.KeybindYP.Position.Y + 20 then
                    sec.Binding = true
                    sec.KeybindYP.Text = "Listening..."
                    local function onInputBegan(input, gameProcessed)
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            sec.KeybindYP.Text = input.KeyCode.Name
                            task.spawn(task.delay(1, function() YPosToggleKey = input.KeyCode end))
                            return true -- Breaks out of the function
                        end
                        return false -- Keeps the connection if not broken
                    end
                    UserInputService.InputBegan:Once(function(input, gameProcessed)
                        onInputBegan(input, gameProcessed)
                    end)
                end
            end

        end
    end
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        local mousePos = UserInputService:GetMouseLocation()
        for _, sec in ipairs(menu.Sections) do
            if sec.ColorPicker and sec.ColorPicker.Visible then
                if mousePos.X >= sec.ColorPicker.Position.X and mousePos.X <= sec.ColorPicker.Position.X + sec.ColorPicker.Size.X and mousePos.Y >= sec.ColorPicker.Position.Y and mousePos.Y <= sec.ColorPicker.Position.Y + sec.ColorPicker.Size.Y then
                    sec.CallbackColorBack()
                end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
    end
end)

RunService.RenderStepped:Connect(function()
    if draggingSlider then
        local mousePos = UserInputService:GetMouseLocation()
        local sliderPos = draggingSlider.SliderBar.Position
        local sliderSize = draggingSlider.SliderBar.Size
        local sliderWidth = sliderSize.X
        local relativeX = mousePos.X - sliderPos.X
        local normalizedValue = math.clamp(relativeX / sliderWidth, 0, 1)
        local newValue = draggingSlider.SliderMin + normalizedValue * (draggingSlider.SliderMax - draggingSlider.SliderMin)
        draggingSlider.SliderValue = newValue
        draggingSlider.SliderLabel.Text = tostring(math.floor(newValue))
        draggingSlider.SliderHandle.Position = Vector2.new(sliderPos.X + normalizedValue * sliderWidth - 5, draggingSlider.SliderHandle.Position.Y)
        if draggingSlider.Callback then draggingSlider.Callback(newValue) end
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not sec then return end
        for _, sec in ipairs(menu.Sections) do
            if sec.SliderBar and sec.SliderBar.Visible then
                local mousePos = UserInputService:GetMouseLocation()
                local sliderPos = sec.SliderBar.Position
                local sliderSize = sec.SliderBar.Size
                local margin = 10 * 2

                if mousePos.X >= (sliderPos.X - margin) and mousePos.X <= (sliderPos.X + sliderSize.X + margin) and
                   mousePos.Y >= (sliderPos.Y - margin) and mousePos.Y <= (sliderPos.Y + sliderSize.Y + margin) then
                    draggingSlider = sec
                end
            end
        end
    end
end)

local function animateText(display, text, repeatCount, delay)
    local animatedRandom = "1234567890"
    for i = 1, #text do
        local revealChar = text:sub(i, i)
        local displayText = text:sub(1, i - 1)

        for _ = 1, math.random(1, 6) do
            local fuckmath = math.random(1, #animatedRandom)
            local randomChar = animatedRandom:sub(fuckmath, fuckmath)
            display.Text = displayText .. randomChar
            task.wait(delay)
        end
        display.Text = displayText .. revealChar
        task.wait(delay)
    end
end

task.spawn(function()
    local repeatCount = 10
    local delay = 0.05
    while true do
        for _, text in ipairs(textDisplays) do
            animateText(menu.Title, text, repeatCount, delay)
            task.wait(5)
        end
    end
end)


-- ESP Connections Management
local playerESPConnections = {}
local itemESPConnections = {}

function UpdatePlayerESP(player, head, nameLabel, frame, bbg)
    playerESPConnections[player] = RunService.RenderStepped:Connect(function()
        local localPlayer = Players.LocalPlayer
        local localCharacter = localPlayer.Character

        if localCharacter then
            local localHead = localCharacter:FindFirstChild("WorldCharacter") and localCharacter.WorldCharacter:FindFirstChild("Head")
            if localHead then
                local distance = (head.Position - localHead.Position).Magnitude
                if ShowPlayerStuds then
                    nameLabel.Text = player.Name .. "\n" .. studsToMeters(distance)
                else
                    nameLabel.Text = player.Name
                end
                if distance > tonumber(DistancePlayerESP) or not PlayerESPToggle then
                    frame.Visible = false
                else
                    frame.Visible = true
                end
            end
        end
    end)
end

function CreateESP(player)
    pcall(function()
        if player == Players.LocalPlayer then return end

        local findesp = Workspace:FindFirstChild("ESP" .. player.Name)
        if findesp and not findesp.Adornee then
            if playerESPConnections[player] then
                playerESPConnections[player]:Disconnect()
            end
            findesp:Destroy()
        elseif findesp and findesp.Adornee then
            return
        end

        local character = player.Character
        if character then
            local worldCharacter = character:FindFirstChild("WorldCharacter")
            if worldCharacter then
                local head = worldCharacter:FindFirstChild("Head")
                if head then
                    local billboardGui = Instance.new("BillboardGui")
                    billboardGui.Name = "ESP" .. player.Name
                    billboardGui.Adornee = head
                    billboardGui.Size = UDim2.new(0, 100, 0, 50)
                    billboardGui.StudsOffset = Vector3.new(0, 3, 0)
                    billboardGui.Parent = Workspace
                    billboardGui.AlwaysOnTop = true

                    local frame = Instance.new("Frame")
                    frame.Size = UDim2.new(1, 0, 1, 0)
                    frame.BackgroundColor3 = Color3.new(0, 0, 0)
                    frame.BackgroundTransparency = 1
                    frame.Parent = billboardGui

                    local nameLabel = Instance.new("TextLabel")
                    nameLabel.Size = UDim2.new(1, 0, 1, 0)
                    nameLabel.Text = player.Name
                    nameLabel.TextSize = 16
                    nameLabel.TextColor3 = Color3.new(1, 0.2, 0.2)
                    nameLabel.Parent = frame
                    nameLabel.Font = Enum.Font.RobotoMono
                    nameLabel.TextStrokeTransparency = 0
                    nameLabel.TextStrokeColor3 = Color3.new(0.1, 0.1, 0.1)
                    nameLabel.BackgroundTransparency = 1

                    UpdatePlayerESP(player, head, nameLabel, frame, billboardGui)
                end
            end
        end
    end)
end

local lastUpdateItem = 0
function CreateItemESP(item)
    local mainPart = item:FindFirstChild("main") or item:FindFirstChild("Main") or item:FindFirstChildWhichIsA("BasePart")
    if mainPart and not mainPart.Name:match("_") and not mainPart.Name:match("StopSign") and not mainPart.Name:match("CantParkHere") and not mainPart.Name:match("LargeFence") then

        local espLabel = Drawing.new("Text")
        espLabel.Size = TextSizeItemESP
        espLabel.Color = Color3.new(1, 1, 1)
        espLabel.Outline = true
        espLabel.Center = true
        espLabel.Font = Drawing.Fonts.Monospace
        espLabel.Visible = false

        itemLabels[item] = espLabel

        if itemESPConnections[item] then
            itemESPConnections[item]:Disconnect()
        end

        itemESPConnections[item] = RunService.RenderStepped:Connect(function(deltaTime)
            lastUpdateItem = lastUpdateItem + deltaTime
            local timeInterval = 1 / frameRateCap
            if lastUpdateItem >= timeInterval then
                if not mainPart.Parent or not ItemESPToggle then
                    espLabel.Visible = false
                    itemESPConnections[item]:Disconnect()
                    itemESPConnections[item] = nil
                    return
                end

                local localPlayer = Players.LocalPlayer
                local localCharacter = localPlayer.Character
                if localCharacter then
                    local localHead = localCharacter:FindFirstChildWhichIsA("BasePart")
                    if localHead then
                        local distance = (mainPart.Position - localHead.Position).Magnitude
                        local itemType = "Misc"
                        if string.match(item.Name, "Ammo") then
                            itemType = "Ammo"
                        elseif item.Name == "WorldModel" then
                            itemType = "Weapons"
                        elseif item.Name == "DataModel" then
                            itemType = "Attachments"
                        elseif item.Name == "WorldData" then
                            itemType = "Attachments"
                        end

                        if (itemType == "Weapons" and not esp_guns) or
                            (itemType == "Ammo" and not esp_ammo) or
                            (itemType == "Misc" and not esp_misc) or
                            (itemType == "Attachments" and not esp_attachments) or
                            distance > DistanceItemESP then
                            espLabel.Visible = false
                        else
                            local screenPos, onScreen = Workspace.CurrentCamera:WorldToViewportPoint(mainPart.Position)
                            if onScreen then
                                espLabel.Position = Vector2.new(screenPos.X, screenPos.Y)
                                espLabel.Size = TextSizeItemESP
                                if ShowItemStuds then
                                    espLabel.Text = item.Name .. "\n" .. studsToMeters(distance)
                                else
                                    espLabel.Text = item.Name
                                end
                                if itemType == "Ammo" then
                                    espLabel.Color = ColorAmmo
                                elseif itemType == "Weapons" then
                                    espLabel.Color = ColorWeaponry
                                    if ShowItemStuds then
                                        espLabel.Text = "Weapon" .. "\n" .. studsToMeters(distance)
                                    else
                                        espLabel.Text = "Weapon"
                                    end
                                elseif itemType == "Attachments" then
                                    espLabel.Color = ColorAttachments
                                    if ShowItemStuds then
                                        espLabel.Text = "Attachment" .. "\n" .. studsToMeters(distance)
                                    else
                                        espLabel.Text = "Attachment"
                                    end
                                else
                                    espLabel.Color = ColorMisc
                                end
                                espLabel.Visible = true
                            else
                                espLabel.Visible = false
                            end
                        end
                    end
                else
                    espLabel.Visible = false
                end

                lastUpdateItem = lastUpdateItem - timeInterval
            end
        end)
    end
end

function INIT_PLAYERS_ESP()
    task.spawn(function()
        while true do
            for i, v in Players:GetPlayers() do
                CreateESP(v)
                task.wait()
            end
            task.wait(3)
        end
    end)
end

function INIT_ITEMS_ESP()
    local items = Workspace:FindFirstChild("world_assets") and Workspace.world_assets:FindFirstChild("StaticObjects") and Workspace.world_assets.StaticObjects:FindFirstChild("Misc")
    if items then
        REFRESH_ITEMS_ESP()
        items.ChildAdded:Connect(function(child)
            CreateItemESP(child)
        end)
    end
    task.spawn(function()
        for _, x in items:GetChildren() do
            task.spawn(function()
                CreateItemESP(x)
            end)
            task.wait()
        end
    end)
end

function REFRESH_ITEMS_ESP()
    local items = Workspace:FindFirstChild("world_assets") and Workspace.world_assets:FindFirstChild("StaticObjects") and Workspace.world_assets.StaticObjects:FindFirstChild("Misc")
    if items then
        for _, x in items:GetChildren() do
            task.spawn(function()
                CreateItemESP(x)
            end)
        end
    end
end

-- INIT_PLAYERS_ESP()
INIT_ITEMS_ESP()
