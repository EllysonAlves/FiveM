-- Alves Racing - Client
-- Sistema de corridas baseado em cw-racingapp

print('^2[Alves Racing]^0 Client iniciado!')

local inRace = false
local CurrentRaceData = {}
local checkpointBlips = {}
local startTime = 0
local lapStartTime = 0

-- ==================== CONFIGURAÇÃO ====================
-- Config vem de config.lua (shared_script). Mantemos fallback para compatibilidade.
Config = Config or {}
Config.CheckpointBuffer = Config.CheckpointBuffer or 5.0
Config.MarkAmountOfCheckpointsAhead = Config.CheckpointsAhead or Config.MarkAmountOfCheckpointsAhead or 8
Config.ShowGpsRoute = Config.ShowGpsRoute ~= false
Config.UseRoadsForGps = Config.UseRoadsForGps ~= false
Config.GpsColor = Config.GpsColor or 83
Config.BlipColor = Config.BlipColor or 85
Config.DefaultTotalRacers = Config.DefaultTotalRacers or 1
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
    openTablet()
end, false)

RegisterKeyMapping('race', 'Abrir Menu de Corridas', 'keyboard', 'F1')
print('^2[Alves Racing]^0 F1 registrado para abrir menu')

RegisterCommand('sair', function()
    if not inRace then
        lib.notify({ type = 'error', description = 'Você não está em uma corrida' })
        return
    end
    
    leaveRace()
end, false)

-- ==================== FUNÇÕES AUXILIARES ====================
function openTablet()
    local playerInfo = lib.callback.await('alves-racingapp:getPlayerInfo', false)
    local onlineCount = lib.callback.await('alves-racingapp:getOnlineCount', false)
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openTablet',
        data = {
            player = playerInfo,
            onlineCount = onlineCount or 0
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
        vehicleName = GetDisplayNameFromVehicleModel(GetEntityModel(veh))
    end
    
    print(string.format('[Alves Racing Client] Finalizando corrida: %s - Tempo: %dms', raceName, finalTime))
    
    -- Salvar tempo no banco
    TriggerServerEvent('alves-racingapp:server:finishRace', {
        raceId = raceId,
        raceName = raceName,
        totalTime = finalTime,
        laps = CurrentRaceData.TotalLaps,
        vehicle = vehicleName,
        raceType = raceType
    })
    
    Wait(500)
    leaveRace()
end

function leaveRace()
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
    for k, v in pairs(CurrentRaceData.Checkpoints) do
        checkpointBlips[k] = CreateCheckpointBlip(v.coords, k)
    end
    
    if checkpointBlips[CurrentRaceData.CurrentCheckpoint + 1] then
        nextBlip(checkpointBlips[CurrentRaceData.CurrentCheckpoint + 1])
    end
    
    updateGpsForRace()
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
        SetBlipColour(blip, Config.GpsColor or 5)
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

function applyFullTuning(vehicle)
    if not DoesEntityExist(vehicle) then return end
    
    SetVehicleMod(vehicle, 11, GetNumVehicleMods(vehicle, 11) - 1, false)
    SetVehicleMod(vehicle, 12, GetNumVehicleMods(vehicle, 12) - 1, false)
    SetVehicleMod(vehicle, 13, GetNumVehicleMods(vehicle, 13) - 1, false)
    SetVehicleMod(vehicle, 15, GetNumVehicleMods(vehicle, 15) - 1, false)
    SetVehicleMod(vehicle, 16, GetNumVehicleMods(vehicle, 16) - 1, false)
    
    ToggleVehicleMod(vehicle, 18, true)
    
    SetVehicleEnginePowerMultiplier(vehicle, 50.0)
    SetVehicleEngineTorqueMultiplier(vehicle, 50.0)
    
    SetEntityInvincible(vehicle, true)
    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleBodyHealth(vehicle, 1000.0)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
end

-- ==================== NUI CALLBACKS ====================
RegisterNUICallback('closeTablet', function(_, cb)
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('startRace', function(data, cb)
    cb('ok')
    
    local raceType = data.raceType or 'ranked'
    
    if inRace then
        lib.notify({ type = 'error', description = 'Você já está em uma corrida' })
        return
    end
    
    lib.notify({ type = 'inform', description = 'Preparando corrida...' })
    
    CreateThread(function()
        local result = lib.callback.await('alves-racingapp:server:startQuickRace', false, raceType)
        
        if not result then
            lib.notify({ type = 'error', description = 'Erro ao iniciar corrida' })
            return
        end
        
        local ped = PlayerPedId()
        local currentVehicle = GetVehiclePedIsIn(ped, false)
        if DoesEntityExist(currentVehicle) then
            DeleteEntity(currentVehicle)
        end
        
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        
        SetEntityCoords(ped, result.startCoords.x, result.startCoords.y, result.startCoords.z + 1.0, false, false, false, false)
        SetEntityHeading(ped, result.startCoords.h or 0.0)
        
        local model = GetHashKey(result.vehicleModel)
        RequestModel(model)
        while not HasModelLoaded(model) do Wait(10) end
        
        local veh = CreateVehicle(model, result.startCoords.x, result.startCoords.y, result.startCoords.z + 0.5, result.startCoords.h or 0.0, true, false)
        SetVehicleOnGroundProperly(veh)
        SetPedIntoVehicle(ped, veh, -1)
        SetVehicleEngineOn(veh, true, true, false)
        SetModelAsNoLongerNeeded(model)
        
        applyFullTuning(veh)
        
        -- CONGELAR VEÍCULO durante contagem
        FreezeEntityPosition(veh, true)
        SetVehicleBrake(veh, true)
        SetEntityInvincible(veh, true)
        
        DoScreenFadeIn(500)
        
        CurrentRaceData = {
            RaceId = result.raceId,
            RaceName = result.trackName,
            RaceType = raceType,
            Checkpoints = result.checkpoints,
            TotalLaps = result.laps,
            CurrentCheckpoint = 1,
            Lap = 1,
            Started = false,
            RaceTime = 0,
            TotalTime = 0,
            BestLap = 0,
            TotalRacers = result.totalRacers or Config.DefaultTotalRacers,
            Vehicle = veh
        }
        
        inRace = true
        
        local typeText = raceType == 'ranked' and 'RANKED' or 'CASUAL'
        lib.notify({ type = 'success', description = string.format('Pista: %s (%s)', result.trackName, typeText) })
        
        setupBlipsForRace()
        
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
        SendNUIMessage({
            action = 'startCountdown',
            seconds = 5
        })
        
        Wait(5000)
        
        -- DESCONGELAR VEÍCULO após contagem
        FreezeEntityPosition(veh, false)
        SetVehicleBrake(veh, false)
        
        CurrentRaceData.Started = true
        startTime = GetGameTimer()
        lapStartTime = GetGameTimer()
        
        initRacingHudThread()
        markWithDrawTextWaypoint()
    end)
end)

RegisterNUICallback('showScoreboard', function(data, cb)
    cb('ok')
    
    CreateThread(function()
        local trackName = data.trackName or (CurrentRaceData.RaceName or nil)
        
        if not trackName then
            lib.notify({ type = 'error', description = 'Nenhuma pista selecionada' })
            return
        end
        
        local scoreboard = lib.callback.await('alves-racingapp:getScoreboard', false, trackName)
        
        SendNUIMessage({
            action = 'showScoreboard',
            data = {
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
                            passedBlip(checkpointBlips[CurrentRaceData.CurrentCheckpoint])
                            nextBlip(checkpointBlips[CurrentRaceData.CurrentCheckpoint + 1])
                            updateGpsForRace()
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
                                
                                passedBlip(checkpointBlips[1])
                                nextBlip(checkpointBlips[2])
                                updateGpsForRace()
                            end
                        else
                            CurrentRaceData.CurrentCheckpoint = CurrentRaceData.CurrentCheckpoint + 1
                            passedBlip(checkpointBlips[CurrentRaceData.CurrentCheckpoint])
                            
                            if CurrentRaceData.CurrentCheckpoint ~= #CurrentRaceData.Checkpoints then
                                nextBlip(checkpointBlips[CurrentRaceData.CurrentCheckpoint + 1])
                            else
                                nextBlip(checkpointBlips[1])
                            end
                            updateGpsForRace()
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
        Wait(1000)
        
        if inRace then
            local ped = PlayerPedId()
            local veh = GetVehiclePedIsIn(ped, false)
            
            if DoesEntityExist(veh) then
                applyFullTuning(veh)
            end
        end
    end
end)
