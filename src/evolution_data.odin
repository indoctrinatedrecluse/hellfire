package hellfire

import "core:math"

Card_Stage_Data :: struct {
    stage:       int,     // 0 to 4
    name:        string,
    epithet:     string,
    element:     Element,
    rarity:      int,     // 3 to 7 stars
    power_mult:  f32,     // 1.0x, 2.0x, 3.0x, 4.0x, 5.0x
    description: string,
}

get_card_stage_data :: proc(elem: Element, stage_in: int) -> Card_Stage_Data {
    stage := math.clamp(stage_in, 0, MAX_EVO_STAGES - 1)
    mult  := 1.0 + f32(stage) * 1.0 // 1x, 2x, 3x, 4x, 5x
    stars := 3 + stage              // 3, 4, 5, 6, 7 stars

    switch elem {
    case .FIRE:
        switch stage {
        case 0: return Card_Stage_Data{0, "Ignis Drake", "Volcanic Whelp", elem, stars, mult, "Fierce dragon forged in boiling magma trenches."}
        case 1: return Card_Stage_Data{1, "Flame Valkyrie", "Crimson Maiden", elem, stars, mult, "Alluring winged maiden wielding twin flaming blades."}
        case 2: return Card_Stage_Data{2, "Infernal Sorceress", "Hellfire Weaver", elem, stars, mult, "Enchantress clad in burning silk, weaving cataclysmic embers."}
        case 3: return Card_Stage_Data{3, "Pyromancer Queen", "Sovereign of Ash", elem, stars, mult, "Majestic queen reigning over volcanos and molten seas."}
        case 4: return Card_Stage_Data{4, "Ignis, Hellfire Goddess", "Primordial Flame", elem, stars, mult, "Transcendent divine goddess of pure cosmic combustion."}
        }

    case .WATER:
        switch stage {
        case 0: return Card_Stage_Data{0, "Abyssal Leviathan", "Tidal Wyrm", elem, stars, mult, "Colossal sea dragon haunting deep oceanic trenches."}
        case 1: return Card_Stage_Data{1, "Coral Siren", "Abyssal Nymph", elem, stars, mult, "Enchanting siren whose hypnotic melody summons tidal waves."}
        case 2: return Card_Stage_Data{2, "Tide Empress", "Ocean Monarch", elem, stars, mult, "Imperial mistress commanding whirlpools and geysers."}
        case 3: return Card_Stage_Data{3, "Oceanic Nereid", "Spire of the Deep", elem, stars, mult, "Graceful goddess draped in bioluminescent aquatic veil."}
        case 4: return Card_Stage_Data{4, "Tiamat, Sea Queen", "Primordial Tides", elem, stars, mult, "Ancient sovereign mother of all waters in the cosmos."}
        }

    case .EARTH:
        switch stage {
        case 0: return Card_Stage_Data{0, "Gaea Titan", "Granite Colossus", elem, stars, mult, "Ancient moss-clad stone monolith of primeval caverns."}
        case 1: return Card_Stage_Data{1, "Bramble Dryad", "Grove Spirit", elem, stars, mult, "Alluring nature maiden draped in blooming vines and emerald petals."}
        case 2: return Card_Stage_Data{2, "Verdant Huntress", "Archon of Thorns", elem, stars, mult, "Fierce sylvan warden commanding crushing ancient roots."}
        case 3: return Card_Stage_Data{3, "Sylvan Matriarch", "Heart of the Forest", elem, stars, mult, "High matriarch channeling the living pulse of the world."}
        case 4: return Card_Stage_Data{4, "Gaea, Sovereign Mother", "Earth Ascendant", elem, stars, mult, "Supreme titan goddess embodying the enduring strength of the earth."}
        }

    case .CHAOS:
        switch stage {
        case 0: return Card_Stage_Data{0, "Malphas Fiend", "Void Gargoyle", elem, stars, mult, "Demonic beast soaring on leathery wings across the abyss."}
        case 1: return Card_Stage_Data{1, "Shadow Succubus", "Nether Temptress", elem, stars, mult, "Alluring dark demoness weaving seductive violet flame sorcery."}
        case 2: return Card_Stage_Data{2, "Void Temptress", "Archduchess of Ruin", elem, stars, mult, "Bewitching chaos sovereign tearing fractures through reality."}
        case 3: return Card_Stage_Data{3, "Abyssal Archduchess", "Mistress of Shadows", elem, stars, mult, "Gothic queen adorned in obsidian regalia and purple flame."}
        case 4: return Card_Stage_Data{4, "Lilith, Queen of Abyss", "Empress of Chaos", elem, stars, mult, "Supreme mistress of the dark abyss, ruler of eternal night."}
        }

    case .LIGHT:
        switch stage {
        case 0: return Card_Stage_Data{0, "Sunstone Guard", "Gilded Sentinel", elem, stars, mult, "Golden armor sentinel safeguarding holy cathedral gates."}
        case 1: return Card_Stage_Data{1, "Dawn Maiden", "Sunlight Priestess", elem, stars, mult, "Radiant maiden bathed in the warm light of the rising dawn."}
        case 2: return Card_Stage_Data{2, "Seraph Valkyrie", "Sword of Dawn", elem, stars, mult, "Six-winged angelic valkyrie striking down demons with holy judgment."}
        case 3: return Card_Stage_Data{3, "Solar Archangel", "Divine Judgement", elem, stars, mult, "Blinding celestial entity cloaked in sacred silver and gold."}
        case 4: return Card_Stage_Data{4, "Aurora, Light Goddess", "Infinite Radiance", elem, stars, mult, "Supreme goddess of the sun and celestial dawn, banishing all darkness."}
        }
    }

    return Card_Stage_Data{0, "Unknown", "None", elem, 3, 1.0, "Unknown creature."}
}

get_stage_roman :: proc(stage: int) -> cstring {
    switch stage {
    case 0: return "TIER I"
    case 1: return "TIER II"
    case 2: return "TIER III"
    case 3: return "TIER IV"
    case 4: return "TIER V"
    }
    return "TIER I"
}

