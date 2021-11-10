#include common_scripts\utility;
#include common_scripts\_createfx;

CONST_MAX_SP_CREATEFX 		= 1500;
CONST_MAX_SP_CREATESOUND 	= 384;
initFX()
{
	if ( !isdefined( level.func ) )
		level.func = [];
	
	if ( !isdefined( level.func[ "create_triggerfx" ] ) )
		 level.func[ "create_triggerfx" ] = ::create_triggerfx;

	if ( !IsDefined( level._fx ) )
		level._fx = SpawnStruct();
		 
	create_lock( "createfx_looper", 20 );
	level.fxfireloopmod = 1;

	// wrapper for the exploder function so we dont have to use flags and do ifs/waittills on every exploder call
	level._fx.exploderFunction = common_scripts\_exploder::exploder_before_load;
	waittillframeend;// Wait one frame so the effects get setup by the maps fx thread
	waittillframeend;// Wait another frame so effects can be loaded based on start functions. Without this FX are initialiazed before they are defined by start functions.
	level._fx.exploderFunction = common_scripts\_exploder::exploder_after_load;
	
	level._fx.server_culled_sounds = false;
	if ( GetDvarInt( "serverCulledSounds" ) == 1 )
		level._fx.server_culled_sounds = true;
	
	if ( level.createFX_enabled )
		level._fx.server_culled_sounds = false;
	
/#
	SetDevDvarIfUninitialized( "scr_map_exploder_dump", 0 );
	SetDevDvarIfUninitialized( "createfx_removedupes", 0 );
		
	if ( GetDvarInt( "r_reflectionProbeGenerate" ) == 1 )
		level._fx.server_culled_sounds = true;
#/

	// Give createfx_common time to delete triggers to free up entity slots.
	if ( level.createFX_enabled )
	{
		level waittill( "createfx_common_done" );
	}
	
/#
	remove_dupes();
#/
	
	for ( i = 0; i < level.createFXent.size; i++ )
	{
		ent = level.createFXent[ i ];
		ent set_forward_and_up_vectors();
		
		switch ( ent.v[ "type" ] )
		{
			case "loopfx":
				ent thread loopfxthread();
				break;
			case "oneshotfx":
				ent thread oneshotfxthread();
				break;
			case "soundfx":
				ent thread create_loopsound();
				break;
			case "soundfx_interval":
				ent thread create_interval_sound();
				break;
			case "reactive_fx":
				ent add_reactive_fx();
				break;
		}
	}
		
	check_createfx_limit();
}

remove_dupes()
{
/#
	if ( GetDvarInt( "createfx_removedupes" ) == 0 )
		return;

	new_ents = [];
	for ( i = 0; i < level.createFXent.size; i++ )
	{
		add_ent = true;
		i_ent = level.createFXent[ i ];
		for ( j = i + 1; j < level.createFXent.size; j++ )
		{
			j_ent = level.createFXent[ j ];
			
			if ( j_ent.v[ "type" ] == i_ent.v[ "type" ] )
			{
				if ( j_ent.v[ "origin" ] == i_ent.v[ "origin" ] )
				{
					println( "^3--REMOVING DUPE'D " + j_ent.v[ "type" ] + " AT " + j_ent.v[ "origin" ] );
					add_ent = false;
				}
			}
		}
		
		if ( add_ent )
			new_ents[ new_ents.size ] = i_ent;
	}
	
	level.createFXent = new_ents;
#/
}

check_createfx_limit()
{
/#
	if ( !isSP() )
	{
		return;
	}

	fx_count = 0;
	sound_count = 0;
	foreach ( ent in level.createFXent )
	{
		if ( is_createfx_type( ent, "fx" ) )
			fx_count++;
		else if ( is_createfx_type( ent, "sound" ) )
			sound_count++;
	}
	
	println( "^5Total CreateFX FX Ents: " + fx_count );
	println( "^5Total CreateFX SOUND Ents: " + sound_count );
	
	check_limit_type( "fx", fx_count );
	check_limit_type( "sound", sound_count );
#/
}

check_limit_type( type, count )
{
/#
	limit = undefined;
	if ( type == "fx" )
	{
		limit = CONST_MAX_SP_CREATEFX;
	}
	else if ( type == "sound" )
	{
		limit = CONST_MAX_SP_CREATESOUND;
	}
	
	if ( count > limit )
		AssertMsg( "CREATEFX: You have too many " + type + " createFX ents. You need to reduce the amount.\nYou have " + count + " and the limit is " + limit );
#/
}


print_org( fxcommand, fxId, fxPos, waittime )
{
	if ( GetDvar( "debug" ) == "1" )
	{
		println( "{" );
		println( "\"origin\" \"" + fxPos[ 0 ] + " " + fxPos[ 1 ] + " " + fxPos[ 2 ] + "\"" );
		println( "\"classname\" \"script_model\"" );
		println( "\"model\" \"fx\"" );
		println( "\"script_fxcommand\" \"" + fxcommand + "\"" );
		println( "\"script_fxid\" \"" + fxId + "\"" );
		println( "\"script_delay\" \"" + waittime + "\"" );
		println( "}" );
	}
}

OneShotfx( fxId, fxPos, waittime, fxPos2 )
{
//	level thread print_org ("OneShotfx", fxId, fxPos, waittime);
//    level thread OneShotfxthread (fxId, fxPos, waittime, fxPos2);
}

exploderfx( num, fxId, fxPos, waittime, fxPos2, fireFx, fireFxDelay, fireFxSound, fxSound, fxQuake, fxDamage, soundalias, repeat, delay_min, delay_max, damage_radius, fireFxTimeout, exploder_group )
{
	if ( 1 )
	{
		ent = createExploder( fxId );
		ent.v[ "origin" ] = fxPos;
		ent.v[ "angles" ] = ( 0, 0, 0 );
		if ( isdefined( fxPos2 ) )
			ent.v[ "angles" ] = vectortoangles( fxPos2 - fxPos );
		ent.v[ "delay" ] = waittime;
		ent.v[ "exploder" ] = num;
		if (isdefined(level.createFXexploders))
		{	// if we're using the optimized lookup, add it in the proper place
			ary = level.createFXexploders[ ent.v[ "exploder" ] ];
			if (!isdefined(ary))
				ary = [];
			ary[ary.size] = ent;
			level.createFXexploders[ ent.v[ "exploder" ] ] = ary;
		}
		// deprecated
		return;
	}
	fx = spawn( "script_origin", ( 0, 0, 0 ) );
//	println ("total ", getentarray ("script_origin","classname").size);
	fx.origin = fxPos;
	fx.angles = vectortoangles( fxPos2 - fxPos );
//	fx.targetname = "exploder";
	fx.script_exploder = num;
	fx.script_fxid = fxId;
	fx.script_delay = waittime;

	fx.script_firefx = fireFx;
	fx.script_firefxdelay = ( fireFxDelay );// for awhile the script exported strings for this value so we cast it to float
	fx.script_firefxsound = fireFxSound;

	fx.script_sound = fxSound;
	fx.script_earthquake = fxQuake;
	fx.script_damage = ( fxDamage );
	fx.script_radius = ( damage_radius );
	fx.script_soundalias = soundalias;
	fx.script_firefxtimeout = ( fireFxTimeout );
	fx.script_repeat = ( repeat );
	fx.script_delay_min = ( delay_min );
	fx.script_delay_max = ( delay_max );
	fx.script_exploder_group = exploder_group;

	forward = anglestoforward( fx.angles );
	forward  *= ( 150 );
	fx.targetPos = fxPos + forward;

	if ( !isdefined( level._script_exploders ) )
		level._script_exploders = [];
	level._script_exploders[ level._script_exploders.size ] = fx;
}


/*
loopfxRotate(fxId, fxPos, waittime, angle, fxStart, fxStop, timeout)
{
	level thread print_org ("loopfx", fxId, fxPos, waittime);
    level thread loopfxthread (fxId, fxPos, waittime, fxPos2, fxStart, fxStop, timeout);
}
*/


loopfx( fxId, fxPos, waittime, fxPos2, fxStart, fxStop, timeout )
{
	println( "Loopfx is deprecated!" );
	ent = createLoopEffect( fxId );
	ent.v[ "origin" ] = fxPos;
	ent.v[ "angles" ] = ( 0, 0, 0 );
	if ( isdefined( fxPos2 ) )
		ent.v[ "angles" ] = vectortoangles( fxPos2 - fxPos );
	ent.v[ "delay" ] = waittime;
}

/*
loopfx(fxId, fxPos, waittime, fxPos2, fxStart, fxStop, timeout)
{
	level thread print_org ("loopfx", fxId, fxPos, waittime);
    level thread loopfxthread (fxId, fxPos, waittime, fxPos2, fxStart, fxStop, timeout);
}
*/

create_looper()
{
	//assert (isdefined(self.looper));
	self.looper = playLoopedFx( level._effect[ self.v[ "fxid" ] ], self.v[ "delay" ], self.v[ "origin" ], 0, self.v[ "forward" ], self.v[ "up" ] );
	create_loopsound();
}

create_loopsound()
{
	self notify( "stop_loop" );
	
	if ( !IsDefined( self.v[ "soundalias" ] ) )
		return;
	
	if ( self.v[ "soundalias" ] == "nil" )
		return;
	
/#
	if ( GetDvar( "r_reflectionProbeGenerate" ) == "1" )
		return;
#/

	culled = false;
	end_on = undefined;
	if ( isdefined( self.v[ "stopable" ] ) && self.v[ "stopable" ] )
	{
		if ( IsDefined( self.looper ) )
			end_on = "death";
		else
			end_on = "stop_loop";
	}
	else
	{
		if ( level._fx.server_culled_sounds && IsDefined( self.v[ "server_culled" ] ) )
			culled = self.v[ "server_culled" ];
	}
	
	ent = self;
	if ( IsDefined( self.looper ) )
		ent = self.looper;
	
	createfx_ent = undefined;
	if ( level.createFX_enabled )
		createfx_ent = self;
	
	ent loop_fx_sound_with_angles( self.v[ "soundalias" ], self.v[ "origin" ], self.v[ "angles" ], culled, end_on, createfx_ent );
}

create_interval_sound()
{
	self notify( "stop_loop" );
	
	if ( !IsDefined( self.v[ "soundalias" ] ) )
		return;
	if ( self.v[ "soundalias" ] == "nil" )
		return;

	ender = undefined;
	runner = self;
	
/#
	if ( GetDvar( "r_reflectionProbeGenerate" ) == "1" )
		return;
#/

	
	if( ( IsDefined( self.v[ "stopable" ] ) && self.v[ "stopable" ] ) || level.createFX_enabled )
	{
		if ( IsDefined( self.looper ) )
		{
			runner = self.looper;
			ender = "death";
		}
		else
			ender = "stop_loop";
		
	}
	
	runner thread loop_fx_sound_interval_with_angles( self.v[ "soundalias" ], self.v[ "origin" ], self.v[ "angles" ], ender, undefined, self.v[ "delay_min" ], self.v[ "delay_max" ] );
}

loopfxthread()
{
	waitframe();
//	println ( "fx testing running Id: ", fxId );
//    if ((isdefined (level.scr_sound)) && (isdefined (level.scr_sound[fxId])))
//	   loopSound(level.scr_sound[fxId], fxPos);

	if ( isdefined( self.fxStart ) )
		level waittill( "start fx" + self.fxStart );

	while ( 1 )
	{
		/*
		if (isdefined (ent.org2))
		{
			fxAngle = vectorNormalize (ent.org2 - ent.org);
			looper = playLoopedFx( level._effect[fxId], ent.delay, ent.org, 0, fxAngle );
		}
		else
			looper = playLoopedFx( level._effect[fxId], ent.delay, ent.org, 0 );
		*/
		create_looper();

		if ( isdefined( self.timeout ) )
			thread loopfxStop( self.timeout );

		if ( isdefined( self.fxStop ) )
			level waittill( "stop fx" + self.fxStop );
		else
			return;

		if ( isdefined( self.looper ) )
			self.looper delete();

		if ( isdefined( self.fxStart ) )
			level waittill( "start fx" + self.fxStart );
		else
			return;
	}
}

loopfxChangeID( ent )
{
	self endon( "death" );
	ent waittill( "effect id changed", change );
}

loopfxChangeOrg( ent )
{
	self endon( "death" );
	for ( ;; )
	{
		ent waittill( "effect org changed", change );
		self.origin = change;
	}
}

loopfxChangeDelay( ent )
{
	self endon( "death" );
	ent waittill( "effect delay changed", change );
}

loopfxDeletion( ent )
{
	self endon( "death" );
	ent waittill( "effect deleted" );
	self delete();
}

loopfxStop( timeout )
{
	self endon( "death" );
	wait( timeout );
	self.looper delete();
}

loopSound( sound, Pos, waittime )
{
//	level thread print_org ("loopSound", sound, Pos, waittime);
	level thread loopSoundthread( sound, Pos, waittime );
}

loopSoundthread( sound, pos, waittime )
{
	org = spawn( "script_origin", ( pos ) );

	org.origin = pos;
//	println ("hello1 ", org.origin, sound);
	org playLoopSound( sound );
}

gunfireloopfx( fxId, fxPos, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax )
{
    thread gunfireloopfxthread( fxId, fxPos, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax );
}

gunfireloopfxthread( fxId, fxPos, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax )
{
	level endon( "stop all gunfireloopfx" );
	waitframe();

	if ( betweenSetsMax < betweenSetsMin )
	{
		temp = betweenSetsMax;
		betweenSetsMax = betweenSetsMin;
		betweenSetsMin = temp;
	}

	betweenSetsBase = betweenSetsMin;
	betweenSetsRange = betweenSetsMax - betweenSetsMin;

	if ( shotdelayMax < shotdelayMin )
	{
		temp = shotdelayMax;
		shotdelayMax = shotdelayMin;
		shotdelayMin = temp;
	}

	shotdelayBase = shotdelayMin;
	shotdelayRange = shotdelayMax - shotdelayMin;

	if ( shotsMax < shotsMin )
	{
		temp = shotsMax;
		shotsMax = shotsMin;
		shotsMin = temp;
	}

	shotsBase = shotsMin;
	shotsRange = shotsMax - shotsMin;

	fxEnt = spawnFx( level._effect[ fxId ], fxPos );
	
	if ( !level.createFX_enabled )
		fxEnt willNeverChange();
		
    for ( ;; )
    {
		shotnum = shotsBase + randomint( shotsRange );
		for ( i = 0;i < shotnum;i++ )
		{
			triggerFx( fxEnt );

			wait( shotdelayBase + randomfloat( shotdelayRange ) );
		}
        wait( betweenSetsBase + randomfloat( betweenSetsRange ) );
    }
}

gunfireloopfxVec( fxId, fxPos, fxPos2, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax )
{
    thread gunfireloopfxVecthread( fxId, fxPos, fxPos2, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax );
}

gunfireloopfxVecthread( fxId, fxPos, fxPos2, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax )
{
	level endon( "stop all gunfireloopfx" );
	waitframe();

	if ( betweenSetsMax < betweenSetsMin )
	{
		temp = betweenSetsMax;
		betweenSetsMax = betweenSetsMin;
		betweenSetsMin = temp;
	}

	betweenSetsBase = betweenSetsMin;
	betweenSetsRange = betweenSetsMax - betweenSetsMin;

	if ( shotdelayMax < shotdelayMin )
	{
		temp = shotdelayMax;
		shotdelayMax = shotdelayMin;
		shotdelayMin = temp;
	}

	shotdelayBase = shotdelayMin;
	shotdelayRange = shotdelayMax - shotdelayMin;

	if ( shotsMax < shotsMin )
	{
		temp = shotsMax;
		shotsMax = shotsMin;
		shotsMin = temp;
	}

	shotsBase = shotsMin;
	shotsRange = shotsMax - shotsMin;

	fxPos2 = vectornormalize( fxPos2 - fxPos );

	fxEnt = spawnFx( level._effect[ fxId ], fxPos, fxPos2 );

	if ( !level.createFX_enabled )
		fxEnt willNeverChange();

	for ( ;; )
	{
		shotnum = shotsBase + randomint( shotsRange );
		for ( i = 0;i < int( shotnum / level.fxfireloopmod );i++ )
		{
			triggerFx( fxEnt );
			delay = ( ( shotdelayBase + randomfloat( shotdelayRange ) ) * level.fxfireloopmod );
			if ( delay < .05 )
				delay = .05;
			wait delay;
		}
		wait( shotdelayBase + randomfloat( shotdelayRange ) );
		wait( betweenSetsBase + randomfloat( betweenSetsRange ) );
	}
}

setfireloopmod( value )
{
	level.fxfireloopmod = 1 / value;
}

setup_fx()
{
	if ( ( !isdefined( self.script_fxid ) ) || ( !isdefined( self.script_fxcommand ) ) || ( !isdefined( self.script_delay ) ) )
	{
//		println (self.script_fxid);
//		println (self.script_fxcommand);
//		println (self.script_delay);
//		println ("Effect at origin ", self.origin," doesn't have script_fxid/script_fxcommand/script_delay");
//		self delete();
		return;
	}

//	println ("^a Command:", self.script_fxcommand, " Effect:", self.script_fxID, " Delay:", self.script_delay, " ", self.origin);
	if ( isdefined( self.model ) )
		if ( self.model == "toilet" )
		{
			self thread burnville_paratrooper_hack();
			return;
		}

	org = undefined;
	if ( isdefined( self.target ) )
	{
		ent = getent( self.target, "targetname" );
		if ( isdefined( ent ) )
			org = ent.origin;
	}

	fxStart = undefined;
	if ( isdefined( self.script_fxstart ) )
		fxStart = self.script_fxstart;

	fxStop = undefined;
	if ( isdefined( self.script_fxstop ) )
		fxStop = self.script_fxstop;

	if ( self.script_fxcommand == "OneShotfx" )
		OneShotfx( self.script_fxId, self.origin, self.script_delay, org );
	if ( self.script_fxcommand == "loopfx" )
		loopfx( self.script_fxId, self.origin, self.script_delay, org, fxStart, fxStop );
	if ( self.script_fxcommand == "loopsound" )
		loopsound( self.script_fxId, self.origin, self.script_delay );

	self delete();
}

burnville_paratrooper_hack()
{
	normal = ( 0, 0, self.angles[ 1 ] );
//	println ("z:       paratrooper fx hack: ", normal);
	id = level._effect[ self.script_fxId ];
	origin = self.origin;

//	if (isdefined (self.script_delay))
//		wait (self.script_delay);

	wait 1;
	level thread burnville_paratrooper_hack_loop( normal, origin, id );
	self delete();
}

burnville_paratrooper_hack_loop( normal, origin, id )
{
	while ( 1 )
	{
	//	iprintln ("z:        playing paratrooper fx", origin);

		playfx( id, origin );
		wait( 30 + randomfloat( 40 ) );
	}
}

create_triggerfx()
{
	//assert (isdefined(self.looper));
	if( ! verify_effects_assignment( self.v[ "fxid" ] ) )
		return;
		
	self.looper = spawnFx( level._effect[ self.v[ "fxid" ] ], self.v[ "origin" ], self.v[ "forward" ], self.v[ "up" ] );
	triggerFx( self.looper, self.v[ "delay" ] );

	if ( !level.createFX_enabled )
		self.looper willNeverChange();

	create_loopsound();
}

verify_effects_assignment( effectID )
{
	if( isdefined ( level._effect[ effectID ] ) )
		return true;
	if( ! isdefined( level._missing_FX ) )
		level._missing_FX = [];
	level._missing_FX[ self.v[ "fxid" ] ] = effectID;
	verify_effects_assignment_print( effectID );
	return false;
}

verify_effects_assignment_print( effectID )
{
	
	level notify ( "verify_effects_assignment_print" );
	level endon ( "verify_effects_assignment_print" );
	wait .05; //allow errors on the same frame to que up before printing
	
	println("Error:");
	println("Error:**********MISSING EFFECTS IDS**********");
	keys = getarraykeys( level._missing_FX );
	foreach( key in keys )
	{
		println( "Error: Missing Effects ID assignment for: "+ key  );
	}
	println("Error:");
	
	assertmsg( "Missing Effects ID assignments ( see console )" );
}

OneShotfxthread()
{
	wait(0.05);

	if ( self.v[ "delay" ] > 0 )
		wait self.v[ "delay" ];

	[[ level.func[ "create_triggerfx" ] ]]();
}

//---------------------------------------------------------
// Reactive Section
//---------------------------------------------------------
CONST_MAX_REACTIVE_SOUND_ENTS = 4;
CONST_NEXT_PLAY_TIME = 3000;
add_reactive_fx()
{
	// MP should not start this thread in release
	if ( !isSP() && GetDVar( "createfx" ) == "" )
	{
		return;
	}

	if ( !IsDefined( level._fx.reactive_thread ) )
	{
		level._fx.reactive_thread = true;
		level thread reactive_fx_thread();
	}
	
	if ( !IsDefined( level._fx.reactive_fx_ents ) )
	{
		level._fx.reactive_fx_ents = [];
	}
	
	level._fx.reactive_fx_ents[ level._fx.reactive_fx_ents.size ] = self;
	self.next_reactive_time = 3000;
}

reactive_fx_thread()
{
	if ( !isSp() )
	{
		if ( GetDvar( "createfx" ) == "on" )
		{
			// wait till the player spawns and createfxlogic starts before continuing.
			flag_wait( "createfx_started" );
		}
	}

	// TODO: Switch to using level notify instead
	// HOWEVER!!! we will need the trigger_radius for when we are in CREATEFX mode for MP only!!!
	// use level.mp_createfx condition
//	trigger = Spawn( "trigger_radius", level.player.origin, 0, 5000, 5000 );
//	trigger SetCanDamage( true );
	
//	trigger EnableLinkTo();
//	trigger LinkTo( level.player );
	
	level._fx.reactive_sound_ents = [];
	
	explosion_radius = 256;

	while ( 1 )
	{
//		trigger waittill( "damage", dmg, attacker, dir_vec, point, type );
		level waittill( "code_damageradius", attacker, explosion_radius, point, weapon_name );

		ents = sort_reactive_ents( point, explosion_radius );

		foreach ( i, ent in ents )
			ent thread play_reactive_fx( i );
	}
}

vector2d( vec )
{
	return ( vec[ 0 ], vec[ 1 ], 0 );
}

sort_reactive_ents( point, explosion_radius )
{
	closest = [];
	time = GetTime();
	foreach ( ent in level._fx.reactive_fx_ents )
	{
		if ( ent.next_reactive_time > time )
			continue;
		
		radius_squared = ent.v[ "reactive_radius" ] + explosion_radius;
		radius_squared *= radius_squared;
		if ( DistanceSquared( point, ent.v[ "origin" ] ) < radius_squared )
		{
			closest[ closest.size ] = ent;			
		}
	}

	foreach ( ent in closest )
	{
		playerToEnt = vector2d( ent.v[ "origin" ] - level.player.origin );
		playerToPoint = vector2d( point - level.player.origin );
		vec1 = VectorNormalize( playerToEnt );
		vec2 = VectorNormalize( playerToPoint );
		ent.dot = VectorDot( vec1, vec2 );
	}

	// Sort from lowest dot to greatest
	for ( i = 0; i < closest.size - 1; i++ )
	{
		for ( j = i + 1; j < closest.size; j++ )
		{
			if ( closest[ i ].dot > closest[ j ].dot )
			{
				temp = closest[ i ];
				closest[ i ] = closest[ j ];
				closest[ j ] = temp;
			}
		}
	}
	
	// remove the .origin and .dot since we're done with sortbydistance()
	foreach ( ent in closest )
	{
		ent.origin = undefined;
		ent.dot = undefined;
	}
	
	// Make sure we only have 4
	for ( i = CONST_MAX_REACTIVE_SOUND_ENTS; i < closest.size; i++ )
	{
		closest[ i ] = undefined;
	}
	
	return closest;
}

play_reactive_fx( num )
{
	sound_ent = get_reactive_sound_ent();
	
	if ( !IsDefined( sound_ent ) )
		return;

/#
	self.is_playing = true;
#/

	self.next_reactive_time = GeTTime() + CONST_NEXT_PLAY_TIME;
	sound_ent.origin = self.v[ "origin" ];
	sound_ent.is_playing = true;
	
	wait( num * RandomFloatRange( 0.05, 0.1 ) );
	
	if ( isSP() )
	{
		sound_ent PlaySound( self.v[ "soundalias" ], "sounddone" );
		sound_ent waittill( "sounddone" );
	}
	else
	{
		sound_ent PlaySound( self.v[ "soundalias" ] );
		wait( 2 );
	}
	
	// wait for sounddone to be removed compeletely
	// bug in prague port to iw6 where in the same frame this got called again after the sounddone notify
	// odd thing, even 0.05 doesn't work. Code should fix this!
	wait( 0.1 );
	sound_ent.is_playing = false;

/#
	self.is_playing = undefined;
#/
}

get_reactive_sound_ent()
{
	foreach ( ent in level._fx.reactive_sound_ents )
	{
		if ( !ent.is_playing )
			return ent;
	}

	if ( level._fx.reactive_sound_ents.size < CONST_MAX_REACTIVE_SOUND_ENTS )
	{
		ent = Spawn( "script_origin", ( 0, 0, 0 ) );
		ent.is_playing = false;

		level._fx.reactive_sound_ents[ level._fx.reactive_sound_ents.size ] = ent;

		return ent;
	}

	return undefined;
}