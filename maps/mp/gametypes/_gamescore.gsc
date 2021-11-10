#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;



getHighestScoringPlayer()
{
	updatePlacement();
	
	if ( !level.placement["all"].size )
		return ( undefined );
	else 
		return ( level.placement["all"][0] );
}


getLosingPlayers()
{
	updatePlacement();
	
	players = level.placement["all"];
	losingPlayers = [];
	
	foreach ( player in players )
	{
		if ( player == level.placement["all"][0] )
			continue;
		
		losingPlayers[losingPlayers.size] = player;
	}

	return losingPlayers;
}


givePlayerScore( event, player, victim, overrideCheckPlayerScoreLimitSoon, overridePointsPopup, bScaleDown )
{
	if ( is_aliens() )
		return;
	else
		givePlayerScore_regularMP( event, player, victim, overrideCheckPlayerScoreLimitSoon, overridePointsPopup, bScaleDown );
}

givePlayerScore_regularMP( event, player, victim, overrideCheckPlayerScoreLimitSoon, overridePointsPopup, bScaleDown )
{
	// If this is a squadmate, give credit to the agent's owner player
	if ( IsDefined(player.owner) && !IsBot( player ) )
	{
		player = player.owner;
	}
	
	if ( !IsBot( player ) )
	{
		//If a player is commanding a bot, give the credit to the bot, not the player
		if ( IsDefined( player.commanding_bot ) )
		{
			player = player.commanding_bot;
		}
	}
	
	if ( !IsPlayer(player) )
		return;
	
	if ( !isDefined( overrideCheckPlayerScoreLimitSoon ) )
		overrideCheckPlayerScoreLimitSoon = false;
	
	if ( !isDefined( overridePointsPopup ) )
		overridePointsPopup = false;

	// score has a max value of 65000
	if ( !isDefined( bScaleDown ) )
		bScaleDown = false;	
	
	prevScore = player.pers["score"];
	onPlayerScore( event, player, victim, bScaleDown );
	score_change = (player.pers["score"] - prevScore);
	
	if ( score_change == 0 )
		return;
	
	// score was scaled down, multiply back to the real value
	if( bScaleDown )
		score_change = int(score_change * 10);
	
	// Store the event value to use for dm and sotf_ffa
	// This is used to get the correct value of each kill event 
	// so we display them correct for the xpPointsPopup in offline matches, and leaderboards
	eventValue = maps\mp\gametypes\_rank::getScoreInfoValue( event );
	
	if ( !player rankingEnabled() && !level.hardcoreMode && !overridePointsPopup )
	{
		// Get the correct value of the "kill" event to be shown in the XP Point Popups 
		if ( gameModeUsesDeathmatchScoring( level.gameType ) )
			player thread maps\mp\gametypes\_rank::xpPointsPopup( eventValue );
		else
			player thread maps\mp\gametypes\_rank::xpPointsPopup( score_change );
	}
	
	// Store the correct lifetime score
	if ( gameModeUsesDeathmatchScoring( level.gameType ) )
		player maps\mp\gametypes\_persistence::statAdd( "score", eventValue );
	else if ( !IsSquadsMode() )
		player maps\mp\gametypes\_persistence::statAdd( "score", score_change );
	
	//maxing player score to 65000 to protect from scoreboard overflow(max unsigned short?)
	if ( player.pers["score"] >= 65000 )
		player.pers["score"] = 65000;
	
	player.score = player.pers["score"];
	scoreChildStat  = player.score;
	
	// score was scaled down, multiply back to the real value
	if( bScaleDown )
		scoreChildStat = int(scoreChildStat * 10);
	
	// Store the correct per game score
	if ( gameModeUsesDeathmatchScoring( level.gameType ) )
		player maps\mp\gametypes\_persistence::statSetChild( "round", "score", scoreChildStat * eventValue );
	else
		player maps\mp\gametypes\_persistence::statSetChild( "round", "score", scoreChildStat );
	
	if ( !level.teambased )
		thread sendUpdatedDMScores();
	
	//	player score and team score aren't always the same values towards winning the match
	//	checkScoreLimit() checks team score correctly, checkPlayerScoreLimitSoon() uses player score
	if ( !overrideCheckPlayerScoreLimitSoon )
		player maps\mp\gametypes\_gamelogic::checkPlayerScoreLimitSoon();
		
	scoreEndedMatch = player maps\mp\gametypes\_gamelogic::checkScoreLimit();
}

onPlayerScore( event, player, victim, bScaleDown )
{
	score = undefined;
	if ( IsDefined( level.onPlayerScore ) )
	{
		score = [[level.onPlayerScore]](event, player, victim);
	}
	if ( !IsDefined( score ) )
	{
		score = maps\mp\gametypes\_rank::getScoreInfoValue( event );
	}
	
	score = score * level.objectivePointsMod;
	
	// player.score has a max value of 65000
	// scale down by 10 to allow larger numbers
	if( bScaleDown )
		score = int( score / 10 );
		
	assert( isDefined( score ) );
	
	player.pers["score"] += score;
}

// Seems to only be used for reducing a player's score due to suicide
_setPlayerScore( player, score )
{
	if ( score == player.pers["score"] )
		return;
	
	if ( score < 0 )
		return;

	player.pers["score"] = score;
	player.score = player.pers["score"];

	player thread maps\mp\gametypes\_gamelogic::checkScoreLimit();
}


_getPlayerScore( player )
{
	if( !IsDefined( player ) )
		player = self;
	return player.pers["score"];
}


giveTeamScoreForObjective( team, score )
{
	score *= level.objectivePointsMod;
	
	// NOTE: don't set level.wasWinning here because it'll give a false positive if they are tied and the lead changes below
	//	this caused a bug where the lead_taken and lead_lost vo was reversed, it was happening because the first time the lead changed
	//	they were tied before the score changed, then the next time it came in here it set level.wasWinning to the team that was already winning
	//	this then caused the lead_lost vo to play for the team who is winning
	
	_setTeamScore( team, _getTeamScore( team ) + score );
	
	level notify( "update_team_score", team, _getTeamScore( team ) );

	isWinning = getWinningTeam();

	if ( !level.splitScreen && isWinning != "none" && isWinning != level.wasWinning && getTime() - level.lastStatusTime  > 5000 && getScoreLimit() != 1 )
	{
		level.lastStatusTime = getTime();
		leaderDialog( "lead_taken", isWinning, "status" );
		if ( level.wasWinning != "none")
			leaderDialog( "lead_lost", level.wasWinning, "status" );
	}

	if( isWinning != "none" )
	{
		level.wasWinning = isWinning;
		
		teamScore = _getTeamScore( isWinning );
		scoreLimit = getWatchedDvar( "scorelimit" );
		
		// this is to handle join in progress potential div by 0
		if ( teamScore == 0 || scoreLimit == 0 )
			return;
		
		scorePercentage = ( teamScore/ scoreLimit ) * 100;
		
		if( scorePercentage > level.scorePercentageCutOff )
			SetNoJIPScore( true );	
	}
}


getWinningTeam()
{
	assert( level.teamBased == true );
	teams_list = level.teamNameList;
	
	if( !IsDefined( level.wasWinning ) )
		level.wasWinning = "none";

	winning_team = "none";
	winning_score = 0;
	if( level.wasWinning != "none" )
	{
		winning_team = level.wasWinning;
		winning_score = game[ "teamScores" ][ level.wasWinning ];
	}

	num_teams_tied_for_winning = 1;
	foreach( teamName in teams_list )
	{
		if( teamName == level.wasWinning )
			continue;

		if( game[ "teamScores" ][ teamName ] > winning_score )
		{
			// new winning team found
			winning_team = teamName;
			winning_score = game[ "teamScores" ][ teamName ];
			num_teams_tied_for_winning = 1;
		}
		else if( game[ "teamScores" ][ teamName ] == winning_score )
		{
			num_teams_tied_for_winning = num_teams_tied_for_winning + 1;
			winning_team = "none";
		}
	}

	return( winning_team );
	
}

_setTeamScore( team, teamScore )
{
	if ( teamScore == game["teamScores"][team] )
		return;

	game["teamScores"][team] = teamScore;
	
	updateTeamScore( team );
	
	if ( game["status"] == "overtime" && !isDefined( level.overtimeScoreWinOverride ) || ( isDefined( level.overtimeScoreWinOverride ) && !level.overtimeScoreWinOverride ) )
		thread maps\mp\gametypes\_gamelogic::onScoreLimit();
	else
	{
		thread maps\mp\gametypes\_gamelogic::checkTeamScoreLimitSoon( team );
		thread maps\mp\gametypes\_gamelogic::checkScoreLimit();
	}
}


updateTeamScore( team )
{
	assert( level.teamBased );
	
	teamScore = 0;
	
	// Blitz was added in this check, because it is technically a round based game, even though we don't keep track of the score based on rounds won.
	if ( !isRoundBased() || !isObjectiveBased() || level.gameType == "blitz")
		teamScore = _getTeamScore( team );
	else
		teamScore = game["roundsWon"][team];
	
	setTeamScore( team, teamScore );

	//thread sendUpdatedTeamScores();
}


_getTeamScore( team )
{
	return game["teamScores"][team];
}


sendUpdatedTeamScores()
{
	level notify("updating_scores");
	level endon("updating_scores");
	wait .05;
	
	WaitTillSlowProcessAllowed();

	foreach ( player in level.players )
		player updateScores();
}

sendUpdatedDMScores()
{
	level notify("updating_dm_scores");
	level endon("updating_dm_scores");
	wait .05;
	
	WaitTillSlowProcessAllowed();
	
	for ( i = 0; i < level.players.size; i++ )
	{
		level.players[i] updateDMScores();
		level.players[i].updatedDMScores = true;
	}
}


removeDisconnectedPlayerFromPlacement()
{
	offset = 0;
	numPlayers = level.placement["all"].size;
	found = false;
	for ( i = 0; i < numPlayers; i++ )
	{
		if ( level.placement["all"][i] == self )
			found = true;
		
		if ( found )
			level.placement["all"][i] = level.placement["all"][ i + 1 ];
	}
	if ( !found )
		return;
	
	level.placement["all"][ numPlayers - 1 ] = undefined;
	assert( level.placement["all"].size == numPlayers - 1 );

	
	if( level.multiTeamBased )
	{
		MTDM_updateTeamPlacement();
	}
	if ( level.teamBased )
	{
		updateTeamPlacement();
		return;
	}
		
	numPlayers = level.placement["all"].size;
	for ( i = 0; i < numPlayers; i++ )
	{
		player = level.placement["all"][i];
		player notify( "update_outcome" );
	}
	
}

updatePlacement()
{
	prof_begin("updatePlacement");
	
	placementAll = [];
	foreach ( player in level.players )
	{
		if ( isDefined( player.connectedPostGame ))
			continue;

		if( player.pers["team"] == "spectator" || player.pers["team"] == "none" )
			continue;
			
		placementAll[placementAll.size] = player;
	}
	
	for ( i = 1; i < placementAll.size; i++ )
	{
		player = placementAll[i];
		playerScore = player.score;
//		for ( j = i - 1; j >= 0 && (player.score > placementAll[j].score || (player.score == placementAll[j].score && player.deaths < placementAll[j].deaths)); j-- )
		for ( j = i - 1; j >= 0 && getBetterPlayer( player, placementAll[j] ) == player; j-- )
			placementAll[j + 1] = placementAll[j];
		placementAll[j + 1] = player;
	}
	
	level.placement["all"] = placementAll;
	
	if( level.multiTeamBased )
	{
		MTDM_updateTeamPlacement();
	}
	else if ( level.teamBased )
	{
		updateTeamPlacement();
	}

	prof_end("updatePlacement");
}


getBetterPlayer( playerA, playerB )
{
	if ( playerA.score > playerB.score )
		return playerA;
		
	if ( playerB.score > playerA.score )
		return playerB;
		
	if ( playerA.deaths < playerB.deaths )
		return playerA;
		
	if ( playerB.deaths < playerA.deaths )
		return playerB;
		
	// TODO: more metrics for getting the better player
		
	if ( cointoss() )
		return playerA;
	else
		return playerB;
}


updateTeamPlacement()
{
	placement["allies"]    = [];
	placement["axis"]      = [];
	placement["spectator"] = [];

	assert( level.teamBased );
	
	placementAll = level.placement["all"];
	placementAllSize = placementAll.size;
	
	for ( i = 0; i < placementAllSize; i++ )
	{
		player = placementAll[i];
		team = player.pers["team"];
		
		placement[team][ placement[team].size ] = player;
	}
	
	level.placement["allies"] = placement["allies"];
	level.placement["axis"]   = placement["axis"];
}

//NOTE: should conisder consolidating this with updateTeamPlacement... ( this was easiest 1st pass implementation )
MTDM_updateTeamPlacement()
{
	placement["spectator"] = [];
	
	foreach( teamname in level.teamNameList )
	{
		placement[teamname] = [];
	}
	
	assert( level.multiTeamBased );
	
	placementAll = level.placement["all"];
	placementAllSize = placementAll.size;
	
	for ( i = 0; i < placementAllSize; i++ )
	{
		player = placementAll[i];
		team = player.pers["team"];
		
		placement[team][ placement[team].size ] = player;
	}
	
	foreach( teamname in level.teamNameList )
	{
		level.placement[teamname] = placement[teamname];
	}
}

initialDMScoreUpdate()
{
	// the first time we call updateDMScores on a player, we have to send them the whole scoreboard.
	// by calling updateDMScores on each player one at a time,
	// we can avoid having to send the entire scoreboard to every single player
	// the first time someone kills someone else.
	wait .2;
	numSent = 0;
	while(1)
	{
		didAny = false;
		
		players = level.players;
		for ( i = 0; i < players.size; i++ )
		{
			player = players[i];
			
			if ( !isdefined( player ) )
				continue;
			
			if ( isdefined( player.updatedDMScores ) )
				continue;
			
			player.updatedDMScores = true;
			player updateDMScores();
			
			didAny = true;
			wait .5;
		}
		
		if ( !didAny )
			wait 3; // let more players connect
	}
}


processAssist( killedplayer )
{
	if ( IsDefined( level.assists_disabled ) )
		return;
		
	if ( is_aliens() )
		return;
	else
		processAssist_regularMP( killedplayer );
}

processAssist_regularMP( killedplayer )
{
	self endon("disconnect");
	killedplayer endon("disconnect");
	
	wait .05; // don't ever run on the same frame as the playerkilled callback.
	WaitTillSlowProcessAllowed();
	
	self_pers_team = self.pers["team"];
	if ( self_pers_team != "axis" && self_pers_team != "allies" )
		return;
	
	if ( self_pers_team == killedplayer.pers["team"] )
		return;
	
	assistCreditTo = self;
	if ( IsDefined( self.commanding_bot ) )
	{
		assistCreditTo = self.commanding_bot;
	}
	assistCreditTo thread [[level.onXPEvent]]( "assist" );
	assistCreditTo incPersStat( "assists", 1 );
	assistCreditTo.assists = assistCreditTo getPersStat( "assists" );
	assistCreditTo incPlayerStat( "assists", 1 );
	
	assistCreditTo maps\mp\gametypes\_persistence::statSetChild( "round", "assists", assistCreditTo.assists );
	
	givePlayerScore( "assist", self, killedplayer );
	self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "assist" );
	
	self thread maps\mp\gametypes\_missions::playerAssist( killedplayer );
}

processShieldAssist( killedPlayer )
{
	if ( IsDefined( level.assists_disabled ) )
		return;
		
	if ( is_aliens() )
		return;
	else
		processShieldAssist_regularMP( killedPlayer );
}

processShieldAssist_regularMP( killedPlayer )
{
	self endon( "disconnect" );
	killedPlayer endon( "disconnect" );
	
	wait .05; // don't ever run on the same frame as the playerkilled callback.
	WaitTillSlowProcessAllowed();
	
	if ( self.pers["team"] != "axis" && self.pers["team"] != "allies" )
		return;
	
	if ( self.pers["team"] == killedplayer.pers["team"] )
		return;
	
	self thread [[level.onXPEvent]]( "assist" );
	self thread [[level.onXPEvent]]( "assist" );
	self incPersStat( "assists", 1 );
	self.assists = self getPersStat( "assists" );
	self incPlayerStat( "assists", 1 );
	
	self maps\mp\gametypes\_persistence::statSetChild( "round", "assists", self.assists );
	
	givePlayerScore( "assist", self, killedplayer );

	self thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "shield_assist" );		
	
	self thread maps\mp\gametypes\_missions::playerAssist( killedPlayer );
}

gameModeUsesDeathmatchScoring( mode )
{
	return ( mode== "dm" 
		    || mode == "sotf_ffa" 
			// || mode == "gun"
		   );
}