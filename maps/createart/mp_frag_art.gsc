// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_frag_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 1500, 6145, 0.8, 0.88, 1, 1, 0.25, 0, 1, 1, 0.94, 1.06, (0.76, 0.38, 0.51), 0, 100, 1, 1, 60, 85 );
	VisionSetNaked( "mp_frag", 0 );
}
