// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_ca_impact_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 3026.57, 1163.94, 0.711328, 0.78437, 0.798145, 0.793067, 0.811095, 0, 1, -0.538688, 90 );
	VisionSetNaked( "mp_ca_impact", 0 );
}
