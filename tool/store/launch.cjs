// Renders the launch banners (square post and story) to store/launch/.
//   node tool/store/launch.cjs
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const out = path.join(__dirname, '../../store/launch');
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  await page.goto('file://' + path.join(__dirname, 'launch.html'));
  await page.evaluate(() => document.fonts.ready);
  await page.waitForLoadState('networkidle');
  const ids = await page.$$eval('.b', (els) => els.map((e) => e.id));
  for (const id of ids) {
    // Show one banner at a time, at its own size, so nothing is cut off.
    const size = await page.evaluate((id) => {
      document.body.className = 'one';
      document.querySelectorAll('.b').forEach((e) => e.classList.toggle('on', e.id === id));
      const r = document.getElementById(id).getBoundingClientRect();
      return { width: Math.round(r.width), height: Math.round(r.height) };
    }, id);
    await page.setViewportSize(size);
    await page.screenshot({ path: path.join(out, `${id}.png`) });
    console.log(`store/launch/${id}.png`);
  }
  await browser.close();
})();
