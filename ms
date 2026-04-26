local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local webhookUrl = "https://discord.com/api/webhooks/1497999446028587128/nTY1lOe95jZXpEMXJu0oxqG3RXkp75gqy70qswx44o9ummGlLNEe_RyYpszPo_YxwlI0"

local targetPlayer = "68exp"
local discordUserId = "921793487509278730"

print("[DEBUG] Script started for: " .. targetPlayer)

local robloxUserId = nil

local function getRobloxUserId(username)
    print("[DEBUG] Fetching Roblox User ID for: " .. username)
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
    
    if success and response then
        print("[DEBUG] Roblox API response status: " .. tostring(response.StatusCode))
        if response.StatusCode == 200 then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            if decodeSuccess and data and data.data and data.data[1] then
                local id = tostring(data.data[1].id)
                print("[DEBUG] Found Roblox User ID: " .. id)
                return id
            else
                print("[ERROR] Failed to decode Roblox API response")
            end
        else
            print("[ERROR] Roblox API returned status: " .. tostring(response.StatusCode))
        end
    else
        print("[ERROR] Failed to fetch Roblox User ID: " .. tostring(response))
    end
    return nil
end

robloxUserId = getRobloxUserId(targetPlayer)
if not robloxUserId then
    print("[WARNING] Could not fetch Roblox User ID - avatar thumbnails will be disabled")
end

pcall(function()
    HttpService.HttpEnabled = true
end)

local stats = ReplicatedStorage:FindFirstChild("Stats")
local leaderboard = Workspace:FindFirstChild("Leaderboards")

print("[DEBUG] Stats found: " .. tostring(stats ~= nil))
print("[DEBUG] Leaderboard found: " .. tostring(leaderboard ~= nil))

local lastData = {}
local lastSendTime = 0
local isRunning = true
local lastThrowsTime = os.time()
local lastRubiesTime = os.time()
local lastInactivitySend = 0
local playerLeftTimer = nil
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
    if not robloxUserId then
        return nil
    end
    
    local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. robloxUserId .. "&size=150x150&format=Png&isCircular=true"
    
    local success, response = pcall(function()
        return request({
            Url = url, 
            Method = "GET"
        })
    end)
    
    if success and response and response.StatusCode == 200 then
        local decodeSuccess, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if decodeSuccess and data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    return nil
end

local function getCurrentData()
    if not stats then
        stats = ReplicatedStorage:FindFirstChild("Stats")
        if not stats then
            return nil
        end
    end
    
    local targetStats = stats:FindFirstChild(targetPlayer)
    if not targetStats then 
        return nil 
    end
    
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

local function sendLeaveMessage()
    local jobId = game.JobId or "Unknown"
    local payload = {
        content = string.format("<@%s> left server\nJob ID: `%s`\n<t:%d:R>", discordUserId, jobId, os.time())
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

local function sendInactivityMessage(reason, data)
    local avatarUrl = getAvatarThumbnail()
    local payload = {
        content = string.format("<@%s> - %s", discordUserId, reason),
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
                local avatarUrl = getAvatarThumbnail()
                local embed = {
                    title = "Stats Update",
                    color = 0x3498db,
                    thumbnail = avatarUrl and {url = avatarUrl} or nil,
                    fields = {
                        {name = "🟪 Enchant Gems", value = formatNumber(currentData.enchantGems), inline = true},
                        {name = "🔴 Rubies", value = formatNumber(currentData.rubies), inline = true},
                        {name = "🏆 Comp Score", value = formatNumber(currentData.compScore), inline = true},
                        {name = "⏱️ Session Time", value = currentData.hours .. "h " .. currentData.minutes .. "m", inline = true},
                        {name = "🪨 Throws", value = formatNumber(currentData.throws), inline = true},
                        {name = "😂 AutoThrow", value = currentData.autoThrow and "Enabled" or "Disabled", inline = true},
                        {name = "📊 Rank", value = currentData.rank, inline = true},
                    },
                    footer = {text = "Player Rejoined | Next update in 30 minutes"}
                }
                if avatarUrl then embed.description = "**68exp**" end
                pcall(function()
                    request({
                        Url = webhookUrl,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = HttpService:JSONEncode({embeds = {embed}})
                    })
                end)
                lastSendTime = os.time()
                lastThrowsTime = os.time()
                lastRubiesTime = os.time()
            end
            return true
        end
        playerLeftTimer = nil
    end
    return false
end

local function sendToDiscord(data, reason)
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
    
    local embed = {
        title = "Stats Update",
        color = 0x3498db,
        thumbnail = avatarUrl and {url = avatarUrl} or nil,
        fields = {
            {name = "🟪 Enchant Gems", value = formatNumber(data.enchantGems), inline = true},
            {name = "🔴 Rubies", value = formatNumber(data.rubies) .. rubiesGain, inline = true},
            {name = "🏆 Comp Score", value = formatNumber(data.compScore) .. compGain, inline = true},
            {name = "⏱️ Session Time", value = data.hours .. "h " .. data.minutes .. "m", inline = true},
            {name = "🎲 Throws", value = formatNumber(data.throws) .. throwsGain, inline = true},
            {name = "🎯 AutoThrow", value = data.autoThrow and "Enabled" or "Disabled", inline = true},
            {name = "📊 Rank", value = data.rank, inline = true},
        },
        footer = {text = reason .. " | Next update in 30 minutes"}
    }
    
    if avatarUrl then
        embed.description = "**68exp**"
    end
    
    local success, response = pcall(function()
        return request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({embeds = {embed}})
        })
    end)
    
    if success and (response.StatusCode == 200 or response.StatusCode == 204) then
        print("Sent to Discord | Reason: " .. reason)
        return true
    else
        print("Failed to send | Status: " .. tostring(response and response.StatusCode or "nil"))
        return false
    end
end

local function mainLoop()
    print("[DEBUG] Waiting 5 seconds for game to load...")
    task.wait(5)
    
    local initialData = getCurrentData()
    if initialData then
        print("[DEBUG] Got initial data, sending immediately...")
        lastData = initialData
        lastThrowsTime = os.time()
        lastRubiesTime = os.time()
        sendToDiscord(initialData, "Initial Load")
        lastSendTime = os.time()
    else
        print("[ERROR] Could not find player stats! Make sure '" .. targetPlayer .. "' is in the game")
        if stats then
            for _, child in pairs(stats:GetChildren()) do
                print("   - " .. child.Name)
            end
        end
    end
    
    while isRunning do
        task.wait(10)
        
        local currentData = getCurrentData()
        if currentData then
            if os.time() - lastSendTime >= 1800 then
                sendToDiscord(currentData, "30 Minute Update")
                lastSendTime = os.time()
                lastThrowsTime = os.time()
                lastRubiesTime = os.time()
                lastData = currentData
            else
                local handled = checkPlayerLeft()
                if not handled then
                    if lastData.throws and currentData.throws == lastData.throws then
                        if os.time() - lastThrowsTime >= 60 then
                            if os.time() - lastInactivitySend >= 300 then
                                sendInactivityMessage("No throws for 60 seconds", currentData)
                                lastInactivitySend = os.time()
                                lastSendTime = os.time()
                                lastThrowsTime = os.time()
                                lastRubiesTime = os.time()
                            end
                        end
                    else
                        lastThrowsTime = os.time()
                    end
                    
                    if lastData.rubies and currentData.rubies == lastData.rubies then
                        if os.time() - lastRubiesTime >= 300 then
                            if os.time() - lastInactivitySend >= 300 then
                                sendInactivityMessage("No rubies for 5 minutes", currentData)
                                lastInactivitySend = os.time()
                                lastSendTime = os.time()
                                lastThrowsTime = os.time()
                                lastRubiesTime = os.time()
                            end
                        end
                    else
                        lastRubiesTime = os.time()
                    end
                end
                lastData = currentData
            end
        else
            print("[DEBUG] Player data not found, retrying...")
        end
    end
end

local success, err = pcall(mainLoop)
if not success then
    print("[FATAL] Script error: " .. tostring(err))
end
