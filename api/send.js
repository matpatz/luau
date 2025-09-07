// /api/send.js
let players = [];

export default function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");
  res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.setHeader("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(200).end();
  }

  if (req.method === "GET") {
    const { player, userid, killcode, timestamp } = req.query;

    if (player && userid && killcode) {
      const entry = {
        player,
        userid,
        killcode,
        timestamp: timestamp || Date.now(),
        commands: [],
      };

      const i = players.findIndex((p) => p.killcode === killcode);
      if (i >= 0) {
        // keep existing commands if any
        entry.commands = players[i].commands || [];
        players[i] = entry;
      } else {
        players.push(entry);
      }
    }

    // snapshot for response
    const snapshot = players.map((p) => ({
      player: p.player,
      userid: p.userid,
      killcode: p.killcode,
      timestamp: p.timestamp,
      commands: p.commands,
    }));

    // clear commands after sending them out
    players.forEach((p) => (p.commands = []));

    res.status(200).json(snapshot);
    return;
  }

  if (req.method === "POST") {
    try {
      const { killcode, type, value } = req.body;
      const i = players.findIndex((p) => p.killcode === killcode);
      if (i >= 0) {
        if (!players[i].commands) players[i].commands = [];
        players[i].commands.push({ type, value });
        res.status(200).json({ ok: true });
      } else {
        res.status(404).json({ error: "Player not found" });
      }
    } catch (e) {
      res.status(400).json({ error: "Invalid body" });
    }
    return;
  }

  res.status(405).json({ error: "Method not allowed" });
}
