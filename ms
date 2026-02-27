local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize
local winSize = UDim2.fromOffset(viewport.X * 0.55, viewport.Y * 0.35)

local Window = Fluent:CreateWindow({
    Title = "Shop & Player Manager",
    SubTitle = "Fixed Offer System",
    TabWidth = 160,
    Size = winSize,
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

----------------------------------------------------------------
-- PLAYER LIST FUNCTIONS
----------------------------------------------------------------

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

----------------------------------------------------------------
-- SHOP CYCLER
----------------------------------------------------------------

local selectedShops = {}
local shopSpamEnabled = false
local shopIndex = 1

Tabs.Main:AddDropdown("RegisterPlayers", {
    Title = "Select Shops",
    Values = getAllPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        selectedShops = Value
    end
})

Tabs.Main:AddToggle("RegisterToggle", {
    Title = "Cycle Between Shops",
    Default = false,
    Callback = function(Value)
        shopSpamEnabled = Value
        shopIndex = 1
    end
})

local function teleportToShop(playerName)

    local char = LocalPlayer.Character
    if not char then return end

    local plr = Players:FindFirstChild(playerName)
    if not plr then return end

    local nonSaveVars = plr:FindFirstChild("NonSaveVars")
    if not nonSaveVars then return end

    local defaultFloor = nonSaveVars:FindFirstChild("DefaultFloor")
    if not defaultFloor then return end

    local floor = defaultFloor.Value
    if not floor then return end

    local canvas = floor:FindFirstChild("Canvas")
    if not canvas then return end

    char:SetPrimaryPartCFrame(canvas.CFrame + Vector3.new(0,3,0))

end

task.spawn(function()

    while true do

        if shopSpamEnabled and next(selectedShops) then

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

----------------------------------------------------------------
-- SEND OFFERS (FIXED VERSION)
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

local function getShelfItems(plot)

    local t = {}

    for _, v in pairs(plot:GetDescendants()) do

        if v.Name == "Item" and (v:IsA("Model") or v:IsA("BasePart")) then
            table.insert(t, v)
        end

    end

    return t

end

local function calculatePrice(itemInstance)

    local itemId = itemInstance:GetAttribute("ItemId")

    if not itemId then return nil end

    local itemInfo = ItemsModule[itemId]

    if not itemInfo then return nil end

    local basePrice = itemInfo.Price or 0

    local offerPrice = math.floor(basePrice * (1 + offerPercent / 100))

    return offerPrice

end

task.spawn(function()

    while true do

        if sendEnabled then

            for playerName, enabled in pairs(sendPlayers) do

                if enabled then

                    local target = Players:FindFirstChild(playerName)

                    if target then

                        local nonSaveVars = target:FindFirstChild("NonSaveVars")

                        if nonSaveVars then

                            local plotVal = nonSaveVars:FindFirstChild("OwnsPlot")

                            if plotVal and typeof(plotVal.Value) == "Instance" then

                                local plot = plotVal.Value

                                local shelves = getShelfItems(plot)

                                for _, shelfItem in ipairs(shelves) do

                                    local price = calculatePrice(shelfItem)

                                    if price then

                                        pcall(function()

                                            MakeOfferRemote:InvokeServer(
                                                target,
                                                nil,
                                                price,
                                                shelfItem
                                            )

                                        end)

                                        print("Offered", price, "for", shelfItem.Name, "from", target.Name)

                                        task.wait(1)

                                    end

                                end

                            end

                        end

                    end

                end

            end

        end

        task.wait(1)

    end

end)

----------------------------------------------------------------
-- ACCEPT OFFERS
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

task.spawn(function()

    while true do

        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do

            local from = gui:GetAttribute("OfferFromPlayerName")
            local guid = gui:GetAttribute("GUID")
            local price = gui:GetAttribute("Offer")

            if from and guid and price then

                if acceptAny or (acceptSpecific and from == acceptPlayer) then

                    pcall(function()
                        AcceptRemote:InvokeServer(from, guid, price)
                    end)

                    print("Accepted offer from", from)

                end

            end

        end

        task.wait(1)

    end

end)

----------------------------------------------------------------
-- PLACE ITEMS
----------------------------------------------------------------

local placeEnabled = false

Tabs.Main:AddToggle("PlaceToggle", {
    Title = "Place Items",
    Default = false,
    Callback = function(v)
        placeEnabled = v
    end
})

local GetAllRemote = ReplicatedStorage.Events.Data.GetAll
local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop

task.spawn(function()

    while true do

        if placeEnabled then

            local myData = GetAllRemote:InvokeServer()

            if myData and myData.Inventory then

                local nonSaveVars = LocalPlayer:FindFirstChild("NonSaveVars")

                if nonSaveVars then

                    local plotVal = nonSaveVars:FindFirstChild("OwnsPlot")

                    if plotVal then

                        local plot = plotVal.Value

                        local shelves = {}

                        for _, f in pairs(plot.Furniture:GetChildren()) do

                            local s = f:FindFirstChild("Shelves")

                            if s then

                                for _, shelf in pairs(s:GetChildren()) do
                                    table.insert(shelves, shelf)
                                end

                            end

                        end

                        local availableGuids = {}

                        for guid, info in pairs(myData.Inventory) do

                            if not info.ItemPlaced then
                                table.insert(availableGuids, guid)
                            end

                        end

                        for i = 1, math.min(#availableGuids, #shelves) do

                            SellRemote:FireServer(
                                availableGuids[i],
                                shelves[i],
                                true
                            )

                            print("Placed item")

                            task.wait(0.25)

                        end

                    end

                end

            end

        end

        task.wait(2)

    end

end)

Window:SelectTab(Tabs.Main)
