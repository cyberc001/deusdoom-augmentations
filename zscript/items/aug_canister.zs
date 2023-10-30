class DD_AugmentationCanister : DDItem
{
	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 400;

		Inventory.PickupMessage "Picked up an augmentation canister.";
		Tag "Augmentation cannister";

		Scale 0.4;
		+DONTGIB;
	}
	states
	{
		Spawn:
			AGCN ABCDEFGHIJKLMNOPQRSTUVWXYZ 1;
			AGCO ABCDEFGH 1;
			Loop;
	}

	DD_Augmentation aug; // used when dropping augs from inventory to retain the same augs
	DD_Augmentation aug2;

	override bool shouldCreateTossable() // handle dropping from inventory
	{
		DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(aughld && aughld.inv_augs.size()){
			DD_AugmentationCanister todrop = DD_AugmentationCanister(Inventory.Spawn("DD_AugmentationCanister"));
			todrop.bTHRUACTORS = true;
			todrop.aug = aughld.inv_augs[0];
			todrop.aug2 = aughld.inv_augs2[0];

			todrop.warp(aughld.owner, 0.0, 0.0, aughld.owner.player.viewHeight, 0.0, WARPF_NOCHECKPOSITION);
			vector3 owner_look = (AngleToVector(aughld.owner.angle, cos(aughld.owner.pitch)), -sin(aughld.owner.pitch));
			owner_look *= aughld.dropped_items_svel;
			todrop.A_ChangeVelocity(owner_look.x, owner_look.y, owner_look.z);

			aughld.inv_augs.delete(0);
			aughld.inv_augs2.delete(0);
		}
		return false;
	}

	// -------------
	// Engine events
	// -------------

	// 0 - success
	// 1 - out of augmentation slots, cease
	// 2 - other error (being picked up by a non-player), ignore event
	// 3 - reroll
	int roll_augs(DD_AugmentationCanister realself, Actor other, array<class<DD_Augmentation> > aug_pool)
	{
		if(!(other is "PlayerPawn"))
			return 2;

		PlayerPawn plr = PlayerPawn(other);
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));
		if(!aughld)
			return 3;

		if(realself.aug){ // dropped from a player's inventory - no need to roll for augs
			aughld.inv_augs.push(realself.aug);
			aughld.addInventory(realself.aug);
			aughld.inv_augs2.push(realself.aug2);
			aughld.addInventory(realself.aug2);
			return 0;
		}

		DD_AugSlots slot;

		uint installed_aug_cnt = 0;
		// Counting amount of augmentations installed
		for(uint i = 1; i < aughld.augs_slots; ++i)
		{
			if(aughld.augs[i])
				++installed_aug_cnt;
		}
		if(aughld.inv_augs.size() + installed_aug_cnt >= aughld.augs_slots - 1) // can't fit more augmentations!
			return 1; //we ignore light slot for now

		DD_Augmentation.shuffleAugPool(aug_pool);

		// Rolling for a random slot
		int slot_max_taken; // maximum augmentations that can take this slot
		int slot_taken; // amount of augmentations that can currently take this slot
				 // (available to install)
		while(true)
		{
			slot = random(Subdermal1, Torso3);

			// Checking if this slot is occupied
			if(aughld.augs[slot])
				continue;

			slot_max_taken = 1;
			// This is crap, the system with slots should probably at least have this
			// as a separate function
			if(slot == Subdermal1 || slot == Subdermal2)
				slot_max_taken = 2;
			else if(slot == Torso1 || slot == Torso2 || slot == Torso3)
				slot_max_taken = 3;
			for(uint i = 1; i < aughld.augs_slots; ++i)
			{
				if(aughld.augs[i]){
					for(uint j = 0; j < aughld.augs[i].slots_cnt; ++j)
					{
						if(aughld.augs[i].slots[j] == slot){
							// For each installed augmentation that fits this slot
							// maximum amount of augmentations available for this
							// slot goes down by 1
							slot_max_taken--;
							break;
						}
					}
				}
			}

			slot_taken = 0;
			for(uint i = 0; i < aughld.inv_augs.size(); ++i)
			{
				// we trust that both inv_augs and 2 contain augmentations for 1 slot
				for(uint j = 0; j < aughld.inv_augs[i].slots_cnt; ++j)
				{
					if(aughld.inv_augs[i].slots[j] == slot){
						slot_taken++;
						break;
					}
				}
			}

			if(slot_taken >= slot_max_taken)
				continue;

			break;
		}

		uint aug_i = 0;
		uint dup_amount = 0; // Amount of duplicated agumentations.
				     // if this exceeds 2, then they'll be rerolled
				     // (unusable canister).
		for(uint i = 0; i < aug_pool.size() && aug_i < 2; ++i)
		{
			DD_Augmentation aug_obj = DD_Augmentation(Inventory.Spawn(aug_pool[i]));
			aug_obj.install();

			// Checking if this augmentation class can be installed in this slot
			bool aug_obj_in_slot = false;
			for(uint i = 0; i < aug_obj.slots_cnt; ++i){
				if(aug_obj.slots[i] == slot){
					aug_obj_in_slot = true;
					break;
				}
			}
			if(!aug_obj_in_slot){
				aug_obj.destroy();
				continue;
			}

			// Checking for dupes in installed augmentations
			bool found_dup = false;
			for(uint i = 0; i < aughld.augs_slots; ++i)
			{
				if(aughld.augs[i] && aughld.augs[i].id == aug_obj.id){
					++dup_amount;
					found_dup = true;
					break;
				}
			}
			if(!found_dup)
			{ // Checking for dupes in available augmentations
				for(uint i = 0; i < aughld.inv_augs.size(); ++i)
				{
					if(!aughld.inv_augs[i])
						continue;
					if(aughld.inv_augs[i].id == aug_obj.id){
						++dup_amount;
						found_dup = true;
						break;
					}
				}
				if(!found_dup)
				{
					for(uint i = 0; i < aughld.inv_augs2.size(); ++i)
					{
						if(!aughld.inv_augs2[i])
							continue;
						if(aughld.inv_augs2[i].id == aug_obj.id){
							++dup_amount;
							found_dup = true;
							break;
						}
					}
				}
			}


			if(aug_i == 0){
				aughld.inv_augs.push(aug_obj);
				aughld.addInventory(aug_obj);
			}
			else{
				aughld.inv_augs2.push(aug_obj);
				aughld.addInventory(aug_obj);
			}
			++aug_i;
		}

		if(aug_i == 2){
			if(dup_amount == 2){
				aughld.inv_augs[aughld.inv_augs.size()-1].detachFromOwner();
				aughld.inv_augs[aughld.inv_augs.size()-1].destroy();
				aughld.inv_augs.delete(aughld.inv_augs.size()-1);
				aughld.inv_augs2[aughld.inv_augs2.size()-1].detachFromOwner();
				aughld.inv_augs2[aughld.inv_augs2.size()-1].destroy();
				aughld.inv_augs2.delete(aughld.inv_augs2.size()-1);
				return 3;
			}
			realself.aug = aughld.inv_augs[aughld.inv_augs.size()-1];
			realself.aug2 = aughld.inv_augs2[aughld.inv_augs2.size()-1];
			return 0;
		}
		else{
			if(aug_i == 1){
				aughld.inv_augs[aughld.inv_augs.size()-1].detachFromOwner();
				aughld.inv_augs[aughld.inv_augs.size()-1].destroy();
				aughld.inv_augs.delete(aughld.inv_augs.size()-1);
			}
			return 3;
		}
	}

	override void AttachToOwner(Actor other)
	{
		array<class<DD_Augmentation> > aug_pool;
		DD_Augmentation.initAugPool(aug_pool);
		while(1){
			int res = roll_augs(self, other, aug_pool);
			if(res == 0)
				break;
			else if(res == 1){
				A_Remove(AAPTR_DEFAULT);
				return;
			}
			else if(res == 2)
				return;
		}
		super.AttachToOwner(other);
	}
	override bool HandlePickup(Inventory item)
	{
		if(!(item is "DD_AugmentationCanister"))
			return false;

		let nitem = DD_AugmentationCanister(item);
		array<class<DD_Augmentation> > aug_pool;
		DD_Augmentation.initAugPool(aug_pool);
		while(1){
			int res = roll_augs(nitem, self.owner, aug_pool);
			if(res == 0)
				break;
			else if(res == 1){
				self.master = item;
				A_RemoveMaster(RMVF_EVERYTHING);
				return false;
			}
			else if(res == 2)
				return false;
		}

		return super.HandlePickup(item);
	}

	override bool CanPickup(Actor toucher)
	{
		if(!(toucher is "PlayerPawn"))
			return false;

		PlayerPawn plr = PlayerPawn(toucher);
		DD_AugsHolder aughld = DD_AugsHolder(plr.findInventory("DD_AugsHolder"));
		uint installed_aug_cnt = 0;
		for(uint i = 1; i < aughld.augs_slots; ++i)
		{
			if(aughld.augs[i])
				++installed_aug_cnt;
		}
		if(aughld.inv_augs.size() + installed_aug_cnt >= aughld.augs_slots - 1) // can't fit more augmentations!
			return false;

		return true;
	}
}
