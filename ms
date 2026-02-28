local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer

local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local MakeOfferRemote = ReplicatedStorage.Events.Shop.MakePlayerOffer
local GetRemote = ReplicatedStorage.Events.Data.Get
local GetAllRemote = ReplicatedStorage.Events.Data.GetAll
local AcceptRemote = ReplicatedStorage.Events.Shop.AcceptPlayerOffer
local SellRemote = ReplicatedStorage.Events.Shop.SellItemInShop

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize

local Window = Fluent:CreateWindow({
    Title = "Malik",
    SubTitle = "lmklmk",
    TabWidth = 160,
    Size = UDim2.fromOffset(viewport.X * 0.55, viewport.Y * 0.35),
    Acrylic = true,
    Theme = "Dark"
})

local Tabs = {
    Main = Window:AddTab({ Title = "Main", Icon = "home" })
}

local function getAllPlayers()
    local t = {}
    for _,p in ipairs(Players:GetPlayers()) do
        table.insert(t,p.Name)
    end
    return t
end

local function getOtherPlayers()
    local t = {}
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LocalPlayer then
            table.insert(t,p.Name)
        end
    end
    return t
end

local selectedTeleportPlayer=nil

Tabs.Main:AddDropdown("TeleportPlayer",{
    Title="Select Player Shop",
    Values=getAllPlayers(),
    Callback=function(v)
        selectedTeleportPlayer=v
    end
})

Tabs.Main:AddButton({
    Title="Teleport To Shop",
    Callback=function()
        pcall(function()
            if not selectedTeleportPlayer then return end
            local char=LocalPlayer.Character
            if not char then return end
            local target=Players:FindFirstChild(selectedTeleportPlayer)
            if not target then return end
            local plot=target.NonSaveVars.OwnsPlot.Value
            if not plot then return end
            local door=plot:FindFirstChild("Door",true)
            if not door then return end
            local part=door:FindFirstChild("StartPart")
            if not part then return end
            char:SetPrimaryPartCFrame(part.CFrame+Vector3.new(0,3,0))
        end)
    end
})

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
                for guid,itemData in pairs(inv) do
                    local info=ItemsModule[itemData.Id]
                    if not info then continue end
                    local placed=placedMap[info.Name]
                    if placed and #placed>0 then
                        local instance=table.remove(placed,1)
                        local price=RepLibrary:GetItemPrice(itemData)
                        local offer=math.floor(price*(1+offerPercent/100))
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

            local plotVal = LocalPlayer:FindFirstChild("NonSaveVars") and LocalPlayer.NonSaveVars:FindFirstChild("OwnsPlot")
            if not plotVal or not plotVal.Value then return end

            local plot = workspace:WaitForChild("Plots"):FindFirstChild(plotVal.Value.Name)
            if not plot then return end

            local shelves = {}
            local furnitureFolder = plot:FindFirstChild("Furniture")
            if not furnitureFolder then return end

            for _, furniture in ipairs(furnitureFolder:GetChildren()) do
                local s = furniture:FindFirstChild("Shelves")
                if s then
                    for _, shelf in ipairs(s:GetChildren()) do
                        table.insert(shelves, shelf)
                    end
                end
            end

            if #shelves == 0 then return end

            local freeShelves = {}
            for _, shelf in ipairs(shelves) do
                if #shelf:GetChildren() == 0 then
                    table.insert(freeShelves, shelf)
                end
            end

            if #freeShelves == 0 then return end

            local shelfIndex = 1

            for guid, info in pairs(data.Inventory) do
                if shelfIndex > #freeShelves then break end
                local id = tonumber(info.Id)
                local itemData = id and ItemsModule[id]
                local name = itemData and string.lower(itemData.Name or "") or ""
                if not info.ItemPlaced and id ~= 681 and id ~= 2294 and not string.find(name,"safe") then
                    pcall(function()
                        SellRemote:FireServer(guid, freeShelves[shelfIndex], true)
                    end)
                    shelfIndex += 1
                    task.wait(0.15)
                end
            end

        end)
        task.wait(1)
    end
end)

Window:SelectTab(Tabs.Main)
