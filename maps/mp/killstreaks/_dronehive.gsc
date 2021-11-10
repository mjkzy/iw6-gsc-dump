#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;


//============================================
// 				constants
//============================================
CONST_DRONE_HIVE_DEBUG 	= false;
CONST_MISSILE_COUNT		= 2;
CONST_WEAPON_MAIN = "drone_hive_projectile_mp";
CONST_WEAPON_CHILD = "switch_blade_child_mp";


//============================================
// 					init
//============================================
init()
{		
	level.killstreakFuncs["drone_hive"] = ::tryUseDroneHive;
	
	level.droneMissileSpawnArray = GetEntArray( "remoteMissileSpawn", "targetname" );
	
	foreach( missileSpawn in level.droneMissileSpawnArray )
	{
		missileSpawn.targetEnt = GetEnt( missileSpawn.target, "targetname" );	
	}
}	


//============================================
// 				tryUseDroneHive
//============================================
tryUseDroneHive( lifeId, streakName )
{
	/#
	if( (!IsDefined(level.droneMissileSpawnArray) || !level.droneMissileSpawnArray.size) )
	{
		AssertMsg( "map needs remoteMissileSpawn entities" );
	}
	#/
		
	return useDroneHive( self, lifeId );
}


//============================================
// 				useDroneHive
//============================================
useDroneHive( player, lifeId )
{
	if ( IsDefined( self.underWater ) && self.underWater )
	{
		return false;
	}
	
	player setUsingRemote( "remotemissile" );
	player freezeControlsWrapper( true );
	player _disableWeaponSwitch();
	// JC-10/01/13-Because the init ride of the killstreak has waits
	// the killstreak disowned notify could get missed causing the
	// usingRemote variable to never get cleared on the player. Start
	// these clean up threads off before to prevent this.
	level thread monitorDisownKillstreaks( player );
	level thread monitorGameEnd( player );
	level thread monitorObjectiveCamera(player);
	
	result = player maps\mp\killstreaks\_killstreaks::initRideKillstreak( "drone_hive" );
	
	if ( result == "success" )
	{
		player freezeControlsWrapper( false );
		level thread runDroneHive( player, lifeId);
	}
	else
	{
		player notify( "end_kill_streak" );	// stop the monitor threads
		player clearUsingRemote();
		player _enableWeaponSwitch();
	}
	
	return result == "success";
}

//============================================
// 		 watchHostMigrationStartedInit
//============================================
watchHostMigrationStartedInit( player )
{
	player endon( "killstreak_disowned" );
	player endon ( "disconnect" );
	level  endon( "game_ended" );
	self endon ( "death" );
	
	for (;;)
	{
		level waittill( "host_migration_begin" );
		
		if ( isDefined( self ) )
		{
			player VisionSetMissilecamForPlayer( game["thermal_vision"], 0 );
			player set_visionset_for_watching_players( "default", 0, undefined, true );
			player ThermalVisionFOFOverlayOn();
		}
		else
		{
			player SetClientOmnvar( "ui_predator_missile", 2 );
		}
	}
}

//============================================
// 		 watchHostMigrationFinishedInit
//============================================
watchHostMigrationFinishedInit( player )
{
	player endon( "killstreak_disowned" );
	player endon ( "disconnect" );
	level  endon( "game_ended" );
	self endon ( "death" );
	
	for (;;)
	{
		level waittill( "host_migration_end" );
		
		
		if ( isDefined( self ) )
		{
			player SetClientOmnvar( "ui_predator_missile", 1 );
			player SetClientOmnvar( "ui_predator_missiles_left", self.missilesLeft );
		}
		else
		{
			player SetClientOmnvar( "ui_predator_missile", 2 );
		}

	}
}

//============================================
// 				useDroneHive
//============================================
runDroneHive( player, lifeId )
{
	player endon( "killstreak_disowned" );
	level  endon( "game_ended" );
	
	player notifyOnPlayerCommand( "missileTargetSet", "+attack" );
	player notifyOnPlayerCommand( "missileTargetSet", "+attack_akimbo_accessible" );
	
	remoteMissileSpawn = getBestMissileSpawnPoint( player, level.droneMissileSpawnArray );
	
	startPos 	= remoteMissileSpawn.origin;	
	targetPos 	= remoteMissileSpawn.targetEnt.origin;
	vector 		= VectorNormalize( startPos - targetPos );		
	startPos 	= ( vector * 14000 ) + targetPos;

	/#
	if( CONST_DRONE_HIVE_DEBUG )
	{
		level thread drawLine( startPos, targetPos, 15, (1,0,0) );
	}
	#/
	
	rocket = MagicBullet( CONST_WEAPON_MAIN, startpos, targetPos, player );
	rocket SetCanDamage( true );
	rocket DisableMissileBoosting();
	rocket SetMissileMinimapVisible( true );

	rocket.team 		= player.team;
	rocket.lifeId 		= lifeId;
	rocket.type 		= "remote";
	rocket.owner 		= player;
	rocket.entityNumber = rocket GetEntityNumber();
	
	level.rockets[ rocket.entityNumber ] = rocket;
	level.remoteMissileInProgress = true;
	
	level thread monitorDeath( rocket, true );
	level thread monitorBoost( rocket );
	
	// this is used for challenge tracking
	if ( IsDefined( player.killsThisLifePerWeapon ) )
	{
		player.killsThisLifePerWeapon[ CONST_WEAPON_MAIN ] = 0;
		player.killsThisLifePerWeapon[ CONST_WEAPON_CHILD ] = 0;
	}
	
	missileEyes( player, rocket );
	
	player SetClientOmnvar( "ui_predator_missile", 1 );
	
	rocket thread watchHostMigrationStartedInit( player );
	rocket thread watchHostMigrationFinishedInit( player );
	
	missileCount = 0;
	rocket.missilesLeft = CONST_MISSILE_COUNT;
	
	player setClientOmnVar( "ui_predator_missiles_left", CONST_MISSILE_COUNT );
	
	while( true )
	{
		result = rocket waittill_any_return( "death", "missileTargetSet" );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		
		if( result == "death" )
			break;
		
		//rocket trigger could be hit pre migration then rocket dies during migration
		//causing this case
		if ( !isDefined( rocket ) )
			break;
		
		if( missileCount < CONST_MISSILE_COUNT )
		{
			level thread spawnSwitchBlade( rocket, missileCount );
			missileCount++;
			
			rocket.missilesLeft = CONST_MISSILE_COUNT - missileCount;
			player setClientOmnVar( "ui_predator_missiles_left", rocket.missilesLeft );
			
			if( missileCount == CONST_MISSILE_COUNT )
				rocket EnableMissileBoosting();
		}
	}
	
	thread returnPlayer( player );
}


//============================================
// 			monitorLockedTarget NOT IN USE  WorldPointInReticle_Circle doesnt function here
//============================================
monitorLockedTarget()
{
	level endon( "game_ended" );
	self endon ( "death" );
	
	enemyTargets = [];
	sortedTargets = [];
	
	for(;;)
	{
		targetsInsideReticle = [];
		enemyTargets = getEnemyTargets();
		
		foreach( targ in enemyTargets )
		{
			targInReticle = self.owner WorldPointInReticle_Circle( targ.origin, 65, 90 );
			
			if ( targInReticle )
			{
				self.owner thread drawLine( self.origin, targ.origin, 10, (0,0,1) );
				targetsInsideReticle[targetsInsideReticle.size] = targ;
			}
		}
		
		if( targetsInsideReticle.size )
		{
			sortedTargets = SortByDistance( targetsInsideReticle, self.origin );
			self.lastTargetLocked = sortedTargets[0];
			maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 0.25 );
		}
		
		wait ( 0.05 );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	}
}

//============================================
// 			getEnemyTargets
//============================================
getEnemyTargets( owner )
{
	enemyTargets = [];
	
	foreach ( player in level.participants )
	{
		if ( owner isEnemy( player ) 
		    && !(player _hasPerk( "specialty_blindeye" )) 
		   )
		{
			enemyTargets[ enemyTargets.size ] = player;
		}
	}
	
	enemyVehicleTargets = maps\mp\gametypes\_weapons::lockOnLaunchers_getTargetArray();
	
	if ( enemyTargets.size && enemyVehicleTargets.size )
	{
		finalTargets = array_combine( enemyTargets, enemyVehicleTargets );
		return finalTargets;
	}
	else if ( enemyTargets.size )
	{
		return enemyTargets;
	}
	else 
	{
		return enemyVehicleTargets;
	}
}


//============================================
// 			spawnSwitchBlade
//============================================
spawnSwitchBlade( rocket, spawnOnLeft )
{
	rocket.owner playLocalSound( "ammo_crate_use" );
	
	playerViewAngles 	= rocket GetTagAngles( "tag_camera" );
	forwardDir 	 		= AnglesToForward( playerViewAngles );
	rightDir	 		= AnglesToRight( playerViewAngles );
	spawnOffset  = (35,35,35);
	targetOffset = (15000,15000,15000);
	
	if(spawnOnLeft)
		spawnOffset = spawnOffset * -1;
	
	result = BulletTrace( rocket.origin, rocket.origin + (forwardDir * targetOffset), false, rocket );

	targetOffset 	= targetOffset * result["fraction"];			 
	startPosition 	= rocket.origin + (rightDir * spawnOffset );
	targetLocation 	= rocket.origin + (forwardDir * targetOffset );
	
	targets = rocket.owner getEnemyTargets( rocket.owner );
	missile = MagicBullet( CONST_WEAPON_CHILD, startPosition, targetLocation, rocket.owner );
	
	foreach ( targ in targets )
	{
		if ( Distance2dsquared( targ.origin, targetLocation ) < (512*512) )
		{
			missile Missile_SetTargetEnt( targ );
			break;
		}
	}
	
	//missile.targEffect = SpawnFx( level.lasedStrikeGlow, targetLocation );
	//self thread DrawLine(startPosition, targetLocation, 20, (1,0,0) );
	
	missile SetCanDamage( true );
	missile SetMissileMinimapVisible( true );

	missile.team 			= rocket.team;
	missile.lifeId 			= rocket.lifeId;
	missile.type			= rocket.type;
	missile.owner 			= rocket.owner;
	missile.entityNumber 	= missile GetEntityNumber();
	
	level.rockets[ missile.entityNumber ] = missile;
	level thread monitorDeath( missile, false );
}


//============================================
// 			loop effect for targ
//============================================
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


//============================================
// 			getNextMissileSpawnIndex
//============================================
getNextMissileSpawnIndex( oldIndex )
{
	index = oldIndex + 1;
	
	if( index == level.droneMissileSpawnArray.size )
	{
		index = 0;
	}
	
	return index;
}


//============================================
// 				monitorBoost
//============================================
monitorBoost( rocket )
{
	rocket endon( "death" );
	
	while( true )
	{
		rocket.owner waittill( "missileTargetSet" );
		rocket notify( "missileTargetSet" );
	}
}


//============================================
// 			getBestMissileSpawnPoint
//============================================
getBestMissileSpawnPoint( owner, remoteMissileSpawnPoints )
{
	validEnemies = [];
	
	foreach( player in level.players )
	{
		if( !isReallyAlive( player ) )
			continue;

		if( player.team == owner.team )
			continue;
		
		if( player.team == "spectator" )
			continue;
	
		validEnemies[validEnemies.size] = player;
	}

	if( !validEnemies.size )
	{
		return remoteMissileSpawnPoints[ RandomInt(remoteMissileSpawnPoints.size)];
	}
	
	remoteMissileSpawnPointsRandomized = array_randomize(remoteMissileSpawnPoints);
	bestMissileSpawn = remoteMissileSpawnPointsRandomized[0];
	
	// select a missile spawn that can see the most enemies
	foreach( missileSpawn in remoteMissileSpawnPointsRandomized )
	{
		missileSpawn.sightedEnemies = 0;
		
		for ( i = 0; i < validEnemies.size; i++ )
		{
			enemy = validEnemies[i];
			if( !isReallyAlive( enemy ) )
			{
				validEnemies[i] = validEnemies[validEnemies.size-1];
				validEnemies[validEnemies.size-1] = undefined;
				i--;
				continue;
			}
			
			//IW6 JH made this way cheaper if it sees an enemy it returns it.
			if( BulletTracePassed( enemy.origin + (0,0,32), missileSpawn.origin, false, enemy ) )
			{
				missileSpawn.sightedEnemies += 1;
				return missileSpawn;
			}
			
			wait(0.05);		// This loop is O(n^2), and it does a trace each time, so make sure to only do one per frame
			maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		}
		
		if ( missileSpawn.sightedEnemies == validEnemies.size )
		{
			// Optimization - if this missileSpawn can see all enemies, then we're not going to find a better one, so just return it immediately
			return missileSpawn;
		}
		
		if( missileSpawn.sightedEnemies > bestMissileSpawn.sightedEnemies )
		{
			bestMissileSpawn = missileSpawn;
		}
	}
	
	return bestMissileSpawn;
}


//============================================
// 				missileEyes
//============================================
missileEyes( player, rocket )
{
	delayTime = 1.0;
	
	player freezeControlsWrapper( true );
	player CameraLinkTo( rocket, "tag_origin" );
	player ControlsLinkTo( rocket );
	player VisionSetMissilecamForPlayer( "default", delayTime );
	player thread set_visionset_for_watching_players( "default", delayTime, undefined, true );

	player VisionSetMissilecamForPlayer( game["thermal_vision"], 1.0 );
	player thread delayedFOFOverlay();

	level thread unfreezeControls( player, delayTime );
}


delayedFOFOverlay()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 0.25 );
	
	self ThermalVisionFOFOverlayOn();
}

//============================================
// 			unfreezeControls
//============================================
unfreezeControls( player, delayTime, i )
{
	player endon( "disconnect" );
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( delayTime - 0.35 );

	player freezeControlsWrapper( false );
}


//============================================
// 			monitorDisownKillstreaks
//============================================
monitorDisownKillstreaks( player )
{
	player endon( "disconnect" );
	player endon( "end_kill_streak" );
	
	player waittill( "killstreak_disowned" );
	
	level thread returnPlayer( player );
}


//============================================
// 			monitorGameEnd
//============================================
monitorGameEnd( player )
{
	player endon( "disconnect" );
	player endon( "end_kill_streak" );
	
	level waittill( "game_ended" );
	
	level thread returnPlayer( player );
}


//============================================
// 			monitorObjectiveCamera
//============================================
monitorObjectiveCamera( player )
{
	player endon( "end_kill_streak" );
	player endon( "disconnect" );
	
	level waittill( "objective_cam" );	
	
	level thread returnPlayer( player, true );
}


//============================================
// 				monitorDeath
//============================================
monitorDeath( killStreakEnt, mainMissile )
{
	killStreakEnt waittill( "death" );
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	
	if ( isDefined( killStreakEnt.targEffect ) )
		killStreakEnt.targEffect Delete();
	
	if ( isDefined ( killStreakEnt.entityNumber ) )
		level.rockets[ killStreakEnt.entityNumber ] = undefined;
		
	if ( mainMissile )
		level.remoteMissileInProgress = undefined;
}


//============================================
// 				returnPlayer
//============================================
returnPlayer( player, instant )
{
	if( !IsDefined(player) )
		return;
	
	player SetClientOmnvar( "ui_predator_missile", 2 );
	player notify( "end_kill_streak" );
	
	player freezeControlsWrapper( true );
	player ThermalVisionFOFOverlayOff();
	player ControlsUnlink();
	
	if ( !isDefined( instant ) )
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 0.95 );
	
	player CameraUnlink();
	player SetClientOmnvar( "ui_predator_missile", 0 );
	player clearUsingRemote();
	player _enableWeaponSwitch();
}
