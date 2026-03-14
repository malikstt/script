local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer

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
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
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

local teleportPlayers = {}
local teleportEnabled = false

Tabs.Main:AddDropdown("TeleportPlayersMulti", {
    Title = "Teleport To Player Shops",
    Values = getAllPlayersIncludingSelf(),
    Multi = true,
    Default = {},
    Callback = function(v)
        teleportPlayers = v
    end
})

Tabs.Main:AddToggle("TeleportToggle", {
    Title = "Auto Teleport Shops",
    Default = false,
    Callback = function(v)
        teleportEnabled = v
    end
})

local function enterNormally(plot)
    local exterior = plot:FindFirstChild("Exterior")
    if not exterior then return end
    local Character = LocalPlayer.Character
    if not Character then return end
    local Root = Character:FindFirstChild("HumanoidRootPart")
    if not Root then return end
    for _, door in ipairs(CollectionService:GetTagged("Door")) do
        if door:IsDescendantOf(exterior) and door:FindFirstChild("TouchPart") then
            local touchPart = door.TouchPart
            Root.CFrame = touchPart.CFrame + Vector3.new(0,0,-2)
            firetouchinterest(Root, touchPart, 0)
            task.wait()
            firetouchinterest(Root, touchPart, 1)
            return
        end
    end
end

task.spawn(function()
    while true do
        pcall(function()
            if not teleportEnabled then return end
            for playerName, state in pairs(teleportPlayers) do
                if not teleportEnabled then break end
                if not state then continue end
                local target = Players:FindFirstChild(playerName)
                if not target then continue end
                local vars = target:FindFirstChild("NonSaveVars")
                if not vars then continue end
                local plotVal = vars:FindFirstChild("OwnsPlot")
                if not plotVal then continue end
                local plot = plotVal.Value
                if not plot then continue end
                enterNormally(plot)
                task.wait(math.random(30,32))
            end
        end)
        task.wait(0.25)
    end
end)

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
