local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local MakeOfferRemote = ReplicatedStorage.Events.Shop.MakePlayerOffer
local GetInventoryRemote = ReplicatedStorage.Events.Data.Get
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
        print("Shops updated")
    end
})

Tabs.Main:AddToggle("RegisterToggle", {
    Title = "Cycle Between Shops",
    Default = false,
    Callback = function(v)
        shopSpamEnabled = v
        shopIndex = 1
        print("Shop cycling:", v)
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

    print("Teleported to", playerName)

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
        print("Send players updated")
    end
})

Tabs.Main:AddDropdown("OfferPercent", {
    Title = "Offer Percent",
    Values = {"+50%","-50%"},
    Default = "+50%",
    Callback = function(v)
        offerPercent = v == "+50%" and 50 or -50
        print("Offer percent set to", offerPercent)
    end
})

Tabs.Main:AddToggle("SendToggle", {
    Title = "Send Offers",
    Default = false,
    Callback = function(v)
        sendEnabled = v
        print("Send offers:", v)
    end
})

local function getPlacedMap(plot)

    local map = {}

    local furniture = plot:FindFirstChild("Furniture")
    if not furniture then return map end

    for _,v in pairs(furniture:GetDescendants()) do
        if v.Name == "Item" then
            for _,item in pairs(v:GetChildren()) do
                map[item.Name] = map[item.Name] or {}
                table.insert(map[item.Name], item)
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
            print("Player not found", playerName)
            continue
        end

        local ok, inv = pcall(function()
            return GetInventoryRemote:InvokeServer("Inventory", target)
        end)

        if not ok or type(inv) ~= "table" then
            print("Inventory failed", playerName)
            continue
        end

        local plotVal = target.NonSaveVars and target.NonSaveVars.OwnsPlot

        if not plotVal or not plotVal.Value then
            print("Plot missing", playerName)
            continue
        end

        local placedMap = getPlacedMap(plotVal.Value)

        for guid, itemData in pairs(inv) do

            local info = ItemsModule[itemData.Id]

            if info then

                local placed = placedMap[info.Name]

                if placed and #placed > 0 then

                    local instance = table.remove(placed,1)

                    local price = RepLibrary:GetItemPrice(itemData)

                    local offer = math.floor(price * (1 + offerPercent/100))

                    local success = pcall(function()

                        MakeOfferRemote:InvokeServer(
                            target,
                            guid,
                            offer,
                            instance
                        )

                    end)

                    if success then
                        print("Offer sent", info.Name, offer, playerName)
                    else
                        print("Offer failed", info.Name, playerName)
                    end

                    task.wait(0.5)

                end

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

                    print("Accepted offer", guid, price)

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
        print("Place items:", v)
    end
})

task.spawn(function()

    while true do

        if placeEnabled then

            local ok, myData = pcall(function()
                return GetInventoryRemote:InvokeServer("Inventory", LocalPlayer)
            end)

            if ok and type(myData) == "table" then

                local plot = LocalPlayer.NonSaveVars.OwnsPlot.Value

                local shelves = {}

                for _, v in pairs(plot.Furniture:GetDescendants()) do
                    if v.Name == "Shelf" then
                        table.insert(shelves,v)
                    end
                end

                local index = 1

                for guid, info in pairs(myData) do

                    if not info.ItemPlaced and shelves[index] then

                        SellRemote:FireServer(
                            guid,
                            shelves[index],
                            true
                        )

                        print("Placed item", guid)

                        index += 1

                        task.wait(0.25)

                    end

                end

            end

        end

        task.wait(2)

    end

end)

Window:SelectTab(Tabs.Main)
