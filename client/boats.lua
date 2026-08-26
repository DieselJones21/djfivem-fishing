lib.locale()

local dockPeds = {}
local dockBlips = {}

local function notify(key, nType, ...)
    lib.notify({
        title = 'Boat Rental',
        description = locale(key, ...),
        type = nType or 'inform',
    })
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

function OpenBoatMenu(dock)
    if IsFishing() or IsShopOpen() then return end

    local payload = lib.callback.await('djfivem-fishing:boatMenu', false, dock.id)
    if not payload or not payload.ok then
        notify(payload and payload.error or 'notify_too_far', 'error')
        return
    end

    local options = {}
    if payload.rented then
        local time = payload.rented.remaining
            and ('%dm %ds left'):format(math.floor(payload.rented.remaining / 60), payload.rented.remaining % 60)
            or locale('boat_until_return')
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
        local disabled = payload.rented ~= nil or (payload.cash or 0) < (boat.price + boat.deposit)
        options[#options + 1] = {
            title = boat.label,
            description = locale('boat_option_desc', boat.description, boat.price, boat.deposit),
            icon = 'ship',
            disabled = disabled,
            onSelect = function()
                local result = lib.callback.await('djfivem-fishing:rentBoat', false, dock.id, boat.id)
                if result and result.ok then
                    notify('notify_boat_rented', 'success', result.label, result.price, result.deposit)
                else
                    notify(result and result.error or 'notify_boat_fail', 'error')
                end
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

RegisterNetEvent('djfivem-fishing:client:boardBoat', function(netId, plate)
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
