class DD_Aug_Targeting : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

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
			    "the optic nerve with doped polyacetylene \"quantum\n"
			    "wires\" delivers situational info about a target.\n\n";

		_level = 1;
		disp_desc = disp_desc .. string.format("TECH ONE: Damage bonus is %g%%.\nHealth is visible.\n\n", (getDamageFactor() - 1) * 100);
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Damage bonus is %g%%.\nMax health and active augmentations are visible.\n\n", (getDamageFactor() - 1) * 100);
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Damage bonus is %g%%.\nAll augmentations are visible.\n\n", (getDamageFactor() - 1) * 100);
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Damage bonus is %g%%.\nAugmentation levels are visible.\n\n", (getDamageFactor() - 1) * 100);
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		disp_legend_desc = "LEGENDARY UPGRADE: Augmentation firmly\n"
				   "integrates with agent's mind, providing\n"
				   "extensive info on the last target they aimed\n"
				   "at, boosting overall offence effectiveness\n"
				   "against such target.";

		slots_cnt = 1;
		slots[0] = Eyes;
	}
	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("TARG0");
		tex_on = TexMan.checkForTexture("TARG1");
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
			dname = dname .. " [FRIENDLY])";
		return dname;
	}
	clearscope static string getAugDisplayName(DD_Augmentation aug)
	{
		if(aug is "DD_Aug_AggressiveDefenseSystem") return "ADS";
		else if(aug is "DD_Aug_AgilityEnhancement") return "Agility";
		else if(aug is "DD_Aug_BallisticProtection") return "Ballistic";
		else if(aug is "DD_Aug_CombatStrength") return "Strength";
		else if(aug is "DD_Aug_AggressiveDefenseSystem") return "ADS";
		else if(aug is "DD_Aug_EnergyShield") return "Energy";
		else if(aug is "DD_Aug_GravitationalField") return "Grav. Field";
		else if(aug is "DD_Aug_Regeneration") return "Regen";
		else if(aug is "DD_Aug_SpeedEnhancement") return "Speed";
		else return aug.disp_name;
	}

	// -------------
	// Engine events
	// -------------

	override void tick()
	{
		super.tick();

		if(!owner || !(owner is "PlayerPawn"))
			return;

		let look_tracer = new("DD_Targeting_Tracer");
		look_tracer.source = owner;

		vector3 dir = (AngleToVector(owner.angle, cos(owner.pitch)), -sin(owner.pitch));
		
		look_tracer.trace(owner.pos + (0, 0, PlayerPawn(owner).viewHeight), owner.curSector, dir, PLAYERMISSILERANGE, 0);

		Actor target_obj = look_tracer.hit_obj;
		if(target_obj)
			last_target_obj = target_obj;
		string ss = "look";
	}

	protected double getDamageFactor() { return 1.08 + 0.05 * getRealLevel(); }

	override void ownerDamageDealt(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor victim, int flags)
	{
		if(!enabled)
			return;

		newDamage = damage * getDamageFactor();
	}

	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		bool hud_dbg = false;
		vector2 off = CVar_Utils.getOffset("dd_targeting_info_off");
		off += (160, 0);

		if(CVar_UTils.isHUDDebugEnabled())
		{
			UI_Draw.str(hndl.aug_overlay_font_bold, "Baron of Hell", 0xFFFFFFFF,
					8 + off.x, 8 + off.y, -0.27, -0.27, UI_Draw_CenterText);
			UI_Draw.str(hndl.aug_overlay_font_bold, "Health 500 | 1000",
								0xFFFFFFFF, 8 + off.x, 13 + off.y, -0.27, -0.27, UI_Draw_CenterText);
			UI_Draw.str(hndl.aug_overlay_font_bold, "All: <56> ADS (3) | [Speed] (2)",
									0xFFFFFFFF, 8 + off.x, 18 + off.y, -0.27, -0.27, UI_Draw_CenterText);

			hud_dbg = true;
		}
		if(!enabled)
			return;


		if(!hud_dbg && last_target_obj && shouldDisplayObj(last_target_obj))
		{
			UI_Draw.str(hndl.aug_overlay_font_bold, getActorDisplayName(last_target_obj), 0xFFFFFFFF,
					8 + off.x, 8 + off.y, -0.27, -0.27, UI_Draw_CenterText);
			int target_hp = last_target_obj.health;

			// level 2: target max health and active augmentations
			if(getRealLevel() >= 2){
				int target_maxhp = last_target_obj.getSpawnHealth();
				UI_Draw.str(hndl.aug_overlay_font_bold, String.Format("Health %d | %d",
								target_hp, target_maxhp),
								0xFFFFFFFF, 8 + off.x, 13 + off.y, -0.27, -0.27, UI_Draw_CenterText);
				if(getRealLevel() == 2)
				{
					DD_AugsHolder aughld = DD_AugsHolder(last_target_obj.findInventory("DD_AugsHolder"));
					if(aughld)
					{
						string active_aug_list;
						for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
							if(aughld.augs[i] && aughld.augs[i].enabled)
								if(active_aug_list == "") active_aug_list = active_aug_list .. getAugDisplayName(aughld.augs[i]);
								else active_aug_list = active_aug_list .. " | " .. getAugDisplayName(aughld.augs[i]);
						if(active_aug_list.length() > 0)
							UI_Draw.str(hndl.aug_overlay_font_bold, "Active: " .. active_aug_list,
										0xFFFFFFFF, 8 + off.x, 18 + off.y, -0.27, -0.27, UI_Draw_CenterText);
					}
				}
			}
			// level 1: target health
			else if(getRealLevel() >= 1){
				UI_Draw.str(hndl.aug_overlay_font_bold, String.Format("Health %d",
								target_hp),
								0xFFFFFFFF, 8 + off.x, 13 + off.y, -0.27, -0.27);
			}

			// level 3: target and all augmentations, bioelectric energy level
			if(getRealLevel() >= 3){
				DD_AugsHolder aughld = DD_AugsHolder(last_target_obj.findInventory("DD_AugsHolder"));
				if(getRealLevel() == 3 && aughld){
					string aug_list;
					for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
						if(aughld.augs[i])
							if(aug_list == ""){
								aug_list = "<" .. string.format("%d", last_target_obj.countinv("DD_BioelectricEnergy")) .. "> ";
								aug_list = aug_list .. (aughld.augs[i].enabled ? "[" : "") .. getAugDisplayName(aughld.augs[i]) .. (aughld.augs[i].enabled ? "]" : "");
							}
							else aug_list = aug_list .. " | " .. (aughld.augs[i].enabled ? "[" : "") .. getAugDisplayName(aughld.augs[i]) .. (aughld.augs[i].enabled ? "]" : "");
					if(aug_list.length() > 0)
						UI_Draw.str(hndl.aug_overlay_font_bold, "All: " .. aug_list,
									0xFFFFFFFF, 8 + off.x, 18 + off.y, -0.27, -0.27, UI_Draw_CenterText);
				}
			}

			// level 4: all augmentations with levels
			if(getRealLevel() >= 4){
				DD_AugsHolder aughld = DD_AugsHolder(last_target_obj.findInventory("DD_AugsHolder"));
				if(aughld){
					string aug_list;
					for(uint i = 0; i < DD_AugsHolder.augs_slots; ++i)
						if(aughld.augs[i])
							if(aug_list == ""){
								aug_list = "<" .. string.format("%d", last_target_obj.countinv("DD_BioelectricEnergy")) .. "> ";
								aug_list = aug_list .. (aughld.augs[i].enabled ? "[" : "") .. getAugDisplayName(aughld.augs[i]) .. (aughld.augs[i].enabled ? "]" : "") .. " (" .. string.format("%d", aughld.augs[i].getRealLevel()) .. ")";
							}
							else aug_list = aug_list .. " | " .. (aughld.augs[i].enabled ? "[" : "") .. getAugDisplayName(aughld.augs[i]) .. (aughld.augs[i].enabled ? "]" : "") .. " (" .. string.format("%d", aughld.augs[i].getRealLevel()) .. ")";
					if(aug_list.length() > 0)
						UI_Draw.str(hndl.aug_overlay_font_bold, "All: " .. aug_list,
									0xFFFFFFFF, 8 + off.x, 18 + off.y, -0.27, -0.27, UI_Draw_CenterText);
				}
			}
		}
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
