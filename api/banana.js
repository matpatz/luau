// server.js
const express = require("express");
const fs = require("fs");
const app = express();
app.use(express.json());

const DATA_FILE = "./userdata.json";

// Load or create data
let userData = {};
if (fs.existsSync(DATA_FILE)) {
    userData = JSON.parse(fs.readFileSync(DATA_FILE, "utf8"));
}

// Utility: save data
function saveData() {
    fs.writeFileSync(DATA_FILE, JSON.stringify(userData, null, 2));
}

// GET user data
app.get("/api/userdata", (req, res) => {
    const userId = req.query.userid;
    if (!userId) return res.status(400).json({error: "No userid"});
    if (!userData[userId]) {
        userData[userId] = {cash:0, bananas:[], lastSpin:0};
        saveData();
    }
    res.json(userData[userId]);
});

// POST save user data
app.post("/api/saveuserdata", (req, res) => {
    const data = req.body;
    if (!data.userid) return res.status(400).json({error: "No userid"});
    userData[data.userid] = {
        cash: data.cash || 0,
        bananas: data.bananas || [],
        lastSpin: data.lastSpin || 0
    };
    saveData();
    res.json({success:true});
});

// START SERVER
app.listen(3000, () => {
    console.log("Server running on port 3000");
});
