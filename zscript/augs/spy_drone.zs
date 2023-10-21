class DD_Aug_SpyDrone : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	// Camera feed border color
	ui TextureID camfd_bd;

	// Object detection projection
	ui DDLe_ProjScreen proj_scr;
	DDLe_SWScreen proj_sw;
	DDLe_GLScreen proj_gl;
	ui DDLe_Viewport vwport;

	// For marking objects
	array<Actor> mark_objs;
	array<int> mark_timers;

	ui TextureID marker_normal;
	ui TextureID marker_boss;
	ui TextureID marker_item;

	int mark_limit;

	// Mouse sensitivity CVARs cache
	double msens_x;
	double msens_yaw;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 100; }

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

	override void install()
	{
		super.install();

		id = 16;
		disp_name = "Spy Drone";
		disp_desc = "Advanced nanofactories can assemble a spy drone on\n"
			    "demand which can then be remotely controlled by the\n"
			    "agent until released, at which point a new drone\n"
			    "will be assembled. The drone reveals various objects\n"
			    "for a certain period of time with marks that can\n"
			    "be seen through walls.\n\n"
			    "TECH ONE: The drone is slow and marks objects for\n"
			    "short period of time.\n\n"
			    "TECH TWO: The drone is faster and marks objects for\n"
			    "longer.\n\n"
			    "TECH THREE: The drone is significantly faster and\n"
			    "marks objects for a long time.\n\n"
			    "TECH FOUR: The drone is incredibly fast and marks\n"
			    "objects for a very long time.\n\n"
			    "Energy Rate: 100 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: can teleport items within\n"
				   "certain distance to agent piloting it. It is\n"
				   "actiavated the same way as an agent would trigger\n"
				   "a switch or a door.\n";

		slots_cnt = 1;
		slots[0] = Cranial;

		can_be_legendary = true;

		initProjection();
	}

	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("SPYDRON0");
		tex_on = TexMan.checkForTexture("SPYDRON1");

		camfd_bd = TexMan.checkForTexture("AUGUI36");

		drone_camtex = TexMan.checkForTexture("DDRONCAM", TexMan.Type_Any);

		marker_normal = TexMan.checkForTexture("AUGUI42", TexMan.Type_Any);
		marker_boss = TexMan.checkForTexture("AUGUI43", TexMan.Type_Any);
		marker_item = TexMan.checkForTexture("AUGUI44", TexMan.Type_Any);
	}

	// ------------------
	// Internal functions
	// ------------------

	DD_SpyDrone drone_actor;
	ui TextureID drone_camtex;

	// -------------
	// Engine events
	// -------------

	override void toggle()
	{
		super.toggle();

		if(enabled){
			if(!owner || !(owner is "PlayerPawn")){
				toggle();
				return;
			}

			mark_limit = CVar.getCVar("dd_spy_drone_mark_limit", owner.player).getInt();

			msens_x = CVar.getCVar("m_sensitivity_x").getFloat();
			msens_yaw = CVar.getCVar("m_yaw").getFloat();

			if(drone_actor)
				drone_actor.die(null, null);
			if(owner.countInv("DD_BioelectricEnergy") <= 1)
				return;

			drone_actor = DD_SpyDrone(Actor.spawn("DD_SpyDrone"));
			drone_actor.warp(owner, 0.0, 0.0, PlayerPawn(owner).viewHeight, 0.0,
					WARPF_ABSOLUTEOFFSET | WARPF_NOCHECKPOSITION);
			drone_actor.parent_aug = self;
			drone_actor.master = owner;

			drone_actor.mode = DD_MDroneManual;

			TexMan.setCameraToTexture(drone_actor, "DDRONCAM", 90.0);
		}
		else{
			if(drone_actor){
				drone_actor.die(null, null);
				drone_actor = null;
			}
		}
	}

	override void tick()
	{
		super.tick();

		// Ticking mark timers
		for(uint i = 0; i < mark_timers.size(); ++i)
		{
			if(mark_timers[i] > 0)
				--mark_timers[i];
			else{
				mark_timers.delete(i);
				mark_objs.delete(i);
			}
		}

		// Checking if drone is still alive
		if(enabled
		&& (!drone_actor || drone_actor.health <= 0))
			toggle();
	}

	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		// Rendering object marks
		vwport.fromHUD();
		prepareProjection();

		proj_scr.cacheResolution();
		proj_scr.cacheFOV();
		proj_scr.orientForRenderOverlay(e);
		proj_scr.beginProjection();

		uint marks = 0;
		for(uint i = 0; i < mark_objs.size() && marks < mark_limit; ++i)
		{
			if(!mark_objs[i])
				continue;

			let sight_tr = new("DD_Aug_SpyDrone_SightTracer");
				sight_tr.ignore[0] = owner;
				sight_tr.ignore[1] = drone_actor;
			vector3 trace_dir = mark_objs[i].pos + (0, 0, mark_objs[i].height)
					    - (owner.pos + (0, 0, PlayerPawn(owner).viewHeight));
			if(trace_dir.length() == 0)
				continue;
			trace_dir /= trace_dir.length();
			sight_tr.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, trace_dir, 999999.0, 0);
			if(sight_tr.results.hitActor == mark_objs[i])
				continue;

			// Preparing projection
			vector3 proj_pos = mark_objs[i].pos + (0, 0, mark_objs[i].height);
			proj_scr.projectWorldPos(proj_pos);
			vector2 proj_norm = proj_scr.projectToNormal();
			vector2 mark_pos = vwport.sceneToWindow(proj_norm);

			if(!vwport.isInside(proj_norm) || !proj_scr.isInScreen())
				continue;

			mark_pos.x *= double(320) / screen.getWidth();
			mark_pos.y *= double(200) / screen.getHeight();


			// Drawing object sprite
			bool spriteflip;
			bool wildcarded;
			if(wildcarded && mark_objs[i].health <= 0)
				continue;

			vector3 objvec = mark_objs[i].pos
					 - (owner.pos + (0, 0, owner.player.viewHeight));
			double objdist = objvec.length();
			double texcoff;
			if(objdist != 0)
				texcoff = 1 / (objdist / 92.0);
			else
				texcoff = 1;

			if(mark_objs[i].scale.x < 0)
				spriteflip = !spriteflip;

			TextureID spritetex;
			if(mark_objs[i] is "Inventory" || mark_objs[i].bFRIENDLY)
				spritetex = marker_item;
			else
				spritetex = (mark_objs[i].bBOSS ? marker_boss : marker_normal);
			double texw = UI_Draw.texWidth(spritetex, -1, -1) * texcoff;
			double texh = UI_Draw.texHeight(spritetex, -1, -1) * texcoff;

			UI_Draw.texture(spritetex,
					mark_pos.x - texw/2,
					mark_pos.y - texh/2,
					texw, texh,
					(spriteflip ? UI_Draw_FlipX : 0)
					| (mark_objs[i].scale.y < 0 ? UI_Draw_FlipY : 0));
			++marks;
		}

		bool hud_dbg = false;
		if(CVar_Utils.isHUDDebugEnabled())
		{
			vector2 off = CVar_Utils.getOffset("dd_spy_drone_cam_off");
			string s_act = "Remote SpyDrone Active";
			UI_Draw.str(hndl.aug_ui_font, s_act, 11,
					320.0/3/2 + 2
					- UI_Draw.strWidth(hndl.aug_ui_font, s_act, -0.55, -0.55)/2
					+ off.x,
					200.0/3 - UI_Draw.strHeight(hndl.aug_ui_font, s_act, -0.55, -0.55) - 1
					+ off.y + 15,
					-0.55, -0.55);
			UI_Draw.texture(camfd_bd,
					off.x,
					200.0/3 + off.y + 15,
					320.0/3 + 2, 200.0/3 + 2);
		}

		// Rendering camera feed
		if(!enabled || !drone_actor || hud_dbg)
			return;

		vector2 off = CVar_Utils.getOffset("dd_spy_drone_cam_off");

		string s_act = "Remote SpyDrone Active";
		UI_Draw.str(hndl.aug_ui_font, s_act, 11,
				320.0/3/2 + 2
				- UI_Draw.strWidth(hndl.aug_ui_font, s_act, -0.55, -0.55)/2
				+ off.x,
				200.0/3 - UI_Draw.strHeight(hndl.aug_ui_font, s_act, -0.55, -0.55) - 1
				+ off.y + 15,
				-0.55, -0.55);
		UI_Draw.texture(camfd_bd,
				off.x,
				200.0/3 + off.y + 15,
				320.0/3 + 2, 200.0/3 + 2);
		UI_Draw.texture(drone_camtex,
				1 + off.x,
				200.0/3 + 1 + off.y + 15,
				320.0/3, 200.0/3);
	}


	override bool inputProcess(InputEvent e)
	{
		if(!enabled)
			return false;
		if(drone_actor && drone_actor.mode == DD_MDroneManual)
		{
			if(e.type == InputEvent.Type_KeyDown)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward")){
					EventHandler.sendNetworkEvent("dd_drone", 0, 1 * 10000);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+back")){
					EventHandler.sendNetworkEvent("dd_drone", 0, -1 * 10000);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")){
					EventHandler.sendNetworkEvent("dd_drone", 1, 1 * 10000);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright")){
					EventHandler.sendNetworkEvent("dd_drone", 1, -1 * 10000);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump")){
					EventHandler.sendNetworkEvent("dd_drone", 2, 0.8 * 10000);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+crouch")){
					EventHandler.sendNetworkEvent("dd_drone", 2, -0.8 * 10000);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+use")){
					EventHandler.sendNetworkEvent("dd_drone", 4);
				}
				else
					return false;
				return true;
			}
			else if(e.type == InputEvent.Type_KeyUp)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward")){
					EventHandler.sendNetworkEvent("dd_drone", 0, 0);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+back")){
					EventHandler.sendNetworkEvent("dd_drone", 0, 0);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")){
					EventHandler.sendNetworkEvent("dd_drone", 1, 0);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright")){
					EventHandler.sendNetworkEvent("dd_drone", 1, 0);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump")){
					EventHandler.sendNetworkEvent("dd_drone", 2, 0);
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+crouch")){
					EventHandler.sendNetworkEvent("dd_drone", 2, 0);
				}
				else
					return false;
				return true;
			}
			else if(e.type == InputEvent.Type_Mouse)
			{
				EventHandler.sendNetworkEvent("dd_drone", 3, (int)(-e.mouseX / 90.0 * msens_x * msens_yaw * 10000));
				return true;
			}
		}
		return false;
	}
}
class DD_Aug_SpyDrone_SightTracer : LineTracer
{
	Actor ignore[2];

	override ETraceStatus traceCallback()
	{
		if(results.hitActor == ignore[0]
		|| results.hitActor == ignore[1])
			return TRACE_Skip;
		if(results.hitType == TRACE_HitWall){
			if(results.tier == TIER_Middle && results.hitLine.flags & LINE.ML_TWOSIDED > 0)
				return TRACE_Skip;
			return TRACE_Stop;
		}
		if(results.hitActor)
			return TRACE_Stop;
		return TRACE_Skip;
	}
}

enum DD_SpyDroneMode
{
	DD_MDroneScout,
	DD_MDroneManual
}
struct DD_SpyDrone_Queue
{
	vector3 acc;
	double ang;
	bool use;
}
class DD_SpyDrone_Tracer : LineTracer
{
	override ETraceStatus traceCallback()
	{
		if(results.hitType == TRACE_HitWall){
			if(results.tier == TIER_Middle && results.hitLine.flags & LINE.ML_TWOSIDED > 0)
				return TRACE_Skip;
			return TRACE_Stop;
		}
		if(results.hitActor && results.hitActor is "Inventory")
			return TRACE_Stop;
		return TRACE_Skip;
	}
}
class DD_SpyDrone : Actor
{
	DD_Aug_SpyDrone parent_aug;

	DD_SpyDroneMode mode;
	DD_SpyDrone_Queue act_queue;

	// Physical speed properties

	default
	{
		Health 120;

		Radius 7;
		Height 4;

		Mass 10;

		+Shootable
		+NoGravity

		+CanPass
		+NoBlockMonst

		+NoPain
		+NoBlood
		+NoTrigger
	}

	clearscope double getAccMult() { return 0.17 + 0.15 * (parent_aug.getRealLevel() - 1);  }
	vector3 getDeacc() { return (1.0, 1.0, 1.0)
				* (0.1 + 0.05 * (parent_aug.getRealLevel() - 1)); }
	vector3 getMaxVel() { return (1.0, 1.0, 0.4)
				* (6.0 + 4.0 * (parent_aug.getRealLevel() - 1)); }

	int getMarkTime() { return 35 * 25 + 20 * (parent_aug.getRealLevel() - 1);  }

	states
	{
		Spawn:
			DSDR A 1{
				// Changing velocity according to acceleration/deceleration
				if(!parent_aug){
					A_Die();
					return;
				}

				A_ChangeVelocity(act_queue.acc.x, act_queue.acc.y, act_queue.acc.z,
							CVF_RELATIVE);
				vector3 maxvel = getMaxVel();
				if(abs(vel.x) > maxvel.x)
					A_ChangeVelocity((vel.x > 0 ? 1 : -1)*maxvel.x, vel.y, vel.z, CVF_REPLACE);
				if(abs(vel.y) > maxvel.y)
					A_ChangeVelocity(vel.x, (vel.y > 0 ? 1 : -1)*maxvel.y, vel.z, CVF_REPLACE);
				if(abs(vel.z) > maxvel.z)
					A_ChangeVelocity(vel.x, vel.y, (vel.z > 0 ? 1 : -1)*maxvel.z, CVF_REPLACE);

				vector3 deacc = getDeacc();
				if(abs(vel.x) > deacc.x)
					A_ChangeVelocity(vel.x > 0 ? -deacc.x : deacc.x, 0, 0);
				else
					A_ChangeVelocity(0, vel.y, vel.z, CVF_REPLACE);
				if(abs(vel.y) > deacc.y)
					A_ChangeVelocity(0, vel.y > 0 ? -deacc.y : deacc.y, 0);
				else
					A_ChangeVelocity(vel.x, 0, vel.z, CVF_REPLACE);
				if(abs(vel.z) > deacc.z)
					A_ChangeVelocity(0, 0, vel.z > 0 ? -deacc.z : deacc.z);
				else
					A_ChangeVelocity(vel.x, vel.y, 0, CVF_REPLACE);

				A_SetAngle(angle + act_queue.ang);
				act_queue.ang = 0;

				// Trying to use a line or pick up an item if queued
				if(act_queue.use)
				{
					act_queue.use = false;
					let usetracer = new("DD_SpyDrone_Tracer");
					vector3 dir = (AngleToVector(angle, cos(pitch)), -sin(pitch));
					usetracer.trace(pos, curSector, dir, 64.0, 0);

					if(usetracer.results.hitLine
					&& usetracer.results.hitLine.special != 243
					&& usetracer.results.hitLine.special != 244)
					// Preventing drone from activating exit lines
						usetracer.results.hitLine
							.activate(self.master, usetracer.results.side, 
							SPAC_PlayerActivate);
					if(usetracer.results.hitActor is "Inventory"
						&& parent_aug && parent_aug.isLegendary())
					{
						if(usetracer.results.hitActor is "Inventory"){
							Inventory inv = Inventory(usetracer.results.hitActor);

							if(inv.canPickup(master)){
								int prev_amt = master.countInv(inv.getClass());
								bool given = master.giveInventory(inv.getClass(), inv.amount);
								if(!given){
									master.setInventory(inv.getClassName(), prev_amt);
								}
								else{
									Inventory togive = inv.CreateCopy(master);
									togive.doPickupSpecial(master);
									spawnTeleportFog(inv.pos, true, false);
									if(togive == inv)
										inv.destroy();
								}
							}
						}
					}
				}


				// Looking for objects in LOS to mark
				Actor obj;
				BlockThingsIterator it = BlockThingsIterator.Create(self, 8192.0);

				Actor prev_targ = self.target;
				while(it.next())
				{
					obj = it.thing;
					if(obj == self)
						continue;
					self.target = obj;

					// Marking objects
					if(self.checkIfTargetInLOS(90.0))
					{
						uint oi = parent_aug.mark_objs.find(obj);
						if(oi == parent_aug.mark_objs.size())
						{
							parent_aug.mark_objs.push(obj);
							parent_aug.mark_timers.push(getMarkTime());
						}
						else
							parent_aug.mark_timers[oi] = getMarkTime();
					}
				}
				self.target = prev_targ;
			}
			Loop;
		Death:
			DSDR A 1;
			Stop;
	}

	clearscope void queueAccelerationX(double ax){ act_queue.acc.x = ax * getAccMult(); }
	clearscope void queueAccelerationY(double ay){ act_queue.acc.y = ay * getAccMult(); }
	clearscope void queueAccelerationZ(double az){ act_queue.acc.z = az * getAccMult(); }

	clearscope void queueTurnAngle(double ang) { act_queue.ang = ang; }

	clearscope void queueUse() { act_queue.use = true; }
}
