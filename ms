local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local DataEvent = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Data"):WaitForChild("GetAll")
local ItemsModule = require(ReplicatedStorage.Modules.Items)

local PODIUM_ID = "4"

-- Function to count podiums in Furniture (placed)
local function countPlacedPodiums(playerData)
    local count = 0
    local podiumList = {}
    
    if playerData and playerData.Furniture then
        for guid, furnitureData in pairs(playerData.Furniture) do
            if tostring(furnitureData.Id) == PODIUM_ID then
                count = count + 1
                table.insert(podiumList, {
                    guid = guid,
                    id = furnitureData.Id,
                    floor = furnitureData.Floor
                })
            end
        end
    end
    
    return count, podiumList
end

-- Function to count podiums in Inventory (unplaced)
local function countInventoryPodiums(playerData)
    local count = 0
    local podiumList = {}
    
    if playerData and playerData.Inventory then
        for guid, itemData in pairs(playerData.Inventory) do
            if tostring(itemData.Id) == PODIUM_ID then
                -- Verify it's actually a Floor Podium
                local itemInfo = ItemsModule[PODIUM_ID]
                if itemInfo and itemInfo.Name == "Floor Podium" then
                    count = count + 1
                    table.insert(podiumList, {
                        guid = guid,
                        id = itemData.Id,
                        data = itemData
                    })
                end
            end
        end
    end
    
    return count, podiumList
end

-- Main function to get podium counts
local function getPodiumCounts()
    print("\n" .. string.rep("=", 40))
    print("FETCHING PODIUM DATA...")
    print(string.rep("=", 40))
    
    -- Get player data
    local success, playerData = pcall(function()
        return DataEvent:InvokeServer()
    end)
    
    if not success or not playerData then
        print("❌ Failed to get player data")
        return
    end
    
    -- Get counts
    local placedCount, placedList = countPlacedPodiums(playerData)
    local inventoryCount, inventoryList = countInventoryPodiums(playerData)
    
    -- Display results
    print("\n📊 PODIUM COUNTS:")
    print(string.rep("-", 30))
    print("🪑 Placed podiums:   " .. placedCount)
    print("📦 Inventory podiums: " .. inventoryCount)
    print("💰 Total owned:      " .. (placedCount + inventoryCount))
    
    -- Show individual podiums if any exist
    if placedCount > 0 then
        print("\n🏠 PLACED PODIUMS:")
        for i, podium in ipairs(placedList) do
            print(string.format("  %d. GUID: %s (Floor %s)", i, podium.guid, tostring(podium.floor)))
        end
    end
    
    if inventoryCount > 0 then
        print("\n📦 INVENTORY PODIUMS:")
        for i, podium in ipairs(inventoryList) do
            print(string.format("  %d. GUID: %s", i, podium.guid))
        end
    end
    
    print("\n" .. string.rep("=", 40))
    
    return {
        placed = placedCount,
        inventory = inventoryCount,
        total = placedCount + inventoryCount,
        placedList = placedList,
        inventoryList = inventoryList
    }
end

-- Run once
getPodiumCounts()

-- Optional: Keep checking every 30 seconds
while true do
    task.wait(30)
    getPodiumCounts()
end
