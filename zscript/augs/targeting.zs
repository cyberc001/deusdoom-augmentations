struct DD_Aug_Targeting_Queue
{
	bool zoomed_in; // current status of zooming
	double tfov; // desired FOV or 0 if shouldn't be changed
}
class DD_Aug_Targeting : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	ui TextureID targ_frame; // frame background for rendering target's image
	ui TextureID scope; // scope displayed while zooming in

	DD_Aug_Targeting_Queue queue;
	double zoom_fov; // FOV when zoomed

	Actor last_target_obj; // Target to render info about

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 40; }

	override void install()
	{
		super.install();

		id = 17;
		disp_name = "Targeting";
		disp_desc = "Image-scaling and recognition provided by multiplexing\n"
			    "the optic nerve with doped polyacetylene \"quantum wires\"\n"
			    "delivers situational info about a target.\n\n"
			    "TECH ONE: Distance and health level are provided.\n\n"
			    "TECH TWO: Maximum health level of a target is provided.\n\n"
			    "TECH THREE: Current state of the target and their\n"
			    "targeted entity are provided additionaly.\n\n"
			    "TECH FOUR: Also grants an ability to capture image of\n"
			    "a target and an autonomous telescopic zoom.\n\n"
			    "Energy Rate: 40 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Augmentation firmly\n"
				   "integrates with agent's mind, providing\n"
				   "extensive info on the last target they aimed\n"
				   "at, boosting overall offence effectiveness\n"
				   "against such target.";

		slots_cnt = 1;
		slots[0] = Eyes;
		zoom_fov = 15.0;

		can_be_legendary = true;
	}
	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("TARG0");
		tex_on = TexMan.checkForTexture("TARG1");
		targ_frame = TexMan.checkForTexture("AUGUI20");
		scope = TexMan.checkForTexture("AUGUI38");
	}

	// ------------------
	// Internal functions
	// ------------------

	clearscope static bool shouldDisplayObj(Actor ac)
	{
		if(!ac.bShootable || ac.health <= 0)
			return false;
		return true;
	}
	clearscope string getActorDisplayName(Actor ac)
	{
		string dname;
		if(ac is "PlayerPawn")
			dname = ac.player.getUserName();
		else
			dname = ac.getTag("");
		if(ac.bFriendly)
			dname = dname .. " (friendly)";
		return dname;
	}

	// -------------
	// Engine events
	// -------------

	override void toggle()
	{
		super.toggle();
		if(!enabled && queue.zoomed_in){
			queue.zoomed_in = false;
			queue.tfov = 0;
			players[consoleplayer].setFOV(CVar.getCVar("fov", players[consoleplayer]).getFloat());
		}
	}

	override void tick()
	{
		super.tick();

		if(!owner || !(owner is "PlayerPawn"))
			return;

		if(queue.tfov != 0){
			owner.player.setFOV(queue.tfov);
			queue.tfov = 0;
		}

		let look_tracer = new("DD_Targeting_Tracer");
		look_tracer.source = owner;

		vector3 dir = (AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
		
		look_tracer.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, dir, PLAYERMISSILERANGE, 0);

		Actor target_obj = look_tracer.hit_obj;
		if(target_obj)
			last_target_obj = target_obj;
		string ss = "look";
	}


	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		bool hud_dbg = false;
		if(CVar_UTils.isHUDDebugEnabled())
		{
			vector2 off = CVar_Utils.getOffset("dd_targeting_info_off");
			UI_Draw.str(hndl.aug_overlay_font_bold, "Monster", 0xFFFFFFFF,
					4 + off.x, 22 + off.y, -0.35, -0.35);
			// level 1: target range
			UI_Draw.str(hndl.aug_overlay_font_bold, "Range 100 ft (1000 map units)",
							0xFFFFFFFF, 4 + off.x, 28 + off.y, -0.35, -0.35);
			// level 2: target max health
			UI_Draw.str(hndl.aug_overlay_font_bold, "Health 10000\\10000",
							0xFFFFFFFF, 4 + off.x, 34 + off.y, -0.35, -0.35);

			// level 3: target state, it's target and master
			UI_Draw.str(hndl.aug_overlay_font_bold, "Chasing DoomPlayer",
							0xFFFFFFFF, 4 + off.x, 40 + off.y, -0.35, -0.35);

			// level 4: target image
			UI_Draw.texture(targ_frame,
						4 + off.x, 51 + off.y,
						50 + 2,
						30 + 2);

			hud_dbg = true;
		}

		if(!enabled)
			return;
		if(queue.zoomed_in){
			UI_Draw.texture(scope,
					320/2-200/2, 0, 200, 200);
		}

		vector2 off = CVar_Utils.getOffset("dd_targeting_info_off");

		if(!hud_dbg && last_target_obj && shouldDisplayObj(last_target_obj))
		{
			UI_Draw.str(hndl.aug_overlay_font_bold, getActorDisplayName(last_target_obj), 0xFFFFFFFF,
					4 + off.x, 22 + off.y, -0.35, -0.35);
			double target_dist = ((last_target_obj.pos - owner.pos).length()
						- last_target_obj.radius - owner.radius);
			double target_ft_dist = target_dist
						/ 32 * 3.28; // see agressive defense system

			int target_hp = last_target_obj.health;

			UI_Draw.str(hndl.aug_overlay_font_bold, String.format("Range %.0f ft (%.0f map units)",
							round(target_ft_dist), round(target_dist)),
							0xFFFFFFFF, 4 + off.x, 28 + off.y, -0.35, -0.35);

			// level 2: target max health and active augmentations
			if(getRealLevel() >= 2){
				int target_maxhp = last_target_obj.getSpawnHealth();
				UI_Draw.str(hndl.aug_overlay_font_bold, String.Format("Health %d\\%d",
								target_hp, target_maxhp),
								0xFFFFFFFF, 4 + off.x, 34 + off.y, -0.35, -0.35);
				if(getRealLevel() == 2)
				{
					DD_AugsHolder aughld = DD_AugsHolder(last_target_obj.findInventory("DD_AugsHolder"));
					if(aughld)
					{
						string active_aug_list;
						for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
							if(aughld.augs[i] && aughld.augs[i].enabled)
								active_aug_list = active_aug_list .. ": " .. aughld.augs[i].disp_name .. " ";
						if(active_aug_list.length() > 0)
							UI_Draw.str(hndl.aug_overlay_font_bold, "Active augmentations" .. active_aug_list,
										0xFFFFFFFF, 4 + off.x, 42 + off.y, -0.35, -0.35);
					}
				}
			}
			// level 1: target range and health
			else if(getRealLevel() >= 1){
				UI_Draw.str(hndl.aug_overlay_font_bold, String.Format("Health %d",
								target_hp),
								0xFFFFFFFF, 4 + off.x, 34 + off.y, -0.35, -0.35);
			}

			// level 3: target state and it's target, also all augmentations
			if(getRealLevel() >= 3){
				UI_Draw.str(hndl.aug_overlay_font_bold, StateUtils.getTranslation(last_target_obj),
								0xFFFFFFFF, 4 + off.x, 40 + off.y, -0.35, -0.35);
				if(getRealLevel() == 3)
				{
					DD_AugsHolder aughld = DD_AugsHolder(last_target_obj.findInventory("DD_AugsHolder"));
					if(aughld)
					{
						string active_aug_list;
						for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
							if(aughld.augs[i])
								active_aug_list = active_aug_list .. ": " .. aughld.augs[i].disp_name .. " ";
						if(active_aug_list.length() > 0)
							UI_Draw.str(hndl.aug_overlay_font_bold, "Augmentations" .. active_aug_list,
										0xFFFFFFFF, 4 + off.x, 45 + off.y, -0.35, -0.35);
					}
				}
			}

			// level 4: target image and augmentations, including levels
			if(getRealLevel() >= 4){
				TextureID sprtex; bool flip;
				[sprtex, flip] = TextureUtils.getActorRenderSpriteTex(last_target_obj, owner);
				UI_Draw.texture(targ_frame,
							4 + off.x, 55 + off.y,
							UI_Draw.texWidth(sprtex, 0, 30) + 2,
							UI_Draw.texHeight(sprtex, 0, 30) + 2,
							flip ? UI_Draw_FlipX : 0);
				UI_Draw.texture(sprtex,
							5 + off.x, 56 + off.y, 0, 30);
				DD_AugsHolder aughld = DD_AugsHolder(last_target_obj.findInventory("DD_AugsHolder"));
				if(aughld)
				{
					string active_aug_list;
					for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
						if(aughld.augs[i])
							active_aug_list = active_aug_list .. ": " .. aughld.augs[i].disp_name .. " [" .. string.format("%d", aughld.augs[i]._level) .. "] ";
					if(active_aug_list.length() > 0)
						UI_Draw.str(hndl.aug_overlay_font_bold, "Augmentations" .. active_aug_list,
									0xFFFFFFFF, 4 + off.x, 45 + off.y, -0.35, -0.35);
				}
			}
		}
	}

	const target_damage_mult = 1.8;
	override void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		if(!enabled || !isLegendary())
			return;

		if(source == last_target_obj)
			newDamage = damage * target_damage_mult;
	}


	override bool inputProcess(InputEvent e)
	{
		super.inputProcess(e);

		if(!enabled)
			return false;
		if(e.type == UiEvent.Type_KeyDown)
		{
			if(KeyBindUtils.checkBind(e.KeyScan, "dd_togg_zoom")
			&& getRealLevel() >= 4)
			{
				queue.zoomed_in = !queue.zoomed_in;
				if(queue.zoomed_in){
					queue.tfov = zoom_fov;
				}
				else{
					queue.tfov = CVar.getCVar("fov", players[consoleplayer]).getFloat();
				}
			}
		}
		return false;
	}

}

class DD_Targeting_Tracer : LineTracer
{
	Actor source;
	Actor hit_obj;

	override ETraceStatus traceCallback()
	{
		if(results.hitType == TRACE_HitActor)
		{
			if(results.hitActor == source)
				return TRACE_Skip;
			if(!DD_Aug_Targeting.shouldDisplayObj(results.hitActor))
				return TRACE_Skip;
			hit_obj = results.hitActor;
			return TRACE_Stop;
		}
		if(results.hitType == TRACE_HitFloor || results.hitType == TRACE_HitCeiling){
			return TRACE_Stop;
		}
		if(results.hitType == TRACE_HitWall){
			if(results.tier == TIER_Middle && results.hitLine.flags & Line.ML_TWOSIDED > 0)
				return TRACE_Skip;
			return TRACE_Stop;
		}
		return TRACE_Skip;
	}
}
