/decl/hierarchy/outfit/job/ministation/engineer
	name = "Job - Station Engineer"
	belt = /obj/item/storage/belt/utility/full
	l_ear = /obj/item/radio/headset/headset_eng
	shoes = /obj/item/clothing/shoes/workboots
	pda_slot = slot_l_store_str
	outfit_flags = OUTFIT_HAS_BACKPACK | OUTFIT_EXTENDED_SURVIVAL | OUTFIT_HAS_VITALS_SENSOR
	head = /obj/item/clothing/head/hardhat
	uniform = /obj/item/clothing/under/engineer
	r_pocket = /obj/item/t_scanner
	id_type = /obj/item/card/id/ministation/engineering
	pda_type = /obj/item/modular_computer/pda/engineering

/decl/hierarchy/outfit/job/ministation/engineer/Initialize()
	. = ..()
	BACKPACK_OVERRIDE_ENGINEERING

/obj/item/card/id/ministation/engineering
	name = "identification card"
	desc = "A card issued to engineering staff."
	detail_color = COLOR_SUN