class UI_DDInstalledAugLevelDisplay : UI_Widget
{
	ui int aug_slot; // slot to display

	// Texture dimensions, as used in UI_Draw::texture()
	// They apply to each separate level checklet
	ui double tex_w;
	ui double tex_h;

	// Textures
	ui TextureID checklet;
	ui TextureID checklet_lgnd;

	override void UIinit()
	{
		checklet = TexMan.CheckForTexture("AUGUI11");
		checklet_lgnd = TexMan.CheckForTexture("AUGUI40");
	}

	override void drawOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));
		DD_Augmentation au = aughld.augs[aug_slot];

		double sx = x;
		double sy = y;
		double chk_gap = 0.44;
		if(au)
		{
			TextureID ch;
			if(au.legendary) ch = checklet_lgnd;
			else		 ch = checklet;

			for(uint lvl = 1; lvl <= au._level; ++lvl)
			{
				UI_Draw.texture(ch, sx, sy, tex_w, tex_h);
				sx += UI_Draw.texWidth(ch, tex_w, tex_h) + chk_gap;
			}
		}
	}
}
