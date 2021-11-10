/*
	Ball Drone
	Author: Aaron Eady
	Description: The idea is to have a companion killstreak that stays with you and acts as a helper.
*/

#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\gametypes\_hostmigration;

STUNNED_TIME = 7.0;
Z_OFFSET = ( 0, 0, 90 );

BALL_DRONE_STAND_UP_OFFSET		= 118;
BALL_DRONE_CROUCH_UP_OFFSET		= 70;
BALL_DRONE_PRONE_UP_OFFSET		= 36;
BALL_DRONE_BACK_OFFSET			= 40;
BALL_DRONE_SIDE_OFFSET			= 40;
	
init()
{
	level.killStreakFuncs[ "ball_drone_radar" ] = ::tryUseBallDrone;
	level.killStreakFuncs[ "ball_drone_backup" ] = ::tryUseBallDrone;

	level.ballDroneSettings = [];

	level.ballDroneSettings[ "ball_drone_radar" ] 							= SpawnStruct();
	level.ballDroneSettings[ "ball_drone_radar" ].timeOut 					= 60.0;	
	level.ballDroneSettings[ "ball_drone_radar" ].health 					= 999999; // keep it from dying anywhere in code	
	level.ballDroneSettings[ "ball_drone_radar" ].maxHealth 				= 500; // this is what we check against for death	
	level.ballDroneSettings[ "ball_drone_radar" ].streakName 				= "ball_drone_radar";
	level.ballDroneSettings[ "ball_drone_radar" ].vehicleInfo				= "ball_drone_mp";
	level.ballDroneSettings[ "ball_drone_radar" ].modelBase 				= "vehicle_ball_drone_iw6";
	level.ballDroneSettings[ "ball_drone_radar" ].teamSplash 				= "used_ball_drone_radar";	
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_sparks 				= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_ims_sparks" );	
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_explode 				= LoadFX( "vfx/gameplay/explosions/vehicle/ball/vfx_exp_ball_drone" );	
	level.ballDroneSettings[ "ball_drone_radar" ].sound_explode 			= "ball_drone_explode";	
	level.ballDroneSettings[ "ball_drone_radar" ].voDestroyed 				= "nowl_destroyed";	
	level.ballDroneSettings[ "ball_drone_radar" ].voTimedOut 				= "nowl_gone";	
	level.ballDroneSettings[ "ball_drone_radar" ].xpPopup 					= "destroyed_ball_drone_radar";	
	level.ballDroneSettings[ "ball_drone_radar" ].playFXCallback 			= ::radarBuddyPlayFx;
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light1				= [];
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light2				= [];
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light3				= [];
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light4				= [];
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light1[ "enemy" ] 	= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light2[ "enemy" ] 	= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light3[ "enemy" ] 	= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light4[ "enemy" ] 	= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light1[ "friendly" ] = LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light2[ "friendly" ] = LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light3[ "friendly" ] = LoadFX( "fx/misc/light_mine_blink_friendly" );
	level.ballDroneSettings[ "ball_drone_radar" ].fxId_light4[ "friendly" ] = LoadFX( "fx/misc/light_mine_blink_friendly" );

	level.ballDroneSettings[ "ball_drone_backup" ] 							= SpawnStruct();
	level.ballDroneSettings[ "ball_drone_backup" ].timeOut 					= 90.0;	
	level.ballDroneSettings[ "ball_drone_backup" ].health 					= 999999; // keep it from dying anywhere in code	
	level.ballDroneSettings[ "ball_drone_backup" ].maxHealth 				= 500; // this is what we check against for death	
	level.ballDroneSettings[ "ball_drone_backup" ].streakName 				= "ball_drone_backup";
	level.ballDroneSettings[ "ball_drone_backup" ].vehicleInfo 				= "backup_drone_mp";
	level.ballDroneSettings[ "ball_drone_backup" ].modelBase 				= "vehicle_drone_backup_buddy";
	level.ballDroneSettings[ "ball_drone_backup" ].teamSplash 				= "used_ball_drone_radar";	
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_sparks 				= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_ims_sparks" );	
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_explode 			= LoadFX( "fx/explosions/bouncing_betty_explosion" );	
	level.ballDroneSettings[ "ball_drone_backup" ].sound_explode 			= "ball_drone_explode";	
	level.ballDroneSettings[ "ball_drone_backup" ].voDestroyed 				= "vulture_destroyed";	
	level.ballDroneSettings[ "ball_drone_backup" ].voTimedOut 				= "vulture_gone";	
	level.ballDroneSettings[ "ball_drone_backup" ].xpPopup 					= "destroyed_ball_drone";	
	level.ballDroneSettings[ "ball_drone_backup" ].weaponInfo 				= "ball_drone_gun_mp";
	level.ballDroneSettings[ "ball_drone_backup" ].weaponModel 				= "vehicle_drone_backup_buddy_gun";
	level.ballDroneSettings[ "ball_drone_backup" ].weaponTag 				= "tag_turret_attach";	
	level.ballDroneSettings[ "ball_drone_backup" ].sound_weapon 			= "weap_p99_fire_npc";	
	level.ballDroneSettings[ "ball_drone_backup" ].sound_targeting 			= "ball_drone_targeting";	
	level.ballDroneSettings[ "ball_drone_backup" ].sound_lockon 			= "ball_drone_lockon";	
	level.ballDroneSettings[ "ball_drone_backup" ].sentryMode 				= "sentry";	
	level.ballDroneSettings[ "ball_drone_backup" ].visual_range_sq 			= 1200 * 1200; // distance radius it will acquire targets (see)
	//level.ballDroneSettings[ "ball_drone_backup" ].target_recognition 	= 0.5; // percentage of the player's body it sees before it labels him as a target
	level.ballDroneSettings[ "ball_drone_backup" ].burstMin 				= 10;
	level.ballDroneSettings[ "ball_drone_backup" ].burstMax 				= 20;
	level.ballDroneSettings[ "ball_drone_backup" ].pauseMin 				= 0.15;
	level.ballDroneSettings[ "ball_drone_backup" ].pauseMax 				= 0.35;	
	level.ballDroneSettings[ "ball_drone_backup" ].lockonTime 				= 0.25;	
	level.ballDroneSettings[ "ball_drone_backup" ].playFXCallback 			= ::backupBuddyPlayFX;
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_light1				= [];
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_light1[ "enemy" ] 	= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_light_detonator_blink" );
	level.ballDroneSettings[ "ball_drone_backup" ].fxId_light1[ "friendly" ] = LoadFX( "fx/misc/light_mine_blink_friendly" );

	//ballDrone_setAirNodeMesh();
	
	level.ballDrones = [];

/#
	SetDevDvarIfUninitialized( "scr_balldrone_timeout", 60.0 );
	SetDevDvarIfUninitialized( "scr_balldrone_debug_position", 0 );
	SetDevDvarIfUninitialized( "scr_balldrone_debug_position_forward", 50.0 );
	SetDevDvarIfUninitialized( "scr_balldrone_debug_position_height", 35.0 );
	SetDevDvarIfUninitialized( "scr_balldrone_debug_path", 0 );
#/
}

tryUseBallDrone( lifeId, streakName ) // self == player
{
	return useBallDrone( streakName );
}

useBallDrone( ballDroneType )
{
	numIncomingVehicles = 1;
	if( self isUsingRemote() )
	{
		return false;
	}	
	else if( exceededMaxBallDrones() )
	{
		self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;	
	}
	else if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount + numIncomingVehicles >= maxVehiclesAllowed() )
	{
		self IPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}		
	else if( IsDefined( self.ballDrone ) )
	{
		self IPrintLnBold( &"KILLSTREAKS_COMPANION_ALREADY_EXISTS" );
		return false;
	}
	else if ( IsDefined ( self.drones_disabled ))
	{
		self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE" );
		return false;
	}
	
	// increment the faux vehicle count before we spawn the vehicle so no other vehicles try to spawn
	incrementFauxVehicleCount();

	ballDrone = createBallDrone( ballDroneType );
	if( !IsDefined( ballDrone ) )
	{
		if(is_aliens())
			self.drone_failed = true;
		else
			self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE" );
		
		// decrement the faux vehicle count since this failed to spawn
		decrementFauxVehicleCount();

		return false;	
	}

	self.ballDrone = ballDrone;
	self thread startBallDrone( ballDrone );

	//level thread teamPlayerCardSplash( level.ballDroneSettings[ ballDroneType ].teamSplash, self, self.team );
	
	if ( ballDroneType == "ball_drone_backup" && maps\mp\agents\_agent_utility::getNumOwnedActiveAgentsByType( self, "dog" ) > 0 )
	{
		self maps\mp\gametypes\_missions::processChallenge( "ch_twiceasdeadly" );
	}

	return true;
}

createBallDrone( ballDroneType ) // self == player
{
	// Node way
	//closestStartNode = ballDrone_getClosestNode( self.origin );	
	//if( IsDefined( closestStartNode.angles ) )
	//	startAng = closestStartNode.angles;
	//else
	//	startAng = ( 0, 0, 0);

	//closestNode = ballDrone_getClosestNode( self.origin );

	//forward = AnglesToForward( self.angles );
	//targetPos = closestNode.origin;

	//startPos = closestStartNode.origin;

	// new way
	startAng = self.angles;
	forward = AnglesToForward( self.angles );
	startPos = self.origin + ( forward * 100 ) + Z_OFFSET;
	playerStartPos = self.origin + Z_OFFSET;
	trace = BulletTrace( playerStartPos, startPos, false );
	// make sure we aren't starting in geo
	attempts = 3;
	while( trace[ "surfacetype" ] != "none" && attempts > 0 )
	{
		startPos = self.origin + ( VectorNormalize( playerStartPos - trace[ "position" ] ) * 5 );
		trace = BulletTrace( playerStartPos, startPos, false );
		attempts--;
		wait( 0.05 );
	}
	if( attempts <= 0 )
		return;
	
	right = AnglesToRight( self.angles );
	targetPos = self.origin + ( right * 20 ) + Z_OFFSET;
	trace = BulletTrace( startPos, targetPos, false );
	// make sure we aren't sending it into geo
	attempts = 3;
	while( trace[ "surfacetype" ] != "none" && attempts > 0 )
	{
		targetPos = startPos + ( VectorNormalize( startPos - trace[ "position" ] ) * 5 );
		trace = BulletTrace( startPos, targetPos, false );
		attempts--;
		wait( 0.05 );
	}
	if( attempts <= 0 )
		return;
	
	drone = SpawnHelicopter( self, startPos, startAng, level.ballDroneSettings[ ballDroneType ].vehicleInfo, level.ballDroneSettings[ ballDroneType ].modelBase );
	if( !IsDefined( drone ) )
		return;

	drone EnableAimAssist();
	
	drone MakeVehicleNotCollideWithPlayers( true );
	
	drone addToBallDroneList();
	drone thread removeFromBallDroneListOnDeath();

	drone.health = level.ballDroneSettings[ ballDroneType ].health;
	drone.maxHealth = level.ballDroneSettings[ ballDroneType ].maxHealth;
	drone.damageTaken = 0; // how much damage has it taken

	drone.speed = 140;
	drone.followSpeed = 140;
	drone.owner = self;
	drone.team = self.team;
	drone Vehicle_SetSpeed( drone.speed, 16, 16 );
	drone SetYawSpeed( 120, 90 );
	drone SetNearGoalNotifyDist( 16 );
	drone.ballDroneType = ballDroneType;
	drone SetHoverParams( 30, 10, 5 );
	drone SetOtherEnt(self);
	
	// make expendable if it is non-lethal drone
	drone make_entity_sentient_mp( self.team, balldroneType != "ball_drone_backup" );
	if ( IsSentient( drone ) )
	{
		drone SetThreatBiasGroup( "DogsDontAttack" );
	}
	if ( !is_aliens() )
	{
		if( level.teamBased )
			drone maps\mp\_entityheadicons::setTeamHeadIcon( drone.team, ( 0, 0, 25 ) );
		else
			drone maps\mp\_entityheadicons::setPlayerHeadIcon( drone.owner, ( 0, 0, 25 ) );
	}
	// for special settings on different types of drones
	maxPitch = 45;
	maxRoll = 45;
	switch( ballDroneType )
	{
	case "ball_drone_radar":
		maxPitch = 90;
		maxRoll = 90;
		
		radar = Spawn( "script_model", self.origin );
		radar.team = self.team;
		radar MakePortableRadar( self );
		drone.radar = radar;
		drone thread radarMover();
		drone.ammo = 99999; // trophy "ammo" for how many things it can shot down before dying
		drone.cameraOffset = distance( drone.origin, drone GetTagOrigin( "camera_jnt" ) ) ;
		drone thread maps\mp\gametypes\_trophy_system::trophyActive( self );
		drone thread ballDrone_handleDamage();
		break;

	case "ball_drone_backup":
	case "alien_ball_drone":
	case "alien_ball_drone_1":
	case "alien_ball_drone_2":
	case "alien_ball_drone_3":
	case "alien_ball_drone_4":			
		turret = SpawnTurret( "misc_turret", drone GetTagOrigin( level.ballDroneSettings[ ballDroneType ].weaponTag ), level.ballDroneSettings[ ballDroneType ].weaponInfo );
		turret LinkTo( drone, level.ballDroneSettings[ ballDroneType ].weaponTag );
		turret SetModel( level.ballDroneSettings[ ballDroneType ].weaponModel );
		turret.angles = drone.angles;
		turret.owner = drone.owner;
		turret.team = self.team;
		turret MakeTurretInoperable();
		turret MakeUnusable();
		turret.vehicle = drone;	

		turret.health = level.ballDroneSettings[ ballDroneType ].health;
		turret.maxHealth = level.ballDroneSettings[ ballDroneType ].maxHealth;
		turret.damageTaken = 0; // how much damage has it taken
		
		// when the turret is idle it needs to look at something behind the player
		idleTargetPos = self.origin + ( forward * -100 ) + ( 0, 0, 40 ); 
		turret.idleTarget = Spawn( "script_origin", idleTargetPos );
		turret.idleTarget.targetname = "test";
		self thread idleTargetMover( turret.idleTarget );

		if( level.teamBased )
			turret SetTurretTeam( self.team );
		turret SetMode( level.ballDroneSettings[ ballDroneType ].sentryMode );
		turret SetSentryOwner( self );
		turret SetLeftArc( 180 );
		turret SetRightArc( 180 );
		turret SetBottomArc( 50 );
		turret thread ballDrone_attackTargets();
		turret SetTurretMinimapVisible( true, "buddy_turret" );

		killCamOrigin = ( drone.origin + ( ( AnglesToForward( drone.angles ) * -10 ) + ( AnglesToRight( drone.angles ) * -10 )  ) ) + ( 0, 0, 10 );
		turret.killCamEnt = Spawn( "script_model", killCamOrigin );
		turret.killCamEnt SetScriptMoverKillCam( "explosive" );
		turret.killCamEnt LinkTo( drone );
		//turret.killCamEnt LinkTo( drone, "tag_origin" );

		drone.turret = turret; 
		turret.parent = drone;
		
		drone thread ballDrone_backup_handleDamage();
		drone.turret thread ballDrone_backup_turret_handleDamage();
		
		// this is for using the vehicle's turret
		//drone SetVehWeapon( level.ballDroneSettings[ ballDroneType ].weaponInfo );
		//drone thread ballDrone_targeting();
		//drone thread ballDrone_attackTargets();
		break;

	default:
		break;
	}

	drone SetMaxPitchRoll( maxPitch, maxRoll );	

	drone.targetPos = targetPos;
	//drone.currentNode = closestNode;

	drone.attract_strength = 10000;
	drone.attract_range = 150;
	if(!(is_aliens() && isdefined(level.script) && level.script == "mp_alien_last"))
		drone.attractor = Missile_CreateAttractorEnt( drone, drone.attract_strength, drone.attract_range );

	drone.hasDodged = false;
	drone.stunned = false;
	drone.inactive = false;

	drone thread watchEMPDamage();
	drone thread ballDrone_watchDeath();
	drone thread ballDrone_watchTimeout();
	drone thread ballDrone_watchOwnerLoss();
	drone thread ballDrone_watchOwnerDeath();
	drone thread ballDrone_watchRoundEnd();
	drone thread ballDrone_enemy_lightFX();
	drone thread ballDrone_friendly_lightFX();

	// Handle moving platform. 
	data = SpawnStruct();
	data.validateAccurateTouching = true;
	data.deathOverrideCallback = ::balldrone_moving_platform_death;
	drone thread maps\mp\_movers::handle_moving_platforms( data );

	drone.owner maps\mp\_matchdata::logKillstreakEvent( level.ballDroneSettings[ drone.ballDroneType ].streakName, drone.targetPos );	

	return drone;
}

balldrone_moving_platform_death( data )
{
	if ( !IsDefined( data.lastTouchedPlatform.destroyDroneOnCollision ) || data.lastTouchedPlatform.destroyDroneOnCollision )
	{
		self notify( "death" );
	}
}

idleTargetMover( ent ) // self == player
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	ent endon( "death" );

	// keep the idleTarget entity behind the player so the turret is always default looking back there
	forward = AnglesToForward( self.angles );
	while( true )
	{
		if( isReallyAlive( self ) && !self isUsingRemote() && AnglesToForward( self.angles ) != forward )
		{
			forward = AnglesToForward( self.angles );
			pos = self.origin + ( forward * -100 ) + ( 0, 0, 40 ); 
			ent MoveTo( pos, 0.5 );
		}
		wait( 0.5 );
	}
}

ballDrone_enemy_lightFX() // self == drone
{
	// non-looping fx

	self endon( "death" );
	settings = level.ballDroneSettings[ self.ballDroneType ];

	while ( true )
	{
		foreach( player in level.players )
		{
			if( IsDefined( player ) )
			{
				if( level.teamBased )
				{
					if( player.team != self.team )
						self [[ settings.playFXCallback ]]( "enemy", player );
				}
				else
				{
					if( player != self.owner )
						self [[ settings.playFXCallback ]]( "enemy", player );
				}
			}
		}

		wait( 1.0 );
	}
}

ballDrone_friendly_lightFX() // self == drone
{
	// looping fx

	self endon( "death" );
	settings = level.ballDroneSettings[ self.ballDroneType ];

	foreach( player in level.players )
	{
		if( IsDefined( player ) )
		{
			if( level.teamBased )
			{
				if( player.team == self.team )
					self [[ settings.playFXCallback ]]( "friendly", player );
			}
			else
			{
				if( player == self.owner )
					self [[ settings.playFXCallback ]]( "friendly", player );
			}
		}
	}

	self thread watchConnectedPlayFX();
	self thread watchJoinedTeamPlayFX();
}

backupBuddyPlayFX( fof, player ) // self == drone
{
	settings = level.ballDroneSettings[ self.ballDroneType ];

	PlayFXOnTagForClients( settings.fxId_light1[ fof ], self.turret, "tag_fx", player );
	PlayFXOnTagForClients( settings.fxId_light1[ fof ], self, "tag_fx", player );
}

radarBuddyPlayFx( fof, player ) // self == drone
{
	settings = level.ballDroneSettings[ self.ballDroneType ];

	PlayFXOnTagForClients( settings.fxId_light1[ fof ], self, "tag_fx", player );
	PlayFXOnTagForClients( settings.fxId_light2[ fof ], self, "tag_fx1", player );
	PlayFXOnTagForClients( settings.fxId_light3[ fof ], self, "tag_fx2", player );
	PlayFXOnTagForClients( settings.fxId_light4[ fof ], self, "tag_fx3", player );
}

watchConnectedPlayFX() // self == drone
{
	self endon( "death" );

	// play fx for late comers
	while( true )
	{
		level waittill( "connected", player );
		player waittill( "spawned_player" );

		settings = level.ballDroneSettings[ self.ballDroneType ];
	
		if( IsDefined( player ) )
		{
			if( level.teamBased )
			{
				if( player.team == self.team )
					self [[ settings.playFXCallback ]]( "friendly", player );
				else
					self [[ settings.playFXCallback ]]( "enemy", player );
			}
			else
			{
				if( player == self.owner )
					self [[ settings.playFXCallback ]]( "friendly", player );
				else
					self [[ settings.playFXCallback ]]( "enemy", player );
			}
		}
	}
}

watchJoinedTeamPlayFX() // self == drone
{
	self endon( "death" );

	// play fx for team changers
	while( true )
	{
		level waittill( "joined_team", player );
		player waittill( "spawned_player" );

		settings = level.ballDroneSettings[ self.ballDroneType ];

		if( IsDefined( player ) )
		{
			if( level.teamBased )
			{
				if( player.team == self.team )
					self [[ settings.playFXCallback ]]( "friendly", player );
				else
					self [[ settings.playFXCallback ]]( "enemy", player );
			}
			else
			{
				if( player == self.owner )
					self [[ settings.playFXCallback ]]( "friendly", player );
				else
					self [[ settings.playFXCallback ]]( "enemy", player );
			}
		}
	}
}

startBallDrone( ballDrone ) // self == player
{			
	level endon( "game_ended" );
	ballDrone endon( "death" );

	switch( ballDrone.ballDroneType )
	{
	case "ball_drone_backup":
	case "alien_ball_drone":
	case "alien_ball_drone_1":
	case "alien_ball_drone_2":
	case "alien_ball_drone_3":
	case "alien_ball_drone_4":	
		// watch the player's back
		if( IsDefined( ballDrone.turret ) && IsDefined( ballDrone.turret.idleTarget ) )
			ballDrone SetLookAtEnt( ballDrone.turret.idleTarget );
		else
			ballDrone SetLookAtEnt( self );
		break;

	default:
		// look at the player
		ballDrone SetLookAtEnt( self );
		break;
	}

	//	go to pos
	targetOffset	= (0, 0, BALL_DRONE_STAND_UP_OFFSET);
	ballDrone SetDroneGoalPos( self, targetOffset );
	ballDrone waittill( "near_goal" );
	ballDrone Vehicle_SetSpeed( ballDrone.speed, 10, 10 );	
	ballDrone waittill( "goal" );	

	//	begin following player	
	ballDrone thread ballDrone_followPlayer();
}

ballDrone_followPlayer() // self == drone
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	if( !IsDefined( self.owner ) )
	{
		self thread ballDrone_leave();
		return;
	}

	self.owner endon( "disconnect" );	
	self endon( "owner_gone" );

	self Vehicle_SetSpeed( self.followSpeed, 10, 10 );
	previousOrigin = ( 0, 0, 0 );
	destRadiusSq = 64 * 64;
	
	self thread low_entries_watcher();
	
	while( true )
	{
		if( IsDefined( self.owner ) && IsAlive( self.owner ) )
		{
			// check to see if the player has moved
			//	make sure the turret isn't currently trying to shoot anyone
			//	check if player is still within a radius
			if( self.owner.origin != previousOrigin &&
			   	DistanceSquared( self.owner.origin, previousOrigin ) > destRadiusSq )
			{
				if( self.ballDroneType == "ball_drone_backup" || self.ballDroneType == "alien_ball_drone" || self.ballDroneType == "alien_ball_drone_1" || self.ballDroneType == "alien_ball_drone_2" || self.ballDroneType == "alien_ball_drone_3" || self.ballDroneType == "alien_ball_drone_4" )
				{
					if( !IsDefined( self.turret GetTurretTarget( false ) ) )
					{
						previousOrigin = self.owner.origin;
						ballDrone_moveToPlayer();
						continue;
					}
				}
				else
				{
					previousOrigin = self.owner.origin;
					ballDrone_moveToPlayer();
					continue;
				}
			}
		}
		wait( 1 );
	}
}

ballDrone_moveToPlayer() // self == drone
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self endon( "owner_gone" );

	self notify( "ballDrone_moveToPlayer" );
	self endon( "ballDrone_moveToPlayer" );

	
	// collect the ideal offsets from the player
	backOffset = BALL_DRONE_BACK_OFFSET;
	
	sideOffset = BALL_DRONE_SIDE_OFFSET;
	
	heightOffset = BALL_DRONE_STAND_UP_OFFSET;
	switch( self.owner getStance() )
	{
		case "stand":
			heightOffset = BALL_DRONE_STAND_UP_OFFSET;
			break;
		case "crouch":
			heightOffset = BALL_DRONE_CROUCH_UP_OFFSET;
			break;
		case "prone":
			heightOffset = BALL_DRONE_PRONE_UP_OFFSET;
			break;
	}
	
	// If ball drone is touching a low_entry volume, we adjust the height by a custom offset to allow for low clearance situations
	if ( IsDefined( self.low_entry ) )
		heightOffset = heightOffset * self.low_entry;
	
	targetOffset	= (sideOffset, backOffset, heightOffset);
	
/#
	if( GetDvarInt( "scr_balldrone_debug_position" ) )
	{
		targetOffset = (0, -1*GetDvarFloat( "scr_balldrone_debug_position_forward" ), GetDvarFloat( "scr_balldrone_debug_position_height" ) );
	}
#/

	// ask code to navigate us as close as possible to the offset from the owner, set us as in-transit and start a thread waiting for us to get to the goal
	self SetDroneGoalPos( self.owner, targetOffset );
	self.inTransit = true;
	self thread ballDrone_watchForGoal();
}

/#
debugDrawDronePath()
{
	self endon( "death" );
	self endon( "hit_goal" );
	
	self notify( "debugDrawDronePath" );
	self endon( "debugDrawDronePath" );
	
	while( true )
	{
		nodePath = GetNodesOnPath( self.owner.origin, self.origin );
		if( IsDefined( nodePath ) )
		{
			for( i = 0; i < nodePath.size; i++ )
			{
				if( IsDefined( nodePath[ i + 1 ] ) )
				   Line( nodePath[ i ].origin + Z_OFFSET, nodePath[ i + 1 ].origin + Z_OFFSET, ( 1, 0, 0 ) );
			}
		}
		wait( 0.05 );
	}
}
#/
	
ballDrone_watchForGoal() // self == drone
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self endon( "owner_gone" );
	
	self notify( "ballDrone_watchForGoal" );
	self endon( "ballDrone_watchForGoal" );

	result = self waittill_any_return( "goal", "near_goal", "hit_goal" );
	self.inTransit = false;
	self.inactive = false;
	self notify( "hit_goal" );		
}

radarMover() // self == drone
{
	level endon("game_ended");
	self endon( "death" );

	while( true )
	{
		if( IsDefined( self.stunned ) && self.stunned )
		{
			wait( 0.5 );
			continue;
		}
		if( IsDefined( self.inactive ) && self.inactive )
		{
			wait( 0.5 );
			continue;
		}

		if( IsDefined( self.radar ) )
			self.radar MoveTo( self.origin, 0.5 );
			
		wait( 0.5 );
	}
}

low_entries_watcher()
{
	level endon( "game_ended" );
	self endon( "gone" );
	self endon( "death" );
	
	// Users can add as many trigger volumes as they need for tight spaces.  KVPs needed are:
	// targetname: low_entry
	// script_parameters: X (where X is a number, 0-1, that represents a fraction of the default height that you need the drone to lower to while inside the volume
	//
	// If no script_parameters are defined, it will default to half the default height
	low_entries = GetEntArray( "low_entry", "targetname" );
	
	while( low_entries.size > 0 )  // bails on the thread if there are no low_entry volumes present
	{
		foreach( trigger in low_entries )
		{
			while( self IsTouching( trigger ) || self.owner IsTouching( trigger ) )
			{
				if ( IsDefined( trigger.script_parameters ) )
					self.low_entry = float( trigger.script_parameters );
				else
					self.low_entry = 0.5;
				
				wait 0.1;
			}
	
			self.low_entry = undefined;
		}
		
		wait 0.1;
	}
}
	

/* ============================
State Trackers
============================ */

ballDrone_watchDeath() // self == drone
{
	level endon( "game_ended" );
	self endon( "gone" );

	self waittill( "death" );

	self thread ballDroneDestroyed();
}


ballDrone_watchTimeout() // self == drone
{
	level endon ( "game_ended" );
	self endon( "death" );
	self.owner endon( "disconnect" );
	self endon( "owner_gone" );

	config = level.ballDroneSettings[ self.ballDroneType ];
	timeout = config.timeOut;
	if ( is_aliens() && isDefined( level.ball_drone_alien_timeout_func ) && isDefined( self.owner ) )
	{
		timeout = self [[level.ball_drone_alien_timeout_func]]( timeout, self.owner );
	}
	if ( !is_aliens() )
	{
/#
		timeout = GetDvarFloat( "scr_balldrone_timeout" );
#/
	}
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( timeout );
	if( IsDefined( self.owner ) && !is_aliens()  )
		self.owner leaderDialogOnPlayer( config.voTimedOut );
	
	self thread ballDrone_leave();
}


ballDrone_watchOwnerLoss() // self == drone
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	self.owner waittill( "killstreak_disowned" );	

	self notify( "owner_gone" );
	//	leave
	self thread ballDrone_leave();
}

ballDrone_watchOwnerDeath() // self == drone
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	while( true )
	{
		self.owner waittill( "death" );	

		if( getGametypeNumLives() && self.owner.pers[ "deaths" ] == getGametypeNumLives() )
			self thread ballDrone_leave();
//		else
//			self.inactive = true;
	}
}

ballDrone_watchRoundEnd() // self == drone
{
	self endon( "death" );
	self endon( "leaving" );	
	self.owner endon( "disconnect" );
	self endon( "owner_gone" );

	level waittill_any( "round_end_finished", "game_ended" );

	//	leave
	self thread ballDrone_leave();
}

ballDrone_leave() // self == drone
{
	self endon( "death" );
	self notify( "leaving" );

	ballDroneExplode();
}

/* ============================
End State Trackers
============================ */

/* ============================
Damage and Death Monitors
============================ */

ballDrone_handleDamage() // self == drone
{
	self maps\mp\gametypes\_damage::monitorDamage(
		self.maxHealth,
		"ball_drone",
		::handleDeathDamage,
		::modifyDamage,
		true	// isKillstreak
	);
}

ballDrone_backup_handleDamage() // self == drone
{
	self endon( "death" );
	level endon( "game_ended" );

	self SetCanDamage( true );

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		self maps\mp\gametypes\_damage::monitorDamageOneShot(
			damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon,
			"ball_drone",
			::handleDeathDamage,
			::modifyDamage,
			true	// isKillstreak
		);
	}
}

ballDrone_backup_turret_handleDamage() // self == turret attached to drone
{
	self endon( "death" );
	level endon( "game_ended" );

	self MakeTurretSolid();
	self SetCanDamage( true );
	
	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		// if this is explosive damage then don't do it on the turret because the tank will do it, unless this is an airstrike or stealth bomb
		if( IsDefined( self.parent ) )
		{
			self.parent maps\mp\gametypes\_damage::monitorDamageOneShot(
				damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon,
				"ball_drone",
				::handleDeathDamage,
				::modifyDamage,
				true	// isKillstreak
			);
		}
	}
}


modifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
	
	// for stuns
	// self thread ballDrone_stunned(); 
	
	// modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	// modifiedDamage = self maps\mp\gametypes\_damage::handleEmpDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleGrenadeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	return modifiedDamage;
}

handleDeathDamage( attacker, weapon, type, damage )	// self == drone
{
	config = level.ballDroneSettings[ self.ballDroneType ];
	self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, damage, config.xpPopup, config.voDestroyed  );
	
	if ( self.ballDroneType == "ball_drone_backup" )
	{
		attacker maps\mp\gametypes\_missions::processChallenge( "ch_vulturekiller" );
	}
	/*
	else if ( self.ballDroneType == "ball_drone_radar" )
	{
		attacker maps\mp\gametypes\_missions::processChallenge( "???" );
	}
	*/
}

watchEMPDamage()
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		// this handles any flash or concussion damage
		self waittill( "emp_damage", attacker, duration );

		self ballDrone_stunned( duration );
	}
}

ballDrone_stunned( duration ) // self == drone
{
	self notify( "ballDrone_stunned" );
	self endon( "ballDrone_stunned" );

	self endon( "death" );
	self.owner endon( "disconnect" );
	level endon( "game_ended" );

	self.stunned = true;
	
	if( IsDefined( level.ballDroneSettings[ self.ballDroneType ].fxId_sparks ) )
	{
		PlayFXOnTag( level.ballDroneSettings[ self.ballDroneType ].fxId_sparks, self, "tag_origin" );
	}

	// for the portable radar we need to destroy it and recreate it
	if( self.ballDroneType == "ball_drone_radar" )
	{
		if( IsDefined( self.radar ) )
			self.radar delete();
	}
	
	if ( IsDefined( self.turret ) )
	{
		self.turret notify( "turretstatechange" );
	}

	wait( duration );

	self.stunned = false;

	if( self.ballDroneType == "ball_drone_radar" )
	{
		radar = Spawn( "script_model", self.origin );
		radar.team = self.team;
		radar MakePortableRadar( self.owner );
		self.radar = radar;
	}
	
	if ( IsDefined( self.turret ) )
	{
		self.turret notify( "turretstatechange" );
	}
}

ballDroneDestroyed() // self == drone
{
	if( !IsDefined( self ) )
		return;
	
	// TODO: could put some drama here as it crashes

	ballDroneExplode();
}

ballDroneExplode() // self == drone
{
	if( IsDefined( level.ballDroneSettings[ self.ballDroneType ].fxId_explode ) )
	{
		PlayFX( level.ballDroneSettings[ self.ballDroneType ].fxId_explode, self.origin );
	}

	if( IsDefined( level.ballDroneSettings[ self.ballDroneType ].sound_explode ) )
	{
		self PlaySound( level.ballDroneSettings[ self.ballDroneType ].sound_explode );
	}

	self notify( "explode" );

	self removeBallDrone();
}

removeBallDrone() // self == drone
{	
	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();

	if( IsDefined( self.radar ) )
		self.radar delete();

	if( IsDefined( self.turret ) )
	{
		self.turret SetTurretMinimapVisible( false );

		if( IsDefined( self.turret.idleTarget ) )
			self.turret.idleTarget delete();

		if( IsDefined( self.turret.killCamEnt ) )
			self.turret.killCamEnt delete();

		self.turret delete();
	}

	if( IsDefined( self.owner ) && IsDefined( self.owner.ballDrone ) )
		self.owner.ballDrone = undefined;

	self delete();	
}

/* ============================
End Damage and Death Monitors
============================ */

/* ============================
List and Count Management
============================ */

addToBallDroneList()
{
	level.ballDrones[ self GetEntityNumber() ] = self;	
}

removeFromBallDroneListOnDeath()
{
	entNum = self GetEntityNumber();

	self waittill ( "death" );

	level.ballDrones[ entNum ] = undefined;
}

exceededMaxBallDrones()
{
	if( level.ballDrones.size >= maxVehiclesAllowed() )
		return true;	
	else
		return false;	
}

/* ============================
End List and Count Management
============================ */

/* ============================
Turret Logic Functions
============================ */

ballDrone_attackTargets() // self == turret
{
	self.vehicle endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		self waittill( "turretstatechange" );

		if( self IsFiringTurret() && 
			( IsDefined( self.vehicle.stunned ) && !self.vehicle.stunned ) &&
			( IsDefined( self.vehicle.inactive ) && !self.vehicle.inactive ) )
		{
			self LaserOn();
			self doLockOn( level.ballDroneSettings[ self.vehicle.ballDroneType ].lockonTime );
			self thread ballDrone_burstFireStart();
		}
		else
		{
			self LaserOff();
			self thread ballDrone_burstFireStop();
		}
	}
}

ballDrone_burstFireStart() // self == turret
{
	self.vehicle endon( "death" );
	self endon( "stop_shooting" );
	level endon( "game_ended" );

	vehicle = self.vehicle;
	
	fireTime = WeaponFireTime( level.ballDroneSettings[ vehicle.ballDroneType ].weaponInfo );
	minShots = level.ballDroneSettings[ vehicle.ballDroneType ].burstMin;
	maxShots = level.ballDroneSettings[ vehicle.ballDroneType ].burstMax;
	minPause = level.ballDroneSettings[ vehicle.ballDroneType ].pauseMin;
	maxPause = level.ballDroneSettings[ vehicle.ballDroneType ].pauseMax;
	
	if ( is_aliens() && level.ballDroneSettings[ vehicle.ballDroneType ].weaponInfo  == "alien_ball_drone_gun4_mp" )
		self childthread fire_rocket();
	
	while( true )
	{		
		numShots = RandomIntRange( minShots, maxShots + 1 );
		for( i = 0; i < numShots; i++ )
		{			
			// don't shoot when inactive
			if( IsDefined( vehicle.inactive ) && vehicle.inactive )
				break;

			targetEnt = self GetTurretTarget( false );
			if( IsDefined( targetEnt ) && canBeTargeted( targetEnt ) )
			{
				vehicle SetLookAtEnt( targetEnt );
				//self PlaySound( level.ballDroneSettings[ vehicle.ballDroneType ].sound_weapon );
				self ShootTurret();
				//MagicBullet( level.ballDroneSettings[ vehicle.ballDroneType ].projectileInfo, self GetTagOrigin( "tag_flash" ), targetEnt.origin, self.owner );
			}
					
			wait( fireTime );
		}

		wait( RandomFloatRange( minPause, maxPause ) );
	}
}

fire_rocket( )
{
	while ( true )
	{
		targetEnt = self GetTurretTarget( false );
		if( IsDefined( targetEnt ) && canBeTargeted( targetEnt ) )
		{
			MagicBullet( "alienvulture_mp", self GetTagOrigin( "tag_flash" ), targetEnt.origin, self.owner );
		}
		waittime = WeaponFireTime( "alienvulture_mp" );
		
		if ( isDefined( level.ball_drone_faster_rocket_func ) && isDefined( self.owner ) )
		{
			waittime = self [[level.ball_drone_faster_rocket_func]]( waittime, self.owner );
		}
		
		wait WeaponFireTime( "alienvulture_mp" );
	}
}
	
doLockOn( time ) // self == turret
{
	// lock-on time
	while( time > 0 )
	{
		self PlaySound( level.ballDroneSettings[ self.vehicle.ballDroneType ].sound_targeting );

		wait( 0.5 );
		time -= 0.5;
	}

	// locked on
	self PlaySound( level.ballDroneSettings[ self.vehicle.ballDroneType ].sound_lockon );
}

ballDrone_burstFireStop() // self == turret
{
	self notify( "stop_shooting" );
	if( IsDefined( self.idleTarget ) )
		self.vehicle SetLookAtEnt( self.idleTarget );
}

canBeTargeted( ent ) // self == turret
{
	canTarget = true;

	if( IsPlayer( ent ) )
	{
		if( !isReallyAlive( ent ) || ent.sessionstate != "playing" )
			return false;
	}

	if( level.teamBased && IsDefined( ent.team ) && ent.team == self.team )
		return false;

	if( IsDefined( ent.team ) && ent.team == "spectator" )
		return false;

	if( IsPlayer( ent ) && ent == self.owner )
		return false;

	if( IsPlayer( ent ) && IsDefined( ent.spawntime ) && ( GetTime() - ent.spawntime ) / 1000 <= 5 )
		return false;

	if( IsPlayer( ent ) && ent _hasPerk( "specialty_blindeye" ) )
		return false;

	if( DistanceSquared( ent.origin, self.origin ) > level.ballDroneSettings[ self.vehicle.ballDroneType ].visual_range_sq )
		return false;

	turret_point = self GetTagOrigin( "tag_flash" );

	return canTarget;
}