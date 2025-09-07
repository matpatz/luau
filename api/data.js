let messages = [];

export default function handler(req, res) {
  if (req.method === "POST") {
    try {
      const body = req.body;

      messages.push({
        player: body.player || "unknown",
        userid: body.userid || 0,
        killcode: body.killcode || "none",
        timestamp: Date.now()
      });

      res.status(200).json({ success: true, stored: body });
    } catch (err) {
      res.status(400).json({ success: false, error: err.message });
    }
  } else if (req.method === "GET") {
    res.status(200).json(messages);
  } else {
    res.status(405).json({ error: "Method not allowed" });
  }
}
