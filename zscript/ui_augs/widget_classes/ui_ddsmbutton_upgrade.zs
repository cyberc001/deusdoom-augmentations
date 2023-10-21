	class UI_DDSmallButton_Upgrade : UI_DDSmallButton
{
	UI_Augs parent_wnd; // parent window

	override void processUIInput(UiEvent e)
	{
		if(e.type == UiEvent.Type_LButtonUp && pressed)
		{
			PlayerInfo plr = players[consoleplayer];
			
			EventHandler.sendNetworkEvent("dd_upgrade_aug", parent_wnd.selected_aug_slot);
		}
		super.processUIInput(e);
	}

	override void uiTick()
	{
		if(!self)
			return;

		PlayerInfo plr = players[consoleplayer];

		if(DD_AugmentationUpgradeCanister.canConsume(plr.mo,
				parent_wnd.selected_aug_slot)){
			disabled = false;
			text_color = 0xFFFFFFFF;
			text = "Upgrade";
		}
		else if(DD_AugmentationUpgradeCanisterLegendary.canConsume(plr.mo,
				parent_wnd.selected_aug_slot)){
			disabled = false;
			text_color = 0xFFFFFFFF;
			text = "Perfect";
		}
		else{
			disabled = true;
			text_color = 0x80808080;
		}
			
	}
}
