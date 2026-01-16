export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).json({ ok: false, error: "Method not allowed" });

  const { key } = req.body || {};
  if (typeof key !== "string" || key.length < 4) return res.status(400).json({ ok: false, error: "Bad key" });

  const SUPABASE_URL = process.env.supabaseurl;
  const SERVICE_ROLE = process.env.supabaseService;
  if (!SUPABASE_URL || !SERVICE_ROLE) return res.status(500).json({ ok: false, error: "Server misconfigured" });

  const selectUrl = `${SUPABASE_URL}/rest/v1/keys?select=key,expires_at,used&key=eq.${encodeURIComponent(key)}&limit=1`;
  const headers = { apikey: SERVICE_ROLE, Authorization: `Bearer ${SERVICE_ROLE}`, "Content-Type": "application/json" };

  const r = await fetch(selectUrl, { method: "GET", headers });
  const rows = await r.json().catch(() => null);
  const row = rows && rows[0];
  if (!row) return res.status(401).json({ ok: false, error: "Invalid key" });
  if (row.used) return res.status(401).json({ ok: false, error: "Used key" });

  if (row.expires_at) {
    const exp = Date.parse(row.expires_at);
    if (!Number.isNaN(exp) && exp <= Date.now()) return res.status(401).json({ ok: false, error: "Expired" });
  }

  const patchUrl = `${SUPABASE_URL}/rest/v1/keys?key=eq.${encodeURIComponent(key)}`;
  const pr = await fetch(patchUrl, {
    method: "PATCH",
    headers: { ...headers, Prefer: "return=minimal" },
    body: JSON.stringify({ used: true, used_at: new Date().toISOString() })
  });

  if (!pr.ok) return res.status(500).json({ ok: false, error: "Update failed" });
  return res.status(200).json({ ok: true });
}
