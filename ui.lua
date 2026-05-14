local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")

local webhookUrl = "https://discord.com/api/webhooks/1503019592258424942/58mydsCKdv3lieuUsebXNu2kLBT9aenLVZJ36y5zZ1uKFqNMRmnKn1ORgabStBrStYkg"

if not request then
    warn("nigga pls switch to a real executor ")
    return
end

local CONFIG = {
    PLACE_ID       = game.PlaceId,
    LIMIT          = 100,
    MAX_RETRIES    = 3,
    BASE_WAIT      = 0.3,
    BACKOFF_BASE   = 1.5,
    BACKOFF_MAX    = 30,
    CURSOR_RETRIES = 3,
    MAX_PAGES      = 100,
}

local RATE = {
    consecutiveSuccess = 0,
    consecutiveFail    = 0,
    currentWait        = 0.15,  
    minWait            = 0.15,
    maxWait            = 12.0,
    rateLimitHits      = 0,
    lastRateLimitTime  = 0,
    cooldownActive     = false,
    cooldownUntil      = 0,
}

local STATE = {
    running         = false,
    stopped         = false,
    filterActive    = false,
    filterEmpty     = false,
    filterHideFull  = false,
    antiIdleEnabled = false,
    antiIdleConn    = nil,
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
titleLabel.Size = UDim2.new(0.5, -12, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Server Fetcher"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = titleBar

local titleStatus = Instance.new("TextLabel")
titleStatus.Size = UDim2.new(0.5, -12, 1, 0)
titleStatus.Position = UDim2.new(0.5, 0, 0, 0)
titleStatus.BackgroundTransparency = 1
titleStatus.Text = "STATUS: Idle"
titleStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
titleStatus.TextSize = 11
titleStatus.Font = Enum.Font.Gotham
titleStatus.TextXAlignment = Enum.TextXAlignment.Right
titleStatus.Parent = titleBar

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

local function makeNumericInput(parent, yOffset, labelText, defaultValue, minVal, maxVal)
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
    box.Text = tostring(defaultValue)
    box.TextColor3 = Color3.fromRGB(80, 140, 255)
    box.TextSize = 12
    box.Font = Enum.Font.Gotham
    box.ClearTextOnFocus = false
    box.PlaceholderText = tostring(defaultValue)
    box.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
    box.Parent = row
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)

    local function setValue(val)
        local num = tonumber(val)
        if num then
            num = math.clamp(num, minVal, maxVal)
            box.Text = tostring(num)
            return num
        else
            box.Text = tostring(defaultValue)
            return defaultValue
        end
    end

    box.Focused:Connect(function()
        if box.Text == tostring(defaultValue) then
            box.Text = ""
        end
    end)

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if not num then
            box.Text = tostring(defaultValue)
        else
            num = math.clamp(num, minVal, maxVal)
            box.Text = tostring(num)
        end
    end)

    return box, setValue
end

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
    setState(false)

    return btn, setState, function() return enabled end
end

local function makeDivider(parent, yOffset)
    local d = Instance.new("Frame")
    d.Size = UDim2.new(1, -24, 0, 1)
    d.Position = UDim2.new(0, 12, 0, yOffset)
    d.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    d.BorderSizePixel = 0
    d.Parent = parent
end

local function createPopup(title, message, buttons)
    local overlay = Instance.new("Frame")
    overlay.Size = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.6
    overlay.Parent = screenGui
    overlay.ZIndex = 20

    local popup = Instance.new("Frame")
    popup.Size = UDim2.new(0, 280, 0, 140)
    popup.Position = UDim2.new(0.5, -140, 0.5, -70)
    popup.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    popup.BorderSizePixel = 0
    popup.Parent = overlay
    popup.ZIndex = 21
    Instance.new("UICorner", popup).CornerRadius = UDim.new(0, 8)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, 0, 0, 32)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    titleLabel.Text = title
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.TextSize = 14
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.Parent = popup
    titleLabel.ZIndex = 21
    Instance.new("UICorner", titleLabel).CornerRadius = UDim.new(0, 8)

    local msgLabel = Instance.new("TextLabel")
    msgLabel.Size = UDim2.new(1, -20, 0, 50)
    msgLabel.Position = UDim2.new(0, 10, 0, 40)
    msgLabel.BackgroundTransparency = 1
    msgLabel.Text = message
    msgLabel.TextColor3 = Color3.fromRGB(220, 220, 220)
    msgLabel.TextSize = 12
    msgLabel.Font = Enum.Font.Gotham
    msgLabel.TextWrapped = true
    msgLabel.Parent = popup
    msgLabel.ZIndex = 21

    local btnContainer = Instance.new("Frame")
    btnContainer.Size = UDim2.new(1, -20, 0, 30)
    btnContainer.Position = UDim2.new(0, 10, 1, -40)
    btnContainer.BackgroundTransparency = 1
    btnContainer.Parent = popup
    btnContainer.ZIndex = 21

    local function close()
        overlay:Destroy()
    end

    local btnWidth = (#buttons == 2 and 0.48) or 0.9
    local startX = (#buttons == 2 and 0) or 0.05
    for i, btnData in ipairs(buttons) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(btnWidth, 0, 1, 0)
        btn.Position = UDim2.new(startX + (i-1) * (btnWidth + 0.04), 0, 0, 0)
        btn.BackgroundColor3 = btnData.color or Color3.fromRGB(60, 60, 60)
        btn.BorderSizePixel = 0
        btn.Text = btnData.text
        btn.TextColor3 = Color3.fromRGB(255, 255, 255)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamBold
        btn.Parent = btnContainer
        btn.ZIndex = 21
        Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
        btn.MouseButton1Click:Connect(function()
            close()
            if btnData.callback then btnData.callback() end
        end)
    end
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
local toggleAntiIdleBtn, setAntiIdleState, getAntiIdleState = makeToggleRow(col1, 124, "Idle Protection")

local totalLabel = Instance.new("TextLabel")
totalLabel.Size = UDim2.new(1, -24, 0, 18)
totalLabel.Position = UDim2.new(0, 12, 0, 156)
totalLabel.BackgroundTransparency = 1
totalLabel.Text = "Total Servers: 0"
totalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
totalLabel.TextSize = 11
totalLabel.Font = Enum.Font.Gotham
totalLabel.TextXAlignment = Enum.TextXAlignment.Left
totalLabel.Parent = col1

makeDivider(col1, 178)

local bottomStatus = Instance.new("TextLabel")
bottomStatus.Size = UDim2.new(1, -24, 0, 34)
bottomStatus.Position = UDim2.new(0, 12, 0, 203)
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

local limitBox, setLimit = makeNumericInput(col2, 28, "Server Limit (per page)", 100, 1, 100)
local retriesBox, setRetries = makeNumericInput(col2, 60, "Max Retries", 3, 1, 10)
local baseWaitBox, setBaseWait = makeNumericInput(col2, 92, "Base Wait (s)", 0.3, 0.1, 5)
local maxPagesBox, setMaxPages = makeNumericInput(col2, 124, "Max Pages", 100, 1, 500)

makeDivider(col2, 157)

local btnRow = Instance.new("Frame")
btnRow.Size = UDim2.new(1, -24, 0, 28)
btnRow.Position = UDim2.new(0, 12, 0, 162)
btnRow.BackgroundTransparency = 1
btnRow.Parent = col2

local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.31, 0, 1, 0)
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
stopBtn.Size = UDim2.new(0.31, 0, 1, 0)
stopBtn.Position = UDim2.new(0.345, 0, 0, 0)
stopBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
stopBtn.BorderSizePixel = 0
stopBtn.Text = "STOP"
stopBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
stopBtn.TextSize = 12
stopBtn.Font = Enum.Font.GothamBold
stopBtn.Parent = btnRow
Instance.new("UICorner", stopBtn).CornerRadius = UDim.new(0, 4)

local sendNowBtn = Instance.new("TextButton")
sendNowBtn.Size = UDim2.new(0.31, 0, 1, 0)
sendNowBtn.Position = UDim2.new(0.69, 0, 0, 0)
sendNowBtn.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
sendNowBtn.BorderSizePixel = 0
sendNowBtn.Text = "SEND NOW"
sendNowBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
sendNowBtn.TextSize = 11
sendNowBtn.Font = Enum.Font.GothamBold
sendNowBtn.Parent = btnRow
Instance.new("UICorner", sendNowBtn).CornerRadius = UDim.new(0, 4)
local function setStatus(text)
    titleStatus.Text = "STATUS: " .. text
end

local function setBottom(text)
    bottomStatus.Text = text
end

local function updateTotalLabel()
    totalLabel.Text = "Total Servers: " .. #STATE.jobIdList
end

local function log(tag, msg)
    print(string.format("[ServerFetcher][%s] %s", tag, msg))
end

local function onRateLimitHit(attempt)
    RATE.rateLimitHits   = RATE.rateLimitHits + 1
    RATE.consecutiveFail = RATE.consecutiveFail + 1
    RATE.consecutiveSuccess = 0

    --
    RATE.currentWait = math.min(
        RATE.currentWait * (CONFIG.BACKOFF_BASE ^ math.min(RATE.consecutiveFail, 5)),
        RATE.maxWait
    )

    -- 
    -- 
    local cooldown = math.min(6 * RATE.consecutiveFail, CONFIG.BACKOFF_MAX)
    -- Add ±20% jitter so parallel scripts don't slam simultaneously
    local jitter = cooldown * 0.2 * (math.random() * 2 - 1)
    local pauseFor = math.max(2, cooldown + jitter)

    setStatus(string.format("Rate Limited (%d)", RATE.rateLimitHits))
    setBottom(string.format(
        "429 hit #%d | pausing %.1fs | new wait=%.2fs",
        RATE.rateLimitHits, pauseFor, RATE.currentWait
    ))
    log("RATE_LIMIT", string.format(
        "Hit #%d attempt=%d | cooldown=%.1fs | currentWait=%.3fs",
        RATE.rateLimitHits, attempt, pauseFor, RATE.currentWait
    ))

    task.wait(pauseFor)
end

local function onSoftFail(attempt)
    -- don't touch currentWait
    local wait = math.min(
        0.8 * (CONFIG.BACKOFF_BASE ^ (attempt - 1)),
        CONFIG.BACKOFF_MAX
    )
    local jitter = wait * 0.3 * (math.random() * 2 - 1)
    local final  = math.max(0.5, wait + jitter)
    setBottom(string.format("Soft-fail (attempt %d) — waiting %.1fs", attempt, final))
    task.wait(final)
end

local function onSuccess()
    RATE.consecutiveSuccess = RATE.consecutiveSuccess + 1
    RATE.consecutiveFail    = 0
    if RATE.consecutiveSuccess % 3 == 0 then
        RATE.currentWait = math.max(
            RATE.minWait,
            RATE.currentWait - 0.05
        )
    end
end

local function getFullReportContent()
    local lines = {
        "Server Fetcher Complete Report",
        string.format("Total Fetched: %d",         #STATE.jobIdList),
        string.format("Active: %d",                STATE.activeCount),
        string.format("Empty: %d",                 STATE.emptyCount),
        string.format("Duplicates Skipped: %d",    STATE.duplicateCount),
        string.format("Pages Fetched: %d",         STATE.pageCount),
        "",
        "Server List:",
        "",
    }
    for _, server in ipairs(STATE.jobIdList) do
        table.insert(lines, string.format("%s : %d/%d",
            server.id, server.playing, server.maxPlayers))
    end
    return table.concat(lines, "\n")
end

local function getMaskedWebhook()
    if #webhookUrl <= 10 then return webhookUrl end
    return string.sub(webhookUrl, 1, 10) .. "..."
end

local function sendReport(summaryText, fileContent, filename)
    setStatus("Sending...")
    setBottom("Sending report to Discord...")
    local boundary = "----Boundary" .. tostring(math.random(100000, 999999))
    local payload  = HttpService:JSONEncode({ username = "Server Fetcher", content = summaryText })
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
            Url     = webhookUrl,
            Method  = "POST",
            Headers = { ["Content-Type"] = "multipart/form-data; boundary=" .. boundary },
            Body    = body,
        })
    end)
    if success then
        log("WEBHOOK", "Sent: " .. filename)
        setBottom("Report sent successfully!")
    else
        log("ERROR", "Webhook failed: " .. tostring(err))
        setBottom("Webhook failed: " .. tostring(err))
    end
    return success
end

local function sendNow()
    if #STATE.jobIdList == 0 then
        createPopup("No Data", "No servers have been fetched yet. Run START first.", {
            { text = "OK", color = Color3.fromRGB(80, 80, 80), callback = function() end }
        })
        return
    end
    createPopup("Confirm Send", string.format("Send %d server(s) to Discord?", #STATE.jobIdList), {
        { text = "NO",  color = Color3.fromRGB(120, 40, 40), callback = function() end },
        { text = "YES", color = Color3.fromRGB(40, 100, 40), callback = function()
            local content   = getFullReportContent()
            local summary   = string.format(
                "**Server Fetcher Manual Send**\nTotal: **%d** | Active: **%d** | Empty: **%d** | Dupes skipped: **%d**",
                #STATE.jobIdList, STATE.activeCount, STATE.emptyCount, STATE.duplicateCount)
            local timestamp = tostring(os.time())
            local success   = sendReport(summary, content, "servers_" .. timestamp .. ".txt")
            if success then
                createPopup("Success", string.format("Successfully sent to webhook %s", getMaskedWebhook()), {
                    { text = "OK", color = Color3.fromRGB(80, 80, 80), callback = function() end }
                })
            else
                createPopup("Error", "Failed to send report. Check console.", {
                    { text = "OK", color = Color3.fromRGB(80, 80, 80), callback = function() end }
                })
            end
        end }
    })
end
local function fetchPage(cursor)
    local url = string.format(
        "https://games.roblox.com/v1/games/%d/servers/Public?limit=%d",
        CONFIG.PLACE_ID, CONFIG.LIMIT
    )
    if cursor and cursor ~= "" then
        url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
    end

    local maxAttempts = CONFIG.MAX_RETRIES + 2 
    local attempt = 0

    while attempt < maxAttempts do
        if STATE.stopped then return nil end
        attempt = attempt + 1

        local ok, response = pcall(function()
            return request({ Url = url, Method = "GET" })
        end)

        if not ok then
            -- pcall-level failure (executor error, no network, etc.)
            log("ERROR", "request() threw on attempt " .. attempt .. ": " .. tostring(response))
            if attempt >= maxAttempts then return nil end
            onSoftFail(attempt)

        elseif response.StatusCode == 429 then
            -- Rate limited — pause then retry without counting against MAX_RETRIES
            onRateLimitHit(attempt)
            -- Don't increment attempt for rate-limit hits so retries aren't wasted
            attempt = attempt - 1
            maxAttempts = maxAttempts + 1  -- extend budget to compensate for the pause

        elseif response.StatusCode == 200 then
            local decodeOk, data = pcall(HttpService.JSONDecode, HttpService, response.Body)
            if decodeOk and type(data) == "table" and type(data.data) == "table" then
                onSuccess()
                return data
            else
                log("WARN", "Bad JSON on attempt " .. attempt)
                if attempt >= maxAttempts then return nil end
                onSoftFail(attempt)
            end

        else
            -- 5xx, 4xx (non-429), etc.
            log("WARN", string.format("HTTP %d on attempt %d", response.StatusCode, attempt))
            if attempt >= maxAttempts then return nil end
            onSoftFail(attempt)
        end
    end

    log("ABORT", string.format("fetchPage exhausted %d attempts for page %d", maxAttempts, STATE.pageCount + 1))
    return nil
end

local function applyConfigFromUI()
    CONFIG.LIMIT       = math.clamp(tonumber(limitBox.Text)    or 100,  1,   100)
    CONFIG.MAX_RETRIES = math.clamp(tonumber(retriesBox.Text)  or 3,    1,   10)
    CONFIG.BASE_WAIT   = math.clamp(tonumber(baseWaitBox.Text) or 0.3,  0.1, 5)
    CONFIG.MAX_PAGES   = math.clamp(tonumber(maxPagesBox.Text) or 100,  1,   500)
    -- Sync the adaptive wait floor with user-configured base wait
    RATE.minWait     = CONFIG.BASE_WAIT
    RATE.currentWait = math.max(RATE.currentWait, RATE.minWait)
end

local function shouldIncludeServer(server)
    if STATE.filterActive   and server.playing == 0              then return false end
    if STATE.filterEmpty    and server.playing > 0               then return false end
    if STATE.filterHideFull and server.playing >= server.maxPlayers then return false end
    return true
end

local function enableAntiIdle()
    local lp = Players.LocalPlayer
    if STATE.antiIdleConn then
        STATE.antiIdleConn:Disconnect()
        STATE.antiIdleConn = nil
    end
    STATE.antiIdleConn = lp.Idled:Connect(function()
        VirtualUser:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait()
        VirtualUser:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end)
end

local function disableAntiIdle()
    if STATE.antiIdleConn then
        STATE.antiIdleConn:Disconnect()
        STATE.antiIdleConn = nil
    end
end

local fetchThread = nil

local function startFetch()
    if STATE.running then return end

    STATE.running        = true
    STATE.stopped        = false
    STATE.jobIdSet       = {}
    STATE.jobIdList      = {}
    STATE.pageCount      = 0
    STATE.activeCount    = 0
    STATE.emptyCount     = 0
    STATE.duplicateCount = 0
    STATE.startTime      = os.clock()

    -- Reset adaptive rate state for a clean run
    RATE.consecutiveSuccess = 0
    RATE.consecutiveFail    = 0
    RATE.currentWait        = RATE.minWait
    RATE.rateLimitHits      = 0

    applyConfigFromUI()

    STATE.filterActive    = getActiveState()
    STATE.filterEmpty     = getEmptyState()
    STATE.filterHideFull  = getHideFullState()
    STATE.antiIdleEnabled = getAntiIdleState()

    if STATE.antiIdleEnabled then enableAntiIdle() else disableAntiIdle() end

    updateTotalLabel()
    setStatus("Fetching...")
    setBottom(string.format("Starting — Limit: %d | Max Pages: %d | Base wait: %.2fs",
        CONFIG.LIMIT, CONFIG.MAX_PAGES, RATE.currentWait))
    log("START", string.format(
        "PlaceId %d | Limit %d | MaxPages %d | Filters: Active=%s Empty=%s HideFull=%s",
        CONFIG.PLACE_ID, CONFIG.LIMIT, CONFIG.MAX_PAGES,
        tostring(STATE.filterActive), tostring(STATE.filterEmpty), tostring(STATE.filterHideFull)))

    if fetchThread then task.cancel(fetchThread) end

    fetchThread = task.spawn(function()
        local cursor          = nil
        local cursorStallCount = 0
        local prevCursor      = nil  -- tracks last-successful cursor for stall detection

        repeat
            if STATE.stopped then
                log("STOP", "Stopped by user.")
                setStatus("Stopped")
                setBottom("Fetch stopped by user.")
                break
            end

            local data = fetchPage(cursor)

            if not data then
                log("ABORT", "fetchPage returned nil — stopping.")
                setStatus("Aborted")
                setBottom("Fetch aborted: too many consecutive errors.")
                break
            end

            -- Process servers from this page
            local newThisPage = 0
            for _, server in ipairs(data.data) do
                local id = server.id
                if id then
                    if STATE.jobIdSet[id] then
                        STATE.duplicateCount = STATE.duplicateCount + 1
                    elseif shouldIncludeServer(server) then
                        STATE.jobIdSet[id] = true
                        local playing  = server.playing or 0
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
                    end
                end
            end

            STATE.pageCount = STATE.pageCount + 1
            updateTotalLabel()

            local elapsed   = os.clock() - STATE.startTime
            local rate      = (elapsed > 0) and (STATE.pageCount / elapsed * 60) or 0
            log("PAGE", string.format("#%d new=%d total=%d rate=%.1f/min",
                STATE.pageCount, newThisPage, #STATE.jobIdList, rate))
            setStatus(string.format("Page %d/%d", STATE.pageCount, CONFIG.MAX_PAGES))
            setBottom(string.format(
                "p%d +%d | total=%d act=%d emp=%d dup=%d | wait=%.2fs rl=%d",
                STATE.pageCount, newThisPage,
                #STATE.jobIdList, STATE.activeCount, STATE.emptyCount, STATE.duplicateCount,
                RATE.currentWait, RATE.rateLimitHits))

            -- Cursor stall detection
            local nextCursor = (data.nextPageCursor ~= "") and data.nextPageCursor or nil

            if nextCursor and nextCursor == prevCursor then
                cursorStallCount = cursorStallCount + 1
                log("WARN", string.format("Cursor stall #%d", cursorStallCount))
                if cursorStallCount >= CONFIG.CURSOR_RETRIES then
                    log("ABORT", "Cursor permanently stalled — stopping.")
                    setStatus("Aborted")
                    setBottom("Cursor stalled. Pagination may be exhausted.")
                    break
                end
                -- Wait slightly longer on stall before retrying same cursor
                task.wait(RATE.currentWait * 2)
            else
                cursorStallCount = 0
                prevCursor = nextCursor
            end

            cursor = nextCursor

            -- Only wait between pages when there's a next page to fetch
            if cursor and not STATE.stopped then
                task.wait(RATE.currentWait)
            end

        until not cursor or STATE.pageCount >= CONFIG.MAX_PAGES or STATE.stopped

        -- Final report
        if not STATE.stopped then
            local elapsed = os.clock() - STATE.startTime
            setStatus("Building report...")
            log("DONE", string.format(
                "Finished %d pages | %d unique servers | %.1fs | %.1f pages/min",
                STATE.pageCount, #STATE.jobIdList, elapsed,
                (elapsed > 0) and (STATE.pageCount / elapsed * 60) or 0))
            local content   = getFullReportContent()
            local summary   = string.format(
                "**Server Fetcher Complete**\nTotal: **%d** | Active: **%d** | Empty: **%d** | Pages: **%d**",
                #STATE.jobIdList, STATE.activeCount, STATE.emptyCount, STATE.pageCount)
            local timestamp = tostring(os.time())
            sendReport(summary, content, "servers_" .. timestamp .. ".txt")
            setStatus("Done")
        else
            setStatus("Incomplete")
            setBottom(string.format(
                "Stopped at page %d | %d unique servers collected.",
                STATE.pageCount, #STATE.jobIdList))
        end

        STATE.running = false
        fetchThread   = nil
    end)
end

local function stopFetch()
    if not STATE.running then return end
    STATE.stopped = true
    setStatus("Stopping...")
    setBottom("Stop requested.")
end

-- ─── Button wiring (unchanged) ───────────────────────────────────────────────

lockBtn.MouseButton1Click:Connect(function()
    uiLocked = not uiLocked
    if uiLocked then
        lockBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
        lockBtn.Text = "LOCKED"
    else
        lockBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        lockBtn.Text = "LOCK"
    end
end)

hideBtn.MouseButton1Click:Connect(function()
    uiVisible = not uiVisible
    mainFrame.Visible = uiVisible
    hideBtn.Text = uiVisible and "HIDE UI" or "SHOW UI"
end)

startBtn.MouseButton1Click:Connect(startFetch)
stopBtn.MouseButton1Click:Connect(stopFetch)
sendNowBtn.MouseButton1Click:Connect(sendNow)

toggleActiveBtn.MouseButton1Click:Connect(function()
    local val = not getActiveState()
    setActiveState(val)
    STATE.filterActive = val
    setBottom("Active Only: " .. (val and "ON" or "OFF"))
end)

toggleEmptyBtn.MouseButton1Click:Connect(function()
    local val = not getEmptyState()
    setEmptyState(val)
    STATE.filterEmpty = val
    setBottom("Empty Only: " .. (val and "ON" or "OFF"))
end)

toggleHideFullBtn.MouseButton1Click:Connect(function()
    local val = not getHideFullState()
    setHideFullState(val)
    STATE.filterHideFull = val
    setBottom("Hide Full Servers: " .. (val and "ON" or "OFF"))
end)

toggleAntiIdleBtn.MouseButton1Click:Connect(function()
    local val = not getAntiIdleState()
    setAntiIdleState(val)
    STATE.antiIdleEnabled = val
    if val then
        enableAntiIdle()
        setBottom("Idle Protection enabled")
    else
        disableAntiIdle()
        setBottom("Idle Protection disabled")
    end
end)

setStatus("Idle")
setBottom("Ready. Configure settings and press START.")
