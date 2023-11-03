class DD_ProgressionTracker : Inventory
{
	int points_cells;
	int points_upgrades;
	int points_upgrades_lgnd;
	int points_augs;

	const item_minvel = 0.8;
	const item_maxvel = 3.0;

	default
	{
		+DONTGIB;
	}


	override void travelled()
	{
		let hndl = DD_SpawnHandler(StaticEventHandler.find("DD_SpawnHandler"));

		givePoints(hndl.pointsamt_exit_lvl);
		double items_ratio = (hndl.prev_lvl_total_items == 0 ? 0 : double(hndl.prev_lvl_found_items) / hndl.prev_lvl_total_items);
		givePoints(items_ratio * DD_SpawnHandler.pointsamt_all_items);
		double secrets_ratio = (hndl.prev_lvl_total_secrets == 0 ? 0 : double(hndl.prev_lvl_found_secrets) / hndl.prev_lvl_total_secrets);
		givePoints(secrets_ratio * DD_SpawnHandler.pointsamt_all_secrets);
	}

	// ------------------
	// Internal functions
	// ------------------

	void givePoints(int amount)
	{
		points_augs += amount;
		if(owner is "PlayerPawn" && owner.countInv("DD_AugsHolder") > 0)
		{
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			bool plr_hasaugs = false;
			if(aughld.inv_augs.size() > 0 || aughld.inv_augs2.size() > 0)
				plr_hasaugs = true;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
				if(aughld.augs[i]){
					plr_hasaugs = true;
					break;
			}

			if(plr_hasaugs){
				points_cells += amount;
				points_upgrades += amount;
				points_upgrades_lgnd += amount;
			}
		}
	}

	protected void spawnItemActor(Actor ac, class<Actor> item, int amount)
	{
		vector3 spawnpos = ac.pos + (0, 0, ac.height/2);
		for(int i = 0; i < amount; ++i)
		{
			let itm = Spawn(item, spawnpos);
			vector2 velsign = (random(0, 1) ? 1 : -1, random(0, 1) ? 1 : -1);	
			itm.A_ChangeVelocity(frandom(item_minvel, item_maxvel) * velsign.x, frandom(item_minvel, item_maxvel) * velsign.y, 0);
			spawnpos.z += frandom(-0.1, 0.1);
		}
	}

	void trySpawnItemsActor(Actor ac)
	{
		let hndl = DD_SpawnHandler(StaticEventHandler.find("DD_SpawnHandler"));
		double pts_cell = DD_SpawnHandler.points_for_cell
				* hndl.points_global_mult
				* hndl.points_for_cell_mult;
		double pts_upgrade = DD_SpawnHandler.points_for_upgrade
				* hndl.points_global_mult
				* hndl.points_for_upgrade_mult;
		double pts_upgrade_lgnd = DD_SpawnHandler.points_for_upgrade_lgnd
				* hndl.points_global_mult
				* hndl.points_for_upgrade_lgnd_mult;
		double pts_aug = DD_SpawnHandler.points_for_aug
				* hndl.points_global_mult
				* hndl.points_for_aug_mult;

		if(points_cells >= pts_cell)
		{
			int amnt = points_cells / pts_cell;
			spawnItemActor(ac, "DD_BioelectricCell", amnt);
			points_cells -= amnt * pts_cell;
		}
		if(points_upgrades >= pts_upgrade)
		{
			int amnt = points_upgrades / pts_upgrade;
			spawnItemActor(ac, "DD_AugmentationUpgradeCanister", amnt);
			points_upgrades -= amnt * pts_upgrade;
		}
		if(points_upgrades_lgnd >= pts_upgrade_lgnd)
		{
			int amnt = points_upgrades_lgnd / pts_upgrade_lgnd;
			spawnItemActor(ac, "DD_AugmentationUpgradeCanisterLegendary", amnt);
			points_upgrades_lgnd -= amnt * pts_upgrade_lgnd;
		}

		bool plr_hasaugs = false;
		if(owner is "PlayerPawn" && owner.countInv("DD_AugsHolder") > 0)
		{
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			if(aughld.inv_augs.size() > 0 || aughld.inv_augs2.size() > 0)
				plr_hasaugs = true;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
				if(aughld.augs[i]){
					plr_hasaugs = true;
					break;
			}
		}
		Actor obj;
		ThinkerIterator it = ThinkerIterator.create();
		while(obj = Actor(it.next()))
		{
			if(obj is "DD_AugmentationCanister")
			{
				plr_hasaugs = true;
				break;
			}
		}

		if(!plr_hasaugs && points_augs >= pts_aug * DD_SpawnHandler.points_for_aug_first_ml)
		{
			int amnt = points_augs / (pts_aug * DD_SpawnHandler.points_for_aug_first_ml);
			spawnItemActor(ac, "DD_AugmentationCanister", amnt);
			points_augs -= amnt * (pts_aug * DD_SpawnHandler.points_for_aug_first_ml);
		}
		else if(plr_hasaugs && points_augs >= pts_aug)
		{
			int amnt = points_augs / pts_aug;
			spawnItemActor(ac, "DD_AugmentationCanister", amnt);
			points_augs -= amnt * pts_aug;
		}
	}
}

class DD_SpawnHandler : StaticEventHandler
{
	// -----------------------------------
	// Progression variables and constants
	// -----------------------------------

	// Multipliers for various events
	const pointsml_killed_hp = 0.2;
	const pointsml_killed_hp_boss = 0.1;

	// Constants for rewarding exiting a level
	const pointsamt_exit_lvl = 350;
	const pointsamt_all_items = 125;
	const pointsamt_all_secrets = 225;

	// Set amount of points needed to gain an item
	double points_global_mult;
	const points_for_cell = 300;
	double points_for_cell_mult;
	const points_for_upgrade = 2100;
	double points_for_upgrade_mult;
	const points_for_upgrade_lgnd = 12250;
	double points_for_upgrade_lgnd_mult;
	const points_for_aug = 4550;
	double points_for_aug_mult;
	const points_for_aug_first_ml = 0.05;

	// ---------------
	// Other variables
	// ---------------
	
	int prev_lvl_found_items;
	int prev_lvl_total_items;
	int prev_lvl_found_secrets;
	int prev_lvl_total_secrets;

	// Transfering items
	// Canisters:
	array<class<Inventory> > transfer_items;

	const item_minvel = 0.8;
	const item_maxvel = 3.0;

	override void onRegister()
	{
		points_global_mult = CVar.getCVar("dd_ptmult_global").getFloat();
		points_for_cell_mult = CVar.getCVar("dd_ptmult_cell").getFloat();
		points_for_upgrade_mult = CVar.getCVar("dd_ptmult_upgrade").getFloat();
		points_for_aug_mult = CVar.getCVar("dd_ptmult_aug").getFloat();
		setOrder(1001);
	}


	override void playerSpawned(PlayerEvent e)
	{
		PlayerPawn plr = players[e.PlayerNumber].mo;
		if(plr.countInv("DD_ProgressionTracker") == 0)
			plr.giveInventory("DD_ProgressionTracker", 1);

		while(transfer_items.size() > 0)
		{
			Inventory inv = Inventory(Inventory.Spawn(transfer_items[0]));
			inv.warp(plr, 0, 0, 0, 0, WARPF_NOCHECKPOSITION);
			vector2 velsign = (random(0, 1) ? 1 : -1, random(0, 1) ? 1 : -1);
			inv.A_ChangeVelocity(velsign.x * frandom(item_minvel, item_maxvel), velsign.y * frandom(item_minvel, item_maxvel));
			inv.bTHRUACTORS = true; // so it can't be picked up on first tick and break the game
			transfer_items.delete(0);
		}
	}

	override void NewGame()
	{
		transfer_items.clear();
	}

	// Tracking progression
	override void WorldThingDied(WorldEvent e)
	{
		if(!e.thing.bISMONSTER || e.thing is "PlayerPawn")
			return;

		for(uint i = 0; i < MAXPLAYERS; ++i)
		{
			if(!playeringame[i])
				continue;

			PlayerPawn plr = players[i].mo;
			let tr = DD_ProgressionTracker(plr.findInventory("DD_ProgressionTracker"));
			if(!tr){
				tr = DD_ProgressionTracker(Inventory.Spawn("DD_ProgressionTracker"));
				plr.addInventory(tr);
			}
				
			if(tr)
			{
				// Giving points for a monster dying
				if(e.thing.bBOSS)
					tr.givePoints(e.thing.getSpawnHealth() * pointsml_killed_hp_boss);
				else
					tr.givePoints(min(e.thing.getSpawnHealth() * pointsml_killed_hp, 50));

				tr.trySpawnItemsActor(e.thing);
			}
		}
	}

	override void WorldLoaded(WorldEvent e)
	{
		points_global_mult = CVar.getCVar("dd_ptmult_global").getFloat();
		points_for_cell_mult = CVar.getCVar("dd_ptmult_cell").getFloat();
		points_for_upgrade_mult = CVar.getCVar("dd_ptmult_upgrade").getFloat();
		points_for_upgrade_lgnd_mult = CVar.getCVar("dd_ptmult_upgrade_lgnd").getFloat();
		points_for_aug_mult = CVar.getCVar("dd_ptmult_aug").getFloat();
	}
	override void WorldUnloaded(WorldEvent e)
	{
		points_global_mult = CVar.getCVar("dd_ptmult_global").getFloat();
		points_for_cell_mult = CVar.getCVar("dd_ptmult_cell").getFloat();
		points_for_upgrade_mult = CVar.getCVar("dd_ptmult_upgrade").getFloat();
		points_for_upgrade_lgnd_mult = CVar.getCVar("dd_ptmult_upgrade_lgnd").getFloat();
		points_for_aug_mult = CVar.getCVar("dd_ptmult_aug").getFloat();

		if(e.isSaveGame)
			return;

		prev_lvl_found_items = level.found_items;
		prev_lvl_total_items = level.total_items;
		prev_lvl_found_secrets = level.found_secrets;
		prev_lvl_total_secrets = level.total_secrets;

		// Carrying all unpickuped augmentation canisters to the next level
		bool transfer_augcans = CVar.getCVar("dd_transfer_augcanisters").getFloat();
		bool transfer_upgrcans = CVar.getCVar("dd_transfer_upgradecanisters").getFloat();
		bool transfer_upgrcans_lgnd = CVar.getCVar("dd_transfer_upgradecanisters_lgnd").getFloat();

		Actor obj;
		ThinkerIterator it = ThinkerIterator.create();
		while(obj = Actor(it.next())){
			if(!(obj is "Inventory") || Inventory(obj).owner)
				continue;
			if((transfer_augcans && obj is "DD_AugmentationCanister")
			|| (transfer_upgrcans && obj is "DD_AugmentationUpgradeCanister")
			|| (transfer_upgrcans_lgnd && obj is "DD_AugmentationUpgradeCanisterLegendary"))
				transfer_items.push((class<Inventory>)(obj.GetClass()));
		}
	}
}
