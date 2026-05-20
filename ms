
repeat task.wait() until game:GetService("Players").LocalPlayer.PlayerGui:WaitForChild("__MAINHUD__")
repeat task.wait() until game:IsLoaded()

local cfg = getgenv().slime_rng_cfg or {}

local RS = game:GetService("ReplicatedStorage")
local plrs = game:GetService("Players")
local localPlr = plrs.LocalPlayer
local http = game:GetService("HttpService")

local pkgs = RS:WaitForChild("Packages")
local idx = pkgs:WaitForChild("_Index")
local net = idx:WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker")
local rmt = net:WaitForChild("_remotes")

local dataCli = require(pkgs.DataService).client
dataCli:waitForData()

local rollRmt = rmt:WaitForChild("RollService"):WaitForChild("RemoteFunction")
local codeRmt = rmt:WaitForChild("CodeService"):WaitForChild("RemoteFunction")
local invRmt = rmt:WaitForChild("InventoryService"):WaitForChild("RemoteFunction")
local rebRmt = rmt:WaitForChild("RebirthService"):WaitForChild("RemoteFunction")
local zoneRmt = rmt:WaitForChild("ZonesService"):WaitForChild("RemoteFunction")
local upgRmt = rmt:WaitForChild("UpgradeService"):WaitForChild("RemoteFunction")
local boostRmt = rmt:WaitForChild("BoostService"):WaitForChild("RemoteFunction")
local offRmt = rmt:WaitForChild("OfflineEarningsService"):WaitForChild("RemoteFunction")
local idxRmt = rmt:WaitForChild("IndexService"):WaitForChild("RemoteFunction")

local src = RS:WaitForChild("Source", 30)
if not src then
    warn("Main module missing")
    return
end

local itms = src:WaitForChild("Game"):WaitForChild("Items")
local rollFeat = src:WaitForChild("Features"):WaitForChild("Roll")
local mutFolder = src:WaitForChild("Features"):WaitForChild("Mutations")

local rollSlice = require(rollFeat:WaitForChild("RollSlice"))
local slimeData = require(itms:WaitForChild("Slimes"))
local rarityTiers = require(itms:WaitForChild("RarityTiers"))
local mutations = require(mutFolder:WaitForChild("Mutations"))
local zones = require(RS.Source.Game.Items.Zones)
local upgTree = require(RS.Source.Features.Upgrades.UpgradeTree)
local idxRewards = require(RS.Source.Features.Index.IndexRewards)

local expected = {
    "OFFLINE_EARNINGS", "FAST_ROLL", "REDEEM_CODES", "CODES",
    "EQUIP_BEST_SLIMES", "AUTO_REBIRTH", "REQUIRED_ZONE_TO_REBIRTH",
    "UNLOCK_AFFORDABLE_ZONES", "AUTOFARM_BEST_ZONE", "AUTO_BUY_UPGRADES",
    "USE_POTIONS", "POTIONS_TO_USE", "USE_DICES", "DICES_TO_USE",
    "AUTO_CLAIM_INDEX_REWARDS", "AUTO_COLLECT_LOOT", "OPTIMIZATION",
    "WEBHOOK_URL", "MINIMUM_LUCK_SENT"
}

local fnd = 0
for _, k in ipairs(expected) do
    if cfg[k] ~= nil then
        fnd = fnd + 1
    else
        warn("Cfg missing: "..k)
    end
end

print("Configs: "..fnd.."/"..#expected)

local function f1(n)
    if type(n) ~= "number" then return tostring(n) end
    local a = math.abs(n)
    local s = ""
    local d = 1
    if a >= 1e18 then
        s = "Qn"; d = 1e18
    elseif a >= 1e15 then
        s = "Qd"; d = 1e15
    elseif a >= 1e12 then
        s = "T"; d = 1e12
    elseif a >= 1e9 then
        s = "B"; d = 1e9
    elseif a >= 1e6 then
        s = "M"; d = 1e6
    elseif a >= 1e3 then
        s = "K"; d = 1e3
    end
    if s ~= "" then
        local fm = n / d
        if math.abs(fm - math.floor(fm)) < 0.01 then
            return string.format("%d%s", math.floor(fm), s)
        else
            return string.format("%.1f%s", fm, s):gsub("%.0f", "")
        end
    end
    return tostring(math.floor(n))
end

local function f2(rmt, ...)
    local ok, res = pcall(rmt.InvokeServer, rmt, ...)
    return ok, res
end

local function f3(id)
    if not id then return nil end
    local url = "https://thumbnails.roblox.com/v1/assets?assetIds="..id.."&size=420x420&format=Png&isCircular=false"
    local suc, res = pcall(request, {Url = url, Method = "GET"})
    if suc and res and res.Success then
        local data = http:JSONDecode(res.Body)
        if data and data.data and data.data[1] and data.data[1].imageUrl then
            return data.data[1].imageUrl
        end
    end
    return nil
end

if cfg.OPTIMIZATION then
    pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))()
    end)
end

if cfg.OFFLINE_EARNINGS then
    pcall(offRmt.InvokeServer, offRmt, "requestClaim")
end

if cfg.EQUIP_BEST_SLIMES then
    task.spawn(function()
        local d = 30
        while true do
            pcall(invRmt.InvokeServer, invRmt, "requestEquipBest")
            task.wait(d)
            d = math.min(d * 2, 600)
        end
    end)
end

if cfg.REDEEM_CODES then
    task.spawn(function()
        local codes = dataCli._data._data._codes or {}
        for _, cd in ipairs(cfg.CODES) do
            if not codes[cd] then
                pcall(codeRmt.InvokeServer, codeRmt, "redeem", cd)
                task.wait(0.5)
            end
        end
    end)
end

if cfg.AUTO_REBIRTH then
    task.spawn(function()
        while true do
            local rbs = dataCli:get("rebirths") or 0
            local gp = dataCli:get("goop") or 0
            local fz = dataCli:get("furthestZone") or 0
            local cost = (2 ^ rbs) * 500
            if fz >= cfg.REQUIRED_ZONE_TO_REBIRTH and gp >= cost then
                pcall(rebRmt.InvokeServer, rebRmt, "requestRebirth")
            end
            task.wait(10)
        end
    end)
end

local curZone = dataCli:get("zone") or 1

if cfg.UNLOCK_AFFORDABLE_ZONES then
    task.spawn(function()
        while true do
            pcall(zoneRmt.InvokeServer, zoneRmt, "requestPurchaseZone")
            task.wait(5)
        end
    end)
end

if cfg.AUTOFARM_BEST_ZONE then
    task.spawn(function()
        local MAX = 25
        while true do
            for z = MAX, 1, -1 do
                local suc = pcall(zoneRmt.InvokeServer, zoneRmt, "requestTeleportZone", z)
                if suc then
                    task.wait(1)
                    local nz = dataCli:get("zone") or 1
                    if nz == z then
                        curZone = z
                        break
                    end
                end
            end
            task.wait(10)
        end
    end)
end

if cfg.AUTO_BUY_UPGRADES then
    task.spawn(function()
        local function f4(t, ids)
            if type(t) ~= "table" then return end
            for id, d in pairs(t) do
                if type(d) == "table" and d.cost then
                    table.insert(ids, id)
                end
            end
        end
        local upgs = {}
        f4(upgTree.main, upgs)
        if upgTree.main.lootTree and upgTree.main.lootTree.subTree then
            f4(upgTree.main.lootTree.subTree, upgs)
        end
        if upgTree.main.playerTree and upgTree.main.playerTree.subTree then
            f4(upgTree.main.playerTree.subTree, upgs)
        end
        local function f5(id)
            local function f6(t)
                if type(t) ~= "table" then return nil end
                for k, d in pairs(t) do
                    if k == id and type(d) == "table" then return d.cost end
                end
            end
            return f6(upgTree.main)
                or f6(upgTree.main.lootTree and upgTree.main.lootTree.subTree)
                or f6(upgTree.main.playerTree and upgTree.main.playerTree.subTree)
        end
        while task.wait(0.5) do
            local owned = dataCli:get("upgrades") or {}
            local coins = dataCli:get("coins") or 0
            local goop = dataCli:get("goop") or 0
            local rc = dataCli:get("rollCurrency") or 0
            for _, id in ipairs(upgs) do
                if not owned[id] then
                    local cost = f5(id)
                    if cost then
                        local amt = cost.amount or 0
                        local cur = cost.currency
                        local aff = (cur == "coins" and coins >= amt)
                            or (cur == "goop" and goop >= amt)
                            or (cur == "rollCurrency" and rc >= amt)
                        if aff then
                            local ok = pcall(upgRmt.InvokeServer, upgRmt, "requestUnlock", id)
                            if ok then task.wait(0.2) end
                        end
                    end
                end
            end
        end
    end)
end

if cfg.USE_POTIONS or cfg.USE_DICES then
    task.spawn(function()
        while task.wait(1) do
            local boosts = dataCli:get("boosts") or {}
            local items = dataCli:get("items") or {}
            if cfg.USE_POTIONS then
                for _, p in ipairs(cfg.POTIONS_TO_USE) do
                    local d = boosts[p]
                    if d and (d.amount or 0) > 0 then
                        pcall(boostRmt.InvokeServer, boostRmt, "requestUseBoost", p)
                    end
                end
            end
            if cfg.USE_DICES then
                for _, d in ipairs(cfg.DICES_TO_USE) do
                    if (items[d] or 0) > 0 then
                        pcall(invRmt.InvokeServer, invRmt, "requestUseItem", d)
                    end
                end
            end
        end
    end)
end

if cfg.AUTO_CLAIM_INDEX_REWARDS then
    task.spawn(function()
        local function f7()
            local d = dataCli:get("index")
            if not d or not d.categories then return end
            for cat, rw in pairs(idxRewards) do
                local cd = d.categories[cat]
                if cd then
                    local unlocked = cd.unlocked or {}
                    local cnt = 0
                    for _, v in pairs(unlocked) do
                        if v == true then cnt = cnt + 1 end
                    end
                    local claimed = cd.claimedRewards or {}
                    for _, r in ipairs(rw) do
                        if cnt >= r.req and not claimed[r.key] then
                            pcall(idxRmt.InvokeServer, idxRmt, "requestClaimReward", cat)
                            task.wait(0.5)
                        end
                    end
                end
            end
        end
        while true do
            f7()
            task.wait(60)
        end
    end)
end

if cfg.AUTO_COLLECT_LOOT then
    task.spawn(function()
        local lootRmt = RS:WaitForChild("Packages")
            :WaitForChild("_Index")
            :WaitForChild("leifstout_networker@0.3.1")
            :WaitForChild("networker")
            :WaitForChild("_remotes")
            :WaitForChild("LootService")
            :WaitForChild("RemoteFunction")
        while true do
            task.wait(30)
            local lootFolder = workspace:FindFirstChild("Loot")
            if not lootFolder then continue end
            local loots = lootFolder:GetChildren()
            for _, l in ipairs(loots) do
                pcall(lootRmt.InvokeServer, lootRmt, "requestCollect", l.Name)
            end
        end
    end)
end

if cfg.FAST_ROLL then
    task.spawn(function()
        while true do
            pcall(rollRmt.InvokeServer, rollRmt, "requestRoll")
            task.wait()
        end
    end)
end

if cfg.WEBHOOK_URL and #cfg.WEBHOOK_URL > 0 then
    task.spawn(function()
        local web = cfg.WEBHOOK_URL[1]
        local minLuck = 0
        if cfg.MINIMUM_LUCK_SENT then
            local ml = cfg.MINIMUM_LUCK_SENT
            if type(ml) == "string" then
                local mult = 1
                if string.sub(ml, -1) == "B" then
                    mult = 1e9
                    ml = string.sub(ml, 1, -2)
                elseif string.sub(ml, -1) == "M" then
                    mult = 1e6
                    ml = string.sub(ml, 1, -2)
                elseif string.sub(ml, -1) == "K" then
                    mult = 1e3
                    ml = string.sub(ml, 1, -2)
                end
                local num = tonumber(ml)
                if num then
                    minLuck = num * mult
                end
            elseif type(ml) == "number" then
                minLuck = ml
            end
        end
        local sent = {}
        local function f8(odds)
            if not odds or odds <= 0 then return "Unknown" end
            local ok, tier = pcall(rarityTiers.getTier, odds)
            return (ok and tier and tier.name) or "Unknown"
        end
        local function f9(res)
            if type(res) ~= "table" then return nil end
            for _, e in ipairs(res) do
                if type(e) == "table" and e.id then
                    return e
                end
            end
            return nil
        end
        local function f10(res)
            if type(res) ~= "table" then return "nil" end
            local cnt = #res
            if cnt == 0 then return "empty" end
            local parts = {}
            for i, r in ipairs(res) do
                local it = f9(r)
                parts[i] = it and tostring(it.id) or tostring(i)
            end
            return cnt.."|"..table.concat(parts, ",")
        end
        local function f11(n)
            local s = tostring(n)
            local last = n % 10
            local tens = n % 100
            if tens >= 11 and tens <= 13 then return s.."th" end
            if last == 1 then return s.."st" end
            if last == 2 then return s.."nd" end
            if last == 3 then return s.."rd" end
            return s.."th"
        end
        local function f12(m)
            if not m then return 64 end
            if m.huge then return 128
            elseif m.big then return 96 end
            return 64
        end
        local function f13(m)
            if not m then return nil end
            if m.inverted then return 0x9b59b6
            elseif m.huge then return 0xf1c40f
            elseif m.big then return 0xe67e22
            elseif m.shiny then return 0xf39c12 end
            return nil
        end
        local function f14(pName, dName, rarity, chance, stats, muts, mutList, img, rolls, coins, kills)
            local finalImg = nil
            local sz = f12(muts)
            if img and img ~= "N/A" then
                local aid = string.match(img, "rbxassetid://(%d+)")
                if aid then
                    finalImg = f3(aid)
                end
            end
            local hidden = "||"..pName.."||"
            local desc = string.format("**%s** rolled **%s**!\n\n🎲 **Total Rolls:** %s", hidden, dName, f11(rolls))
            local fields = {
                {name = "Rarity", value = rarity, inline = true},
                {name = "Chance", value = chance, inline = true}
            }
            if stats and stats ~= "" then
                table.insert(fields, {name = "Stats", value = stats, inline = true})
            end
            if mutList and #mutList > 0 then
                table.insert(fields, {name = "Mutations", value = table.concat(mutList, ", "), inline = true})
            end
            table.insert(fields, {name = "🪙 Coins", value = f1(coins), inline = true})
            table.insert(fields, {name = "⚔️ Kills", value = f1(kills), inline = true})
            local payload = {
                username = "makik",
                embeds = {{
                    title = "New Slime Rolled!",
                    description = desc,
                    thumbnail = finalImg and {url = finalImg, width = sz, height = sz} or nil,
                    fields = fields,
                    color = f13(muts)
                }}
            }
            pcall(function()
                request({
                    Url = web,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = http:JSONEncode(payload)
                })
                print("Webhook sent: "..dName)
            end)
        end
        local lastFp = nil
        while true do
            task.wait(0.1)
            local ok, res = pcall(rollSlice.rollResults)
            if not ok then continue end
            local fp = f10(res)
            if fp ~= lastFp then
                lastFp = fp
                if type(res) == "table" and #res > 0 then
                    local stats = dataCli:get("stats") or {}
                    local rolls = stats.rolls or 0
                    local kills = stats.kills or 0
                    local coins = dataCli:get("coins") or 0
                    for _, r in ipairs(res) do
                        local it = f9(r)
                        if not it then continue end
                        local id = tostring(it.id or "unknown")
                        local okSlime, slime = pcall(slimeData.getSlime, id)
                        slime = okSlime and slime or nil
                        local muts = type(it.mutations) == "table" and next(it.mutations) ~= nil and it.mutations or nil
                        local inv = muts and it.mutations.inverted == true
                        local img = inv and (slime and slime.invertedIcon or "N/A") or (slime and slime.image or "N/A")
                        local name = slime and slime.name or id
                        local baseOdds = slime and slime.odds or nil
                        local baseDmg = slime and slime.damage or 0
                        local baseHp = slime and slime.health or 0
                        local rarity = baseOdds and f8(baseOdds) or "Unknown"
                        local mult = muts and mutations.getVisualOddsMultiplier(muts) or 1
                        local statBonus = muts and mutations.getStatBonus(muts, "damage") or 1
                        local finalOdds = baseOdds and (baseOdds / mult) or nil
                        local finalDmg = baseDmg * statBonus
                        local finalHp = baseHp * statBonus
                        local chanceText = finalOdds and string.format("1 in %s", f1(math.floor(1 / finalOdds + 0.5))) or "N/A"
                        local chanceNum = finalOdds and (1 / finalOdds) or nil
                        local dName = muts and mutations.getDisplayName(name, muts) or name
                        local mutList = muts and mutations.getIds(muts) or {}
                        if minLuck > 0 and chanceNum and chanceNum < minLuck then
                            continue
                        end
                        local statsText = ""
                        if finalDmg > 0 and finalHp > 0 then
                            statsText = string.format("⚔️ %s  ❤️ %s", f1(finalDmg), f1(finalHp))
                        elseif finalDmg > 0 then
                            statsText = string.format("⚔️ %s", f1(finalDmg))
                        elseif finalHp > 0 then
                            statsText = string.format("❤️ %s", f1(finalHp))
                        end
                        local pName = localPlr and localPlr.Name or "Someone"
                        local key = pName.."_"..dName.."_"..tostring(os.time())
                        if not sent[key] then
                            sent[key] = os.time()
                            task.spawn(function()
                                f14(pName, dName, rarity, chanceText, statsText, muts, mutList, img, rolls, coins, kills)
                            end)
                        end
                    end
                end
            end
        end
    end)
end
