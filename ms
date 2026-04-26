local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local webhookUrl = "https://discord.com/api/webhooks/1495059756371546345/L3e0gHM3cdJAhq80YGviVwkvNOcJKOKYjerPBRPp2I5mli4FZ7r8vD7-8LPrBqWODKNw"

local targetPlayer = "68exp"
local targetDisplayName = "68exp"

local stats = ReplicatedStorage:FindFirstChild("Stats")
local leaderboard = Workspace:FindFirstChild("Leaderboards")
local compLeaderboard = leaderboard and leaderboard:FindFirstChild("CompLeaderboardScore")
local main = compLeaderboard and compLeaderboard:FindFirstChild("Main")

local lastData = {}
local lastSendTime = 0
local lastActivityTime = os.time()
local playerLeftTimer = nil
local inactivityTimer = nil
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

local function formatNumberRaw(num)
    return math.floor(num)
end

local function getUserId(username)
    local url = "https://users.roblox.com/v1/usernames/users"
    local body = {usernames = {username}}
    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(body)
        })
    end)
    if success and response and response.Success then
        local data = HttpService:JSONDecode(response.Body)
        if data.data and data.data[1] then
            return data.data[1].id
        end
    end
    return nil
end

local function getAvatarThumbnail(userId)
    local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=150x150&format=Png&isCircular=true"
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

local function sendWebhook(data, reason)
    local userId = getUserId(targetPlayer)
    local avatarUrl = userId and getAvatarThumbnail(userId) or "https://www.roblox.com/headshot-thumbnail/image?userId=1&width=150&height=150&format=png"
    
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
        print("Sent stats for " .. targetPlayer .. " | Reason: " .. reason)
    end)
    
    lastData = data
    lastSendTime = os.time()
end

local function checkPlayerLeft()
    local player = Players:FindFirstChild(targetDisplayName)
    if not player then
        if not playerLeftTimer then
            playerLeftTimer = tick()
        elseif tick() - playerLeftTimer >= 60 then
            local currentData = getCurrentData()
            if currentData then
                sendWebhook(currentData, "Player Left Server")
            end
            playerLeftTimer = nil
            lastSendTime = os.time()
        end
    else
        playerLeftTimer = nil
    end
end

local function checkInactivity()
    local currentData = getCurrentData()
    if not currentData then return end
    
    if lastData.throws then
        if currentData.throws == lastData.throws and os.time() - lastActivityTime >= 60 then
            sendWebhook(currentData, "No Throws for 60s")
            lastActivityTime = os.time()
            lastSendTime = os.time()
            return
        elseif currentData.throws > lastData.throws then
            lastActivityTime = os.time()
        end
    end
    
    if lastData.rubies then
        if currentData.rubies == lastData.rubies and os.time() - lastActivityTime >= 300 then
            sendWebhook(currentData, "No Rubies for 5m")
            lastActivityTime = os.time()
            lastSendTime = os.time()
        elseif currentData.rubies > lastData.rubies then
            lastActivityTime = os.time()
        end
    end
end

local function mainLoop()
    local initialData = getCurrentData()
    if initialData then
        sendWebhook(initialData, "Initial Load")
        lastActivityTime = os.time()
    end
    
    while isRunning do
        local currentTime = os.time()
        local currentData = getCurrentData()
        
        if currentData then
            lastData = currentData
            if currentTime - lastSendTime >= 1800 then
                sendWebhook(currentData, "30 Minute Interval")
                lastActivityTime = currentTime
            else
                checkPlayerLeft()
                checkInactivity()
            end
        end
        
        task.wait(10)
    end
end

mainLoop()
