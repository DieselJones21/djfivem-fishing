# DJ FiveM Fishing

Ocean, lake, and river fishing for FiveM. Catch fish with **ox_lib** progress bars and skill checks, store them in **ox_inventory**, and buy/sell through a dark red tackle-shop UI.

## Requirements

- [ox_lib](https://github.com/overextended/ox_lib)
- [ox_inventory](https://github.com/overextended/ox_inventory)
- [interact](https://github.com/darktrovx/interact) (all shop peds use this)
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

Shop peds are wired with `exports.interact:AddLocalEntityInteraction`. Look at the ped and use the interact prompt for **Open Tackle Shop** or **Sell Fish**.

## How to fish

1. Buy a **rod**, **reel**, **line**, and the bait that matches the water at any tackle ped.
2. Walk into a marked fishing area (ocean / lake / river) and stand on the bank facing the water.
3. Use the rod from inventory, press **G**, or run `/fish`.
4. Wait out the cast and bite progress bars, then complete the **ox_lib skill check**. Harder fish (marlin, shark, striper, catfish) take more checks. Better reels open the success window.
5. Correct bait is required: ocean bait on the coast, lake bait on lakes, river bait on rivers. Line and bait are consumed when a fish hits.

Admin test kit: `/fishingkit` (ace `group.admin`).

## Waters and payouts

Prices are server-side. Bait + line cost is paid on every bite, so common fish still profit without printing money.

| Water | Fish | Sell |
| --- | --- | --- |
| Ocean | Sardine, rockfish, tuna, marlin, shark | $15 – $425 |
| Lake | Bluegill, perch, smallmouth, largemouth, trout, catfish | $12 – $88 |
| River | Salmon, striper | $58 – $96 |

Tackle shops: Del Perro, Chumash Pier, Alamo Sea, Cassidy / river road, and a La Puerta fish buyer. Shop and sell share the same UI.

Move peds and zones in `config.lua`. Radius blips show legal fishing water; red blips mark shops.
