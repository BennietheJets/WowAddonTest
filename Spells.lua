local addonName, addonTable = ...

-- Central registry for boss abilities
addonTable.BossAbilities = {}

--- Registers a new boss ability alert.
-- @param spellId The numeric ID of the spell.
-- @param data A table containing:
--   - message: Default alert text.
--   - TANK, HEALER, MELEE, RANGED: Role-specific alert text (optional).
--   - timer: Seconds until a follow-up alert (optional).
--   - type: "cast" (default) or "aura".
function addonTable:RegisterAbility(spellId, data)
    if not spellId or not data then return end
    self.BossAbilities[spellId] = data
end

-- Example abilities (will be moved to Mechanics/ folder later)
addonTable:RegisterAbility(123456, { 
    message = "BIG ATTACK INCOMING!", 
    TANK = "TAUNT THE BOSS NOW!", 
    HEALER = "INTENSE GROUP DAMAGE!",
    timer = 5,
    type = "cast"
})

addonTable:RegisterAbility(234567, { 
    message = "GET AWAY!", 
    MELEE = "RUN OUT OF MELEE RANGE!",
    type = "cast"
})
