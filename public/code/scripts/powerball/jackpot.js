import { promises as fs } from "fs";

export default async function handler(req, res) {
  const filePath = './jackpot.json';
  let data = JSON.parse(await fs.readFile(filePath, 'utf-8'));

  if (req.method === 'POST') {
    const { whites, powerball, jackpot } = req.body;
    if (whites && powerball && jackpot != null) {
      data.whites = whites;
      data.powerball = powerball;
      data.jackpot = jackpot;
      await fs.writeFile(filePath, JSON.stringify(data, null, 2));
      return res.status(200).json({ success: true });
    }
    return res.status(400).json({ error: 'Invalid body' });
  }

  // GET request returns current jackpot + winning numbers
  res.status(200).json(data);
}
