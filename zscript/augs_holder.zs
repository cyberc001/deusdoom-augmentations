// Description:
// Internal structure designed as a workaround for ConsoleProcess event
// being unable to modify augmentation states etc.
struct DD_UIQueue{
	bool aug_toggle_queue[DD_AugsHolder.augs_slots];
	array<DD_Augmentation> aug_install_queue;
	array<int> aug_drop_queue;
};

// Description:
// Item class that holds information about all augmentations installed in a player.

class DD_AugsHolder : Inventory
{
	const augs_slots = 9;
	DD_Augmentation augs[augs_slots];

	const dropped_items_svel = 3.5;

	DD_UIQueue ui_queue;
	int aug_loop_snd_timer; // delay timer not to start the sound without waiting for activation sound

	array<DD_Augmentation> inv_augs;
	array<DD_Augmentation> inv_augs2;

	// For drawing augmentations
	ui TextureID aug_frame_top;
	ui TextureID aug_frame_mid;
	ui TextureID aug_frame_bottom;
	ui TextureID aug_frame_bg;

	ui TextureId bioel_bg;
	ui TextureId bioel_bg2;
	ui TextureId bioel_full_tex;
	ui TextureId bioel_high_tex;
	ui TextureId bioel_med_tex;
	ui TextureId bioel_low_tex;

	// For drawing damage directions and absorption amount
	ui TextureID dmg_dir_texs[5];
	int absorbtion_msg_timer;
	string absorbtion_msg;

	// For draining/gaining energy on certain attacks
	double energy_drainq;
	double energy_gainq;
	int energy_recirc;
	const energy_recirc_max = 100;

	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;
		Inventory.InterHubAmount 1;

		+Inventory.UNDROPPABLE;
		+Inventory.UNCLEARABLE;
		+Inventory.UNTOSSABLE;

		+DONTGIB; // at some maps there can be a door at around (0, 0, 0) coordinates where augs holder spawns so it crashes it, removing all augmentations.
			  // same goes for augmentation inventory items.
		+THRUACTORS;
	}

	override void BeginPlay()
	{
		absorbtion_msg = " ";

		aug_loop_snd_timer = 0;
		energy_drain_ml = 1.0;

		energy_drainq = 0.0;
		energy_gainq = 0.0;

		orig_speed = -1;
	}


	// -------------
	// Engine events
	// -------------

	ui void UIInit()
	{
		aug_frame_top = TexMan.checkForTexture("AUGUI21");
		aug_frame_mid = TexMan.checkForTexture("AUGUI22");
		aug_frame_bottom = TexMan.checkForTexture("AUGUI23");
		aug_frame_bg = TexMan.checkForTexture("AUGUI25");

		bioel_bg = TexMan.checkForTexture("AUGUI16");
		bioel_bg2 = TexMan.checkForTexture("AUGUI39");
		bioel_low_tex = TexMan.checkForTexture("AUGUI12");
		bioel_med_tex = TexMan.checkForTexture("AUGUI13");
		bioel_high_tex = TexMan.checkForTexture("AUGUI14");
		bioel_full_tex = TexMan.checkForTexture("AUGUI15");

		dmg_dir_texs[0] = TexMan.checkForTexture("AUGUI26");
		dmg_dir_texs[1] = TexMan.checkForTexture("AUGUI27");
		dmg_dir_texs[2] = TexMan.checkForTexture("AUGUI28");
		dmg_dir_texs[3] = TexMan.checkForTexture("AUGUI29");
		dmg_dir_texs[4] = TexMan.checkForTexture("AUGUI30");
	}

	// Lil' hacks for Power Recirculator and Synthetic Heart
	double energy_drain_ml;
	int level_boost; // 0 - no boost, 1 - boost up to level 4, 2 - boost to level 5 if legendary
	bool legendary_boost;

	// Monster-specific workarounds
	int orig_speed; // original speed to muliply by getSpeedFactor()

	override void tick()
	{
		if(!owner)
			return;
		super.tick();

		// Handling damage interface timers
		if(absorbtion_msg_timer > 0)
			--absorbtion_msg_timer;
		for(uint i = 0; i < 5; ++i)
			if(dmg_dir_timers[i] > 0)
				--dmg_dir_timers[i];

		bool one_aug_enabled = false;
		// Toggle queue
		for(uint i = 0; i < augs_slots; ++i)
		{
			if(augs[i] && ui_queue.aug_toggle_queue[i]){
				augs[i].toggle();
				ui_queue.aug_toggle_queue[i] = false;
			}
			if(augs[i] && augs[i].enabled){
				one_aug_enabled = true;
			}
		}
		// Installation queue
		while(ui_queue.aug_install_queue.size() > 0)
		{
			installAug(ui_queue.aug_install_queue[0]);
			ui_queue.aug_install_queue.delete(0);
		}
		DD_InventoryHolder hld = DD_InventoryHolder(owner.findInventory("DD_InventoryHolder"));
		// Dropping queue
		while(ui_queue.aug_drop_queue.size() > 0)
		{
			DD_AugmentationCanister todrop = DD_AugmentationCanister(Inventory.Spawn("DD_AugmentationCanister"));
			todrop.bTHRUACTORS = true;
			todrop.aug = inv_augs[ui_queue.aug_drop_queue[0]];
			todrop.aug2 = inv_augs2[ui_queue.aug_drop_queue[0]];

			todrop.warp(owner, 0.0, 0.0, owner.player.viewHeight, 0.0, WARPF_NOCHECKPOSITION);
			vector3 owner_look = (AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
			owner_look *= dropped_items_svel;
			todrop.A_ChangeVelocity(owner_look.x, owner_look.y, owner_look.z);

			inv_augs.delete(ui_queue.aug_drop_queue[0]);
			inv_augs2.delete(ui_queue.aug_drop_queue[0]);

			if(hld){
				DD_InventoryWrapper item = hld.findItem("DD_AugmentationCanister");
				--item.amount;
				if(item.amount <= 0)
					hld.removeItem(item);
			}
			
			ui_queue.aug_drop_queue.delete(0);
		}

		// 3512 is just this mod's own slot for this sound
		if(one_aug_enabled)
		{
			if(aug_loop_snd_timer == 0)
				aug_loop_snd_timer = 55;
			else{
				if(aug_loop_snd_timer - 1 == 0 && owner)
					owner.A_StartSound("play/aug/loop", 3512, CHANF_LOOPING, 0.2);
				aug_loop_snd_timer--;
			}
		}
		else
			owner.A_StopSound(3512);

		// handling speed factor for monsters, since getSpeedFactor() is not called for them
		if(orig_speed == -1)
			orig_speed = owner.speed;
		if(owner.bISMONSTER)
			owner.A_SetSpeed(orig_speed * getSpeedFactor());
	}

	// Inventory events
	override void modifyDamage(int damage, Name damageType, out int newDamage, bool passive,
					Actor inflictor, Actor source, int flags)
	{
		// Detecting damage directions
		if(passive){
			// Draining energy
			double eamt = RecognitionUtils.drainsEnergy(source, inflictor);
			if(eamt > 0)
			{
				energy_drainq += eamt;
				double energy_drainamt = floor(energy_drainq);
				energy_drainq -= energy_drainamt;
				owner.takeInventory("DD_BioelectricEnergy", energy_drainamt);
			}
			else if(eamt < 0)
			{
				energy_gainq += -eamt;
				double energy_gainamt = floor(energy_gainq);
				energy_gainq -= energy_gainamt;
				owner.giveInventory("DD_BioelectricEnergy", energy_gainamt);
			}
			
			// Setting damage direction timers
			if(source && owner)
			{
				double dmg_ang = deltaAngle(owner.angleTo(source), owner.angle);
				dmg_dir_timers[int((dmg_ang + 45) % 360 / 90)] = 70;
			}

			else if(inflictor && owner)
			{
				double dmg_ang = deltaAngle(owner.angleTo(inflictor), owner.angle);
				dmg_dir_timers[int((dmg_ang + 45) % 360 / 90)] = 70;
			}
			else if( (!source && !inflictor) || (inflictor == owner) )
			{
				dmg_dir_timers[4] = 35;
			}
		}

		// Invoking damage events
		if(passive){
			for(uint i = 0; i < augs.size(); ++i)
				if(augs[i])
					augs[i].ownerDamageTaken(damage, damageType, newDamage,
									inflictor, source, flags);
		}
		else{
			for(uint i = 0; i < augs.size(); ++i)
				if(augs[i])
					augs[i].ownerDamageDealt(damage, damageType, newDamage,
									inflictor, source, flags);
		}
	}

	override double getSpeedFactor()
	{
		double speed_ml = 1.0;
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i])
				speed_ml *= augs[i].getSpeedFactor();
		return speed_ml;
	}


	ui bool inputProcess(InputEvent e)
	{
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i])
				if(augs[i].inputProcess(e))
					return true;
		return false;
	}

	// ---------------------------------
	// Augmentation management functions
	// --------------------------------

	// Makes an attempt to install an augmentation of a certain type into an augmentation holder.
	// Return values:
	//	false - augmentation couldn't be installed.
	//		(there is already an augmentation in this slot or of this type)
	//	true  - successfull installation.
	bool installAug(DD_Augmentation aug_obj)
	{
		aug_obj.install();

		// Trying to find a vacant slot
		bool has_slot = false;
		uint in_slot;
		for(in_slot = 0; in_slot < aug_obj.slots_cnt; ++in_slot)
		{
			if(!augs[aug_obj.slots[in_slot]]){
				has_slot = true;
				break;
			}
			else if(augs[aug_obj.slots[in_slot]].id == aug_obj.id){
				// it's a duplicate
				return false;
			}
		}
		if(!has_slot) // out of slots
			return false;

		augs[aug_obj.slots[in_slot]] = aug_obj;
		aug_obj.owner = self.owner;

		// Deleting it from available for installation augmentations array
		uint aui;
		aui = inv_augs.find(aug_obj);
		if(aui == inv_augs.size()) aui = inv_augs2.find(aug_obj);
		if(aui != inv_augs.size()){
			inv_augs.delete(aui);
			inv_augs2.delete(aui);
		}

		DD_InventoryHolder hld = DD_InventoryHolder(owner.findInventory("DD_InventoryHolder"));
		if(hld){
			DD_InventoryWrapper item = hld.findItem("DD_AugmentationCanister");
			--item.amount;
			if(item.amount <= 0)
				hld.removeItem(item);
		}

		return true;
	}

	// Indicates whether the augmentation of this type can be installed or not.
	// Return values:
	//	false - augmentation can't be installed.
	//		(there is already an augmentation in this slot or of this type)
	//	true  - augmentation can be installed.
	clearscope bool canInstallAug(DD_Augmentation aug_obj)
	{
		// Trying to find a vacant slot
		bool has_slot = false;
		uint in_slot;
		for(in_slot = 0; in_slot < aug_obj.slots_cnt; ++in_slot)
		{
			if(!augs[aug_obj.slots[in_slot]]){
				has_slot = true;
				break;
			}
			else if(augs[aug_obj.slots[in_slot]].id == aug_obj.id){
				// it's a duplicate
				return false;
			}
		}
		if(!has_slot) // out of slots
			return false;
		return true;
	}
	play bool canInstallAugPlay(DD_Augmentation aug_obj)
	{
		// Trying to find a vacant slot
		bool has_slot = false;
		uint in_slot;
		for(in_slot = 0; in_slot < aug_obj.slots_cnt; ++in_slot)
		{
			if(!augs[aug_obj.slots[in_slot]]){
				has_slot = true;
				break;
			}
			else if(augs[aug_obj.slots[in_slot]].id == aug_obj.id){
				// it's a duplicate
				return false;
			}
		}
		if(!has_slot) // out of slots
			return false;
		return true;
	}


	// Queues installing an augemntation.
	clearscope void queueInstallAug(DD_Augmentation aug_obj)
	{
		ui_queue.aug_install_queue.push(aug_obj);
	}

	// Queues removing an augmentation from available augmentations (lost forever)
	clearscope void queueDropAug(int install_index)
	{
		ui_queue.aug_drop_queue.push(install_index);
	}

	// Queues toggling an augmentation in certain slot.
	// Trusts validity of the slot.
	clearscope void queueToggleAug(int slot)
	{
		ui_queue.aug_toggle_queue[slot] = true;
	}
	clearscope void queueEnableAllAugs()
	{
		for(uint i = 0; i < augs_slots; ++i)
		{
			if(augs[i] && augs[i].can_be_all_toggled && !augs[i].enabled)
				ui_queue.aug_toggle_queue[i] = true;
		}
	}
	clearscope void queueDisableAllAugs()
	{
		for(uint i = 0; i < augs_slots; ++i)
		{
			if(augs[i] && augs[i].can_be_all_toggled && augs[i].enabled)
				ui_queue.aug_toggle_queue[i] = true;
		}
	}

	// Adds spent energy to energy recirculation pool.
	// The pool always has the same capacity, but efficiency depends
	// on power recirculation level.
	play void addRecirculationEnergy(int amt)
	{
		energy_recirc += amt;
		if(energy_recirc > energy_recirc_max)
			energy_recirc = energy_recirc_max;
	}
	// Removes recirculated energy through recirculation pool.
	play int spendRecirculationEnergy(int amt)
	{
		if(amt >= energy_recirc)
			amt = energy_recirc;
		energy_recirc -= amt;
		return amt;
	}

	// ------------
	// UI functions
	// ------------

	ui void UITick()
	{
		for(uint i = 0; i < augs_slots; ++i)
			if(augs[i])
				augs[i].UITick();
		for(uint i = 0; i < inv_augs.size(); ++i){
			if(!inv_augs[i].ui_init)
				inv_augs[i].UIInit();
			if(!inv_augs2[i].ui_init)
				inv_augs2[i].UIInit();
		}
	}

	// Drawing damage absorbtion/directions interface
	int absorbmsg_timer;	// how long "XX% ABSORB" message stays on screen
	int dmg_dir_timers[5];	// timers for separate damage directions

	ui void draw(RenderEvent ev, DD_EventHandler hndl, double x, double y)
	{
		// Rendering bioelectric energy display
		int energy = owner.countInv("DD_BioelectricEnergy");
		double energy_perc = double(energy) / DD_BioelectricEnergy.max_energy;
		TextureID bioel_tex =	energy_perc >= 0.75 ? bioel_full_tex :
					energy_perc >= 0.50 ? bioel_high_tex :
					energy_perc >= 0.25 ? bioel_med_tex  :
							bioel_low_tex;

		vector2 bioel_off = (-4.5, 3.25) + CVar_Utils.getOffset("dd_bioelbar_off");
		double bioel_max_h = 20.0;

		UI_Draw.texture(bioel_bg, x + bioel_off.x, y + bioel_off.y,
					2 + 0.4, bioel_max_h + 0.4);
		UI_Draw.texture(bioel_bg2, x + bioel_off.x + 0.2, y + bioel_off.y + 0.2,
					2, bioel_max_h);
		if(energy_perc > 0.0){
			UI_Draw.texture(bioel_tex, x + bioel_off.x + 0.2,
						   y + bioel_off.y + 0.2 + bioel_max_h * (1.0 - energy_perc),
							2, bioel_max_h * energy_perc);
		}


		// Invoking rendering of augmentations
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i]){
				augs[i].drawOverlay(ev, hndl);
			if(!augs[i].ui_init)
					augs[i].UIInit();
		}

		// Rendering damage directions
		double absmsg_w = UI_Draw.strWidth(hndl.aug_overlay_font_bold, absorbtion_msg, -0.25, -0.25);
		double absmsg_h = UI_Draw.strHeight(hndl.aug_overlay_font_bold, absorbtion_msg, -0.25, -0.25);

		CVar disp_dmgind = CVar.getCVar("dd_dmgind_show", players[consoleplayer]);
		if(CVar_Utils.isHUDDebugEnabled())
		{
			vector2 off = CVar_Utils.getOffset("dd_dmgind_off");
			UI_Draw.texture(dmg_dir_texs[0],
						14 + off.x, 152 + off.y,
						-0.45, -0.45);
			UI_Draw.texture(dmg_dir_texs[1],
						30 + off.x, 162 + off.y,
						-0.45, -0.45);
			UI_Draw.texture(dmg_dir_texs[2],
						14 + off.x, 178 + off.y,
						-0.45, -0.45);
			UI_Draw.texture(dmg_dir_texs[3],
						4 + off.x, 162 + off.y,
						-0.45, -0.45);
			UI_Draw.texture(dmg_dir_texs[4],
						14.9 + off.x, 162.9 + off.y,
						-0.53, -0.53);

			UI_Draw.str(hndl.aug_overlay_font_bold, "ABSORB 100%",
					0xFFFFFFFF,
					35- UI_Draw.strWidth(hndl.aug_ui_font, "ABSORB 100%", -0.5, -0.5) + off.x,
					168 + off.y,
					-0.25, -0.25);
		}
		else if(!disp_dmgind || (disp_dmgind && disp_dmgind.getBool()) )
		{
			vector2 off = CVar_Utils.getOffset("dd_dmgind_off");
			if(dmg_dir_timers[0] > 0)
				UI_Draw.texture(dmg_dir_texs[0],
							14 + off.x, 152 + off.y,
							-0.45, -0.45);
			if(dmg_dir_timers[1] > 0)
				UI_Draw.texture(dmg_dir_texs[1],
							30 + off.x, 162 + off.y,
							-0.45, -0.45);
			if(dmg_dir_timers[2] > 0)
				UI_Draw.texture(dmg_dir_texs[2],
							14 + off.x, 178 + off.y,
							-0.45, -0.45);
			if(dmg_dir_timers[3] > 0)
				UI_Draw.texture(dmg_dir_texs[3],
							4 + off.x, 162 + off.y,
							-0.45, -0.45);
			if(dmg_dir_timers[4] > 0)
				UI_Draw.texture(dmg_dir_texs[4],
							14.9 + off.x, 162.9 + off.y,
							-0.53, -0.53);

			if(absorbtion_msg_timer > 0)
				UI_Draw.str(hndl.aug_ui_font, absorbtion_msg,
						0xFFFFFFFF,
						35- UI_Draw.strWidth(hndl.aug_overlay_font_bold, absorbtion_msg, -0.25, -0.25) + off.x,
						170 + off.y,
						-0.5, -0.5);
		}
		

		// Rendering augmentations frame
		vector2 aug_frame_off = CVar_Utils.getOffset("dd_augdisp_off");
		double aug_frame_scale = CVar_Utils.getScale("dd_augdisp_scale");
		x += aug_frame_off.x;
		y += aug_frame_off.y;

		double draw_x = x;
		double draw_y = y;
		double aug_sz_x = 16 * aug_frame_scale;
		double aug_sz_y = 16 * aug_frame_scale;
		double draw_dy = 2 * aug_frame_scale;

		uint aug_cnt = 0;
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i])
				aug_cnt++;

		// Drawing augmentations background frame
		draw_y = y + UI_Draw.texHeight(aug_frame_top, aug_sz_x * 0.5, 0);
		for(uint i = 0; i < augs.size(); ++i)
		{
			if(!augs[i]) // no augmentation in the slot
				continue;
			UI_Draw.texture(aug_frame_bg, draw_x+0.75, draw_y, aug_sz_x-1, aug_sz_y);
			
			draw_y += aug_sz_y + draw_dy;
		}

		// Drawing augmentations frame
		draw_y = y;
		UI_Draw.texture(aug_frame_top, draw_x - aug_sz_x * 0.44, draw_y, aug_sz_x * 1.621, 0);
		draw_y += UI_Draw.texHeight(aug_frame_top, aug_sz_x * 0.8, 0);
		if(aug_cnt > 0){
			UI_Draw.texture(aug_frame_mid, draw_x, draw_y, aug_sz_x, aug_sz_y * aug_cnt + draw_dy * (aug_cnt - 1) - aug_sz_y * 0.25);
		}

		draw_y = y + UI_Draw.texHeight(aug_frame_top, aug_sz_x * 0.8, 0) + aug_sz_y * aug_cnt + draw_dy * (aug_cnt - 1) + aug_sz_y * 0.2;
		if(aug_cnt > 0)
			UI_Draw.texture(aug_frame_bottom, draw_x - aug_sz_x * 0.44, draw_y - aug_sz_y * 1.0, aug_sz_x * 1.621, 0);
		else
			UI_Draw.texture(aug_frame_bottom, draw_x - aug_sz_x * 0.44, draw_y - 1, aug_sz_x * 1.621, 0);

		// Drawing augmentation icons
		draw_y = y + UI_Draw.texHeight(aug_frame_top, aug_sz_x * 0.5, 0);
		for(uint i = 0; i < augs.size(); ++i)
		{
			if(!augs[i]) // no augmentation in the slot
				continue;

			UI_Draw.texture(augs[i].get_ui_texture(augs[i].enabled),
						draw_x+0.75,
						draw_y + UI_Draw.texHeight(aug_frame_bg, aug_sz_x-1, aug_sz_y)/2
						       - UI_Draw.texHeight(augs[i].get_ui_texture(false),
										aug_sz_x-1, aug_sz_y)/2,
						aug_sz_x-1, aug_sz_y);

			// draw the bind
			int kb1, kb2;
			[kb1, kb2] = Bindings.getKeysForCommand(String.format("dd_togg_aug_%d", i));
			String bindstr = String.format("%s%s%s", KeyBindUtils.keyScanToName(kb1), KeyBindUtils.keyScanToName(kb2) == "" ? "" : "; ", KeyBindUtils.keyScanToName(kb2));
			UI_Draw.str(hndl.aug_overlay_font_bold, bindstr, Font.CR_LIGHTBLUE, draw_x + 2.2, draw_y + aug_sz_y - 5,
					-0.2 * aug_frame_scale, -0.25 * aug_frame_scale);
			
			draw_y += aug_sz_y + draw_dy;
		}
	}
	ui void drawUnderlay(RenderEvent ev, DD_EventHandler hndl)
	{
		for(uint i = 0; i < augs.size(); ++i)
			if(augs[i])
				augs[i].drawUnderlay(ev, hndl);
	}


	// --------------------------------
	// For resistance augmentations GFX
	// --------------------------------
	
	DD_ResistanceGFX gfx_resistance;
	void doGFXResistance()
	{
		if(!gfx_resistance){
			gfx_resistance = DD_ResistanceGFX(Spawn("DD_ResistanceGFX"));
			gfx_resistance.target = owner;
			gfx_resistance.tracer = self;
		}
		else
			gfx_resistance.gfx_resistance_timer = 0;
	}
}

class DD_ResistanceGFX : Actor
{
	default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+MASKROTATION
		+BRIGHT
		+NOTELEPORT

		VisibleAngles -180, 180;
		VisiblePitch -80, 110;

		XScale 0.85;
		YScale 0.23;
	}

	int gfx_resistance_timer;
	const gfx_resistance_time = 22;

	override void Tick()
	{
		super.tick();
		warp(target, 0, 0, 0, 0, WARPF_NOCHECKPOSITION);
		A_SetRenderStyle(1 - (double(gfx_resistance_timer) / gfx_resistance_time), STYLE_Translucent);

		if(gfx_resistance_timer < gfx_resistance_time)
			++gfx_resistance_timer;
		else{
			if(tracer && DD_AugsHolder(tracer)) DD_AugsHolder(tracer).gfx_resistance = null;
			destroy();
		}
	}

	states
	{
		Spawn:
			DDFX BCDEFGHI 2;
			Loop;
	}
}
