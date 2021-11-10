// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_hashima_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 1536, 10241, 0, 0.705811, 0.921875, 1, 0.5, 0, 0.757813, 0.607019, 0.363672, 1, (0.097, -0.031, -0.375), 55, 180, 2.5, 1, 60, 80 );
	VisionSetNaked( "mp_hashima", 0 );
}
