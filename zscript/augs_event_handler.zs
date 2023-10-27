class DD_AugsEventHandler : DD_EventHandlerBase
{
	SoundUtils snd_utils;
	RecognitionUtils recg_utils;
	DD_ModChecker mod_checker;
	DD_PatchChecker patch_checker;

	ui UI_Augs wnd_augs;

	DD_EventHandlerQueue queue;

	// Font for augs holder
	ui Font aug_ui_font;
	ui Font aug_ui_font_bold;
	ui Font aug_overlay_font_bold;

	array<Sector> dissipating_sectors; // for envinronmental resistance
	array<int> dissipating_damage;
	array<int> dissipating_timers;

	// For better ADS performance it keeps track of all projectiles on the map
	array<Actor> proj_list;

	override void playerSpawned(PlayerEvent e)
	{
		PlayerPawn plr = players[e.PlayerNumber].mo;
		DD_AugsHolder aughld = DD_AugsHolder(Inventory.Spawn("DD_AugsHolder"));
		queue.ui_init = false;
		if(plr.countInv("DD_AugsHolder") == 0)
			plr.addInventory(aughld);
		else
			aughld.destroy();
	}

	bool proj_damage_inflicted; // avoid stepping down more than one function
	override void WorldThingDamaged(WorldEvent e)
	{
		if(e.inflictor && e.inflictor.countInv("DD_ProjDamageMod"))
		{
			if(!proj_damage_inflicted){
				let moditem = DD_ProjDamageMod(e.inflictor.findInventory("DD_ProjDamageMod"));
				e.thing.DamageMobj(e.inflictor, e.inflictor, (moditem.mult - 1), e.damageType, e.damageFlags, e.damageAngle);
				proj_damage_inflicted = true;
			}
			else
				proj_damage_inflicted = false;
		}
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		if(e.thing.bMISSILE) proj_list.push(e.thing);
	}

	override void WorldThingDied(WorldEvent e)
	{
		if(e.thing.bMISSILE)
		{
			uint i = proj_list.find(e.thing);
			if(i != proj_list.size())
				proj_list.delete(i);
		}
	}


	override void renderUnderlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));
		if(aughld)
			aughld.drawUnderlay(e, DD_EventHandler(StaticEventHandler.Find("DD_EventHandler")));
	}
	override void renderOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));
		if(aughld)
			aughld.draw(e, DD_EventHandler(StaticEventHandler.Find("DD_EventHandler")), 301, 0);
	}


	override void networkProcess(ConsoleEvent e)
	{
		PlayerInfo plr = players[e.Player];
		if(!plr || !plr.mo)
			return;
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));

		if(e.name == "dd_togg_aug")
		{
			// Toggle augmentation (inverse it's current state)
			// Arguments: < augmentation slot / -1 to toggle everything on / -2 to toggle everything off>
			// (see DD_AugSlots enum)

			if(e.args[0] == -1){
				aughld.queueEnableAllAugs(); return;
			}
			else if(e.args[0] == -2){
				aughld.queueDisableAllAugs(); return;
			}

			if(e.args[0] < 0 || e.args[0] >= aughld.augs_slots){
				if(consoleplayer == e.player)
					console.printf("ERROR: Augmentation slot %d doesn't exist.",
							e.args[0]);
				return;
			}
			if(!aughld.augs[e.args[0]]){
				if(consoleplayer == e.player)
					console.printf("ERROR: No augmentation in this slot.");
				return;
			}

			aughld.queueToggleAug(e.args[0]);
		}
		else if(e.name == "dd_install_aug")
		{
			// Install augmentation
			// Arguments: < DD_AugsHolder.augs_toinstall slot (shown in UI, starting from 0 up) > < aug selection (1 - leftmost, 2 - rightmost)  >

			DD_Augmentation aug_obj;
			if(e.args[1] == 1)
				aug_obj = aughld.inv_augs[e.args[0]];
			else if(e.args[1] == 2)
				aug_obj = aughld.inv_augs2[e.args[0]];
			
			if(aug_obj && aughld.canInstallAug(aug_obj))
				aughld.queueInstallAug(aug_obj);
		}
		else if(e.name == "dd_upgrade_aug")
		{
			// Upgrade augmentation
			// Arguments: < DD_AugsHolder.augs slot >
			// (same slots as dd_togg_aug)

			DD_InventoryHolder hld = DD_InventoryHolder(plr.mo.findInventory("DD_InventoryHolder"));
			if(hld){
				DD_InventoryWrapper item = hld.findItem("DD_AugmentationUpgradeCanister");
				if(DD_AugmentationUpgradeCanister.canConsume(plr.mo, e.args[0])){
					aughld.augs[e.args[0]]._level++;
					--item.amount;
					if(item.amount <= 0)
						hld.removeItem(item);
				}
				else if(DD_AugmentationUpgradeCanisterLegendary.canConsume(plr.mo, e.args[0])){
					item = hld.findItem("DD_AugmentationUpgradeCanisterLegendary");
					aughld.augs[e.args[0]].legendary = true;
					--item.amount;
					if(item.amount <= 0)
						hld.removeItem(item);
				}
			}
		}
		else if(e.name == "dd_drop_aug")
		{
			// Drop augmentation
			// Arguments: < DD_AugsHolder.augs_toinstall slot >

			aughld.queueDropAug(e.args[0]);
		}
		else if(e.name == "dd_use_cell")
		{
			// Consume a bioelectric cell
			// Arguments: none
			DD_InventoryHolder hld = DD_InventoryHolder(plr.mo.findInventory("DD_InventoryHolder"));
			if(hld){
				DD_InventoryWrapper item = hld.findItem("DD_BioelectricCell");
				if(item)
					hld.useItem(item);
			}
		}

		// Augmentations-specific commands
		if(e.name == "dd_vdash")
		{
			DD_Aug_AgilityEnhancement agaug;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_AgilityEnhancement")
				{
					agaug = DD_Aug_AgilityEnhancement(aughld.augs[i]);
					switch(e.args[0])
					{
						case 0: agaug.queue.dashvel[0].x = agaug.getDashVel(); break;
						case 1: agaug.queue.dashvel[1].x = -agaug.getDashVel(); break;
						case 2: agaug.queue.dashvel[2].y = agaug.getDashVel(); break;
						case 3: agaug.queue.dashvel[3].y = -agaug.getDashVel(); break;
						case 4: agaug.queue.dashvel[4].z = agaug.getDashVel() * 0.25; break;
					}
					break;
				}
			}
		}
		else if(e.name == "dd_grip"){
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_AgilityEnhancement")
				{
					let aug = DD_Aug_AgilityEnhancement(aughld.augs[i]);
					if(e.args[0])	aug.queue.deacc = aug.getDecelerateFactor();
					else		aug.queue.deacc = 0.0;
					break;
				}
				else if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_SpeedEnhancement")
				{
					let aug = DD_Aug_SpeedEnhancement(aughld.augs[i]);
					if(e.args[0])	aug.queue.deacc = aug.getDecelerateFactor();
					else		aug.queue.deacc = 0.0;
					break;
				}
			}
		}
		else if(e.name == "dd_climb"){
			// 1st argument:
			// 0/1 - disable/enable wall climbing
			// 2-5 - start moving in a direction
			// 6-9 - stop moving in a direction
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_AgilityEnhancement")
				{
					let aug = DD_Aug_AgilityEnhancement(aughld.augs[i]);
					switch(e.args[0]){
						case 0: case 1:
							aug.climbing = e.args[0];
							break;
						case 2: case 3: case 4: case 5:
							aug.climb_move[e.args[0] - 2] = true;
							break;
						case 6: case 7: case 8: case 9:
							aug.climb_move[e.args[0] - 6] = false;
							break;
					}
					break;
				}
			}
		}
		else if(e.name == "dd_muscle"){
			// 1st argument: 0/1 - stop/start subduing a target
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_MicrofibralMuscle")
				{
					let aug = DD_Aug_MicrofibralMuscle(aughld.augs[i]);
					if(e.args[0]) aug.subdueStart();
					else aug.subdueEnd();
					break;
				}
			}
		}
		else if(e.name == "dd_drone"){
			DD_Aug_SpyDrone spyaug;
			for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i] is "DD_Aug_SpyDrone")
				{
					spyaug = DD_Aug_SpyDrone(aughld.augs[i]);
					if(spyaug.drone_actor && spyaug.drone_actor.health > 0)
					{
						switch(e.args[0])
						{
							case 0: spyaug.drone_actor.queueAccelerationX(double(e.args[1]) / 10000); break;
							case 1: spyaug.drone_actor.queueAccelerationY(double(e.args[1]) / 10000); break;
							case 2: spyaug.drone_actor.queueAccelerationZ(double(e.args[1]) / 10000); break;
							case 3: spyaug.drone_actor.queueTurnAngle((double)(e.args[1]) / 10000); break;
							case 4: spyaug.drone_actor.queueUse();
						}
					}
				}
			}
		}
	}

	override void consoleProcess(ConsoleEvent e) { _ConsoleProcess(e.name); }
	override void _ConsoleProcess(string e_name)
	{
		if(e_name == "dd_toggle_ui_augs")
		{
			let ddevh = DD_EventHandler(StaticEventHandler.Find("DD_EventHandler"));
			if(!ddevh.wnd_nav.child_wnd){
				ddevh.wndmgr.addWindow(ddevh, wnd_augs);
				ddevh.wnd_nav.child_wnd = wnd_augs;
				ddevh.wndmgr.addWindow(ddevh, ddevh.wnd_nav);
			}
		}
	}

	override void UiTick()
	{
		DD_AugsHolder aughld;
		if(players[consoleplayer].mo)
			aughld = DD_AugsHolder(players[consoleplayer].mo.findInventory("DD_AugsHolder"));
		if(!queue.ui_init)
		{
			let ddevh = DD_EventHandler(StaticEventHandler.Find("DD_EventHandler"));
			if(ddevh.wndmgr && aughld){
				queue.ui_init = true;
				aughld.UIInit();
				wnd_augs = new("UI_Augs");
				wnd_augs.UIInit();
			}
		}
		if(aughld)
			aughld.UITick();
	}
}

class DD_InputEventHandler : EventHandler
{
	override void onRegister()
	{
		SetOrder(1000);

		DD_InventoryHolder.addItemDescriptor("DD_BioelectricCell", 1, 1, 30, -1, 2, 0.8, "A bioelectric cell provides efficient storage of\nenergy in a form that can be utilized by a number of\ndifferent devices.");
		DD_InventoryHolder.addItemDescriptor("DD_AugmentationCanister", 1, 1, 3, 3.5, 0, 1.2, "An augmentation canister teems with nanoscale\nmecanocarbon ROM modules suspended in a carrier\nserum. When injected into a compatible host subject,\nthese modules augment an individual with\nextra-sapient abilities. For more information, please\nsee 'Face of the New Man' by Kelley Chance.");
		DD_InventoryHolder.addItemDescriptor("DD_AugmentationUpgradeCanisterLegendary", 1, 1, 2, 2, 0, 1.0, "An augmentation upgrade canister that was\nmanufactured in an unknown facility. There is no\nfactual information about it, only rumors. Some\nsay it came from a secret upgraded UC, some say\nit came from another planet, other say it came from\nthe future.");
		DD_InventoryHolder.addItemDescriptor("DD_AugmentationUpgradeCanister", 1, 1, 8, 2, 0, 1.0, "An augmentation upgrade canister contains highly\nspecific nanomechanisms that, when combined with\na previously programmed module, can increase the\nefficiency of an installed augmentation. Because no\nprogramming is required, upgrade canisters may be\nused by trained agents in the field with minimal risk.");
	}

	override bool inputProcess(InputEvent e)
	{
		DD_AugsHolder aughld;
		if(players[consoleplayer].mo)
			aughld = DD_AugsHolder(players[consoleplayer].mo.findInventory("DD_AugsHolder"));
		if(aughld)
			if(aughld.inputProcess(e))
				return true;
		return false;
	}
}
