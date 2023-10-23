class UI_Augs_Sidepanel : UI_Window
{
	// Fonts
	ui Font aug_font;
	ui Font aug_font_bold;

	// Textures
	ui TextureID bg1;	// Background for sidepanel (augmentations info, actions)
	ui TextureID frame1; // Frame for sidepanel

	// Widgets
	UI_DDLabel label_aug_name;
	UI_DDMultiLineLabel label_aug_desc;
	UI_DDScrollBar aug_scrollbar;

	UI_DDSmallButton_UseCell butn_usecell;
	UI_DDSmallButton_Install butn_install;

	UI_DDCanisterAugButton augbutns[3];

	UI_DDBioelectricEnergyBar bioelenergy_bar;

	UI_DDItemFrame itframe_cells;
	UI_DDItemFrame itframe_canupgrades;
	UI_DDItemFrame itframe_canupgrades_lgnd;

	// Misc
	ui int aug_sel;			// Currently selected augmentation, changed by UI_Augs widgets
	ui int aug_install_sel_slot;	// Currently selected augmentation installation widget (index in canister installation buttons)
	ui int aug_install_sel;		// Currently selected augmentation to install (1 or 2)

	override void UIinit()
	{
		widgets.clear();

		self.x = 150; self.y = 16;
		w = 140; h = 195;

		// Fonts
		aug_font = Font.GetFont("DD_UI");
		aug_font_bold = Font.GetFont("DD_UIBold");

		label_aug_name = UI_DDLabel(New("UI_DDLabel"));
		addWidget(label_aug_name);
		label_aug_desc = UI_DDMultiLineLabel(New("UI_DDMultiLineLabel"));
		addWidget(label_aug_desc);
		aug_scrollbar = UI_DDScrollBar(New("UI_DDScrollBar"));
		aug_scrollbar.mlabel = label_aug_desc;
		addWidget(aug_scrollbar);

		butn_usecell = UI_DDSmallButton_UseCell(New("UI_DDSmallButton_UseCell"));
		butn_usecell.sidepanel = self;
		addWidget(butn_usecell);
		butn_install = UI_DDSmallButton_Install(New("UI_DDSmallButton_Install"));
		butn_install.sidepanel = self;
		addWidget(butn_install);

		for(uint i = 0; i < 3; ++i)
		{
			augbutns[i] = UI_DDCanisterAugButton(New("UI_DDCanisterAugButton"));
			augbutns[i].sidepanel = self;
			addWidget(augbutns[i]);
		}

		bioelenergy_bar = UI_DDBioelectricEnergyBar(New("UI_DDBioelectricEnergyBar"));
		addWidget(bioelenergy_bar);

		itframe_cells = UI_DDItemFrame(New("UI_DDItemFrame"));
		addWidget(itframe_cells);
		itframe_canupgrades = UI_DDItemFrame(New("UI_DDItemFrame"));
		addWidget(itframe_canupgrades);
		itframe_canupgrades_lgnd = UI_DDItemFrame(New("UI_DDItemFrame"));
		addWidget(itframe_canupgrades_lgnd);

		aug_sel = -1;
		aug_install_sel_slot = -1;
		aug_install_sel = -1;

		// Textures
		bg1 = TexMan.CheckForTexture("AUGUI02");
		frame1 = TexMan.CheckForTexture("AUGUI41");

		// Widgets
		label_aug_name.text = " ";
		label_aug_name.text_font = aug_font_bold;
		label_aug_name.text_color = 0xFFFFFFFF;
		label_aug_name.x = x + 5;
		label_aug_name.y = y + 5;
		label_aug_name.text_w = -0.4;
		label_aug_name.text_h = -0.4;

		label_aug_desc.text = " ";
		label_aug_desc.text_font = aug_font;
		label_aug_desc.text_color = 0xFFFFFFFF;
		label_aug_desc.x = x + 5;
		label_aug_desc.y = y + 14;
		label_aug_desc.h = 95;
		label_aug_desc.text_w = -0.45;
		label_aug_desc.text_h = -0.45;
		label_aug_desc.line_gap = 1;

		aug_scrollbar.x = x + 109.5;
		aug_scrollbar.y = y + 13;
		aug_scrollbar.w = 6;
		aug_scrollbar.h = 98;

		butn_usecell.x = x + 22;
		butn_usecell.y = y + 171;
		butn_usecell.w = 21;
		butn_usecell.h = 6;
		butn_usecell.disabled = true;
		butn_usecell.text = "Use cell";
		butn_usecell.text_color = 0x80808080;
		butn_usecell.text_font = aug_font;

		butn_install.x = x + 4;
		butn_install.y = y + 171;
		butn_install.w = 17;
		butn_install.h = 6;
		butn_install.disabled = true;
		butn_install.text = "Install";
		butn_install.text_color = 0x80808080;
		butn_install.text_font = aug_font;

		double butnsy = y + 114;
		for(uint i = 0; i < 3; ++i)
		{
			augbutns[i].x = x + 3.5;
			augbutns[i].y = butnsy;
			augbutns[i].w = 112;
			augbutns[i].h = 14;
			augbutns[i].tex_w = -0.28;
			augbutns[i].tex_h = -0.28;
			augbutns[i].install_slot = i;
			augbutns[i].text_font = aug_font;
			butnsy += 15;
		}

		bioelenergy_bar.x = x + 46;
		bioelenergy_bar.y = y + 171;
		bioelenergy_bar.w = 69;
		bioelenergy_bar.h = 6;
		bioelenergy_bar.text_color = 0xFFFFFFFF;
		bioelenergy_bar.text_font = aug_font;

		itframe_cells.x = x + 122;
		itframe_cells.y = y + 85;
		itframe_cells.tex_w = -0.6;
		itframe_cells.tex_h = -0.6;
		itframe_cells.frame_w = -0.5;
		itframe_cells.frame_h = -0.5;
		itframe_cells.str_w = -0.5;
		itframe_cells.str_h = -0.5;
		itframe_cells.item_cls = "DD_BioelectricCell";
		itframe_cells.disp_font = aug_font;
		itframe_cells.disp_name1 = "Bioelectric";
		itframe_cells.disp_name2 = "cell";
		itframe_cells.item_tex = TexMan.checkForTexture("BCELA0", TexMan.Type_Any);

		itframe_canupgrades.x = x + 122;
		itframe_canupgrades.y = y + 115;
		itframe_canupgrades.tex_w = -0.6;
		itframe_canupgrades.tex_h = -0.6;
		itframe_canupgrades.frame_w = -0.5;
		itframe_canupgrades.frame_h = -0.5;
		itframe_canupgrades.str_w = -0.5;
		itframe_canupgrades.str_h = -0.5;
		itframe_canupgrades.item_cls = "DD_AugmentationUpgradeCanister";
		itframe_canupgrades.disp_font = aug_font;
		itframe_canupgrades.disp_name1 = "Upgrade";
		itframe_canupgrades.disp_name2 = "canister";
		itframe_canupgrades.item_tex = TexMan.checkForTexture("AUCNA0", TexMan.Type_Any);

		itframe_canupgrades_lgnd.x = x + 122;
		itframe_canupgrades_lgnd.y = y + 145;
		itframe_canupgrades_lgnd.tex_w = -0.6;
		itframe_canupgrades_lgnd.tex_h = -0.6;
		itframe_canupgrades_lgnd.frame_w = -0.5;
		itframe_canupgrades_lgnd.frame_h = -0.5;
		itframe_canupgrades_lgnd.str_w = -0.5;
		itframe_canupgrades_lgnd.str_h = -0.5;
		itframe_canupgrades_lgnd.item_cls = "DD_AugmentationUpgradeCanisterLegendary";
		itframe_canupgrades_lgnd.disp_font = aug_font;
		itframe_canupgrades_lgnd.disp_name1 = "Legendary";
		itframe_canupgrades_lgnd.disp_name2 = "upgrade can.";
		itframe_canupgrades_lgnd.item_tex = TexMan.checkForTexture("AULCA0", TexMan.Type_Any);
	}

	override void drawOverlay(RenderEvent e)
	{
		UI_Draw.texture(bg1, x, y, 0, 180);
		UI_Draw.texture(frame1, x - 3, y - 4.5, 130, 200);

		super.drawOverlay(e);
	}


	override bool processUIInput(UiEvent e)
	{
		super.processUIInput(e);
		return false;
	}
}
