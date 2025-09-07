// /api/send.js
let messages = [];

export default function handler(req, res) {
  // CORS for browser dashboard
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(200).end();
    return;
  }

  if (req.method === 'POST') {
    try {
      const body = req.body || {};
      const entry = {
        player: body.player || 'unknown',
        userid: body.userid || 0,
        killcode: body.killcode || 'none',
        timestamp: body.timestamp || Date.now()
      };

      // replace existing by killcode or push
      const idx = messages.findIndex(m => m.killcode === entry.killcode);
      if (idx >= 0) messages[idx] = entry;
      else messages.push(entry);

      res.status(200).json({ success: true, stored: entry, count: messages.length });
    } catch (err) {
      res.status(400).json({ success: false, error: err.message });
    }
    return;
  }

  if (req.method === 'GET') {
    res.status(200).json(messages);
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
}
