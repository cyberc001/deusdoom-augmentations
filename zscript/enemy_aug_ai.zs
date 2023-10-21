// Description:
// A class that toggles augmentations spawned on enemies.

class DD_EnemyAugAI : Inventory
{
	default
	{
		+THRUACTORS;	// prevents being picked up at (0; 0)
	}

	virtual void tryEnableAug(DD_AugsHolder aughld, string aug_class) {
		for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			if(aughld.augs[i] && aughld.augs[i].getClassName() == aug_class
				&& !aughld.augs[i].enabled)
				aughld.augs[i].toggle();
	}
	virtual void tryDisableAug(DD_AugsHolder aughld, string aug_class)
	{
		for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			if(aughld.augs[i] && aughld.augs[i].getClassName() == aug_class
				&& aughld.augs[i].enabled)
				aughld.augs[i].toggle();
	}

	const cloak_health_thres = 0.42;
	const cloak_bioel_thres = 15;
	const cloak_sight_time = 170;
	int cloak_sight_timer;

	const ads_time = 75;
	int ads_timer;

	const resist_time = 140;
	int resist_ballistic_timer;
	int resist_eshield_timer;

	const combat_strength_bonus_dist = 180;

	const grav_field_bioel_thres = 25;
	const grav_field_bonus_dist = 220;

	const speed_bioel_thres = 30;
	const speed_far_dist = 600;

	override void Tick()
	{
		super.Tick();
		if(!owner)
			return;

		if(owner is "PlayerPawn" || owner.health <= 0)
		{
			self.destroy();
			return;
		}

		DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		int bioel = owner.countInv("DD_BioelectricEnergy");

		// ---- CLOAK ----
		// Cloak when in sight of a player for a few seconds
		if(cloak_sight_timer < cloak_sight_time){
			if(owner.target && owner.target.CheckSight(owner, SF_IGNOREVISIBILITY))
			{
				if(bioel > cloak_bioel_thres * 1.5)
					tryEnableAug(aughld, "DD_Aug_Cloak");
				else
					tryDisableAug(aughld, "DD_Aug_Cloak");
				++cloak_sight_timer;
			}
			else
				tryDisableAug(aughld, "DD_Aug_Cloak");
		}
		else if(cloak_sight_timer == cloak_sight_time)
		{
			tryDisableAug(aughld, "DD_Aug_Cloak");
			++cloak_sight_timer;
		}
		// Cloak when low on health, but not too low on energy
		if(owner.health <= owner.getMaxHealth() * cloak_health_thres
			&& bioel > cloak_bioel_thres)
			tryEnableAug(aughld, "DD_Aug_Cloak");
		if(bioel <= cloak_bioel_thres)
			tryDisableAug(aughld, "DD_Aug_Cloak");

		// ---- ADS ----
		// Enable ADS for some time when facing the target
		if(ads_timer > 0)
			--ads_timer;
		else if(ads_timer == 0){
			tryDisableAug(aughld, "DD_Aug_AggressiveDefenseSystem");
			--ads_timer;
		}
		if(owner.target && owner.target.CheckSight(owner, SF_IGNOREVISIBILITY))
		{
			ads_timer = ads_time;
			tryEnableAug(aughld, "DD_Aug_AggressiveDefenseSystem");
		}
		// ---- Ballistic protection ----
		// If hit by ballistic damage (see ownerDamageTaken()), enable for a few seconds
		if(resist_ballistic_timer > 0){
			tryEnableAug(aughld, "DD_Aug_BallisticProtection");
			--resist_ballistic_timer;
		}
		else if(resist_ballistic_timer == 0){
			--resist_ballistic_timer;
			tryDisableAug(aughld, "DD_Aug_BallisticProtection");
		}

		// ---- Energy shield ----
		// If hit by energy damage (see ownerDamageTaken()), enable for a few seconds
		if(resist_eshield_timer > 0){
			tryEnableAug(aughld, "DD_Aug_EnergyShield");
			--resist_eshield_timer;
		}
		else if(resist_eshield_timer == 0){
			--resist_eshield_timer;
			tryDisableAug(aughld, "DD_Aug_EnergyShield");
		}

		double target_dist = owner.target ? owner.Distance2D(owner.target) : 0;

		// ---- Combat strength ----
		// Activate when in melee range of a player
		if(owner.MeleeState)
		{
			if(owner.target && target_dist <= owner.MeleeRange + owner.Radius + combat_strength_bonus_dist)
				tryEnableAug(aughld, "DD_Aug_CombatStrength");
			else
				tryDisableAug(aughld, "DD_Aug_CombatStrength");
		}

		// ---- Gravitational field ----
		// Enable if there is a ranged attack and a player is nearby (and in line of sight)
		bool gravf_enabled = false;
		if(owner.MissileState)
		{
			if(owner.target && owner.CheckSight(owner.target) && target_dist <= owner.MeleeRange + owner.Radius + grav_field_bonus_dist && bioel > grav_field_bioel_thres){
				tryEnableAug(aughld, "DD_Aug_GravitationalField");
				gravf_enabled = true;
			}
			else
				tryDisableAug(aughld, "DD_Aug_GravitationalField");
		}

		// ---- Regeneration ----
		// Enable if low on health, threshold depending on amount of bioelectric energy possessed
		if(double(owner.health) / owner.getMaxHealth() <= (bioel / 100.) ** (1./3))
			tryEnableAug(aughld, "DD_Aug_Regeneration");
		else
			tryDisableAug(aughld, "DD_Aug_Regeneration");

		// ---- Speed Enhancement ----
		// Enable if a) there is no missile state and not in range of a player
		//			 b) the player is too far and bioelectric energy reserve is high enough
		//			 c) not attacking and bioelectric energy reserve is high enough
		if(owner.target
			&& (owner.target.CheckSight(owner, SF_IGNOREVISIBILITY) || target_dist > speed_far_dist)
			&& (!owner.MissileState || target_dist > speed_far_dist || (owner.curstate != owner.MissileState && owner.curstate != owner.MeleeState && bioel > speed_bioel_thres)))
			tryEnableAug(aughld, "DD_Aug_SpeedEnhancement");
		else
			tryDisableAug(aughld, "DD_Aug_SpeedEnhancement");
	}

	override void ModifyDamage(int damage, Name damageType, out int newdamage, bool passive, Actor inflictor, Actor source, int flags)
	{
		if(passive)
		{
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			double protfact_ml; // not used, but required by RecognitionUtils functions

			if(RecognitionUtils.damageIsBallistic(inflictor, source, damageType, flags, protfact_ml))
				resist_ballistic_timer = resist_time;
			if(RecognitionUtils.damageIsEnergy(inflictor, source, damageType, flags, protfact_ml))
				resist_eshield_timer = resist_time;
		}
	}
}

