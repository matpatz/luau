import { createClient } from "@supabase/supabase-js";

const SHARED = process.env.sSecret;
const SUPABASE_URL = process.env.supabaseurl;
const SUPABASE_SERVICE = process.env.supabaseService;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE);

const BASE_JACKPOT = 1000;
const FAIL_INCREASE = 50;

function generateCode() {

    const nums = [];

    for (let i = 0; i < 5; i++) {
        nums.push(Math.floor(Math.random() * 69) + 1);
    }

    const power = Math.floor(Math.random() * 26) + 1;

    return `${nums.join("-")}|${power}`;
}

async function getUser(username) {

    const { data } = await supabase
        .from("users")
        .select("*")
        .eq("username", username)
        .single();

    if (!data) {

        await supabase.from("users").insert({
            username,
            balance: 0
        });

        return 0;
    }

    return data.balance;
}

async function setBalance(username, balance) {

    await supabase
        .from("users")
        .update({
            balance,
            updated_at: new Date()
        })
        .eq("username", username);
}

export default async function handler(req, res) {

    if (req.method !== "POST") {
        return res.status(405).json({ error: "method not allowed" });
    }

    if (req.headers["x-secret"] !== SHARED) {
        return res.status(401).json({ error: "unauthorized" });
    }

    const { username, code } = req.body;

    if (!username || !code) {
        return res.status(400).json({ error: "invalid request" });
    }

    let { data: state } = await supabase
        .from("powerball")
        .select("*")
        .eq("id", 1)
        .single();

    const now = Date.now();
    const lastUpdate = new Date(state.updated_at).getTime();

    if (now - lastUpdate > 3600000) {

        const newCode = generateCode();

        await supabase
            .from("powerball")
            .update({
                code: newCode,
                jackpot: BASE_JACKPOT,
                updated_at: new Date()
            })
            .eq("id", 1);

        state.code = newCode;
        state.jackpot = BASE_JACKPOT;
    }

    if (code === state.code) {

        const payout = state.jackpot;

        const balance = await getUser(username);
        const newBalance = balance + payout;

        await setBalance(username, newBalance);

        const newCode = generateCode();

        await supabase
            .from("powerball")
            .update({
                code: newCode,
                jackpot: BASE_JACKPOT,
                updated_at: new Date()
            })
            .eq("id", 1);

        return res.json({
            valid: true,
            payout,
            balance: newBalance
        });
    }

    const newJackpot = state.jackpot + FAIL_INCREASE;

    await supabase
        .from("powerball")
        .update({ jackpot: newJackpot })
        .eq("id", 1);

    return res.json({
        valid: false,
        jackpot: newJackpot
    });
}
