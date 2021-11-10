#include maps\mp\_utility;
#include common_scripts\utility;

KS_NAME = "ca_a10_strafe";
kTransitionTime = 0.125;
kLockIconOffset = (0, 0, -70);

init(map_name)
{
	level._effect["vfx_a10_missile_fire"] = LoadFX("vfx/moments/mp_ca_impact/vfx_a10_missile_fire");
	
	//TODO Missiles and Control Surfaces
	//vehicle_ca_a10_warthog
	//vehicle_a10_warthog_iw6_mp
	config = SpawnStruct();
	config.modelNames = [];
	config.modelNames[ "allies" ] = "vehicle_ca_a10_warthog";
	config.modelNames[ "axis" ] = "vehicle_ca_a10_warthog";
	config.vehicle = "ca_a10warthog_mp";
	config.inboundSfx = "veh_mig29_dist_loop";

	config.speed = 750;
	config.halfDistance = 12500;
	config.heightRange = 750;
	config.chooseDirection = true;
	config.selectLocationVO = "KS_hqr_airstrike";
	config.inboundVO = "KS_ast_inbound";
	
	config.cannonFireVfx = LoadFX( "fx/smoke/smoke_trail_white_heli" );
	config.cannonRumble = "ac130_25mm_fire";
	config.turretName = "a10_cammturret_mp";
	config.turretAttachPoint = "tag_barrel";
	
	config.rocketModelName = "iw6_a10impactmissile_mp";

	config.numRockets = 4;
	config.delayBetweenRockets = 0.125;
	config.delayBetweenLockon = 0.4;
	config.lockonIcon = "veh_hud_target_chopperfly";	//  "veh_hud_target_lock"
	
	config.maxHealth = 10000;
	config.xpPopup = "destroyed_a10_strafe";
	config.callout = "callout_destroyed_a10";
	config.voDestroyed = undefined;
	config.explodeVfx = LoadFX( "vfx/gameplay/explosions/vehicle/aas_mp/vfx_x_mpaas_primary");
	
	// holy crap, lots of sfx
	config.sfxCannonFireLoop_1p = "a10_plr_fire_gatling_lp";
	config.sfxCannonFireStop_1p = "a10_plr_fire_gatling_cooldown";
	config.sfxCannonFireLoop_3p = "a10_npc_fire_gatling_lp";
	config.sfxCannonFireStop_3p = "a10_npc_fire_gatling_cooldown";
	config.sfxCannonFireBurpTime = 500;
	config.sfxCannonFireBurpShort_3p = "veh_a10_npc_fire_gatling_short_burst";
	config.sfxCannonFireBurpLong_3p = "veh_a10_npc_fire_gatling_long_burst";
	config.sfxCannonBulletImpact = "a10_bullet_impact_lp";	// loop, should play on moving entity
	
	config.sfxMissileFire_1p = [];
	config.sfxMissileFire_1p[0] = "veh_a10_plr_missile_ignition_left";
	config.sfxMissileFire_1p[1] = "veh_a10_plr_missile_ignition_right";
	config.sfxMissileFire_3p = "veh_a10_npc_missile_fire";
	config.sfxMissile = "veh_a10_missile_loop";
	
	config.sfxEngine_1p = "veh_a10_plr_engine_lp";
	config.sfxEngine_3p = "veh_a10_dist_loop";
	
	level.planeConfigs[ KS_NAME ] = config;
	
	level.killstreakFuncs[KS_NAME] = ::onUse;
	
	level.a10_active = 0;	
	level.curr_a10_index = 0;
	
	// set up custom flight paths based on each map	
	if(map_name == "impact")
		buildAllFlightPathsImpact();
	else
		buildAllFlightPathsDefault();
	
	level.debug_prints = 0;
}

onUse( lifeId, streakName )
{	
	config = level.planeConfigs[KS_NAME];
	level.killstreakWeildWeapons[config.rocketModelName] = "ca_a10_strafe";
	level.killstreakWeildWeapons[config.turretName] = "ca_a10_strafe";
	
	if(isAirDenied())
	{
		self IPrintLnBold(&"KILLSTREAKS_UNAVAILABLE_WHEN_AA");
		return false;
	}
	
	// because a lot of things break when the A10 is called while the nuke is incoming
	if(isDefined(level.nukeIncoming) && level.nukeIncoming)
	{
		self IPrintLnBold(&"MP_CA_KILLSTREAKS_A10_UNAVAIL_NUKE");
		return false;
	}
	
	// make it unavailable to opposing team if the nuke just hit
	if(self isNuked())
	{
		self iPrintlnBold(&"KILLSTREAKS_UNAVAILABLE_FOR_N_WHEN_NUKE", level.nukeEmpTimeRemaining);
		return false;
	}
	
	if (level.a10_active || self isUsingRemote() || self isKillStreakDenied() || !isAlive(self))
	{
		return false;
	}
	
	if((level.littleBirds.size == 0) && !(IsDefined(level.chopper)))
	{
		self thread doStrike( lifeId, KS_NAME );
		return true;
	}
	
	self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
	return false;
}

doStrike( lifeId, streakName )	//self == player
{
	self endon ("end_remote");
	self endon ("disconnect");
	level endon ("game_ended");
	self endon("ca_a10_nuked");
	
	self thread watchTeamSwitchPre();
	self thread watchDisconnect();
	self thread watchNukePlayer();
	
	index_a = 0;
	index_b = 1;
	
	pathIndex = 0;
	
	print( " A10 fly path (" + level.a10SplinesIn[ pathIndex ] + ", " + level.a10SplinesOut[ pathIndex ] + ")\n" );
	
	result = self startStrafeSequence( streakName, lifeId );
	if ( result )
	{
		if ( level.teamBased )
		{
	    	level.teamAirDenied[self.team] = true;
	    	level.teamAirDenied[getOtherTeam(self.team)] = true;
		}
	    else
	    	level.airDeniedPlayer = self;
	 
		self thread watchGameEnd();
		
		level.a10_active = 1;
		
		level thread teamPlayerCardSplash( "used_ca_a10_strafe", self, self.team );

		self.is_attacking = 0;
		plane = spawnAircraft( streakName, lifeId, level.a10SplinesIn[ index_a ], "1" );
		if ( IsDefined( plane ) )
		{	
			//wait a little bit before starting the first line, otherwise an announcer vo line will get cut off
			self thread a10_play_pilot_vo_with_wait( "mp_ca_impact_a10_pilot_01", 1.05 );			
			plane doOneFlyby();
			
			self.is_attacking = 0;
			
			self VisionSetNakedForPlayer( "black_bw", 0.75 );
			wait( 0.80 );
			
			self RemoteControlVehicleOff();
			
			if ( IsDefined( plane ) )
			{
				plane.forceClean = true; // make it clean up faster since we're doing another pass
				plane thread endFlyby( streakName );
			}
			
			plane = spawnAircraft( streakName, lifeId, level.a10SplinesIn[ index_b ], "2" );
			
			if ( IsDefined( plane ) )
			{
				self thread maps\mp\killstreaks\_killstreaks::clearRideIntro( 1.0, kTransitionTime );				
				self thread a10_play_pilot_vo_with_wait( "mp_ca_impact_a10_pilot_02", 0.3 );				
				
				plane doOneFlyby();
				
				if(isDefined(plane))
					plane thread endFlyby( streakName );
				
				self endStrafeSequence( streakName );
			}
		}
	}
	
	return result;
}

a10_play_pilot_vo_with_wait( aliasname, waittime )
{
	wait ( waittime );	
	self PlayLocalSound( aliasname );				
}


startStrafeSequence( streakName, lifeId )	// self == owner
{
	self endon ("end_remote");
	self endon ("disconnect");
	
	self setUsingRemote( KS_NAME );
	self freezeControlsWrapper( true );

	if( GetDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( false );
	
	self.restoreAngles = self.angles;
	
	if( self isJuggernaut() && IsDefined( self.juggernautOverlay ) )
	{
		self.juggernautOverlay.alpha = 0;
	}
	
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
	
	self freezeControlsWrapper( false );
	
	level.a10strafeActive = true;
	self.using_remote_a10 = true;
	
	return true;
}

endStrafeSequence( switch_state )
{	
	level endon("game_over");
	
	//println("endStrafeSequence()::start");
	
	// only do this if the player is still connected
	if(IsDefined(self))
	{
	
		// if the player ends the killstreak by switching teams, they're dead and this breaks down.
		if(switch_state != "team_switch")
		{
			// make sure the player is alive before trying to run the cleanup process
			while(!IsAlive(self))
			{
				wait 0.5;
			}
		}
		
		if( self isJuggernaut() && IsDefined( self.juggernautOverlay ) )
		{
			self.juggernautOverlay.alpha = 1;
		}
		
		self freezeControlsWrapper( false );
		
		if(self isUsingRemote())
			self clearUsingRemote();
		
		self SetClientOmnvar( "ui_a10", false );
		self SetClientOmnvar( "ui_a10_alt_warn", false );
		self SetClientOmnvar( "ui_a10_cannon", false);
		self ThermalVisionFOFOverlayOff();	
		
		if( GetDvarInt( "camera_thirdPerson" ) )
		{
			self setThirdPersonDOF( true );
		}
		
		//edge cases	
		if(IsDefined(self.restoreAngles))
		{
			self SetPlayerAngles( self.restoreAngles );	
			self.restoreAngles = undefined;
		}
		
		self thread a10_FreezeBuffer();
		self.using_remote_a10 = undefined;
		
	}
	
	level.a10strafeActive = undefined;
	level.a10_active = 0;
	
	if ( level.teamBased )
	{
    	level.teamAirDenied["axis"] = false;
    	level.teamAirDenied["allies"] = false;
	}
    else
    	level.airDeniedPlayer = undefined;
	
	//println("endStafeSequence()::end");
	
}

attachMissiles()
{
	i = 4;
	self.missiles = [];
	while(i)
	{
		missileTag = "tag_missile_" + i;
		self.missiles[missileTag] = Spawn("script_model", self GetTagOrigin(missileTag));
		self.missiles[missileTag] SetModel("veh_ca_a10_missile");
		self.missiles[missileTag].angles = self GetTagAngles(missileTag);
		self.missiles[missileTag] LinkTo(self, missileTag);
		i--;
	}
	
}

attachAnimatedFlaps()
{
	self.animated_flaps = Spawn("script_model", self GetTagOrigin("tag_origin"));
	self.animated_flaps SetModel("veh_ca_a10_flaps_animated");
	self.animated_flaps.angles = self GetTagAngles("tag_origin");
	self.animated_flaps LinkTo(self, "tag_origin");
}

spawnAircraft( streakName, lifeId, splineId, numPlane ) //self = player
{	
	self endon ("end_remote");
	self endon ("disconnect");
	
	self.plane = createPlaneAsHeli( streakName, lifeId, splineId );
	if( !IsDefined( self.plane ) )
		return undefined;
	
	self.plane.streakName = streakName;
	// plane endon( "death" );
	
	self.plane attachMissiles();
	self.plane attachAnimatedFlaps();
	
	//self.plane attachTurret( streakName );

	self CameraLinkTo(self.plane, "tag_player");
	self RemoteControlVehicle( self.plane );
	self thread watchIntroCleared( streakName, self.plane );
	self.plane SetPlaneSplineId( self, splineId );

	config = level.planeConfigs[ streakName ];
	
	sound_name = "scn_impact_a10_passby_0" + numPlane;
	self.plane playsoundonmovingent(sound_name);		
	self.plane.sound_name = sound_name;
	
	// add damage handling
	self.plane thread a10_handleDamage();
	
	self.plane thread watchDisconnectPlane();
	
	return self.plane;
}

SpawnAndPlaySoundForA10( plane, numPlane)
{
	sound_ent = Spawn( "script_model", plane.origin );
	sound_ent SetModel( "tag_origin" );
	sound_alias = ( "scn_impact_a10_passby_0" + numPlane );
	sound_ent linkto(plane);
	sound_ent PlaySoundOnMovingEnt( sound_alias );	
}


attachTurret( streakName )	// self == plane
{
	config = level.planeConfigs[ streakName ];
	turretPos = self GetTagOrigin( config.turretAttachPoint );
	turret = SpawnTurret( "misc_turret", self.origin + turretPos, config.turretName, false );
	turret.angles = self GetTagAngles( config.turretAttachPoint );
	turret LinkTo( self, config.turretAttachPoint, ( 0, 0, 0 ), ( 0, 0, 0 ) );
	
	turret.owner = self.owner;
	
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
	
	
	i = 4;
	while(i)
	{
		missileTag = "tag_missile_" + i;
		self.missiles[missileTag] Hide();
		self.missiles[missileTag] Delete();
		i--;
	}
	
	self.animated_flaps Hide();
	self.animated_flaps Delete();
	
	// check because in certain situations, this won't have been defined yet
	// usually because of team-switch
	if(IsDefined(self.targetList))
	{
		foreach ( targetInfo in self.targetList )
		{
			if ( IsDefined( targetInfo["icon"] ) )
			{
				targetInfo["icon"] Destroy();
				targetInfo["icon"] = undefined;
			}
		}
	}
		
	self Delete();
}

getPathIndex()
{
	return ( RandomInt(level.a10SplinesIn.size ) );
}

debug_print_movement(movement)
{
	println(movement);
	outString = "";
	if(movement[0] > 0)
		outString += "forward";
	else if(movement[0] == 0)
		outString += "-";
	else if(movement[0] < 0)
		outString += "backward";
		    
	outString += ", ";
	
	if(movement[1] > 0)
		outString += "right";
	else if(movement[1] == 0)
		outString += "-";
	else if(movement[1] < 0)
		outString += "left";
	
	println(outString);
}

//xanims
/*
veh_ca_a10_roll_left
veh_ca_a10_roll_level
veh_ca_a10_roll_right
*/

#using_animtree("mp_ca_impact");
handle_anim(state)
{
	self endon("a10_end_strafe");
	self endon ("disconnect");
	
	if(state == "left")
		self.animated_flaps ScriptModelPlayAnim( "veh_ca_a10_roll_left" );
	if(state == "right")
		self.animated_flaps ScriptModelPlayAnim( "veh_ca_a10_roll_right" );
	if(state == "level")
		self.animated_flaps ScriptModelPlayAnim( "veh_ca_a10_roll_level" );
}

player_input_monitor() //self = plane
{
	self endon("a10_end_strafe");
	self.owner endon ("disconnect");
	
	while(IsDefined(self))
	{
		// [1,1] = ['forward', 'right']
		
		//movement = [ 0, 0, 0 ];
		movement = self.owner GetNormalizedMovement();

		if(movement[1] > 0)
		{
			self thread handle_anim("right");
		}
		else if(movement[1] == 0)
		{
			self thread handle_anim("level");
		}
		else if(movement[1] < 0)
		{
			self thread handle_anim("left");
		}
		wait 0.05;
	}
	
}

doOneFlyby()// self = plane
{
	self endon( "death" );
	level endon( "game_ended" );
	
	//TODO Missiles and Control Surfaces
	self thread player_input_monitor();
	
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
	
	self.owner notify("a10_cannon_stop");
	self notify("a10_cannon_stop");
}

endFlyby( streakName ) //self = plane
{
	//println("endFlyby()");
	
	if( !IsDefined( self ) )
	{
		//IPrintLnBold("endFlyby()::self is not defined!");
		return;
	}
	
	config = level.planeConfigs[streakName];
	
	
	// disconnect the player from the plane
	if(streakName != "disconnect")
	{
		//self.owner CameraUnlink (self);
		
		self.owner.is_attacking = 0;
		
		self.owner RemoteControlVehicleOff( self );
		if ( IsDefined( self.turret ) )
		{
			self.owner RemoteControlTurretOff( self.turret );
		}
	}
	
	self notify( "end_remote" );
	
	// let it fly away if we're not cleaning up after an early-exit situation
	if(!(IsDefined(self.forceClean)))
		wait( 5 );
	else
		self StopSounds();
	
	if (IsDefined( self ) )
	{
		
		//PrintLn("Moving into cleanupAircraft()");
		
		self cleanupAircraft();
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
	//level endon( "game_ended" );
	self endon( "delete" );
	
	self waittill( "death" );
	
	self.forceClean = true;
	self.owner thread endStrafeSequence( KS_NAME );
	self thread endFlyby(KS_NAME);
	
	level.a10_active = 0;
	level.a10strafeActive = undefined;
	self.owner.using_remote_a10 = undefined;
}

a10_FreezeBuffer()
{
	self endon( "disconnect" );
	//self endon( "death" );
	level endon( "game_ended" );
	
	self freezeControlsWrapper( true );
	wait( 0.5 );
	self freezeControlsWrapper( false );
}

monitorRocketFire2(streakName, plane)
{
	plane endon( "end_remote" );
	plane endon( "death" );
	self endon ("disconnect");
	level endon( "game_ended" );
	
	config = level.planeConfigs[ streakName ];
	plane.numRocketsLeft = config.numRockets;
	
	
	plane.targetList = [];
		
	// bots don't press +/- buttons, so this falls apart if they try to use the A10 killstreak
	if(!IsBot(self))
	{
			
		self NotifyOnPlayerCommand( "rocket_fire_pressed", "+speed_throw" );
		self NotifyOnPlayerCommand( "rocket_fire_pressed", "+ads_akimbo_accessible" );
			
		if( !level.console )
		{
			self NotifyOnPlayerCommand( "rocket_fire_pressed", "+toggleads_throw" );
		}
		
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
	self endon ("disconnect");
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
	//self endon( "death" );
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
	//info["icon"] = target maps\mp\_entityheadIcons::setHeadIcon( self.owner, config.lockonIcon, kLockIconOffset, 10, 10, false, 0.05, true, false, false, false );
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
	self endon ("disconnect");
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

	self endon ("disconnect");
	
//	side = self.numRocketsLeft % 2;
//	tagName = "tag_missile_" + (side + 1);
	
	//TODO:FLAPS AND MISSILES
	tagName = "tag_missile_" + self.numRocketsLeft;

	rocketPos = self GetTagOrigin( tagName );
	if ( IsDefined( rocketPos ) )
	{
		owner = self.owner;
		
		config = level.planeConfigs[ streakName ];
		
		// this is what fires the missile
		rocket = MagicBullet( config.rocketModelName, rocketPos, rocketPos + 100 * AnglesToForward(self.angles), self.owner );
		rocket thread a10_missile_set_target( target, targetOffset );
		
		Earthquake (0.25, 0.05, self.origin, 512);
		
		self.numRocketsLeft--;
		self.owner SetClientOmnvar( "ui_a10_rocket", self.numRocketsLeft );
		
		//rocket PlaySoundOnMovingEnt( config.sfxMissileFire_1p[ side ] );
		//rocket PlayLoopSound( config.sfxMissile );
		
		//play the missile fire sound on the a10
		self PlaySoundOnMovingEnt( "a10p_missile_launch" );
		
		// player the missile fire effect on the a10
		PlayFXOnTag(level._effect["vfx_a10_missile_fire"], self, tagName);
		
		// HidePart doesn't work with helicopters?
		//self HidePart( tagName );
		
		//TODO Missiles and Control Surfaces
		self.missiles[tagName] Hide();
		
		return rocket;
	}
	
	return undefined;
}

MISSILE_IMPACT_DIST_MAX		   = 15000;
MISSILE_IMPACT_DIST_MIN		   = 1000;

a10_missile_set_target( target, offset )
{
	self thread a10_missile_cleanup();
	
	wait 0.2;
	
	if(IsDefined(self) && IsAlive(self))
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

bot_plane_watcher(plane)
{
	level.end_a10_firing = 0;
	plane waittill( "end_remote" );
	level.end_a10_firing = 1;
}

//resetStreakCount()

bot_fire_controller(plane, config)
{
	self BotPressButton("attack");
	
	self thread bot_plane_watcher(plane);
	
	self.is_attacking = 1;
	plane thread update_hit_sound_ent();
	plane thread update_gatling_sound_ent();
	
	while(!level.end_a10_firing)
	{
		self BotPressButton("attack");
		wait 0.01;
	}
	
	self.is_attacking = 0;
	
}

get_look_position()
{
	eye = self.origin;
	angles = self.angles;
	forward = anglestoforward( angles );
	end = eye + ( forward * 7000 );
	trace = bullettrace( eye, end, true, self);	
	
	return trace["position"];
}

update_hit_sound_ent() //self == plane
{
	//self endon( "end_remote" );
	//self endon( "death" );
	level endon( "game_ended" );
	//self endon("a10_end_strafe");
	
	//PrintLn("waiting for firing hits");	
	
	spawn_origin = self get_look_position();
	moving_ent = Spawn("script_origin", spawn_origin);
	moving_ent PlayLoopSound("a10_bullet_impact_lp");
	
	while(IsDefined(self) && self.owner.is_attacking)
	{
		moving_ent MoveTo(self get_look_position(), 0.15);
		wait 0.01;
	}	
	
	moving_ent StopLoopSound();
	moving_ent Delete();
}


update_gatling_sound_ent() //self = plane
{
	//DR: This will play 1st person and 3rd person sounds - both - for the gatling gun while firing
	
	level endon( "game_ended" );
	
	//PrintLn("waiting for gatling gun to start");	
	
	spawn_origin = self.origin;
	moving_gatling_ent = Spawn("script_origin", spawn_origin);	
	
	//player sound for gatling gun
	self.owner PlayLocalSound("a10_plr_fire_gatling_lp");
	//npc sound for gatling gun
	moving_gatling_ent PlayLoopSound( "a10_npc_fire_gatling_lp" );
	
	while( IsDefined( self ) && IsDefined( self.owner ) && IsDefined( moving_gatling_ent ) && self.owner.is_attacking )
	{
		moving_gatling_ent MoveTo( self.origin, 0.1 );
		wait 0.01;
	}	
	
	//start playing the release sound, then stop the loop sound - will need a new ent for the release sound
	
	if( IsDefined( self ) )
		self thread update_gatling_sound_release_ent();
	
	//MO: cut the delay because of IWSIX-170454
	//wait a short period of time, then stop the sounds
	//wait 0.1;
	
	//stop the player and npc sounds, and then play a release sound
	//player
	if( IsDefined( self ) && IsDefined( self.owner ) )
		self.owner StopLocalSound("a10_plr_fire_gatling_lp");

	//npc
	if( IsDefined( moving_gatling_ent ) )
	{
		moving_gatling_ent StopLoopSound();
		//moving_gatling_ent playsound ("a10_npc_fire_gatling_cooldown");	
		moving_gatling_ent Delete();
	}
}

cutoff_gatling_sound_release()
{
	self waittill_any("end_remote", "end_gatling");
	self.owner StopLocalSound("a10_plr_fire_gatling_cooldown");
}

update_gatling_sound_release_ent()
{
	//this spawns a new ent for the release sound, and plays it
	//so that we have overlap between the loop and release
	
	level endon( "game_ended" );
	//self endon("a10_end_strafe");
	
	//PrintLn("playing release sound for gatling gun");	
	
	spawn_origin = self.origin;
	moving_gatling_release_ent = Spawn("script_origin", spawn_origin);		
	
	// so it shuts off correctly if it's playing while the killstreak is ending
	self thread cutoff_gatling_sound_release();
	
	self.owner PlayLocalSound("a10_plr_fire_gatling_cooldown");	
	moving_gatling_release_ent PlaySound( "a10_npc_fire_gatling_cooldown" );
	
	wait 2.5;
	
	if( IsDefined( moving_gatling_release_ent ) )
		moving_gatling_release_ent Delete();
	
	self notify("end_gatling");
}

CANNON_SHAKE_TIME = 0.5;
monitorWeaponFire( streakName, plane )	// self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	plane endon("end_remote");
	plane endon("death");
	plane endon("a10_end_strafe");
	
	config = level.planeConfigs[ streakName ];
	
	plane.ammoCount = 1350;
	
	self SetClientOmnvar( "ui_a10_cannon", plane.ammoCount );

	if(isBot(self))
		self thread bot_fire_controller(plane, config);
	
	else
	{
	
		self thread monitor_attack_button(plane);

		while ( plane.ammoCount > 0 )
		{
			while(!self.is_attacking)
			{
				wait 0.01;	
			}
			
			cannonShortBurstTimeLimit = GetTime() + config.sfxCannonFireBurpTime;
			
			plane thread update_hit_sound_ent();
			plane thread update_gatling_sound_ent();
			plane thread updateCannonShake( streakName );
			
			while(self.is_attacking)
			{
				wait 0.1;	
			}			
		}
		
		self.is_attacking = 0;
	}

}

monitor_attack_button(plane)
{
	plane endon("a10_end_strafe");
	self endon("a10_end_strafe");
	self endon("disconnect");
	
	self.is_attacking = 0;
	while(IsDefined(plane))
	{
		if(self AttackButtonPressed())
			self.is_attacking = 1;
		else
			self.is_attacking = 0;
		wait 0.1;
	}
}

// should eventually unify
updateCannonShake( streakName )	// self == plane
{
	self.owner endon( "a10_cannon_stop" );
	self.owner endon ("disconnect");
	self endon( "death" );
	level endon( "game_ended" );
	
	config = level.planeConfigs[ streakName ];
		
	while (( self.ammoCount > 0 ) && self.owner.is_attacking && (IsDefined(self)))
	{
		Earthquake (0.2, CANNON_SHAKE_TIME, self.origin, 512);
		self.ammoCount -= 10;
		self.owner SetClientOmnvar( "ui_a10_cannon", self.ammoCount );
		barrelPoint = self GetTagOrigin( "tag_flash_attach" ) + 20 * AnglesToForward( self.angles );
		
		PlayFX( config.cannonFireVFX, barrelPoint );
		
		self.owner PlayRumbleOnEntity( config.cannonRumble );
		
		// this needs to match the cannon's fire rate in the gdt
		wait( 0.1 );
	}
	
	if(IsDefined(self))
		if(IsDefined(self.turret))
			self.turret TurretFireDisable();
}

ALTITUDE_WARNING_LIMIT = 10;
monitorAltitude( streakName, plane )
{
	plane endon( "end_remote" );
	plane endon( "death" );
	self endon( "disconnect" );
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


watchDisconnectPlane() //self = plane
{
	level endon( "game_ended" );
	level endon( "round_end_finished" );
	self endon("end_remote");
	
	self.owner waittill( "disconnect" );
	
	//println("plane disconnect");
	
	self.forceClean = true;
	self thread a10_explode();
	self thread endFlyby("disconnect");
	thread endStrafeSequence( KS_NAME );
}

watchDisconnect()
{
	level endon( "game_ended" );
	level endon( "round_end_finished" );
	self endon("cleared_intro");

	self waittill( "disconnect" );

	//self notify("a10_end_strafe");
	//self notify("switch_team");
	//self notify("end_remote");
	
	//println("player disconnect");
	
	if(IsDefined(self) && IsDefined(self.plane))
	{
		self.plane.forceClean = true;
		self.plane thread endFlyby(KS_NAME);
	}
	if(IsDefined(self))
		self endStrafeSequence( "team_switch" );
}

watchGameEnd()
{
	level endon( "round_end_finished" );
	self endon("end_remote");

	level waittill( "game_ended" );

	self notify("a10_end_strafe");
	
	if(IsDefined(self) && IsDefined(self.plane))
	{
		self.plane.forceClean = true;
		self.plane thread endFlyby(KS_NAME);
	}
	if(IsDefined(self))
		self endStrafeSequence( "team_switch" );
}

watchTeamSwitchPre()	// self == player
{
	level endon( "game_ended" );
	level endon( "round_end_finished" );
	self endon("cleared_intro");

	self waittill_any( "joined_team", "joined_spectators" );

	//self notify("a10_end_strafe");
	self notify("switch_team");
	self notify("end_remote");
	
	if(IsDefined(self.plane))
	{
		self.plane.forceClean = true;
		self.plane thread endFlyby(KS_NAME);
	}
	
	self endStrafeSequence( "team_switch" );
}

watchIntroCleared( streakName, plane ) // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon("end_remote");
	
	self waittill( "intro_cleared" );
	
	self thread monitorAltitude( streakname, plane );
	self thread monitorRocketFire2( streakName, plane );
	self thread monitorWeaponFire( streakName, plane );
	self thread watchRoundEnd( plane, streakName );	
	
	self thread watchEarlyExit( plane );
	self thread watchNuke( plane, KS_NAME);
	self thread watchTeamSwitchPost(plane, KS_NAME);
	
	//println("setting ui_a10");
	self SetClientOmnvar( "ui_a10", true );
	self ThermalVisionFOFOverlayOn();
}


watchEarlyExit( veh )	// self == player
{
	level endon( "round_end_finished" );
	level endon( "game_ended" );
	veh endon( "death" );
	veh endon( "a10_end_strafe" );
	
	veh thread maps\mp\killstreaks\_killstreaks::allowRideKillstreakPlayerExit("killstreakExit");
	
	veh waittill("killstreakExit");

//	PrintLn("Player exited the killstreak early");
	
	self notify("end_remote");
	veh notify("end_remote");
	
	veh.forceClean = true;
	veh thread a10_explode();
	self thread endStrafeSequence( KS_NAME );
	veh thread endFlyby( KS_NAME );
	
}

watchNukePlayer() // self == player
{
	self endon( "disconnect" );
	self endon( "end_remote");
	
	level waittill("nuke_death");
	self notify("ca_a10_nuked");
	
//	Println("player nuked");
	
	self thread endStrafeSequence( KS_NAME );
}

watchNuke( plane, streakName) // self == player
{
	//plane endon("death");
	plane endon("a10_end_strafe");
	self endon( "disconnect" );
	self endon( "end_remote");
	
	level waittill("nuke_death");
	self notify("ca_a10_nuked");
	
//	Println("plane nuked");
	
	self thread endStrafeSequence( KS_NAME );
	
	if(IsDefined(plane))
	{
		plane.forceClean = true;
		plane thread a10_explode();
		plane thread endFlyby( KS_NAME );
	}
	
}

watchTeamSwitchPost( plane, streakName )	// self == player
{
	plane endon( "death" );
	plane endon( "leaving" );	
	self endon( "disconnect" );
	level endon( "game_ended" );
	level endon( "round_end_finished" );

	// cut off the pre-team switch watcher
	self notify("cleared_intro");
	
	self waittill_any( "joined_team", "joined_spectators" );

	self notify("a10_end_strafe");
	self notify("end_remote");
	
	//	leave
	plane.forceClean = true;
	self thread endStrafeSequence( "team_switch" );
	plane thread a10_explode();
	plane thread endFlyby( streakName );
	
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
	plane.forceClean = true;
	plane thread endFlyby( streakName );
	plane thread a10_explode();
	self endStrafeSequence( "team_switch" );

}

// SETUP FUNCS

buildAllFlightPathsImpact()
{
	inBoundList = [];
	inBoundList[0] = 1;
	inBoundList[1] = 2;
	
	outBoundList = [];
	outBoundList[0] = 1;
	outBoundList[1] = 2;
	
	buildAllFlightPaths( inBoundList, outBoundList );
}

buildAllFlightPathsDefault()
{
//	PrintLn("Building default flight paths");
	
	// temp - do not check in - should be done per level
	inBoundList = [];
	inBoundList[0] = 1;
	inBoundList[1] = 1;
	
	outBoundList = [];
	outBoundList[0] = 1;
	outBoundList[1] = 1;
	
	buildAllFlightPaths( inBoundList, outBoundList );
}

buildAllFlightPaths( inBoundList, outBoundList )
{
	level.a10SplinesIn = inBoundList;
	level.a10SplinesOut = outBoundList;
}

//DAMAGE FUNCS

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
	
	self thread a10_explode();
}

// plane explode
a10_explode()
{
	if(IsDefined(self))
	{
		config = level.planeConfigs[ self.streakName ];
		
		PlayFX ( config.explodeVfx, self.origin );
		self Hide();
		
		// wait so killcams can work and things like that
		wait 20.0;
		
		//self Delete();
	}
}
