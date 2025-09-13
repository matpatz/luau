let messages = []

export default function handler(req, res) {
  if (req.method === "GET") {
    res.status(200).json(messages)
  } else if (req.method === "POST") {
    try {
      const body = JSON.parse(req.body)
      const { Player, Message } = body
      if (Player && Message) {
        messages.push({ Player, Message })
        res.status(200).json({ status: "ok" })
      } else {
        res.status(400).json({ error: "Missing Player or Message" })
      }
    } catch (e) {
      res.status(400).json({ error: "Invalid JSON" })
    }
  } else {
    res.status(405).json({ error: "Method not allowed" })
  }
}
