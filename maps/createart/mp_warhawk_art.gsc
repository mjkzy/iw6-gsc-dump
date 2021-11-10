// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_warhawk_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 1307.29, 8178.08, 0.888789, 0.851156, 0.664851, 1.07658, 0.468766, 0, 0.639683, 0.464798, 0.346012, 0.573353, (0.89, 0.06, 0.44), 0, 137, 2.40463, 0.730742, 26.9803, 63.638 );
	VisionSetNaked( "mp_warhawk", 0 );
}
