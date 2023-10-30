class UI_DDCanisterAugButton : UI_Widget
{
	UI_Augs_Sidepanel sidepanel;

	ui int install_slot; // install slot to display (index in aug holder)

	ui Font text_font;

	ui TextureID bg;
	ui TextureID augcan_tex;
	ui TextureID selection_tex;
	ui TextureID drop_tex;

	// Augmentation icons dimensions
	ui double tex_w;
	ui double tex_h;

	override void UIInit()
	{
		bg = TexMan.CheckForTexture("AUGUI17");
		augcan_tex = TexMan.CheckForTexture("AUGUI18");
		selection_tex = TexMan.CheckForTexture("AUGUI19");
		drop_tex = TexMan.CheckForTexture("AUGUI24");
	}

	override void drawOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));

		if(install_slot >= aughld.inv_augs.size() || !aughld.inv_augs[install_slot]
		|| install_slot >= aughld.inv_augs2.size() || !aughld.inv_augs2[install_slot])
			return;
		

		UI_Draw.texture(bg, x, y, w, h);
		UI_Draw.texture(augcan_tex, x + 1.5, y + 0.5, 0, h - 1);
		UI_Draw.str(text_font, "Contents:", 0xFFFFFFFF, x + 8, y + 1, 0, h / 4);

		if(install_slot < aughld.inv_augs.size() && aughld.inv_augs[install_slot])
		{
			bool caninstall = aughld.canInstallAug(aughld.inv_augs[install_slot]);

			UI_Draw.texture(aughld.inv_augs[install_slot].get_ui_texture(caninstall),
					x + 77.5, y, tex_w, tex_h);
			UI_Draw.str(text_font, aughld.inv_augs[install_slot].disp_name, 0xFFFFFFFF,
					x + 10, y + h / 4 + 2, 0, h / 4);

			if(sidepanel.aug_install_sel_slot == install_slot
			&& sidepanel.aug_install_sel == 1){
				UI_Draw.texture(selection_tex, x + 77.5, y - 0.2, 14, 14.5);
			}
		}
		if(install_slot < aughld.inv_augs2.size() && aughld.inv_augs2[install_slot])
		{
			if(!aughld.inv_augs2[install_slot].ui_init)
				aughld.inv_augs2[install_slot].UIInit();

			bool caninstall = aughld.canInstallAug(aughld.inv_augs2[install_slot]);

			UI_Draw.texture(aughld.inv_augs2[install_slot].get_ui_texture(caninstall),
					x + 92, y, tex_w, tex_h);
			UI_Draw.str(text_font, aughld.inv_augs2[install_slot].disp_name, 0xFFFFFFFF,
					x + 10, y + h / 4 * 2 + 3, 0, h / 4);

			if(sidepanel.aug_install_sel_slot == install_slot
			&& sidepanel.aug_install_sel == 2){
				UI_Draw.texture(selection_tex, x + 92, y - 0.2, 14, 14.5);
			}
		}

		UI_Draw.texture(drop_tex, x + 106.5, y + 2,
				5, 10);
	}


	override void processUIInput(UiEvent e)
	{
		if(e.type == UiEvent.Type_LButtonDown)
		{
			PlayerInfo plr = players[consoleplayer];
			DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));
			int mousex = e.MouseX * 320 / Screen.getWidth();

			if(mousex >= x + 77.5 && mousex <= x + 92
				&& install_slot < aughld.inv_augs.size()
				&& aughld.inv_augs[install_slot])
			{
				if(sidepanel.aug_install_sel_slot != install_slot
				|| sidepanel.aug_install_sel != 1){
					SoundUtils.uiStartSound("ui/menu/focus", plr.mo);
				}
				sidepanel.aug_install_sel_slot = install_slot;
				sidepanel.aug_install_sel = 1;

				sidepanel.label_aug_name.text = aughld.inv_augs[install_slot].disp_name;
				sidepanel.label_aug_desc.text = aughld.inv_augs[install_slot].disp_desc;
			}
			else if(mousex >= x + 92 && mousex <= x + 107.5
				&& install_slot < aughld.inv_augs2.size()
				&& aughld.inv_augs2[install_slot])
			{
				if(sidepanel.aug_install_sel_slot != install_slot
				|| sidepanel.aug_install_sel != 2){
					SoundUtils.uiStartSound("ui/menu/focus", plr.mo);
				}
				sidepanel.aug_install_sel_slot = install_slot;
				sidepanel.aug_install_sel = 2;
				sidepanel.label_aug_name.text = aughld.inv_augs2[install_slot].disp_name;
				sidepanel.label_aug_desc.text = aughld.inv_augs2[install_slot].disp_desc;
			}
			else if(mousex > x + 107.5)
			{
				SoundUtils.uiStartSound("ui/menu/press", plr.mo);
				sidepanel.aug_install_sel_slot = -1;
				sidepanel.aug_install_sel = -1;
				sidepanel.label_aug_name.text = " ";
				sidepanel.label_aug_desc.text = " ";
				if(install_slot < aughld.inv_augs.size())
					EventHandler.sendNetworkEvent("dd_drop_aug", install_slot);
			}
			else{
				sidepanel.aug_install_sel_slot = -1;
				sidepanel.aug_install_sel = -1;
				sidepanel.label_aug_name.text = " ";
				sidepanel.label_aug_desc.text = " ";
			}
		}
	}
}
