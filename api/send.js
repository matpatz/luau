// /api/send.js
let players = [];

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');

  if (req.method === 'GET') {
    const { player, userid, killcode, timestamp } = req.query;

    if (player && userid && killcode) {
      const entry = {
        player,
        userid,
        killcode,
        timestamp: timestamp || Date.now()
      };

      const i = players.findIndex(p => p.killcode === killcode);
      if (i >= 0) players[i] = entry;
      else players.push(entry);
    }

    res.status(200).json(players);
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
}
