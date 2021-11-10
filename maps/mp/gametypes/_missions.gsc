#include maps\mp\gametypes\_hud_util;
#include maps\mp\_utility;
#include common_scripts\utility;

CH_REF_COL		= 0;
CH_NAME_COL		= 1;
CH_DESC_COL		= 2;
CH_LABEL_COL	= 3;
CH_RES1_COL		= 4;
CH_RES2_COL		= 5;
CH_LEVEL_COL	= 6;
CH_CHALLENGE_COL = 7;
CH_PRESTIGE_COL	= 8;
CH_TARGET_COL	= 9;
CH_REWARD_COL	= 10;
CH_SP_REWARD_COL= 27;


TIER_FILE_COL	= 4;

CH_REGULAR		= 0;
CH_DAILY			= 1;
CH_WEEKLY			= 2;

UNLOCK_TABLE_REF = "mp/unlockTable.csv";
CHALLENGE_TABLE_REF = "mp/challengeTable.csv";
ALL_CHALLENGES_TABLE_REF = "mp/allChallengesTable.csv";
DAILY_CHALLENGES_TABLE_REF = "mp/dailychallengesTable.csv";
WEEKLY_CHALLENGES_TABLE_REF = "mp/weeklychallengesTable.csv";
CONST_OPREF_NUM_COMPLETED_OPS = "ch_weekly_2";	// needs to match CONST_OPREF_NUM_COMPLETED_OPS in OperationsUtils.lua


// OPERATIONS CONSTANTS
OP_ONTHEGO_RELOADTIME = 3000;	// in ms
OP_SLEIGHTOFHAND_RELOADTIME = 3000;
OP_OP_SLEIGHTOFHAND_RELOADTIME_SNIPER = 5000;
OP_RIOTSHIELD_PISTOLKILL_SWAPTIME = 2000;
CONSECUTIVE_KILL_INTERVAL = 3;

init()
{
	precacheString(&"MP_CHALLENGE_COMPLETED");

	if ( !mayProcessChallenges() )
		return;
	
	level.missionCallbacks = [];

	registerMissionCallback( "playerKilled", ::ch_kills );	
	registerMissionCallback( "playerKilled", ::ch_killstreak_kills );
	registerMissionCallback( "playerHardpoint", ::ch_hardpoints );
	registerMissionCallback( "playerAssist", ::ch_assists );	
	registerMissionCallback( "roundEnd", ::ch_roundwin );
	registerMissionCallback( "roundEnd", ::ch_roundplayed );
	registerMissionCallback( "vehicleKilled", ::ch_vehicle_killed );

	level thread onPlayerConnect();
}


mayProcessChallenges()
{
	/#
	if ( getDvarInt( "debug_challenges" ) )
		return true;
	#/
	
	if ( IsSquadsMode() )
	{
		return false;
	}
	
	// TEMPORARY: turning off challenges while we prototype
	// return false;
	return ( level.rankedMatch );
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		
		if ( !isDefined( player.pers["postGameChallenges"] ) )
			player.pers["postGameChallenges"] = 0;
		
		// need all players, including bots to set up some data (specifically explosiveInfo)
		player thread initMissionData();
		
		if (IsAI(player))
			continue;

		player thread onPlayerSpawned();
		player thread monitorBombUse();
		player thread monitorFallDistance();
		player thread monitorLiveTime();	
		player thread monitorStreaks();
		player thread monitorStreakReward();
		player thread monitorScavengerPickup();
		player thread monitorBlastShieldSurvival();
		// player thread monitorTacInsertionsDestroyed();
		player thread monitorProcessChallenge();
		player thread monitorKillstreakProgress();
		//player thread monitorCombatHighSurvival();
		player thread monitorKilledKillstreak();
		player thread monitorADSTime();
		player thread monitorWeaponSwap();
		player thread monitorFlashbang();
		player thread monitorConcussion();
		// player thread monitorMineTriggering();
		player thread monitorReload();
		player thread monitorSprintSlide();
		
		player NotifyOnPlayerCommand( "hold_breath", "+breath_sprint" );
		player NotifyOnPlayerCommand( "hold_breath", "+melee_breath" ); // needed for lefty button layout
		player NotifyOnPlayerCommand( "release_breath", "-breath_sprint" );
		player NotifyOnPlayerCommand( "release_breath", "-melee_breath" ); // needed for lefty button layout
		player thread monitorHoldBreath();
		
		player NotifyOnPlayerCommand( "jumped", "+goStand" );
		player thread monitorMantle();

		if ( isDefined( level.patientZeroName ) && isSubStr( player.name, level.patientZeroName ) )
		{
			player setRankedPlayerData( "challengeState", "ch_infected", 2 );
			player setRankedPlayerData( "challengeProgress", "ch_infected", 1 );
			player setRankedPlayerData( "challengeState", "ch_plague", 2 );
			player setRankedPlayerData( "challengeProgress", "ch_plague", 1 );
		}	
		
		player setCommonPlayerData( "round", "weaponsUsed", 0, "none" );
		player setCommonPlayerData( "round", "weaponsUsed", 1, "none" );
		player setCommonPlayerData( "round", "weaponsUsed", 2, "none" );
		player setCommonPlayerData( "round", "weaponXpEarned", 0, 0 );
		player setCommonPlayerData( "round", "weaponXpEarned", 1, 0 );
		player setCommonPlayerData( "round", "weaponXpEarned", 2, 0 );

		cardTitleIndex = player GetCommonPlayerData( "cardTitle" );
		cardTitle = tableLookupByRow( "mp/cardTitleTable.csv", cardTitleIndex, 0 );

		if ( cardTitle == "cardtitle_infected" )
			player.infected = true;
		else if ( cardTitle == "cardtitle_plague" )
			player.plague = true;
	}
}

// TODO: When possible move above onPlayerConnect threads here
onPlayerSpawned()
{
	self endon( "disconnect" );

	for(;;)
	{
		self waittill( "spawned_player" );
		
		// reset the tracker for meticulous challenge
		self.killsThisMag = [];

		self thread monitorSprintDistance();
	}
}

monitorScavengerPickup()
{
	self endon ( "disconnect" );

	for( ;; )
	{
		self waittill( "scavenger_pickup" ); 
		
		if ( self IsItemUnlocked( "specialty_scavenger" ) && self _hasPerk( "specialty_scavenger" ) && !self isJuggernaut() )
			self processChallenge( "ch_scavenger_pro" );
		
		wait( 0.05 );
	}	
}


monitorStreakReward()
{
	self endon ( "disconnect" );

	for( ;; )
	{
		self waittill( "received_earned_killstreak" ); 
		
		if ( self IsItemUnlocked( "specialty_hardline" ) && self _hasPerk( "specialty_hardline" ) )
			self processChallenge( "ch_hardline_pro" );
		
		wait( 0.05 );
	}	
}

monitorBlastShieldSurvival()
{
	self endon ( "disconnect" );

	for( ;; )
	{
		self waittill( "survived_explosion", attacker ); 
		
		// don't let the player boost themselves
		if( IsDefined( attacker ) && IsPlayer( attacker ) && self == attacker )
			continue;

		if ( self IsItemUnlocked( "_specialty_blastshield" ) && self _hasPerk( "_specialty_blastshield" ) )
			self processChallenge( "ch_blastshield_pro" );
		
		waitframe();
	}	
}

monitorTacInsertionsDestroyed()
{
	self endon ( "disconnect" );
	
	for(;;)
	{
		self waittill( "destroyed_insertion", owner );
		
		if ( self == owner )
			return;
		
		self processChallenge( "ch_darkbringer" );
		self incPlayerStat( "mosttacprevented", 1 );
	
		self thread maps\mp\gametypes\_hud_message::SplashNotify( "denied", 20 );
		owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "destroyed_insertion", self );

		waitframe();
	}
}

//monitorCombatHighSurvival()
//{
//	self endon ( "disconnect" );
//
//	for(;;)
//	{
//		self waittill( "combathigh_survived" );
//		
//		self processChallenge( "ch_thenumb" );
//
//		waitframe();
//	}
//}

// round based tracking
initMissionData()
{
	keys = getArrayKeys( level.killstreakFuncs );	
	foreach ( key in keys )
		self.pers[key] = 0;
	
	self.pers["lastBulletKillTime"] = 0;
	self.pers["bulletStreak"] = 0;
	self.explosiveInfo = [];
}

registerMissionCallback(callback, func)
{
	if (!isdefined(level.missionCallbacks[callback]))
		level.missionCallbacks[callback] = [];
	level.missionCallbacks[callback][level.missionCallbacks[callback].size] = func;
}


getChallengeStatus( name )
{
	assertEx( isDefined(self.challengeData), "Player: " + self.name + " doesnt have challenge data." );
	
	if ( isDefined( self.challengeData[name] ))
		return self.challengeData[name];
	else
		return 0;
}


ch_assists( data )
{
	player = data.player;
	
	player processChallenge( "ch_assists" );
	
	if ( IsDefined( player.isJuggernautRecon ) && player.isJuggernautRecon )
	{
		player processChallenge( "ch_assisted_firepower" );
	}
	
	// OP_IW6 - weapon camo challenges
	if ( IsDefined( data.sWeapon ) )
	{
		weaponClass = getWeaponClass( data.sWeapon );
		baseWeapon = getBaseWeaponName( data.sWeapon );
		switch ( weaponClass )
		{
			// 2013-09-25 wallace: erg, these challenge names should all have the same ending, but I made a mistake
			case "weapon_smg":
			case "weapon_assault":
			case "weapon_dmr":
			case "weapon_lmg":
				self processChallenge( "ch_" + baseWeapon + "_assists" );
				break;
			case "weapon_shotgun":
				self processChallenge( "ch_" + baseWeapon + "_assist" );
				break;
			default:
				if ( maps\mp\gametypes\_weapons::isRiotShield( data.sWeapon ) )
				{
					self processChallenge( "ch_iw6_riotshield_assist" );
				}
				break;
		}
	}
}

NUM_SATCOMS_FOR_CHALLENGE = 3;
NUM_HELICOPTERS_FOR_CHALLENGE = 2;
ch_hardpoints( data )
{
	player = data.player;
	
	player.pers[data.hardpointType]++;

	switch ( data.hardpointType )
	{
	// Assault Killstreaks
	case "uplink":
		player processChallenge( "ch_uplink" );
		player processChallenge( "ch_assault_streaks" );
		if ( player checkNumUsesOfPersistentData( "uplink", NUM_SATCOMS_FOR_CHALLENGE ) )
			player processChallenge( "ch_nosecrets" );
		break;
	case "guard_dog":
		player processChallenge( "ch_guard_dog" );
		player processChallenge( "ch_assault_streaks" );
		break;
	case "airdrop_juggernaut_maniac":
		player processChallenge( "ch_airdrop_juggernaut_maniac" );
		player processChallenge( "ch_assault_streaks" );
		break;
	case "ims":
		// player processChallenge( "ch_ims" );
		player processChallenge( "ch_assault_streaks" );
		//if ( player.pers["ims"] >= 2 )
		//	player processChallenge( "ch_???" );
		break;
	case "helicopter":
		player processChallenge( "ch_assault_streaks" );
		
		// OP_IW6 Far Superior: 2 helis in one match. Different from ch_air_superiority!
		if ( player checkNumUsesOfPersistentData( "helicopter", NUM_HELICOPTERS_FOR_CHALLENGE ) )
		{
			player processChallenge( "ch_airsuperiority" );
		}
		break;
	case "sentry":
	case "ball_drone_backup":
	case "drone_hive":
	case "vanguard":
	case "airdrop_juggernaut":
	case "heli_pilot":
	case "odin_assault":
		player processChallenge( "ch_assault_streaks" );
		break;
	// End Assault Killstreaks



	// Support Killstreaks
	case "uplink_support":
		player processChallenge( "ch_uplink_support" );
		player processChallenge( "ch_support_streaks" );
		break;
	case "deployable_vest":
		player processChallenge( "ch_deployable_vest" );
		player processChallenge( "ch_support_streaks" );
		//if ( player.pers["deployable_vest"] >= 3 )
		//	player processChallenge( "ch_???" );
		break;
	case "deployable_ammo":
		player processChallenge( "ch_deployable_ammo" );
		player processChallenge( "ch_support_streaks" );
		break;
	case "ball_drone_radar":
		player processChallenge( "ch_ball_drone_radar" );
		player processChallenge( "ch_support_streaks" );
		break;
	case "aa_launcher":
		player processChallenge( "ch_support_streaks" );
		break;
	case "jammer":
		player processChallenge( "ch_jammer" );
		player processChallenge( "ch_support_streaks" );
		break;
	case "air_superiority":
		player processChallenge( "ch_support_streaks" );
		break;
	case "recon_agent":
		player processChallenge( "ch_recon_agent" );
		player processChallenge( "ch_support_streaks" );
		break;
	case "heli_sniper":
		player processChallenge( "ch_heli_sniper" );
		player processChallenge( "ch_support_streaks" );
		break;
	case "uav_3dping":
		player processChallenge( "ch_uav_3dping" );
		player processChallenge( "ch_support_streaks" );
		break;
	case "airdrop_juggernaut_recon":
		player processChallenge( "ch_support_streaks" );
		//if ( player.pers["airdrop_juggernaut_recon"] >= 2 )
		//	player processChallenge( "ch_???" );
		break;
	case "odin_support":
		player processChallenge( "ch_odin_support" );
		player processChallenge( "ch_support_streaks" );
		break;
	// End Support Killstreaks



	// Specialist Killstreaks
	/*
	case "specialty_longersprint_ks":
	case "specialty_longersprint_ks_pro":
		player processChallenge( "ch_longersprint_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_fastreload_ks":
	case "specialty_fastreload_ks_pro":
		player processChallenge( "ch_fastreload_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_scavenger_ks":
	case "specialty_scavenger_ks_pro":
		player processChallenge( "ch_scavenger_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_blindeye_ks":
	case "specialty_blindeye_ks_pro":
		player processChallenge( "ch_blindeye_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_paint_ks":
	case "specialty_paint_ks_pro":
		player processChallenge( "ch_paint_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_hardline_ks":
	case "specialty_hardline_ks_pro":
		player processChallenge( "ch_hardline_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_coldblooded_ks":
	case "specialty_coldblooded_ks_pro":
		player processChallenge( "ch_coldblooded_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_quickdraw_ks":
	case "specialty_quickdraw_ks_pro":
		player processChallenge( "ch_quickdraw_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "_specialty_blastshield_ks":
	case "_specialty_blastshield_ks_pro":
		player processChallenge( "ch_blastshield_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_detectexplosive_ks":
	case "specialty_detectexplosive_ks_pro":
		player processChallenge( "ch_detectexplosive_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_autospot_ks":
	case "specialty_autospot_ks_pro":
		player processChallenge( "ch_autospot_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_bulletaccuracy_ks":
	case "specialty_bulletaccuracy_ks_pro":
		player processChallenge( "ch_bulletaccuracy_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_quieter_ks":
	case "specialty_quieter_ks_pro":
		player processChallenge( "ch_quieter_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
	case "specialty_stalker_ks":
	case "specialty_stalker_ks_pro":
		player processChallenge( "ch_stalker_ks" );
		player processChallenge( "ch_specialist_streaks" );
		break;
		*/
	case "all_perks_bonus":
		player processChallenge( "ch_all_perks_bonus" );
		break;
	// End Specialist Killstreaks



	// Secret Killstreaks
	case "nuke":
		player processChallenge( "ch_nuke" );
		break;
	}
}


ch_killstreak_kills( data )
{
	if ( !isDefined( data.attacker ) || !isPlayer( data.attacker ) )
		return;

	if ( !isKillstreakWeapon( data.sWeapon ) )
		return;
		
	player = data.attacker;

	// we need to reset the streak if there has been time in between airstrike kills because the challenge is for killing with 1 airstrike but this was accumulating during the entire match
	if( !isDefined( player.pers[data.sWeapon + "_streak"] ) || 
		( IsDefined( player.pers[data.sWeapon + "_streakTime"] ) && GetTime() - player.pers[data.sWeapon + "_streakTime"] > 7000 ) )
	{
		player.pers[data.sWeapon + "_streak"] = 0;
		player.pers[data.sWeapon + "_streakTime"] = GetTime();
	}

	player.pers[data.sWeapon + "_streak"]++;

	switch ( data.sWeapon )
	{
		case "sentry_minigun_mp":		// Sentry Gun
			player processChallenge( "ch_looknohands" );
			break;

		case "remote_tank_projectile_mp":	// vanguard
			player processChallenge( "ch_incoming" );
			break;

		case "heli_pilot_turret_mp": // heli pilot
			player processChallenge( "ch_helo_pilot" );
			break;
			
		// will this get processed in this function?
		case "iw6_gm6helisnipe_mp_gm6scope":	// heli sniper
			player processChallenge( "ch_long_distance_shooter" );
			break;
		
		case "drone_hive_projectile_mp":	// trinity rocket
		case "switch_blade_child_mp":
			player processChallenge( "ch_clusterfunk" );
			
			// 2013-09-08 wallace: a minor hack: going to count on _droneHive to reset these values for each missile, because the array was originally meant to track gun kills
			trinityKills = player.killsThisLifePerWeapon[ "drone_hive_projectile_mp" ] + player.killsThisLifePerWeapon[ "switch_blade_child_mp" ];
			if ( isNumberMultipleOf( trinityKills, 4 ) )
			{
				player processChallenge( "ch_bullseye" );
			}
			break;
			
		case "ball_drone_gun_mp":	// backup buddy / vulture
			player processChallenge( "ch_vulture" );
			break;
			
		case "odin_projectile_large_rod_mp":	// loki
		case "odin_projectile_small_rod_mp":
			player processChallenge( "ch_overlord" );
			break;
		
		case "cobra_20mm_mp":	// Attack Helicopter
		case "hind_bomb_mp":	// battle hind
		case "hind_missile_mp":
			player processChallenge( "ch_choppervet" );
			break;
			
		case "guard_dog_mp":
			player processChallenge( "ch_downboy" );
			break;
		
		case "ims_projectile_mp":
			player processChallenge( "ch_outsmarted" );
			break;
			
		case "iw6_minigunjugg_mp":	// assault juggernaut
		case "iw6_p226jugg_mp":
		case "mortar_shelljugg_mp":
			player processChallenge( "ch_painless" );
			break;

		case "nuke_mp":					// Nuke
			data.victim processChallenge( "ch_radiationsickness" );
			break;
		
		case "throwingknifejugg_mp":
		case "iw6_knifeonlyjugg_mp":	// maniac
			break;
			
		case "agent_support_mp":	// recon agent
			break;

		default:
			break;		
	}
}	


ch_vehicle_killed( data )
{
	if ( !isDefined( data.attacker ) || !isPlayer( data.attacker ) )
		return;

	player = data.attacker;
}


clearIDShortly( expId )
{
	self endon ( "disconnect" );
	
	self notify( "clearing_expID_" + expID );
	self endon ( "clearing_expID_" + expID );
	
	wait ( 3.0 );
	self.explosiveKills[expId] = undefined;
}

MGKill()
{
	player = self;
	if ( !isDefined( player.pers["MGStreak"] ) )
	{
		player.pers["MGStreak"] = 0;
		player thread endMGStreakWhenLeaveMG();
		if ( !isDefined( player.pers["MGStreak"] ) )
			return;
	}
	player.pers["MGStreak"]++;
	//iprintln( player.pers["MGStreak"] );
	if ( player.pers["MGStreak"] >= 5 )
		player processChallenge( "ch_mgmaster" );
}

endMGStreakWhenLeaveMG()
{
	self endon("disconnect");
	while(1)
	{
		if ( !isAlive( self ) || self useButtonPressed() )
		{
			self.pers["MGStreak"] = undefined;
			//iprintln("0");
			break;
		}
		wait .05;
	}
}

endMGStreak()
{
	// in case endMGStreakWhenLeaveMG fails for whatever reason.
	self.pers["MGStreak"] = undefined;
	//iprintln("0");
}

killedBestEnemyPlayer( wasBest )
{
	if ( !isdefined( self.pers["countermvp_streak"] ) || !wasBest )
		self.pers["countermvp_streak"] = 0;
	
	self.pers["countermvp_streak"]++;
	
	if ( self.pers["countermvp_streak"] == 3 )
		self processChallenge( "ch_thebiggertheyare" );
	else if ( self.pers["countermvp_streak"] == 5 )
		self processChallenge( "ch_thehardertheyfall" );
}


isHighestScoringPlayer( player )
{
	if ( !isDefined( player.score ) || player.score < 1 )
		return false;

	players = level.players;
	if ( level.teamBased )
		team = player.pers["team"];
	else
		team = "all";

	highScore = player.score;

	for( i = 0; i < players.size; i++ )
	{
		if ( !isDefined( players[i].score ) )
			continue;
			
		if ( players[i].score < 1 )
			continue;

		if ( team != "all" && players[i].pers["team"] != team )
			continue;
		
		if ( players[i].score > highScore )
			return false;
	}
	
	return true;
}


ch_kills( data, time )
{
	player = data.attacker;
	victim = data.victim;
	
	victim playerDied();
	
	// bots are players, and also AI
	if ( !isDefined( player ) || !isPlayer( player ) )
		return;
	
	time = data.time;
	
	if ( player.pers["cur_kill_streak"] == 10 )
		player processChallenge( "ch_fearless" );

	if ( level.teamBased )
	{
		// using player.ch_tangoDownComplete to throttle challenge completion in case killedPlayers.size is never > 4
		if ( level.teamCount[data.victim.pers["team"]] > 3 && player.killedPlayers.size == 4 && player.ch_tangoDownComplete == false )
		{
			player processChallenge( "ch_tangodown" );
			player.ch_tangoDownComplete = true;
			//maps\mp\_awards::addAwardWinner( "killedotherteam", player.clientid );
		}
		// using player.ch_extremeCrueltyComplete to throttle challenge completion in case killedPlayersCurrent.size is never > 4
		if ( level.teamCount[data.victim.pers["team"]] > 3 && player.killedPlayersCurrent.size == 4 && player.ch_extremeCrueltyComplete == false )
		{
			player processChallenge( "ch_extremecruelty" );
			player.ch_extremeCrueltyComplete = true;
			//maps\mp\_awards::addAwardWinner( "killedotherteamonelife", player.clientid );
		}
	}
	
	// if the victim is within the attackers smoke when they are killed
	if( IsDefined( victim.inPlayerSmokeScreen ) && victim.inPlayerSmokeScreen == player )
		player processChallenge( "ch_smokeemifyougotem" );

	if ( isDefined( player.killedPlayers[data.victim.guid] ) && player.killedPlayers[data.victim.guid] == 5 )
		player processChallenge( "ch_rival" );
	
	if ( isdefined( player.tookWeaponFrom[ data.sWeapon ] ) )
	{
		if ( player.tookWeaponFrom[ data.sWeapon ] == data.victim 
		    // allow the challenge to work with riotshields and knife-only
		    && ( data.sMeansOfDeath != "MOD_MELEE" || maps\mp\gametypes\_weapons::isRiotShield( data.sWeapon ) || maps\mp\gametypes\_weapons::isKnifeOnly( data.sWeapon ) )
		   )
			player processChallenge( "ch_cruelty" );
	}

	oneLeftCount = 0;

	secondaryCount = 0;
	longshotCount = 0;
	killsLast10s = 1;
	loadoutPrimaryCount = 0;
	loadoutSecondaryCount = 0;
	
	
	killedPlayers[data.victim.name] = data.victim.name;
	usedWeapons[data.sWeapon] = data.sWeapon;
	uniqueKills = 1;
	killstreakKills = [];
	
	foreach ( killData in player.killsThisLife )
	{
		if ( isCACSecondaryWeapon( killData.sWeapon ) && killData.sMeansOfDeath != "MOD_MELEE" )
			secondaryCount++;
		
		if ( killData.sWeapon == player.primaryWeapon )
			loadoutPrimaryCount++;
		else if ( killData.sWeapon == player.secondaryWeapon )
			loadoutSecondaryCount++;
		
		if ( isDefined( killData.modifiers["longshot"] ) )
			longshotCount++;

		if ( time - killData.time < 10000 )
			killsLast10s++;		

		if ( isKillstreakWeapon( killData.sWeapon ) )
		{
			if ( !isDefined( killstreakKills[ killData.sWeapon ] ) )
				killstreakKills[ killData.sWeapon ] = 0;

			killstreakKills[ killData.sWeapon ]++;
		}
		else
		{
			if ( isDefined( level.oneLeftTime[player.team] ) && killData.time > level.oneLeftTime[player.team] )
				oneLeftCount++;

			if ( isDefined( killData.victim ) )
			{
				if ( !isDefined( killedPlayers[killData.victim.name] ) && !isDefined( usedWeapons[killData.sWeapon] ) )
					uniqueKills++;
		
				killedPlayers[killData.victim.name] = killData.victim.name;
			}
			
			usedWeapons[killData.sWeapon] = killData.sWeapon;
		}
	}

	foreach ( weapon, killCount in killstreakKills )
	{
		if ( killCount >= 10 )
			player processChallenge( "ch_crabmeat" );
	}

	if ( uniqueKills == 3 )
		player processChallenge( "ch_renaissance" );

	if ( killsLast10s > 3 && level.teamCount[data.victim.team] <= killsLast10s )
		player processChallenge( "ch_omnicide" );

	if ( isCACSecondaryWeapon( data.sWeapon ) && secondaryCount == 2 )
		player processChallenge( "ch_sidekick" );

	if ( isDefined( data.modifiers["longshot"] ) && longshotCount == 2 )
		player processChallenge( "ch_nbk" );
	
	if ( isDefined( level.oneLeftTime[player.team] ) && oneLeftCount == 2 )
		player processChallenge( "ch_enemyofthestate" );
	
	// OP_IW6 No Place to Hide - kill 6 enemy players as the maniac in one life
	// should this be team-based only?
	if ( data.sWeapon == "iw6_knifeonlyjugg_mp" )
	{
		uniqueManiacKills[data.victim.name] = true;
		foreach ( killData in player.killsThisLife )
		{
			if ( killData.sWeapon == "iw6_knifeonlyjugg_mp" )
			{
				if ( isDefined( killData.victim ) && !isDefined( uniqueManiacKills[killData.victim.name] ) )
				{
					uniqueManiacKills[killData.victim.name] = true;
				}
			}
		}
		
		if ( uniqueManiacKills.size >= 6 )
			player processChallenge( "ch_noplacetohide" );
	}
	
	if ( data.sMeansOfDeath != "MOD_MELEE" )
	{
		// OP_IW6 Always Deadly - get a kill each with primary and secondary in one life
		if ( 
		    ( data.sWeapon == player.primaryWeapon && loadoutPrimaryCount < loadoutSecondaryCount )
		    || ( data.sWeapon == player.secondaryWeapon && loadoutSecondaryCount < loadoutPrimaryCount )
		   )
		{
			player processChallenge( "ch_always_deadly" );
		}

		if ( player shouldProcessChallengeForPerk( "specialty_twoprimaries" )
		    && player.secondaryWeapon == data.sWeapon 
		   )
		{
		player processChallenge( "ch_twoprimaries_pro" );
		}
	}
	
	if ( data.victim.score > 0 )
	{
		if ( level.teambased )
		{
			victimteam = data.victim.pers["team"];
			if ( isdefined( victimteam ) && victimteam != player.pers["team"] )
			{
				if ( isHighestScoringPlayer( data.victim ) && level.players.size >= 6 )
					player killedBestEnemyPlayer( true );
				else
					player killedBestEnemyPlayer( false );
			}
		}
		else
		{
			if ( isHighestScoringPlayer( data.victim ) && level.players.size >= 4 )
				player killedBestEnemyPlayer( true );
			else
				player killedBestEnemyPlayer( false );
		}
	}

	if ( isDefined( data.modifiers["avenger"] ) )
		player processChallenge( "ch_avenger" );
	
	if ( isDefined( data.modifiers["buzzkill"] ) && data.modifiers["buzzkill"] >= 9 )
		player processChallenge( "ch_thedenier" );
	
	// we want to track killstreak weapons too
	if ( isReallyAlive( player ) && data.sWeapon != "none" )
	{
		if ( IsDefined( player.killsThisLifePerWeapon[ data.sWeapon ] ) )
			player.killsThisLifePerWeapon[ data.sWeapon ]++;
		else
			player.killsThisLifePerWeapon[ data.sWeapon ] = 1;
	}

	// Filter out killstreak weapons
	// 2013-09-02 wallace: but allow some killstreaks, like juggernauts, to continue
	if ( isKillstreakWeapon( data.sWeapon ) 
	    && !allowKillChallengeForKillstreak( player, data.sWeapon ) )
		return;

	if ( isDefined( data.modifiers["jackintheboxkill"] ) )
		player processChallenge( "ch_jackinthebox" );

	if ( isDefined( data.modifiers["cooking"] ) )
		player processChallenge( "ch_no" );

	if ( player isAtBrinkOfDeath() )
	{
		player.brinkOfDeathKillStreak++;
		if ( isNumberMultipleOf( player.brinkOfDeathKillStreak, 3 ) )
		{
			player processChallenge( "ch_thebrink" );
		}
	}

	// In general, should killstreak kills count?
	
	// OP_IW6: Off the Grid: get kills while enemy satcoms are up
	if ( player shouldProcessChallengeForPerk( "specialty_gpsjammer" ) )
	{
		numSatComs = 0;
		if ( level.teamBased )
		{
			assert( IsDefined( level.comExpFuncs[ "getRadarStrengthForTeam" ] ) );
			getRadarStrengthForTeamFunc = level.comExpFuncs[ "getRadarStrengthForTeam" ];
			numSatComs = [[ getRadarStrengthForTeamFunc ]]( getOtherTeam( player.team ) );
		}
		else
		{
			foreach( uplink in level.uplinks )
			{
				if ( IsDefined( uplink ) && uplink.owner.guid != player.guid )
				{
					// if any enemy has a satcom, count it
					numSatComs++;
					break;
				}
			}
		}
		
		if ( numSatComs > 0 )
		{
			player processChallenge( "ch_offthegrid" );
		}
	}
	
	// OP_IW6 DeadEye
	if ( player shouldProcessChallengeForPerk( "specialty_deadeye" ) )
		player processChallenge( "ch_deadeye" );
	
	// OP_IW6 lightweight
	if ( player shouldProcessChallengeForPerk( "specialty_lightweight" ) )
		player processChallenge( "ch_lightweight" );

	// OP_IW6 Extra attachments
	// the attachment limit should come 
	if ( player shouldProcessChallengeForPerk( "specialty_extra_attachment" )
		&& data.sWeapon != "none" )	// 2013-09-05 wallace: should we be rejecting "none" weapons earlier?
	{
		// handle both primaries and pistols
		curAttachments = weaponGetNumAttachments( data.sWeapon );
		normalAttachments = 2;
		if ( maps\mp\gametypes\_weapons::isSideArm( data.sWeapon ) )
			normalAttachments = 1;
		
		if ( curAttachments > normalAttachments )
		{
			player processChallenge( "ch_extra_attachment" );
		}
	}
	
	// OP_IW6 Gambler
	if ( player shouldProcessChallengeForPerk( "specialty_gambler" ) )
	{
		player processChallenge( "ch_gambler" );
	}
	
	// OP_IW6 Regen faster
	if ( player shouldProcessChallengeForPerk( "specialty_regenfaster" ) 
	    && player.health < player.maxHealth
	   )
	{
		player processChallenge( "ch_regenfaster" );
	}
	
	// OP_IW6 On the Go
	if ( player shouldProcessChallengeForPerk( "specialty_sprintreload" )
	    && IsDefined( player.sprintReloadTimeStamp ) 
	    && GetTime() <= player.sprintReloadTimeStamp
	    && player.lastReloadedWeapon == data.sWeapon	// this must be defined if sprintReloadTimeStamp is also defined
	    && data.sMeansOfDeath != "MOD_MELEE"
	   )
	{
		player processChallenge( "ch_onthego" );
	}
	
	// OP_IW6 Strong Arm
	if ( player shouldProcessChallengeForPerk( "specialty_pitcher" ) 
	    && maps\mp\gametypes\_weapons::isOffhandWeapon( data.sWeapon )
	   )
	{
		player processChallenge( "ch_pitcher" );
	}
	
	// OP_IW6 Takedown
	if ( player shouldProcessChallengeForPerk( "specialty_silentkill" ) )
	{
		player processChallenge( "ch_silentkill" );
	}
	
	// OP_IW6 Wiretap - if there are satcoms up, it counts
	if ( player shouldProcessChallengeForPerk( "specialty_comexp" ) 
	    && level.uplinks.size > 0
	   )
	{
		player processChallenge( "ch_comexp" );
	}
	
	// OP_IW6 Boom - kill an enemy marked by ping. 
	// This isn't exactly accurate, since the timestamp can get overwritten if he's pinged again
	// also, we don't check ownership, so it might be more generous
	if ( player shouldProcessChallengeForPerk( "specialty_boom" ) )
	{
		guid = player getUniqueId();
		if ( IsDefined( victim.markedByBoomPerk )
		    && IsDefined( victim.markedByBoomPerk[ guid ] )
		    && GetTime() <= victim.markedByBoomPerk[ guid ] )
		{
			player processChallenge( "ch_boom" );
			victim.markedByBoomPerk = undefined;
		}
	}
	
	// OP_IW6 wise guy: get kills with picked up weapons
	if ( !maps\mp\gametypes\_weapons::isOffhandWeapon( data.sWeapon )
	    && data.sWeapon != player.pers[ "primaryWeapon" ]
	    && data.sWeapon != player.pers[ "secondaryWeapon" ]
	   )
	{
		player processChallenge( "ch_wiseguy" );
	}
	
	// OP_IW6 Meticulous: kill 4 or more enemies in one clip
	// riot shield?
	if ( !maps\mp\gametypes\_weapons::isOffhandWeapon( data.sWeapon )
	    && data.sMeansOfDeath != "MOD_MELEE"
	   )
	{
		// !!! HACK? - 2013-09-04 wallace: killsThisMag should be created on each spawn, but it seems like sometimes it gets missed?
		if ( !IsDefined( player.killsThisMag ) )
		{
			player.killsThisMag = [];
		}
		
		if ( IsDefined( player.killsThisMag[ data.sWeapon ] ) )
		{
			player.killsThisMag[ data.sWeapon ]++;
			
			if ( isNumberMultipleOf( player.killsThisMag[ data.sWeapon ], 4 ) )
			{
				player processChallenge( "ch_meticulous" );
			}
		}
		else
		{
			player.killsThisMag[ data.sWeapon ] = 1;
		}
	}
	
	// OP_IW6 Can't See Me: kill an enemy while enemy Oracle is up
	cantSeeMeCompleted = false;
	if ( level.teamBased )
	{
		cantSeeMeCompleted = level.activeUAVs[ getOtherTeam( player.team ) ] > 0;
	}
	else
	{
		// only if the victim had oracle up
		cantSeeMeCompleted = level.activeUAVs[ victim.guid ] > 0;
	}
	if ( cantSeeMeCompleted )
		player processChallenge( "ch_youcantseeme" );
	
	// OP_IW6 Incog allow non-bullet kills
	if ( player shouldProcessChallengeForPerk( "specialty_incog" ) )
		player processChallenge( "ch_incog" );
	
	// OP_IW6 BlindEye special case for heli sniper, since you're actually killing a dude
	if ( IsDefined( level.lbSniper ) && IsDefined( level.lbSniper.owner ) && level.lbSniper.owner == victim 
	    && shouldProcessChallengeForPerk( "specialty_blindeye" )
	   )
	{
		self processChallenge( "ch_blindeye_pro" );
	}		
	
	// 2013-09-05 wallace: stop processing weapon challenges if the wapon is unknown
	if ( data.sWeapon == "none" )
	{
		if ( IsDefined( data.victim.explosiveInfo ) && IsDefined( data.victim.explosiveInfo["weapon"] ) )
			data.sWeapon = data.victim.explosiveInfo["weapon"];
		else
	   return;
	}
	
	// !!!! 2013-08-21 Lots of things use the base weapon, so let's just get it once
	baseWeapon = getBaseWeaponName( data.sWeapon );
	weaponClass = getWeaponClass( data.sWeapon );
	if ( data.sMeansOfDeath == "MOD_PISTOL_BULLET" || data.sMeansOfDeath == "MOD_RIFLE_BULLET" || data.sMeansOfDeath == "MOD_HEAD_SHOT" )
	{
		ch_bulletDamageCommon( data, player, time, weaponClass );
	
		if ( weaponClass == "weapon_mg" )
		{
			player MGKill();
		}
		else
		{
			switch ( weaponClass )
			{
				// OP_IW6 Weapon camo challenges
				// in IW5, we also had ch_expert_X for headshots
				case "weapon_smg":
					player processWeaponClassChallenge_SMG( baseWeapon, data );	
					break;
				case "weapon_assault":
					player processWeaponClassChallenge_AR( baseWeapon, data );
					break;
				case "weapon_shotgun":
					player processWeaponClassChallenge_Shotgun( baseWeapon, data );
					break;
				case "weapon_dmr":
					player processWeaponClassChallenge_DMR( baseWeapon, data );
					break;
				case "weapon_sniper":
					player processWeaponClassChallenge_Sniper( baseWeapon, data );
					
					break;
				case "weapon_pistol":
					player processChallenge( "ch_handgun_kill" );
					
					// OP_IW6 Clueless - get kills with magnum with akimbo and acog
					if ( baseWeapon == "iw6_magnum" )
					{
						weaponAttachments = getWeaponAttachmentsBaseNames( data.sWeapon );
						attachCounter = 0;
						foreach ( attachment in weaponAttachments )
						{
							if ( attachment == "acog" )
								attachCounter++;
							else if ( attachment == "akimbo" )
								attachCounter++;
						}
						
						if ( weaponAttachments.size == 2 && attachCounter == 2 )
							player processChallenge( "ch_noidea" );
					}
					
					// OP_IW6 - check if last weapon was riotshield, and how recently we swapped
					if ( player checkWasLastWeaponRiotShield()
					    && IsDefined( player.lastPrimaryWeaponSwapTime ) 
					    && ( GetTime() - player.lastPrimaryWeaponSwapTime ) < OP_RIOTSHIELD_PISTOLKILL_SWAPTIME )
					{
						player processChallenge( "ch_iw6_riotshield_pistol" );
					}
					break;
				case "weapon_lmg":
					player processWeaponClassChallenge_LMG( baseWeapon, data );
					break;
				default:
					break;
			}
			
			if ( data.sMeansOfDeath == "MOD_HEAD_SHOT" )
			{
				if ( isDefined( data.modifiers["revenge"] ) )
					player processChallenge( "ch_colorofmoney" );
				
				if ( isStrStart( data.sWeapon, "frag_" ) )
				{
					player processChallenge( "ch_thinkfast" );
				}
				else if ( isStrStart( data.sWeapon, "concussion_" ) )
				{
					player processChallenge( "ch_thinkfastconcussion" );
				}
				else if ( isStrStart( data.sWeapon, "flash_" ) )
				{
					player processChallenge( "ch_thinkfastflash" );
				}
			}
		}
	}
	else if ( isSubStr( data.sMeansOfDeath, "MOD_GRENADE" ) || isSubStr( data.sMeansOfDeath, "MOD_EXPLOSIVE" ) || isSubStr( data.sMeansOfDeath, "MOD_PROJECTILE" ) )
	{
		if ( isStrStart( data.sWeapon, "frag_grenade_short" ) && ( !isDefined( data.victim.explosiveInfo["throwbackKill"] ) || !data.victim.explosiveInfo["throwbackKill"] ) )
			player processChallenge( "ch_martyr" );

		// this isdefined check should not be needed... find out where these mystery explosions are coming from
		if ( isDefined( data.victim.explosiveInfo["damageTime"] ) && data.victim.explosiveInfo["damageTime"] == time )
		{
			expId = time + "_" + data.victim.explosiveInfo["damageId"];
			if ( !isDefined( player.explosiveKills[expId] ) )
			{
				player.explosiveKills[expId] = 0;
			}
			player thread clearIDShortly( expId );
			
			player.explosiveKills[expId]++;
			
			weaponAttachments = getWeaponAttachmentsBaseNames( data.sWeapon );
			foreach( weaponAttachment in weaponAttachments )
			{
				switch ( weaponAttachment )
				{
				case "gl":
					if( isStrStart( data.sWeapon, "alt_" ) )
						player processWeaponAttachmentChallenge( baseWeapon, weaponAttachment );
					continue;
				}
			}
			
			if ( isDefined( data.victim.explosiveInfo["stickKill"] ) && data.victim.explosiveInfo["stickKill"] )
			{
				if ( isDefined( data.modifiers["revenge"] ) ) 
					player processChallenge( "ch_overdraft" );				

				if ( player.explosiveKills[expId] > 1 )
					player processChallenge( "ch_grouphug" );
			}

			if ( isDefined( data.victim.explosiveInfo["stickFriendlyKill"] ) && data.victim.explosiveInfo["stickFriendlyKill"] )
			{
				player processChallenge( "ch_resourceful" );
			}
			
			// OP_IW6 - THROW AWAY: this was supposed to be for mortars, but the fuse is too short
			// so, generalize to all grenades?
			if ( data.victim.explosiveInfo["throwbackKill"] )
			{
				player processChallenge( "ch_throwaway" );
			}
			
			if ( isStrStart( data.sWeapon, "frag_" ) )
			{
				if ( player.explosiveKills[expId] > 1 )
					player processChallenge( "ch_multifrag" );
	
				if ( isDefined( data.modifiers["revenge"] ) ) 
					player processChallenge( "ch_bangforbuck" );				
				
				player processChallenge( "ch_grenadekill" );
				
				if ( data.victim.explosiveInfo["cookedKill"] )
					player processChallenge( "ch_masterchef" );
				
				if ( data.victim.explosiveInfo["suicideGrenadeKill"] )
					player processChallenge( "ch_miserylovescompany" );
				
				if ( data.victim.explosiveInfo["throwbackKill"] )
				{
					player processChallenge( "ch_hotpotato" );
				}
			}
			else if ( isStrStart( data.sWeapon, "semtex" ) || data.sWeapon == "iw6_mk32_mp" )	// checks for both semtex_mp and semtexproj_mp as well as mk32 directly
			{
				if ( isDefined( data.modifiers["revenge"] ) ) 
					player processChallenge( "ch_timeismoney" );
				
				// OP_IW6
				if ( isDefined( data.victim.explosiveInfo["stickKill"] ) && data.victim.explosiveInfo["stickKill"] )
					player processChallenge( "ch_plastered" );
				
				data.victim.stuckByGrenade = undefined;
			}
			else if ( isStrStart( data.sWeapon, "c4_" ) )
			{
				if ( isDefined( data.modifiers["revenge"] ) ) 
					player processChallenge( "ch_iamrich" );				

				if ( player.explosiveKills[expId] > 1 )
					player processChallenge( "ch_multic4" );

				if ( data.victim.explosiveInfo["returnToSender"] )
					player processChallenge( "ch_returntosender" );				
				
				if ( data.victim.explosiveInfo["counterKill"] )
					player processChallenge( "ch_counterc4" );
				
				if ( IsDefined( data.victim.explosiveInfo["bulletPenetrationKill"] ) && data.victim.explosiveInfo["bulletPenetrationKill"] )
					player processChallenge( "ch_howthe" );

				if ( data.victim.explosiveInfo["chainKill"] )
					player processChallenge( "ch_dominos" );

				player processChallenge( "ch_c4shot" );
				
				// OP_IW6 Riotshield camo challenge
				if ( player checkWasLastWeaponRiotShield() )
				{
					player processChallenge( "ch_iw6_riotshield_c4" );
				}
			}
			else if ( isStrStart( data.sWeapon, "proximity_explosive_" ) )
			{
				player processChallenge( "ch_proximityexplosive" );
				
				if ( isDefined( data.modifiers["revenge"] ) )
					player processChallenge( "ch_breakbank" );
				
				if ( data.victim.explosiveInfo["chainKill"] )
					player processChallenge( "ch_dominos" );
			}
			else if ( isStrStart( data.sWeapon, "mortar_shell_" ) )
			{
				player processChallenge( "ch_mortarshell" );
			}
			// No claymores / bettys in IW6
			/*
			else if ( isStrStart( data.sWeapon, "claymore_" ) )
			{
				if ( isDefined( data.modifiers["revenge"] ) ) 
					player processChallenge( "ch_breakbank" );				

				player processChallenge( "ch_claymoreshot" );

				if ( player.explosiveKills[expId] > 1 )
					player processChallenge( "ch_multiclaymore" );

				if ( data.victim.explosiveInfo["returnToSender"] )
					player processChallenge( "ch_returntosender" );				

				if ( data.victim.explosiveInfo["counterKill"] )
					player processChallenge( "ch_counterclaymore" );
				
				if ( IsDefined( data.victim.explosiveInfo["bulletPenetrationKill"] ) && data.victim.explosiveInfo["bulletPenetrationKill"] )
					player processChallenge( "ch_howthe" );

				if ( data.victim.explosiveInfo["chainKill"] )
					player processChallenge( "ch_dominos" );
			}
			else if ( isStrStart( data.sWeapon, "bouncingbetty_" ) )
			{
				player processChallenge( "ch_bouncingbetty" );
			}
			*/
			else if ( data.sWeapon == "explodable_barrel" )
			{
				//player processChallenge( "ch_redbarrelsurprise" );
			}
			else if ( data.sWeapon == "destructible_car" )
			{
				player processChallenge( "ch_carbomb" );
			}
			else if ( maps\mp\gametypes\_weapons::isRocketLauncher( data.sWeapon ) )
			{
				rpgKills = player.explosiveKills[expId];
				if ( isNumberMultipleOf( rpgKills, 2 ) )
					player processChallenge( "ch_multirpg" );
			}
			
			// OP_IW6 Danger Close
			if ( player shouldProcessChallengeForPerk( "specialty_explosivedamage" ) )
			{
				player processChallenge( "ch_explosivedamage" );
			}
			
			// OP_IW6 Extra Lethal - check if the 2nd grenade was used to kill
			// is there a way to restock lethals?
			player checkChallengeExtraDeadly( data.sWeapon );
		}
	}
	else if ( isSubStr( data.sMeansOfDeath,	"MOD_MELEE" ) && !maps\mp\gametypes\_weapons::isRiotShield( data.sWeapon ) )
	{
		player endMGStreak();
		
		player processChallenge( "ch_knifevet" );
		player.pers["meleeKillStreak"]++;

		if ( player.pers["meleeKillStreak"] == 3 )
			player processChallenge( "ch_slasher" );
		
		if ( player IsItemUnlocked( "specialty_quieter" ) && player _hasPerk( "specialty_quieter" ) )
			player processChallenge( "ch_deadsilence_pro" );
		
		vAngles = data.victim.anglesOnDeath[1];
		pAngles = player.anglesOnKill[1];
		angleDiff = AngleClamp180( vAngles - pAngles );
		if ( abs(angleDiff) < 30 )
		{
			player processChallenge( "ch_backstabber" );
			
			if ( isDefined( player.attackers ) )
			{
				foreach ( attacker in player.attackers )
				{
					if ( !IsDefined( _validateAttacker( attacker ) ) )
					    continue;
					    
					if ( attacker != data.victim )
						continue;
						
					player processChallenge( "ch_neverforget" );
					break;
				}
			}
		}
		// stop iw6_knifeonly from processing no ammo challenge
		if ( !player playerHasAmmo() && baseWeapon != "iw6_knifeonly" && baseWeapon != "iw6_knifeonlyfast" && baseWeapon != "iw6_knifeonlyjugg" )
			player processChallenge( "ch_survivor" );
			
		if ( isDefined( player.infected ) )
			data.victim processChallenge( "ch_infected" );

		if ( isDefined( data.victim.plague ) )
			player processChallenge( "ch_plague" );
		
		// OP_IW6 Smooth Moves: knife an enemy while sliding
		// would be nice to have other sliding challenges?
		if ( player playerIsSprintSliding() )
		{
			player processChallenge( "ch_smooth_moves" );
		}
		
		weaponAttachments = getWeaponAttachmentsBaseNames( data.sWeapon );
		foreach( weaponAttachment in weaponAttachments )
		{
			switch ( weaponAttachment )
			{
			case "tactical":
				player processWeaponAttachmentChallenge( baseWeapon, weaponAttachment );
				continue;
			}
		}
		
		// OP_IW6 Balls of Steel: kill without primary or second.
		if ( player.weaponList.size == 1
		    && ( player.weaponList[0] == "iw6_knifeonly_mp" || player.weaponList[0] == "iw6_knifeonlyfast_mp" )
		   )
		{
			player processChallenge( "ch_ballsofsteel" );
		}
		
		// OP_IW6 Bigfoot - kill an enemy in full ghillie suit with a knife
		if ( checkCostumeChallenge( victim, "mp_fullbody_sniper_ab" ) )
		{
			player processChallenge( "ch_bigfoot" );
		}
	}
	else if ( maps\mp\gametypes\_weapons::isRiotShield( data.sWeapon ) )
	{
		if ( isSubStr( data.sMeansOfDeath,	"MOD_MELEE" ) )
		{
			player endMGStreak();
			
			player processChallenge( "ch_shieldvet" );
			player.pers["shieldKillStreak"]++;
			
			//IW5 daily/weekly
			player processChallenge( "ch_riot_kill" );
			
			vAngles = data.victim.anglesOnDeath[1];
			pAngles = player.anglesOnKill[1];
			angleDiff = AngleClamp180( vAngles - pAngles );
			if ( abs(angleDiff) < 30 )
				player processChallenge( "ch_iw6_riotshield_backsmasher" );	
	
			if ( !player playerHasAmmo() )
				player processChallenge( "ch_survivor" );
			
			// OP_IW6 Weapon Camo challenge
			player processWeaponClassChallenge_RiotShield( baseWeapon, data );
		}
		
		weaponAttachments = getWeaponAttachmentsBaseNames( data.sWeapon );
		foreach( weaponAttachment in weaponAttachments )
		{
			switch ( weaponAttachment )
			{
			case "rshieldradar":
			case "rshieldscrambler":
			case "rshieldspikes":
				player processWeaponAttachmentChallenge( baseWeapon, weaponAttachment );
				break;
			}
		}
	}
	else if ( isSubStr( data.sMeansOfDeath,	"MOD_IMPACT" ) )
	{
		if ( isStrStart( data.sWeapon, "frag_" ) )
			player processChallenge( "ch_thinkfast" );
		else if ( isStrStart( data.sWeapon, "concussion_" ) )
			player processChallenge( "ch_thinkfastconcussion" );
		else if ( isStrStart( data.sWeapon, "flash_" ) )
			player processChallenge( "ch_thinkfastflash" );

		if ( maps\mp\gametypes\_weapons::isThrowingKnife( data.sWeapon ) )
		{
			if ( isDefined( data.modifiers["revenge"] ) )
				player processChallenge( "ch_atm" );
				
			player processChallenge( "ch_carnie" );
			
			if ( isDefined( data.victim.attackerData[player.guid] ) )
				player processChallenge( "ch_its_personal" );

			if( player IsItemUnlocked( "specialty_fastoffhand" ) && player _hasPerk( "specialty_fastoffhand" ) )
				player processChallenge( "ch_fastoffhand" );
			
			// OP_iw6 riotshield camo challenge
			if ( player checkWasLastWeaponRiotShield() )
			{
				player processChallenge( "ch_iw6_riotshield_throwingknife" );
			}
			
			// OP_iw6 Extra Deadly - also have to check throwing knives
			player checkChallengeExtraDeadly( data.sWeapon );
		}
		
		weaponAttachments = getWeaponAttachmentsBaseNames( data.sWeapon );
		foreach( weaponAttachment in weaponAttachments )
		{
			switch ( weaponAttachment )
			{
			case "gl":
				if( isStrStart( data.sWeapon, "alt_" ) )
				{
					player processWeaponAttachmentChallenge( baseWeapon, weaponAttachment );
					player processChallenge( "ch_ouch" );
				}
				continue;
			}
		}
	}
	
	if( ( data.sMeansOfDeath == "MOD_PISTOL_BULLET" || data.sMeansOfDeath == "MOD_RIFLE_BULLET" || data.sMeansOfDeath == "MOD_HEAD_SHOT" ) && 
		!isKillstreakWeapon( data.sWeapon ) && 
		!isEnvironmentWeapon( data.sWeapon )
		)
	{
		// checks and processes all weapon attachment challenges
		weaponAttachments = getWeaponAttachmentsBaseNames( data.sWeapon );
		foreach( weaponAttachment in weaponAttachments )
		{		
			switch ( weaponAttachment )
			{
			// sights
			case "acog":
				player processWeaponAttachmentChallenge_Acog( baseWeapon, weaponAttachment, data );
				break;
			case "eotech":
				player processWeaponAttachmentChallenge_EOTech( baseWeapon, weaponAttachment, data );
				break;
			case "hybrid":
				player processWeaponAttachmentChallenge_Hybrid( baseWeapon, weaponAttachment, data );
				break;
			case "reflex":
				player processWeaponAttachmentChallenge_Reflex( baseWeapon, weaponAttachment, data );
				break;
			case "ironsight":
			case "thermal":
			case "tracker":
			case "vzscope":
			case "scope":
				if ( player isPlayerAds() )
					player processWeaponAttachmentChallenge( baseWeapon, weaponAttachment );
				break;
			// other
			case "akimbo":
			case "ammoslug":
			case "barrelbored":
			case "barrelrange":
			case "firetypeauto":
			case "firetypeburst":
			case "firetypesingle":
			case "flashsuppress":
			case "grip":
			case "rof":
			case "silencer":
			case "xmags":	
				player processWeaponAttachmentChallenge( baseWeapon, weaponAttachment );
				break;
			// alt fire
			case "gl":
			case "shotgun":
				if( isStrStart( data.sWeapon, "alt_" ) )
					player processWeaponAttachmentChallenge( baseWeapon, weaponAttachment );
				continue;
			case "fmj":
				// OP_IW6: should rename this to be ch_fmj
				player processChallenge( "ch_armorpiercing" );
				break;
			default:
				break;					
			}
		}
		
		// Handle weapons with integrated attachments
		if ( weaponHasIntegratedFireTypeBurst( data.sWeapon ) )
		{
			player processWeaponAttachmentChallenge( baseWeapon, "firetypeburst" );
		}
		
		if ( weaponHasIntegratedSilencer( baseWeapon ) )
		{
			player processWeaponAttachmentChallenge( baseWeapon, "silencer" );
		}
		
		if ( weaponHasIntegratedGrip( baseWeapon ) )
		{
			player processWeaponAttachmentChallenge( baseWeapon, "grip" );
		}
		
		if ( weaponHasIntegratedFMJ( baseWeapon ) )
		{
			player processWeaponAttachmentChallenge( baseWeapon, "fmj" );
		}
		
		// 2014-01-29 wallace: maverick sniper has built in tracker for its scopes
		if ( player isPlayerAds() && weaponHasIntegratedTrackerScope( data.sWeapon ) )
		{
			player processWeaponAttachmentChallenge( baseWeapon, "tracker" ); 
		}
		
		// if the gun is naked
		numDefaultAttachments = getNumDefaultAttachments( data.sWeapon );
		if ( weaponAttachments.size == numDefaultAttachments )
		{
			player processChallenge( "ch_noattachments" );
		}
		
		if ( player shouldProcessChallengeForPerk( "specialty_bulletaccuracy" ) && !player isPlayerAds() )
			player processChallenge( "ch_bulletaccuracy_pro" );
		
		if ( player shouldProcessChallengeForPerk( "specialty_stalker" ) && player isPlayerAds() )
			player processChallenge( "ch_stalker_pro" );

		if ( distanceSquared( player.origin, data.victim.origin ) < 65536 )// 256^2 
		{
			if ( player shouldProcessChallengeForPerk( "specialty_quieter" ) )
				player processChallenge( "ch_deadsilence_pro" );
		}
		
		if ( player shouldProcessChallengeForPerk( "specialty_fastreload" ) 
		    && player hasReloadedRecently()
		   )
		{
			player processChallenge( "ch_sleightofhand_pro" );
		}
		
		// OP_IW6 Focus - kill an enemy while being shot at
		if ( player shouldProcessChallengeForPerk( "specialty_sharp_focus" ) )
		{
			if ( IsDefined( player.attackers ) && player.attackers.size > 0 )
			{
				player processChallenge( "ch_sharp_focus" );
			}
		}
		
		/*if ( player isBuffUnlockedForWeapon( "specialty_marksman", baseWeapon ) && player isBuffEquippedOnWeapon( "specialty_marksman", baseWeapon ) && player _hasPerk( "specialty_marksman" ) && player PlayerAds() )
			player processChallenge( "ch_kickstop" );

		if ( data.victim.iDFlagsTime == time )
		{
			if ( data.victim.iDFlags & level.iDFLAGS_PENETRATION )
			{
				//if( player isBuffUnlockedForWeapon( "specialty_bulletpenetration", baseWeapon ) && player isBuffEquippedOnWeapon( "specialty_bulletpenetration", baseWeapon ) && player _hasPerk( "specialty_bulletpenetration" ) )
				//	player processChallenge( "ch_xrayvision" ); 
			}
		}

		if( player isBuffUnlockedForWeapon( "specialty_holdbreathwhileads", baseWeapon ) && player isBuffEquippedOnWeapon( "specialty_holdbreathwhileads", baseWeapon ) && player _hasPerk( "specialty_holdbreathwhileads" ) && ( player.holdingBreath && player PlayerAds() ) )
			player processChallenge( "ch_holditrightthere" );

		if( player isBuffUnlockedForWeapon( "specialty_reducedsway", baseWeapon ) && player isBuffEquippedOnWeapon( "specialty_reducedsway", baseWeapon ) && player _hasPerk( "specialty_reducedsway" ) && player PlayerAds() )
			player processChallenge( "ch_swayless" );

		if( player isBuffUnlockedForWeapon( "specialty_longerrange", baseWeapon ) && player isBuffEquippedOnWeapon( "specialty_longerrange", baseWeapon ) && player _hasPerk( "specialty_longerrange" ) )
			player processChallenge( "ch_longishshot" );

		if( player isBuffUnlockedForWeapon( "specialty_moredamage", baseWeapon ) && player isBuffEquippedOnWeapon( "specialty_moredamage", baseWeapon ) && player _hasPerk( "specialty_moredamage" ) )
			player processChallenge( "ch_moredamage" );
			
		*/
	}
	
	if( player IsItemUnlocked( "specialty_quickdraw" ) && player _hasPerk( "specialty_quickdraw" ) && ( player.adsTime > 0 && player.adsTime < 3 ) )
		player processChallenge( "ch_quickdraw_pro" );		

	if( player IsItemUnlocked( "specialty_empimmune" ) && player _hasPerk( "specialty_empimmune" ) )
	{
		if( level.teambased )
		{
			cuavUp = false;
			foreach( cuav in level.uavmodels[ getOtherTeam( player.team ) ] )
			{
				if( cuav.uavType != "counter" )
					continue;

				cuavUp = true;
				break;
			}	
			if( cuavUp || player isEMPed() )
				player processChallenge( "ch_spygame" );		
		}
		else
		{
			// enemy cuav or emp is up
			if( player.isRadarBlocked || player isEMPed() )
			{
				player processChallenge( "ch_spygame" );
			}
		}
	}

	if ( isDefined( data.victim.isPlanting ) && data.victim.isPlanting )
		player processChallenge( "ch_bombplanter" );		

	if ( isDefined( data.victim.isDefusing ) && data.victim.isDefusing )
		player processChallenge( "ch_bombdefender" );

	if ( isDefined( data.victim.isBombCarrier ) && data.victim.isBombCarrier && ( !isDefined( level.dd ) || !level.dd ) )
		player processChallenge( "ch_bombdown" );

	if ( isDefined( data.victim.wasTI ) && data.victim.wasTI )
		player processChallenge( "ch_tacticaldeletion" );
		
	if( player IsItemUnlocked( "specialty_quickswap" ) && player _hasPerk( "specialty_quickswap" ) )
	{
		if( IsDefined( player.lastPrimaryWeaponSwapTime ) && ( GetTime() - player.lastPrimaryWeaponSwapTime ) < 3000 )
			player processChallenge( "ch_quickswap" );
	}

	if( player IsItemUnlocked( "specialty_extraammo" ) && player _hasPerk( "specialty_extraammo" ) )
		player processChallenge( "ch_extraammo" );

	if( IsExplosiveDamageMOD( data.sMeansOfDeath ) )
	{
		switch( data.sWeapon )
		{
		case "frag_grenade_mp":
		case "semtex_mp":
		case "flash_grenade_mp":
		case "concussion_grenade_mp":
		case "emp_grenade_mp":
		case "thermobaric_grenade_mp":
		case "mortar_shell_mp":
			if( player IsItemUnlocked( "specialty_fastoffhand" ) && player _hasPerk( "specialty_fastoffhand" ) )
				player processChallenge( "ch_fastoffhand" );
			break;
		}
		
		// OP_IW6 Kill enemies weakened by thermo
		if ( isDefined( victim.thermoDebuffed ) && victim.thermoDebuffed )
			player processChallenge( "ch_thermobaric" );
	}

	if ( player IsItemUnlocked( "specialty_overkillpro" ) && player _hasPerk( "specialty_overkillpro" ) )
	{
		if( player.secondaryWeapon == data.sWeapon )
		{
			weaponAttachments = getWeaponAttachments( data.sWeapon );
			if( weaponAttachments.size > 0 )
				player processChallenge( "ch_secondprimary" );
		}
	}

	if( player IsItemUnlocked( "specialty_stun_resistance" ) && player _hasPerk( "specialty_stun_resistance" ) )
	{
		if( IsDefined( player.lastFlashedTime ) && ( GetTime() - player.lastFlashedTime ) < 5000 )
			player processChallenge( "ch_stunresistance" );
		else if( IsDefined( player.lastConcussedTime ) && ( GetTime() - player.lastConcussedTime ) < 5000 )
			player processChallenge( "ch_stunresistance" );
	}

	if( player IsItemUnlocked( "specialty_selectivehearing" ) && player _hasPerk( "specialty_selectivehearing" ) )
		player processChallenge( "ch_selectivehearing" );

	if( player IsItemUnlocked( "specialty_fastsprintrecovery" ) && player _hasPerk( "specialty_fastsprintrecovery" ) )
	{
		if( IsDefined( player.lastSprintEndTime ) && ( GetTime() - player.lastSprintEndTime ) < 3000 )
			player processChallenge( "ch_fastsprintrecovery" );
	}
}

ch_bulletDamageCommon( data, player, time, weaponClass )
{
	if ( !isEnvironmentWeapon( data.sWeapon ) )
		player endMGStreak();
		
	if ( isKillstreakWeapon( data.sWeapon ) )
		return;
	
	if ( player.pers["lastBulletKillTime"] == time )
		player.pers["bulletStreak"]++;
	else
		player.pers["bulletStreak"] = 1;
	
	player.pers["lastBulletKillTime"] = time;

	if ( !data.victimOnGround )
		player processChallenge( "ch_hardlanding" );
	
	assert( data.attacker == player );
	if ( !data.attackerOnGround )
		player.pers["midairStreak"]++;
	
	if ( player.pers["midairStreak"] == 2 )
		player processChallenge( "ch_airborne" );
	
	if ( time < data.victim.flashEndTime )
		player processChallenge( "ch_flashbangvet" );
	
	if ( time < player.flashEndTime )
		player processChallenge( "ch_blindfire" );
	
	if ( time < data.victim.concussionEndTime )
		player processChallenge( "ch_concussionvet" );
	
	if ( time < player.concussionEndTime )
		player processChallenge( "ch_slowbutsure" );
	
	
	if ( player.pers["bulletStreak"] == 2  )
	{
		if ( isDefined( data.modifiers["headshot"] ) )
		{
			foreach ( killData in player.killsThisLife )
			{
				if ( killData.time != time )
					continue;
					
				if ( !isDefined( data.modifiers["headshot"] ) )
					continue;
					
				player processChallenge( "ch_allpro" );
			}
		}

		if ( weaponClass == "weapon_sniper" )
			player processChallenge( "ch_collateraldamage" );
	}
	
	if ( weaponClass == "weapon_pistol" )
	{
		if ( isdefined( data.victim.attackerData ) && isdefined( data.victim.attackerData[player.guid] ) )
		{
			if ( isDefined ( data.victim.attackerData[player.guid].isPrimary ) )
				player processChallenge( "ch_fastswap" );
		}
	}
	
if( !IsDefined( player.inFinalStand ) || !player.inFinalStand )
	{
		if ( data.attackerStance == "crouch" )
		{
			player processChallenge( "ch_crouchshot" );
		}
		else if ( data.attackerStance == "prone" )
		{
			player processChallenge( "ch_proneshot" );
			if ( weaponClass == "weapon_sniper" )
			{
				player processChallenge( "ch_invisible" );
			}
		}
	}
	
	/*
	if ( weaponClass == "weapon_sniper" )
	{
		if ( isDefined( data.modifiers["oneshotkill"] ) )
			player processChallenge( "ch_ghillie" );	
	}
	*/
	
	if ( isSubStr( data.sWeapon, "silencer" ) )
		player processChallenge( "ch_stealthvet" ); 
}

ch_roundplayed( data )
{
	player = data.player;
	
	if ( player.wasAliveAtMatchStart )
	{
		deaths = player.pers[ "deaths" ];
		kills = player.pers[ "kills" ];

		kdratio = 1000000;
		if ( deaths > 0 )
			kdratio = kills / deaths;
		
		if ( kdratio >= 5.0 && kills >= 5.0 )
		{
			player processChallenge( "ch_starplayer" );
		}
		
		if ( deaths == 0 && getTimePassed() > 5 * 60 * 1000 )
			player processChallenge( "ch_flawless" );
		
		//not enough players to count as winning
		if ( level.placement["all"].size < 3 )
			return;
			
		if ( player.score > 0 )
		{
			switch ( level.gameType )
			{
				case "dm":
				case "gun":
					if ( data.place < 3 )
					{
						player processChallenge( "ch_victor_dm" );	
						player processChallenge( "ch_hunted_victor" );
					}
					// would put "games played" challenges in here.
					// player processChallenge( "ch_ffa_participate" );	
					break;
				case "sotf_ffa":
					if ( data.place < 3 )
					{
						player processChallenge( "ch_hunted_victor" );	
					}
					break;					
			}
		}
	}
}


ch_roundwin( data )
{
	if ( !data.winner )
		return;
		
	player = data.player;
	if ( player.wasAliveAtMatchStart )
	{
		switch ( level.gameType )
		{
			case "war":
				if ( level.hardcoreMode )
				{
					player processChallenge( "ch_teamplayer_hc" );
					if ( data.place == 0 )
						player processChallenge( "ch_mvp_thc" );
				}
				else
				{
					player processChallenge( "ch_teamplayer" );
					// OP_IW6 TDM skills place in top 3 of TDM
					// change from mw3, tdm_mvp - be 1st in tdm
					if ( data.place <= 2 )
					{
						player processChallenge( "ch_tdmskills" );
						if ( data.place == 0 )
							player processChallenge( "ch_mvp_tdm" );
					}
				}
				break;
			case "blitz":
				player processChallenge( "ch_blitz_victor" );
				break;
			case "cranked":
				player processChallenge( "ch_crank_victor" );
				break;
			case "dom":
				player processChallenge( "ch_dom_victor" );
				break;
			case "grind":
				player processChallenge( "ch_grind_victor" );
				break;
			case "infect":
				if ( player.team == "allies" )
				{
					player processChallenge( "ch_alive" );
				}
				
				player processChallenge( "ch_infected" );
					
				break;
			case "sd":
				player processChallenge( "ch_victor_sd" );
				break;
			case "sr":
				player processChallenge( "ch_sr_victor" );
				break;
			case "conf":
				player processChallenge( "ch_conf_victor" );
				break;
			case "dm":
			case "koth":
			case "sotf_ffa":
			case "gun":
				break;
			default:
				break;
		}
		
		playlistType = GetDvarInt( "scr_playlist_type", 0 );
		if ( playlistType == 1 )
		{
			// clan match
			player processChallenge( "ch_bromance" );
			
			// Also count clan matches towards Team Tactical challenges for PC, since that game mode is removed.
			if ( !level.console )
				player processChallenge( "ch_tactician" );
		}
		else if ( playlistType == 2 )
		{
			// team tactical match
			player processChallenge( "ch_tactician" );
		}
		
		if ( level.hardcoreMode )
		{
			player processChallenge( "ch_hardcore_extreme" );
		}
	}
}

/*
char *modNames[MOD_NUM] =
{
	"MOD_UNKNOWN",
	"MOD_PISTOL_BULLET",
	"MOD_RIFLE_BULLET",
	"MOD_GRENADE",
	"MOD_GRENADE_SPLASH",
	"MOD_PROJECTILE",
	"MOD_PROJECTILE_SPLASH",
	"MOD_MELEE",
	"MOD_HEAD_SHOT",
	"MOD_MELEE_DOG",
	"MOD_MELEE_ALIEN",
	"MOD_CRUSH",
	"MOD_TELEFRAG",
	"MOD_FALLING",
	"MOD_SUICIDE",
	"MOD_TRIGGER_HURT",
	"MOD_EXPLOSIVE",
	"MOD_IMPACT",
};

static const char *g_HitLocNames[] =
{
	"none",
	"helmet",
	"head",
	"neck",
	"torso_upper",
	"torso_lower",
	"right_arm_upper",
	"left_arm_upper",
	"right_arm_lower",
	"left_arm_lower",
	"right_hand",
	"left_hand",
	"right_leg_upper",
	"left_leg_upper",
	"right_leg_lower",
	"left_leg_lower",
	"right_foot",
	"left_foot",
	"gun",
};

*/

// ==========================================
// Callback functions

playerDamaged( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sHitLoc )
{
	if ( is_aliens() )
		return;
	else
		playerDamaged_regularMP( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sHitLoc );
}

playerDamaged_regularMP( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sHitLoc )
{
	if ( !isPlayer( self ) )
		return;

	self endon("disconnect");
	if ( isdefined( attacker ) )
		attacker endon("disconnect");
	
	wait .05;
	WaitTillSlowProcessAllowed();

	data = spawnstruct();

	data.victim = self;
	data.eInflictor = eInflictor;
	data.attacker = attacker;
	data.iDamage = iDamage;
	data.sMeansOfDeath = sMeansOfDeath;
	data.sWeapon = sWeapon;
	data.sHitLoc = sHitLoc;
	
	data.victimOnGround = data.victim isOnGround();
	
	if ( isPlayer( attacker ) )
	{
		data.attackerInLastStand = isDefined( data.attacker.lastStand );
		data.attackerOnGround = data.attacker isOnGround();
		data.attackerStance = data.attacker getStance();
	}
	else
	{
		data.attackerInLastStand = false;
		data.attackerOnGround = false;
		data.attackerStance = "stand";
	}
	
	doMissionCallback("playerDamaged", data);
}

playerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sPrimaryWeapon, sHitLoc, modifiers )
{
	if ( is_aliens() )
		return;
	else
		playerKilled_regularMP( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sPrimaryWeapon, sHitLoc, modifiers );
}

playerKilled_regularMP( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, sPrimaryWeapon, sHitLoc, modifiers )
{
	if ( self isUsingRemote() )
		self.anglesOnDeath = self.angles;
	else
	self.anglesOnDeath = self getPlayerAngles();
	if ( isdefined( attacker ) )
		attacker.anglesOnKill = attacker getPlayerAngles();
	
	self endon("disconnect");

	data = spawnstruct();

	data.victim = self;
	data.eInflictor = eInflictor;
	data.attacker = attacker;
	data.iDamage = iDamage;
	data.sMeansOfDeath = sMeansOfDeath;
	data.sWeapon = sWeapon;
	data.sPrimaryWeapon = sPrimaryWeapon;
	data.sHitLoc = sHitLoc;
	data.time = gettime();
	data.modifiers = modifiers;
	// 2013-09-30 wallace: cache the state of the attacker's hybrid scope 
	// since the challenge callback may not be called for a few frames, 
	// and the attacker may change weapons or otherwise be in a state where GetHybridScopeState cannot be called 
	if ( IsDefined ( sWeapon ) && IsSubStr( sWeapon, "_hybrid" ) )
	{
		if ( attacker GetCurrentWeapon() == sWeapon )
		{
			data.hybridScopeState = attacker GetHybridScopeState( sWeapon );
		}
		else
		{
			data.hybridScopeState = 0;
		}
	}
	
	data.victimOnGround = data.victim isOnGround();
	
	if ( isPlayer( attacker ) )
	{
		data.attackerInLastStand = isDefined( data.attacker.lastStand );
		data.attackerOnGround = data.attacker isOnGround();
		data.attackerStance = data.attacker getStance();
	}
	else
	{
		data.attackerInLastStand = false;
		data.attackerOnGround = false;
		data.attackerStance = "stand";
	}

	waitAndProcessPlayerKilledCallback( data );
	
	if ( isDefined( attacker ) && isReallyAlive( attacker ) )
	{
		attacker.killsThisLife[attacker.killsThisLife.size] = data;	
	}


	data.attacker notify( "playerKilledChallengesProcessed" );
}


/*
=============
///ScriptDocBegin
"Name: vehicleKilled( <owner>, <vehicle>, <eInflictor>, <attacker>, <iDamage>, <sMeansOfDeath>, <sWeapon> )"
"Summary: !!! DEPRECATED call killstreakKilled instead
"Module: missions"
"CallOn: killstreak entity"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
vehicleKilled( owner, vehicle, eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon )
{
	if ( !is_aliens() )
	{
		killstreakKilled_regularMP( owner, vehicle, eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon );
	}
}

/*
=============
///ScriptDocBegin
"Name: killstreakKilled( <owner>, <vehicle>, <eInflictor>, <attacker>, <iDamage>, <sMeansOfDeath>, <sWeapon> )"
"Summary: award adrenaline, do bookkeeping
"Module: missions"
"CallOn: killstreak entity"
"Example: self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, 100, level.sentrySettings[ self.sentryType ].voDestroyed );
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
killstreakKilled( owner, killedEnt, eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon )
{
	if ( !is_aliens() )
	{
		killstreakKilled_regularMP( owner, killedEnt, eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon );
	}
}

killstreakKilled_regularMP( owner, vehicle, eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon )
{
	// renable this block when we need it for challenges again
	/*
	data = spawnstruct();

	data.vehicle = vehicle;
	data.victim = owner;
	data.eInflictor = eInflictor;
	data.attacker = attacker;
	data.iDamage = iDamage;
	data.sMeansOfDeath = sMeansOfDeath;
	data.sWeapon = sWeapon;
	data.time = gettime();
	*/
	
	if ( IsDefined( attacker ) 
	    && isPlayer( attacker ) 
	    && ( !IsDefined( owner ) || attacker != owner )
	    // only allow killstreaks to kill other killstreaks if they are allowed to chain
	    && attacker killShouldAddToKillstreak( sWeapon )
		)
	{
		attacker maps\mp\killstreaks\_killstreaks::giveAdrenaline( "vehicleDestroyed" );
		
		// there used to be a bunch of processChallenge calls in here
		// lock on weapons, perks
		// which we'll remove for the time being
	}
}


waitAndProcessPlayerKilledCallback( data )
{
	if ( isdefined( data.attacker ) )
		data.attacker endon("disconnect");
	
	self.processingKilledChallenges = true;
	wait 0.05;
	WaitTillSlowProcessAllowed();
	
	doMissionCallback( "playerKilled", data );
	self.processingKilledChallenges = undefined;
}

playerAssist( killedPlayer )
{
	data = spawnstruct();

	data.player = self;
	data.victim = killedPlayer;
	
	attackerData = killedPlayer.attackerData[ self.guid ];
	if ( IsDefined( attackerData ) )
	{
		data.sWeapon = attackerData.weapon;
	}

	doMissionCallback( "playerAssist", data );
}


useHardpoint( hardpointType )
{
	if ( is_aliens() )
		return;
	else
		useHardpoint_regularMP( hardpointType );	
}

useHardpoint_regularMP( hardpointType )
{
	// since this is threaded we need this endon in case they player disconnects, this fixes an sre when calling the ac130 and leaving the game as you are entering it
	self endon( "disconnect" );

	wait .05;
	WaitTillSlowProcessAllowed();

	data = spawnstruct();

	data.player = self;
	data.hardpointType = hardpointType;

	doMissionCallback( "playerHardpoint", data );
}


roundBegin()
{
	doMissionCallback( "roundBegin" );
}

roundEnd( winner )
{
	data = spawnstruct();
	
	if ( level.teamBased )
	{
		team = "allies";
		for ( index = 0; index < level.placement[team].size; index++ )
		{
			data.player = level.placement[team][index];
			data.winner = (team == winner);
			data.place = index;

			doMissionCallback( "roundEnd", data );
		}
		team = "axis";
		for ( index = 0; index < level.placement[team].size; index++ )
		{
			data.player = level.placement[team][index];
			data.winner = (team == winner);
			data.place = index;

			doMissionCallback( "roundEnd", data );
		}
	}
	else
	{
		for ( index = 0; index < level.placement["all"].size; index++ )
		{
			data.player = level.placement["all"][index];
			data.winner = (isdefined( winner ) && isPlayer( winner ) && (data.player == winner));
			data.place = index;

			doMissionCallback( "roundEnd", data );
		}		
	}
}

doMissionCallback( callback, data )
{
	if ( !mayProcessChallenges() )
		return;
	
	// 2013-09-02 wallace: don't let AI  (bots) process challenges
	// this check blocks bots from calling functions set up by registerMissionCallback, instead of having those functions check individually
	if ( IsDefined( data ) )
	{
		// Argh, both data.player AND data.attacker might be used, depending on who's calling the callback
		player = data.player;
		if ( !IsDefined( player ) )
			player = data.attacker;
		
		if ( IsDefined( player ) && IsAI( player ) )
			return;
	}
	
	if ( getDvarInt( "disable_challenges" ) > 0 )
		return;
	
	if ( !isDefined( level.missionCallbacks[callback] ) )
		return;
	
	if ( isDefined( data ) ) 
	{
		for ( i = 0; i < level.missionCallbacks[callback].size; i++ )
			thread [[level.missionCallbacks[callback][i]]]( data );
	}
	else 
	{
		for ( i = 0; i < level.missionCallbacks[callback].size; i++ )
			thread [[level.missionCallbacks[callback][i]]]();
	}
}

CONST_SPRINT_DISTANCE_FACTOR = 120;
monitorSprintDistance()
{
	// 2013-10-01 TODO: perhaps we should not end on death/spawn, because players won't get credit if they die mid-sprint?
	level endon( "game_ended" );
	self endon( "spawned_player" );
	self endon( "death" );
	self endon( "disconnect" );
	
	self.sprintDistThisSprint = 0;
	
	while(1)
	{
		self waittill("sprint_begin");
		
		self thread monitorSprintTime();
		
		// OP_IW6 Marathon perk (not longersprint)
		if ( self _hasPerk( "specialty_marathon" ) )
		{
			self monitorSingleSprintDistance();
			
			roundedSprintDistance = Int( self.sprintDistThisSprint / CONST_SPRINT_DISTANCE_FACTOR );
			// Since we are tracking this progress with coarser granularity (every 10', instead of 1'
			// we'll accumulate the leftover distance			
			self.sprintDistThisSprint -= roundedSprintDistance * CONST_SPRINT_DISTANCE_FACTOR;

			self processChallenge( "ch_longersprint_pro", roundedSprintDistance );
		}
	}
}

CONST_MAX_SPRINT_DIST_PER_UPDATE = 40;	// in units/inches. Empirically, this topped out @ 35 u/.1 s (even with maniac and agility)
monitorSingleSprintDistance()
{
	level endon( "game_ended" );
	self endon( "spawned_player" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "sprint_end" );
	self endon( "heli_sniper_enter" );	// for heli sniper teleport
	
	prevpos = self.origin;
	while(1)
	{
		wait .1;

		dist = distance( self.origin, prevpos );
		self.sprintDistThisSprint += Clamp( dist, 0, CONST_MAX_SPRINT_DIST_PER_UPDATE );
		prevpos = self.origin;
	}
}

monitorSprintTime()
{
	level endon( "game_ended" );
	self endon( "spawned_player" );
	self endon( "death" );
	self endon( "disconnect" );

	startTime = getTime();
	
	self waittill( "sprint_end" );
	
	sprintTime = int( getTime() - startTime );
	self incPlayerStat( "sprinttime", sprintTime );
	
	self.lastSprintEndTime = GetTime();

	//total = self getPlayerStat( "sprinttime" );
	//println( "SprintTime: ", sprintTime, " Total:", total );
}	

monitorFallDistance()
{
	self endon("disconnect");

	self.pers["midairStreak"] = 0;
	
	while(1)
	{
		if ( !isAlive( self ) )
		{
			self waittill("spawned_player");
			continue;
		}
		
		if ( !self isOnGround() )
		{
			self.pers["midairStreak"] = 0;
			highestPoint = self.origin[2];
			while( !self isOnGround() && isAlive( self ) )
			{
				if ( self.origin[2] > highestPoint )
					highestPoint = self.origin[2];
				wait .05;
			}
			self.pers["midairStreak"] = 0;

			falldist = highestPoint - self.origin[2];
			if ( falldist < 0 )
				falldist = 0;
			
			if ( falldist / 12.0 > 15 && isAlive( self ) )
				self processChallenge( "ch_basejump" );

			if ( falldist / 12.0 > 30 && !isAlive( self ) )
				self processChallenge( "ch_goodbye" );
			
			//println( "You fell ", falldist / 12.0, " feet");
		}
		wait .05;
	}
}


// TODO: Make this challenge happen after winning while being the last person on your team
lastManSD()
{
	if ( !mayProcessChallenges() )
		return;

	if ( !self.wasAliveAtMatchStart )
		return;
	
	if ( self.teamkillsThisRound > 0 )
		return;
	
	self processChallenge( "ch_lastmanstanding" );
}


monitorBombUse()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		result = self waittill_any_return( "bomb_planted", "bomb_defused" );
		
		if ( !isDefined( result ) )
			continue;
			
		if ( result == "bomb_planted" )
		{
			self processChallenge( "ch_saboteur" );
		}
		else if ( result == "bomb_defused" )
			self processChallenge( "ch_hero" );
	}
}


monitorLiveTime()
{
	for ( ;; )
	{
		self waittill ( "spawned_player" );
		
		self thread survivalistChallenge();
	}
}

survivalistChallenge()
{
	self endon("death");
	self endon("disconnect");
	
	wait 5 * 60;
	
	if ( isDefined(self) )
		self processChallenge( "ch_survivalist" );
}


monitorStreaks()
{
	self endon ( "disconnect" );

	self.pers["airstrikeStreak"] = 0;
	self.pers["meleeKillStreak"] = 0;
	self.pers["shieldKillStreak"] = 0;

	self thread monitorMisc();

	for ( ;; )
	{
		self waittill ( "death" );
		
		self.pers["airstrikeStreak"] = 0;
		self.pers["meleeKillStreak"] = 0;
		self.pers["shieldKillStreak"] = 0;
	}
}


monitorMisc()
{
	self thread monitorMiscSingle( "destroyed_equipment" );
	self thread monitorMiscSingle( "begin_airstrike" );
	self thread monitorMiscSingle( "destroyed_car" );
	self thread monitorMiscSingle( "destroyed_helicopter" );
	self thread monitorMiscSingle( "used_airdrop" );
	self thread monitorMiscSingle( "used_emp" );
	self thread monitorMiscSingle( "used_nuke" );
	self thread monitorMiscSingle( "crushed_enemy" );
	
	self waittill("disconnect");
	
	// make sure the threads end when we disconnect.
	// (this allows one disconnect waittill instead of 4 disconnect endons)
	self notify( "destroyed_equipment" );
	self notify( "begin_airstrike" );
	self notify( "destroyed_car" );
	self notify( "destroyed_helicopter" );
}

monitorMiscSingle( waittillString )
{
	// don't need to endon disconnect because we will get the notify we're waiting for when we disconnect.
	// avoiding the endon disconnect saves a lot of script variables (5 * 4 threads * 64 players = 1280)
	
	while(1)
	{
		self waittill( waittillString );
		
		if ( !isDefined( self ) )
			return;
		
		monitorMiscCallback( waittillString );
	}
}

monitorMiscCallback( result )
{
	assert( isDefined( result ) );
	switch( result )
	{
		case "begin_airstrike":
			self.pers["airstrikeStreak"] = 0;
		break;

		case "destroyed_equipment":		
			if ( self IsItemUnlocked( "specialty_detectexplosive" ) && self _hasPerk( "specialty_detectexplosive" ) )
				self processChallenge( "ch_detectexplosives_pro" );

			self processChallenge( "ch_backdraft" );
		break;

		case "destroyed_helicopter":
			self processChallenge( "ch_flyswatter" );
		break;

		case "destroyed_car":
			self processChallenge( "ch_vandalism" );
		break;
		
		case "crushed_enemy":
			self processChallenge( "ch_heads_up" );

			if ( isDefined( self.finalKill ) )
				self processChallenge( "ch_droppincrates" );
		break;
	}
}


healthRegenerated()
{
	if ( is_aliens() )
		return;
	else
		healthRegenerated_regularMP();	
}

healthRegenerated_regularMP()
{
	if ( !isalive( self ) )
		return;
	
	if ( !mayProcessChallenges() )
		return;
	
	if ( !self rankingEnabled() )
		return;
	
	self thread resetBrinkOfDeathKillStreakShortly();
	
	self notify( "healed" );
	
	if ( isdefined( self.lastDamageWasFromEnemy ) && self.lastDamageWasFromEnemy )
	{
		// TODO: this isn't always getting incremented when i regen
		self.healthRegenerationStreak++;
		if ( self.healthRegenerationStreak >= 5 )
		{
			self processChallenge( "ch_invincible" );
		}
	}
}

resetBrinkOfDeathKillStreakShortly()
{
	self endon("disconnect");
	self endon("death");
	self endon("damage");
	
	wait 1;
	
	self.brinkOfDeathKillStreak = 0;
}

playerSpawned()
{
	if ( is_aliens() )
		return;
	else
		playerSpawned_regularMP();
}

playerSpawned_regularMP()
{
	self.brinkOfDeathKillStreak = 0;
	self.healthRegenerationStreak = 0;
	self.pers["MGStreak"] = 0;
}

playerDied()
{
	self.brinkOfDeathKillStreak = 0;
	self.healthRegenerationStreak = 0;
	self.pers["MGStreak"] = 0;
}

isAtBrinkOfDeath()
{
	if ( IsAlive( self ) )
	{
		ratio = self.health / self.maxHealth;
		return (ratio <= level.healthOverlayCutoff);
	}
	
	return false;
}


processChallenge( baseName, progressInc, forceSetProgress )
{
	if ( is_aliens() )
		return;
	else
		processChallenge_regularMP( baseName, progressInc, forceSetProgress );
}

processChallenge_regularMP( baseName, progressInc, forceSetProgress )
{
	if ( !mayProcessChallenges() )
		return;
	
	if ( level.players.size < 2 )
		return;
	
	if ( !self rankingEnabled() )
		return;
	 
	if ( !IsPlayer( self ) || IsAI( self ) )
		return;
	
	if ( !isDefined( progressInc ) )
		progressInc = 1;	
	
	// No daily/weekly challenges in IW6
	// need to check for daily and weekly challenges as well, but don't let it get recursive
	/*
	if( !IsSubStr( baseName, "_daily" ) && !IsSubStr( baseName, "_weekly" ) && self isItemUnlocked("tier_90") )
	{
		self thread processChallenge( baseName + "_daily", progressInc, forceSetProgress );
		self thread processChallenge( baseName + "_weekly", progressInc, forceSetProgress );
	}
	*/

	missionStatus = getChallengeStatus( baseName );
	
	if ( missionStatus == 0 )
		return;

	// challenge already completed
	isOperation = isDefined( level.challengeInfo[baseName]["operation"] );
	if ( missionStatus > level.challengeInfo[baseName]["targetval"].size )
	{
		// Operations that are on the tier past the max tier repeat the last tier, but only if they weren't completed during this match.
		isReplayOperation = isOperation && missionStatus == level.challengeInfo[baseName]["targetval"].size + 1;
		wasCompletedThisMatch = IsDefined( self.operationsMaxed ) && IsDefined( self.operationsMaxed[baseName] );
		if ( isReplayOperation && !wasCompletedThisMatch )
			missionStatus = level.challengeInfo[baseName]["targetval"].size;
		else
			return;
	}

	/#
	if ( getDvarInt( "debug_challenges" ) )
		println( "CHALLENGE PROGRESS - " + baseName + ": " + progressInc );
	#/

	// get the current progress from the player data
	currentProgress = ch_getProgress( baseName );
	targetProgress = level.challengeInfo[baseName]["targetval"][missionStatus];

	assertex( !isOperation || currentProgress < targetProgress, "Operation " + baseName + "has more progress (" + currentProgress + ") than the current tier requires (" + targetProgress + ")"  );

	if ( isDefined( forceSetProgress ) && forceSetProgress )
	{
		newProgress = progressInc;
		assertex( newProgress >= currentProgress, "Attempted progress regression (forceSet) for challenge '" + baseName + "' - from " + currentProgress + " to " + newProgress + " for player " + self.name );
	}
	else
	{
		newProgress = currentProgress + progressInc;
		assertex( newProgress >= currentProgress, "Attempted progress regression (inc) for challenge '" + baseName + "' - from " + currentProgress + " to " + newProgress + " for player " + self.name );
	}
	

	// check whether we've completed this tier
	overflowProgress = 0;
	if ( newProgress >= targetProgress )
	{
		reachedNewTier = true;
		overflowProgress = newProgress - targetProgress;
		newProgress = targetProgress;
		assertex( newProgress >= currentProgress, "Attempted progress regression (tiered up) for challenge '" + baseName + "' - from " + currentProgress + " to " + newProgress + " for player " + self.name );
	}
	else
	{
		reachedNewTier = false;
	}

	// defensive, don't set the progress if it would be a regression
	if ( currentProgress < newProgress )
		self ch_setProgress( baseName, newProgress );

	if ( reachedNewTier )
	{
		self thread giveRankXpAfterWait( baseName, missionStatus );
		self maps\mp\_matchdata::logChallenge( baseName, missionStatus );
		
		if( isOperation )
		{
			storeCompletedOperation( baseName );
		}
		else
		{
			storeCompletedChallenge( baseName );
		}
		
		//award squad points for completing the operation,
		// 2013-11-06 wallace: must comment out preferred way, bc we can't ffotd allchallengestable.csv
		/*
		if ( IsDefined( level.challengeInfo[baseName]["spReward"] ) )
		{
			unlockPtsReward = level.challengeInfo[baseName]["spReward"][missionStatus];
			self maps\mp\gametypes\_rank::giveUnlockPoints( unlockPtsReward, false );
		}
		*/
		// Instead, we will hard code the award. All Operations and higher level weapon challenges receive 1 SP
		if ( isOperation )
		{
			if( !IsDefined( level.challengeInfo[baseName]["weapon"] ) || missionStatus >= 4 )
			{
				self maps\mp\gametypes\_rank::giveUnlockPoints( 1, false );
			}
		}
		
		missionStatus++;
		self ch_setState( baseName, missionStatus );
		self.challengeData[baseName] = missionStatus;
		
		// allow the op to roll over to the next tier 
		if ( isOperation )
		{
			// If the max tier is completed
			if ( missionStatus > level.challengeInfo[baseName]["targetval"].size )
			{
				if ( !IsDefined( self.operationsMaxed ) )
					self.operationsMaxed = [];
				self.operationsMaxed[baseName] = true;
				
				// Weapon challenges only reset the max tier
				if ( IsDefined( level.challengeInfo[baseName]["weapon"] ) )
				{
					ch_setProgress( baseName, overFlowProgress );
				}
			}
			
			// Do not reset weapon challenge progress after each tier completion
			if ( !IsDefined( level.challengeInfo[baseName]["weapon"] ) )
			{
				ch_setProgress( baseName, overFlowProgress );
			}
			
			// increment the number of operations completed so that player can receive bonuses when ops recycle
			numOpscompleted = self GetRankedPlayerData( "challengeState", CONST_OPREF_NUM_COMPLETED_OPS );
			self SetRankedPlayerData( "challengeState", CONST_OPREF_NUM_COMPLETED_OPS, numOpscompleted + 1 );
		}

		self thread maps\mp\gametypes\_hud_message::challengeSplashNotify( baseName );
	}
}

storeCompletedChallenge( baseName )
{
		if ( !isDefined( self.challengesCompleted ) )
		{
			self.challengesCompleted = [];
		}
		
		//remove duplicate entries.
		chFound = false;
		foreach ( challenge in self.challengesCompleted )
		{
			if ( challenge == baseName )
				chFound = true;
		}
		
		if ( !chFound )
			self.challengesCompleted[ self.challengesCompleted.size ] = baseName;
}
		
storeCompletedOperation( baseName )
{
	if ( !isDefined( self.operationsCompleted ) )
	{
		self.operationsCompleted = [];
	}

	//remove duplicate entries.
	chFound = false;
	foreach ( challenge in self.operationsCompleted )
	{
		if ( challenge == baseName )
		{
			chFound = true;
			break;
		}
	}
		
	if ( !chFound )
		self.operationsCompleted[ self.operationsCompleted.size ] = baseName;
}

giveRankXpAfterWait( baseName, missionStatus )
{
	self endon ( "disconnect" );

	wait( 0.25 );
	type = "challenge";
	if ( isOperationChallenge( baseName ))
	{
		type = "operation";
	}
	self maps\mp\gametypes\_rank::giveRankXP( type, level.challengeInfo[baseName]["reward"][missionStatus], undefined, undefined, baseName );
}


CONST_NUM_OP_CATEGORIES = 5;
CONST_NUM_OPS_PER_CATEGORY = 10;
updateChallenges()
{
	self.challengeData = [];
	
	self endon( "disconnect" );
	
	if ( !mayProcessChallenges() )
		return;
	/#
		// sometimes we want to do fake challenge tracking in systemlink
		if ( !level.rankedMatch )
			return;
	#/
	
	challengeCount = 0;

	foreach ( challengeRef, levelChallengeData in level.challengeInfo )
	{
		// limit the number of these we do in a single server frame so that it doesn't cause jitter as clients join
		// with ~800 challenges at 20Hz, processing 20 per frame should take 2 total seconds to complete.
		challengeCount++;
		if ( (challengeCount % 20) == 0 )
		{
			wait( 0.05 );
		}

		self.challengeData[challengeRef] = 0;
		
		assertEx( IsDefined( levelChallengeData["type"] ), "Challenge type not defined: " + challengeRef + " for player " + self.name + " from " + level.challengeInfo.size + " total challenges" );
		assertEx( IsDefined( levelChallengeData["index"] ), "Challenge index not defined: " + challengeRef + " for player " + self.name + " from " + level.challengeInfo.size + " total challenges" );
		
		challengeIndex = levelChallengeData["index"];
		
		status = ch_getState( challengeRef );
		if ( status == 0 )
		{
			ch_setState( challengeRef, 1 );
			status = 1;
		}
		
		self.challengeData[challengeRef] = status;
	}
	
	// 2013-11-22 wallace: in game, repair the state of some bad challenges. We should remove this for IW7.
	self fixAllBadOperations();
}

isInUnlockTable( challengeName )
{
	return ( TableLookup( UNLOCK_TABLE_REF, 0, challengeName, 0 ) != "" );
}

getChallengeFilter( challengeName )
{
	return TableLookup( ALL_CHALLENGES_TABLE_REF, 0, challengeName, 5 );
}

getChallengeTable( challengeFilter )
{
	return TableLookup( CHALLENGE_TABLE_REF, 8, challengeFilter, 4 );
}

getTierFromTable( challengeTable, challengeName )
{
	return TableLookup( challengeTable, 0, challengeName, 1 );
}

isWeaponChallenge( challengeName )
{
	if( !IsDefined( challengeName ) )
		return false;

	tableValue = getChallengeFilter( challengeName );
	
	// IW6: challenge filters use weapon base names and are used to signify weapon challenges
	if ( IsDefined( tableValue ) )
	{
		if ( maps\mp\gametypes\_class::isValidPrimary( tableValue, false ) 
		    || maps\mp\gametypes\_class::isValidSecondary( tableValue, false ) 
		   )
		{
			return true;
		}
	}
	
	return false;
}

// IW6: challenge filters use weapon base names and are used to signify weapon challenges
getWeaponFromChallenge( challengeRef )
{
	assertex( isWeaponChallenge( challengeRef ), challengeRef + " is not a weapon challenge!" );
	return getChallengeFilter( challengeRef );
}

isReticleChallenge( challengeRef )
{
	tableValue = getChallengeFilter( challengeRef );
	return ( tableValue == "acog"
	    || tableValue == "eotech"
	    || tableValue == "hybrid"
	    || tableValue == "reflex"
	   );
}

getSightFromReticleChallenge( challengeRef )
{
	return getChallengeFilter( challengeRef );
}

getWeaponAttachmentFromChallenge( challengeRef )
{
	prefix = "ch_";
	if ( isSubStr( challengeRef, "ch_marksman_" ) )
		prefix = "ch_marksman_";
	else if ( isSubStr( challengeRef, "ch_expert_" ) )
		prefix = "ch_expert_";
	else if ( isSubStr( challengeRef, "pr_marksman_" ) )
		prefix = "pr_marksman_";
	else if ( isSubStr( challengeRef, "pr_expert_" ) )
		prefix = "pr_expert_";

	baseWeapon = GetSubStr( challengeRef, prefix.size, challengeRef.size );
	// now strip off the attachment
	weaponTokens = StrTok( baseWeapon, "_" );
	attachment = undefined;
	if( IsDefined( weaponTokens[2] ) && isAttachment( weaponTokens[2] ) )
		attachment = weaponTokens[2];

	return attachment;
}

isKillstreakChallenge( challengeName )
{
	if( !IsDefined( challengeName ) )
		return false;

	// look at the filter column to see if this is a killstreak challenge
	tableValue = getChallengeFilter( challengeName );
	if( IsDefined( tableValue ) && ( tableValue == "killstreaks_assault" || tableValue == "killstreaks_support" ) )
		return true;

	return false;
}

getKillstreakFromChallenge( challengeRef )
{
	prefix = "ch_";
	killstreakName = GetSubStr( challengeRef, prefix.size, challengeRef.size );

	if( killstreakName == "assault_streaks" || killstreakName == "support_streaks" )
		killstreakName = undefined;

	return killstreakName;
}


isOperationChallenge( challengeRef )
{
	//TODO.cleanup ... create better filters for the operations challenges...
	
	if( !IsDefined( challengeRef ) )
		return false;

	// look at the filter column to see if this is an operation challenge
	tableValue = getChallengeFilter( challengeRef );
	if( IsDefined( tableValue ))
	{
		if( tableValue == "perk_slot_0" ||
			tableValue == "perk_slot_1" ||
			tableValue == "perk_slot_2" ||
			tableValue == "proficiency" ||
			tableValue == "equipment" ||
			tableValue == "special_equipment" ||
			tableValue == "attachment" ||
			tableValue == "prestige" ||
			tableValue == "final_killcam" ||
			tableValue == "basic" ||
			tableValue == "humiliation" ||
			tableValue == "precision" ||
			tableValue == "revenge" ||
			tableValue == "elite" ||
			tableValue == "intimidation" ||
			tableValue == "operations" ||
			isStrStart( tableValue, "killstreaks_" )	// catches all 3 killstreak types
		)
		{
			return true;
		}
	}
	
	if( isWeaponChallenge( challengeRef ) )
   	{
		return true;
	}

	return false;
}


/*
	challenge_targetVal and rewardVal should cast their return values to int
*/
challenge_targetVal( tableName, refString, tierId )
{
	value = tableLookup( tableName, CH_REF_COL, refString, CH_TARGET_COL + ((tierId-1)*2) );
	return int( value );
}


challenge_rewardVal( tableName, refString, tierId )
{
	value = tableLookup( tableName, CH_REF_COL, refString, CH_REWARD_COL + ((tierId-1)*2) );
	return int( value );
}


challenge_spRewardVal( tableName, refString, tierId )
{
	value = tableLookup( tableName, CH_REF_COL, refString, CH_SP_REWARD_COL + (tierId-1) );
	return int( value );
}


buildChallengeTableInfo( tableName, typeId )
{
	index = 0;
	totalRewardXP = 0;

	refString = tableLookupByRow( tableName, 0, CH_REF_COL );
	assertEx( isSubStr( refString, "ch_" ), "Invalid challenge name: " + refString + " found in " + tableName );
	for ( index = 1; refString != ""; index++ )
	{
		assertEx( isSubStr( refString, "ch_" ), "Invalid challenge name: " + refString + " found in " + tableName );

		level.challengeInfo[refString] = [];
		level.challengeInfo[refString]["index"] = index - 1;
		level.challengeInfo[refString]["type"] = typeId;
		level.challengeInfo[refString]["targetval"] = [];
		level.challengeInfo[refString]["reward"] = [];

		if ( isReticleChallenge( refString ) )
		{
			sight = getSightFromReticleChallenge( refString );
			if ( IsDefined( sight ) )
				level.challengeInfo[refString]["sight"] = sight;
		}
		else if( isOperationChallenge( refString ))
		{
			level.challengeInfo[refString]["operation"] = 1;
			level.challengeInfo[refString]["spReward"] = [];
			
			// In IW6 killstreak challenges are als ops
			if( isKillstreakChallenge( refString ) ) 	// make sure the killstreak is unlocked
			{
				killstreakName = getKillstreakFromChallenge( refString );
				if( IsDefined( killstreakName ) )
					level.challengeInfo[refString]["killstreak"] = killstreakName;
			}
			
			// Weapon challenges are now ops
			if ( isWeaponChallenge( refString ) )
			{
				baseWeapon = getWeaponFromChallenge( refString );
				
				if ( IsDefined( baseWeapon ) )
					level.challengeInfo[refString]["weapon"] = baseWeapon;
			}
		}


		for ( tierId = 1; tierId < 11; tierId++ )
		{
			targetVal = challenge_targetVal( tableName, refString, tierId );
			rewardVal = challenge_rewardVal( tableName, refString, tierId );

			if ( targetVal == 0 )
				break;

			level.challengeInfo[refString]["targetval"][tierId] = targetVal;
			level.challengeInfo[refString]["reward"][tierId] = rewardVal;

			//store off squad point reward values for operation challenges
			if ( isDefined( level.challengeInfo[refString]["spReward"] ) )
			{
				spRewardVal = challenge_spRewardVal( tableName, refString, tierId );
				level.challengeInfo[refString]["spReward"][tierId] = spRewardVal;
			}
			
			totalRewardXP += rewardVal;
		}
		
		assert( isDefined( level.challengeInfo[refString]["targetval"][1] ) );

		refString = tableLookupByRow( tableName, index, CH_REF_COL );
	}

	/#
	printLn( "Added " + (index - 1) + " challenges from " + tableName );
	#/
	
	return int( totalRewardXP );
}

buildChallegeInfo()
{
	level.challengeInfo = [];

	totalRewardXP = 0;
	
	totalRewardXP += buildChallengeTableInfo( ALL_CHALLENGES_TABLE_REF, CH_REGULAR );
	// Comment out these challenges for now - they need to be cleaned up to match allchallengestable
	//totalRewardXP += buildChallengeTableInfo( DAILY_CHALLENGES_TABLE_REF, CH_DAILY );
	//totalRewardXP += buildChallengeTableInfo( WEEKLY_CHALLENGES_TABLE_REF, CH_WEEKLY );
	
	/#
	printLn( "TOTAL CHALLENGE REWARD XP: " + totalRewardXP );
	#/

	/*
	tierTable = tableLookupByRow( "mp/challengeTable.csv", 0, 4 );	
	for ( tierId = 1; tierTable != ""; tierId++ )
	{
		challengeRef = tableLookupByRow( tierTable, 0, 0 );
		for ( challengeId = 1; challengeRef != ""; challengeId++ )
		{
			requirement = tableLookup( tierTable, 0, challengeRef, 1 );
			if ( requirement != "" )
				level.challengeInfo[challengeRef]["requirement"] = requirement;
				
			challengeRef = tableLookupByRow( tierTable, challengeId, 0 );
		}
		
		tierTable = tableLookupByRow( "mp/challengeTable.csv", tierId, 4 );	
	}
	*/
}

/#
verifyMarksmanChallenges()
{
}

verifyExpertChallenges()
{
}
#/

/#
completeAllChallenges( percentage )
{
	foreach ( challengeRef, challengeData in level.challengeInfo )
	{
		finalTarget = 0;
		finalTier = 0;
		for ( tierId = 1; isDefined( challengeData["targetval"][tierId] ); tierId++ )
		{
			finalTarget = challengeData["targetval"][tierId];
			finalTier = tierId + 1;
		}
		
		if ( percentage != 1.0 )
		{
			finalTarget--;
			finalTier--;
		}

		if( matchMakingGame() )
		{
			if ( self IsItemUnlocked( challengeRef ) || percentage == 1.0 )
			{		
				self setRankedPlayerData( "challengeProgress", challengeRef, finalTarget );
				self setRankedPlayerData( "challengeState", challengeRef, finalTier );
			}
		}
		else
		{
			actionData = spawnStruct();
			actionData.name = challengeRef;	
			actionData.type = TableLookup( maps\mp\gametypes\_hud_message::get_table_name(), 0, challengeRef, 11 );
			actionData.optionalNumber = finalTier;
			actionData.sound = TableLookup( maps\mp\gametypes\_hud_message::get_table_name(), 0, challengeRef, 9 );
			// use the same slot as playercard
			actionData.slot = 1;
			self thread maps\mp\gametypes\_hud_message::actionNotify( actionData );
		}
		
		wait ( 0.05 );
	}
	
	println( "Done unlocking challenges" );
}
#/

monitorProcessChallenge()
{
	self endon( "disconnect" );
	level endon( "game_end" );
	
	for( ;; )
	{
		if( !mayProcessChallenges() )
			return;
			
		self waittill( "process", challengeName );
		self processChallenge( challengeName );
	}	
}

monitorKillstreakProgress()
{
	self endon( "disconnect" );
	level endon( "game_end" );
	
	for( ;; )
	{
		self waittill ( "got_killstreak", streakCount );
		
		//for scr_givkillstreak
		if( !isDefined( streakCount ) )
			continue;
		
		switch ( streakCount )
		{
			case 3:
				self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "3streak" ); 
				break;
			case 4:
				self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "4streak" ); 
				break;
			case 5:
				self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "5streak" ); 
				break;
			case 6:
				self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "6streak" ); 
				break;
			case 7:
				self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "7streak" ); 
				break;
			case 8:
				self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "8streak" ); 
				break;
			case 9:
				self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "9streak" ); 	
				break;
			case 10:
				self maps\mp\killstreaks\_killstreaks::giveAdrenaline( "10streak" ); 
				break;
			default:
				break;
		}
		
		if ( streakCount == 10 && self.killstreaks.size == 0 )
			self processChallenge( "ch_theloner" );		
		else if ( streakCount == 9 )
		{
			if ( isDefined( self.killstreaks[7] ) && isDefined( self.killstreaks[8] ) && isDefined( self.killstreaks[9] ) )
			{
				self processChallenge( "ch_6fears7" );
			}
		}
	}
}


monitorKilledKillstreak()
{
	self endon( "disconnect" );
	level endon( "game_end" );
	
	for( ;; )
	{
		self waittill( "destroyed_killstreak", weapon );
		
		if ( self IsItemUnlocked( "specialty_blindeye" ) && self _hasPerk( "specialty_blindeye" ) )
			self processChallenge( "ch_blindeye_pro" );
	}	
}


genericChallenge( challengeType, value )
{
	switch ( challengeType )
	{
		case "hijacker_airdrop":
			self processChallenge( "ch_smoothcriminal" );
			break;
		case "hijacker_airdrop_mega":
			self processChallenge( "ch_poolshark" );
			break;
		case "wargasm":
			self processChallenge( "ch_wargasm" );
			break;
		case "weapon_assault":
			self processChallenge( "ch_surgical_assault" );
			break;
		case "weapon_smg":
			self processChallenge( "ch_surgical_smg" );
			break;
		case "weapon_lmg":
			self processChallenge( "ch_surgical_lmg" );
			break;
		case "weapon_dmr":
			self processChallenge( "ch_surgical_dmr" );
			break;
		case "weapon_sniper":
			self processChallenge( "ch_surgical_sniper" );
			break;
		case "weapon_shotgun":
			self processChallenge( "ch_surgical_shotgun" );
			break;
		case "shield_damage":
			if( !self isJuggernaut() )
			{
				// OP_IW6, used to be ch_shield_damage
				self processChallenge( "ch_iw6_riotshield_damage", value );
			}
			break;
		case "shield_bullet_hits":
			if( !self isJuggernaut() )
				self processChallenge( "ch_shield_bullet", value );
			break;
		case "shield_explosive_hits":
			// OP_IW6, used to be ch_shield_explosive
			if( !self isJuggernaut() )
				self processChallenge( "ch_iw6_riotshield_explosive", value );
			break;
	}	
}

playerHasAmmo()
{
	primaryWeapons = self getWeaponsListPrimaries();	

	foreach ( primary in primaryWeapons )
	{
		if ( self GetWeaponAmmoClip( primary ) )
		{
			// melee weapons will return non-zero so that code will auto switch to them
			if ( !maps\mp\gametypes\_weapons::isRiotShield( primary )
			    && !maps\mp\gametypes\_weapons::isKnifeOnly( primary )
			   )
			{
				return true;
			}
		}
			
		altWeapon = weaponAltWeaponName( primary );

		if ( !isDefined( altWeapon ) || (altWeapon == "none") )
			continue;

		if ( self GetWeaponAmmoClip( altWeapon ) )
			return true;
	}
	
	return false;
}

monitorADSTime()
{
	self endon ( "disconnect" );

	self.adsTime = 0.0;
	while( true )
	{
		if( self PlayerAds() == 1 )
		{
			self.adsTime += 0.05;
		}
		else
		{
			self.adsTime = 0.0;
		}

		wait( 0.05 );
	}
}

monitorHoldBreath()
{
	self endon ( "disconnect" );

	self.holdingBreath = false;
	while( true )
	{
		self waittill( "hold_breath" );
		self.holdingBreath = true;
		self waittill( "release_breath" );
		self.holdingBreath = false;
	}
}

monitorMantle()
{
	self endon( "disconnect" );

	self.mantling = false;
	while( true )
	{
		self waittill( "jumped" );
		prevWeaponName = self GetCurrentWeapon();
		self waittill_notify_or_timeout( "weapon_change", 1 );
		currWeaponName = self GetCurrentWeapon();
		if( currWeaponName == "none" )
			self.mantling = true;
		else
			self.mantling = false;
		
		if( self.mantling )
		{
			if( self IsItemUnlocked( "specialty_fastmantle" ) && self _hasPerk( "specialty_fastmantle" ) )
				self processChallenge( "ch_fastmantle" );

			self waittill_notify_or_timeout( "weapon_change", 1 );
			currWeaponName = self GetCurrentWeapon();
			if( currWeaponName == prevWeaponName )
				self.mantling = false;
		}
	}
}

monitorWeaponSwap()
{
	self endon( "disconnect" );

	prevWeaponName = self GetCurrentWeapon();
	while( true )
	{
		self waittill( "weapon_change", newWeaponName );
		
		if( newWeaponName == "none" )
			continue;

		if( newWeaponName == prevWeaponName )
			continue;

		if( isKillstreakWeapon( newWeaponName ) )
			continue;

		if( newWeaponName == "briefcase_bomb_mp" || newWeaponName == "briefcase_bomb_defuse_mp" )
			continue;
		
		weaponInvType = WeaponInventoryType( newWeaponName );
		if( weaponInvType != "primary" )
			continue;

		self.lastPrimaryWeaponSwapTime = GetTime();
	}
}

monitorFlashbang()
{
	self endon( "disconnect" );

	while( true )
	{
		self waittill( "flashbang", origin, amount_distance, amount_angle, attacker );
		
		if( self == attacker )
			continue;

		self.lastFlashedTime = GetTime();
	}
}

monitorConcussion()
{
	self endon( "disconnect" );

	while( true )
	{
		self waittill( "concussed", attacker );

		if( self == attacker )
			continue;

		self.lastConcussedTime = GetTime();
	}
}

monitorMineTriggering()
{
	self endon( "disconnect" );

	while( true )
	{
		// made this very simple, if they trip a mine, claymore, ims and live the delay mine amount of time then process challenge
		self waittill( "triggeredExpl", explType );

		self thread waitDelayMineTime();
	}
}

waitDelayMineTime()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	// add more time to give the mine a chance to detonate and kill
	wait( level.delayMineTime + 2 );

	self processChallenge( "ch_delaymine" );
}

monitorReload()
{
	self endon( "disconnect" );
	
	while (true)
	{
		self waittill ( "reload" );
		
		if ( self IsSprinting() )
		{
			self.sprintReloadTimeStamp = GetTime() + OP_ONTHEGO_RELOADTIME;
		}
		
		curWeapon = self GetCurrentWeapon();
		self.lastReloadedWeapon = curWeapon;
		
		switch ( WeaponClass( curweapon ) )
		{
			// this handles both dmr and snipers
			case "sniper":
				self.reloadTimeStamp = GetTime() + OP_OP_SLEIGHTOFHAND_RELOADTIME_SNIPER;
				break;
			default:
				self.reloadTimeStamp = GetTime() + OP_SLEIGHTOFHAND_RELOADTIME;
				break;
		}
		
		// used for ch_meticulous: kill at least 4 enemies in one clip
		self.killsThisMag[ curWeapon ] = 0;
	}
}

CONST_SPRINT_SLIDE_GRACEPERIOD = 1000;
// Used for events that must happen during a slide.
monitorSprintSlide()
{
	self endon( "disconnect" );
	
	// when the player slides we want to play a cam fx
	while ( true )
	{
		msg = self waittill_any_return( "sprint_slide_begin", "sprint_slide_end", "death" );
		
		if ( !IsAlive( self ) )
		{
			self.isSliding = undefined;
			self.isSlidingGracePeriod = GetTime() - 1;
		}
		else if ( msg == "sprint_slide_end" )
		{
			self.isSliding = undefined;
			self.isSlidingGracePeriod = GetTime() + CONST_SPRINT_SLIDE_GRACEPERIOD;
		}
		else if ( msg == "sprint_slide_begin" )
		{
			// would have liked to use IsSprintSliding instead, but it's sp only
			self.isSliding = true;
		}
	}
}

playerIsSprintSliding()	// self == player
{
	return ( IsDefined( self.isSliding ) 
		    || ( IsDefined( self.isSlidingGracePeriod) && GetTime() <= self.isSlidingGracePeriod )
		   );
}

CONST_SPRINT_SLIDE_RECENT_GRACEPERIOD = 2000 - CONST_SPRINT_SLIDE_GRACEPERIOD;
// Used for events where the player is 
// required to do something during or 
// just after a slide
playerSprintSlidRecently()
{
	return ( IsDefined( self.isSliding ) 
		    || ( IsDefined( self.isSlidingGracePeriod) && GetTime() <= self.isSlidingGracePeriod + CONST_SPRINT_SLIDE_RECENT_GRACEPERIOD )
		   );
}

shouldProcessChallengeForPerk( perkName )	// self == player
{
	return ( self IsItemUnlocked( perkName ) && self _hasPerk( perkName ) );
}

processWeaponAttachmentChallenge( baseWeapon, weaponAttachment )	// self == player
{
	// self processChallenge( "ch_" + baseWeapon + "_" + weaponAttachment );	// IW5:  per weapon, per attachment
	self processChallenge( "ch_" + weaponAttachment );	// IW6: per attachment, across all weapons
}

processFinalKillChallenges( attacker, victim )
{
	if ( !mayProcessChallenges() || IsAI( attacker ) )
		return;
	
	attacker processChallenge( "ch_theedge" );
	
	if ( !IsAI( victim ) )
		victim processChallenge( "ch_starryeyed" );

	if( IsDefined( attacker.modifiers["revenge"] ) )
		attacker processChallenge( "ch_moneyshot" );

	if( IsDefined( victim ) 
	   && IsDefined( victim.explosiveInfo ) 
	   && IsDefined( victim.explosiveInfo["stickKill"] ) 
	   && victim.explosiveInfo["stickKill"] 
	  )
	{
		attacker processChallenge( "ch_stickman" );
	}
		
	if( IsDefined( victim.attackerData[ attacker.guid ] ) && 
		IsDefined( victim.attackerData[ attacker.guid ].sMeansOfDeath ) && 
		IsDefined( victim.attackerData[ attacker.guid ].weapon ) && 
		isSubStr( victim.attackerData[ attacker.guid ].sMeansOfDeath, "MOD_MELEE" ) && 
		maps\mp\gametypes\_weapons::isRiotShield( victim.attackerData[ attacker.guid ].weapon ) )
	{
		attacker maps\mp\gametypes\_missions::processChallenge( "ch_owned" );
	}
	
	// 2013-09-11 wallace: ugh, so hack-y. ffa players actually have a team, but we set the final kill cam weapon based on "none"
	finalTeam = attacker.team;
	if ( !level.teamBased )
	{
		finalTeam = "none";
	}

	switch( level.finalKillCam_sWeapon[ finalTeam ] )
	{
	case "sentry_minigun_mp":		// Sentry Gun
		attacker processChallenge( "ch_absentee" );
		break;
	case "remote_tank_projectile_mp":	// vanguard
		attacker processChallenge( "ch_gryphonattack" );
		break;
		
	case "heli_pilot_turret_mp": // heli pilot
		attacker processChallenge( "ch_hotshot" );
		break;
		
	case "iw6_gm6helisnipe_mp_gm6scope":	// heli sniper
		attacker processChallenge( "ch_heli_sniper_finalkill" );
		break;
		
	case "drone_hive_projectile_mp":	// trinity rocket
	case "switch_blade_child_mp":
		attacker processChallenge( "ch_noescape" );
		break;
	
	case "ball_drone_gun_mp":	// backup buddy / vulture
		attacker processChallenge( "ch_thanksbuddy" );
		break;
	
	case "odin_projectile_large_rod_mp":	// loki
	case "odin_projectile_small_rod_mp":
		attacker processChallenge( "ch_lokikiller" );
		break;
		
	case "cobra_20mm_mp":	// Attack Helicopter
	case "hind_bomb_mp":	// battle hind
	case "hind_missile_mp":
		attacker processChallenge( "ch_og" );
		break;
		
	case "guard_dog_mp":
		attacker processChallenge( "ch_bestinshow" );
		break;
		
	case "ims_projectile_mp":
		attacker processChallenge( "ch_outsmarted" );
		break;
			
	case "iw6_minigunjugg_mp":	// assault juggernaut
	case "iw6_p226jugg_mp":
	case "mortar_shelljugg_mp":
		attacker processChallenge( "ch_painless" );
		break;
		
	case "throwingknifejugg_mp":
	case "iw6_knifeonlyjugg_mp":	// maniac
		attacker processChallenge( "ch_untouchable" );
		break;
			
	case "agent_support_mp":	// recon agent
		attacker processChallenge( "ch_bestmates" );
		break;

	default:
		break;	
	}
}


//-------------------------------------------
// OP_IW6 Reticle unlock challenges for sights
processWeaponAttachmentChallenge_Acog( baseWeapon, weaponAttachment, data )	// self == player
{
	if ( self isPlayerAds() )
	{
		// kills
		self processChallenge( "ch_" + weaponAttachment );	
	
		if ( self GetStance() == "prone" )
		{
			self processChallenge( "ch_" + weaponAttachment + "_prone" );
		}
		
		self checkChallengeKillModifier( data, "longshot", weaponAttachment );
		
		self checkChallengeKillModifier( data, "headshot", weaponAttachment );
		
		if ( self.recentKillCount == 2 )
		{
			self processChallenge( "ch_" + weaponAttachment + "_double" );
		}
		
		// 2013-09-25 wallace: another typo with challenge name. called "_oneshot" instead of matching modifier name
		// self checkChallengeKillModifier( data, "oneshotkill", weaponAttachment );
		if ( IsDefined( data.modifiers[ "oneshotkill" ] ) )
		{
			self processChallenge( "ch_acog_oneshot" );
		}
	}
}

processWeaponAttachmentChallenge_EOTech( baseWeapon, weaponAttachment, data )	// self == player
{
	if ( self isPlayerAds() )
	{
		// kills
		self processChallenge( "ch_" + weaponAttachment );	
		
		// burst fire
		if ( weaponIsFireTypeBurst( data.sWeapon ) )
		{
			self processChallenge( "ch_" + weaponAttachment + "_burst" );
		}
		
		if ( self isLeaning() )
		{
			// should have used checkChallengeIsLeaning, but the reticle challenges are named differently than camo ones
			self processChallenge( "ch_" + weaponAttachment + "_lean" );
		}
		
		self checkChallengeKillModifier( data, "headshot", weaponAttachment );
		
		if ( self.recentKillCount == 2 )
		{
			self processChallenge( "ch_" + weaponAttachment + "_double" );
		}
		
		self checkConsecutiveChallenge( data.sWeapon, weaponAttachment );
	}
}

processWeaponAttachmentChallenge_Hybrid( baseWeapon, weaponAttachment, data )	// self == player
{
	if ( self isPlayerAds() )
	{
		// kills
		self processChallenge( "ch_" + weaponAttachment );
		
		if ( data.hybridScopeState )	// this value is defined in PlayerKilled_regularMP
		{
			// zoomed out
			self processChallenge( "ch_hybrid_zoomout" );
			
			self checkChallengeKillModifier( data, "headshot", weaponAttachment );
		}
		else
		{
			// zoomed in
			self processChallenge( "ch_hybrid_zoomin" );
			
			self checkChallengeKillModifier( data, "longshot", weaponAttachment );
		}
		
		self checkPenetrationChallenge( data.victim, weaponAttachment );
	}
}

processWeaponAttachmentChallenge_Reflex( baseWeapon, weaponAttachment, data )	// self == player
{
	if ( self isPlayerAds() )
	{
		// kills
		self processChallenge( "ch_" + weaponAttachment );	
	
		if ( self GetStance() == "crouch" )
		{
			self processChallenge( "ch_" + weaponAttachment + "_crouch" );
		}
		
		// moving
		movement = self GetVelocity();
		if ( LengthSquared( movement ) > 16 )
		{
			self processChallenge( "ch_reflex_moving" );
		}
		
		// slug round
		if ( weaponHasAttachment( data.sWeapon, "ammoslug" ) )
		{
			self processChallenge( "ch_" + weaponAttachment + "_ammoslug" );
		}
		
		self checkChallengeKillModifier( data, "headshot", weaponAttachment );
		
		// alt shotgun
		if ( isStrStart( data.sWeapon, "alt_" )
		    && weaponHasAttachment( data.sWeapon, "shotgun" )
			)
		{
			self processChallenge( "ch_" + weaponAttachment + "_altshotgun" );
		}
	}
}

// ---------------------------------------
// OP_IW6 Weapon camo challenges
processWeaponClassChallenge_AR( baseWeapon, data )	// self == player
{
	// player processChallenge( "ch_ar_kill" );
	self processChallenge( "ch_" + baseWeapon );
	
	// crouch
	if ( self GetStance() == "crouch" )
	{
		self processChallenge( "ch_" + baseWeapon + "_crouch" );
	}
	
	// assists must be tracked elsewhere, this is for kills only
	
	// aka rescuer!
	self checkChallengeKillModifier( data, "defender", baseWeapon );
	
	// no attachments
	if ( weaponGetNumAttachments( data.sWeapon ) == 0 )
	{
		self processChallenge( "ch_" + baseWeapon + "_noattach" );
	}
	
	// long shots
	self checkChallengeKillModifier( data, "longshot", baseWeapon );
	
	// consecutive kills
	self checkConsecutiveChallenge( data.sWeapon, baseWeapon );
	
	// point blank
	self checkChallengeKillModifier( data, "pointblank", baseWeapon );
	
	// kills within X secs of reload
	if ( self hasReloadedRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_reload" );
	}
	
	// sliding
	if ( self playerSprintSlidRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_sliding" );
	}
	
	// lean
	self checkChallengeIsLeaning( baseWeapon );
}

processWeaponClassChallenge_SMG( baseWeapon, data )	// self == player
{
	// self processChallenge( "ch_smg_kill" );
	
	self processChallenge( "ch_" + baseWeapon );
	
	// crouch
	if ( self GetStance() == "crouch" )
	{
		self processChallenge( "ch_" + baseWeapon + "_crouch" );
	}
	
	// assists must be tracked elsewhere, this is for kills only
	
	// aka rescuer!
	self checkChallengeKillModifier( data, "defender", baseWeapon );
	
	// no attachments
	if ( weaponGetNumAttachments( data.sWeapon ) == 0 )
	{
		self processChallenge( "ch_" + baseWeapon + "_noattach" );
	}
	
	// hip fire kills
	if ( !self isPlayerAds() )
	{
		self processChallenge( "ch_" + baseWeapon + "_hipfire" );
	}
	
	// consecutive kills
	self checkConsecutiveChallenge( data.sWeapon, baseWeapon );
	
	// point blank
	self checkChallengeKillModifier( data, "pointblank", baseWeapon );
	
	// kills within X secs of reload
	if ( self hasReloadedRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_reload" );
	}
	
	// sliding
	if ( self playerSprintSlidRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_sliding" );
	}
	
	// lean
	self checkChallengeIsLeaning( baseWeapon );
}

processWeaponClassChallenge_LMG( baseWeapon, data )	// self == player
{
	// self processChallenge( "ch_lmg_kill" );
	
	self processChallenge( "ch_" + baseWeapon );
	
	// crouch
	if ( self GetStance() == "crouch" )
	{
		self processChallenge( "ch_" + baseWeapon + "_crouch" );
	}
	
	// assists must be tracked elsewhere, this is for kills only
	
	// aka rescuer!
	self checkChallengeKillModifier( data, "defender", baseWeapon );
	
	// no attachments
	if ( weaponGetNumAttachments( data.sWeapon ) == 0 )
	{
		self processChallenge( "ch_" + baseWeapon + "_noattach" );
	}
	
	// hip fire kills
	if ( !self isPlayerAds() )
	{
		self processChallenge( "ch_" + baseWeapon + "_hipfire" );
	}
	
	// consecutive kills
	self checkConsecutiveChallenge( data.sWeapon, baseWeapon );
	
	// point blank
	self checkChallengeKillModifier( data, "pointblank", baseWeapon );
	
	// penetration kills
	self checkPenetrationChallenge( data.victim, baseWeapon );
	
	// sliding
	if ( self playerSprintSlidRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_sliding" );
	}
	
	// OP_IW6 Ghost Busted - kill an enemy in PMC elite heavy
	if ( data.sMeansOfDeath == "MOD_HEAD_SHOT"
	    && checkCostumeChallenge( data.victim, "mp_body_elite_pmc_lmg_b" ) )
	{
		self processChallenge( "ch_ghostbusted" );
	}
	
	// lean
	self checkChallengeIsLeaning( baseWeapon );
}

processWeaponClassChallenge_DMR( baseWeapon, data )	// self == player
{
	// self processChallenge( "ch_dmr_kill" );	// ToDo: Update with challenge pass
	
	self processChallenge( "ch_" + baseWeapon );
	
	// crouch
	if ( self GetStance() == "crouch" )
	{
		self processChallenge( "ch_" + baseWeapon + "_crouch" );
	}
	
	// assists must be tracked elsewhere, this is for kills only
	
	// aka rescuer!
	self checkChallengeKillModifier( data, "defender", baseWeapon );
	
	// long shots
	self checkChallengeKillModifier( data, "longshot", baseWeapon );
	
	// head shot
	self checkChallengeKillModifier( data, "headshot", baseWeapon );
	
	// point blank
	self checkChallengeKillModifier( data, "pointblank", baseWeapon );
	
	// consecutive kills
	self checkConsecutiveChallenge( data.sWeapon, baseWeapon );
	
	// no attachments
	if ( weaponGetNumAttachments( data.sWeapon ) == 0 )
	{
		self processChallenge( "ch_" + baseWeapon + "_noattach" );
	}
	
	// kills within X secs of reload
	if ( self hasReloadedRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_reload" );
	}
	
	// lean
	self checkChallengeIsLeaning( baseWeapon );
}

processWeaponClassChallenge_Sniper( baseWeapon, data )	// self == player
{
	self processChallenge( "ch_sniper_kill" );
	
	self processChallenge( "ch_" + baseWeapon );
	
	// crouch
	if ( self GetStance() == "crouch" )
	{
		self processChallenge( "ch_" + baseWeapon + "_crouch" );
	}
	
	// no attachments
	if ( weaponGetNumAttachments( data.sWeapon ) == 0 )
	{
		self processChallenge( "ch_" + baseWeapon + "_noattach" );
	}
	
	// aka rescuer!
	self checkChallengeKillModifier( data, "defender", baseWeapon );
	
	// prone
	if ( self GetStance() == "prone" )
	{
		self processChallenge( "ch_" + baseWeapon + "_prone" );
	}
	
	// one shots
	self checkChallengeKillModifier( data, "oneshotkill", baseWeapon );
	
	// consecutive kills
	self checkConsecutiveChallenge( data.sWeapon, baseWeapon );
	
	// pointblank
	self checkChallengeKillModifier( data, "pointblank", baseWeapon );
	
	// kills within X secs of reload
	if ( self hasReloadedRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_reload" );
	}
	
	// penetration kills
	self checkPenetrationChallenge( data.victim, baseWeapon );
	
	// lean
	self checkChallengeIsLeaning( baseWeapon );
}

processWeaponClassChallenge_Shotgun( baseWeapon, data )	// self == player
{
	// self processChallenge( "ch_shotgun_kill" );
	
	self processChallenge( "ch_" + baseWeapon );
	
	// crouch
	if ( self GetStance() == "crouch" )
	{
		self processChallenge( "ch_" + baseWeapon + "_crouch" );
	}
	
	// assists must be tracked elsewhere, this is for kills only
	
	// aka rescuer!
	self checkChallengeKillModifier( data, "defender", baseWeapon );
	
	// no attachments
	if ( weaponGetNumAttachments( data.sWeapon ) == 0 )
	{
		self processChallenge( "ch_" + baseWeapon + "_noattach" );
	}
	
	// hip fire kills
	if ( !self isPlayerAds() )
	{
		self processChallenge( "ch_" + baseWeapon + "_hipfire" );
	}
	
	// consecutive kills
	self checkConsecutiveChallenge( data.sWeapon, baseWeapon );
	
	// point blank
	self checkChallengeKillModifier( data, "pointblank", baseWeapon );
	
	// kills within X secs of reload
	if ( self hasReloadedRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_reload" );
	}
	
	// sliding
	if ( self playerSprintSlidRecently() )
	{
		self processChallenge( "ch_" + baseWeapon + "_sliding" );
	}
	
	// head shot
	self checkChallengeKillModifier( data, "headshot", baseWeapon );
}

processWeaponClassChallenge_RiotShield( baseWeapon, data )	// self == player
{
	// need to be detected elsewhere?
	// pistol kills
	// c4 kills
	// throwing knife kills
	// assists must be tracked elsewhere, this is for kills only
	
	// TODO Back smasher
	// self processChallenge( "ch_riot_kill" );
	
	self processChallenge( "ch_" + baseWeapon );
	
	// crouch
	if ( self GetStance() == "crouch" )
	{
		self processChallenge( "ch_" + baseWeapon + "_crouch" );
	}
	
	// consecutive kills
	if ( self checkNumUsesOfPersistentData( "shieldKillStreak", CONSECUTIVE_KILL_INTERVAL ) )
	{
		// formerly called ch_smasher
		self processChallenge( "ch_" + baseWeapon + "_consecutive" );
	}
	
	// check no perks
	if ( self hasNoPerks() )
	{
		self processChallenge( "ch_" + baseWeapon + "_noperks" );
	}
}

checkChallengeKillModifier( killData, modifierName, challengeName )
{
	if ( IsDefined( killData.modifiers[modifierName] ) )
	{
		self processChallenge( "ch_" + challengeName + "_" + modifierName );
	}
}

checkChallengeIsLeaning( challengeName )	// self == player
{
	if ( self isLeaning() )
	{
		self processChallenge( "ch_" + challengeName + "_leaning" );
	}
}

checkPenetrationChallenge( victim, challengeName )	// self == player
{
	if ( victim.iDFlags & level.iDFLAGS_PENETRATION )
	{
		self processChallenge( "ch_" + challengeName + "_penetrate" );
	}
}

checkConsecutiveChallenge( weaponName, challengeName )	// self == player
{
	kills = self.killsThisLifePerWeapon[ weaponName ];
	if ( IsDefined( kills ) 
	    && isNumberMultipleOf( kills, CONSECUTIVE_KILL_INTERVAL )
	   )
	{
		self processChallenge( "ch_" + challengeName + "_consecutive" );
	}
}

checkWasLastWeaponRiotShield()	// self == player
{
	curWeapon = self GetCurrentWeapon();
	
	if ( maps\mp\gametypes\_weapons::isRiotShield( curWeapon ) )
	{
		return true;
	}
	else
	{
		lastWeapon = self getLastWeapon();	// check against current weapon too
		return ( maps\mp\gametypes\_weapons::isRiotShield( lastWeapon ) );
	}
}

checkAAChallenges( attacker, victim, weapon )
{
	// log traps in prison break don't send the right weapon?
	if ( IsDefined( weapon ) )
	{
		// OP_IW6 Shooting Star - kill aircraft with loki
		if ( IsDefined( level.odinSettings )
		    && IsDefined( level.odinSettings[ "odin_assault" ] )
		    && ( weapon == level.odinSettings[ "odin_assault" ].weapon[ "large_rod" ].projectile || weapon == level.odinSettings[ "odin_assault" ].weapon[ "small_rod" ].projectile )
		   )
		{
			attacker processChallenge( "ch_shooting_star" ); 
			return true;
		}
		// OP_IW6 Two missiles, one launcher - kill aircraft with MAAWS
		else if ( weaponMap( weapon ) == "iw6_maaws_mp" )
		{
			attacker processChallenge( "ch_aa_launcher" );
		}
		// OP_IW6 Air superiority - shoot down aircraft with aa
		else if ( weapon == "aamissile_projectile_mp" )
		{
			// do not confuse this with ch_airsuperiority, the battle hind challenge
			attacker processChallenge( "ch_air_superiority" );
		}
	}
	
	// OP_IW6 clear skies - just shoot down aircraft
	attacker maps\mp\gametypes\_missions::processChallenge( "ch_clearskies" );
	
	return false;
}

checkChallengeExtraDeadly( weaponName )	// self == player
{
	if ( self shouldProcessChallengeForPerk( "specialty_extra_deadly" ) )
	{
		if ( weaponName == self.loadoutPerkEquipment )
		{
			self processChallenge( "ch_extra_deadly" );
		}
	}
}

// mp_fullbody_sniper_ab - full
// mp_body_elite_pmc_lmg_b
checkCostumeChallenge( victim, desiredName )
{
	// 2013-09-02 shouldn't be able to complete challenges against bots, but just a safety check
	if ( !IsAI( victim ) )
	{
		bodyIndex = victim maps\mp\gametypes\_teams::getPlayerModelIndex();
		bodyName = victim maps\mp\gametypes\_teams::getPlayerModelName( bodyIndex );
		return ( bodyName == desiredName );
	}
	
	return false;
}

hasReloadedRecently()	// self == player
{
	return ( IsDefined( self.reloadTimeStamp ) && GetTime() < self.reloadTimeStamp );
}

processChallengeForTeam( challengeName, team )
{
	foreach( player in level.players )
	{
		if ( player.team == team )
		{
			player processChallenge( challengeName );
		}
	}
}

/*
============= 
///ScriptDocBegin
"Name: allowKillChallengeForKillstreak( player, weaponName)"
"Summary: Checks if we should allow this killstreak to do normal challenge processing in ch_kill based on the attacker and killing weapon
"Module: missions"
"Example: if( allowKillChallengeForKillstreak( attacker, "iw6_knifeonlyjugg_mp" );
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/

allowKillChallengeForKillstreak( player, weaponName )
{
	if ( player isJuggernaut() )
		return true;
	else if ( weaponName == "ims_projectile_mp" )	// allow IMS to pass through to danger close op
		return true;
	
	return false;
}

checkNumUsesOfPersistentData( keyName, targetNum )	// self == player
{
	numUses  = self.pers[keyName];
	return isNumberMultipleOf( numUses, targetNum );
}

/*
============= 
///ScriptDocBegin
"Name: isNumberMultipleOf
"Summary: returns true if number is an exact multiple factor
"Module: missions"
"Example: if ( isNumberMultipleOf( numKills, 5 ) )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
isNumberMultipleOf( number, factor )
{
	return ( number > 0 && number % factor == 0 );
}

hasNoPerks()
{
	if ( IsDefined( self.pers[ "loadoutPerks" ] ) )
	{
		return ( self.pers[ "loadoutPerks" ].size == 0 );
	}
	
	return true;
}

fixBadOperationState( challengeName )	// self == player
{
	maxTiers = level.challengeInfo[challengeName]["targetval"].size;
	currentTier = ch_getState( challengeName );
	
	if ( currentTier > maxTiers + 1 )
	{
		ch_setState( challengeName, maxTiers );
		ch_setProgress( challengeName, 0 );
	}
}

fixAllBadOperations()
{
	self fixBadOperationState( "ch_atm" );
	self fixBadOperationState( "ch_breakbank" );
}
