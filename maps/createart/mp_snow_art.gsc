// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_snow_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 714.363, 7073.18, 0.345189, 0.457268, 0.453545, 1, 0.55, 0, 0.608505, 0.999996, 0.828083, 1, (0.12, -0.03, 0.99), 0, 55, 0.38, 1, 67.2161, 92.6819 );
	VisionSetNaked( "mp_snow", 0 );
}
