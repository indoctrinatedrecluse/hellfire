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
    
    // Dual elements feature 1.5x higher base power scaling than basic elements!
    is_dual := is_dual_element(elem)
    base_step : f32 = is_dual ? 1.5 : 1.0
    mult  := base_step + f32(stage) * base_step // Basic: 1x..5x | Dual: 1.5x..7.5x
    stars := (is_dual ? 4 : 3) + stage         // Basic: 3..7★ | Dual: 4..8★

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

    // --- 10 Dual / Compound Elements (5C2) ---
    case .STEAM:
        switch stage {
        case 0: return Card_Stage_Data{0, "Steam Nymph", "Spring Dancer", elem, stars, mult, "Playful nymph dancing amidst bubbling thermal hot springs and white vapor."}
        case 1: return Card_Stage_Data{1, "Geyser Valkyrie", "Scalding Wing", elem, stars, mult, "Fierce winged maiden wielding dual spears of superheated pressurized steam."}
        case 2: return Card_Stage_Data{2, "Scalding Sorceress", "Thermal Weaver", elem, stars, mult, "Enchantress clad in sheer white vapor silk, melting heavy armor with boiling mist."}
        case 3: return Card_Stage_Data{3, "Vapor Empress", "Cloud Monarch", elem, stars, mult, "Majestic empress commanding thermal cloudbursts and hurricane scalds."}
        case 4: return Card_Stage_Data{4, "Sulis, Thermal Goddess", "Primordial Caldera", elem, stars, mult, "Supreme deity presiding over cosmic hydrothermal eruptions and boiling seas."}
        }

    case .MAGMA:
        switch stage {
        case 0: return Card_Stage_Data{0, "Basalt Drake", "Lava Hound", elem, stars, mult, "Spiky beast armored in cooling volcanic basalt and liquid molten rock."}
        case 1: return Card_Stage_Data{1, "Volcanic Maiden", "Ashen Grace", elem, stars, mult, "Alluring maiden leaving incandescent molten footprints wherever she steps."}
        case 2: return Card_Stage_Data{2, "Pyroclast Archon", "Basalt Warden", elem, stars, mult, "Fierce warrioress hurling burning obsidian boulders and rivers of magma."}
        case 3: return Card_Stage_Data{3, "Caldera Queen", "Mistress of Mantle", elem, stars, mult, "Regal queen seated atop an active supervolcano throne of liquid fire."}
        case 4: return Card_Stage_Data{4, "Pele, Core Goddess", "Tectonic Sovereign", elem, stars, mult, "Supreme titan mother of planetary core magma and tectonic genesis."}
        }

    case .NETHERFLAME:
        switch stage {
        case 0: return Card_Stage_Data{0, "Cinder Imp", "Void Spark", elem, stars, mult, "Mischievous horned imp flickering with eerie violet infernal sparks."}
        case 1: return Card_Stage_Data{1, "Hellfire Succubus", "Nether Temptress", elem, stars, mult, "Bewitching demoness cloaked in hungry dark violet flames that devour souls."}
        case 2: return Card_Stage_Data{2, "Nether Pyromancer", "Abyssal Weaver", elem, stars, mult, "Sorceress casting cataclysmic violet combustion that burns through reality."}
        case 3: return Card_Stage_Data{3, "Abyssal Flame Mistress", "Queen of Embers", elem, stars, mult, "Dark sovereign surrounded by eternal burning vortexes of cursed purple fire."}
        case 4: return Card_Stage_Data{4, "Hecate, Hellfire Queen", "Primordial Voidflame", elem, stars, mult, "Supreme goddess of the darkest unholy flames spanning the cosmic abyss."}
        }

    case .SOLAR:
        switch stage {
        case 0: return Card_Stage_Data{0, "Sunstone Sprite", "Dawn Sparkle", elem, stars, mult, "Gleaming golden sprite radiating warm noon daylight and bright sparks."}
        case 1: return Card_Stage_Data{1, "Solar Valkyrie", "Corona Blade", elem, stars, mult, "Glorious winged champion clad in sun-forged armor, cleaving darkness."}
        case 2: return Card_Stage_Data{2, "Dawn Empress", "Matriarch of Noon", elem, stars, mult, "Radiant queen cloaked in blinding sunlight, summoning scorching rays."}
        case 3: return Card_Stage_Data{3, "Corona Seraph", "Heavenly Flare", elem, stars, mult, "Six-winged archangel weaving incandescent solar plasma and holy sunfire."}
        case 4: return Card_Stage_Data{4, "Amaterasu, Sun Sovereign", "Infinite Sol", elem, stars, mult, "Supreme celestial goddess of the radiant burning sun, banishing all shadow."}
        }

    case .MIRE:
        switch stage {
        case 0: return Card_Stage_Data{0, "Swamp Sylph", "Fen Lurker", elem, stars, mult, "Ethereal spirit resting amidst blooming lotus pads, marsh mist, and tangled moss."}
        case 1: return Card_Stage_Data{1, "Lotus Dryad", "Bog Blossom", elem, stars, mult, "Alluring maiden adorned in poisonous water orchids and sweet marsh blossoms."}
        case 2: return Card_Stage_Data{2, "Wetland Enchantress", "Mire Weaver", elem, stars, mult, "Sylvan witch ensnaring trespassers in deep quagmires and toxic waters."}
        case 3: return Card_Stage_Data{3, "Matriarch of the Fen", "Cypress Sovereign", elem, stars, mult, "Ancient queen ruling overgrown wetland labyrinths and primordial bogs."}
        case 4: return Card_Stage_Data{4, "Danu, Wetland Mother", "Cradle of Life", elem, stars, mult, "Supreme primordial mother of fertile wetlands, marshes, and emerald life."}
        }

    case .ABYSS:
        switch stage {
        case 0: return Card_Stage_Data{0, "Trench Fiend", "Hadal Stalker", elem, stars, mult, "Bioluminescent creature gliding through pitch-black oceanic abyssal depths."}
        case 1: return Card_Stage_Data{1, "Abyssal Siren", "Trench Temptress", elem, stars, mult, "Hypnotic mermaid whose haunting song lures seafarers into bottomless rifts."}
        case 2: return Card_Stage_Data{2, "Leviathan Priestess", "Crushing Void", elem, stars, mult, "Gothic ocean priestess wielding the crushing atmospheric pressure of the trench."}
        case 3: return Card_Stage_Data{3, "Mistress of the Deep", "Hadal Queen", elem, stars, mult, "Dark sovereign crowned in black coral, summoning colossal dark tides."}
        case 4: return Card_Stage_Data{4, "Charybdis, Maelstrom Empress", "Oceanic Singularity", elem, stars, mult, "Supreme abyssal titan swallowing entire ocean basins into endless void."}
        }

    case .GLACIER:
        switch stage {
        case 0: return Card_Stage_Data{0, "Frost Sprite", "Glistening Flurry", elem, stars, mult, "Playful crystalline fairy trailing glittering sacred frost across ice crystals."}
        case 1: return Card_Stage_Data{1, "Aurora Maiden", "Polar Lights", elem, stars, mult, "Graceful dancer cloaked in glowing green and violet polar auroras."}
        case 2: return Card_Stage_Data{2, "Glacial Valkyrie", "Spear of Winter", elem, stars, mult, "Armored maiden brandishing a holy spear carved of unbreakable eternal ice."}
        case 3: return Card_Stage_Data{3, "Ice Queen", "Blizzard Monarch", elem, stars, mult, "Majestic sovereign freezing entire battlefields into pristine crystal sculptures."}
        case 4: return Card_Stage_Data{4, "Skadi, Winter Goddess", "Everlasting Frost", elem, stars, mult, "Supreme celestial goddess reigning over the frozen reaches of the cosmos."}
        }

    case .OBSIDIAN:
        switch stage {
        case 0: return Card_Stage_Data{0, "Gargoyle Whelp", "Glass Shard", elem, stars, mult, "Living black glass imp with razor-sharp wings reflecting violet light."}
        case 1: return Card_Stage_Data{1, "Obsidian Maiden", "Razor Stone", elem, stars, mult, "Alluring gothic maiden carved of mirrored black glass and purple runes."}
        case 2: return Card_Stage_Data{2, "Rift Archon", "Chasm Cleaver", elem, stars, mult, "Dark geomancer rending catastrophic necrotic fractures through bedrock."}
        case 3: return Card_Stage_Data{3, "Necro-Titan Empress", "Obsidian Queen", elem, stars, mult, "Dark sovereign commanding towering monoliths of sharp crystalline obsidian."}
        case 4: return Card_Stage_Data{4, "Morrigan, Shattered Sovereign", "Tectonic Doom", elem, stars, mult, "Supreme goddess of fractured tectonic plates and indestructible volcanic glass."}
        }

    case .CRYSTAL:
        switch stage {
        case 0: return Card_Stage_Data{0, "Quartz Sprite", "Prism Glow", elem, stars, mult, "Radiant sprite reflecting prismatic rainbow beams through natural gemstones."}
        case 1: return Card_Stage_Data{1, "Prism Priestess", "Sacred Facet", elem, stars, mult, "Graceful holy maiden channeling sunlight through orbiting sacred crystals."}
        case 2: return Card_Stage_Data{2, "Diamond Valkyrie", "Unbreakable Aegis", elem, stars, mult, "Holy warrior clad in flawless diamond armor that reflects all hostile magic."}
        case 3: return Card_Stage_Data{3, "Geode Matriarch", "Heart of the Mine", elem, stars, mult, "Divine empress birthing iridescent living gemstones from the deep earth."}
        case 4: return Card_Stage_Data{4, "Astarte, Crystal Goddess", "Prismatic Eternal", elem, stars, mult, "Supreme goddess of celestial diamond spires and boundless holy radiance."}
        }

    case .ECLIPSE:
        switch stage {
        case 0: return Card_Stage_Data{0, "Twilight Shade", "Syzygy Wisp", elem, stars, mult, "Mystic entity balanced perfectly between radiant illumination and deep abyss."}
        case 1: return Card_Stage_Data{1, "Eclipse Valkyrie", "Dual Wing", elem, stars, mult, "Maiden with one wing of blinding light and one wing of velvet shadow."}
        case 2: return Card_Stage_Data{2, "Umbral Priestess", "Corona Dancer", elem, stars, mult, "Sorceress harmonizing sacred angelic hymns with ancient abyssal incantations."}
        case 3: return Card_Stage_Data{3, "Syzygy Monarch", "Black Sun Queen", elem, stars, mult, "Goddess crowned in the golden corona ring of a total solar eclipse."}
        case 4: return Card_Stage_Data{4, "Nyx-Helia, Goddess of Dual Cosmos", "Equilibrium Ascendant", elem, stars, mult, "Supreme transcendent deity commanding the cosmic balance of all light and void."}
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

