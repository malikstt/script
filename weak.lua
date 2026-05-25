task.spawn(function()
    repeat task.wait() until game:IsLoaded()

    -- Compatibility layer with capability detection
    local function has(f) return type(f) == "function" end

    -- Resolve each function using known executor alternatives
    local setclipboard    = setclipboard or toclipboard or set_clipboard
    local setreadonly     = setreadonly or make_readonly or set_readonly
    local make_writeable  = make_writeable or makewriteable or make_writable or set_writable
    local getconnections  = getconnections or get_connections
    local getrawmetatable = getrawmetatable or getrawmt or get_raw_metatable
    local newcclosure     = newcclosure or new_c_closure
    local getnamecallmethod = getnamecallmethod or get_namecall_method or getnamecall
    local sethiddenproperty = sethiddenproperty or sethiddenprop or set_hidden_property or set_hidden_prop
    local identifyexecutor  = identifyexecutor or getexecutorname
    local request         = request or http_request or (http and http.request)

    -- Provide fallbacks for missing functions
    setclipboard    = has(setclipboard) and setclipboard or function() end
    setreadonly     = has(setreadonly) and setreadonly or function() end
    make_writeable  = has(make_writeable) and make_writeable or function() end
    getconnections  = has(getconnections) and getconnections or function() return {} end
    getrawmetatable = has(getrawmetatable) and getrawmetatable or function() return nil end
    newcclosure     = has(newcclosure) and newcclosure or function(f) return f end
    getnamecallmethod = has(getnamecallmethod) and getnamecallmethod or function() return "" end
    sethiddenproperty = has(sethiddenproperty) and sethiddenproperty or function() end
    identifyexecutor  = has(identifyexecutor) and identifyexecutor or function() return "Unknown" end
    request         = has(request) and request or function() return {Success=false,Body="",StatusCode=0} end

    -- Capability detection for optional features
    local caps = {
        setClipboard    = has(setclipboard),
        setReadonly     = has(setreadonly),
        makeWriteable   = has(make_writeable),
        getConnections  = has(getconnections),
        getRawMetatable = has(getrawmetatable),
        newCClosure     = has(newcclosure),
        getNamecall     = has(getnamecallmethod),
        setHiddenProp   = has(sethiddenproperty),
        identify        = has(identifyexecutor),
        requestFunc     = has(request),
    }

    print("[CactusHub] Executor: " .. identifyexecutor())
    print("[CactusHub] Capabilities:",
        "Connections=" .. tostring(caps.getConnections),
        "SetReadonly=" .. tostring(caps.setReadonly),
        "RawMetatable=" .. tostring(caps.getRawMetatable),
        "SetHiddenProp=" .. tostring(caps.setHiddenProp),
        "Request=" .. tostring(caps.requestFunc)
    )

    -- Startup webhook (safe)
    local Players = game:GetService("Players")
    local HttpService = game:GetService("HttpService")
    local player = Players.LocalPlayer
    local executor = identifyexecutor()
    if caps.requestFunc then
        local embed = {{
            description = player.Name .. " executed the script",
            color = 5763719,
            footer = { text = "Executor: " .. tostring(executor) },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%S")
        }}
        local body = HttpService:JSONEncode({ embeds = embed })
        pcall(function()
            request({
                Url = "https://discord.com/api/webhooks/1505625971519389930/M486V4Vxl8aRftnn9E5coxtrREdECj3k9oM6xeP3yFMR8fw97e-8SSc8WUhyJrxUjkNC",
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body
            })
        end)
    end

    local PUBLIC_WEBHOOK_URL = "https://discord.com/api/webhooks/1508176094522511370/4INSvRJo1j6kE2zL_neypXOrpkgEhpCwm2NTVLfPV8_czBsVMHFrbG7tno46VnhcMKSR"
    local PUBLIC_MINIMUM_CHANCE = 1000000

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

    local _0x7b3f5a
    pcall(function()
        _0x7b3f5a = require(_0x5c1a4d.DataService).client
    end)
    if not _0x7b3f5a then
        _0x7b3f5a = setmetatable({}, { __index = function() return function() end end })
    end
    pcall(function() _0x7b3f5a:waitForData() end)

    local _0x2c9e4d
    pcall(function() _0x2c9e4d = require(_0x5c1a4d.Networker) end)

    local _0x8a1d6f, _0x4e7b2c
    pcall(function()
        _0x8a1d6f = _0x2c9e4d and _0x2c9e4d.client and _0x2c9e4d.client.new("InventoryService")
    end)
    pcall(function()
        _0x4e7b2c = _0x2c9e4d and _0x2c9e4d.client and _0x2c9e4d.client.new("XpTransferService")
    end)

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
        local _0x9a1c4d, _0x2b6e8f = pcall(_0x1f8a3c.getTier, _0x3d8f1a)
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
        local _0x4e7a2c, _0x5f8c2a = pcall(request, {
            Url = "https://thumbnails.roblox.com/v1/assets?assetIds=" .. _0x1c6a2d .. "&size=420x420&format=Png&isCircular=false",
            Method = "GET"
        })
        if _0x4e7a2c and _0x5f8c2a and _0x5f8c2a.Success then
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

        pcall(function()
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
        end)

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
                pcall(function()
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
                end)
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
            pcall(function()
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
            end)
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

    -- ========== FLUENT UI INITIALIZATION ==========
    local Library = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

    -- Config tables for UI state (replaces Rayfield Flags)
    local config = {
        FarmingZoneTarget = "Best Unlocked",
        FarmingStayInBestZone = false,
        FarmingUnlockAffordableZones = false,
        FarmingEquipBestSlimes = false,
        FarmingAutoFeed = false,
        FarmingTransferXP = false,
        FarmingTransferTarget = "Best Slime",
        FarmingTransferSource = "Unequipped With XP",
        FarmingFastRoll = false,
        FarmingCollectLoot = false,
        GameAutoRebirth = false,
        GameMinZoneRebirth = "",
        GameAutoUpgrade = false,
        GameUpgradeMode = "All",
        CombatAutoShoot = false,
        CombatTargetPriority = "Closest",
        GameFloatEnemies = false,
        GameFloatRadius = 12,
        GameFloatSpeed = 1,
        GameFloatWaveSpeed = 3,
        GameFloatWaveHeight = 1.5,
        GameAttackEnemies = false,
        GameAttackRange = 25,
        GameAttackLungeSpeed = 15,
        MiscRedeemCodes = false,
        MiscClaimOffline = false,
        MiscClaimIndex = false,
        MiscUsePotions = false,
        MiscPotionTypes = {},
        MiscUseDice = false,
        MiscDiceTypes = {},
        WebhookEnabled = false,
        WebhookURL = "",
        WebhookUserID = "",
        WebhookMinChance = "",
        WebhookSendAll = false,
        WebhookSendNew = false,
        WebhookSendMutated = false,
        WebhookMutations = {},
        SettingsAntiAFK = true,
        SettingsAntiKick = false,
        SettingsAutoRejoin = false,
        AutoFriend = false,
        OptimizeAll = false,
        OptimizeGPU = false,
        OptimizeParticles = false,
        FireOptimization = false,
        LuaGC = false,
        IntenseOptimization = false,
        HideDamageUI = false,
        CraftingSelectedRecipes = {},
        CraftingAmount = 1,
        CraftingAutoAmount = 1,
        CraftingAutoToggle = false,
        CraftingProtectCategories = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
    }

    local Window = Library:CreateWindow({
        Title = "Cactus Hub",
        SubTitle = "discord.gg/qMWFBWdcf",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = "Dark",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- Main Tab
    local mainTab = Window:AddTab({Title = "Main", Icon = "home"})

    local fpsPara = mainTab:AddParagraph({Title = "", Content = "FPS: --"})
    local pingPara = mainTab:AddParagraph({Title = "", Content = "Ping: --"})

    local fpsCount = 0
    local fpsLast = tick()
    _0x1e5f3d.RenderStepped:Connect(function()
        fpsCount = fpsCount + 1
        local now = tick()
        if now - fpsLast >= 1 then
            fpsPara:Set("FPS: " .. fpsCount)
            fpsCount = 0
            fpsLast = now
        end
    end)

    task.spawn(function()
        while true do
            pcall(function()
                local pingValue = game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()
                pingPara:Set("Ping: " .. math.floor(pingValue) .. "ms")
            end)
            task.wait(1)
        end
    end)

    mainTab:AddSection("Release")
    mainTab:AddParagraph({Title = "Enabled By Default", Content = "[+] Anti AFK"})
    mainTab:AddParagraph({Title = "Latest Update", Content = "[+] Auto Send & Accept Friend Requests\n[+] Fixed Auto Collect Loot\n[+] Fixed Settings (Optimization Toggles)\n[+] Added Public Webhook in Discord\n[+] Hide Attack & Damage UI\n[+] Bug Fixes"})

    mainTab:AddButton({
        Title = "Copy Discord Invite",
        Callback = function()
            if not caps.setClipboard then
                Library:Notify({Title = "Not Supported", Content = "Your executor doesn't support clipboard copy.", Duration = 4})
                return
            end
            pcall(function() setclipboard("https://discord.gg/qMWFBWdcf") end)
            Library:Notify({Title = "Discord", Content = "Link copied to clipboard!", Duration = 3})
        end,
    })

    mainTab:AddParagraph({Title = "", Content = "Report bugs in the Discord\nhttps://discord.gg/qMWFBWdcf"})

    mainTab:AddButton({
        Title = "Save Config Manually",
        Callback = function()
            SaveManager:Save()
            Library:Notify({Title = "Config", Content = "Configuration saved!", Duration = 3})
        end,
    })

    local dashboardBusy = false
    mainTab:AddToggle("DashboardToggle", {
        Title = "Dashboard",
        Default = false,
        Callback = function(Value)
            if dashboardBusy then return end
            dashboardBusy = true
            if Value then
                task.spawn(function()
                    local success, err = pcall(function()
                        loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/no"))()
                    end)
                    if not success then
                        Library:Notify({Title = "Dashboard", Content = "Feature unavailable on this executor", Duration = 3})
                    else
                        Library:Notify({Title = "Dashboard", Content = "Dashboard enabled!", Duration = 3})
                    end
                    dashboardBusy = false
                end)
            else
                local gui = game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("__MAINHUD__")
                if gui then
                    gui:Destroy()
                end
                Library:Notify({Title = "Dashboard", Content = "Dashboard closed!", Duration = 3})
                dashboardBusy = false
            end
        end,
    })

    -- Farming Tab
    local farmingTab = Window:AddTab({Title = "Farming", Icon = "sword"})

    farmingTab:AddSection("Zones")

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

    farmingTab:AddDropdown("FarmingZoneTarget", {
        Title = "Zone Target",
        Values = zoneOptions,
        Default = "Best Unlocked",
        Multi = false,
        Callback = function(opt) config.FarmingZoneTarget = opt end,
    })

    farmingTab:AddToggle("FarmingStayInBestZone", {
        Title = "Auto Farm Zone",
        Default = false,
        Callback = function(v)
            config.FarmingStayInBestZone = v
            if v then
                task.spawn(function()
                    while config.FarmingStayInBestZone do
                        pcall(function()
                            local targetOption = config.FarmingZoneTarget
                            if targetOption == "Best Unlocked" then
                                local maxZone = 33
                                for zoneNum = maxZone, 1, -1 do
                                    if not config.FarmingStayInBestZone then break end
                                    local success = pcall(_0x2a7e4c.InvokeServer, _0x2a7e4c, "requestTeleportZone", zoneNum)
                                    if success then
                                        task.wait(1)
                                        if (_0x7b3f5a:get("zone") or 1) == zoneNum then break end
                                    end
                                end
                            else
                                local zoneNum = tonumber(targetOption:match("Zone (%d+)"))
                                if zoneNum then
                                    pcall(_0x2a7e4c.InvokeServer, _0x2a7e4c, "requestTeleportZone", zoneNum)
                                end
                            end
                        end)
                        task.wait(10)
                    end
                end)
            end
        end,
    })

    farmingTab:AddToggle("FarmingUnlockAffordableZones", {
        Title = "Auto Unlock Affordable Zones",
        Default = false,
        Callback = function(v)
            config.FarmingUnlockAffordableZones = v
            if v then
                task.spawn(function()
                    while config.FarmingUnlockAffordableZones do
                        pcall(function()
                            pcall(_0x2a7e4c.InvokeServer, _0x2a7e4c, "requestPurchaseZone")
                        end)
                        task.wait(5)
                    end
                end)
            end
        end,
    })

    farmingTab:AddSection("Slimes")

    farmingTab:AddToggle("FarmingEquipBestSlimes", {
        Title = "Auto Equip Best Slimes",
        Default = false,
        Callback = function(v)
            config.FarmingEquipBestSlimes = v
            if v then
                task.spawn(function()
                    local delay = 30
                    while config.FarmingEquipBestSlimes do
                        pcall(function()
                            pcall(_0x9c3a2e.InvokeServer, _0x9c3a2e, "requestEquipBest")
                        end)
                        task.wait(delay)
                        delay = math.min(delay * 2, 600)
                    end
                end)
            end
        end,
    })

    farmingTab:AddToggle("FarmingAutoFeed", {
        Title = "Auto Feed Best Slime",
        Default = false,
        Callback = function(v) config.FarmingAutoFeed = v end,
    })

    task.spawn(function()
        while task.wait(10) do
            if config.FarmingAutoFeed then
                pcall(function()
                    local bestUid = _0x2f8c4a()
                    if bestUid then
                        local items = _0x7b3f5a:get("items") or {}
                        for itemId, count in pairs(items) do
                            if type(count) == "number" and count > 0 then
                                pcall(_0x8a1d6f.fetch, _0x8a1d6f, "requestUseFood", itemId, bestUid, count)
                                task.wait(0.3)
                            end
                        end
                    end
                end)
            end
        end
    end)

    farmingTab:AddToggle("FarmingTransferXP", {
        Title = "Auto Transfer XP",
        Default = false,
        Callback = function(v) config.FarmingTransferXP = v end,
    })

    farmingTab:AddDropdown("FarmingTransferTarget", {
        Title = "Transfer To",
        Values = { "Best Slime", "Whole Team" },
        Default = "Best Slime",
        Multi = false,
        Callback = function(opt) config.FarmingTransferTarget = opt end,
    })

    farmingTab:AddDropdown("FarmingTransferSource", {
        Title = "Transfer From",
        Values = { "Unequipped With XP", "All Slimes" },
        Default = "Unequipped With XP",
        Multi = false,
        Callback = function(opt) config.FarmingTransferSource = opt end,
    })

    task.spawn(function()
        while task.wait(30) do
            if config.FarmingTransferXP then
                pcall(function()
                    local inventory = _0x7b3f5a:get("inventory") or {}
                    local equipped = _0x7b3f5a:get("equipped") or {}
                    local teamSet = {}
                    for _, uid in ipairs(equipped) do teamSet[uid] = true end
                    local targetOption = config.FarmingTransferTarget
                    local sourceOption = config.FarmingTransferSource
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
                                    pcall(_0x4e7b2c.fetch, _0x4e7b2c, "requestTransferXp", uid, target)
                                    task.wait(0.5)
                                elseif sourceOption == "All Slimes" and hasXp then
                                    pcall(_0x4e7b2c.fetch, _0x4e7b2c, "requestTransferXp", uid, target)
                                    task.wait(0.5)
                                end
                            end
                        end
                    end
                end)
            end
        end
    end)

    farmingTab:AddSection("Rolling")

    farmingTab:AddToggle("FarmingFastRoll", {
        Title = "Auto Fast Roll",
        Default = false,
        Callback = function(v)
            config.FarmingFastRoll = v
            if v then
                task.spawn(function()
                    local RollSlice = require(game:GetService("ReplicatedStorage"):WaitForChild("Source"):WaitForChild("Features"):WaitForChild("Roll"):WaitForChild("RollSlice"))
                    while config.FarmingFastRoll do
                        pcall(function()
                            game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("RollService"):WaitForChild("RemoteFunction"):InvokeServer("requestRoll")
                        end)
                        task.wait(RollSlice.rollTime())
                    end
                end)
            end
        end,
    })

    farmingTab:AddSection("Loot")

    farmingTab:AddToggle("FarmingCollectLoot", {
        Title = "Auto Collect Loot",
        Default = false,
        Callback = function(v)
            config.FarmingCollectLoot = v
            if v then
                task.spawn(function()
                    print("[CactusHub] Auto Collect Loot started")
                    while config.FarmingCollectLoot do
                        pcall(function()
                            for _, folder in ipairs({"Loot", "Debris"}) do
                                local container = workspace:FindFirstChild(folder)
                                if container then
                                    for _, item in ipairs(container:GetChildren()) do
                                        local id = item:GetAttribute("uniqueId") or item:GetAttribute("id") or item.Name
                                        if id then
                                            pcall(function()
                                                local success = _0x4c2a7e:InvokeServer("requestCollect", id)
                                                if success then
                                                    print("[CactusHub] Collected: " .. tostring(item.Name) .. " | ID: " .. tostring(id))
                                                else
                                                    print("[CactusHub] Failed to collect: " .. tostring(item.Name))
                                                end
                                            end)
                                        end
                                    end
                                end
                            end
                        end)
                        task.wait(0.5)
                    end
                    print("[CactusHub] Auto Collect Loot stopped")
                end)
            else
                print("[CactusHub] Auto Collect Loot disabled")
            end
        end,
    })

    -- Game Tab
    local gameTab = Window:AddTab({Title = "Game", Icon = "game"})

    gameTab:AddSection("Rebirth")

    gameTab:AddToggle("GameAutoRebirth", {
        Title = "Auto Rebirth",
        Default = false,
        Callback = function(v)
            config.GameAutoRebirth = v
            if v then
                task.spawn(function()
                    while config.GameAutoRebirth do
                        pcall(function()
                            local rebirths = _0x7b3f5a:get("rebirths") or 0
                            local goop = _0x7b3f5a:get("goop") or 0
                            local furthestZone = _0x7b3f5a:get("furthestZone") or 0
                            local cost = (2 ^ rebirths) * 500
                            local minZone = tonumber(config.GameMinZoneRebirth) or 0
                            if furthestZone >= minZone and goop >= cost then
                                pcall(_0x4d8f1b.InvokeServer, _0x4d8f1b, "requestRebirth")
                            end
                        end)
                        task.wait(10)
                    end
                end)
            end
        end,
    })

    gameTab:AddInput("GameMinZoneRebirth", {
        Title = "Minimum Zone To Rebirth",
        Default = "",
        Placeholder = "e.g. 10",
        Callback = function(val) config.GameMinZoneRebirth = val end,
    })

    gameTab:AddSection("Upgrades")

    gameTab:AddToggle("GameAutoUpgrade", {
        Title = "Auto Upgrade Purchasing",
        Default = false,
        Callback = function(v)
            config.GameAutoUpgrade = v
            if v then
                task.spawn(function()
                    local upgradeList, upgradeCosts = _0x7c3f2a()
                    while task.wait(0.5) and config.GameAutoUpgrade do
                        pcall(function()
                            local mode = config.GameUpgradeMode
                            local upgradesOwned = _0x7b3f5a:get("upgrades") or {}
                            local coins = _0x7b3f5a:get("coins") or 0
                            local goop = _0x7b3f5a:get("goop") or 0
                            local rollCurr = _0x7b3f5a:get("rollCurrency") or 0
                            for _, upgradeId in ipairs(upgradeList) do
                                if not upgradesOwned[upgradeId] then
                                    local costData = upgradeCosts[upgradeId]
                                    if costData then
                                        local amount = costData.amount or 0
                                        local currency = costData.currency
                                        local modeMatch = (mode == "All") or
                                            (mode == "Coins" and currency == "coins") or
                                            (mode == "Goop" and currency == "goop") or
                                            (mode == "Rolls" and currency == "rollCurrency")
                                        local canAfford = (currency == "coins" and coins >= amount) or
                                                          (currency == "goop" and goop >= amount) or
                                                          (currency == "rollCurrency" and rollCurr >= amount)
                                        if modeMatch and canAfford then
                                            local success = pcall(_0x5c8f2a.InvokeServer, _0x5c8f2a, "requestUnlock", upgradeId)
                                            if success then task.wait(0.2) end
                                        end
                                    end
                                end
                            end
                        end)
                    end
                end)
            end
        end,
    })

    gameTab:AddDropdown("GameUpgradeMode", {
        Title = "Upgrade Mode",
        Values = {"All", "Goop", "Coins", "Rolls"},
        Default = "All",
        Multi = false,
        Callback = function(opt) config.GameUpgradeMode = opt end,
    })

    gameTab:AddSection("Combat")

    gameTab:AddToggle("CombatAutoShoot", {
        Title = "Auto Shoot Enemies",
        Default = false,
        Content = "Auto Shoot is enabled but visual effects will not appear — damage is still dealt.",
        Callback = function(v) config.CombatAutoShoot = v end,
    })

    gameTab:AddDropdown("CombatTargetPriority", {
        Title = "Target Priority",
        Values = {"Closest", "Lowest HP", "Highest HP"},
        Default = "Closest",
        Multi = false,
        Callback = function(opt) config.CombatTargetPriority = opt end,
    })

    local function ensureEquipped()
        local character = _0x9a4b7c.Character
        if not character then return false end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if not humanoid then return false end
        local gun = character:FindFirstChild("SlimeGun") or _0x9a4b7c.Backpack:FindFirstChild("SlimeGun")
        if gun and gun.Parent ~= character then
            humanoid:EquipTool(gun)
        end
        return gun ~= nil
    end

    task.spawn(function()
        while true do
            ensureEquipped()
            task.wait(2)
        end
    end)

    local damageUIParent = nil
    local function getDamageUIParent()
        if damageUIParent and damageUIParent.Parent then return damageUIParent end
        local playerGui = _0x9a4b7c.PlayerGui
        local screenGui = playerGui:FindFirstChild("SlimeGunHUD")
        if screenGui then
            local container = screenGui:FindFirstChild("PopupContainer")
            if container then
                damageUIParent = container
                return container
            end
        end
        return nil
    end

    task.spawn(function()
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local Players = game:GetService("Players")
        local player = Players.LocalPlayer
        
        local GameplayServiceClient = require(ReplicatedStorage.Source.Features.Gameplay.GameplayServiceClient)
        local GoopGunServiceClient = require(ReplicatedStorage.Source.Features.GoopGun.GoopGunServiceClient)
        local GoopGunServiceUtils = require(ReplicatedStorage.Source.Features.GoopGun.GoopGunServiceUtils)
        local DataService = require(ReplicatedStorage.Packages.DataService).client
        
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "SlimeGunHUD"
        screenGui.ResetOnSpawn = false
        screenGui.IgnoreGuiInset = true
        screenGui.DisplayOrder = 999
        screenGui.Parent = player.PlayerGui
        
        local container = Instance.new("Frame")
        container.Name = "PopupContainer"
        container.Position = UDim2.new(1, -276, 0, 48)
        container.Size = UDim2.new(0, 260, 1, -96)
        container.BackgroundTransparency = 1
        container.Parent = screenGui
        
        local layout = Instance.new("UIListLayout")
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
        layout.Padding = UDim.new(0, 6)
        layout.Parent = container
        
        local COLORS = {
            normal   = Color3.fromRGB(120, 220, 255),
            big      = Color3.fromRGB(255, 180, 50),
            huge     = Color3.fromRGB(255, 80, 80),
            shiny    = Color3.fromRGB(255, 230, 50),
            inverted = Color3.fromRGB(180, 80, 255),
        }
        
        local function getMutationColor(mutations)
            if not mutations then return COLORS.normal end
            if mutations.inverted then return COLORS.inverted end
            if mutations.huge     then return COLORS.huge end
            if mutations.shiny    then return COLORS.shiny end
            if mutations.big      then return COLORS.big end
            return COLORS.normal
        end
        
        local function getEnemyLabel(enemy)
            local tier = "Lv." .. tostring(enemy.enemyId or 1)
            local uid = "#" .. tostring(enemy.uniqueId or "?")
            if enemy.mutations then
                local tags = {}
                for mut in pairs(enemy.mutations) do
                    table.insert(tags, mut:sub(1,1):upper() .. mut:sub(2))
                end
                if #tags > 0 then
                    return table.concat(tags, " ") .. " Slime " .. tier .. " " .. uid
                end
            end
            return "Slime " .. tier .. " " .. uid
        end
        
        local activePopups = {}
        local popupOrder = 0
        
        local TweenService = game:GetService("TweenService")
        
        local function pulseFrame(frame, accentColor)
            TweenService:Create(frame, TweenInfo.new(0.06, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                BackgroundColor3 = accentColor
            }):Play()
            task.delay(0.06, function()
                TweenService:Create(frame, TweenInfo.new(0.12, Enum.EasingStyle.Quad), {
                    BackgroundColor3 = Color3.fromRGB(10, 10, 18)
                }):Play()
            end)
        end
        
        local function destroyPopup(uid)
            local p = activePopups[uid]
            if not p then return end
            activePopups[uid] = nil
            local frame = p.frame
            TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quint), {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 0)
            }):Play()
            for _, lbl in ipairs(p.labels) do
                TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            end
            TweenService:Create(p.accent, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
            task.delay(0.3, function() frame:Destroy() end)
        end
        
        local function scheduleExpiry(uid)
            local p = activePopups[uid]
            if not p then return end
            if p.expireTask then task.cancel(p.expireTask) end
            p.expireTask = task.delay(2.5, function()
                destroyPopup(uid)
            end)
        end
        
        local function createPopup(uid, enemyLabel, dmg, hpAfter, accentColor)
            popupOrder += 1
        
            local frame = Instance.new("Frame")
            frame.Size = UDim2.new(1, 0, 0, 52)
            frame.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
            frame.BackgroundTransparency = 0.1
            frame.BorderSizePixel = 0
            frame.ClipsDescendants = true
            frame.LayoutOrder = popupOrder
            frame.Parent = container
        
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
        
            local accent = Instance.new("Frame")
            accent.Size = UDim2.new(0, 3, 1, 0)
            accent.BackgroundColor3 = accentColor
            accent.BorderSizePixel = 0
            accent.Parent = frame
            Instance.new("UICorner", accent).CornerRadius = UDim.new(0, 10)
        
            local nameLabel = Instance.new("TextLabel")
            nameLabel.Position = UDim2.new(0, 14, 0, 5)
            nameLabel.Size = UDim2.new(1, -90, 0, 18)
            nameLabel.BackgroundTransparency = 1
            nameLabel.Text = enemyLabel
            nameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
            nameLabel.TextXAlignment = Enum.TextXAlignment.Left
            nameLabel.Font = Enum.Font.GothamBold
            nameLabel.TextSize = 13
            nameLabel.Parent = frame
        
            local hpLabel = Instance.new("TextLabel")
            hpLabel.Position = UDim2.new(0, 14, 0, 25)
            hpLabel.Size = UDim2.new(1, -90, 0, 14)
            hpLabel.BackgroundTransparency = 1
            hpLabel.Text = "HP: " .. tostring(math.max(0, math.floor(hpAfter)))
            hpLabel.TextColor3 = Color3.fromRGB(130, 130, 150)
            hpLabel.TextXAlignment = Enum.TextXAlignment.Left
            hpLabel.Font = Enum.Font.Gotham
            hpLabel.TextSize = 11
            hpLabel.Parent = frame
        
            local hitsLabel = Instance.new("TextLabel")
            hitsLabel.Position = UDim2.new(0, 14, 0, 38)
            hitsLabel.Size = UDim2.new(1, -90, 0, 12)
            hitsLabel.BackgroundTransparency = 1
            hitsLabel.Text = "1 hit  •  " .. tostring(math.floor(dmg)) .. " total dmg"
            hitsLabel.TextColor3 = Color3.fromRGB(90, 90, 110)
            hitsLabel.TextXAlignment = Enum.TextXAlignment.Left
            hitsLabel.Font = Enum.Font.Gotham
            hitsLabel.TextSize = 10
            hitsLabel.Parent = frame
        
            local dmgLabel = Instance.new("TextLabel")
            dmgLabel.Position = UDim2.new(1, -80, 0, 0)
            dmgLabel.Size = UDim2.new(0, 72, 1, 0)
            dmgLabel.BackgroundTransparency = 1
            dmgLabel.Text = "-" .. tostring(math.floor(dmg))
            dmgLabel.TextColor3 = accentColor
            dmgLabel.TextXAlignment = Enum.TextXAlignment.Right
            dmgLabel.Font = Enum.Font.GothamBold
            dmgLabel.TextSize = 20
            dmgLabel.Parent = frame
        
            frame.Position = UDim2.new(-1, 0, 0, 0)
            TweenService:Create(frame, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = UDim2.new(0, 0, 0, 0)
            }):Play()
        
            activePopups[uid] = {
                frame      = frame,
                accent     = accent,
                labels     = { nameLabel, hpLabel, hitsLabel, dmgLabel },
                hpLabel    = hpLabel,
                hitsLabel  = hitsLabel,
                dmgLabel   = dmgLabel,
                totalDmg   = dmg,
                hits       = 1,
                accentColor = accentColor,
                expireTask = nil,
            }
        
            scheduleExpiry(uid)
        end
        
        local function updatePopup(uid, dmg, hpAfter)
            local p = activePopups[uid]
            if not p then return end
        
            p.totalDmg = p.totalDmg + dmg
            p.hits = p.hits + 1
        
            p.hpLabel.Text   = "HP: " .. tostring(math.max(0, math.floor(hpAfter)))
            p.hitsLabel.Text = p.hits .. " hits  •  " .. tostring(math.floor(p.totalDmg)) .. " total dmg"
            p.dmgLabel.Text  = "-" .. tostring(math.floor(p.totalDmg))
        
            pulseFrame(p.frame, p.accentColor)
            scheduleExpiry(uid)
        end
        
        local function selectTarget()
            local gameplay = GameplayServiceClient.gameplay
            if not gameplay then return nil end
            local character = player.Character
            if not character then return nil end
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if not rootPart then return nil end
        
            local priority = config.CombatTargetPriority
            local best, bestVal = nil, nil
        
            for uniqueId, enemy in pairs(gameplay.enemies) do
                if enemy.health and enemy.health > 0 then
                    if priority == "Closest" then
                        local dist = (enemy.pos - rootPart.Position).Magnitude
                        if bestVal == nil or dist < bestVal then
                            bestVal = dist
                            best = uniqueId
                        end
                    elseif priority == "Lowest HP" then
                        if bestVal == nil or enemy.health < bestVal then
                            bestVal = enemy.health
                            best = uniqueId
                        end
                    elseif priority == "Highest HP" then
                        if bestVal == nil or enemy.health > bestVal then
                            bestVal = enemy.health
                            best = uniqueId
                        end
                    end
                end
            end
            return best
        end
        
        while true do
            if config.CombatAutoShoot then
                local character = player.Character
                if character and character:FindFirstChildOfClass("Humanoid") and character:FindFirstChildOfClass("Humanoid").Health > 0 then
                    pcall(function()
                        ensureEquipped()
                        local upgrades = DataService:get("upgrades") or {}
                        local fireRate = GoopGunServiceUtils.getFireRate(upgrades)
                        local targetId = selectTarget()
                        if targetId then
                            local gameplay = GameplayServiceClient.gameplay
                            local enemy = gameplay and gameplay.enemies[targetId]
                            local hpBefore = enemy and enemy.health or 0
                            local enemyLabel = enemy and getEnemyLabel(enemy) or "Slime"
                            local accentColor = enemy and getMutationColor(enemy.mutations) or COLORS.normal
        
                            local wrapper = GoopGunServiceClient.wrapper
                            if wrapper and wrapper.onEnemyHit then
                                wrapper.onEnemyHit(targetId)
                            end
        
                            task.wait()
                            local hpAfter = enemy and enemy.health or 0
                            local dmg = hpBefore - hpAfter
        
                            if dmg > 0 then
                                if activePopups[targetId] then
                                    updatePopup(targetId, dmg, hpAfter)
                                else
                                    createPopup(targetId, enemyLabel, dmg, hpAfter, accentColor)
                                end
                            end
                        end
                        task.wait(fireRate)
                    end)
                else
                    task.wait(1)
                end
            else
                task.wait(0.5)
            end
        end
    end)

    local function getPrimaryPart(model)
        return model.PrimaryPart
            or model:FindFirstChild("HumanoidRootPart")
            or model:FindFirstChild("RootPart")
            or model:FindFirstChildWhichIsA("BasePart")
    end

    local floatEnemiesEnabled = false
    local attackEnemiesEnabled = false

    local enemiesList = {}
    local slimesList = {}
    local lastScan = 0

    local function scanEntities()
        local now = tick()
        if now - lastScan < 0.5 then return end
        lastScan = now

        local gameplay = _0x3e2c8f()
        if not gameplay then return end

        local enemiesFolder = gameplay:FindFirstChild("Enemies")
        local slimesFolder = gameplay:FindFirstChild("Slimes")

        enemiesList = {}
        if enemiesFolder then
            for _, child in ipairs(enemiesFolder:GetChildren()) do
                if child:IsA("Model") then
                    local root = getPrimaryPart(child)
                    if root then
                        table.insert(enemiesList, {model = child, root = root})
                    end
                end
            end
        end

        slimesList = {}
        if slimesFolder then
            for _, child in ipairs(slimesFolder:GetChildren()) do
                if child:IsA("Model") then
                    local root = getPrimaryPart(child)
                    if root then
                        table.insert(slimesList, {model = child, root = root, id = child.Name})
                    end
                end
            end
        end
    end

    local function isValidEntity(model)
        if not model or not model.Parent then return false end
        local root = getPrimaryPart(model)
        if not root then return false end
        local humanoid = model:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoid.Health <= 0 then return false end
        return true
    end

    local function getClosestEnemy(pos)
        local closest, closestDist = nil, math.huge
        for _, enemy in ipairs(enemiesList) do
            if isValidEntity(enemy.model) then
                local dist = (enemy.root.Position - pos).Magnitude
                if dist < closestDist then
                    closestDist = dist
                    closest = enemy.model
                end
            end
        end
        return closest
    end

    gameTab:AddSection("Floating Enemies")

    gameTab:AddToggle("GameFloatEnemies", {
        Title = "Float Enemies Around Player",
        Default = false,
        Callback = function(v) config.GameFloatEnemies = v end,
    })

    gameTab:AddSlider("GameFloatRadius", {
        Title = "Float Radius",
        Default = 12,
        Min = 5,
        Max = 25,
        Rounding = 1,
        Suffix = "studs",
        Callback = function(v) config.GameFloatRadius = v end,
    })

    gameTab:AddSlider("GameFloatSpeed", {
        Title = "Float Rotation Speed",
        Default = 1,
        Min = 0.5,
        Max = 5,
        Rounding = 1,
        Suffix = "x",
        Callback = function(v) config.GameFloatSpeed = v end,
    })

    gameTab:AddSlider("GameFloatWaveSpeed", {
        Title = "Float Wave Speed",
        Default = 3,
        Min = 1,
        Max = 10,
        Rounding = 0.5,
        Suffix = "x",
        Callback = function(v) config.GameFloatWaveSpeed = v end,
    })

    gameTab:AddSlider("GameFloatWaveHeight", {
        Title = "Float Wave Height",
        Default = 1.5,
        Min = 0.5,
        Max = 5,
        Rounding = 0.5,
        Suffix = "studs",
        Callback = function(v) config.GameFloatWaveHeight = v end,
    })

    gameTab:AddSection("Attack System")

    gameTab:AddToggle("GameAttackEnemies", {
        Title = "Attack Floating Enemies",
        Default = false,
        Callback = function(v) config.GameAttackEnemies = v end,
    })

    gameTab:AddSlider("GameAttackRange", {
        Title = "Attack Range",
        Default = 25,
        Min = 10,
        Max = 50,
        Rounding = 1,
        Suffix = "studs",
        Callback = function(v) config.GameAttackRange = v end,
    })

    gameTab:AddSlider("GameAttackLungeSpeed", {
        Title = "Attack Lunge Speed",
        Default = 15,
        Min = 5,
        Max = 30,
        Rounding = 1,
        Suffix = "x",
        Callback = function(v) config.GameAttackLungeSpeed = v end,
    })

    local attackCooldown = {}

    local function setModelCFrame(model, cf)
        if not model or not model.Parent then return end
        pcall(function()
            local primary = model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart")
            if primary and not primary:IsA("UnionOperation") then
                model:PivotTo(cf)
            end
        end)
    end

    _0x1e5f3d.RenderStepped:Connect(function()
        if not config.GameFloatEnemies and not config.GameAttackEnemies then return end

        scanEntities()

        local character = _0x9a4b7c.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        if not rootPart then return end

        local now = tick()
        local radius = config.GameFloatRadius
        local speed = config.GameFloatSpeed
        local waveSpeed = config.GameFloatWaveSpeed
        local waveHeight = config.GameFloatWaveHeight

        if config.GameFloatEnemies and #enemiesList > 0 then
            local count = #enemiesList
            for i, enemy in ipairs(enemiesList) do
                local angle = ((i / count) * math.pi * 2) + (now * speed)
                local yOffset = math.sin((now * waveSpeed) + i) * waveHeight

                local targetPos = rootPart.Position + Vector3.new(
                    math.cos(angle) * radius,
                    yOffset + 2,
                    math.sin(angle) * radius
                )

                local dir = (targetPos - rootPart.Position).Unit
                setModelCFrame(enemy.model, CFrame.lookAt(targetPos, targetPos + dir))
            end
        end

        if config.GameAttackEnemies and #slimesList > 0 and #enemiesList > 0 then
            local attackRange = config.GameAttackRange
            local lungeSpeed = config.GameAttackLungeSpeed

            local slimeCount = #slimesList
            for i, slime in ipairs(slimesList) do
                local angle = ((i / slimeCount) * math.pi * 2) + (now * speed)
                local yOffset = math.sin((now * waveSpeed) + i) * waveHeight

                local basePos = rootPart.Position + Vector3.new(
                    math.cos(angle) * radius,
                    yOffset + 2,
                    math.sin(angle) * radius
                )

                local closestEnemy, closestDist = nil, attackRange
                for _, enemy in ipairs(enemiesList) do
                    local dist = (basePos - enemy.root.Position).Magnitude
                    if dist < closestDist then
                        closestDist = dist
                        closestEnemy = enemy
                    end
                end

                local targetPos = basePos
                local lookPos = basePos + (basePos - rootPart.Position).Unit

                if closestEnemy then
                    if not attackCooldown[slime.id] then
                        attackCooldown[slime.id] = now
                    end

                    local elapsed = now - attackCooldown[slime.id]
                    local lungeFactor = math.sin(elapsed * lungeSpeed)

                    if lungeFactor > 0 then
                        targetPos = basePos:Lerp(closestEnemy.root.Position, lungeFactor * 0.85)
                        lookPos = closestEnemy.root.Position
                    else
                        attackCooldown[slime.id] = now
                    end
                else
                    attackCooldown[slime.id] = nil
                end

                setModelCFrame(slime.model, CFrame.lookAt(targetPos, lookPos))
            end
        end
    end)

    -- Misc Tab
    local miscTab = Window:AddTab({Title = "Misc", Icon = "settings"})

    miscTab:AddSection("Codes & Rewards")

    miscTab:AddToggle("MiscRedeemCodes", {
        Title = "Auto Redeem Codes",
        Default = false,
        Callback = function(v)
            config.MiscRedeemCodes = v
            if v then
                task.spawn(function()
                    local codes = {
                        "gullible",
                        "test",
                        "goingBananas",
                        "AAisComing",
                        "Sliming",
                    }
                    while config.MiscRedeemCodes do
                        pcall(function()
                            for _, code in ipairs(codes) do
                                pcall(_0x1b6d8f.InvokeServer, _0x1b6d8f, "redeem", code)
                                task.wait(0.5)
                            end
                        end)
                        task.wait(300)
                    end
                end)
            end
        end,
    })

    miscTab:AddToggle("MiscClaimOffline", {
        Title = "Auto Claim Offline Earnings",
        Default = false,
        Callback = function(v)
            config.MiscClaimOffline = v
            if v then
                task.spawn(function()
                    while config.MiscClaimOffline do
                        pcall(function()
                            pcall(_0x3e7a2c_remote.InvokeServer, _0x3e7a2c_remote, "requestClaim")
                        end)
                        task.wait(60)
                    end
                end)
            end
        end,
    })

    miscTab:AddToggle("MiscClaimIndex", {
        Title = "Auto Claim Index Rewards",
        Default = false,
        Callback = function(v)
            config.MiscClaimIndex = v
            if v then
                task.spawn(function()
                    local function claimIndex()
                        local indexData = _0x7b3f5a:get("index")
                        if not indexData or not indexData.categories then return end
                        for categoryId, rewards in pairs(_0x3e6a1d) do
                            local cat = indexData.categories[categoryId]
                            if cat then
                                local unlocked = cat.unlocked or {}
                                local unlockedCount = 0
                                for _, val in pairs(unlocked) do if val == true then unlockedCount = unlockedCount + 1 end end
                                local claimed = cat.claimedRewards or {}
                                for _, reward in ipairs(rewards) do
                                    if unlockedCount >= reward.req and not claimed[reward.key] then
                                        pcall(_0x6f1a8d.InvokeServer, _0x6f1a8d, "requestClaimReward", categoryId)
                                        task.wait(0.5)
                                    end
                                end
                            end
                        end
                    end
                    while config.MiscClaimIndex do
                        pcall(claimIndex)
                        task.wait(60)
                    end
                end)
            end
        end,
    })

    miscTab:AddSection("Consumables")

    miscTab:AddToggle("MiscUsePotions", {
        Title = "Auto Use Potions",
        Default = false,
        Callback = function(v)
            config.MiscUsePotions = v
            if v then
                task.spawn(function()
                    while task.wait(1) and config.MiscUsePotions do
                        pcall(function()
                            local boosts = _0x7b3f5a:get("boosts") or {}
                            for _, kind in ipairs(config.MiscPotionTypes) do
                                local boost = boosts[kind]
                                if boost and (boost.amount or 0) > 0 then
                                    pcall(_0x8b1d4f.InvokeServer, _0x8b1d4f, "requestUseBoost", kind)
                                end
                            end
                        end)
                    end
                end)
            end
        end,
    })

    miscTab:AddDropdown("MiscPotionTypes", {
        Title = "Potion Types",
        Values = _0x4a8d2f,
        Default = {_0x4a8d2f[1]},
        Multi = true,
        Callback = function(sel) config.MiscPotionTypes = sel end,
    })

    miscTab:AddToggle("MiscUseDice", {
        Title = "Auto Use Dice & Items",
        Default = false,
        Callback = function(v)
            config.MiscUseDice = v
            if v then
                task.spawn(function()
                    while task.wait(1) and config.MiscUseDice do
                        pcall(function()
                            local items = _0x7b3f5a:get("items") or {}
                            for _, displayName in ipairs(config.MiscDiceTypes) do
                                local itemId = _0x9d4c1e[displayName]
                                if itemId and (items[itemId] or 0) > 0 then
                                    pcall(_0x9c3a2e.InvokeServer, _0x9c3a2e, "requestUseItem", itemId)
                                end
                            end
                        end)
                    end
                end)
            end
        end,
    })

    do
        local diceNames = {}
        for _, id in ipairs(_0x7c2e5a) do
            table.insert(diceNames, _0x3f8a2b[id])
        end
        miscTab:AddDropdown("MiscDiceTypes", {
            Title = "Dice & Item Types",
            Values = diceNames,
            Default = {diceNames[1]},
            Multi = true,
            Callback = function(sel) config.MiscDiceTypes = sel end,
        })
    end

    -- Webhook Tab
    local webhookTab = Window:AddTab({Title = "Webhook", Icon = "webhook"})

    webhookTab:AddSection("Warning")
    webhookTab:AddParagraph({Title = "⚠️ WARNING", Content = "WEBHOOK WILL ONLY WORK IF YOU MANUALLY ENABLE AUTO ROLL IN GAME\nPLEASE DISABLE FAST ROLL (from Farming Tab) if you have it enabled"})

    webhookTab:AddSection("Configuration")

    webhookTab:AddToggle("WebhookEnabled", {
        Title = "Enable Webhook",
        Default = false,
        Callback = function(v) config.WebhookEnabled = v end,
    })

    webhookTab:AddInput("WebhookURL", {
        Title = "Webhook URL",
        Default = "",
        Placeholder = "Paste your Discord webhook URL",
        Callback = function(val)
            if val and val:match("^https://discord") then
                config.WebhookURL = val
                local masked = string.rep("•", #val - 6) .. val:sub(-6)
                Library:Notify({Title = "Webhook", Content = "URL saved: " .. masked, Duration = 3})
            end
        end,
    })

    webhookTab:AddInput("WebhookUserID", {
        Title = "User ID",
        Default = "",
        Placeholder = "Discord User ID",
        Callback = function(val) config.WebhookUserID = val end,
    })

    webhookTab:AddInput("WebhookMinChance", {
        Title = "Minimum Chance To Send",
        Default = "",
        Placeholder = "e.g. 1B or 1000000000",
        Callback = function(val) config.WebhookMinChance = val end,
    })

    webhookTab:AddButton({
        Title = "Test Webhook",
        Callback = function()
            if config.WebhookURL == "" then
                Library:Notify({Title = "Webhook", Content = "Please paste a Webhook URL first.", Duration = 4})
                return
            end
            if not config.WebhookEnabled then
                Library:Notify({Title = "Webhook", Content = "Please enable Webhook first.", Duration = 4})
                return
            end
            local userId = config.WebhookUserID
            local mention = (userId and userId ~= "" and userId ~= "everyone" and userId ~= "here") and ("<@" .. userId .. "> ") or ""
            local success, err = pcall(function()
                request({
                    Url = config.WebhookURL,
                    Method = "POST",
                    Headers = {["Content-Type"] = "application/json"},
                    Body = _0x2b6f8e:JSONEncode({
                        content = mention,
                        username = "Cactus Hub",
                        avatar_url = WEBHOOK_AVATAR,
                        embeds = {{
                            title = "✅ Webhook Test",
                            description = "Your webhook is working correctly!",
                            color = 0x2ecc71,
                        }}
                    })
                })
            end)
            if not success then
                Library:Notify({Title = "Webhook", Content = "Failed: " .. (err or "unknown"), Duration = 4})
            else
                Library:Notify({Title = "Webhook", Content = "Test sent successfully!", Duration = 4})
            end
        end,
    })

    webhookTab:AddSection("Filters")

    webhookTab:AddToggle("WebhookSendAll", {
        Title = "Send All Slimes",
        Default = false,
        Callback = function(v) config.WebhookSendAll = v end,
    })

    webhookTab:AddToggle("WebhookSendNew", {
        Title = "Send New Slimes Only",
        Default = false,
        Callback = function(v) config.WebhookSendNew = v end,
    })

    webhookTab:AddToggle("WebhookSendMutated", {
        Title = "Send Mutated Slimes",
        Default = false,
        Callback = function(v) config.WebhookSendMutated = v end,
    })

    webhookTab:AddDropdown("WebhookMutations", {
        Title = "Mutations Filter",
        Values = {"All", "Shiny", "Big", "Huge", "Inverted"},
        Default = {"All"},
        Multi = true,
        Callback = function(sel) config.WebhookMutations = sel end,
    })

    local lastRollHash = nil

    local function mutationFilter(mutations)
        local selected = config.WebhookMutations
        if #selected == 0 then return true end
        for _, m in ipairs(selected) do
            if m == "All" then return true end
            if m == "Shiny" and mutations and mutations.shiny then return true end
            if m == "Big" and mutations and mutations.big then return true end
            if m == "Huge" and mutations and mutations.huge then return true end
            if m == "Inverted" and mutations and mutations.inverted then return true end
        end
        return false
    end

    task.spawn(function()
        while true do
            task.wait(0.1)

            if not config.WebhookEnabled or config.WebhookURL == "" then
                -- do nothing
            else
                if not _0x8d1f4a or type(_0x8d1f4a.rollResults) ~= "function" then
                    task.wait(1)
                else
                    local ok, results = pcall(_0x8d1f4a.rollResults)
                    if not ok or type(results) ~= "table" or #results == 0 then
                        task.wait(0.5)
                    else
                        local hash = _0x9b2c4e(results)
                        if hash ~= lastRollHash then
                            lastRollHash = hash

                            local sendAll = config.WebhookSendAll
                            local sendNew = config.WebhookSendNew
                            local sendMutated = config.WebhookSendMutated
                            local minChanceNum = parseChanceString(config.WebhookMinChance)

                            for _, roll in ipairs(results) do
                                local slimeData = _0x7c5f2a(roll)
                                if slimeData then
                                    local slimeId = tostring(slimeData.id or "")
                                    if slimeId ~= "" then
                                        local mutations = type(slimeData.mutations) == "table" and next(slimeData.mutations) ~= nil and slimeData.mutations or nil
                                        local okSlime, slimeDef = pcall(_0x6f3a2c.getSlime, slimeId)
                                        local slimeDefOk = okSlime and slimeDef

                                        local isMutated = mutations ~= nil
                                        local isNew = _0x1a7c4f(slimeId, mutations)

                                        local shouldSend = sendAll or (sendNew and isNew) or (sendMutated and isMutated and mutationFilter(mutations))

                                        if shouldSend and minChanceNum then
                                            local odds = slimeDefOk and slimeDef.odds or 0
                                            local chanceValue = odds > 0 and (1 / odds) or 0
                                            if chanceValue > minChanceNum then
                                                shouldSend = false
                                            end
                                        end

                                        if shouldSend then
                                            local userId = config.WebhookUserID
                                            local uniqueKey = hash .. "_" .. slimeId .. "_" .. tostring(mutations and _0x1b7e4d.getIds(mutations) or "")
                                            task.spawn(_0x4c7e2a, slimeId, slimeDefOk and slimeDef, mutations, config.WebhookURL, userId, uniqueKey)
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

    -- Settings Tab
    local settingsTab = Window:AddTab({Title = "Settings", Icon = "settings"})

    settingsTab:AddSection("System")

    settingsTab:AddToggle("SettingsAntiAFK", {
        Title = "Anti AFK",
        Default = true,
        Callback = function(v)
            config.SettingsAntiAFK = v
            if not caps.getConnections then
                if v then
                    Library:Notify({Title = "Not Supported", Content = "Your executor doesn't support getconnections. Anti-AFK will not work.", Duration = 4})
                end
                return
            end
            local ok, err = pcall(function()
                local conns = getconnections(_0x9a4b7c.Idled)
                if v then
                    for _, x in pairs(conns) do
                        pcall(function() x:Disable() end)
                    end
                else
                    for _, x in pairs(conns) do
                        pcall(function() x:Enable() end)
                    end
                end
            end)
            if not ok then
                warn("[CactusHub] getconnections error: " .. tostring(err))
            end
        end,
    })

    settingsTab:AddToggle("SettingsAntiKick", {
        Title = "Anti Kick",
        Default = false,
        Callback = function(v)
            config.SettingsAntiKick = v
            if (not caps.getRawMetatable or not caps.setReadonly) and v then
                Library:Notify({Title = "Not Supported", Content = "Anti-Kick requires getrawmetatable + setreadonly. Feature disabled.", Duration = 4})
            end
        end,
    })

    settingsTab:AddToggle("SettingsAutoRejoin", {
        Title = "Auto Rejoin On Disconnect",
        Default = false,
        Callback = function(v) config.SettingsAutoRejoin = v end,
    })

    settingsTab:AddToggle("AutoFriend", {
        Title = "Auto Friend Requests",
        Default = false,
        Callback = function(v)
            config.AutoFriend = v
            if v then
                task.spawn(function()
                    while config.AutoFriend do
                        pcall(function()
                            local players = game:GetService("Players"):GetChildren()
                            for _, p in ipairs(players) do
                                pcall(function()
                                    _0x9a4b7c:RequestFriendship(p)
                                end)
                                task.wait(1)
                            end
                        end)
                        task.wait(600)
                    end
                end)
            end
        end,
    })
    settingsTab:AddParagraph({Title = "", Content = "( I'm not sure if it works )"})

    settingsTab:AddSection("Advanced Optimization")

    local optConnections = {}
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

    local function safeDestroy(obj)
        if obj and obj.Parent then obj:Destroy() end
    end

    local function tryHidden(obj, prop, val)
        if caps.setHiddenProp then sethiddenproperty(obj, prop, val) end
    end

    local function applyOptimizationToInstance(v)
        local cn = v.ClassName
        if OPT_VISUAL_TYPES[cn] then safeDestroy(v) return end
        if cn == "Decal" or cn == "Texture" then v.Transparency = 1 return end
        if cn == "SpecialMesh" then v.TextureId = "" return end
        if cn == "PointLight" or cn == "SpotLight" or cn == "SurfaceLight" then v.Enabled = false return end
        if v:IsA("BasePart") then
            v.CastShadow = false
            v.Reflectance = 0
            pcall(function() v.Material = CHEAP_MATERIAL end)
            if not v:IsA("TriangleMeshPart") then
                tryHidden(v, "RenderFidelity", 2)
            end
        end
    end

    local function optimizeLighting()
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
        tryHidden(L, "Technology", 0)
        for _, c in ipairs(L:GetChildren()) do
            if OPT_LIGHTING_TYPES[c.ClassName] then c:Destroy() end
        end
        local terrain = workspace:FindFirstChildOfClass("Terrain")
        if terrain then
            pcall(function()
                local clouds = terrain:FindFirstChildOfClass("Clouds")
                if clouds then clouds:Destroy() end
                terrain.WaterWaveSize = 0
                terrain.WaterWaveSpeed = 0
                terrain.WaterReflectance = 0
                terrain.WaterTransparency = 1
            end)
        end
        table.insert(optConnections, L.ChildAdded:Connect(function(child)
            if OPT_LIGHTING_TYPES[child.ClassName] then
                task.defer(child.Destroy, child)
            end
        end))
    end

    local function optimizeCharacter(character)
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
                pcall(v.Destroy, v)
            elseif v:IsA("BasePart") then
                v.CastShadow = false
                v.Reflectance = 0
                pcall(function() v.Material = CHEAP_MATERIAL end)
            elseif cn == "Decal" or cn == "Texture" then
                v.Transparency = 1
            elseif cn == "SpecialMesh" then
                v.TextureId = ""
            elseif cn == "Accessory" then
                pcall(v.Destroy, v)
            end
        end
    end

    local function optimizeWorkspaceScan()
        local Camera = workspace.CurrentCamera
        local charSet = {}
        for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
            if p.Character then charSet[p.Character] = true end
        end
        for _, obj in ipairs(workspace:GetChildren()) do
            if obj ~= Camera and not charSet[obj] then
                for _, v in ipairs(obj:GetDescendants()) do
                    applyOptimizationToInstance(v)
                end
            end
        end
        table.insert(optConnections, workspace.ChildAdded:Connect(function(obj)
            if obj == workspace.CurrentCamera then return end
            task.defer(function()
                for _, v in ipairs(obj:GetDescendants()) do
                    applyOptimizationToInstance(v)
                end
            end)
        end))
    end

    local function optimizePlayers()
        local Players = game:GetService("Players")
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character then optimizeCharacter(p.Character) end
            table.insert(optConnections, p.CharacterAdded:Connect(function(char)
                task.defer(optimizeCharacter, char)
            end))
        end
        table.insert(optConnections, Players.PlayerAdded:Connect(function(p)
            table.insert(optConnections, p.CharacterAdded:Connect(function(char)
                task.defer(optimizeCharacter, char)
            end))
        end))
    end

    local function optimizeCamera()
        local cam = workspace.CurrentCamera
        if not cam then return end
        cam.FieldOfView = 70
        for _, v in ipairs(cam:GetChildren()) do
            if OPT_LIGHTING_TYPES[v.ClassName] then v:Destroy() end
        end
    end

    local function optimizeGUI()
        pcall(function()
            local sg = game:GetService("StarterGui")
            sg:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
            sg:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
            sg:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
        end)
    end

    local function optimizeRenderQuality()
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function()
            UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel01
        end)
        pcall(function()
            local rs = game:GetService("RunService")
            rs:Set3dRenderingEnabled(false)
            task.wait(0.1)
            rs:Set3dRenderingEnabled(true)
        end)
    end

    local function cleanOptConnections()
        for _, c in ipairs(optConnections) do pcall(c.Disconnect, c) end
        table.clear(optConnections)
    end

    local optGPUToggle, optParticlesToggle, optFireToggle, optGCToggle, optIntenseToggle, optHideDamageToggle, optMainToggle

    local function setAllOptimizations(value)
        if optGPUToggle then optGPUToggle:SetValue(value) end
        if optParticlesToggle then optParticlesToggle:SetValue(value) end
        if optFireToggle then optFireToggle:SetValue(value) end
        if optGCToggle then optGCToggle:SetValue(value) end
        if optIntenseToggle then optIntenseToggle:SetValue(value) end
        if optHideDamageToggle then optHideDamageToggle:SetValue(value) end
    end

    optMainToggle = settingsTab:AddToggle("OptimizeAll", {
        Title = "Optimize All",
        Default = false,
        Callback = function(v)
            config.OptimizeAll = v
            setAllOptimizations(v)
        end,
    })

    optGPUToggle = settingsTab:AddToggle("OptimizeGPU", {
        Title = "Optimize GPU (Low Graphics)",
        Default = false,
        Callback = function(v)
            config.OptimizeGPU = v
            if v then
                if not caps.setHiddenProp then
                    Library:Notify({Title = "Not Supported", Content = "sethiddenproperty missing. GPU optimization will be limited.", Duration = 4})
                end
                pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
                local L = game:GetService("Lighting")
                L.GlobalShadows = false
                L.EnvironmentDiffuseScale = 0
                L.EnvironmentSpecularScale = 0
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") then
                        v.CastShadow = false
                        v.Reflectance = 0
                        pcall(function() v.Material = CHEAP_MATERIAL end)
                    end
                end
                pcall(function()
                    local rs = game:GetService("RunService")
                    rs:Set3dRenderingEnabled(false)
                    task.wait(0.1)
                    rs:Set3dRenderingEnabled(true)
                end)
            end
        end,
    })

    optParticlesToggle = settingsTab:AddToggle("OptimizeParticles", {
        Title = "Remove All Particles & Effects",
        Default = false,
        Callback = function(v)
            config.OptimizeParticles = v
            if v then
                for _, v in ipairs(game:GetDescendants()) do
                    if OPT_VISUAL_TYPES[v.ClassName] then
                        pcall(v.Destroy, v)
                    end
                end
            end
        end,
    })

    optFireToggle = settingsTab:AddToggle("FireOptimization", {
        Title = "Remove Fire Effects",
        Default = false,
        Callback = function(v)
            config.FireOptimization = v
            if v then
                for _, v in ipairs(game:GetDescendants()) do
                    if v:IsA("Fire") then pcall(v.Destroy, v) end
                end
            end
        end,
    })

    optGCToggle = settingsTab:AddToggle("LuaGC", {
        Title = "Lua GC (Memory Cleaner)",
        Default = false,
        Callback = function(v)
            config.LuaGC = v
            if v then
                if _G.__memoryCleaner then
                    pcall(_G.__memoryCleaner.Disconnect, _G.__memoryCleaner)
                end
                _G.__memoryCleaner = game:GetService("RunService").Heartbeat:Connect(function()
                    pcall(function() gcinfo() end)
                end)
            else
                if _G.__memoryCleaner then
                    pcall(_G.__memoryCleaner.Disconnect, _G.__memoryCleaner)
                    _G.__memoryCleaner = nil
                end
            end
        end,
    })

    optIntenseToggle = settingsTab:AddToggle("IntenseOptimization", {
        Title = "Intense Optimization",
        Default = false,
        Callback = function(v)
            config.IntenseOptimization = v
            if v then
                local success, err = pcall(function()
                    loadstring(game:HttpGet("https://raw.githubusercontent.com/malikstt/script/main/Optimization.lua"))()
                end)
                if not success then
                    Library:Notify({Title = "Intense Optimization", Content = "Feature unavailable on this executor", Duration = 3})
                end
            end
        end,
    })

    optHideDamageToggle = settingsTab:AddToggle("HideDamageUI", {
        Title = "Hide Damage UI",
        Default = false,
        Callback = function(v)
            config.HideDamageUI = v
            local container = getDamageUIParent()
            if container then
                container.Visible = not v
            else
                task.spawn(function()
                    while not getDamageUIParent() and task.wait(0.5) do end
                    local cont = getDamageUIParent()
                    if cont then cont.Visible = not v end
                end)
            end
        end,
    })

    -- Stats Tab
    local statsTab = Window:AddTab({Title = "Stats", Icon = "chart"})

    local DataClient = _0x7b3f5a
    local function safeGet(...)
        local data = DataClient._data and DataClient._data._data
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
    local function lbl(key, text) L[key] = statsTab:AddParagraph({Title = "", Content = text}) end

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

    local function updateStats()
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
            pcall(updateStats)
            task.wait(2)
        end
    end)

    -- Crafting Tab (replaces previous "Game" tab section)
    local craftingTab = Window:AddTab({Title = "Crafting", Icon = "hammer"})

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

    local MutationsModule = _0x1b7e4d
    local RecipesModule
    pcall(function() RecipesModule = require(RS.Source.Features.Crafting.Recipes) end)

    local function getMutationValue(mutId)
        if not MutationsModule then return 0 end
        local ok, data = pcall(function() return MutationsModule.get(mutId) end)
        return ok and data and data.value or 0
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
        local equipped = _0x7b3f5a:get("equipped") or {}
        local set = {}
        for _, uid in pairs(equipped) do set[uid] = true end
        return set
    end

    local function getBestSlimeSet()
        local inventory = _0x7b3f5a:get("inventory") or {}
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
        local inventory = _0x7b3f5a:get("inventory") or {}
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
        local unlocked = _0x7b3f5a:get("craftingRecipes") or {}
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
        local ok, r = pcall(function() return RecipesModule.getRecipe(id) end)
        return ok and r or nil
    end

    local function findBestIngredient(baseId, usedCounts, protectedPets)
        local inventory = _0x7b3f5a:get("inventory") or {}
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
        
        local inventory = _0x7b3f5a:get("inventory") or {}
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
                local ok, result = pcall(function()
                    return getCraftingRemote():InvokeServer(table.unpack(args))
                end)
                if not ok then warn("[CactusHub]", result) end
                results[recipeId] = ok and result ~= false
            end
        end
        return results
    end

    local recipeIdsList = getUnlockedRecipeIds()
    if #recipeIdsList > 0 then
        craftingState.selectedRecipeIds = { recipeIdsList[1] }
    end

    craftingTab:AddSection("Recipes")

    craftingTab:AddDropdown("CraftingSelectedRecipes", {
        Title = "Select Recipes to Craft",
        Values = recipeIdsList,
        Default = { recipeIdsList[1] or "" },
        Multi = true,
        Callback = function(sel) craftingState.selectedRecipeIds = sel end,
    })

    craftingTab:AddSection("Craft")

    craftingTab:AddSlider("CraftingAmount", {
        Title = "Craft Amount",
        Default = 1,
        Min = 1,
        Max = 99,
        Rounding = 1,
        Suffix = "x",
        Callback = function(v) craftingState.craftAmount = v end,
    })

    craftingTab:AddButton({
        Title = "Craft Now",
        Callback = function()
            local results = doCraftAll(craftingState.craftAmount)
            local succeeded, failed = 0, 0
            for _, ok in pairs(results) do
                if ok then succeeded = succeeded + 1 else failed = failed + 1 end
            end
            Library:Notify({
                Title = "Cactus Hub",
                Content = succeeded .. " crafts succeeded" .. (failed > 0 and (", " .. failed .. " failed") or ""),
                Duration = 3,
            })
        end,
    })

    craftingTab:AddSection("Auto Craft")

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

    craftingTab:AddSlider("CraftingAutoAmount", {
        Title = "Auto Craft Amount",
        Default = 1,
        Min = 1,
        Max = 99,
        Rounding = 1,
        Suffix = "x",
        Callback = function(v) craftingState.autoCraftAmount = v end,
    })

    craftingTab:AddToggle("CraftingAutoToggle", {
        Title = "Enable Auto Craft",
        Default = false,
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
                        pcall(function()
                            updateAutoCraftMax()
                            local craftAmount = math.min(craftingState.autoCraftAmount, autoCraftMax)
                            if craftAmount > 0 then
                                doCraftAll(craftAmount)
                            end
                        end)
                        task.wait(5)
                    end
                end)
                Library:Notify({
                    Title = "Auto Craft",
                    Content = "Started - " .. craftingState.autoCraftAmount .. "x per recipe (max " .. autoCraftMax .. ")",
                    Duration = 3,
                })
            else
                if craftingState.autoCraftThread then
                    task.cancel(craftingState.autoCraftThread)
                    craftingState.autoCraftThread = nil
                end
                Library:Notify({
                    Title = "Auto Craft",
                    Content = "Stopped.",
                    Duration = 3,
                })
            end
        end,
    })

    craftingTab:AddSection("Protected Pets")

    craftingTab:AddDropdown("CraftingProtectCategories", {
        Title = "Protect Categories",
        Values = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
        Default = { "Best Slime", "Equipped Slimes", "Xp Slimes" },
        Multi = true,
        Callback = function(sel)
            craftingState.protectCategories = sel
            craftingState.protectedPets = buildProtectedSet(sel)
        end,
    })

    Library:Notify({
        Title = "Cactus Hub",
        Content = "Loaded - " .. #recipeIdsList .. " unlocked recipes ready.",
        Duration = 5,
    })

    -- Anti-AFK via VirtualUser
    _0x9a4b7c.Idled:Connect(function()
        if config.SettingsAntiAFK then
            _0x7d2c9a:CaptureController()
            _0x7d2c9a:ClickButton2(Vector2.new())
        end
    end)

    -- Auto Rejoin
    game:GetService("GuiService").ErrorMessageChanged:Connect(function()
        if config.SettingsAutoRejoin then
            game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, _0x9a4b7c)
        end
    end)

    -- SaveManager setup
    SaveManager:SetLibrary(Library)
    InterfaceManager:SetLibrary(Library)
    SaveManager:BuildConfigSection(Window)
    InterfaceManager:BuildInterfaceSection(Window)
    SaveManager:LoadAutoLoad()

    Library:Notify({Title = "Cactus Hub", Content = "Loaded! Join discord.gg/qMWFBWdcf", Duration = 4})
    print("[Cactus Hub] Script fully loaded (Fluent version)")
end)