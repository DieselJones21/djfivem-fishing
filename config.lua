Config = {}

-- 'auto' detects qbx_core, qb-core, then es_extended. Falls back to ox_inventory money item.
Config.Framework = 'auto'

Config.Money = {
    -- 'auto' uses framework cash when ESX/QB/Qbox is present, otherwise ox_inventory item.
    -- 'item' always uses ox_inventory (Config.Money.item).
    -- 'framework' always uses ESX/QB/Qbox account money.
    method = 'auto',
    item = 'money',
    account = 'cash', -- 'cash' or 'bank'
}

Config.Debug = false
Config.FishKey = 'G'
Config.Command = 'fish'
Config.ShopDistance = 3.0
Config.MaxBuyAmount = 50

-- darktrovx/interact (resource name: interact)
Config.Interact = {
    distance = 8.0,
    interactDst = 2.0,
    offset = vec3(0.0, 0.0, 0.18),
}
Config.CastCooldown = 2 -- seconds between resolved casts (server)

-- Rods are used from ox_inventory. Press G (or /fish) to cast with the best rod you have.
Config.RequireZone = true
Config.RequireFacingWater = true
Config.AllowSwimming = false
Config.AllowBoatFishing = true

Config.BiteWait = { min = 4500, max = 11000 }
Config.CastDuration = 2200
Config.ReelDuration = { min = 3200, max = 6200 }

Config.LineSnapChance = 0.08 -- extra chance to snap line after a failed fight
Config.LegendarySnapChance = 0.15

Config.SkillKeys = { 'w', 'a', 's', 'd' }

-- How much a reel opens the skill-check window and slows the needle.
Config.ReelEase = {
    fishing_reel_basic = { area = 0, speed = 0.0 },
    fishing_reel_pro = { area = 8, speed = -0.15 },
    fishing_reel_elite = { area = 16, speed = -0.28 },
}

Config.Difficulty = {
    easy = { areaSize = 52, speedMultiplier = 0.95 },
    medium = { areaSize = 40, speedMultiplier = 1.35 },
    hard = { areaSize = 26, speedMultiplier = 1.7 },
}

----------------------------------------------------------------
-- Equipment sold at tackle shops
----------------------------------------------------------------
Config.Equipment = {
    fishing_rod_basic = {
        label = 'Canal Rod',
        description = 'A Los Santos canal stick. Gets you started on the seawall.',
        category = 'rods',
        price = 175,
        uses = 200,
        rareBonus = 0,
        weight = 1200,
    },
    fishing_rod_pro = {
        label = 'Biscayne Rod',
        description = 'Carbon blank for the bay. Better luck on snook and mahi.',
        category = 'rods',
        price = 520,
        uses = 450,
        rareBonus = 6,
        weight = 1100,
    },
    fishing_rod_elite = {
        label = 'Gulf Stream Rod',
        description = 'Heavy-action rod for tarpon and shark. Highest rare luck.',
        category = 'rods',
        price = 1450,
        uses = 750,
        rareBonus = 14,
        weight = 1400,
    },
    fishing_rod_miami = {
        label = 'Envy Night Rod',
        description = 'Signature Envy blank. Built for silver kings after dark.',
        category = 'rods',
        price = 2200,
        uses = 900,
        rareBonus = 18,
        weight = 1350,
    },
    fishing_reel_basic = {
        label = 'South Beach Spin',
        description = 'Reliable spinning reel. Keeps line tension, no extra assist.',
        category = 'reels',
        price = 125,
        uses = 250,
        weight = 450,
    },
    fishing_reel_pro = {
        label = 'Calle Ocho Caster',
        description = 'Smoother drag. Makes skill checks a little more forgiving.',
        category = 'reels',
        price = 380,
        uses = 500,
        weight = 500,
    },
    fishing_reel_elite = {
        label = 'Midnight Reel',
        description = 'Saltwater drag system. Biggest skill-check window in the kit.',
        category = 'reels',
        price = 980,
        uses = 850,
        weight = 560,
    },
    fishing_line = {
        label = 'Fluoro Line',
        description = 'Clear fluoro. Each spool lasts 20 bites.',
        category = 'line',
        price = 4,
        uses = 20,
        weight = 20,
    },
    fishing_line_braid = {
        label = 'Envy Braid',
        description = 'Cyan braid for the night bite. 40 bites a spool.',
        category = 'line',
        price = 12,
        uses = 40,
        weight = 18,
    },
    bait_ocean = {
        label = 'Cut Bait',
        description = 'Oily chunks. Works the ocean and Biscayne.',
        category = 'bait',
        price = 8,
        weight = 30,
    },
    bait_shrimp = {
        label = 'Live Shrimp',
        description = 'Premium Envy bait. Used first on the ocean if you have it.',
        category = 'bait',
        price = 14,
        weight = 28,
    },
    bait_lake = {
        label = 'Panfish Bait',
        description = 'Live worms and jigs. Required on lakes and canals.',
        category = 'bait',
        price = 5,
        weight = 25,
    },
    bait_river = {
        label = 'Creek Bait',
        description = 'Roe and spinner bait. Required on creeks.',
        category = 'bait',
        price = 6,
        weight = 25,
    },
}

-- String or list. Lists are tried in order so premium bait is spent first.
Config.BaitByZone = {
    ocean = { 'bait_shrimp', 'bait_ocean' },
    lake = 'bait_lake',
    river = 'bait_river',
}

Config.RodOrder = { 'fishing_rod_miami', 'fishing_rod_elite', 'fishing_rod_pro', 'fishing_rod_basic' }
Config.ReelOrder = { 'fishing_reel_elite', 'fishing_reel_pro', 'fishing_reel_basic' }
Config.LineOrder = { 'fishing_line_braid', 'fishing_line' }

function Config.BaitList(zoneType)
    local bait = Config.BaitByZone[zoneType]
    if type(bait) == 'table' then return bait end
    if type(bait) == 'string' then return { bait } end
    return {}
end

----------------------------------------------------------------
-- Fish by water type
-- weight = relative spawn chance in that zone
-- sell = payout in dollars (server-authoritative)
----------------------------------------------------------------
Config.Fish = {
    -- Ocean
    fish_sardine = {
        label = 'Sardine',
        zone = 'ocean',
        weight = 38,
        sell = 15,
        difficulty = 'easy',
        checks = 1,
        rarity = 'common',
        description = 'Dense schooling baitfish. Easy money on the coast.',
    },
    fish_rockfish = {
        label = 'Rockfish',
        zone = 'ocean',
        weight = 28,
        sell = 32,
        difficulty = 'easy',
        checks = 1,
        rarity = 'common',
        description = 'Bottom dweller around pilings and reefs.',
    },
    fish_tuna = {
        label = 'Tuna',
        zone = 'ocean',
        weight = 18,
        sell = 95,
        difficulty = 'medium',
        checks = 2,
        rarity = 'uncommon',
        description = 'Fast pelagic. Puts a real bend in the rod.',
    },
    fish_marlin = {
        label = 'Marlin',
        zone = 'ocean',
        weight = 11,
        sell = 210,
        difficulty = 'hard',
        checks = 2,
        rarity = 'rare',
        description = 'Billfish that will dump your spool if you panic.',
    },
    fish_shark = {
        label = 'Shark',
        zone = 'ocean',
        weight = 5,
        sell = 425,
        difficulty = 'hard',
        checks = 3,
        rarity = 'legendary',
        description = 'Apex coastal hunter. Bring elite tackle.',
    },
    fish_snapper = {
        label = 'Mangrove Snapper',
        zone = 'ocean',
        weight = 22,
        sell = 28,
        difficulty = 'easy',
        checks = 1,
        rarity = 'common',
        description = 'Hangs on seawalls and pilings.',
    },
    fish_snook = {
        label = 'Snook',
        zone = 'ocean',
        weight = 12,
        sell = 110,
        difficulty = 'medium',
        checks = 2,
        rarity = 'uncommon',
        description = 'Linesider under the lights. An Envy classic.',
    },
    fish_permit = {
        label = 'Permit',
        zone = 'ocean',
        weight = 8,
        sell = 88,
        difficulty = 'medium',
        checks = 2,
        rarity = 'uncommon',
        description = 'Spooky flats fish. Soft hands or it is gone.',
    },
    fish_bonefish = {
        label = 'Bonefish',
        zone = 'ocean',
        weight = 7,
        sell = 185,
        difficulty = 'hard',
        checks = 2,
        rarity = 'rare',
        description = 'Grey ghost of the flats. Runs like a stolen car.',
    },
    fish_mahi = {
        label = 'Mahi-Mahi',
        zone = 'ocean',
        weight = 6,
        sell = 240,
        difficulty = 'hard',
        checks = 2,
        rarity = 'rare',
        description = 'Gulf Stream gold. Hits fast and jumps harder.',
    },
    fish_tarpon = {
        label = 'Silver King',
        zone = 'ocean',
        weight = 3,
        sell = 520,
        difficulty = 'hard',
        checks = 3,
        rarity = 'legendary',
        description = 'The Envy trophy. Bring the Night rod.',
    },

    -- Lakes
    fish_bluegill = {
        label = 'Bluegill',
        zone = 'lake',
        weight = 28,
        sell = 12,
        difficulty = 'easy',
        checks = 1,
        rarity = 'common',
        description = 'Panfish stacked under docks and weeds.',
    },
    fish_perch = {
        label = 'Perch',
        zone = 'lake',
        weight = 24,
        sell = 18,
        difficulty = 'easy',
        checks = 1,
        rarity = 'common',
        description = 'Striped school fish along drop-offs.',
    },
    fish_smallmouth_bass = {
        label = 'Smallmouth Bass',
        zone = 'lake',
        weight = 16,
        sell = 40,
        difficulty = 'medium',
        checks = 1,
        rarity = 'uncommon',
        description = 'Fights above its weight on rocky points.',
    },
    fish_largemouth_bass = {
        label = 'Largemouth Bass',
        zone = 'lake',
        weight = 14,
        sell = 52,
        difficulty = 'medium',
        checks = 2,
        rarity = 'uncommon',
        description = 'Ambush predator in the pads.',
    },
    fish_trout = {
        label = 'Trout',
        zone = 'lake',
        weight = 12,
        sell = 68,
        difficulty = 'medium',
        checks = 2,
        rarity = 'uncommon',
        description = 'Cold-water fish that wants clean presentations.',
    },
    fish_catfish = {
        label = 'Catfish',
        zone = 'lake',
        weight = 6,
        sell = 88,
        difficulty = 'hard',
        checks = 2,
        rarity = 'rare',
        description = 'Night feeder. Heavy, ugly, and worth the wait.',
    },
    fish_tilapia = {
        label = 'Tilapia',
        zone = 'lake',
        weight = 20,
        sell = 14,
        difficulty = 'easy',
        checks = 1,
        rarity = 'common',
        description = 'Warm-water panfish stacked in the canals.',
    },
    fish_peacock_bass = {
        label = 'Peacock Bass',
        zone = 'lake',
        weight = 10,
        sell = 72,
        difficulty = 'medium',
        checks = 2,
        rarity = 'uncommon',
        description = 'Miami canal celebrity. Hits like a freight train.',
    },

    -- Rivers
    fish_salmon = {
        label = 'Salmon',
        zone = 'river',
        weight = 65,
        sell = 58,
        difficulty = 'medium',
        checks = 2,
        rarity = 'uncommon',
        description = 'Runs the current. Staple river paycheck.',
    },
    fish_striper = {
        label = 'Striper',
        zone = 'river',
        weight = 35,
        sell = 96,
        difficulty = 'hard',
        checks = 2,
        rarity = 'rare',
        description = 'Striped bass pushing up from the estuary.',
    },
}

----------------------------------------------------------------
-- Fishing waters (stand on shore, face the water, press G)
----------------------------------------------------------------
Config.Zones = {
    -- Ocean
    { name = 'Del Perro Coast', type = 'ocean', coords = vec3(-1850.0, -1275.0, 8.0), radius = 190.0 },
    { name = 'Vespucci Beach', type = 'ocean', coords = vec3(-1405.0, -1450.0, 2.0), radius = 170.0 },
    { name = 'Chumash Pier', type = 'ocean', coords = vec3(-3426.0, 967.0, 8.3), radius = 140.0 },
    { name = 'North Chumash', type = 'ocean', coords = vec3(-3236.0, 1108.0, 2.5), radius = 130.0 },
    { name = 'Pacific Bluffs', type = 'ocean', coords = vec3(-3030.0, 97.0, 11.0), radius = 150.0 },
    { name = 'Paleto Cove', type = 'ocean', coords = vec3(-1605.0, 5255.0, 3.0), radius = 170.0 },
    { name = 'Paleto Bay Pier', type = 'ocean', coords = vec3(-247.0, 6568.0, 10.0), radius = 130.0 },
    { name = 'Hookies Outlook', type = 'ocean', coords = vec3(-2255.0, 4290.0, 2.0), radius = 140.0 },
    { name = 'Procopio Beach', type = 'ocean', coords = vec3(1540.0, 6625.0, 2.0), radius = 160.0 },
    { name = 'El Gordo Lighthouse', type = 'ocean', coords = vec3(3315.0, 5184.0, 18.0), radius = 160.0 },
    { name = 'Cape Catfish', type = 'ocean', coords = vec3(3865.0, 4463.0, 2.7), radius = 130.0 },
    { name = 'San Chianski Shore', type = 'ocean', coords = vec3(2836.0, 4092.0, 6.8), radius = 150.0 },
    { name = 'Palomino Highlands', type = 'ocean', coords = vec3(2828.0, -623.0, 1.5), radius = 140.0 },
    { name = 'La Puerta Docks', type = 'ocean', coords = vec3(-778.0, -1425.0, 1.0), radius = 140.0 },
    { name = 'Elysian Island', type = 'ocean', coords = vec3(127.0, -2695.0, 6.0), radius = 140.0 },
    { name = 'Port of LS', type = 'ocean', coords = vec3(1134.0, -2904.0, 5.9), radius = 150.0 },
    { name = 'Del Perro Pier', type = 'ocean', coords = vec3(-1604.0, -1108.0, 13.0), radius = 130.0 },
    { name = 'Vespucci Canals', type = 'ocean', coords = vec3(-1005.0, -980.0, 2.0), radius = 120.0 },
    { name = 'Humane Labs Shore', type = 'ocean', coords = vec3(3420.0, 3758.0, 30.0), radius = 150.0 },
    { name = 'Paleto Beach', type = 'ocean', coords = vec3(-140.0, 6350.0, 10.0), radius = 140.0 },
    { name = 'Great Ocean Highway', type = 'ocean', coords = vec3(-2505.0, 3650.0, 3.0), radius = 160.0 },
    { name = 'NOOSE Beach', type = 'ocean', coords = vec3(2490.0, -380.0, 3.0), radius = 140.0 },
    { name = 'Terminal Docks', type = 'ocean', coords = vec3(582.0, -3118.0, 6.0), radius = 140.0 },

    -- Lakes
    { name = 'Alamo Sea', type = 'lake', coords = vec3(1300.0, 4220.0, 33.0), radius = 420.0 },
    { name = 'Alamo Sea West', type = 'lake', coords = vec3(714.0, 4094.0, 34.0), radius = 180.0 },
    { name = 'Alamo Sea South', type = 'lake', coords = vec3(1732.0, 3988.0, 31.8), radius = 180.0 },
    { name = 'Alamo Sea East', type = 'lake', coords = vec3(2140.0, 3910.0, 31.0), radius = 170.0 },
    { name = 'Stab City Shore', type = 'lake', coords = vec3(80.0, 3705.0, 39.5), radius = 160.0 },
    { name = 'Land Act Reservoir', type = 'lake', coords = vec3(1662.0, 42.0, 161.0), radius = 160.0 },
    { name = 'Mirror Park Lake', type = 'lake', coords = vec3(1108.0, -655.0, 57.0), radius = 85.0 },
    { name = 'Vinewood Reservoir', type = 'lake', coords = vec3(1072.0, -324.0, 67.0), radius = 70.0 },
    { name = 'Lago Zancudo', type = 'lake', coords = vec3(-2084.0, 2612.0, 2.0), radius = 180.0 },
    { name = 'Galilee', type = 'lake', coords = vec3(1310.0, 4368.0, 39.0), radius = 160.0 },
    { name = 'Sandy Shores Jetty', type = 'lake', coords = vec3(1544.0, 3915.0, 31.5), radius = 150.0 },

    -- Rivers
    { name = 'Cassidy Creek', type = 'river', coords = vec3(-840.0, 4430.0, 16.0), radius = 220.0 },
    { name = 'Raton Canyon', type = 'river', coords = vec3(-1518.0, 1516.0, 111.0), radius = 150.0 },
    { name = 'Zancudo River', type = 'river', coords = vec3(-484.0, 2930.0, 27.0), radius = 200.0 },
    { name = 'Zancudo River South', type = 'river', coords = vec3(-1134.0, 2685.0, 18.0), radius = 160.0 },
    { name = 'Grapeseed River', type = 'river', coords = vec3(1670.0, 4508.0, 30.0), radius = 180.0 },
    { name = 'Grapeseed Canal', type = 'river', coords = vec3(1846.0, 4784.0, 40.0), radius = 140.0 },
    { name = 'Chiliad River', type = 'river', coords = vec3(-474.0, 4395.0, 31.0), radius = 160.0 },
    { name = 'Paleto River', type = 'river', coords = vec3(-219.0, 3902.0, 37.0), radius = 150.0 },
    { name = 'LS River La Mesa', type = 'river', coords = vec3(752.0, -1505.0, 20.0), radius = 140.0 },
    { name = 'Cypress Canal', type = 'river', coords = vec3(920.0, -2210.0, 30.0), radius = 130.0 },
    { name = 'Banham Canyon Creek', type = 'river', coords = vec3(-1465.0, 2148.0, 54.0), radius = 140.0 },
    { name = 'Tongva Valley', type = 'river', coords = vec3(-1578.0, 2105.0, 72.0), radius = 140.0 },
    { name = 'LS River Downtown', type = 'river', coords = vec3(400.0, -1600.0, 20.0), radius = 140.0 },
    { name = 'Paleto Creek', type = 'river', coords = vec3(-575.0, 4428.0, 31.0), radius = 140.0 },
    { name = 'Tataviam Creek', type = 'river', coords = vec3(2588.0, 615.0, 98.0), radius = 130.0 },

    -- Offshore hotspots (boat out to the marker)
    { name = 'Pacific Trench', type = 'ocean', coords = vec3(-2200.0, -2100.0, 0.5), radius = 320.0, offshore = true },
    { name = 'West Current', type = 'ocean', coords = vec3(-3600.0, 400.0, 0.5), radius = 280.0, offshore = true },
    { name = 'Chumash Grounds', type = 'ocean', coords = vec3(-3850.0, 1800.0, 0.5), radius = 280.0, offshore = true },
    { name = 'Paleto Shelf', type = 'ocean', coords = vec3(-2100.0, 6200.0, 0.5), radius = 280.0, offshore = true },
    { name = 'Procopio Deep', type = 'ocean', coords = vec3(800.0, 7200.0, 0.5), radius = 260.0, offshore = true },
    { name = 'El Gordo Banks', type = 'ocean', coords = vec3(3900.0, 6200.0, 0.5), radius = 260.0, offshore = true },
    { name = 'San Chianski Deep', type = 'ocean', coords = vec3(4300.0, 3800.0, 0.5), radius = 280.0, offshore = true },
    { name = 'Palomino Rise', type = 'ocean', coords = vec3(3800.0, -400.0, 0.5), radius = 260.0, offshore = true },
    { name = 'Harbor Mouth', type = 'ocean', coords = vec3(400.0, -3200.0, 0.5), radius = 280.0, offshore = true },
    { name = 'Elysian Drop', type = 'ocean', coords = vec3(-400.0, -2800.0, 0.5), radius = 240.0, offshore = true },
    { name = 'Alamo Deep', type = 'lake', coords = vec3(1550.0, 4080.0, 30.5), radius = 200.0, offshore = true },
    { name = 'Zancudo Basin', type = 'lake', coords = vec3(-2200.0, 2580.0, 0.5), radius = 180.0, offshore = true },
}

for i = 1, #Config.Zones do
    local zone = Config.Zones[i]
    zone.radiusSq = zone.radius * zone.radius
end

-- Shoreline spots stay fishable but do not spam the pause map.
-- Offshore marks stay on so boaters can waypoint them.
Config.ShowZoneBlips = false
Config.ShowOffshoreBlips = true
Config.ShowZoneRadius = false
Config.ZoneBlip = {
    sprite = 68,
    scale = 0.7,
    shortRange = true,
    ocean = { color = 3, label = 'Ocean Fishing' },
    lake = { color = 2, label = 'Lake Fishing' },
    river = { color = 5, label = 'River Fishing' },
    offshore = { sprite = 68, color = 1, scale = 0.8, shortRange = true, label = 'Offshore Fishing' },
}

-- Rare/legendary fish are more likely once you leave the shoreline.
Config.OffshoreLuck = {
    common = 0.55,
    uncommon = 0.9,
    rare = 2.4,
    legendary = 3.2,
}

-- Stream shop peds in only when nearby
Config.PedSpawn = {
    distance = 85.0,
    despawn = 125.0,
    interval = 1500,
}

Config.ZoneCheck = {
    inside = 850,
    nearby = 1500,
    far = 2500,
    nearbyRadius = 220.0,
}

Config.PedSpawn.distanceSq = Config.PedSpawn.distance * Config.PedSpawn.distance
Config.PedSpawn.despawnSq = Config.PedSpawn.despawn * Config.PedSpawn.despawn
Config.ZoneCheck.nearbySq = Config.ZoneCheck.nearbyRadius * Config.ZoneCheck.nearbyRadius

----------------------------------------------------------------
-- Tackle shop / fish buyer peds
----------------------------------------------------------------
Config.Shops = {
    {
        id = 'delperro',
        label = 'Envy Pier Outfitters',
        subtitle = 'Los Santos tackle',
        ped = `s_m_m_dockwork_01`,
        coords = vec4(-1845.09, -1195.53, 19.18, 166.30),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 68, color = 3, scale = 0.85, label = 'Envy Tackle' },
        defaultView = 'shop',
    },
    {
        id = 'chumash',
        label = 'Sunset Bait Co.',
        subtitle = 'Pier shop',
        ped = `a_m_m_beach_01`,
        coords = vec4(-3426.55, 982.16, 8.43, 96.0),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        blip = { sprite = 68, color = 3, scale = 0.85, label = 'Envy Tackle' },
        defaultView = 'shop',
    },
    {
        id = 'alamo',
        label = 'Inland Envy Tackle',
        subtitle = 'Canal shop',
        ped = `a_m_m_hillbilly_01`,
        coords = vec4(1301.09, 4319.37, 38.18, 311.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 68, color = 3, scale = 0.85, label = 'Envy Tackle' },
        defaultView = 'shop',
    },
    {
        id = 'cassidy',
        label = 'Creek & Palm Outfitters',
        subtitle = 'Creek shop',
        ped = `a_m_m_farmer_01`,
        coords = vec4(-811.42, 4394.18, 16.96, 192.0),
        scenario = 'WORLD_HUMAN_SMOKING',
        blip = { sprite = 68, color = 3, scale = 0.85, label = 'Envy Tackle' },
        defaultView = 'shop',
    },
    {
        id = 'docks',
        label = 'Envy Wholesale Market',
        subtitle = 'Cash for catch',
        ped = `s_m_m_linecook_01`,
        coords = vec4(-1038.64, -1397.12, 5.55, 75.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 356, color = 3, scale = 0.8, label = 'Envy Fish Buyer' },
        defaultView = 'sell',
    },
}

Config.ShopCatalogOrder = {
    'fishing_rod_basic', 'fishing_rod_pro', 'fishing_rod_elite', 'fishing_rod_miami',
    'fishing_reel_basic', 'fishing_reel_pro', 'fishing_reel_elite',
    'fishing_line', 'fishing_line_braid',
    'bait_ocean', 'bait_shrimp', 'bait_lake', 'bait_river',
}

Config.ShopViews = { 'shop', 'sell', 'tasks', 'board' }

----------------------------------------------------------------
-- Daily tasks (reset at Config.DailyResetHour, server time)
----------------------------------------------------------------
Config.DailyResetHour = 0
Config.LeaderboardSize = 10

Config.DailyTasks = {
    {
        id = 'catch_any',
        label = 'Pack the cooler',
        description = 'Land 8 fish of any kind today.',
        type = 'catch',
        count = 8,
        reward = { money = 175 },
    },
    {
        id = 'catch_ocean',
        label = 'Biscayne run',
        description = 'Catch 5 ocean fish.',
        type = 'catch_zone',
        zone = 'ocean',
        count = 5,
        reward = { money = 200 },
    },
    {
        id = 'catch_fresh',
        label = 'Canal grind',
        description = 'Catch 5 lake or creek fish.',
        type = 'catch_fresh',
        count = 5,
        reward = { money = 180 },
    },
    {
        id = 'catch_trophy',
        label = 'Silver King',
        description = 'Land a rare or legendary fish.',
        type = 'catch_rarity',
        rarities = { rare = true, legendary = true },
        count = 1,
        reward = { money = 400, items = { { 'bait_shrimp', 5 }, { 'fishing_line_braid', 2 } } },
    },
    {
        id = 'catch_offshore',
        label = 'Gulf Stream',
        description = 'Catch 3 fish at an offshore hotspot.',
        type = 'catch_offshore',
        count = 3,
        reward = { money = 275 },
    },
    {
        id = 'sell_cash',
        label = 'Harbor payout',
        description = 'Sell $400 worth of fish today.',
        type = 'sell',
        count = 400,
        reward = { money = 125 },
    },
    {
        id = 'rent_boat',
        label = 'Launch Envy waters',
        description = 'Rent a boat from any marina.',
        type = 'boat',
        count = 1,
        reward = { money = 75 },
    },
}

----------------------------------------------------------------
-- Boat rentals (real-world clock, not in-game time)
----------------------------------------------------------------
Config.BoatRental = {
    warnAt = 180, -- seconds before expiry to ping the renter
    returnRadius = 32.0,
    lockDoors = false,
    fuel = 100.0,
    spawnTimeout = 20,
}

-- IRL minutes. Price is boat.price * multiplier. Deposit is always refunded on a clean return.
Config.BoatDurations = {
    { id = '15m', label = '15 minutes', minutes = 15, multiplier = 1.0 },
    { id = '30m', label = '30 minutes', minutes = 30, multiplier = 1.8 },
    { id = '1h', label = '1 hour', minutes = 60, multiplier = 3.0 },
    { id = '2h', label = '2 hours', minutes = 120, multiplier = 5.0 },
}

-- Addon spawn names: freeman, gradywhite, 26ftyellowfin
Config.BoatCatalog = {
    freeman = {
        model = joaat('freeman'),
        spawn = 'freeman',
        label = 'Freeman',
        description = 'Center-console fishing boat. Good all-rounder.',
        price = 350,
        deposit = 200,
    },
    gradywhite = {
        model = joaat('gradywhite'),
        spawn = 'gradywhite',
        label = 'Grady White',
        description = 'Coastal walker. Stable for longer trips.',
        price = 450,
        deposit = 250,
    },
    yellowfin = {
        model = joaat('26ftyellowfin'),
        spawn = '26ftyellowfin',
        label = '26ft Yellowfin',
        description = 'Offshore center console. Built for the deep marks.',
        price = 600,
        deposit = 300,
    },
}

Config.BoatHashLookup = {}
for id, boat in pairs(Config.BoatCatalog) do
    Config.BoatHashLookup[boat.model] = id
end

Config.BoatDocks = {
    {
        id = 'vespucci',
        label = 'Envy Marina',
        subtitle = 'Puerto Del Sol',
        ped = `s_m_y_baywatch_01`,
        coords = vec4(-806.42, -1496.64, 1.60, 110.0),
        spawn = vec4(-858.00, -1528.00, 0.20, 110.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        boats = { 'freeman', 'gradywhite', 'yellowfin' },
        blip = { sprite = 410, color = 3, scale = 0.8, label = 'Envy Marina' },
    },
    {
        id = 'chumash',
        label = 'Sunset Marina',
        subtitle = 'Pier launch',
        ped = `a_m_y_beach_01`,
        coords = vec4(-3428.10, 995.20, 8.30, 90.0),
        spawn = vec4(-3485.00, 968.40, 0.40, 90.0),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        boats = { 'freeman', 'gradywhite', 'yellowfin' },
        blip = { sprite = 410, color = 3, scale = 0.8, label = 'Envy Marina' },
    },
    {
        id = 'paleto',
        label = 'North Shore Marina',
        subtitle = 'Bay launch',
        ped = `a_m_m_farmer_01`,
        coords = vec4(-247.80, 6548.40, 11.10, 140.0),
        spawn = vec4(-320.00, 6665.00, 0.40, 40.0),
        scenario = 'WORLD_HUMAN_SMOKING',
        boats = { 'freeman', 'gradywhite', 'yellowfin' },
        blip = { sprite = 410, color = 3, scale = 0.8, label = 'Envy Marina' },
    },
    {
        id = 'alamo',
        label = 'Inland Envy Dock',
        subtitle = 'Canal launch',
        ped = `a_m_m_hillbilly_02`,
        coords = vec4(1540.55, 3907.20, 31.70, 200.0),
        spawn = vec4(1595.00, 3865.00, 30.40, 170.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        boats = { 'freeman', 'gradywhite', 'yellowfin' },
        blip = { sprite = 410, color = 3, scale = 0.8, label = 'Envy Marina' },
    },
}

function Config.GetBoatDuration(id)
    for i = 1, #Config.BoatDurations do
        if Config.BoatDurations[i].id == id then
            return Config.BoatDurations[i]
        end
    end
end

function Config.BoatRentalCost(boat, duration)
    local price = math.floor((boat.price * (duration.multiplier or 1.0)) + 0.5)
    return price, boat.deposit or 0
end

