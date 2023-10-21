struct DD_Aug_AgilityEnhancement_Queue
{
	vector3 dashvel[5];
	double deacc;

	int vwheight_timer;
	double vwheight_prev;
	double vwheight_delta;

	int falldmg_immune_timer;
}
class DD_Aug_AgilityEnhancement : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	DD_Aug_AgilityEnhancement_Queue queue;
	ui bool mov_keys_held[4];
	// amount of ticks passed since a key was pressed last time,
	// used to engage dashses.
	// 0 - forward, 1 - backward, 2 - left, 3 - right, 4 - up
	ui int mov_keys_timer[5];

	int dash_cd;
	const vwheight_time = 20;
	const vwheight_time_coff = 0.30;

	const falldmg_immune_time = 20;

	bool use_doubletap_scheme; // keeps the value of dd_dash_on_doubletap CVAR between toggles
	int dash_tap_time; // also keeps a value of dd_dash_doubletap_timer CVAR
	bool dash_held;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 55; }

	override void install()
	{
		super.install();

		id = 18;
		disp_name = "Agility Enhancement";
		disp_desc = "The necessary muscle movements for quick and precise\n"
			    "body motions determined continuously with reactive\n"
			    "kinematics equations produced by embedded\n"
			    "nanocomputers, allowing an agent to quickly change\n"
			    "their momentum even while in air.\n\n"
			    "TECH ONE: Deceleration is a bit faster, agent can\n"
			    "do short dashes and double jumps.\n\n"
			    "TECH TWO: Deceleration is faster, agent can do\n"
			    "longer dashes and double jumps.\n\n"
			    "TECH THREE: Decelration is significantly faster and\n"
			    "agent can perform stunningly long dashes.\n\n"
			    "TECH FOUR: Agent decelerates almost instantly and\n"
			    "can cross entire rooms in one leap.\n\n"
			    "Energy Rate: 55 Units/Minute\n\n";

		disp_legend_desc = "LEGENDARY UPGRADE: Agent leaps so quick\n"
				   "it seems they are teleporting.\n"
				   "They also can slow down their fall.\n";

		slots_cnt = 1;
		slots[0] = Legs;

		can_be_legendary = true;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("SILENT0");
		tex_on = TexMan.CheckForTexture("SILENT1");
	}


	const levitation_velz_cap = 1.0;
	const levitation_velz_deacc = 15.0;

	clearscope double getDeaccFactor()
	{
		return 0.2 + 0.35 * (getRealLevel() - 1);
	}
	clearscope double getDashVel()
	{
		if(isLegendary())	return 350;
		else		return 26 + 13 * (getRealLevel() - 1);
	}
	protected clearscope int getDashCD()
	{
		return 60 - 8 * (getRealLevel() - 1) - (isLegendary() ? 14 : 0);
	}
	protected double getImpactNegationFactor() { return 0.25 + getRealLevel() * 0.15; }
	protected double getImpactThreshold() { return 50 + getRealLevel() * 25; }


	override void toggle()
	{
		super.toggle();

		if(owner && owner.player){
			use_doubletap_scheme = CVar.getCVar("dd_dash_on_doubletap", owner.player).getFloat();
			dash_tap_time = CVar.getCVar("dd_dash_doubletap_timer", owner.player).getInt();
		}
	}

	// ------
	// Events
	// ------

	override void tick()
	{
		super.tick();
		if(!owner || !(owner is "PlayerPawn"))
			return;

		// View height change handling
		if(queue.vwheight_timer > 0){
			--queue.vwheight_timer;

			if(queue.vwheight_timer > vwheight_time * vwheight_time_coff)
				owner.player.viewHeight -= queue.vwheight_delta / (vwheight_time * vwheight_time_coff);
			else
				owner.player.viewHeight += queue.vwheight_delta / (vwheight_time * (1 - vwheight_time_coff));

			if(queue.vwheight_timer == 0)
				owner.player.viewHeight = queue.vwheight_prev;
		}
		if(!enabled)
			return;

		// preventing HDest incap from happening
		if(DD_ModChecker.isLoaded_HDest() && DD_PatchChecker.isLoaded_HDest() && queue.falldmg_immune_timer > 0){
			Class<Actor> lv_cls = ClassFinder.findActorClass("DD_HDLastVelCorrector");
			Actor lastvelcor = spawn(lv_cls);
			lastvelcor.target = owner;
			lastvelcor.postBeginPlay();
			lastvelcor.destroy();
		}

		if(abs(queue.deacc) > 0)
		{
			if(abs(owner.vel.x) > queue.deacc){
				if(owner.warp(owner, owner.vel.x, owner.vel.y, owner.vel.z, 0, WARPF_TESTONLY)){
					owner.A_ChangeVelocity((owner.vel.x > 0 ? -1 : 1)*queue.deacc, 0, 0);
					owner.warp(owner, -owner.vel.x, -owner.vel.y, -owner.vel.z, 0, WARPF_TESTONLY);
				}
			}
			else
				owner.A_ChangeVelocity(0, owner.vel.y, owner.vel.z, CVF_REPLACE);
			if(abs(owner.vel.y) > queue.deacc){
				if(owner.warp(owner, owner.vel.x, owner.vel.y, owner.vel.z, 0, WARPF_TESTONLY)){
					owner.A_ChangeVelocity(0, (owner.vel.y > 0 ? -1 : 1)*queue.deacc, 0);
					owner.warp(owner, -owner.vel.x, -owner.vel.y, -owner.vel.z, 0, WARPF_TESTONLY);
				}
			}
			else
				owner.A_ChangeVelocity(owner.vel.x, 0, owner.vel.z, CVF_REPLACE);
		}

		if(dash_cd > 0)
			--dash_cd;
		for(uint i = 0; i < 5; ++i)
		{
			if(dash_cd == 0 && queue.dashvel[i].length() > 0){
				if(!isLegendary())
				{
					if(DD_ModChecker.isLoaded_HDest())
						queue.falldmg_immune_timer = falldmg_immune_time;

					owner.A_ChangeVelocity(queue.dashvel[i].x, queue.dashvel[i].y, queue.dashvel[i].z, CVF_RELATIVE);
					dash_cd = getDashCD();
					if(queue.dashvel[i].z == 0 && queue.vwheight_timer == 0){
						queue.vwheight_prev = owner.player.viewHeight;
						queue.vwheight_timer = vwheight_time;
						queue.vwheight_delta = owner.player.viewHeight * 0.8;
					}
				}
				else
				{
					dash_cd = getDashCD();

					double warpstep = 8;
					double dist = warpstep / ceil(queue.dashvel[i].length());
					for(uint _try = 0; _try < ceil(queue.dashvel[i].length()); _try += warpstep)
					{
						if(!owner.warp(owner, queue.dashvel[i].x * dist,
								 -queue.dashvel[i].y * dist,
								  queue.dashvel[i].z * dist,
								0, WARPF_USECALLERANGLE))
							break;
					}
				}
			}
			queue.dashvel[i] = (0, 0, 0);
		}
	}

	override void ownerDamageTaken(int damage, Name damageType, out int newDamage,
					Actor inflictor, Actor source, int flags)
	{
		// Hdest compat for preventing player from taking "falling" damage when dashing
		if(enabled && damageType == "falling"){
			if(damage <= getImpactThreshold() || queue.falldmg_immune_timer > 0)
				newDamage = 0;
			else
				newDamage = damage * (1 - getImpactNegationFactor());

			Class<Actor> st_cls = ClassFinder.findActorClass("DD_HDStunTaker");
			Actor stuntaker = spawn(st_cls);
			stuntaker.target = owner;
		}
	}


	override void UITick()
	{
		for(uint i = 0; i < 5; ++i)
		{
			if(use_doubletap_scheme && mov_keys_timer[i] <= dash_tap_time)
				++mov_keys_timer[i];
		}
	}

	override bool inputProcess(InputEvent e)
	{
		if(e.type == InputEvent.Type_KeyDown)
		{
			if(isLegendary() && KeyBindUtils.checkBind(e.keyScan, "+jump"))
			{ // levitating in air
				EventHandler.sendNetworkEvent("dd_levitate", 1);
			}

			if(KeyBindUtils.checkBind(e.keyScan, "+forward")) mov_keys_held[0] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+back")) mov_keys_held[1] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) mov_keys_held[2] = true;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) mov_keys_held[3] = true;

			if(mov_keys_held[0] || mov_keys_held[1] || mov_keys_held[2] || mov_keys_held[3])
				EventHandler.sendNetworkEvent("dd_grip", 0);

			if(use_doubletap_scheme)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
				{
					if(mov_keys_timer[0] <= dash_tap_time && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 0);
					mov_keys_timer[0] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
				{
					if(mov_keys_timer[1] <= dash_tap_time && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 1);
					mov_keys_timer[1] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
				{
					if(mov_keys_timer[2] <= dash_tap_time && enabled) 
						EventHandler.sendNetworkEvent("dd_vdash", 2);
					mov_keys_timer[2] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
				{
					if(mov_keys_timer[3] <= dash_tap_time && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 3);
					mov_keys_timer[3] = 0;
				}
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
				{
					if(mov_keys_timer[4] <= dash_tap_time && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 4);
					mov_keys_timer[4] = 0;
				}
			}
			else
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
					mov_keys_timer[0] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
					mov_keys_timer[1] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
					mov_keys_timer[2] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
					mov_keys_timer[3] = 1;
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
					mov_keys_timer[4] = 1;

				else if(KeyBindUtils.checkBind(e.keyScan, "dd_dash")){
					if(mov_keys_timer[0] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 0);
					else if(mov_keys_timer[1] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 1);
					else if(mov_keys_timer[2] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 2);
					else if(mov_keys_timer[3] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 3);
					else if(mov_keys_timer[4] && enabled)
						EventHandler.sendNetworkEvent("dd_vdash", 4);
				}
			}
		}
		if(e.type == InputEvent.Type_KeyUp)
		{
			if(isLegendary() && KeyBindUtils.checkBind(e.keyScan, "+jump"))
			{ // stopping levitating in air
				EventHandler.sendNetworkEvent("dd_levitate", 0);
			}

			if(KeyBindUtils.checkBind(e.keyScan, "+forward")) mov_keys_held[0] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+back")) mov_keys_held[1] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveleft")) mov_keys_held[2] = false;
			if(KeyBindUtils.checkBind(e.keyScan, "+moveright")) mov_keys_held[3] = false;
			if(!mov_keys_held[0] && !mov_keys_held[1] && !mov_keys_held[2] && !mov_keys_held[3] && enabled)
					EventHandler.sendNetworkEvent("dd_grip", 1);
			if(!use_doubletap_scheme)
			{
				if(KeyBindUtils.checkBind(e.keyScan, "+forward"))
					mov_keys_timer[0] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+back"))
					mov_keys_timer[1] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveleft"))
					mov_keys_timer[2] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+moveright"))
					mov_keys_timer[3] = 0;
				else if(KeyBindUtils.checkBind(e.keyScan, "+jump"))
					mov_keys_timer[4] = 0;
			}
		}
		return false;
	}

	override void drawOverlay(RenderEvent e, DD_EventHandler hndl)
	{
		if(CVar_Utils.isHUDDebugEnabled()){
			UI_Draw.str(hndl.aug_overlay_font_bold,
					String.Format("Dash CD 1.23s", double(dash_cd) / 35),
					0xFFFFFFFF, 4, 12, -0.4, -0.4);
			return;
		}

		if(!enabled)
			return;

		if(dash_cd > 0)
			UI_Draw.str(hndl.aug_overlay_font_bold,
					String.Format("Dash CD %.2fs", double(dash_cd) / 35),
					0xFFFFFFFF, 4, 12, -0.4, -0.4);
	}
}
