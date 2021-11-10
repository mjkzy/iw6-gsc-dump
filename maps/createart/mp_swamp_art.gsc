// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_swamp_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 0, 2985.05, 0.339273, 0.302975, 0.400243, 1, 0.485193, 0, 0, 0, 0 );
	VisionSetNaked( "mp_swamp", 0 );
}
