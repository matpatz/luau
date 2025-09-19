let messages = []

export default function handler(req, res) {
  const { player, message } = req.query

  if (player && message) {
    messages.push({
      Date: new Date().toISOString(),
      Player: player,
      Message: message
    })
  }

  res.status(200).json(messages)
}
