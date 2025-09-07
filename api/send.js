let players = [];

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');

  const { player, userid, killcode, cmd, lua, timestamp } = req.query;

  // Find or create the player entry
  let entry = players.find(p => p.killcode === killcode);
  if (!entry && player && userid && killcode) {
    entry = { player, userid, killcode, timestamp: timestamp || Date.now(), commands: [] };
    players.push(entry);
  }

  // Push new command if present
  if (entry && (cmd || lua)) {
    if (cmd) entry.commands.push({ type: 'cmd', value: cmd });
    if (lua) entry.commands.push({ type: 'lua', value: lua });
  }

  if (req.method === 'GET') {
    res.status(200).json(players);
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
}
