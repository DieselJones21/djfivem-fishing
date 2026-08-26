lib.locale()

local docksById = {}
local rentals = {} -- src -> rental

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

local function clearRental(src, refund)
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

local function spawnBoat(model, spawn)
    local hash = model
    local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    local deadline = GetGameTimer() + 5000
    while not DoesEntityExist(veh) and GetGameTimer() < deadline do
        Wait(50)
    end
    if not DoesEntityExist(veh) then return nil end

    SetEntityHeading(veh, spawn.w)
    SetVehicleDoorsLocked(veh, Config.BoatRental.lockDoors and 2 or 1)
    return veh
end

local function catalogFor(dock)
    local list = {}
    for i = 1, #dock.boats do
        local id = dock.boats[i]
        local boat = Config.BoatCatalog[id]
        if boat then
            list[#list + 1] = {
                id = id,
                label = boat.label,
                description = boat.description,
                price = boat.price,
                deposit = boat.deposit,
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
        } or nil,
        cash = Bridge.GetMoney(source),
    }
end)

lib.callback.register('djfivem-fishing:rentBoat', function(source, dockId, boatId)
    local dock = type(dockId) == 'string' and docksById[dockId]
    local boat = type(boatId) == 'string' and Config.BoatCatalog[boatId]
    if not dock or not boat or not isNearDock(source, dock) then
        return { ok = false, error = 'notify_too_far' }
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

    if rentals[source] then
        return { ok = false, error = 'notify_have_boat' }
    end

    local total = (boat.price or 0) + (boat.deposit or 0)
    if not Bridge.RemoveMoney(source, total) then
        return { ok = false, error = 'notify_no_money' }
    end

    local veh = spawnBoat(boat.model, dock.spawn)
    if not veh then
        Bridge.AddMoney(source, total)
        return { ok = false, error = 'notify_boat_fail' }
    end

    local plate = ('FISH%04d'):format(math.random(0, 9999))
    pcall(SetVehicleNumberPlateText, veh, plate)
    local netId = NetworkGetNetworkIdFromEntity(veh)
    local duration = Config.BoatRental.duration or 0

    rentals[source] = {
        entity = veh,
        netId = netId,
        plate = plate,
        dock = dock.id,
        label = boat.label,
        deposit = boat.deposit or 0,
        expires = duration > 0 and (os.time() + duration) or nil,
        warned = false,
    }

    giveKeys(source, veh, plate)
    TriggerClientEvent('djfivem-fishing:client:boardBoat', source, netId, plate)
    Stats.RecordBoat(source)

    return {
        ok = true,
        label = boat.label,
        price = boat.price,
        deposit = boat.deposit,
        duration = duration,
        netId = netId,
    }
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
        if #(coords - dock.spawnPos) > (Config.BoatRental.returnRadius + 20.0) and #(coords - dock.pos) > (Config.BoatRental.returnRadius + 20.0) then
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
        local warnAt = Config.BoatRental.warnAt or 120
        for src, rental in pairs(rentals) do
            if rental.entity and not DoesEntityExist(rental.entity) then
                rentals[src] = nil
                TriggerClientEvent('ox_lib:notify', src, {
                    title = 'Boat Rental',
                    description = locale('notify_boat_lost'),
                    type = 'error',
                })
            elseif rental.expires then
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
                        description = locale('notify_boat_warn', left),
                        type = 'inform',
                    })
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
    for src in pairs(rentals) do
        clearRental(src, true)
    end
end)
