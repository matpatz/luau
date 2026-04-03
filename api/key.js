// cleaned up the ai code with more ai
import crypto from "crypto";

const SECRET = process.env.sSecret;
const URL = process.env.supabaseurl;
const SERVICE_KEY = process.env.supabaseService;

const hash = (str) =>
  crypto.createHash("sha256").update(str).digest("hex");

const makeSig = (...vals) => {
  let out = "";

  for (let v of vals) {
    if (v === true) out += "1";
    else if (v === false) out += "0";
    else if (v != null) out += String(v);

    out += "|";
  }

  return hash(out + SECRET);
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

    const key = data?.key ? String(data.key) : "";
    const sig = data?.sig ? String(data.sig) : "";

    if (!key || !sig) {
      return res.status(400).json({ ok: false });
    }

    // verify request
    if (sig !== makeSig(key)) {
      return res.status(401).json({ ok: false });
    }

    // search supabase
    const query =
      `${URL}/rest/v1/keys?select=key` +
      `&key=eq.${encodeURIComponent(key)}` +
      `&limit=1`;

    const resp = await fetch(query, {
      headers: {
        apikey: SERVICE_KEY,
        Authorization: `Bearer ${SERVICE_KEY}`,
      },
    });

    if (!resp.ok) {
      return res.status(500).json({ ok: false });
    }

    const result = await resp.json();
    const valid = Array.isArray(result) && result.length > 0;

    const out = {
      ok: valid,
      sig: makeSig(valid),
    };

    return res.status(200).json(out);
  } catch (err) {
    console.error("handler error:", err);
    return res.status(500).json({ ok: false });
  }
}
