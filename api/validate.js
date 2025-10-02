export default async function handler(req, res) {
  if (req.method !== "POST")
    return res.status(405).json({ error: "Method Not Allowed" });

  const { UserId } = req.body || {};
  if (!UserId) return res.status(400).json({ error: "Missing UserId" });

  const isValid = UserId % 2 === 0;

  if (isValid) {
    return res.status(200).json({
      valid: true,
      scriptUrl: "https://website-iota-ivory-12.vercel.app/code/loader/g/lr.lua"
    });
  } else {
    return res.status(200).json({ valid: false });
  }
}
