class DD_Aug_SpeedEnhancement : DD_Augmentation
{
	ui TextureID tex_off;
	ui TextureID tex_on;

	override TextureID get_ui_texture(bool state)
	{
		return state ? tex_on : tex_off;
	}

	override int get_base_drain_rate(){ return 70; }

	override void install()
	{
		super.install();

		id = 4;
		disp_name = "Speed Enhancement";
		disp_desc = "Ionic polymeric gel myofibrils are woven into the leg\n"
			    "muscles increasing the speed at which an agent can\n"
			    "run and the height they can jump.\n\n";
		_level = 1;
		enabled = true;
		disp_desc = disp_desc .. string.format("TECH ONE: Speed increase is %g%%.\nJump height increase is %g%%.\n\n", (getSpeedFactor() - 1) * 100, getJumpFactor() * 100);
		_level = 2;
		disp_desc = disp_desc .. string.format("TECH TWO: Speed increase is %g%%.\nJump height increase is %g%%.\n\n", (getSpeedFactor() - 1) * 100, getJumpFactor() * 100);
		_level = 3;
		disp_desc = disp_desc .. string.format("TECH THREE: Speed increase is %g%%.\nJump height increase is %g%%.\n\n", (getSpeedFactor() - 1) * 100, getJumpFactor() * 100);
		_level = 4;
		disp_desc = disp_desc .. string.format("TECH FOUR: Speed increase is %g%%.\nJump height increase is %g%%.\n\n", (getSpeedFactor() - 1) * 100, getJumpFactor() * 100);
		_level = 1;
		enabled = false;
		disp_desc = disp_desc .. string.format("Energy Rate: %d Units/Minute\n\n", get_base_drain_rate());

		slots_cnt = 1;
		slots[0] = Legs;
	}

	override void UIInit()
	{
		tex_off = TexMan.CheckForTexture("SPEED0");
		tex_on = TexMan.CheckForTexture("SPEED1");
	}


	// ------------------
	// Internal functions
	// ------------------

	override double getSpeedFactor()
	{
		if(enabled){
			double hdestmult = 1.0;
			return 1.20 + 0.20 * (getRealLevel() - 1) * hdestmult;
		}
		return 1.0;
	}
	protected double getJumpFactor() { return 0.20 + 0.3 * (getRealLevel() - 1);  }

	// -------------
	// Engine events
	// -------------

	double prevOwnerJumpZ;
	override void toggle()
	{
		super.toggle();
		if(!owner || !(owner is "PlayerPawn"))
			return;

		if(enabled){
			prevOwnerJumpZ = PlayerPawn(owner).jumpZ;
			PlayerPawn(owner).jumpZ *= 1.0 + getJumpFactor();
		}
		else{
			PlayerPawn(owner).jumpZ = prevOwnerJumpZ;
		}	
	}
}
