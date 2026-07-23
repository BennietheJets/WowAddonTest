local addonName, addonTable = ...

-- Karazhan Boss Mechanics

-- Attumen the Huntsman: Spectral Blast
addonTable:RegisterAbility(29844, {
    message = "Spectral Blast!",
    HEALER = "Big tank damage!",
    type = "cast"
})

-- Moroes: Garrote
addonTable:RegisterAbility(37066, {
    message = "Garrote",
    HEALER = "Cleanse/Heal Garrote!",
    type = "aura",
    playerOnly = false
})

-- Prince Malchezaar: Enfeeble
addonTable:RegisterAbility(30843, {
    message = "Enfeeble - 1 HP!",
    RANGED = "Stay away from boss!",
    type = "aura",
    playerOnly = true
})
