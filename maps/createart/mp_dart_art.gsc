// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_dart_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 200, 3500, 0.54, 0.54, 0.54, 1, 0.75, 0, 0.92, 0.69, 0.44, 1, (-0.27, -0.86, 0.4), 15, 60, 2.25, 1, 61, 85 );
	VisionSetNaked( "mp_dart", 0 );
}
