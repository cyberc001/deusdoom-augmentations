struct DD_Aug_AgilityEnhancement_Queue
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
	ui bool mov_keys_held[4];
	// amount of ticks passed since a key was pressed last time,
	// used to engage dash.
	// 0 - forward, 1 - backward, 2 - left, 3 - right, 4 - up
	ui int mov_keys_timer[5];

	int dash_cd;
	const vwheight_time = 20;
	const vwheight_time_coff = 0.30;

	bool use_doubletap_scheme; // keeps the value of dd_dash_on_doubletap CVAR between toggles
	int dash_tap_time; // also keeps a value of dd_dash_doubletap_timer CVAR
	bool dash_held;

	const wall_climb_range = 32;
	const wall_climb_keep_range = 70;
	bool climbing;
	bool prev_climbing;
	bool climb_move[4];

	const gap_squeeze_vel_thres = 1;

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
		disp_desc = disp_desc .. string.format("TECH THREE: Deceleration rate is %.3g%%.\n", getDecelerateFactor() * 100) .. "Agent takes less damage while dashing.\n\n";
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Deceleration rate is %.3g%%.\n", getDecelerateFactor() * 100) .. "Agent cannot collide with foes while dashing.\n\n";
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

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
		if(owner && owner.player){
			use_doubletap_scheme = CVar.getCVar("dd_dash_on_doubletap", owner.player).getFloat();
			dash_tap_time = CVar.getCVar("dd_dash_doubletap_timer", owner.player).getInt();
		}
	}

	// ------
	// Events
	// ------

	override double getSpeedFactor() { return climbing ? 0 : 1; }
	protected double getClimbingVelocity() { return 2 + 1 * (getRealLevel() - 2); }

	override void tick()
	{
		super.tick();
		if(!owner)
			return;

		// Wall climbing
		if(climbing != prev_climbing){
			console.printf(climbing ? "Now climbing" : "Stopped climbing");
			prev_climbing = climbing;
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

			if(!aim_tracer.hit_wall || !aim_tracer.hit_line)
				climbing = false;
			else{
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

			if(getRealLevel() > 3)
				owner.bTHRUACTORS = true;

			if(queue.vwheight_timer == 0){
				owner.player.viewHeight = queue.vwheight_prev;
				owner.bTHRUACTORS = false;
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
		for(uint i = 0; i < 5; ++i)
		{
			if(dash_cd == 0 && queue.dashvel[i].length() > 0){
				owner.A_ChangeVelocity(queue.dashvel[i].x, queue.dashvel[i].y, queue.dashvel[i].z, CVF_RELATIVE);
				dash_cd = getDashCD();
				if(queue.dashvel[i].z == 0 && queue.vwheight_timer == 0){
					queue.vwheight_prev = owner.player.viewHeight;
					queue.vwheight_timer = vwheight_time;
					queue.vwheight_delta = owner.player.viewHeight * 0.8;
				}
			}
			queue.dashvel[i] = (0, 0, 0);
		}
	}

	protected double getProtectionFactor()
	{
		return GetRealLevel() > 2 ? 0.3 : 0;
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

	override void UITick()
	{
		for(uint i = 0; i < 5; ++i)
			if(use_doubletap_scheme && mov_keys_timer[i] <= dash_tap_time)
				++mov_keys_timer[i];
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

			/* Deceleration */
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")) mov_keys_held[0] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+back")) mov_keys_held[1] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) mov_keys_held[2] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) mov_keys_held[3] = true;

			if(mov_keys_held[0] || mov_keys_held[1] || mov_keys_held[2] || mov_keys_held[3])
				EventHandler.sendNetworkEvent("dd_grip", 0);

			/* Dashing */
			if(use_doubletap_scheme)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
				{
					if(mov_keys_timer[0] <= dash_tap_time && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 0);
					mov_keys_timer[0] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
				{
					if(mov_keys_timer[1] <= dash_tap_time && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 1);
					mov_keys_timer[1] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
				{
					if(mov_keys_timer[2] <= dash_tap_time && enabled) 
						EventHandler.sendNetworkEvent("dd_vdash", 2);
					mov_keys_timer[2] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
				{
					if(mov_keys_timer[3] <= dash_tap_time && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 3);
					mov_keys_timer[3] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
				{
					if(mov_keys_timer[4] <= dash_tap_time && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 4);
					mov_keys_timer[4] = 0;
				}
			}
			else
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
					mov_keys_timer[0] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
					mov_keys_timer[1] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
					mov_keys_timer[2] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
					mov_keys_timer[3] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
					mov_keys_timer[4] = 1;

				else if(KeyBindUtils.checkBind(e.keyScan, "dd_dash")){
					if(mov_keys_timer[0] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 0);
					else if(mov_keys_timer[1] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 1);
					else if(mov_keys_timer[2] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 2);
					else if(mov_keys_timer[3] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 3);
					else if(mov_keys_timer[4] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 4);
				}
			}
		}
		else if(e.type == InputEvent.Type_KeyUp)
		{
			/* Deceleration */
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")) mov_keys_held[0] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+back")) mov_keys_held[1] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) mov_keys_held[2] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) mov_keys_held[3] = false;
			if(!mov_keys_held[0] && !mov_keys_held[1] && !mov_keys_held[2] && !mov_keys_held[3] && enabled)
					EventHandler.sendNetworkEvent("dd_grip", 1);

			/* Climbing */
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")) EventHandler.sendNetworkEvent("dd_climb", 6);
			if(KeyBindUtils.checkBind(e.keyScan, "+back")) EventHandler.sendNetworkEvent("dd_climb", 7);
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) EventHandler.sendNetworkEvent("dd_climb", 8);
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) EventHandler.sendNetworkEvent("dd_climb", 9);

			/* Dashing */
			if(!use_doubletap_scheme)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
					mov_keys_timer[0] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
					mov_keys_timer[1] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
					mov_keys_timer[2] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
					mov_keys_timer[3] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
					mov_keys_timer[4] = 0;
			}
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
