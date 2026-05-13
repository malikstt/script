local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")
local TweenService = game:GetService("TweenService")
local lp = Players.LocalPlayer

local webhookUrl = "https://discord.com/api/webhooks/1495059756371546345/L3e0gHM3cdJAhq80YGviVwkvNOcJKOKYjerPBRPp2I5mli4FZ7r8vD7-8LPrBqWODKNw"

if not request then
    warn("No request function available")
    return
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerFetcher"
screenGui.ResetOnSpawn = false
screenGui.Parent = gethui and gethui() or game:GetService("CoreGui")

local main = Instance.new("Frame")
main.Size = UDim2.new(0, 520, 0, 120)
main.Position = UDim2.new(0.5, -260, 0.5, -60)
main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
main.BorderSizePixel = 0
main.Parent = screenGui
Instance.new("UICorner", main).CornerRadius = UDim.new(0, 8)

local dragging = false
local dragStart
local frameStart
local isLocked = false

main.InputBegan:Connect(function(input)
    if isLocked then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        frameStart = main.Position
    end
end)

main.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and not isLocked and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        local newX = math.clamp(frameStart.X.Offset + delta.X, 0, screenGui.AbsoluteSize.X - main.AbsoluteSize.X)
        local newY = math.clamp(frameStart.Y.Offset + delta.Y, 0, screenGui.AbsoluteSize.Y - main.AbsoluteSize.Y)
        main.Position = UDim2.new(0, newX, 0, newY)
    end
end)

local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(0, 60, 0, 30)
lockBtn.Position = UDim2.new(0, 8, 0, 8)
lockBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
lockBtn.Text = "LOCK"
lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBtn.TextSize = 11
lockBtn.Font = Enum.Font.GothamBold
lockBtn.BorderSizePixel = 0
lockBtn.Parent = main
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 6)

lockBtn.MouseButton1Click:Connect(function()
    isLocked = not isLocked
    if isLocked then
        lockBtn.Text = "UNLOCK"
        lockBtn.BackgroundColor3 = Color3.fromRGB(80, 40, 40)
    else
        lockBtn.Text = "LOCK"
        lockBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
    end
end)

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 70, 0, 30)
hideBtn.Position = UDim2.new(1, -78, 0, 8)
hideBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
hideBtn.Text = "HIDE UI"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.TextSize = 11
hideBtn.Font = Enum.Font.GothamBold
hideBtn.BorderSizePixel = 0
hideBtn.Parent = main
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 6)

local uiVisible = true
hideBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    main.Visible = uiVisible
    if uiVisible then
        hideBtn.Text = "HIDE UI"
    else
        hideBtn.Text = "SHOW UI"
    end
end)

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0, 70, 0, 30)
startBtn.Position = UDim2.new(0, 8, 0, 46)
startBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
startBtn.Text = "START"
startBtn.TextColor3 = Color3.fromRGB(100, 255, 140)
startBtn.TextSize = 11
startBtn.Font = Enum.Font.GothamBold
startBtn.BorderSizePixel = 0
startBtn.Parent = main
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 6)

local running = false
local fetchThread = nil

local function makeToggle(xPos, yPos, text, defaultColor)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 90, 0, 30)
    container.Position = UDim2.new(0, xPos, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = main
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 70, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(200, 200, 220)
    label.TextSize = 11
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggle = Instance.new("Frame")
    toggle.Size = UDim2.new(0, 20, 0, 20)
    toggle.Position = UDim2.new(1, -20, 0, 5)
    toggle.BackgroundColor3 = defaultColor or Color3.fromRGB(45, 45, 55)
    toggle.BorderSizePixel = 0
    toggle.Parent = container
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(1, 0)
    
    local circle = Instance.new("Frame")
    circle.Size = UDim2.new(0, 16, 0, 16)
    circle.Position = UDim2.new(0, 2, 0, 2)
    circle.BackgroundColor3 = Color3.fromRGB(200, 200, 220)
    circle.BorderSizePixel = 0
    circle.Parent = toggle
    Instance.new("UICorner", circle).CornerRadius = UDim.new(1, 0)
    
    local state = false
    
    local function updateToggle()
        if state then
            TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(60, 140, 220)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.15), {Position = UDim2.new(0, 18, 0, 2)}):Play()
        else
            TweenService:Create(toggle, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(45, 45, 55)}):Play()
            TweenService:Create(circle, TweenInfo.new(0.15), {Position = UDim2.new(0, 2, 0, 2)}):Play()
        end
    end
    
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, 0, 1, 0)
    button.BackgroundTransparency = 1
    button.Text = ""
    button.Parent = container
    
    button.MouseButton1Click:Connect(function()
        state = not state
        updateToggle()
    end)
    
    updateToggle()
    
    return function()
        return state
    end, function(newState)
        state = newState
        updateToggle()
    end
end

local function makeNumberBox(xPos, yPos, label, default)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 80, 0, 30)
    container.Position = UDim2.new(0, xPos, 0, yPos)
    container.BackgroundTransparency = 1
    container.Parent = main
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 0, 14)
    textLabel.Position = UDim2.new(0, 0, 0, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = label
    textLabel.TextColor3 = Color3.fromRGB(150, 150, 180)
    textLabel.TextSize = 9
    textLabel.Font = Enum.Font.Gotham
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Parent = container
    
    local box = Instance.new("TextBox")
    box.Size = UDim2.new(1, 0, 0, 18)
    box.Position = UDim2.new(0, 0, 0, 12)
    box.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    box.Text = tostring(default)
    box.TextColor3 = Color3.fromRGB(100, 180, 255)
    box.TextSize = 11
    box.Font = Enum.Font.Gotham
    box.BorderSizePixel = 0
    box.Parent = container
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    
    local value = default
    
    box.FocusLost:Connect(function(enterPressed)
        if enterPressed then
            local num = tonumber(box.Text)
            if num then
                value = num
            else
                box.Text = tostring(value)
            end
        end
    end)
    
    return function()
        return value
    end, function(newValue)
        value = newValue
        box.Text = tostring(value)
    end
end

local getActiveOnly, setActiveOnly = makeToggle(85, 46, "ACTIVE ONLY", Color3.fromRGB(45, 45, 55))
local getEmptyOnly, setEmptyOnly = makeToggle(180, 46, "EMPTY ONLY", Color3.fromRGB(45, 45, 55))
local getHideFull, setHideFull = makeToggle(275, 46, "HIDE FULL", Color3.fromRGB(45, 45, 55))
local getAntiAFK, setAntiAFK = makeToggle(370, 46, "ANTI AFK", Color3.fromRGB(45, 45, 55))

local getMinPlayers, setMinPlayers = makeNumberBox(85, 80, "MIN", 1)
local getMaxPlayers, setMaxPlayers = makeNumberBox(175, 80, "MAX", 100)
local getFetchDelay, setFetchDelay = makeNumberBox(265, 80, "DELAY(MS)", 500)

local statusText = Instance.new("TextLabel")
statusText.Size = UDim2.new(0, 120, 0, 20)
statusText.Position = UDim2.new(1, -128, 0, 55)
statusText.BackgroundTransparency = 1
statusText.Text = "IDLE"
statusText.TextColor3 = Color3.fromRGB(200, 200, 200)
statusText.TextSize = 10
statusText.Font = Enum.Font.Gotham
statusText.TextXAlignment = Enum.TextXAlignment.Right
statusText.Parent = main

local serverCount = Instance.new("TextLabel")
serverCount.Size = UDim2.new(0, 120, 0, 20)
serverCount.Position = UDim2.new(1, -128, 0, 75)
serverCount.BackgroundTransparency = 1
serverCount.Text = "SERVERS: 0"
serverCount.TextColor3 = Color3.fromRGB(100, 200, 255)
serverCount.TextSize = 10
serverCount.Font = Enum.Font.Gotham
serverCount.TextXAlignment = Enum.TextXAlignment.Right
serverCount.Parent = main

local antiAFKConnection = nil

local function enableAntiAFK()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
    
    for _, x in pairs(getconnections(lp.Idled)) do
        x:Disable()
    end
    
    antiAFKConnection = lp.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(0.5)
        VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end)
end

local function disableAntiAFK()
    if antiAFKConnection then
        antiAFKConnection:Disconnect()
        antiAFKConnection = nil
    end
end

local function fetchServers()
    local jobIdSet = {}
    local jobIdList = {}
    local duplicateCount = 0
    local activeCount = 0
    local emptyCount = 0
    local pageCount = 0
    local cursor = nil
    
    statusText.Text = "FETCHING..."
    statusText.TextColor3 = Color3.fromRGB(255, 200, 100)
    
    repeat
        local url = string.format("https://games.roblox.com/v1/games/%d/servers/Public?limit=100", game.PlaceId)
        if cursor and cursor ~= "" then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end
        
        local success, response = pcall(function()
            return request({Url = url, Method = "GET"})
        end)
        
        if not success or response.StatusCode ~= 200 then
            statusText.Text = "ERROR"
            statusText.TextColor3 = Color3.fromRGB(255, 80, 80)
            return
        end
        
        local data = HttpService:JSONDecode(response.Body)
        
        for _, server in ipairs(data.data) do
            local id = server.id
            if id and not jobIdSet[id] then
                local playing = server.playing or 0
                local maxPlayers = server.maxPlayers or 0
                local minPlayers = getMinPlayers()
                local maxPlayersLimit = getMaxPlayers()
                
                if playing >= minPlayers and playing <= maxPlayersLimit then
                    local isActive = playing > 0
                    local skip = false
                    
                    if getActiveOnly() and not isActive then skip = true end
                    if getEmptyOnly() and isActive then skip = true end
                    if getHideFull() and playing >= maxPlayers and maxPlayers > 0 then skip = true end
                    
                    if not skip then
                        jobIdSet[id] = true
                        table.insert(jobIdList, {
                            id = id,
                            playing = playing,
                            maxPlayers = maxPlayers,
                            active = isActive
                        })
                        
                        if isActive then
                            activeCount = activeCount + 1
                        else
                            emptyCount = emptyCount + 1
                        end
                    end
                end
            else
                duplicateCount = duplicateCount + 1
            end
        end
        
        pageCount = pageCount + 1
        serverCount.Text = string.format("SERVERS: %d", #jobIdList)
        
        cursor = data.nextPageCursor
        
        if cursor and running then
            task.wait(getFetchDelay() / 1000)
        end
        
        if pageCount >= 500 then break end
        
    until not cursor or not running
    
    if not running then return end
    
    local lines = {"SERVER REPORT"}
    table.insert(lines, string.format("Total: %d", #jobIdList))
    table.insert(lines, string.format("Active: %d", activeCount))
    table.insert(lines, string.format("Empty: %d", emptyCount))
    table.insert(lines, string.format("Duplicates: %d", duplicateCount))
    table.insert(lines, "")
    table.insert(lines, "DETAILS:")
    
    for _, server in ipairs(jobIdList) do
        table.insert(lines, string.format("%s | %s | %d/%d",
            server.active and "ACTIVE" or "EMPTY",
            string.sub(server.id, 1, 8),
            server.playing, server.maxPlayers))
    end
    
    local content = table.concat(lines, "\n")
    local summary = string.format("**Server Fetcher Complete**\nTotal: %d | Active: %d | Empty: %d",
        #jobIdList, activeCount, emptyCount)
    local boundary = "boundary" .. tostring(math.random(100000, 999999))
    
    local payload = HttpService:JSONEncode({username = "Server Fetcher", content = summary})
    local body = "--" .. boundary .. "\r\n"
        .. 'Content-Disposition: form-data; name="payload_json"\r\n'
        .. "Content-Type: application/json\r\n\r\n"
        .. payload .. "\r\n"
        .. "--" .. boundary .. "\r\n"
        .. 'Content-Disposition: form-data; name="file"; filename="servers.txt"\r\n'
        .. "Content-Type: text/plain\r\n\r\n"
        .. content .. "\r\n"
        .. "--" .. boundary .. "--\r\n"
    
    pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "multipart/form-data; boundary=" .. boundary},
            Body = body,
        })
    end)
    
    statusText.Text = "DONE"
    statusText.TextColor3 = Color3.fromRGB(100, 255, 140)
end

startBtn.MouseButton1Click:Connect(function()
    if running then
        running = false
        startBtn.Text = "START"
        startBtn.TextColor3 = Color3.fromRGB(100, 255, 140)
        statusText.Text = "STOPPED"
        statusText.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        if getAntiAFK() then
            disableAntiAFK()
        end
    else
        running = true
        startBtn.Text = "STOP"
        startBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
        
        if getAntiAFK() then
            enableAntiAFK()
        end
        
        task.spawn(function()
            fetchServers()
            if running then
                running = false
                startBtn.Text = "START"
                startBtn.TextColor3 = Color3.fromRGB(100, 255, 140)
            end
        end)
    end
end)

local antiAFKCheck = nil
antiAFKCheck = game:GetService("RunService").Stepped:Connect(function()
    if getAntiAFK() and running then
        enableAntiAFK()
    elseif not getAntiAFK() then
        disableAntiAFK()
    end
end)
