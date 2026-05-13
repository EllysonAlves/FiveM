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

-- Lobby/fila de corrida rápida.
Config.LobbyCountdownSeconds = 60
Config.LobbyMapOptions = 3
Config.LobbyVehicleOptions = 3

-- Voltas automáticas por distância da pista no banco.
-- Regra do Alves Racing:
-- - pistas curtas viram circuito com mais voltas;
-- - pistas médias viram circuito menor;
-- - pistas longas viram sprint/ponto-a-ponto para não ficar corrida gigante com 3 voltas.
-- laps = 0 significa sprint.
Config.LapsByDistance = {
    { maxDistance = 6000, laps = 3 },
    { maxDistance = 10000, laps = 2 },
    { maxDistance = 14000, laps = 1 },
    { minDistance = 14000, laps = 0 } -- sprint
}

Config.CheckpointsAhead = 8
Config.CheckpointBuffer = 5.0
Config.ShowGpsRoute = true
Config.UseRoadsForGps = true
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
