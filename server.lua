local ESX = exports['es_extended']:getSharedObject()

-- Generate random coordinates
local function generateRandomCoords()
    local x = math.random(-2000, 2000)
    local y = math.random(-2000, 2000)
    local z = 30.0
    return {x = x, y = y, z = z}
end

-- Create a new contract
local function createContract()
    local vehicleModel = Config.VehicleModels[math.random(#Config.VehicleModels)]
    local startCoords = generateRandomCoords()
    local endCoords = generateRandomCoords()
    
    MySQL.Async.execute('INSERT INTO boosting_contracts (vehicle_model, start_location, end_location) VALUES (?, ?, ?)', {
        vehicleModel,
        json.encode(startCoords),
        json.encode(endCoords)
    }, function(rowsChanged)
        if rowsChanged > 0 then
            print('New boosting contract created')
        end
    end)
end

-- Get available contracts
ESX.RegisterServerCallback('boostingcontracts:getAvailableContracts', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    MySQL.Async.fetchAll('SELECT * FROM boosting_contracts WHERE status = "available"', {}, function(contracts)
        local formattedContracts = {}
        
        for _, contract in ipairs(contracts) do
            table.insert(formattedContracts, {
                id = contract.id,
                vehicle_model = contract.vehicle_model,
                start_location = contract.start_location,
                end_location = contract.end_location
            })
        end
        
        cb(formattedContracts)
    end)
end)

-- Accept a contract
RegisterNetEvent('boostingcontracts:acceptContract')
AddEventHandler('boostingcontracts:acceptContract', function(contractId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Check cooldown
    MySQL.Async.fetchScalar('SELECT last_contract FROM boosting_contract_cooldowns WHERE player_id = ?', {xPlayer.identifier}, function(lastContract)
        if lastContract and (os.time() - lastContract) < Config.ContractCooldown then
            xPlayer.showNotification('You must wait before accepting another contract.')
            return
        end
        
        -- Update contract status
        MySQL.Async.execute('UPDATE boosting_contracts SET status = "accepted", player_id = ?, accepted_at = NOW() WHERE id = ?', {
            xPlayer.identifier,
            contractId
        }, function(rowsChanged)
            if rowsChanged > 0 then
                -- Update cooldown
                MySQL.Async.execute('INSERT INTO boosting_contract_cooldowns (player_id, last_contract) VALUES (?, NOW()) ON DUPLICATE KEY UPDATE last_contract = NOW()', {
                    xPlayer.identifier
                })
                
                -- Get contract details
                MySQL.Async.fetchScalar('SELECT start_location FROM boosting_contracts WHERE id = ?', {contractId}, function(startLocation)
                    local startCoords = json.decode(startLocation)
                    TriggerClientEvent('boostingcontracts:contractAccepted', xPlayer.source, {
                        id = contractId,
                        start_coords = startCoords,
                        end_coords = json.decode(MySQL.Sync.fetchScalar('SELECT end_location FROM boosting_contracts WHERE id = ?', {contractId}))
                    })
                end)
            end
        end)
    end)
end)

-- Complete a contract
RegisterNetEvent('boostingcontracts:completeContract')
AddEventHandler('boostingcontracts:completeContract', function(contractId)
    local xPlayer = ESX.GetPlayerFromId(source)
    
    -- Update contract status
    MySQL.Async.execute('UPDATE boosting_contracts SET status = "completed", completed_at = NOW() WHERE id = ?', {contractId}, function(rowsChanged)
        if rowsChanged > 0 then
            -- Pay the player
            xPlayer.addAccountMoney('bank', Config.ContractPrice)
            xPlayer.showNotification(string.format('Contract completed! You have been paid $%d.', Config.ContractPrice))
            
            -- Create a new contract
            createContract()
        end
    end)
end)

-- Create initial contracts on resource start
Citizen.CreateThread(function()
    for i = 1, 5 do
        createContract()
        Citizen.Wait(1000)
    end
end)