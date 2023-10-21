class DD_Aug_RadarTransparency : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}


	override int get_base_drain_rate()
	{
		return (360 - 40 * (getRealLevel() - 1)) * (blinktimer == 0 ? 1 : 0.5);
	}

	override void install()
	{
		super.install();

		id = 12;
		disp_name = "Radar Transparency";
		disp_desc = "Radar-absorbent resin augments epithelial proteins;\n"
			    "microprojection units distort agent's visual signature.\n"
			    "Provides highly effective concealment from electronic\n"
			    "detection methods used by cybernetic enemies.\n"
			    "Attacking by any means breaks this effect by a brief\n"
			    "moment.\n\n"
			    "TECH ONE: Power drain is normal, agent is discovered\n"
			    "for a significant period of time.\n\n"
			    "TECH TWO: Power drain is reduced slightly, agent\n"
			    "becomes undetectable faster after attacking.\n\n"
			    "TECH THREE: Power drain is reduced moderately, agent\n"
			    "becomes undetectable significantly faster.\n\n"
			    "TECH FOUR: Power drain is reduced significantly. agent\n"
			    "is detected for a very brief moment.\n\n"
			    "Energy Rate: 400-250 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Augmentation can interfere\n"
				   "with heat and visual signatures using EMP, creating\n"
				   "an illusion of agent present somewhere else, causing\n"
				   "enemies to turn against each other.";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;

		can_be_legendary = true;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("RADTRNP0");
		tex_on = TexMan.CheckForTexture("RADTRNP1");
	}


	int getBlinkTime()
	{
		if(getRealLevel() <= max_level)
			return 28 - 6 * (getRealLevel() - 1);
		else
			return 28 - 6 * (max_level - 1) - 4 * (getRealLevel() - max_level);
	}
	int blinktimer; // timer that start when player starts an attack,
			// revealing him for a short time.

	const trick_range = 512;
	const trick_cd_min = 35 * 8;
	const trick_cd_max = 35 * 18;
	int tricktimer;

	override void tick()
	{
		super.tick();

		if(!enabled){
			return;
		}

		if(owner.curstate == PlayerPawn(owner).MissileState
		|| owner.curstate == PlayerPawn(owner).MeleeState)
		{
			owner.A_SetRenderStyle(1.0, Style_Normal);
			blinktimer = getBlinkTime();
			return;
		}
		if(blinktimer > 0){
			--blinktimer;
			return;
		}

		Actor mnst;
		ThinkerIterator it = ThinkerIterator.create("Actor", STAT_DEFAULT);
		if(DD_ModChecker.getInstance().isLoaded_HDest()
			&& DD_PatchChecker.getInstance().isLoaded_HDest())
		{
			Class<Actor> tgclr_cls = ClassFinder.findActorClass("DD_HDTargetClearer");
			Actor tgclr = Spawn(tgclr_cls);

			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster || mnst.health <= 0)
					continue;
				if(!RecognitionUtils.isFooledByRadarTransparency(mnst))
					continue;

				tgclr.target = mnst;
				tgclr.master = owner;
				tgclr.PostBeginPlay();
			}
		}
		else
		{
			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster || mnst.health <= 0)
					continue;
				if(!RecognitionUtils.isFooledByRadarTransparency(mnst))
					continue;

				if(mnst.target && mnst.target == owner){
					mnst.target = null;
					mnst.seeSound = "";
				}
			}
		}

		// Creating illusions
		BlockThingsIterator itb = BlockThingsIterator.Create(owner, trick_range);
		Actor prevmnst = null;
		while(itb.next())
		{
			Actor mnst = itb.thing;

			if(!mnst.bIsMonster || mnst.health <= 0)
				continue;
			if(!RecognitionUtils.isFooledByRadarTransparency(mnst))
				continue;

			if(isLegendary() && tricktimer == 0 && !random(0, 4)) // random() to just not always pick the same monster
			{
				if(prevmnst){
					mnst.target = prevmnst;

					tricktimer = random(trick_cd_min, trick_cd_max);
				}
				prevmnst = mnst;
			}
		}

	}

	override void toggle()
	{
		super.toggle();
		if(enabled)
			SoundUtils.playStartSound("ui/aug/cloak_up", owner);
		else
			SoundUtils.playStartSound("ui/aug/cloak_down", owner);

		if(!enabled){
			Actor mnst;
			ThinkerIterator it = ThinkerIterator.create("Actor", STAT_DEFAULT);
			while(mnst = Actor(it.next()))
			{
				if(!mnst.bIsMonster)
					continue;

				if(mnst.seeSound == "")
					mnst.seeSound = getDefaultByType(mnst.getClass()).seeSound;

				if(DD_ModChecker.getInstance().isLoaded_HDest()
					&& DD_PatchChecker.getInstance().isLoaded_HDest())
				{
					Class<Actor> tgrst_cls = ClassFinder.findActorClass("DD_HDTargetRestorer");
					Actor tgrst = Spawn(tgrst_cls);
					tgrst.target = mnst;
				}
			}
		}
	}

}
