class DD_MuscleToken : Inventory
{
	default
	{
		Inventory.MaxAmount 4;
	}
}
class DD_MoreMuscleToken : Inventory
{
}

class DD_Aug_MicrofibralMuscle : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}
	override int get_base_drain_rate(){ return 40; }

	override void install()
	{
		super.install();

		id = 19;
		disp_name = "Microfibral Muscle";
		disp_desc = "Muscle strength is amplified with ionic polymeric gel\n"
			    "myofibrils that allow the agent to:\n"
			    "- lift heavy objects (+use) and inflict damage by\n"
			    "throwing them (+attack).\n"
			    "- subdue foes (hold +use) and strangle them to death\n"
			    "(+attack) or throw them (+altattack).\n\n";

		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Maximum damage by throwing is %g.\nSubdue health limit is %d.\n\n", round((50 + (getRealLevel() - 1) * 100)), 150 + 150 * (getRealLevel() - 1));
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Maximum damage by throwing is %g.\nSubdue health limit is %d.\n\n", round((50 + (getRealLevel() - 1) * 100)), 150 + 150 * (getRealLevel() - 1));
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Maximum damage by throwing is %g.\nSubdue health limit is %d.\n\n", round((50 + (getRealLevel() - 1) * 100)), 150 + 150 * (getRealLevel() - 1));
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Maximum damage by throwing is %g.\nSubdue health limit is %d.\n\n", round((50 + (getRealLevel() - 1) * 100)), 150 + 150 * (getRealLevel() - 1));
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		legend_count = 2;
		legend_names[0] = "subdue health +400, subdue damage x3";
		legend_names[1] = "x2 throw damage, x2 throw distance";

		slots_cnt = 1;
		slots[0] = Arms;
	}

	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("MICMUSC0");
		tex_on = TexMan.checkForTexture("MICMUSC1");
	}

	override void toggle()
	{
		super.toggle();
		if(!enabled)
			owner.takeInventory("DD_MuscleToken", 999999);
	}

	Actor subdue_target;
	const subdue_range = 48;
	const subdue_off = 32;
	Weapon owner_last_weapon;
	protected clearscope bool canSubdue(Actor a)
	{
		return a.bISMONSTER && a.health <= 150 + 150 * (getRealLevel() - 1) + (legend_installed == 0 ? 400 : 0);
	}
	void subdueStart()
	{
		let pickup_tracer = new("DD_AimTracer");
		pickup_tracer.source = owner;
		vector3 dir = (Actor.AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
		pickup_tracer.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, dir, subdue_range + owner.radius, 0);
		if(pickup_tracer.hit_obj && canSubdue(pickup_tracer.hit_obj)){
			owner.giveInventory("DD_MuscleHolder", 1);
			let wep = DD_MuscleHolder(owner.findInventory("DD_MuscleHolder"));
			if(wep){
				owner_last_weapon = owner.player.readyWeapon;
				wep.Init(pickup_tracer.hit_obj, self, owner.player.readyWeapon);
				owner.player.pendingWeapon = wep;
				owner.player.mo.bringUpWeapon();
			}
			subdue_target = pickup_tracer.hit_obj;
		}
	}
	void subdueEnd()
	{
		if(subdue_target){
			subdue_target.bNOGRAVITY = false;
			subdue_target = null;
			if(owner_last_weapon){
				owner.player.pendingWeapon = owner_last_weapon;
				PlayerPawn(owner).bringUpWeapon();
			}
			owner.takeInventory("DD_MuscleHolder", 1);
		}
	}

	override void tick()
	{
		super.tick();
		if(!enabled)
			return;

		owner.takeInventory("DD_MuscleToken", 999999);
		owner.takeInventory("DD_MoreMuscleToken", 999999);
		owner.giveinventory("DD_MuscleToken", getreallevel());
		if(legend_installed == 1)
			owner.giveInventory("DD_MoreMuscleToken", 1);

		if(subdue_target){
			subdue_target.A_ChangeVelocity(0, 0, 0, CVF_REPLACE);
			double pit = owner.pitch > 0 ? min(65, owner.pitch) : max(-65, owner.pitch);
			vector3 dir = (Actor.AngleToVector(owner.angle, cos(pit)), -sin(pit));
			dir *= (subdue_off + owner.radius + subdue_target.radius);
			dir += (0, 0, owner.player.viewHeight * 0.8);
			subdue_target.warp(owner, dir.x, dir.y, dir.z, flags: WARPF_NOCHECKPOSITION | WARPF_ABSOLUTEOFFSET | WARPF_ABSOLUTEANGLE | WARPF_INTERPOLATE);

			subdue_target.triggerPainChance("None", true);
		}
	}

	override bool inputProcess(InputEvent e)
	{
		if(e.type == InputEvent.Type_KeyDown) {
			if(KeybindUtils.checkBind(e.keyscan, "+use")){
				let pickup_tracer = new("DD_AimTracer");
				pickup_tracer.source = owner;
				vector3 dir = (Actor.AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
				pickup_tracer.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, dir, subdue_range + owner.radius, 0);
				if(pickup_tracer.hit_obj && canSubdue(pickup_tracer.hit_obj))
					EventHandler.sendNetworkEvent("dd_muscle", 1);
			}
		}
		else if(e.type == InputEvent.Type_KeyUp)
			if(KeybindUtils.checkBind(e.keyscan, "+use")){
				if(subdue_target)
					EventHandler.sendNetworkEvent("dd_muscle", 0);
			}
		return false;
	}
}

class DD_MuscleHolder : Weapon
{
	Actor holding;
	DD_Aug_MicrofibralMuscle aug;
	Weapon owner_last_weapon;

	default
	{
		Weapon.SelectionOrder 1000;
		Weapon.SlotNumber 0;
		+Weapon.NOALERT;
	}

	void Init(Actor tohold, DD_Aug_MicrofibralMuscle aug, Weapon last_weapon)
	{
		holding = tohold;
		holding.bNOGRAVITY = true;
		self.aug = aug;
		owner_last_weapon = last_weapon;
	}
	action void Free(bool toss = false)
	{
		invoker.holding.bNOGRAVITY = false;
		Name cls = "DD_MuscleToken";
		let pickup_level = countinv(cls);
		double my_mass = DD_PickupHolder.getMass(invoker.holding);
		my_mass = max(0.5, my_mass); my_mass = min(10, my_mass);
		if(toss){
			vector3 dir = (Actor.AngleToVector(angle, cos(pitch)), -sin(pitch));
			dir *= (13 + 7 * pickup_level) / my_mass;
			dir *= (invoker.aug.legend_installed == 1 ? 2 : 1);
			invoker.holding.A_ChangeVelocity(dir.x, dir.y, dir.z, CVF_REPLACE);
			if(pickup_level > 0){
				invoker.holding.giveInventory("DD_PickupDamager", 1);
				invoker.aug.subdueEnd();
				let dmgr = DD_PickupDamager(invoker.holding.findInventory("DD_PickupDamager"));
				dmgr.thrower = self;
				dmgr.damage = (30 + (pickup_level - 1) * 60) * 2.7**(-((my_mass - 0.8)**2) / (2*0.6**2)) * (invoker.aug.legend_installed == 1 ? 2 : 1);
				dmgr.source = self;
				dmgr.init_vel = invoker.holding.vel;
			}
		}
		invoker.aug.subdueEnd();
	}
	action void SpawnHurtParticles()
	{
		for(uint i = 0; i < 9; ++i){
			double ang = frandom(0, 360), pit = frandom(0, 360);
			vector3 dir = (AngleToVector(ang, cos(pit)), -sin(pit));
			vector3 dir_vel = dir * frandom(0.3, 0.6);
			dir *= frandom(4, 9);
			dir += (0, 0, invoker.holding.height / 2);
			for(uint i = 0; i < 9; ++i){
				double div = i / 9. + 0.1;
				invoker.holding.A_SpawnParticle(0x00FF0000, flags: SPF_NOTIMEFREEZE, lifetime: 35, size: 5, xoff: dir.x, yoff: dir.y, zoff: dir.z, velx: dir_vel.x / div, vely: dir_vel.y / div, velz: dir_vel.z / div, accelx: dir_vel.x * -0.1, accely: dir_vel.y * -0.1, accelz: -0.8, startalphaf: 0.9);
			}
		}
	}

	action void End()
	{
		if(invoker.owner_last_weapon){
			invoker.owner.player.pendingWeapon = invoker.owner_last_weapon;
			PlayerPawn(invoker.owner).bringUpWeapon();
		}
		invoker.owner.takeInventory("DD_MuscleHolder", 1);
	}

	const pickup_off = 16;
	const pain_sound_delay_min = 15;
	const pain_sound_delay_max = 30;
	int pain_sound_delay;
	override void Tick()
	{
		super.Tick();
		if(!holding){
			End();
			destroy();
		}
		if(holding.health <= 0){
			owner.giveInventory("DD_PickupHolder", 1);
			let wep = DD_PickupHolder(owner.findInventory("DD_PickupHolder"));
			if(wep){
				wep.Init(holding, owner_last_weapon);
				wep.dont_fire = true;
				owner.player.pendingWeapon = wep;
				PlayerPawn(owner).bringUpWeapon();
				aug.owner_last_weapon = null;
				owner_last_weapon = null;
			}
			End();
		}
	}

	states
	{
		Ready:
			TNT1 A 1 A_WeaponReady();
			Loop;
		Deselect:
			TNT1 A 0 { End(); Free(); }
			Stop;
		Select:
			Goto Ready;
		Fire:
			TNT1 A 1 {
				if(--invoker.pain_sound_delay <= 0){
					let pickup_level = countinv("DD_MuscleToken");
					invoker.holding.DamageMobj(self, self, 17 + pickup_level * 11 * (invoker.aug.legend_installed == 0 ? 3 : 1), "None", DMG_FORCED | DMG_NO_PROTECT);
					SpawnHurtParticles();
					invoker.holding.A_StartSound(invoker.holding.PainSound, volume: 0.5);
					invoker.pain_sound_delay = random(pain_sound_delay_min, pain_sound_delay_max);
				}
			}
			TNT1 A 0 A_ReFire();
			goto Ready;
		AltFire:
			TNT1 A 0 { End(); Free(true); }
			Stop;
	}
}

