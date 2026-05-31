// api/ascii.js
// Vercel Serverless Function — converts a base64 image to ASCII art
// Called from Roblox Luau via HttpService

import { createCanvas, loadImage } from '@napi-rs/canvas';

// ---------------------------------------------------------------------------
// Tiny ASCII-magic re-implementation (no Python dependency needed in Node.js)
// Uses luminance sampling to pick characters — no native modules required.
// ---------------------------------------------------------------------------

const CHARS_DARK_TO_LIGHT = ' .\'`^",:;Il!i><~+_-?][}{1)(|/tfjrxnuvczXYUJCLQ0OZmwqpdbkhao*#MW&8%B@$';
//                           ^ darkest                                                              ^ brightest

/**
 * Converts a Pillow-style pixel (r,g,b,a) luminance to an ASCII character.
 */
function luminanceToChar(r, g, b) {
  // Standard luminance formula
  const lum = 0.299 * r + 0.587 * g + 0.114 * b;
  const index = Math.floor((lum / 255) * (CHARS_DARK_TO_LIGHT.length - 1));
  return CHARS_DARK_TO_LIGHT[index];
}

/**
 * Converts a raw RGBA pixel buffer to an ASCII string.
 *
 * @param {Uint8ClampedArray} data  - raw RGBA bytes from canvas
 * @param {number}            width - canvas width in pixels
 * @param {number}            height- canvas height in pixels
 * @param {number}            cols  - desired character columns (default 80)
 * @returns {string}
 */
function pixelsToAscii(data, width, height, cols = 80) {
  // ASCII characters are roughly twice as tall as they are wide,
  // so we sample every ~2 rows per 1 column to keep proportions.
  const cellW = width / cols;
  const cellH = cellW * 2.2;          // width_ratio = 2.2 (same default as ascii-magic)
  const rows  = Math.floor(height / cellH);

  const lines = [];

  for (let row = 0; row < rows; row++) {
    let line = '';
    for (let col = 0; col < cols; col++) {
      // Sample the center pixel of each cell
      const px = Math.floor((col + 0.5) * cellW);
      const py = Math.floor((row + 0.5) * cellH);

      const idx = (py * width + px) * 4;
      const r   = data[idx];
      const g   = data[idx + 1];
      const b   = data[idx + 2];
      // Alpha blend over black background
      const a   = data[idx + 3] / 255;
      line += luminanceToChar(r * a, g * a, b * a);
    }
    lines.push(line);
  }

  return lines.join('\n');
}

// ---------------------------------------------------------------------------
// Request handler
// ---------------------------------------------------------------------------

export default async function handler(req, res) {
  // --- CORS headers (allow Roblox & any client) ---
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  // Pre-flight
  if (req.method === 'OPTIONS') {
    return res.status(200).end();
  }

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed. Use POST.' });
  }

  // --- Parse body ---
  let body;
  try {
    body = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
  } catch {
    return res.status(400).json({ error: 'Invalid JSON body.' });
  }

  const { image, columns } = body;

  if (!image) {
    return res.status(400).json({
      error: 'Missing required field: "image" (base64-encoded image string).',
    });
  }

  // Accept both bare base64 and data-URI format
  // e.g. "data:image/png;base64,iVBOR..." or just "iVBOR..."
  const base64Data = image.includes(',') ? image.split(',')[1] : image;

  // Validate columns (Roblox GUI label lines work best at 60–100 columns)
  const cols = Math.min(Math.max(parseInt(columns) || 80, 10), 200);

  // --- Decode image ---
  let img;
  try {
    const buffer = Buffer.from(base64Data, 'base64');
    img = await loadImage(buffer);
  } catch (err) {
    return res.status(400).json({
      error: 'Could not decode image. Make sure it is valid base64 PNG/JPG.',
      detail: err.message,
    });
  }

  // --- Render to canvas and extract pixels ---
  const canvas = createCanvas(img.width, img.height);
  const ctx    = canvas.getContext('2d');
  ctx.drawImage(img, 0, 0);

  const { data } = ctx.getImageData(0, 0, img.width, img.height);

  // --- Convert to ASCII ---
  const ascii = pixelsToAscii(data, img.width, img.height, cols);

  return res.status(200).json({ ascii });
}
