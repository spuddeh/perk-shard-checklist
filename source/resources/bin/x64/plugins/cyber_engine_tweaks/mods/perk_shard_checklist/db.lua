-- ======================================================================================
-- Mod Name: Perk Shard Checklist
-- Author: Spuddeh
-- Description: Static Database of Perk Shards (Coords, Facts, IDs)
-- Mod Version: 3.0.0
-- ======================================================================================

local PerkShardsDB = {
  {
    category = "Watson",
    entries = {
      {
        id = "watson_northside",
        name = "Northside (Warehouse)",
        fast_travel = "Offshore St",
        directions =
        "Facing the 'Offshore St' fast travel terminal, turn left and cross the train tracks, turning right onto the street, follow it, and immediately turn left at the intersection. Continue down that road and turn right at the end. Keep going up the street until you see a large warehouse with 'A', 'B', and 'C' on the doors. After clearing the drones, the shard is in a chest on the upper platform at the back of the warehouse.",
        coords = { x = -962.8983, y = 2776.678, z = 30.053505, yaw = 180 },
        requirement = "",
        district = "Watson",
        sub_district = "Northside",

        -- Automation Keys (Populated via Inspector)
        quest_fact = nil,
        container_id = 11141267953235869916ULL -- Found
      },
    }
  },
  {
    category = "Westbrook",
    entries = {
      {
        id = "westbrook_japantown",
        name = "Japantown (Willow St)",
        fast_travel = "Dark Matter",
        directions =
        "From the 'Dark Matter' fast travel terminal, head down the road to the right. Crossing over to the 'Assault in Progress' at the Kiroshi building. The Perk Shard is the main reward, found on a corpse in the trunk of a car.",
        coords = { x = -397.77917, y = 253.49315, z = 22.14943, yaw = 240 },
        requirement = "",
        district = "Westbrook",
        sub_district = "Japantown",

        -- Automation Keys (Populated via Inspector)
        quest_fact = "rng_ma_wbr_jpn_13_finished_seconds",
        container_id = 10703751649953267597ULL -- Found (Optional fallback)
      },
    }
  },
  {
    category = "City Center",
    entries = {
      {
        id = "citycenter_republic_way",
        name = "Corpo Plaza (Republic Way)",
        fast_travel = "Metro: Sarasti & Republic",
        directions =
        "Coming out of 'Metro: Sarasti & Republic', take a left heading east. Across the street from the Drop Point, climb onto the small buildings/AC units. The shard is on a dead body (Cindy Hogan).",
        coords = { x = -1355.2417, y = 444.28317, z = 13.151001, yaw = 85 },
        requirement = "",
        district = "City Center",
        sub_district = "Corpo Plaza",

        -- Automation Keys (Populated via Inspector)
        quest_fact = nil,
        container_id = 5308967096587726338ULL -- Found
      },
      {
        id = "citycenter_memorial_park",
        name = "Corpo Plaza (Memorial Park)",
        fast_travel = "Metro: Memorial Park",
        directions =
        "At an NCPD: Assault in Progress, located inside the 'Metro: Memorial Park' station. The shard is in the circular center of the area.",
        coords = { x = -1305.9713, y = -47.537872, z = 2.1500015, yaw = 1 },
        requirement = "",
        district = "City Center",
        sub_district = "Corpo Plaza",

        -- Automation Keys (Populated via Inspector)
        quest_fact = "rng_ma_cct_cpz_06_finished_seconds",
        container_id = 5900401364668429713ULL
      },
    }
  },
  {
    category = "Heywood",
    entries = {
      {
        id = "heywood_glen",
        name = "The Glen (Ford St)",
        fast_travel = "Ventura & Skyline",
        directions =
        "Facing the 'Ventura & Skyline' fast travel terminal, turn left and head down the street, turn right at the intersection and continue on straight into the alley at the end of the street. The shard is at an NCPD: Assault in Progress on Ford Street.",
        coords = { x = -1984.4291, y = -1027.1007, z = 7.6316757, yaw = 210 },
        requirement = "",
        district = "Heywood",
        sub_district = "The Glen",

        -- Automation Keys (Populated via Inspector)
        quest_fact = "rng_ma_hey_gle_03_finished_seconds",
        container_id = 14761521365856738251ULL
      },
    }
  },
  {
    category = "Santo Domingo",
    entries = {
      {
        id = "santo_arroyo_industrial",
        name = "Arasaka Industrial Park",
        fast_travel = "Arasaka Industrial Park",
        directions =
        "Inside the Arasaka Industrial Park. Can be found in a kit box on the top floor of the central Command Tower during the 'Gimme Danger' main quest.",
        coords = { x = -254.44232, y = -1509.1215, z = 12.610001, yaw = 250 },
        requirement = "Gimme Danger (Can be looted before the mission)",
        district = "Santo Domingo",
        sub_district = "Arroyo",

        -- Automation Keys (Populated via Inspector)
        quest_fact = nil,
        container_id = 16807519934993404690ULL -- Found
      },
      {
        id = "santo_rancho_garage",
        name = "Rancho Coronado (Garage)",
        fast_travel = "Rancho Coronado East",
        directions =
        "From the 'Rancho Coronado East' fast travel terminal, follow the road down to the north-west to a house with wrecked cars outside. Start the 'Reported Crime: Welcome to Night City' by looting the body in the shack outside. The garage with the shard will only open once this quest is active.",
        coords = { x = 641.6564, y = -2166.3987, z = 38.88919, yaw = 330 },
        gig_coords = { x = 356.9766, y = -2021.5840, z = -2.8910, yaw = -80.5498 },
        requirement = "Reported Crime: Welcome to Night City",
        district = "Santo Domingo",
        sub_district = "Rancho Coronado",

        -- Automation Keys (Populated via Inspector)
        quest_fact = nil,
        container_id = 13464244570183847069ULL -- Found
      },
      {
        id = "santo_arroyo_mission_st",
        name = "Arroyo (Mission St)",
        fast_travel = "Red Dirt Bar",
        directions =
        "Facing the Red Dirt Bar fast travel terminal, follow the road straight (south-west). Take the first right and then the next left onto Mission Street. There will be a garage with an NCPD: Assault in Progress on your right. The shard is on the body of Jimmy Kreutz.",
        coords = { x = -874.53455, y = -1008.7321, z = 11.372383, yaw = 330 },
        requirement = "",
        district = "Santo Domingo",
        sub_district = "Arroyo",

        -- Automation Keys (Populated via Inspector)
        quest_fact = "rng_ma_std_arr_09_finished_seconds",
        container_id = 6757251104848085705ULL
      },
    }
  },
  {
    category = "Badlands",
    entries = {
      {
        id = "badlands_rocky_ridge_billboard",
        name = "Badlands (Billboard)",
        fast_travel = "Edgewood Farm",
        directions =
        "From the Edgewood Farm fast travel terminal, follow the road north-west to the second billboard. There will be tire tracks leading off the road to the left. Look for a crashed car with a drone flying around it. The shard is on the body of Darius Loaf.",
        coords = { x = 2288.5564, y = -1051.321, z = 55.478294, yaw = 65 },
        requirement = "",
        district = "Badlands",
        sub_district = "Rocky Ridge",

        -- Automation Keys (Populated via Inspector)
        quest_fact = nil,
        container_id = 13783772799954550023ULL -- Found
      },
      {
        id = "badlands_rocky_ridge_wraith_camp",
        name = "Badlands (Wraith Camp)",
        fast_travel = "Edgewood Farm",
        directions =
        "From the Edgewood Farm fast travel terminal, follow the road north-east until you find a Wraith camp with an NCPD: Suspected Organized Crime Activity. The shard is the main reward for clearing the event.",
        coords = { x = 2870.7043, y = -1014.3431, z = 68.361404, yaw = 200 },
        requirement = "",
        district = "Badlands",
        sub_district = "Rocky Ridge",

        -- Automation Keys (Populated via Inspector)
        quest_fact = nil,
        container_id = 5282874794714734620ULL -- Found
      },
    }
  },
  {
    category = "Dogtown (PL)",
    entries = {
      {
        id = "dogtown_stadium_missable",
        name = "Dogtown (Stadium - Missable)",
        fast_travel = "Stadium Parking",
        directions =
        "\n---!!!MISSABLE!!!---\n\nDuring the 'Dog Eat Dog' intro mission, right after stepping off the elevator into the garage. Look for a broken blue sedan (Villefort) on a platform above you. Climb onto the nearby Thorton Colby pick-up (with Blackwall markings) to jump up. The shard is in the trunk of the blue sedan. The 'Blackwall' red glitch effects lead you towards it.\nIf you do not loot the shard during this mission, there is no legitimate way to go back and get it.",
        coords = { x = -1366.0392, y = -1791.2286, z = 10.321457, yaw = 140 },
        requirement = "Dog Eat Dog",
        district = "Dogtown",
        sub_district = "Stadium",

        -- Automation Keys (Populated via Inspector)
        quest_fact = nil,
        container_id = 10924321826273557083ULL -- Found
      },
      {
        id = "dogtown_stadium_vendor",
        name = "Dogtown (Stadium - Vendor)",
        fast_travel = "EBM Petrochem Stadium",
        directions =
        "Can be purchased from the Junk Shop vendor (run by Marcin Iwinski and Michal Kicinsky) inside the EBM Petrochem Stadium market. The shard is named '72h Extreme Sensory Deprivation' and costs ~17,000 eddies.",
        coords = { x = -1397.7173, y = -2048.7893, z = 71.86578, yaw = 270 },
        requirement = "",
        district = "Dogtown",
        sub_district = "Stadium",

        -- Automation Keys (To be populated via Inspector)
        quest_fact = nil,
        vendor_record = "Character.cz_stadium_junk_01_michal_k", -- Static Record ID
        vendor_ui_id = 9004955ULL,                               -- Vendor MarketSystem ID (from UI)
        container_id = nil
      },
      {
        id = "dogtown_longshore",
        name = "Dogtown (Longshore Stacks)",
        fast_travel = "Longshore Stacks",
        directions =
        "In the Longshore Stacks market area. Go one level below the Junk Shop (run by Laura May / former Media). The shard is in a container in a narrow corridor blocked by destructible cardboard boxes.",
        coords = { x = -2369.396, y = -2652.7573, z = 27.96164, yaw = 65 },
        requirement = "",
        district = "Dogtown",
        sub_district = "Longshore Stacks",

        -- Automation Keys (Populated via Inspector)
        quest_fact = nil,
        container_id = 8216909869566957947ULL -- Found
      },
    }
  }
}

-- This makes the table available to any file that 'requires' it
return PerkShardsDB
