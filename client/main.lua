lib.locale()

local spawnedPeds = {}
local spawnedBlips = {}
local radiusBlips = {}
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

local function addTarget(entity, shop)
    exports.ox_target:addLocalEntity(entity, {
        {
            name = 'djfivem_shop_' .. shop.id,
            icon = 'fa-solid fa-shop',
            label = locale('shop_open'),
            distance = Config.TargetDistance,
            onSelect = function()
                openShop(shop, 'shop')
            end,
        },
        {
            name = 'djfivem_sell_' .. shop.id,
            icon = 'fa-solid fa-fish',
            label = locale('shop_sell'),
            distance = Config.TargetDistance,
            onSelect = function()
                openShop(shop, 'sell')
            end,
        },
    })
end

local function spawnShop(shop)
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

    if Config.UseTarget and GetResourceState('ox_target') == 'started' then
        addTarget(ped, shop)
    else
        local point = lib.points.new({
            coords = vec3(shop.coords.x, shop.coords.y, shop.coords.z),
            distance = Config.ShopDistance + 0.5,
            shop = shop,
        })

        function point:onEnter()
            lib.showTextUI(locale('textui_shop'))
        end

        function point:onExit()
            lib.hideTextUI()
        end

        function point:nearby()
            if self.currentDistance < Config.ShopDistance and IsControlJustReleased(0, 38) then
                openShop(self.shop, self.shop.defaultView)
            end
        end
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
    for i = 1, #Config.Shops do
        spawnShop(Config.Shops[i])
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
