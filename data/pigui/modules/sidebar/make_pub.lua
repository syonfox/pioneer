
--
--local pubRequirements = {
--    robots = 2,
--    computers = 2,
--    air_processors = 4,
--    industrial_machinery = 2, --10
--    water = 10,
--    liquor = 40,
--    grain = 20, -- 80
--    metal_alloy = 80, -- 160
--    precious_medals = 20 -- 180
--}
--
---- Print the Lua table for verification
--for key, value in pairs(pubRequirements) do
--    print(key .. ": " .. value)
--end


local colonyRequirements = {
    level0 = {
        name = "pub",
        title = "Syon Pub",
        desc = "Its just a landing pad with some beer for a wherey traveler.",
        requirements = {
            robots = 2,
            computers = 2,
            air_processors = 4,
            industrial_machinery = 2, --10
            water = 10,
            liquor = 40,
            grain = 20, -- 80
            metal_alloy = 80, -- 160
            precious_medals = 20 -- 180
        }
    },
    level1 = {
        name = "basic",
        title = "Basic Colony Establishment",
        desc = "Initial requirements for establishing a basic colony.",
        requirements = {
            slaves = 15,                -- Additional workforce needed for basic operations and construction
            live_animals = 10,           -- Livestock for food and potentially for farming
            fertilizer = 10,            -- Essential for soil enrichment in farming
            farming_machinery = 5,      -- Basic tools and equipment for agricultural activities
            industrial_machinery = 5,   -- Basic machinery for initial construction and basic industrial activities
            mining_machinery = 5,       -- Basic equipment for initial resource extraction
            metal_alloys = 60,          -- For construction and basic infrastructure
            precious_metals = 15,       -- Valuable for electronics and trade
            medicine = 15,              -- Essential for healthcare and maintaining crew health
            consumer_goods = 10,        -- Basic supplies for comfort and morale
            textiles = 10,              -- Clothing and basic textile needs
            robots = 10,                -- Initial automation for efficiency and basic tasks
            plastics = 10,               -- Versatile material for various purposes
            water = 10
        }
    },

    -- todo balence past this point
    level2 = {
        name = "farming",
        title = "Farming Colony Upgrade",
        desc = "Additional requirements to upgrade the basic colony to focus on agriculture.",
        requirements = {
            slaves = 10,                -- Additional workforce for expanded agricultural operations
            live_animals = 5,           -- Additional livestock for increased food production
            fertilizer = 10,            -- Continued need for soil enrichment
            farming_machinery = 10,     -- Enhanced tools and equipment for larger-scale farming
            metal_alloys = 40,          -- Additional materials for farm expansions and infrastructure
            precious_metals = 10,       -- Continuation for electronics and trade
            medicine = 10,              -- Continued healthcare needs
            consumer_goods = 5,         -- Additional comfort items for growing population
            textiles = 5,               -- Continued clothing needs
            robots = 8,                 -- Enhanced automation for efficiency in farming tasks
            plastics = 8                -- Continued use for various colony needs
        }
    },
    level3 = {
        name = "mining",
        title = "Mining Colony Upgrade",
        desc = "Additional requirements to upgrade the basic colony to focus on mining activities.",
        requirements = {
            slaves = 15,                -- Increased workforce for mining operations
            mining_machinery = 12,      -- Enhanced equipment for deeper and more efficient mining
            metal_alloys = 50,          -- Additional materials for mining infrastructure and expansion
            precious_metals = 15,       -- Continued need for valuable metals
            medicine = 15,              -- Enhanced healthcare facilities and supplies
            consumer_goods = 10,        -- Additional comforts and supplies for miners
            robots = 10,                -- Automation for mining operations
            plastics = 10               -- Continued use for various colony needs
        }
    },
    level4 = {
        name = "industrial",
        title = "Industrial Colony Upgrade",
        desc = "Additional requirements to upgrade the basic colony to focus on industrial production.",
        requirements = {
            slaves = 20,                -- Expanded workforce for industrial production
            industrial_machinery = 15,  -- Advanced machinery for manufacturing and production
            metal_alloys = 80,          -- Significant materials for industrial infrastructure and expansion
            precious_metals = 25,       -- Increased demand for precious metals in electronics and trade
            medicine = 20,              -- Enhanced healthcare facilities and supplies
            consumer_goods = 15,        -- Increased comfort items for industrial workers
            textiles = 10,              -- Additional clothing and textile needs
            robots = 12,                -- Enhanced automation for industrial efficiency
            plastics = 12               -- Continued use for various colony needs
        }
    }
}

-- Function to calculate total units for each level
local function calculateTotalUnits(level)
    local totalUnits = 0
    for _, value in pairs(colonyRequirements[level].requirements) do
        totalUnits = totalUnits + value
    end
    return totalUnits
end

-- Print information for each level
for i = 0, 4 do
    local level = "level" .. i
    print(colonyRequirements[level].title .. " (" .. colonyRequirements[level].name .. ")")
    print("Description: " .. colonyRequirements[level].desc)
    print("Requirements:")
    for key, value in pairs(colonyRequirements[level].requirements) do
        print(" - " .. key .. ": " .. value)
    end
    print("Total Units: " .. calculateTotalUnits(level))
    print()
end
