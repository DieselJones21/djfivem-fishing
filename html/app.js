const resourceName = (() => {
  try { return GetParentResourceName(); } catch { return null; }
})();

const inFiveM = Boolean(resourceName);
const app = document.getElementById('app');
const content = document.getElementById('content');
const stats = document.getElementById('stats');
const tabsEl = document.getElementById('tabs');
const navEl = document.getElementById('nav');
const search = document.getElementById('search');
const toastEl = document.getElementById('toast');
const playerNameEl = document.getElementById('player-name');
const playerAvatarEl = document.getElementById('player-avatar');
const playerRoleEl = document.getElementById('player-role');
const titleEl = document.getElementById('shop-title');
const subtitleEl = document.getElementById('shop-subtitle');

const ICONS = {
  shop: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 7h16l-1.2 12.4A2 2 0 0 1 16.81 21H7.19a2 2 0 0 1-1.99-1.6L4 7z"/><path d="M8 7V5a4 4 0 0 1 8 0v2"/></svg>',
  sell: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 12c4-6 12-6 16 0-4 6-12 6-16 0z"/><circle cx="12" cy="12" r="2.2"/></svg>',
  tasks: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M9 11l3 3L22 4"/><path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11"/></svg>',
  board: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M4 19V5M4 19h16M8 15v4M12 11v8M16 8v11"/></svg>',
  fleet: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 17h18l-2-7H5l-2 7z"/><path d="M12 4 5 10h14L12 4z"/><path d="M4 20h16"/></svg>',
  active: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><circle cx="12" cy="12" r="8"/><path d="M12 8v5l3 2"/></svg>',
  fish: '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8"><path d="M3 12s5-6 11-6c5 0 7 6 7 6s-2 6-7 6c-6 0-11-6-11-6z"/><path d="M3 12l4 4M3 12l4-4"/><circle cx="16" cy="12" r="1"/></svg>',
};

const BRAND_LOGO = '<img class="empty-logo" src="brand/envy.png" alt="Envy Roleplay" decoding="async" draggable="false" />';

function emptyState(title, copy, extraClass) {
  const cls = extraClass === 'compact' ? ' empty-compact' : '';
  return `<div class="empty${cls}">${BRAND_LOGO}<strong>${escapeHtml(title)}</strong><p>${escapeHtml(copy)}</p></div>`;
}

function safeItemId(name) {
  return String(name || '').replace(/[^a-zA-Z0-9_-]/g, '');
}

function itemImage(name) {
  const id = safeItemId(name);
  if (!id) return '';
  if (inFiveM) return `nui://${resourceName}/images/${id}.png`;
  return `../images/${id}.png`;
}

function iconFor(item) {
  const src = itemImage(item.item);
  const alt = escapeHtml(item.label || item.item);
  if (!src) return ICONS.fish;
  return `<img src="${src}" alt="${alt}" decoding="async" draggable="false" />`;
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
  { id: 'lake', label: 'Canals' },
  { id: 'river', label: 'Creeks' },
];

const BOARD_TABS = [
  { id: 'today', label: 'Today' },
  { id: 'all', label: 'All time' },
];

const SHOP_NAV = [
  { id: 'shop', label: 'Store', icon: 'shop' },
  { id: 'sell', label: 'Sell', icon: 'sell' },
  { id: 'tasks', label: 'Tasks', icon: 'tasks' },
  { id: 'board', label: 'Board', icon: 'board' },
];

const BOAT_NAV = [
  { id: 'fleet', label: 'Fleet', icon: 'fleet' },
  { id: 'active', label: 'Active', icon: 'active' },
];

const DEMO = {
  ok: true,
  player: { name: 'MoodyNewt8638', cash: 12450 },
  catalog: [
    { item: 'fishing_rod_basic', label: 'Canal Rod', description: 'A Los Santos canal stick. Gets you started on the seawall.', category: 'rods', price: 175, uses: 200 },
    { item: 'fishing_rod_pro', label: 'Biscayne Rod', description: 'Carbon blank for the bay. Better luck on snook and mahi.', category: 'rods', price: 520, uses: 450 },
    { item: 'fishing_rod_elite', label: 'Gulf Stream Rod', description: 'Heavy-action rod for tarpon and shark. Highest rare luck.', category: 'rods', price: 1450, uses: 750 },
    { item: 'fishing_rod_miami', label: 'Envy Night Rod', description: 'Signature Envy blank. Built for silver kings after dark.', category: 'rods', price: 2200, uses: 900 },
    { item: 'fishing_reel_basic', label: 'South Beach Spin', description: 'Reliable spinning reel. Keeps line tension, no extra assist.', category: 'reels', price: 125, uses: 250 },
    { item: 'fishing_reel_pro', label: 'Calle Ocho Caster', description: 'Smoother drag. Makes skill checks a little more forgiving.', category: 'reels', price: 380, uses: 500 },
    { item: 'fishing_reel_elite', label: 'Midnight Reel', description: 'Saltwater drag system. Biggest skill-check window in the kit.', category: 'reels', price: 980, uses: 850 },
    { item: 'fishing_line', label: 'Fluoro Line', description: 'Clear fluoro. Each spool lasts 20 bites.', category: 'line', price: 4, uses: 20 },
    { item: 'fishing_line_braid', label: 'Envy Braid', description: 'Cyan braid for the night bite. 40 bites a spool.', category: 'line', price: 12, uses: 40 },
    { item: 'bait_ocean', label: 'Cut Bait', description: 'Oily chunks. Works the ocean and Biscayne.', category: 'bait', price: 8 },
    { item: 'bait_shrimp', label: 'Live Shrimp', description: 'Premium Envy bait. Preferred on the ocean if you have it.', category: 'bait', price: 14 },
    { item: 'bait_lake', label: 'Panfish Bait', description: 'Live worms and jigs. Required on lakes and canals.', category: 'bait', price: 5 },
    { item: 'bait_river', label: 'Creek Bait', description: 'Roe and spinner bait. Required on creeks.', category: 'bait', price: 6 },
  ],
  fish: [
    { item: 'fish_snapper', label: 'Mangrove Snapper', description: 'Hangs on seawalls and pilings.', zone: 'ocean', rarity: 'common', price: 28, count: 4 },
    { item: 'fish_snook', label: 'Snook', description: 'Linesider under the lights.', zone: 'ocean', rarity: 'uncommon', price: 110, count: 1 },
    { item: 'fish_mahi', label: 'Mahi-Mahi', description: 'Gulf Stream gold.', zone: 'ocean', rarity: 'rare', price: 240, count: 1 },
    { item: 'fish_peacock_bass', label: 'Peacock Bass', description: 'Miami canal celebrity.', zone: 'lake', rarity: 'uncommon', price: 72, count: 2 },
    { item: 'fish_tilapia', label: 'Tilapia', description: 'Warm-water panfish in the canals.', zone: 'lake', rarity: 'common', price: 14, count: 5 },
    { item: 'fish_salmon', label: 'Salmon', description: 'Runs the current. Staple creek paycheck.', zone: 'river', rarity: 'uncommon', price: 58, count: 2 },
  ],
  equipment: {
    fishing_rod_basic: 1,
    fishing_reel_basic: 1,
    fishing_line: 14,
    bait_ocean: 9,
    bait_shrimp: 3,
    bait_lake: 4,
    bait_river: 2,
  },
  tasks: [
    { id: 'catch_any', label: 'Pack the cooler', description: 'Land 8 fish of any kind today.', count: 8, progress: 5, claimed: false, reward: 175, rewardItems: [] },
    { id: 'catch_ocean', label: 'Biscayne run', description: 'Catch 5 ocean fish.', count: 5, progress: 5, claimed: false, reward: 200, rewardItems: [] },
    { id: 'catch_offshore', label: 'Gulf Stream', description: 'Catch 3 fish at an offshore hotspot.', count: 3, progress: 1, claimed: false, reward: 275, rewardItems: [] },
    { id: 'catch_trophy', label: 'Silver King', description: 'Land a rare or legendary fish.', count: 1, progress: 0, claimed: false, reward: 400, rewardItems: [{ item: 'bait_shrimp', count: 5, label: 'Live Shrimp' }] },
    { id: 'sell_cash', label: 'Harbor payout', description: 'Sell $400 worth of fish today.', count: 400, progress: 210, claimed: false, reward: 125, rewardItems: [] },
    { id: 'rent_boat', label: 'Launch Envy waters', description: 'Rent a boat from any marina.', count: 1, progress: 1, claimed: true, reward: 75, rewardItems: [] },
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

const BOAT_DEMO = {
  ok: true,
  player: { name: 'MoodyNewt8638', cash: 12450 },
  dock: { id: 'vespucci', label: 'Envy Marina', subtitle: 'Puerto Del Sol' },
  boats: [
    {
      id: 'freeman',
      label: 'Freeman',
      description: 'Center-console fishing boat. Good all-rounder for the bay.',
      times: [
        { id: '15m', label: '15 minutes', minutes: 15, price: 350, deposit: 200, total: 550 },
        { id: '30m', label: '30 minutes', minutes: 30, price: 630, deposit: 200, total: 830 },
        { id: '1h', label: '1 hour', minutes: 60, price: 1050, deposit: 200, total: 1250 },
        { id: '2h', label: '2 hours', minutes: 120, price: 1750, deposit: 200, total: 1950 },
      ],
    },
    {
      id: 'gradywhite',
      label: 'Grady White',
      description: 'Coastal walker. Stable for longer trips along the coast.',
      times: [
        { id: '15m', label: '15 minutes', minutes: 15, price: 450, deposit: 250, total: 700 },
        { id: '30m', label: '30 minutes', minutes: 30, price: 810, deposit: 250, total: 1060 },
        { id: '1h', label: '1 hour', minutes: 60, price: 1350, deposit: 250, total: 1600 },
        { id: '2h', label: '2 hours', minutes: 120, price: 2250, deposit: 250, total: 2500 },
      ],
    },
    {
      id: 'yellowfin',
      label: '26ft Yellowfin',
      description: 'Offshore center console. Built for the Gulf Stream marks.',
      times: [
        { id: '15m', label: '15 minutes', minutes: 15, price: 600, deposit: 300, total: 900 },
        { id: '30m', label: '30 minutes', minutes: 30, price: 1080, deposit: 300, total: 1380 },
        { id: '1h', label: '1 hour', minutes: 60, price: 1800, deposit: 300, total: 2100 },
        { id: '2h', label: '2 hours', minutes: 120, price: 3000, deposit: 300, total: 3300 },
      ],
    },
  ],
  rented: null,
};

const SHOP_VIEWS = new Set(['shop', 'sell', 'tasks', 'board']);
const BOAT_VIEWS = new Set(['fleet', 'active']);
const NUI_ACTIONS = new Set(['close', 'buy', 'sell', 'sellAll', 'claimTask', 'rentBoat', 'returnBoat', 'refresh']);

const state = {
  mode: 'shop',
  view: 'shop',
  tab: 'all',
  query: '',
  qty: {},
  shop: { label: 'Envy Pier Outfitters', subtitle: 'Los Santos tackle', views: ['shop', 'sell', 'tasks', 'board'] },
  player: { name: 'Angler', cash: 0 },
  catalog: [],
  fish: [],
  equipment: {},
  tasks: [],
  board: { dailyFish: { rows: [] }, dailyMoney: { rows: [] }, fish: { rows: [] }, money: { rows: [] } },
  you: { fish: 0, money: 0, dailyFish: 0, dailyMoney: 0 },
  resetsIn: 0,
  boats: [],
  rented: null,
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
  return (name || 'ENV').split(/\s+/).filter(Boolean).map((p) => p[0]).join('').slice(0, 3).toUpperCase() || 'ENV';
}

function toast(message) {
  if (!message) return;
  toastEl.textContent = message;
  toastEl.classList.remove('hidden');
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => toastEl.classList.add('hidden'), 2200);
}

async function nui(name, payload = {}) {
  if (!NUI_ACTIONS.has(name)) return { ok: false };
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
    const amount = Math.max(1, Math.min(50, payload.amount || 1));
    if (!item) return { ok: false };
    const total = item.price * amount;
    if (state.player.cash < total) return { ok: false, error: 'notify_no_money' };
    state.player.cash -= total;
    state.equipment[item.item] = (state.equipment[item.item] || 0) + amount;
    return { ok: true, amount, label: item.label, total, refresh: currentPayload() };
  }
  if (name === 'sell') {
    const fish = state.fish.find((i) => i.item === payload.item);
    if (!fish) return { ok: false };
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
  if (name === 'rentBoat') {
    if (state.rented) return { ok: false, error: 'notify_have_boat' };
    const boat = state.boats.find((b) => b.id === payload.boat);
    const slot = boat && (boat.times || []).find((t) => t.id === payload.duration);
    if (!boat || !slot) return { ok: false };
    if (state.player.cash < slot.total) return { ok: false };
    state.player.cash -= slot.total;
    state.rented = { label: boat.label, remaining: slot.minutes * 60, deposit: slot.deposit, durationLabel: slot.label };
    return { ok: true, label: boat.label, durationLabel: slot.label, price: slot.price, deposit: slot.deposit, refresh: currentBoatPayload() };
  }
  if (name === 'returnBoat') {
    if (!state.rented) return { ok: false };
    const deposit = state.rented.deposit || 0;
    state.player.cash += deposit;
    state.rented = null;
    return { ok: true, deposit, refresh: currentBoatPayload() };
  }
  return state.mode === 'boats' ? currentBoatPayload() : currentPayload();
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

function currentBoatPayload() {
  return {
    ok: true,
    player: state.player,
    dock: state.shop,
    boats: state.boats,
    rented: state.rented,
    cash: state.player.cash,
  };
}

function toArray(value) {
  if (!value) return [];
  if (Array.isArray(value)) return value;
  return Object.keys(value)
    .sort((a, b) => Number(a) - Number(b))
    .map((key) => value[key])
    .filter((entry) => entry && typeof entry === 'object' && (entry.item || entry.label || entry.id));
}

function applyPayload(payload) {
  if (!payload || payload.ok === false) return;

  if (payload.player) {
    state.player = {
      name: payload.player.name || state.player.name,
      cash: Number(payload.player.cash != null ? payload.player.cash : payload.cash || 0),
    };
  } else if (payload.cash != null) {
    state.player.cash = Number(payload.cash) || 0;
  }

  const catalog = toArray(payload.catalog);
  if (catalog.length) state.catalog = catalog;

  if (payload.fish) state.fish = toArray(payload.fish);
  if (payload.equipment && !Array.isArray(payload.equipment)) state.equipment = payload.equipment;
  if (payload.tasks) state.tasks = toArray(payload.tasks);
  if (payload.board) state.board = payload.board;
  if (payload.you) state.you = payload.you;
  if (payload.resetsIn != null) state.resetsIn = Number(payload.resetsIn) || 0;
  if (payload.boats) state.boats = toArray(payload.boats);
  if (payload.rented !== undefined) state.rented = payload.rented || null;
  if (payload.dock) state.shop = { ...state.shop, ...payload.dock };

  playerNameEl.textContent = state.player.name;
  playerAvatarEl.textContent = initials(state.player.name);
  render();
}

function setView(view) {
  const allowed = state.mode === 'boats' ? BOAT_VIEWS : SHOP_VIEWS;
  if (!allowed.has(view)) return;
  state.view = view;
  state.tab = view === 'board' ? 'today' : 'all';
  state.query = '';
  search.value = '';
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

function formatLeft(sec) {
  sec = Math.max(0, Math.floor(Number(sec) || 0));
  if (sec >= 3600) return `${Math.floor(sec / 3600)}h ${Math.floor((sec % 3600) / 60)}m left`;
  if (sec >= 60) return `${Math.floor(sec / 60)}m ${sec % 60}s left`;
  return `${sec}s left`;
}

function rankLabel(rank) {
  return rank ? `#${rank}` : '—';
}

function renderNav() {
  const items = state.mode === 'boats' ? BOAT_NAV : SHOP_NAV;
  navEl.innerHTML = items.map((item) => `
    <button type="button" class="nav-btn ${state.view === item.id ? 'active' : ''}" data-view="${item.id}">
      ${ICONS[item.icon] || ''}
      ${item.label}
    </button>
  `).join('');
}

function renderStats() {
  const gear = countOwned((item) => item.category !== 'bait');
  const bait = countOwned((item) => item.category === 'bait');
  const fishCount = state.fish.reduce((a, f) => a + f.count, 0);
  const value = state.fish.reduce((a, f) => a + f.price * f.count, 0);
  const done = state.tasks.filter((t) => t.progress >= t.count).length;
  const claimed = state.tasks.filter((t) => t.claimed).length;

  let cards;
  if (state.mode === 'boats') {
    cards = [
      { label: 'Cash on hand', value: money(state.player.cash), hint: 'WALLET' },
      { label: 'Boats on the slip', value: String(state.boats.length), hint: 'FLEET' },
      { label: 'Active rental', value: state.rented ? state.rented.label : 'None', hint: 'DOCK' },
    ];
  } else if (state.view === 'shop') {
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
      <strong>${escapeHtml(c.value)}</strong>
      <em>${c.hint}</em>
    </article>
  `).join('');
}

function renderTabs() {
  const toolbar = document.querySelector('.toolbar');
  const hideSearch = state.mode === 'boats' || state.view === 'tasks' || state.view === 'board';
  toolbar.classList.toggle('search-hidden', hideSearch);

  let tabs = [];
  if (state.mode === 'shop' && state.view === 'shop') tabs = CATEGORIES;
  else if (state.view === 'sell') tabs = SELL_TABS;
  else if (state.view === 'board') tabs = BOARD_TABS;

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
    content.innerHTML = emptyState('No gear matches', 'Try another tab or search the marina.');
    return;
  }

  content.innerHTML = items.map((item) => {
    const qty = qtyFor(item.item, 50);
    const owned = ownedCount(item.item);
    return `
      <article class="card" data-item="${escapeHtml(item.item)}">
        <div class="card-head">
          <div class="icon">${iconFor(item)}</div>
          <span class="badge">${escapeHtml(item.category)}</span>
        </div>
        <div>
          <h3>${escapeHtml(item.label)}</h3>
          <p>${escapeHtml(item.description)}</p>
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
    content.innerHTML = emptyState('No fish in your pack', 'Hit Biscayne, the canals, or the creeks, then sell here.');
    return;
  }

  content.innerHTML = items.map((item) => {
    const qty = qtyFor(item.item, item.count);
    return `
      <article class="card" data-item="${escapeHtml(item.item)}">
        <div class="card-head">
          <div class="icon">${iconFor(item)}</div>
          <span class="badge ${escapeHtml(item.rarity || '')}">${escapeHtml(item.rarity)} · ${escapeHtml(item.zone)}</span>
        </div>
        <div>
          <h3>${escapeHtml(item.label)}</h3>
          <p>${escapeHtml(item.description)}</p>
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
    content.innerHTML = emptyState('No daily tasks', 'Come back after the next reset.');
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
      <article class="card task-card" data-task="${escapeHtml(task.id)}">
        <div class="card-head">
          <div class="icon">${ICONS.fish}</div>
          <span class="badge ${task.claimed ? 'uncommon' : ready ? 'legendary' : ''}">${task.progress}/${task.count}</span>
        </div>
        <div>
          <h3>${escapeHtml(task.label)}</h3>
          <p>${escapeHtml(task.description)}</p>
        </div>
        <div class="bar"><i style="width:${pct}%"></i></div>
        <div class="meta-row">
          <div class="price">${money(task.reward)} <span>reward</span></div>
          <span class="badge">${escapeHtml(extras || 'Cash')}</span>
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
      return emptyState('No scores yet', 'Catch or sell fish to appear here.', 'compact');
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

function renderFleet() {
  if (!state.boats.length) {
    content.innerHTML = emptyState('No boats on the slip', 'This marina has nothing to launch right now.');
    return;
  }

  content.innerHTML = state.boats.map((boat) => `
    <article class="card boat-card" data-boat="${escapeHtml(boat.id)}">
      <div class="card-head">
        <div class="icon">${ICONS.fleet}</div>
        <span class="badge">rental</span>
      </div>
      <div>
        <h3>${escapeHtml(boat.label)}</h3>
        <p>${escapeHtml(boat.description || '')}</p>
      </div>
      <div class="times">
        ${(boat.times || []).map((slot) => `
          <button type="button" class="time-btn" data-act="rent" data-duration="${escapeHtml(slot.id)}" ${state.rented || state.player.cash < slot.total ? 'disabled' : ''}>
            <b>${escapeHtml(slot.label)}</b>
            <span>${money(slot.price)} + ${money(slot.deposit)} deposit</span>
          </button>
        `).join('')}
      </div>
    </article>
  `).join('');
}

function renderActive() {
  if (!state.rented) {
    content.innerHTML = emptyState('No boat on the clock', 'Rent a skiff from the Fleet tab, then bring it back here.');
    return;
  }

  content.innerHTML = `
    <div class="active-rental">
      <div>
        <h3>${escapeHtml(state.rented.label)}</h3>
        <p>${escapeHtml(state.rented.durationLabel || 'On the water')} · ${formatLeft(state.rented.remaining)}</p>
        <p>Deposit held: ${money(state.rented.deposit || 0)}</p>
      </div>
      <button type="button" class="btn" data-act="return">Return boat</button>
    </div>
  `;
}

function render() {
  titleEl.textContent = state.mode === 'boats'
    ? (state.shop.label || 'Envy Marina')
    : (state.shop.label || 'Envy Fishing');
  subtitleEl.textContent = state.shop.subtitle || (state.mode === 'boats' ? 'Boat rental' : 'Los Santos tackle');
  playerRoleEl.textContent = state.mode === 'boats' ? 'Marina guest' : 'Licensed Envy angler';
  content.classList.toggle('tasks-view', state.view === 'tasks');
  content.classList.toggle('board-view', state.view === 'board');
  content.classList.toggle('boats-view', state.mode === 'boats' && state.view === 'fleet');
  renderNav();
  renderStats();
  renderTabs();
  if (state.mode === 'boats') {
    if (state.view === 'active') renderActive();
    else renderFleet();
    return;
  }
  if (state.view === 'shop') renderShop();
  else if (state.view === 'sell') renderSell();
  else if (state.view === 'tasks') renderTasks();
  else renderBoard();
}

function openUI(payload) {
  payload = payload || {};
  state.mode = payload.mode === 'boats' ? 'boats' : 'shop';
  if (payload.shop) state.shop = payload.shop;
  if (payload.dock) state.shop = { ...state.shop, ...payload.dock };
  const fallbackView = state.mode === 'boats' ? 'fleet' : 'shop';
  const allowed = state.mode === 'boats' ? BOAT_VIEWS : SHOP_VIEWS;
  state.view = allowed.has(payload.view) ? payload.view : fallbackView;
  state.tab = state.view === 'board' ? 'today' : 'all';
  state.query = '';
  state.qty = {};
  search.value = '';
  applyPayload(payload);
  if (state.mode === 'shop' && !state.catalog.length) state.catalog = DEMO.catalog;
  if (state.mode === 'boats' && !state.boats.length) state.boats = BOAT_DEMO.boats;
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

navEl.addEventListener('click', (e) => {
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

let searchTimer = 0;
search.addEventListener('input', () => {
  state.query = String(search.value || '').slice(0, 64);
  clearTimeout(searchTimer);
  searchTimer = setTimeout(render, 80);
});

content.addEventListener('error', (e) => {
  const el = e.target;
  if (el && el.tagName === 'IMG') el.style.display = 'none';
}, true);

content.addEventListener('click', async (e) => {
  const btn = e.target.closest('button');
  if (!btn || state.busy) return;
  const act = btn.dataset.act;

  if (act === 'return') {
    state.busy = true;
    const result = await nui('returnBoat');
    state.busy = false;
    await handleResult(result, result && result.ok ? `Boat returned. ${money(result.deposit)} deposit back.` : '');
    return;
  }

  const card = e.target.closest('.card');
  if (!card) return;

  if (act === 'rent') {
    state.busy = true;
    const result = await nui('rentBoat', { boat: card.dataset.boat, duration: btn.dataset.duration });
    state.busy = false;
    await handleResult(result, result && result.ok ? `Rented ${result.label} · ${result.durationLabel}` : '');
    return;
  }

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
  const mode = new URLSearchParams(location.search).get('mode') === 'boats' ? 'boats' : 'shop';
  if (mode === 'boats') {
    openUI({ mode: 'boats', view: 'fleet', ...BOAT_DEMO });
  } else {
    openUI({
      view: 'shop',
      shop: { label: 'Envy Pier Outfitters', subtitle: 'Los Santos tackle', views: ['shop', 'sell', 'tasks', 'board'] },
      ...DEMO,
    });
  }
}
