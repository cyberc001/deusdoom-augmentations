class DD_Aug_CombatStrength : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 50; }

	override void install()
	{
		super.install();

		id = 3;
		disp_name = "Combat Strength";
		disp_desc = "Sorting rotors accelerate calcium ion concentration\n"
			     "in the sarcoplasmic reticulum, increasing an agent's\n"
			     "muscle speed several-fold and multiplying the damage\n"
			     "they inflict in melee combat.\n\n"
			     "TECH ONE: The effectiveness of melee weapons is\n"
			     "increased slightly.\n\n"
			     "TECH TWO: The effectiveness of melee weapons is\n"
			     "increased moderately.\n\n"
			     "TECH THREE: The effectiveness of melee weapons is\n"
			     "increased significantly.\n\n"
			     "TECH FOUR: Melee weapons are almost instantly lethal.\n\n"
			     "Energy Rate: 50 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: after agent does not execute\n"
				   "successful melee attacks for a while, next\n"
				   "attack will be greatly empowered, either it is\n"
				   "a single hit or a rapid combination of attacks.\n";

		slots_cnt = 1;
		slots[0] = Arms;

		can_be_legendary = true;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("COMBSTR0");
		tex_on = TexMan.CheckForTexture("COMBSTR1");
	}

	// ------------------	
	// Internal functions
	// ------------------

	protected double getDamageFactor() { return 1 + 0.75 * getRealLevel(); }

	const lgbonus_cd = 35 * 15;
	int lgbonus_cd_timer;
	const lgbonus_time = 20;
	int lgbonus_timer;
	protected double getLegendaryDamageBonus() { return 4.5; }

	// ------
	// Events
	// ------

	override void tick()
	{
		super.tick();
		if(!owner)
			return;

		if(lgbonus_cd_timer > 0) --lgbonus_cd_timer;
		if(lgbonus_timer > 0) --lgbonus_timer;

		if(enabled)
		{
			Actor.Spawn("DD_CombatStrength_SmokeGFX", owner.pos + (0, 0, owner.height / 2) + RotateVector((owner.radius / 1.5, 0), owner.angle - 90) + (frandom(-3, 3), frandom(-3, 3), frandom(-1.5, 1.5))).A_ChangeVelocity(frandom(-0.5, 0.5), frandom(-0.5, 0.5), frandom(1, 4));
			Actor.Spawn("DD_CombatStrength_SmokeGFX", owner.pos + (0, 0, owner.height / 2) + RotateVector((-owner.radius / 1.5, 0), owner.angle - 90) + (frandom(-3, 3), frandom(-3, 3), frandom(-1.5, 1.5))).A_ChangeVelocity(frandom(-0.5, 0.5), frandom(-0.5, 0.5), frandom(1, 4));
		}
	}

	override void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled)
			return;

		// source is actually the victim that got hit by augmentation owner (player)
		if(RecognitionUtils.isHandToHandDamage(PlayerPawn(owner), inflictor, source, damageType, flags))
		{
			newDamage = damage * getDamageFactor();
			if(isLegendary()){
				if(lgbonus_cd_timer == 0)
					lgbonus_timer = lgbonus_time;
				if(lgbonus_timer > 0){
					newDamage = newDamage * getLegendaryDamageBonus();
				}
				lgbonus_cd_timer = lgbonus_cd;
			}
		}
	}
}

class DD_CombatStrength_SmokeGFX : Actor
{
	default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+NOTELEPORT

		XScale 0.2;
		YScale 0.2;

		Alpha 0.5;
		RenderStyle "Translucent";
	}

	states
	{
		Spawn:
			DDFX PQRST 2;
			Stop;
	}
}
