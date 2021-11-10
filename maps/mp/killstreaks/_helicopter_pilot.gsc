#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	level.killstreakFuncs[ "heli_pilot" ] = ::tryUseHeliPilot;
	
	level.heli_pilot = [];	
	
	level.heliPilotSettings = [];	

	level.heliPilotSettings[ "heli_pilot" ] = SpawnStruct();
	level.heliPilotSettings[ "heli_pilot" ].timeOut =				60.0;	
	level.heliPilotSettings[ "heli_pilot" ].maxHealth =				2000; // this is what we check against for death	
	level.heliPilotSettings[ "heli_pilot" ].streakName =			"heli_pilot";
	level.heliPilotSettings[ "heli_pilot" ].vehicleInfo =			"heli_pilot_mp";
	level.heliPilotSettings[ "heli_pilot" ].modelBase =				level.littlebird_model;
	level.heliPilotSettings[ "heli_pilot" ].teamSplash =			"used_heli_pilot";	

	heliPilot_setAirStartNodes();
	
	// throw the mesh way up into the air, the gdt entry for the vehicle must match
	level.heli_pilot_mesh = GetEnt( "heli_pilot_mesh", "targetname" );
	if( !IsDefined( level.heli_pilot_mesh ) )
		PrintLn( "heli_pilot_mesh doesn't exist in this level: " + level.script );
	else
		level.heli_pilot_mesh.origin += getHeliPilotMeshOffset();
	
	config = SpawnStruct();
	config.xpPopup = "destroyed_helo_pilot";
	// !!! NEED VO
	config.voDestroyed = undefined;
	config.callout = "callout_destroyed_helo_pilot";
	config.samDamageScale = 0.09;
	config.engineVFXtag = "tag_engine_right";
	// xpval = 200
	level.heliConfigs[ "heli_pilot" ] = config;
	
/#
	SetDevDvarIfUninitialized( "scr_helipilot_timeout", 60.0 );
#/
}

tryUseHeliPilot( lifeId, streakName )
{
	heliPilotType = "heli_pilot";
	
	numIncomingVehicles = 1;
	
	if ( IsDefined( self.underWater ) && self.underWater )
	{
		return false;
	}
	else if( exceededMaxHeliPilots( self.team ) )
	{
		self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}
	else if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount + numIncomingVehicles >= maxVehiclesAllowed() )
	{
		self IPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}
	
	// increment the faux vehicle count before we spawn the vehicle so no other vehicles try to spawn
	incrementFauxVehicleCount();
	
	heli = createHeliPilot( heliPilotType );
	
	if( !IsDefined( heli ) )
	{
		// decrement the faux vehicle count since this failed to spawn
		decrementFauxVehicleCount();

		return false;	
	}

	level.heli_pilot[ self.team ] = heli;
	
	result = self startHeliPilot( heli );
	
	if( !IsDefined( result ) )
		result = false;

	return result;
}

exceededMaxHeliPilots( team )
{
	if ( level.gameType == "dm" )
	{
		if ( IsDefined( level.heli_pilot[ team ] ) || IsDefined( level.heli_pilot[ level.otherTeam[ team ] ] ) )
			return true;
		else
			return false;
	}
	else
	{
		if ( IsDefined( level.heli_pilot[ team ] ) )
			return true;
		else
			return false;
	}
}

//============================================
// 		 watchHostMigrationFinishedInit
//============================================
watchHostMigrationFinishedInit( player )
{
	player endon( "killstreak_disowned" );
	player endon( "disconnect" );
	level  endon( "game_ended" );
	self endon ( "death" );
	
	for (;;)
	{
		level waittill( "host_migration_end" );
		
		player SetClientOmnvar( "ui_heli_pilot", 1 );
	}
}


createHeliPilot( heliPilotType )
{
	closestStartNode = heliPilot_getClosestStartNode( self.origin );		
	closestNode = heliPilot_getLinkedStruct( closestStartNode );
	startAng = VectorToAngles( closestNode.origin - closestStartNode.origin );
	
	forward = AnglesToForward( self.angles );
	targetPos = closestNode.origin + ( forward * -100 );
	
	startPos = closestStartNode.origin;
	
	heli = SpawnHelicopter( self, startPos, startAng, level.heliPilotSettings[ heliPilotType ].vehicleInfo, level.heliPilotSettings[ heliPilotType ].modelBase );
	if( !IsDefined( heli ) )
		return;

	// radius and offset should match vehHelicopterBoundsRadius (GDT) and bg_vehicle_sphere_bounds_offset_z.
	heli MakeVehicleSolidCapsule( 18, -9, 18 ); 
	
	heli maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	heli thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();

	heli.maxHealth = level.heliPilotSettings[ heliPilotType ].maxHealth;

	heli.speed = 40;
	heli.owner = self;
	heli SetOtherEnt(self);
	heli.team = self.team;
	heli.heliType = "littlebird";
	heli.heliPilotType = "heli_pilot";
	heli SetMaxPitchRoll( 45, 45 );	
	heli Vehicle_SetSpeed( heli.speed, 40, 40 );
	heli SetYawSpeed( 120, 60 );
	heli SetNearGoalNotifyDist( 32 );
	heli SetHoverParams( 100, 100, 100 );
	heli make_entity_sentient_mp( heli.team );

	heli.targetPos = targetPos;
	heli.currentNode = closestNode;
			
	heli.attract_strength = 10000;
	heli.attract_range = 150;
	heli.attractor = Missile_CreateAttractorEnt( heli, heli.attract_strength, heli.attract_range );

	// heli thread heliPilot_handleDamage(); // since the model is what players will be shooting at, it should handle the damage
	heli thread maps\mp\killstreaks\_helicopter::heli_damage_monitor( "heli_pilot" );
	heli thread heliPilot_lightFX();
	heli thread heliPilot_watchTimeout();
	heli thread heliPilot_watchOwnerLoss();
	heli thread heliPilot_watchRoundEnd();
	heli thread heliPilot_watchObjectiveCam();
	heli thread heliPilot_watchDeath();
	heli thread watchHostMigrationFinishedInit( self );

	heli.owner maps\mp\_matchdata::logKillstreakEvent( level.heliPilotSettings[ heli.heliPilotType ].streakName, heli.targetPos );	
	
	return heli;
}

heliPilot_lightFX()
{
	PlayFXOnTag( level.chopper_fx["light"]["left"], self, "tag_light_nose" );
	wait ( 0.05 );
	PlayFXOnTag( level.chopper_fx["light"]["belly"], self, "tag_light_belly" );
	wait ( 0.05 );
	PlayFXOnTag( level.chopper_fx["light"]["tail"], self, "tag_light_tail1" );
	wait ( 0.05 );
	PlayFXOnTag( level.chopper_fx["light"]["tail"], self, "tag_light_tail2" );
}

startHeliPilot( heli ) // self == player
{
	level endon( "game_ended" );
	heli endon( "death" );

	self setUsingRemote( heli.heliPilotType );

	if( GetDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( false );

	self.restoreAngles = self.angles;
	
	heli thread maps\mp\killstreaks\_flares::ks_setup_manual_flares( 2, "+smoke", "ui_heli_pilot_flare_ammo", "ui_heli_pilot_warn" );
	
	self thread watchIntroCleared( heli );

	self freezeControlsWrapper( true );
	result = self maps\mp\killstreaks\_killstreaks::initRideKillstreak( heli.heliPilotType );
	if( result != "success" )
	{
		if( IsDefined( self.disabledWeapon ) && self.disabledWeapon )
			self _enableWeapon();
		heli notify( "death" );

		return false;
	}	
	
	self freezeControlsWrapper( false );
	/*
	// need to link the player here but not give control yet
	self CameraLinkTo( heli, "tag_player" );
	
	//	go to pos
	heli SetVehGoalPos( heli.targetPos );	
	heli waittill( "near_goal" );
	heli Vehicle_SetSpeed( heli.speed, 60, 30 );	
	heli waittill( "goal" );
	*/

	
	// make sure we go to the mesh as we enter the map
	traceOffset = getHeliPilotTraceOffset();
	traceStart = ( heli.currentNode.origin ) + ( getHeliPilotMeshOffset() + traceOffset );
	traceEnd = ( heli.currentNode.origin ) + ( getHeliPilotMeshOffset() - traceOffset );
	traceResult = BulletTrace( traceStart, traceEnd, false, undefined, false, false, true );
	if( !IsDefined( traceResult["entity"] ) )
	{
/#
		// draw where it thinks this is breaking down
		self thread drawSphere( traceResult[ "position" ] - getHeliPilotMeshOffset(), 32, 10000, ( 1, 0, 0 ) );
		self thread drawSphere( heli.currentNode.origin, 16, 10000, ( 0, 1, 0 ) );
		self thread drawLine( traceStart - getHeliPilotMeshOffset(), traceEnd - getHeliPilotMeshOffset(), 10000, ( 0, 0, 1 ) );
#/
		AssertMsg( "The trace didn't hit the heli_pilot_mesh. Please grab an MP scripter." );
	}
	
	targetOrigin = ( traceResult[ "position" ] - getHeliPilotMeshOffset() ) + ( 0, 0, 250 ); // offset to make sure we're on top of the mesh
	targetNode = Spawn( "script_origin", targetOrigin );

	// link the heli into the mesh and give them control
	self RemoteControlVehicle( heli );
	
	heli thread heliGoToStartPosition( targetNode );
	heli thread heliPilot_watchADS();
	
	level thread teamPlayerCardSplash( level.heliPilotSettings[ heli.heliPilotType ].teamSplash, self );

	heli.killCamEnt = Spawn( "script_origin", self GetViewOrigin() );
	
	return true;
}

heliGoToStartPosition( targetNode ) // self == heli
{
	self endon( "death" );
	level endon( "game_ended" );
	
	self RemoteControlVehicleTarget( targetNode );
	self waittill( "goal_reached" );
	self RemoteControlVehicleTargetOff();
	
	targetNode delete();
}

watchIntroCleared( heli ) // self == player
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );
	level endon( "game_ended" );
	heli endon( "death" );
	
	self waittill( "intro_cleared" );
	self SetClientOmnvar( "ui_heli_pilot", 1 );

	// highlight the owner
	id = outlineEnableForPlayer( self, "cyan", self, false, "killstreak" );
	self removeOutline( id, heli );

	// highlight enemies
	foreach( player in level.participants )
	{
		if( !isReallyAlive( player ) || player.sessionstate != "playing" )
			continue;
		
		if( self isEnemy( player ) )
		{
			if( !player _hasPerk( "specialty_noplayertarget" ) )
			{
				id = outlineEnableForPlayer( player, "orange", self, false, "killstreak" );
				player removeOutline( id, heli );
			}
			else
			{
				player thread watchForPerkRemoval( heli );
			}
		}
	}
	
	// watch for enemies spawning while the pilot is up
	heli thread watchPlayersSpawning();
	
	// do this here to make sure we are in the killstreak before letting them leave, it was causing a bug where the player could get stuck on a black screen
	self thread watchEarlyExit( heli );
}

watchForPerkRemoval( heli ) // self == enemy player
{
	self notify( "watchForPerkRemoval" );
	self endon( "watchForPerkRemoval" );
	
	self endon( "death" );
	
	// since we give blindeye and noplayetarget each time a player spawns, we need to wait for it to be removed to turn the outline on
	self waittill( "removed_specialty_noplayertarget" );
	id = outlineEnableForPlayer( self, "orange", heli.owner, false, "killstreak" );
	self removeOutline( id, heli );
}

watchPlayersSpawning() // self == heli
{
	self endon( "leaving" );
	self endon( "death" );
	
	while( true )
	{
		level waittill( "player_spawned", player );
		if( player.sessionstate == "playing" && self.owner isEnemy( player ) )
			player thread watchForPerkRemoval( self );
	}
}

removeOutline( id, heli ) // self == player
{
	self thread heliRemoveOutline( id, heli );
	self thread playerRemoveOutline( id, heli );
}

heliRemoveOutline( id, heli ) // self == player
{
	self notify( "heliRemoveOutline" );
	self endon( "heliRemoveOutline" );
	
	self endon( "outline_removed" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	wait_array = [ "leaving", "death" ];
	heli waittill_any_in_array_return_no_endon_death( wait_array );
	
	if( IsDefined( self ) )
	{
		outlineDisable( id, self );
		self notify( "outline_removed" );
	}
}

playerRemoveOutline( id, heli ) // self == player
{
	self notify( "playerRemoveOutline" );
	self endon( "playerRemoveOutline" );

	self endon( "outline_removed" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	wait_array = [ "death" ];
	self waittill_any_in_array_return_no_endon_death( wait_array );
	
	outlineDisable( id, self );
	self notify( "outline_removed" );
}

//
//	state trackers
//

heliPilot_watchDeath()
{
	level endon( "game_ended" );
	self endon( "gone" );
	
	self waittill( "death" );
	
	if( IsDefined( self.owner ) )
		self.owner heliPilot_EndRide( self );

	if( IsDefined( self.killCamEnt ) )
		self.killCamEnt delete();
	
	self thread maps\mp\killstreaks\_helicopter::lbOnKilled();
}


heliPilot_watchObjectiveCam()
{
	level endon( "game_ended" );
	self endon( "gone" );
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );
	
	level waittill( "objective_cam" );
	
	self thread maps\mp\killstreaks\_helicopter::lbOnKilled();
	if( IsDefined( self.owner ) )
		self.owner heliPilot_EndRide( self );
}


heliPilot_watchTimeout()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );
		
	timeout = level.heliPilotSettings[ self.heliPilotType ].timeOut;
/#
	timeout = GetDvarFloat( "scr_helipilot_timeout" );
#/
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( timeout );
	
	self thread heliPilot_leave();
}


heliPilot_watchOwnerLoss()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "leaving" );

	self.owner waittill_any( "disconnect", "joined_team", "joined_spectators" );	
		
	//	leave
	self thread heliPilot_leave();
}

heliPilot_watchRoundEnd()
{
	self endon( "death" );
	self endon( "leaving" );	
	self.owner endon( "disconnect" );
	self.owner endon( "joined_team" );
	self.owner endon( "joined_spectators" );	

	level waittill_any( "round_end_finished", "game_ended" );

	//	leave
	self thread heliPilot_leave();
}

heliPilot_leave()
{
	self endon( "death" );
	self notify( "leaving" );

	if( IsDefined( self.owner ) )
		self.owner heliPilot_EndRide( self );
	
	//	rise
	flyHeight = self maps\mp\killstreaks\_airdrop::getFlyHeightOffset( self.origin );	
	targetPos = self.origin + ( 0, 0, flyHeight );
	self Vehicle_SetSpeed( 140, 60 );
	self SetMaxPitchRoll( 45, 180 );
	self SetVehGoalPos( targetPos );
	self waittill( "goal" );	
	
	//	leave
	targetPos = targetPos + AnglesToForward( self.angles ) * 15000;
	// make sure it doesn't fly away backwards
	endEnt = Spawn( "script_origin", targetPos );
	if( IsDefined( endEnt ) )
	{
		self SetLookAtEnt( endEnt );
		endEnt thread wait_and_delete( 3.0 );
	}
	self SetVehGoalPos( targetPos );
	self waittill( "goal" );
	
	//	remove
	self notify( "gone" );
	self maps\mp\killstreaks\_helicopter::removeLittlebird();
}

wait_and_delete( waitTime )
{
	self endon( "death" );
	level endon( "game_ended" );
	wait( waitTime );
	self delete();
}

heliPilot_EndRide( heli )
{
	if( IsDefined( heli ) )
	{		
		self SetClientOmnvar( "ui_heli_pilot", 0 );
		
		heli notify( "end_remote" );
		
		if( self isUsingRemote() )
			self clearUsingRemote();
		
		if( GetDvarInt( "camera_thirdPerson" ) )
			self setThirdPersonDOF( true );			
		
		self RemoteControlVehicleOff( heli );
		
		self SetPlayerAngles( self.restoreAngles );	
					
		self thread heliPilot_FreezeBuffer();
	}
}

heliPilot_FreezeBuffer()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self freezeControlsWrapper( true );
	wait( 0.5 );
	self freezeControlsWrapper( false );
}

heliPilot_watchADS() // self == heli
{
	self endon( "leaving" );
	self endon( "death" );
	level endon( "game_ended" );
	
	already_set = false;
	while( true )
	{
		if( IsDefined( self.owner ) )
		{
			if( self.owner AdsButtonPressed() )
			{
				if( !already_set )
				{
					self.owner SetClientOmnvar( "ui_heli_pilot", 2 );
					already_set = true;
				}
			}
			else
			{
				if( already_set )
				{
					self.owner SetClientOmnvar( "ui_heli_pilot", 1 );
					already_set = false;
				}
			}
		}
		
		wait( 0.1 );
	}
}

//
//	node funcs
//

heliPilot_setAirStartNodes()
{
	level.air_start_nodes = getstructarray( "chopper_boss_path_start", "targetname" );
}

heliPilot_getLinkedStruct( struct )
{
	if( IsDefined( struct.script_linkTo ) )
	{
		linknames = struct get_links();
		for( i = 0; i < linknames.size; i++ )
		{
			ent = getstruct( linknames[ i ], "script_linkname" );
			if( IsDefined( ent ) )
			{
				return ent;
			}
		}
	}

	return undefined;
}

heliPilot_getClosestStartNode( pos )
{
	// gets the start node that is closest to the position passed in
	closestNode = undefined;
	closestDistance = 999999;

	foreach( loc in level.air_start_nodes )
	{ 	
		nodeDistance = Distance( loc.origin, pos );
		if ( nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}

	return closestNode;
}


watchEarlyExit( heli )	// self == player
{
	level endon( "game_ended" );
	heli endon( "death" );
	self endon ("leaving");
	
	heli thread maps\mp\killstreaks\_killstreaks::allowRideKillstreakPlayerExit();
	
	heli waittill("killstreakExit");
	
	heli thread heliPilot_leave();
}