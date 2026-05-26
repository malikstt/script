task.spawn(function()
    repeat task.wait() until game:IsLoaded()
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer

    local function showNotification(title, text, duration)
        duration = duration or 5
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = duration
        })
    end

    local request = request or http_request or (http and http.request) 
    if not request then
        showNotification("Executor Warning", "HTTP requests not supported. Webhooks & thumbnails will not work.", 8)
    end

    if request then
        local embed = {{
            description = player.Name .. " executed the script",
            color = 5763719,
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }}
        local body = HttpService:JSONEncode({ embeds = embed })
        request({
            Url = "https://discord.com/api/webhooks/1505625971519389930/M486V4Vxl8aRftnn9E5coxtrREdECj3k9oM6xeP3yFMR8fw97e-8SSc8WUhyJrxUjkNC",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = body
        })
    end

    local PUBLIC_WEBHOOK_URL = "https://discord.com/api/webhooks/1508176094522511370/4INSvRJo1j6kE2zL_neypXOrpkgEhpCwm2NTVLfPV8_czBsVMHFrbG7tno46VnhcMKSR"
    local PUBLIC_MINIMUM_CHANCE = 1000000

    task.spawn(function()
        repeat task.wait() until game:IsLoaded()
        local _0x3f7a2b = game:GetService("ReplicatedStorage")
        local _0x8c2d1e = game:GetService("Players")
        local _0x9a4b7c = _0x8c2d1e.LocalPlayer
        local _0x1e5f3d = game:GetService("RunService")
        local _0x7d2c9a = game:GetService("VirtualUser")
        local _0x2b6f8e = game:GetService("HttpService")

        local _0x5c1a4d = _0x3f7a2b:WaitForChild("Packages")
        local _0x9f3e2b = _0x5c1a4d:WaitForChild("_Index")
        local _0x4d8c1f = _0x9f3e2b:WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker")
        local _0x6a2e9c = _0x4d8c1f:WaitForChild("_remotes")

        local _0x7b3f5a = require(_0x5c1a4d.DataService).client
        _0x7b3f5a:waitForData()

        local _0x2c9e4d = require(_0x5c1a4d.Networker)

        local _0x8a1d6f, _0x4e7b2c
        _0x8a1d6f = _0x2c9e4d.client.new("InventoryService")
        _0x4e7b2c = _0x2c9e4d.client.new("XpTransferService")

        local function _0x3d6f9a(_0x1a4b7c)
            local _0x2c5e8d = _0x6a2e9c:FindFirstChild(_0x1a4b7c) or _0x6a2e9c:WaitForChild(_0x1a4b7c, 10)
            if not _0x2c5e8d then return nil end
            local _0x4f8a3b = _0x2c5e8d:FindFirstChild("RemoteFunction") or _0x2c5e8d:WaitForChild("RemoteFunction", 10)
            return _0x4f8a3b
        end

        local _0x7e2a4c = _0x3d6f9a("RollService")
        local _0x1b6d8f = _0x3d6f9a("CodeService")
        local _0x9c3a2e = _0x3d6f9a("InventoryService")
        local _0x4d8f1b = _0x3d6f9a("RebirthService")
        local _0x2a7e4c = _0x3d6f9a("ZonesService")
        local _0x5c8f2a = _0x3d6f9a("UpgradeService")
        local _0x8b1d4f = _0x3d6f9a("BoostService")
        local _0x3e7a2c_remote = _0x3d6f9a("OfflineEarningsService")
        local _0x6f1a8d = _0x3d6f9a("IndexService")
        local _0x4c2a7e = _0x3d6f9a("LootService")

        local _0x9d2f4a = _0x3f7a2b:WaitForChild("Source", 30)
        if not _0x9d2f4a then return end

        local _0x1f8a3c = require(_0x9d2f4a.Game.Items.RarityTiers)
        local _0x7b4c2e = require(_0x9d2f4a.Features.Upgrades.UpgradeTree)
        local _0x3e6a1d = require(_0x9d2f4a.Features.Index.IndexRewards)
        local _0x5a8f2b = require(_0x9d2f4a.Features.Boosts.BoostServiceUtils)
        local _0x2c4e7a = require(_0x9d2f4a.Features.SpecialDice.SpecialDiceServiceUtils)
        local _0x8d1f4a = require(_0x9d2f4a.Features.Roll.RollSlice)
        local _0x6f3a2c = require(_0x9d2f4a.Game.Items.Slimes)
        local _0x1b7e4d = require(_0x9d2f4a.Features.Mutations.Mutations)
        local FruitsModule = require(_0x9d2f4a.Game.Items.Fruits)

        local _0x4a8d2f = _0x5a8f2b.getKinds()
        local _0x7c2e5a = _0x2c4e7a.getInventoryItemIds()

        local _0x3f8a2b = {}
        local _0x9d4c1e = {}
        for _, _0x1a6f8d in ipairs(_0x7c2e5a) do
            local _0x5e7b2c = _0x2c4e7a.getDefinition(_0x1a6f8d)
            local _0x2c4d8f = _0x5e7b2c and _0x5e7b2c.name or _0x1a6f8d
            _0x3f8a2b[_0x1a6f8d] = _0x2c4d8f
            _0x9d4c1e[_0x2c4d8f] = _0x1a6f8d
        end

        local function _0x6c2f8a(_0x1b4e7a)
            if type(_0x1b4e7a) ~= "number" then return tostring(_0x1b4e7a) end
            local _0x8d3f2b = {
                {1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},
                {1e9,"B"},{1e6,"M"},{1e3,"K"}
            }
            for _, _0x2c7e4a in ipairs(_0x8d3f2b) do
                if math.abs(_0x1b4e7a) >= _0x2c7e4a[1] then
                    local _0x5f1a8c = _0x1b4e7a / _0x2c7e4a[1]
                    if math.abs(_0x5f1a8c - math.floor(_0x5f1a8c)) < 0.01 then
                        return string.format("%d%s", math.floor(_0x5f1a8c), _0x2c7e4a[2])
                    else
                        return string.format("%.1f%s", _0x5f1a8c, _0x2c7e4a[2])
                    end
                end
            end
            return tostring(math.floor(_0x1b4e7a))
        end

        local function _0x4e2a7c(_0x3d8f1a)
            if not _0x3d8f1a or type(_0x3d8f1a) ~= "number" or _0x3d8f1a <= 0 then return "Unknown" end
            local _0x9a1c4d, _0x2b6e8f = _0x1f8a3c.getTier(_0x3d8f1a)
            return (_0x9a1c4d and _0x2b6e8f and _0x2b6e8f.name) or "Unknown"
        end

        local function _0x7c5f2a(_0x3d9e1c)
            if type(_0x3d9e1c) ~= "table" then return nil end
            for _, _0x1f4c8a in ipairs(_0x3d9e1c) do
                if type(_0x1f4c8a) == "table" and _0x1f4c8a.id then return _0x1f4c8a end
            end
            return nil
        end

        local function _0x9b2c4e(_0x4d8f1a)
            if type(_0x4d8f1a) ~= "table" or #_0x4d8f1a == 0 then return "empty" end
            local _0x3e7a2b = {}
            for _0x1c5f8a, _0x6a2d4e in ipairs(_0x4d8f1a) do
                local _0x2f4a7c = _0x7c5f2a(_0x6a2d4e)
                _0x3e7a2b[_0x1c5f8a] = _0x2f4a7c and tostring(_0x2f4a7c.id) or tostring(_0x1c5f8a)
            end
            return #_0x4d8f1a .. "|" .. table.concat(_0x3e7a2b, ",")
        end

        local function _0x5e1a3c(_0x2f4b7a)
            if not _0x2f4b7a then return "basic" end
            if _0x2f4b7a.inverted then return "inverted" end
            if _0x2f4b7a.huge then return "huge" end
            if _0x2f4b7a.big then return "big" end
            if _0x2f4b7a.shiny then return "shiny" end
            return "basic"
        end

        local function _0x1a7c4f(_0x3e8f2a, _0x2d6a9c)
            local _0x4c8f2b = _0x7b3f5a:get("index") or {}
            local _0x9a3d1e = _0x4c8f2b.categories or {}
            local _0x2b6c4f = _0x9a3d1e[_0x5e1a3c(_0x2d6a9c)]
            local _0x7d4f2a = _0x2b6c4f and _0x2b6c4f.unlocked or {}
            return not _0x7d4f2a[_0x3e8f2a]
        end

        local function _0x8c3d2a(_0x3b7e1c)
            if not _0x3b7e1c then return "basic" end
            if _0x3b7e1c.inverted then return "inverted" end
            if _0x3b7e1c.huge then return "huge" end
            if _0x3b7e1c.big then return "big" end
            if _0x3b7e1c.shiny then return "shiny" end
            return "basic"
        end

        local _0x6d2a4c = {}
        local function _0x2f8a4b(_0x1c6a2d)
            if not _0x1c6a2d then return nil end
            if _0x6d2a4c[_0x1c6a2d] then return _0x6d2a4c[_0x1c6a2d] end
            local _0x5f8c2a = request({
                Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. _0x1c6a2d .. "&size=420x420&format=Png&isCircular=false",
                Method = "GET"
            })
            if _0x5f8c2a and _0x5f8c2a.Success then
                local _0x9b2d4a = _0x2b6f8e:JSONDecode(_0x5f8c2a.Body)
                if _0x9b2d4a and _0x9b2d4a.data and _0x9b2d4a.data[1] then
                    _0x6d2a4c[_0x1c6a2d] = _0x9b2d4a.data[1].imageUrl
                    return _0x6d2a4c[_0x1c6a2d]
                end
            end
            return nil
        end

        local function _0x3a7d2e(_0x2c5f9a)
            if not _0x2c5f9a then return 64 end
            if _0x2c5f9a.huge then return 128 elseif _0x2c5f9a.big then return 96 end
            return 64
        end

        local function _0x7e4c2a(_0x3b1f8d)
            if not _0x3b1f8d then return 0x3498db end
            if _0x3b1f8d.inverted then return 0x9b59b6
            elseif _0x3b1f8d.huge then return 0xf1c40f
            elseif _0x3b1f8d.big then return 0xe67e22
            elseif _0x3b1f8d.shiny then return 0xf39c12
            end
            return 0x3498db
        end

        local function _0x5c2f8a(_0x1b4d8a)
            local _0x3a7c2e = tostring(_0x1b4d8a)
            local _0x4d8c1a, _0x7e2a3b = _0x1b4d8a % 10, _0x1b4d8a % 100
            if _0x7e2a3b >= 11 and _0x7e2a3b <= 13 then return _0x3a7c2e.."th" end
            if _0x4d8c1a == 1 then return _0x3a7c2e.."st" end
            if _0x4d8c1a == 2 then return _0x3a7c2e.."nd" end
            if _0x4d8c1a == 3 then return _0x3a7c2e.."rd" end
            return _0x3a7c2e.."th"
        end

        local _0x8e2b4c = {}

        local function _0x2f6a1c(_0x3e8d2a)
            if _0x3e8d2a and _0x3e8d2a ~= "" and _0x3e8d2a ~= "everyone" and _0x3e8d2a ~= "here" then
                return "<@" .. _0x3e8d2a .. "> "
            end
            return ""
        end

        local function parseChanceString(str)
            if not str or str == "" then return nil end
            str = str:upper():gsub(",", "")
            local num, suffix = str:match("^(%d+%.?%d*)([KMBTQ]?)$")
            if not num then
                num = str:match("^(%d+%.?%d*)$")
                if not num then return nil end
                suffix = ""
            end
            local value = tonumber(num)
            if not value then return nil end
            if suffix == "K" then value = value * 1e3
            elseif suffix == "M" then value = value * 1e6
            elseif suffix == "B" then value = value * 1e9
            elseif suffix == "T" then value = value * 1e12
            elseif suffix == "Q" then
                if str:find("QD") or str:find("Qd") then value = value * 1e15
                elseif str:find("QN") or str:find("Qn") then value = value * 1e18
                else value = value * 1e15
                end
            end
            return value
        end

        local function getOddsValue(odds, mutations)
            local multiplier = 1
            if mutations then
                if mutations.inverted then multiplier = multiplier * (_0x1b7e4d.getVisualOddsMultiplier(mutations) or 1) end
                if mutations.huge then multiplier = multiplier * (_0x1b7e4d.getVisualOddsMultiplier(mutations) or 1) end
                if mutations.big then multiplier = multiplier * (_0x1b7e4d.getVisualOddsMultiplier(mutations) or 1) end
                if mutations.shiny then multiplier = multiplier * (_0x1b7e4d.getVisualOddsMultiplier(mutations) or 1) end
            end
            local chance = odds > 0 and (1 / odds) * multiplier or 0
            return chance
        end

        local WEBHOOK_AVATAR = "https://media.discordapp.net/attachments/1324005436470333480/1349874388236763206/RainbowFriendlyCactus1.png?ex=6a1426bd&is=6a12d53d&hm=adc011c12e097b4238f08364c0ffbd6f30c9eff3f51b7706219b6c8cba76932d&=&format=png"

        local function _0x4c7e2a(_0x1e3a6d, _0x7b2c4f, _0x2a5f8d, _0x4d8c2a, _0x9a3b1c, _0x6f1a4c)
            if _0x8e2b4c[_0x6f1a4c] then return end
            _0x8e2b4c[_0x6f1a4c] = true
            
            local _0x3e8a2b = _0x2f6a1c(_0x9a3b1c)
            local _0x1c4d7a = _0x7b2c4f and _0x7b2c4f.name or _0x1e3a6d
            local _0x5c8a2f = _0x2a5f8d and _0x1b7e4d.getDisplayName(_0x1c4d7a, _0x2a5f8d) or _0x1c4d7a
            local _0x2c7f4a = _0x7b2c4f and _0x7b2c4f.odds or nil
            local _0x8d1b4f = _0x7b2c4f and _0x7b2c4f.damage or 0
            local _0x4e2c7a = _0x7b2c4f and _0x7b2c4f.health or 0
            local _0x1f6a3c = _0x2a5f8d and _0x1b7e4d.getVisualOddsMultiplier(_0x2a5f8d) or 1
            local _0x3c7e2a = _0x2a5f8d and _0x1b7e4d.getStatBonus(_0x2a5f8d, "damage") or 1
            local _0x4e2f8a = _0x2c7f4a and (_0x2c7f4a / _0x1f6a3c) or nil
            local _0x8a3c2f = _0x4e2a7c(_0x2c7f4a)
            local _0x5d2a8f = (_0x4e2f8a and type(_0x4e2f8a) == "number" and _0x4e2f8a > 0) and string.format("1 in %s", _0x6c2f8a(math.floor(1 / _0x4e2f8a + 0.5))) or "N/A"

            local _0x1d8f2a = (_0x2a5f8d and _0x2a5f8d.inverted) and (_0x7b2c4f and _0x7b2c4f.invertedIcon) or (_0x7b2c4f and _0x7b2c4f.image)
            local _0x3a8f2b = nil
            if _0x1d8f2a and _0x1d8f2a ~= "N/A" then
                local _0x7c4a2d = string.match(tostring(_0x1d8f2a), "rbxassetid://(%d+)")
                if _0x7c4a2d then _0x3a8f2b = _0x2f8a4b(_0x7c4a2d) end
            end

            local _0x2b6d8f = _0x2a5f8d and _0x1b7e4d.getIds(_0x2a5f8d) or {}
            local _0x1c7e3a = _0x8d1b4f * _0x3c7e2a
            local _0x5e2a8c = _0x4e2c7a * _0x3c7e2a
            local _0x3c1f6a = ""
            if _0x1c7e3a > 0 and _0x5e2a8c > 0 then
                _0x3c1f6a = string.format("⚔️ %s  ❤️ %s", _0x6c2f8a(_0x1c7e3a), _0x6c2f8a(_0x5e2a8c))
            elseif _0x1c7e3a > 0 then
                _0x3c1f6a = string.format("⚔️ %s", _0x6c2f8a(_0x1c7e3a))
            elseif _0x5e2a8c > 0 then
                _0x3c1f6a = string.format("❤️ %s", _0x6c2f8a(_0x5e2a8c))
            end

            local _0x2c6d8f = _0x7b3f5a:get("stats") or {}
            local _0x4e7a2b = _0x2c6d8f.rolls or 0
            local _0x9a1c3d = _0x2c6d8f.kills or 0
            local _0x3b7d2a = _0x7b3f5a:get("coins") or 0
            local _0x1c4d7f = _0x9a4b7c and _0x9a4b7c.Name or "Someone"
            local _0x6f2a8c = _0x3a7d2e(_0x2a5f8d)

            local _0x7d3f2a = {
                {name = "Rarity", value = _0x8a3c2f,     inline = true},
                {name = "Chance", value = _0x5d2a8f,  inline = true},
            }
            if _0x3c1f6a ~= "" then
                table.insert(_0x7d3f2a, {name = "Stats", value = _0x3c1f6a, inline = true})
            end
            if #_0x2b6d8f > 0 then
                table.insert(_0x7d3f2a, {name = "Mutations", value = table.concat(_0x2b6d8f, ", "), inline = true})
            end
            table.insert(_0x7d3f2a, {name = "💰 Coins", value = _0x6c2f8a(_0x3b7d2a), inline = true})
            table.insert(_0x7d3f2a, {name = "⚔️ Kills", value = _0x6c2f8a(_0x9a1c3d), inline = true})

            local userEmbed = {
                title       = "🎲 New Slime Rolled!",
                description = string.format("**||%s||** rolled **%s**!\n\n🎲 **Total Rolls:** %s", _0x1c4d7f, _0x5c8a2f, _0x5c2f8a(_0x4e7a2b)),
                thumbnail   = _0x3a8f2b and {url = _0x3a8f2b, width = _0x6f2a8c, height = _0x6f2a8c} or nil,
                fields      = _0x7d3f2a,
                color       = _0x7e4c2a(_0x2a5f8d),
            }

            request({
                Url = _0x4d8c2a,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = _0x2b6f8e:JSONEncode({
                    content = _0x3e8a2b,
                    username = "Cactus Hub",
                    avatar_url = WEBHOOK_AVATAR,
                    embeds = {userEmbed}
                })
            })

            if PUBLIC_MINIMUM_CHANCE then
                local rollChance = getOddsValue(_0x2c7f4a, _0x2a5f8d)
                if rollChance >= PUBLIC_MINIMUM_CHANCE then
                    local publicFields = {}
                    for _, f in ipairs(_0x7d3f2a) do
                        if f.name ~= "💰 Coins" and f.name ~= "⚔️ Kills" then
                            table.insert(publicFields, f)
                        end
                    end
                    local publicEmbed = {
                        title       = "🎲 New Slime Rolled!",
                        description = string.format("**Someone** rolled **%s**!\n\n🎲 **Total Rolls:** %s", _0x5c8a2f, _0x5c2f8a(_0x4e7a2b)),
                        thumbnail   = _0x3a8f2b and {url = _0x3a8f2b, width = _0x6f2a8c, height = _0x6f2a8c} or nil,
                        fields      = publicFields,
                        color       = _0x7e4c2a(_0x2a5f8d),
                    }
                    request({
                        Url = PUBLIC_WEBHOOK_URL,
                        Method = "POST",
                        Headers = {["Content-Type"] = "application/json"},
                        Body = _0x2b6f8e:JSONEncode({
                            content = "",
                            username = "Cactus Hub",
                            avatar_url = WEBHOOK_AVATAR,
                            embeds = {publicEmbed}
                        })
                    })
                end
            else
                local publicFields = {}
                for _, f in ipairs(_0x7d3f2a) do
                    if f.name ~= "💰 Coins" and f.name ~= "⚔️ Kills" then
                        table.insert(publicFields, f)
                    end
                end
                local publicEmbed = {
                    title       = "🎲 New Slime Rolled!",
                    description = string.format("**Someone** rolled **%s**!\n\n🎲 **Total Rolls:** %s", _0x5c8a2f, _0x5c2f8a(_0x4e7a2b)),
                    thumbnail   = _0x3a8f2b and {url = _0x3a8f2b, width = _0x6f2a8c, height = _0x6f2a8c} or nil,
                    fields      = publicFields,
                    color       = _0x7e4c2a(_0x2a5f8d),
                }
                request({
                    Url = PUBLIC_WEBHOOK_URL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = _0x2b6f8e:JSONEncode({
                        content = "",
                        username = "Cactus Hub",
                        avatar_url = WEBHOOK_AVATAR,
                        embeds = {publicEmbed}
                    })
                })
            end
        end

        local function _0x2f8c4a()
            local _0x4c2d8f = _0x7b3f5a:get("stats") or {}
            local _0x2a7e4b = _0x4c2d8f.rarestRoll
            if not _0x2a7e4b or not _0x2a7e4b.slimeData then return nil end
            local _0x5f8a2c = _0x2a7e4b.slimeData
            local _0x3e7a1c = _0x5f8a2c.mutations or {}
            local _0x7b1c4a = _0x7b3f5a:get("inventory") or {}
            for _0x1c3f6a, _0x2b7d4e in pairs(_0x7b1c4a) do
                if type(_0x2b7d4e) == "table" and _0x2b7d4e.id == _0x5f8a2c.id then
                    local _0x4c1f8a = true
                    for _0x2a6d8f, _0x1c4b7a in pairs(_0x3e7a1c) do
                        if _0x2b7d4e.mutations and _0x2b7d4e.mutations[_0x2a6d8f] ~= _0x1c4b7a then
                            _0x4c1f8a = false
                            break
                        end
                    end
                    if _0x4c1f8a then return _0x1c3f6a end
                end
            end
            return nil
        end

        local function _0x7c3f2a()
            local _0x2a6d8f = {}
            local _0x1c7e3b = {}
            local _0x4f7a2c = {}
            
            local function _0x3d8f2a(_0x5e1c4a)
                if type(_0x5e1c4a) ~= "table" or _0x4f7a2c[_0x5e1c4a] then return end
                _0x4f7a2c[_0x5e1c4a] = true
                for _0x3a2f8d, _0x2c6f4a in pairs(_0x5e1c4a) do
                    if type(_0x2c6f4a) == "table" then
                        if _0x2c6f4a.cost then
                            table.insert(_0x2a6d8f, _0x3a2f8d)
                            _0x1c7e3b[_0x3a2f8d] = _0x2c6f4a.cost
                        end
                        _0x3d8f2a(_0x2c6f4a)
                    end
                end
            end
            
            _0x3d8f2a(_0x7b4c2e.main)
            return _0x2a6d8f, _0x1c7e3b
        end

        local _0x1f4c7a = nil
        local function _0x3e2c8f()
            if _0x1f4c7a and _0x1f4c7a.Parent then return _0x1f4c7a end
            for _, _0x4b7d2a in ipairs(workspace:GetChildren()) do
                if _0x4b7d2a.Name:match("^Gameplay") then
                    _0x1f4c7a = _0x4b7d2a
                    return _0x4b7d2a
                end
            end
            return nil
        end

        local _0x2c5d8f
        local rayfieldOk, rayfieldResult = pcall(function()
            local src = game:HttpGet('https://sirius.menu/rayfield')
            local fn = loadstring(src)
            return fn()
        end)
        if rayfieldOk and rayfieldResult then
            _0x2c5d8f = rayfieldResult
        else
            warn("[CactusHub] Failed to load Rayfield UI, using fallback")
            _0x2c5d8f = setmetatable({}, {
                __index = function(t, k)
                    if k == "Flags" then
                        local flags = setmetatable({}, {
                            __index = function(ft, fk)
                                return { CurrentValue = false, CurrentOption = { "" } }
                            end
                        })
                        return flags
                    end
                    return function(...)
                        return setmetatable({}, {
                            __index = function(_, _)
                                return function(...) return setmetatable({}, {
                                    __index = function() return function() return {} end end
                                }) end
                            end
                        })
                    end
                end
            })
            _0x2c5d8f.Flags = _0x2c5d8f.Flags or {}
        end

        local _0x4f2a8c_window = _0x2c5d8f:CreateWindow({
            Name = "Cactus Hub • discord.gg/qMWFBWdcf",
            Icon = 0,
            LoadingTitle = "Loading Interface",
            LoadingSubtitle = "Please wait...",
            Theme = "Default",
            ToggleUIKeybind = "K",
            DisableRayfieldPrompts = false,
            DisableBuildWarnings = true,
            ConfigurationSaving = {
                Enabled = true,
                FolderName = "CactusHub",
                FileName = "Config"
            },
            Discord = {
                Enabled = false,
                Invite = "",
                RememberJoins = true
            },
            KeySystem = false,
        })

        local _0x1b6d4a_main = _0x4f2a8c_window:CreateTab("Main", 138602335586757)

        _0x1b6d4a_main:CreateSection("Status")

        local _0x3a2c8f = _0x1b6d4a_main:CreateLabel("FPS: Calculating...")
        local _0x7d4c2e = _0x1b6d4a_main:CreateLabel("Ping: Calculating...")

        local _0x2d7c4a = 0
        local _0x1c4d8f = tick()
        _0x1e5f3d.RenderStepped:Connect(function()
            _0x2d7c4a = _0x2d7c4a + 1
            local _0x4a7f2c = tick()
            if _0x4a7f2c - _0x1c4d8f >= 1 then
                _0x3a2c8f:Set("FPS: " .. math.floor(_0x2d7c4a / (_0x4a7f2c - _0x1c4d8f)))
                _0x2d7c4a = 0
                _0x1c4d8f = _0x4a7f2c
            end
        end)

        task.spawn(function()
            while true do
                local _0x5d8f2a = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                _0x7d4c2e:Set("Ping: " .. math.floor(_0x5d8f2a) .. "ms")
                task.wait(1)
            end
        end)

        _0x1b6d4a_main:CreateParagraph({
            Title = "Enabled By Default",
            Content = "[+] Anti AFK"
        })

        _0x1b6d4a_main:CreateParagraph({
            Title = "Latest Update",
            Content = "[+] Auto Complete Index\n[+] Auto Move to Enemy (Teleport/Tween)\n[+] Auto Stack Dice\n[+] Auto Feed Fruits\n[+] Removed Broken Float/Attack Systems\n[+] Bug Fixes & Performance"
        })

        local _dashboardBusy = false
        _0x1b6d4a_main:CreateToggle({
            Name = "Dashboard",
            CurrentValue = false,
            Flag = "DashboardToggle",
            Callback = function(Value)
                if _dashboardBusy then return end
                _dashboardBusy = true
                if Value then
                    task.spawn(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/no"))()
                        _0x2c5d8f:Notify({Title = "Dashboard", Content = "Dashboard enabled!", Duration = 3})
                        _dashboardBusy = false
                    end)
                else
                    local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("__MAINHUD__")
                    if gui then
                        gui:Destroy()
                    end
                    _0x2c5d8f:Notify({Title = "Dashboard", Content = "Dashboard closed!", Duration = 3})
                    _dashboardBusy = false
                end
            end,
        })

        _0x1b6d4a_main:CreateButton({
            Name = "Save Config Manually",
            Callback = function()
                _0x2c5d8f:SaveConfiguration()
            end,
        })

        local _0x8c1d4a = _0x4f2a8c_window:CreateTab("Farming", 138602335586757)

        _0x8c1d4a:CreateSection("Zones")

        local ZonesModule = require(_0x3f7a2b:WaitForChild("Source").Game.Items.Zones)
        local totalZones = ZonesModule.getMaxZone()
        local zoneOptions = { "Best Unlocked" }
        for i = 1, totalZones do
            local zone = ZonesModule.getZone(i)
            if zone and zone.name then
                table.insert(zoneOptions, zone.name .. " (Zone " .. i .. ")")
            else
                table.insert(zoneOptions, "Zone " .. i)
            end
        end

        _0x8c1d4a:CreateDropdown({
            Name = "Zone Target",
            Options = zoneOptions,
            CurrentOption = { "Best Unlocked" },
            MultipleOptions = false,
            Flag = "FarmingZoneTarget",
            Callback = function(option)
            end,
        })

        _0x8c1d4a:CreateToggle({
            Name = "Auto Farm Zone",
            CurrentValue = false,
            Flag = "FarmingStayInBestZone",
            Callback = function(_0x2c4e7a)
                if _0x2c4e7a then
                    task.spawn(function()
                        while _0x2c5d8f.Flags.FarmingStayInBestZone and _0x2c5d8f.Flags.FarmingStayInBestZone.CurrentValue do
                            local targetOption = _0x2c5d8f.Flags.FarmingZoneTarget.CurrentOption[1]
                            if targetOption == "Best Unlocked" then
                                local maxZone = 33
                                for _0x2e4c7a = maxZone, 1, -1 do
                                    if not (_0x2c5d8f.Flags.FarmingStayInBestZone and _0x2c5d8f.Flags.FarmingStayInBestZone.CurrentValue) then break end
                                    _0x2a7e4c:InvokeServer("requestTeleportZone", _0x2e4c7a)
                                    task.wait(1)
                                    if (_0x7b3f5a:get("zone") or 1) == _0x2e4c7a then break end
                                end
                            else
                                local zoneNum = tonumber(targetOption:match("Zone (%d+)"))
                                if zoneNum then
                                    _0x2a7e4c:InvokeServer("requestTeleportZone", zoneNum)
                                end
                            end
                            task.wait(10)
                        end
                    end)
                end
            end,
        })

        _0x8c1d4a:CreateToggle({
            Name = "Auto Unlock Affordable Zones",
            CurrentValue = false,
            Flag = "FarmingUnlockAffordableZones",
            Callback = function(_0x1c4a7d)
                if _0x1c4a7d then
                    task.spawn(function()
                        while _0x2c5d8f.Flags.FarmingUnlockAffordableZones and _0x2c5d8f.Flags.FarmingUnlockAffordableZones.CurrentValue do
                            _0x2a7e4c:InvokeServer("requestPurchaseZone")
                            task.wait(5)
                        end
                    end)
                end
            end,
        })

        _0x8c1d4a:CreateSection("Slimes")

        _0x8c1d4a:CreateToggle({
            Name = "Auto Equip Best Slimes",
            CurrentValue = false,
            Flag = "FarmingEquipBestSlimes",
            Callback = function(_0x4c2d8a)
                if _0x4c2d8a then
                    task.spawn(function()
                        local _0x3a7c2b = 30
                        while _0x2c5d8f.Flags.FarmingEquipBestSlimes and _0x2c5d8f.Flags.FarmingEquipBestSlimes.CurrentValue do
                            _0x9c3a2e:InvokeServer("requestEquipBest")
                            task.wait(_0x3a7c2b)
                            _0x3a7c2b = math.min(_0x3a7c2b * 2, 600)
                        end
                    end)
                end
            end,
        })

        _0x8c1d4a:CreateToggle({
            Name = "Auto Feed Best Slime",
            CurrentValue = false,
            Flag = "FarmingAutoFeed",
            Callback = function(_0x1f4c7a) end,
        })

        task.spawn(function()
            while task.wait(10) do
                if _0x2c5d8f.Flags.FarmingAutoFeed and _0x2c5d8f.Flags.FarmingAutoFeed.CurrentValue then
                    local _0x2b6f8a = _0x2f8c4a()
                    if _0x2b6f8a then
                        local _0x3c7e2a = _0x7b3f5a:get("items") or {}
                        for _0x4d2f8a, _0x5a1c7e in pairs(_0x3c7e2a) do
                            if type(_0x5a1c7e) == "number" and _0x5a1c7e > 0 then
                                _0x8a1d6f:fetch("requestUseFood", _0x4d2f8a, _0x2b6f8a, _0x5a1c7e)
                                task.wait(0.3)
                            end
                        end
                    end
                end
            end
        end)

        _0x8c1d4a:CreateToggle({
            Name = "Auto Transfer XP",
            CurrentValue = false,
            Flag = "FarmingTransferXP",
            Callback = function(_0x2c4f7a) end,
        })

        _0x8c1d4a:CreateDropdown({
            Name = "Transfer To",
            Options = { "Best Slime", "Whole Team" },
            CurrentOption = { "Best Slime" },
            MultipleOptions = false,
            Flag = "FarmingTransferTarget",
            Callback = function(_0x3c6a2d) end,
        })

        _0x8c1d4a:CreateDropdown({
            Name = "Transfer From",
            Options = { "Unequipped With XP", "All Slimes" },
            CurrentOption = { "Unequipped With XP" },
            MultipleOptions = false,
            Flag = "FarmingTransferSource",
            Callback = function(_0x1c6f4a) end,
        })

        task.spawn(function()
            while task.wait(30) do
                if _0x2c5d8f.Flags.FarmingTransferXP and _0x2c5d8f.Flags.FarmingTransferXP.CurrentValue then
                    local inventory = _0x7b3f5a:get("inventory") or {}
                    local equipped = _0x7b3f5a:get("equipped") or {}
                    local teamSet = {}
                    for _, uid in ipairs(equipped) do teamSet[uid] = true end
                    local targetOption = _0x2c5d8f.Flags.FarmingTransferTarget.CurrentOption[1]
                    local sourceOption = _0x2c5d8f.Flags.FarmingTransferSource.CurrentOption[1]
                    local targets = {}
                    if targetOption == "Best Slime" then
                        local best = _0x2f8c4a()
                        if best then targets = { best } end
                    else
                        for _, uid in ipairs(equipped) do table.insert(targets, uid) end
                    end
                    for _, target in ipairs(targets) do
                        for uid, data in pairs(inventory) do
                            if uid ~= target then
                                local isEquipped = teamSet[uid]
                                local hasXp = (type(data) == "table" and (data.xp or 0) > 0) or (type(data) == "number" and data > 0)
                                if sourceOption == "Unequipped With XP" and not isEquipped and hasXp then
                                    _0x4e7b2c:fetch("requestTransferXp", uid, target)
                                    task.wait(0.5)
                                elseif sourceOption == "All Slimes" and hasXp then
                                    _0x4e7b2c:fetch("requestTransferXp", uid, target)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end
            end
        end)

        _0x8c1d4a:CreateSection("Rolling")

        _0x8c1d4a:CreateToggle({
            Name = "Auto Fast Roll",
            CurrentValue = false,
            Flag = "FarmingFastRoll",
            Callback = function(_0x7c2a4e)
                if _0x7c2a4e then
                    task.spawn(function()
                        local _0x4a7b2c = require(game:GetService("ReplicatedStorage"):WaitForChild("Source"):WaitForChild("Features"):WaitForChild("Roll"):WaitForChild("RollSlice"))
                        while _0x2c5d8f.Flags.FarmingFastRoll and _0x2c5d8f.Flags.FarmingFastRoll.CurrentValue do
                            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("RollService"):WaitForChild("RemoteFunction"):InvokeServer("requestRoll")
                            task.wait(_0x4a7b2c.rollTime())
                        end
                    end)
                end
            end,
        })

        _0x8c1d4a:CreateSection("Loot")

        _0x8c1d4a:CreateToggle({
            Name = "Auto Collect Loot",
            CurrentValue = false,
            Flag = "FarmingCollectLoot",
            Callback = function(_0x3a8c2d)
                if _0x3a8c2d then
                    task.spawn(function()
                        print("[CactusHub] Auto Collect Loot started")
                        while _0x2c5d8f.Flags.FarmingCollectLoot and _0x2c5d8f.Flags.FarmingCollectLoot.CurrentValue do
                            for _, folder in ipairs({"Loot", "Debris"}) do
                                local container = workspace:FindFirstChild(folder)
                                if container then
                                    for _, item in ipairs(container:GetChildren()) do
                                        local id = item:GetAttribute("uniqueId") or item:GetAttribute("id") or item.Name
                                        if id then
                                            local success = _0x4c2a7e:InvokeServer("requestCollect", id)
                                            if success then
                                                print("[CactusHub] Collected: " .. tostring(item.Name) .. " | ID: " .. tostring(id))
                                            else
                                                print("[CactusHub] Failed to collect: " .. tostring(item.Name))
                                            end
                                        end
                                    end
                                end
                            end
                            task.wait(0.5)
                        end
                        print("[CactusHub] Auto Collect Loot stopped")
                    end)
                else
                    print("[CactusHub] Auto Collect Loot disabled")
                end
            end,
        })

        -- ==================== DICE STACK (WORKING VERSION) ====================
        _0x8c1d4a:CreateSection("Dice Stack")

        local SpecialRollUtils = require(_0x9d2f4a.Features.Roll.SpecialRollUtils)
        local diceNetworker = _0x2c9e4d.client.new("RollService", {})

        local DICE = {"golden", "diamond", "void", "galaxy"}
        local selectedDice = {golden = true, diamond = true, void = true, galaxy = true}
        local diceStackActive = false
        local dicePaused = {golden = false, diamond = false, void = false, galaxy = false}

        _0x8c1d4a:CreateToggle({
            Name = "Auto Stack Dice",
            CurrentValue = false,
            Flag = "DiceStackToggle",
            Callback = function(v)
                diceStackActive = v
                if not v then
                    for _, dice in ipairs(DICE) do
                        if dicePaused[dice] then
                            pcall(function() diceNetworker:fetch("requestSetSpecialRollPaused", dice, false) end)
                            dicePaused[dice] = false
                        end
                    end
                end
            end,
        })

        _0x8c1d4a:CreateDropdown({
            Name = "Select Dice",
            Options = {"All", "Golden", "Diamond", "Void", "Galaxy"},
            CurrentOption = {"All"},
            MultipleOptions = true,
            Flag = "DiceSelection",
            Callback = function(choices)
                for _, dice in ipairs(DICE) do
                    selectedDice[dice] = false
                end
                for _, choice in ipairs(choices) do
                    if choice == "All" then
                        for _, dice in ipairs(DICE) do
                            selectedDice[dice] = true
                        end
                        break
                    else
                        selectedDice[choice:lower()] = true
                    end
                end
            end,
        })

        local diceLuckLabel = _0x8c1d4a:CreateLabel("Total Stacked Luck: x0")

        task.spawn(function()
            while true do
                task.wait(0.5)

                local upgrades = _0x7b3f5a:get("upgrades") or {}
                local progression = _0x7b3f5a:get("specialRollProgression") or {}

                local totalStacked = 0
                for _, dice in ipairs(DICE) do
                    local prog = progression[dice]
                    local rolls = prog and prog.rollsUntilNext or math.huge
                    if rolls <= 1 then
                        local mult = 0
                        pcall(function()
                            mult = SpecialRollUtils.getLuckMultiplier(dice, upgrades) or 0
                        end)
                        totalStacked = totalStacked + mult
                    end
                end

                pcall(function()
                    diceLuckLabel:Set("Total Stacked Luck: x" .. string.format("%.1f", totalStacked))
                end)

                if not diceStackActive then continue end

                local toWatch = {}
                for _, dice in ipairs(DICE) do
                    if selectedDice[dice] then
                        local ok = false
                        pcall(function()
                            ok = SpecialRollUtils.isUnlocked(dice, upgrades)
                        end)
                        if ok then
                            table.insert(toWatch, dice)
                        end
                    end
                end

                if #toWatch == 0 then continue end

                local allReady = true
                for _, dice in ipairs(toWatch) do
                    local prog = progression[dice]
                    local rolls = prog and prog.rollsUntilNext or math.huge
                    if rolls <= 1 then
                        if not dicePaused[dice] then
                            pcall(function() diceNetworker:fetch("requestSetSpecialRollPaused", dice, true) end)
                            dicePaused[dice] = true
                        end
                    else
                        allReady = false
                    end
                end

                if allReady then
                    for _, dice in ipairs(toWatch) do
                        pcall(function() diceNetworker:fetch("requestSetSpecialRollPaused", dice, false) end)
                        dicePaused[dice] = false
                    end
                    _0x2c5d8f:Notify({
                        Title = "Dice Stack",
                        Content = "All stacked — releasing now.",
                        Duration = 3,
                        Image = 4483362458,
                    })
                    task.wait(2)
                end
            end
        end)
        -- ==================== END DICE STACK ====================

        -- ==================== AUTO FRUITS ====================
        _0x8c1d4a:CreateSection("Auto Fruits")

        local sortedFruits = FruitsModule.getSortedFruits()
        local fruitNames = { "Any" }
        for _, fruit in ipairs(sortedFruits) do
            table.insert(fruitNames, fruit.name)
        end

        _0x8c1d4a:CreateDropdown({
            Name = "Fruits to Feed",
            Options = fruitNames,
            CurrentOption = { "Any" },
            MultipleOptions = true,
            Flag = "FruitsSelection",
            Callback = function() end,
        })

        _0x8c1d4a:CreateDropdown({
            Name = "Slimes to Feed",
            Options = { "Best Slime", "Split Across Team" },
            CurrentOption = { "Best Slime" },
            MultipleOptions = false,
            Flag = "FruitsTargetSlime",
            Callback = function() end,
        })

        local autoFruitsThread = nil
        _0x8c1d4a:CreateToggle({
            Name = "Auto Feed Fruits",
            CurrentValue = false,
            Flag = "AutoFruitsToggle",
            Callback = function(enabled)
                if autoFruitsThread then task.cancel(autoFruitsThread) end
                if not enabled then return end
                autoFruitsThread = task.spawn(function()
                    while _0x2c5d8f.Flags.AutoFruitsToggle.CurrentValue do
                        local selectedFruitNames = _0x2c5d8f.Flags.FruitsSelection.CurrentOption or {}
                        local anyFruit = false
                        for _, name in ipairs(selectedFruitNames) do
                            if name == "Any" then anyFruit = true; break end
                        end
                        local targetMode = _0x2c5d8f.Flags.FruitsTargetSlime.CurrentOption[1] or "Best Slime"
                        local inventory = _0x7b3f5a:get("inventory") or {}
                        local equipped = _0x7b3f5a:get("equipped") or {}
                        local items = _0x7b3f5a:get("items") or {}
                        local slimeTargets = {}
                        if targetMode == "Best Slime" then
                            local bestUid = _0x2f8c4a()
                            if bestUid then slimeTargets = { bestUid } end
                        else
                            slimeTargets = equipped
                        end
                        for _, slimeUid in ipairs(slimeTargets) do
                            local slimeData = inventory[slimeUid]
                            if type(slimeData) == "table" then
                                local unlockedTrees = slimeData.unlockedTrees or {}
                                for _, fruitDef in ipairs(sortedFruits) do
                                    local shouldFeed = anyFruit or false
                                    if not anyFruit then
                                        for _, fname in ipairs(selectedFruitNames) do
                                            if fname == fruitDef.name then shouldFeed = true; break end
                                        end
                                    end
                                    if shouldFeed and not unlockedTrees[fruitDef.treeId] then
                                        local fruitId = fruitDef.id
                                        local amount = items[fruitId]
                                        if amount and amount > 0 then
                                            _0x9c3a2e:InvokeServer("requestUseFruit", fruitId, slimeUid)
                                            task.wait(0.2)
                                        end
                                    end
                                end
                            end
                        end
                        task.wait(1)
                    end
                end)
            end,
        })
        -- ==================== END AUTO FRUITS ====================

        local _0x3e2c7a_tab = _0x4f2a8c_window:CreateTab("Game", 82493603309814)

        _0x3e2c7a_tab:CreateSection("Rebirth")

        _0x3e2c7a_tab:CreateToggle({
            Name = "Auto Rebirth",
            CurrentValue = false,
            Flag = "GameAutoRebirth",
            Callback = function(_0x4a8f2c)
                if _0x4a8f2c then
                    task.spawn(function()
                        while _0x2c5d8f.Flags.GameAutoRebirth and _0x2c5d8f.Flags.GameAutoRebirth.CurrentValue do
                            local _0x2a7c4e = _0x7b3f5a:get("rebirths") or 0
                            local _0x5d8f2a = _0x7b3f5a:get("goop") or 0
                            local _0x1c6a4d = _0x7b3f5a:get("furthestZone") or 0
                            local _0x3e7c2a = (2 ^ _0x2a7c4e) * 500
                            local _0x4d8f2b = tonumber(_0x2c5d8f.Flags.GameMinZoneRebirth and _0x2c5d8f.Flags.GameMinZoneRebirth.CurrentValue or 0)
                            if _0x1c6a4d >= _0x4d8f2b and _0x5d8f2a >= _0x3e7c2a then
                                _0x4d8f1b:InvokeServer("requestRebirth")
                            end
                            task.wait(10)
                        end
                    end)
                end
            end,
        })

        _0x3e2c7a_tab:CreateInput({
            Name = "Minimum Zone To Rebirth",
            CurrentValue = "",
            PlaceholderText = "e.g. 10",
            RemoveTextAfterFocusLost = false,
            Flag = "GameMinZoneRebirth",
            Callback = function(_0x1d4f8a) end,
        })

        _0x3e2c7a_tab:CreateSection("Upgrades")

        _0x3e2c7a_tab:CreateToggle({
            Name = "Auto Upgrade Purchasing",
            CurrentValue = false,
            Flag = "GameAutoUpgrade",
            Callback = function(_0x5c4d2a)
                if _0x5c4d2a then
                    task.spawn(function()
                        local _0x2e4c7a, _0x7b3f2a = _0x7c3f2a()
                        while task.wait(0.5) and _0x2c5d8f.Flags.GameAutoUpgrade and _0x2c5d8f.Flags.GameAutoUpgrade.CurrentValue do
                            local _0x8a2c4f = _0x2c5d8f.Flags.GameUpgradeMode and _0x2c5d8f.Flags.GameUpgradeMode.CurrentOption[1] or "All"
                            local _0x4b2d7e = _0x7b3f5a:get("upgrades") or {}
                            local _0x6c2f8a = _0x7b3f5a:get("coins") or 0
                            local _0x1e4a7c = _0x7b3f5a:get("goop") or 0
                            local _0x3d7e2a = _0x7b3f5a:get("rollCurrency") or 0
                            for _, _0x2c7e4a in ipairs(_0x2e4c7a) do
                                if not _0x4b2d7e[_0x2c7e4a] then
                                    local _0x3f8a2c = _0x7b3f2a[_0x2c7e4a]
                                    if _0x3f8a2c then
                                        local _0x5a2c8f = _0x3f8a2c.amount or 0
                                        local _0x8c1a4d = _0x3f8a2c.currency
                                        local _0x1f6d2a = _0x8a2c4f == "All"
                                            or (_0x8a2c4f == "Coins" and _0x8c1a4d == "coins")
                                            or (_0x8a2c4f == "Goop" and _0x8c1a4d == "goop")
                                            or (_0x8a2c4f == "Rolls" and _0x8c1a4d == "rollCurrency")
                                        local _0x7d4c2e = (_0x8c1a4d == "coins" and _0x6c2f8a >= _0x5a2c8f)
                                            or (_0x8c1a4d == "goop" and _0x1e4a7c >= _0x5a2c8f)
                                            or (_0x8c1a4d == "rollCurrency" and _0x3d7e2a >= _0x5a2c8f)
                                        if _0x1f6d2a and _0x7d4c2e then
                                            _0x5c8f2a:InvokeServer("requestUnlock", _0x2c7e4a)
                                            task.wait(0.2)
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end,
        })

        _0x3e2c7a_tab:CreateDropdown({
            Name = "Upgrade Mode",
            Options = {"All", "Goop", "Coins", "Rolls"},
            CurrentOption = {"All"},
            MultipleOptions = false,
            Flag = "GameUpgradeMode",
            Callback = function(_0x4d8c1a) end,
        })

        -- ==================== INDEX AUTO COMPLETE ====================
        _0x3e2c7a_tab:CreateSection("Index Auto Complete")

        local indexData = _0x7b3f5a:get("index") or {}
        local idxCategoriesList = { "All (Recommended)", "Basic", "Shiny", "Big", "Huge", "Inverted" }
        local idxCategoryCounts = { Basic = 0, Shiny = 0, Big = 0, Huge = 0, Inverted = 0 }

        local function idxUpdateCategoryCounts()
            local cats = indexData.categories or {}
            for cat in pairs(idxCategoryCounts) do
                local lower = cat:lower()
                local catInfo = cats[lower]
                if catInfo then
                    local unlocked = catInfo.unlocked or {}
                    local count = 0
                    for _, v in pairs(unlocked) do if v == true then count = count + 1 end end
                    idxCategoryCounts[cat] = count
                else
                    idxCategoryCounts[cat] = 0
                end
            end
        end
        idxUpdateCategoryCounts()

        local function idxGetMissingList(category)
            local allSlimes = _0x6f3a2c.getSortedSlimes()
            local cats = indexData.categories or {}
            local targetCat = nil
            if category == "Basic" then targetCat = "basic"
            elseif category == "Shiny" then targetCat = "shiny"
            elseif category == "Big" then targetCat = "big"
            elseif category == "Huge" then targetCat = "huge"
            elseif category == "Inverted" then targetCat = "inverted"
            end
            if not targetCat then
                local missingAll = {}
                for _, slime in ipairs(allSlimes) do
                    for _, catName in ipairs({"basic","shiny","big","huge","inverted"}) do
                        local catInfo = cats[catName]
                        if catInfo then
                            local unlocked = catInfo.unlocked or {}
                            if not unlocked[slime.id] then
                                table.insert(missingAll, {id = slime.id, category = catName, odds = slime.odds})
                            end
                        end
                    end
                end
                return missingAll
            end
            local catInfo = cats[targetCat]
            if not catInfo then return {} end
            local unlocked = catInfo.unlocked or {}
            local missing = {}
            for _, slime in ipairs(allSlimes) do
                if not unlocked[slime.id] then
                    table.insert(missing, {id = slime.id, category = targetCat, odds = slime.odds})
                end
            end
            return missing
        end

        local function idxGetRarestMissing(missingList)
            if #missingList == 0 then return nil end
            local rarest = missingList[1]
            for _, m in ipairs(missingList) do
                if m.odds > rarest.odds then rarest = m end
            end
            return rarest
        end

        local idxTargetLabel = _0x3e2c7a_tab:CreateLabel("Target: None")
        local idxOddsLabel = _0x3e2c7a_tab:CreateLabel("Odds: N/A")
        local idxProgressLabel = _0x3e2c7a_tab:CreateLabel("Progress: Calculating...")

        local function idxUpdateProgressLabels()
            idxUpdateCategoryCounts()
            local totalBasic = #_0x6f3a2c.getSortedSlimes()
            local progressText = string.format("Basic: %d/%d", idxCategoryCounts.Basic, totalBasic)
            for cat, count in pairs(idxCategoryCounts) do
                if cat ~= "Basic" then
                    progressText = progressText .. string.format("  |  %s: %d/%d", cat, count, totalBasic)
                end
            end
            idxProgressLabel:Set(progressText)
        end

        local idxSelectedCategory = "All (Recommended)"
        local idxCurrentMissing = idxGetMissingList(idxSelectedCategory)
        local idxCurrentTarget = idxGetRarestMissing(idxCurrentMissing)

        _0x3e2c7a_tab:CreateDropdown({
            Name = "Category",
            Options = idxCategoriesList,
            CurrentOption = { idxSelectedCategory },
            MultipleOptions = false,
            Flag = "IndexCategory",
            Callback = function(opt)
                idxSelectedCategory = opt[1]
                idxCurrentMissing = idxGetMissingList(idxSelectedCategory)
                idxCurrentTarget = idxGetRarestMissing(idxCurrentMissing)
                if idxCurrentTarget then
                    idxTargetLabel:Set("Target: " .. idxCurrentTarget.id .. " (" .. idxCurrentTarget.category .. ")")
                    local oddsFormatted = idxCurrentTarget.odds > 0 and ("1 in " .. _0x6c2f8a(idxCurrentTarget.odds)) or "Unknown"
                    idxOddsLabel:Set("Odds: " .. oddsFormatted)
                else
                    idxTargetLabel:Set("Target: None (complete!)")
                    idxOddsLabel:Set("Odds: N/A")
                end
            end,
        })

        _0x3e2c7a_tab:CreateDropdown({
            Name = "Strategy",
            Options = { "Easiest First", "Rarest First" },
            CurrentOption = { "Rarest First" },
            MultipleOptions = false,
            Flag = "IndexStrategy",
            Callback = function() end,
        })

        local autoIndexThread = nil
        _0x3e2c7a_tab:CreateToggle({
            Name = "Start Auto Complete Index",
            CurrentValue = false,
            Flag = "AutoIndexToggle",
            Callback = function(enabled)
                if autoIndexThread then task.cancel(autoIndexThread) end
                if not enabled then return end
                autoIndexThread = task.spawn(function()
                    while _0x2c5d8f.Flags.AutoIndexToggle.CurrentValue do
                        idxUpdateProgressLabels()
                        local strategy = _0x2c5d8f.Flags.IndexStrategy.CurrentOption[1] or "Rarest First"
                        local missing = idxGetMissingList(idxSelectedCategory)
                        if #missing == 0 then
                            _0x2c5d8f:Notify({
                                Title = "Index Completion",
                                Content = "No missing slimes in selected category!",
                                Duration = 3,
                                Image = 4483362458,
                            })
                            break
                        end
                        local target = nil
                        if strategy == "Easiest First" then
                            table.sort(missing, function(a,b) return a.odds < b.odds end)
                            target = missing[1]
                        else
                            target = idxGetRarestMissing(missing)
                        end
                        if target then
                            idxTargetLabel:Set("Target: " .. target.id .. " (" .. target.category .. ")")
                            local oddsFormatted = target.odds > 0 and ("1 in " .. _0x6c2f8a(target.odds)) or "Unknown"
                            idxOddsLabel:Set("Odds: " .. oddsFormatted)
                        end
                        _0x7e2a4c:InvokeServer("requestRoll")
                        task.wait(_0x8d1f4a.rollTime() + 0.25)
                        indexData = _0x7b3f5a:get("index") or {}
                        idxUpdateCategoryCounts()
                        idxCurrentMissing = idxGetMissingList(idxSelectedCategory)
                    end
                end)
            end,
        })

        idxUpdateProgressLabels()
        if idxCurrentTarget then
            idxTargetLabel:Set("Target: " .. idxCurrentTarget.id .. " (" .. idxCurrentTarget.category .. ")")
            local oddsFormatted = idxCurrentTarget.odds > 0 and ("1 in " .. _0x6c2f8a(idxCurrentTarget.odds)) or "Unknown"
            idxOddsLabel:Set("Odds: " .. oddsFormatted)
        end
        -- ==================== END INDEX AUTO COMPLETE ====================

        -- ==================== MOVE TO ENEMY (AUTO FARM) ====================
        _0x3e2c7a_tab:CreateSection("Move to Enemy")

        local farmSettings = {
            TeleportStyle = "Teleport",
            TargetPriorities = { ["Most Coins & Goop"] = true },
            AutoFarm = false,
            MutationFilter = "Any",
        }
        local FARM_RANGE = 50
        local farmCache = {}
        local farmLastCache = 0
        local farmCurrentTarget = nil
        local farmTweenConn = nil

        local function getGameplayContainer()
            for _, child in ipairs(workspace:GetChildren()) do
                if child.Name:match("^Gameplay") then
                    return child
                end
            end
            return nil
        end

        local function getEnemyRoot(enemy)
            return enemy:FindFirstChild("HumanoidRootPart") or enemy.PrimaryPart or enemy:FindFirstChildWhichIsA("BasePart")
        end

        local function getEnemyMutation(enemy)
            for _, mut in ipairs({"inverted", "huge", "shiny", "big"}) do
                local ok, val = pcall(function() return enemy:GetAttribute(mut) end)
                if ok and val then return mut end
                if enemy:FindFirstChild(mut) then return mut end
                local m = enemy:FindFirstChild("Mutation")
                if m and m.Value == mut then return mut end
                if enemy.Name:lower():find(mut) then return mut end
            end
            return nil
        end

        local function getEnemyValue(enemy, rootPart)
            local coins = enemy:GetAttribute("reward") or enemy:GetAttribute("coins") or enemy:GetAttribute("coinReward")
            local goop = enemy:GetAttribute("goop") or enemy:GetAttribute("goopReward")
            local health = enemy:GetAttribute("health") or enemy:GetAttribute("maxHealth")
            local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
            if humanoid then health = health or humanoid.MaxHealth end
            local valueObj = enemy:FindFirstChild("Reward") or enemy:FindFirstChild("Coins") or enemy:FindFirstChild("Value")
            if valueObj and valueObj:IsA("NumberValue") then coins = coins or valueObj.Value end
            local goopObj = enemy:FindFirstChild("Goop") or enemy:FindFirstChild("GoopReward")
            if goopObj and goopObj:IsA("NumberValue") then goop = goop or goopObj.Value end
            local healthObj = enemy:FindFirstChild("Health") or enemy:FindFirstChild("MaxHealth")
            if healthObj and healthObj:IsA("NumberValue") then health = health or healthObj.Value end
            local dist = math.huge
            local char = _0x9a4b7c.Character
            if char and rootPart then
                local rp = char:FindFirstChild("HumanoidRootPart")
                if rp then dist = (rootPart.Position - rp.Position).Magnitude end
            end
            return {
                coins = coins or 0,
                goop = goop or 0,
                health = health or 0,
                mutation = getEnemyMutation(enemy),
                distance = dist,
            }
        end

        local function isEnemyAlive(enemy)
            if not enemy or not enemy.Parent then return false end
            local humanoid = enemy:FindFirstChildWhichIsA("Humanoid")
            if humanoid and humanoid.Health <= 0 then return false end
            local hp = enemy:GetAttribute("health") or enemy:GetAttribute("currentHealth")
            if hp and hp <= 0 then return false end
            return true
        end

        local function refreshEnemyCache()
            if tick() - farmLastCache < 2 then return end
            farmLastCache = tick()
            farmCache = {}
            local container = getGameplayContainer()
            if not container then return end
            local enemyFolder = container:FindFirstChild("Enemies")
            if not enemyFolder then return end
            for _, enemy in ipairs(enemyFolder:GetChildren()) do
                if enemy:IsA("Model") then
                    table.insert(farmCache, enemy)
                end
            end
        end

        local function matchesMutationFilter(enemy)
            if farmSettings.MutationFilter == "Any" then return true end
            return getEnemyMutation(enemy) == farmSettings.MutationFilter:lower()
        end

        local function computeScores()
            local char = _0x9a4b7c.Character
            if not char then return {} end
            local rp = char:FindFirstChild("HumanoidRootPart")
            if not rp then return {} end
            local entries = {}
            for _, enemy in ipairs(farmCache) do
                if not isEnemyAlive(enemy) then continue end
                if not matchesMutationFilter(enemy) then continue end
                local root = getEnemyRoot(enemy)
                if not root then continue end
                local dist = (root.Position - rp.Position).Magnitude
                if dist > FARM_RANGE then continue end
                local data = getEnemyValue(enemy, root)
                table.insert(entries, { enemy = enemy, data = data })
            end
            if #entries == 0 then return {} end
            local maxCoins, maxGoop, maxHealth, maxDist = 0, 0, 0, 0
            for _, e in ipairs(entries) do
                if e.data.coins > maxCoins then maxCoins = e.data.coins end
                if e.data.goop > maxGoop then maxGoop = e.data.goop end
                if e.data.health > maxHealth then maxHealth = e.data.health end
                if e.data.distance > maxDist then maxDist = e.data.distance end
            end
            local scores = {}
            local priorities = farmSettings.TargetPriorities
            for _, e in ipairs(entries) do
                local s = 0
                if priorities["Most Coins & Goop"] then
                    local coinsNorm = maxCoins > 0 and e.data.coins / maxCoins or 0
                    local goopNorm = maxGoop > 0 and e.data.goop / maxGoop or 0
                    s = s + (coinsNorm + goopNorm) / 2
                end
                if priorities["Closest"] then s = s + (maxDist > 0 and 1 - e.data.distance / maxDist or 0) end
                if priorities["Lowest HP"] then s = s + (maxHealth > 0 and 1 - e.data.health / maxHealth or 0) end
                if priorities["Mutations Only"] then s = s + (e.data.mutation and 1 or 0) end
                scores[e.enemy] = s
            end
            return scores
        end

        local function selectTarget()
            local scores = computeScores()
            local best, bestScore = nil, -math.huge
            for enemy, score in pairs(scores) do
                if score > bestScore then
                    bestScore = score
                    best = enemy
                end
            end
            return best
        end

        local function moveToEnemy(enemy)
            local char = _0x9a4b7c.Character
            if not char then return end
            local root = getEnemyRoot(enemy)
            if not root then return end
            local target = root.CFrame * CFrame.new(0, 3, 0)
            if farmSettings.TeleportStyle == "Teleport" then
                char:PivotTo(target)
            elseif farmSettings.TeleportStyle == "Tween" then
                if farmTweenConn then farmTweenConn:Disconnect() farmTweenConn = nil end
                local start = char:GetPivot()
                local startTime = tick()
                local duration = 0.25
                farmTweenConn = _0x1e5f3d.RenderStepped:Connect(function()
                    local alpha = math.clamp((tick() - startTime) / duration, 0, 1)
                    char:PivotTo(start:Lerp(target, alpha))
                    if alpha >= 1 then farmTweenConn:Disconnect() farmTweenConn = nil end
                end)
            end
        end

        _0x1e5f3d.Heartbeat:Connect(function()
            refreshEnemyCache()
            if not farmSettings.AutoFarm then
                farmCurrentTarget = nil
                return
            end
            if farmCurrentTarget and isEnemyAlive(farmCurrentTarget) and farmCurrentTarget.Parent then
                return
            end
            local newTarget = selectTarget()
            if newTarget and newTarget ~= farmCurrentTarget then
                farmCurrentTarget = newTarget
                moveToEnemy(farmCurrentTarget)
            end
        end)

        _0x3e2c7a_tab:CreateDropdown({
            Name = "Teleport Style",
            Options = {"Teleport", "Tween"},
            CurrentOption = {"Teleport"},
            MultipleOptions = false,
            Flag = "FarmTeleportStyle",
            Callback = function(option) farmSettings.TeleportStyle = option[1] end,
        })

        _0x3e2c7a_tab:CreateDropdown({
            Name = "Target Priority",
            Options = {"Most Coins & Goop", "Closest", "Lowest HP", "Mutations Only"},
            CurrentOption = {"Most Coins & Goop"},
            MultipleOptions = true,
            Flag = "FarmTargetPriority",
            Callback = function(options)
                farmSettings.TargetPriorities = {}
                for _, opt in ipairs(options) do
                    farmSettings.TargetPriorities[opt] = true
                end
            end,
        })

        _0x3e2c7a_tab:CreateDropdown({
            Name = "Mutation Filter",
            Options = {"Any", "Inverted", "Huge", "Shiny", "Big"},
            CurrentOption = {"Any"},
            MultipleOptions = true,
            Flag = "FarmMutationFilter",
            Callback = function(option) farmSettings.MutationFilter = option[1] end,
        })

        _0x3e2c7a_tab:CreateToggle({
            Name = "Auto Farm",
            CurrentValue = false,
            Flag = "AutoFarmToggle",
            Callback = function(value)
                farmSettings.AutoFarm = value
                if not value then farmCurrentTarget = nil end
            end,
        })
        -- ==================== END MOVE TO ENEMY ====================

        local _0x4c2e7a_tab = _0x4f2a8c_window:CreateTab("Misc", 96334002390551)

        _0x4c2e7a_tab:CreateSection("Codes & Rewards")

        _0x4c2e7a_tab:CreateToggle({
            Name = "Auto Redeem Codes",
            CurrentValue = false,
            Flag = "MiscRedeemCodes",
            Callback = function(_0x3e7a2c)
                if _0x3e7a2c then
                    task.spawn(function()
                        local _0x1c4a7d = {
                            "gullible",
                            "test",
                            "goingBananas",
                            "AAisComing",
                            "Sliming",
                        }
                        while _0x2c5d8f.Flags.MiscRedeemCodes and _0x2c5d8f.Flags.MiscRedeemCodes.CurrentValue do
                            for _, _0x2a7b4c in ipairs(_0x1c4a7d) do
                                _0x1b6d8f:InvokeServer("redeem", _0x2a7b4c)
                                task.wait(0.5)
                            end
                            task.wait(300)
                        end
                    end)
                end
            end,
        })

        _0x4c2e7a_tab:CreateToggle({
            Name = "Auto Claim Offline Earnings",
            CurrentValue = false,
            Flag = "MiscClaimOffline",
            Callback = function(_0x2d4c7e)
                if _0x2d4c7e then
                    task.spawn(function()
                        while _0x2c5d8f.Flags.MiscClaimOffline and _0x2c5d8f.Flags.MiscClaimOffline.CurrentValue do
                            _0x3e7a2c_remote:InvokeServer("requestClaim")
                            task.wait(60)
                        end
                    end)
                end
            end,
        })

        _0x4c2e7a_tab:CreateToggle({
            Name = "Auto Claim Index Rewards",
            CurrentValue = false,
            Flag = "MiscClaimIndex",
            Callback = function(_0x8c3a2e)
                if _0x8c3a2e then
                    task.spawn(function()
                        local function _0x3c2e7a()
                            local _0x1a4b7c = _0x7b3f5a:get("index")
                            if not _0x1a4b7c or not _0x1a4b7c.categories then return end
                            for _0x5c3e2a, _0x7c3f2a in pairs(_0x3e6a1d) do
                                local _0x3f6a2c = _0x1a4b7c.categories[_0x5c3e2a]
                                if _0x3f6a2c then
                                    local _0x9b2c4e = _0x3f6a2c.unlocked or {}
                                    local _0x2e7a4c = 0
                                    for _, _0x4d8f2a in pairs(_0x9b2c4e) do
                                        if _0x4d8f2a == true then _0x2e7a4c = _0x2e7a4c + 1 end
                                    end
                                    local _0x1c3d6a = _0x3f6a2c.claimedRewards or {}
                                    for _, _0x5a8f2c in ipairs(_0x7c3f2a) do
                                        if _0x2e7a4c >= _0x5a8f2c.req and not _0x1c3d6a[_0x5a8f2c.key] then
                                            _0x6f1a8d:InvokeServer("requestClaimReward", _0x5c3e2a)
                                            task.wait(0.5)
                                        end
                                    end
                                end
                            end
                        end
                        while _0x2c5d8f.Flags.MiscClaimIndex and _0x2c5d8f.Flags.MiscClaimIndex.CurrentValue do
                            _0x3c2e7a()
                            task.wait(60)
                        end
                    end)
                end
            end,
        })

        _0x4c2e7a_tab:CreateSection("Consumables")

        _0x4c2e7a_tab:CreateToggle({
            Name = "Auto Use Potions",
            CurrentValue = false,
            Flag = "MiscUsePotions",
            Callback = function(_0x2b4c7a)
                if _0x2b4c7a then
                    task.spawn(function()
                        while task.wait(1) and _0x2c5d8f.Flags.MiscUsePotions and _0x2c5d8f.Flags.MiscUsePotions.CurrentValue do
                            local _0x1f4a7c   = _0x7b3f5a:get("boosts") or {}
                            local _0x4c2d7e = _0x2c5d8f.Flags.MiscPotionTypes and _0x2c5d8f.Flags.MiscPotionTypes.CurrentOption or {}
                            for _, _0x2c4f8a in ipairs(_0x4c2d7e) do
                                local _0x1a4b7c = _0x1f4a7c[_0x2c4f8a]
                                if _0x1a4b7c and (_0x1a4b7c.amount or 0) > 0 then
                                    _0x8b1d4f:InvokeServer("requestUseBoost", _0x2c4f8a)
                                end
                            end
                        end
                    end)
                end
            end,
        })

        _0x4c2e7a_tab:CreateDropdown({
            Name = "Potion Types",
            Options = _0x4a8d2f,
            CurrentOption = {_0x4a8d2f[1]},
            MultipleOptions = true,
            Flag = "MiscPotionTypes",
            Callback = function(_0x3c2f7a) end,
        })

        _0x4c2e7a_tab:CreateToggle({
            Name = "Auto Use Dice & Items",
            CurrentValue = false,
            Flag = "MiscUseDice",
            Callback = function(_0x3e7a2c)
                if _0x3e7a2c then
                    task.spawn(function()
                        while task.wait(1) and _0x2c5d8f.Flags.MiscUseDice and _0x2c5d8f.Flags.MiscUseDice.CurrentValue do
                            local _0x1c4d7a    = _0x7b3f5a:get("items") or {}
                            local _0x5c2f7a = _0x2c5d8f.Flags.MiscDiceTypes and _0x2c5d8f.Flags.MiscDiceTypes.CurrentOption or {}
                            for _, _0x2f4a7c in ipairs(_0x5c2f7a) do
                                local _0x1b4c6a = _0x9d4c1e[_0x2f4a7c]
                                if _0x1b4c6a and (_0x1c4d7a[_0x1b4c6a] or 0) > 0 then
                                    _0x9c3a2e:InvokeServer("requestUseItem", _0x1b4c6a)
                                end
                            end
                        end
                    end)
                end
            end,
        })

        do
            local _0x7a3c2e = {}
            for _, _0x1f4c8a in ipairs(_0x7c2e5a) do
                table.insert(_0x7a3c2e, _0x3f8a2b[_0x1f4c8a])
            end
            _0x4c2e7a_tab:CreateDropdown({
                Name = "Dice & Item Types",
                Options = _0x7a3c2e,
                CurrentOption = {_0x7a3c2e[1]},
                MultipleOptions = true,
                Flag = "MiscDiceTypes",
                Callback = function(_0x1a6c4d) end,
            })
        end

        local _0x2a7b4c_tab = _0x4f2a8c_window:CreateTab("Webhook", 84577758013974)

        _0x2a7b4c_tab:CreateSection("Warning")

        _0x2a7b4c_tab:CreateParagraph({
            Title = "⚠️ WARNING",
            Content = "WEBHOOK WILL ONLY WORK IF YOU MANUALLY ENABLE AUTO ROLL IN GAME\nPLEASE DISABLE FAST ROLL (from Farming Tab) if you have it enabled"
        })

        _0x2a7b4c_tab:CreateSection("Configuration")

        _0x2a7b4c_tab:CreateToggle({
            Name = "Enable Webhook",
            CurrentValue = false,
            Flag = "WebhookEnabled",
            Callback = function(_0x2b4c7a) end,
        })

        local _0x1d3f6a = ""
        _0x2a7b4c_tab:CreateInput({
            Name = "Webhook URL",
            CurrentValue = "",
            PlaceholderText = "Paste your Discord webhook URL",
            RemoveTextAfterFocusLost = false,
            Flag = "WebhookURLDisplay",
            Callback = function(_0x3f6a2c)
                if _0x3f6a2c and _0x3f6a2c:match("^https://discord") then
                    _0x1d3f6a = _0x3f6a2c
                    local _0x2a7c4e = string.rep("•", #_0x3f6a2c - 6) .. _0x3f6a2c:sub(-6)
                    _0x2c5d8f:Notify({Title = "Webhook", Content = "URL saved: " .. _0x2a7c4e, Duration = 3})
                end
            end,
        })

        _0x2a7b4c_tab:CreateInput({
            Name = "User ID",
            CurrentValue = "",
            PlaceholderText = "Discord User ID",
            RemoveTextAfterFocusLost = false,
            Flag = "WebhookUserID",
            Callback = function(_0x1d4f8a) end,
        })

        _0x2a7b4c_tab:CreateInput({
            Name = "Minimum Chance To Send",
            CurrentValue = "",
            PlaceholderText = "e.g. 1B or 1000000000",
            RemoveTextAfterFocusLost = false,
            Flag = "WebhookMinChance",
            Callback = function(_0x3c2e7a) end,
        })

        _0x2a7b4c_tab:CreateButton({
            Name = "Test Webhook",
            Callback = function()
                if _0x1d3f6a == "" then
                    _0x2c5d8f:Notify({Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4})
                    return
                end
                if not _0x2c5d8f.Flags.WebhookEnabled.CurrentValue then
                    _0x2c5d8f:Notify({Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4})
                    return
                end
                local _0x2c6e4a  = _0x2c5d8f.Flags.WebhookUserID.CurrentValue
                local _0x4d7c2a = _0x2f6a1c(_0x2c6e4a)
                local _0x1a6b4c = request({
                    Url = _0x1d3f6a,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = _0x2b6f8e:JSONEncode({
                        content  = _0x4d7c2a,
                        username = "Cactus Hub",
                        avatar_url = WEBHOOK_AVATAR,
                        embeds   = {{
                            title       = "✅ Webhook Test",
                            description = "Your webhook is working correctly!",
                            color       = 0x2ecc71,
                        }}
                    })
                })
                if not _0x1a6b4c then
                    _0x2c5d8f:Notify({
                        Title   = "Webhook",
                        Content = "Failed to send test.",
                        Duration = 4,
                    })
                else
                    _0x2c5d8f:Notify({
                        Title   = "Webhook",
                        Content = "Test sent successfully!",
                        Duration = 4,
                    })
                end
            end,
        })

        _0x2a7b4c_tab:CreateSection("Filters")

        _0x2a7b4c_tab:CreateToggle({
            Name = "Send All Slimes",
            CurrentValue = false,
            Flag = "WebhookSendAll",
            Callback = function(_0x2c4a7d) end,
        })

        _0x2a7b4c_tab:CreateToggle({
            Name = "Send New Slimes Only",
            CurrentValue = false,
            Flag = "WebhookSendNew",
            Callback = function(_0x4b2c7a) end,
        })

        _0x2a7b4c_tab:CreateToggle({
            Name = "Send Mutated Slimes",
            CurrentValue = false,
            Flag = "WebhookSendMutated",
            Callback = function(_0x3f6a2c) end,
        })

        _0x2a7b4c_tab:CreateDropdown({
            Name = "Mutations Filter",
            Options = {"All", "Shiny", "Big", "Huge", "Inverted"},
            CurrentOption = {"All"},
            MultipleOptions = true,
            Flag = "WebhookMutations",
            Callback = function(_0x1c7d3e) end,
        })

        local _0x7b2c4f = nil

        local function _0x4f2a8c_filter(_0x3c6a2d)
            local _0x5d2f8a = _0x2c5d8f.Flags.WebhookMutations and _0x2c5d8f.Flags.WebhookMutations.CurrentOption or {"All"}
            local _0x1c7e4a = false
            for _, _0x3e4c2a in ipairs(_0x5d2f8a) do
                if _0x3e4c2a == "All" then
                    _0x1c7e4a = true
                    break
                end
            end
            if _0x1c7e4a then return true end
            if not _0x3c6a2d then return false end
            local _0x1d4f8a = _0x8c3d2a(_0x3c6a2d)
            for _, _0x3a8f2c in ipairs(_0x5d2f8a) do
                if string.lower(_0x3a8f2c) == _0x1d4f8a then return true end
            end
            return false
        end

        task.spawn(function()
            while true do
                task.wait(0.1)

                if not _0x2c5d8f.Flags.WebhookEnabled or not _0x2c5d8f.Flags.WebhookEnabled.CurrentValue then

                elseif _0x1d3f6a ~= "" then
                    if not _0x8d1f4a or type(_0x8d1f4a.rollResults) ~= "function" then
                        task.wait(1)
                    else
                        local _0x2c6d8a = _0x8d1f4a.rollResults()
                        if type(_0x2c6d8a) ~= "table" or #_0x2c6d8a == 0 then
                            task.wait(0.5)
                        else
                            local _0x1a6d4f = _0x9b2c4e(_0x2c6d8a)
                            if _0x1a6d4f ~= _0x7b2c4f then
                                _0x7b2c4f = _0x1a6d4f

                                local _0x7e2a4c = _0x2c5d8f.Flags.WebhookSendAll and _0x2c5d8f.Flags.WebhookSendAll.CurrentValue
                                local _0x1f4a3c = _0x2c5d8f.Flags.WebhookSendNew and _0x2c5d8f.Flags.WebhookSendNew.CurrentValue
                                local _0x3c8a2d = _0x2c5d8f.Flags.WebhookSendMutated and _0x2c5d8f.Flags.WebhookSendMutated.CurrentValue
                                local minChanceStr = _0x2c5d8f.Flags.WebhookMinChance.CurrentValue
                                local minChanceNum = parseChanceString(minChanceStr)

                                for _, _0x3f8c2a in ipairs(_0x2c6d8a) do
                                    local _0x2c4e7a = _0x7c5f2a(_0x3f8c2a)
                                    if _0x2c4e7a then
                                        local _0x1d4c8f = tostring(_0x2c4e7a.id or "")
                                        if _0x1d4c8f ~= "" then
                                            local _0x4d2c8f = type(_0x2c4e7a.mutations) == "table" and next(_0x2c4e7a.mutations) ~= nil and _0x2c4e7a.mutations or nil
                                            local slimeOk, slimeData = pcall(_0x6f3a2c.getSlime, _0x1d4c8f)
                                            local _0x1d8f2a = slimeOk and slimeData or nil

                                            local _0x1b4c7d = _0x4d2c8f ~= nil
                                            local _0x7c3d2a = _0x1a7c4f(_0x1d4c8f, _0x4d2c8f)

                                            local _0x3e2c7a = _0x7e2a4c or (_0x1f4a3c and _0x7c3d2a) or (_0x3c8a2d and _0x1b4c7d and _0x4f2a8c_filter(_0x4d2c8f))

                                            if _0x3e2c7a and minChanceNum then
                                                local odds = _0x1d8f2a and _0x1d8f2a.odds or 0
                                                local chanceValue = odds > 0 and (1 / odds) or 0
                                                if chanceValue > minChanceNum then
                                                    _0x3e2c7a = false
                                                end
                                            end

                                            if _0x3e2c7a then
                                                local _0x2a6d4c = _0x2c5d8f.Flags.WebhookUserID.CurrentValue
                                                local _0x1c6d4f = _0x1a6d4f .. "_" .. _0x1d4c8f .. "_" .. tostring(_0x4d2c8f and _0x1b7e4d.getIds(_0x4d2c8f) or "")
                                                task.spawn(_0x4c7e2a, _0x1d4c8f, _0x1d8f2a, _0x4d2c8f, _0x1d3f6a, _0x2a6d4c, _0x1c6d4f)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)

        local _0x7d2c4a_tab = _0x4f2a8c_window:CreateTab("Settings", 122930981612451)

        _0x7d2c4a_tab:CreateSection("System")

        _0x7d2c4a_tab:CreateToggle({
            Name = "Anti Kick",
            CurrentValue = false,
            Flag = "SettingsAntiKick",
            Callback = function(_0x8c3a2e) end,
        })

        _0x7d2c4a_tab:CreateToggle({
            Name = "Auto Rejoin On Disconnect",
            CurrentValue = false,
            Flag = "SettingsAutoRejoin",
            Callback = function(_0x2d7c4a) end,
        })

        _0x7d2c4a_tab:CreateToggle({
            Name = "Auto Friend Requests",
            CurrentValue = false,
            Flag = "AutoFriend",
            Callback = function(value)
                if value then
                    task.spawn(function()
                        while _0x2c5d8f.Flags.AutoFriend and _0x2c5d8f.Flags.AutoFriend.CurrentValue do
                            local players = game:GetService("Players"):GetChildren()
                            for _, p in ipairs(players) do
                                _0x9a4b7c:RequestFriendship(p)
                                task.wait(1)
                            end
                            task.wait(600)
                        end
                    end)
                end
            end,
        })
        _0x7d2c4a_tab:CreateLabel("( I'm not sure if it works )")

        _0x7d2c4a_tab:CreateSection("Advanced Optimization")

        local _optConnections = {}
        local _optApplied = false

        local CHEAP_MATERIAL = Enum.Material.SmoothPlastic
        local OPT_VISUAL_TYPES = {
            ParticleEmitter=true, Trail=true, Beam=true, Fire=true,
            Smoke=true, Sparkles=true, SurfaceAppearance=true,
            Highlight=true, SelectionBox=true, SelectionSphere=true, Atmosphere=true,
        }
        local OPT_LIGHTING_TYPES = {
            BloomEffect=true, BlurEffect=true, ColorCorrectionEffect=true,
            DepthOfFieldEffect=true, SunRaysEffect=true, PixelateEffect=true,
            FilmGrainEffect=true, Atmosphere=true, Sky=true,
        }

        local function _optSafeDestroy(obj)
            if obj and obj.Parent then obj:Destroy() end
        end

        local function _optTryHidden(obj, prop, val)
            if sethiddenproperty then sethiddenproperty(obj, prop, val) end
        end

        local function _optApplyInstance(v)
            local cn = v.ClassName
            if OPT_VISUAL_TYPES[cn] then _optSafeDestroy(v) return end
            if cn == "Decal" or cn == "Texture" then v.Transparency = 1 return end
            if cn == "SpecialMesh" then v.TextureId = "" return end
            if cn == "PointLight" or cn == "SpotLight" or cn == "SurfaceLight" then v.Enabled = false return end
            if v:IsA("BasePart") then
                v.CastShadow = false
                v.Reflectance = 0
                v.Material = CHEAP_MATERIAL
                if not v:IsA("TriangleMeshPart") then
                    _optTryHidden(v, "RenderFidelity", 2)
                end
            end
        end

        local function _optLighting()
            local L = game:GetService("Lighting")
            L.GlobalShadows = false
            L.FogEnd = 100000
            L.FogStart = 100000
            L.Brightness = 1
            L.Ambient = Color3.fromRGB(180, 180, 180)
            L.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
            L.ShadowSoftness = 0
            L.EnvironmentDiffuseScale = 0
            L.EnvironmentSpecularScale = 0
            _optTryHidden(L, "Technology", 0)
            for _, c in ipairs(L:GetChildren()) do
                if OPT_LIGHTING_TYPES[c.ClassName] then c:Destroy() end
            end
            local terrain = workspace:FindFirstChildOfClass("Terrain")
            if terrain then
                local clouds = terrain:FindFirstChildOfClass("Clouds")
                if clouds then clouds:Destroy() end
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end
            table.insert(_optConnections, L.ChildAdded:Connect(function(child)
                if OPT_LIGHTING_TYPES[child.ClassName] then
                    task.defer(child.Destroy, child)
                end
            end))
        end

        local function _optCharacter(character)
            if not character then return end
            local hum = character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
                hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
                hum.NameDisplayDistance = 0
                hum.HealthDisplayDistance = 0
            end
            for _, v in ipairs(character:GetDescendants()) do
                local cn = v.ClassName
                if OPT_VISUAL_TYPES[cn] then
                    v:Destroy()
                elseif v:IsA("BasePart") then
                    v.CastShadow = false
                    v.Reflectance = 0
                    v.Material = CHEAP_MATERIAL
                elseif cn == "Decal" or cn == "Texture" then
                    v.Transparency = 1
                elseif cn == "SpecialMesh" then
                    v.TextureId = ""
                elseif cn == "Accessory" then
                    v:Destroy()
                end
            end
        end

        local function _optWorkspaceScan()
            local Camera = workspace.CurrentCamera
            local charSet = {}
            for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
                if p.Character then charSet[p.Character] = true end
            end
            for _, obj in ipairs(workspace:GetChildren()) do
                if obj ~= Camera and not charSet[obj] then
                    for _, v in ipairs(obj:GetDescendants()) do
                        _optApplyInstance(v)
                    end
                end
            end
            table.insert(_optConnections, workspace.ChildAdded:Connect(function(obj)
                if obj == workspace.CurrentCamera then return end
                task.defer(function()
                    for _, v in ipairs(obj:GetDescendants()) do
                        _optApplyInstance(v)
                    end
                end)
            end))
        end

        local function _optPlayers()
            local Players = game:GetService("Players")
            for _, p in ipairs(Players:GetPlayers()) do
                if p.Character then _optCharacter(p.Character) end
                table.insert(_optConnections, p.CharacterAdded:Connect(function(char)
                    task.defer(_optCharacter, char)
                end))
            end
            table.insert(_optConnections, Players.PlayerAdded:Connect(function(p)
                table.insert(_optConnections, p.CharacterAdded:Connect(function(char)
                    task.defer(_optCharacter, char)
                end))
            end))
        end

        local function _optCamera()
            local cam = workspace.CurrentCamera
            if not cam then return end
            cam.FieldOfView = 70
            for _, v in ipairs(cam:GetChildren()) do
                if OPT_LIGHTING_TYPES[v.ClassName] then v:Destroy() end
            end
        end

        local function _optGUI()
            local sg = game:GetService("StarterGui")
            sg:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
            sg:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
            sg:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
        end

        local function _optRenderQuality()
            settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel01
            local rs = game:GetService("RunService")
            rs:Set3dRenderingEnabled(false)
            task.wait(0.1)
            rs:Set3dRenderingEnabled(true)
        end

        local function _cleanOptConnections()
            for _, c in ipairs(_optConnections) do c:Disconnect() end
            table.clear(_optConnections)
        end

        local optGPUToggle
        local optParticlesToggle
        local optFireToggle
        local optGCToggle
        local optIntenseToggle
        local optHideDamageToggle
        local optMainToggle
        local updatingOptimizations = false

        local function setAllOptimizations(value)
            if optGPUToggle then optGPUToggle:Set(value) end
            if optParticlesToggle then optParticlesToggle:Set(value) end
            if optFireToggle then optFireToggle:Set(value) end
            if optGCToggle then optGCToggle:Set(value) end
            if optIntenseToggle then optIntenseToggle:Set(value) end
            if optHideDamageToggle then optHideDamageToggle:Set(value) end
        end

        optMainToggle = _0x7d2c4a_tab:CreateToggle({
            Name = "Optimize All",
            CurrentValue = false,
            Flag = "OptimizeAll",
            Callback = function(Value)
                if updatingOptimizations then return end
                setAllOptimizations(Value)
            end,
        })

        optGPUToggle = _0x7d2c4a_tab:CreateToggle({
            Name = "Optimize GPU (Low Graphics)",
            CurrentValue = false,
            Flag = "OptimizeGPU",
            Callback = function(Value)
                if updatingOptimizations then return end
                if Value then
                    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
                    local L = game:GetService("Lighting")
                    L.GlobalShadows = false
                    L.EnvironmentDiffuseScale = 0
                    L.EnvironmentSpecularScale = 0
                    for _, v in ipairs(workspace:GetDescendants()) do
                        if v:IsA("BasePart") then
                            v.CastShadow = false
                            v.Reflectance = 0
                            v.Material = CHEAP_MATERIAL
                        end
                    end
                    local rs = game:GetService("RunService")
                    rs:Set3dRenderingEnabled(false)
                    task.wait(0.1)
                    rs:Set3dRenderingEnabled(true)
                end
            end,
        })

        optParticlesToggle = _0x7d2c4a_tab:CreateToggle({
            Name = "Remove All Particles & Effects",
            CurrentValue = false,
            Flag = "OptimizeParticles",
            Callback = function(Value)
                if updatingOptimizations then return end
                if Value then
                    for _, v in ipairs(game:GetDescendants()) do
                        if OPT_VISUAL_TYPES[v.ClassName] then
                            v:Destroy()
                        end
                    end
                end
            end,
        })

        optFireToggle = _0x7d2c4a_tab:CreateToggle({
            Name = "Remove Fire Effects",
            CurrentValue = false,
            Flag = "FireOptimization",
            Callback = function(Value)
                if updatingOptimizations then return end
                if Value then
                    for _, v in ipairs(game:GetDescendants()) do
                        if v:IsA("Fire") then v:Destroy() end
                    end
                end
            end,
        })

        optGCToggle = _0x7d2c4a_tab:CreateToggle({
            Name = "Lua GC (Memory Cleaner)",
            CurrentValue = false,
            Flag = "LuaGC",
            Callback = function(Value)
                if updatingOptimizations then return end
                if Value then
                    if _G.__memoryCleaner then
                        _G.__memoryCleaner:Disconnect()
                    end
                    _G.__memoryCleaner = game:GetService("RunService").Heartbeat:Connect(function()
                        gcinfo()
                    end)
                else
                    if _G.__memoryCleaner then
                        _G.__memoryCleaner:Disconnect()
                        _G.__memoryCleaner = nil
                    end
                end
            end,
        })

        optIntenseToggle = _0x7d2c4a_tab:CreateToggle({
            Name = "Intense Optimization",
            CurrentValue = false,
            Flag = "IntenseOptimization",
            Callback = function(Value)
                if updatingOptimizations then return end
                if Value then
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))()
                end
            end,
        })

        optHideDamageToggle = _0x7d2c4a_tab:CreateToggle({
            Name = "Hide Damage UI",
            CurrentValue = false,
            Flag = "HideDamageUI",
            Callback = function(Value)
                if updatingOptimizations then return end
                local container = getDamageUIParent()
                if container then
                    container.Visible = not Value
                else
                    task.spawn(function()
                        while not getDamageUIParent() and task.wait(0.5) do end
                        local cont = getDamageUIParent()
                        if cont then cont.Visible = not Value end
                    end)
                end
            end,
        })

        local statsTab = _0x4f2a8c_window:CreateTab("Stats", 4483362458)

        local DataClient = _0x7b3f5a
        local function safeGet(...)
            local data = DataClient._data._data
            local cur = data
            for _, k in ipairs({...}) do
                if type(cur) ~= "table" then return 0 end
                cur = cur[k]
                if cur == nil then return 0 end
            end
            return cur
        end

        local function safeNum(...)
            return tonumber(safeGet(...)) or 0
        end

        local SUFFIXES = {
            {1e24,"Sp"},{1e21,"Sx"},{1e18,"Qn"},{1e15,"Qd"},
            {1e12,"T"},{1e9,"B"},{1e6,"M"},{1e3,"K"},
        }

        local function fmt(n)
            n = tonumber(n) or 0
            for _, p in ipairs(SUFFIXES) do
                if n >= p[1] then
                    local s = string.format("%.2f", n / p[1]):gsub("%.?0+$","")
                    return s .. p[2]
                end
            end
            return tostring(math.floor(n))
        end

        local function fmtTime(s)
            s = math.floor(tonumber(s) or 0)
            local d = math.floor(s/86400)
            local h = math.floor((s%86400)/3600)
            local m = math.floor((s%3600)/60)
            if d > 0 then return d.."d "..h.."h "..m.."m"
            elseif h > 0 then return h.."h "..m.."m"
            elseif m > 0 then return m.."m "..math.floor(s%60).."s"
            else return math.floor(s%60).."s" end
        end

        local function countKeys(t)
            if type(t) ~= "table" then return 0 end
            local c = 0; for _ in pairs(t) do c = c + 1 end; return c
        end

        local function getBestRoll()
            local rd = safeGet("stats","rarestRoll","slimeData")
            if type(rd) ~= "table" then return "None", "N/A" end
            local id = tostring(rd.id or "?")
            local muts = rd.mutations
            local prefix = ""
            if type(muts) == "table" then
                if muts.inverted then prefix = "Inverted "
                elseif muts.shiny and muts.huge then prefix = "Shiny Huge "
                elseif muts.shiny and muts.big then prefix = "Shiny Big "
                elseif muts.huge then prefix = "Huge "
                elseif muts.shiny then prefix = "Shiny "
                elseif muts.big then prefix = "Big "
                end
            end
            local name = prefix .. id:sub(1,1):upper()..id:sub(2)
            local odds = safeNum("stats","rarestRoll","odds")
            return name, odds > 0 and ("1 in "..fmt(math.floor(odds))) or "N/A"
        end

        local function getEquipped()
            local eq = safeGet("equipped")
            if type(eq) ~= "table" then return "None" end
            local names = {}
            for i = 1, 7 do
                local v = eq[i]
                if v and type(v) == "string" then
                    local clean = v:match("%-(.+)$") or v:gsub("^%.","")
                    table.insert(names, clean:sub(1,1):upper()..clean:sub(2))
                end
            end
            return #names > 0 and table.concat(names, ", ") or "None"
        end

        local function getIndexCounts()
            local cats = safeGet("index","categories")
            if type(cats) ~= "table" then return 0,0,0,0,0 end
            local function c(cat)
                local t = cats[cat]
                return type(t)=="table" and countKeys(t.unlocked or {}) or 0
            end
            return c("basic"), c("big"), c("shiny"), c("huge"), c("inverted")
        end

        local function getTotalInv()
            local inv = safeGet("inventory")
            if type(inv) ~= "table" then return 0 end
            local t = 0
            for _, v in pairs(inv) do if type(v)=="number" then t = t + v end end
            return t
        end

        local function getUniqueSpecies()
            local inv = safeGet("inventory")
            if type(inv) ~= "table" then return 0 end
            local seen = {}; local c = 0
            for k in pairs(inv) do
                if type(k)=="string" and not k:match("^%.") then
                    local base = k:match("%-(.+)$") or k
                    if not seen[base] then seen[base]=true; c = c + 1 end
                end
            end
            return c
        end

        local sessionStart = os.clock()
        local startRolls   = safeNum("stats","rolls")
        local startKills   = safeNum("stats","kills")
        local startCoins   = safeNum("coins")
        local startGoop    = safeNum("goop")

        local prevRolls = startRolls
        local prevCoins = startCoins
        local prevGoop  = startGoop
        local lastWin   = os.clock()

        local windowRPS, windowCPS, windowGPS = nil, nil, nil
        local lastRollMove = os.clock()
        local lastCoinMove = os.clock()
        local lastGoopMove = os.clock()
        local STALE = 60

        task.spawn(function()
            while true do
                task.wait(10)
                local now = os.clock()
                local dt  = math.max(1, now - lastWin)
                lastWin   = now
                local r = safeNum("stats","rolls")
                local c = safeNum("coins")
                local g = safeNum("goop")
                local dr = math.max(0, r - prevRolls)
                local dc = math.max(0, c - prevCoins)
                local dg = math.max(0, g - prevGoop)
                if dr > 0 then windowRPS = dr/dt;    lastRollMove = now end
                if dc > 0 then windowCPS = dc/dt;    lastCoinMove = now end
                if dg > 0 then windowGPS = dg/dt;    lastGoopMove = now end
                prevRolls = r; prevCoins = c; prevGoop = g
            end
        end)

        local function getRate(windowVal, lastMove, startVal, curVal)
            local now     = os.clock()
            local elapsed = math.max(1, now - sessionStart)
            if (now - lastMove) > STALE then return 0 end
            if windowVal and windowVal > 0 then return windowVal end
            local gain = math.max(0, curVal - startVal)
            return gain > 0 and (gain / elapsed) or 0
        end

        local L = {}
        local function lbl(key, text) L[key] = statsTab:CreateLabel(text) end

        lbl("sess",        "Session: --  |  Played: --  |  Rebirths: --")
        lbl("rolls1",      "Rolls/sec: --  |  Rolls/min: --  |  Rolls/hr: --")
        lbl("rolls2",      "Session Rolls: --  |  Lifetime: --")
        lbl("coins1",      "Coins/min: --  |  Coins/hr: --")
        lbl("coins2",      "Session Coins: --  |  Total Ever: --")
        lbl("goop1",       "Goop/min: --  |  Goop/hr: --")
        lbl("goop2",       "Session Goop: --  |  Balance: --")
        lbl("kills",       "Session Kills: --  |  Lifetime Kills: --")
        lbl("best",        "Best Ever: --  |  Odds: --")
        lbl("daily",       "Best Today Odds: --")
        lbl("prog",        "Zone: --  |  Max Zone: --  |  Roll Currency: --")
        lbl("idx1",        "Basic: --  |  Big: --  |  Shiny: --  |  Huge: --  |  Inverted: --")
        lbl("inv",         "Total Slimes: --  |  Species: --  |  Crafting: --")
        lbl("equipped",    "Equipped: --")

        local function updateAll()
            local now     = os.clock()
            local elapsed = math.max(1, now - sessionStart)

            local rolls    = safeNum("stats","rolls")
            local kills    = safeNum("stats","kills")
            local coins    = safeNum("coins")
            local goop     = safeNum("goop")
            local timePl   = safeNum("stats","timePlayed")
            local totCoins = safeNum("stats","totalCoins")
            local rebirths = safeNum("rebirths")
            local zone     = safeNum("zone")
            local maxZone  = safeNum("furthestZone")
            local rollCur  = safeNum("rollCurrency")

            local sessRolls = math.max(0, rolls - startRolls)
            local sessKills = math.max(0, kills - startKills)
            local sessCoins = math.max(0, coins - startCoins)
            local sessGoop  = math.max(0, goop  - startGoop)

            local sessH = math.floor(elapsed/3600)
            local sessM = math.floor((elapsed%3600)/60)
            local sessS = math.floor(elapsed%60)

            local rps = getRate(windowRPS, lastRollMove, startRolls, rolls)
            local cps = getRate(windowCPS, lastCoinMove, startCoins, coins)
            local gps = getRate(windowGPS, lastGoopMove, startGoop,  goop)

            local bestName, bestOdds = getBestRoll()
            local dailyOdds = safeNum("stats","dailyRarestRoll","odds")
            local dailyStr  = dailyOdds > 0 and ("1 in "..fmt(math.floor(dailyOdds))) or "N/A"
            local basic, big, shiny, huge, inverted = getIndexCounts()
            local crafting = countKeys(safeGet("craftingRecipes") or {})

            L.sess:Set(string.format("Session: %dh%dm%ds  |  Played: %s  |  Rebirths: %s", sessH, sessM, sessS, fmtTime(timePl), fmt(rebirths)))
            L.rolls1:Set(string.format("Rolls/sec: %.2f  |  Rolls/min: %s  |  Rolls/hr: %s", rps, fmt(rps*60), fmt(rps*3600)))
            L.rolls2:Set("Session Rolls: "..fmt(sessRolls).."  |  Lifetime: "..fmt(rolls))
            L.coins1:Set("Coins/min: "..fmt(cps*60).."  |  Coins/hr: "..fmt(cps*3600))
            L.coins2:Set("Session Coins: "..fmt(sessCoins).."  |  Total Ever: "..fmt(totCoins))
            L.goop1:Set("Goop/min: "..fmt(gps*60).."  |  Goop/hr: "..fmt(gps*3600))
            L.goop2:Set("Session Goop: "..fmt(sessGoop).."  |  Balance: "..fmt(goop))
            L.kills:Set("Session Kills: "..fmt(sessKills).."  |  Lifetime Kills: "..fmt(kills))
            L.best:Set("Best Ever: "..bestName.."  |  Odds: "..bestOdds)
            L.daily:Set("Best Today Odds: "..dailyStr)
            L.prog:Set("Zone: "..fmt(zone).."  |  Max Zone: "..fmt(maxZone).."  |  Roll Currency: "..fmt(rollCur))
            L.idx1:Set("Basic: "..basic.."  |  Big: "..big.."  |  Shiny: "..shiny.."  |  Huge: "..huge.."  |  Inverted: "..inverted)
            L.inv:Set("Total Slimes: "..fmt(getTotalInv()).."  |  Species: "..getUniqueSpecies().."  |  Crafting: "..crafting)
            L.equipped:Set("Equipped: "..getEquipped())
        end

        task.spawn(function()
            while true do
                updateAll()
                task.wait(2)
            end
        end)

        local craftingTab = _0x3e2c7a_tab

        local RS = game:GetService("ReplicatedStorage")
        local function getCraftingRemote()
            return RS
                :WaitForChild("Packages")
                :WaitForChild("_Index")
                :WaitForChild("leifstout_networker@0.3.1")
                :WaitForChild("networker")
                :WaitForChild("_remotes")
                :WaitForChild("CraftingService")
                :WaitForChild("RemoteFunction")
        end

        local function getCraftingData(key)
            return _0x7b3f5a:get(key)
        end

        local MutationsModule = _0x1b7e4d
        local RecipesModule
        RecipesModule = require(RS.Source.Features.Crafting.Recipes)

        local function getMutationValue(mutId)
            if not MutationsModule then return 0 end
            local data = MutationsModule.get(mutId)
            return data and data.value or 0
        end

        local function getSizeMutations()
            return MutationsModule and MutationsModule.sizeMutations or {}
        end

        local function getModifierMutations()
            return MutationsModule and MutationsModule.modifierMutations or {}
        end

        local function parseUniqueId(uid)
            local base, sizeMut, modMut = uid, nil, nil
            for _, sId in ipairs(getSizeMutations()) do
                local prefix = sId .. "_"
                if base:sub(1, #prefix) == prefix then
                    sizeMut = sId
                    base = base:sub(#prefix + 1)
                    break
                end
            end
            if base:sub(1, 1) == "-" then base = base:sub(2) end
            for _, mId in ipairs(getModifierMutations()) do
                local suffix = "_" .. mId
                if base:sub(-#suffix) == suffix then
                    modMut = mId
                    base = base:sub(1, -#suffix - 1)
                    break
                end
            end
            return base, sizeMut, modMut
        end

        local function scoreUniqueId(uid)
            local _, sizeMut, modMut = parseUniqueId(uid)
            local score = 0
            if sizeMut then score = score + getMutationValue(sizeMut) * 1000 end
            if modMut then score = score + getMutationValue(modMut) * 100 end
            return score
        end

        local function getOwnedAmount(data)
            if type(data) == "number" then return math.max(data, 0) end
            if type(data) == "table" then return 1 end
            return 0
        end

        local function isXpSlime(data)
            return type(data) == "table"
        end

        local function getEquippedSet()
            local equipped = getCraftingData("equipped") or {}
            local set = {}
            for _, uid in pairs(equipped) do set[uid] = true end
            return set
        end

        local function getBestSlimeSet()
            local inventory = getCraftingData("inventory") or {}
            local best = nil
            local bestScore = -1
            for uid, data in pairs(inventory) do
                if not isXpSlime(data) then
                    local s = scoreUniqueId(uid)
                    if s > bestScore then
                        bestScore = s
                        best = uid
                    end
                end
            end
            local set = {}
            if best then set[best] = true end
            return set
        end

        local function getXpSlimeSet()
            local inventory = getCraftingData("inventory") or {}
            local set = {}
            for uid, data in pairs(inventory) do
                if isXpSlime(data) then set[uid] = true end
            end
            return set
        end

        local function buildProtectedSet(categories)
            local catSet = {}
            for _, c in ipairs(categories) do catSet[c] = true end
            local protected = {}
            if catSet["Equipped Slimes"] then
                for uid in pairs(getEquippedSet()) do protected[uid] = true end
            end
            if catSet["Best Slime"] then
                for uid in pairs(getBestSlimeSet()) do protected[uid] = true end
            end
            if catSet["Xp Slimes"] then
                for uid in pairs(getXpSlimeSet()) do protected[uid] = true end
            end
            return protected
        end

        local function getUnlockedRecipeIds()
            if not RecipesModule then return {} end
            local unlocked = getCraftingData("craftingRecipes") or {}
            local all = RecipesModule.getRecipes() or {}
            local result = {}
            for _, recipe in ipairs(all) do
                if unlocked[recipe.id] then
                    table.insert(result, recipe.id)
                end
            end
            return result
        end

        local function getRecipe(id)
            if not RecipesModule then return nil end
            return RecipesModule.getRecipe(id)
        end

        local function findBestIngredient(baseId, usedCounts, protectedPets)
            local inventory = getCraftingData("inventory") or {}
            local bestUid, bestScore = nil, -1
            for uid, data in pairs(inventory) do
                if not protectedPets[uid] then
                    local parsedBase = parseUniqueId(uid)
                    if parsedBase == baseId then
                        local owned = getOwnedAmount(data)
                        local used = usedCounts[uid] or 0
                        if owned - used > 0 then
                            local s = scoreUniqueId(uid)
                            if s > bestScore then
                                bestScore = s
                                bestUid = uid
                            end
                        end
                    end
                end
            end
            return bestUid
        end

        local craftingState = {
            selectedRecipeIds = {},
            craftAmount = 1,
            autoCraftEnabled = false,
            autoCraftAmount = 1,
            autoCraftThread = nil,
            protectCategories = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
            protectedPets = {},
        }

        craftingState.protectedPets = buildProtectedSet(craftingState.protectCategories)

        local function getMaxCraftsForRecipe(recipeId)
            local recipe = getRecipe(recipeId)
            if not recipe then return 0 end
            
            local inventory = getCraftingData("inventory") or {}
            local usedCounts = {}
            local maxCrafts = math.huge
            
            for _, inp in ipairs(recipe.inputs) do
                local bestUid = findBestIngredient(inp.id, usedCounts, craftingState.protectedPets)
                if not bestUid then
                    return 0
                end
                usedCounts[bestUid] = (usedCounts[bestUid] or 0) + 1
                local owned = getOwnedAmount(inventory[bestUid])
                local used = usedCounts[bestUid]
                local available = owned - used + 1
                if available < maxCrafts then
                    maxCrafts = available
                end
            end
            
            return maxCrafts == math.huge and 0 or maxCrafts
        end

        local function buildCraftArgsForRecipe(recipeId, amount)
            local recipe = getRecipe(recipeId)
            if not recipe then return nil end
            local ingredientIds = {}
            local usedCounts = {}
            for i, inp in ipairs(recipe.inputs) do
                local uid = findBestIngredient(inp.id, usedCounts, craftingState.protectedPets) or ("-" .. inp.id)
                usedCounts[uid] = (usedCounts[uid] or 0) + 1
                table.insert(ingredientIds, uid)
            end
            return { "requestCraftRecipe", recipeId, ingredientIds, tostring(amount) }
        end

        local function doCraftAll(amount)
            local results = {}
            for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
                local args = buildCraftArgsForRecipe(recipeId, amount)
                if args then
                    local result = getCraftingRemote():InvokeServer(table.unpack(args))
                    results[recipeId] = result ~= false
                end
            end
            return results
        end

        local recipeIdsList = getUnlockedRecipeIds()
        if #recipeIdsList > 0 then
            craftingState.selectedRecipeIds = { recipeIdsList[1] }
        end

        craftingTab:CreateSection("Recipes")

        craftingTab:CreateDropdown({
            Name = "Select Recipes to Craft",
            Options = recipeIdsList,
            CurrentOption = { recipeIdsList[1] or "" },
            MultipleOptions = true,
            Flag = "CraftingSelectedRecipes",
            Callback = function(options)
                craftingState.selectedRecipeIds = options
            end,
        })

        craftingTab:CreateSection("Craft")

        craftingTab:CreateSlider({
            Name = "Craft Amount",
            Range = { 1, 99 },
            Increment = 1,
            Suffix = "x",
            CurrentValue = 1,
            Flag = "CraftingAmount",
            Callback = function(val)
                craftingState.craftAmount = val
            end,
        })

        craftingTab:CreateButton({
            Name = "Craft Now",
            Callback = function()
                local results = doCraftAll(craftingState.craftAmount)
                local succeeded, failed = 0, 0
                for _, ok in pairs(results) do
                    if ok then succeeded = succeeded + 1 else failed = failed + 1 end
                end
                _0x2c5d8f:Notify({
                    Title = "Cactus Hub",
                    Content = succeeded .. " crafts succeeded" .. (failed > 0 and (", " .. failed .. " failed") or ""),
                    Duration = 3,
                    Image = 4483362458,
                })
            end,
        })

        craftingTab:CreateSection("Auto Craft")

        local autoCraftMax = 1

        local function updateAutoCraftMax()
            local minMax = math.huge
            for _, recipeId in ipairs(craftingState.selectedRecipeIds) do
                local maxCrafts = getMaxCraftsForRecipe(recipeId)
                if maxCrafts < minMax then
                    minMax = maxCrafts
                end
            end
            if minMax == math.huge then
                autoCraftMax = 1
            else
                autoCraftMax = math.max(1, minMax)
            end
        end

        updateAutoCraftMax()

        craftingTab:CreateSlider({
            Name = "Auto Craft Amount",
            Range = { 1, 99 },
            Increment = 1,
            Suffix = "x",
            CurrentValue = 1,
            Flag = "CraftingAutoAmount",
            Callback = function(val)
                craftingState.autoCraftAmount = val
            end,
        })

        craftingTab:CreateToggle({
            Name = "Enable Auto Craft",
            CurrentValue = false,
            Flag = "CraftingAutoToggle",
            Callback = function(enabled)
                craftingState.autoCraftEnabled = enabled
                if enabled then
                    updateAutoCraftMax()
                    local maxAmount = autoCraftMax
                    if craftingState.autoCraftAmount > maxAmount then
                        craftingState.autoCraftAmount = maxAmount
                    end
                    if craftingState.autoCraftThread then task.cancel(craftingState.autoCraftThread) end
                    craftingState.autoCraftThread = task.spawn(function()
                        while craftingState.autoCraftEnabled do
                            updateAutoCraftMax()
                            local craftAmount = math.min(craftingState.autoCraftAmount, autoCraftMax)
                            if craftAmount > 0 then
                                doCraftAll(craftAmount)
                            end
                            task.wait(5)
                        end
                    end)
                    _0x2c5d8f:Notify({
                        Title = "Auto Craft",
                        Content = "Started - " .. craftingState.autoCraftAmount .. "x per recipe (max " .. autoCraftMax .. ")",
                        Duration = 3,
                        Image = 4483362458,
                    })
                else
                    if craftingState.autoCraftThread then
                        task.cancel(craftingState.autoCraftThread)
                        craftingState.autoCraftThread = nil
                    end
                    _0x2c5d8f:Notify({
                        Title = "Auto Craft",
                        Content = "Stopped.",
                        Duration = 3,
                        Image = 4483362458,
                    })
                end
            end,
        })

        craftingTab:CreateSection("Protected Pets")

        craftingTab:CreateDropdown({
            Name = "Protect Categories",
            Options = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
            CurrentOption = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
            MultipleOptions = true,
            Flag = "CraftingProtectCategories",
            Callback = function(options)
                craftingState.protectCategories = options
                craftingState.protectedPets = buildProtectedSet(options)
            end,
        })

        _0x2c5d8f:Notify({
            Title = "Cactus Hub",
            Content = "Loaded - " .. #recipeIdsList .. " unlocked recipes ready.",
            Duration = 5,
            Image = 4483362458,
        })

        local bb = game:GetService('VirtualUser')
        game:GetService("Players").LocalPlayer.Idled:Connect(function()
            bb:CaptureController()
            bb:ClickButton2(Vector2.new())
        end)

        game:GetService("GuiService").ErrorMessageChanged:Connect(function()
            if _0x2c5d8f.Flags.SettingsAutoRejoin and _0x2c5d8f.Flags.SettingsAutoRejoin.CurrentValue then
                game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, _0x9a4b7c)
            end
        end)

        _0x2c5d8f:LoadConfiguration()
    end)
end)
