// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{

	level.tweakfile = true;
 	level.parse_fog_func = maps\createart\mp_sovereign_fog::main;

	//* Fog section * 

	setDevDvar( "scr_fog_disable", "0" );

	//setExpFog( 650, 2049, 0.352941, 0.411765, 0.478431, 1, 0.5, 0, 1, 0.854902, 0.74902, 1, (0.00390755, 0.00323934, -1), 61, 93.7872, 0.25 );
	VisionSetNaked( "mp_sovereign", 0 );

}
