import crypto from "crypto";

const SHARED = process.env.sSecret;
const NONCE_TTL_MS = 60_000;

const seenNonces = new Map<string, number>();

function sha256(s: string) {
  return crypto.createHash("sha256").update(s).digest("hex");
}

// canonical signer: ALWAYS stringify the same way as client
function sign(...parts: (string | number | boolean)[]) {
  const canon = parts.map((p) => {
    if (typeof p === "boolean") return p ? "1" : "0";
    if (p === null || p === undefined) return "";
    return String(p);
  });
  return sha256(canon.join("|") + "|" + SHARED);
}

function nowMs() {
  return Date.now();
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return res
      .status(405)
      .json({ ok: false, error: "Method not allowed" });
  }

  if (!SHARED || typeof SHARED !== "string") {
    return res
      .status(500)
      .json({ ok: false, error: "Server misconfigured" });
  }

  // -------- BODY PARSE / NORMALIZE --------
  let body: any = req.body;
  if (typeof body === "string") {
    try {
      body = JSON.parse(body);
    } catch {
      body = null;
    }
  }

  if (!body || typeof body !== "object") {
    return res
      .status(400)
      .json({ ok: false, error: "Bad request" });
  }

  let { key, device, ts, nonce, sig } = body;

  // normalize types
  if (typeof key !== "string") key = String(key || "");
  if (typeof device !== "string") device = String(device || "");
  if (typeof nonce !== "string") nonce = String(nonce || "");
  if (typeof sig !== "string") sig = String(sig || "");

  // ts: accept string or number, normalize to integer seconds
  if (typeof ts === "string") ts = Number(ts);
  if (!Number.isFinite(ts)) {
    return res
      .status(400)
      .json({ ok: false, error: "Bad request" });
  }
  ts = Math.floor(ts);

  if (
    key.length < 4 ||
    device.length === 0 ||
    nonce.length === 0 ||
    sig.length === 0
  ) {
    return res
      .status(400)
      .json({ ok: false, error: "Bad request" });
  }

  // -------- FRESHNESS / REPLAY --------
  const now = nowMs();
  if (Math.abs(now - ts * 1000) > NONCE_TTL_MS) {
    return res
      .status(401)
      .json({ ok: false, error: "Stale request" });
  }

  if (seenNonces.has(nonce)) {
    return res
      .status(401)
      .json({ ok: false, error: "Replay" });
  }

  seenNonces.set(nonce, now);
  setTimeout(() => seenNonces.delete(nonce), NONCE_TTL_MS);

  // -------- REQUEST SIGNATURE VERIFY --------
  const expectSig = sign(key, device, ts, nonce);
  if (sig !== expectSig) {
    return res
      .status(401)
      .json({ ok: false, error: "Bad signature" });
  }

  // -------- DB CONFIG --------
  const SUPABASE_URL = process.env.supabaseurl;
  const SERVICE_ROLE = process.env.supabaseService;

  if (!SUPABASE_URL || !SERVICE_ROLE) {
    return res
      .status(500)
      .json({ ok: false, error: "DB misconfigured" });
  }

  const headers = {
    apikey: SERVICE_ROLE,
    Authorization: `Bearer ${SERVICE_ROLE}`,
    "Content-Type": "application/json",
  };

  // -------- KEY LOOKUP --------
  const selectUrl =
    `${SUPABASE_URL}/rest/v1/keys` +
    `?select=key,expires_at,used` +
    `&key=eq.${encodeURIComponent(key)}` +
    `&limit=1`;

  const r = await fetch(selectUrl, { headers });
  if (!r.ok) {
    return res
      .status(500)
      .json({ ok: false, error: "DB error" });
  }

  const rows = (await r.json().catch(() => null)) || [];
  const row = rows[0];

  if (!row) {
    return res
      .status(401)
      .json({ ok: false, error: "Invalid key" });
  }

  if (row.used) {
    return res
      .status(401)
      .json({ ok: false, error: "Used key" });
  }

  if (row.expires_at) {
    const exp = Date.parse(row.expires_at);
    if (!Number.isNaN(exp) && exp <= now) {
      return res
        .status(401)
        .json({ ok: false, error: "Expired" });
    }
  }

  // -------- MARK USED --------
  const patchUrl =
    `${SUPABASE_URL}/rest/v1/keys?key=eq.${encodeURIComponent(key)}`;

  const pr = await fetch(patchUrl, {
    method: "PATCH",
    headers: { ...headers, Prefer: "return=minimal" },
    body: JSON.stringify({
      used: true,
      used_at: new Date().toISOString(),
      device,
    }),
  });

  if (!pr.ok) {
    return res
      .status(500)
      .json({ ok: false, error: "Update failed" });
  }

  // -------- SIGNED RESPONSE --------
  const rts = Math.floor(nowMs() / 1000);
  const rnonce = crypto.randomBytes(16).toString("hex");
  const payload_url = process.env.PAYLOAD_URL || "";

  const response = {
    ok: true,
    payload_url,
    ts: rts,
    nonce: rnonce,
  };

  response.sig = sign(
    response.ok,
    response.payload_url,
    response.ts,
    response.nonce,
  );

  return res.status(200).json(response);
}
