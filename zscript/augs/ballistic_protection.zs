class DD_Aug_BallisticProtection : DD_Augmentation
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
			    "from bullet-like projectiles and piercing melee attacks.\n\n"
			    "TECH ONE: Damage from projectiles and melee attacks\n"
			    "is reduced sligthly.\n\n"
			    "TECH TWO: Damage from projectiles and melee attacks\n"
			    "is reduced moderately.\n\n"
			    "TECH THREE: Damage from projectiles and melee\n"
			    "attacks is reduced significantly.\n\n"
			    "TECH FOUR: An agent is nearly invulnurable to damage\n"
			    "from projectiles and melee attacks.\n\n"
			    "Energy Rate: 70 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Some ballistic attacks\n"
				   "directed at agent are redirected towards their origin.\n"
				   "Statistically this effect triggers on 1 from 3 such\n"
				   "attacks.";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;

		can_be_legendary = true;
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
		double lgnd_off = isLegendary() ? 0.07 : 0;
		if(getRealLevel() <= max_level)
			return 0.20 + 0.166 * (getRealLevel() - 1) + lgnd_off;
		else
			return 0.20 + 0.166  * (max_level - 1) + 0.1 * (getRealLevel() - max_level) + lgnd_off;
	}

	// ------
	// Events
	// ------

	const ricochet_dminst_cd = 2; // cooldown of ricochet in damage instances
	int ricochet_dminst; // current damage instance

	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;

		double protfact_ml;
		if(RecognitionUtils.damageIsBallistic(inflictor, source, damageType, flags, protfact_ml))
		{
			if(isLegendary() && ricochet_dminst == ricochet_dminst_cd){
				ricochet_dminst = 0;
				newDamage = 0;

				if(source || inflictor){
					vector3 tosrc;
					if(source)	tosrc = owner.Vec3To(source).unit();
					else		tosrc = owner.Vec3To(inflictor).unit();

					double angle;
					if(source)	angle = owner.AngleTo(source);
					else		angle = owner.AngleTo(inflictor);
					double pitch = -asin(tosrc.z);

					owner.LineAttack(angle, 4096, pitch, damage * 2, "None", null);
				}
			}
			else {
				Name shld_cls = "DSMagicShield";
				for(Inventory i = owner.Inv; i != null; i = i.Inv)
					if(i is shld_cls)
						return;

				if(isLegendary())
					ricochet_dminst++;
				newDamage = damage * (1 - getProtectionFactor() * protfact_ml);
				DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
				aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor()*100*protfact_ml);
				aughld.absorbtion_msg_timer = 35 * 2;
				aughld.doGFXResistance();
			}
		}
	}
}
