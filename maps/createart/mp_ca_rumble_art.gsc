// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_ca_rumble_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 562.278, 5000, 0.685692, 0.564965, 0.436857, 1, 0.60214, 0, 0, 0, 90 );
	VisionSetNaked( "mp_ca_rumble", 0 );
}
