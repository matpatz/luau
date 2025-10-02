const seenIds = new Set();

export default function handler(req, res) {
  if (req.method !== "POST")
    return res.status(405).json({ error: "Method Not Allowed" });

  const { UserId } = req.body || {};
  if (!UserId) return res.status(400).json({ error: "Missing UserId" });

  if (seenIds.has(UserId)) {
    return res.status(200).json({ valid: false });
  }

  seenIds.add(UserId);

  return res.status(200).json({ valid: true, UserId: UserId });
}
