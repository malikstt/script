--// LOAD UI LIBRARY
-- Creates the Fluent UI window system used for all controls
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

--// SERVICES
-- Core Roblox services used throughout the script
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// PLAYER REFERENCES
-- LocalPlayer is you
local LocalPlayer = Players.LocalPlayer

--// GAME MODULES
-- RepLibrary handles pricing
-- ItemsModule contains item info
local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

--// WINDOW SIZE BASED ON SCREEN SIZE
local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize
local winSize = UDim2.fromOffset(viewport.X * 0.60, viewport.Y * 0.30)

--// CREATE WINDOW
local Window = Fluent:CreateWindow({
    Title = "Shop & Player Manager",
    SubTitle = "Parallel System",
    TabWidth = 160,
    Size = winSize,
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

--// PLAYER LIST FUNCTIONS

-- Returns ALL players including you
local function getAllPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(t, p.Name)
    end
    return t
end

-- Returns all players except you
local function getOtherPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end
    return t
end

----------------------------------------------------------------
-- SHOP REGISTRATION SYSTEM
-- This makes the game think you are inside selected shops
-- Uses firetouchinterest instead of teleporting
-- Allows being "registered" in multiple shops at once
----------------------------------------------------------------

local registerPlayers = {}
local registerEnabled = false

Tabs.Main:AddDropdown("RegisterPlayers", {
    Title = "Select Shops",
    Values = getAllPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        registerPlayers = Value
    end
})

Tabs.Main:AddToggle("RegisterToggle", {
    Title = "Register In Shops",
    Default = false,
    Callback = function(Value)
        registerEnabled = Value
    end
})

local function registerShop(playerName)

    local char = LocalPlayer.Character
    if not char then return end

    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local plr = Players:FindFirstChild(playerName)
    if not plr then return end

    local owns = plr:FindFirstChild("NonSaveVars")
    if not owns then return end

    local plotVal = owns:FindFirstChild("OwnsPlot")
    if not plotVal then return end

    local plot = plotVal.Value
    if typeof(plot) ~= "Instance" then return end

    local door = plot:FindFirstChild("Door", true)
    if not door then return end

    local startPart = door:FindFirstChild("StartPart")
    if not startPart then return end

    firetouchinterest(root, startPart, 0)
    firetouchinterest(root, startPart, 1)

end

task.spawn(function()
    while true do

        if registerEnabled then

            for name, state in pairs(registerPlayers) do

                if state then
                    pcall(function()
                        registerShop(name)
                    end)
                end

            end

        end

        task.wait(0.5)

    end
end)

----------------------------------------------------------------
-- SEND OFFERS SYSTEM
-- Sends offers automatically to selected players
----------------------------------------------------------------

local sendPlayers = {}
local sendEnabled = false
local offerPercent = 50

Tabs.Main:AddDropdown("SendPlayers", {
    Title = "Send To Players",
    Values = getOtherPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        sendPlayers = Value
    end
})

Tabs.Main:AddDropdown("OfferPercent", {
    Title = "Offer Percent",
    Values = {"+50%", "-50%"},
    Default = "+50%",
    Callback = function(Value)
        offerPercent = Value == "+50%" and 50 or -50
    end
})

Tabs.Main:AddToggle("SendToggle", {
    Title = "Send Offers",
    Default = false,
    Callback = function(Value)
        sendEnabled = Value
    end
})

local MakeOfferRemote = ReplicatedStorage.Events.Shop.MakePlayerOffer
local GetInventoryRemote = ReplicatedStorage.Events.Data.Get

task.spawn(function()

    while true do

        if sendEnabled then

            for name, state in pairs(sendPlayers) do

                if state then

                    pcall(function()

                        local target = Players:FindFirstChild(name)
                        if not target then return end

                        local inv = GetInventoryRemote:InvokeServer("Inventory", target)
                        if type(inv) ~= "table" then return end

                        local plot = target.NonSaveVars.OwnsPlot.Value
                        if not plot then return end

                        local instances = {}

                        for _, v in pairs(plot:GetDescendants()) do
                            if v.Name == "Item" then
                                for _, item in pairs(v:GetChildren()) do
                                    table.insert(instances, item)
                                end
                            end
                        end

                        local map = {}

                        for _, inst in pairs(instances) do
                            map[inst.Name] = map[inst.Name] or {}
                            table.insert(map[inst.Name], inst)
                        end

                        for guid, data in pairs(inv) do

                            local info = ItemsModule[data.Id]
                            if info then

                                local match = map[info.Name]

                                if match and #match > 0 then

                                    local instance = table.remove(match,1)

                                    local real = RepLibrary:GetItemPrice(data)

                                    local price = math.floor(real * (1 + offerPercent/100))

                                    MakeOfferRemote:InvokeServer(target,guid,price,instance)

                                    break
                                end
                            end
                        end

                    end)

                end
            end
        end

        task.wait(1)

    end

end)

----------------------------------------------------------------
-- ACCEPT OFFERS SYSTEM
-- Accepts incoming offers automatically
----------------------------------------------------------------

local acceptAny = false
local acceptPlayer = ""
local acceptSpecific = false

Tabs.Main:AddToggle("AcceptAny", {
    Title = "Accept Any",
    Default = false,
    Callback = function(v)
        acceptAny = v
    end
})

Tabs.Main:AddDropdown("AcceptPlayer", {
    Title = "Accept From Player",
    Values = getOtherPlayerNames(),
    Default = "",
    Callback = function(v)
        acceptPlayer = v
    end
})

Tabs.Main:AddToggle("AcceptSpecific", {
    Title = "Accept Selected Player",
    Default = false,
    Callback = function(v)
        acceptSpecific = v
    end
})

local AcceptRemote = ReplicatedStorage.Events.Shop.AcceptPlayerOffer

local function acceptLoop()

    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do

        local from = gui:GetAttribute("OfferFromPlayerName")
        local guid = gui:GetAttribute("GUID")
        local price = gui:GetAttribute("Offer")

        if from and guid and price then

            if acceptAny or (acceptSpecific and from == acceptPlayer) then

                pcall(function()
                    AcceptRemote:InvokeServer(from,guid,price)
                end)

            end
        end
    end
end

task.spawn(function()

    while true do

        pcall(acceptLoop)

        task.wait(1)

    end

end)

----------------------------------------------------------------
-- PLACE ITEMS SYSTEM
-- Automatically places inventory items on shelves
----------------------------------------------------------------

local placeEnabled = false

Tabs.Main:AddToggle("PlaceToggle", {
    Title = "Place Items",
    Default = false,
    Callback = function(v)
        placeEnabled = v
    end
})

local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop
local GetAllRemote = ReplicatedStorage.Events.Data.GetAll

task.spawn(function()

    while true do

        if placeEnabled then

            pcall(function()

                local data = GetAllRemote:InvokeServer()

                local plot = LocalPlayer.NonSaveVars.OwnsPlot.Value

                local shelves = {}

                for _, f in pairs(plot.Furniture:GetChildren()) do
                    local s = f:FindFirstChild("Shelves")
                    if s then
                        for _, shelf in pairs(s:GetChildren()) do
                            table.insert(shelves,shelf)
                        end
                    end
                end

                local guids = {}

                for guid, info in pairs(data.Inventory) do
                    table.insert(guids,guid)
                end

                for i=1, math.min(#guids,#shelves) do

                    SellRemote:FireServer(guids[i],shelves[i],true)

                    task.wait(0.1)

                end

            end)

        end

        task.wait(1)

    end

end)

Window:SelectTab(Tabs.Main)
