lib.locale()

local spawnedBlips = {}
local radiusBlips = {}
local shopPeds = {}
local shopOpen = false
local currentShopId
local cachedCatalog

CurrentZone = nil

function IsShopOpen()
    return shopOpen
end

local function notify(key, nType, ...)
    lib.notify({
        title = 'Fishing',
        description = locale(key, ...),
        type = nType or 'inform',
    })
end

Notify = notify

local function nuiCall(name, data)
    SendNUIMessage({ action = name, data = data or {} })
end

local function closeShop()
    if not shopOpen then return end
    shopOpen = false
    currentShopId = nil
    SetNuiFocus(false, false)
    nuiCall('close')
end

CloseShop = closeShop

local function catalogFromConfig()
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

local function openShop(shop, view)
    if shopOpen or IsFishing() then return end
    local payload = lib.callback.await('djfivem-fishing:openShop', false, shop.id)
    if not payload or not payload.ok then
        notify(payload and payload.error or 'notify_too_far', 'error')
        return
    end

    shopOpen = true
    currentShopId = shop.id
    SetNuiFocus(true, true)
    nuiCall('open', {
        ok = true,
        view = view or shop.defaultView or 'shop',
        shop = {
            id = shop.id,
            label = shop.label,
            subtitle = shop.subtitle,
            views = shop.views or Config.ShopViews or { 'shop', 'sell' },
        },
        player = payload.player,
        catalog = catalogFromConfig(),
        fish = payload.fish or {},
        equipment = payload.equipment or {},
        tasks = payload.tasks or {},
        board = payload.board or {},
        you = payload.you or {},
        resetsIn = payload.resetsIn or 0,
    })
end

OpenShop = openShop

local function waitForInteract()
    if GetResourceState('interact') == 'started' then
        return true
    end

    local started = pcall(function()
        lib.waitFor(function()
            return GetResourceState('interact') == 'started' or nil
        end, 'interact resource is not started', 15000)
    end)

    return started and GetResourceState('interact') == 'started'
end

local function addInteract(entity, shop)
    local id = 'djfivem_fishing_' .. shop.id
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
                label = locale('shop_open'),
                action = function()
                    openShop(shop, 'shop')
                end,
            },
            {
                label = locale('shop_sell'),
                action = function()
                    openShop(shop, 'sell')
                end,
            },
        },
    })
    return id
end

local function createShopBlip(shop)
    if not shop.blip then return end
    local blip = AddBlipForCoord(shop.coords.x, shop.coords.y, shop.coords.z)
    SetBlipSprite(blip, shop.blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, shop.blip.scale)
    SetBlipColour(blip, shop.blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(shop.blip.label)
    EndTextCommandSetBlipName(blip)
    spawnedBlips[#spawnedBlips + 1] = blip
end

local function spawnShopPed(shop, useInteract)
    if shopPeds[shop.id] and DoesEntityExist(shopPeds[shop.id].entity) then
        return
    end

    lib.requestModel(shop.ped, 5000)
    local ped = CreatePed(0, shop.ped, shop.coords.x, shop.coords.y, shop.coords.z - 1.0, shop.coords.w, false, true)
    SetEntityAsMissionEntity(ped, true, true)
    SetPedFleeAttributes(ped, 0, false)
    SetPedDiesWhenInjured(ped, false)
    SetPedKeepTask(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)
    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetPedCanRagdollFromPlayerImpact(ped, false)
    SetModelAsNoLongerNeeded(shop.ped)

    if shop.scenario then
        TaskStartScenarioInPlace(ped, shop.scenario, 0, true)
    end

    local interactId
    if useInteract then
        interactId = addInteract(ped, shop)
    end

    shopPeds[shop.id] = { entity = ped, interactId = interactId }
end

local function despawnShopPed(shop)
    local entry = shopPeds[shop.id]
    if not entry then return end

    if entry.interactId and GetResourceState('interact') == 'started' then
        pcall(function()
            exports.interact:RemoveLocalEntityInteraction(entry.entity, entry.interactId)
        end)
    end

    if DoesEntityExist(entry.entity) then
        DeleteEntity(entry.entity)
    end

    shopPeds[shop.id] = nil
end

local function createZoneBlip(zone)
    local style = (zone.offshore and Config.ZoneBlip.offshore) or Config.ZoneBlip[zone.type]
    if not style then return end

    local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
    SetBlipSprite(blip, style.sprite or Config.ZoneBlip.sprite or 68)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, style.scale or Config.ZoneBlip.scale or 0.7)
    SetBlipColour(blip, style.color)
    local shortRange = Config.ZoneBlip.shortRange ~= false
    if style.shortRange ~= nil then
        shortRange = style.shortRange
    end
    SetBlipAsShortRange(blip, shortRange)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentString(('%s · %s'):format(style.label or 'Fishing', zone.name))
    EndTextCommandSetBlipName(blip)
    spawnedBlips[#spawnedBlips + 1] = blip

    if Config.ShowZoneRadius then
        local radius = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
        SetBlipColour(radius, style.color)
        SetBlipAlpha(radius, style.alpha or 70)
        radiusBlips[#radiusBlips + 1] = radius
    end
end

local function setupZones()
    local zones = Config.Zones
    local zoneCount = #zones

    if Config.ShowZoneBlips then
        for i = 1, zoneCount do
            createZoneBlip(zones[i])
        end
    end

    CreateThread(function()
        while true do
            local coords = GetEntityCoords(cache.ped)
            local found, nearestSq

            for i = 1, zoneCount do
                local zone = zones[i]
                local dx = coords.x - zone.coords.x
                local dy = coords.y - zone.coords.y
                local distSq = dx * dx + dy * dy
                if distSq <= zone.radiusSq then
                    found = zone
                    break
                end
                if not nearestSq or distSq < nearestSq then
                    nearestSq = distSq
                end
            end

            if found then
                if not CurrentZone or CurrentZone.name ~= found.name then
                    local previous = CurrentZone
                    CurrentZone = found
                    if found.offshore then
                        notify('zone_enter_offshore', 'inform')
                    elseif not previous or previous.type ~= found.type then
                        notify('zone_enter_' .. found.type, 'inform')
                    end
                end
                Wait(Config.ZoneCheck.inside)
            else
                if CurrentZone then
                    CurrentZone = nil
                end
                local wait = Config.ZoneCheck.far
                if nearestSq and nearestSq < Config.ZoneCheck.nearbySq then
                    wait = Config.ZoneCheck.nearby
                end
                Wait(wait)
            end
        end
    end)
end

local function streamShopPeds(useInteract)
    local spawnSq = Config.PedSpawn.distanceSq
    local despawnSq = Config.PedSpawn.despawnSq

    CreateThread(function()
        while true do
            local coords = GetEntityCoords(cache.ped)
            for i = 1, #Config.Shops do
                local shop = Config.Shops[i]
                local dx = coords.x - shop.coords.x
                local dy = coords.y - shop.coords.y
                local distSq = dx * dx + dy * dy
                if distSq <= spawnSq then
                    spawnShopPed(shop, useInteract)
                elseif distSq >= despawnSq then
                    despawnShopPed(shop)
                end
            end
            Wait(Config.PedSpawn.interval)
        end
    end)
end

CreateThread(function()
    local useInteract = waitForInteract()
    if not useInteract then
        lib.print.error('interact is not started. Shop peds require the interact resource.')
        notify('notify_need_interact', 'error')
    end

    for i = 1, #Config.Shops do
        createShopBlip(Config.Shops[i])
    end

    setupZones()
    streamShopPeds(useInteract)
end)

local function refreshFromServer()
    if not shopOpen or not currentShopId then return nil end
    return lib.callback.await('djfivem-fishing:openShop', false, currentShopId)
end

RegisterNUICallback('close', function(_, cb)
    closeShop()
    cb({ ok = true })
end)

RegisterNUICallback('buy', function(data, cb)
    local result = lib.callback.await('djfivem-fishing:buy', false, currentShopId, data.item, data.amount)
    if result and result.ok then
        notify('notify_bought', 'success', result.amount, result.label, result.total)
        result.refresh = refreshFromServer()
    else
        notify(result and result.error or 'notify_invalid', 'error')
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('sell', function(data, cb)
    local result = lib.callback.await('djfivem-fishing:sell', false, currentShopId, data.item, data.amount)
    if result and result.ok then
        notify('notify_sold', 'success', result.amount, result.label, result.total)
        result.refresh = refreshFromServer()
    else
        notify(result and result.error or 'notify_invalid', 'error')
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('sellAll', function(_, cb)
    local result = lib.callback.await('djfivem-fishing:sellAll', false, currentShopId)
    if result and result.ok then
        notify('notify_sold_all', 'success', result.total)
        result.refresh = refreshFromServer()
    else
        notify(result and result.error or 'notify_no_fish', 'error')
    end
    cb(result or { ok = false })
end)

RegisterNUICallback('refresh', function(_, cb)
    cb(refreshFromServer() or { ok = false })
end)

RegisterNUICallback('claimTask', function(data, cb)
    local result = lib.callback.await('djfivem-fishing:claimTask', false, currentShopId, data and data.id)
    if result and result.ok then
        notify('notify_task_claimed', 'success', result.label, result.money or 0)
        result.refresh = refreshFromServer()
    else
        notify(result and result.error or 'notify_invalid', 'error')
    end
    cb(result or { ok = false })
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closeShop()
    for _, shop in pairs(shopPeds) do
        if shop.interactId and GetResourceState('interact') == 'started' then
            pcall(function()
                exports.interact:RemoveLocalEntityInteraction(shop.entity, shop.interactId)
            end)
        end
        if DoesEntityExist(shop.entity) then
            DeleteEntity(shop.entity)
        end
    end
    for i = 1, #spawnedBlips do
        RemoveBlip(spawnedBlips[i])
    end
    for i = 1, #radiusBlips do
        RemoveBlip(radiusBlips[i])
    end
end)
