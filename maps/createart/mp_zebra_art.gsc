// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_zebra_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 371.287, 7055.43, 0.395946, 0.358963, 0.352442, 0.742574, 0.919554, 0, 0, 0, 0 );
	VisionSetNaked( "mp_zebra", 0 );
}
