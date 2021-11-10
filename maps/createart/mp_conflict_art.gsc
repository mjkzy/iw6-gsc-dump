// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_conflict_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 0, 1958.84, 0.656882, 0.680657, 0.696267, 2, 0.90625, 0, 0.396688, 0.396688, 0.396619, 0.5, (0, 0, -1), 80, 105, 0.0625, 0.960938, 0, 54 );
	VisionSetNaked( "mp_conflict", 0 );
}
