local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local webhookUrl = "https://discord.com/api/webhooks/1497999446028587128/nTY1lOe95jZXpEMXJu0oxqG3RXkp75gqy70qswx44o9ummGlLNEe_RyYpszPo_YxwlI0"

local targetPlayer = "68exp"
local userId = "921793487509278730"

print("[DEBUG] Script started - checking services...")
print("[DEBUG] ReplicatedStorage exists: " .. tostring(ReplicatedStorage ~= nil))
print("[DEBUG] Workspace exists: " .. tostring(Workspace ~= nil))
print("[DEBUG] HttpService exists: " .. tostring(HttpService ~= nil))
print("[DEBUG] Players exists: " .. tostring(Players ~= nil))

-- Enable HTTP requests
pcall(function()
    HttpService.HttpEnabled = true
    print("[DEBUG] HttpEnabled set to true")
end)

local stats = ReplicatedStorage:FindFirstChild("Stats")
local leaderboard = Workspace:FindFirstChild("Leaderboards")
local compLeaderboard = leaderboard and leaderboard:FindFirstChild("CompLeaderboardScore")
local main = compLeaderboard and compLeaderboard:FindFirstChild("Main")

print("[DEBUG] Stats found: " .. tostring(stats ~= nil))
print("[DEBUG] Leaderboard found: " .. tostring(leaderboard ~= nil))
print("[DEBUG] CompLeaderboard found: " .. tostring(compLeaderboard ~= nil))
print("[DEBUG] Main found: " .. tostring(main ~= nil))

local lastData = {}
local lastSendTime = 0
local lastActivityTime = os.time()
local playerLeftTimer = nil
local isRunning = true
local lastInactivitySend = 0
local wasGone = false
local errorCount = 0

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
    local url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. userId .. "&size=150x150&format=Png&isCircular=true"
    print("[DEBUG] Fetching avatar thumbnail from: " .. url)
    
    local success, response = pcall(function()
        return request({
            Url = url, 
            Method = "GET"
        })
    end)
    
    if success and response then
        print("[DEBUG] Avatar request success, response status: " .. tostring(response.StatusCode))
        if response.StatusCode == 200 then
            local decodeSuccess, data = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)
            if decodeSuccess and data and data.data and data.data[1] and data.data[1].imageUrl then
                print("[DEBUG] Avatar URL obtained: " .. data.data[1].imageUrl)
                return data.data[1].imageUrl
            else
                print("[DEBUG] Failed to decode avatar response or missing image URL")
            end
        else
            print("[DEBUG] Avatar request failed with status: " .. tostring(response.StatusCode))
        end
    else
        print("[DEBUG] Avatar request failed: " .. tostring(success))
        if response then
            print("[DEBUG] Error response: " .. tostring(response))
        end
    end
    return nil
end

local function getCurrentData()
    print("[DEBUG] Getting current data for player: " .. targetPlayer)
    local targetStats = stats and stats:FindFirstChild(targetPlayer)
    if not targetStats then
        print("[DEBUG] Target stats not found for: " .. targetPlayer)
        print("[DEBUG] Available children in Stats: ")
        if stats then
            for _, child in ipairs(stats:GetChildren()) do
                print("[DEBUG]   - " .. child.Name)
            end
        end
        return nil 
    end
    print("[DEBUG] Target stats found")
    
    local enchantGems = targetStats:FindFirstChild("EnchantGems")
    local compScore = targetStats:FindFirstChild("CompLeaderboardScore")
    local sessionTime = targetStats:FindFirstChild("Analytics") and targetStats.Analytics:FindFirstChild("SessionTime")
    local rubies = targetStats:FindFirstChild("Twenty Event") and targetStats["Twenty Event"]:FindFirstChild("Rubies")
    local autoThrow = targetStats:FindFirstChild("Settings") and targetStats.Settings:FindFirstChild("AutoThrow")
    local throws = targetStats:FindFirstChild("Analytics") and targetStats.Analytics:FindFirstChild("Throws")
    
    print("[DEBUG] Stats found - EnchantGems: " .. tostring(enchantGems ~= nil))
    print("[DEBUG] Stats found - CompScore: " .. tostring(compScore ~= nil))
    print("[DEBUG] Stats found - SessionTime: " .. tostring(sessionTime ~= nil))
    print("[DEBUG] Stats found - Rubies: " .. tostring(rubies ~= nil))
    print("[DEBUG] Stats found - AutoThrow: " .. tostring(autoThrow ~= nil))
    print("[DEBUG] Stats found - Throws: " .. tostring(throws ~= nil))
    
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
    
    local data = {
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
    
    print("[DEBUG] Current data - EnchantGems: " .. data.enchantGems .. ", CompScore: " .. data.compScore .. ", Rubies: " .. data.rubies)
    return data
end

local function sendFullEmbed(data, reason)
    print("[DEBUG] sendFullEmbed called with reason: " .. reason)
    
    -- Test webhook connectivity first
    local testSuccess, testResponse = pcall(function()
        return request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({content = "Testing connection from script"})
        })
    end)
    
    if testSuccess and testResponse then
        print("[DEBUG] Webhook test sent, status: " .. tostring(testResponse.StatusCode))
        if testResponse.StatusCode ~= 204 and testResponse.StatusCode ~= 200 then
            print("[ERROR] Webhook test failed with status: " .. tostring(testResponse.StatusCode))
            if testResponse.Body then
                print("[ERROR] Response body: " .. tostring(testResponse.Body))
            end
            return
        end
    else
        print("[ERROR] Webhook test failed completely: " .. tostring(testSuccess))
        return
    end
    
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
        title = "📊 " .. targetPlayer .. " - Stats Update",
        color = 0x9b59b6,
        thumbnail = avatarUrl and {url = avatarUrl} or nil,
        fields = {
            {name = "🟪 Enchant Gems", value = formatNumber(data.enchantGems), inline = true},
            {name = "🔴 Rubies", value = formatNumber(data.rubies) .. rubiesGain, inline = true},
            {name = "🏆 S2 Comp Score", value = formatNumber(data.compScore) .. compGain, inline = true},
            {name = "⏱️ Session Time", value = data.hours .. "h " .. data.minutes .. "m", inline = true},
            {name = "🪨 Throws", value = formatNumber(data.throws) .. throwsGain, inline = true},
            {name = "😂 AutoThrow", value = autoThrowStatus, inline = true},
            {name = "📊 Rank", value = data.rank, inline = true},
        },
        footer = {text = "Trigger: " .. reason .. " | Next update in 30m | " .. os.date("%Y-%m-%d %H:%M:%S")}
    }
    
    local jsonBody = HttpService:JSONEncode({embeds = {embed}})
    print("[DEBUG] Sending embed to Discord, body length: " .. #jsonBody)
    
    local success, response = pcall(function()
        return request({
            Url = webhookUrl,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = jsonBody
        })
    end)
    
    if success then
        print("[DEBUG] Discord request completed with status: " .. tostring(response.StatusCode))
        if response.StatusCode == 204 or response.StatusCode == 200 then
            print("✅ SUCCESS: Sent stats | Reason: " .. reason)
            errorCount = 0
        else
            print("[ERROR] Discord returned status: " .. tostring(response.StatusCode))
            if response.Body then
                print("[ERROR] Response body: " .. tostring(response.Body))
            end
            errorCount = errorCount + 1
        end
    else
        print("[ERROR] Failed to send Discord webhook: " .. tostring(response))
        errorCount = errorCount + 1
    end
end

-- Rest of the functions (sendLeaveMessage, sendInactivityMessage, etc.) remain similar with debug prints added

local function mainLoop()
    print("[DEBUG] Main loop started")
    
    -- Wait a bit for everything to load
    task.wait(5)
    
    local initialData = getCurrentData()
    if initialData then
        print("[DEBUG] Initial data obtained, sending...")
        lastData = initialData
        sendFullEmbed(initialData, "Initial Load")
        lastSendTime = os.time()
        lastActivityTime = os.time()
    else
        print("[ERROR] Could not get initial data - script may not work correctly")
    end
    
    local loopCount = 0
    
    while isRunning do
        loopCount = loopCount + 1
        if loopCount % 6 == 0 then -- Print every minute (6 * 10 seconds)
            print("[DEBUG] Loop iteration " .. loopCount .. " - Script still running")
        end
        
        local currentTime = os.time()
        local currentData = getCurrentData()
        
        if currentData then
            lastData = currentData
            
            if currentTime - lastSendTime >= 1800 then
                print("[DEBUG] 30 minute interval reached, sending update")
                sendFullEmbed(currentData, "30 Minute Interval")
                lastSendTime = currentTime
                lastActivityTime = currentTime
            end
        else
            print("[DEBUG] No current data available in this iteration")
        end
        
        task.wait(10)
    end
    
    print("[DEBUG] Main loop ended")
end

print("[DEBUG] Starting main loop...")
local success, err = xpcall(mainLoop, function(err)
    print("[FATAL ERROR] " .. tostring(err))
    print("[FATAL ERROR] Stack trace: " .. debug.traceback())
end)

if not success then
    print("[FATAL ERROR] Script crashed: " .. tostring(err))
end

print("[DEBUG] Script execution completed")
