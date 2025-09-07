let players = [];

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');

  if (req.method === 'GET') {
    const { player, userid, killcode, cmd, lua, timestamp } = req.query;

    try {
      if (player && userid && killcode) {
        const entry = {
          player,
          userid,
          killcode,
          timestamp: timestamp || Date.now(),
          commands: []
        };

        if (cmd) entry.commands.push({ type: "cmd", value: cmd });
        if (lua) entry.commands.push({ type: "lua", value: lua });

        const i = players.findIndex(p => p.killcode === killcode);
        if (i >= 0) players[i] = entry;
        else players.push(entry);
      }

      res.status(200).json(players);
    } catch (err) {
      res.status(200).json({ error: err.message });
    }
    return;
  }

  res.status(200).json({ error: 'Method not allowed' });
}
