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

Config.BiteWait = { min = 4500, max = 11000 }
Config.CastDuration = 2200
Config.ReelDuration = { min = 3200, max = 6200 }

Config.LineSnapChance = 0.18 -- extra chance to snap line after a failed fight
Config.LegendarySnapChance = 0.35

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
        label = 'Driftwood Rod',
        description = 'A shoreline rod that will get you started. Low luck for trophy fish.',
        category = 'rods',
        price = 175,
        uses = 40,
        rareBonus = 0,
        weight = 1200,
    },
    fishing_rod_pro = {
        label = 'Carbon Rod',
        description = 'Lighter blank with better hook-sets. Improves rare catch rates.',
        category = 'rods',
        price = 520,
        uses = 90,
        rareBonus = 6,
        weight = 1100,
    },
    fishing_rod_elite = {
        label = 'Offshore Rod',
        description = 'Heavy-action rod built for marlin and shark. Highest rare luck.',
        category = 'rods',
        price = 1450,
        uses = 160,
        rareBonus = 14,
        weight = 1400,
    },
    fishing_reel_basic = {
        label = 'Spin Reel',
        description = 'Reliable spinning reel. Keeps line tension, no extra assist.',
        category = 'reels',
        price = 125,
        uses = 50,
        weight = 450,
    },
    fishing_reel_pro = {
        label = 'Baitcaster',
        description = 'Smoother drag. Makes skill checks a little more forgiving.',
        category = 'reels',
        price = 380,
        uses = 100,
        weight = 500,
    },
    fishing_reel_elite = {
        label = 'Tournament Reel',
        description = 'Saltwater drag system. Biggest skill-check window in the kit.',
        category = 'reels',
        price = 980,
        uses = 180,
        weight = 560,
    },
    fishing_line = {
        label = 'Fishing Line',
        description = 'Mono line. One spool is used every time a fish hits the bait.',
        category = 'line',
        price = 4,
        weight = 20,
    },
    bait_ocean = {
        label = 'Ocean Bait',
        description = 'Cut squid and oily chunks. Required to fish the ocean.',
        category = 'bait',
        price = 8,
        weight = 30,
    },
    bait_lake = {
        label = 'Lake Bait',
        description = 'Live worms and panfish jigs. Required on lakes.',
        category = 'bait',
        price = 5,
        weight = 25,
    },
    bait_river = {
        label = 'River Bait',
        description = 'Roe sacks and spinner bait. Required on rivers.',
        category = 'bait',
        price = 6,
        weight = 25,
    },
}

Config.BaitByZone = {
    ocean = 'bait_ocean',
    lake = 'bait_lake',
    river = 'bait_river',
}

Config.RodOrder = { 'fishing_rod_elite', 'fishing_rod_pro', 'fishing_rod_basic' }
Config.ReelOrder = { 'fishing_reel_elite', 'fishing_reel_pro', 'fishing_reel_basic' }

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
    { name = 'Del Perro Coast', type = 'ocean', coords = vec3(-1850.0, -1275.0, 8.0), radius = 190.0 },
    { name = 'Vespucci Beach', type = 'ocean', coords = vec3(-1405.0, -1450.0, 2.0), radius = 170.0 },
    { name = 'Chumash Pier', type = 'ocean', coords = vec3(-3426.0, 967.0, 8.3), radius = 140.0 },
    { name = 'Paleto Cove', type = 'ocean', coords = vec3(-1605.0, 5255.0, 3.0), radius = 170.0 },
    { name = 'Procopio Beach', type = 'ocean', coords = vec3(1540.0, 6625.0, 2.0), radius = 160.0 },
    { name = 'El Gordo Lighthouse', type = 'ocean', coords = vec3(3315.0, 5184.0, 18.0), radius = 160.0 },
    { name = 'La Puerta Docks', type = 'ocean', coords = vec3(-778.0, -1425.0, 1.0), radius = 140.0 },

    { name = 'Alamo Sea', type = 'lake', coords = vec3(1300.0, 4220.0, 33.0), radius = 420.0 },
    { name = 'Alamo Sea West', type = 'lake', coords = vec3(714.0, 4094.0, 34.0), radius = 180.0 },
    { name = 'Land Act Reservoir', type = 'lake', coords = vec3(1662.0, 42.0, 161.0), radius = 160.0 },
    { name = 'Mirror Park Lake', type = 'lake', coords = vec3(1108.0, -655.0, 57.0), radius = 85.0 },
    { name = 'Vinewood Reservoir', type = 'lake', coords = vec3(1072.0, -324.0, 67.0), radius = 70.0 },

    { name = 'Cassidy Creek', type = 'river', coords = vec3(-840.0, 4430.0, 16.0), radius = 220.0 },
    { name = 'Raton Canyon', type = 'river', coords = vec3(-1518.0, 1516.0, 111.0), radius = 150.0 },
    { name = 'Zancudo River', type = 'river', coords = vec3(-484.0, 2930.0, 27.0), radius = 200.0 },
    { name = 'Grapeseed River', type = 'river', coords = vec3(1670.0, 4508.0, 30.0), radius = 180.0 },
    { name = 'Chilliad River', type = 'river', coords = vec3(-474.0, 4395.0, 31.0), radius = 160.0 },
}

Config.ShowZoneBlips = true
Config.ZoneBlip = {
    ocean = { color = 3, alpha = 80 },
    lake = { color = 2, alpha = 80 },
    river = { color = 4, alpha = 80 },
}

----------------------------------------------------------------
-- Tackle shop / fish buyer peds
----------------------------------------------------------------
Config.Shops = {
    {
        id = 'delperro',
        label = 'Del Perro Tackle',
        subtitle = 'Ocean outfitter',
        ped = `s_m_m_dockwork_01`,
        coords = vec4(-1852.42, -1239.18, 13.02, 319.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 68, color = 1, scale = 0.85, label = 'Fishing Shop' },
        views = { 'shop', 'sell' },
        defaultView = 'shop',
    },
    {
        id = 'chumash',
        label = 'Chumash Bait & Tackle',
        subtitle = 'Pier shop',
        ped = `a_m_m_beach_01`,
        coords = vec4(-3426.55, 982.16, 8.43, 96.0),
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT',
        blip = { sprite = 68, color = 1, scale = 0.85, label = 'Fishing Shop' },
        views = { 'shop', 'sell' },
        defaultView = 'shop',
    },
    {
        id = 'alamo',
        label = 'Alamo Lakeside Tackle',
        subtitle = 'Freshwater shop',
        ped = `a_m_m_hillbilly_01`,
        coords = vec4(1301.09, 4319.37, 38.18, 311.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 68, color = 1, scale = 0.85, label = 'Fishing Shop' },
        views = { 'shop', 'sell' },
        defaultView = 'shop',
    },
    {
        id = 'cassidy',
        label = 'Cassidy Creek Outfitters',
        subtitle = 'River shop',
        ped = `a_m_m_farmer_01`,
        coords = vec4(-811.42, 4394.18, 16.96, 192.0),
        scenario = 'WORLD_HUMAN_SMOKING',
        blip = { sprite = 68, color = 1, scale = 0.85, label = 'Fishing Shop' },
        views = { 'shop', 'sell' },
        defaultView = 'shop',
    },
    {
        id = 'docks',
        label = 'La Puerta Fish Buyer',
        subtitle = 'Wholesale market',
        ped = `s_m_m_linecook_01`,
        coords = vec4(-1038.64, -1397.12, 5.55, 75.0),
        scenario = 'WORLD_HUMAN_CLIPBOARD',
        blip = { sprite = 356, color = 1, scale = 0.8, label = 'Fish Buyer' },
        views = { 'shop', 'sell' },
        defaultView = 'sell',
    },
}

Config.ShopCatalogOrder = {
    'fishing_rod_basic', 'fishing_rod_pro', 'fishing_rod_elite',
    'fishing_reel_basic', 'fishing_reel_pro', 'fishing_reel_elite',
    'fishing_line',
    'bait_ocean', 'bait_lake', 'bait_river',
}
