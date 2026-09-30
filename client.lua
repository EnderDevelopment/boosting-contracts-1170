local ESX = exports['es_extended']:getSharedObject()

local currentContract = nil
local minigameActive = false
local dispatchBlip = nil

-- Phone interaction
RegisterNetEvent('boostingcontracts:openPhone')
AddEventHandler('boostingcontracts:openPhone', function()
    ESX.UI.Menu.CloseAll()
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'boosting_contracts', {
        title = 'Boosting Contracts',
        align = 'top-left',
        elements = {{
            label = 'Available Contracts',
            value = 'available_contracts'
        }}
    }, function(data, menu)
        if data.current.value == 'available_contracts' then
            TriggerServerEvent('boostingcontracts:getAvailableContracts')
        end
    end, function(data, menu)
        menu.close()
    end)
end)

-- Get available contracts
RegisterNetEvent('boostingcontracts:showAvailableContracts')
AddEventHandler('boostingcontracts:showAvailableContracts', function(contracts)
    local elements = {}
    for _, contract in ipairs(contracts) do
        table.insert(elements, {
            label = string.format('Boost %s from %s to %s - $%d', contract.vehicle_model, contract.start_location, contract.end_location, Config.ContractPrice),
            value = contract.id
        })
    end
    
    ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'available_contracts', {
        title = 'Available Contracts',
        align = 'top-left',
        elements = elements
    }, function(data, menu)
        TriggerServerEvent('boostingcontracts:acceptContract', data.current.value)
        menu.close()
    end, function(data, menu)
        menu.close()
    end)
end)

-- Accept contract
RegisterNetEvent('boostingcontracts:contractAccepted')
AddEventHandler('boostingcontracts:contractAccepted', function(contract)
    currentContract = contract
    ESX.ShowNotification('Contract accepted! Locate the vehicle.')
    
    -- Create blip for vehicle location
    local blip = AddBlipForCoord(contract.start_coords.x, contract.start_coords.y, contract.start_coords.z)
    SetBlipSprite(blip, Config.ContractBlipSprite)
    SetBlipColour(blip, Config.ContractBlipColor)
    SetBlipScale(blip, Config.ContractBlipScale)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Vehicle Location')
    EndTextCommandSetBlipName(blip)
    
    -- Check if player is near the vehicle
    Citizen.CreateThread(function()
        while currentContract do
            Citizen.Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(contract.start_coords.x, contract.start_coords.y, contract.start_coords.z))
            
            if distance < 5.0 then
                RemoveBlip(blip)
                ESX.ShowNotification('You have located the vehicle. Prepare to defeat the tracker.')
                TriggerEvent('boostingcontracts:startMinigame')
                break
            end
        end
    end)
end)

-- Minigame
RegisterNetEvent('boostingcontracts:startMinigame')
AddEventHandler('boostingcontracts:startMinigame', function()
    minigameActive = true
    ESX.ShowNotification('Defeat the tracker!')
    
    -- Simple minigame: press a key within a time limit
    Citizen.CreateThread(function()
        local startTime = GetGameTimer()
        local success = false
        
        while GetGameTimer() - startTime < Config.MinigameDuration * 1000 do
            Citizen.Wait(0)
            
            if IsControlJustPressed(0, 38) then -- E key
                if math.random() < Config.MinigameSuccessRate then
                    success = true
                    break
                else
                    ESX.ShowNotification('Failed to defeat the tracker!')
                    minigameActive = false
                    return
                end
            end
        end
        
        if success then
            ESX.ShowNotification('Tracker defeated! Deliver the vehicle.')
            TriggerEvent('boostingcontracts:startDelivery')
        else
            ESX.ShowNotification('Time is up! Tracker still active.')
        end
        
        minigameActive = false
    end)
end)

-- Delivery
RegisterNetEvent('boostingcontracts:startDelivery')
AddEventHandler('boostingcontracts:startDelivery', function()
    -- Create blip for delivery location
    local blip = AddBlipForCoord(currentContract.end_coords.x, currentContract.end_coords.y, currentContract.end_coords.z)
    SetBlipSprite(blip, Config.ContractBlipSprite)
    SetBlipColour(blip, Config.ContractBlipColor)
    SetBlipScale(blip, Config.ContractBlipScale)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString('Delivery Location')
    EndTextCommandSetBlipName(blip)
    
    -- Dispatch alert
    dispatchBlip = AddBlipForCoord(currentContract.end_coords.x, currentContract.end_coords.y, currentContract.end_coords.z)
    SetBlipSprite(dispatchBlip, 161)
    SetBlipColour(dispatchBlip, 1)
    SetBlipScale(dispatchBlip, 1.0)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(Config.DispatchMessage)
    EndTextCommandSetBlipName(dispatchBlip)
    
    -- Check if player is near the delivery location
    Citizen.CreateThread(function()
        while currentContract do
            Citizen.Wait(1000)
            local playerCoords = GetEntityCoords(PlayerPedId())
            local distance = #(playerCoords - vector3(currentContract.end_coords.x, currentContract.end_coords.y, currentContract.end_coords.z))
            
            if distance < 5.0 then
                RemoveBlip(blip)
                RemoveBlip(dispatchBlip)
                TriggerServerEvent('boostingcontracts:completeContract', currentContract.id)
                currentContract = nil
                break
            end
        end
    end)
end)

-- Cleanup
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        if dispatchBlip then
            RemoveBlip(dispatchBlip)
        end
    end
end)