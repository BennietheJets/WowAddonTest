local addonName, addonTable = ...

-- Mount Hyjal Wave Breakdowns
-- -------------------------
-- Wave 1: 10 Ghoul
-- Wave 2: 10 Ghoul, 2 Crypt Fiend
-- Wave 3: 6 Ghoul, 6 Crypt Fiend
-- Wave 4: 6 Ghoul, 4 Crypt Fiend, 2 Shadowy Necromancer
-- Wave 5: 2 Ghoul, 6 Crypt Fiend, 4 Shadowy Necromancer
-- Wave 6: 6 Ghoul, 6 Abomination (Tanks use FAP for stun)
-- Wave 7: 4 Ghoul, 4 Shadowy Necromancer, 4 Abomination
-- Wave 8: 6 Ghoul, 4 Crypt Fiend, 2 Abomination, 2 Shadowy Necromancer
-- Boss: RAGE WINTERCHILL

-- Wave 1: 10 Ghoul
-- Wave 2: 8 Ghoul, 4 Abomination
-- Wave 3: 4 Ghoul, 4 Crypt Fiend, 4 Shadowy Necromancer
-- Wave 4: 4 Shadowy Necromancer, 6 Crypt Fiend, 2 Banshee
-- Wave 5: 6 Ghoul, 2 Shadowy Necromancer, 4 Banshee
-- Wave 6: 6 Ghoul, 2 Abomination, 4 Shadowy Necromancer
-- Wave 7: 2 Ghoul, 4 Crypt Fiend, 4 Abomination, 4 Banshee
-- Wave 8: 3 Ghoul, 3 Crypt Fiend, 2 Shadowy Necromancer, 4 Abomination, 2 Banshee
-- Boss: ANETHERON

-- Wave 1: 4 Ghoul, 2 Shadowy Necromancer, 4 Abomination, 2 Banshee
-- Wave 2: 4 Ghoul, 10 Gargoyle
-- Wave 3: 6 Ghoul, 6 Crypt Fiend, 2 Shadowy Necromancer
-- Wave 4: 6 Crypt Fiend, 2 Shadowy Necromancer, 6 Gargoyle
-- Wave 5: 4 Ghoul, 4 Shadowy Necromancer, 6 Abomination
-- Wave 6: 8 Gargoyle, 1 Frost Wyrm
-- Wave 7: 6 Ghoul, 4 Abomination, 1 Frost Wyrm
-- Wave 8: 6 Ghoul, 2 Crypt Fiend, 2 Shadowy Necromancer, 4 Abomination, 2 Banshee
-- Boss: KAZ'ROGAL

-- Wave 1: 6 Shadowy Necromancer, 6 Abomination
-- Wave 2: 5 Ghoul, 8 Gargoyle, 1 Frost Wyrm
-- Wave 3: 6 Ghoul, 8 Giant Infernal
-- Wave 4: 8 Giant Infernal, 6 Fel Stalker
-- Wave 5: 4 Shadowy Necromancer, 6 Fel Stalker, 4 Abomination
-- Wave 6: 6 Shadowy Necromancer, 6 Banshee
-- Wave 7: 2 Ghoul, 2 Crypt Fiend, 8 Giant Infernal, 2 Fel Stalker
-- Wave 8: 4 Crypt Fiend, 2 Shadowy Necromancer, 4 Abomination, 4 Banshee, 2 Fel Stalker
-- Boss: AZGALOR

-- Boss: ARCHIMONDE

-- Trash Abilities
-- -------------------------

-- Ghoul: Enrage
addonTable:RegisterAbility(31549, {
    message = "Ghoul Enrage - Dispel!",
    type = "aura"
})

-- Crypt Fiend: Web
addonTable:RegisterAbility(28991, {
    message = "Web - Rooted!",
    type = "aura"
})

-- Shadowy Necromancer: Unholy Frenzy
addonTable:RegisterAbility(31626, {
    message = "Unholy Frenzy - Dispel!",
    HEALER = "Dispel Unholy Frenzy!",
    type = "aura"
})

-- Shadowy Necromancer: Cripple
addonTable:RegisterAbility(33787, {
    message = "Cripple - Dispel!",
    HEALER = "Dispel Cripple!",
    type = "aura"
})

-- Abomination: Knockdown
addonTable:RegisterAbility(31610, {
    message = "Abomination Knockdown!",
    TANK = "Use FAP or Ironshield!",
    type = "cast"
})

-- Banshee: Banshee Curse
addonTable:RegisterAbility(17905, {
    message = "Banshee Curse - Decurse!",
    HEALER = "Decurse Banshee Curse!",
    type = "aura"
})

-- Banshee: Anti-Magic Shell
addonTable:RegisterAbility(31662, {
    message = "Banshee Anti-Magic Shell!",
    type = "aura"
})

-- Gargoyle: Gargoyle Strike
addonTable:RegisterAbility(31664, {
    message = "Gargoyle Strike!",
    type = "cast"
})

-- Frost Wyrm: Frost Breath
addonTable:RegisterAbility(31688, {
    message = "Frost Breath - Move!",
    HEALER = "Dispel Frost Breath Slow!",
    type = "cast"
})

-- Infernal: Flame Buffet
addonTable:RegisterAbility(31724, {
    message = "Flame Buffet - Dispel!",
    type = "aura"
})

-- Infernal: Immolation
addonTable:RegisterAbility(39007, {
    message = "Immolation - Stay away!",
    type = "aura"
})

-- Fel Hound: Mana Burn
addonTable:RegisterAbility(31729, {
    message = "Mana Burn - Interrupt!",
    type = "cast"
})

-- Boss: Rage Winterchill
-- -------------------------

-- Icebolt
addonTable:RegisterAbility(31249, {
    message = "Icebolt - Stunned!",
    HEALER = "Heal Icebolt target!",
    type = "cast"
})

-- Frost Nova
addonTable:RegisterAbility(31250, {
    message = "Frost Nova - Rooted!",
    type = "cast"
})

-- Frost Armor
addonTable:RegisterAbility(31256, {
    message = "Frost Armor - Snared!",
    type = "aura"
})

-- Death & Decay
addonTable:RegisterAbility(31258, {
    message = "Death & Decay - MOVE OUT!",
    type = "cast"
})

-- Boss: Anetheron
-- -------------------------

-- Vampiric Aura
addonTable:RegisterAbility(38196, {
    message = "Vampiric Aura - Healing Reduction Needed!",
    type = "aura"
})

-- Sleep
addonTable:RegisterAbility(31298, {
    message = "Sleep!",
    type = "aura"
})

-- Carrion Swarm
addonTable:RegisterAbility(31306, {
    message = "Carrion Swarm - Spread!",
    HEALER = "Carrion Swarm - Healing Reduced!",
    type = "cast"
})

-- Summon Infernal
addonTable:RegisterAbility(31299, {
    message = "Infernal Spawning - Move!",
    TANK = "Pick up Infernal!",
    RANGED = "Focus Infernal!",
    type = "cast"
})

-- Boss: Kaz'rogal
-- -------------------------

-- Malevolent Cleave
addonTable:RegisterAbility(31436, {
    message = "Cleave!",
    TANK = "Soak cleave with NPCs!",
    type = "cast"
})

-- War Stomp
addonTable:RegisterAbility(31480, {
    message = "War Stomp - Stunned!",
    type = "cast"
})

-- Mark of Kaz'rogal
addonTable:RegisterAbility(31447, {
    message = "Mark of Kaz'rogal - Watch Mana!",
    RANGED = "Mana low? Spread out!",
    type = "aura"
})

-- Cripple (Note: Guide listed ID 31258, which conflicts with Death & Decay. Using 33787 from trash instead if needed, but omitted for now to avoid conflict)

-- Boss: Azgalor
-- -------------------------

-- Cleave
addonTable:RegisterAbility(31345, {
    message = "Cleave!",
    type = "cast"
})

-- Doom
addonTable:RegisterAbility(31347, {
    message = "DOOM!",
    HEALER = "Heal Doom target!",
    type = "aura",
    playerOnly = false
})

-- Howl of Azgalor
addonTable:RegisterAbility(31344, {
    message = "Silence!",
    HEALER = "Silence - Spells locked!",
    type = "cast"
})

-- Rain of Fire
addonTable:RegisterAbility(31340, {
    message = "Rain of Fire - MOVE!",
    type = "cast"
})

-- Boss: Archimonde
-- -------------------------

-- Air Burst
addonTable:RegisterAbility(32014, {
    message = "Air Burst - Use Tear!",
    type = "cast"
})

-- Doomfire Strike
addonTable:RegisterAbility(31903, {
    message = "Doomfire - MOVE!",
    type = "cast"
})

-- Fear
addonTable:RegisterAbility(31970, {
    message = "Fear - Tremor Totem!",
    type = "cast"
})

-- Grip of the Legion
addonTable:RegisterAbility(31972, {
    message = "Grip of the Legion - Decurse!",
    HEALER = "Decurse Grip!",
    type = "aura",
    playerOnly = false
})
