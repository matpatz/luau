// /api/banana.js
import fs from "fs";
import path from "path";

const DB_PATH = path.resolve("./banana_db.json");

// Load or create DB
function loadDB() {
  if (!fs.existsSync(DB_PATH)) fs.writeFileSync(DB_PATH, JSON.stringify({}));
  return JSON.parse(fs.readFileSync(DB_PATH, "utf8"));
}

function saveDB(db) {
  fs.writeFileSync(DB_PATH, JSON.stringify(db, null, 2));
}

// Utility: generate random banana
function createBanana() {
  const colors = [
    {r: 1,g:1,b:0}, {r:1,g:0.9,b:0}, {r:1,g:1,b:0.5}, {r:0.9,g:0.9,b:0}
  ];
  const color = colors[Math.floor(Math.random() * colors.length)];

  const patches = Math.floor(Math.random() * 10);
  const rarityRoll = Math.random();
  const rarity = rarityRoll < 0.05 ? "Sigma" : rarityRoll < 0.2 ? "Gold" : "Normal";
  const curveyness = Math.random() * 10;
  const length = 10 + Math.random() * 10;
  const weight = length * (1 + curveyness/10);

  const value = Math.floor(
    weight * (patches+1) * (rarity==="Sigma"?5:rarity==="Gold"?2:1)
  );

  return {Color: color, Patches: patches, Rarity: rarity, Curveyness: curveyness, Length: length, Weight: weight, value};
}

export default function handler(req, res) {
  const { hwid, action } = req.query;
  if (!hwid) return res.status(400).json({error:"HWID missing"});

  const db = loadDB();
  if (!db[hwid]) db[hwid] = {bananas:[], cash:0, lastSpin:0};

  const user = db[hwid];

  if (!action) return res.json(user);

  const now = Date.now();

  if (action === "spin") {
    // once per 24h
    if (now - user.lastSpin < 1000*60*60*24) {
      return res.json({error:"Already spun today"});
    }
    const banana = createBanana();
    user.bananas.push(banana);
    user.lastSpin = now;
    saveDB(db);
    return res.json({banana});
  }

  if (action === "sell") {
    if (user.bananas.length === 0) return res.json({error:"No bananas to sell"});
    // sell highest value banana
    let maxIndex = 0;
    let maxValue = 0;
    user.bananas.forEach((b,i)=>{if(b.value>maxValue){maxValue=b.value; maxIndex=i}});
    const banana = user.bananas.splice(maxIndex,1)[0];
    user.cash += banana.value;
    saveDB(db);
    return res.json({cash:banana.value});
  }

  return res.json({error:"Unknown action"});
}
