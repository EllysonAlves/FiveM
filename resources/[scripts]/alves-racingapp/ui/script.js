// Alves Racing - UI Script

let raceStartTime = 0;
let timerInterval = null;
let countdownInterval = null;

window.addEventListener('message', function(event) {
    const data = event.data || {};
    switch (data.action) {
        case 'openTablet': openTablet(data.data); break;
        case 'closeTablet': closeTablet(); break;
        case 'startCountdown': startCountdown(data.seconds); break;
        case 'updateRaceHUD': updateRaceHUD(data.data || {}); break;
        case 'showRaceHUD': showRaceHUD(); break;
        case 'hideRaceHUD': hideRaceHUD(); break;
        case 'hideCountdown': hideCountdown(); break;
        case 'updateProfile': updateProfile(data.data || {}); break;
        case 'showScoreboard': displayScoreboard(data.data || {}); break;
        case 'showRanking': displayRanking(data.data || {}); break;
        case 'showProfile': displayProfile(data.data || {}); break;
    }
});

function openTablet(data) {
    $('#tablet').removeClass('hidden');
    const player = data?.player || {};

    $('#player-id').text(player.id || '0000');
    $('#player-name').text(player.name || 'Piloto');
    $('#player-level').text(player.level || '1');

    const elo = player.elo || 0;
    const level = player.level || 1;
    $('#level-progress').text(`${elo} / ${level * 50} XP`);
    $('#level-fill').css('width', `${player.levelProgress || 0}%`);

    const stats = player.stats || {};
    $('#stats-races').text(stats.races || '0');
    $('#stats-wins').text(stats.wins || '0');

    const totalSeconds = stats.totalTime || 0;
    $('#stats-time').text(`${Math.floor(totalSeconds / 3600)}h ${Math.floor((totalSeconds % 3600) / 60)}m`);

    if (stats.bestLap && stats.bestLap > 0) {
        $('#stats-best').text(formatTime(stats.bestLap));
    } else {
        $('#stats-best').text('--:--.---');
    }

    $('#online-players').text(data?.onlineCount ?? '0');
}

function closeTablet() {
    $('#tablet').addClass('hidden');
    $.post('https://alves-racingapp/closeTablet');
}

function startRace(type) {
    $.post('https://alves-racingapp/startRace', JSON.stringify({ raceType: type }));
    closeTablet();
}

function showScoreboard() {
    $.post('https://alves-racingapp/showScoreboard');
}

function showRanking() {
    $('.menu-item').removeClass('active');
    $('.menu-item').has('span:contains("RANKING")').addClass('active');
    $.post('https://alves-racingapp/showRanking');
}

function showProfile() {
    $.post('https://alves-racingapp/showProfile');
}

function showRaceHUD() {
    $('#race-hud').removeClass('hidden');
    raceStartTime = Date.now();
    startTimer();
}

function hideRaceHUD() {
    $('#race-hud').addClass('hidden');
    stopTimer();
}

function hideCountdown() {
    $('#countdown').addClass('hidden');

    if (countdownInterval) {
        clearInterval(countdownInterval);
        countdownInterval = null;
    }
}

function startCountdown(seconds) {
    hideCountdown();

    const countdown = $('#countdown');
    const countdownNumber = $('#countdown-number');

    countdown.removeClass('hidden');

    let current = Number(seconds) || 0;
    countdownNumber.text(current > 0 ? current : 'GO!');

    if (countdownInterval) clearInterval(countdownInterval);

    countdownInterval = setInterval(() => {
        current -= 1;

        if (current <= 0) {
            countdownNumber.text('GO!');

            setTimeout(() => {
                hideCountdown();
                showRaceHUD();
            }, 800);

            clearInterval(countdownInterval);
            countdownInterval = null;
        } else {
            countdownNumber.text(current);
        }
    }, 1000);
}

function updateRaceHUD(data) {
    const d = data || {};

    if (d.position !== undefined) {
        $('#race-position').html(
            d.totalRacers !== undefined
                ? `${d.position}º <span class="stat-total">/ ${d.totalRacers}</span>`
                : `${d.position}º`
        );
    }

    if (d.lap !== undefined) {
        $('#race-lap').html(
            d.totalLaps !== undefined
                ? `${d.lap} <span class="stat-total">/ ${d.totalLaps}</span>`
                : `${d.lap}`
        );
    }

    if (d.checkpoint !== undefined) {
        $('#race-checkpoint').html(
            d.totalCheckpoints !== undefined
                ? `${d.checkpoint} <span class="stat-total">/ ${d.totalCheckpoints}</span>`
                : `${d.checkpoint}`
        );
    }

    if (d.bestLap !== undefined) {
        $('#race-best-lap').text(d.bestLap === 0 ? '--:--.---' : formatTime(d.bestLap));
    }

    if (d.time !== undefined) {
        $('#race-time').text(formatTime(d.time));
    }
}

function startTimer() {
    stopTimer();

    timerInterval = setInterval(() => {
        const elapsed = Date.now() - raceStartTime;
        $('#race-time').text(formatTime(elapsed));
    }, 100);
}

function stopTimer() {
    if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
    }
}

function updateProfile(data) {
    if (data?.elo !== undefined) {
        $('#profile-elo').text(`ELO: ${data.elo}`);
    }
}

function displayScoreboard(data) {
    $('.modal').addClass('hidden');
    $('#scoreboard-title').text(`SCOREBOARD - ${data?.trackName || 'CORRIDA'}`);

    let html = '';

    if (Array.isArray(data?.times) && data.times.length) {
        data.times.forEach((entry, index) => {
            html += `
                <tr>
                    <td>${index + 1}</td>
                    <td>${entry.racerName || entry.racer || 'Desconhecido'}</td>
                    <td>${entry.vehicleModel || entry.car || 'N/A'}</td>
                    <td>${formatTime(entry.time || 0)}</td>
                </tr>
            `;
        });
    } else {
        html = '<tr><td colspan="4" style="text-align:center;">Nenhum tempo registrado ainda</td></tr>';
    }

    $('#scoreboard-tbody').html(html);
    $('#modal-scoreboard').removeClass('hidden');
}

function displayRanking(data) {
    $('.modal').addClass('hidden');
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
                        <div class="ranking-stat">
                            <span class="ranking-stat-label">ELO</span>
                            <span class="ranking-stat-value" style="color:${tierColor};">${eloPoints} PTS</span>
                        </div>
                        <div class="ranking-stat">
                            <span class="ranking-stat-label">Corridas</span>
                            <span class="ranking-stat-value">${entry.races || 0}</span>
                        </div>
                        <div class="ranking-stat">
                            <span class="ranking-stat-label">Vitórias</span>
                            <span class="ranking-stat-value">${entry.wins || 0}</span>
                        </div>
                        <div class="ranking-stat">
                            <span class="ranking-stat-label">Taxa de Vitória</span>
                            <span class="ranking-stat-value">${winRate}%</span>
                        </div>
                    </div>
                </div>
            `;
        });
    } else {
        html = '<div style="grid-column:1/-1;text-align:center;color:rgba(255,255,255,0.5);padding:40px;">Nenhum piloto no ranking</div>';
    }

    $('#ranking-list').html(html);
    $('#modal-ranking').removeClass('hidden');
}

function displayProfile(data) {
    $('.modal').addClass('hidden');
    $('#profile-name').text(`PERFIL - ${data?.racername || 'PILOTO'}`);

    const winRate = data?.races > 0 ? ((data.wins / data.races) * 100).toFixed(1) : '0.0';
    const bestTimeFormatted = data?.bestTime > 0 ? formatTime(data.bestTime) : 'N/A';
    const tierProgress = data?.tierMaxPoints > 0 ? ((data.pointsInTier / data.tierMaxPoints) * 100).toFixed(1) : 0;
    const tierColor = data?.tierColor || '#a855f7';

    $('#profile-stats').html(`
        <div class="tier-card" style="grid-column:1/-1; background: linear-gradient(135deg, ${tierColor}20 0%, ${tierColor}10 100%); border-left-color:${tierColor};">
            <div class="tier-header">
                <div>
                    <span class="tier-label">TIER ATUAL</span>
                    <span class="tier-name" style="color:${tierColor};">${data?.eloTier || 'Street'}</span>
                </div>
                <span class="tier-points" style="color:${tierColor};">${data?.eloPoints || 0} PTS</span>
            </div>
            <div class="tier-progress-container">
                <div class="tier-progress-bar">
                    <div class="tier-progress-fill" style="width:${tierProgress}%; background:${tierColor};"></div>
                </div>
                <span class="tier-progress-text">${data?.pointsInTier || 0}/${data?.tierMaxPoints || 100} pontos para próximo tier</span>
            </div>
        </div>

        <div class="stat-row">
            <span class="stat-label">NOME DO PILOTO</span>
            <span class="stat-value">${data?.racername || 'Desconhecido'}</span>
        </div>

        <div class="stat-row">
            <span class="stat-label">POSIÇÃO NO RANKING</span>
            <span class="stat-value">#${data?.position || 'N/A'}</span>
        </div>

        <div class="stat-row">
            <span class="stat-label">CORRIDAS</span>
            <span class="stat-value">${data?.races || 0}</span>
        </div>

        <div class="stat-row">
            <span class="stat-label">VITÓRIAS</span>
            <span class="stat-value">${data?.wins || 0}</span>
        </div>

        <div class="stat-row">
            <span class="stat-label">TAXA DE VITÓRIA</span>
            <span class="stat-value">${winRate}%</span>
        </div>

        <div class="stat-row">
            <span class="stat-label">MELHOR TEMPO</span>
            <span class="stat-value">${bestTimeFormatted}</span>
        </div>
    `);

    $('#modal-profile').removeClass('hidden');
}

function closeModal() {
    $('.modal').addClass('hidden');
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
    if (e.key === 'Escape') {
        closeModal();
        closeTablet();
        hideCountdown();
        hideRaceHUD();
    }
});
