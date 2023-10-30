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
			     "they inflict in melee combat.\n\n";
		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Damage bonus is %g%%.\n\n", (getDamageFactor() - 1) * 100);
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Damage bonus is %g%%.\n\n", (getDamageFactor() - 1) * 100);
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Damage bonus is %g%%.\n\n", (getDamageFactor() - 1) * 100);
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Damage bonus is %g%%.\n\n", (getDamageFactor() - 1) * 100);
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		legend_count = 4;
		legend_names[0] = "one much stronger attack on cooldown";
		legend_names[1] = "cleave damage on attack";
		legend_names[2] = "stacking damage against one target";
		legend_names[3] = "one-shots sprees increase damage";

		slots_cnt = 1;
		slots[0] = Arms;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("COMBSTR0");
		tex_on = TexMan.CheckForTexture("COMBSTR1");
	}

	protected double getDamageFactor() { return 1 + 0.4 * getRealLevel() + (legend_installed == 0 && bonus_timer <= 0 ? 4 : 0) + stack_mul; }

	override void toggle()
	{
		super.toggle();
		if(!enabled)
			stack_mul = 0;
	}

	override void tick()
	{
		super.tick();
		if(legend_installed == 0)
			hud_info = string.format("%.1g", bonus_timer / 35.);
		else if(legend_installed == 2 || legend_installed == 3)
			hud_info = (stack_mul > 0 ? string.format("+x%.2g", stack_mul) : "");

		if(legend_installed == 2 && !stack_victim)
			stack_mul = 0;

		if(!owner)
			return;

		if(enabled)
		{
			if(bonus_timer > 0)
				--bonus_timer;

			Actor.Spawn("DD_CombatStrength_SmokeGFX", owner.pos + (0, 0, owner.height / 2) + RotateVector((owner.radius / 1.5, 0), owner.angle - 90) + (frandom(-3, 3), frandom(-3, 3), frandom(-1.5, 1.5))).A_ChangeVelocity(frandom(-0.5, 0.5), frandom(-0.5, 0.5), frandom(1, 4));
			Actor.Spawn("DD_CombatStrength_SmokeGFX", owner.pos + (0, 0, owner.height / 2) + RotateVector((-owner.radius / 1.5, 0), owner.angle - 90) + (frandom(-3, 3), frandom(-3, 3), frandom(-1.5, 1.5))).A_ChangeVelocity(frandom(-0.5, 0.5), frandom(-0.5, 0.5), frandom(1, 4));
		}
	}

	int bonus_timer;
	const bonus_cd = 35 * 10;

	bool cleave_now; // avoiding infinite recursion
	const cleave_radius = 280;
	const cleave_angle = 90;
	const cleave_pitch = 40;

	double stack_mul;
	Actor stack_victim;
	const stack_mul_inc = 0.5;
	const stack_mul_dim = 4; // determines severity of diminishing returns
	// same stacking but different numbers for upgrade 4
	const os_stack_mul_inc = 0.6;
	const os_stack_mul_dim = 3;

	void doCleaveGFX()
	{
		for(double ang = -cleave_angle/2; ang <= cleave_angle/2; ang += cleave_angle / 8){
			for(double pit = -cleave_pitch/2; pit <= cleave_pitch/2; pit += cleave_pitch / 8){
				vector3 vel = (Actor.AngleToVector(ang + owner.angle, cos(pit + owner.pitch)), -sin(pit + owner.pitch));
				vel *= 15;
				vel += (frandom(-0.2, 0.2), frandom(-0.2, 0.2), frandom(-0.2, 0.2));
				owner.A_SpawnParticle(0xFFFFFFFF, 0, lifetime: 15, size: 4,
						zoff: owner.player.viewHeight,
						velx: vel.x, vely: vel.y, velz: vel.z);
			}
		}
	}

	override void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor victim, int flags)
	{
		if(!enabled || cleave_now)
			return;

		if(RecognitionUtils.isHandToHandDamage(PlayerPawn(owner), inflictor, victim, damageType, flags))
			newDamage = damage * getDamageFactor();
		else
			return;

		if(legend_installed == 0 && bonus_timer <= 0)
			bonus_timer = bonus_cd;
		else if(legend_installed == 1){
			cleave_now = true;
			doCleaveGFX();
			let it = BlockThingsIterator.create(owner, owner.radius + cleave_radius);
			while(it.next()){
				if(!it.thing.bSHOOTABLE || it.thing == owner || it.thing.bFRIENDLY || it.thing == victim)
					continue;
				double d_ang = AbsAngle(owner.AngleTo(it.thing), owner.angle);
				double d_pitch = AbsAngle(owner.PitchTo(it.thing), owner.pitch);
				if(d_ang <= cleave_angle && d_pitch <= cleave_pitch)
					it.thing.DamageMobj(owner, owner, damage, damageType);
			}
			cleave_now = false;
		}
		else if(legend_installed == 2){
			if(victim != stack_victim){
				stack_victim = victim;
				stack_mul = 0;
			}
			stack_mul += stack_mul_inc * max(1 - stack_mul / stack_mul_dim, 0);
		}
		else if(legend_installed == 3){
			if(damage < victim.health)
				stack_mul = 0;
			else
				stack_mul += os_stack_mul_inc * max(1 - stack_mul / os_stack_mul_dim, 0);
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
