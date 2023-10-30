class UI_DDLegendaryList : UI_Widget
{
	DD_Augmentation aug;

	UI_Augs parent_wnd;

	ui Font text_font;
	ui Font sel_text_font;
	ui TextureID bg;

	ui int sel;
	ui bool face_left;

	override void UIInit()
	{
		bg = TexMan.checkForTexture("AUGUI16");
		sel = -1;
	}

	void adjust(bool face_left)
	{
		self.face_left = face_left;

		sel = -1;
		w = 0; h = aug.legend_count * 6 + 1;
		for(int i = 0; i < aug.legend_count; ++i){
			double str_w = UI_Draw.strWidth(text_font, aug.legend_names[i], 0, 4);
			if(str_w > w)
				w = str_w;
		}
		if(face_left)
			x -= w;
	}

	override void drawOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		if(!aug || aug.legend_count <= 0 || aug._level < aug.max_level || aug.legend_installed != -1 || !DD_AugmentationUpgradeCanisterLegendary.canConsume(plr.mo, parent_wnd.selected_aug_slot))
			return;

		for(int i = 0; i < aug.legend_count; ++i){
			double str_w = UI_Draw.strWidth(i == sel ? sel_text_font : text_font, aug.legend_names[i], 0, 4);
			double str_h = 4;
			UI_Draw.texture(bg, x + (face_left ? w - str_w : 0), y + i * 6, str_w + 1, str_h + 1);
			UI_Draw.str(i == sel ? sel_text_font : text_font, aug.legend_names[i], 0xFFFFFFFF, x + (face_left ? w - str_w + 1 : 1), y + i * 6 + 1, 0, 4);
		}
	}

	override void processUIInput(UiEvent e)
	{
		if(!aug)
			return;
		if(e.type == UiEvent.Type_LButtonDown){
			int mousex = e.MouseX * 320 / Screen.getWidth();
			int mousey = e.MouseY * 200 / Screen.getHeight();
			for(int i = 0; i < aug.legend_count; ++i){
				double str_w = UI_Draw.strWidth(text_font, aug.legend_names[i], 0, 4);
				if(mousex <= x + (face_left ? w + 1 : str_w + 1)
				&& mousey >= y + i * 6 && mousey <= y + (i + 1) * 6){
					sel = i;
					break;
				}}
		}
	}
}
