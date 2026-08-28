lib.locale()

local docksById = {}
local rentals = {}
local pendingSpawns = {}

for i = 1, #Config.BoatDocks do
    local dock = Config.BoatDocks[i]
    dock.pos = vec3(dock.coords.x, dock.coords.y, dock.coords.z)
    dock.spawnPos = vec3(dock.spawn.x, dock.spawn.y, dock.spawn.z)
    docksById[dock.id] = dock
end

local function playerCoords(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end
    return GetEntityCoords(ped)
end

local function isNearDock(src, dock, extra)
    local coords = playerCoords(src)
    if not dock or not coords then return false end
    return #(coords - dock.pos) <= (Config.ShopDistance + (extra or 4.0))
end

local function isNearReturn(src, dock)
    local coords = playerCoords(src)
    if not dock or not coords then return false end
    local radius = Config.BoatRental.returnRadius or 32.0
    return #(coords - dock.pos) <= radius or #(coords - dock.spawnPos) <= radius
end

local function deleteBoat(entity)
    if entity and DoesEntityExist(entity) then
        DeleteEntity(entity)
    end
end

local function refundPending(src)
    local pending = pendingSpawns[src]
    if not pending then return end
    if pending.total and pending.total > 0 then
        Bridge.AddMoney(src, pending.total)
    end
    pendingSpawns[src] = nil
end

local function clearRental(src, refund)
    refundPending(src)
    local rental = rentals[src]
    if not rental then return end
    deleteBoat(rental.entity)
    if refund and rental.deposit and rental.deposit > 0 then
        Bridge.AddMoney(src, rental.deposit)
    end
    rentals[src] = nil
end

local function giveKeys(src, entity, plate)
    pcall(function()
        if GetResourceState('qbx_vehiclekeys') == 'started' then
            exports.qbx_vehiclekeys:GiveKeys(src, entity)
        end
    end)
    pcall(function()
        if GetResourceState('qb-vehiclekeys') == 'started' then
            exports['qb-vehiclekeys']:GiveKeys(src, plate)
        end
    end)
    TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
end

local function catalogFor(dock)
    local list = {}
    for i = 1, #dock.boats do
        local id = dock.boats[i]
        local boat = Config.BoatCatalog[id]
        if boat then
            local times = {}
            for t = 1, #Config.BoatDurations do
                local duration = Config.BoatDurations[t]
                local price = Config.BoatRentalCost(boat, duration)
                times[t] = {
                    id = duration.id,
                    label = duration.label,
                    minutes = duration.minutes,
                    price = price,
                    deposit = boat.deposit or 0,
                    total = price + (boat.deposit or 0),
                }
            end
            list[#list + 1] = {
                id = id,
                label = boat.label,
                description = boat.description,
                deposit = boat.deposit,
                times = times,
            }
        end
    end
    return list
end

lib.callback.register('djfivem-fishing:boatMenu', function(source, dockId)
    local dock = type(dockId) == 'string' and docksById[dockId]
    if not dock or not isNearDock(source, dock) then
        return { ok = false, error = 'notify_too_far' }
    end

    local rental = rentals[source]
    local remaining
    if rental and rental.expires then
        remaining = math.max(0, rental.expires - os.time())
    end

    return {
        ok = true,
        dock = { id = dock.id, label = dock.label, subtitle = dock.subtitle },
        boats = catalogFor(dock),
        rented = rental and {
            label = rental.label,
            remaining = remaining,
            deposit = rental.deposit,
            durationLabel = rental.durationLabel,
        } or nil,
        cash = Bridge.GetMoney(source),
    }
end)

lib.callback.register('djfivem-fishing:rentBoat', function(source, dockId, boatId, durationId)
    local dock = type(dockId) == 'string' and docksById[dockId]
    local boat = type(boatId) == 'string' and Config.BoatCatalog[boatId]
    local duration = Config.GetBoatDuration(durationId)
    if not dock or not isNearDock(source, dock) then
        return { ok = false, error = 'notify_too_far' }
    end
    if not boat or not duration then
        return { ok = false, error = 'notify_invalid' }
    end

    local allowed
    for i = 1, #dock.boats do
        if dock.boats[i] == boatId then
            allowed = true
            break
        end
    end
    if not allowed then
        return { ok = false, error = 'notify_invalid' }
    end

    if rentals[source] or pendingSpawns[source] then
        return { ok = false, error = 'notify_have_boat' }
    end

    local price, deposit = Config.BoatRentalCost(boat, duration)
    local total = price + deposit
    if not Bridge.RemoveMoney(source, total) then
        return { ok = false, error = 'notify_no_money' }
    end

    local plate = ('FISH%04d'):format(math.random(0, 9999))
    local expires = os.time() + (duration.minutes * 60)

    pendingSpawns[source] = {
        boatId = boatId,
        dock = dock.id,
        model = boat.model,
        spawnName = boat.spawn,
        plate = plate,
        label = boat.label,
        price = price,
        deposit = deposit,
        total = total,
        durationLabel = duration.label,
        expires = expires,
        created = os.time(),
    }

    return {
        ok = true,
        needSpawn = true,
        label = boat.label,
        price = price,
        deposit = deposit,
        duration = duration.minutes,
        durationLabel = duration.label,
        plate = plate,
        model = boat.model,
        spawnName = boat.spawn,
        spawn = { x = dock.spawn.x, y = dock.spawn.y, z = dock.spawn.z, w = dock.spawn.w },
        fuel = Config.BoatRental.fuel or 100.0,
    }
end)

lib.callback.register('djfivem-fishing:confirmBoat', function(source, netId)
    local pending = pendingSpawns[source]
    if not pending then
        return { ok = false, error = 'notify_boat_fail' }
    end

    netId = tonumber(netId)
    if not netId then
        refundPending(source)
        return { ok = false, error = 'notify_boat_fail' }
    end

    local entity
    local deadline = GetGameTimer() + 4000
    while GetGameTimer() < deadline do
        entity = NetworkGetEntityFromNetworkId(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            break
        end
        Wait(50)
    end

    if not entity or entity == 0 or not DoesEntityExist(entity) then
        refundPending(source)
        return { ok = false, error = 'notify_boat_fail' }
    end

    if GetEntityModel(entity) ~= pending.model then
        refundPending(source)
        return { ok = false, error = 'notify_boat_fail' }
    end

    pendingSpawns[source] = nil
    rentals[source] = {
        entity = entity,
        netId = netId,
        plate = pending.plate,
        dock = pending.dock,
        label = pending.label,
        deposit = pending.deposit,
        durationLabel = pending.durationLabel,
        expires = pending.expires,
        warned = false,
        missing = 0,
    }

    giveKeys(source, entity, pending.plate)
    Stats.RecordBoat(source)

    return {
        ok = true,
        label = pending.label,
        price = pending.price,
        deposit = pending.deposit,
        durationLabel = pending.durationLabel,
        netId = netId,
    }
end)

lib.callback.register('djfivem-fishing:abortBoat', function(source)
    if not pendingSpawns[source] then
        return { ok = false }
    end
    refundPending(source)
    return { ok = true }
end)

lib.callback.register('djfivem-fishing:returnBoat', function(source, dockId)
    local rental = rentals[source]
    if not rental then
        return { ok = false, error = 'notify_no_rental' }
    end

    local dock = (type(dockId) == 'string' and docksById[dockId]) or docksById[rental.dock]
    if not dock or not isNearReturn(source, dock) then
        return { ok = false, error = 'notify_return_dock' }
    end

    if rental.entity and DoesEntityExist(rental.entity) then
        local coords = GetEntityCoords(rental.entity)
        local radius = (Config.BoatRental.returnRadius or 32.0) + 20.0
        if #(coords - dock.spawnPos) > radius and #(coords - dock.pos) > radius then
            return { ok = false, error = 'notify_return_dock' }
        end
    end

    local deposit = rental.deposit or 0
    clearRental(source, true)
    return { ok = true, deposit = deposit }
end)

CreateThread(function()
    while true do
        Wait(10000)
        local now = os.time()
        local warnAt = Config.BoatRental.warnAt or 180
        local spawnTimeout = Config.BoatRental.spawnTimeout or 20

        for src, pending in pairs(pendingSpawns) do
            if (now - (pending.created or now)) >= spawnTimeout then
                refundPending(src)
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Boat Rental',
                    description = locale('notify_boat_fail'),
                    type = 'error',
                })
            end
        end

        for src, rental in pairs(rentals) do
            if rental.entity and not DoesEntityExist(rental.entity) then
                rental.missing = (rental.missing or 0) + 1
                if rental.missing >= 3 then
                    rentals[src] = nil
                    TriggerClientEvent('ox_lib:notify', src, {
                        title = 'Boat Rental',
                        description = locale('notify_boat_lost'),
                        type = 'error',
                    })
                end
            else
                rental.missing = 0
                if rental.expires then
                    local left = rental.expires - now
                    if left <= 0 then
                        clearRental(src, true)
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Boat Rental',
                            description = locale('notify_boat_expired'),
                            type = 'inform',
                        })
                    elseif not rental.warned and left <= warnAt then
                        rental.warned = true
                        TriggerClientEvent('ox_lib:notify', src, {
                            title = 'Boat Rental',
                            description = locale('notify_boat_warn', math.ceil(left / 60)),
                            type = 'inform',
                        })
                    end
                end
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    clearRental(source, true)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for src in pairs(pendingSpawns) do
        refundPending(src)
    end
    for src in pairs(rentals) do
        clearRental(src, true)
    end
end)
