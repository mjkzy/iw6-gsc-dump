// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_mine_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 122.24, 25282, 0.846864, 0.748939, 0.5479, 1, 1, 0, 0, 0, 0 );
	VisionSetNaked( "mp_mine", 0 );
}
