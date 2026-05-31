import sharp from 'sharp';

const CHARS = ' .\'`^",:;Il!i><~+_-?][}{1)(|/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$';

function pixelsToAscii(data, width, height, cols) {
  const cellW = width / cols;
  const cellH = cellW * 2.2;
  const rows  = Math.floor(height / cellH);
  const lines = [];

  for (let row = 0; row < rows; row++) {
    let line = '';
    for (let col = 0; col < cols; col++) {
      const px  = Math.floor((col + 0.5) * cellW);
      const py  = Math.floor((row + 0.5) * cellH);
      const idx = (py * width + px) * 4;
      const r   = data[idx];
      const g   = data[idx + 1];
      const b   = data[idx + 2];
      const a   = data[idx + 3] / 255;
      const lum = (0.299 * r + 0.587 * g + 0.114 * b) * a;
      line += CHARS[Math.floor((lum / 255) * (CHARS.length - 1))];
    }
    lines.push(line);
  }

  return lines.join('\n');
}

export default async function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') return res.status(200).end();
  if (req.method !== 'POST') return res.status(405).json({ error: 'Use POST.' });

  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch {
    return res.status(400).json({ error: 'Invalid JSON.' });
  }

  const { image, columns } = body;
  if (!image) return res.status(400).json({ error: 'Missing "image" field.' });

  const cols    = Math.min(Math.max(parseInt(columns) || 80, 10), 200);
  const b64data = image.includes(',') ? image.split(',')[1] : image;
  const buffer  = Buffer.from(b64data, 'base64');

  let raw, width, height;
  try {
    const img = sharp(buffer).ensureAlpha();
    const meta = await img.metadata();
    width  = meta.width;
    height = meta.height;
    raw    = await img.raw().toBuffer();
  } catch (err) {
    return res.status(400).json({ error: 'Could not decode image.', detail: err.message });
  }

  const ascii = pixelsToAscii(raw, width, height, cols);
  return res.status(200).json({ ascii });
}
