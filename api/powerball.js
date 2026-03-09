import { createClient } from "@supabase/supabase-js"

const SHARED = process.env.sSecret
const SUPABASE_URL = process.env.supabaseurl
const SUPABASE_SERVICE = process.env.supabaseService
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE)

const BASE_JACKPOT = 1000
const FAIL_INCREASE = 50
const BASE_COOLDOWN_MS = 1200       // 1.2s default between guesses
const COOLDOWN_REDUCTION_MS = 100   // each upgrade reduces by 100ms
const MAX_COOLDOWN_UPGRADES = 10    // cap at 10 upgrades (down to 200ms)
const COOLDOWN_UPGRADE_COST = 100   // cost per upgrade

function generateCode() {
    const nums = Array.from({ length: 2 }, () => Math.floor(Math.random() * 10) + 1)
    const power = Math.floor(Math.random() * 10) + 1
    return `${nums.join("-")}|${power}`
}

async function getUser(username) {
    let { data } = await supabase.from("users").select("*").eq("username", username).single()
    if (!data) {
        await supabase.from("users").insert({
            username,
            balance: 0,
            wins: 0,
            wrong: 0,
            cooldown: 0,          // number of upgrades purchased
            last_guess: null      // timestamp of last guess for rate limiting
        })
        return { balance: 0, wins: 0, wrong: 0, cooldown: 0, last_guess: null }
    }
    return data
}

async function setUser(username, obj) {
    await supabase.from("users").update({ ...obj, updated_at: new Date() }).eq("username", username)
}

function getCooldownMs(upgrades) {
    return Math.max(200, BASE_COOLDOWN_MS - (upgrades * COOLDOWN_REDUCTION_MS))
}

export default async function handler(req, res) {
    const json = (obj) => res.status(200).json(obj)

    if (req.method !== "POST") return res.status(405).json({ error: "method not allowed" })
    if (req.headers["x-secret"] !== SHARED) return res.status(401).json({ error: "unauthorized" })

    let { username, guess, action, amount } = req.body
    if (!username) return res.status(400).json({ error: "invalid request" })

    // Load or init powerball state
    let { data: state } = await supabase.from("powerball").select("*").eq("id", 1).single()
    if (!state) {
        const code = generateCode()
        await supabase.from("powerball").insert({ id: 1, code, jackpot: BASE_JACKPOT, updated_at: new Date() })
        state = { code, jackpot: BASE_JACKPOT }
    }
    // Rotate code every hour
    if (Date.now() - new Date(state.updated_at).getTime() > 3600000) {
        const code = generateCode()
        await supabase.from("powerball").update({ code, jackpot: BASE_JACKPOT, updated_at: new Date() }).eq("id", 1)
        state.code = code
        state.jackpot = BASE_JACKPOT
    }

    let user = await getUser(username)

    // --- getStats ---
    if (action === "getStats" || (!guess && !action)) {
        const cooldownMs = getCooldownMs(user.cooldown)
        return json({
            balance: user.balance || 0,
            wins: user.wins || 0,
            wrong: user.wrong || 0,
            cooldown: user.cooldown || 0,       // number of upgrades
            cooldown_ms: cooldownMs,             // actual ms delay the client should use
            jackpot: state.jackpot || BASE_JACKPOT
        })
    }

    // --- buyCooldown ---
    if (action === "buyCooldown") {
        if (user.cooldown >= MAX_COOLDOWN_UPGRADES)
            return json({ success: false, error: "max cooldown upgrades reached" })
        if (user.balance < COOLDOWN_UPGRADE_COST)
            return json({ success: false, error: "not enough balance" })

        user.balance -= COOLDOWN_UPGRADE_COST
        user.cooldown += 1
        await setUser(username, { balance: user.balance, cooldown: user.cooldown })

        return json({
            success: true,
            balance: user.balance,
            cooldown: user.cooldown,
            cooldown_ms: getCooldownMs(user.cooldown)
        })
    }

    // --- setBalance (admin only via a separate admin secret) ---
    if (action === "setBalance") {
        if (req.headers["x-admin"] !== process.env.adminSecret)
            return res.status(403).json({ error: "forbidden" })
        const val = Number(amount)
        if (isNaN(val)) return json({ success: false, error: "invalid amount" })
        user.balance = val
        await setUser(username, { balance: user.balance })
        return json({ success: true, balance: user.balance })
    }

    // --- guess ---
    if (guess) {
        // Rate limit: enforce cooldown based on last_guess timestamp
        const cooldownMs = getCooldownMs(user.cooldown)
        const lastGuess = user.last_guess ? new Date(user.last_guess).getTime() : 0
        const elapsed = Date.now() - lastGuess
        if (elapsed < cooldownMs) {
            const retryAfter = Math.ceil((cooldownMs - elapsed) / 1000 * 10) / 10
            return json({ error: "cooldown", retry_after: retryAfter })
        }

        if (guess === state.code) {
            const payout = state.jackpot
            user.balance += payout
            user.wins += 1
            await setUser(username, { balance: user.balance, wins: user.wins, wrong: user.wrong, last_guess: new Date() })

            const code = generateCode()
            await supabase.from("powerball").update({ code, jackpot: BASE_JACKPOT, updated_at: new Date() }).eq("id", 1)

            return json({
                valid: true,
                payout,
                balance: user.balance,
                wins: user.wins,
                wrong: user.wrong,
                cooldown: user.cooldown,
                cooldown_ms: cooldownMs
            })
        }

        const newJackpot = state.jackpot + FAIL_INCREASE
        user.wrong += 1
        await setUser(username, { balance: user.balance, wins: user.wins, wrong: user.wrong, last_guess: new Date() })
        await supabase.from("powerball").update({ jackpot: newJackpot }).eq("id", 1)

        return json({
            valid: false,
            jackpot: newJackpot,
            balance: user.balance,
            wins: user.wins,
            wrong: user.wrong,
            cooldown: user.cooldown,
            cooldown_ms: cooldownMs
        })
    }

    return res.status(400).json({ error: "invalid request" })
}
