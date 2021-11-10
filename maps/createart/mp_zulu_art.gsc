// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_zulu_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 7346.26, 10487.6, 0.583682, 0.52939, 0.302793, 1, 1, 0, 0, 0, 0 );
	VisionSetNaked( "mp_zulu", 0 );
}
