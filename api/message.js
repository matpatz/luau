// api/message.js
import { kv } from '@vercel/kv'

export default async function handler(req, res) {
  const { player, message } = req.query

  if (player && message) {
    await kv.rpush('chat:messages', JSON.stringify({ Player: player, Message: message }))
  }

  const all = await kv.lrange('chat:messages', -50, -1) // last 50 messages
  res.status(200).json(all.map(JSON.parse))
}
