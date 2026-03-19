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

  if (code.length > 100000) {
    return res.status(400).json({ error: 'Code too long (max 100KB)' });
  }

  const tempDir = mkdtempSync(join(tmpdir(), 'luau-'));
  const tempFile = join(tempDir, 'script.luau');

  try {
    writeFileSync(tempFile, code);

    const result = await new Promise((resolve, reject) => {
      const process = spawn('lune', ['run', tempFile]);
      
      let stdout = '';
      let stderr = '';
      let killed = false;

      const timer = setTimeout(() => {
        killed = true;
        process.kill();
        reject(new Error('Execution timeout after 5000ms'));
      }, 5000);

      process.stdout.on('data', (data) => {
        stdout += data.toString();
      });

      process.stderr.on('data', (data) => {
        stderr += data.toString();
      });

      process.on('close', (code) => {
        clearTimeout(timer);
        if (killed) return;
        resolve({
          success: code === 0,
          stdout,
          stderr,
          exitCode: code
        });
      });

      process.on('error', (error) => {
        clearTimeout(timer);
        reject(error);
      });
    });

    unlinkSync(tempFile);
    
    return res.status(200).json(result);

  } catch (error) {
    try {
      unlinkSync(tempFile);
    } catch (e) {}
    
    return res.status(500).json({
      success: false,
      error: error.message
    });
  }
}
