let players = [];

export default function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*'); // allow your HTML to fetch
    res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

    if (req.method === 'OPTIONS') {
        res.status(200).end();
        return;
    }

    if (req.method === 'POST') {
        // Store incoming player info
        try {
            const player = req.body;
            // Check for existing player by killcode
            const index = players.findIndex(p => p.killcode === player.killcode);
            if (index !== -1) players[index] = player;
            else players.push(player);

            res.status(200).json({ status: 'ok', players: players.length });
        } catch (err) {
            res.status(400).json({ status: 'error', message: err.message });
        }
    } else if (req.method === 'GET') {
        // Return list of connected players
        res.status(200).json(players);
    } else {
        res.status(405).json({ error: 'Method not allowed' });
    }
}
