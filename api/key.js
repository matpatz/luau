import crypto from "crypto";

/* ================= CONFIG ================= */

const SHARED = process.env.sSecret;
const NONCE_TTL_MS = 60_000;
const seenNonces = new Map();

/* ================= UTILS ================= */

function sha256(s) {
  return crypto.createHash("sha256").update(s).digest("hex");
}

function sign() {
  const parts = Array.from(arguments).map((p) => {
    if (typeof p === "boolean") return p ? "1" : "0";
    if (p === null || p === undefined) return "";
    return String(p);
  });
  return sha256(parts.join("|") + "|" + SHARED);
}

/* ================= HANDLER ================= */

export default async function handler(req, res) {
  res.setHeader("Content-Type", "application/json");

  try {
    if (req.method !== "POST") {
      return res.status(405).json({ ok: false, error: "Method not allowed" });
    }

    if (!SHARED) {
      return res.status(500).json({ ok: false, error: "Server misconfigured" });
    }

    let body = req.body;
    if (typeof body === "string") body = JSON.parse(body);

    if (!body || typeof body !== "object") {
      return res.status(400).json({ ok: false, error: "Bad request" });
    }

    let { key, device, ts, nonce, sig } = body;

    key = String(key || "");
    device = String(device || "");
    nonce = String(nonce || "");
    sig = String(sig || "");
    ts = Number(ts);

    if (!key || !device || !nonce || !sig || !Number.isFinite(ts)) {
      return res.status(400).json({ ok: false, error: "Bad request" });
    }

    const now = Date.now();

    if (Math.abs(now - ts * 1000) > NONCE_TTL_MS) {
      return res.status(401).json({ ok: false, error: "Stale" });
    }

    if (seenNonces.has(nonce)) {
      return res.status(401).json({ ok: false, error: "Replay" });
    }

    seenNonces.set(nonce, now);
    setTimeout(() => seenNonces.delete(nonce), NONCE_TTL_MS);

    const expect = sign(key, device, String(ts), nonce);
    if (sig !== expect) {
      return res.status(401).json({ ok: false, error: "Bad signature" });
    }

    const response = {
      ok: true,
      ts: String(Math.floor(now / 1000)),
      nonce: crypto.randomBytes(16).toString("hex"),
    };

    response.sig = sign(response.ok, response.ts, response.nonce);

    return res.status(200).json(response);
  } catch (e) {
    return res.status(500).json({
      ok: false,
      error: "Server crash",
      detail: String(e.message || e),
    });
  }
}
