#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;


UAV_REMOTE_MAX_PAST_RANGE 		= 200;
UAV_REMOTE_MIN_HELI_PROXIMITY 	= 150;
UAV_REMOTE_MAX_HELI_PROXIMITY 	= 300;
UAV_REMOTE_PAST_RANGE_COUNTDOWN = 6;
UAV_REMOTE_HELI_RANGE_COUNTDOWN = 3;
UAV_REMOTE_COLLISION_RADIUS 	= 20;
UAV_REMOTE_Z_OFFSET 			= -5;
UAV_REMOTE_COLLISION_HEIGHT		= 10;

VANGUARD_AMMO_COUNT 			= 100;
VANGUARD_TRANSITION_TIME		= 1;
VANGUARD_FLY_TIME 				= 60;
VANGUARD_SOUND_EXPLODE			= "ball_drone_explode";
VANGUARD_VO_DESTROYED			= "gryphon_destroyed";
VANGUARD_VO_GONE				= "gryphon_gone";
VANGUARD_NODE_SEARCH_RADIUS		= 192;	// used for node-style spawn
VANGUARD_SPAWN_HEIGHT			= 90;	// used for node-style spawn
VANGUARD_FALLBACK_SPAWN_RADIUS	= 80;
VANGUARD_HALF_SIZE				= 20;	// used for fallback capsule test around the player spawn
VANGUARD_HEIGHT_OFFSET			= 35;	// used for fallback capsule test around the player spawn
VANGUARD_WEAPON					= "remote_tank_projectile_mp";
VANGUARD_RELOAD_TIME_MS			= 1500;
VANGUARD_CAM_SHAKE_RANGE		= 60;
VANGUARD_SPAWN_GRACE_PERIOD		= 2000;	// in ms

CONST_VANGUARD_MIN_DIST = 50;
CONST_VANGUARD_MAX_DIST = 550;

init()
{	
	setupFx();
	//setupDialog();
	setupHeliRange();
	level.remote_uav = [];	
	level.killstreakFuncs["vanguard"] = ::tryUseVanguard;
	level.Vanguard_lastDialogTime = 0;
	level.vanguardFireMissleFunc = ::vanguard_fireMissile;
	level.lasedStrikeGlow = loadfx("fx/misc/laser_glow");
	
/#
	SetDevDvarIfUninitialized( "scr_vanguard_timeout", VANGUARD_FLY_TIME );
	SetDevDvarIfUninitialized( "scr_vanguard_reloadTime", VANGUARD_RELOAD_TIME_MS );
	SetDevDvarIfUninitialized( "scr_dbg_drone_spawn", 0 );
#/
}	


setupFx()
{
	level.Vanguard_fx["hit"] 					= loadfx("fx/impacts/large_metal_painted_hit");
	level.Vanguard_fx["smoke"] 				= loadfx( "fx/smoke/remote_heli_damage_smoke_runner" );
	level.Vanguard_fx["explode"] 				= loadfx( "vfx/gameplay/explosions/vehicle/vang/vfx_exp_vanguard" );	
	level.Vanguard_fx["target_marker_circle"]	= LoadFX( "vfx/gameplay/mp/core/vfx_marker_gryphon_orange" );
}

setupHeliRange()
{
	level.vanguardRangeTriggers	= GetEntArray( "remote_heli_range", "targetname" );
	level.vanguardMaxHeightEnt 	= GetEnt( "airstrikeheight", "targetname" );
	
	if( IsDefined(level.vanguardMaxHeightEnt) )
	{
		level.vanguardMaxHeight 	= level.vanguardMaxHeightEnt.origin[2];
		level.vanguradMaxDistanceSq = 12800 * 12800;
	}
	
	// the range trigger in descent is too short, and players can fly straight up through it without getting destroyed
	// add an uppermost limit
	level.is_mp_descent = false;
	if ( (getMapName() == "mp_descent") || (getMapName() == "mp_descent_new") )
	{
		level.vanguardMaxHeight = level.vanguardRangeTriggers[0].origin[2] + 360;
		level.is_mp_descent = true;
	}
}

tryUseVanguard( lifeId, streakName )
{
	return useVanguard( lifeId, streakName );
}


useVanguard( lifeId, streakName ) // self == player
{
	if( self isUsingRemote() || ( self isUsingTurret() ) )
	{
		return false;
	}	
	
	if( IsDefined(self.underWater) && self.underWater )
	{
		return false;
	}
	
	if( exceededMaxVanguards( self.team ) || (level.littleBirds.size >= 4) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}		
	else if( ( currentActiveVehicleCount() >= maxVehiclesAllowed() ) || ( level.fauxVehicleCount + 1 >= maxVehiclesAllowed() ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}
	else if ( IsDefined ( self.drones_disabled ))
	{
		self IPrintLnBold( &"KILLSTREAKS_UNAVAILABLE" );
		return false;
	}	
	
	incrementFauxVehicleCount();
	vanguard = self giveCarryVanguard( lifeId, streakName );
	
	if ( !IsDefined( vanguard ) )
	{
		decrementFauxVehicleCount();
		return false;
	}
	
	if ( !is_aliens() )
		self maps\mp\_matchdata::logKillstreakEvent( streakName, self.origin );
			
	return self startVanguard( vanguard, streakName, lifeId );
}


exceededMaxVanguards( team )
{
	if( level.teamBased )
	{
		return ( isDefined(level.remote_uav[team]) );
	}
	else
	{
		return ( isDefined(level.remote_uav[team]) || isDefined(level.remote_uav[level.otherTeam[team]]) );
	}
}

findValidVanguardSpawnPoint( spawnDist, heightOffset )	// self == player
{
	forward = AnglesToForward( self.angles );
	right = AnglesToRight( self.angles );
	
	eyePos = self GetEye();
	startPos = eyePos + (0, 0, heightOffset);
	
	// we check in this order, where 9 is the player's position and the last spot checked.
	// 8 1 6
	// 4 5 3
	// 7 2 9
	
	// forward
	curPos = startPos + spawnDist * forward;
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	// behind
	curPos = startPos - spawnDist * forward;
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	// right
	curPos += spawnDist * right;
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	// left
	curPos = startPos - spawnDist * right;
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	// above player
	curPos = startPos;
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	// don't want to do too many traces at once
	waitframe();
	
	// forward-right
	// scale vector to be closer to sqrt(2)/2, so it's a spawnDist radius circle
	curPos = startPos + 0.707 * spawnDist * (forward + right);
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	// forward-left
	curPos = startPos + 0.707 * spawnDist * (forward - right);
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	// behind-right
	curPos = startPos + 0.707 * spawnDist * (right - forward);
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	// behind-left
	curPos = startPos + 0.707 * spawnDist * (-1 * forward - right);
	if ( checkVanguardSpawnPoint( eyePos, curPos ) )
		return curPos;
	
	return undefined;
}

checkVanguardSpawnPoint( startPoint, spawnPoint )
{
	// capsule trace is much too big; a cylinder or even sphere check would be more appropriate
	result = false;
	
	if ( CapsuleTracePassed( spawnPoint, VANGUARD_HALF_SIZE, VANGUARD_HALF_SIZE*2 + 0.01, undefined, true, true ) )
	{
		result = BulletTracePassed( startPoint, spawnPoint, false, undefined );
	}
	
	/#
	if ( !result && GetDvarInt( "scr_dbg_drone_spawn" ) != 0 )
		Cylinder( spawnPoint - (0, 0, VANGUARD_HALF_SIZE), spawnPoint + (0, 0, VANGUARD_HALF_SIZE), VANGUARD_HALF_SIZE, (1, 0, 0), false, 300 );
	#/
	
	return result;
}

giveCarryVanguard( lifeId, streakName, duration ) // self == player
{
	origin = maps\mp\gametypes\_spawnscoring::findDronePathNode( self, VANGUARD_SPAWN_HEIGHT, VANGUARD_HALF_SIZE, VANGUARD_NODE_SEARCH_RADIUS );
	if ( !IsDefined( origin ) )
	{
		origin = maps\mp\gametypes\_spawnscoring::findDronePathNode( self, 0, VANGUARD_HALF_SIZE, VANGUARD_NODE_SEARCH_RADIUS );
		
		if ( !IsDefined( origin ) )
		{
			origin = self findValidVanguardSpawnPoint( VANGUARD_FALLBACK_SPAWN_RADIUS, VANGUARD_HEIGHT_OFFSET );
			
			if ( !IsDefined( origin ) )
			{
				origin = self findValidVanguardSpawnPoint( VANGUARD_FALLBACK_SPAWN_RADIUS, 0 );
			}
		}
	}
	
	if ( IsDefined( origin ) )
	{
		/#
		if ( GetDvarInt( "scr_dbg_drone_spawn" ) != 0 )
			Cylinder( origin - (0, 0, VANGUARD_HALF_SIZE), origin + (0, 0, VANGUARD_HALF_SIZE), VANGUARD_HALF_SIZE, (0, 1, 0), false, 300 );
		#/
		
		angles = self.angles;
		
		vanguard = createVanguard( lifeId, self, streakName, origin, angles, duration );
		if ( !IsDefined( vanguard ) )
		{
			self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		}
		
		return vanguard;
	}
	else
	{
		// we could not find any valid point to spawn
		self iPrintLnBold( &"KILLSTREAKS_VANGUARD_NO_SPAWN_POINT" );
		return undefined;
	}
}



startVanguard( vanguard, streakName, lifeId ) // self == player
{
	self setUsingRemote( streakName );
	self freezeControlsWrapper( true );
	
	self.restoreAngles = self.angles;
	
	if ( getDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( false );
	
	self thread watchIntroCleared( vanguard );
	
	result = self maps\mp\killstreaks\_killstreaks::initRideKillstreak( "vanguard" );
	
	if ( result != "success" )
	{
		vanguard notify ( "death" );
		// death will call clearUsingRemote
		
		return false;
	}
	else if ( !IsDefined( vanguard ) )
	{
		return false;
	}
	
	self freezeControlsWrapper( false );
	
	vanguard.playerLinked = true;
		
	self CameraLinkTo( vanguard, "tag_origin" );	
	self RemoteControlVehicle( vanguard );	
	vanguard.ammoCount = VANGUARD_AMMO_COUNT;

	self.remote_uav_rideLifeId = lifeId;
	self.remoteUAV = vanguard;
	
	self thread teamPlayerCardSplash( "used_vanguard", self );
	
	return true;		
}

vanguard_moving_platform_death( data )
{
	//self notify( "death" );
	// remove this check for IW7. On mp_ca_rumble, we don't want the trolley to destroy vanguard right away
	if ( !IsDefined( data.lastTouchedPlatform.destroyDroneOnCollision ) 
	    || data.lastTouchedPlatform.destroyDroneOnCollision
	    || !IsDefined( self.spawnGracePeriod )
	    || GetTime() > self.spawnGracePeriod )	// the grace period only gets checked if destroyDroneOnCollision is defined. (i.e., it will only be used in mp_ca_rumble for the time being).
	{
		self thread handleDeathDamage( undefined, undefined, undefined, undefined );
	}
	else
	{
		// 2014-06-16 wallace: we need to restart this function, 
		// because _movers.gsc::handle_moving_platform_touch stops itself when it thinks it should kill the object
		// however, need to wait a little bit, because the vanguard is still touching the platform at this point
		wait( 1.0 );
		thread maps\mp\_movers::handle_moving_platform_touch( data );
	}
}


createVanguard( lifeId, owner, streakName, origin, angles, duration ) // self == player
{
	vanguard = spawnHelicopter( owner, origin, angles, "remote_uav_mp", "vehicle_drone_vanguard" );
	
	if ( !isDefined( vanguard ) )
		return undefined;
	
	vanguard maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	vanguard thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();

	//radius and offset should match vehHelicopterBoundsRadius (GDT) and bg_vehicle_sphere_bounds_offset_z.
	vanguard MakeVehicleSolidCapsule( UAV_REMOTE_COLLISION_RADIUS, UAV_REMOTE_Z_OFFSET, UAV_REMOTE_COLLISION_HEIGHT ); 
	
	// target fx
	vanguard.attackArrow = spawn( "script_model", ( 0, 0, 0 ) );
	vanguard.attackArrow setModel( "tag_origin" );
	vanguard.attackArrow.angles = ( -90, 0, 0 );
	vanguard.attackArrow.offset = 4;
	
	//turret
	missileTurret = SpawnTurret( "misc_turret", vanguard.origin, "ball_drone_gun_mp", false );
	missileTurret LinkTo( vanguard, "tag_turret_attach", ( 0, 0, 0 ), ( 0, 0, 0 ) );
	missileTurret SetModel( "vehicle_drone_vanguard_gun" );
	missileTurret makeTurretInoperable();
	vanguard.turret = missileTurret;
	missileTurret MakeUnusable();
		
	vanguard.lifeId = lifeId;
	vanguard.team = owner.team;
	vanguard.pers["team"] = owner.team;	
	vanguard.owner = owner;
	vanguard make_entity_sentient_mp( owner.team );
	if ( IsSentient( vanguard ) )
	{
		vanguard SetThreatBiasGroup( "DogsDontAttack" );
	}

	// use a health buffer to prevent dying to friendly fire
	vanguard.health = 999999; // keep it from dying anywhere in code
	vanguard.maxHealth = 750; // this is the health we'll check
	vanguard.damageTaken = 0; // how much damage has it taken
	
	vanguard.smoking = false;
	vanguard.inHeliProximity = false;		
	vanguard.heliType = "remote_uav";	
	
	// !!! 
	missileTurret.owner = owner;
	missileTurret SetEntityOwner( vanguard );
	missileTurret thread maps\mp\gametypes\_weapons::doBlinkingLight( "tag_fx1" );
	missileTurret.parent = vanguard;
	// use a health buffer to prevent dying to friendly fire
	missileTurret.health = 999999; // keep it from dying anywhere in code
	missileTurret.maxHealth = 250; // this is the health we'll check
	missileTurret.damageTaken = 0; // how much damage has it taken
	
	level thread vanguard_monitorKillStreakDisowned( vanguard );
	level thread vanguard_monitorTimeout( vanguard, duration );
	level thread vanguard_monitorDeath( vanguard );
	level thread vanguard_monitorObjectiveCam( vanguard );	
	
	vanguard thread vanguard_watch_distance();
	vanguard thread vanguard_watchHeliProximity();	
	vanguard thread vanguard_handleDamage();
	vanguard.turret thread vanguard_turret_handleDamage();
	vanguard thread watchEMPDamage();
	
	killCamEnt = Spawn( "script_model", vanguard.origin );
	killCamEnt SetScriptMoverKillCam( "explosive" );
	killCamEnt LinkTo( vanguard, "tag_player", (-10, 0, 20), (0,0,0) );	// use offset from GDT
	vanguard.killCamEnt = killCamEnt;
	
	// Handle moving platform.
	vanguard.spawnGracePeriod = GetTime() + VANGUARD_SPAWN_GRACE_PERIOD;
	data = SpawnStruct();
	data.validateAccurateTouching = true;
	data.deathOverrideCallback = ::vanguard_moving_platform_death;
	vanguard thread maps\mp\_movers::handle_moving_platforms( data );
	
	level.remote_uav[vanguard.team] = vanguard;
	return vanguard;
}

watchHostMigrationFinishedInit( vanguard )
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );
	level endon( "game_ended" );
	vanguard endon( "death" );
	
	for(;;)
	{
		level waittill( "host_migration_end" );
		
		self initVanguardHud();

		vanguard thread vanguard_reticleStart();	
	}
}

watchIntroCleared( vanguard ) // self == player
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );
	level endon( "game_ended" );
	vanguard endon( "death" );
	
	self waittill( "intro_cleared" );
	
	self initVanguardHud();
	
	vanguard EnableAimAssist();
	
	self thread vanguard_think( vanguard );
	self thread vanguard_monitorFire( vanguard );
	self thread vanguard_monitorManualPlayerExit( vanguard );
	self thread vanguard_turretTarget( vanguard );
	// don't show arrow to friendly players
	vanguard thread vanguard_reticleStart();
	if ( !level.hardcoreMode )
	{
		vanguard thread vanguard_reticleWaitForJoinedTeam();
	}
	self thread watchHostMigrationFinishedInit( vanguard );
	self freezeControlsWrapper( false );
}


initVanguardHud()	// self = owner
{		
	self ThermalVisionFOFOverlayOn();
	self ThermalVisionOn();
	self SetClientOmnvar( "ui_vanguard", 1 );
	// self SetClientOmnvar( "ui_vanguard_signal", 0 );
}

vanguard_monitorManualPlayerExit( vanguard )
{
	level endon( "game_ended" );
	self endon ( "disconnect" );
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	
	vanguard thread maps\mp\killstreaks\_killstreaks::allowRideKillstreakPlayerExit();
	
	vanguard waittill("killstreakExit");
	
	if( IsDefined( vanguard.owner ) )
		vanguard.owner leaderDialogOnPlayer( VANGUARD_VO_GONE );
	
	vanguard notify ("death");
}

vanguard_turretTarget( vanguard )
{
	level endon ( "game_ended" );
	self endon ( "disconnect" );
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	
	while( !isDefined( vanguard.attackArrow ) )
		wait( 0.05 );
	
	vanguard SetOtherEnt( vanguard.attackArrow );

	vanguard SetTurretTargetEnt( vanguard.attackArrow );
}

vanguard_think( vanguard )
{
	level endon ( "game_ended" );
	self endon ( "disconnect" );
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	
	while( true )
	{
		if( vanguard touchingBadTrigger( "gryphon" ) )
		{
			vanguard notify( "damage", 1019, self, self.angles, self.origin, "MOD_EXPLOSIVE", undefined, undefined, undefined, undefined, "c4_mp" );
		}
		
		//self.lockedLocation = vanguard_selectTarget( vanguard );
		self.lockedLocation = vanguard.attackArrow.origin;
		waitframe();
	}
}

vanguard_reticleStart()	// self == vanguard
{
	PlayFXOnTagForClients( level.Vanguard_fx["target_marker_circle"], self.attackArrow, "tag_origin", self.owner );
	
	self thread vanguard_showReticleToEnemies();
}

vanguard_reticleWaitForJoinedTeam()	// self == vanguard
{
	self endon ("death");
	self endon ( "end_remote" );
	
	while (true)
	{
		level waittill ("joined_team", player );
		
		// self vanguard_showReticleToPlayer( player );
		StopFXOnTag( level.Vanguard_fx["target_marker_circle"], self.attackArrow, "tag_origin" );
		
		waitframe();
		
		self vanguard_reticleStart();
	}
}

vanguard_showReticleToEnemies()	// self == vanguard
{
	self endon ("death");
	self endon ( "end_remote" );
	
	if ( !level.hardcoreMode )
	{
		foreach ( player in level.players )
		{
			if ( self.owner isEnemy( player ) )
			{
				waitframe();
				PlayFXOnTagForClients( level.Vanguard_fx["target_marker_circle"], self.attackArrow, "tag_origin", player );
			}
		}
	}
}


vanguard_selectTarget( vanguard )
{
	result = getTargetPoint( vanguard.owner, vanguard);
	
	if( IsDefined(result) )
	{
		vanguard.attackArrow.origin = result[0] + (0,0,4);
		return result[0];
	}
	
	return undefined;
}


getTargetPoint( player, vanguard)
{
	origin = vanguard.turret getTagOrigin( "tag_flash" );
	angles = player GetPlayerAngles();
	forward = AnglesToForward( angles );
	endpoint = origin + forward * 15000;
	
	res = BulletTrace( origin, endpoint, false, vanguard );

	if ( res["surfacetype"] == "none" )
		return undefined;
	if ( res["surfacetype"] == "default" )
		return undefined;

	ent = res["entity"];

	results = [];
	results[0] = res["position"];
	results[1] = res["normal"];
	
	return results;
}


vanguard_monitorFire( vanguard )
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	
	self notifyOnPlayerCommand( "vanguard_fire", "+attack" );
	self notifyOnPlayerCommand( "vanguard_fire", "+attack_akimbo_accessible" );
	
	vanguard.fireReadyTime = GetTime();
	
	while ( true )
	{	
		self waittill( "vanguard_fire" );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		if( IsDefined( level.hostMigrationTimer ) )
			continue;
		
		if( isDefined( self.lockedLocation ) && GetTime() >= vanguard.fireReadyTime )
		{
			self thread [[level.vanguardFireMissleFunc]]( vanguard, self.lockedLocation );
		}
	}
}


vanguard_rumble( vanguard, rumbleType, numFrames )
{
	self      endon ( "disconnect" );
	level     endon ( "game_ended" );
	
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	vanguard notify( "end_rumble" );
	vanguard endon ( "end_rumble" );
	
	for( i = 0; i < numFrames; i++ )
	{
		self playRumbleOnEntity( rumbleType );
		waitframe();
	}	
}


loopTriggeredEffect( effect, missile )
{
	missile endon( "death" );
	level endon( "game_ended" );
	self endon ( "death" );
	
	for( ;; )
	{
		TriggerFX( effect );
		wait ( 0.25 );
	}
	
}

vanguard_fireMissile( vanguard, targetLocation )
{	
	level endon( "game_ended" );
		
	if( vanguard.ammoCount <= 0 )
	{
		return;
	}
	
	// call in missile use real tag when we get them.
	startPosition = vanguard.turret getTagOrigin( "tag_fire" );
	startPosition += (0,0,-25);	// offset the start position so we don't shoot ourselves
	
	if ( DistanceSquared( startPosition, targetLocation ) < 10000 )
	{
		vanguard PlaySoundToPlayer( "weap_vanguard_fire_deny", self );
		return;
	}
	
	// 2013-08-29 turning off the missile's target indicator glow for now, b/c we'd have to track each one independently
	// vanguard.targetEffect = SpawnFx( level.lasedStrikeGlow, targetLocation );
	vanguard.ammoCount--;
	
	// player feedback for missile fire
	self playLocalSound( "weap_gryphon_fire_plr" );
	playSoundinSpace( "weap_gryphon_fire_npc", vanguard.origin );
	self thread vanguard_rumble( vanguard, "shotgun_fire", 1 );
	Earthquake( 0.3, 0.25, vanguard.origin, VANGUARD_CAM_SHAKE_RANGE );	// earthquake for player
	
	missile = MagicBullet( VANGUARD_WEAPON, startPosition, targetLocation, self );
	missile.vehicle_fired_from = vanguard;
	
	reloadTime = VANGUARD_RELOAD_TIME_MS;
	
	/#
		reloadTime = GetDvarInt( "scr_vanguard_reloadTime" );
	#/
	
	vanguard.fireReadyTime = GetTime() + reloadTime;
	
	self thread updateWeaponUI( vanguard, reloadTime * 0.001 );	// reloadTime is in MS
	
	// vanguard thread loopTriggeredEffect( vanguard.targetEffect, vanguard.missile );
	
	// wait until missile explodes
	missile maps\mp\gametypes\_hostmigration::waittill_notify_or_timeout_hostmigration_pause( "death", 4 );
	
	// missile hit	
	Earthquake( 0.3, 0.75, targetLocation, 128 );	// earthquake for impact
	
	if ( IsDefined( vanguard ) )
	{
		Earthquake( 0.25, 0.75, vanguard.origin, VANGUARD_CAM_SHAKE_RANGE );	// earthquake for player
		self thread vanguard_rumble( vanguard, "damage_heavy", 3 );
		
		// vanguard.targetEffect Delete();
		
		if ( vanguard.ammoCount == 0 )
		{
			wait( 0.75 );
			vanguard notify( "death" );
		}
	}
}

updateWeaponUI( vanguard, reloadTime )	// self == owner
{
	level endon ( "game_ended" );
	self endon ( "disconnect" );
	vanguard endon ( "death" );
	vanguard endon ( "end_remote" );
	
	self SetClientOmnvar( "ui_vanguard_ammo", -1 );
	
	wait( reloadTime );
	// self maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	
	self SetClientOmnvar( "ui_vanguard_ammo", vanguard.ammoCount );
}

getStartPosition( vanguard, targetPoint )
{
	traceLength = (3000,3000,3000);
	dir 		= VectorNormalize( vanguard.origin - ( targetPoint + (0,0,-400) ) );
	
	// try an angle over the shoulder of the vanguard
	dirRotated 	= RotateVector(dir, (0,25,0) );
	startPos 	= targetPoint + (dirRotated*traceLength);
	
	if( isValidStartPoint( startPos, targetPoint ) )
	{
		return startPos;
	}
	
	// try an angle over the other shoulder of the vanguard 
	dirRotated 	= RotateVector(dir, (0,-25,0) );
	startPos 	= targetPoint + (dirRotated*traceLength);
	
	if( isValidStartPoint( startPos, targetPoint ) )
	{
		return startPos;
	}
	
	// try an angle directly behind
	startPos = targetPoint + (dir*traceLength);
	
	if( isValidStartPoint( startPos, targetPoint ) )
	{
		return startPos;
	}
		
	// drop the missile straight down
	return ( targetPoint + (0,0,3000) );
}

isValidStartPoint( startPoint, enPoint )
{
	skyTrace = bulletTrace( startPoint, enPoint , false );
	//level thread drawLine( startPoint, enPoint, 25, (1,0,0) );
	
	if( skyTrace["fraction"] > .99 )
	{
		return true;	
	}
	
	return false;;
}

CONST_INCHES_TO_METERS = 0.0254;
vanguard_watch_distance()
{
	self endon ("death" );
		
	//	shouldn't be possible to start out of range, but just in case
	inRangePos = self.origin;		
	
	self.rangeCountdownActive = false;
	
	//	loop
	while ( true )
	{
		if ( !isDefined( self ) )
			return;
		
		if ( !isDefined( self.owner ) )
			return;
		
		if ( !self vanguard_in_range() )
		{
			//	increase static with distance from exit point or distance to heli in proximity
			while ( !self vanguard_in_range() )
			{
				if ( !isDefined( self ) )
					return;
				
				if ( !isDefined( self.owner ) )
					return;
				
				//self.owner vanguard_dialog( "out_of_range" );
				if ( !self.rangeCountdownActive )
				{
					self.rangeCountdownActive = true;
					self thread vanguard_rangeCountdown();
				}
				
				if ( isDefined( self.heliInProximity ) )
				{
					dist = distance( self.origin, self.heliInProximity.origin );
				}
				// for mp_descent only
				else if ( IsDefined( level.disableVanguardsInAir ) )
				{
					dist = 0.85 * CONST_VANGUARD_MAX_DIST;
				}
				else
				{
					dist = distance( self.origin, inRangePos );				
				}
				
				staticAlpha = getSignalStrengthAlpha( dist );
				// self.owner SetClientOmnvar( "ui_vanguard_signal", staticAlpha );
				self.owner SetClientOmnvar( "ui_vanguard", staticAlpha );
				
				wait(0.1);
			}
			
			//	end countdown
			self notify( "in_range" );
			self.rangeCountdownActive = false;
			
			//	fade out static
			self.owner SetClientOmnvar( "ui_vanguard", 1 );
		}

		vanguardYaw = int( AngleClamp( self.angles[ 1 ] ) );
		self.owner SetClientOmnvar( "ui_vanguard_heading", vanguardYaw );
		
		vanguardHeight = self.origin[ 2 ] * CONST_INCHES_TO_METERS;
		vanguardHeight = Int( Clamp( vanguardHeight, -250, 250 ) );
		self.owner SetClientOmnvar( "ui_vanguard_altitude", vanguardHeight );
		
		targetRange = Distance2D( self.origin, self.attackArrow.origin ) * CONST_INCHES_TO_METERS;
		targetRange = Int( Clamp( targetRange, 0, 256 ) );
		self.owner SetClientOmnvar( "ui_vanguard_range", targetRange );
		
		
		inRangePos = self.origin;
		wait ( 0.1 );
	}
}

// map distance to signal strength
// <= MIN_DIST = 100% signal = 0.0 static alpha
// >= MAX_DIST = 0% signal = 1.0 static alpha
getSignalStrengthAlpha( dist )
{
	dist = clamp( dist, CONST_VANGUARD_MIN_DIST, CONST_VANGUARD_MAX_DIST );
	return 2 + int(8 * ( dist - CONST_VANGUARD_MIN_DIST ) / ( CONST_VANGUARD_MAX_DIST - CONST_VANGUARD_MIN_DIST ));
}


vanguard_in_range()
{
	if ( IsDefined(self.inHeliProximity) && self.inHeliProximity  )
	{
		return false;
	}
	
	// for mp_descent only
	if ( IsDefined( level.disableVanguardsInAir ) )
	{
		return false;
	}
	
	if ( IsDefined( level.vanguardRangeTriggers[0] ) )
	{
		foreach ( trigger in level.vanguardRangeTriggers )
		{
			if ( self isTouching( trigger )  )
				return false;
		}
		
		if ( level.is_mp_descent )
			return self.origin[2] < level.vanguardMaxHeight;
		else
			return true;
	}
	else
	{
		if( (Distance2DSquared( self.origin, level.mapCenter ) < level.vanguradMaxDistanceSq ) && (self.origin[2] < level.vanguardMaxHeight) )
			return true;
	}
	
	return false;
}


vanguard_rangeCountdown()
{
	self endon( "death" );
	self endon( "in_range" );
	
	if ( isDefined( self.heliInProximity ) )
		countdown = UAV_REMOTE_HELI_RANGE_COUNTDOWN;
	else
		countdown = UAV_REMOTE_PAST_RANGE_COUNTDOWN;
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( countdown );
	
	self notify( "death", "range_death" );
}


vanguard_monitorKillStreakDisowned( vanguard ) // self == level
{
	vanguard endon( "death" );	

	vanguard.owner waittill_any( "killstreak_disowned" );
	
	vanguard notify( "death" );
}


vanguard_monitorTimeout( vanguard, duration ) // self == level
{
	vanguard endon ( "death" );	
	
	timeout = VANGUARD_FLY_TIME;
	if ( !is_aliens() )
	{
/#
		timeout = GetDvarFloat( "scr_vanguard_timeout" );
#/
	}
	else
		timeout = duration;
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( timeout );
	
	if( IsDefined( vanguard.owner ) )
		vanguard.owner leaderDialogOnPlayer( VANGUARD_VO_GONE );
	
	vanguard notify( "death" );
}


vanguard_monitorDeath( vanguard ) // self == level
{
	level endon( "game_ended" );
	level endon( "objective_cam" );
	
	turret = vanguard.turret;
	
	vanguard waittill( "death" );			
	
	vanguard maps\mp\gametypes\_weapons::stopBlinkingLight();
	
	StopFXOnTag( level.Vanguard_fx["target_marker_circle"], vanguard.attackArrow, "tag_origin" );
		
	PlayFX( level.Vanguard_fx["explode"], vanguard.origin );
	vanguard PlaySound( VANGUARD_SOUND_EXPLODE );
	turret Delete();
	
	if( isDefined( vanguard.targetEffect ) )
		 vanguard.targetEffect Delete();
	
	vanguard_endride( vanguard.owner, vanguard );	
}

vanguard_monitorObjectiveCam( vanguard ) // self == level
{
	vanguard endon( "death" );
	
	level waittill_any( "objective_cam", "game_ended" );
	
	PlayFX( level.Vanguard_fx["explode"], vanguard.origin );
	vanguard PlaySound( VANGUARD_SOUND_EXPLODE );
	
	vanguard_endride( vanguard.owner, vanguard );	
}


vanguard_endride( player, vanguard )
{
	vanguard notify( "end_remote" );
	vanguard.playerLinked = false;

	vanguard SetOtherEnt( undefined );

	vanguard_removePlayer( player, vanguard );
	
	stopFXOnTag( level.Vanguard_fx["smoke"], vanguard, "tag_origin" );
	
	level.remote_uav[vanguard.team] = undefined;

	decrementFauxVehicleCount();
	
	if( IsDefined( vanguard.killCamEnt ) )
		vanguard.killCamEnt delete();
	
	vanguard.attackArrow delete();
	vanguard delete();
}

restoreVisionSet()
{
	self VisionSetNakedForPlayer( "", 1 );
	self set_visionset_for_watching_players( "", 1 );
}

vanguard_removePlayer( player, vanguard )
{
	if( !IsDefined(player) )
		return;
		
	player clearUsingRemote();
	// use clearRideIntro
	player restoreVisionSet();
	
	player SetClientOmnvar( "ui_vanguard", 0 );				
	
	if( getDvarInt( "camera_thirdPerson" ) )
	{
		player setThirdPersonDOF( true );	
	}
	
	player CameraUnlink( vanguard );
	player RemoteControlVehicleOff( vanguard );
	player ThermalVisionOff();
	player ThermalVisionFOFOverlayOff();
	// player set_visionset_for_watching_players( game["thermal_vision"], 0, undefined, "thermal" );
	player setPlayerAngles( player.restoreAngles );	
	
	player.remoteUAV = undefined;
	
	if( player.team == "spectator" )
		return;
	
	level thread vanguard_freezeControlsBuffer( player );
}


vanguard_freezeControlsBuffer( player )
{
	player endon( "disconnect" );
	player endon( "death" );
	level endon( "game_ended" );
	
	player freezeControlsWrapper( true );
	wait(0.5);	// wait longer than a frame, so players don't use triggers and other things when exiting the streak early
	player freezeControlsWrapper( false );
}

/*
vanguard_dialog( dialogGroup )
{
	if ( dialogGroup == "tag" )
		waitTime = 1000;
	else
		waitTime = 5000;
	
	if ( getTime() - level.Vanguard_lastDialogTime < waitTime )
		return;
	
	level.Vanguard_lastDialogTime = getTime();
	
	randomIndex = randomInt( level.vanguard_dialog[ dialogGroup ].size );
	soundAlias = level.vanguard_dialog[ dialogGroup ][ randomIndex ];
	
	fullSoundAlias = maps\mp\gametypes\_teams::getTeamVoicePrefix( self.team ) + soundAlias;
	
	self playLocalSound( fullSoundAlias );
}
*/

vanguard_watchHeliProximity()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "end_remote" );
	
	while( true )
	{
		inHeliProximity = false;
		foreach( heli in level.helis )
		{
			if ( distance( heli.origin, self.origin ) < UAV_REMOTE_MAX_HELI_PROXIMITY )
			{
				inHeliProximity = true;
				self.heliInProximity = heli;
			}
		}
		foreach( littlebird in level.littleBirds )
		{
			if ( littlebird != self && ( !isDefined(littlebird.heliType) || littlebird.heliType != "remote_uav" ) && distance( littlebird.origin, self.origin ) < UAV_REMOTE_MAX_HELI_PROXIMITY )
			{
				inHeliProximity = true;
				self.heliInProximity = littlebird;	
			}
		}
		
		if ( !self.inHeliProximity && inHeliProximity )
			self.inHeliProximity = true;
		else if ( self.inHeliProximity && !inHeliProximity )
		{
			self.inHeliProximity = false;
			self.heliInProximity = undefined;
		}
		
		wait( 0.05 );
	}
}

vanguard_handleDamage() // self == vanguard
{
	self endon( "death" );
	level endon( "game_ended" );

	self SetCanDamage( true );

	while( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );

		self maps\mp\gametypes\_damage::monitorDamageOneShot(
			damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon,
			"remote_uav",
			::handleDeathDamage,
			::modifyDamage,
			true	// isKillstreak
		);
	}
}

vanguard_turret_handleDamage() // self == turret attached to vanguard
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
		"remote_uav",
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
	
	// modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleEmpDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleGrenadeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	if( type == "MOD_MELEE" )
	{
		// make it take a few hits to kill
		modifiedDamage = self.maxhealth * 0.34; // three hits, same as sentry
	}
	
	// this is super hacky. Should be in an "onDamaged" function
	PlayFXOnTagForClients( level.Vanguard_fx["hit"], self, "tag_origin", self.owner );
	
	if( self.smoking == false && self.damageTaken >= self.maxhealth/2 )
	{
		self.smoking = true;

		PlayFxOnTag( level.Vanguard_fx["smoke"], self, "tag_origin" );
	}
	
	return modifiedDamage;
}

handleDeathDamage( attacker, weapon, type, damage )	// self == vehicle
{
	if( IsDefined( self.owner ) )
		self.owner leaderDialogOnPlayer( VANGUARD_VO_DESTROYED );
	self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, damage, "destroyed_vanguard", undefined, "callout_destroyed_vanguard" );
	
	if ( IsDefined( attacker ) )
	{
		attacker maps\mp\gametypes\_missions::processChallenge( "ch_gryphondown" ); 
	
		maps\mp\gametypes\_missions::checkAAChallenges( attacker, self, weapon );
	}
}

watchEMPDamage()
{
	// self endon( "carried" );
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		// this handles any flash or concussion damage
		self waittill( "emp_damage", attacker, duration );
		
		StopFXOnTag( level.Vanguard_fx["target_marker_circle"], self.attackArrow, "tag_origin" );
		waitframe();
		self thread vanguard_showReticleToEnemies();
		
		PlayFXOnTag( getfx( "emp_stun" ), self, "tag_origin" );
		
		// set the ui flag
		
		wait( duration );
		
		// stop the ui flag
		StopFXOnTag( level.Vanguard_fx["target_marker_circle"], self.attackArrow, "tag_origin" );
		waitframe();
		self thread vanguard_reticleStart();
	}
}
