local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize
local winSize = UDim2.fromOffset(viewport.X * 0.35, viewport.Y * 0.65)

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

local selectedPlayers = {}
local autoTpEnabled = false

Tabs.Main:AddDropdown("MultiTP", {
    Title = "Select Players to TP",
    Values = getOtherPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        selectedPlayers = Value
    end
})

Tabs.Main:AddToggle("AutoTP", {
    Title = "Auto TP",
    Default = false,
    Callback = function(Value)
        autoTpEnabled = Value
    end
})

task.spawn(function()
    while true do
        local ok,err = pcall(function()
            if autoTpEnabled and LocalPlayer.Character then
                local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                if myRoot then
                    for name, state in pairs(selectedPlayers) do
                        if state then
                            local p = Players:FindFirstChild(name)
                            if p and p.Character then
                                local targetRoot = p.Character:FindFirstChild("HumanoidRootPart")
                                if targetRoot then
                                    LocalPlayer.Character:PivotTo(targetRoot.CFrame * CFrame.new(0,0,-3))
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

Tabs.Main:AddSection("Send Offers")

local sendOfferPlayers = {}
local sendOffersEnabled = false
local offerPercent = 50

Tabs.Main:AddDropdown("OfferPlayers", {
    Title = "Select Players",
    Values = getOtherPlayerNames(),
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
        if state then
            pcall(function()
                local targetPlayer = Players:FindFirstChild(playerName)
                if not targetPlayer then return end

                local inv = GetInventoryRemote:InvokeServer("Inventory", targetPlayer)
                if type(inv) ~= "table" then return end

                local plotName = targetPlayer.NonSaveVars.OwnsPlot.Value
                if typeof(plotName) ~= "string" then
                    plotName = plotName.Name
                end

                local plot = workspace.Plots:FindFirstChild(plotName)
                if not plot then return end

                local furniture = plot:FindFirstChild("Furniture")
                if not furniture then return end

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
                    if itemInfo then
                        local matching = nameMap[itemInfo.Name]
                        if matching and #matching > 0 then
                            local instance = table.remove(matching,1)
                            local realPrice = RepLibrary:GetItemPrice(itemData)
                            local offerPrice = math.floor(realPrice * (1 + offerPercent / 100))
                            MakeOfferRemote:InvokeServer(targetPlayer, guid, offerPrice, instance)
                            break
                        end
                    end
                end
            end)
        end
    end
end

task.spawn(function()
    while true do
        pcall(SendOffersFunction)
        task.wait(1)
    end
end)

Tabs.Main:AddSection("Place Items")

local placeItemsEnabled = false

Tabs.Main:AddToggle("PlaceItemsToggle", {
    Title = "Place Items",
    Default = false,
    Callback = function(Value)
        placeItemsEnabled = Value
    end
})

local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop
local GetAllRemote = ReplicatedStorage.Events.Data.GetAll

task.spawn(function()
    while true do
        local ok,err = pcall(function()
            if not placeItemsEnabled then return end

            local data = GetAllRemote:InvokeServer()
            if not data or not data.Inventory then return end

            local plotName = LocalPlayer.NonSaveVars.OwnsPlot.Value
            if typeof(plotName) ~= "string" then
                plotName = plotName.Name
            end

            local plot = workspace.Plots:FindFirstChild(plotName)
            if not plot then return end

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
                SellRemote:FireServer(guids[i], shelves[i], true)
                task.wait(0.1)
            end
        end)
        task.wait(1)
    end
end)

Tabs.Main:AddSection("Accept Offers")

local acceptAnyEnabled = false
local acceptSpecificEnabled = false
local targetAcceptPlayer = ""

Tabs.Main:AddToggle("AcceptAnyToggle", {
    Title = "Accept Any",
    Default = false,
    Callback = function(Value)
        acceptAnyEnabled = Value
    end
})

Tabs.Main:AddDropdown("AcceptSpecificDropdown", {
    Title = "Select Player",
    Values = getOtherPlayerNames(),
    Default = "",
    Callback = function(Value)
        targetAcceptPlayer = Value
    end
})

Tabs.Main:AddToggle("AcceptSpecificToggle", {
    Title = "Accept Selected",
    Default = false,
    Callback = function(Value)
        acceptSpecificEnabled = Value
    end
})

local AcceptRemote = ReplicatedStorage.Events.Shop.AcceptPlayerOffer

AcceptOffersFunction = function()
    pcall(function()
        for _, gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
            local from = gui:GetAttribute("OfferFromPlayerName")
            local guid = gui:GetAttribute("GUID")
            local price = gui:GetAttribute("Offer")

            if from and guid and price then
                if acceptAnyEnabled then
                    AcceptRemote:InvokeServer(from, guid, price)
                elseif acceptSpecificEnabled and from == targetAcceptPlayer then
                    AcceptRemote:InvokeServer(from, guid, price)
                end
            end
        end
    end)
end

LocalPlayer.PlayerGui.ChildAdded:Connect(function()
    task.spawn(function()
        task.wait(0.1)
        pcall(AcceptOffersFunction)
    end)
end)

task.spawn(function()
    while true do
        pcall(AcceptOffersFunction)
        task.wait(1)
    end
end)

Tabs.Main:AddSection("Shop Teleport")

local tpPlayers = {}
local tpLoopEnabled = false

Tabs.Main:AddDropdown("TeleportPlayers", {
    Title = "Teleport Players",
    Values = getAllPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        tpPlayers = Value
    end
})

Tabs.Main:AddToggle("TeleportLoopToggle", {
    Title = "Teleport Loop",
    Default = false,
    Callback = function(Value)
        tpLoopEnabled = Value
    end
})

local function teleportToPlot(playerName)
    local plr = Players:FindFirstChild(playerName)
    if not plr then return end

    local owns = plr:FindFirstChild("NonSaveVars")
    if not owns then return end

    local plot = owns:FindFirstChild("OwnsPlot")
    if not plot then return end

    plot = plot.Value
    if typeof(plot) ~= "Instance" then return end

    local door = plot:FindFirstChild("Door", true)
    if not door then return end

    local startPart = door:FindFirstChild("StartPart")
    if not startPart then return end

    local char = LocalPlayer.Character
    if char and char.PrimaryPart then
        char:SetPrimaryPartCFrame(startPart.CFrame + Vector3.new(0,3,0))
    end
end

task.spawn(function()
    while true do
        if tpLoopEnabled then
            for playerName, state in pairs(tpPlayers) do
                if state then
                    pcall(function()
                        teleportToPlot(playerName)
                    end)

                    pcall(SendOffersFunction)
                    pcall(AcceptOffersFunction)

                    task.wait(1)
                end
            end
        end
        task.wait(0.1)
    end
end)

Window:SelectTab(Tabs.Main)
