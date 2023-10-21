class DD_Aug_EnergyShield : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	DD_EnergyShield_AuraGFX aura_effect;

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
			    "electrical, and plasma attacks.\n\n"
			    "TECH ONE: Damage from energy attacks is reduced\n"
			    "slightly.\n\n"
			    "TECH TWO: Damage from energy attacks is reduced\n"
			    "moderately.\n\n"
			    "TECH THREE: Damage from energy attacks is reduced\n"
			    "significantly.\n\n"
			    "TECH FOUR: An agent is nearly invulnerable to damage\n"
			    "from energy attacks.\n\n"
			    "Energy Rate: 70 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Heat absorbed by the capacitors\n"
				   "is released back with some nanites that control it's\n"
				   "spread, creating an area of controllable heat that\n"
				   "damages everything it touches.";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		can_be_legendary = true;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("ENGSHLD0");
		tex_on = TexMan.CheckForTexture("ENGSHLD1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getProtectionFactor()
	{
		if(getRealLevel() <= max_level)
			return 0.20 + 0.15 * (getRealLevel() - 1);
		else
			return 0.20 + 0.15 * (max_level - 1) + 0.1 * (getRealLevel() - max_level);
	}

	// -------------
	// Engine events
	// -------------

	const dmg_aura_threshold = 15; // minimum damage to actually harm things around
	const dmg_aura_range = 110; // added to the owner's radius

	int dmg_resv; // damage reserve
	const dmg_resv_diss = 8; // ticks for 1 point of damage reserve to dissipate when aug is off
	int dmg_resv_timer;

	const fire_spawn_time = 30; // how often spawn archvile flames on burnt enemies
	int fire_spawn_timer;

	override void Tick()
	{
		super.Tick();

		if(!enabled){
			if(dmg_resv_timer > 0)
				--dmg_resv_timer;
			else if(dmg_resv > 0){
				dmg_resv_timer = dmg_resv_diss;
				dmg_resv--;
			}

			if(aura_effect){
				aura_effect.Destroy();
				aura_effect = null;
			}
			return;
		}

		if(isLegendary() && dmg_resv > dmg_aura_threshold){
			if(!aura_effect){
				aura_effect = DD_EnergyShield_AuraGFX(Spawn("DD_EnergyShield_AuraGFX"));
				aura_effect.parent_aug = self;
			}
		}
		else if(aura_effect){
			aura_effect.Destroy();
			aura_effect = null;
		}

		if(fire_spawn_timer > 0)
			--fire_spawn_timer;

		if(dmg_resv > dmg_aura_threshold){
			BlockThingsIterator itb = BlockThingsIterator.Create(owner, owner.radius + dmg_aura_range);
			bool dealt_dmg = false; // was damage dealt to any monster?
			while(itb.next())
			{
				Actor mnst = itb.thing;
				if(!mnst.bIsMonster || mnst.health <= 0)
					continue;

				dealt_dmg = true;
				mnst.damageMobj(owner, owner, 4, "Fire",
						DMG_NO_PAIN | DMG_THRUSTLESS);

				if(fire_spawn_timer == 0)
					Spawn("ArchvileFire", mnst.pos);
			}

			if(dealt_dmg){
				dmg_resv -= 4;
				if(fire_spawn_timer == 0)
					fire_spawn_timer = fire_spawn_time;
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

			if(isLegendary()){
				int abs_dmg = damage * getProtectionFactor() * protfact_ml;
				dmg_resv += abs_dmg * 4;
			}
		}
	}
}


class DD_EnergyShield_AuraGFX : Actor
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

		Scale 0.2;
	}

	states
	{
		Spawn:
			DDFX A -1;
			Stop;
	}


	DD_Aug_EnergyShield parent_aug;

	const dmg_aura_minopaq = 0.1;
	const dmg_aura_maxopaq_resv = 200.0; // Damage reserve that makes effect 50% opaque

	override void Tick()
	{
		Warp(parent_aug.owner, 0, 0, 0, 0, WARPF_NOCHECKPOSITION | WARPF_COPYVELOCITY);

		super.Tick();

		double opaq = dmg_aura_minopaq + (1 - dmg_aura_minopaq) * min(parent_aug.dmg_resv / dmg_aura_maxopaq_resv, 1);
		A_SetRenderStyle(0.5 * opaq, STYLE_Translucent);

		if(parent_aug.dmg_resv > dmg_aura_maxopaq_resv)		A_SetTranslation("DD_EnergyShield_AuraRed");
		else if(parent_aug.dmg_resv > dmg_aura_maxopaq_resv/2)	A_SetTranslation("DD_EnergyShield_AuraOrange");
		else							A_SetTranslation("DD_EnergyShield_AuraYellow");
	}
}
