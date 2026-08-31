Bridge = {}

local actionStamp = {}

function Bridge.RateLimit(src, key, wait)
    wait = wait or 0.35
    local now = os.clock()
    local bucket = actionStamp[src]
    if not bucket then
        bucket = {}
        actionStamp[src] = bucket
    end
    local last = bucket[key]
    if last and (now - last) < wait then
        return false
    end
    bucket[key] = now
    return true
end

function Bridge.ClearRate(src)
    actionStamp[src] = nil
end

AddEventHandler('playerDropped', function()
    actionStamp[source] = nil
end)

local framework
local ESX
local QBCore

local function detectFramework()
    if Config.Framework ~= 'auto' then
        return Config.Framework
    end

    if GetResourceState('qbx_core') == 'started' then
        return 'qbx'
    end
    if GetResourceState('qb-core') == 'started' then
        return 'qb'
    end
    if GetResourceState('es_extended') == 'started' then
        return 'esx'
    end

    return 'ox'
end

local function ensureFramework()
    if framework then return framework end

    framework = detectFramework()

    if framework == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
    elseif framework == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
    end

    return framework
end

local function moneyMethod()
    if Config.Money.method == 'item' then
        return 'item'
    end
    if Config.Money.method == 'framework' then
        return 'framework'
    end

    local fw = ensureFramework()
    if fw == 'esx' or fw == 'qb' or fw == 'qbx' then
        return 'framework'
    end

    return 'item'
end

local function getEsxPlayer(src)
    ensureFramework()
    if not ESX then return nil end
    return ESX.GetPlayerFromId(src)
end

local function getQbPlayer(src)
    local fw = ensureFramework()
    if fw == 'qbx' then
        return exports.qbx_core:GetPlayer(src)
    end
    if fw == 'qb' then
        if not QBCore then
            QBCore = exports['qb-core']:GetCoreObject()
        end
        return QBCore.Functions.GetPlayer(src)
    end
end

function Bridge.GetPlayerName(src)
    local fw = ensureFramework()

    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if player then
            return player.getName()
        end
    elseif fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if player and player.PlayerData and player.PlayerData.charinfo then
            local info = player.PlayerData.charinfo
            local name = ((info.firstname or '') .. ' ' .. (info.lastname or '')):gsub('^%s+', ''):gsub('%s+$', '')
            if name ~= '' then
                return name
            end
        end
    end

    return GetPlayerName(src) or ('ID ' .. src)
end

function Bridge.GetMoney(src)
    if moneyMethod() == 'item' then
        return exports.ox_inventory:GetItemCount(src, Config.Money.item) or 0
    end

    local fw = ensureFramework()
    local account = Config.Money.account or 'cash'

    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if not player then return 0 end
        if account == 'bank' then
            local data = player.getAccount('bank')
            return data and data.money or 0
        end
        return player.getMoney() or 0
    end

    if fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if not player then return 0 end
        return player.Functions.GetMoney(account) or 0
    end

    return exports.ox_inventory:GetItemCount(src, Config.Money.item) or 0
end

function Bridge.RemoveMoney(src, amount)
    amount = math.floor(amount or 0)
    if amount <= 0 then return true end
    if Bridge.GetMoney(src) < amount then return false end

    if moneyMethod() == 'item' then
        return exports.ox_inventory:RemoveItem(src, Config.Money.item, amount) == true
    end

    local fw = ensureFramework()
    local account = Config.Money.account or 'cash'

    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if not player then return false end
        if account == 'bank' then
            player.removeAccountMoney('bank', amount)
        else
            player.removeMoney(amount)
        end
        return true
    end

    if fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if not player then return false end
        player.Functions.RemoveMoney(account, amount, 'djfivem-fishing')
        return true
    end

    return exports.ox_inventory:RemoveItem(src, Config.Money.item, amount) == true
end

function Bridge.AddMoney(src, amount)
    amount = math.floor(amount or 0)
    if amount <= 0 then return true end

    if moneyMethod() == 'item' then
        return exports.ox_inventory:AddItem(src, Config.Money.item, amount) == true
    end

    local fw = ensureFramework()
    local account = Config.Money.account or 'cash'

    if fw == 'esx' then
        local player = getEsxPlayer(src)
        if not player then return false end
        if account == 'bank' then
            player.addAccountMoney('bank', amount)
        else
            player.addMoney(amount)
        end
        return true
    end

    if fw == 'qb' or fw == 'qbx' then
        local player = getQbPlayer(src)
        if not player then return false end
        player.Functions.AddMoney(account, amount, 'djfivem-fishing')
        return true
    end

    return exports.ox_inventory:AddItem(src, Config.Money.item, amount) == true
end

function Bridge.GetIdentifier(src)
    if GetPlayerIdentifierByType then
        local license = GetPlayerIdentifierByType(src, 'license2') or GetPlayerIdentifierByType(src, 'license')
        if license and license ~= '' then
            return license
        end
    end

    local identifiers = GetPlayerIdentifiers(src) or {}
    for i = 1, #identifiers do
        local value = identifiers[i]
        if value and value:find('license', 1, true) then
            return value
        end
    end

    return ('name:%s'):format(GetPlayerName(src) or src)
end

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    ensureFramework()
    lib.print.info(('Framework: %s  |  Money: %s'):format(ensureFramework(), moneyMethod()))
end)
