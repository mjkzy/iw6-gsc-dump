// _createart generated.  modify at your own risk. Changing values should be fine.
main()
{
	level.tweakfile = true;
	level.parse_fog_func = maps\createart\mp_skeleton_fog::main;

	setDevDvar( "scr_fog_disable", "0" );
//	setExpFog( 575.658, 5181.9, 0.899167, 0.930833, 1, 3.42928, 0.619243, 0, 1, 78.972, 92.2944 );
	VisionSetNaked( "mp_skeleton", 0 );
}
