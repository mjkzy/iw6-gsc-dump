#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\agents\_agent_utility;
#include maps\mp\perks\_perkfunctions;

NUM_KILLS_GIVE_NUKE = 25;

isSwitchingTeams()
{
	if ( IsDefined( self.switching_teams ) )
		return true;

	return false;
}


isTeamSwitchBalanced()
{
	playerCounts = self maps\mp\gametypes\_teams::CountPlayers();
	playerCounts[ self.leaving_team ] -- ;
	playerCounts[ self.joining_team ]++ ;

	return( ( playerCounts[ self.joining_team ] - playerCounts[ self.leaving_team ] ) < 2 );
}


isFriendlyFire( victim, attacker )
{
	if ( !level.teamBased )
		return false;
	
	if ( !IsDefined( attacker ) )
		return false;
	
	if ( !IsPlayer( attacker ) && !IsDefined( attacker.team ) )
		return false;
	
	if ( victim.team != attacker.team )
		return false;
	
	if ( victim == attacker )
		return false;
	
	return true;
}


killedSelf( attacker )
{
	if ( !IsPlayer( attacker ) )
		return false;

	if ( attacker != self )
		return false;

	return true;
}


handleTeamChangeDeath()
{
	if ( !level.teamBased )
		return;

	// this might be able to happen now, but we should remove instances where it can
	assert( self.leaving_team != self.joining_team );

	if ( self.joining_team == "spectator" || !isTeamSwitchBalanced() )
	{
		self thread [[ level.onXPEvent ]]( "suicide" );
		self incPersStat( "suicides", 1 );
		self.suicides = self getPersStat( "suicides" );
	}
	
	if( IsDefined( level.onTeamChangeDeath ) )
		[[ level.onTeamChangeDeath ]]( self );
}


handleWorldDeath( attacker, lifeId, sMeansOfDeath, sHitLoc )
{
	if ( !IsDefined( attacker ) )
		return;

	if ( !IsDefined( attacker.team ) )
	{	
		handleSuicideDeath( sMeansOfDeath, sHitLoc );
		return;
	}
	
	assert( attacker.team == "axis" || attacker.team == "allies" );

	if ( ( level.teamBased && attacker.team != self.team ) || !level.teamBased )
	{
		if ( IsDefined( level.onNormalDeath ) && (IsPlayer( attacker ) || IsAgent( attacker )) && attacker.team != "spectator" )
			[[ level.onNormalDeath ]]( self, attacker, lifeId );
	}
}


handleSuicideDeath( sMeansOfDeath, sHitLoc )
{
	self thread [[ level.onXPEvent ]]( "suicide" );
	self incPersStat( "suicides", 1 );
	self.suicides = self getPersStat( "suicides" );
	
	if ( !matchMakingGame() )
		self incPlayerStat( "suicides", 1 );

	scoreSub = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "suicidepointloss" );
	maps\mp\gametypes\_gamescore::_setPlayerScore( self, maps\mp\gametypes\_gamescore::_getPlayerScore( self ) - scoreSub );

	if ( sMeansOfDeath == "MOD_SUICIDE" && sHitLoc == "none" && IsDefined( self.throwingGrenade ) )
		self.lastGrenadeSuicideTime = gettime();

	if ( IsDefined( level.onSuicideDeath ) )
		[[ level.onSuicideDeath ]]( self );
	
	// suicide was caused by too many team kills
	if ( IsDefined( self.friendlydamage ) )
		self iPrintLnBold( &"MP_FRIENDLY_FIRE_WILL_NOT" );
}


handleFriendlyFireDeath( attacker )
{
	attacker thread [[ level.onXPEvent ]]( "teamkill" );
	attacker.pers[ "teamkills" ] += 1.0;

	attacker.teamkillsThisRound++ ;

	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "team", "teamkillpointloss" ) )
	{
		scoreSub = maps\mp\gametypes\_rank::getScoreInfoValue( "kill" );
		maps\mp\gametypes\_gamescore::_setPlayerScore( attacker, maps\mp\gametypes\_gamescore::_getPlayerScore( attacker ) - scoreSub );
	}

 	if ( level.maxAllowedTeamkills < 0 )
 		return;

	if ( level.inGracePeriod )
	{
		teamKillDelay = 1;
		attacker.pers["teamkills"] += level.maxAllowedTeamkills;
	}
	else if ( attacker.pers[ "teamkills" ] > 1 && getTimePassed() < ( (level.gracePeriod * 1000) + 8000 + ( attacker.pers[ "teamkills" ] * 1000 ) ) )
	{
		teamKillDelay = 1;
		attacker.pers["teamkills"] += level.maxAllowedTeamkills;
	}
	else
	{
		teamKillDelay = attacker maps\mp\gametypes\_playerlogic::TeamKillDelay();
	}

	if ( teamKillDelay > 0 )
	{
		attacker.pers["teamKillPunish"] = true;
		attacker _suicide();
	}
}


handleNormalDeath( lifeId, attacker, eInflictor, sWeapon, sMeansOfDeath )
{
	attacker thread maps\mp\_events::killedPlayer( lifeId, self, sWeapon, sMeansOfDeath );

	//if ( attacker.pers["teamkills"] <= level.maxAllowedTeamkills )
	//	attacker.pers["teamkills"] = max( attacker.pers["teamkills"] - 1, 0 );

	if ( sMeansOfDeath == "MOD_HEAD_SHOT" )
	{
		attacker incPersStat( "headshots", 1 );
		attacker.headshots = attacker getPersStat( "headshots" );
		attacker incPlayerStat( "headshots", 1 );

		if ( IsDefined( attacker.lastStand ) )
			value = maps\mp\gametypes\_rank::getScoreInfoValue( "kill" ) * 2;
		else
			value = undefined;

		attacker PlayLocalSound( "bullet_impact_headshot_plr" );
		self PlaySound( "bullet_impact_headshot" );
	}
	else
	{
		if ( IsDefined( attacker.lastStand ) )
			value = maps\mp\gametypes\_rank::getScoreInfoValue( "kill" ) * 2;
		else
			value = undefined;
	}

	killCreditTo = attacker;
	if ( IsDefined( attacker.commanding_bot ) )
	{
		killCreditTo = attacker.commanding_bot;
	}
	
	dontStoreKillsValue = false;
	if ( IsSquadsMode() )
		dontStoreKillsValue = true;
	
	killCreditTo incPersStat( "kills", 1, dontStoreKillsValue );
	killCreditTo.kills = killCreditTo getPersStat( "kills" );
	killCreditTo updatePersRatio( "kdRatio", "kills", "deaths" );
	killCreditTo maps\mp\gametypes\_persistence::statSetChild( "round", "kills", killCreditTo.kills );
	killCreditTo incPlayerStat( "kills", 1 );

	if ( isFlankKill( self, attacker ) )
	{
		killCreditTo incPlayerStat( "flankkills", 1 );

		self incPlayerStat( "flankdeaths", 1 );
	}
	
	lastKillStreak = attacker.pers["cur_kill_streak"];
	
	if( isAlive( attacker ) || attacker.streakType == "support" )
	{
		if( ( sMeansOfDeath == "MOD_MELEE" && !attacker isJuggernaut() ) || attacker killShouldAddToKillstreak( sWeapon ) )
		{
			attacker registerKill( sWeapon, true );
		}

		attacker setPlayerStatIfGreater( "killstreak", attacker.pers["cur_kill_streak"] );

		if( attacker.pers["cur_kill_streak"] > attacker getPersStat( "longestStreak" ) )
			attacker setPersStat( "longestStreak", attacker.pers["cur_kill_streak"] );
	}

	attacker.pers["cur_death_streak"] = 0;

	// giving rank xp after kill and death streak updates so we can use them in the giveRankXP function
	attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", value, sWeapon, sMeansOfDeath, undefined, self );

	if ( attacker.pers["cur_kill_streak"] > attacker maps\mp\gametypes\_persistence::statGetChild( "round", "killStreak" ) )
	{
		attacker maps\mp\gametypes\_persistence::statSetChild( "round", "killStreak", attacker.pers["cur_kill_streak"] );
	}
	
	if ( attacker rankingEnabled() )
	{
		if ( attacker.pers["cur_kill_streak"] > attacker.kill_streak )
		{
			if ( !IsSquadsMode() )
			{
				attacker maps\mp\gametypes\_persistence::statSet( "killStreak", attacker.pers["cur_kill_streak"] );
			}
			attacker.kill_streak = attacker.pers["cur_kill_streak"];
		}
	}

	maps\mp\gametypes\_gamescore::givePlayerScore( "kill", attacker, self );

	scoreSub = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "deathpointloss" );
	maps\mp\gametypes\_gamescore::_setPlayerScore( self, maps\mp\gametypes\_gamescore::_getPlayerScore( self ) - scoreSub );

	if ( IsDefined( level.ac130player ) && level.ac130player == attacker )
		level notify( "ai_killed", self );
	
	if ( IsDefined( attacker.odin ) )
		level notify( "odin_killed_player", self );

	//if ( lastKillStreak != attacker.pers["cur_kill_streak"] )
	level notify ( "player_got_killstreak_" + attacker.pers["cur_kill_streak"], attacker );
	attacker notify( "got_killstreak" , attacker.pers["cur_kill_streak"] );

	attacker notify ( "killed_enemy", self, sWeapon, sMeansOfDeath );
	
	//	assists for marking player with remote uav (allow in FFA)
	// 2013-07-18 wallace: remote uav doesn't exist iw6, but motion sensor does
	/*
	if ( IsDefined( self.UAVRemoteMarkedBy ) )
	{
		if ( self.UAVRemoteMarkedBy != attacker )
			self.UAVRemoteMarkedBy thread maps\mp\killstreaks\_remoteuav::remoteUAV_processTaggedAssist( self );
		self.UAVRemoteMarkedBy = undefined;
	}
	*/
	if ( IsDefined( self.motionSensorMarkedBy ) )
	{
		if ( self.motionSensorMarkedBy != attacker )
			self.motionSensorMarkedBy thread maps\mp\gametypes\_weapons::motionSensor_processTaggedAssist( self );
		self.motionSensorMarkedBy = undefined;
	}

	if ( IsDefined( level.onNormalDeath ) && attacker.pers[ "team" ] != "spectator" )
		[[ level.onNormalDeath ]]( self, attacker, lifeId );

	if ( !level.teamBased )
	{
		// see note below about self.attackers
		self.attackers = [];
		return;
	}

	level thread maps\mp\gametypes\_battlechatter_mp::sayLocalSoundDelayed( attacker, "kill", 0.75 );	
	
	if ( IsDefined( self.lastAttackedShieldPlayer ) && IsDefined( self.lastAttackedShieldTime ) && self.lastAttackedShieldPlayer != attacker )
	{
		if ( getTime() - self.lastAttackedShieldTime < 2500 )
		{
			self.lastAttackedShieldPlayer thread maps\mp\gametypes\_gamescore::processShieldAssist( self );
			
			// if you are using the assists perk, then every assist is a kill towards a killstreak
			if( self.lastAttackedShieldPlayer _hasPerk( "specialty_assists" ) )
			{
				self.lastAttackedShieldPlayer.pers["assistsToKill"]++;

				if( !( self.lastAttackedShieldPlayer.pers["assistsToKill"] % 2 ) )
				{
					self.lastAttackedShieldPlayer maps\mp\gametypes\_missions::processChallenge( "ch_hardlineassists" );
					self.lastAttackedShieldPlayer maps\mp\killstreaks\_killstreaks::giveAdrenaline( "kill" );
					self.lastAttackedShieldPlayer.pers["cur_kill_streak"]++;
				}
			}
			else
			{
				self.lastAttackedShieldPlayer.pers["assistsToKill"] = 0;
			}
		}
		else if ( isAlive( self.lastAttackedShieldPlayer ) && getTime() - self.lastAttackedShieldTime < 5000 )
		{
			forwardVec = vectorNormalize( anglesToForward( self.angles ) );
			shieldVec = vectorNormalize( self.lastAttackedShieldPlayer.origin - self.origin );
		
			if ( vectorDot( shieldVec, forwardVec ) > 0.925 )
			{
				self.lastAttackedShieldPlayer thread maps\mp\gametypes\_gamescore::processShieldAssist( self );
				
				// if you are using the assists perk, then every assist is a kill towards a killstreak
				if( self.lastAttackedShieldPlayer _hasPerk( "specialty_assists" ) )
				{
					self.lastAttackedShieldPlayer.pers["assistsToKill"]++;

					if( !( self.lastAttackedShieldPlayer.pers["assistsToKill"] % 2 ) )
					{
						self.lastAttackedShieldPlayer maps\mp\gametypes\_missions::processChallenge( "ch_hardlineassists" );
						self.lastAttackedShieldPlayer maps\mp\killstreaks\_killstreaks::giveAdrenaline( "kill" );
						self.lastAttackedShieldPlayer.pers["cur_kill_streak"]++;
					}
				}
				else
				{
					self.lastAttackedShieldPlayer.pers["assistsToKill"] = 0;
				}
			}
		}
	}	

	//	regular assists
	if ( IsDefined( self.attackers ) )
	{
		foreach ( player in self.attackers )
		{
			if ( !IsDefined( _validateAttacker( player ) ) )
				continue;

			if ( player == attacker )
				continue;

			// don't let the victim get an assist off of themselves
			//	this fixes a bug where the player could injure themselves from a ridable killstreak (ac130, predator, reaper, remote turret) at the same time that an enemy kills them
			//	it would then result in invincibility, the player wouldn't die and couldn't die because we were trying to give them a killstreak point
			//	and the script would get stuck looping because they are in the middle of changing weapons while in a ridable killstreak (giveKillstreakWeapon() loop)
			if( self == player )
				continue;

			if ( IsDefined( level.assists_disabled ) )
				continue;
			
			player thread maps\mp\gametypes\_gamescore::processAssist( self );

			// if you are using the assists perk, then every assist is a kill towards a killstreak
			if( player _hasPerk( "specialty_assists" ) )
			{
				player.pers["assistsToKill"]++;

				if( !( player.pers["assistsToKill"] % 2 ) )
				{
					player maps\mp\gametypes\_missions::processChallenge( "ch_hardlineassists" );
					player registerKill( sWeapon, false );
				}
			}
			else
			{
				player.pers["assistsToKill"] = 0;
			}
		}
		
		// 2013-09-11 wallace: can't reset attackerData yet, because missions.gsc needs it after death
		// I'm not sure why we're resetting attackers here, but I will live it alone for now. (was in v.1 of this file)
		self.attackers = [];
	}
}

IsPlayerWeapon( weaponName )
{
	if ( weaponClass( weaponName ) == "non-player" )
		return false;
		
	if ( weaponClass( weaponName ) == "turret" )
		return false;

	if ( weaponInventoryType( weaponName ) == "primary" || weaponInventoryType( weaponName ) == "altmode" )
		return true;
		
	return false;
}


waitSkipKillcamButtonDuringDeathTimer()
{
	self endon("disconnect");
	self endon("killcam_death_done_waiting");
	
	self NotifyOnPlayerCommand( "death_respawn", "+usereload" );
	self NotifyOnPlayerCommand( "death_respawn", "+activate" );
	
	self waittill("death_respawn");
	self notify( "killcam_death_button_cancel" );
}

waitSkipKillCamDuringDeathTimer( waitTime )
{
	self endon("disconnect");
	self endon("killcam_death_button_cancel");
	
	wait( waitTime );
	self notify( "killcam_death_done_waiting" );
}
	
skipKillcamDuringDeathTimer( waitTime )
{
	self endon("disconnect");
	
	if ( level.showingFinalKillcam )
		return false;
	
	if ( !IsAI( self ) )
	{
		self thread waitSkipKillcamButtonDuringDeathTimer();
		self thread waitSkipKillCamDuringDeathTimer( waitTime );
		
		result = waittill_any_return( "killcam_death_done_waiting", "killcam_death_button_cancel" );
		
		if ( result == "killcam_death_done_waiting" )
			return false;
		else
			return true;
	}
	
	return false;
}


Callback_PlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	PlayerKilled_internal( eInflictor, attacker, self, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, false );
}


QueueShieldForRemoval( shield )
{
	MY_MAX_SHIELDS_AT_A_TIME = 5;

	if ( !IsDefined( level.shieldTrashArray ) )
		level.shieldTrashArray = [];

	if ( level.shieldTrashArray.size >= MY_MAX_SHIELDS_AT_A_TIME )
	{
		idxMax = (level.shieldTrashArray.size - 1);
		level.shieldTrashArray[0] delete();
		for ( idx = 0; idx < idxMax; idx++ )
			level.shieldTrashArray[idx] = level.shieldTrashArray[idx + 1];
		level.shieldTrashArray[idxMax] = undefined;
	}

	level.shieldTrashArray[level.shieldTrashArray.size] = shield;
}


LaunchShield( damage, meansOfDeath )
{
	if ( IsDefined( self.hasRiotShieldEquipped ) && self.hasRiotShieldEquipped )
	{
		// If the player is planting a trophy the riotshield may be temporarily
		// stowed. Make sure the model is detached.
		if ( IsDefined( self.riotShieldModel ) )
		{
			self riotShield_detach( true );
		}
		else if ( IsDefined( self.riotShieldModelStowed ) )
		{
			self riotShield_detach( false );
		}
	}
}

PlayerKilled_internal( eInflictor, attacker, victim, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, isFauxDeath )
{
/#
	//// print sniper hit info to the player so we can see why we get hit markers instead of kills
	////	this is also happening in player damage so we can see if they get killed or not
	//if( IsDefined( sWeapon ) && getWeaponClass( sWeapon ) == "weapon_sniper" )
	//{
	//	//IPrintLn( "=========================" );
	//	//IPrintLn( "PlayerKilled_internal" );
	//	//IPrintLn( sWeapon );
	//	//if( IsPlayer( attacker ) )
	//	//	IPrintLn( "Attacker: " + attacker.name );
	//	//if( IsPlayer( victim ) )
	//	//	IPrintLn( "Victim: " + victim.name + " alive? " + IsAlive( victim ) );
	//	//IPrintLn( "Damage: " + iDamage );
	//	//IPrintLn( "Hit Loc: " + sHitLoc );
	//	//IPrintLn( "Time of death: " + GetTime() );

	//	PrintLn( "=========================" );
	//	PrintLn( "PlayerKilled_internal" );
	//	PrintLn( sWeapon );
	//	if( IsPlayer( attacker ) )
	//		PrintLn( "Attacker: " + attacker.name );
	//	if( IsPlayer( victim ) )
	//		PrintLn( "Victim: " + victim.name + " alive? " + IsAlive( victim ) );
	//	PrintLn( "Damage: " + iDamage );
	//	PrintLn( "Hit Loc: " + sHitLoc );
	//	PrintLn( "Time of death: " + GetTime() );
	//}
#/	
	//prof_begin( "PlayerKilled" );
	prof_begin( " PlayerKilled_1" );

	victim endon( "spawned" );
	victim notify( "killed_player" );
	
	// reset some ui omnvars
	victim maps\mp\gametypes\_playerlogic::resetUIDvarsOnDeath();

	// Set it so the respwaned player can get another ability from Gambler
	victim.abilityChosen = false;
	victim.perkOutlined = false;
	
	// HACK: Overwrite the obituary for when players are killed by crates, so it is always seen as a suicide
	// This is to fix the issue where kills are awarded to players who "technically" own the crates in games like Hunted
	if ( gameHasNeutralCrateOwner( level.gameType ) )
	{	
		if ( victim != attacker && sMeansOfDeath == "MOD_CRUSH" )
		{
			eInflictor = victim;
			attacker = victim;
			sMeansofDeath = "MOD_SUICIDE";
			sWeapon = "none";
			sHitLoc = "none";	
			victim.attackers = [];
		}
	}

	assert( victim.sessionteam != "spectator" );
	
	attacker = _validateAttacker( attacker );

	if ( IsDefined( attacker ) )
		attacker.assistedSuicide = undefined;

	if ( !IsDefined( victim.idFlags ) )
	{
		if ( sMeansOfDeath == "MOD_SUICIDE" )
			victim.idFlags = 0;
		else if ( sMeansOfDeath == "MOD_GRENADE" )
			if( ( IsSubStr( sWeapon, "frag_grenade" ) || IsSubStr( sWeapon, "thermobaric_grenade" ) || IsSubStr( sWeapon, "mortar_shell" ) ) && iDamage == 100000 )
				victim.idFlags = 0;
		else if ( sWeapon == "nuke_mp" )
			victim.idFlags = 0;
		else if ( level.friendlyfire >= 2)
			victim.idFlags = 0;
		else
			assertEx( 0, "Victims ID flags not set, sMeansOfDeath == " + sMeansOfDeath  );
	}

	if ( IsDefined( victim.hasRiotShieldEquipped ) && victim.hasRiotShieldEquipped )
		victim LaunchShield( iDamage, sMeansofDeath );
	
	victim riotShield_clear();

	// Record here instead of in a waittill( "death" ) thread
	// because the player is still holding the drop weapon
	maps\mp\gametypes\_weapons::recordToggleScopeStates();
	
	//victim thread checkForceBleedOut();

	if ( !isFauxDeath )
	{
		if ( IsDefined( victim.endGame ) )
		{
			self restoreBaseVisionSet( 2 );
		}
		else
		{
			self restoreBaseVisionSet( 0 );
			victim ThermalVisionOff();
		}
	}
	else
	{
		victim.fauxDead = true;
		self notify ( "death" );
	}

	if ( game[ "state" ] == "postgame" )
	{
		//prof_end( " PlayerKilled_1" );
		prof_end( "PlayerKilled" );
		return;
	}
	
	// Update all active perks for the attacker/victim
	maps\mp\perks\_perks::updateActivePerks( eInflictor, attacker, victim, iDamage, sMeansOfDeath );

	// replace params with last stand info
	deathTimeOffset = 0;

	if ( !IsPlayer( eInflictor ) && IsDefined( eInflictor.primaryWeapon ) )
	{
		sPrimaryWeapon = eInflictor.primaryWeapon;
	}
	else if ( IsDefined( attacker ) && IsPlayer( attacker ) && attacker getCurrentPrimaryWeapon() != "none" )
	{
		sPrimaryWeapon = attacker getCurrentPrimaryWeapon();
	}
	else//getCurrentPrimaryWeapon() will return none if the player is: ladder, grenade, killstreak placment, etc...
	{
		if ( isSubStr( sWeapon, "alt_" ) )
		{
			sPrimaryWeapon = GetSubStr( sWeapon, 4, sWeapon.size );
		}
		else//killstreak weapon or offhand
		{
			sPrimaryWeapon = undefined;
		}
	}
		
	if ( IsDefined( victim.useLastStandParams ) || ( IsDefined( victim.lastStandParams ) && sMeansOfDeath == "MOD_SUICIDE" ) )
	{
		victim ensureLastStandParamsValidity();
		victim.useLastStandParams = undefined;

		assert( IsDefined( victim.lastStandParams ) );

		eInflictor = victim.lastStandParams.eInflictor;
		attacker = victim.lastStandParams.attacker;
		iDamage = victim.lastStandParams.iDamage;
		sMeansOfDeath = victim.lastStandParams.sMeansOfDeath;
		sWeapon = victim.lastStandParams.sWeapon;
		sPrimaryWeapon = victim.lastStandParams.sPrimaryWeapon;
		vDir = victim.lastStandParams.vDir;
		sHitLoc = victim.lastStandParams.sHitLoc;

		deathTimeOffset = ( gettime() - victim.lastStandParams.lastStandStartTime ) / 1000;
		victim.lastStandParams = undefined;
		
		attacker = _validateAttacker( attacker );
	}

	prof_end( " PlayerKilled_1" );
	prof_begin( " PlayerKilled_2" );

	//used for endgame perk and assisted suicide.
	if ( (!IsDefined( attacker ) || attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" || attacker == victim ) && IsDefined( self.attackers )  )
	{
		bestPlayer = undefined;

		foreach ( player in self.attackers )
		{
			if ( !IsDefined( _validateAttacker( player ) ) )
				continue;

			if (! IsDefined( victim.attackerData[ player.guid ].damage ) )
				continue;

			if ( player == victim || (level.teamBased && player.team == victim.team ) )
				continue;

			if ( victim.attackerData[ player.guid ].lasttimedamaged + 2500 < getTime() && ( attacker != victim && ( IsDefined(victim.lastStand) && victim.lastStand ) ) )
				continue;			

			if ( victim.attackerData[ player.guid ].damage > 1 && ! IsDefined( bestPlayer ) )
				bestPlayer = player;
			else if ( IsDefined( bestPlayer ) && victim.attackerData[ player.guid ].damage > victim.attackerData[ bestPlayer.guid ].damage )
				bestPlayer = player;		
		}

		if ( IsDefined( bestPlayer ) )
		{
			attacker = bestPlayer;
			attacker.assistedSuicide = true;
			sWeapon = victim.attackerData[ bestPlayer.guid ].weapon; 
			vDir = victim.attackerData[ bestPlayer.guid ].vDir;
			sHitLoc = victim.attackerData[ bestPlayer.guid ].sHitLoc;
			psOffsetTime = victim.attackerData[ bestPlayer.guid ].psOffsetTime;
			sMeansOfDeath = victim.attackerData[ bestPlayer.guid ].sMeansOfDeath;
			iDamage = victim.attackerData[ bestPlayer.guid ].damage;
			sPrimaryWeapon = victim.attackerData[ bestPlayer.guid ].sPrimaryWeapon;
			eInflictor = attacker;
		}
	}
	else
	{
		if ( IsDefined( attacker ) )
			attacker.assistedSuicide = undefined;	
	}

	// override MOD
	if ( isHeadShot( sWeapon, sHitLoc, sMeansOfDeath, attacker ) )
		sMeansOfDeath = "MOD_HEAD_SHOT";
	else if ( !IsDefined( victim.nuked ) )
	{
		// Used for custom death animation sounds				
		if ( IsDefined( level.custom_death_sound ) )
			[[ level.custom_death_sound ]]( victim, sMeansOfDeath, eInflictor );
		else if ( sMeansOfDeath != "MOD_MELEE" )
			victim playDeathSound();
	}
	
	// Custom visual effect you want to play when the player dies
	if ( IsDefined( level.custom_death_effect ) )
		[[ level.custom_death_effect ]]( victim, sMeansOfDeath, eInflictor );
	
	friendlyFire = isFriendlyFire( victim, attacker );

	if ( IsDefined( attacker ) )
	{
		// override attacker if it's a vehicle	
		if ( attacker.code_classname == "script_vehicle" && IsDefined( attacker.owner ) )
		{
			attacker = attacker.owner;
		}

		// override attacker if it's a sentry	
		if ( attacker.code_classname == "misc_turret" && IsDefined( attacker.owner ) )
		{
			if ( IsDefined( attacker.vehicle ) )
				attacker.vehicle notify( "killedPlayer", victim );

			attacker = attacker.owner;
		}
		
		if( IsAgent(attacker) )
		{
			sWeapon = "agent_mp";
			sMeansOfDeath = "MOD_RIFLE_BULLET";
			
			if( IsDefined( attacker.agent_type ) )
			{
				if( attacker.agent_type == "dog" )
			 		sWeapon = "guard_dog_mp";
				else if( attacker.agent_type == "squadmate" )
					sWeapon = "agent_support_mp";
				else if ( attacker.agent_type == "pirate" )
					sWeapon = "pirate_agent_mp";
				else if ( attacker.agent_type == "wolf" )	// 2014-05-30 wallace: this is the mp_mine killstreak, not the wolf skin
					sWeapon = "killstreak_wolfpack_mp";
				else if ( attacker.agent_type == "beastmen" )
					sWeapon = "beast_agent_mp";
			}
			
			if( IsDefined(attacker.owner) )
				attacker = attacker.owner;
		}

		// override attacker if it's a crate	
		if ( attacker.code_classname == "script_model" && IsDefined( attacker.owner ) )
		{
			attacker = attacker.owner;

			if ( !isFriendlyFire( victim, attacker ) && attacker != victim )
				attacker notify( "crushed_enemy" );
		}
	}
 
	if ( (sMeansOfDeath != "MOD_SUICIDE") && ( IsAIGameParticipant( victim ) || IsAIGameParticipant( attacker ) ) && IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["get_attacker_ent"] ) )
    {
		killing_entity = [[ level.bot_funcs["get_attacker_ent"] ]]( attacker, eInflictor );
		if ( IsDefined(killing_entity) )
		{
			if ( IsAIGameParticipant( victim ) )
	        {
				// The "get_attacker_ent" should never return the worldspawn as the attacker, so if it has, then something is unhandled in that function
				Assert(killing_entity.classname != "worldspawn" && killing_entity.classname != "trigger_hurt");
				victim BotMemoryEvent( "death", sWeapon, killing_entity.origin, victim.origin, killing_entity );
	        }
	        
	        if ( IsAIGameParticipant( attacker ) )
	        {
	        	should_record_kill = true;
	        	if ( (killing_entity.classname == "script_vehicle" && IsDefined(killing_entity.helitype)) || killing_entity.classname == "rocket" || killing_entity.classname == "misc_turret" )
					should_record_kill = false;	        		// Don't record memory event if bot killed someone from the air
				
	        	if ( should_record_kill )
	        		attacker BotMemoryEvent( "kill", sWeapon, killing_entity.origin, victim.origin, victim );
	        }
	    }
    }

    prof_end( " PlayerKilled_2" );
	prof_begin( " PlayerKilled_3" );

	prof_begin( " PlayerKilled_3_drop" );
	// drop weapons from killed player
	victim maps\mp\gametypes\_weapons::dropScavengerForDeath( attacker );	// must be done before dropWeaponForDeath, since we use some weapon information
	victim [[level.weaponDropFunction]]( attacker, sMeansOfDeath );
	prof_end( " PlayerKilled_3_drop" );

	if ( !isFauxDeath )
	{
		victim updateSessionState( "dead", "hud_status_dead" );
	}

	// UTS update aliveCount
	switching_teams_while_already_dead = IsDefined(victim.fauxDead) && victim.fauxDead && IsDefined(victim.switching_teams) && victim.switching_teams;
	if ( !switching_teams_while_already_dead )	// If player is switching teams while he is already dead, then he has already been removed from the alive count
		victim maps\mp\gametypes\_playerlogic::removeFromAliveCount();

	// update our various stats
	if ( !IsDefined( victim.switching_teams ) )
	{
		deathDebitTo = victim;
		if ( IsDefined( victim.commanding_bot ) )
		{
			deathDebitTo = victim.commanding_bot;
		}	

		if( IsDefined(level.isHorde) )
		{
			deathDebitTo.deaths++;
		}
		else
		{
			dontStoreKillsValue = false;
			if ( IsSquadsMode() )
				dontStoreKillsValue = true;
			
			deathDebitTo incPersStat( "deaths", 1, dontStoreKillsValue );
			deathDebitTo.deaths = deathDebitTo getPersStat( "deaths" );
			deathDebitTo updatePersRatio( "kdRatio", "kills", "deaths" );
			deathDebitTo maps\mp\gametypes\_persistence::statSetChild( "round", "deaths", deathDebitTo.deaths );
			deathDebitTo incPlayerStat( "deaths", 1 );
		}
	}

	if ( IsDefined( attacker ) && IsPlayer(attacker) )
		attacker checkKillSteal( victim );

	// obituary
	obituary( victim, attacker, sWeapon, sMeansOfDeath );

	doKillcam = false;

	lifeId = victim maps\mp\_matchdata::logPlayerLife();
	victim maps\mp\_matchdata::logPlayerDeath( lifeId, attacker, iDamage, sMeansOfDeath, sWeapon, sPrimaryWeapon, sHitLoc );

	if ( IsPlayer( attacker ) )
	{
		if ( (sMeansOfDeath == "MOD_MELEE") )
		{
			if ( maps\mp\gametypes\_weapons::isRiotShield( sWeapon ) )
			{
				attacker incPlayerStat( "shieldkills", 1 );

				if ( !matchMakingGame() )
					victim incPlayerStat( "shielddeaths", 1 );
			}
			else
			{
				attacker incPlayerStat( "knifekills", 1 );
			}
			
			addAttacker( victim, attacker, eInflictor, sWeapon, iDamage, (0,0,0), vDir, sHitLoc, psOffsetTime, sMeansOfDeath );
		}
	}

	prof_end( " PlayerKilled_3" );
	prof_begin( " PlayerKilled_4" );

	if ( victim isSwitchingTeams() )
	{
		handleTeamChangeDeath();
	}
	else if ( !IsPlayer( attacker ) || (IsPlayer( attacker ) && sMeansOfDeath == "MOD_FALLING") )
	{
		handleWorldDeath( attacker, lifeId, sMeansOfDeath, sHitLoc );
		
		if( IsAgent(attacker) )
			doKillcam = true;
	}
	else if ( attacker == victim )
	{
		handleSuicideDeath( sMeansOfDeath, sHitLoc );
	}
	else if ( friendlyFire )
	{
		if ( !(IsDefined( victim.nuked ) || sWeapon == "bomb_site_mp" ) )
		{
			handleFriendlyFireDeath( attacker );
		}
	}
	else
	{
		if ( (sMeansOfDeath == "MOD_GRENADE" && eInflictor == attacker) )
			addAttacker( victim, attacker, eInflictor, sWeapon, iDamage, (0,0,0), vDir, sHitLoc, psOffsetTime, sMeansOfDeath );

		doKillcam = true;
		if( IsAI( victim ) && IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["should_do_killcam"] ) )
			doKillcam = victim [[ level.bot_funcs["should_do_killcam"] ]]();
		
		if(isDefined(level.disable_killcam) && level.disable_killcam)
			doKillcam = false;
		
		handleNormalDeath( lifeId, attacker, eInflictor, sWeapon, sMeansOfDeath );
		victim thread maps\mp\gametypes\_missions::playerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sPrimaryWeapon, sHitLoc, attacker.modifiers );

		victim.pers["cur_death_streak"]++;

		// team splash if juggernaut was killed
		if( IsPlayer( attacker ) && victim isJuggernaut() )
		{
			if ( IsDefined( victim.isJuggernautManiac) && victim.isJuggernautManiac )
			{
				attacker thread teamPlayerCardSplash( "callout_killed_maniac", attacker );
				// OP_IW6 This is a knife: kill an enemy maniac with a knife
				if ( sMeansOfDeath == "MOD_MELEE" )
				{
					attacker maps\mp\gametypes\_missions::processChallenge( "ch_thisisaknife" );
				}
			}
			else if ( IsDefined( victim.isJuggernautLevelCustom) && victim.isJuggernautLevelCustom )
			{
				AssertEx( IsDefined( level.mapCustomJuggKilledSplash ), "level.mapCustomJuggKilledSplash must be defined for custom juggernaut!" );
				attacker thread teamPlayerCardSplash( level.mapCustomJuggKilledSplash, attacker );
			}
			else
			{
				attacker thread teamPlayerCardSplash( "callout_killed_juggernaut", attacker );
			}
		}
	}
	
	// Don't increment weapon stats for team kills or deaths
	wasInLastStand = false;
	lastWeaponBeforeDroppingIntoLastStand = undefined;
	if ( IsDefined( self.previousPrimary ) )
	{
		wasInLastStand = true;
		lastWeaponBeforeDroppingIntoLastStand = self.previousPrimary;
		self.previousprimary = undefined;
	}
	
	if ( IsPlayer( attacker ) && attacker != self && ( !level.teamBased || ( level.teamBased && self.team != attacker.team ) ) )
	{

		if ( wasInLastStand && IsDefined( lastWeaponBeforeDroppingIntoLastStand ) ) 
			weaponName = lastWeaponBeforeDroppingIntoLastStand;
		else
			weaponName = self.lastdroppableweapon;
		
		// If the player's held weapon is a weapon that requires mapping,
		// make sure it gets mapped before logging stats.
		weaponName = weaponMap( weaponName );
		
		self thread  maps\mp\gametypes\_gamelogic::trackLeaderBoardDeathStats( weaponName, sMeansOfDeath ); 

		attacker thread  maps\mp\gametypes\_gamelogic::trackAttackerLeaderBoardDeathStats( sWeapon, sMeansOfDeath ); 
	}

	if ( IsDefined( attacker ) && IsDefined( victim ) )
	{
		bbprint( "kills", "attackername %s attackerteam %s attackerx %f attackery %f attackerz %f attackerweapon %s victimx %f victimy %f victimz %f victimname %s victimteam %s damage %i damagetype %s damagelocation %s attackerisbot %i victimisbot %i timesincespawn %f", attacker.name, attacker.team, attacker.origin[0], attacker.origin[1], attacker.origin[2], sWeapon, victim.origin[0], victim.origin[1], victim.origin[2], victim.name, victim.team, iDamage, sMeansOfDeath, sHitLoc, IsAI( attacker ), IsAI( victim ), ((getTime()-victim.lastSpawnTime)/1000) );
	}

	prof_end( " PlayerKilled_4" );
	prof_begin( " PlayerKilled_5" );

	//	- onPlayerKilled (called after resetPlayerVariables() has no way to differentiate between change team suicide and falling crate suicide
	//	- probably too risky to move resetPlayerVariables() to after onPlayerKilled right now
	victim.wasSwitchingTeamsForOnPlayerKilled = undefined; // this should never get set to false, either undefined or true
	if ( IsDefined( victim.switching_teams ) )
		victim.wasSwitchingTeamsForOnPlayerKilled = true;

	// clear any per life variables
	victim resetPlayerVariables();
	victim.lastAttacker = attacker;
	victim.lastDeathPos = victim.origin;
	victim.deathTime = getTime();
	victim.wantSafeSpawn = false;
	victim.revived = false;
	victim.sameShotDamage = 0;

	if( maps\mp\killstreaks\_killstreaks::streakTypeResetsOnDeath( victim.streakType ) )
		victim maps\mp\killstreaks\_killstreaks::resetAdrenaline();

	killcamentity = undefined;
	if ( self isRocketCorpse() )
	{
		doKillcam = true;
		isFauxDeath = false;
		killcamentity = self.killCamEnt;
		self waittill( "final_rocket_corpse_death" );
	}
	else
	{
		if ( isFauxDeath )
		{
			doKillcam = false;
			deathAnimDuration = (victim PlayerForceDeathAnim( eInflictor, sMeansOfDeath, sWeapon, sHitLoc, vDir ));
		}
	
		victim.body = victim clonePlayer( deathAnimDuration );
		victim.body.targetname = "player_corpse";
		
		if ( isFauxDeath )
			victim PlayerHide();
	
		if ( victim isOnLadder() || victim isMantling() || !victim isOnGround() || IsDefined( victim.nuked ) || IsDefined( victim.customDeath ) )
		{
			// don't want to instantly go into ragdoll if dying from melee while planting bomb or during "nuke" state.
			// note that victim isOnGround() is false when player is planting
			skipInstantRagdoll = false;
			
			if ( sMeansOfDeath == "MOD_MELEE" ) 
			{
				if ((IsDefined( victim.isPlanting ) && victim.isPlanting) || IsDefined( victim.nuked ) )
					skipInstantRagdoll = true;
			}
			
			if ( !skipInstantRagdoll )
			{
				victim.body startRagDoll();
				victim notify ( "start_instant_ragdoll", sMeansOfDeath, eInflictor );
			}
		}

		if ( !IsDefined( victim.switching_teams ) )
		{
			if (isDefined(attacker) && isPlayer( attacker ) && !attacker _hasPerk("specialty_silentkill"))
				thread maps\mp\gametypes\_deathicons::addDeathicon( victim.body, victim, victim.team, 5.0 );
		}
		thread delayStartRagdoll( victim.body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath );
	}

	// allow per gametype death handling	
	victim thread [[ level.onPlayerKilled ]]( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, lifeId );

	if( IsAI( victim ) && IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["on_killed"] ) )
		victim thread [[ level.bot_funcs["on_killed"] ]]( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, lifeId );

	if ( IsGameParticipant( attacker ) )
		attackerNum = attacker getEntityNumber();
	else
		attackerNum = -1;
	
	if ( !IsDefined( killcamentity ) )
		killcamentity = victim getKillcamEntity( attacker, eInflictor, sWeapon );
	
	killcamentityindex = -1;
	killcamentitystarttime = 0;

	if ( IsDefined( killcamentity ) )
	{
		killcamentityindex = killcamentity getEntityNumber();// must do this before any waiting lest the entity be deleted
		killcamentitystarttime = killcamentity.birthtime;
		if ( !IsDefined( killcamentitystarttime ) )
			killcamentitystarttime = 0;
	}

/#
	if ( getDvarInt( "scr_forcekillcam" ) != 0 )
		doKillcam = true;
#/
	prof_end( " PlayerKilled_5" );
	prof_begin( " PlayerKilled_6" );

	///////////////////////////////////////////////////////
	// KILL CAM STUFF

	// record the kill cam values for the final kill cam
	if ( (!isDefined(level.disable_killcam) || !level.disable_killcam) && sMeansOfDeath != "MOD_SUICIDE" && !( !IsDefined( attacker ) || attacker.classname == "trigger_hurt" || attacker.classname == "worldspawn" || attacker == victim ) )
	{
		recordFinalKillCam( 5.0, victim, attacker, attackerNum, eInflictor, killcamentityindex, killcamentitystarttime, sWeapon, deathTimeOffset, psOffsetTime, sMeansOfDeath );
	}

	// tell the ingame killcam ui what to say, this was tried but has an issue with new players not understanding, maybe just needs new text that is understood
	victim SetCommonPlayerData( "killCamHowKilled", 0 );
	switch( sMeansOfDeath )
	{
	case "MOD_HEAD_SHOT":
		victim SetCommonPlayerData( "killCamHowKilled", 1 );
		break;

	//case "MOD_MELEE":
	//	victim SetCommonPlayerData( "killCamHowKilled", 2 );
	//	break;

	//case "MOD_RIFLE_BULLET":
	//case "MOD_PISTOL_BULLET":
	//	if( attacker PlayerAds() <= 0.5 )
	//		victim SetCommonPlayerData( "killCamHowKilled", 3 );
	//	else
	//		victim SetCommonPlayerData( "killCamHowKilled", 4 );
	//	break;

	//case "MOD_GRENADE_SPLASH":
	//case "MOD_GRENADE":
	//	weaponTokens = StrTok( sWeapon, "_" );
	//	if( "gl" == weaponTokens[0] )
	//		victim SetCommonPlayerData( "killCamHowKilled", 5 );
	//	break;

	//case "MOD_IMPACT":
	//	weaponTokens = StrTok( sWeapon, "_" );
	//	if( "gl" == weaponTokens[0] )
	//		victim SetCommonPlayerData( "killCamHowKilled", 6 );
	//	break;

	default:
		break;
	}

	//// check for camping last because it'll override the others
	//if( IsDefined( attacker.lastKillWasCamping ) && attacker.lastKillWasCamping )
	//	victim SetCommonPlayerData( "killCamHowKilled", 7 );

	// END KILL CAM
	///////////////////////////////////////////////////////

	inflictorAgentInfo = undefined;
	
	if ( doKillcam )
	{
		victim maps\mp\gametypes\_killcam::preKillcamNotify( eInflictor, attacker );
		
		// make sure to cache off the agent_type before the inflictor could die during the wait( 1.0 ) below
		// if agent dies before call to ::killcam, it's script variables all get reset and become invalid
		if ( IsDefined( eInflictor ) && IsAgent( eInflictor ) )
		{
			inflictorAgentInfo = spawnStruct();
			inflictorAgentInfo.agent_type = eInflictor.agent_type;
			inflictorAgentInfo.lastSpawnTime = eInflictor.lastSpawnTime;
		}
	}
	
	
	if ( !isFauxDeath )
	{
		// 2016-06-26 wallace
		// Removing the cancel handler from damage in favor to waitSkipKillcamButton contained within cancelKillCam
		// Previously, both were being called, but cancelKillCamOnUse did some clunky polling instead of waiting for events
		/*
		wait( 0.25 );
		victim thread maps\mp\gametypes\_killcam::cancelKillCamOnUse();
		wait( 0.25 );
		*/

		self.respawnTimerStartTime = gettime() + 1000;
		timeUntilSpawn = maps\mp\gametypes\_playerlogic::TimeUntilSpawn( true );
		if ( timeUntilSpawn < 1 )
			timeUntilSpawn = 1;
		victim thread maps\mp\gametypes\_playerlogic::predictAboutToSpawnPlayerOverTime( timeUntilSpawn );

		wait( 1.0 );
		
		if ( doKillcam )
		{
			// allow half a second before going into killcam to allow player to skip entering killcam and immediately respawn
			doKillcam = !skipKillcamDuringDeathTimer( 0.5 );
		}
		
		victim notify( "death_delay_finished" );
	}

	postDeathDelay = ( getTime() - victim.deathTime ) / 1000;
	self.respawnTimerStartTime = gettime();
	
	doKillcam = doKillcam && !(victim maps\mp\gametypes\_battlebuddy::canBuddySpawn());

	if ( !(IsDefined( victim.cancelKillcam) && victim.cancelKillcam) && doKillcam && level.killcam && game[ "state" ] == "playing" && !victim isUsingRemote() && !level.showingFinalKillcam )
	{
		livesLeft = !( getGametypeNumLives() && !victim.pers[ "lives" ] );
		timeUntilSpawn = maps\mp\gametypes\_playerlogic::TimeUntilSpawn( true );
		willRespawnImmediately = livesLeft && ( timeUntilSpawn <= 0 );

		if ( !livesLeft ) 
		{
			timeUntilSpawn = -1;
			level notify( "player_eliminated", victim );
		}

		victim maps\mp\gametypes\_killcam::killcam( eInflictor, inflictorAgentInfo, attackerNum, killcamentityindex, killcamentitystarttime, sWeapon, postDeathDelay + deathTimeOffset, psOffsetTime, timeUntilSpawn, maps\mp\gametypes\_gamelogic::timeUntilRoundEnd(), attacker, victim, sMeansOfDeath );
	}
	
	//if( IsDefined( killcamentity ) )
	//	killcamentity Delete();

	prof_end( " PlayerKilled_6" );
	prof_begin( " PlayerKilled_7" );

	if ( game[ "state" ] != "playing" )
	{
		if ( !level.showingFinalKillcam )
		{
			victim updateSessionState( "dead" );
			victim ClearKillcamState();
		}

		prof_end( " PlayerKilled_7" );
		prof_end( "PlayerKilled" );
		return;
	}

	gameTypeLives = getGametypeNumLives();
	playerLives = self.pers["lives"];
	
	if ( self == victim && IsDefined( victim.battleBuddy ) && isReallyAlive( victim.battleBuddy ) && ( !getGametypeNumLives() || self.pers["lives"] ) && !victim isUsingRemote() )
	{
		self maps\mp\gametypes\_battlebuddy::waitForPlayerRespawnChoice();
	}
	
	// class may be undefined if we have changed teams
	if ( isValidClass( victim.class ) )
	{
		victim thread maps\mp\gametypes\_playerlogic::spawnClient();
	}

	prof_end( " PlayerKilled_7" );
	//prof_end( "PlayerKilled" );
}


checkForceBleedout()
{
	if ( level.dieHardMode != 1 )
		return false;
	
	if ( !getGametypeNumLives() )
		return false;
	
	if ( level.livesCount[self.team] > 0 )
		return false;
	
	foreach ( player in level.players )
	{
		if ( !isAlive( player ) )
			continue;
			
		if ( player.team != self.team )
			continue;
			
		if ( player == self )
			continue;
		
		if ( !player.inLastStand )
			return false;
	}
	
	foreach ( player in level.players )
	{
		if ( !isAlive( player ) )
			continue;
		
		if ( player.team != self.team )
			continue;
		
		if ( player.inLastStand && player != self )
			player lastStandBleedOut(false);		
	}
	
	return true;					
}

checkKillSteal( vic )
{
	if ( matchMakingGame() )
		return;
	
	greatestDamage = 0;
	greatestAttacker = undefined;
	
	if ( IsDefined( vic.attackerdata ) && vic.attackerdata.size > 1 )	
	{
		foreach ( attacker in vic.attackerdata )
		{
			if ( attacker.damage > greatestDamage )
			{
				greatestDamage = attacker.damage;
				greatestAttacker = attacker.attackerEnt;	
			}
		}
		
		if ( IsDefined( greatestAttacker ) && greatestAttacker != self )
			self incPlayerStat( "killsteals", 1 );
	}
}

initFinalKillCam()
{
	level.finalKillCam_delay					= [];
	level.finalKillCam_victim					= [];
	level.finalKillCam_attacker					= [];
	level.finalKillCam_attackerNum				= [];
	level.finalKillCam_inflictor				= [];
	level.finalKillCam_inflictor_agent_type		= [];
	level.finalKillCam_inflictor_lastSpawnTime	= [];
	level.finalKillCam_killCamEntityIndex		= [];
	level.finalKillCam_killCamEntityStartTime	= [];
	level.finalKillCam_sWeapon					= [];
	level.finalKillCam_deathTimeOffset			= [];
	level.finalKillCam_psOffsetTime				= [];
	level.finalKillCam_timeRecorded				= [];
	level.finalKillCam_timeGameEnded			= [];
	level.finalKillCam_sMeansOfDeath			= [];

    if( level.multiTeamBased )
    {
        foreach ( teamName in level.teamNameList )
        {
            level.finalKillCam_delay[teamName]			            = undefined;
	        level.finalKillCam_victim[teamName]						= undefined;
	        level.finalKillCam_attacker[teamName]					= undefined;
	        level.finalKillCam_attackerNum[teamName]				= undefined;
	        level.finalKillCam_inflictor[teamName]					= undefined;
	        level.finalKillCam_inflictor_agent_type[teamName]		= undefined;
	        level.finalKillCam_inflictor_lastSpawnTime[teamName]	= undefined;
	        level.finalKillCam_killCamEntityIndex[teamName]			= undefined;
	        level.finalKillCam_killCamEntityStartTime[teamName]		= undefined;
	        level.finalKillCam_sWeapon[teamName]					= undefined;
	        level.finalKillCam_deathTimeOffset[teamName]			= undefined;
	        level.finalKillCam_psOffsetTime[teamName]				= undefined;
	        level.finalKillCam_timeRecorded[teamName]				= undefined;
			level.finalKillCam_timeGameEnded[teamName]			    = undefined;
			level.finalKillCam_sMeansOfDeath[teamName]			    = undefined;
        }
    }
	else
	{
		level.finalKillCam_delay[ "axis" ]					= undefined;
		level.finalKillCam_victim[ "axis" ]					= undefined;
		level.finalKillCam_attacker[ "axis" ]				= undefined;
		level.finalKillCam_attackerNum[ "axis" ]			= undefined;
		level.finalKillCam_inflictor[ "axis" ]				= undefined;
		level.finalKillCam_inflictor_agent_type[ "axis" ]	= undefined;
		level.finalKillCam_inflictor_lastSpawnTime[ "axis" ]= undefined;
		level.finalKillCam_killCamEntityIndex[ "axis" ]		= undefined;
		level.finalKillCam_killCamEntityStartTime[ "axis" ]	= undefined;
		level.finalKillCam_sWeapon[ "axis" ]				= undefined;
		level.finalKillCam_deathTimeOffset[ "axis" ]		= undefined;
		level.finalKillCam_psOffsetTime[ "axis" ]			= undefined;
		level.finalKillCam_timeRecorded[ "axis" ]			= undefined;
		level.finalKillCam_timeGameEnded[ "axis" ]			= undefined;
		level.finalKillCam_sMeansOfDeath[ "axis" ]			= undefined;

		level.finalKillCam_delay[ "allies" ]					= undefined;
		level.finalKillCam_victim[ "allies" ]					= undefined;
		level.finalKillCam_attacker[ "allies" ]					= undefined;
		level.finalKillCam_attackerNum[ "allies" ]				= undefined;
		level.finalKillCam_inflictor[ "allies" ]				= undefined;
		level.finalKillCam_inflictor_agent_type[ "allies" ]		= undefined;
		level.finalKillCam_inflictor_lastSpawnTime[ "allies" ]	= undefined;
		level.finalKillCam_killCamEntityIndex[ "allies" ]		= undefined;
		level.finalKillCam_killCamEntityStartTime[ "allies" ]	= undefined;
		level.finalKillCam_sWeapon[ "allies" ]					= undefined;
		level.finalKillCam_deathTimeOffset[ "allies" ]			= undefined;
		level.finalKillCam_psOffsetTime[ "allies" ]				= undefined;
		level.finalKillCam_timeRecorded[ "allies" ]				= undefined;
		level.finalKillCam_timeGameEnded[ "allies" ]			= undefined;
		level.finalKillCam_sMeansOfDeath[ "allies" ]			= undefined;
	}

	level.finalKillCam_delay[ "none" ]					= undefined;
	level.finalKillCam_victim[ "none" ]					= undefined;
	level.finalKillCam_attacker[ "none" ]				= undefined;
	level.finalKillCam_attackerNum[ "none" ]			= undefined;
	level.finalKillCam_inflictor[ "none" ]				= undefined;
	level.finalKillCam_inflictor_agent_type[ "none" ]	= undefined;
	level.finalKillCam_inflictor_lastSpawnTime[ "none" ]= undefined;
	level.finalKillCam_killCamEntityIndex[ "none" ]		= undefined;
	level.finalKillCam_killCamEntityStartTime[ "none" ]	= undefined;
	level.finalKillCam_sWeapon[ "none" ]				= undefined;
	level.finalKillCam_deathTimeOffset[ "none" ]		= undefined;
	level.finalKillCam_psOffsetTime[ "none" ]			= undefined;
	level.finalKillCam_timeRecorded[ "none" ]			= undefined;
	level.finalKillCam_timeGameEnded[ "none" ]			= undefined;
	level.finalKillCam_sMeansOfDeath[ "none" ]			= undefined;

	level.finalKillCam_winner = undefined;
}

recordFinalKillCam( delay, victim, attacker, attackerNum, eInflictor, killCamEntityIndex, killCamEntityStartTime, sWeapon, deathTimeOffset, psOffsetTime, sMeansOfDeath )
{
	// save this kill as the final kill cam so we can play it back when the match ends
	// we want to save each team seperately so we can show the winning team's kill when applicable
	if( level.teambased && IsDefined( attacker.team ) )
	{
		level.finalKillCam_delay[ attacker.team ]					= delay;
		level.finalKillCam_victim[ attacker.team ]					= victim;
		level.finalKillCam_attacker[ attacker.team ]				= attacker;
		level.finalKillCam_attackerNum[ attacker.team ]				= attackerNum;
		level.finalKillCam_inflictor[ attacker.team ]				= eInflictor;		
		level.finalKillCam_killCamEntityIndex[ attacker.team ]		= killCamEntityIndex;
		level.finalKillCam_killCamEntityStartTime[ attacker.team ]	= killCamEntityStartTime;
		level.finalKillCam_sWeapon[ attacker.team ]					= sWeapon;
		level.finalKillCam_deathTimeOffset[ attacker.team ]			= deathTimeOffset;
		level.finalKillCam_psOffsetTime[ attacker.team ]			= psOffsetTime;
		level.finalKillCam_timeRecorded[ attacker.team ]			= getSecondsPassed();
		level.finalKillCam_timeGameEnded[ attacker.team ]			= getSecondsPassed(); // this gets set in endGame()
		level.finalKillCam_sMeansOfDeath[ attacker.team ]			= sMeansOfDeath;
		
		if ( IsDefined( eInflictor ) && IsAgent( eInflictor ) )
		{
			level.finalKillCam_inflictor_agent_type[ attacker.team ] = eInflictor.agent_type;
			level.finalKillCam_inflictor_lastSpawnTime[ attacker.team ] = eInflictor.lastSpawnTime;
		}
		else
		{
			level.finalKillCam_inflictor_agent_type[ attacker.team ] = undefined;
			level.finalKillCam_inflictor_lastSpawnTime[ attacker.team ] = undefined;
		}
	}

	// none gets filled just in case we need something without a team or this is ffa
	level.finalKillCam_delay[ "none" ]					= delay;
	level.finalKillCam_victim[ "none" ]					= victim;
	level.finalKillCam_attacker[ "none" ]				= attacker;
	level.finalKillCam_attackerNum[ "none" ]			= attackerNum;
	level.finalKillCam_inflictor[ "none" ]				= eInflictor;
	level.finalKillCam_killCamEntityIndex[ "none" ]		= killCamEntityIndex;
	level.finalKillCam_killCamEntityStartTime[ "none" ]	= killCamEntityStartTime;
	level.finalKillCam_sWeapon[ "none" ]				= sWeapon;
	level.finalKillCam_deathTimeOffset[ "none" ]		= deathTimeOffset;
	level.finalKillCam_psOffsetTime[ "none" ]			= psOffsetTime;
	level.finalKillCam_timeRecorded[ "none" ]			= getSecondsPassed();
	level.finalKillCam_timeGameEnded[ "none" ]			= getSecondsPassed(); // this gets set in endGame()
	level.finalKillCam_timeGameEnded[ "none" ]			= getSecondsPassed(); // this gets set in endGame()
	level.finalKillCam_sMeansOfDeath[ "none" ]			= sMeansOfDeath;
	
	if ( IsDefined( eInflictor ) && IsAgent( eInflictor ) )
	{
		level.finalKillCam_inflictor_agent_type[ "none" ] = eInflictor.agent_type;
		level.finalKillCam_inflictor_lastSpawnTime[ "none" ] = eInflictor.lastSpawnTime;
	}
	else
	{
		level.finalKillCam_inflictor_agent_type[ "none" ] = undefined;
		level.finalKillCam_inflictor_lastSpawnTime[ "none" ] = undefined;
	}
}

eraseFinalKillCam()
{
	// erase this kill as the final kill cam so we don't play it back when the match ends
    if( level.multiTeamBased )
    {
        for( i = 0; i < level.teamNameList.size; i++ )
        {
            level.finalKillCam_delay[level.teamNameList[i]]			            = undefined;
	        level.finalKillCam_victim[level.teamNameList[i]]					= undefined;
	        level.finalKillCam_attacker[level.teamNameList[i]]					= undefined;
	        level.finalKillCam_attackerNum[level.teamNameList[i]]				= undefined;
	        level.finalKillCam_inflictor[level.teamNameList[i]]					= undefined;
	        level.finalKillCam_inflictor_agent_type[level.teamNameList[i]]		= undefined;
	        level.finalKillCam_inflictor_lastSpawnTime[level.teamNameList[i]]	= undefined;
	        level.finalKillCam_killCamEntityIndex[level.teamNameList[i]]		= undefined;
	        level.finalKillCam_killCamEntityStartTime[level.teamNameList[i]]	= undefined;
	        level.finalKillCam_sWeapon[level.teamNameList[i]]					= undefined;
	        level.finalKillCam_deathTimeOffset[level.teamNameList[i]]			= undefined;
	        level.finalKillCam_psOffsetTime[level.teamNameList[i]]				= undefined;
	        level.finalKillCam_timeRecorded[level.teamNameList[i]]				= undefined;
			level.finalKillCam_timeGameEnded[level.teamNameList[i]]			    = undefined;
			level.finalKillCam_sMeansOfDeath[level.teamNameList[i]]			    = undefined;
        }
    }
	else
	{
		level.finalKillCam_delay[ "axis" ]					= undefined;
		level.finalKillCam_victim[ "axis" ]					= undefined;
		level.finalKillCam_attacker[ "axis" ]				= undefined;
		level.finalKillCam_attackerNum[ "axis" ]			= undefined;
		level.finalKillCam_inflictor[ "axis" ]				= undefined;
		level.finalKillCam_inflictor_agent_type[ "axis" ]	= undefined;
		level.finalKillCam_inflictor_lastSpawnTime[ "axis" ]= undefined;
		level.finalKillCam_killCamEntityIndex[ "axis" ]		= undefined;
		level.finalKillCam_killCamEntityStartTime[ "axis" ]	= undefined;
		level.finalKillCam_sWeapon[ "axis" ]				= undefined;
		level.finalKillCam_deathTimeOffset[ "axis" ]		= undefined;
		level.finalKillCam_psOffsetTime[ "axis" ]			= undefined;
		level.finalKillCam_timeRecorded[ "axis" ]			= undefined;
		level.finalKillCam_timeGameEnded[ "axis" ]			= undefined;
		level.finalKillCam_sMeansOfDeath[ "axis" ]			= undefined;

		level.finalKillCam_delay[ "allies" ]					= undefined;
		level.finalKillCam_victim[ "allies" ]					= undefined;
		level.finalKillCam_attacker[ "allies" ]					= undefined;
		level.finalKillCam_attackerNum[ "allies" ]				= undefined;
		level.finalKillCam_inflictor[ "allies" ]				= undefined;
		level.finalKillCam_inflictor_agent_type[ "allies" ]		= undefined;
		level.finalKillCam_inflictor_lastSpawnTime[ "allies" ]	= undefined;
		level.finalKillCam_killCamEntityIndex[ "allies" ]		= undefined;
		level.finalKillCam_killCamEntityStartTime[ "allies" ]	= undefined;
		level.finalKillCam_sWeapon[ "allies" ]					= undefined;
		level.finalKillCam_deathTimeOffset[ "allies" ]			= undefined;
		level.finalKillCam_psOffsetTime[ "allies" ]				= undefined;
		level.finalKillCam_timeRecorded[ "allies" ]				= undefined;
		level.finalKillCam_timeGameEnded[ "allies" ]			= undefined;
		level.finalKillCam_sMeansOfDeath[ "allies" ]			= undefined;
	}

	level.finalKillCam_delay[ "none" ]					= undefined;
	level.finalKillCam_victim[ "none" ]					= undefined;
	level.finalKillCam_attacker[ "none" ]				= undefined;
	level.finalKillCam_attackerNum[ "none" ]			= undefined;
	level.finalKillCam_inflictor[ "none" ]				= undefined;
	level.finalKillCam_inflictor_agent_type[ "none" ]	= undefined;
	level.finalKillCam_inflictor_lastSpawnTime[ "none" ]= undefined;
	level.finalKillCam_killCamEntityIndex[ "none" ]		= undefined;
	level.finalKillCam_killCamEntityStartTime[ "none" ]	= undefined;
	level.finalKillCam_sWeapon[ "none" ]				= undefined;
	level.finalKillCam_deathTimeOffset[ "none" ]		= undefined;
	level.finalKillCam_psOffsetTime[ "none" ]			= undefined;
	level.finalKillCam_timeRecorded[ "none" ]			= undefined;
	level.finalKillCam_timeGameEnded[ "none" ]			= undefined;
	level.finalKillCam_sMeansOfDeath[ "none" ]			= undefined;

	level.finalKillCam_winner = undefined;
}

doFinalKillcam()
{
	level waittill ( "round_end_finished" );

	level.showingFinalKillcam = true;

	// we want to show the winner's final kill cam
	winner = "none";
	if( IsDefined( level.finalKillCam_winner ) )
	{
		winner = level.finalKillCam_winner;
		//switch( level.gametype )
		//{
		//case "war":		// tdm
		//case "dom":		// domination
		//case "sab":		// sabotage
		//case "sd":		// search and destroy
		//case "dd":		// demolition
		//case "ctf":		// capture the flag
		//case "koth":	// headquarters
		//case "tdef":	// team defender
		//	winner = level.finalKillCam_winner;
		//	break;

		//case "dm":		// ffa
		//default:
		//	break;
		//}
	}

	delay = level.finalKillCam_delay[ winner ];
	victim = level.finalKillCam_victim[ winner ];
	attacker = level.finalKillCam_attacker[ winner ];
	attackerNum = level.finalKillCam_attackerNum[ winner ];
	eInflictor = level.finalKillCam_inflictor[ winner ];
	inflictor_agent_type = level.finalKillCam_inflictor_agent_type[ winner ];
	inflictor_lastSpawnTime = level.finalKillCam_inflictor_lastSpawnTime[ winner ];
	killCamEntityIndex = level.finalKillCam_killCamEntityIndex[ winner ];
	killCamEntityStartTime = level.finalKillCam_killCamEntityStartTime[ winner ];
	sWeapon = level.finalKillCam_sWeapon[ winner ];
	deathTimeOffset = level.finalKillCam_deathTimeOffset[ winner ];
	psOffsetTime = level.finalKillCam_psOffsetTime[ winner ];
	timeRecorded = level.finalKillCam_timeRecorded[ winner ];
	timeGameEnded = level.finalKillCam_timeGameEnded[ winner ];
	sMeansOfDeath = level.finalKillCam_sMeansOfDeath[ winner ];

	if( !IsDefined( victim ) || 
		!IsDefined( attacker ) )
	{
		level.showingFinalKillcam = false;
		level notify( "final_killcam_done" );
		return;
	}

	// if the killcam happened longer than 15 seconds ago, don't show it
	killCamBufferTime = 15;
	killCamOffsetTime = timeGameEnded - timeRecorded;
	if( killCamOffsetTime > killCamBufferTime )
	{
		level.showingFinalKillcam = false;
		level notify( "final_killcam_done" );
		return;
	}

	if ( IsDefined( attacker ) )
	{
		//maps\mp\_awards::addAwardWinner( "finalkill", attacker.clientid );
		attacker.finalKill = true;

		killCamTeam = "none";	// for FFA
		if ( level.teamBased )
			killCamTeam = attacker.team;
		
		// award final kill cam ops for both time out and for scoring winning kill. Kill confirmed has to do its check here anyways, since winning is based on tags, not kills		
		if( IsDefined( level.finalKillCam_attacker[ killCamTeam ] ) && level.finalKillCam_attacker[ killCamTeam ] == attacker )
		{
			maps\mp\gametypes\_missions::processFinalKillChallenges( attacker, victim );
		}
	}
	
	inflictorAgentInfo = spawnStruct();
	inflictorAgentInfo.agent_type = inflictor_agent_type;
	inflictorAgentInfo.lastSpawnTime = inflictor_lastSpawnTime;

	postDeathDelay = (( getTime() - victim.deathTime ) / 1000);
	
	foreach ( player in level.players )
	{
		player restoreBaseVisionSet( 0 );
		player.killcamentitylookat = victim getEntityNumber();
		
		player thread maps\mp\gametypes\_killcam::killcam( eInflictor, inflictorAgentInfo, attackerNum, killcamentityindex, killcamentitystarttime, sWeapon, postDeathDelay + deathTimeOffset, psOffsetTime, 0, 12, attacker, victim, sMeansOfDeath );
	}

	wait( 0.1 );

	while ( anyPlayersInKillcam() )
		wait( 0.05 );
	
	level notify( "final_killcam_done" );
	level.showingFinalKillcam = false;
}


anyPlayersInKillcam()
{
	foreach ( player in level.players )
	{
		if ( IsDefined( player.killcam ) )
			return true;
	}
	
	return false;
}


resetPlayerVariables()
{
	self.killedPlayersCurrent = [];
	self.ch_extremeCrueltyComplete = false; // setting a player var to throttle challenge completion rate
	self.switching_teams = undefined; // this should never get set to false, either undefined or true
	self.joining_team = undefined;
	self.leaving_team = undefined;

	self.pers["cur_kill_streak"] = 0;
	self.pers["cur_kill_streak_for_nuke"] = 0;

	self maps\mp\gametypes\_gameobjects::detachUseModels();// want them detached before we create our corpse
}


getKillcamEntity( attacker, eInflictor, sWeapon ) // self == victim
{
	if( !IsDefined( attacker ) || !IsDefined( eInflictor ) || ( (attacker == eInflictor) && !isAgent( attacker ) ) )
	   return undefined;
	
	switch( sWeapon )
	{
	// case "bouncingbetty_mp":			// bouncing betty
	case "bomb_site_mp":				// bomb sites
	case "trophy_mp":					// trophy systems, ball drone radar (night owl)
	case "heli_pilot_turret_mp":		// heli pilot
	case "proximity_explosive_mp":
	case "hashima_missiles_mp":			// hashima level specific killstreak
	case "sentry_minigun_mp":			// mp_shipment_ns multiturret
		return eInflictor.killCamEnt;
	case "aamissile_projectile_mp":		// air superiority
	case "remote_tank_projectile_mp":	// vanguard
	case "hind_missile_mp":			// heli missile	
	case "hind_bomb_mp":				// heli bomb
		if ( isDefined( eInflictor.vehicle_fired_from ) && isDefined( eInflictor.vehicle_fired_from.killCamEnt ) )
			return eInflictor.vehicle_fired_from.killCamEnt;
		else if ( isDefined( eInflictor.vehicle_fired_from ) )
			return eInflictor.vehicle_fired_from;
		break;
	case "sam_projectile_mp":			// sam turret
		if( IsDefined( eInflictor.samTurret ) && IsDefined( eInflictor.samTurret.killCamEnt ) )
			return eInflictor.samTurret.killCamEnt;
		break;

	case "ims_projectile_mp":			// ims
		if( IsDefined( attacker ) && IsDefined( attacker.imsKillCamEnt ) )
			return attacker.imsKillCamEnt;
		break;

	case "ball_drone_gun_mp":			// ball drone
	case "ball_drone_projectile_mp":	// ball drone
		if( IsPlayer( attacker ) && IsDefined( attacker.ballDrone ) && IsDefined( attacker.ballDrone.turret ) && IsDefined( attacker.ballDrone.turret.killCamEnt ) )
			return attacker.ballDrone.turret.killCamEnt;
		break;		
	// JC-ToDo: - Kept this here in case I bring back mine logic for the mk32
		//xm45 mine launcher
//	case "xm45_mp":
//		if ( IsDefined( attacker ) && isDefined( eInflictor ) )
//			return eInflictor.killCamEnt;
//		break;

	case "artillery_mp":
	case "none":						// could be care package
		if( ( IsDefined( eInflictor.targetname ) && eInflictor.targetname == "care_package" ) || ( IsDefined( eInflictor.killCamEnt ) && ( ( eInflictor.classname == "script_brushmodel" ) || ( eInflictor.classname == "trigger_multiple" ) || ( eInflictor.classname == "script_model" ) ) ) )
			return eInflictor.killCamEnt;
		break;

	case "ac130_105mm_mp":				// ac130
	case "ac130_40mm_mp":				// ac130
	case "ac130_25mm_mp":				// ac130
	case "remotemissile_projectile_mp":	// predator missile
	case "osprey_player_minigun_mp":	// osprey gunner
	case "ugv_turret_mp":				// remote tank
	case "remote_turret_mp":			// remote turret
		return undefined;
	}
		
	// could be a destructible
	if( isDestructibleWeapon( sWeapon ) || isBombSiteWeapon( sWeapon ) )
	{
		// a barrel or a car or another destructible, the killcament gets set in _load.gsc when the level loads
		// if the attacker shot a destructible to kill the victim, then show from the ac130 or gunner and not the destructible because it causes a weird thermal bug
		if( IsDefined( eInflictor.killCamEnt ) && !attacker attackerInRemoteKillstreak() )
			return eInflictor.killCamEnt;
		else
			return undefined; 
	}
	
	return eInflictor;
}

attackerInRemoteKillstreak() // self == attacker
{
	if( !IsDefined( self ) )
		return false;
	if( IsDefined( level.ac130player ) && self == level.ac130player )
		return true;
	if( IsDefined( level.chopper ) && IsDefined( level.chopper.gunner ) && self == level.chopper.gunner )
		return true;
	if( IsDefined( level.remote_mortar ) && IsDefined( level.remote_mortar.owner ) && self == level.remote_mortar.owner )
		return true;
	if( IsDefined( self.using_remote_turret ) && self.using_remote_turret )
		return true;
	if( IsDefined( self.using_remote_tank ) && self.using_remote_tank )
		return true;
	else if ( IsDefined( self.using_remote_a10 ) )
	{
		return true;
	}

	return false;
}

HitlocDebug( attacker, victim, damage, hitloc, dflags )
{
	colors = [];
	colors[ 0 ] = 2;
	colors[ 1 ] = 3;
	colors[ 2 ] = 5;
	colors[ 3 ] = 7;

	if ( !getdvarint( "scr_hitloc_debug" ) )
		return;

	if ( !IsDefined( attacker.hitlocInited ) )
	{
		for ( i = 0; i < 6; i++ )
		{
			attacker setClientDvar( "ui_hitloc_" + i, "" );
		}
		attacker.hitlocInited = true;
	}

	if ( level.splitscreen || !isPLayer( attacker ) )
		return;

	elemcount = 6;
	if ( !IsDefined( attacker.damageInfo ) )
	{
		attacker.damageInfo = [];
		for ( i = 0; i < elemcount; i++ )
		{
			attacker.damageInfo[ i ] = spawnstruct();
			attacker.damageInfo[ i ].damage = 0;
			attacker.damageInfo[ i ].hitloc = "";
			attacker.damageInfo[ i ].bp = false;
			attacker.damageInfo[ i ].jugg = false;
			attacker.damageInfo[ i ].colorIndex = 0;
		}
		attacker.damageInfoColorIndex = 0;
		attacker.damageInfoVictim = undefined;
	}

	for ( i = elemcount - 1; i > 0; i -- )
	{
		attacker.damageInfo[ i ].damage = attacker.damageInfo[ i - 1 ].damage;
		attacker.damageInfo[ i ].hitloc = attacker.damageInfo[ i - 1 ].hitloc;
		attacker.damageInfo[ i ].bp = attacker.damageInfo[ i - 1 ].bp;
		attacker.damageInfo[ i ].jugg = attacker.damageInfo[ i - 1 ].jugg;
		attacker.damageInfo[ i ].colorIndex = attacker.damageInfo[ i - 1 ].colorIndex;
	}
	attacker.damageInfo[ 0 ].damage = damage;
	attacker.damageInfo[ 0 ].hitloc = hitloc;
	attacker.damageInfo[ 0 ].bp = ( dflags & level.iDFLAGS_PENETRATION );
	attacker.damageInfo[ 0 ].jugg = victim isJuggernaut();
	if ( IsDefined( attacker.damageInfoVictim ) && ( attacker.damageInfoVictim != victim ) )
	{
		attacker.damageInfoColorIndex++ ;
		if ( attacker.damageInfoColorIndex == colors.size )
			attacker.damageInfoColorIndex = 0;
	}
	attacker.damageInfoVictim = victim;
	attacker.damageInfo[ 0 ].colorIndex = attacker.damageInfoColorIndex;

	for ( i = 0; i < elemcount; i++ )
	{
		color = "^" + colors[ attacker.damageInfo[ i ].colorIndex ];
		if ( attacker.damageInfo[ i ].hitloc != "" )
		{
			val = color + attacker.damageInfo[ i ].hitloc;
			if ( attacker.damageInfo[ i ].bp )
				val += " (BP)";
			if ( attacker.damageInfo[ i ].jugg )
				val += " (Jugg)";
			attacker setClientDvar( "ui_hitloc_" + i, val );
		}
		attacker setClientDvar( "ui_hitloc_damage_" + i, color + attacker.damageInfo[ i ].damage );
	}
}

giveRecentShieldXP()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	self notify ( "giveRecentShieldXP" );
	self endon ( "giveRecentShieldXP" );
	
	self.recentShieldXP++;
	
	wait ( 20.0 );
	
	self.recentShieldXP = 0;
}

updateInflictorStat( eInflictor, eAttacker, sWeapon )
{
	if	(
		!IsDefined( eInflictor )
	||	!IsDefined( eInflictor.alreadyHit )
	||	!eInflictor.alreadyHit
	||	!isSingleHitWeapon( sWeapon )
		)
	{
		self maps\mp\gametypes\_gamelogic::setInflictorStat( eInflictor, eAttacker, sWeapon );
	}
	
	if ( IsDefined( eInflictor ) )
	{
		eInflictor.alreadyHit = true;
	}
}

Callback_PlayerDamage_internal( eInflictor, eAttacker, victim, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	eAttacker = _validateAttacker( eAttacker );

	//checking for aliens gametype so we don't report the weapon usage stats TODO: If we want to record per weapon usage in aliens then we will need to set up our own playerdata struct for the mode. BB
	gametype = GetDvar ("g_gametype");

	// don't let helicopters and other vehicles crush a player, if we want it to then put in a special case here
	if( IsDefined( sMeansOfDeath ) && sMeansOfDeath == "MOD_CRUSH" && 
		IsDefined( eInflictor ) && IsDefined( eInflictor.classname ) && eInflictor.classname == "script_vehicle" )
		return "crushed";
	
	if ( !isReallyAlive( victim ) )
		return "!isReallyAlive( victim )";
	
	// JC-ToDo: - Kept this here in case I bring back mine logic for the mk32
//	if ( sWeapon == "xm45_mp" && sMeansOfDeath != "MOD_PROJECTILE" && isDefined( eAttacker.owner ) )
//	{
//		eInflictor = eAttacker;
//		eAttacker = eAttacker.owner;
//	}
	
	//hind missiles and bombs are likely to hit the owner.  We dont want to be punitive. 
	if ( sWeapon == "hind_bomb_mp" || sWeapon == "hind_missile_mp" )
	{
		if ( IsDefined( eAttacker ) && victim == eAttacker )
			return 0;
	}
	
	if ( IsDefined( eAttacker ) && eAttacker.classname == "script_origin" && IsDefined( eAttacker.type ) && eAttacker.type == "soft_landing" )
		return "soft_landing";

	if ( sWeapon == "killstreak_emp_mp" )
		return "sWeapon == killstreak_emp_mp";

	if ( sWeapon == "bouncingbetty_mp" && !maps\mp\gametypes\_weapons::mineDamageHeightPassed( eInflictor, victim ) )
		return "mineDamageHeightPassed";
	
	if ( sWeapon == "bouncingbetty_mp" && ( victim GetStance() == "crouch" || victim GetStance() == "prone" ) )
		iDamage = Int(iDamage/2);

	// JC-ToDo: - Kept this here in case I bring back mine logic for the mk32
//	if ( sWeapon == "xm25_mp" && sMeansOfDeath == "MOD_IMPACT" )
//		iDamage = 95;
	
	if ( sWeapon == "emp_grenade_mp" && sMeansOfDeath != "MOD_IMPACT" )
		victim notify( "emp_damage", eAttacker );
	
	
	if ( IsDefined( level.hostMigrationTimer ) )
		return "level.hostMigrationTimer";

	// JC-ToDo: - Kept this here in case I bring back mine logic for the mk32
//	if ( sWeapon == "xm45_mp" && sMeansOfDeath == "MOD_IMPACT" )
//	{
//		iDamage = 95;
//		victim shellShock( "concussion_grenade_mp", level.CONCUSSED_TIME );
//	}
	
	if ( sMeansOfDeath == "MOD_FALLING" )
		victim thread emitFallDamage( iDamage );
		
	if ( sMeansOfDeath == "MOD_EXPLOSIVE_BULLET" && iDamage != 1 )
	{
		iDamage *= getDvarFloat( "scr_explBulletMod" );	
		iDamage = int( iDamage );
	}

	if ( IsDefined( eAttacker ) && eAttacker.classname == "worldspawn" )
		eAttacker = undefined;
	
	if ( IsDefined( eAttacker ) && IsDefined( eAttacker.gunner ) )
		eAttacker = eAttacker.gunner;
	
	// Overwrite the attacker if a c4/ied was blown up manually
	if ( IsDefined( eInflictor) && IsDefined( eInflictor.damagedBy ) )
		eAttacker = eInflictor.damagedBy;	
	
	attackerIsNPC = IsDefined( eAttacker ) && !IsDefined( eAttacker.gunner ) && (eAttacker.classname == "script_vehicle" || eAttacker.classname == "misc_turret" || eAttacker.classname == "script_model");
	attackerIsHittingTeammate = attackerIsHittingTeam( victim, eAttacker );

/#
	//// print sniper hit info to the player so we can see why we get hit markers instead of kills
	//if( IsDefined( sWeapon ) && getWeaponClass( sWeapon ) == "weapon_sniper" && !attackerIsHittingTeammate )
	//{
	//	//IPrintLn( "=========================" );
	//	//IPrintLn( "Callback_PlayerDamage_internal" );
	//	//IPrintLn( sWeapon );
	//	//if( IsPlayer( eAttacker ) )
	//	//	IPrintLn( "Attacker: " + eAttacker.name );
	//	//if( IsPlayer( victim ) )
	//	//	IPrintLn( "Victim: " + victim.name + " alive? " + IsAlive( victim ) );
	//	IPrintLn( "Damage: " + iDamage );
	//	IPrintLn( "Hit Loc: " + sHitLoc );
	//	if( IsDefined( iDFlags ) )
	//		IPrintLn( "Penetration: " + ( iDFlags & level.iDFLAGS_PENETRATION ) );
	//	//IPrintLn( "Time of damage: " + GetTime() );

	//	PrintLn( "=========================" );
	//	PrintLn( "Callback_PlayerDamage_internal" );
	//	PrintLn( sWeapon );
	//	if( IsPlayer( eAttacker ) )
	//		PrintLn( "Attacker: " + eAttacker.name );
	//	if( IsPlayer( victim ) )
	//		PrintLn( "Victim: " + victim.name + " alive? " + IsAlive( victim ) );
	//	PrintLn( "Damage: " + iDamage );
	//	PrintLn( "Hit Loc: " + sHitLoc );
	//	if( IsDefined( iDFlags ) )
	//		PrintLn( "Penetration: " + ( iDFlags & level.iDFLAGS_PENETRATION ) );
	//	PrintLn( "Time of damage: " + GetTime() );
	//}
#/


	// fixes Bugzilla 136417 where player shoots inside a dropped ballistic vest, sentry or ims, but ends up damaging himself too
	//	also need to do an extra check for if the eInflictor is a radiation trigger
	attackerIsInflictorVictim = IsDefined( eAttacker ) && IsDefined( eInflictor ) && IsDefined( victim ) && 
		IsPlayer( eAttacker ) && ( eAttacker == eInflictor ) && ( eAttacker == victim ) &&
		!IsDefined( eInflictor.poison );

	if ( attackerIsInflictorVictim )
		return "attackerIsInflictorVictim";

	stunFraction = 0.0;

	if ( iDFlags & level.iDFLAGS_STUN )
	{
		stunFraction = 0.0;
		//victim StunPlayer( 1.0 );
		iDamage = 0.0;
	}
	else if ( sHitLoc == "shield" )
	{
		if ( attackerIsHittingTeammate && level.friendlyfire == 0 )
			return "attackerIsHittingTeammate";
		
		if ( sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET" || sMeansOfDeath == "MOD_EXPLOSIVE_BULLET" && !attackerIsHittingTeammate )
		{
			if ( IsPlayer( eAttacker ) )
			{
				if ( IsDefined ( victim.owner ) )
					victim = victim.owner;
					
				eAttacker.lastAttackedShieldPlayer = victim;
				eAttacker.lastAttackedShieldTime = getTime();
			}
			victim notify ( "shield_blocked" );

			// fix turret + shield challenge exploits
			if ( isEnvironmentWeapon( sWeapon ) )
				shieldDamage = 25;
			else
				shieldDamage = maps\mp\perks\_perks::cac_modified_damage( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc );
						
			victim.shieldDamage += shieldDamage;

			// fix turret + shield challenge exploits
			if ( !isEnvironmentWeapon( sWeapon ) || cointoss() )
				victim.shieldBulletHits++;

			if ( victim.shieldBulletHits >= level.riotShieldXPBullets )
			{
				if ( self.recentShieldXP > 4 )
					xpVal = int( 50 / self.recentShieldXP );
				else
					xpVal = 50;
				
				//printLn( xpVal );
				
				victim thread maps\mp\gametypes\_rank::giveRankXP( "shield_damage", xpVal );
				victim thread giveRecentShieldXP();
				
				victim thread maps\mp\gametypes\_missions::genericChallenge( "shield_damage", victim.shieldDamage );

				victim thread maps\mp\gametypes\_missions::genericChallenge( "shield_bullet_hits", victim.shieldBulletHits );
				
				victim.shieldDamage = 0;
				victim.shieldBulletHits = 0;
			}
		}

		if ( iDFlags & level.iDFLAGS_SHIELD_EXPLOSIVE_IMPACT )
		{
			if (  !attackerIsHittingTeammate )
				victim thread maps\mp\gametypes\_missions::genericChallenge( "shield_explosive_hits", 1 );

			sHitLoc = "none";	// code ignores any damage to a "shield" bodypart.
			if ( !(iDFlags & level.iDFLAGS_SHIELD_EXPLOSIVE_IMPACT_HUGE) )
				iDamage *= 0.0;
		}
		else if ( iDFlags & level.iDFLAGS_SHIELD_EXPLOSIVE_SPLASH )
		{
			// does enough damage to shield carrier to ensure death
			if ( IsDefined( eInflictor ) && IsDefined( eInflictor.stuckEnemyEntity ) && eInflictor.stuckEnemyEntity == victim )
				iDamage = 151;
			
			victim thread maps\mp\gametypes\_missions::genericChallenge( "shield_explosive_hits", 1 );
			sHitLoc = "none";	// code ignores any damage to a "shield" bodypart.
		}
		else
		{
			return "hit shield";
		}
	}
	else if ( (smeansofdeath == "MOD_MELEE") && maps\mp\gametypes\_weapons::isRiotShield( sweapon ) )
	{
		if ( !(attackerIsHittingTeammate && (level.friendlyfire == 0)) )
		{
			stunFraction = 0.0;
			victim StunPlayer( 0.0 );
		}
	}

	// ensures stuck death, this needs to be above the cac_modified_damage() call to make sure juggernauts don't die so easily
	if ( IsDefined( eInflictor ) && IsDefined( eInflictor.stuckEnemyEntity ) && eInflictor.stuckEnemyEntity == victim ) 
		iDamage = 151;

	if ( !attackerIsHittingTeammate )
	{		
		// Deadeye Perk: This should be impossible, but make sure we remove this perk if they some how hold onto it, the next time they damage a player
		if ( self _hasPerk( "specialty_moredamage" ) )
			self _unsetPerk ( "specialty_moredamage" );
		
		// Deadeye perk handling
		if ( isBulletDamage( sMeansOfDeath ) && eAttacker _hasPerk( "specialty_deadeye" ) )	
		{
			// Check to see if we got a critial hit
			eAttacker maps\mp\perks\_perkfunctions::setDeadeyeInternal();				
		}
				
		iDamage = maps\mp\perks\_perks::cac_modified_damage( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, eInflictor );
		
		if ( IsPlayer( eAttacker ) && ( sWeapon == "smoke_grenade_mp" || sWeapon == "throwingknife_mp" ) )
			eAttacker thread maps\mp\gametypes\_gamelogic::threadedSetWeaponStatByName( sWeapon, 1, "hits" );
	}
	
	
	if ( IsDefined( level.modifyPlayerDamage ) )	
		iDamage = [[level.modifyPlayerDamage]]( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc );
	
/#
		//// print sniper hit info to the player so we can see why we get hit markers instead of kills
		//if( IsDefined( sWeapon ) && getWeaponClass( sWeapon ) == "weapon_sniper" && !attackerIsHittingTeammate )
		//{
		//	//IPrintLn( "=========================" );
		//	//IPrintLn( "Callback_PlayerDamage_internal" );
		//	//IPrintLn( sWeapon );
		//	//if( IsPlayer( eAttacker ) )
		//	//	IPrintLn( "Attacker: " + eAttacker.name );
		//	//if( IsPlayer( victim ) )
		//	//	IPrintLn( "Victim: " + victim.name + " alive? " + IsAlive( victim ) );
		//	//IPrintLn( "Damage: " + iDamage );
		//	//IPrintLn( "Hit Loc: " + sHitLoc );
		//	//if( IsDefined( iDFlags ) )
		//	//	IPrintLn( "Penetration: " + ( iDFlags & level.iDFLAGS_PENETRATION ) );
		//	//IPrintLn( "Time of damage: " + GetTime() );

		//	PrintLn( "=========================" );
		//	PrintLn( "Callback_PlayerDamage_internal -> after damage is modified" );
		//	PrintLn( sWeapon );
		//	if( IsPlayer( eAttacker ) )
		//		PrintLn( "Attacker: " + eAttacker.name );
		//	if( IsPlayer( victim ) )
		//		PrintLn( "Victim: " + victim.name + " alive? " + IsAlive( victim ) );
		//	PrintLn( "Damage: " + iDamage );
		//	PrintLn( "Hit Loc: " + sHitLoc );
		//	if( IsDefined( iDFlags ) )
		//		PrintLn( "Penetration: " + ( iDFlags & level.iDFLAGS_PENETRATION ) );
		//	PrintLn( "Time of damage: " + GetTime() );
		//}
#/

		
	if ( !iDamage )
		return "!iDamage";
	//eInflictor, eAttacker, victim, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime
	
	//if ( !(attackerIsHittingTeammate && (level.friendlyfire == 0)) )
	//	checkVictimStutter( victim, eAttacker, vDir, sWeapon, sMeansofDeath );
	
	victim.iDFlags = iDFlags;
	victim.iDFlagsTime = getTime();

	if ( game[ "state" ] == "postgame" )
		return "game[ state ] == postgame";
	if ( victim.sessionteam == "spectator" )
		return "victim.sessionteam == spectator";
	if ( IsDefined( victim.canDoCombat ) && !victim.canDoCombat )
		return "!victim.canDoCombat";
	if ( IsDefined( eAttacker ) && IsPlayer( eAttacker ) && IsDefined( eAttacker.canDoCombat ) && !eAttacker.canDoCombat )
		return "!eAttacker.canDoCombat";
	
	// handle vehicles/turrets and friendly fire
	if ( attackerIsNPC && attackerIsHittingTeammate )
	{
		if ( sMeansOfDeath == "MOD_CRUSH" )
		{
			victim _suicide();
			return "suicide crush";
		}
		
		if ( !level.friendlyfire )
			return "!level.friendlyfire";
	}
	
	if ( IsAI( self ) )
	{
		assert( IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["on_damaged"] ) );
		self [[ level.bot_funcs["on_damaged"] ]]( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc );
	}
	
	prof_begin( "PlayerDamage flags/tweaks" );

	// Don't do knockback if the damage direction was not specified
	if ( !IsDefined( vDir ) )
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	friendly = false;

	if ( ( victim.health == victim.maxhealth && ( !IsDefined( victim.lastStand ) || !victim.lastStand )  ) || !IsDefined( victim.attackers ) && !IsDefined( victim.lastStand )  )
	{
		victim resetAttackerList_Internal();
	}

	if ( isHeadShot( sWeapon, sHitLoc, sMeansOfDeath, eAttacker ) )
		sMeansOfDeath = "MOD_HEAD_SHOT";

	if ( maps\mp\gametypes\_tweakables::getTweakableValue( "game", "onlyheadshots" ) )
	{
		if ( sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET" || sMeansOfDeath == "MOD_EXPLOSIVE_BULLET" )
			return "getTweakableValue( game, onlyheadshots )";
		else if ( sMeansOfDeath == "MOD_HEAD_SHOT" )
		{
			if ( victim isJuggernaut() )
				iDamage = 75;
			else
				iDamage = 150;
		}
	}

	// explosive barrel/car detection
	// 2013-09-09 wallace: !!!HACK we didn't have time to give vehicles proper target names
	// and somehow, they are being set to destructible_toy (the gdts even have death_car set)
	// old way:
	if ( sWeapon == "destructible_toy" && IsDefined( eInflictor ) )
		sWeapon = "destructible_car";
/*	
	if ( sWeapon == "none" && IsDefined( eInflictor ) )
	{
		if ( IsDefined( eInflictor.destructible_type ) && isSubStr( eInflictor.destructible_type, "vehicle_" ) )
			sWeapon = "destructible_car";
	}
*/

	if ( getTime() < (victim.spawnTime + level.killstreakSpawnShield) )
	{
		damageLimit = int( max( (victim.health / 4), 1 ) );
		if ( (iDamage >= damageLimit) && isKillstreakWeapon( sWeapon ) && sMeansOfDeath != "MOD_MELEE" )
		{
			//println( "damage was: " + iDamage + "  is: " + damageLimit + " of health: " + victim.health);
			iDamage = damageLimit;
		}
	}

	prof_end( "PlayerDamage flags/tweaks" );

	// check for completely getting out of the damage
	if ( !(iDFlags & level.iDFLAGS_NO_PROTECTION) )
	{
		// items you own don't damage you in FFA
		if ( !level.teamBased && attackerIsNPC && IsDefined( eAttacker.owner ) && eAttacker.owner == victim )
		{
			prof_end( "PlayerDamage player" );

			if ( sMeansOfDeath == "MOD_CRUSH" )
				victim _suicide();

			return "ffa suicide";
		}

		if ( ( isSubStr( sMeansOfDeath, "MOD_GRENADE" ) || isSubStr( sMeansOfDeath, "MOD_EXPLOSIVE" ) || isSubStr( sMeansOfDeath, "MOD_PROJECTILE" ) ) && IsDefined( eInflictor ) && IsDefined( eAttacker ) )
		{
			// protect players from spawnkill grenades (IW5 ensure attacker is not player)
			if ( victim != eAttacker && eInflictor.classname == "grenade" && ( victim.lastSpawnTime + 3500 ) > getTime() && IsDefined( victim.lastSpawnPoint ) && distance( eInflictor.origin, victim.lastSpawnPoint.origin ) < 500 )
			{
				prof_end( "PlayerDamage player" );
				return "spawnkill grenade protection";
			}

			victim.explosiveInfo = [];
			victim.explosiveInfo[ "damageTime" ] = getTime();
			victim.explosiveInfo[ "damageId" ] = eInflictor getEntityNumber();
			victim.explosiveInfo[ "returnToSender" ] = false;
			victim.explosiveInfo[ "counterKill" ] = false;
			victim.explosiveInfo[ "chainKill" ] = false;
			victim.explosiveInfo[ "cookedKill" ] = false;
			victim.explosiveInfo[ "throwbackKill" ] = false;
			victim.explosiveInfo[ "suicideGrenadeKill" ] = false;
			victim.explosiveInfo[ "weapon" ] = sWeapon;

			isFrag = isSubStr( sWeapon, "frag_" );

			if ( eAttacker != victim )
			{
				if ( ( isSubStr( sWeapon, "c4_" ) || isSubStr( sWeapon, "proximity_explosive_" ) || isSubStr( sWeapon, "claymore_" ) ) && IsDefined( eInflictor.owner ) )
				{
					victim.explosiveInfo[ "returnToSender" ] = ( eInflictor.owner == victim );
					victim.explosiveInfo[ "counterKill" ] = IsDefined( eInflictor.wasDamaged );
					victim.explosiveInfo[ "chainKill" ] = IsDefined( eInflictor.wasChained );
					victim.explosiveInfo[ "bulletPenetrationKill" ] = IsDefined( eInflictor.wasDamagedFromBulletPenetration );
					victim.explosiveInfo[ "cookedKill" ] = false;
				}

				if ( IsDefined( eAttacker.lastGrenadeSuicideTime ) && eAttacker.lastGrenadeSuicideTime >= gettime() - 50 && isFrag )
					victim.explosiveInfo[ "suicideGrenadeKill" ] = true;
			}

			if ( isFrag )
			{
				victim.explosiveInfo[ "cookedKill" ] = IsDefined( eInflictor.isCooked );
				victim.explosiveInfo[ "throwbackKill" ] = IsDefined( eInflictor.threwBack );
			}
			
			victim.explosiveInfo[ "stickKill" ] = IsDefined( eInflictor.isStuck ) && eInflictor.isStuck == "enemy";
			victim.explosiveInfo[ "stickFriendlyKill" ] = IsDefined( eInflictor.isStuck ) && eInflictor.isStuck == "friendly";
			
			if( IsPlayer( eAttacker ) && eAttacker != self && gametype != "aliens" )
			{
				self updateInflictorStat( eInflictor, eAttacker, sWeapon );
			}
		}
		
		if ( IsSubStr( sMeansOfDeath, "MOD_IMPACT" ) && sWeapon == "iw6_rgm_mp" )
		{
			if ( IsPlayer( eAttacker ) && eAttacker != self && gametype != "aliens" )
			{
				self updateInflictorStat( eInflictor, eAttacker, sWeapon );
			}
		}
	
		if ( IsPlayer( eAttacker ) && IsDefined( eAttacker.pers[ "participation" ] ) )
			eAttacker.pers[ "participation" ]++ ;
		else if( IsPlayer( eAttacker ) )
			eAttacker.pers[ "participation" ] = 1;
			
		prevHealthRatio = victim.health / victim.maxhealth;
		
		if ( attackerIsHittingTeammate )
		{
			if ( !matchMakingGame() && IsPlayer(eAttacker) )
				eAttacker incPlayerStat( "mostff", 1 );
			
			prof_begin( "PlayerDamage player" );// profs automatically end when the function returns
			if ( level.friendlyfire == 0 || ( !IsPlayer(eAttacker) && level.friendlyfire != 1 ) || sWeapon == "bomb_site_mp" )	// no one takes damage	// S&R bomb doesn't count as a team kill
			{
				if ( sWeapon == "artillery_mp" || sWeapon == "stealth_bomb_mp" )
					victim damageShellshockAndRumble( eInflictor, sWeapon, sMeansOfDeath, iDamage, iDFlags, eAttacker );
				return "friendly fire";
			}
			else if ( level.friendlyfire == 1 )// the friendly takes damage
			{
				if ( iDamage < 1 )
					iDamage = 1;

				// this fixes a bug where the friendly could kill the jugg in one or two shots
				if( victim isJuggernaut() )
					iDamage = maps\mp\perks\_perks::cac_modified_damage( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc );

				victim.lastDamageWasFromEnemy = false;

				victim finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );
			}
			else if ( ( level.friendlyfire == 2 ) && isReallyAlive( eAttacker ) )// only the attacker takes damage
			{
				iDamage = int( iDamage * .5 );
				if ( iDamage < 1 )
					iDamage = 1;

				eAttacker.lastDamageWasFromEnemy = false;

				eAttacker.friendlydamage = true;
				eAttacker finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );
				eAttacker.friendlydamage = undefined;
			}
			else if ( level.friendlyfire == 3 && isReallyAlive( eAttacker ) )// both friendly and attacker take damage
			{
				iDamage = int( iDamage * .5 );
				if ( iDamage < 1 )
					iDamage = 1;

				victim.lastDamageWasFromEnemy = false;
				eAttacker.lastDamageWasFromEnemy = false;

				victim finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );
				if ( isReallyAlive( eAttacker ) )// may have died due to friendly fire punishment
				{
					eAttacker.friendlydamage = true;
					eAttacker finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );
					eAttacker.friendlydamage = undefined;
				}
			}

			friendly = true;
			
		}
		else// not hitting teammate
		{
			prof_begin( "PlayerDamage world" );

			if ( iDamage < 1 )
				iDamage = 1;

			if ( IsDefined( eAttacker ) && IsPlayer( eAttacker ) )
				addAttacker( victim, eAttacker, eInflictor, sWeapon, iDamage, vPoint, vDir, sHitLoc, psOffsetTime, sMeansOfDeath );
	
			if ( IsDefined( eAttacker ) && !IsPlayer( eAttacker ) && IsDefined( eAttacker.owner ) && ( !IsDefined( eAttacker.scrambled ) || !eAttacker.scrambled ) )
				addAttacker( victim, eAttacker.owner, eInflictor, sWeapon, iDamage, vPoint, vDir, sHitLoc, psOffsetTime, sMeansOfDeath );
			else if ( IsDefined( eAttacker ) && !IsPlayer( eAttacker ) && IsDefined( eAttacker.secondOwner ) && IsDefined( eAttacker.scrambled ) && eAttacker.scrambled )
				addAttacker( victim, eAttacker.secondOwner, eInflictor, sWeapon, iDamage, vPoint, vDir, sHitLoc, psOffsetTime, sMeansOfDeath );
			
			if ( sMeansOfDeath == "MOD_EXPLOSIVE" || sMeansOfDeath == "MOD_GRENADE_SPLASH" && iDamage < victim.health )
				victim notify( "survived_explosion", eAttacker );

			if ( IsDefined( eAttacker ) )
				level.lastLegitimateAttacker = eAttacker;

			if ( IsDefined( eAttacker ) && IsPlayer( eAttacker ) && IsDefined( sWeapon ) )
				eAttacker thread maps\mp\gametypes\_weapons::checkHit( sWeapon, victim );

			if ( IsDefined( eAttacker ) && IsPlayer( eAttacker ) && IsDefined( sWeapon ) && eAttacker != victim )
			{
				eAttacker thread maps\mp\_events::damagedPlayer( self, iDamage, sWeapon );
				victim.attackerPosition = eAttacker.origin;
			}
			else
			{
				victim.attackerPosition = undefined;
			}

			if ( issubstr( sMeansOfDeath, "MOD_GRENADE" ) && IsDefined( eInflictor.isCooked ) )
				victim.wasCooked = getTime();
			else
				victim.wasCooked = undefined;

			victim.lastDamageWasFromEnemy = ( IsDefined( eAttacker ) && ( eAttacker != victim ) );

			if ( victim.lastDamageWasFromEnemy )
			{
				timeStamp = getTime();
				eAttacker.damagedPlayers[ victim.guid ] = timeStamp;
				// need this timestamp for battle buddy spawning
				victim.lastDamagedTime = timeStamp;
			}

			victim finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );

			if ( IsDefined( level.ac130player ) && IsDefined( eAttacker ) && ( level.ac130player == eAttacker ) )
				level notify( "ai_pain", victim );

			victim thread maps\mp\gametypes\_missions::playerDamaged( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, sHitLoc );

			prof_end( "PlayerDamage world" );
			
		}

		if ( attackerIsNPC && IsDefined( eAttacker.gunner ) )
			damager = eAttacker.gunner;
		else
			damager = eAttacker;

		if ( IsDefined( damager) && damager != victim && iDamage > 0 && ( !IsDefined( sHitLoc ) || sHitLoc != "shield" ) )
		{
			wasKilled = !isReallyAlive( victim ) || ( IsAgent( victim ) && iDamage >= victim.health );			

			if ( iDFlags & level.iDFLAGS_STUN )
				typeHit = "stun";
			else if ( IsExplosiveDamageMOD( sMeansOfDeath ) && ( IsDefined( victim.thermoDebuffed ) && victim.thermoDebuffed ) )
				typeHit = ter_op( wasKilled, "thermodebuff_kill", "thermobaric_debuff" );
			// 6/9/14 DM - HITMARKER color update for kill
			else if ( IsExplosiveDamageMOD( sMeansOfDeath ) && victim _hasPerk( "_specialty_blastshield" ) && !weaponIgnoresBlastShield( sWeapon ) )
				typeHit = ter_op( wasKilled, "hitkillblast", "hitblastshield" );
			else if ( victim _hasPerk( "specialty_combathigh" ) )
				typeHit = "hitendgame";
			else if ( IsDefined( victim.lightArmorHP ) && sMeansOfDeath != "MOD_HEAD_SHOT" && !isFMJDamage( sWeapon, sMeansOfDeath, eAttacker ) )
				typeHit = "hitlightarmor";
			else if ( hasHeavyArmor ( victim ) )
				typeHit = "hitlightarmor";
			// 6/9/14 DM - HITMARKER color update for kill
			else if ( victim isJuggernaut() )
				typeHit = ter_op( wasKilled, "hitkilljugg", "hitjuggernaut" );
			else if ( victim _hasPerk( "specialty_moreHealth" ) )
				typeHit = "hitmorehealth";
			// 6/9/14 DM - HITMARKER color update for kill
			else if ( damager _hasPerk( "specialty_moredamage" ) )
			{
				typeHit = ter_op( wasKilled, "hitdeadeyekill", "hitcritical" );
				damager _unsetPerk("specialty_moredamage");
			}
			else if ( !shouldWeaponFeedback( sWeapon ) )
				typeHit = "none";
			// 6/9/14 DM - HITMARKER color update for kill
			else
				typeHit = ter_op( wasKilled, "hitkill", "standard" );
				
			damager thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( typeHit );
		}

		maps\mp\gametypes\_gamelogic::setHasDoneCombat( victim, true );
	}

	if ( IsDefined( eAttacker ) && ( eAttacker != victim ) && !friendly )
		level.useStartSpawns = false;

	// show directional blood if any damage taken
	if ( iDamage > 10 && IsDefined( eInflictor ) && !victim isUsingRemote() && isPlayer( victim ) )
	{
		victim thread maps\mp\gametypes\_shellshock::bloodEffect( eInflictor.origin );

		if( IsPlayer( eInflictor ) && sMeansOfDeath == "MOD_MELEE" )
			eInflictor thread maps\mp\gametypes\_shellshock::bloodMeleeEffect();
	}

	//=================
	// Damage Logging
	//=================

	prof_begin( "PlayerDamage log" );

/#
	if ( getDvarInt( "g_debugDamage" ) )
	{
		PrintLn( "client:" + victim GetEntityNumber() + " health:" + victim.health + " attacker:" + eAttacker GetEntityNumber() + " inflictor is player:" + IsPlayer( eInflictor ) + " damage:" + iDamage + " hitLoc:" + sHitLoc + " range:" + Distance( eAttacker.origin, victim.origin ) );
	}
#/
	/*
	if ( victim.sessionstate != "dead" )
	{
		lpselfnum = victim getEntityNumber();
		lpselfname = victim.name;
		lpselfteam = victim.pers[ "team" ];
		lpselfGuid = victim.guid;
		lpattackerteam = "";

		if ( IsPlayer( eAttacker ) )
		{
			lpattacknum = eAttacker getEntityNumber();
			lpattackGuid = eAttacker.guid;
			lpattackname = eAttacker.name;
			lpattackerteam = eAttacker.pers[ "team" ];
		}
		else
		{
			lpattacknum = -1;
			lpattackGuid = "";
			lpattackname = "";
			lpattackerteam = "world";
		}

		logPrint( "D;" + lpselfGuid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackGuid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n" );
	}*/

	HitlocDebug( eAttacker, victim, iDamage, sHitLoc, iDFlags ); // early outs on scr_hitloc_debug

	if( IsDefined( eAttacker ) && eAttacker != victim )
	{
		if ( IsPlayer( eAttacker ) )
			eAttacker incPlayerStat( "damagedone", iDamage );
		
		victim incPlayerStat( "damagetaken", iDamage );
	}
	
	if ( IsAgent( self ) )
	{
		self [[ self agentFunc("on_damaged_finished") ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime );
	}	

	prof_end( "PlayerDamage log" );

	// this needs to return a result
	return "finished";
}

shouldWeaponFeedback( sWeapon )
{
	// should this weapon give feedback
	switch( sWeapon )
	{
		case "stealth_bomb_mp":
		case "artillery_mp":
			return false;
	}

	return true;
}

checkVictimStutter( victim, eAttacker, vDir, sWeapon, sMeansOfDeath )
{
	if ( sMeansOfDeath == "MOD_PISTOL_BULLET" || sMeansOfDeath == "MOD_RIFLE_BULLET" || sMeansOfDeath == "MOD_HEAD_SHOT" )
	{
		if ( Distance( victim.origin, eAttacker.origin ) > 256 )
			return;
		
		vicVelocity = victim getVelocity();
		
		if (  LengthSquared( vicVelocity ) < 10 )
			return;
		
		facing = findIsFacing( victim, eAttacker, 25 );
	
		if ( facing )
		{	
			victim thread stutterStep();
		}	
	}
}

		
stutterStep( enterScale )
{	
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	
	self.inStutter = true;
	
	self.moveSpeedScaler = 0.05;
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	wait( .5 );
	
	self.moveSpeedScaler = 1;
	if( self _hasPerk( "specialty_lightweight" ) )
		self.moveSpeedScaler = lightWeightScalar();
	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	
	self.inStutter = false;
}


addAttacker( victim, eAttacker, eInflictor, sWeapon, iDamage, vPoint, vDir, sHitLoc, psOffsetTime, sMeansOfDeath )
{
	if ( !IsDefined( victim.attackerData ) )
		victim.attackerData = [];
	
	if ( !IsDefined( victim.attackerData[ eAttacker.guid ] ) )
	{
		victim.attackers[ eAttacker.guid ] = eAttacker;
		// we keep an array of attackers by their client ID so we can easily tell
		// if they're already one of the existing attackers in the above if().
		// we store in this array data that is useful for other things, like challenges
		victim.attackerData[ eAttacker.guid ] = SpawnStruct();
		victim.attackerData[ eAttacker.guid ].damage = 0;	
		victim.attackerData[ eAttacker.guid ].attackerEnt = eAttacker;
		victim.attackerData[ eAttacker.guid ].firstTimeDamaged = getTime();				
	}
	if ( maps\mp\gametypes\_weapons::isPrimaryWeapon( sWeapon ) && ! maps\mp\gametypes\_weapons::isSideArm( sWeapon ) )
		victim.attackerData[ eAttacker.guid ].isPrimary = true;
	
	victim.attackerData[ eAttacker.guid ].damage += iDamage;
	victim.attackerData[ eAttacker.guid ].weapon = sWeapon;
	victim.attackerData[ eAttacker.guid ].vPoint = vPoint;
	victim.attackerData[ eAttacker.guid ].vDir = vDir;
	victim.attackerData[ eAttacker.guid ].sHitLoc = sHitLoc;
	victim.attackerData[ eAttacker.guid ].psOffsetTime = psOffsetTime;
	victim.attackerData[ eAttacker.guid ].sMeansOfDeath = sMeansOfDeath;
	victim.attackerData[ eAttacker.guid ].attackerEnt = eAttacker;
	victim.attackerData[ eAttacker.guid ].lasttimeDamaged = getTime();
	
	if ( IsDefined( eInflictor ) && !IsPlayer( eInflictor ) && IsDefined( eInflictor.primaryWeapon ) )
		victim.attackerData[ eAttacker.guid ].sPrimaryWeapon = eInflictor.primaryWeapon;
	else if ( IsDefined( eAttacker ) && IsPlayer( eAttacker ) && eAttacker getCurrentPrimaryWeapon() != "none" )
		victim.attackerData[ eAttacker.guid ].sPrimaryWeapon = eAttacker getCurrentPrimaryWeapon();
	else
		victim.attackerData[ eAttacker.guid ].sPrimaryWeapon = undefined;
}

resetAttackerList( noWait )
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	//wait is to offset premature calling in _healthOverlay
	wait( 1.75 ); 
	
	self resetAttackerList_Internal();
}

resetAttackerList_Internal()
{
	self.attackers = [];
	self.attackerData = [];
}


Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	result = Callback_PlayerDamage_internal( eInflictor, eAttacker, self, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime );

/#
	//// print sniper hit info to the player so we can see why we get hit markers instead of kills
	//if( IsDefined( sWeapon ) && getWeaponClass( sWeapon ) == "weapon_sniper" && IsDefined( result ) && result != "finished" )
	//{
	//	//IPrintLn( "=========================" );
	//	//IPrintLn( "Callback_PlayerDamage" );
	//	IPrintLn( "Return value: " + result );

	//	PrintLn( "=========================" );
	//	PrintLn( "Callback_PlayerDamage" );
	//	PrintLn( "Return value: " + result );
	//}
#/
}


finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction )
{
/#
	//// print sniper hit info to the player so we can see why we get hit markers instead of kills
	//if( IsDefined( sWeapon ) && getWeaponClass( sWeapon ) == "weapon_sniper" )
	//{
	//	//IPrintLn( "=========================" );
	//	//IPrintLn( "finishPlayerDamageWrapper" );
	//	//IPrintLn( sWeapon );
	//	//if( IsPlayer( eAttacker ) )
	//	//	IPrintLn( "Attacker: " + eAttacker.name );
	//	//if( IsPlayer( self ) )
	//	//	IPrintLn( "Victim: " + self.name + " alive? " + IsAlive( self ) );
	//	//IPrintLn( "Damage: " + iDamage );
	//	//IPrintLn( "Hit Loc: " + sHitLoc );
	//	//if( IsDefined( iDFlags ) )
	//	//	IPrintLn( "Penetration: " + ( iDFlags & level.iDFLAGS_PENETRATION ) );
	//	//IPrintLn( "Time of damage: " + GetTime() );

	//	PrintLn( "=========================" );
	//	PrintLn( "finishPlayerDamageWrapper" );
	//	PrintLn( sWeapon );
	//	if( IsPlayer( eAttacker ) )
	//		PrintLn( "Attacker: " + eAttacker.name );
	//	if( IsPlayer( self ) )
	//		PrintLn( "Victim: " + self.name + " alive? " + IsAlive( self ) );
	//	PrintLn( "Damage: " + iDamage );
	//	PrintLn( "Hit Loc: " + sHitLoc );
	//	if( IsDefined( iDFlags ) )
	//		PrintLn( "Penetration: " + ( iDFlags & level.iDFLAGS_PENETRATION ) );
	//	PrintLn( "Time of damage: " + GetTime() );
	//}
#/

	if ( ( self isUsingRemote() && (iDamage >= self.health) && !(iDFlags & level.iDFLAGS_STUN) && allowFauxDeath() ) || self isRocketCorpse() )
	{
		if ( !IsDefined( vDir ) )
			vDir = ( 0,0,0 );

		if ( !IsDefined( eAttacker ) && !IsDefined( eInflictor ) )
		{
			eAttacker = self;
			eInflictor = eAttacker;
		}
		
		assert( IsDefined( eAttacker ) );
		assert( IsDefined( eInflictor ) );

		PlayerKilled_internal( eInflictor, eAttacker, self, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, 0, true );
	}
	else
	{
		if ( !self Callback_KillingBlow( eInflictor, eAttacker, iDamage - (iDamage * stunFraction), iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime ) )
			return;
			
		if ( !isAlive(self) )
			return;

		if ( isPlayer( self ) ) 
			self finishPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, stunFraction );
	}

	if ( sMeansOfDeath == "MOD_EXPLOSIVE_BULLET" && !is_aliens() )
		self shellShock( "damage_mp", getDvarFloat( "scr_csmode" ) );

	self damageShellshockAndRumble( eInflictor, sWeapon, sMeansOfDeath, iDamage, iDFlags, eAttacker );
}

allowFauxDeath()
{
	//will be true unless explicitly defined otherwise
	if ( !IsDefined( level.allowFauxDeath ) )
		level.allowFauxDeath = true;
	
	return ( level.allowFauxDeath );
}

Callback_PlayerLastStand( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{	
		
	lastStandParams = spawnStruct();
	lastStandParams.eInflictor = eInflictor;
	lastStandParams.attacker = attacker;
	lastStandParams.iDamage = iDamage;
	lastStandParams.attackerPosition = attacker.origin;
	if ( attacker == self )
		lastStandParams.sMeansOfDeath = "MOD_SUICIDE";
	else
		lastStandParams.sMeansOfDeath = sMeansOfDeath;
	
	lastStandParams.sWeapon = sWeapon;
	if ( IsDefined( attacker ) && IsPlayer( attacker ) && attacker getCurrentPrimaryWeapon() != "none" )
		lastStandParams.sPrimaryWeapon = attacker getCurrentPrimaryWeapon();
	else
		lastStandParams.sPrimaryWeapon = undefined;
	lastStandParams.vDir = vDir;
	lastStandParams.sHitLoc = sHitLoc;
	lastStandParams.lastStandStartTime = getTime();

	mayDoLastStand = mayDoLastStand( sWeapon, sMeansOfDeath, sHitLoc );
	
	//if ( mayDoLastStand )
	//	mayDoLastStand = !self checkForceBleedOut();
	
	if ( IsDefined( self.endGame ) )
		mayDoLastStand = false;
	
	if ( level.teamBased && IsDefined( attacker.team ) && attacker.team == self.team )
		mayDoLastStand = false;

	if ( level.dieHardMode )
	{
		if ( level.teamCount[ self.team ] <= 1 )
		{
			mayDoLastStand = false;
		}
		else if ( self isTeamInLastStand() )
		{
			mayDoLastStand = false;
			killTeamInLastStand( self.team );
		}
		
	}
	
	 /#
	if ( getdvar( "scr_forcelaststand" ) == "1" )
		mayDoLastStand = true;
	#/
	
	if ( !mayDoLastStand )
	{
		self.lastStandParams = lastStandParams;
		self.useLastStandParams = true;
		self _suicide();
		return;
	}
	
	self.inLastStand = true;

	notifyData = spawnStruct();
	if ( self _hasPerk( "specialty_finalstand" ) )
	{
		notifyData.titleText = game[ "strings" ][ "final_stand" ];
		notifyData.iconName = "specialty_finalstand";
	}
	else if ( self _hasPerk( "specialty_c4death" ) )
	{
		notifyData.titleText = game[ "strings" ][ "c4_death" ];
		notifyData.iconName = "specialty_c4death";
	}
	else
	{
		notifyData.titleText = game[ "strings" ][ "last_stand" ];
		notifyData.iconName = "specialty_finalstand";
	}
	notifyData.glowColor = ( 1, 0, 0 );
	notifyData.sound = "mp_last_stand";
	notifyData.duration = 2.0;

	self.health = 1;

	self thread maps\mp\gametypes\_hud_message::notifyMessage( notifyData );

	grenadeTypePrimary = "frag_grenade_mp";

	if ( IsDefined( level.ac130player ) && IsDefined( attacker ) && level.ac130player == attacker )
		level notify( "ai_crawling", self );
	
	if ( self _hasPerk( "specialty_finalstand" ) )
	{
		self.lastStandParams = lastStandParams;
		self.inFinalStand = true;
		
		weaponList = self GetWeaponsListExclusives();
		foreach ( weapon in weaponList )
			self takeWeapon( weapon );
		
		self _disableUsability();

		self thread enableLastStandWeapons();
		self thread lastStandTimer( 20, true );		
	}
	else if ( self _hasPerk( "specialty_c4death" ) )
	{
		self.previousPrimary = self.lastdroppableweapon;
		self.lastStandParams = lastStandParams;

		self takeAllWeapons();
		self giveWeapon( "c4death_mp", 0, false );
		self switchToWeapon( "c4death_mp" );
		self _disableUsability();
		self.inC4Death = true;
		
		//self thread dieAfterTime( 7 );
		self thread lastStandTimer( 20, false );	
		self thread detonateOnUse();
		self thread detonateOnDeath();	
	}
	else if ( level.dieHardMode )
	{	
		attacker maps\mp\gametypes\_rank::giveRankXP( "kill", 100, sWeapon, sMeansOfDeath );
		self.lastStandParams = lastStandParams;
//		self thread enableLastStandWeapons();
		self _DisableWeapon();
		//self thread dieAfterTime( 10 );
		self thread lastStandTimer( 20, false );
		self _disableUsability();
	}
	else // normal last stand
	{
		self.lastStandParams = lastStandParams;
		
		pistolWeapon = undefined;
		
		weaponsList = self GetWeaponsListPrimaries();
		foreach ( weapon in weaponsList )
		{
			if ( maps\mp\gametypes\_weapons::isSideArm( weapon ) )
				pistolWeapon = weapon;			
		}
			
		if ( !IsDefined( pistolWeapon ) )
		{
			pistolWeapon = "iw6_p226_mp";
			self _giveWeapon( pistolWeapon );
		}
	
		self giveMaxAmmo( pistolWeapon );
		self DisableWeaponSwitch();
		self _disableUsability();
		
		if ( !self _hasPerk("specialty_laststandoffhand") )
			self DisableOffhandWeapons();
				
		self switchToWeapon( pistolWeapon );
		
		self thread lastStandTimer( 10, false );
	}
}

dieAfterTime( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "joined_team" );
	level endon( "game_ended" );
	
	wait ( time );
	self.useLastStandParams = true;
	self _suicide();
}

detonateOnUse()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "joined_team" );
	level endon( "game_ended" );
	
	self waittill( "detonate" );
	self.useLastStandParams = true;
	self c4DeathDetonate();
}

detonateOnDeath()
{
	self endon( "detonate" );
	self endon( "disconnect" );
	self endon( "joined_team" );
	level endon( "game_ended" );
	
	self waittill( "death" );
	self c4DeathDetonate();
}

c4DeathDetonate()
{
	self playSound( "detpack_explo_default" );
	//self.c4DeathEffect = playFX( level.c4Death, self.origin );
	RadiusDamage( self.origin, 312, 100, 100, self );
	
	if ( isAlive( self ) )
		self _suicide();
}

enableLastStandWeapons()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	self freezeControlsWrapper( true );
	wait .30;
	
	self freezeControlsWrapper( false );
}

lastStandTimer( delay, isFinalStand )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "revive");
	level endon( "game_ended" );
	
	level notify ( "player_last_stand" );
	
	self thread lastStandWaittillDeath();
	
	self.lastStand = true;
	
	if ( !isFinalStand && ( !IsDefined( self.inC4Death ) || !self.inC4Death ) )
	{
		self thread lastStandAllowSuicide();
		self setLowerMessage( "last_stand", &"PLATFORM_COWARDS_WAY_OUT", undefined, undefined, undefined, undefined, undefined, undefined, true );
		self thread lastStandKeepOverlay();
	}
	
	if ( level.dieHardMode == 1 && level.dieHardMode != 2 )
	{
		reviveEnt = spawn( "script_model", self.origin );
		reviveEnt setModel( "tag_origin" );
		reviveEnt setCursorHint( "HINT_NOICON" );
		reviveEnt setHintString( &"PLATFORM_REVIVE" );

		reviveEnt reviveSetup( self );
		reviveEnt endon ( "death" );

		reviveIcon = newTeamHudElem( self.team );
		reviveIcon setShader( "waypoint_revive", 8, 8 );
		reviveIcon setWaypoint( true, true );
		reviveIcon SetTargetEnt( self );
		reviveIcon thread destroyOnReviveEntDeath( reviveEnt );

		reviveIcon.color = (0.33, 0.75, 0.24);
		self playDeathSound();
		
		if ( isFinalStand )
		{
			wait( delay );
			
			if ( self.inFinalStand )
				self thread lastStandBleedOut( isFinalStand, reviveEnt );
		}
		
		return;
	}
	else if( level.dieHardMode == 2 )
	{
		self thread lastStandKeepOverlay();
		reviveEnt = spawn( "script_model", self.origin );
		reviveEnt setModel( "tag_origin" );
		reviveEnt setCursorHint( "HINT_NOICON" );
		reviveEnt setHintString( &"PLATFORM_REVIVE" );

		reviveEnt reviveSetup( self );
		reviveEnt endon ( "death" );

		reviveIcon = newTeamHudElem( self.team );
		reviveIcon setShader( "waypoint_revive", 8, 8 );
		reviveIcon setWaypoint( true, true );
		reviveIcon SetTargetEnt( self );
		reviveIcon thread destroyOnReviveEntDeath( reviveEnt );

		reviveIcon.color = (0.33, 0.75, 0.24);
		self playDeathSound();
		
		if ( isFinalStand )
		{
			wait( delay );
			
			if ( self.inFinalStand )
				self thread lastStandBleedOut( isFinalStand, reviveEnt );
		}
		
		wait delay / 3;
		reviveIcon.color = (1.0, 0.64, 0.0);
		
		while ( reviveEnt.inUse )
			wait ( 0.05 );
		
		self playDeathSound();	
		wait delay / 3;
		reviveIcon.color = (1.0, 0.0, 0.0);

		while ( reviveEnt.inUse )
			wait ( 0.05 );

		self playDeathSound();
		wait delay / 3;	

		while ( reviveEnt.inUse )
			wait ( 0.05 );
		
		wait( 0.05 ); 
		self thread lastStandBleedOut( isFinalStand );
		return;
	}
	
	self thread lastStandKeepOverlay();
	wait( delay );
	self thread lastStandBleedout( isFinalStand );

}

maxHealthOverlay( maxHealth, refresh )
{
	self endon( "stop_maxHealthOverlay" );
	self endon( "revive" );
	self endon( "death" );
	
	for( ;; )
	{
		self.health -= 1;
		self.maxHealth = maxHealth;
		wait( .05 );
		self.maxHealth = 50;
		self.health += 1;
	
		wait ( .50 );
	}	
}

lastStandBleedOut( reviveOnBleedOut, reviveEnt )
{
	if ( reviveOnBleedOut )
	{
		self.lastStand = undefined;
		self.inFinalStand = false;
		self notify( "revive" );
		self clearLowerMessage( "last_stand" );
		maps\mp\gametypes\_playerlogic::lastStandRespawnPlayer();
		
		if( IsDefined( reviveEnt ) )
			reviveEnt Delete();
	}
	else
	{
		self.useLastStandParams = true;
		self.beingRevived = false;
		self _suicide();
	}
}


lastStandAllowSuicide()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "game_ended" );
	self endon( "revive");

	while ( 1 )
	{
		if ( self useButtonPressed() )
		{
			pressStartTime = gettime();
			while ( self useButtonPressed() )
			{
				wait .05;
				if ( gettime() - pressStartTime > 700 )
					break;
			}
			if ( gettime() - pressStartTime > 700 )
				break;
		}
		wait .05;
	}

	self thread lastStandBleedOut( false );
}

lastStandKeepOverlay()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "revive" );

	// keep the health overlay going by making code think the player is getting damaged
	while ( !level.gameEnded )
	{
		self.health = 2;
		wait .05;
		self.health = 1;
		wait .5;
	}
	
	self.health = self.maxhealth;
}


lastStandWaittillDeath()
{
	self endon( "disconnect" );
	self endon( "revive" );
	level endon( "game_ended" );
	self waittill( "death" );

	self clearLowerMessage( "last_stand" );
	self.lastStand = undefined;
}


mayDoLastStand( sWeapon, sMeansOfDeath, sHitLoc )
{
	if ( sMeansOfDeath == "MOD_TRIGGER_HURT" )
		return false;
	
	if ( sMeansOfDeath != "MOD_PISTOL_BULLET" && sMeansOfDeath != "MOD_RIFLE_BULLET" && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_EXPLOSIVE_BULLET" )
		return false;

	if ( sMeansOfDeath == "MOD_IMPACT" && maps\mp\gametypes\_weapons::isThrowingKnife( sWeapon ) )
		return false;
		
	if ( sMeansOfDeath == "MOD_IMPACT" && ( sWeapon == "m79_mp" || isSubStr(sWeapon, "gl_") ) )
		return false;

	if ( isHeadShot( sWeapon, sHitLoc, sMeansOfDeath ) )
		return false;
	
	if ( self isUsingRemote() )
		return false;

	return true;
}


ensureLastStandParamsValidity()
{
	// attacker may have become undefined if the player that killed me has disconnected
	if ( !IsDefined( self.lastStandParams.attacker ) )
		self.lastStandParams.attacker = self;
}

getHitLocHeight( sHitLoc )
{
	switch( sHitLoc )
	{
		case "helmet":
		case "head":
		case "neck":
			return 60;
		case "torso_upper":
		case "right_arm_upper":
		case "left_arm_upper":
		case "right_arm_lower":
		case "left_arm_lower":
		case "right_hand":
		case "left_hand":
		case "gun":
			return 48;
		case "torso_lower":
			return 40;
		case "right_leg_upper":
		case "left_leg_upper":
			return 32;
		case "right_leg_lower":
		case "left_leg_lower":
			return 10;
		case "right_foot":
		case "left_foot":
			return 5;
	}
	return 48;
}

delayStartRagdoll( ent, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath )
{
	if ( IsDefined( ent ) )
	{
		deathAnim = ent getCorpseAnim();
		if ( animhasnotetrack( deathAnim, "ignore_ragdoll" ) )
			return;
	}
	
	if ( IsDefined( level.noRagdollEnts ) && level.noRagdollEnts.size )
	{
		foreach( noRag in level.noRagdollEnts )
		{
			if ( distanceSquared( ent.origin, noRag.origin ) <	65536 ) //256^2
				return;
		}
	}

	wait( 0.2 );

	if ( !IsDefined( ent ) )
		return;

	if ( ent isRagDoll() )
		return;

	deathAnim = ent getcorpseanim();

	startFrac = 0.35;

	if ( animhasnotetrack( deathAnim, "start_ragdoll" ) )
	{
		times = getnotetracktimes( deathAnim, "start_ragdoll" );
		if ( IsDefined( times ) )
			startFrac = times[ 0 ];
	}

	waitTime = startFrac * getanimlength( deathAnim );
	wait( waitTime );

	if ( IsDefined( ent ) )
	{
		ent startragdoll( );
	}
}


getMostKilledBy()
{
	mostKilledBy = "";
	killCount = 0;

	killedByNames = getArrayKeys( self.killedBy );

	for ( index = 0; index < killedByNames.size; index++ )
	{
		killedByName = killedByNames[ index ];
		if ( self.killedBy[ killedByName ] <= killCount )
			continue;

		killCount = self.killedBy[ killedByName ];
		mostKilleBy = killedByName;
	}

	return mostKilledBy;
}


getMostKilled()
{
	mostKilled = "";
	killCount = 0;

	killedNames = getArrayKeys( self.killedPlayers );

	for ( index = 0; index < killedNames.size; index++ )
	{
		killedName = killedNames[ index ];
		if ( self.killedPlayers[ killedName ] <= killCount )
			continue;

		killCount = self.killedPlayers[ killedName ];
		mostKilled = killedName;
	}

	return mostKilled;
}


damageShellshockAndRumble( eInflictor, sWeapon, sMeansOfDeath, iDamage, iDFlags, eAttacker )
{
	self thread maps\mp\gametypes\_weapons::onWeaponDamage( eInflictor, sWeapon, sMeansOfDeath, iDamage, eAttacker );
	
	if( !IsAI( self ) )
		self PlayRumbleOnEntity( "damage_heavy" );
}


reviveSetup( owner )
{
	team = owner.team;
	
	self linkTo( owner, "tag_origin" );

	self.owner = owner;
	self.inUse = false;
	self makeUsable();
	self updateUsableByTeam( team );
	self thread trackTeamChanges( team );
	
	self thread reviveTriggerThink( team );
	
	self thread deleteOnReviveOrDeathOrDisconnect();
}


deleteOnReviveOrDeathOrDisconnect()
{
	self endon ( "death" );
	
	self.owner waittill_any ( "death", "disconnect" );
	
	self delete();
}


updateUsableByTeam( team )
{
	foreach (player in level.players)
	{
		if ( team == player.team && player != self.owner )
			self enablePlayerUse( player );	
		else
			self disablePlayerUse( player );	
	}	
}


trackTeamChanges( team )
{
	self endon ( "death" );
	
	while ( true )
	{
		level waittill ( "joined_team" );
		
		self updateUsableByTeam( team );
	}
}


trackLastStandChanges( team )
{
	self endon ( "death" );
	
	while ( true )
	{
		level waittill ( "player_last_stand" );
		
		self updateUsableByTeam( team );
	}
}


reviveTriggerThink( team )
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		self waittill ( "trigger", player );
		self.owner.beingRevived = true;

		if ( IsDefined(player.beingRevived) && player.beingRevived )
		{
			self.owner.beingRevived = false;
			continue;
		}
			
		self makeUnUsable();
		self.owner freezeControlsWrapper( true );

		revived = self useHoldThink( player );
		self.owner.beingRevived = false;
		
		if ( !isAlive( self.owner ) )
		{	
			self delete();
			return;
		}

		self.owner freezeControlsWrapper( false );
			
		if ( revived )
		{
			player thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "reviver", maps\mp\gametypes\_rank::getScoreInfoValue( "reviver" ) );
			player thread maps\mp\gametypes\_rank::giveRankXP( "reviver" );

			self.owner.lastStand = undefined;
			self.owner clearLowerMessage( "last_stand" );
			
			self.owner.moveSpeedScaler = 1;
			if( self.owner _hasPerk( "specialty_lightweight" ) )
				self.owner.moveSpeedScaler = lightWeightScalar();
			
			self.owner _EnableWeapon();
			self.owner.maxHealth = 100;
			
			self.owner maps\mp\gametypes\_weapons::updateMoveSpeedScale();
			self.owner maps\mp\gametypes\_playerlogic::lastStandRespawnPlayer();

			self.owner givePerk( "specialty_pistoldeath", false );
			self.owner.beingRevived = false;
			
			self delete();
			return;
		}
			
		self makeUsable();
		self updateUsableByTeam( team );
	}
}



/*
=============
useHoldThink

Claims the use trigger for player and displays a use bar
Returns true if the player sucessfully fills the use bar
=============
*/
useHoldThink( player, useTime )
{
	DEFAULT_USE_TIME = 3000;
	
	reviveSpot = spawn( "script_origin", self.origin );
	reviveSpot hide();	
	player playerLinkTo( reviveSpot );		
	player PlayerLinkedOffsetEnable();
	
	player _disableWeapon();
	
	self.curProgress = 0;
	self.inUse = true;
	self.useRate = 0;
	
	if ( isDefined ( useTime ) )
		self.useTime = useTime;
	else
		self.useTime = DEFAULT_USE_TIME;
		
	result = useHoldThinkLoop( player );
	
	self.inUse = false;
	reviveSpot Delete();
	
	if ( IsDefined( player ) && isReallyAlive( player ) )
	{
		player Unlink();
		player _enableWeapon();
	}

	if ( IsDefined( result ) && result )
	{
		self.owner thread maps\mp\gametypes\_hud_message::playerCardSplashNotify( "revived", player );
		self.owner.inlaststand = false;
		return true;
	}
	
	return false;
}

useHoldThinkLoop( player )
{
	level endon ( "game_ended" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );

	while( isReallyAlive( player ) && player useButtonPressed() && (self.curProgress < self.useTime) && (!IsDefined(player.lastStand) || !player.lastStand) )
	{
		self.curProgress += (50 * self.useRate);
		self.useRate = 1; /* * player.objectiveScaler;*/

		// the player is the one who is reviving and the self.owner being revived
		player maps\mp\gametypes\_gameobjects::updateUIProgress( self, true );
		self.owner maps\mp\gametypes\_gameobjects::updateUIProgress( self, true );

		if ( self.curProgress >= self.useTime )
		{
			self.inUse = false;
			player maps\mp\gametypes\_gameobjects::updateUIProgress( self, false );
			self.owner maps\mp\gametypes\_gameobjects::updateUIProgress( self, false );
			
			return isReallyAlive( player );
		}
		
		wait 0.05;
	}
	
	player maps\mp\gametypes\_gameobjects::updateUIProgress( self, false );
	self.owner maps\mp\gametypes\_gameobjects::updateUIProgress( self, false );
	return false;
}


Callback_KillingBlow( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	if ( IsDefined(self.lastDamageWasFromEnemy) && self.lastDamageWasFromEnemy && iDamage >= self.health && IsDefined( self.combatHigh ) && self.combatHigh == "specialty_endgame" )
	{
		//self maps\mp\killstreaks\_killstreaks::setAdrenaline( 0 );
		self givePerk( "specialty_endgame", false );
		return false;
	}
	
	return true;
}


emitFallDamage( iDamage )
{
	PhysicsExplosionSphere( self.origin, 64, 64, 1 );
	
	// get the entities we landed on
	damageEnts = [];
	for ( testAngle = 0; testAngle < 360; testAngle += 30 )
	{
		xOffset = cos( testAngle ) * 16;
		yOffset = sin( testAngle ) * 16;

		traceData = bulletTrace( self.origin + (xOffset, yOffset, 4), self.origin + (xOffset,yOffset,-6), true, self );
		//thread drawLine( self.origin + (xOffset, yOffset, 4), self.origin + (xOffset,yOffset,-6), 10.0 );
		
		if ( IsDefined( traceData["entity"] ) && IsDefined( traceData["entity"].targetname ) && (traceData["entity"].targetname == "destructible_vehicle" || traceData["entity"].targetname == "destructible_toy") )
			damageEnts[damageEnts.size] = traceData["entity"];
	}

	if ( damageEnts.size )
	{
		damageOwner = spawn( "script_origin", self.origin );
		damageOwner hide();
		damageOwner.type = "soft_landing";
		damageOwner.destructibles = damageEnts;
		radiusDamage( self.origin, 64, 100, 100, damageOwner );

		wait ( 0.1 );	
		damageOwner delete();
	}
}

isFlankKill( victim, attacker )
{
	victimForward = anglestoforward( victim.angles );
	victimForward = ( victimForward[0], victimForward[1], 0 );
	victimForward = VectorNormalize( victimForward );

	attackDirection = victim.origin - attacker.origin;
	attackDirection = ( attackDirection[0], attackDirection[1], 0 ); 
	attackDirection = VectorNormalize( attackDirection );

	dotProduct = VectorDot( victimForward, attackDirection );
	if ( dotProduct > 0 ) // 0 = cos( 90 ), 180 degree arc total
		return true;
	else
		return false;
}

//logPrintPlayerDeath( lifeId, attacker, iDamage, sMeansOfDeath, sWeapon, sPrimaryWeapon, sHitLoc )
//{
//	// create a lot of redundant data for the log print
//	lpselfnum = self getEntityNumber();
//	lpselfname = self.name;
//	lpselfteam = self.team;
//	lpselfguid = self.guid;
//
//	if ( IsPlayer( attacker ) )
//	{
//		lpattackGuid = attacker.guid;
//		lpattackname = attacker.name;
//		lpattackerteam = attacker.team;
//		lpattacknum = attacker getEntityNumber();
//		attackerString = attacker getXuid() + "(" + lpattackname + ")";
//	}
//	else
//	{
//		lpattackGuid = "";
//		lpattackname = "";
//		lpattackerteam = "world";
//		lpattacknum = -1;
//		attackerString = "none";
//	}
//
//	logPrint( "K;" + lpselfguid + ";" + lpselfnum + ";" + lpselfteam + ";" + lpselfname + ";" + lpattackguid + ";" + lpattacknum + ";" + lpattackerteam + ";" + lpattackname + ";" + sWeapon + ";" + iDamage + ";" + sMeansOfDeath + ";" + sHitLoc + "\n" );
//}


destroyOnReviveEntDeath( reviveEnt )
{
	reviveEnt waittill ( "death" );
	
	self destroy();
}


gamemodeModifyPlayerDamage( victim, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc )
{
	if ( IsDefined( eAttacker ) && IsPlayer( eAttacker ) && isAlive( eAttacker ) )
	{
		if ( level.matchRules_damageMultiplier )
			iDamage *= level.matchRules_damageMultiplier;
			
		if ( level.matchRules_vampirism )
			eAttacker.health = int( min( float( eAttacker.maxHealth ), float( eAttacker.health + 20 ) ) );
	}

	return iDamage;
}

registerKill( sWeapon, bNotifyIncrease )	// self == player
{
	// NOTE: added threading to the giveAdrenaline() call because it could block the killcam from playing for a killed player
	//	this was happening if you earned a remote mortar and had one more kill to get something like the remote tank, and earned it while in the remote mortar
	//	there's a isChangingWeapon() loop that blocks since we're in the remote mortar not changing weapons when given the new killstreak
	self thread maps\mp\killstreaks\_killstreaks::giveAdrenaline( "kill" );
	self.pers["cur_kill_streak"]++;
	
	if ( bNotifyIncrease )
	{
		self notify( "kill_streak_increased" );
	}
	
	bIsNotKillstreakWeapon = !isKillstreakWeapon( sWeapon );
	if( bIsNotKillstreakWeapon )
	{
		self.pers["cur_kill_streak_for_nuke"]++;
	}
	
	numKills = NUM_KILLS_GIVE_NUKE;
	if( self _hasPerk( "specialty_hardline" ) )
	{
		numKills--;
	}
	
	if( bIsNotKillstreakWeapon && self.pers["cur_kill_streak_for_nuke"] == numKills && !isAnyMLGMatch() )
	{
		if (!isDefined(level.supportNuke) || level.supportNuke )
			self giveUltimateKillstreak( numKills );
	}
}

giveUltimateKillstreak( numKills )	// self == player
{
	// assault
	self thread maps\mp\killstreaks\_killstreaks::giveKillstreak( "nuke", false, true, self );
	self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( "nuke", numKills );
}

/*
=============
///ScriptDocBegin
"Name: monitorDamage( <maxHealth>, <damageFeedback>, <onDeathFunc>, <modifyDamageFunc>, <bIsKillstreak> )"
"Summary: Monitor the entity taking damage and do the things that need to be done."
"Module: damage"
"CallOn: entity"
"MandatoryArg: <maxHealth> Max health of entity
"MandatoryArg: <damageFeedback> String name of effect to play on damage
"MandatoryArg: <onDeathFunc> Callback function if the entity is killed. Takes the form onDeathFunc( <attacker>, <weapon>, <damageType> )
"OptionalArg: <modifyDamageFunc> Modulate the damage based on the weapon, damageType, and other conditions. Takes the form of <int> modifyDamageFunc( <attacker>, <weapon>, <damageType>, <damage> ). If return < 0, stop processing damage
"OptionalArg: <bIsKillstreak> Track killstreak hit stats
"Example: self maps\mp\gametypes\_damage::monitorDamage( 100, "trophy", ::trophyHandleDeathDamage, ::trophyModifyDamage, false );
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
monitorDamage( maxHealth, damageFeedback, onDeathFunc, modifyDamageFunc, bIsKillstreak, rumble )
{
	self endon( "death" );
	level endon( "game_ended" );
	
	if( !isDefined( rumble ) )
		rumble = false;
	
	// use a health buffer to prevent dying to friendly fire
	self SetCanDamage( true );
	self.health = 999999; // keep it from dying anywhere in code
	self.maxHealth = maxHealth; // this is the health we'll check
	self.damageTaken = 0; // how much damage has it taken
	
	if ( !IsDefined( bIsKillstreak ) )
	{
		bIsKillstreak = false;
	}
	
	running = true;
	while ( running )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
		
		if ( rumble )
		{
			self PlayRumbleOnEntity( "damage_light" );
		}
		
		// Special little bird damage logic should be in modifyDamageFunc param
		// not in generic system -JC-ToDo:09/18/13
		if( isDefined( self.heliType ) && self.heliType == "littlebird" )
		{
			if ( !isDefined( self.attackers ) )
				self.attackers = [];
			
			// in some cases, like in mp_descent, there is no attacking player
			uniqueId = "";
			if ( IsDefined( attacker ) && isPlayer( attacker ) )
				uniqueId = attacker getUniqueId();
			
			if ( isDefined( self.attackers[ uniqueId ] ) )
				self.attackers[ uniqueId ] += damage;
			else
				self.attackers[ uniqueId ] = damage;
		}
		
		running = self monitorDamageOneShot( damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon, damageFeedback, onDeathFunc, modifyDamageFunc, bIsKillstreak );
	}
}

/*
=============
///ScriptDocBegin
"Name: monitorDamageOneShot( <damage>, <attacker>, <direction_vec>, <point>, <meansOfDeath>, <modelName>, <tagName>, <partName>, <iDFlags>, <weapon>, <damageFeedback>, <onDeathFunc>, <modifyDamageFunc>, <bIsKillstreak> )"
"Summary: Does the things that need to be done when the entity takes damage. This should be called if you are doing your own waittill( "damage" ) and not using monitorDamage."
"Module: damage"
"CallOn: entity"
"MandatoryArg: <damageFeedback> String name of effect to play on damage
"MandatoryArg: <onDeathFunc> Callback function if the entity is killed. Takes the form onDeathFunc( <attacker>, <weapon>, <damageType> )
"OptionalArg: <modifyDamageFunc> Modulate the damage based on the weapon, damageType, and other conditions. Takes the form of <int> modifyDamageFunc( <attacker>, <weapon>, <damageType>, <damage> ). If return < 0, stop processing damage
"OptionalArg: <bIsKillstreak> Track killstreak hit stats
"Example: self maps\mp\gametypes\_damage::monitorDamageOneShot( damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon, "trophy", ::trophyHandleDeathDamage, ::trophyModifyDamage, false );
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
monitorDamageOneShot( damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon, damageFeedback, onDeathFunc, modifyDamageFunc, bIsKillstreak )
{
	if ( !IsDefined( self ) )
		return false;

	// The "allowMonitoredDamage" was added for a specific case where the harrier is the attacker, instead of a player. (because the player calls a harrier, and the harrier shoots a missile)
	if ( IsDefined( attacker ) && !IsGameParticipant( attacker ) && !IsDefined( attacker.allowMonitoredDamage ) )
		return true;
	
	// don't allow people to destroy equipment on their team if FF is off
	// alines mode never allows FF on equipment/killstreaks
	if ( is_aliens() || ( IsDefined( attacker ) && !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, attacker ) ) )
		return true;
	
	modifiedDamage = damage;	
	if( IsDefined( weapon ) )
	{
		switch( weapon )
		{
		case "concussion_grenade_mp":
		case "flash_grenade_mp":
		case "smoke_grenade_mp":
		case "smoke_grenadejugg_mp":
			return true;
		}
		
		// -------------------------------------------------
		// OK, we are actually going to do some damage
		// modifyDamageFunc
		if ( !IsDefined( modifyDamageFunc ) )
		{
			modifyDamageFunc = ::modifyDamage;
		}
		modifiedDamage = [[ modifyDamageFunc ]]( attacker, weapon, meansOfDeath, damage );
	}
	
	// See IMS, helicopter for examples where we might want to stop processing this damage
	if ( modifiedDamage < 0 )
	{
		return true;
	}
	
	self.wasDamaged = true;
	self.damageTaken += modifiedDamage;
	
	if ( isDefined( iDFlags ) && ( iDFlags & level.iDFLAGS_PENETRATION ) )
	{
		self.wasDamagedFromBulletPenetration = true;
	}
	
	if ( bIsKillstreak )
	{
		maps\mp\killstreaks\_killstreaks::killstreakHit( attacker, weapon, self );	
	}
	
	if ( IsDefined( attacker ) )
	{
		if( IsPlayer( attacker ) )
		{
			// 6/17/14 DM - HITMARKER color update for killing killstreaks( except dogs and squadmates )
			if ( self.damagetaken >= self.maxhealth )
			{		
			 	damageFeedback = "hitkill";
			}
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( damageFeedback );
		}
		else if ( IsDefined( attacker.owner) && IsPlayer( attacker.owner ) )
		{
			attacker.owner maps\mp\gametypes\_damagefeedback::updateDamageFeedback( damageFeedback );
		}
	}
	
	// -------------------------------------------------
	// OK, we are actually going to do some damage
	if ( self.damagetaken >= self.maxhealth )
	{
		// what other params do we need to pass in?
		self thread [[ onDeathFunc ]]( attacker, weapon, meansOfDeath, damage );
		return false;
	}
	
	return true;
}

/*
=============
///ScriptDocBegin
"Name: modifyDamage( <attacker>, <weapon>, <damageType>, <damage> )"
"Summary: Increase the incoming damage under certain conditions
"Module: damage"
"CallOn: entity"
"MandatoryArg: <attacker>
"MandatoryArg: <weapon>
"MandatoryArg: <damageType>
"MandatoryArg: <damage>
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
modifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
	
	// modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleEmpDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleGrenadeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	return modifiedDamage;
}

// handleMissileDamage, handleMeleeDamage, handleEmpDamage, handleAPDamage
// in your modifyDamage callback, you can use any subset of these functions to
// do extra damage under certain conditions
handleMissileDamage( weapon, meansOfDeath, damage )
{
	actualDamage = damage;
	switch ( weapon )
	{
		// these are old
		/*
		case "stinger_mp":
		case "javelin_mp":
		case "remote_mortar_missile_mp":		
		case "remotemissile_projectile_mp":
		*/
		case "odin_projectile_large_rod_mp":
		case "odin_projectile_small_rod_mp":
		case "ac130_105mm_mp":	// odin reuse
		case "ac130_40mm_mp":	// odin reuse
		case "bomb_site_mp":
		case "drone_hive_projectile_mp":
		case "maverick_projectile_mp":		// a10
		case "aamissile_projectile_mp":
		case "iw6_maaws_mp":		// aa launcher
		case "iw6_maawschild_mp":	// aa launcher
		case "iw6_maawshoming_mp":	// aa launcher
		case "iw6_panzerfaust3_mp":
			self.largeProjectileDamage = true;
			actualDamage = self.maxHealth + 1;
			break;
		case "switch_blade_child_mp":
		case "remote_tank_projectile_mp":	// also used by vanguard
		case "hind_bomb_mp":
		case "hind_missile_mp":
			self.largeProjectileDamage = false;
			actualDamage = self.maxHealth + 1;
			break;
		// these are old
		/*
		case "artillery_mp":
		case "stealth_bomb_mp":
			self.largeProjectileDamage = false;
			actualDamage = ( damage * 4 );
			break;
		*/
		case "a10_30mm_turret_mp":
		case "heli_pilot_turret_mp":
		//case "osprey_player_minigun_mp":
			self.largeProjectileDamage = false;
			actualDamage *= 2; // since it's a larger caliber, make it hurt
			break;
		// !!! We should allow for adjustments to sam damage
		case "sam_projectile_mp":
			self.largeProjectileDamage = true;
			actualDamage = damage;
			break;
	}
	
	return actualDamage;
}

handleGrenadeDamage( weapon, damageType, modifiedDamage )
{
	if ( IsExplosiveDamageMOD( damageType ) )
	{
		switch ( weapon )
		{			
			// these guys do ~200 damage at max
			case "c4_mp":
			case "proximity_explosive_mp":
			case "mortar_shell_mp":
			case "iw6_rgm_mp":	// since this will also do impact damage
				modifiedDamage *= 3;
				break;
			// these guys do 130 damage at max
			case "frag_grenade_mp":
			case "semtex_mp":
			case "semtexproj_mp":
			case "iw6_mk32_mp":	// semtexproj_mp mapped to mk32 in code call back
				modifiedDamage *= 4;
				break;
			default:
				// if it's alt mode and explosive, we assume it's the underbarrel GL
				if ( isStrStart( weapon, "alt_" ) )
				{
					modifiedDamage *= 3;
				}					
				break;
		}
	}
	
	return modifiedDamage;
}

handleMeleeDamage( weapon, meansOfDeath, damage )
{
	if ( meansOfDeath == "MOD_MELEE" )
	{
		return self.maxHealth + 1;
	}
	
	return damage;
}

handleEmpDamage( weapon, meansOfDeath, damage )
{
	// add the fully cooked flash?
	if ( weapon == "emp_grenade_mp" && meansOfDeath == "MOD_GRENADE_SPLASH" )
	{
		// send stun?
		self notify( "emp_damage", weapon.owner, 8.0 );
		return 0;
	}
	
	return damage;
}

handleAPDamage( weapon, meansOfDeath, damage, attacker )
{
	if( meansOfDeath == "MOD_RIFLE_BULLET" || meansOfDeath == "MOD_PISTOL_BULLET" )
	{
		if( attacker _hasPerk( "specialty_armorpiercing" ) || isFMJDamage( weapon, meansOfDeath, attacker ) )
		{
			return damage * level.armorPiercingMod;
		}
	}
	
	return damage;
}

/*
=============
///ScriptDocBegin
"Name: onKillstreakKilled( <attacker>, <weapon>, <damageType>, <xpPopupName>, <leaderDialog>, <cardSplash> )"
"Summary: Handle the bookkeeping involved when a player's KS is killed
"Module: damage"
"CallOn: killstreak entity"
"MandatoryArg: <attacker>
"MandatoryArg: <weapon>
"MandatoryArg: <damageType>
"MandatoryArg: <xpPopup> From xp_event_table.csv.  Controls both the displayed text and the xp reward
"MandatoryArg: <leaderDialog>
"OptionalArg: <cardSplash> From splashTable.csv
"Example: self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, "sentry_destroyed", level.sentrySettings[ self.sentryType ].voDestroyed );
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
onKillstreakKilled( attacker, weapon, damageType, damage, xpPopup, leaderDialog, cardSplash )
{
	notifyFlag = false;
	
	validAttacker = undefined;
	if ( IsDefined( attacker ) && IsDefined( self.owner ) )
	{
		if ( IsDefined( attacker.owner ) && IsPlayer( attacker.owner ) )
		{
			attacker = attacker.owner;
		}
		
		if ( self.owner isEnemy( attacker ) )
		{
			validAttacker = attacker;
		}
	}
	
	/* 
	 * 2013-07-10 wallace: remoteUAV was using these checks, not sure why. I'm leaving them here in case we need them again
		if ( !isDefined(attacker.owner) && attacker.classname == "script_vehicle" )
				validAttacker = undefined;
		if ( isDefined( attacker.class ) && attacker.class == "worldspawn" )
				validAttacker = undefined;	
		if ( attacker.classname == "trigger_hurt" )
				validAttacker = undefined;		
	*/
	
	if( IsDefined( validAttacker )  )
	{
		validAttacker notify( "destroyed_killstreak", weapon );
		
		// !!! BLARG - should probably put some extra checks in giveRankXP to account for all the new <destroyed_X" events
		xpReward = 100;
		if ( IsDefined( xpPopup ) )
		{
			xpReward = maps\mp\gametypes\_rank::getScoreInfoValue( xpPopup );
			validAttacker thread maps\mp\gametypes\_rank::xpEventPopup( xpPopup );
		}
		validAttacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", xpReward, weapon, damageType );
		
		if ( IsDefined( cardSplash ) )
		{
			thread teamPlayerCardSplash( cardSplash, validAttacker );
		}
		
		thread maps\mp\gametypes\_missions::killstreakKilled( self.owner, self, undefined, validAttacker, damage, damageType, weapon );
		
		notifyFlag = true;
	}

	if( IsDefined( self.owner ) && IsDefined( leaderDialog ) )
	{
		self.owner thread leaderDialogOnPlayer( leaderDialog, undefined, undefined, self.origin );
	}

	self notify( "death" );
	
	return notifyFlag;
}
