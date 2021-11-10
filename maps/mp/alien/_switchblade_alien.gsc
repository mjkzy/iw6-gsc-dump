#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;


//============================================
// 				constants
//============================================
CONST_DRONE_HIVE_DEBUG 	= false;
CONST_MISSILE_COUNT		= 0;


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
tryUseDroneHive( rank, num_missiles, missile_name, altitude, baby_missile_name )
{
	/#
	if( (!IsDefined(level.droneMissileSpawnArray) || !level.droneMissileSpawnArray.size) )
	{
		AssertMsg( "map needs remoteMissileSpawn entities" );
	}
	#/
	self notify( "action_use" );	
	level thread maps\mp\alien\_music_and_dialog::PlayVOForPredator( self );
	return useDroneHive( self, rank, num_missiles, missile_name, altitude, baby_missile_name );
}


//============================================
// 				useDroneHive
//============================================
useDroneHive( player, rank, num_missiles, missile_name, altitude, baby_missile_name )
{	
	player setUsingRemote( "remotemissile" );

	self VisionSetNakedForPlayer( "black_bw", 0.75 );
	self maps\mp\alien\_utility::restore_client_fog( 0 );
	self thread set_visionset_for_watching_players( "black_bw", 0.75, 1.0 );
	//blackOutWait = self waittill_any_timeout( 0.2, "disconnect", "death" );
	
	level thread runDroneHive( player, rank, num_missiles, missile_name, altitude, baby_missile_name );
//	level thread monitorDisownKillstreaks( player );
	level thread monitorGameEnd( player, rank );
	
	return true;
}


//============================================
// 				useDroneHive
//============================================
runDroneHive( player, rank, num_missiles, missile_name, altitude, baby_missile_name )
{
	player endon( "killstreak_disowned" );
	level  endon( "game_ended" );
	
	if ( !IsDefined( missile_name ) )
		missile_name = "switchblade_rocket_mp";
	
	if ( !IsDefined( num_missiles ) )
		num_missiles = 0;
	
	player notifyOnPlayerCommand( "missileTargetSet", "+attack" );
	remoteMissileSpawn = getClosest( player.origin,level.droneMissileSpawnArray );
	
	startPos 	= remoteMissileSpawn.origin;	
	targetPos 	= player.origin; 
	vector 		= VectorNormalize( startPos - targetPos );		
	startPos 	= ( vector * altitude ) + targetPos;

	/#
	if( CONST_DRONE_HIVE_DEBUG )
	{
		level thread drawLine( startPos, targetPos, 15, (1,0,0) );
	}
	#/
	
	rocket = MagicBullet( missile_name, startpos, targetPos, player );
	rocket SetCanDamage( true );
	
	if( num_missiles != 0 )
		rocket DisableMissileBoosting();

	rocket.team 		= player.team;

	rocket.type 		= "remote";
	rocket.owner 		= player;
	rocket.entityNumber = rocket GetEntityNumber();
	
	level.rockets[ rocket.entityNumber ] = rocket;
	level.remoteMissileInProgress = true;
	
	level thread monitorDeath( rocket );
	level thread monitorBoost( rocket );
	
	missileEyes( player, rocket, rank );
//	player setDepthOfField( 0, 96, 768, 4000, 4, 0 );
	player notify( "action_use" );
	
	player SetClientOmnvar( "ui_predator_missile", 1 );
		
	missileCount = 0;
	
	while( true )
	{
		result = rocket waittill_any_return( "death", "missileTargetSet" );
		
		if( result == "death" )
			break;
		
		if  ( missileCount < num_missiles )
		{
			level thread spawnSwitchBlade( rocket, missileCount, baby_missile_name );
			missileCount++;
		}
		
		if( missileCount == num_missiles )
			rocket EnableMissileBoosting();
	}
	
	player.turn_off_class_skill_activation = undefined;
	returnPlayer( player, rank );
}


//============================================
// 			getEnemyTargets
//============================================
getEnemyTargets( owner )
{
	enemyTargets = [];

	foreach ( agent in level.agentArray )
	{
		// only active
		if ( !IsDefined( agent.isActive ) || !agent.isActive )
			continue;
		
		enemyTargets[ enemyTargets.size ] = agent;
	}

	return enemyTargets;

}


//============================================
// 			spawnSwitchBlade
//============================================
spawnSwitchBlade( rocket, spawnOnLeft, baby_missile_name )
{
	rocket.owner playLocalSound( "ammo_crate_use" );
	
	forwardDir 	 = AnglesToForward( rocket.angles );
	rightDir	 = AnglesToRight( rocket.angles );
	spawnOffset  = (35,35,35);
	targetOffset = (15000,15000,15000);
	
	if(spawnOnLeft)
		spawnOffset = spawnOffset * -1;
	
	result = BulletTrace( rocket.origin, rocket.origin + (forwardDir * targetOffset), false, rocket );

	targetOffset 	= targetOffset * result["fraction"];			 
	startPoistion 	= rocket.origin + (rightDir * spawnOffset );
	targetLocation 	= startPoistion + (forwardDir * targetOffset );
	
	targets = rocket.owner getEnemyTargets( rocket.owner );
	
	missile = MagicBullet( baby_missile_name, startPoistion, targetLocation, rocket.owner );
	
	TargetArea = 262144;	//512*512
	
	foreach ( targ in targets )
	{
		if ( Distance2dsquared( targ.origin, targetLocation ) < TargetArea )
		{
			missile Missile_SetTargetEnt( targ );
			break;
		}
	}
	
	missile SetCanDamage( true );
	
	missile.team 			= rocket.team;

	missile.owner 			= rocket.owner;
	missile.entityNumber 	= missile GetEntityNumber();
	
	level.rockets[ missile.entityNumber ] = missile;
	level thread monitorDeath( rocket );
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
// 				missileEyes
//============================================
missileEyes( player, rocket, rank )
{
	delayTime = 1.0;
	
	player freezeControlsWrapper( true );
	
	if ( rank >= 1 )
		player thread delayedFOFOverlay();
		
	player CameraLinkTo( rocket, "tag_origin" );
	player ControlsLinkTo( rocket );
	player VisionSetMissilecamForPlayer( "default", delayTime );
	player set_visionset_for_watching_players( "default", delayTime, undefined, true );
	player VisionSetMissilecamForPlayer( game["thermal_vision_trinity"], 0.0 );
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
	
	wait( delayTime - 0.35 );
	player freezeControlsWrapper( false );
}


//============================================
// 			monitorDisownKillstreaks
//============================================
monitorDisownKillstreaks( player, rank )
{
	player endon( "end_kill_streak" );
	
	player waittill( "killstreak_disowned" );
	
	level thread returnPlayer( player, rank );
}


//============================================
// 			monitorGameEnd
//============================================
monitorGameEnd( player, rank )
{
	player endon( "end_kill_streak" );
	
	level waittill( "game_ended" );
	
	level thread returnPlayer( player, rank );
}


//============================================
// 				monitorDeath
//============================================
monitorDeath( killStreakEnt )
{
	killStreakEnt waittill( "death" );
	
	level.rockets[ killStreakEnt.entityNumber ] = undefined;
	level.remoteMissileInProgress = undefined;
}


//============================================
// 				returnPlayer
//============================================
returnPlayer( player, rank )
{
	if( !IsDefined(player) )
		return;
	
	player SetClientOmnvar( "ui_predator_missile", 2 );
	player notify( "end_kill_streak" );
	
	player freezeControlsWrapper( true );
	if ( rank >= 1 )
	{
		player ThermalVisionFOFOverlayOff();
	}
	
	player ControlsUnlink();
//	player setDepthOfField( 0, 96, 768, 4000, 6, 1.8 );
	player setExitPredatorVisionSet();
	
	wait( 0.95 );
	
	player CameraUnlink();
	player SetClientOmnvar( "ui_predator_missile", 0 );
	player clearUsingRemote();
	if ( IsDefined( player.last_weapon ) )
		player SwitchToWeapon( player.last_weapon );
}

setExitPredatorVisionSet()
{
	transition_time = 0.5;

	self VisionSetNakedForPlayer( "", transition_time );
	self VisionSetStage( 0, transition_time );
}