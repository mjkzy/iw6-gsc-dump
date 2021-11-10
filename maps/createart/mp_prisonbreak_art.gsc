// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_prisonbreak_fog::main;
	//* Fog section * 
	setDevDvar( "scr_fog_disable", "0" );
	//setExpFog( 1400, 40500, 0.92, 0.99, 1.0, 0.22, 1, 0.64, 0.50, 0.50, (0.98, 0.09, 0.1), 0, 80.0, 5.0 );
	VisionSetNaked( "mp_prisonbreak", 0 );

}
