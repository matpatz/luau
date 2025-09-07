let players = [];

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');

  try {
    if (req.method === 'POST') {
      const { player, userid, killcode, timestamp } = req.body;

      if (!player || !userid || !killcode) {
        res.status(400).json({ error: 'Missing required fields' });
        return;
      }

      const entry = {
        player,
        userid,
        killcode,
        timestamp: timestamp || Date.now()
      };

      const i = players.findIndex(p => p.killcode === killcode);
      if (i >= 0) players[i] = entry;
      else players.push(entry);

      res.status(200).json({ success: true, players });
      return;
    }

    if (req.method === 'GET') {
      res.status(200).json(players);
      return;
    }

    res.status(405).json({ error: 'Method not allowed' });
  } catch (e) {
    console.error('Send.js error:', e);
    res.status(500).json({ error: e.message });
  }
}
