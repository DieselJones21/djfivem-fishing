lib.locale()

local dockPeds = {}
local dockBlips = {}

local FUEL_SCRIPTS = {
    { 'LegacyFuel', 'SetFuel' },
    { 'legacyfuel', 'SetFuel' },
    { 'cdn-fuel', 'SetFuel' },
    { 'ps-fuel', 'SetFuel' },
    { 'lc_fuel', 'SetFuel' },
    { 'ox_fuel', 'SetFuel' },
    { 'qs-fuel', 'SetFuel' },
    { 'qs-fuelstations', 'SetFuel' },
    { 'nd_fuel', 'SetFuel' },
    { 'BigDaddy-Fuel', 'SetFuel' },
    { 'x-fuel', 'SetFuel' },
}

local function notify(key, nType, ...)
    lib.notify({
        title = 'Boat Rental',
        description = locale(key, ...),
        type = nType or 'inform',
    })
end

local function fillFuel(veh, amount)
    amount = amount or Config.BoatRental.fuel or 100.0
    SetVehicleFuelLevel(veh, amount + 0.0)
    pcall(function()
        Entity(veh).state:set('fuel', amount, true)
    end)
    pcall(function()
        DecorSetFloat(veh, '_FUEL_LEVEL', amount + 0.0)
    end)
    for i = 1, #FUEL_SCRIPTS do
        local resource, method = FUEL_SCRIPTS[i][1], FUEL_SCRIPTS[i][2]
        if GetResourceState(resource) == 'started' then
            pcall(function()
                exports[resource][method](veh, amount)
            end)
        end
    end
end

local function spawnRentalBoat(info)
    local hash = info.model or joaat(info.spawnName)
    if not lib.requestModel(hash, 10000) then
        return nil, nil, 'notify_boat_model'
    end

    local spawn = info.spawn
    local veh = CreateVehicle(hash, spawn.x, spawn.y, spawn.z, spawn.w, true, true)
    local deadline = GetGameTimer() + 5000
    while (not veh or veh == 0 or not DoesEntityExist(veh)) and GetGameTimer() < deadline do
        Wait(50)
    end
    if not veh or veh == 0 or not DoesEntityExist(veh) then
        SetModelAsNoLongerNeeded(hash)
        return nil, nil, 'notify_boat_fail'
    end

    SetEntityAsMissionEntity(veh, true, true)
    SetEntityHeading(veh, spawn.w)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleUndriveable(veh, false)
    SetVehicleHasBeenOwnedByPlayer(veh, true)
    pcall(SetBoatAnchor, veh, false)
    if info.plate then
        SetVehicleNumberPlateText(veh, info.plate)
    end
    fillFuel(veh, info.fuel)
    SetModelAsNoLongerNeeded(hash)

    local netId = NetworkGetNetworkIdFromEntity(veh)
    SetNetworkIdExistsOnAllMachines(netId, true)
    SetNetworkIdCanMigrate(netId, true)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
    Wait(150)
    fillFuel(veh, info.fuel)
    return netId, veh
end

local function createDockBlip(dock)
    if not dock.blip then return end
    local blip = AddBlipForCoord(dock.coords.x, dock.coords.y, dock.coords.z)
    SetBlipSprite(blip, dock.blip.sprite or 410)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, dock.blip.scale or 0.8)
    SetBlipColour(blip, dock.blip.color or 3)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(dock.blip.label or 'Boat Rental')
    EndTextCommandSetBlipName(blip)
    dockBlips[#dockBlips + 1] = blip
end

local function addDockInteract(entity, dock)
    local id = 'djfivem_fishing_boat_' .. dock.id
    exports.interact:AddLocalEntityInteraction({
        entity = entity,
        id = id,
        name = id,
        distance = Config.Interact.distance,
        interactDst = Config.Interact.interactDst,
        offset = Config.Interact.offset,
        ignoreLos = false,
        options = {
            {
                label = locale('boat_rent'),
                action = function()
                    OpenBoatMenu(dock)
                end,
            },
            {
                label = locale('boat_return'),
                action = function()
                    ReturnBoat(dock)
                end,
            },
        },
    })
    return id
end

local function spawnDockPed(dock, useInteract)
    if dockPeds[dock.id] and DoesEntityExist(dockPeds[dock.id].entity) then
        return
    end

    lib.requestModel(dock.ped, 5000)
    local ped = CreatePed(0, dock.ped, dock.coords.x, dock.coords.y, dock.coords.z - 1.0, dock.coords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedDiesWhenInjured(ped, false)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetModelAsNoLongerNeeded(dock.ped)

    if dock.scenario then
        TaskStartScenarioInPlace(ped, dock.scenario, 0, true)
    end

    local interactId
    if useInteract then
        interactId = addDockInteract(ped, dock)
    end

    dockPeds[dock.id] = { entity = ped, interactId = interactId }
end

local function despawnDockPed(dock)
    local entry = dockPeds[dock.id]
    if not entry then return end

    if entry.interactId and GetResourceState('interact') == 'started' then
        pcall(function()
            exports.interact:RemoveLocalEntityInteraction(entry.entity, entry.interactId)
        end)
    end

    if DoesEntityExist(entry.entity) then
        DeleteEntity(entry.entity)
    end

    dockPeds[dock.id] = nil
end

function ReturnBoat(dock)
    local result = lib.callback.await('djfivem-fishing:returnBoat', false, dock.id)
    if result and result.ok then
        notify('notify_boat_returned', 'success', result.deposit or 0)
    else
        notify(result and result.error or 'notify_no_rental', 'error')
    end
end

local function formatLeft(sec)
    sec = math.floor(tonumber(sec) or 0)
    if sec >= 3600 then
        return ('%dh %dm left'):format(math.floor(sec / 3600), math.floor((sec % 3600) / 60))
    end
    if sec >= 60 then
        return ('%dm %ds left'):format(math.floor(sec / 60), sec % 60)
    end
    return ('%ds left'):format(sec)
end

local function rentBoat(dock, boatId, durationId)
    local authorized = lib.callback.await('djfivem-fishing:rentBoat', false, dock.id, boatId, durationId)
    if not authorized or not authorized.ok then
        notify(authorized and authorized.error or 'notify_boat_fail', 'error')
        return
    end

    local netId, veh, spawnErr = spawnRentalBoat(authorized)
    if not netId then
        lib.callback.await('djfivem-fishing:abortBoat', false)
        notify(spawnErr or 'notify_boat_fail', 'error')
        return
    end

    local confirmed = lib.callback.await('djfivem-fishing:confirmBoat', false, netId)
    if confirmed and confirmed.ok then
        notify('notify_boat_rented', 'success', confirmed.label, confirmed.durationLabel or '', confirmed.price, confirmed.deposit)
    else
        if veh and DoesEntityExist(veh) then
            DeleteEntity(veh)
        end
        notify(confirmed and confirmed.error or 'notify_boat_fail', 'error')
    end
end

function OpenBoatMenu(dock)
    if IsFishing() or IsShopOpen() then return end

    local payload = lib.callback.await('djfivem-fishing:boatMenu', false, dock.id)
    if not payload or not payload.ok then
        notify(payload and payload.error or 'notify_too_far', 'error')
        return
    end

    local options = {}
    if payload.rented then
        local time = payload.rented.remaining and formatLeft(payload.rented.remaining) or locale('boat_until_return')
        options[#options + 1] = {
            title = locale('boat_return'),
            description = locale('boat_return_desc', payload.rented.label, payload.rented.deposit or 0, time),
            icon = 'anchor',
            onSelect = function()
                ReturnBoat(dock)
            end,
        }
    end

    for i = 1, #payload.boats do
        local boat = payload.boats[i]
        options[#options + 1] = {
            title = boat.label,
            description = boat.description,
            icon = 'ship',
            disabled = payload.rented ~= nil,
            onSelect = function()
                local times = {}
                for t = 1, #(boat.times or {}) do
                    local slot = boat.times[t]
                    times[#times + 1] = {
                        title = slot.label,
                        description = locale('boat_duration_desc', slot.price, slot.deposit, slot.minutes),
                        icon = 'clock',
                        disabled = payload.rented ~= nil or (payload.cash or 0) < slot.total,
                        onSelect = function()
                            rentBoat(dock, boat.id, slot.id)
                        end,
                    }
                end
                lib.registerContext({
                    id = 'djfishing_boat_time',
                    title = boat.label,
                    menu = 'djfishing_boats',
                    options = times,
                })
                lib.showContext('djfishing_boat_time')
            end,
        }
    end

    lib.registerContext({
        id = 'djfishing_boats',
        title = payload.dock.label,
        options = options,
    })
    lib.showContext('djfishing_boats')
end

function StartBoatDocks(useInteract)
    for i = 1, #Config.BoatDocks do
        createDockBlip(Config.BoatDocks[i])
    end

    local spawnSq = Config.PedSpawn.distanceSq
    local despawnSq = Config.PedSpawn.despawnSq
    local docks = Config.BoatDocks
    local count = #docks

    CreateThread(function()
        while true do
            local coords = GetEntityCoords(cache.ped)
            for i = 1, count do
                local dock = docks[i]
                local dx = coords.x - dock.coords.x
                local dy = coords.y - dock.coords.y
                local distSq = dx * dx + dy * dy
                if distSq <= spawnSq then
                    spawnDockPed(dock, useInteract)
                elseif distSq >= despawnSq then
                    despawnDockPed(dock)
                end
            end
            Wait(Config.PedSpawn.interval)
        end
    end)
end

RegisterNetEvent('djfivem-fishing:client:boardBoat', function(netId, plate, fuel)
    if type(netId) ~= 'number' then return end

    local veh = lib.waitFor(function()
        if not NetworkDoesNetworkIdExist(netId) then return end
        local entity = NetToVeh(netId)
        if entity and entity ~= 0 and DoesEntityExist(entity) then
            return entity
        end
    end, false, 8000)

    if not veh then
        notify('notify_boat_fail', 'error')
        return
    end

    if plate then
        SetVehicleNumberPlateText(veh, plate)
    end
    fillFuel(veh, fuel)
    SetVehicleEngineOn(veh, true, true, false)
    TaskWarpPedIntoVehicle(cache.ped, veh, -1)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for _, entry in pairs(dockPeds) do
        if entry.interactId and GetResourceState('interact') == 'started' then
            pcall(function()
                exports.interact:RemoveLocalEntityInteraction(entry.entity, entry.interactId)
            end)
        end
        if DoesEntityExist(entry.entity) then
            DeleteEntity(entry.entity)
        end
    end
    for i = 1, #dockBlips do
        RemoveBlip(dockBlips[i])
    end
end)

CreateThread(function()
    pcall(function()
        DecorRegister('_FUEL_LEVEL', 1)
    end)
    local useInteract = GetResourceState('interact') == 'started'
    if not useInteract then
        pcall(function()
            lib.waitFor(function()
                return GetResourceState('interact') == 'started' or nil
            end, nil, 15000)
        end)
        useInteract = GetResourceState('interact') == 'started'
    end
    StartBoatDocks(useInteract)
end)
