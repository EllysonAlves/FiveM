-----------------------------------------------
-- cw-vehicledash | client/main.lua
-- Dashboard de veiculos (NUI tablet) usando a mesma lista das corridas
-- Comando: /carros
-----------------------------------------------

local isOpen      = false

-----------------------------------------------
-- Abrir a UI
-----------------------------------------------

local function openUI()
    if isOpen then return end
    isOpen = true

    local raceCars = lib.callback.await('alves-racingapp:getQuickRaceVehicles', false) or {}
    if #raceCars == 0 then
        isOpen = false
        lib.notify({ type = 'error', description = 'Lista de carros de corrida indisponível.' })
        return
    end

    local list = {}
    -- Lista direta dos carros usados nas corridas (sem scripts de classe externos)
    for _, modelName in ipairs(raceCars) do
        list[#list + 1] = {
            modelName = modelName,
            name = modelName:upper(), -- Nome em maiusculas
            brand = 'JFx',
            category = 'super',
            class = 'S', -- Todos são Classe S
            score = 100 -- Score fixo
        }
    end

    print('[cw-vehicledash] openUI: ' .. #list .. ' veiculos de corrida')
    SetNuiFocus(true, true)
    SendNUIMessage({ action = 'open', data = { vehicles = list } })
end

-----------------------------------------------
-- NUI Callbacks
-----------------------------------------------

-- Full Tuning Helper
local function applyFullTuning(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    -- Motor e performance
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false) -- Motor
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false) -- Freios  
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false) -- Transmissao
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false) -- Suspensao
    SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false) -- Blindagem
    
    -- Turbo
    ToggleVehicleMod(vehicle, 18, true)
    
    -- Xenon
    ToggleVehicleMod(vehicle, 22, true)
    
    -- Cor e extras
    SetVehicleColours(vehicle, 0, 0) -- Preto
    SetVehicleWindowTint(vehicle, 1) -- Vidro fumê
    
    -- Performance maxima
    SetVehicleEnginePowerMultiplier(vehicle, 50.0)
    SetVehicleEngineTorqueMultiplier(vehicle, 50.0)
    
    print('[cw-vehicledash] Full tuning aplicado')
end

RegisterNUICallback('spawnVehicle', function(data, cb)
    cb('ok')

    local modelName = data.modelName
    local vehName   = data.name or modelName

    CreateThread(function()
        local netId = lib.callback.await('cw-vehicledash:server:spawnVehicle', false, modelName)

        if not netId then
            SendNUIMessage({ action = 'spawnFail', data = { name = vehName } })
            return
        end

        local veh, attempts = nil, 0
        repeat
            veh = NetToVeh(netId)
            Wait(100)
            attempts = attempts + 1
        until DoesEntityExist(veh) or attempts > 50

        if not DoesEntityExist(veh) then
            SendNUIMessage({ action = 'spawnFail', data = { name = vehName } })
            return
        end

        -- Aplicar full tuning
        applyFullTuning(veh)
        
        SetVehicleNeedsToBeHotwired(veh, false)
        SetVehicleHasBeenOwnedByPlayer(veh, true)
        SetEntityAsMissionEntity(veh, true, false)
        SetVehicleIsStolen(veh, false)
        SetVehicleIsWanted(veh, false)
        SetVehicleEngineOn(veh, true, true, true)
        SetPedIntoVehicle(cache.ped, veh, -1)
        SetVehicleOnGroundProperly(veh)
        SetVehicleRadioEnabled(veh, true)
        SetVehRadioStation(veh, 'OFF')

        SendNUIMessage({ action = 'spawnOk', data = { name = vehName } })
    end)
end)

RegisterNUICallback('closeUI', function(_, cb)
    SetNuiFocus(false, false)
    isOpen = false
    cb('ok')
end)

-----------------------------------------------
-- Comando /carros
-----------------------------------------------

RegisterCommand('carros', function()
    openUI()
end, false)

TriggerEvent('chat:addSuggestion', '/carros', 'Abre o menu de carros usados nas corridas')
