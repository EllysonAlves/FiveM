-- Alves Racing - Client
-- Sistema de corridas baseado em cw-racingapp

print('^2[Alves Racing]^0 Client iniciado!')

local inRace = false
local inLobby = false
local lobbyOpen = false
local CurrentRaceData = {}
local checkpointBlips = {}
local checkpointProps = {}
local startTime = 0
local lapStartTime = 0
local phasedVehicle = 0
local lastProgressSync = 0

-- ==================== CONFIGURAÇÃO ====================
-- Config vem de config.lua (shared_script). Mantemos fallback para compatibilidade.
Config = Config or {}
Config.CheckpointBuffer = Config.CheckpointBuffer or 5.0
Config.MarkAmountOfCheckpointsAhead = Config.CheckpointsAhead or Config.MarkAmountOfCheckpointsAhead or 8
Config.ShowGpsRoute = Config.ShowGpsRoute ~= false
Config.UseRoadsForGps = Config.UseRoadsForGps ~= false
Config.GpsColor = Config.GpsColor or 83
Config.BlipColor = Config.BlipColor or 85
Config.MapBlipsAhead = Config.MapBlipsAhead or 4
Config.CheckpointPropsAhead = Config.CheckpointPropsAhead or Config.MapBlipsAhead or 4
Config.CheckpointPropModel = Config.CheckpointPropModel or 'prop_offroad_tyres02'
Config.DefaultTotalRacers = Config.DefaultTotalRacers or 1
Config.RaceVehiclePhase = Config.RaceVehiclePhase ~= false
Config.DrawTextSetup = Config.DrawTextSetup or {
    markerType = 1,
    minHeight = 1.0,
    maxHeight = 30.0,
    baseSize = 0.1,
    markerColor = { r = 139, g = 92, b = 246, a = 220 },
    distanceColor = { r = 255, g = 255, b = 255, a = 255 },
    primaryColor = { r = 168, g = 85, b = 247, a = 255 }
}

-- ==================== COMANDOS ====================
RegisterCommand('race', function()
    print('[Alves Racing] Comando /race executado')
    if inLobby then
        lobbyOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'maximizeLobby' })
        return
    end
    openTablet()
end, false)

RegisterKeyMapping('race', 'Abrir Menu de Corridas', 'keyboard', 'F1')
print('^2[Alves Racing]^0 F1 registrado para abrir menu')

RegisterCommand('race_lobby_toggle', function()
    if not inLobby then return end

    lobbyOpen = not lobbyOpen
    SetNuiFocus(lobbyOpen, lobbyOpen)
    SendNUIMessage({ action = lobbyOpen and 'maximizeLobby' or 'minimizeLobby' })
end, false)

RegisterKeyMapping('race_lobby_toggle', 'Abrir/fechar lobby de corrida', 'keyboard', 'F2')

RegisterCommand('race_lobby_leave', function()
    if not inLobby then return end

    inLobby = false
    lobbyOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'hideLobby' })
    TriggerServerEvent('alves-racingapp:server:leaveRace')
    lib.notify({ type = 'inform', description = 'Você saiu do lobby' })
end, false)

RegisterKeyMapping('race_lobby_leave', 'Sair do lobby de corrida', 'keyboard', 'F3')

RegisterCommand('sair', function()
    if not inRace then
        lib.notify({ type = 'error', description = 'Você não está em uma corrida' })
        return
    end
    
    leaveRace()
end, false)

-- ==================== FUNÇÕES AUXILIARES ====================
local function awaitServerCallback(name, ...)
    local ok, result = pcall(lib.callback.await, name, false, ...)
    if ok then return result end

    print(('[Alves Racing] Callback indisponível: %s | %s'):format(name, tostring(result)))
    return nil
end

function openTablet()
    local playerInfo = awaitServerCallback('alves-racingapp:getPlayerInfo')
    if not playerInfo then
        lib.notify({
            type = 'error',
            description = 'Servidor do Alves Racing ainda não está pronto. Reinicie/ensure o alves-racingapp no servidor.'
        })
        return
    end

    local onlineCount = awaitServerCallback('alves-racingapp:getOnlineCount') or 0
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openTablet',
        data = {
            player = playerInfo,
            onlineCount = onlineCount or 0,
            theme = Config.Theme
        }
    })
end

function finishRace()
    local finalTime = CurrentRaceData.TotalTime
    local raceId = CurrentRaceData.RaceId
    local raceName = CurrentRaceData.RaceName
    local raceType = CurrentRaceData.RaceType or 'casual'
    local veh = GetVehiclePedIsIn(PlayerPedId(), false)
    local vehicleName = 'Unknown'
    
    if DoesEntityExist(veh) then
        vehicleName = CurrentRaceData.VehicleModel or GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    end
    
    print(string.format('[Alves Racing Client] Finalizando corrida: %s - Tempo: %dms', raceName, finalTime))
    
    -- Salvar tempo no banco
    TriggerServerEvent('alves-racingapp:server:finishRace', {
        raceId = raceId,
        raceName = raceName,
        totalTime = finalTime,
        laps = CurrentRaceData.TotalLaps,
        checkpoints = CurrentRaceData.TotalCheckpoints or #(CurrentRaceData.Checkpoints or {}),
        bestLap = CurrentRaceData.BestLap or 0,
        vehicle = vehicleName,
        raceType = raceType,
        raceClass = CurrentRaceData.RaceClass
    })
    
    Wait(500)
    leaveRace()
end

function leaveRace()
    disableRaceVehiclePhase()
    inRace = false
    clearCheckpoints()
    CurrentRaceData = {}
    
    -- Esconder HUD e contagem regressiva
    SendNUIMessage({ action = 'hideRaceHUD' })
    SendNUIMessage({ action = 'hideCountdown' })
    
    TriggerServerEvent('alves-racingapp:server:leaveRace')
    
    lib.notify({ type = 'inform', description = 'Você saiu da corrida' })
end

function clearCheckpoints()
    for _, blip in pairs(checkpointBlips) do
        if DoesBlipExist(blip) then
            SetBlipRoute(blip, false)
            RemoveBlip(blip)
        end
    end
    checkpointBlips = {}

    for _, prop in pairs(checkpointProps) do
        if DoesEntityExist(prop) then
            SetEntityAsMissionEntity(prop, true, true)
            DeleteObject(prop)
        end
    end
    checkpointProps = {}
    
    -- Limpar GPS route
    ClearGpsCustomRoute()
    ClearGpsMultiRoute()
end

function CreateCheckpointBlip(coords, id)
    local Blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(Blip, 1)
    SetBlipDisplay(Blip, 4)
    SetBlipScale(Blip, 0.8)
    SetBlipAsShortRange(Blip, true)
    SetBlipColour(Blip, Config.BlipColor) -- Roxo
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentSubstringPlayerName("Checkpoint: " .. id)
    EndTextCommandSetBlipName(Blip)
    return Blip
end

function setupBlipsForRace()
    clearCheckpoints()
    refreshCheckpointMarkers()
    updateGpsForRace()
end

function getCheckpointDataByRaceIndex(index, totalCheckpoints)
    if CurrentRaceData.TotalLaps == 0 and index > totalCheckpoints then
        return nil, nil
    end

    if CurrentRaceData.Lap > 0 and CurrentRaceData.Lap == CurrentRaceData.TotalLaps then
        if index - 1 == totalCheckpoints then
            return CurrentRaceData.Checkpoints[1], 1
        elseif index > totalCheckpoints then
            return nil, nil
        end
    end

    local checkpointIndex = (index - 1) % totalCheckpoints + 1
    return CurrentRaceData.Checkpoints[checkpointIndex], checkpointIndex
end

function loadCheckpointPropModel()
    local model = GetHashKey(Config.CheckpointPropModel)
    if not IsModelInCdimage(model) then
        print(('[Alves Racing] Prop de checkpoint inválido: %s'):format(Config.CheckpointPropModel))
        return nil
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 2000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do
        Wait(10)
    end

    if not HasModelLoaded(model) then
        print(('[Alves Racing] Falha ao carregar prop de checkpoint: %s'):format(Config.CheckpointPropModel))
        return nil
    end

    return model
end

function createCheckpointProp(coords, heading)
    local model = loadCheckpointPropModel()
    if not model then return nil end

    local prop = CreateObject(model, coords.x, coords.y, (coords.z or 0.0) - 0.15, false, false, false)
    if DoesEntityExist(prop) then
        SetEntityHeading(prop, heading or 0.0)
        FreezeEntityPosition(prop, true)
        SetEntityCollision(prop, false, false)
        SetEntityAlpha(prop, 235, false)
        return prop
    end

    return nil
end

function refreshCheckpointMarkers()
    for _, blip in pairs(checkpointBlips) do
        if DoesBlipExist(blip) then
            SetBlipRoute(blip, false)
            RemoveBlip(blip)
        end
    end
    checkpointBlips = {}

    for _, prop in pairs(checkpointProps) do
        if DoesEntityExist(prop) then
            SetEntityAsMissionEntity(prop, true, true)
            DeleteObject(prop)
        end
    end
    checkpointProps = {}

    local totalCheckpoints = #CurrentRaceData.Checkpoints
    local currentIndex = CurrentRaceData.CurrentCheckpoint + 1
    local amount = Config.MapBlipsAhead or 4
    local propsAhead = Config.CheckpointPropsAhead or amount

    for i = 0, amount - 1 do
        local raceIndex = currentIndex + i
        local checkpointData, checkpointIndex = getCheckpointDataByRaceIndex(raceIndex, totalCheckpoints)
        if not checkpointData then break end

        local blip = CreateCheckpointBlip(checkpointData.coords, checkpointIndex)
        if i == 0 then
            nextBlip(blip)
        end
        checkpointBlips[raceIndex] = blip

        if i < propsAhead and checkpointData.offset and checkpointData.offset.left and checkpointData.offset.right then
            local left = checkpointData.offset.left
            local right = checkpointData.offset.right
            local heading = GetHeadingFromVector_2d(right.x - left.x, right.y - left.y)
            local leftProp = createCheckpointProp(left, heading)
            local rightProp = createCheckpointProp(right, heading)

            if leftProp then checkpointProps[#checkpointProps + 1] = leftProp end
            if rightProp then checkpointProps[#checkpointProps + 1] = rightProp end
        end
    end
end

function updateGpsForRace()
    ClearGpsMultiRoute()
    ClearGpsCustomRoute()

    if Config.UseRoadsForGps then
        StartGpsMultiRoute(Config.GpsColor, true, true)
    else
        StartGpsCustomRoute(Config.GpsColor, true, true)
    end
    
    -- CurrentCheckpoint representa o último checkpoint já alcançado.
    -- A rota precisa começar no PRÓXIMO checkpoint, senão o GPS tenta voltar para trás
    -- e fica com traçado estranho entre os pontos.
    local currentCheckpoint = (CurrentRaceData.CurrentCheckpoint or 0) + 1
    local lastCheckpoint = currentCheckpoint + Config.MarkAmountOfCheckpointsAhead - 1
    local totalCheckpoints = #CurrentRaceData.Checkpoints
    local isCircuit = CurrentRaceData.TotalLaps > 0
    
    for i = currentCheckpoint, lastCheckpoint do
        local checkpointIndex = isCircuit and ((i - 1) % totalCheckpoints) + 1 or i
        if checkpointIndex > totalCheckpoints and not isCircuit then break end
        
        local checkpointData = CurrentRaceData.Checkpoints[checkpointIndex]
        local coords = checkpointData.coords
        
        if Config.UseRoadsForGps then
            AddPointToGpsMultiRoute(coords.x, coords.y, coords.z or 0.0)
        else
            AddPointToGpsCustomRoute(coords.x, coords.y, coords.z or 0.0)
        end
    end
    
    if Config.UseRoadsForGps then
        SetGpsMultiRouteRender(Config.ShowGpsRoute)
    else
        SetGpsCustomRouteRender(Config.ShowGpsRoute, Config.GpsColor, Config.GpsColor)
    end
end

function passedBlip(blip)
    if DoesBlipExist(blip) then
        SetBlipRoute(blip, false)
        SetBlipColour(blip, 79) -- Roxo escuro (completo)
    end
end

function nextBlip(blip)
    if DoesBlipExist(blip) then
        -- Apenas destaca o próximo checkpoint. A rota fica a cargo do GPS multi-route,
        -- evitando conflito entre SetBlipRoute e StartGpsMultiRoute.
        SetBlipRoute(blip, false)
        SetBlipColour(blip, Config.GpsColor or 83)
    end
end

function getMaxDistance(center, offsetCoords)
    local distance = #(vector3(center.x, center.y, center.z) - vector3(offsetCoords.left.x, offsetCoords.left.y, offsetCoords.left.z))
    return distance + Config.CheckpointBuffer
end

function DrawRacingMarker(coords, height)
    local cfg = Config.DrawTextSetup
    DrawMarker(cfg.markerType, coords.x, coords.y, coords.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, cfg.baseSize, cfg.baseSize, height, cfg.markerColor.r, cfg.markerColor.g, cfg.markerColor.b, cfg.markerColor.a, false, true, 2, nil, nil, false)
end

function Draw3DText(coords, text, scale, color)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(color.r, color.g, color.b, color.a)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
    end
end

function getCheckpointCoord(index, totalCheckpoints)
    if CurrentRaceData.TotalLaps == 0 and index > #CurrentRaceData.Checkpoints then
        return nil
    end
    
    if CurrentRaceData.Lap > 0 and CurrentRaceData.Lap == CurrentRaceData.TotalLaps then
        if index - 1 == totalCheckpoints then
            return vector3(CurrentRaceData.Checkpoints[1].coords.x, CurrentRaceData.Checkpoints[1].coords.y, CurrentRaceData.Checkpoints[1].coords.z)
        elseif index > totalCheckpoints then
            return nil
        end
    end
    
    index = (index - 1) % totalCheckpoints + 1
    return vector3(CurrentRaceData.Checkpoints[index].coords.x, CurrentRaceData.Checkpoints[index].coords.y, CurrentRaceData.Checkpoints[index].coords.z)
end

function getFinishLabel(totalCheckpoints, index)
    if CurrentRaceData.TotalLaps == 0 and totalCheckpoints == index then
        return 'CHEGADA'
    elseif index - 1 == totalCheckpoints then
        if CurrentRaceData.Lap == CurrentRaceData.TotalLaps then
            return 'CHEGADA'
        else
            return 'PRÓXIMA VOLTA'
        end
    end
    return nil
end

function getUpcomingCheckpoints()
    local checkpoints = {}
    local totalCheckpoints = #CurrentRaceData.Checkpoints
    local currentIndex = CurrentRaceData.CurrentCheckpoint + 1
    
    for i = 0, 2 do
        local index = currentIndex + i
        local coord = getCheckpointCoord(index, totalCheckpoints)
        if coord then
            local label = getFinishLabel(totalCheckpoints, index) or "Checkpoint " .. ((index - 1) % totalCheckpoints + 1)
            checkpoints[#checkpoints + 1] = { coord = coord, label = label }
        end
    end
    
    return checkpoints
end

local VisualModTypes = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 48 }

local function getRaceVehicleModels()
    return lib.callback.await('alves-racingapp:getQuickRaceVehicles', false) or {}
end

local function getVehicleModelName(vehicle)
    if not DoesEntityExist(vehicle) then return nil end
    local modelHash = GetEntityModel(vehicle)
    for _, modelName in ipairs(getRaceVehicleModels()) do
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
        mods[tostring(modType)] = {
            index = GetVehicleMod(vehicle, modType),
            customTires = GetVehicleModVariation(vehicle, modType) == 1
        }
    end

    local extras = {}
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId)
        end
    end

    return {
        primary = primary,
        secondary = secondary,
        pearlescent = pearlescent,
        wheelColor = wheelColor,
        windowTint = GetVehicleWindowTint(vehicle),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        wheelType = GetVehicleWheelType(vehicle),
        livery = GetVehicleLivery(vehicle),
        xenonColor = GetVehicleXenonLightsColor(vehicle),
        interiorColor = GetVehicleInteriorColor(vehicle),
        dashboardColor = GetVehicleDashboardColor(vehicle),
        neon = neon,
        neonColor = { r = neonR, g = neonG, b = neonB },
        tyreSmokeColor = { r = smokeR, g = smokeG, b = smokeB },
        mods = mods,
        extras = extras
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
    if preset.neon then
        for key, enabled in pairs(preset.neon) do SetVehicleNeonLightEnabled(vehicle, tonumber(key), enabled == true) end
    end
    if preset.neonColor then SetVehicleNeonLightsColour(vehicle, preset.neonColor.r or 255, preset.neonColor.g or 255, preset.neonColor.b or 255) end
    if preset.tyreSmokeColor then SetVehicleTyreSmokeColor(vehicle, preset.tyreSmokeColor.r or 255, preset.tyreSmokeColor.g or 255, preset.tyreSmokeColor.b or 255) end
    if preset.mods then
        for key, mod in pairs(preset.mods) do
            if type(mod) == 'table' and mod.index and mod.index >= -1 then
                SetVehicleMod(vehicle, tonumber(key), mod.index, mod.customTires == true)
            end
        end
    end
    if preset.livery and preset.livery >= 0 then SetVehicleLivery(vehicle, preset.livery) end
    if preset.extras then
        for key, enabled in pairs(preset.extras) do SetVehicleExtra(vehicle, tonumber(key), enabled and 0 or 1) end
    end
end

local function applySavedVisualPreset(vehicle, modelName)
    modelName = modelName and tostring(modelName):lower() or getVehicleModelName(vehicle)
    if not modelName or modelName == '' then return end
    local preset = lib.callback.await('alves-racingapp:getVehiclePreset', false, modelName)
    if preset then applyVehicleVisualPreset(vehicle, preset) end
end



local function loadGarageModel(modelName)
    local model = joaat(modelName)
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then return nil end

    RequestModel(model)
    local deadline = GetGameTimer() + 5000
    while not HasModelLoaded(model) and GetGameTimer() < deadline do
        Wait(50)
    end

    if not HasModelLoaded(model) then return nil end
    return model
end

local function spawnLocalGarageVehicle(modelName)
    local model = loadGarageModel(modelName)
    if not model then return nil, 'Modelo indisponível ou não carregado no client.' end

    local ped = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    if DoesEntityExist(currentVehicle) then
        SetEntityAsMissionEntity(currentVehicle, true, true)
        DeleteVehicle(currentVehicle)
    end

    local coords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.0)
    local heading = GetEntityHeading(ped)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    local veh = CreateVehicle(model, coords.x, coords.y, coords.z + 0.35, heading, true, false)
    SetModelAsNoLongerNeeded(model)

    if not DoesEntityExist(veh) then return nil, 'Falha ao criar veículo no client.' end

    local netId = VehToNet(veh)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)

    SetEntityAsMissionEntity(veh, true, true)
    SetVehicleOnGroundProperly(veh)
    return veh, nil
end

local function prepareGarageVehicle(vehicle)
    if not DoesEntityExist(vehicle) then return end

    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetEntityAsMissionEntity(vehicle, true, false)
    SetVehicleIsStolen(vehicle, false)
    SetVehicleIsWanted(vehicle, false)
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
    SetVehicleFuelLevel(vehicle, 100.0)
    Entity(vehicle).state:set('fuel', 100.0, true)
    SetVehicleUndriveable(vehicle, false)
    SetVehicleEngineOn(vehicle, true, true, true)
    SetPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetVehicleOnGroundProperly(vehicle)
    SetVehicleRadioEnabled(vehicle, true)
    SetVehRadioStation(vehicle, 'OFF')
end

function disableRaceVehiclePhase()
    local vehicle = phasedVehicle
    if (not vehicle or vehicle == 0 or not DoesEntityExist(vehicle)) and CurrentRaceData.Vehicle then
        vehicle = CurrentRaceData.Vehicle
    end
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    end

    if DoesEntityExist(vehicle) then
        if Config.RaceVehiclePhase then
            SetNetworkVehicleAsGhost(vehicle, false)
            ResetEntityAlpha(vehicle)
        end

        -- O alves-racingapp só protege o veículo durante a corrida.
        -- Ao sair/finalizar, devolve o comportamento normal para o servidor.
        SetEntityInvincible(vehicle, false)
        SetVehicleCanBeVisiblyDamaged(vehicle, true)
        SetVehicleEngineCanDegrade(vehicle, true)
    end

    phasedVehicle = 0
end

function applyRaceVehicleRules(vehicle)
    if not DoesEntityExist(vehicle) then return end
    SetVehicleModKit(vehicle, 0)
    for _, modType in ipairs({ 11, 12, 13, 15, 16 }) do
        local count = GetNumVehicleMods(vehicle, modType)
        if count and count > 0 then
            SetVehicleMod(vehicle, modType, count - 1, false)
        end
    end
    ToggleVehicleMod(vehicle, 18, true)

    SetEntityInvincible(vehicle, true)
    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleEngineCanDegrade(vehicle, false)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
end

RegisterCommand('salvarpreset', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if not DoesEntityExist(vehicle) then
        lib.notify({ type = 'error', description = 'Entre em um carro de corrida para salvar o preset visual.' })
        return
    end
    local modelName = getVehicleModelName(vehicle)
    if not modelName or modelName == '' then
        lib.notify({ type = 'error', description = 'Não consegui identificar o modelo desse veículo.' })
        return
    end
    local ok = lib.callback.await('alves-racingapp:saveVehiclePreset', false, {
        vehicleModel = modelName,
        preset = captureVehicleVisualPreset(vehicle)
    })
    lib.notify({ type = ok and 'success' or 'error', description = ok and ('Preset visual salvo para ' .. modelName) or 'Falha ao salvar preset visual.' })
end, false)

TriggerEvent('chat:addSuggestion', '/salvarpreset', 'Salva o visual do carro atual para respawn/corridas')


local function resolveGroundSpawn(x, y, z)
    local baseZ = tonumber(z) or 0.0
    RequestCollisionAtCoord(x, y, baseZ)

    local deadline = GetGameTimer() + 2500
    local groundFound, groundZ = false, baseZ

    while GetGameTimer() < deadline do
        for _, probeZ in ipairs({ baseZ + 2.0, baseZ + 15.0, baseZ + 40.0, 1000.0 }) do
            groundFound, groundZ = GetGroundZFor_3dCoord(x, y, probeZ, false)
            if groundFound then
                return groundZ + 0.35
            end
        end
        RequestCollisionAtCoord(x, y, baseZ)
        Wait(50)
    end

    return baseZ + 0.35
end

local function settleRaceVehicleOnGround(vehicle, x, y, z, heading)
    if not DoesEntityExist(vehicle) then return end

    RequestCollisionAtCoord(x, y, z)
    SetEntityCoordsNoOffset(vehicle, x, y, z, false, false, false)
    SetEntityHeading(vehicle, heading or 0.0)

    for _ = 1, 20 do
        RequestCollisionAtCoord(x, y, z)
        SetVehicleOnGroundProperly(vehicle)
        if HasCollisionLoadedAroundEntity(vehicle) then
            local coords = GetEntityCoords(vehicle)
            local found, groundZ = GetGroundZFor_3dCoord(coords.x, coords.y, coords.z + 2.0, false)
            if found and math.abs(coords.z - groundZ) < 1.5 then
                return
            end
        end
        Wait(50)
    end

    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 10.0, false)
    if found then
        SetEntityCoordsNoOffset(vehicle, x, y, groundZ + 0.35, false, false, false)
        SetVehicleOnGroundProperly(vehicle)
    end
end

function startRaceSession(result)
    if not result then
        lib.notify({ type = 'error', description = 'Erro ao iniciar corrida' })
        return
    end

    local raceType = result.raceType or 'casual'
    local ped = PlayerPedId()
    local currentVehicle = GetVehiclePedIsIn(ped, false)
    if DoesEntityExist(currentVehicle) then
        DeleteEntity(currentVehicle)
    end

    DoScreenFadeOut(500)
    while not IsScreenFadedOut() do Wait(0) end

    local startCoords = result.startCoords
    local spawnIndex = result.spawnIndex or 1
    local heading = startCoords.h or 0.0
    if (not startCoords.h) and result.checkpoints and result.checkpoints[2] then
        local nextCoords = result.checkpoints[2].coords
        heading = GetHeadingFromVector_2d(nextCoords.x - startCoords.x, nextCoords.y - startCoords.y)
    end

    -- Pequeno grid lateral para evitar jogadores nascendo um dentro do outro.
    local gridOffset = (spawnIndex - 1) * 4.2
    local lateralRad = math.rad(heading + 90.0)
    local spawnX = startCoords.x + math.sin(lateralRad) * gridOffset
    local spawnY = startCoords.y + math.cos(lateralRad) * gridOffset
    local spawnZ = resolveGroundSpawn(spawnX, spawnY, startCoords.z)

    SetEntityCoords(ped, spawnX, spawnY, spawnZ + 0.5, false, false, false, false)
    SetEntityHeading(ped, heading)

    local requestedModel = result.vehicleModel or 'sultanrs'
    local model = GetHashKey(requestedModel)
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        print(('[Alves Racing] Veículo inválido no lobby: %s. Usando fallback sultanrs.'):format(tostring(requestedModel)))
        requestedModel = 'sultanrs'
        model = GetHashKey(requestedModel)
    end

    RequestModel(model)
    local modelTimeout = GetGameTimer() + 8000
    while not HasModelLoaded(model) and GetGameTimer() < modelTimeout do Wait(10) end

    if not HasModelLoaded(model) then
        DoScreenFadeIn(500)
        lib.notify({ type = 'error', description = ('Não consegui carregar o veículo %s'):format(tostring(requestedModel)) })
        inRace = false
        return
    end

    local veh = CreateVehicle(model, spawnX, spawnY, spawnZ, heading, true, false)
    settleRaceVehicleOnGround(veh, spawnX, spawnY, spawnZ, heading)
    SetPedIntoVehicle(ped, veh, -1)
    SetVehicleEngineOn(veh, true, true, false)
    SetModelAsNoLongerNeeded(model)

    applyRaceVehicleRules(veh)
    applySavedVisualPreset(veh, requestedModel)
    if Config.RaceVehiclePhase then
        phasedVehicle = veh
        SetNetworkVehicleAsGhost(veh, true)
    end

    -- CONGELAR VEÍCULO durante contagem
    FreezeEntityPosition(veh, true)
    SetVehicleBrake(veh, true)
    SetEntityInvincible(veh, true)

    DoScreenFadeIn(500)

    CurrentRaceData = {
        RaceId = result.raceId,
        RaceName = result.trackName,
        RaceType = raceType,
        RaceClass = result.raceClass,
        Checkpoints = result.checkpoints,
        TotalLaps = result.laps,
        CurrentCheckpoint = 1,
        Lap = 1,
        Started = false,
        RaceTime = 0,
        TotalTime = 0,
        BestLap = 0,
        TotalRacers = result.totalRacers or Config.DefaultTotalRacers,
        VehicleModel = requestedModel,
        Vehicle = veh
    }

    inRace = true

    local typeText = raceType == 'ranked' and 'RANKED' or 'CASUAL'
    lib.notify({ type = 'success', description = string.format('Pista: %s (%s) | Carro: %s', result.trackName, typeText, requestedModel) })

    setupBlipsForRace()

    SendNUIMessage({ action = 'hideLobby' })
    SendNUIMessage({
        action = 'updateRaceHUD',
        data = {
            position = 1,
            totalRacers = result.totalRacers or Config.DefaultTotalRacers,
            lap = CurrentRaceData.Lap,
            totalLaps = CurrentRaceData.TotalLaps,
            checkpoint = CurrentRaceData.CurrentCheckpoint,
            totalCheckpoints = #CurrentRaceData.Checkpoints,
            bestLap = 0
        }
    })

    Wait(1000)
    SendNUIMessage({ action = 'startCountdown', seconds = 5 })

    Wait(5000)

    FreezeEntityPosition(veh, false)
    SetVehicleBrake(veh, false)

    CurrentRaceData.Started = true
    startTime = GetGameTimer()
    lapStartTime = GetGameTimer()

    initRacingHudThread()
    markWithDrawTextWaypoint()
end

RegisterNetEvent('alves-racingapp:client:updateLobby', function(data)
    inLobby = true
    SendNUIMessage({ action = 'showLobby', data = data })
end)

RegisterNetEvent('alves-racingapp:client:startLobbyRace', function(result)
    inLobby = false
    lobbyOpen = false
    SetNuiFocus(false, false)
    CreateThread(function()
        startRaceSession(result)
    end)
end)

RegisterNetEvent('alves-racingapp:client:globalLobbyAlert', function(data)
    data = data or {}
    if inRace or inLobby then return end
    if tonumber(data.source) == GetPlayerServerId(PlayerId()) then return end

    local typeText = data.raceType == 'ranked' and 'ranqueada' or 'casual'
    local racerName = data.racerName or 'Um piloto'
    lib.notify({
        type = 'inform',
        description = string.format('%s abriu um lobby de corrida %s. Aperte F1 para entrar.', racerName, typeText)
    })
    SendNUIMessage({ action = 'playSound', sound = 'lobby' })
    SendNUIMessage({ action = 'showGlobalLobbyAlert', data = data })
end)

RegisterNetEvent('alves-racingapp:client:updateRaceGaps', function(data)
    if not inRace or not CurrentRaceData.RaceId or data.raceId ~= CurrentRaceData.RaceId then return end
    SendNUIMessage({ action = 'updateRaceGaps', data = data })
end)

-- ==================== NUI CALLBACKS ====================
RegisterNUICallback('closeTablet', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('leaveLobby', function(_, cb)
    cb('ok')
    inLobby = false
    lobbyOpen = false
    SetNuiFocus(false, false)
    TriggerServerEvent('alves-racingapp:server:leaveRace')
    lib.notify({ type = 'inform', description = 'Você saiu do lobby' })
end)

RegisterNUICallback('minimizeLobby', function(_, cb)
    cb('ok')
    if inLobby then
        lobbyOpen = false
        SetNuiFocus(false, false)
    end
end)

RegisterNUICallback('maximizeLobby', function(_, cb)
    cb('ok')
    if inLobby then
        lobbyOpen = true
        SetNuiFocus(true, true)
    end
end)

RegisterNUICallback('startRace', function(data, cb)
    cb('ok')
    
    local raceType = data.raceType or 'ranked'
    
    if inRace then
        lib.notify({ type = 'error', description = 'Você já está em uma corrida' })
        return
    end
    
    lib.notify({ type = 'inform', description = 'Entrando no lobby...' })
    
    CreateThread(function()
        local lobby = lib.callback.await('alves-racingapp:server:startQuickRace', false, raceType)
        
        if not lobby then
            lib.notify({ type = 'error', description = 'Erro ao entrar no lobby' })
            return
        end
        inLobby = true
        lobbyOpen = true
        SetNuiFocus(true, true)
        SendNUIMessage({ action = 'showLobby', data = lobby })
    end)
end)

RegisterNUICallback('lobbyVote', function(data, cb)
    cb('ok')
    CreateThread(function()
        local lobby = lib.callback.await('alves-racingapp:server:voteLobby', false, data or {})
        if lobby then
            SendNUIMessage({ action = 'showLobby', data = lobby })
        end
    end)
end)


RegisterNUICallback('showGarage', function(_, cb)
    cb('ok')

    CreateThread(function()
        local vehicles = getRaceVehicleModels()
        SendNUIMessage({ action = 'showGarage', data = { vehicles = vehicles } })
    end)
end)

RegisterNUICallback('spawnGarageVehicle', function(data, cb)
    cb('ok')

    CreateThread(function()
        local modelName = data and data.modelName and tostring(data.modelName):lower() or nil
        if not modelName or modelName == '' then
            SendNUIMessage({ action = 'garageSpawnFail', data = { name = 'Veículo', message = 'Modelo inválido.' } })
            return
        end

        local veh, errorMessage = spawnLocalGarageVehicle(modelName)
        if not veh then
            SendNUIMessage({ action = 'garageSpawnFail', data = { name = modelName, message = errorMessage or 'Falha ao spawnar veículo.' } })
            return
        end

        applySavedVisualPreset(veh, modelName)
        prepareGarageVehicle(veh)

        local netId = VehToNet(veh)
        lib.callback.await('alves-racingapp:server:giveGarageVehicleKeys', false, netId)

        SendNUIMessage({ action = 'garageSpawnOk', data = { name = modelName } })
    end)
end)

RegisterNUICallback('saveGaragePreset', function(_, cb)
    cb('ok')

    CreateThread(function()
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if not DoesEntityExist(vehicle) then
            SendNUIMessage({ action = 'garagePresetFail', data = { message = 'Entre em um carro para salvar o visual.' } })
            return
        end

        local modelName = getVehicleModelName(vehicle)
        if not modelName or modelName == '' then
            SendNUIMessage({ action = 'garagePresetFail', data = { message = 'Modelo do veículo não identificado.' } })
            return
        end

        local ok = lib.callback.await('alves-racingapp:saveVehiclePreset', false, {
            vehicleModel = modelName,
            preset = captureVehicleVisualPreset(vehicle)
        })

        SendNUIMessage({ action = ok and 'garagePresetOk' or 'garagePresetFail', data = { name = modelName } })
    end)
end)

RegisterNUICallback('showScoreboard', function(data, cb)
    cb('ok')
    
    CreateThread(function()
        local trackName = data and data.trackName or nil
        local scoreboard = nil
        local title = 'MINHAS CORRIDAS'

        if trackName and trackName ~= '' then
            scoreboard = lib.callback.await('alves-racingapp:getScoreboard', false, trackName)
            title = ('SCOREBOARD - %s'):format(trackName)
        else
            scoreboard = lib.callback.await('alves-racingapp:getMyRaceHistory', false)
        end
        
        SendNUIMessage({
            action = 'showScoreboard',
            data = {
                title = title,
                trackName = trackName,
                times = scoreboard
            }
        })
    end)
end)

RegisterNUICallback('showRanking', function(_, cb)
    cb('ok')
    
    CreateThread(function()
        local ranking = lib.callback.await('alves-racingapp:getGlobalRanking', false)
        
        SendNUIMessage({
            action = 'showRanking',
            data = { ranking = ranking }
        })
    end)
end)

RegisterNUICallback('showProfile', function(_, cb)
    cb('ok')
    
    CreateThread(function()
        local profile = lib.callback.await('alves-racingapp:getMyProfile', false)
        
        if not profile then
            lib.notify({ type = 'error', description = 'Perfil não encontrado' })
            return
        end
        
        SendNUIMessage({
            action = 'showProfile',
            data = profile
        })
    end)
end)

RegisterNUICallback('saveSettings', function(data, cb)
    cb('ok')

    CreateThread(function()
        local result = lib.callback.await('alves-racingapp:updateRacerName', false, data and data.racerName or '')
        if result and result.ok then
            lib.notify({ type = 'success', description = 'Nome de corredor atualizado.' })
            local playerInfo = awaitServerCallback('alves-racingapp:getPlayerInfo')
            if playerInfo then
                SendNUIMessage({ action = 'openTablet', data = { player = playerInfo, onlineCount = awaitServerCallback('alves-racingapp:getOnlineCount') or 0, theme = Config.Theme } })
            end
            SendNUIMessage({ action = 'settingsSaved', data = { racerName = result.racername } })
        else
            lib.notify({ type = 'error', description = (result and result.message) or 'Não consegui salvar as configurações.' })
            SendNUIMessage({ action = 'settingsSaveFailed', data = { message = (result and result.message) or 'Falha ao salvar.' } })
        end
    end)
end)

-- ==================== RACING THREADS ====================
function markWithDrawTextWaypoint()
    CreateThread(function()
        while inRace and CurrentRaceData.Started do
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            
            local checkpoints = getUpcomingCheckpoints()
            
            for i, checkpoint in ipairs(checkpoints) do
                local distance = #(playerCoords - checkpoint.coord)
                local height = math.min(Config.DrawTextSetup.maxHeight, math.max(Config.DrawTextSetup.minHeight, distance / 2.5))
                
                DrawRacingMarker(checkpoint.coord, height)
                
                local baseTextHeight = checkpoint.coord.z + height
                local labelHeight = baseTextHeight + 0.7 + height * 0.05
                local distanceHeight = baseTextHeight + 0.5
                
                local color = i == 1 and Config.DrawTextSetup.primaryColor or Config.DrawTextSetup.distanceColor
                
                local labelCoords = vector3(checkpoint.coord.x, checkpoint.coord.y, labelHeight)
                Draw3DText(labelCoords, checkpoint.label, 0.25, color)
                
                local distanceCoords = vector3(checkpoint.coord.x, checkpoint.coord.y, distanceHeight)
                Draw3DText(distanceCoords, string.format("%.0fm", distance), 0.5, Config.DrawTextSetup.distanceColor)
            end
            
            Wait(0)
        end
    end)
end

function initRacingHudThread()
    CreateThread(function()
        while inRace and CurrentRaceData.RaceName ~= nil do
            if CurrentRaceData.Started then
                CurrentRaceData.RaceTime = GetTimeDifference(GetGameTimer(), lapStartTime)
                CurrentRaceData.TotalTime = GetTimeDifference(GetGameTimer(), startTime)
                local now = GetGameTimer()
                if now - lastProgressSync >= 500 then
                    lastProgressSync = now
                    TriggerServerEvent('alves-racingapp:server:updateRaceProgress', {
                        raceId = CurrentRaceData.RaceId,
                        lap = CurrentRaceData.Lap,
                        checkpoint = CurrentRaceData.CurrentCheckpoint,
                        totalCheckpoints = #CurrentRaceData.Checkpoints,
                        elapsed = CurrentRaceData.TotalTime
                    })
                end
                
                SendNUIMessage({
                    action = 'updateRaceHUD',
                    data = {
                        position = 1,
                        totalRacers = CurrentRaceData.TotalRacers or Config.DefaultTotalRacers,
                        lap = CurrentRaceData.Lap,
                        totalLaps = CurrentRaceData.TotalLaps,
                        checkpoint = CurrentRaceData.CurrentCheckpoint,
                        totalCheckpoints = #CurrentRaceData.Checkpoints,
                        bestLap = CurrentRaceData.BestLap or 0
                    }
                })
                
                local ped = PlayerPedId()
                local pos = GetEntityCoords(ped)
                local checkpointId
                
                if CurrentRaceData.CurrentCheckpoint + 1 > #CurrentRaceData.Checkpoints then
                    checkpointId = 1
                else
                    checkpointId = CurrentRaceData.CurrentCheckpoint + 1
                end
                
                local data = CurrentRaceData.Checkpoints[checkpointId]
                local currentCheckpointCenterCoords = vector3(data.coords.x, data.coords.y, data.coords.z)
                local CheckpointDistance = #(pos - currentCheckpointCenterCoords)
                local MaxDistance = getMaxDistance(currentCheckpointCenterCoords, data.offset)
                
                if CheckpointDistance < MaxDistance then
                    if CurrentRaceData.TotalLaps == 0 then
                        if CurrentRaceData.CurrentCheckpoint + 1 < #CurrentRaceData.Checkpoints then
                            CurrentRaceData.CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint + 1
                            updateGpsForRace()
                            refreshCheckpointMarkers()
                            lib.notify({ type = 'success', description = 'Checkpoint!' })
                        else
                            lib.notify({ type = 'success', description = '🏁 Corrida finalizada!' })
                            finishRace()
                        end
                    else
                        if CurrentRaceData.CurrentCheckpoint + 1 > #CurrentRaceData.Checkpoints then
                            if CurrentRaceData.Lap + 1 > CurrentRaceData.TotalLaps then
                                lib.notify({ type = 'success', description = '🏁 Corrida finalizada!' })
                                finishRace()
                            else
                                if CurrentRaceData.BestLap == 0 or CurrentRaceData.RaceTime < CurrentRaceData.BestLap then
                                    CurrentRaceData.BestLap = CurrentRaceData.RaceTime
                                end
                                
                                lapStartTime = GetGameTimer()
                                CurrentRaceData.Lap = CurrentRaceData.Lap + 1
                                CurrentRaceData.CurrentCheckpoint = 1
                                
                                lib.notify({ type = 'inform', description = string.format('Volta %d/%d', CurrentRaceData.Lap, CurrentRaceData.TotalLaps) })
                                
                                updateGpsForRace()
                                refreshCheckpointMarkers()
                            end
                        else
                            CurrentRaceData.CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint + 1
                            updateGpsForRace()
                            refreshCheckpointMarkers()
                        end
                    end
                end
            end
            
            Wait(0)
        end
        print('[Alves Racing] Racing HUD thread encerrada')
    end)
end

-- ==================== VEHICLE PROTECTION ====================
CreateThread(function()
    while true do
        if Config.RaceVehiclePhase and inRace then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)

            if DoesEntityExist(veh) then
                if phasedVehicle ~= veh then
                    if phasedVehicle ~= 0 and DoesEntityExist(phasedVehicle) then
                        SetNetworkVehicleAsGhost(phasedVehicle, false)
                        ResetEntityAlpha(phasedVehicle)
                    end

                    phasedVehicle = veh
                    SetNetworkVehicleAsGhost(veh, true)
                else
                    -- Mantém o ghost ativo caso outro recurso/native tente restaurar o estado.
                    SetNetworkVehicleAsGhost(veh, true)
                end

                for _, player in ipairs(GetActivePlayers()) do
                    if player ~= PlayerId() then
                        local otherPed = GetPlayerPed(player)
                        local otherVeh = GetVehiclePedIsIn(otherPed, false)

                        if DoesEntityExist(otherVeh) and otherVeh ~= veh then
                            SetEntityNoCollisionEntity(veh, otherVeh, true)
                            SetEntityNoCollisionEntity(otherVeh, veh, true)
                        end
                    end
                end
            end

            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(1000)
        
        if inRace then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            
            if DoesEntityExist(veh) then
                applyRaceVehicleRules(veh)
            end
        end
    end
end)
