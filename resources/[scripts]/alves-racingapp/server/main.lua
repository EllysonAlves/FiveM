-- Alves Racing - Server
-- Sistema de corridas simplificado

print('^2[Alves Racing]^0 Server iniciado!')

-- ==================== CONFIGURAÇÃO ====================
-- Apenas veículos Classe S (Super Cars)
local QuickRaceVehicles = {
    -- JFx Super Cars
    'arbitergtc', 'arbitergtn', 'carrion', 'carrionmech', 'cazador', 'cazadortcr',
    'clubr', 'clubrhyc', 'elegyrh8c', 'elegyxa19', 'elegyxa19ven', 'flashgrs',
    'growlerc', 'gstasp3', 'gstbanac1', 'gstbanac1b', 'gstbanac1c',
    'gstbisc1', 'gstbisc1b', 'gstbisc1c', 'gstcdy2', 'gstcdy2b', 'gstcdy2c', 'gstcdy2d',
    'gstcs24', 'gstevmr1', 'gstingnt1', 'gstingnt1b', 'gstpaladingt', 'gstpenf1',
    'gstpmp7s1', 'gstpmp7s1b', 'gstpmp7s1c', 'gstpmp7s1d', 'gstraid3', 'gstrh5s2',
    'gstsadlt5', 'gstsettimo1', 'gstslt1', 'gstsrs1', 'gsttorle1', 'gstturo1',
    'gstvanguard1b', 'gstxsajest3reptile', 'gstyc1', 'hellfirec', 'nwjester',
    's790', 'schlag', 'shenron', 'shinobid', 'sr8', 'str', 'strcoupe',
    'taurion', 'trager', 'tragmech', 'vulture',
}

-- Sistema de Tiers ELO
local ELO_TIERS = {
    {name = 'Street', minPoints = 0, maxPoints = 100, color = '#6b7280'},
    {name = 'Semi Slick', minPoints = 101, maxPoints = 200, color = '#3b82f6'},
    {name = 'Slick', minPoints = 201, maxPoints = 300, color = '#8b5cf6'},
    {name = 'Profissional', minPoints = 301, maxPoints = 999999, color = '#fbbf24'}
}

local Tracks = {}
local activeRaces = {}
local raceLobbies = {}

-- ==================== INICIALIZAÇÃO ====================
MySQL.ready(function()
    print('[Alves Racing] MySQL conectado, carregando pistas...')
    
    -- Carregar tracks do banco
    MySQL.query('SELECT * FROM race_tracks', {}, function(results)
        if results then
            for _, track in ipairs(results) do
                Tracks[track.raceid] = {
                    raceid = track.raceid,
                    name = track.name,
                    checkpoints = json.decode(track.checkpoints),
                    distance = track.distance
                }
            end
            print(('[Alves Racing] ✅ %d pistas carregadas'):format(#results))
        else
            print('[Alves Racing] ❌ ERRO ao carregar pistas do banco')
        end
    end)
    
    -- Testar tabela track_times
    MySQL.query('SELECT COUNT(*) as count FROM track_times', {}, function(result)
        if result then
            print(string.format('[Alves Racing] ✅ Tabela track_times OK (%d registros)', result[1].count))
            
            -- Verificar estrutura
            MySQL.query('SHOW COLUMNS FROM track_times', {}, function(cols)
                if cols then
                    local columns = {}
                    for _, col in ipairs(cols) do
                        table.insert(columns, col.Field)
                    end
                    print(string.format('[Alves Racing] Colunas track_times: %s', table.concat(columns, ', ')))
                end
            end)
        else
            print('[Alves Racing] ❌ ERRO: Tabela track_times não encontrada')
        end
    end)
    
    -- Testar tabela racer_names
    MySQL.query('SELECT COUNT(*) as count FROM racer_names', {}, function(result)
        if result then
            print(string.format('[Alves Racing] ✅ Tabela racer_names OK (%d registros)', result[1].count))
            
            -- Verificar estrutura
            MySQL.query('SHOW COLUMNS FROM racer_names', {}, function(cols)
                if cols then
                    local columns = {}
                    for _, col in ipairs(cols) do
                        table.insert(columns, col.Field)
                    end
                    print(string.format('[Alves Racing] Colunas racer_names: %s', table.concat(columns, ', ')))
                end
            end)
        else
            print('[Alves Racing] ❌ ERRO: Tabela racer_names não encontrada')
        end
    end)
end)

-- ==================== FUNÇÕES AUXILIARES ====================
local function getCitizenId(src)
    local player = exports.qbx_core:GetPlayer(tonumber(src))
    if not player then return nil end
    return player.PlayerData.citizenid
end

local function getOrCreateRacer(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return nil end
    
    -- Buscar racer existente
    local result = MySQL.query.await('SELECT racername, elo_points, elo_tier FROM racer_names WHERE citizenid = ? AND active = 1', {citizenId})
    
    if not result or #result == 0 then
        -- Criar novo racer
        local player = exports.qbx_core:GetPlayer(tonumber(src))
        local racerName = player.PlayerData.charinfo.firstname .. ' ' .. player.PlayerData.charinfo.lastname
        local racerId = 'RC-' .. string.upper(string.sub(citizenId, 1, 6)) .. math.random(1, 9)
        local timestamp = os.date('%Y-%m-%d %H:%M:%S')
        
        MySQL.insert.await(
            'INSERT INTO racer_names (racerid, citizenid, racername, lasttouched, races, wins, tracks, ranking, active, crypto, elo_points, elo_tier) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            {racerId, citizenId, racerName, timestamp, 0, 0, 0, 1000, 1, 10066, 0, 'Street'}
        )
        
        print(('[Alves Racing] Novo racer criado: %s (ID: %s) - Tier: Street'):format(racerName, racerId))
        return racerName
    else
        -- Verificar se tem elo_points e elo_tier (para compatibilidade com BDs antigos)
        if result[1].elo_points == nil then
            MySQL.update.await('UPDATE racer_names SET elo_points = 0, elo_tier = ? WHERE citizenid = ? AND active = 1', {'Street', citizenId})
        end
        return result[1].racername
    end
end


local function getRacerRecordByCitizenId(citizenId)
    local rows = MySQL.query.await('SELECT racerid, racername, ranking, races, wins, elo_points, elo_tier FROM racer_names WHERE citizenid = ? AND active = 1 LIMIT 1', {citizenId})
    return rows and rows[1] or nil
end

local function getAutoLaps(distance)
    distance = tonumber(distance) or 0
    local rules = Config.LapsByDistance or {}
    for _, rule in ipairs(rules) do
        local minDistance = rule.minDistance
        local maxDistance = rule.maxDistance
        local minOk = minDistance == nil or distance >= minDistance
        local maxOk = maxDistance == nil or distance < maxDistance

        if minOk and maxOk then
            return rule.laps or 0
        end
    end
    return 0
end

local function cloneCheckpoints(track)
    local checkpoints = {}
    for i, checkpoint in ipairs(track.checkpoints or {}) do
        checkpoints[i] = {
            coords = checkpoint.coords,
            offset = checkpoint.offset or {
                left = {
                    x = checkpoint.coords.x - 5,
                    y = checkpoint.coords.y - 5,
                    z = checkpoint.coords.z
                },
                right = {
                    x = checkpoint.coords.x + 5,
                    y = checkpoint.coords.y + 5,
                    z = checkpoint.coords.z
                }
            }
        }
    end
    return checkpoints
end

local function getRandomTrackOptions(amount)
    local ids = {}
    for id, track in pairs(Tracks) do
        if track and track.checkpoints and #track.checkpoints > 0 then
            ids[#ids + 1] = id
        end
    end

    local options = {}
    while #ids > 0 and #options < amount do
        local index = math.random(1, #ids)
        local id = table.remove(ids, index)
        local track = Tracks[id]
        options[#options + 1] = {
            id = id,
            name = track.name,
            distance = track.distance or 0
        }
    end
    return options
end

local function getRandomVehicleOptions(amount)
    local pool = {}
    for _, vehicle in ipairs(QuickRaceVehicles) do
        pool[#pool + 1] = vehicle
    end

    local options = {}
    while #pool > 0 and #options < amount do
        local index = math.random(1, #pool)
        options[#options + 1] = table.remove(pool, index)
    end
    return options
end

local function countTable(tbl)
    local count = 0
    for _ in pairs(tbl or {}) do count = count + 1 end
    return count
end

local function buildLobbyState(lobby)
    local mapVotes = {}
    for _, option in ipairs(lobby.mapOptions or {}) do
        mapVotes[tostring(option.id)] = 0
    end

    local carVotes = {}
    for _, option in ipairs(lobby.vehicleOptions or {}) do
        carVotes[option] = 0
    end

    local players = {}
    for src, player in pairs(lobby.players or {}) do
        players[#players + 1] = {
            source = src,
            name = player.name,
            mapVote = player.mapVote,
            vehicleVote = player.vehicleVote
        }
        if player.mapVote then
            local key = tostring(player.mapVote)
            mapVotes[key] = (mapVotes[key] or 0) + 1
        end
        if player.vehicleVote then
            carVotes[player.vehicleVote] = (carVotes[player.vehicleVote] or 0) + 1
        end
    end

    return {
        lobbyId = lobby.id,
        raceType = lobby.raceType,
        endsAt = lobby.endsAt,
        secondsLeft = math.max(0, lobby.endsAt - os.time()),
        mapOptions = lobby.mapOptions,
        vehicleOptions = lobby.vehicleOptions,
        mapVotes = mapVotes,
        carVotes = carVotes,
        players = players,
        playerCount = #players
    }
end

local function broadcastLobby(lobby)
    local state = buildLobbyState(lobby)
    for src in pairs(lobby.players or {}) do
        TriggerClientEvent('alves-racingapp:client:updateLobby', src, state)
    end
end

local function broadcastGlobalLobbyAlert(lobby, racerName, sourcePlayer)
    local data = {
        lobbyId = lobby.id,
        raceType = lobby.raceType,
        racerName = racerName,
        source = sourcePlayer,
        secondsLeft = Config.LobbyCountdownSeconds or 60
    }

    for _, playerId in ipairs(GetPlayers()) do
        TriggerClientEvent('alves-racingapp:client:globalLobbyAlert', tonumber(playerId), data)
    end
end

local function pickWinningMap(lobby)
    local totals = {}
    for _, option in ipairs(lobby.mapOptions or {}) do
        totals[tostring(option.id)] = 0
    end
    for _, player in pairs(lobby.players or {}) do
        if player.mapVote then
            local key = tostring(player.mapVote)
            totals[key] = (totals[key] or 0) + 1
        end
    end

    local winners = {}
    local best = 0
    for _, option in ipairs(lobby.mapOptions or {}) do
        local votes = totals[tostring(option.id)] or 0
        if votes > best then
            best = votes
            winners = { option }
        elseif votes == best then
            winners[#winners + 1] = option
        end
    end

    if #winners == 0 then return nil end
    return winners[math.random(1, #winners)]
end

local function getPlayerVehicleChoice(lobby, src)
    local player = lobby.players[src]
    if player and player.vehicleVote then
        for _, option in ipairs(lobby.vehicleOptions or {}) do
            if option == player.vehicleVote then return option end
        end
    end
    return lobby.vehicleOptions[math.random(1, #lobby.vehicleOptions)]
end

local function startLobbyRace(lobby)
    if not lobby or lobby.started then return end
    lobby.started = true
    raceLobbies[lobby.raceType] = nil

    if countTable(lobby.players) == 0 then return end

    local winningMap = pickWinningMap(lobby)
    local track = winningMap and Tracks[winningMap.id] or nil
    if not track or not track.checkpoints or #track.checkpoints == 0 then
        print('[Alves Racing] Lobby cancelado: pista vencedora inválida')
        return
    end

    local checkpoints = cloneCheckpoints(track)
    local raceId = ('lobby_%s_%d'):format(lobby.raceType, os.time())
    local laps = getAutoLaps(track.distance)
    local participants = {}
    local totalRacers = countTable(lobby.players)
    local index = 0

    activeRaces[raceId] = {
        raceId = raceId,
        trackId = winningMap.id,
        trackName = track.name,
        raceType = lobby.raceType,
        laps = laps,
        startTime = os.time(),
        totalRacers = totalRacers,
        participants = participants
    }

    for src, player in pairs(lobby.players) do
        index = index + 1
        local vehicle = getPlayerVehicleChoice(lobby, src)
        participants[src] = {
            racerName = player.name,
            vehicleModel = vehicle,
            finished = false
        }
        TriggerClientEvent('alves-racingapp:client:startLobbyRace', src, {
            raceId = raceId,
            trackName = track.name,
            vehicleModel = vehicle,
            startCoords = checkpoints[1].coords,
            spawnIndex = index,
            laps = laps,
            checkpoints = checkpoints,
            totalRacers = totalRacers,
            raceType = lobby.raceType
        })
    end

    print(('[Alves Racing] Lobby iniciado: %s - %s - %d pilotos'):format(lobby.raceType, track.name, totalRacers))
end

local function scheduleLobbyStart(lobby)
    lobby.version = (lobby.version or 0) + 1
    local version = lobby.version
    lobby.endsAt = os.time() + (Config.LobbyCountdownSeconds or 60)

    SetTimeout((Config.LobbyCountdownSeconds or 60) * 1000, function()
        if lobby.started or lobby.version ~= version then return end
        startLobbyRace(lobby)
    end)
end

local function getOrCreateLobby(raceType)
    raceType = raceType == 'ranked' and 'ranked' or 'casual'
    local lobby = raceLobbies[raceType]
    if lobby and not lobby.started then return lobby end

    local maps = getRandomTrackOptions(Config.LobbyMapOptions or 3)
    local vehicles = getRandomVehicleOptions(Config.LobbyVehicleOptions or 3)
    if #maps == 0 or #vehicles == 0 then return nil end

    lobby = {
        id = ('%s_%d'):format(raceType, os.time()),
        raceType = raceType,
        players = {},
        mapOptions = maps,
        vehicleOptions = vehicles,
        started = false,
        version = 0,
        endsAt = os.time() + (Config.LobbyCountdownSeconds or 60)
    }
    raceLobbies[raceType] = lobby
    scheduleLobbyStart(lobby)
    return lobby
end

local function getTrackByName(trackName)
    if not trackName then return nil end
    for _, t in pairs(Tracks) do
        if t.name == trackName then return t end
    end
    return nil
end

local function getBestTimesForTrack(trackId)
    if not trackId then return {} end
    return MySQL.query.await(
        [[
            SELECT
                tt.racerName,
                tt.time,
                tt.vehicleModel AS car,
                tt.raceType,
                tt.trackId,
                rt.name AS trackName,
                FROM_UNIXTIME(tt.timestamp) AS date
            FROM track_times tt
            LEFT JOIN race_tracks rt ON rt.raceid = tt.trackId
            WHERE tt.trackId = ?
            ORDER BY tt.timestamp DESC
            LIMIT 30
        ]],
        {trackId}
    ) or {}
end

-- ==================== SISTEMA DE ELO ====================
local function getTierByPoints(eloPoints)
    for _, tier in ipairs(ELO_TIERS) do
        if eloPoints >= tier.minPoints and eloPoints <= tier.maxPoints then
            return tier
        end
    end
    return ELO_TIERS[1] -- Retorna Street como padrão
end

local function calculateEloGain(position, totalRacers)
    -- Sistema: Top 40% ganham pontos, distribuição decrescente
    local gainPercentage = totalRacers * 0.4
    
    if position > gainPercentage then
        -- Posições fora do top 40% perdem pontos
        local lossBase = 10
        return -lossBase
    end
    
    -- Pontos máximos baseados no número de participantes
    local maxPoints = math.floor(totalRacers * 5) -- 5 pontos por participante
    
    -- Distribuição decrescente (1º ganha mais)
    local pointsPerPosition = maxPoints / gainPercentage
    local gain = math.floor(maxPoints - ((position - 1) * pointsPerPosition))
    
    return math.max(gain, 5) -- Mínimo 5 pontos para ganhadores
end

function GetPlayerFromCitizenId(citizenId)
    local players = exports.qbx_core:GetQBPlayers()
    for src, player in pairs(players) do
        if player.PlayerData.citizenid == citizenId then
            return tonumber(src)
        end
    end
    return nil
end

local function updateRacerElo(citizenId, eloChange, raceType)
    -- Só aplica mudança de ELO em corridas rankeadas
    if raceType ~= 'ranked' then return end
    
    -- Buscar dados atuais
    local racerData = MySQL.query.await(
        'SELECT elo_points, elo_tier FROM racer_names WHERE citizenid = ? AND active = 1',
        {citizenId}
    )
    
    if not racerData or #racerData == 0 then return end
    
    local currentPoints = racerData[1].elo_points or 0
    local newPoints = math.max(0, currentPoints + eloChange) -- Não pode ficar negativo
    
    -- Verificar progressão de tier
    local newTier = getTierByPoints(newPoints)
    local oldTier = racerData[1].elo_tier or 'Street'
    
    -- Atualizar no banco
    MySQL.update.await(
        'UPDATE racer_names SET elo_points = ?, elo_tier = ? WHERE citizenid = ? AND active = 1',
        {newPoints, newTier.name, citizenId}
    )
    
    -- Notificar mudança de tier
    if newTier.name ~= oldTier then
        local src = GetPlayerFromCitizenId(citizenId)
        if src then
            TriggerClientEvent('ox_lib:notify', src, {
                title = '🏆 NOVO TIER!',
                description = string.format('Você subiu para %s!', newTier.name),
                type = 'success',
                duration = 5000
            })
        end
    end
    
    return newPoints, newTier.name
end

-- ==================== CALLBACKS ====================
print('[Alves Racing] Registrando callbacks...')

lib.callback.register('alves-racingapp:getOnlineCount', function(src)
    return #GetPlayers()
end)
print('[Alves Racing] ✅ Callback getOnlineCount registrado')

lib.callback.register('alves-racingapp:getPlayerInfo', function(src)
    local citizenId = getCitizenId(src)
    if not citizenId then 
        print('[Alves Racing] ERRO: citizenId não encontrado para source ' .. src)
        return {
            id = src,
            name = 'Piloto',
            level = 1,
            levelProgress = 0,
            elo = 0,
            tier = 'Street',
            stats = {
                races = 0,
                wins = 0,
                winRate = 0,
                totalTime = 0,
                bestLap = 0
            }
        }
    end
    
    local player = exports.qbx_core:GetPlayer(tonumber(src))
    if not player then 
        print('[Alves Racing] ERRO: player não encontrado para source ' .. src)
        return nil 
    end
    
    -- Buscar dados do racer
    local racerData = MySQL.query.await(
        'SELECT racername, elo_points, elo_tier FROM racer_names WHERE citizenid = ? AND active = 1',
        {citizenId}
    )
    
    if not racerData or #racerData == 0 then 
        print('[Alves Racing] AVISO: Dados de racer não encontrados, criando padrão para ' .. citizenId)
        return {
            id = src,
            name = 'Piloto',
            level = 1,
            levelProgress = 0,
            elo = 0,
            tier = 'Street',
            stats = {
                races = 0,
                wins = 0,
                winRate = 0,
                totalTime = 0,
                bestLap = 0
            }
        }
    end
    
    local racerRecord = getRacerRecordByCitizenId(citizenId)
    local totalRaces = racerRecord and (racerRecord.races or 0) or 0
    local wins = racerRecord and (racerRecord.wins or 0) or 0
    local totalTime = 0
    local bestLap = 0

    if racerRecord and racerRecord.racerid then
        local stats = MySQL.query.await([[
            SELECT 
                COUNT(*) as total_races,
                SUM(time) / 1000 as total_time_seconds,
                MIN(time) as best_lap
            FROM track_times
            WHERE racerid = ?
        ]], {racerRecord.racerid})

        if stats and stats[1] then
            totalTime = stats[1].total_time_seconds or 0
            bestLap = stats[1].best_lap or 0
            if totalRaces == 0 then totalRaces = stats[1].total_races or 0 end
        end
    end
    
    -- Calcular nível baseado em pontos ELO (cada 50 pontos = 1 nível)
    local eloPoints = racerData[1].elo_points or 0
    local level = math.floor(eloPoints / 50) + 1 -- Nível inicial é 1
    local levelProgress = (eloPoints % 50) * 2 -- Progresso até próximo nível em %
    
    print(string.format('[Alves Racing] Dados carregados para %s: Level %d, ELO %d', racerData[1].racername, level, eloPoints))
    
    return {
        id = src,
        name = racerData[1].racername,
        level = level,
        levelProgress = levelProgress,
        elo = eloPoints,
        tier = racerData[1].elo_tier,
        stats = {
            races = totalRaces,
            wins = wins,
            winRate = totalRaces > 0 and math.floor((wins / totalRaces) * 100) or 0,
            totalTime = totalTime,
            bestLap = bestLap
        }
    }
end)
print('[Alves Racing] ✅ Callback getPlayerInfo registrado')

lib.callback.register('alves-racingapp:getMyElo', function(src)
    local citizenId = getCitizenId(src)
    if not citizenId then return 1000 end
    
    local result = MySQL.query.await('SELECT ranking FROM racer_names WHERE citizenid = ? AND active = 1', {citizenId})
    if result and result[1] then
        return result[1].ranking or 1000
    end
    return 1000
end)
print('[Alves Racing] ✅ Callback getMyElo registrado')

lib.callback.register('alves-racingapp:getScoreboard', function(src, trackName)
    print(string.format('[Alves Racing] getScoreboard chamado para pista: %s', trackName or 'geral'))

    if trackName and trackName ~= '' then
        local track = getTrackByName(trackName)
        if not track then
            print(string.format('[Alves Racing] ERRO: Pista não encontrada: %s', trackName))
            return {}
        end
        return getBestTimesForTrack(track.raceid)
    end

    -- Sem pista selecionada: retorna as últimas corridas salvas no banco.
    return MySQL.query.await(
        [[
            SELECT
                tt.racerName,
                tt.time,
                tt.vehicleModel AS car,
                tt.raceType,
                tt.trackId,
                rt.name AS trackName,
                FROM_UNIXTIME(tt.timestamp) AS date
            FROM track_times tt
            LEFT JOIN race_tracks rt ON rt.raceid = tt.trackId
            ORDER BY tt.timestamp DESC
            LIMIT 30
        ]],
        {}
    ) or {}
end)

lib.callback.register('alves-racingapp:getTracks', function(src)
    local tracks = {}
    for _, track in pairs(Tracks) do
        tracks[#tracks + 1] = {
            id = track.raceid,
            name = track.name,
            distance = track.distance or 0
        }
    end
    table.sort(tracks, function(a, b) return tostring(a.name) < tostring(b.name) end)
    return tracks
end)

lib.callback.register('alves-racingapp:getMyProfile', function(src)
    print(string.format('[Alves Racing] getMyProfile chamado por source %d', src))
    
    local citizenId = getCitizenId(src)
    if not citizenId then 
        print('[Alves Racing] ERRO: citizenId não encontrado')
        return nil 
    end
    
    print(string.format('[Alves Racing] Buscando perfil para citizenId: %s', citizenId))
    
    -- Buscar dados do racer incluindo tier ELO
    local racerData = MySQL.query.await(
        'SELECT racername, ranking, races, wins, elo_points, elo_tier FROM racer_names WHERE citizenid = ? AND active = 1',
        {citizenId}
    )
    
    if not racerData or #racerData == 0 then
        print('[Alves Racing] Nenhum racer encontrado')
        return nil
    end
    
    local racer = racerData[1]
    local eloPoints = racer.elo_points or 0
    local eloTier = racer.elo_tier or 'Street'
    
    -- Buscar melhor tempo usando racerid
    local racerId = MySQL.query.await('SELECT racerid FROM racer_names WHERE citizenid = ? AND active = 1', {citizenId})
    local bestTime = 0
    
    if racerId and racerId[1] then
        local timeResult = MySQL.query.await(
            'SELECT MIN(time) as bestTime FROM track_times WHERE racerid = ?',
            {racerId[1].racerid}
        )
        
        if timeResult and timeResult[1] and timeResult[1].bestTime then
            bestTime = timeResult[1].bestTime
        end
    end
    
    -- Buscar posição no ranking geral
    local position = 1
    local allRacers = MySQL.query.await('SELECT citizenid FROM racer_names WHERE active = 1 ORDER BY ranking DESC')
    
    if allRacers then
        for i, r in ipairs(allRacers) do
            if r.citizenid == citizenId then
                position = i
                break
            end
        end
    end
    
    -- Buscar informações do tier
    local currentTier = getTierByPoints(eloPoints)
    local pointsInTier = eloPoints - currentTier.minPoints
    local tierMaxPoints = currentTier.maxPoints - currentTier.minPoints
    
    print(string.format('[Alves Racing] Perfil: %s - Tier: %s (%d/%d)', racer.racername, eloTier, eloPoints, tierMaxPoints))
    
    return {
        racername = racer.racername,
        ranking = racer.ranking,
        races = racer.races,
        wins = racer.wins,
        bestTime = bestTime,
        position = position,
        eloPoints = eloPoints,
        eloTier = eloTier,
        pointsInTier = pointsInTier,
        tierMaxPoints = tierMaxPoints,
        tierColor = currentTier.color
    }
end)

lib.callback.register('alves-racingapp:getGlobalRanking', function(src)
    print('[Alves Racing] getGlobalRanking chamado')
    
    -- Buscar top 50 ordenado por tier e pontos ELO
    local ranking = MySQL.query.await(
        [[SELECT racername, races, wins, ranking, elo_tier, elo_points 
          FROM racer_names 
          WHERE active = 1 
          ORDER BY 
            CASE elo_tier
              WHEN 'Profissional' THEN 4
              WHEN 'Slick' THEN 3
              WHEN 'Semi Slick' THEN 2
              WHEN 'Street' THEN 1
              ELSE 0
            END DESC,
            elo_points DESC 
          LIMIT 50]],
        {}
    )
    
    if ranking then
        print(string.format('[Alves Racing] Ranking encontrado: %d pilotos', #ranking))
        
        -- Adicionar cor de tier para cada piloto
        for _, racer in ipairs(ranking) do
            local tier = getTierByPoints(racer.elo_points or 0)
            racer.tierColor = tier.color
        end
    else
        print('[Alves Racing] ERRO: Nenhum piloto no ranking')
    end
    
    return ranking or {}
end)

lib.callback.register('alves-racingapp:server:startQuickRace', function(src, raceType)
    local racer = getOrCreateRacer(src)
    if not racer then
        return nil
    end

    local normalizedRaceType = raceType == 'ranked' and 'ranked' or 'casual'
    local existingLobby = raceLobbies[normalizedRaceType]
    local lobby = getOrCreateLobby(raceType)
    if not lobby then
        print('[Alves Racing] Não foi possível criar lobby: sem pistas ou veículos disponíveis')
        return nil
    end

    local isNewPlayer = lobby.players[src] == nil
    lobby.players[src] = lobby.players[src] or { name = racer }
    lobby.players[src].name = racer

    -- Toda entrada nova reinicia o contador de 1 minuto.
    if isNewPlayer then
        scheduleLobbyStart(lobby)
        print(('[Alves Racing] %s entrou no lobby %s. Timer reiniciado.'):format(racer, lobby.raceType))
    end

    broadcastLobby(lobby)
    if not existingLobby then
        broadcastGlobalLobbyAlert(lobby, racer, src)
    end
    return buildLobbyState(lobby)
end)

lib.callback.register('alves-racingapp:server:voteLobby', function(src, data)
    data = data or {}
    local raceType = data.raceType == 'ranked' and 'ranked' or 'casual'
    local lobby = raceLobbies[raceType]
    if not lobby or lobby.started or not lobby.players[src] then
        return nil
    end

    if data.mapId ~= nil then
        local mapId = tostring(data.mapId)
        for _, option in ipairs(lobby.mapOptions or {}) do
            if tostring(option.id) == mapId then
                lobby.players[src].mapVote = option.id
                break
            end
        end
    end

    if data.vehicleModel ~= nil then
        local vehicleModel = tostring(data.vehicleModel)
        for _, option in ipairs(lobby.vehicleOptions or {}) do
            if option == vehicleModel then
                lobby.players[src].vehicleVote = option
                break
            end
        end
    end

    broadcastLobby(lobby)
    return buildLobbyState(lobby)
end)

print('[Alves Racing] ✅ Todos os callbacks registrados com sucesso!')

-- ==================== EVENTOS ====================
RegisterNetEvent('alves-racingapp:server:finishRace', function(data)
    local src = source
    data = data or {}
    print(string.format('[Alves Racing] Recebendo finish race de source %d', src))
    print(string.format('[Alves Racing] Dados: %s', json.encode(data)))
    
    local citizenId = getCitizenId(src)
    if not citizenId then 
        print('[Alves Racing] ERRO: citizenId não encontrado')
        return 
    end

    local race = data.raceId and activeRaces[data.raceId] or nil
    local participant = race and race.participants and race.participants[src] or nil
    if not race or not participant then
        print(('[Alves Racing] ERRO: finishRace rejeitado. Corrida ativa inválida para source %d'):format(src))
        return
    end

    if participant.finished then
        print(('[Alves Racing] ERRO: finishRace duplicado rejeitado para source %d'):format(src))
        return
    end

    local totalTime = tonumber(data.totalTime) or 0
    if totalTime < (Config.MinRaceTimeMs or 15000) or totalTime > (Config.MaxRaceTimeMs or 3600000) then
        print(('[Alves Racing] ERRO: tempo suspeito rejeitado (%dms) para source %d'):format(totalTime, src))
        return
    end

    if data.raceName ~= race.trackName then
        print(('[Alves Racing] ERRO: nome de pista divergente. client=%s server=%s'):format(tostring(data.raceName), tostring(race.trackName)))
        return
    end
    participant.finished = true
    
    print(string.format('[Alves Racing] citizenId: %s', citizenId))
    
    -- Garantir que racer existe
    local racer = getOrCreateRacer(src)
    if not racer then
        print('[Alves Racing] ERRO: Não foi possível criar/buscar racer')
        return
    end
    
    local racerName = racer
    print(string.format('[Alves Racing] Racer: %s', racerName))
    
    -- Buscar ID da pista
    local track = nil
    for _, t in pairs(Tracks) do
        if t.name == data.raceName then
            track = t
            break
        end
    end
    
    if not track then
        print('[Alves Racing] Pista não encontrada: ' .. data.raceName)
        return
    end
    
    -- Salvar tempo na tabela track_times (estrutura real do banco)
    print(string.format('[Alves Racing] Salvando tempo no banco: trackId=%s, racer=%s, time=%d', track.raceid, racerName, totalTime))
    
    -- Buscar racerid
    local racerData = MySQL.query.await('SELECT racerid FROM racer_names WHERE citizenid = ? AND active = 1', {citizenId})
    local racerid = (racerData and racerData[1]) and racerData[1].racerid or 0
    
    local success = MySQL.insert.await(
        'INSERT INTO track_times (trackId, racerName, racerid, carClass, vehicleModel, raceType, time, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {track.raceid, racerName, racerid, 'S', data.vehicle or participant.vehicleModel or 'Unknown', race.raceType or data.raceType or 'casual', totalTime, os.time()}
    )
    
    if success then
        print(('[Alves Racing] ✅ Tempo salvo: %s - %s - %dms'):format(racerName, track.name, totalTime))
    else
        print('[Alves Racing] ❌ ERRO ao salvar tempo no banco')
    end
    
    -- Atualizar estatísticas do racer
    MySQL.update.await('UPDATE racer_names SET races = races + 1 WHERE citizenid = ? AND active = 1', {citizenId})
    
    -- Calcular e aplicar pontos ELO (apenas para corridas rankeadas)
    if race.raceType == 'ranked' then
        -- Sistema simplificado: cada corrida completada ganha pontos
        -- Futuramente expandir para sistema multiplayer com posições
        local eloGain = Config.RankedCompletionElo or 20 -- Pontos fixos por corrida rankeada completada
        
        local newPoints, newTier = updateRacerElo(citizenId, eloGain, 'ranked')
        
        -- Notificar jogador
        TriggerClientEvent('ox_lib:notify', src, {
            title = '🏆 ELO Ganho!',
            description = string.format('+%d pontos ELO\nTier: %s (%d/100)', eloGain, newTier or 'Street', newPoints or 0),
            type = 'success',
            duration = 5000
        })
        
        print(string.format('[Alves Racing] ✅ ELO atualizado: %s ganhou %d pontos', racerName, eloGain))
    end

    local allFinished = true
    for _, p in pairs(race.participants or {}) do
        if not p.finished then
            allFinished = false
            break
        end
    end
    if allFinished then
        activeRaces[data.raceId] = nil
    end
end)

RegisterNetEvent('alves-racingapp:server:leaveRace', function()
    local src = source
    
    -- Remover de lobbies abertos
    for _, lobby in pairs(raceLobbies) do
        if lobby.players and lobby.players[src] then
            lobby.players[src] = nil
            broadcastLobby(lobby)
            if countTable(lobby.players) == 0 then
                lobby.started = true
                raceLobbies[lobby.raceType] = nil
            end
            break
        end
    end
    
    -- Remover de corridas ativas
    for raceId, race in pairs(activeRaces) do
        if race.participants and race.participants[src] then
            race.participants[src] = nil
            if countTable(race.participants) == 0 then
                activeRaces[raceId] = nil
            end
            print(('[Alves Racing] Source %d saiu da corrida'):format(src))
            break
        end
    end
end)

-- ==================== COMANDOS ADMIN ====================
RegisterCommand('racestats', function(source, args, rawCommand)
    if source == 0 then  -- Console only
        print('========== ALVES RACING STATS ==========')
        print(('Pistas carregadas: %d'):format(#Tracks))
        print(('Corridas ativas: %d'):format(#activeRaces))
        print(('Veículos disponíveis: %d'):format(#QuickRaceVehicles))
        print('========================================')
    end
end, true)

RegisterCommand('racedebug', function(source, args, rawCommand)
    if source == 0 then return end
    
    local citizenId = getCitizenId(source)
    print('========== ALVES RACING DEBUG ==========')
    print(('Source: %d'):format(source))
    print(('CitizenId: %s'):format(citizenId or 'nil'))
    
    if citizenId then
        local racer = MySQL.query.await('SELECT * FROM racer_names WHERE citizenid = ? AND active = 1', {citizenId})
        if racer and #racer > 0 then
            print(('Racer: %s (ELO: %d)'):format(racer[1].racername, racer[1].ranking))
        else
            print('Racer: NÃO ENCONTRADO')
        end
        
        local times = MySQL.query.await('SELECT COUNT(*) as count FROM track_times WHERE citizenid = ?', {citizenId})
        if times and times[1] then
            print(('Tempos salvos: %d'):format(times[1].count))
        end
    end
    print('========================================')
end, false)

RegisterCommand('racetest', function(source, args, rawCommand)
    if source == 0 then return end
    
    -- Testar criação de racer
    local racer = getOrCreateRacer(source)
    if racer then
        exports.qbx_core:Notify(source, string.format('Racer: %s', racer), 'success')
    else
        exports.qbx_core:Notify(source, 'ERRO ao criar racer', 'error')
    end
end, false)
