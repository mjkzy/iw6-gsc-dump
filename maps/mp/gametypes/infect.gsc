#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_class;
#include common_scripts\utility;


// survivors are allies
// infected are axis


CONST_FIRST_INFECTED_TIMER 		= 15;
CONST_INFECTED_MOVE_SCALAR		= 1.2;
CONST_PLAYER_START_LETHAL 		= "proximity_explosive_mp";
CONST_PLAYER_START_TACTICAL 	= "concussion_grenade_mp";
CONST_INFECTED_LETHAL 			= "throwingknife_mp";
CONST_INFECTED_TACTICAL 		= "specialty_tacticalinsertion";

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
		registerTimeLimitDvar( level.gameType, 10 );
		setOverrideWatchDvar( "scorelimit", 0 );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 ); 
		
		level.matchRules_numInitialInfected = 1;		
		level.matchRules_damageMultiplier = 0;
	}
	
	setSpecialLoadouts();
	
	level.teamBased 		= true;
	level.supportIntel		= false;
	level.disableForfeit	= true;
	level.noBuddySpawns		= true;
	level.onStartGameType 	= ::onStartGameType;
	level.onSpawnPlayer 	= ::onSpawnPlayer;
	level.getSpawnPoint 	= ::getSpawnPoint;
	level.onPlayerKilled	= ::onPlayerKilled;
	level.onDeadEvent 		= ::onDeadEvent;
	level.onTimeLimit 		= ::onTimeLimit;
	level.bypassClassChoiceFunc	= ::alwaysGamemodeClass;	
	
	if ( level.matchRules_damageMultiplier )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;
	
	game["dialog"]["gametype"] = "infected";
	
	if ( getDvarInt( "g_hardcore" ) )
		game["dialog"]["gametype"] = "hc_" + game["dialog"]["gametype"];
	
	game["dialog"]["offense_obj"] = "infct_hint";
}


initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	//	set everything else (private match options, default .cfg file values, and what normally is registered in the 'else' below)
	level.matchRules_numInitialInfected = GetMatchRulesData( "infectData", "numInitialInfected" );
		
	//	always infinite lives
	SetDynamicDvar( "scr_" + level.gameType + "_numLives", 0 );
	registerNumLivesDvar( level.gameType, 0 );
	
	setOverrideWatchDvar( "scorelimit", 0 );
	SetDynamicDvar( "scr_infect_roundswitch", 0 );
	registerRoundSwitchDvar( "infect", 0, 0, 9 );
	SetDynamicDvar( "scr_infect_roundlimit", 1 );
	registerRoundLimitDvar( "infect", 1 );		
	SetDynamicDvar( "scr_infect_winlimit", 1 );
	registerWinLimitDvar( "infect", 1 );			
	SetDynamicDvar( "scr_infect_halftime", 0 );
	registerHalfTimeDvar( "infect", 0 );
	
	//	Always force these values for this mode
	SetDynamicDvar( "scr_infect_playerrespawndelay", 0 );
	SetDynamicDvar( "scr_infect_waverespawndelay", 0 );
	SetDynamicDvar( "scr_player_forcerespawn", 1 );	
	SetDynamicDvar( "scr_team_fftype", 0 );	
		
	SetDynamicDvar( "scr_infect_promode", 0 );	
}


onStartGameType()
{
	setClientNameMode("auto_change");

	setObjectiveText( "allies", &"OBJECTIVES_INFECT" );
	setObjectiveText( "axis", &"OBJECTIVES_INFECT" );

	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_INFECT" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_INFECT" );
	}
	else
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_INFECT_SCORE" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_INFECT_SCORE" );
	}
	setObjectiveHintText( "allies", &"OBJECTIVES_INFECT_HINT" );
	setObjectiveHintText( "axis", &"OBJECTIVES_INFECT_HINT" );

	initSpawns();

	allowed[0] = level.gameType;
	maps\mp\gametypes\_gameobjects::main( allowed );	
		
	level.QuickMessageToAll 	= true;	
	level.blockWeaponDrops 		= true;
	level.infect_allowSuicide 	= false;
	
	level.infect_choseFirstInfected = false;
	level.infect_choosingFirstInfected = false;
	level.infect_awardedFinalSurvivor = false;
	level.infect_countdownInProgress = false;
	
	level.infect_teamScores["axis"] = 0;
	level.infect_teamScores["allies"] = 0;	
	level.infect_players = [];
	
	level thread onPlayerConnect();
	level thread gameTimer();
}


gameTimer()
{
	level endon( "game_ended" );
	
	SetDynamicDvar( "scr_infect_timelimit", 0 );
	
	while( true )
	{
		level waittill( "update_game_time", newGameTime );
		
		if( !IsDefined( newGameTime ) )
		{
			// this addes 2 minutes and 1.5 seconds to the timer
			newGameTime = ( ( getTimePassed() + 1500 ) / ( 60 * 1000 ) ) + 2;
		}
		SetDynamicDvar( "scr_infect_timelimit", newGameTime );
		level thread watchHostMigration( newGameTime );
	}
}

watchHostMigration( newGameTime ) // self == level
{
	level notify( "watchHostMigration" );
	level endon( "watchHostMigration" );
	
	level endon( "game_ended" );
	
	// this watches for host migration so we can reset the game time to the correct time
	//	if we didn't do this then the game time would get reset to the default recipe game rules time of 10 minutes
	level waittill( "host_migration_begin" );
	SetDynamicDvar( "scr_infect_timelimit", 0 );
	waittillframeend; // match rules are reinit'd so give it a frame and then set the timelimit to 0 so it doesn't show as 10 minutes while the match restarts
	SetDynamicDvar( "scr_infect_timelimit", 0 );
	level waittill( "host_migration_end" );
	level notify( "update_game_time", newGameTime );
}

onPlayerConnect()
{
	while( true )
	{
		level waittill( "connected", player );
		
		player.gameModefirstSpawn 		= true;
		player.gameModeJoinedAtStart 	= true;
		player.infectedRejoined 		= false;
		
		if( gameFlag( "prematch_done" ) )
		{
			player.gameModeJoinedAtStart = false;
			if ( IsDefined(level.infect_choseFirstInfected) && level.infect_choseFirstInfected )
				player.survivalStartTime = GetTime();
		}
			
		//	infected who quit and rejoined same game
		if( IsDefined( level.infect_players[player.name] ) )
		{
			player.infectedRejoined = true;
		}
		
		player thread monitorSurvivalTime();
	}
}


initSpawns()
{
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );	
	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );
}

alwaysGamemodeClass()
{
	return "gamemode";
}

getSpawnPoint()
{	
	if( self.gameModefirstSpawn )
	{
		self.gameModefirstSpawn = false;
		
		//	everyone is a gamemode class in infected, no class selection
		self.pers["class"] 		= "gamemode";
		self.pers["lastClass"] 	= "";
		self.class 				= self.pers["class"];
		self.lastClass 			= self.pers["lastClass"];	
			
		// survivors are allies
		teamChoice = "allies";
		
		//	everyone starts as survivors, unless an infected quit and rejoined same game
		if( self.infectedRejoined )	
		{
			teamChoice = "axis";	
		}
		
		self maps\mp\gametypes\_menus::addToTeam( teamChoice, true );	
		self thread monitorDisconnect();
	}
		
	if( level.inGracePeriod )
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_tdm_spawn" );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_NearTeam( spawnPoints );
	}
	
	return spawnPoint;	
}

onSpawnPlayer()
{
	self.teamChangedThisFrame = undefined;
	self.infect_spawnPos = self.origin;
	
	//	resynch teams
	updateTeamScores();	
	
	//	let the first spawned player kick this off
	if ( !level.infect_choosingFirstInfected )
	{
		level.infect_choosingFirstInfected = true;
		level thread chooseFirstInfected();
	}	
	
	//	infected who quit and rejoined same game?
	if( self.infectedRejoined )
	{
		//	stop initial infect countdown (if quit/join player was initial and a new coutdown is underway)
		if ( !level.infect_allowSuicide ) 
		{
			level notify( "infect_stopCountdown" );			
			level.infect_choseFirstInfected = true;
			level.infect_allowSuicide = true;
			foreach( player in level.players )
			{
				if ( isDefined( player.infect_isBeingChosen ) )
					player.infect_isBeingChosen = undefined;
			}		
		}
		
		//	if an initial was already chosen while they were gone and they are still initial, set them to normal
		foreach( player in level.players )
		{
			if ( isDefined( player.isInitialInfected ) )
				player thread setInitialToNormalInfected();
		}
		
		//	if they're the only infected, then set them as initial infected
		if ( level.infect_teamScores["axis"] == 1 )
			self.isInitialInfected = true;
		
		self initSurvivalTime( true );
	}
	
	//	onSpawnPlayer() is called before giveLoadout()
	//	set self.pers["gamemodeLoadout"] for giveLoadout() to use
	if ( isDefined( self.isInitialInfected ) )
	{
		self.pers["gamemodeLoadout"] = level.infect_loadouts["axis_initial"];
		self.infected_class = "axis_initial";
	}
	else
	{
		self.pers["gamemodeLoadout"] = level.infect_loadouts[self.pers["team"]];
		self.infected_class = self.pers["team"];
	}
	
	self thread onSpawnFinished();
	
	level notify ( "spawned_player" );
}

spawnWithPlayerSecondary()
{
	playerWeapons = self GetWeaponsListPrimaries();
	playerCurrentWeapon = self GetCurrentPrimaryWeapon();
	
	if ( playerWeapons.size > 1 )
	{
		if ( playerCurrentWeapon == "iw6_knifeonly_mp" )
		{			
			foreach ( weapon in playerWeapons )
			{
				if ( weapon != playerCurrentWeapon )
					self SetSpawnWeapon( weapon );
			}
		}
	}
}

setDefaultAmmoClip( team )
{
	// self == player
	
	setDefaultAmmoClip = true;

	if ( IsDefined( self.isInitialInfected ) )
	{
		if ( isUsingDefaultClass( team, 1 ) )
			setDefaultAmmoClip = false;
	}
	else
	{
		if ( isUsingDefaultClass( team, 0 ) )
			setDefaultAmmoClip = false;
	}

	return setDefaultAmmoClip;
}

onSpawnFinished()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	self waittill( "giveLoadout" );
	
	self.last_infected_class = self.infected_class;
	
	// ES - 01/15/14 - Used for Default Loadouts
	// Players will now spawn in with a valid secondary weapon already equipped, if the primary is knife only 
	// Now blocking the mode from setting the player's tactical/lethal ammo clip, if there is an active default loadout for the team they are going to spawn on
	// This prevents issue where the default loadout could contain ( for example ) the same lethal, with the extra lethal perk, it this overwrites it
	
	if( self.pers["team"] == "allies" ) // SURVIVORS
	{
		self spawnWithPlayerSecondary();
		
		if ( setDefaultAmmoClip( "allies" ) )
		{
			self SetWeaponAmmoClip( CONST_PLAYER_START_LETHAL, 1 );
			self SetWeaponAmmoClip( CONST_PLAYER_START_TACTICAL, 1 );
		}
	}
	else if( self.pers["team"] == "axis" ) // INFECTED
	{
		self thread setInfectedMsg();
		
		self setMoveSpeedScale( CONST_INFECTED_MOVE_SCALAR );
		
		if ( setDefaultAmmoClip( "axis" ) )
			self SetWeaponAmmoClip( CONST_INFECTED_LETHAL, 1 );
		
		self thread setInfectedModels();
	}

	// HACK: clearing a HACK variable see HACK_NOTE_1
	self.faux_spawn_infected = undefined;
}

setInfectedModels()
{
	self SetModel( "mp_body_infected_a" );
	if( IsDefined( self.headModel ) )
	{
		self Detach( self.headModel, "" );
		self.headModel = undefined;
	}
	self Attach( "head_mp_infected", "", true );
	self.headModel = "head_mp_infected";
	self SetViewmodel( "viewhands_gs_hostage" );
	self SetClothType("cloth");		
}

setInfectedMsg()
{
	if ( isDefined( self.isInitialInfected ) )
	{
		if (!isDefined(self.shownInfected) || !self.shownInfected)
		{
			self thread maps\mp\gametypes\_rank::xpEventPopup( "first_infected" );
			self.shownInfected = true;
		}
	}
	else if ( isDefined( self.changingToRegularInfected ) )
	{
		self.changingToRegularInfected = undefined;
		if ( isDefined( self.changingToRegularInfectedByKill ) )
		{
			self.changingToRegularInfectedByKill = undefined;
			self thread maps\mp\gametypes\_rank::xpEventPopup( "firstblood" );	
			maps\mp\gametypes\_gamescore::givePlayerScore( "first_infected", self );	
			self thread maps\mp\gametypes\_rank::giveRankXP( "first_infected" );
		}	
	}
	else
	{
		if (!isDefined(self.shownInfected) || !self.shownInfected)
		{
			self thread maps\mp\gametypes\_rank::xpEventPopup( "got_infected" );
			self.shownInfected = true;
		}
	}
}


chooseFirstInfected()
{
	level endon( "game_ended" );
	level endon( "infect_stopCountdown" );
	
	level.infect_allowSuicide = false;
	gameFlagWait( "prematch_done" );
	
	level.infect_countdownInProgress = true;
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 1.0 );
	SetOmnvar( "ui_match_start_text", "first_infected_in" );
	countTime = CONST_FIRST_INFECTED_TIMER;
	while( countTime > 0 && !level.gameEnded )
	{
		SetOmnvar( "ui_match_start_countdown", countTime );
		countTime--;
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 1.0 );
	}
	SetOmnvar( "ui_match_start_countdown", 0 );
	
	level.infect_countdownInProgress = false;	
	
	possibleInfected = [];
	
	foreach( player in level.players )
	{
		// don't pick the host as the first infected to prevent host migration
		if( matchMakingGame() && (level.players.size > 1) && (player IsHost()) )
			continue;
		
		if ( player.team == "spectator" )
			continue;
		
		if ( !player.hasSpawned )
			continue;
				
		possibleInfected[possibleInfected.size] = player;
	}
	
	firstInfectedPlayer = possibleInfected[ randomInt( possibleInfected.size ) ];
	firstInfectedPlayer setFirstInfected( true );
	
	foreach( player in level.players )
	{
		if( player == firstInfectedPlayer )
			continue;
		player.survivalStartTime = GetTime();
	}
}


setFirstInfected( wasChosen )
{	
	self endon( "disconnect" );
	
	if ( wasChosen )
		self.infect_isBeingChosen = true;
	
	//	wait alive
	while( !isReallyAlive( self ) || self isUsingRemote() )
		wait( 0.05 );
	
	//	remove placement item if carrying
	if ( IsDefined( self.isCarrying ) && self.isCarrying == true )
	{
		self notify( "force_cancel_placement" );
		wait( 0.05 );
	}				
	
	//	not while mantling
	while ( self IsMantling() )
		wait( 0.05 );	
	
	//	not while in air
	while ( !self isOnGround() && !self IsOnLadder() )
		wait( 0.05 );
	
	//	remove jugg
	if ( self isJuggernaut() )
	{
		self notify( "lost_juggernaut" );
		wait( 0.05 );
	}		
		
	while ( !isAlive( self ) )
		waitframe();

	//	move to other team
	if ( wasChosen )
	{
		self maps\mp\gametypes\_menus::addToTeam( "axis", undefined, true );
		self thread monitorDisconnect();
		level.infect_choseFirstInfected = true;
		self.infect_isBeingChosen = undefined;
		
		//	resynch teams
		level notify( "update_game_time" );
		updateTeamScores();					
		
		//	allow suicides now
		level.infect_allowSuicide = true;		
	}
	
	//	store initial
	self.isInitialInfected = true;	
	
	//	set the gamemodeloadout for giveLoadout() to use
	self.pers["gamemodeLoadout"] = level.infect_loadouts["axis_initial"];
	
	//	remove old TI if it exists
	if ( isDefined ( self.setSpawnpoint ) )
		self maps\mp\perks\_perkfunctions::deleteTI( self.setSpawnpoint );	
	
	//	set faux TI to respawn in place
	spawnPoint = spawn( "script_model", self.origin );
	spawnPoint.angles = self.angles;
	spawnPoint.playerSpawnPos = self.origin;
	spawnPoint.notTI = true;		
	self.setSpawnPoint = spawnPoint;
		
	//	faux spawn
	self notify( "faux_spawn" );
	self.faux_spawn_stance = self getStance();
	// HACK_NOTE_1: setting faux_spawn_infected to not reset the lastSpawnTime when we call spawnPlayer because it messes up the killcam
	//	the correct fix here is to not respawn the player
	//	the original HACK was done for MW3 TU0 because a player could hold a grenade while being changed to the inital infected 
	//	and it would cause you to have no weapons, for Ghosts it causes a code crash on PWF_USING_OFFHAND
	// 	see HACK_NOTE_2
	self.faux_spawn_infected = true;
	self thread maps\mp\gametypes\_playerlogic::spawnPlayer( true );
	
	//	store infected
	if ( wasChosen )
		level.infect_players[self.name] = true;

	//	tell the world!
	foreach( player in level.players )
		player thread maps\mp\gametypes\_hud_message::SplashNotify( "first_infected" );
	level thread teamPlayerCardSplash( "callout_first_infected", self );
	playSoundOnPlayers( "mp_enemy_obj_captured" );	
	
	self initSurvivalTime( true );
}


setInitialToNormalInfected( gotKill, sMeansOfDeath )
{
	level endon( "game_ended" );
	
	self.isInitialInfected = undefined;	
	self.changingToRegularInfected = true;	
	if ( isDefined( gotKill ) )
		self.changingToRegularInfectedByKill = true;
	
	//	wait till we spawn if we died at the same time
	while ( !isReallyAlive( self ) )
		wait( 0.05 );

	//	remove placement item if carrying
	if ( IsDefined( self.isCarrying ) && self.isCarrying == true )
	{
		self notify( "force_cancel_placement" );
		wait( 0.05 );
	}		
	
	//	not while mantling
	while ( self IsMantling() )
		wait( 0.05 );	
	
	//	not while in air
	while ( !self isOnGround() )
		wait( 0.05 );
	
	//	remove jugg
	if ( self isJuggernaut() )
	{
		self notify( "lost_juggernaut" );
		wait( 0.05 );
	}	
	
	//	HACK: not while meleeing - this is a hack until MP has a way to be able to tell that the player is meleeing
	if( isDefined( sMeansOfDeath ) && sMeansOfDeath == "MOD_MELEE" )
		wait( 1.2 );
	
	//	Gotta check again, more time has passed, wait till we spawn if we died at the same time
	while ( !isReallyAlive( self ) )
		wait( 0.05 );
	
	//	set the gamemodeloadout for giveLoadout() to use
	self.pers["gamemodeLoadout"] = level.infect_loadouts["axis"];
	
	//	remove old TI if it exists
	if ( isDefined ( self.setSpawnpoint ) )
		self maps\mp\perks\_perkfunctions::deleteTI( self.setSpawnpoint );	
	
	//	set faux TI to respawn in place	
	spawnPoint = spawn( "script_model", self.origin );
	spawnPoint.angles = self.angles;
	spawnPoint.playerSpawnPos = self.origin;
	spawnPoint.notTI = true;		
	self.setSpawnPoint = spawnPoint;
		
	//	faux spawn
	self notify( "faux_spawn" );
	self.faux_spawn_stance = self getStance();
	// HACK_NOTE_1: setting faux_spawn_infected to not reset the lastSpawnTime when we call spawnPlayer because it messes up the killcam
	//	the correct fix here is to not respawn the player
	//	the original HACK was done for MW3 TU0 because a player could hold a grenade while being changed to the inital infected 
	//	and it would cause you to have no weapons, for Ghosts it causes a code crash on PWF_USING_OFFHAND
	// 	see HACK_NOTE_2
	self.faux_spawn_infected = true;
	self thread maps\mp\gametypes\_playerlogic::spawnPlayer( true );
}


onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, lifeId )
{
	processKill = false;
	wasSuicide = false;
	
	if ( self.team == "allies" && isDefined( attacker ) )
	{
		if ( isPlayer( attacker ) && attacker != self )
			processKill = true;
		else if ( level.infect_allowSuicide && ( attacker == self || !isPlayer( attacker ) ) )
		{
			processKill = true;
			wasSuicide = true;
		}
	}
	
	//For leaderboards
	if( isPlayer( attacker ) && attacker.team == "allies" && attacker != self  )
	{
		attacker.pers["killsAsSurvivor"]++;
		attacker maps\mp\gametypes\_persistence::statSetChild( "round", "killsAsSurvivor", attacker.pers["killsAsSurvivor"] );
	}
	else if( isPlayer( attacker ) && attacker.team == "axis" && attacker != self )
	{
		attacker.pers["killsAsInfected"]++;
		attacker maps\mp\gametypes\_persistence::statSetChild( "round", "killsAsInfected", attacker.pers["killsAsInfected"] );
	}
	
	if ( processKill )
	{		
		//	track team change for this frame (so explosives can't team kill, now that they changed teams)
		self.teamChangedThisFrame = true;
		
		//	move victim to infected
		self maps\mp\gametypes\_menus::addToTeam( "axis" );
		self thread monitorDisconnect();
		
		//	resynch teams
		level notify( "update_game_time" );
		updateTeamScores();	
		
		//	store infected
		level.infect_players[self.name] = true;		
		
		if ( wasSuicide )
		{
			//	set initial infected to regular infected since a survivor just commited suicide and initial infected is no longer alone
			if ( level.infect_teamScores["axis"] > 1 )
			{
				foreach( player in level.players )
				{
					if ( isDefined( player.isInitialInfected ) )
						player thread setInitialToNormalInfected();
				}				
			}
		}
		else
		{
			//	set attacker to regular infected if they were the first infected
			if ( isDefined( attacker.isInitialInfected ) )
				attacker thread setInitialToNormalInfected( true, sMeansOfDeath );	
			else
			{				
				//	regular attacker reward
				attacker thread maps\mp\gametypes\_rank::xpEventPopup( "infected_survivor" );
				maps\mp\gametypes\_gamescore::givePlayerScore( "infected_survivor", attacker, self, true );
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "infected_survivor" );
			}
		}
		
		//	generic messages/sounds, and reward survivors
		if ( level.infect_teamScores["allies"] > 1 )
		{
			playSoundOnPlayers( "mp_enemy_obj_captured", "allies" );
			playSoundOnPlayers( "mp_war_objective_taken", "axis" );
			thread teamPlayerCardSplash( "callout_got_infected", self, "allies" );	
			if ( !wasSuicide )
			{
				thread teamPlayerCardSplash( "callout_infected", attacker, "axis" );			
				
				foreach ( player in level.players )
				{
					if( !isReallyAlive( player ) || self.sessionstate == "spectator" )
						continue;
					
					if ( player.team == "allies" && player != self && distance( player.infect_spawnPos, player.origin ) > 32 )
					{
						player thread maps\mp\gametypes\_rank::xpEventPopup( "survivor" );
						maps\mp\gametypes\_gamescore::givePlayerScore( "survivor", player, undefined, true );
						player thread maps\mp\gametypes\_rank::giveRankXP( "survivor" );	
					}
				}		
			}	
		}		
		//	inform/reward last
		else if ( level.infect_teamScores["allies"] == 1 )
		{
			onFinalSurvivor();
		}
		//	infected win
		else if ( level.infect_teamScores["allies"] == 0 )
		{
			onSurvivorsEliminated();
		}	
		
		self setSurvivalTime( true );
	}		
}


onFinalSurvivor()
{
	playSoundOnPlayers( "mp_obj_captured" );
	foreach ( player in level.players )
	{
		if( !isDefined(player) )
			continue;
		
		if ( player.team == "allies" )
		{
			player thread maps\mp\gametypes\_rank::xpEventPopup( "final_survivor" );
			if ( !level.infect_awardedFinalSurvivor )
			{
				if ( player.gameModeJoinedAtStart && isDefined( player.infect_spawnPos ) && distance( player.infect_spawnPos, player.origin ) > 32 )
				{
					maps\mp\gametypes\_gamescore::givePlayerScore( "final_survivor", player, undefined, true );	
					player thread maps\mp\gametypes\_rank::giveRankXP( "final_survivor" );	
				}
				level.infect_awardedFinalSurvivor = true;
			}				
			thread teamPlayerCardSplash( "callout_final_survivor", player );
			if( !player isJuggernaut() )
				level thread finalSurvivorUAV( player );
			break;
		}
	}
}


finalSurvivorUAV( finalPlayer )
{
	level endon( "game_ended" );
	finalPlayer endon( "disconnect" );
	finalPlayer endon( "eliminated" );
	level endon( "infect_lateJoiner" );
	level thread endUAVonLateJoiner( finalPlayer );
	
	removeUAV = false;
	level.radarMode["axis"] = "normal_radar";	
	foreach ( player in level.players )
	{
		if ( player.team == "axis" )
			player.radarMode = "normal_radar";	
	}
	setTeamRadarStrength( "axis", 1 );	
		
	while( true )
	{		
		prevPos = finalPlayer.origin;
		
		wait( 4 );
		if ( removeUAV )
		{
			setTeamRadar( "axis", 0 );		
			removeUAV = false;
		}
		
		wait( 6 );		
		if ( distance( prevPos, finalPlayer.origin ) < 200 )
		{
			setTeamRadar( "axis", 1 );
			removeUAV = true;
			
			foreach ( player in level.players )
				player playLocalSound( "recondrone_tag" );
		}		
	}
}


endUAVonLateJoiner( finalPlayer )
{
	level endon( "game_ended" );
	finalPlayer endon( "disconnect" );
	finalPlayer endon( "eliminated" );
	
	while( true )
	{
		if ( level.infect_teamScores["allies"] > 1 )
		{
			level notify( "infect_lateJoiner" );
			wait( 0.05 );
			setTeamRadar( "axis", 0 );
			break;
		}
		wait( 0.05 );
	}
}

monitorDisconnect()
{
	level endon( "game_ended" );
	self endon( "eliminated" );

	self notify( "infect_monitor_disconnect" );
	self endon( "infect_monitor_disconnect" );

	team = self.team;
	if ( !IsDefined(team) && IsDefined(self.bot_team) )
		team = self.bot_team;
	
	self waittill( "disconnect" );
	
	//	resynch teams
	updateTeamScores();
	
	//	team actions or win condition necessary?
	if ( isDefined( self.infect_isBeingChosen ) || level.infect_choseFirstInfected )
	{			
		if ( level.infect_teamScores["axis"] && level.infect_teamScores["allies"] )
		{
			if ( team == "allies" && level.infect_teamScores["allies"] == 1 )
			{
				//	final survivor was abandoned: inform, reward, call uav
				onFinalSurvivor();
			}
			else if ( team == "axis" && level.infect_teamScores["axis"] == 1 )
			{
				//	final infected was abandoned: inform, set initial
				foreach ( player in level.players )
				{
					if ( player != self && player.team == "axis" )
						player setFirstInfected( false );
				}
			}
		}		
		else if ( level.infect_teamScores["allies"] == 0 )
		{
			//	no more survivors, infected win
			onSurvivorsEliminated();	
		}			
		else if ( level.infect_teamScores["axis"] == 0 )
		{
			if ( level.infect_teamScores["allies"] == 1 )
			{
				//	last survivor wins
				level.finalKillCam_winner = "allies";
				level thread maps\mp\gametypes\_gamelogic::endGame( "allies", game[ "end_reason" ][ "axis_eliminated" ] );				
			}			
			else if ( level.infect_teamScores["allies"] > 1 )
			{
				//	pick a new infected and keep the game going					
				level.infect_choseFirstInfected = false;
				level thread chooseFirstInfected();	
			}			
		}	
	}
	// If there is only one person who spawns in, and leaves before the countdown timer is up 
	else if ( level.infect_countdownInProgress && level.infect_teamScores["allies"] == 0 && level.infect_teamScores["axis"] == 0 )
	{
		level notify( "infect_stopCountdown" );	
		level.infect_choosingFirstInfected = false;
		SetOmnvar( "ui_match_start_countdown", 0 );
	}
		
	//	clear this regardless on the way out
	self.isInitialInfected = undefined;	
}


onDeadEvent( team )
{
	//	override default to supress the normal game ending process 
	return;
}


onTimeLimit()
{
	//	survivors win
	level.finalKillCam_winner = "allies";
	level thread maps\mp\gametypes\_gamelogic::endGame( "allies", game[ "end_reason" ][ "time_limit_reached" ] );	
}


onSurvivorsEliminated()
{
	//	infected win	
	level.finalKillCam_winner = "axis";
	level thread maps\mp\gametypes\_gamelogic::endGame( "axis", game[ "end_reason" ][ "allies_eliminated" ] );	
}


getTeamSize( team )
{
	size = 0;
	
	foreach( player in level.players )
	{
		// Make sure we don't check for spectators
		// Also need to check for if they are in killcam, because player session states are set to spectator when killcam happens
		if ( player.sessionstate == "spectator" && !player.spectatekillcam )
			continue;
	
		if( player.team == team )
			size++;
	}
	
	return size;	
}


updateTeamScores()
{
	// survivors
	level.infect_teamScores["allies"] = getTeamSize( "allies" );
	game["teamScores"]["allies"] = level.infect_teamScores["allies"];
	setTeamScore( "allies", level.infect_teamScores["allies"] );
	
	// infected
	level.infect_teamScores["axis"] = getTeamSize( "axis" );
	game["teamScores"]["axis"] = level.infect_teamScores["axis"];
	setTeamScore( "axis", level.infect_teamScores["axis"] );
}

setSpecialLoadouts()
{	
	//	survivors	
	if ( isUsingDefaultClass( "allies", 0 ) )
		level.infect_loadouts["allies"] = getMatchRulesSpecialClass( "allies", 0 );	
	else
	{
		level.infect_loadouts["allies"]["loadoutPrimary"] 						= "iw6_maul";
		level.infect_loadouts["allies"]["loadoutPrimaryAttachment"] 			= "none";
		level.infect_loadouts["allies"]["loadoutPrimaryAttachment2"] 			= "none";
		level.infect_loadouts["allies"]["loadoutPrimaryBuff"] 					= "specialty_longerrange";
		level.infect_loadouts["allies"]["loadoutPrimaryCamo"] 					= "none";
		level.infect_loadouts["allies"]["loadoutPrimaryReticle"] 				= "none";
		level.infect_loadouts["allies"]["loadoutSecondary"] 					= "none";
		level.infect_loadouts["allies"]["loadoutSecondaryAttachment"] 			= "none";
		level.infect_loadouts["allies"]["loadoutSecondaryAttachment2"] 			= "none";
		level.infect_loadouts["allies"]["loadoutSecondaryBuff"] 				= "specialty_null";
		level.infect_loadouts["allies"]["loadoutSecondaryCamo"] 				= "none";
		level.infect_loadouts["allies"]["loadoutSecondaryReticle"] 				= "none";
		level.infect_loadouts["allies"]["loadoutEquipment"]						= CONST_PLAYER_START_LETHAL;
		level.infect_loadouts["allies"]["loadoutOffhand"] 						= CONST_PLAYER_START_TACTICAL;
		level.infect_loadouts["allies"]["loadoutStreakType"] 					= "assault";
		level.infect_loadouts["allies"]["loadoutKillstreak1"] 					= "none";
		level.infect_loadouts["allies"]["loadoutKillstreak2"] 					= "none";
		level.infect_loadouts["allies"]["loadoutKillstreak3"] 					= "none";	
		level.infect_loadouts["allies"]["loadoutJuggernaut"] 					= false;	
		level.infect_loadouts["allies"]["loadoutPerks"] 						= [ "specialty_scavenger", "specialty_quickdraw", "specialty_quieter" ];
	}
	
	//	initial infected
	if ( isUsingDefaultClass( "axis", 1 ) )
	{
		level.infect_loadouts["axis_initial"] = getMatchRulesSpecialClass( "axis", 1 );
		level.infect_loadouts["axis_initial"]["loadoutStreakType"] = "assault";
		level.infect_loadouts["axis_initial"]["loadoutKillstreak1"] = "none";
		level.infect_loadouts["axis_initial"]["loadoutKillstreak2"] = "none";
		level.infect_loadouts["axis_initial"]["loadoutKillstreak3"] = "none";		
	}
	else
	{
		level.infect_loadouts["axis_initial"]["loadoutPrimary"] 				= "iw6_m9a1";
		level.infect_loadouts["axis_initial"]["loadoutPrimaryAttachment"] 		= "none";
		level.infect_loadouts["axis_initial"]["loadoutPrimaryAttachment2"] 		= "none";
		level.infect_loadouts["axis_initial"]["loadoutPrimaryBuff"] 			= "specialty_bling";
		level.infect_loadouts["axis_initial"]["loadoutPrimaryCamo"] 			= "none";
		level.infect_loadouts["axis_initial"]["loadoutPrimaryReticle"] 			= "none";
		level.infect_loadouts["axis_initial"]["loadoutSecondary"] 				= "none";
		level.infect_loadouts["axis_initial"]["loadoutSecondaryAttachment"] 	= "none";
		level.infect_loadouts["axis_initial"]["loadoutSecondaryAttachment2"] 	= "none";
		level.infect_loadouts["axis_initial"]["loadoutSecondaryBuff"] 			= "specialty_null";
		level.infect_loadouts["axis_initial"]["loadoutSecondaryCamo"] 			= "none";
		level.infect_loadouts["axis_initial"]["loadoutSecondaryReticle"] 		= "none";
		level.infect_loadouts["axis_initial"]["loadoutEquipment"] 				= CONST_INFECTED_LETHAL;
		level.infect_loadouts["axis_initial"]["loadoutOffhand"] 				= CONST_INFECTED_TACTICAL;
		level.infect_loadouts["axis_initial"]["loadoutStreakType"] 				= "assault";
		level.infect_loadouts["axis_initial"]["loadoutKillstreak1"] 			= "none";
		level.infect_loadouts["axis_initial"]["loadoutKillstreak2"] 			= "none";
		level.infect_loadouts["axis_initial"]["loadoutKillstreak3"] 			= "none";	
		level.infect_loadouts["axis_initial"]["loadoutJuggernaut"] 				= false;	
		level.infect_loadouts["axis_initial"]["loadoutPerks"] 					= [ "specialty_longersprint", "specialty_quickdraw", "specialty_quieter", "specialty_falldamage", "specialty_bulletaccuracy" ];
	}
	
	//	infected
	if ( isUsingDefaultClass( "axis", 0 ) )
	{
		level.infect_loadouts["axis"] = getMatchRulesSpecialClass( "axis", 0 );
		level.infect_loadouts["axis"]["loadoutStreakType"] = "assault";
		level.infect_loadouts["axis"]["loadoutKillstreak1"] = "none";
		level.infect_loadouts["axis"]["loadoutKillstreak2"] = "none";
		level.infect_loadouts["axis"]["loadoutKillstreak3"] = "none";		
	}	
	else
	{
		level.infect_loadouts["axis"]["loadoutPrimary"] 						= "iw6_knifeonly";
		level.infect_loadouts["axis"]["loadoutPrimaryAttachment"] 				= "none";
		level.infect_loadouts["axis"]["loadoutPrimaryAttachment2"] 				= "none";
		level.infect_loadouts["axis"]["loadoutPrimaryBuff"] 					= "specialty_null";
		level.infect_loadouts["axis"]["loadoutPrimaryCamo"] 					= "none";
		level.infect_loadouts["axis"]["loadoutPrimaryReticle"]					= "none";
		level.infect_loadouts["axis"]["loadoutSecondary"]						= "none";
		level.infect_loadouts["axis"]["loadoutSecondaryAttachment"] 			= "none";
		level.infect_loadouts["axis"]["loadoutSecondaryAttachment2"] 			= "none";
		level.infect_loadouts["axis"]["loadoutSecondaryBuff"] 					= "specialty_null";
		level.infect_loadouts["axis"]["loadoutSecondaryCamo"] 					= "none";
		level.infect_loadouts["axis"]["loadoutSecondaryReticle"] 				= "none";
		level.infect_loadouts["axis"]["loadoutEquipment"]						= CONST_INFECTED_LETHAL;
		level.infect_loadouts["axis"]["loadoutOffhand"] 						= CONST_INFECTED_TACTICAL;
		level.infect_loadouts["axis"]["loadoutStreakType"] 						= "assault";
		level.infect_loadouts["axis"]["loadoutKillstreak1"] 					= "none";
		level.infect_loadouts["axis"]["loadoutKillstreak2"] 					= "none";
		level.infect_loadouts["axis"]["loadoutKillstreak3"] 					= "none";		
		level.infect_loadouts["axis"]["loadoutJuggernaut"] 						= false;	
		level.infect_loadouts["axis"]["loadoutPerks"] 							= [ "specialty_longersprint", "specialty_quickdraw", "specialty_quieter", "specialty_falldamage" ];
	}
}

monitorSurvivalTime() // self == player
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "infected" );
	level endon( "game_ended" );
	
	while( true )
	{
		if( !level.infect_choseFirstInfected || !IsDefined( self.survivalStartTime ) || !isAlive(self) )
		{
			wait( 0.05 );
			continue;
		}
		
		self setSurvivalTime( false );
		wait( 1.0 );
	}
}

initSurvivalTime( infected )
{
	self setExtraScore0( 0 );
	
	if( IsDefined( infected ) && infected )
	{
		self notify( "infected" );
		self.extrascore1 = 1;
	}
}

setSurvivalTime( infected )
{
	// some times a player can join late and not get the survialStartTime set, so we'll use their spawnTime
	if( !IsDefined( self.survivalStartTime ) )
		self.survivalStartTime = self.spawnTime;
	
	// set the survival time and infected for the scoreboard
	timeSurvived = int( ( GetTime() - self.survivalStartTime ) / 1000 );
	if( timeSurvived > 999 )
		timeSurvived = 999;
	self setExtraScore0( timeSurvived );
	
	if( IsDefined( infected ) && infected )
	{
		self notify( "infected" );
		self.extrascore1 = 1;
	}
}
