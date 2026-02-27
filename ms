local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local RepLibrary = require(ReplicatedStorage.Modules.RepLibrary)
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local cam = workspace.CurrentCamera
local viewport = cam.ViewportSize
local winSize = UDim2.fromOffset(viewport.X * 0.25, viewport.Y * 0.25)

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
            local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myRoot then continue end
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

Tabs.Main:AddSection("Send Offers")

local sendOfferPlayers = {}
local sendOffersEnabled = false
local offerPercent = 0

Tabs.Main:AddDropdown("OfferPlayers", {
    Title = "Select Players to Send Offers",
    Values = getPlayerNames(),
    Multi = true,
    Default = {},
    Callback = function(Value)
        sendOfferPlayers = Value
    end
})

Tabs.Main:AddSlider("OfferPercentSlider", {
    Title = "Offer Percentage",
    Min = -50,
    Max = 50,
    Default = 0,
    Rounding = 0,
    Callback = function(Value)
        offerPercent = Value
    end
})

Tabs.Main:AddToggle("SendOffersToggle", {
    Title = "Send Offers (1s)",
    Default = false,
    Callback = function(Value)
        sendOffersEnabled = Value
    end
})

local MakeOfferRemote = ReplicatedStorage.Events.Shop.MakePlayerOffer
local GetInventoryRemote = ReplicatedStorage.Events.Data.Get

task.spawn(function()
    while task.wait(1) do
        if not sendOffersEnabled then continue end
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
end)

Window:SelectTab(Tabs.Main)
