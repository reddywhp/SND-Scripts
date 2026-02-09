--[=====[
[[SND Metadata]]
author: reddywhp
version: 0.6.1
description: |
  Slogging through Fishing achievements.  Just tries to catch everything.  Does not help towards anything other than the straight-up fishing numbers.
  -  Moves around from time to time.
  -  Lets you repair your gear before it breaks.
plugin_dependencies:
  - Lifestream
  - vnavmesh
  - AutoHook
configs:
    TargetAchievement:
        description: "What is your target achievement?"
        default: "Any"
        is_choice: true
        choices: [ "Good Things Come to Those Who Bait: La Noscea I", 
            "Good Things Come to Those Who Bait: La Noscea II", 
            "Good Things Come to Those Who Bait: La Noscea III", 
            "Good Things Come to Those Who Bait: La Noscea IV", 
            "Good Things Come to Those Who Bait: La Noscea V", 
            "Good Things Come to Those Who Bait: Black Shroud I", 
            "Good Things Come to Those Who Bait: Black Shroud II", 
            "Good Things Come to Those Who Bait: Black Shroud III", 
            "Good Things Come to Those Who Bait: Black Shroud IV", 
            "Good Things Come to Those Who Bait: Black Shroud V", 
            "Good Things Come to Those Who Bait: Thanalan I", 
            "Good Things Come to Those Who Bait: Thanalan II", 
            "Good Things Come to Those Who Bait: Thanalan III", 
            "Good Things Come to Those Who Bait: Thanalan IV", 
            "Good Things Come to Those Who Bait: Thanalan V", 
            "Baiting Heavensward", 
            "Baiting Stormblood", 
            "Baiting Shadowbringers", 
            "Baiting the End", 
            "Baiting Dawntrail" ]
    Food:
        description: "Leave blank if you don't want to use any food. If its HQ include <hq> next to the name \"Nasi Goreng <HQ>\"."
    Potion:
        description: "Leave blank if you don't want to use any potions. If its HQ include <hq> next to the name \"Superior Spiritbond Potion <hq>\"."
    SelfRepair:
        description: "Automatically repair your own gear when durability is low."
        default: true
    BuyDarkMatter:
        description: "Buy Dark Matter for self repair."
        default: true
    RepairThreshold:
        description: "Durability percentage at which tools should be repaired."
        default: 20
        min: 0
        max: 100
    ExtractMateria:
        description: "Automatically extract materia from fully spiritbonded gear."
        default: true
    MoveSpotsAfter:
        description: "Number of minutes to fish one spot before moving to the next."
        default: 15
        min: 2
        max: 30
    MinInventoryFreeSlots:
        description: "Stop fishing if you have this many spots open."
        default: 5
        min: 0
        max: 140
    ResetHardAmissAfter:
        description: "Number of minutes to farm in current instance before teleporting away and back."
        default: 120
        min: 2
        max: 180
    LoggingTimer:
        description: "How many minutes between log entries"
        default: 5
        min: 1
        max: 30
    
[[End Metadata]]
--]=====]

--[[
    -> 0.6.1    Exit script on achievement completion.
    -> 0.5.3    Fix fish sensing something amiss
    -> 0.5.2    Added Timer reporting
    -> 0.5.1    Basic functionality is working
    -> 0.1a     Typo
    -> 0.1.0    Initial adaptation

********************************************************************************
*                               Required Plugins                               *
********************************************************************************

1. AutoHook
2. VnavMesh
3. Lifestream

]]

--=========================== VARIABLES ==========================--

import("System")
import("System.Numerics")

ScriptName="Baiting Achievements"

-------------------
--    General    --
-------------------

TargetAchievement      = Config.Get("TargetAchievement")
SelfRepair             = Config.Get("SelfRepair")
BuyDarkMatter          = Config.Get("BuyDarkMatter")
RepairThreshold        = Config.Get("RepairThreshold")
ExtractMateria         = Config.Get("ExtractMateria")
MoveSpotsAfter         = Config.Get("MoveSpotsAfter")
ResetHardAmissAfter    = Config.Get("ResetHardAmissAfter")
Food                   = Config.Get("Food")
Potion                 = Config.Get("Potion")
MinInventoryFreeSlots  = Config.Get("MinInventoryFreeSlots")
LoggingTimer           = Config.Get("LoggingTimer")

--============================ CONSTANT ==========================--

----------------------------
--    State Management    --
----------------------------

CharacterState = {}

CharacterCondition = {
    mounted                            = 4,
    gathering                          = 6,
    casting                            = 27,
    occupiedInQuestEvent               = 32,
    occupiedMateriaExtractionAndRepair = 39,
    fishing                            = 43,
    betweenAreas                       = 45,
    occupiedSummoningBell              = 50
}

-----------------
--    Items    --
-----------------


--------------------
--    Merchant    --
--------------------

FishingBaitMerchant = {
    npcName   = "Merchant & Mender",
    x         = -398,
    y         = 3,
    z         = 80,
    zoneId    = 129,
    aetheryte = "Limsa Lominsa",
    aethernet = { name = "Arcanists' Guild", x = -336, y = 12, z = 56 }
}

Mender = {
    npcName   = "Alistair",
    x         = -246.87,
    y         = 16.19,
    z         = 49.83
}

DarkMatterVendor = {
    npcName   = "Unsynrael",
    x         = -257.71,
    y         = 16.19,
    z         = 50.11,
    wait      = 0.08
}

------------------------
--    Collectables    --
------------------------

AutohookEverything = "AH4_H4sIAAAAAAAACuVWTXOjOBD9KymdoQqwwMDN43WyqfIkqTizc5jag4DGqCxLHkk44035v28JkG38lcxWbnuD7tbr1+qnlt7QqNZiTJRW43KO0jc04SRjMGIMpVrW4CDjnFIOe2dhXfcFSoM4cdCTpEJSvUGp76B7NfmVs7qAYm828dsW66sQeWXAmo/AfDU4Ueygu9VLJUFVghUo9T2vh3wdusFIhr0V3rtkxlW9vFAY9j18xCg4YmRBBGOQa1sJ9j3/MCx4n4WQBSWsAeBrkNbQD25pRT7236EV9PyjTKwBpSVhyua7paqabEAdMA6PMMOwjzmw3SMLmFW01F8IbSo2BmUNM03yhUJp2PUjik+Be7C4g30imgLP4YBRdLww6jMK7VJJ/4Ex0a2obNronT2KutUvFWGULNQtWQtpAHoGW8/A6dufIRdrkIaF55w9FVF8op7BqZ6vt+kLnd+RZbMnIz5nIJXlYyRlEIcePim0lyO2bauZppUQi90GB16YHB+4K0LdOmjyS0vSmxK7kk3vX8Tslazuua6ppoLfEcptMtd30LSW8BWUInNAKUIOemhKQw+CA+oQNitAqVHaGbypUPo/4z1JUHCeIXLRBX+bsfHv+cxWkGtJ2LiWErj+pCqPUD+t1rNsTyo+m72JuhUyh+Zgv5KVbXZjLIy1m7n+0OkEOtNiZYYL5fOZhlUjqX2VnYhH8nOKO4Q7remVLjNC9S1lTF3xP9dcPdYW4RunP2swzFCAYxJkGNxwgBMX4yxyE0xiN05whOMSkgCGaOugKVX6sTQsFUp/vDV8zRbshlG7P5eq/AukIpoyuDERBvBByCVhf3Zn1Q7G70AW+4NnvAp6XelM7VZhf5iY3eoWz7QUfP7x5UESHayewhx4QeTmdwH+EHXGdsz7AVGyC9izuxjSo3Am6kXS1aVMwzAY7EIu5eoFXcnWxRmdj0oN8tkoaixqru0+7FxjUs8rPaVLc0/icNC6+qfDC3D3wKplex2bj4Nbp53yYXJ8i1592pjXkB1iVkfP8LOmEoqZJro2N7R5bh2L62MaOoryBpe0ci7wf6CJXuP9c23/WM/xb/Z81o20Ro79a/2Rs803Bd8r4A+ieXeP1oQyc5Stbg9GXzkMBn5cDt0sLomLgyRz46L03dzL8iKHPEkiQNu/7ezrHvQ/doZ2/Jn/duJ2o+4O9M1kDXKjzVbccHGTd+/e/uCFjEQkIK7vxbGL/Sh0szLHLhngEMoo9oY5oO2/u7GGm7kMAAA="

FishTable = {
    {
        AchievementName = "Good Things Come to Those Who Bait: La Noscea I",
        AchievementNumber = 259,
        Spot = "West Agelyss River",
        NumberOfFish = 7,
        zoneId = 134,
        zoneName = "Middle La Noscea",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-34.80, y=45.87, z=-203.31 },
                { x=-53.75, y=45.08, z=-176.26 },
                { x=-88.09, y=44.98, z=-148.15 },
            },
            pointToFace = { x=-66.69, y=45.00, z=-173.75 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Limsa Lominsa Lower Decks",
        AmissResetZoneID            = 129,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: La Noscea II",
        AchievementNumber = 260,
        Spot = "Empty Heart",
        NumberOfFish = 9,
        zoneId = 135,
        zoneName = "Lower La Noscea",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=21.16, y=35.65, z=697.33 },
                { x=8.35, y=35.44, z=689.45 },
                { x=8.22, y=35.44, z=673.76 },
            },
            pointToFace = { x=23.02, y=35.44, z=674.69 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Limsa Lominsa Lower Decks",
        AmissResetZoneID            = 129,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: La Noscea III",
        AchievementNumber = 261,
        Spot = "South Bloodshore",
        NumberOfFish = 10,
        zoneId = 137,
        zoneName = "Eastern La Noscea",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=566.71, y=8.71, z=581.70 },
                { x=525.50, y=8.66, z=682.77 },
            },
            pointToFace = { x=573.53, y=8.4, z=651.59 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Limsa Lominsa Lower Decks",
        AmissResetZoneID            = 129,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: La Noscea IV",
        AchievementNumber = 262,
        Spot = "North Bloodshore",
        NumberOfFish = 10,
        zoneId = 137,
        zoneName = "Eastern La Noscea",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=554.80, y=8.72, z=173.22 },
                { x=533.35, y=8.81, z=118.77 },
            },
            pointToFace = { x=573.04, y=8.43, z=131.18 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Limsa Lominsa Lower Decks",
        AmissResetZoneID            = 129,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: La Noscea V",
        AchievementNumber = 263,
        Spot = "The Ship Graveyard",
        NumberOfFish = 10,
        zoneId = 138,
        zoneName = "Western La Noscea",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-244.92, y=-42.24, z=732.19 },
                { x=-305.71, y=-42.26, z=706.13 },
                { x=-344.85, y=-42.22, z=711.24 },
            },
            pointToFace = { x=-295.06, y=-42.27, z=728.24 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Limsa Lominsa Lower Decks",
        AmissResetZoneID            = 129,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Black Shroud I",
        AchievementNumber = 265,
        Spot = "The Vein",
        NumberOfFish = 8,
        zoneId = 148,
        zoneName = "Central Shroud",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=52.08, y=-12, z=-37.22 },
                { x=73.42, y=-12, z=29.91 }, -- Watermill
                { x=81.09, y=-12, z=37.42 },
            },
            pointToFace = { x=81.14, y=-12, z=85.49 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "New Gridania",
        AmissResetZoneID            = 132,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Black Shroud II",
        AchievementNumber = 266,
        Spot = "Springripple Brook",
        NumberOfFish = 8,
        zoneId = 152,
        zoneName = "East Shroud",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=114.28, y=7.76, z=190.25 },
                { x=114.88, y=8.02, z=192.07 },
            },
            pointToFace = { x=125.08, y=5.22, z=176.13 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "New Gridania",
        AmissResetZoneID            = 132,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Black Shroud III",
        AchievementNumber = 267,
        Spot = "Verdant Drop",
        NumberOfFish = 9,
        zoneId = 152,
        zoneName = "East Shroud",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-61.87, y=16.91, z=5.12 },
                { x=-29.82, y=17.15, z=0.29 },
            },
            pointToFace = { x=-46.73, y=15.69, z=-15.86 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "New Gridania",
        AmissResetZoneID            = 132,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Black Shroud IV",
        AchievementNumber = 268,
        Spot = "Rootslake",
        NumberOfFish = 7,
        zoneId = 153,
        zoneName = "South Shroud",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-108.74, y=-0.43, z=336.70 },
                { x=-146.36, y=-0.44, z=387.20 },
            },
            pointToFace = { x=-158.16, y=-0.15, z=355.32 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "New Gridania",
        AmissResetZoneID            = 132,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Black Shroud V",
        AchievementNumber = 269,
        Spot = "Lake Tahtotl",
        NumberOfFish = 9,
        zoneId = 154,
        zoneName = "North Shroud",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-155.23, y=-10.39, z=-73.63 },
                { x=-160.29, y=-9.54, z=-88.65 },
            },
            pointToFace = { x=-207.99, y=-10.02, z=-86.55 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "New Gridania",
        AmissResetZoneID            = 132,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Thanalan I",
        AchievementNumber = 271,
        Spot = "Upper Soot Creek",
        NumberOfFish = 6,
        zoneId = 141,
        zoneName = "Central Thanalan",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=100.56, y=-2, z=-165.39 },
                { x=124.34, y=-2, z=-183.17 },
            },
            pointToFace = { x=172.29, y=-2, z=-242.88 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Ul'dah - Steps of Nald",
        AmissResetZoneID            = 130,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Thanalan II",
        AchievementNumber = 272,
        Spot = "The Unholy Heir",
        NumberOfFish = 8,
        zoneId = 141,
        zoneName = "Central Thanalan",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=299.11, y=-19.72, z=-165.64 },
                { x=265.05, y=-19.72, z=-132.28 },
                { x=281.53, y=-19.72, z=-86.03 },
            },
            pointToFace = { x=316.14, y=-19.72, z=-115.08 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Ul'dah - Steps of Nald",
        AmissResetZoneID            = 130,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Thanalan III",
        AchievementNumber = 273,
        Spot = "Burnt Lizard Creek",
        NumberOfFish = 6,
        zoneId = 146,
        zoneName = "Southern Thanalan",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=34.73, y=3.61, z=-336.61 },
                { x=35.65, y=3.56, z=-309.33 },
            },
            pointToFace = { x=15.07, y=-16.25, z=-323.77 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Ul'dah - Steps of Nald",
        AmissResetZoneID            = 130,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Thanalan IV",
        AchievementNumber = 274,
        Spot = "Sagolii Desert",
        NumberOfFish = 9,
        zoneId = 146,
        zoneName = "Southern Thanalan",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-435.83, y=-0.59, z=645.48 },
                { x=-423.32, y=-0.95, z=691.30 },
            },
            pointToFace = { x=-496.03, y=-0.59, z=655.54 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Ul'dah - Steps of Nald",
        AmissResetZoneID            = 130,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Good Things Come to Those Who Bait: Thanalan V",
        AchievementNumber = 275,
        Spot = "Ceruleum Field",
        NumberOfFish = 9,
        zoneId = 147,
        zoneName = "Northern Thanalan",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-69.48, y=47, z=29.85 },
                { x=-57.91, y=46.79, z=40.89 },
                { x=-49.24, y=46.87, z=43.11 },
            },
            pointToFace = { x=-68.69, y=47, z=68.65 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Ul'dah - Steps of Nald",
        AmissResetZoneID            = 130,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Baiting Heavensward",
        AchievementNumber = 1311,
        Spot = "The Blue Window",
        NumberOfFish = 9,
        zoneId = 401,
        zoneName = "The Sea of Clouds",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-643.67, y=-64.19, z=-484.30 },
                { x=-638.45, y=-64.92, z=-515.86 },
                { x=-621.05, y=-65.20, z=-541.71 },
                { x=-606.60, y=-64.19, z=-554.24 },
            },
            pointToFace = { x=-738.11, y=-65, z=-548.02 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Foundation",
        AmissResetZoneID            = 418,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Baiting Stormblood",
        AchievementNumber = 1858,
        Spot = "Onokoro",
        NumberOfFish = 7,
        zoneId = 613,
        zoneName = "The Ruby Sea",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-85.85, y=-0.44, z=-572.17 },
                { x=-124.40, y=-0.5, z=-527.79 },
            },
            pointToFace = { x=23.39, y=-0.5, z=-521.56 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Kugane",
        AmissResetZoneID            = 628,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Baiting Shadowbringers",
        AchievementNumber = 2290,
        Spot = "The Jealous One",
        NumberOfFish = 5,
        zoneId = 816,
        zoneName = "Il Mheg",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=229.15, y=70.76, z=-706.48 },
                { x=214.81, y=64.52, z=-670.44 },
                { x=210.81, y=51.18, z=-619.13 },
            },
            pointToFace = { x=187.97, y=25.39, z=-569.34 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "The Crystarium",
        AmissResetZoneID            = 628,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Baiting the End",
        AchievementNumber = 2938,
        Spot = "The Mover Beta",
        NumberOfFish = 7,
        zoneId = 956,
        zoneName = "Labyrinthos",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=323.77, y=154.17, z=-573.98 },
                { x=245.83, y=142.84, z=-532.72 },
            },
            pointToFace = { x=198.89, y=140.34, z=-508.89 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Radz-at-Han",
        AmissResetZoneID            = 963,
        autoHookPreset              = AutohookEverything,
    },
    {
        AchievementName = "Baiting Dawntrail",
        AchievementNumber = 3477,
        Spot = "Miyakabek'zoma",
        NumberOfFish = 5,
        zoneId = 1188,
        zoneName = "Kozama'uka",
        fishingSpots = {
            maxHeight = 1024,
            waypoints = {
                { x=-99.37, y=109.2, z=291.20 },
                { x=-141.66, y=109.2, z=471.10 },
                { x=-207.56, y=109.2, z=538.69 },
            },
            pointToFace = { x=-356.19, y=109.2, z=355.41 },
        },
        baitName                    = "Versatile Lure",
        baitId                      = 29717,
        AmissResetZoneName          = "Tuliyollal",
        AmissResetZoneID            = 1185,
        autoHookPreset              = AutohookEverything,
    },
}


--[[
   Action Functions
  ]]

--[[ Mount ]]
function Mount()
    local mountActionId = 9
    Dalamud.Log(string.format("[%s] Using Mount Roulette...", ScriptName))
    repeat
        Actions.ExecuteGeneralAction(mountActionId)
        yield("/wait 2")
    until Svc.Condition[CharacterCondition.mounted]
end

--[[ Dismount ]]
function Dismount()
    local dismountActionId = 23
    repeat
        Actions.ExecuteGeneralAction(dismountActionId)
        yield("/wait 1")
    until not Svc.Condition[CharacterCondition.mounted]
end

--[[ CastFishing ]]
function CastFishing()
    local castFishingActionId = 289
    Actions.ExecuteAction(castFishingActionId, ActionType.Action)
end

--[[ QuitFishing ]]
function QuitFishing()
    local quitFishingActionId = 299
    Actions.ExecuteAction(quitFishingActionId, ActionType.Action)
end


--[[
   Utility Functions
  ]]

--[[ WaitForPlayer ]]
function WaitForPlayer()
    Dalamud.Log(string.format("[%s] Waiting for player...", ScriptName))
    repeat
        yield("/wait 0.1")
    until Player.Available and not Player.IsBusy
    yield("/wait 0.1")
end

--[[ GetAetheryteName ]]
function GetAetheryteName(zoneId)
    local territoryData = Excel.GetRow("TerritoryType", zoneId)

    if territoryData and territoryData.Aetheryte and territoryData.Aetheryte.PlaceName then
        return tostring(territoryData.Aetheryte.PlaceName.Name)
    else
        return nil
    end
end

--[[ TeleportTo ]]
function TeleportTo(aetheryteName)
    IPC.Lifestream.ExecuteCommand(aetheryteName)
    yield("/wait 1")
    while Svc.Condition[CharacterCondition.casting] do
        yield("/wait 1")
    end
    yield("/wait 1")
    while Svc.Condition[CharacterCondition.betweenAreas] do
        yield("/wait 1")
    end
    yield("/wait 1")
end

--[[ OnChatMessage ]]
function OnChatMessage()
    local message = TriggerData.message
    local patternAmiss = "The fish sense something amiss."
    local patternAchievement = SelectedFish.AchievementName

    if message and message:find(patternAmiss) then
        Dalamud.Log(string.format("[%s] OnChatMessage triggered for Fish sense..!!", ScriptName))
        State = CharacterState.gsFishSense
        Dalamud.Log(string.format("[%s] State Changed → FishSense", ScriptName))
    elseif message and message:find(patternAchievement) then
        Dalamud.Log(string.format("[%s] OnChatMessage triggered for Achievement '%s'", ScriptName, SelectedFish.AchievementName))
        State = CharacterState.gsExit
        Dalamud.Log(string.format("[%s] State Changed -> gsExit", ScriptName))
    end
end

--[[ NeedsRepair ]]
function NeedsRepair(repairThreshold)
    local repairList = Inventory.GetItemsInNeedOfRepairs(repairThreshold)
    local needsRepair = repairList.Count > 0
    Dalamud.Log(string.format("[%s] Items below %d%% durability: %s", ScriptName, repairThreshold, needsRepair and repairList.Count or "None"))
    return needsRepair
end

--[[ CanExtractMateria ]]
function CanExtractMateria()
    local bondedItems = Inventory.GetSpiritbondedItems()
    local count = (bondedItems and bondedItems.Count) or 0
    Dalamud.Log(string.format("[%s] Found %d spiritbonded items.", ScriptName, count))
    return count
end

--[[ HasStatusId ]]
function HasStatusId(statusId)
    local statusList = Player.Status

    if not statusList then
        return false
    end

    for i = 0, statusList.Count - 1 do
        local status = statusList:get_Item(i)
        if status and status.StatusId == statusId then
            return true
        end
    end

    return false
end

--[[ GetDistanceToPoint ]]
function GetDistanceToPoint(dX, dY, dZ)
    local player = Svc.ClientState.LocalPlayer
    if not player or not player.Position then
        Dalamud.Log(string.format("[%s] GetDistanceToPoint: Player position unavailable.", ScriptName))
        return math.huge
    end

    local px = player.Position.X
    local py = player.Position.Y
    local pz = player.Position.Z

    local dx = dX - px
    local dy = dY - py
    local dz = dZ - pz

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance
end

--[[ DistanceBetween ]]
function DistanceBetween(px1, py1, pz1, px2, py2, pz2)
    local dx = px2 - px1
    local dy = py2 - py1
    local dz = pz2 - pz1

    local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
    return distance
end


--[[
   Fishing Functions
  ]]

--[[ InterpolateCoordinates ]]
function InterpolateCoordinates(startCoords, endCoords, n)
    local x = startCoords.x + n * (endCoords.x - startCoords.x)
    local y = startCoords.y + n * (endCoords.y - startCoords.y)
    local z = startCoords.z + n * (endCoords.z - startCoords.z)
    return { waypointX = x, waypointY = y, waypointZ = z }
end

--[[ GetWaypoint ]]
function GetWaypoint(coords, n)
    local total_distance = 0
    local distances = {}

    for i = 1, #coords - 1 do
        local dx = coords[i + 1].x - coords[i].x
        local dy = coords[i + 1].y - coords[i].y
        local dz = coords[i + 1].z - coords[i].z
        local distance = math.sqrt(dx * dx + dy * dy + dz * dz)
        table.insert(distances, distance)
        total_distance = total_distance + distance
    end

    local target_distance = n * total_distance

    local accumulated_distance = 0
    for i = 1, #coords - 1 do
        if accumulated_distance + distances[i] >= target_distance then
            local remaining_distance = target_distance - accumulated_distance
            local t = remaining_distance / distances[i]
            return InterpolateCoordinates(coords[i], coords[i + 1], t)
        end
        accumulated_distance = accumulated_distance + distances[i]
    end

    return { waypointX = coords[#coords].x, waypointY = coords[#coords].y, waypointZ = coords[#coords].z }
end


--[[ SelectNewFishingHole ]]
function SelectNewFishingHole()
    logged = false
    SelectedFishingSpot = GetWaypoint(SelectedFish.fishingSpots.waypoints, math.random())
    local point = IPC.vnavmesh.PointOnFloor(Vector3(SelectedFishingSpot.waypointX, SelectedFish.fishingSpots.maxHeight, SelectedFishingSpot.waypointZ), false, 50)
    SelectedFishingSpot.waypointY = (point and point.Y) or SelectedFishingSpot.waypointY or 0

    SelectedFishingSpot.x = SelectedFish.fishingSpots.pointToFace.x
    SelectedFishingSpot.y = SelectedFish.fishingSpots.pointToFace.y
    SelectedFishingSpot.z = SelectedFish.fishingSpots.pointToFace.z

    SelectedFishingSpot.startTime = os.clock()
    SelectedFishingSpot.timer = 0
    SelectedFishingSpot.lastStuckCheckPosition = { x = Player.Entity.Position.X, y = Player.Entity.Position.Y, z = Player.Entity.Position.Z }
end

--[[ RandomAdjustCoordinates ]]
function RandomAdjustCoordinates(x, y, z, maxDistance)
    local angle = math.random() * 2 * math.pi
    local distance = maxDistance * math.random()

    local randomX = x + distance * math.cos(angle)
    local randomY = y + maxDistance
    local randomZ = z + distance * math.sin(angle)

    return randomX, randomY, randomZ
end

--[[ FoodCheck ]]
function FoodCheck()
    if not HasStatusId(48) and Food ~= "" then
        yield("/item " .. Food)
        yield("/wait 3")
    end
end

--[[ PotionCheck ]]
function PotionCheck()
    if not HasStatusId(49) and Potion ~= "" then
        yield("/item " .. Potion)
        yield("/wait 3")
    end
end

--[[ BaitCheck ]]
function BaitCheck()
    if Inventory.GetItemCount(SelectedFish.baitId) == 0 then
        Dalamud.Log(string.format("[%s] BaitCheck found no %s, return to gsReady for bait acquisition", ScriptName))
    else
        if not Addons.GetAddon("Bait").Ready then
            yield('/action "Bait"')
            yield("/wait 0.2")
            local looper = 0
            while not Addons.GetAddon("Bait").Ready and looper < 50 do
                yield("/wait 0.1")
                looper = looper + 1
            end
            if not Addons.GetAddon("Bait").Ready then
                Dalamud.Log(string.format("[%s] Not able to open bait window", ScriptName))
            end
        end
        yield(string.format("/callback Bait true %d false", SelectedFish.baitId))    
    end
    if Addons.GetAddon("Bait").Ready then
        yield("/callback Bait true -1")
        yield("/wait 1")
    end
end

--[[ SelectFishTable ]]
function SelectFishTable()
    for _, fishTable in ipairs(FishTable) do
        if TargetAchievement == fishTable.AchievementName then
            return fishTable
        end
    end
    Dalamud.Log(string.format("[%s] No matching fish table found for : %s", ScriptName, TargetAchievement))
    return nil
end


--[[
   Character State Functions
  ]]

--[[ CharacterState.gsFishsense ]]
function CharacterState.gsFishSense()
    if Svc.Condition[CharacterCondition.gathering] or Svc.Condition[CharacterCondition.fishing] then
        QuitFishing()
    end

    WaitForPlayer()
    State = CharacterState.gsResetAmiss
    Dalamud.Log(string.format("[%s] State Changed → gsResetAmiss", ScriptName))
end


--[[ CharacterState.gsTeleportFishingZone ]]
function CharacterState.gsTeleportFishingZone()
    if Svc.ClientState.TerritoryType ~= SelectedFish.zoneId then
        local aetheryteName = GetAetheryteName(SelectedFish.zoneId)
        if aetheryteName then
            TeleportTo(aetheryteName)
        end
    elseif Player.Available and not Player.IsBusy then
        yield("/wait 1")
        SelectNewFishingHole()
        ResetHardAmissTime = os.clock()
        State = CharacterState.gsGoToFishingHole
        Dalamud.Log(string.format("[%s] State Changed → GoToFishingHole", ScriptName))
    end
end

--[[ CharacterState.gsGoToFishingHole ]]
function CharacterState.gsGoToFishingHole()
    if Svc.ClientState.TerritoryType ~= SelectedFish.zoneId then
        State = CharacterState.gsTeleportFishingZone
        Dalamud.Log(string.format("[%s] State Changed → TeleportFishingZone", ScriptName))
        return
    end

    local now = os.clock()
    if now - SelectedFishingSpot.startTime > 10 then
        if not Svc.Condition[CharacterCondition.mounted] then
            Mount()
            return
        end
        SelectedFishingSpot.startTime = now
        SelectedFishingSpot.timer = 0
        local x = Player.Entity.Position.X
        local y = Player.Entity.Position.Y
        local z = Player.Entity.Position.Z

        local lastStuckCheckPosition = SelectedFishingSpot.lastStuckCheckPosition

        if lastStuckCheckPosition and lastStuckCheckPosition.x and lastStuckCheckPosition.y and lastStuckCheckPosition.z then
            if GetDistanceToPoint(lastStuckCheckPosition.x, lastStuckCheckPosition.y, lastStuckCheckPosition.z) < 2 then
                Dalamud.Log(string.format("[%s] Stuck in same spot for over 10 seconds.", ScriptName))
                if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
                    IPC.vnavmesh.Stop()
                end
                local rX, rY, rZ = RandomAdjustCoordinates(x, y, z, 20)
                if rX and rY and rZ then
                    IPC.vnavmesh.PathfindAndMoveTo(Vector3(rX, rY, rZ), true)
                    while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                        yield("/wait 1")
                    end
                end
                return
            end
        end
        SelectedFishingSpot.lastStuckCheckPosition = { x = x, y = y, z = z }
    end

    local distanceToWaypoint = GetDistanceToPoint(SelectedFishingSpot.waypointX, Player.Entity.Position.Y, SelectedFishingSpot.waypointZ)
    Dalamud.Log(string.format("[%s] distance to waypoint (%.2f, %.2f, %.2f): %.2f", ScriptName, SelectedFishingSpot.waypointX, SelectedFishingSpot.waypointY, SelectedFishingSpot.waypointZ, distanceToWaypoint))

    if distanceToWaypoint > 10 then
        if not Svc.Condition[CharacterCondition.mounted] then
            Mount()
            State = CharacterState.gsGoToFishingHole
            Dalamud.Log(string.format("[%s] State Changed → GoToFishingHole", ScriptName))
        elseif not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            Dalamud.Log(string.format("[%s] Moving to waypoint: (%.2f, %.2f, %.2f)", ScriptName, SelectedFishingSpot.waypointX, SelectedFishingSpot.waypointY, SelectedFishingSpot.waypointZ))
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(SelectedFishingSpot.waypointX, SelectedFishingSpot.waypointY, SelectedFishingSpot.waypointZ), true)
            while IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() do
                yield("/wait 1")
            end
        end
        yield("/wait 1")
        return
    end

    if Svc.Condition[CharacterCondition.mounted] then
        Dismount()
    end

    State = CharacterState.gsFishing
    Dalamud.Log(string.format("[%s] State Changed gsGoToFishingHole to gsFishing", ScriptName))
end

--[[ CharacterState.gsFishing ]]
function CharacterState.gsFishing()
    if Inventory.GetItemCount(SelectedFish.baitId) == 0 then
        State = CharacterState.gsBuyFishingBait
        Dalamud.Log(string.format("[%s] State Changed → BuyFishingBait", ScriptName))
        return
    end

    if Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots then
        Dalamud.Log(string.format("[%s] Not enough inventory space", ScriptName))
        if Svc.Condition[CharacterCondition.gathering] then
            QuitFishing()
            yield("/wait 1")
        else
            State = CharacterState.gsReduce
            Dalamud.Log(string.format("[%s] State Changed → Reduce", ScriptName))
        end
        return
    end

    if (os.clock() - SelectedFishingSpot.startTime) > (SelectedFishingSpot.timer * 60) then
        Dalamud.Log(string.format("[%s] in current location for %s seconds", ScriptName, (os.clock() - SelectedFishingSpot.startTime)))
        SelectedFishingSpot.timer = SelectedFishingSpot.timer + LoggingTimer
    end
    
    if os.clock() - ResetHardAmissTime > (ResetHardAmissAfter * 60) then
        if Svc.Condition[CharacterCondition.gathering] then
            if not Svc.Condition[CharacterCondition.fishing] then
                QuitFishing()
                yield("/wait 1")
            end
        else
            State = CharacterState.gsResetAmiss
            Dalamud.Log(string.format("[%s] State Changed gsFishing -> gsResetAmiss, forced teleport away to avoid hard amiss", ScriptName))
        end
        return
    elseif os.clock() - SelectedFishingSpot.startTime > (MoveSpotsAfter * 60) then
        if not logged then
            Dalamud.Log(string.format("[%s] Switching fishing spots", ScriptName))
            logged = true
        end
        if Svc.Condition[CharacterCondition.gathering] then
            if not Svc.Condition[CharacterCondition.fishing] then
                QuitFishing()
                yield("/wait 1")
            end
        else
            SelectNewFishingHole()
            State = CharacterState.gsReady
            Dalamud.Log(string.format("[%s] State Changed gsFishing → gsReady, timeout ready", ScriptName))
        end
        return
    elseif Svc.Condition[CharacterCondition.gathering] then
        if (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
            IPC.vnavmesh.Stop()
        end
        yield("/wait 1")
        return
    end

    local now = os.clock()
    if now - SelectedFishingSpot.startTime > 10 then
        local x = Player.Entity.Position.X
        local y = Player.Entity.Position.Y
        local z = Player.Entity.Position.Z

        local lastStuckCheckPosition = SelectedFishingSpot.lastStuckCheckPosition

        if GetDistanceToPoint(lastStuckCheckPosition.x, lastStuckCheckPosition.y, lastStuckCheckPosition.z) < 2 then
            Dalamud.Log(string.format("[%s] Stuck in same spot for over 10 seconds.", ScriptName))
            if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
                IPC.vnavmesh.Stop()
            end
            SelectNewFishingHole()
            State = CharacterState.gsReady
            Dalamud.Log(string.format("[%s] State Changed → Stuck Ready", ScriptName))
            return
        else
            SelectedFishingSpot.lastStuckCheckPosition = { x = x, y = y, z = z }
        end
    end

    if not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning() then
        local genericListType = Type.GetType("System.Collections.Generic.List`1[System.Numerics.Vector3]")
        local vectorList = Activator.CreateInstance(genericListType)
        local vector = Vector3(SelectedFishingSpot.x, SelectedFishingSpot.y, SelectedFishingSpot.z)
        vectorList:Add(vector)
        IPC.vnavmesh.MoveTo(vectorList, false)
        return
    end

    if IPC.vnavmesh.PathfindInProgress() and IPC.vnavmesh.IsRunning() then
        yield("/wait 0.5")
    end

    CastFishing()
    yield("/wait 0.5")
end

--[[ CharacterState.gsBuyFishingBait ]]
function CharacterState.gsBuyFishingBait()
    if Inventory.GetItemCount(SelectedFish.baitId) >= 1 then
        if Addons.GetAddon("Shop").Ready then
            yield("/callback Shop true -1")
        else
            State = CharacterState.gsGoToFishingHole
            Dalamud.Log(string.format("[%s] State Changed → GoToFishingHole", ScriptName))
        end
        return
    end

    if Svc.ClientState.TerritoryType ~= FishingBaitMerchant.zoneId then
        TeleportTo(FishingBaitMerchant.aetheryte)
        return
    end

    local distanceToMerchant = GetDistanceToPoint(FishingBaitMerchant.x, FishingBaitMerchant.y, FishingBaitMerchant.z)
    local distanceViaAethernet = DistanceBetween(FishingBaitMerchant.aethernet.x, FishingBaitMerchant.aethernet.y, FishingBaitMerchant.aethernet.z, FishingBaitMerchant.x, FishingBaitMerchant.y, FishingBaitMerchant.z)

    if distanceToMerchant > distanceViaAethernet + 20 then
        if not IPC.Lifestream.IsBusy() then
            TeleportTo(FishingBaitMerchant.aethernet.name)
        end
        return
    end

    if Addons.GetAddon("TeleportTown").Ready then
        yield("/callback TeleportTown false -1")
        return
    end

    if distanceToMerchant > 5 then
        if not IPC.vnavmesh.PathfindInProgress() and not IPC.vnavmesh.IsRunning() then
            IPC.vnavmesh.PathfindAndMoveTo(Vector3(FishingBaitMerchant.x, FishingBaitMerchant.y, FishingBaitMerchant.z), false)
        end
        return
    end

    if IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning() then
        IPC.vnavmesh.Stop()
        return
    end

    local baitMerchant = Entity.GetEntityByName(FishingBaitMerchant.npcName)
    if not Entity.Player.Target or Entity.Player.Target.Name ~= FishingBaitMerchant.npcName then
        if baitMerchant then
            baitMerchant:SetAsTarget()
        end
        return
    end

    if Addons.GetAddon("SelectIconString").Ready then
        yield("/callback SelectIconString true 0")
    elseif Addons.GetAddon("SelectYesno").Ready then
        yield("/callback SelectYesno true 0")
    elseif Addons.GetAddon("Shop").Ready then
        -- #TODO Change this to be variable based on the target bait
        yield("/callback Shop true 0 3 99 0")
    elseif baitMerchant then
        baitMerchant:Interact()
    end
end

--[[ CharacterState.gsReduce ]]
function CharacterState.gsReduce()
    if Inventory.GetCollectableItemCount(SelectedFish.fishId, 1) > 0 then
        if Addons.GetAddon("PurifyItemSelector").Ready then
            if Addons.GetAddon("PurifyAutoDialog").Ready then
                yield("/wait 1")
                return
            else
                if Addons.GetAddon("PurifyResult").Ready then
                    yield("/click PurifyResult Automatic")
                    yield("/wait 1")
                    return
                else
                    Dalamud.Log(string.format("[%s] Initiating Aetherial Reduction", ScriptName))
                    yield("/callback PurifyItemSelector true 12 0")
                    yield("/wait 1")
                    return
                end
            end
        else
            yield('/action "Aetherial Reduction"')
            yield("/wait 1")
            return
        end
    else
        if Addons.GetAddon("PurifyItemSelector").Ready then
            yield("/callback PurifyItemSelector true -1 0")
            yield("/wait 1")
            return
        end
        if Addons.GetAddon("PurifyResult").Ready then
            yield("/click PurifyResult Close")
            yield("/wait 1")
            return
        end
        if Addons.GetAddon("PurifyAutoDialog").Ready then
            yield("/click PurifyAutoDialog CancelExit")
            yield("/wait 1")
            return
        end
        Dalamud.Log(string.format("[%s] State Changed Reduce → Ready", ScriptName))
        State = CharacterState.gsReady
        return
    end
end

--[[ CharacterState.gsResetAmiss ]]
function CharacterState.gsResetAmiss()
    if Svc.ClientState.TerritoryType == SelectedFish.AmissResetZoneID then
        Dalamud.Log(string.format("[%s] State changed ResetAmiss → Ready", ScriptName))
        State = CharacterState.gsReady
        return
    else
        Dalamud.Log(string.format("[%s] Teleport to %s to hard reset fish amiss sense", ScriptName, SelectedFish.AmissResetZoneName))
        TeleportTo(SelectedFish.AmissResetZoneName)
        return
    end
end
        

--[[ CharacterState.gsRepair ]]
function CharacterState.gsRepair()
    if Addons.GetAddon("SelectYesno").Ready then
        yield("/callback SelectYesno true 0")
        return
    end

    if Addons.GetAddon("Repair").Ready then
        if not NeedsRepair(RepairThreshold) then
            yield("/callback Repair true -1")
        else
            yield("/callback Repair true 0")
        end
        return
    end

    if Svc.Condition[CharacterCondition.occupiedMateriaExtractionAndRepair] then
        Dalamud.Log(string.format("[%s] Repairing...", ScriptName))
        yield("/wait 1")
        return
    end

    local hawkersAlleyAethernetShard = { x = -213.95, y = 15.99, z = 49.35 }

    if SelfRepair then
        if Inventory.GetItemCount(33916) > 0 then
            if NeedsRepair(RepairThreshold) then
                if not Addons.GetAddon("Repair").Ready then
                    local repairActionId = 6
                    Actions.ExecuteGeneralAction(repairActionId)
                    yield("/echo Repairing...")
                    for i=12,1,-2 do
                        yield("/echo ..."..i)
                        yield("/wait 2")
                    end
                end
            else
                State = CharacterState.gsReady
                Dalamud.Log(string.format("[%s] State Changed → Ready", ScriptName))
            end

        elseif BuyDarkMatter then
            if Svc.ClientState.TerritoryType ~= 129 then
                Dalamud.Log(string.format("[%s] Teleporting to Limsa to buy Dark Matter.", ScriptName))
                TeleportTo("Limsa Lominsa Lower Decks")
                return
            end

            local npcVendor = Entity.GetEntityByName(DarkMatterVendor.npcName)
            if GetDistanceToPoint(DarkMatterVendor.x, DarkMatterVendor.y, DarkMatterVendor.z) > (DistanceBetween(hawkersAlleyAethernetShard.x, hawkersAlleyAethernetShard.y, hawkersAlleyAethernetShard.z,DarkMatterVendor.x, DarkMatterVendor.y, DarkMatterVendor.z) + 10) then
                TeleportTo("Hawkers' Alley")
                yield("/wait 1")
            elseif Addons.GetAddon("TeleportTown").Ready then
                yield("/callback TeleportTown false -1")
            elseif GetDistanceToPoint(DarkMatterVendor.x, DarkMatterVendor.y, DarkMatterVendor.z) > 5 then
                if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                    IPC.vnavmesh.PathfindAndMoveTo(Vector3(DarkMatterVendor.x, DarkMatterVendor.y, DarkMatterVendor.z), false)
                end
            else
                if not Entity.Player.Target or Entity.Player.Target.Name ~= DarkMatterVendor.npcName then
                    if npcVendor then
                        npcVendor:SetAsTarget()
                    end
                elseif not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
                    if npcVendor then
                        npcVendor:Interact()
                    end
                elseif Addons.GetAddon("SelectYesno").Ready then
                    yield("/callback SelectYesno true 0")
                elseif Addons.GetAddon("Shop").Ready then
                    yield("/callback Shop true 0 40 99")
                end
            end

        else
            Dalamud.Log(string.format("[%s] SelfRepair disabled. Using Limsa Mender instead.", ScriptName))
            SelfRepair = false
        end

    else
        if NeedsRepair(RepairThreshold) then
            if Svc.ClientState.TerritoryType ~= 129 then
                Dalamud.Log(string.format("[%s] Teleporting to Limsa for Mender.", ScriptName))
                TeleportTo("Limsa Lominsa Lower Decks")
                return
            end

            local npcMender = Entity.GetEntityByName(Mender.npcName)
            if GetDistanceToPoint(Mender.x, Mender.y, Mender.z) > (DistanceBetween(hawkersAlleyAethernetShard.x, hawkersAlleyAethernetShard.y, hawkersAlleyAethernetShard.z, Mender.x, Mender.y, Mender.z) + 10) then
                TeleportTo("Hawkers' Alley")
                yield("/wait 1")
            elseif Addons.GetAddon("TeleportTown").Ready then
                yield("/callback TeleportTown false -1")
            elseif GetDistanceToPoint(Mender.x, Mender.y, Mender.z) > 5 then
                if not (IPC.vnavmesh.PathfindInProgress() or IPC.vnavmesh.IsRunning()) then
                    IPC.vnavmesh.PathfindAndMoveTo(Vector3(Mender.x, Mender.y, Mender.z), false)
                end
            else
                if not Entity.Player.Target or Entity.Player.Target.Name ~= Mender.npcName then
                    if npcMender then
                        npcMender:SetAsTarget()
                    end
                elseif not Svc.Condition[CharacterCondition.occupiedInQuestEvent] then
                    if npcMender then
                        npcMender:Interact()
                    end
                end
            end
        else
            State = CharacterState.gsReady
            Dalamud.Log(string.format("[%s] State Changed → Ready", ScriptName))
        end
    end
end

--[[ CharacterState.gsExtractMateria ]]
function CharacterState.gsExtractMateria()
    if Svc.Condition[CharacterCondition.mounted] then
        Dismount()
        return
    end

    if Svc.Condition[CharacterCondition.occupiedMateriaExtractionAndRepair] then
        yield("/wait 1")
        return
    end

    if CanExtractMateria() > 0 and Inventory.GetFreeInventorySlots() > 1 then
        if not Addons.GetAddon("Materialize").Ready then
            local extractionActionId = 14
            Actions.ExecuteGeneralAction(extractionActionId)
            yield("/wait 3")
            return
        end

        if Addons.GetAddon("MaterializeDialog").Ready then
            yield("/callback MaterializeDialog true 0")
            yield("/wait 3")
        else
            yield("/callback Materialize true 2 0")
            yield("/wait 3")
        end
    else
        if Addons.GetAddon("Materialize").Ready then
            yield("/callback Materialize true -1")
            yield("/wait 3")
        else
            State = CharacterState.gsReady
            Dalamud.Log(string.format("[%s] State Changed → Ready", ScriptName))
            yield("/wait 3")
        end
    end
end

--[[ CharacterState.gsExit ]]
function CharacterState.gsExit()
    if Svc.Condition[CharacterCondition.gathering] or Svc.Condition[CharacterCondition.fishing] then
        QuitFishing()
    end
    ContinueLoop = false
    return
end

--[[ CharacterState.gsReady ]]
function CharacterState.gsReady()
    if Player.Available then
        FoodCheck()
    else
        return
    end
    if Player.Available then
        PotionCheck()
     else
        return
    end
    if Player.Available then
        BaitCheck()
     else
        return
    end

    if not Player.Available then
        return

    elseif RepairThreshold > 0 and NeedsRepair(RepairThreshold) and (SelfRepair and Inventory.GetItemCount(33916) > 0) then
        State = CharacterState.gsRepair
        Dalamud.Log(string.format("[%s] State Changed → Repair", ScriptName))

    elseif ExtractMateria and CanExtractMateria() > 0 and Inventory.GetFreeInventorySlots() > 1 then
        State = CharacterState.gsExtractMateria
        Dalamud.Log(string.format("[%s] State Changed → ExtractMateria", ScriptName))

    elseif Inventory.GetFreeInventorySlots() <= MinInventoryFreeSlots then
        continueLoop = false
        Dalamud.Log(string.format("[%s] Available inventory (%s) at or less than allowed (%s)", ScriptName, Inventory.GetFreeInventorySlots(), MinInventoryFreeSlots))
        return
        
    elseif Inventory.GetItemCount(SelectedFish.baitId) == 0 then
        State = CharacterState.gsBuyFishingBait
        Dalamud.Log(string.format("[%s] State Changed → BuyFishingBait", ScriptName))

    else
        State = CharacterState.gsGoToFishingHole
        Dalamud.Log(string.format("[%s] State Changed → GoToFishingHole", ScriptName))
    end
end

--=========================== EXECUTION ==========================--
--[[
List of CharacterStates:
#TODO Document
  - gsFishSense
    Use OnChatMessage trigger to force relocation when seeing "fish sense something amiss".
  - gsTeleportFishingZone
    Teleport to the zone for fishing using "TeleportTo" function
  - gsGoToFishingHole
    Use vnavmesh to move to a semi-random location for fishing
  - gsFishing
    Do the fishing until hitting minimum free inventory slots.
  - gsBuyFishingBait
    Go buy the bait if needed
  - gsRepair
  - gsExtractMateria
  - gsResetAmiss
    Select place to teleport to and go there to reset hard amiss timer
  - gsReduce
    Reduce all items capable of Aetherial Reduction "Purify"
  - gsReady

    
]]


local logged = false
ResetHardAmissTime = os.clock()

LastStuckCheckTime = os.clock()
LastStuckCheckPosition = {
    x = Player.Entity.Position.X,
    y = Player.Entity.Position.Y,
    z = Player.Entity.Position.Z
}

SelectedFish = SelectFishTable()

if not SelectedFish then
    yield(string.format("/echo %s No fish table for %s. Stopping.", ScriptName, FishToFarm))
    Dalamud.Log(string.format("[%s] No fish table for %s. Stopping.", ScriptName, FishToFarm))
    yield("/snd stop all")
end

if Svc.ClientState.TerritoryType == SelectedFish.zoneId then
    Dalamud.Log(string.format("[%s] In fishing zone already. Selecting new fishing hole.", ScriptName))
    SelectNewFishingHole()
end

IPC.AutoHook.SetPluginState(true)
IPC.AutoHook.DeleteAllAnonymousPresets()
IPC.AutoHook.CreateAndSelectAnonymousPreset(SelectedFish.autoHookPreset)

if Player.Job.Id ~= 18 then
    Dalamud.Log(string.format("[%s] Switching to Fisher.", ScriptName))
    yield("/gs change Fisher")
    yield("/wait 1")
end

State = CharacterState.gsReady
Dalamud.Log(string.format("[%s] State Changed → Ready", ScriptName))

continueLoop = true

while continueLoop do
    State()
    yield("/wait 0.1")
end

--============================== END =============================--
