var/global/list/_limb_mask_cache = list()
/proc/get_limb_mask_for(var/decl/bodytype/bodytype, var/bodypart)
	LAZYINITLIST(_limb_mask_cache[bodytype])
	if(!_limb_mask_cache[bodytype][bodypart])
		var/icon/limb_mask = icon(bodytype.icon_base, bodypart)
		limb_mask.MapColors(0,0,0, 0,0,0, 0,0,0, 1,1,1)
		_limb_mask_cache[bodytype][bodypart] = limb_mask
	return _limb_mask_cache[bodytype][bodypart]

/*
	Global associative list for caching humanoid icons.
	Index format m or f, followed by a string of 0 and 1 to represent bodyparts followed by husk 1 or 0.
	TODO: Proper documentation
	icon_key is [bodytype.get_icon_cache_uid(src)][g][husk][skin_tone]
*/
var/global/list/human_icon_cache = list()
var/global/list/tail_icon_cache = list() //key is [bodytype.get_icon_cache_uid(src)][skin_colour]
var/global/list/light_overlay_cache = list()

/proc/overlay_image(icon,icon_state,color,flags)
	var/image/ret = image(icon,icon_state)
	ret.color = color
	ret.appearance_flags = flags
	return ret

	///////////////////////
	//UPDATE_ICONS SYSTEM//
	///////////////////////
/*

UPDATED August 2023: The comments below are from a point where human equipment overlay code was entirely
defined in procs in this file; please refer to get/set_current_mob_underlay/overlay and update_equipment_overlay.

Calling this  a system is perhaps a bit trumped up. It is essentially update_clothing dismantled into its
core parts. The key difference is that when we generate overlays we do not generate either lying or standing
versions. Instead, we generate both and store them in two fixed-length lists, both using the same list-index
(The indexes are in update_icons.dm): Each list for humans is (at the time of writing) of length 19.
This will hopefully be reduced as the system is refined.

When we call update_icons, the 'lying' variable is checked and then the appropriate list is assigned to our overlays!
That in itself uses a tiny bit more memory (no more than all the ridiculous lists the game has already mind you).

On the other-hand, it should be very CPU cheap in comparison to the old system.
In the old system, we updated all our overlays every life() call, even if we were standing still inside a crate!
or dead!. 25ish overlays, all generated from scratch every second for every xeno/human/monkey and then applied.
More often than not update_clothing was being called a few times in addition to that! CPU was not the only issue,
all those icons had to be sent to every client. So really the cost was extremely cumulative. To the point where
update_clothing would frequently appear in the top 10 most CPU intensive procs during profiling.

Another feature of this new system is that our lists are indexed. This means we can update specific overlays!
So we only regenerate icons when we need them to be updated! This is the main saving for this system.

In practice this means that:
	everytime you fall over, we just switch between precompiled lists. Which is fast and cheap.
	Everytime you do something minor like take a pen out of your pocket, we only update the in-hand overlay
	etc...


There are several things that need to be remembered:

>	Whenever we do something that should cause an overlay to update (which doesn't use standard procs
	( i.e. you do something like l_hand = /obj/item/something new(src) )
	You will need to call the update_equipment_overlay() proc with the approriate slot flag ie.
		update_equipment_overlay(slot_wear_suit_str)

>	There are also these special cases:
		update_mutations()	//handles updating your appearance for certain mutations.  e.g TK head-glows
		UpdateDamageIcon()	//handles damage overlays for brute/burn damage //(will rename this when I geta round to it)
		update_body()	//Handles updating your mob's icon to reflect their gender/race/complexion etc
		update_hair()	//Handles updating your hair overlay (used to be update_face, but mouth and
																			...eyes were merged into update_body)
		update_targeted() // Updates the target overlay when someone points a gun at you

>	All of these procs update our overlay lists, and then call update_icon() by default.
	If you wish to update several overlays at once, you can set the argument to 0 to disable the update and call
	it manually:
		e.g.
		update_equipment_overlay(slot_head_str, FALSE)
		update_inhand_overlays()		//<---calls update_icon()

	or equivillantly:
		update_equipment_overlay(slot_head_str, FALSE)
		update_inhand_overlays(FALSE)
		update_icon()

>	If you need to update all overlays you can use try_refresh_visible_overlays(). it works exactly like update_clothing used to.

>	I reimplimented an old unused variable which was in the code called (coincidentally) var/update_icon
	It can be used as another method of triggering update_icon(). It's basically a flag that when set to non-zero
	will call update_icon() at the next life() call and then reset itself to 0.
	The idea behind it is icons are regenerated only once, even if multiple events requested it.

This system is confusing and is still a WIP. It's primary goal is speeding up the controls of the game whilst
reducing processing costs. So please bear with me while I iron out the kinks. It will be worth it, I promise.
If I can eventually free var/lying stuff from the life() process altogether, stuns/death/status stuff
will become less affected by lag-spikes and will be instantaneous! :3

If you have any questions/constructive-comments/bugs-to-report/or have a massivly devestated butt...
Please contact me on #coderbus IRC. ~Carn x
*/

/mob/living/carbon/human
	var/previous_damage_appearance // store what the body last looked like, so we only have to update it if something changed

/mob/living/carbon/human/refresh_visible_overlays()
	update_mutations(FALSE)
	update_body(FALSE)
	update_skin(FALSE)
	update_underwear(FALSE)
	update_hair(FALSE)
	update_inhand_overlays(FALSE)
	update_fire(FALSE)
	update_surgery(FALSE)
	update_bandages(FALSE)
	UpdateDamageIcon(FALSE)
	return ..()

/mob/living/carbon/human/on_update_icon()
	if(regenerate_body_icon)
		regenerate_body_icon = FALSE
	..()

/mob/living/carbon/human/apply_visible_overlays()
	var/list/visible_overlays
	var/list/visible_underlays
	if(is_cloaked())
		icon = 'icons/mob/human.dmi'
		icon_state = "blank"
		visible_overlays = get_current_mob_overlay(HO_INHAND_LAYER)
	else
		icon = stand_icon
		icon_state = null
		visible_overlays = 	get_all_current_mob_overlays()
		visible_underlays = get_all_current_mob_underlays()

	var/decl/bodytype/root_bodytype = get_bodytype()
	var/matrix/M = matrix()
	if(lying && (root_bodytype.prone_overlay_offset[1] || root_bodytype.prone_overlay_offset[2]))
		M.Translate(root_bodytype.prone_overlay_offset[1], root_bodytype.prone_overlay_offset[2])

	for(var/i = 1 to LAZYLEN(visible_overlays))
		var/entry = visible_overlays[i]
		if(istype(entry, /image))
			var/image/overlay = entry
			if(i != HO_DAMAGE_LAYER)
				overlay.transform = M
			add_overlay(entry)
		else if(islist(entry))
			for(var/image/overlay in entry)
				if(i != HO_DAMAGE_LAYER)
					overlay.transform = M
				add_overlay(overlay)

	for(var/i = 1 to LAZYLEN(visible_underlays))
		var/entry = visible_underlays[i]
		if(istype(entry, /image))
			var/image/underlay = entry
			underlay.transform = M
		else if(islist(entry))
			for(var/image/underlay in entry)
				underlay.transform = M
	underlays = visible_underlays

	var/obj/item/organ/external/head/head = get_organ(BP_HEAD, /obj/item/organ/external/head)
	if(head)
		var/image/I = head.get_eye_overlay()
		if(I)
			add_overlay(I)

/mob/living/carbon/human/proc/get_icon_scale_mult()
	// If you want stuff like scaling based on species or something, here is a good spot to mix the numbers together.
	return list(icon_scale_x, icon_scale_y)

/mob/living/carbon/human/update_transform()

	// First, get the correct size.
	var/list/icon_scale_values = get_icon_scale_mult()
	var/desired_scale_x = icon_scale_values[1]
	var/desired_scale_y = icon_scale_values[2]

	// Apply KEEP_TOGETHER so all the component overlays move properly when
	// applying a transform, or remove it if we aren't doing any transforms
	// (due to cost).
	if(!lying && desired_scale_x == 1 && desired_scale_y == 1)
		appearance_flags &= ~KEEP_TOGETHER
	else
		appearance_flags |= KEEP_TOGETHER

	// Scale/translate/rotate and apply the transform.
	var/matrix/M = matrix()
	if(lying)
		var/turn_angle
		if(dir & WEST)
			turn_angle = -90
		else if(dir & EAST)
			turn_angle = 90
		else
			turn_angle = pick(-90, 90)
		M.Turn(turn_angle)
		M.Scale(desired_scale_y, desired_scale_x)
		M.Translate(turn_angle == 90 ? 1 : -2, (turn_angle == 90 ? -6 : -5) - default_pixel_z)
	else
		M.Scale(desired_scale_x, desired_scale_y)
		M.Translate(0, 16 * (desired_scale_y - 1))

	if(transform_animate_time)
		animate(src, transform = M, time = transform_animate_time)
	else
		transform = M

	return transform

var/global/list/damage_icon_parts = list()

//DAMAGE OVERLAYS
//constructs damage icon for each organ from mask * damage field and saves it in our overlays_ lists
/mob/living/carbon/human/UpdateDamageIcon(var/update_icons=1)

	// first check whether something actually changed about damage appearance
	var/damage_appearance = ""
	for(var/obj/item/organ/external/O in get_external_organs())
		damage_appearance += O.damage_state

	if(damage_appearance == previous_damage_appearance)
		// nothing to do here
		return

	previous_damage_appearance = damage_appearance
	var/decl/bodytype/root_bodytype = get_bodytype()
	var/image/standing_image = image(root_bodytype.get_damage_overlays(src), icon_state = "00")

	// blend the individual damage states with our icons
	for(var/obj/item/organ/external/O in get_external_organs())
		O.update_damstate()
		O.update_icon()
		if(O.damage_state == "00")
			continue
		var/icon/DI
		var/use_colour = (BP_IS_PROSTHETIC(O) ? SYNTH_BLOOD_COLOR : O.species.get_blood_color(src))
		var/cache_index = "[O.damage_state]/[O.bodytype.type]/[O.icon_state]/[use_colour]/[species.name]"
		if(damage_icon_parts[cache_index] == null)
			DI = new /icon(O.bodytype.get_damage_overlays(src), O.damage_state) // the damage icon for whole human
			DI.Blend(get_limb_mask_for(O.bodytype, O.icon_state), ICON_MULTIPLY)  // mask with this organ's pixels
			DI.Blend(use_colour, ICON_MULTIPLY)
			damage_icon_parts[cache_index] = DI
		else
			DI = damage_icon_parts[cache_index]

		standing_image.overlays += DI

	update_bandages(update_icons)
	set_current_mob_overlay(HO_DAMAGE_LAYER, standing_image, update_icons)

/mob/living/carbon/human/proc/update_bandages(var/update_icons=1)
	var/list/bandage_overlays
	var/bandage_icon = get_bodytype().get_bandages_icon(src)
	if(bandage_icon)
		for(var/obj/item/organ/external/O in get_external_organs())
			var/bandage_level = O.bandage_level()
			if(bandage_level)
				LAZYADD(bandage_overlays, image(bandage_icon, "[O.icon_state][bandage_level]"))
	set_current_mob_overlay(HO_DAMAGE_LAYER, bandage_overlays, update_icons)

//BASE MOB SPRITE
/mob/living/carbon/human/update_body(var/update_icons=1)

	var/list/limbs = get_external_organs()
	if(!LAZYLEN(limbs))
		return // Something is trying to update our body pre-init (probably loading a preview image during world startup).

	var/husk_color_mod = rgb(96,88,80)
	var/husk = is_husked()

	//CACHING: Generate an index key from visible bodyparts.
	//0 = destroyed, 1 = normal, 2 = robotic, 3 = necrotic.

	//Create a new, blank icon for our mob to use.
	if(stand_icon)
		qdel(stand_icon)
	var/decl/bodytype/root_bodytype = get_bodytype()
	stand_icon = new(root_bodytype.icon_template || 'icons/mob/human.dmi',"blank")

	var/icon_key = "[root_bodytype.get_icon_cache_uid(src)][skin_tone][skin_colour]"
	if(lip_style)
		icon_key += "[lip_style]"
	else
		icon_key += "nolips"
	var/obj/item/organ/internal/eyes/eyes = get_organ((root_bodytype.vision_organ || BP_EYES), /obj/item/organ/internal/eyes)
	icon_key += istype(eyes) ? eyes.eye_colour : COLOR_BLACK

	for(var/limb_tag in global.all_limb_tags)
		var/obj/item/organ/external/part = GET_EXTERNAL_ORGAN(src, limb_tag)
		if(isnull(part) || part.skip_body_icon_draw)
			icon_key += "0"
			continue
		for(var/M in part.markings)
			icon_key += "[M][part.markings[M]]"
		if(part)
			icon_key += "[part.bodytype.get_icon_cache_uid(part.owner)][part.render_alpha]"
			icon_key += "[part.skin_tone]"
			if(part.skin_colour)
				icon_key += "[part.skin_colour]"
				icon_key += "[part.skin_blend]"
			for(var/M in part.markings)
				icon_key += "[M][part.markings[M]]"
		if(!BP_IS_PROSTHETIC(part) && (part.status & ORGAN_DEAD))
			icon_key += "2"
		else
			icon_key += "1"

	icon_key = "[icon_key][husk ? 1 : 0]"

	var/icon/base_icon
	if(human_icon_cache[icon_key])
		base_icon = human_icon_cache[icon_key]
	else
		//BEGIN CACHED ICON GENERATION.
		base_icon = icon(root_bodytype.icon_template)
		for(var/obj/item/organ/external/part in limbs)
			var/icon/temp = part.get_icon()
			//That part makes left and right legs drawn topmost and lowermost when human looks WEST or EAST
			//And no change in rendering for other parts (they icon_position is 0, so goes to 'else' part)
			if(part.icon_position & (LEFT | RIGHT))
				var/icon/temp2 = icon(root_bodytype.icon_template)
				temp2.Insert(new /icon(temp,dir=NORTH),dir=NORTH)
				temp2.Insert(new /icon(temp,dir=SOUTH),dir=SOUTH)
				if(!(part.icon_position & LEFT))
					temp2.Insert(new /icon(temp,dir=EAST),dir=EAST)
				if(!(part.icon_position & RIGHT))
					temp2.Insert(new /icon(temp,dir=WEST),dir=WEST)
				base_icon.Blend(temp2, ICON_OVERLAY)
				if(part.icon_position & LEFT)
					temp2.Insert(new /icon(temp,dir=EAST),dir=EAST)
				if(part.icon_position & RIGHT)
					temp2.Insert(new /icon(temp,dir=WEST),dir=WEST)
				base_icon.Blend(temp2, ICON_UNDERLAY)
			else if(part.icon_position & UNDER)
				base_icon.Blend(temp, ICON_UNDERLAY)
			else
				base_icon.Blend(temp, ICON_OVERLAY)

		if(husk)
			base_icon.ColorTone(husk_color_mod)

		//Handle husk overlay.
		if(husk)
			var/husk_icon = root_bodytype.get_husk_icon(src)
			if(husk_icon)
				var/icon/mask = new(base_icon)
				var/icon/husk_over = new(husk_icon, "")
				mask.MapColors(0,0,0,1, 0,0,0,1, 0,0,0,1, 0,0,0,1, 0,0,0,0)
				husk_over.Blend(mask, ICON_ADD)
				base_icon.Blend(husk_over, ICON_OVERLAY)

		human_icon_cache[icon_key] = base_icon

	//END CACHED ICON GENERATION.
	stand_icon.Blend(base_icon,ICON_OVERLAY)

	//tail
	update_tail_showing(0)
	..()

//UNDERWEAR OVERLAY

/mob/living/carbon/human/proc/update_underwear(var/update_icons=1)
	var/list/undies = list()
	for(var/entry in worn_underwear)
		var/obj/item/underwear/UW = entry
		if (!UW || !UW.icon) // Avoid runtimes for nude underwear types
			continue
		var/image/I
		var/decl/bodytype/root_bodytype = get_bodytype()
		if(UW.slot_offset_str && LAZYACCESS(root_bodytype.equip_adjust, UW.slot_offset_str))
			I = root_bodytype.get_offset_overlay_image(UW.icon, UW.icon_state, UW.color, UW.slot_offset_str)
		else
			I = image(icon = UW.icon, icon_state = UW.icon_state)
			I.color = UW.color
		I.appearance_flags |= RESET_COLOR
		undies += I
	set_current_mob_overlay(HO_UNDERWEAR_LAYER, undies, update_icons)

/mob/living/carbon/human/update_hair(var/update_icons=1)
	var/obj/item/organ/external/head/head_organ = get_organ(BP_HEAD, /obj/item/organ/external/head)

	set_current_mob_overlay(HO_HAIR_LAYER, (istype(head_organ) ? head_organ.get_hair_icon() : null), update_icons)
/mob/living/carbon/human/proc/update_skin(var/update_icons=1)
	// todo: make this use bodytype
	set_current_mob_overlay(HO_SKIN_LAYER, species.update_skin(src), update_icons)

/mob/living/carbon/human/update_mutations(var/update_icons=1)

	var/image/standing	= overlay_image('icons/effects/genetics.dmi', flags=RESET_COLOR)
	var/add_image = 0
	var/g = "m"
	if(gender == FEMALE)	g = "f"
	// DNA2 - Drawing underlays.
	var/list/all_genes = decls_repository.get_decls_of_subtype(/decl/gene)
	for(var/gene_type in all_genes)
		var/decl/gene/gene = all_genes[gene_type]
		if(!gene.block)
			continue
		if(gene.is_active(src))
			var/underlay=gene.OnDrawUnderlays(src,g)
			if(underlay)
				standing.underlays += underlay
				add_image = 1
	set_current_mob_overlay(HO_MUTATIONS_LAYER, (add_image ? standing : null), update_icons)

/* --------------------------------------- */
//vvvvvv UPDATE_INV PROCS vvvvvv
/mob/living/proc/update_tail_showing(var/update_icons=1)
	return

/mob/living/carbon/human/update_tail_showing(var/update_icons=1)

	var/obj/item/organ/external/tail/tail_organ = get_organ(BP_TAIL, /obj/item/organ/external/tail)
	if(!istype(tail_organ))
		set_current_mob_overlay(HO_TAIL_LAYER, null, FALSE)
		set_current_mob_underlay(HU_TAIL_LAYER, null, update_icons)
		return

	var/tail_state = tail_organ.get_tail(tail_organ)
	if(!tail_state)
		set_current_mob_overlay(HO_TAIL_LAYER, null, FALSE)
		set_current_mob_underlay(HU_TAIL_LAYER, null, update_icons)
		return

	var/obj/item/suit = get_equipped_item(slot_wear_suit_str)
	if(suit && (suit.flags_inv & HIDETAIL))
		set_current_mob_overlay(HO_TAIL_LAYER, null, FALSE)
		set_current_mob_underlay(HU_TAIL_LAYER, null, update_icons)

	var/icon/tail_s = get_tail_icon(tail_organ)
	var/tail_image = image(tail_s, icon_state = "[tail_state]_s")
	animate_tail_reset(0)
	if(dir == NORTH)
		set_current_mob_underlay(HU_TAIL_LAYER, null, FALSE)
		set_current_mob_overlay(HO_TAIL_LAYER, tail_image, update_icons)
	else
		set_current_mob_overlay(HO_TAIL_LAYER, null, FALSE)
		set_current_mob_underlay(HU_TAIL_LAYER, tail_image, update_icons)

/mob/living/carbon/human/proc/get_tail_icon(var/obj/item/organ/external/tail/tail_organ)
	if(!istype(tail_organ))
		return
	var/icon_key = "[tail_organ.get_tail()]\ref[tail_organ.icon][tail_organ.get_tail_blend(src)][tail_organ.bodytype.appearance_flags & HAS_SKIN_COLOR][skin_colour][tail_organ.get_tail_hair()][tail_organ.get_tail_hair_blend()][hair_colour]"
	var/icon/tail_icon = tail_icon_cache[icon_key]
	if(!tail_icon)
		//generate a new one
		var/tail_anim = tail_organ.get_tail_animation() || tail_organ.get_tail_icon()
		tail_icon = new/icon(tail_anim)
		if(tail_organ.bodytype.appearance_flags & HAS_SKIN_COLOR)
			tail_icon.Blend(skin_colour, tail_organ.get_tail_blend(src))
		// The following will not work with animated tails.
		var/use_tail = tail_organ.get_tail_hair()
		if(use_tail)
			var/icon/hair_icon = icon(tail_organ.get_tail_icon(src), "[tail_organ.get_tail()]_[use_tail]")
			hair_icon.Blend(hair_colour, tail_organ.get_tail_hair_blend())
			tail_icon.Blend(hair_icon, ICON_OVERLAY)
		tail_icon_cache[icon_key] = tail_icon

	return tail_icon

/mob/living/set_dir()
	. = ..()
	if(.)
		var/obj/item/organ/external/tail/tail_organ = get_organ(BP_TAIL, /obj/item/organ/external/tail)
		if(tail_organ?.get_tail())
			update_tail_showing()

/mob/living/carbon/human/proc/set_tail_state(var/t_state)
	var/image/tail_overlay = get_current_tail_image()
	var/obj/item/organ/external/tail/tail_organ = get_organ(BP_TAIL, /obj/item/organ/external/tail)
	if(!tail_organ)
		return null

	if(tail_overlay && tail_organ.get_tail_animation())
		tail_overlay.icon_state = t_state
		return tail_overlay

//Not really once, since BYOND can't do that.
//Update this if the ability to flick() images or make looping animation start at the first frame is ever added.
/mob/living/carbon/human/proc/get_current_tail_image()
	return get_current_mob_overlay(HO_TAIL_LAYER) || get_current_mob_underlay(HU_TAIL_LAYER)

/mob/living/carbon/human/proc/animate_tail_once(var/update_icons=1)
	var/obj/item/organ/external/tail/tail_organ = get_organ(BP_TAIL, /obj/item/organ/external/tail)
	if(!tail_organ)
		return
	var/t_state = "[tail_organ.get_tail()]_once"

	var/image/tail_overlay = get_current_tail_image()
	if(tail_overlay && tail_overlay.icon_state == t_state)
		return //let the existing animation finish

	tail_overlay = set_tail_state(t_state)
	if(tail_overlay)
		spawn(20)
			//check that the animation hasn't changed in the meantime
			var/current_tail = get_current_tail_image()
			if(current_tail == tail_overlay && tail_overlay.icon_state == t_state)
				animate_tail_stop()

	if(update_icons)
		queue_icon_update()

/mob/living/carbon/human/proc/animate_tail_start(var/update_icons=1)
	var/obj/item/organ/external/tail/tail_organ = get_organ(BP_TAIL, /obj/item/organ/external/tail)
	if(!tail_organ)
		return
	var/tail_states = tail_organ.get_tail_states()
	if(tail_states)
		set_tail_state("[tail_organ.get_tail()]_slow[rand(1, tail_states)]")
		if(update_icons)
			queue_icon_update()

/mob/living/carbon/human/proc/animate_tail_fast(var/update_icons=1)
	var/obj/item/organ/external/tail/tail_organ = get_organ(BP_TAIL, /obj/item/organ/external/tail)
	if(!tail_organ)
		return
	var/tail_states = tail_organ.get_tail_states()
	if(tail_states)
		set_tail_state("[tail_organ.get_tail()]_loop[rand(1, tail_states)]")
		if(update_icons)
			queue_icon_update()

/mob/living/carbon/human/proc/animate_tail_reset(var/update_icons=1)
	var/obj/item/organ/external/tail/tail_organ = get_organ(BP_TAIL, /obj/item/organ/external/tail)
	if(!tail_organ)
		return
	var/tail_states = tail_organ.get_tail_states(src)
	if(stat != DEAD && tail_states)
		set_tail_state("[tail_organ.get_tail()]_idle[rand(1, tail_states)]")
	else
		set_tail_state("[tail_organ.get_tail()]_static")

	if(update_icons)
		queue_icon_update()

/mob/living/carbon/human/proc/animate_tail_stop(var/update_icons=1)
	var/obj/item/organ/external/tail/tail_organ = get_organ(BP_TAIL, /obj/item/organ/external/tail)
	if(!tail_organ)
		return
	set_tail_state("[tail_organ.get_tail()]_static")

/mob/living/carbon/human/update_fire(var/update_icons=1)
	if(on_fire)
		var/image/standing = overlay_image(get_bodytype().get_ignited_icon(src) || 'icons/mob/OnFire.dmi', "Standing", RESET_COLOR)
		set_current_mob_overlay(HO_FIRE_LAYER, standing, update_icons)
	else
		set_current_mob_overlay(HO_FIRE_LAYER, null, update_icons)

//Ported from hud login stuff
//
/mob/living/carbon/hud_reset(full_reset = FALSE)
	if(!(. = ..()))
		return .
	for(var/obj/item/gear in get_equipped_items(TRUE))
		client.screen |= gear
	if(hud_used)
		hud_used.hidden_inventory_update()
		hud_used.persistant_inventory_update()
		update_action_buttons()
	if(internals && internal)
		internals.icon_state = "internal1"
	queue_hand_rebuild()
