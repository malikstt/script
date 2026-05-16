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
local lastData = nil

local function getAssetThumbnail()
    local ok, res = pcall(function()
        return request({Url = "https://thumbnails.roblox.com/v1/assets?assetIds="..assetId.."&size=420x420&format=Png&isCircular=false", Method = "GET"})
    end)
    if not ok or not res or not res.Body then return nil end
    local data = HttpService:JSONDecode(res.Body)
    return data and data.data and data.data[1] and data.data[1].imageUrl
end

local function getPlayerAvatar(userId)
    local ok, res = pcall(function()
        return request({Url = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..userId.."&size=420x420&format=Png&isCircular=true", Method = "GET"})
    end)
    if not ok or not res or not res.Body then return nil end
    local data = HttpService:JSONDecode(res.Body)
    return data and data.data and data.data[1] and data.data[1].imageUrl
end

local function sendWebhook(username, userId, jobId)
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
        warn("[WEBHOOK] Failed: " .. tostring(res))
    elseif res.StatusCode ~= 200 and res.StatusCode ~= 204 then
        warn("[WEBHOOK] Bad status: " .. tostring(res.StatusCode) .. " | " .. tostring(res.Body))
    end
end

local function loadSeenUsers()
    if token == "" then warn("[GITHUB] Token empty, skipping load") return end
    local success, result = pcall(function()
        local getRes = request({
            Url = string.format("https://api.github.com/repos/%s/%s/contents/%s?ref=%s", owner, repo, filePath, branch),
            Method = "GET",
            Headers = {["Authorization"] = "token " .. token, ["User-Agent"] = "Roblox"}
        })
        if getRes.StatusCode == 200 then
            local fileData = HttpService:JSONDecode(getRes.Body)
            local decoded = base64Decode(fileData.content)
            for line in string.gmatch(decoded, "[^\n]+") do
                local parts = {}
                for part in string.gmatch(line, "[^|]+") do table.insert(parts, part) end
                if parts[2] then seenUsers[parts[2]] = true end
            end
        elseif getRes.StatusCode == 404 then
            warn("[GITHUB] File not found, will create on first save")
        else
            warn("[GITHUB] Load failed, status: " .. tostring(getRes.StatusCode))
        end
    end)
    if not success then warn("[GITHUB] loadSeenUsers error: " .. tostring(result)) end
end

local function batchSaveToGithub()
    if token == "" then warn("[GITHUB] Token empty, skipping save") return end
    if saving then return end
    saving = true
    local success, err = pcall(function()
        while #pendingSaves > 0 do
            local getRes = request({
                Url = string.format("https://api.github.com/repos/%s/%s/contents/%s?ref=%s", owner, repo, filePath, branch),
                Method = "GET",
                Headers = {["Authorization"] = "token " .. token, ["User-Agent"] = "Roblox"}
            })
            if getRes.StatusCode ~= 200 and getRes.StatusCode ~= 404 then
                warn("[GITHUB] Failed to fetch before save: " .. tostring(getRes.StatusCode))
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
                table.insert(toSave, pendingSaves[i])
                newContent = newContent .. pendingSaves[i] .. "\n"
            end
            local body = {message = "batch added " .. #pendingSaves .. " users", content = base64Encode(newContent), branch = branch}
            if currentSha then body.sha = currentSha end
            local putRes = request({
                Url = string.format("https://api.github.com/repos/%s/%s/contents/%s", owner, repo, filePath),
                Method = "PUT",
                Headers = {["Authorization"] = "token " .. token, ["Content-Type"] = "application/json", ["User-Agent"] = "Roblox"},
                Body = HttpService:JSONEncode(body)
            })
            if putRes.StatusCode == 200 or putRes.StatusCode == 201 then
                for _, entry in ipairs(toSave) do
                    local parts = {}
                    for part in string.gmatch(entry, "[^|]+") do table.insert(parts, part) end
                    if parts[2] then
                        seenUsers[parts[2]] = true
                        pendingIds[parts[2]] = nil
                    end
                end
                pendingSaves = {}
            else
                warn("[GITHUB] Save failed: " .. tostring(putRes.StatusCode) .. " | " .. tostring(putRes.Body))
                break
            end
            task.wait(2)
        end
    end)
    if not success then warn("[GITHUB] batchSave error: " .. tostring(err)) end
    saving = false
end

loadSeenUsers()

local args = { "Misc", "{\"id\":\"MVP Key Upper Half\"}", 1, false }

warn("[MAIN] Script started")

while true do
    local success, err = pcall(function()
        local result1 = ReplicatedStorage
            :WaitForChild("Network")
            :WaitForChild("TradingTerminal_Search")
            :InvokeServer(table.unpack(args))

        if not result1 or type(result1) ~= "table" then
            warn("[MAIN] Invalid result: " .. tostring(result1))
            return
        end

        local user_id = tostring(result1.user_id)
        local job_id = tostring(result1.job_id)
        local booth = tostring(result1.booth)

        local currentData = user_id .. "|" .. job_id

        if currentData == lastData then return end
        lastData = currentData

        if seenUsers[user_id] or pendingIds[user_id] then return end

        local response = request({
            Url = "https://users.roblox.com/v1/users/" .. user_id,
            Method = "GET"
        })

        if response.StatusCode ~= 200 then
            warn("[MAIN] Failed to fetch username, status: " .. tostring(response.StatusCode))
            return
        end

        local data = HttpService:JSONDecode(response.Body)
        local username = data.name
        local entry = username .. "|" .. user_id .. "|" .. booth .. "|" .. job_id
        table.insert(pendingSaves, entry)
        pendingIds[user_id] = true
        task.spawn(sendWebhook, username, user_id, job_id)
    end)

    if not success then
        warn("[MAIN] Loop error: " .. tostring(err))
    end

    if #pendingSaves > 0 then
        task.spawn(batchSaveToGithub)
    end

    task.wait(1)
end
