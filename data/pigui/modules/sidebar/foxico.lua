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
        FOXI.save_data.joined = true

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
        FOXI.save_data.joined = false
        Timer:CallAt(Game.time + 1, okFineThen)
    end
    FOXI.save_data.joined = false;
    if FOXI.save_data.init == false then
        msgbox.OK_CANCEL("Welcome to pioneer. Would you like to join the Syon Free Traders & Co?",
            joinCallback, cancelCallback)
    end
    --if FOXI.save_data.init == false then
    --    msgbox.OK("No worries we are all free peoples. If you wish to join later find us at Syon 570.")
    --end





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
    if ship.IsPlayer() or not attacker.IsPlayer() then return end -- dont count players or other battles

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
    local isMember = FOXI.save_data.joined;
    if isMember then
        ui.textAlignedColored("Woo You are n active member", 0.1, fg)
    end
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

function module:drawBody()
    local cargoMgr = self.ship:GetComponent("CargoManager")

    ui.spacing(4)
    ui.separator()
    ui.spacing(2)

    ui.text("From here you can receive galactic updates.")
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
        for _, mission in ipairs(missions) do
            ui.text(mission.title)
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
