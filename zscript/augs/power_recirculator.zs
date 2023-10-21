class DD_Aug_PowerRecirculator : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
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
			    "Moreover, polianilene circuits act as condensators,\n"
			    "storing leftover charge that can be released back by\n"
			    "turning on the augmentation while every other\n"
			    "augmentation is off.\n\n"
			    "TECH ONE: Power drain of augmentations is reduced\n"
			    "slightly.\n\n"
			    "TECH TWO: Power drain of augmentations is reduced\n"
			    "moderately. Efficiency and capacity of storing energy\n"
			    "is increased.\n\n"
			    "TECH THREE: Power drain of augmentations is reduced\n"
			    "by a good amount. Same is true about efficiency and\n"
			    "capacity of storing energy.\n\n"
			    "TECH FOUR: Power drain of augmentations is reduced\n"
			    "significantly, capacity and efficiency of storing\n"
			    "energy is significantly increased.\n\n"
			    "Energy Rate: 10 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: polianilene circuits\n"
				   "are improved, gaining ability to capture\n"
				   "energy released from forming molecular\n"
				   "bonds when agent is getting healed.\n"
				   "Augmentation-induced regeneration\n"
				   "does not generate energy. This happens\n"
				   "even while augmentation is off.";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		can_be_all_toggled = false;
		can_be_legendary = true;

		prev_health = -1;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("POWREC0");
		tex_on = TexMan.CheckForTexture("POWREC1");
	}

	// ------------------
	// Internal functions
	// ------------------

	int recirc_timer;
	double energy_gainq;

	protected double getPowerSaveFactor() { return 0.1 + 0.1 * (getRealLevel() - 1); }
	// per second
	protected int getRecirculationSpendingRate() { return 4 + 3 * (getRealLevel() - 1); }
	protected double getRecirculationEfficiency() { return 0.26 + 0.13 * (getRealLevel() - 1); }

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
		if(!enabled){
			aughld.energy_drain_ml = 1.0;
		}
		else{
			aughld.energy_drain_ml = 1.0 - getPowerSaveFactor();
		}

		if(!enabled)
			return;

		bool one_aug_enabled = false;
		for(uint i = 0; i < aughld.augs_slots; ++i)
		{
			if(aughld.augs[i] && !(aughld.augs[i] is "DD_Aug_PowerRecirculator") && aughld.augs[i].enabled)
				one_aug_enabled = true;
		}
		if(one_aug_enabled){
			toggle(); return;
		}

		if(recirc_timer == 0){
			recirc_timer = 35;
			int amt = getRecirculationSpendingRate();
			amt = aughld.spendRecirculationEnergy(amt);
			if(amt == 0)
				toggle();
			else {
				energy_gainq += amt * getRecirculationEfficiency();
				if(floor(energy_gainq)){
					int gain_amt = floor(energy_gainq);
					energy_gainq -= gain_amt;
					owner.giveInventory("DD_BioelectricEnergy", gain_amt);
				}
			}
		}
		else {
			recirc_timer--;
		}
	}
}
