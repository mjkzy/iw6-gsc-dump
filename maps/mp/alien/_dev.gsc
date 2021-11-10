
/#
init()
{
	SetDevDvarIfUninitialized( "debug_reflection", "0" );

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );

		player thread updateReflectionProbe();
	}
}

updateReflectionProbe()
{
	for(;;)
	{
		if ( GetDvarInt( "debug_reflection" ) == 1 )
		{
			if ( !IsDefined( self.debug_reflectionobject ) )
			{
				self.debug_reflectionobject = spawn( "script_model", self geteye() + ( ( anglestoforward( self.angles ) * 100 ) ) );
				self.debug_reflectionobject setmodel( "test_sphere_silver" );
				self.debug_reflectionobject.origin = self geteye() + ( ( anglestoforward( self getplayerangles() ) * 100 ) );
				self thread reflectionProbeButtons();
			}
		}
		else if ( GetDvarInt( "debug_reflection" ) == 0 )
		{
			if ( IsDefined( self.debug_reflectionobject ) )
				self.debug_reflectionobject delete();
		}

		wait( 0.05 );
	}
}

reflectionProbeButtons()
{
	offset = 100;
	offsetinc = 50;

	while ( GetDvarInt( "debug_reflection" ) == 1 )
	{
		if ( self buttonpressed( "BUTTON_X" ) )
			offset += offsetinc;
		if ( self buttonpressed( "BUTTON_Y" ) )
			offset -= offsetinc;
		if ( offset > 1000 )
			offset = 1000;
		if ( offset < 64 )
			offset = 64;

		self.debug_reflectionobject.origin = self GetEye() + ( ( AnglesToForward( self GetPlayerAngles() ) * offset ) );

		wait .05;
	}
}
#/