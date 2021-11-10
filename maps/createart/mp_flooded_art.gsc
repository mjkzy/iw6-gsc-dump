// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_flooded_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 600, 1600, 0.721569, 0.823529, 0.929412, 1, 0.314067, 0, 0, 0, 90 );
	VisionSetNaked( "mp_flooded", 0 );
}
