import crypto from "crypto";

/* ===== CONFIG ===== */
const SHARED = process.env.sSecret;
const SUPABASE_URL = process.env.supabaseurl;
const SUPABASE_SERVICE = process.env.supabaseService;

/* ===== UTILS ===== */
function sha256(s) {
  return crypto.createHash("sha256").update(s).digest("hex");
}

function sign(...args) {
  const parts = Array.from(args).map(v => {
    if (typeof v === "boolean") return v ? "1" : "0";
    if (v === null || v === undefined) return "";
    return String(v);
  });
  return sha256(parts.join("|") + "|" + SHARED);
}

/* ===== HANDLER ===== */
export default async function handler(req, res) {
  res.setHeader("Content-Type", "application/json");

  try {
    if (req.method !== "POST") return res.status(405).json({ ok: false });

    if (!SHARED || !SUPABASE_URL || !SUPABASE_SERVICE)
      return res.status(500).json({ ok: false });

    let body = req.body;
    if (typeof body === "string") body = JSON.parse(body);

    const key = String(body?.key || "");
    const sig = String(body?.sig || "");

    if (!key || !sig) return res.status(400).json({ ok: false });

    /* ===== VERIFY REQUEST SIGNATURE ===== */
    if (sig !== sign(key)) return res.status(401).json({ ok: false });

    /* ===== SUPABASE LOOKUP ===== */
    const url = `${SUPABASE_URL}/rest/v1/keys?select=key&key=eq.${encodeURIComponent(key)}&limit=1`;
    const r = await fetch(url, {
      headers: {
        apikey: SUPABASE_SERVICE,
        Authorization: `Bearer ${SUPABASE_SERVICE}`,
      },
    });

    if (!r.ok) return res.status(500).json({ ok: false });

    const rows = await r.json();
    const ok = Array.isArray(rows) && rows.length > 0;

    /* ===== SIGN RESPONSE ===== */
    const response = { ok };
    response.sig = sign(ok);

    return res.status(200).json(response);

  } catch (e) {
    console.error("Key handler crashed:", e);
    return res.status(500).json({ ok: false });
  }
}
