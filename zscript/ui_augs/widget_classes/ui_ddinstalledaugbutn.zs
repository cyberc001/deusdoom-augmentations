class UI_DDInstalledAugButton : UI_Widget
{
	ui int aug_slot; // slot to display

	UI_Augs parent_wnd; // parent window
	UI_Augs_Sidepanel sidepanel; // sidepanel window to change information in

	// Texture dimensions, as used in UI_Draw::texture()
	ui double tex_w;
	ui double tex_h;

	override void drawOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));

		if(aughld.augs[aug_slot])
		{
			UI_Draw.texture(aughld.augs[aug_slot].get_ui_texture(aughld.augs[aug_slot].enabled),
						x, y, tex_w, tex_h);
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
				sidepanel.label_aug_desc.text = aughld.augs[aug_slot].disp_desc;

				sidepanel.aug_sel = aug_slot;
			}
		}
	}
}
