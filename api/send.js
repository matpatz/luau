async function updatePlayerList() {
    playerList.innerHTML = '<div class="player-item">Loading...</div>';
    try {
        const res = await fetch(API_URL);
        let players = await res.json();

        // Ensure players is always an array
        if (!Array.isArray(players)) {
            // wrap single object into array
            if (typeof players === 'object' && players !== null) players = [players];
            else throw new Error("Invalid player data from server");
        }

        playerList.innerHTML = '';
        if (players.length === 0) {
            playerList.innerHTML = '<div class="player-item">No players connected</div>';
            return;
        }

        players.forEach(player => {
            const item = document.createElement('div');
            item.className = 'player-item';
            item.innerHTML = `
                <div class="player-info">
                    <span class="player-name">${player.player}</span>
                    <span class="player-id">ID: ${player.userid}</span>
                </div>
                <span class="player-killcode">${player.killcode}</span>
            `;
            item.addEventListener('click', () => {
                selectedPlayer = player;
                killcodeInput.value = player.killcode;
                addLogEntry(`Selected player: ${player.player} (${player.killcode})`, 'success');
            });
            playerList.appendChild(item);
        });

    } catch(e) {
        playerList.innerHTML = '<div class="player-item">Error loading players</div>';
        addLogEntry('Failed to fetch players: ' + e.message, 'error');
    }
}
