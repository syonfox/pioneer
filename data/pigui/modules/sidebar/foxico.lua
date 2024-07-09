-- Copyright © 2008-2024 Pioneer Developers. See AUTHORS.txt for details
-- Licensed under the terms of the GPL v3. See licenses/GPL-3.txt

local Commodities = require 'Commodities'
local Game = require 'Game'
local utils = require 'utils'
local Vector2 = _G.Vector2
local ShipDef = require 'ShipDef'

local Lang = require 'Lang'
local lui = Lang.GetResource("ui-core");

local ui = require 'pigui'
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

local gameView = require 'pigui.views.game'



-- Define the FOXI object
local FOXI = {
    roles = {
        {
            title = "Negotiating Open Contracts",
            shortDescription = "FOXI acts as the galaxy's smoothest negotiator, securing win-win deals between free traders and factions.",
            longTooltip = "FOXI's negotiation prowess isn't just about sealing the deal—it's about optimizing resource exchanges and profit margins, ensuring both sides benefit from the agreements. Its advanced algorithms analyze market trends and factional needs to craft contracts that promote economic growth and stability across the galaxy."
        },
        {
            title = "Establishing Resource Exports to Sol Fed",
            shortDescription = "FOXI transforms rival resources into Sol Fed's economic fuel, navigating complex supply chains with precision.",
            longTooltip = "By identifying lucrative export opportunities from rival factions, FOXI strategically channels valuable resources to Sol Fed. Its meticulous planning and coordination with free traders ensure a steady flow of goods, bolstering Sol Fed's economic prosperity and influence in the galaxy."
        },
        {
            title = "Establishing Resource Exports to Commonwealth",
            shortDescription = "FOXI brokers resource trades that bridge factional divides, enriching both sides in a galaxy of shifting alliances.",
            longTooltip = "Facilitating resource exports to Commonwealths, FOXI fosters cooperation and stability among factions. Its strategic agreements not only optimize resource utilization but also nurture inter-factional relationships, fostering a collaborative environment that benefits all parties involved."
        },
        {
            title = "Disrupting Competitors of Commonwealth",
            shortDescription = "FOXI outsmarts rivals with cunning tactics, weakening threats to Commonwealth interests across the stars.",
            longTooltip = "FOXI's intelligence operations are at the forefront of disrupting competitors of Commonwealths. Through careful analysis and covert actions, it exposes vulnerabilities in rival factions' strategies, employing measures from economic sanctions to strategic alliances with counteracting factions, all aimed at safeguarding Commonwealths' economic and political standing."
        },
        {
            title = "Disrupting Competitors of Sol Fed",
            shortDescription = "FOXI defends Sol Fed's economic dominance with calculated precision, thwarting rivals in the cosmic game of power.",
            longTooltip = "Safeguarding Sol Fed's economic supremacy, FOXI employs a range of disruptive strategies. From intercepting critical supply routes to destabilizing rival markets, FOXI's actions are designed to maintain and strengthen Sol Fed's position as a leading economic force in the galaxy. Its meticulous analysis and swift responses ensure that threats to Sol Fed's interests are effectively neutralized."
        },
        {
            title = "Establishing a Syon Free Traders Pub",
            shortDescription = "FOXI pioneers the establishment of a Syon Free Traders pub in an uncharted or disrupted system, fostering a hub for commerce and camaraderie.",
            longTooltip = "In an effort to expand the network of Syon Free Traders, FOXI undertakes the bold initiative of establishing a pub in a remote, uninhabited, or recently disrupted system. The pub serves not only as a gathering place for traders but also as a nexus for exchanging information, negotiating deals, and fostering community among independent operators. FOXI oversees the logistical challenges of infrastructure development, security arrangements, and cultural integration, ensuring that the pub becomes a beacon of opportunity and solidarity in the vast expanse of the galaxy."
        }

    }
}

-- -- Example method to display FOXI's roles
-- function FOXI.displayRoles()
--     print("FOXI's Roles and Actions:")
--     for _, role in ipairs(FOXI.roles) do
--         print(role.title)
--         print("   - " .. role.shortDescription)
--         print("   - " .. role.longTooltip)
--         print()  -- Print an empty line for readability
--     end
-- end
--
-- -- Example usage
-- FOXI.displayRoles()




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

-- 	local tooltip = AMT_OF_AMT:format(usedSpace, totalSpace)
-- 	draw_cargo_bar(pos, size, usedSpace / totalSpace, style.cargoColor, tooltip)

-- 	if self.transferMode then
-- 		local amount = self:countTransfer()
--
-- 		tooltip = AMT_OF_AMT:format(amount, usedSpace)
-- 		draw_cargo_bar_section(pos, size, amount / totalSpace, self.transferMode.color, tooltip)
-- 	end
end

function module:drawCargoRow(v, rowWidth, totalSpace)
	local commodity = Commodities[v.name]
	local transferAmt = self.transfer[v.name] or 0


	ui.tableNextRow()

	-- Draw name
	ui.tableNextColumn()
	ui.text(commodity:GetName())

	-- Draw contained amount or transferred amount
	ui.tableNextColumn()
	if self.transferMode then
		local fontCol = transferAmt > 0 and self.transferMode.color or colors.font

		ui.withStyleColors({ Text = fontCol }, function()
			ui.text(transferAmt .. "t")
		end)
	else
		ui.text(v.count .. "t")
	end

	-- Draw cargo gauge
	ui.tableNextColumn()

	local width = math.max(ui.getContentRegion().x, rowWidth / 4)
	local pos = ui.getCursorScreenPos()
	local size = Vector2(width, ui.getTextLineHeight())

	ui.dummy(size)

	local tooltip = AMT_OF_AMT:format(v.count, totalSpace)
	draw_cargo_bar(pos, size, v.count / totalSpace, style.cargoColor, tooltip)

	-- Draw transfer gauge
	if self.transferMode and transferAmt > 0 then
		tooltip = AMT_OF_AMT:format(transferAmt, v.count)
		draw_cargo_bar_section(pos, size, transferAmt / totalSpace, self.transferMode.color, tooltip)
	end

	-- Draw transfer buttons
	ui.tableNextColumn()
	if self.transferMode then
		ui.withID(commodity.name, function()
			local max = self.transferMode and v.count or 0
			self.transfer[v.name] = transfer_buttons(transferAmt, 0, max, lui.DECREASE, lui.INCREASE)
		end)
	end
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
        local isFoxiShip = string.sub(self.ship.shipId, 1, 4) == "syon"
        if isFoxiShip then
    --         print("ShipId starts with 'syon'")
            ui.text(": Member Status Verified")
            ui.separator()

            ui.text("Foxi Co Active Contracts")

            for _, role in ipairs(FOXI.roles) do
                ui.text(role.title)
               --                 print("   - " .. role.shortDescription)
--                 print("   - " .. role.longTooltip)
--                 print()  -- Print an empty line for readability
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

-- 	self:drawModeButtons()

	ui.separator()
	if isFoxiShip then
        ui.text("Foxi Co Agent Computer")
    else
        ui.text("Please enjoy this free info")
    end
--     ui.text(self.shipDef.name)


-- 	if cargoMgr:GetUsedSpace() > 0 then
-- 		if ui.beginTable("cargo", 4) then
-- 			ui.tableSetupColumn("Cargo")
-- 			ui.tableSetupColumn("Amount")
-- 			ui.tableSetupColumn("Gauge", { "WidthStretch" })
-- 			ui.tableSetupColumn("Buttons")
--
-- 			for _, v in ipairs(sortTable) do
-- 				self:drawCargoRow(v, maxWidth, totalSpace)
-- 			end
--
-- 			ui.endTable()
-- 		end
--
-- 	else
-- 		ui.alignTextToButtonPadding()
-- 		ui.textAligned(lui.NO_CARGO, 0.5)
-- 	end

-- 	ui.separator()
-- 	ui.spacing()

-- 	ui.alignTextToButtonPadding()
-- 	ui.text("{} {}t {} / {}t {}" % {
-- 		lui.TOTAL,
-- 		cargoMgr:GetUsedSpace(), lui.USED,
-- 		cargoMgr:GetFreeSpace(), lui.FREE
-- 	})
--
-- 	if self.transferMode then
-- 		ui.sameLine()
-- 		local amount = self:countTransfer()
--
-- 		local buttonText = string.format("%s %st", self.transferMode.label, amount)
-- 		ui.addCursorPos(Vector2(ui.getContentRegion().x - ui.calcButtonSize(buttonText).x, 0))
--
-- 		if ui.button(buttonText) then
-- 			self.transferMode.action(self.ship, self.transfer)
-- 			self:resetTransfer()
-- 		end
-- 	end
end


function module:refresh()
	self.ship = Game.player

-- 	self.shipDef = ShipDef[self.ship.id]

	self:resetTransfer()
end

-- gameView.

gameView.registerSidebarModule("foxico", module)
