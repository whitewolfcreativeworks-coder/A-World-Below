// Native Chromium multitouch plus Safari-style DOM partial-release sequences.
// Run against a served Web export; visual screenshots complement native-state tests.
const { chromium } = require('playwright');
const fs = require('node:fs');
const path = require('node:path');

(async () => {
  const out = path.resolve('build/multitouch-checks');
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch({
    executablePath: process.env.CHROMIUM_PATH || undefined,
    args: ['--no-sandbox', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'],
  });
  try {
    const context = await browser.newContext({
      viewport: { width: 1366, height: 1024 }, hasTouch: true, isMobile: true, deviceScaleFactor: 1,
    });
    const page = await context.newPage();
    const errors = [];
    page.on('pageerror', e => errors.push(String(e)));
    page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
    const ready = page.waitForEvent('console', {
      predicate: m => m.text().includes('A World Below ready'), timeout: 90000,
    });
    await page.goto(process.env.GAME_URL || 'http://127.0.0.1:8001/');
    await ready;
    await page.keyboard.press('Escape');
    const box = await page.locator('canvas').boundingBox();
    const scale = Math.min(box.width / 1280, box.height / 800);
    const point = (id, x, y) => ({ id,
      x: box.x + (box.width - 1280 * scale) / 2 + x * scale,
      y: box.y + (box.height - 800 * scale) / 2 + y * scale,
    });
    const cdp = await context.newCDPSession(page);
    const send = (type, touchPoints) => cdp.send('Input.dispatchTouchEvent', { type, touchPoints });
    const shot = name => page.screenshot({ path: path.join(out, name + '.png') });
    const left = point(10, 105, 640);
    const right = point(20, 900, 400);
    await send('touchStart', [point(10,105,690)]);
    await send('touchMove', [left]);
    await send('touchStart', [left,right]);
    for (let i = 1; i <= 7; i++) {
      await send('touchMove', [left,point(20,900+i*9,400-i*2)]);
      await page.waitForTimeout(100);
    }
    await shot('01-left-first-swim-and-look');
    await send('touchEnd', []);
    await send('touchStart', [point(30,900,400)]);
    await send('touchStart', [point(30,900,400),point(40,105,690)]);
    for (let i = 1; i <= 7; i++) {
      await send('touchMove', [point(30,900-i*9,400),point(40,105,640)]);
      await page.waitForTimeout(100);
    }
    await shot('02-right-first-swim-and-look');
    await send('touchEnd', []);

    // DOM touches explicitly represent lifting one thumb while another stays down.
    const dom = async (type, active, changed) => page.evaluate(({type,active,changed}) => {
      const canvas = document.querySelector('canvas');
      const touches = list => list.map(p => new Touch({
        identifier:p.id,target:canvas,clientX:p.x,clientY:p.y,pageX:p.x,pageY:p.y,
        screenX:p.x,screenY:p.y,radiusX:8,radiusY:8,force:1,
      }));
      canvas.dispatchEvent(new TouchEvent(type, {bubbles:true,cancelable:true,
        touches:touches(active),targetTouches:touches(active),changedTouches:touches(changed)}));
    }, {type,active,changed});
    const l = point(61,105,640), r = point(104,900,400);
    await dom('touchstart',[l],[l]);
    await dom('touchstart',[l,r],[r]);
    const r2 = point(104,960,400);
    await dom('touchmove',[l,r2],[r2]);
    await dom('touchend',[l],[r2]);
    await page.waitForTimeout(400);
    await shot('03-look-lifted-swim-still-held');
    const r3 = point(105,900,400);
    await dom('touchstart',[l,r3],[r3]);
    await dom('touchend',[r3],[l]);
    const r4 = point(105,940,410);
    await dom('touchmove',[r4],[r4]);
    await page.waitForTimeout(400);
    await shot('04-swim-lifted-look-still-held');
    await dom('touchend',[],[r4]);
    // Menus must remain usable after independent touch routing.
    const journal = point(1,990,48);
    await page.touchscreen.tap(journal.x,journal.y);
    await page.waitForTimeout(300);
    await shot('05-journal');
    await page.keyboard.press('Escape');
    const specimen = point(1,1100,96);
    await page.touchscreen.tap(specimen.x,specimen.y);
    await page.waitForTimeout(300);
    await shot('06-specimen');
    if (errors.length) throw new Error(errors.join('\n'));
    console.log('Two-thumb sequences and partial-release screenshots captured; no browser runtime errors.');
    console.log('Physical iPad verification is still required.');
  } finally { await browser.close(); }
})().catch(error => { console.error(error); process.exitCode = 1; });
