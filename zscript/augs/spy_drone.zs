class DD_Aug_SpyDrone : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	// Camera feed border color
	ui TextureID camfd_bd;

	// Mouse sensitivity CVARs cache
	double msens_x;
	double msens_yaw;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}
	override int get_base_drain_rate(){ return 70; }

	override void install()
	{
		super.install();

		id = 16;
		disp_name = "Spy Drone";
		disp_desc = "Advanced nanofactories can assemble a spy drone on\n"
			    "demand which can then be remotely controlled by the\n"
			    "agent until released, at which point a new drone\n"
			    "will be assembled. The drone can explode in regular\n"
			    "(+attack) or in EMP explosion (+altattack), destroying\n"
			    "it in the process.\n"
			    "Augmentation rebuils the drone in 10 seconds.\n\n";

		let drone = DD_SpyDrone(Spawn("DD_SpyDrone"));
		drone.parent_aug = self;
		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Drone speed is %g.\nDrone explosion damage is %g (0).\nDrone explosion radius is %g (%g).\n\n", drone.getVel(), drone.getExplosionDamage(), drone.getExplosionRadius(), drone.getEMPRadius());
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Drone speed is %g.\nDrone explosion damage is %g (0).\nDrone explosion radius is %g (%g).\n\n", drone.getVel(), drone.getExplosionDamage(), drone.getExplosionRadius(), drone.getEMPRadius());
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Drone speed is %g.\nDrone explosion damage is %g (0).\nDrone explosion radius is %g (%g).\n\n", drone.getVel(), drone.getExplosionDamage(), drone.getExplosionRadius(), drone.getEMPRadius());
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Drone speed is %g.\nDrone explosion damage is %g (0).\nDrone explosion radius is %g (%g).\n\n", drone.getVel(), drone.getExplosionDamage(), drone.getExplosionRadius(), drone.getEMPRadius());
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());
		drone.destroy();

		slots_cnt = 1;
		slots[0] = Cranial;
	}

	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("SPYDRON0");
		tex_on = TexMan.checkForTexture("SPYDRON1");

		camfd_bd = TexMan.checkForTexture("AUGUI36");

		drone_camtex = TexMan.checkForTexture("DDRONCAM", TexMan.Type_Any);
	}

	// ------------------
	// Internal functions
	// ------------------

	DD_SpyDrone drone;
	DD_SpyDrone drone_prev;
	ui TextureID drone_camtex;

	const construction_time = 10 * 35;
	int construction_timer;

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

			if(construction_timer > 0){
				console.printf("Drone reconstruction after %.3gs", ceil(construction_timer / 35.));
				toggle();
				return;
			}

			msens_x = CVar.getCVar("m_sensitivity_x").getFloat();
			msens_yaw = CVar.getCVar("m_yaw").getFloat();

			if(drone)
				drone.die(null, null);
			if(owner.countInv("DD_BioelectricEnergy") <= 1)
				return;

			drone = DD_SpyDrone(Actor.spawn("DD_SpyDrone"));
			drone.warp(owner, 0.0, 0.0, PlayerPawn(owner).viewHeight, 0.0,
					WARPF_ABSOLUTEOFFSET | WARPF_NOCHECKPOSITION);
			drone.parent_aug = self;
			drone.master = owner;

			drone.mode = DD_MDroneManual;

			TexMan.setCameraToTexture(drone, "DDRONCAM", 90.0);
		}
		else{
			if(drone){
				drone.die(null, null);
				drone = null;
			}
		}
	}

	override void tick()
	{
		super.tick();

		if(construction_timer > 0)
			--construction_timer;
		if(!drone && drone_prev){
			if(enabled) toggle();
			construction_timer = construction_time;
		}
		drone_prev = drone;

		if(enabled && (!drone || drone.health <= 0))
			toggle();
	}

	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		bool hud_dbg = false;
		if(CVar_Utils.isHUDDebugEnabled())
		{
			vector2 off = CVar_Utils.getOffset("dd_spy_drone_cam_off");
			string s_act = "Remote SpyDrone Active";
			UI_Draw.str(hndl.aug_ui_font, s_act, 0xFFFFFFFF,
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
		if(!enabled || !drone || hud_dbg)
			return;

		vector2 off = CVar_Utils.getOffset("dd_spy_drone_cam_off");

		string s_act = "Remote SpyDrone Active";
		UI_Draw.str(hndl.aug_ui_font, s_act, 0xFFFFFFFF,
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
		if(drone && drone.mode == DD_MDroneManual)
		{
			if(e.type == InputEvent.Type_KeyDown)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
					EventHandler.sendNetworkEvent("dd_drone", 0, 1 * 10000);
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
					EventHandler.sendNetworkEvent("dd_drone", 0, -1 * 10000);
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
					EventHandler.sendNetworkEvent("dd_drone", 1, 0.85 * 10000);
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
					EventHandler.sendNetworkEvent("dd_drone", 1, -0.85 * 10000);
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
					EventHandler.sendNetworkEvent("dd_drone", 2, 0.85 * 10000);
				else if(KeyBindUtils.checkBind(e.keyScan, "+crouch"))
					EventHandler.sendNetworkEvent("dd_drone", 2, -0.85 * 10000);
				else if(KeyBindUtils.checkBind(e.keyScan, "+use"))
					EventHandler.sendNetworkEvent("dd_drone", 4);
				else if(KeyBindUtils.checkBind(e.keyScan, "+attack"))
					EventHandler.sendNetworkEvent("dd_drone", 5);
				else if(KeyBindUtils.checkBind(e.keyScan, "+altattack"))
					EventHandler.sendNetworkEvent("dd_drone", 6);
				else
					return false;
				return true;
			}
			else if(e.type == InputEvent.Type_KeyUp)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
					EventHandler.sendNetworkEvent("dd_drone", 0, 0);
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
					EventHandler.sendNetworkEvent("dd_drone", 0, 0);
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
					EventHandler.sendNetworkEvent("dd_drone", 1, 0);
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
					EventHandler.sendNetworkEvent("dd_drone", 1, 0);
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
					EventHandler.sendNetworkEvent("dd_drone", 2, 0);
				else if(KeyBindUtils.checkBind(e.keyScan, "+crouch"))
					EventHandler.sendNetworkEvent("dd_drone", 2, 0);
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

enum DD_SpyDroneMode
{
	DD_MDroneScout,
	DD_MDroneManual
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

	bool use;
	vector3 acc_queue;
	int death_lifetime;

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

		Tag "Spy drone";
	}

	clearscope double getVel() { return 2.5 + 2 * (parent_aug.getRealLevel() - 1); }
	clearscope double getEMPRadius() { return 120 + 25 * (parent_aug.getRealLevel() - 1); }
	clearscope double getEMPFactor() { return 0.4 + 0.2 * (parent_aug.getRealLevel() - 1); }
	clearscope double getExplosionRadius() { return 110 + 20 * (parent_aug.getRealLevel() - 1); }
	clearscope double getExplosionDamage() { return 100 + 100 * (parent_aug.getRealLevel() - 1); }

	void explode(bool emp)
	{
		if(health <= 0)
			return;
		if(emp){
			Spawn("DDAnimatedEffect_EMPSphere", pos).A_StartSound("DDWeapon_EMPGrenade/explode"); // sounds are stopped on actor's death, so it's a workaround
			Spawn("DDAnimatedEffect_ExplosionMediumLAM", pos);
			ExplosionUtils.DoEMPAoe(self, getEMPRadius(), getEMPFactor(), parent_aug.owner);
		}
		else{
			Spawn("DDAnimatedEffect_EnergySphere", pos).A_StartSound("DDWeapon_LAM/explode"); 
			Spawn("DDAnimatedEffect_ExplosionMediumLAM", pos);
			ExplosionUtils.DoExplosion(self, getExplosionDamage(), getExplosionRadius(), parent_aug.owner);
		}
		Damagemobj(self, self, health, "None");
		Die(null, null);
	}

	states
	{
		Spawn:
			DSDR A 1{
				if(health <= 0)
					return ResolveState("Death");

				// Changing velocity according to acceleration/deceleration
				if(!parent_aug){
					A_Die();
					return ResolveState("Death");
				}

				if(acc_queue.length() > 0)
					A_StartSound("play/aug/spy_drone/move", 59172, 0, 0.5);
				A_ChangeVelocity(acc_queue.x * getVel(), acc_queue.y * getVel(), acc_queue.z * getVel(),
							CVF_RELATIVE | CVF_REPLACE);

				// Trying to use a line or pick up an item if queued
				if(use)
				{
					use = false;
					let usetracer = new("DD_SpyDrone_Tracer");
					vector3 dir = (AngleToVector(angle, cos(pitch)), -sin(pitch));
					usetracer.trace(pos, curSector, dir, 64, 0);

					if(usetracer.results.hitLine
					&& usetracer.results.hitLine.special != 243
					&& usetracer.results.hitLine.special != 244)
					// Preventing drone from activating exit lines
					usetracer.results.hitLine.activate(self.master, usetracer.results.side, SPAC_PlayerActivate);
				}
				return ResolveState(null);
			}
			Loop;
		Death:
			LSDR A 1 { A_StartSound("play/aug/spy_drone/death"); death_lifetime = 35 * 10; }
		DeathLoop:
			DSDR A 1 { if(--death_lifetime <= 0) destroy(); }
			Loop;
	}
}
