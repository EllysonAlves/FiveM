// Alves Racing - UI Script sem dependências externas

let raceStartTime = 0;
let timerInterval = null;
let countdownInterval = null;
let lobbyInterval = null;
let currentLobby = null;
let lobbyMinimized = false;

const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => Array.from(document.querySelectorAll(selector));

function setText(selector, value) {
    const el = $(selector);
    if (el) el.textContent = value;
}

function setHtml(selector, value) {
    const el = $(selector);
    if (el) el.innerHTML = value;
}

function addClass(selector, cls) {
    const el = typeof selector === 'string' ? $(selector) : selector;
    if (el) el.classList.add(cls);
}

function removeClass(selector, cls) {
    const el = typeof selector === 'string' ? $(selector) : selector;
    if (el) el.classList.remove(cls);
}

function nuiPost(eventName, payload = {}) {
    fetch(`https://alves-racingapp/${eventName}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(payload)
    }).catch(() => {});
}

window.addEventListener('message', function(event) {
    const data = event.data || {};
    switch (data.action) {
        case 'openTablet': openTablet(data.data); break;
        case 'closeTablet': closeTablet(); break;
        case 'startCountdown': startCountdown(data.seconds); break;
        case 'updateRaceHUD': updateRaceHUD(data.data || {}); break;
        case 'showRaceHUD': showRaceHUD(); break;
        case 'hideRaceHUD': hideRaceHUD(); break;
        case 'updateProfile': updateProfile(data.data || {}); break;
        case 'showScoreboard': displayScoreboard(data.data || {}); break;
        case 'showRanking': displayRanking(data.data || {}); break;
        case 'showProfile': displayProfile(data.data || {}); break;
        case 'showLobby': displayLobby(data.data || {}); break;
        case 'hideLobby': hideLobby(); break;
        case 'minimizeLobby': minimizeLobby(false); break;
        case 'maximizeLobby': maximizeLobby(false); break;
        case 'toggleLobby': toggleLobby(false); break;
    }
});

function setActiveMenu(label) {
    $$('.menu-item').forEach(item => {
        item.classList.toggle('active', item.textContent.toUpperCase().includes(label.toUpperCase()));
    });
}

function openTablet(data) {
    removeClass('#tablet', 'hidden');
    const player = data?.player || {};

    setText('#player-id', player.id || '0000');
    setText('#player-name', player.name || 'Piloto');
    setText('#player-level', player.level || '1');

    const elo = player.elo || 0;
    const level = player.level || 1;
    setText('#level-progress', `${elo} / ${level * 50} XP`);
    const fill = $('#level-fill');
    if (fill) fill.style.width = `${player.levelProgress || 0}%`;

    const stats = player.stats || {};
    setText('#stats-races', stats.races || '0');
    setText('#stats-wins', stats.wins || '0');

    const totalSeconds = stats.totalTime || 0;
    setText('#stats-time', `${Math.floor(totalSeconds / 3600)}h ${Math.floor((totalSeconds % 3600) / 60)}m`);
    setText('#stats-best', stats.bestLap && stats.bestLap > 0 ? formatTime(stats.bestLap) : '--:--.---');
    setText('#online-players', data?.onlineCount ?? '0');
}

function closeTablet() {
    addClass('#tablet', 'hidden');
    nuiPost('closeTablet');
}

function showDashboard() {
    setActiveMenu('DASHBOARD');
    $$('.modal').forEach(m => m.classList.add('hidden'));
}

function showComingSoon(name) {
    $$('.modal').forEach(m => m.classList.add('hidden'));
    displayInfoModal(name, 'Área preparada para a identidade visual do servidor. Funcionalidade pode ser conectada na próxima fase.');
}

function displayInfoModal(title, message) {
    setText('#scoreboard-title', title.toUpperCase());
    setHtml('#scoreboard-tbody', `<tr><td colspan="4" style="text-align:center;">${message}</td></tr>`);
    removeClass('#modal-scoreboard', 'hidden');
}

function startRace(type) {
    addClass('#tablet', 'hidden');
    $$('.modal').forEach(m => m.classList.add('hidden'));
    nuiPost('startRace', { raceType: type });
}

function hideLobby() {
    addClass('#modal-lobby', 'hidden');
    addClass('#lobby-mini', 'hidden');
    currentLobby = null;
    lobbyMinimized = false;
    if (lobbyInterval) {
        clearInterval(lobbyInterval);
        lobbyInterval = null;
    }
}

function leaveLobby() {
    nuiPost('leaveLobby');
    hideLobby();
}

function minimizeLobby(notifyClient = true) {
    if (!currentLobby) return;
    lobbyMinimized = true;
    addClass('#modal-lobby', 'hidden');
    removeClass('#lobby-mini', 'hidden');
    updateLobbyMini();
    if (notifyClient) nuiPost('minimizeLobby');
}

function maximizeLobby(notifyClient = true) {
    if (!currentLobby) return;
    lobbyMinimized = false;
    addClass('#lobby-mini', 'hidden');
    removeClass('#modal-lobby', 'hidden');
    if (notifyClient) nuiPost('maximizeLobby');
}

function toggleLobby(notifyClient = true) {
    if (!currentLobby) return;
    if (lobbyMinimized || $('#modal-lobby')?.classList.contains('hidden')) {
        maximizeLobby(notifyClient);
    } else {
        minimizeLobby(notifyClient);
    }
}

function getTopVotedOption(options, votes, keyGetter) {
    let winner = null;
    let winnerVotes = 0;
    (options || []).forEach(option => {
        const key = String(keyGetter(option));
        const count = Number(votes?.[key] || 0);
        if (count > winnerVotes) {
            winner = option;
            winnerVotes = count;
        }
    });
    return winnerVotes > 0 ? winner : null;
}

function updateLobbyMini() {
    if (!currentLobby) return;
    const mapWinner = getTopVotedOption(currentLobby.mapOptions || [], currentLobby.mapVotes || {}, map => map.id);
    const carWinner = getTopVotedOption(currentLobby.vehicleOptions || [], currentLobby.carVotes || {}, vehicle => vehicle);

    setText('#lobby-mini-map', mapWinner?.name || 'Aleatória');
    setText('#lobby-mini-car', carWinner || 'Aleatório');
    setText('#lobby-mini-players', currentLobby.playerCount || 0);

    const remaining = Math.max(0, (currentLobby.endsAt || 0) - Math.floor(Date.now() / 1000));
    setText('#lobby-mini-timer', `${remaining}s`);
}

function voteMap(mapId) {
    if (!currentLobby) return;
    nuiPost('lobbyVote', { raceType: currentLobby.raceType, mapId });
}

function voteCar(vehicleModel) {
    if (!currentLobby) return;
    nuiPost('lobbyVote', { raceType: currentLobby.raceType, vehicleModel });
}

function displayLobby(data) {
    currentLobby = data || {};
    $$('.modal').forEach(m => m.classList.add('hidden'));
    addClass('#tablet', 'hidden');

    if (lobbyMinimized) {
        addClass('#modal-lobby', 'hidden');
        removeClass('#lobby-mini', 'hidden');
    } else {
        addClass('#lobby-mini', 'hidden');
        removeClass('#modal-lobby', 'hidden');
    }

    const typeText = currentLobby.raceType === 'ranked' ? 'RANQUEADA' : 'CASUAL';
    setText('#lobby-title', `LOBBY ${typeText}`);
    setText('#lobby-players-count', currentLobby.playerCount || 0);

    const renderTimer = () => {
        const remaining = Math.max(0, (currentLobby.endsAt || 0) - Math.floor(Date.now() / 1000));
        setText('#lobby-timer', `${remaining}s`);
        updateLobbyMini();
    };
    renderTimer();
    if (lobbyInterval) clearInterval(lobbyInterval);
    lobbyInterval = setInterval(renderTimer, 250);

    const mapVotes = currentLobby.mapVotes || {};
    const carVotes = currentLobby.carVotes || {};
    const players = currentLobby.players || [];

    const mapHtml = (currentLobby.mapOptions || []).map((map, index) => {
        const votes = mapVotes[String(map.id)] || 0;
        const distance = map.distance ? `${(Number(map.distance) / 1000).toFixed(1)} km` : 'distância dinâmica';
        return `
            <button class="lobby-option map-option" onclick="voteMap('${String(map.id).replace(/'/g, "\\'")}')">
                <span class="option-index">MAPA ${index + 1}</span>
                <strong>${map.name || 'Pista desconhecida'}</strong>
                <small>${distance}</small>
                <span class="option-votes">${votes} voto${votes === 1 ? '' : 's'}</span>
            </button>`;
    }).join('');

    const carHtml = (currentLobby.vehicleOptions || []).map((vehicle, index) => {
        const votes = carVotes[vehicle] || 0;
        return `
            <button class="lobby-option car-option" onclick="voteCar('${String(vehicle).replace(/'/g, "\\'")}')">
                <span class="option-index">CARRO ${index + 1}</span>
                <strong>${vehicle}</strong>
                <small>Escolha individual</small>
                <span class="option-votes">${votes} escolhido${votes === 1 ? '' : 's'}</span>
            </button>`;
    }).join('');

    setHtml('#lobby-map-options', mapHtml || '<p class="lobby-empty">Nenhum mapa disponível</p>');
    setHtml('#lobby-car-options', carHtml || '<p class="lobby-empty">Nenhum carro disponível</p>');

    const playerHtml = players.map(player => `
        <div class="lobby-player">
            <span>${player.name || 'Piloto'}</span>
            <small>${player.mapVote ? 'mapa votado' : 'sem mapa'} • ${player.vehicleVote || 'carro aleatório'}</small>
        </div>`).join('');
    setHtml('#lobby-player-list', playerHtml || '<div class="lobby-player"><span>Aguardando pilotos...</span></div>');
}

function showScoreboard() {
    nuiPost('showScoreboard');
}

function showRanking() {
    setActiveMenu('RANKING');
    nuiPost('showRanking');
}

function showProfile() {
    setActiveMenu('PERFIL');
    nuiPost('showProfile');
}

function showRaceHUD() {
    removeClass('#race-hud', 'hidden');
    raceStartTime = Date.now();
    startTimer();
}

function hideRaceHUD() {
    addClass('#race-hud', 'hidden');
    stopTimer();
}

function hideCountdown() {
    addClass('#countdown', 'hidden');
    if (countdownInterval) {
        clearInterval(countdownInterval);
        countdownInterval = null;
    }
}

function startCountdown(seconds) {
    hideCountdown();
    const countdown = $('#countdown');
    const countdownNumber = $('#countdown-number');
    if (!countdown || !countdownNumber) return;

    countdown.classList.remove('hidden');
    let current = Number(seconds) || 0;
    countdownNumber.textContent = current > 0 ? current : 'GO!';

    if (countdownInterval) clearInterval(countdownInterval);
    countdownInterval = setInterval(() => {
        current -= 1;
        if (current <= 0) {
            countdownNumber.textContent = 'GO!';
            setTimeout(() => {
                hideCountdown();
                showRaceHUD();
            }, 800);
            clearInterval(countdownInterval);
            countdownInterval = null;
        } else {
            countdownNumber.textContent = current;
        }
    }, 1000);
}

function updateRaceHUD(data) {
    const d = data || {};
    if (d.position !== undefined) {
        setHtml('#race-position', d.totalRacers !== undefined ? `<span class="race-value-accent">${d.position}º</span> <span class="stat-total">/ ${d.totalRacers}</span>` : `<span class="race-value-accent">${d.position}º</span>`);
    }
    if (d.lap !== undefined) {
        setHtml('#race-lap', d.totalLaps !== undefined ? `${d.lap} <span class="stat-total">/ ${d.totalLaps}</span>` : `${d.lap}`);
    }
    if (d.checkpoint !== undefined) {
        setHtml('#race-checkpoint', d.totalCheckpoints !== undefined ? `<span class="race-value-accent">${d.checkpoint}</span> <span class="stat-total">/ ${d.totalCheckpoints}</span>` : `<span class="race-value-accent">${d.checkpoint}</span>`);
    }
    if (d.bestLap !== undefined) setText('#race-best-lap', d.bestLap === 0 ? '--:--.---' : formatTime(d.bestLap));
    if (d.time !== undefined) setText('#race-time', formatTime(d.time));
}

function startTimer() {
    stopTimer();
    timerInterval = setInterval(() => {
        setText('#race-time', formatTime(Date.now() - raceStartTime));
    }, 100);
}

function stopTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
}

function updateProfile(data) {
    if (data?.elo !== undefined) setText('#profile-elo', `ELO: ${data.elo}`);
}

function displayScoreboard(data) {
    $$('.modal').forEach(m => m.classList.add('hidden'));
    setText('#scoreboard-title', data?.trackName ? `SCOREBOARD - ${data.trackName}` : 'SCOREBOARD GLOBAL');
    let html = '';
    if (Array.isArray(data?.times) && data.times.length) {
        data.times.forEach((entry, index) => {
            html += `
                <tr>
                    <td>${index + 1}</td>
                    <td>${entry.racerName || entry.racer || 'Desconhecido'}</td>
                    <td>${entry.vehicleModel || entry.car || 'N/A'}</td>
                    <td>${formatTime(entry.time || 0)}</td>
                </tr>`;
        });
    } else {
        html = '<tr><td colspan="4" style="text-align:center;">Nenhum tempo registrado ainda</td></tr>';
    }
    setHtml('#scoreboard-tbody', html);
    removeClass('#modal-scoreboard', 'hidden');
}

function displayRanking(data) {
    $$('.modal').forEach(m => m.classList.add('hidden'));
    let html = '';
    if (Array.isArray(data?.ranking) && data.ranking.length) {
        data.ranking.forEach((entry, index) => {
            const winRate = entry.races > 0 ? ((entry.wins / entry.races) * 100).toFixed(1) : '0.0';
            const tierColor = entry.tierColor || '#a855f7';
            const tierName = entry.elo_tier || 'Street';
            const eloPoints = entry.elo_points || 0;
            html += `
                <div class="ranking-entry-card" style="--tier-color:${tierColor};">
                    <div class="ranking-position">#${index + 1}</div>
                    <div class="ranking-tier-badge">${tierName}</div>
                    <div class="ranking-info">
                        <div class="ranking-name">${entry.racername || 'Desconhecido'}</div>
                        <div class="ranking-stat"><span class="ranking-stat-label">ELO</span><span class="ranking-stat-value" style="color:${tierColor};">${eloPoints} PTS</span></div>
                        <div class="ranking-stat"><span class="ranking-stat-label">Corridas</span><span class="ranking-stat-value">${entry.races || 0}</span></div>
                        <div class="ranking-stat"><span class="ranking-stat-label">Vitórias</span><span class="ranking-stat-value">${entry.wins || 0}</span></div>
                        <div class="ranking-stat"><span class="ranking-stat-label">Taxa de Vitória</span><span class="ranking-stat-value">${winRate}%</span></div>
                    </div>
                </div>`;
        });
    } else {
        html = '<div style="grid-column:1/-1;text-align:center;color:rgba(255,255,255,0.5);padding:40px;">Nenhum piloto no ranking</div>';
    }
    setHtml('#ranking-list', html);
    removeClass('#modal-ranking', 'hidden');
}

function displayProfile(data) {
    $$('.modal').forEach(m => m.classList.add('hidden'));
    setText('#profile-name', 'MEU PERFIL');

    const winRate = data?.races > 0 ? ((data.wins / data.races) * 100).toFixed(1) : '0.0';
    const bestTimeFormatted = data?.bestTime > 0 ? formatTime(data.bestTime) : '--:--.---';
    const tierProgress = data?.tierMaxPoints > 0 ? Math.min(100, ((data.pointsInTier / data.tierMaxPoints) * 100)).toFixed(1) : 0;
    const tierColor = data?.tierColor || '#a855f7';
    const racerName = data?.racername || 'Piloto';
    const initials = racerName.split(' ').map(p => p[0]).join('').slice(0, 2).toUpperCase() || 'AR';

    setHtml('#profile-stats', `
        <div class="profile-hero" style="--tier-color:${tierColor};">
            <div class="profile-avatar">${initials}</div>
            <div class="profile-hero-info">
                <span class="profile-kicker">PILOTO ALVES RACING</span>
                <strong>${racerName}</strong>
                <div class="profile-tier-line">
                    <span class="profile-tier-badge" style="border-color:${tierColor}; color:${tierColor};">${data?.eloTier || 'Street'}</span>
                    <span>${data?.eloPoints || 0} PTS</span>
                </div>
            </div>
            <div class="profile-rank-box">
                <span>RANK</span>
                <strong>#${data?.position || 'N/A'}</strong>
            </div>
        </div>

        <div class="profile-progress-card" style="--tier-color:${tierColor};">
            <div class="profile-progress-head">
                <span>PROGRESSO DO TIER</span>
                <strong>${data?.pointsInTier || 0}/${data?.tierMaxPoints || 100}</strong>
            </div>
            <div class="tier-progress-bar"><div class="tier-progress-fill" style="width:${tierProgress}%; background:${tierColor};"></div></div>
            <small>${tierProgress}% para o próximo marco</small>
        </div>

        <div class="profile-metric-card">
            <span class="metric-label">CORRIDAS</span>
            <strong>${data?.races || 0}</strong>
            <small>Total finalizadas</small>
        </div>
        <div class="profile-metric-card">
            <span class="metric-label">VITÓRIAS</span>
            <strong>${data?.wins || 0}</strong>
            <small>${winRate}% win rate</small>
        </div>
        <div class="profile-metric-card">
            <span class="metric-label">MELHOR TEMPO</span>
            <strong>${bestTimeFormatted}</strong>
            <small>Recorde pessoal</small>
        </div>
        <div class="profile-metric-card">
            <span class="metric-label">ELO</span>
            <strong style="color:${tierColor};">${data?.eloPoints || 0}</strong>
            <small>Pontuação atual</small>
        </div>
    `);

    removeClass('#modal-profile', 'hidden');
}
function closeModal() {
    $$('.modal').forEach(m => m.classList.add('hidden'));
}

function formatTime(milliseconds) {
    const ms = Math.max(0, Number(milliseconds) || 0);
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    const millis = ms % 1000;
    return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(millis).padStart(3, '0')}`;
}

document.addEventListener('keydown', function(e) {
    if (e.key === 'F2') {
        e.preventDefault();
        toggleLobby();
        return;
    }

    if (e.key === 'F3') {
        e.preventDefault();
        if (currentLobby) leaveLobby();
        return;
    }

    if (e.key === 'Escape') {
        if (currentLobby && !$('#modal-lobby')?.classList.contains('hidden')) {
            minimizeLobby();
        } else {
            closeModal();
        }
        closeTablet();
        // Não escondemos HUD/countdown aqui para não quebrar corrida em andamento.
    }
});
