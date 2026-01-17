import crypto from "crypto";

const SHARED = process.env.sSecret;
const NONCE_TTL_MS = 60_000;

const seenNonces = new Map();

function sha256(s) {
  return crypto.createHash("sha256").update(s).digest("hex");
}

function sign(...parts) {
  return sha256(parts.join("|") + "|" + SHARED);
}

function now() {
  return Date.now();
}

export default async function handler(req, res) {
  if (req.method !== "POST")
    return res.status(405).json({ ok: false, error: "Method not allowed" });

  if (!SHARED)
    return res.status(500).json({ ok: false, error: "Server misconfigured" });

  const { key, device, ts, nonce, sig } = req.body || {};

  if (
    typeof key !== "string" || key.length < 4 ||
    typeof device !== "string" ||
    typeof ts !== "number" ||
    typeof nonce !== "string" ||
    typeof sig !== "string"
  ) {
    return res.status(400).json({ ok: false, error: "Bad request" });
  }

  if (Math.abs(now() - ts * 1000) > 60_000)
    return res.status(401).json({ ok: false, error: "Stale request" });

  if (seenNonces.has(nonce))
    return res.status(401).json({ ok: false, error: "Replay" });

  seenNonces.set(nonce, now());
  setTimeout(() => seenNonces.delete(nonce), NONCE_TTL_MS);

  const expectSig = sign(key, device, ts, nonce);
  if (sig !== expectSig)
    return res.status(401).json({ ok: false, error: "Bad signature" });

  const SUPABASE_URL = process.env.supabaseurl;
  const SERVICE_ROLE = process.env.supabaseService;

  if (!SUPABASE_URL || !SERVICE_ROLE)
    return res.status(500).json({ ok: false, error: "DB misconfigured" });

  const headers = {
    apikey: SERVICE_ROLE,
    Authorization: `Bearer ${SERVICE_ROLE}`,
    "Content-Type": "application/json"
  };

  const selectUrl =
    `${SUPABASE_URL}/rest/v1/keys` +
    `?select=key,expires_at,used` +
    `&key=eq.${encodeURIComponent(key)}` +
    `&limit=1`;

  const r = await fetch(selectUrl, { headers });
  const rows = await r.json().catch(() => null);
  const row = rows && rows[0];

  if (!row)
    return res.status(401).json({ ok: false, error: "Invalid key" });

  if (row.used)
    return res.status(401).json({ ok: false, error: "Used key" });

  if (row.expires_at) {
    const exp = Date.parse(row.expires_at);
    if (!Number.isNaN(exp) && exp <= now())
      return res.status(401).json({ ok: false, error: "Expired" });
  }

  const patchUrl =
    `${SUPABASE_URL}/rest/v1/keys?key=eq.${encodeURIComponent(key)}`;

  const pr = await fetch(patchUrl, {
    method: "PATCH",
    headers: { ...headers, Prefer: "return=minimal" },
    body: JSON.stringify({
      used: true,
      used_at: new Date().toISOString(),
      device
    })
  });

  if (!pr.ok)
    return res.status(500).json({ ok: false, error: "Update failed" });

  // ---- signed response ----

  const rts = Math.floor(now() / 1000);
  const rnonce = crypto.randomBytes(16).toString("hex");

  const payload_url = process.env.PAYLOAD_URL || "";

  const response = {
    ok: true,
    payload_url,
    ts: rts,
    nonce: rnonce
  };

  response.sig = sign(
    String(response.ok),
    payload_url,
    response.ts,
    response.nonce
  );

  return res.status(200).json(response);
}
