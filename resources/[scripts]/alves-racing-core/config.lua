Config = Config or {}

Config.SpawnBlip = {
    enabled = true,
    label = 'Alves Racing Spawn',
    coords = vec3(97.5, -1924.4, 20.7),
    sprite = 38,
    color = 27,
    scale = 0.9,
    shortRange = false
}

Config.DisablePopulation = true
Config.ImmortalPlayers = true
Config.NoVehicleEjection = true
Config.DisableFuelDrain = true
Config.HideGtaHud = true
Config.MaxVehiclePerformance = true

-- Sistemas locais do servidor Alves Racing. Não ficam no alves-racingapp para manter o pacote de corridas isolado.
Config.EnableNitroSystem = true
Config.EnableThermalSystem = true
Config.EnableThermalHud = true

-- Nitro arcade/simcade do servidor.
Config.Nitro = {
    rechargePerSecond = 10.0,
    rechargeDelayMs = 1400,
    minToActivate = 6.0,
    defaultMode = 'balanced',
    order = { 'power', 'eco', 'balanced' },
    modes = {
        power = { label = 'AGRESSIVO', color = { r = 1.0, g = 0.05, b = 0.02 }, drainPerSecond = 38.0, torqueMultiplier = 1.75, powerMultiplier = 2.05 },
        eco = { label = 'ECONÔMICO', color = { r = 0.05, g = 1.0, b = 0.20 }, drainPerSecond = 16.0, torqueMultiplier = 1.22, powerMultiplier = 1.35 },
        balanced = { label = 'BALANCEADO', color = { r = 0.05, g = 0.45, b = 1.0 }, drainPerSecond = 25.0, torqueMultiplier = 1.45, powerMultiplier = 1.65 },
    }
}

-- Ped padrão para todos os jogadores no modo racing.
-- Troque somente esse campo se quiser outro piloto.
Config.ForcePilotPed = true
Config.PilotPedModel = 's_m_y_xmech_01'
