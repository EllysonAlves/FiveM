local spawnBlip = nil

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

    if Config.DisableFuelDrain then
        SetVehicleFuelLevel(vehicle, 100.0)
    end

    SetVehicleCanBeVisiblyDamaged(vehicle, false)
    SetVehicleEngineCanDegrade(vehicle, false)
    SetVehicleEngineHealth(vehicle, 1000.0)
    SetVehiclePetrolTankHealth(vehicle, 1000.0)
end

CreateThread(function()
    createSpawnBlip()
    disableDispatch()

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
