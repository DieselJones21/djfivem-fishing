lib.locale()

local spawnedPeds = {}
local spawnedBlips = {}
local radiusBlips = {}
local spawnedInteracts = {}
local shopOpen = false
local currentShopId

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
        view = view or shop.defaultView or 'shop',
        shop = {
            id = shop.id,
            label = shop.label,
            subtitle = shop.subtitle,
            views = shop.views,
        },
        player = payload.player,
        catalog = payload.catalog,
        fish = payload.fish,
        equipment = payload.equipment,
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
    spawnedInteracts[#spawnedInteracts + 1] = { entity = entity, id = id }
end

local function spawnShop(shop, useInteract)
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

    spawnedPeds[#spawnedPeds + 1] = ped
    if useInteract then
        addInteract(ped, shop)
    end

    if shop.blip then
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
end

local function setupZones()
    local inside = {}

    local function refreshZone()
        local nextZone
        for _, zone in pairs(inside) do
            nextZone = zone
            break
        end
        CurrentZone = nextZone
    end

    for i = 1, #Config.Zones do
        local zone = Config.Zones[i]

        lib.zones.sphere({
            coords = zone.coords,
            radius = zone.radius,
            debug = Config.Debug,
            onEnter = function()
                local previous = CurrentZone
                inside[zone.name] = zone
                CurrentZone = zone
                if not previous or previous.type ~= zone.type then
                    notify('zone_enter_' .. zone.type, 'inform')
                end
            end,
            onExit = function()
                inside[zone.name] = nil
                refreshZone()
            end,
        })

        if Config.ShowZoneBlips then
            local style = Config.ZoneBlip[zone.type]
            local blip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
            SetBlipColour(blip, style.color)
            SetBlipAlpha(blip, style.alpha)
            radiusBlips[#radiusBlips + 1] = blip
        end
    end
end

CreateThread(function()
    local useInteract = waitForInteract()
    if not useInteract then
        lib.print.error('interact is not started. Shop peds require the interact resource.')
        notify('notify_need_interact', 'error')
    end

    for i = 1, #Config.Shops do
        spawnShop(Config.Shops[i], useInteract)
    end
    setupZones()
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

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    closeShop()
    if GetResourceState('interact') == 'started' then
        for i = 1, #spawnedInteracts do
            local entry = spawnedInteracts[i]
            pcall(function()
                exports.interact:RemoveLocalEntityInteraction(entry.entity, entry.id)
            end)
        end
    end
    for i = 1, #spawnedPeds do
        if DoesEntityExist(spawnedPeds[i]) then
            DeleteEntity(spawnedPeds[i])
        end
    end
    for i = 1, #spawnedBlips do
        RemoveBlip(spawnedBlips[i])
    end
    for i = 1, #radiusBlips do
        RemoveBlip(radiusBlips[i])
    end
end)
