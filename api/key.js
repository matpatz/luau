// /api/checkkey.js
let db = {} // In-memory example, replace with proper DB

export default function handler(req, res) {
    const { hwid, key } = req.query;
    if (!hwid || !key) return res.status(400).send("INVALID");

    // Example: store key if not exists
    if (!db[hwid]) {
        db[hwid] = key;
        return res.status(200).send("VALID");
    }

    // Check if key matches
    if (db[hwid] === key) return res.status(200).send("VALID");

    return res.status(200).send("INVALID");
}
