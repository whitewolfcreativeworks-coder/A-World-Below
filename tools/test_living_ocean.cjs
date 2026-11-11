const { chromium } = require('playwright');
const fs = require('node:fs');
(async () => {
  const dir='build/living-ocean-checks'; fs.mkdirSync(dir,{recursive:true});
  const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  try {
    const page=await browser.newPage({viewport:{width:1024,height:768},hasTouch:true,isMobile:true});
    const errors=[];page.on('console',m=>console.log(m.type(),m.text()));page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
    const ready=page.waitForEvent('console',{predicate:m=>m.text().includes('A World Below ready'),timeout:90000});
    ready.catch(()=>{});
    await page.goto(process.env.GAME_URL||'http://127.0.0.1:8001/'); await ready;
    const box=await page.locator('canvas').boundingBox();const scale=Math.min(box.width/1280,box.height/800);
    const point=(x,y)=>({x:box.x+(box.width-1280*scale)/2+x*scale,y:box.y+(box.height-800*scale)/2+y*scale});
    const tap=async(x,y)=>{const p=point(x,y);await page.touchscreen.tap(p.x,p.y)};
    await page.keyboard.press('Escape'); await page.waitForTimeout(300);
    await page.screenshot({path:dir+'/01-compact-music-button.png'});
    await tap(85,387); await page.waitForTimeout(300);
    await page.screenshot({path:dir+'/02-music-panel.png'});
    // Use actual tablet touch dragging to scroll through the track choices.
    const cdp=await page.context().newCDPSession(page);
    const start=point(190,735);
    await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...start,id:77}]});
    for(let i=1;i<=6;i++) {
      await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[{...point(190,735-i*17),id:77}]});
      await page.waitForTimeout(70);
    }
    await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
    await page.waitForTimeout(500);
    await page.screenshot({path:dir+'/03-scrolled-tracks.png'});
    await tap(190,700); await page.waitForTimeout(1100);
    await tap(190,575); await page.waitForTimeout(200);
    await tap(170,505); await page.waitForTimeout(200);
    await page.screenshot({path:dir+'/04-volume-and-off.png'});
    await tap(170,505);await tap(310,453);await page.waitForTimeout(200);
    await page.screenshot({path:dir+'/05-collapsed-again.png'});
    // The catalog remains reachable through the journal after removing its sidebar.
    await tap(990,48);await page.waitForTimeout(200);await tap(500,80);
    await page.waitForTimeout(300);
    await page.screenshot({path:dir+'/06-life-catalog.png'});
    // Scroll inside the catalog to inspect the actual licensed image and credit.
    await page.mouse.move(800,650);await page.mouse.wheel(0,2800);await page.waitForTimeout(700);
    await page.screenshot({path:dir+'/04-real-microscopy.png'});
    await page.keyboard.press('Escape');
    if(errors.length)throw new Error(errors.join('\n'));
    console.log('Compact music button, floating controls, touch-scrolled selections, volume, on/off, closing and catalog captured without runtime errors. Inspect screenshots; physical iPad/audio audition pending.');
  } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
