// api/message.js

// Simple in-memory storage (resets on cold start)
let messages = []

export default function handler(req, res) {
  const { player, message } = req.query

  // Add new message if both player and message exist
  if (player && message) {
    messages.push({ Player: player, Message: message })
  }

  // Return all messages
  res.status(200).json(messages)
}
