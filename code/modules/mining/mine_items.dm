/**********************Miner Lockers**************************/

/obj/structure/closet/secure_closet/miner
	name = "miner's equipment"
	closet_appearance = /decl/closet_appearance/secure_closet/mining
	req_access = list(access_mining)

/obj/structure/closet/secure_closet/miner/WillContain()
	return list(
		new /datum/atom_creator/weighted(list(
				/obj/item/storage/backpack/industrial,
				/obj/item/storage/backpack/satchel/eng
			)),
		/obj/item/radio/headset/headset_cargo,
		/obj/item/clothing/under/miner,
		/obj/item/clothing/gloves/thick,
		/obj/item/clothing/shoes/color/black,
		/obj/item/scanner/gas,
		/obj/item/storage/ore,
		/obj/item/flashlight/lantern,
		/obj/item/shovel,
		/obj/item/pickaxe,
		/obj/item/clothing/glasses/meson
	)

/**********'pickaxes' but theyre drills actually***************/

/obj/item/pickaxe
	name = "mining drill"
	desc = "The most basic of mining drills, for short excavations and small mineral extractions."
	icon = 'icons/obj/items/tool/drills/drill.dmi'
	icon_state = ICON_STATE_WORLD
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_LOWER_BODY
	force = 15.0
	throwforce = 4
	w_class = ITEM_SIZE_HUGE
	material = /decl/material/solid/metal/steel
	origin_tech = "{'materials':1,'engineering':1}"
	attack_verb = list("hit", "pierced", "sliced", "attacked")
	sharp = 0

	var/digspeed = 40 //moving the delay to an item var so R&D can make improved picks. --NEO
	var/drill_sound = 'sound/weapons/Genhit.ogg'
	var/drill_verb = "drilling"
	var/excavation_amount = 200
	var/build_from_parts = FALSE
	var/hardware_color

/obj/item/pickaxe/on_update_icon()
	. = ..()
	if(build_from_parts)
		color = hardware_color
		var/image/I = image(icon, "[icon_state]-handle")
		I.appearance_flags |= RESET_COLOR
		add_overlay(I)

/obj/item/pickaxe/adjust_mob_overlay(mob/living/user_mob, bodytype, image/overlay, slot, bodypart, use_fallback_if_icon_missing = TRUE)
	if(overlay && build_from_parts && check_state_in_icon("[overlay.icon_state]-handle", overlay.icon))
		var/image/handle = image(overlay.icon, "[overlay.icon_state]-handle")
		handle.appearance_flags |= RESET_COLOR
		overlay.overlays += handle
	. = ..()

/obj/item/pickaxe/hammer
	name = "sledgehammer"
	desc = "A mining hammer made of reinforced metal. You feel like smashing your boss in the face with this."
	icon = 'icons/obj/items/tool/drills/sledgehammer.dmi'

/obj/item/pickaxe/drill
	name = "advanced mining drill" // Can dig sand as well!
	icon = 'icons/obj/items/tool/drills/drill_hand.dmi'
	digspeed = 30
	origin_tech = "{'materials':2,'powerstorage':3,'engineering':2}"
	desc = "Yours is the drill that will pierce through the rock walls."
	drill_verb = "drilling"
	material = /decl/material/solid/metal/steel
	matter = list(/decl/material/solid/fiberglass = MATTER_AMOUNT_REINFORCEMENT)

/obj/item/pickaxe/drill/Initialize(ml, material_key)
	. = ..()
	set_extension(src, /datum/extension/tool, list(TOOL_DRILL = TOOL_QUALITY_MEDIOCRE))

/obj/item/pickaxe/jackhammer
	name = "sonic jackhammer"
	icon = 'icons/obj/items/tool/drills/jackhammer.dmi'
	digspeed = 20 //faster than drill, but cannot dig
	origin_tech = "{'materials':3,'powerstorage':2,'engineering':2}"
	desc = "Cracks rocks with sonic blasts, perfect for killing cave lizards."
	drill_verb = "hammering"

/obj/item/pickaxe/diamonddrill //When people ask about the badass leader of the mining tools, they are talking about ME!
	name = "diamond mining drill"
	icon = 'icons/obj/items/tool/drills/drill_diamond.dmi'
	digspeed = 5 //Digs through walls, girders, and can dig up sand
	origin_tech = "{'materials':6,'powerstorage':4,'engineering':5}"
	desc = "Yours is the drill that will pierce the heavens!"
	drill_verb = "drilling"
	material = /decl/material/solid/metal/steel
	matter = list(
		/decl/material/solid/fiberglass = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/gemstone/diamond = MATTER_AMOUNT_TRACE
	)

/obj/item/pickaxe/borgdrill
	name = "cyborg mining drill"
	icon = 'icons/obj/items/tool/drills/drill_diamond.dmi'
	digspeed = 15
	desc = ""
	drill_verb = "drilling"

//****************************actual pickaxes***********************
/obj/item/pickaxe/silver
	name = "silver pickaxe"
	desc = "This makes no metallurgic sense."
	icon_state = "preview"
	icon = 'icons/obj/items/tool/drills/pickaxe.dmi'
	digspeed = 30
	origin_tech = "{'materials':3}"
	drill_verb = "picking"
	sharp = 1
	build_from_parts = TRUE
	hardware_color = COLOR_SILVER

/obj/item/pickaxe/gold
	name = "golden pickaxe"
	desc = "This makes no metallurgic sense."
	icon_state = "preview"
	icon = 'icons/obj/items/tool/drills/pickaxe.dmi'
	digspeed = 20
	origin_tech = "{'materials':4}"
	drill_verb = "picking"
	sharp = 1
	build_from_parts = TRUE
	hardware_color = COLOR_GOLD

/obj/item/pickaxe/diamond
	name = "diamond pickaxe"
	desc = "A pickaxe with a diamond pick head."
	icon_state = "preview"
	icon = 'icons/obj/items/tool/drills/pickaxe.dmi'
	digspeed = 10
	origin_tech = "{'materials':6,'engineering':4}"
	drill_verb = "picking"
	sharp = 1
	build_from_parts = TRUE
	hardware_color = COLOR_DIAMOND
	material = /decl/material/solid/gemstone/diamond

/*****************************Shovel********************************/

/obj/item/shovel
	name        = "shovel"
	desc        = "A large tool for digging and moving dirt."
	icon        = 'icons/obj/items/tool/shovels/shovel.dmi'
	icon_state  = ICON_STATE_WORLD
	slot_flags  = SLOT_LOWER_BODY
	force       = 8.0
	throwforce  = 4
	w_class     = ITEM_SIZE_HUGE
	origin_tech = "{'materials':1,'engineering':1}"
	material    = /decl/material/solid/metal/steel
	attack_verb = list("bashed", "bludgeoned", "thrashed", "whacked")
	edge        = 1
	var/tmp/shovel_quality = TOOL_QUALITY_DEFAULT

/obj/item/shovel/Initialize(ml, material_key)
	. = ..()
	set_extension(src, /datum/extension/tool, list(TOOL_SHOVEL = shovel_quality))

/obj/item/shovel/spade
	name           = "spade"
	desc           = "A small tool for digging and moving dirt."
	icon           = 'icons/obj/items/tool/shovels/spade.dmi'
	icon_state     = ICON_STATE_WORLD
	force          = 5.0
	throwforce     = 7
	w_class        = ITEM_SIZE_SMALL
	shovel_quality = TOOL_QUALITY_BAD //You're not gonna dig a trench with a garden spade..

// Flags.
/obj/item/stack/flag
	name = "beacon"
	desc = "Some deployable high-visibilty beacons."
	singular_name = "beacon"
	icon_state = "folded"
	amount = 10
	max_amount = 10
	icon = 'icons/obj/items/marking_beacon.dmi'
	z_flags = ZMM_MANGLE_PLANES

	var/upright = FALSE

/obj/item/stack/flag/red
	light_color = COLOR_RED

/obj/item/stack/flag/yellow
	light_color = COLOR_YELLOW

/obj/item/stack/flag/green
	light_color = COLOR_LIME

/obj/item/stack/flag/blue
	light_color = COLOR_BLUE

/obj/item/stack/flag/teal
	light_color = COLOR_TEAL

/obj/item/stack/flag/Initialize()
	. = ..()
	update_icon()

/obj/item/stack/flag/attackby(var/obj/item/W, var/mob/user)
	if(upright)
		return attack_hand_with_interaction_checks(user)
	return ..()

/obj/item/stack/flag/attack_hand(var/mob/user)
	if(!upright)
		return ..()
	knock_down()
	user.visible_message("\The [user] knocks down \the [singular_name].")
	return TRUE

/obj/item/stack/flag/attack_self(var/mob/user)
	var/turf/T = get_turf(src)

	if(!istype(T) || T.is_open())
		to_chat(user, "<span class='warning'>There's no solid surface to plant \the [singular_name] on.</span>")
		return

	for(var/obj/item/stack/flag/F in T)
		if(F.upright)
			to_chat(user, "<span class='warning'>\The [F] is already planted here.</span>")
			return

	if(use(1)) // Don't skip use() checks even if you only need one! Stacks with the amount of 0 are possible, e.g. on synthetics!
		var/obj/item/stack/flag/newflag = new src.type(T, 1)
		newflag.set_up()
		if(istype(T, /turf/simulated/floor/asteroid) || istype(T, /turf/exterior))
			user.visible_message("\The [user] plants \the [newflag.singular_name] firmly in the ground.")
		else
			user.visible_message("\The [user] attaches \the [newflag.singular_name] firmly to the ground.")

/obj/item/stack/flag/proc/set_up()
	upright = 1
	anchored = TRUE
	update_icon()

/obj/item/stack/flag/on_update_icon()
	. = ..()
	if(upright)
		pixel_x = 0
		pixel_y = 0
		icon_state = "base"
		add_overlay(emissive_overlay(icon = icon, icon_state = "glowbit", color = light_color))
		z_flags |= ZMM_MANGLE_PLANES
		set_light(2, 0.1) // Very dim so the rest of the thingie is barely visible - if the turf is completely dark, you can't see anything on it, no matter what
	else
		pixel_x = rand(-randpixel, randpixel)
		pixel_y = rand(-randpixel, randpixel)
		icon_state = "folded"
		add_overlay(overlay_image(icon, "basebit", light_color))
		z_flags &= ~ZMM_MANGLE_PLANES
		set_light(0)

/obj/item/stack/flag/proc/knock_down()
	upright = 0
	anchored = FALSE
	update_icon()
