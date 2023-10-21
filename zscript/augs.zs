#include "zscript/augs/ballistic_protection.zs"
#include "zscript/augs/gravitational_field.zs"
#include "zscript/augs/cloak.zs"
#include "zscript/augs/radar_transparency.zs"

#include "zscript/augs/combat_strength.zs"
#include "zscript/augs/microfibral_muscle.zs"

#include "zscript/augs/speed_enhancement.zs"
#include "zscript/augs/agility_enhancement.zs"

#include "zscript/augs/energy_shield.zs"
#include "zscript/augs/environmental_resistance.zs"
#include "zscript/augs/power_recirculator.zs"
#include "zscript/augs/regeneration.zs"
#include "zscript/augs/synthetic_heart.zs"

#include "zscript/augs/aggressive_defense_system.zs"
#include "zscript/augs/spy_drone.zs"

#include "zscript/augs/vision_enhancement.zs"
#include "zscript/augs/targeting.zs"

enum DD_AugSlots
{
	Subdermal1	= 0,
	Subdermal2	= 1,
	Cranial		= 2,
	Arms		= 3,
	Legs		= 4,
	Eyes		= 5,
	Torso1		= 6,
	Torso2		= 7,
	Torso3		= 8,
};

// Description:
// Class that describes an augmentation stored in player's "body".
class DD_Augmentation : Inventory
{
	int id; // to identify duplicates
	String disp_name; // name to display
	String disp_desc; // description to display,
			  // lines are separated by '\n'
	String disp_legend_desc; // legendary description that is appended when the aug is upgraded to legendary state

	uint _level;
	clearscope uint getRealLevel()
	{
		if(!owner)
			return _level;
		let aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(!aughld)
			return _level;

		uint ret = _level;
		if(aughld.level_boost >= 1 && ret < max_level)
			ret++;
		if(aughld.level_boost == 2 && legendary)
			ret++;
		return ret;
			
	}
	uint max_level;
	bool legendary; // if augmentation is legendary upgraded
	clearscope bool isLegendary()
	{
		if(!owner)
			return legendary;
		let aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(!aughld)
			return legendary;
		return legendary || (aughld.legendary_boost && _level >= max_level);
	}
	bool can_be_legendary;

	bool enabled;
	bool passive;			// if false, cannot be toggled
	bool can_be_all_toggled;	// is toggled on/off by "enable/disable all augmentations" binds

	DD_AugSlots slots[3];	// possible slot numbers
	uint slots_cnt;		// count of possible slots

	virtual int get_base_drain_rate(){ return 1; }	// amount of energy drained per minute
	double drain_queue;				// amount of energy drain queued (since inventory items have integer amount,
							// we can't just substract energy every tick; instead, amount of energy to
							// be drained is accumulated in this variable)

	// Returns texture ID based on augmentation state (false - disabled, true - enabled)
	// This code is a stub, refer to BallisticProtection for example!
	virtual ui TextureID get_ui_texture(bool state){ return TexMan.CheckForTexture("TNT0"); }


	// This is actually unused: AugsHolder class manages augmentations through a dynamic array
	default
	{
		Inventory.Amount 1;
		Inventory.MaxAmount 1;

		+DONTGIB; // see augs_holder.zs
		+THRUACTORS; // prevents being picked up at (0; 0)
	}


	// -------------
	// Engine events
	// -------------

	override void tick()
	{
		if(enabled && owner)
		{
			if(owner.countInv("DD_BioelectricEnergy") == 0){
				toggle();
				return;
			}
			if(owner.health <= 0){
				CVar deadcv = CVar.getCVar("dd_toggle_augs_dead");
				if(!deadcv || !deadcv.getBool())
				{ enabled = false; return; }
			}
	
			DD_AugsHolder aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
			drain_queue += (get_base_drain_rate() * aughld.energy_drain_ml) / (35 * 60);
			if(drain_queue > 1.0)
			{
				owner.takeInventory("DD_BioelectricEnergy", floor(drain_queue));
				aughld.addRecirculationEnergy(floor(drain_queue));
				drain_queue -= floor(drain_queue);
			}
		}
	}

	ui bool ui_init;
	virtual ui void UIInit(){}
	virtual ui void UITick(){}
	virtual ui void drawOverlay(RenderEvent e, DD_EventHandler hndl){}
	virtual ui void drawUnderlay(RenderEvent e, DD_EventHandler hndl){}
	virtual ui bool inputProcess(InputEvent e){ return false; }

	virtual void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags){}
	virtual void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags){}


	// ---------
	// Functions
	// ---------

	// Called when augmentation is installed the first time.
	virtual void install()
	{
		id = -1;
		_level = 1;
		max_level = 4;

		slots_cnt = 0;

		enabled = false;
		can_be_all_toggled = true;
	}

	// Called to toggle augmentation state.
	virtual void toggle()
	{
		enabled = !enabled;
		if(enabled){
			if(owner.health <= 0){
				CVar deadcv = CVar.getCVar("dd_toggle_augs_dead");
				if(!deadcv || !deadcv.getBool())
				{ enabled = false; return; }
			}
			SoundUtils.playStartSound("ui/aug/activate", owner);
		}
		else
			SoundUtils.playStartSound("ui/aug/deactivate", owner);
	}

	// ---------------------
	// Static util functions
	// ---------------------

	
	static void initAugPool(out array<class<DD_Augmentation> > aug_pool)
	{
		for(uint i = 0; i < allActorClasses.size(); ++i)
		{
			Class<Actor> cls = allActorClasses[i];
			if(cls == "DD_Augmentation" || !(cls is "DD_Augmentation"))
				continue;

			aug_pool.push(cls);
		}
	}
	// Called by augmentation canister to generate it's contents
	static void shuffleAugPool(in out array<class<DD_Augmentation> > aug_pool)
	{
		for(uint i = 0; i < aug_pool.size()/2; ++i)
		{
			uint i1 = random(0, aug_pool.size()-1);
			uint i2 = random(0, aug_pool.size()-1);
			class<DD_Augmentation> t = aug_pool[i1];
			aug_pool[i1] = aug_pool[i2];
			aug_pool[i2] = t;
		}
	}
}

