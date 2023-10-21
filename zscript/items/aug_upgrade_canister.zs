struct DD_AugmentationUpgradeCanister_Queue
{
	array<int> toupgrade;
};

class DD_AugmentationUpgradeCanister : DDItem
{
	DD_AugmentationUpgradeCanister_Queue queue;

	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 8;

		Inventory.PickupMessage "Picked up an augmentation upgrade canister.";
		Tag "Augmentation upgrade cannister";

		Scale 0.4;

		+DONTGIB;
	}

	states
	{
		Spawn:
			AUCN A -1;
			Stop;
	}

	override void Tick()
	{
		super.tick();
		if(!self || !owner) // there is a strange crash sometimes
			return;

		DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));

		while(queue.toupgrade.size() > 0)
		{
			if(aughld.augs[queue.toupgrade[0]]._level < aughld.augs[queue.toupgrade[0]].max_level)
			{	
				DD_InventoryHolder hld = DD_InventoryHolder(owner.findInventory("DD_InventoryHolder"));
				if(hld){
					DD_InventoryWrapper item = hld.findItem("DD_AugmentationUpgradeCanister");
					if(item){
						aughld.augs[queue.toupgrade[0]]._level++;
						--item.amount;
						if(item.amount <= 0)
							hld.removeItem(item);
					}
				}
			}
			queue.toupgrade.Delete(0);
		}
	}

	override bool use(bool pickup)
	{
		return false;
	}

	// ------------------
	// External functions
	// ------------------

	// Description:
	//	Tells whether an augmentation canister can be consumed or not 
	static clearscope bool canConsume(PlayerPawn plr, int aug_slot)
	{
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));
		DD_InventoryHolder hld = DD_InventoryHolder(plr.findInventory("DD_InventoryHolder"));
		if(hld){
			DD_InventoryWrapper item = hld.findItem("DD_AugmentationUpgradeCanister");
			if(!item)
				return false;
		}

		return aug_slot > -1
		    && aughld.augs[aug_slot]
		    && aughld.augs[aug_slot]._level < aughld.augs[aug_slot].max_level;
	}
}
