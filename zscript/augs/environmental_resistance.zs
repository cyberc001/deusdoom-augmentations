class DD_Aug_EnvironmentalResistance : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;
	ui TextureID tex_passive;

	override TextureID get_ui_texture(bool state)
	{
		return passive ? tex_passive : (state ? tex_on : tex_off);
	}

	override int get_base_drain_rate(){ return 40; }

	override void install()
	{
		super.install();

		id = 13;
		disp_name = "Environmental Resistance";
		disp_desc = "Induced keratin production strengthens all epithelial\n"
			    "tissues and reduces an agent's vulnerability to\n"
			    "radiation, toxins and hot surfaces.\n\n";

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

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		legend_count = 2;
		legend_names[0] = "augmentation works passively";
		legend_names[1] = "heal on top of hurtfloors";
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("ENVRES0");
		tex_on = TexMan.CheckForTexture("ENVRES1");
		tex_passive = TexMan.CheckForTexture("ENVRES2");
	}

	override void tick()
	{
		super.tick();
		passive = (legend_installed == 0);
	}

	protected double getProtectionFactor()
	{
		return 0.25 + 0.25 * (getRealLevel() - 1);
	}

	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled && !passive)
			return;

		double protfact_ml;
		if(RecognitionUtils.damageIsEnvironmental(inflictor, source, damageType, flags, protfact_ml))
		{
			newDamage = damage * (1 - getProtectionFactor() * protfact_ml);
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor() * 100 * protfact_ml);
			aughld.absorbtion_msg_timer = 35 * 1;
			aughld.doGFXResistance();

			if(legend_installed == 1){
				if(DD_ModChecker.isLoaded_DeathStrider() && DD_PatchChecker.isLoaded_DeathStrider()){
					owner.giveInventory("Health", ceil(damage / 3.));
					Actor hg;
					Class<Actor> hg_cls = ClassFinder.findActorClass("DD_DSHealthGiver");
					if(hg_cls)
						hg = Actor.spawn(hg_cls);
					hg.target = owner;
					hg.args[0] = 0.003 * 10000;
					hg.args[1] = 0.002 * 10000;
					hg.args[2] = 0.002 * 10000;
				}			
				else
					owner.giveInventory("Health", 3);
			}
		}
	}
}
