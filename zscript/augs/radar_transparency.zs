class DD_RadarChangedMonster : Inventory
{
	bool was_friendly;
}

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
		return (250 - 30 * (getRealLevel() - 1)) * (blinktimer == 0 ? 1 : 0.5);
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
			    "moment.\n\n";
		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Invisibility restores after %.2gs.\nEnergy rate %d Units/Minute.\n\n", getBlinkTime() / 35., get_base_drain_rate());
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Invisibility restores after %.2gs.\nEnergy rate %d Units/Minute.\n\n", getBlinkTime() / 35., get_base_drain_rate());
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Invisibility restores after %.2gs.\nEnergy rate %d Units/Minute.\n\n", getBlinkTime() / 35., get_base_drain_rate());
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Invisibility restores after %.2gs.\nEnergy rate %d Units/Minute.\n\n", getBlinkTime() / 35., get_base_drain_rate());
		_level = 1;

		legend_count = 2;
		legend_names[0] = "turn cybernetic enemies to your side when invisible";
		legend_names[1] = "attacking when invisible stuns the victim";

		slots_cnt = 2;
		slots[0] = Subdermal1;
		slots[1] = Subdermal2;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("RADTRNP0");
		tex_on = TexMan.CheckForTexture("RADTRNP1");
	}


	int getBlinkTime()
	{
		return 28 - 6 * (getRealLevel() - 1);
	}
	int blinktimer; // timer that start when player starts an attack, revealing them for a short time
	int boost_timer; // timer for boosting an attack after cloak, lasts a few ticks
	int boost_cd_timer;
	const boost_cd = 35 * 10;

	override void tick()
	{
		super.tick();

		if(!enabled)
			return;
		if(legend_installed == 1)
			hud_info = (boost_timer || !blinktimer ? "+" : "") .. string.format("%.2gs", boost_cd_timer / 35.);

		if(owner.curstate == PlayerPawn(owner).MissileState
		|| owner.curstate == PlayerPawn(owner).MeleeState)
		{
			owner.A_SetRenderStyle(1.0, Style_Normal);
			if(blinktimer == 0 && legend_installed == 1)
				boost_timer = 3;
			blinktimer = getBlinkTime();
			return;
		}

		if(boost_timer > 0)
			--boost_timer;
		if(boost_cd_timer > 0)
			--boost_cd_timer;
		if(blinktimer > 0)
			--blinktimer;

		Actor mnst;
		ThinkerIterator it = ThinkerIterator.create("Actor", STAT_DEFAULT);
		while(mnst = Actor(it.next()))
		{
			if(!mnst.bIsMonster || mnst.health <= 0)
				continue;
			if(!RecognitionUtils.isFooledByRadarTransparency(mnst))
				continue;
			if(legend_installed == 0){
				if(blinktimer){
					DD_RadarChangedMonster token;
					if(token = DD_RadarChangedMonster(mnst.findInventory("DD_RadarChangedMonster"))){
						mnst.bFRIENDLY = token.was_friendly;
						mnst.takeInventory("DD_RadarChangedMonster", 1);
					}	
				}
				else{
					if(!mnst.countinv("DD_RadarChangedMonster")){
						mnst.giveInventory("DD_RadarChangedMonster", 1);
						DD_RadarChangedMonster(mnst.findInventory("DD_RadarChangedMonster")).was_friendly = mnst.bFRIENDLY;
						mnst.bFRIENDLY = true;
					}
				}
			}
			if(mnst.target && mnst.target == owner){
				mnst.target = null;
				mnst.seeSound = "";
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

				if(legend_installed == 0){
					DD_RadarChangedMonster token;
					if(token = DD_RadarChangedMonster(mnst.findInventory("DD_RadarChangedMonster"))){
						mnst.bFRIENDLY = token.was_friendly;
						mnst.takeInventory("DD_RadarChangedMonster", 1);
					}
				}
			}
		}
	}

	override void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor victim, int flags)
	{
		if(!enabled)
			return;
		if(legend_installed == 1 && boost_timer && RecognitionUtils.isFooledByRadarTransparency(victim) && !victim.bBOSS && boost_cd_timer <= 0){
			let existing_pu = victim.FindInventory("DDPowerup_GasStun");
			if(existing_pu){
				existing_pu.DetachFromOwner();
				existing_pu.Destroy();
			}
			let pu = Inventory(Actor.Spawn("DDPowerup_GasStun"));
			victim.addInventory(pu);
			boost_cd_timer = boost_cd;
		}
	}

}
