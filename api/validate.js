const seenIds = new Map();

export default function handler(req, res) {
  if (req.method !== "POST")
    return res.status(405).json({ error: "Method Not Allowed" });

  const { UserId } = req.body || {};
  if (!UserId) return res.status(400).json({ error: "Missing UserId" });

  const now = Date.now();

  for (const [id, expiry] of seenIds) {
    if (expiry <= now) seenIds.delete(id);
  }

  if (seenIds.has(UserId)) {
    return res.status(200).json({ valid: false });
  }

  seenIds.set(UserId, now + 60 * 1000);

  return res.status(200).json({ valid: true, UserId });
}
