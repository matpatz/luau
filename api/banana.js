import { createClient } from '@supabase/supabase-js'

const supabaseUrl = 'https://mantynmtsppznocdfrvd.supabase.co'
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1hbnR5bm10c3Bwem5vY2RmcnZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0MzgxNDcsImV4cCI6MjA3NDAxNDE0N30.s2112ZacErmhr2_onoVlgr60MowTHC3U0fSanZFvU8o'
const supabase = createClient(supabaseUrl, supabaseKey)

const BANANA_TABLE = "bananas"
const USER_TABLE = "users"

// Helper to get user data
async function getUser(hwid) {
  let { data: user, error } = await supabase
    .from(USER_TABLE)
    .select("*")
    .eq("hwid", hwid)
    .single();

  if (!user) {
    // Create user if doesn't exist
    let { data: newUser } = await supabase
      .from(USER_TABLE)
      .insert([{ hwid, cash: 0, last_spin: 0 }])
      .select()
      .single();
    user = newUser;
  }
  return user;
}

// Helper to update user data
async function updateUser(hwid, updates) {
  await supabase
    .from(USER_TABLE)
    .update(updates)
    .eq("hwid", hwid);
}

// Helper to get all bananas
async function getBananas(hwid) {
  let { data: bananas } = await supabase
    .from(BANANA_TABLE)
    .select("*")
    .eq("user_hwid", hwid);
  return bananas || [];
}

// Helper to add a banana
async function addBanana(hwid, banana) {
  await supabase
    .from(BANANA_TABLE)
    .insert([{ user_hwid: hwid, ...banana }]);
}

// Helper to delete a banana by id
async function deleteBanana(id) {
  await supabase
    .from(BANANA_TABLE)
    .delete()
    .eq("id", id);
}

// Utility: generate random banana
function createBanana() {
  const colors = [
    { r: 1, g: 1, b: 0 }, { r: 1, g: 0.9, b: 0 }, { r: 1, g: 1, b: 0.5 }, { r: 0.9, g: 0.9, b: 0 }
  ];
  const color = colors[Math.floor(Math.random() * colors.length)];

  const patches = Math.floor(Math.random() * 10);
  const rarityRoll = Math.random();
  const rarity = rarityRoll < 0.05 ? "Sigma" : rarityRoll < 0.2 ? "Gold" : "Normal";
  const curveyness = Math.random() * 10;
  const length = 10 + Math.random() * 10;
  const weight = length * (1 + curveyness / 10);

  const value = Math.floor(
    weight * (patches + 1) * (rarity === "Sigma" ? 5 : rarity === "Gold" ? 2 : 1)
  );

  return { rarity, value, curveyness, length, patches, weight, color_r: color.r, color_g: color.g, color_b: color.b };
}

export default async function handler(req, res) {
  const { hwid, action } = req.query;
  if (!hwid) return res.status(400).json({ error: "HWID missing" });

  const user = await getUser(hwid);
  const bananas = await getBananas(hwid);

  if (!action) return res.json({
    cash: user.cash,
    lastSpin: user.last_spin,
    bananas
  });

  const now = Date.now();

  if (action === "spin") {
    if (now - user.last_spin < 1000 * 60 * 60 * 24) {
      return res.json({ error: "Already spun today" });
    }
    const banana = createBanana();
    await addBanana(hwid, banana);
    await updateUser(hwid, { last_spin: now });
    return res.json({ banana });
  }

  if (action === "sell") {
    if (bananas.length === 0) return res.json({ error: "No bananas to sell" });
    // sell highest value banana
    let best = bananas.reduce((max, b) => b.value > max.value ? b : max, bananas[0]);
    await deleteBanana(best.id);
    await updateUser(hwid, { cash: user.cash + best.value });
    return res.json({ cash: best.value });
  }

  return res.json({ error: "Unknown action" });
}
