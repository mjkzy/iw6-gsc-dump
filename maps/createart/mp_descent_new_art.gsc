main()
{
	level.tweakfile = true;
 	level.parse_fog_func = maps\createart\mp_descent_new_fog::main;
  
	//* Fog section * 

	setDevDvar( "scr_fog_disable", "0" );

//	setExpFog( 0, 5211.68, 0.480657, 0.755661, 0.785471, 2.01908, 0, 0, 0, 0, 0 );
	VisionSetNaked( "mp_descent_new", 0 );

}
