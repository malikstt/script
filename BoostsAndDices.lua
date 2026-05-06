-- CONFIG
local POTIONS_TO_USE = {"luck","ultraLuck","currency","rollSpeed"}
local USE_DICES = true
local DICES_TO_USE = {"jackpotSpin","bigDice","hugeDice","shinyDice","invertedDice"}

-- SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Network = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("leifstout_networker@0.3.1")
    :WaitForChild("networker")
    :WaitForChild("_remotes")

local BoostRemote = Network:WaitForChild("BoostService"):WaitForChild("RemoteFunction")
local InventoryRemote = Network:WaitForChild("InventoryService"):WaitForChild("RemoteFunction")

local DataClient = require(ReplicatedStorage.Packages.DataService).client
DataClient:waitForData()

-- MAIN LOOP
while task.wait(1) do
    local items = DataClient:get("items") or {}
    local boosts = DataClient:get("boosts") or {}

    -- USE POTIONS
    for _, potion in ipairs(POTIONS_TO_USE) do
        local data = boosts[potion]
        if data and (data.amount or 0) > 0 then
            pcall(function()
                BoostRemote:InvokeServer("requestUseBoost", potion)
            end)
        end
    end

    -- USE DICES
    if USE_DICES then
        for _, dice in ipairs(DICES_TO_USE) do
            local amount = items[dice] or 0
            if amount > 0 then
                pcall(function()
                    InventoryRemote:InvokeServer("requestUseItem", dice)
                end)
            end
        end
    end
end
