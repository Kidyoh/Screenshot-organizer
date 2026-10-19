// Renders the Play Store feature graphic (1024 × 500) to store/feature-graphic.png
// and copies the 512 × 512 icon. Needs the `playwright` package.
//   node tool/store/render.cjs
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

(async () => {
  const root = path.join(__dirname, '../..');
  const out = path.join(root, 'store');
  fs.mkdirSync(out, { recursive: true });
  const browser = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
  const page = await browser.newPage({ viewport: { width: 1024, height: 500 }, deviceScaleFactor: 1 });
  await page.goto('file://' + path.join(__dirname, 'feature.html'));
  await page.evaluate(() => document.fonts.ready);
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: path.join(out, 'feature-graphic.png') });
  await browser.close();
  fs.copyFileSync(path.join(root, 'docs/icon.png'), path.join(out, 'icon-512.png'));
  console.log('store/feature-graphic.png, store/icon-512.png');
})();
