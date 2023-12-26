class DD_Aug_Cloak : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	double bonus_drain; // affected by legendary upgrade 1
	const bonus_drain_decay = 1;
	const bonus_drain_inc = 7;
	override int get_base_drain_rate()
	{
		return (240 - 30 * (getRealLevel() - 1)) * (owner && owner.bISMONSTER ? 0.35 : 1) + bonus_drain;
	}

	override void install()
	{
		super.install();

		id = 10;
		disp_name = "Cloak";
		disp_desc = "Subdermal pigmentation cells allow an agent to blend\n"
			    "with their surrounding environment, rendering them\n"
			    "effectively invisible to observation by organic hostiles.\n"
			    "Attacking by any means breaks invisibility by a brief\n"
			    "moment.\n\n";
		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Invisibility restores after %.2gs.\nEnergy rate is %d Units/Minute.\n\n", getBlinkTime() / 35., get_base_drain_rate());
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Invisibility restores after %.2gs.\nEnergy rate is %d Units/Minute.\n\n", getBlinkTime() / 35., get_base_drain_rate());
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Invisibility restores after %.2gs.\nEnergy rate is %d Units/Minute.\n\n", getBlinkTime() / 35., get_base_drain_rate());
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Invisibility restores after %.2gs.\nEnergy rate is %d Units/Minute.\n\n", getBlinkTime() / 35., get_base_drain_rate());
		_level = 1;

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;

		legend_count = 2;
		legend_names[0] = "increase energy drain instead of losing cloak";
		legend_names[1] = "attacking when cloaked does more damage";
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("CLOAK0");
		tex_on = TexMan.CheckForTexture("CLOAK1");
	}

	int getBlinkTime()
	{
		return 40 - 6 * (getRealLevel() - 1);
	}
	int blinktimer; // timer that starts when player starts an attack, revealing them for a short time
	int boost_timer; // timer for boosting an attack after cloak, lasts a few ticks
	int boost_cd_timer;
	const boost_cd = 35 * 5;

	override void tick()
	{
		super.tick();

		bonus_drain = max(0, bonus_drain - bonus_drain_decay * (1 + bonus_drain / 200.));
		if(legend_installed == 0)
			hud_info = string.format("+%d", bonus_drain);
		else if(legend_installed == 1)
			hud_info = (boost_timer || !blinktimer ? "+" : "") .. string.format("%.2gs", boost_cd_timer / 35.);

		if(!enabled || !owner)
			return;

		if(owner is "PlayerPawn"
		&& (owner.curstate == PlayerPawn(owner).MissileState
		 || owner.curstate == PlayerPawn(owner).MeleeState))
		{
			if(legend_installed == 0)
				bonus_drain += bonus_drain_inc;
			else{
				owner.A_SetRenderStyle(1.0, Style_Normal);
				if(blinktimer == 0 && legend_installed == 1)
					boost_timer = 3;
				blinktimer = getBlinkTime();
				return;
			}
		}

		if(boost_timer > 0)
			--boost_timer;
		if(boost_cd_timer > 0)
			--boost_cd_timer;
		if(blinktimer > 0){
			--blinktimer;
			return;
		}

		if(owner is "PlayerPawn")
			owner.A_SetRenderStyle(1.0, Style_Fuzzy);
		else
			owner.A_SetRenderStyle(0.25, Style_Translucent);

		Actor mnst;
		ThinkerIterator it = ThinkerIterator.create("Actor", STAT_DEFAULT);

		if(owner is "PlayerPawn")
		{
			while(mnst = Actor(it.next()))
			{
				IF(!mnst.bIsMonster || mnst.health <= 0)
					continue;
				if(!RecognitionUtils.isFooledByCloak(mnst))
					continue;
					if(mnst.target && mnst.target == owner){
					mnst.target = null;
					mnst.seeSound = "";
				}
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
			owner.A_SetRenderStyle(1.0, Style_Normal);

			if(owner is "PlayerPawn")
			{
				Actor mnst;
				ThinkerIterator it = ThinkerIterator.create("Actor", STAT_DEFAULT);
				while(mnst = Actor(it.next()))
				{
					if(!mnst.bIsMonster)
						continue;

					if(mnst.seeSound == "")
						mnst.seeSound = getDefaultByType(mnst.getClass()).seeSound;

				}
			}
		}
	}

	override void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor victim, int flags)
	{
		if(!enabled)
			return;
		if(legend_installed == 1 && boost_timer && RecognitionUtils.isFooledByCloak(victim) && boost_cd_timer <= 0){
			newDamage = damage * 2;
			boost_cd_timer = boost_cd;
		}
	}
}
