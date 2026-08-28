const resourceName = (() => {
  try { return GetParentResourceName(); } catch { return null; }
})();

const inFiveM = Boolean(resourceName);
const app = document.getElementById('app');
const content = document.getElementById('content');
const stats = document.getElementById('stats');
const tabsEl = document.getElementById('tabs');
const search = document.getElementById('search');
const toastEl = document.getElementById('toast');
const playerNameEl = document.getElementById('player-name');
const playerAvatarEl = document.getElementById('player-avatar');
const subtitleEl = document.getElementById('shop-subtitle');

const ICONS = {
  rods: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 20 20 4"/><path d="M14 4h6v6"/><path d="M4 20c2-3 6-3 8 0"/></svg>',
  reels: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="7"/><circle cx="12" cy="12" r="2"/><path d="M12 5v3M12 16v3M5 12h3M16 12h3"/></svg>',
  line: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M5 19c8-2 6-8 14-10"/><circle cx="5" cy="19" r="2"/><circle cx="19" cy="9" r="2"/></svg>',
  bait: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 13c6-8 14-8 16 0-2 4-6 6-8 6s-6-2-8-6z"/><circle cx="15" cy="11" r="1"/></svg>',
  fish: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 12s5-6 11-6c5 0 7 6 7 6s-2 6-7 6c-6 0-11-6-11-6z"/><path d="M3 12l4 4M3 12l4-4"/><circle cx="16" cy="12" r="1"/></svg>',
};

function itemImage(name) {
  if (inFiveM) return `nui://${resourceName}/images/${name}.png`;
  return `../images/${name}.png`;
}

function iconFor(item) {
  return `<img src="${itemImage(item.item)}" alt="${item.label || item.item}" />`;
}

const CATEGORIES = [
  { id: 'all', label: 'All gear' },
  { id: 'rods', label: 'Rods' },
  { id: 'reels', label: 'Reels' },
  { id: 'line', label: 'Line' },
  { id: 'bait', label: 'Bait' },
];

const SELL_TABS = [
  { id: 'all', label: 'All catch' },
  { id: 'ocean', label: 'Ocean' },
  { id: 'lake', label: 'Lakes' },
  { id: 'river', label: 'Rivers' },
];

const DEMO = {
  ok: true,
  player: { name: 'MoodyNewt8638', cash: 12450 },
  catalog: [
    { item: 'fishing_rod_basic', label: 'Driftwood Rod', description: 'A shoreline rod that will get you started. Low luck for trophy fish.', category: 'rods', price: 175, uses: 200 },
    { item: 'fishing_rod_pro', label: 'Carbon Rod', description: 'Lighter blank with better hook-sets. Improves rare catch rates.', category: 'rods', price: 520, uses: 450 },
    { item: 'fishing_rod_elite', label: 'Offshore Rod', description: 'Heavy-action rod built for marlin and shark. Highest rare luck.', category: 'rods', price: 1450, uses: 750 },
    { item: 'fishing_reel_basic', label: 'Spin Reel', description: 'Reliable spinning reel. Keeps line tension, no extra assist.', category: 'reels', price: 125, uses: 250 },
    { item: 'fishing_reel_pro', label: 'Baitcaster', description: 'Smoother drag. Makes skill checks a little more forgiving.', category: 'reels', price: 380, uses: 500 },
    { item: 'fishing_reel_elite', label: 'Tournament Reel', description: 'Saltwater drag system. Biggest skill-check window in the kit.', category: 'reels', price: 980, uses: 850 },
    { item: 'fishing_line', label: 'Fishing Line', description: 'Mono spool. Each spool lasts 20 bites before you need another.', category: 'line', price: 4, uses: 20 },
    { item: 'bait_ocean', label: 'Ocean Bait', description: 'Cut squid and oily chunks. Required to fish the ocean.', category: 'bait', price: 8 },
    { item: 'bait_lake', label: 'Lake Bait', description: 'Live worms and panfish jigs. Required on lakes.', category: 'bait', price: 5 },
    { item: 'bait_river', label: 'River Bait', description: 'Roe sacks and spinner bait. Required on rivers.', category: 'bait', price: 6 },
  ],
  fish: [
    { item: 'fish_sardine', label: 'Sardine', description: 'Dense schooling baitfish. Easy money on the coast.', zone: 'ocean', rarity: 'common', price: 15, count: 6 },
    { item: 'fish_rockfish', label: 'Rockfish', description: 'Bottom dweller around pilings and reefs.', zone: 'ocean', rarity: 'common', price: 32, count: 3 },
    { item: 'fish_tuna', label: 'Tuna', description: 'Fast pelagic. Puts a real bend in the rod.', zone: 'ocean', rarity: 'uncommon', price: 95, count: 1 },
    { item: 'fish_bluegill', label: 'Bluegill', description: 'Panfish stacked under docks and weeds.', zone: 'lake', rarity: 'common', price: 12, count: 4 },
    { item: 'fish_largemouth_bass', label: 'Largemouth Bass', description: 'Ambush predator in the pads.', zone: 'lake', rarity: 'uncommon', price: 52, count: 2 },
    { item: 'fish_salmon', label: 'Salmon', description: 'Runs the current. Staple river paycheck.', zone: 'river', rarity: 'uncommon', price: 58, count: 2 },
    { item: 'fish_striper', label: 'Striper', description: 'Striped bass pushing up from the estuary.', zone: 'river', rarity: 'rare', price: 96, count: 1 },
  ],
  equipment: {
    fishing_rod_basic: 1,
    fishing_reel_basic: 1,
    fishing_line: 14,
    bait_ocean: 9,
    bait_lake: 4,
    bait_river: 2,
  },
  tasks: [
    { id: 'catch_any', label: 'Fill the cooler', description: 'Land 8 fish of any kind today.', count: 8, progress: 5, claimed: false, reward: 175, rewardItems: [] },
    { id: 'catch_ocean', label: 'Saltwater run', description: 'Catch 5 ocean fish.', count: 5, progress: 5, claimed: false, reward: 200, rewardItems: [] },
    { id: 'catch_offshore', label: 'Go offshore', description: 'Catch 3 fish at an offshore hotspot.', count: 3, progress: 1, claimed: false, reward: 275, rewardItems: [] },
    { id: 'catch_trophy', label: 'Trophy hunt', description: 'Land a rare or legendary fish.', count: 1, progress: 0, claimed: false, reward: 400, rewardItems: [{ item: 'bait_ocean', count: 5, label: 'Ocean Bait' }] },
    { id: 'sell_cash', label: 'Cash out', description: 'Sell $400 worth of fish today.', count: 400, progress: 210, claimed: false, reward: 125, rewardItems: [] },
    { id: 'rent_boat', label: 'Launch a skiff', description: 'Rent a boat from any fishing dock.', count: 1, progress: 1, claimed: true, reward: 75, rewardItems: [] },
  ],
  board: {
    dailyFish: { rows: [{ rank: 1, name: 'MoodyNewt8638', value: 18, me: true }, { rank: 2, name: 'Kai', value: 14 }, { rank: 3, name: 'Reese', value: 9 }], you: { rank: 1, value: 18 } },
    dailyMoney: { rows: [{ rank: 1, name: 'Kai', value: 1240 }, { rank: 2, name: 'MoodyNewt8638', value: 980, me: true }, { rank: 3, name: 'Reese', value: 410 }], you: { rank: 2, value: 980 } },
    fish: { rows: [{ rank: 1, name: 'Kai', value: 220 }, { rank: 2, name: 'MoodyNewt8638', value: 87, me: true }], you: { rank: 2, value: 87 } },
    money: { rows: [{ rank: 1, name: 'Kai', value: 18400 }, { rank: 2, name: 'MoodyNewt8638', value: 6120, me: true }], you: { rank: 2, value: 6120 } },
  },
  you: { fish: 87, money: 6120, dailyFish: 18, dailyMoney: 980 },
  resetsIn: 14600,
};

const BOARD_TABS = [
  { id: 'today', label: 'Today' },
  { id: 'all', label: 'All time' },
];

const state = {
  view: 'shop',
  tab: 'all',
  query: '',
  qty: {},
  shop: { label: 'Del Perro Tackle', subtitle: 'Ocean outfitter', views: ['shop', 'sell', 'tasks', 'board'] },
  player: { name: 'Angler', cash: 0 },
  catalog: [],
  fish: [],
  equipment: {},
  tasks: [],
  board: { dailyFish: { rows: [] }, dailyMoney: { rows: [] }, fish: { rows: [] }, money: { rows: [] } },
  you: { fish: 0, money: 0, dailyFish: 0, dailyMoney: 0 },
  resetsIn: 0,
  busy: false,
};

function money(n) {
  return '$' + Math.floor(Number(n) || 0).toLocaleString('en-US');
}

function escapeHtml(value) {
  return String(value ?? '').replace(/[&<>"']/g, (ch) => ({
    '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;',
  }[ch]));
}

function initials(name) {
  return (name || 'DJ').split(/\s+/).map((p) => p[0]).join('').slice(0, 2).toUpperCase();
}

function toast(message) {
  toastEl.textContent = message;
  toastEl.classList.remove('hidden');
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => toastEl.classList.add('hidden'), 2200);
}

async function nui(name, payload = {}) {
  if (!inFiveM) return mockNui(name, payload);
  const res = await fetch(`https://${resourceName}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(payload),
  });
  try { return await res.json(); } catch { return { ok: false }; }
}

function mockNui(name, payload) {
  if (name === 'close') return { ok: true };
  if (name === 'buy') {
    const item = state.catalog.find((i) => i.item === payload.item);
    const amount = payload.amount || 1;
    const total = item.price * amount;
    if (state.player.cash < total) return { ok: false, error: 'notify_no_money' };
    state.player.cash -= total;
    state.equipment[item.item] = (state.equipment[item.item] || 0) + amount;
    return { ok: true, amount, label: item.label, total, refresh: currentPayload() };
  }
  if (name === 'sell') {
    const fish = state.fish.find((i) => i.item === payload.item);
    const amount = Math.min(payload.amount || 1, fish.count);
    fish.count -= amount;
    const total = fish.price * amount;
    state.player.cash += total;
    state.fish = state.fish.filter((f) => f.count > 0);
    return { ok: true, amount, label: fish.label, total, refresh: currentPayload() };
  }
  if (name === 'sellAll') {
    const total = state.fish.reduce((sum, f) => sum + f.price * f.count, 0);
    state.player.cash += total;
    state.fish = [];
    return { ok: true, total, refresh: currentPayload() };
  }
  if (name === 'claimTask') {
    const task = state.tasks.find((t) => t.id === payload.id);
    if (!task || task.claimed || task.progress < task.count) return { ok: false };
    task.claimed = true;
    state.player.cash += task.reward || 0;
    return { ok: true, money: task.reward, label: task.label, refresh: currentPayload() };
  }
  return currentPayload();
}

function currentPayload() {
  return {
    ok: true,
    player: state.player,
    catalog: state.catalog,
    fish: state.fish,
    equipment: state.equipment,
    tasks: state.tasks,
    board: state.board,
    you: state.you,
    resetsIn: state.resetsIn,
  };
}

function toArray(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return Object.keys(value)
    .sort((a, b) => Number(a) - Number(b))
    .map((key) => value[key])
    .filter((entry) => entry && typeof entry === 'object' && (entry.item || entry.label));
}

function applyPayload(payload) {
  if (!payload || payload.ok === false) return;

  if (payload.player) {
    state.player = {
      name: payload.player.name || state.player.name,
      cash: Number(payload.player.cash || 0),
    };
  }

  const catalog = toArray(payload.catalog);
  if (catalog.length) state.catalog = catalog;

  state.fish = toArray(payload.fish);
  state.equipment = payload.equipment && !Array.isArray(payload.equipment)
    ? payload.equipment
    : (payload.equipment || {});

  if (payload.tasks) state.tasks = toArray(payload.tasks);
  if (payload.board) state.board = payload.board;
  if (payload.you) state.you = payload.you;
  if (payload.resetsIn != null) state.resetsIn = Number(payload.resetsIn) || 0;

  playerNameEl.textContent = state.player.name;
  playerAvatarEl.textContent = initials(state.player.name);
  render();
}

function setView(view) {
  state.view = view;
  state.tab = view === 'board' ? 'today' : 'all';
  state.query = '';
  search.value = '';
  document.querySelectorAll('.nav-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.view === view);
  });
  render();
}

function ownedCount(item) {
  if (state.view === 'shop') return state.equipment[item] || 0;
  const fish = state.fish.find((f) => f.item === item);
  return fish ? fish.count : 0;
}

function qtyFor(item, max) {
  const current = state.qty[item] || 1;
  return Math.max(1, Math.min(max || 50, current));
}

function countOwned(predicate) {
  return state.catalog.reduce((sum, item) => {
    if (!predicate(item)) return sum;
    return sum + (state.equipment[item.item] || 0);
  }, 0);
}

function formatReset(seconds) {
  seconds = Math.max(0, Math.floor(Number(seconds) || 0));
  const h = Math.floor(seconds / 3600);
  const m = Math.floor((seconds % 3600) / 60);
  if (h > 0) return `${h}h ${m}m`;
  return `${m}m`;
}

function rankLabel(rank) {
  return rank ? `#${rank}` : '—';
}

function renderStats() {
  const gear = countOwned((item) => item.category !== 'bait');
  const bait = countOwned((item) => item.category === 'bait');
  const fishCount = state.fish.reduce((a, f) => a + f.count, 0);
  const value = state.fish.reduce((a, f) => a + f.price * f.count, 0);
  const done = state.tasks.filter((t) => t.progress >= t.count).length;
  const claimed = state.tasks.filter((t) => t.claimed).length;

  let cards;
  if (state.view === 'shop') {
    cards = [
      { label: 'Cash on hand', value: money(state.player.cash), hint: 'WALLET' },
      { label: 'Tackle owned', value: String(gear), hint: 'GEAR' },
      { label: 'Bait remaining', value: String(bait), hint: 'BAIT' },
    ];
  } else if (state.view === 'sell') {
    cards = [
      { label: 'Cash on hand', value: money(state.player.cash), hint: 'WALLET' },
      { label: 'Fish in pack', value: String(fishCount), hint: 'CATCH' },
      { label: 'Market value', value: money(value), hint: 'PAYOUT' },
    ];
  } else if (state.view === 'tasks') {
    cards = [
      { label: 'Tasks done', value: `${done}/${state.tasks.length || 0}`, hint: 'TODAY' },
      { label: 'Rewards claimed', value: String(claimed), hint: 'CLAIMED' },
      { label: 'Resets in', value: formatReset(state.resetsIn), hint: 'DAILY' },
    ];
  } else {
    cards = [
      { label: 'Fish today', value: String(state.you.dailyFish || 0), hint: 'CATCH' },
      { label: 'Sold today', value: money(state.you.dailyMoney || 0), hint: 'CASH' },
      { label: 'Your fish rank', value: rankLabel(state.board.dailyFish && state.board.dailyFish.you && state.board.dailyFish.you.rank), hint: 'TODAY' },
    ];
  }

  stats.innerHTML = cards.map((c) => `
    <article class="stat">
      <span>${c.label}</span>
      <strong>${c.value}</strong>
      <em>${c.hint}</em>
    </article>
  `).join('');
}

function renderTabs() {
  const toolbar = document.querySelector('.toolbar');
  toolbar.classList.toggle('search-hidden', state.view === 'tasks' || state.view === 'board');

  let tabs;
  if (state.view === 'shop') tabs = CATEGORIES;
  else if (state.view === 'sell') tabs = SELL_TABS;
  else if (state.view === 'board') tabs = BOARD_TABS;
  else tabs = [];

  tabsEl.innerHTML = tabs.map((tab) => `
    <button type="button" class="tab ${state.tab === tab.id ? 'active' : ''}" data-tab="${tab.id}">${tab.label}</button>
  `).join('') + (state.view === 'sell' ? '<button type="button" class="tab" data-tab="sellall">Sell all</button>' : '');
}

function matchesQuery(item) {
  const q = state.query.trim().toLowerCase();
  if (!q) return true;
  return `${item.label} ${item.description} ${item.item} ${item.zone || ''} ${item.category || ''}`.toLowerCase().includes(q);
}

function renderShop() {
  const items = state.catalog.filter((item) => (state.tab === 'all' || item.category === state.tab) && matchesQuery(item));
  if (!items.length) {
    content.innerHTML = `<div class="empty"><strong>No gear matches</strong><p>Try another tab or search.</p></div>`;
    return;
  }

  content.innerHTML = items.map((item) => {
    const qty = qtyFor(item.item, 50);
    const owned = ownedCount(item.item);
    return `
      <article class="card" data-item="${item.item}">
        <div class="card-head">
          <div class="icon">${iconFor(item)}</div>
          <span class="badge">${item.category}</span>
        </div>
        <div>
          <h3>${item.label}</h3>
          <p>${item.description}</p>
        </div>
        <div class="meta-row">
          <div class="price">${money(item.price)} <span>each</span></div>
          <span class="badge">Owned ${owned}${item.uses ? ` · ${item.uses} uses` : ''}</span>
        </div>
        <div class="buy-row">
          <div class="qty">
            <button type="button" data-act="minus">-</button>
            <b>${qty}</b>
            <button type="button" data-act="plus">+</button>
          </div>
          <button type="button" class="btn" data-act="buy">${money(item.price * qty)} · Buy</button>
        </div>
      </article>
    `;
  }).join('');
}

function renderSell() {
  const items = state.fish.filter((item) => (state.tab === 'all' || item.zone === state.tab) && matchesQuery(item));
  if (!items.length) {
    content.innerHTML = `<div class="empty"><div class="icon">${ICONS.fish}</div><strong>No fish in your pack</strong><p>Hit the ocean, lakes, or rivers, then sell here.</p></div>`;
    return;
  }

  content.innerHTML = items.map((item) => {
    const qty = qtyFor(item.item, item.count);
    return `
      <article class="card" data-item="${item.item}">
        <div class="card-head">
          <div class="icon">${iconFor(item)}</div>
          <span class="badge ${item.rarity}">${item.rarity} · ${item.zone}</span>
        </div>
        <div>
          <h3>${item.label}</h3>
          <p>${item.description}</p>
        </div>
        <div class="meta-row">
          <div class="price">${money(item.price)} <span>each</span></div>
          <span class="badge">x${item.count} · ${money(item.price * item.count)}</span>
        </div>
        <div class="sell-row">
          <div class="qty">
            <button type="button" data-act="minus">-</button>
            <b>${qty}</b>
            <button type="button" data-act="plus">+</button>
          </div>
          <button type="button" class="btn ghost" data-act="sellone">Sell ${qty}</button>
          <button type="button" class="btn" data-act="sellstack">Sell all</button>
        </div>
      </article>
    `;
  }).join('');
}

function renderTasks() {
  const items = state.tasks.filter((item) => matchesQuery(item));
  if (!items.length) {
    content.innerHTML = `<div class="empty"><strong>No daily tasks</strong><p>Come back after the next reset.</p></div>`;
    return;
  }

  content.innerHTML = items.map((task) => {
    const pct = Math.min(100, Math.round(((task.progress || 0) / (task.count || 1)) * 100));
    const ready = !task.claimed && (task.progress || 0) >= task.count;
    const extras = (task.rewardItems || []).map((item) => `${item.count}x ${item.label}`).join(', ');
    let action = `<button type="button" class="btn" disabled>In progress</button>`;
    if (task.claimed) action = `<button type="button" class="btn ghost" disabled>Claimed</button>`;
    else if (ready) action = `<button type="button" class="btn" data-act="claim">Claim ${money(task.reward)}</button>`;
    return `
      <article class="card task-card" data-task="${task.id}">
        <div class="card-head">
          <div class="icon">${ICONS.fish}</div>
          <span class="badge ${task.claimed ? 'uncommon' : ready ? 'legendary' : ''}">${task.progress}/${task.count}</span>
        </div>
        <div>
          <h3>${task.label}</h3>
          <p>${task.description}</p>
        </div>
        <div class="bar"><i style="width:${pct}%"></i></div>
        <div class="meta-row">
          <div class="price">${money(task.reward)} <span>reward</span></div>
          <span class="badge">${extras || 'Cash'}</span>
        </div>
        ${action}
      </article>
    `;
  }).join('');
}

function renderBoard() {
  const daily = state.tab !== 'all';
  const fish = daily ? state.board.dailyFish : state.board.fish;
  const cash = daily ? state.board.dailyMoney : state.board.money;
  const fishMoney = (block) => {
    const rows = (block && block.rows) || [];
    if (!rows.length) {
      return `<div class="empty" style="min-height:160px"><strong>No scores yet</strong><p>Catch or sell fish to appear here.</p></div>`;
    }
    const you = block.you || {};
    const isMoney = block === cash;
    return rows.map((row) => `
      <div class="board-row ${row.me ? 'me' : ''}">
        <b>${row.rank}</b>
        <span>${escapeHtml(row.name)}</span>
        <span class="value">${isMoney ? money(row.value) : row.value}</span>
      </div>
    `).join('') + `<div class="board-you">You · ${rankLabel(you.rank)} · ${isMoney ? money(you.value || 0) : (you.value || 0)}</div>`;
  };

  content.innerHTML = `
    <section class="board-col">
      <h3>Most fish ${daily ? 'today' : 'all time'}</h3>
      ${fishMoney(fish)}
    </section>
    <section class="board-col">
      <h3>Most money ${daily ? 'today' : 'all time'}</h3>
      ${fishMoney(cash)}
    </section>
  `;
}

function render() {
  subtitleEl.textContent = state.shop.subtitle || 'Tackle & market';
  content.classList.toggle('tasks-view', state.view === 'tasks');
  content.classList.toggle('board-view', state.view === 'board');
  renderStats();
  renderTabs();
  if (state.view === 'shop') renderShop();
  else if (state.view === 'sell') renderSell();
  else if (state.view === 'tasks') renderTasks();
  else renderBoard();
}

function openUI(payload) {
  payload = payload || {};
  if (payload.shop) state.shop = payload.shop;
  state.view = payload.view || 'shop';
  state.tab = state.view === 'board' ? 'today' : 'all';
  state.query = '';
  state.qty = {};
  search.value = '';
  applyPayload(payload);
  if (!state.catalog.length) state.catalog = DEMO.catalog;
  document.querySelectorAll('.nav-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.view === state.view);
  });
  app.classList.remove('hidden');
  app.setAttribute('aria-hidden', 'false');
  render();
}

function closeUI() {
  app.classList.add('hidden');
  app.setAttribute('aria-hidden', 'true');
  nui('close');
}

async function handleResult(result, fallback) {
  if (result && result.ok) {
    if (result.refresh) applyPayload(result.refresh);
    toast(fallback);
  } else {
    toast('That transaction did not go through.');
  }
}

document.getElementById('nav').addEventListener('click', (e) => {
  const btn = e.target.closest('.nav-btn');
  if (btn) setView(btn.dataset.view);
});

tabsEl.addEventListener('click', async (e) => {
  const btn = e.target.closest('.tab');
  if (!btn) return;
  if (btn.dataset.tab === 'sellall') {
    if (state.busy) return;
    state.busy = true;
    const result = await nui('sellAll');
    state.busy = false;
    await handleResult(result, result && result.ok ? `Sold catch for ${money(result.total)}` : '');
    return;
  }
  state.tab = btn.dataset.tab;
  render();
});

search.addEventListener('input', () => {
  state.query = search.value;
  render();
});

content.addEventListener('click', async (e) => {
  const card = e.target.closest('.card');
  const btn = e.target.closest('button');
  if (!card || !btn || state.busy) return;
  const act = btn.dataset.act;

  if (act === 'claim') {
    state.busy = true;
    const result = await nui('claimTask', { id: card.dataset.task });
    await handleResult(result, result && result.ok ? `Claimed ${result.label}` : '');
    state.busy = false;
    return;
  }

  const itemName = card.dataset.item;
  const item = state.view === 'shop'
    ? state.catalog.find((i) => i.item === itemName)
    : state.fish.find((i) => i.item === itemName);
  if (!item) return;

  const max = state.view === 'shop' ? 50 : item.count;
  if (act === 'minus') {
    state.qty[itemName] = Math.max(1, qtyFor(itemName, max) - 1);
    render();
    return;
  }
  if (act === 'plus') {
    state.qty[itemName] = Math.min(max, qtyFor(itemName, max) + 1);
    render();
    return;
  }

  state.busy = true;
  if (act === 'buy') {
    const amount = qtyFor(itemName, 50);
    const result = await nui('buy', { item: itemName, amount });
    await handleResult(result, result && result.ok ? `Purchased ${result.amount}x ${result.label}` : '');
  } else if (act === 'sellone') {
    const amount = qtyFor(itemName, item.count);
    const result = await nui('sell', { item: itemName, amount });
    await handleResult(result, result && result.ok ? `Sold ${result.amount}x ${result.label}` : '');
  } else if (act === 'sellstack') {
    const result = await nui('sell', { item: itemName, amount: item.count });
    await handleResult(result, result && result.ok ? `Sold ${result.amount}x ${result.label}` : '');
  }
  state.busy = false;
});

window.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !app.classList.contains('hidden')) {
    closeUI();
  }
});

window.addEventListener('message', (event) => {
  const msg = event.data || {};
  const action = msg.action;
  const data = msg.data || msg;
  if (action === 'open') openUI(data);
  if (action === 'close') {
    app.classList.add('hidden');
    app.setAttribute('aria-hidden', 'true');
  }
  if (action === 'update') applyPayload(data);
});

if (!inFiveM) {
  document.body.classList.add('preview');
  openUI({
    view: 'shop',
    shop: { label: 'Del Perro Tackle', subtitle: 'Ocean outfitter', views: ['shop', 'sell', 'tasks', 'board'] },
    ...DEMO,
  });
}
