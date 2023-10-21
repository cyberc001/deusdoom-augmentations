class DD_Aug_VisionEnhancement : DD_Augmentation
{
	TextureID tex_off;
	TextureID tex_on;


	DD_VisionEnhancement_LightDummy dlight;

	// For imitation of sonar imaging
	ui DDLe_ProjScreen proj_scr;
	DDLe_SWScreen proj_sw;
	DDLe_GLScreen proj_gl;
	ui DDLe_Viewport vwport;
	

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 60; }

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
			switch(renderer_Type.getInt())
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

		id = 9;
		disp_name = "Vision Enhancement";
		disp_desc = "By bleaching selected rod photoreceptors and\n"
			    "saturating them with metarhodopsin XII, the\n"
			    "\"nightvision\" present in most nocturnal animals\n"
			    "can be duplicated. Subsequent upgrades and\n"
			    "modifications add sonar-resonance imaging that\n"
			    "effectively allows an agent to see through walls.\n\n"
			    "TECH ONE: Agent emits certain amount of light,\n"
			    "illuminating area around them.\n\n"
			    "TECH TWO: Night vision.\n\n"
			    "TECH THREE: Close range sonar imaging.\n\n"
			    "TECH FOUR: Long range sonar imaging.\n\n"
			    "Energy Rate: 60 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Augmentation aquires\n"
				   "capability to scan sonar imaging signatures\n"
				   "to get a complete picture of objects through\n"
				   "walls using an enormous database of agent's\n"
				   "vision recordings. It also improves upon\n"
				   "chemical structure of metarhodopsin XII,\n"
				   "getting rid of night vision green tint.";


		tex_off = TexMan.CheckForTexture("VISENCH0");
		tex_on = TexMan.CheckForTexture("VISENCH1");

		slots_cnt = 1;
		slots[0] = Eyes;

		initProjection();

		can_be_legendary = true;
	}


	// ------------------
	// Internal functions
	// ------------------

	protected clearscope double getSonarRange() { return 400.0 + (getRealLevel() - 3.0) * 256.0; }

	protected clearscope bool shouldReveal(Actor ac)
	{
		int res = RecognitionUtils.displayedSonar(ac);
		if(res == -1) return false;
		else if(res == 1) return true;

		if(ac.health <= 0)
			return false;
		return true;
	}

	// -------------
	// Engine events
	// -------------

	override void toggle()
	{
		super.toggle();

		if(enabled){
			if(getRealLevel() == 1){
				dlight = DD_VisionEnhancement_LightDummy(Actor.spawn("DD_VisionEnhancement_LightDummy"));
				dlight.target = owner;
				if(owner.player)
					dlight.warp_offset.z = owner.player.viewHeight;
			}
		}
		else{
			if(getRealLevel() == 1 && dlight){
				dlight.destroy();
			}
		}
	}

	override void tick()
	{
		super.tick();

		PlayerInfo pl = owner.player;
		if(!pl)
			return;

		if(enabled){
			if(getRealLevel() >= 2){
				if(!isLegendary())
					Shader.setEnabled(pl, "DD_NightVision", true);
				owner.giveInventory("DD_VisionEnhancement_Amp", 1);
			}
		}
		else{
			if(getRealLevel() >= 2){
				Shader.setEnabled(pl, "DD_NightVision", false);
				owner.takeInventory("DD_VisionEnhancement_Amp", 1);
			}
		}
	}


	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(!enabled)
			return;
		if(!(owner is "PlayerPawn"))
			return;

		PlayerInfo pl = owner.player;
		if(getRealLevel() >= 3)
		{
			vwport.fromHUD();
			prepareProjection();

			proj_scr.cacheResolution();
			proj_scr.cacheFOV();
			proj_scr.orientForRenderOverlay(e);
			proj_scr.beginProjection();

			Actor obj;
			BlockThingsIterator it = BlockThingsIterator.Create(owner, getSonarRange());
			while(it.next())
			{
				obj = it.thing;
				if(!shouldReveal(obj))
					continue;
				if(owner.distance3D(obj) > getSonarRange())
					continue;
				if(obj == owner)
					continue;

				// First we check if actor is in LOS and shouldn't be rendered
				let sight_tr = new("DD_VisionEnhancement_SightTracer");
					sight_tr.ignore = owner;
					sight_tr.seek = obj;
				vector3 trace_dir = obj.pos
						  - (owner.pos + (0, 0, PlayerPawn(owner).viewHeight));
				if(trace_dir.length() == 0)
					continue;
				trace_dir /= trace_dir.length();
				sight_tr.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, trace_dir, 999999.0, 0);
				if(sight_tr.results.hitActor == obj && obj.Alpha > 0)
					continue;
			

				vector3 obj_pos = obj.pos;
				proj_scr.projectWorldPos(obj_pos);
				vector2 proj_norm = proj_scr.projectToNormal();
				vector2 sonar_pos = vwport.sceneToWindow(proj_norm);
	
				if(!vwport.isInside(proj_norm) || !proj_scr.isInScreen())
					continue;
	
				sonar_pos.x *= double(320) / screen.getWidth();
				sonar_pos.y *= double(200) / screen.getHeight();
	
				// Drawing object sprite
				TextureID spritetex; bool flip;
				[spritetex, flip] = TextureUtils.getActorRenderSpriteTex(obj, owner);
	
				vector3 objvec = obj.pos - owner.pos;
				double objdist = objvec.length();
				double texcoff;
				if(objdist != 0)
					texcoff = 1 / (objdist / 164.0);
				else
					texcoff = 1.0;
				double tex_scale_w = abs(obj.scale.x) * texcoff;
				double tex_scale_h = abs(obj.scale.y) * texcoff;
				double texw = UI_Draw.texWidth(spritetex, -1, -1) * tex_scale_w;
				double texh = UI_Draw.texHeight(spritetex, -1, -1) * tex_scale_h;
				if(obj.scale.x < 0)
					flip = !flip;

				if(isLegendary())
					UI_Draw.texture(spritetex,
						sonar_pos.x - texw/2,
						sonar_pos.y - texh,
						texw, texh,
						(flip ? 0 : UI_Draw_FlipX)
						| (obj.scale.y < 0 ? UI_Draw_FlipY : 0));
				else
					UI_Draw.textureStencil(spritetex,
						sonar_pos.x - texw/2,
						sonar_pos.y - texh,
						texw, texh,
						color(255, 255, 255),
						(flip ? 0 : UI_Draw_FlipX)
						| (obj.scale.y < 0 ? UI_Draw_FlipY : 0));
			}
		}
	}
}


class DD_VisionEnhancement_LightDummy : Actor
{
	vector3 warp_offset;

	states
	{
		Spawn:
			TNT0 A 1 A_Warp(AAPTR_TARGET, warp_offset.x, warp_offset.y, warp_offset.z);
			Loop;
	}
}
class DD_VisionEnhancement_Amp : PowerTorch
{
	default
	{
		Powerup.duration -1;
	}
}

class DD_VisionEnhancement_SightTracer : LineTracer
{
	Actor ignore;
	Actor seek;

	override ETraceStatus traceCallback()
	{
		if(results.hitType == TRACE_HitActor && results.hitActor == ignore)
			return TRACE_Skip;
		if(results.hitType == TRACE_HitWall && results.tier == TIER_Middle && results.hitLine.flags & Line.ML_TWOSIDED > 0)
			return TRACE_Skip;
		if(results.hitType == TRACE_HitWall || results.hitType == TRACE_HitFloor || results.hitType == TRACE_HitCeiling
		   || results.hitActor == seek){
			if(results.hitType != TRACE_HitActor)
				results.hitActor = null;
			return TRACE_Stop;
		}
		return TRACE_Skip;
	}
}
