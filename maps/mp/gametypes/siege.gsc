#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\agents\_agent_utility;
/*
	Reinforce
	Objective: 	Capture enemy flags, revive teammates with each capture.  Capture all flags to win the round.
	Map ends:	When the score limit is reached
	Respawning:	No wait / Near teammates

	Level requirements
	------------------
		Spawnpoints:
			classname		mp_dom_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of owned flags, teammates and 
			enemies at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies.

		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.

		Flags:
			classname       trigger_radius
			targetname      flag_primary or flag_secondary
			Flags that need to be captured to win. Primary flags take time to capture; secondary flags are instant.
*/

/*QUAKED mp_dom_spawn (0.5 0.5 1.0) (-16 -16 0) (16 16 72)
Players spawn near their flags at one of these positions.*/

/*QUAKED mp_dom_spawn_axis_start (1.0 0.0 1.0) (-16 -16 0) (16 16 72)
Axis players spawn away from enemies and near their team at one of these positions at the start of a round.*/

/*QUAKED mp_dom_spawn_allies_start (0.0 1.0 1.0) (-16 -16 0) (16 16 72)
Allied players spawn away from enemies and near their team at one of these positions at the start of a round.*/

CONST_FRIENDLY_TAG_MODEL = "prop_dogtags_friend_iw6";
CONST_ENEMY_TAG_MODEL	 = "prop_dogtags_foe_iw6";

OP_HELPME_NUM_TEAMMATES = 4;	// # of teammates to rescue to trigger op

CONST_DOM_TRAP_TIME = 40000;
CONST_USE_TIME		= 10;

CONST_MAX_FLAGPOS_COL = 10;

///////////////////////////////////
// Setup & Initialization
///////////////////////////////////

main()
{
	if ( GetDvar( "mapname" ) == "mp_background" )
		return;
	
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();	
	
	if ( IsUsingMatchRulesData() )
	{
		level.initializeMatchRules = ::initializeMatchRules;
		[[ level.initializeMatchRules ]]();
		level thread reInitializeMatchRulesOnMigration();	
	}
	else
	{
		registerRoundSwitchDvar( level.gameType, 3, 0, 9 );
		registerTimeLimitDvar( level.gameType, 5 );
		registerScoreLimitDvar( level.gameType, 1 );
		registerRoundLimitDvar( level.gameType, 0 );
		registerWinLimitDvar( level.gameType, 4 );
		registerNumLivesDvar( level.gameType, 1 );
		registerHalfTimeDvar( level.gameType, 0 );
		
		level.matchRules_damageMultiplier = 0;
		level.matchRules_vampirism		  = 0;
	}
	
	level.objectiveBased	 = true;
	level.teamBased			 = true;
	level.noBuddySpawns		 = true;
	level.gameHasStarted	 = false;
	level.onStartGameType	 = ::onStartGameType;
	level.getSpawnPoint		 = ::getSpawnPoint;
	level.onSpawnPlayer		 = ::onSpawnPlayer;
	level.onPlayerKilled	 = ::onPlayerKilled;
	level.onDeadEvent 		 = ::onDeadEvent;	
	level.onOneLeftEvent	 = ::onOneLeftEvent;
	level.onTimeLimit		 = ::onTimeLimit;
	level.initGametypeAwards = ::initGametypeAwards;
	
	level.lastCapTime		  = GetTime();
	level.alliesPrevFlagCount = 0;
	level.axisPrevFlagCount	  = 0;
	level.allowLateComers	  = false;
	level.gameTimerBeeps	  = false;
	
	level.siegeFlagCapturing = [];

	if ( level.matchRules_damageMultiplier || level.matchRules_vampirism )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;
	
//	game["dialog"]["gametype"] = "domination";
//
//	if ( getDvarInt( "g_hardcore" ) )
//		game["dialog"]["gametype"] = "hc_" + game["dialog"]["gametype"];
//	else if ( getDvarInt( "camera_thirdPerson" ) )
//		game["dialog"]["gametype"] = "thirdp_" + game["dialog"]["gametype"];
//	else if ( getDvarInt( "scr_diehard" ) )
//		game["dialog"]["gametype"] = "dh_" + game["dialog"]["gametype"];
//	else if (getDvarInt( "scr_" + level.gameType + "_promode" ) )
//		game["dialog"]["gametype"] = game["dialog"]["gametype"] + "_pro";

	game[ "dialog" ] [ "offense_obj" ] = "capture_objs";
	game[ "dialog" ] [ "defense_obj" ] = "capture_objs";
	
  //  game["dialog"]["lead_lost"]  = "null";
  //  game["dialog"]["lead_tied"]  = "null";
  //  game["dialog"]["lead_taken"] = "null";
	
	game[ "dialog" ][ "revived" ] = "sr_rev";
	
	self thread onPlayerConnect();
	self thread onPlayerSwitchTeam();
}

initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	//	set everything else (private match options, default .cfg file values, and what normally is registered in the 'else' below)
	roundLength = GetMatchRulesData( "siegeData", "roundLength" );
	SetDynamicDvar( "scr_siege_timelimit", roundLength );
	registerTimeLimitDvar( "siege", roundLength );	
			
	roundSwitch = GetMatchRulesData( "siegeData", "roundSwitch" );
	SetDynamicDvar( "scr_siege_roundswitch", roundSwitch );
	registerRoundSwitchDvar( "siege", roundSwitch, 0, 9 );
			
	winLimit = GetMatchRulesData( "commonOption", "scoreLimit" );
	SetDynamicDvar( "scr_siege_winlimit", winLimit );
	registerWinLimitDvar( "siege", winLimit );
	
	capRate = GetMatchRulesData( "siegeData", "capRate" );
	SetDynamicDvar( "scr_siege_caprate", capRate );	

	rushTimer = GetMatchRulesData( "siegeData", "rushTimer" );
	SetDynamicDvar( "scr_siege_rushtimer", rushTimer );

	rushTimerAmount = GetMatchRulesData( "siegeData", "rushTimerAmount" );
	SetDynamicDvar( "scr_siege_rushtimeramount", rushTimerAmount );	
	
	preCapPoints = GetMatchRulesData( "siegeData", "preCapPoints" );
	SetDynamicDvar( "scr_siege_precap", preCapPoints );
	
	SetDynamicDvar( "scr_siege_roundlimit", 0 );
	registerRoundLimitDvar( "siege", 0 );		
	SetDynamicDvar( "scr_siege_scorelimit", 1 );
	registerScoreLimitDvar( "siege", 1 );			
	SetDynamicDvar( "scr_siege_halftime", 0 );
	registerHalfTimeDvar( "siege", 0 );				
	
	SetDynamicDvar( "scr_siege_promode", 0 );	
}

onStartGameType()
{
	if ( !IsDefined( game[ "switchedsides" ] ) )
		game[ "switchedsides" ] = false;
	
	if ( game[ "switchedsides" ] )
	{
		oldAttackers		= game[ "attackers" ];
		oldDefenders		= game[ "defenders" ];
		game[ "attackers" ] = oldDefenders;
		game[ "defenders" ] = oldAttackers;
	}
	
	//"Capture and defend the flags."
	setObjectiveText( "allies", &"OBJECTIVES_DOM" );
	//"Capture and defend the flags."
	setObjectiveText( "axis", &"OBJECTIVES_DOM" );

	if ( level.splitscreen )
	{
		//"Capture and defend the flags."
		setObjectiveScoreText( "allies", &"OBJECTIVES_DOM" );
		//"Capture and defend the flags."
		setObjectiveScoreText( "axis", &"OBJECTIVES_DOM" );
	}
	else
	{
		//"Capture and defend the flags.  First team to &&1 points wins."
		setObjectiveScoreText( "allies", &"OBJECTIVES_DOM_SCORE" );
		//"Capture and defend the flags.  First team to &&1 points wins."
		setObjectiveScoreText( "axis", &"OBJECTIVES_DOM_SCORE" );
	}
	//"Capture the flags and defend them."
	setObjectiveHintText( "allies", &"OBJECTIVES_DOM_HINT" );
	//"Capture the flags and defend them."
	setObjectiveHintText( "axis", &"OBJECTIVES_DOM_HINT" );
	
	initSpawns();
	
	allowed[ 0 ] = "dom";
	maps\mp\gametypes\_gameobjects::main( allowed );
	
	level.flagBaseFXid[ "neutral" ]	 = LoadFX( "vfx/gameplay/mp/core/vfx_marker_base_grey" );
	level.flagBaseFXid[ "friendly" ] = LoadFX( "vfx/gameplay/mp/core/vfx_marker_base_cyan" );
	level.flagBaseFXid[ "enemy" ]	 = LoadFX( "vfx/gameplay/mp/core/vfx_marker_base_orange" );
	
	thread domFlags();
	thread watchFlagTimerPause();
	thread watchFlagTimerReset();
	thread watchFlagEndUse();
	thread watchGameInactive();
	thread watchGameStart();
}

initSpawns()
{
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_dom_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_dom_spawn_axis_start" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dom_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis"  , "mp_dom_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	SetMapCenter( level.mapCenter );
}

getSpawnPoint()
{
	spawnteam = self.pers[ "team" ];
	otherteam = getOtherTeam( spawnTeam );
	
	if ( level.useStartSpawns )
	{
		if ( game[ "switchedsides" ] )
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn_" + otherteam + "_start" );
			spawnPoint	= maps\mp\gametypes\_spawnlogic::getSpawnpoint_startSpawn( spawnPoints );
		}
		else
		{
			spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn_" + spawnteam + "_start" );
			spawnPoint	= maps\mp\gametypes\_spawnlogic::getSpawnpoint_startSpawn( spawnPoints );
		}
	}
	else
	{
		teamDomPoints		 = getTeamDomPoints( spawnteam );
		enemyTeam			 = getOtherTeam( spawnteam );
		enemyDomPoints		 = getTeamDomPoints( enemyTeam );
		perferdDomPointArray = getPerferedDomPoints( teamDomPoints, enemyDomPoints );
		
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( spawnteam );
		spawnPoint	= maps\mp\gametypes\_spawnscoring::getSpawnpoint_Domination( spawnPoints, perferdDomPointArray );
	}
	
	Assert( IsDefined( spawnpoint ) );
	return spawnpoint;
}

getTeamDomPoints( team )
{
	teamDomPoints = [];
	
	foreach ( domPoint in level.domFlags )
	{
		if ( domPoint.ownerTeam == team )
		{
			teamDomPoints[ teamDomPoints.size ] = domPoint;
		}
	}
	
	return teamDomPoints;
}

getPerferedDomPoints( teamDomPoints, enemyDomPoints )
{
	perferdDomPointArray	  = [];
	perferdDomPointArray[ 0 ] = false; //dom point A
	perferdDomPointArray[ 1 ] = false; //dom point B
	perferdDomPointArray[ 2 ] = false; //dom point C
	
	// the player's team owns all the dom points
	self_pers_team = self.pers[ "team" ];
	if ( teamDomPoints.size == level.domFlags.size )
	{
		myTeam		  = self_pers_team;
		bestFlagPoint = level.bestSpawnFlag[ self_pers_team ];
		
		// pefer a spawn point near the first dom point the player's team captured
		perferdDomPointArray[ bestFlagPoint.useObj.domPointNumber ] = true;
		return perferdDomPointArray;
	}		
	
	if ( teamDomPoints.size > 0 )
	{
		// prefer spawn locations near dom points the player's team owns
		foreach ( domPoint in teamDomPoints )
		{
			perferdDomPointArray[ domPoint.domPointNumber ] = true;
		}
		
		return perferdDomPointArray;
	}

	// the player's team owns zero flags
	if ( teamDomPoints.size == 0 )
	{
		// pefer a spawn point near the first dom point the player's team captured
		myTeam		  = self_pers_team;
		bestFlagPoint = level.bestSpawnFlag[ myTeam ];
		
		// the enemy does not own all the flags
		if ( ( enemyDomPoints.size > 0 ) && ( enemyDomPoints.size < level.domFlags.size ) )
		{
			// perfer a spawn point near the uncapture dom locations
			bestFlagPoint				  = getUnownedFlagNearestStart( myTeam, undefined );
			level.bestSpawnFlag[ myTeam ] = bestFlagPoint;
		}
		
		perferdDomPointArray[ bestFlagPoint.useObj.domPointNumber ] = true;
		return perferdDomPointArray;
	}
	
	return perferdDomPointArray;
}

getTimeSinceDomPointCapture( domPoint )
{
	return ( GetTime() - domPoint.captureTime );
}

onPlayerConnect()
{
	while ( true )
	{
		level waittill( "connected", player );
		
		player._domFlagEffect = [];
		
		player thread onPlayerDisconnect();
		player thread refreshFreecamBaseFX();
		
		player.siegeLateComer = true;
	}
}

onPlayerSwitchTeam()
{
	level endon( "game_ended" );
	
	while ( true )
	{
		level waittill ( "joined_team", player );
		
		// This is really just for private match
		// When players switch teams, they need to be labeled as a late comer, so they are correctly handled in the spawning logic
		if ( gameHasStarted() )
			player.siegeLateComer = true;
	}
}

onSpawnPlayer()
{
	// set the extra score value for the scoreboard
	self setExtraScore0( 0 );
	if( IsDefined( self.pers[ "captures" ] ) )
		self setExtraScore0( self.pers[ "captures" ] );

	level notify ( "spawned_player" );
}

onPlayerDisconnect()	// self == player
{
	self waittill ( "disconnect" );
	
	foreach ( effect in self._domFlagEffect )
	{
		if ( IsDefined( effect ) )
			effect Delete();
	}
}

checkAllowSpectating()
{
	wait ( 0.05 );
	
	update = false;
	if ( !level.aliveCount[ game[ "attackers" ] ] )
	{
		level.spectateOverride[ game[ "attackers" ]].allowEnemySpectate = 1;
		update = true;
	}
	if ( !level.aliveCount[ game[ "defenders" ] ] )
	{
		level.spectateOverride[ game[ "defenders" ]].allowEnemySpectate = 1;
		update = true;
	}
	if ( update )
		maps\mp\gametypes\_spectating::updateSpectateSettings();
}

initGametypeAwards()
{
//	maps\mp\_awards::initStatAward( "targetsdestroyed", 	0, maps\mp\_awards::highestWins );
//	maps\mp\_awards::initStatAward( "bombsplanted", 		0, maps\mp\_awards::highestWins );
//	maps\mp\_awards::initStatAward( "bombsdefused", 		0, maps\mp\_awards::highestWins );
//	maps\mp\_awards::initStatAward( "bombcarrierkills", 	0, maps\mp\_awards::highestWins );
//	maps\mp\_awards::initStatAward( "bombscarried", 		0, maps\mp\_awards::highestWins );
//	maps\mp\_awards::initStatAward( "killsasbombcarrier", 	0, maps\mp\_awards::highestWins );
	maps\mp\_awards::initStatAward( "pointscaptured", 0, maps\mp\_awards::highestWins );	
}

updateGameTypeDvars()
{
  //  level.plantTime  = dvarFloatValue( "planttime", 5, 0, 20 );
  //  level.defuseTime = dvarFloatValue( "defusetime", 5, 0, 20 );
  //  level.bombTimer  = dvarFloatValue( "bombtimer", 45, 1, 300 );
  //  level.multiBomb  = dvarIntValue( "multibomb", 0, 0, 1 );
}

///////////////////////////////////
// Game Mode Logic
///////////////////////////////////

domFlags()
{
	level endon ( "game_ended" );
	
	level.lastStatus[ "allies" ] = 0;
	level.lastStatus[ "axis"   ] = 0;
	
	game[ "flagmodels" ]			  = [];
	game[ "flagmodels" ][ "neutral" ] = "prop_flag_neutral";

	game[ "flagmodels" ][ "allies" ] = maps\mp\gametypes\_teams::getTeamFlagModel( "allies" );
	game[ "flagmodels" ][ "axis" ]	 = maps\mp\gametypes\_teams::getTeamFlagModel( "axis" );
	
	primaryFlags   = GetEntArray( "flag_primary", "targetname" );
	secondaryFlags = GetEntArray( "flag_secondary", "targetname" );
	
	if ( ( primaryFlags.size + secondaryFlags.size ) < 2 )
	{
		AssertMsg( "^1Not enough domination flags found in level!" );
		return;
	}
	
	level.flags = [];
	
	// Set new flag positions
	filename   = "mp/siegeFlagPos.csv";
	currentMap = getMapName();
	searchCol  = 1;
		
	for ( returnCol = 2; returnCol < CONST_MAX_FLAGPOS_COL + 1; returnCol++ )
	{
		returnValue = TableLookup( filename, searchCol, currentMap, returnCol );
		
		if ( returnValue != "" )
			setFlagPositions( returnCol, Float( returnValue ) );
	}
	
	for ( index = 0; index < primaryFlags.size; index++ )
		level.flags[ level.flags.size ] = primaryFlags[ index ];
	
	for ( index = 0; index < secondaryFlags.size; index++ )
		level.flags[ level.flags.size ] = secondaryFlags[ index ];
	
	level.domFlags = [];
	for ( index = 0; index < level.flags.size; index++ )
	{
		trigger = level.flags[ index ];

		trigger.origin = getFlagPos( trigger.script_label, trigger.origin );
		
		if ( IsDefined( trigger.target ) )
		{
			visuals[ 0 ] = GetEnt( trigger.target, "targetname" );
		}
		else
		{
			visuals[ 0 ]		= Spawn( "script_model", trigger.origin );
			visuals[ 0 ].angles = trigger.angles;
		}

		domFlag = maps\mp\gametypes\_gameobjects::createUseObject( "neutral", trigger, visuals, ( 0, 0, 100 ) );
		domFlag maps\mp\gametypes\_gameobjects::allowUse( "enemy" );
		domFlag maps\mp\gametypes\_gameobjects::setUseTime( GetDvarFloat( "scr_siege_caprate" ) );
		//"Securing Position"
		domFlag maps\mp\gametypes\_gameobjects::setUseText( &"MP_SECURING_POSITION" );
		label		  = domFlag maps\mp\gametypes\_gameobjects::getLabel();
		domFlag.label = label;
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_defend" + label );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + label );
		domFlag maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_captureneutral" + label );
		domFlag maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_captureneutral" + label );
		domFlag maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
		domFlag.onUse		   = ::onUse;
		domFlag.onBeginUse	   = ::onBeginUse;
		domFlag.onUseUpdate	   = ::onUseUpdate;
		domFlag.onEndUse	   = ::onEndUse;
		domFlag.noUseBar	   = true;
		domFlag.id			   = "domFlag";
		domFlag.firstCapture   = true;
		domFlag.prevTeam	   = "neutral";
		domFlag.flagCapSuccess = false;

		traceStart = visuals[ 0 ].origin + ( 0, 0, 32 );
		traceEnd   = visuals[ 0 ].origin + ( 0, 0, -32 );
		trace	   = BulletTrace( traceStart, traceEnd, false, undefined );
		
		domFlag.baseEffectPos	  = trace[ "position" ];
		upangles				  = VectorToAngles( trace[ "normal" ] );
		domFlag.baseeffectforward = AnglesToForward( upangles );
		
		domFlag thread setFlagNeutral();
	
		level.flags[ index ].useObj = domFlag;
		domFlag.levelFlag			= level.flags[ index ];
		
		level.domFlags[ level.domFlags.size ] = domFlag;
	}
	
	spawn_axis_start		   = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn_axis_start" );
	spawn_allies_start		   = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn_allies_start" );
	level.startPos[ "allies" ] = spawn_allies_start[ 0 ] .origin;
	level.startPos[ "axis"	 ] = spawn_axis_start  [ 0 ] .origin;
	
	// level.bestSpawnFlag is used as a last resort when the enemy holds all flags.
	level.bestSpawnFlag				= [];
	level.bestSpawnFlag[ "allies" ] = getUnownedFlagNearestStart( "allies", undefined );
	level.bestSpawnFlag[ "axis" ]	= getUnownedFlagNearestStart( "axis", level.bestSpawnFlag[ "allies" ] );
	
	if ( GetDvarInt( "scr_siege_precap" ) )
	{
		storeCenterFlag();
		
		excludedFlags						= [];
		excludedFlags[ excludedFlags.size ] = level.centerFlag;
		
		if ( game[ "switchedsides" ] )
		{
			level.closestAlliesFlag				= getUnownedFlagNearestStart( "axis", level.centerFlag );
			excludedFlags[ excludedFlags.size ] = level.closestAlliesFlag;
			
			level.closestAxisFlag = getUnownedFlagNearestStart( "allies", excludedFlags );
		}
		else
		{		
			level.closestAlliesFlag				= getUnownedFlagNearestStart( "allies", level.centerFlag );
			excludedFlags[ excludedFlags.size ] = level.closestAlliesFlag;
						
			level.closestAxisFlag = getUnownedFlagNearestStart( "axis", excludedFlags );
		}
	
		level.closestAlliesFlag.useobj setFlagCaptured( "allies", "neutral", undefined, true );
		level.closestAxisFlag.useobj setFlagCaptured( "axis", "neutral", undefined, true );	
	}

	flagSetup();
}

setFlagPositions( col, posValue )
{
	switch ( col )
	{
		// A 
		case 2:
			level.siege_A_XPos = posValue;
			break;
		case 3:
			level.siege_A_YPos = posValue;	
			break;
		case 4:
			level.siege_A_ZPos = posValue;	
			break;
		
		// B			
		case 5:
			level.siege_B_XPos = posValue;
			break;			
		case 6:
			level.siege_B_YPos = posValue;
			break;
		case 7:
			level.siege_B_ZPos = posValue;
			break;
			
		// C
		case 8:
			level.siege_C_XPos = posValue;
			break;
		case 9:
			level.siege_C_YPos = posValue;
			break;
		case 10:
			level.siege_C_ZPos = posValue;	
			break;
	}
}

getFlagPos( flagLabel, flagOrigin )
{
	// If any values are empty/undefined, just use the original vector
	// This should allow us to customize which flags we want to move, and which should stay in place
	
	returnOrigin = flagOrigin;
	
	if ( flagLabel == "_a" )
	{
		if ( IsDefined( level.siege_A_XPos ) && IsDefined( level.siege_A_YPos ) && IsDefined( level.siege_A_ZPos ) )
			returnOrigin = ( level.siege_A_XPos, level.siege_A_YPos, level.siege_A_ZPos );
	}
	else if ( flagLabel == "_b" )
	{
		if ( IsDefined( level.siege_B_XPos ) && IsDefined( level.siege_B_YPos ) && IsDefined( level.siege_B_ZPos ) )
			returnOrigin = ( level.siege_B_XPos, level.siege_B_YPos, level.siege_B_ZPos );	
	}
	else
	{
		if ( IsDefined( level.siege_C_XPos ) && IsDefined( level.siege_C_YPos ) && IsDefined( level.siege_C_ZPos ) )
			returnOrigin = ( level.siege_C_XPos, level.siege_C_YPos, level.siege_C_ZPos );			
	}
	
	return returnOrigin;
}

storeCenterFlag()
{
	bestcentersq = undefined;
	
	foreach ( flag in level.flags )
	{
		if ( flag.script_label == "_b" )
			level.centerFlag = flag;
	}
}

watchFlagTimerPause()
{
	level endon ( "game_ended" );
	
	while ( true )
	{
		level waittill ( "flag_capturing", flag );

		if ( GetDvarInt( "scr_siege_rushtimer" ) )
		{	
			capturingTeam = getOtherTeam ( flag.prevTeam );
			
			// Pause the timer
			if ( flag.prevTeam != "neutral" && ( IsDefined ( level.siegeTimerState ) && level.siegeTimerState != "pause" ) && !isWinningTeam( capturingTeam ) )
			{
				level.gameTimerBeeps  = false;
				level.siegeTimerState = "pause";
				pauseCountdownTimer();
				
				if ( !flagOwnersAlive( flag.prevTeam ) )
					setWinner( capturingTeam, flag.prevTeam + "_eliminated" );
			}
		}
	}
}

isWinningTeam( team )
{
	isWinning = false;
	
	teamFlags = getFlagCount( team );
	
	if ( teamFlags == 2 )
		isWinning = true;
	
	return isWinning;
}

flagOwnersAlive( team )
{
	ownersAlive = false;

	foreach ( player in level.participants )
	{
		// See if the flag owners have at least one person still alive
		if ( IsDefined( player ) && player.team == team && ( isReallyAlive( player ) || player.pers["lives"] > 0 ) )
		{
		 	ownersAlive = true;
			break;
		}
	}
	
	return ownersAlive;
}

pauseCountdownTimer()
{
	// Pause the timer
	SetGameEndTime( 0 );
	
	// Show all players the paused timer text
	foreach ( player in level.players )
	{
		player SetClientOmnvar( "ui_bomb_timer", 5 );
	}
	
	level notify ( "siege_timer_paused" );
}

watchFlagTimerReset()
{
	level endon ( "game_ended" );
	
	while ( true )
	{
		level waittill ( "start_flag_captured", flag );

		// We only want to reset if the Rush Timer has already been started
		if ( GetDvarInt( "scr_siege_rushtimer" ) )
		{
			// We also want to check if the flag not neutral, since we want to keep the timer running
			if ( IsDefined( level.siegeTimerState ) && level.siegeTimerState != "reset" )
			{		
				// Clear any remaining time since we are resetting
				level.gameTimerBeeps  = false;
				level.siegeTimeLeft	  = undefined;
				level.siegeTimerState = "reset";
				notifyPlayers( "siege_timer_reset" );		
			}
		}
		
		level notify ( "flag_end_use", flag );			
	}
}

watchFlagEndUse()
{
	level endon ( "game_ended" );
	
	while ( true )
	{
		alliesFlags = 0;
		axisFlags	= 0;
	
		level waittill ( "flag_end_use", flag );
		
		// Tally up on the number of current capped flags
		alliesFlags = getFlagCount( "allies" );
		axisFlags	= getFlagCount( "axis" );
		
		// Start the rush timer		
		if ( alliesFlags == 2 || axisFlags == 2 )
		{
			// The logic below should happen when the timer has yet to start, when the flag fails to capture, or when the timer is reset
			if ( GetDvarInt( "scr_siege_rushtimer" ) )
			{	
				// We also need to make sure that no one is currently capturing a flag
				// The reason for this is if both teams capture different flags at about the same time, it will send a false positive and continue the timer, even though someone is still capturing
				if ( level.siegeFlagCapturing.size == 0 && ( !flag.flagCapSuccess || !IsDefined( level.siegeTimerState ) || level.siegeTimerState != "start" ) )
				{
					// Grab the default Rush Timer
					siegeRushTimer = GetDvarFloat( "scr_siege_rushtimeramount" );
						
					// If there was time from the previous timer, continue from there
					if ( IsDefined( level.siegeTimeLeft ) )
						siegeRushTimer = level.siegeTimeLeft;
					
					gameOverTime = Int( GetTime() + siegeRushTimer * 1000 );
					
					// Clear the current timer, and overwrite it
					foreach ( player in level.players )
					{
						player SetClientOmnvar( "ui_bomb_timer", 0 );
					}				
					
					level.timeLimitOverride = true;				
					maps\mp\gametypes\_gamelogic::pauseTimer();
					SetGameEndTime( gameOverTime );
			
					// We don't want to keep notifying the player unless it's needed
					if ( !IsDefined( level.siegeTimerState ) || level.siegeTimerState == "pause" )
					{
						level.siegeTimerState = "start";
						notifyPlayers( "siege_timer_start" );
					}
					
					// Keep track of the passing time on my own
					if ( !level.gameTimerBeeps )
						thread watchGameTimer( siegeRushTimer );
				}
			}
		}
		else if ( alliesFlags == 3 )
			setWinner( "allies", "score_limit_reached" );
		else if ( axisFlags == 3 )
			setWinner( "axis", "score_limit_reached" );
		
		flag.prevTeam = flag.ownerTeam;
	}
}

watchGameInactive()
{
	level endon ( "game_ended" );
	level endon ( "flag_capturing" );

	timeLimit = GetDvarFloat( "scr_siege_timelimit" );
	
	if ( timeLimit > 0 )
	{
		// If for some reason the game remains inactive for the entire round, force end the game.
		inactiveTime = ( timeLimit * 60 ) - 1;
		
		while ( inactiveTime > 0 )
		{	
			inactiveTime -= 1;		
			wait ( 1 );
		}
	
		level.siegeGameInactive = true;
	}
}

watchGameStart()
{
	level endon ( "game_ended" );
	
	gameFlagWait( "prematch_done" );
	
	// We are doing this to counter a rare occurrence that happens when disconnecting from a game
	// UpdateGameEvents fires off, which may trigger the onOneLeftEvent even before the game has fully started (causing a SRE due to certain players not having a valid team yet)
	// This happens because level.inGracePeriod is being set to false when ending the game, allowing the game to run this function even when it isn't supposed to
	while ( !haveSpawnedPlayers() )
	{
		waitframe();
	}
	
	level.gameHasStarted = true;
}

haveSpawnedPlayers()
{
	if( level.teamBased )
		return( level.hasSpawned[ "axis" ] && level.hasSpawned[ "allies" ] );
	
	return( level.maxPlayerCount > 1 );	
}

watchGameTimer( gameTime )
{
	level endon ( "game_ended" );
	level endon ( "siege_timer_paused" );
	level endon ( "siege_timer_reset" );
	
	remainingTime = gameTime;
	clockObject	  = Spawn( "script_origin", ( 0, 0, 0 ) );
	clockObject Hide();	
	
	level.gameTimerBeeps = true;
	
	while ( remainingTime > 0 )
	{
		remainingTime -= 1;
		level.siegeTimeLeft = remainingTime;

		if ( remainingTime <= 30 )
		{
			// don't play a tick at exactly 0 seconds, that's when something should be happening!
			if ( remainingTime != 0 )
				clockObject PlaySound( "ui_mp_timer_countdown" );
		}		
		
		wait ( 1 );
	}	

	onTimeLimit();
}

getFlagCount( team )
{
	teamFlags = 0;
	
	foreach ( flag in level.domFlags )
	{
		if ( flag.ownerTeam == team && !isBeingCaptured( flag ) )
			teamFlags += 1;
	}
	
	return teamFlags;
}

isBeingCaptured( flag )
{
	// self == player capping flag
	cappingFlag = false;
	
	if ( IsDefined( flag ) )
	{	
		if ( level.siegeFlagCapturing.size > 0 )
		{
			foreach ( flagLabel in level.siegeFlagCapturing )
			{
				if ( flag.label == flagLabel )
					cappingFlag = true;
			}
		}
	}

	return cappingFlag;
}

setWinner( team, reason )
{
	if ( team != "tie" )
		level.finalKillCam_winner = team;		
	else
		level.finalKillCam_winner = "none";	
	
	foreach( player in level.players )
	{
		if( !IsAI( player ) )
		{
			player SetClientOmnvar( "ui_dom_securing", 0 );
			player SetClientOmnvar( "ui_bomb_timer", 0 );
		}
	}

	thread maps\mp\gametypes\_gamelogic::endGame( team, game[ "end_reason" ][ reason ] );	
}

onBeginUse( player )
{
	ownerTeam			 = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	self.didStatusNotify = false;
	
	self maps\mp\gametypes\_gameobjects::setUseTime( GetDvarFloat( "scr_siege_caprate" ) );
	
	// Store flags being captured
	level.siegeFlagCapturing[ level.siegeFlagCapturing.size ] = self.label;
	
	level notify ( "flag_capturing", self );
}

onUse( credit_player )
{		
	team	= credit_player.team;
	oldTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	
	self.captureTime = GetTime();
	
	setFlagCaptured( team, oldTeam, credit_player );
	
	level.useStartSpawns = false;
	
	if ( oldTeam == "neutral" )
	{
		otherTeam = getOtherTeam( team );
		thread printAndSoundOnEveryone( team, otherTeam, undefined, undefined, "mp_dom_flag_captured", undefined, credit_player );
		
		if ( getTeamFlagCount( team ) < level.flags.size )
		{
			//   dialog 				     team 	    forceDialog  
			statusDialog( "secured" + self.label, team , true );
			statusDialog( "enemy_has" + self.label, otherTeam, true );
		}
	}
	
	credit_player maps\mp\_events::giveObjectivePointStreaks(); 
	self thread giveFlagCaptureXP( self.touchList[ team ] );
}

onUseUpdate( team, progress, change )
{
	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	if ( progress > 0.05 && change && !self.didStatusNotify )
	{
		if ( ownerTeam == "neutral" )
		{
			statusDialog( "securing" + self.label, team );
			self.prevOwnerTeam = getOtherTeam( team );
		}
		else
		{
			// force the losing dialog because it gets lost a lot in the other chatter
			statusDialog( "losing" + self.label, ownerTeam, true );
			statusDialog( "securing" + self.label, team );
		}
		
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_taking" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_taking" + self.label );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_losing" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_losing" + self.label );

		self.didStatusNotify = true;
	}
}

onEndUse( team, player, success )
{
	if ( IsPlayer( player ) )
	{
		player SetClientOmnvar( "ui_dom_securing", 0 );
		player.ui_dom_securing = undefined;
	}

	if ( success )
	{
		self.flagCapSuccess = true;
		level notify ( "start_flag_captured", self );
	}
	else
	{
		self.flagCapSuccess = false;
		level notify ( "flag_end_use", self );
	}

	ownerTeam = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	if ( ownerTeam != "neutral" )
	{
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_capture" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + self.label );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_defend" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + self.label );
	}
	else
	{
		self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_captureneutral" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_captureneutral" + self.label );
		self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_captureneutral" + self.label );
		self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_captureneutral" + self.label );
	}

	level.siegeFlagCapturing = array_remove( level.siegeFlagCapturing, self.label );
}

onReset()
{
}

getUnownedFlagNearestStart( team, excludeFlag )
{
	best	   = undefined;
	bestdistsq = undefined;
	flagObj	   = undefined;
	
	foreach ( flag in level.flags )
	{	
		if ( flag.useObj getFlagTeam() != "neutral" )
			continue;

		distsq = DistanceSquared( flag.origin, level.startPos[ team ] );	
		
		// Check to see if this flag should be excluded from the search
		if ( IsDefined( excludeFlag ) )
		{
			if ( !isFlagExcluded( flag, excludeFlag ) && ( !IsDefined( best ) || distsq < bestdistsq ) )
			{		
				bestdistsq = distsq;
				best	   = flag;
			}					
		}
		else	
		{
			// If there are no exluded flags go ahead and see if this is the best one
			if ( ( !IsDefined( best ) || distsq < bestdistsq ) )
			{
				bestdistsq = distsq;
				best	   = flag;
			}
		}				
	}
	return best;
}

isFlagExcluded( flagToCheck, excludeFlag )
{
	excluded = false;

	if ( IsArray( excludeFlag ) )
	{
		foreach ( flag in excludeFlag )
		{
			if ( flagToCheck == flag )
			{
				excluded = true;
				break;
			}	
		}
	}
	else
	{
		if ( flagToCheck == excludeFlag )
			excluded = true;
	}
	
	return excluded;
}

onDeadEvent( team )
{
	if ( gameHasStarted() )
	{
		if ( team == "all" )
		{
			onTimeLimit();
		}
		else if ( team == game["attackers"] )
		{	
			if ( getFlagCount( team ) == 2 )
				return;
			
			setWinner( game["defenders"], game[ "attackers" ]+"_eliminated" );
		}
		else if ( team == game["defenders"] )
		{
			if ( getFlagCount( team ) == 2 )
				return;
			
			setWinner( game["attackers"], game[ "defenders" ]+"_eliminated" );
		}
	}
}

onOneLeftEvent( team )
{
	lastPlayer = getLastLivingPlayer( team );

	lastPlayer thread giveLastOnTeamWarning();
}

onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, killId )
{
	if ( !IsPlayer( attacker ) || attacker.team == self.team )
		return;

	awardedAssault = false;
	awardedDefend  = false;

	victim = self;

	foreach ( trigger in victim.touchTriggers )
	{
		if ( trigger != level.flags[ 0 ]  &&
			trigger != level.flags[ 1 ]  &&
			trigger != level.flags[ 2 ] )
			continue;
		
		ownerTeam  = trigger.useObj.ownerTeam;
		victimTeam = victim.team;

		if ( ownerTeam == "neutral" )
			continue;
		
		// if the victim owns the flag and is touching the flag when killed, then the attacker gets the assault medal
		if ( victimTeam == ownerTeam )
		{
			awardedAssault = true;
			attacker thread maps\mp\gametypes\_hud_message::splashNotify( "assault", maps\mp\gametypes\_rank::getScoreInfoValue( "assault" ) );
			attacker thread maps\mp\gametypes\_rank::giveRankXP( "assault" );
			maps\mp\gametypes\_gamescore::givePlayerScore( "assault", attacker );

			thread maps\mp\_matchdata::logKillEvent( killId, "defending" );
		}
		// if the victim doesn't own the flag and is touching the flag when killed, then the attacker gets the defend medal
		else
		{
			awardedDefend = true;
			attacker thread maps\mp\gametypes\_hud_message::splashNotify( "defend", maps\mp\gametypes\_rank::getScoreInfoValue( "defend" ) );
			attacker thread maps\mp\gametypes\_rank::giveRankXP( "defend" );
			maps\mp\gametypes\_gamescore::givePlayerScore( "defend", attacker );

			attacker incPersStat( "defends", 1 );
			attacker maps\mp\gametypes\_persistence::statSetChild( "round", "defends", attacker.pers[ "defends" ] );
			
			// OP_IW6 Domination Protector - defend a dom flag
			attacker maps\mp\gametypes\_missions::processChallenge( "ch_domprotector" );

			thread maps\mp\_matchdata::logKillEvent( killId, "assaulting" );
		}
	}

	foreach ( trigger in attacker.touchTriggers )
	{
		if ( trigger != level.flags[ 0 ]  &&
			trigger != level.flags[ 1 ]  &&
			trigger != level.flags[ 2 ] )
			continue;
		
		ownerTeam	 = trigger.useObj.ownerTeam;
		attackerTeam = attacker.team;
		
		if ( ownerTeam == "neutral" )
			continue;
		
		// if the attacker doesn't own the flag and is touching the flag when killing the victim, then the attacker gets an assault medal
		if ( attackerTeam != ownerTeam )
		{
			if ( !awardedAssault )
				attacker thread maps\mp\gametypes\_hud_message::splashNotify( "assault", maps\mp\gametypes\_rank::getScoreInfoValue( "assault" ) );
			attacker thread maps\mp\gametypes\_rank::giveRankXP( "assault" );
			maps\mp\gametypes\_gamescore::givePlayerScore( "assault", attacker );		

			thread maps\mp\_matchdata::logKillEvent( killId, "defending" );
		}
	}

	// now if the attacker kills the victim within a radius of a flag that the attacker owns, the attacker gets a defend medal
	foreach ( trigger in level.flags )
	{
		ownerTeam	 = trigger.useObj.ownerTeam;
		attackerTeam = attacker.team;
		
		victimDistanceToFlag = DistanceSquared( trigger.origin, victim.origin );
		defendDistance		 = 300 * 300;

		if ( attackerTeam == ownerTeam && victimDistanceToFlag < defendDistance )
		{
			if ( !awardedDefend )
				attacker thread maps\mp\gametypes\_hud_message::splashNotify( "defend", maps\mp\gametypes\_rank::getScoreInfoValue( "defend" ) );
			attacker thread maps\mp\gametypes\_rank::giveRankXP( "defend" );
			maps\mp\gametypes\_gamescore::givePlayerScore( "defend", attacker );
			
			attacker incPersStat( "defends", 1 );
			attacker maps\mp\gametypes\_persistence::statSetChild( "round", "defends", attacker.pers[ "defends" ] );

			thread maps\mp\_matchdata::logKillEvent( killId, "assaulting" );
		}
	}
}

giveLastOnTeamWarning()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
		
	self waitTillRecoveredHealth( 3 );
	
	otherTeam = getOtherTeam( self.pers[ "team" ] );
								   //   splash 						   owner    team 			    
	level thread teamPlayerCardSplash( "callout_lastteammemberalive", self	 , self.pers[ "team" ] );
	level thread teamPlayerCardSplash( "callout_lastenemyalive"		, self	 , otherTeam );
	level notify ( "last_alive", self );	
	self maps\mp\gametypes\_missions::lastManSD();
}

onTimeLimit()
{
	if ( IsDefined( level.siegeGameInactive ) )
		level thread maps\mp\gametypes\_gamelogic::forceEnd();		
	else
	{
		alliesFlags = getFlagCount( "allies" );
		axisFlags	= getFlagCount( "axis" );
		
		if ( alliesFlags > axisFlags )
			setWinner( "allies", "time_limit_reached" );
		else if ( axisFlags > alliesFlags )
			setWinner( "axis", "time_limit_reached" );
		else
			setWinner( "tie", "time_limit_reached" );
	}	
}

statusDialog( dialog, team, forceDialog )
{
	time = GetTime();
	
	if ( GetTime() < level.lastStatus[ team ] + 5000 && ( !IsDefined( forceDialog ) || !forceDialog ) )
		return;
		
	thread delayedLeaderDialog( dialog, team );
	level.lastStatus[ team ] = GetTime();	
}

delayedLeaderDialog( sound, team )
{
	level endon ( "game_ended" );
	wait 0.1;
	WaitTillSlowProcessAllowed();
	
	leaderDialog( sound, team );
}

teamRespawn( team, credit_player )
{
	foreach ( player in level.participants )
	{
		// Checking to see:
		// --------------------------------------------------
		// If they are part of the team that is reviving
		// If they are alive
		// If they have not been added to the alive count for that team ( which may happen if the team captures multiple flags at once )
		// If they have a valid class.  Initially checked to see if the player.class was defined, but it's possible that a class could be empty and defined
		// So now we are checking to see if the player is waiting to select a class
		// We are also checking to see if the variable is defined, because after a round switch players will automatically spawn in, which bypasses where the variable is created		
		if ( IsDefined( player ) && player.team == team && !isReallyAlive( player ) && !array_contains( level.alive_players[ player.team ], player ) && ( !IsDefined( player.waitingToSelectClass ) || !player.waitingToSelectClass ) )
		{	
			// Make sure we turn this flag off for late comers, so playerlogic will know to make an exception, and let this player spawn in
			if ( IsDefined ( player.siegeLateComer ) && player.siegeLateComer )
				player.siegeLateComer = false;
			
			// Need to count this player as alive immediately, because they can wait to spawn whenever they want.  If we don't increment this until they become alive,
			// then things get screwed up when level.aliveCount becomes 1.  The game thinks that there's only one player left alive, and yet there are multiple players
			// on the team with self.pers["lives"] greater than 0.
			player maps\mp\gametypes\_playerlogic::incrementAliveCount( player.team );
			player.alreadyAddedToAliveCount = true;
			
			player thread waiTillCanSpawnClient();
			
			player thread maps\mp\gametypes\_hud_message::splashNotify( "sr_respawned" );
			level notify( "sr_player_respawned", player );
			player leaderDialogOnPlayer( "revived" );			
			
			// OP_IW6 Rescuer - rescue X teammates
			credit_player maps\mp\gametypes\_missions::processChallenge( "ch_rescuer" );
			
			// OP_IW6 Help Me
			if ( !IsDefined( credit_player.rescuedPlayers ) )
			{
				credit_player.rescuedPlayers = [];
			}
			credit_player.rescuedPlayers[ player.guid ] = true;
			
			if ( credit_player.rescuedPlayers.size == OP_HELPME_NUM_TEAMMATES )
			{
				credit_player maps\mp\gametypes\_missions::processChallenge( "ch_helpme" );
			}
		}
	}
}

// Update: ESU - 7/15/2014
// - The SRE that is happening ( where the player is getting counted alive multiple times ) is caused by the function below
// - The problem was that waittillspawnclient was not ending correctly
// - Normally, even though it would continously call spawnClient, it would end since the player would spawn before the next call
// - However in the case where several players spawn on the same frame this starts to cause an issue where it will incementally wait longer and longer depending on how many people are in "queue"
// - This causes the waittillspawnclient to keep running, calling spawnClient for the same player multiple times, causing this SRE
// - To solve this, I added in an endon that is notified when the spawnPlayer function is run, so this function will end correctly
waiTillCanSpawnClient()
{
	self endon ( "started_spawnPlayer" );
	
	for ( ;; )
	{
		wait ( 0.05 );
		if ( IsDefined( self ) && ( self.sessionstate == "spectator" || !isReallyAlive( self ) ) )
		{
			self.pers[ "lives" ] = 1;
			self maps\mp\gametypes\_playerlogic::spawnClient();
			
			//we need to continue here because spawn client can fail for up to 3 server frames in this instance
			continue;
		}
		
		//player either disconnected or has spawned
		return;
	}
}

notifyPlayers( notifyString )
{	
	foreach ( player in level.players )
	{
		player thread maps\mp\gametypes\_hud_message::splashNotify( notifyString );
	}
	
	//TODO: Player times almost up audio
	level notify ( "match_ending_soon", "time" );
	level notify ( notifyString );
}

resetFlagBaseEffect()
{
	team = self maps\mp\gametypes\_gameobjects::getOwnerTeam();
	if ( team == "neutral" )
	{
		playFlagNeutralFX();
	}
	else
	{
		Assert( team == "axis" || team == "allies" );
		foreach ( player in level.players )
		{
			showCapturedBaseEffectToPlayer( team, player );
		}
	}
}

refreshFreecamBaseFX()
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );	
	
	while ( true )
	{
		self waittill ( "luinotifyserver", channel, view );
		if ( channel == "mlg_view_change" )
		{
			foreach ( domFlag in level.domFlags )
			{
				if ( domFlag.ownerTeam != "neutral" )
				{
					domFlag showCapturedBaseEffectToPlayer( domFlag.ownerTeam, self );
				}
			}
		}
	}
}

showCapturedBaseEffectToPlayer( team, player )
{
	if ( IsDefined( player._domFlagEffect[ self.label ] ) )
		player._domFlagEffect[ self.label ] Delete();
	
	effect = undefined;
	
	viewerTeam = player.team;
	isMLG	   = player IsMLGSpectator();
	if ( isMLG )
		viewerTeam = player GetMLGSpectatorTeam();
	else if ( viewerTeam == "spectator" )
		viewerTeam = "allies";
	
	if ( viewerTeam == team )
	{
		effect = SpawnFXForClient( level.flagBaseFXid[ "friendly" ], self.baseEffectPos, player, self.baseEffectForward );
	}
	else
	{
		effect = SpawnFXForClient( level.flagBaseFXid[ "enemy" ], self.baseEffectPos, player, self.baseEffectForward );
	}
	
	player._domFlagEffect[ self.label ] = effect;
	TriggerFX( effect );
}

setFlagNeutral()
{
	self notify( "flag_neutral" );
	
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( "neutral" );
	self.visuals[ 0 ] SetModel( game[ "flagmodels" ][ "neutral" ] );
	
	foreach ( player in level.players )
	{
		effect = player._domFlagEffect[ self.label ];
		if ( IsDefined( effect ) )
		{
			effect Delete();
		}	
	}
	
	playFlagNeutralFX();
}

playFlagNeutralFX()
{
	if ( IsDefined( self.neutralFlagFx ) )
		self.neutralFlagFx Delete();
	self.neutralFlagFx = SpawnFx( level.flagBaseFXid[ "neutral" ], self.baseEffectPos, self.baseEffectForward );
	TriggerFX( self.neutralFlagFx );
}

getTeamFlagCount( team )
{
	score = 0;
	for ( i = 0; i < level.flags.size; i++ )
	{
		if ( level.domFlags[ i ] maps\mp\gametypes\_gameobjects::getOwnerTeam() == team )
			score++;
	}	
	return score;
}

getFlagTeam()
{
	return self maps\mp\gametypes\_gameobjects::getOwnerTeam();
}

flagSetup()
{			
	// give each dom point a unique number
	foreach ( domPoint in level.domFlags )
	{
		switch( domPoint.label )
		{
			case "_a":
				domPoint.domPointNumber = 0;
				break;
			case "_b":
				domPoint.domPointNumber = 1;
				break;
			case "_c":
				domPoint.domPointNumber = 2;
				break;
		}	
	}
	
	spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_dom_spawn" );
	
	// assign each spawn point to the nearest a dom point
	foreach ( spawnPoint in spawnPoints )
	{
		spawnPoint.domPointA = false;
		spawnPoint.domPointB = false;
		spawnPoint.domPointC = false;
	
		spawnPoint.nearFlagPoint = getNearestFlagPoint( spawnPoint );
		
		switch( spawnPoint.nearFlagPoint.useObj.domPointNumber )
		{
			case 0:
				spawnPoint.domPointA = true;
				break;
			case 1:
				spawnPoint.domPointB = true;
				break;
			case 2:
				spawnPoint.domPointC = true;
				break;
		}	
	}
}

getNearestFlagPoint( spawnPoint )
{
	isPathDataAvailable = maps\mp\gametypes\_spawnlogic::isPathDataAvailable();
	nearestDomPoint		= undefined;
	nearestDist			= undefined;

	foreach ( domPoint in level.domFlags )
	{
		dist = undefined;
		
		// find the actual pathing distance between the dom point and spawn point
		if ( isPathDataAvailable )
		{
			dist = GetPathDist( spawnPoint.origin, domPoint.levelFlag.origin, 999999 );
		}
		
		// fail safe for bad pathing data		
		if ( !IsDefined( dist ) || ( dist == -1 ) )
		{
			dist = DistanceSquared( domPoint.levelFlag.origin, spawnPoint.origin );
		}
		
		// record the nearest dom point
		if ( !IsDefined( nearestDomPoint ) || dist < nearestDist )
		{
			nearestDomPoint = domPoint;
			nearestDist		= dist;
		}
	}
	
	return nearestDomPoint.levelFlag;
}

giveFlagCaptureXP( touchList ) // self == dom flag
{
	level endon ( "game_ended" );
	
	first_player = self maps\mp\gametypes\_gameobjects::getEarliestClaimPlayer();
	if ( IsDefined( first_player.owner ) )
		first_player = first_player.owner;
	
	//sets last capture time
	level.lastCapTime = GetTime();
	
	if ( IsPlayer( first_player ) )
	{
		level thread teamPlayerCardSplash( "callout_securedposition" + self.label, first_player );
		
		first_player thread maps\mp\_matchdata::logGameEvent( "capture", first_player.origin );	
	}
	
	players_touching = GetArrayKeys( touchList );
	for ( index = 0; index < players_touching.size; index++ )
	{
		player = touchList[ players_touching[ index ] ].player;
		if ( IsDefined( player.owner ) )
			player = player.owner;
		
		if ( !IsPlayer( player ) )
			continue;
		
		player thread maps\mp\gametypes\_hud_message::splashNotify( "capture", maps\mp\gametypes\_rank::getScoreInfoValue( "capture" ) );
		player thread updateCPM();
		player thread maps\mp\gametypes\_rank::giveRankXP( "capture", maps\mp\gametypes\_rank::getScoreInfoValue( "capture" ) * player getCapXPScale() );
		//printLn( maps\mp\gametypes\_rank::getScoreInfoValue( "capture" ) * player getCapXPScale() );
		maps\mp\gametypes\_gamescore::givePlayerScore( "capture", player );
		
		player incPlayerStat( "pointscaptured", 1 );
		player incPersStat( "captures", 1 );
		player maps\mp\gametypes\_persistence::statSetChild( "round", "captures", player.pers[ "captures" ] );
		
		// OP_IW6 Domination Capture - all players touching get credit for a capture
		player maps\mp\gametypes\_missions::processChallenge( "ch_domcap" );
		
		// set the extra score value for the scoreboard
		player setExtraScore0( player.pers[ "captures" ] );

		if ( player != first_player )
			player maps\mp\_events::giveObjectivePointStreaks();
		
		wait( 0.05 );	// This can occasionally spike when players is large, so spread it out over multiple frames
	}
}

getCapXPScale()
{
	if ( self.CPM < 4 )
		return 1;
	else
		return 0.25;
}

updateCPM()
{
	if ( !IsDefined( self.CPM ) )
	{
		self.numCaps = 0;
		self.CPM	 = 0;
	}
	
	self.numCaps++;
	
	if ( getMinutesPassed() < 1 )
		return;
		
	self.CPM = self.numCaps / getMinutesPassed();
}

setFlagCaptured( team, oldTeam, credit_player, setStartingFlags )
{
	label = self maps\mp\gametypes\_gameobjects::getLabel();
	self maps\mp\gametypes\_gameobjects::setOwnerTeam( team );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_capture" + label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_capture" + label );
	self maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_defend" + self.label );
	self maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defend" + self.label );
	self.visuals[ 0 ] SetModel( game[ "flagmodels" ][ team ] );
	
	if ( IsDefined( self.neutralFlagFx ) )
		self.neutralFlagFx Delete();

	foreach ( player in level.players )
	{
		self showCapturedBaseEffectToPlayer( team, player );
	}
	
	if ( !IsDefined( setStartingFlags ) )
	{
		// let the old team know that they lost the point
		if ( oldTeam != "neutral" )
		{
			statusDialog( "secured" + self.label, team , true );
			statusDialog( "lost" + self.label, oldTeam, true );
			playSoundOnPlayers( "mp_dom_flag_lost", oldTeam );
			level.lastCapTime = GetTime();
		}
		
		// revive any fallen teammates
		teamRespawn( team, credit_player );
		
		self.firstCapture = false;
	}
	
	self thread baseEffectsWaitForJoined();
}

// this is only run once a flag has been captured
// and will be stopped when it returns to neutral
baseEffectsWaitForJoined()	
{
	level endon( "game_ended" );
	self endon( "flag_neutral" );
	
	while ( true )
	{
		level waittill ( "joined_team", player );
		
		// stop any existing effects
		if ( IsDefined( player._domFlagEffect[ self.label ] ) )
		{
			player._domFlagEffect[ self.label ] Delete();
			player._domFlagEffect[ self.label ] = undefined;
		}
		
		if ( player.team != "spectator" )
		{
			self showCapturedBaseEffectToPlayer( self.ownerTeam, player );
		}
	}
}