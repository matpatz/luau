// api/banana.js
import fs from 'fs';
import path from 'path';

const DATA_FILE = path.join(process.cwd(), 'banana_data.json');

// Load existing data
function loadData() {
    if (!fs.existsSync(DATA_FILE)) return {};
    return JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
}

// Save data
function saveData(data) {
    fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

// Generate random banana stats
function generateBanana() {
    return {
        id: Math.floor(Math.random() * 1000000),
        length: (Math.random() * 30).toFixed(2),   // cm
        ripeness: Math.floor(Math.random() * 101), // 0-100
        value: Math.floor(Math.random() * 1000)    // cash value
    };
}

export default function handler(req, res) {
    const hwid = req.query.hwid;
    if (!hwid) return res.status(400).json({error: "No HWID provided"});

    let data = loadData();
    if (!data[hwid]) {
        data[hwid] = { spins: 0, cash: 0, bananas: [] };
    }

    const user = data[hwid];

    if (req.method === 'GET') {
        // Return user data
        return res.json(user);
    }

    if (req.method === 'POST') {
        const action = req.query.action;

        if (action === 'spin') {
            const today = new Date().toDateString();
            if (user.lastSpin === today) {
                return res.json({ error: "Already spun today!" });
            }

            const banana = generateBanana();
            user.bananas.push(banana);
            user.lastSpin = today;
            saveData(data);
            return res.json({ message: "You got a banana!", banana });
        }

        if (action === 'sell') {
            if (!user.bananas.length) return res.json({ error: "No bananas to sell" });
            const banana = user.bananas.pop();
            user.cash += banana.value;
            saveData(data);
            return res.json({ message: `Sold banana for ${banana.value} cash`, cash: user.cash });
        }

        return res.status(400).json({ error: "Invalid action" });
    }

    return res.status(405).json({ error: "Method not allowed" });
}
