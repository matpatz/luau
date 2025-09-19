// api/message.js
let messages = []

export default function handler(req, res) {
  const { player, message } = req.query

  if (player && message) {
    messages.push({ Player: player, Message: message })
  }

  res.status(200).json(messages)
}
