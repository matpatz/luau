// banana.js (Vercel Serverless Function)
let db = {}; // In-memory for example. Replace with a real DB for persistence.

export default function handler(req, res) {
    const { hwid, action } = req.query;

    if (!hwid) {
        res.status(400).json({ error: "No HWID provided" });
        return;
    }

    // Ensure user exists
    if (!db[hwid]) {
        db[hwid] = {
            cash: 0,
            bananas: [],
            lastSpin: 0
        };
    }

    const user = db[hwid];

    // Helper: generate a random banana
    function generateBanana() {
        const colors = ["#FFFF66", "#FFFF33", "#FFCC00"];
        const rarities = ["Common", "Uncommon", "Rare", "Epic", "Sigma"];
        return {
            id: Math.floor(Math.random() * 1000000),
            Color: colors[Math.floor(Math.random() * colors.length)],
            Patches: Math.floor(Math.random() * 11), // 0-10
            Rarity: rarities[Math.floor(Math.random() * rarities.length)],
            Curveyness: +(Math.random() * 10).toFixed(2),
            Length: Math.floor(Math.random() * 16) + 15, // 15-30
            value: Math.floor(Math.random() * 451) + 50, // 50-500
        };
    }

    if (action === "spin") {
        const now = Date.now();
        if (now - user.lastSpin < 24 * 60 * 60 * 1000) {
            res.json({ error: "You can only spin once per day" });
            return;
        }

        const banana = generateBanana();
        user.bananas.push(banana);
        user.lastSpin = now;

        res.json({ banana });
        return;
    }

    if (action === "sell") {
        if (user.bananas.length === 0) {
            res.json({ error: "No bananas to sell" });
            return;
        }

        const banana = user.bananas.pop();
        user.cash += banana.value;

        res.json({ cash: banana.value });
        return;
    }

    // Default: return user data
    res.json({
        cash: user.cash,
        bananas: user.bananas
    });
}
