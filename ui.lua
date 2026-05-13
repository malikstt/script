local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local webhookUrl = "https://discord.com/api/webhooks/1495059756371546345/L3e0gHM3cdJAhq80YGviVwkvNOcJKOKYjerPBRPp2I5mli4FZ7r8vD7-8LPrBqWODKNw"

if not request then
    warn("[ServerFetcher] No request function available. Aborting.")
    return
end

local CONFIG = {
    PLACE_ID       = game.PlaceId,
    LIMIT          = 100,
    MAX_RETRIES    = 5,
    BASE_WAIT      = 0.5,
    BACKOFF_BASE   = 2.0,
    BACKOFF_MAX    = 60,
    CURSOR_RETRIES = 3,
    MAX_PAGES      = 500,
}

local STATE = {
    running         = false,
    stopped         = false,
    filterActive    = false,
    filterEmpty     = false,
    filterHideFull  = false,
    antiAfkEnabled  = false,
    antiAfkConn     = nil,
    jobIdSet        = {},
    jobIdList       = {},
    pageCount       = 0,
    activeCount     = 0,
    emptyCount      = 0,
    duplicateCount  = 0,
    startTime       = 0,
}

local uiLocked  = false
local uiVisible = true

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ServerFetcherUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = gethui and gethui() or game:GetService("CoreGui")

local topbarHeight = 36

local lockBtn = Instance.new("TextButton")
lockBtn.Size = UDim2.new(0, 72, 0, 22)
lockBtn.Position = UDim2.new(0, 10, 0, topbarHeight + 4)
lockBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
lockBtn.BorderSizePixel = 0
lockBtn.Text = "LOCK"
lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
lockBtn.TextSize = 11
lockBtn.Font = Enum.Font.GothamBold
lockBtn.ZIndex = 10
lockBtn.Parent = screenGui
Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(0, 4)

local hideBtn = Instance.new("TextButton")
hideBtn.Size = UDim2.new(0, 80, 0, 22)
hideBtn.Position = UDim2.new(0, 88, 0, topbarHeight + 4)
hideBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
hideBtn.BorderSizePixel = 0
hideBtn.Text = "HIDE UI"
hideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
hideBtn.TextSize = 11
hideBtn.Font = Enum.Font.GothamBold
hideBtn.ZIndex = 10
hideBtn.Parent = screenGui
Instance.new("UICorner", hideBtn).CornerRadius = UDim.new(0, 4)

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 480, 0, 300)
mainFrame.Position = UDim2.new(0, 10, 0, topbarHeight + 32)
mainFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
mainFrame.Parent = screenGui
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 6)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 30)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
titleBar.BorderSizePixel = 0
titleBar.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -12, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Server Fetcher"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local contentFrame = Instance.new("Frame")
contentFrame.Size = UDim2.new(1, 0, 1, -30)
contentFrame.Position = UDim2.new(0, 0, 0, 30)
contentFrame.BackgroundTransparency = 1
contentFrame.Parent = mainFrame

local do_drag = false
local drag_start = Vector2.new()
local frame_start = UDim2.new()

titleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if uiLocked then return end
        do_drag = true
        drag_start = Vector2.new(input.Position.X, input.Position.Y)
        frame_start = mainFrame.Position
    end
end)

titleBar.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        do_drag = false
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if do_drag and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = Vector2.new(input.Position.X - drag_start.X, input.Position.Y - drag_start.Y)
        mainFrame.Position = UDim2.new(
            frame_start.X.Scale,
            frame_start.X.Offset + delta.X,
            frame_start.Y.Scale,
            frame_start.Y.Offset + delta.Y
        )
    end
end)

local function makeToggleRow(parent, yOffset, labelText)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -24, 0, 28)
    row.Position = UDim2.new(0, 12, 0, yOffset)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.65, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 48, 0, 22)
    btn.Position = UDim2.new(1, -48, 0.5, -11)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    btn.BorderSizePixel = 0
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(180, 180, 180)
    btn.TextSize = 11
    btn.Font = Enum.Font.GothamBold
    btn.Parent = row
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)

    local enabled = false
    local function setState(val)
        enabled = val
        if enabled then
            btn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            btn.TextColor3 = Color3.fromRGB(180, 180, 180)
            btn.Text = "OFF"
        end
    end

    return btn, setState, function() return enabled end
end

local function makeInputRow(parent, yOffset, labelText, defaultValue)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, -24, 0, 28)
    row.Position = UDim2.new(0, 12, 0, yOffset)
    row.BackgroundTransparency = 1
    row.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.55, 0, 1, 0)
    lbl.Position = UDim2.new(0, 0, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.TextSize = 12
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = row

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0, 110, 0, 22)
    box.Position = UDim2.new(1, -110, 0.5, -11)
    box.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
    box.BorderSizePixel = 0
    box.Text = defaultValue
    box.TextColor3 = Color3.fromRGB(80, 140, 255)
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.PlaceholderText = "min - max"
    box.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    return box
end

local function makeDivider(parent, yOffset)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -24, 0, 1)
    d.Position = UDim2.new(0, 12, 0, yOffset)
    d.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function parsePair(text, min1, max1, min2, max2)
    local a, b = string.match(text, "^%s*(%d+)%s*%-%s*(%d+)%s*$")
    a, b = tonumber(a), tonumber(b)
    if not a or not b then return nil, nil end
    if min1 then a = math.clamp(a, min1, max1 or math.huge) end
    if min2 then b = math.clamp(b, min2, max2 or math.huge) end
    if a > b then a, b = b, a end
    return a, b
end

local col1 = Instance.new("Frame")
col1.Size = UDim2.new(0.5, -6, 1, 0)
col1.Position = UDim2.new(0, 0, 0, 0)
col1.BackgroundTransparency = 1
col1.Parent = contentFrame

local col2 = Instance.new("Frame")
col2.Size = UDim2.new(0.5, -6, 1, 0)
col2.Position = UDim2.new(0.5, 6, 0, 0)
col2.BackgroundTransparency = 1
col2.Parent = contentFrame

local sectionLabel1 = Instance.new("TextLabel")
sectionLabel1.Size = UDim2.new(1, -24, 0, 20)
sectionLabel1.Position = UDim2.new(0, 12, 0, 6)
sectionLabel1.BackgroundTransparency = 1
sectionLabel1.Text = "TOGGLES"
sectionLabel1.TextColor3 = Color3.fromRGB(120, 120, 120)
sectionLabel1.TextSize = 10
sectionLabel1.Font = Enum.Font.GothamBold
sectionLabel1.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel1.Parent = col1

local toggleActiveBtn, setActiveState, getActiveState = makeToggleRow(col1, 28, "Active Only")
local toggleEmptyBtn, setEmptyState, getEmptyState   = makeToggleRow(col1, 60, "Empty Only")
local toggleHideFullBtn, setHideFullState, getHideFullState = makeToggleRow(col1, 92, "Hide Full Servers")
local toggleAntiAfkBtn, setAntiAfkState, getAntiAfkState    = makeToggleRow(col1, 124, "Anti AFK")

makeDivider(col1, 157)

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -24, 0, 18)
statusLabel.Position = UDim2.new(0, 12, 0, 162)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Status: Idle"
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 11
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Left
statusLabel.Parent = col1

local bottomStatus = Instance.new("TextLabel")
bottomStatus.Size = UDim2.new(1, -24, 0, 34)
bottomStatus.Position = UDim2.new(0, 12, 0, 182)
bottomStatus.BackgroundTransparency = 1
bottomStatus.Text = "Ready."
bottomStatus.TextColor3 = Color3.fromRGB(140, 140, 140)
bottomStatus.TextSize = 10
bottomStatus.Font = Enum.Font.Gotham
bottomStatus.TextXAlignment = Enum.TextXAlignment.Left
bottomStatus.TextWrapped = true
bottomStatus.Parent = col1

local sectionLabel2 = Instance.new("TextLabel")
sectionLabel2.Size = UDim2.new(1, -24, 0, 20)
sectionLabel2.Position = UDim2.new(0, 12, 0, 6)
sectionLabel2.BackgroundTransparency = 1
sectionLabel2.Text = "CONFIG"
sectionLabel2.TextColor3 = Color3.fromRGB(120, 120, 120)
sectionLabel2.TextSize = 10
sectionLabel2.Font = Enum.Font.GothamBold
sectionLabel2.TextXAlignment = Enum.TextXAlignment.Left
sectionLabel2.Parent = col2

local limitBox    = makeInputRow(col2, 28,  "Server Limit",       "1 - 100")
local retriesBox  = makeInputRow(col2, 60,  "Max Retries",        "1 - 5")
local baseWaitBox = makeInputRow(col2, 92,  "Base Wait (s)",      "0 - 2")
local maxPagesBox = makeInputRow(col2, 124, "Max Pages",          "1 - 500")

makeDivider(col2, 157)

local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -24, 0, 28)
btnRow.Position = UDim2.new(0, 12, 0, 162)
btnRow.BackgroundTransparency = 1
btnRow.Parent = col2

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.48, 0, 1, 0)
startBtn.Position = UDim2.new(0, 0, 0, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
startBtn.BorderSizePixel = 0
startBtn.Text = "START"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextSize = 12
startBtn.Font = Enum.Font.GothamBold
startBtn.Parent = btnRow
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 4)

local stopBtn = Instance.new("TextButton")
stopBtn.Size = UDim2.new(0.48, 0, 1, 0)
stopBtn.Position = UDim2.new(0.52, 0, 0, 0)
stopBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
stopBtn.BorderSizePixel = 0
stopBtn.Text = "STOP"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.TextSize = 12
stopBtn.Font = Enum.Font.GothamBold
stopBtn.Parent = btnRow
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 4)

local function setStatus(text)
    statusLabel.Text = "Status: " .. text
end

local function setBottom(text)
    bottomStatus.Text = text
end

local function log(tag, msg)
    print(string.format("[ServerFetcher][%s] %s", tag, msg))
end

local function backoffWait(attempt, isRateLimit)
    local base = isRateLimit and 8 or 0.8
    local wait = math.min(base * (CONFIG.BACKOFF_BASE ^ (attempt - 1)), CONFIG.BACKOFF_MAX)
    local jitter = wait * 0.3 * (math.random() * 2 - 1)
    local final = math.max(0.5, wait + jitter)
    setBottom(string.format("Waiting %.1fs (attempt %d)", final, attempt))
    task.wait(final)
end

local function getReportContent()
    local lines = {
        "=== SERVER STATUS REPORT ===",
        string.format("Total Fetched: %d", #STATE.jobIdList),
        string.format("Active: %d", STATE.activeCount),
        string.format("Empty: %d", STATE.emptyCount),
        string.format("Duplicates Skipped: %d", STATE.duplicateCount),
        "",
        "=== DETAILED LIST ===",
        "",
    }
    for _, server in ipairs(STATE.jobIdList) do
        local skip = false
        if STATE.filterActive and not server.active then skip = true end
        if STATE.filterEmpty and server.active then skip = true end
        if STATE.filterHideFull and server.playing >= server.maxPlayers and server.maxPlayers > 0 then skip = true end
        if not skip then
            table.insert(lines, string.format("%s | %s | %d/%d players",
                server.active and "ACTIVE" or "EMPTY",
                server.id, server.playing, server.maxPlayers))
        end
    end
    return table.concat(lines, "\n")
end

local function sendReport(summaryText, fileContent, filename)
    setStatus("Sending...")
    setBottom("Sending report to Discord...")
    local boundary = "----Boundary" .. tostring(math.random(100000, 999999))
    local payload = HttpService:JSONEncode({ username = "Server Fetcher", content = summaryText })
    local body = "--" .. boundary .. "\r\n"
        .. 'Content-Disposition: form-data; name="payload_json"\r\n'
        .. "Content-Type: application/json\r\n\r\n"
        .. payload .. "\r\n"
        .. "--" .. boundary .. "\r\n"
        .. 'Content-Disposition: form-data; name="file"; filename="' .. filename .. '"\r\n'
        .. "Content-Type: text/plain\r\n\r\n"
        .. fileContent .. "\r\n"
        .. "--" .. boundary .. "--\r\n"
    local success, err = pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = { ["Content-Type"] = "multipart/form-data; boundary=" .. boundary },
            Body = body,
        })
    end)
    if success then
        log("WEBHOOK", "Sent: " .. filename)
        setBottom("Report sent.")
    else
        log("ERROR", "Webhook failed: " .. tostring(err))
        setBottom("Webhook failed.")
    end
end

local function fetchPage(cursor)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?limit=%d",
        CONFIG.PLACE_ID, CONFIG.LIMIT
    )
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end
    for attempt = 1, CONFIG.MAX_RETRIES do
        setBottom(string.format("Fetching page %d (attempt %d)...", STATE.pageCount + 1, attempt))
        local success, response = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)
        if not success then
            log("ERROR", "request threw: " .. tostring(response))
            backoffWait(attempt, false)
        elseif response.StatusCode == 429 then
            log("RATE_LIMIT", "429 on attempt " .. attempt)
            setStatus("Rate Limited")
            backoffWait(attempt, true)
        elseif response.StatusCode ~= 200 then
            log("WARN", "HTTP " .. response.StatusCode)
            backoffWait(attempt, false)
        else
            local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
            if decodeOk and type(data) == "table" and type(data.data) == "table" then
                return data
            end
            backoffWait(attempt, false)
        end
    end
    return nil
end

local function applyConfigFromUI()
    local lMin, lMax = parsePair(limitBox.Text, 1, 100, 1, 100)
    if lMax then CONFIG.LIMIT = lMax end

    local rMin, rMax = parsePair(retriesBox.Text, 1, 20, 1, 20)
    if rMax then CONFIG.MAX_RETRIES = rMax end

    local wMin, wMax = parsePair(baseWaitBox.Text, 0, 10, 0, 10)
    if wMin then CONFIG.BASE_WAIT = wMin end

    local pMin, pMax = parsePair(maxPagesBox.Text, 1, 2000, 1, 2000)
    if pMax then CONFIG.MAX_PAGES = pMax end
end

local function startFetch()
    if STATE.running then return end

    STATE.running       = true
    STATE.stopped       = false
    STATE.jobIdSet      = {}
    STATE.jobIdList     = {}
    STATE.pageCount     = 0
    STATE.activeCount   = 0
    STATE.emptyCount    = 0
    STATE.duplicateCount= 0
    STATE.startTime     = os.clock()

    STATE.filterActive   = getActiveState()
    STATE.filterEmpty    = getEmptyState()
    STATE.filterHideFull = getHideFullState()

    applyConfigFromUI()

    setStatus("Fetching...")
    log("START", string.format("PlaceId %d | Limit %d | MaxPages %d", CONFIG.PLACE_ID, CONFIG.LIMIT, CONFIG.MAX_PAGES))

    task.spawn(function()
        local cursor = nil
        local cursorStallCount = 0

        repeat
            if STATE.stopped then
                log("STOP", "Stopped by user.")
                break
            end

            local data = fetchPage(cursor)

            if not data then
                log("ABORT", "fetchPage returned nil. Stopping.")
                setStatus("Aborted")
                break
            end

            local newThisPage = 0
            for _, server in ipairs(data.data) do
                local id = server.id
                if id then
                    if not STATE.jobIdSet[id] then
                        STATE.jobIdSet[id] = true
                        local playing = server.playing or 0
                        local isActive = playing > 0
                        table.insert(STATE.jobIdList, {
                            id         = id,
                            playing    = playing,
                            maxPlayers = server.maxPlayers or 0,
                            active     = isActive,
                        })
                        newThisPage = newThisPage + 1
                        if isActive then
                            STATE.activeCount = STATE.activeCount + 1
                        else
                            STATE.emptyCount = STATE.emptyCount + 1
                        end
                    else
                        STATE.duplicateCount = STATE.duplicateCount + 1
                    end
                end
            end

            STATE.pageCount = STATE.pageCount + 1
            log("PAGE", string.format("#%d | new=%d | total=%d", STATE.pageCount, newThisPage, #STATE.jobIdList))
            setStatus(string.format("Page %d", STATE.pageCount))
            setBottom(string.format("Fetched %d servers | Active: %d | Empty: %d | Dupes: %d",
                #STATE.jobIdList, STATE.activeCount, STATE.emptyCount, STATE.duplicateCount))

            local nextCursor = nil
            if data.nextPageCursor and data.nextPageCursor ~= "" then
                nextCursor = data.nextPageCursor
            end

            if nextCursor == cursor then
                cursorStallCount = cursorStallCount + 1
                if cursorStallCount >= CONFIG.CURSOR_RETRIES then
                    log("ABORT", "Cursor stuck.")
                    setStatus("Aborted")
                    break
                end
                backoffWait(cursorStallCount, false)
            else
                cursorStallCount = 0
            end

            cursor = nextCursor
            if cursor then
                task.wait(CONFIG.BASE_WAIT)
            end

        until not cursor or STATE.pageCount >= CONFIG.MAX_PAGES or STATE.stopped

        if not STATE.stopped then
            setStatus("Building report...")
            local content = getReportContent()
            local summary = string.format(
                "**Server Fetcher Complete**\nTotal: **%d** | Active: **%d** | Empty: **%d** | Dupes skipped: **%d**",
                #STATE.jobIdList, STATE.activeCount, STATE.emptyCount, STATE.duplicateCount)
            local timestamp = tostring(os.time())
            sendReport(summary, content, "servers_" .. timestamp .. ".txt")
            setStatus("Done")
        else
            local content = getReportContent()
            local summary = string.format(
                "**Server Fetcher Stopped**\nTotal: **%d** | Active: **%d** | Empty: **%d** | Dupes skipped: **%d**",
                #STATE.jobIdList, STATE.activeCount, STATE.emptyCount, STATE.duplicateCount)
            local timestamp = tostring(os.time())
            sendReport(summary, content, "stopped_" .. timestamp .. ".txt")
            setStatus("Stopped")
        end

        STATE.running = false
    end)
end

local function stopFetch()
    if not STATE.running then return end
    STATE.stopped = true
    setStatus("Stopping...")
    setBottom("Stop requested.")
end

local function enableAntiAfk()
    local lp = Players.LocalPlayer
    local VirtualUser = game:GetService("VirtualUser")
    STATE.antiAfkConn = lp.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
    task.wait(1)
    for _, x in pairs(getconnections(lp.Idled)) do
        x:Disable()
    end
end

local function disableAntiAfk()
    if STATE.antiAfkConn then
        STATE.antiAfkConn:Disconnect()
        STATE.antiAfkConn = nil
    end
end

startBtn.MouseButton1Click:Connect(function()
    startFetch()
end)

stopBtn.MouseButton1Click:Connect(function()
    stopFetch()
end)

toggleActiveBtn.MouseButton1Click:Connect(function()
    local val = not getActiveState()
    setActiveState(val)
    STATE.filterActive = val
end)

toggleEmptyBtn.MouseButton1Click:Connect(function()
    local val = not getEmptyState()
    setEmptyState(val)
    STATE.filterEmpty = val
end)

toggleHideFullBtn.MouseButton1Click:Connect(function()
    local val = not getHideFullState()
    setHideFullState(val)
    STATE.filterHideFull = val
end)

toggleAntiAfkBtn.MouseButton1Click:Connect(function()
    local val = not getAntiAfkState()
    setAntiAfkState(val)
    STATE.antiAfkEnabled = val
    if val then
        enableAntiAfk()
    else
        disableAntiAfk()
    end
end)

lockBtn.MouseButton1Click:Connect(function()
    uiLocked = not uiLocked
    if uiLocked then
        lockBtn.TextColor3 = Color3.fromRGB(180, 0, 0)
        lockBtn.Text = "LOCKED"
    else
        lockBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        lockBtn.Text = "LOCK"
    end
end)

hideBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    mainFrame.Visible = uiVisible
    hideBtn.Text = uiVisible and "HIDE UI" or "SHOW UI"
end)
