struct DD_BioelectricCell_Queue
{
	int cell_toconsume;
};

// Description:
// Main source of bioelectric energy needed to power up augmentations
class DD_BioelectricCell : DDItem
{
	DD_BioelectricCell_Queue queue;

	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 999999;

		Inventory.PickupMessage "Picked up a bioelectric cell.";
		Tag "Bioelectric cell";

		Scale 0.35;
	}

	states
	{
		Spawn:
			BCEL A -1;
			Stop;
	}


	int energy_value;

	override void BeginPlay()
	{
		energy_value = 25;
	}

	override void tick() // This should be static, but DD_EventHandler may become messy
	{
		super.tick();

		if(!self) // there is a strange crash sometimes
			return;

		while(queue.cell_toconsume > 0)
		{
			owner.GiveInventory("DD_BioelectricEnergy", 25); 
			SoundUtils.playStartSound("ui/aug/cell_use", owner);
			--queue.cell_toconsume;
		}
	}

	override bool use(bool pickup)
	{
		if(!pickup && owner)
			return queueConsume(PlayerPawn(owner), self);
		return false;
	}

	// ------------------
	// External functions
	// ------------------

	// Description:
	//	Queues trying to consume a bioelectrical cell from player's inventory
	//	to refill energy.
	// Arguments:
	//	plr - player's actor.
	//	cell_instance - instance of bioelectric cell class for queueing purposes.
	// Return value:
	//	false - no cells left or bioelectrical energy is full or cell instance is NULL.
	//	true - successfull queueing;
	static clearscope bool queueConsume(PlayerPawn plr, DD_BioelectricCell cell_instance)
	{
		DD_InventoryHolder hld = DD_InventoryHolder(plr.FindInventory("DD_InventoryHolder"));

		if(plr.countInv("DD_BioelectricEnergy") >= DD_BioelectricEnergy.max_energy)
			return false;
		if(!cell_instance)
			return false;
		if(!hld || !hld.findItem("DD_BioelectricCell"))
			return false;

		cell_instance.queue.cell_toconsume++;

		return true;
	}

	// Description:
	//	Tells whether a cell can be consumed or not (for UI).
	static ui bool canConsume(PlayerPawn plr)
	{
		DD_InventoryHolder hld = DD_InventoryHolder(plr.FindInventory("DD_InventoryHolder"));
		return plr.countInv("DD_BioelectricEnergy") < DD_BioelectricEnergy.max_energy
		    && hld && hld.findItem("DD_BioelectricCell");
	}
}
