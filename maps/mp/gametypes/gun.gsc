#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_class;
#include common_scripts\utility;

CONST_WEAPON_TABLE = "mp/gunGameWeapons.csv";
CONST_GROUP_NAME_IDX = 0;
CONST_WEAPON_BASE_IDX = 1;
CONST_WEAPON_MIN_ATTACH_IDX = 2;
CONST_WEAPON_MAX_ATTACH_IDX = 3;
CONST_WEAPON_BONUS_PERK_IDX = 4;
CONST_WEAPON_DLC_UNLOCK_IDX = 5;

CONST_CAMO_CHANCE = 0.5;
CONST_CAMO_TABLE = "mp/camotable.csv";
CONST_CAMO_ID_IDX = 4;
CONST_NUM_CAMOS = 12; // don't give gold camo?

CONST_RETICLE_CHANCE = 0.25;
CONST_NUM_RETICLES = 11;

main()
{
	maps\mp\gametypes\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\gametypes\_globallogic::SetupCallbacks();
	
	//	must be done before scorelimit is set
	setGuns();

	if ( IsUsingMatchRulesData() )
	{
		level.initializeMatchRules = ::initializeMatchRules;
		[[level.initializeMatchRules]]();
		level thread reInitializeMatchRulesOnMigration();	
	}
	else
	{
		registerTimeLimitDvar( level.gameType, 10 );
		scoreLimit = level.gun_guns.size;
		SetDynamicDvar( "scr_gun_scorelimit", scoreLimit );
		registerScoreLimitDvar( level.gameType, scoreLimit );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 0 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 ); 
		
		level.matchRules_randomize = 0;
		level.matchRules_damageMultiplier = 0;
		level.matchRules_vampirism = 0;
	}
	setSpecialLoadout();	
	
	SetTeamMode( "ffa" );
	level.teamBased = false;
	
	level.doPrematch = true;
	level.killstreakRewards = false;
	level.supportIntel		= false;
	level.supportNuke		= false;
	level.assists_disabled	= true;
	level.onPrecacheGameType = ::onPrecacheGameType;
	level.onStartGameType = ::onStartGameType;
	level.onSpawnPlayer = ::onSpawnPlayer;
	level.getSpawnPoint = ::getSpawnPoint;
	level.onPlayerKilled = ::onPlayerKilled;
	level.onTimeLimit = ::onTimeLimit;
	level.onPlayerScore = ::onPlayerScore;
	
	if ( level.matchRules_damageMultiplier || level.matchRules_vampirism )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;
}


initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData( true );
	
	//	set everything else (private match options, default .cfg file values, and what normally is registered in the 'else' below)			
	level.matchRules_randomize = GetMatchRulesData( "gunData", "randomize" );
	
	scoreLimit = level.gun_guns.size;
	SetDynamicDvar( "scr_gun_scorelimit", scoreLimit );
	registerScoreLimitDvar( level.gameType, scoreLimit );	
	SetDynamicDvar( "scr_gun_winlimit", 1 );
	registerWinLimitDvar( "gun", 1 );
	SetDynamicDvar( "scr_gun_roundlimit", 1 );
	registerRoundLimitDvar( "gun", 1 );
	SetDynamicDvar( "scr_gun_halftime", 0 );
	registerHalfTimeDvar( "gun", 0 );
	
	//	Always force these values for this mode
	SetDynamicDvar( "scr_gun_playerrespawndelay", 0 );
	SetDynamicDvar( "scr_gun_waverespawndelay", 0 );
	SetDynamicDvar( "scr_player_forcerespawn", 1 );	
		
	SetDynamicDvar( "scr_gun_promode", 0 );
}


onPrecacheGameType()
{
}


onStartGameType()
{
	val = maps\mp\gametypes\_rank::getScoreInfoValue( "gained_gun_score" );
	// xp_event_table ignores -1 values, so we have to manually set it
	maps\mp\gametypes\_rank::registerScoreInfo( "dropped_gun_score", -1 * val );
	
	// if we're using random guns, selecting the actual guns must wait until _weapons::init has run in order to build attachments
	setGunsFinal();
	
	setClientNameMode("auto_change");

	setObjectiveText( "allies", &"OBJECTIVES_DM" );
	setObjectiveText( "axis", &"OBJECTIVES_DM" );

	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_DM" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_DM" );
	}
	else
	{
		setObjectiveScoreText( "allies", &"OBJECTIVES_DM_SCORE" );
		setObjectiveScoreText( "axis", &"OBJECTIVES_DM_SCORE" );
	}
	setObjectiveHintText( "allies", &"OBJECTIVES_DM_HINT" );
	setObjectiveHintText( "axis", &"OBJECTIVES_DM_HINT" );

	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );

	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_dm_spawn" );

	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	setMapCenter( level.mapCenter );		
	
	allowed = [];
	maps\mp\gametypes\_gameobjects::main(allowed);
	
	level.QuickMessageToAll = true;
	level.blockWeaponDrops = true;
	
	//	set index on enter	
	level thread onPlayerConnect();	
	
	level.killstreakRewards = false;
}


onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		
		player.gun_firstSpawn = true;
		
		player.gunGameGunIndex = 0;
		player.gunGamePrevGunIndex = 0;
		
		if ( level.matchRules_randomize )
		{
			player.gun_nextGuns = level.gun_guns;
			player.gun_prevGuns = [];
		}
		
		player thread refillAmmo();
		player thread refillSingleCountAmmo();
		
		player setFakeLoadoutWeaponSlot( level.gun_guns[0], 1 );
	}
}


getSpawnPoint()
{
	//	first time here?
	if ( self.gun_firstSpawn )
	{
		self.gun_firstSpawn = false;
		
		//	everyone is a gamemode class in gun, no class selection
		self.pers["class"] = "gamemode";
		self.pers["lastClass"] = "";
		self.class = self.pers["class"];
		self.lastClass = self.pers["lastClass"];	
		
		//	random team
		if ( cointoss() )
			self maps\mp\gametypes\_menus::addToTeam( "axis", true );
		else
			self maps\mp\gametypes\_menus::addToTeam( "allies", true );		
	}	
	
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.pers["team"] );
	spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_FreeForAll( spawnPoints );

	return spawnPoint;
}


onSpawnPlayer()
{
	//	level.onSpawnPlayer() gets called before giveLoadout()
	//	so wait until it is done then override weapons
	self.pers["gamemodeLoadout"] = level.gun_loadouts[self.pers["team"]];
	self thread waitLoadoutDone();
	
	level notify ( "spawned_player" );	
}


waitLoadoutDone()
{	
	level endon( "game_ended" );
	self endon( "disconnect" );
	
	self waittill( "spawned_player" );
	
	self givePerk( "specialty_bling", false );
	self giveNextGun( true );
}


onPlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, lifeId )
{
	if ( sMeansOfDeath == "MOD_FALLING" || ( isDefined( attacker ) && isPlayer( attacker ) ) )
	{
		isMeleeWeapon = maps\mp\gametypes\_weapons::isRiotShield( sWeapon ); // || maps\mp\gametypes\_weapons::isKnifeOnly( sWeapon )
			
		if ( sMeansOfDeath == "MOD_FALLING" || attacker == self || ( sMeansOfDeath == "MOD_MELEE" && !isMeleeWeapon ) )
		{			
			self playLocalSound( "mp_war_objective_lost" );
			
			//	drop level for suicide and getting knifed
			self.gunGamePrevGunIndex = self.gunGameGunIndex;
			self.gunGameGunIndex = int( max( 0, self.gunGameGunIndex-1 ) );	
			if ( self.gunGamePrevGunIndex > self.gunGameGunIndex )
			{
				self thread maps\mp\gametypes\_rank::xpEventPopup( "dropped_gun_rank" );
				maps\mp\gametypes\_gamescore::givePlayerScore( "dropped_gun_score", self, undefined, true, true );
				
				self setFakeLoadoutWeaponSlot( level.gun_guns[self.gunGameGunIndex], 1 );
			}
			
			if ( sMeansOfDeath == "MOD_MELEE" )
			{
				if ( self.gunGamePrevGunIndex )
				{
					attacker thread maps\mp\gametypes\_rank::xpEventPopup( "dropped_enemy_gun_rank" );
					attacker thread maps\mp\gametypes\_rank::giveRankXP( "dropped_enemy_gun_rank" );	
				}		
				
				attacker.assists++;

				// repurposing unused sguardWave in round stats for stabs
				attacker maps\mp\gametypes\_persistence::statSetChild( "round", "sguardWave",  attacker.assists );
			}
		}
		else if ( ( sMeansOfDeath == "MOD_PISTOL_BULLET" ) 
				 || ( sMeansOfDeath == "MOD_RIFLE_BULLET" ) 
				 || ( sMeansOfDeath == "MOD_HEAD_SHOT" ) 
				 || ( sMeansOfDeath == "MOD_PROJECTILE" ) || ( sMeansOfDeath == "MOD_PROJECTILE_SPLASH" ) 
				 || ( sMeansOfDeath == "MOD_IMPACT" ) 
				 || ( sMeansOfDeath == "MOD_GRENADE" ) || ( sMeansOfDeath == "MOD_GRENADE_SPLASH" ) 
				 || ( sMeansOfDeath == "MOD_MELEE" && isMeleeWeapon )
				)
		{
			// Prevent sequential kills from counting by validating the primary weapon
			// Let throwing knife kills count even though they're not the primary weapon
			if ( sWeapon != attacker.primaryWeapon && !attacker isValidThrowingKnifeKill( sWeapon ) )
				return;		
			
			attacker.gunGamePrevGunIndex = attacker.gunGameGunIndex;
			attacker.gunGameGunIndex++;
			
			attacker thread maps\mp\gametypes\_rank::giveRankXP( "gained_gun_rank" );
			maps\mp\gametypes\_gamescore::givePlayerScore( "gained_gun_score", attacker, self, true, true );
			
			if ( attacker.gunGameGunIndex == level.gun_guns.size-1 )
			{
				playSoundOnPlayers( "mp_enemy_obj_captured" );
				level thread teamPlayerCardSplash( "callout_top_gun_rank", attacker );
			}		
				
			if ( attacker.gunGameGunIndex < level.gun_guns.size )
			{
				attacker thread maps\mp\gametypes\_rank::xpEventPopup( "gained_gun_rank" );
				attacker playLocalSound( "mp_war_objective_taken" );
				attacker giveNextGun();
				
				attacker setFakeLoadoutWeaponSlot( level.gun_guns[attacker.gunGameGunIndex], 1 );
			}
		}
	}
}

giveNextGun( doSetSpawnWeapon )
{	
	//	get the next one
	newWeapon = getNextGun();
	
	//	give gun
	self takeAllWeapons();
	_giveWeapon( newWeapon );		
	
	//	set vars
	if ( isDefined( doSetSpawnWeapon ) )
		self setSpawnWeapon( newWeapon );
	
	self.pers["primaryWeapon"] = newWeapon;	
	self.primaryWeapon = newWeapon;
	
	//	use it!
	self GiveStartAmmo( newWeapon );
	
	self SwitchToWeapon( newWeapon );
	
	self giveOrTakeThrowingKnife( newWeapon );
	
	// have to record the hybrid scope state?
	self maps\mp\gametypes\_weapons::updateToggleScopeState( newWeapon );
	
	//	gain/drop scoring/messaging
	if ( self.gunGamePrevGunIndex > self.gunGameGunIndex )
	{
		//	we dropped :(
		self thread maps\mp\gametypes\_rank::xpEventPopup( "dropped_gun_rank" );		
	}
	else if ( self.gunGamePrevGunIndex < self.gunGameGunIndex )
	{
		//	we gained :)
		self thread maps\mp\gametypes\_rank::xpEventPopup( "gained_gun_rank" );		
	}
	self.gunGamePrevGunIndex = self.gunGameGunIndex;
	
	// remove old perks, add new ones
	
	// remove old equipment, add new ones
}


getNextGun()
{
	newWeapon = level.gun_guns[self.gunGameGunIndex];
		
	return newWeapon;	
}

/*
waitUntilNotFiringToGiveNextGun()
{
	self endon ( "death" );
	
	while ( self AttackButtonPressed() )
	{
		waitframe();
	}
	
	self giveNextGun();
}
*/


onTimeLimit()
{
	level.finalKillCam_winner = "none";
	winners = getHighestProgressedPlayers();
	
	if ( !isDefined( winners ) || !winners.size )
		thread maps\mp\gametypes\_gamelogic::endGame( "tie", game[ "end_reason" ][ "time_limit_reached" ] );	
	else if ( winners.size == 1 )
		thread maps\mp\gametypes\_gamelogic::endGame( winners[0], game[ "end_reason" ][ "time_limit_reached" ] );
	else
	{
		if ( winners[winners.size-1].gunGameGunIndex > winners[winners.size-2].gunGameGunIndex )
			thread maps\mp\gametypes\_gamelogic::endGame( winners[winners.size-1], game[ "end_reason" ][ "time_limit_reached" ] );
		else
			thread maps\mp\gametypes\_gamelogic::endGame( "tie", game[ "end_reason" ][ "time_limit_reached" ] );
	}
}


getHighestProgressedPlayers()
{
	highestProgress = -1;
	highestProgressedPlayers = [];
	foreach( player in level.players )
	{
		if ( isDefined( player.gunGameGunIndex ) && player.gunGameGunIndex >= highestProgress )
		{
			highestProgress = player.gunGameGunIndex;
			highestProgressedPlayers[highestProgressedPlayers.size] = player;
		}
	}
	return highestProgressedPlayers;
}


refillAmmo()
{
	level endon( "game_ended" );
	self  endon( "disconnect" );
	
	while ( true )
	{
		self waittill( "reload" );
		self GiveStartAmmo( self.primaryWeapon );
	}	
}


refillSingleCountAmmo()
{
	level endon( "game_ended" );
	self  endon( "disconnect" );
	
	while ( true )
	{
		if ( isReallyAlive( self ) && self.team != "spectator" && isDefined( self.primaryWeapon ) && self getAmmoCount( self.primaryWeapon ) == 0 )
		{
			//	fake a reload time
			wait( 2 );
			self notify( "reload" );
			wait( 1 );
		}
		else
			wait( 0.05 );
	}	
}

setGuns()
{	
	level.gun_guns = [];
	level.selectedWeapons = [];
	
	numGuns = 0;
	if ( isUsingMatchRulesData() )
		numGuns = GetMatchRulesData( "gunData", "numGuns" );
		
	if( numGuns > 20 )
		numGuns = 20;
		
	if ( numGuns )
	{
		for ( i=0; i<numGuns; i++ )
		{
			level.gun_guns[i] = GetMatchRulesData( "gunData", "guns", i );
		}
	}
	else
	{	
		//	hand guns
		level.gun_guns[0]  = "rand_pistol";	
		
		level.gun_guns[1]  = "rand_shotgun";
		level.gun_guns[2]  = "rand_smg";
		level.gun_guns[3]  = "rand_assault";
		level.gun_guns[4]  = "rand_lmg";
		
		level.gun_guns[5]  = "rand_dmr";
		level.gun_guns[6]  = "rand_smg";
		level.gun_guns[7]  = "rand_assault";		
		level.gun_guns[8]  = "rand_lmg2";
		
		level.gun_guns[9]  = "rand_launcher";
		level.gun_guns[10] = "rand_sniper";	
		
		level.gun_guns[11] = "rand_smg";
		level.gun_guns[12] = "rand_assault2";
		
		level.gun_guns[13] = "rand_shotgun2";
		level.gun_guns[14] = "rand_dmr";
		level.gun_guns[15] = "rand_sniper2";	
		
		level.gun_guns[16] = "iw6_magnum_mp_acogpistol_akimbo";
		level.gun_guns[17] = "iw6_knifeonly_mp";
	}	
	
	// if ( level.matchRules_randomize )
	// shuffle the list if desired
}

// after weapons have initialized, set the guns for real
setGunsFinal()
{
	level.selectedWeapons = [];	// keep track of which weapons we've used
	
	buildRandomWeaponTable();
	
	for ( i = 0; i < level.gun_guns.size; i++ )
	{
		curGun = level.gun_guns[i];
		if ( isStrStart( curGun, "rand_" ) )
		{
			level.gun_guns[i] = getRandomWeaponFromCategory( curGun );
		}
		else
		{
			baseWeapon = getBaseWeaponName( level.gun_guns[i] );
			level.selectedWeapons[ baseWeapon ] = true;
		}
	}
	
	level.selectedWeapons = undefined;
}

setSpecialLoadout()
{	
	//	no killstreaks defined for special classes		
	level.gun_loadouts["axis"]["loadoutPrimary"] = "iw6_sc2010";	//  can't use "none" for primary, this is replaced on spawn anyway
	level.gun_loadouts["axis"]["loadoutPrimaryAttachment"] = "none";
	level.gun_loadouts["axis"]["loadoutPrimaryAttachment2"] = "none";
	level.gun_loadouts["axis"]["loadoutPrimaryBuff"] = "specialty_null";
	level.gun_loadouts["axis"]["loadoutPrimaryCamo"] = "none";
	level.gun_loadouts["axis"]["loadoutPrimaryReticle"] = "none";
	
	level.gun_loadouts["axis"]["loadoutSecondary"] = "none";
	level.gun_loadouts["axis"]["loadoutSecondaryAttachment"] = "none";
	level.gun_loadouts["axis"]["loadoutSecondaryAttachment2"] = "none";
	level.gun_loadouts["axis"]["loadoutSecondaryBuff"] = "specialty_null";
	level.gun_loadouts["axis"]["loadoutSecondaryCamo"] = "none";
	level.gun_loadouts["axis"]["loadoutSecondaryReticle"] = "none";
	
	level.gun_loadouts["axis"]["loadoutEquipment"] = "specialty_null";
	level.gun_loadouts["axis"]["loadoutOffhand"] = "none";
	level.gun_loadouts[ "axis" ] [ "loadoutStreakType"	 ] = "assault";
	level.gun_loadouts[ "axis" ] [ "loadoutKillstreak1" ] = "none";
	level.gun_loadouts[ "axis" ] [ "loadoutKillstreak2" ] = "none";
	level.gun_loadouts[ "axis" ] [ "loadoutKillstreak3" ] = "none";
	level.gun_loadouts["axis"]["loadoutPerks"] = [ "specialty_quickswap", "specialty_marathon" ];
	
	level.gun_loadouts["axis"]["loadoutJuggernaut"]	= false;
	
	//	FFA games don't have teams, but players are allowed to choose team on the way in
	//	just for character model and announcer voice variety.  Same loadout for both.	
	level.gun_loadouts["allies"] = level.gun_loadouts["axis"];
}

buildRandomWeaponTable()
{
	level.weaponCategories = [];
	
	row = 0;
	while ( true )
	{
		// do I need to check against "#" values?
		
		categoryName = TableLookupByRow( CONST_WEAPON_TABLE, row, CONST_GROUP_NAME_IDX );
		if ( categoryName == "" )
			break;
	
		if ( !IsDefined( level.weaponCategories[ categoryName ] ) )
		{
			level.weaponCategories[ categoryName ] = [];
		}
		
		// 2014-01-31 wallace: we don't unlock dlc packs at the same time across all platforms		
		requiredPack = TableLookupByRow( CONST_WEAPON_TABLE, row, CONST_WEAPON_DLC_UNLOCK_IDX );
		if ( requiredPack == "" || GetDvarInt( requiredPack, 0 ) == 1 )
		{	
			data = [];
			data[ "weapon" ] = TableLookupByRow( CONST_WEAPON_TABLE, row, CONST_WEAPON_BASE_IDX );
			data[ "min" ] = Int( TableLookupByRow( CONST_WEAPON_TABLE, row, CONST_WEAPON_MIN_ATTACH_IDX ) );
			data[ "max" ] = Int( TableLookupByRow( CONST_WEAPON_TABLE, row, CONST_WEAPON_MAX_ATTACH_IDX ) );
			data[ "perk" ] = TableLookupByRow( CONST_WEAPON_TABLE, row, CONST_WEAPON_BONUS_PERK_IDX );
			
			level.weaponCategories[ categoryName ][ level.weaponCategories[ categoryName ].size ] = data;
		}
		
		row++;
	}
}

getRandomWeaponFromCategory( categoryName )
{
	weaponList = level.weaponCategories[ categoryName ];
	if ( IsDefined( weaponList ) && weaponList.size > 0 )
	{
		newWeapon = "";
		data = undefined;
		
		// make sure we haven't already selected this weapon
		loopCount = 0;
		while ( true )
		{
			index = RandomIntRange( 0, weaponList.size );
			data = weaponList[ index ];
			
			baseWeapon = getBaseWeaponName( data[ "weapon" ] );
			if ( !IsDefined( level.selectedWeapons[ baseWeapon ] ) 
			    || loopCount > weaponList.size )	// give up if we've looped too many times
			{
				level.selectedWeapons[ baseWeapon ] = true;
				newWeapon = data[ "weapon" ];
				break;
			}
			
			loopCount++;
		}
		
		// add random attachments
		// otherwise, we assume the newWeapon already includes some attachment configs
		if ( newWeapon == baseWeapon )
		{
			numAttachments = RandomIntRange( data[ "min" ], data[ "max" ] + 1 );
			newWeapon = modifyWeapon( newWeapon, numAttachments );
		}
		
		// should try to return the perk, too?
		
		return newWeapon;
	}
	else
	{
		// error
		AssertMsg( "Unknown weapon category name " + categoryName );
		return "none";
	}
}

// this is adapated from sotf
modifyWeapon( baseWeapon, numAttachments )
{
	// Attachments for the weapon
	chosenAttachments = [];
	hasScopeAttach = false;
	
	if ( numAttachments > 0 )
	{
		allAttachments = getWeaponAttachmentArrayFromStats( baseWeapon );
		
		if ( allAttachments.size > 0 )
		{
			validAttachments = getValidAttachments( allAttachments );
			
			/#
				Print( "gun: attempting to modify " + baseWeapon + " with " + numAttachments + " of " + validAttachments.size + " attachments\n" );
			#/
			
			//2014-01-08 wllace: arbitrary cap so we don't loop forever
			// we could recreate validAttachments each time we select an attachment to filter out the bad ones, but I'm lazy.
			maxAttempts = validAttachments.size;	
			for ( i = 0; i < numAttachments; i++ )
			{
				newAttachment = "";
				while ( newAttachment == "" && maxAttempts > 0 )
				{
					maxAttempts--;
					
					randomIndex = RandomInt( validAttachments.size );
					if ( maps\mp\gametypes\sotf::attachmentCheck( validAttachments[ randomIndex ], chosenAttachments ) )
					{
					    newAttachment = attachmentMap_toUnique( validAttachments[ randomIndex ], baseWeapon );
					    
					    chosenAttachments[ chosenAttachments.size ] = newAttachment;
					    
					    if ( getAttachmentType( newAttachment ) == "rail" )
					    {
					    	hasScopeAttach = true;
					    }
					}
				}
			}
		}
	}
	
	// randomly select camos, reticles. 0 = default
	camoIndex = 0;
	reticleIndex = 0;
	/*
	modifyChance = RandomFloat(1.0);
	if ( hasScopeAttach && modifyChance < CONST_RETICLE_CHANCE )
	{
		reticleIndex = RandomIntRange( 1, CONST_NUM_RETICLES );
	}
	
	if ( modifyChance < CONST_CAMO_CHANCE 
	    && maps\mp\gametypes\_class::isValidPrimary( baseWeapon, false ) 
	    && !maps\mp\gametypes\_weapons::isKnifeOnly( baseWeapon ) 
	   )
	{
		camoNum = RandomIntRange( 1, CONST_NUM_CAMOS );
		camoIndex = Int( TableLookup( CONST_CAMO_TABLE, 0, camoNum, CONST_CAMO_ID_IDX ) );
	}
	*/
	
	// what happens if you try to attach a reticle if the gun has no scope?
	newWeapon = buildWeaponName( baseWeapon, chosenAttachments, camoIndex, reticleIndex );
			
	return newWeapon;
}

getValidAttachments( attachmentArray )
{
	validAttachments = [];
	
	foreach ( attachment in attachmentArray )
	{
		switch ( attachment )
		{
			// reject some attachments that would not be fun in gun game.
			case "gl":
			case "shotgun":
			case "silencer":
			case "firetypesingle":
			case "firetypeburst":
			case "firetypeauto":	// this would be fine, but eh.
			case "ammoslug":
				break;
			default:
				validAttachments[ validAttachments.size ] = attachment;
		}
	}
	
	return validAttachments;
}

giveOrTakeThrowingKnife( currentWeapon )
{
	if ( maps\mp\gametypes\_weapons::isKnifeOnly( currentWeapon ) )
	{
		self givePerkEquipment( "throwingknife_mp", true );
		
		self.loadoutPerkEquipment = "throwingknife_mp";
		self givePerk( "specialty_extra_deadly", false );
		self givePerk( "specialty_scavenger", false );
	}
	else
	{
		self TakeWeapon( "throwingknife_mp" );
		self givePerkEquipment( "specialty_null", true );
	}
}

isValidThrowingKnifeKill( killWeapon )
{
	return ( killWeapon == "throwingknife_mp" && IsDefined( self.loadoutPerkEquipment ) && self.loadoutPerkEquipment == "throwingknife_mp" );
}

onPlayerScore( event, player, victim )
{
	score = 0;
	
	if ( event == "gained_gun_score"
		|| event == "dropped_gun_score" )
	{
		score = maps\mp\gametypes\_rank::getScoreInfoValue( event );
		Assert( IsDefined( score ) );
	}
	
	return score;
}
