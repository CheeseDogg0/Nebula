#define ANYMPH_SCREEN_LOC_HELD   "RIGHT-8:16,BOTTOM:5"
#define ANYMPH_SCREEN_LOC_HAT    "RIGHT-7:16,BOTTOM:5"
#define ANYMPH_SCREEN_LOC_MOLT   "RIGHT-6:16,BOTTOM:5"
#define ANYMPH_SCREEN_LOC_INTENT "RIGHT-2,BOTTOM:5"
#define ANYMPH_SCREEN_LOC_HEALTH ui_alien_health

#define ANYMPH_MAX_CRYSTALS      20000
#define ANYMPH_CRYSTAL_MOLT      2000  // How much it takes to molt.
#define ANYMPH_NUTRITION_MOLT    125   // How much nutrition it takes to molt.
#define ANYMPH_TIME_MOLT         300   // How long to wait between molts.

/mob/living/carbon/alien/ascent_nymph
	name = "mantid nymph"
	desc = "It's a little alien skittery critter. Hiss."
	icon = 'mods/species/ascent/icons/species/nymph.dmi'
	icon_state = ICON_STATE_WORLD
	death_msg = "expires with a pitiful hiss..."
	health = 60
	maxHealth = 60
	available_maneuvers = list(/decl/maneuver/leap)

	only_species_language = 1
	voice_name = "mantid nymph"
	speak_emote = list("hisses", "chitters")
	universal_understand = FALSE
	universal_speak = FALSE

	can_pull_size = ITEM_SIZE_SMALL
	can_pull_mobs = MOB_PULL_SMALLER

	holder_type = /obj/item/holder/ascent_nymph
	possession_candidate = 1
	atom_flags = ATOM_FLAG_NO_TEMP_CHANGE | ATOM_FLAG_NO_CHEM_CHANGE
	hud_type = /datum/hud/ascent_nymph

	var/crystal_reserve = 1000
	var/last_molt = 0
	var/molt

/mob/living/carbon/alien/ascent_nymph/get_jump_distance()
	return 3

/mob/living/carbon/alien/ascent_nymph/Initialize(var/mapload)
	update_icon()
	. = ..(mapload)
	add_inventory_slot(new /datum/inventory_slot/head/simple)
	add_held_item_slot(new /datum/inventory_slot/gripper/mouth/nymph/ascent)
	set_extension(src, /datum/extension/base_icon_state, icon_state)

/mob/living/carbon/alien/ascent_nymph/get_dexterity(var/silent)
	return (DEXTERITY_EQUIP_ITEM|DEXTERITY_HOLD_ITEM)

/mob/living/carbon/alien/ascent_nymph/on_update_icon()
	..()
	icon_state = ICON_STATE_WORLD
	if(stat != CONSCIOUS || lying)
		icon_state += "-dead"
