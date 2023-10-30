STRUCt DD_Aug_AgilityEnhancement_Queue
{
	vector3 dashvel[5];
	double deacc;

	int vwheight_timer;
	double vwheight_prev;
	double vwheight_delta;
}
class DD_Aug_AgilityEnhancement : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	DD_Aug_AgilityEnhancement_Queue queue;
	ui bool mov_keys_held[5];
	// amount of ticks passed since a key was pressed last time,
	// used to engage dash.
	// 0 - forward, 1 - backward, 2 - left, 3 - right, 4 - up
	ui array<int> mov_keys_order;
	ui void movKeysOrderAdd(int key)
	{
		movKeysOrderRemove(key);
		mov_keys_order.push(key);
	}
	ui void movKeysOrderRemove(int key)
	{
		uint i = mov_keys_order.find(key);
		if(i != mov_keys_order.size())
			mov_keys_order.delete(i);
	}

	int dash_cd;
	const vwheight_time = 20;
	const vwheight_time_coff = 0.30;

	bool dash_held;

	const wall_climb_range = 32;
	const wall_climb_keep_range = 70;
	bool climbing;
	bool prev_climbing;
	bool climb_move[4];
	Line last_climb_wall;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 55; }

	override void install()
	{
		super.install();

		id = 18;
		disp_name = "Agility Enhancement";
		disp_desc = "The necessary muscle movements for quick and precise\n"
			    "body motions determined continuously with reactive\n"
			    "kinematics equations produced by embedded\n"
			    "nanocomputers, enhancing agent's ability to do\n"
			    "demanding body movements and improving\n"
			    "deceleration.\n\n";

		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Deceleration rate is %.2g%%.\n", getDecelerateFactor() * 100) .. "Agent can perform a dash, even in the air.\n\n";
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Deceleration rate is %.2g%%.\n", getDecelerateFactor() * 100) .. "Agent can climb flat walls (+use near a wall).\n\n";
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Deceleration rate is %.3g%%.\n", getDecelerateFactor() * 100) .. "Agent takes 30% less damage while dashing.\n\n";
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Deceleration rate is %.3g%%.\n", getDecelerateFactor() * 100) .. "Agent cannot collide with foes while dashing.\n\n";
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		legend_count = 3;
		legend_names[0] = "-90% damage taken while dashing";
		legend_names[1] = "dash in all held directions";
		legend_names[2] = "no need to look at a wall to keep climbing";

		slots_cnt = 1;
		slots[0] = Legs;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("SILENT0");
		tex_on = TexMan.CheckForTexture("SILENT1");
	}

	clearscope double getDecelerateFactor() { return 0.3 + 0.35 * (getRealLevel() - 1); }
	clearscope double getDashVel() { return 22 + 7 * (getRealLevel() - 1); }
	protected clearscope int getDashCD() { return 48 - 9 * (getRealLevel() - 1); }

	override void toggle()
	{
		super.toggle();
		climbing = false;
		owner.bTHRUACTORS = false;
	}

	override double getSpeedFactor() { return climbing ? 0 : 1; }
	protected double getClimbingVelocity() { return 2 + 1 * (getRealLevel() - 2); }
	array<Actor> noclip_monsters;

	override void tick()
	{
		super.tick();
		if(!owner)
			return;

		// Wall climbing
		if(climbing != prev_climbing){
			console.printf(climbing ? "Now climbing" : "Stopped climbing");
			prev_climbing = climbing;
			if(!climbing)
				last_climb_wall = null;
		}
		if(climbing){
			owner.A_ChangeVelocity(0, 0, -owner.vel.z);
			vector3 dir = (Actor.AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
			let aim_tracer = new("DD_AimTracer");
			aim_tracer.source = owner;
			aim_tracer.trace(owner.pos + (0, 0, owner.player.viewHeight), owner.curSector, dir, wall_climb_keep_range, 0);

			for(double height_mod = 0; (!aim_tracer.hit_wall || !aim_tracer.hit_line) && height_mod <= owner.player.viewHeight * 3 / 2 + 15; height_mod += owner.player.viewHeight / 2){
				aim_tracer = new("DD_AimTracer");
				aim_tracer.source = owner;
				aim_tracer.trace(owner.pos + (0, 0, owner.player.viewHeight - height_mod), owner.curSector, dir, wall_climb_keep_range, 0);
			}

			if(legend_installed == 2 && aim_tracer.hit_line)
				last_climb_wall = aim_tracer.hit_line;
			if((!aim_tracer.hit_wall || !aim_tracer.hit_line) && legend_installed == 2){
				aim_tracer.hit_line = last_climb_wall;
				aim_tracer.hit_wall = (last_climb_wall == null ? false : true);
			}

			if(!aim_tracer.hit_wall || !aim_tracer.hit_line)
				climbing = false;
			else{
				if(!aim_tracer.hit_line)
					aim_tracer.hit_line = last_climb_wall;

				if(climb_move[0]) owner.A_ChangeVelocity(0, 0, getClimbingVelocity());
				if(climb_move[1]) owner.A_ChangeVelocity(0, 0, -getClimbingVelocity());
				vector2 side_dir = aim_tracer.hit_line.delta;
				if(side_dir.length()) side_dir /= side_dir.length();
				side_dir *= getClimbingVelocity() * (aim_tracer.hit_front_side ? 1 : -1);

				double sign_corr = side_dir.x * owner.vel.x > 0 ? 1 : -1;
				if(side_dir.x > 0 && side_dir.x < owner.vel.x * sign_corr) side_dir.x = owner.vel.x;
				if(side_dir.x < 0 && side_dir.x > owner.vel.x * sign_corr) side_dir.x = owner.vel.x;

				sign_corr = side_dir.y * owner.vel.y > 0 ? 1 : -1;
				if(side_dir.y > 0 && side_dir.y < owner.vel.y * sign_corr) side_dir.y = owner.vel.y;
				if(side_dir.y < 0 && side_dir.y > owner.vel.y * sign_corr) side_dir.y = owner.vel.y;

				if(climb_move[2]) owner.A_ChangeVelocity(-side_dir.x, -side_dir.y, owner.vel.z, CVF_REPLACE);
				if(climb_move[3]) owner.A_ChangeVelocity(side_dir.x, side_dir.y, owner.vel.z, CVF_REPLACE);
				if(!climb_move[2] && !climb_move[3]) owner.A_ChangeVelocity(0, 0, owner.vel.z, CVF_REPLACE);
			}
		}

		// View height change handling
		if(queue.vwheight_timer > 0){
			--queue.vwheight_timer;

			if(queue.vwheight_timer > vwheight_time * vwheight_time_coff)
				owner.player.viewHeight -= queue.vwheight_delta / (vwheight_time * vwheight_time_coff);
			else
				owner.player.viewHeight += queue.vwheight_delta / (vwheight_time * (1 - vwheight_time_coff));

			if(getRealLevel() > 3){
				let it = BlockThingsIterator.create(owner, owner.vel.length() * 32);
				for(uint i = 0; i < noclip_monsters.size(); ++i)
					if(noclip_monsters[i].distance2D(owner) >= owner.vel.length() * 32)
					{ noclip_monsters[i].bTHRUACTORS = false; noclip_monsters.delete(i); --i; }
				while(it.next()){
					if(it.thing.bISMONSTER && noclip_monsters.find(it.thing) == noclip_monsters.size()){
						it.thing.bTHRUACTORS = true;
						noclip_monsters.push(it.thing);
					}
				}
			}

			if(queue.vwheight_timer == 0){
				owner.player.viewHeight = queue.vwheight_prev;
				for(uint i = 0; i < noclip_monsters.size(); ++i)
					noclip_monsters[i].bTHRUACTORS = false;
				noclip_monsters.clear();
			}
		}
		if(!enabled)
			return;

		if(abs(queue.deacc) > 0)
		{
			if(abs(owner.vel.x) > queue.deacc){
				if(owner.warp(owner, owner.vel.x, owner.vel.y, owner.vel.z, 0, WARPF_TESTONLY) || climbing){
					owner.A_ChangeVelocity((owner.vel.x > 0 ? -1 : 1)*queue.deacc, 0, 0);
					owner.warp(owner, -owner.vel.x, -owner.vel.y, -owner.vel.z, 0, WARPF_TESTONLY);
				}
			}
			else
				owner.A_ChangeVelocity(0, owner.vel.y, owner.vel.z, CVF_REPLACE);
			if(abs(owner.vel.y) > queue.deacc){
				if(owner.warp(owner, owner.vel.x, owner.vel.y, owner.vel.z, 0, WARPF_TESTONLY) || climbing){
					owner.A_ChangeVelocity(0, (owner.vel.y > 0 ? -1 : 1)*queue.deacc, 0);
					owner.warp(owner, -owner.vel.x, -owner.vel.y, -owner.vel.z, 0, WARPF_TESTONLY);
				}
			}
			else
				owner.A_ChangeVelocity(owner.vel.x, 0, owner.vel.z, CVF_REPLACE);
		}

		if(dash_cd > 0)
			--dash_cd;

		if(dash_cd == 0){
			for(uint i = 0; i < 5; ++i)
			{
				if(queue.dashvel[i].length() == 0)
					continue;
				owner.A_ChangeVelocity(queue.dashvel[i].x, queue.dashvel[i].y, queue.dashvel[i].z, CVF_RELATIVE);
				dash_cd = getDashCD();
				if(queue.dashvel[i].z == 0 && queue.vwheight_timer == 0){
					queue.vwheight_prev = owner.player.viewHeight;
					queue.vwheight_timer = vwheight_time;
					queue.vwheight_delta = owner.player.viewHeight * 0.8;
				}
			}
		}
		for(uint i = 0; i < 5; ++i)
			queue.dashvel[i] = (0, 0, 0);

	}

	protected double getProtectionFactor()
	{
		return legend_installed == 0 ? 0.9 : 0.3;
	}
	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;

		if(queue.vwheight_timer > 0 && getRealLevel() > 2)
		{
			newDamage = damage * (1 - getProtectionFactor());
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor() * 100);
			aughld.absorbtion_msg_timer = 35 * 1;
			aughld.doGFXResistance();
		}
	}

	override bool inputProcess(InputEvent e)
	{
		if(e.type == InputEvent.Type_KeyDown)
		{
			/* Climbing */
			if(KeyBindUtils.checkBind(e.keyScan, "+use") && getRealLevel() > 1){
				if(climbing)
					EventHandler.sendNetworkEvent("dd_climb", 0);
				else{
					vector3 dir = (Actor.AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
					let aim_tracer = new("DD_AimTracer");
					aim_tracer.source = owner;
					aim_tracer.trace(owner.pos + (0, 0, owner.player.viewHeight), owner.curSector, dir, wall_climb_range, 0);
					if(aim_tracer.hit_wall && aim_tracer.hit_line
						&& aim_tracer.hit_line.activation == 0)
						EventHandler.sendNetworkEvent("dd_climb", 1);
				}
			}

			if(climbing){
				if(KeyBindUtils.checkBind(e.keyScan, "+forward")) EventHandler.sendNetworkEvent("dd_climb", 2);
				if(KeyBindUtils.checkBind(e.keyScan, "+back")) EventHandler.sendNetworkEvent("dd_climb", 3);
				if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) EventHandler.sendNetworkEvent("dd_climb", 4);
				if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) EventHandler.sendNetworkEvent("dd_climb", 5);
			}

			/* Held movement keys */
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")){
				mov_keys_held[0] = true;
				movKeysOrderAdd(0);
			}
			if(KeyBindUtils.checkBind(e.keyScan, "+back")){
				mov_keys_held[1] = true;
				movKeysOrderAdd(1);
			}
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")){
				mov_keys_held[2] = true;
				movKeysOrderAdd(2);
			}
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")){
				mov_keys_held[3] = true;
				movKeysOrderAdd(3);
			}
			if(KeyBindUtils.checkBind(e.keyScan, "+jump")){
				mov_keys_held[4] = true;
				movKeysOrderAdd(4);
			}

			if(mov_keys_held[0] || mov_keys_held[1] || mov_keys_held[2] || mov_keys_held[3])
				EventHandler.sendNetworkEvent("dd_grip", 0);

			/* Dashing */
			if(KeyBindUtils.checkBind(e.keyScan, "dd_dash") && enabled
			&& (mov_keys_held[0] || mov_keys_held[1] || mov_keys_held[2] || mov_keys_held[3] || mov_keys_held[4])){
				for(int i = mov_keys_order.size() - 1; i >= 0; --i)
					if(mov_keys_held[mov_keys_order[i]]){
						EventHandler.sendNetworkEvent("dd_vdash", mov_keys_order[i]);
						IF(LEgend_installed != 1)
							break;
					}
			}
		}
		else if(e.type == InputEvent.Type_KeyUp)
		{
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")){
				mov_keys_held[0] = false;
				movKeysOrderRemove(0);
			}
			if(KeyBindUtils.checkBind(e.keyScan, "+back")){
				mov_keys_held[1] = false;
				movKeysOrderRemove(1);
			}
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")){
				mov_keys_held[2] = false;
				movKeysOrderRemove(2);
			}
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")){
				mov_keys_held[3] = false;
				movKeysOrderRemove(3);
			}
			if(KeyBindUtils.checkBind(e.keyScan, "+jump")){
				mov_keys_held[4] = false;
				movKeysOrderRemove(4);
			}

			if(!mov_keys_held[0] && !mov_keys_held[1] && !mov_keys_held[2] && !mov_keys_held[3] && enabled)
					EventHandler.sendNetworkEvent("dd_grip", 1);

			/* Climbing */
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")) EventHandler.sendNetworkEvent("dd_climb", 6);
			if(KeyBindUtils.checkBind(e.keyScan, "+back")) EventHandler.sendNetworkEvent("dd_climb", 7);
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) EventHandler.sendNetworkEvent("dd_climb", 8);
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) EventHandler.sendNetworkEvent("dd_climb", 9);
		}
		return false;
	}

	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(CVar_Utils.isHUDDebugEnabled()){
			UI_Draw.str(hndl.aug_overlay_font_bold,
					String.Format("Dash CD 1.23s", double(dash_cd) / 35),
					0xFFFFFFFF, 4, 12, -0.4, -0.4);
			return;
		}

		if(!enabled)
			return;

		if(dash_cd > 0)
			UI_Draw.str(hndl.aug_overlay_font_bold,
					String.Format("Dash CD %.2fs", double(dash_cd) / 35),
					0xFFFFFFFF, 4, 12, -0.4, -0.4);
	}
}
