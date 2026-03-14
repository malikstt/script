local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local UIModule = require(ReplicatedStorage.Modules.UIModule)
local Events = ReplicatedStorage:WaitForChild("Events")
local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local MakeOfferRemote = ReplicatedStorage.Events.Shop.MakePlayerOffer
local GetRemote = ReplicatedStorage.Events.Data.Get
local GetAllRemote = ReplicatedStorage.Events.Data.GetAll
local AcceptRemote = ReplicatedStorage.Events.Shop.AcceptPlayerOffer
local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop
local SetInsideShopRemote = ReplicatedStorage.Events.Misc.SetInsideShop

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize

local Window = Fluent:CreateWindow({
    Title = "Malik",
    SubTitle = "lmklmk",
    TabWidth = 160,
    Size = UDim2.fromOffset(viewport.X * 0.35, viewport.Y * 0.55),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" }),
    Sender = Window:AddTab({ Title = "Sender", Icon = "send" }),
    Receiver = Window:AddTab({ Title = "Receiver", Icon = "download" })
}

local function getAllPlayersIncludingSelf()
    local t = {}
    for _,p in ipairs(Players:GetPlayers()) do
        table.insert(t,p.Name)
    end
    return t
end

local function getOtherPlayers()
    local t = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            table.insert(t,p.Name)
        end
    end
    return t
end

local function parseNumber(str)
    if type(str) == "number" then return str end
    str = str:upper():gsub(",", "")
    local mult = 1
    if str:find("K$") then mult = 1000
    elseif str:find("M$") then mult = 1000000
    elseif str:find("B$") then mult = 1000000000
    elseif str:find("T$") then mult = 1000000000000 end
    local num = tonumber(str:gsub("[KMBT$]", ""))
    return num and num * mult or 0
end

local SenderOptions = {
    Enabled = false,
    TargetPlayers = {},
    AutoSend = false,
    AutoAccept = false,
    AutoAdd = false,
    MinItems = 16,
    StopWhenCash = "2B",
    SendDelay = 5,
    CurrentTargetIndex = 1,
    LastSend = 0
}

local ReceiverOptions = {
    Enabled = false,
    TargetPlayer = "",
    AutoSend = false,
    AutoAccept = false,
    AutoAdd = false,
    SendDelay = 5,
    LastSend = 0
}

local pivotTargetPlayer = nil
local pivotTeleportEnabled = false

Tabs.Main:AddDropdown("PivotTeleportPlayer", {
    Title = "Teleport To Player (Pivot)",
    Values = getAllPlayersIncludingSelf(),
    Multi = false,
    Default = nil,
    Callback = function(v)
        pivotTargetPlayer = v
    end
})

Tabs.Main:AddToggle("PivotTeleportToggle", {
    Title = "Pivot Teleport Toggle",
    Default = false,
    Callback = function(v)
        pivotTeleportEnabled = v
    end
})

task.spawn(function()
    local currentTargetCharacter = nil
    local currentTargetPlayer = nil
    local lastLoadedPlot = nil
    local lastUpdateTime = 0
    while true do
        pcall(function()
            if not pivotTeleportEnabled then
                currentTargetCharacter = nil
                currentTargetPlayer = nil
                lastLoadedPlot = nil
                return
            end
            local now = tick()
            if now - lastUpdateTime >= 0.5 then
                lastUpdateTime = now
                if pivotTargetPlayer then
                    local targetPlayer = Players:FindFirstChild(pivotTargetPlayer)
                    if targetPlayer then
                        currentTargetCharacter = targetPlayer.Character
                        currentTargetPlayer = targetPlayer
                    else
                        currentTargetCharacter = nil
                        currentTargetPlayer = nil
                    end
                else
                    currentTargetCharacter = nil
                    currentTargetPlayer = nil
                end
            end
            if currentTargetCharacter then
                local targetRoot = currentTargetCharacter:FindFirstChild("HumanoidRootPart")
                local myCharacter = LocalPlayer.Character
                if targetRoot and myCharacter then
                    myCharacter:PivotTo(targetRoot.CFrame * CFrame.new(0,0,-2))
                    if currentTargetPlayer then
                        local vars = currentTargetPlayer:FindFirstChild("NonSaveVars")
                        if vars then
                            local plotVal = vars:FindFirstChild("OwnsPlot")
                            if plotVal and plotVal.Value then
                                local plot = plotVal.Value
                                if plot ~= lastLoadedPlot then
                                    lastLoadedPlot = plot
                                    local floorVal = vars:FindFirstChild("DefaultFloor")
                                    if floorVal and floorVal.Value then
                                        pcall(function()
                                            SetInsideShopRemote:FireServer(nil)
                                            task.wait()
                                            SetInsideShopRemote:FireServer(floorVal.Value)
                                        end)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        task.wait(0.05)
    end
end)

local shopTargetPlayers = {}
local shopTeleportEnabled = false
local shopTeleportDelay = 5

Tabs.Main:AddDropdown("ShopTargetPlayers", {
    Title = "Shop Teleport Players",
    Values = getAllPlayersIncludingSelf(),
    Multi = true,
    Default = {},
    Callback = function(v)
        shopTargetPlayers = v
    end
})

Tabs.Main:AddInput("ShopTeleportDelay", {
    Title = "Shop Teleport Delay",
    Default = "5",
    Placeholder = "Seconds",
    Numeric = true,
    Callback = function(v)
        shopTeleportDelay = tonumber(v) or 5
    end
})

Tabs.Main:AddToggle("ShopTeleportToggle", {
    Title = "Shop Teleport Toggle",
    Default = false,
    Callback = function(v)
        shopTeleportEnabled = v
    end
})

local function teleportToShop(plot)
    if not plot then return end
    local exterior = plot:FindFirstChild("Exterior")
    if not exterior then return end
    local Character = LocalPlayer.Character
    if not Character then return end
    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    local door = nil
    for _, d in ipairs(CollectionService:GetTagged("Door")) do
        if d:IsDescendantOf(exterior) and d:FindFirstChild("TouchPart") then
            door = d
            break
        end
    end
    if not door then return end
    local touchPart = door.TouchPart
    Root.CFrame = touchPart.CFrame + Vector3.new(0,0,-2)
    local floorVal = exterior.Parent:FindFirstChild("Owner") and exterior.Parent.Owner.Value and exterior.Parent.Owner.Value.NonSaveVars and exterior.Parent.Owner.Value.NonSaveVars:FindFirstChild("DefaultFloor")
    if floorVal and floorVal.Value then
        SetInsideShopRemote:FireServer(nil)
        task.wait()
        SetInsideShopRemote:FireServer(floorVal.Value)
    end
end

task.spawn(function()
    while true do
        pcall(function()
            if not shopTeleportEnabled then return end
            for playerName, state in pairs(shopTargetPlayers) do
                if not shopTeleportEnabled then break end
                if not state then continue end
                local target = Players:FindFirstChild(playerName)
                if not target then continue end
                local vars = target:FindFirstChild("NonSaveVars")
                if not vars then continue end
                local plotVal = vars:FindFirstChild("OwnsPlot")
                if not plotVal then continue end
                local plot = plotVal.Value
                if not plot then continue end
                teleportToShop(plot)
                task.wait(shopTeleportDelay)
            end
        end)
        task.wait(0.25)
    end
end)

local SenderTargetsDropdown = Tabs.Sender:AddDropdown("SenderTargetPlayers", {
    Title = "Target Players",
    Values = getOtherPlayers(),
    Multi = true,
    Default = {},
    Callback = function(v)
        SenderOptions.TargetPlayers = v
        if #v > 0 and SenderOptions.CurrentTargetIndex > #v then
            SenderOptions.CurrentTargetIndex = 1
        end
    end
})

Tabs.Sender:AddInput("SenderMinItems", {
    Title = "Min Items",
    Default = "16",
    Placeholder = "Number",
    Numeric = true,
    Callback = function(v)
        SenderOptions.MinItems = tonumber(v) or 16
    end
})

Tabs.Sender:AddInput("SenderStopCash", {
    Title = "Stop When Cash",
    Default = "2B",
    Placeholder = "Examples: 500M, 1B, 2.5B",
    Callback = function(v)
        SenderOptions.StopWhenCash = v
    end
})

Tabs.Sender:AddInput("SenderSendDelay", {
    Title = "Send Delay (Seconds)",
    Default = "5",
    Placeholder = "Seconds",
    Numeric = true,
    Callback = function(v)
        SenderOptions.SendDelay = tonumber(v) or 5
    end
})

local SenderEnabledToggle = Tabs.Sender:AddToggle("SenderEnabled", {
    Title = "Enable Sender",
    Default = false,
    Callback = function(v)
        SenderOptions.Enabled = v
    end
})

local SenderAutoSendToggle = Tabs.Sender:AddToggle("SenderAutoSend", {
    Title = "Auto Send",
    Default = false,
    Callback = function(v)
        SenderOptions.AutoSend = v
    end
})

local SenderAutoAcceptToggle = Tabs.Sender:AddToggle("SenderAutoAccept", {
    Title = "Auto Accept",
    Default = false,
    Callback = function(v)
        SenderOptions.AutoAccept = v
    end
})

local SenderAutoAddToggle = Tabs.Sender:AddToggle("SenderAutoAdd", {
    Title = "Auto Add Items",
    Default = false,
    Callback = function(v)
        SenderOptions.AutoAdd = v
    end
})

Tabs.Sender:AddButton({
    Title = "Next Target",
    Description = "Switch to next target player",
    Callback = function()
        if #SenderOptions.TargetPlayers > 0 then
            SenderOptions.CurrentTargetIndex = (SenderOptions.CurrentTargetIndex % #SenderOptions.TargetPlayers) + 1
            local newTarget = SenderOptions.TargetPlayers[SenderOptions.CurrentTargetIndex]
            UIModule:Notify(LocalPlayer, "Switched target to: " .. newTarget)
        else
            UIModule:Notify(LocalPlayer, "No targets selected")
        end
    end
})

local ReceiverTargetDropdown = Tabs.Receiver:AddDropdown("ReceiverTargetPlayer", {
    Title = "Target Player",
    Values = getOtherPlayers(),
    Default = "",
    Callback = function(v)
        ReceiverOptions.TargetPlayer = v
    end
})

Tabs.Receiver:AddInput("ReceiverSendDelay", {
    Title = "Send Delay (Seconds)",
    Default = "5",
    Placeholder = "Seconds",
    Numeric = true,
    Callback = function(v)
        ReceiverOptions.SendDelay = tonumber(v) or 5
    end
})

local ReceiverEnabledToggle = Tabs.Receiver:AddToggle("ReceiverEnabled", {
    Title = "Enable Receiver",
    Default = false,
    Callback = function(v)
        ReceiverOptions.Enabled = v
    end
})

local ReceiverAutoSendToggle = Tabs.Receiver:AddToggle("ReceiverAutoSend", {
    Title = "Auto Send",
    Default = false,
    Callback = function(v)
        ReceiverOptions.AutoSend = v
    end
})

local ReceiverAutoAcceptToggle = Tabs.Receiver:AddToggle("ReceiverAutoAccept", {
    Title = "Auto Accept",
    Default = false,
    Callback = function(v)
        ReceiverOptions.AutoAccept = v
    end
})

local ReceiverAutoAddToggle = Tabs.Receiver:AddToggle("ReceiverAutoAdd", {
    Title = "Auto Add Items",
    Default = false,
    Callback = function(v)
        ReceiverOptions.AutoAdd = v
    end
})

local function getCurrentTarget()
    return SenderOptions.TargetPlayers[SenderOptions.CurrentTargetIndex]
end

local function checkPlayerCash(playerName)
    local player = Players:FindFirstChild(playerName)
    if player and player:FindFirstChild("SaveVars") and player.SaveVars:FindFirstChild("Cash") then
        return player.SaveVars.Cash.Value
    end
    return nil
end

local function switchToNextTarget()
    if #SenderOptions.TargetPlayers > 0 then
        SenderOptions.CurrentTargetIndex = (SenderOptions.CurrentTargetIndex % #SenderOptions.TargetPlayers) + 1
        local newTarget = getCurrentTarget()
        UIModule:Notify(LocalPlayer, "Switched target to: " .. newTarget)
    end
end

task.spawn(function()
    while true do
        task.wait(1)
        if SenderOptions.Enabled and SenderOptions.AutoSend and getCurrentTarget() and tick() - SenderOptions.LastSend >= SenderOptions.SendDelay then
            
            local currentTarget = getCurrentTarget()
            if not currentTarget then 
                SenderOptions.CurrentTargetIndex = 1
                if not getCurrentTarget() then
                    task.wait(5)
                    continue
                end
                currentTarget = getCurrentTarget()
            end
            
            local targetCash = checkPlayerCash(currentTarget)
            local stopCashValue = parseNumber(SenderOptions.StopWhenCash)
            
            if targetCash and targetCash >= stopCashValue then
                UIModule:Notify(LocalPlayer, currentTarget .. " has $" .. targetCash .. " - Switching target")
                switchToNextTarget()
            else
                local success, data = pcall(function()
                    return Events.Data.Get:InvokeServer("Inventory")
                end)
                
                if success and data then
                    local inventory = data.Inventory or data
                    local availableCount = 0
                    
                    for guid, itemData in pairs(inventory) do
                        if not (itemData.ItemPlaced or itemData.NextOfferDue) then
                            availableCount = availableCount + 1
                        end
                    end
                    
                    if availableCount >= SenderOptions.MinItems then
                        local inviteSuccess = Events.Trading.SendInvite:InvokeServer(currentTarget)
                        if inviteSuccess then
                            UIModule:Notify(LocalPlayer, "Sent trade to " .. currentTarget .. " (" .. availableCount .. " items)")
                            SenderOptions.LastSend = tick()
                        end
                    else
                        UIModule:Notify(LocalPlayer, "Not enough items: " .. availableCount .. "/" .. SenderOptions.MinItems)
                    end
                end
            end
        end
    end
end)

Events.Trading.AcceptTradeFromServer.OnClientEvent:Connect(function()
    if SenderOptions.Enabled and SenderOptions.AutoAccept then
        task.wait(0.5)
        local success = pcall(function()
            Events.Trading.AcceptTrade:InvokeServer()
        end)
        if success then
            UIModule:Notify(LocalPlayer, "Trade Accepted (Sender)")
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if SenderOptions.Enabled and SenderOptions.AutoAdd then
            local success, data = pcall(function()
                return Events.Data.Get:InvokeServer("Inventory")
            end)
            
            if success and data then
                local inventory = data.Inventory or data
                local addedCount = 0
                
                for guid, itemData in pairs(inventory) do
                    if addedCount >= 16 then
                        break
                    end
                    
                    if not (itemData.ItemPlaced or itemData.NextOfferDue) then
                        local addSuccess = pcall(function()
                            return Events.Trading.AddItem:InvokeServer({
                                GUID = guid,
                                Type = "Item"
                            })
                        end)
                        
                        if addSuccess then
                            addedCount = addedCount + 1
                        end
                        
                        task.wait(0.1)
                    end
                end
                
                if addedCount > 0 then
                    UIModule:Notify(LocalPlayer, "Added " .. addedCount .. " items (Sender)")
                    task.wait(0.5)
                    pcall(function()
                        Events.Trading.AcceptTrade:InvokeServer()
                        UIModule:Notify(LocalPlayer, "Trade Accepted (Sender)")
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(1)
        if ReceiverOptions.Enabled and ReceiverOptions.AutoSend and ReceiverOptions.TargetPlayer and ReceiverOptions.TargetPlayer ~= "" and tick() - ReceiverOptions.LastSend >= ReceiverOptions.SendDelay then
            local success = pcall(function()
                return Events.Trading.SendInvite:InvokeServer(ReceiverOptions.TargetPlayer)
            end)
            if success then
                UIModule:Notify(LocalPlayer, "Sent trade to " .. ReceiverOptions.TargetPlayer)
                ReceiverOptions.LastSend = tick()
            end
        end
    end
end)

Events.Trading.AcceptTradeFromServer.OnClientEvent:Connect(function()
    if ReceiverOptions.Enabled and ReceiverOptions.AutoAccept then
        task.wait(0.5)
        local success = pcall(function()
            Events.Trading.AcceptTrade:InvokeServer()
        end)
        if success then
            UIModule:Notify(LocalPlayer, "Trade Accepted (Receiver)")
        end
    end
end)

task.spawn(function()
    while true do
        task.wait(2)
        if ReceiverOptions.Enabled and ReceiverOptions.AutoAdd then
            local success, inventory = pcall(function()
                return Events.Data.Get:InvokeServer("Inventory")
            end)
            
            if success and inventory then
                local addedCount = 0
                
                for guid, itemData in pairs(inventory) do
                    if addedCount >= 16 then
                        break
                    end
                    
                    if not (itemData.ItemPlaced or itemData.NextOfferDue) then
                        local addSuccess = pcall(function()
                            return Events.Trading.AddItem:InvokeServer({
                                GUID = guid,
                                Type = "Item"
                            })
                        end)
                        
                        if addSuccess then
                            addedCount = addedCount + 1
                        end
                        
                        task.wait(0.1)
                    end
                end
                
                if addedCount > 0 then
                    UIModule:Notify(LocalPlayer, "Added " .. addedCount .. " items (Receiver)")
                    task.wait(0.5)
                    pcall(function()
                        Events.Trading.AcceptTrade:InvokeServer()
                        UIModule:Notify(LocalPlayer, "Trade Accepted (Receiver)")
                    end)
                end
            end
        end
    end
end)

local sendPlayers={}
local sendEnabled=false
local offerPercent=50

Tabs.Main:AddDropdown("SendPlayers",{
    Title="Send Offers To",
    Values=getOtherPlayers(),
    Multi=true,
    Default={},
    Callback=function(v)
        sendPlayers=v
    end
})

Tabs.Main:AddDropdown("OfferPercent",{
    Title="Offer Percent",
    Values={"+50%","-50%"},
    Default="+50%",
    Callback=function(v)
        offerPercent=v=="+50%" and 50 or -50
    end
})

Tabs.Main:AddToggle("SendToggle",{
    Title="Send Offers",
    Default=false,
    Callback=function(v)
        sendEnabled=v
    end
})

local function getPlacedMap(plot)
    local map={}
    local furniture=plot:FindFirstChild("Furniture")
    if not furniture then return map end
    for _,v in pairs(furniture:GetDescendants()) do
        if v.Name=="Item" then
            for _,item in pairs(v:GetChildren()) do
                map[item.Name]=map[item.Name] or {}
                table.insert(map[item.Name],item)
            end
        end
    end
    return map
end

task.spawn(function()
    while true do
        pcall(function()
            if not sendEnabled then return end
            for playerName,state in pairs(sendPlayers) do
                if not state then continue end
                local target=Players:FindFirstChild(playerName)
                if not target then continue end
                local inv=GetRemote:InvokeServer("Inventory",target)
                if type(inv)~="table" then continue end
                local plotVal=target.NonSaveVars and target.NonSaveVars.OwnsPlot
                if not plotVal then continue end
                local plot=plotVal.Value
                if not plot then continue end
                local placedMap=getPlacedMap(plot)

                local sortedItems = {}
                for guid,itemData in pairs(inv) do
                    local price = RepLibrary:GetItemPrice(itemData)
                    table.insert(sortedItems,{GUID=guid,Data=itemData,Price=price})
                end
                table.sort(sortedItems,function(a,b) return a.Price > b.Price end)

                for _, item in ipairs(sortedItems) do
                    local guid = item.GUID
                    local itemData = item.Data
                    local info = ItemsModule[itemData.Id]
                    if not info then continue end
                    local placed = placedMap[info.Name]
                    if placed and #placed > 0 then
                        local instance = table.remove(placed,1)
                        local price = item.Price
                        local offer = math.floor(price*(1+offerPercent/100))
                        pcall(function()
                            MakeOfferRemote:InvokeServer(target,guid,offer,instance)
                        end)
                        task.wait(0.25)
                    end
                end
            end
        end)
        task.wait(1)
    end
end)

local acceptPlayers={}
local acceptEnabled=false

Tabs.Main:AddDropdown("AcceptPlayers",{
    Title="Accept From Players",
    Values=getOtherPlayers(),
    Multi=true,
    Default={},
    Callback=function(v)
        acceptPlayers=v
    end
})

Tabs.Main:AddToggle("AcceptToggle",{
    Title="Accept Offers",
    Default=false,
    Callback=function(v)
        acceptEnabled=v
    end
})

task.spawn(function()
    while true do
        pcall(function()
            if not acceptEnabled then return end
            for _,gui in ipairs(LocalPlayer.PlayerGui:GetChildren()) do
                local from=gui:GetAttribute("OfferFromPlayerName")
                local guid=gui:GetAttribute("GUID")
                local price=gui:GetAttribute("Offer")
                if from and guid and price then
                    if acceptPlayers[from] then
                        pcall(function()
                            AcceptRemote:InvokeServer(from,guid,price)
                        end)
                    end
                end
            end
        end)
        task.wait(0.5)
    end
end)

local placeEnabled=false

Tabs.Main:AddToggle("PlaceToggle",{
    Title="Place Items",
    Default=false,
    Callback=function(v)
        placeEnabled=v
    end
})

task.spawn(function()
    while true do
        pcall(function()
            if not placeEnabled then return end

            local data = GetAllRemote:InvokeServer()
            if not data or not data.Inventory then return end

            local plotName = LocalPlayer.NonSaveVars.OwnsPlot.Value.Name
            local plot = workspace.Plots[plotName]

            local shelves = {}
            local furnitureFolder = plot:FindFirstChild("Furniture")
            if furnitureFolder then
                for _, furniture in ipairs(furnitureFolder:GetChildren()) do
                    local s = furniture:FindFirstChild("Shelves")
                    if s then
                        for _, shelf in ipairs(s:GetChildren()) do
                            table.insert(shelves, shelf)
                        end
                    end
                end
            end

            local sortedInventory = {}
            for guid, info in pairs(data.Inventory) do
                local id = tonumber(info.Id)
                local itemData = ItemsModule[id]
                local name = itemData and string.lower(itemData.Name or "") or ""
                if id ~= 681 and id ~= 2294 and not string.find(name,"safe") then
                    local price = RepLibrary:GetItemPrice(info)
                    table.insert(sortedInventory,{GUID=guid,Data=info,Price=price})
                end
            end

            table.sort(sortedInventory,function(a,b) return a.Price > b.Price end)

            local shelfIndex = 1
            for _, item in ipairs(sortedInventory) do
                if shelfIndex > #shelves then break end
                pcall(function()
                    SellRemote:FireServer(item.GUID, shelves[shelfIndex], true)
                end)
                shelfIndex += 1
                task.wait(0.15)
            end

        end)
        task.wait(1)
    end
end)

Window:SelectTab(Tabs.Main)
