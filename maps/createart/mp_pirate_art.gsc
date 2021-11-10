// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_pirate_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 0, 1, 0.109, 0.113, 0.124, 0.807, 1, 0, 1, 30, 90 );
	VisionSetNaked( "mp_pirate", 0 );
}
