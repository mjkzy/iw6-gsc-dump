#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

RESPAWN_DELAY = 4000;
RESPAWN_MIN_DELAY = 2000;

BATTLEBUDDY_SPAWN_STATUS_OK			= 0;
BATTLEBUDDY_SPAWN_STATUS_INCOMBAT	= -1;
BATTLEBUDDY_SPAWN_STATUS_BLOCKED	= -2;
BATTLEBUDDY_SPAWN_STATUS_ENEMY_LOS	= -3;
BATTLEBUDDY_SPAWN_STATUS_BUDDY_DEAD	= -4;

init()
{
	if ( level.teamBased
	    && !IsDefined( level.noBuddySpawns )
	   )
	{
		if ( !IsDefined( level.battleBuddyWaitList ) )
		{
			level.battleBuddyWaitList = [];
		}
		
		level thread onPlayerSpawned();
		level thread onPlayerConnect();
	}
}

onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		//this could be more efficient... check for fireTeam
		player thread onBattleBuddyMenuSelection();
		player thread onDisconnect();
	}
}

onPlayerSpawned()
{
	level endon("game_ended");
	
	for(;;)
	{
		level waittill( "player_spawned", player );
		
		if ( !IsAI( player ) )
		{
			// If we're coming back from a battle buddy spawn
			// try to match our stance with our buddy's
			if ( IsDefined( player.isSpawningOnBattleBuddy ) )
			{
				player.isSpawningOnBattleBuddy = undefined;
				
				if ( IsDefined( player.battleBuddy ) && IsAlive( player.battleBuddy ) )
				{
					if ( player.battleBuddy GetStance() != "stand" )
					{
						player SetStance( "crouch" );
					}
				}
			}
			
			if ( player wantsBattleBuddy() )
			{
				if ( !(player hasBattleBuddy()) )
				{
					player.firstSpawn = false;
					
					player findBattleBuddy();
				}
			}
			else
			{
				player leaveBattleBuddySystem();
			}
		}
	}
}

// onBattleBuddyMenuSelection
// wait for BB toggle from the LUI and change stuff accordingly
onBattleBuddyMenuSelection()	// self == player
{
	self endon( "disconnect" );
	level endon("game_ended");
	
	while ( true )
	{
		self waittill( "luinotifyserver", channel, value );
		
		if ( channel == "battlebuddy_update" )
		{
			newBBFlag = !(self wantsBattleBuddy() );
			self SetCommonPlayerData( "enableBattleBuddy", newBBFlag );
			if ( newBBFlag )
			{
				self findBattleBuddy();
			}
			else
			{
				self leaveBattleBuddySystem();
			}
		}
		else if ( channel == "team_select" 
				 && self.hasSpawned
				)
		{
			// we need to remove this player from whatever BB situation he's in now
			// but if he wants a BB on his new team, we need to preserve that
			// the respawn should handle the new pairing
			bbFlag = self wantsBattleBuddy();
			
			self leaveBattleBuddySystem();
			
			self SetCommonPlayerData( "enableBattleBuddy", bbFlag );
		}
	}
}

onDisconnect()	// self == player
{
	self waittill ( "disconnect" );
	
	self leaveBattleBuddySystemDisconnect();
}

waitForPlayerRespawnChoice()	// self == dead player
{
	self updateSessionState( "spectator" );
	self.forceSpectatorClient = self.battleBuddy getEntityNumber();
	self forceThirdPersonWhenFollowing();
	
	self SetClientOmnvar( "cam_scene_name", "over_shoulder" );
	self SetClientOmnvar( "cam_scene_lead", self.battleBuddy getEntityNumber() );
	
	self waitForBuddySpawnTimer();
}

watchForRandomSpawnButton()
{
	self endon( "disconnect" );
	self endon( "abort_battlebuddy_spawn" );
	self endon ( "teamSpawnPressed" );
	level endon("game_ended");
	
	self SetClientOmnvar( "ui_battlebuddy_showButtonPrompt", true );
	
	self NotifyOnPlayerCommand( "respawn_random", "+usereload" );
	self NotifyOnPlayerCommand( "respawn_random", "+activate" );
	
	// give a little space for the mashers to see the menu
	wait (0.5);
	
	self waittill( "respawn_random" );
	
	self SetClientOmnvar( "ui_battlebuddy_timer_ms", 0 );
	self SetClientOmnvar( "ui_battlebuddy_showButtonPrompt", false );
	
	self setupForRandomSpawn();
}

setupForRandomSpawn()	// self == player
{
	self clearBuddyMessage();
	
	self.isSpawningOnBattleBuddy = undefined;

	self notify( "randomSpawnPressed" );
	
	self cleanupBuddySpawn();
}

/*
watchForBuddyDeath()
{
	self endon( "disconnect" );
	self endon( "abort_battlebuddy_spawn" );
	self endon( "success_battlebuddy_spawn" );
	
	while ( isReallyAlive( self.battleBuddy ) )
	{
		wait ( 0.5 );
	}
	
	self notify( "abort_battlebuddy_spawn" );
}
*/

waitForBuddySpawnTimer()
{
	self endon( "randomSpawnPressed" );
	level endon("game_ended");
	
	self.isSpawningOnBattleBuddy = undefined;
	
	self thread watchForRandomSpawnButton();
	
	if ( IsDefined(self.battleBuddyRespawnTimeStamp) )
	{
		timeToWait = RESPAWN_DELAY - (GetTime() - self.battleBuddyRespawnTimeStamp);
		
		if (timeToWait < RESPAWN_MIN_DELAY)
		{
			timeToWait = RESPAWN_MIN_DELAY;
		}
	}
	else
	{
		timeToWait = RESPAWN_DELAY;
	}		
	
	result = self checkBuddySpawn();
	if ( result.status == BATTLEBUDDY_SPAWN_STATUS_OK )
	{
		self.battleBuddy SetClientOmnvar( "ui_battlebuddy_status", "incoming" );
	}
	else if ( result.status == BATTLEBUDDY_SPAWN_STATUS_INCOMBAT
		|| result.status == BATTLEBUDDY_SPAWN_STATUS_ENEMY_LOS )
	{
		self.battleBuddy SetClientOmnvar( "ui_battlebuddy_status", "err_combat" );
	}
	else
	{
		self.battleBuddy SetClientOmnvar( "ui_battlebuddy_status", "err_pos" );
	}
	
	self updateTimer( timeToWait );
	
	result = self checkBuddySpawn();
	while ( result.status != BATTLEBUDDY_SPAWN_STATUS_OK )
	{
		if ( result.status == BATTLEBUDDY_SPAWN_STATUS_INCOMBAT 
		   	|| result.status == BATTLEBUDDY_SPAWN_STATUS_ENEMY_LOS )
		{
			self SetClientOmnvar( "ui_battlebuddy_status", "wait_combat" );
			self.battleBuddy SetClientOmnvar( "ui_battlebuddy_status", "err_combat" );
		}
		else if ( result.status == BATTLEBUDDY_SPAWN_STATUS_BLOCKED )
		{
			self SetClientOmnvar( "ui_battlebuddy_status", "wait_pos" );
			self.battleBuddy SetClientOmnvar( "ui_battlebuddy_status", "err_pos" );
		}
		else if ( result.status == BATTLEBUDDY_SPAWN_STATUS_BUDDY_DEAD )
		{
			self cleanupBuddySpawn();
			return;
		}
		
		// not sure how expensive the safety checks are
		// but 1s delays can be kind of unresponsive
		wait ( 0.5 );
		result = self checkBuddySpawn();
	}
	
	self.isSpawningOnBattleBuddy = true;
	self thread displayBuddySpawnSuccessful();
	
	self playLocalSound( "copycat_steal_class" );
	self notify ( "teamSpawnPressed" );
}

clearBuddyMessage()
{
	self SetClientOmnvar( "ui_battlebuddy_status", "none" );
	self SetClientOmnvar( "ui_battlebuddy_showButtonPrompt", false );
	
	if ( IsDefined( self.battleBuddy ) )
	{
		self.battleBuddy SetClientOmnvar( "ui_battlebuddy_status", "none" );
	}
}

displayBuddyStatusMessage( messageID )	// self == player who sees message
{
	self setLowerMessage( "waiting_info", messageID, undefined, undefined, undefined, undefined, undefined, undefined, true );
}

displayBuddySpawnSuccessful()
{
	self clearBuddyMessage();
	
	if ( IsDefined( self.battleBuddy ) )
	{
		self.battleBuddy SetClientOmnvar( "ui_battlebuddy_status", "on_you" );
		wait (1.5);	
		self.battleBuddy SetClientOmnvar( "ui_battlebuddy_status", "none" );
	}
}

checkBuddySpawn()	// self == player
{
	result = SpawnStruct();
	
	if ( !IsDefined( self.battleBuddy ) || !IsAlive( self.battleBuddy ) )
	{
		result.status = BATTLEBUDDY_SPAWN_STATUS_BUDDY_DEAD;
		return result;
	}
	
	if( maps\mp\gametypes\_spawnscoring::isPlayerInCombat( self.battleBuddy, true ) )
	{
		result.status = BATTLEBUDDY_SPAWN_STATUS_INCOMBAT;
	}
	else
	{
		spawnLocation = maps\mp\gametypes\_spawnscoring::findSpawnLocationNearPlayer( self.battleBuddy );
		
		if( IsDefined(spawnLocation) )
		{
			trace = SpawnStruct();
			trace.maxTraceCount = 18;
			trace.currentTraceCount = 0;
	
			if( !maps\mp\gametypes\_spawnscoring::isSafeToSpawnOn( self.battleBuddy, spawnLocation, trace) )
			{
				result.status = BATTLEBUDDY_SPAWN_STATUS_ENEMY_LOS;
			}
			else
			{
				// we have a valid location, let's go!
				result.status = BATTLEBUDDY_SPAWN_STATUS_OK;
				result.origin = spawnLocation;
				dirToBuddy = self.battleBuddy.origin - spawnLocation;
				result.angles = (0, self.battleBuddy.angles[1], 0);
			}
		}
		else
		{
			result.status = BATTLEBUDDY_SPAWN_STATUS_BLOCKED;
		}
	}
	
	return result;
}

cleanupBuddySpawn()
{
	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
	self.forceSpectatorClient = -1;
	self updateSessionState( "dead" );
	self disableForceThirdPersonWhenFollowing();
	// this should get cleaned up in the respawn
	// self.isSpawningOnBattleBuddy = undefined;
	
	self SetClientOmnvar( "cam_scene_name", "unknown" );
	
	self clearBuddyMessage();
	
	self notify("abort_battlebuddy_spawn");
}

updateTimer( timeToWait )
{
	self endon( "disconnect" );
    self endon( "abort_battlebuddy_spawn" );
	self endon ( "teamSpawnPressed" );
	
	timeInSeconds = timeToWait * 0.001;
	self SetClientOmnvar( "ui_battlebuddy_timer_ms", timeToWait + GetTime() );
	
	wait ( timeInSeconds );
	
	self SetClientOmnvar( "ui_battlebuddy_timer_ms", 0 );
}

/* --------------------------------------------------------------------------
 * Manager functions
 * Used to pair up players as they spawn
 */
 
wantsBattleBuddy()	// self == player
{
	return self GetCommonPlayerData( "enableBattleBuddy" );
}

hasBattleBuddy()	// self == player
{
	return IsDefined( self.battleBuddy );
}
 
needsBattleBuddy()	// self == player
{
	return (self wantsBattleBuddy() 
		    && ! self hasBattleBuddy() );
}

isValidBattleBuddy( otherPlayer )	// self == player
{
	return ( self != otherPlayer
		    && self.team == otherPlayer.team
		    && otherPlayer needsBattleBuddy()
		    );
}

canBuddySpawn()	// self == player
{
	return ( self hasBattleBuddy() && isReallyAlive( self.battleBuddy ) );
}

pairBattleBuddy( otherPlayer )	// self == player
{
	removeFromBattleBuddyWaitList( otherPlayer );
	
	self.battleBuddy = otherPlayer;
	otherPlayer.battleBuddy = self;
	
	self SetClientOmnvar( "ui_battlebuddy_idx", otherPlayer GetEntityNumber() );
	otherPlayer SetClientOmnvar( "ui_battlebuddy_idx", self GetEntityNumber() );
}

getWaitingBattleBuddy()	// self == player
{
	return ( level.battleBuddyWaitList[ self.team ] );
}

// there should only be one player on the wait list at any time
addToBattleBuddyWaitList( player )
{
	if ( !IsDefined( level.battleBuddyWaitList[ player.team ] ) )
	{
		level.battleBuddyWaitList[ player.team ] = player;
	}
	else if ( level.battleBuddyWaitList[ player.team ] != player )
	{
		Print( "There is already a player: " + (level.battleBuddyWaitList[ player.team ] GetEntityNumber()) + " but trying to add: " + (player GetEntityNumber()));
	}
}

removeFromBattleBuddyWaitList( player )
{
	if ( IsDefined( player.team )
	    && IsDefined( level.battleBuddyWaitList[ player.team ] )
	    && player == level.battleBuddyWaitList[ player.team ] )
	{
		level.battleBuddyWaitList[ player.team ] = undefined;
	}
}

findBattleBuddy()	// self == player
{
	// look for a buddy inside the private party
	if ( level.onlineGame )
	{
		self.fireTeamMembers = self GetFireteamMembers();;
		if ( self.fireTeamMembers.size >= 1 )
		{
			foreach ( otherPlayer in self.fireTeamMembers )
			{
				if ( self isValidBattleBuddy( otherPlayer ) )
				{
					self pairBattleBuddy( otherPlayer );
				}
			}
		}
	}
	
	// we couldn't find a match among the fireteam members
	// so find one from the overflow
	if ( !(self hasBattleBuddy()) )
	{
		// guarantee that the player is on the same team and wants a BB
		// need to make sure we update this list if the player switches teams or untoggles his BB status
		otherPlayer = self getWaitingBattleBuddy();
		if ( IsDefined( otherPlayer ) && self isValidBattleBuddy( otherPlayer ) )
		{
			self pairBattleBuddy( otherPlayer );
		}
		else
		{
			addToBattleBuddyWaitList( self );
			self SetClientOmnvar( "ui_battlebuddy_idx", -1 );
		}
	}
}

clearBattleBuddy()
{
	if ( !IsAlive( self ) )
	{
		self setupForRandomSpawn();
	}
	
	self SetClientOmnvar( "ui_battlebuddy_idx", -1 );
	self.battleBuddy = undefined;
}

leaveBattleBuddySystem()	// self == player
{
	if ( self hasBattleBuddy() )
	{
		otherPlayer = self.battleBuddy;
		
		self clearBattleBuddy();
		self SetCommonPlayerData( "enableBattleBuddy", false );
		
		otherPlayer clearBattleBuddy();
		otherPlayer findBattleBuddy();
	}
	else
	{
		// must make sure that the teams are correct in the team_select case
		removeFromBattleBuddyWaitList( self );
		// !!! hack. Can't call SetClientDvar on removed entity
		// according to UAV code, birth_time is one way to id removed entities
		self SetClientOmnvar( "ui_battlebuddy_idx", -1 );
	}
}

// we need a specialized function, unfortunately, because disconnected players don't have all the variables anymore
// and we can't cleanly distinguished a removed entity and a newly spawned player
// we *could* have a player wait on his buddy's disconnect, but it won't handle the case 
leaveBattleBuddySystemDisconnect()	// self == player
{
	if ( self hasBattleBuddy() )
	{
		otherPlayer = self.battleBuddy;
		otherPlayer clearBattleBuddy();
		otherPlayer findBattleBuddy();
		
		otherPlayer clearBuddyMessage();
	}
	else
	{
		// ensure that this guy is not being tracked any more
		foreach ( teamName, waitingPlayer in level.battleBuddyWaitList )
		{
			if ( waitingPlayer == self)
			{
				level.battleBuddyWaitList[ teamName ] = undefined;
				break;
			}
		}
	}
}
