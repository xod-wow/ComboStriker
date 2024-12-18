--[[----------------------------------------------------------------------------

    ComboStriker
    Copyright 2022 Mike "Xodiv" Battersby

----------------------------------------------------------------------------]]--


local MASTERY_COMBO_STRIKES_SPELL_ID = 115636

local ComboStrikeSpellIDs = {
    [100784] = true,            -- Blackout Kick
    [123986] = true,            -- Chi Burst
    [443028] = true,            -- Celestial Conduit
    [117952] = true,            -- Crackling Jade Lightning
    [388193] = true,            -- Jadefire Stomp
    [113656] = true,            -- Fists of Fury
    [107428] = true,            -- Rising Sun Kick
    [101546] = true,            -- Spinning Crane Kick
    [137639] = true,            -- Storm, Earth and Fire
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
    if not self.isDirty then return end
    self.isDirty = nil

    if IsPlayerSpell(MASTERY_COMBO_STRIKES_SPELL_ID) then
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

function ComboStriker:TriggerEnableDisable()
    self.isDirty = true
    C_Timer.After(0, function () self:EnableDisable() end)
end

function ComboStriker:TRAIT_CONFIG_UPDATED(id)
    if id == C_ClassTalents.GetActiveConfigID() then
        self:TriggerEnableDisable()
    end
end

function ComboStriker:PLAYER_SPECIALIZATION_CHANGED(unit)
    if unit == 'player' then
        self:TriggerEnableDisable()
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
        self:TriggerEnableDisable()
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

    if type == 'macro' and subType == 'spell' then
        return id
    end
end

function ComboStrikerOverlayMixin:Update()
    local id = self:GetActionSpellID()
    self:GetParent().icon:SetDesaturated(id and id == previousSpellID)
    self:SetShown(id and id == previousSpellID)
end
