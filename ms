local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local webhookUrl = "https://discord.com/api/webhooks/1497999446028587128/nTY1lOe95jZXpEMXJu0oxqG3RXkp75gqy70qswx44o9ummGlLNEe_RyYpszPo_YxwlI0"

local targetPlayer = "68exp"
local discordUserId = "921793487509278730"

print("comp script loaded v7")

local robloxUserId = nil

local function getRobloxUserId(username)
    print("Fetching Roblox User ID for: " .. username)
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
        print("Roblox API response status: " .. tostring(response.StatusCode))
        if response.StatusCode == 200 then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            if decodeSuccess and data and data.data and data.data[1] then
                local id = tostring(data.data[1].id)
                print("Found Roblox User ID: " .. id)
                return id
            else
                print("Failed to decode Roblox API response")
            end
        else
            print("Roblox API returned status: " .. tostring(response.StatusCode))
        end
    else
        print("Failed to fetch Roblox User ID: " .. tostring(response))
    end
    return nil
end

robloxUserId = getRobloxUserId(targetPlayer)
if not robloxUserId then
    print("Could not fetch Roblox User ID - avatar thumbnails will be disabled")
end

pcall(function()
    HttpService.HttpEnabled = true
end)

local stats = ReplicatedStorage:FindFirstChild("Stats")
local leaderboard = Workspace:FindFirstChild("Leaderboards")

print("Stats found: " .. tostring(stats ~= nil))
print("Leaderboard found: " .. tostring(leaderboard ~= nil))

local lastData = {}
local last30MinData = nil
local lastSendTime = 0
local isRunning = true
local lastThrowsTime = os.time()
local lastRubiesTime = os.time()
local noThrowsSent = false
local noRubiesSent = false
local playerHasLeft = false

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
        content = string.format("<@%s> left server | Job ID: `%s` | <t:%d:R>", discordUserId, jobId, os.time())
    }
    pcall(function()
        request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(payload)
        })
        print("[CASE 2] Leave message sent - stopping all further updates")
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
                {name = "🔳 Enchant Gems", value = formatNumber(data.enchantGems), inline = true},
                {name = "🔴 Rubies", value = formatNumber(data.rubies), inline = true},
                {name = "🏆 Comp Score", value = formatNumber(data.compScore), inline = true},
                {name = "🕐 Session Time", value = data.hours .. "h " .. data.minutes .. "m", inline = true},
                {name = "🪨 Throws", value = formatNumber(data.throws), inline = true},
                {name = "😂 AutoThrow", value = data.autoThrow and "Enabled" or "Disabled", inline = true},
                {name = "# Rank", value = data.rank, inline = true},
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
        print("[CASE 3] " .. reason .. " message sent")
    end)
end

local function sendToDiscord(data, reason, isRejoin)
    local avatarUrl = getAvatarThumbnail()
    
    local embed = {
        title = "Stats Update",
        color = 0x3498db,
        thumbnail = avatarUrl and {url = avatarUrl} or nil,
        fields = {
            {name = "🔳 Enchant Gems", value = formatNumber(data.enchantGems), inline = true},
            {name = "🔴 Rubies", value = formatNumber(data.rubies), inline = true},
            {name = "🏆 Comp Score", value = formatNumber(data.compScore), inline = true},
            {name = "🕐 Session Time", value = data.hours .. "h " .. data.minutes .. "m", inline = true},
            {name = "🪨 Throws", value = formatNumber(data.throws), inline = true},
            {name = "😂 AutoThrow", value = data.autoThrow and "Enabled" or "Disabled", inline = true},
            {name = "# Rank", value = data.rank, inline = true},
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

local function sendToDiscordWithCompare(currentData, compareData, reason)
    local avatarUrl = getAvatarThumbnail()
    
    local compGain = ""
    local rubiesGain = ""
    local throwsGain = ""
    
    if compareData and compareData.compScore and currentData.compScore > compareData.compScore then
        local gain = currentData.compScore - compareData.compScore
        compGain = string.format(" (+%s)", formatNumber(gain))
    end
    
    if compareData and compareData.rubies and currentData.rubies > compareData.rubies then
        local gain = currentData.rubies - compareData.rubies
        rubiesGain = string.format(" (+%s)", formatNumber(gain))
    end
    
    if compareData and compareData.throws and currentData.throws > compareData.throws then
        local gain = currentData.throws - compareData.throws
        throwsGain = string.format(" (+%s)", formatNumber(gain))
    end
    
    local embed = {
        title = "Stats Update",
        color = 0x3498db,
        thumbnail = avatarUrl and {url = avatarUrl} or nil,
        fields = {
            {name = "🔳 Enchant Gems", value = formatNumber(currentData.enchantGems), inline = true},
            {name = "🔴 Rubies", value = formatNumber(currentData.rubies) .. rubiesGain, inline = true},
            {name = "🏆 Comp Score", value = formatNumber(currentData.compScore) .. compGain, inline = true},
            {name = "🕐 Session Time", value = currentData.hours .. "h " .. currentData.minutes .. "m", inline = true},
            {name = "🪨 Throws", value = formatNumber(currentData.throws) .. throwsGain, inline = true},
            {name = "😂 AutoThrow", value = currentData.autoThrow and "Enabled" or "Disabled", inline = true},
            {name = "# Rank", value = currentData.rank, inline = true},
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
    print("Waiting 5 seconds for game to load...")
    task.wait(5)
    
    local initialData = getCurrentData()
    if initialData then
        print("Got initial data, sending immediately...")
        lastData = initialData
        last30MinData = initialData
        lastThrowsTime = os.time()
        lastRubiesTime = os.time()
        sendToDiscord(initialData, "Initial Load", false)
        lastSendTime = os.time()
    else
        print("Could not find player stats! Make sure '" .. targetPlayer .. "' is in the game")
        if stats then
            for _, child in pairs(stats:GetChildren()) do
                print("   - " .. child.Name)
            end
        end
    end
    
    while isRunning do
        task.wait(10)
        
        local playerExists = Players:FindFirstChild(targetPlayer) ~= nil
        
        if not playerExists and not playerHasLeft then
            playerHasLeft = true
            sendLeaveMessage()
            print("[CASE 2] Player left, stopped all updates")
        elseif playerExists and playerHasLeft then
            playerHasLeft = false
            noThrowsSent = false
            noRubiesSent = false
            lastThrowsTime = os.time()
            lastRubiesTime = os.time()
            print("Player rejoined, resuming updates")
            local currentData = getCurrentData()
            if currentData then
                sendToDiscord(currentData, "Rejoin Update", true)
                lastSendTime = os.time()
                last30MinData = currentData
                lastData = currentData
            end
        end
        
        if playerHasLeft then
            task.wait(10)
            continue
        end
        
        local currentData = getCurrentData()
        if currentData then
            if os.time() - lastSendTime >= 1800 then
                if last30MinData then
                    sendToDiscordWithCompare(currentData, last30MinData, "30 Minute Update")
                else
                    sendToDiscord(currentData, "30 Minute Update", false)
                end
                last30MinData = currentData
                lastSendTime = os.time()
                lastThrowsTime = os.time()
                lastRubiesTime = os.time()
                lastData = currentData
                noThrowsSent = false
                noRubiesSent = false
            else
                if lastData.throws and currentData.throws == lastData.throws then
                    if os.time() - lastThrowsTime >= 60 and not noThrowsSent then
                        sendInactivityMessage("No throws for 60 seconds", currentData)
                        noThrowsSent = true
                        lastSendTime = os.time()
                    end
                else
                    if noThrowsSent then
                        print("Player started throwing again, resetting timer")
                        lastThrowsTime = os.time()
                        noThrowsSent = false
                    end
                    if currentData.throws > lastData.throws then
                        lastThrowsTime = os.time()
                    end
                end
                
                if lastData.rubies and currentData.rubies == lastData.rubies then
                    if os.time() - lastRubiesTime >= 300 and not noRubiesSent then
                        sendInactivityMessage("No rubies for 5 minutes", currentData)
                        noRubiesSent = true
                        lastSendTime = os.time()
                    end
                else
                    if noRubiesSent then
                        print("Player started gaining rubies again, resetting timer")
                        lastRubiesTime = os.time()
                        noRubiesSent = false
                    end
                    if currentData.rubies > lastData.rubies then
                        lastRubiesTime = os.time()
                    end
                end
                lastData = currentData
            end
        else
            print("Player data not found, retrying...")
        end
    end
end

local success, err = pcall(mainLoop)
if not success then
    print("Script error: " .. tostring(err))
end
