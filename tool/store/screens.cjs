// Renders 1080 × 1920 Play Store screenshots to store/screenshots/ from the
// raw app captures in tool/store/shots/<id>.png. Needs the `playwright` package.
//   node tool/store/screens.cjs
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const out = path.join(__dirname, '../../store/screenshots');
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
  const page = await browser.newPage({ viewport: { width: 1080, height: 1920 }, deviceScaleFactor: 1 });
  await page.goto('file://' + path.join(__dirname, 'screens.html'));
  await page.evaluate(() => document.fonts.ready);
  await page.waitForLoadState('networkidle');
  for (const el of await page.$$('.s')) {
    const id = await el.getAttribute('id');
    if (!fs.existsSync(path.join(__dirname, 'shots', `${id}.png`))) continue;
    await el.screenshot({ path: path.join(out, `${id}.png`) });
    console.log(`store/screenshots/${id}.png`);
  }
  await browser.close();
})();
