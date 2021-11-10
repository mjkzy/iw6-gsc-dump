#include common_scripts\utility;

//////////////////////////////////////////////////////////////////////////////
//									CONSTANTS								//
//////////////////////////////////////////////////////////////////////////////
level_limit_barrel_fx = 8;
max_fires_from_entity = 4;
level_barrel_fx_chance = 33;


//////////////////////////////////////////////////////////////////////////////
//									LOGIC									//
//////////////////////////////////////////////////////////////////////////////
main()
{
	if ( IsDefined( level.barrels_init ) )
		return;
		
		
	level.barrels_init = true;
	//level._barrel_fx_time = 25; //handle this individually for different barrel types
	barrels = GetEntArray( "barrel_shootable", "targetname" );
	if ( !barrels.size )
		return;
	level._barrels = SpawnStruct();
	level._barrels.num_barrel_fx	 = 0;

	barrels thread precacheFX();
	barrels thread methodsInit();

	thread post_load( barrels );
}

post_load( barrels )
{
	waittillframeend;// insure that structs are initialized
	if( level.createFX_enabled )
		return;
	array_thread( barrels, ::barrelsetup );
}

barrelsetup()
{
	self SetCanDamage( true );
	self SetCanRadiusDamage( false ); // optimization
	self.barrel_fx_array = [];


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
	
	self thread barrel_wait_loop();
}

barrel_wait_loop()
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
			if ( randomint( 100 ) <= level_barrel_fx_chance )
				continue;
		}
		hasTakenDamage = true;
		
		result = self barrel_logic( direction_vec, P, type, attacker );
		if ( result )
			remaining--;
		
		if ( remaining <= 0 )
			break;
	}
	
	self SetCanDamage( false );
}

barrel_logic( direction_vec, P, type, damageOwner )
{
	if ( level._barrels.num_barrel_fx > level_limit_barrel_fx )
		return false;

	if ( !isDefined( level._barrels._barrel_methods[ type ] ) )
		P = self barrel_calc_nofx( P, type );
	else
	P = self [[ level._barrels._barrel_methods[ type ] ]]( P, type );

	if ( !isdefined( P ) )
		return false;

	if ( IsDefined( damageOwner.classname ) && damageOwner.classname == "worldspawn" )
		return false;

	foreach ( value in self.barrel_fx_array )
	{
		if ( DistanceSquared( P, value.origin ) < 25 )
			return false;
	}

	//calculate the vector derived from the center line of our barrel and the point of damage

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
		self thread barrelfx( P, vec, damageOwner );
		return true;
	}
	return false;
}
//DC_NOTE commented out all sound related stuff because it was giving me grief in mp_zulu
barrelfx( P, vec, damageOwner )
{
	time 		 = level._barrels.fx_time[ self.script_noteworthy ] ;
	fx_time		 = level._barrels._barrel_fx_time[ self.script_noteworthy ] ;
	intervals 	 = Int( fx_time / time );// loops for 25 seconds
	intervals_end = 30;
	hitsnd 		 = level._barrels._sound[ self.script_noteworthy + "_hit" ];
	loopsnd 	 = level._barrels._sound[ self.script_noteworthy + "_loop" ];
	endsnd 		 = level._barrels._sound[ self.script_noteworthy + "_end" ];

	snd = Spawn( "script_origin", P );								  
	// snd Hide();
	snd PlaySound( hitsnd );
	snd PlayLoopSound( loopsnd );
	self.barrel_fx_array[ self.barrel_fx_array.size ] = snd;

//	if ( isSP() || self.script_noteworthy != "steam" )
	if ( isSP() )
		self thread barrel_damage( P, vec, damageOwner, snd );

	//rotate the emitter angle over time
	efx_rot = Spawn( "script_model", P );
	efx_rot SetModel( "tag_origin" );
	efx_rot.angles = VectorToAngles( vec );
	wait .05;//cant play fx on same frame it's spawned in mp appearantly
	PlayFXOnTag( level._barrels._effect[ self.script_noteworthy ] , efx_rot, "tag_origin" );
	level._barrels.num_barrel_fx++;
	efx_rot RotatePitch( 90, time, 1, 1 );
	wait time;
	StopFXOnTag( level._barrels._effect[ self.script_noteworthy ] , efx_rot, "tag_origin" );
	intervals--;
	//now check	for other fx and rest of intervals
	while ( level._barrels.num_barrel_fx <= level_limit_barrel_fx && intervals > 0 )
	{
		efx_rot = Spawn( "script_model", P );
		efx_rot SetModel( "tag_origin" );
		efx_rot.angles = VectorToAngles( vec );
		wait .05;//cant play fx on same frame it's spawned in mp appearantly
		PlayFXOnTag( level._barrels._effect[ self.script_noteworthy ] , efx_rot, "tag_origin" );
		level._barrels.num_barrel_fx++;
		efx_rot RotatePitch( 90, time, 1, 1 );
		wait time;
		StopFXOnTag( level._barrels._effect[ self.script_noteworthy ] , efx_rot, "tag_origin" );
	}

//	snd PlaySound( endsnd );
	wait( .5 );
//	snd StopLoopSound( loopsnd );
	snd Delete();
	self.barrel_fx_array = array_removeUndefined( self.barrel_fx_array );

	level._barrels.num_barrel_fx--;
}

barrel_damage( P, vec, damageOwner, fx )
{
	if ( !allow_barrel_damage() )
		return;
		
	fx endon( "death" );

	origin = fx.origin + ( VectorNormalize( vec ) * 40 );
	dmg = level._barrels._dmg[ self.script_noteworthy ];

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

allow_barrel_damage()
{
	if( !isSP() )
		return false;
	
	if ( !isDefined( level.barrelsDamage ) )
		return false;
	
	return ( level.barrelsDamage );
}

//////////////////////////////////////////////////////////////////////////////
//							CALCULATIONS / SETUP							//
//////////////////////////////////////////////////////////////////////////////

methodsInit()
{
	level._barrels._barrel_methods = [];
	level._barrels._barrel_methods[ "MOD_UNKNOWN" ] 			 = ::barrel_calc_splash;
	level._barrels._barrel_methods[ "MOD_PISTOL_BULLET" ] 		 = ::barrel_calc_ballistic;
	level._barrels._barrel_methods[ "MOD_RIFLE_BULLET" ] 		 = ::barrel_calc_ballistic;
	level._barrels._barrel_methods[ "MOD_GRENADE" ] 			 = ::barrel_calc_splash;
	level._barrels._barrel_methods[ "MOD_GRENADE_SPLASH" ] 		 = ::barrel_calc_splash;
	level._barrels._barrel_methods[ "MOD_PROJECTILE" ] 			 = ::barrel_calc_splash;
	level._barrels._barrel_methods[ "MOD_PROJECTILE_SPLASH" ] 	 = ::barrel_calc_splash;
	level._barrels._barrel_methods[ "MOD_TRIGGER_HURT" ] 		 = ::barrel_calc_splash;
	level._barrels._barrel_methods[ "MOD_EXPLOSIVE" ] 			 = ::barrel_calc_splash;
	level._barrels._barrel_methods[ "MOD_EXPLOSIVE_BULLET" ] 	 = ::barrel_calc_splash;
}

barrel_calc_ballistic( P, type )
{
	return P;
}

barrel_calc_splash( P, type )
{
	vec = VectorNormalize( VectorFromLineToPoint( self.A, self.B, P ) );
	P = PointOnSegmentNearestToPoint( self.A, self.B, P );
	return( P + ( vec * 4 ) );
}

barrel_calc_nofx( P, type )
{
	return undefined;
}

precacheFX()
{
	oil_leak = false;
	oil_cap = false;
	beer_leak = false;
	foreach ( value in self )
	{
		if ( value.script_noteworthy == "oil_leak" )
		{
			value willNeverChange();
			oil_leak = true;
		}
		else if ( value.script_noteworthy == "oil_cap" )
		{
			value willNeverChange();
			oil_cap = true;
		}
		else if ( value.script_noteworthy == "beer_leak" )
		{
			value willNeverChange();
			beer_leak = true;
		}
		else
		{
			println( "Unknown 'barrel_shootable' script_noteworthy type '%s'\n", value.script_noteworthy );
		}
	}

	//DC_NOTE commented out all sound related stuff because it was giving me grief in mp_zulu
	if ( oil_leak )
	{
		level._barrels._effect[ "oil_leak" ]		 = loadfx( "fx/impacts/pipe_oil_barrel_spill" );
		//level._barrels._sound[ "oil_leak_hit" ] 	 = "mtl_oil_barrel_hit";
		//level._barrels._sound[ "oil_leak_loop" ] 	 = "mtl_oil_barrel_hiss_loop";
		//level._barrels._sound[ "oil_leak_end" ] 	 = "mtl_oil_barrel_hiss_loop_end";
		level._barrels.fx_time[ "oil_leak" ]		 = 6;
		level._barrels._barrel_fx_time["oil_leak"]   = 6;
		level._barrels._dmg[ "oil_leak" ]			 = 5;
	}
	if ( oil_cap )
	{
		level._barrels._effect[ "oil_cap" ]			 = loadfx( "fx/impacts/pipe_oil_barrel_squirt" );
		//level._barrels._sound[ "oil_cap_hit" ] 		 = "mtl_oil_barrel_hit";
		//level._barrels._sound[ "oil_cap_loop" ] 	 = "mtl_oil_barrel_hiss_loop";
		//level._barrels._sound[ "oil_cap_end" ] 		 = "mtl_oil_barrel_hiss_loop_end";
		level._barrels.fx_time[ "oil_cap" ]		 	 = 3;
		level._barrels._dmg[ "oil_cap" ]			 = 5;
		level._barrels._barrel_fx_time["oil_cap"]    = 5;
	}
	if ( beer_leak )//DC_TODO create beer fx
	{
		level._barrels._effect[ "beer_leak" ]		 = loadfx( "fx/impacts/beer_barrel_spill" );
		level._barrels._sound[ "beer_leak_hit" ] 	 = "mtl_beer_keg_hit";
		level._barrels._sound[ "beer_leak_loop" ] 	 = "mtl_beer_keg_hiss_loop";
		level._barrels._sound[ "beer_leak_end" ] 	 = "mtl_beer_keg_hiss_loop_end";
		level._barrels.fx_time[ "beer_leak" ]		 = 6;
		level._barrels._barrel_fx_time["beer_leak"]  = 6;
		level._barrels._dmg[ "beer_leak" ]			 = 5;
	}
}