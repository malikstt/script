local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local webhookUrl = "https://discord.com/api/webhooks/1497999446028587128/nTY1lOe95jZXpEMXJu0oxqG3RXkp75gqy70qswx44o9ummGlLNEe_RyYpszPo_YxwlI0"

local targetPlayer = "68exp"
local discordUserId = "921793487509278730"

print("[DEBUG] Script started v4 nigga fetching Roblox ID for: " .. targetPlayer)

-- AUTO GET ROBLOX USER ID FROM USERNAME
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

-- Get the Roblox ID before continuing
robloxUserId = getRobloxUserId(targetPlayer)
if not robloxUserId then
    print("[WARNING] Could not fetch Roblox User ID - avatar thumbnails will be disabled")
end

print("[DEBUG] HttpService exists: " .. tostring(HttpService ~= nil))

-- Enable HTTP requests
pcall(function()
    HttpService.HttpEnabled = true
end)

local stats = ReplicatedStorage:FindFirstChild("Stats")
local leaderboard = Workspace:FindFirstChild("Leaderboards")
local compLeaderboard = leaderboard and leaderboard:FindFirstChild("CompLeaderboardScore")
local main = compLeaderboard and compLeaderboard:FindFirstChild("Main")

print("[DEBUG] Stats found: " .. tostring(stats ~= nil))
print("[DEBUG] Leaderboard found: " .. tostring(leaderboard ~= nil))

local lastData = {}
local lastSendTime = 0
local lastActivityTime = os.time()
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
    if not robloxUserId then
        print("[DEBUG] No Roblox User ID available, skipping avatar")
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
    local targetStats = stats and stats:FindFirstChild(targetPlayer)
    if not targetStats then 
        return nil 
    end
    
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

local function sendToDiscord(data, reason, isInitial)
    local avatarUrl = getAvatarThumbnail()
    
    -- Calculate gains over 30 minutes
    local compGain = ""
    local compGainValue = 0
    local rubiesGain = ""
    local rubiesGainValue = 0
    local throwsGain = ""
    local throwsGainValue = 0
    
    if lastData.compScore and data.compScore > lastData.compScore then
        compGainValue = data.compScore - lastData.compScore
        compGain = string.format(" (+%s)", formatNumber(compGainValue))
    end
    
    if lastData.rubies and data.rubies > lastData.rubies then
        rubiesGainValue = data.rubies - lastData.rubies
        rubiesGain = string.format(" (+%s)", formatNumber(rubiesGainValue))
    end
    
    if lastData.throws and data.throws > lastData.throws then
        throwsGainValue = data.throws - lastData.throws
        throwsGain = string.format(" (+%s)", formatNumber(throwsGainValue))
    end
    
    local embed = {
        title = targetPlayer .. " - Stats Update",
        color = 0x3498db,
        thumbnail = avatarUrl and {url = avatarUrl} or nil,
        fields = {
            {name = "🟪 Enchant Gems", value = formatNumber(data.enchantGems), inline = true},
            {name = "🔴 Rubies", value = formatNumber(data.rubies) .. rubiesGain, inline = true},
            {name = "🏆 Comp Score", value = formatNumber(data.compScore) .. compGain, inline = true},
            {name = "⏱️ Session Time", value = data.hours .. "h " .. data.minutes .. "m", inline = true},
            {name = "🪨 Throws", value = formatNumber(data.throws) .. throwsGain, inline = true},
            {name = "😂 AutoThrow", value = data.autoThrow and "✅ Enabled" or "❌ Disabled", inline = true},
            {name = "📊 Rank", value = data.rank, inline = true},
        },
        footer = {text = "📌 " .. reason .. " | Next update in 30 minutes"}
    }
    
    -- Add 68exp under thumbnail
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
        print("✅ Sent to Discord | Reason: " .. reason)
        return true
    else
        print("❌ Failed to send | Status: " .. tostring(response and response.StatusCode or "nil"))
        return false
    end
end

-- Main loop
local function mainLoop()
    print("[DEBUG] Waiting 5 seconds for game to load...")
    task.wait(5)
    
    local initialData = getCurrentData()
    if initialData then
        print("[DEBUG] Got initial data, sending immediately...")
        lastData = initialData
        sendToDiscord(initialData, "🟢 Initial Load", true)
        lastSendTime = os.time()
        lastActivityTime = os.time()
    else
        print("[ERROR] Could not find player stats! Make sure '" .. targetPlayer .. "' is in the game")
        print("[DEBUG] Available Stats children:")
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
            lastData = currentData
            
            -- Send every 30 minutes (1800 seconds)
            if os.time() - lastSendTime >= 1800 then
                if sendToDiscord(currentData, "⏰ 30 Minute Update", false) then
                    lastSendTime = os.time()
                    lastActivityTime = os.time()
                end
            end
        end
    end
end

-- Start the script
local success, err = pcall(mainLoop)
if not success then
    print("[FATAL] Script error: " .. tostring(err))
end
