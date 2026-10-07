// Frame-accurate export of index.html to MP4 (or stills).
//
//   node render.mjs                      -> frontend-motion.mp4 (1920x1080, 30 fps)
//   node render.mjs --stills 3,12,20     -> still-3.png, still-12.png, ... (seconds)
//   node render.mjs --fps 24 --scale 1   -> 1280x720 at 24 fps
//
// Needs Node, Playwright (Chromium) and ffmpeg with libx264. The page exposes
// window.__motion.seek(t), so every frame is rendered at an exact time instead
// of recording the screen in real time.
import { createRequire } from 'node:module';
import { spawn, execFileSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
// require() also honours NODE_PATH, so a globally installed Playwright works.
const { chromium } = createRequire(import.meta.url)('playwright');
const args = process.argv.slice(2);
const opt = (name, def) => { const i = args.indexOf(name); return i >= 0 ? args[i + 1] : def; };
const fps = Number(opt('--fps', 30));
const scale = Number(opt('--scale', 1.5));
const stills = opt('--stills', null);
const out = path.resolve(opt('--out', path.join(here, 'frontend-motion.mp4')));

const browser = await chromium.launch({ executablePath: process.env.CHROMIUM_PATH || undefined });
const page = await browser.newPage({ viewport: { width: 1312, height: 900 }, deviceScaleFactor: scale });

// Fetch Google Fonts with curl so proxies and CA bundles configured for curl apply.
await page.route(/fonts\.(googleapis|gstatic)\.com/, route => {
  const url = route.request().url();
  try {
    const body = execFileSync('curl', ['-sSL', '-A', 'Mozilla/5.0 (X11; Linux x86_64) Chrome/140 Safari/537.36', url], { maxBuffer: 1 << 26 });
    const type = url.includes('googleapis') ? 'text/css' : 'font/woff2';
    route.fulfill({ status: 200, body, headers: { 'content-type': type, 'access-control-allow-origin': '*' } });
  } catch {
    route.abort();
  }
});

await page.goto(pathToFileURL(path.join(here, 'index.html')).href);
await page.evaluate(() => document.fonts.ready);
await page.waitForTimeout(300);
const stage = page.locator('#stage');
const total = await page.evaluate(() => window.__motion.total);

if (stills) {
  for (const s of stills.split(',').map(Number)) {
    await page.evaluate(t => window.__motion.seek(t), s);
    await stage.screenshot({ path: path.join(here, `still-${s}.png`) });
  }
} else {
  const w = Math.round(1280 * scale), h = Math.round(720 * scale);
  const ff = spawn('ffmpeg', ['-y', '-loglevel', 'error', '-f', 'image2pipe', '-framerate', String(fps), '-i', '-',
    '-vf', `scale=${w}:${h}`, '-c:v', 'libx264', '-preset', 'slow', '-crf', '20', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', out],
    { stdio: ['pipe', 'inherit', 'inherit'] });
  const frames = Math.round(total * fps);
  for (let f = 0; f < frames; f++) {
    await page.evaluate(t => window.__motion.seek(t), f / fps);
    const buf = await stage.screenshot({ type: 'jpeg', quality: 95 });
    if (!ff.stdin.write(buf)) await new Promise(r => ff.stdin.once('drain', r));
    if (f % (fps * 5) === 0) process.stdout.write(`\r${(f / fps).toFixed(0)}s / ${total.toFixed(0)}s`);
  }
  ff.stdin.end();
  await new Promise((res, rej) => ff.on('close', c => (c === 0 ? res() : rej(new Error('ffmpeg exited ' + c)))));
  console.log(`\nwrote ${out}`);
}
await browser.close();
