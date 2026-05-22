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
pcall(function()
    _0x8a1d6f = _0x2c9e4d.client.new("InventoryService")
end)
pcall(function()
    _0x4e7b2c = _0x2c9e4d.client.new("XpTransferService")
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
        {1e18,"Qn"},{1e15,"Qd"},{1e12,"T"},
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

    pcall(function()
        request({
            Url = _0x4d8c2a,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = _0x2b6f8e:JSONEncode({
                content = _0x3e8a2b,
                username = "Cactus Hub",
                embeds = {{
                    title       = "🎲 New Slime Rolled!",
                    description = string.format("**||%s||** rolled **%s**!\n\n🎲 **Total Rolls:** %s", _0x1c4d7f, _0x5c8a2f, _0x5c2f8a(_0x4e7a2b)),
                    thumbnail   = _0x3a8f2b and {url = _0x3a8f2b, width = _0x6f2a8c, height = _0x6f2a8c} or nil,
                    fields      = _0x7d3f2a,
                    color       = _0x7e4c2a(_0x2a5f8d),
                }}
            })
        })
    end)
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

local _0x3c8a2f = getrawmetatable(game)
local _0x4a7b2c = _0x3c8a2f.__namecall
setreadonly(_0x3c8a2f, false)
_0x3c8a2f.__namecall = newcclosure(function(_0x1b3f8a, ...)
    local _0x3d2c7e = getnamecallmethod()
    if _0x3d2c7e == "Kick" or _0x3d2c7e == "kick" then
        if _0x2c5d8f and _0x2c5d8f.Flags and _0x2c5d8f.Flags.SettingsAntiKick and _0x2c5d8f.Flags.SettingsAntiKick.CurrentValue then
            return nil
        end
    end
    return _0x4a7b2c(_0x1b3f8a, ...)
end)
setreadonly(_0x3c8a2f, true)

local _0x2c5d8f = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local _0x4f2a8c_window = _0x2c5d8f:CreateWindow({
    Name = "Cactus Hub",
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
    Content = "[+] Fixed Upgrade System (Recursive)\n[+] Fixed Slime Gun\n[+] Added Advanced Optimization\n[+] Fixed All Variable Collisions\n[+] Bug Fixes"
})

_0x1b6d4a_main:CreateButton({
    Name = "Copy Discord Invite",
    Callback = function()
        setclipboard("https://discord.gg/6ANCjyaR5")
        _0x2c5d8f:Notify({Title = "Discord", Content = "Link copied to clipboard!", Duration = 3})
    end,
})

_0x1b6d4a_main:CreateParagraph({
    Title = "",
    Content = "Report bugs in the Discord\nhttps://discord.gg/6ANCjyaR5"
})

_0x1b6d4a_main:CreateButton({
    Name = "Save Config Manually",
    Callback = function()
        _0x2c5d8f:SaveConfiguration()
    end,
})

local _0x8c1d4a = _0x4f2a8c_window:CreateTab("Farming", 138602335586757)

_0x8c1d4a:CreateSection("Zones")

_0x8c1d4a:CreateToggle({
    Name = "Auto Stay In Best Unlocked Zone",
    CurrentValue = false,
    Flag = "FarmingStayInBestZone",
    Callback = function(_0x2c4e7a)
        if _0x2c4e7a then
            task.spawn(function()
                while _0x2c5d8f.Flags.FarmingStayInBestZone and _0x2c5d8f.Flags.FarmingStayInBestZone.CurrentValue do
                    local _0x3a7c2e = 33
                    for _0x2e4c7a = _0x3a7c2e, 1, -1 do
                        if not (_0x2c5d8f.Flags.FarmingStayInBestZone and _0x2c5d8f.Flags.FarmingStayInBestZone.CurrentValue) then break end
                        local _0x4b8d2a = pcall(_0x2a7e4c.InvokeServer, _0x2a7e4c, "requestTeleportZone", _0x2e4c7a)
                        if _0x4b8d2a then
                            task.wait(1)
                            if (_0x7b3f5a:get("zone") or 1) == _0x2e4c7a then break end
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
                    pcall(_0x2a7e4c.InvokeServer, _0x2a7e4c, "requestPurchaseZone")
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
                    pcall(_0x9c3a2e.InvokeServer, _0x9c3a2e, "requestEquipBest")
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
                        pcall(_0x8a1d6f.fetch, _0x8a1d6f, "requestUseFood", _0x4d2f8a, _0x2b6f8a, _0x5a1c7e)
                        task.wait(0.3)
                    end
                end
            end
        end
    end
end)

_0x8c1d4a:CreateToggle({
    Name = "Auto Transfer XP To Best Slime",
    CurrentValue = false,
    Flag = "FarmingTransferXP",
    Callback = function(_0x2c4f7a) end,
})

task.spawn(function()
    while task.wait(30) do
        if _0x2c5d8f.Flags.FarmingTransferXP and _0x2c5d8f.Flags.FarmingTransferXP.CurrentValue then
            local _0x4d8f1a = _0x2f8c4a()
            local _0x6e2a4c = _0x7b3f5a:get("inventory") or {}
            if _0x4d8f1a then
                for _0x1c7e3b, _0x9a2d4f in pairs(_0x6e2a4c) do
                    if type(_0x9a2d4f) == "table" and _0x9a2d4f.id and _0x1c7e3b ~= _0x4d8f1a then
                        if (_0x9a2d4f.xp or 0) > 0 or (_0x9a2d4f.level or 1) > 1 then
                            pcall(_0x4e7b2c.fetch, _0x4e7b2c, "requestTransferXp", _0x1c7e3b, _0x4d8f1a)
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
                    pcall(function()
                        game:GetService("ReplicatedStorage"):WaitForChild("Packages"):WaitForChild("_Index"):WaitForChild("leifstout_networker@0.3.1"):WaitForChild("networker"):WaitForChild("_remotes"):WaitForChild("RollService"):WaitForChild("RemoteFunction"):InvokeServer("requestRoll")
                    end)
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
                while _0x2c5d8f.Flags.FarmingCollectLoot and _0x2c5d8f.Flags.FarmingCollectLoot.CurrentValue do
                    task.wait(30)
                    local _0x2b7c4e = workspace:FindFirstChild("Loot")
                    if _0x2b7c4e then
                        for _, _0x4d2f8a in ipairs(_0x2b7c4e:GetChildren()) do
                            pcall(function()
                                _0x4c2a7e:InvokeServer("requestCollect", _0x4d2f8a.Name)
                            end)
                        end
                    end
                end
            end)
        end
    end,
})

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
                        pcall(_0x4d8f1b.InvokeServer, _0x4d8f1b, "requestRebirth")
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
                                    local _0x2e6a4c = pcall(_0x5c8f2a.InvokeServer, _0x5c8f2a, "requestUnlock", _0x2c7e4a)
                                    if _0x2e6a4c then task.wait(0.2) end
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

_0x3e2c7a_tab:CreateSection("Combat")

_0x3e2c7a_tab:CreateToggle({
    Name = "Spam Slime Gun",
    CurrentValue = false,
    Flag = "GameSpamSlimeGun",
    Callback = function(_0x3c7e2a)
        if _0x3c7e2a then
            task.spawn(function()
                local Players = game:GetService("Players")
                local VirtualInputManager = game:GetService("VirtualInputManager")
                local ReplicatedStorage = game:GetService("ReplicatedStorage")
                
                local LocalPlayer = Players.LocalPlayer
                
                local Gameplay = require(ReplicatedStorage.Source.Features.Gameplay.GameplayServiceClient)
                local DataService = require(ReplicatedStorage.Packages.DataService).client
                local GoopUtils = require(ReplicatedStorage.Source.Features.GoopGun.GoopGunServiceUtils)
                
                local function equipGun()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    if not hum then return end
                    local tool = char:FindFirstChild("SlimeGun") or LocalPlayer.Backpack:FindFirstChild("SlimeGun")
                    if tool and tool.Parent ~= char then
                        hum:EquipTool(tool)
                    end
                end
                
                local function getRoot()
                    local char = LocalPlayer.Character
                    if not char then return end
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    if not hum then return end
                    return hum.RootPart
                end
                
                local function getClosestEnemy()
                    local gameplay = Gameplay.gameplay
                    local root = getRoot()
                    if not gameplay or not root then return end
                    local upgrades = DataService:get("upgrades") or {}
                    local range = GoopUtils.getRange(upgrades)
                    local closest
                    local dist = math.huge
                    for id, enemy in pairs(gameplay.enemies) do
                        if enemy and not enemy.dead and enemy.pos then
                            local mag = (enemy.pos - root.Position).Magnitude
                            if mag <= range and mag < dist then
                                dist = mag
                                closest = id
                            end
                        end
                    end
                    return closest
                end
                
                while _0x2c5d8f.Flags.GameSpamSlimeGun and _0x2c5d8f.Flags.GameSpamSlimeGun.CurrentValue do
                    local enemy = getClosestEnemy()
                    if enemy then
                        equipGun()
                        local camera = workspace.CurrentCamera
                        if camera then
                            local cx = camera.ViewportSize.X / 2
                            local cy = camera.ViewportSize.Y / 2
                            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                            VirtualInputManager:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                        end
                    end
                    local upgrades = DataService:get("upgrades") or {}
                    task.wait(GoopUtils.getFireRate(upgrades))
                end
                
                local char = LocalPlayer.Character
                if char then
                    local hum = char:FindFirstChildWhichIsA("Humanoid")
                    local tool = char:FindFirstChild("SlimeGun")
                    if hum and tool then
                        hum:UnequipTools()
                    end
                end
                VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.A, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.S, false, game)
                VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.D, false, game)
            end)
        end
    end,
})

local function _0x2c7f4a(_0x3e2c4a)
    return _0x3e2c4a.PrimaryPart
        or _0x3e2c4a:FindFirstChild("HumanoidRootPart")
        or _0x3e2c4a:FindFirstChild("RootPart")
        or _0x3e2c4a:FindFirstChildWhichIsA("BasePart")
end

local _0x3a8c2d = false
local _0x5d2c4a    = false
local _0x4f2c7a   = false

local _0x8c1a3d = {}
local _0x2e4b7a = {}
local _0x1a6c4d  = 0

local function _0x9b4c2e()
    local _0x1c4d8f = tick()
    if _0x1c4d8f - _0x1a6c4d < 0.5 then return end
    _0x1a6c4d = _0x1c4d8f

    local _0x3e2c7a = _0x3e2c8f()
    if not _0x3e2c7a then return end

    local _0x4d2f8a = _0x3e2c7a:FindFirstChild("Enemies")
    local _0x2b7c4e = _0x3e2c7a:FindFirstChild("Slimes")

    _0x8c1a3d = {}
    if _0x4d2f8a then
        for _, _0x1c4a7e in ipairs(_0x4d2f8a:GetChildren()) do
            if _0x1c4a7e:IsA("Model") then
                local _0x3e8d2a = _0x2c7f4a(_0x1c4a7e)
                if _0x3e8d2a then
                    table.insert(_0x8c1a3d, {model = _0x1c4a7e, root = _0x3e8d2a})
                end
            end
        end
    end

    _0x2e4b7a = {}
    if _0x2b7c4e then
        for _, _0x1b7d2a in ipairs(_0x2b7c4e:GetChildren()) do
            if _0x1b7d2a:IsA("Model") then
                local _0x2a7e4c = _0x2c7f4a(_0x1b7d2a)
                if _0x2a7e4c then
                    table.insert(_0x2e4b7a, {model = _0x1b7d2a, root = _0x2a7e4c, id = _0x1b7d2a.Name})
                end
            end
        end
    end
end

local _0x1c6f4a = nil

local function _0x5a8f2c(_0x3e2a6c)
    if not _0x3e2a6c or not _0x3e2a6c.Parent then return false end
    local _0x4d8f1a = _0x2c7f4a(_0x3e2a6c)
    if not _0x4d8f1a then return false end
    local _0x2e4b7a = _0x3e2a6c:FindFirstChildOfClass("Humanoid")
    if _0x2e4b7a and _0x2e4b7a.Health <= 0 then return false end
    return true
end

local function _0x3c4e2a(_0x1b4c7d)
    local _0xgameplay = _0x3e2c8f()
    if not _0xgameplay then return nil end
    local _0x1a4b7c = _0xgameplay:FindFirstChild("Enemies")
    if not _0x1a4b7c then return nil end
    local _0x3d6f2a, _0x2c8e4a = nil, math.huge
    for _, _0x1c7a2e in ipairs(_0x1a4b7c:GetChildren()) do
        if _0x1c7a2e:IsA("Model") and _0x5a8f2c(_0x1c7a2e) then
            local _0x5a3b8c = _0x2c7f4a(_0x1c7a2e)
            if _0x5a3b8c then
                local _0x1f6c4a = (_0x5a3b8c.Position - _0x1b4c7d).Magnitude
                if _0x1f6c4a < _0x2c8e4a then
                    _0x2c8e4a = _0x1f6c4a
                    _0x3d6f2a     = _0x1c7a2e
                end
            end
        end
    end
    return _0x3d6f2a
end

_0x3e2c7a_tab:CreateSection("Floating Enemies")

_0x3e2c7a_tab:CreateToggle({
    Name = "Float Enemies Around Player",
    CurrentValue = false,
    Flag = "GameFloatEnemies",
    Callback = function(_0x3c6a2d)
        _0x5d2c4a = _0x3c6a2d
    end,
})

_0x3e2c7a_tab:CreateSlider({
    Name = "Float Radius",
    Range = {5, 25},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 12,
    Flag = "GameFloatRadius",
    Callback = function(_0x2a7b4c) end,
})

_0x3e2c7a_tab:CreateSlider({
    Name = "Float Rotation Speed",
    Range = {0.5, 5},
    Increment = 0.1,
    Suffix = "x",
    CurrentValue = 1,
    Flag = "GameFloatSpeed",
    Callback = function(_0x4c2d7e) end,
})

_0x3e2c7a_tab:CreateSlider({
    Name = "Float Wave Speed",
    Range = {1, 10},
    Increment = 0.5,
    Suffix = "x",
    CurrentValue = 3,
    Flag = "GameFloatWaveSpeed",
    Callback = function(_0x1c5f8a) end,
})

_0x3e2c7a_tab:CreateSlider({
    Name = "Float Wave Height",
    Range = {0.5, 5},
    Increment = 0.5,
    Suffix = "studs",
    CurrentValue = 1.5,
    Flag = "GameFloatWaveHeight",
    Callback = function(_0x2d7e4a) end,
})

_0x3e2c7a_tab:CreateSection("Attack System")

_0x3e2c7a_tab:CreateToggle({
    Name = "Attack Floating Enemies",
    CurrentValue = false,
    Flag = "GameAttackEnemies",
    Callback = function(_0x8c3e2a)
        _0x4f2c7a = _0x8c3e2a
    end,
})

_0x3e2c7a_tab:CreateSlider({
    Name = "Attack Range",
    Range = {10, 50},
    Increment = 1,
    Suffix = "studs",
    CurrentValue = 25,
    Flag = "GameAttackRange",
    Callback = function(_0x4c2e6a) end,
})

_0x3e2c7a_tab:CreateSlider({
    Name = "Attack Lunge Speed",
    Range = {5, 30},
    Increment = 1,
    Suffix = "x",
    CurrentValue = 15,
    Flag = "GameAttackLungeSpeed",
    Callback = function(_0x3a7c2e) end,
})

local _0x4b2d7e = {}

local function _0x7c3e2a(_0x1f4c8a, _0x3a8d2c)
    if not _0x1f4c8a or not _0x1f4c8a.Parent then return end
    pcall(function()
        local _0x1c5f8a = _0x1f4c8a.PrimaryPart or _0x1f4c8a:FindFirstChildWhichIsA("BasePart")
        if _0x1c5f8a and not _0x1c5f8a:IsA("UnionOperation") then
            _0x1f4c8a:PivotTo(_0x3a8d2c)
        end
    end)
end

_0x1e5f3d.RenderStepped:Connect(function()
    if not _0x5d2c4a and not _0x4f2c7a then return end

    _0x9b4c2e()

    local _0x1c4f7a = _0x9a4b7c.Character
    local _0x7c2e4a  = _0x1c4f7a and _0x1c4f7a:FindFirstChild("HumanoidRootPart")
    if not _0x7c2e4a then return end

    local _0x1a4c7d         = tick()
    local _0x2a7b4c    = _0x2c5d8f.Flags.GameFloatRadius    and _0x2c5d8f.Flags.GameFloatRadius.CurrentValue    or 12
    local _0x3c2e7a  = _0x2c5d8f.Flags.GameFloatSpeed     and _0x2c5d8f.Flags.GameFloatSpeed.CurrentValue     or 1
    local _0x4d7e2a = _0x2c5d8f.Flags.GameFloatWaveSpeed and _0x2c5d8f.Flags.GameFloatWaveSpeed.CurrentValue or 3
    local _0x5a2c8f= _0x2c5d8f.Flags.GameFloatWaveHeight and _0x2c5d8f.Flags.GameFloatWaveHeight.CurrentValue or 1.5

    if _0x5d2c4a and #_0x8c1a3d > 0 then
        local _0x1b7c4d = #_0x8c1a3d
        for _0x1a3c6d, _0x3e7a2c in ipairs(_0x8c1a3d) do
            local _0x2c7e4a        = ((_0x1a3c6d / _0x1b7c4d) * math.pi * 2) + (_0x1a4c7d * _0x3c2e7a)
            local _0x4d2f8a = math.sin((_0x1a4c7d * _0x4d7e2a) + _0x1a3c6d) * _0x5a2c8f

            local _0x3f6a2c = _0x7c2e4a.Position + Vector3.new(
                math.cos(_0x2c7e4a) * _0x2a7b4c,
                _0x4d2f8a + 2,
                math.sin(_0x2c7e4a) * _0x2a7b4c
            )

            local _0x2e4c7a = (_0x3f6a2c - _0x7c2e4a.Position).Unit
            _0x7c3e2a(_0x3e7a2c.model, CFrame.lookAt(_0x3f6a2c, _0x3f6a2c + _0x2e4c7a))
        end
    end

    if _0x4f2c7a and #_0x2e4b7a > 0 and #_0x8c1a3d > 0 then
        local _0x3c6d2a = _0x2c5d8f.Flags.GameAttackRange     and _0x2c5d8f.Flags.GameAttackRange.CurrentValue     or 25
        local _0x6b2c4f  = _0x2c5d8f.Flags.GameAttackLungeSpeed and _0x2c5d8f.Flags.GameAttackLungeSpeed.CurrentValue or 15

        local _0x1e4c6a = #_0x2e4b7a
        for _0x1a3c6d, _0x2e4c7a in ipairs(_0x2e4b7a) do
            local _0x1c4d8f   = ((_0x1a3c6d / _0x1e4c6a) * math.pi * 2) + (_0x1a4c7d * _0x3c2e7a)
            local _0x7d2c4e = math.sin((_0x1a4c7d * _0x4d7e2a) + _0x1a3c6d) * _0x5a2c8f

            local _0x3f6a2c = _0x7c2e4a.Position + Vector3.new(
                math.cos(_0x1c4d8f) * _0x2a7b4c,
                _0x7d2c4e + 2,
                math.sin(_0x1c4d8f) * _0x2a7b4c
            )

            local _0x5c2d7a, _0x1c7d3a = nil, _0x3c6d2a
            for _, _0x1c4a7e in ipairs(_0x8c1a3d) do
                local _0x2a6d4c = (_0x3f6a2c - _0x1c4a7e.root.Position).Magnitude
                if _0x2a6d4c < _0x1c7d3a then
                    _0x1c7d3a  = _0x2a6d4c
                    _0x5c2d7a = _0x1c4a7e
                end
            end

            local _0x7e2a4c  = _0x3f6a2c
            local _0x1b6d4a = _0x3f6a2c + (_0x3f6a2c - _0x7c2e4a.Position).Unit

            if _0x5c2d7a then
                if not _0x4b2d7e[_0x2e4c7a.id] then
                    _0x4b2d7e[_0x2e4c7a.id] = _0x1a4c7d
                end

                local _0x5f2c7a   = _0x1a4c7d - _0x4b2d7e[_0x2e4c7a.id]
                local _0x8c3e2a = math.sin(_0x5f2c7a * _0x6b2c4f)

                if _0x8c3e2a > 0 then
                    _0x7e2a4c   = _0x3f6a2c:Lerp(_0x5c2d7a.root.Position, _0x8c3e2a * 0.85)
                    _0x1b6d4a = _0x5c2d7a.root.Position
                else
                    _0x4b2d7e[_0x2e4c7a.id] = _0x1a4c7d
                end
            else
                _0x4b2d7e[_0x2e4c7a.id] = nil
            end

            _0x7c3e2a(_0x2e4c7a.model, CFrame.lookAt(_0x7e2a4c, _0x1b6d4a))
        end
    end
end)

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
                        pcall(_0x1b6d8f.InvokeServer, _0x1b6d8f, "redeem", _0x2a7b4c)
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
                    pcall(_0x3e7a2c_remote.InvokeServer, _0x3e7a2c_remote, "requestClaim")
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
                                    pcall(_0x6f1a8d.InvokeServer, _0x6f1a8d, "requestClaimReward", _0x5c3e2a)
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
                            pcall(_0x8b1d4f.InvokeServer, _0x8b1d4f, "requestUseBoost", _0x2c4f8a)
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
                            pcall(_0x9c3a2e.InvokeServer, _0x9c3a2e, "requestUseItem", _0x1b4c6a)
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
        local _0x3e4a2c, _0x1a6b4c = pcall(function()
            request({
                Url = _0x1d3f6a,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = _0x2b6f8e:JSONEncode({
                    content  = _0x4d7c2a,
                    username = "Cactus Hub",
                    embeds   = {{
                        title       = "✅ Webhook Test",
                        description = "Your webhook is working correctly!",
                        color       = 0x2ecc71,
                    }}
                })
            })
        end)
        _0x2c5d8f:Notify({
            Title   = "Webhook",
            Content = _0x3e4a2c and "Test sent successfully!" or "Failed: " .. (_0x1a6b4c or "unknown"),
            Duration = 4,
        })
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
                local _0x4f7a2c, _0x2c6d8a = pcall(_0x8d1f4a.rollResults)
                if not _0x4f7a2c or type(_0x2c6d8a) ~= "table" or #_0x2c6d8a == 0 then
                    task.wait(0.5)
                else
                    local _0x1a6d4f = _0x9b2c4e(_0x2c6d8a)
                    if _0x1a6d4f ~= _0x7b2c4f then
                        _0x7b2c4f = _0x1a6d4f

                        local _0x7e2a4c = _0x2c5d8f.Flags.WebhookSendAll and _0x2c5d8f.Flags.WebhookSendAll.CurrentValue
                        local _0x1f4a3c = _0x2c5d8f.Flags.WebhookSendNew and _0x2c5d8f.Flags.WebhookSendNew.CurrentValue
                        local _0x3c8a2d = _0x2c5d8f.Flags.WebhookSendMutated and _0x2c5d8f.Flags.WebhookSendMutated.CurrentValue

                        for _, _0x3f8c2a in ipairs(_0x2c6d8a) do
                            local _0x2c4e7a = _0x7c5f2a(_0x3f8c2a)
                            if _0x2c4e7a then
                                local _0x1d4c8f = tostring(_0x2c4e7a.id or "")
                                if _0x1d4c8f ~= "" then
                                    local _0x4d2c8f = type(_0x2c4e7a.mutations) == "table" and next(_0x2c4e7a.mutations) ~= nil and _0x2c4e7a.mutations or nil
                                    local _0x2a3b7c, _0x3e7a2c = pcall(_0x6f3a2c.getSlime, _0x1d4c8f)
                                    local _0x1d8f2a = _0x2a3b7c and _0x3e7a2c or nil

                                    local _0x1b4c7d = _0x4d2c8f ~= nil
                                    local _0x7c3d2a = _0x1a7c4f(_0x1d4c8f, _0x4d2c8f)

                                    local _0x3e2c7a = _0x7e2a4c or (_0x1f4a3c and _0x7c3d2a) or (_0x3c8a2d and _0x1b4c7d and _0x4f2a8c_filter(_0x4d2c8f))

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
    Name = "Anti AFK",
    CurrentValue = true,
    Flag = "SettingsAntiAFK",
    Callback = function(Value)
        if Value then
            for _, x in pairs(getconnections(_0x9a4b7c.Idled)) do
                x:Disable()
            end
        else
            for _, x in pairs(getconnections(_0x9a4b7c.Idled)) do
                x:Enable()
            end
        end
    end,
})

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
    if sethiddenproperty then pcall(sethiddenproperty, obj, prop, val) end
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
        pcall(function() v.Material = CHEAP_MATERIAL end)
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
        pcall(function()
            local clouds = terrain:FindFirstChildOfClass("Clouds")
            if clouds then clouds:Destroy() end
            terrain.WaterWaveSize = 0
            terrain.WaterWaveSpeed = 0
            terrain.WaterReflectance = 0
            terrain.WaterTransparency = 1
        end)
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
    pcall(function()
        local sg = game:GetService("StarterGui")
        sg:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
        sg:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
        sg:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
    end)
end

local function _optRenderQuality()
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

local function _cleanOptConnections()
    for _, c in ipairs(_optConnections) do pcall(c.Disconnect, c) end
    table.clear(_optConnections)
end

_0x7d2c4a_tab:CreateToggle({
    Name = "Optimize All (Full)",
    CurrentValue = false,
    Flag = "OptimizeAll",
    Callback = function(Value)
        if Value then
            _cleanOptConnections()
            _optRenderQuality()
            _optLighting()
            _optCamera()
            _optGUI()
            _optWorkspaceScan()
            _optPlayers()
            _optApplied = true
        else
            _cleanOptConnections()
        end
    end,
})

_0x7d2c4a_tab:CreateToggle({
    Name = "Optimize GPU (Low Graphics)",
    CurrentValue = false,
    Flag = "OptimizeGPU",
    Callback = function(Value)
        if Value then
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

_0x7d2c4a_tab:CreateToggle({
    Name = "Remove All Particles & Effects",
    CurrentValue = false,
    Flag = "OptimizeParticles",
    Callback = function(Value)
        if Value then
            for _, v in ipairs(game:GetDescendants()) do
                if OPT_VISUAL_TYPES[v.ClassName] then
                    pcall(v.Destroy, v)
                end
            end
        end
    end,
})

_0x7d2c4a_tab:CreateToggle({
    Name = "Remove Fire Effects",
    CurrentValue = false,
    Flag = "FireOptimization",
    Callback = function(Value)
        if Value then
            for _, v in ipairs(game:GetDescendants()) do
                if v:IsA("Fire") then pcall(v.Destroy, v) end
            end
        end
    end,
})

_0x7d2c4a_tab:CreateToggle({
    Name = "Lua GC (Memory Cleaner)",
    CurrentValue = false,
    Flag = "LuaGC",
    Callback = function(Value)
        if Value then
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

_0x9a4b7c.Idled:Connect(function()
    if _0x2c5d8f.Flags.SettingsAntiAFK and _0x2c5d8f.Flags.SettingsAntiAFK.CurrentValue then
        _0x7d2c9a:CaptureController()
        _0x7d2c9a:ClickButton2(Vector2.new())
    end
end)

game:GetService("GuiService").ErrorMessageChanged:Connect(function()
    if _0x2c5d8f.Flags.SettingsAutoRejoin and _0x2c5d8f.Flags.SettingsAutoRejoin.CurrentValue then
        game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, _0x9a4b7c)
    end
end)

_0x2c5d8f:LoadConfiguration()
