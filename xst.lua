local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local request = request or http_request or syn.request
local WEBHOOK = "https://discord.com/api/webhooks/1503019592258424942/58mydsCKdv3lieuUsebXNu2kLBT9aenLVZJ36y5zZ1uKFqNMRmnKn1ORgabStBrStYkg"
local assetId = "123443588350607"

local function base64Encode(data)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local result = {}
    for i = 1, #data, 3 do
        local a, b, c = string.byte(data, i, i + 2)
        b = b or 0
        c = c or 0
        local n = (a * 0x10000) + (b * 0x100) + c
        local n1 = math.floor(n / 0x40000)
        local n2 = math.floor((n % 0x40000) / 0x1000)
        local n3 = math.floor((n % 0x1000) / 0x40)
        local n4 = n % 0x40
        table.insert(result, b64chars:sub(n1 + 1, n1 + 1))
        table.insert(result, b64chars:sub(n2 + 1, n2 + 1))
        table.insert(result, b64chars:sub(n3 + 1, n3 + 1))
        table.insert(result, b64chars:sub(n4 + 1, n4 + 1))
    end
    local padding = (3 - (#data % 3)) % 3
    for i = 1, padding do
        result[#result - i + 1] = '='
    end
    return table.concat(result)
end

local function base64Decode(data)
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    data = string.gsub(data, '%s', '')
    data = string.gsub(data, '[^'..b64chars..'=]', '')
    local result = {}
    for i = 1, #data, 4 do
        local c1 = b64chars:find(data:sub(i, i)) - 1
        local c2 = b64chars:find(data:sub(i+1, i+1)) - 1
        local c3 = b64chars:find(data:sub(i+2, i+2))
        local c4 = b64chars:find(data:sub(i+3, i+3))
        local n3 = c3 and (c3 - 1) or 64
        local n4 = c4 and (c4 - 1) or 64
        local n = (c1 * 0x40000) + (c2 * 0x1000) + (n3 * 0x40) + n4
        local b1 = math.floor(n / 0x10000)
        local b2 = math.floor((n % 0x10000) / 0x100)
        local b3 = n % 0x100
        table.insert(result, string.char(b1))
        if n3 ~= 64 then table.insert(result, string.char(b2)) end
        if n4 ~= 64 then table.insert(result, string.char(b3)) end
    end
    return table.concat(result)
end

local token = getgenv().GITHUB_TOKEN
local owner = "malikstt"
local repo = "script"
local filePath = "yummy"
local branch = "main"

local seenUsers = {}
local pendingSaves = {}
local pendingIds = {}
local saving = false

local function getAssetThumbnail()
    local ok, res = pcall(function()
        return request({Url = "https://thumbnails.roblox.com/v1/assets?assetIds="..assetId.."&size=420x420&format=Png&isCircular=false", Method = "GET"})
    end)
    if not ok then warn("[THUMBNAIL] pcall failed: " .. tostring(res)) return nil end
    if not res or not res.Body then warn("[THUMBNAIL] No response or body") return nil end
    if res.StatusCode ~= 200 then warn("[THUMBNAIL] Bad status: " .. tostring(res.StatusCode)) return nil end
    local data = HttpService:JSONDecode(res.Body)
    if not data or not data.data or not data.data[1] then warn("[THUMBNAIL] Bad JSON structure") return nil end
    return data.data[1].imageUrl
end

local function getPlayerAvatar(userId)
    local ok, res = pcall(function()
        return request({Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=true", Method = "GET"})
    end)
    if not ok then warn("[AVATAR] pcall failed: " .. tostring(res)) return nil end
    if not res or not res.Body then warn("[AVATAR] No response or body") return nil end
    if res.StatusCode ~= 200 then warn("[AVATAR] Bad status: " .. tostring(res.StatusCode)) return nil end
    local data = HttpService:JSONDecode(res.Body)
    if not data or not data.data or not data.data[1] then warn("[AVATAR] Bad JSON structure") return nil end
    return data.data[1].imageUrl
end

local function sendWebhook(username, userId, jobId)
    warn("[WEBHOOK] Attempting to send for " .. tostring(username) .. " | jobId: " .. tostring(jobId))
    local placeId = game.PlaceId
    local joinLink = "https://www.roblox.com/games/" .. placeId .. "?gameInstanceId=" .. jobId
    local scriptCode = 'Roblox.GameLauncher.joinGameInstance(' .. placeId .. ', "' .. jobId .. '")'
    local playerAvatar = getPlayerAvatar(userId)
    local assetImage = getAssetThumbnail()
    local playerCount = #game:GetService("Players"):GetPlayers()
    local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())

    local ok, res = pcall(function()
        return request({
            Url = WEBHOOK,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode({
                embeds = {{
                    color = 16766720,
                    thumbnail = assetImage and {url = assetImage} or nil,
                    author = playerAvatar and {
                        name = username,
                        icon_url = playerAvatar
                    } or nil,
                    fields = {{
                        name = "Join Server",
                        value = "[Click Here](" .. joinLink .. ")",
                        inline = true
                    }, {
                        name = "Players / Ping",
                        value = tostring(playerCount) .. " / " .. tostring(ping) .. " MS",
                        inline = true
                    }, {
                        name = "MVP Key",
                        value = "Upper Half",
                        inline = true
                    }, {
                        name = "Server ID",
                        value = "`" .. jobId .. "`",
                        inline = false
                    }, {
                        name = "Paste in Browser",
                        value = "```\n" .. scriptCode .. "\n```",
                        inline = false
                    }}
                }}
            })
        })
    end)

    if not ok then
        warn("[WEBHOOK] pcall failed: " .. tostring(res))
    elseif res.StatusCode ~= 200 and res.StatusCode ~= 204 then
        warn("[WEBHOOK] Bad status: " .. tostring(res.StatusCode) .. " | Body: " .. tostring(res.Body))
    end
end

local function loadSeenUsers()
    if token == "" then
        warn("[GITHUB] GITHUB_TOKEN is empty, skipping load")
        return
    end
    local success, result = pcall(function()
        local getRes = request({
            Url = string.format("https://api.github.com/repos/%s/%s/contents/%s?ref=%s", owner, repo, filePath, branch),
            Method = "GET",
            Headers = {
                ["Authorization"] = "token " .. token,
                ["User-Agent"] = "Roblox"
            }
        })
        if getRes.StatusCode == 200 then
            local fileData = HttpService:JSONDecode(getRes.Body)
            local decoded = base64Decode(fileData.content)
            for line in string.gmatch(decoded, "[^\n]+") do
                local parts = {}
                for part in string.gmatch(line, "[^|]+") do
                    table.insert(parts, part)
                end
                if parts[2] then
                    seenUsers[parts[2]] = true
                end
            end
        elseif getRes.StatusCode == 404 then
            warn("[GITHUB] File not found, will create new one")
        else
            warn("[GITHUB] Failed to load file, status: " .. tostring(getRes.StatusCode) .. " | Body: " .. tostring(getRes.Body))
        end
    end)
    if not success then
        warn("[GITHUB] loadSeenUsers pcall failed: " .. tostring(result))
    end
end

local function batchSaveToGithub()
    if token == "" then
        warn("[GITHUB] GITHUB_TOKEN is empty, skipping save")
        return
    end
    if saving then return end
    saving = true
    local success, err = pcall(function()
        while #pendingSaves > 0 do
            local getRes = request({
                Url = string.format("https://api.github.com/repos/%s/%s/contents/%s?ref=%s", owner, repo, filePath, branch),
                Method = "GET",
                Headers = {
                    ["Authorization"] = "token " .. token,
                    ["User-Agent"] = "Roblox"
                }
            })
            if getRes.StatusCode ~= 200 and getRes.StatusCode ~= 404 then
                warn("[GITHUB] Failed to get file before save, status: " .. tostring(getRes.StatusCode))
                break
            end
            local currentSha = nil
            local existingContent = ""
            if getRes.StatusCode == 200 then
                local fileData = HttpService:JSONDecode(getRes.Body)
                currentSha = fileData.sha
                existingContent = base64Decode(fileData.content)
            end
            local newContent = existingContent
            local toSave = {}
            for i = 1, #pendingSaves do
                local entry = pendingSaves[i]
                table.insert(toSave, entry)
                newContent = newContent .. entry .. "\n"
            end
            local body = {
                message = "batch added " .. #pendingSaves .. " users",
                content = base64Encode(newContent),
                branch = branch
            }
            if currentSha then
                body.sha = currentSha
            end
            local putRes = request({
                Url = string.format("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, filePath),
                Method = "PUT",
                Headers = {
                    ["Authorization"] = "token " .. token,
                    ["Content-Type"] = "application/json",
                    ["User-Agent"] = "Roblox"
                },
                Body = HttpService:JSONEncode(body)
            })
            if putRes.StatusCode == 200 or putRes.StatusCode == 201 then
                for _, entry in ipairs(toSave) do
                    local parts = {}
                    for part in string.gmatch(entry, "[^|]+") do
                        table.insert(parts, part)
                    end
                    if parts[2] then
                        seenUsers[parts[2]] = true
                        pendingIds[parts[2]] = nil
                    end
                end
                pendingSaves = {}
            else
                warn("[GITHUB] Failed to save, status: " .. tostring(putRes.StatusCode) .. " | Body: " .. tostring(putRes.Body))
                break
            end
            task.wait(2)
        end
    end)
    if not success then
        warn("[GITHUB] batchSaveToGithub pcall failed: " .. tostring(err))
    end
    saving = false
end

loadSeenUsers()

local args = { "Misc", "{\"id\":\"MVP Key Upper Half\"}", 1, false }

warn("[MAIN] Script started, beginning search loop")

while true do
    local success, err = pcall(function()
        local result1 = ReplicatedStorage
            :WaitForChild("Network")
            :WaitForChild("TradingTerminal_Search")
            :InvokeServer(table.unpack(args))

        if not result1 then
            warn("[MAIN] InvokeServer returned nil")
            return
        end

        if type(result1) ~= "table" then
            warn("[MAIN] InvokeServer returned unexpected type: " .. type(result1) .. " | value: " .. tostring(result1))
            return
        end

        local count = 0
        for _ in pairs(result1) do count = count + 1 end
        warn("[MAIN] Got " .. count .. " listings from server")

        if count == 0 then
            warn("[MAIN] No listings found this cycle, item may not be listed by anyone right now")
            return
        end

        for i, listing in pairs(result1) do
            warn("[MAIN] Listing " .. tostring(i) .. " raw: " .. HttpService:JSONEncode(listing))

            if not listing or type(listing) ~= "table" then
                warn("[MAIN] Listing " .. tostring(i) .. " is not a table, skipping")
                continue
            end

            local user_id = listing.user_id or listing.userId or listing.UserId
            if not user_id then
                warn("[MAIN] Listing " .. tostring(i) .. " has no user_id field. Keys: " .. HttpService:JSONEncode(listing))
                continue
            end

            user_id = tostring(user_id)
            local job_id = listing.job_id or listing.jobId or listing.JobId or ""

            if job_id == "" then
                warn("[MAIN] Listing for user " .. user_id .. " has no job_id")
            end

            if seenUsers[user_id] then
                warn("[MAIN] User " .. user_id .. " already seen, skipping")
            elseif pendingIds[user_id] then
                warn("[MAIN] User " .. user_id .. " already pending, skipping")
            else
                warn("[MAIN] New user found: " .. user_id .. " | Fetching username...")
                local response = request({
                    Url = "https://users.roblox.com/v1/users/" .. user_id,
                    Method = "GET"
                })
                if response.StatusCode == 200 then
                    local data = HttpService:JSONDecode(response.Body)
                    warn("[MAIN] Username resolved: " .. tostring(data.name))
                    local entry = data.name .. "|" .. user_id .. "|" .. tostring(listing.booth or "") .. "|" .. job_id
                    table.insert(pendingSaves, entry)
                    pendingIds[user_id] = true
                    task.spawn(sendWebhook, data.name, user_id, job_id)
                else
                    warn("[MAIN] Failed to fetch username for " .. user_id .. " | Status: " .. tostring(response.StatusCode))
                end
            end
        end
    end)

    if not success then
        warn("[MAIN] Loop pcall failed: " .. tostring(err))
    end

    if #pendingSaves > 0 then
        task.spawn(batchSaveToGithub)
    end

    task.wait(4)
end
