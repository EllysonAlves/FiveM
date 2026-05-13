local spawnBlip = nil
local pilotPedApplied = false

local function applyPilotPed()
    if not Config.ForcePilotPed or pilotPedApplied then return end

    local modelName = Config.PilotPedModel or 's_m_y_xmech_01'
    local model = joaat(modelName)
    if not IsModelInCdimage(model) or not IsModelValid(model) then
        print(('[Alves Racing Core] Ped inválido: %s'):format(modelName))
        pilotPedApplied = true
        return
    end

    RequestModel(model)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(model) and GetGameTimer() < timeout do Wait(50) end
    if not HasModelLoaded(model) then
        print(('[Alves Racing Core] Timeout carregando ped: %s'):format(modelName))
        pilotPedApplied = true
        return
    end

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    pilotPedApplied = true
end

local function createSpawnBlip()
    if not Config.SpawnBlip or not Config.SpawnBlip.enabled or spawnBlip then return end

    local coords = Config.SpawnBlip.coords
    spawnBlip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(spawnBlip, Config.SpawnBlip.sprite or 38)
    SetBlipColour(spawnBlip, Config.SpawnBlip.color or 27)
    SetBlipScale(spawnBlip, Config.SpawnBlip.scale or 0.9)
    SetBlipAsShortRange(spawnBlip, Config.SpawnBlip.shortRange ~= false)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(Config.SpawnBlip.label or 'Alves Racing')
    EndTextCommandSetBlipName(spawnBlip)
end

local function disableDispatch()
    for service = 1, 15 do
        EnableDispatchService(service, false)
    end
    SetCreateRandomCops(false)
    SetCreateRandomCopsNotOnScenarios(false)
    SetCreateRandomCopsOnScenarios(false)
end

local function applyPlayerRaceRules(ped)
    if not DoesEntityExist(ped) then return end

    if Config.ImmortalPlayers then
        SetEntityInvincible(ped, true)
        SetPlayerInvincible(PlayerId(), true)
        SetPedCanRagdoll(ped, false)
        SetEntityProofs(ped, true, true, true, true, true, true, true, true)
        SetEntityHealth(ped, GetEntityMaxHealth(ped))
        SetPedArmour(ped, 0)
    end

    if Config.NoVehicleEjection then
        SetPedCanBeKnockedOffVehicle(ped, 1)
        SetPedConfigFlag(ped, 32, false)
        SetPedConfigFlag(ped, 429, true)
    end
end

local function applyVehicleRaceRules(vehicle)
    if not DoesEntityExist(vehicle) then return end

    if Config.MaxVehiclePerformance then
        SetVehicleModKit(vehicle, 0)
        for _, modType in ipairs({ 11, 12, 13, 15, 16 }) do
            local count = GetNumVehicleMods(vehicle, modType)
            if count and count > 0 then
                SetVehicleMod(vehicle, modType, count - 1, false)
            end
        end
        ToggleVehicleMod(vehicle, 18, true) -- turbo
    end

    if Config.DisableFuelDrain then
        SetVehicleFuelLevel(vehicle, 100.0)
    end

    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleEngineCanDegrade(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
end

local function openVisualTuning()
    local ped = PlayerPedId()
    if not IsPedInAnyVehicle(ped, false) then
        lib.notify({ type = 'error', description = 'Entre em um carro para abrir o tuning visual.' })
        return
    end

    if GetResourceState('qbx_customs') ~= 'started' then
        lib.notify({ type = 'error', description = 'qbx_customs não está iniciado.' })
        return
    end

    exports.qbx_customs:OpenMenu()
end

RegisterCommand('tuning', openVisualTuning, false)
RegisterCommand('bennys', openVisualTuning, false)
TriggerEvent('chat:addSuggestion', '/tuning', 'Abre o tuning visual do carro atual')
TriggerEvent('chat:addSuggestion', '/bennys', 'Abre o tuning visual do carro atual')

CreateThread(function()
    createSpawnBlip()
    disableDispatch()
    applyPilotPed()

    while true do
        local ped = PlayerPedId()

        if Config.DisablePopulation then
            SetVehicleDensityMultiplierThisFrame(0.0)
            SetRandomVehicleDensityMultiplierThisFrame(0.0)
            SetParkedVehicleDensityMultiplierThisFrame(0.0)
            SetPedDensityMultiplierThisFrame(0.0)
            SetScenarioPedDensityMultiplierThisFrame(0.0, 0.0)
            SetGarbageTrucks(false)
            SetRandomBoats(false)
            SetRandomTrains(false)
        end

        if Config.HideGtaHud then
            HideHudComponentThisFrame(1)
            HideHudComponentThisFrame(2)
            HideHudComponentThisFrame(3)
            HideHudComponentThisFrame(4)
            HideHudComponentThisFrame(6)
            HideHudComponentThisFrame(7)
            HideHudComponentThisFrame(8)
            HideHudComponentThisFrame(9)
            HideHudComponentThisFrame(13)
        end

        applyPlayerRaceRules(ped)

        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle and vehicle ~= 0 then
            applyVehicleRaceRules(vehicle)
        end

        Wait(0)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if spawnBlip and DoesBlipExist(spawnBlip) then
        RemoveBlip(spawnBlip)
        spawnBlip = nil
    end
end)
