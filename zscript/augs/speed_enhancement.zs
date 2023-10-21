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
			    "run and the height they can jump.\n\n"
			    "TECH ONE: Speed and jumping are increased slightly.\n\n"
			    "TECH TWO: Speed and jumping are increased\n"
			    "moderately.\n\n"
			    "TECH THREE: Speed and jumping are increased\n"
			    "significantly.\n\n"
			    "TECH FOUR: An agent can run like the wind and leap\n"
			    "meters high.\n\n"
			    "Energy Rate: 70 Units/Minute";

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
			if(DD_ModChecker.isLoaded_HDest() && DD_PatchChecker.isLoaded_HDest()){
				Class<Actor> cmlc_cls = ClassFinder.findActorClass("DD_HDCanMoveLegsCompensator");
				Actor cmlc = spawn(cmlc_cls);
				cmlc.target = owner;
				hdestmult = cmlc.getDeathHeight();
				cmlc.destroy();
			}
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
