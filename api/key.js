import crypto from "crypto";

const SECRET = process.env.sSecret;
const URL = process.env.supabaseurl;
const SERVICE_KEY = process.env.supabaseService;

const hash = (str) =>
  crypto.createHash("sha256").update(str).digest("hex");

const safeEqual = (a, b) => {
  const ba = Buffer.from(a || "");
  const bb = Buffer.from(b || "");
  if (ba.length !== bb.length) return false;
  return crypto.timingSafeEqual(ba, bb);
};

const canon = (v) => {
  if (v === true) return "1";
  if (v === false) return "0";
  if (v == null) return "";
  return String(v);
};

const makeSig = (...vals) => {
  const joined = vals.map(canon).join("|") + "|" + SECRET;
  return hash(joined);
};

export default async function handler(req, res) {
  res.setHeader("Content-Type", "application/json");

  if (req.method !== "POST") {
    return res.status(405).json({ ok: false });
  }

  if (!SECRET || !URL || !SERVICE_KEY) {
    return res.status(500).json({ ok: false });
  }

  try {
    let data = req.body;

    if (typeof data === "string") {
      try {
        data = JSON.parse(data);
      } catch {
        return res.status(400).json({ ok: false });
      }
    }

    if (!data || typeof data !== "object") {
      return res.status(400).json({ ok: false });
    }

    const key = typeof data.key === "string" ? data.key : "";
    const sig = typeof data.sig === "string" ? data.sig : "";

    if (key.length < 4 || sig.length < 10) {
      return res.status(400).json({ ok: false });
    }

    // verify request signature (tamper check)
    const expectedSig = makeSig(key);
    if (!safeEqual(sig, expectedSig)) {
      return res.status(401).json({ ok: false });
    }

    // query supabase
    const query =
      `${URL}/rest/v1/keys?select=key,expires_at` +
      `&key=eq.${encodeURIComponent(key)}` +
      `&limit=1`;

    const resp = await fetch(query, {
      headers: {
        apikey: SERVICE_KEY,
        Authorization: `Bearer ${SERVICE_KEY}`,
      },
    });

    if (!resp.ok) {
      return res.status(502).json({ ok: false });
    }

    const rows = await resp.json();

    let valid = false;

    if (Array.isArray(rows) && rows.length > 0) {
      const row = rows[0];

      if (row.expires_at) {
        const now = Date.now();
        const exp = new Date(row.expires_at).getTime();

        if (!Number.isNaN(exp) && now < exp) {
          valid = true;
        }
      }
    }

    return res.status(200).json({
      ok: valid,
      sig: makeSig(valid),
    });

  } catch (err) {
    console.error("handler error:", err);
    return res.status(500).json({ ok: false });
  }
}
