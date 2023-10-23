class UI_Augs : UI_Window
{
	// Fonts
	ui Font aug_font;
	ui Font aug_font_bold;

	// Textures
	ui TextureID bg1; // Background for augmentations
	ui TextureID frame1; // Frame for augmentations

	ui TextureID body; // Body image
		// Body parts images:
		ui TextureID body_arms;
		ui TextureID body_cranial;
		ui TextureID body_eyes;
		ui TextureID body_legs;
		ui TextureID body_subdermal;
		ui TextureID body_torso;

	ui TextureID overlay; // Body parts overlay

	// Widgets
	UI_DDInstalledAugButton iaugbutn_arms;
	UI_DDInstalledAugButton iaugbutn_subdermal1;
	UI_DDInstalledAugButton iaugbutn_subdermal2;
	UI_DDInstalledAugButton iaugbutn_legs;
	UI_DDInstalledAugButton iaugbutn_torso1;
	UI_DDInstalledAugButton iaugbutn_torso2;
	UI_DDInstalledAugButton iaugbutn_torso3;
	UI_DDInstalledAugButton iaugbutn_cranial;
	UI_DDInstalledAugButton iaugbutn_eyes;

	UI_DDInstalledAugLevelDisplay iauglvldisp_arms;
	UI_DDInstalledAugLevelDisplay iauglvldisp_subdermal1;
	UI_DDInstalledAugLevelDisplay iauglvldisp_subdermal2;
	UI_DDInstalledAugLevelDisplay iauglvldisp_legs;
	UI_DDInstalledAugLevelDisplay iauglvldisp_torso1;
	UI_DDInstalledAugLevelDisplay iauglvldisp_torso2;
	UI_DDInstalledAugLevelDisplay iauglvldisp_torso3;
	UI_DDInstalledAugLevelDisplay iauglvldisp_cranial;
	UI_DDInstalledAugLevelDisplay iauglvldisp_eyes;

	UI_DDSmallButton_ToggleAug butn_toggle_aug;
	UI_DDSmallButton_Upgrade butn_upgrade;

	// Misc
	UI_Augs_Sidepanel sidepanel; // for augmentation buttons widget, set externally
	ui int selected_aug_slot;

	override String getName() { return "Augmentations"; }
	override String getToggEvent() { return "dd_toggle_ui_augs"; }

	override void UIInit()
	{
		widgets.clear();
		if(!sidepanel){
			sidepanel = new("UI_Augs_Sidepanel");
			sidepanel.UIInit();
			
		}

		self.x = 10; self.y = 15;

		iaugbutn_arms = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_arms.parent_wnd = self;
		iaugbutn_arms.sidepanel = sidepanel;
		addWidget(iaugbutn_arms);
		iaugbutn_subdermal1 = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_subdermal1.parent_wnd = self;
		iaugbutn_subdermal1.sidepanel = sidepanel;
		addWidget(iaugbutn_subdermal1);
		iaugbutn_subdermal2 = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_subdermal2.parent_wnd = self;
		iaugbutn_subdermal2.sidepanel = sidepanel;
		addWidget(iaugbutn_subdermal2);
		iaugbutn_legs = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_legs.parent_wnd = self;
		iaugbutn_legs.sidepanel = sidepanel;
		addWidget(iaugbutn_legs);
		iaugbutn_torso1 = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_torso1.parent_wnd = self;
		iaugbutn_torso1.sidepanel = sidepanel;
		addWidget(iaugbutn_torso1);
		iaugbutn_torso2 = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_torso2.parent_wnd = self;
		iaugbutn_torso2.sidepanel = sidepanel;
		addWidget(iaugbutn_torso2);
		iaugbutn_torso3 = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_torso3.parent_wnd = self;
		iaugbutn_torso3.sidepanel = sidepanel;
		addWidget(iaugbutn_torso3);
		iaugbutn_cranial = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_cranial.parent_wnd = self;
		iaugbutn_cranial.sidepanel = sidepanel;
		addWidget(iaugbutn_cranial);
		iaugbutn_eyes = UI_DDInstalledAugButton(New("UI_DDInstalledAugButton"));
		iaugbutn_eyes.parent_wnd = self;
		iaugbutn_eyes.sidepanel = sidepanel;
		addWidget(iaugbutn_eyes);

		iauglvldisp_arms = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_arms);
		iauglvldisp_subdermal1 = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_subdermal1);
		iauglvldisp_subdermal2 = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_subdermal2);
		iauglvldisp_legs = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_legs);
		iauglvldisp_torso1 = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_torso1);
		iauglvldisp_torso2 = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_torso2);
		iauglvldisp_torso3 = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_torso3);
		iauglvldisp_cranial = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_cranial);
		iauglvldisp_eyes = UI_DDInstalledAugLevelDisplay(New("UI_DDInstalledAugLevelDisplay"));
		addWidget(iauglvldisp_eyes);

		butn_toggle_aug = UI_DDSmallButton_ToggleAug(New("UI_DDSmallButton_ToggleAug"));
		butn_toggle_aug.sidepanel = sidepanel;
		addWidget(butn_toggle_aug);

		butn_upgrade = UI_DDSmallButton_Upgrade(New("UI_DDSmallButton_Upgrade"));
		butn_upgrade.parent_wnd = self;
		addWidget(butn_upgrade);

		w = 135;
		h = 180;

		selected_aug_slot = -1;

		// Fonts
		aug_font = Font.GetFont("DD_UI");
		aug_font_bold = Font.GetFont("DD_UIBold");

		// Textures
		bg1 = TexMan.CheckForTexture("AUGUI01");
		frame1 = TexMan.CheckForTexture("AUGUI20");

		body = TexMan.CheckForTexture("AUGUI03");
			body_arms = TexMan.CheckForTexture("AUGUI04");
			body_cranial = TexMan.CheckForTexture("AUGUI05");
			body_eyes = TexMan.CheckForTexture("AUGUI06");
			body_legs = TexMan.CheckForTexture("AUGUI07");
			body_subdermal = TexMan.CheckForTexture("AUGUI08");
			body_torso = TexMan.CheckForTexture("AUGUI09");

		overlay = TexMan.CheckForTexture("AUGUI10");

		// Widgets
		iaugbutn_arms.aug_slot = Arms;
		iaugbutn_arms.x = x + 8.5;
		iaugbutn_arms.y = y + 49;
		iaugbutn_arms.w = 20;
		iaugbutn_arms.h = 20;
		iaugbutn_arms.tex_w = -0.4;
		iaugbutn_arms.tex_h = -0.4;

		iaugbutn_subdermal1.aug_slot = Subdermal1;
		iaugbutn_subdermal1.x = x + 8.5;
		iaugbutn_subdermal1.y = y + 84;
		iaugbutn_subdermal1.w = 20;
		iaugbutn_subdermal1.h = 20;
		iaugbutn_subdermal1.tex_w = -0.4;
		iaugbutn_subdermal1.tex_h = -0.4;

		iaugbutn_subdermal2.aug_slot = Subdermal2;
		iaugbutn_subdermal2.x = x + 8.5;
		iaugbutn_subdermal2.y = y + 109;
		iaugbutn_subdermal2.w = 20;
		iaugbutn_subdermal2.h = 20;
		iaugbutn_subdermal2.tex_w = -0.4;
		iaugbutn_subdermal2.tex_h = -0.4;

		iaugbutn_legs.aug_slot = Legs;
		iaugbutn_legs.x = x + 104.7;
		iaugbutn_legs.y = y + 137;
		iaugbutn_legs.w = 20;
		iaugbutn_legs.h = 20;
		iaugbutn_legs.tex_w = -0.4;
		iaugbutn_legs.tex_h = -0.4;

		iaugbutn_torso1.aug_slot = Torso1;
		iaugbutn_torso1.x = x + 104.7;
		iaugbutn_torso1.y = y + 51;
		iaugbutn_torso1.w = 20;
		iaugbutn_torso1.h = 20;
		iaugbutn_torso1.tex_w = -0.4;
		iaugbutn_torso1.tex_h = -0.4;

		iaugbutn_torso2.aug_slot = Torso2;
		iaugbutn_torso2.x = x + 104.7;
		iaugbutn_torso2.y = y + 76.5;
		iaugbutn_torso2.w = 20;
		iaugbutn_torso2.h = 20;
		iaugbutn_torso2.tex_w = -0.4;
		iaugbutn_torso2.tex_h = -0.4;

		iaugbutn_torso3.aug_slot = Torso3;
		iaugbutn_torso3.x = x + 104.7;
		iaugbutn_torso3.y = y + 101.5;
		iaugbutn_torso3.w = 20;
		iaugbutn_torso3.h = 20;
		iaugbutn_torso3.tex_w = -0.4;
		iaugbutn_torso3.tex_h = -0.4;

		iaugbutn_cranial.aug_slot = Cranial;
		iaugbutn_cranial.x = x + 24.5;
		iaugbutn_cranial.y = y + 17;
		iaugbutn_cranial.w = 20;
		iaugbutn_cranial.h = 20;
		iaugbutn_cranial.tex_w = -0.4;
		iaugbutn_cranial.tex_h = -0.4;

		iaugbutn_eyes.aug_slot = Eyes;
		iaugbutn_eyes.x = x + 90;
		iaugbutn_eyes.y = y + 17;
		iaugbutn_eyes.w = 20;
		iaugbutn_eyes.h = 20;
		iaugbutn_eyes.tex_w = -0.4;
		iaugbutn_eyes.tex_h = -0.4;


		iauglvldisp_arms.aug_slot = Arms;
		iauglvldisp_arms.x = x + 20.2;
		iauglvldisp_arms.y = y + 70.8;
		iauglvldisp_arms.tex_w = -0.42;
		iauglvldisp_arms.tex_h = -0.42;

		iauglvldisp_subdermal1.aug_slot = Subdermal1;
		iauglvldisp_subdermal1.x = x + 20.2;
		iauglvldisp_subdermal1.y = y + 106.3;
		iauglvldisp_subdermal1.tex_w = -0.42;
		iauglvldisp_subdermal1.tex_h = -0.42;

		iauglvldisp_subdermal2.aug_slot = Subdermal2;
		iauglvldisp_subdermal2.x = x + 20.2;
		iauglvldisp_subdermal2.y = y + 131;
		iauglvldisp_subdermal2.tex_w = -0.42;
		iauglvldisp_subdermal2.tex_h = -0.42;

		iauglvldisp_legs.aug_slot = Legs;
		iauglvldisp_legs.x = x + 116.5;
		iauglvldisp_legs.y = y + 158.4;
		iauglvldisp_legs.tex_w = -0.42;
		iauglvldisp_legs.tex_h = -0.42;

		iauglvldisp_torso1.aug_slot = Torso1;
		iauglvldisp_torso1.x = x + 116.4;
		iauglvldisp_torso1.y = y + 73.3;
		iauglvldisp_torso1.tex_w = -0.42;
		iauglvldisp_torso1.tex_h = -0.42;

		iauglvldisp_torso2.aug_slot = Torso2;
		iauglvldisp_torso2.x = x + 116.4;
		iauglvldisp_torso2.y = y + 98;
		iauglvldisp_torso2.tex_w = -0.42;
		iauglvldisp_torso2.tex_h = -0.42;

		iauglvldisp_torso3.aug_slot = Torso3;
		iauglvldisp_torso3.x = x + 116.4;
		iauglvldisp_torso3.y = y + 123;
		iauglvldisp_torso3.tex_w = -0.42;
		iauglvldisp_torso3.tex_h = -0.42;

		iauglvldisp_cranial.aug_slot = Cranial;
		iauglvldisp_cranial.x = x + 36.3;
		iauglvldisp_cranial.y = y + 38.7;
		iauglvldisp_cranial.tex_w = -0.42;
		iauglvldisp_cranial.tex_h = -0.42;

		iauglvldisp_eyes.aug_slot = Eyes;
		iauglvldisp_eyes.x = x + 101.5;
		iauglvldisp_eyes.y = y + 38.7;
		iauglvldisp_eyes.tex_w = -0.42;
		iauglvldisp_eyes.tex_h = -0.42;


		butn_toggle_aug.x = x + 7;
		butn_toggle_aug.y = y + 172.5;
		butn_toggle_aug.w = 31;
		butn_toggle_aug.h = 6;
		butn_toggle_aug.text = "Toggle on/off";
		butn_toggle_aug.text_color = 0xFFFFFF;
		butn_toggle_aug.text_font = aug_font;

		butn_upgrade.x = x + 39;
		butn_upgrade.y = y + 172.5;
		butn_upgrade.w = 21;
		butn_upgrade.h = 6;
		butn_upgrade.text = "Upgrade";
		butn_upgrade.text_color = 0xFFFFFF;
		butn_upgrade.text_font = aug_font;
	}
	override void open()
	{
		let ddevh = DD_EventHandler(StaticEventHandler.Find("DD_EventHandler"));
		ddevh.wndmgr.addWindow(ddevh, sidepanel);
	}
	override void close()
	{
		let ddevh = DD_EventHandler(StaticEventHandler.Find("DD_EventHandler"));
		ddevh.wndmgr.closeWindow(ddevh, sidepanel);
	}

	override void drawOverlay(RenderEvent e)
	{
		PlayerInfo plr = players[consoleplayer];
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));

		UI_Draw.texture(bg1, x, y, 0, 180);
		UI_Draw.texture(body, x + 33, y + 19, 0, 142);

		UI_Draw.str(aug_font_bold, "Augmentations", 0xFFFFFFFF, x + 4.6, y + 1.8, -0.4, -0.4);

		UI_Draw.str(aug_font, "Cranial", 0xFFFFFFFF, x + 25, y + 12, -0.45, -0.45);
			UI_Draw.texture(body_cranial, x + 60.3, y + 19, 0, 9);
		UI_Draw.str(aug_font, "Eyes", 0xFFFFFFFF, x + 90.5, y + 12, -0.45, -0.45);
			UI_Draw.texture(body_eyes, x + 67.5, y + 26.5, 0, 5);
		UI_Draw.str(aug_font, "Arms", 0xFFFFFFFF, x + 9, y + 44, -0.45, -0.45);
			UI_Draw.texture(body_arms, x + 44, y + 46, 0, 19);
		UI_Draw.str(aug_font, "Torso", 0xFFFFFFFF, x + 104.5, y + 46.6, -0.45, -0.45);
			UI_Draw.texture(body_torso, x + 66, y + 45.5, 0, 20);
		UI_Draw.str(aug_font, "Subdermal", 0xFFFFFFFF, x + 9, y + 79.5, -0.45, -0.45);
			UI_Draw.texture(body_subdermal, x + 35.5, y + 67, 0, 15.5);
		UI_Draw.str(aug_font, "Legs", 0xFFFFFFFF, x + 104.5, y + 131.5, -0.45, -0.45);
			UI_Draw.texture(body_legs, x + 69, y + 93, 0, 40);
		UI_Draw.str(aug_font, "Unclassified", 0xFFFFFFFF, x + 8.5, y + 139.5, -0.45, -0.45);

		UI_Draw.texture(overlay, x + 30.5, y + 11.5, 0, 128.5);
		UI_Draw.texture(frame1, x - 10, y - 2, 0, 184.5);

		super.drawOverlay(e);
	}


	override bool demandsUIProcessor() { return true; }

	override bool processUIInput(UiEvent e)
	{
		super.processUIInput(e);

		if(e.type == UiEvent.Type_KeyDown)
		{
			if(KeyBindUtils.checkBind(KeyBindUtils.keyCharToScan(e.KeyChar), "dd_togg_ui_augs")
			|| e.KeyChar == UiEvent.Key_Escape)
			{
				container.closeWindow(ev_handler, sidepanel);
				container.closeWindow(ev_handler, self);
			}
		}	

		return false;
	}
}
