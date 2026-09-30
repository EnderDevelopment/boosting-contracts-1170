Config = {}

-- Contract settings
Config.ContractPrice = 5000
Config.ContractCooldown = 300 -- 5 minutes in seconds

-- Minigame settings
Config.MinigameDuration = 10 -- seconds
Config.MinigameSuccessRate = 0.7 -- 70% chance to succeed

-- Vehicle settings
Config.VehicleModels = {
    'adder',
    'banshee',
    'bullet',
    'cheetah',
    'entityxf',
    'fmj',
    'infernus',
    'reaper',
    't20',
    'turismor',
    'vacca',
    'voltic',
    'zentorno'
}

-- Blip settings
Config.ContractBlipSprite = 225
Config.ContractBlipColor = 5
Config.ContractBlipScale = 1.0

-- Dispatch settings
Config.DispatchMessage = 'Boosting Contract: Vehicle delivery in progress'
Config.DispatchDuration = 30 -- seconds