#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;


/*QUAKED mp_blitz_spawn (0.0 0.0 1.0) (-16 -16 0) (16 16 72)
Respawn Point.*/

/*QUAKED mp_blitz_spawn_axis_start (0.5 0.0 1.0) (-16 -16 0) (16 16 72)
Start Spawn.*/

/*QUAKED mp_blitz_spawn_allies_start (0.0 0.5 1.0) (-16 -16 0) (16 16 72)
Start Spawn.*/

BLITZ_DEFEND				 = "waypoint_blitz_defend";
BLITZ_GOAL					 = "waypoint_blitz_goal";
BLITZ_WAIT_ENEMY			 = "waypoint_blitz_wait_enemy";
BLITZ_WAIT_FRIEND			 = "waypoint_blitz_wait_friend";
BLITZ_SCORE_LIMIT			 = 16;
BLITZ_TRIGGER_RADIUS_SQUARED = 4300;

//============================================
// 		 			main
//============================================
main()
{
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
		registerScoreLimitDvar( level.gameType, BLITZ_SCORE_LIMIT );
		registerTimeLimitDvar( level.gameType, 5 );
		registerRoundLimitDvar( level.gameType, 2 );	
		registerRoundSwitchDvar( level.gameType, 1, 0, 1 );
		registerWinLimitDvar( level.gameType, 0 );
		registerNumLivesDvar( level.gameType, 0 );
		
		level.matchRules_damageMultiplier = 0;
	}
	
	level.teamBased			 = true;
	level.objectiveBased	 = false;
	level.supportBuddySpawn	 = false;
	level.onStartGameType	 = ::onStartGameType;
	level.getSpawnPoint		 = ::getSpawnPoint;
	level.onTimeLimit		 = ::onTimeLimit;
	level.onNormalDeath		 = ::onNormalDeath;
	level.onPlayerKilled	 = ::onPlayerKilled;
	level.onSpawnPlayer		 = ::onSpawnPlayer;
	level.initGametypeAwards = ::initGametypeAwards;
	level.spawnNodeType		 = ter_op( GetDvarInt( "scr_altBlitzSpawns", 0 ) == 1, "mp_tdm_spawn", "mp_blitz_spawn" );
	
	if ( level.matchRules_damageMultiplier )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;
	
	game["dialog"]["gametype"] = "blitz";
	
	if ( getDvarInt( "g_hardcore" ) )
		game["dialog"]["gametype"] = "hc_" + game["dialog"]["gametype"];
	
	game["dialog"]["offense_obj"] = "bltz_hint";
	game["dialog"]["defense_obj"] = "bltz_hint";
	game["dialog"]["bltz_e_scored"] = "bltz_e_scored";
	game["dialog"]["bltz_scored"] = "bltz_scored";
}


//============================================
// 		 	initializeMatchRules
//============================================
initializeMatchRules()
{
	// Score check
	AssertEx( GetDvarInt( "scr_blitz_scorelimit", BLITZ_SCORE_LIMIT ) % 2 == 0, "Blitz scorelimit needs to be an even number." );
	
	//	set common values
	setCommonRulesFromMatchRulesData();

	SetDynamicDvar( "scr_blitz_roundswitch", 1 );
	registerRoundSwitchDvar( "blitz", 1, 0 , 1 );						
	SetDynamicDvar( "scr_blitz_roundlimit", 2 );
	registerRoundLimitDvar( "blitz", 2 );					
	SetDynamicDvar( "scr_blitz_winlimit", 0 );
	registerWinLimitDvar( "blitz", 0 );			
		
	SetDynamicDvar( "scr_blitz_promode", 0 );		
}


//============================================
// 		 	initEffects
//============================================
initEffects()
{
	level._effect["portal_fx_defend"] 	= LoadFX("vfx/gameplay/mp/core/vfx_marker_base_cyan");
	level._effect["portal_fx_goal"] 	= LoadFX("vfx/gameplay/mp/core/vfx_marker_base_orange");
	level._effect["portal_fx_closed"]	= LoadFX("vfx/gameplay/mp/core/vfx_marker_base_grey");
	level._effect["blitz_teleport"] 	= LoadFX("vfx/gameplay/mp/core/vfx_teleport_player");
}


//============================================
// 		 	onStartGameType
//============================================
onStartGameType()
{
	setObjectiveText( "allies", &"OBJECTIVES_BLITZ" );
	setObjectiveText( "axis", &"OBJECTIVES_BLITZ" );

	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_BLITZ" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_BLITZ" );
	}
	else
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_BLITZ_ATTACKER_SCORE" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_BLITZ_ATTACKER_SCORE" );
	}
	setObjectiveHintText( "allies", &"OBJECTIVES_BLITZ_HINT" );
	setObjectiveHintText( "axis", &"OBJECTIVES_BLITZ_HINT" );
	
	setClientNameMode("auto_change");
	
	if ( !isdefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	if( game["switchedsides"] )
	{
		oldAttackers = game["attackers"];
		oldDefenders = game["defenders"];
		game["attackers"] = oldDefenders;
		game["defenders"] = oldAttackers;
	}

	initSpawns();
	initEffects();
		
	allowed[0] = level.gameType;
	maps\mp\gametypes\_gameobjects::main( allowed );	
	
	createPortals();
	level thread onPlayerConnect();
	
	assignTeamSpawns();
	level thread runBlitz();
}

onPlayerConnect()
{
	level endon ("game_ended");
	
	while (true)
	{
		level waittill("connected", player);
		
		// Show spectator portal effects after connecting 
		player showSpectatorPortalFX();
		
		player thread refreshFreecamPortalFX();
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self waittill( "spawned_player" );

	// Show them the portal effects after they initially spawn
	self showTeamPortalFX();

	// Refresh their effects if they switch teams
	self thread	refreshTeamPortalFX();
	self thread refreshSpectatorPortalFX();
	self thread clearFXOnDisconnect();
}

//============================================
// 		 		initSpawns
//============================================
initSpawns()
{
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_blitz_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_blitz_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", level.spawnNodeType );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", level.spawnNodeType );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
}


//============================================
// 		 		createPortals
//============================================
createPortals()
{
	level.portals = [];
	
	if ( game["switchedsides"] )
	{
		// Switch the team affiliation of the triggers after halftime
		axisPortalTrigger = getEnt( "allies_portal", "targetname" );
		alliesPortalTrigger = getEnt( "axis_portal", "targetname" );		
	}
	else
	{
		axisPortalTrigger = getEnt( "axis_portal", "targetname" );
		alliesPortalTrigger = getEnt( "allies_portal", "targetname" );
	}
	
	level.portalList["axis"] = createPortal( axisPortalTrigger, "axis" );
	level.portalList["allies"] 	= createPortal( alliesPortalTrigger, "allies" );
}


//============================================
// 		 		cretaePortal
//============================================
createPortal( trigger, team )
{
	AssertEx( IsDefined(trigger), "map needs blitz game objects" );
	
	portal 				= SpawnStruct();
	portal.origin 		= trigger.origin;
	portal.ownerTeam	= team;
	portal.open 		= true;
	portal.guarded		= false;
	portal.trigger 		= trigger;
	
	if( IsDefined( level.matchRecording_generateID ) && IsDefined( level.matchRecording_logEvent ) )
	{
		if( !IsDefined( game["blitzPortalLogIDs"] ) )
			game["blitzPortalLogIDs"] = [];
		
		if( !IsDefined( game["blitzPortalLogIDs"][team] ) )
			game["blitzPortalLogIDs"][team] = [[ level.matchRecording_generateID ]]();
		
		stateValue = ter_op( team == "allies", 0, 1 );
		
		[[ level.matchRecording_logEvent ]]( game["blitzPortalLogIDs"][team] , undefined, "PORTAL", portal.origin[ 0 ],portal.origin[ 1 ], GetTime(), stateValue );
	}

	return portal;
}


CONST_PORTAL_TERRITORY_PERCENT = 0.33;


//============================================
// 		 		assginTeamSpawns
//============================================
assignTeamSpawns()
{
	spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( level.spawnNodeType );
	isPathDataAvailable = maps\mp\gametypes\_spawnlogic::isPathDataAvailable();
	
	level.teamSpawnPoints["axis"] 	= [];
	level.teamSpawnPoints["allies"] = [];
	level.teamSpawnPoints["neutral"] = [];
	
	
	if( GetDvarInt( "scr_altBlitzSpawns", 0 ) == 1 && level.portalList.size == 2 )
	{
		portalA = level.portalList["allies"];
		portalB = level.portalList["axis"];
		
		portalOriginA2D = ( portalA.origin[0], portalA.origin[1], 0 );
		portalOriginB2D = ( portalB.origin[0], portalB.origin[1], 0 );
		
		portalDelta = portalOriginB2D - portalOriginA2D;
		portalDist = Length2D( portalDelta );
		
		foreach( spawnPoint in spawnPoints )
		{
			spawnPointOrigin2D = ( spawnPoint.origin[0], spawnPoint.origin[1], 0 );
			portalAToSpawnpoint = spawnPointOrigin2D - portalOriginA2D;
			dotValue = VectorDot( portalAToSpawnpoint, portalDelta );
			percentageBetweenPortals = dotValue / ( portalDist * portalDist );
			if( percentageBetweenPortals < CONST_PORTAL_TERRITORY_PERCENT )
			{
				spawnPoint.teamBase = portalA.ownerTeam;
				level.teamSpawnPoints[spawnPoint.teamBase][level.teamSpawnPoints[spawnPoint.teamBase].size] = spawnPoint;
			}
			else if( percentageBetweenPortals > 1.0 - CONST_PORTAL_TERRITORY_PERCENT )
			{
				spawnPoint.teamBase = portalB.ownerTeam;
				level.teamSpawnPoints[spawnPoint.teamBase][level.teamSpawnPoints[spawnPoint.teamBase].size] = spawnPoint;
			}
			else
			{
				// The spawnPoint is in the neutral zone, now decide if it's balanced enough to use.
				// NOTE ahampton 4/8/14: This is only because we're switching to TDM spawns post-ship on IW6, future titles shouldn't need this logic
				portalADist = undefined;
				portalBDist = undefined;
				if( isPathDataAvailable )
					portalADist = GetPathDist( spawnPoint.origin, portalA.origin, 999999 );
				
				if( IsDefined(portalADist) && (portalADist != -1) )
				{
					portalBDist = GetPathDist( spawnPoint.origin, portalB.origin, 999999 );
				}
				
				if( !IsDefined(portalBDist) || (portalBDist == -1) )
				{
					portalADist = distance2D( portalA.origin, spawnPoint.origin );
					portalBDist = distance2D( portalB.origin, spawnPoint.origin );
				}
				
				biggerDist = max( portalADist, portalBDist );
				smallerDist = min( portalADist, portalBDist );
				distPercent = smallerDist / biggerDist;
				
				// Check that the distance to each portal is not overly lopsided.
				if( distPercent > 0.5 )
				{
					level.teamSpawnPoints["neutral"][level.teamSpawnPoints["neutral"].size] = spawnPoint;
				}
				
			}
		}
	}
	else
	{
		foreach( spawnPoint in spawnPoints )
		{	
			spawnPoint.teamBase = getNearestPortalTeam( spawnPoint );
			
			if( spawnPoint.teamBase == "axis" )
			{
				level.teamSpawnPoints["axis"][level.teamSpawnPoints["axis"].size] = spawnPoint;
			}
			else
			{
				level.teamSpawnPoints["allies"][level.teamSpawnPoints["allies"].size] = spawnPoint;
			}
		}	
	}
	
	/#
	level thread blitzDebug();
	#/
}


//===========================================
// 			getNearestPortalTeam
//===========================================
getNearestPortalTeam( spawnPoint )
{
	isPathDataAvailable = maps\mp\gametypes\_spawnlogic::isPathDataAvailable();
	nearestPortal		= undefined;
	nearestDist			= undefined;

	foreach( portal in level.portalList )
	{
		dist = undefined;
		
		// find the actual pathing distance between the portal and spawn point
		if( isPathDataAvailable )
		{
			dist = GetPathDist( spawnPoint.origin, portal.origin, 999999 );
		}
		
		// fail safe for bad pathing data		
		if( !IsDefined(dist) || (dist == -1) )
		{
			dist = distancesquared( portal.origin, spawnPoint.origin );
		}
		
		// record the nearest portal
		if( !isdefined( nearestPortal ) || dist < nearestDist )
		{
			nearestPortal 	= portal;
			nearestDist 	= dist;
		}
	}
	
	return nearestPortal.ownerTeam;
}

//============================================
// 		 		onNormalDeath
//============================================
onNormalDeath( victim, attacker, lifeId )
{
	attacker thread maps\mp\gametypes\_rank::xpEventPopup( "kill" );
}


//============================================
// 		 		runBlitz
//============================================
runBlitz()
{
	startPortal( level.portalList["axis"] );
	startPortal( level.portalList["allies"] );	
}


//============================================
// 		 		startPortal
//============================================
startPortal( portal )
{
	level thread runPortalFX( portal );
	level thread runPortalStatus( portal );
	level thread runPortalThink( portal );
}


//============================================
// 		 		runPortalFX
//============================================
runPortalFX( portal )
{
	level endon( "final_score_teleport" );
	level endon( "halftime_score_teleport" );
	level endon( "time_ended" );
	level endon( "force_end" );
	
	portalTeam = blitzGetTeam( portal );
	
	portal childthread onPortalUsed( portalTeam );
	portal childthread onPortalReady( portalTeam );
}

onPortalUsed( portalTeam )
{
	// self == portal 
	
	while ( true )
	{
		level waittill ( "portal_used", teamUsed );
		
		// Skip if the portal that was used is not this one
		if ( teamUsed != portalTeam )
			continue;
		
		// Hide the open effect for this portal
		self hideOpenPortalFX( portalTeam );

		// Show the closed effect for this portal
		self showClosedPortalFX( portalTeam );
	}	
}

onPortalReady( portalTeam )
{
	// self == portal 
	
	while ( true )
	{
		level waittill ( "portal_ready", teamReady );
	
		// Skip if the portal that was used is not this one
		if ( teamReady != portalTeam )
			continue;

		// Since we are connstantly sending the "portal_ready" notification if the portal isn't guarded,
		// This will stop "wait" effect from being prematurely stopped
		if ( !self.open )
			continue;
		
		// Hide the closed effect for this portal
		self hideClosePortalFX( portalTeam );

		// Show the open effect for this portal
		self showOpenPortalFX( portalTeam );
	}	
}

hideOpenPortalFX( portalTeam )
{
	// self == portal 
	// Go through each player and hide the open effect
	foreach ( player in level.players )
	{
		if ( !IsDefined( player ) || !IsDefined( player.team ) )
			continue;	
		
		if ( player.team == "allies" || player.team == "axis" )
		{
			if ( player.team == portalTeam )
			{
				if ( IsDefined( player.defend_fx_ent ) )
					player.defend_fx_ent Delete();
			}
			else
			{
				if ( IsDefined( player.goal_fx_ent ) )
					player.goal_fx_ent Delete();		
			}
		}
		else
		{
			// Spectator view
			isMLG = player isMLGSpectator();
			if ( ( isMLG && portalTeam == ( player GetMLGSpectatorTeam() ) ) || ( !isMLG && portalTeam == "allies" ) )
			{
				if ( IsDefined( player.defend_fx_ent ) )
					player.defend_fx_ent Delete();
			}
			else
			{
				if ( IsDefined( player.goal_fx_ent ) )
					player.goal_fx_ent Delete();	
			}	
				
		}
	}	
}

showOpenPortalFX( portalTeam )
{
	// self == portal 
	// Go through each player and show the open effect
	foreach ( player in level.players )
	{
		if ( !IsDefined( player ) || !IsDefined( player.team ) )
			continue;
		
		if ( player.team == "allies" || player.team == "axis" )
		{
			if ( player.team == portalTeam )
			{
				if ( !IsDefined( player.defend_fx_ent ) )
				{
					player.defend_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_defend" ], self.origin, player );
					TriggerFX( player.defend_fx_ent );
				}
			}
			else
			{
				if ( !IsDefined( player.goal_fx_ent ) )
				{			
					player.goal_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_goal" ], self.origin, player );
					TriggerFX( player.goal_fx_ent );
				}
			}
		}
		else
		{
			// Spectator view
			isMLG = player isMLGSpectator();
			if ( ( isMLG && portalTeam == player GetMLGSpectatorTeam() ) || ( !isMLG && portalTeam == "allies" ) )
			{
				if ( !IsDefined( player.defend_fx_ent ) )
				{
					player.defend_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_defend" ], self.origin, player );
					TriggerFX( player.defend_fx_ent );
				}
			}
			else
			{
				if ( !IsDefined( player.goal_fx_ent ) )
				{			
					player.goal_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_goal" ], self.origin, player );
					TriggerFX( player.goal_fx_ent );
				}
			}			
		}
	}	
}

hideClosePortalFX( portalTeam )
{
	// self == portal 
	// Go through each player and hide the closed effect
	foreach ( player in level.players )
	{
		if ( !IsDefined( player ) || !IsDefined( player.team ) )
			continue;

		if ( player.team == "allies" || player.team == "axis" )
		{		
			if ( player.team == portalTeam )
			{
				if ( IsDefined( player.closed_defend_fx_ent ) )
					player.closed_defend_fx_ent Delete();
			}
			else
			{
				if ( IsDefined( player.closed_goal_fx_ent ) )
					player.closed_goal_fx_ent Delete();			
			}
		}
		else
		{
			isMLG = player isMLGSpectator();
			if ( ( isMLG && portalTeam == ( player GetMLGSpectatorTeam() ) ) || ( !isMLG && portalTeam == "allies" ) )
			{
				if ( IsDefined( player.closed_defend_fx_ent ) )
					player.closed_defend_fx_ent Delete();
			}
			else
			{
				if ( IsDefined( player.closed_goal_fx_ent ) )
					player.closed_goal_fx_ent Delete();			
			}				
		}
	}
}

showClosedPortalFX( portalTeam )
{
	// self == portal 
	// Go through each player and show the closed effect
	foreach ( player in level.players )
	{
		if ( !IsDefined( player ) || !IsDefined( player.team ) )
			continue;

		if ( player.team == "allies" || player.team == "axis" )
		{		
			if ( player.team == portalTeam )
			{
				if ( !IsDefined( player.closed_defend_fx_ent ) )
				{			
					player.closed_defend_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_closed" ], self.origin, player );
					TriggerFX( player.closed_defend_fx_ent );
				}
			}
			else
			{
				if ( !IsDefined( player.closed_goal_fx_ent ) )
				{				
					player.closed_goal_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_closed" ], self.origin, player );
					TriggerFX( player.closed_goal_fx_ent );
				}
			}
		}
		else
		{
			isMLG = player isMLGSpectator();
			if ( ( isMLG && portalTeam == ( player GetMLGSpectatorTeam() ) ) || ( !isMLG && portalTeam == "allies" ) )
			{
				if ( !IsDefined( player.closed_defend_fx_ent ) )
				{			
					player.closed_defend_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_closed" ], self.origin, player );
					TriggerFX( player.closed_defend_fx_ent );
				}
			}
			else
			{
				if ( !IsDefined( player.closed_goal_fx_ent ) )
				{				
					player.closed_goal_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_closed" ], self.origin, player );
					TriggerFX( player.closed_goal_fx_ent );
				}
			}			
		}
	}
}

refreshTeamPortalFX()
{
	self endon ("disconnect");
	level endon ("game_ended");
	
	while(true)
	{
		self waittill ("joined_team");
		self showTeamPortalFX();
	}
}

refreshSpectatorPortalFX()
{
	self endon ("disconnect");
	level endon ("game_ended");	
	
	while(true)
	{
		self waittill ("joined_spectators");
		self showSpectatorPortalFX();
	}
}


refreshFreecamPortalFX()
{
	self endon ("disconnect");
	level endon ("game_ended");	
	
	while(true)
	{
		self waittill ("luinotifyserver", channel, view);
		if ( channel == "mlg_view_change" )
		{
			self showSpectatorPortalFX();
		}
	}
}


clearFXOnDisconnect()
{
	self waittill ("disconnect");
	self clearPortalFX();
}

showTeamPortalFX()
{
	// self == player
	
	// Failsafe for when someone does not join a team in Private Match, and exits the game
	// When the KEM strike happens, this function gets called to refresh the effects on the portals
	// So we need to make sure they have a valid team before proceeding to show them anything
	if ( self.team != "allies" && self.team != "axis" )
		return;
	
	playerTeam = self.team;
	enemyTeam = getOtherTeam(playerTeam);
	
	// Make sure we start out with a clean state
	self clearPortalFX();
	
	if ( IsDefined( level.portalList[ playerTeam ] ) && IsDefined( level.portalList[ enemyTeam ] ) )
	{
		// Player team's portal
		if ( level.portalList[ playerTeam ].open && !level.portalList[ playerTeam ].guarded )
		{
			self.defend_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_defend" ], level.portalList[playerTeam].origin , self );
			TriggerFX( self.defend_fx_ent );
		}
		else
		{
			self.closed_defend_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_closed" ], level.portalList[playerTeam].origin , self );
			TriggerFX( self.closed_defend_fx_ent );		
		}
		// Enemy team's portal	
		if ( level.portalList[enemyTeam].open && !level.portalList[enemyTeam].guarded )
		{
			self.goal_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_goal" ], level.portalList[enemyTeam].origin , self );
			TriggerFX( self.goal_fx_ent );
		}
		else
		{
			self.closed_goal_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_closed" ], level.portalList[enemyTeam].origin , self );
			TriggerFX( self.closed_goal_fx_ent );	
		}
	}
}

showSpectatorPortalFX()
{
	// self == player
	
	// Make sure we start out with a clean state
	self clearPortalFX();
	
	playerTeam = "allies";
	enemyTeam = "axis";
	isMLG = self isMLGSpectator();
	if ( isMLG )
	{
		playerTeam = self GetMLGSpectatorTeam();
		enemyTeam = getOtherTeam(playerTeam);
	}
	
	if ( IsDefined( level.portalList[ playerTeam ] ) && IsDefined( level.portalList[ enemyTeam ] ) )
	{
		// Player team's portal
		if ( level.portalList[ playerTeam ].open && !level.portalList[ playerTeam ].guarded )
		{
			self.defend_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_defend" ], level.portalList[playerTeam].origin , self );
			TriggerFX( self.defend_fx_ent );
		}
		else
		{
			self.closed_defend_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_closed" ], level.portalList[playerTeam].origin , self );
			TriggerFX( self.closed_defend_fx_ent );		
		}
		// Enemy team's portal	
		if ( level.portalList[enemyTeam].open && !level.portalList[enemyTeam].guarded )
		{
			self.goal_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_goal" ], level.portalList[enemyTeam].origin , self );
			TriggerFX( self.goal_fx_ent );
		}
		else
		{
			self.closed_goal_fx_ent = SpawnFXForClient( level._effect[ "portal_fx_closed" ], level.portalList[enemyTeam].origin , self );
			TriggerFX( self.closed_goal_fx_ent );	
		}
	}
}

clearPortalFX()
{
	// self == player
	
	// Clear out any existing effects
	
	if ( isDefined ( self.defend_fx_ent ) )
		self.defend_fx_ent delete();
	
	if ( isDefined ( self.closed_defend_fx_ent ) )
		self.closed_defend_fx_ent delete();
	
	if ( isDefined ( self.goal_fx_ent ) )
		self.goal_fx_ent delete();
	
	if ( isDefined( self.closed_goal_fx_ent ) )
		self.closed_goal_fx_ent delete();
}

//============================================
// 		 		runPortalStatus
//============================================
runPortalStatus( portal, label )
{
	level endon( "final_score_teleport" );
	level endon( "halftime_score_teleport" );
	level endon( "time_ended" );
	level endon( "force_end" );
	
	offset = (0,0,72);
	portalTeam 	= blitzGetTeam( portal );
	enemyTeam 	= getOtherTeam( portalTeam );
	
	portal.ownerTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( portal.ownerTeamID, "active", portal.origin + offset, BLITZ_DEFEND ); 
	Objective_Team( portal.ownerTeamID, portalTeam );
	
	portal.enemyTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
	objective_add( portal.enemyTeamID, "active", portal.origin + offset, BLITZ_GOAL );
	Objective_Team( portal.enemyTeamID, enemyTeam );
	
	while( true )
	{
		if( portal.open )
		{
			portal.teamHeadIcon 	= portal maps\mp\_entityheadIcons::setHeadIcon( portalTeam, BLITZ_DEFEND, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			portal.enemyHeadIcon 	= portal maps\mp\_entityheadIcons::setHeadIcon( enemyTeam, BLITZ_GOAL, offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			Objective_Icon( portal.ownerTeamID, BLITZ_DEFEND );
			Objective_Icon( portal.enemyTeamID, BLITZ_GOAL );
		}
		else
		{
			if(!isDefined(portal.waitIconActive) || !portal.waitIconActive)
			{
				portal.waitIconActive = true;
				portal childthread refreshWaitIcon(portal, portalTeam, enemyTeam, offset);
			}
		}
		
		level waittill_any( "portal_used", "portal_ready" );
	}
}

refreshWaitIcon( portal, portalTeam, enemyTeam, offset )
{
	countdownMaxNum = 10;
	
	for(i = countdownMaxNum; i > 0; i--)
	{
		// Team Wait Icon
		if ( i == countdownMaxNum )
		{
			portal.teamHeadIcon = portal maps\mp\_entityheadIcons::setHeadIcon( portalTeam, "blitz_time_" + i + "_blue", offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			Objective_Icon( portal.ownerTeamID, "blitz_time_" + i + "_blue" );
		}
		else
		{
			portal.teamHeadIcon = portal maps\mp\_entityheadIcons::setHeadIcon( portalTeam, "blitz_time_0" + i + "_blue", offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			Objective_Icon( portal.ownerTeamID, "blitz_time_0" + i + "_blue" );
		}		
		
		// Enemy Wait Icon
		if ( i == countdownMaxNum )
		{
			portal.enemyHeadIcon = portal maps\mp\_entityheadIcons::setHeadIcon( enemyTeam, "blitz_time_" + i + "_orng", offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			Objective_Icon( portal.enemyTeamID, "blitz_time_" + i + "_orng" );	
		}
		else
		{
			portal.enemyHeadIcon = portal maps\mp\_entityheadIcons::setHeadIcon( enemyTeam, "blitz_time_0" + i + "_orng", offset, 4, 4, undefined, undefined, undefined, true, undefined, false );
			Objective_Icon( portal.enemyTeamID, "blitz_time_0" + i + "_orng" );	
		}

		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 1 );
	}
	
	portal.waitIconActive = false;
}

//============================================
// 		 	runPortalThink
//============================================
runPortalThink( portal )
{
	level endon( "final_score_teleport" );
	level endon( "halftime_score_teleport" );
	level endon( "time_ended" );
	level endon( "force_end" );	
	
	portalTeam = blitzGetTeam( portal );
	
	// The amount of time it takes before the portal opens up again
	inactiveTime = GetDvarFloat( "scr_blitz_scoredelay", 10 );
	
	portal childthread guardWatch( portalTeam );
		
	while( true )
	{
		portal.trigger waittill( "trigger", player );
		
		if ( validScorerCheck( player, portal, portalTeam ) )
		{
			portal.open = false;
			level notify( "portal_used", portalTeam );
	
			playerTriggeredPortal( player, portal, portalTeam );
			maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( inactiveTime );
				
			portal.open = true;
			level notify( "portal_ready", portalTeam );	
		}
	}
}

validScorerCheck( player, portal, portalTeam )
{
	if( !isPlayer(player) )
		return false;
	
	if ( player.team == portalTeam || player.team == "spectator" )
		return false;
	
	// Stop players of the other team from entering the portal while someone on the portal team is guarding it
	if ( checkGuardedPortal( portal, portalTeam ) )
		return false;
	
	if ( player IsLinked() )
		return false;
	
	//keeps a player from porting while placing a killstreak (for consistency)
	if ( isDefined( player.isCarrying ) && player.isCarrying )
		return false;	
	
	return true;
}

playerTriggeredPortal( player, portal, portalTeam )
{
	leaderDialog( "bltz_e_scored", portalTeam );
	
	leaderDialog( "bltz_scored", getOtherTeam(portalTeam) );
	
	maps\mp\gametypes\_gamescore::givePlayerScore( "capture", player );	
	player thread maps\mp\gametypes\_rank::giveRankXP( "capture" );
	player maps\mp\killstreaks\_killstreaks::giveAdrenaline( "capture" );
	giveTeamScore( player.team );
	
	player incPlayerStat( "pointscaptured", 1 );
	player incPersStat( "captures", 1 );
	player maps\mp\gametypes\_persistence::statSetChild( "round", "captures", player.pers[ "captures" ] );
	
	player maps\mp\gametypes\_missions::processChallenge( "ch_blitz_score" );
	if ( player maps\mp\gametypes\_missions::playerIsSprintSliding() )
	{
		player maps\mp\gametypes\_missions::processChallenge( "ch_saafe" );
	}
	
	// OP_IW6 Telefragged - stick an enemy with semtex before he scores
	if ( IsDefined( player.stuckByGrenade ) && IsDefined( player.stuckByGrenade.owner ) )
	{
		player.stuckByGrenade.owner maps\mp\gametypes\_missions::processChallenge( "ch_telefragged" );
	}
	
	// set the extra score value for the scoreboard
	player setExtraScore0( player.pers[ "captures" ] );

	spawnPoint = player getSpawnPoint();
	player thread teleport_player( spawnPoint.origin, spawnPoint.angles );
}

guardWatch( portalTeam )
{
	//self == portal
	
	while(true)
	{
		if ( checkGuardedPortal( self, portalTeam ) )
		{
			level notify( "portal_used", portalTeam );
			self.guarded = true;
		}
		else
		{
			level notify( "portal_ready", portalTeam );
			self.guarded = false;
		}
		
		waitframe();
	}
}

checkGuardedPortal( portal, portalTeam )
{	
	foreach ( player in level.participants )
	{
		if ( !isDefined( player ) || !isDefined( player.team ) )
			continue;
		
		// We are checking fauxDead to make sure they are truly alive
		// They could be dead, but still using a killstreak
		if ( player.team == portalTeam && IsAlive( player ) && !IsDefined ( player.fauxDead ) ) 
		{
			if ( DistanceSquared( portal.origin, player.origin ) < BLITZ_TRIGGER_RADIUS_SQUARED )
				return true;
		}
	}
	
	return false;
}


//============================================
// 		 		giveTeamScore
//============================================
giveTeamScore(team)
{
	maps\mp\gametypes\_gamescore::giveTeamScoreForObjective( team, 1 );
	
	foreach( player in level.players )
	{
		ourTeam = player.team;
		if( player.team == "spectator" )
		{		
			spectated_player = player GetSpectatingPlayer();
			if ( isDefined( spectated_player ) )
			{
				ourTeam = spectated_player.team;
			}
			else
			{
				// give generic team score message if spectating free-cam
				player thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "blitz_score_team" );
				continue;
			}
		}

		if( ourTeam == team )
		{
			player thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "blitz_score_team" );
		}
		else
		{
			player thread maps\mp\gametypes\_hud_message::SplashNotifyUrgent( "blitz_score_enemy" );
		}
	}
}


teleport_player( origin, angles )
{
	self endon("death");
	self endon("disconnect");
	
	// Let airdrop know that the player is teleporting, so they can't use a care package while teleporting
	self.teleporting = true;
	
	// Notify the final score teleport
	self checkScoreLimit();
	
	flashTime = 1;
	white = create_client_overlay( "white", 1, self );
	white thread fade_over_time( 0, flashTime );
	white thread hudDelete( flashTime );
	
	fx_origin = self gettagorigin( "j_SpineUpper" );
	PlayFX( level._effect["blitz_teleport"], fx_origin );
	
	//Clear Tac insert on teleport
	if ( isDefined( self.setSpawnPoint ) )
		self maps\mp\perks\_perkfunctions::deleteTI( self.setSpawnPoint );
	
	self CancelMantle();
	self SetOrigin(origin);
	self SetPlayerAngles( angles );
	self SetStance("stand");

	// Allow the player to visually finish teleporting before we reset his status
	wait(flashTime);
	
	self.teleporting = false;
}

create_client_overlay( shader_name, start_alpha, player )
{
	if ( isdefined( player ) )
		overlay = newClientHudElem( player );
	else
		overlay = newHudElem();
	overlay.x = 0;
	overlay.y = 0;
	overlay setshader( shader_name, 640, 480 );
	overlay.alignX = "left";
	overlay.alignY = "top";
	overlay.sort = 1;
	overlay.horzAlign = "fullscreen";
	overlay.vertAlign = "fullscreen";
	overlay.alpha = start_alpha;
	overlay.foreground = true;
	return overlay;
}

fade_over_time( target_alpha, fade_time )
{
	assertex( isdefined( target_alpha ), "fade_over_time must be passed a target_alpha." );
	
	if ( isdefined( fade_time ) && fade_time > 0 )
	{
		self fadeOverTime( fade_time );
	}
	
	self.alpha = target_alpha;
	
	if ( isdefined( fade_time ) && fade_time > 0 )
	{
		wait fade_time;
	}
}


//============================================
// 		 		hudDelete
//============================================
hudDelete( delay )
{
	self endon("death");
	wait( delay );
	
	self Destroy();
}


//============================================
// 		 		getSpawnPoint
//============================================
getSpawnPoint()
{
	spawnteam = blitzGetTeam( self );
	enemyteam = getOtherTeam(spawnteam);

	if ( maps\mp\gametypes\_spawnlogic::shouldUseTeamStartSpawn() )
	{
		// Since we switched sides we need to make sure players are spawning on the correct side
		if( game["switchedsides"] )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_blitz_spawn_" + enemyteam + "_start" );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_startSpawn( spawnPoints );			
		}
		else
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_blitz_spawn_" + spawnteam + "_start" );
			spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_startSpawn( spawnPoints );
		}
	}
	else
	{
		usingFallbackPoints = level.teamSpawnPoints["neutral"].size > 0;
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnteam );
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_awayFromEnemies( spawnPoints, spawnteam, usingFallbackPoints );
		if( !IsDefined( spawnPoint ) && usingFallbackPoints )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( "neutral" );
			spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_awayFromEnemies( spawnPoints, spawnteam, false );
		}
	}
	
	return spawnPoint;
}


//============================================
// 		 		onPlayerKilled
//============================================
onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, killId )
{
	if( !IsDefined(attacker) || !isPlayer(attacker) )
		return;
		
	victim 				= self;
	victimTeam 			= blitzGetTeam( victim );
	attackerTeam 		= blitzGetTeam( attacker );
	
	if( attackerTeam == victimTeam )
		return;

	defendLocation 		= level.portalList[attackerTeam].origin;
	scoreLocation 		= level.portalList[victimTeam].origin;
	awardedAssault 		= 0;
	awardedDefend 		= 0;
	nearPortalDistSq	= 300 * 300;
	
	// if the victim is near the attacker's defend location, the attacker gets a defend bonus
	if( Distance2DSquared(victim.origin, defendLocation) < nearPortalDistSq )
	{
		awardedDefend++;
	}
	
	// if the victim is near the attacker's score location, the attacker gets the assault bonus 
	if( Distance2DSquared(victim.origin, scoreLocation) < nearPortalDistSq )
	{
		awardedAssault++;
	}
		
	// give defend rewards
	if( awardedDefend )
	{
		attacker thread maps\mp\gametypes\_hud_message::SplashNotify( "defend", maps\mp\gametypes\_rank::getScoreInfoValue( "defend" ) );
		attacker incPersStat( "defends", 1 );
		
		attacker thread maps\mp\gametypes\_rank::giveRankXP( "defend" );
		maps\mp\gametypes\_gamescore::givePlayerScore( "defend", attacker );
		
		attacker maps\mp\gametypes\_missions::processChallenge( "ch_denied" );
		
		victim thread maps\mp\_matchdata::logKillEvent( killId, "assaulting" );
	}
	
	// give attack rewards
	if( awardedAssault )
	{
		attacker thread maps\mp\gametypes\_hud_message::SplashNotify( "assault", maps\mp\gametypes\_rank::getScoreInfoValue( "assault" ) );
		
		attacker thread maps\mp\gametypes\_rank::giveRankXP( "assault" );
		maps\mp\gametypes\_gamescore::givePlayerScore( "assault", attacker );

		victim thread maps\mp\_matchdata::logKillEvent( killId, "defending" );
	}
}


//============================================
// 		 		blitzGetTeam
//============================================
blitzGetTeam( object )
{
	objectTeam = object.team;
	
	if( !IsDefined(objectTeam) )
		objectTeam = object.ownerTeam;
		
	return objectTeam;
}

//============================================
// 		 		onTimeLimit
//============================================
onTimeLimit()
{	
	// Prevent people from scoring when the timer hits 0
	level notify ( "time_ended" );
	level.finalKillCam_winner = "none";
	
	if ( game["teamScores"]["axis"] == game["teamScores"]["allies"] )
	{
		winner = "tie";	
	}
	else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
	{
		level.finalKillCam_winner = "axis";
		winner = "axis";
	}
	else
	{
		level.finalKillCam_winner = "allies";
		winner = "allies";
	}
	
	thread maps\mp\gametypes\_gamelogic::endGame( winner, game[ "end_reason" ][ "time_limit_reached" ] );
}

checkScoreLimit()
{
	if ( game["switchedsides"] )
	{
		scoreLimit = GetDvarInt("scr_blitz_scorelimit", BLITZ_SCORE_LIMIT);
		if ( GetTeamScore(self.team) == scoreLimit )
		{
		    level notify( "final_score_teleport" );
			level.finalKillCam_winner = self.team;
			
			// OP_IW6 Lockdown: shut out the enemy team
			otherteam = getOtherTeam( self.team );
			if ( scoreLimit >= BLITZ_SCORE_LIMIT
			    && GetTeamScore( otherteam ) == 0 )
			{
				maps\mp\gametypes\_missions::processChallengeForTeam( "ch_lockdown", self.team );
			}
		}
	}
	else
	{
		scoreLimit = GetDvarInt("scr_blitz_scorelimit", BLITZ_SCORE_LIMIT) / 2;
		if ( GetTeamScore(self.team) == scoreLimit )
		{
			// Manually swich over to halftime if the score limit is reached
			level notify( "halftime_score_teleport" );
			level.finalKillCam_winner = self.team;				
			thread maps\mp\gametypes\_gamelogic::endGame( "roundend", game[ "end_reason" ][ "score_limit_reached" ] );
			
			// OP_IW6 Clocking out: force half time by scoring half the score limit
			if ( scoreLimit >= BLITZ_SCORE_LIMIT / 2 )
			{
				maps\mp\gametypes\_missions::processChallengeForTeam( "ch_clocking", self.team );
			}
		}
	}
}

onSpawnPlayer()
{
	// Set variable to check if the player is currently teleporting
	self.teleporting = false;
	
	// set the extra score value for the scoreboard
	self setExtraScore0( 0 );
	if( IsDefined( self.pers[ "captures" ] ) )
		self setExtraScore0( self.pers[ "captures" ] );
}

initGametypeAwards()
{
	maps\mp\_awards::initStatAward( "pointscaptured", 0, maps\mp\_awards::highestWins );
}

/#
//============================================
// 		 		blitzDebug
//============================================
blitzDebug()
{
	setDevDvarIfUninitialized( "scr_blitzdebug", "0" );
	
	spawnPoints 		= maps\mp\gametypes\_spawnlogic::getSpawnpointArray( level.spawnNodeType );
	isPathDataAvailable = maps\mp\gametypes\_spawnlogic::isPathDataAvailable();
	heightOffsetLines 	= (0,0,12);
	heightOffsetNames 	= (0,0,64);
	
	while( true )
	{
		if( getdvar("scr_blitzdebug") != "1" ) 
		{
			wait( 1 );
			continue;
		}
		
		SetDevDvar( "scr_showspawns", "1" );
		
		while( true )
		{
			if( getdvar("scr_blitzdebug") != "1" )
			{
				SetDevDvar( "scr_showspawns", "0" );
				break;
			}
			
			if( GetDvarInt( "scr_altBlitzSpawns", 0 ) == 1 )
			{
				portalA = level.portalList["allies"];
				portalB = level.portalList["axis"];
				
				portalOriginA = portalA.origin;
				portalOriginB = portalB.origin;
				
				portalDelta = portalOriginB - portalOriginA;
				territoryPointA = portalOriginA + portalDelta * CONST_PORTAL_TERRITORY_PERCENT;
				territoryPointB = portalOriginA + portalDelta * ( 1.0 - CONST_PORTAL_TERRITORY_PERCENT );
				
				line( portalOriginA, territoryPointA, (0, 1, 0), 0, false );
				line( territoryPointA, territoryPointB, (1, 0, 0), 0, false );
				line( territoryPointB, portalOriginB, (0, 1, 0), 0, false );
			}
			
			// draw the path from each spawn point to the nearest portal
			foreach( spawnPoint in spawnPoints )
			{
				if( IsDefined( spawnPoint.teamBase ) )
				{
				if( isPathDataAvailable )
				{
					if( !IsDefined(spawnPoint.nodeArray) )
					{
						spawnPoint.nodeArray = GetNodesOnPath( spawnPoint.origin, level.portalList[spawnPoint.teamBase].origin );
					}
					
					if( !IsDefined(spawnPoint.nodeArray) || (spawnPoint.nodeArray.size == 0) )
					{
						continue;
					}
					
					line( spawnPoint.origin + heightOffsetLines, spawnPoint.nodeArray[0].origin + heightOffsetLines, (0.2, 0.2, 0.6) );
					
					for( i = 0; i <  spawnPoint.nodeArray.size - 1; i++ )
					{
						line( spawnPoint.nodeArray[i].origin + heightOffsetLines, spawnPoint.nodeArray[i+1].origin + heightOffsetLines, (0.2, 0.2, 0.6) );
					}
				}
				else
				{
					line( level.portalList[spawnPoint.teamBase].origin + heightOffsetLines, spawnPoint.origin + heightOffsetLines, (0.2, 0.2, 0.6) );
				}
			}
			}
			
			foreach( portal in level.portalList )
			{
				if ( portal.ownerTeam == "allies" )
					print3d( portal.origin + heightOffsetNames, "allies portal" );
				
				if ( portal.ownerTeam == "axis" )
					print3d( portal.origin + heightOffsetNames, "axis portal" );
			}
			
			waitframe();
		}
	}
}
#/
