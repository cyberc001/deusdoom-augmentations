class UI_DDBioelectricEnergyBar : UI_Widget
{
	// The worst hack I've ever done.
	// Also, the original game doesn't behave like this, colors "blend".
	// (RGB values change based on %)
	ui TextureID low_tex;  // 0  - 25  %
	ui TextureID med_tex;  // 25 - 50  %
	ui TextureID high_tex; // 50 - 75  %
	ui TextureID full_tex; // 75 - 100 %

	ui TextureID bg; // energy bar background
	
	ui int text_color; // color and...
	ui Font text_font; // font of display of % of energy

	override void UIInit()
	{
		low_tex = TexMan.checkForTexture("AUGUI12");
		med_tex = TexMan.checkForTexture("AUGUI13");
		high_tex = TexMan.checkForTexture("AUGUI14");
		full_tex = TexMan.checkForTexture("AUGUI15");

		bg = TexMan.CheckForTexture("AUGUI16");
	}

	override void drawOverlay(RenderEvent e)
	{
		UI_Draw.texture(bg, x, y, w, h);

		PlayerInfo plr = players[consoleplayer];
		int energy = plr.mo.CountInv("DD_BioelectricEnergy");
		double energy_perc = double(energy) / DD_BioelectricEnergy.max_energy;

		TextureID bar_tex =	energy_perc >= 0.75 ? full_tex :
					energy_perc >= 0.50 ? high_tex :
					energy_perc >= 0.25 ? med_tex  :
						       low_tex;		
		if(energy_perc > 0.0)
			UI_Draw.texture(bar_tex, x + 0.5, y + 0.5, w * energy_perc - 1, h - 1);

		string perc_text = String.Format("%d%%", int(round(energy_perc * 100)));
		double textx = x + w / 2 -
					UI_Draw.strWidth(text_font, perc_text, 0, h - 1) / 2;
		UI_Draw.str(text_font, perc_text, text_color, textx, y + 1, 0, h - 1);
	}
}
