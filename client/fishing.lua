lib.locale()

local fishing = false

local function isDead()
    local ped = cache.ped
    return IsEntityDead(ped) or IsPedFatallyInjured(ped) or LocalPlayer.state.dead
end

local function inBoat()
    if Config.AllowBoatFishing == false then return false end
    local veh = cache.vehicle
    if not veh then return false end
    if GetVehicleClass(veh) == 14 then return true end
    return Config.BoatHashLookup and Config.BoatHashLookup[GetEntityModel(veh)] ~= nil
end

local function blockedVehicle()
    return cache.vehicle and not inBoat()
end

local frozenBoat

local function freezeBoat(state)
    if frozenBoat and DoesEntityExist(frozenBoat) then
        FreezeEntityPosition(frozenBoat, false)
        if not state then
            SetVehicleEngineOn(frozenBoat, true, true, false)
        end
    end
    frozenBoat = nil
    if not state then return end
    local veh = cache.vehicle
    if veh and GetVehicleClass(veh) == 14 then
        FreezeEntityPosition(veh, true)
        frozenBoat = veh
    end
end

local function facingWater()
    if not Config.RequireFacingWater then return true end
    if Config.AllowBoatFishing ~= false and cache.vehicle then
        if GetVehicleClass(cache.vehicle) == 14 or (Config.BoatHashLookup and Config.BoatHashLookup[GetEntityModel(cache.vehicle)]) then
            return true
        end
    end

    local ped = cache.ped
    local probe = GetOffsetFromEntityInWorldCoords(ped, 0.0, 4.0, 0.4)
    local found = GetWaterHeight(probe.x, probe.y, probe.z + 8.0)

    if not found then
        local pos = GetEntityCoords(ped)
        found = GetWaterHeight(pos.x, pos.y, pos.z + 2.0)
    end

    return found == true or found == 1
end

local function startScenario()
    local ped = cache.ped
    ClearPedTasks(ped)
    TaskStartScenarioInPlace(ped, 'WORLD_HUMAN_STAND_FISHING', 0, true)
end

local function stopScenario()
    local ped = cache.ped
    ClearPedTasks(ped)
    ClearPedSecondaryTask(ped)
end

local function progress(label, duration, canCancel)
    return lib.progressBar({
        duration = duration,
        label = label,
        useWhileDead = false,
        canCancel = canCancel,
        disable = {
            move = true,
            car = true,
            combat = true,
            sprint = true,
        },
    })
end

local function buildSkillCheck(fish, reelEase)
    local base = Config.Difficulty[fish.difficulty] or Config.Difficulty.medium
    local area = math.max(16, (base.areaSize or 40) + (reelEase.area or 0))
    local speed = math.max(0.45, (base.speedMultiplier or 1.2) + (reelEase.speed or 0))
    local steps = {}
    local count = fish.checks or 1

    for _ = 1, count do
        steps[#steps + 1] = { areaSize = area, speedMultiplier = speed }
        area = math.max(14, area - 4)
        speed = speed + 0.08
    end

    return steps
end

function IsFishing()
    return fishing
end

function StartFishing(preferredRod)
    if fishing then
        Notify('notify_busy', 'error')
        return
    end

    if IsShopOpen() then return end

    local ped = cache.ped
    if isDead() then
        Notify('notify_dead', 'error')
        return
    end

    if blockedVehicle() then
        Notify('notify_vehicle', 'error')
        return
    end

    if not Config.AllowSwimming and (IsPedSwimming(ped) or IsPedSwimmingUnderWater(ped)) then
        Notify('notify_swimming', 'error')
        return
    end

    if Config.RequireZone and not CurrentZone then
        Notify('notify_need_zone', 'error')
        return
    end

    if not facingWater() then
        Notify('notify_need_water', 'error')
        return
    end

    fishing = true
    LocalPlayer.state:set('fishing', true, false)
    local boatFishing = inBoat()
    if boatFishing then
        freezeBoat(true)
    else
        startScenario()
        Wait(700)
    end

    while fishing do
        if isDead() or blockedVehicle() then
            break
        end

        if Config.RequireZone and not CurrentZone then
            Notify('notify_need_zone', 'error')
            break
        end

        if not facingWater() then
            Notify('notify_need_water', 'error')
            break
        end

        local prepared = lib.callback.await('djfivem-fishing:prepareCast', false, {
            zone = CurrentZone and CurrentZone.type,
            zoneName = CurrentZone and CurrentZone.name,
            rod = preferredRod,
        })

        if not prepared or not prepared.ok then
            if prepared and prepared.errorArg then
                Notify(prepared.error, 'error', prepared.errorArg)
            else
                Notify(prepared and prepared.error or 'notify_need_rod', 'error')
            end
            break
        end

        if not progress(locale('progress_cast'), Config.CastDuration, true) then
            lib.callback.await('djfivem-fishing:cancelCast', false)
            Notify('notify_cancelled', 'inform')
            break
        end

        local waitTime = math.random(Config.BiteWait.min, Config.BiteWait.max)
        if not progress(locale('progress_wait'), waitTime, true) then
            lib.callback.await('djfivem-fishing:cancelCast', false)
            Notify('notify_cancelled', 'inform')
            break
        end

        local bite = lib.callback.await('djfivem-fishing:onBite', false)
        if not bite or not bite.ok then
            Notify(bite and bite.error or 'notify_no_bite', 'error')
            break
        end

        Notify('notify_bite', 'inform')
        PlaySoundFrontend(-1, 'CHALLENGE_UNLOCKED', 'HUD_AWARDS', true)
        ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', 0.08)

        local steps = buildSkillCheck(bite.fish, bite.reelEase or { area = 0, speed = 0 })
        local won = lib.skillCheck(steps, Config.SkillKeys)

        if won then
            local reelMs = math.random(Config.ReelDuration.min, Config.ReelDuration.max)
            if bite.fish.rarity == 'legendary' then
                reelMs = reelMs + 1800
            end

            if not progress(locale('progress_reel', bite.fish.label), reelMs, true) then
                lib.callback.await('djfivem-fishing:resolveCast', false, false, 'cancel')
                Notify('notify_got_away', 'error')
                break
            end
        end

        local result = lib.callback.await('djfivem-fishing:resolveCast', false, won, won and 'catch' or 'fail')
        if not result or not result.ok then
            Notify(result and result.error or 'notify_got_away', 'error')
            if result and result.stop then
                break
            end
        elseif result.caught then
            Notify('notify_caught', 'success', result.label, result.rarity)
            PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
        else
            Notify(result.snapped and 'notify_line_snap' or 'notify_got_away', 'error')
            if result.rodBroke then
                Notify('notify_rod_broke', 'error')
                break
            end
            if result.reelBroke then
                Notify('notify_reel_broke', 'error')
                break
            end
            if result.snapped then
                -- keep fishing if they still have line; next loop will validate
            end
        end

        preferredRod = nil
        Wait(400)
    end

    fishing = false
    LocalPlayer.state:set('fishing', false, false)
    freezeBoat(false)
    if not inBoat() then
        stopScenario()
    end
    lib.callback.await('djfivem-fishing:cancelCast', false)
end

exports('useRod', function(data)
    StartFishing(data and data.name)
end)

RegisterNetEvent('djfivem-fishing:client:useRod', function(item)
    StartFishing(item and item.name)
end)

if Config.Command and Config.Command ~= '' then
    RegisterCommand(Config.Command, function()
        StartFishing()
    end, false)
end

lib.addKeybind({
    name = 'djfishing_cast',
    description = locale('keybind_fish'),
    defaultKey = Config.FishKey,
    onPressed = function()
        if IsShopOpen() or LocalPlayer.state.invBusy then return end
        StartFishing()
    end,
})

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    if fishing then
        fishing = false
        freezeBoat(false)
        stopScenario()
    end
end)
