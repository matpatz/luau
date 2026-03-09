import crypto from "crypto";
import { createClient } from "@supabase/supabase-js";

const SHARED = process.env.sSecret;
const SUPABASE_URL = process.env.supabaseurl;
const SUPABASE_SERVICE = process.env.supabaseService;

const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE);

const BASE_JACKPOT = 1000;
const INCREASE_PER_FAIL = 50;

function generateCode() {
    const nums = [];

    for (let i = 0; i < 5; i++) {
        nums.push(Math.floor(Math.random() * 69) + 1);
    }

    const powerball = Math.floor(Math.random() * 26) + 1;

    return `${nums.join("-")}|${powerball}`;
}

async function getState() {
    const { data } = await supabase
        .from("powerball")
        .select("*")
        .eq("id", 1)
        .single();

    return data;
}

async function setState(code, jackpot) {
    await supabase
        .from("powerball")
        .update({
            code,
            jackpot,
            updated_at: new Date()
        })
        .eq("id", 1);
}

export default async function handler(req, res) {

    if (req.method !== "POST") {
        return res.status(405).json({ error: "method not allowed" });
    }

    if (req.headers["x-secret"] !== SHARED) {
        return res.status(401).json({ error: "unauthorized" });
    }

    const { code } = req.body;

    if (!code || typeof code !== "string") {
        return res.status(400).json({ error: "invalid code" });
    }

    let state = await getState();

    const now = Date.now();
    const updated = new Date(state.updated_at).getTime();

    if (now - updated > 3600000) {
        const newCode = generateCode();

        await setState(newCode, BASE_JACKPOT);

        state = {
            code: newCode,
            jackpot: BASE_JACKPOT
        };
    }

    if (code === state.code) {

        const payout = state.jackpot;

        const newCode = generateCode();

        await setState(newCode, BASE_JACKPOT);

        return res.json({
            valid: true,
            payout
        });
    }

    const newJackpot = state.jackpot + INCREASE_PER_FAIL;

    await supabase
        .from("powerball")
        .update({ jackpot: newJackpot })
        .eq("id", 1);

    return res.json({
        valid: false,
        jackpot: newJackpot
    });
}
