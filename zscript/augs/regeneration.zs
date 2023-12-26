class DD_RegenConsumption : Inventory
{
	double hp_left;
}
class DD_200Health : Health
{
	default
	{
		Inventory.MaxAmount 200;
	}
}
class DD_120Armor : ArmorBonus
{
	default
	{
		Armor.MaxSaveAmount 120;
	}
}

class DD_Aug_Regeneration : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate() { return 80; }

	override void install()
	{
		super.install();

		id = 5;
		disp_name = "Regeneration";

		if(DD_ModChecker.isLoaded_DeathStrider() && DD_PatchChecker.isLoaded_DeathStrider()){
			disp_desc = "Programmable polymerase automatically directs\n"
				    "construction of proteins in injured cells, healing various\n"
				    "wounds of an agent at slow rate.\n"
				    "Each level increases not only healing rate, but allows\n"
				    "more wound types to be healed.\n\n"
				    "TECH ONE: Overall health is healed.\n\n"
				    "TECH TWO: Wounds are healed.\n\n"
				    "TECH THREE: Body integrity is restored.\n\n"
				    "TECH FOUR: Blood is restored.\n\n";
		}
		else{
			disp_desc = "Programmable polymerase automatically directs\n"
				    "construction of proteins in injured cells, restoring an\n"
				    "agent to full health over time.\n\n";
			_level = 1;
			disp_desc = disp_desc .. string.format("TECH ONE: %g health regenerated per %.2gs.\n\n", getHealthRegenRate(), getHealthRegenInterval() / 35.);
			_level = 2;
			disp_desc = disp_desc .. string.format("TECH TWO: %g health regenerated per %.2gs.\n\n", getHealthRegenRate(), getHealthRegenInterval() / 35.);
			_level = 3;
			disp_desc = disp_desc .. string.format("TECH THREE: %g health regenerated per %.2gs.\n\n", getHealthRegenRate(), getHealthRegenInterval() / 35.);
			_level = 4;
			disp_desc = disp_desc .. string.format("TECH FOUR: %g health regenerated per %.2gs.\n\n", getHealthRegenRate(), getHealthRegenInterval() / 35.);

			_level = 1;
			disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());
		}

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;

		legend_count = 3;
		legend_names[0] = "Consume corpses to regain more health";
		legend_names[1] = "Regenerate up to 200 hp, less effective >=100 hp";
		legend_names[2] = "Regenerate current armor up to 120";

		regen_timer = getHealthRegenInterval();
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("REGEN0");
		tex_on = TexMan.CheckForTexture("REGEN1");
	}

	int regen_timer;
	protected int getHealthRegenRate() { return 5 * ((!owner || owner is "PlayerPawn" || owner is "DD_AugsHolder") ? 1 : (3 + getRealLevel() - 1) * 1.5) - (owner ? (owner.health >= 100 && legend_installed == 1 ? 2 : 0) : 0); }
	protected int getHealthRegenInterval()
	{
		return 65 - 12 * (getRealLevel() - 1);
	}

	int regenerated_this_tick; // how much HP was regenerated this tick; used by power recirculator legendary upgrade
	double consume_queue;
	const consume_fact = 0.0125; // consumed health is multiplied by this
	const consume_maxhp_frac = 0.01; // fraction of monster corpse's max hp consumed
	const consume_hp = 1; // plain amount of hp consumed
	const consume_radius = 90;

	protected double getDSWoundRegenAmt()
	{ return 0.003 + 0.003 * (getRealLevel() - 2); }
	protected double getDSBodyRegenAmt()
	{ return 0.02 + 0.015 * (getRealLevel() - 3); }
	protected double getDSBloodRegenAmt()
	{ return 0.008 + 0.006 * (getRealLevel() - 4); }

	void spawnBloodGFX()
	{
		for(uint i = 0; i < 8; ++i)
			Actor.Spawn("Blood", owner.pos + (frandom(-owner.radius, owner.radius), frandom(-owner.radius, owner.radius), owner.height / 2 + frandom(-owner.height / 3, 0)));
	}

	const gfx_line_roff = 3;
	const gfx_line_step = 4;
	void spawnConsumeGFX(Actor to)
	{
		vector3 pt = owner.pos + (0, 0, owner.height * 3./5);
		vector3 dir = to.pos - pt;
		uint steps = dir.length() / gfx_line_step;
		if(dir.length() > 0) dir /= dir.length();
		dir *= gfx_line_step;
		pt -= owner.pos;
		for(uint j = 0; j < steps; ++j, pt += dir){
			owner.A_SpawnParticle(0x00FF4040, flags: SPF_NOTIMEFREEZE, lifetime: 1, size: 5, xoff: pt.x + frandom(-gfx_line_roff, gfx_line_roff), yoff: pt.y + frandom(-gfx_line_roff, gfx_line_roff), zoff: pt.z + frandom(-gfx_line_roff, gfx_line_roff), velx: owner.vel.x, vely: owner.vel.y, velz: owner.vel.z, startalphaf: 0.5);
			owner.A_SpawnParticle(0x00DC9787, flags: SPF_NOTIMEFREEZE, lifetime: 1, size: 5, xoff: pt.x + frandom(-gfx_line_roff, gfx_line_roff), yoff: pt.y + frandom(-gfx_line_roff, gfx_line_roff), zoff: pt.z + frandom(-gfx_line_roff, gfx_line_roff), velx: owner.vel.x, vely: owner.vel.y, velz: owner.vel.z, startalphaf: 0.5);
		}
	}

	override void tick()
	{
		super.tick();
		regenerated_this_tick = 0;

		if(!owner || !enabled)
			return;
		
		if(!(owner is "PlayerPawn")){
			if(regen_timer > 0)
				--regen_timer;
			else{
				double maxreg = min(owner.SpawnHealth() * 0.015 * getRealLevel(), 75 * (getRealLevel() + 1) / 2.);
				if(!owner.giveInventory("Health", getHealthRegenRate() + maxreg))
					toggle();
				regenerated_this_tick += getHealthRegenRate();
				regen_timer = getHealthRegenInterval();
				spawnBloodGFX();
			}
			return;
		}

		if(legend_installed == 0){
			let it = BlockThingsIterator.create(owner, consume_radius);
			double consumed_total = 0;
			while(it.next()){
				if(!it.thing.bISMONSTER || it.thing.health > 0)
					continue;
				let consume_token = DD_RegenConsumption(it.thing.findInventory("DD_RegenConsumption"));
				if(!consume_token){
					it.thing.giveInventory("DD_RegenConsumption", 1);
					consume_token = DD_RegenConsumption(it.thing.findInventory("DD_RegenConsumption"));
					consume_token.hp_left = it.thing.SpawnHealth();
				}
				if(consume_token.hp_left <= 0){
					consume_token.destroy();
					Actor.Spawn("RealGibs", it.thing.pos);
					it.thing.destroy();
				}
				else{
					double consumed = min(consume_token.hp_left, it.thing.SpawnHealth() * consume_maxhp_frac + consume_hp);
					consume_token.hp_left -= consumed;
					consumed_total += consumed;
					spawnConsumeGFX(it.thing);
					if(random() == 65)
						it.thing.A_StartSound("misc/gibbed", volume: 0.7);
				}
			}
			consume_queue += consumed_total * consume_fact;
			if(consume_queue >= 1){
				if(owner.giveInventory("Health", floor(consume_queue))){
					regenerated_this_tick += floor(consume_queue);
					consume_queue -= floor(consume_queue);
				}
			}
			if(DD_ModChecker.isLoaded_DeathStrider() && DD_PatchChecker.isLoaded_DeathStrider())
			{
				Actor hg;
				Class<Actor> hg_cls = ClassFinder.findActorClass("DD_DSHealthGiver");
				if(hg_cls)
					hg = Actor.spawn(hg_cls);
				hg.target = owner;
				if(getRealLevel() >= 2) hg.args[0] = consumed_total * 0.001 * 10000;
				if(getRealLevel() >= 3) hg.args[1] = consumed_total * 0.001 * getDSBodyRegenAmt() * 10000;
				if(getRealLevel() >= 4) hg.args[2] = consumed_total * 0.001 * getDSBloodRegenAmt() * 10000;
			}
		}

		if(DD_ModChecker.isLoaded_DeathStrider() && DD_PatchChecker.isLoaded_DeathStrider())
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
				bool do_toggle = false;
				if(!owner.giveInventory(legend_installed == 1 ? "DD_200Health" : "Health", getHealthRegenRate()))
					do_toggle = true;
				if(legend_installed == 2){
					owner.giveInventory("DD_120Armor", getHealthRegenRate() - 2);
					do_toggle = owner.countinv("BasicArmor") >= 120;
				}
				regenerated_this_tick += getHealthRegenRate();
				regen_timer = getHealthRegenInterval();
				spawnBloodGFX();
				if(do_toggle)
					toggle();
			}
		}
	}
}
