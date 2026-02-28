local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local MakeOfferRemote = ReplicatedStorage.Events.Shop.MakePlayerOffer
local GetInventoryRemote = ReplicatedStorage.Events.Data.GetAll
local AcceptRemote = ReplicatedStorage.Events.Shop.AcceptPlayerOffer
local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize

local Window = Fluent:CreateWindow({
    Title = "Shop & Player Manager",
    SubTitle = "Full Fixed System",
    TabWidth = 160,
    Size = UDim2.fromOffset(viewport.X * 0.55, viewport.Y * 0.35),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

--------------------------------------------------
-- PLAYER LIST FUNCTIONS
--------------------------------------------------

local function getAllPlayerNames()

    local t = {}

    for _, p in ipairs(Players:GetPlayers()) do
        table.insert(t, p.Name)
    end

    return t
end

local function getOtherPlayerNames()

    local t = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end

    return t
end

--------------------------------------------------
-- SHOP CYCLER
--------------------------------------------------

local selectedShops = {}
local shopSpamEnabled = false
local shopIndex = 1

Tabs.Main:AddDropdown("RegisterPlayers", {
    Title = "Select Shops",
    Values = getAllPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(v)
        selectedShops = v
    end
})

Tabs.Main:AddToggle("RegisterToggle", {
    Title = "Cycle Between Shops",
    Default = false,
    Callback = function(v)
        shopSpamEnabled = v
        shopIndex = 1
    end
})

local function teleportToShop(playerName)

    local char = LocalPlayer.Character
    if not char then return end

    local plr = Players:FindFirstChild(playerName)
    if not plr then return end

    local floor = plr.NonSaveVars.DefaultFloor.Value
    if not floor then return end

    local canvas = floor:FindFirstChild("Canvas")
    if not canvas then return end

    char:SetPrimaryPartCFrame(canvas.CFrame + Vector3.new(0,3,0))

end

task.spawn(function()

    while true do

        if shopSpamEnabled then

            local shopNames = {}

            for name, enabled in pairs(selectedShops) do
                if enabled then
                    table.insert(shopNames, name)
                end
            end

            if #shopNames > 0 then

                if shopIndex > #shopNames then
                    shopIndex = 1
                end

                teleportToShop(shopNames[shopIndex])

                shopIndex += 1

            end

        end

        task.wait(0.25)

    end

end)

--------------------------------------------------
-- SEND OFFERS (FULLY FIXED)
--------------------------------------------------

local sendPlayers = {}
local sendEnabled = false
local offerPercent = 50

Tabs.Main:AddDropdown("SendPlayers", {
    Title = "Send To Players",
    Values = getOtherPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(v)
        sendPlayers = v
    end
})

Tabs.Main:AddDropdown("OfferPercent", {
    Title = "Offer Percent",
    Values = {"+50%","-50%"},
    Default = "+50%",
    Callback = function(v)
        offerPercent = v == "+50%" and 50 or -50
    end
})

Tabs.Main:AddToggle("SendToggle", {
    Title = "Send Offers",
    Default = false,
    Callback = function(v)
        sendEnabled = v
    end
})

local function SendOffersFunction()

    if not sendEnabled then return end

    for playerName, state in pairs(sendPlayers) do

        if not state then continue end

        local target = Players:FindFirstChild(playerName)
        if not target then continue end

        local inv = GetInventoryRemote:InvokeServer("Inventory", target)
        if type(inv) ~= "table" then continue end

        local plot = target.NonSaveVars.OwnsPlot.Value
        if not plot then continue end

        local furniture = plot:FindFirstChild("Furniture")
        if not furniture then continue end

        local placedMap = {}

        for _, v in pairs(furniture:GetDescendants()) do

            if v.Name == "Item" then

                for _, item in pairs(v:GetChildren()) do

                    placedMap[item.Name] = placedMap[item.Name] or {}

                    table.insert(placedMap[item.Name], item)

                end

            end

        end

        for guid, itemData in pairs(inv) do

            local itemInfo = ItemsModule[itemData.Id]
            if not itemInfo then continue end

            local placedInstances = placedMap[itemInfo.Name]

            if placedInstances and #placedInstances > 0 then

                local instance = table.remove(placedInstances,1)

                local price = RepLibrary:GetItemPrice(itemData)

                local offerPrice = math.floor(price * (1 + offerPercent/100))

                MakeOfferRemote:InvokeServer(
                    target,
                    guid,
                    offerPrice,
                    instance
                )

                print("Offered", itemInfo.Name, "for", offerPrice)

                task.wait(1)

            end

        end

    end

end

task.spawn(function()

    while true do

        pcall(SendOffersFunction)

        task.wait(1)

    end

end)

--------------------------------------------------
-- ACCEPT OFFERS
--------------------------------------------------

local acceptAny = false

Tabs.Main:AddToggle("AcceptAny", {
    Title = "Accept Any",
    Default = false,
    Callback = function(v)
        acceptAny = v
    end
})

task.spawn(function()

    while true do

        if acceptAny then

            for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do

                local from = gui:GetAttribute("OfferFromPlayerName")
                local guid = gui:GetAttribute("GUID")
                local price = gui:GetAttribute("Offer")

                if from and guid and price then

                    AcceptRemote:InvokeServer(from,guid,price)

                    print("Accepted offer")

                end

            end

        end

        task.wait(1)

    end

end)

--------------------------------------------------
-- PLACE ITEMS
--------------------------------------------------

local placeEnabled = false

Tabs.Main:AddToggle("PlaceToggle", {
    Title = "Place Items",
    Default = false,
    Callback = function(v)
        placeEnabled = v
    end
})

task.spawn(function()

    while true do

        if placeEnabled then

            local myData = GetInventoryRemote:InvokeServer()

            local plot = LocalPlayer.NonSaveVars.OwnsPlot.Value

            local shelves = {}

            for _, v in pairs(plot.Furniture:GetDescendants()) do
                if v.Name == "Shelf" then
                    table.insert(shelves,v)
                end
            end

            local index = 1

            for guid, info in pairs(myData.Inventory) do

                if not info.ItemPlaced and shelves[index] then

                    SellRemote:FireServer(
                        guid,
                        shelves[index],
                        true
                    )

                    index += 1

                    task.wait(0.25)

                end

            end

        end

        task.wait(2)

    end

end)

Window:SelectTab(Tabs.Main)
