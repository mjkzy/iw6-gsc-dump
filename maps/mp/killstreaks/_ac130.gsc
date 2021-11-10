#include maps\mp\_utility;
#include common_scripts\utility;

CONST_AIRCRAFT_MODEL = "vehicle_y_8_gunship_mp";

init()
{
	level.ac130_use_duration = 40;
	//level.ac130_num_flares = 2;
	
	angelFlarePrecache();
	
	level._effect[ "cloud" ] 					= loadfx( "fx/misc/ac130_cloud" );
	level._effect[ "beacon" ] 					= loadfx( "fx/misc/ir_beacon_coop" );
	level._effect[ "ac130_explode" ] 			= loadfx( "fx/explosions/aerial_explosion_ac130_coop" );
	level._effect[ "ac130_flare" ] 				= loadfx( "fx/misc/flares_cobra" );
	level._effect[ "ac130_light_red" ] 			= loadfx( "fx/misc/aircraft_light_wingtip_red" );
	level._effect[ "ac130_light_white_blink" ] 	= loadfx( "fx/misc/aircraft_light_white_blink" );
	level._effect[ "ac130_light_red_blink" ]	= loadfx( "fx/misc/aircraft_light_red_blink" );
	level._effect[ "ac130_engineeffect" ]		= loadfx( "fx/fire/jet_engine_ac130" );

	// ac130 muzzleflash effects for player on ground to see
	level._effect[ "coop_muzzleflash_105mm" ] = loadfx( "fx/muzzleflashes/ac130_105mm" );
	level._effect[ "coop_muzzleflash_40mm" ] = loadfx( "fx/muzzleflashes/ac130_40mm" );
	
	level.radioForcedTransmissionQueue = [];
	level.enemiesKilledInTimeWindow = 0;
	level.lastRadioTransmission = getTime();
	
	level.color[ "white" ] = ( 1, 1, 1 );
	level.color[ "red" ] = ( 1, 0, 0 );
	level.color[ "blue" ] = ( .1, .3, 1 );
	
	level.cosine = [];
	level.cosine[ "45" ] = cos( 45 );
	level.cosine[ "5" ] = cos( 5 );
	
	level.physicsSphereRadius[ "ac130_25mm_mp" ] = 60;
	level.physicsSphereRadius[ "ac130_40mm_mp" ] = 600;
	level.physicsSphereRadius[ "ac130_105mm_mp" ] = 1000;
	
	level.physicsSphereForce[ "ac130_25mm_mp" ] = 0;
	level.physicsSphereForce[ "ac130_40mm_mp" ] = 3.0;
	level.physicsSphereForce[ "ac130_105mm_mp" ] = 6.0;
	
	level.weaponReloadTime[ "ac130_25mm_mp" ] = 1.5;
	level.weaponReloadTime[ "ac130_40mm_mp" ] = 3.0;
	level.weaponReloadTime[ "ac130_105mm_mp" ] = 5.0;
	
	level.ac130_Speed[ "move" ] = 250;
	level.ac130_Speed[ "rotate" ] = 70;
	
	//flag_init( "ir_beakons_on" );
	flag_init( "allow_context_sensative_dialog" );
	flag_set( "allow_context_sensative_dialog" );
	minimapOrigins = getEntArray( "minimap_corner", "targetname" );
	ac130Origin = (0,0,0);
	
	if ( miniMapOrigins.size )
		ac130Origin = maps\mp\gametypes\_spawnlogic::findBoxCenter( miniMapOrigins[0].origin, miniMapOrigins[1].origin );
	
	level.ac130 = spawn( "script_model", ac130Origin );
	level.ac130 setModel( "c130_zoomRig" );
	level.ac130.angles = ( 0, 115, 0 );
	level.ac130.owner = undefined;
	level.ac130.thermal_vision = "ac130_thermal_mp";
	level.ac130.enhanced_vision = "ac130_enhanced_mp";
	
	// used for debug printing
	level.ac130.targetname = "ac130rig_script_model";

	level.ac130 hide();

	level.ac130InUse = false;

	thread rotatePlane( "on" );
	thread ac130_spawn();
	thread onPlayerConnect();
	
	//thread handleIncomingStinger();
	//thread handleIncomingSAM();
	
	level.killstreakFuncs["ac130"] = ::tryUseAC130;
	
	level.ac130Queue = [];

/#
	SetDevDvarIfUninitialized( "scr_ac130_timeout", level.ac130_use_duration );
	SetDevDvarIfUninitialized( "scr_debugac130", 0 );
	level thread debug_AC130();
	
	AddDebugCommand( "bind p \"set scr_givekillstreak " + "ac130" + "\"\n" );
#/
}


tryUseAC130( lifeId, streakName )
{
	if ( IsDefined( level.ac130player ) || level.ac130InUse )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}

	if ( self isUsingRemote() )
	{
		return false;
	}
	
	if ( self isKillStreakDenied() )
	{
		return false;
	}

	self setUsingRemote( "ac130" );
	result = self maps\mp\killstreaks\_killstreaks::initRideKillstreak( streakName );
	if ( result != "success" )
	{
		if ( result != "disconnect" )
			self clearUsingRemote();

		return false;
	}	

	result = setAC130Player( self );
	
	// this needs to get set after we say the player is using it because this could get set to true and then they leave the game
	// this fixes a bug where a player calls it, leaves before getting fully in it and then no one else can call it because it thinks it's being used
	if( IsDefined( result ) && result )
	{
		//AC130 is now a map specific killstreak and does not log events
		//self maps\mp\_matchdata::logKillstreakEvent( "ac130", self.origin );

		//self.ac130LifeId = lifeId;
		level.ac130.planeModel.crashed = undefined;

		level.ac130InUse = true;
	}
	else
	{
		self clearUsingRemote();
	}

	return ( IsDefined( result ) && result );
}


init_sounds()
{
	level.scr_sound["foo"]["bar"] = "";
	//-------------------------------------------------------------------------------------------------
	//CONTEXT SENSATIVE DIALOG
	//-------------------------------------------------------------------------------------------------
	
	add_context_sensative_dialog( "ai", "in_sight", 0, "ac130_fco_getthatguy" );		// Get that guy.
	add_context_sensative_dialog( "ai", "in_sight", 1, "ac130_fco_guymovin" );			// Roger, guy movin'.
	add_context_sensative_dialog( "ai", "in_sight", 2, "ac130_fco_getperson" );			// Get that person.
	add_context_sensative_dialog( "ai", "in_sight", 3, "ac130_fco_guyrunnin" );			// Guy runnin'.
	add_context_sensative_dialog( "ai", "in_sight", 4, "ac130_fco_gotarunner" );		// Uh, we got a runner here.
	add_context_sensative_dialog( "ai", "in_sight", 5, "ac130_fco_backonthose" );		// Get back on those guys.
	add_context_sensative_dialog( "ai", "in_sight", 6, "ac130_fco_gonnagethim" );		// You gonna get him?

	add_context_sensative_dialog( "ai", "in_sight", 7, "ac130_fco_nailthoseguys" );		// Nail those guys.
	add_context_sensative_dialog( "ai", "in_sight", 8, "ac130_fco_lightemup" );			// Light ‘em up.
	add_context_sensative_dialog( "ai", "in_sight", 9, "ac130_fco_takehimout" );		// Yeah take him out.
	add_context_sensative_dialog( "ai", "in_sight", 10, "ac130_plt_yeahcleared" );		// Yeah, cleared to engage.
	add_context_sensative_dialog( "ai", "in_sight", 11, "ac130_plt_copysmoke" );		// Copy, smoke ‘em.
	
	add_context_sensative_dialog( "ai", "wounded_crawl", 0, "ac130_fco_movingagain" );		// Ok he’s moving again.
	add_context_sensative_timeout( "ai", "wounded_crawl", undefined, 6 );
	
	add_context_sensative_dialog( "ai", "wounded_pain", 0, "ac130_fco_doveonground" );		// Yeah, he just dove on the ground.	
	add_context_sensative_dialog( "ai", "wounded_pain", 1, "ac130_fco_knockedwind" );		// Probably just knocked the wind out of him.
	add_context_sensative_dialog( "ai", "wounded_pain", 2, "ac130_fco_downstillmoving" );	// That guy's down but still moving.
	add_context_sensative_dialog( "ai", "wounded_pain", 3, "ac130_fco_gettinbackup" );		// He's gettin' back up.
	add_context_sensative_dialog( "ai", "wounded_pain", 4, "ac130_fco_yepstillmoving" );	// Yep, that guy’s still moving.
	add_context_sensative_dialog( "ai", "wounded_pain", 5, "ac130_fco_stillmoving" );		// He's still moving.
	add_context_sensative_timeout( "ai", "wounded_pain", undefined, 12 );
	
	add_context_sensative_dialog( "weapons", "105mm_ready", 0, "ac130_gnr_gunready1" );
	
	add_context_sensative_dialog( "weapons", "105mm_fired", 0, "ac130_gnr_shot1" );
	
	add_context_sensative_dialog( "plane", "rolling_in", 0, "ac130_plt_rollinin" );
	
	add_context_sensative_dialog( "explosion", "secondary", 0, "ac130_nav_secondaries1" );
	add_context_sensative_timeout( "explosion", "secondary", undefined, 7 );
	
	add_context_sensative_dialog( "kill", "single", 0, "ac130_plt_gottahurt" );			// Ooo that's gotta hurt.
	add_context_sensative_dialog( "kill", "single", 1, "ac130_fco_iseepieces" );		// Yeah, good kill. I see lots of little pieces down there.
	add_context_sensative_dialog( "kill", "single", 2, "ac130_fco_oopsiedaisy" );		// (chuckling) Oopsie-daisy.
	add_context_sensative_dialog( "kill", "single", 3, "ac130_fco_goodkill" );			// Good kill good kill.
	add_context_sensative_dialog( "kill", "single", 4, "ac130_fco_yougothim" );			// You got him.
	add_context_sensative_dialog( "kill", "single", 5, "ac130_fco_yougothim2" );		// You got him!
	add_context_sensative_dialog( "kill", "single", 6, "ac130_fco_thatsahit" );			// That's a hit.
	add_context_sensative_dialog( "kill", "single", 7, "ac130_fco_directhit" );			// Direct hit.
	add_context_sensative_dialog( "kill", "single", 8, "ac130_fco_rightontarget" );		// Yep, that was right on target.
	add_context_sensative_dialog( "kill", "single", 9, "ac130_fco_okyougothim" );		// Ok, you got him. Get back on the other guys.
	add_context_sensative_dialog( "kill", "single", 10, "ac130_fco_within2feet" );		// All right you got the guy. That might have been within two feet of him.
	
	add_context_sensative_dialog( "kill", "small_group", 0, "ac130_fco_nice" );			// (chuckling) Niiiice.
	add_context_sensative_dialog( "kill", "small_group", 1, "ac130_fco_directhits" );	// Yeah, direct hits right there.
	add_context_sensative_dialog( "kill", "small_group", 2, "ac130_fco_iseepieces" );	// Yeah, good kill. I see lots of little pieces down there.
	add_context_sensative_dialog( "kill", "small_group", 3, "ac130_fco_goodkill" );		// Good kill good kill.
	add_context_sensative_dialog( "kill", "small_group", 4, "ac130_fco_yougothim" );	// You got him.
	add_context_sensative_dialog( "kill", "small_group", 5, "ac130_fco_yougothim2" );	// You got him!
	add_context_sensative_dialog( "kill", "small_group", 6, "ac130_fco_thatsahit" );	// That's a hit.
	add_context_sensative_dialog( "kill", "small_group", 7, "ac130_fco_directhit" );	// Direct hit.
	add_context_sensative_dialog( "kill", "small_group", 8, "ac130_fco_rightontarget" );// Yep, that was right on target.
	add_context_sensative_dialog( "kill", "small_group", 9, "ac130_fco_okyougothim" );	// Ok, you got him. Get back on the other guys.

	add_context_sensative_dialog( "misc", "action", 0, "ac130_fco_tracking" );			// In the area.
	add_context_sensative_timeout( "misc", "action", 0, 70 );
	
	add_context_sensative_dialog( "misc", "action", 1, "ac130_fco_moreenemy" );			// Got a crowd down there.
	add_context_sensative_timeout( "misc", "action", 1, 80 );
	
	add_context_sensative_dialog( "misc", "action", 2, "ac130_random" );				// Call visual.
	add_context_sensative_timeout( "misc", "action", 2, 55 );
	
	add_context_sensative_dialog( "misc", "action", 3, "ac130_fco_rightthere" );		// Still got movement down there.
	add_context_sensative_timeout( "misc", "action", 3, 100 );
}


add_context_sensative_dialog( name1, name2, group, soundAlias )
{
	assert( IsDefined( name1 ) );
	assert( IsDefined( name2 ) );
	assert( IsDefined( group ) );
	assert( IsDefined( soundAlias ) );

	fullSoundAlias = maps\mp\gametypes\_teams::getTeamVoicePrefix( "allies" ) + soundAlias;
	assertex( soundexists( fullSoundAlias ), "ERROR: missing soundalias " + fullSoundAlias );

	fullSoundAlias = maps\mp\gametypes\_teams::getTeamVoicePrefix( "axis" ) + soundAlias;
	assertex( soundexists( fullSoundAlias ), "ERROR: missing soundalias " + fullSoundAlias );
	
	if( ( !IsDefined( level.scr_sound[ name1 ] ) ) || ( !IsDefined( level.scr_sound[ name1 ][ name2 ] ) ) || ( !IsDefined( level.scr_sound[ name1 ][ name2 ][group] ) ) )
	{
		// creating group for the first time
		level.scr_sound[ name1 ][ name2 ][group] = spawnStruct();
		level.scr_sound[ name1 ][ name2 ][group].played = false;
		level.scr_sound[ name1 ][ name2 ][group].sounds = [];
	}
	
	//group exists, add the sound to the array
	index = level.scr_sound[ name1 ][ name2 ][group].sounds.size;
	level.scr_sound[ name1 ][ name2 ][group].sounds[index] = soundAlias;
}


add_context_sensative_timeout( name1, name2, groupNum, timeoutDuration )
{
	if( !IsDefined( level.context_sensative_dialog_timeouts ) )
		level.context_sensative_dialog_timeouts = [];
	
	createStruct = false;
	if ( !IsDefined( level.context_sensative_dialog_timeouts[ name1 ] ) )
		createStruct = true;
	else if ( !IsDefined( level.context_sensative_dialog_timeouts[ name1 ][ name2 ] ) )
		createStruct = true;
	if ( createStruct )
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ] = spawnStruct();
	
	if ( IsDefined( groupNum ) )
	{
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups = [];
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ] = spawnStruct();
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ].v["timeoutDuration"] = timeoutDuration * 1000;
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ].v["lastPlayed"] = ( timeoutDuration * -1000 );
	}
	else
	{
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ].v["timeoutDuration"] = timeoutDuration * 1000;
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ].v["lastPlayed"] = ( timeoutDuration * -1000 );
	}
}


/* 
 ============= 
///ScriptDocBegin
"Name: play_sound_on_entity( <alias> )"
"Summary: Play the specified sound alias on an entity at it's origin"
"Module: Sound"
"CallOn: An entity"
"MandatoryArg: <alias> : Sound alias to play"
"Example: level.player play_sound_on_entity( "breathing_better" );"
"SPMP: singleplayer"
///ScriptDocEnd
 ============= 
 */ 
play_sound_on_entity( alias )
{
	play_sound_on_tag( alias );
}

/*
=============
///ScriptDocBegin
"Name: array_remove_nokeys( <ents> , <remover> )"
"Summary: array_remove used on non keyed arrays doesn't flip the array "
"Module: Utility"
"CallOn: Level"
"MandatoryArg: <ents>: array to remove from"
"MandatoryArg: <remover>: thing to remove from the array"
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

array_remove_nokeys( ents, remover )
{
	newents = [];
	for ( i = 0; i < ents.size; i++ )
		if ( ents[ i ] != remover )
			newents[ newents.size ] = ents[ i ];
	return newents;
}

array_remove_index( array, index )
{
	newArray = [];
	keys = getArrayKeys( array );
	for ( i = ( keys.size - 1 );i >= 0 ; i -- )
	{
		if ( keys[ i ] != index )
			newArray[ newArray.size ] = array[ keys[ i ] ];
	}

	return newArray;
}


string( num )
{
	return( "" + num );
}


onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		
		player thread onPlayerSpawned();
	}
}


onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");
	}
}


deleteOnAC130PlayerRemoved()
{
	level waittill ( "ac130player_removed" );
	
	self delete();
}

monitorManualPlayerExit()
{
	level endon( "game_ended" );
	level endon( "ac130player_removed" );
	
	self endon ( "disconnect" );
	
	level.ac130 thread maps\mp\killstreaks\_killstreaks::allowRideKillstreakPlayerExit();
	
	level.ac130 waittill("killstreakExit");
	
	if( IsDefined( level.ac130.owner ) )
	{
		level thread removeAC130Player( level.ac130.owner, false );
	}
}

setAC130Player( player )
{
	self endon ( "ac130player_removed" );
	
	if( IsDefined( level.ac130player ) )
		return false;
	
	init_sounds();
	player SetClientOmnvar( "enableCustomAudioZone", true );	// in iw6, this replaces the ambiance setting?
	
	level.ac130player = player;
	level.ac130.owner = player;
	level.ac130.planeModel show();
	level.ac130.planemodel thread playAC130Effects();
	level.ac130.incomingMissile = false;
	
	level.ac130.planeModel playLoopSound( "veh_ac130iw6_ext_dist" );

	level.ac130.planeModel thread damageTracker();
	self thread handleIncomingMissiles();
	
	level.ac130.planeModel ThermalDrawEnable();
	
	// This creates the plane model for the minimap
	objModel = spawnPlane( player, "script_model", level.ac130.planeModel.origin, "compass_objpoint_c130_friendly", "compass_objpoint_c130_enemy" );
	objModel notSolid();
	objModel linkTo( level.ac130, "tag_player", ( 0, 80, 32 ), ( 0, -90, 0 ) );
	objModel thread deleteOnAC130PlayerRemoved();
	
	// AC130 commenting this out, deprecated code
	//player startAC130();

	//level.ac130.numFlares = level.ac130_num_flares;

/*
	result = player maps\mp\killstreaks\_killstreaks::initRideKillstreak();
	if ( result != "success" )
	{
		if ( result != "disconnect" )
		{
			if ( result == "fail" )
				player maps\mp\killstreaks\_killstreaks::giveKillstreak( "ac130", player.ac130LifeId == player.pers["deaths"], false );

			level thread removeAC130Player( player, result == "disconnect" );
		}

		return;
	}
*/
	thread teamPlayerCardSplash( "used_ac130", player );
	
	// with the way we do visionsets we need to wait for the clearRideIntro() is done before we set thermal

	player thread waitSetThermal( 1.0 );
	player thread reInitializeThermal( level.ac130.planeModel );

	if ( getDvarInt( "camera_thirdPerson" ) )
		player setThirdPersonDOF( false );
	
	player _giveWeapon("ac130_105mm_mp");
	player _giveWeapon("ac130_40mm_mp");
	player _giveWeapon("ac130_25mm_mp");
	player SwitchToWeapon("ac130_105mm_mp");
	// this needs to occur before hud gets initialized to show the countdown timer correctly
	player thread removeAC130PlayerAfterTime( level.ac130_use_duration * player.killStreakScaler );
	player SetClientOmnvar( "ui_ac130_hud", 1 );

	player thread overlay_coords();	
	player SetBlurForPlayer( 1.2, 0 );

	player thread attachPlayer( player );
	player thread changeWeapons();
	player thread weaponFiredThread();
	player thread context_Sensative_Dialog();
	player thread shotFired();
	player thread clouds();
	
	if ( IsBot( self ) )
	{
		self.vehicle_controlling = level.ac130;
		player thread ac130_control_bot_aiming();
	}
	
	player thread watchHostMigrationFinishedInit();
	player thread removeAC130PlayerOnDisconnect();
	player thread removeAC130PlayerOnChangeTeams();
	player thread removeAC130PlayerOnSpectate();
	//player thread removeAC130PlayerOnDeath();
	player thread removeAC130PlayerOnCrash();
	//player thread removeAC130PlayerOnGameEnd();
	player thread removeAC130PlayerOnGameCleanup();
	player thread monitorManualPlayerExit();
	
	thread AC130_AltScene();

	return true;
}

// DM 5/15/14 - reinit all omnvars for the HUD after a host migration
// Forcing the weapon back to 105mm otherwise the reticle won't show until the player changes weapons
initAC130Hud()
{
	self SetClientOmnvar( "ui_ac130_hud", 1 );
	waitframe();
	self SwitchToWeapon( "ac130_105mm_mp" );
	waitframe();
	self SetClientOmnvar( "ui_ac130_weapon", 0 );
	waitframe();
	self SetClientOmnvar( "ui_ac130_105mm_ammo", self GetWeaponAmmoClip( "ac130_105mm_mp" ) );
	waitframe();
	self SetClientOmnvar( "ui_ac130_40mm_ammo", self GetWeaponAmmoClip( "ac130_40mm_mp" ) );
	waitframe();
	self SetClientOmnvar( "ui_ac130_25mm_ammo", self GetWeaponAmmoClip( "ac130_25mm_mp" ) );
	waitframe();
	self thread overlay_coords();
	self SetClientOmnvar( "enableCustomAudioZone", true );	
}

watchHostMigrationFinishedInit()
{
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );
	level endon( "game_ended" );
	self endon( "death" );
	
	for(;;)
	{
		level waittill( "host_migration_end" );
		
		self initAC130Hud();
	}
}

waitSetThermal( delay )
{
	self endon( "disconnect" );
	level endon( "ac130player_removed" );

	wait( delay	);

	self VisionSetThermalForPlayer( game["thermal_vision"], 0 );
	self ThermalVisionFOFOverlayOn();
	self thread thermalVision();
}

playAC130Effects()
{
	wait .05;
	PlayFXOnTag( level._effect[ "ac130_light_red_blink" ] , self, "tag_light_belly" );
	PlayFXOnTag( level._effect[ "ac130_engineeffect" ] , self, "tag_body" );
	wait .5;
	PlayFXOnTag( level._effect[ "ac130_light_white_blink" ] , self, "tag_light_tail" );
	PlayFXOnTag( level._effect[ "ac130_light_red" ] , self, "tag_light_top" );
	
	wait(0.5);
	PlayFXOnTag( level.fx_airstrike_contrail, self, "tag_light_L_wing" );
	PlayFXOnTag( level.fx_airstrike_contrail, self, "tag_light_R_wing" );
}

AC130_AltScene()
{
	// need team check
	foreach ( player in level.players )
	{
		if ( player != level.ac130player && player.team == level.ac130player.team )
			player thread setAltSceneObj( level.ac130.cameraModel, "tag_origin", 20 );
	}
}


removeAC130PlayerOnGameEnd()
{
	self endon ( "ac130player_removed" );
	
	level waittill ( "game_ended" );

	level thread removeAC130Player( self, false );
}


removeAC130PlayerOnGameCleanup()
{
	self endon ( "ac130player_removed" );
	
	level waittill ( "game_cleanup" );

	level thread removeAC130Player( self, false );
}


removeAC130PlayerOnDeath()
{
	self endon ( "ac130player_removed" );
	
	self waittill ( "death" );

	level thread removeAC130Player( self, false );
}


removeAC130PlayerOnCrash()
{
	self endon ( "ac130player_removed" );
	
	level.ac130.planeModel waittill ( "crashing" );

	level thread removeAC130Player( self, false );
}


removeAC130PlayerOnDisconnect()
{
	self endon ( "ac130player_removed" );

	self waittill ( "disconnect" );

	level thread removeAC130Player( self, true );
}

removeAC130PlayerOnChangeTeams()
{
	self endon ( "ac130player_removed" );

	self waittill ( "joined_team" );

	level thread removeAC130Player( self, false);
}

removeAC130PlayerOnSpectate()
{
	self endon ( "ac130player_removed" );

	self waittill_any ( "joined_spectators", "spawned" );

	level thread removeAC130Player( self, false);
}

removeAC130PlayerAfterTime( removeDelay )
{
	self endon ( "ac130player_removed" );
	
	lifeSpan = removeDelay;
/#
	lifeSpan = GetDvarInt( "scr_ac130_timeout" );
#/
		
	self SetClientOmnvar( "ui_ac130_use_time", ( lifeSpan * 1000 ) + GetTime() );
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( lifeSpan );
	self SetClientOmnvar( "ui_ac130_use_time", 0 );

	level thread removeAC130Player( self, false );
}

removeAC130Player( player, disconnected )
{
	player notify ( "ac130player_removed" );
	level notify ( "ac130player_removed" );
	
	level.ac130.cameraModel notify ( "death" );
	
	waittillframeend;

	if ( !disconnected )
	{
		player clearUsingRemote();

		player stopLocalSound( "missile_incoming" ); 
		player StopLoopSound();

		player show();
		player unlink();		
		// restore bots view to bot
		if ( IsBot( player ) )
		{
			player ControlsUnlink();
			player CameraUnlink();
			player.vehicle_controlling = undefined;
		}
	
		player ThermalVisionOff();
		player ThermalVisionFOFOverlayOff();
		player VisionSetThermalForPlayer( level.ac130.thermal_vision, 0 );
		player.lastVisionSetThermal = level.ac130.thermal_vision;
		player setBlurForPlayer( 0, 0 );
		// AC130 commenting this out, deprecated code.
		//player stopAC130();

		if ( getDvarInt( "camera_thirdPerson" ) )
			player setThirdPersonDOF( true );

		// take the killstreak weapons
		killstreakWeapon = getKillstreakWeapon( "ac130" );
		player TakeWeapon( killstreakWeapon );
		player TakeWeapon( "ac130_105mm_mp" );
		player TakeWeapon( "ac130_40mm_mp" );
		player TakeWeapon( "ac130_25mm_mp" );

		player SetClientOmnvar( "ui_ac130_hud", 0 );
		player SetClientOmnvar( "enableCustomAudioZone", false );	
	}
	
	self removeFromLittleBirdList();
	
	// delay before AC130 can be used again
	wait ( 0.5 );
	
	level.ac130.planeModel playSound( "veh_ac130iw6_ext_dist_fade" );
	
	wait ( 0.5 );

	// TODO: this might already be undefined if the player disconnected... need a better solution.
	// we could set it to "true" or something... but we'll have to check places it is used for potential issues with that.
	level.ac130player = undefined;
	level.ac130.planeModel hide();
	level.ac130.planeModel stopLoopSound();
	
	if ( IsDefined( level.ac130.planeModel.crashed ) )
	{
		level.ac130InUse = false;
		return;
	}
	
	ac130model = spawn( "script_model", level.ac130.planeModel getTagOrigin( "tag_origin" ) );
	ac130model.angles = level.ac130.planeModel.angles;
	ac130model setModel( CONST_AIRCRAFT_MODEL );
	destPoint = ac130model.origin + ( anglestoright( ac130model.angles ) * 20000 );
	
	destPoint = destPoint + (0, 0, 10000);	// increase the altitude b/c in favela, it might hit the mountain.

	ac130model thread playAC130Effects();	
	ac130model moveTo( destPoint, 40.0, 0.0, 0.0 );
	
	// straighten out the plane
	planeAngles = (0, ac130model.angles[1], -20);
	ac130model RotateTo( planeAngles, 30, 1, 1 );
	
	ac130model thread deployFlares( true );

	wait ( 5.0 );
	ac130model thread deployFlares( true );

	wait ( 5.0 );
	ac130model thread deployFlares( true );

	level.ac130InUse = false;

	wait ( 30.0 );

	ac130model delete();
}

removeFromLittleBirdList()
{
	entNum = level.ac130.planeModel GetEntityNumber();
	
	level.littleBirds[ entNum ] = undefined;
}

damageTracker() // self == level.ac130.planeModel
{
	self endon( "death" );
	self endon( "crashing" );
	level endon( "game_ended" );
	level endon( "ac130player_removed" );

	self.health = 999999; // keep it from dying anywhere in code
	self.maxHealth = 1000; // this is the health we'll check
	self.damageTaken = 0; // how much damage has it taken
	
	// DM - 5/14/14 - adding AC130 to lblist, which isn't ideal, but I'd rather not add special cases into _weapons.gsc for map specfic KS
	self.team = level.ac130player.team;
	self maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	self.attractor = Missile_CreateAttractorEnt( self, 1000, 4096 ); 

	for ( ;; )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, sMeansOfDeath, modelName, tagName, partName, iDFlags, sWeapon );

		if ( IsDefined( level.ac130player ) && level.teambased && isPlayer( attacker ) && attacker.team == level.ac130player.team && !IsDefined( level.nukeDetonated ) )
			continue;

		if ( sMeansOfDeath == "MOD_RIFLE_BULLET" || sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_EXPLOSIVE_BULLET" )
			continue;
		
		self.wasDamaged = true;

		modifiedDamage = damage;

		if ( isPlayer( attacker ) )
  		{
  			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "ac130" );
  		}
  		
		maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, sWeapon, level.ac130 );
		
		// in case we are shooting from a remote position, like being in the osprey gunner shooting this
		if( IsDefined( attacker.owner ) && IsPlayer( attacker.owner ) )
		{
			attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "ac130" );
		}
		
		self.damageTaken += modifiedDamage;		

		if ( self.damageTaken >= self.maxHealth )
		{
			if ( isPlayer( attacker ) )
			{
				thread maps\mp\gametypes\_missions::vehicleKilled( level.ac130player, self, undefined, attacker, damage, sMeansOfDeath, sWeapon );
				thread teamPlayerCardSplash( "callout_destroyed_ac130", attacker );
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 400, sWeapon, sMeansOfDeath );
				attacker notify( "destroyed_killstreak" );
			}

			level thread crashPlane( 10.0 );
		}
	}
}


ac130_spawn()
{
	wait 0.05;
	
	ac130model = spawn( "script_model", level.ac130 getTagOrigin( "tag_player" ) );
	ac130model setModel( CONST_AIRCRAFT_MODEL );
	
	// used for debug printing
	ac130model.targetname = CONST_AIRCRAFT_MODEL;

	ac130model setCanDamage( true );
	ac130model.maxhealth = 1000;
	ac130model.health = ac130model.maxhealth;
		
	ac130model linkTo( level.ac130, "tag_player", ( 0, 80, 32 ), ( -25, 0, 0 ) );
	level.ac130.planeModel = ac130model;
	level.ac130.planeModel hide();

	ac130CameraModel = spawn( "script_model", level.ac130 getTagOrigin( "tag_player" ) );
	ac130CameraModel setModel( "tag_origin" );
	ac130CameraModel hide();

	// used for debug printing
	ac130CameraModel.targetname = "ac130CameraModel";

	ac130CameraModel linkTo( level.ac130, "tag_player", ( 0, 0, 32 ), ( 5, 0, 0 ) );
	level.ac130.cameraModel = ac130CameraModel;
	
	// moving this call to mp_favela_iw6.gsc, otherwise level.players is undefined as this gets called before the map loads
	//level.ac130player = level.players[0];
}

overlay_coords()
{
	self endon ( "ac130player_removed" );
	
	wait 0.05;
	self thread updatePlaneModelCoords();
	//self thread updatePlayerPositionCoords();
	self thread updateAimingCoords();
}

updatePlaneModelCoords()
{
	self endon ( "ac130player_removed" );

	while( true )
	{
		// ac130 plane model position
		self SetClientOmnvar( "ui_ac130_coord1_posx", abs( level.ac130.planeModel.origin[0] ) );
		self SetClientOmnvar( "ui_ac130_coord1_posy", abs( level.ac130.planeModel.origin[1] ) );
		self SetClientOmnvar( "ui_ac130_coord1_posz", abs( level.ac130.planeModel.origin[2] ) );

		wait( 0.5 );
	}
}

updatePlayerPositionCoords()
{
	self endon ( "ac130player_removed" );
	// player position stays the same once we're in the air, no need to continuously poll pos
	waitframe();
	self SetClientOmnvar( "ui_ac130_coord2_posx", abs( self.origin[0] ) );
	self SetClientOmnvar( "ui_ac130_coord2_posy", abs( self.origin[1] ) );
	self SetClientOmnvar( "ui_ac130_coord2_posz", abs( self.origin[2] ) );
}

updateAimingCoords()
{
	self endon ( "ac130player_removed" );

	while( true )
	{
		origin = self GetEye();
		angles = self GetPlayerAngles();
		forward = AnglesToForward( angles );
		endpoint = origin + forward * 15000;
		pos = PhysicsTrace( origin, endpoint );
		// aiming position
		self SetClientOmnvar( "ui_ac130_coord3_posx", abs( pos[0] ) );
		self SetClientOmnvar( "ui_ac130_coord3_posy", abs( pos[1] ) );
		self SetClientOmnvar( "ui_ac130_coord3_posz", abs( pos[2] ) );

		wait( 0.1 );
	}
}


ac130ShellShock()
{
	self endon ( "ac130player_removed" );

	level endon( "post_effects_disabled" );
	duration = 5;
	for (;;)
	{
		self shellshock( "ac130", duration );
		wait duration;
	}
}


rotatePlane( toggle )
{
	level notify("stop_rotatePlane_thread");
	level endon("stop_rotatePlane_thread");
	
	if (toggle == "on")
	{
		rampupDegrees = 10;
		rotateTime = ( level.ac130_Speed[ "rotate" ] / 360 ) * rampupDegrees;
		level.ac130 rotateyaw( level.ac130.angles[ 2 ] + rampupDegrees, rotateTime, rotateTime, 0 );
		
		for (;;)
		{
			level.ac130 rotateyaw( 360, level.ac130_Speed[ "rotate" ] );
			wait level.ac130_Speed[ "rotate" ];
		}
	}
	else if (toggle == "off")
	{
		slowdownDegrees = 10;
		rotateTime = ( level.ac130_Speed[ "rotate" ] / 360 ) * slowdownDegrees;
		level.ac130 rotateyaw( level.ac130.angles[ 2 ] + slowdownDegrees, rotateTime, 0, rotateTime );
	}
}

/#
debug_AC130()
{
	level endon( "game_ended" );
	while( true )
	{
		if( GetDvarInt( "scr_debugac130" ) )
		{
			if( IsDefined( level.ac130.planeModel ) )
			{
				Line( level.ac130.origin, self.ac130.planeModel.origin, ( 1, 0, 0 ) );
				Print3d( level.ac130 getTagOrigin( "tag_player" ), "tag_player", ( 0, 0, 1 ) );
				Print3d( level.ac130.origin, "level.ac130 origin", ( 0, 0, 1 ) );
				Print3d( level.ac130.planeModel.origin, "level.ac130.planeModel origin", ( 0, 0, 1 ) );
			}
		}
		wait( 0.05 );
	}
}
#/

attachPlayer( player )
{
	if ( IsBot( player ) )
    {
	    player CameraLinkTo( level.ac130, "tag_player" );
    }
	// 2014-05-12 wallace: in IW6, we found a sound bug. Linking player view to the orbiting rig would confuse the sound system, 
	// which would try to use the origin of the rig as the player's listening position.
	// We'll use a different model that is closer to the player's actual position to link to.
	// As a hack, we'll use the camera model, because PlayerLinkWeaponviewToDelta will fall through to tag_origin if a tag_player is not found.
	self PlayerLinkWeaponviewToDelta( level.ac130.cameramodel, "tag_player", 1.0, 35, 35, 35, 35 );
	self setPlayerAngles( level.ac130 getTagAngles( "tag_player" ) );
}


changeWeapons()
{
	self endon ( "ac130player_removed" );

	wait( 0.05 );
	self EnableWeapons();
	//DM 4/10/14 - added this call in, as it gets set to disabled in beginKillstreakWeaponSwitch() after using KS
	self enableWeaponSwitch();
	waitframe();
	self SetClientOmnvar( "ui_ac130_105mm_ammo", self GetWeaponAmmoClip( "ac130_105mm_mp" ) );
	waitframe();
	self SetClientOmnvar( "ui_ac130_40mm_ammo", self GetWeaponAmmoClip( "ac130_40mm_mp" ) );
	waitframe();
	self SetClientOmnvar( "ui_ac130_25mm_ammo", self GetWeaponAmmoClip( "ac130_25mm_mp" ) );

	for(;;)
	{
		self waittill ( "weapon_change", newWeapon );

		self thread play_sound_on_entity( "ac130iw6_weapon_switch" );
		
		self notify( "reset_25mm" );
		self StopLoopSound( "ac130iw6_25mm_fire_loop" );
		switch( newWeapon )
		{
		case "ac130_105mm_mp":
			self SetClientOmnvar( "ui_ac130_weapon", 0 );
			break;
		case "ac130_40mm_mp":
			self SetClientOmnvar( "ui_ac130_weapon", 1 );
			break;
		case "ac130_25mm_mp":
			self SetClientOmnvar( "ui_ac130_weapon", 2 );
			self thread playSound25mm();
			break;
		}
	}
}


weaponFiredThread()
{
	self endon ( "ac130player_removed" );

	for(;;)
	{
		self waittill( "weapon_fired" );
		
		weapon = self getCurrentWeapon();
		
		switch( weapon )
		{
		case "ac130_105mm_mp":
			self thread gun_fired_and_ready_105mm();			
			Earthquake (0.2, 1, level.ac130.planeModel.origin, 1000);
			self SetClientOmnvar( "ui_ac130_105mm_ammo", self GetWeaponAmmoClip( weapon ) );
			break;
		case "ac130_40mm_mp":
			Earthquake (0.1, 0.5, level.ac130.planeModel.origin, 1000);
			self SetClientOmnvar( "ui_ac130_40mm_ammo", self GetWeaponAmmoClip( weapon ) );
			break;
		case "ac130_25mm_mp":
			self SetClientOmnvar( "ui_ac130_25mm_ammo", self GetWeaponAmmoClip( weapon ) );
			break;
		}

		if ( self GetWeaponAmmoClip( weapon ) )
			continue;
			
		self thread weaponReload( weapon );
	}
}


weaponReload( weapon )
{
	self endon ( "ac130player_removed" );

	wait level.weaponReloadTime[ weapon ];
	
	self SetWeaponAmmoClip( weapon, 9999 );
	
	switch( weapon )
	{
	case "ac130_105mm_mp":
		self SetClientOmnvar( "ui_ac130_105mm_ammo", self GetWeaponAmmoClip( weapon ) );
		break;
	case "ac130_40mm_mp":
		self SetClientOmnvar( "ui_ac130_40mm_ammo", self GetWeaponAmmoClip( weapon ) );
		break;
	case "ac130_25mm_mp":
		self SetClientOmnvar( "ui_ac130_25mm_ammo", self GetWeaponAmmoClip( weapon ) );
		break;
	}

	// force the reload to stop if we're currently using the weapon
	if ( self getCurrentWeapon() == weapon )
	{
		self takeWeapon( weapon );
		self _giveWeapon( weapon );
		self switchToWeapon( weapon );
	}
}

playSound25mm()	//self == player
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	self endon ( "ac130player_removed" );
	
	self endon( "reset_25mm" );
	
	weaponName = self GetCurrentWeapon();
	
	while ( true )
	{
		self waittill( "weapon_fired" );
		
		self StopLocalSound( "ac130iw6_25mm_fire_loop_cooldown" );
		
		self PlayLoopSound( "ac130iw6_25mm_fire_loop" );
		
		while ( self AttackButtonPressed() 
			  && self GetWeaponAmmoClip( weaponName ) )
		{
			wait(0.05);
		}
		
		self StopLoopSound();
		
		self PlayLocalSound( "ac130iw6_25mm_fire_loop_cooldown" );
	}
}


ac130_control_bot_aiming()
{
	self endon("ac130player_removed");
	
	last_enemy_loc = undefined;
	last_enemy_seen = undefined;
	target_loc = undefined;
	next_random_node_time = 0;
	last_inaccuracy_check = 0;
	inaccuracy_vector = undefined;
	bot_inaccuracy = (self BotGetDifficultySetting("minInaccuracy") + self BotGetDifficultySetting("maxInaccuracy")) / 2;
	time_following_outlines = 0;

	while( 1 )
	{
		should_aim_at_enemy = false;
		should_fire_at_enemy = false;
		
		if ( IsDefined(last_enemy_seen) && last_enemy_seen.health <= 0 && GetTime() - last_enemy_seen.deathtime < 2000 )
		{
			// Enemy just died, so force aim and fire at the last recorded position
			should_aim_at_enemy = true;
			should_fire_at_enemy = true;
		}
		else if ( IsAlive(self.enemy) && ( self BotCanSeeEntity(self.enemy) || (GetTime() - self LastKnownTime(self.enemy)) <= 300 ) )	
		{
			// Enemy is either on screen or visible due to outline, etc
			should_aim_at_enemy = true;
			last_enemy_seen = self.enemy;
			last_enemy_seen_loc = last_enemy_seen.origin;
			last_enemy_loc = self.enemy.origin;
			
			if ( self BotCanSeeEntity(self.enemy) )
			{
				// Enemy is onscreen (i.e. direct line of sight)
				time_following_outlines = 0;
				should_fire_at_enemy = true;
				last_time_actually_saw_enemy = GetTime();
			}
			else
			{
				time_following_outlines += 0.05;
				
				if ( time_following_outlines > 5.0 )
				{
					// If we keep seeing enemies as outlines but they're never actually visible, then eventually stop following them and look around randomly
					should_aim_at_enemy = false;
				}
			}
		}
		
		if ( should_aim_at_enemy )
		{
			if ( IsDefined( last_enemy_loc ) )
			{
				target_loc = last_enemy_loc;
			}
			if ( should_fire_at_enemy && ( self maps\mp\bots\_bots_ks_remote_vehicle::bot_body_is_dead() || DistanceSquared( target_loc, level.ac130.origin ) > level.physicsSphereRadius[ "ac130_105mm_mp" ] * level.physicsSphereRadius[ "ac130_105mm_mp" ] ) )
					self BotPressButton("attack");

			if ( GetTime() > last_inaccuracy_check + 500 )
			{
				random_x = RandomFloatRange(-1 * bot_inaccuracy/2, bot_inaccuracy/2);
				random_y = RandomFloatRange(-1 * bot_inaccuracy/2, bot_inaccuracy/2);
				random_z = RandomFloatRange(-1 * bot_inaccuracy/2, bot_inaccuracy/2);
				inaccuracy_vector = (150*random_x, 150*random_y, 150*random_z);
				last_inaccuracy_check = GetTime();
			}
			target_loc = target_loc + inaccuracy_vector;
			
		}
		else if ( GetTime() > next_random_node_time )
		{
			next_random_node_time = GetTime() + RandomIntRange(1000,2000);
			target_loc = maps\mp\bots\_bots_ks_remote_vehicle::get_random_outside_target();
		}
		
		self BotLookAtPoint( target_loc, 0.2, "script_forced");		
		wait(0.05);
	}
}


thermalVision()
{
	// DM 5/1/14 - changed the thermal to be always on and thermal only - MW2 style
	self endon ( "ac130player_removed" );
	self ThermalVisionOn();
	self VisionSetThermalForPlayer( level.ac130.enhanced_vision, 1 );
	self.lastVisionSetThermal = level.ac130.enhanced_vision;
	self VisionSetThermalForPlayer( level.ac130.thermal_vision, 0.62 );
	self.lastVisionSetThermal = level.ac130.thermal_vision;
	self SetClientDvar( "ui_ac130_thermal", 1 );
	// DM 5/1/14 - commenting out the thermal system
	/*
	self endon ( "ac130player_removed" );
	
	if ( getIntProperty( "ac130_thermal_enabled", 1 ) == 0 )
		return;
	
	inverted = false;
	
	self ThermalVisionOff();
	self VisionSetThermalForPlayer( level.ac130.enhanced_vision, 1 );
	self.lastVisionSetThermal = level.ac130.enhanced_vision;

	self notifyOnPlayerCommand( "switch thermal", "+usereload" );
	self notifyOnPlayerCommand( "switch thermal", "+activate" );

	for (;;)
	{
		self waittill ( "switch thermal" );
		
		if ( !inverted )
		{
			self ThermalVisionOn();
			self VisionSetThermalForPlayer( level.ac130.thermal_vision, 0.62 );
			self.lastVisionSetThermal = level.ac130.thermal_vision;
			self SetClientDvar( "ui_ac130_thermal", 1 );
		}
		else
		{
			self ThermalVisionOff();
			self VisionSetThermalForPlayer( level.ac130.enhanced_vision, 0.51 );
			self.lastVisionSetThermal = level.ac130.enhanced_vision;
			self SetClientDvar( "ui_ac130_thermal", 0 );
		}

		inverted = !inverted;
	}
	*/
}




clouds()
{
	self endon ( "ac130player_removed" );

	wait 6;
	clouds_create();
	for(;;)
	{
		wait( randomfloatrange( 40, 80 ) );
		clouds_create();
	}
}


clouds_create()
{
	if ( ( IsDefined( level.playerWeapon ) ) && ( IsSubStr( tolower( level.playerWeapon ), "25" ) ) )
		return;
	playfxontagforclients( level._effect[ "cloud" ], level.ac130, "tag_player", level.ac130player );
}


gun_fired_and_ready_105mm()
{
	self endon ( "ac130player_removed" );
	level notify( "gun_fired_and_ready_105mm" );
	level endon( "gun_fired_and_ready_105mm" );
	
	wait 0.5;
	
	if ( randomint( 2 ) == 0 )
		thread context_Sensative_Dialog_Play_Random_Group_Sound( "weapons", "105mm_fired" );
	
	wait 5.0;
	
	thread context_Sensative_Dialog_Play_Random_Group_Sound( "weapons", "105mm_ready" );
}


shotFired()
{
	self endon ( "ac130player_removed" );
	
	for (;;)
	{
		self waittill( "projectile_impact", weaponName, position, radius );
		
		if ( IsSubStr( tolower( weaponName ), "105" ) )
		{
			Earthquake( 0.4, 1.0, position, 3500 );
			self SetClientOmnvar( "ui_ac130_darken", 1 );
		}
		else if ( IsSubStr( tolower( weaponName ), "40" ) )
		{
			Earthquake( 0.2, 0.5, position, 2000 );
		}
		
		if ( getIntProperty( "ac130_ragdoll_deaths", 0 ) )
			thread shotFiredPhysicsSphere( position, weaponName );
			
		wait 0.05;
	}
}


shotFiredPhysicsSphere( center, weapon )
{
	wait 0.1;
	physicsExplosionSphere( center, level.physicsSphereRadius[ weapon ], level.physicsSphereRadius[ weapon ] / 2, level.physicsSphereForce[ weapon ] );
}

add_beacon_effect()
{
	self endon( "death" );
	
	flashDelay = 0.75;
	
	wait randomfloat(3.0);
	for (;;)
	{
		if ( level.ac130player )
			playfxontagforclients( level._effect[ "beacon" ], self, "j_spine4", level.ac130player );
		wait flashDelay;
	}
}


context_Sensative_Dialog()
{
	thread enemy_killed_thread();
	
	thread context_Sensative_Dialog_Guy_In_Sight();
	thread context_Sensative_Dialog_Guy_Crawling();
	thread context_Sensative_Dialog_Guy_Pain();
	thread context_Sensative_Dialog_Secondary_Explosion_Vehicle();
	thread context_Sensative_Dialog_Kill_Thread();
	thread context_Sensative_Dialog_Locations();
	thread context_Sensative_Dialog_Filler();
}


context_Sensative_Dialog_Guy_In_Sight()
{
	self endon ( "ac130player_removed" );

	for (;;)
	{
		if ( context_Sensative_Dialog_Guy_In_Sight_Check() )
			thread context_Sensative_Dialog_Play_Random_Group_Sound( "ai", "in_sight" );
		wait randomfloatrange( 1, 3 );
	}
}


context_Sensative_Dialog_Guy_In_Sight_Check()
{
	prof_begin( "AI_in_sight_check" );
	
	//enemies = getaiarray( "axis" );
	//replace with level of enemy team members?
	enemies = [];
	foreach( player in level.players )
	{
		if( !isReallyAlive( player ) )
			continue;

		if( player.team == level.ac130player.team )
			continue;
		
		if( player.team == "spectator" )
			continue;
	
		enemies[enemies.size] = player;
	}
	
	for( i = 0 ; i < enemies.size ; i++ )
	{
		if ( !IsDefined( enemies[ i ] ) )
			continue;
		
		if ( !isalive( enemies[ i ] ) )
			continue;
		
		if ( within_fov( level.ac130player getEye(), level.ac130player getPlayerAngles(), enemies[ i ].origin, level.cosine[ "5" ] ) )
		{
			prof_end( "AI_in_sight_check" );
			return true;
		}
		wait 0.05;
	}
	
	prof_end( "AI_in_sight_check" );
	return false;
}


context_Sensative_Dialog_Guy_Crawling()
{
	self endon ( "ac130player_removed" );

	for (;;)
	{
		level waittill ( "ai_crawling", guy );
		
/#
		if ( ( IsDefined( guy ) ) && ( IsDefined( guy.origin ) ) )
		{
			if ( getdvar( "ac130_debug_context_sensative_dialog", 0 ) == "1" )
				thread debug_line(level.ac130player.origin, guy.origin, 5.0, ( 0, 1, 0 ) );
		}
#/		
		thread context_Sensative_Dialog_Play_Random_Group_Sound( "ai", "wounded_crawl" );
	}
}


context_Sensative_Dialog_Guy_Pain()
{
	self endon ( "ac130player_removed" );

	for (;;)
	{
		level waittill ( "ai_pain", guy );		
/#		
		if ( ( IsDefined( guy ) ) && ( IsDefined( guy.origin ) ) )
		{
			if ( getdvar( "ac130_debug_context_sensative_dialog" ) == "1" )
				thread debug_line( level.ac130player.origin, guy.origin, 5.0, ( 1, 0, 0 ) );
		}
#/		
		thread context_Sensative_Dialog_Play_Random_Group_Sound( "ai", "wounded_pain" );
	}
}


context_Sensative_Dialog_Secondary_Explosion_Vehicle()
{
	self endon ( "ac130player_removed" );
	
	for (;;)
	{
		level waittill ( "player_destroyed_car", player, vehicle_origin );	
		
		wait 1;	
/#
		if ( IsDefined( vehicle_origin ) )
		{
			if ( getdvar( "ac130_debug_context_sensative_dialog" ) == "1" )
				thread debug_line( level.ac130player.origin, vehicle_origin, 5.0, ( 0, 0, 1 ) );
		}
#/
		
		thread context_Sensative_Dialog_Play_Random_Group_Sound( "explosion", "secondary" );
	}
}


enemy_killed_thread()
{
	self endon ( "ac130player_removed" );

	for ( ;; )
	{		
		level waittill ( "ai_killed", guy );
		
		// context kill dialog
		thread context_Sensative_Dialog_Kill( guy, level.ac130player );
	}
}


context_Sensative_Dialog_Kill( guy, attacker )
{
	if ( !IsDefined( attacker ) )
		return;
	
	if ( !isplayer( attacker ) )
		return;
	
	level.enemiesKilledInTimeWindow++;
	level notify ( "enemy_killed" );

/#	
	if ( ( IsDefined( guy ) ) && ( IsDefined( guy.origin ) ) )
	{
		if ( getdvar( "ac130_debug_context_sensative_dialog" ) == "1" )
			thread debug_line( level.ac130player.origin, guy.origin, 5.0, ( 1, 1, 0 ) );
	}
#/

}


context_Sensative_Dialog_Kill_Thread()
{
	self endon ( "ac130player_removed" );

	timeWindow = 1;
	for (;;)
	{
		level waittill ( "enemy_killed" );
		wait timeWindow;
		println ( "guys killed in time window: " );
		println ( level.enemiesKilledInTimeWindow );
		
		soundAlias1 = "kill";
		soundAlias2 = undefined;
		
		if ( level.enemiesKilledInTimeWindow >= 2 )
			soundAlias2 = "small_group";
		else
		{
			soundAlias2 = "single";
			if ( randomint( 3 ) != 1 )
			{
				level.enemiesKilledInTimeWindow = 0;
				continue;
			}
		}
		
		level.enemiesKilledInTimeWindow = 0;
		assert( IsDefined( soundAlias2 ) );
		
		thread context_Sensative_Dialog_Play_Random_Group_Sound( soundAlias1, soundAlias2, true );
	}
}


context_Sensative_Dialog_Locations()
{
	array_thread( getentarray( "context_dialog_car",		"targetname" ),	::context_Sensative_Dialog_Locations_Add_Notify_Event, "car" );
	array_thread( getentarray( "context_dialog_truck",		"targetname" ),	::context_Sensative_Dialog_Locations_Add_Notify_Event, "truck" );
	array_thread( getentarray( "context_dialog_building",	"targetname" ),	::context_Sensative_Dialog_Locations_Add_Notify_Event, "building" );
	array_thread( getentarray( "context_dialog_wall",		"targetname" ),	::context_Sensative_Dialog_Locations_Add_Notify_Event, "wall" );
	array_thread( getentarray( "context_dialog_field",		"targetname" ),	::context_Sensative_Dialog_Locations_Add_Notify_Event, "field" );
	array_thread( getentarray( "context_dialog_road",		"targetname" ),	::context_Sensative_Dialog_Locations_Add_Notify_Event, "road" );
	array_thread( getentarray( "context_dialog_church",		"targetname" ),	::context_Sensative_Dialog_Locations_Add_Notify_Event, "church" );
	array_thread( getentarray( "context_dialog_ditch",		"targetname" ),	::context_Sensative_Dialog_Locations_Add_Notify_Event, "ditch" );
	
	thread context_Sensative_Dialog_Locations_Thread();
}

context_Sensative_Dialog_Locations_Thread()
{
	self endon ( "ac130player_removed" );

	for (;;)
	{
		level waittill ( "context_location", locationType );
		
		if ( !IsDefined( locationType ) )
		{
			assertMsg( "LocationType " + locationType + " is not valid" );
			continue;
		}
		
		if ( !flag( "allow_context_sensative_dialog" ) )
			continue;
		
		thread context_Sensative_Dialog_Play_Random_Group_Sound( "location", locationType );
		
		wait ( 5 + randomfloat( 10 ) );
	}
}

context_Sensative_Dialog_Locations_Add_Notify_Event( locationType )
{
	self endon ( "ac130player_removed" );

	for (;;)
	{
		self waittill ( "trigger", triggerer );
		
		if ( !IsDefined( triggerer ) )
			continue;
		
		if ( ( !IsDefined( triggerer.team) ) || ( triggerer.team != "axis" ) )
			continue;
		
		level notify ( "context_location", locationType );
		
		wait 5;
	}
}

context_Sensative_Dialog_VehicleSpawn( vehicle )
{
	if ( vehicle.script_team != "axis" )
		return;
	
	thread context_Sensative_Dialog_VehicleDeath( vehicle );
	
	vehicle endon( "death" );
	
	while( !within_fov( level.ac130player getEye(), level.ac130player getPlayerAngles(), vehicle.origin, level.cosine[ "45" ] ) )
		wait 0.5;
	
	context_Sensative_Dialog_Play_Random_Group_Sound( "vehicle", "incoming" );
}

context_Sensative_Dialog_VehicleDeath( vehicle )
{
	vehicle waittill( "death" );
	thread context_Sensative_Dialog_Play_Random_Group_Sound( "vehicle", "death" );
}

context_Sensative_Dialog_Filler()
{
	self endon ( "ac130player_removed" );

	for(;;)
	{
		if( ( IsDefined( level.radio_in_use ) ) && ( level.radio_in_use == true ) )
			level waittill ( "radio_not_in_use" );
		
		// if 3 seconds has passed and nothing has been transmitted then play a sound
		currentTime = getTime();
		if ( ( currentTime - level.lastRadioTransmission ) >= 3000 )
		{
			level.lastRadioTransmission = currentTime;
			thread context_Sensative_Dialog_Play_Random_Group_Sound( "misc", "action" );
		}
		
		wait 0.25;
	}
}

context_Sensative_Dialog_Play_Random_Group_Sound( name1, name2, force_transmit_on_turn )
{
	level endon ( "ac130player_removed" );

	assert( IsDefined( level.scr_sound[ name1 ] ) );
	assert( IsDefined( level.scr_sound[ name1 ][ name2 ] ) );
	
	if ( !IsDefined( force_transmit_on_turn ) )
		force_transmit_on_turn = false;
	
	if ( !flag( "allow_context_sensative_dialog" ) )
	{
		if ( force_transmit_on_turn )
			flag_wait( "allow_context_sensative_dialog" );
		else
			return;
	}
	
	validGroupNum = undefined;
	
	randGroup = randomint( level.scr_sound[ name1 ][ name2 ].size );
	
	// if randGroup has already played
	if ( level.scr_sound[ name1 ][ name2 ][ randGroup ].played == true )
	{
		//loop through all groups and use the next one that hasn't played yet
		
		for( i = 0 ; i < level.scr_sound[ name1 ][ name2 ].size ; i++ )
		{
			randGroup++;
			if ( randGroup >= level.scr_sound[ name1 ][ name2 ].size )
				randGroup = 0;
			if ( level.scr_sound[ name1 ][ name2 ][ randGroup ].played == true )
				continue;
			validGroupNum = randGroup;
			break;
		}
		
		// all groups have been played, reset all groups to false and pick a new random one
		if ( !IsDefined( validGroupNum ) )
		{
			for( i = 0 ; i < level.scr_sound[ name1 ][ name2 ].size ; i++ )
				level.scr_sound[ name1 ][ name2 ][ i ].played = false;
			validGroupNum = randomint( level.scr_sound[ name1 ][ name2 ].size );
		}
	}
	else
		validGroupNum = randGroup;
	
	assert( IsDefined( validGroupNum ) );
	assert( validGroupNum >= 0 );
	
	if ( context_Sensative_Dialog_Timedout( name1, name2, validGroupNum ) )
		return;
	
	level.scr_sound[ name1 ][ name2 ][ validGroupNum ].played = true;
	randSound = randomint( level.scr_sound[ name1 ][ name2 ][ validGroupNum ].size );
	playSoundOverRadio( level.scr_sound[ name1 ][ name2 ][ validGroupNum ].sounds[ randSound ], force_transmit_on_turn );
}

context_Sensative_Dialog_Timedout( name1, name2, groupNum )
{
	// dont play this sound if it has a timeout specified and the timeout has not expired
	
	if( !IsDefined( level.context_sensative_dialog_timeouts ) )
		return false;
	
	if( !IsDefined( level.context_sensative_dialog_timeouts[ name1 ] ) )
		return false;
	
	if( !IsDefined( level.context_sensative_dialog_timeouts[ name1 ][name2 ] ) )
		return false;
	
	if( IsDefined( level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups ) && IsDefined( level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ] ) )
	{
		assert( IsDefined( level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ].v[ "timeoutDuration" ] ) );
		assert( IsDefined( level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ].v[ "lastPlayed" ] ) );
		
		currentTime = getTime();
		if( ( currentTime - level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ].v[ "lastPlayed" ] ) < level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ].v[ "timeoutDuration" ] )
			return true;
		
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ].groups[ string( groupNum ) ].v[ "lastPlayed" ] = currentTime;
	}
	else if ( IsDefined( level.context_sensative_dialog_timeouts[ name1 ][ name2 ].v ) )
	{
		assert( IsDefined( level.context_sensative_dialog_timeouts[ name1 ][ name2 ].v[ "timeoutDuration" ] ) );
		assert( IsDefined( level.context_sensative_dialog_timeouts[ name1 ][ name2 ].v[ "lastPlayed" ] ) );
		
		currentTime = getTime();
		if( ( currentTime - level.context_sensative_dialog_timeouts[ name1 ][ name2 ].v[ "lastPlayed" ] ) < level.context_sensative_dialog_timeouts[ name1 ][ name2 ].v[ "timeoutDuration" ] )
			return true;
		
		level.context_sensative_dialog_timeouts[ name1 ][ name2 ].v[ "lastPlayed" ] = currentTime;
	}
	
	return false;
}

playSoundOverRadio( soundAlias, force_transmit_on_turn, timeout )
{
	if ( !IsDefined( level.radio_in_use ) )
		level.radio_in_use = false;
	if ( !IsDefined( force_transmit_on_turn ) )
		force_transmit_on_turn = false;
	if ( !IsDefined( timeout ) )
		timeout = 0;
	timeout = timeout * 1000;
	soundQueueTime = gettime();
	
	soundPlayed = false;
	soundPlayed = playAliasOverRadio( soundAlias );
	if ( soundPlayed )
		return;
	
	// Dont make the sound wait to be played if force transmit wasn't set to true
	if ( !force_transmit_on_turn )
		return;
	
	level.radioForcedTransmissionQueue[ level.radioForcedTransmissionQueue.size ] = soundAlias;
	while( !soundPlayed )
	{
		if ( level.radio_in_use )
			level waittill ( "radio_not_in_use" );
		
		if ( ( timeout > 0 ) && ( getTime() - soundQueueTime > timeout ) )
			break;
			
		if ( !IsDefined( level.ac130player ) )
			break;
		
		soundPlayed = playAliasOverRadio( level.radioForcedTransmissionQueue[ 0 ] );
		if ( !level.radio_in_use && IsDefined( level.ac130player ) && !soundPlayed )
			assertMsg( "The radio wasn't in use but the sound still did not play. This should never happen." );
	}
	level.radioForcedTransmissionQueue = array_remove_index( level.radioForcedTransmissionQueue, 0 );
}


playAliasOverRadio( soundAlias )
{
	if ( level.radio_in_use )
		return false;
	
	if ( !IsDefined( level.ac130player ) )
		return false;
	
	level.radio_in_use = true;
	if ( self.team == "allies" || self.team == "axis" )
	{
		soundAlias = maps\mp\gametypes\_teams::getTeamVoicePrefix( self.team ) + soundAlias;
		level.ac130player playLocalSound( soundAlias );
	}
	wait ( 4.0 );
	level.radio_in_use = false;
	level.lastRadioTransmission = getTime();
	level notify ( "radio_not_in_use" );
	return true;
}


debug_circle(center, radius, duration, color, startDelay, fillCenter)
{
	circle_sides = 16;
	
	angleFrac = 360/circle_sides;
	circlepoints = [];
	for(i=0;i<circle_sides;i++)
	{
		angle = (angleFrac * i);
		xAdd = cos(angle) * radius;
		yAdd = sin(angle) * radius;
		x = center[0] + xAdd;
		y = center[1] + yAdd;
		z = center[2];
		circlepoints[circlepoints.size] = (x,y,z);
	}
	
	if (IsDefined(startDelay))
		wait startDelay;
	
	thread debug_circle_drawlines(circlepoints, duration, color, fillCenter, center);
}


debug_circle_drawlines(circlepoints, duration, color, fillCenter, center)
{
	if (!IsDefined(fillCenter))
		fillCenter = false;
	if (!IsDefined(center))
		fillCenter = false;
	
	for( i = 0 ; i < circlepoints.size ; i++ )
	{
		start = circlepoints[i];
		if (i + 1 >= circlepoints.size)
			end = circlepoints[0];
		else
			end = circlepoints[i + 1];
		
		thread debug_line( start, end, duration, color);
		
		if (fillCenter)
			thread debug_line( center, start, duration, color);
	}
}


debug_line(start, end, duration, color)
{
	if (!IsDefined(color))
		color = (1,1,1);
	
	for ( i = 0; i < (duration * 20) ; i++ )
	{
		line(start, end, color);
		wait 0.05;
	}
}

// Start Flare logic
handleIncomingMissiles()
{
	level endon ( "game_ended" );
	
	level.ac130.planeModel thread flares_monitor( 1 );
	/*
	for ( ;; )
	{
		level waittill ( "stinger_fired", player, missile, lockTarget );
		
		if ( !IsDefined( lockTarget ) || (lockTarget != level.ac130.planeModel) )
			continue;
		
		missile thread stingerProximityDetonate( player, player.team );
	}
	*/
}

flares_monitor( flareCount ) // self == vehicle
{
	self.flaresReserveCount = flareCount;
	self.flaresLive = [];
	
	self thread ks_laserGuidedMissile_handleIncoming();
	self thread ks_airSuperiority_handleIncoming();
}


playFlareFx( numFlares )
{	
	for ( i = 0; i < numFlares; i++ )
	{
		self thread angel_flare();

		wait ( randomFloatRange( 0.1, 0.25 ) );
	}
}

deployFlares( fxOnly )
{
	self playSound( "ac130iw6_flare_burst" );
	
	if ( !IsDefined( fxOnly ) )
	{
		flareObject = spawn( "script_origin", level.ac130.planemodel.origin );
		flareObject.angles = level.ac130.planemodel.angles;
	
		flareObject moveGravity( (0, 0, 0), 5.0 );
		
		self thread playFlareFx( 10 );
		
		self.flaresLive[ self.flaresLive.size ] = flareObject;
		
		flareObject thread deleteAfterTime( 5.0 );
	
		return flareObject;
	}
	else
	{
		self thread playFlareFx( 5 );
	}
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
	
	flare = vehicle deployFlares();
	
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
// handle MAAWS here
ks_laserGuidedMissile_handleIncoming() //self == vehicle
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "leaving" );
	self endon( "helicopter_done" );
	
	while ( flares_areAvailable( self ) )
	{
		level waittill ( "laserGuidedMissiles_incoming", player, missiles, target );
		
		if ( !IsDefined( target ) || target != self )
			continue;
		
		level.ac130player PlayLocalSound( "missile_incoming" );
		level.ac130player thread ks_watch_death_stop_sound( self, "missile_incoming" );
		
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
			level.ac130player StopLocalSound( "missile_incoming" );
			break;
		}
		
		waitframe();
	}
}


// handle air superiority here

ks_airSuperiority_handleIncoming() // self == vehicle
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
		
		level.ac130player PlayLocalSound( "missile_incoming" );
		level.ac130player thread ks_watch_death_stop_sound( self, "missile_incoming" );
		
		foreach( missile in missiles )
		{
			if( IsValidMissile( missile ) )
			{
				self thread ks_airSuperiority_monitorProximity( missile );
			}
		}
	}
}

ks_airSuperiority_monitorProximity( missile ) // self == vehicle
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
			// DM - 5/19/14 - This is new logic to handle Air Sup missiles pairing with auto-flares
			// If flaresLive count is 0, check if reserved flares are available, otherwise Air Sup will kill the ac130 without hitting the flare
			if ( !IsDefined( flare ) && self.flaresReserveCount > 0 )
			{
				flare = flares_getFlareReserve( self );
			}
			if( IsDefined( flare ) )
			{
				missile Missile_SetTargetEnt( flare );
				missile notify( "missile_pairedWithFlare" );
				level.ac130player StopLocalSound( "missile_incoming" );
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
// End Flare logic 


deleteAfterTime( delay )
{
	wait ( delay );
	
	self delete();
}

crashPlane( crashTime )
{
	level.ac130.planeModel notify ( "crashing" );
	level.ac130.planeModel.crashed = true;

	// 2014-05-06 wallace: commenting out this effect because we don't expect to shoot down the ac130 in this level, so no need to load it
	playFxOnTag( level._effect[ "ac130_explode" ], level.ac130.planeModel, "tag_deathfx" );	
	wait .25;

	level.ac130.planeModel hide();
}

angelFlarePrecache()
{
	level._effect[ "angel_flare_geotrail" ]			= loadfx( "fx/smoke/angel_flare_geotrail" );
	level._effect[ "angel_flare_swirl" ]			= loadfx( "fx/smoke/angel_flare_swirl_runner" );
}

angel_flare()
{
	rig = spawn( "script_model", self.origin );
	rig setModel( "angel_flare_rig" );

	rig.origin = self getTagOrigin( "tag_flash_flares" );
	rig.angles = self getTagAngles( "tag_flash_flares" );

	rig.angles = (rig.angles[0],rig.angles[1] + 180,rig.angles[2] + -90);

	fx_id = level._effect[ "angel_flare_geotrail" ];

	rig ScriptModelPlayAnim( "ac130_angel_flares0" + (randomInt( 3 )+1) );

	wait 0.1;
	PlayFXOnTag( fx_id, rig, "flare_left_top" );
	PlayFXOnTag( fx_id, rig, "flare_right_top" );
	wait 0.05;
	PlayFXOnTag( fx_id, rig, "flare_left_bot" );
	PlayFXOnTag( fx_id, rig, "flare_right_bot" );

	//rig waittillmatch( "flare_anim", "end" );
	wait ( 3.0 );

	StopFXOnTag( fx_id, rig, "flare_left_top" );
	StopFXOnTag( fx_id, rig, "flare_right_top" );
	StopFXOnTag( fx_id, rig, "flare_left_bot" );
	StopFXOnTag( fx_id, rig, "flare_right_bot" );
	
	rig delete();
}

/*
stingerProximityDetonate( player, missileTeam )
{
	self endon ( "death" );
	
	if ( IsDefined( level.ac130player ) )
		level.ac130player playLocalSound( "missile_incoming" );

	level.ac130.incomingMissile = true;

	missileTarget = level.ac130.planeModel;

	self Missile_SetTargetEnt( missileTarget );
	
	didSeatbelts = false;
	center = missileTarget GetPointInBounds( 0, 0, 0 );
	minDist = distance( self.origin, center );
	
	lastVecToTarget = vectorNormalize( center - self.origin );

	for ( ;; )
	{		
		if ( !IsDefined( level.ac130player ) || ( IsDefined( level.ac130.planeModel.crashed ) && level.ac130.planeModel.crashed == true ) )
		{
			self Missile_SetTargetPos( level.ac130.origin + (0,0,100000) );
			return;
		}
		
		center = missileTarget GetPointInBounds( 0, 0, 0 );
		
		curDist = distance( self.origin, center );
		
		if ( curDist < 3000 && missileTarget == level.ac130.planeModel && level.ac130.numFlares > 0 )
		{
			level.ac130.numFlares--;			

			newTarget = missileTarget deployFlares();
			
			self Missile_SetTargetEnt( newTarget );
			missileTarget = newTarget;
			
			if ( IsDefined( level.ac130player ) )
				level.ac130player stopLocalSound( "missile_incoming" ); 
		
			return;
		}		
		
		if ( curDist < minDist )
		{
			speedPerFrame = (minDist - curDist) * 20;
			eta = (curDist / speedPerFrame);

			if ( eta < 1.5 && !didSeatbelts && missileTarget == level.ac130.planeModel )
			{	
				if ( IsDefined( level.ac130player ) )
					level.ac130player playLocalSound( "fasten_seatbelts" );
					
				didSeatbelts = true;
			}
			
			minDist = curDist;
		}
		
		currVecToTarget = vectorNormalize( center - self.origin );
		if ( vectorDot( currVecToTarget, lastVecToTarget ) < 0 )
		{			
			if ( IsDefined( level.ac130player ) )
			{
				level.ac130player stopLocalSound( "missile_incoming" ); 
				
				if ( level.ac130player.team != missileTeam )
					RadiusDamage( self.origin, 1000, 1000, 1000, player, "MOD_EXPLOSIVE", "stinger_mp" );
			}
			self hide();
			wait ( 0.05 );
			self delete();
		}
		else
			lastVecToTarget = currVecToTarget;
		
		wait ( 0.05 );
	}	
}
*/

/*
handleIncomingSAM()
{
	level endon ( "game_ended" );

	for ( ;; )
	{
		self waittill( "targeted_by_incoming_missile", missiles );
		
		level thread samProximityDetonate( missiles );
		
		
		level waittill ( "sam_fired", player, missileGroup, lockTarget );

		if ( !IsDefined( lockTarget ) || (lockTarget != level.ac130.planeModel) )
			continue;

		level thread samProximityDetonate( player, player.team, missileGroup );
		
	}
}

samProximityDetonate( missileGroup )
{
	if ( IsDefined( level.ac130player ) )
		level.ac130player playLocalSound( "missile_incoming" );

	level.ac130.incomingMissile = true;

	missileTarget = level.ac130.planeModel;

	didSeatbelts = false;
	minDist = [];
	center = missileTarget GetPointInBounds( 0, 0, 0 );
	for( i = 0; i < missileGroup.size; i++ )
	{
		if( IsDefined( missileGroup[ i ] ) )
		{
			minDist[ i ] = distance( missileGroup[ i ].origin, center );
			missileGroup[ i ].lastVecToTarget = vectorNormalize( center - missileGroup[ i ].origin );
		}
		else
			minDist[ i ] = undefined;
	}

	for ( ;; )
	{
		if ( !IsDefined( level.ac130player ) || ( IsDefined( level.ac130.planeModel.crashed ) && level.ac130.planeModel.crashed == true ) )
		{
			for( i = 0; i < missileGroup.size; i++ )					
			{
				if( IsDefined( missileGroup[ i ] ) )
				{
					missileGroup[ i ] Missile_SetTargetPos( level.ac130.origin + ( 0, 0, 100000 ) );
				}
			}
			return;
		}

		center = missileTarget GetPointInBounds( 0, 0, 0 );

		curDist = [];
		for( i = 0; i < missileGroup.size; i++ )
		{
			if( IsDefined( missileGroup[ i ] ) )
				curDist[ i ] = distance( missileGroup[ i ].origin, center );
		}

		if ( !IsDefined( level.ac130player ) )
		{
			return;
		}

		for( i = 0; i < curDist.size; i++ )
		{
			if( IsDefined( curDist[ i ] ) )
			{
				// if one of the missiles in the group get close, set off flares and redirect them all
				if ( curDist[ i ] < 3000 && missileTarget == level.ac130.planeModel && level.ac130.numFlares > 0 )
				{
					level.ac130.numFlares--;			

					newTarget = missileTarget deployFlares();

					for( j = 0; j < missileGroup.size; j++ )					
					{
						if( IsDefined( missileGroup[ j ] ) )
						{
							missileGroup[ j ] Missile_SetTargetEnt( newTarget );
						}
					}

					if ( IsDefined( level.ac130player ) )
						level.ac130player stopLocalSound( "missile_incoming" ); 

					return;
				}		

				if ( curDist[ i ] < minDist[ i ] )
				{
					speedPerFrame = ( minDist[ i ] - curDist[ i ] ) * 20;
					eta = ( curDist[ i ] / speedPerFrame );

					if ( eta < 1.5 && !didSeatbelts && missileTarget == level.ac130.planeModel )
					{	
						if ( IsDefined( level.ac130player ) )
							level.ac130player playLocalSound( "fasten_seatbelts" );

						didSeatbelts = true;
					}

					minDist[ i ] = curDist[ i ];
				}

				currVecToTarget = vectorNormalize( center - missileGroup[ i ].origin );
				if ( vectorDot( currVecToTarget, missileGroup[ i ].lastVecToTarget ) < 0 )
				{
					if ( IsDefined( level.ac130player ) )
					{
						level.ac130player stopLocalSound( "missile_incoming" ); 

						if ( level.teambased )
						{
							if( level.ac130player.team != missileTeam )
								RadiusDamage( missileGroup[ i ].origin, 1000, 1000, 1000, player, "MOD_EXPLOSIVE", "sam_projectile_mp" );
						}
						else
						{
							RadiusDamage( missileGroup[ i ].origin, 1000, 1000, 1000, player, "MOD_EXPLOSIVE", "sam_projectile_mp" );
						}
					}

					missileGroup[ i ] hide();

					wait ( 0.05 );
					missileGroup[ i ] delete();
				}
			}
		}

		wait ( 0.05 );
	}	
}
*/


/*
#using_animtree( "script_model" );
angel_flare_rig_anims()
{
	level.scr_animtree[ "angel_flare_rig" ] 						= #animtree;
	level.scr_model[ "angel_flare_rig" ] 							= "angel_flare_rig";

	level.scr_anim[ "angel_flare_rig" ][ "ac130_angel_flares" ][0]	= %ac130_angel_flares01;
	level.scr_anim[ "angel_flare_rig" ][ "ac130_angel_flares" ][1]	= %ac130_angel_flares02;
	level.scr_anim[ "angel_flare_rig" ][ "ac130_angel_flares" ][2]	= %ac130_angel_flares03;

}

assign_model()
{
	AssertEx( IsDefined( level.scr_model[ self.animname ] ), "There is no level.scr_model for animname " + self.animname );

	if ( IsArray( level.scr_model[ self.animname ] ) )
	{
		randIndex = RandomInt( level.scr_model[ self.animname ].size );
		self SetModel( level.scr_model[ self.animname ][ randIndex ] );
	}
	else
		self SetModel( level.scr_model[ self.animname ] );
}
assign_animtree( animname )
{
	if ( IsDefined( animname ) )
		self.animname = animname;

	AssertEx( IsDefined( level.scr_animtree[ self.animname ] ), "There is no level.scr_animtree for animname " + self.animname );
	self UseAnimTree( level.scr_animtree[ self.animname ] );
}

spawn_anim_model( animname, origin )
{
	if ( !IsDefined( origin ) )
		origin = ( 0, 0, 0 );
	model = Spawn( "script_model", origin );
	model.animname = animname;
	model assign_animtree();
	model assign_model();
	return model;
}


angel_flare_burst( flare_count )
{
	// Angel Flare Swirl
	PlayFXOnTag( getfx( "angel_flare_swirl" ), self, "tag_flash_flares" );

	// Angel Flare Trails
	for( i=0; i<flare_count; i++ )
	{
		self thread angel_flare();
		wait randomfloatrange( 0.1, 0.25 );
	}
}
*/
