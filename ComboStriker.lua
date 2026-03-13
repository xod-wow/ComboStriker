--[[----------------------------------------------------------------------------

    ComboStriker
    Copyright 2022 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--


local MASTERY_COMBO_STRIKES_SPELL_ID = 115636

--  These vals are new (Midnight) buffs that track the last ability used. The
--  cooldown viewers pull this from the buffs but the data is secret in
--  combat so it's only helpful getting the ID initially.
--
--  You can get these from the linkedSpellIDs table in
--      C_CooldownViewer.GetCooldownViewerCooldownInfo(70297)
--  but it only contains things you are specced into.

local ComboStrikeSpellIDs = {
    [100784]    = 1249757,      -- Blackout Kick
    [443028]    = 1249790,      -- Celestial Conduit
    [117952]    = 1249764,      -- Crackling Jade Lightning
    [113656]    = 1249758,      -- Fists of Fury
    [107428]    = 1249753,      -- Rising Sun Kick
    [467307]    = 1250987,      -- Rushing Wind Kick
    [1217413]   = 1249759,      -- Slicing Winds
    [101546]    = 1249754,      -- Spinning Crane Kick
    [137639]    = 1249762,      -- Storm, Earth and Fire
    [392983]    = 1249766,      -- Strike of the Windlord
    [100780]    = 1249756,      -- Tiger Palm
    [322109]    = 1249791,      -- Touch of Death
    [152175]    = 1249765,      -- Whirling Dragon Punch
    [1249625]   = 1249763,      -- Zenith
}

local ComboStrikeAuraIDs = tInvert(ComboStrikeSpellIDs)

local function GetPreviousSpellID()
    for auraSpellID, spellID in pairs(ComboStrikeAuraIDs) do
        -- Doesn't return a secret, just nil in combat
        if C_UnitAuras.GetPlayerAuraBySpellID(auraSpellID) then
            return spellID
        end
    end
end

local previousSpellID

--[[------------------------------------------------------------------------]]--

ComboStriker = CreateFrame('Frame')
ComboStriker:RegisterEvent('PLAYER_LOGIN')
ComboStriker:SetScript('OnEvent',
    function (self, e, ...) if self[e] then self[e](self, ...) end end)

function ComboStriker:PLAYER_LOGIN()
    if select(2, UnitClass('player')) == 'MONK' then
        self.overlayFrames = {}
        for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
            if actionButton:GetName():sub(1,8) ~= 'Override' then
                self:CreateOverlay(actionButton)
            end
        end
        self:RegisterEvent('PLAYER_REGEN_DISABLED')
    end
end

function ComboStriker:UNIT_SPELLCAST_SUCCEEDED(_unit, _castGUID, spellID)
    -- Note RegisterUnitEvent so don't need to check unit, always player
    if ComboStrikeSpellIDs[spellID] then
        previousSpellID = spellID
        self:UpdateAllOverlays()
    end
end

function ComboStriker:SPELLS_CHANGED()
    self:UpdateAllOverlays()
end

function ComboStriker:PLAYER_REGEN_DISABLED()
    if IsPlayerSpell(MASTERY_COMBO_STRIKES_SPELL_ID) then
        self:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
        self:RegisterEvent('SPELLS_CHANGED')
        previousSpellID = GetPreviousSpellID()
        self:UpdateAllOverlays()
    end
end

function ComboStriker:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
    self:UnregisterEvent('PLAYER_REGEN_ENABLED')
    self:UnregisterEvent('SPELLS_CHANGED')
    previousSpellID = nil
    self:UpdateAllOverlays()
end

function ComboStriker:CreateOverlay(actionButton)
    if not self.overlayFrames[actionButton] then
        local name = actionButton:GetName() .. "ComboStrikerOverlay"
        local overlay = CreateFrame('Frame', name, actionButton, "ComboStrikerOverlayTemplate")
        self.overlayFrames[actionButton] = overlay
    end
    return self.overlayFrames[actionButton]
end

function ComboStriker:UpdateAllOverlays()
    for _, overlay in pairs(self.overlayFrames) do
        overlay:Update()
    end
end


ComboStrikerOverlayMixin = {}

function ComboStrikerOverlayMixin:OnLoad()
    -- Bump it so it's on top of the cooldown frame
    local parent = self:GetParent()
    self:SetFrameLevel(parent.cooldown:GetFrameLevel() + 1)
    self:SetSize(parent.icon:GetSize())
    local mask = parent.icon:GetMaskTexture(1)
    self.Texture:AddMaskTexture(mask)
end

function ComboStrikerOverlayMixin:GetActionSpellID()
    local actionButton = self:GetParent()

    local type, id, subType = GetActionInfo(actionButton.action)

    if type == 'spell' then
        return id
    end

    if type == 'macro' and subType == 'spell' then
        return id
    end
end

function ComboStrikerOverlayMixin:Update()
    local id = self:GetActionSpellID()
    self:GetParent().icon:SetDesaturated(id and id == previousSpellID)
    self:SetShown(id and id == previousSpellID)
end
