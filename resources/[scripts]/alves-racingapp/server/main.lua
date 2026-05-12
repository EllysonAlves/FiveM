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
    
    -- Buscar estatísticas
    local stats = MySQL.query.await([[
        SELECT 
            COUNT(*) as total_races,
            SUM(CASE WHEN placement = 1 THEN 1 ELSE 0 END) as wins,
            SUM(time) / 1000 as total_time_seconds,
            MIN(time) as best_lap
        FROM track_times
        WHERE citizenid = ?
    ]], {citizenId})
    
    local totalRaces = (stats and stats[1]) and stats[1].total_races or 0
    local wins = (stats and stats[1]) and stats[1].wins or 0
    local totalTime = (stats and stats[1]) and stats[1].total_time_seconds or 0
    local bestLap = (stats and stats[1]) and stats[1].best_lap or 0
    
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
    print(string.format('[Alves Racing] getScoreboard chamado para pista: %s', trackName or 'nil'))
    
    if not trackName or trackName == '' then 
        print('[Alves Racing] ERRO: trackName vazio')
        return {} 
    end
    
    -- Buscar track ID
    local track = nil
    for _, t in pairs(Tracks) do
        if t.name == trackName then
            track = t
            break
        end
    end
    
    if not track then 
        print(string.format('[Alves Racing] ERRO: Pista não encontrada: %s', trackName))
        return {} 
    end
    
    print(string.format('[Alves Racing] Buscando tempos para trackId: %s', track.raceid))
    
    -- Buscar top 10 tempos da pista
    local times = MySQL.query.await(
        'SELECT racerName, time, vehicleModel as car, FROM_UNIXTIME(timestamp) as date FROM track_times WHERE trackId = ? ORDER BY time ASC LIMIT 10',
        {track.raceid}
    )
    
    if times then
        print(string.format('[Alves Racing] Scoreboard: %d tempos encontrados', #times))
    else
        print('[Alves Racing] ERRO: Nenhum tempo encontrado')
    end
    
    return times or {}
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
    
    -- Selecionar pista aleatória
    local trackIds = {}
    for id, _ in pairs(Tracks) do
        table.insert(trackIds, id)
    end
    
    if #trackIds == 0 then
        print('[Alves Racing] Nenhuma pista disponível')
        return nil
    end
    
    local trackId = trackIds[math.random(1, #trackIds)]
    local track = Tracks[trackId]
    
    if not track or not track.checkpoints or #track.checkpoints == 0 then
        print('[Alves Racing] Pista inválida')
        return nil
    end
    
    -- Selecionar veículo aleatório
    local vehicle = QuickRaceVehicles[math.random(1, #QuickRaceVehicles)]
    
    -- Determinar voltas baseado na distância
    local laps = 0  -- Sprint por padrão
    if track.distance >= 15000 then
        laps = 3
    elseif track.distance >= 8000 then
        laps = 2
    end
    
    -- Criar ID de corrida
    local raceId = 'quick_' .. src .. '_' .. os.time()
    
    -- Garantir que checkpoints tenham offset (para compatibilidade com sistema de detecção)
    local checkpoints = {}
    for i, checkpoint in ipairs(track.checkpoints) do
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
    
    -- Registrar corrida ativa
    activeRaces[raceId] = {
        raceId = raceId,
        trackId = trackId,
        trackName = track.name,
        vehicleModel = vehicle,
        raceType = raceType,
        laps = laps,
        racerId = src,
        racerName = racer,
        startTime = os.time()
    }
    
    print(('[Alves Racing] Quick race iniciada: %s - %s (%s)'):format(racer, track.name, raceType))
    
    return {
        raceId = raceId,
        trackName = track.name,
        vehicleModel = vehicle,
        startCoords = checkpoints[1].coords,
        laps = laps,
        checkpoints = checkpoints
    }
end)

print('[Alves Racing] ✅ Todos os callbacks registrados com sucesso!')

-- ==================== EVENTOS ====================
RegisterNetEvent('alves-racingapp:server:finishRace', function(data)
    local src = source
    print(string.format('[Alves Racing] Recebendo finish race de source %d', src))
    print(string.format('[Alves Racing] Dados: %s', json.encode(data)))
    
    local citizenId = getCitizenId(src)
    if not citizenId then 
        print('[Alves Racing] ERRO: citizenId não encontrado')
        return 
    end
    
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
    print(string.format('[Alves Racing] Salvando tempo no banco: trackId=%s, racer=%s, time=%d', track.raceid, racerName, data.totalTime))
    
    -- Buscar racerid
    local racerData = MySQL.query.await('SELECT racerid FROM racer_names WHERE citizenid = ? AND active = 1', {citizenId})
    local racerid = (racerData and racerData[1]) and racerData[1].racerid or 0
    
    local success = MySQL.insert.await(
        'INSERT INTO track_times (trackId, racerName, racerid, carClass, vehicleModel, raceType, time, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        {track.raceid, racerName, racerid, 'S', data.vehicle or 'Unknown', data.raceType or 'Circuit', data.totalTime, os.time()}
    )
    
    if success then
        print(('[Alves Racing] ✅ Tempo salvo: %s - %s - %dms'):format(racerName, track.name, data.totalTime))
    else
        print('[Alves Racing] ❌ ERRO ao salvar tempo no banco')
    end
    
    -- Atualizar estatísticas do racer
    MySQL.update.await('UPDATE racer_names SET races = races + 1 WHERE citizenid = ? AND active = 1', {citizenId})
    
    -- Calcular e aplicar pontos ELO (apenas para corridas rankeadas)
    if data.raceType == 'ranked' then
        -- Sistema simplificado: cada corrida completada ganha pontos
        -- Futuramente expandir para sistema multiplayer com posições
        local eloGain = 20 -- Pontos fixos por corrida rankeada completada
        
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
end)

RegisterNetEvent('alves-racingapp:server:leaveRace', function()
    local src = source
    
    -- Remover de corridas ativas
    for raceId, race in pairs(activeRaces) do
        if race.racerId == src then
            activeRaces[raceId] = nil
            print(('[Alves Racing] %s saiu da corrida'):format(race.racerName))
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
