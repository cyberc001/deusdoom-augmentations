class DD_AugmentationUpgradeCanisterLegendary : DD_AugmentationUpgradeCanister
{
	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 4;

		Inventory.PickupMessage "Picked up a legendary augmentation upgrade canister.";
		Tag "Legendary augmentation upgrade cannister";

		Scale 0.4;

		+DONTGIB;
	}

	states
	{
		Spawn:
			AULC A -1;
			Stop;
	}

	override void Tick()
	{
		if(!self || !owner){ // there is a strange crash sometimes
			super.tick();
			return;
		}

		DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));

		while(queue.toupgrade.size() > 0)
		{
			if(aughld.augs[queue.toupgrade[0]]._level >= aughld.augs[queue.toupgrade[0]].max_level
			&& !aughld.augs[queue.toupgrade[0]].legendary)
			{
				owner.TakeInventory("DD_AugmentationUpgradeCanisterLegendary", 1);
				aughld.augs[queue.toupgrade[0]].legendary = true;
				aughld.augs[queue.toupgrade[0]].disp_desc = aughld.augs[queue.toupgrade[0]].disp_desc .. aughld.augs[queue.toupgrade[0]].disp_legend_desc;
			}
			queue.toupgrade.Delete(0);
		}
		super.tick();
	}


	// ------------------
	// External functions
	// ------------------

	// Description:
	//	Queues trying to consume a legendary upgrade canister from player's inventory
	//	to upgrade an augmentation.
	// Arguments:
	//	plr - player's actor.
	//	cnst_instance - instance of upgrade canister class for queueing purposes
	//	aug_slot - augmentation slot to upgrade.
	// Return value:
	//	false - no canisters left or augmentation is already legendary upgraded or it is not at max level
	//		or there is no augmentation in this slot or canister instance is NULL.
	//	true - successfull queueing;
	static clearscope bool queueConsume(PlayerPawn plr, DD_AugmentationUpgradeCanisterLegendary cnst_instance, int aug_slot)
	{
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));

		if(aug_slot <= -1)
			return false;
		if(!aughld.augs[aug_slot])
			return false;
		if(aughld.augs[aug_slot]._level < aughld.augs[aug_slot].max_level)
			return false;
		if(aughld.augs[aug_slot].legendary)
			return false;
		if(!aughld.augs[aug_slot].can_be_legendary)
			return false;
		if(!cnst_instance)
			return false;
		if(plr.countInv("DD_AugmentationUpgradeCanisterLegendary") < cnst_instance.queue.toupgrade.size())
			return false;

		cnst_instance.queue.toupgrade.push(aug_slot);

		return true;
	}

	// Description:
	//	Tells whether a legendary augmentation canister can be consumed or not
	static clearscope bool canConsume(PlayerPawn plr, int aug_slot)
	{
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));
		DD_InventoryHolder hld = DD_InventoryHolder(plr.findInventory("DD_InventoryHolder"));
		if(hld){
			DD_InventoryWrapper item = hld.findItem("DD_AugmentationUpgradeCanisterLegendary");
			if(!item)
				return false;
		}

		return aug_slot > -1
		    && aughld.augs[aug_slot]
		    && aughld.augs[aug_slot]._level >= aughld.augs[aug_slot].max_level
		    && !aughld.augs[aug_slot].legendary
		    && aughld.augs[aug_slot].can_be_legendary;
	}
}
