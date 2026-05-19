-- Alves Racing - Configuração central
-- Ajuste aqui o comportamento padrão do resource.

Config = Config or {}

Config.Debug = false

-- Cor global do servidor. Altere o convar `alves:themePrimary` no server.cfg
-- e as UIs derivam as variações claras/escuras automaticamente.
Config.Theme = {
    primary = GetConvar('alves:themePrimary', '#8b5cf6'),
    background = GetConvar('alves:themeBackground', '#080712')
}

-- Corridas solo por enquanto. Quando montar lobby multiplayer, troque para o total real.
Config.DefaultTotalRacers = 1

-- Proteção básica contra tempo fake enviado pelo client.
Config.MinRaceTimeMs = 15000
Config.MaxRaceTimeMs = 60 * 60 * 1000

Config.RankedCompletionElo = 20

-- Phase/ghost durante corrida: carros dos competidores não colidem entre si.
-- Continua permitindo colisão com mapa/props, só remove batida player x player.
Config.RaceVehiclePhase = true

-- Lobby/fila de corrida rápida.
Config.LobbyCountdownSeconds = 60
Config.LobbyMapOptions = 3
Config.LobbyVehicleOptions = 3

-- Chance da classe do carro em corridas ranked por tier.
-- Tiers baixos ficam mais em Classe A para a progressão começar menos brutal.
Config.RankedVehicleClassWeightsByTier = {
    Street = { A = 80, S = 20 },
    ['Semi Slick'] = { A = 80, S = 20 },
    Slick = { A = 35, S = 65 },
    Profissional = { A = 15, S = 85 },
    default = { A = 50, S = 50 }
}

-- Veículos disponíveis no lobby de corrida.
-- Apenas modelos JFx/custom: não usar carros padrão do GTA na frota do Alves Racing.
-- Use o spawn name do veículo e garanta que o pack JFx esteja em `ensure [JFx]`
-- antes do `ensure alves-racingapp`.
Config.RaceVehicles = {
    'arbitergtn', 'benito2020', 'carrion', 'carrionmech', 'cazador', 'clubr',
    'elegyrh8c', 'elegyxa19', 'elegyxa19ven', 'flashgrs', 'gstban1k2', 'gstbanac1',
    'gstbanac1b', 'gstbanac1c', 'gstbisc1', 'gstbisc1b', 'gstbisc1c', 'gstcdy2',
    'gstcdy2b', 'gstcdy2c', 'gstcdy2d', 'gstevmr1', 'gstgoose1', 'gstgoose1b',
    'gstingnt1', 'gstingnt1b', 'gstpaladingt', 'gstpenf1', 'gstpmp7s1', 'gstpmp7s1b',
    'gstpmp7s1d', 'gstraid3', 'gstrh5s2', 'gstsadlt5', 'gstsettimo1', 'gstslt1',
    'gstsrs1', 'gsttorle1', 'gstturo1', 'gstxsajest3reptile', 'gstyc1', 'hb450c',
    'hb450d', 'hb450p', 'hellfirec', 'komtour', 'nwjester', 'rathaulc',
    'rattowc', 'rattrailer', 'rattruckc', 'shenron', 'shinobid', 'sr8',
    'srspback', 'strwag', 'taurion', 'trager', 'tragmech', 'xlsstr',
}

Config.RaceVehiclesByClass = {
    S = Config.RaceVehicles,
    A = {
        'arbitergtc', 'cazadortcr', 'clubrhyc', 'dawn', 'growlerc', 'gstasp3',
        'gstcs24', 'gstpmp7s1c', 'gstvanguard1b', 'hb450s', 'hb4503k', 'remusx',
        's790', 'schlag', 'str', 'strcoupe', 'sunrise1', 'tailgatersr',
        'vulture',
    }
}

-- Balanceamento de handling por classe/tração.
-- maxFlatVel usa MPH neste servidor. acceleration = fInitialDriveForce.
Config.VehicleHandlingBalance = {
    A = {
        RWD = { maxFlatVel = 155.0, initialDriveForce = 0.36, steeringLock = 38.0, tractionMax = 2.45, tractionMin = 2.20 },
        AWD = { maxFlatVel = 149.0, initialDriveForce = 0.39, steeringLock = 35.5, tractionMax = 2.38, tractionMin = 2.18 },
        FWD = { maxFlatVel = 146.0, initialDriveForce = 0.34, steeringLock = 34.0, tractionMax = 2.32, tractionMin = 2.10 },
    },
    S = {
        RWD = { maxFlatVel = 183.0, initialDriveForce = 0.45, steeringLock = 39.0, tractionMax = 2.65, tractionMin = 2.35 },
        AWD = { maxFlatVel = 177.0, initialDriveForce = 0.49, steeringLock = 36.5, tractionMax = 2.58, tractionMin = 2.34 },
        FWD = { maxFlatVel = 171.0, initialDriveForce = 0.41, steeringLock = 34.5, tractionMax = 2.48, tractionMin = 2.22 },
    }
}

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

-- Quantos checkpoints entram no GPS/rota e quantos blips/props aparecem no mapa/mundo.
Config.CheckpointsAhead = 8
Config.MapBlipsAhead = 4
Config.CheckpointPropsAhead = 4
Config.CheckpointPropModel = 'prop_offroad_tyres02'
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
