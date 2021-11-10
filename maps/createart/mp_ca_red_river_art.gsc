// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_ca_red_river_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 7220, 1084, 0.901961, 0.917647, 0.843137, 1, 0.2094, 0, 0, 0, 90 );
	VisionSetNaked( "mp_ca_red_river", 0 );
}
