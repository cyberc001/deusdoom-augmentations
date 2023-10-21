class DD_Aug_PowerRecirculator : DD_Augmentation
{
	ui TextureID ui_tex;

	override TextureID get_ui_texture(bool state)
	{
		return ui_tex;
	}

	override int get_base_drain_rate(){ return 10; }

	override void install()
	{
		super.install();

		id = 7;
		disp_name = "Power Recirculator";
		disp_desc = "Power consumption for all augmentations\ is reduced by\n"
			    "polianilene circuits, plugged directly into cell membranes\n"
			    "that allow nanite particles to interconnect\n"
			    "electronically without leaving their host cells.\n"
			    "Augmentation works passively.\n"
			    "TECH ONE: Power drain of augmentations is reduced\n"
			    "slightly.\n\n"
			    "TECH TWO: Power drain of augmentations is reduced\n"
			    "moderately.\n\n"
			    "TECH THREE: Power drain of augmentations is reduced\n"
			    "by a good amount.\n\n"
			    "TECH FOUR: Power drain of augmentations is reduced\n"
			    "significantly.\n\n"
			    "Energy Rate: 10 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: polianilene circuits\n"
				   "are improved, gaining ability to capture\n"
				   "energy released from forming molecular\n"
				   "bonds when agent is getting healed.\n"
				   "Augmentation-induced regeneration\n"
				   "does not generate energy.";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		can_be_all_toggled = false;
		passive = true;
		can_be_legendary = true;

		prev_health = -1;
	}

	override void UIInit()
	{
		ui_tex = TexMan.CheckForTexture("POWREC0");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected double getPowerSaveFactor() { return 0.15 + 0.1 * (getRealLevel() - 1); }

	// legendary upgrade health regen tracking
	int prev_health;

	// -------------
	// Engine events
	// -------------

	override void tick()
	{
		super.tick();

		if(!owner)
			return;

		if(prev_health == -1 && owner)
			prev_health = owner.health;
		if(isLegendary())
		{
			int health_diff = owner.health - prev_health;
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_Regeneration")
				{
					let regaug = DD_Aug_Regeneration(aughld.augs[i]);
					health_diff -= regaug.regenerated_this_tick;
					break;
				}
			}
			if(health_diff > 0)
				owner.giveInventory("DD_BioelectricEnergy", ceil(health_diff / 2.));
			prev_health = owner.health;
		}

		DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(!aughld)
			return;
		aughld.energy_drain_ml = 1.0 - getPowerSaveFactor();
	}
}
