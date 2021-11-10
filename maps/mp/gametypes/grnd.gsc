#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

/*
	Drop Zone
	Objective: 	Score points for your team over time by holding the drop zone.
				Periodic carepackage awarded to player who's been in drop zone the longest.
	Map ends:	When one team reaches the score limit, or time limit is reached
	Respawning:	No wait / Near teammates / Near drop zone

	Level requirementss
	------------------
		Start Spawnpoints:
			classname		mp_sd_spawn_defender, mp_sd_spawn_attacker
			
		Spawnpoints:
			classname		mp_tdm_spawn	
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of drop zone, teammates, and enemies
			at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.
*/

GRND_ZONE_TOUCH_RADIUS = 300;
GRND_ZONE_DROP_RADIUS = 50;

main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();

	if ( isUsingMatchRulesData() )
	{
		level.initializeMatchRules = ::initializeMatchRules;
		[[level.initializeMatchRules]]();
		level thread reInitializeMatchRulesOnMigration();	
	}
	else
	{
		registerRoundSwitchDvar( level.gameType, 0, 0, 9 );
		registerTimeLimitDvar( level.gameType, 10 );
		registerScoreLimitDvar( level.gameType, 7500 );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 );
		
		level.matchRules_dropTime = 15;
		level.matchRules_zoneSwitchTime = 60;		
		level.matchRules_damageMultiplier = 0;
		level.matchRules_vampirism = 0;	
		setDvar( "scr_game_hardpoints", 0 );
	}

	level.teamBased = true;
	level.onStartGameType = ::onStartGameType;
	level.getSpawnPoint = ::getSpawnPoint;
	level.onSpawnPlayer = ::onSpawnPlayer;
	
	if ( level.matchRules_damageMultiplier || level.matchRules_vampirism )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;
	
	level.grnd_fx["smoke"] = loadFx( "smoke/airdrop_flare_mp_effect_now" );
	level.grnd_fx["flare"] = loadFx( "smoke/signal_smoke_airdrop" );
	level.grnd_targetFXID = loadfx( "vfx/gameplay/mp/core/vfx_marker_base_cyan" );
	
	level.dangerMaxRadius["drop_zone"] 	= 1200;
	level.dangerMinRadius["drop_zone"] 	= 1190;
	level.dangerForwardPush["drop_zone"]= 0;
	level.dangerOvalScale["drop_zone"] 	= 1;
}


initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	//	set everything else (private match options, default .cfg file values, and what normally is registered in the 'else' below)
	level.matchRules_dropTime = GetMatchRulesData( "grndData", "dropTime" );
	level.matchRules_zoneSwitchTime = 60 * GetMatchRulesData( "grndData", "zoneSwitchTime" );
	if( level.matchRules_zoneSwitchTime < 60 )
		level.matchRules_zoneSwitchTime = 60;
	
	SetDynamicDvar( "scr_grnd_roundswitch", 0 );
	registerRoundSwitchDvar( "grnd", 0, 0, 9 );
	SetDynamicDvar( "scr_grnd_roundlimit", 1 );
	registerRoundLimitDvar( "grnd", 1 );		
	SetDynamicDvar( "scr_grnd_winlimit", 1 );
	registerWinLimitDvar( "grnd", 1 );			
	SetDynamicDvar( "scr_grnd_halftime", 0 );
	registerHalfTimeDvar( "grnd", 0 );
		
	SetDynamicDvar( "scr_grnd_promode", 0 );
}


onStartGameType()
{
	setClientNameMode("auto_change");

	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;

	setObjectiveText( "allies", &"OBJECTIVES_GRND" );
	setObjectiveText( "axis", &"OBJECTIVES_GRND" );
	
	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_GRND" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_GRND" );
	}
	else
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_GRND_SCORE" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_GRND_SCORE" );
	}
	setObjectiveHintText( "allies", &"OBJECTIVES_DOM_HINT" );
	setObjectiveHintText( "axis", &"OBJECTIVES_DOM_HINT" );
			
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_tdm_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
	
	//	get the central loction "b" flag
	domFlags = getEntArray( "flag_primary", "targetname" );

	sortedDomFlags = SortByDistance( domFlags, level.mapCenter );
	centerLocObj = sortedDomFlags[0];
	//end new stuff

	//level.grnd_centerLoc = centerLocObj.origin;
	
	level.grnd_centerLoc = level.mapCenter;
	
	maps\mp\gametypes\_rank::registerScoreInfo( "kill", 50 );
	maps\mp\gametypes\_rank::registerScoreInfo( "zone_kill", 100 );	
	maps\mp\gametypes\_rank::registerScoreInfo( "zone_tick",  20 );
	
	allowed[0] = level.gameType;
	allowed[1] = "tdm";
	
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	//	timer
	level.grnd_HUD["timerDisplay"] = createServerTimer( "objective", 1.4 );
	level.grnd_HUD["timerDisplay"].label = &"MP_NEXT_DROP_ZONE_IN";	
	
	level.grnd_HUD["timerDisplay"] setPoint( "BOTTOMCENTER", "BOTTOMCENTER", 0, -28 );
	
	level.grnd_HUD["timerDisplay"].alpha = 0;
	level.grnd_HUD["timerDisplay"].archived = false;
	level.grnd_HUD["timerDisplay"].hideWhenInMenu = true;
	level.grnd_HUD["timerDisplay"].hideWhenInDemo = true;	
	thread hideHudElementOnGameEnd( level.grnd_HUD["timerDisplay"] );

	createZones();
	initZones();
	initFirstZone();
}


initFirstZone()
{
	level.zonesCycling = false;	
	level.firstZoneActive = false;
	
	//	find the closest zone to center	
	shortestDistance = 999999;
	shortestDistanceIndex = 0;
	
	//Adding specialcase for dlc map mp_shipment_ns
	if( toLower( getDvar("mapname") ) == "mp_shipment_ns" )
	{
		initialPos = (1.60, 63, 192);
	}
	else
	{
		for ( i=0; i < level.grnd_zones.size; i++ )
		{
			dropZone = level.grnd_zones[i];
			distToCenter = distance2d( level.grnd_centerLoc, dropZone.origin );
			if ( distToCenter < shortestDistance )
			{
				shortestDistance = distToCenter;
				shortestDistanceIndex = i;
			}
		}
		//grnd_initialIndex is currently unused.	
		level.grnd_initialIndex = shortestDistanceIndex;
		initialPos = level.grnd_zones[shortestDistanceIndex].origin;
	}
	
	level.grnd_initialPos = initialPos;
	
	//	create marker
	level.grnd_zone = spawn( "script_model", initialPos );
	level.grnd_zone.origin = initialPos;
	level.grnd_zone.angles = ( 90, 0, 0 );
	level.grnd_zone setModel( "weapon_us_smoke_grenade_burnt2" );
	
	// create effect entity
	ringVfx = Spawn( "script_model", level.grnd_zone.origin );
	ringVfx SetModel( "tag_origin" );	// tag_origin doesn't seem to work as a model with the effect
	ringVfx.angles = VectorToAngles( (0, 0, 1) );
	ringVfx LinkTo( level.grnd_zone );
	level.grnd_zone.ringVfx = ringVfx;
	
	//	add drop zone target to danger zones so spawnlogic tries not to spawn too close to it
	level.grnd_dangerCenter = spawnstruct();
	level.grnd_dangerCenter.origin = initialPos;
	level.grnd_dangerCenter.forward = anglesToForward( (0,0,0) );
	level.grnd_dangerCenter.streakName = "drop_zone";
	
	//	spawning
	level.favorCloseSpawnEnt = level.grnd_zone;
}


initZones()
{
	level.grnd_zones = [];
	
	//playing strikezone
	if( GetDvar( "mapname" ) == "mp_strikezone" )
	{
		//zone one
		if ( isDefined( level.teleport_zone_current ) && level.teleport_zone_current == "start" )
		{
			for ( i=0; i<level.grnd_dropZones1.size; i++ )
			{
				dropZone = level.grnd_dropZones1[i].origin;
				level.grnd_zones[i] = spawn( "script_origin", dropZone );
				level.grnd_zones[i].origin = dropZone;
				wait( 0.05 );
			}
		}
		else//zone two
		{
			for ( i=0; i<level.grnd_dropZones2.size; i++ )
			{
				dropZone = level.grnd_dropZones2[i].origin;
				level.grnd_zones[i] = spawn( "script_origin", dropZone );
				level.grnd_zones[i].origin = dropZone;
				wait( 0.05 );
			}
		}
	}
	else
	{
		for ( i=0; i<level.grnd_dropZones.size; i++ )
		{
			dropZone = level.grnd_dropZones[i].origin;
			level.grnd_zones[i] = spawn( "script_origin", dropZone );
			level.grnd_zones[i].origin = dropZone;
			wait( 0.05 );
		}
	}
}

getSpawnPoint()
{	
	spawnteam = self.pers["team"];
	if ( game["switchedsides"] )
		spawnteam = getOtherTeam( spawnteam );

	if ( maps\mp\gametypes\_spawnlogic::shouldUseTeamStartSpawn() )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_tdm_spawn_" + spawnteam + "_start" );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_startSpawn( spawnPoints );
	}
	else
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnteam );
		
		//this could be optimized to store on the level when the point changes.
		closeSortedSpawnArray = SortByDistance( spawnPoints, level.favorCloseSpawnEnt.origin );
		closestPoints = [];		
		
		//loop will continue to get points until they are 768 or further away as long as 6 have already been retreived.
		for ( i = 0; i < closeSortedSpawnArray.size; i++ )
		{			
			closestPoints[i] = closeSortedSpawnArray[i];
			
			//level thread drawLine( level.favorCloseSpawnEnt.origin, closestPoints[i].origin+(0,0,60), 60, (0,0,1) );
			
			if( distance_2d_squared( closestPoints[i].origin, level.favorCloseSpawnEnt.origin ) > (768*768) && i > 5 )
				break;
		}
		
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_DZ( spawnPoints, closestPoints );
	}

	return spawnPoint;
}


onSpawnPlayer()
{				
	//	in/out zone indicator
	if ( !isDefined( self.inGrindZone ) )
	{
		if ( IsAgent(self) )
			return;
	
		level thread setPlayerMessages( self );
		
		//	let the first player in activate this
		if ( !level.zonesCycling )
		{
			level.zonesCycling = true;
			level thread cycleZones();
			level thread locationStatus();	
			level thread locationScoring();	
		}
		
		self thread waitReplaySmokeFxForNewPlayer();
	}	
		
	level notify ( "spawned_player" );	
}


waitReplaySmokeFxForNewPlayer()
{
	level endon( "game_ended" );
	self  endon( "disconnect" );
	
	gameFlagWait( "prematch_done" );
	
	//	let cycleZones() do it's initial work so we only catch people who are joining late
	wait( 0.5 );
	
	if ( !isDefined( self.grnd_fx_playing ) )
	{
		PlayFxOnTagForClients( level.grnd_fx["smoke"], level.grnd_zone, "tag_fx", self );		
		self.grnd_fx_playing = true;
	}
}


createHudInfo( elemName, font, fontSize, xPos, yPos, text, color )
{
	hudElem = createFontString( font, fontSize );
	hudElem setText( text );
	
	if ( level.splitscreen )
		hudElem setPoint( "TOPLEFT", "TOPLEFT", (xPos-35), (yPos-5) );
	else
		hudElem setPoint( "TOPLEFT", "TOPLEFT", xPos, yPos );
	
	hudElem.alpha = 1;
	hudElem.color = color;
	hudElem.glowColor = color;
	hudElem.archived = false;
	hudElem.hideWhenInMenu = true;	
	thread hideHudElementOnGameEnd( hudElem );	
	
	self.grnd_HUD[elemName] = hudElem;
}


setPlayerMessages( player )
{
	level endon( "game_ended" );	
	
	gameFlagWait( "prematch_done" );	
	
	if( !IsDefined( player ) )
		return;
	
	//	points
	player.inGrindZonePoints = 0;	
	
	/*	player team players in zone	
	elemName = player.team+"Score";
	player createHudInfo( elemName, "small", 1.6, 115, 22, 0, (0.6,1.0,0.6) );	
	elemName = player.team+"Text";
	player createHudInfo( elemName, "small", 1.6, 225, 22, maps\mp\gametypes\_teams::getTeamShortName( player.team ), (0.6,1.0,0.6) );
	
	//	enemy team players in zone
	elemName = level.otherTeam[player.team]+"Score";
	player createHudInfo( elemName, "small", 1.6, 115, 39, 0, (1.0,0.6,0.6) );	
	elemName = level.otherTeam[player.team]+"Text";
	player createHudInfo( elemName, "small", 1.6, 225, 39, maps\mp\gametypes\_teams::getTeamShortName( level.otherTeam[player.team] ), (1.0,0.6,0.6) );	
	*/
	
	//	hud icon
	player.grndHeadIcon = level.grnd_zone maps\mp\_entityheadIcons::setHeadIcon( player, "waypoint_captureneutral_b", (0,0,0), 14, 14, undefined, undefined, undefined, true, undefined, false );

	//	minimap waypoint
	player.grndObjId = maps\mp\gametypes\_gameobjects::getNextObjID();	
	objective_add( player.grndObjId, "invisible", (0,0,0) );
	objective_player( player.grndObjId, player getEntityNumber() );	
	Objective_OnEntity( player.grndObjId, level.grnd_zone );
	objective_icon( player.grndObjId, "waypoint_captureneutral_b" );
	objective_state( player.grndObjId, "active" );
	
	if ( player isInGrindZone() )	
	{
		player.inGrindZone = true;
		player.grndHeadIcon.alpha = 0;
	}
	else
	{
		player.inGrindZone = false;	
		player.grndHeadIcon.alpha = 0.85;
	}
	
	player.grnd_wasSpectator = false;
	if ( player.team == "spectator" )
	{
		player.inGrindZone = false;
		player.inGrindZonePoints = 0;
		player.grndHeadIcon.alpha = 0;
		player.grnd_HUD["axisScore"].alpha = 0;	
		player.grnd_HUD["axisText"].alpha = 0;
		player.grnd_HUD["alliesScore"].alpha = 0;	
		player.grnd_HUD["alliesText"].alpha = 0;			
		player.grnd_wasSpectator = true;		
	}
	
	if( !isAI( player ) )
		player thread grndTracking();		
}


getNextZone()
{
	pos = undefined;
	index = undefined;
	
	//	get the distance to the current zone from all the remaining zones
	//	set index and save furthest and closest along the way
	closestDistance = 99999999;
	furthestDistance = 0;
	
	if ( isDefined( level.teleport_zone_current ) && level.teleport_zone_current == "start" )
	{
		sortedZonesByDistance = SortByDistance( level.grnd_dropZones1, level.grnd_zone.origin );
	}
	else if ( isDefined( level.teleport_zone_current ) && level.teleport_zone_current != "start" )
	{
		//defensive check for zone 2 being active
		if( !isDefined(level.grnd_dropZones2) || !level.grnd_dropZones2.size )
			level initZones();
		
		sortedZonesByDistance = SortByDistance( level.grnd_dropZones2, level.grnd_zone.origin );
	}
	else
	{
		sortedZonesByDistance = SortByDistance( level.grnd_zones, level.grnd_zone.origin );
	}
	
	//totally random except for current node
	pos = sortedZonesByDistance[ RandomIntRange( 1, sortedZonesByDistance.size ) ].origin;
	
	return pos;	
}


cycleZones()
{	
	level notify ("cycleZones");
	level endon ("cycleZones");
	
	level endon( "game_ended" );	
	
	gameFlagWait( "prematch_done" );	
		
	while( true )
	{	
		//	move zone
		pos = undefined;
		if ( !level.firstZoneActive )
		{
			level.firstZoneActive = true;
			pos = level.grnd_zone.origin;
		}
		else
		{
			pos = getNextZone();			
			StopFxOnTag( level.grnd_fx["smoke"], level.grnd_zone, "tag_fx" );
			wait( 0.05 );					
		}		
		traceStart = pos + (0,0,30);
		traceEnd = pos + (0,0,-1000);
		trace = bulletTrace( traceStart, traceEnd, false, level.grnd_zone );		
		level.grnd_zone.origin = trace["position"]+(0,0,1);
		
		// there may be artifacts if something is in the way of the drop zone marker
		hitEntity = trace["entity"];
		if ( IsDefined( hitEntity ) )
		{
			// search up the links until we get the moving platform
			parent = hitEntity GetLinkedParent();
			while ( IsDefined( parent ) )
			{
				hitEntity = parent;
				parent = hitEntity GetLinkedParent();
			}
		}
		
		if ( IsDefined( hitEntity ) 
//		    && hitEntity != level.grnd_zone 
		   )
		{
			level.grnd_zone LinkTo( hitEntity );
		}
		else if ( level.grnd_zone IsLinked() )
		{
			level.grnd_zone Unlink();
		}
		
		level.alliesWeightOrg = level.grnd_zone.origin;
		level.axisWeightOrg = level.grnd_zone.origin;
		
		//	update danger zone
		level.grnd_dangerCenter.origin = level.grnd_zone.origin;
		
		//	target			
		thread spawnRegionVfx( level.grnd_zone.ringVfx, trace["position"], VectorToAngles( trace["normal"] ), 0.5 );
		
		//	smoke
		wait( 0.05 );
		PlayFxOnTag( level.grnd_fx["smoke"], level.grnd_zone, "tag_fx" );	
		
		foreach ( player in level.players )
			player.grnd_fx_playing = true;
	
		//	reset drops
		if ( level.matchRules_dropTime )
			level thread randomDrops();
		
		//	wait
		level.grnd_HUD["timerDisplay"].label = &"MP_NEXT_DROP_ZONE_IN";
		level.grnd_HUD["timerDisplay"] setTimer( level.matchRules_zoneSwitchTime );
		level.grnd_HUD["timerDisplay"].alpha = 1;	
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( level.matchRules_zoneSwitchTime );				
		level.grnd_HUD["timerDisplay"].alpha = 0;
		
		//	audio cue for progress
		playSoundOnPlayers( "mp_dropzone_obj_new" );	

		//Update bot ai
		foreach( player in level.players )
		{
			if( isAI( player ) )
				player thread maps\mp\bots\_bots_gametype_grnd::bot_grnd_think();
		}
	}
}


spawnFxDelay( pos, forward, right, delay )
{
	if ( isDefined( level.grnd_targetFX ) )
		level.grnd_targetFX delete();
	wait delay;
	level.grnd_targetFX = spawnFx( level.grnd_targetFXID, pos, forward, right );
	triggerFx( level.grnd_targetFX );
}

spawnRegionVfx( ringEnt, newPostion, angles, delay )
{
	StopFXOnTag( level.grnd_targetFXID, ringEnt, "tag_origin" );
	
	wait delay;
	
	ringEnt.origin = newPostion;
	ringEnt.angles = angles;
	
	PlayFXOnTag( level.grnd_targetFXID, ringEnt, "tag_origin" );
}


grndTracking()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	AssertEx( isDefined( self.team ), self.name + "Doesnt have a team defined.");
	
	if( !isDefined( self.team ) )
		return;
	
	while( true )
	{	
		if( !isDefined( self.grnd_wasSpectator ) )
			self.grnd_wasSpectator = false;
		
		if ( !self.grnd_wasSpectator && self.pers["team"] == "spectator" )
		{
			self.inGrindZone = false;
			self.inGrindZonePoints = 0;
			self.grndHeadIcon.alpha = 0;	
			//self.grnd_HUD["axisScore"].alpha = 0;	
			//self.grnd_HUD["axisText"].alpha = 0;
			//self.grnd_HUD["alliesScore"].alpha = 0;	
			//self.grnd_HUD["alliesText"].alpha = 0;			
			self.grnd_wasSpectator = true;		
		}
		else if ( self.team != "spectator" )
		{
			if ( ( self.grnd_wasSpectator || !self.inGrindZone ) && self isInGrindZone() )	
			{
				self.inGrindZone = true;
				self.inGrindZonePoints = 0;					
				self iPrintLnBold( &"OBJECTIVES_GRND_CONFIRM" );			
				//self.grnd_HUD["axisScore"].alpha = 1;	
				//self.grnd_HUD["axisText"].alpha = 1;
				//self.grnd_HUD["alliesScore"].alpha = 1;	
				//self.grnd_HUD["alliesText"].alpha = 1;
				//self.grnd_HUD[self.team+"Score"].glowAlpha = 1;
				//self.grnd_HUD[self.team+"Text"].glowAlpha = 1;				
				self.grndHeadIcon.alpha = 0;
			}
			else if ( ( self.grnd_wasSpectator || self.inGrindZone ) && !self isInGrindZone() )
			{
				self.inGrindZone = false;
				self.inGrindZonePoints = 0;
				self iPrintLnBold( &"OBJECTIVES_GRND_HINT" );				
				//self.grnd_HUD["axisScore"].alpha = 1;	
				//self.grnd_HUD["axisText"].alpha = 1;
				//self.grnd_HUD["alliesScore"].alpha = 1;	
				//self.grnd_HUD["alliesText"].alpha = 1;
				//self.grnd_HUD[self.team+"Score"].glowAlpha = 0;
				//self.grnd_HUD[self.team+"Text"].glowAlpha = 0;				
				self.grndHeadIcon.alpha = 0.85;
			}
			self.grnd_wasSpectator = false;
		}
		
		wait( 0.05 );
	}	
}


locationStatus()
{
	level endon( "game_ended" );
	
	level.grnd_numPlayers["axis"] = 0;
	level.grnd_numPlayers["allies"] = 0;	
	
	gameFlagWait( "prematch_done" );
	
	while( true )
	{
		level.grnd_numPlayers["axis"] = 0;
		level.grnd_numPlayers["allies"] = 0;
		
		foreach( player in level.players )
		{
			if ( isDefined( player.inGrindZone ) && isReallyAlive( player ) && player.pers["team"] != "spectator" && player isInGrindZone() )
				level.grnd_numPlayers[player.pers["team"]]++;
		}
		
		foreach( player in level.players )
		{
			if ( isDefined( player.inGrindZone ) && player.pers["team"] != "spectator" )
			{
				//axisPlayers = level.grnd_numPlayers["axis"] + 0;
				//alliesPlayers = level.grnd_numPlayers["allies"] + 0;
				//player.grnd_HUD["axisScore"] setText( 22 );	
				//player.grnd_HUD["alliesScore"] setText( 11 );	
				
				if ( level.grnd_numPlayers["axis"] == level.grnd_numPlayers["allies"] )
				{
					player.grndHeadIcon setShader( "waypoint_captureneutral_b", 14, 14 );
					player.grndHeadIcon setWaypoint( false, true, false, false );
					objective_icon( player.grndObjId, "waypoint_captureneutral_b" );					
				}
				else if ( level.grnd_numPlayers[player.pers["team"]] > level.grnd_numPlayers[level.otherTeam[player.pers["team"]]] )
				{
					player.grndHeadIcon setShader( "waypoint_defend_b", 14, 14 );
					player.grndHeadIcon setWaypoint( false, true, false, false );
					objective_icon( player.grndObjId, "waypoint_defend_b" );
				}
				else
				{
					player.grndHeadIcon setShader( "waypoint_capture_b", 14, 14 );
					player.grndHeadIcon setWaypoint( false, true, false, false );
					objective_icon( player.grndObjId, "waypoint_capture_b" );					
				}
			}
		}		
		
		//	wait
		wait( 0.5 );
	}
}


locationScoring()
{
	level endon( "game_ended" );
	
	gameFlagWait( "prematch_done" );
	
	score = maps\mp\gametypes\_rank::getScoreInfoValue( "zone_tick" );
	assert( isDefined( score ) );	
	
	while( true )
	{
		//	player team scoring feedback
		foreach( player in level.players )
		{
			
			if ( isDefined( player.inGrindZone ) && isReallyAlive( player ) && player.pers["team"] != "spectator" && player isInGrindZone() )
			{
				player.inGrindZonePoints += score;
				maps\mp\gametypes\_gamescore::givePlayerScore( "zone_tick", player, undefined, false, true );
				
				if ( isAI( player ) )
					continue;
				
				player.xpUpdateTotal = 0;
				player thread maps\mp\gametypes\_rank::xpPointsPopup( 20 );							
			}
		}
		
		//	update team scores
		if ( level.grnd_numPlayers["axis"] )
			maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( "axis", score * level.grnd_numPlayers["axis"] );
		if ( level.grnd_numPlayers["allies"] )
			maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( "allies", score * level.grnd_numPlayers["allies"] );	
		
		//	wait
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 1.0 );
	}
}

randomDrops()
{
	level endon( "game_ended" );
	level notify( "reset_grnd_drops" );
	level endon( "reset_grnd_drops" );
	
	//	try for no repeats per zone
	level.grnd_previousCrateTypes = [];
	
	while( true )
	{
		owner = getBestPlayer();			
		numIncomingVehicles = 1;
		if( isDefined( owner ) && 
			currentActiveVehicleCount() < maxVehiclesAllowed() && 
			level.fauxVehicleCount + numIncomingVehicles < maxVehiclesAllowed() && 
			level.numDropCrates < 8 )
		{
			owner thread maps\mp\gametypes\_rank::xpEventPopup( "earned_care_package" );
			owner thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "callout_earned_carepackage" );
			owner thread leaderDialog( level.otherTeam[ owner.team ] + "_enemy_airdrop_assault_inbound", level.otherTeam[ owner.team ] );
			owner thread leaderDialog( owner.team + "_friendly_airdrop_assault_inbound", owner.team );
			playSoundOnPlayers( "mp_dropzone_obj_taken", owner.team );
			playSoundOnPlayers( "mp_dropzone_obj_lost", level.otherTeam[owner.team] );			
			
			position = level.grnd_zone.origin + ( randomIntRange( (-1*GRND_ZONE_DROP_RADIUS), GRND_ZONE_DROP_RADIUS ), randomIntRange( (-1*GRND_ZONE_DROP_RADIUS), GRND_ZONE_DROP_RADIUS ), 0 );
						
			crateType = getDropZoneCrateType();
			if ( isSubStr( toLower( crateType ), "juggernaut" ) )
			{
				level thread maps\mp\killstreaks\_airdrop::doC130FlyBy( owner, position, randomFloat( 360 ), crateType );
			}
			else if ( crateType == "mega" )
			{
				level thread maps\mp\killstreaks\_airdrop::doMegaC130FlyBy( owner, position, randomFloat( 360 ), "airdrop_grnd", -360 );
			}
			else
			{
				incrementFauxVehicleCount();
				level thread maps\mp\killstreaks\_airdrop::doFlyBy( owner, position, randomFloat( 360 ), "airdrop_grnd", 0, crateType );
			}
			
			waitTime = level.matchRules_dropTime;
		}		
		else
			waitTime = 0.5;		
		
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( waitTime );
	}
}


getBestPlayer()
{		
	bestPlayer = undefined;
	bestPlayerPoints = 0;
		
	//	find the player with the currently highest accumulated points in the zone
	foreach ( player in level.players )
	{
		if ( isReallyAlive( player ) && player.pers["team"] != "spectator" )
		{
			if ( player isInGrindZone() && player.inGrindZonePoints > bestPlayerPoints )
			{
				bestPlayer = player;
				bestPlayerPoints = player.inGrindZonePoints;
			}
		}
	}	
	
	//	may return undefined
	return bestPlayer;
}


getDropZoneCrateType()
{
	crateType = undefined;
	if ( !isDefined( level.grnd_previousCrateTypes["mega"] ) && level.numDropCrates == 0 && randomIntRange( 0, 100 ) < 5 )
	{
		crateType = "mega";
	}
	else
	{
		if ( level.grnd_previousCrateTypes.size )
		{
			maxTries = 200;
			while( maxTries )
			{
				crateType = maps\mp\killstreaks\_airdrop::getRandomCrateType( "airdrop_grnd" );				
				if ( isDefined( level.grnd_previousCrateTypes[crateType] ) )
					crateType = undefined;
				else
					break;
				
				maxTries--;
			}
		}
		
		if ( !isDefined( crateType ) )
			crateType = maps\mp\killstreaks\_airdrop::getRandomCrateType( "airdrop_grnd" );
	}
	
	//	track it
	level.grnd_previousCrateTypes[crateType] = 1;	
	if ( level.grnd_previousCrateTypes.size == 15 )
		level.grnd_previousCrateTypes = [];
		
	return crateType;	
}


isInGrindZone()
{
	if ( distance2D( level.grnd_zone.origin, self.origin ) < GRND_ZONE_TOUCH_RADIUS && ( self.origin[2] > ( level.grnd_zone.origin[2] - 50 ) ) )
		return true;
	else
		return false;
}


hideHudElementOnGameEnd( hudElement )
{
	level waittill("game_ended");
	if ( isDefined( hudElement ) )
		hudElement.alpha = 0;
}


createZones()
{
	level.grnd_dropZones = [];
	level.grnd_dropZones1 = [];
	level.grnd_dropZones2 = [];
	
	chestSpawns = getstructarray( "sotf_chest_spawnpoint", "targetname" );
	
	if( GetDvar( "mapname" ) == "mp_strikezone" )
	{
		zone2grnd_zones = [];
		zone1grnd_zones = [];
		
		foreach( zone in chestSpawns )
		{
			if ( zone.origin[2] > 10000 )
				level.grnd_dropZones2[level.grnd_dropZones2.size] = zone;
			else
				level.grnd_dropZones1[level.grnd_dropZones1.size] = zone;
		}
	}
	else
	{
		foreach ( zone in chestSpawns)
		{
			level.grnd_dropZones[level.grnd_dropZones.size] = zone;	
		}
	}
	
	adjustZones();
}

//Add zone adjustments here, add new stuff or move them
adjustZones()
{
	levelName = toLower( getDvar("mapname") );
	
	//adding additional zone for sz part one
	if( levelName == "mp_strikezone" )
	{
		level.grnd_dropZones1[level.grnd_dropZones1.size] = spawnstruct();
		level.grnd_dropZones1[level.grnd_dropZones1.size-1].origin = (-121,-1334,-73);
	}
	
	//Flooded Adjustments
	if ( levelName == "mp_flooded" )
	{
		foreach( zone in level.grnd_dropZones )
		{
			if ( zone.origin == (-1596.9, 1315.7, 374.1) )
				zone.origin = (-1561, 1278, 431 );
		}
	}
	
	//Zebra Adjustments
	if ( levelName == "mp_zebra" )
	{
		foreach( zone in level.grnd_dropZones )
		{
			if ( zone.origin == (4008.3, -2066.3, 482.1 ) )
				zone.origin = (4048, -1985, 539 );
		}
	}
	
	if ( isSubStr( levelName, "descent" ) )
	{
		foreach( zone in level.grnd_dropZones )
		{
			if ( zone.origin == (1101, 116, 5373.1) )
				zone.origin = (1072, -80, 5378);
		}
	}
	
	//debug prints
	/#
		println( "" );
		println( "DROPZONE DEBUG INFORMATION" );
		foreach ( zone in level.grnd_dropZones)
		{
			println( "Zone Origin: " + zone.origin );
		}
		println( "" );
	#/
}