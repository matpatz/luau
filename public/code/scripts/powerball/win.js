// win.js -> actually a serverless function like /api/win.js
import { promises as fs } from 'fs';

export default async function handler(req, res) {
  const filePath = './win.json'; // stored on server
  const data = JSON.parse(await fs.readFile(filePath, 'utf-8'));

  if (req.method === 'POST') {
    const { player, won, balance } = req.body;
    const playerIndex = data.findIndex(p => p.player === player);

    if (playerIndex >= 0) {
      data[playerIndex].balance = balance;
      data[playerIndex].won = won;
    } else {
      data.push({ player, balance, won });
    }

    await fs.writeFile(filePath, JSON.stringify(data, null, 2));
    return res.status(200).json({ success: true });
  }

  return res.status(200).json(data);
}
