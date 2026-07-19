local addonName, addonTable = ...

-- Configuration for specific boss abilities
-- You can now add role-specific messages using: TANK, HEALER, MELEE, RANGED
addonTable.BossAbilities = {
    [123456] = { 
        message = "BIG ATTACK INCOMING!", 
        TANK = "TAUNT THE BOSS NOW!", 
        HEALER = "INTENSE GROUP DAMAGE!",
        timer = 5 
    },
    [234567] = { 
        message = "GET AWAY!", 
        MELEE = "RUN OUT OF MELEE RANGE!",
        timer = nil 
    },
}
