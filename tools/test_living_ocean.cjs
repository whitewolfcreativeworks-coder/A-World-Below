const { chromium } = require('playwright');
const fs = require('node:fs');
(async () => {
  const dir='build/living-ocean-checks'; fs.mkdirSync(dir,{recursive:true});
  const browser=await chromium.launch({executablePath:process.env.CHROMIUM_PATH||'/usr/bin/chromium',args:['--no-sandbox','--use-angle=swiftshader','--enable-unsafe-swiftshader','--disable-dev-shm-usage']});
  try {
    const page=await browser.newPage({viewport:{width:1024,height:768},hasTouch:true,isMobile:true});
    const errors=[];page.on('console',m=>console.log(m.type(),m.text()));page.on('pageerror',e=>errors.push(String(e)));page.on('console',m=>{if(m.type()==='error')errors.push(m.text())});
    const ready=page.waitForEvent('console',{predicate:m=>m.text().includes('A World Below ready'),timeout:90000});
    await page.goto(process.env.GAME_URL||'http://127.0.0.1:8001/'); await ready;
    const box=await page.locator('canvas').boundingBox();const scale=Math.min(box.width/1280,box.height/800);
    const point=(x,y)=>({x:box.x+(box.width-1280*scale)/2+x*scale,y:box.y+(box.height-800*scale)/2+y*scale});
    const tap=async(x,y)=>{const p=point(x,y);await page.touchscreen.tap(p.x,p.y)};
    // A real touch gesture unlocks browser audio on entry.
    await tap(500,515); await page.waitForTimeout(1000);
    await page.screenshot({path:dir+'/01-habitat-and-sonar.png'});
    for (const [name,y] of [['ambient',400],['electronic',435],['downtempo',470],['piano',505]]) {
      await tap(110,y);await page.waitForTimeout(1000);
      if(name==='piano') await page.screenshot({path:dir+'/02-music-'+name+'.png'});
    }
    await tap(110,579);await page.waitForTimeout(500);
    await page.screenshot({path:dir+'/03-life-catalog.png'});
    // Scroll inside the catalog to inspect the actual licensed image and credit.
    await page.mouse.move(800,650);await page.mouse.wheel(0,2800);await page.waitForTimeout(700);
    await page.screenshot({path:dir+'/04-real-microscopy.png'});
    await page.keyboard.press('Escape');
    if(errors.length)throw new Error(errors.join('\n'));
    console.log('Living ocean browser loaded; soundtrack selections, sonar, atlas and microscopy captured without runtime errors. Inspect screenshots; physical iPad/audio audition pending.');
  } finally {await browser.close()}
})().catch(e=>{console.error(e);process.exitCode=1});
