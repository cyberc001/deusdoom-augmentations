class DD_Aug_SpeedEnhancement : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	DD_Aug_AgilityEnhancement_Queue queue;
	ui bool mov_keys_held[4];

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 70; }

	override void install()
	{
		super.install();

		id = 4;
		disp_name = "Speed Enhancement";
		disp_desc = "Ionic polymeric gel myofibrils are woven into the leg\n"
			    "muscles increasing the speed at which an agent can\n"
			    "run and the height they can jump.\n\n";
		_level = 1;
		enabled = true;
		disp_desc = disp_desc .. string.format("TECH ONE: Speed increase is %g%%.\nJump height increase is %g%%.\nDeceleration rate is %.3g%%.\n\n", (getSpeedFactor() - 1) * 100, getJumpFactor() * 100, getDecelerateFactor() * 100);
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Speed increase is %g%%.\nJump height increase is %g%%.\nDeceleration rate is %.3g%%.\n\n", (getSpeedFactor() - 1) * 100, getJumpFactor() * 100, getDecelerateFactor() * 100);
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Speed increase is %g%%.\nJump height increase is %g%%.\nDeceleration rate is %.3g%%.\n\n", (getSpeedFactor() - 1) * 100, getJumpFactor() * 100, getDecelerateFactor() * 100);
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Speed increase is %g%%.\nJump height increase is %g%%.\nDeceleration rate is %.3g%%.\n\n", (getSpeedFactor() - 1) * 100, getJumpFactor() * 100, getDecelerateFactor() * 100);
		_level = 1;
		enabled = false;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		legend_count = 2;
		legend_names[0] = "almost instant deceleration";
		legend_names[1] = "slow down enemies around you";

		slots_cnt = 1;
		slots[0] = Legs;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("SPEED0");
		tex_on = TexMan.CheckForTexture("SPEED1");
	}

	override double getSpeedFactor()
	{
		if(enabled)
			return 1.20 + 0.20 * (getRealLevel() - 1);
		return 1.0;
	}
	protected double getJumpFactor() { return 0.4 + 0.4 * (getRealLevel() - 1); }
	clearscope double getDecelerateFactor() { return 0.25 + 0.2 * (getRealLevel() - 1) + (legend_installed == 0 ? 2 : 0); }

	const enemy_speed_mul = 0.7;
	const enemy_speed_radius = 160;
	array<Actor> affected_enemies;
	array<double> prev_speeds;

	const gfx_line_roff = 1;
	const gfx_line_step = 5;
	private void doSlowGFX()
	{
		// draw lines to slowed enemies
		for(uint i = 0; i < affected_enemies.size(); ++i){
			vector3 pt = owner.pos + (0, 0, 10);
			vector3 dir = affected_enemies[i].pos - pt;
			uint steps = dir.length() / gfx_line_step;
			if(dir.length() > 0) dir /= dir.length();
			dir *= gfx_line_step;
			pt -= owner.pos;
			for(uint j = 0; j < steps; ++j, pt += dir){
				owner.A_SpawnParticle(0x000000AA, flags: SPF_NOTIMEFREEZE, lifetime: 1, size: 5, xoff: pt.x + frandom(-gfx_line_roff, gfx_line_roff), yoff: pt.y + frandom(-gfx_line_roff, gfx_line_roff), zoff: pt.z + frandom(-gfx_line_roff, gfx_line_roff), velx: owner.vel.x, vely: owner.vel.y, velz: owner.vel.z, startalphaf: 0.5);
				owner.A_SpawnParticle(0x000070AA, flags: SPF_NOTIMEFREEZE, lifetime: 1, size: 5, xoff: pt.x + frandom(-gfx_line_roff, gfx_line_roff), yoff: pt.y + frandom(-gfx_line_roff, gfx_line_roff), zoff: pt.z + frandom(-gfx_line_roff, gfx_line_roff), velx: owner.vel.x, vely: owner.vel.y, velz: owner.vel.z, startalphaf: 0.5);
			}
		}	
	}

	override void tick()
	{
		super.tick();
		if(legend_installed == 1){
			for(uint i = 0; i < affected_enemies.size(); ++i){
				if(!affected_enemies[i]){
					affected_enemies.delete(i);
					prev_speeds.delete(i);
					--i; continue;
				}
			}
			for(uint i = 0; i < affected_enemies.size(); ++i){
				if(!enabled || owner.Distance3D(affected_enemies[i]) - affected_enemies[i].radius > enemy_speed_radius){
					affected_enemies[i].speed = prev_speeds[i];
					affected_enemies.delete(i);
					prev_speeds.delete(i);
					--i; continue;
				}
			}
		}

		if(!enabled)
			return;

		if(legend_installed == 1){
			let it = BlockThingsIterator.create(owner, enemy_speed_radius);
			while(it.next()){
				if(!it.thing.bISMONSTER || it.thing.bFRIENDLY || it.thing.health <= 0 || affected_enemies.find(it.thing) != affected_enemies.size())
					continue;
				affected_enemies.push(it.thing);
				prev_speeds.push(it.thing.speed);
				it.thing.speed *= enemy_speed_mul;
			}
			doSlowGFX();
		}

		if(abs(queue.deacc) > 0)
		{
			if(abs(owner.vel.x) > queue.deacc){
				if(owner.warp(owner, owner.vel.x, owner.vel.y, owner.vel.z, 0, WARPF_TESTONLY)){
					owner.A_ChangeVelocity((owner.vel.x > 0 ? -1 : 1)*queue.deacc, 0, 0);
					owner.warp(owner, -owner.vel.x, -owner.vel.y, -owner.vel.z, 0, WARPF_TESTONLY);
				}
			}
			else
				owner.A_ChangeVelocity(0, owner.vel.y, owner.vel.z, CVF_REPLACE);
			if(abs(owner.vel.y) > queue.deacc){
				if(owner.warp(owner, owner.vel.x, owner.vel.y, owner.vel.z, 0, WARPF_TESTONLY)){
					owner.A_ChangeVelocity(0, (owner.vel.y > 0 ? -1 : 1)*queue.deacc, 0);
					owner.warp(owner, -owner.vel.x, -owner.vel.y, -owner.vel.z, 0, WARPF_TESTONLY);
				}
			}
			else
				owner.A_ChangeVelocity(owner.vel.x, 0, owner.vel.z, CVF_REPLACE);
		}
	}

	double prevOwnerJumpZ;
	override void toggle()
	{
		super.toggle();
		if(!owner || !(owner is "PlayerPawn"))
			return;

		if(enabled){
			prevOwnerJumpZ = PlayerPawn(owner).jumpZ;
			PlayerPawn(owner).jumpZ *= 1.0 + getJumpFactor();
		}
		else{
			PlayerPawn(owner).jumpZ = prevOwnerJumpZ;
		}	
	}

	override bool inputProcess(InputEvent e)
	{
		if(e.type == InputEvent.Type_KeyDown)
		{
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")) mov_keys_held[0] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+back")) mov_keys_held[1] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) mov_keys_held[2] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) mov_keys_held[3] = true;

			if(mov_keys_held[0] || mov_keys_held[1] || mov_keys_held[2] || mov_keys_held[3])
				EventHandler.sendNetworkEvent("dd_grip", 0);
		}
		else if(e.type == InputEvent.Type_KeyUp)
		{
			if(KeyBindUtils.checkBind(e.keyScan, "+forward")) mov_keys_held[0] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+back")) mov_keys_held[1] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) mov_keys_held[2] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) mov_keys_held[3] = false;
			if(!mov_keys_held[0] && !mov_keys_held[1] && !mov_keys_held[2] && !mov_keys_held[3] && enabled)
				EventHandler.sendNetworkEvent("dd_grip", 1);
		}
		return false;
	}
}
