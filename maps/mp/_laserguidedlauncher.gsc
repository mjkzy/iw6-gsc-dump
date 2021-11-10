#include maps\mp\_utility;
#include common_scripts\utility;

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Init
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

CONST_LOCK_ON_TIME_MSEC = 1500;

LGM_init( fxSplit, fxHoming )
{
	level._effect[ "laser_guided_launcher_missile_split" ] = LoadFX( fxSplit );
	level._effect[ "laser_guided_launcher_missile_spawn_homing" ] = LoadFX( fxHoming );
}

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Monitor Player Weapon for Use as CAC Launcher
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

// Function to use if you want to have a laser guided launcher as
// a launcher in CAC. Just thread this watch off in _weapons.gsc::init()
LGM_update_launcherUsage( weaponName, weaponNameHoming )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "faux_spawn" );
	
	self thread LGM_monitorLaser();
	
	weaponCurr = self GetCurrentWeapon();
	while ( 1 )
	{
		while ( weaponCurr != weaponName )
		{
			self waittill( "weapon_change", weaponCurr );
		}
		
		self childthread LGM_firing_monitorMissileFire( weaponCurr, weaponNameHoming );
		
		self waittill( "weapon_change", weaponCurr );
		
		self LGM_firing_endMissileFire();
	}
}

LGM_monitorLaser()
{
	self endon( "LGM_player_endMonitorFire" );
	
	self waittill_any( "death", "disconnect" );
	
	if ( IsDefined( self ) )
	{
		self LGM_disableLaser();
	}
}

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Monitor Player Firing
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

LASER_GUIDED_MISSILE_LASER_TRACE_CLOSE_TIME_MSEC = 400; // Time after firing that the trace distance is short. This forces the missiles forward.
LASER_GUIDED_MISSILE_LASER_TRACE_LENGTH_SHORT	 = 800;
LASER_GUIDED_MISSILE_LASER_TRACE_LENGTH			 = 8000;
LASER_GUIDED_MISSILE_DELAY_CHILDREN_SPAWN		 = 0.35;
LASER_GUIDED_MISSILE_DELAY_CHILDREN_TRACK		 = 0.1;
LASER_GUIDED_MISSILE_PITCH_CHILDREN_DIVERGE		 = 20;
LASER_GUIDED_MISSILE_YAW_CHILDREN_DIVERGE		 = 20;

LGM_firing_endMissileFire()
{
	self LGM_disableLaser();
	
	self notify( "LGM_player_endMonitorFire" );
}

LGM_firing_monitorMissileFire( weaponName, weaponNameChild, weaponNameHoming )
{
	self endon( "LGM_player_endMonitorFire" );

	self LGM_enableLaser();
	
	entTarget = undefined;
	
	while ( 1 )
	{
		missile = undefined;
		self waittill( "missile_fire", missile, weaponNotified );
		
		// Ignore missiles fired by script
		if ( IsDefined( missile.isMagicBullet ) && missile.isMagicBullet )
			continue;
		
		// The hind magic bullets missiles on behalf of the player, so ignore without assert.
		if ( weaponNotified != weaponName )
			continue;
		
		if ( !IsDefined( entTarget ) )
		{
			entTarget = LGM_requestMissileGuideEnt( self );
		}
		
		self thread LGM_firing_delaySpawnChildren( weaponName, weaponNameChild, weaponNameHoming, LASER_GUIDED_MISSILE_DELAY_CHILDREN_SPAWN, LASER_GUIDED_MISSILE_DELAY_CHILDREN_TRACK, missile, entTarget );
	}
}

LGM_firing_delaySpawnChildren( weaponName, weaponNameChild, weaponNameHoming, delaySpawn, delayTrack, missile, entTarget )
{
	// If the player fires rapidly, cancel the previous missile spawn
	self notify( "monitor_laserGuidedMissile_delaySpawnChildren" );
	self endon( "monitor_laserGuidedMissile_delaySpawnChildren" );
	
	// If the player dies this function needs to be cleared up immediately. This is because
	// the target ent gets scrubbed on death so any created missiles may have been 
	// removed from the array
	self endon( "death" );
	self endon( "LGM_player_endMonitorFire" );
	
	// Only let one set of rockets be guided by releasing
	// any previously fired rockets
	LGM_missilesNotifyAndRelease( entTarget );
	
	wait( delaySpawn );
	
	// Exit if missile has blown up
	if ( !IsValidMissile( missile ) )
		return;
	
	missileOrigin = missile.origin;
	missileFwd	  = AnglesToForward( missile.angles );
	missileUp	  = AnglesToUp( missile.angles );
	missileRight  = AnglesToRight( missile.angles );
	
	missile Delete();
	
	// Spawn missile break apart fx
	PlayFX( level._effect[ "laser_guided_launcher_missile_split" ], missileOrigin, missileFwd, missileUp );
	
	missiles = [];
	
	for ( i = 0; i < 2; i++ )
	{
		pitch = LASER_GUIDED_MISSILE_PITCH_CHILDREN_DIVERGE; // Default Upwards Pitch: Forward and Up n degrees
		yaw = 0;
		
		if ( i == 0 ) // Right Missile: Up 45 degrees and then 45 degrees around Z
		{
			yaw = LASER_GUIDED_MISSILE_YAW_CHILDREN_DIVERGE;
		}
		else if ( i == 1 ) // Left Missile: Up 45 degrees and then -45 degrees around Z
		{
			yaw = -1 * LASER_GUIDED_MISSILE_YAW_CHILDREN_DIVERGE;
		}
		else if ( i == 2 )// Middle Missile: Already rotated up
		{
			// All done
		}
		
		childMissileFwd = RotatePointAroundVector( missileRight, missileFwd, pitch );
		childMissileFwd = RotatePointAroundVector( missileUp, childMissileFwd, yaw );
		
		missileChild = MagicBullet( weaponNameChild, missileOrigin, missileOrigin + childMissileFwd * 180, self );
		missileChild.isMagicBullet = true;
		missiles[ missiles.size ] = missileChild;
		
		// Don't spawn missiles on the same frame
		waitframe();
	}
	
	wait( delayTrack );
	
	missiles = LGM_removeInvalidMissiles( missiles );
	
	if ( missiles.size > 0 )
	{
		foreach ( missChild in missiles )
		{
			entTarget.missilesChasing[ entTarget.missilesChasing.size ] = missChild;
			missChild Missile_SetTargetEnt( entTarget );
			
			self thread LGM_onMissileNotifies( entTarget, missChild );
		}
		
		self thread LGM_firing_monitorPlayerAim( entTarget, weaponNameHoming );
	}
}

LGM_onMissileNotifies( entTarget, missile )
{
	missile waittill_any( "death", "missile_pairedWithFlare", "LGM_missile_abandoned" );
	
	if ( IsDefined( entTarget.missilesChasing ) && entTarget.missilesChasing.size > 0 )
	{
		entTarget.missilesChasing = array_remove( entTarget.missilesChasing, missile );
		entTarget.missilesChasing = LGM_removeInvalidMissiles( entTarget.missilesChasing );
	}
	
	if ( !IsDefined( entTarget.missilesChasing ) || entTarget.missilesChasing.size == 0 )
	{
		self notify( "LGM_player_allMissilesDestroyed" );
	}
}

// Handles initial lock visual / audio fx

LGM_firing_monitorPlayerAim( entTarget, weaponNameHoming )
{
	self notify( "LGM_player_newMissilesFired" );
	self endon( "LGM_player_newMissilesFired" );
	
	self endon( "LGM_player_allMissilesDestroyed" );
	self endon( "LGM_player_endMonitorFire" );
	self endon( "death" );
	self endon( "disconnect" );
	
	originGoal	 = undefined;
	targetVeh	 = undefined;
	lockOnTime	 = undefined;
	lockedOn	 = false;
	
	timeTraceFar = GetTime() + LASER_GUIDED_MISSILE_LASER_TRACE_CLOSE_TIME_MSEC;
	
	while ( IsDefined( entTarget.missilesChasing ) && entTarget.missilesChasing.size > 0 )
	{
		targetLook = self LGM_targetFind();
		
		if ( !IsDefined( targetLook ) )
		{
			// If there was a previous target, clear that target and
			// notify systmes watching the missiles that the
			// target has changed
			if ( IsDefined( targetVeh ) )
			{
				self notify( "LGM_player_targetLost" );
				targetVeh = undefined;
				
				foreach ( missile in entTarget.missilesChasing )
				{
					missile notify( "missile_targetChanged" );
				}
			}
			
			lockOnTime = undefined;
			lockedOn   = false;
			
			traceDist = ter_op( GetTime() > timeTraceFar, LASER_GUIDED_MISSILE_LASER_TRACE_LENGTH, LASER_GUIDED_MISSILE_LASER_TRACE_LENGTH_SHORT );
			viewDir = AnglesToForward( self GetPlayerAngles() );
			startPos = self GetEye() + viewDir * 12;
			trace = BulletTrace( startPos, startPos + viewDir * traceDist, true, self, false, false, false );
			
			originGoal = trace[ "position" ];
		}
		else
		{
			originGoal = targetLook.origin;
			
			newTarget = !IsDefined( targetVeh ) || targetLook != targetVeh;
			targetVeh = targetLook;
			
			if ( newTarget || !IsDefined( lockOnTime ) )
			{
				lockOnTime = GetTime() + CONST_LOCK_ON_TIME_MSEC;
				level thread LGM_locking_think( targetVeh, self );
			}
			else if ( GetTime() >= lockOnTime )
			{
				// incoming notify was fired as soon as the player looked at
				// the target
				lockedOn = true;
				self notify( "LGM_player_lockedOn" );
			}
			
			if ( lockedOn )
			{
				// In case the current live missiles are paired with flares
				// this script update wait untill after they're removed
				// from missilesChasing
				waittillframeend;
				
				if ( entTarget.missilesChasing.size > 0 )
				{
					missileOrigins = [];
					
					foreach ( missile in entTarget.missilesChasing )
					{
						if ( !IsValidMissile( missile ) )
							continue;
						
						missileOrigins[ missileOrigins.size ] = missile.origin;
						
						missile notify( "missile_targetChanged" );
						missile notify( "LGM_missile_abandoned" );
						missile Delete();
					}
					
					if ( missileOrigins.size > 0 )
					{
						level thread LGM_locked_think( targetVeh, self, weaponNameHoming, missileOrigins );
					}
					
					entTarget.missilesChasing = [];
				}
				else
				{
					// All missiles were removed during the waittillframeend
					break;
				}
			}
			else if ( newTarget )
			{
				LGM_targetNotifyMissiles( targetVeh, self, entTarget.missilesChasing );
			}
		}
		
		entTarget.origin = originGoal;
		
		waitframe();
	}
}

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Monitor LaserGuided Missile Ent Pool
//	- Prevent too many ents being created
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

TARGET_ENT_COUNT_PREFERRED_MAX	= 4;	// The pool of target ents can get larger than this but should shrink back down when less are needed.

LGM_requestMissileGuideEnt( player )
{
	if ( !IsDefined( level.laserGuidedMissileEnts_inUse ) )
	{
		level.laserGuidedMissileEnts_inUse = [];
	}
	
	if ( !IsDefined( level.laserGuidedMissileEnts_ready ) )
	{
		level.laserGuidedMissileEnts_ready = [];
	}
	
	ent = undefined;
	
	if ( level.laserGuidedMissileEnts_ready.size )
	{
		ent = level.laserGuidedMissileEnts_ready[ 0 ];
		level.laserGuidedMissileEnts_ready = array_remove( level.laserGuidedMissileEnts_ready, ent );
	}
	else
	{
		ent = spawn( "script_origin", player.origin );
	}
	
	level.laserGuidedMissileEnts_inUse[ level.laserGuidedMissileEnts_inUse.size ] = ent;
	
	level thread LGM_monitorLaserEntCleanUp( ent, player );
	
	ent.missilesChasing = [];
	
	return ent;
}

LGM_monitorLaserEntCleanUp( entTarget, player )
{
	player waittill_any( "death", "disconnect", "LGM_player_endMonitorFire" );
	
	AssertEx( array_contains( level.laserGuidedMissileEnts_inUse, entTarget ), "LGM_monitorLaserEntCleanUp() attempting to clean up laser target ent not currently in use." );
	
	// Scrub ent clean
	AssertEx( IsDefined( entTarget.missilesChasing ) && IsArray( entTarget.missilesChasing ), "LGM_monitorLaserEntCleanUp() given missile ent with now missile array." );
	foreach ( missile in entTarget.missilesChasing )
	{
		if ( IsValidMissile( missile ) )
		{
			missile Missile_ClearTarget();
		}
	}
	
	entTarget.missilesChasing = undefined;
	
	// Move ent fron in use to ready array
	level.laserGuidedMissileEnts_inUse = array_remove( level.laserGuidedMissileEnts_inUse, entTarget );
	
	// If the too many ents exist delete it, otherwise add it to ready array
	if ( level.laserGuidedMissileEnts_ready.size + level.laserGuidedMissileEnts_inUse.size < TARGET_ENT_COUNT_PREFERRED_MAX )
	{
		level.laserGuidedMissileEnts_ready[ level.laserGuidedMissileEnts_ready.size ] = entTarget;
	}
	else
	{
		entTarget Delete();
	}
}

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// Monitor Locking and Locked On
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

LGM_locking_think( targetVeh, player )
{
	AssertEx( IsDefined( player ), "LGM_locking_think called with undefined player." );
	
	outline = outlineEnableForPlayer( targetVeh, "orange", player, true, "killstreak_personal" );
	
	level thread LGM_locking_loopSound( player, "maaws_reticle_tracking", 1.5, "LGM_player_lockingDone" );
	level thread LGM_locking_notifyOnTargetDeath( targetVeh, player );
	
	player waittill_any(
							"death",								// targetting player died
							"disconnect",							// targetting player left game
						  	"LGM_player_endMonitorFire",			// ks system stopped launcher logic
						  	"LGM_player_newMissilesFired",			// player fired again, these missiles are going to be abandoned
						  	"LGM_player_targetLost",				// player looked away or new enemy came into view during lock on
						  	"LGM_player_lockedOn",					// player obtained full lock, this outlin is removed, a new outlin call is made
						  	"LGM_player_allMissilesDestroyed",		// the current set of tracked missiles all died or were paired with flares
						  	"LGM_player_targetDied"					// target destroyed
					  );
	
	// Some entities delete instantly on death and may
	// be removed at this point
	if ( IsDefined( targetVeh ) )
	{
		outlineDisable( outline, targetVeh );
	}
	
	if ( IsDefined( player ) )
	{
		player notify( "LGM_player_lockingDone" );
		
		player StopLocalSound( "maaws_reticle_tracking" );
	}
}

LGM_locked_missileOnDeath( missile, targetVeh, groupID )
{
	targetVeh endon( "death" );
	
	missile waittill( "death" );
	
	targetVeh.LG_missilesLocked[ groupID ] = array_remove( targetVeh.LG_missilesLocked[ groupID ], missile );
	
	if ( targetVeh.LG_missilesLocked[ groupID ].size == 0 )
	{
		targetVeh.LG_missilesLocked[ groupID ] = undefined;
		targetVeh notify( "LGM_target_lockedMissilesDestroyed" );
	}
}

LGM_locking_notifyOnTargetDeath( target, player )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "LGM_player_lockingDone" );
	
	target waittill( "death" );
	
	player notify( "LGM_player_targetDied" );
}

LGM_locking_loopSound( player, sound, time, endonPlayer )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( endOnPlayer );
	
	while ( 1 )
	{
		player PlayLocalSound( sound );
		wait( time );
	}
}

LGM_locked_spawnMissiles( target, player, weaponNameHoming, missileOrigins )
{
	target endon( "death" );
	player endon( "death" );
	player endon( "disconnect" );
	
	missilesLocked = [];
	
	for ( i = 0; i < missileOrigins.size; i++ )
	{
		missileChild = MagicBullet( weaponNameHoming, missileOrigins[ i ], target.origin, player );
		missileChild.isMagicBullet = true;
		missilesLocked[ missilesLocked.size ] = missileChild;
		
		PlayFX( level._effect[ "laser_guided_launcher_missile_spawn_homing" ], missileChild.origin, AnglesToForward( missileChild.angles ), AnglesToUp( missileChild.angles ) );
		
		// Don't spawn missiles on the same frame
		waitframe();
	}
	
	return missilesLocked;
}

// Handles locked on visual / audio fx
LGM_locked_think( targetVeh, player, weaponNameHoming, missileOrigins )
{
	AssertEx( missileOrigins.size > 0, "LGM_locked_think() passed empty missile origin array." );
	
	if ( missileOrigins.size == 0 )
		return;
	
	missilesLocked = LGM_locked_spawnMissiles( targetVeh, player, weaponNameHoming, missileOrigins );
	
	// If undefined the player died or the target died
	if ( !IsDefined( missilesLocked ) )
		return;
	
	// In case a missile died after the above wait frame
	missilesLocked = LGM_removeInvalidMissiles( missilesLocked );
	if ( missilesLocked.size == 0 )
		return;
	
	// Visual and audio fx
	player PlayLocalSound( "maaws_reticle_locked" );
	outlineID = outlineEnableForPlayer( targetVeh, "red", player, false, "killstreak_personal" );
	
	// Give missiles their target with an offset
	targetOffset = LGM_getTargetOffset( targetVeh );
	
	foreach ( mChild in missilesLocked )
	{
		mChild missile_setTargetAndFlightMode( targetVeh, "direct", targetOffset );
		
		LGM_targetNotifyMissiles( targetVeh, player, missilesLocked );
	}
	
	if ( !IsDefined( targetVeh.LG_missilesLocked ) )
	{
		targetVeh.LG_missilesLocked = [];
	}
	
	// Because multiple sets of missiles from the same or different players
	// can be tracking the helicopter at the same timed, add the missiles
	// to an array by the unique outline ID
	targetVeh.LG_missilesLocked[ outlineID ] = missilesLocked;
	
	foreach ( vMiss in missilesLocked )
	{
		level thread LGM_locked_missileOnDeath( vMiss, targetVeh, outlineID );
	}
	
	outlineOn = true;
	while ( outlineOn )
	{
		msg = targetVeh waittill_any_return( "death", "LGM_target_lockedMissilesDestroyed" );
		
		if ( msg == "death" )
		{
			outlineOn = false;
			if ( IsDefined( targetVeh ) )
			{
				targetVeh.LG_missilesLocked[ outlineID ] = undefined;
			}
		}
		else if ( msg == "LGM_target_lockedMissilesDestroyed" )
		{
			// Two sets of missiles could potentially throw the "LGM_target_lockedMissilesDestroyed"
			// notification on the same frame. Wait until frame end and then check to see if this
			// outline's missiles are all gone
			waittillframeend;
			
			if ( !IsDefined( targetVeh.LG_missilesLocked[ outlineID ] ) || targetVeh.LG_missilesLocked[ outlineID ].size == 0 )
			{
				outlineOn = false;
			}
		}
	}
	
	// Targetveh may be deleted at this point
	if ( IsDefined( targetVeh ) )
	{
		outlineDisable( outlineID, targetVeh );
	}
}

LGM_targetFind()
{
	targets = self maps\mp\gametypes\_weapons::lockOnLaunchers_getTargetArray();
	targets = SortByDistance( targets, self.origin );
	
	targetLook = undefined;
	foreach ( target in targets )
	{
		if ( self WorldPointInReticle_Circle( target.origin, 65, 75 ) )
		{
			targetLook = target;
			break;
		}
	}
	
	return targetLook;
}

// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //
// LaserGuided Missile Utils
// -.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-.-. //

LGM_enableLaser()
{
	if ( !IsDefined( self.laserGuidedLauncher_laserOn ) || self.laserGuidedLauncher_laserOn == false )
	{
		self.laserGuidedLauncher_laserOn = true;
		self enableWeaponLaser();
	}
}

LGM_disableLaser()
{
	if ( IsDefined( self.laserGuidedLauncher_laserOn ) && self.laserGuidedLauncher_laserOn == true )
	{
		self disableWeaponLaser();
	}
	
	self.laserGuidedLauncher_laserOn = undefined;
}

LGM_removeInvalidMissiles( missiles )
{
	valid = [];
	foreach ( m in missiles )
	{
		if ( IsValidMissile( m ) )
		{
			valid[ valid.size ] = m;
		}
	}
	return valid;
}

LGM_targetNotifyMissiles( targetVeh, attacker, missiles )
{
	// General notifies to other systems to handle incoming missiles
	level notify( "laserGuidedMissiles_incoming", attacker, missiles, targetVeh );
	targetVeh notify( "targeted_by_incoming_missile", missiles );
}

LGM_getTargetOffset( target )
{
	targetPoint = undefined;
	//AH: HACK: The harrier doesn't have the tag_missile_target, but it does have a tag_body.
	//			The code works fine without this check, but GetTagOrigin throws an SRE if the tag does not exist.
	if ( target.model != "vehicle_av8b_harrier_jet_mp" )
		targetPoint = target GetTagOrigin( "tag_missile_target" );
	else
		targetPoint = target GetTagOrigin( "tag_body" );
	
	if ( !IsDefined( targetPoint ) )
	{
		targetPoint = target GetPointInBounds( 0, 0, 0 );
		AssertMsg( "LGM_getTargetOffset() failed to find tag_missile_target on entity." + target.classname );
	}
	
	return targetPoint - target.origin;
}

LGM_missilesNotifyAndRelease( entTarget )
{
	if ( IsDefined( entTarget.missilesChasing ) && entTarget.missilesChasing.size > 0 )
	{
		foreach ( missChasing in entTarget.missilesChasing )
		{
			if ( IsValidMissile( missChasing ) )
			{
				// Let systems watching incoming missiles know the
				// target has changed
				missChasing notify( "missile_targetChanged" );
				missChasing notify( "LGM_missile_abandoned" );
				missChasing Missile_ClearTarget();
			}
		}
	}
	
	entTarget.missilesChasing = [];
}
