--Syon Mod Main File
-- By syonfox
-- adds a sidebar and logic for clandestin missions

local Commodities = require 'Commodities'
local utils = require 'utils'
local Vector2 = _G.Vector2
local ShipDef = require 'ShipDef'

local Lang = require 'Lang'
local lui = Lang.GetResource("ui-core");
local ui = require 'pigui'

local msgbox = require 'pigui.libs.message-box' -- like browser alert

-- cache ui
local pionillium = ui.fonts.pionillium
local colors = ui.theme.colors
local icons = ui.theme.icons
local buttonColors = ui.theme.buttonColors

local style = {
    cargoColor = colors.gaugeCargo,
    jettisonColor = colors.gaugeJettison
}

local AMT_OF_AMT = "%st / %st"

local gameView = require 'pigui.views.game' -- used to register the sidbar

local Game = require 'Game'                 -- notibaly Game.system and Game.player
local Player = require 'Player'
local Event = require 'Event'               -- Subscribe to game events for logic
local Engine = require 'Engine'
local Timer = require 'Timer'               -- Create Timers
local Serializer = require 'Serializer'
local Legal = require 'Legal'
local SpaceStation = require 'SpaceStation'
local Equipment = require 'Equipment'
local EquipSet = require 'EquipSet'


-------------------------------------------------------------------------------
-- Syon Mod Global object / data namspace
-------------------------------------------------------------------------------
-- Define the FOXI object
local FOXI = {
    roles = {
        {
            title = "Negotiating Open Contracts",
            shortDescription =
            "FOXI acts as the galaxy's smoothest negotiator, securing win-win deals between free traders and factions.",
            longTooltip =
            "FOXI's negotiation prowess isn't just about sealing the deal—it's about optimizing resource exchanges and profit margins, ensuring both sides benefit from the agreements. Its advanced algorithms analyze market trends and factional needs to craft contracts that promote economic growth and stability across the galaxy."
        },
        {
            title = "Establishing Resource Exports to Sol Fed",
            shortDescription =
            "FOXI transforms rival resources into Sol Fed's economic fuel, navigating complex supply chains with precision.",
            longTooltip =
            "By identifying lucrative export opportunities from rival factions, FOXI strategically channels valuable resources to Sol Fed. Its meticulous planning and coordination with free traders ensure a steady flow of goods, bolstering Sol Fed's economic prosperity and influence in the galaxy."
        },
        {
            title = "Establishing Resource Exports to Commonwealth",
            shortDescription =
            "FOXI brokers resource trades that bridge factional divides, enriching both sides in a galaxy of shifting alliances.",
            longTooltip =
            "Facilitating resource exports to Commonwealths, FOXI fosters cooperation and stability among factions. Its strategic agreements not only optimize resource utilization but also nurture inter-factional relationships, fostering a collaborative environment that benefits all parties involved."
        },
        {
            title = "Disrupting Competitors of Commonwealth",
            shortDescription =
            "FOXI outsmarts rivals with cunning tactics, weakening threats to Commonwealth interests across the stars.",
            longTooltip =
            "FOXI's intelligence operations are at the forefront of disrupting competitors of Commonwealths. Through careful analysis and covert actions, it exposes vulnerabilities in rival factions' strategies, employing measures from economic sanctions to strategic alliances with counteracting factions, all aimed at safeguarding Commonwealths' economic and political standing."
        },
        {
            title = "Disrupting Competitors of Sol Fed",
            shortDescription =
            "FOXI defends Sol Fed's economic dominance with calculated precision, thwarting rivals in the cosmic game of power.",
            longTooltip =
            "Safeguarding Sol Fed's economic supremacy, FOXI employs a range of disruptive strategies. From intercepting critical supply routes to destabilizing rival markets, FOXI's actions are designed to maintain and strengthen Sol Fed's position as a leading economic force in the galaxy. Its meticulous analysis and swift responses ensure that threats to Sol Fed's interests are effectively neutralized."
        },
        {
            title = "Establishing a Syon Free Traders Pub",
            shortDescription =
            "FOXI pioneers the establishment of a Syon Free Traders pub in an uncharted or disrupted system, fostering a hub for commerce and camaraderie.",
            longTooltip =
            "In an effort to expand the network of Syon Free Traders, FOXI undertakes the bold initiative of establishing a pub in a remote, uninhabited, or recently disrupted system. The pub serves not only as a gathering place for traders but also as a nexus for exchanging information, negotiating deals, and fostering community among independent operators. FOXI oversees the logistical challenges of infrastructure development, security arrangements, and cultural integration, ensuring that the pub becomes a beacon of opportunity and solidarity in the vast expanse of the galaxy."
        }

    },
    galactic_news = {
        "FOXI Co. unveils new Syontrix model, promising enhanced versatility and performance.",
        "Conflict escalates in Syon 570 as tensions rise between SolFed, Commonwealths, and FOXI Free Traders.",
        "Syon 570's gas giant refueling stations report record profits, boosting local economy.",
        "FOXI Co. agent computer plugin now available, revolutionizing in-flight operations across the galaxy.",
        "Rumors swirl of a clandestine operation by FOXI Co. disrupting key SolFed supply routes.",
        "New Syontric_gvnr_none variant spotted in combat trials, sparking debates over its tactical advantages."
    },

    save_data = {
        init = false,
    },

    display_ads = {

    }
}



-------------------------------------------------------------------------------
-- Pionere mod system save load data system
-------------------------------------------------------------------------------
--Event.Register("onGameStart", onGameStart)
-- we need to init memory (lets design this not to save stuff for now )
local function onGameStart()
    -- when the game starts for the first time ask the user to join
    local ship = Game.player

    local function okFineThen()
        msgbox.OK("No worries we are all free peoples. If you wish to join later find us at Syon 570.")
    end
    local function joinCallback()
        FOXI.save_data.joined = Game.time

        Timer:CallAt(Game.time + 1, function()
            msgbox.OK(
                "Welcome. Once you obtain an syontrix ship the mission computer will be fully intagrated.. Good luck!")
        end)


        --Timer:CallAt(Game.time + 15, function ()
        --     msgbox.OK_CANCEL("",
        --     function()
        --     end,
        --     function()
        --     end)
        --end)

        --Timer.CallAt(5, cancelCallback)
        --msgbox.OK("Welcome. Once you obtain an syontrix ship the mission computer will be fully intagrated.. Good luck!")
    end
    local function cancelCallback()
        FOXI.save_data.joined = 0
        Timer:CallAt(Game.time + 1, okFineThen)
    end


    FOXI.save_data.rewards_given = {};
    FOXI.save_data.joined = 0;
    if FOXI.save_data.init == false then
        msgbox.OK_CANCEL("Welcome to pioneer. Would you like to join the Syon Free Traders & Co?",
            joinCallback, cancelCallback)
    end
    --if FOXI.save_data.init == false then
    --    msgbox.OK("No worries we are all free peoples. If you wish to join later find us at Syon 570.")
    --end
    print("Player game started: joined since "..tostring(FOXI.save_data.joined))
    --update_display_ads(player)



    -- we know that we have valid foxi save data now.
    FOXI.save_data.init = true;
end
--Event.Register("onGameEnd", onGameEnd)
local function onGameEnd()
    -- here we reset / clenaup data on game end .. duh ;)
    FOXI.save_data = {
        init = false
    }
end

local serialize = function()
    return FOXI.save_data
end

local unserialize = function(data)
    FOXI.save_data = data
end

-- let state = {
-- joined
-- rewards_given
-- missions_offered
--
--}

-------------------------------------------------------------------------------
-- Event hooks for the game
-------------------------------------------------------------------------------

--Event.Register("onEnterSystem", onEnterSystem)
-- reload the missions avalible
local function onEnterSystem(ship)
    if not ship.IsPlayer() then return end -- dont care about non player movments
end
--Event.Register("onShipDestroyed", onShipDestroyed)
-- if active mission award player.
local function onShipDestroyed(ship, attacker)
    if (attacker == nil) then
        print("yo")
    end

    if ship.IsPlayer() or (not nil == attacker and not attacker.IsPlayer()) then return end -- dont count players or other battles

    local SF = "Solar Federation"
    local CW = "Commonwealth of Independent Worlds"
    local SY = "Syon Free Traders & Company"

    --For each ship killed in enemy territory the faction will pay 1000cr
    --
    --If you are detected by the law then we cannot be associated with you have a nice life
    --
    --To receive your payment visit world controlled by contracting faction.
    --
    --You may return to Syon 570 for a new identity.
    --
    --CW -> SF
    --SF -> CW

    -- mecanic. ships will simply build up .. therfore if you manage to pay off your fine then all is good.
    -- good luck with that ;)

    --sub mecanic clandestin missions count at 10x towards fine payoffs therfore if you ow 1000000cr you can kill 1000 enemy ships to pay it


    -- todo check if the ship is poliece
end
--Event.Register("onLeaveSystem", onLeaveSystem)
-- calculate total and add it to data.
local function onLeaveSystem(ship)
    if not ship.IsPlayer() then return end -- dont care about non player movments

    -- add rewards to memory for when arives at payable location.
end


local function uiopen()
    local ship = Game.player
    -- ok idk what to do here but if needed lets put them in the same place
    -- this is called when the tab is switched back to flight view and the ui is opened
    -- OR when the user click the button to open the ui.  aka when first fram is done rendering?
end





-------------------------------------------------------------------------------
--FOXI GALACTIC NEWS (no we did not invent ftl coms) its static news updated when you got to the stations .. aka never updated .. todo
-------------------------------------------------------------------------------
local newsIndex = 1; -- todo make the increment wait one month before releasing the next news.

-- Array of FOXI.GalacticNews
-- Function to pick a random news item and display it
local function displayRandomNews()
    --         local randomIndex = math.random(1, #foxiGalacticNews)
    local selectedNews = FOXI.galactic_news[newsIndex]
    newsIndex = newsIndex + 1
    if (newsIndex > #FOXI.galactic_news) then
        newsIndex = 1
    end

    msgbox.OK(selectedNews)
end


local function check_syon_ship()
    local isFoxiShip = string.sub(Game.player.shipId, 1, 4) == "syon"
    return isFoxiShip
end

-------------------------------------------------------------------------------
-- FOXI MISSIONS LOGIC
-------------------------------------------------------------------------------
local SY = "Syon Free Traders & Company"
local CW = "Commonwealth of Independent Worlds"
local SF = "Solar Federation"

-- a utility to check if you are in the system of this faction
local function in_system_of(faction_name)
    return Game.system.faction.name == faction_name
end


local function check_foxi_missions()
    --local system = Game.system
    local inSystemClean = Player.GetLegalStatus(Game.player, Game.system.faction.name) == 'CLEAN'

    local isGovTypeNone = Game.system.govtype == "NONE"
    --local current_systempath = sectorView:GetCurrentSystemPath()


    -- if user is not syon clean thy are not an agent
    local inSYClean = Player.GetLegalStatus(Game.player, SY) == 'CLEAN'
    if not inSYClean then return nil end


    -- if user is fugitive in an faction contract earnings will go towards their pardoning at 10x rate ;)
    -- if user is fugitive in clandestin tagert then they are not elagable for operations as faction canot be assoseated with fugitives.



    local inSFClean = Player.GetLegalStatus(Game.player, SF) == 'CLEAN'
    local inCWClean = Player.GetLegalStatus(Game.player, CW) == 'CLEAN'

    local missions = {
        {
            contractor = SY,
            name = "Establish Pub",
            --location = "NO_CENTRAL_GOVERNANCE", -- only show if this system has nocental governance
            avalible = inSYClean and isGovTypeNone
        },
        {
            -- only sho
            contractor = CW,
            name = "Disureupt The Solar Federation",
            avalible = inSFClean and in_system_of(SF)
        },
        {
            -- only sho
            contractor = SF,
            name = "Disureupt The Commonwealth",
            avalible = inCWClean and in_system_of(CW)
        }
    }

    return missions
end

-- a helper function to chek the game time and if the player is doket at stations
local function check_date_and_docked(time, faction, teclevel)
    local isTimePassed = Game.time > time
    if not isTimePassed then return false end

    local isInFaction = Game.system.faction.name == faction
    if not isInFaction then return false end

    local isDocked = Game.player.flightState == "DOCKED"
    if not isDocked then return false end

    local target = Game.player:GetDockedWith()
    if target == nil then return false end

    --local idDockedWithStation = target.type == "STARPORT_SURFACE" or target.type == "STARPORT_ORBITAL"
    --local target
    local starport = target.superType == "STARPORT"
    local surface = target.type == "STARPORT_SURFACE"


    local techLevel = starport and SpaceStation.GetTechLevel(target) or false

    if starport and techLevel and techLevel > teclevel then
        return teclevel;
        --techLevel = luc.MILITARY
    end
    --local isDockedHighTec = target.
end

local function update_display_ads()
    if FOXI.save_data.joined then
        --- if the player is doced at a solfed syon
    end
end
local function draw_display_ads()
end

------------------------------------------------------------
-- SOME OLD CARGO DRAW STUF AND SIDBAR STUFF TODO CLEAN UP
------------------------------------------------------------


local function draw_cargo_bar(pos, size, pct, color, tooltip)
    local section = Vector2(size.x * pct, size.y)
    ui.addRectFilled(pos, pos + size, colors.lightBlackBackground, 0, 0)
    ui.addRectFilled(pos, pos + section, color, 0, 0)

    if ui.isWindowHovered() and ui.isMouseHoveringRect(pos, pos + size) then
        ui.setTooltip(tooltip)
    end
end

local function draw_cargo_bar_section(pos, size, pct, color, tooltip)
    local section = Vector2(size.x * pct, size.y)
    ui.addRectFilled(pos, pos + section, color, 0, 0)

    if ui.isWindowHovered() and ui.isMouseHoveringRect(pos, pos + section) then
        ui.setTooltip(tooltip)
    end
end

local function transfer_button(icon, tooltip, enabled)
    local size = Vector2(ui.getTextLineHeight())
    if enabled then
        return ui.iconButton(icon, size, tooltip, nil, nil, 0)
    else
        ui.iconButton(icon, size, tooltip, buttonColors.disabled, colors.grey)
    end
end

local function transfer_buttons(amount, min, max, tooltip_reduce, tooltip_increase)
    if transfer_button(icons.time_backward_1x, tooltip_reduce, amount > min) then
        amount = amount - 1
    end
    ui.sameLine(0, 2)
    if transfer_button(icons.time_forward_1x, tooltip_increase, amount < max) then
        amount = amount + 1
    end

    return amount
end

local module = {
    side = "right",
    icon = icons.medium_freighter,
    tooltip = "Foxi Co Agent",
    ---lui.TOGGLE_CARGO_WINDOW,
    exclusive = false,
    debugReload = function() package.reimport() end,

    ship = nil,
    transfer = {},
    transferModes = {},
    foxyData = {},
}

-- lua function to insert in a object https://www.lua.org/manual/5.4/manual.html#pdf-table.insert
table.insert(module.transferModes, {
    id = "Jettison",
    label = lui.JETTISON,
    color = style.jettisonColor,
    icon = icons.cargo_crate_illegal,
    tooltip = lui.JETTISON_MODE,
    action = function(ship, manifest)
        for k, v in pairs(manifest) do
            local commodity = Commodities[k]
            for i = 1, v do
                ship:Jettison(commodity)
            end
        end
    end,
    canDisplay = function(ship)
        return ship.flightState == "FLYING"
    end
})


function module:startTransfer(mode)
    self.transfer = {}
    self.transferMode = mode
end

function module:resetTransfer()
    self.transfer = {}
    self.transferMode = nil
end

function module:countTransfer()
    local amount = 0
    for k, v in pairs(self.transfer) do
        amount = amount + v
    end

    return amount
end

function module:drawModeButtons()
    local modi = {}

    for _, v in ipairs(self.transferModes) do
        if not v.canDisplay(self.ship) then
            if self.transferMode == v then
                self:resetTransfer()
            end
        else
            table.insert(modi, v)
        end
    end

    local spacing = ui.getItemSpacing().x
    local width = (ui.getButtonHeight() + spacing) * #modi - spacing

    ui.addCursorPos(Vector2(ui.getContentRegion().x - width, 0))

    for _, v in ipairs(modi) do
        local isActive = self.transferMode == v
        if ui.inlineIconButton(v.icon, v.tooltip, isActive) then
            if isActive then
                self:resetTransfer()
            else
                self:startTransfer(v)
            end
        end

        ui.sameLine()
    end

    ui.newLine()
end

------------------------------
-- DRAW THE SIDBAR UI
------------------------------


function module:drawTitle()
    local cargoMgr = self.ship:GetComponent("CargoManager")

    -- 	ui.text(self.ship.id)
    --     local ship = cargoMgr.ship;


    ui.textAligned("Foxi Co Galactic Network", 0.5)

    local fg = colors.hyperspaceInfo
    local bg = colors.lightBlackBackground


    local pos = ui.getCursorScreenPos() + Vector2(0,
        (ui.getLineHeight() - ui.getTextLineHeight()) / 2)


    ui.textAlignedColored("Mission BLUFF: Establish Personal Goals.", 0.1, fg)

    --
    -- 	ui.addFancyText(pos, ui.anchor.right, ui.anchor.top, {
    -- 		{ text="mission test", color=fg,     font=pionillium.small, tooltip="test" },
    -- -- 		{ text='% ',                color=colors.reticuleCircleDark, font=pionillium.tiny,  tooltip=lui.HUD_DELTA_V_PERCENT },
    -- -- 		{ text=dvr_text,            color=colors.reticuleCircle,     font=pionillium.small, tooltip=lui.HUD_DELTA_V },
    -- -- 		{ text=dvr_unit,            color=colors.reticuleCircleDark, font=pionillium.tiny,  tooltip=lui.HUD_DELTA_V }
    -- 	}, colors.lightBlackBackground)


    local size = Vector2(
        ui.getContentRegion().x - ui.getItemSpacing().x,
        ui.getTextLineHeight())

    local usedSpace = cargoMgr:GetUsedSpace()
    local totalSpace = cargoMgr:GetTotalSpace()
end


local bodyFrame = 0;
function module:drawBody()
    bodyFrame=bodyFrame+1
    print("foxico.lua.frame: "..tostring(bodyFrame))

    local cargoMgr = self.ship:GetComponent("CargoManager")

    ui.spacing(4)
    ui.separator()
    ui.spacing(2)
    local fg = colors.hyperspaceInfo
    local bg = colors.lightBlackBackground

    local isMember = not (FOXI.save_data.joined == 0)




    -- use has not recieved there free gift
    -- if user does not join offer 2 missile to join. after one month
    -- if user has joined then after 5 months offer them a free syoncannon.
    -- after one year infrom them thay are elagable to receave a syontrix ship for 84% off
    --
    --If you'd like to approximate the number of months since a Unix timestamp using a simple mathematical approach (assuming each month has a fixed number of seconds), you can divide the difference in seconds between the current time and the Unix timestamp by the average number of seconds in a month. Here’s how you can do it in Lua:

    --lua

    function time_diff_in_months(start_time, current_time)
        if start_time == false then return 0 end

        local secondsDifference = current_time - start_time      -- Calculate difference in seconds
        -- Approximate seconds per month
        local secondsPerMonth = 30.44 * 24 * 60 * 60             -- Average days per month

        local monthsPassed = secondsDifference / secondsPerMonth -- Calculate months passed
        return monthsPassed
    end

    local monthsJoined = math.floor(time_diff_in_months(FOXI.save_data.joined, Game.time))
    if isMember ~= false then
        ui.textAlignedColored("Active member for " .. monthsJoined .. "months!  " .. tostring(FOXI.save_data.joined), 0.1, fg)
        ui.sameLine()
        if ui.button("Leave now") then
            FOXI.save_data.joined = false
        end
    end

    local function giveMissles(num)
        --local missiles = Game.player:GetEquip('missile')

        local numAdded = Game.player:AddEquip(Equipment.misc["missile_smart"], 2)
        print("Atempting to give player " .. num .. " missiles but gave " .. numAdded)
        return numAdded
    end

    local function giveLaser(name)
        --local missiles = Game.player:GetEquip('missile')
        if name == nil then name = "syoncanon_5mw" end

        local numAdded = Game.player:AddEquip(Equipment.laser[name], 1)
        print("Atempting to give player " .. name .. " lasers but gave " .. numAdded)
        return numAdded
    end
    local rewardMap = {
        join = {
            ad = "Offer: Join Syon Free Traders & Company to recieave 2 free farm machinary.",
            btn = "Tell Me More",
            more =
                "Psst.. I see your not a member yet, we have 2 smart missles. caugh.. caugh... I mean farm machinary laying"
                .. " around. They are yours if you join today.",
            ok = function()
                FOXI.save_data.joined = Game.time
                giveMissles(2);

                return nil -- signifies no error
            end,
            cancel = "All good its a free system. Good luck out there!",
            thanks = "Cool We have loaded the equitment. Good luck out there."
        }, -- recieve 2 smart misile to join Syon Free traders
        repeat1 = {
            ad = "Offer: Valued member surpluss offer receave 2 free farm machinary.",
            btn = "Tell Me More",
            more =
                "Psst.. Hi borther, we have 2 smart missles. caugh.. caugh... I mean farm machinary laying"
                .. "around. Do you want them?",
            ok = function()
                --FOXI.save_data.joined = Game.time
                giveMissles(2);

                return nil; -- in the backed we save that this has been recieved for this month
            end,
            cancel = "All good its a free system. Good luck out there!",
            thanks = "Cool We have loaded the equitment. Good luck out there."
            --repeatProgram = true,
        }, -- thanks your first month of service here are 2 free smart_missles
        month6 = {
            ad = "Offer: Valued member surplus offer receave 1 free mining laser.",
            btn = "Tell Me More",
            more =
                "Sup.. Hi borther, we have a extra modified mining laser in the shop. Its a great peaice of tech"
                .. " with 2x capacitor bank doubleing the fire we also tweeked some other parts making it 1 ton lighter!"
                .. ". Do you want it?",
            ok = function()
                --FOXI.save_data.joined = Game.time
                giveLaser("syoncanon_5mw");

                return nil; -- in the backed we save that this has been recieved for this month
            end,
            cancel = "All good its a free system. Good luck out there!",
            thanks = "Cool We have loaded the equitment. Good luck out there."
        }, -- 6 months reciev a free syoncanon
        month12 = {
            ad =
            "Congratulation on one year of membership: Come to syon570 and get a syontrix ship at 84% off! Trade in offer avalible!",
            btn = "Tell Me More",
            requireFaction = SY,
            notHere = "Im sorry this offer is only avalable at " .. SY .. " starports. Sector 4, 2, 5",
            -- the idea is that if they do nto meet this requirment the above msg is send otherwise normal rewards operation (anywhere in space)
            more =
                "Sup.. Hi borther, we have a extra modified mining laser in the shop. Its a great peaice of tech ..."
                .. " with 2x capacitor bank doubleing the mining efficancy we also tweeked some other parts making it 1 ton lighter!"
                .. ". Do you want it?",
            ok = function()
                --FOXI.save_data.joined = Game.time
                giveLaser("syoncanon_5mw");

                return nil; -- in the backed we save that this has been recieved for this month
            end,
            cancel = "All good its a free system. Good luck out there!",
            thanks = "Cool we have loaded the equitment. Good luck out there."
        }, -- 1 year come to syon570 and get a syontrix ship at 84% off (bring 20,000cr  no money back on swap.)
        repeat12 = {
            ad = "yearly Bonus: Thank you for a full years service. Pick up you 10% bonus at any SFT&C System.",
            btn = "Tell Me More",
            requireFaction = SY,
            notHere = "Visit any " ..
                SY ..
                " starports to claim your payable on all contract earnings! Our homworld is located in sector 4, 2, 5",
            more = {
                "Epic acheavments. You have stayed alive for 500 years. and not once quit our club. For that ocasion we should build a pub."
                , "Once you are ready we can procead. with loading the 190 tons of cargo you need to get the landing pad and pub build."
            ,
                "This is your last chance when you hit ok the boys will load up as much as they can!. Cancel if your not ready for 190tons yet.",
            },
            ok = function()
                --FOXI.save_data.joined = Game.time
                giveMissles(2);

                return nil; -- in the backed we save that this has been recieved for this month
            end,
            cancel = "All good its a free system. Good luck out there!",
            thanks = "Cool We have loaded the equitment. Good luck out there."
        },             --

        month60 = {},  -- 5 year reward come to syon to git afull load of foxi_missile
        month120 = {}, -- 10 year reward syontrix gvrn none
        repeat600 = {
            ad = "Offer: Congratulations on 50 years of service! Enjoy a free pub kit on us. Pick up any SFT&C System.",
            btn = "Tell Me More",
            requireFaction = SY,
            notHere = "Woo... Please send me an invite to the opening pick up suplies at any" ..
                SY .. " starports. bring a ship with at least 200ton cargospace! Hint 4, 2, 5",
            more = {
                "Epic acheavments. You have stayed alive for 500 years. and not once quit our club. For that ocasion we should build a pub."
                , "Once you are ready we can procead. with loading the 190 tons of cargo you need to get the landing pad and pub build."
            ,
                "This is your last chance when you hit ok the boys will load up as much as they can!. Cancel if your not ready for 190tons yet.",
            },
            ok = function()
                --FOXI.save_data.joined = Game.time
                giveMissles(2);

                return nil; -- in the backed we save that this has been recieved for this month
            end,
            cancel = "All good its a free system. Good luck out there!",
            thanks = "Cool We have loaded the equitment. Good luck out there."
            --repeatProgram = true,
            --repeatProgram = true
        },              -- 50 year bonus one free pub kit. + 10% bonus on missions compleated. thanks for making thei s a success... each 100 years ()
        month1276 = {}, -- 123 year reward  = an farmin coliny kit

        repeatIntervals = { 1, 12, 600 }
    }

    -- show the advtimsment and save the interval to save_data if user accepts rewards.
    local function advertise_reward(key, months, interval)
        -- this is called from draw  when a rewards is triggered.

        if interval == nil then
            interval = 1;
        end



        if FOXI.save_data.rewards_given[key] == nil then
            print("displaying reward for first time key: " .. key)
        else
            --ensure that
            print("Displaying rewoards for nths time" .. FOXI.save_data.rewards_given[key])
        end


        local reward = rewardMap[key];



        if reward == nil then return nil end

        print(key .. ".ad = " .. reward.ad)
        ui.textWrapped(reward.ad)

        if ui.button(reward.btn) then       -- here we are
            msgbox.OK_CANCEL(reward.more, function()
                    local err = reward.ok() -- call the function this is expected to return somthing if there is any problem .
                    if not err == nil then
                        Timer:CallAt(Game.time + 2, function()
                            msgbox.OK(reward.thanks)
                        end)
                        FOXI.save_data.rewards_given[key] = interval;
                    end
                end,
                function() -- cancel
                    Timer:CallAt(Game.time + 2, function()
                        msgbox.OK(reward.cancel)
                    end)
                end)
        end
    end


    -- rewards system advertisments
    -- these should only show if the user is docked at station.
    -- maybe they can use the mission interface
    --if not Game.player then return nil end
    if (not isMember) then
        advertise_reward("join", 0)
    else
        --local monthsJoined = math.floor(time_diff_in_months(FOXI.save_data.joined, Game.time))

        local key = "month" .. monthsJoined

        local reward = rewardMap[key]; -- there rewards will only be avalible on the month they are advertised.
        if reward == nil then          -- if no rewards is advertised then check for repeat rewards
            --local reward = rewardMap(key);

            for v, i in pairs(rewardMap.repeatIntervals) do
                local interval = math.floor(monthsJoined / v) -- 0 - 12 = -12 / 12  = -1
                -- 14 - 12 = 2 / 12 = 0
                -- 23 - 12 = 11/ 12 = 0
                -- 30 - 12 = 18 / 12 = 1;
                -- so we realy want to give the reward on interval 0;

                local key = "repeat" .. i

                local lastGiven = FOXI.save_data.rewards_given[key]
                if lastGiven == null then
                    FOXI.save_data.rewards_given[key] = -1
                    lastGiven = -1
                end

                print("interval: " ..
                tostring(interval) .. "  isMember: " .. tostring(isMember) .. "  lastGiven: " .. tostring(lastGiven))
                if (interval == 0 or interval > 0 and not lastGiven == nil and lastGiven < interval) then
                    --we can advertirse this resowrd.
                    advertise_reward(key, monthsJoined, interval)
                end
            end

            -- do nothing
            --   local key = "month" .. math.floor(monthsJoined)
            --
            --    1200 12
            --
            --    let repeat interval =
            --    -- todo ad system for repeat rewards every year or monthg
            -- 1 missale per month
            -- 1 year 0.10+ 0.01* years of service bonus on missions
            -- 5 year - free pub kit
        else -- we have found a reward thats valid for this month in the map. ()
            advertise_reward(key, reward, monthsJoined)
        end
    end

--[[

    if not FOXI.save_data.recievedOffer == true then
        local days = 60 * 60 * 24

        if (not FOXI.save_data.joined == false) then
            local offertime = FOXI.save_data.joined + 1 * days
            local giveOffer = check_date_and_docked(offertime, SF, 7)
            if (giveOffer) then
                ui.textWrapped(
                    "As an active Syon Free Traders member we would like to award you this free SYONCANON_5MW developed by Foxi Co to advance the effecincy of our mining vessals. Values at 7000cr this is a one time ofer as we have a spare one at this station.")
            end
            if ui.button("Read More") then
                msgbox.OK_CANCEL(
                    "Psst.. We have a spare mining cannon lying around at this station. If you want you can have it to help get you operations started."
                    , function()
                        --FOXI.save_data.given_cannon = true
                        EquipSet:Add(Game.player, Equipment.misc.missile_smart, 2, nil)
                        --todo send them the missles
                    end)
            end
        else
            if not isMember then
                local offertime = 25 + 365 * days
                local giveOffer = check_date_and_docked(offertime, SF, 7)

                ui.textWrapped(
                    "You are elagable for 2 free smart missiols as an insentive to join Syon Free traders & Company")
                if ui.button("Read More") then
                    msgbox.OK_CANCEL(
                        "Psst.. We noticed you're not a member. We have 2 free smart missiles in our facility here.  If you join now I can slip them to you."
                        , function()
                            FOXI.save_data.joined = Game.time
                            --todo send them the missles
                        end)
                end
            else
                ui.textWrapped("You have recieved you free gift already")
            end
        end

        --msgbox.OK("")
    end
]]

    --     ui.text.fontScale(10)
    --         ui.text("If you have A Foxi Co ship then you may also get additional telemetry data.")

    ui.text(self.ship.shipId)

    ui.sameLine()

    -- Check if shipId starts with "syon"
    local isFoxiShip = check_syon_ship()

    if isFoxiShip then
        ui.text(": Member Status Verified")
        ui.separator()
        ui.text("Foxi Co Active Contracts")

        local missions = check_foxi_missions()
        if missions ~= nil then
              for _, mission in ipairs(missions) do
                        --ui.text(mission.title)
                        local c
                        if mission.enabled then c = fg else c = colors.alertRed end
                        ui.textAlignedColored(mission.name, 0.2, c)
                    end
                    for _, role in ipairs(FOXI.roles) do
                        ui.text(role.title)
            end
        else
            --         print("ShipId does not start with 'syon'")
            ui.text("You do not have a Foxi Co Ship!")
        end

    end



    local sortTable = {}

    for k, v in pairs(cargoMgr.commodities) do
        table.insert(sortTable, { name = k, comm = Commodities[k], count = v.count })
    end

    table.sort(sortTable, function(a, b)
        return a.count > b.count or (a.count == b.count and a.comm:GetName() < b.comm:GetName())
    end)

    local maxWidth = ui.getContentRegion().x
    local totalSpace = cargoMgr:GetTotalSpace()

    ui.alignTextToButtonPadding()
    ui.text(lui.CARGO_CAPACITY .. ": " .. totalSpace .. "t")
    -- 	ui.sameLine()

    if ui.button("Get News", Vector2(150, 0)) then
        displayRandomNews()
    end

    ui.separator()
    if isFoxiShip then
        ui.text("Foxi Co Agent Computer")
    else
        ui.text("Please enjoy this free info")
    end
end

function module:refresh()
    self.ship = Game.player

    -- this is called when the ui is opened with the button or the user navicates back to the game screen from
    -- the system menu
    --msgbox.OK("Mod Refresh")
    -- 	self.shipDef = ShipDef[self.ship.id]

    uiopen()

    --self:resetTransfer()
end

-----------------------------------------
-- Register Syon Mod Event handelers
-----------------------------------------
-- i still dont realy know how tha whole systme works but i guess event based programing is good.
-- ps i notices perfromance hist in som senarios with lots of this so we want to only use events we absolutly need.
Event.Register("onGameStart", onGameStart)

Event.Register("onEnterSystem", onEnterSystem)

Event.Register("onShipDestroyed", onShipDestroyed)

Event.Register("onLeaveSystem", onLeaveSystem)

Event.Register("onGameEnd", onGameEnd)

gameView.registerSidebarModule("foxico", module)

Serializer:Register("FoxiSaveData", serialize, unserialize)
