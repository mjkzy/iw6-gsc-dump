#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

MIN_NUM_KILLS_GIVE_BONUS_PERKS = 8;
NUM_ABILITY_CATEGORIES = 7;
NUM_SUB_ABILITIES = 5;

KILLSTREAK_GIMME_SLOT = 0;
KILLSTREAK_SLOT_1 = 1;
KILLSTREAK_SLOT_2 = 2;
KILLSTREAK_SLOT_3 = 3;
KILLSTREAK_BONUS_PERKS_SLOT = 4;
KILLSTREAK_STACKING_START_SLOT = 5;

initKillstreakData()
{
	for ( i = 1; true; i++ )
	{
		retVal = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].ref_col );
		if ( !IsDefined( retVal ) || retVal == "" )
			break;

		streakRef = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].ref_col );
		assert( streakRef != "" );

		streakUseHint = TableLookupIString( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].earned_hint_col );
		assert( streakUseHint != &"" );

		streakEarnDialog = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].earned_dialog_col );
		assert( streakEarnDialog != "" );
		game["dialog"][ streakRef ] = streakEarnDialog;

		streakAlliesUseDialog = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].allies_dialog_col );
		assert( streakAlliesUseDialog != "" );
		game["dialog"][ "allies_friendly_" + streakRef + "_inbound" ] = "friendly_" + streakAlliesUseDialog;
		game["dialog"][ "allies_enemy_" + streakRef + "_inbound" ] = "enemy_" + streakAlliesUseDialog;

		streakAxisUseDialog = TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].enemy_dialog_col );
		assert( streakAxisUseDialog != "" );
		game["dialog"][ "axis_friendly_" + streakRef + "_inbound" ] = "friendly_" + streakAxisUseDialog;
		game["dialog"][ "axis_enemy_" + streakRef + "_inbound" ] = "enemy_" + streakAxisUseDialog;

		streakPoints = int( TableLookup( level.global_tables[ "killstreakTable" ].path, level.global_tables[ "killstreakTable" ].index_col, i, level.global_tables[ "killstreakTable" ].score_col ) );
		assert( streakPoints != 0 );
		maps\mp\gametypes\_rank::registerScoreInfo( "killstreak_" + streakRef, streakPoints );
	}
}


onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		
		if( !IsDefined ( player.pers[ "killstreaks" ] ) )
			player.pers[ "killstreaks" ] = [];

		if( !IsDefined ( player.pers[ "kID" ] ) )
			player.pers[ "kID" ] = 10;

		//if( !IsDefined ( player.pers[ "kIDs_valid" ] ) )
		//	player.pers[ "kIDs_valid" ] = [];
		
		player.lifeId = 0;
		player.curDefValue = 0;
			
		if ( IsDefined( player.pers["deaths"] ) )
			player.lifeId = player.pers["deaths"];

		player VisionSetMissilecamForPlayer( game["thermal_vision"] );	
	
		player thread onPlayerSpawned();
		player thread monitorDisownKillstreaks();
	
		player.spUpdateTotal = 0;
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );
	
	if ( is_aliens() ) //don't do this for Aliens
		return;

	for ( ;; )
	{
		self waittill( "spawned_player" );			
		
		self thread killstreakUseWaiter();
		self thread waitForChangeTeam();		
		
		// these three threads need to be run regardless of the streak type because you could switch during the grace period from specialist to assault or support and not be able to toggle up/down
		self thread streakSelectUpTracker();
		self thread streakSelectDownTracker();
		
		if( level.console )
		{
			self thread streakUseTimeTracker();
		}
		else
		{
			// pc doesn't do killstreak selections, just a single button press
			self thread pc_watchStreakUse();
			// they could be on pc but using a game pad, we need to monitor that
			self thread pc_watchGamepad();
		}
		self thread streakNotifyTracker();	

		if ( !IsDefined( self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ] ) )
			self initPlayerKillstreaks();
		if ( !IsDefined( self.earnedStreakLevel ) )
			self.earnedStreakLevel = 0;
		// we want to reset the adrenaline back to what it was for round based games
		// we reset the adrenaline on first connect in playerlogic and if they are in the game until the end
		// 2014-01-24 wallace: in CL 656322, .adrenaline is always initialized for MLG purposes, so we can't count it being undefined any more
		if( game["roundsPlayed"] > 0 && self.adrenaline == 0 )
		{
			self.adrenaline = self GetCommonPlayerData( "killstreaksState", "count" );
		}
		// if we reset stats then countToNext will be 0 and no bars will show until you kill someone
		// this also means the first time someone plays the game they won't see bars, so we need to set it
		//if( self.adrenaline == self GetCommonPlayerData( "killstreaksState", "countToNext" ) )
		{
			self setStreakCountToNext();
			self updateStreakSlots();
		}

		if ( self.streakType == "specialist" )
			self updateSpecialistKillstreaks();
		else
			self giveOwnedKillstreakItem();
	}
}

initPlayerKillstreaks()
{
	// this IsDefined check keeps the clearkillstreaks call when we quit the game without selecting a class, from erroring out
	if( !IsDefined( self.streakType ) )
		return;

	if ( self.streakType == "specialist" )
		self setCommonPlayerData( "killstreaksState", "isSpecialist", true );
	else
		self setCommonPlayerData( "killstreaksState", "isSpecialist", false );
	
	// gimme slot is where care package items and special given items go
	// we want the gimme slot to be stackable so we don't lose killstreaks when we pick another up
	// so we'll make index 0 be a pointer of sorts to show where the next usable killstreak is in the killstreak array
	self_pers_killstreaks_gimme_slot = spawnStruct(); 
	self_pers_killstreaks_gimme_slot.available = false;
	self_pers_killstreaks_gimme_slot.streakName = undefined;
	self_pers_killstreaks_gimme_slot.earned = false;
	self_pers_killstreaks_gimme_slot.awardxp = undefined;
	self_pers_killstreaks_gimme_slot.owner = undefined;
	self_pers_killstreaks_gimme_slot.kID = undefined;
	self_pers_killstreaks_gimme_slot.lifeId = undefined;
	self_pers_killstreaks_gimme_slot.isGimme = true;
	self_pers_killstreaks_gimme_slot.isSpecialist = false;
	self_pers_killstreaks_gimme_slot.nextSlot = undefined;
	self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ] = self_pers_killstreaks_gimme_slot;

	// reserved for each killstreak whether they have them or not
	for( i = 1; i < KILLSTREAK_BONUS_PERKS_SLOT; i++ )
	{
		self_pers_killstreaks_i = spawnStruct();
		
		self_pers_killstreaks_i.available = false;
		self_pers_killstreaks_i.streakName = undefined;
		self_pers_killstreaks_i.earned = true;
		self_pers_killstreaks_i.awardxp = 1;
		self_pers_killstreaks_i.owner = undefined;
		self_pers_killstreaks_i.kID = undefined;
		self_pers_killstreaks_i.lifeId = -1;
		self_pers_killstreaks_i.isGimme = false;
		self_pers_killstreaks_i.isSpecialist = false;
		self.pers["killstreaks"][ i ] = self_pers_killstreaks_i;
	}

	// reserved for specialist all perks bonus
	self_pers_killstreaks_bonus_perks_slot = spawnStruct();
	
	self_pers_killstreaks_bonus_perks_slot.available = false;
	self_pers_killstreaks_bonus_perks_slot.streakName = "all_perks_bonus";
	self_pers_killstreaks_bonus_perks_slot.earned = true;
	self_pers_killstreaks_bonus_perks_slot.awardxp = 0;
	self_pers_killstreaks_bonus_perks_slot.owner = undefined;
	self_pers_killstreaks_bonus_perks_slot.kID = undefined;
	self_pers_killstreaks_bonus_perks_slot.lifeId = -1;
	self_pers_killstreaks_bonus_perks_slot.isGimme = false;
	self_pers_killstreaks_bonus_perks_slot.isSpecialist = true;
	self.pers["killstreaks"][ KILLSTREAK_BONUS_PERKS_SLOT ] = self_pers_killstreaks_bonus_perks_slot;

	// init all of the icons to 0 in case the player hasn't selected all 3 streaks
	//	also init the hasStreak to false
	for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		self setCommonPlayerData( "killstreaksState", "icons", i, 0 );
		self setCommonPlayerData( "killstreaksState", "hasStreak", i, false );
	}
	self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_GIMME_SLOT, false );
	
	index = 1;
	foreach ( streakName in self.killstreaks )
	{
		self_pers_killstreaks_index = self.pers["killstreaks"][index];
		self_pers_killstreaks_index.streakName = streakName;
		self_pers_killstreaks_index.isSpecialist = ( self.streakType == "specialist" );	
		
		killstreakIndexName = self_pers_killstreaks_index.streakName;
		// if specialist then we need to check to see if they have the pro version of the perk and get that icon
		if( self.streakType == "specialist" )
		{
			perkTokens = StrTok( self_pers_killstreaks_index.streakName, "_" );
			if( perkTokens[ perkTokens.size - 1 ] == "ks" )
			{
				perkName = undefined;
				foreach( token in perkTokens )
				{
					if( token != "ks" )
					{
						if( !IsDefined( perkName ) )
							perkName = token;
						else
							perkName += ( "_" + token );
					}
				}

				// blastshield has an _ at the beginning
				if( isStrStart( self_pers_killstreaks_index.streakName, "_" ) )
					perkName = "_" + perkName;

				if( IsDefined( perkName ) && self maps\mp\gametypes\_class::getPerkUpgrade( perkName ) != "specialty_null" )
					killstreakIndexName = self_pers_killstreaks_index.streakName + "_pro";
			}
		}

		self setCommonPlayerData( "killstreaksState", "icons", index, getKillstreakIndex( killstreakIndexName ) );
		self setCommonPlayerData( "killstreaksState", "hasStreak", index, false );
		
		index++;	
	}

	self setCommonPlayerData( "killstreaksState", "nextIndex", 1 );		
	self setCommonPlayerData( "killstreaksState", "selectedIndex", -1 );
	self setCommonPlayerData( "killstreaksState", "numAvailable", 0 );

	// specialist shows one more icon
	self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_BONUS_PERKS_SLOT, false );
}

updateStreakCount()
{
	if ( !IsDefined( self.pers["killstreaks"] ) )
		return;	
	if ( self.adrenaline == self.previousAdrenaline )
		return;	

	curCount = self.adrenaline;
	
	self setCommonPlayerData( "killstreaksState", "count", self.adrenaline );
		
	if ( self.adrenaline >= self getCommonPlayerData( "killstreaksState", "countToNext" ) )
		self setStreakCountToNext();		
}

resetStreakCount()
{
	self setCommonPlayerData( "killstreaksState", "count", 0 );
	self setStreakCountToNext();
}

setStreakCountToNext()
{
	// this IsDefined check keeps the resetadrenaline call when we first connect in playerlogic, from erroring out
	if( !IsDefined( self.streakType ) )
	{
		// if they have no streak then count to next should be zero
		self setCommonPlayerData( "killstreaksState", "countToNext", 0 );
		return;
	}

	// if they have no killstreaks
	if( self getMaxStreakCost() == 0 )
	{
		self setCommonPlayerData( "killstreaksState", "countToNext", 0 );
		return;
	}

	// specialist but have maxed out
	if( self.streakType == "specialist" )
	{
		if( self.adrenaline >= self getMaxStreakCost() )
			return;
	}

	// set the next streaks cost
	nextStreakName = getNextStreakName();
	if ( !IsDefined( nextStreakname ) )
		return;
	nextStreakCost = getStreakCost( nextStreakName );
	self setCommonPlayerData( "killstreaksState", "countToNext", nextStreakCost );
}

getNextStreakName()
{
	if ( self.adrenaline == self getMaxStreakCost() && ( self.streakType != "specialist" ) )
	{
		adrenaline = 0;
	}
	else
	{
		adrenaline = self.adrenaline;
	}
	
	foreach ( streakName in self.killstreaks )
	{
		streakVal = self getStreakCost( streakName );	
		
		if ( streakVal > adrenaline )
		{					
			return streakName;
		}
	}	
	return undefined;
}

getMaxStreakCost()
{
	maxCost = 0;
	foreach ( streakName in self.killstreaks )
	{
		streakVal = self getStreakCost( streakName );	
		
		if ( streakVal > maxCost )	
		{
			maxCost = streakVal;
		}
	}	
	return maxCost;
}

updateStreakSlots()
{
	// this IsDefined check keeps the clearkillstreaks call when we quit the game without selecting a class, from erroring out
	if( !IsDefined( self.streakType ) )
		return;

	if ( !isReallyAlive(self) )
		return;
	
	self_pers_killstreaks = self.pers["killstreaks"];

	//	what's available?
	numStreaks = 0;
	for( i = 0; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		if( IsDefined( self_pers_killstreaks[i] ) && IsDefined( self_pers_killstreaks[i].streakName ) )
		{
			self setCommonPlayerData( "killstreaksState", "hasStreak", i, self_pers_killstreaks[i].available );	
			if ( self_pers_killstreaks[i].available == true )
				numStreaks++;	
			
			if( IsDefined(level.removeKillStreakIcons) && level.removeKillStreakIcons && !self_pers_killstreaks[i].available )
				self setCommonPlayerData( "killstreaksState", "icons", i, 0 );			
		}	
	}	
	if ( self.streakType != "specialist" )
		self setCommonPlayerData( "killstreaksState", "numAvailable", numStreaks );
	
	//	next to earn
	minLevel = self.earnedStreakLevel;
	maxLevel = self getMaxStreakCost();
	if ( self.earnedStreakLevel == maxLevel && self.streakType != "specialist" )
		minLevel = 0;
			
	nextIndex = 1;
	
	foreach ( streakName in self.killstreaks )
	{
		streakVal = self getStreakCost( streakName );	
		
		if ( streakVal > minLevel )	
		{
			nextStreak = streakName;
			break;
		}

		// for specialsit we don't want the next index to go above the max
		if( self.streakType == "specialist" )
		{
			if( self.earnedStreakLevel == maxLevel )
				break;
		}

		nextIndex++;
	} 
	
	self setCommonPlayerData( "killstreaksState", "nextIndex", nextIndex );	
	
	//	selected index
	if ( IsDefined( self.killstreakIndexWeapon ) && ( self.streakType != "specialist" ) )
	{
		self setCommonPlayerData( "killstreaksState", "selectedIndex", self.killstreakIndexWeapon );
	}
	else
	{
		if( self.streakType == "specialist" && self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].available )
			self setCommonPlayerData( "killstreaksState", "selectedIndex", 0 );	
		else
			self setCommonPlayerData( "killstreaksState", "selectedIndex", -1 );	
	}
}


waitForChangeTeam()
{
	self endon ( "disconnect" );
	self endon( "faux_spawn" );
	
	self notify ( "waitForChangeTeam" );
	self endon ( "waitForChangeTeam" );
	
	for ( ;; )
	{
		self waittill ( "joined_team" );
		clearKillstreaks();
	}
}

killstreakUsePressed()
{
	self_pers_killstreaks = self.pers["killstreaks"];
	
	streakName = self_pers_killstreaks[self.killstreakIndexWeapon].streakName;
	lifeId = self_pers_killstreaks[self.killstreakIndexWeapon].lifeId;
	isEarned = self_pers_killstreaks[self.killstreakIndexWeapon].earned;
	awardXp = self_pers_killstreaks[self.killstreakIndexWeapon].awardXp;
	kID = self_pers_killstreaks[self.killstreakIndexWeapon].kID;
	isGimme = self_pers_killstreaks[self.killstreakIndexWeapon].isGimme;

	if( !self validateUseStreak() )
		return false;

	////	Balance for anyone using the explosive ammo killstreak, remove it when they activate the next killstreak
	//removeExplosiveAmmo = false;
	//if ( self _hasPerk( "specialty_explosivebullets" ) && !issubstr( streakName, "explosive_ammo" ) )
	//	removeExplosiveAmmo = true;

	if ( !self [[ level.killstreakFuncs[ streakName ] ]]( lifeId, streakName ) )
	  return ( false );
	
/#
	// let test client bots (not AI bots) use the full functionality of the killstreak usage	
	if( !IsBot( self ) && IsDefined( self.pers[ "isBot" ] ) && self.pers[ "isBot" ] )
		return true;
#/

	////	Balance for anyone using the explosive ammo killstreak, remove it when they activate the next killstreak
	//if ( removeExplosiveAmmo )
	//	self _unsetPerk( "specialty_explosivebullets" );
	
	self thread updateKillstreaks();
	self usedKillstreak( streakName, awardXp );

	//// NOTE: match leveling prototype
	////	clear the active killstreak bonus after use, this keeps it from being given back after death if nothing else has been earned
	//if( IsDefined( self.pers[ "activeKillstreakBonuses" ][0] ) )
	//	self.pers[ "activeKillstreakBonuses" ][0] = undefined;

	return ( true );
}


usedKillstreak( streakName, awardXp )
{	
	if ( awardXp )
	{
		self thread [[ level.onXPEvent ]]( "killstreak_" + streakName );
		self thread maps\mp\gametypes\_missions::useHardpoint( streakName );
	}
	
	awardref = maps\mp\_awards::getKillstreakAwardRef( streakName );
	if ( IsDefined( awardref ) )
		self thread incPlayerStat( awardref, 1 );

	if( isAssaultKillstreak( streakName ) )
	{
		self thread incPlayerStat( "assaultkillstreaksused", 1 );
	}
	else if( isSupportKillstreak( streakName ) )
	{
		self thread incPlayerStat( "supportkillstreaksused", 1 );
	}
	else if( isSpecialistKillstreak( streakName ) )
	{
		self thread incPlayerStat( "specialistkillstreaksearned", 1 );
		// no need to play specialist because we do leader dialog on the player with killstreakSplashNotify() and not just team specific things
		return;
	}

	// play killstreak dialog
	team = self.team;
	if ( level.teamBased )
	{
		thread leaderDialog( team + "_friendly_" + streakName + "_inbound", team );
		
		if ( getKillstreakEnemyUseDialog( streakName ) )
		{		
			if ( self playEnemyDialog( streakName ) )
				thread leaderDialog( team + "_enemy_" + streakName + "_inbound", level.otherTeam[ team ] );
		}
	}
	else
	{
		self thread leaderDialogOnPlayer( team + "_friendly_" + streakName + "_inbound" );
		
		if ( getKillstreakEnemyUseDialog( streakName ) )
		{
			excludeList[0] = self;
			
			if ( self playEnemyDialog( streakName ) )
				thread leaderDialog( team + "_enemy_" + streakName + "_inbound", undefined, undefined, excludeList );
		}
	}
}

playEnemyDialog( streakName )
{
	// self == player 
	
	// Only for multiplayer sat com usage
	if ( !is_aliens() )
	{	
		// Only play the enemy dialog for Sat Coms, if it's the only one in existence
		if ( level.teamBased && streakName == "uplink" && [[level.comExpFuncs[ "getRadarStrengthForTeam" ]]]( self.team ) != 1 )
			return false;
			
		// FFA uplink strength starts at 2
		else if ( !level.teamBased && streakName == "uplink" && [[level.comExpFuncs[ "getRadarStrengthForPlayer" ]]]( self ) != 2 )
			return false;
	}
	
	// For all other killstreaks / situations
	return true;
}

updateKillstreaks( keepCurrent )
{
	// early exit for when you give bots a killstreak to use
	if( IsAI( self ) && !IsDefined( self.killstreakIndexWeapon ) )
		return;
	
	if ( !IsDefined( keepCurrent ) )
	{
		self.pers["killstreaks"][self.killstreakIndexWeapon].available = false;
	
		// if this is the gimme slot and we still have some stacked then leave available and set the new icon
		if( self.killstreakIndexWeapon == KILLSTREAK_GIMME_SLOT )
		{
			// if this is the gimme slot then clear the last used stacked killstreak before updating killstreaks
			self.pers["killstreaks"][ self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].nextSlot ] = undefined;		

			// loop through the stacked killstreaks and find the next available one
			streakName = undefined;
			kID = undefined;
			self_pers_killstreaks = self.pers["killstreaks"];
			for( i = KILLSTREAK_STACKING_START_SLOT; i < self_pers_killstreaks.size; i++ )
			{
				if( !IsDefined( self_pers_killstreaks[i] ) || !IsDefined( self_pers_killstreaks[i].streakName ) )
					continue;

				streakName = self_pers_killstreaks[i].streakName;
				kID = self_pers_killstreaks[i].kID;
				self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].nextSlot = i;
			}
			
			if( IsDefined( streakName ) )
			{
				self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].available = true;
				self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].streakName = streakName;
				self_pers_killstreaks[ KILLSTREAK_GIMME_SLOT ].kID = kID;

				streakIndex = getKillstreakIndex( streakName );	
				self setCommonPlayerData( "killstreaksState", "icons", KILLSTREAK_GIMME_SLOT, streakIndex );

				// pc need to put this new one in the actionslot for use
				if( !level.console && !self is_player_gamepad_enabled() )
				{
					killstreakWeapon = getKillstreakWeapon( streakName );
					_setActionSlot( 4, "weapon", killstreakWeapon );	
				}
			}
		}
	}
	
	//	find the highest remaining streak and select it
	highestStreakIndex = undefined;
	if( self.streakType == "specialist" )
	{
		if ( self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].available )
			highestStreakIndex = KILLSTREAK_GIMME_SLOT;
	}	
	else
	{
		for ( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			self_pers_killstreaks_i = self.pers["killstreaks"][i];
			if( IsDefined( self_pers_killstreaks_i ) && 
				IsDefined( self_pers_killstreaks_i.streakName ) &&
				self_pers_killstreaks_i.available )
			{
				highestStreakIndex = i;
			}
		}
	}

	if ( IsDefined( highestStreakIndex ) )
	{
		if( level.console || self is_player_gamepad_enabled() )
		{
			self.killstreakIndexWeapon = highestStreakIndex;
			self.pers["lastEarnedStreak"] = self.pers["killstreaks"][highestStreakIndex].streakName;

			self giveSelectedKillstreakItem();			
		}
		// pc doesn't select killstreaks
		else
		{
			// make sure we still have all of the available killstreak weapons, things like the airdrop will get taken if you have more than one
			for ( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
			{
				self_pers_killstreaks_i = self.pers["killstreaks"][i];
				if( IsDefined( self_pers_killstreaks_i ) && 
					IsDefined( self_pers_killstreaks_i.streakName ) &&
					self_pers_killstreaks_i.available )
				{
					killstreakWeapon = getKillstreakWeapon( self_pers_killstreaks_i.streakName );
					weaponsListItems = self GetWeaponsListItems();
					hasKillstreakWeapon = false;
					for( j = 0; j < weaponsListItems.size; j++ )
					{
						if( killstreakWeapon == weaponsListItems[j] )
						{
							hasKillstreakWeapon = true;
							break;
						}
					}

					if( !hasKillstreakWeapon )
					{
						self _giveWeapon( killstreakWeapon );
					}
					else
					{
						// if we have more than one airdrop type weapon the ammo gets set to 0 because we give the next airdrop weapon before we take the last one
						//	this is a quicker fix than trying to figure out how to take and give at the right times
						if( IsSubStr( killstreakWeapon, "airdrop_" ) )
							self SetWeaponAmmoClip( killstreakWeapon, 1 );
					}

					// we should re-set the action slot just to make sure everything is correct (juggernaut needs this or they won't be able to use their killstreaks once obtained because we clear the action slots in giveLoadout())
					self _setActionSlot( i + 4, "weapon", killstreakWeapon );
				}
			}

			self.killstreakIndexWeapon = undefined;
			self.pers["lastEarnedStreak"] = self.pers["killstreaks"][highestStreakIndex].streakName;
			self updateStreakSlots();
		}
	}
	else
	{
		self.killstreakIndexWeapon = undefined;
		self.pers["lastEarnedStreak"] = undefined;
		self updateStreakSlots();

		// NOTE: we used to take item weapons from the player here but that stopped killstreak weapon animations from playing if it was the only killstreak
		//		since we take the item weapons when we give a killstreak weapon anyways, no need to do that here
		//		we've also added the waitTakeKillstreakWeapon() function to take them when appropriate
		// VERY IMPORTANT: with the current system, we NEVER want to loop and take all weapon list items
	}
}

clearKillstreaks()
{
	self_pers_killstreaks = self.pers["killstreaks"];
	if( !IsDefined(self_pers_killstreaks) )
		return;
	
	for( i = self_pers_killstreaks.size - 1; i > -1; i-- )
	{
		self.pers["killstreaks"][i] = undefined;
	}		
	
	initPlayerKillstreaks();
		
	self resetAdrenaline();
	self.killstreakIndexWeapon = undefined;
	self updateStreakSlots();
}

updateSpecialistKillstreaks()
{
	// reset if no adrenaline
	if( self.adrenaline == 0 )
	{
		for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			if( IsDefined( self.pers["killstreaks"][i] ) )
			{
				self.pers["killstreaks"][i].available = false;
				self setCommonPlayerData( "killstreaksState", "hasStreak", i, false );
			}
		}
		self setCommonPlayerData( "killstreaksState", "nextIndex", 1 );
		self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_BONUS_PERKS_SLOT, false );
	}
	else
	{
		// loop through each earnable killstreak
		for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			self_pers_killstreaks_i = self.pers["killstreaks"][i];
			if( IsDefined( self_pers_killstreaks_i ) && 
				IsDefined( self_pers_killstreaks_i.streakName ) &&
				self_pers_killstreaks_i.available )
			{
				streakVal = getStreakCost( self_pers_killstreaks_i.streakName );
				if( streakVal > self.adrenaline )
				{
					// reset them because we're going to check them again and set them
					self.pers["killstreaks"][i].available = false;
					self setCommonPlayerData( "killstreaksState", "hasStreak", i, false );
					continue;
				}

				if( self.adrenaline >= streakVal )
				{
					// no need to give this again if we've already got it, this fixes a bug where all of the achieved sounds play as you enter the next round
					//	this also fixes a possibility of getting credit for getting another set of this killstreak in your player stats
					if( self getCommonPlayerData( "killstreaksState", "hasStreak", i ) )
					{
						// just call the killstreak function so we give the specialist perk back to the player each round
						self [[ level.killstreakFuncs[ self_pers_killstreaks_i.streakName ] ]]( undefined, self_pers_killstreaks_i.streakName );
						
						continue;
					}
					
					self giveKillstreak( self_pers_killstreaks_i.streakName, self_pers_killstreaks_i.earned, false, self );
				}
			}
		}

		// at a certain number of kills we'll give you bonus perks
		specialist_max_kills = self getMaxStreakCost();;
		if ( isAI( self ) )
			specialist_max_kills = self.pers["specialistStreakKills"][2];
		numKills = int( max( MIN_NUM_KILLS_GIVE_BONUS_PERKS, ( specialist_max_kills + 2 ) ) );
		if( self _hasPerk( "specialty_hardline" ) )
			numKills--;

		if( self.adrenaline >= numKills )
		{
			self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_BONUS_PERKS_SLOT, true );
			self giveBonusPerks();
		}
		else
			self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_BONUS_PERKS_SLOT, false );
	}

	// update gimme slot killstreak regardless
	if ( self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].available )
	{
		streakName = self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].streakName;
		killstreakWeapon = getKillstreakWeapon( streakName );
		
		if( level.console || self is_player_gamepad_enabled() )
		{
			self giveKillstreakWeapon( killstreakWeapon );		
			self.killstreakIndexWeapon = KILLSTREAK_GIMME_SLOT;		
		}
		else
		{
			self _giveWeapon( killstreakWeapon );
			self _setActionSlot( 4, "weapon", killstreakWeapon );
			self.killstreakIndexWeapon = undefined;		
		}
	}
}

getFirstPrimaryWeapon()
{
	weaponsList = self getWeaponsListPrimaries();
	
	assert ( IsDefined( weaponsList[0] ) );
	// the juggernaut primary weapon is a killstreak weapon so we shouldn't assert for killstreak weapons
	//assert ( !isKillstreakWeapon( weaponsList[0] ) );

	return weaponsList[0];
}

isTryingToUseKillstreakInGimmeSlot()
{
	return IsDefined( self.tryingToUseKS ) && self.tryingToUseKS && IsDefined( self.killstreakIndexWeapon ) && self.killstreakIndexWeapon == 0;
}

isTryingToUseKillstreakSlot()
{
	return IsDefined( self.tryingToUseKS ) && self.tryingToUseKS && IsDefined( self.killstreakIndexWeapon );
}

waitForKillstreakWeaponSwitchStarted()
{
	self endon( "weapon_switch_invalid" );
	
	self waittill( "weapon_switch_started", newWeapon );	
	self notify( "killstreak_weapon_change", "switch_started", newWeapon );
}

waitForKillstreakWeaponSwitchInvalid()
{
	self endon( "weapon_switch_started" );
	
	self waittill( "weapon_switch_invalid", invalidWeapon );	
	self notify( "killstreak_weapon_change", "switch_invalid", invalidWeapon );
}

waitForKillstreakWeaponChange()
{
	self childthread waitForKillstreakWeaponSwitchStarted();
	self childthread waitForKillstreakWeaponSwitchInvalid();
	
	self waittill( "killstreak_weapon_change", result, weapon );
	
	if ( result == "switch_started" )
		return weapon;
	
	// caused by client server mistmatch where the client selects a killstreak that is no longer in his inventory
	assert( result == "switch_invalid" );
	assert( isTryingToUseKillstreakSlot() );
	
	killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName );
	
	PrintLn( "Invalid killstreak weapon switch: " + weapon + ". Forcing switch to " + killstreakWeapon + " instead." );
	
	self SwitchToWeapon( killstreakWeapon );
	
	waittillframeend;
	
	newWeapon = undefined;
	if ( IsDefined( self.changingWeapon ) )
	{
		PrintLn( "changing weapon defined\n" );
		newWeapon = self.changingWeapon;
	}
	else
	{
		PrintLn( "waiting for weapon switch\n" );
		self waittill( "weapon_switch_started", newWeapon );
	}
	
	PrintLn( "Weapon switche started: " + newWeapon + "\n" );
	
	// player changed weapons while waiting for switch.
	if ( newWeapon != killstreakWeapon )
	{
		PrintLn( "Player switched weapons after script forced killstreak weapon. Skipping killstreak weapon change. " + newWeapon + " != " + killstreakWeapon );
		return undefined;
	}
	
	return killstreakWeapon;
}

killstreakUseWaiter()
{
	self endon( "disconnect" );
	self endon( "finish_death" );
	self endon( "joined_team" );
	self endon( "faux_spawn" );
	self endon( "spawned" );
	level endon( "game_ended" );
	
	self notify( "killstreakUseWaiter" );
	self endon( "killstreakUseWaiter" );

	self.lastKillStreak = 0;
	if ( !IsDefined( self.pers["lastEarnedStreak"] ) )
		self.pers["lastEarnedStreak"] = undefined;
		
	self thread finishDeathWaiter();

	// adding the notify array wait so we only do killstreak use stuff if the user presses to use it instead of always happening on weapon_change
	// this fixes an issue where you could pick up a juggernaut from a care package and get the weapon taken away
	notify_array = [ "streakUsed", "streakUsed1", "streakUsed2", "streakUsed3", "streakUsed4" ];
	while( true )
	{
		self.tryingToUseKS = undefined;
		notify_result = self waittill_any_in_array_return_no_endon_death( notify_array );
		self.tryingToUseKS = true;
		
		// try to ensure that we run after any thread that is changing self.killstreakIndexWeapon
		// this is particularly bad for PC, which uses pc_watchStreakUse to set that value, and they may get out of order if you use a KS, then immediately start sprinting
		waittillframeend;

		// we've pressed a streak used button, but there's no killstreak to use
		if ( !IsDefined( self.killstreakIndexWeapon )
		    || !IsDefined( self.pers["killstreaks"][self.killstreakIndexWeapon] )
		    || !IsDefined( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName ) )
		{
			continue;
		}
		
		// Special killstreak use check if the player is a custom juggernaut
		if ( !canCustomJuggUseKillstreak( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName ) )
		{
			printCustomJuggKillstreakErrorMsg();
			
			// fix 180771 - on PC, predator can be in a no-weapon state if he tries to use killstreaks
			if ( notify_result != "streakUsed" )	// this should only happen on keyboard
			{
				lastWeapon = self GetCurrentWeapon();
				self switch_to_last_weapon( lastWeapon );
			}
			
			continue;
		}		
		
		// corresponding to code change that we're no longer allowing player to 'queue up' a killstreak 
		// when they're cooking a grenade or holding up the underbarrel grenade launcher
		if( self IsOffhandWeaponReadyToThrow() )
			continue;
				
		// make sure we are switching to a KS weapon before we turn off weapon switches
		// self.changingWeapon is set by watchStartWeaponChange, so this is a safety check in case we have already missed the weapon_switch_started notify
		if ( IsDefined( self.changingWeapon ) )
		{
			newWeapon = self.changingWeapon;
		}
		else
		{
			self waittill( "weapon_switch_started", newWeapon );
		}
		killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName );
		if ( newWeapon != killstreakWeapon )
		{
			// it's possible, through a series of weapon switches and cancels, to get equip the killstreak weapon after this fail case and thus not run the killstreak logic
			// take the weapon away if that happens
			self thread removeUnitializedKillstreakWeapon();
			continue;
		}
		
		// 2013-09-20 wallace: Block weapon switch inputs once we've started the killstreak.
		// Addresses bugs like 124029, where players can get in a bad state if the player mashes weapon switch as the killstreak weapon is being raised.
		self beginKillstreakWeaponSwitch();
		
		// We want to switch to a killstreak weapon, but we haven't switched to it yet
		// ?? handles some weird ordering of notify issues that occur if you 
		// 1. give yourself a trinity rocket and equip juggernaut
		// 2. start sprinting
		// 3. use trinity rocket
		// 4. immediately start sprinting
		// 5. bug would leave player with laptop out, but wouldn't start ks
		if ( newWeapon != self GetCurrentWeapon() )
		{
			// !!! HACK 2013-10-19 wallace: because we client predict weapon switches, 
			// it is possible to use a KS and then quickly switch to another weapon and get stuck in a bad state. The timeout is a failsafe.
			// In IW7, we should let code handle these KS switches just like weapon switches
			self thread killstreakWaitForWeaponChange();
			result = self waittill_any_timeout_no_endon_death( 1.5, "ks_weapon_change", "ks_alt_weapon_change" );
			
			// if killstreak is activated while weapon is in alt mode, there will be an extra 'weapon_change'
			// notify that comes first which is the alt toggle change, skip this to wait for the actual weapon change
			if ( result == "ks_alt_weapon_change" )
			{
				self waittill( "weapon_change", newWeapon, isAltToggle );
			}
			else
			{
				newWeapon = self GetCurrentWeapon();
			}
		}
			
		if ( !IsAlive( self ) )
		{
			self endKillstreakWeaponSwitch();
			continue;
		}

		if ( newWeapon != killstreakWeapon )
		{
			// 2013-09-25 wallace: it's possible that the only thing we need to do inhere is endKillstreakWeaponSwitch
			// I don't want to rock the boat and change these juggernaut/heli sniper fixes
			// However, it leads to a bug if you call in a KS; host migrate as the weapon is lowered; then switch weapons after migration, you will see 2 weaon switches
			// since this weapon is not the killstreak we have selected, go back to the last weapon
			//	this fixes an issue where you could be pulling out a killstreak weapon at the same time that you earned a new killstreak
			//	the new killstreak would run giveKillstreak and change the killstreakIndexWeapon before the weapon_change event happens
			switch_to_weapon = self.lastdroppableweapon;
			if( isKillstreakWeapon( newWeapon ) )
			{
				// we need see if we're trying to go back to a juggernaut weapon, since they are killstreak weapons we fall into this
				//	this will fix an issue where you could be a juggernaut, call in a dog, call in a sat com, and get stuck with no weapon
				if( self isJuggernaut() && isJuggernautWeapon( newWeapon ) )
					switch_to_weapon = newWeapon;
				else if ( newWeapon == "iw6_gm6helisnipe_mp_gm6scope" )
					switch_to_weapon = newWeapon;
				else
					self TakeWeapon( newWeapon );
			}
			self SwitchToWeapon( switch_to_weapon );
			self endKillstreakWeaponSwitch();
			continue;
		}

		// Fix for infinite MAAWS and other killstreaks. See comment in
		// _weapons.gsc::watchWeaponChange() where KS_aboutToUse is
		// checked. 06/26/2014-JC
		self.KS_aboutToUse = true;
		waittillframeend;
		self.KS_aboutToUse = undefined;
		
		//	get this stuff now because self.killstreakIndexWeapon will change after killstreakUsePressed()
		streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;
		isGimme = self.pers["killstreaks"][self.killstreakIndexWeapon].isGimme;		
		
		assert( IsDefined( streakName ) );
		assert( IsDefined( level.killstreakFuncs[ streakName ] ) );		
		
		// We need to re-enable weapon switch once the KS weapon is equipped so that players can stow vest / maaws / airdrop / etc. to cancel its use
		self endKillstreakWeaponSwitch();
		result = self killstreakUsePressed();		
		self beginKillstreakWeaponSwitch();

		lastWeapon = self getLastWeapon();
		if ( !self HasWeapon( lastWeapon ) )
		{
			if ( isReallyAlive( self ) )
			{
				lastWeapon = self getFirstPrimaryWeapon();	
			}
			else
			{
				// - JC: 09/27/13 The previous logic assumed in the case of death that
				// the result would be false and the killstreak hadn't been used. In the
				// case of the MAAWS the player could die after firing all rockets and
				// so on death the killStreakUsePressed func would return true. Fix below:
				// If the player is not alive the last weapon may not be equipped. Insure
				// the player has a last weapon
				self _giveWeapon( lastWeapon );
			}
		}
		
		// we need to take the killstreak weapon away once we've switched back to our last weapon
		// this fixes an issue where you can call in a killstreak and then press right again to pull the killstreak weapon out
		if( result )
		{
			self thread waitTakeKillstreakWeapon( killstreakWeapon, lastWeapon );
		}

		//no force switching weapon for ridable killstreaks
		if ( shouldSwitchWeaponPostKillstreak( result, streakName ) )
		{
			self switch_to_last_weapon( lastWeapon );
		}
		
		// 2013-09-25 wallace: we need to renable weapon switches once the player has his gun back
		// some KS's, like airdrop and MAAWS, will auto switch for us, which the while statement checks for
		currentWeapon = self GetCurrentWeapon();
		while ( currentWeapon != lastWeapon )
		{
			self waittill( "weapon_change", currentWeapon );
		}
		
		self endKillstreakWeaponSwitch();
	}
}

removeUnitializedKillstreakWeapon()
{
	self notify( "removeUnitializedKillstreakWeapon" );
	self endon( "removeUnitializedKillstreakWeapon" );
	self endon( "death" );
	self endon( "disconnect" );
	
//	self endon( "weapon_switch_started" );
//	self endon( "weapon_switch_invalid" );
	
	self waittill( "weapon_change", weaponName );
	
	// If the player queues up an IED (or another cancellable equipment)
	// and then immediately cancels it by pressing Y and also presses right
	// on the d-pad to activate a killstreak code will only send one 
	// weapon_change_started notify for the switch back to the primary. This
	// means no weapon_change_started is sent for the killstreak. This causes the
	// player to end up with the killstreak without the killstreak management logic
	// getting started. Players can then use the killstreak without actually having
	// it subtracted from their inventory. To fix this make sure the player is
	// not holding a killstreak after the weapon_change without the killstreak
	// logic running. If they are, switch them to their last weapon.
	// 06/26/2014-JC
	
	weaponIsStreakInFocus =	IsDefined( self.killstreakIndexWeapon )
					&&	IsDefined( self.pers[ "killstreaks" ] )
					&&	IsDefined( self.pers[ "killstreaks" ][ self.killstreakIndexWeapon ] )
					&&	IsDefined( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName )
					&&	weaponName == getKillstreakWeapon( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName );
	
	if ( weaponIsStreakInFocus && !IsDefined( self.KS_aboutToUse ) )
	{
		// Take the weapon and reset the action slot so that the player can
		// call it in again.
		self TakeWeapon( weaponName );
		self _giveWeapon( weaponName, 0 );
		self _setActionSlot( 4, "weapon", weaponName );
		
		lastWeapon = self getLastWeapon();
		if ( !self HasWeapon( lastWeapon ) )
		{
			lastWeapon = self maps\mp\killstreaks\_killstreaks::getFirstPrimaryWeapon();
		}
		
		if ( IsDefined( lastWeapon ) )
		{
			self switch_to_last_weapon( lastWeapon );
		}
	}
}

beginKillstreakWeaponSwitch()
{
	self _disableWeaponSwitch();
	self _disableUsability();
	self thread killstreakWeaponSwitchWatchHostMigration();
}

endKillstreakWeaponSwitch()
{
	self notify( "endKillstreakWeaponSwitch" );
	self _enableWeaponSwitch();
	self _enableUsability();
}

killstreakWaitForWeaponChange()
{
	self waittill( "weapon_change", newWeapon, isAltMode );
	
	if ( !isAltMode )
	{
		self notify( "ks_weapon_change" );
	}
	else
	{
		self notify( "ks_alt_weapon_change" );
	}
}

// killstreakWeaponSwitchWatchHostMigration
// the host could migrate while we are pulling out or putting away a KS weapon (and we've disabled weapon switches)
// since this cancels the KS switching, renable weapon switches in
killstreakWeaponSwitchWatchHostMigration()
{
	self endon( "death" );
	level endon( "game_ended" );
	
	self endon( "endKillstreakWeaponSwitch" );
	
	level waittill( "host_migration_end" );
	// use the code call, instead of the wrapper, because we are in a bad state after host migration.
	// useKillstreakWaiter is waiting for a weapon_changed event; if we re-use our KS, everything's great
	// otherwise, that function will fail and call the _enableWeaponSwitch wrapper again
	if ( isDefined( self ) )
		self enableWeaponSwitch();
}

waitTakeKillstreakWeapon( killstreakWeapon, lastWeapon )
{
	self endon( "disconnect" );
	self endon( "finish_death" );
	self endon( "joined_team" );
	level endon( "game_ended" );

	self notify( "waitTakeKillstreakWeapon" );
	self endon( "waitTakeKillstreakWeapon" );

	// planted killstreaks like the sam, sentry, remote turret, and ims, will come in here with none as the current weapon sometimes because we _disableWeapons() while you carry them
	//	we need to know this so we can take the weapon correctly in these cases
	wasNone = ( self GetCurrentWeapon() == "none" );
	
	// this lets the killstreak weapon animation play and then take it once we switch away from it
	self waittill( "weapon_change", newWeapon );

	if( newWeapon == lastWeapon )
	{
		takeKillstreakWeaponIfNoDupe( killstreakWeapon );
		// pc needs to reset the killstreakIndexWeapon because we set this when they press the use button and we don't want the value lingering
		if( !level.console && !self is_player_gamepad_enabled() )
			self.killstreakIndexWeapon = undefined;
	}
	// this could happen with ridden killstreaks like the ac130
	else if( newWeapon != killstreakWeapon )
	{
		self thread waitTakeKillstreakWeapon( killstreakWeapon, lastWeapon );
	}
	// this could happen with planted killstreaks like the sam, sentry, remote turret, and ims
	//	they come into this function with current weapon as none and then the weapon change fires off immediately because we call _enableWeapons()
	//	that gives us back the killstreak weapon and it plays an animation before switching back to your normal weapon
	else if( wasNone && self GetCurrentWeapon() == killstreakWeapon )
	{
		self thread waitTakeKillstreakWeapon( killstreakWeapon, lastWeapon );
	}
}

takeKillstreakWeaponIfNoDupe( killstreakWeapon )
{
	// only take the killstreak weapon if they don't have anymore
	// the player could have two of the same killstreak and if we take the weapon then they can't use the second one
	hasKillstreak = false;
	self_pers_killstreaks = self.pers["killstreaks"];
	for( i = 0; i < self_pers_killstreaks.size; i++ )
	{
		if( IsDefined( self_pers_killstreaks[i] ) &&  IsDefined( self_pers_killstreaks[i].streakName ) && self_pers_killstreaks[i].available )
		{
			// the specialist streaks use the killstreak_uav_mp weapon so don't try to compare specialist killstreak weapons
			//	this fixes a bug where you earn a uav, change classes to specialist and earn the first streak, use the uav and the killstreak weapon doesn't get taken because it thinks you still have one
			if( !isSpecialistKillstreak( self_pers_killstreaks[i].streakName ) && killstreakWeapon == getKillstreakWeapon( self_pers_killstreaks[i].streakName ) )
			{
				hasKillstreak = true;
				break;
			}
		}
	}

	// if they have the killstreak then check to see if the currently selected killstreak is the same killstreak, if not take the weapon because it'll be given to them when they select it
	if( hasKillstreak )
	{
		if( level.console || self is_player_gamepad_enabled() )
		{
			if( IsDefined( self.killstreakIndexWeapon ) && killstreakWeapon != getKillstreakWeapon( self_pers_killstreaks[self.killstreakIndexWeapon].streakName ) )
			{
				// take the weapon because it's currently not the selected killstreak
				self TakeWeapon( killstreakWeapon );
			}
			else if( IsDefined( self.killstreakIndexWeapon ) && killstreakWeapon == getKillstreakWeapon( self_pers_killstreaks[self.killstreakIndexWeapon].streakName ) )
			{
				// take and give it right back, this fixes an issue where you could have two of the same weapons and after using the first then you couldn't use the second
				//	this was reproduced by doing predator, precision airstrike, strafe run, where airstrike and strafe run use the same weapon
				//	so if you called in the predator, then called in the strafe, you couldn't use the airstrike because you no longer have the weapon
				//	script isn't taking the weapon from you but code was saying clear that slot because the weapons were 'clip only', they shouldn't be
				self TakeWeapon( killstreakWeapon );
				self _giveWeapon( killstreakWeapon, 0 );
				self _setActionSlot( 4, "weapon", killstreakWeapon );
			}
		}
		// pc doesn't have selected killstreaks
		else
		{
			// we still want to take and give to make sure they have the weapon
			self TakeWeapon( killstreakWeapon );
			self _giveWeapon( killstreakWeapon, 0 );
		}
	}
	else
	{
		//for the case of queued hellicopter
		if ( killstreakWeapon == "" )
			return;
		
		self TakeWeapon( killstreakWeapon );
	}
}

shouldSwitchWeaponPostKillstreak( result, streakName )
{
	// certain killstreaks handle the weapon switching
	if( !result )
		return true;
	if( isRideKillstreak( streakName ) )
		return false;

	return true;	
}


finishDeathWaiter()
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	self notify ( "finishDeathWaiter" );
	self endon ( "finishDeathWaiter" );
	
	self waittill ( "death" );
	wait ( 0.05 );
	self notify ( "finish_death" );
	self.pers["lastEarnedStreak"] = undefined;
}

checkStreakReward()
{
	foreach ( streakName in self.killstreaks )
	{
		streakVal = getStreakCost( streakName );
		
		if ( streakVal > self.adrenaline )
			break;
		
		if ( self.previousAdrenaline < streakVal && self.adrenaline >= streakVal )
		{
			// to avoid confusion about not really earning a killstreak if you already have it and come around again
			//	we're going to give you the killstreak again and also allow it to chain
			self earnKillstreak( streakName, streakVal ); 

			////	No stacking (double earning)
			//alreadyEarned = false;
			//for ( i=1; i<self.pers["killstreaks"].size; i++ )
			//{
			//	if( IsDefined( self.pers["killstreaks"][i] ) && 
			//		( IsDefined( self.pers["killstreaks"][i].streakName ) && self.pers["killstreaks"][i].streakName == streakName ) && 
			//		( IsDefined( self.pers["killstreaks"][i].available ) && self.pers["killstreaks"][i].available == true ) )
			//	{
			//		alreadyEarned = true;
			//		break;
			//	}
			//}
			//if ( alreadyEarned )
			//{
			//	self.earnedStreakLevel = streakVal;
			//	updateStreakSlots();
			//}
			//else
			//	self earnKillstreak( streakName, streakVal ); 
			break;
		}
	}
}


killstreakEarned( streakName )
{
	streakArray = "assault";
	switch ( self.streakType )
	{
		case "assault":
			streakArray = "assaultStreaks";
			break;
		case "support":
			streakArray = "supportStreaks";
			break;
		case "specialist":
			streakArray = "specialistStreaks";
			break;
	}

	if( IsDefined( self.class_num ) )
	{
		if ( self getCacPlayerData( "loadouts", self.class_num, streakArray, 0 ) == streakName )
		{
			self.firstKillstreakEarned = getTime();
		}	
		else if ( self getCaCPlayerData( "loadouts", self.class_num, streakArray, 2 ) == streakName && IsDefined( self.firstKillstreakEarned ) )
		{
			if ( getTime() - self.firstKillstreakEarned < 20000 )
				self thread maps\mp\gametypes\_missions::genericChallenge( "wargasm" );
		}
	}
}


earnKillstreak( streakName, streakVal )
{
	level notify ( "gave_killstreak", streakName );
	
	self.earnedStreakLevel = streakVal;

	if ( !level.gameEnded )
	{
		appendString = undefined;
		// if this is specialist then we need to see if they are using the pro versions of perks in the streak
		if( self.streakType == "specialist" )
		{
			perkName = GetSubStr( streakName, 0, streakName.size - 3 );
			if( maps\mp\gametypes\_class::isPerkUpgraded( perkName ) )
			{
				appendString = "pro";
			}
		}
		self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( streakName, streakVal, appendString );
		//In Fireteam mode, notify my commander if I got a killstreak
		if ( bot_is_fireteam_mode() )
		{
			if ( IsDefined( appendString ) )
			{
				self notify( "bot_killstreak_earned", streakName+"_"+appendString, streakVal );
			}
			else
			{
				self notify( "bot_killstreak_earned", streakName, streakVal );
			}
		}
	}

	self thread killstreakEarned( streakName );
	self.pers["lastEarnedStreak"] = streakName;

	self setStreakCountToNext();

	/* UNUSED IW6 TEAMSTREAK
	if ( level.teamBased && isAllTeamStreak( streakName ) )
	{
		
		if ( streakName == "lasedStrike" )
			self thread teamPlayerCardSplash( "team_lasedStrike", self, self.team );
					
		foreach ( player in level.players )
		{
						
			if ( streakName == "lasedStrike" )
			{
				if ( player.hasSoflam )
					continue;
				
				player.soflamAmmoUsed = 0;
			}
				
			if ( player.team == self.team && player != self )
			{
				player giveKillstreak( streakName, false, false, player );
			}
				
			if ( player == self )
			{
				player giveKillstreak( streakName, false, true, self );
			}
			
		}
	}
	else */
		
	self giveKillstreak( streakName, true, true );
}

// The streakID param was added to allow already existing killstreaks
// being put into the gimmie slot during give load out to retain their
// unique ID. This shouldn't be used for new killstreaks. JC-09/19/13
giveKillstreak( streakName, isEarned, awardXp, owner, slotNumber, streakID )
{
	// JC-10/01/13-The giveKillstreakWeapon() call below waits while
	// the player is flagged as changing weapons. If a player is in
	// the try use of a kill streak, earns another kill streak in
	// the gimme slot and then switches teams this giveKillstreak
	// thread is left behind and will run after the player's 
	// killstreaks are cleaned out by the team switch. Fix this by
	// ending this thread on joined_team.
	self endon( "joined_team" );
	self endon( "givingLoadout" );
	self endon ( "disconnect" );
	
	// If a streak ID was not passed, grab the next available ID
	// and increment the stored value.
	if ( !IsDefined( streakID ) )
	{
		streakID = self.pers["kID"];
		self.pers["kID"]++;
	}
	
	if ( !IsDefined( level.killstreakFuncs[streakName] ) )
	{
		AssertMsg( "giveKillstreak() called with invalid killstreak: " + streakName );
		return;
	}	
	//	for devmenu give with spectators in match 
	if( self.team == "spectator" )
		return;	
	
	//	streaks given from crates go in the gimme 
	index = undefined;
	if ( !IsDefined( isEarned ) || isEarned == false )
	{
		// put this killstreak in the next available position
		// 0 - gimme slot (that will index stacked killstreaks)
		// 1-3 - cac selected killstreaks
		// 4 - specialist all perks bonus
		// 5 or more - stacked killstreaks

		if( IsDefined(slotNumber) )
		{
			nextSlot = slotNumber;
		}
		else
		{
			// MW3 way so it will stack in the gimme slot
			nextSlot = self.pers[ "killstreaks" ].size; // the size should be 5 by default, it will grow as they get stacked killstreaks
		}
		
		if( !IsDefined( self.pers[ "killstreaks" ][ nextSlot ] ) )
			self.pers[ "killstreaks" ][ nextSlot ] = spawnStruct();
		
		// Do not stack on top of a killstreak currently in use.
		// JC-09/17-13: The new intel system allows players to get killstreaks
		// while in the tryuse of another killstreak. If the currently in use
		// killstreak was in the gimme slot and the new killstreak was added
		// to the gimme slot it would cover the killstreak. Upon exiting or
		// using the currently in use killstreak the new killstreak would get
		// deleted. Example:
			//	Player pulls out MAAWS from gimme slot
			//	Player earns odin from intel
			//	Player attempts to put MAAWS away
			//	Odin killstreak is deleted
		addedToTop = true;
		if ( nextSlot > KILLSTREAK_STACKING_START_SLOT && self isTryingToUseKillstreakInGimmeSlot() )
		{
			// Copy current gimme slot killstreak info to the new top
			// of the stack
			addedToTop = false;
			addedSlot = nextSlot;
			currSlot = nextSlot - 1;
			currStruct = self.pers[ "killstreaks" ][ currSlot ];
			
			addedStruct				 = self.pers[ "killstreaks" ][ addedSlot ];
			addedStruct.available	 = currStruct.available;
			addedStruct.streakName	 = currStruct.streakName;
			addedStruct.earned		 = currStruct.earned;
			addedStruct.awardxp		 = currStruct.awardxp;
			addedStruct.owner		 = currStruct.owner;
			addedStruct.kID			 = currStruct.kID;
			addedStruct.lifeId		 = currStruct.lifeId;
			addedStruct.isGimme		 = currStruct.isGimme;
			addedStruct.isSpecialist = currStruct.isSpecialist;
			
			// Update next slot index to be the original top. The new killstreak
			// will be copied into here.
			nextSlot = currSlot;
		}
	
		self_pers_killstreak_nextSlot = self.pers[ "killstreaks" ][ nextSlot ];

		self_pers_killstreak_nextSlot.available = false;
		self_pers_killstreak_nextSlot.streakName = streakName;
		self_pers_killstreak_nextSlot.earned = false;
		self_pers_killstreak_nextSlot.awardxp = IsDefined( awardXp ) && awardXp;
		self_pers_killstreak_nextSlot.owner = owner;
		self_pers_killstreak_nextSlot.kID = streakID;
		self_pers_killstreak_nextSlot.lifeId = -1;
		self_pers_killstreak_nextSlot.isGimme = true;		
		self_pers_killstreak_nextSlot.isSpecialist = false;
		
		// If the killstreak was not added to the top of the stack, it was slid
		// underneath the currently in use gimme slot killstreak. In this case
		// update the stored gimme slot stack index, increment the killstreak
		// ID for future killstreaks and get the F out! - JC-09/17-13
		if ( !addedToTop )
		{
			// Point the gimme slot to the new top of the stack
			self.pers[ "killstreaks" ][ KILLSTREAK_GIMME_SLOT ].nextSlot = nextSlot + 1;
			// Because the new killstreak was not added to the top of the gimme
			// queue there is no need to update the gimme slot or to give the
			// player any weapons.
			return;
		}
		
		if( !IsDefined(slotNumber) )
			slotNumber = KILLSTREAK_GIMME_SLOT;

		self.pers[ "killstreaks" ][ slotNumber ].nextSlot = nextSlot;
		self.pers[ "killstreaks" ][ slotNumber ].streakName = streakName;

		index = slotNumber;
		streakIndex = getKillstreakIndex( streakName );	
		self setCommonPlayerData( "killstreaksState", "icons", slotNumber, streakIndex );
	}
	else
	{
		for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			self_pers_killstreak_i = self.pers["killstreaks"][i];
			if( IsDefined( self_pers_killstreak_i ) && IsDefined( self_pers_killstreak_i.streakName ) && streakName == self_pers_killstreak_i.streakName )
			{
				index = i;
				break;
			}
		}		
		if ( !IsDefined( index ) )
		{
			AssertMsg( "earnKillstreak() trying to give unearnable killstreak with giveKillstreak(): " + streakName );
			return;
		}		
	}
	
	self_pers_killstreak_index = self.pers["killstreaks"][index];
	self_pers_killstreak_index.available = true;
	self_pers_killstreak_index.earned = IsDefined( isEarned ) && isEarned;
	self_pers_killstreak_index.awardxp = IsDefined( awardXp ) && awardXp;
	self_pers_killstreak_index.owner = owner;
	self_pers_killstreak_index.kID = streakID;
	//self.pers["kIDs_valid"][self.pers["kID"]] = true;

	if ( !self_pers_killstreak_index.earned )
		self_pers_killstreak_index.lifeId = -1;
	else
		self_pers_killstreak_index.lifeId = self.pers["deaths"];
	
	AssertEx( isDefined(self), "Player to be rewarded is undefined" );
	AssertEx( IsPlayer(self), "Somehow a non player ent is receiving a killstreak reward" );
	AssertEx( isDefined(self.streakType), "Player: "+ self.name + " doesn't have a streakType defined" );
	
	// the specialist streak type automatically turns on and there is no weapon to use
	if( self.streakType == "specialist" && index != KILLSTREAK_GIMME_SLOT )
	{
		self_pers_killstreak_index.isSpecialist = true;		
		if( IsDefined( level.killstreakFuncs[ streakName ] ) )
			self [[ level.killstreakFuncs[ streakName ] ]]( -1, streakName );
		//self thread updateKillstreaks();
		self usedKillstreak( streakName, awardXp );
	}
	else
	{
		if( level.console || self is_player_gamepad_enabled() )
		{
			weapon = getKillstreakWeapon( streakName );
			self giveKillstreakWeapon( weapon );	

			// NOTE_A (also see NOTE_B): before we change the killstreakIndexWeapon, let's make sure it's not the one we're holding
			//	if we're currently holding something like an airdrop marker and we earned a killstreak while holding it then we want that to remain the weapon index
			//	because if it's not, then when you throw it, it'll think we're using a different killstreak and not take it away but it'll take away the other one
			if( IsDefined( self.killstreakIndexWeapon ) )
			{
				streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;
				killstreakWeapon = getKillstreakWeapon( streakName );
				if( !( self isHoldingWeapon( killstreakWeapon ) ) )
				{
					self.killstreakIndexWeapon = index;
				}
			}
			else
			{
				self.killstreakIndexWeapon = index;		
			}
		}
		else
		{
			// for pc, we need to give you the killstreak weapon in the right action slot

			// if this is the gimme slot then take away the weapon for what is in there right now and just give them this new one
			//	we don't want to keep giving weapons every time they get something in the gimme slot because there is a cap eventually
			if( KILLSTREAK_GIMME_SLOT == index && self.pers[ "killstreaks" ][ KILLSTREAK_GIMME_SLOT ].nextSlot > KILLSTREAK_STACKING_START_SLOT )
			{
				// since nextSlot has already been incremented, get the next lowest and take the weapon
				slotToTake = self.pers[ "killstreaks" ][ KILLSTREAK_GIMME_SLOT ].nextSlot - 1;
				killstreakWeaponToTake = getKillstreakWeapon( self.pers["killstreaks"][ slotToTake ].streakName );		
				self TakeWeapon( killstreakWeaponToTake );
			}

			killstreakWeapon = getKillstreakWeapon( streakName );		
			self _giveWeapon( killstreakWeapon, 0 );
			
			enableActionSlot = true;
			// disable the new action slot if we need to
			if( IsDefined( self.killstreakIndexWeapon ) )
			{
				streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;
				killstreakWeapon = getKillstreakWeapon( streakName );
				// don't update the action slot if we are currently holding the killstreak weapon
				// or "none" which means we are trying to place an IMS/SatCom
				enableActionSlot = !( self isHoldingWeapon( killstreakWeapon ) ) && (self GetCurrentWeapon() != "none");
			}
			
			if ( enableActionSlot )
			{
				self _setActionSlot( index + 4, "weapon", killstreakWeapon );
			}
			else
			{
				self _setActionSlot( index + 4, "" );
				self.actionSlotEnabled[ index ] = false;
			}
		}
	}
		
	self updateStreakSlots();
	
	if ( IsDefined( level.killstreakSetupFuncs[ streakName ] ) )
		self [[ level.killstreakSetupFuncs[ streakName ] ]]();
		
	if ( IsDefined( isEarned ) && isEarned && IsDefined( awardXp ) && awardXp )
		self notify( "received_earned_killstreak" );
}

giveKillstreakWeapon( weapon )
{
	self endon( "disconnect" );
	
	// pc doesn't need to give the weapon because you use on a single button press (unless using gamepad)
	if( !level.console && !self is_player_gamepad_enabled() )
		return;

	// If the custom juggernaut cannot use the specified killstreak, make sure we clear out the slot to prevent them from using it
	streakName = getKillstreakReferenceByWeapon( weapon );
	if ( !canCustomJuggUseKillstreak( streakName ) )
	{
		self _setActionSlot( 4, "" );
		return;
	}

	weaponList = self GetWeaponsListItems();
	
	foreach( item in weaponList )
	{
		if( !isStrStart( item, "killstreak_" ) && !isStrStart( item, "airdrop_" ) && !isStrStart( item, "deployable_" ) )
			continue;
	
		// need to do an extra check here because current weapon could be "none" but the weapon we're changing to could be one of the items in the weaponList
		//	this fixes a bug where you could be pulling out a care package when you earned the next killstreak and it would not give you the next killstreak but give you an extra care package instead
		if ( self isHoldingWeapon( item ) )
			continue;
		
		while( self isChangingWeapon() )
			wait ( 0.05 );	
		
		self TakeWeapon( item );
	}
	
	// NOTE_B (also see NOTE_A) : before we giving the killstreak weapon, let's make sure it's not the one we're holding
	//	if we're currently holding something like an airdrop marker and we earned a killstreak while holding it then we want that to remain the killstreak weapon
	//	because if it's not, then when we earn the new killstreak, we won't be able to put this one away because it thinks it's something else
	if( IsDefined( self.killstreakIndexWeapon ) )
	{
		streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;
		killstreakWeapon = getKillstreakWeapon( streakName );
		if ( !(self isHoldingWeapon( killstreakWeapon )) )
		{
			if( weapon != "" )
			{
				self _giveWeapon( weapon, 0 );
				self _setActionSlot( 4, "weapon", weapon );
			}
		}
	}
	else
	{
		self _giveWeapon( weapon, 0 );
		self _setActionSlot( 4, "weapon", weapon );
	}
}

isHoldingWeapon( weapon )
{
	return ( self GetCurrentWeapon() == weapon
		    || (IsDefined( self.changingWeapon ) && self.changingWeapon == weapon ));
}


getStreakCost( streakName )
{
	cost = int( getKillstreakKills( streakName ) );

	if( IsDefined( self ) && IsPlayer( self ) )
	{
		if( isSpecialistKillstreak( streakName ) )
		{
			if ( isDefined( self.pers["gamemodeLoadout"] ) )
			{
				if ( isDefined( self.pers["gamemodeLoadout"]["loadoutKillstreak1"] ) && self.pers["gamemodeLoadout"]["loadoutKillstreak1"] == streakName )
					cost = 2;
				else if ( isDefined( self.pers["gamemodeLoadout"]["loadoutKillstreak2"] ) && self.pers["gamemodeLoadout"]["loadoutKillstreak2"] == streakName )
					cost = 4;
				else if ( isDefined( self.pers["gamemodeLoadout"]["loadoutKillstreak3"] ) && self.pers["gamemodeLoadout"]["loadoutKillstreak3"] == streakName )
					cost = 6;
				else
					AssertMsg( "getStreakCost: killstreak doesn't exist in player's loadout" );	
			}			
			else if ( IsSubStr( self.curClass, "custom" ) )
			{
				index = 0;
				for( ; index < 3; index++ )
				{
					killstreak = self getCaCPlayerData( "loadouts", self.class_num, "specialistStreaks", index );
					if( killstreak == streakName )
						break;
				}
				AssertEx( index <= 2, "getStreakCost: killstreak index greater than 2 when it shouldn't be" );
				cost = self getCaCPlayerData( "loadouts", self.class_num, "specialistStreakKills", index );
			}
			else if ( IsSubStr( self.curClass, "callback" ) )
			{
				assert( isAI( self ) );
				assert( isdefined( self.pers[ "specialistStreaks" ] ) );
				assert( isdefined( self.pers[ "specialistStreakKills" ] ) );
				assert( self.pers[ "specialistStreakKills" ].size == self.pers[ "specialistStreaks" ].size );
				index = 0;
				foreach ( index, streak in self.pers[ "specialistStreaks" ] )
				{
					if ( streak == streakName )
						break;
				}
				assert( index >= 0 && index < self.pers[ "specialistStreakKills" ].size );
				cost = self.pers[ "specialistStreakKills" ][index];
			}
			else if ( isSubstr( self.curClass, "axis" ) || isSubstr( self.curClass, "allies" ) )
			{
				index = 0;
				teamName = "none";
				if( isSubstr( self.curClass, "axis" ) )
				{
					teamName = "axis";
				}
				else if( isSubstr( self.curClass, "allies" ) )
				{
					teamName = "allies";
				}

				classIndex = getClassIndex( self.curClass );
				for( ; index < 3; index++ )
				{
					killstreak = GetMatchRulesData( "defaultClasses", teamName, classIndex, "class", "specialistStreaks", index );					
					if( killstreak == streakName )
						break;
				}
				AssertEx( index <= 2, "getStreakCost: killstreak index greater than 2 when it shouldn't be" );
				cost = GetMatchRulesData( "defaultClasses", teamName, classIndex, "class", "specialistStreakKills", index );
			}
		}

		if( self _hasPerk( "specialty_hardline" ) && cost > 0 )
			cost--;
	}
	
	// JC-12/03/13- Hackers are adjusting their specialist perk kill
	// requirement in player data to be enormous. This is causing some
	// suspect script in _class::setKillstreaks() to throw an infinite
	// loop assert. In ship this is killing the thread and preventing 
	// the player from getting a body. This results in an invisible player
	// who is also invincible. Simple fix, clamp the killstreak cost.
	// JC-ToDo: May want to clamp this according to a precalculated
	// max killstreak cost or make the logic in setKillstreaks() better.
	cost = Int( clamp( cost, 0, 30 ) );
	
	return cost;
}

streakTypeResetsOnDeath( streakType )
{
	switch ( streakType )
	{
		case "assault":
		case "specialist":
			return true;
		case "support":
			return false;
	}
}

giveOwnedKillstreakItem( skipDialog )
{
	self_pers_killstreaks = self.pers["killstreaks"];
	
	if( level.console || self is_player_gamepad_enabled() )
	{
		//	find the highest costing streak
		keepIndex = -1;
		highestCost = -1;
		for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			if( IsDefined( self_pers_killstreaks[i] ) && 
				IsDefined( self_pers_killstreaks[i].streakName ) &&
				self_pers_killstreaks[i].available && 
				getStreakCost( self_pers_killstreaks[i].streakName ) > highestCost )
			{
				// make sure the gimme slot is the lowest regardless of the cost of the killstreak in it
				highestCost = 0;
				if( !self_pers_killstreaks[i].isGimme )
					highestCost = getStreakCost( self_pers_killstreaks[i].streakName );
				keepIndex = i;	
			} 
		}

		if ( keepIndex != -1 )
		{
			//	select it
			self.killstreakIndexWeapon = keepIndex;

			//	give the weapon
			streakName = self_pers_killstreaks[self.killstreakIndexWeapon].streakName;
			weapon = getKillstreakWeapon( streakName );
			self giveKillstreakWeapon( weapon );		
		}	
		else
			self.killstreakIndexWeapon = undefined;			
	}
	// pc doesn't select killstreaks, unless game pad is enabled
	else
	{
		keepIndex = -1;
		highestCost = -1;
		// make sure we still have all of the available killstreak weapons
		for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
		{
			if( IsDefined( self_pers_killstreaks[i] ) && 
				IsDefined( self_pers_killstreaks[i].streakName ) &&
				self_pers_killstreaks[i].available )
			{
				killstreakWeapon = getKillstreakWeapon( self_pers_killstreaks[i].streakName );
				weaponsListItems = self GetWeaponsListItems();
				hasKillstreakWeapon = false;
				for( j = 0; j < weaponsListItems.size; j++ )
				{
					if( killstreakWeapon == weaponsListItems[j] )
					{
						hasKillstreakWeapon = true;
						break;
					}
				}

				if( !hasKillstreakWeapon )
				{
					self _giveWeapon( killstreakWeapon );
				}
				else
				{
					// if we have more than one airdrop type weapon the ammo gets set to 0 because we give the next airdrop weapon before we take the last one
					//	this is a quicker fix than trying to figure out how to take and give at the right times
					if( IsSubStr( killstreakWeapon, "airdrop_" ) )
						self SetWeaponAmmoClip( killstreakWeapon, 1 );
				}

				// since the killstreak is available, make sure the actionslot is set correctly
				//	this fixes a bug where you could have, for example, a uav in your gimme slot and earned a uav before you died, when you respawned the earned uav actionslot wasn't set and you couldn't use it
				self _setActionSlot( i + 4, "weapon", killstreakWeapon );

				// get the highest value killstreak so we can show hint text for it on spawn
				// make sure the gimme slot is the lowest regardless of the cost of the killstreak in it
				if( getStreakCost( self_pers_killstreaks[i].streakName ) > highestCost )
				{
					highestCost = 0;
					if( !self_pers_killstreaks[i].isGimme )
						highestCost = getStreakCost( self_pers_killstreaks[i].streakName );
					keepIndex = i;	
				}
			}
		}

		if ( keepIndex != -1 )
		{
			streakName = self_pers_killstreaks[ keepIndex ].streakName;
		}

		self.killstreakIndexWeapon = undefined;
	}
		
	updateStreakSlots();	
}


initRideKillstreak( streak )
{
	self _disableUsability();
	result = self initRideKillstreak_internal( streak );

	if ( IsDefined( self ) )
		self _enableUsability();
		
	return result;
}


initRideKillstreak_internal( streak )
{	
	if ( IsDefined( streak ) && isLaptopTimeoutKillstreak( streak ) )
		laptopWait = "timeout";
	else
		laptopWait = self waittill_any_timeout( 1.0, "disconnect", "death", "weapon_switch_started" );
	
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	
	if ( laptopWait == "weapon_switch_started" )
		return ( "fail" );
	
	if ( !isAlive( self ) )
		return "fail";

	if ( laptopWait == "disconnect" || laptopWait == "death" )
	{	
		if ( laptopWait == "disconnect" )
			return ( "disconnect" );

		if ( self.team == "spectator" )
			return "fail";

		return ( "success" );		
	}
	
	if ( self isKillStreakDenied() )
	{
		return ( "fail" );
	}
	
	if( !IsDefined(streak) || !IsSubStr( streak, "odin" ) )
	{
		self VisionSetNakedForPlayer( "black_bw", 0.75 );
		self thread set_visionset_for_watching_players( "black_bw", 0.75, 1.0, undefined, true );
		blackOutWait = self waittill_any_timeout( 0.80, "disconnect", "death" );
	}
	else
	{
		blackOutWait = self waittill_any_timeout( 1.0, "disconnect", "death" );
	}
	
	self notify( "black_out_done" );
	
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();

	if ( blackOutWait != "disconnect"  ) 
	{
		if( !IsDefined(streak) || !IsSubStr( streak, "odin" ) )
			self thread clearRideIntro( 1.0 );
		else
			self notify( "intro_cleared" );
		
		if ( self.team == "spectator" )
			return "fail";
	}

	if ( self isOnLadder() )
		return "fail";	

	if ( !isAlive( self ) )
		return "fail";

	if ( self isKillStreakDenied() )
		return "fail";
	
	if ( blackOutWait == "disconnect" )
		return ( "disconnect" );
	else
		return ( "success" );		
}

isLaptopTimeoutKillstreak( streak )
{
	switch( streak )
	{
		case "osprey_gunner":
		case "remote_uav":
		case "remote_tank":
		case "heli_pilot":
		case "vanguard":
		case "drone_hive":
		case "odin_support":
		case "odin_assault":
		case "ca_a10_strafe": 	// Level Specific
		case "ac130":			// Level Specific
			return true;
	}
	return false;
}

clearRideIntro( delay, fadeBack )
{
	self endon( "disconnect" );

	if ( IsDefined( delay ) )
		wait( delay );
	
	if ( !isDefined( fadeBack ) )
		fadeBack = 0;

	//self freezeControlsWrapper( false );
	self VisionSetNakedForPlayer( "", fadeBack ); // go to default visionset
	self set_visionset_for_watching_players( "", fadeBack );

	self notify( "intro_cleared" );
}

allowRideKillstreakPlayerExit( earlyEndNotify ) // self == killstreak
{
	if ( isDefined( earlyEndNotify ) )
	{
		self endon( earlyEndNotify );
	}
	
	if( !IsDefined( self.owner ) )
		return;

	owner = self.owner;

	level endon( "game_ended" );
	owner endon ( "disconnect" );
	owner endon ( "end_remote" );
	self endon ( "death" );

	while( true )
	{
		timeUsed = 0;
		while(	owner UseButtonPressed() )
		{	
			timeUsed += 0.05;
			if( timeUsed > 0.75 )
			{	
				self notify( "killstreakExit" );
				return;
			}
			wait( 0.05 );
		}
		wait( 0.05 );
	}
}

giveSelectedKillstreakItem()
{
	streakName = self.pers["killstreaks"][self.killstreakIndexWeapon].streakName;

	weapon = getKillstreakWeapon( streakName );
	self giveKillstreakWeapon( weapon );
	
	self updateStreakSlots();
}

getKillstreakCount()
{
	numAvailable = 0;
	for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		if( IsDefined( self.pers["killstreaks"][i] ) && 
			IsDefined( self.pers["killstreaks"][i].streakName ) &&
			self.pers["killstreaks"][i].available )
		{
			numAvailable++;
		}
	}
	return numAvailable;
}

shuffleKillstreaksUp()
{
	if ( getKillstreakCount() > 1 )
	{		
		while ( true )
		{
			self.killstreakIndexWeapon++;		
			if ( self.killstreakIndexWeapon > KILLSTREAK_SLOT_3 )
				self.killstreakIndexWeapon = 0;
			if ( self.pers["killstreaks"][self.killstreakIndexWeapon].available == true )
				break;			
		}
		
		giveSelectedKillstreakItem();		
	}
}

shuffleKillstreaksDown()
{
	if ( getKillstreakCount() > 1 )
	{
		while ( true )
		{
			self.killstreakIndexWeapon--;		
			if ( self.killstreakIndexWeapon < 0 )
				self.killstreakIndexWeapon = KILLSTREAK_SLOT_3;
			if ( self.pers["killstreaks"][self.killstreakIndexWeapon].available == true )
				break;
		}
		
		giveSelectedKillstreakItem();		
	}
}

streakSelectUpTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	level endon ( "game_ended" );
	
	for (;;)
	{
		self waittill( "toggled_up" );
		
		if ( !level.Console && !self is_player_gamepad_enabled() )
			continue;
		
		if( IsDefined( self.showingTacticalSelections ) && self.showingTacticalSelections )
			continue;

		if( !self isMantling() &&
			( !IsDefined( self.changingWeapon ) || ( IsDefined( self.changingWeapon ) && self.changingWeapon == "none" ) ) && 
			( !isKillstreakWeapon( self GetCurrentWeapon() ) || isMiniGun(self GetCurrentWeapon()) || self GetCurrentWeapon() == "venomxgun_mp" || ( isKillstreakWeapon( self GetCurrentWeapon() ) && self isJuggernaut() ) ) &&
			self.streakType != "specialist" &&
			( !IsDefined( self.isCarrying ) || ( IsDefined( self.isCarrying ) && self.isCarrying == false ) ) &&
			( !IsDefined( self.lastStreakUsed ) || ( IsDefined( self.lastStreakUsed ) && ( GetTime() - self.lastStreakUsed ) > 100 ) ) )
		{
			self shuffleKillstreaksUp();
			self SetClientOmnvar( "ui_killstreak_scroll", 1 );
		}
		wait( .12 );
	}
}

isMiniGun( sWeapon )
{
	return (sWeapon == "iw6_minigunjugg_mp" );
}
streakSelectDownTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	level endon ( "game_ended" );
	
	for (;;)
	{
		self waittill( "toggled_down" );
		
		if ( !level.Console && !self is_player_gamepad_enabled() )
			continue;
		
		if( IsDefined( self.showingTacticalSelections ) && self.showingTacticalSelections )
			continue;

		if( !self isMantling() &&
			( !IsDefined( self.changingWeapon ) || ( IsDefined( self.changingWeapon ) && self.changingWeapon == "none" ) ) && 
			( !isKillstreakWeapon( self GetCurrentWeapon() ) || isMiniGun(self GetCurrentWeapon()) || self GetCurrentWeapon() == "venomxgun_mp" || ( isKillstreakWeapon( self GetCurrentWeapon() ) && self isJuggernaut() ) ) &&
			self.streakType != "specialist" &&
			( !IsDefined( self.isCarrying ) || ( IsDefined( self.isCarrying ) && self.isCarrying == false ) ) &&
			( !IsDefined( self.lastStreakUsed ) || ( IsDefined( self.lastStreakUsed ) && ( GetTime() - self.lastStreakUsed ) > 100 ) ) )
		{
			self shuffleKillstreaksDown();
			self SetClientOmnvar( "ui_killstreak_scroll", 1 );
		}
		wait( .12 );
	}
}

streakUseTimeTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	level endon ( "game_ended" );
	
	for (;;)
	{
		self waittill( "streakUsed" );
		self.lastStreakUsed = GetTime();
	}
}

streakNotifyTracker()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	if ( IsBot(self) )
		return;	// Bots handle killstreaks internally
	
	gameFlagWait( "prematch_done" );

	if( level.console || self is_player_gamepad_enabled() )
	{
		self notifyOnPlayerCommand( "toggled_up", "+actionslot 1" );
		self notifyOnPlayerCommand( "toggled_down", "+actionslot 2" );
		self notifyOnPlayerCommand( "streakUsed", "+actionslot 4" );
		self notifyOnPlayerCommand( "streakUsed", "+actionslot 5" );
		self notifyOnPlayerCommand( "streakUsed", "+actionslot 6" );
		self notifyOnPlayerCommand( "streakUsed", "+actionslot 7" );
	}
	
	if( !level.console )
	{
		self notifyOnPlayerCommand( "streakUsed1", "+actionslot 4" );
		self notifyOnPlayerCommand( "streakUsed2", "+actionslot 5" );
		self notifyOnPlayerCommand( "streakUsed3", "+actionslot 6" );
		self notifyOnPlayerCommand( "streakUsed4", "+actionslot 7" );
	}
}



//	ADRENALINE STUFF MOVED FROM _UTILITY.GSC
//	TODO: rename

registerAdrenalineInfo( type, value )
{
	if ( !IsDefined( level.adrenalineInfo ) )
		level.adrenalineInfo = [];
		
	level.adrenalineInfo[type] = value;
}


giveAdrenaline( type )
{	
	assertEx( IsDefined( level.adrenalineInfo[type] ), "Unknown adrenaline type: " + type );	
	
	if ( level.adrenalineInfo[type] == 0 )
		return;		
	
	//fixes bug with juggernaut bomb carrier
	if ( self isJuggernaut() && self.streakType == "specialist" )
		return;
	
	newAdrenaline = self.adrenaline + level.adrenalineInfo[type];
	adjustedAdrenaline = newAdrenaline;
	maxStreakCost = self getMaxStreakCost();
	if ( adjustedAdrenaline > maxStreakCost && ( self.streakType != "specialist" ) )
	{
		adjustedAdrenaline = adjustedAdrenaline - maxStreakCost;
	}
	else if ( level.killstreakRewards && adjustedAdrenaline > maxStreakCost && self.streakType == "specialist" )
	{
		// at a certain number of kills we'll give you the bonus perks
		specialist_max_kills = maxStreakCost;
		if ( isAI( self ) )
			specialist_max_kills = self.pers["specialistStreakKills"][2];
		numKills = int( max( MIN_NUM_KILLS_GIVE_BONUS_PERKS, ( specialist_max_kills + 2 ) ) );
		if( self _hasPerk( "specialty_hardline" ) )
			numKills--;

		// there is a case where you could get hardline as your last specialist perk and not get the bonus because your kills will be more than numKills needed
		should_give_bonus = ( adjustedAdrenaline >= numKills && self GetCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_BONUS_PERKS_SLOT ) == false );
		
		if( should_give_bonus )
		{
			//self thread giveKillstreak( "airdrop_assault", false, true, self );
			//self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( "airdrop_assault", 8 );

			self giveBonusPerks();

			self usedKillstreak( "all_perks_bonus", true );
			self thread maps\mp\gametypes\_hud_message::killstreakSplashNotify( "all_perks_bonus", numKills );
			self setCommonPlayerData( "killstreaksState", "hasStreak", KILLSTREAK_BONUS_PERKS_SLOT, true );
			self.pers["killstreaks"][ KILLSTREAK_BONUS_PERKS_SLOT ].available = true;
		}

		// give a little xp for being maxed out and continued streaking, for the specialist only
		// every two kills after max
		if( maxStreakCost > 0 && !( ( adjustedAdrenaline - maxStreakCost ) % 2 ) )
		{
			self thread maps\mp\gametypes\_rank::xpEventPopup( "specialist_streaking_xp" );
			self thread maps\mp\gametypes\_rank::giveRankXP( "kill" );
		}
	}

	self setAdrenaline( adjustedAdrenaline );
	self checkStreakReward();
	
	if ( newAdrenaline == maxStreakCost && ( self.streakType != "specialist" ) )
		setAdrenaline( 0 );
}

giveBonusPerks() // self == player
{
	// for the specialist strike package when you get to a certain number of kills
	// give them bonus perks
	if ( isAI( self ) )
	{
		if ( IsDefined( self.pers ) && IsDefined( self.pers[ "specialistBonusStreaks" ] ) )
		{
			foreach ( abilityRef in self.pers["specialistBonusStreaks"] )
			{
				if( !self _hasPerk( abilityRef ) )
				{
					self givePerk( abilityRef, false );
				}
			}
		}
	}
	else
	{
		for( abilityCategoryIndex = 0; abilityCategoryIndex < NUM_ABILITY_CATEGORIES; abilityCategoryIndex++ )
		{
			for( abilityIndex = 0; abilityIndex < NUM_SUB_ABILITIES; abilityIndex++ )
			{
				picked = false;
				if( IsDefined( self.teamName ) )
				{
					picked = getMatchRulesData( "defaultClasses", self.teamName, self.class_num, "class", "specialistBonusStreaks", abilityCategoryIndex, abilityIndex );
				}
				else
				{
					picked = self GetCaCPlayerData( "loadouts", self.class_num, "specialistBonusStreaks", abilityCategoryIndex, abilityIndex );
				}
				if( IsDefined( picked ) && picked )
				{
					abilityRef = TableLookup( "mp/cacAbilityTable.csv", 0, abilityCategoryIndex + 1, 4 + abilityIndex );
					if( !self _hasPerk( abilityRef ) )
					{
						self givePerk( abilityRef, false );
					}
				}
			}
		}
	}
}

resetAdrenaline()
{
	self.earnedStreakLevel = 0;
	self setAdrenaline(0);		
	self resetStreakCount();	
	self.pers["lastEarnedStreak"] = undefined;
	self.pers["objectivePointStreak"] = 0;
	self SetClientOmnvar( "ui_half_tick", false );
}


setAdrenaline( value )
{
	if ( value < 0 )
		value = 0;
	
	if ( IsDefined( self.adrenaline ) )
		self.previousAdrenaline = self.adrenaline;
	else
		self.previousAdrenaline = 0;
	
	self.adrenaline = value;
	
	self setClientDvar( "ui_adrenaline", self.adrenaline );
	
	self updateStreakCount();
}

pc_watchGamepad() // self == player
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );

	game_pad_enabled = self is_player_gamepad_enabled();
	while( true )
	{
		if( game_pad_enabled != self is_player_gamepad_enabled() )
		{
			game_pad_enabled = self is_player_gamepad_enabled();
			
			if( !game_pad_enabled )
			{
				if( IsDefined( self.actionSlotEnabled ) )
				{
					// turn on all of the actionSlotEnables
					for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
					{
						self.actionSlotEnabled[ i ] = true;
					}

					// make sure the action notifies are correct
					self notifyOnPlayerCommand( "streakUsed1", "+actionslot 4" );
					self notifyOnPlayerCommand( "streakUsed2", "+actionslot 5" );
					self notifyOnPlayerCommand( "streakUsed3", "+actionslot 6" );
					self notifyOnPlayerCommand( "streakUsed4", "+actionslot 7" );
					
					self giveOwnedKillstreakItem();
				}
			}
			else
			{
				// take all of the killstreak weapons, unless you're holding one
				weapon_list = self GetWeaponsListItems();
				foreach( weapon in weapon_list )
				{
					if( isKillstreakWeapon( weapon ) && weapon == self GetCurrentWeapon() )
					{
						self SwitchToWeapon( self getLastWeapon() );
						while( self isChangingWeapon() )
							wait( 0.05 );
					}
					
					if( isKillstreakWeapon( weapon ) )
						self TakeWeapon( weapon );
				}
				// clear the action slots, it should get filled by the function call below
				for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
				{
					self _setActionSlot( i + 4, "" );
					self.actionSlotEnabled[ i ] = false;
				}
				
				// make sure the action notifies are correct
				self notifyOnPlayerCommand( "toggled_up", "+actionslot 1" );
				self notifyOnPlayerCommand( "toggled_down", "+actionslot 2" );
				self notifyOnPlayerCommand( "streakUsed", "+actionslot 4" );
				self notifyOnPlayerCommand( "streakUsed", "+actionslot 5" );
				self notifyOnPlayerCommand( "streakUsed", "+actionslot 6" );
				self notifyOnPlayerCommand( "streakUsed", "+actionslot 7" );

				self giveOwnedKillstreakItem();
			}
		}
		wait( 0.05 );
	}
}

pc_watchStreakUse() // self == player
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );

	self.actionSlotEnabled = [];
	self.actionSlotEnabled[ KILLSTREAK_GIMME_SLOT ] = true;
	self.actionSlotEnabled[ KILLSTREAK_SLOT_1 ] = true;
	self.actionSlotEnabled[ KILLSTREAK_SLOT_2 ] = true;
	self.actionSlotEnabled[ KILLSTREAK_SLOT_3 ] = true;

	while( true )
	{
		result = self waittill_any_return( "streakUsed1", "streakUsed2", "streakUsed3", "streakUsed4" );
		
		if( self is_player_gamepad_enabled() )
			continue;

		if( !IsDefined( result ) )
			continue;

		// specialist can only use the gimme slot
		if( self.streakType == "specialist" && result != "streakUsed1" )
			continue;

		// don't let the killstreakIndexWeapon change while we are at none weapon because that could mean we're carrying something like sentry or ims
		if( IsDefined( self.changingWeapon ) && self.changingWeapon == "none" )
			continue;

		// corresponding to code change that we're no longer allowing player to 'queue up' a killstreak 
		// when they're cooking a grenade or holding up the underbarrel grenade launcher
		if( self IsOffhandWeaponReadyToThrow() )
			continue;
		
		switch( result )
		{
		case "streakUsed1":
			if( self.pers["killstreaks"][ KILLSTREAK_GIMME_SLOT ].available && self.actionSlotEnabled[ KILLSTREAK_GIMME_SLOT ] )
				self.killstreakIndexWeapon = KILLSTREAK_GIMME_SLOT;
			break;
		case "streakUsed2":
			if( self.pers["killstreaks"][ KILLSTREAK_SLOT_1 ].available && self.actionSlotEnabled[ KILLSTREAK_SLOT_1 ] )
				self.killstreakIndexWeapon = KILLSTREAK_SLOT_1;
			break;
		case "streakUsed3":
			if( self.pers["killstreaks"][ KILLSTREAK_SLOT_2 ].available && self.actionSlotEnabled[ KILLSTREAK_SLOT_2 ] )
				self.killstreakIndexWeapon = KILLSTREAK_SLOT_2;
			break;
		case "streakUsed4":
			if( self.pers["killstreaks"][ KILLSTREAK_SLOT_3 ].available && self.actionSlotEnabled[ KILLSTREAK_SLOT_3 ] )
				self.killstreakIndexWeapon = KILLSTREAK_SLOT_3;
			break;
		}

		// just a sanity check to make sure we reset the killstreakIndexWeapon
		if( IsDefined( self.killstreakIndexWeapon ) && !self.pers["killstreaks"][ self.killstreakIndexWeapon ].available )
			self.killstreakIndexWeapon = undefined;

		if( IsDefined( self.killstreakIndexWeapon ) )
		{
			self disableKillstreakActionSlots();
			while( true )
			{
				self waittill( "weapon_change", newWeapon, isAltToggle );
				if( IsDefined( self.killstreakIndexWeapon ) )
				{
					killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][ self.killstreakIndexWeapon ].streakName );
					// if this is the killstreak weapon or none or alt mode switch then continue and wait for the next weapon change
					//	remote uav gives you a different weapon than the killstreak weapon from the killstreaktable.csv, so we need to also check for that
					if( newWeapon == killstreakWeapon || 
						newWeapon == "none" || 
						( killstreakWeapon == "killstreak_uav_mp" && newWeapon == "killstreak_remote_uav_mp" ) ||
						( killstreakWeapon == "killstreak_uav_mp" && newWeapon == "uav_remote_mp" ) ||
						isAltToggle )
						continue;

					break;
				}
				
				break;
			}
			// they either used the killstreak or cancelled it
			self enableKillstreakActionSlots();
			self.killstreakIndexWeapon = undefined;
		}
	}
}

disableKillstreakActionSlots() // self == player
{
	for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		if( !IsDefined( self.killstreakIndexWeapon ) )
			break;

		if( self.killstreakIndexWeapon == i )
			continue;

		// clear all other killstreak slots while we are using a killstreak so they can't try to use another one
		self _setActionSlot( i + 4, "" );
		self.actionSlotEnabled[ i ] = false;
	}
}

enableKillstreakActionSlots() // self == player
{
	for( i = KILLSTREAK_GIMME_SLOT; i < KILLSTREAK_SLOT_3 + 1; i++ )
	{
		// turn all of the action slots back on
		if( self.pers["killstreaks"][ i ].available )
		{
			killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][ i ].streakName );
			self _setActionSlot( i + 4, "weapon", killstreakWeapon );
		}
		else
		{
			// since this killstreak isn't available, clear the action slot so they can't pull an empty weapon out
			self _setActionSlot( i + 4, "" );
		}

		// even if they don't have a killstreak in this slot we need to switch this flag for later uses
		//	if we don't, then once they earn it they won't be able to use it because this flag is off
		self.actionSlotEnabled[ i ] = true;
	}
}

killstreakHit( attacker, weapon, vehicle )
{
	if( IsDefined( weapon ) && isPlayer( attacker ) && IsDefined( vehicle.owner ) && IsDefined( vehicle.owner.team ) )
	{
		if ( ( (level.teamBased && vehicle.owner.team != attacker.team) || !level.teamBased ) && attacker != vehicle.owner )
		{
			if( isKillstreakWeapon( weapon ) )
				return;
				
			if ( !isDefined( attacker.lastHitTime[ weapon ] ) )
				attacker.lastHitTime[ weapon ] = 0;
		
			// already hit with this weapon on this frame
			if ( attacker.lastHitTime[ weapon ] == getTime() )
				return;

			attacker.lastHitTime[ weapon ] = getTime();
			
			attacker thread maps\mp\gametypes\_gamelogic::threadedSetWeaponStatByName( weapon, 1, "hits" );
			
			
			if ( !IsSquadsMode() )
			{
				totalShots = attacker maps\mp\gametypes\_persistence::statGetBuffered( "totalShots" );		
				hits = attacker maps\mp\gametypes\_persistence::statGetBuffered( "hits" ) + 1;
	
				if ( hits <= totalShots )
				{
					attacker maps\mp\gametypes\_persistence::statSetBuffered( "hits", hits );
					attacker maps\mp\gametypes\_persistence::statSetBuffered( "misses", int(totalShots - hits) );
					attacker maps\mp\gametypes\_persistence::statSetBuffered( "accuracy", int(hits * 10000 / totalShots) );
				}
			}
		}
	}
}

copy_killstreak_status( from, noTransfer )
{
	self.streakType = from.streakType;
	self.pers[ "cur_kill_streak" ] = from.pers[ "cur_kill_streak" ];
	//self setPlayerStat( "killstreak", from getPlayerStat( "killstreak" ) );
	self maps\mp\gametypes\_persistence::statSetChild( "round", "killStreak", self.pers[ "cur_kill_streak" ] );

	self.pers["killstreaks"] = from.pers["killstreaks"];
	self.killstreaks = from.killstreaks;

	if ( !IsDefined( noTransfer ) || noTransfer == false )
	{
		//this is pretty ugly and possibly quite unsafe, but the owner of a killstreak needs to change
		allEntities = GetEntArray();
		foreach( ent in allEntities )
		{
			if ( !IsDefined( ent ) || IsPlayer( ent ) )//don't transfer ownership of clients, this is just for owned objects in the world, not leadership transfer
				continue;
			
			if ( IsDefined( ent.owner ) && ent.owner == from )
			{
				if ( ent.classname == "misc_turret" )
					ent maps\mp\killstreaks\_autosentry::sentry_setOwner( self );
				else
					ent.owner = self;
			}
		}
	}
	
	self.adrenaline = undefined;
	self setAdrenaline( from.adrenaline );
	self resetStreakCount();
	self updateStreakCount();

	if ( IsDefined( noTransfer ) && noTransfer == true && IsDefined( self.killstreaks ) )
	{//just copying the info, need to update our HUD
		//update the icons
		index = 1;
		foreach ( streakName in self.killstreaks )
		{
			killstreakIndexName = self.pers["killstreaks"][index].streakName;
			// if specialist then we need to check to see if they have the pro version of the perk and get that icon
			if( self.streakType == "specialist" )
			{
				perkTokens = StrTok( self.pers["killstreaks"][index].streakName, "_" );
				if( perkTokens[ perkTokens.size - 1 ] == "ks" )
				{
					perkName = undefined;
					foreach( token in perkTokens )
					{
						if( token != "ks" )
						{
							if( !IsDefined( perkName ) )
								perkName = token;
							else
								perkName += ( "_" + token );
						}
					}
	
					// blastshield has an _ at the beginning
					if( isStrStart( self.pers["killstreaks"][index].streakName, "_" ) )
						perkName = "_" + perkName;
	
					if( IsDefined( perkName ) && self maps\mp\gametypes\_class::getPerkUpgrade( perkName ) != "specialty_null" )
						killstreakIndexName = self.pers["killstreaks"][index].streakName + "_pro";
				}
			}
	
			self setCommonPlayerData( "killstreaksState", "icons", index, getKillstreakIndex( killstreakIndexName ) );
			index++;	
		}
	}

	self updateStreakSlots();

	//copy over perks	
	foreach( perkName in from.perksPerkName )
	{
		//FIXME: this will restart a perk's threads - timer, etc.  So all timed perks get reset to full length
		if ( !self _hasPerk( perkName ) )
		{
			useSlot = false;
			if ( IsDefined( self.perksUseSlot[ perkName ] ) )
				useSlot = self.perksUseSlot[ perkName ];
			self givePerk( perkName, useSlot );
		}
		if ( !IsDefined( noTransfer ) || noTransfer == false )
		{//stop & remove perks from other guy
			from _unsetPerk( perkName );
		}
	}
}

copy_adrenaline( from )
{
	self.adrenaline = undefined;
	self setAdrenaline( from.adrenaline );
	self resetStreakCount();
	self updateStreakCount();
	self updateStreakSlots();
}

is_using_killstreak()
{
	curWeap = self GetCurrentWeapon();
	usingKS = IsSubStr( curWeap, "killstreak" ) || (IsDefined(self.selectingLocation) && self.selectingLocation == true) || !(self isWeaponEnabled()) && !(self maps\mp\gametypes\_damage::attackerInRemoteKillstreak());
	return usingKS;
}

monitorDisownKillstreaks()
{
	while(IsDefined(self))
	{
		if ( bot_is_fireteam_mode() )
		{
			self waittill( "disconnect" );
		}
		else
		{
			self waittill_any( "disconnect", "joined_team", "joined_spectators" );
		}
		self notify( "killstreak_disowned" );
	}
}

PROJECTILE_TRACE_OBSTRUCTED_THRESHOLD = 0.99;	// this allows us to reject cases where we only see a tiny part of the target point
PROJECTILE_TRACE_YAW_ANGLE_INCREMENT = 30;

// should I allow user to specify flight distance or height?
/* 
============= 
///ScriptDocBegin
"Name: findUnobstructedFiringPointAroundZ( <player>, <targetPosition>, <flightDistance>, <angleOfAttack> )"
"Summary: Find a suitible flight path for a projectile around the +Z axis. Starts from behind the player and sweeps around in a circle in 30 degree increments. Returns undefined if all paths are blocked. Useful for tall narrow spaces."
"Module: Killstreaks"
"MandatoryArg: <player> : The player whose POV we'll use as a reference"
"MandatoryArg: <targetPosition> : The position to aim at."
"MandatoryArg: <flightDistance> : # of units for the projectile to travel. Very large values may collide with the skybox."
"MandatoryArg: <angleOfAttack> : The angle from +Z axis"
"Example: findUnobstructedFiringPointAroundZ( player, designatorEntity.origin, 10000, 30 )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
findUnobstructedFiringPointAroundZ( player, targetPosition, flightDistance, angleOfAttack  )	// self == player
{
	initialVector = RotateVector( (0, 0, 1), (-1 * angleOfAttack, 0, 0) );
	
	anglesToPlayer = VectorToAngles( targetPosition - player.origin );
	for ( deltaAngle = 0; deltaAngle < 360; deltaAngle += PROJECTILE_TRACE_YAW_ANGLE_INCREMENT )
	{
		// want to start from behind the target
		approachVector = flightDistance * RotateVector( initialVector, (0,  deltaAngle + anglesToPlayer[1], 0 ) );
		startPosition = targetPosition + approachVector;
		
		// if ( deltaAngle == 0 )
		//	player thread drawLine( startPosition, targetPosition, 20, (0, 0, 1) );
				
		if ( _findUnobstructedFiringPointHelper( player, startPosition, targetPosition ) )
		{
			return startPosition;
		}
	}
	
	return undefined;
}

/* 
============= 
///ScriptDocBegin
"Name: findUnobstructedFiringPointAroundY( <player>, <targetPosition>, <flightDistance>, <minPitch>, <maxPitch>, <angleStep> )"
"Summary: Find a suitible flight path for a projectile behind the player. Starts high and lowers angle of attack. Useful for getting into doorways and windows. Returns undefined if all paths blocked.
"Module: Killstreaks"
"MandatoryArg: <player> : The player whose POV we'll use as a reference"
"MandatoryArg: <targetPosition> : The position to aim at."
"MandatoryArg: <flightDistance> : # of units for the projectile to travel. Very large values may collide with the skybox."
"MandatoryArg: <minPitch> : shallowest pitch angle (0 = parallel to ground)
"MandatoryArg: <maxPitch> : steepest ptich angle (90 = straight up)
"MandatoryArg: <angleStep> : # of degrees to step from max to min pitch
"Example: findUnobstructedFiringPointAroundZ( player, designatorEntity.origin, 10000, 15, 75, 15 )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
findUnobstructedFiringPointAroundY( player, targetPosition, flightDistance, minPitch, maxPitch, angleStep )
{
	anglesToPlayer = VectorToAngles( player.origin - targetPosition );
	
	for ( deltaAngle = minPitch; deltaAngle <= maxPitch; deltaAngle += angleStep )
	{
		// since we're starting with the front vector, keep pitching up (so the firing angle becomes shallower)
		initialVector = RotateVector( (1, 0, 0), ( deltaAngle - 90, 0, 0 ) );
		// not sure why, but can't yaw the vector towards the player before pitching
		// so we have to do two rotates per check
		approachVector = flightDistance * RotateVector( initialVector, (0, anglesToPlayer[1], 0) );
		startPosition = targetPosition + approachVector;
		
		//if ( deltaAngle == minPitch )
		//	player thread drawLine( startPosition, targetPosition, 20, (0, 0, 1) );
		
		if ( _findUnobstructedFiringPointHelper( player, startPosition, targetPosition ) )
		{
			return startPosition;
		}
	}
	
	return undefined;
}

_findUnobstructedFiringPointHelper( player, startPosition, targetPosition )
{
	traceResult = BulletTrace( startPosition, targetPosition, false );
		
	if ( traceResult[ "fraction" ] > PROJECTILE_TRACE_OBSTRUCTED_THRESHOLD )
	{
		//player thread drawLine( startPosition, targetPosition, 20, (0, 1, 0) );
		// player thread drawSphere( traceResult[ "position" ], 3, (0, 1, 0) );
		return true;
	}
	/*
	else
	{
		player thread drawLine( startPosition, targetPosition, 20, (1, 0, 0) );
	}
	*/
	
	return false;
}

/* 
============= 
///ScriptDocBegin
"Name: findUnobstructedFiringPoint( <player>, <targetPosition>, <flightDistance> )"
"Summary: Find a suitible flight path for a projectile to hit the target point. Will try to find a firing point high and behind the player."
"Module: Killstreaks"
"MandatoryArg: <player> : The player whose POV we'll use as a reference"
"MandatoryArg: <targetPosition> : The position to aim at."
"MandatoryArg: <flightDistance> : # of units for the projectile to travel. Very large values may collide with the skybox."
"Example: findUnobstructedFiringPointAroundZ( player, designatorEntity.origin, 10000 )
"SPMP: multiplayer"
///ScriptDocEnd
============= 
*/
findUnobstructedFiringPoint( player, targetPosition, flightDistance )
{
	result = findUnobstructedFiringPointAroundZ( player, targetPosition, flightDistance, 30 );
	
	if ( !IsDefined( result ) )
	{
		result = findUnobstructedFiringPointAroundY( player, targetPosition, flightDistance, 15, 75, 15 );
	}
	
	return result;
}

isAirdropMarker( weaponName )
{
	switch ( weaponName )
	{
		case "airdrop_marker_mp":
		case "airdrop_marker_assault_mp":
		case "airdrop_marker_support_mp":
		case "airdrop_mega_marker_mp":
		case "airdrop_sentry_marker_mp":
		case "airdrop_juggernaut_mp":
		case "airdrop_juggernaut_def_mp":
		case "airdrop_juggernaut_maniac_mp":
		case "airdrop_tank_marker_mp":
		case "airdrop_escort_marker_mp":
			return true;
		default:
			return false;
	}
}

isUsingHeliSniper()
{
	return ( IsDefined( self.OnHeliSniper ) && self.OnHeliSniper );
}


destroyTargetArray( attacker, victimTeam, weaponName, targetList )
{
	meansOfDeath = "MOD_EXPLOSIVE";

	damage = 5000;
	direction_vec = ( 0, 0, 0 );
	point = ( 0, 0, 0 );
	modelName = "";
	tagName = "";
	partName = "";
	iDFlags = undefined;

	if ( level.teamBased )
	{
		foreach ( target in targetList )
		{
			if ( isValidTeamTarget( attacker, victimTeam, target ) )
			{
				target notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weaponName );
				wait( 0.05 );
			}
		}
	}
	else
	{
		foreach ( target in targetList )
		{
			if ( isValidFFATarget( attacker, victimTeam, target ) )
			{
				target notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weaponName );
				wait( 0.05 );
			}
		}
	}
}
