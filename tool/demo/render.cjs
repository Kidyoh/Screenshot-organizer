// Renders the sample screenshots in assets/demo (demo mode, onboarding art,
// README and banners). Fictional apps' screens, no real logos.
//
//   node tool/demo/render.cjs        # needs the `playwright` package
const { chromium } = require('playwright');
const out = require('path').join(__dirname, '../../assets/demo');
const base = `*{box-sizing:border-box;margin:0;padding:0}body{width:390px;height:844px;overflow:hidden;font-family:'Inter','Helvetica Neue',Arial,sans-serif;-webkit-font-smoothing:antialiased}
.sb{height:44px;display:flex;justify-content:space-between;align-items:center;padding:0 22px;font-size:15px;font-weight:600}
.sb i{display:inline-block;width:18px;height:10px;border-radius:3px;border:1.5px solid currentColor;margin-left:6px;position:relative}
.sb i:after{content:'';position:absolute;inset:1.5px;right:5px;background:currentColor;border-radius:1px}
.sb b{display:inline-block;width:16px;height:10px;margin-left:6px;background:linear-gradient(90deg,currentColor 20%,transparent 20% 30%,currentColor 30% 50%,transparent 50% 60%,currentColor 60% 80%,transparent 80% 90%,currentColor 90%);clip-path:polygon(0 100%,100% 0,100% 100%)}
.row{display:flex;align-items:center}.av{border-radius:50%;flex:none}.line{height:10px;border-radius:5px;background:#ddd;margin:7px 0}`;
const sb = (t, c='#111') => `<div class="sb" style="color:${c}"><span>${t}</span><span><b></b><i></i></span></div>`;
const screens = {
 // WhatsApp-style chat
 'Screenshot_20261012-091522_WhatsApp': `<body style="background:#efe7de">${sb('9:15','#fff').replace('class="sb"','class="sb" style="background:#0b6b5a;color:#fff"')}
  <div class="row" style="background:#0b6b5a;color:#fff;padding:6px 16px 14px"><div class="av" style="width:40px;height:40px;background:#f3b27a"></div><div style="margin-left:12px"><div style="font-weight:700;font-size:17px">Mom</div><div style="font-size:13px;opacity:.8">online</div></div></div>
  <div style="padding:16px 12px;display:flex;flex-direction:column;gap:8px;font-size:15px;line-height:1.35">
  ${[['l','Did you get home ok?'],['r','Yes! Just got in'],['l','Don\'t forget dinner on Sunday, 6pm'],['l','Bring the cake recipe too'],['r','Will do. Sending it now'],['r','Love you'],['l','Love you more'],['l','Also call your aunt, it\'s her birthday tomorrow!'],['r','Already on my list']].map(([s,t])=>`<div style="align-self:${s=='l'?'flex-start':'flex-end'};max-width:78%;background:${s=='l'?'#fff':'#d8fdd2'};padding:8px 12px 18px;border-radius:12px;position:relative;box-shadow:0 1px 1px rgba(0,0,0,.08)">${t}<span style="position:absolute;right:8px;bottom:3px;font-size:11px;color:#888">9:1${Math.floor(Math.random()*9)}</span></div>`).join('')}</div></body>`,
 'Screenshot_20261011-201244_WhatsApp': `<body style="background:#efe7de">${sb('20:12','#fff').replace('class="sb"','class="sb" style="background:#0b6b5a;color:#fff"')}
  <div class="row" style="background:#0b6b5a;color:#fff;padding:6px 16px 14px"><div class="av" style="width:40px;height:40px;background:#8fb7ff"></div><div style="margin-left:12px"><div style="font-weight:700;font-size:17px">Weekend trip</div><div style="font-size:13px;opacity:.8">Abel, Sara, Liya, You</div></div></div>
  <div style="padding:16px 12px;display:flex;flex-direction:column;gap:8px;font-size:15px;line-height:1.35">
   <div style="align-self:flex-start;background:#fff;padding:6px;border-radius:12px;width:240px"><div style="height:130px;border-radius:8px;background:#7cc24a"></div><div style="padding:6px 4px 2px;font-weight:600">Entoto Park</div><div style="padding:0 4px;color:#666;font-size:13px">Meet here at 8:00</div></div>
   ${[['l','Sara','Who\'s bringing snacks?'],['r','','I got the drinks'],['l','Liya','I\'ll bring sandwiches'],['l','Abel','Leaving at 7:30 sharp!!'],['r','','Perfect, see you there']].map(([s,n,t])=>`<div style="align-self:${s=='l'?'flex-start':'flex-end'};max-width:78%;background:${s=='l'?'#fff':'#d8fdd2'};padding:8px 12px;border-radius:12px">${n?`<div style="color:#c2185b;font-size:13px;font-weight:700">${n}</div>`:''}${t}</div>`).join('')}</div></body>`,
 // Article in a browser
 'Screenshot_20261010-143010_Chrome': `<body style="background:#fff">${sb('14:30')}
  <div style="margin:4px 12px 10px;background:#f1f3f4;border-radius:22px;padding:10px 16px;font-size:14px;color:#555">dailyreads.co/productivity</div>
  <div style="padding:8px 20px"><div style="color:#6c4dff;font-weight:700;font-size:13px;letter-spacing:1px">PRODUCTIVITY</div>
  <div style="font-family:Georgia,serif;font-size:30px;line-height:1.15;font-weight:700;margin:8px 0 12px">7 small habits that make every morning easier</div>
  <div style="color:#777;font-size:13px">By Hana T. · 6 min read</div>
  <div style="height:190px;border-radius:14px;margin:16px 0;background:#ffa877"></div>
  <p style="font-family:Georgia,serif;font-size:17px;line-height:1.55;color:#222">1. <b>Lay out tomorrow tonight.</b> Picking clothes and packing your bag before bed removes a dozen tiny decisions from your morning.</p>
  <p style="font-family:Georgia,serif;font-size:17px;line-height:1.55;color:#222;margin-top:12px">2. <b>Water before coffee.</b> A full glass first thing wakes you up faster than you think.</p></div></body>`,
 'Screenshot_20261009-190533_Chrome': `<body style="background:#fffaf3">${sb('19:05')}
  <div style="margin:4px 12px 10px;background:#f1ece4;border-radius:22px;padding:10px 16px;font-size:14px;color:#555">cookwell.com/shiro</div>
  <div style="height:230px;background:#f3e3cc;display:grid;place-items:center"><div style="width:150px;height:150px;border-radius:50%;background:#e2a04a;border:22px solid #b4642a"></div><div style="display:none"></div>
  <div style="padding:16px 20px"><div style="font-size:28px;font-weight:800;letter-spacing:-.5px">Weeknight shiro</div>
  <div class="row" style="gap:16px;color:#8a6d4b;font-size:14px;margin:8px 0 16px"><span>25 min</span><span>4 servings</span><span>4.9 rating</span></div>
  <div style="font-weight:700;margin-bottom:8px">Ingredients</div>
  ${['1 cup shiro powder','2 red onions, finely chopped','3 tbsp oil','4 garlic cloves','2 tomatoes','Salt to taste'].map(i=>`<div class="row" style="padding:9px 0;border-bottom:1px solid #eee3d3;font-size:15px"><span style="width:18px;height:18px;border:2px solid #d9a35f;border-radius:5px;margin-right:12px"></span>${i}</div>`).join('')}</div></body>`,
 // Maps
 'Screenshot_20261008-081210_Maps': `<body style="background:#e8eef0">${sb('8:12')}
  <div style="position:absolute;top:44px;left:0;right:0;bottom:250px;background:
   linear-gradient(90deg,transparent 47%,#fff 47% 53%,transparent 53%),linear-gradient(0deg,transparent 30%,#fff 30% 34%,transparent 34%),linear-gradient(30deg,transparent 60%,#fff 60% 63%,transparent 63%),#e5eae0"></div>
  <svg style="position:absolute;top:44px;left:0" width="390" height="550"><path d="M80 470 C 120 380, 190 360, 195 280 S 260 160, 300 90" stroke="#4285f4" stroke-width="8" fill="none" stroke-linecap="round"/><circle cx="80" cy="470" r="10" fill="#fff" stroke="#4285f4" stroke-width="5"/><circle cx="300" cy="90" r="12" fill="#ea4335"/></svg>
  <div style="position:absolute;top:56px;left:14px;right:14px;background:#fff;border-radius:16px;padding:14px 16px;box-shadow:0 4px 14px rgba(0,0,0,.12);font-size:15px">Bole International Airport</div>
  <div style="position:absolute;left:0;right:0;bottom:0;height:260px;background:#fff;border-radius:22px 22px 0 0;padding:22px;box-shadow:0 -4px 20px rgba(0,0,0,.08)">
   <div style="font-size:26px;font-weight:800;color:#188038">24 min <span style="color:#555;font-weight:500;font-size:18px">(11 km)</span></div>
   <div style="color:#666;margin:6px 0 18px">Fastest route, usual traffic</div>
   <div class="row" style="gap:10px"><div style="background:#1a73e8;color:#fff;padding:12px 22px;border-radius:22px;font-weight:700">Start</div><div style="border:1px solid #ccc;padding:12px 18px;border-radius:22px;color:#1a73e8;font-weight:600">Steps</div></div></div></body>`,
 // Instagram-ish post
 'Screenshot_20261007-221804_Instagram': `<body style="background:#fff">${sb('22:18')}
  <div class="row" style="padding:8px 14px;gap:10px"><div class="av" style="width:36px;height:36px;background:#d62976;padding:2px"><div style="width:100%;height:100%;border-radius:50%;background:#7aa7c7;border:2px solid #fff"></div></div><div style="font-weight:700;font-size:14px">addis.sunsets</div></div>
  <div style="height:390px;background:#3a1a5c;position:relative"><div style="position:absolute;left:50%;top:58%;width:120px;height:120px;margin-left:-60px;border-radius:50%;background:#ffd56b;"></div><div style="position:absolute;bottom:0;left:0;right:0;height:110px;background:#1d0c2e;clip-path:polygon(0 60%,15% 30%,30% 55%,48% 20%,65% 50%,80% 25%,100% 55%,100% 100%,0 100%)"></div></div>
  <div class="row" style="padding:14px;gap:18px">${['M12 21s-7-4.5-9.5-9A5.5 5.5 0 0 1 12 6a5.5 5.5 0 0 1 9.5 6c-2.5 4.5-9.5 9-9.5 9z','M4 5h16v11H8l-4 4z','M4 12l16-8-6 16-3-6z'].map(d=>`<svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#111" stroke-width="2" stroke-linejoin="round"><path d="${d}"/></svg>`).join('')}</div>
  <div style="padding:0 14px;font-size:14px"><b>2,481 likes</b><div style="margin-top:6px"><b>addis.sunsets</b> golden hour from the hills tonight</div><div style="color:#999;margin-top:6px">View all 96 comments</div></div></body>`,
 // Music player
 'Screenshot_20261006-171932_Spotify': `<body style="background:#1a1424;color:#fff">${sb('17:19','#fff')}
  <div style="text-align:center;font-size:12px;letter-spacing:1px;opacity:.8;margin-top:8px">PLAYING FROM PLAYLIST<div style="font-weight:700;opacity:1;letter-spacing:0;font-size:14px;margin-top:2px">Late night drives</div></div>
  <div style="margin:34px 34px 30px;height:322px;border-radius:8px;background:#ff7a93;box-shadow:0 20px 50px rgba(0,0,0,.5)"></div>
  <div style="padding:0 34px"><div style="font-size:24px;font-weight:800">Golden Hour</div><div style="opacity:.7;font-size:16px;margin-top:4px">Mimi & the Bells</div>
  <div style="height:4px;background:rgba(255,255,255,.3);border-radius:2px;margin:26px 0 8px"><div style="width:42%;height:100%;background:#fff;border-radius:2px"></div></div>
  <div class="row" style="justify-content:space-between;font-size:12px;opacity:.7"><span>1:34</span><span>3:41</span></div>
  <div class="row" style="justify-content:space-between;margin-top:22px">
   <svg width="26" height="26" viewBox="0 0 24 24" fill="#fff"><path d="M18 6v12h-2V6zM4 6l11 6-11 6z" transform="matrix(-1 0 0 1 24 0)"/></svg>
   <span style="width:66px;height:66px;border-radius:50%;background:#fff;display:flex;align-items:center;justify-content:center;gap:6px"><i style="width:6px;height:22px;background:#000;border-radius:2px"></i><i style="width:6px;height:22px;background:#000;border-radius:2px"></i></span>
   <svg width="26" height="26" viewBox="0 0 24 24" fill="#fff"><path d="M18 6v12h-2V6zM4 6l11 6-11 6z"/></svg></div></div></body>`,
 // Bank receipt
 'Screenshot_20261005-110245_Bank': `<body style="background:#f4f6fb">${sb('11:02')}
  <div style="text-align:center;padding:40px 24px 0"><div style="width:76px;height:76px;border-radius:50%;background:#20c997;margin:0 auto;display:grid;place-items:center"><svg width="40" height="40" viewBox="0 0 24 24" fill="none" stroke="#fff" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M5 12.5l4.5 4.5L19 7.5"/></svg></div>
  <div style="font-size:22px;font-weight:800;margin-top:18px">Transfer successful</div><div style="color:#777;margin-top:6px">Oct 5, 2026 · 11:02 AM</div>
  <div style="font-size:44px;font-weight:800;margin:26px 0 6px;letter-spacing:-1px">ETB 2,450.00</div></div>
  <div style="margin:20px;background:#fff;border-radius:18px;padding:6px 18px">${[['To','Sara Bekele'],['Account','1000 •••• 4821'],['Reference','Rent share – Oct'],['Fee','ETB 0.00'],['Transaction ID','FT26278QX91']].map(([k,v])=>`<div class="row" style="justify-content:space-between;padding:14px 0;border-bottom:1px solid #eef0f5;font-size:15px"><span style="color:#888">${k}</span><b>${v}</b></div>`).join('')}</div>
  <div style="margin:0 20px;background:#2b59ff;color:#fff;text-align:center;padding:16px;border-radius:16px;font-weight:700">Share receipt</div></body>`,
 // Boarding pass in mail
 'Screenshot_20261003-063015_Gmail': `<body style="background:#fff">${sb('6:30')}
  <div style="padding:10px 18px"><div style="font-size:22px;font-weight:700">Your boarding pass</div><div class="row" style="margin:14px 0;gap:12px"><div class="av" style="width:38px;height:38px;background:#2e7d32"></div><div style="font-size:14px"><b>Skyline Air</b><div style="color:#777">to me · 6:28 AM</div></div></div></div>
  <div style="margin:0 18px;border-radius:20px;overflow:hidden;box-shadow:0 6px 20px rgba(0,0,0,.12)"><div style="background:#14532d;color:#fff;padding:20px"><div class="row" style="justify-content:space-between;font-size:40px;font-weight:800"><span>ADD</span><span style="font-size:22px;opacity:.8">to</span><span>NBO</span></div><div class="row" style="justify-content:space-between;opacity:.8;font-size:13px"><span>Addis Ababa</span><span>Nairobi</span></div></div>
  <div style="padding:18px 20px;display:grid;grid-template-columns:1fr 1fr 1fr;gap:14px;font-size:12px;color:#888">${[['FLIGHT','SA 304'],['GATE','B12'],['SEAT','14A'],['BOARDING','07:45'],['DATE','03 OCT'],['GROUP','2']].map(([k,v])=>`<div>${k}<div style="color:#111;font-size:18px;font-weight:800;margin-top:2px">${v}</div></div>`).join('')}</div>
  <div style="margin:4px 20px 20px;height:70px;background:repeating-linear-gradient(90deg,#111 0 3px,#fff 3px 5px,#111 5px 6px,#fff 6px 9px)"></div></div></body>`,
 // Social post
 'Screenshot_20261002-213355_X': `<body style="background:#fff">${sb('21:33')}
  <div style="padding:10px 16px;font-weight:800;font-size:19px;border-bottom:1px solid #eee">Post</div>
  <div style="padding:16px"><div class="row" style="gap:10px"><div class="av" style="width:44px;height:44px;background:#ffb23f"></div><div><b>Dev Tips</b><div style="color:#666;font-size:14px">@devtips</div></div></div>
  <div style="font-size:21px;line-height:1.35;margin:14px 0">Reminder: the best time to write the README is while you still remember why you made the decisions.<br><br>Future you will be grateful.</div>
  <div style="color:#666;font-size:14px;padding-bottom:12px;border-bottom:1px solid #eee">9:33 PM · Oct 2, 2026 · <b style="color:#111">48.2K</b> views</div>
  <div style="padding:12px 0;font-size:14px;border-bottom:1px solid #eee"><b>1,204</b> Reposts &nbsp; <b>8,930</b> Likes &nbsp; <b>312</b> Bookmarks</div>
  ${[1,2].map(()=>`<div class="row" style="gap:10px;padding:14px 0;border-bottom:1px solid #eee;align-items:flex-start"><div class="av" style="width:38px;height:38px;background:#c9d6ff"></div><div style="flex:1"><div class="line" style="width:40%"></div><div class="line" style="width:95%"></div><div class="line" style="width:70%"></div></div></div>`).join('')}</div></body>`,
 // Calendar
 'Screenshot_20260928-090102_Calendar': `<body style="background:#fff">${sb('9:01')}
  <div style="padding:8px 20px 14px;font-size:28px;font-weight:800">September</div>
  <div class="row" style="padding:0 12px;justify-content:space-around;font-size:13px;color:#888">${['M','T','W','T','F','S','S'].map((d,i)=>`<div style="text-align:center">${d}<div style="margin-top:6px;width:34px;height:34px;border-radius:50%;line-height:34px;font-size:16px;font-weight:700;${i==0?'background:#6c4dff;color:#fff':'color:#111'}">${28+i>30?28+i-30:28+i}</div></div>`).join('')}</div>
  <div style="padding:18px 16px;display:flex;flex-direction:column;gap:10px">${[['09:30','Team standup','#6c4dff'],['11:00','Dentist','#ff5e8e'],['13:00','Lunch with Liya','#ffb23f'],['15:30','Design review','#2ec4a6'],['18:00','Gym','#4b8bff']].map(([t,n,c])=>`<div class="row" style="gap:14px"><div style="width:48px;color:#888;font-size:13px">${t}</div><div style="flex:1;background:${c}22;border-left:4px solid ${c};border-radius:10px;padding:14px;font-weight:700">${n}</div></div>`).join('')}</div></body>`,
 // Notes checklist
 'Screenshot_20260924-184420_Keep': `<body style="background:#fff8e1">${sb('18:44')}
  <div style="padding:16px 22px"><div style="font-size:26px;font-weight:800">Moving checklist</div><div style="color:#9a8a5a;margin-top:4px;font-size:14px">Edited yesterday</div>
  ${[['Book the van',1],['Pack the kitchen',1],['Cancel old internet',1],['Change address at bank',0],['Clean the old flat',0],['Buy curtains',0],['Housewarming invites',0]].map(([t,d])=>`<div class="row" style="padding:12px 0;font-size:17px;${d?'color:#a39b80;text-decoration:line-through':''}"><span style="width:22px;height:22px;border-radius:6px;margin-right:14px;border:2px solid #c8b26b;${d?'background:#c8b26b':''}"></span>${t}</div>`).join('')}</div></body>`,
 // Settings
 'Screenshot_20260915-120931': `<body style="background:#f2f2f7">${sb('12:09')}
  <div style="padding:10px 20px;font-size:30px;font-weight:800">Storage</div>
  <div style="margin:10px 16px;background:#fff;border-radius:18px;padding:18px"><div style="font-size:15px;color:#666">96.4 GB of 128 GB used</div><div class="row" style="height:14px;border-radius:7px;overflow:hidden;margin:12px 0"><div style="width:34%;height:100%;background:#ff5e8e"></div><div style="width:22%;height:100%;background:#6c4dff"></div><div style="width:12%;height:100%;background:#ffb23f"></div><div style="width:7%;height:100%;background:#2ec4a6"></div></div>
  ${[['Photos','32.8 GB','#ff5e8e'],['Apps','21.2 GB','#6c4dff'],['Music','11.5 GB','#ffb23f'],['Documents','6.9 GB','#2ec4a6']].map(([n,s,c])=>`<div class="row" style="justify-content:space-between;padding:10px 0;font-size:15px"><span class="row"><span style="width:10px;height:10px;border-radius:50%;background:${c};margin-right:10px"></span>${n}</span><b>${s}</b></div>`).join('')}</div></body>`,
};
(async () => {
  const b = await chromium.launch(process.env.CHROMIUM ? { executablePath: process.env.CHROMIUM } : {});
  const p = await b.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 2 });
  for (const [name, body] of Object.entries(screens)) {
    await p.setContent(`<html><head><style>${base}</style></head>${body}</html>`);
    await p.screenshot({ path: `${out}/${name}.jpg`, type: 'jpeg', quality: 72 });
  }
  await b.close();
})();
