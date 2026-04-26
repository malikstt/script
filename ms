local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local webhookUrl = "https://discord.com/api/webhooks/1497999446028587128/nTY1lOe95jZXpEMXJu0oxqG3RXkp75gqy70qswx44o9ummGlLNEe_RyYpszPo_YxwlI0"

local targetPlayer = "68exp"
local discordUserId = "921793487509278730"

-- AUTO GET ROBLOX USER ID FROM USERNAME
local robloxUserId = nil

local function getRobloxUserId(username)
    local url = "https://users.roblox.com/v1/usernames/users"
    local body = HttpService:JSONEncode({usernames = {username}})
    
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = body
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        if data and data.data and data.data[1] then
            return tostring(data.data[1].id)
        end
    end
    return nil
end

robloxUserId = getRobloxUserId(targetPlayer)

local stats = ReplicatedStorage:FindFirstChild("Stats")
local leaderboard = Workspace:FindFirstChild("Leaderboards")

local lastData = {}
local lastSendTime = os.time()
local lastActivityTime = os.time()
local lastInactivitySend = 0
local playerLeftTimer = nil
local wasGone = false
local isRunning = true

local function formatNumber(num)
    if num >= 1e12 then
        return string.format("%.1fT", num / 1e12)
    elseif num >= 1e9 then
        return string.format("%.1fB", num / 1e9)
    elseif num >= 1e6 then
        return string.format("%.1fM", num / 1e6)
    elseif num >= 1e3 then
        return string.format("%.1fK", num / 1e3)
    else
        return tostring(math.floor(num))
    end
end

local function getAvatarThumbnail()
    if not robloxUserId then return nil end
    local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. robloxUserId .. "&size=150x150&format=Png&isCircular=true"
    local success, response = pcall(function() return request({Url = url, Method = "GET"}) end)
    if success and response and response.StatusCode == 200 then
        local data = HttpService:JSONDecode(response.Body)
        if data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    return nil
end

local function getCurrentData()
    if not stats then stats = ReplicatedStorage:FindFirstChild("Stats") end
    if not stats then return nil end
    
    local targetStats = stats:FindFirstChild(targetPlayer)
    if not targetStats then return nil end
    
    local compLeaderboard = leaderboard and leaderboard:FindFirstChild("CompLeaderboardScore")
    local main = compLeaderboard and compLeaderboard:FindFirstChild("Main")
    
    local enchantGems = targetStats:FindFirstChild("EnchantGems")
    local compScore = targetStats:FindFirstChild("CompLeaderboardScore")
    local sessionTime = targetStats:FindFirstChild("Analytics") and targetStats.Analytics:FindFirstChild("SessionTime")
    local rubies = targetStats:FindFirstChild("Twenty Event") and targetStats["Twenty Event"]:FindFirstChild("Rubies")
    local autoThrow = targetStats:FindFirstChild("Settings") and targetStats.Settings:FindFirstChild("AutoThrow")
    local throws = targetStats:FindFirstChild("Analytics") and targetStats.Analytics:FindFirstChild("Throws")
    
    local sessionValue = sessionTime and sessionTime.Value or 0
    local hours = math.floor(sessionValue / 3600)
    local minutes = math.floor((sessionValue % 3600) / 60)
    
    local playerRank = nil
    if main then
        local ui = main:FindFirstChild("UI")
        local normal = ui and ui:FindFirstChild("Normal")
        if normal then
            for _, frame in ipairs(normal:GetChildren()) do
                if frame:IsA("Frame") then
                    local nameLabel = frame:FindFirstChild("PlayerName")
                    local placeLabel = frame:FindFirstChild("Place")
                    if nameLabel and nameLabel.Text == "@" .. targetPlayer then
                        playerRank = placeLabel and placeLabel.Text or "?"
                        break
                    end
                end
            end
        end
    end
    
    return {
        enchantGems = enchantGems and enchantGems.Value or 0,
        compScore = compScore and compScore.Value or 0,
        rubies = rubies and rubies.Value or 0,
        throws = throws and throws.Value or 0,
        autoThrow = autoThrow and autoThrow.Value or false,
        hours = hours,
        minutes = minutes,
        rank = playerRank or "N/A",
        timestamp = os.time()
    }
end

-- CASE 1: Full embed send (with optional ping)
local function sendFullEmbed(data, reason, shouldPing)
    local avatarUrl = getAvatarThumbnail()
    
    local compGain = ""
    local rubiesGain = ""
    local throwsGain = ""
    
    if lastData.compScore and data.compScore > lastData.compScore then
        compGain = string.format(" (+%s)", formatNumber(data.compScore - lastData.compScore))
    end
    if lastData.rubies and data.rubies > lastData.rubies then
        rubiesGain = string.format(" (+%s)", formatNumber(data.rubies - lastData.rubies))
    end
    if lastData.throws and data.throws > lastData.throws then
        throwsGain = string.format(" (+%s)", formatNumber(data.throws - lastData.throws))
    end
    
    local autoThrowStatus = data.autoThrow and "Enabled" or "Disabled"
    local payload = {}
    
    if shouldPing then
        payload.content = string.format("<@%s>", discordUserId)
    end
    
    payload.embeds = {{
        color = 0x9b59b6,
        thumbnail = avatarUrl and {url = avatarUrl} or nil,
        fields = {
            {name = "💎 Enchant Gems", value = formatNumber(data.enchantGems), inline = true},
            {name = "🔴 Rubies", value = formatNumber(data.rubies) .. rubiesGain, inline = true},
            {name = "🏆 Comp Score", value = formatNumber(data.compScore) .. compGain, inline = true},
            {name = "⏱️ Session Time", value = data.hours .. "h " .. data.minutes .. "m", inline = true},
            {name = "🎲 Throws", value = formatNumber(data.throws) .. throwsGain, inline = true},
            {name = "🎯 AutoThrow", value = autoThrowStatus, inline = true},
            {name = "📊 Rank", value = data.rank, inline = true},
        },
        footer = {text = "Trigger: " .. reason .. " | Next update in 30m"}
    }}
    
    pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        print("[CASE 1/2/3] Sent | Reason: " .. reason)
    end)
end

-- CASE 2: Player left message
local function sendLeaveMessage()
    local jobId = game.JobId or "Unknown"
    local payload = {
        content = string.format("<@%s> User %s left server\nJob ID: `%s`\n<t:%d:R>", discordUserId, targetPlayer, jobId, os.time())
    }
    pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        print("[CASE 2] Leave message sent")
    end)
end

-- CASE 3: Inactivity message
local function sendInactivityMessage(reason, data)
    local avatarUrl = getAvatarThumbnail()
    local payload = {
        content = string.format("<@%s> %s\nReason: %s", discordUserId, targetPlayer, reason),
        embeds = {{
            color = 0x9b59b6,
            thumbnail = avatarUrl and {url = avatarUrl} or nil,
            fields = {
                {name = "💎 Enchant Gems", value = formatNumber(data.enchantGems), inline = true},
                {name = "🔴 Rubies", value = formatNumber(data.rubies), inline = true},
                {name = "🏆 Comp Score", value = formatNumber(data.compScore), inline = true},
                {name = "⏱️ Session Time", value = data.hours .. "h " .. data.minutes .. "m", inline = true},
                {name = "🎲 Throws", value = formatNumber(data.throws), inline = true},
                {name = "🎯 AutoThrow", value = data.autoThrow and "Enabled" or "Disabled", inline = true},
                {name = "📊 Rank", value = data.rank, inline = true},
            }
        }}
    }
    pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        print("[CASE 3] Inactivity message sent | " .. reason)
    end)
end

-- Check if player left (CASE 2)
local function checkPlayerLeft()
    local player = Players:FindFirstChild(targetPlayer)
    if not player then
        if not wasGone then
            wasGone = true
            playerLeftTimer = tick()
        elseif tick() - playerLeftTimer >= 60 then
            sendLeaveMessage()
            playerLeftTimer = nil
            wasGone = false
            lastSendTime = os.time()
            return true
        end
    else
        if wasGone then
            print("[REJOIN] Player rejoined!")
            wasGone = false
            playerLeftTimer = nil
            local currentData = getCurrentData()
            if currentData then
                sendFullEmbed(currentData, "Player Rejoined", true)
                lastSendTime = os.time()
                lastActivityTime = os.time()
            end
            return true
        end
        playerLeftTimer = nil
    end
    return false
end

-- Check inactivity (CASE 3)
local function checkInactivity(currentData)
    if not currentData then return false end
    
    if lastData.throws then
        if currentData.throws == lastData.throws and os.time() - lastActivityTime >= 60 then
            if os.time() - lastInactivitySend >= 300 then
                sendInactivityMessage("No throws for 60 seconds", currentData)
                lastActivityTime = os.time()
                lastSendTime = os.time()
                lastInactivitySend = os.time()
                return true
            end
        elseif currentData.throws > lastData.throws then
            lastActivityTime = os.time()
        end
    end
    
    if lastData.rubies then
        if currentData.rubies == lastData.rubies and os.time() - lastActivityTime >= 300 then
            if os.time() - lastInactivitySend >= 300 then
                sendInactivityMessage("No rubies for 5 minutes", currentData)
                lastActivityTime = os.time()
                lastSendTime = os.time()
                lastInactivitySend = os.time()
                return true
            end
        elseif currentData.rubies > lastData.rubies then
            lastActivityTime = os.time()
        end
    end
    
    return false
end

-- Main loop
local function mainLoop()
    task.wait(5)
    
    local initialData = getCurrentData()
    if initialData then
        lastData = initialData
        sendFullEmbed(initialData, "Initial Load", false)
        lastSendTime = os.time()
        lastActivityTime = os.time()
    end
    
    while isRunning do
        task.wait(10)
        local currentData = getCurrentData()
        
        if currentData then
            lastData = currentData
            
            -- CASE 1: 30 minute interval
            if os.time() - lastSendTime >= 1800 then
                sendFullEmbed(currentData, "30 Minute Interval", false)
                lastSendTime = os.time()
                lastActivityTime = os.time()
            else
                -- CASE 2: Player left
                local handled = checkPlayerLeft()
                -- CASE 3: Inactivity (only if no other case triggered)
                if not handled then
                    checkInactivity(currentData)
                end
            end
        end
    end
end

pcall(mainLoop)
