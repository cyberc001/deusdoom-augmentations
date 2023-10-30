CLASS DD_Aug_EnergyShield : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 70; }

	override void install()
	{
		super.install();

		id = 6;
		disp_name = "Energy Shield";
		disp_desc = "Polyanilene capacitors below the skin absorb heat and\n"
			    "electricity, reducing the damage received from flame,\n"
			    "electrical, and plasma attacks.\n\n";

		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Damage reduction is %g%%.\n\n", round(getProtectionFactor() * 100));
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Damage reduction is %g%%.\n\n", round(getProtectionFactor() * 100));
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Damage reduction is %g%%.\n\n", round(getProtectionFactor() * 100));
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Damage reduction is %g%%.\n\n", round(getProtectionFactor() * 100));
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		legend_count = 2;
		legend_names[0] = "absorbing damage creates flaming aura";
		legend_names[1] = "more resistance when not taking damage";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("ENGSHLD0");
		tex_on = TexMan.CheckForTexture("ENGSHLD1");
	}

	protected double getProtectionFactor()
	{
		return 0.20 + 0.12 * (getRealLevel() - 1) + bonus_res;
	}

	double aura_level;
	const aura_level_max = 100;
	const aura_deg = 0.04;
	const aura_deg_disabled = 0.15;
	const aura_level_min = 10;
	const aura_radius = 128;
	const aura_burn_dur = 5*15;
	const gfx_aura_roff = 0.02;

	void doAuraGFX()
	{
		double radius = 90;
		for(double pit = -80; pit < 80; pit += 30 / (1 + 2 * (aura_level / aura_level_max))){
			for(double ang = 0; ang < 360; ang += 30 / (1 + 2 * (aura_level / aura_level_max))){
				double acc = frandom(0.1, 0.3);
				vector3 off = (AngleToVector(ang, cos(pit)), -sin(pit));
				off.x += frandom(-gfx_aura_roff, gfx_aura_roff);
				off.y += frandom(-gfx_aura_roff, gfx_aura_roff);
				off.z += frandom(-gfx_aura_roff, gfx_aura_roff);
				owner.A_SpawnParticle(0x00FF0000 | ((int)(0xFF * (1 - aura_level / aura_level_max)) << 8), flags: SPF_NOTIMEFREEZE, lifetime: 15, size: 5, xoff: radius * off.x, yoff: radius * off.y, zoff: radius * off.z, velx: owner.vel.x, vely: owner.vel.y, velz: owner.vel.z, accelx: acc * off.x, accely: acc * off.y, accelz: acc * off.z, startalphaf: enabled ? 0.75 : 0.3, sizestep: 0.1);
			}
		}
	}

	double bonus_res;
	const bonus_res_max = 0.44;
	const bonus_res_inc = 0.003;
	const bonus_res_dec_instance = 0.02;
	const bonus_res_dec_damage = 0.001;

	override void tick()
	{
		super.tick();
		if(legend_installed == 0){
			hud_info = string.format("%.2g", aura_level);
			aura_level = max(0, aura_level - (enabled ? aura_deg : aura_deg_disabled));
		}
		else if(legend_installed == 1){
			hud_info = bonus_res > 0 ? string.format("+x%.2g", bonus_res) : "";
			if(enabled)
				bonus_res = min(bonus_res_max, bonus_res + bonus_res_inc);
		}

		if(aura_level >= aura_level_min){
			doAuraGFX();
			if(!enabled)
				return;
			let it = BlockThingsIterator.create(owner, owner.radius + aura_radius);
			while(it.next()){
				if(it.thing == owner || !owner.CheckSight(it.thing) || it.thing.bFRIENDLY || !it.thing.bISMONSTER || it.thing.health <= 0)
					continue;
				let existing_burn = DDPowerup_Burn(it.thing.FindInventory("DDPowerup_Burn"));
				if(existing_burn && aura_burn_dur - existing_burn.dur_timer > 15){
					it.thing.takeInventory("DDPowerup_Burn", 1);
					existing_burn.destroy();
					existing_burn = null;
				}
				if(!existing_burn){
					let burn = DDPowerup_Burn(Actor.Spawn("DDPowerup_Burn"));
					burn.dmg = aura_level / 2.;
					burn.dur_timer = aura_burn_dur;
					it.thing.addInventory(burn);
				}
			}
		}
	}

	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;

		double protfact_ml;
		if(RecognitionUtils.damageIsEnergy(inflictor, source, damageType, flags, protfact_ml))
		{
			Name shld_cls = "DSMagicShield";
			for(Inventory i = owner.Inv; i != null; i = i.Inv)
				if(i is shld_cls)
					return;

			newDamage = damage * (1 - getProtectionFactor() * protfact_ml);
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor() * 100 * protfact_ml);
			aughld.absorbtion_msg_timer = 35 * 2;
			aughld.doGFXResistance();

			if(legend_installed == 0)
				aura_level = min(aura_level_max, aura_level + damage * getProtectionFactor() * protfact_ml);
			else if(legend_installed == 1){
				bonus_res = max(0, bonus_res - bonus_res_dec_instance - bonus_res_dec_damage * damage);
			}
		}
	}
}
