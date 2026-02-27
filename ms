local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize
local winSize = UDim2.fromOffset(viewport.X * 0.35, viewport.Y * 0.55)

local Window = Fluent:CreateWindow({
    Title = "Shop & Player Manager",
    SubTitle = "Main Controls",
    TabWidth = 160,
    Size = winSize,
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

local function getPlayerNames()
    local t = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t, p.Name)
        end
    end
    return t
end

local function getRoot(plr)
    local char = plr.Character
    if char then
        return char:FindFirstChild("HumanoidRootPart")
    end
end

local selectedPlayers = {}
local autoTpEnabled = false

Tabs.Main:AddDropdown("MultiTP", {
    Title = "Select Players to TP",
    Values = getPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        selectedPlayers = Value
    end
})

Tabs.Main:AddToggle("AutoTP", {
    Title = "Auto TP (0.5s)",
    Default = false,
    Callback = function(Value)
        autoTpEnabled = Value
    end
})

task.spawn(function()
    while task.wait(0.5) do
        if autoTpEnabled and LocalPlayer.Character then
            local myRoot = getRoot(LocalPlayer)
            if not myRoot then continue end
            for name, state in pairs(selectedPlayers) do
                if state then
                    local p = Players:FindFirstChild(name)
                    local targetRoot = p and getRoot(p)
                    if targetRoot then
                        myRoot.CFrame = targetRoot.CFrame * CFrame.new(0,0,-3)
                    end
                end
            end
        end
    end
end)

Tabs.Main:AddSection("Send Offers")

local sendOfferPlayers = {}
local sendOffersEnabled = false
local offerPercent = 50

Tabs.Main:AddDropdown("OfferPlayers", {
    Title = "Select Players to Send Offers",
    Values = getPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        sendOfferPlayers = Value
    end
})

Tabs.Main:AddDropdown("OfferPercentSelect", {
    Title = "Offer Percentage",
    Values = {"+50%", "-50%"},
    Default = "+50%",
    Callback = function(Value)
        if Value == "+50%" then
            offerPercent = 50
        else
            offerPercent = -50
        end
    end
})

Tabs.Main:AddToggle("SendOffersToggle", {
    Title = "Send Offers",
    Default = false,
    Callback = function(Value)
        sendOffersEnabled = Value
    end
})

local MakeOfferRemote = ReplicatedStorage.Events.Shop.MakePlayerOffer
local GetInventoryRemote = ReplicatedStorage.Events.Data.Get

SendOffersFunction = function()
    if not sendOffersEnabled then return end
    for playerName, state in pairs(sendOfferPlayers) do
        if not state then continue end
        local targetPlayer = Players:FindFirstChild(playerName)
        if not targetPlayer then continue end

        local success, inv = pcall(function()
            return GetInventoryRemote:InvokeServer("Inventory", targetPlayer)
        end)
        if not success or type(inv) ~= "table" then continue end

        local plotName = targetPlayer.NonSaveVars.OwnsPlot.Value
        if typeof(plotName) ~= "string" then
            plotName = plotName.Name
        end

        local plot = workspace.Plots:FindFirstChild(plotName)
        if not plot then continue end

        local furniture = plot:FindFirstChild("Furniture")
        if not furniture then continue end

        local instances = {}
        for _, obj in pairs(furniture:GetDescendants()) do
            if obj.Name == "Item" then
                for _, item in pairs(obj:GetChildren()) do
                    table.insert(instances, item)
                end
            end
        end

        local nameMap = {}
        for _, inst in pairs(instances) do
            nameMap[inst.Name] = nameMap[inst.Name] or {}
            table.insert(nameMap[inst.Name], inst)
        end

        for guid, itemData in pairs(inv) do
            local itemInfo = ItemsModule[itemData.Id]
            if not itemInfo then continue end

            local matching = nameMap[itemInfo.Name]
            if not matching or #matching == 0 then continue end

            local instance = table.remove(matching,1)
            local realPrice = RepLibrary:GetItemPrice(itemData)
            local offerPrice = math.floor(realPrice * (1 + offerPercent / 100))

            pcall(function()
                MakeOfferRemote:InvokeServer(targetPlayer, guid, offerPrice, instance)
            end)

            break
        end
    end
end

task.spawn(function()
    while task.wait(1) do
        SendOffersFunction()
    end
end)

Tabs.Main:AddSection("Place Items")

local placeItemsEnabled = false

Tabs.Main:AddToggle("PlaceItemsToggle", {
    Title = "Place All Items",
    Default = false,
    Callback = function(Value)
        placeItemsEnabled = Value
    end
})

local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop
local GetAllRemote = ReplicatedStorage.Events.Data.GetAll

task.spawn(function()
    while task.wait(1) do
        if not placeItemsEnabled then continue end

        local success, data = pcall(function()
            return GetAllRemote:InvokeServer()
        end)
        if not success or not data or not data.Inventory then continue end

        local plotName = LocalPlayer.NonSaveVars.OwnsPlot.Value
        if typeof(plotName) ~= "string" then
            plotName = plotName.Name
        end

        local plot = workspace.Plots:FindFirstChild(plotName)
        if not plot then continue end

        local shelves = {}
        for _, furniture in ipairs(plot.Furniture:GetChildren()) do
            local s = furniture:FindFirstChild("Shelves")
            if s then
                for _, shelf in ipairs(s:GetChildren()) do
                    table.insert(shelves, shelf)
                end
            end
        end

        local guids = {}
        for guid, info in pairs(data.Inventory) do
            local itemData = ItemsModule[tostring(info.Id)]
            local name = itemData and string.lower(itemData.Name or "") or ""
            if tostring(info.Id) ~= "281" and tostring(info.Id) ~= "2294" and not string.find(name, "safe") then
                table.insert(guids, guid)
            end
        end

        local count = math.min(#shelves, #guids)
        for i = 1, count do
            if not placeItemsEnabled then break end
            pcall(function()
                SellRemote:FireServer(guids[i], shelves[i], true)
            end)
            task.wait(0.1)
        end
    end
end)

Tabs.Main:AddSection("Accept Offers")

local acceptAnyEnabled = false
local acceptSpecificEnabled = false
local targetAcceptPlayer = ""

Tabs.Main:AddToggle("AcceptAnyToggle", {
    Title = "Accept Any Offers",
    Default = false,
    Callback = function(Value)
        acceptAnyEnabled = Value
    end
})

Tabs.Main:AddDropdown("AcceptSpecificDropdown", {
    Title = "Select Player",
    Values = getPlayerNames(),
    Default = "",
    Callback = function(Value)
        targetAcceptPlayer = Value
    end
})

Tabs.Main:AddToggle("AcceptSpecificToggle", {
    Title = "Accept Specific Player Offers",
    Default = false,
    Callback = function(Value)
        acceptSpecificEnabled = Value
    end
})

local AcceptRemote = ReplicatedStorage.Events.Shop.AcceptPlayerOffer

AcceptOffersFunction = function()
    for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
        local from = gui:GetAttribute("OfferFromPlayerName")
        local guid = gui:GetAttribute("GUID")
        local price = gui:GetAttribute("Offer")

        if from and guid and price then
            if acceptAnyEnabled or (acceptSpecificEnabled and from == targetAcceptPlayer) then
                pcall(function()
                    AcceptRemote:InvokeServer(from, guid, price)
                end)
            end
        end
    end
end

LocalPlayer.PlayerGui.ChildAdded:Connect(function()
    task.wait(0.1)
    AcceptOffersFunction()
end)

task.spawn(function()
    while task.wait(1) do
        AcceptOffersFunction()
    end
end)

Tabs.Main:AddSection("Shop Teleport")

local ShopTPEnabled = false
local SelectedTradePlayer = nil
local YourShopCFrame = nil
local TeleportDelay = 0.6

Tabs.Main:AddDropdown("TradePlayerSelect", {
    Title = "Select Trade Player",
    Values = getPlayerNames(),
    Default = "",
    Callback = function(Value)
        SelectedTradePlayer = Players:FindFirstChild(Value)
    end
})

Tabs.Main:AddToggle("ShopTeleportToggle", {
    Title = "Teleport Back & Forth",
    Default = false,
    Callback = function(Value)
        ShopTPEnabled = Value
    end
})

task.spawn(function()
    repeat task.wait() until getRoot(LocalPlayer)
    YourShopCFrame = getRoot(LocalPlayer).CFrame
end)

task.spawn(function()
    while task.wait(TeleportDelay) do
        if ShopTPEnabled and SelectedTradePlayer then
            local myRoot = getRoot(LocalPlayer)
            local targetRoot = getRoot(SelectedTradePlayer)

            if myRoot and targetRoot then
                myRoot.CFrame = targetRoot.CFrame * CFrame.new(0,0,-4)
                task.wait(TeleportDelay)
                SendOffersFunction()
                AcceptOffersFunction()
                task.wait(TeleportDelay)
                if YourShopCFrame then
                    myRoot.CFrame = YourShopCFrame
                end
            end
        end
    end
end)

Window:SelectTab(Tabs.Main)
