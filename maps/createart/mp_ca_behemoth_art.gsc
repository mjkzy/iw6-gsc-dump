// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_ca_behemoth_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 0, 34658, 0.423529, 0.490196, 0.666667, 0.88, 0.776167, 0, 0.482353, 0.458824, 0.4, 2.3, (0, 0, -1), 0, 135, 10, 0.901, 180, 113 );
	VisionSetNaked( "mp_ca_behemoth", 0 );
}
