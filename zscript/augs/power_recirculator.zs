class DD_Aug_PowerRecirculator : DD_Augmentation
{
	ui TextureID ui_tex;

	override TextureID get_ui_texture(bool state)
	{
		return ui_tex;
	}

	override void install()
	{
		super.install();

		id = 7;
		disp_name = "Power Recirculator";
		disp_desc = "Power consumption for all augmentations\ is reduced by\n"
			    "polianilene circuits, plugged directly into cell membranes\n"
			    "that allow nanite particles to interconnect\n"
			    "electronically without leaving their host cells.\n"
			    "Augmentation works passively.\n\n";
		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Energy cost reduction is %g%%.\n\n", getPowerSaveFactor() * 100);
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Energy cost reduction is %g%%.\n\n", getPowerSaveFactor() * 100);
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Energy cost reduction is %g%%.\n\n", getPowerSaveFactor() * 100);
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Energy cost reduction is %g%%.\n\n", getPowerSaveFactor() * 100);
		_level = 1;
		
		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		legend_count = 3;
		legend_names[0] = "regain 1/3rd of healing as energy";
		legend_names[1] = "slow energy regeneration";
		legend_names[2] = "+20% power drain reduction";

		passive = true;
	}

	override void UIInit()
	{
		ui_tex = TexMan.CheckForTexture("POWREC0");
	}

	// legendary upgrade health regen tracking
	int prev_health;
	double energy_regen_queue;
	const energy_regen = 0.005;

	protected double getPowerSaveFactor() { return 0.15 + 0.1 * (getRealLevel() - 1) + (legend_installed == 2 ? 0.2 : 0); }

	override void tick()
	{
		super.tick();
		if(!owner) return;
		DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(!aughld) return;

		if(prev_health == -1 && owner)
			prev_health = owner.health;
		if(legend_installed == 0)
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
				owner.giveInventory("DD_BioelectricEnergy", ceil(health_diff / 3.));
		}
		else if(legend_installed == 1){
			energy_regen_queue += energy_regen;
			if(energy_regen_queue >= 1){
				owner.giveInventory("DD_BioelectricEnergy", floor(energy_regen_queue));
				energy_regen_queue -= floor(energy_regen_queue);
			}
		}
			
		prev_health = owner.health;

		aughld.energy_drain_ml = 1.0 - getPowerSaveFactor();
	}
}
