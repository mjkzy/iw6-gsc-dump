#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	level.splitscreen = isSplitScreen();
	set_console_status();
	
	level.onlineGame = getDvarInt( "onlinegame" );
	level.rankedMatch = ( ( level.onlineGame && !getDvarInt( "xblive_privatematch" ) ) || GetDvarInt( "force_ranking" ) ); // System link games are no longer ranked games
	
	/#
	if ( getdvarint( "scr_forcerankedmatch" ) == 1 )
	{
		level.onlineGame = true;
		level.rankedMatch = true;
	}
	#/

	level.script = toLower( getDvar( "mapname" ) );
	level.gametype = toLower( getDvar( "g_gametype" ) );

	//default team list, use this for team algos, overwrite it for Multiteam games
	level.teamNameList = ["axis", "allies"];

	level.otherTeam["allies"] = "axis";
	level.otherTeam["axis"] = "allies";

	level.multiTeamBased = false;

	level.teamBased = false;
	
	level.objectiveBased = false;
	
	level.endGameOnTimeLimit = true;
	
	level.showingFinalKillcam = false;
	
	level.tiSpawnDelay = getDvarInt( "scr_tispawndelay" );
	
	// hack to allow maps with no scripts to run correctly
	if ( !isDefined( level.tweakablesInitialized ) )
		maps\mp\gametypes\_tweakables::init();
	
	level.halftimeType = "halftime";
	
	level.lastStatusTime = 0;
	level.wasWinning = "none";
	
	level.lastSlowProcessFrame = 0;
	
	level.placement["allies"] = [];
	level.placement["axis"] = [];
	level.placement["all"] = [];
	
	level.postRoundTime = 5.0;
	
	level.playersLookingForSafeSpawn = [];
	
	registerDvars();

	if( matchMakingGame() )
	{
		mapLeaderboard = " LB_MAP_" + getdvar( "ui_mapname" );

		gamemodeLeaderboard = "";
		baseLeaderboards = "";
		if( IsSquadsMode() )
		{
			if( getDvarInt( "squad_match" ) )
			{
				gamemodeLeaderboard = " LB_GM_SQUAD_ASSAULT";
				level thread endMatchOnHostDisconnect();
			}
			else if( level.gametype == "horde" )
			{
				gamemodeLeaderboard = " LB_GM_HORDE";
			}
		}
		else
		{
			baseLeaderboards = "LB_GB_TOTALXP_AT LB_GB_TOTALXP_LT LB_GB_WINS_AT LB_GB_WINS_LT LB_GB_KILLS_AT LB_GB_KILLS_LT LB_GB_ACCURACY_AT LB_ACCOLADES";
			gamemodeLeaderboard = " LB_GM_" + level.gametype;
		
			if( getDvarInt( "g_hardcore" ) )
				gamemodeLeaderboard += "_HC";
		}
		
		precacheLeaderboards( baseLeaderboards + gamemodeLeaderboard + mapLeaderboard );
	}
	
	level.teamCount["allies"] = 0;
	level.teamCount["axis"] = 0;
	level.teamCount["spectator"] = 0;

	level.aliveCount["allies"] = 0;
	level.aliveCount["axis"] = 0;
	level.aliveCount["spectator"] = 0;
	
	level.livesCount["allies"] = 0;
	level.livesCount["axis"] = 0;

	level.oneLeftTime = [];
	
	level.hasSpawned["allies"] = 0;
	level.hasSpawned["axis"] = 0;

	/#
	if ( getdvarint( "scr_runlevelandquit" ) == 1 )
	{
		thread runLevelAndQuit();
	}
	#/

	max_possible_teams = 9;
	init_multiTeamData( max_possible_teams );
}

endMatchOnHostDisconnect()
{
	level endon ( "game_ended" );
	
	for( ;; )
	{
		level waittill( "connected", player );
		
		if( player isHost() )
		{
			host = player;
			break;
		}
	}
	
	host waittill( "disconnect" );
	thread maps\mp\gametypes\_gamelogic::endGame( "draw", game[ "end_reason" ][ "host_ended_game" ] );	
}

init_multiTeamData( max_num_teams )
{
	for( i = 0; i < max_num_teams; i++ )
	{
		team_name = "team_" + i;

		level.placement[team_name] = [];
		
		level.teamCount[team_name] = 0;
		level.aliveCount[team_name] = 0;
		level.livesCount[team_name] = 0;
		level.hasSpawned[team_name] = 0;
	}
}


/#
runLevelAndQuit()
{
	wait 1;
	while ( level.players.size < 1 )
	{
		wait 0.5;
	}
	wait 0.5;
	level notify( "game_ended" );
	exitLevel();	
}
#/


registerDvars()
{
	SetOmnvar( "ui_bomb_timer", 0 );
	if( getDvar( "r_reflectionProbeGenerate" ) != "1" )
	{
		SetOmnvar( "ui_nuke_end_milliseconds", 0 );
	}
	SetDvar( "ui_danger_team", "" );	
	SetDvar( "ui_inhostmigration", 0 );
	SetDvar( "ui_override_halftime", 0 );
	SetDvar( "camera_thirdPerson", getDvarInt( "scr_thirdPerson" ) );
}

SetupCallbacks()
{
	level.onXPEvent = ::onXPEvent;
	
	level.getSpawnPoint = ::blank;
	level.onSpawnPlayer = ::blank;
	level.onRespawnDelay = ::blank;

	level.onTimeLimit = maps\mp\gametypes\_gamelogic::default_onTimeLimit;
	level.onHalfTime = maps\mp\gametypes\_gamelogic::default_onHalfTime;
	level.onDeadEvent = maps\mp\gametypes\_gamelogic::default_onDeadEvent;
	level.onOneLeftEvent = maps\mp\gametypes\_gamelogic::default_onOneLeftEvent;
	
	level.onPrecacheGametype = ::blank;
	level.onStartGameType = ::blank;
	level.onPlayerKilled = ::blank;
	
	level.killStreakInit = maps\mp\killstreaks\_killstreaks_init::init;	
	level.matchEventsInit = maps\mp\_matchevents::init;
	level.intelInit = maps\mp\gametypes\_intel::init;
	
	/#
	level.devInit = maps\mp\gametypes\_dev::init;
	#/

	//level.autoassign = maps\mp\gametypes\_menus::menuAutoAssign;
	//level.spectator = maps\mp\gametypes\_menus::menuSpectator;
	//level.class = maps\mp\gametypes\_menus::menuClass;
	//level.onTeamSelection = maps\mp\gametypes\_menus::onMenuTeamSelect;
}



blank( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 )
{
}



/#
xpRateThread()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );

	gameFlagWait( "prematch_done" );

	for ( ;; )
	{
		wait ( 5.0 );
		if ( level.players[0].pers["team"] == "allies" || level.players[0].pers["team"] == "axis" )
			self maps\mp\gametypes\_rank::giveRankXP( "kill", int(min( getDvarInt( "scr_xprate" ), 50 )) );
	}
}
#/

testMenu()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	for ( ;; )
	{
		wait ( 10.0 );
		
		notifyData = spawnStruct();
		notifyData.titleText = &"MP_CHALLENGE_COMPLETED";
		notifyData.notifyText = "wheee";
		notifyData.sound = "mp_challenge_complete";
	
		self thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );
	}
}

testShock()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	for ( ;; )
	{
		wait ( 3.0 );

		numShots = randomInt( 6 );
		
		for ( i = 0; i < numShots; i++ )
		{
			iPrintLnBold( numShots );
			self shellShock( "frag_grenade_mp", 0.2 );
			wait ( 0.1 );
		}
	}
}


onXPEvent( event )
{
	//self thread maps\mp\_loot::giveMoney( event, 10 );
	self thread maps\mp\gametypes\_rank::giveRankXP( event );
}


debugLine( start, end )
{
	for ( i = 0; i < 50; i++ )
	{
		line( start, end );
		wait .05;
	}
}
