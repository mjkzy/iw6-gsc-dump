#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_class;
#include maps\mp\gametypes\_hud_util;

/*
	Survival of the Fittest
	Objective: 	Eliminate opposing players
	Map ends:	First player to 15 kills is the winner
	Respawning:	No wait 

	Level requirements
	------------------
		Spawnpoints:
			// FFA 
			classname		mp_dm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of enemies at the time of spawn.
			Players generally spawn away from enemies.

			// TDM
			classname		mp_tdm_spawn
			All players spawn from these. The spawnpoint chosen is dependent on the current locations of teammates and enemies
			at the time of spawn. Players generally spawn behind their teammates relative to the direction of enemies.		
			
		Spectator Spawnpoints:
			classname		mp_global_intermission
			Spectators spawn from these and intermission is viewed from these positions.
			Atleast one is required, any more and they are randomly chosen between.
			
		Chest Spawnpoints:
			Key 			targetname
			Value 			sotf_chest_spawnpoint
			Each spawnpoint is set up as a script > struct in the map, with the key/value above
			Set as many as you like to exand the number of spawn points
*/

/*QUAKED mp_dm_spawn (1.0 0.5 0.0) (-16 -16 0) (16 16 72)
Players spawn away from enemies at one of these positions.*/

////////////////////////
// Constants
////////////////////////
CONST_MAX_ATTACHMENTS = 4;
CONST_CRATE_LIFE = 60;
CONST_CRATE_USE_TIME_OVERRIDE = 500;
CONST_WEAPON_NAME_COL = 2;
CONST_WEAPON_SELECTABLE_COL = 3;
CONST_DLC_MAPPACK_COL = 4;

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
		// Initialize all of the Dvars for this game mode
		registerScoreLimitDvar( level.gameType, 65 );
		registerTimeLimitDvar( level.gameType, 10 );		
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 );
		
		level.matchRules_randomize		  = 0;
		level.matchRules_damageMultiplier = 0;
		level.matchRules_vampirism		  = 0;
	}
	
	// Set the player loadout for this mode
	setPlayerLoadout();
	
	// SoTF is a FFA game mode
	SetTeamMode( "ffa" );
	level.teamBased			   = false;
	level.overrideCrateUseTime = CONST_CRATE_USE_TIME_OVERRIDE;
	level.onPlayerScore		   = ::onPlayerScore;
	level.onPrecacheGameType   = ::onPrecacheGameType;
	level.onStartGameType	   = ::onStartGameType;
	level.getSpawnPoint		   = ::getSpawnPoint;
	level.onSpawnPlayer		   = ::onSpawnPlayer;
	level.onNormalDeath		   = ::onNormalDeath;
	level.customCrateFunc	   = ::sotfCrateContents;
	level.crateKill			   = ::crateKill;
	level.pickupWeaponHandler  = ::pickupWeaponHandler;
	level.iconVisAll		   = ::iconVisAll;
	level.objVisAll			   = ::objVisAll;
	
	// Kill intels for this mode
	level.supportIntel	  = false;
	level.supportNuke	  = false;
	level.vehicleOverride = "littlebird_neutral_mp";
	
	// Storage to keep track of positions of where crates have been dropped
	level.usedLocations	 = [];
	level.emptyLocations = true;
	
	level.assists_disabled = true;
	
	if ( level.matchRules_damageMultiplier || level.matchRules_vampirism )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;
	
	game["dialog"]["gametype"] = "hunted";
	
	if ( getDvarInt( "g_hardcore" ) )
		game["dialog"]["gametype"] = "hc_" + game["dialog"]["gametype"];
	
	game["dialog"]["offense_obj"] = "sotf_hint";
	game["dialog"]["defense_obj"] = "sotf_hint";
}

initializeMatchRules()
{
	Assert( IsUsingMatchRulesData() );

	//	set common values
	setCommonRulesFromMatchRulesData();

	//	set everything else (private match options, default .cfg file values, and what normally is registered in the 'else' below)
	SetDynamicDvar( "scr_sotf_ffa_crateamount", GetMatchRulesData( "sotfFFAData", "crateAmount" ) );
	SetDynamicDvar( "scr_sotf_ffa_crategunamount", GetMatchRulesData( "sotfFFAData", "crateGunAmount" ) );
	SetDynamicDvar( "scr_sotf_ffa_cratetimer", GetMatchRulesData( "sotfFFAData", "crateDropTimer" ) );	
	
	SetDynamicDvar( "scr_sotf_ffa_roundlimit", 1 );
	registerRoundLimitDvar( "sotf_ffa", 1 );		
	SetDynamicDvar( "scr_sotf_ffa_winlimit", 1 );
	registerWinLimitDvar( "sotf_ffa", 1 );	
	SetDynamicDvar( "scr_sotf_ffa_halftime", 0 );
	registerHalfTimeDvar( "sotf_ffa", 0 );			

	SetDynamicDvar( "scr_sotf_ffa_promode", 0 );
}

onPrecacheGameType()
{
	// Precache any assets that need to be used within the game
	level._effect[ "signal_chest_drop" ] 	= LoadFX( "smoke/signal_smoke_airdrop" );
	level._effect[ "signal_chest_drop_mover" ] 	= LoadFX( "smoke/airdrop_flare_mp_effect_now" );
}

onStartGameType()
{	
	SetClientNameMode( "auto_change" );

	obj_text = &"OBJECTIVES_DM";
	obj_score_text = &"OBJECTIVES_DM_SCORE";
	obj_hint_text = &"OBJECTIVES_DM_HINT";
	
	setObjectiveText( "allies", obj_text );
	setObjectiveText( "axis", obj_text );

	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", obj_text );
		setObjectiveScoreText( "axis", obj_text );
	}
	else
	{
		setObjectiveScoreText( "allies", obj_score_text );
		setObjectiveScoreText( "axis", obj_score_text );
	}
	
	setObjectiveHintText( "allies", obj_hint_text );
	setObjectiveHintText( "axis", obj_hint_text );

	initSpawns();
	
	allowed = [];
	maps\mp\gametypes\_gameobjects::main( allowed );
	
	// Start threading the functions within the game
	level thread sotf();
}

////////////////////////
// Init functions
////////////////////////
initSpawns()
{
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_dm_spawn" );
	maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis"  , "mp_dm_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	SetMapCenter( level.mapCenter );
}

setPlayerLoadout()
{
	// Give the player 
	// o	Primary - Knife(?) Or Pistol
	// o	Tactical - flash
	// o	Lethal – Throwing Knife
	// o	NO KILLSTREAKS
	// o	NO PERKS 
	// o	(Possible update – Chests may also contain perks?)
	
	
	// Define what we will get from the crates
	defineChestWeapons();
	
	// Give a random pistol at the beginning of the match
	randomPistol = getRandomWeapon(level.pistolArray);
	
	// Used to display within the fake loadout screen
	pistolBaseName = getBaseWeaponName( randomPistol["name"] );
	pistolIndex = TableLookup( "mp/sotfWeapons.csv", 2, pistolBaseName, 0 );
	
	// Perform a reverse lookup so we know what to display
	SetOmnvar( "ui_sotf_pistol", int(pistolIndex) );
	
	level.sotf_loadouts[ "axis" ] [ "loadoutPrimary"			] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutPrimaryAttachment"	] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutPrimaryAttachment2" ] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutPrimaryBuff"		] = "specialty_null";
	level.sotf_loadouts[ "axis" ] [ "loadoutPrimaryCamo"		] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutPrimaryReticle"		] = "none";
//---------------------------------------------------------------------------------------
	level.sotf_loadouts[ "axis" ] [ "loadoutSecondary"			  ] = randomPistol["name"];
	level.sotf_loadouts[ "axis" ] [ "loadoutSecondaryAttachment"  ] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutSecondaryAttachment2" ] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutSecondaryBuff"		  ] = "specialty_null";
	level.sotf_loadouts[ "axis" ] [ "loadoutSecondaryCamo"		  ] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutSecondaryReticle"	  ] = "none";
//---------------------------------------------------------------------------------------
	level.sotf_loadouts[ "axis" ] [ "loadoutEquipment"	 ] = "throwingknife_mp";
	level.sotf_loadouts[ "axis" ] [ "loadoutOffhand"	 ] = "flash_grenade_mp";
	level.sotf_loadouts[ "axis" ] [ "loadoutStreakType"	 ] = "assault";
	level.sotf_loadouts[ "axis" ] [ "loadoutKillstreak1" ] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutKillstreak2" ] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutKillstreak3" ] = "none";
	level.sotf_loadouts[ "axis" ] [ "loadoutJuggernaut"	 ] = false;
	level.sotf_loadouts[ "axis" ] [ "loadoutPerks"		 ] = [ "specialty_longersprint", "specialty_extra_deadly" ];
	
	//	FFA games don't have teams, but players are allowed to choose team on the way in
	//	just for character model and announcer voice variety.  Same loadout for both.	
	level.sotf_loadouts[ "allies" ] = level.sotf_loadouts[ "axis" ];
}

getSpawnPoint()
{	
	spawnPoints = maps\mp\gametypes\_spawnlogic::getTeamSpawnPoints( self.team );
	
	if( level.inGracePeriod )
	{
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		spawnPoint = maps\mp\gametypes\_spawnscoring::getSpawnpoint_FreeForAll( spawnPoints );
	}

	return spawnPoint;
}

onSpawnPlayer()
{	
	//	onSpawnPlayer() gets called before giveLoadout()
	//	So make sure to tell giveLoadout() where to search/apply the new loadout
	
	// Set the class when looking in giveLoadout(), so it knows what to replace
	// Gamemode is the only class used within SOTF
	self.pers[ "class"	   ] = "gamemode";
	self.pers[ "lastClass" ] = "";
	self.class				 = self.pers[ "class" ];
	self.lastClass			 = self.pers[ "lastClass" ];

	// Set the loadout to give the player when going through giveLoadout()
	// The loadout is set within setPlayerLoadout()
	self.pers[ "gamemodeLoadout" ] = level.sotf_loadouts[ self.pers[ "team" ]];
	
	level notify( "sotf_player_spawned", self );
	
	// Keep track of what the "kill" value
	// This value will be used to calculate the score in the front end match summary
	if ( !isDefined( self.eventValue ) )
	{
		self.eventValue = maps\mp\gametypes\_rank::getScoreInfoValue( "kill" );
		self setExtraScore0( self.eventValue );
	}	
	
	self.oldPrimaryGun = undefined;
	self.newPrimaryGun = undefined;
	
	self thread waitLoadoutDone();
}

waitLoadoutDone()
{	
	level endon( "game_ended" );
	self endon( "disconnect" );
	
	// waiting for giveLoadout();
	self waittill ( "giveLoadout" );
	
	// Clear the player's initial primary weapon stock
	playerWeapon = self GetCurrentWeapon();
	self SetWeaponAmmoStock( playerWeapon, 0 );	
	self.oldPrimaryGun = playerWeapon;
	
	self thread pickupWeaponHandler();
}

onPlayerScore( event, player, victim )
{
	player.assists = player getPersStat( "longestStreak" );
	
	if( event == "kill" )
	{
		score = maps\mp\gametypes\_rank::getScoreInfoValue( "score_increment" );
		assert( isDefined( score ) );
		
		return score;
	}
	
	return 0;
}

onNormalDeath( victim, attacker, lifeId )
{
	attacker perkWatcher();
		
	score = maps\mp\gametypes\_rank::getScoreInfoValue( "score_increment" );
	assert( isDefined( score ) );

	// get the highest score
	highestScore = 0;
	
	foreach ( player in level.players )
	{
		if ( IsDefined( player.score ) && player.score > highestScore )
			highestScore = player.score;
	}
	
	if ( game[ "state" ] == "postgame" && attacker.score >= highestScore )
		attacker.finalKill = true;
}

////////////////////////
// Game functions
////////////////////////
sotf()
{	
	// Spawn in the chests!
	level thread startSpawnChest();
}

startSpawnChest()
{
	level endon( "game_ended" );
	self endon( "disconnect" );
	
	// Private Match Rules
	crateAmount = GetDvarInt( "scr_sotf_ffa_crateamount", 3 );
	crateTimer = GetDvarInt( "scr_sotf_ffa_cratetimer", 30 );	
	
	// Wait till a player has spawned in the game
	level waittill( "sotf_player_spawned", player );
	
	for ( ;; )
	{
		// Find a valid owner
		// If the first owner is no longer in the game, find another
		if ( !IsAlive( player ) )
		{
		   player = findNewOwner( level.players );
		   
		   if ( !IsDefined( player ) )
		   	continue;
		}
		else
		{
			// As long as there is a owner, continue to call in chests
			while ( IsAlive( player ) )
			{
				if ( level.emptyLocations )
				{	
					for ( i = 0; i < crateAmount; i++ )
					{	
						level thread spawnChests( player );
					}
		
					// Wait till it checks all the locations seeing if new drops are coming in
					level thread showCrateSplash("sotf_crates_incoming");

					wait ( crateTimer );
				}
				else
				{
					// Wait a frame and then check again if there is an empty space
					wait( 0.05 );
				}														
			}
		}
	}
}

showCrateSplash(splashRef)
{
	foreach(player in level.players)
	{
		player thread maps\mp\gametypes\_hud_message::SplashNotify( splashRef );	
	}
}

findNewOwner( playerPool )
{
	// Check within the player pool to see who is alive
	// Reminder: The player pool can still contain players who are in Spectator Mode
	foreach ( player in playerPool )
	{
		if ( IsAlive( player ) )
			return player;
	}
	
	// If there are no players alive within the pool, wait till a new player has spawned and pass him back
	level waittill( "sotf_player_spawned", newPlayer );
	return newPlayer;
}

spawnChests( player )
{	
	// Get all of the spawn locations for the chests
	chestSpawns = getstructarray( "sotf_chest_spawnpoint", "targetname" );
	
	// Grab a valid location 
	chestSpawnPoint = getRandomPoint( chestSpawns );
	
	if ( IsDefined( chestSpawnPoint ) )
	{
		// Set the marker effect at the location
		playFxAtPoint( chestSpawnPoint );
	
		// TODO: [Drop Zone Icon]
		// Implement additional weapon markers to make it read easier?
			
		// Call the heli to drop in the crate for the specified owner, and provided location
		level thread maps\mp\killstreaks\_airdrop::doFlyby( player, chestSpawnPoint, RandomFloat( 360 ), "airdrop_sotf" );
	}
}

playFxAtPoint( pos )
{
	// make sure that the point we've selected isn't floating in the air
	traceStart = pos + (0,0,30);
	traceEnd = pos + (0,0,-1000);
	trace = BulletTrace( traceStart, traceEnd, false, undefined );		
	
	spawnPoint = trace["position"]+(0,0,1);
		
	// there may be artifacts if something is in the way of the drop zone marker
	hitEntity = trace["entity"];
	if ( IsDefined( hitEntity ) )
	{
		// search up the links until we get the moving platform
		parent = hitEntity GetLinkedParent();
		while ( IsDefined( parent ) )
		{
			hitEntity = parent;
			parent = hitEntity GetLinkedParent();
		}
	}
		
	if ( IsDefined( hitEntity ) )
	{
		fxEntity = Spawn( "script_model", spawnPoint);
		fxEntity SetModel( "tag_origin" );
		fxEntity.angles = (90, RandomIntRange(-180, 179), 0);
		
		fxEntity LinkTo( hitEntity );
		
		// we have to use a different effect, because the burnt out smoke grenade stays behind, floating
		thread playLinkedSmokeEffect( getfx( "signal_chest_drop_mover" ), fxEntity );
	}
	else
	{
		PlayFx( getfx( "signal_chest_drop" ), spawnPoint );
	}
	
}

playLinkedSmokeEffect( fxId, fxEntity )
{
	level endon ( "game_ended" );
	
	wait ( 0.05 );
	
	PlayFXOnTag( fxId, fxEntity, "tag_origin" );
	
	wait ( 6 );
	
	StopFXOnTag( fxId, fxEntity, "tag_origin" );
	
	wait ( 0.05 );
	
	fxEntity Delete();
}

getCenterPoint( spawnPoints )
{
	chosenPoint = undefined;
	shortestDist = undefined;
	
	foreach ( point in spawnPoints )
	{
		distTest = Distance2DSquared(level.mapCenter, point.origin);
		
		if (!isDefined(chosenPoint) || distTest < shortestDist)
		{
			chosenPoint = point;
			shortestDist = distTest;
		}
	}

	level.usedLocations[ level.usedLocations.size ] = chosenPoint.origin;
	
	return chosenPoint.origin;
}

getRandomPoint( spawnPoints )
{	
	validLocations = [];
	
	// Look through all of the available spawn points
	for ( point = 0; point < spawnPoints.size; point++ )
	{
		usedLocationFound = false;
			
		// If there are previously used locations
		if ( IsDefined( level.usedLocations ) && level.usedLocations.size > 0 )
		{
			// Look through all of the locations and see which ones are used
			foreach ( usedLocation in level.usedLocations )
			{
				if ( spawnPoints[ point ].origin == usedLocation )
				{
					usedLocationFound = true;
					break;
				}
			}
			
			if ( usedLocationFound )
				continue;
			
			// Store all the remaining valid location(s)
			validLocations[ validLocations.size ] = spawnPoints[ point ].origin;
		}
		else
		{
			// Store all the valid location(s)
			validLocations[ validLocations.size ] = spawnPoints[ point ].origin;
		}
	}
			
	// If there are valid locations, grab one, and then store it as a used location
	if ( validLocations.size > 0 )
	{
		value											= RandomInt( validLocations.size );
		spawnLocation									= validLocations[ value ];
		level.usedLocations[ level.usedLocations.size ] = spawnLocation;
	
		// Send back the valid location
		return spawnLocation;
	}
		
	// If there are no valid locations, then don't spawn anything
	level.emptyLocations = false;
	return undefined;
}

defineChestWeapons()
{	
	// Create a pistol array to only house the random starting weapon
	pistolArray = [];
	
	// Create a new array to store all of the main weapons we want in the chest
	weaponArray = [];
	
	// Perform a table lookup on sotfWeapons.csv, and store the weapons of the desired type into the array
	for ( row = 0; TableLookupByRow( "mp/sotfWeapons.csv", row, 0 ) != ""; row++ )
	{
		weaponName = TableLookupIStringByRow( "mp/sotfWeapons.csv", row, 2 );
  		weaponGroup = TableLookupIStringByRow( "mp/sotfWeapons.csv", row, 1 );
  		
  		// Make sure we are picking from a list of weapons that can be used in game
  		selectableWeapon = isSelectableWeapon(weaponName);
  		
    	if ( IsDefined( weaponGroup ) && selectableWeapon && ( weapongroup == "weapon_pistol" ) )
		{
		    weaponWeight = 30;
			
			// Make sure we omit the "_mp" string to the names, otherwise the system wil not reconize these weapons
			pistolArray[ pistolArray.size	  ] [ "name"   ] = weaponName;
			pistolArray[ pistolArray.size - 1 ] [ "weight" ] = weaponWeight;
  		}		

  		// Add custom weight to each weapon of that group
  		// Higher the weight, the better chance the group of weapons will drop
		else if ( IsDefined( weaponGroup ) && selectableWeapon &&
		    ( weapongroup == "weapon_shotgun" ||
		      weapongroup == "weapon_smg" ||
		      weapongroup == "weapon_assault" ||
		      weapongroup == "weapon_sniper" ||
		      weapongroup == "weapon_dmr" ||
		      weapongroup == "weapon_lmg" ||
			  weapongroup == "weapon_projectile" ) )
		{
		    weaponWeight = 0;
		    
			switch( weaponGroup )
			{
				case "weapon_shotgun":
					weaponWeight = 35;
					break;					
				
				case "weapon_smg":
				case "weapon_assault":	
					weaponWeight = 25;
					break;
					
				case "weapon_sniper":
				case "weapon_dmr":						
					weaponWeight = 15;
					break;					

				case "weapon_lmg":	
					weaponWeight = 10;
					break;				
					
				case "weapon_projectile":
					weaponWeight = 30;
					break;						
			}

			// Make sure we append the "_mp" string to the names, otherwise the system wil not recognize these weapons
			weaponArray[ weaponArray.size	  ] [ "name"   ] = weaponName + "_mp";
			weaponArray[ weaponArray.size - 1 ] [ "group"  ] = weaponGroup;
			weaponArray[ weaponArray.size - 1 ] [ "weight" ] = weaponWeight;
		}
		else
			continue;
	}
	
	// We need to sort the weapons according to weight
	weaponArray = sortByWeight( weaponArray );
	
	level.pistolArray = pistolArray;
	level.weaponArray = weaponArray;
}

sotfCrateContents( friendly_crate_model, enemy_crate_model )
{	
	//"Press and hold [{+activate}] for a Random Weapon"
	maps\mp\killstreaks\_airdrop::addCrateType(	"airdrop_sotf",	"sotf_weapon",	100, ::sotfCrateThink, friendly_crate_model, friendly_crate_model,	&"KILLSTREAKS_HINTS_WEAPON_PICKUP" );
}

sotfCrateThink( dropType )
{
	self endon ( "death" );
	self endon ( "restarting_physics" );
	level endon ("game_ended");
	
	if ( IsDefined( game[ "strings" ][ self.crateType + "_hint" ] ) )
		crateHint = game[ "strings" ][ self.crateType + "_hint" ];
	else
		//"[{+activate}] Killstreak"
		crateHint = &"PLATFORM_GET_KILLSTREAK";
	
	weaponOverheadIcon = "icon_hunted";
	
	maps\mp\killstreaks\_airdrop::crateSetupForUse( crateHint, weaponOverheadIcon );
	
	self thread maps\mp\killstreaks\_airdrop::crateAllCaptureThink();
	
	// Manually delete the crate after a set amount of time
	self childthread crateWatcher( CONST_CRATE_LIFE );
	
	// If the player joins in mid match, make sure to show them the current head icon for the crate
	self childthread playerJoinWatcher();
	
	crateUseCount = 0;
	crateRemainingUses = GetDvarInt( "scr_sotf_ffa_crategunamount", 1 );
	
	// Wait till the player has captured the crate, and then proceed to give them a new weapon, or replace existing
	for ( ;; )
	{	
		self waittill ( "captured", player );
				
		player PlayLocalSound( "ammo_crate_use" );		
		
		// Get randomized weapon
		newWeapon = getRandomWeapon( level.weaponArray );
	
		// Get randomized weapon attachment(s)
		newWeapon = getRandomAttachments( newWeapon );
		
		// See how much ammo the player had for the last weapon
		playerPrimary = player.lastDroppableWeapon;
		lastAmmoCount = player GetAmmoCount( playerPrimary );
		
		// If the player already has the weapon, then give them the remaining ammo to the stock
		if ( newWeapon == playerPrimary )
		{
			player GiveStartAmmo( newWeapon );
			player SetWeaponAmmoStock( newWeapon, lastAmmoCount );
		}
		else
		{
			// Does the player have a primary weapon?
			// Bot support
			if ( IsDefined( playerPrimary ) && playerPrimary != "none" )
			{
				dropped_weapon = player DropItem( playerPrimary );
				if ( IsDefined( dropped_weapon ) && lastAmmoCount > 0 )
				{
					dropped_weapon.targetname = "dropped_weapon";
				}
			}
				
			// Give the player the new weapon
			player giveWeapon( newWeapon, 0, false, 0, true);
			player SetWeaponAmmoStock( newWeapon, 0 );
			player SwitchToWeaponImmediate( newWeapon );
			
			// If the new weapon only has 1 bullet in the clip, give it at least 1 ammo in the stock
			// This is mostly for grenade launchers/rpgs
			if ( player GetWeaponAmmoClip( newWeapon ) == 1 )
				player SetWeaponAmmoStock ( newWeapon, 1 );
			
			player.oldPrimaryGun = newWeapon;
		}
		
		crateUseCount++;
		
		// Show the remaining uses for the crate
		crateRemainingUses = crateRemainingUses - 1;
		
		if (crateRemainingUses > 0 )
		{
			foreach (player in level.players)
			{
				self maps\mp\_entityheadIcons::setHeadIcon( player, "blitz_time_0" + crateRemainingUses + "_blue", ( 0, 0, 24 ), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
				self.crateHeadIcon = "blitz_time_0" + crateRemainingUses + "_blue";
			}
		}
		
		if ( self.crateType == "sotf_weapon" && crateUseCount == GetDvarInt( "scr_sotf_ffa_crategunamount", 1 ) )
			self maps\mp\killstreaks\_airdrop::deleteCrate();		
	}
}

crateWatcher(delay)
{	
	// Wait for 60 seconds before we kill the existing crate
	wait ( delay );
	
	// Make sure the crate does not go away as long as the player is capturing it
	while( IsDefined(self.inUse) && self.inUse )
	{
		waitframe();
	}
	
	self maps\mp\killstreaks\_airdrop::deleteCrate();	
}

playerJoinWatcher()
{	
	while (true)
	{
		level waittill( "connected", player );
		
		if (!isDefined(player))
			continue;
		
		self maps\mp\_entityheadIcons::setHeadIcon( player, self.crateHeadIcon, ( 0, 0, 24 ), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
	}
}

crateKill( dropPoint )
{
	// Clear the position used by the killed crate
	// This happens when either the player picks up the crate, or the crate dies naturally
	for ( i = 0; i < level.usedLocations.size; i++ )
	{
		if ( dropPoint != level.usedLocations[ i ] )
			continue;
		
		level.usedLocations = array_remove(level.usedLocations, dropPoint);
	}
	
	// We have at least one position open, let's continue to drop crates
	level.emptyLocations = true;	
}

isSelectableWeapon(weaponName)
{
	selectableWeapon = TableLookup( "mp/sotfWeapons.csv", CONST_WEAPON_NAME_COL, weaponName, CONST_WEAPON_SELECTABLE_COL );
	requiredPack = TableLookup( "mp/sotfWeapons.csv", CONST_WEAPON_NAME_COL, weaponName, CONST_DLC_MAPPACK_COL );
	
	if (selectableWeapon == "TRUE" && ( requiredPack == "" || GetDvarInt( requiredPack, 0 ) == 1 ) )
		return true;

	return false;	
}

getRandomWeapon( weaponArray )
{	
	// Store and grab the total bucket value of all the weights
	newWeaponArray = setBucketVal( weaponArray );
	
	// Send back a random pistol
	randValue = RandomInt( level.weaponMaxVal[ "sum" ] );
	
	newWeapon = undefined;
	
	for ( i = 0; i < newWeaponArray.size; i++ )
	{
		if ( !newWeaponArray[ i ][ "weight" ] )
			continue;
		if ( newWeaponArray[ i ][ "weight" ]  > randValue )
		{			
			newWeapon = newWeaponArray[ i ];
			break;
		}	
	}
	
	return newWeapon;
}

getRandomAttachments( newWeapon )
{
	// Attachments for the weapon
	validAttachments  = [];	
	usedAttachments	  = [];
	chosenAttachments = [];
	
	// Find the compatible attachments for the passed in weapon (without "_mp")
	baseName		= getBaseWeaponName( newWeapon[ "name" ] );
	attachmentArray = getWeaponAttachmentArrayFromStats( baseName );
	
	if ( attachmentArray.size > 0 )
	{
		// How many attachments do we want? From 0 to 4
		numAttachments = RandomInt( CONST_MAX_ATTACHMENTS + 1 );
			
		for ( i = 0; i < numAttachments; i++ )
		{
			// Grab all of the valid attachments
			validAttachments = getValidAttachments( newWeapon, usedAttachments, attachmentArray );
			
			// If there are no longer any valid attachments, break out
			if ( validAttachments.size == 0 )
				break;
			
			// Grab a random attachment index 
			randomIndex = RandomInt( validAttachments.size );
		
			// Store the used attachment
			usedAttachments[ usedAttachments.size ] = validAttachments[ randomIndex ];
			
			// Store the chosen attachment
			newAttachment								= attachmentMap_toUnique( validAttachments[ randomIndex ], baseName );
			chosenAttachments[ chosenAttachments.size ] = newAttachment;
		}
		
		weapClass = getWeaponClass( newWeapon[ "name" ] );
		
		// Check to see if this is a sniper,  if so make sure we have a scope (if there isn't any)
		if ( weapClass == "weapon_dmr" || weapClass == "weapon_sniper" || baseName == "iw6_dlcweap02" )
		{
			scopeFound = false;
			foreach ( attachName in usedAttachments )
			{
				if ( getAttachmentType( attachName ) == "rail" )
				{
					scopeFound = true;
					break;
				}
			}
			
			if ( !scopeFound )
			{
				nameMid = StrTok( baseName, "_" )[ 1 ];
				chosenAttachments[ chosenAttachments.size ] = nameMid + "scope";

			}
		}
		
		// Make sure the attachments are alphabetized
		if (chosenAttachments.size > 0)
		{
			chosenAttachments = alphabetize( chosenAttachments );
			
			foreach ( attachment in chosenAttachments )
			{
				newWeapon[ "name" ]	= newWeapon[ "name" ] + "_" + attachment;
			}
		}
	}

	return newWeapon[ "name" ];
}

getValidAttachments( newWeapon, usedAttachments, attachmentArray )
{
	validAttachments = [];
	
	// Look through all of the attachments for the gun
	foreach ( attachment in attachmentArray )
	{
		// Take out underbarrel lethals from the valid attachments
		if ( attachment == "gl" || attachment == "shotgun" )
			continue; 
		
		// Check to see if the attachment is already being used, or is compatible with the existing attachment(s)
		attachmentOK = attachmentCheck( attachment, usedAttachments );
		
		if ( !attachmentOK )
			continue;
		
		validAttachments[ validAttachments.size ] = attachment;
	}
	
	return validAttachments;
}

attachmentCheck( attachment, usedAttachments )
{
	for ( i = 0; i < usedAttachments.size; i++ )
	{	
		// If it is already an active attachment, or an incompatible attachment, return false
		if ( attachment == usedAttachments[ i ] || !attachmentsCompatible( attachment, usedAttachments[ i ] ) )
			return false;
	}	
	
	// Everything clear? 
	return true;
}

checkScopes( usedAttachments )
{
	foreach ( attachment in usedAttachments )
	{
		if ( attachment == "thermal" || attachment == "vzscope" || attachment == "acog" || attachment == "ironsight" )
			return true;
	}
	
	return false;
}

pickupWeaponHandler()
{	
	// self == player 
	
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while (true)
	{
		waitframe();
		
		playerPrimaries = self GetWeaponsListPrimaries();
		
		if ( playerPrimaries.size > 1 )
		{	
			foreach( weapon in playerPrimaries )
			{
				if ( weapon == self.oldPrimaryGun )
				{
					oldAmmo = self GetAmmoCount( weapon );
					dropped_weapon = self DropItem( weapon );
					if ( IsDefined( dropped_weapon ) && oldAmmo > 0 )
					{
						// Setting the targetname for bots, so they know it's a valid weapon to pick up
						dropped_weapon.targetname = "dropped_weapon";
					}
					break;					
				}
			}
			
			// Store the new gun
			playerPrimaries = array_remove ( playerPrimaries, self.oldPrimaryGun );
			self.oldPrimaryGun = playerPrimaries[0];
		}
	}
}

logIncKillChain()
{
	self.pers["killChains"]++;
	self maps\mp\gametypes\_persistence::statSetChild( "round", "killChains", self.pers["killChains"] );
}

perkWatcher()
{
	if( GetDvarInt("scr_game_perks") )
	{	
		// Give the players specific perks as they get kills
		switch ( self.adrenaline )
		{
			case 2:
				self givePerk( "specialty_fastsprintrecovery", false );
				self thread maps\mp\gametypes\_hud_message::splashNotify( "specialty_fastsprintrecovery_sotf", self.adrenaline );
				self thread logIncKillChain();
				break;
			case 3:
				self givePerk( "specialty_lightweight", false );
				self thread maps\mp\gametypes\_hud_message::splashNotify( "specialty_lightweight_sotf", self.adrenaline );
				self thread logIncKillChain();
				break;
			case 4:
				self givePerk( "specialty_stalker", false );
				self thread maps\mp\gametypes\_hud_message::splashNotify( "specialty_stalker_sotf", self.adrenaline );
				self thread logIncKillChain();
				break;
			case 5:
				self givePerk( "specialty_regenfaster", false );
				self thread maps\mp\gametypes\_hud_message::splashNotify( "specialty_regenfaster_sotf", self.adrenaline );
				self thread logIncKillChain();
				break;
			case 6:
				self givePerk( "specialty_deadeye", false );
				self thread maps\mp\gametypes\_hud_message::splashNotify( "specialty_deadeye_sotf", self.adrenaline );
				self thread logIncKillChain();
				break;
		}
	}
}

iconVisAll( crate, icon )
{
	// Make sure everyone can see the head icon set for the crate
	foreach ( player in level.players )
	{
		crate maps\mp\_entityheadIcons::setHeadIcon( player, icon, ( 0, 0, 24 ), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
		self.crateHeadIcon = icon;
	}	
}

objVisAll( objID )
{
	// Make sure everyone can see the objective set for the crate		
	Objective_PlayerMask_ShowToAll( objID );
}

setBucketVal( weaponArray )
{	
	level.weaponMaxVal[ "sum" ] = 0;
	
	modWeaponArray = weaponArray;
	
	for ( i = 0; i < modWeaponArray.size; i++ )
	{
		if ( !modWeaponArray[ i ][ "weight" ] )
			continue;
		
		level.weaponMaxVal[ "sum" ]   += modWeaponArray[ i ][ "weight" ];
		modWeaponArray[ i ][ "weight" ] = level.weaponMaxVal[ "sum" ];
	}
	
	return modWeaponArray;
}

sortByWeight( weaponArray )
{
	nextWeapon = [];
	prevWeapon = [];
	
	// Go through the array, starting at index [1]
	for ( nextIndex = 1; nextIndex < weaponArray.size; nextIndex++ )
	{
		// Set the weight that you want to compare
		nextWeight = weaponArray[ nextIndex ][ "weight" ];
		nextWeapon = weaponArray[ nextIndex ];
		
		// Next go through the loop through again starting at index [0]
		for ( prevIndex = nextIndex - 1; ( prevIndex >= 0 ) && is_weight_a_less_than_b( weaponArray[ prevIndex ][ "weight" ], nextWeight ); prevIndex-- )
		{
			// If the current weight is not less than the current weight 
			// Set the nextIndex's weight to the prevIndex weight
			prevWeapon = weaponArray[ prevIndex ];
			
			weaponArray[ prevIndex	   ] = nextWeapon;
			weaponArray[ prevIndex + 1 ] = prevWeapon;
		}
	}
	
	return weaponArray;
}

is_weight_a_less_than_b( a, b )
{
	return ( a < b );
}
