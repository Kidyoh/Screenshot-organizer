// Renders icon.svg (written by gen_icon.py) to every PNG the project uses.
//
//   python3 design/icon/gen_icon.py android/app/src/main/res design/icon/icon.svg
//   node design/icon/render.cjs        # needs the `playwright` package
//   dart run flutter_native_splash:create
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const root = path.join(__dirname, '../..');
const circle = fs.readFileSync(path.join(__dirname, 'icon.svg'), 'utf8')
  .replace('width="512" height="512"', 'width="100%" height="100%"');
// Full-bleed square (no circle mask) for the banners' rounded app tile.
const square = circle
  .replace('viewBox="9 9 90 90"', 'viewBox="18 18 72 72"')
  .replace(' clip-path="url(#c)"', '');

const jobs = [
  ...[['mdpi', 48], ['hdpi', 72], ['xhdpi', 96], ['xxhdpi', 144], ['xxxhdpi', 192]].flatMap(([d, px]) =>
    ['ic_launcher', 'ic_launcher_round'].map((n) =>
      [`android/app/src/main/res/mipmap-${d}/${n}.png`, circle, px, px])),
  ['docs/icon.png', circle, 512, 512],
  ['assets/icon/icon_full.png', square, 512, 512],
  ['assets/icon/splash_mark.png', circle, 1152, 640],
  ['assets/icon/splash_legacy.png', circle, 480, 480],
];

(async () => {
  const browser = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
  const page = await browser.newPage();
  for (const [out, svg, canvas, size] of jobs) {
    await page.setViewportSize({ width: canvas, height: canvas });
    await page.setContent(`<style>html,body{margin:0;background:transparent}
      body{width:${canvas}px;height:${canvas}px;display:flex;align-items:center;justify-content:center}</style>
      <div style="width:${size}px;height:${size}px">${svg}</div>`);
    await page.screenshot({ path: path.join(root, out), omitBackground: true });
    console.log(out);
  }
  await browser.close();
})();
