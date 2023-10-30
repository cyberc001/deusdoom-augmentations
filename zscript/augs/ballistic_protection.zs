CLASS DD_Aug_BallisticProtection : DD_Augmentation
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

		id = 1;
		disp_name = "Ballistic Protection";
		disp_desc = "Monomolecular plates reinforce the skin's epithelial\n"
			    "membrane, reducing the damage an agent recieves\n"
			    "from bullet-like projectiles and piercing melee attacks.\n\n";
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
		legend_names[0] = "Reflect every 2nd bullet";
		legend_names[1] = "Increase resistance when taking damage";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("BALPROT0");
		tex_on = TexMan.CheckForTexture("BALPROT1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getProtectionFactor()
	{
		return 0.2 + 0.13 * (getRealLevel() - 1) + bonus_res;
	}

	int reflect_cnt;
	double bonus_res;
	const bonus_res_inc = 0.05;
	const bonus_res_decay = 0.001;
	const max_bonus_res = 0.3;

	override void tick()
	{
		super.tick();
		bonus_res = max(bonus_res - bonus_res_decay, 0);
	}

	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;

		double protfact_ml;
		if(RecognitionUtils.damageIsBallistic(inflictor, source, damageType, flags, protfact_ml))
		{
			Name shld_cls = "DSMagicShield";
			for(Inventory i = owner.Inv; i != null; i = i.Inv)
				if(i is shld_cls)
					return;

			if(legend_installed == 0){
				if(++reflect_cnt == 2){
					reflect_cnt = 0;
					if(source || inflictor){
						vector3 tosrc;
						if(source)	tosrc = owner.Vec3To(source).unit();
						else		tosrc = owner.Vec3To(inflictor).unit();
						double angle;
						if(source)	angle = owner.AngleTo(source);
						else		angle = owner.AngleTo(inflictor);
						double pitch = -asin(tosrc.z);
						owner.LineAttack(angle, 4096, pitch, damage * 2, damageType, null);
					}
				}
				hud_info = string.format("REFL %d", reflect_cnt);
			}
			else if(legend_installed == 1)
				bonus_res = min(bonus_res + bonus_res_inc, max_bonus_res);

			newDamage = damage * (1 - getProtectionFactor() * protfact_ml);
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor()*100*protfact_ml);
			aughld.absorbtion_msg_timer = 35 * 2;
			aughld.doGFXResistance();
		}
	}
}
