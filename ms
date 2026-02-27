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
    SubTitle = "Parallel System",
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
        if shopSpamEnabled and next(selectedShops) ~= nil then
            pcall(function()
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
                    shopIndex = shopIndex + 1
                end
            end)
        end
        task.wait(0.05)
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
local GetAllRemote = ReplicatedStorage.Events.Data.GetAll

task.spawn(function()
    while true do
        if sendEnabled then
            for name, state in pairs(sendPlayers) do
                if state then
                    pcall(function()
                        local target = Players:FindFirstChild(name)
                        if not target then return end
                        
                        local targetData = GetAllRemote:InvokeServer(target)
                        if type(targetData) ~= "table" or not targetData.Inventory then return end
                        
                        local inv = targetData.Inventory
                        
                        local nonSaveVars = target:FindFirstChild("NonSaveVars")
                        if not nonSaveVars then return end
                        
                        local plotVal = nonSaveVars:FindFirstChild("OwnsPlot")
                        if not plotVal then return end
                        
                        local plot = plotVal.Value
                        if typeof(plot) ~= "Instance" then return end
                        
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
                            if not data.ItemPlaced then
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
                        end
                    end)
                end
            end
        end
        task.wait(1)
    end
end)

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

local placeEnabled = false

Tabs.Main:AddToggle("PlaceToggle", {
    Title = "Place Items",
    Default = false,
    Callback = function(v)
        placeEnabled = v
    end
})

local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop

task.spawn(function()
    while true do
        if placeEnabled then
            pcall(function()
                local myData = GetAllRemote:InvokeServer()
                if not myData or not myData.Inventory then return end
                
                local nonSaveVars = LocalPlayer:FindFirstChild("NonSaveVars")
                if not nonSaveVars then return end
                
                local plotVal = nonSaveVars:FindFirstChild("OwnsPlot")
                if not plotVal then return end
                
                local plot = plotVal.Value
                if typeof(plot) ~= "Instance" then return end
                
                local shelves = {}
                for _, f in pairs(plot.Furniture:GetChildren()) do
                    local s = f:FindFirstChild("Shelves")
                    if s then
                        for _, shelf in pairs(s:GetChildren()) do
                            table.insert(shelves,shelf)
                        end
                    end
                end
                
                local availableGuids = {}
                for guid, info in pairs(myData.Inventory) do
                    if not info.ItemPlaced then
                        table.insert(availableGuids, guid)
                    end
                end
                
                for i=1, math.min(#availableGuids,#shelves) do
                    SellRemote:FireServer(availableGuids[i],shelves[i],true)
                    task.wait(0.1)
                end
            end)
        end
        task.wait(1)
    end
end)

Window:SelectTab(Tabs.Main)
