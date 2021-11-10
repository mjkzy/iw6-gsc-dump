// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_strikezone_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 525.762, 18137.9, 0.62, 0.81, 0.81, 1.4, 1, 0, 0.99, 0.97, 0.83, 1.2, (-0.05, -0.89, 0.44), 0, 100, 0.9, 1, 13.7392, 117.129 );
	VisionSetNaked( "mp_strikezone", 0 );
}
