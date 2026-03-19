import { spawn } from 'child_process';
import { writeFileSync, unlinkSync, mkdtempSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const { code } = req.body;

  if (!code || typeof code !== 'string') {
    return res.status(400).json({ error: 'Missing or invalid code parameter' });
  }

  const tempDir = mkdtempSync(join(tmpdir(), 'luau-'));
  const tempFile = join(tempDir, 'script.luau');

  try {
    writeFileSync(tempFile, code);

    const result = await new Promise((resolve, reject) => {
      const child = spawn('npx', ['--yes', 'lune-cli@0.8.9', 'run', tempFile]);
      
      let stdout = '';
      let stderr = '';

      const timer = setTimeout(() => {
        child.kill();
        reject(new Error('Timeout'));
      }, 5000);

      child.stdout.on('data', (data) => stdout += data.toString());
      child.stderr.on('data', (data) => stderr += data.toString());

      child.on('close', (code) => {
        clearTimeout(timer);
        resolve({ success: code === 0, stdout, stderr, exitCode: code });
      });

      child.on('error', (error) => {
        clearTimeout(timer);
        reject(error);
      });
    });

    unlinkSync(tempFile);
    return res.status(200).json(result);

  } catch (error) {
    try { unlinkSync(tempFile); } catch (e) {}
    return res.status(500).json({ success: false, error: error.message });
  }
}
