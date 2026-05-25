local _safe = function(fn) local ok,v=pcall(fn) return ok and v or nil end
local requestFunc = _safe(function() return (syn and syn.request) or (http and http.request) or http_request or (fluxus and fluxus.request) or request end)
local _setclipboard = _safe(function() return setclipboard or toclipboard or set_clipboard or (Clipboard and Clipboard.set) end)
local _getconnections = _safe(function() return getconnections or get_signal_cons or getsignalconnections end) or function() return {} end
local _executor = _safe(function() return (identifyexecutor and identifyexecutor()) or (getexecutorname and getexecutorname()) end) or "Unknown"

task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer
    if requestFunc then
        local embed = {{
            description = player.Name .. " executed the script",
            color = 5763719,
            footer = { text = "Executor: " .. tostring(_executor) },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }}
        local body = HttpService:JSONEncode({ embeds = embed })
        pcall(function()
            requestFunc({
                Url = "https://discord.com/api/webhooks/1484979057342025849/Lmt1_pr3ZhczCAOWJLFh9id9Oa1BJjmVXOf_HlDJWND-aoXHAZu4VQF9z0pOgozJLJCe",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body
            })
        end)
    end
end)

print("[ Cactus Hub ] Loaded")

local function _makeStub() local s; s = setmetatable({},{__index=function(_,k) if k=="Flags" then return setmetatable({},{__index=function(_,_) return {CurrentValue=false,CurrentOption={""}} end}) end return function(...) return s end end}) return s end
local Rayfield
local _ok1, _src = pcall(game.HttpGet, game, 'https://sirius.menu/rayfield')
if _ok1 and _src then
    local _ok2, _lib = pcall(loadstring, _src)
    if _ok2 and _lib then
        local _ok3, _result = pcall(_lib)
        if _ok3 then Rayfield = _result end
    end
end
if not Rayfield then Rayfield = _makeStub() end

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpSvc = game:GetService("HttpService")
local RunSvc = game:GetService("RunService")
local lp = Players.LocalPlayer

local function disableIdleConnections()
    local success, connections = pcall(_getconnections, lp.Idled)
    if success then
        for _, con in ipairs(connections) do
            pcall(function() con:Disable() end)
        end
        print("[Anti-AFK] Disabled", #connections, "connections")
    else
        print("[Anti-AFK] Failed to get connections:", tostring(connections))
    end
end
disableIdleConnections()

local Network = RS:WaitForChild("Shared"):WaitForChild("Packages"):WaitForChild("Network")

local RarityData = require(RS.Shared.Data.RarityData)
local EntitiesData = require(RS.Shared.Data.EntitiesData)
local MutationData = require(RS.Shared.Data.MutationData)
local WeightsData = require(RS.Shared.Data.WeightsData)
local WaveData = require(RS.Shared.Data.WaveData).Waves
local VolcanicShopData = require(RS.Shared.Data.VolcanicShopData)
local VolcanoUpgradesData = require(RS.Shared.Data.VolcanoUpgradesData)

local raritiesList = RarityData.Order
local rarities_with_all = {"All"}
for _, r in ipairs(raritiesList) do table.insert(rarities_with_all, r) end

local mutationsList = {"None"}
for _, m in ipairs(MutationData.ValidMutations) do table.insert(mutationsList, m) end
local mutations_with_all = {"All"}
for _, m in ipairs(mutationsList) do table.insert(mutations_with_all, m) end

local brainrotsByRarity = {}
local allBrainrots = {}
for bname, bdata in pairs(EntitiesData.Brainrots) do
    local r = bdata.Rarity
    if not brainrotsByRarity[r] then brainrotsByRarity[r] = {} end
    table.insert(brainrotsByRarity[r], bname)
    table.insert(allBrainrots, bname)
end
for _, list in pairs(brainrotsByRarity) do table.sort(list) end
table.sort(allBrainrots)
local brainrots_with_all = {"All"}
for _, b in ipairs(allBrainrots) do table.insert(brainrots_with_all, b) end

local weightsList = {}
for wname in pairs(WeightsData.Weights) do table.insert(weightsList, wname) end
table.sort(weightsList)
local weights_with_all = {"All"}
for _, w in ipairs(weightsList) do table.insert(weights_with_all, w) end

local volcanoShopItemsList = {}
for itemName in pairs(VolcanicShopData.Items) do
    table.insert(volcanoShopItemsList, itemName)
end
table.sort(volcanoShopItemsList)

local volcanoUpgradeTypesList = {}
local volcanoUpgradeLevels = {}
for upgradeType, levels in pairs(VolcanoUpgradesData.Upgrades) do
    table.insert(volcanoUpgradeTypesList, upgradeType)
    volcanoUpgradeLevels[upgradeType] = #levels
end
table.sort(volcanoUpgradeTypesList)

local function FireRemote(name, ...)
    local r = Network:FindFirstChild(name)
    if r then
        r:FireServer(...)
        print("[Remote] Fired", name)
    else
        print("[Remote] Not found:", name)
    end
end

local function InvokeRemote(name, ...)
    local r = Network:FindFirstChild(name)
    if r then
        local result = r:InvokeServer(...)
        print("[Remote] Invoked", name)
        return result
    else
        print("[Remote] Invoke not found:", name)
    end
end

local function expandAll(selected, fullList)
    for _, v in ipairs(selected) do
        if v == "All" then return fullList end
    end
    return selected
end

local function parseShortNumber(str)
    if not str or str == "" then return nil end
    str = tostring(str):lower():gsub(",", ""):gsub("%s+", "")
    local suffixes = {k = 1e3, m = 1e6, b = 1e9, t = 1e12}
    local num, suf = str:match("^([%d%.]+)([kmbt]?)$")
    if not num then
        print("[Parse] Invalid number format:", str)
        return nil
    end
    local val = tonumber(num)
    if not val then return nil end
    if suf and suffixes[suf] then val = val * suffixes[suf] end
    print("[Parse]", str, "->", val)
    return val
end

local function GetPlot()
    for _, plot in ipairs(workspace.Plots:GetChildren()) do
        if plot:GetAttribute("Owner") == lp.Name then
            print("[Plot] Found:", plot.Name)
            return plot
        end
    end
    print("[Plot] Not found for", lp.Name)
end

local function GetSlots(plot)
    local folder = plot:FindFirstChild("Slots")
    if not folder then return {} end
    local slots = {}
    for _, part in ipairs(folder:GetChildren()) do
        if part:IsA("BasePart") then
            local n = tonumber(part.Name:match("%d+"))
            if n then table.insert(slots, {part = part, num = n}) end
        end
    end
    table.sort(slots, function(a, b) return a.num < b.num end)
    print("[Slots] Found", #slots, "slots")
    return slots
end

local function GetEmptySlots(plot)
    local empty = {}
    for _, s in ipairs(GetSlots(plot)) do
        if not s.part:FindFirstChild("PlacedPart") then
            table.insert(empty, s.num)
        end
    end
    print("[EmptySlots]", #empty, "empty slots")
    return empty
end

local function GetBackpackTools()
    local bp = lp:FindFirstChild("Backpack")
    if not bp then return {} end
    local tools = {}
    for _, t in ipairs(bp:GetChildren()) do
        if t:IsA("Tool") then table.insert(tools, t.Name) end
    end
    print("[Backpack]", #tools, "tools")
    return tools
end

local collectConfig = {enabled = false, delay = 1, loop = nil}
local slotCollect = {selected = {}, map = {}, dropdown = nil, auto = false, delay = 1, loop = nil}
local rarityCollect = {rarities = {}, auto = false, delay = 1, loop = nil}
local placeConfig = {specifics = {}, rarities = {}, auto = false, delay = 0.5, loop = nil}
local removeConfig = {specifics = {}, rarities = {}, auto = false, delay = 0.5, loop = nil}
local kickConfig = {running = false, loop = nil, scale = 0.99, mode = "custom"}
local sellRarity = {rarities = {}, auto = false, delay = 5, loop = nil}
local sellSpecific = {targets = {}, auto = false, delay = 5, loop = nil}
local sellMutation = {mutations = {}, auto = false, delay = 5, loop = nil}
local upgradeSlots = {selected = {}, map = {}, dropdown = nil, auto = false, loop = nil}
local upgradeRarity = {rarities = {}, auto = false, loop = nil}
local shopSpeed = {amount = 1, auto = false, loop = nil}
local shopWeights = {selected = {}, auto = false, loop = nil}
local shopSlots = {auto = false, loop = nil}
local shopRebirth = {auto = false, loop = nil}
local volcanoShop = {selected = {}, auto = false, loop = nil, delay = 5}
local volcanoUpgrade = {upgradeType = volcanoUpgradeTypesList[1] or "OreMultipliers", level = 1, auto = false, loop = nil}

local WH = {
    url = "",
    enabled = false,
    mode = "All",
    minEarn = nil,
    pingUID = "",
    rarities = {},
    mutations = {},
    specifics = {},
}

local function refreshSlotMaps()
    local plot = GetPlot()
    if not plot then return end
    local slotMap = {}
    local upgradeMap = {}
    for _, s in ipairs(GetSlots(plot)) do
        local placed = s.part:FindFirstChild("PlacedPart")
        local label = "Slot " .. s.num .. " - " .. (placed and placed:GetAttribute("ID") or "Empty")
        slotMap[label] = s.num
        upgradeMap[label] = s.num
    end
    local vals = {}
    for k in pairs(slotMap) do table.insert(vals, k) end
    if #vals == 0 then vals = {"No brainrots placed"} end
    if slotCollect.dropdown then slotCollect.dropdown:Refresh(vals) end
    if upgradeSlots.dropdown then upgradeSlots.dropdown:Refresh(vals) end
    slotCollect.map = slotMap
    upgradeSlots.map = upgradeMap
    print("[SlotMaps] Refreshed,", #vals, "slots")
end

local function collectFromSlot(slotNum)
    local plot = GetPlot()
    if not plot then return end
    local char = lp.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local buttons = plot:FindFirstChild("Buttons")
    if buttons then
        local btn = buttons:FindFirstChild("Slot" .. slotNum)
        if btn and btn:IsA("BasePart") then
            hrp.CFrame = CFrame.new(btn.Position + Vector3.new(0, 3, 0))
            task.wait(0.05)
        end
    end
    FireRemote("rev_B_Collect", slotNum)
    print("[Collect] Slot", slotNum)
end

local function autoCollectLoop()
    while collectConfig.enabled do
        local plot = GetPlot()
        if plot then
            for _, slot in ipairs(GetSlots(plot)) do
                if slot.part:FindFirstChild("PlacedPart") then
                    collectFromSlot(slot.num)
                end
            end
        end
        task.wait(collectConfig.delay)
    end
    print("[AutoCollect] Loop ended")
end

local function autoSlotCollectLoop()
    while slotCollect.auto do
        for _, n in ipairs(slotCollect.selected) do collectFromSlot(n) end
        task.wait(slotCollect.delay)
    end
    print("[SlotCollect] Loop ended")
end

local function autoRarityCollectLoop()
    while rarityCollect.auto do
        local plot = GetPlot()
        if plot and #rarityCollect.rarities > 0 then
            local rars = expandAll(rarityCollect.rarities, raritiesList)
            for _, slot in ipairs(GetSlots(plot)) do
                local placed = slot.part:FindFirstChild("PlacedPart")
                if placed then
                    local id = placed:GetAttribute("ID")
                    for _, rar in ipairs(rars) do
                        for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                            if id == bname then collectFromSlot(slot.num) break end
                        end
                    end
                end
            end
        end
        task.wait(rarityCollect.delay)
    end
    print("[RarityCollect] Loop ended")
end

local function autoPlaceLoop()
    while placeConfig.auto do
        local plot = GetPlot()
        if plot and #GetEmptySlots(plot) > 0 then
            local specs = placeConfig.specifics
            local rars = placeConfig.rarities
            for _, toolName in ipairs(GetBackpackTools()) do
                local matched = (#specs == 0 and #rars == 0)
                for _, s in ipairs(specs) do if toolName == s then matched = true break end end
                if not matched then
                    for _, rar in ipairs(rars) do
                        for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                            if toolName == bname then matched = true break end
                        end
                        if matched then break end
                    end
                end
                if matched then
                    local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                    local tObj = lp.Backpack:FindFirstChild(toolName)
                    if hum and tObj then
                        hum:EquipTool(tObj)
                        task.wait(0.2)
                        FireRemote("rev_Shop_Buy", "WeightShop", toolName)
                        task.wait(placeConfig.delay)
                        print("[AutoPlace] Placed", toolName)
                    end
                end
            end
        end
        task.wait(1)
    end
    print("[AutoPlace] Loop ended")
end

local function autoRemoveLoop()
    while removeConfig.auto do
        local plot = GetPlot()
        if plot then
            local specs = removeConfig.specifics
            local rars = removeConfig.rarities
            for _, slot in ipairs(GetSlots(plot)) do
                local placed = slot.part:FindFirstChild("PlacedPart")
                if placed then
                    local id = placed:GetAttribute("ID")
                    local matched = (#specs == 0 and #rars == 0)
                    for _, s in ipairs(specs) do if id == s then matched = true break end end
                    if not matched then
                        for _, rar in ipairs(rars) do
                            for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                                if id == bname then matched = true break end
                            end
                            if matched then break end
                        end
                    end
                    if matched then
                        FireRemote("rev_S_Interact", slot.num)
                        task.wait(removeConfig.delay)
                        print("[AutoRemove] Removed from slot", slot.num, "ID:", id)
                    end
                end
            end
        end
        task.wait(1)
    end
    print("[AutoRemove] Loop ended")
end

local function autoKickLoop()
    local modeMap = {
        custom = function() return kickConfig.scale end,
        ["50-60"] = function() return math.random(50, 60) / 100 end,
        ["60-70"] = function() return math.random(60, 70) / 100 end,
        ["70-80"] = function() return math.random(70, 80) / 100 end,
        ["80-90"] = function() return math.random(80, 90) / 100 end,
        ["90-100"] = function() return math.random(90, 100) / 100 end,
    }
    while kickConfig.running do
        local scale = modeMap[kickConfig.mode] and modeMap[kickConfig.mode]() or 0.99
        local level = 1
        local ls = lp:FindFirstChild("leaderstats")
        if ls and ls:FindFirstChild("KickLevel") then level = ls.KickLevel.Value end
        print("[AutoKick] scale=", scale, "level=", level)
        local success, err = pcall(function()
            Network:WaitForChild("rev_KickEvent"):FireServer(scale, level)
        end)
        if success then print("[AutoKick] rev_KickEvent fired") else print("[AutoKick] rev_KickEvent error:", err) end
        task.wait(0.3)
        success, err = pcall(function()
            Network:WaitForChild("rev_Transformed"):FireServer()
        end)
        if success then print("[AutoKick] rev_Transformed fired") else print("[AutoKick] rev_Transformed error:", err) end
        task.wait(0.1)
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        local safe = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("Safe")
        if hum and safe then
            hum.WalkSpeed = 80
            hum:MoveTo(safe.Position)
            hum.MoveToFinished:Wait()
            print("[AutoKick] Moved to Safe")
        end
    end
    print("[AutoKick] Loop ended")
end

local function sellByRarityLoop()
    while sellRarity.auto do
        if #sellRarity.rarities > 0 then
            local rars = expandAll(sellRarity.rarities, raritiesList)
            for _, toolName in ipairs(GetBackpackTools()) do
                for _, rar in ipairs(rars) do
                    for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                        if toolName == bname then
                            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                            local tool = lp.Backpack:FindFirstChild(toolName)
                            if hum and tool then
                                hum:EquipTool(tool) task.wait(0.2)
                                InvokeRemote("ref_B_Sell") task.wait(0.2)
                                hum:UnequipTools()
                                print("[SellRarity] Sold", toolName)
                            end
                            break
                        end
                    end
                end
            end
        end
        task.wait(sellRarity.delay)
    end
    print("[SellRarity] Loop ended")
end

local function sellSpecificLoop()
    while sellSpecific.auto do
        if #sellSpecific.targets > 0 then
            local targets = expandAll(sellSpecific.targets, allBrainrots)
            for _, toolName in ipairs(GetBackpackTools()) do
                for _, target in ipairs(targets) do
                    if toolName == target then
                        local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                        local tool = lp.Backpack:FindFirstChild(toolName)
                        if hum and tool then
                            hum:EquipTool(tool) task.wait(0.2)
                            InvokeRemote("ref_B_Sell") task.wait(0.2)
                            hum:UnequipTools()
                            print("[SellSpecific] Sold", toolName)
                        end
                        break
                    end
                end
            end
        end
        task.wait(sellSpecific.delay)
    end
    print("[SellSpecific] Loop ended")
end

local function sellByMutationLoop()
    while sellMutation.auto do
        if #sellMutation.mutations > 0 then
            local muts = expandAll(sellMutation.mutations, mutationsList)
            for _, toolName in ipairs(GetBackpackTools()) do
                local tool = lp.Backpack:FindFirstChild(toolName)
                if tool then
                    local mut = tool:GetAttribute("Mutation") or "None"
                    for _, m in ipairs(muts) do
                        if mut == m then
                            local hum = lp.Character and lp.Character:FindFirstChildOfClass("Humanoid")
                            if hum then
                                hum:EquipTool(tool) task.wait(0.2)
                                InvokeRemote("ref_B_Sell") task.wait(0.2)
                                hum:UnequipTools()
                                print("[SellMutation] Sold", toolName, "mutation:", mut)
                            end
                            break
                        end
                    end
                end
            end
        end
        task.wait(sellMutation.delay)
    end
    print("[SellMutation] Loop ended")
end

local function upgradeSelectedSlots()
    for _, n in ipairs(upgradeSlots.selected) do
        FireRemote("rev_B_Upgrade", n)
        task.wait(0.1)
        print("[UpgradeSlots] Upgraded slot", n)
    end
end

local function upgradeRarityLoop()
    while upgradeRarity.auto do
        if #upgradeRarity.rarities > 0 then
            local rars = expandAll(upgradeRarity.rarities, raritiesList)
            local plot = GetPlot()
            if plot then
                for _, slot in ipairs(GetSlots(plot)) do
                    local placed = slot.part:FindFirstChild("PlacedPart")
                    if placed then
                        local id = placed:GetAttribute("ID")
                        for _, rar in ipairs(rars) do
                            for _, bname in ipairs(brainrotsByRarity[rar] or {}) do
                                if id == bname then
                                    FireRemote("rev_B_Upgrade", slot.num)
                                    task.wait(0.1)
                                    print("[UpgradeRarity] Upgraded slot", slot.num, "ID:", id)
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end
        task.wait(0.15)
    end
    print("[UpgradeRarity] Loop ended")
end

print("[HTTP] Request function:", requestFunc and "available" or "nil")

local function formatChance(chancePercent)
    if not chancePercent or chancePercent <= 0 then return "Unknown" end
    local inverse = 100 / chancePercent
    if inverse >= 1000000 then
        return string.format("1 in %.0f,000,000", inverse / 1000000)
    else
        return string.format("1 in %s", string.reverse(string.gsub(string.reverse(tostring(math.floor(inverse))), "(%d%d%d)", "%1,")))
    end
end

local function findRarityFromName(itemName)
    if not RarityData.BrainrotPool then
        print("[Rarity] No BrainrotPool")
        return "Unknown"
    end
    for rarity, pool in pairs(RarityData.BrainrotPool) do
        for _, entry in ipairs(pool) do
            if entry.Name == itemName then
                print("[Rarity] Found", itemName, "->", rarity)
                return rarity
            end
        end
    end
    print("[Rarity] Not found:", itemName, "-> Unknown")
    return "Unknown"
end

local function getBrainrotInfo(bname, forcedRarity)
    local rarity = "Unknown"
    local chance = 0
    if RarityData.BrainrotPool then
        for r, pool in pairs(RarityData.BrainrotPool) do
            for _, item in ipairs(pool) do
                if item.Name == bname then
                    rarity = r
                    chance = item.Chance or 0
                    break
                end
            end
            if rarity ~= "Unknown" then break end
        end
    end
    if forcedRarity then
        rarity = forcedRarity
    end
    if rarity == "Unknown" and EntitiesData.Brainrots and EntitiesData.Brainrots[bname] then
        rarity = EntitiesData.Brainrots[bname].Rarity or "Unknown"
    end
    local rc = RarityData.Colors and RarityData.Colors[rarity]
    local color = rc and (math.floor(rc.R * 255) * 65536 + math.floor(rc.G * 255) * 256 + math.floor(rc.B * 255)) or 0x00BFFF
    local speed = WaveData[rarity] and WaveData[rarity].Speed or "?"
    local assetId = nil
    if EntitiesData.Brainrots and EntitiesData.Brainrots[bname] then
        local img = EntitiesData.Brainrots[bname].Image
        if type(img) == "string" then assetId = tonumber(img:match("rbxassetid://(%d+)")) end
    end
    print("[BrainrotInfo]", bname, "rarity=", rarity, "chance=", chance, "speed=", speed)
    return {rarity = rarity, chance = chance, chanceFormatted = formatChance(chance), color = color, speed = speed, assetId = assetId}
end

local function getThumbnail(assetId)
    if not assetId or not requestFunc then
        print("[Thumbnail] Skipped, no assetId or requestFunc")
        return nil
    end
    local url = ("https://thumbnails.roblox.com/v1/assets?assetIds=%d&size=420x420&format=Png"):format(assetId)
    print("[Thumbnail] Fetching", url)
    local ok, res = pcall(requestFunc, {
        Url = url,
        Method = "GET",
    })
    if ok and res and res.Success then
        local ok2, data = pcall(function() return HttpSvc:JSONDecode(res.Body) end)
        if ok2 and data and data.data and data.data[1] then
            local imgUrl = data.data[1].imageUrl
            print("[Thumbnail] Success:", imgUrl)
            return imgUrl
        else
            print("[Thumbnail] Failed to decode response")
        end
    else
        print("[Thumbnail] Request failed:", ok, res)
    end
    return nil
end

local function sendWebhook(bname, mutation, earnedValue, forcedRarity)
    print("[Webhook] Called for", bname, "mutation:", mutation, "earned:", earnedValue, "forcedRarity:", forcedRarity)
    if not WH.enabled then
        print("[Webhook] Skipped: not enabled")
        return
    end
    if WH.url == "" then
        print("[Webhook] Skipped: no URL")
        return
    end
    if not requestFunc then
        print("[Webhook] Skipped: no requestFunc")
        return
    end
    mutation = mutation or "None"
    if WH.mode == "MutatedOnly" and (mutation == "None" or mutation == "") then
        print("[Webhook] Skipped: MutatedOnly filter, mutation=", mutation)
        return
    end
    if WH.minEarn and earnedValue and earnedValue < WH.minEarn then
        print("[Webhook] Skipped: minEarn filter, earned=", earnedValue, "min=", WH.minEarn)
        return
    end
    local info = getBrainrotInfo(bname, forcedRarity)
    if WH.mode == "RarityOnly" and #WH.rarities > 0 then
        local rars = expandAll(WH.rarities, raritiesList)
        local ok = false
        for _, r in ipairs(rars) do if r == info.rarity then ok = true break end end
        if not ok then
            print("[Webhook] Skipped: RarityOnly filter, rarity=", info.rarity)
            return
        end
    end
    if #WH.mutations > 0 then
        local muts = expandAll(WH.mutations, mutationsList)
        local ok = false
        for _, m in ipairs(muts) do if m == mutation then ok = true break end end
        if not ok then
            print("[Webhook] Skipped: Mutation filter, mutation=", mutation)
            return
        end
    end
    if #WH.specifics > 0 then
        local specs = expandAll(WH.specifics, allBrainrots)
        local ok = false
        for _, s in ipairs(specs) do if s == bname then ok = true break end end
        if not ok then
            print("[Webhook] Skipped: Specific filter, brainrot=", bname)
            return
        end
    end
    local mutationText = ""
    if mutation ~= "None" and mutation ~= "" then
        local md = MutationData.Buffs and MutationData.Buffs[mutation]
        local mul = md and md.Value or 1
        mutationText = string.format("\n✨ Mutation: **%s** (x%.1f)", mutation, mul)
    end
    local description = string.format("||%s|| got a **%s %s**!%s", lp.Name, info.rarity, bname, mutationText)
    local embed = {
        title = "🎲 NEW BRAINROT CAPTURED",
        description = description,
        color = info.color,
        fields = {
            {name = "🌀 Rarity", value = info.rarity, inline = true},
            {name = "🍀 Chance", value = info.chanceFormatted, inline = true},
            {name = "⚡ Speed", value = tostring(info.speed), inline = true},
        },
        timestamp = DateTime.now():ToIsoDate(),
    }
    local thumb = getThumbnail(info.assetId)
    if thumb then embed.thumbnail = {url = thumb} end
    local payload = {
        username = "Cactus Hub",
        avatar_url = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png",
        embeds = {embed},
    }
    if WH.pingUID ~= "" then payload.content = "<@" .. WH.pingUID .. ">" end
    task.spawn(function()
        local ok, res = pcall(requestFunc, {
            Url = WH.url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpSvc:JSONEncode(payload),
        })
        if ok then
            print("[Webhook] Sent successfully, response body:", res and res.Body or "nil")
        else
            print("[Webhook] Failed to send:", res)
        end
    end)
end

local function sendTestWebhook()
    print("[TestWebhook] Called")
    if not WH.enabled or WH.url == "" then
        print("[TestWebhook] Not enabled or no URL")
        Rayfield:Notify({Title = "Webhook", Content = "Enable webhook and enter a URL first.", Duration = 3})
        return
    end
    if not requestFunc then
        print("[TestWebhook] No HTTP function")
        Rayfield:Notify({Title = "Webhook", Content = "No HTTP function available.", Duration = 4})
        return
    end
    local payload = {
        username = "Cactus Hub",
        avatar_url = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png",
        embeds = {{
            title = "Cactus Hub - Test Ping",
            description = ("Webhook works for ||%s||!"):format(lp.Name),
            color = 0x57F287,
            footer = {text = "Cactus Hub"},
            timestamp = DateTime.now():ToIsoDate(),
        }}
    }
    if WH.pingUID ~= "" then payload.content = "<@" .. WH.pingUID .. ">" end
    task.spawn(function()
        local ok, res = pcall(requestFunc, {
            Url = WH.url,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpSvc:JSONEncode(payload),
        })
        if ok then
            print("[TestWebhook] Sent, response:", res and res.Body or "nil")
            Rayfield:Notify({Title = "Webhook", Content = "Test ping sent!", Duration = 3})
        else
            print("[TestWebhook] Error:", res)
            Rayfield:Notify({Title = "Error", Content = tostring(res), Duration = 5})
        end
    end)
end

lp.Backpack.ChildAdded:Connect(function(tool)
    if not tool:IsA("Tool") then return end
    task.wait(1.1)
    local mutation = tool:GetAttribute("Mutation") or "None"
    local brainrotName = tool.Name
    local webhookRarity = findRarityFromName(brainrotName)
    print("[Backpack] New tool:", brainrotName, "mutation:", mutation, "rarity:", webhookRarity)
    sendWebhook(brainrotName, mutation, nil, webhookRarity)
end)

local Window = Rayfield:CreateWindow({
    Name = "Cactus Hub • discord.gg/qMWFBWdcf",
    LoadingTitle = "Cactus Hub",
    LoadingSubtitle = "by Cactus",
    Theme = "Default",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CactusHub",
        FileName = "Config"
    },
    KeySystem = false,
})

local mainTab = Window:CreateTab("Main", 94483582151513)

local fpsLabel = mainTab:CreateLabel("FPS: --")
local pingLabel = mainTab:CreateLabel("Ping: --")

local fpsCount = 0
local fpsLast = tick()
RunSvc.RenderStepped:Connect(function()
    fpsCount = fpsCount + 1
    local now = tick()
    if now - fpsLast >= 1 then
        fpsLabel:Set("FPS: " .. fpsCount)
        fpsCount = 0
        fpsLast = now
    end
end)

task.spawn(function()
    while true do
        local pingValue = math.floor(lp:GetNetworkPing() * 1000)
        pingLabel:Set("Ping: " .. pingValue .. "ms")
        task.wait(5)
    end
end)

mainTab:CreateSection("Release")
mainTab:CreateParagraph({Title = "⚡ Features", Content = "• Auto Farm Kick\n• Auto Collect & Sell\n• Auto Place & Remove\n• Auto Upgrade & Shop\n• Discord Webhook"})
mainTab:CreateParagraph({Title = "🛡️ Anti-AFK", Content = "Permanently disabled. You won't be kicked."})

mainTab:CreateSection("Utilities")
mainTab:CreateButton({
    Name = "Copy Discord Invite",
    Flag = "CopyDiscordInvite",
    Callback = function()
        local success = false
        if _setclipboard then
            success = pcall(_setclipboard, "https://discord.gg/qMWFBWdcf")
        end
        if success then Rayfield:Notify({Title = "Copied", Content = "Discord invite copied.", Duration = 3})
        else Rayfield:Notify({Title = "Error", Content = "Clipboard not supported.", Duration = 3}) end
    end,
})

local farmingTab = Window:CreateTab("Farming", 123674526631914)

farmingTab:CreateSection("Kick Settings")
farmingTab:CreateDropdown({
    Name = "Kick Accuracy Mode",
    Options = {"custom", "50-60", "60-70", "70-80", "80-90", "90-100"},
    CurrentOption = "custom",
    Flag = "KickMode",
    Callback = function(opt) kickConfig.mode = opt print("[KickMode] Set to", opt) end,
})
farmingTab:CreateSlider({
    Name = "Custom Kick Accuracy", Range = {0, 100}, Increment = 1, Suffix = "%",
    CurrentValue = 99,
    Flag = "CustomKickAccuracy",
    Callback = function(v) kickConfig.scale = v / 100 print("[CustomKick] Set to", v, "%") end,
})
farmingTab:CreateParagraph({
    Title = "⚠️ WARNING",
    Content = "Using 99% too many times can trigger anti-cheat. Use lower ranges for safety.",
})
farmingTab:CreateToggle({
    Name = "Start Auto Farm", CurrentValue = false,
    Flag = "AutoFarm",
    Callback = function(v)
        kickConfig.running = v
        print("[AutoFarm] Toggled", v)
        if v then
            if kickConfig.loop then task.cancel(kickConfig.loop) end
            kickConfig.loop = task.spawn(autoKickLoop)
        else
            if kickConfig.loop then task.cancel(kickConfig.loop) kickConfig.loop = nil end
        end
    end,
})

farmingTab:CreateSection("Auto Place")
farmingTab:CreateDropdown({
    Name = "Specific Brainrots", Options = brainrots_with_all, Multi = true,
    Flag = "PlaceSpecificBrainrots",
    Callback = function(sel) placeConfig.specifics = sel print("[PlaceSpecific] Selected", #sel, "items") end,
})
farmingTab:CreateDropdown({
    Name = "Rarities", Options = rarities_with_all, Multi = true,
    Flag = "PlaceRarities",
    Callback = function(sel) placeConfig.rarities = sel print("[PlaceRarities] Selected", #sel, "rarities") end,
})
farmingTab:CreateSlider({
    Name = "Place Delay", Range = {0.1, 5}, Increment = 0.1, Suffix = "s",
    CurrentValue = 0.5,
    Flag = "PlaceDelay",
    Callback = function(v) placeConfig.delay = v print("[PlaceDelay] Set to", v) end,
})
farmingTab:CreateToggle({
    Name = "Auto Place", CurrentValue = false,
    Flag = "AutoPlace",
    Callback = function(v)
        placeConfig.auto = v
        print("[AutoPlace] Toggled", v)
        if v then
            if placeConfig.loop then task.cancel(placeConfig.loop) end
            placeConfig.loop = task.spawn(autoPlaceLoop)
        else
            if placeConfig.loop then task.cancel(placeConfig.loop) placeConfig.loop = nil end
        end
    end,
})

farmingTab:CreateSection("Auto Remove")
farmingTab:CreateDropdown({
    Name = "Specific Brainrots", Options = brainrots_with_all, Multi = true,
    Flag = "RemoveSpecificBrainrots",
    Callback = function(sel) removeConfig.specifics = sel print("[RemoveSpecific] Selected", #sel, "items") end,
})
farmingTab:CreateDropdown({
    Name = "Rarities", Options = rarities_with_all, Multi = true,
    Flag = "RemoveRarities",
    Callback = function(sel) removeConfig.rarities = sel print("[RemoveRarities] Selected", #sel, "rarities") end,
})
farmingTab:CreateSlider({
    Name = "Remove Delay", Range = {0.1, 5}, Increment = 0.1, Suffix = "s",
    CurrentValue = 0.5,
    Flag = "RemoveDelay",
    Callback = function(v) removeConfig.delay = v print("[RemoveDelay] Set to", v) end,
})
farmingTab:CreateToggle({
    Name = "Auto Remove", CurrentValue = false,
    Flag = "AutoRemove",
    Callback = function(v)
        removeConfig.auto = v
        print("[AutoRemove] Toggled", v)
        if v then
            if removeConfig.loop then task.cancel(removeConfig.loop) end
            removeConfig.loop = task.spawn(autoRemoveLoop)
        else
            if removeConfig.loop then task.cancel(removeConfig.loop) removeConfig.loop = nil end
        end
    end,
})

local bcTab = Window:CreateTab("Brainrots & Cash", 96942169425973)

bcTab:CreateSection("Auto Collect All")
bcTab:CreateToggle({
    Name = "Auto Collect All Slots", CurrentValue = false,
    Flag = "AutoCollectAllSlots",
    Callback = function(v)
        collectConfig.enabled = v
        print("[AutoCollectAll] Toggled", v)
        if v then
            if collectConfig.loop then task.cancel(collectConfig.loop) end
            collectConfig.loop = task.spawn(autoCollectLoop)
        else
            if collectConfig.loop then task.cancel(collectConfig.loop) collectConfig.loop = nil end
        end
    end,
})
bcTab:CreateSlider({
    Name = "Collect Interval", Range = {0.1, 10}, Increment = 0.1, Suffix = "s",
    CurrentValue = 1,
    Flag = "CollectInterval",
    Callback = function(v) collectConfig.delay = v print("[CollectInterval] Set to", v) end,
})

bcTab:CreateSection("Collect by Slot")
bcTab:CreateButton({
    Name = "Refresh Slots",
    Flag = "RefreshSlots",
    Callback = refreshSlotMaps,
})
slotCollect.dropdown = bcTab:CreateDropdown({
    Name = "Select Slots", Options = {"Press Refresh first"}, Multi = true,
    Flag = "SlotCollectSelected",
    Callback = function(sel)
        local nums = {}
        for _, lbl in ipairs(sel) do
            if slotCollect.map[lbl] then table.insert(nums, slotCollect.map[lbl]) end
        end
        slotCollect.selected = nums
        print("[SlotCollectSelected] Selected", #nums, "slots")
    end,
})
bcTab:CreateToggle({
    Name = "Auto Collect Selected Slots", CurrentValue = false,
    Flag = "AutoCollectSelectedSlots",
    Callback = function(v)
        slotCollect.auto = v
        print("[AutoCollectSelected] Toggled", v)
        if v then
            if slotCollect.loop then task.cancel(slotCollect.loop) end
            slotCollect.loop = task.spawn(autoSlotCollectLoop)
        else
            if slotCollect.loop then task.cancel(slotCollect.loop) slotCollect.loop = nil end
        end
    end,
})
bcTab:CreateSlider({
    Name = "Slot Collect Interval", Range = {0.1, 10}, Increment = 0.1, Suffix = "s",
    CurrentValue = 1,
    Flag = "SlotCollectInterval",
    Callback = function(v) slotCollect.delay = v print("[SlotCollectInterval] Set to", v) end,
})

bcTab:CreateSection("Collect by Rarity")
bcTab:CreateDropdown({
    Name = "Select Rarities", Options = rarities_with_all, Multi = true,
    Flag = "CollectRarities",
    Callback = function(sel) rarityCollect.rarities = sel print("[CollectRarities] Selected", #sel, "rarities") end,
})
bcTab:CreateToggle({
    Name = "Auto Collect by Rarity", CurrentValue = false,
    Flag = "AutoCollectByRarity",
    Callback = function(v)
        rarityCollect.auto = v
        print("[AutoCollectByRarity] Toggled", v)
        if v then
            if rarityCollect.loop then task.cancel(rarityCollect.loop) end
            rarityCollect.loop = task.spawn(autoRarityCollectLoop)
        else
            if rarityCollect.loop then task.cancel(rarityCollect.loop) rarityCollect.loop = nil end
        end
    end,
})
bcTab:CreateSlider({
    Name = "Rarity Collect Interval", Range = {0.1, 10}, Increment = 0.1, Suffix = "s",
    CurrentValue = 1,
    Flag = "RarityCollectInterval",
    Callback = function(v) rarityCollect.delay = v print("[RarityCollectInterval] Set to", v) end,
})

bcTab:CreateSection("Quick Sell")
bcTab:CreateButton({
    Name = "Sell Equipped",
    Flag = "SellEquipped",
    Callback = function()
        local char = lp.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:UnequipTools() task.wait(0.2)
            FireRemote("rev_S_Interact", 1)
            print("[SellEquipped] Executed")
        end
    end,
})
bcTab:CreateButton({
    Name = "Sell All Brainrots",
    Flag = "SellAllBrainrots",
    Callback = function()
        InvokeRemote("ref_B_SellAll")
        print("[SellAll] Executed")
    end,
})

bcTab:CreateSection("Sell by Rarity")
bcTab:CreateDropdown({
    Name = "Select Rarities", Options = rarities_with_all, Multi = true,
    Flag = "SellRarities",
    Callback = function(sel) sellRarity.rarities = sel print("[SellRarities] Selected", #sel, "rarities") end,
})
bcTab:CreateToggle({
    Name = "Auto Sell by Rarity", CurrentValue = false,
    Flag = "AutoSellByRarity",
    Callback = function(v)
        sellRarity.auto = v
        print("[AutoSellByRarity] Toggled", v)
        if v then
            if sellRarity.loop then task.cancel(sellRarity.loop) end
            sellRarity.loop = task.spawn(sellByRarityLoop)
        else
            if sellRarity.loop then task.cancel(sellRarity.loop) sellRarity.loop = nil end
        end
    end,
})
bcTab:CreateSlider({
    Name = "Sell Interval", Range = {1, 60}, Increment = 1, Suffix = "s",
    CurrentValue = 5,
    Flag = "SellRarityInterval",
    Callback = function(v) sellRarity.delay = v print("[SellRarityInterval] Set to", v) end,
})

bcTab:CreateSection("Sell Specific")
bcTab:CreateDropdown({
    Name = "Select Brainrots", Options = brainrots_with_all, Multi = true,
    Flag = "SellSpecificBrainrots",
    Callback = function(sel) sellSpecific.targets = sel print("[SellSpecific] Selected", #sel, "brainrots") end,
})
bcTab:CreateToggle({
    Name = "Auto Sell Specific", CurrentValue = false,
    Flag = "AutoSellSpecific",
    Callback = function(v)
        sellSpecific.auto = v
        print("[AutoSellSpecific] Toggled", v)
        if v then
            if sellSpecific.loop then task.cancel(sellSpecific.loop) end
            sellSpecific.loop = task.spawn(sellSpecificLoop)
        else
            if sellSpecific.loop then task.cancel(sellSpecific.loop) sellSpecific.loop = nil end
        end
    end,
})
bcTab:CreateSlider({
    Name = "Sell Interval", Range = {1, 60}, Increment = 1, Suffix = "s",
    CurrentValue = 5,
    Flag = "SellSpecificInterval",
    Callback = function(v) sellSpecific.delay = v print("[SellSpecificInterval] Set to", v) end,
})

bcTab:CreateSection("Sell by Mutation")
bcTab:CreateDropdown({
    Name = "Select Mutations", Options = mutations_with_all, Multi = true,
    Flag = "SellMutations",
    Callback = function(sel) sellMutation.mutations = sel print("[SellMutations] Selected", #sel, "mutations") end,
})
bcTab:CreateToggle({
    Name = "Auto Sell by Mutation", CurrentValue = false,
    Flag = "AutoSellByMutation",
    Callback = function(v)
        sellMutation.auto = v
        print("[AutoSellByMutation] Toggled", v)
        if v then
            if sellMutation.loop then task.cancel(sellMutation.loop) end
            sellMutation.loop = task.spawn(sellByMutationLoop)
        else
            if sellMutation.loop then task.cancel(sellMutation.loop) sellMutation.loop = nil end
        end
    end,
})
bcTab:CreateSlider({
    Name = "Sell Interval", Range = {1, 60}, Increment = 1, Suffix = "s",
    CurrentValue = 5,
    Flag = "SellMutationInterval",
    Callback = function(v) sellMutation.delay = v print("[SellMutationInterval] Set to", v) end,
})

local miscTab = Window:CreateTab("Misc", 135748283315148)

miscTab:CreateSection("Shop - Speed")
miscTab:CreateSlider({
    Name = "Amount to Buy", Range = {1, 50}, Increment = 1, Suffix = "x",
    CurrentValue = 1,
    Flag = "SpeedAmount",
    Callback = function(v) shopSpeed.amount = v print("[SpeedAmount] Set to", v) end,
})
miscTab:CreateToggle({
    Name = "Auto Buy Speed", CurrentValue = false,
    Flag = "AutoBuySpeed",
    Callback = function(v)
        shopSpeed.auto = v
        print("[AutoBuySpeed] Toggled", v)
        if v then
            if shopSpeed.loop then task.cancel(shopSpeed.loop) end
            shopSpeed.loop = task.spawn(function()
                while shopSpeed.auto do
                    FireRemote("rev_SPEED_UPGRADE", shopSpeed.amount)
                    task.wait(1)
                end
            end)
        else
            if shopSpeed.loop then task.cancel(shopSpeed.loop) shopSpeed.loop = nil end
        end
    end,
})

miscTab:CreateSection("Shop - Weights")
miscTab:CreateDropdown({
    Name = "Select Weights", Options = weights_with_all, Multi = true,
    Flag = "AutoBuyWeightsList",
    Callback = function(sel) shopWeights.selected = sel print("[AutoBuyWeightsList] Selected", #sel, "weights") end,
})
miscTab:CreateToggle({
    Name = "Auto Buy Weights", CurrentValue = false,
    Flag = "AutoBuyWeights",
    Callback = function(v)
        shopWeights.auto = v
        print("[AutoBuyWeights] Toggled", v)
        if v then
            if shopWeights.loop then task.cancel(shopWeights.loop) end
            shopWeights.loop = task.spawn(function()
                while shopWeights.auto do
                    for _, w in ipairs(expandAll(shopWeights.selected, weightsList)) do
                        FireRemote("rev_Shop_Buy", "WeightShop", w)
                        task.wait(0.1)
                    end
                    task.wait(1)
                end
            end)
        else
            if shopWeights.loop then task.cancel(shopWeights.loop) shopWeights.loop = nil end
        end
    end,
})

miscTab:CreateSection("Shop - Slots & Rebirth")
miscTab:CreateToggle({
    Name = "Auto Buy Slots", CurrentValue = false,
    Flag = "AutoBuySlots",
    Callback = function(v)
        shopSlots.auto = v
        print("[AutoBuySlots] Toggled", v)
        if v then
            if shopSlots.loop then task.cancel(shopSlots.loop) end
            shopSlots.loop = task.spawn(function()
                while shopSlots.auto do
                    FireRemote("rev_bs_upgrade")
                    task.wait(1)
                end
            end)
        else
            if shopSlots.loop then task.cancel(shopSlots.loop) shopSlots.loop = nil end
        end
    end,
})
miscTab:CreateToggle({
    Name = "Auto Rebirth", CurrentValue = false,
    Flag = "AutoRebirth",
    Callback = function(v)
        shopRebirth.auto = v
        print("[AutoRebirth] Toggled", v)
        if v then
            if shopRebirth.loop then task.cancel(shopRebirth.loop) end
            shopRebirth.loop = task.spawn(function()
                while shopRebirth.auto do
                    FireRemote("rev_RebirthRequest")
                    task.wait(1)
                end
            end)
        else
            if shopRebirth.loop then task.cancel(shopRebirth.loop) shopRebirth.loop = nil end
        end
    end,
})

miscTab:CreateSection("Upgrades")
miscTab:CreateButton({
    Name = "Refresh Slots",
    Flag = "UpgradeRefreshSlots",
    Callback = refreshSlotMaps,
})
upgradeSlots.dropdown = miscTab:CreateDropdown({
    Name = "Select Slots", Options = {"Press Refresh first"}, Multi = true,
    Flag = "UpgradeSlotsSelected",
    Callback = function(sel)
        local nums = {}
        for _, lbl in ipairs(sel) do
            if upgradeSlots.map[lbl] then table.insert(nums, upgradeSlots.map[lbl]) end
        end
        upgradeSlots.selected = nums
        print("[UpgradeSlotsSelected] Selected", #nums, "slots")
    end,
})
miscTab:CreateToggle({
    Name = "Auto Upgrade Selected Slots", CurrentValue = false,
    Flag = "AutoUpgradeSelectedSlots",
    Callback = function(v)
        upgradeSlots.auto = v
        print("[AutoUpgradeSelected] Toggled", v)
        if v then
            if upgradeSlots.loop then task.cancel(upgradeSlots.loop) end
            upgradeSlots.loop = task.spawn(function()
                while upgradeSlots.auto do
                    upgradeSelectedSlots()
                    task.wait(0.15)
                end
            end)
        else
            if upgradeSlots.loop then task.cancel(upgradeSlots.loop) upgradeSlots.loop = nil end
        end
    end,
})
miscTab:CreateDropdown({
    Name = "Upgrade by Rarity", Options = rarities_with_all, Multi = true,
    Flag = "UpgradeRarities",
    Callback = function(sel) upgradeRarity.rarities = sel print("[UpgradeRarities] Selected", #sel, "rarities") end,
})
miscTab:CreateToggle({
    Name = "Auto Upgrade by Rarity", CurrentValue = false,
    Flag = "AutoUpgradeByRarity",
    Callback = function(v)
        upgradeRarity.auto = v
        print("[AutoUpgradeByRarity] Toggled", v)
        if v then
            if upgradeRarity.loop then task.cancel(upgradeRarity.loop) end
            upgradeRarity.loop = task.spawn(upgradeRarityLoop)
        else
            if upgradeRarity.loop then task.cancel(upgradeRarity.loop) upgradeRarity.loop = nil end
        end
    end,
})

local webhookTab = Window:CreateTab("Webhook", 122447804258070)

webhookTab:CreateSection("Setup")
webhookTab:CreateInput({
    Name = "Webhook URL",
    CurrentValue = "",
    PlaceholderText = "https://discord.com/api/webhooks/...",
    Flag = "WebhookURL",
    Callback = function(text) WH.url = text print("[WebhookURL] Set") end,
})
webhookTab:CreateInput({
    Name = "Ping User ID",
    CurrentValue = "",
    PlaceholderText = "e.g. 123456789012345678",
    Flag = "PingUserID",
    Callback = function(text) WH.pingUID = text or "" print("[PingUserID] Set") end,
})
webhookTab:CreateInput({
    Name = "Min Earn",
    CurrentValue = "",
    PlaceholderText = "1m, 500k, 1b, blank = off",
    Flag = "MinEarn",
    Callback = function(text)
        if text == nil or text == "" then
            WH.minEarn = nil
            print("[MinEarn] Disabled")
        else
            local val = parseShortNumber(text)
            WH.minEarn = val
            if not val then
                Rayfield:Notify({Title = "Webhook", Content = "Invalid number format", Duration = 3})
                print("[MinEarn] Invalid format:", text)
            else
                print("[MinEarn] Set to", val)
            end
        end
    end,
})
webhookTab:CreateToggle({
    Name = "Enable Discord Webhook",
    CurrentValue = false,
    Flag = "EnableDiscordWebhook",
    Callback = function(v) WH.enabled = v print("[WebhookEnabled] Set to", v) end,
})
webhookTab:CreateButton({
    Name = "Send Test Ping",
    Flag = "SendTestPing",
    Callback = sendTestWebhook,
})

webhookTab:CreateSection("Filters")
webhookTab:CreateDropdown({
    Name = "Send Mode",
    Options = {"All", "MutatedOnly", "RarityOnly"},
    CurrentOption = "All",
    Flag = "SendMode",
    Callback = function(opt) WH.mode = opt print("[SendMode] Set to", opt) end,
})
webhookTab:CreateDropdown({
    Name = "Rarity Filter",
    Options = rarities_with_all,
    Multi = true,
    Flag = "RarityFilter",
    Callback = function(sel) WH.rarities = sel print("[RarityFilter] Selected", #sel, "rarities") end,
})
webhookTab:CreateDropdown({
    Name = "Mutation Filter",
    Options = mutations_with_all,
    Multi = true,
    Flag = "MutationFilter",
    Callback = function(sel) WH.mutations = sel print("[MutationFilter] Selected", #sel, "mutations") end,
})
webhookTab:CreateDropdown({
    Name = "Specific Brainrot Filter",
    Options = brainrots_with_all,
    Multi = true,
    Flag = "SpecificBrainrotFilter",
    Callback = function(sel) WH.specifics = sel print("[SpecificFilter] Selected", #sel, "brainrots") end,
})

local eventTab = Window:CreateTab("🌋 Event", 94483582151513)

eventTab:CreateSection("🛒 Volcano Shop")

eventTab:CreateDropdown({
    Name = "📦 Select Items to Buy",
    Options = volcanoShopItemsList,
    Multi = true,
    Flag = "VolcanoShopItems",
    Callback = function(sel)
        volcanoShop.selected = sel
    end,
})

eventTab:CreateButton({
    Name = "⚡ Buy Selected Once",
    Flag = "VolcanoBuyOnce",
    Callback = function()
        if #volcanoShop.selected == 0 then
            Rayfield:Notify({Title = "🌋 Volcano Shop", Content = "No items selected!", Duration = 3})
            return
        end
        for _, item in ipairs(volcanoShop.selected) do
            FireRemote("rev_VolcanicShop_Buy", item)
            task.wait(0.2)
        end
        Rayfield:Notify({Title = "🌋 Volcano Shop", Content = "Bought " .. #volcanoShop.selected .. " item(s)!", Duration = 3})
    end,
})

eventTab:CreateSlider({
    Name = "⏱️ Buy Interval",
    Range = {1, 60},
    Increment = 1,
    Suffix = "s",
    CurrentValue = 5,
    Flag = "VolcanoShopDelay",
    Callback = function(v)
        volcanoShop.delay = v
    end,
})

eventTab:CreateToggle({
    Name = "🔁 Auto Buy Selected Items",
    CurrentValue = false,
    Flag = "AutoVolcanoShop",
    Callback = function(v)
        volcanoShop.auto = v
        if v then
            if volcanoShop.loop then task.cancel(volcanoShop.loop) end
            volcanoShop.loop = task.spawn(function()
                while volcanoShop.auto do
                    for _, item in ipairs(volcanoShop.selected) do
                        FireRemote("rev_VolcanicShop_Buy", item)
                        task.wait(0.2)
                    end
                    task.wait(volcanoShop.delay)
                end
            end)
        else
            if volcanoShop.loop then task.cancel(volcanoShop.loop) volcanoShop.loop = nil end
        end
    end,
})

eventTab:CreateSection("⬆️ Volcano Upgrades")

local function updateUpgradeLevelMax()
    local maxLvl = volcanoUpgradeLevels[volcanoUpgrade.upgradeType] or 1
    if upgradeLevelSliderRef then
        upgradeLevelSliderRef:SetRange(1, maxLvl)
    end
    if volcanoUpgrade.level > maxLvl then
        volcanoUpgrade.level = maxLvl
        if upgradeLevelSliderRef then
            upgradeLevelSliderRef:SetValue(maxLvl)
        end
    end
end

eventTab:CreateDropdown({
    Name = "🔧 Upgrade Type",
    Options = volcanoUpgradeTypesList,
    CurrentOption = volcanoUpgradeTypesList[1] or "OreMultipliers",
    Flag = "VolcanoUpgradeType",
    Callback = function(sel)
        volcanoUpgrade.upgradeType = sel
        updateUpgradeLevelMax()
    end,
})

local upgradeLevelSliderRef = eventTab:CreateSlider({
    Name = "📈 Upgrade Level",
    Range = {1, 4},
    Increment = 1,
    Suffix = "",
    CurrentValue = 1,
    Flag = "VolcanoUpgradeLevel",
    Callback = function(v)
        volcanoUpgrade.level = v
    end,
})
updateUpgradeLevelMax()

eventTab:CreateButton({
    Name = "💥 Buy Upgrade Once",
    Flag = "VolcanoBuyUpgradeOnce",
    Callback = function()
        FireRemote("rev_volcanoUpgrade", volcanoUpgrade.upgradeType, volcanoUpgrade.level)
        Rayfield:Notify({Title = "⬆️ Upgraded", Content = volcanoUpgrade.upgradeType .. " Lv" .. volcanoUpgrade.level, Duration = 3})
    end,
})

eventTab:CreateButton({
    Name = "🚀 Max Selected Upgrade Type",
    Flag = "VolcanoMaxUpgrade",
    Callback = function()
        local maxLevel = volcanoUpgradeLevels[volcanoUpgrade.upgradeType] or 1
        for i = 1, maxLevel do
            FireRemote("rev_volcanoUpgrade", volcanoUpgrade.upgradeType, i)
            task.wait(0.2)
        end
        Rayfield:Notify({Title = "🚀 Maxed!", Content = volcanoUpgrade.upgradeType .. " fully upgraded!", Duration = 3})
    end,
})

eventTab:CreateButton({
    Name = "🌟 Max ALL Upgrades",
    Flag = "VolcanoMaxAllUpgrades",
    Callback = function()
        for _, upgradeType in ipairs(volcanoUpgradeTypesList) do
            local maxLevel = volcanoUpgradeLevels[upgradeType] or 1
            for i = 1, maxLevel do
                FireRemote("rev_volcanoUpgrade", upgradeType, i)
                task.wait(0.2)
            end
        end
        Rayfield:Notify({Title = "🌋 ALL MAXED!", Content = "Every volcano upgrade purchased!", Duration = 4})
    end,
})

eventTab:CreateToggle({
    Name = "🔄 Auto Upgrade (Selected Type & Level)",
    CurrentValue = false,
    Flag = "AutoVolcanoUpgrade",
    Callback = function(v)
        volcanoUpgrade.auto = v
        if v then
            if volcanoUpgrade.loop then task.cancel(volcanoUpgrade.loop) end
            volcanoUpgrade.loop = task.spawn(function()
                while volcanoUpgrade.auto do
                    FireRemote("rev_volcanoUpgrade", volcanoUpgrade.upgradeType, volcanoUpgrade.level)
                    task.wait(1)
                end
            end)
        else
            if volcanoUpgrade.loop then task.cancel(volcanoUpgrade.loop) volcanoUpgrade.loop = nil end
        end
    end,
})

refreshSlotMaps()
Rayfield:Notify({Title = "Cactus Hub", Content = "Loaded! Join discord.gg/qMWFBWdcf", Duration = 4})
print("[Cactus Hub] Script fully loaded")
