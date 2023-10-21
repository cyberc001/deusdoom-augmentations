class UI_DDSmallButton_Install : UI_DDSmallButton
{
	UI_Augs_Sidepanel sidepanel;

	override void processUIInput(UiEvent e)
	{
		if(e.type == UiEvent.Type_LButtonUp && pressed)
		{
			PlayerInfo plr = players[consoleplayer];
			DD_AugsHolder aughld = DD_AugsHolder(plr.mo.findInventory("DD_AugsHolder"));

			if(sidepanel.aug_install_sel_slot == -1 || sidepanel.aug_install_sel == -1)
				return;

			EventHandler.sendNetworkEvent("dd_install_aug", sidepanel.aug_install_sel_slot, sidepanel.aug_install_sel);

			sidepanel.aug_install_sel_slot = 0;
			sidepanel.aug_install_sel = 0;
		}
		super.processUIInput(e);
	}

	override void uiTick()
	{
		if(sidepanel.aug_install_sel_slot == -1
		|| sidepanel.aug_install_sel == -1)
		{
			disabled = true;
			text_color = 0x80808080;
			return;
		}

		PlayerInfo plr = players[consoleplayer];
		if(!plr.mo)
			return;
		DD_AugsHolder aughld = DD_AugsHolder(plr.mo.FindInventory("DD_AugsHolder"));
		if(sidepanel.aug_install_sel == 1){
			if(!aughld.canInstallAug(aughld.inv_augs[sidepanel.aug_install_sel_slot])){
				disabled = true;
				text_color = 0x80808080;
				return;
			}
		}
		else if(sidepanel.aug_install_sel == 2){
			if(!aughld.canInstallAug(aughld.inv_augs2[sidepanel.aug_install_sel_slot])){
				disabled = true;
				text_color = 0x80808080;
				return;
			}
		}

		disabled = false;
		text_color = 0xFFFFFFFF;
	}
}
