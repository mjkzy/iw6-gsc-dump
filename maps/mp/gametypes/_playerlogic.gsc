#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

CONST_PREDICT_SPAWN_POINT = false;

TimeUntilWaveSpawn( minimumWait )
{
	if ( !self.hasSpawned )
		return 0;

	// the time we'll spawn if we only wait the minimum wait.
	earliestSpawnTime = gettime() + minimumWait * 1000;
	
	lastWaveTime = level.lastWave[self.pers["team"]];
	waveDelay = level.waveDelay[self.pers["team"]] * 1000;
	
	// the number of waves that will have passed since the last wave happened, when the minimum wait is over.
	numWavesPassedEarliestSpawnTime = (earliestSpawnTime - lastWaveTime) / waveDelay;
	// rounded up
	numWaves = ceil( numWavesPassedEarliestSpawnTime );
	
	timeOfSpawn = lastWaveTime + numWaves * waveDelay;

	// don't push our spawn out because we watched killcam
	if ( isDefined( self.respawnTimerStartTime ) )
	{
		timeAlreadyPassed = (gettime() - self.respawnTimerStartTime) / 1000.0;
		
		if ( self.respawnTimerStartTime < lastWaveTime )
			return 0;
	}
	
	// avoid spawning everyone on the same frame
	if ( isdefined( self.waveSpawnIndex ) )
		timeOfSpawn += 50 * self.waveSpawnIndex;
	
	return (timeOfSpawn - gettime()) / 1000;
}

TeamKillDelay()
{
	teamKills = self.pers["teamkills"];

	if ( level.maxAllowedTeamKills < 0 || teamkills <= level.maxAllowedTeamKills )
		return 0;

	exceeded = (teamkills - level.maxAllowedTeamKills);
	return maps\mp\gametypes\_tweakables::getTweakableValue( "team", "teamkillspawndelay" ) * exceeded;
}


TimeUntilSpawn( includeTeamkillDelay )
{
	if ( (level.inGracePeriod && !self.hasSpawned) || level.gameended )
		return 0;
	
	respawnDelay = 0;
	if ( self.hasSpawned )
	{
		result = self [[level.onRespawnDelay]]();
		if ( isDefined( result ) )
			respawnDelay = result;
		else
			respawnDelay = getDvarInt( "scr_" + level.gameType + "_playerrespawndelay" );
		
		if ( includeTeamkillDelay && isDefined( self.pers["teamKillPunish"] ) && self.pers["teamKillPunish"] )
			respawnDelay += TeamKillDelay();
		
		if ( isDefined( self.respawnTimerStartTime ) )
		{
			timeAlreadyPassed = (gettime() - self.respawnTimerStartTime) / 1000.0;
			respawnDelay -= timeAlreadyPassed;
			if ( respawnDelay < 0 )
				respawnDelay = 0;
		}
		
		// Spawning with tactical insertion
    	if ( isDefined( self.setSpawnPoint) )
    		respawnDelay += level.tiSpawnDelay;
		
	}

	waveBased = (getDvarInt( "scr_" + level.gameType + "_waverespawndelay" ) > 0);

	if ( waveBased )
		return self TimeUntilWaveSpawn( respawnDelay );
	
	return respawnDelay;
}


maySpawn()
{
	if ( getGametypeNumLives() || isDefined( level.disableSpawning ) )
	{
		if ( isDefined( level.disableSpawning ) && level.disableSpawning )
			return false;

		if ( isDefined( self.pers["teamKillPunish"] ) && self.pers["teamKillPunish"] )
			return false;
		
		if ( self.pers["lives"] <= 0 && gameHasStarted() )
		{
			return false;
		}
		else if ( gameHasStarted() )
		{
			// disallow spawning for late comers
			if ( !level.inGracePeriod && !self.hasSpawned && ( IsDefined( level.allowLateComers ) && !level.allowLateComers ) )
			{
				// Exception for reinforce late comers
				// The reason why we are checking false, is because we still want late comers to remain dead until they are manually spawned in through a team captured flag
				if ( IsDefined( self.siegeLateComer ) && !self.siegeLateComer )
					return true;
				
				return false;
			}
		}
	}

	return true;
}


spawnClient()
{
	self endon("becameSpectator");
	assert(	isDefined( self.team ) );
	assert(	isValidClass( self.class ) );
	
	if ( isDefined( self.waitingToSelectClass ) && self.waitingToSelectClass )
		self waittill( "okToSpawn" );
	
	//	iw5, new game modes cause team switch on death
	//		- allow death flow to happen as previous team, 
	//		  then change team and do spawn flow 
	if ( isDefined( self.addToTeam ) )
	{
		self maps\mp\gametypes\_menus::addToTeam( self.addToTeam );
		self.addToTeam = undefined;
	}
	
	if ( !self maySpawn() )
	{
		// wait a frame to prevent stack overflow in S&D and S&R 
		// (where damage triggers spectator spawn immediately from within damage call)
		wait 0.05; 

		currentorigin =	self.origin;
		currentangles =	self.angles;
		
		self notify ( "attempted_spawn" );

		self_pers_teamKillPunish = self.pers["teamKillPunish"];
		if ( isDefined( self_pers_teamKillPunish ) && self_pers_teamKillPunish )
		{
			self.pers["teamkills"] = max( self.pers["teamkills"] - 1, 0 );
			setLowerMessage( "friendly_fire", &"MP_FRIENDLY_FIRE_WILL_NOT" );

			if ( !self.hasSpawned && self.pers["teamkills"] <= level.maxAllowedTeamkills )
				self.pers["teamKillPunish"] = false;

		}
		else if ( isRoundBased() && !isLastRound() )
		{
			if ( IsDefined( self.tagAvailable ) && self.tagAvailable )
			{
				setLowerMessage( "spawn_info", game["strings"]["spawn_tag_wait"] );
			}
			else if ( level.gameType == "siege" )
			{
				setLowerMessage( "spawn_info", game["strings"]["spawn_flag_wait"] );
			}
			else
			{
				setLowerMessage( "spawn_info", game["strings"]["spawn_next_round"] );
			}
			self thread removeSpawnMessageShortly( 3.0 );
		}

		if ( self.sessionstate != "spectator" )
			currentorigin = currentorigin + (0, 0, 60);

		self thread	spawnSpectator( currentorigin, currentangles );
		return;
	}
	
	if ( self.waitingToSpawn )
		return;
		
	self.waitingToSpawn = true;
	
	self waitAndSpawnClient();
	
	if ( isdefined( self ) )
		self.waitingToSpawn = false;
}


waitAndSpawnClient()
{
	self endon ( "disconnect" );
	self endon ( "end_respawn" );
	level endon ( "game_ended" );
	
	self notify ( "attempted_spawn" );

	spawnedAsSpectator = false;
	
	self_pers_teamKillPunish = self.pers["teamKillPunish"];
	if ( isDefined( self_pers_teamKillPunish ) && self_pers_teamKillPunish )
	{
		teamKillDelay = TeamKillDelay();
		
		if ( teamKillDelay > 0 )
		{
			setLowerMessage( "friendly_fire", &"MP_FRIENDLY_FIRE_WILL_NOT", teamKillDelay, 1, true );
			
			self thread	respawn_asSpectator( self.origin + (0, 0, 60), self.angles );
			spawnedAsSpectator = true;
			
			wait( teamKillDelay );
			clearLowerMessage( "friendly_fire" );
			self.respawnTimerStartTime = gettime();
		}
		
		self.pers["teamKillPunish"] = false;
	}
	else if ( !is_aliens() && TeamKillDelay() )
	{
		self.pers["teamkills"] = max( self.pers["teamkills"] - 1, 0 );
	}
	
	// for missiles, helicopters, ac130, etc...
	if ( self isUsingRemote() )
	{
		//	- when killed while using a remote, the player's location remains at their corpse
		//	- the using remote variable is cleared before they are actually respawned and moved
		//	- if you want control over proximity related events with relation to their corpse location
		//    between the clearing of the remote variables and their actual respawning somewhere else use this variable	
		self.spawningAfterRemoteDeath = true;
		self.deathPosition = self.origin;
		
		self waittill ( "stopped_using_remote" );
	}
	
	if ( !isdefined( self.waveSpawnIndex ) && isdefined( level.wavePlayerSpawnIndex[self.team] ) )
	{
		self.waveSpawnIndex = level.wavePlayerSpawnIndex[self.team];
		level.wavePlayerSpawnIndex[self.team]++;
	}
	
	timeUntilSpawn = TimeUntilSpawn( false );
	
	self thread predictAboutToSpawnPlayerOverTime( timeUntilSpawn );
	
	if ( timeUntilSpawn > 0 )
	{
		// spawn player into spectator on death during respawn delay, if he switches teams during this time, he will respawn next round
		setLowerMessage( "spawn_info", game["strings"]["waiting_to_spawn"], timeUntilSpawn, 1, true );
		
		if ( !spawnedAsSpectator )
			self thread	respawn_asSpectator( self.origin + (0, 0, 60), self.angles );
		spawnedAsSpectator = true;
		
		self waitForTimeOrNotify( timeUntilSpawn, "force_spawn" );
		
		self notify("stop_wait_safe_spawn_button");
	}
	
	if ( self needsButtonToRespawn() )
	{
		setLowerMessage( "spawn_info", game["strings"]["press_to_spawn"], undefined, undefined, undefined, undefined, undefined, undefined, true );
		
		if ( !spawnedAsSpectator )
			self thread	respawn_asSpectator( self.origin + (0, 0, 60), self.angles );
		spawnedAsSpectator = true;
		
		self waitRespawnButton();
	}
	
	// do not wait after this point
	
	self.waitingToSpawn = false;
	
	self clearLowerMessage( "spawn_info" );
	
	self.waveSpawnIndex = undefined;
	
	self thread	spawnPlayer();
}


needsButtonToRespawn()
{
	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "player", "forcerespawn" ) != 0 )
		return false;
	
	if ( !self.hasSpawned )
		return false;
	
	waveBased = (getDvarInt( "scr_" + level.gameType + "_waverespawndelay" ) > 0);
	if ( waveBased )
		return false;
	
	if ( self.wantSafeSpawn )
		return false;
	
	return true;
}


waitRespawnButton()
{
	self endon("disconnect");
	self endon("end_respawn");

	while (1)
	{
		if ( self useButtonPressed() )
			break;

		wait .05;
	}
}


removeSpawnMessageShortly( delay )
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	waittillframeend; // so we don't endon the end_respawn from spawning as a spectator
	
	self endon("end_respawn");
	
	wait delay;
	
	self clearLowerMessage( "spawn_info" );
}


lastStandRespawnPlayer()
{
	self LastStandRevive();

	if ( self _hasPerk( "specialty_finalstand" ) && !level.dieHardMode )
		self _unsetPerk( "specialty_finalstand" );

	if ( level.dieHardMode )
		self.headicon = "";
	
	self setStance( "crouch" );	
	self.revived = true;
	
	self notify ( "revive" );
	
	// should only be defined if level.diehardmode
	if ( isDefined( self.standardmaxHealth ) )
		self.maxHealth = self.standardMaxHealth;
	
	self.health = self.maxHealth;
	self _enableUsability();
	
	if ( game["state"] == "postgame" )
	{
		assert( !level.intermission );
		// We're in the victory screen, but before intermission
		self maps\mp\gametypes\_gamelogic::freezePlayerForRoundEnd();
	}
}

getDeathSpawnPoint()
{
	spawnpoint = spawn( "script_origin", self.origin );
	spawnpoint hide();
	spawnpoint.angles = self.angles;
	return spawnpoint;

}

showSpawnNotifies()
{
	if ( isDefined( game["defcon"] ) )
		thread maps\mp\gametypes\_hud_message::defconSplashNotify( game["defcon"], false );	

	if ( !is_aliens() && self isRested() )
		thread maps\mp\gametypes\_hud_message::splashNotify( "rested" );
}


predictAboutToSpawnPlayerOverTime( preduration )
{
	if( !CONST_PREDICT_SPAWN_POINT )
	{
		return;
	}
		
	self endon( "disconnect" );
	self endon( "spawned" );
	self endon( "used_predicted_spawnpoint" );
	self notify( "predicting_about_to_spawn_player" );
	self endon( "predicting_about_to_spawn_player" );
	
	if ( preduration <= 0 )
		return; // no point predicting if no time will pass. (if time until spawn is unknown, use 0.1)
	
	if ( preduration > 1.0 )
		wait preduration - 1.0;
	
	self predictAboutToSpawnPlayer();
	
	self PredictStreamPos( self.predictedSpawnPoint.origin + (0,0,60), self.predictedSpawnPoint.angles );
	self.predictedSpawnPointTime = gettime();
	
	for ( i = 0; i < 30; i++ )
	{
		wait .4; // this time is carefully selected: we want it as long as possible, but we want the loop to iterate about .1 to .3 seconds before people spawn for our final check
		
		prevPredictedSpawnPoint = self.predictedSpawnPoint;
		self predictAboutToSpawnPlayer();
		
		if ( self.predictedSpawnPoint != prevPredictedSpawnPoint )
		{
			self PredictStreamPos( self.predictedSpawnPoint.origin + (0,0,60), self.predictedSpawnPoint.angles );
			self.predictedSpawnPointTime = gettime();
		}
	}
}

predictAboutToSpawnPlayer()
{
	assert( !isReallyAlive( self ) );
	
	// test predicting spawnpoints to see if we can eliminate streaming pops
	
	if ( self TimeUntilSpawn( true ) > 1.0 )
	{
		self.predictedSpawnPoint = getSpectatePoint();
		return;
	}
	
	if ( isDefined( self.setSpawnPoint ) )
	{
		self.predictedSpawnPoint = self.setSpawnPoint;
		return;
	}
	spawnPoint = self [[level.getSpawnPoint]]();
	self.predictedSpawnPoint = spawnPoint;
}

checkPredictedSpawnpointCorrectness( spawnpointorigin )
{
	/#
	if( !CONST_PREDICT_SPAWN_POINT )
	{
		return;
	}
		
	if ( !isdefined( level.spawnpointPrediction ) )
	{
		level.spawnpointPrediction = spawnstruct();
		level.spawnpointPrediction.failures = 0;
		for ( i = 0; i < 7; i++ )
			level.spawnpointPrediction.buckets[i] = 0;
	}
	
	if ( !isdefined( self.predictedSpawnPoint ) )
	{
		if ( getDvarInt( "g_debugPredictedSpawnPoint" ) )
		{
			println( "Failed to predict spawn for player " + self.name + " at " + spawnpointorigin );
		}
		level.spawnpointPrediction.failures++;
	}
	else
	{
		dist = distance( self.predictedSpawnPoint.origin, spawnpointorigin );
		if ( dist <= 0 )
			level.spawnpointPrediction.buckets[0]++;
		else if ( dist <= 128 )
			level.spawnpointPrediction.buckets[1]++;
		else if ( dist <= 256 )
			level.spawnpointPrediction.buckets[2]++;
		else if ( dist <= 512 )
			level.spawnpointPrediction.buckets[3]++;
		else if ( dist <= 1024 )
			level.spawnpointPrediction.buckets[4]++;
		else if ( dist <= 2048 )
			level.spawnpointPrediction.buckets[5]++;
		else
			level.spawnpointPrediction.buckets[6]++;
		
		if ( getDvarInt( "g_debugPredictedSpawnPoint" ) )
		{
			if ( dist > 0 )
				println( "Predicted player " + self.name + " would spawn at " + self.predictedSpawnPoint.origin + ", but spawned " + dist + " units away at " + spawnpointorigin );
			else
				println( "Predicted " + self.name + "'s spawn " + ((gettime() - self.predictedSpawnPointTime) / 1000) + " seconds ahead of time" );
		}
	}
	#/
	
	self notify( "used_predicted_spawnpoint" );
	self.predictedSpawnPoint = undefined;
}

percentage( a, b )
{
	return a + " (" + int(a / b * 100) + "%)";
}

printPredictedSpawnpointCorrectness()
{
	/#
	if ( !isdefined( level.spawnpointPrediction ) )
		return;
	
	total = level.spawnpointPrediction.failures;
	for ( i = 0; i < 7; i++ )
		total += level.spawnpointPrediction.buckets[i];
	
	if ( total <= 0 )
		return;
	
	println( "****** Spawnpoint Prediction *******" );
	println( "There were " + total + " spawns. " + percentage( level.spawnpointPrediction.failures, total ) + " failed to be predicted." );
	
	total -= level.spawnpointPrediction.failures;
	if ( total > 0 )
	{
		println( "Out of the predicted ones..." );
		
		println( " " + percentage( level.spawnpointPrediction.buckets[0], total ) + " were perfect" );
		println( " " + percentage( level.spawnpointPrediction.buckets[1], total ) + " were within 128 units" );
		println( " " + percentage( level.spawnpointPrediction.buckets[2], total ) + " were within 256 units" );
		println( " " + percentage( level.spawnpointPrediction.buckets[3], total ) + " were within 512 units" );
		println( " " + percentage( level.spawnpointPrediction.buckets[4], total ) + " were within 1024 units" );
		println( " " + percentage( level.spawnpointPrediction.buckets[5], total ) + " were within 2048 units" );
		println( " " + percentage( level.spawnpointPrediction.buckets[6], total ) + " were beyond 2048 units" );
	}
	
	println( "*************" );
	#/
}

getSpawnOrigin( spawnpoint )
{
	if ( !positionWouldTelefrag( spawnpoint.origin ) )
		return spawnpoint.origin;
	
	if ( !isdefined( spawnpoint.alternates ) )
		return spawnpoint.origin;
	
	foreach( alternate in spawnpoint.alternates )
	{
		if ( !positionWouldTelefrag( alternate ) )
			return alternate;
	}
	
	return spawnpoint.origin;
}

tiValidationCheck()
{
	if ( !isDefined( self.setSpawnPoint ) )
		return false;
		
	carePackages = getEntArray( "care_package", "targetname" );
	
	foreach ( package in carePackages )
	{
		if ( distance( package.origin, self.setSpawnPoint.playerSpawnPos ) > 64 )
			continue;
		
		if ( isDefined( package.owner ) )
			self maps\mp\gametypes\_hud_message::playerCardSplashNotify( "destroyed_insertion", package.owner );

		maps\mp\perks\_perkfunctions::deleteTI( self.setSpawnpoint );
		return false;
	}

	if ( !BulletTracePassed( self.setSpawnPoint.origin + (0,0,60), self.setSpawnPoint.origin, false, self.setSpawnPoint ) )
		return false;

	traceStartPos = self.setSpawnPoint.origin + (0, 0, 1);
	traceEndPos = PlayerPhysicsTrace( traceStartPos, self.setSpawnPoint.origin + (0, 0, -16) );
	if ( traceStartPos[2] == traceEndPos[2] )
	{
		//In solid, trace failed
		return false;
	}
	
	return true;
}

//part of spawn amortization for multiple clients attempting a same frame spawn.
spawningClientThisFrameReset()
{
	self notify ( "spawningClientThisFrameReset" );
	self endon ( "spawningClientThisFrameReset" );
	
	wait 0.05;
	level.numPlayersWaitingToSpawn--;
}


spawnPlayer( fauxSpawn )
{
	self endon( "disconnect" );
	self endon( "joined_spectators" );
	self notify( "spawned" );
	self notify( "end_respawn" );
	self notify( "started_spawnPlayer" );
	
	if ( !isDefined( fauxSpawn ) )
		fauxSpawn = false;
	
	spawnPoint 	= undefined;
	self.TI_spawn = false;
	
	// reset the omnvar to make sure the team/class select menu doesn't show again after a reload
	self SetClientOmnvar( "ui_options_menu", 0 );
		
	// reset the hud shake because you could spawn in with the value set to true and you get a small shake when you shouln't
	self SetClientOmnvar( "ui_hud_shake", false );
	
	// reset the last kill streak splash displayed ( e.g Player got 5 kills! )
	self.lastKillSplash = undefined;
		
	//Only Amortize if it is in the match (not beginning of the round)
	if ( !level.inGracePeriod && !self.hasDoneCombat )
	{
		//this is to track and amortize number of spawns per frame
		level.numPlayersWaitingToSpawn++;
		if ( level.numPlayersWaitingToSpawn > 1 )
		{
			/#
				println( "spawning more than one client this frame" );
			#/
			self.waitingToSpawnAmortize = true;	
			wait 0.05 * (level.numPlayersWaitingToSpawn - 1);
		}
		
		self thread spawningClientThisFrameReset();
		self.waitingToSpawnAmortize = false;
	}

	// It's possible when changing teams not to have our own customization loaded, wait until that's done
	if ( !self HasLoadedCustomizationPlayerView( self ) )
	{
		customizationTimeout = gettime() + 5000;

		println( "Waiting for client to load viewarms " + self.name + " at time " + gettime() );

		self.waitingToSpawnAmortize = true;
		wait 0.1;

		while ( !self HasLoadedCustomizationPlayerView( self ) )
		{
			wait 0.1;

			// At this point, we'll show a default hand for this spawn
			if ( gettime() > customizationTimeout )
				break;
		}

		println( "Finished waiting for client to load viewarms " + self.name + " at time " + gettime() );

		self.waitingToSpawnAmortize = false;
	}

	if ( IsDefined( self.forceSpawnOrigin ) )
	{
		spawnOrigin = self.forceSpawnOrigin;
		self.forceSpawnOrigin = undefined;
		
		if ( IsDefined( self.forceSpawnAngles ) )
		{
			spawnAngles = self.forceSpawnAngles;
			self.forceSpawnAngles = undefined;
		}
		else
		{
			spawnAngles = (0,RandomFloatRange(0,360),0);
		}
	}
	else if ( isDefined( self.setSpawnPoint ) && ( isDefined( self.setSpawnPoint.notTI ) || self tiValidationCheck() ) )
	{
		spawnPoint = self.setSpawnPoint;

		if ( !isDefined( self.setSpawnPoint.notTI ) )
		{
			self.TI_spawn = true;
			self playLocalSound( "tactical_spawn" );
			
			if( level.multiTeamBased )
			{
				foreach( teamname in level.teamNameList )
				{
					if( teamname != self.team )
					{
						self playSoundToTeam( "tactical_spawn", teamname );
					}
				}
			}
			else if ( level.teamBased )
				self playSoundToTeam( "tactical_spawn", level.otherTeam[self.team] );
			else
				self playSound( "tactical_spawn" );
		}
		
		//check for vehicles and kill them
		foreach ( tank in level.ugvs )
		{
			if ( DistanceSquared( tank.origin, spawnPoint.playerSpawnPos ) < 1024 )//32^2
				tank notify( "damage", 5000, tank.owner, ( 0, 0, 0 ), ( 0, 0, 0 ), "MOD_EXPLOSIVE", "", "", "", undefined, "killstreak_emp_mp" );
		}

		assert( isDefined( spawnPoint.playerSpawnPos ) );
		assert( isDefined( spawnPoint.angles ) );
			
		spawnOrigin = self.setSpawnPoint.playerSpawnPos;
		spawnAngles = self.setSpawnPoint.angles;		

		if ( isDefined( self.setSpawnPoint.enemyTrigger ) )
			 self.setSpawnPoint.enemyTrigger Delete();
		
		self.setSpawnPoint delete();

		spawnPoint = undefined;
	}//FIRE TEAMS!!!
    else if( isDefined( self.isSpawningOnBattleBuddy ) && isDefined( self.battleBuddy ) )
    {
    	spawnOrigin = undefined;
    	spawnAngles = undefined;
    	result = self maps\mp\gametypes\_battlebuddy::checkBuddySpawn();
    	if ( result.status == 0 )
    	{
    		spawnOrigin = result.origin; 
			spawnAngles = result.angles;
    	}
    	else
    	{
    		// error!
    		print( "BattleBuddy Spawn error: " + result.status );
    		
    		// fall back to a default position
    		spawnPoint = self [[level.getSpawnPoint]]();
    		spawnOrigin = spawnPoint.origin;
			spawnAngles = spawnPoint.angles;
    	}
    	self maps\mp\gametypes\_battlebuddy::cleanupBuddySpawn();

		self SetClientOmnvar( "cam_scene_name", "battle_spawn" );
		self SetClientOmnvar( "cam_scene_lead", self.battleBuddy getEntityNumber() );
		self SetClientOmnvar( "cam_scene_support", self getEntityNumber() );
		
    }//HELI SPAWN ALLIES
    else if( isDefined(self.heliSpawning) && ( !isDefined( self.firstSpawn ) || isDefined( self.firstSpawn ) && self.firstSpawn ) && level.prematchPeriod > 0 && self.team == "allies")
    {
    	while ( !isDefined (level.alliesChopper ) )
    		wait 0.1;
    	
    	spawnOrigin = level.alliesChopper.origin;
    	spawnAngles = level.alliesChopper.angles;
    	
    	self.firstSpawn = false;
    	
    }
    else if( isDefined(self.heliSpawning) && ( !isDefined( self.firstSpawn ) || isDefined( self.firstSpawn ) && self.firstSpawn ) && level.prematchPeriod > 0 && self.team == "axis")
    {
    	while ( !isDefined (level.axisChopper ) )
    		wait 0.1;
    	
    	spawnOrigin = level.axisChopper.origin;
    	spawnAngles = level.axisChopper.angles;
    	
    	self.firstSpawn = false;
    	
    }
	else
	{
		spawnPoint = self [[level.getSpawnPoint]]();

		assert( isDefined( spawnPoint ) );
		assert( isDefined( spawnPoint.origin ) );
		assert( isDefined( spawnPoint.angles ) );

		spawnOrigin = spawnPoint.origin;
		spawnAngles = spawnPoint.angles;
	}
	
	
	self setSpawnVariables();

	/#
	if ( !getDvarInt( "scr_forcerankedmatch" ) && !bot_is_fireteam_mode() )
		assert( (level.teamBased && ( !allowTeamChoice() || self.sessionteam == self.team )) || (!level.teamBased && self.sessionteam == "none") );
	#/

	hadSpawned = self.hasSpawned;

	self.fauxDead = undefined;

	if ( !fauxSpawn )
	{
		self.killsThisLife = [];
		self.killsThisLifePerWeapon = [];
	
		self updateSessionState( "playing" );
		self ClearKillcamState();
		self.cancelkillcam = undefined;
		
		self.maxhealth = maps\mp\gametypes\_tweakables::getTweakableValue( "player", "maxhealth" );
		self.health = self.maxhealth;
		
		self.friendlydamage = undefined;
		self.hasSpawned = true;
		self.spawnTime = getTime();
		self.wasTI = !isDefined( spawnPoint );
		self.afk = false;
		self.damagedPlayers = [];
		self.killStreakScaler = 1;
		self.xpScaler = 1;
		self.objectiveScaler = 1;
		self.clampedHealth = undefined;
		self.shieldDamage = 0;
		self.shieldBulletHits = 0;
		self.recentShieldXP = 0;
	}
	
	self.moveSpeedScaler = 1;
	self.inLastStand = false;
	self.lastStand = undefined;
	self.infinalStand = undefined;
	self.inC4Death = undefined;
	self.disabledWeapon = 0;
	self.disabledWeaponSwitch = 0;
	self.disabledOffhandWeapons = 0;
	self resetUsability();

	if ( !fauxSpawn )
	{
		// trying to stop killstreaks from targeting the newly spawned
		self.avoidKillstreakOnSpawnTimer = 5.0;
	
		if ( !is_aliens() )
		{
			self_pers_lives = self.pers["lives"];
			if ( self_pers_lives == getGametypeNumLives() )
			{
				maps\mp\gametypes\_playerlogic::addToLivesCount();
			}
			
			if ( self_pers_lives )
				self.pers["lives"]--;
		}
	
		self maps\mp\gametypes\_playerlogic::addToAliveCount();
	
		if ( !hadSpawned || gameHasStarted() || (gameHasStarted() && level.inGracePeriod && self.hasDoneCombat) )
			self maps\mp\gametypes\_playerlogic::removeFromLivesCount();
	
		if ( !self.wasAliveAtMatchStart )
		{
			acceptablePassedTime = 20;
			if ( getTimeLimit() > 0 && acceptablePassedTime < getTimeLimit() * 60 / 4 )
				acceptablePassedTime = getTimeLimit() * 60 / 4;
			
			if ( level.inGracePeriod || getTimePassed() < acceptablePassedTime * 1000 )
				self.wasAliveAtMatchStart = true;
		}
	}
	
	self setDepthOfField( 0, 0, 512, 512, 4, 0 );
	if( level.console )
	{
		self SetClientDvar( "cg_fov", "65" );
	}
	
	self resetUIDvarsOnSpawn();

	// Don't do this stuff for TI spawn points	
	if ( isDefined( spawnPoint ) )
	{
		self maps\mp\gametypes\_spawnlogic::finalizeSpawnpointChoice( spawnpoint );
		spawnOrigin = getSpawnOrigin( spawnpoint );
		spawnAngles = spawnpoint.angles;
	}
	else
	{
		// HACK_NOTE_2: faux_spawn_infected is set to keep the lastSpawnTime from being reset because it messes up the killcam for the first kill in infected
		// 	see HACK_NOTE_1
		if( !IsDefined( self.faux_spawn_infected ) )
		{
			// the only useful part of finalizeSpawnpointChoice() when using tactical insertion
			self.lastSpawnTime = getTime();
		}
	}

	self.spawnPos = spawnOrigin;

	//	the actual spawn
	self spawn( spawnOrigin, spawnAngles );
	
	//	immediately fix our stance if we were spawned in place so we don't get stuck in geo
	if ( fauxSpawn && isDefined( self.faux_spawn_stance ) )
	{
		self setStance( self.faux_spawn_stance );
		self.faux_spawn_stance = undefined;
	}

	if ( IsAI( self ) )
	{
		// Immediately freeze us so that waits in nonthreaded function calls below don't allow us to move before we're done spawning
		self freezeControlsWrapper( true );
	}

	//	spawn callback
	[[level.onSpawnPlayer]]();
	
	// Don't do this stuff for TI spawn points	
	if ( isDefined( spawnPoint ) )
		self checkPredictedSpawnpointCorrectness( spawnPoint.origin );
	
	if ( !fauxSpawn )
	{
		self maps\mp\gametypes\_missions::playerSpawned();
		
		if ( IsAI( self ) && IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["player_spawned"] ) )
			self [[ level.bot_funcs["player_spawned"] ]]();
	
		if( !IsAI( self ) )
			self thread watchForSlide();
	}
	
	prof_begin( "spawnPlayer_postUTS" );
	
	assert( isValidClass( self.class ) );
	
	self maps\mp\gametypes\_class::setClass( self.class );
	if ( isDefined ( level.custom_giveloadout ) )
	{
		self [[level.custom_giveloadout]]( fauxSpawn );
	}
	else
	{
		self maps\mp\gametypes\_class::giveLoadout( self.team, self.class );
	}
	
	// Resend omnvars to re-highlight class selected for round based games
	if ( isDefined( game["roundsPlayed"] ) && game["roundsPlayed"] > 0 )
	{
		if ( !isDefined( self.classRefreshed ) || !self.classRefreshed )
		{
			if ( isDefined( self.class_num ) )
			{			
				self SetClientOmnvar( "ui_loadout_selected", self.class_num );
				self.classRefreshed = true;
			}
		}
	}
		
	if ( getDvarInt( "camera_thirdPerson" ) )
		self setThirdPersonDOF( true );

	if ( !gameFlag( "prematch_done" ) )
		self freezeControlsWrapper( true );
	else
		self freezeControlsWrapper( false );

	if ( !gameFlag( "prematch_done" ) || !hadSpawned && game["state"] == "playing" )
	{
		if ( !is_aliens() )
		{
			if ( game["status"] == "overtime" )
				thread maps\mp\gametypes\_hud_message::oldNotifyMessage( game["strings"]["overtime"], game["strings"]["overtime_hint"], undefined, (1, 0, 0), "mp_last_stand" );
		 }
		    
		thread showSpawnNotifies();
	}

	if( getIntProperty( "scr_showperksonspawn", 1 ) == 1 && game["state"] != "postgame" )
	{
		if( !is_aliens() )
			self SetClientOmnvar( "ui_spawn_abilities_show", 1 );
	}

	prof_end( "spawnPlayer_postUTS" );

	//self logstring( "S " + self.origin[0] + " " + self.origin[1] + " " + self.origin[2] );
	
	// give "connected" handlers a chance to start
	// many of these start onPlayerSpawned handlers which rely on the "spawned_player"
	// notify which can happen on the same frame as the "connected" notify
	waittillframeend;

	//	- when killed while using a remote, the player's location remains at their corpse
	//	- the using remote variable is cleared before they are actually respawned and moved
	//	- if you want control over proximity related events with relation to their corpse location
	//    between the clearing of the remote variables and their actual respawning somewhere else use this variable
	self.spawningAfterRemoteDeath = undefined;

	self notify( "spawned_player" );
	level notify ( "player_spawned", self );
	
	if ( game["state"] == "postgame" )
	{
		assert( !level.intermission );
		// We're in the victory screen, but before intermission
		self maps\mp\gametypes\_gamelogic::freezePlayerForRoundEnd();
	}
}

spawnSpectator( origin, angles )
{
	self notify("spawned");
	self notify("end_respawn");
	self notify("joined_spectators");
	in_spawnSpectator( origin, angles );
}

// spawnSpectator clone without notifies for spawning between respawn delays
respawn_asSpectator( origin, angles )
{
	in_spawnSpectator( origin, angles );
}

// spawnSpectator helper
in_spawnSpectator( origin, angles )
{
	self setSpawnVariables();
	
	// don't clear lower message if not actually a spectator,
	// because it probably has important information like when we'll spawn
	self_pers_team = self.pers["team"];
	if ( isDefined( self_pers_team ) && self_pers_team == "spectator" && !level.gameEnded )
		self clearLowerMessage( "spawn_info" );
	
	self updateSessionState( "spectator" );
	self ClearKillcamState();
	self.friendlydamage = undefined;

	self resetUIDvarsOnSpectate();

	if( isDefined( self_pers_team ) && self_pers_team == "spectator" )
		self.statusicon = "";
	else
		self.statusicon = "hud_status_dead";

	maps\mp\gametypes\_spectating::setSpectatePermissions();
	
	onSpawnSpectator( origin, angles );
	
	if ( level.teamBased && !level.splitscreen && !self IsSplitScreenPlayer() )
		self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
}


getPlayerFromClientNum( clientNum )
{
	if ( clientNum < 0 )
		return undefined;
	
	for ( i = 0; i < level.players.size; i++ )
	{
		if ( level.players[i] getEntityNumber() == clientNum )
			return level.players[i];
	}
	return undefined;
}


onSpawnSpectator( origin, angles)
{
	if( isDefined( origin ) && isDefined( angles ) )
	{
		self SetSpectateDefaults( origin, angles );
		self spawn(origin, angles);
		
		self checkPredictedSpawnpointCorrectness( origin );
		return;
	}
	
	spawnpoint = getSpectatePoint();
	
	if ( !is_aliens() )
	{
		mlgcameras = getentarray( "mp_mlg_camera", "classname");
		if ( isDefined( mlgcameras ) && mlgcameras.size )
		{
			for ( i = 0; i < mlgcameras.size && i < 4; i++ )
			{
				self SetMLGCameraDefaults( i, mlgcameras[i].origin, mlgcameras[i].angles);
				level.CameraMapObjs[i].origin = mlgcameras[i].origin;
				level.CameraMapObjs[i].angles = mlgcameras[i].angles;
			}
		}
		else if ( isDefined( level.Camera3Pos ) )
		{
			// setup the mlg camera defaults
			mapname = ToLower( getDvar( "mapname" ) );
			
			//strikezone special logic for 2nd zone cams
			if ( mapname == "mp_strikezone" && isDefined( level.teleport_zone_current ) && level.teleport_zone_current != "start" )
			{
				self setmlgcameradefaults( 0, level.Camera5Pos, level.Camera5Ang );
				level.CameraMapObjs[0].origin = level.Camera5Pos;
				level.CameraMapObjs[0].angles = level.Camera5Ang;
				self setmlgcameradefaults( 1, level.Camera6Pos, level.Camera6Ang );
				level.CameraMapObjs[1].origin = level.Camera6Pos;
				level.CameraMapObjs[1].angles = level.Camera6Ang;
				self setmlgcameradefaults( 2, level.Camera7Pos, level.Camera7Ang );
				level.CameraMapObjs[2].origin = level.Camera7Pos;
				level.CameraMapObjs[2].angles = level.Camera7Ang;
				self setmlgcameradefaults( 3, level.Camera8Pos, level.Camera8Ang );
				level.CameraMapObjs[3].origin = level.Camera8Pos;
				level.CameraMapObjs[3].angles = level.Camera8Ang;
			}
			else 
			{
				self setmlgcameradefaults( 0, level.Camera1Pos, level.Camera1Ang );
				level.CameraMapObjs[0].origin = level.Camera1Pos;
				level.CameraMapObjs[0].angles = level.Camera1Ang;
				self setmlgcameradefaults( 1, level.Camera2Pos, level.Camera2Ang );
				level.CameraMapObjs[1].origin = level.Camera2Pos;
				level.CameraMapObjs[1].angles = level.Camera2Ang;
				self setmlgcameradefaults( 2, level.Camera3Pos, level.Camera3Ang );
				level.CameraMapObjs[2].origin = level.Camera3Pos;
				level.CameraMapObjs[2].angles = level.Camera3Ang;
				self setmlgcameradefaults( 3, level.Camera4Pos, level.Camera4Ang );
				level.CameraMapObjs[3].origin = level.Camera4Pos;
				level.CameraMapObjs[3].angles = level.Camera4Ang;
			}
		}
		else
		{
			/#
				IPrintLnBold( "THIS MAP IS NOT SETUP PROPERLY FOR MLG CAMERAS."	);
			#/
			
		    for ( i = 0; i < 4; i++ )
		    {
		    	self SetMLGCameraDefaults( i, spawnpoint.origin, spawnpoint.angles);
		    }
		}
	}
	
	self SetSpectateDefaults(spawnpoint.origin, spawnpoint.angles);
	self spawn(spawnpoint.origin, spawnpoint.angles);
	
	self checkPredictedSpawnpointCorrectness( spawnpoint.origin );
}

getSpectatePoint()
{
	spawnpoints = getentarray( "mp_global_intermission", "classname" );
	assertEx( spawnPoints.size, "NO mp_global_intermission SPAWNPOINTS IN MAP" );
	spawnpoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random(spawnpoints);
	
	return spawnpoint;
}

spawnIntermission()
{
	self endon( "disconnect" );
	
	self notify( "spawned" );
	self notify( "end_respawn" );
	
	self setSpawnVariables();
	
	self clearLowerMessages();
	
	self freezeControlsWrapper( true );
	
	self SetClientDvar( "cg_everyoneHearsEveryone", 1 );

	self_pers_postGameChallenges = self.pers["postGameChallenges"];
	if ( !is_aliens() && level.rankedMatch && ( self.postGamePromotion || ( IsDefined( self_pers_postGameChallenges ) && self_pers_postGameChallenges ) ) )
	{
		if ( self.postGamePromotion )
			self playLocalSound( "mp_level_up" );
		else if( IsDefined( self_pers_postGameChallenges ) )
			self playLocalSound( "mp_challenge_complete" );

		if ( self.postGamePromotion > level.postGameNotifies )
			level.postGameNotifies = 1;

		if ( IsDefined( self_pers_postGameChallenges ) && self_pers_postGameChallenges > level.postGameNotifies )
			level.postGameNotifies = self_pers_postGameChallenges;

		waitTime = 7.0;
		if( IsDefined( self_pers_postGameChallenges ) )
			waitTime = 4.0 + min( self_pers_postGameChallenges, 3 );		

		while ( waitTime )
		{
			wait ( 0.25 );
			waitTime -= 0.25;
		}
	}
	
	// Gives the award ceremony in mp_shipment a few more seconds to play out (or any level that decides to define level.match_end_delay)
	// Skips this if it's a round-based gametype to play the current score instead
	if ( ( IsDefined( level.finalKillCam_winner ) && level.finalKillCam_winner != "none" ) && IsDefined( level.match_end_delay ) && wasLastRound() )
		wait level.match_end_delay;
	
	self updateSessionState( "intermission" );
	self ClearKillcamState();
	self.friendlydamage = undefined;
	
	spawnPoints = getEntArray( "mp_global_intermission", "classname" );
	spawnPoints = maps\mp\gametypes\_spawnscoring::checkDynamicSpawns( spawnPoints );
	assertEx( spawnPoints.size, "NO mp_global_intermission SPAWNPOINTS IN MAP" );
	
	spawnPoint = spawnPoints[0];
	
	// Opt out for shipment to allow for podium scene (or any other level that wants to do something custom)  
	// Removes depth of field change and notifies mp_shipment_ns of the scoreboard starting
	if ( !IsDefined( level.custom_ending ) )
	{
		self spawn( spawnPoint.origin, spawnPoint.angles );
		
		self checkPredictedSpawnpointCorrectness( spawnPoint.origin );
		
		self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
	}
	else
	{
		// Let mp_shipment_ns know that the scoreboard is coming in so it can manage the match winners
		level notify( "scoreboard_displaying" );
		
//		self spawn( spawnPoint.origin, spawnPoint.angles );
	}
}


spawnEndOfGame()
{
	if ( 1 )
	{
		// If a level, such as mp_shipment_ns, has a custom ending, we notify them that the finalkillcam is done and ready to hand off
		// Doing it here helps us set up the scene earlier, making for a smoother transition
		if ( IsDefined( level.custom_ending ) && wasLastRound() )
		{
			level notify( "start_custom_ending" );
		}
		
		self freezeControlsWrapper( true );
		self spawnSpectator();
		self freezeControlsWrapper( true );
		return;
	}
	
	self notify("spawned");
	self notify("end_respawn");
	
	self setSpawnVariables();
	
	self clearLowerMessages();

	self SetClientDvar( "cg_everyoneHearsEveryone", 1 );

	self updateSessionState( "dead" );
	self ClearKillcamState();
	self.friendlydamage = undefined;

	spawnpoint = getSpectatePoint();
	
//	self spawn( spawnPoint.origin, spawnPoint.angles );
	self spawnSpectator( spawnPoint.origin, spawnPoint.angles );
	
	self checkPredictedSpawnpointCorrectness( spawnPoint.origin );
	
//	spawnPoint setModel( "tag_origin" );
	
	//self playerLinkTo( spawnPoint, "tag_origin", (0,0,0), spawnPoint.angles );
//	self playerLinkTo( spawnPoint );
	
//	self PlayerHide();
	self freezeControlsWrapper( true );
	
	self setDepthOfField( 0, 0, 512, 512, 4, 0 );
}


setSpawnVariables()
{
	// Stop shellshock and rumble
	self StopShellshock();
	self StopRumble( "damage_heavy" );
	self.deathPosition = undefined;
}


notifyConnecting()
{
	waittillframeend;

	if( isDefined( self ) )
		level notify( "connecting", self );
}


Callback_PlayerDisconnect(reason)
{
	if ( !isDefined( self.connected ) )
		return;

	gameLength = getMatchData( "gameLength" );
	gameLength = gameLength + int( getSecondsPassed() );
	setMatchData( "players", self.clientid, "disconnectTime", gameLength );
	setMatchData( "players", self.clientid, "disconnectReason", reason );

	if ( self rankingEnabled() && !is_aliens() )
	{
		self maps\mp\_matchdata::logFinalStats();
	}


	if ( isDefined( self.pers["confirmed"] ) )
	{
		self maps\mp\_matchdata::logKillsConfirmed();
	}
	if ( isDefined( self.pers["denied"] ) )
	{
		self maps\mp\_matchdata::logKillsDenied();
	}
	self removePlayerOnDisconnect();
	self maps\mp\gametypes\_spawnlogic::removeFromParticipantsArray();
	self maps\mp\gametypes\_spawnlogic::removeFromCharactersArray();

	entNum = self GetEntityNumber();
	
	if ( !level.teamBased )
		game["roundsWon"][self.guid] = undefined;
	
	//if ( !level.gameEnded )
	//	self logXPGains();
	
	if ( level.splitscreen )
	{
		players = level.players;
		
		if ( players.size <= 1 )
			level thread maps\mp\gametypes\_gamelogic::forceEnd();
	}

	if ( isDefined( self.score ) && isDefined( self.pers["team"] ) )
	{
		spm = self.score;
		if ( getMinutesPassed() )
			spm = self.score / getMinutesPassed();

		println("Score:" + self.score + " Minutes Passed:" + getMinutesPassed() + " SPM:" + spm );

		setPlayerTeamRank( self, self.clientid, int( spm ) );		
	}
	
	lpselfnum = self getEntityNumber();
	lpGuid = self.guid;
	logPrint("Q;" + lpGuid + ";" + lpselfnum + ";" + self.name + "\n");

	self thread maps\mp\_events::disconnected();

	if ( level.gameEnded )
		self maps\mp\gametypes\_gamescore::removeDisconnectedPlayerFromPlacement();
	
	// this checks self.team because the only time we set it is below, so if a player has already been set up this removes them
	//	DO NOT check self.pers["team"] here because the removeFromTeamCount() function asserts if self.team isn't defined plus other checks
	if ( isDefined( self.team ) )
		self maps\mp\gametypes\_playerlogic::removeFromTeamCount();
	
	if ( self.sessionstate == "playing" && !(IsDefined(self.fauxDead) && self.fauxdead) )	// if fauxdead, the player has already been removed from the list
		self maps\mp\gametypes\_playerlogic::removeFromAliveCount( true );
	else if ( self.sessionstate == "spectator" || self.sessionstate == "dead" )
		level thread maps\mp\gametypes\_gamelogic::updateGameEvents();
}


removePlayerOnDisconnect()
{
	found = false;
	for ( entry = 0; entry < level.players.size; entry++ )
	{
		if ( level.players[entry] == self )
		{
			found = true;
			while ( entry < level.players.size-1 )
			{
				level.players[entry] = level.players[entry + 1];
				assert( level.players[entry] != self );
				entry++;
			}
			level.players[entry] = undefined;
			break;
		}
	}
	assert( found );
}


initClientDvarsSplitScreenSpecific()
{
	if ( level.splitScreen || self IsSplitscreenPlayer() )
	{
		self SetClientDvars("cg_hudGrenadeIconHeight", "37.5", 
							"cg_hudGrenadeIconWidth", "37.5", 
							"cg_hudGrenadeIconOffset", "75", 
							"cg_hudGrenadePointerHeight", "18", 
							"cg_hudGrenadePointerWidth", "37.5", 
							"cg_hudGrenadePointerPivot", "18 40.5", 
							"cg_fovscale", "0.75" );
		
		//turns off HQ bloom if ss player on server
		SetDvar( "r_materialBloomHQScriptMasterEnable", 0 );
	}
	else
	{
		self SetClientDvars("cg_hudGrenadeIconHeight", "25", 
							"cg_hudGrenadeIconWidth", "25", 
							"cg_hudGrenadeIconOffset", "50", 
							"cg_hudGrenadePointerHeight", "12", 
							"cg_hudGrenadePointerWidth", "25", 
							"cg_hudGrenadePointerPivot", "12 27", 
							"cg_fovscale", "1");
	}
}


initClientDvars()
{
	setDvar( "cg_drawTalk", 1 );
	setDvar( "cg_drawCrosshair", 1 );
	setDvar( "cg_drawCrosshairNames", 1 );
	setDvar( "cg_hudGrenadeIconMaxRangeFrag", 250 );

	if ( level.hardcoreMode )
	{
		setDvar( "cg_drawTalk", 3 );
		setDvar( "cg_drawCrosshair", 0 );
		setDvar( "cg_drawCrosshairNames", 1 );
		setDvar( "cg_hudGrenadeIconMaxRangeFrag", 0 );
	}

	if ( IsDefined( level.alwaysdrawfriendlyNames ) && level.alwaysdrawfriendlyNames )
		setDvar( "cg_drawFriendlyNamesAlways", 1 );
	else
		setDvar( "cg_drawFriendlyNamesAlways", 0 );
	
	self SetClientDvars( "cg_drawSpectatorMessages", 1,
						 "cg_scoreboardPingGraph", 1 );

	self initClientDvarsSplitScreenSpecific();

	if ( getGametypeNumLives() )
	{
		self SetClientDvars("cg_deadChatWithDead", 1,
							"cg_deadChatWithTeam", 0,
							"cg_deadHearTeamLiving", 0,
							"cg_deadHearAllLiving", 0);
	}
	else
	{
		self SetClientDvars("cg_deadChatWithDead", 0,
							"cg_deadChatWithTeam", 1,
							"cg_deadHearTeamLiving", 1,
							"cg_deadHearAllLiving", 0);
	}
	
	if ( level.teamBased )
		self SetClientDvars("cg_everyonehearseveryone", 0);
	
	self SetClientDvar( "ui_altscene", 0 );

	if ( getdvarint("scr_hitloc_debug") )
	{
		for ( i = 0; i < 6; i++ )
		{
			self SetClientDvar( "ui_hitloc_" + i, "" );
		}
		self.hitlocInited = true;
	}
}

getLowestAvailableClientId()
{
	found = false;
	
	for ( i = 0; i < 30; i++ )
	{
		foreach( player in level.players )
		{
			if( !isDefined( player ) )
				continue;
			
			if( player.clientId == i )
			{
				found = true;
				break; 
			}
			
			found = false;
		}
		
		if( !found )
		{
			return i;
		}
	}
	//would get here if nothing found (shouldnt be possible).
}

setupSavedActionSlots()
{
	self.saved_actionSlotData = [];		
	for( slotID = 1; slotID <= 4; slotID++ )
	{
		self.saved_actionSlotData[slotID] = spawnStruct();
		self.saved_actionSlotData[slotID].type = "";
		self.saved_actionSlotData[slotID].item = undefined;
	}
		
	// pc needs a few more action slots
	if( !level.console )
	{
		for( slotID = 5; slotID <= 8; slotID++ )
		{
			self.saved_actionSlotData[slotID] = spawnStruct();
			self.saved_actionSlotData[slotID].type = "";
			self.saved_actionSlotData[slotID].item = undefined;
		}
	}
}

Callback_PlayerConnect()
{
	// TODO: we should eventually remove this function, since only _dyanmic_world waits on "connecting"
	// it's actually unreliable because two players could connect on the same frame, but we'd only get one notify. "connected" is now more reliable.
	thread notifyConnecting();

	self.statusicon = "hud_status_connecting";
	self waittill( "begin" );
	self.statusicon = "";
	
	// this needs to be set in this function because of the assert below
	self.connectTime = undefined;
	/#
	self.connectTime = getTime();
	#/
		
	level notify( "connected", self );
	
	self.connected = true;

	if ( self isHost() )
		level.player = self;
		
	// only print that we connected if we haven't connected in a previous round
	if( !level.splitscreen && !isDefined( self.pers["score"] ) )
		iPrintLn(&"MP_CONNECTED", self);

	self.usingOnlineDataOffline = self isUsingOnlineDataOffline();

	self initClientDvars();
	
	if ( !is_aliens() )
		self initPlayerStats();
	
	if( getdvar( "r_reflectionProbeGenerate" ) == "1" )
		level waittill( "eternity" );

	self.guid = self getUniqueId();

	firstConnect = false;
	if ( !isDefined( self.pers["clientid"] ) )
	{
		if ( game["clientid"] >= 30 )
		{
			self.pers["clientid"] = getLowestAvailableClientId();
		}
		else
		{
			self.pers["clientid"] = game["clientid"];
		}
		
		if ( game["clientid"] < 30 )
			game["clientid"]++;
		
		firstConnect = true;
	}

	// if first time connecting, reset killstreaks so they don't carry over after a disconnect
	if( firstConnect )
		self maps\mp\killstreaks\_killstreaks::resetAdrenaline();

	self.clientid = self.pers["clientid"];
	self.pers["teamKillPunish"] = false;

	logPrint("J;" + self.guid + ";" + self getEntityNumber() + ";" + self.name + "\n");

	if ( game["clientid"] <= 30 && game["clientid"] != getMatchData( "playerCount" ) )
	{
		connectionIDChunkHigh = 0;
		connectionIDChunkLow = 0;
		
		if ( !isAI( self ) && matchMakingGame() )
			self registerParty( self.clientid );

		setMatchData( "playerCount", game["clientid"] );
		setMatchData( "players", self.clientid, "playerID", "xuid", self getXuid() );
		setMatchData( "players", self.clientid, "playerID", "ucdIDHigh", self getUcdIdHigh() );
		setMatchData( "players", self.clientid, "playerID", "ucdIDLow", self getUcdIdLow() );
		setMatchData( "players", self.clientid, "playerID", "clanIDHigh", self getClanIdHigh() );
		setMatchData( "players", self.clientid, "playerID", "clanIDLow", self getClanIdLow() );
		setMatchData( "players", self.clientid, "gamertag", self.name );
		connectionIDChunkLow = self getCommonPlayerData( "connectionIDChunkLow", 0 );
		connectionIDChunkHigh = self getCommonPlayerData( "connectionIDChunkHigh", 0 );
		setMatchData( "players", self.clientid, "connectionIDChunkLow", connectionIDChunkLow );
		setMatchData( "players", self.clientid, "connectionIDChunkHigh", connectionIDChunkHigh );
		setmatchclientip( self, self.clientid );
		
		gameLength = getMatchData( "gameLength" );
		gameLength = gameLength + int( getSecondsPassed() );
		setMatchData( "players", self.clientid, "joinType", self getJoinType( ) );
		setMatchData( "players", self.clientid, "connectTime", gameLength );
		
		if ( self rankingEnabled() && !is_aliens() )
		{
			self maps\mp\_matchdata::logInitialStats();
		}
		
		if ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] || IsAI(self) )
			connectedBot = true;
		else
			connectedBot = false;
		
		if( matchMakingGame() && allowTeamChoice() && !connectedBot )
		{
			/#
			//if ( ( getDvarInt( "scr_forcerankedmatch" ) && level.teamBased ) || ( isDefined( self.pers["isBot"] ) && level.teamBased ) )
			//	self.sessionteam = maps\mp\gametypes\_menus::getTeamAssignment();
			#/		
			assert( getdvarint( "scr_runlevelandquit" ) == 1 || (level.multiTeamBased) || (level.teamBased && (self.sessionteam == "allies" || self.sessionteam == "axis")) || (!level.teamBased && self.sessionteam == "none" ) );
			//assert( (level.teamBased && self.sessionteam == self.team) || (!level.teamBased && self.sessionteam == "none") );
			setMatchData( "players", self.clientid, "team", self.sessionteam );
		}
	}

	if ( !level.teamBased )
		game["roundsWon"][self.guid] = 0;
	
	self.leaderDialogQueue = [];
	self.leaderDialogLocQueue = [];
	self.leaderDialogActive = "";
	self.leaderDialogGroups = [];
	self.leaderDialogGroup = "";

	if( !IsDefined( self.pers["cur_kill_streak"] ) )
		self.pers["cur_kill_streak"] = 0;
	if( !IsDefined( self.pers["cur_death_streak"] ) )
		self.pers["cur_death_streak"] = 0;
	if( !IsDefined( self.pers["assistsToKill"] ) )
		self.pers["assistsToKill"] = 0;
	if( !IsDefined( self.pers["cur_kill_streak_for_nuke"] ) )
		self.pers["cur_kill_streak_for_nuke"] = 0;
	if( !IsDefined( self.pers["objectivePointStreak"] ) )
		self.pers["objectivePointStreak"] = 0;
	
	if ( self rankingEnabled() && !is_aliens() )
		self.kill_streak = self maps\mp\gametypes\_persistence::statGet( "killStreak" );

	self.lastGrenadeSuicideTime = -1;

	self.teamkillsThisRound = 0;
	
	self.hasSpawned = false;
	self.waitingToSpawn = false;
	self.wantSafeSpawn = false;
	
	self.wasAliveAtMatchStart = false;
	self.moveSpeedScaler = 1;
	self.killStreakScaler = 1;
	self.xpScaler = 1;
	self.objectiveScaler = 1;
	self.isSniper = false;
	
	if ( !is_aliens() )
		self setRestXPGoal();

	self setupSavedActionSlots();

	self thread maps\mp\_flashgrenades::monitorFlash();
	
	self resetUIDvarsOnConnect();

	// give any threads waiting on the "connected" notify a chance to process before we are added to level.players
	// this should ensure that all . variables on the player are correctly initialized by this point
	waittillframeend;
	/#
	foreach ( player in level.players )
		assert( player != self );
	#/
	level.players[level.players.size] = self;
	self maps\mp\gametypes\_spawnlogic::addToParticipantsArray();
	self maps\mp\gametypes\_spawnlogic::addToCharactersArray();
	
	if ( level.teambased )
		self updateScores();
	
	// When joining a game in progress, if the game is at the post game state (scoreboard) the connecting player should spawn into intermission
	if ( game["state"] == "postgame" )
	{
		self.connectedPostGame = true;
		
		//if ( matchMakingGame() )
		//	self maps\mp\gametypes\_menus::addToTeam( maps\mp\gametypes\_menus::getTeamAssignment(), true );
		//else
		//	self maps\mp\gametypes\_menus::addToTeam( "spectator", true );
		
		self SetClientDvars( "cg_drawSpectatorMessages", 0 );
		
		spawnIntermission();
		return;
	}

	/#
	if ( getDvarInt( "scr_debug_postgameconnect" ) )
	{
		self.pers["class"] = "";
		self.class = "";
		if ( self.sessionteam != "spectator" )
			self.pers["team"] = self.sessionteam;
		
		// setting team to "free" is equivelent to setting it to undefined in MP [ isDefined( self.team ) returns false after self.team = "free"; ]
		// This is a special case so that the team can be code bound yet still undefined until script sets it something valid
		self.team = "free"; 
	}
	#/
	
	if ( IsAI( self ) && IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["think"] ) )
		self thread [[ level.bot_funcs["think"] ]]();

	level endon( "game_ended" );
	
	if ( isDefined( level.hostMigrationTimer ) )
		self thread maps\mp\gametypes\_hostmigration::hostMigrationTimerThink();


	if ( isDefined( level.onPlayerConnectAudioInit ) )
	{
		[[ level.onPlayerConnectAudioInit ]]();
	}
	
	if ( bot_is_fireteam_mode() && !IsAI( self ) )
	{
		self thread spawnSpectator();
		self SetClientOmnvar( "ui_options_menu", 0 );		
	}
	// first connect only
	else if ( !isDefined( self.pers["team"] ) )
	{
		if ( matchMakingGame() && self.sessionteam != "none" )
		{
			self thread spawnSpectator();
			self thread maps\mp\gametypes\_menus::setTeam( self.sessionteam );
			
			if( allowClassChoice() || ( showFakeLoadout() && !isAI(self) ) )
				self SetClientOmnvar( "ui_options_menu", 2 );
			
			self thread kickIfDontSpawn();
			return;
		}
		else if ( isSquadsMode() && GetDvarInt( "onlinegame" ) == 0 && level.gametype != "horde" && IsBot( self ) == false)
		{
			self thread spawnSpectator();
			self thread maps\mp\gametypes\_menus::setTeam( "allies" );
			self SetClientOmnvar( "ui_options_menu", 2 );
		}
		else if ( !matchMakingGame() && allowTeamChoice() )
		{		
			self maps\mp\gametypes\_menus::menuSpectator();
			self SetClientOmnvar( "ui_options_menu", 1 );
		}
		else
		{
			self thread spawnSpectator();
			self maps\mp\gametypes\_menus::autoAssign();
			
			if( allowClassChoice() || ( showFakeLoadout() && !isAI(self) ) )
				self SetClientOmnvar( "ui_options_menu", 2 );
			
			if ( matchMakingGame() )
				self thread kickIfDontSpawn();
		
			return;
		}
	}
	else
	{
		self maps\mp\gametypes\_menus::addToTeam( self.pers["team"], true );
		
		if ( isValidClass( self.pers["class"] ) )
		{
			self thread spawnClient();
			return;
		}

		self thread spawnSpectator();

		if ( self.pers["team"] == "spectator" )
		{
			if ( isDefined( self.pers["mlgSpectator"] ) && self.pers["mlgSpectator"] )
			{
				self SetMlgSpectator( 1 );
				self thread maps\mp\gametypes\_spectating::setMLGCamVisibility( true );
				self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
			}
			if ( allowTeamChoice() )
				self maps\mp\gametypes\_menus::beginTeamChoice();
			else
				self [[level.autoassign]]();
		}
		else
			self maps\mp\gametypes\_menus::beginClassChoice();
			
	}

	/#	
		assert( self.connectTime == getTime() );
	#/
}


Callback_PlayerMigrated()
{
	println( "Player " + self.name + " finished migrating at time " + gettime() );
	
	if ( isDefined( self.connected ) && self.connected )
	{
		self updateObjectiveText();
		self updateMainMenu();

		if ( level.teambased )
			self updateScores();
	}
	
	//set split screen specific dvars as the host could be split screen
	if ( self isHost() )
	{
		self initClientDvarsSplitScreenSpecific();
	}
	
	humanPlayerCount = 0;
	foreach ( player in level.players )
	{
		if ( !IsDefined( player.pers["isBot"] ) || player.pers["isBot"] == false )
			humanPlayerCount++;
	}
	
	if ( !IsDefined( self.pers["isBot"] ) || self.pers["isBot"] == false )
	{
		level.hostMigrationReturnedPlayerCount++;
		if ( level.hostMigrationReturnedPlayerCount >= humanPlayerCount * 2 / 3 )
		{
			println( "2/3 of human players have finished migrating" );
			level notify( "hostmigration_enoughplayers" );
		}
	}
}


AddLevelsToExperience( experience, levels ) // lets you add "1500 experience + 1.5 levels" and returns the result in experience
{
	rank = maps\mp\gametypes\_rank::getRankForXp( experience );
	
	minXP = maps\mp\gametypes\_rank::getRankInfoMinXp( rank );
	maxXP = maps\mp\gametypes\_rank::getRankInfoMaxXp( rank );
	rank += (experience - minXP) / (maxXP - minXP);
	
	rank += levels;
	
	if ( rank < 0 )
	{
		rank = 0;
		fractionalPart = 0.0;
	}
	else if ( rank >= level.maxRank + 1.0 )
	{
		rank = level.maxRank;
		fractionalPart = 1.0;
	}
	else
	{
		fractionalPart = rank - floor( rank );
		rank = int(floor( rank ));
	}
	
	minXP = maps\mp\gametypes\_rank::getRankInfoMinXp( rank );
	maxXP = maps\mp\gametypes\_rank::getRankInfoMaxXp( rank );
	return int( fractionalPart * (maxXP - minXP) ) + minXP;
}


GetRestXPCap( experience )
{
	levelsToCap = getDvarFloat( "scr_restxp_cap" );
	return AddLevelsToExperience( experience, levelsToCap );
}


setRestXPGoal()
{
	if ( !self rankingEnabled() )
		return;

	if ( !getdvarint( "scr_restxp_enable" ) )
	{
		self setRankedPlayerData( "restXPGoal", 0 );
		return;
	}
	
	secondsSinceLastGame = self getRestedTime();
	hoursSinceLastGame = secondsSinceLastGame / 3600;
	
	/#
	hoursSinceLastGame *= getDvarFloat( "scr_restxp_timescale" );
	#/
	
	experience = self getRankedPlayerData( "experience" );
	
	minRestXPTime = getDvarFloat( "scr_restxp_minRestTime" ); // hours
	restXPGainRate = getDvarFloat( "scr_restxp_levelsPerDay" ) / 24.0;
	restXPCap = GetRestXPCap( experience );
	
	restXPGoal = self getRankedPlayerData( "restXPGoal" );
	
	if ( restXPGoal < experience )
		restXPGoal = experience;
	
	oldRestXPGoal = restXPGoal;
	
	restLevels = 0;
	if ( hoursSinceLastGame > minRestXPTime )
	{
		restLevels = restXPGainRate * hoursSinceLastGame;
		restXPGoal = AddLevelsToExperience( restXPGoal, restLevels );
	}
	
	cappedString = "";
	if ( restXPGoal >= restXPCap )
	{
		restXPGoal = restXPCap;
		cappedString = " (hit cap)";
	}
	
	println( "Player " + self.name + " has rested for " + hoursSinceLastGame + " hours; gained " + restLevels + " levels of rest XP" + cappedString + ". Now has " + (restXPGoal - experience) + " rest XP; was " + (oldRestXPGoal - experience) );
	
	self setRankedPlayerData( "restXPGoal", restXPGoal );
}


forceSpawn()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "spawned" );

	wait ( 60.0 );

	if ( self.hasSpawned )
		return;
	
	if ( self.pers["team"] == "spectator" )
		return;
	
	if ( !isValidClass( self.pers["class"] ) )
	{
		self.pers["class"] = "CLASS_CUSTOM1";
		
		self.class = self.pers["class"];
	}
	
	self thread spawnClient();
}


kickIfDontSpawn()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "spawned" );
	self endon ( "attempted_spawn" );
	
	wait_time 		= GetDvarFloat("scr_kick_time", 90 );
	min_time 		= GetDvarFloat("scr_kick_mintime", 45 );
	host_wait_time 	= GetDvarFloat("scr_kick_hosttime", 120 );
	
	starttime = gettime();
	
	if ( self isHost() )
		kickWait( host_wait_time );
	else
		kickWait( wait_time );
	
	timePassed = (gettime() - starttime)/1000;
	if ( timePassed < wait_time - .1 && timePassed < min_time )
		return;
	
	if ( self.hasSpawned )
		return;
	
	if ( self.pers["team"] == "spectator" )
		return;
	
	kick( self getEntityNumber(), "EXE_PLAYERKICKED_INACTIVE" );

	level thread maps\mp\gametypes\_gamelogic::updateGameEvents();
}


kickWait( waittime )
{
	level endon("game_ended");

	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( waittime );
}

initPlayerStats()
{
	self maps\mp\gametypes\_persistence::initBufferedStats();
	
	self.pers["lives"] = getGametypeNumLives();

	//Deaths
	if ( !isDefined( self.pers["deaths"] ) )
	{
		self initPersStat( "deaths" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "deaths", 0 );
	}
	self.deaths = self getPersStat( "deaths" );
	
	//Score
	if ( !isDefined( self.pers["score"] ) )
	{
		self initPersStat( "score" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "score", 0 );
	}
	self.score = self getPersStat( "score" );
	
	//Suicides
	if ( !isDefined( self.pers["suicides"] ) )
	{
		self initPersStat( "suicides" );
	}
	self.suicides = self getPersStat( "suicides" );

	//Kills
	if ( !isDefined( self.pers["kills"] ) )
	{
		self initPersStat( "kills" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "kills", 0 );
	}
	self.kills = self getPersStat( "kills" );

	//Headshots
	if ( !isDefined( self.pers["headshots"] ) )
	{
		self initPersStat( "headshots" );
	}
	self.headshots = self getPersStat( "headshots" );

	//Assists
	if ( !isDefined( self.pers["assists"] ) )
	{
		self initPersStat( "assists" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "assists", 0 );
	}
	self.assists = self getPersStat( "assists" );
	
	//Captures
	if ( !isDefined( self.pers["captures"] ) )
	{
		self initPersStat( "captures" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "captures", 0 );
	}
	self.captures = self getPersStat( "captures" );
	
	//Returns
	if ( !isDefined( self.pers["returns"] ) )
	{
		self initPersStat( "returns" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "returns", 0 );
	}
	self.returns = self getPersStat( "returns" );
	
	//Defends
	if ( !isDefined( self.pers["defends"] ) )
	{
		self initPersStat( "defends" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "defends", 0 );
	}
	self.defends = self getPersStat( "defends" );

	//Plants
	if ( !isDefined( self.pers["plants"] ) )
	{
		self initPersStat( "plants" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "plants", 0 );
	}
	self.plants = self getPersStat( "plants" );

	//Defuses
	if ( !isDefined( self.pers["defuses"] ) )
	{
		self initPersStat( "defuses" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "defuses", 0 );
	}
	self.defuses = self getPersStat( "defuses" );

	//Destructions
	if ( !isDefined( self.pers["destructions"] ) )
	{
		self initPersStat( "destructions" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "destructions", 0 );
	}
	self.destructions = self getPersStat( "destructions" );
	
	//Confirmed
	if ( !isDefined( self.pers["confirmed"] ) )
	{
		self initPersStat( "confirmed" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "confirmed", 0 );
	}
	self.confirmed = self getPersStat( "confirmed" );
	
	//Denies
	if ( !isDefined( self.pers["denied"] ) )
	{
		self initPersStat( "denied" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "denied", 0 );
	}
	self.denied = self getPersStat( "denied" );
	
	//Rescues
	if ( !isDefined( self.pers["rescues"] ) )
	{
		self initPersStat( "rescues" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "rescues", 0 );
	}
	self.rescues = self getPersStat( "rescues" );
	
	//killChains
	if ( !isDefined( self.pers["killChains"] ) )
	{
		self initPersStat( "killChains" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "killChains", 0 );
	}
	self.killChains = self getPersStat( "killChains" );
	
	//killsAsSurvivor
	if ( !isDefined( self.pers["killsAsSurvivor"] ) )
	{
		self initPersStat( "killsAsSurvivor" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "killsAsSurvivor", 0 );
	}
	self.killsAsSurvivor = self getPersStat( "killsAsSurvivor" );
	
	//killsAsInfected
	if ( !isDefined( self.pers["killsAsInfected"] ) )
	{
		self initPersStat( "killsAsInfected" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "killsAsInfected", 0 );
	}
	self.killsAsInfected = self getPersStat( "killsAsInfected" );
	
	//Teamkills
	if ( !isDefined( self.pers["teamkills"] ) )
	{
		self initPersStat( "teamkills" );
	}
	
	//extrascore0
	if ( !isDefined( self.pers["extrascore0"] ) )
	{
		self initPersStat( "extrascore0" );
	}
	
	//hordeKills
	if ( !isDefined( self.pers["hordeKills"] ) )
	{
		self initPersStat( "hordeKills" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "squardKills", 0 );
	}
	
	//hordeRevives
	if ( !isDefined( self.pers["hordeRevives"] ) )
	{
		self initPersStat( "hordeRevives" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "squardRevives", 0 );
	}
	
	//hordeCrates
	if ( !isDefined( self.pers["hordeCrates"] ) )
	{
		self initPersStat( "hordeCrates" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "squardCrates", 0 );
	}
	
	//hordeRound
	if ( !isDefined( self.pers["hordeRound"] ) )
	{
		self initPersStat( "hordeRound" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "sguardWave", 0 );
	}

	//hordeWeapon
	if ( !isDefined( self.pers["hordeWeapon"] ) )
	{
		self initPersStat( "hordeWeapon" );
		self maps\mp\gametypes\_persistence::statSetChild( "round", "sguardWeaponLevel", 0 );
	}

	if ( !isDefined( self.pers["teamKillPunish"] ) )
		self.pers["teamKillPunish"] = false;
	
	self initPersStat( "longestStreak" );	

	self.pers["lives"] = getGametypeNumLives();
	
	self maps\mp\gametypes\_persistence::statSetChild( "round", "killStreak", 0 );
	self maps\mp\gametypes\_persistence::statSetChild( "round", "loss", false );
	self maps\mp\gametypes\_persistence::statSetChild( "round", "win", false );
	self maps\mp\gametypes\_persistence::statSetChild( "round", "scoreboardType", "none" );
	self maps\mp\gametypes\_persistence::statSetChildBuffered( "round", "timePlayed", 0 );
}


addToTeamCount()
{
	assert( isPlayer( self ) );
	assert( isDefined( self.team ) );
	assert( isDefined( self.pers["team"] ) );
	assert( self.team == self.pers["team"] );
	
	level.teamCount[ self.team ]++;

	if( !IsDefined( level.teamList ) )
		level.teamList = [];		
	if( !IsDefined( level.teamList[ self.team ] ) )
		level.teamList[ self.team ] = [];
	level.teamList[ self.team ][ level.teamList[ self.team ].size ] = self;

	maps\mp\gametypes\_gamelogic::updateGameEvents();
}


removeFromTeamCount()
{
	assert( isPlayer( self ) );
	assert( isDefined( self.team ) );
	assert( isDefined( self.pers["team"] ) );
	assert( self.team == self.pers["team"] );
	
	level.teamCount[ self.team ]--;
	
	if( IsDefined( level.teamList ) && IsDefined( level.teamList[ self.team ] ) )
	{
		teamList = [];
		foreach( player in level.teamList[ self.team ] )
		{
			if( !IsDefined( player ) || player == self )
				continue;
			teamList[ teamList.size ] = player; 
		}
		level.teamList[ self.team ] = teamList;
	}
}


addToAliveCount()
{
	assert( isPlayer( self ) );
	
	teamAdding = self.team;
	
	if ( !(IsDefined(self.alreadyAddedToAliveCount) && self.alreadyAddedToAliveCount) )
	{
		level.hasSpawned[teamAdding]++;
		self incrementAliveCount(teamAdding);
	}
	
	self.alreadyAddedToAliveCount = undefined;

	if ( level.aliveCount["allies"] + level.aliveCount["axis"] > level.maxPlayerCount )
		level.maxPlayerCount = level.aliveCount["allies"] + level.aliveCount["axis"];
}


incrementAliveCount( teamAdding )
{
	// NOTE: While we probably want to remove the level.aliveCount system in favor of something simpler, the dev script in this function has
	// been very helpful in identifying cases where a player was spawning twice.  Should maybe consider keeping it in some form.
	
	level.aliveCount[teamAdding]++;
/#	
	if ( !IsDefined(level.alive_players) )
		level.alive_players = [];
	if ( !IsDefined(level.alive_players[teamAdding]) )
		level.alive_players[teamAdding] = [];
	
	AssertEx(!array_contains(level.alive_players[teamAdding],self), "Player " + self.name + " somehow added to level.aliveCount twice");
	level.alive_players[teamAdding] = array_add(level.alive_players[teamAdding],self);
	
	// Make sure these arrays are always in sync
	if( level.alive_players[teamAdding].size != level.aliveCount[teamAdding] )
	{
		AssertMsg( "WARNING: level.alive_players and level.aliveCount are out of sync!" );
	}
#/	
}


removeFromAliveCount( disconnected )
{
	if ( is_aliens() )
		return;
	
	assert( isPlayer( self ) );

	teamRemoving = self.team;
	if ( IsDefined(self.switching_teams) && self.switching_teams && IsDefined(self.joining_team) && self.joining_team == self.team)
		teamRemoving = self.leaving_team;	// Already switched teams and respawned, so need to remove from old team instead

	if ( isDefined( disconnected ) )
	{
		self maps\mp\gametypes\_playerlogic::removeAllFromLivesCount();
	}
	else if ( isDefined( self.switching_teams ) )
	{
		self.pers["lives"]--;
		//self removeFromLivesCount();
	}

	self decrementAliveCount(teamRemoving);
	return maps\mp\gametypes\_gamelogic::updateGameEvents();
}


decrementAliveCount( teamRemoving )
{
	// NOTE: While we probably want to remove the level.aliveCount system in favor of something simpler, the dev script in this function has
	// been very helpful in identifying cases where a player was spawning twice.  Should maybe consider keeping it in some form.
	
	level.aliveCount[teamRemoving]--;
/#	
	for ( i = 0; i < level.alive_players[teamRemoving].size; i++ )
	{
		if ( level.alive_players[teamRemoving][i] == self )
		{
			level.alive_players[teamRemoving][i] = level.alive_players[teamRemoving][level.alive_players[teamRemoving].size-1];
			level.alive_players[teamRemoving][level.alive_players[teamRemoving].size-1] = undefined;
			break;
		}
	}
	
	// Make sure these arrays are always in sync
	if( level.alive_players[teamRemoving].size != level.aliveCount[teamRemoving] )
	{
		AssertMsg( "WARNING: level.alive_players and level.aliveCount are out of sync!" );
	}
#/	
}


addToLivesCount()
{
	assert( isPlayer( self ) );
	level.livesCount[self.team] += self.pers["lives"];
}


removeFromLivesCount()
{
	assert( isPlayer( self ) );
	level.livesCount[self.team]--;

	// defensive, but we need to allow players to die/respawn when they're the only player in an offline game
	level.livesCount[self.team] = int( max( 0, level.livesCount[self.team] ) );
}


removeAllFromLivesCount()
{
	assert( isPlayer( self ) );
	level.livesCount[self.team] -= self.pers["lives"];

	// defensive, but we need to allow players to die/respawn when they're the only player in an offline game
	level.livesCount[self.team] = int( max( 0, level.livesCount[self.team] ) );
}

resetUIDvarsOnSpawn()
{
	// need to reset certain ui dvars so the hud doesn't show up when it shouldn't
	self SetClientOmnvar( "ui_carrying_bomb", false );
	self SetClientOmnvar( "ui_dom_securing", 0 );
	self SetClientOmnvar( "ui_securing", 0 );
	self SetClientOmnvar( "ui_bomb_planting_defusing", 0 );
	self SetClientOmnvar( "ui_light_armor", false );
	self SetClientDvar( "ui_juiced_end_milliseconds", 0 );
	self SetClientOmnvar( "ui_killcam_end_milliseconds", 0 );
	self SetClientOmnvar( "ui_cranked_bomb_timer_end_milliseconds", 0 );
}

resetUIDvarsOnConnect()
{
	// need to reset certain ui dvars so the hud doesn't show up when it shouldn't
	self SetClientOmnvar( "ui_carrying_bomb", false );
	self SetClientOmnvar( "ui_dom_securing", 0 );
	self SetClientOmnvar( "ui_securing", 0 );
	self SetClientOmnvar( "ui_bomb_planting_defusing", 0 );
	self SetClientOmnvar( "ui_light_armor", false );
	self SetClientOmnvar( "ui_killcam_end_milliseconds", 0 );
	self SetClientDvar( "ui_juiced_end_milliseconds", 0 );
	self SetClientDvar( "ui_eyes_on_end_milliseconds", 0 );
	self SetClientOmnvar( "ui_cranked_bomb_timer_end_milliseconds", 0 );
}

resetUIDvarsOnSpectate()
{
	// need to reset certain ui dvars so the hud doesn't show up when it shouldn't
	self SetClientOmnvar( "ui_carrying_bomb", false );
	self SetClientOmnvar( "ui_dom_securing", 0 );
	self SetClientOmnvar( "ui_securing", 0 );
	self SetClientOmnvar( "ui_bomb_planting_defusing", 0 );
	self SetClientOmnvar( "ui_light_armor", false );
	self SetClientOmnvar( "ui_killcam_end_milliseconds", 0 );
	self SetClientDvar( "ui_juiced_end_milliseconds", 0 );
	self SetClientDvar( "ui_eyes_on_end_milliseconds", 0 );
	self SetClientOmnvar( "ui_cranked_bomb_timer_end_milliseconds", 0 );
}

resetUIDvarsOnDeath()
{
	// need to reset certain ui dvars so the hud doesn't show up when it shouldn't
}

watchForSlide() // self == player
{
	self endon( "death" );
	self endon( "disconnect" );
	
	// when the player slides we want to play a cam fx
	while( true )
	{
		self waittill( "sprint_slide_begin" );
		self PlayFX( level._effect[ "slide_dust" ], self GetEye() );
	}
}
