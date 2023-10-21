class UI_DDSmallButton_UseCell : UI_DDSmallButton
{
	UI_Augs_Sidepanel sidepanel;

	override void processUIInput(UiEvent e)
	{
		if(e.type == UiEvent.Type_LButtonUp && pressed)
			EventHandler.sendNetworkEvent("dd_use_cell");
		super.processUIInput(e);
	}

	override void uiTick()
	{
		PlayerInfo plr = players[consoleplayer];
		if(plr.mo)
		{
			if(DD_BioelectricCell.canConsume(plr.mo)){
				disabled = false;
				text_color = 0xFFFFFFFF;
			}
			else{
				disabled = true;
				text_color = 0x80808080;
			}
		}
	}
}
