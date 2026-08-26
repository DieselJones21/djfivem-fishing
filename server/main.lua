lib.locale()
math.randomseed(os.time() % 2147483646)

local pending = {}
local lastResolve = {}
local shopsById = {}
local fishByZone = { ocean = {}, lake = {}, river = {} }
local cachedCatalog

local RODS = Config.RodOrder
local REELS = Config.ReelOrder
local LINES = { 'fishing_line' }
local ZONES = Config.Zones
local ZONE_COUNT = #ZONES

for i = 1, #Config.Shops do
    local shop = Config.Shops[i]
    shop.pos = vec3(shop.coords.x, shop.coords.y, shop.coords.z)
    shopsById[shop.id] = shop
end

for name, data in pairs(Config.Fish) do
    local bucket = fishByZone[data.zone]
    if bucket then
        bucket[#bucket + 1] = { name = name, data = data }
    end
end

local function now()
    return os.clock()
end

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function getShop(shopId)
    return shopsById[shopId]
end

local function isNearShop(src, shopId)
    local shop = getShop(shopId)
    local coords = playerCoords(src)
    if not shop or not coords then return false end
    return #(coords - shop.pos) <= (Config.ShopDistance + 2.0)
end

local function getZoneAt(src, expectedType)
    local coords = playerCoords(src)
    if not coords then return nil end

    for i = 1, ZONE_COUNT do
        local zone = ZONES[i]
        local dx = coords.x - zone.coords.x
        local dy = coords.y - zone.coords.y
        if (dx * dx + dy * dy) <= zone.radiusSq then
            if not expectedType or zone.type == expectedType then
                return zone
            end
        end
    end
end

local function slotList(result)
    if not result then return {} end
    if result.slot then return { result } end

    local list = {}
    for _, slot in pairs(result) do
        if type(slot) == 'table' and slot.slot then
            list[#list + 1] = slot
        end
    end
    return list
end

local function findBest(src, names)
    for i = 1, #names do
        local name = names[i]
        local slots = slotList(exports.ox_inventory:Search(src, 'slots', name))
        local best, bestScore
        for s = 1, #slots do
            local slot = slots[s]
            local durability = slot.metadata and slot.metadata.durability
            local usesLeft = slot.metadata and slot.metadata.uses
            if slot.count and slot.count > 0 and (usesLeft == nil or usesLeft > 0) and (durability == nil or durability > 0) then
                -- Prefer opened / more worn items so a started spool finishes first.
                local score = (type(usesLeft) == 'number' and usesLeft or (type(durability) == 'number' and durability or 101)) * 1000 + (slot.count or 1)
                if not bestScore or score < bestScore then
                    best, bestScore = slot, score
                end
            end
        end
        if best then
            return name, best
        end
    end
end

local function starterMetadata(item)
    if not item or not item.uses then return nil end
    if item.category == 'line' then
        return { uses = item.uses, durability = 100 }
    end
    return { durability = 100 }
end

local function lineUsesFromSlot(slot)
    local maxUses = Config.Equipment.fishing_line and Config.Equipment.fishing_line.uses or 5
    local uses = slot.metadata and slot.metadata.uses
    if type(uses) == 'number' then
        return uses, maxUses
    end
    local durability = slot.metadata and slot.metadata.durability
    if type(durability) == 'number' then
        return math.max(1, math.ceil((durability / 100) * maxUses)), maxUses
    end
    return maxUses, maxUses
end

local function lineMetadata(uses, maxUses)
    return {
        uses = uses,
        durability = math.floor((uses / maxUses) * 1000 + 0.5) / 10,
    }
end

local function consumeLine(src)
    local name, slot = findBest(src, LINES)
    if not slot then return false end

    local uses, maxUses = lineUsesFromSlot(slot)
    uses = uses - 1

    -- Split one spool off a stack so the remaining spools keep full uses.
    if (slot.count or 1) > 1 then
        local removed = exports.ox_inventory:RemoveItem(src, name, 1, nil, slot.slot)
        if not removed then return false end
        if uses > 0 then
            exports.ox_inventory:AddItem(src, name, 1, lineMetadata(uses, maxUses))
        end
        return true
    end

    if uses <= 0 then
        return exports.ox_inventory:RemoveItem(src, name, 1, nil, slot.slot) and true or false
    end

    local metadata = slot.metadata or {}
    metadata.uses = uses
    metadata.durability = lineMetadata(uses, maxUses).durability
    exports.ox_inventory:SetMetadata(src, slot.slot, metadata)
    return true
end

local function consumeDurability(src, slot, itemName, uses)
    if not slot or not uses or uses <= 0 then return false end

    local current = slot.metadata and slot.metadata.durability or 100
    local loss = 100 / uses
    local nextValue = current - loss

    if nextValue <= 0.5 then
        exports.ox_inventory:RemoveItem(src, itemName, 1, nil, slot.slot)
        return true
    end

    local metadata = slot.metadata or {}
    metadata.durability = math.floor(nextValue * 10 + 0.5) / 10
    exports.ox_inventory:SetMetadata(src, slot.slot, metadata)
    return false
end

local function baitFor(zoneType)
    return Config.BaitByZone[zoneType]
end

local function catalog()
    if cachedCatalog then return cachedCatalog end

    local items = {}
    for i = 1, #Config.ShopCatalogOrder do
        local name = Config.ShopCatalogOrder[i]
        local data = Config.Equipment[name]
        if data then
            items[#items + 1] = {
                item = name,
                label = data.label,
                description = data.description,
                category = data.category,
                price = data.price,
                uses = data.uses,
            }
        end
    end
    cachedCatalog = items
    return items
end

local function equipmentCounts(src)
    local counts = {}
    for name in pairs(Config.Equipment) do
        counts[name] = exports.ox_inventory:GetItemCount(src, name) or 0
    end
    return counts
end

local function fishStock(src)
    local list = {}
    for name, data in pairs(Config.Fish) do
        local count = exports.ox_inventory:GetItemCount(src, name) or 0
        if count > 0 then
            list[#list + 1] = {
                item = name,
                label = data.label,
                description = data.description,
                zone = data.zone,
                rarity = data.rarity,
                price = data.sell,
                count = count,
            }
        end
    end

    table.sort(list, function(a, b)
        if a.zone == b.zone then
            return a.price > b.price
        end
        return a.zone < b.zone
    end)

    return list
end

local function shopPayload(src)
    return {
        ok = true,
        player = {
            name = Bridge.GetPlayerName(src),
            cash = Bridge.GetMoney(src),
        },
        catalog = catalog(),
        fish = fishStock(src),
        equipment = equipmentCounts(src),
    }
end

local function weightedFish(zoneType, rareBonus)
    local pool = fishByZone[zoneType]
    if not pool or #pool == 0 then return nil end

    local total = 0
    local weighted = {}
    rareBonus = rareBonus or 0

    for i = 1, #pool do
        local entry = pool[i]
        local weight = entry.data.weight
        if rareBonus > 0 and (entry.data.rarity == 'rare' or entry.data.rarity == 'legendary') then
            weight = weight + rareBonus
        end
        total = total + weight
        weighted[i] = weight
    end

    if total <= 0 then return nil end

    local roll = math.random() * total
    local acc = 0
    for i = 1, #pool do
        acc = acc + weighted[i]
        if roll <= acc then
            return pool[i]
        end
    end

    return pool[#pool]
end

local function clearPending(src)
    pending[src] = nil
end

lib.callback.register('djfivem-fishing:openShop', function(source, shopId)
    if type(shopId) ~= 'string' or not isNearShop(source, shopId) then
        return { ok = false, error = 'notify_too_far' }
    end
    return shopPayload(source)
end)

lib.callback.register('djfivem-fishing:buy', function(source, shopId, itemName, amount)
    amount = math.floor(tonumber(amount) or 0)
    if type(shopId) ~= 'string' or not isNearShop(source, shopId) then
        return { ok = false, error = 'notify_too_far' }
    end
    if amount < 1 or amount > Config.MaxBuyAmount then
        return { ok = false, error = 'notify_invalid' }
    end

    local item = Config.Equipment[itemName]
    if not item then
        return { ok = false, error = 'notify_invalid' }
    end

    local total = item.price * amount
    if not Bridge.RemoveMoney(source, total) then
        return { ok = false, error = 'notify_no_money' }
    end

    if not exports.ox_inventory:CanCarryItem(source, itemName, amount) then
        Bridge.AddMoney(source, total)
        return { ok = false, error = 'notify_cannot_carry' }
    end

    local metadata = starterMetadata(item)

    local added = exports.ox_inventory:AddItem(source, itemName, amount, metadata)
    if not added then
        Bridge.AddMoney(source, total)
        return { ok = false, error = 'notify_cannot_carry' }
    end

    return {
        ok = true,
        amount = amount,
        label = item.label,
        total = total,
        cash = Bridge.GetMoney(source),
    }
end)

lib.callback.register('djfivem-fishing:sell', function(source, shopId, itemName, amount)
    amount = math.floor(tonumber(amount) or 0)
    if type(shopId) ~= 'string' or not isNearShop(source, shopId) then
        return { ok = false, error = 'notify_too_far' }
    end

    local fish = Config.Fish[itemName]
    if not fish or amount < 1 then
        return { ok = false, error = 'notify_invalid' }
    end

    local have = exports.ox_inventory:GetItemCount(source, itemName) or 0
    if have < amount then
        return { ok = false, error = 'notify_invalid' }
    end

    local removed = exports.ox_inventory:RemoveItem(source, itemName, amount)
    if not removed then
        return { ok = false, error = 'notify_invalid' }
    end

    local total = fish.sell * amount
    if not Bridge.AddMoney(source, total) then
        exports.ox_inventory:AddItem(source, itemName, amount)
        return { ok = false, error = 'notify_invalid' }
    end

    return {
        ok = true,
        amount = amount,
        label = fish.label,
        total = total,
        cash = Bridge.GetMoney(source),
    }
end)

lib.callback.register('djfivem-fishing:sellAll', function(source, shopId)
    if type(shopId) ~= 'string' or not isNearShop(source, shopId) then
        return { ok = false, error = 'notify_too_far' }
    end

    local sold = {}
    local payout = 0

    for name, data in pairs(Config.Fish) do
        local count = exports.ox_inventory:GetItemCount(source, name) or 0
        if count > 0 then
            sold[#sold + 1] = { item = name, count = count, price = data.sell }
            payout = payout + data.sell * count
        end
    end

    if #sold == 0 then
        return { ok = false, error = 'notify_no_fish' }
    end

    for i = 1, #sold do
        local entry = sold[i]
        if not exports.ox_inventory:RemoveItem(source, entry.item, entry.count) then
            for r = 1, i - 1 do
                exports.ox_inventory:AddItem(source, sold[r].item, sold[r].count)
            end
            return { ok = false, error = 'notify_invalid' }
        end
    end

    if not Bridge.AddMoney(source, payout) then
        for i = 1, #sold do
            exports.ox_inventory:AddItem(source, sold[i].item, sold[i].count)
        end
        return { ok = false, error = 'notify_invalid' }
    end

    return { ok = true, total = payout, cash = Bridge.GetMoney(source) }
end)

lib.callback.register('djfivem-fishing:prepareCast', function(source, info)
    info = info or {}
    clearPending(source)

    if lastResolve[source] and (now() - lastResolve[source]) < Config.CastCooldown then
        return { ok = false, error = 'notify_busy' }
    end

    local zone = getZoneAt(source, info.zone)
    if Config.RequireZone and not zone then
        return { ok = false, error = 'notify_need_zone' }
    end
    zone = zone or { type = info.zone, name = info.zoneName }
    if not zone.type or not Config.BaitByZone[zone.type] then
        return { ok = false, error = 'notify_need_zone' }
    end

    local preferred = {}
    if type(info.rod) == 'string' then
        for i = 1, #RODS do
            if RODS[i] == info.rod then
                preferred = { info.rod }
                break
            end
        end
    end
    for i = 1, #RODS do
        preferred[#preferred + 1] = RODS[i]
    end

    local rodName, rodSlot = findBest(source, preferred)
    if not rodName then
        return { ok = false, error = 'notify_need_rod' }
    end

    local reelName, reelSlot = findBest(source, REELS)
    if not reelName then
        return { ok = false, error = 'notify_need_reel' }
    end

    local lineName, lineSlot = findBest(source, LINES)
    if not lineName then
        return { ok = false, error = 'notify_need_line' }
    end

    local baitName = baitFor(zone.type)
    if (exports.ox_inventory:GetItemCount(source, baitName) or 0) < 1 then
        local bait = Config.Equipment[baitName]
        return { ok = false, error = 'notify_need_bait', errorArg = bait and bait.label or baitName }
    end

    pending[source] = {
        zone = zone.type,
        zoneName = zone.name,
        rod = rodName,
        rodSlot = rodSlot.slot,
        reel = reelName,
        reelSlot = reelSlot.slot,
        lineSlot = lineSlot.slot,
        bait = baitName,
        stage = 'prepared',
        expires = now() + 90,
    }

    return { ok = true, zone = zone.type, rod = rodName, reel = reelName, bait = baitName }
end)

lib.callback.register('djfivem-fishing:onBite', function(source)
    local cast = pending[source]
    if not cast or cast.stage ~= 'prepared' or now() > cast.expires then
        clearPending(source)
        return { ok = false, error = 'notify_no_bite' }
    end

    if Config.RequireZone and not getZoneAt(source, cast.zone) then
        clearPending(source)
        return { ok = false, error = 'notify_need_zone' }
    end

    local rod = Config.Equipment[cast.rod]
    local rolled = weightedFish(cast.zone, rod and rod.rareBonus or 0)
    if not rolled then
        clearPending(source)
        return { ok = false, error = 'notify_no_bite' }
    end

    cast.stage = 'fighting'
    cast.fish = rolled.name
    cast.expires = now() + 45

    return {
        ok = true,
        fish = {
            item = rolled.name,
            label = rolled.data.label,
            rarity = rolled.data.rarity,
            difficulty = rolled.data.difficulty,
            checks = rolled.data.checks,
            zone = rolled.data.zone,
        },
        reelEase = Config.ReelEase[cast.reel] or { area = 0, speed = 0 },
    }
end)

lib.callback.register('djfivem-fishing:resolveCast', function(source, success, reason)
    local cast = pending[source]
    clearPending(source)

    if not cast or (cast.stage ~= 'fighting' and cast.stage ~= 'prepared') then
        return { ok = false, error = 'notify_got_away' }
    end

    lastResolve[source] = now()

    local fish = cast.fish and Config.Fish[cast.fish]
    if cast.stage == 'prepared' or reason == 'cancel' then
        return { ok = true, caught = false }
    end
    if not fish then
        return { ok = false, error = 'notify_got_away' }
    end

    -- Bait and one line use are spent once a fish actually hits.
    local baitRemoved = exports.ox_inventory:RemoveItem(source, cast.bait, 1)
    local lineUsed = consumeLine(source)
    if not baitRemoved or not lineUsed then
        if baitRemoved then exports.ox_inventory:AddItem(source, cast.bait, 1) end
        return { ok = false, error = 'notify_need_bait' }
    end

    local rodName, rodSlot = findBest(source, { cast.rod })
    local reelName, reelSlot = findBest(source, { cast.reel })
    local rodBroke, reelBroke = false, false
    if rodSlot then
        rodBroke = consumeDurability(source, rodSlot, rodName, Config.Equipment[rodName] and Config.Equipment[rodName].uses)
    end
    if reelSlot then
        reelBroke = consumeDurability(source, reelSlot, reelName, Config.Equipment[reelName] and Config.Equipment[reelName].uses)
    end

    local snapped = false
    if not success then
        local snapChance = Config.LineSnapChance
        if fish.rarity == 'legendary' then
            snapChance = Config.LegendarySnapChance
        end
        snapped = math.random() < snapChance
        return {
            ok = true,
            caught = false,
            snapped = snapped,
            rodBroke = rodBroke,
            reelBroke = reelBroke,
            stop = rodBroke or reelBroke,
        }
    end

    if not exports.ox_inventory:CanCarryItem(source, cast.fish, 1) then
        return {
            ok = false,
            error = 'notify_cannot_carry',
            stop = true,
            rodBroke = rodBroke,
            reelBroke = reelBroke,
        }
    end

    local added = exports.ox_inventory:AddItem(source, cast.fish, 1, {
        description = ('%s · %s'):format(fish.label, fish.rarity),
    })

    if not added then
        return { ok = false, error = 'notify_cannot_carry', stop = true }
    end

    return {
        ok = true,
        caught = true,
        item = cast.fish,
        label = fish.label,
        rarity = fish.rarity,
        sell = fish.sell,
        rodBroke = rodBroke,
        reelBroke = reelBroke,
        stop = rodBroke or reelBroke,
    }
end)

lib.callback.register('djfivem-fishing:cancelCast', function(source)
    clearPending(source)
    return { ok = true }
end)

AddEventHandler('playerDropped', function()
    clearPending(source)
    lastResolve[source] = nil
end)

lib.addCommand('fishingkit', {
    help = 'Give a testing set of fishing gear',
    restricted = 'group.admin',
}, function(source)
    local kit = {
        { 'fishing_rod_pro', 1 },
        { 'fishing_reel_pro', 1 },
        { 'fishing_line', 25 },
        { 'bait_ocean', 15 },
        { 'bait_lake', 15 },
        { 'bait_river', 15 },
    }

    for i = 1, #kit do
        local item, count = kit[i][1], kit[i][2]
        exports.ox_inventory:AddItem(source, item, count, starterMetadata(Config.Equipment[item]))
    end

    TriggerClientEvent('ox_lib:notify', source, {
        title = 'Fishing',
        description = 'Test kit added to your inventory.',
        type = 'success',
    })
end)
