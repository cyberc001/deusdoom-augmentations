class DD_Aug_GravitationalField : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;
	ui TextureID tex_alt;

	override TextureID get_ui_texture(bool state)
	{
		return !state ? tex_off : tex_on;
	}

	override int get_base_drain_rate(){ return 100; }

	override void install()
	{
		super.install();

		id = 2;
		disp_name = "Gravitational field";
		disp_desc = "Nanoscale gravity field generators work in a pattern\n"
			    "and constantly slow down incoming projectiles.\n\n";
		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Range %g, speed reduction %g%%.\n\n", getRange(), getSpeedReduction() * 100);
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Range %g, speed reduction %g%%.\n\n", getRange(), getSpeedReduction() * 100);
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Range %g, speed reduction %g%%.\n\n", getRange(), getSpeedReduction() * 100);
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Range %g, speed reduction %g%%.\n\n", getRange(), getSpeedReduction() * 100);
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("EMPSHLD0");
		tex_on = TexMan.CheckForTexture("EMPSHLD1");
	}

	// ------------------
	// Internal functions
	// ------------------
	
	protected double getSpeedReduction() { return 0.5 + 0.07 * (getRealLevel() - 1); }
	protected double getMinSpeed() { return 2 - 0.35 * (getRealLevel() - 1); }
	protected double getRange() { return 85 + 15 * (getRealLevel() - 1); }

	// -------------
	// Engine events
	// -------------

	array<Actor> affected_projectiles;
	array<double> prev_speeds;

	private vector3 rescaleVector(vector3 vec, double new_length)
	{
		vector3 norm = (vec.length() == 0) ? vec : vec / vec.length();
		return norm * new_length;
	}

	const gfx_sph_roff = 0.08;
	const gfx_line_roff = 1;
	const gfx_line_step = 5;
	private void doGFX()
	{
		double radius = getRange() - gfx_sph_roff * 100;
		for(double pit = -66; pit < 66; pit += 11){
			for(double ang = 0; ang < 360; ang += 12){
				vector3 off = (AngleToVector(ang, cos(pit)), -sin(pit));
				off.x += frandom(-gfx_sph_roff, gfx_sph_roff);
				off.y += frandom(-gfx_sph_roff, gfx_sph_roff);
				off.z += frandom(-gfx_sph_roff, gfx_sph_roff);
				owner.A_SpawnParticle(0x80808080, flags: SPF_NOTIMEFREEZE, lifetime: 5, size: 2, xoff: radius * off.x, yoff: radius * off.y, zoff: owner.height * 3./5 + radius * off.z, velx: owner.vel.x, vely: owner.vel.y, velz: owner.vel.z, startalphaf: 0.5);
			}
		}

		for(uint i = 0; i < affected_projectiles.size(); ++i){
			vector3 pt = owner.pos + (0, 0, owner.height * 3./5);
			vector3 dir = affected_projectiles[i].pos - pt;
			uint steps = dir.length() / gfx_line_step;
			if(dir.length() > 0) dir /= dir.length();
			dir *= gfx_line_step;
			pt -= owner.pos;
			for(uint j = 0; j < steps; ++j, pt += dir){
				owner.A_SpawnParticle(0x80808080, flags: SPF_NOTIMEFREEZE, lifetime: 1, size: 5, xoff: pt.x + frandom(-gfx_line_roff, gfx_line_roff), yoff: pt.y + frandom(-gfx_line_roff, gfx_line_roff), zoff: pt.z + frandom(-gfx_line_roff, gfx_line_roff), velx: owner.vel.x, vely: owner.vel.y, velz: owner.vel.z, startalphaf: 0.5);
			}
		}	
	}

	override void tick()
	{
		super.tick();
		for(uint i = 0; i < affected_projectiles.size(); ++i)
			if(!affected_projectiles[i]){
				affected_projectiles.delete(i);
				prev_speeds.delete(i);
				--i; continue;
			}
			
		for(uint i = 0; i < affected_projectiles.size(); ++i){
			if(!enabled || owner.Distance3D(affected_projectiles[i]) - affected_projectiles[i].radius > getRange()){
				vector3 new_vel = rescaleVector(affected_projectiles[i].vel, prev_speeds[i]);
				affected_projectiles[i].A_ChangeVelocity(new_vel.x, new_vel.y, new_vel.z, CVF_REPLACE);
				affected_projectiles.delete(i);
				prev_speeds.delete(i);
				--i; continue;
			}
		}

		if(!enabled || !owner)
			return;
		doGFX();

		let ddevh = DD_AugsEventHandler(StaticEventHandler.Find("DD_AugsEventHandler"));
		for(uint i = 0; i < ddevh.proj_list.size(); ++i)
		{
			Actor proj = ddevh.proj_list[i];
			if(!proj){
				ddevh.proj_list.delete(i); --i; continue;
			}
			if(proj.target == owner || owner.Distance3D(proj) - proj.radius > getRange() || affected_projectiles.find(proj) != affected_projectiles.size())
				continue;
			affected_projectiles.push(proj);
			prev_speeds.push(proj.vel.length());
			double _speed = proj.vel.length() * (1 - getSpeedReduction());

			if(_speed < getMinSpeed())
				_speed = getMinSpeed();
			vector3 new_vel = rescaleVector(proj.vel, _speed);
			proj.A_ChangeVelocity(new_vel.x, new_vel.y, new_vel.z, CVF_REPLACE);
		}
	}
}
