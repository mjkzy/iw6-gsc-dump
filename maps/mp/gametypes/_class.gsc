#include common_scripts\utility;
// check if below includes are removable
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

KILLSTREAK_GIMME_SLOT = 0;
KILLSTREAK_SLOT_1 = 1;
KILLSTREAK_SLOT_2 = 2;
KILLSTREAK_SLOT_3 = 3;
KILLSTREAK_ALL_PERKS_SLOT = 4;
KILLSTREAK_STACKING_START_SLOT = 5;

PRIMARY_GRENADE_INDEX = 0;
SECONDARY_GRENADE_INDEX = 1;

NUM_ABILITY_CATEGORIES = 7;
NUM_SUB_ABILITIES = 5;

CONST_CLASS_PERK_POINTS = 8;

init()
{
	level.classMap["class0"] = 0;
	level.classMap["class1"] = 1;
	level.classMap["class2"] = 2;
	
	level.classMap["custom1"] = 0;
	level.classMap["custom2"] = 1;
	level.classMap["custom3"] = 2;
	level.classMap["custom4"] = 3;
	level.classMap["custom5"] = 4;
	level.classMap["custom6"] = 5;
	level.classMap["custom7"] = 6;
	level.classMap["custom8"] = 7;
	level.classMap["custom9"] = 8;
	level.classMap["custom10"] = 9;
	
	level.classMap["axis_recipe1"] = 0;
	level.classMap["axis_recipe2"] = 1;
	level.classMap["axis_recipe3"] = 2;
	level.classMap["axis_recipe4"] = 3;
	level.classMap["axis_recipe5"] = 4;
	level.classMap["axis_recipe6"] = 5;

	level.classMap["allies_recipe1"] = 0;
	level.classMap["allies_recipe2"] = 1;
	level.classMap["allies_recipe3"] = 2;
	level.classMap["allies_recipe4"] = 3;
	level.classMap["allies_recipe5"] = 4;
	level.classMap["allies_recipe6"] = 5;

	level.classMap["gamemode"] = 0;
	
	level.classMap["callback"] = 0;

	/#
	// classes testclients may choose from.
	level.botClasses = [];
	level.botClasses[0] = "class0";
	level.botClasses[1] = "class0";
	level.botClasses[2] = "class0";
	level.botClasses[3] = "class0";
	level.botClasses[4] = "class0";
	#/
	
	level.defaultClass = "CLASS_ASSAULT";
	
	level.classTableName = "mp/classTable.csv";
	
	level thread onPlayerConnecting();
}


getClassChoice( response )
{
	assert( isDefined( level.classMap[response] ) );
	
	return response;
}

getWeaponChoice( response )
{
	tokens = strtok( response, "," );
	if ( tokens.size > 1 )
		return int(tokens[1]);
	else
		return 0;
}


logClassChoice( class, primaryWeapon, specialType, perks )
{
	if ( class == self.lastClass )
		return;

	self logstring( "choseclass: " + class + " weapon: " + primaryWeapon + " special: " + specialType );		
	for( i=0; i<perks.size; i++ )
		self logstring( "perk" + i + ": " + perks[i] );
	
	self.lastClass = class;
}

cac_getWeapon( classIndex, weaponIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "weaponSetups", weaponIndex, "weapon" );
}

cac_getWeaponAttachment( classIndex, weaponIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "weaponSetups", weaponIndex, "attachment", 0 );
}

cac_getWeaponAttachmentTwo( classIndex, weaponIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "weaponSetups", weaponIndex, "attachment", 1 );
}

cac_getWeaponAttachmentThree( classIndex, weaponIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "weaponSetups", weaponIndex, "attachment", 2 );
}

cac_getWeaponBuff( classIndex, weaponIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "weaponSetups", weaponIndex, "buff" );
}

cac_getWeaponCamo( classIndex, weaponIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "weaponSetups", weaponIndex, "camo" );
}

cac_getWeaponReticle( classIndex, weaponIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "weaponSetups", weaponIndex, "reticle" );
}

cac_getPerk( classIndex, perkIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "perks", perkIndex );
}

cac_getKillstreak( classIndex, index )
{
	return self getCaCPlayerData( "loadouts", classIndex, "killstreaks", index );	
}

cac_getKillstreakWithType( class_num, streakType, streakIndex )
{
	playerData = undefined;
	switch( streakType )
	{
	case "streaktype_support":
		playerData = "supportStreaks";
		break;
	case "streaktype_specialist":
		playerData = "specialistStreaks";
		break;
	default: // assault
		playerData = "assaultStreaks";
		break;
	}
	return self getCaCPlayerData( "loadouts", class_num, playerData, streakIndex );
}

cac_getCharacterType( classIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "type" );
}

/*
cac_getAmmoType( classIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "perks", 6 );
}
*/

cac_getPrimaryGrenade( classIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "perks", PRIMARY_GRENADE_INDEX );
}

cac_getSecondaryGrenade( classIndex )
{
	return self getCaCPlayerData( "loadouts", classIndex, "perks", SECONDARY_GRENADE_INDEX );
}

recipe_getKillstreak( teamName, classIndex, streakType, streakIndex )
{
	playerData = undefined;
	switch( streakType )
	{
	case "streaktype_support":
		playerData = "supportStreaks";
		break;
	case "streaktype_specialist":
		playerData = "specialistStreaks";
		break;
	default: // assault
		playerData = "assaultStreaks";
		break;
	}
	return getMatchRulesData( "defaultClasses", teamName, classIndex, "class", playerData, streakIndex );
}

table_getWeapon( tableName, classIndex, weaponIndex )
{
	if ( weaponIndex == 0 )
		return TableLookup( tableName, 0, "loadoutPrimary", classIndex + 1 );
	else
		return TableLookup( tableName, 0, "loadoutSecondary", classIndex + 1 );
}

table_getWeaponAttachment( tableName, classIndex, weaponIndex, attachmentIndex )
{
	tempName = "none";
	
	if ( weaponIndex == 0 )
	{
		if ( !isDefined( attachmentIndex ) || attachmentIndex == 0 )
			tempName = TableLookup( tableName, 0, "loadoutPrimaryAttachment", classIndex + 1 );
		else if ( attachmentIndex == 1 )
			tempName = TableLookup( tableName, 0, "loadoutPrimaryAttachment2", classIndex + 1 );
		else if ( attachmentIndex == 2 )
			tempName = TableLookup( tableName, 0, "loadoutPrimaryAttachment3", classIndex + 1 );
	}
	else
	{
		if ( !isDefined( attachmentIndex ) || attachmentIndex == 0 )
			tempName = TableLookup( tableName, 0, "loadoutSecondaryAttachment", classIndex + 1 );
		else
			tempName = TableLookup( tableName, 0, "loadoutSecondaryAttachment2", classIndex + 1 );
	}
	
	if ( tempName == "" || tempName == "none" )
		return "none";
	else
		return tempName;
	
	
}

table_getWeaponBuff( tableName, classIndex, weaponIndex )
{
	if ( weaponIndex == 0 )
		return TableLookup( tableName, 0, "loadoutPrimaryBuff", classIndex + 1 );
	else
		return TableLookup( tableName, 0, "loadoutSecondaryBuff", classIndex + 1 );
}

table_getWeaponCamo( tableName, classIndex, weaponIndex )
{
	return "none";
// right not only the classTable is using this and we don't want weapon camo on default classes
//	if ( weaponIndex == 0 )
//		return TableLookup( tableName, 0, "loadoutPrimaryCamo", classIndex + 1 );
//	else
//		return TableLookup( tableName, 0, "loadoutSecondaryCamo", classIndex + 1 );
}

table_getWeaponReticle( tableName, classIndex, weaponIndex )
{
	return "none";
}

table_getEquipment( tableName, classIndex, perkIndex )
{
	assert( perkIndex < 5 );
	return TableLookup( tableName, 0, "loadoutEquipment", classIndex + 1 );
}

table_getPerk( tableName, classIndex, perkIndex )
{
	assert( perkIndex <= 6 );
	return TableLookup( tableName, 0, "loadoutPerk" + perkIndex, classIndex + 1 );
}

table_getTeamPerk( tableName, classIndex )
{
	return TableLookup( tableName, 0, "loadoutTeamPerk", classIndex + 1 );
}

table_getOffhand( tableName, classIndex )
{
	return TableLookup( tableName, 0, "loadoutOffhand", classIndex + 1 );
}

table_getKillstreak( tableName, classIndex, streakIndex )
{
	return TableLookup( tableName, 0, "loadoutStreak" + streakIndex, classIndex + 1 );
}

table_getCharacterType( tableName, classIndex )
{
	return TableLookup( tableName, 0, "loadoutCharacterType", classIndex + 1 );
}

//avoiding going through code for extra perk types
loadoutFakePerks( loadoutStreakType, loadoutAmmoType )
{
	switch ( loadoutStreakType )
	{
		case "streaktype_support":
			self.streakType = "support";
			break;
		case "streaktype_specialist":
			self.streakType = "specialist";
			break;
		default: // assault/null:
			self.streakType = "assault";		 
	}
	
	//self.ammoType = loadoutAmmoType;
}

getLoadoutStreakTypeFromStreakType( streakType )
{
	if ( !isDefined( streakType ) )
	{
		assertEx( false, "getLoadoutStreakTypeFromStreakType() called with undefined streaktype" );
		return "streaktype_assault";
	}
	
	switch ( streakType )
	{
		case "support":
			return "streaktype_support";
		case "specialist":
			return "streaktype_specialist";
		case "assault":
			return "streaktype_assault";
		default: 
			assertEx( false, "getLoadoutStreakTypeFromStreakType() called with unknown streaktype" );		
			return "streaktype_assault"; 
	}	
}

giveLoadout( team, class, setPrimarySpawnWeapon ) // setPrimarySpawnWeapon only when called during spawn
{
	self.gettingLoadout = true;
	
	self takeAllWeapons();
	
	self.changingWeapon = undefined;

	teamName = "none";
	if ( !isDefined( setPrimarySpawnWeapon ) )
		setPrimarySpawnWeapon = true;

	primaryIndex = 0;
	
	// initialize specialty array
	self.specialty = [];

	primaryWeapon = undefined;
	
	clearAmmo = false;
	
	//	set in game mode custom class
	loadoutKillstreak1 = undefined;
	loadoutKillstreak2 = undefined;
	loadoutKillstreak3 = undefined;	
	loadoutPerksOverride = [];
	if( isSubstr( class, "axis" ) )
	{
	    teamName = "axis";
	}
	else if( isSubstr( class, "allies" ) )
	{
	    teamName = "allies";
	}

	if ( teamName != "none" )
	{
		classIndex = getClassIndex( class );
		self.class_num = classIndex;
		self.teamName = teamName;

		loadoutPrimaryAttachment2 = "none";
		loadoutPrimaryAttachment3 = "none";
		loadoutSecondaryAttachment2 = "none";

		loadoutPrimary = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 0, "weapon" );
		if ( loadoutPrimary == "none" )
		{
			loadoutPrimary = "iw6_knifeonly";
			loadoutPrimaryAttachment = "none";
			loadoutPrimaryAttachment2 = "none";
			loadoutPrimaryAttachment3 = "none";
		}
		else
		{
			loadoutPrimaryAttachment = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 0, "attachment", 0 );
			loadoutPrimaryAttachment2 = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 0, "attachment", 1 );
			loadoutPrimaryAttachment3 = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 0, "attachment", 2 );
		}
		loadoutPrimaryBuff = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 0, "buff" );
		loadoutPrimaryCamo = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 0, "camo" );
		loadoutPrimaryReticle = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 0, "reticle" );

		loadoutSecondary = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 1, "weapon" );
		loadoutSecondaryAttachment = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 1, "attachment", 0 );
		loadoutSecondaryAttachment2 = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 1, "attachment", 1 );
		loadoutSecondaryBuff = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 1, "buff" );
		loadoutSecondaryCamo = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 1, "camo" );
		loadoutSecondaryReticle = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "weaponSetups", 1, "reticle" );
		
		//	replace the placeholder throwing knife or a none with the valid secondary if there is one
		if ( ( ( loadoutPrimary == "throwingknife" ) || ( loadoutPrimary == "none" ) ) && loadoutSecondary != "none" )
		{
			loadoutPrimary = loadoutSecondary;
			loadoutPrimaryAttachment = loadoutSecondaryAttachment;
			loadoutPrimaryAttachment2 = loadoutSecondaryAttachment2;
			loadoutPrimaryBuff = loadoutSecondaryBuff;
			loadoutPrimaryCamo = loadoutSecondaryCamo;
			loadoutPrimaryReticle = loadoutSecondaryReticle;	
			
			loadoutSecondary = "none";
			loadoutSecondaryAttachment = "none";
			loadoutSecondaryAttachment2 = "none";
			loadoutSecondaryBuff = "specialty_null";
			loadoutSecondaryCamo = "none";
			loadoutSecondaryReticle = "none";				
		}
		//	otherwise replace the placeholder throwing knife or a none with an unloaded basic pistol and tac knife
		else if ( ( ( loadoutPrimary == "throwingknife" ) || ( loadoutPrimary == "none" ) ) && loadoutSecondary == "none" )
		{
			clearAmmo = true;
			loadoutPrimary = "iw6_p226";
			loadoutPrimaryAttachment = "tactical";
		}

		loadoutEquipment = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "perks", 0 );
		
		loadoutStreakType = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "perks", 5 );
		if ( loadoutStreakType == "specialty_null" )
		{
			loadoutKillstreak1 = "none";
			loadoutKillstreak2 = "none";
			loadoutKillstreak3 = "none";			
		}
		else
		{
			loadoutKillstreak1 = recipe_getKillstreak( teamName, classIndex, loadoutStreakType, 0 );
			loadoutKillstreak2 = recipe_getKillstreak( teamName, classIndex, loadoutStreakType, 1 );
			loadoutKillstreak3 = recipe_getKillstreak( teamName, classIndex, loadoutStreakType, 2 );
		}
		loadoutOffhand = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "perks", 1 );	
		//	hack, until game mode default class data can be reset
		if ( loadoutOffhand == "specialty_null" )
			loadoutOffhand = "none";	
		//	if juggernaut is enabled on this class, then apply the juggernaut elements
		if ( getMatchRulesData( "defaultClasses", teamName, classIndex, "juggernaut" ) )
		{
			self thread recipeClassApplyJuggernaut( self isJuggernaut() );
			self.isJuggernaut = true;	// needed this frame for playerModelForWeapon() called at the end of this function
			self.juggMoveSpeedScaler = 0.7;	// for unset juiced
		}
		else if ( self isJuggernaut() ) 
		{
			self notify( "lost_juggernaut" );
			self.isJuggernaut = false;	// needed this frame for playerModelForWeapon() called at the end of this function
			self.moveSpeedScaler = 1;
		}
	}
	else if ( isSubstr( class, "custom" ) )
	{
		class_num = getClassIndex( class );
		self.class_num = class_num;

		loadoutPrimary = cac_getWeapon( class_num, 0 );
		loadoutPrimaryAttachment = cac_getWeaponAttachment( class_num, 0 );
		loadoutPrimaryAttachment2 = cac_getWeaponAttachmentTwo( class_num, 0 );
		loadoutPrimaryAttachment3 = cac_getWeaponAttachmentThree( class_num, 0 );
		loadoutPrimaryBuff = cac_getWeaponBuff( class_num, 0 );
		loadoutPrimaryCamo = cac_getWeaponCamo( class_num, 0 );
		loadoutPrimaryReticle = cac_getWeaponReticle( class_num, 0 );
		loadoutSecondary = cac_getWeapon( class_num, 1 );
		loadoutSecondaryAttachment = cac_getWeaponAttachment( class_num, 1 );
		loadoutSecondaryAttachment2 = cac_getWeaponAttachmentTwo( class_num, 1 );
		loadoutSecondaryBuff = cac_getWeaponBuff( class_num, 1 );
		loadoutSecondaryCamo = cac_getWeaponCamo( class_num, 1 );
		loadoutSecondaryReticle = cac_getWeaponReticle( class_num, 1 );
		loadoutEquipment = cac_getPrimaryGrenade( class_num );
		loadoutOffhand = cac_getSecondaryGrenade( class_num );
		loadoutStreakType = cac_getPerk( class_num, 5 );

		self.character_type = cac_getCharacterType( class_num );
	}
	else if ( class == "gamemode" )
	{
		class_num = getClassIndex( class );
		self.class_num = class_num;
		
		gamemodeLoadout = self.pers[ "gamemodeLoadout" ];

		loadoutPrimary				= ter_op( IsDefined( gamemodeLoadout[ "loadoutPrimary" ] ),					gamemodeLoadout[ "loadoutPrimary" ],				"none" );
		loadoutPrimaryAttachment	= ter_op( IsDefined( gamemodeLoadout[ "loadoutPrimaryAttachment" ] ),		gamemodeLoadout[ "loadoutPrimaryAttachment" ],		"none" );
		loadoutPrimaryAttachment2	= ter_op( IsDefined( gamemodeLoadout[ "loadoutPrimaryAttachment2" ] ),		gamemodeLoadout[ "loadoutPrimaryAttachment2" ],		"none" );
		loadoutPrimaryAttachment3	= ter_op( IsDefined( gamemodeLoadout[ "loadoutPrimaryAttachment3" ] ),		gamemodeLoadout[ "loadoutPrimaryAttachment3" ], 	"none" );
		loadoutPrimaryBuff			= ter_op( IsDefined( gamemodeLoadout[ "loadoutPrimaryBuff" ] ),				gamemodeLoadout[ "loadoutPrimaryBuff" ],			"specialty_null" );
		loadoutPrimaryCamo			= ter_op( IsDefined( gamemodeLoadout[ "loadoutPrimaryCamo" ] ),				gamemodeLoadout[ "loadoutPrimaryCamo" ],			"none" );
		loadoutPrimaryReticle		= ter_op( IsDefined( gamemodeLoadout[ "loadoutPrimaryReticle" ] ),			gamemodeLoadout[ "loadoutPrimaryReticle" ],			"none" );
		loadoutSecondary			= ter_op( IsDefined( gamemodeLoadout[ "loadoutSecondary" ] ),				gamemodeLoadout[ "loadoutSecondary" ],				"none" );
		loadoutSecondaryAttachment	= ter_op( IsDefined( gamemodeLoadout[ "loadoutSecondaryAttachment" ] ),		gamemodeLoadout[ "loadoutSecondaryAttachment" ],	"none" );
		loadoutSecondaryAttachment2 = ter_op( IsDefined( gamemodeLoadout[ "loadoutSecondaryAttachment2" ] ),	gamemodeLoadout[ "loadoutSecondaryAttachment2" ], 	"none" );
		loadoutSecondaryBuff		= ter_op( IsDefined( gamemodeLoadout[ "loadoutSecondaryBuff" ] ), 			gamemodeLoadout[ "loadoutSecondaryBuff" ],			"specialty_null" );
		loadoutSecondaryCamo		= ter_op( IsDefined( gamemodeLoadout[ "loadoutSecondaryCamo" ] ), 			gamemodeLoadout[ "loadoutSecondaryCamo" ],			"none" );
		loadoutSecondaryReticle		= ter_op( IsDefined( gamemodeLoadout[ "loadoutSecondaryReticle" ] ), 		gamemodeLoadout[ "loadoutSecondaryReticle" ],		"none" );
		loadoutPerksOverride		= ter_op( IsDefined( gamemodeLoadout[ "loadoutPerks" ] ), 					gamemodeLoadout[ "loadoutPerks" ],					[] );
		
		//	replace the placeholder throwing knife with the valid secondary if there is one
		if ( ( ( loadoutPrimary == "throwingknife" ) || ( loadoutPrimary == "none" ) ) && loadoutSecondary != "none" )
		{
			loadoutPrimary = loadoutSecondary;
			loadoutPrimaryAttachment = loadoutSecondaryAttachment;
			loadoutPrimaryAttachment2 = loadoutSecondaryAttachment2;
			loadoutPrimaryBuff = loadoutSecondaryBuff;
			loadoutPrimaryCamo = loadoutSecondaryCamo;
			loadoutPrimaryReticle = loadoutSecondaryReticle;	
			
			loadoutSecondary = "none";
			loadoutSecondaryAttachment = "none";
			loadoutSecondaryAttachment2 = "none";
			loadoutSecondaryBuff = "specialty_null";
			loadoutSecondaryCamo = "none";
			loadoutSecondaryReticle = "none";				
		}
		//	otherwise replace the placeholder throwing knife with an unloaded basic pistol and tac knife 
		else if ( ( ( loadoutPrimary == "throwingknife" ) || ( loadoutPrimary == "none" ) ) && loadoutSecondary == "none" )
		{
			clearAmmo = true;
			loadoutPrimary = "iw6_p226";
			loadoutPrimaryAttachment = "tactical";
		}	
		
		loadoutEquipment = gamemodeLoadout["loadoutEquipment"];
		loadoutOffhand = gamemodeLoadout["loadoutOffhand"];
		//	hack, until game mode default class data can be reset
		if ( loadoutOffhand == "specialty_null" )
			loadoutOffhand = "none";	

		if ( level.killstreakRewards && isDefined( gamemodeLoadout["loadoutStreakType"] ) && gamemodeLoadout["loadoutStreakType"] != "specialty_null" )
		{
			loadoutStreakType = gamemodeLoadout["loadoutStreakType"];
			loadoutKillstreak1 = gamemodeLoadout["loadoutKillstreak1"];
			loadoutKillstreak2 = gamemodeLoadout["loadoutKillstreak2"];
			loadoutKillstreak3 = gamemodeLoadout["loadoutKillstreak3"];			
		}
		else if ( level.killstreakRewards && isDefined( self.streakType ) )
			loadoutStreakType = getLoadoutStreakTypeFromStreakType( self.streakType );
		else 
		{
			loadoutStreakType = "streaktype_assault";
			loadoutKillstreak1 = "none";
			loadoutKillstreak2 = "none";
			loadoutKillstreak3 = "none";			
		}
		
		//	if juggernaut is enabled on this class, then apply the juggernaut elements
		if ( gamemodeLoadout["loadoutJuggernaut"] )
		{
			// give 100% health to fix some issues
			//	first was if you are being damaged and pick up juggernaut then you could die very quickly as juggernaut, seems weird in practice
			self.health = self.maxHealth;
			self thread recipeClassApplyJuggernaut( self isJuggernaut() );
			self.isJuggernaut = true;	// needed this frame for playerModelForWeapon() called at the end of this function
			self.juggMoveSpeedScaler = 0.7;	// for unset juiced
		}
		else if ( self isJuggernaut() )
		{
			self notify( "lost_juggernaut" );
			self.isJuggernaut = false;	// needed this frame for playerModelForWeapon() called at the end of this function
			self.moveSpeedScaler = 1;
		} 
	}
	else if( class == "juggernaut" )
	{
		loadoutPrimary				= "iw6_minigunjugg";
		loadoutPrimaryAttachment	= "none";
		loadoutPrimaryAttachment2	= "none";
		loadoutPrimaryAttachment3	= "none";
		loadoutPrimaryBuff			= "specialty_null";
		loadoutPrimaryCamo			= "none";
		loadoutPrimaryReticle		= "none";
		loadoutSecondary			= "iw6_p226jugg";
		loadoutSecondaryAttachment	= "none";
		loadoutSecondaryAttachment2 = "none";
		loadoutSecondaryBuff		= "specialty_null";
		loadoutSecondaryCamo		= "none";
		loadoutSecondaryReticle		= "none";
		loadoutEquipment			= "mortar_shelljugg_mp";
		loadoutStreakType			= getLoadoutStreakTypeFromStreakType( self.streakType );
		loadoutOffhand				= "none";
	}
	else if( class == "juggernaut_recon" )
	{
		loadoutPrimary				= "iw6_riotshieldjugg";
		loadoutPrimaryAttachment	= "none";
		loadoutPrimaryAttachment2	= "none";
		loadoutPrimaryAttachment3	= "none";
		loadoutPrimaryBuff			= "specialty_null";
		loadoutPrimaryCamo			= "none";
		loadoutPrimaryReticle		= "none";
		loadoutSecondary			= "iw6_magnumjugg";
		loadoutSecondaryAttachment	= "none";
		loadoutSecondaryAttachment2 = "none";
		loadoutSecondaryBuff		= "specialty_null";
		loadoutSecondaryCamo		= "none";
		loadoutSecondaryReticle		= "none";
		loadoutEquipment			= "specialty_null";
		loadoutStreakType			= getLoadoutStreakTypeFromStreakType( self.streakType );
		loadoutOffhand				= "smoke_grenadejugg_mp";
	}
	else if( class == "juggernaut_maniac" )
	{
		loadoutPrimary				= "iw6_knifeonlyjugg";
		loadoutPrimaryAttachment	= "none";
		loadoutPrimaryAttachment2	= "none";
		loadoutPrimaryAttachment3	= "none";
		loadoutPrimaryBuff			= "specialty_null";
		loadoutPrimaryCamo			= "none";
		loadoutPrimaryReticle		= "none";
		loadoutSecondary			= "none";
		loadoutSecondaryAttachment	= "none";
		loadoutSecondaryAttachment2 = "none";
		loadoutSecondaryBuff		= "specialty_null";
		loadoutSecondaryCamo		= "none";
		loadoutSecondaryReticle		= "none";
		loadoutEquipment			= "throwingknifejugg_mp";
		loadoutStreakType			= getLoadoutStreakTypeFromStreakType( self.streakType );
		loadoutOffhand				= "none";
	}
	else if ( isStrStart( class, "juggernaut_" ) )
	// else if( class == "juggernaut_swamp_slasher" ) // level killstreak for mp_swamp dlc
	{
		AssertEx( IsDefined( level.mapCustomJuggSetclass ), "Must have level.mapCustomJuggSetClass defined to give loadout to " + class + "!\n" );
		
		callbackLoadout = [[ level.mapCustomJuggSetclass ]]( class );
		
		loadoutPrimary				= ter_op( IsDefined( callbackLoadout[ "loadoutPrimary" ] ), 				callbackLoadout[ "loadoutPrimary" ], 					"none" );
		loadoutPrimaryAttachment	= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryAttachment" ] ), 		callbackLoadout[ "loadoutPrimaryAttachment" ], 			"none" );
		loadoutPrimaryAttachment2	= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryAttachment2" ] ), 		callbackLoadout[ "loadoutPrimaryAttachment2" ], 		"none" );
		loadoutPrimaryAttachment3	= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryAttachment3" ] ), 		callbackLoadout[ "loadoutPrimaryAttachment3" ], 		"none" );
		loadoutPrimaryBuff			= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryBuff" ] ), 			callbackLoadout[ "loadoutPrimaryBuff" ], 				"specialty_null" );
		loadoutPrimaryCamo			= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryCamo" ] ), 			callbackLoadout[ "loadoutPrimaryCamo" ], 				"none" );
		loadoutPrimaryReticle		= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryReticle" ] ), 			callbackLoadout[ "loadoutPrimaryReticle" ], 			"none" );
		loadoutSecondary			= ter_op( IsDefined( callbackLoadout[ "loadoutSecondary" ] ), 				callbackLoadout[ "loadoutSecondary" ], 					"none" );
		loadoutSecondaryAttachment	= ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryAttachment" ] ), 	callbackLoadout[ "loadoutSecondaryAttachment" ], 		"none" );
		loadoutSecondaryAttachment2 = ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryAttachment2" ] ), 	callbackLoadout[ "loadoutSecondaryAttachment2" ], 		"none" );
		loadoutSecondaryBuff		= ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryBuff" ] ), 			callbackLoadout[ "loadoutSecondaryBuff" ], 				"specialty_null" );
		loadoutSecondaryCamo		= ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryCamo" ] ), 			callbackLoadout[ "loadoutSecondaryCamo" ], 				"none" );
		loadoutSecondaryReticle		= ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryReticle" ] ), 		callbackLoadout[ "loadoutSecondaryReticle" ], 			"none" );
		loadoutEquipment			= ter_op( IsDefined( callbackLoadout[ "loadoutEquipment" ] ), 				callbackLoadout[ "loadoutEquipment" ], 					"none" );
		loadoutOffhand				= ter_op( IsDefined( callbackLoadout[ "loadoutOffhand" ] ), 				callbackLoadout[ "loadoutOffhand" ], 					"none" );
		
		loadoutStreakType			= getLoadoutStreakTypeFromStreakType( self.streakType );
	}
	else if( class == "reconAgent" )
	{
		loadoutPrimary				= "iw6_riotshield";
		loadoutPrimaryAttachment	= "none";
		loadoutPrimaryAttachment2	= "none";
		loadoutPrimaryAttachment3	= "none";
		loadoutPrimaryBuff			= "specialty_null";
		loadoutPrimaryCamo			= "none";
		loadoutPrimaryReticle		= "none";
		loadoutSecondary			= "iw6_mp443";
		loadoutSecondaryAttachment	= "none";
		loadoutSecondaryAttachment2 = "none";
		loadoutSecondaryBuff		= "specialty_null";
		loadoutSecondaryCamo		= "none";
		loadoutSecondaryReticle		= "none";
		loadoutEquipment			= "specialty_null";
		loadoutStreakType			= "streaktype_assault";
		loadoutOffhand				= "none";
		loadoutKillstreak1 			= "none";
		loadoutKillstreak2 			= "none";
		loadoutKillstreak3 			= "none";			
	}
	else if ( class == "callback" )
	{
		if ( !isDefined( self.classCallback ) )
			error( "self.classCallback function reference required for class 'callback'" );

		callbackLoadout = [[ self.classCallback ]]();
		if ( !IsDefined( callbackLoadout ) )
			error( "array required from self.classCallback for class 'callback'" );
		
		loadoutPrimary				= ter_op( IsDefined( callbackLoadout[ "loadoutPrimary" ] ), 				callbackLoadout[ "loadoutPrimary" ], 					"none" );
		loadoutPrimaryAttachment	= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryAttachment" ] ), 		callbackLoadout[ "loadoutPrimaryAttachment" ], 			"none" );
		loadoutPrimaryAttachment2	= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryAttachment2" ] ), 		callbackLoadout[ "loadoutPrimaryAttachment2" ], 		"none" );
		loadoutPrimaryAttachment3	= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryAttachment3" ] ), 		callbackLoadout[ "loadoutPrimaryAttachment3" ], 		"none" );
		loadoutPrimaryBuff			= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryBuff" ] ), 			callbackLoadout[ "loadoutPrimaryBuff" ], 				"specialty_null" );
		loadoutPrimaryCamo			= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryCamo" ] ), 			callbackLoadout[ "loadoutPrimaryCamo" ], 				"none" );
		loadoutPrimaryReticle		= ter_op( IsDefined( callbackLoadout[ "loadoutPrimaryReticle" ] ), 			callbackLoadout[ "loadoutPrimaryReticle" ], 			"none" );
		loadoutSecondary			= ter_op( IsDefined( callbackLoadout[ "loadoutSecondary" ] ), 				callbackLoadout[ "loadoutSecondary" ], 					"none" );
		loadoutSecondaryAttachment	= ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryAttachment" ] ), 	callbackLoadout[ "loadoutSecondaryAttachment" ], 		"none" );
		loadoutSecondaryAttachment2 = ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryAttachment2" ] ), 	callbackLoadout[ "loadoutSecondaryAttachment2" ], 		"none" );
		loadoutSecondaryBuff		= ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryBuff" ] ), 			callbackLoadout[ "loadoutSecondaryBuff" ], 				"specialty_null" );
		loadoutSecondaryCamo		= ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryCamo" ] ), 			callbackLoadout[ "loadoutSecondaryCamo" ], 				"none" );
		loadoutSecondaryReticle		= ter_op( IsDefined( callbackLoadout[ "loadoutSecondaryReticle" ] ), 		callbackLoadout[ "loadoutSecondaryReticle" ], 			"none" );
		loadoutEquipment			= ter_op( IsDefined( callbackLoadout[ "loadoutEquipment" ] ), 				callbackLoadout[ "loadoutEquipment" ], 					"none" );
		loadoutOffhand				= ter_op( IsDefined( callbackLoadout[ "loadoutOffhand" ] ), 				callbackLoadout[ "loadoutOffhand" ], 					"none" );
		loadoutStreakType			= ter_op( IsDefined( callbackLoadout[ "loadoutStreakType" ] ), 				callbackLoadout[ "loadoutStreakType" ], 				"none" );
		loadoutKillstreak1			= ter_op( IsDefined( callbackLoadout[ "loadoutStreak1" ] ), 				callbackLoadout[ "loadoutStreak1" ], 					"none" );
		loadoutKillstreak2			= ter_op( IsDefined( callbackLoadout[ "loadoutStreak2" ] ), 				callbackLoadout[ "loadoutStreak2" ], 					"none" );
		loadoutKillstreak3			= ter_op( IsDefined( callbackLoadout[ "loadoutStreak3" ] ), 				callbackLoadout[ "loadoutStreak3" ], 					"none" );
		
		self.character_type 		= callbackLoadout["loadoutCharacterType"];
	}
	else // default classes
	{
		class_num = getClassIndex( class );
		self.class_num = class_num;
		
		loadoutPrimary = table_getWeapon( level.classTableName, class_num, 0 );
		loadoutPrimaryAttachment = table_getWeaponAttachment( level.classTableName, class_num, 0 , 0);
		loadoutPrimaryAttachment2 = table_getWeaponAttachment( level.classTableName, class_num, 0, 1 );
		loadoutPrimaryAttachment3 = table_getWeaponAttachment( level.classTableName, class_num, 0, 2 );
		loadoutPrimaryBuff = table_getWeaponBuff( level.classTableName, class_num, 0 );
		loadoutPrimaryCamo = table_getWeaponCamo( level.classTableName, class_num, 0 );
		loadoutPrimaryReticle = table_getWeaponReticle( level.classTableName, class_num, 0 );
		loadoutSecondary = table_getWeapon( level.classTableName, class_num, 1 );
		loadoutSecondaryAttachment = table_getWeaponAttachment( level.classTableName, class_num, 1 , 0);
		loadoutSecondaryAttachment2 = table_getWeaponAttachment( level.classTableName, class_num, 1, 1 );;
		loadoutSecondaryBuff = table_getWeaponBuff( level.classTableName, class_num, 1 );
		loadoutSecondaryCamo = table_getWeaponCamo( level.classTableName, class_num, 1 );
		loadoutSecondaryReticle = table_getWeaponReticle( level.classTableName, class_num, 1 );
		loadoutEquipment = table_getEquipment( level.classTableName, class_num, 0 );
		loadoutStreakType = "specialty_null"; //table_getPerk( level.classTableName, class_num, 5 );
		loadoutOffhand = "specialty_null"; //table_getOffhand( level.classTableName, class_num );
		
		self.character_type = table_getCharacterType( level.classTableName, class_num );
	}

	// HACK for Gold Knife. This uses uav as the weapon enum entry in playerdata. - JoeC
	loadoutPrimary = ter_op( loadoutPrimary == "uav", "iw6_knifeonlyfast", loadoutPrimary );
	loadoutSecondary = ter_op( loadoutSecondary == "uav", "iw6_knifeonlyfast", loadoutSecondary );
	
	// HACK for Gold PDW. This uses laser_designator as teh weapon enum entry in playerdata. - JoeC
	loadoutSecondary = ter_op( loadoutSecondary == "laser_designator", "iw6_pdwauto", loadoutSecondary );
	
	self loadoutFakePerks( loadoutStreakType );

	isCustomClass = isSubstr( class, "custom" );
	isRecipeClass = isSubstr( class, "recipe" );
	isGameModeClass = ( class == "gamemode" );
	isCallbackClass = ( class == "callback" );
	
	if ( !isGameModeClass && !isRecipeClass && !isCallbackClass )
	{
		if ( !isValidPrimary( loadoutPrimary ) || ( level.rankedMatch && isCustomClass && !self isItemUnlocked( loadoutPrimary )) )
			loadoutPrimary = table_getWeapon( level.classTableName, 10, 0 );
		
		if ( !isValidAttachment( loadoutPrimaryAttachment, loadoutPrimary ) || (  level.rankedMatch && isCustomClass && !self isAttachmentUnlocked( loadoutPrimary, loadoutPrimaryAttachment ) ) )
			loadoutPrimaryAttachment = table_getWeaponAttachment( level.classTableName, 10, 0 , 0);
		
		if ( !isValidAttachment( loadoutPrimaryAttachment2, loadoutPrimary ) || (  level.rankedMatch && isCustomClass && !self isAttachmentUnlocked( loadoutPrimary, loadoutPrimaryAttachment2 ) ) )
			loadoutPrimaryAttachment2 = table_getWeaponAttachment( level.classTableName, 10, 0, 1 );
		
		if ( !isValidAttachment( loadoutPrimaryAttachment3, loadoutPrimary ) || (  level.rankedMatch && isCustomClass && !self isAttachmentUnlocked( loadoutPrimary, loadoutPrimaryAttachment3 ) ) )
			loadoutPrimaryAttachment3 = table_getWeaponAttachment( level.classTableName, 10, 0, 2 );
		
		if ( !isValidWeaponBuff( loadoutPrimaryBuff, loadoutPrimary ) || ( level.rankedMatch && isCustomClass && !self isWeaponBuffUnlocked( loadoutPrimary, loadoutPrimaryBuff )) )
			loadoutPrimaryBuff = table_getWeaponBuff( level.classTableName, 10, 0 );

		if ( !isValidCamo( loadoutPrimaryCamo ) || (  level.rankedMatch && isCustomClass && !self isCamoUnlocked( loadoutPrimary, loadoutPrimaryCamo )) )
			loadoutPrimaryCamo = table_getWeaponCamo( level.classTableName, 10, 0 );

		if ( !isValidReticle( loadoutPrimaryReticle ) )
			loadoutPrimaryReticle = table_getWeaponReticle( level.classTableNum, 10, 0 );
		
		if ( !isValidAttachment( loadoutSecondaryAttachment, loadoutSecondary ) || (  level.rankedMatch && isCustomClass && !self isAttachmentUnlocked( loadoutSecondary, loadoutSecondaryAttachment )) )
			loadoutSecondaryAttachment = table_getWeaponAttachment( level.classTableName, 10, 1 , 0);
		
		if ( !isValidAttachment( loadoutSecondaryAttachment2, loadoutSecondary ) || (  level.rankedMatch && isCustomClass && !self isAttachmentUnlocked( loadoutSecondary, loadoutSecondaryAttachment2 )) )
			loadoutSecondaryAttachment2 = table_getWeaponAttachment( level.classTableName, 10, 1, 1 );;
		
		if ( !isValidWeaponBuff( loadoutSecondaryBuff, loadoutSecondary ) || ( level.rankedMatch && isCustomClass && !self isItemUnlocked( loadoutSecondary + " " + loadoutSecondaryBuff )) )
			loadoutSecondaryBuff = table_getWeaponBuff( level.classTableName, 10, 1 );

		if ( !isValidCamo( loadoutSecondaryCamo ) || ( level.rankedMatch && isCustomClass && !self isCamoUnlocked( loadoutSecondary, loadoutSecondaryCamo )) )
			loadoutSecondaryCamo = table_getWeaponCamo( level.classTableName, 10, 1 );

		if ( !isValidReticle( loadoutSecondaryReticle ) )
			loadoutSecondaryReticle = table_getWeaponReticle( level.classTableName, 10, 1 );
		
		if ( !isValidEquipment( loadoutEquipment ) || ( level.rankedMatch && isCustomClass && !self isItemUnlocked( loadoutEquipment )) )
			loadoutEquipment = table_getEquipment( level.classTableName, 10, 0 );
		
		if ( !isValidOffhand( loadoutOffhand ) )
			loadoutOffhand = table_getOffhand( level.classTableName, 10 );
	}

	// -.-.-.-.-.-.-.-.-.-.-.-.- //
	// Perks
	// -.-.-.-.-.-.-.-.-.-.-.-.- //
	self _clearPerks();
	self _detachAll();
	
	// these special case giving pistol death have to come before
	// perk loadout to ensure player perk icons arent overwritten
	if ( level.dieHardMode )
		self givePerk( "specialty_pistoldeath", false );
	
	if ( !is_aliens() )
	{
		// Equipment does not need to be validated if coming from a game mode
		// because these values are hard coded in script. Allows non loadout
		// equipment to get through such as tactical insertion
		self loadoutAllAbilities( loadoutEquipment, loadoutOffhand, loadoutPerksOverride, class != "gamemode", class, teamName );
	}

	// trying to stop killstreaks from targeting the newly spawned
	// also stopping radar pings from revealing the newly spawned
	self.spawnPerk = false;
	if( !self isJuggernaut() && IsDefined( self.avoidKillstreakOnSpawnTimer ) && self.avoidKillstreakOnSpawnTimer > 0 )
		self thread maps\mp\perks\_perks::givePerksAfterSpawn();
	
	// -.-.-.-.-.-.-.-.-.-.-.-.- //
	// Store load out on player
	// -.-.-.-.-.-.-.-.-.-.-.-.- //
	
	blockPrimaryAsSecondary = !perksEnabled() || !_hasPerk( "specialty_twoprimaries" );
	if ( loadoutSecondary != "none" && !isValidSecondary( loadoutSecondary, false, blockPrimaryAsSecondary ) )
	{
		loadoutSecondary = "none";
		loadoutSecondaryAttachment = "none";
		loadoutSecondaryAttachment2 = "none";
		loadoutSecondaryBuff = "specialty_null";
		loadoutSecondaryCamo = "none";
		loadoutSecondaryReticle = "none";
	}
	
	//loadoutSecondaryCamo = "none";

	self.loadoutPrimary = loadoutPrimary;
	if ( IsDefined( loadoutPrimaryCamo ) )
	{
		self.loadoutPrimaryCamo = int(TableLookup( "mp/camoTable.csv", 1, loadoutPrimaryCamo, 4 ));
	}
	
	self.loadoutSecondary = loadoutSecondary;
	if ( IsDefined( loadoutSecondaryCamo ) )
	{
		self.loadoutSecondaryCamo = int(TableLookup( "mp/camoTable.csv", 1, loadoutSecondaryCamo, 4 ));
	}
	
	self.loadoutPrimaryAttachments = [];
	if ( IsDefined( loadoutPrimaryAttachment ) && loadoutPrimaryAttachment != "none" )
		self.loadoutPrimaryAttachments[ self.loadoutPrimaryAttachments.size ] = loadoutPrimaryAttachment;
	if ( IsDefined( loadoutPrimaryAttachment2 ) && loadoutPrimaryAttachment2 != "none" )
		self.loadoutPrimaryAttachments[ self.loadoutPrimaryAttachments.size ] = loadoutPrimaryAttachment2;
	if ( IsDefined( loadoutPrimaryAttachment3 ) && loadoutPrimaryAttachment3 != "none" )
		self.loadoutPrimaryAttachments[ self.loadoutPrimaryAttachments.size ] = loadoutPrimaryAttachment3;
	
	self.loadoutSecondaryAttachments = [];
	if ( IsDefined( loadoutSecondaryAttachment ) && loadoutSecondaryAttachment != "none" )
		self.loadoutSecondaryAttachments[ self.loadoutSecondaryAttachments.size ] = loadoutSecondaryAttachment;
	if ( IsDefined( loadoutSecondaryAttachment2 ) && loadoutSecondaryAttachment2 != "none" )
		self.loadoutSecondaryAttachments[ self.loadoutSecondaryAttachments.size ] = loadoutSecondaryAttachment2;
	
	if ( !IsSubstr( loadoutPrimary, "iw5" ) && !IsSubstr( loadoutPrimary, "iw6" ) )
		self.loadoutPrimaryCamo = 0;
	if ( !IsSubstr( loadoutSecondary, "iw5" ) && !IsSubstr( loadoutSecondary, "iw6" ) )
		self.loadoutSecondaryCamo = 0;

	self.loadoutPrimaryReticle	 = Int( TableLookup( "mp/reticleTable.csv", 1, loadoutPrimaryReticle, 5 ) );
	self.loadoutSecondaryReticle = Int( TableLookup( "mp/reticleTable.csv", 1, loadoutSecondaryReticle, 5 ) );
	
	if ( !IsSubstr( loadoutPrimary, "iw5" ) && !IsSubstr( loadoutPrimary, "iw6" ) )
		self.loadoutPrimaryReticle = 0;
	if ( !IsSubstr( loadoutSecondary, "iw5" ) && !IsSubstr( loadoutSecondary, "iw6" ) )
		self.loadoutSecondaryReticle = 0;

	// -.-.-.-.-.-.-.-.-.-.-.-.- //
	// Action Slots
	// -.-.-.-.-.-.-.-.-.-.-.-.- //
	self _setActionSlot( 1, "" ); // dpad up
	self _setActionSlot( 2, "" ); // dpad down
	self _setActionSlot( 3, "altMode" ); // dpad left
	self _setActionSlot( 4, "" ); // dpad right
	// pc has extra action slots
	if( !level.console )
	{
		self _setActionSlot( 5, "" );
		self _setActionSlot( 6, "" );
		self _setActionSlot( 7, "" );
	}
	
	// -.-.-.-.-.-.-.-.-.-.-.-.- //
	// killstreaks need to be given after perks because of things like hardline
	// -.-.-.-.-.-.-.-.-.-.-.-.- //
	if ( level.killstreakRewards && !isDefined( loadoutKillstreak1 ) && !isDefined( loadoutKillstreak2 ) && !isDefined( loadoutKillstreak3 ) )
	{
		defaultKillstreak1 = undefined;
		defaultKillstreak2 = undefined;
		defaultKillstreak3 = undefined;
		playerData = undefined;

		// IW5 Defcon Killstreak loadout
		switch( self.streakType )
		{
		case "support":
			defaultKillstreak1 = table_getKillstreak( level.classTableName, 2, 0 );
			defaultKillstreak2 = table_getKillstreak( level.classTableName, 2, 1 );
			defaultKillstreak3 = table_getKillstreak( level.classTableName, 2, 2 );
			playerData = "supportStreaks";
			break;
		case "specialist":
			defaultKillstreak1 = table_getKillstreak( level.classTableName, 1, 0 );
			defaultKillstreak2 = table_getKillstreak( level.classTableName, 1, 1 );
			defaultKillstreak3 = table_getKillstreak( level.classTableName, 1, 2 );
			playerData = "specialistStreaks";
			break;
		default: // assault
			defaultKillstreak1 = table_getKillstreak( level.classTableName, 0, 0 );
			defaultKillstreak2 = table_getKillstreak( level.classTableName, 0, 1 );
			defaultKillstreak3 = table_getKillstreak( level.classTableName, 0, 2 );
			playerData = "assaultStreaks";
			break;
		}

		loadoutKillstreak1 = undefined;
		loadoutKillstreak2 = undefined;
		loadoutKillstreak3 = undefined;

		// this is a custom class so pull from the player data
		if( IsSubStr( class, "custom" ) )
		{
			assert( IsDefined( self.class_num ) );
			loadoutKillstreak1 = self getCaCPlayerData( "loadouts", self.class_num, playerData, 0 );
			loadoutKillstreak2 = self getCaCPlayerData( "loadouts", self.class_num, playerData, 1 );
			loadoutKillstreak3 = self getCaCPlayerData( "loadouts", self.class_num, playerData, 2 );
		}

		// give juggernauts and special gamemode classes the current killstreaks the player has
		if( IsSubStr( class, "juggernaut" ) || isGameModeClass )
		{
			foreach( killstreak in self.killstreaks )
			{
				if( !IsDefined( loadoutKillstreak1 ) )
					loadoutKillstreak1 = killstreak;
				else if( !IsDefined( loadoutKillstreak2 ) )
					loadoutKillstreak2 = killstreak;
				else if( !IsDefined( loadoutKillstreak3 ) )
					loadoutKillstreak3 = killstreak;
			}
			if ( isGameModeClass && self.streakType == "specialist" )
			{
				//	store these for getStreakCost()
				self.pers["gamemodeLoadout"]["loadoutKillstreak1"] = loadoutKillstreak1;
				self.pers["gamemodeLoadout"]["loadoutKillstreak2"] = loadoutKillstreak2;
				self.pers["gamemodeLoadout"]["loadoutKillstreak3"] = loadoutKillstreak3;
			}
		}

		// give defaults if this isn't a custom class, or juggernauts, or special gamemode classes
		if( !isSubstr( class, "custom" ) && !isSubstr( class, "juggernaut" ) && !isGameModeClass )
		{
			loadoutKillstreak1 = defaultKillstreak1;
			loadoutKillstreak2 = defaultKillstreak2;
			loadoutKillstreak3 = defaultKillstreak3;
		}

		// if the killstreak variables are undefined by the time they get here then we should set them to "none" because they may not have selected a killstreak
		if( !IsDefined( loadoutKillstreak1 ) || (loadoutKillstreak1 == "") )
			loadoutKillstreak1 = "none";
		if( !IsDefined( loadoutKillstreak2 ) || (loadoutKillstreak2 == "") )
			loadoutKillstreak2 = "none";
		if( !IsDefined( loadoutKillstreak3 ) || (loadoutKillstreak3 == "") )
			loadoutKillstreak3 = "none";

		// validate to stop cheaters
		if( !isValidKillstreak( loadoutKillstreak1, self.streakType ) || ( isCustomClass && !self isItemUnlocked( loadoutKillstreak1 ) ) ||
			!isValidKillstreak( loadoutKillstreak2, self.streakType ) || ( isCustomClass && !self isItemUnlocked( loadoutKillstreak2 ) ) ||
			!isValidKillstreak( loadoutKillstreak3, self.streakType ) || ( isCustomClass && !self isItemUnlocked( loadoutKillstreak3 ) ) )
		{
			loadoutKillstreak1 = "none";
			loadoutKillstreak2 = "none";
			loadoutKillstreak3 = "none";
		}
	}
	else if ( !level.killstreakRewards )
	{
		loadoutKillstreak1 = "none";
		loadoutKillstreak2 = "none";
		loadoutKillstreak3 = "none";
	}

	self setKillstreaks( loadoutKillstreak1, loadoutKillstreak2, loadoutKillstreak3 );
	// reset the killstreaks when there is a new class chosen (or class is dynamic "callback"), unless it's juggernaut or special gamemode class, this fixes the bug where killstreaks don't reset if you change classes during pre-match timer
	if( !IsAgent(self) && 
		( self hasChangedClass() || self.class == "callback" ) && 
		!IsSubStr( self.class, "juggernaut" ) && 
		!IsSubStr( self.lastClass, "juggernaut" ) && 
		!IsSubStr( class, "juggernaut" ) )
	{
		if( wasOnlyRound() || self.lastClass != "" )
		{
			// put all of their killstreaks into the gimme slot now that it stacks
			streakNames = [];
			streakIDs = [];
			inc = 0;
			self_pers_killstreaks = self.pers["killstreaks"];
			
			// first go through the gimme slot killstreaks, this way they will be in the bottom of the pile
			if( self_pers_killstreaks.size > KILLSTREAK_STACKING_START_SLOT )
			{
				for( i = KILLSTREAK_STACKING_START_SLOT; i < self_pers_killstreaks.size; i++ )
				{
					streakNames[inc] = self_pers_killstreaks[i].streakName;
					streakIDs[inc] = self_pers_killstreaks[i].kID;
					inc++;
				}
			}
			// now go through the earned killstreaks, so these will be on the top of the pile
			if( self_pers_killstreaks.size )
			{
				for( i = KILLSTREAK_SLOT_1; i < KILLSTREAK_SLOT_3 + 1; i++ )
				{
					if( IsDefined( self_pers_killstreaks[i] ) && 
						IsDefined( self_pers_killstreaks[i].streakName ) &&
						self_pers_killstreaks[i].available && 
						!self_pers_killstreaks[i].isSpecialist )
					{
						streakNames[inc] = self_pers_killstreaks[i].streakName;
						streakIDs[inc] = self_pers_killstreaks[i].kID;
						inc++;
					}
				}
			}

			// this is a safety check in case they were in something like an ac130, switched classes, earned a killstreak and were killed while in the ac130
			//	since giveKillstreakWeapon() is a blocking function in giveKillstrak(), it gets stuck until you are done with the ac130, we've already set up the newly selected class before we get here
			//	this notify will end the stuck thread and keep it from changing the killstreakIndexWeapon after we have already changed it here
			self notify( "givingLoadout" );

			maps\mp\killstreaks\_killstreaks::clearKillstreaks();

			for( i = 0; i < streakNames.size; i++ )
			{
				// JC-09/19/13: Added streak ID param to allow killstreaks being shuffled into
				// the gimme slot to retain their unique ID. A future fix for this would be to
				// pass a killstreak struct reference instead of recreating each killstreak
				// buy just passing the name
				self maps\mp\killstreaks\_killstreaks::giveKillstreak( streakNames[ i ], undefined, undefined, undefined, undefined, streakIDs[ i ] );
			}
		}
	}
	
	// don't change these if we're becoming a juggernaut
	if( !IsSubStr( class, "juggernaut" ) )
	{
		if( self hasChangedClass() )
		{
			self incPlayerStat( "mostclasseschanged", 1 );
			self notify( "changed_class" );
		}

		self.pers["lastClass"] = self.class;
		self.lastClass = self.class;		
	}
	
	//	Loadouts can be forced on the player due to game mode context.  
	//	To ensure the player is in a clean state, their class is set to the 
	//	"gamemode" class and they are respawned in place to clear their state.  
	//	Their current class is saved in self.gamemode_chosenClass.
	//	The class and last class variables are reset back to what they had originally chosen so they're back to normal
	//	when they next die or when the game mode forces their originally chosen loadout back on them through context.
	if ( isDefined( self.gamemode_chosenClass ) )
	{
		self.pers["class"] = self.gamemode_chosenClass;
		self.pers["lastClass"] = self.gamemode_chosenClass;
		self.class = self.gamemode_chosenClass;
		self.lastClass = self.gamemode_chosenClass;
		self.gamemode_chosenClass = undefined;	
	}

	// Primary Weapon
	attachments = [ loadoutPrimaryAttachment, loadoutPrimaryAttachment2 ];
	if ( perksEnabled() && self _hasPerk( "specialty_extra_attachment" ) )
	{
		attachments[ attachments.size ] = loadoutPrimaryAttachment3;
	}
	
	// Verify that our weapon has a scope (it could have come in as part of an Extra Attachment, but that perk could be disabled)
	finalPrimaryHasScope = false;
	foreach( attachment in attachments )
	{
		if ( getAttachmentType( attachment ) == "rail" )
		{
			finalPrimaryHasScope = true;
			break;
		}
	}
	if ( !finalPrimaryHasScope )
		self.loadoutPrimaryReticle = 0;
	
	primaryName = buildWeaponName( loadoutPrimary, attachments, self.loadoutPrimaryCamo, self.loadoutPrimaryReticle );
	/#
		primaryName = GetDvar( "dbg_spawn_weap", primaryName );
	#/
	self _giveWeapon( primaryName );

	if ( !IsAI( self ) )
	{
		// Bots/Agents handle weapon switching internally
		self.saved_lastWeaponHack = undefined;
		self SwitchToWeapon( primaryName );
	}
	
	// do a quick check to make sure the weapon xp and rank jive with each other
	weaponName = getBaseWeaponName( primaryName );
	
	//No longer used for IW6 - JORDAN H
	/*
	if ( IsPlayer( self ) && !is_aliens() )
	{
		curWeaponRank = self maps\mp\gametypes\_rank::getWeaponRank( weaponName );
		curWeaponStatRank = self GetPlayerData( "weaponRank", weaponName );
		if( curWeaponRank != curWeaponStatRank )
			self SetPlayerData( "weaponRank", weaponName, curWeaponRank );
	}
	*/

	// fix changing from a riotshield class to a riotshield class during grace period not giving a shield
	if ( maps\mp\gametypes\_weapons::isRiotShield( primaryName ) && level.inGracePeriod )
		self notify ( "weapon_change", primaryName );
	
	//	only when called during spawn flow
	if ( setPrimarySpawnWeapon )
	{
		self SetSpawnWeapon( primaryName );
	}

	//	clear ammo for created default classes using placeholder gun when primary and secondary was set to none
	if ( clearAmmo )
	{
		self SetWeaponAmmoClip( self.primaryWeapon, 0 );
		self SetWeaponAmmoStock( self.primaryWeapon, 0 );
	}
	
	self maps\mp\gametypes\_weapons::updateToggleScopeState( primaryName );

	// Secondary Weapon

	if ( loadoutSecondary == "none" )
		secondaryName = "none";
	else
	{
		attachments = [ loadoutSecondaryAttachment ];
		if ( perksEnabled() && self _hasPerk( "specialty_extra_attachment" ) )
		{
			attachments[ attachments.size ] = loadoutSecondaryAttachment2;
		}
		secondaryName = buildWeaponName( loadoutSecondary, attachments, self.loadoutSecondaryCamo, self.loadoutSecondaryReticle );
		self _giveWeapon( secondaryName );

		// do a quick check to make sure the weapon xp and rank jive with each other
		weaponName = getBaseWeaponName( secondaryName );

		//no longer used for IW6 Jordan H
		/*
		if ( IsPlayer( self ) && !is_aliens()  )
		{
			curWeaponRank = self maps\mp\gametypes\_rank::getWeaponRank( weaponName );
			curWeaponStatRank = self GetPlayerData( "weaponRank", weaponName );
			if( curWeaponRank != curWeaponStatRank )
				self SetPlayerData( "weaponRank", weaponName, curWeaponRank );
		}
		*/
		
		maps\mp\gametypes\_weapons::updateToggleScopeState( secondaryName );
	}

	// store the whole weapon names for later use
	self.primaryWeapon = primaryName;
	self.secondaryWeapon = secondaryName;
	
	self.pers[ "primaryWeapon" ] = primaryName;
	self.pers[ "secondaryWeapon" ] = secondaryName;

	self maps\mp\gametypes\_teams::setupPlayerModel();

	self.isSniper = (weaponClass( self.primaryWeapon ) == "sniper");
	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();

	// cac specialties that require loop threads
	self maps\mp\perks\_perks::cac_selector();
	
	// Validation Exceptions:
		// Juggernauts get their perks later on after loadout so do not validate.
		// AI outside of squads does not properly obey perk points. For now only
		// validate squad ai that are not random
	shouldValidateAi = IsAI( self ) && IsSquadsMode() && !self bot_israndom();
	
	if	(
		    !self isJuggernaut()					// Juggernauts get perks later, do not validate pers perks
		&&	( !IsAI( self ) || shouldValidateAi )	// AI outside of squads do not obey perk point rules
		&&	!isGameModeClass						// Some game modes use deprecated perks. They are hardcoded so no need to validate.
		 )
	{
		perkPointBonus = 0;
		if ( loadoutEquipment == "specialty_null" )
			perkPointBonus += 1;
		// ES - 01/17/14 - In the case of default loadouts, loadoutOffhand is going to return "none".  Adding defensive fix for this issue.
		if ( loadoutOffhand == "specialty_null" || loadoutOffhand == "none" )
			perkPointBonus += 1;
		if ( loadoutPrimary == "iw6_knifeonly" || loadoutPrimary == "iw6_knifeonlyfast" )
			perkPointBonus += 1;
		if ( loadoutSecondary == "none" || loadoutSecondary == "iw6_knifeonlyfast" )
			perkPointBonus += 1;
		
		if ( !isValidPerkWeight( CONST_CLASS_PERK_POINTS + perkPointBonus, self.pers[ "loadoutPerks" ], true ) )
		{
			// Clear the perk functionality given to the player
			self _clearPerks();
			
			// Clear the ability bit mask used by lua to show player perks on spawn
			self SetClientOmnvar( "ui_spawn_abilities1", 0 );
			self SetClientOmnvar( "ui_spawn_abilities2", 0 );
			
			// Clear the pers perk array as this is used by the killcam to
			// populate another omnvar bit mask relayed to lua
			self.pers[ "loadoutPerks" ] = [];
		}
	}
	
	self.gettingLoadout = false;
	
	self notify ( "changed_kit" );
	self notify ( "giveLoadout" );
}

hasValidationInfraction()
{
	return IsDefined( self.pers ) && IsDefined( self.pers[ "validationInfractions" ] ) && self.pers[ "validationInfractions" ] > 0;
}

recordValidationInfraction()
{
	if ( IsDefined( self.pers ) && IsDefined( self.pers[ "validationInfractions" ] ) )
	{
		self.pers[ "validationInfractions" ] += 1;
	}
}

// JC-11/04/13- Validate the weight of the passed perks. This should be in _perks.gsc next
// to the other perk validate func but is here to keep the ffotd size down.
isValidPerkWeight( pointsAvailable, perks, shouldAssert )
{
	if ( !IsDefined( shouldAssert ) )
		shouldAssert = true;
	
	weight = 0;
	
	foreach ( perk in perks )
	{
		switch ( perk )
		{
			// Default Loadout Perks
			case "specialty_null":
				weight += 0;
				break;
			case "specialty_fastsprintrecovery":
			case "specialty_pitcher":
			case "specialty_sprintreload":
			case "specialty_silentkill":
			case "specialty_paint":
			case "specialty_falldamage":
			case "specialty_extra_equipment":
			case "specialty_gambler":
				weight += 1;
				break;
			case "specialty_fastreload":
			case "specialty_lightweight":
			case "specialty_marathon":
			case "specialty_quickswap":
			case "specialty_bulletaccuracy":
			case "specialty_blindeye":
			case "specialty_quieter":
			case "specialty_scavenger":
			case "specialty_detectexplosive":
			case "specialty_selectivehearing":
			case "specialty_regenfaster":
			case "specialty_sharp_focus":
			case "specialty_stun_resistance":
			case "_specialty_blastshield":
			case "specialty_extra_deadly":
			case "specialty_extraammo":
			case "specialty_hardline":
			case "specialty_boom":
				weight += 2;
				break;
			case "specialty_stalker":
			case "specialty_quickdraw":
			case "specialty_incog":
			case "specialty_gpsjammer":
			case "specialty_comexp":
			case "specialty_extra_attachment":
			case "specialty_twoprimaries":
				weight += 3;
				break;
			case "specialty_explosivedamage":
				weight += 4;
				break;
			case "specialty_deadeye":
				weight += 5;
				break;
			default:
				if ( shouldAssert )
				{
					// JC-ToDo: Uncomment to validate perks not in this switch post DLC Map Pack 1
					// weight = pointsAvailable + 1;
					AssertMsg( "isValidPerkWeight() found invalid perk: " + perk + " in load out perks. This should never happen." );
				}
				break;
		}
	}
	
	if ( weight > pointsAvailable && shouldAssert )
	{
		self recordValidationInfraction();
		AssertMsg( "isValidPerkWeight() found invalid perk weight total." );
	}
	
	return weight <= pointsAvailable;
}

_detachAll()
{
	if ( IsDefined( self.riotShieldModel ) )
	{
		self riotShield_detach( true );
	}
	
	if ( IsDefined( self.riotShieldModelStowed ) )
	{
		self riotShield_detach( false );
	}
	
	self.hasRiotShieldEquipped = false;
	
	self detachAll();
}

isPerkUpgraded( perkName )
{
	perkUpgrade = TableLookup( "mp/perktable.csv", 1, perkName, 8 );
	
	if ( perkUpgrade == "" || perkUpgrade == "specialty_null" )
		return false;
		
	if ( !self isItemUnlocked( perkUpgrade ) )
		return false;
		
	return true;
}

getPerkUpgrade( perkName )
{
	perkUpgrade = TableLookup( "mp/perktable.csv", 1, perkName, 8 );
	
	if ( perkUpgrade == "" || perkUpgrade == "specialty_null" )
		return "specialty_null";
		
	if ( !self isItemUnlocked( perkUpgrade ) )
		return "specialty_null";
		
	return ( perkUpgrade );
}


loadoutAllAbilities( loadoutEquipment, loadoutOffhand, loadoutPerksOverride, validateEquipment, class, teamName )
{
	dataOwner = self;
	if ( bot_is_fireteam_mode() && IsBot( self ) )
	{
		if ( !IsDefined( self.fireteam_commander ) )
			return;
		
		dataOwner = self.fireteam_commander;
	}
	else if ( isAI( self ) )
	{
		if ( validateEquipment )
		{
			loadoutEquipment = maps\mp\perks\_perks::validateEquipment( loadoutEquipment, true );
			loadoutOffhand = maps\mp\perks\_perks::validateEquipment( loadoutOffhand, false );
		}
		
		self maps\mp\gametypes\_weapons::lethalStowed_clear();
		
		self.loadoutPerkEquipment = loadoutEquipment;
		self.loadoutPerkOffhand = loadoutOffhand;
	
		self givePerkEquipment( loadoutEquipment, true );
		self givePerkOffhand( loadoutOffhand, false );
		
		if ( !IsDefined( self.pers[ "loadoutPerks" ] ) )
		{
			self.pers[ "loadoutPerks" ] = [];
		}
		
		// Game modes may override perks blocking loadout perks. Ignore disable
		// perks in this case
		if( IsDefined( loadoutPerksOverride ) && loadoutPerksOverride.size > 0 )
		{
			self.pers[ "loadoutPerks" ] = loadoutPerksOverride;
			
			// Game mode perks are hard coded / do not come from player data so
			// they do not need to be validated. Some game modes also use perks
			// not exposed to regular load outs.
			self maps\mp\perks\_abilities::givePerksFromKnownLoadout( loadoutPerksOverride, false );
		}
		else if ( perksEnabled() )
		{
			self_pers_loadout_perks = self.pers[ "loadoutPerks" ];
			if ( IsDefined( self_pers_loadout_perks ) && self_pers_loadout_perks.size > 0 && !self isJuggernaut() )
			{
				self maps\mp\perks\_abilities::givePerksFromKnownLoadout( self_pers_loadout_perks, true );		
			}
		}
		return;
	}
	
	if ( !IsDefined( self.class_num ) )
	{
		//Should we assert here?
		return;
	}
	
	if( !isJuggernaut() )
	{
		loadOutPerks = [];
		
		// Game modes may override perks blocking loadout perks. Ignore disable
		// perks in this case
		if( IsDefined( loadoutPerksOverride ) && loadoutPerksOverride.size > 0 )
		{
			loadoutPerks = loadoutPerksOverride;
			self.pers[ "loadoutPerks" ] = loadoutPerks;
			
			// Game mode perks are hard coded / do not come from player data so
			// they do not need to be validated. Some game modes also use perks
			// not exposed to regular load outs.
			self maps\mp\perks\_abilities::givePerksFromKnownLoadout( loadoutPerks, false );
		}
		// Other script assumes self.pers[ "loadoutPerks" ] defined
		else if ( !perksEnabled() )
		{
			self.pers[ "loadoutPerks" ] = loadoutPerks;
		}
		else
		{
			// if we haven't changed classes then we don't need to do this every time we get our loadout
			if( self hasChangedClass() )
			{
				for ( abilityCategoryIndex = 0 ; abilityCategoryIndex < NUM_ABILITY_CATEGORIES ; abilityCategoryIndex++ )
				{
					for ( abilityIndex = 0 ; abilityIndex < NUM_SUB_ABILITIES ; abilityIndex++ )
					{
						picked = false;
						if ( teamName != "none" )
						{
							classIndex = getClassIndex( class );
							picked = getMatchRulesData( "defaultClasses", teamName, classIndex, "class", "abilitiesPicked", abilityCategoryIndex, abilityIndex );
						}
						else
						{
							picked = self getCaCPlayerData( "loadouts", self.class_num, "abilitiesPicked", abilityCategoryIndex, abilityIndex );
						}
						if ( isDefined( picked ) && picked )
						{
							abilityRef = TableLookup( "mp/cacAbilityTable.csv", 0, abilityCategoryIndex + 1, 4 + abilityIndex );
							//println( "Picked ability: " + abilityRef );
							loadoutPerks[loadoutPerks.size] = abilityRef;
						}
					}
				}
				self.pers[ "loadoutPerks" ] = loadoutPerks;
			}
			else
			{
				loadoutPerks = self.pers[ "loadoutPerks" ];
			}
	
			self maps\mp\perks\_abilities::givePerksFromKnownLoadout( loadoutPerks, true );
		}
		// abilities, bit masking for lua
		bit_mask = [ 0, 0 ];
		pers_loadout_perks = self.pers[ "loadoutPerks" ];
		for( i = 0; i < pers_loadout_perks.size; i++ )
		{
			idx = int( TableLookup( "mp/killCamAbilitiesBitMaskTable.csv", 1, pers_loadout_perks[i], 0 ) );
			if( idx == 0 )
				continue;
			bitmaskIdx = int( ( idx - 1 ) / 24 );
			bit = 1 << ( ( idx - 1 ) % 24 );
			bit_mask[bitmaskIdx] |= bit;
		}
		self SetClientOmnvar( "ui_spawn_abilities1", bit_mask[0] );
		self SetClientOmnvar( "ui_spawn_abilities2", bit_mask[1] );
		
		// store these masks for matchdata recording, since it's expensive to do lots of table lookups
		self.abilityFlags = bit_mask;
	}
	
	if ( validateEquipment )
	{
		loadoutEquipment = maps\mp\perks\_perks::validateEquipment( loadoutEquipment, true );
		loadoutOffhand = maps\mp\perks\_perks::validateEquipment( loadoutOffhand, false );
	}
	
	self maps\mp\gametypes\_weapons::lethalStowed_clear();
	
	self.loadoutPerkEquipment = loadoutEquipment;
	self.loadoutPerkOffhand = loadoutOffhand;

	self givePerkEquipment( loadoutEquipment, true );
	self givePerkOffhand( loadoutOffhand, false );
}

//loadoutAllPerks( loadoutEquipment, loadoutOffhand, loadoutPerk1, loadoutPerk2, loadoutPerk3, loadoutPrimaryBuff, loadoutSecondaryBuff )
//{
//	loadoutEquipment = maps\mp\perks\_perks::validatePerk( 1, loadoutEquipment );
//	loadoutOffhand = maps\mp\perks\_perks::validatePerk( 0, loadoutOffhand );
//	loadoutPerk1 = maps\mp\perks\_perks::validatePerk( 2, loadoutPerk1 );
//	loadoutPerk2 = maps\mp\perks\_perks::validatePerk( 3, loadoutPerk2 );
//	loadoutPerk3 = maps\mp\perks\_perks::validatePerk( 4, loadoutPerk3 );
//	
//	loadoutPrimaryBuff = maps\mp\perks\_perks::validatePerk( undefined, loadoutPrimaryBuff );
//	if( loadoutPerk2 == "specialty_twoprimaries" )
//		loadoutSecondaryBuff = maps\mp\perks\_perks::validatePerk( undefined, loadoutSecondaryBuff );
//
//	self.loadoutPerk1 = loadoutPerk1;
//	self.loadoutPerk2 = loadoutPerk2;
//	self.loadoutPerk3 = loadoutPerk3;
//	self.loadoutPerkEquipment = loadoutEquipment;
//	self.loadoutPerkOffhand = loadoutOffhand;
//	self.loadoutPrimaryBuff = loadoutPrimaryBuff;
//	// we don't need to check to see if the player has specialty_twoprimaries because we want to clear this regardless and it will come in with specialty_null if nothing selected
//	//	this fixes a bug where you could set up your secondary with a proficiency while using overkill and then switch classes and have that proficiency on a weapon that shouldn't have it
//	self.loadoutSecondaryBuff = loadoutSecondaryBuff;
//
//	self givePerkEquipment( loadoutEquipment, true );
//	self givePerkOffhand( loadoutOffhand, false );
//
//	// TODO: put perk slots on the perks in petktable.csv and then set this to true
//	useSlot = false;
//	if( loadoutPerk1 != "specialty_null" )
//		self givePerk( loadoutPerk1, useSlot );
//	if( loadoutPerk2 != "specialty_null" )
//		self givePerk( loadoutPerk2, useSlot );
//	if( loadoutPerk3 != "specialty_null" )
//		self givePerk( loadoutPerk3, useSlot );
//
//	if( loadoutPrimaryBuff != "specialty_null" )
//		self givePerk( loadoutPrimaryBuff, useSlot );
//	// NOTE: don't give the secondary buff here because it should be weapon specific and only if you're currently holding the weapon, see watchWeaponChange()
//
//	perkUpgrd[0] = TableLookup( "mp/perktable.csv", 1, loadoutPerk1, 8 );
//	perkUpgrd[1] = TableLookup( "mp/perktable.csv", 1, loadoutPerk2, 8 );
//	perkUpgrd[2] = TableLookup( "mp/perktable.csv", 1, loadoutPerk3, 8 );
//	
//	foreach( upgrade in perkUpgrd )
//	{
//		if ( upgrade == "" || upgrade == "specialty_null" )
//			continue;
//			
//		if ( self isItemUnlocked( upgrade ) || !self rankingEnabled() )
//		{
//			// we want to put the upgrade perk in the slot in code
//			self givePerk( upgrade, useSlot );
//		}
//	}
//
//	// now if we don't have specialty_assists then reset the persistent data
//	if( !self _hasPerk( "specialty_assists" ) )
//		self.pers["assistsToKill"] = 0;
//}

trackRiotShield_onTrophyStow()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	
	while ( 1 )
	{
		self waittill( "grenade_pullback", grenadeName );
		
		if ( grenadeName != "trophy_mp" )
			continue;
		
		if ( !IsDefined( self.riotShieldModel ) )
			continue;
		
		self riotShield_move( true );
		
		self waittill( "offhand_end" );
		
		// Defensive checks in case the shield has moved
		if ( maps\mp\gametypes\_weapons::isRiotShield( self GetCurrentWeapon() ) && IsDefined( self.riotShieldModelStowed ) )
		{
			self riotShield_move( false );
		}
	}
}

trackRiotShield()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	
	self.hasRiotShield = self riotShield_hasWeapon();
	self.hasRiotShieldEquipped = maps\mp\gametypes\_weapons::isRiotShield( self.currentWeaponAtSpawn );
	
	// Code no longer allows two riotshields to be held so logic can assume one shield always
	if ( self.hasRiotShield )
	{
		if ( self.hasRiotShieldEquipped )
		{
			self riotShield_attach( true, self riotShield_getModel() );
		}
		else
		{
			self riotShield_attach( false, self riotShield_getModel() );
		}
	}
	
	self thread trackRiotShield_onTrophyStow();
	
	for ( ;; )
	{
		self waittill ( "weapon_change", newWeapon );
		
		if ( newWeapon == "none" )
			continue;
		
		onArm = maps\mp\gametypes\_weapons::isRiotShield( newWeapon );
		onBack = !onArm && riotShield_hasWeapon();
		
		AssertEx( !( onArm && onBack ), "The player should never be carrying two riotshields." );
		
		// Verify arm model is correct
		if ( onArm )
		{
			if ( !IsDefined( self.riotShieldModel ) )
			{
				if ( IsDefined( self.riotShieldModelStowed ) )
				{
					self riotShield_move( false );
				}
				else
				{
					self riotShield_attach( true, self riotShield_getModel() );
				}
			}
		}
		// Verify back model is correct
		else if ( onBack )
		{
			if ( !IsDefined( self.riotShieldModelStowed ) )
			{
				if ( IsDefined( self.riotShieldModel ) )
				{
					self riotShield_move( true );
				}
				else
				{
					self riotShield_attach( false, self riotShield_getModel() );
				}
			}
		}
		else
		{
			if ( IsDefined( self.riotShieldModel ) )
			{
				self riotShield_detach( true );
			}
			
			if ( IsDefined( self.riotShieldModelStowed ) )
			{
				self riotShield_detach( false );
			}
		}
		
		self.hasRiotShield = onArm || onBack;
		self.hasRiotShieldEquipped = onArm;
	}
}

buildWeaponName( baseName, attachments, camo, reticle )
{
	AssertEx( IsArray( attachments ), "buildWeaponName() passed invalid attachment array." );

	attachments = array_remove( attachments, "none" );
	
	AssertEx( attachments.size <= 4, "buildWeaponName() passed attachment array that was too large." );
	
	for ( idxAtt = 0; idxAtt < attachments.size; idxAtt++ )
	{
		attachments[ idxAtt ] = attachmentMap_toUnique( attachments[ idxAtt ], baseName );
	}
	
	bareWeaponName = "";
	
	if ( IsSubStr( baseName, "iw5" ) || IsSubStr( baseName, "iw6" ) )
	{
		weaponName = baseName + "_mp";
		endIndex = baseName.size;
		bareWeaponName = GetSubStr( baseName, 4, endIndex );
	}
	else
	{
		weaponName = baseName;
	}
	
	weapClass = getWeaponClass( baseName );
	needScope = weapClass == "weapon_sniper" || weapClass == "weapon_dmr" || baseName == "iw6_dlcweap02";
	
	// If the gun needs a scope and doesn't have a rail attachment
	canUseReticle = false;
	hasAttachRail = false;
	foreach ( attachment in attachments )
	{
		if ( getAttachmentType( attachment ) == "rail" )
		{
			hasAttachRail = true;
			canUseReticle = true;
			break;
		}
	}
		
	if ( needScope && !hasAttachRail )
	{
		attachments[ attachments.size ] = bareWeaponName + "scope";
	}
	
	if ( !canUseReticle && IsDefined( reticle ) )
    {
		reticle = 0;
    }
	
	if ( IsDefined( attachments.size ) && attachments.size )
	{
		attachments = alphabetize( attachments );
	}
	
	foreach ( attachment in attachments )
	{
		weaponName += "_" + attachment;
	}

	if ( IsSubStr( weaponName, "iw5" ) || IsSubStr( weaponName, "iw6" ) )
	{
		weaponName = buildWeaponNameCamo( weaponName, camo );
		weaponName = buildWeaponNameReticle( weaponName, reticle );
	}
	else if ( !isValidWeapon( weaponName + "_mp", false ) )
	{
		weaponName = baseName + "_mp";
	}
	else
	{
		weaponName = buildWeaponNameCamo( weaponName, camo );
		weaponName = buildWeaponNameReticle( weaponName, reticle );
		weaponName += "_mp";
	}
	
	return weaponName;
}

buildWeaponNameCamo( weaponName, camo )
{
	if ( !IsDefined( camo ) || camo <= 0 )
		return weaponName;

	return weaponName + "_camo" + ter_op( camo < 10, "0", "" ) + camo;
}

buildWeaponNameReticle( weaponName, reticle )
{
	// Not defined or scope default
	if ( !IsDefined( reticle ) || reticle == 0 )
	{
		return weaponName;
	}
	
	// reticle names are: scope1, scope2... scope11, scope12 up to 16
	weaponName += "_scope" + reticle;

	return weaponName;
}

setKillstreaks( streak1, streak2, streak3 )
{
	self.killStreaks = [];

	killStreaks = [];

	if ( IsDefined( streak1 ) && streak1 != "none" )
	{
		streakVal = self maps\mp\killstreaks\_killstreaks::getStreakCost( streak1 );
		killStreaks[streakVal] = streak1;
	}
	if ( IsDefined( streak2 ) && streak2 != "none" )
	{
		streakVal = self maps\mp\killstreaks\_killstreaks::getStreakCost( streak2 );
		killStreaks[streakVal] = streak2;
	}
	if ( IsDefined( streak3 ) && streak3 != "none" )
	{
		streakVal = self maps\mp\killstreaks\_killstreaks::getStreakCost( streak3 );
		killStreaks[streakVal] = streak3;
	}

	// foreach doesn't loop through numbers arrays in number order; it loops through the elements in the order
	// they were added. We'll use this to fix it for now.
	maxVal = 0;
	foreach ( streakVal, streakName in killStreaks )
	{
		if ( streakVal > maxVal )
			maxVal = streakVal;
	}

	for ( streakIndex = 0; streakIndex <= maxVal; streakIndex++ )
	{
		if ( !IsDefined( killStreaks[ streakIndex ] ) )
			continue;
			
		streakName = killStreaks[streakIndex];
			
		self.killStreaks[ streakIndex ] = killStreaks[ streakIndex ];
	}
}


replenishLoadout() // used by ammo hardpoint.
{
	team = self.pers["team"];
	class = self.pers["class"];

    weaponsList = self GetWeaponsListAll();
    for( idx = 0; idx < weaponsList.size; idx++ )
    {
		weapon = weaponsList[idx];

		self giveMaxAmmo( weapon );
		self SetWeaponAmmoClip( weapon, 9999 );

		if ( weapon == "claymore_mp" || weapon == "claymore_detonator_mp" )
			self setWeaponAmmoStock( weapon, 2 );
    }
	
	if ( self getAmmoCount( level.classGrenades[class]["primary"]["type"] ) < level.classGrenades[class]["primary"]["count"] )
 		self SetWeaponAmmoClip( level.classGrenades[class]["primary"]["type"], level.classGrenades[class]["primary"]["count"] );

	if ( self getAmmoCount( level.classGrenades[class]["secondary"]["type"] ) < level.classGrenades[class]["secondary"]["count"] )
 		self SetWeaponAmmoClip( level.classGrenades[class]["secondary"]["type"], level.classGrenades[class]["secondary"]["count"] );	
}


onPlayerConnecting()
{
	for(;;)
	{
		level waittill( "connected", player );

		if ( !isDefined( player.pers["class"] ) )
		{
			player.pers["class"] = "";
		}
		if ( !isDefined( player.pers["lastClass"] ) )
		{
			player.pers["lastClass"] = "";
		}
		player.class = player.pers["class"];
		player.lastClass = player.pers["lastClass"];
		player.detectExplosives = false;
		player.bombSquadIcons = [];
		player.bombSquadIds = [];
		
		if ( !IsDefined( player.pers[ "validationInfractions" ] ) )
		{
			player.pers[ "validationInfractions" ] = 0;
		}
	}
}


fadeAway( waitDelay, fadeDelay )
{
	wait waitDelay;
	
	self fadeOverTime( fadeDelay );
	self.alpha = 0;
}


setClass( newClass )
{
	self.curClass = newClass;
}

getPerkForClass( perkSlot, className )
{
    class_num = getClassIndex( className );

    if( isSubstr( className, "custom" ) )
        return cac_getPerk( class_num, perkSlot );
    else
        return table_getPerk( level.classTableName, class_num, perkSlot );
}


classHasPerk( className, perkName )
{
	return( getPerkForClass( 0, className ) == perkName || getPerkForClass( 1, className ) == perkName || getPerkForClass( 2, className ) == perkName );
}

isValidPrimary( refString, showAssert )
{
	if( !IsDefined( showAssert ) )
		showAssert = true;
	result = false;
	switch ( refString )
	{
		case "iw6_cbjms":
		case "iw6_k7":
		case "iw6_kriss":
		case "iw6_microtar":
		case "iw6_pp19":
		case "iw6_vepr":

		case "iw6_ak12":
		case "iw6_arx160":
		case "iw6_bren":
		case "iw6_fads":
		case "iw6_honeybadger":
		case "iw6_msbs":
		case "iw6_r5rgp":
		case "iw6_sc2010":

		case "iw6_gm6":
		case "iw6_l115a3":
		case "iw6_usr":
		case "iw6_vks":

		case "iw6_g28":
		case "iw6_imbel":
		case "iw6_mk14":
		case "iw6_svu":

		case "iw6_fp6":
		case "iw6_maul":
		case "iw6_mts255":
		case "iw6_uts15":

		case "iw6_ameli":
		case "iw6_kac":
		case "iw6_lsat":
		case "iw6_m27":
		case "iw6_riotshield":
		
		case "iw6_knifeonly":
		case "iw6_knifeonlyfast":
		
		case "iw6_dlcweap01":
		case "iw6_dlcweap02":
		case "iw6_dlcweap03":
			result = true;
			break;
		case "iw6_minigunjugg":
		case "iw6_riotshieldjugg":
		case "iw6_knifeonlyjugg":
		case "iw6_axe":
		case "iw6_predatorcannon":
		case "iw6_mariachimagnum":
			if ( self isJuggernaut() )
				result = true;
			else
				result = false;
			break;
		default:
			result = false;
			break;
	}
	
	if ( !result && showAssert )
	{
		self recordValidationInfraction();
		AssertMsg( "Replacing invalid primary weapon: " + refString );
	}
	
	return result;
}

isValidSecondary( refString, showAssert, blockPrimary )
{
	if( !IsDefined( showAssert ) )
		showAssert = true;
	
	if ( !IsDefined( blockPrimary ) )
		blockPrimary = true;

	result = false;
	switch ( refString )
	{
		case "none":
		case "iw6_magnum":
		case "iw6_m9a1":
		case "iw6_p226":
		case "iw6_mp443":
		case "iw6_pdw":
		case "iw6_pdwauto":
		case "iw6_mk32":
		case "iw6_rgm":
		case "iw6_panzerfaust3":
		
		case "iw6_p226jugg":
		case "iw6_magnumjugg":
			result = true;
			break;
		default:
		{
			if ( blockPrimary == false )
			{
				result = isValidPrimary( refString, false );
			}
			break;
		}
	}
	
	if ( !result && showAssert )
	{
		self recordValidationInfraction();
		AssertMsg( "Replacing invalid secondary weapon: " + refString );
	}
	
	return result;
}

isValidAttachment( refString, weaponName, shouldAssert )
{
	result = false;
	
	if( !IsDefined( shouldAssert ) )
		shouldAssert = true;

	switch ( refString )
	{
		case "none":
		
		case "acog":
		case "akimbo":
		case "ammoslug":
		case "barrelbored":
		case "barrelrange":
		case "eotech":  
		case "firetypeauto":
		case "firetypeburst":
		case "firetypesingle":
		case "flashsuppress":
		case "fmj":
		case "gl":
		case "grip":
		case "heartbeat":
		case "hybrid":
		case "ironsight":
		case "reflex":
		case "rof":
		case "rshieldradar":
		case "rshieldscrambler":
		case "rshieldspikes":
		case "shotgun":
		case "silencer":
		case "tactical":
		case "thermal":
		case "tracker":
		case "vzscope":
		case "xmags":
			result = true;
			break;
		default:
			result = false;
			break;
	}
	
	if ( result && refString != "none" )
	{
		validAttachments = getWeaponAttachmentArrayFromStats( weaponName );
		result = array_contains( validAttachments, refString );
	}
	
	if( !result && shouldAssert )
	{
		self recordValidationInfraction();
		AssertMsg( "Replacing invalid weapon attach: " + refString );
	}
	
	return result;
}

isAttachmentUnlocked( weaponRef, attachmentRef )
{
/#
	if( GetDvarInt( "unlockAllItems" ) )
		return true;
#/
	if ( isMLGMatch() )
		return true;

	// HACK: bypassing this check until we do weapon progression or remove if no progression
	if( true )
		return true;

	tableWeaponClassCol = 0;
	tableWeaponClassAttachmentCol = 2;
	tableWeaponRankCol = 4;
	weaponRank = self GetRankedPlayerData( "weaponRank", weaponRef );
	colNum = int( TableLookup( "mp/weaponRankTable.csv", tableWeaponClassCol, getWeaponClass( weaponRef ), tableWeaponClassAttachmentCol ) );
	attachmentRank = int( TableLookup( "mp/weaponRankTable.csv", colNum, attachmentRef, tableWeaponRankCol ) );
	if( weaponRank >= attachmentRank )
		return true;

	return false;
}

//detectedExploit is used to set playerdata in _matchdata
isValidWeaponBuff( refString, weapon )
{
	weapClass = getWeaponClass( weapon );
	
	if ( weapClass == "weapon_assault" )
	{		
		switch ( refString )
		{
			case "specialty_bulletpenetration":
			case "specialty_marksman":
			case "specialty_bling":
			case "specialty_sharp_focus":
			case "specialty_holdbreathwhileads":
			case "specialty_reducedsway":
				return true;
			default:
				self.detectedExploit = 250;
				return false;
		}
	}
	else if ( weapClass == "weapon_smg" )
	{
		switch ( refString )
		{
			case "specialty_marksman":
			case "specialty_bling":
			case "specialty_sharp_focus":
			case "specialty_longerrange":
			case "specialty_fastermelee":
			case "specialty_reducedsway":
				return true;
			default:
				self.detectedExploit = 250;
				return false;
		}
	}
	else if ( weapClass == "weapon_lmg" )
	{
		switch ( refString )
		{
			case "specialty_bulletpenetration":
			case "specialty_marksman":
			case "specialty_bling":
			case "specialty_sharp_focus":
			case "specialty_reducedsway":
			case "specialty_lightweight":
				return true;
			default:
				self.detectedExploit = 250;
				return false;
		}
	}
	else if ( weapClass == "weapon_sniper" )
	{
		switch ( refString )
		{
			case "specialty_marksman":
			case "specialty_bulletpenetration":
			case "specialty_bling":
			case "specialty_sharp_focus":
			case "specialty_lightweight":
			case "specialty_reducedsway":
				return true;
			default:
				self.detectedExploit = 250;
				return false;
		}
	}
	else if ( weapClass == "weapon_shotgun" )
	{
		switch ( refString )
		{
			case "specialty_marksman":
			case "specialty_sharp_focus":
			case "specialty_bling":
			case "specialty_fastermelee":
			case "specialty_longerrange":
			case "specialty_moredamage":
				return true;
			default:
				self.detectedExploit = 250;
				return false;
		}
	}
	else if ( weapClass == "weapon_riot" )
	{
		switch ( refString )
		{
			case "specialty_fastermelee":
			case "specialty_lightweight":
				return true;
			default:
				self.detectedExploit = 250;
				return false;
		}
	}
	else //secondary weapons dont have buffs...
	{
		self.detectedExploit = 250;
		return false;
	}
}

isWeaponBuffUnlocked( weaponRef, buffRef )
{
/#
	if( GetDvarInt( "unlockAllItems" ) )
		return true;
#/
	if ( isMLGMatch() )
		return true;

	tableWeaponClassCol = 0;
	tableWeaponClassBuffCol = 4;
	tableWeaponRankCol = 4;
	weaponRank = self GetRankedPlayerData( "weaponRank", weaponRef );
	colNum = int( TableLookup( "mp/weaponRankTable.csv", tableWeaponClassCol, getWeaponClass( weaponRef ), tableWeaponClassBuffCol ) );
	buffRank = int( TableLookup( "mp/weaponRankTable.csv", colNum, buffRef, tableWeaponRankCol ) );
	if( weaponRank >= buffRank )
		return true;

	return false;
}

// This camo list needs to stay in synch with patch_common_core_mp.csv
isValidCamo( refString )
{
	switch ( refString )
	{
		case "none":
		case "snow":
		case "brush":
		case "autumn":
		case "ocean":
		case "tan":
		case "red":
		case "caustic":
		case "dark":
		case "green":
		case "net":
		case "trail":
		case "winter":
		case "gold":
		case "clan01":
		case "clan02":
		case "camo03":	// Clan - Diamond
		case "camo04":	// Zebra
		case "camo05":	// Ice
		case "camo06":	// Promo - Blacksmith
		case "camo07":	// Micro - Fire
		case "camo08":	// Micro - Bling
		case "camo09":	// Micro - Crisis
		case "camo10":	// Micro - Kitties
		case "camo11":	// Micro - Extinction
		case "camo12":	// Festive
		case "camo13":	// Micro - Makaraov
		case "camo14":	// Micro - Molten
		case "camo15":	// Micro - Soap
		case "camo16":	// Micro - 80's
		case "camo17":	// Micro - Heartlands
		case "camo18":	// Micro - Circuit Board
		case "camo19":	// Micro - Blooshot
		case "camo20":	// Micro - Blunt Force
		case "camo21":	// Micro - Fitness
		case "camo22":	// Micro - Koi
		case "camo23":	// Micro - Leopard
		case "camo24":	// Micro - Price
		case "camo25":	// Micro - Metal
		case "camo26":	// Micro - Unicorn
		case "camo27":	// Micro - Rubber Ducky
		case "camo28":	// Micro - Flags
		case "camo29":	// Micro - Abstract
		case "camo30":	// Micro - Dragon
		case "camo31":	// Micro - Pirate Skulls
		case "camo32":	// Micro - Sailor Jerry
		case "camo33":	// Micro - Lime Wolf
			return true;
		default:
			self recordValidationInfraction();
			AssertMsg( "Replacing invalid camo: " + refString );
			return false;
	}
}

// This reticle list needs to stay in synch with patch_common_core_mp.csv
isValidReticle( refString )
{
	switch ( refString )
	{
		case "none":
		case "ret01":
		case "ret02":
		case "ret03":
		case "ret04":
		case "ret05":
		case "acogdef":
		case "acog01":
		case "acog02":
		case "acog03":
		case "acog04":
		case "acog05":
		case "eotechdef":
		case "eotech01":
		case "eotech02":
		case "eotech03":
		case "eotech04":
		case "eotech05":
		case "hybriddef":
		case "hybrid01":
		case "hybrid02":
		case "hybrid03":
		case "hybrid04":
		case "hybrid05":
		case "reflexdef":
		case "reflex01":
		case "reflex02":
		case "reflex03":
		case "reflex04":
		case "reflex05":
		case "retclan01":
		case "retdlc01":	// Zebra
		case "retdlc02":	// Pow
		case "retdlc03":	// Festive
		case "retdlc04":	// Micro - Blunt Force
		case "retdlc05":	// Micro - Price
		case "retdlc06":	// Micro - Circuit Board
		case "retdlc07":	// Micro - Fire
		case "retdlc08":	// Micro - Rubber Ducky
		case "retdlc09":	// Micro - Kitties
		case "retdlc10":	// Clan  - Diamond
		case "retdlc11":	// Micro - Flags
		case "retdlc12":	// Micro - Bling
		case "retdlc13":	// Micro - Makaraov
		case "retdlc14":	// Micro - Crisis
		case "retdlc15":	// Micro - Bloodshot
		case "retdlc16":	// Micro - 80's
		case "retdlc17":	// Micro - Heartlands
		case "retdlc18":	// Micro - Molten
		case "retdlc19":	// Micro - Soap
		case "retdlc20":	// Promo - Blacksmith
		case "retdlc21":	// Micro - Extinction
		case "retdlc22":	// Micro - Fitness
		case "retdlc23":	// Micro - Koi
		case "retdlc24":	// Micro - Leopard
		case "retdlc25":	// Micro - Metal
		case "retdlc26":	// Micro - Unicorn
		case "retdlc27":	// Micro - Abstract
		case "retdlc28":	// Micro - Dragon
		case "retdlc29":	// Micro - Pirate Skulls
		case "retdlc30":	// Micro - Sailor Jerry
		case "retdlc31":	// Micro - Lime Wolf
			return true;
		default:
			self recordValidationInfraction();
			AssertMsg( "Replacing invalid reticle " + refString );
			return false;
	}
}

isCamoUnlocked( weaponRef, camoRef )
{
	if ( isMLGMatch() )
		return true;
	
	//This will need to be replaced with a check to challenge state	
	if ( !isDefined( level.challengeInfo["ch_" + weaponRef + "_" + camoRef] ) )
	{
		/#
			println("ch_" + weaponRef + "_" + camoRef + " Does not exist");
		#/
		
		return true;
	}

	return true;
}

isValidEquipment( refString, shouldAssert )
{
	if( !IsDefined( shouldAssert ) )
		shouldAssert = true;
	
	result = true;
	
	refString = ter_op( refString == "none", "specialty_null", refString );
	if ( maps\mp\perks\_perks::validateEquipment( refString, true, shouldAssert ) != refString )
	{
		result = false;
		if ( shouldAssert )
		{
			self recordValidationInfraction();
			AssertMsg( "Replacing invalid equipment: " + refString );
		}
	}
	
	return result;
}

isValidOffhand( refString, shouldAssert )
{
	if( !IsDefined( shouldAssert ) )
		shouldAssert = true;
	
	result = true;
	
	refString = ter_op( refString == "none", "specialty_null", refString );
	if ( maps\mp\perks\_perks::validateEquipment( refString, false, shouldAssert ) != refString )
	{
		if ( shouldAssert )
		{
			self recordValidationInfraction();
			AssertMsg( "Replacing invalid off hand: " + refString );
		}
	}
	
	return result;
}

isPerk( refString )
{
	return int( TableLookup( "mp/perktable.csv", 1, refString, 0 ) );
}

isKillstreak( refString )
{
	return ( getKillstreakIndex( refString ) != -1 );
}

isValidPerk1( refString )
{
	switch ( refString )
	{
	case "specialty_longersprint":
	case "specialty_fastreload":
	case "specialty_scavenger":	
	case "specialty_blindeye":
	case "specialty_paint":
		return true;
	default:
		//assertMsg( "Replacing invalid perk1: " + refString );
		//return false;
		return true;
	}
}

isValidPerk2( refString, perk1 )
{
	if( !IsDefined( perk1 ) || perk1 != "specialty_anytwo" )
	{
		switch ( refString )
		{
		case "specialty_hardline":
		case "specialty_coldblooded":
		case "specialty_quickdraw":
		case "specialty_twoprimaries":
		case "specialty_assists":
		case "_specialty_blastshield":
			return true;
		default:
			//assertMsg( "Replacing invalid perk2: " + refString );
			//return false;
			return true;
		}
	}
	return true;
}

isValidPerk3( refString, perk1 )
{
	if( !IsDefined( perk1 ) || perk1 != "specialty_anytwo" )
	{
		switch ( refString )
		{
		case "specialty_detectexplosive":
		case "specialty_paint":
		case "specialty_bulletaccuracy":
		case "specialty_quieter":
		case "specialty_stalker":
			return true;
		default:
			//assertMsg( "Replacing invalid perk3: " + refString );
			//return false;
			return true;
		}
	}
	return true;
}


isValidWeapon( refString, shouldAssert )
{
	if ( !IsDefined( shouldAssert ) )
		shouldAssert = true;
		
	if ( !isDefined( level.weaponRefs ) )
	{
		level.weaponRefs = [];

		foreach ( weaponRef in level.weaponList )
			level.weaponRefs[ weaponRef ] = true;
	}

	if ( isDefined( level.weaponRefs[ refString ] ) )
		return true;

	if ( shouldAssert )
	{
		self recordValidationInfraction();
		AssertMsg( "Replacing invalid weapon/attachment combo: " + refString );
	}
	
	return false;
}

isValidKillstreak( refString, streakType )
{
	
	validKS =	isAssaultKillstreak( refString ) || 
				isSupportKillstreak( refString ) || 
				isSpecialistKillstreak( refString ) || 
				refString == "none";

	if( IsDefined( streakType ) )
	{
		if( streakType == "assault" )
		{
			validKS =	isAssaultKillstreak( refString ) ||  
						refString == "none";
		}
		else if( streakType == "support" )
		{
			validKS =	isSupportKillstreak( refString ) ||  
						refString == "none";
		}
		else if( streakType == "specialist" )
		{
			validKS =	isSpecialistKillstreak( refString ) || 
						refString == "none";
		}
	}
	
	if( !validKS )
	{
		AssertMsg( "Replacing invalid killstreak: " + refString );
		self recordValidationInfraction();
	}

	return validKS;
}

hasChangedClass() // self == player
{
	changedClass = false;
	
	if ( ( IsDefined( self.lastClass ) && self.lastClass != self.class ) || !IsDefined( self.lastClass ) ) 
		changedClass = true;
	
	// Killstreaks are not being cleared correctly, when default loadouts are set, after player changes from survivor to infected
	// Cant change self.class / self.lasClass, because they need to be set to "gamemode" for infected loadouts to work
	// TODO: Next time around, we need to make sure that special gamemodes have another way	to support multiple classes, so the above check will work by default
	if	(
			level.gameType == "infect"
			&& ( !IsDefined( self.last_infected_class ) || self.last_infected_class != self.infected_class )
		)
	{
		changedClass = true;
	}
	
	return changedClass;
}

getNumAbilityCategories()
{
	return NUM_ABILITY_CATEGORIES;
}

getNumSubAbility()
{
	return NUM_SUB_ABILITIES;
}
