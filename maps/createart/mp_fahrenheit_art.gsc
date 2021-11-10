// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_fahrenheit_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 624.344, 2914.77, 0.53, 0.52, 0.57, 1, 1, 0, 0.84, 0.77, 0.67, 1, (-0.79, 0.17, 0.57), 0, 80.7, 0.9, 1, 23.32, 89.58 );
	VisionSetNaked( "mp_fahrenheit", 0 );
}
