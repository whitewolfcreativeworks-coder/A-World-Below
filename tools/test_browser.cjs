// Optional smoke test: install Playwright locally and serve build/web on port 8000.
// SCREENSHOTS_DIR defaults to build/browser-checks. No game dependencies use npm.
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');

(async () => {
  const directory = process.env.SCREENSHOTS_DIR || path.resolve('build/browser-checks');
  fs.mkdirSync(directory, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    headless: true,
    args: ['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
  });
  try {
    const context = await browser.newContext({
      viewport: { width: 1366, height: 1024 }, hasTouch: true, isMobile: true, deviceScaleFactor: 1,
    });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', error => errors.push(String(error)));
    page.on('console', message => { if (message.type() === 'error') errors.push(message.text()); });
    const ready = page.waitForEvent('console', {
      predicate: message => message.text().includes('A World Below ready'), timeout: 60000,
    });
    await page.goto(process.env.GAME_URL || 'http://127.0.0.1:8000/');
    await ready;
    await page.waitForTimeout(500);
    // Godot preserves the 1280x800 aspect inside the full-window canvas.
    const canvas = await page.locator('canvas').boundingBox();
    const scale = Math.min(canvas.width / 1280, canvas.height / 800);
    const point = (x, y) => ({
      x: canvas.x + (canvas.width - 1280 * scale) / 2 + x * scale,
      y: canvas.y + (canvas.height - 800 * scale) / 2 + y * scale,
    });
    const tap = async (x, y) => { const p = point(x, y); await page.touchscreen.tap(p.x, p.y); };
    await tap(640, 588);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(directory, '01-start.png') });
    const cdp = await context.newCDPSession(page);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ ...point(105, 690), id: 1 }] });
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ ...point(105, 640), id: 1 }] });
    await page.waitForTimeout(2500);
    await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(directory, '02-touch-swim.png') });
    await tap(1015, 48);
    await page.waitForTimeout(500);
    await page.screenshot({ path: path.join(directory, '03-journal.png') });
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('Web runtime loaded; touch and journal screenshots captured; no runtime errors.');
    console.log('Inspect screenshots for visual/interaction results. This is not a physical iPad Safari test.');
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
