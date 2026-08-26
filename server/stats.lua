Stats = {}

local FILE = 'data/stats.json'
local dirty = false
local store = { day = nil, players = {} }

local function todayKey()
    local now = os.date('*t')
    local hour = Config.DailyResetHour or 0
    local stamp = os.time(now)
    if now.hour < hour then
        stamp = stamp - ((now.hour + 1) * 3600)
    end
    return os.date('%Y-%m-%d', stamp)
end

local function secondsUntilReset()
    local now = os.date('*t')
    local hour = Config.DailyResetHour or 0
    local nextReset = os.time({
        year = now.year,
        month = now.month,
        day = now.day,
        hour = hour,
        min = 0,
        sec = 0,
    })
    if os.time() >= nextReset then
        nextReset = nextReset + 86400
    end
    return math.max(0, nextReset - os.time())
end

local function markDirty()
    dirty = true
end

local function loadStore()
    local raw = LoadResourceFile(GetCurrentResourceName(), FILE)
    if not raw or raw == '' then
        store = { day = todayKey(), players = {} }
        return
    end

    local ok, decoded = pcall(json.decode, raw)
    if not ok or type(decoded) ~= 'table' then
        store = { day = todayKey(), players = {} }
        return
    end

    store.day = decoded.day
    store.players = type(decoded.players) == 'table' and decoded.players or {}
end

local function saveStore()
    if not dirty then return end
    SaveResourceFile(GetCurrentResourceName(), FILE, json.encode(store), -1)
    dirty = false
end

local function resetDailies()
    store.day = todayKey()
    for _, player in pairs(store.players) do
        player.dailyFish = 0
        player.dailyMoney = 0
        player.tasks = {}
        player.claimed = {}
        player.notified = {}
    end
    markDirty()
end

local function ensureDay()
    if store.day ~= todayKey() then
        resetDailies()
    end
end

local function playerRecord(src)
    ensureDay()
    local id = Bridge.GetIdentifier(src)
    local player = store.players[id]
    if not player then
        player = {
            name = Bridge.GetPlayerName(src),
            fish = 0,
            money = 0,
            dailyFish = 0,
            dailyMoney = 0,
            tasks = {},
            claimed = {},
            notified = {},
        }
        store.players[id] = player
        markDirty()
    else
        local name = Bridge.GetPlayerName(src)
        if name and name ~= '' then
            player.name = name
        end
        player.tasks = player.tasks or {}
        player.claimed = player.claimed or {}
        player.notified = player.notified or {}
    end
    return player, id
end

local function taskMatches(task, kind, info)
    if kind == 'catch' then
        if task.type == 'catch' then return true end
        if task.type == 'catch_zone' then return info.zone == task.zone end
        if task.type == 'catch_item' then return info.item == task.item end
        if task.type == 'catch_rarity' then return task.rarities and task.rarities[info.rarity] == true end
        if task.type == 'catch_offshore' then return info.offshore == true end
        if task.type == 'catch_fresh' then return info.zone == 'lake' or info.zone == 'river' end
        return false
    end
    if kind == 'sell' then
        return task.type == 'sell'
    end
    if kind == 'boat' then
        return task.type == 'boat'
    end
    return false
end

local function notifyComplete(src, task)
    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Daily Task',
        description = locale('notify_task_done', task.label),
        type = 'success',
    })
end

local function bumpTasks(src, player, kind, info, amount)
    amount = amount or 1
    local tasks = Config.DailyTasks
    for i = 1, #tasks do
        local task = tasks[i]
        if not player.claimed[task.id] and taskMatches(task, kind, info) then
            local current = player.tasks[task.id] or 0
            if current < task.count then
                local nextValue = math.min(task.count, current + amount)
                player.tasks[task.id] = nextValue
                if nextValue >= task.count and not player.notified[task.id] then
                    player.notified[task.id] = true
                    notifyComplete(src, task)
                end
            end
        end
    end
end

local function topList(kind, daily, myId)
    local size = Config.LeaderboardSize or 10
    local rows = {}
    for id, player in pairs(store.players) do
        local value
        if kind == 'fish' then
            value = daily and (player.dailyFish or 0) or (player.fish or 0)
        else
            value = daily and (player.dailyMoney or 0) or (player.money or 0)
        end
        if value > 0 then
            rows[#rows + 1] = { id = id, name = player.name or 'Angler', value = value }
        end
    end

    table.sort(rows, function(a, b)
        if a.value == b.value then
            return a.name < b.name
        end
        return a.value > b.value
    end)

    local list = {}
    for i = 1, math.min(size, #rows) do
        list[i] = {
            rank = i,
            name = rows[i].name,
            value = rows[i].value,
            me = rows[i].id == myId,
        }
    end

    local mine = { rank = nil, value = 0 }
    for i = 1, #rows do
        if rows[i].id == myId then
            mine.rank = i
            mine.value = rows[i].value
            break
        end
    end

    return { rows = list, you = mine, total = #rows }
end

local function boardPayload(src)
    local _, id = playerRecord(src)
    return {
        dailyFish = topList('fish', true, id),
        dailyMoney = topList('money', true, id),
        fish = topList('fish', false, id),
        money = topList('money', false, id),
    }
end

function Stats.Hud(src)
    ensureDay()
    local player = playerRecord(src)
    local tasks = {}
    for i = 1, #Config.DailyTasks do
        local def = Config.DailyTasks[i]
        local progress = player.tasks[def.id] or 0
        local items = {}
        if def.reward and def.reward.items then
            for n = 1, #def.reward.items do
                local entry = def.reward.items[n]
                local itemName, count = entry[1], entry[2]
                local data = Config.Equipment[itemName]
                items[#items + 1] = {
                    item = itemName,
                    count = count,
                    label = data and data.label or itemName,
                }
            end
        end
        tasks[i] = {
            id = def.id,
            label = def.label,
            description = def.description,
            count = def.count,
            progress = math.min(progress, def.count),
            claimed = player.claimed[def.id] == true,
            reward = def.reward and (def.reward.money or 0) or 0,
            rewardItems = items,
        }
    end

    return {
        tasks = tasks,
        board = boardPayload(src),
        you = {
            fish = player.fish or 0,
            money = player.money or 0,
            dailyFish = player.dailyFish or 0,
            dailyMoney = player.dailyMoney or 0,
        },
        resetsIn = secondsUntilReset(),
    }
end

function Stats.RecordCatch(src, info)
    if not src or not info then return end
    local player = playerRecord(src)
    player.fish = (player.fish or 0) + 1
    player.dailyFish = (player.dailyFish or 0) + 1
    bumpTasks(src, player, 'catch', info, 1)
    markDirty()
end

function Stats.RecordSell(src, amount)
    amount = math.floor(tonumber(amount) or 0)
    if not src or amount <= 0 then return end
    local player = playerRecord(src)
    player.money = (player.money or 0) + amount
    player.dailyMoney = (player.dailyMoney or 0) + amount
    bumpTasks(src, player, 'sell', {}, amount)
    markDirty()
end

function Stats.RecordBoat(src)
    if not src then return end
    local player = playerRecord(src)
    bumpTasks(src, player, 'boat', {}, 1)
    markDirty()
end

function Stats.Claim(src, taskId)
    if type(taskId) ~= 'string' then
        return { ok = false, error = 'notify_invalid' }
    end

    local def
    for i = 1, #Config.DailyTasks do
        if Config.DailyTasks[i].id == taskId then
            def = Config.DailyTasks[i]
            break
        end
    end
    if not def then
        return { ok = false, error = 'notify_invalid' }
    end

    local player = playerRecord(src)
    if player.claimed[def.id] then
        return { ok = false, error = 'notify_task_already' }
    end
    if (player.tasks[def.id] or 0) < def.count then
        return { ok = false, error = 'notify_task_incomplete' }
    end

    local money = def.reward and def.reward.money or 0
    if money > 0 and not Bridge.AddMoney(src, money) then
        return { ok = false, error = 'notify_invalid' }
    end

    local given = {}
    if def.reward and def.reward.items then
        for i = 1, #def.reward.items do
            local itemName, count = def.reward.items[i][1], def.reward.items[i][2]
            if not exports.ox_inventory:CanCarryItem(src, itemName, count) then
                if money > 0 then Bridge.RemoveMoney(src, money) end
                for g = 1, #given do
                    exports.ox_inventory:RemoveItem(src, given[g][1], given[g][2])
                end
                return { ok = false, error = 'notify_cannot_carry' }
            end
            if not exports.ox_inventory:AddItem(src, itemName, count) then
                if money > 0 then Bridge.RemoveMoney(src, money) end
                for g = 1, #given do
                    exports.ox_inventory:RemoveItem(src, given[g][1], given[g][2])
                end
                return { ok = false, error = 'notify_cannot_carry' }
            end
            given[#given + 1] = { itemName, count }
        end
    end

    player.claimed[def.id] = true
    markDirty()
    return { ok = true, money = money, label = def.label }
end

loadStore()
ensureDay()

CreateThread(function()
    while true do
        Wait(15000)
        ensureDay()
        saveStore()
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    dirty = true
    saveStore()
end)
