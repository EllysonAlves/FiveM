let currentPage = 'home';
let selectedRaceType = 'ranked';
let playerData = {};

// Update time
function updateTime() {
    const now = new Date();
    const hours = String(now.getHours()).padStart(2, '0');
    const minutes = String(now.getMinutes()).padStart(2, '0');
    document.getElementById('current-time').textContent = `${hours}:${minutes}`;
}

setInterval(updateTime, 1000);
updateTime();

// NUI Message Handler
window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'openTablet':
            openTablet(data.data);
            break;
        case 'closeTablet':
            closeTablet();
            break;
        case 'updateScoreboard':
            updateScoreboard(data.data);
            break;
        case 'updateRanking':
            updateRanking(data.data);
            break;
        case 'updateProfile':
            updateProfile(data.data);
            break;
    }
});

// Open Tablet
function openTablet(data) {
    playerData = data || {};
    document.getElementById('tablet').classList.remove('hidden');
    updateHomeStats();
    updateProfileData();
    
    // Request initial data
    $.post('https://cw-racingapp/requestScoreboard');
    $.post('https://cw-racingapp/requestRanking');
}

// Close Tablet
function closeTablet() {
    document.getElementById('tablet').classList.add('hidden');
    $.post('https://cw-racingapp/closeTablet');
}

// Close on ESC
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        closeTablet();
    }
});

// Switch Page
function switchPage(page) {
    // Update nav buttons
    document.querySelectorAll('.nav-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`.nav-btn[data-page="${page}"]`).classList.add('active');

    // Update pages
    document.querySelectorAll('.page').forEach(p => {
        p.classList.remove('active');
    });
    document.getElementById(`page-${page}`).classList.add('active');

    currentPage = page;

    // Load page-specific data
    if (page === 'scoreboard') {
        $.post('https://cw-racingapp/requestScoreboard');
    } else if (page === 'ranking') {
        $.post('https://cw-racingapp/requestRanking');
    }
}

// Update Home Stats
function updateHomeStats() {
    if (!playerData.racerData) return;

    const racerData = playerData.racerData;
    const division = getDivision(racerData.ranking || 0);

    document.getElementById('player-name').textContent = racerData.racername || 'Corredor';
    document.getElementById('home-division').textContent = division.name;
    document.getElementById('home-elo').textContent = racerData.ranking || 0;
    document.getElementById('home-races').textContent = racerData.races || 0;
    document.getElementById('home-wins').textContent = racerData.wins || 0;
}

// Update Profile Data
function updateProfileData() {
    if (!playerData.racerData) return;

    const racerData = playerData.racerData;
    const division = getDivision(racerData.ranking || 0);
    const winrate = racerData.races > 0 ? ((racerData.wins / racerData.races) * 100).toFixed(1) : 0;
    const nextDivision = getNextDivision(racerData.ranking || 0);
    const progress = getEloProgress(racerData.ranking || 0);

    document.getElementById('profile-name').textContent = racerData.racername || 'Corredor';
    document.getElementById('profile-id').textContent = `ID: ${racerData.racerid || 'N/A'}`;
    document.getElementById('profile-division-icon').textContent = division.icon;
    document.getElementById('profile-division').textContent = division.name;
    document.getElementById('profile-elo').textContent = racerData.ranking || 0;
    document.getElementById('profile-next-elo').textContent = nextDivision.minElo;
    document.getElementById('elo-progress').style.width = `${progress}%`;
    document.getElementById('profile-races').textContent = racerData.races || 0;
    document.getElementById('profile-wins').textContent = racerData.wins || 0;
    document.getElementById('profile-winrate').textContent = `${winrate}%`;
    document.getElementById('profile-best-pos').textContent = '-';
}

// Get Division
function getDivision(elo) {
    if (elo >= 3500) return { name: 'Lenda', icon: '⭐' };
    if (elo >= 3000) return { name: 'Mestre', icon: '👑' };
    if (elo >= 2500) return { name: 'Diamante', icon: '💠' };
    if (elo >= 2000) return { name: 'Platina', icon: '💎' };
    if (elo >= 1500) return { name: 'Ouro', icon: '🥇' };
    if (elo >= 1000) return { name: 'Prata', icon: '🥈' };
    return { name: 'Bronze', icon: '🥉' };
}

// Get Next Division
function getNextDivision(elo) {
    if (elo >= 3500) return { name: 'Lenda', minElo: 3500 };
    if (elo >= 3000) return { name: 'Lenda', minElo: 3500 };
    if (elo >= 2500) return { name: 'Mestre', minElo: 3000 };
    if (elo >= 2000) return { name: 'Diamante', minElo: 2500 };
    if (elo >= 1500) return { name: 'Platina', minElo: 2000 };
    if (elo >= 1000) return { name: 'Ouro', minElo: 1500 };
    return { name: 'Prata', minElo: 1000 };
}

// Get ELO Progress
function getEloProgress(elo) {
    let currentMin = 0;
    let currentMax = 1000;

    if (elo >= 3500) {
        return 100;
    } else if (elo >= 3000) {
        currentMin = 3000;
        currentMax = 3500;
    } else if (elo >= 2500) {
        currentMin = 2500;
        currentMax = 3000;
    } else if (elo >= 2000) {
        currentMin = 2000;
        currentMax = 2500;
    } else if (elo >= 1500) {
        currentMin = 1500;
        currentMax = 2000;
    } else if (elo >= 1000) {
        currentMin = 1000;
        currentMax = 1500;
    } else {
        currentMin = 0;
        currentMax = 1000;
    }

    const range = currentMax - currentMin;
    const progress = ((elo - currentMin) / range) * 100;
    return Math.max(0, Math.min(100, progress));
}

// Select Race Type
function selectRaceType(type) {
    selectedRaceType = type;
    document.querySelectorAll('.race-type-btn').forEach(btn => {
        btn.classList.remove('active');
    });
    document.querySelector(`.race-type-btn[data-type="${type}"]`).classList.add('active');
}

// Start Quick Race
function startQuickRace(type) {
    selectedRaceType = type || selectedRaceType;
    $.post('https://cw-racingapp/startQuickRace', JSON.stringify({
        raceType: selectedRaceType
    }));
    closeTablet();
}

// Confirm Start Race
function confirmStartRace() {
    $.post('https://cw-racingapp/startQuickRace', JSON.stringify({
        raceType: selectedRaceType
    }));
    closeTablet();
}

// Update Scoreboard
function updateScoreboard(data) {
    const scoreboardList = document.getElementById('scoreboard-list');
    scoreboardList.innerHTML = '';

    if (!data || data.length === 0) {
        scoreboardList.innerHTML = '<div class="loading">Nenhuma corrida encontrada</div>';
        return;
    }

    data.forEach(race => {
        const date = new Date(race.timestamp);
        const formattedDate = `${date.toLocaleDateString()} ${date.toLocaleTimeString()}`;
        
        const item = document.createElement('div');
        item.className = 'scoreboard-item';
        item.innerHTML = `
            <div class="scoreboard-header">
                <span class="race-name">${race.raceName || 'Corrida'}</span>
                <span class="race-date">${formattedDate}</span>
            </div>
            <div class="scoreboard-details">
                <span>🏆 Vencedor: ${race.winner || 'N/A'}</span>
                <span>👥 Participantes: ${race.amountOfRacers || 0}</span>
                <span>🔄 Voltas: ${race.laps || 'Sprint'}</span>
                <span>⏱️ Melhor: ${race.bestTime || 'N/A'}</span>
            </div>
        `;
        scoreboardList.appendChild(item);
    });
}

// Update Ranking
function updateRanking(data) {
    const rankingList = document.getElementById('ranking-list');
    rankingList.innerHTML = '';

    if (!data || data.length === 0) {
        rankingList.innerHTML = '<div class="loading">Nenhum corredor encontrado</div>';
        return;
    }

    data.forEach((racer, index) => {
        const position = index + 1;
        const winrate = racer.races > 0 ? ((racer.wins / racer.races) * 100).toFixed(1) : 0;
        let positionClass = '';
        
        if (position === 1) positionClass = 'top1';
        else if (position === 2) positionClass = 'top2';
        else if (position === 3) positionClass = 'top3';

        const item = document.createElement('div');
        item.className = 'ranking-item';
        item.innerHTML = `
            <div class="ranking-position ${positionClass}">${position}</div>
            <div class="ranking-info">
                <div class="ranking-name">${racer.racername}</div>
                <div class="ranking-stats">
                    <span>🏁 ${racer.races || 0} corridas</span>
                    <span>🥇 ${racer.wins || 0} vitórias</span>
                    <span>📊 ${winrate}%</span>
                </div>
            </div>
            <div class="ranking-elo">${racer.ranking || 0}</div>
        `;
        rankingList.appendChild(item);
    });
}

// Update Profile
function updateProfile(data) {
    playerData.racerData = data;
    updateProfileData();
    updateHomeStats();
}
