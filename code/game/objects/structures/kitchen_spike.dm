
//////Kitchen Spike

/obj/structure/kitchenspike_frame
	name = "meatspike frame"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "spikeframe"
	desc = "The frame of a meat spike."
	density = TRUE
	anchored = FALSE
	max_integrity = 200

/obj/structure/kitchenspike_frame/attackby(obj/item/I, mob/user, params)
	add_fingerprint(user)
	if(istype(I, /obj/item/wrench))
		if(anchored)
			to_chat(user, "<span class='notice'>You unwrench [src] from the floor.</span>")
			anchored = FALSE
		else
			to_chat(user, "<span class='notice'>You wrench [src] into place.</span>")
			anchored = TRUE
	else if(istype(I, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = I
		if(R.get_amount() >= 4)
			R.use(4)
			to_chat(user, "<span class='notice'>You add spikes to the frame.</span>")
			new /obj/structure/kitchenspike(loc)
			add_fingerprint(user)
			qdel(src)
		return
	else
		return ..()


/obj/structure/kitchenspike
	name = "meat spike"
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "spike"
	desc = "A spike for collecting meat from animals."
	density = TRUE
	anchored = TRUE
	buckle_lying = FALSE
	can_buckle = TRUE
	max_integrity = 250

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/structure/kitchenspike/attack_hand(mob/user)
	if(has_buckled_mobs())
		for(var/mob/living/L in buckled_mobs)
			user_unbuckle_mob(L, user)
	else
		..()

/obj/structure/kitchenspike/attackby(obj/item/grab/G, mob/user)
	if(istype(G, /obj/item/crowbar))
		if(!has_buckled_mobs())
			playsound(loc, G.usesound, 100, 1)
			if(do_after(user, 20 * G.toolspeed, target = src))
				to_chat(user, "<span class='notice'>You pry the spikes out of the frame.</span>")
				deconstruct(TRUE)
		else
			to_chat(user, "<span class='notice'>You can't do that while something's on the spike!</span>")
		return
	if(!istype(G, /obj/item/grab) || !G.affecting)
		return
	if(isliving(G.affecting))
		start_spike(G.affecting, user)
	return ..()

/obj/structure/kitchenspike/MouseDrop_T(mob/living/victim, mob/living/user)
	if(get_dist(user, src) > 1 || get_dist(user, victim) > 1 || isAI(user))
		return
	if(isanimal(user) && victim != user)
		return // animals cannot put mobs other than themselves onto spikes
	src.add_fingerprint(user)
	start_spike(victim, user)

/obj/structure/kitchenspike/proc/start_spike(mob/living/victim, mob/user)
	if(has_buckled_mobs())
		to_chat(user, "<span class = 'danger'>The spike already has something on it, finish collecting its meat first!</span>")
		return
	victim.visible_message(
		"<span class='danger'>[user] tries to slam [victim] onto the meat spike!</span>",
		"<span class='userdanger'>[user] tries to slam you onto the meat spike!</span>"
	)
	if(do_mob(user, src, 120))
		end_spike(victim, user)

/obj/structure/kitchenspike/proc/end_spike(mob/living/victim, mob/user)

	if(!istype(victim))
		return FALSE

	if(has_buckled_mobs()) //to prevent spam/queing up attacks
		return FALSE
	if(victim.buckled)
		return FALSE
	playsound(loc, 'sound/effects/splat.ogg', 25, 1)
	victim.forceMove(drop_location())
	victim.emote("scream")
	victim.visible_message(
		"<span class='danger'>[user] slams [victim] onto the meat spike!</span>",
		"<span class='userdanger'>[user] slams you onto the meat spike!</span>",
		"<span class='italics'>You hear a squishy wet noise.</span>"
	)
	if(ishuman(victim))
		var/mob/living/carbon/human/H = victim
		H.add_splatter_floor()
	victim.adjustBruteLoss(30)
	victim.setDir(2)
	buckle_mob(victim, force = TRUE)
	victim.set_lying_angle(180)
	victim.update_transform()
	victim.pixel_y = victim.get_standard_pixel_y_offset(180)
	return TRUE

/obj/structure/kitchenspike/user_buckle_mob(mob/living/M, mob/living/user)
	// This will never run because meatspikes have density = TRUE
	return

/obj/structure/kitchenspike/user_unbuckle_mob(mob/living/buckled_mob, mob/living/carbon/human/user)
	if(buckled_mob)
		var/mob/living/M = buckled_mob
		if(M != user)
			M.visible_message("<span class='notice'>[user] tries to pull [M] free of [src]!</span>",\
				"<span class='notice'>[user] is trying to pull you off [src], opening up fresh wounds!</span>",\
				"<span class='italics'>You hear a squishy wet noise.</span>")
			if(!do_after(user, 300, target = src))
				if(M && M.buckled)
					M.visible_message("<span class='notice'>[user] fails to free [M]!</span>",\
					"<span class='notice'>[user] fails to pull you off of [src].</span>")
				return

		else
			M.visible_message("<span class='warning'>[M] struggles to break free from [src]!</span>",\
			"<span class='notice'>You struggle to break free from [src], exacerbating your wounds! (Stay still for two minutes.)</span>",\
			"<span class='italics'>You hear a wet squishing noise..</span>")
			M.adjustBruteLoss(30)
			if(!do_after(M, 1200, target = src))
				if(M && M.buckled)
					to_chat(M, "<span class='warning'>You fail to free yourself!</span>")
				return
		if(!M.buckled)
			return
		release_mob(M)

/obj/structure/kitchenspike/proc/release_mob(mob/living/M)
	M.adjustBruteLoss(30)
	src.visible_message(text("<span class='danger'>[M] falls free of [src]!</span>"))
	unbuckle_mob(M, force = TRUE)
	M.emote("scream")
	M.AdjustWeakened(20 SECONDS)


/obj/structure/kitchenspike/post_unbuckle_mob(mob/living/M)
	M.pixel_y = M.get_standard_pixel_y_offset(0)
	M.set_lying_angle(0)
	M.update_transform()

/obj/structure/kitchenspike/Destroy()
	if(has_buckled_mobs())
		for(var/mob/living/L in buckled_mobs)
			release_mob(L)
	return ..()

/obj/structure/kitchenspike/deconstruct(disassembled = TRUE)
	if(disassembled)
		var/obj/F = new /obj/structure/kitchenspike_frame(loc)
		transfer_fingerprints_to(F)
	else
		new /obj/item/stack/sheet/metal(loc, 4)
	new /obj/item/stack/rods(loc, 4)
	qdel(src)
