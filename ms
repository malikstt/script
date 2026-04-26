local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local webhookUrl = "https://discord.com/api/webhooks/1497999446028587128/nTY1lOe95jZXpEMXJu0oxqG3RXkp75gqy70qswx44o9ummGlLNEe_RyYpszPo_YxwlI0"

local targetPlayer = "68exp"
local userId = "921793487509278730"

local stats = ReplicatedStorage:FindFirstChild("Stats")
local leaderboard = Workspace:FindFirstChild("Leaderboards")
local compLeaderboard = leaderboard and leaderboard:FindFirstChild("CompLeaderboardScore")
local main = compLeaderboard and compLeaderboard:FindFirstChild("Main")

local lastData = {}
local lastSendTime = 0
local lastActivityTime = os.time()
local playerLeftTimer = nil
local isRunning = true
local lastInactivitySend = 0
local wasGone = false

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
    local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=921793487509278730&size=150x150&format=Png&isCircular=true"
    local success, response = pcall(function()
        return request({Url = url, Method = "GET"})
    end)
    if success and response and response.Success then
        local data = HttpService:JSONDecode(response.Body)
        if data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    return nil
end

local function getCurrentData()
    local targetStats = stats and stats:FindFirstChild(targetPlayer)
    if not targetStats then return nil end
    
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

local function sendFullEmbed(data, reason)
    local avatarUrl = getAvatarThumbnail()
    
    local compGain = ""
    if lastData.compScore and data.compScore > lastData.compScore then
        local gain = data.compScore - lastData.compScore
        compGain = string.format(" (+%s)", formatNumber(gain))
    end
    
    local rubiesGain = ""
    if lastData.rubies and data.rubies > lastData.rubies then
        local gain = data.rubies - lastData.rubies
        rubiesGain = string.format(" (+%s)", formatNumber(gain))
    end
    
    local throwsGain = ""
    if lastData.throws and data.throws > lastData.throws then
        local gain = data.throws - lastData.throws
        throwsGain = string.format(" (+%s)", formatNumber(gain))
    end
    
    local autoThrowStatus = data.autoThrow and "Enabled" or "Disabled"
    
    local embed = {
        color = 0x9b59b6,
        thumbnail = {url = avatarUrl},
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
    }
    
    pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({embeds = {embed}})
        })
        print("Sent stats | Reason: " .. reason)
    end)
end

local function sendLeaveMessage()
    local jobId = game.JobId or "Unknown"
    local timestamp = os.time()
    
    local payload = {
        content = string.format("<@%s> User %s left server\nJob ID: `%s`\n<t:%d:R>", userId, targetPlayer, jobId, timestamp)
    }
    
    pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        print("Leave message sent")
    end)
end

local function sendInactivityMessage(reason, data)
    local avatarUrl = getAvatarThumbnail()
    
    local payload = {
        content = string.format("<@%s> %s\nReason: %s", userId, targetPlayer, reason),
        embeds = {{
            color = 0x9b59b6,
            thumbnail = {url = avatarUrl},
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
        print("Inactivity message sent | " .. reason)
    end)
end

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
            print("Player rejoined!")
            wasGone = false
            playerLeftTimer = nil
            local currentData = getCurrentData()
            if currentData then
                sendFullEmbed(currentData, "Player Rejoined")
                lastSendTime = os.time()
                lastActivityTime = os.time()
                return true
            end
        end
        playerLeftTimer = nil
    end
    return false
end

local function checkInactivity()
    local currentData = getCurrentData()
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

local function mainLoop()
    local initialData = getCurrentData()
    if initialData then
        lastData = initialData
        sendFullEmbed(initialData, "Initial Load")
        lastSendTime = os.time()
        lastActivityTime = os.time()
    end
    
    while isRunning do
        local currentTime = os.time()
        local currentData = getCurrentData()
        
        if currentData then
            lastData = currentData
            
            if currentTime - lastSendTime >= 1800 then
                sendFullEmbed(currentData, "30 Minute Interval")
                lastSendTime = currentTime
                lastActivityTime = currentTime
            else
                local handled = checkPlayerLeft()
                if not handled then
                    checkInactivity()
                end
            end
        end
        
        task.wait(10)
    end
end

mainLoop()
