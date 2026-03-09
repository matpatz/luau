import { createClient } from "@supabase/supabase-js";

const SHARED = process.env.sSecret;
const SUPABASE_URL = process.env.supabaseurl;
const SUPABASE_SERVICE = process.env.supabaseService;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE);

const BASE_JACKPOT = 1000;
const FAIL_INCREASE = 50;

// generate random Powerball code
function generateCode() {
  const nums = Array.from({ length: 5 }, () => Math.floor(Math.random() * 69) + 1);
  const power = Math.floor(Math.random() * 26) + 1;
  return `${nums.join("-")}|${power}`;
}

async function getUserBalance(username) {
  const { data } = await supabase.from("users").select("*").eq("username", username).single();
  if (!data) {
    await supabase.from("users").insert({ username, balance: 0 });
    return 0;
  }
  return data.balance;
}

async function setUserBalance(username, balance) {
  await supabase.from("users").update({ balance, updated_at: new Date() }).eq("username", username);
}

export default async function handler(req, res) {
  const jsonResponse = (obj, status = 200) =>
    new Response(JSON.stringify(obj), { status, headers: { "Content-Type": "application/json" } });

  if (req.method !== "POST") return jsonResponse({ error: "method not allowed" }, 405);

  if (req.headers["x-secret"] !== SHARED) return jsonResponse({ error: "unauthorized" }, 401);

  let body;
  try {
    body = await req.json();
  } catch (e) {
    return jsonResponse({ error: "invalid JSON" }, 400);
  }

  const { username, guess } = body;
  if (!username || !guess) return jsonResponse({ error: "invalid request" }, 400);

  // get current powerball state
  let { data: state } = await supabase.from("powerball").select("*").eq("id", 1).single();

  // reset every hour
  if (Date.now() - new Date(state.updated_at).getTime() > 3600000) {
    const newCode = generateCode();
    await supabase.from("powerball").update({ code: newCode, jackpot: BASE_JACKPOT, updated_at: new Date() }).eq("id", 1);
    state.code = newCode;
    state.jackpot = BASE_JACKPOT;
  }

  // check guess
  if (guess === state.code) {
    const payout = state.jackpot;
    const balance = await getUserBalance(username);
    const newBalance = balance + payout;

    await setUserBalance(username, newBalance);

    // reset code and jackpot after win
    const newCode = generateCode();
    await supabase.from("powerball").update({ code: newCode, jackpot: BASE_JACKPOT, updated_at: new Date() }).eq("id", 1);

    return jsonResponse({ valid: true, payout, balance: newBalance });
  }

  // wrong guess: increase jackpot
  const newJackpot = state.jackpot + FAIL_INCREASE;
  await supabase.from("powerball").update({ jackpot: newJackpot }).eq("id", 1);

  return jsonResponse({ valid: false, jackpot: newJackpot });
}
