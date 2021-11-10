// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_lonestar_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 512, 7760.62, 0.5, 0.5, 0.5, 0.75, 0.859375, 0, 0.328125, 0.328125, 0.328125, 1, (0, 0, 1), 64, 91, 0.5, 1, 54, 82 );
	VisionSetNaked( "mp_lonestar", 0 );
}
