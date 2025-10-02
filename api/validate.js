import fs from "fs/promises";

export default async function handler(req, res) {
  if (req.method !== "POST") return res.status(405).json({ error: "Method Not Allowed" });

  const { UserId } = req.body || {};
  if (!UserId) return res.status(400).json({ error: "unauthorized" });

  const data = await fs.readFile("allowed.json", "utf8");
  const allowedIds = JSON.parse(data);

  if (allowedIds.includes(UserId)) {
    return res.status(200).json({ valid: true, scriptUrl: "https://website-iota-ivory-12.vercel.app/code/loader/g/lr.lua" });
  } else {
    return res.status(200).json({ valid: false });
  }
}
