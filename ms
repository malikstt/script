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
    Title = "Malik no",
    SubTitle = "lmklmk",
    TabWidth = 160,
    Size = UDim2.fromOffset(viewport.X * 0.55, viewport.Y * 0.35),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

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
        print("Shops selected")
    end
})

Tabs.Main:AddToggle("RegisterToggle", {
    Title = "Cycle Between Shops",
    Default = false,
    Callback = function(v)
        shopSpamEnabled = v
        shopIndex = 1
        print("Cycle:", v)
    end
})

local function teleportToShop(playerName)

    local char = LocalPlayer.Character
    if not char then return end

    local plr = Players:FindFirstChild(playerName)
    if not plr then
        print("Teleport failed player missing:", playerName)
        return
    end

    local floor = plr.NonSaveVars.DefaultFloor.Value
    if not floor then
        print("Teleport failed floor missing:", playerName)
        return
    end

    local canvas = floor:FindFirstChild("Canvas")
    if not canvas then
        print("Teleport failed canvas missing:", playerName)
        return
    end

    char:SetPrimaryPartCFrame(canvas.CFrame + Vector3.new(0,3,0))
    print("Teleported to:", playerName)

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
        print("Send targets updated")
    end
})

Tabs.Main:AddDropdown("OfferPercent", {
    Title = "Offer Percent",
    Values = {"+50%","-50%"},
    Default = "+50%",
    Callback = function(v)
        offerPercent = v == "+50%" and 50 or -50
        print("Offer percent set:", offerPercent)
    end
})

Tabs.Main:AddToggle("SendToggle", {
    Title = "Send Offers",
    Default = false,
    Callback = function(v)
        sendEnabled = v
        print("Send enabled:", v)
    end
})

local function buildPlacedMap(plot)

    local map = {}

    local furniture = plot:FindFirstChild("Furniture")
    if not furniture then
        print("Furniture missing")
        return map
    end

    for _, v in ipairs(furniture:GetDescendants()) do

        if v.Name == "Item" then

            for _, obj in ipairs(v:GetChildren()) do

                map[obj.Name] = map[obj.Name] or {}
                table.insert(map[obj.Name], obj)

            end

        end

    end

    return map

end

local function SendOffersFunction()

    if not sendEnabled then return end

    for playerName, state in pairs(sendPlayers) do

        if not state then continue end

        local target = Players:FindFirstChild(playerName)

        if not target then
            print("Player missing:", playerName)
            continue
        end

        local data

        local success, err = pcall(function()
            data = GetInventoryRemote:InvokeServer("Inventory", target)
        end)

        if not success or not data or not data.Inventory then
            print("Inventory failed:", playerName)
            continue
        end

        local plotValue = target.NonSaveVars.OwnsPlot.Value

        if not plotValue then
            print("Plot missing:", playerName)
            continue
        end

        local placedMap = buildPlacedMap(plotValue)

        local count = 0

        for guid, itemData in pairs(data.Inventory) do

            if not itemData.ItemPlaced then
                continue
            end

            local itemInfo = ItemsModule[itemData.Id]

            if not itemInfo then
                print("Item info missing:", itemData.Id)
                continue
            end

            local placedList = placedMap[itemInfo.Name]

            if not placedList or #placedList == 0 then
                print("Instance missing:", itemInfo.Name)
                continue
            end

            local instance = table.remove(placedList,1)

            local price

            local ok = pcall(function()
                price = RepLibrary:GetItemPrice(itemData)
            end)

            if not ok or not price then
                print("Price failed:", itemInfo.Name)
                continue
            end

            local offerPrice = math.floor(price * (1 + offerPercent / 100))

            local worked, err2 = pcall(function()

                MakeOfferRemote:InvokeServer(
                    target,
                    guid,
                    offerPrice,
                    instance
                )

            end)

            if worked then
                print("SUCCESS:", playerName, itemInfo.Name, offerPrice)
                count += 1
            else
                print("FAILED:", err2)
            end

            task.wait(0.25)

        end

        print("Total offers sent to", playerName, count)

    end

end

task.spawn(function()

    while true do

        pcall(SendOffersFunction)

        task.wait(1)

    end

end)

local acceptAny = false

Tabs.Main:AddToggle("AcceptAny", {
    Title = "Accept Any",
    Default = false,
    Callback = function(v)
        acceptAny = v
        print("Accept any:", v)
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

                    print("Accepted:", from, guid, price)

                end

            end

        end

        task.wait(1)

    end

end)

local placeEnabled = false

Tabs.Main:AddToggle("PlaceToggle", {
    Title = "Place Items",
    Default = false,
    Callback = function(v)
        placeEnabled = v
        print("Place enabled:", v)
    end
})

task.spawn(function()

    while true do

        if placeEnabled then

            local myData = GetInventoryRemote:InvokeServer()

            local plot = LocalPlayer.NonSaveVars.OwnsPlot.Value

            if not plot then
                print("Your plot missing")
                task.wait(2)
                continue
            end

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

                    print("Placed:", guid)

                    index += 1

                    task.wait(0.25)

                end

            end

        end

        task.wait(2)

    end

end)

Window:SelectTab(Tabs.Main)
