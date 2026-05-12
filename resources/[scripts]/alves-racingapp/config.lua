-- Alves Racing - Configuração central
-- Ajuste aqui o comportamento padrão do resource.

Config = Config or {}

Config.Debug = false

Config.Theme = {
    primary = '#8b5cf6',
    primaryLight = '#a855f7',
    primaryDark = '#4c1d95',
    accent = '#fbbf24',
    background = '#080712'
}

-- Corridas solo por enquanto. Quando montar lobby multiplayer, troque para o total real.
Config.DefaultTotalRacers = 1

-- Proteção básica contra tempo fake enviado pelo client.
Config.MinRaceTimeMs = 15000
Config.MaxRaceTimeMs = 60 * 60 * 1000

Config.RankedCompletionElo = 20

-- Voltas automáticas por distância da pista no banco.
Config.LapsByDistance = {
    { minDistance = 15000, laps = 3 },
    { minDistance = 8000, laps = 2 },
    { minDistance = 0, laps = 0 } -- 0 = sprint
}

Config.CheckpointsAhead = 3
Config.CheckpointBuffer = 5.0
Config.ShowGpsRoute = true
Config.UseRoadsForGps = false
Config.GpsColor = 83
Config.BlipColor = 85

Config.DrawTextSetup = {
    markerType = 1,
    minHeight = 1.0,
    maxHeight = 30.0,
    baseSize = 0.1,
    markerColor = { r = 139, g = 92, b = 246, a = 220 },
    distanceColor = { r = 255, g = 255, b = 255, a = 255 },
    primaryColor = { r = 168, g = 85, b = 247, a = 255 }
}
