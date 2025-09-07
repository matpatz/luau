// /api/send.js
let players = [];

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');

  if (req.method === 'GET') {
    const { player, userid, killcode, timestamp, commands } = req.query;

    if (player && userid && killcode) {
      let entry = players.find(p => p.killcode === killcode);
      if (!entry) {
        entry = { player, userid, killcode, timestamp: Date.now(), inbox: [] };
        players.push(entry);
      } else {
        entry.player = player;
        entry.userid = userid;
        entry.timestamp = timestamp || Date.now();
      }

      if (commands) {
        try {
          const cmds = JSON.parse(commands);
          entry.inbox.push(...cmds);
        } catch (e) {
          console.error("Invalid commands JSON:", e);
        }
      }

      // return & clear inbox (deliver once)
      const outbox = [...entry.inbox];
      entry.inbox = [];
      res.status(200).json(outbox);
      return;
    }

    res.status(200).json([]);
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
}
