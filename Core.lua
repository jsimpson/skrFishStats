local _addon, _ns = ...

local poles = {
    [ 6256] = true, -- Fishing Pole
    [ 6365] = true, -- Strong Fishing Pole
    [ 6366] = true, -- Darkwood Fishing Pole
    [ 6367] = true, -- Big Iron Fishing Pole
    [12225] = true, -- Blump Family Fishing Pole
    [19022] = true, -- Nat Pagle's Extreme Angler FC-5000
    [19970] = true, -- Arcanite Fishing Pole
    [25978] = true, -- Seth's Graphite Fishing Pole
    [44050] = true, -- Mastercraft Kalu'ak Fishing Pole
    [45858] = true, -- Nat's Lucky Fishing Pole
    [45991] = true, -- Bone Fishing Pole
    [45992] = true, -- Jeweled Fishing Pole
    [46337] = true, -- Staats' Fishing Pole
    [52678] = true, -- Jonathan's Fishing Pole
}

local coinsCopper = {
    "A Footman's Copper Coin",
    "Alonsus Faol's Copper Coin",
    "Ansirem's Copper Coin",
    "Attumen's Copper Coin",
    "Danath's Copper Coin",
    "Dornaa's Shiny Copper Coin",
    "Eitrigg's Copper Coin",
    "Elling Trias' Copper Coin",
    "Falstad Wildhammer's Copper Coin",
    "Genn's Copper Coin",
    "Inigo's Copper Coin",
    "Krasus' Copper Coin",
    "Kryll's Copper Coin",
    "Landro Longshot's Copper Coin",
    "Molok's Copper Coin",
    "Murky's Copper Coin",
    "Princess Calia Menethil's Copper Coin",
    "Private Marcus Jonathan's Copper Coin",
    "Salandria's Shiny Copper Coin",
    "Squire Rowe's Copper Coin",
    "Stalvan's Copper Coin",
    "Vareesa's Copper Coin",
    "Vargoth's Copper Coin",
}

local coinsSilver = {
}

local coinsGold = {
}

local backdrop = {
	bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
}

local backdropColor = { 0, 0, 0, 0.8 }

-- Frames
local a = CreateFrame("Button", nil, UIParent)
a:Hide()

local Stats = {}
a.Stats = Stats

-- Functions
local fishSortCount = function(a, b)
	return a.count > b.count
end

local function getZone()
    local zone = GetRealZoneText()
    local subzone = GetSubZoneText()

    if not zone then zone = "Unknown" end
    if not subzone then subzone = zone end

    return zone, subzone
end

local function getSkill()
    local _, _, _, fishing = GetProfessions()
    local _, _, rank, _, _, _, _, modifier = GetProfessionInfo(fishing)

    return rank, (modifier or 0), rank + (modifier or 0)
end

-- Display
local display

function Stats.Show(frame)
    if not display then display = Stats:Create() end

    display:ClearAllPoints()
    display:SetPoint("CENTER", UIParent, a.db.x and "BOTTOMLEFT" or "BOTTOM", a.db.x or 0, a.db.y or 221)

    display:Show()
    display:Update()
end

function Stats.Hide(frame)
    display:Hide()
end

function displayUpdate(self)
    local total, height, copper, silver, gold = 0, 0, 0, 0, 0
    local zone, subzone = getZone()
    local rank, modifier, skill = getSkill()
    local liveDisplay = {}
    local result

    if not a.db.stats[zone][subzone] then
        display:Hide()
        return
    end

    self.caption:SetText(format("|cff44ccff%s|r: |cff44ccff%s|r", zone, subzone))
    height = height + 20

    for name, count in pairs(a.db.stats[zone][subzone]) do
        total = total + count
        table.insert(liveDisplay, { name = name, count = count })
    end

    self.overview:SetText(format("Total: |cffffff00%s|r | Skill: |cffffff00%s|r + |cff00ff00%s|r (|cff00ff00%s|r)", total, rank, modifier, skill))
    height = height + 20

    if next(liveDisplay) then
        table.sort(liveDisplay, fishSortCount)

        for _, fish in pairs(liveDisplay) do
            height = height + 16
            result = (result or "")..format("%s (|cffffff00%d|r, |cff00ff00%.1f|r%%)\r\n", fish.name, fish.count, fish.count / total * 100)
        end
    end

    display.text:SetText(result)
    display:SetHeight(height)
end

function Stats:Create()
    local width = 350

    local display = CreateFrame("Frame", nil, UIParent)
    display:SetFrameLevel(UIParent:GetFrameLevel() + 2)
    display:Hide()
    display:SetWidth(width)
    display:SetBackdrop(backdrop)
    display:SetBackdropColor(unpack(backdropColor))
    display:SetScript("OnDragStart", display.StartMoving)
    display:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        a.db.x, a.db.y = self:GetCenter()
    end)
    display:SetMovable(true)
    display:EnableMouse(true)
    display:RegisterForDrag("LeftButton")

    local caption = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    caption:SetPoint("TOPLEFT", 10, -10)

    local overview = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    overview:SetPoint("TOPLEFT", 10, -30)

    local text = display:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("BOTTOMLEFT", 10, 0)
    text:SetJustifyH("LEFT")

    display.caption = caption
    display.overview = overview
    display.text = text
    display.Update = displayUpdate

    return display
end

function Stats:Toggle()
    if not display then
        Stats:Show(Stats)
        return
    else
        if display:IsVisible() then
            display:Hide()
        else
            display:Show()
            display:Update()
        end
    end
end

-- Logging
local function logCatch(name, quantity)
    local zone, subzone = getZone()

    if not a.db.stats[zone] then
        a.db.stats[zone] = {}
    end

    if not a.db.stats[zone][subzone] then
        a.db.stats[zone][subzone] = {}
    end

    if not a.db.stats[zone][subzone][name] then
        a.db.stats[zone][subzone][name] = {}
        a.db.stats[zone][subzone][name] = 0
    end

    local total = a.db.stats[zone][subzone][name]
    total = total + quantity
    a.db.stats[zone][subzone][name] = total

    if a.db.liveDisplay then
        if not display then Stats:Show(Stats) end

        if display:IsVisible() then
            display:Update()
        else
            display:Show()
        end
    end
end

-- Check Enable/Disable
function a:checkLogging()
    if not InCombatLockdown() then
        local mainHandId = tonumber(GetInventoryItemID("player", INVSLOT_MAINHAND) or nil)
        if mainHandId and poles[mainHandId] then
            a.db.logging = true

            if a.db.liveDisplay then
                if not display then Stats:Show(Stats) end

                if display:IsVisible() then
                    display:Update()
                else
                    display:Show()
                    display:Update()
                end
            end

            return
        end
    end

    if a.db.liveDisplay and display then
        if display:IsVisible() then
            display:Hide()
        end
    end

    a.db.logging = false
end

-- Event Handlers
a:SetScript('OnEvent', function(self, event, ...)
    if type(self[event]) == "function" then
        return self[event](self, event, ...)
    end
end)

function a:LOOT_OPENED(event, autoloot)
    if IsFishingLoot() then
        if not a.db.logging then return end

        for i = 1, GetNumLootItems(), 1 do
            if (LootSlotIsItem(i)) then
                local _, name, quantity, quality = GetLootSlotInfo(i)
                logCatch(name, quantity)
            end
        end
    end
end

function a:UNIT_INVENTORY_CHANGED(_, unit)
    if unit == 'player' then self:checkLogging() end
end

function a:ADDON_LOADED(_, addon)
    if addon:lower() ~= "skrfishstats" then return end
    self:UnregisterEvent('ADDON_LOADED')

    if not skrFishStatsDB then skrFishStatsDB = {} end
    a.db = skrFishStatsDB

    if not a.db.logging then a.db.logging = false end
    if not a.db.liveDisplay then a.db.liveDisplay = true end
    if not a.db.stats then a.db.stats = {} end
    if not a.db.x then a.db.x = {} end
    if not a.db.y then a.db.y = {} end

    self:checkLogging()
end

a.PLAYER_LOGOUT = a.checkLogging
a.PLAYER_REGEN_DISABLED = a.checkLogging
a.PLAYER_REGEN_ENABLED = a.checkLogging
a.ZONE_CHANGED = a.checkLogging

-- Slash Commands
SlashCmdList["SKRFISHSTATS"] = function() Stats:Toggle() end
SLASH_SKRFISHSTATS1 = "/skrfishdata"
SLASH_SKRFISHSTATS2 = "/skrfish"
SLASH_SKRFISHSTATS3 = "/skrfs"

-- Register 
a:RegisterEvent('PLAYER_LOGOUT')
a:RegisterEvent('PLAYER_REGEN_DISABLED')
a:RegisterEvent('PLAYER_REGEN_ENABLED')
a:RegisterEvent('LOOT_OPENED')
a:RegisterEvent('UNIT_INVENTORY_CHANGED')
a:RegisterEvent('ZONE_CHANGED')
a:RegisterEvent('ADDON_LOADED')
