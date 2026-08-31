# 305 Fishing

Miami-themed ocean, canal, and creek fishing for FiveM. Catch fish with **ox_lib** progress bars and skill checks, store them in **ox_inventory**, and buy/sell through a neon-pink **The 305** tackle-shop UI. Boat rentals use the same NUI.

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [interact](https://github.com/darktrovx/interact) (all shop and marina peds use this)
- ESX, QBCore, Qbox, or ox_inventory `money` item

## Install

1. Drop this folder into `resources` as `djfivem-fishing`.
2. Open `ox_inventory/data/items.lua` and paste the item blocks from `install/ox_inventory_items.lua` **inside** the existing `return { ... }` table. Do not replace the whole file, and do not leave any `img(...)` calls in it.
3. Item icons are already in `images/` and load through `nui://djfivem-fishing/images/`. Optional: copy `images/*.png` into `ox_inventory/web/images/` if you want the default inventory path instead.
4. Restart `ox_inventory`, then start this resource:

```cfg
ensure ox_lib
ensure ox_inventory
ensure interact
ensure djfivem-fishing
```

5. Open `config.lua` and set `Config.Money` to match your server:
   - `method = 'auto'` uses framework cash when ESX/QB/Qbox is running, otherwise the ox_inventory money item
   - `method = 'item'` always charges `Config.Money.item` (default `money`)
   - `method = 'framework'` always uses cash/bank

Shop peds use `exports.interact:AddLocalEntityInteraction`. Look at the ped and use the interact prompt for **Open Tackle Shop** or **Sell Fish**. Marina peds open the matching **boat rental UI**.

## How to fish

1. Buy a **rod**, **reel**, **line**, and bait that matches the water at any 305 tackle ped.
2. Walk into a fishing area (ocean / lake-canal / creek) and stand on the bank facing the water.
3. Use the rod from inventory, press **G**, or run `/fish`.
4. Wait out the cast and bite progress bars, then complete the **ox_lib skill check**. Harder fish take more checks. Better reels open the success window.
5. Ocean water accepts **Live Shrimp** first, then **Cut Bait**. Canal water needs panfish bait. Creeks need creek bait. Bait is used every bite. **Fluoro lasts 20 bites. 305 Braid lasts 40.**

Shoreline spots do **not** get map blips (too much clutter). You still get a notify when you walk into a fishing area. **Shop blips**, **boat rental blips**, and **offshore fishing blips** stay on. Set `Config.ShowZoneBlips = true` if you want every shoreline mark back.

Admin test kit: `/fishingkit` (ace `group.admin`).

## Daily tasks and leaderboard

Open any tackle shop and use the **Tasks** and **Board** tabs.

- Daily tasks reset at `Config.DailyResetHour` (server time, default midnight).
- Catch, sell, offshore, and boat-rental tasks credit automatically. Claim the cash (and item) rewards in the shop.
- The board tracks **most fish caught** and **most money made**, for today and all-time. Top 10 plus your rank. Stats save to `data/stats.json`.

## Boat rentals

Interact with a marina ped at **305 Marina / Puerto Del Sol**, **Sunset Marina**, **North Shore**, or **Inland 305 Dock**. The rental UI matches the tackle shop. Pick a **Freeman**, **Grady White**, or **26ft Yellowfin**, then a **real-time** duration (15 min, 30 min, 1 hour, or 2 hours). Boats spawn with a full tank. Return at a dock before the clock runs out to get the deposit back.

Those three spawn names (`freeman`, `gradywhite`, `26ftyellowfin`) must be started on the server as addon vehicles.

You can fish from boats. Cars still block casting.

## Waters and payouts

Prices are server-side. Bait is spent every bite. Common fish still profit without printing money.

| Water | New 305 fish | Also in the pool | Sell range |
| --- | --- | --- | --- |
| Ocean | Snapper, snook, permit, bonefish, mahi, silver king | Sardine, rockfish, tuna, marlin, shark | $15 – $520 |
| Lake / canal | Tilapia, peacock bass | Bluegill, perch, bass, trout, catfish | $12 – $88 |
| Creek | — | Salmon, striper | $58 – $96 |

New shop gear: **Neon 305 Rod**, **305 Braid**, and **Live Shrimp**. Existing rod/reel/line/bait item names stay the same so old inventories keep working.

Tackle shops: 305 Pier Outfitters (Del Perro), Sunset Bait Co., Inland 305 Tackle, Creek & Palm Outfitters, and Vice Wholesale Market. Shop, sell, daily tasks, and the leaderboard share the same UI.

Move peds, docks, and zones in `config.lua`.
