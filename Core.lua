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
    "A Peasant's Silver Coin",
    "Aegwynn's Silver Coin",
    "Alleria's Silver Coin",
    "Antonidas' Silver Coin",
    "Arcanist Doan's Silver Coin",
    "Fandral Staghelm's Silver Coin",
    "High Tinker Mekkatorque's Silver Coin",
    "Khadgar's Silver Coin",
    "King Anasterian Sunstrider's Silver Coin",
    "King Terenas Menethil's Silver Coin",
    "King Varian Wrynn's Silver Coin",
    "Maiev Shadowsong's Silver Coin",
    "Medivh's Silver Coin",
    "Muradin Bronzebeard's Silver Coin",
    "Prince Magni Bronzebeard's Silver Coin",
}

local coinsGold = {
    "Anduin Wrynn's Gold Coin",
    "Archimonde's Gold Coin",
    "Arthas' Gold Coin",
    "Arugal's Gold Coin",
    "Brann Bronzebeard's Gold Coin",
    "Chromie's Gold Coin",
    "Kel'Thuzad's Gold Coin",
    "Lady Jaina Proudmoore's Gold Coin",
    "Lady Katrana Prestor's Gold Coin",
    "Prince Kael'thas Sunstrider's Gold Coin",
    "Sylvanas Windrunner's Gold Coin",
    "Teron's Gold Coin",
    "Thrall's Gold Coin",
    "Tirion Fordring's Gold Coin",
    "Uther Lightbringer's Gold Coin",
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

local function countCoins(t)
    local copper, silver, gold = 0, 0, 0

    for _, exception in pairs(coinsCopper) do
        for i, fish in pairs(t) do
            if fish.name == exception then
                copper = copper + fish.count
                table.remove(t, i)
            end
        end
    end
    for _, exception in pairs(coinsSilver) do
        for i, fish in pairs(t) do
            if fish.name == exception then
                silver = silver + fish.count
                table.remove(t, i)
            end
        end
    end
    for _, exception in pairs(coinsGold) do
        for i, fish in pairs(t) do
            if fish.name == exception then
                gold = gold + fish.count
                table.remove(t, i)
            end
        end
    end

    if copper > 0 then
        table.insert(t, { name = "|cffeda55fCopper Coins|r", count = copper })
    end
    if silver > 0 then
        table.insert(t, { name = "|cffc7c7cfSilver Coins|r", count = silver })
    end
    if gold > 0 then
        table.insert(t, { name = "|cffffd700Gold Coins|r", count = gold })
    end

    return t
end

-- Display
local display

local function displayUpdate(self)
    local total, height = 0, 0
    local zone, subzone = getZone()
    local rank, modifier, skill = getSkill()
    local t = {}
    local result = nil

    if not a.db.stats[zone][subzone] then
        display:Hide()
        return
    end

    self.caption:SetText(format("|cff44ccff%s|r: |cff44ccff%s|r", zone, subzone))

    for name, count in pairs(a.db.stats[zone][subzone]) do
        total = total + count
        table.insert(t, { name = name, count = count })
    end

    if subzone == "The Eventide" then
        t = countCoins(t)
    end

    self.overview:SetText(format("Total: |cffffff00%s|r | Skill: |cffffff00%s|r + |cff00ff00%s|r (|cff00ff00%s|r)", total, rank, modifier, skill))

    if next(t) then
        table.sort(t, fishSortCount)

        for _, fish in pairs(t) do
            local percent = fish.count / total * 100
            result = (result or "")..format("%s (|cffffff00%d|r, |cff00ff00%.1f|r%%)\n", fish.name, fish.count, percent)
        end
    end

    height = (table.getn(t) * 12) + 56
    display.text:SetText(result)
    display:SetHeight(height)
end

function Stats.Show()
    if not display then display = Stats:Create() end

    display:ClearAllPoints()
    display:SetPoint("CENTER", UIParent, a.db.x and "BOTTOMLEFT" or "BOTTOM", a.db.x or 0, a.db.y or 221)

    display:Show()
    display:Update()
end

function Stats.Hide()
    display:Hide()
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

    local caption = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge") -- size: 16
    caption:SetPoint("TOPLEFT", 8, -8)
    caption:SetJustifyH("LEFT")

    local overview = display:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    overview:SetPoint("TOPLEFT", 8, -24)
    caption:SetJustifyH("LEFT")

    local text = display:CreateFontString(nil, "OVERLAY", "GameFontHighlight") -- size: 12
    text:SetPoint("BOTTOMLEFT", 8, 0)
    text:SetJustifyH("LEFT")

    display.caption = caption
    display.overview = overview
    display.text = text
    display.Update = displayUpdate

    return display
end

function Stats:Toggle()
    if not display then
        Stats:Show()
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

    if not display then
        Stats:Show()
        return
    end

    if not display:IsVisible() then
        display:Show()
    end
    display:Update()
end

-- Check Enable/Disable
function a:checkLogging()
    if not InCombatLockdown() then
        local mainHandId = tonumber(GetInventoryItemID("player", INVSLOT_MAINHAND) or nil)
        if mainHandId and poles[mainHandId] then
            a.db.logging = true
            if not display then
                Stats:Show()
            elseif not display:IsVisible() then
                display:Show()
                display:Update()
            end
        else
            if display and display:IsVisible() then
                display:Hide()
            end
            a.db.logging = false
        end
    end
end

-- Event Handlers
a:SetScript('OnEvent', function(self, event, ...)
    if type(self[event]) == "function" then
        return self[event](self, event, ...)
    end
end)

function a:LOOT_OPENED(event, autoloot)
    if not a.db.logging then return end

    if IsFishingLoot() then
        for i = 1, GetNumLootItems(), 1 do
            if LootSlotIsItem(i) then
                local _, name, quantity, quality = GetLootSlotInfo(i)
                logCatch(name, quantity)
            end
        end
    end
end

function a:ZONE_CHANGED()
    local zone, subzone = getZone()

    if not a.db.stats[zone][subzone] then
        if display and display:IsVisible() then
            display:Hide()
            return
        end
    else
        if display then
            if display:IsVisible() then
                display:Update()
            else
                display:Show()
                display:Update()
            end
        else
            Stats:Show()
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
    if not a.db.stats then a.db.stats = {} end
    if not a.db.x then a.db.x = {} end
    if not a.db.y then a.db.y = {} end

    self:checkLogging()
end

a.PLAYER_LOGOUT = a.checkLogging
a.PLAYER_REGEN_DISABLED = a.checkLogging
a.PLAYER_REGEN_ENABLED = a.checkLogging

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
