#include common_scripts\utility;

//////////////////////////////////////////////////////////////////////////////
//									CONSTANTS								//
//////////////////////////////////////////////////////////////////////////////
level_limit_pipe_fx = 8;
max_fires_from_entity = 4;
level_pipe_fx_chance = 33;


//////////////////////////////////////////////////////////////////////////////
//									LOGIC									//
//////////////////////////////////////////////////////////////////////////////
main()
{
	if ( IsDefined( level.pipes_init ) )
		return;
		
		
	level.pipes_init = true;
	//level._pipe_fx_time = 25; //handle this individually for different pipe types
	pipes = GetEntArray( "pipe_shootable", "targetname" );
	if ( !pipes.size )
		return;
	level._pipes = SpawnStruct();
	level._pipes.num_pipe_fx	 = 0;

	pipes thread precacheFX();
	pipes thread methodsInit();

	thread post_load( pipes );
}

post_load( pipes )
{
	waittillframeend;// insure that structs are initialized
	if( level.createFX_enabled )
		return;
	array_thread( pipes, ::pipesetup );
}

pipesetup()
{
	self SetCanDamage( true );
	self SetCanRadiusDamage( false ); // optimization
	self.pipe_fx_array = [];


	node = undefined;

	if ( IsDefined( self.target ) )
	{
		node = getstruct( self.target, "targetname" );
		self.A = node.origin;
		vec = AnglesToForward( node.angles );
		vec = ( vec * 128 );
		self.B = self.A + vec;
	}
	else
	{
		vec = AnglesToForward( self.angles );
		vec1 = ( vec * 64 );
		self.A = self.origin + vec1;
		vec1 = ( vec * -64 );
		self.B = self.origin + vec1;
	}
	
	self thread pipe_wait_loop();
}

pipe_wait_loop()
{
	P = ( 0, 0, 0 );// just to initialize P as a vector
	
	hasTakenDamage = false;
	remaining = max_fires_from_entity;
	
	while ( 1 )
	{
		self waittill( "damage", damage, attacker, direction_vec, P, type );
		
		// random so we don't get so many fx, but the very first time is guarenteed
		if ( hasTakenDamage )
		{
			if ( randomint( 100 ) <= level_pipe_fx_chance )
				continue;
		}
		hasTakenDamage = true;
		
		result = self pipe_logic( direction_vec, P, type, attacker );
		if ( result )
			remaining--;
		
		if ( remaining <= 0 )
			break;
	}
	
	self SetCanDamage( false );
}

pipe_logic( direction_vec, P, type, damageOwner )
{
	if ( level._pipes.num_pipe_fx > level_limit_pipe_fx )
		return false;

	if ( !isDefined( level._pipes._pipe_methods[ type ] ) )
		P = self pipe_calc_nofx( P, type );
	else
	P = self [[ level._pipes._pipe_methods[ type ] ]]( P, type );

	if ( !isdefined( P ) )
		return false;

	if ( IsDefined( damageOwner.classname ) && damageOwner.classname == "worldspawn" )
		return false;

	foreach ( value in self.pipe_fx_array )
	{
		if ( DistanceSquared( P, value.origin ) < 25 )
			return false;
	}

	//calculate the vector derived from the center line of our pipe and the point of damage

	// generate a vector from the attacker's eye to the impact point (AI) or origin to impact point (non-AI)
	E = undefined;
	if( IsAI( damageOwner ))
		E = damageOwner GetEye();
	else
		E = damageOwner.origin;
	
	temp_vec = P - E;
	
	// Extend the vector (this is to ensure it intersects the damaged entity, tracing to the point itself generated new points which were slightly off and bad normals) and return a trace
	trace = BulletTrace ( E, E + 1.5 * temp_vec, false, damageOwner, false );
	if ( isdefined ( trace [ "normal" ] ) && isdefined ( trace [ "entity" ] ) && trace ["entity"] == self )
	{
		vec	  = trace[ "normal" ];

		// Use the surface normal of the impact point to generate the angles for the burst effect
		self thread pipefx( P, vec, damageOwner );
		return true;
	}
	return false;
}

pipefx( P, vec, damageOwner )
{
	time 		 = level._pipes.fx_time[ self.script_noteworthy ] ;
	fx_time		 = level._pipes._pipe_fx_time[ self.script_noteworthy ] ;
	intervals 	 = Int( fx_time / time );// loops for 25 seconds
	intervals_end = 30;
	hitsnd 		 = level._pipes._sound[ self.script_noteworthy + "_hit" ];
	loopsnd 	 = level._pipes._sound[ self.script_noteworthy + "_loop" ];
	endsnd 		 = level._pipes._sound[ self.script_noteworthy + "_end" ];

	snd = Spawn( "script_origin", P );								  
	// snd Hide();
	snd PlaySound( hitsnd );
	snd PlayLoopSound( loopsnd );
	self.pipe_fx_array[ self.pipe_fx_array.size ] = snd;

	if ( isSP() || self.script_noteworthy != "steam" )
		self thread pipe_damage( P, vec, damageOwner, snd );

	//if it is a barrel, rotate the emitter angle over time
	if( self.script_noteworthy == "oil_leak" )
	{
		efx_rot = Spawn( "script_model", P );
		efx_rot SetModel( "tag_origin" );
		efx_rot.angles = VectorToAngles( vec );
		PlayFXOnTag( level._pipes._effect[ self.script_noteworthy ] , efx_rot, "tag_origin" );
		level._pipes.num_pipe_fx++;
		efx_rot RotatePitch( 90, time, 1, 1 );
		wait time;
		StopFXOnTag( level._pipes._effect[ self.script_noteworthy ] , efx_rot, "tag_origin" );
		intervals--;
	}
	else
	{
		//do it once without checking for newer fx being played ( we're the newest )
		PlayFX( level._pipes._effect[ self.script_noteworthy ], P, vec );
		level._pipes.num_pipe_fx++;
		wait time;
		intervals--;
	}
	//now check	for other fx and rest of intervals
	while ( level._pipes.num_pipe_fx <= level_limit_pipe_fx && intervals > 0 )
	{
		if( self.script_noteworthy == "oil_leak" )
		{
			efx_rot = Spawn( "script_model", P );
			efx_rot SetModel( "tag_origin" );
			efx_rot.angles = VectorToAngles( vec );
			PlayFXOnTag( level._pipes._effect[ self.script_noteworthy ] , efx_rot, "tag_origin" );
			level._pipes.num_pipe_fx++;
			efx_rot RotatePitch( 90, time, 1, 1 );
			wait time;
			StopFXOnTag( level._pipes._effect[ self.script_noteworthy ] , efx_rot, "tag_origin" );
		}
		else
		{
			//do it once without checking for newer fx being played ( we're the newest )
			PlayFX( level._pipes._effect[ self.script_noteworthy ], P, vec );
			wait time;
			intervals--;
		}
	}

	snd PlaySound( endsnd );
	wait( .5 );
	snd StopLoopSound( loopsnd );
	snd Delete();
	self.pipe_fx_array = array_removeUndefined( self.pipe_fx_array );

	level._pipes.num_pipe_fx--;
}

pipe_damage( P, vec, damageOwner, fx )
{
	if ( !allow_pipe_damage() )
		return;
		
	fx endon( "death" );

	origin = fx.origin + ( VectorNormalize( vec ) * 40 );
	dmg = level._pipes._dmg[ self.script_noteworthy ];

	while ( 1 )
	{
		// do not pass damage owner if they have disconnected before the barrels explode.. the barrels?
		if ( !isdefined( self.damageOwner ) )
		{
			// MOD_TRIGGER_HURT so they dont do dirt on the player's screen
			self RadiusDamage( origin, 36, dmg, dmg * 0.75, undefined, "MOD_TRIGGER_HURT" );
		}
		else
		{
			// MOD_TRIGGER_HURT so they dont do dirt on the player's screen
			self RadiusDamage( origin, 36, dmg, dmg * 0.75, damageOwner, "MOD_TRIGGER_HURT" );
		}

		wait( 0.4 );
	}
}

allow_pipe_damage()
{
	if( !isSP() )
		return false;
	
	if ( !isDefined( level.pipesDamage ) )
		return true;
	
	return ( level.pipesDamage );
}

//////////////////////////////////////////////////////////////////////////////
//							CALCULATIONS / SETUP							//
//////////////////////////////////////////////////////////////////////////////

methodsInit()
{
	level._pipes._pipe_methods = [];
	level._pipes._pipe_methods[ "MOD_UNKNOWN" ] 				 = ::pipe_calc_splash;
	level._pipes._pipe_methods[ "MOD_PISTOL_BULLET" ] 		 = ::pipe_calc_ballistic;
	level._pipes._pipe_methods[ "MOD_RIFLE_BULLET" ] 			 = ::pipe_calc_ballistic;
	level._pipes._pipe_methods[ "MOD_GRENADE" ] 				 = ::pipe_calc_splash;
	level._pipes._pipe_methods[ "MOD_GRENADE_SPLASH" ] 		 = ::pipe_calc_splash;
	level._pipes._pipe_methods[ "MOD_PROJECTILE" ] 			 = ::pipe_calc_splash;
	level._pipes._pipe_methods[ "MOD_PROJECTILE_SPLASH" ] 	 = ::pipe_calc_splash;
	level._pipes._pipe_methods[ "MOD_TRIGGER_HURT" ] 			 = ::pipe_calc_splash;
	level._pipes._pipe_methods[ "MOD_EXPLOSIVE" ] 			 = ::pipe_calc_splash;
	level._pipes._pipe_methods[ "MOD_EXPLOSIVE_BULLET" ] 	 = ::pipe_calc_splash;
}

pipe_calc_ballistic( P, type )
{
	return P;
}

pipe_calc_splash( P, type )
{
	vec = VectorNormalize( VectorFromLineToPoint( self.A, self.B, P ) );
	P = PointOnSegmentNearestToPoint( self.A, self.B, P );
	return( P + ( vec * 4 ) );
}

pipe_calc_nofx( P, type )
{
	return undefined;
}

precacheFX()
{
	steam = false;
	fire = false;
	steam_small = false;
	oil_leak = false;
	oil_cap = false;
	foreach ( value in self )
	{
		if ( value.script_noteworthy == "water" )
			value.script_noteworthy = "steam";

		if ( value.script_noteworthy == "steam" )
		{
			value willNeverChange();
			steam = true;
		}
		else if ( value.script_noteworthy == "fire" )
		{
			value willNeverChange();
			fire = true;
		}
		else if ( value.script_noteworthy == "steam_small" )
		{
			value willNeverChange();
			steam_small = true;
		}
		else if ( value.script_noteworthy == "oil_leak" )
		{
			value willNeverChange();
			oil_leak = true;
		}
		else if ( value.script_noteworthy == "oil_cap" )
		{
			value willNeverChange();
			oil_cap = true;
		}
		else
		{
			println( "Unknown 'pipe_shootable' script_noteworthy type '%s'\n", value.script_noteworthy );
		}
	}

	if ( steam )
	{
		level._pipes._effect[ "steam" ]		 = LoadFX( "fx/impacts/pipe_steam" );
		level._pipes._sound[ "steam_hit" ] 	 = "mtl_steam_pipe_hit";
		level._pipes._sound[ "steam_loop" ] = "mtl_steam_pipe_hiss_loop";
		level._pipes._sound[ "steam_end" ] = "mtl_steam_pipe_hiss_loop_end";
		level._pipes.fx_time[ "steam" ]		 = 3;
		level._pipes._dmg[ "steam" ]		 = 5;
		level._pipes._pipe_fx_time["steam"]   = 25;
	}
	
	if ( steam_small )
	{
		level._pipes._effect[ "steam_small" ]		 = LoadFX( "fx/impacts/pipe_steam_small" );
		level._pipes._sound[ "steam_small_hit" ] 	 = "mtl_steam_pipe_hit";
		level._pipes._sound[ "steam_small_loop" ] = "mtl_steam_pipe_hiss_loop";
		level._pipes._sound[ "steam_small_end" ] = "mtl_steam_pipe_hiss_loop_end";
		level._pipes.fx_time[ "steam_small" ]		 = 3;
		level._pipes._dmg[ "steam_small" ]		 = 5;
		level._pipes._pipe_fx_time["steam_small"]   = 25;
	}

	if ( fire )
	{
		level._pipes._effect[ "fire" ]		 = LoadFX( "fx/impacts/pipe_fire" );
		level._pipes._sound[ "fire_hit" ]	 = "mtl_gas_pipe_hit";
		level._pipes._sound[ "fire_loop" ]	 = "mtl_gas_pipe_flame_loop";
		level._pipes._sound[ "fire_end" ]	 = "mtl_gas_pipe_flame_end";
		level._pipes.fx_time[ "fire" ]		 = 3;
		level._pipes._dmg[ "fire" ]			 = 5;
		level._pipes._pipe_fx_time["fire"]   = 25;
	}
	
	if ( oil_leak )
	{
		level._pipes._effect[ "oil_leak" ]		 = LoadFX( "fx/impacts/pipe_oil_barrel_spill" );
//		level._pipes._effect[ "oil_leak_end" ]	 = LoadFX( "fx/impacts/pipe_oil_barrel_spill_ending1" );
		level._pipes._sound[ "oil_leak_hit" ] 	 = "mtl_oil_barrel_hit";
		level._pipes._sound[ "oil_leak_loop" ] 	 = "mtl_oil_barrel_hiss_loop";
		level._pipes._sound[ "oil_leak_end" ] 	 = "mtl_oil_barrel_hiss_loop_end";
		level._pipes.fx_time[ "oil_leak" ]		 = 6;
		level._pipes._pipe_fx_time["oil_leak"]   = 6;
		level._pipes._dmg[ "oil_leak" ]			 = 5;
	}
	
	if ( oil_cap )
	{
		level._pipes._effect[ "oil_cap" ]		 = LoadFX( "fx/impacts/pipe_oil_barrel_squirt" );
		level._pipes._sound[ "oil_cap_hit" ] 	 = "mtl_steam_pipe_hit";
		level._pipes._sound[ "oil_cap_loop" ] 	 = "mtl_steam_pipe_hiss_loop";
		level._pipes._sound[ "oil_cap_end" ] 	 = "mtl_steam_pipe_hiss_loop_end";
		level._pipes.fx_time[ "oil_cap" ]		 = 3;
		level._pipes._dmg[ "oil_cap" ]			 = 5;
		level._pipes._pipe_fx_time["oil_cap"]    = 5;
	}
}



