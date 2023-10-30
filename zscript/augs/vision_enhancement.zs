CLASS DD_Aug_VisionEnhancement : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

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

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("VISENCH0");
		tex_on = TexMan.CheckForTexture("VISENCH1");
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
			    "TECH FOUR: Long range sonar imaging.\n\n";

		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		legend_count = 2;
		legend_names[0] = "remove night vision tint";
		legend_names[1] = "display objects in full color";

		slots_cnt = 1;
		slots[0] = Eyes;

		initProjection();
	}

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
				if(legend_installed != 0)
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
				if(trace_dir.length() > 0) trace_dir /= trace_dir.length();
				sight_tr.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, trace_dir, 999999.0, 0);

				if(!obj.bISMONSTER || obj.Alpha >= 1){
					if(sight_tr.results.hitActor == obj){
						sight_tr = new("DD_VisionEnhancement_SightTracer");
						sight_tr.ignore = owner;
						sight_tr.seek = obj;
						vector3 trace_dir = obj.pos + (0, 0, obj.height)
								  - (owner.pos + (0, 0, PlayerPawn(owner).viewHeight));
						if(trace_dir.length() > 0) trace_dir /= trace_dir.length();
						sight_tr.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, trace_dir, 999999.0, 0);
						if(sight_tr.results.hitActor == obj)
							continue;
					}
				}

				int not_inside_x = 0, not_inside_y = 0;

				proj_scr.projectWorldPos(obj.pos);
				vector2 proj_norm = proj_scr.projectToNormal();
				if(!vwport.isInside(proj_norm) || !proj_scr.isInScreen())
					++not_inside_y;
				vector2 sonar_pos_bot = vwport.sceneToWindow(proj_norm);
				proj_scr.projectWorldPos(obj.pos + (0, 0, obj.height));
				proj_norm = proj_scr.projectToNormal();
				if(!vwport.isInside(proj_norm) || !proj_scr.isInScreen())
					++not_inside_y;

				vector2 sonar_pos_top = vwport.sceneToWindow(proj_norm);

				vector3 dir = (Actor.AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
				dir.z = 0;

				proj_scr.projectWorldPos(obj.pos + (RotateVector((dir.x, dir.y), 90), dir.z) * obj.radius);
				proj_norm = proj_scr.projectToNormal();
				if(!vwport.isInside(proj_norm) || !proj_scr.isInScreen())
					++not_inside_x;
				vector2 sonar_pos_left = vwport.sceneToWindow(proj_norm);
				proj_scr.projectWorldPos(obj.pos + (RotateVector((dir.x, dir.y), -90), dir.z) * obj.radius);
				proj_norm = proj_scr.projectToNormal();
				if(!vwport.isInside(proj_norm) || !proj_scr.isInScreen())
					++not_inside_x;
				vector2 sonar_pos_right = vwport.sceneToWindow(proj_norm);

				if(not_inside_x == 2 || not_inside_y == 2)
					continue;
				
				sonar_pos_top.x *= double(320) / screen.getWidth();
				sonar_pos_top.y *= double(200) / screen.getHeight();
				sonar_pos_bot.x *= double(320) / screen.getWidth();
				sonar_pos_bot.y *= double(200) / screen.getHeight();
				sonar_pos_left.x *= double(320) / screen.getWidth();
				sonar_pos_left.y *= double(200) / screen.getHeight();
				sonar_pos_right.x *= double(320) / screen.getWidth();
				sonar_pos_right.y *= double(200) / screen.getHeight();
	
				// Drawing object sprite
				TextureID spritetex; bool flip; bool wildcarded;
				[spritetex, flip, wildcarded] = TextureUtils.getActorRenderSpriteTex(obj, owner);
				double tex_w = 1, tex_h = 1;
				if(wildcarded && obj is "Inventory"){
					spritetex = Inventory(obj).AltHUDIcon;
					tex_w = tex_h = 0.25;
				}

				if(legend_installed == 1)
					UI_Draw.texture(spritetex,
						sonar_pos_left.x, sonar_pos_top.y,
						(sonar_pos_right.x - sonar_pos_left.x) * tex_w, (sonar_pos_bot.y - sonar_pos_top.y) * tex_h,
						(flip ? 0 : UI_Draw_FlipX)
						| (obj.scale.y < 0 ? UI_Draw_FlipY : 0));

				else
					UI_Draw.textureStencil(spritetex,
						sonar_pos_left.x, sonar_pos_top.y,
						(sonar_pos_right.x - sonar_pos_left.x) * tex_w, (sonar_pos_bot.y - sonar_pos_top.y) * tex_h,
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
