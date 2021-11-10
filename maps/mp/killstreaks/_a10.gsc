#include maps\mp\_utility;
#include common_scripts\utility;

/*
	A10 killstreak: the player uses the mini-map selector to select a place to strafe
*/
KS_NAME = "a10_strafe";
kTransitionTime = 0.75;
kLockIconOffset = (0, 0, -70);
init()
{
	precacheLocationSelector( "map_artillery_selector" );
	
	config = SpawnStruct();
	config.modelNames = [];
	config.modelNames[ "allies" ] = "vehicle_a10_warthog_iw6_mp";
	config.modelNames[ "axis" ] = "vehicle_a10_warthog_iw6_mp";
	config.vehicle = "a10_warthog_mp";
	config.inboundSfx = "veh_mig29_dist_loop";
	//config.inboundSfx = "veh_aastrike_flyover_loop";
	//config.outboundSfx = "veh_aastrike_flyover_outgoing_loop";
	//config.compassIconFriendly = "compass_objpoint_a10_friendly";
	//config.compassIconEnemy = "compass_objpoint_a10_enemy";
	// sonic boom?
	config.speed = 3000;
	config.halfDistance = 12500;
	config.heightRange = 750;
	config.chooseDirection = true;
	config.selectLocationVO = "KS_hqr_airstrike";
	config.inboundVO = "KS_ast_inbound";
	
	config.cannonFireVfx = LoadFX( "fx/smoke/smoke_trail_white_heli" );
	config.cannonRumble = "ac130_25mm_fire";
	config.turretName = "a10_30mm_turret_mp";
	config.turretAttachPoint = "tag_barrel";
	config.rocketModelName = "maverick_projectile_mp";
	config.numRockets = 4;
	config.delayBetweenRockets = 0.125;
	config.delayBetweenLockon = 0.4;
	config.lockonIcon = "veh_hud_target_chopperfly";	//  "veh_hud_target_lock"
	
	config.maxHealth = 1000;
	config.xpPopup = "destroyed_a10_strafe";
	config.callout = "callout_destroyed_a10";
	config.voDestroyed = undefined;
	config.explodeVfx = LoadFX( "fx/explosions/aerial_explosion");
	
	// holy crap, lots of sfx
	config.sfxCannonFireLoop_1p = "veh_a10_plr_fire_gatling_lp";
	config.sfxCannonFireStop_1p = "veh_a10_plr_fire_gatling_cooldown";
	config.sfxCannonFireLoop_3p = "veh_a10_npc_fire_gatling_lp";
	config.sfxCannonFireStop_3p = "veh_a10_npc_fire_gatling_cooldown";
	config.sfxCannonFireBurpTime = 500;
	config.sfxCannonFireBurpShort_3p = "veh_a10_npc_fire_gatling_short_burst";
	config.sfxCannonFireBurpLong_3p = "veh_a10_npc_fire_gatling_long_burst";
	config.sfxCannonBulletImpact = "veh_a10_bullet_impact_lp";	// loop, should play on moving entity
	
	config.sfxMissileFire_1p = [];
	config.sfxMissileFire_1p[0] = "veh_a10_plr_missile_ignition_left";
	config.sfxMissileFire_1p[1] = "veh_a10_plr_missile_ignition_right";
	config.sfxMissileFire_3p = "veh_a10_npc_missile_fire";
	config.sfxMissile = "veh_a10_missile_loop";
	
	config.sfxEngine_1p = "veh_a10_plr_engine_lp";
	config.sfxEngine_3p = "veh_a10_dist_loop";
	
	level.planeConfigs[ KS_NAME ] = config;
	
	level.killstreakFuncs[KS_NAME] = ::onUse;
	
	/* 
 	a10 sounds
	a10p_gatling_loop
	a10p_gatling_tail
	a10p_missile_launch
	a10p_impact
	*/

	buildAllFlightPathsDefault();
}

onUse( lifeId, streakName )
{
	assert( isDefined( self ) );
		
	if ( IsDefined( level.a10strafeActive ) )
	{
		self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}
	else if ( self isUsingRemote()
			 || self isKillStreakDenied()
			)
	{
		return false;
	}
	else if ( GetCSplineCount() < 2 )
	{
		PrintLn( "ERROR: need at least two CSpline paths for A10 strafing run. Please add them to your level." );
		return false;
	}
	else
	{
		self thread doStrike( lifeId, KS_NAME );
		
		return true;
	}
}

doStrike( lifeId, streakName )	//self == player
{
	self endon ("end_remote");
	self endon ("death");
	level endon ("game_ended");
	
	pathIndex = getPathIndex();
	
	print( " A10 fly path (" + level.a10SplinesIn[ pathIndex ] + ", " + level.a10SplinesOut[ pathIndex ] + ")\n" );
	
	result = self startStrafeSequence( streakName, lifeId );
	if ( result )
	{
		// randomize the order of the whether to pick inbound or outbound?
		plane = spawnAircraft( streakName, lifeId, level.a10SplinesIn[ pathIndex ] );
		if ( isDefined( plane ) )
		{
			plane doOneFlyby();
			self switchAircraft( plane, streakName );

			plane = spawnAircraft( streakName, lifeId, level.a10SplinesIn[ pathIndex ] );
			if ( isDefined( plane ) )
			{
				self thread maps\mp\killstreaks\_killstreaks::clearRideIntro( 1.0, kTransitionTime );
			
				plane doOneFlyby();
				plane thread endFlyby( streakName );

				self endStrafeSequence( streakName );
			}
		}
	}
}

startStrafeSequence( streakName, lifeId )	// self == owner
{
	self setUsingRemote( KS_NAME );

	if( GetDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( false );
	
	self.restoreAngles = self.angles;
	
	self freezeControlsWrapper( true );
	result = self maps\mp\killstreaks\_killstreaks::initRideKillstreak( KS_NAME );
	if( result != "success" )
	{
		if ( result != "disconnect" )
			self clearUsingRemote();

		if( IsDefined( self.disabledWeapon ) && self.disabledWeapon )
			self _enableWeapon();
		self notify( "death" );

		return false;
	}
	
	if( self isJuggernaut() && IsDefined( self.juggernautOverlay ) )
	{
		self.juggernautOverlay.alpha = 0;
	}
		
	self freezeControlsWrapper( false );
	
	level.a10strafeActive = true;
	self.using_remote_a10 = true;
	
	level thread teamPlayerCardSplash( "used_" + streakName, self, self.team );
	
	return true;
}

endStrafeSequence( streakName )
{
	self clearUsingRemote();
	
	if( GetDvarInt( "camera_thirdPerson" ) )
	{
		self setThirdPersonDOF( true );
	}
		
	if( self isJuggernaut() && IsDefined( self.juggernautOverlay ) )
	{
		self.juggernautOverlay.alpha = 1;
	}
	
	self SetPlayerAngles( self.restoreAngles );	
	self.restoreAngles = undefined;
	
	self thread a10_FreezeBuffer();
	
	// play outbound vo
	level.a10strafeActive = undefined;
	self.using_remote_a10 = undefined;
}

switchAircraft( plane, streakName )	// self == player
{
	// !!!! hack
	// we don't want to call clearUsingRemote because we want to stay in remote
	// but we have to clear this flag so that setUsingRemote during the second pass works
	self.usingRemote = undefined;
	
	self VisionSetNakedForPlayer( "black_bw", kTransitionTime );
	self thread set_visionset_for_watching_players( "black_bw", kTransitionTime, kTransitionTime );
	wait( kTransitionTime );
	
	if ( IsDefined( plane ) )
	{
		plane thread endFlyby( streakName );
	}
	
	// play some VO to indicate a 2nd pilot
}

spawnAircraft( streakName, lifeId, splineId )
{
	plane = createPlaneAsHeli( streakName, lifeId, splineId );
	if ( !isDefined( plane ) )
		return undefined;

	plane.streakName = streakName;
	// plane endon( "death" );
	
	self RemoteControlVehicle( plane );
	plane SetPlaneSplineId( self, splineId );
	
	// plane attachTurret( streakName );
	
	self thread watchIntroCleared( streakName, plane );
	
	config = level.planeConfigs[ streakName ];
	plane PlayLoopSound( config.sfxEngine_1p );
	
	// add damage handling
	plane thread a10_handleDamage();
	
	maps\mp\killstreaks\_plane::startTrackingPlane( plane );
	
	return plane;
}

attachTurret( streakName )	// self == plane
{
	config = level.planeConfigs[ streakName ];
	turretPos = self GetTagOrigin( config.turretAttachPoint );
	turret = SpawnTurret( "misc_turret", self.origin + turretPos, config.turretName, false );
	turret LinkTo( self, config.turretAttachPoint, ( 0, 0, 0 ), ( 0, 0, 0 ) );
	turret SetModel( "vehicle_ugv_talon_gun_mp" );
	turret.angles = self.angles;
	turret.owner = self.owner;
	
	// set model?
	
	turret MakeTurretInoperable();
	turret SetTurretModeChangeWait( false );
	turret SetMode( "sentry_offline" );
	turret MakeUnusable();
	turret SetCanDamage( false );
	turret SetSentryOwner( self.owner );
	
	self.owner RemoteControlTurret( turret );
	
	self.turret = turret;
}

cleanupAircraft()
{
	if ( IsDefined( self.turret ) )
	{
		self.turret Delete();
	}
	
	foreach ( targetInfo in self.targetList )
	{
		if ( IsDefined( targetInfo["icon"] ) )
		{
			targetInfo["icon"] Destroy();
			targetInfo["icon"] = undefined;
		}
	}
		
	self Delete();
}

getPathIndex()
{
	return ( RandomInt(level.a10SplinesIn.size ) );
}

doOneFlyby()
{
	self endon( "death" );
	level endon( "game_ended" );
	
	while ( true )
	{
		// also wait for death of plane
		self waittill ( "splinePlaneReachedNode", nodeLabel );
		if ( IsDefined( nodeLabel ) && nodeLabel == "End" )
		{
			self notify( "a10_end_strafe" );
			break;
		}
	}
}

endFlyby( streakName )
{
	if( !IsDefined( self ) )
		return;
	
	// disconnect the player from the plane
	self.owner RemoteControlVehicleOff( self );
	if ( IsDefined( self.turret ) )
	{
		self.owner RemoteControlTurretOff( self.turret );
	}
	
	self notify( "end_remote" );
	
	self.owner SetClientOmnvar( "ui_a10", false );
	self.owner ThermalVisionFOFOverlayOff();	
	
	config = level.planeConfigs[ streakName ];
	self StopLoopSound( config.sfxCannonFireLoop_1p );
	
	maps\mp\killstreaks\_plane::stopTrackingPlane( self );
	
	// let it fly away
	wait( 5 );
	
	if (IsDefined( self ) )
	{
		self StopLoopSound( config.sfxEngine_1p );
		
		self cleanupAircraft();
		// self notify("delete");
	}
}

createPlaneAsHeli( streakName, lifeId, splineId )	// self == player
{
	// get plane config
	config 			= level.planeConfigs[ streakName ];
	
	// get the start pos and tangent of the spline
	startPos		= GetCSplinePointPosition( splineId, 0 );
	startTangent	= GetCSplinePointTangent( splineId, 0 );
	
	// calculate start angles
	startAngles		= VectorToAngles( startTangent );
	
	// spawn plane
	plane = SpawnHelicopter( self, startPos, startAngles, config.vehicle, config.modelNames[ self.team ] );
	if ( !IsDefined( plane ) )
		return undefined;

	// set plane to be solid
	plane MakeVehicleSolidCapsule( 18, -9, 18 );
	
	// set plane owner/team
	plane.owner = self;
	plane.team = self.team;
	
	// set plane life id
	plane.lifeId = lifeId;
	
	// start fx
	plane thread maps\mp\killstreaks\_plane::playPlaneFX();

	// return the plane
	return plane;
}

handleDeath() // self == plane
{
	level endon( "game_ended" );
	self endon( "delete" );

	self waittill( "death" );
	
	// not sure if this will even work
	// self.owner stopPilot( self );
	
	level.a10strafeActive = undefined;
	self.owner.using_remote_a10 = undefined;
	
	self delete();
}

a10_FreezeBuffer()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self freezeControlsWrapper( true );
	wait( 0.5 );
	self freezeControlsWrapper( false );
}

monitorRocketFire( streakName, plane )	// self == player
{
	plane endon( "end_remote" );
	plane endon( "death" );
	self endon( "death" );
	level endon( "game_ended" );
	
	config = level.planeConfigs[ streakName ];
	plane.numRocketsLeft = config.numRockets;
	
	self NotifyOnPlayerCommand( "rocket_fire_pressed", "+speed_throw" );
	self NotifyOnPlayerCommand( "rocket_fire_pressed", "+ads_akimbo_accessible" );
	if( !level.console )
	{
		self NotifyOnPlayerCommand( "rocket_fire_pressed", "+toggleads_throw" );
	}
	
	self SetClientOmnvar( "ui_a10_rocket", plane.numRocketsLeft );
	
	while (plane.numRocketsLeft > 0)
	{
		self waittill( "rocket_fire_pressed" );
		
		plane onFireRocket( streakName );
		
		wait( config.delayBetweenRockets );
	}
}

monitorRocketFire2(streakName, plane)
{
	plane endon( "end_remote" );
	plane endon( "death" );
	self endon( "death" );
	level endon( "game_ended" );
	
	config = level.planeConfigs[ streakName ];
	plane.numRocketsLeft = config.numRockets;
	
	self NotifyOnPlayerCommand( "rocket_fire_pressed", "+speed_throw" );
	self NotifyOnPlayerCommand( "rocket_fire_pressed", "+ads_akimbo_accessible" );
	if( !level.console )
	{
		self NotifyOnPlayerCommand( "rocket_fire_pressed", "+toggleads_throw" );
	}
	
	plane.targetList = [];
	
	self SetClientOmnvar( "ui_a10_rocket", plane.numRocketsLeft );
	
	while ( plane.numRocketsLeft > 0 )
	{
		if ( !(self AdsButtonPressed()) )
		{
			self waittill( "rocket_fire_pressed" );
		}
	
		plane missileAcquireTargets();
		
		if ( plane.targetList.size > 0 )
		{
			plane thread fireMissiles();
		}
	}
}

missileGetBestTarget()	// self == plane
{
	candidateList = [];
	
	foreach (player in level.players)
	{
		if (self missileIsGoodTarget(player))
		{
			candidateList[ candidateList.size ] = player;
		}
	}
	
	foreach (uplink in level.uplinks)
	{
		if (self missileIsGoodTarget(uplink))
		{
			candidateList[ candidateList.size ] = uplink;
		}
	}
	
	// satcoms?
	// ugvs?
	
	if ( candidateList.size > 0 )
	{
		sortedCandidateList = SortByDistance(candidateList, self.origin);
		
		return sortedCandidateList[0];
	}
	
	return undefined;
}

missileIsGoodTarget( target )	// self == plane
{
	return ( IsAlive(target)
		    && target.team != self.owner.team
		    && !(self isMissileTargeted( target ))
		    && (IsPlayer( target ) && !(target _hasPerk( "specialty_blindeye" )))
			// && (self.owner WorldPointInReticle_Circle(target.origin, 65, 200))
			&& self missileTargetAngle( target ) > 0.25
	);
}

// this needs to be optimized
missileTargetAngle( target )	// self == plane
{
	dirToTarget = VectorNormalize( target.origin - self.origin );
	facingDir = AnglesToForward( self.angles );
	
	return VectorDot( dirToTarget, facingDir );
}

missileAcquireTargets()
{
	self endon ("death");
	self endon( "end_remote" );
	level endon ("game_ended");
	self endon ("a10_missiles_fired");
	
	config = level.planeConfigs[ self.streakName ];
	
	self.owner SetClientOmnvar( "ui_a10_rocket_lock", true );
	
	self thread missileWaitForTriggerRelease();
	
	currentTarget = undefined;
	
	while ( self.targetList.size < self.numRocketsLeft )
	{
		if ( !IsDefined( currentTarget ) )
		{
			currentTarget = self missileGetBestTarget();
			
			if ( IsDefined( currentTarget ) )
			{
				self thread missileLockTarget( currentTarget );
			
				wait (config.delayBetweenLockon);
			
				currentTarget = undefined;
				
				continue;
			}
		}
		
		wait (0.1);
	}
	
	self.owner SetClientOmnvar( "ui_a10_rocket_lock", false );
	self notify( "a10_missiles_fired" );
}

missileWaitForTriggerRelease()
{
	self endon( "end_remote" );
	self endon( "death" );
	level endon( "game_ended" );
	self endon ("a10_missiles_fired");
	
	owner = self.owner;
	owner NotifyOnPlayerCommand( "rocket_fire_released", "-speed_throw" );
	owner NotifyOnPlayerCommand( "rocket_fire_released", "-ads_akimbo_accessible" );
	if( !level.console )
	{
		owner NotifyOnPlayerCommand( "rocket_fire_released", "-toggleads_throw" );
	}
	
	self.owner waittill( "rocket_fire_released" );
	
	owner SetClientOmnvar( "ui_a10_rocket_lock", false );
	
	self notify( "a10_missiles_fired" );
}

missileLockTarget( target )	// self == plane
{
	config = level.planeConfigs[ self.streakName ];
	
	info = [];
	// veh_hud_target_marked
	info["icon"] = target maps\mp\_entityheadIcons::setHeadIcon( self.owner, config.lockonIcon, kLockIconOffset, 10, 10, false, 0.05, true, false, false, false );
	info["target"] = target;
	
	self.targetList[ target GetEntityNumber() ] = info;
	
	self.owner PlayLocalSound( "recondrone_lockon" );
	
	// need to handle case where target dies before
}

isMissileTargeted( target )	// self == plane
{
	return ( IsDefined( self.targetList[ target GetEntityNumber() ] ) );
}

fireMissiles()	// self == plane
{
	self endon( "death" );
	level endon( "game_ended" );
	
	config = level.planeConfigs[ self.streakName ];
	
	foreach ( targetInfo in self.targetList )
	{
		if ( self.numRocketsLeft > 0 )
		{
			// fire at one target
			missile = self onFireHomingMissile( self.streakName, targetInfo["target"], kLockIconOffset );
			
			if ( IsDefined( targetInfo["icon"] ) )
			{
				missile.icon = targetInfo["icon"];
				targetInfo["icon"] = undefined;
			}
			
			wait (config.delayBetweenRockets);
		}
		else
		{
			break;
		}
	}
	
	targetList = [];
}


	
onFireHomingMissile( streakName, target, targetOffset )	// self == plane
{
	side = self.numRocketsLeft % 2;
	tagName = "tag_missile_" + (side + 1);
	
	rocketPos = self GetTagOrigin( tagName );
	if ( IsDefined( rocketPos ) )
	{
		owner = self.owner;
		
		config = level.planeConfigs[ streakName ];
		/*
		eye_pos		 = owner GetEye();
		eye_fwd		 = AnglesToForward( owner GetPlayerAngles() );
		eye_trace	 = BulletTrace( eye_pos + eye_fwd * 360, eye_pos + eye_fwd * MISSILE_IMPACT_DIST_MAX, false, self );
		eye_end_dist = max( MISSILE_IMPACT_DIST_MIN, eye_trace[ "fraction" ] * MISSILE_IMPACT_DIST_MAX );
		
		rocket = MagicBullet( projectileName, rocketPos, rocketPos + eye_end_dist * eye_fwd, self.owner );
		*/
		rocket = MagicBullet( config.rocketModelName, rocketPos, rocketPos + 100 * AnglesToForward(self.angles), self.owner );
		rocket thread a10_missile_set_target( target, targetOffset );
		
		Earthquake (0.25, 0.05, self.origin, 512);
		
		self.numRocketsLeft--;
		self.owner SetClientOmnvar( "ui_a10_rocket", self.numRocketsLeft );
		
		config = level.planeConfigs[ streakName ];
		rocket PlaySoundOnMovingEnt( config.sfxMissileFire_1p[ side ] );
		rocket PlayLoopSound( config.sfxMissile );
		
		// self PlaySoundOnMovingEnt( "a10p_missile_launch" );
		
		// HidePart doesn't work with helicopters?
		// self HidePart( tagName );
		
		// kill cam stuff?
		
		return rocket;
	}
	
	return undefined;
}

MISSILE_IMPACT_DIST_MAX		   = 15000;
MISSILE_IMPACT_DIST_MIN		   = 1000;
onFireRocket( streakName )	// self == plane
{
	tagName = "tag_missile_" + self.numRocketsLeft;
	
	rocketPos = self GetTagOrigin( tagName );
	if ( IsDefined( rocketPos ) )
	{
		owner = self.owner;
		
		config = level.planeConfigs[ streakName ];
		/*
		eye_pos		 = owner GetEye();
		eye_fwd		 = AnglesToForward( owner GetPlayerAngles() );
		eye_trace	 = BulletTrace( eye_pos + eye_fwd * 360, eye_pos + eye_fwd * MISSILE_IMPACT_DIST_MAX, false, self );
		eye_end_dist = max( MISSILE_IMPACT_DIST_MIN, eye_trace[ "fraction" ] * MISSILE_IMPACT_DIST_MAX );
		
		rocket = MagicBullet( projectileName, rocketPos, rocketPos + eye_end_dist * eye_fwd, self.owner );
		*/
		rocket = MagicBullet( config.rocketModelName, rocketPos, rocketPos + 100 * AnglesToForward(self.angles), self.owner );
		
		Earthquake (0.25, 0.05, self.origin, 512);
		
		self.numRocketsLeft--;
		self.owner SetClientOmnvar( "ui_a10_rocket", self.numRocketsLeft );
				
		rocket PlaySoundOnMovingEnt( config.sfxMissileFire_1p[ self.numRocketsLeft ] );
		rocket PlayLoopSound( config.sfxMissile );
		
		self PlaySoundOnMovingEnt( "a10p_missile_launch" );
		
		// HidePart doesn't work with helicopters?
		// self HidePart( tagName );
		
		// kill cam stuff?
	}
}

a10_missile_set_target( target, offset )
{
	self thread a10_missile_cleanup();
	
	wait 0.2;
	
	self Missile_SetTargetEnt( target, offset );
	// self Missile_SetFlightmodeDirect();
}

a10_missile_cleanup()
{
	self waittill( "death" );
	
	if ( IsDefined( self.icon ) )
	{
		self.icon Destroy();
	}
}

CANNON_SHAKE_TIME = 0.5;
monitorWeaponFire( streakName, plane )	// self == player
{
	plane endon( "end_remote" );
	plane endon( "death" );
	self endon( "death" );
	level endon( "game_ended" );
	
	config = level.planeConfigs[ streakName ];
	
	plane.ammoCount = 1350;
	
	self SetClientOmnvar( "ui_a10_cannon", plane.ammoCount );
	
	self NotifyOnPlayerCommand( "a10_cannon_start", "+attack" );
	self NotifyOnPlayerCommand( "a10_cannon_stop", "-attack" );

	while ( plane.ammoCount > 0 )
	{
		// IsFiringVehicleTurret
		if ( !(self AttackButtonPressed()) )
		{
			self waittill( "a10_cannon_start" );
		}
		
		cannonShortBurstTimeLimit = GetTime() + config.sfxCannonFireBurpTime;
		
		plane PlayLoopSound( config.sfxCannonFireLoop_1p );
		plane thread updateCannonShake( streakName );
		
		self waittill( "a10_cannon_stop" );

		plane StopLoopSound( config.sfxCannonFireLoop_1p );
		plane PlaySoundOnMovingEnt( config.sfxCannonFireStop_1p );
		
		if ( GetTime() < cannonShortBurstTimeLimit )
		{
			playSoundAtPos( plane.origin, config.sfxCannonFireBurpShort_3p );
		}
		else
		{
			playSoundAtPos( plane.origin, config.sfxCannonFireBurpLong_3p );
		}
	}
}

// should eventually unify
updateCannonShake( streakName )	// self == plane
{
	self.owner endon( "a10_cannon_stop" );
	self endon( "death" );
	level endon( "game_ended" );
	
	config = level.planeConfigs[ streakName ];
		
	while ( self.ammoCount > 0 )
	{
		Earthquake (0.2, CANNON_SHAKE_TIME, self.origin, 512);
		self.ammoCount -= 10;
		self.owner SetClientOmnvar( "ui_a10_cannon", self.ammoCount );
		
		barrelPoint = self GetTagOrigin( "tag_flash_attach" ) + 20 * AnglesToForward( self.angles );
		PlayFX( config.cannonFireVFX, barrelPoint );
		
		self PlayRumbleOnEntity( config.cannonRumble );
		
		// this needs to match the cannon's fire rate in the gdt
		wait( 0.1 );
	}
	
	self.turret TurretFireDisable();
}

ALTITUDE_WARNING_LIMIT = 1000;
monitorAltitude( streakName, plane )
{
	plane endon( "end_remote" );
	plane endon( "death" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self SetClientOmnvar( "ui_a10_alt_warn", false );

	while( true )
	{
		// the max is in omnvar
		alt = Int( Clamp(plane.origin[2], 0, 16383) );
		self SetClientOmnvar( "ui_a10_alt", alt );
		
		if (alt <= ALTITUDE_WARNING_LIMIT && !IsDefined( plane.altWarning ) )
		{
			plane.altWarning = true;
			self SetClientOmnvar( "ui_a10_alt_warn", true );
		}
		else if (alt > ALTITUDE_WARNING_LIMIT && IsDefined( plane.altWarning ) )
		{
			plane.altWarning = undefined;
			self SetClientOmnvar( "ui_a10_alt_warn", false );
		}

		wait( 0.1 );
	}
}

watchIntroCleared( streakName, plane ) // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill( "intro_cleared" );
	
	self SetClientOmnvar( "ui_a10", true );
	
	// self EnableWeapons();
	
	self thread monitorAltitude( streakname, plane );
	self thread monitorRocketFire2( streakName, plane );
	self thread monitorWeaponFire( streakName, plane );
	self thread watchRoundEnd( plane, streakName );
	
	self ThermalVisionFOFOverlayOn();
	
	/*
	// pick a path
	plane.curFlightPath = level.a10FlightPaths[ 0 ];
	plane thread followFlightPath();
	*/
	
	self thread watchEarlyExit( plane );
}

watchRoundEnd( plane, streakName )	// self == player
{
	plane endon( "death" );
	plane endon( "leaving" );	
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );	

	level waittill_any( "round_end_finished", "game_ended" );

	//	leave
	plane thread endFlyby( streakName );
	self endStrafeSequence( streakName );
	
	self a10_explode();
}

buildAllFlightPathsDefault()
{
	// temp - do not check in - should be done per level
	inBoundList = [];
	inBoundList[0] = 1;
	inBoundList[1] = 2;
	inBoundList[2] = 3;
	inBoundList[3] = 4;
	inBoundList[4] = 1;
	inBoundList[5] = 2;
	inBoundList[6] = 4;
	inBoundList[7] = 3;
	
	outBoundList = [];
	outBoundList[0] = 2;
	outBoundList[1] = 1;
	outBoundList[2] = 4;
	outBoundList[3] = 3;
	outBoundList[4] = 1;
	outBoundList[5] = 4;
	outBoundList[6] = 3;
	outBoundList[7] = 2;
	
	buildAllFlightPaths( inBoundList, outBoundList );
}

buildAllFlightPaths( inBoundList, outBoundList )
{
	level.a10SplinesIn = inBoundList;
	level.a10SplinesOut = outBoundList;
}

// stolen from a10_proto_script
// check it for more audio
a10_cockpit_breathing()
{
	level endon("remove_player_control");
	
	for(;;)
	{
		wait (RandomFloatRange(3.0, 7.0));
		//level.player radio_dialog_add_and_go("a10_breathing_r");
	}
}

watchEarlyExit( veh )	// self == player
{
	level endon( "game_ended" );
	veh endon( "death" );
	veh endon( "a10_end_strafe" );
	
	veh thread maps\mp\killstreaks\_killstreaks::allowRideKillstreakPlayerExit();
	
	veh waittill("killstreakExit");
	
	self notify("end_remote");
	veh thread endFlyby( veh.streakName );
	self endStrafeSequence( veh.streakName );
	veh a10_explode();
}

a10_handleDamage()
{
	self endon( "end_remote" );
	
	config = level.planeConfigs[ self.streakName ];
	
	self maps\mp\gametypes\_damage::monitorDamage(
		config.maxHealth,
		"helicopter",
		::handleDeathDamage,
		::modifyDamage,
		true	// isKillstreak
	);
}

modifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
	
	// modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleEmpDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	// do damage effects?
	
	return modifiedDamage;
}

handleDeathDamage( attacker, weapon, type, damage )	// self == plane
{
	config = level.planeConfigs[ self.streakName ];
	// !!! need VO
	self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, damage, config.voDestroyed, config.xpPopup, config.callout );
	
	self a10_explode();
}

// plane explode
a10_explode()
{
	config = level.planeConfigs[ self.streakName ];
	
	maps\mp\killstreaks\_plane::stopTrackingPlane( self );
	PlayFX ( config.explodeVfx, self.origin );
	self Delete();	// self Hide();
}