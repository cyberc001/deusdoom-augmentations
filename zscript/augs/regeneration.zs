class DD_Aug_Regeneration : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){
		return 150;
	}

	override void install()
	{
		super.install();

		id = 5;
		disp_name = "Regeneration";

		if(DD_ModChecker.isLoaded_HDest() && DD_PatchChecker.isLoaded_HDest())
			disp_desc = "Programmable polymerase automatically directs\n"
				    "construction of proteins in injured cells, healing various\n"
				    "wounds of an agent at slow rate.\n"
				    "Each level increases not only healing rate, but allows\n"
				    "more wound types to be healed.\n\n"
				    "TECH ONE: Fresh and bleeding wounds are healed.\n\n"
				    "TECH TWO: Burns are healed.\n\n"
				    "TECH THREE: Old wounds are healed.\n\n"
				    "TECH FOUR: Aggravated damage is healed.\n\n";
		else if(DD_ModChecker.isLoaded_DeathStrider() && DD_PatchChecker.isLoaded_DeathStrider())
			disp_desc = "Programmable polymerase automatically directs\n"
				    "construction of proteins in injured cells, healing various\n"
				    "wounds of an agent at slow rate.\n"
				    "Each level increases not only healing rate, but allows\n"
				    "more wound types to be healed.\n\n"
				    "TECH ONE: Overall health is healed.\n\n"
				    "TECH TWO: Wounds are healed.\n\n"
				    "TECH THREE: Body integrity is restored.\n\n"
				    "TECH FOUR: Blood is restored.\n\n";
		else
			disp_desc = "Programmable polymerase automatically directs\n"
				    "construction of proteins in injured cells, restoring an\n"
				    "agent to full health over time.\n\n"
				    "TECH ONE: Healing occurs at a normal rate.\n\n"
				    "TECH TWO: Healing occurs at a slightly faster rate.\n\n"
				    "TECH THREE: Healing occurs at a moderately faster\n"
				    "rate.\n\n"
				    "TECH FOUR: Healing occurs at a significantly faster\n"
				    "rate.\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Prevents an instance of\n"
				   "fatal damage directed at agent, granting a short\n"
				   "burst of almost instant regeneration.\n"
				   "This ability has a long cooldown.\n\n";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		can_be_legendary = true;

		regen_timer = getHealthRegenInterval();
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("REGEN0");
		tex_on = TexMan.CheckForTexture("REGEN1");
	}

	// ------------------
	// Internal functions
	// ------------------

	const fatal_regen_burst = 45; // burst of HP regeneration when recieving fatal damage
	const fatal_regen_time = 35 * 210; // time it takes to replenish the fatal damage negating ability
	int fatal_regen_timer;
	const fatal_tint_time = 35 * 15;
	int fatal_tint_timer;

	int regen_timer;
	protected int getHealthRegenRate() { return 2 + 1 * (getRealLevel() - 1) + ((owner is "PlayerPawn") ? 0 : (getRealLevel() - 1) * 1.5); }
	protected int getHealthRegenInterval()
	{
		if(getRealLevel() <= max_level)
			return 40 - 7 * (getRealLevel() - 1);
		else
			return 40 - 7 * (max_level - 1) - 3 * (getRealLevel() - max_level);
	}

	int regenerated_this_tick; // how much HP was regenerated this tick; used by power recirculator legendary upgrade

	// HDest values and timers

	int regen_timer_hdbasehp;
	int regen_timer_hdunstablewound;
	int regen_timer_hdwound;
	int regen_timer_hdburn;
	int regen_timer_hdoldwound;
	int regen_timer_hdaggravated;

	protected int getHDUnstableWoundRegenInterval()
	{ return 175 - 25 * (getRealLevel() - 1); }
	protected int getHDWoundRegenInterval()
	{ return 300 - 40 * (getRealLevel() - 1); }
	protected int getHDBurnRegenInterval()
	{ return 375 - 90 * (getRealLevel() - 1); }
	protected int getHDOldWoundRegenInterval()
	{ return 550 - 120 * (getRealLevel() - 1); }
	protected int getHDAggravatedDamageRegenInterval()
	{ return 700 - 130 * (getRealLevel() - 1); } // the timer is relatively small because aggravated damage is, well, HP points and not count of wounds

	protected double getDSWoundRegenAmt()
	{ return 0.003 + 0.003 * (getRealLevel() - 2); }
	protected double getDSBodyRegenAmt()
	{ return 0.005 + 0.003 * (getRealLevel() - 3); }
	protected double getDSBloodRegenAmt()
	{ return 0.006 + 0.003 * (getRealLevel() - 3); }

	void spawnBloodGFX()
	{
		for(uint i = 0; i < 8; ++i)
			Actor.Spawn("Blood", owner.pos + (frandom(-owner.radius, owner.radius), frandom(-owner.radius, owner.radius), owner.height / 2 + frandom(-owner.height / 3, 0)));
	}

	// -------------
	// Engine events
	// -------------

	override void tick()
	{
		regenerated_this_tick = 0;

		if(!owner)
			return;
		if(owner.player)
		{
			if(fatal_tint_timer > 0)
			{
				--fatal_tint_timer;
				double tint_str = 0.33 + ((double(fatal_tint_timer) / fatal_tint_time)  * 0.66);
				Shader.setEnabled(owner.player, "DD_FatalRegen", true);
				Shader.setUniform1f(owner.player, "DD_FatalRegen", "strength", tint_str);
			}
			else
				Shader.setEnabled(owner.player, "DD_FatalRegen", false);
		}

		super.tick();
		if(!enabled)
			return;
		if(fatal_regen_timer > 0)
			--fatal_regen_timer;

		if(!(owner is "PlayerPawn")){
			if(regen_timer > 0)
				--regen_timer;
			else{
				double maxreg = min(owner.SpawnHealth() * 0.008 * getRealLevel(), 100 * (getRealLevel() + 1) / 2.);
				if(!owner.giveInventory("Health", getHealthRegenRate() + maxreg))
					toggle();
				regenerated_this_tick += getHealthRegenRate();
				regen_timer = getHealthRegenInterval();
				spawnBloodGFX();
			}
		}
		if(DD_ModChecker.isLoaded_HDest() && DD_PatchChecker.isLoaded_HDest())
		{
			// Regenerating overall health regardless
			if(regen_timer_hdbasehp > 0)
				--regen_timer_hdbasehp;
			else{
				spawnBloodGFX();
				owner.giveInventory("Health", getHealthRegenRate());
				regenerated_this_tick += getHealthRegenRate();
				regen_timer_hdbasehp = getHealthRegenInterval();
			}

			// Regenerating wounds
			Actor hg;
			Class<Actor> hg_cls = ClassFinder.findActorClass("DD_HDHealthGiver");
			if(hg_cls)
				hg = Actor.spawn(hg_cls);
			hg.target = owner;

			if(regen_timer_hdunstablewound > 0)
				--regen_timer_hdunstablewound;
			else{
				hg.args[0] = 1;
				regen_timer_hdunstablewound = getHDUnstableWoundRegenInterval();
			}

			if(regen_timer_hdwound > 0)
				--regen_timer_hdwound;
			else{
				hg.args[1] = 1;
				regen_timer_hdwound = getHDWoundRegenInterval();
			}

			if(getRealLevel() >= 2)
			{
				if(regen_timer_hdburn > 0)
					--regen_timer_hdburn;
				else{
					hg.args[2] = 1;
					regen_timer_hdburn = getHDBurnRegenInterval();
				}
			}

			if(getRealLevel() >= 3)
			{
				if(regen_timer_hdoldwound > 0)
					--regen_timer_hdoldwound;
				else{
					hg.args[3] = 1;
					regen_timer_hdoldwound = getHDOldWoundRegenInterval();
				}
			}

			if(getRealLevel() >= 4)
			{
				if(regen_timer_hdaggravated > 0)
					--regen_timer_hdaggravated;
				else{
					hg.args[4] = 1;
					regen_timer_hdaggravated = getHDAggravatedDamageRegenInterval();
				}
			}
		}
		else if(DD_ModChecker.isLoaded_DeathStrider() && DD_PatchChecker.isLoaded_DeathStrider())
		{
			// DeathStrider storing blood level and body integrity as doubles allows to just adjust the numbers instead of playing with timers
			if(regen_timer > 0)
				--regen_timer;
			else{
				owner.giveInventory("Health", getHealthRegenRate());
				regenerated_this_tick += getHealthRegenRate();
				regen_timer = getHealthRegenInterval();

				Actor hg;
				Class<Actor> hg_cls = ClassFinder.findActorClass("DD_DSHealthGiver");
				if(hg_cls)
					hg = Actor.spawn(hg_cls);
				hg.target = owner;
				if(getRealLevel() >= 2) hg.args[0] = getDSWoundRegenAmt() * 10000;
				if(getRealLevel() >= 3) hg.args[1] = getDSBodyRegenAmt() * 10000;
				if(getRealLevel() >= 4) hg.args[2] = getDSBloodRegenAmt() * 10000;

				spawnBloodGFX();
			}			
		}
		else
		{
			if(regen_timer > 0)
				--regen_timer;
			else{
				if(!owner.giveInventory("Health", getHealthRegenRate()))
					toggle();
				regenerated_this_tick += getHealthRegenRate();
				regen_timer = getHealthRegenInterval();
				spawnBloodGFX();
			}
		}
	}

	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;

		if(isLegendary() && damage >= owner.health && fatal_regen_timer == 0)
		{ // save the user
			for(uint i = 0; i < 4; ++i)
				spawnBloodGFX();

			owner.giveInventory("Health", fatal_regen_burst);
			regenerated_this_tick += fatal_regen_burst;
			owner.A_StartSound("play/aug/fatalsave1");
			owner.A_StartSound("play/aug/fatalsave2");

			fatal_tint_timer = fatal_tint_time;
			fatal_regen_timer = fatal_regen_time;
		}
	}
}
