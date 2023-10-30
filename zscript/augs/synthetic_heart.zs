class DD_Aug_SyntheticHeart : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;
	ui TextureID tex_passive;

	override TextureID get_ui_texture(bool state)
	{
		return passive ? tex_passive : (state ? tex_on : tex_off);
	}

	override int get_base_drain_rate(){ return 120; }

	override void install()
	{
		super.install();

		max_level = 1;

		id = 15;
		disp_name = "Synthetic Heart";
		disp_desc = "This synthetic heart circulates not only blood but a\n"
			    "steady concentration of mechanochemical power cells,\n"
			    "smart phagocytes, and liposomes containing prefab\n"
			    "diamondoid machine parts, resulting in upgraded\n"
			    "performance for all installed augmentations.\n\n"
			    "<UNATCO OPS FILE NOTE JR133-VIOLET> It will\n"
			    "enhance any augmentation past its maximum upgrade\n"
			    "level, but not as effectively.\n"
			    "-- Jaime Reyes <END NOTE>\n\n";
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		legend_count = 2;
		legend_names[0] = "+1 level past level 4, works passively";
		legend_names[1] = "+2 levels past level 4";

		slots_cnt = 3;
		slots[0] = Torso1;
		slots[1] = Torso2;
		slots[2] = Torso3;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("SYNHRT0");
		tex_on = TexMan.CheckForTexture("SYNHRT1");
		tex_passive = TexMan.CheckForTexture("SYNHRT2");
	}

	override void tick()
	{
		super.tick();
		passive = (legend_installed == 0);

		if(!owner)
			return;
		let aughld = DD_AugsHolder(owner.findInventory("DD_AugsHolder"));
		if(!aughld)
			return;

		if(enabled || passive){
			aughld.level_boost = (legend_installed == 1 ? 2 : 1);
			aughld.postmax_level_boost = (legend_installed != -1);
		}
		else{
			aughld.level_boost = 0;
			aughld.postmax_level_boost = false;
		}
	}
}
