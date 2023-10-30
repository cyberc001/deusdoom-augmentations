class UI_DDInstalledAugButton : UI_Widget
{
	ui int aug_slot;
	ui bool lgnd_face_left; // whether the menu for legendary upgrades should appear on the left 
	ui int prev_lgnd;

	UI_Augs parent_wnd;
	UI_Augs_Sidepanel sidepanel;

	ui double tex_w;
	ui double tex_h;

	override void UIInit()
	{
		prev_lgnd = 0;
	}

	override void drawOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));

		if(aughld.augs[aug_slot])
			UI_Draw.texture(aughld.augs[aug_slot].get_ui_texture(aughld.augs[aug_slot].enabled),
						x, y, tex_w, tex_h);
	}

	override void UITick()
	{
		// update with legendary description when player clicks "Perfect"
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));
		if(sidepanel.aug_sel == aug_slot
		&& aughld.augs[aug_slot].legend_installed != prev_lgnd){
			prev_lgnd = aughld.augs[aug_slot].legend_installed;
			PlayerInfo plr = players[consoleplayer];
			sidepanel.label_aug_desc.text = aughld.augs[aug_slot].disp_desc;
			if(aughld.augs[aug_slot].legend_installed != -1)
				sidepanel.label_aug_desc.text = sidepanel.label_aug_desc.text .. "Installed legendary upgrade:\n" .. aughld.augs[aug_slot].legend_names[aughld.augs[aug_slot].legend_installed];
		}

	}

	override void processUIInput(UiEvent e)
	{
		if(e.type == UiEvent.Type_LButtonDown)
		{
			PlayerInfo plr = players[consoleplayer];
			DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));

			if(aughld.augs[aug_slot])
			{
				parent_wnd.selected_aug_slot = aug_slot;
				sidepanel.label_aug_name.text = aughld.augs[aug_slot].disp_name;
						sidepanel.aug_sel = aug_slot;
				sidepanel.label_aug_desc.text = aughld.augs[aug_slot].disp_desc;
				if(aughld.augs[aug_slot].legend_installed != -1)
					sidepanel.label_aug_desc.text = sidepanel.label_aug_desc.text .. "Installed legendary upgrade:\n" .. aughld.augs[aug_slot].legend_names[aughld.augs[aug_slot].legend_installed];
			}

			if(parent_wnd.selected_aug_slot == aug_slot){
				if(!lgnd_face_left){
					parent_wnd.lgnd_list.x = x + w + 3;
					parent_wnd.lgnd_list.y = y;
				} else{
					parent_wnd.lgnd_list.x = x - 3;
					parent_wnd.lgnd_list.y = y;
				}
				parent_wnd.lgnd_list.aug = aughld.augs[aug_slot];
				parent_wnd.lgnd_list.adjust(lgnd_face_left);
			}
		}
	}
}
