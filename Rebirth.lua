local ReplicatedStorage = game:GetService("ReplicatedStorage")

local dataService = require(ReplicatedStorage.Packages.DataService).client

local rebirthRemote = ReplicatedStorage:WaitForChild("Packages")
    :WaitForChild("_Index")
    :WaitForChild("leifstout_networker@0.3.1")
    :WaitForChild("networker")
    :WaitForChild("_remotes")
    :WaitForChild("RebirthService")
    :WaitForChild("RemoteFunction")

local requiredZone = 15 -- Change this to whatever zone you want

while true do
    local currentRebirths = dataService:get("rebirths") or 0
    local currentGoop = dataService:get("goop") or 0
    local furthestZone = dataService:get("furthestZone") or 0

    local nextCost = (2 ^ currentRebirths) * 500

    if furthestZone < requiredZone then
        print("Waiting for furthest zone to reach " .. requiredZone .. ". Current: " .. furthestZone)
    elseif currentGoop >= nextCost then
        print("Rebirthing...")
        pcall(function()
            rebirthRemote:InvokeServer("requestRebirth")
        end)
    else
        local remaining = nextCost - currentGoop
        print("Not enough goop. Need:", remaining)
    end

    task.wait(10)
end
