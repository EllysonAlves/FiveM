local nitroConfig = Config.Nitro or {}
local nitroMode = nitroConfig.defaultMode or 'balanced'
local nitroLevel = 100.0
local nitroActive = false
local nitroKeyHeld = false
local nitroLastUsed = 0
local nitroSoundActive = false
local nitroFlameEffects = {}

local tireTemp = 30.0
local tireWear = 0.0
local tireGrip = 0.86
local brakeTemp = 30.0
local brakeFactor = 0.78
local tireHandlingVehicle = 0
local tireBaseHandling = nil
local lastTireSpeedKmh = 0.0
local tireKeys = { 'lf', 'rf', 'lr', 'rr' }
local tireLabels = { lf = 'DE', rf = 'DD', lr = 'TE', rr = 'TD' }
local tireWheelIndex = { lf = 0, rf = 1, lr = 2, rr = 3 }
local tireTelemetry = {
    lf = { label = 'DE', temp = 30.0, wear = 0.0, grip = 0.86 },
    rf = { label = 'DD', temp = 30.0, wear = 0.0, grip = 0.86 },
    lr = { label = 'TE', temp = 30.0, wear = 0.0, grip = 0.86 },
    rr = { label = 'TD', temp = 30.0, wear = 0.0, grip = 0.86 },
}

local nitroExhaustBones = {
    'exhaust', 'exhaust_2', 'exhaust_3', 'exhaust_4',
    'exhaust_5', 'exhaust_6', 'exhaust_7', 'exhaust_8',
}

local function getNitroModeConfig(mode)
    return (nitroConfig.modes and nitroConfig.modes[mode]) or (nitroConfig.modes and nitroConfig.modes.balanced) or {
        label = 'BALANCEADO', drainPerSecond = 25.0, torqueMultiplier = 1.45, powerMultiplier = 1.65
    }
end

local function nextNitroMode(mode)
    local order = nitroConfig.order or { 'power', 'eco', 'balanced' }
    for index, modeName in ipairs(order) do
        if modeName == mode then return order[index + 1] or order[1] end
    end
    return nitroConfig.defaultMode or 'balanced'
end

local function notify(message, notifyType)
    if lib and lib.notify then lib.notify({ type = notifyType or 'inform', description = message }) end
end

local function canUseNitro(vehicle)
    return Config.EnableNitroSystem and vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) and GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() and not IsThisModelABicycle(GetEntityModel(vehicle))
end

local function stopNitroFlames(vehicle)
    local effects = nitroFlameEffects[vehicle]
    if not effects then return end

    for _, effect in ipairs(effects) do
        StopParticleFxLooped(effect.handle, false)
    end
    nitroFlameEffects[vehicle] = nil
end

local function stopAllNitroFlames()
    for vehicle in pairs(nitroFlameEffects) do stopNitroFlames(vehicle) end
end

local function startNitroFlames(vehicle, mode)
    if nitroFlameEffects[vehicle] then return end
    if not DoesEntityExist(vehicle) then return end

    local modeConfig = getNitroModeConfig(mode)
    local effectAsset = 'veh_xs_vehicle_mods'
    local effectName = 'veh_nitrous'
    RequestNamedPtfxAsset(effectAsset)
    local timeout = GetGameTimer() + 1200
    while not HasNamedPtfxAssetLoaded(effectAsset) and GetGameTimer() < timeout do Wait(0) end
    if not HasNamedPtfxAssetLoaded(effectAsset) then return end

    local effects = { mode = mode }
    for _, boneName in ipairs(nitroExhaustBones) do
        local boneIndex = GetEntityBoneIndexByName(vehicle, boneName)
        if boneIndex ~= -1 then
            UseParticleFxAssetNextCall(effectAsset)
            local handle = StartParticleFxLoopedOnEntityBone(effectName, vehicle, 0.0, -0.04, 0.0, 0.0, 0.0, 0.0, boneIndex, 1.0, false, false, false)
            if handle then
                if modeConfig.color then
                    SetParticleFxLoopedColour(handle, modeConfig.color.r or 0.05, modeConfig.color.g or 0.45, modeConfig.color.b or 1.0, false)
                end
                table.insert(effects, { handle = handle })
            end
        end
    end

    if #effects > 0 then nitroFlameEffects[vehicle] = effects end
end

local function setNitroSound(active, mode)
    if nitroSoundActive == active and active then return end
    nitroSoundActive = active
    SendNUIMessage({ action = 'nitroSound', active = active, mode = mode or nitroMode })
end

local function setNitroActive(vehicle, active, mode)
    nitroActive = active == true
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then return end

    SetVehicleBoostActive(vehicle, false)
    if nitroActive then
        startNitroFlames(vehicle, mode or nitroMode)
        Entity(vehicle).state:set('nitroFlames', { active = true, mode = mode or nitroMode }, true)
        setNitroSound(true, mode or nitroMode)
    else
        Entity(vehicle).state:set('nitroFlames', false, true)
        stopNitroFlames(vehicle)
        setNitroSound(false)
    end
end

if Config.EnableNitroSystem then
    lib.addKeybind({
        name = 'alves_core_nitro_mode',
        description = 'Alternar tipo de nitro Alves Racing',
        defaultKey = 'N',
        defaultMapper = 'keyboard',
        onPressed = function()
            nitroMode = nextNitroMode(nitroMode)
            notify(('Nitro: %s'):format(getNitroModeConfig(nitroMode).label or nitroMode), 'inform')
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if nitroActive and vehicle ~= 0 then
                stopNitroFlames(vehicle)
                startNitroFlames(vehicle, nitroMode)
                Entity(vehicle).state:set('nitroFlames', { active = true, mode = nitroMode }, true)
                SendNUIMessage({ action = 'nitroSound', active = true, mode = nitroMode })
            end
        end,
    })

    lib.addKeybind({
        name = 'alves_core_nitro',
        description = 'Usar nitro Alves Racing',
        defaultKey = 'LSHIFT',
        defaultMapper = 'keyboard',
        onPressed = function() nitroKeyHeld = true end,
        onReleased = function()
            nitroKeyHeld = false
            nitroLastUsed = GetGameTimer()
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            if vehicle ~= 0 then setNitroActive(vehicle, false) else nitroActive = false end
            stopAllNitroFlames()
            setNitroSound(false)
        end,
    })

    RegisterCommand('nitrocheio', function()
        nitroLevel = 100.0
        notify('Nitro recarregado.', 'success')
    end, false)

    CreateThread(function()
        local lastTick = GetGameTimer()
        while true do
            Wait(nitroKeyHeld and 0 or 50)
            local now = GetGameTimer()
            local delta = (now - lastTick) / 1000.0
            lastTick = now
            local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
            local usingNitro = canUseNitro(vehicle) and nitroKeyHeld and nitroLevel > (nitroConfig.minToActivate or 6.0)

            if usingNitro then
                local modeConfig = getNitroModeConfig(nitroMode)
                nitroLevel = math.max(0.0, nitroLevel - ((modeConfig.drainPerSecond or 25.0) * delta))
                nitroLastUsed = now
                setNitroActive(vehicle, true, nitroMode)
                SetVehicleCheatPowerIncrease(vehicle, modeConfig.powerMultiplier or 1.65)
                SetVehicleEngineTorqueMultiplier(vehicle, modeConfig.torqueMultiplier or 1.45)
            else
                if nitroActive then setNitroActive(vehicle, false) else stopAllNitroFlames(); setNitroSound(false) end
                if not nitroKeyHeld and (now - nitroLastUsed) >= (nitroConfig.rechargeDelayMs or 1400) then
                    nitroLevel = math.min(100.0, nitroLevel + ((nitroConfig.rechargePerSecond or 10.0) * delta))
                end
            end
        end
    end)

    AddStateBagChangeHandler('nitroFlames', nil, function(bagName, _, value)
        local entity = GetEntityFromStateBagName(bagName)
        if entity == 0 or entity == GetVehiclePedIsIn(PlayerPedId(), false) then return end
        if value and type(value) == 'table' and value.active then
            stopNitroFlames(entity)
            startNitroFlames(entity, value.mode)
        else
            stopNitroFlames(entity)
        end
    end)
end

local function resetTireHandling(vehicle)
    if tireHandlingVehicle ~= 0 and tireBaseHandling and DoesEntityExist(tireHandlingVehicle) then
        SetVehicleHandlingFloat(tireHandlingVehicle, 'CHandlingData', 'fTractionCurveMax', tireBaseHandling.tractionMax)
        SetVehicleHandlingFloat(tireHandlingVehicle, 'CHandlingData', 'fTractionCurveMin', tireBaseHandling.tractionMin)
        SetVehicleHandlingFloat(tireHandlingVehicle, 'CHandlingData', 'fBrakeForce', tireBaseHandling.brakeForce)
    end

    if vehicle and vehicle ~= tireHandlingVehicle then
        tireTemp, tireWear, tireGrip = 30.0, 0.0, 0.86
        brakeTemp, brakeFactor = 30.0, 0.78
        for _, key in ipairs(tireKeys) do tireTelemetry[key] = { label = tireLabels[key], temp = 30.0, wear = 0.0, grip = 0.86 } end
    end
    tireHandlingVehicle, tireBaseHandling = 0, nil
end

local function ensureTireHandlingBase(vehicle)
    if tireHandlingVehicle == vehicle and tireBaseHandling then return end
    resetTireHandling(vehicle)
    tireHandlingVehicle = vehicle
    tireBaseHandling = {
        tractionMax = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax'),
        tractionMin = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin'),
        brakeForce = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce'),
        driveBiasFront = GetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fDriveBiasFront'),
    }
end

local function getTireGripFactor(temp, wear)
    local tempFactor
    if temp < 40.0 then tempFactor = 0.58 + ((temp / 40.0) * 0.16)
    elseif temp < 70.0 then tempFactor = 0.74 + (((temp - 40.0) / 30.0) * 0.26)
    elseif temp <= 95.0 then tempFactor = 1.04
    elseif temp <= 110.0 then tempFactor = 1.04 - (((temp - 95.0) / 15.0) * 0.12)
    elseif temp <= 130.0 then tempFactor = 0.92 - (((temp - 110.0) / 20.0) * 0.24)
    else tempFactor = 0.62 end
    local wearFactor = 1.0 - math.min(0.18, (wear / 100.0) * 0.18)
    return math.max(0.55, math.min(1.04, tempFactor * wearFactor))
end

local function getBrakeFactor(temp)
    if temp < 80.0 then return 0.62 + ((temp / 80.0) * 0.18)
    elseif temp < 180.0 then return 0.80 + (((temp - 80.0) / 100.0) * 0.20)
    elseif temp <= 520.0 then return 1.03
    elseif temp <= 700.0 then return 1.03 - (((temp - 520.0) / 180.0) * 0.23) end
    return 0.68
end

local function getWheelSlipKmh(vehicle, wheelIndex, vehicleSpeedKmh)
    if not GetVehicleWheelSpeed then return 0.0 end
    local ok, wheelSpeed = pcall(GetVehicleWheelSpeed, vehicle, wheelIndex)
    if not ok or not wheelSpeed then return 0.0 end
    return math.max(0.0, math.abs(wheelSpeed) * 3.6 - vehicleSpeedKmh)
end

local function updateThermalSystem(vehicle, delta)
    if not Config.EnableThermalSystem then return end
    local ped = PlayerPedId()
    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) or GetPedInVehicleSeat(vehicle, -1) ~= ped or IsThisModelABicycle(GetEntityModel(vehicle)) then
        resetTireHandling(vehicle)
        lastTireSpeedKmh = 0.0
        SendNUIMessage({ action = 'thermal', show = false })
        return
    end

    ensureTireHandlingBase(vehicle)
    local speed = GetEntitySpeed(vehicle) * 3.6
    local steerAngle = GetVehicleSteeringAngle(vehicle) or 0.0
    local steering = math.abs(steerAngle)
    local handbrake = IsControlPressed(0, 76)
    local throttle = IsControlPressed(0, 71) and 1.0 or 0.0
    local burnout = IsVehicleInBurnout(vehicle)
    local airborne = IsEntityInAir(vehicle)
    local turningLeft = steerAngle > 0.0
    local decel = math.max(0.0, (lastTireSpeedKmh - speed) / math.max(delta, 0.001))
    local braking = (IsControlPressed(0, 72) and speed > 8.0) or decel > 80.0
    local driveBiasFront = math.max(0.0, math.min(1.0, tireBaseHandling.driveBiasFront or 0.5))
    local localSpeed = GetEntitySpeedVector(vehicle, true)
    local lateralSlipKmh = math.abs(localSpeed.x or 0.0) * 3.6
    lastTireSpeedKmh = speed

    if braking then
        local brakeHeat = math.min(115.0, 8.0 + (speed / 180.0) * 34.0 + math.min(45.0, decel / 18.0))
        brakeTemp = math.min(820.0, brakeTemp + (brakeHeat * delta))
    else
        local brakeCoolTarget = 30.0 + math.min(35.0, speed * 0.08)
        local brakeCoolRate = brakeTemp > 520.0 and 0.22 or 0.075
        brakeTemp = brakeTemp + ((brakeCoolTarget - brakeTemp) * brakeCoolRate * delta)
    end
    brakeFactor = getBrakeFactor(brakeTemp)

    local tempSum, wearSum, gripSum = 0.0, 0.0, 0.0
    for _, key in ipairs(tireKeys) do
        local tire = tireTelemetry[key]
        local isFront, isRear = key == 'lf' or key == 'rf', key == 'lr' or key == 'rr'
        local isOuter = (turningLeft and (key == 'rf' or key == 'rr')) or ((not turningLeft) and (key == 'lf' or key == 'lr'))
        local axleDriveShare = isFront and driveBiasFront or (1.0 - driveBiasFront)
        local isDriven = axleDriveShare > 0.08
        local drivenLoad = isDriven and (0.55 + (axleDriveShare * 0.90)) or 0.22
        local wheelSlipKmh = getWheelSlipKmh(vehicle, tireWheelIndex[key], speed)
        local driftSlipKmh = math.max(0.0, lateralSlipKmh - 7.0) * (isOuter and 1.10 or 0.78)
        if handbrake and isRear then driftSlipKmh = driftSlipKmh * 1.55 end
        local slipKmh = math.max(wheelSlipKmh, driftSlipKmh)

        local targetTemp = 30.0
        if speed > 3.0 then
            local rollingTarget = 27.0 + math.min(30.0, speed * 0.17)
            local drivetrainTarget = throttle * math.min(13.0, (speed / 170.0) * 9.0 + 2.0) * drivenLoad
            targetTemp = rollingTarget + drivetrainTarget
        end
        local heatRate = 0.014 + (throttle * drivenLoad * 0.007)
        local directHeat = 0.0

        if speed > 55.0 and steering > 10.0 then
            local cornerLoad = math.min(16.0, ((speed - 45.0) / 135.0) * (steering / 36.0) * 13.0)
            if isFront then cornerLoad = cornerLoad * 1.02 end
            if isOuter then cornerLoad = cornerLoad * 1.30 else cornerLoad = cornerLoad * 0.56 end
            targetTemp = targetTemp + cornerLoad
            heatRate = heatRate + 0.018
        end
        if braking and speed > 40.0 then
            local brakeLoad = math.min(13.0, 3.0 + (speed / 180.0) * 6.0 + math.min(4.0, decel / 110.0))
            targetTemp = targetTemp + (isFront and brakeLoad or (brakeLoad * 0.32))
            directHeat = directHeat + (isFront and math.min(1.8, decel / 190.0) or math.min(0.7, decel / 320.0))
            heatRate = heatRate + (isFront and 0.025 or 0.012)
        end
        if slipKmh > 8.0 then
            local slipHeat = math.min(30.0, (slipKmh - 8.0) * 0.95)
            if isDriven then slipHeat = slipHeat * drivenLoad end
            if isRear and handbrake then slipHeat = slipHeat * 1.35 end
            targetTemp = targetTemp + slipHeat
            directHeat = directHeat + math.min(18.0, slipHeat * 0.45)
            heatRate = heatRate + 0.035
        end
        if throttle > 0.0 and speed > 8.0 and isDriven then directHeat = directHeat + (math.min(0.55, (speed / 180.0) * 0.34 + 0.12) * axleDriveShare) end
        if handbrake and speed > 25.0 then
            targetTemp = targetTemp + (isRear and 14.0 or 4.0)
            directHeat = directHeat + (isRear and 8.0 or 1.5)
            heatRate = heatRate + (isRear and 0.08 or 0.025)
        end
        if burnout and slipKmh > 12.0 then
            local burnoutLoad = isDriven and drivenLoad or 0.25
            targetTemp = targetTemp + (72.0 * burnoutLoad)
            directHeat = directHeat + (34.0 * burnoutLoad)
            heatRate = heatRate + (0.18 * burnoutLoad)
        end
        if airborne then targetTemp = math.max(28.0, targetTemp - 30.0); directHeat = directHeat * 0.20; heatRate = heatRate * 0.35 end

        local coolRate = tire.temp > 110.0 and 0.20 or 0.035
        local rate = targetTemp > tire.temp and heatRate or coolRate
        tire.temp = math.max(20.0, math.min(165.0, tire.temp + ((targetTemp - tire.temp) * rate * delta) + (directHeat * delta)))

        local wearGain = 0.0
        if tire.temp > 110.0 then wearGain = wearGain + ((tire.temp - 110.0) * 0.008) end
        if speed > 85.0 and steering > 20.0 and isOuter then wearGain = wearGain + 0.045 end
        if braking and decel > 110.0 and isFront then wearGain = wearGain + 0.040 end
        if burnout and isDriven and slipKmh > 12.0 then wearGain = wearGain + (0.28 * drivenLoad) end
        if handbrake and speed > 45.0 and isRear then wearGain = wearGain + 0.075 end
        tire.wear = math.max(0.0, math.min(100.0, tire.wear + (wearGain * delta)))
        tire.grip = getTireGripFactor(tire.temp, tire.wear)
        tempSum = tempSum + tire.temp; wearSum = wearSum + tire.wear; gripSum = gripSum + tire.grip
    end

    tireTemp, tireWear, tireGrip = tempSum / 4.0, wearSum / 4.0, gripSum / 4.0
    local tireBrakeFactor = math.max(0.70, tireGrip - math.min(0.10, tireWear / 1000.0))
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMax', tireBaseHandling.tractionMax * tireGrip)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fTractionCurveMin', tireBaseHandling.tractionMin * tireGrip)
    SetVehicleHandlingFloat(vehicle, 'CHandlingData', 'fBrakeForce', tireBaseHandling.brakeForce * tireBrakeFactor * brakeFactor)

    if Config.EnableThermalHud then
        SendNUIMessage({ action = 'thermal', show = true, tires = tireTelemetry, brakeTemp = math.floor(brakeTemp + 0.5) })
    end
end

if Config.EnableThermalSystem then
    CreateThread(function()
        local lastTick = GetGameTimer()
        while true do
            Wait(16)
            local now = GetGameTimer()
            local delta = (now - lastTick) / 1000.0
            lastTick = now
            updateThermalSystem(GetVehiclePedIsIn(PlayerPedId(), false), delta)
        end
    end)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    resetTireHandling(vehicle)
    stopAllNitroFlames()
    setNitroSound(false)
    SendNUIMessage({ action = 'thermal', show = false })
end)
