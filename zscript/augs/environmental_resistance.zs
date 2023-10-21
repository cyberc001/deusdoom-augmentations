class DD_Aug_EnvironmentalResistance : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 40; }

	override void install()
	{
		super.install();

		id = 13;
		disp_name = "Environmental Resistance";
		disp_desc = "Induced keratin production strengthens all epithelial\n"
			    "tissues and reduces an agent's vulnerability to\n"
			    "radiation, toxins and hot surfaces.\n\n"
			    "TECH ONE: Hazard resistance is increased slightly.\n\n"
			    "TECH TWO: Hazard resistance is increased moderately.\n\n"
			    "TECH THREE: Hazard resistance is increased\n"
			    "significantly.\n\n"
			    "TECH FOUR: An agent is invulnerable to damage from\n"
			    "any environmental hazards.\n\n"
			    "Energy Rate: 40 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Energy emitted by hazard\n"
				      "surfaces is converted to bioelectric energy. This\n"
				      "makes such surfaces quickly give away their energy,\n"
				      "eliminating the hazard entirely.";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		can_be_legendary = true;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("ENVRES0");
		tex_on = TexMan.CheckForTexture("ENVRES1");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getProtectionFactor()
	{
		if(getRealLevel() <= max_level)
			return 0.25 + 0.25 * (getRealLevel() - 1);
		else
			return 0.25 + 0.25 * (max_level - 1);
	}

	// -------------
	// Engine events
	// -------------

	const dissipation_time = 35 * 15; // time to completely get rid of damaging property of a sector
	const energy_for_dissipation = 40;
	double energy_gain_queue;

	override void tick()
	{
		super.tick();
		if(!enabled)
			return;

		if(isLegendary() && owner.floorsector.damageamount > 0)
		{
			let deh = DD_AugsEventHandler(StaticEventHandler.find("DD_AugsEventHandler"));
			uint i = deh.dissipating_sectors.find(owner.floorsector);
			if(i == deh.dissipating_sectors.size()) {
				deh.dissipating_sectors.push(owner.floorsector);
				deh.dissipating_damage.push(owner.floorsector.damageamount);
				deh.dissipating_timers.push(dissipation_time);
			}
			else {
				--deh.dissipating_timers[i];
				deh.dissipating_sectors[i].damageamount = ceil(deh.dissipating_damage[i] * (double(deh.dissipating_timers[i]) / dissipation_time));
				energy_gain_queue += double(energy_for_dissipation) / dissipation_time;
				if(energy_gain_queue >= 1.0){
					energy_gain_queue -= 1.0;
					owner.giveInventory("DD_BioelectricEnergy", 1);
				}

				if(deh.dissipating_timers[i] <= 0){
					console.printf("Cleared hazardous surface at (%f; %f)", deh.dissipating_sectors[i].centerspot.x, deh.dissipating_sectors[i].centerspot.y); 
					deh.dissipating_sectors.delete(i);
					deh.dissipating_damage.delete(i);
					deh.dissipating_timers.delete(i);
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
		if(RecognitionUtils.damageIsEnvironmental(inflictor, source, damageType, flags, protfact_ml))
		{
			newDamage = damage * (1 - getProtectionFactor() * protfact_ml);
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			aughld.absorbtion_msg = String.Format("%.0f%% ABSORB", getProtectionFactor() * 100 * protfact_ml);
			aughld.absorbtion_msg_timer = 35 * 1;
			aughld.doGFXResistance();
		}
	}
}
