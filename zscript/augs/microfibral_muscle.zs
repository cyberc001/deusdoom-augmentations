struct DD_Aug_MicrofibralMuscle_Queue
{
	bool objwep;

	array<Actor> soldify_objs;
	array<int> soldify_timers;
	array<bool> soldify_wasthruactors;
	array<bool> soldify_stunned;
}

class DD_Aug_MicrofibralMuscle : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	// Entity borders
	ui TextureID entbd_lt;
	ui TextureID entbd_rt;
	ui TextureID entbd_lb;
	ui TextureID entbd_rb;
	ui TextureID entframe;

	// Thing names/bounding boxes projections
	ui DDLe_ProjScreen proj_scr;
	DDLe_SWScreen proj_sw;
	DDLe_GLScreen proj_gl;
	ui DDLe_Viewport vwport;

	DD_Aug_MicrofibralMuscle_Queue queue;

	static const int doorspecials[]={
		//from https://github.com/coelckers/gzdoom/blob/master/src/p_lnspec.cpp#L3432
		10,11,12,13,14,
		105,106,194,195,198,
		202,
		249,252,262,263,265,266,268,274
	};
	

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 20; }

	override void install()
	{
		super.install();

		id = 19;
		disp_name = "Microfibral Muscle";
		disp_desc = "Muscle strength is amplified with ionic polymeric gel\n"
			    "myofibrils that allow the agent to lift and throw\n"
			    "extraordinarily heavy objects, which can stun\n"
			    "and hurt monsters on impact.\n"
			    "It also allows the agent to strangle and pick up alive\n"
			    "monsters, with each tech level increasing the tier of\n"
			    "monsters possible to pick up.\n\n"
			    "TECH ONE: Strength is increased slightly, agent can\n"
			    "pick up some objects.\n\n"
			    "TECH TWO: Strength is increased moderately, agent\n"
			    "can pick up heavier objects like barrels and corpses.\n\n"
			    "TECH THREE: Strength is increased significantly.\n\n"
			    "TECH FOUR: Agent is inhumanly strong.\n\n"
			    "Energy Rate: 20 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Agent is so strong that they\n"
				   "can pry open many door-like structures with their\n"
				   "bare hands. Also, objects are now thrown much move\n"
				   "violently, causing much more damage on impact, and\n"
				   "much more dangerous monsters can be picked up.";

		slots_cnt = 1;
		slots[0] = Arms;

		initProjection();

		can_be_legendary = true;
	}

	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("MICMUSC0");
		tex_on = TexMan.checkForTexture("MICMUSC1");

		entbd_lt = TexMan.checkForTexture("AUGUI31");
		entbd_rt = TexMan.checkForTexture("AUGUI32");
		entbd_lb = TexMan.checkForTexture("AUGUI33");
		entbd_rb = TexMan.checkForTexture("AUGUI34");
		entframe = TexMan.checkForTexture("AUGUI35");
	}

	// ------------------
	// Internal functions
	// ------------------

	protected void initProjection()
	{
		proj_sw = new("DDLe_SWScreen");
		proj_gl = new("DDLe_GLScreen");
	}
	protected ui void prepareProjection()
	{
		CVar renderer_type = CVar.getCVar("vid_rendermode", players[consoleplayer]);

		if(renderer_type)
		{
			switch(renderer_type.getInt())
			{
				case 0: case 1: proj_scr = proj_sw; break;
				default:	proj_scr = proj_gl; break;
			}
		}
		else
			proj_scr = proj_gl;
	}

	protected ui string getActorDisplayName(Actor ac)
	{
		string dname;
		if(ac is "PlayerPawn")
			dname = ac.player.getUserName();
		else
			dname = ac.getTag("");
		if(ac.health < 0)
			if(ac.bIsMonster)
				dname = dname .. " (corpse)";
			else
				dname = dname .. " (remnants)";
		return dname;
	}

	protected int getMaxMassPickup() { return 80 + 310 * (getRealLevel() - 1); }
	double getThrowForceMult() { return 1.0 + 1.0 * (getRealLevel() - 1); }

	protected double getStunDurMult() { return 1.0 + 0.75 * (getRealLevel() - 1); }
	protected int getStunDurMin() { return 15 + 7 * (getRealLevel() - 1); }
	protected int getStunDurMax() { return 70 + 35 * (getRealLevel() - 1); }

	protected double getDamageMult() { return 0.4 + 0.3 * (getRealLevel() - 1) + (isLegendary() ? 2.6 : 0); }
	protected int getAliveMonsterHealthMax() { return 50 + 150 * (getRealLevel() - 1) + (isLegendary() ? 1000 : 0); }

	protected int cantPickupObj(Actor ac)
	{
		double th_ml = 1.0;
		int bh = RecognitionUtils.canBePickedUp(ac, th_ml);
		if(bh == -1)
			return 1;

		if(ac.bIsMonster && ac.health > getAliveMonsterHealthMax())
			return 1;
		if(ac.bIsMonster && ac.health <= 0 && ac.bBOSS)
			return 1;
		if(ac.mass * th_ml > getMaxMassPickup()
		&& !(ac is "Inventory"))
			return 2;
		return 0;
	}

	// -------------
	// Engine events
	// -------------

	Actor target_obj;
	Sector target_sector;

	override void tick()
	{
		for(uint i = 0; i < queue.soldify_objs.size(); ++i)
		{
			if(queue.soldify_timers[i] > 0){
				queue.soldify_timers[i]--;

				// Checking for collision for stunning enemies
				if(!queue.soldify_stunned[i])
				{
					Actor thrown_obj = queue.soldify_objs[i];
					Actor tobj;
					BlockThingsIterator it = BlockThingsIterator.Create(thrown_obj);
					while(it.next())
					{
						tobj = it.thing;
						if(tobj.bIsMonster
						&& tobj.health > 0
						&& tobj.radius + thrown_obj.radius >= thrown_obj.distance2D(tobj)
						&& tobj.countInv("DD_MicrofibralMuscle_StunPowerup") == 0)
						{
							let pstun = DD_MicrofibralMuscle_StunPowerup(Inventory.Spawn("DD_MicrofibralMuscle_StunPowerup"));
							pstun.dur_timer = double(thrown_obj is "Inventory" ? thrown_obj.mass / 3 : thrown_obj.mass)
									/ (tobj.health*2.0) * 200 * getStunDurMult();
	
							if(pstun.dur_timer > getStunDurMax())
								pstun.dur_timer = getStunDurMax();
							if(pstun.dur_timer < getStunDurMin())
								pstun.dur_timer = getStunDurMin();
							tobj.addInventory(pstun);

							tobj.damageMobj(owner, owner, max(50, min(tobj.GetSpawnHealth() / 10, 200) * getDamageMult()), "None");

							queue.soldify_stunned[i] = true;
						}
					}
				}
			}
			else{
				if(queue.soldify_objs[i]){
					queue.soldify_objs[i].A_ChangeLinkFlags(0, 0);
					if(!queue.soldify_wasthruactors[i])
						queue.soldify_objs[i].bThruActors = false;
				}

				queue.soldify_objs.delete(i);
				queue.soldify_timers.delete(i);
				queue.soldify_wasthruactors.delete(i);
				queue.soldify_stunned.delete(i);
			}
		}

		super.tick();
		if(!enabled)
			return;
		if(!(owner is "PlayerPawn"))
			return;

		let cam_tracer = new("DD_MicrofibralMuscle_Tracer");
		cam_tracer.source = owner;

		vector3 dir = (AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
		cam_tracer.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, dir, 128.0, 0);

		target_obj = cam_tracer.hit_obj;
		target_sector = cam_tracer.results.hitSector;

		if(queue.objwep)
		{
			queue.objwep = false;
			if(!owner.player.readyWeapon || owner.player.readyWeapon is "DD_MicrofibralMuscle_ObjectWeapon")
				return;
			if(owner.countInv("DD_MicrofibralMuscle_ObjectWeapon") > 0)
				return;

			if(target_obj)
			{
				int res = cantPickupObj(target_obj);
				if(res == 2)
					console.printf("It's too heavy to lift");
				if(res)
					return;

				owner.giveInventory("DD_MicrofibralMuscle_ObjectWeapon", 1);
				DD_MicrofibralMuscle_ObjectWeapon objwep = DD_MicrofibralMuscle_ObjectWeapon(owner.findInventory("DD_MicrofibralMuscle_ObjectWeapon"));
				objwep.held_obj = target_obj;
				objwep.parent_aug = self;
				// making target object disappear from the world
				target_obj.warp(owner);
				target_obj.changeTID(0);
				target_obj.changeStatNum(STAT_TRAVELLING);
				target_obj.A_ChangeLinkFlags(1, 1);
				owner.player.pendingWeapon = Weapon(objwep);
				owner.player.bringUpWeapon();
			}
			else if(target_sector && isLegendary())
			{
				for(uint i = 0; i < target_sector.lines.size(); ++i)
				{
					Line l = target_sector.lines[i];

					bool shouldpry = false;
					for(uint i = 0; i < doorspecials.size(); ++i)
						if(l.special == doorspecials[i])
						{ shouldpry = true; break; }
					if(shouldpry)
					{
						Sector door_sector = l.backsector;
						door_sector.flags |= Sector.SECF_SILENTMOVE;

						// based on https://codeberg.org/mc776/hideousdestructor/src/branch/main/zscript/doorbuster.zs
						int doorflat = cam_tracer.results.hitType == TRACE_HitCeiling	? 0
							 : cam_tracer.results.hitType == TRACE_HitFloor		? 2
							 : 1;
						if(doorflat == 2){ // hit the floor of a door - raising the ceiling
							if(door_sector.floordata)
								door_sector.floordata.destroy();

							double hdelta = door_sector.ceilingplane.zatpoint(door_sector.centerspot) - door_sector.findLowestFloorSurrounding();

							level.createFloor(door_sector, Floor.floorRaiseByValue, null, 65536., hdelta);
							door_sector.floordata.tick();
						}
						else{ // hit the ceiling of the door - lowering the floor
							if(door_sector.ceilingdata)
								door_sector.ceilingdata.destroy();

							double hdelta = door_sector.findLowestCeilingSurrounding() - door_sector.floorplane.zatpoint(door_sector.centerspot);

							level.createCeiling(door_sector, Ceiling.ceilRaiseByValue, null, 65536., 0., hdelta);
							door_sector.ceilingdata.tick();
						}

						l.special = 0;
						Spawn("DD_MicrofibralMuscle_TearExplosion", owner.pos + (0, 0, PlayerPawn(owner).viewHeight) + dir*16);
					}
				}
			}
		}
	}

	override void travelled()
	{
		// Reset all the queues to avoid hard crashing when ticking on the next level
		queue.objwep = false;
		queue.soldify_timers.clear();
		queue.soldify_objs.clear();	
		queue.soldify_wasthruactors.clear();
		queue.soldify_stunned.clear();
	}

	override void drawUnderlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(owner && owner is "PlayerPawn" && owner.player.readyWeapon)
		{
			if(owner.player.readyWeapon is "DD_MicrofibralMuscle_ObjectWeapon")
			{
				DD_MicrofibralMuscle_ObjectWeapon objwep = DD_MicrofibralMuscle_ObjectWeapon(owner.player.readyWeapon);
				if(objwep.held_obj){
					TextureID sprtex = objwep.held_obj.CurState.getSpriteTexture(8);
					double radcoff = objwep.held_obj.radius / 320 * 150;
					double texw = UI_Draw.texWidth(sprtex, -1, -1)
							* radcoff
							* abs(objwep.held_obj.scale.x);
					double texh = UI_Draw.texHeight(sprtex, -1, -1)
							* radcoff
							* abs(objwep.held_obj.scale.y);
					UI_Draw.texture(sprtex,
								160 - texw/2, 180 - texh/2,
								texw, texh,
								(objwep.held_obj.scale.x < 0 ? UI_Draw_FlipX : 0)
								| (objwep.held_obj.scale.y < 0 ? UI_Draw_FlipY : 0),
								0.4);
				}
			}
		}
	}
	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(!enabled)
			return;

		if(target_obj)
		{
			vector3 norm_to_bbox = (AngleToVector(owner.angle+90, cos(owner.pitch)), -sin(owner.pitch));
			if(norm_to_bbox.length() == 0)
				return;
			norm_to_bbox /= norm_to_bbox.length();
			vector3 targ_bbox_lbot = target_obj.pos + norm_to_bbox * target_obj.radius;

			norm_to_bbox = (AngleToVector(owner.angle, cos(owner.pitch-90)), -sin(owner.pitch-90));
			if(norm_to_bbox.length() == 0)
				return;
			vector3 targ_bbox_ltop = targ_bbox_lbot + norm_to_bbox * target_obj.height;

			norm_to_bbox = (AngleToVector(owner.angle-90, cos(owner.pitch)), -sin(owner.pitch));
			if(norm_to_bbox.length() == 0)
				return;
			norm_to_bbox /= norm_to_bbox.length();
			vector3 targ_bbox_rbot = target_obj.pos + norm_to_bbox * target_obj.radius;

			norm_to_bbox = (AngleToVector(owner.angle, cos(owner.pitch-90)), -sin(owner.pitch-90));
			if(norm_to_bbox.length() == 0)
				return;
			vector3 targ_bbox_rtop = targ_bbox_rbot + norm_to_bbox * target_obj.height;

			vwport.fromHUD();
			prepareProjection();

			proj_scr.cacheResolution();
			proj_scr.cacheFOV();
			proj_scr.orientForRenderOverlay(e);
			proj_scr.beginProjection();
			vector2 obj_norm;
			vector2 ind_pos;

			// Left top
			proj_scr.projectWorldPos(targ_bbox_ltop);
			obj_norm = proj_scr.projectToNormal();
			ind_pos = vwport.sceneToWindow(obj_norm);
			if(!vwport.isInside(obj_norm) || !proj_scr.isInScreen())
				return;
			ind_pos.x *= double(320) / screen.getWidth();
			ind_pos.y *= double(200) / screen.getHeight();
			UI_Draw.texture(entbd_lt, ind_pos.x, ind_pos.y, -0.2, -0.2);

			// Entity name
			string tdispname = getActorDisplayName(target_obj);
			UI_Draw.texture(entframe, ind_pos.x + 1, ind_pos.y + 1,
					UI_Draw.strWidth(hndl.aug_ui_font, tdispname, -0.5, -0.5) + 2,
					UI_Draw.strHeight(hndl.aug_ui_font, tdispname, -0.5, -0.5) + 2);
			UI_Draw.str(hndl.aug_ui_font, tdispname, 11,
					ind_pos.x + 2, ind_pos.y + 2, -0.5, -0.5);

			// Right top
			proj_scr.projectWorldPos(targ_bbox_rtop);
			obj_norm = proj_scr.projectToNormal();
			ind_pos = vwport.sceneToWindow(obj_norm);
			if(!vwport.isInside(obj_norm) || !proj_scr.isInScreen())
				return;
			ind_pos.x *= double(320) / screen.getWidth();
			ind_pos.y *= double(200) / screen.getHeight();
			UI_Draw.texture(entbd_rt, ind_pos.x, ind_pos.y, -0.2, -0.2);

			// Left bottom
			proj_scr.projectWorldPos(targ_bbox_lbot);
			obj_norm = proj_scr.projectToNormal();
			ind_pos = vwport.sceneToWindow(obj_norm);
			if(!vwport.isInside(obj_norm) || !proj_scr.isInScreen())
				return;
			ind_pos.x *= double(320) / screen.getWidth();
			ind_pos.y *= double(200) / screen.getHeight();
			UI_Draw.texture(entbd_lb, ind_pos.x, ind_pos.y, -0.2, -0.2);

			// Right bottom
			proj_scr.projectWorldPos(targ_bbox_rbot);
			obj_norm = proj_scr.projectToNormal();
			ind_pos = vwport.sceneToWindow(obj_norm);
			if(!vwport.isInside(obj_norm) || !proj_scr.isInScreen())
				return;
			ind_pos.x *= double(320) / screen.getWidth();
			ind_pos.y *= double(200) / screen.getHeight();
			UI_Draw.texture(entbd_rb, ind_pos.x, ind_pos.y, -0.2, -0.2);
		}
	}


	override bool inputProcess(InputEvent e)
	{
		if(e.type == InputEvent.Type_KeyDown)
		{
			if(KeyBindUtils.checkBind(e.keyScan, "+use"))
			{
				if(!owner || !(owner is "PlayerPawn"))
					return false;
				if(!enabled)
					return false;

				EventHandler.sendNetworkEvent("dd_use_muscle");
			}
		}
		return false;
	}
}

class DD_MicrofibralMuscle_Tracer : LineTracer
{
	Actor source;
	Actor hit_obj;

	override ETraceStatus traceCallback()
	{
		if(results.hitType == TRACE_HitActor)
		{
			if(results.hitActor && results.hitActor == source)
				return TRACE_Skip;
	
			if(results.hitActor){
				double ts_ml;
				int bh = RecognitionUtils.canBePickedUp(results.hitActor, ts_ml);
				if(bh == 1 || bh == 0){
					hit_obj = results.hitActor;
					return TRACE_Stop;
				}
				return TRACE_Skip;
			}
		}
		else if(results.hitType == TRACE_HitWall && results.tier == TIER_Middle && results.hitLine.flags & Line.ML_TWOSIDED > 0)
			return TRACE_Skip;
		else if(results.hitType == TRACE_HitWall || results.hitType == TRACE_HitFloor || results.hitType == TRACE_HitCeiling){
			return TRACE_Stop;
		}

		return TRACE_Skip;
	}
}

class DD_MicrofibralMuscle_ObjectWeapon : Weapon
{
	Actor held_obj;
	DD_Aug_MicrofibralMuscle parent_aug;

	default
	{
		Weapon.SelectionOrder 1000;
		Weapon.SlotNumber 0;
	}

	states
	{
		Ready:
			TNT1 A 1 A_WeaponReady();
			Loop;
		Deselect:
			TNT1 A 0 {
					DD_MicrofibralMuscle_ObjectWeapon(player.readyWeapon).respawnHeldObject();
					DD_MicrofibralMuscle_ObjectWeapon(player.readyWeapon).tossHeldObject(400.0);
					takeInventory("DD_MicrofibralMuscle_ObjectWeapon", 1);
				 }
			Stop;
		Select:
			Goto Ready;
		Fire:
			TNT1 A 0 {
					DD_MicrofibralMuscle_ObjectWeapon(player.readyWeapon).respawnHeldObject();
					DD_MicrofibralMuscle_ObjectWeapon(player.readyWeapon).tossHeldObject(800.0);
					takeInventory("DD_MicrofibralMuscle_ObjectWeapon", 1);
				 }
			Stop;
	}

	override void tick()
	{
		// to keep things like dynamic lights originated at player
		if(held_obj && owner)
			held_obj.warp(owner, 0, 0, 0, 0, WARPF_NOCHECKPOSITION);
	}
	void respawnHeldObject()
	{
		if(!held_obj || !parent_aug)
			return;
		held_obj.changeStatNum(STAT_DEFAULT);
		held_obj.A_ChangeLinkFlags(1, 0);
		
		parent_aug.queue.soldify_wasthruactors.push(held_obj.bThruActors);
		held_obj.bThruActors = true;

		parent_aug.queue.soldify_objs.push(held_obj);
		parent_aug.queue.soldify_timers.push(17);
		parent_aug.queue.soldify_stunned.push(false);

		held_obj.warp(self.owner, 0.0, 0.0, self.owner.player.viewHeight, 0.0,
				WARPF_ABSOLUTEOFFSET | WARPF_NOCHECKPOSITION);
	}
	void tossHeldObject(double force_scale)
	{
		if(!held_obj || !parent_aug)
			return;
		force_scale *= parent_aug.getThrowForceMult();

		vector3 owner_look = (AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
		if(owner_look.length() == 0)
			return;
		owner_look /= owner_look.length();
		owner_look *= force_scale;
		if(held_obj is "Inventory")
			owner_look /= (held_obj.mass / 7);
		else
			owner_look /= held_obj.mass;
		held_obj.A_ChangeVelocity(owner_look.x, owner_look.y, owner_look.z);

		held_obj = null;
	}
}

class DD_MicrofibralMuscle_StunPowerup : Powerup
{
	int dur_timer;
	sound prev_pain_snd;

	override void postBeginPlay()
	{
		if(owner && owner.bIsMonster)
		{
			prev_pain_snd = owner.painSound;
			owner.A_Pain();
			owner.painSound = "";
		}
	}
	override void tick()
	{
		if(owner && owner.bIsMonster)
			owner.triggerPainChance("None", true);

		--dur_timer;
		if(dur_timer <= 0){
			if(owner)
				owner.painSound = prev_pain_snd;
			detachFromOwner();
			destroy();
		}
	}
}


class DD_MicrofibralMuscle_TearExplosion : Actor
{
	default
	{
		Scale 1.2;
		+NOBLOCKMAP;
	}

	states
	{
		Spawn:
			MISL B 6 Bright NoDelay A_StartSound("weapons/rocklx");
			MISL CD 6 Bright;
			Stop;
	}
}
