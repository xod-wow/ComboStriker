--[[----------------------------------------------------------------------------

    ComboStriker
    Copyright 2022 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--

local MASTERY_COMBO_STRIKES_SPELL_ID = 115636

local ComboStrikeSpellIDs = {
    [100784] = true,            -- Blackout Kick
    [386276] = true,            -- Bonedust Brew
    [123986] = true,            -- Chi Burst
    [115098] = true,            -- Chi Wave
    [117952] = true,            -- Crackling Jade Lightning
    [322101] = true,            -- Expel Harm
    [388193] = true,            -- Faeline Stomp
    [113656] = true,            -- Fists of Fury
    [101545] = true,            -- Flying Serpent Kick
    [107428] = true,            -- Rising Sun Kick
    [116847] = true,            -- Rushing Jade Wind
    [101546] = true,            -- Spinning Crane Kick
    [392983] = true,            -- Strike of the Windlord
    [100780] = true,            -- Tiger Palm
    [322109] = true,            -- Touch of Death
    [387184] = true,            -- Weapons of Order
    [152175] = true,            -- Whirling Dragon Punch
}
    
local previousSpellID

--[[------------------------------------------------------------------------]]--

ComboStriker = CreateFrame('Frame')
ComboStriker:RegisterEvent('PLAYER_LOGIN')
ComboStriker:SetScript('OnEvent',
    function (self, e, ...) if self[e] then self[e](self, ...) end end)

function ComboStriker:EnableDisable()
    if IsSpellKnown(MASTERY_COMBO_STRIKES_SPELL_ID) then
        print('ComboStriker Enabled')
        self:RegisterUnitEvent('UNIT_SPELLCAST_SUCCEEDED', 'player')
        self:RegisterEvent('PLAYER_REGEN_ENABLED')
        self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
    else
        print('ComboStriker Disabled')
        self:UnregisterEvent('UNIT_SPELLCAST_SUCCEEDED')
        self:UnregisterEvent('PLAYER_REGEN_ENABLED')
        self:UnregisterEvent('ACTIONBAR_SLOT_CHANGED')
    end
    self.previousSpellID = nil
    self:UpdateAllOverlays()
end

function ComboStriker:TRAIT_CONFIG_UPDATED()
    self:EnableDisable()
end

function ComboStriker:PLAYER_SPECIALIZATION_CHANGED(unit)
    if unit == 'player' then
        self:EnableDisable()
    end
end

function ComboStriker:PLAYER_LOGIN()
    if select(2, UnitClass('player')) == 'MONK' then
        self.overlayFrames = {}
        for _, actionButton in pairs(ActionBarButtonEventsFrame.frames) do
            if actionButton:GetName():sub(1,8) ~= 'Override' then
                self:CreateOverlay(actionButton)
            end
        end
        self:RegisterEvent('TRAIT_CONFIG_UPDATED')
        self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
        self:EnableDisable()
    end
end

function ComboStriker:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
    -- Note RegisterUnitEvent so don't need to check unit, always player
    if ComboStrikeSpellIDs[spellID] and InCombatLockdown() then
        previousSpellID = spellID
        self:UpdateAllOverlays()
    end
end

function ComboStriker:ACTIONBAR_SLOT_CHANGED()
    self:UpdateAllOverlays()
end

function ComboStriker:PLAYER_REGEN_ENABLED()
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

    if type == 'item' then
        local _, spellID = GetItemSpell(id)
        return spellID
    end

    if type == 'macro' then
        local itemName = GetMacroItem(id)
        if itemName then
            local name, spellID = GetItemSpell(itemName)
            return spellID
        else
            local spellID = GetMacroSpell(id)
            return spellID
        end
    end
end

function ComboStrikerOverlayMixin:Update()
    local id = self:GetActionSpellID()
    self:GetParent().icon:SetDesaturated(id and id == previousSpellID)
    self:SetShown(id and id == previousSpellID)
end
