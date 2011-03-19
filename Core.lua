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
}

-- Frames
local frame = CreateFrame("Button", nil, UIParent)

local display = frame:CreateFontString(nil, "OVERLAY")
display:SetPoint("TOPLEFT", frame)

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
    local _, _, _, fishing, = GetProfessions()
    local _, _, rank, _, _, _, _, modifier = GetProfessionInfo(fishing)

    return rank, (modifier or 0), rank + (modifier or 0)
end

-- Check Enable/Disable
function frame:checkLogging()
    if not InCombatLockdown() then
        local mainHandId = tonumber(GetInventoryItemID("player", INVSLOT_MAINHAND) or nil)

        if mainHandId and poles[mainHandId] then
            skr.db.logging = true
            return
        end
    end
    skr.db.logging = false
end

local display 
local liveDisplay = {}

-- Display
function Stats.Show()
    if not display then display = Stats:Create() end

    display:ClearAllPoints()
    display:SetPoint("CENTER", UIParent, skr.db.x and "BOTTOMLEFT" or "BOTTOM", skr.db.x or 0, skr.db.y or 221)

    display:Show()
    display:Update()
end

function Stats.Hide()
    display:Hide()
end

function displayUpdate(self)
    local total = 0
    local zone, subzone = getZone()
    local rank, modifier, skillTotal = getSkill()

    GameTooltip:ClearLines()
    GameTooltip:AddLine(format("%s: %s"), zone, subzone)
    GameTooltip:AddLine(format("Total: %s | Skill: %s + %s (%s)", total, skillBase, skillMod, skillTotal))

    if not skr.db.stats[zone][subzone] then
        GameTooltip:AddLine(format("No stats for %s: %s", zone, subzone))
        return
    end

    for name, count in pairs(skr.db.stats[zone][subzone]) do
        total = total + count
        table.insert(liveDisplay, { name = name, count = count })
    end

    if next(liveDisplay) then
        if GameTooltip:NumLines() > 0 then
            GameTooltip:AddLine(" ")
        end

        table.sort(liveDisplay, fishSortCount)

        for name, count in pairs(liveDisplay) do
            GameTooltip:AddLine(format("%s (%s : %s%%)", liveDisplay.name, liveDisplay.count, liveDisplay.count / )
        end
    end
end

function Stats:Create()
    GameTooltip:SetOwner(frame, "ANCHOR_BOTTOMLEFT")
    GameTooltip:Show()
    display:Update()
end

function Stats:Toggle()
    if not display then Stats:Show(stats) end

    if display:IsVisible() then
        display:Hide()
    else
        display:Show()
    end
end

-- Logging
local function logCatch(name, quantity)
    local zone, subzone = getZone()

    if not skr.db.stats[zone] then
        skr.db.stats[zone] = {}
    end

    if not skr.db.stats[zone][subzone] then
        skr.db.stats[zone][subzone] = {}
    end

    if not skr.db.stats[zone][subzone][name] then
        skr.db.stats[zone][subzone][name] = {}
        skr.db.stats[zone][subzone][name] = 0
    end

    local total = skr.db.stats[zone][subzone][name]
    total = total + quantity
    skr.db.stats[zone][subzone][name] = total

    if skr.db.liveDisplay then
        if not display then Stats:Show(stats) end

        if display:IsVisible() then
            display:Update()
        else
            display:Show()
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
    if IsFishingLoot() then
        if not skr.db.logging then return end

        for i = 1, GetNumLootItems(), 1 do
            if (LootSlotIsItem(i)) then
                local _, name, quantity, quality = GetLootSlotInfo(i)
                if quality == 0 then name = "Junk" end
                logCatch(name, quantity)
            end
        end
    end
end

function a:UNIT_INVENTORY_CHANGED(_, unit)
    if unit == 'player' then self:checkLogging() end
end

function a:ADDON_LOADED(_, addon)
    if addon:lower() ~= "sfishingstats" then return end
    self:UnregisterEvent('ADDON_LOADED')

    if not sFishingStatsDB then sFishingStatsDB = {} end
    skr.db = sFishingStatsDB

    if not skr.db.logging then skr.db.logging = false end
    if not skr.db.liveDisplay then skr.db.liveDisplay = true end
    if not skr.db.stats then skr.db.stats = {} end
    if not skr.db.x then skr.db.x = {} end
    if not skr.db.y then skr.db.y = {} end

    for zone in pairs(skr.db.stats) do
        print(zone)
        for subzone in pairs(skr.db.stats[zone]) do
            print(subzone)
            table.sort(skr.db.stats[zone][subzone], function(a, b) print(a.." "..b); return a > b end)
        end
    end
    self:checkLogging()
end

a.PLAYER_LOGOUT = a.checkLogging
a.PLAYER_REGEN_DISABLED = a.checkLogging
a.PLAYER_REGEN_ENABLED = a.checkLogging

-- Slash Commands
SlashCmdList["SFISHINGSTATS"] = function() Stats:Toggle() end
SLASH_SFISHINGSTATS1 = "/sfishingstats"
SLASH_SFISHINGSTATS2 = "/sfs"

SlashCmdList["SFISHINGSTATS_SORT"] = function() sortStats() end
SLASH_SFISHINGSTATS_SORT1 = "/sfsort"

-- Register 
a:RegisterEvent('PLAYER_LOGOUT')
a:RegisterEvent('PLAYER_REGEN_DISABLED')
a:RegisterEvent('PLAYER_REGEN_ENABLED')
a:RegisterEvent('LOOT_OPENED')
a:RegisterEvent('UNIT_INVENTORY_CHANGED')
a:RegisterEvent('ADDON_LOADED')
