#include common_scripts\utility;

FLARES_POP_SOUND_NPC = "veh_helo_flares_npc";
FLARES_POP_SOUND_PLR = "veh_helo_flares_plr";

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Flare Init and Deployment
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

flares_monitor( flareCount ) // self == vehicle
{
	self.flaresReserveCount = flareCount;
	self.flaresLive = [];
	
	self thread ks_laserGuidedMissile_handleIncoming();
	
	// We no longer have fire and forget launchers.
//	self thread flares_handleIncomingSAM();
//	self thread flares_handleIncomingStinger();
}

flares_playFx() // self == vehicle
{
	for ( i = 0; i < 10; i++ )
	{
		if ( !IsDefined( self ) )
			return;
		
		PlayFXOnTag( level._effect[ "vehicle_flares" ], self, "TAG_FLARE" );
		
		wait ( 0.15 );
	}
}

flares_deploy() // self == missile target
{
	flare = spawn( "script_origin", self.origin + ( 0, 0, -256 ) );
	flare.angles = self.angles;

	flare MoveGravity( (0, 0, -1), 5.0 );
	
	self.flaresLive[ self.flaresLive.size ] = flare;
	
	flare thread flares_deleteAfterTime( 5.0, 2.0, self );

	playSoundAtPos( flare.origin, FLARES_POP_SOUND_NPC );
	
	return flare;
}

flares_deleteAfterTime( delayDelete, delayStopTracking, vehicle )
{
	AssertEx( !IsDefined( delayStopTracking ) || delayStopTracking < delayDelete, "flares_deleteAfterTime() delayDelete should never be greater than delayStopTracking." );
	
	if ( IsDefined( delayStopTracking ) && IsDefined( vehicle ) )
	{
		delayDelete -= delayStopTracking;
		wait( delayStopTracking );
		
		if( IsDefined( vehicle ) )
			vehicle.flaresLive = array_remove( vehicle.flaresLive, self );
	}
	
	wait( delayDelete );
	
	self Delete();
}

flares_getNumLeft( vehicle )
{
	return vehicle.flaresReserveCount;
}

flares_areAvailable( vehicle )
{
	flares_cleanFlaresLiveArray( vehicle );
	return vehicle.flaresReserveCount > 0 || vehicle.flaresLive.size > 0;
}

flares_getFlareReserve( vehicle )
{
	AssertEx( vehicle.flaresReserveCount > 0, "flares_getFlareReserve() called on vehicle without any flares in reserve." );
	
	vehicle.flaresReserveCount--;		
	
	vehicle thread flares_playFx();	
	flare = vehicle flares_deploy();
	
	return flare;
}

flares_cleanFlaresLiveArray( vehicle )
{
	vehicle.flaresLive = array_removeUndefined( vehicle.flaresLive );
}

flares_getFlareLive( vehicle )
{
	flares_cleanFlaresLiveArray( vehicle );
	
	flare = undefined;
	if ( vehicle.flaresLive.size > 0 )
	{
		flare = vehicle.flaresLive[ vehicle.flaresLive.size - 1 ];
	}
	return flare;
}

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Missile Incoming Logic
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

ks_laserGuidedMissile_handleIncoming() //self == vehicle
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "leaving" );
	self endon( "helicopter_done" );
	
	while ( flares_areAvailable( self ) )
	{
		level waittill( "laserGuidedMissiles_incoming", player, missiles, target );
		
		if ( !IsDefined( target ) || target != self )
			continue;
		
		foreach ( missile in missiles )
		{
			if ( IsValidMissile( missile ) )
			{
				level thread ks_laserGuidedMissile_monitorProximity( missile, player, player.team, target );
			}
		}
	}
}

ks_laserGuidedMissile_monitorProximity( missile, player, team, target )
{
	target endon( "death" );
	missile endon( "death" );
	missile endon( "missile_targetChanged" );
	
	while ( flares_areAvailable( target ) )
	{
		if ( !IsDefined( target ) || !IsValidMissile( missile ) )
			break;
		
		center = target GetPointInBounds( 0, 0, 0 );
		
		if ( DistanceSquared( missile.origin, center ) < 4000000 ) // 2000 * 2000
		{
			flare = flares_getFlareLive( target );
			if ( !IsDefined( flare ) )
			{
				flare = flares_getFlareReserve( target );
			}
			
			missile Missile_SetTargetEnt( flare );
			missile notify( "missile_pairedWithFlare" );
			
			break;
		}
		
		waitframe();
	}
}

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Old Missile Incoming Logic
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

flares_handleIncomingSAM( functionOverride )
{
	level endon ( "game_ended" );
	self endon ( "death" );
	self endon ( "crashing" );
	self endon ( "leaving" );
	self endon ( "helicopter_done" );	

	for ( ;; )
	{
		level waittill ( "sam_fired", player, missileGroup, lockTarget );

		if ( !IsDefined( lockTarget ) || ( lockTarget != self ) )
			continue;

		if( IsDefined( functionOverride ) )
			level thread [[ functionOverride ]]( player, player.team, lockTarget, missileGroup );
		else
			level thread flares_watchSAMProximity( player, player.team, lockTarget, missileGroup );
	}
}

flares_watchSAMProximity( player, missileTeam, missileTarget, missileGroup ) // self == level
{
	level endon ( "game_ended" );
	missileTarget endon( "death" );

	while( true )
	{
		center = missileTarget GetPointInBounds( 0, 0, 0 );

		curDist = [];
		for( i = 0; i < missileGroup.size; i++ )
		{
			if( IsDefined( missileGroup[ i ] ) )
				curDist[ i ] = distance( missileGroup[ i ].origin, center );
		}

		for( i = 0; i < curDist.size; i++ )
		{
			if( IsDefined( curDist[ i ] ) )
			{
				if ( curDist[ i ] < 4000 && missileTarget.flaresReserveCount > 0 )
				{
					missileTarget.flaresReserveCount--;			

					missileTarget thread flares_playFx();	
					newTarget = missileTarget flares_deploy();
					for( j = 0; j < missileGroup.size; j++ )					
					{
						if( IsDefined( missileGroup[ j ] ) )
						{
							missileGroup[ j ] Missile_SetTargetEnt( newTarget );
							missileGroup[ j ] notify( "missile_pairedWithFlare" );
						}
					}
					return;
				}	
			}
		}
		wait ( 0.05 );
	}	
}

flares_handleIncomingStinger( functionOverride )
{
	level endon ( "game_ended" );
	self endon ( "death" );
	self endon ( "crashing" );
	self endon ( "leaving" );
	self endon ( "helicopter_done" );	

	for ( ;; )
	{
		level waittill ( "stinger_fired", player, missile, lockTarget );
		
		if ( !IsDefined( lockTarget ) || (lockTarget != self) )
			continue;
		
		if( IsDefined( functionOverride ) )
			missile thread [[ functionOverride ]]( player, player.team, lockTarget );
		else
			missile thread flares_watchStingerProximity( player, player.team, lockTarget );
	}	
}

flares_watchStingerProximity( player, missileTeam, missileTarget ) // self == missile
{
	self endon ( "death" );

	while( true )
	{
		if ( !isDefined( missileTarget ) )
			break;
			
		center = missileTarget GetPointInBounds( 0, 0, 0 );

		curDist = distance( self.origin, center );

		if ( curDist < 4000 && missileTarget.flaresReserveCount > 0 )
		{
			missileTarget.flaresReserveCount--;			

			missileTarget thread flares_playFx();	
			newTarget = missileTarget flares_deploy();
			self Missile_SetTargetEnt( newTarget );
			self notify( "missile_pairedWithFlare" );
			return;
		}		
		wait ( 0.05 );
	}	
}

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Manual Flares and Missile Incoming Logic
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

ks_setup_manual_flares( num_flares, button_action, flares_omnvar_name, incoming_omnvar_name ) // self == vehicle
{
	self.flaresReserveCount = num_flares;
	self.flaresLive = [];
	
	if( IsDefined( flares_omnvar_name ) )
		self.owner SetClientOmnvar( flares_omnvar_name, num_flares );

	self thread ks_manualFlares_watchUse( button_action, flares_omnvar_name );
	self thread ks_manualFlares_handleIncoming( incoming_omnvar_name );
}

ks_manualFlares_watchUse( button_action, omnvar_name ) // self == vehicle
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "leaving" );
	self endon( "helicopter_done" );
	
	if ( !IsAI(self.owner) )	// Bots handle this internally
		self.owner NotifyOnPlayerCommand( "manual_flare_popped", button_action );
	
	while( flares_getNumLeft( self ) )
	{
		self.owner waittill( "manual_flare_popped" );
		
		flare = flares_getFlareReserve( self );
		if( IsDefined( flare ) && IsDefined( self.owner ) && !IsAI( self.owner ) )
		{
			self.owner PlayLocalSound( FLARES_POP_SOUND_PLR );
			if( IsDefined( omnvar_name ) )
				self.owner SetClientOmnvar( omnvar_name, self flares_getNumLeft( self ) );
		}
	}
}

ks_manualFlares_handleIncoming( omnvar_name ) // self == vehicle
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "leaving" );
	self endon( "helicopter_done" );
	
	while( flares_areAvailable( self ) )
	{
		self waittill( "targeted_by_incoming_missile", missiles );
		
		if( !IsDefined( missiles ) )
			continue;
		
		self.owner PlayLocalSound( "missile_incoming" );
		self.owner thread ks_watch_death_stop_sound( self, "missile_incoming" );
		
		if( IsDefined( omnvar_name ) )
		{
			// 1 for center, 2 right, 3 left
			// just check the first missile because the others won't matter at this point
			vec_to_target = VectorNormalize( missiles[ 0 ].origin - self.origin );
			vec_to_right = VectorNormalize( AnglesToRight( self.angles ) );
			vec_dot = VectorDot( vec_to_target, vec_to_right );
			dir_index = 1;
			if( vec_dot > 0 )
				dir_index = 2;
			else if( vec_dot < 0 )
				dir_index = 3;
			self.owner SetClientOmnvar( omnvar_name, dir_index );
		}
		
		foreach( missile in missiles )
		{
			if( IsValidMissile( missile ) )
			{
				self thread ks_manualFlares_monitorProximity( missile );
			}
		}
	}
}

ks_manualFlares_monitorProximity( missile ) // self == vehicle
{
	self endon( "death" );
	missile endon( "death" );
	
	while( true )
	{
		if ( !IsDefined( self ) || !IsValidMissile( missile ) )
			break;
		
		center = self GetPointInBounds( 0, 0, 0 );
		
		if( DistanceSquared( missile.origin, center ) < 4000000 ) // 2000 * 2000
		{
			flare = flares_getFlareLive( self );
			if( IsDefined( flare ) )
			{
				missile Missile_SetTargetEnt( flare );
				missile notify( "missile_pairedWithFlare" );
				self.owner StopLocalSound( "missile_incoming" );
				break;
			}			
		}
		
		waitframe();
	}
}

ks_watch_death_stop_sound( vehicle, sound ) // self == player
{
	self endon( "disconnect" );
	
	vehicle waittill( "death" );
	self StopLocalSound( sound );
}
