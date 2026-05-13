-----------------------------------------------
-- cw-vehicledash | client/main.lua
-- Dashboard de veiculos (NUI tablet) usando a mesma lista das corridas
-- Comando: /carros
-----------------------------------------------

local isOpen = false
local cachedRaceCars = {}
local VisualModTypes = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 48 }

local function getVehicleModelName(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local modelHash = GetEntityModel(vehicle)
    for _, modelName in ipairs(cachedRaceCars) do
        if GetHashKey(modelName) == modelHash then return modelName end
    end
    return string.lower(GetDisplayNameFromVehicleModel(modelHash) or '')
end

local function captureVehicleVisualPreset(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    SetVehicleModKit(vehicle, 0)
    local primary, secondary = GetVehicleColours(vehicle)
    local pearlescent, wheelColor = GetVehicleExtraColours(vehicle)
    local neon = {}
    for i = 0, 3 do neon[tostring(i)] = IsVehicleNeonLightEnabled(vehicle, i) end
    local neonR, neonG, neonB = GetVehicleNeonLightsColour(vehicle)
    local smokeR, smokeG, smokeB = GetVehicleTyreSmokeColor(vehicle)
    local mods = {}
    for _, modType in ipairs(VisualModTypes) do
        mods[tostring(modType)] = { index = GetVehicleMod(vehicle, modType), customTires = GetVehicleModVariation(vehicle, modType) == 1 }
    end
    local extras = {}
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId) end
    end
    return {
        primary = primary, secondary = secondary, pearlescent = pearlescent, wheelColor = wheelColor,
        windowTint = GetVehicleWindowTint(vehicle), plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        wheelType = GetVehicleWheelType(vehicle), livery = GetVehicleLivery(vehicle),
        xenonColor = GetVehicleXenonLightsColor(vehicle), interiorColor = GetVehicleInteriorColor(vehicle), dashboardColor = GetVehicleDashboardColor(vehicle),
        neon = neon, neonColor = { r = neonR, g = neonG, b = neonB }, tyreSmokeColor = { r = smokeR, g = smokeG, b = smokeB },
        mods = mods, extras = extras
    }
end

local function applyVehicleVisualPreset(vehicle, preset)
    if not DoesEntityExist(vehicle) or type(preset) ~= 'table' then return end
    SetVehicleModKit(vehicle, 0)
    if preset.wheelType then SetVehicleWheelType(vehicle, preset.wheelType) end
    if preset.primary and preset.secondary then SetVehicleColours(vehicle, preset.primary, preset.secondary) end
    if preset.pearlescent and preset.wheelColor then SetVehicleExtraColours(vehicle, preset.pearlescent, preset.wheelColor) end
    if preset.windowTint then SetVehicleWindowTint(vehicle, preset.windowTint) end
    if preset.plateIndex then SetVehicleNumberPlateTextIndex(vehicle, preset.plateIndex) end
    if preset.interiorColor then SetVehicleInteriorColor(vehicle, preset.interiorColor) end
    if preset.dashboardColor then SetVehicleDashboardColor(vehicle, preset.dashboardColor) end
    if preset.xenonColor then SetVehicleXenonLightsColor(vehicle, preset.xenonColor) end
    if preset.neon then for key, enabled in pairs(preset.neon) do SetVehicleNeonLightEnabled(vehicle, tonumber(key), enabled == true) end end
    if preset.neonColor then SetVehicleNeonLightsColour(vehicle, preset.neonColor.r or 255, preset.neonColor.g or 255, preset.neonColor.b or 255) end
    if preset.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, preset.tyreSmokeColor.r or 255, preset.tyreSmokeColor.g or 255, preset.tyreSmokeColor.b or 255) end
    if preset.mods then
        for key, mod in pairs(preset.mods) do
            if type(mod) == 'table' and mod.index and mod.index >= -1 then SetVehicleMod(vehicle, tonumber(key), mod.index, mod.customTires == true) end
        end
    end
    if preset.livery and preset.livery >= 0 then SetVehicleLivery(vehicle, preset.livery) end
    if preset.extras then for key, enabled in pairs(preset.extras) do SetVehicleExtra(vehicle, tonumber(key), enabled and 0 or 1) end end
end

local function applySavedVisualPreset(vehicle, modelName)
    local preset = lib.callback.await('alves-racingapp:getVehiclePreset', false, tostring(modelName):lower())
    if preset then applyVehicleVisualPreset(vehicle, preset) end
end

-----------------------------------------------
-- Abrir a UI
-----------------------------------------------

local function openUI()
    if isOpen then return end
    isOpen = true

    local raceCars = lib.callback.await('alves-racingapp:getQuickRaceVehicles', false) or {}
    cachedRaceCars = raceCars
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
    SendNUIMessage({
        action = 'open',
        data = {
            vehicles = list,
            theme = {
                primary = GetConvar('alves:themePrimary', '#8b5cf6'),
                background = GetConvar('alves:themeBackground', '#080712')
            }
        }
    })
end

-----------------------------------------------
-- NUI Callbacks
-----------------------------------------------

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

        applySavedVisualPreset(veh, modelName)
        
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

RegisterNUICallback('savePreset', function(_, cb)
    cb('ok')
    local vehicle = GetVehiclePedIsIn(cache.ped, false)
    if not DoesEntityExist(vehicle) then
        SendNUIMessage({ action = 'presetFail', data = { message = 'Entre em um carro para salvar o visual.' } })
        return
    end
    if #cachedRaceCars == 0 then cachedRaceCars = lib.callback.await('alves-racingapp:getQuickRaceVehicles', false) or {} end
    local modelName = getVehicleModelName(vehicle)
    if not modelName or modelName == '' then
        SendNUIMessage({ action = 'presetFail', data = { message = 'Modelo do veículo não identificado.' } })
        return
    end
    local ok = lib.callback.await('alves-racingapp:saveVehiclePreset', false, {
        vehicleModel = modelName,
        preset = captureVehicleVisualPreset(vehicle)
    })
    SendNUIMessage({ action = ok and 'presetOk' or 'presetFail', data = { name = modelName } })
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
