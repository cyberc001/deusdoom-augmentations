class DD_Aug_AggressiveDefenseSystem : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	// Targeted projectiles projection
	ui DDLe_ProjScreen proj_scr;
	DDLe_SWScreen proj_sw;
	DDLe_GLScreen proj_gl;
	ui DDLe_Viewport vwport;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 65; }

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

		id = 8;
		disp_name = "Aggressive Defense System";
		disp_desc = "Aerosol nanoparticles are released upon the detection\n"
			    "of objects fitting the electromagnetic threat profile of\n"
			    "various missiles, like rockets or seeking missiles.\n"
			    "These nanoparticles will prematurely detonate such\n"
			    "objects prior to reaching the agent.\n\n";

		_level = 1;
		disp_desc = disp_desc .. string.format("Effect radius is %g. Cooldown is %.2gs.\n\n", getRange(), getBaseCD() / 35.);
		_level = 2;
		disp_desc = disp_desc .. string.format("Effect radius is %g. Cooldown is %.2gs.\n\n", getRange(), getBaseCD() / 35.);
		_level = 3;
		disp_desc = disp_desc .. string.format("Effect radius is %g. Cooldown is %.2gs.\n\n", getRange(), getBaseCD() / 35.);
		_level = 4;
		disp_desc = disp_desc .. string.format("Effect radius is %g. Cooldown is %.2gs.\n\n", getRange(), getBaseCD() / 35.);
		_level = 1;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		legend_count = 2;
		legend_names[0] = "Reflect projectiles";
		legend_names[1] = "Destroy all projectiles";

		slots_cnt = 1;
		slots[0] = Cranial;

		initProjection();
	}

	override void UIInit()
	{
		tex_off = TexMan.checkForTexture("AGRDSYS0");
		tex_on = TexMan.checkForTexture("AGRDSYS1");
	}

	int destr_cd;		    // projectile desctruction cooldown

	clearscope double getRange()
	{
		return 140 + 20 * (getRealLevel() - 1);
	}
	int getBaseCD()
	{
		return (55 - 10 * (getRealLevel() - 1)) * (owner && owner.bIsMonster ? 3 : 1);
	}

	array<double> proj_dispx;
	array<double> proj_dispy;
	array<double> proj_dispz;

	const reflect_mul = 2; // velocity factor of reflected projectiles

	void detonateProjInRange()
	{
		if(!owner)
			return;

		if(destr_cd > 0)
			--destr_cd;
		proj_dispx.clear();
		proj_dispy.clear();
		proj_dispz.clear();

		Actor proj;
		double cd_ml = 1;
		let ddevh = DD_AugsEventHandler(StaticEventHandler.Find("DD_AugsEventHandler"));
		for(uint i = 0; i < ddevh.proj_list.size(); ++i)
		{
			proj = ddevh.proj_list[i];
			if(!proj){
				ddevh.proj_list.delete(i); --i; continue;
			}

			bool can_destroy = legend_installed == 1 || RecognitionUtils.projCanBeDestroyed(proj, cd_ml, owner.bIsMonster);

			if(proj.countinv("DD_ProjDied") || !can_destroy || owner.Distance3D(proj) > getRange() * 8.0 || proj.target == owner || (owner.bIsMonster && proj.target && proj.target.bIsMonster && proj.tracer != owner))
				continue;
			if(owner.Distance3D(proj) > getRange()) {
				proj_dispx.push(proj.pos.x);
				proj_dispy.push(proj.pos.y);
				proj_dispz.push(proj.pos.z);
			}
			else {
				if(destr_cd == 0){
					Actor.Spawn("DD_AggressiveDefenseSystem_FlashGFX", proj.pos);
					destr_cd = getBaseCD() * cd_ml * (legend_installed == 1 ? min(max(proj.speed / 10., 1), 4) : 1);
					proj.giveInventory("DD_ProjDied", 1);
					if(legend_installed == 0){
						if(proj.bSEEKERMISSILE)
							proj.A_ChangeVelocity(-proj.vel.x,
								     -proj.vel.y,
								     -proj.vel.z, CVF_REPLACE);
						else
							proj.A_ChangeVelocity(-proj.vel.x * reflect_mul,
								     -proj.vel.y * reflect_mul,
								     -proj.vel.z * reflect_mul, CVF_REPLACE);

						proj.tracer = proj.target;
						proj.target = owner;

						proj.giveInventory("DD_ProjDamageMod", 1);
						let dmod = DD_ProjDamageMod(proj.findInventory("DD_ProjDamageMod"));
						dmod.mult = 2.0;
					}
					else
						proj.die(proj, proj);
				}
			}
		}
	}

	override void tick()
	{
		super.tick();
		if(!enabled)
			return;
		detonateProjInRange();
	}

	ui int ui_beep_timer; // timer between beeps; counts FROM zero till a certain value
			      // based on proximity to closest projectile that can be detonated.

	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		bool hud_dbg = false;
		if(CVar_Utils.isHUDDebugEnabled()){
			vector2 off = CVar_Utils.getOffset("dd_agdefsys_cd_off");
			UI_Draw.str(hndl.aug_overlay_font_bold,
					String.Format("Aggr.Def.Sys. CD 1.23s"),
					0xFFFFFFFF, 4 + off.x, 4 + off.y, -0.4, -0.4);
			hud_dbg = true;
		}

		if(!enabled)
			return;

		if(destr_cd > 0 && !hud_dbg){
			vector2 off = CVar_Utils.getOffset("dd_agdefsys_cd_off");
			UI_Draw.str(hndl.aug_overlay_font_bold,
					String.Format("Aggr.Def.Sys. CD %.2fs", double(destr_cd) / 35),
					0xFFFFFFFF, 4 + off.x, 4 + off.y, -0.4, -0.4);
		}

		// Projecting any incoming projectiles' coordinates and then rendering a string
		vwport.fromHUD();
		prepareProjection();

		proj_scr.cacheResolution();
		proj_scr.cacheFOV();
		proj_scr.orientForRenderOverlay(e);
		proj_scr.beginProjection();

		double proj_min_dist = 999999;

		for(uint i = 0; i < proj_dispx.size(); ++i)
		{
			vector3 proj_pos = (proj_dispx[i], proj_dispy[i], proj_dispz[i]);
			proj_scr.projectWorldPos(proj_pos);
			vector2 proj_norm = proj_scr.projectToNormal();
			vector2 str_pos = vwport.sceneToWindow(proj_norm);

			if(!vwport.isInside(proj_norm) || !proj_scr.isInScreen())
				continue;

			str_pos.x *= double(320) / screen.getWidth();
			str_pos.y *= double(200) / screen.getHeight();

			double text_w = -0.15;
			double text_h = -0.15;

			double tstr_w = UI_Draw.strWidth(hndl.aug_overlay_font_bold, "* ADS Tracking *", text_w, text_h);
			double tstr_h = UI_Draw.strHeight(hndl.aug_overlay_font_bold, "* ADS Tracking *", text_w, text_h);
			double proj_dist = ((proj_pos - owner.pos).length()
						- owner.radius);
			double proj_ft_dist = proj_dist
						/ 32 * 3.28; // roughly "converting" to meters and then to feet
									 // https://doomwiki.org/wiki/Map_unit
			if(proj_dist < proj_min_dist)
				proj_min_dist = proj_dist;

			UI_Draw.str(hndl.aug_overlay_font_bold, "* ADS Tracking *", 0xFFFF0000,
					str_pos.x - tstr_w/2, str_pos.y, text_w, text_h);
			UI_Draw.str(hndl.aug_overlay_font_bold, string.format("Range %.0f ft (%.0f map units)",
								round(proj_ft_dist), round(proj_dist)),
					0xFFFF0000,
					str_pos.x - tstr_w/2, str_pos.y + tstr_h + 1, text_w, text_h);
		}

		if(proj_min_dist < 999999)
		{
			if(ui_beep_timer >= (proj_min_dist / getRange() * 4.0) * 2){
				SoundUtils.uiStartSound("ui/aug/agressive_defense_system_beep", owner);
				ui_beep_timer = 0;
			}
			else
				++ui_beep_timer;
		}
	}
}

class DD_ProjDied : Inventory {}
class DD_ProjDamageMod : Inventory
{
	double mult;
	// multiplication is done through DD_EventHandler
}

class DD_AggressiveDefenseSystem_FlashGFX : Actor
{
	default
	{
		+NOBLOCKMAP
		+NOGRAVITY
		+BRIGHT
		+NOTELEPORT

		XScale 0.2;
		YScale 0.2;
	}

	vector2 scale;
	double alpha;

	states
	{
		Spawn:
			DDFX O 0 {scale = (0.2, 0.2); alpha = 1;}
			DDFX OOOO 1
			{
				scale.x += 0.3; scale.y += 0.3;
				A_SetScale(scale.x, scale.y);
			}
			DDFX OOOO 1
			{
				alpha -= 0.25;
				A_SetRenderStyle(1 - alpha, Style_Translucent);
			}
			Stop;
	}
}
