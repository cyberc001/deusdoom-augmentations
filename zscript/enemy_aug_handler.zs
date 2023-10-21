class DD_EnemyAugHandler : StaticEventHandler
{
	array<class<DD_Augmentation> > aug_pool;
	array<double> prob_pool;
	double prob_total;

	virtual void registerAugInPool(class<DD_Augmentation> cls, double prob)
	{
		aug_pool.push(cls); prob_pool.push(prob); prob_total += prob;
	}
	override void OnRegister()
	{
		registerAugInPool("DD_Aug_Cloak", 5);
		registerAugInPool("DD_Aug_AggressiveDefenseSystem", 6);
		registerAugInPool("DD_Aug_BallisticProtection", 10);
		registerAugInPool("DD_Aug_EnergyShield", 12);
		registerAugInPool("DD_Aug_CombatStrength", 16);
		registerAugInPool("DD_Aug_Regeneration", 8);
		registerAugInPool("DD_Aug_SpeedEnhancement", 12);
	}

	bool enabled;
	double aug_chance;
	double aug_chance_regress;
	double boss_aug_chance;
	double boss_aug_chance_regress;
	double level_chance;
	double level_chance_regress;
	double boss_level_chance;
	double boss_level_chance_regress;
	const aug_rerolls = 10;

	override void WorldLoaded(WorldEvent e)
	{
		enabled = CVar.getCVar("dd_enable_enemy_augs").getBool();

		aug_chance = CVar.getCVar("dd_enemy_aug_chance").getFloat();
		aug_chance_regress = CVar.getCVar("dd_enemy_aug_chance_regress").getFloat();
		boss_aug_chance = CVar.getCVar("dd_enemy_boss_aug_chance").getFloat();
		boss_aug_chance_regress = CVar.getCVar("dd_enemy_boss_aug_chance_regress").getFloat();
		level_chance = CVar.getCVar("dd_enemy_aug_level_chance").getFloat();
		level_chance_regress = CVar.getCVar("dd_enemy_aug_level_chance_regress").getFloat();
		boss_level_chance = CVar.getCVar("dd_enemy_boss_aug_level_chance").getFloat();
		boss_level_chance_regress = CVar.getCVar("dd_enemy_boss_aug_level_chance_regress").getFloat();

		if(aug_chance_regress > 0.95) aug_chance_regress = 0.95;
		if(boss_aug_chance_regress > 0.95) boss_aug_chance_regress = 0.95;
		if(level_chance_regress > 0.95) level_chance_regress = 0.95;
		if(boss_level_chance_regress > 0.95) level_chance_regress = 0.95;
	}

	virtual class<DD_Augmentation> pickAugFromPool()
	{
		double sum = 0;
		double r = frandom(0, prob_total);
		for(uint i = 0; i < aug_pool.size(); ++i)
		{
			if(sum < r && sum + prob_pool[i] >= r)
				return aug_pool[i];
			sum += prob_pool[i];
		}
		return null;
	}
	override void WorldThingSpawned(WorldEvent e)
	{
		if(enabled && e.thing.bISMONSTER && !(e.thing is "PlayerPawn"))
		{
			double chance = e.thing.bBOSS ? boss_aug_chance : aug_chance;
			DD_AugsHolder aughld = null;
			while(frandom(0, 1) <= chance)
			{
				if(!aughld){
					aughld = DD_AugsHolder(Inventory.Spawn("DD_AugsHolder"));
					e.thing.addInventory(aughld);
					e.thing.addInventory(DD_EnemyAugAI(DD_EnemyAugAI.Spawn("DD_EnemyAugAI")));
				}
				for(uint i = 0; i < aug_rerolls; ++i)
				{
					DD_Augmentation aug = DD_Augmentation(DD_Augmentation.Spawn(pickAugFromPool()));
					if(aug.getClassName() == "DD_Aug_CombatStrength" && !e.thing.MeleeState)
						continue;
					if(aug.getClassName() == "DD_Aug_GravitationalField" && !e.thing.MissileState)
						continue;
					if(aughld.installAug(aug))
					{
						double lchance = e.thing.bBOSS ? boss_level_chance : level_chance;
						while(frandom(0, 1) <= lchance)
						{
							if(aug._level >= aug.max_level)
								break;
							++aug._level;
							lchance *= e.thing.bBOSS ? boss_level_chance_regress : level_chance_regress;
						}
						break;
					}
				}
				chance *= e.thing.bBOSS ? boss_aug_chance_regress : aug_chance_regress;
			}
			if(aughld)
				if(e.thing.bBOSS)
					e.thing.giveInventory("DD_BioelectricEnergy", 100);
				else
					e.thing.giveInventory("DD_BioelectricEnergy", random(40, 100));
		}
	}	
}
