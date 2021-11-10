#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

CRATE_KILLCAM_OFFSET = ( 0, 0, 300);
GRAVITY_UNITS_PER_SECOND = 800;

DUMMY_CRATE_MODEL 				= "carepackage_dummy_iw6";
FRIENDLY_CRATE_MODEL 			= "carepackage_friendly_iw6";
ENEMY_CRATE_MODEL 				= "carepackage_enemy_iw6";

DUMMY_JUGGERNAUT_CRATE_MODEL	= "mp_juggernaut_carepackage_dummy";
FRIENDLY_JUGGERNAUT_CRATE_MODEL	= "mp_juggernaut_carepackage";
ENEMY_JUGGERNAUT_CRATE_MODEL 	= "mp_juggernaut_carepackage_red";

CONST_CRATE_OWNER_USE_TIME = 500;
CONST_CRATE_OTHER_USE_TIME = 3000;

init()
{
	level._effect[ "airdrop_crate_destroy" ] 	= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_airdrop_crate_dust_kickup" );
	level._effect[ "airdrop_dust_kickup" ]		= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_airdrop_crate_dust_kickup" );
	

	PrecacheMpAnim( "juggernaut_carepackage" );
	
	setAirDropCrateCollision( "airdrop_crate" ); 	// old care package entities
	setAirDropCrateCollision( "care_package" );		// new care package entities
	assert( IsDefined(level.airDropCrateCollision) );
	
	level.killStreakFuncs["airdrop_assault"] 			= ::tryUseAirdrop;
	level.killStreakFuncs["airdrop_support"] 			= ::tryUseAirdrop;
	level.killStreakFuncs["airdrop_juggernaut"] 		= ::tryUseAirdrop;	
	level.killStreakFuncs["airdrop_juggernaut_recon"]	= ::tryUseAirdrop;
	level.killStreakFuncs["airdrop_juggernaut_maniac"] 	= ::tryUseAirdrop;	

	level.numDropCrates = 0;
	level.littleBirds 	= [];
	level.crateTypes	= [];
	level.crateMaxVal 	= [];

	// ASSAULT
	//				Drop Type			Type							Weight  Function				Friendly Model						Enemy Model						Hint String										Dummy Model
	addCrateType(	"airdrop_assault",	"uplink",						25,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL, 				&"KILLSTREAKS_HINTS_UPLINK_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"ims",							25,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_IMS_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"guard_dog",					20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_GUARD_DOG_PICKUP",			DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"drone_hive",					20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_DRONE_HIVE_PICKUP",			DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"sentry",						10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_SENTRY_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"helicopter",					10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_HELICOPTER_PICKUP",			DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_assault",	"ball_drone_backup",			4,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_BALL_DRONE_BACKUP_PICKUP",	DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"vanguard",						4,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_VANGUARD_PICKUP",			DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"airdrop_juggernaut_maniac",	3,		::juggernautCrateThink, FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_MANIAC_PICKUP",	DUMMY_JUGGERNAUT_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"airdrop_juggernaut",			2,		::juggernautCrateThink, FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_PICKUP",			DUMMY_JUGGERNAUT_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"heli_pilot",					1,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_HELI_PILOT_PICKUP",			DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_assault",	"odin_assault",					1,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_ODIN_ASSAULT_PICKUP",		DUMMY_CRATE_MODEL );

	// SUPPORT
	addCrateType(	"airdrop_support",	"uplink_support",				25,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_UPLINK_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_support",	"deployable_vest",				25,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_DEPLOYABLE_VEST_PICKUP",	DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_support",	"deployable_ammo",				20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_DEPLOYABLE_AMMO_PICKUP",	DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_support",	"ball_drone_radar",				20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_BALL_DRONE_RADAR_PICKUP",	DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_support",	"aa_launcher",					10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_AA_LAUNCHER_PICKUP",		DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_support",	"jammer",						10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_JAMMER_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_support",	"air_superiority",				4,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_AIR_SUPERIORITY_PICKUP",	DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_support",	"recon_agent",					4,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_RECON_AGENT_PICKUP",		DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_support",	"heli_sniper",					4,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_HELI_SNIPER_PICKUP",		DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_support",	"uav_3dping",					3,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_UAV_3DPING_PICKUP",			DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_support",	"airdrop_juggernaut_recon",		1,		::juggernautCrateThink,	FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_RECON_PICKUP",	DUMMY_JUGGERNAUT_CRATE_MODEL );	
	addCrateType(	"airdrop_support",	"odin_support",					1,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_ODIN_SUPPORT_PICKUP",		DUMMY_CRATE_MODEL );	

	// KILLSTREAKS
	//			  	Drop Type						Type							Weight	Function				Friendly Model						Enemy Model						Hint String								Dummy Model	
	addCrateType( 	"airdrop_juggernaut",			"airdrop_juggernaut",			100,	::juggernautCrateThink, FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_PICKUP",			DUMMY_JUGGERNAUT_CRATE_MODEL );
	addCrateType( 	"airdrop_juggernaut_recon",		"airdrop_juggernaut_recon",		100,	::juggernautCrateThink, FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_RECON_PICKUP",	DUMMY_JUGGERNAUT_CRATE_MODEL );
	addCrateType( 	"airdrop_juggernaut_maniac",	"airdrop_juggernaut_maniac",	100,	::juggernautCrateThink, FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_MANIAC_PICKUP",	DUMMY_JUGGERNAUT_CRATE_MODEL );
	
	//Grind
	//
	addCrateType(	"airdrop_grnd",	"uplink",						25,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL, 				&"KILLSTREAKS_HINTS_UPLINK_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"ims",							25,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_IMS_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"guard_dog",					20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_GUARD_DOG_PICKUP",			DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"drone_hive",					20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_DRONE_HIVE_PICKUP",			DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"sentry",						10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_SENTRY_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"helicopter",					10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_HELICOPTER_PICKUP",			DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_grnd",	"ball_drone_backup",			4,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_BALL_DRONE_BACKUP_PICKUP",	DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"vanguard",						4,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_VANGUARD_PICKUP",			DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"airdrop_juggernaut_maniac",	3,		::juggernautCrateThink, FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_MANIAC_PICKUP",	DUMMY_JUGGERNAUT_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"airdrop_juggernaut",			2,		::juggernautCrateThink, FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_PICKUP",			DUMMY_JUGGERNAUT_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"heli_pilot",					1,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_HELI_PILOT_PICKUP",			DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"deployable_vest",				25,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_DEPLOYABLE_VEST_PICKUP",	DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"deployable_ammo",				20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_DEPLOYABLE_AMMO_PICKUP",	DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"ball_drone_radar",				20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_BALL_DRONE_RADAR_PICKUP",	DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_grnd",	"aa_launcher",					20,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_AA_LAUNCHER_PICKUP",		DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_grnd",	"jammer",						10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_JAMMER_PICKUP",				DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"air_superiority",				10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_AIR_SUPERIORITY_PICKUP",	DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_grnd",	"recon_agent",					15,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_RECON_AGENT_PICKUP",		DUMMY_CRATE_MODEL );
	addCrateType(	"airdrop_grnd",	"heli_sniper",					10,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_HELI_SNIPER_PICKUP",		DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_grnd",	"uav_3dping",					5,		::killstreakCrateThink,	FRIENDLY_CRATE_MODEL,				ENEMY_CRATE_MODEL,				&"KILLSTREAKS_HINTS_UAV_3DPING_PICKUP",			DUMMY_CRATE_MODEL );	
	addCrateType(	"airdrop_grnd",	"airdrop_juggernaut_recon",		5,		::juggernautCrateThink,	FRIENDLY_JUGGERNAUT_CRATE_MODEL,	ENEMY_JUGGERNAUT_CRATE_MODEL,	&"KILLSTREAKS_HINTS_JUGGERNAUT_RECON_PICKUP",	DUMMY_JUGGERNAUT_CRATE_MODEL );	

	if( IsDefined(level.customCrateFunc) )
		[[level.customCrateFunc]]( FRIENDLY_CRATE_MODEL, ENEMY_CRATE_MODEL );
	
	if( IsDefined(level.mapCustomCrateFunc) )
		[[level.mapCustomCrateFunc]]();
	
	generateMaxWeightedCrateValue();
	
	config = SpawnStruct();
	config.xpPopup = "destroyed_airdrop";
	// !!! NEED VO
	config.voDestroyed = undefined;
	config.callout = "callout_destroyed_airdrop";
	config.samDamageScale = 0.09;
	// xpval = 200
	level.heliConfigs[ "airdrop" ] = config;
	
	maps\mp\gametypes\_rank::registerScoreInfo( "little_bird", 200 );

/#
	SetDevDvarIfUninitialized( "scr_crateOverride", "" );
	SetDevDvarIfUninitialized( "scr_crateTypeOverride", "" );

	SetDevDvarIfUninitialized( "scr_airDrop_max_linear_velocity", 			1200 );
	SetDevDvarIfUninitialized( "scr_airDrop_slowdown_max_linear_velocity", 	 600 );
#/
}

generateMaxWeightedCrateValue()
{
	foreach( dropType, dropTypeArray in level.crateTypes )
	{
		level.crateMaxVal[ dropType ] = 0;	
		foreach( crateType in dropTypeArray )
		{
			type = crateType.type;
			if( !level.crateTypes[ dropType ][ type ].raw_weight )
			{
				level.crateTypes[ dropType ][ type ].weight = level.crateTypes[ dropType ][ type ].raw_weight;
				continue;
			}

			level.crateMaxVal[ dropType ] += level.crateTypes[ dropType ][ type ].raw_weight;
			level.crateTypes[ dropType ][ type ].weight = level.crateMaxVal[ dropType ];
		}
	}
}

changeCrateWeight(dropType, crateType, crateWeight)
{
	if(!IsDefined(level.crateTypes[ dropType ]) || !IsDefined(level.crateTypes[ dropType ][ crateType ]))
	   return;
	   
	level.crateTypes[ dropType ][ crateType ].raw_weight = crateWeight;
	generateMaxWeightedCrateValue();
}

setAirDropCrateCollision( carePackageName )
{
	airDropCrates = GetEntArray( carePackageName, "targetname" );
	
	if( !IsDefined(airDropCrates) || (airDropCrates.size == 0 ) )
	{
		return;
	}
	
	level.airDropCrateCollision = GetEnt( airDropCrates[0].target, "targetname" );
	
	foreach( crate in airDropCrates )
	{
		crate deleteCrate();
	}
}

addCrateType( dropType, crateType, crateWeight, crateFunc, crateModelFriendly, crateModelEnemy, hintString, optionalHint, crateModelDummy )
{
	if( !IsDefined( crateModelFriendly ) )
		crateModelFriendly = FRIENDLY_CRATE_MODEL;
	if( !IsDefined( crateModelEnemy ) )
		crateModelEnemy = ENEMY_CRATE_MODEL;
	if( !IsDefined( crateModelDummy ) )
		crateModelDummy = DUMMY_CRATE_MODEL;
	
	level.crateTypes[ dropType ][ crateType ] = SpawnStruct();
	level.crateTypes[ dropType ][ crateType ].dropType = dropType;
	level.crateTypes[ dropType ][ crateType ].type = crateType;
	level.crateTypes[ dropType ][ crateType ].raw_weight = crateWeight;
	level.crateTypes[ dropType ][ crateType ].weight = crateWeight;
	level.crateTypes[ dropType ][ crateType ].func = crateFunc;
	level.crateTypes[ dropType ][ crateType ].model_name_friendly = crateModelFriendly;
	level.crateTypes[ dropType ][ crateType ].model_name_enemy = crateModelEnemy;
	level.crateTypes[ dropType ][ crateType ].model_name_dummy = crateModelDummy;

	if( IsDefined( hintString ) )
		game[ "strings" ][ crateType + "_hint" ] = hintString;
	
	if( IsDefined( optionalHint ) )
		game[ "strings" ][ crateType + "_optional_hint" ] = optionalHint;
}


getRandomCrateType( dropType )
{
	value = RandomInt( level.crateMaxVal[ dropType ] );
	
	selectedCrateType = undefined;
	foreach( crateType in level.crateTypes[ dropType ] )
	{
		type = crateType.type;
		if( !level.crateTypes[ dropType ][ type ].weight )
			continue;

		selectedCrateType = type;

		if( level.crateTypes[ dropType ][ type ].weight > value )
		{
			break;
		}
	}
	
	return( selectedCrateType );
}


getCrateTypeForDropType( dropType )
{
	switch	( dropType )
	{
		case "airdrop_sentry_minigun":
			return "sentry";
		case "airdrop_predator_missile":
			return "predator_missile";
		case "airdrop_juggernaut":
			return "airdrop_juggernaut";
		case "airdrop_juggernaut_def":
			return "airdrop_juggernaut_def";
		case "airdrop_juggernaut_gl":
			return "airdrop_juggernaut_gl";
		case "airdrop_juggernaut_recon":
			return "airdrop_juggernaut_recon";
		case "airdrop_juggernaut_maniac":
			return "airdrop_juggernaut_maniac";
		case "airdrop_remote_tank":
			return "remote_tank";
		case "airdrop_lase":
			return "lasedStrike";
		case "airdrop_assault":
		case "airdrop_support":
		case "airdrop_escort":
		case "airdrop_mega":
		case "airdrop_grnd":
		case "airdrop_grnd_mega":
		case "airdrop_sotf":
		default:
			if( IsDefined(level.getRandomCrateTypeForGameMode) )
				return [[level.getRandomCrateTypeForGameMode]]( dropType );
					
			return getRandomCrateType( dropType );
	}
}



/**********************************************************
*		 Usage functions
***********************************************************/

tryUseAirdrop( lifeId, streakName )
{
	dropType = streakName;
	result = undefined;
	
	if ( !IsDefined( dropType ) )
		dropType = "airdrop_assault";

	numIncomingVehicles = 1;
	if( ( level.littleBirds.size >= 4 || level.fauxVehicleCount >= 4 ) && dropType != "airdrop_mega" && !isSubStr( toLower( dropType ), "juggernaut" ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	} 
	else if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount + numIncomingVehicles >= maxVehiclesAllowed() )
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}		
	else if( dropType == "airdrop_lase" && IsDefined( level.lasedStrikeCrateActive ) && level.lasedStrikeCrateActive )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	} 
	
	if ( dropType != "airdrop_mega" && !isSubStr( toLower( dropType ), "juggernaut" ) )
	{
		self thread watchDisconnect();
	}
	
	// increment the faux vehicle count before we spawn the vehicle so no other vehicles try to spawn
	if( !IsSubStr( dropType, "juggernaut" ) )
		incrementFauxVehicleCount();

	result = self beginAirdropViaMarker( lifeId, dropType );
	
	if ( (!IsDefined( result ) || !result) )
	{
		self notify( "markerDetermined" );

		// decrement the faux vehicle count since this failed to spawn
		decrementFauxVehicleCount();

		return false;
	}
	
	if ( dropType == "airdrop_mega" )
		thread teamPlayerCardSplash( "used_airdrop_mega", self );
	
	self notify( "markerDetermined" );
	
	self maps\mp\_matchdata::logKillstreakEvent( dropType, self.origin );	
	
	return true;
}

watchDisconnect()
{
	self endon( "markerDetermined" );
	
	self waittill( "disconnect" );
	return;
}


/**********************************************************
*		 Marker functions
***********************************************************/

beginAirdropViaMarker( lifeId, dropType )
{	
	self notify( "beginAirdropViaMarker" );
	self endon( "beginAirdropViaMarker" );

	self endon( "disconnect" );
	level endon( "game_ended" );

	// reworked this to thread all of the functions at once and then watch for what returns
	// this fixes an infinite care package bug where you can kill the player as they throw it and they'll respawn with another one
	self.threwAirDropMarker = undefined;
	self.threwAirDropMarkerIndex = undefined;
	self thread watchAirDropWeaponChange( lifeId, dropType );
	self thread watchAirDropMarkerUsage( lifeId, dropType );
	self thread watchAirDropMarker( lifeId, dropType );

	result = self waittill_any_return( "notAirDropWeapon", "markerDetermined" );
	if( IsDefined( result ) && result == "markerDetermined" )
		return true;
	// result comes back as undefined if the player is killed while throwing, so we need to check to see if they threw the marker before dying
	else if( !IsDefined( result ) && IsDefined( self.threwAirDropMarker ) )
		return true;

	return false;
}

watchAirDropWeaponChange( lifeId, dropType )
{
	level endon( "game_ended" );
	
	self notify( "watchAirDropWeaponChange" );
	self endon( "watchAirDropWeaponChange" );
	
	self endon( "disconnect" );
	self endon( "markerDetermined" );

	while( self isChangingWeapon() )
		wait ( 0.05 );	

	currentWeapon = self getCurrentWeapon();

	if ( maps\mp\killstreaks\_killstreaks::isAirdropMarker( currentWeapon ) )
		airdropMarkerWeapon = currentWeapon;
	else
		airdropMarkerWeapon = undefined;

	while( maps\mp\killstreaks\_killstreaks::isAirdropMarker( currentWeapon ) /*|| currentWeapon == "none"*/ )
	{
		self waittill( "weapon_switch_started", currentWeapon );

		if ( maps\mp\killstreaks\_killstreaks::isAirdropMarker( currentWeapon ) )
			airdropMarkerWeapon = currentWeapon;
	}

	if( IsDefined( self.threwAirDropMarker ) )
	{
		// need to take the killstreak weapon here because the weapon_change happens before it can be taken in _killstreaks::waitTakeKillstreakWeapon()
		killstreakWeapon = getKillstreakWeapon( self.pers["killstreaks"][self.threwAirDropMarkerIndex].streakName );
		self TakeWeapon( killstreakWeapon );

		self notify( "markerDetermined" );
	}
	else
		self notify( "notAirDropWeapon" );
}

watchAirDropMarkerUsage( lifeId, dropType )
{
	level endon( "game_ended" );
	
	self notify( "watchAirDropMarkerUsage" );
	self endon( "watchAirDropMarkerUsage" );

	self endon( "disconnect" );
	self endon( "markerDetermined" );
	
	while( true )
	{
		self waittill( "grenade_pullback", weaponName );

		// could've thrown a grenade while holding the airdrop weapon
		if( !maps\mp\killstreaks\_killstreaks::isAirdropMarker( weaponName ) )
			continue;

		self _disableUsability();

		self beginAirDropMarkerTracking();
	}
}

watchAirDropMarker( lifeId, dropType )
{
	level endon( "game_ended" );
	
	self notify( "watchAirDropMarker" );
	self endon( "watchAirDropMarker" );

	self endon( "disconnect" );
	self endon( "markerDetermined" );

	while( true )
	{
		self waittill( "grenade_fire", airDropWeapon, weapname );
		
		if ( !maps\mp\killstreaks\_killstreaks::isAirdropMarker( weapname ) )
			continue;
		
		self.threwAirDropMarker = true;
		self.threwAirDropMarkerIndex = self.killstreakIndexWeapon;
		airDropWeapon thread airdropDetonateOnStuck();
			
		airDropWeapon.owner = self;
		airDropWeapon.weaponName = weapname;
		
		airDropWeapon thread airDropMarkerActivate( dropType );		
	}
}

beginAirDropMarkerTracking()
{
	level endon( "game_ended" );
	
	self notify( "beginAirDropMarkerTracking" );
	self endon( "beginAirDropMarkerTracking" );

	self endon( "death" );
	self endon( "disconnect" );

	self waittill_any( "grenade_fire", "weapon_change" );
	self _enableUsability();
}

airDropMarkerActivate( dropType, lifeId )
{	
	level endon( "game_ended" );
	
	self notify( "airDropMarkerActivate" );
	self endon( "airDropMarkerActivate" );

	self waittill( "explode", position );

	owner = self.owner;

//	// TODO: DEV ONLY DELETE
//	ent = Spawn( "script_model", position + ( 0, 0, 20 ) );
//	ent SetModel( "mp_juggernaut_carepackage" );
//	ent ScriptModelPlayAnim( "juggernaut_carepackage" );

	if ( !IsDefined( owner ) )
		return;
	
	if ( owner isKillStreakDenied() )
		return;
	
	if( IsSubStr( toLower( dropType ), "escort_airdrop" ) && IsDefined( level.chopper ) )
		return;

	//// play an additional smoke fx that is longer than the normal for the escort airdrop
	//if( IsSubStr( toLower( dropType ), "escort_airdrop" ) && IsDefined( level.chopper_fx["smoke"]["signal_smoke_30sec"] ) )
	//{
	//	PlayFX( level.chopper_fx["smoke"]["signal_smoke_30sec"], position, ( 0, 0, -1 ) );
	//}

	wait 0.05;
	
	if ( IsSubStr( toLower( dropType ), "juggernaut" ) )
		level doC130FlyBy( owner, position, randomFloat( 360 ), dropType );
	else if ( IsSubStr( toLower( dropType ), "escort_airdrop" ) )
		owner maps\mp\killstreaks\_escortairdrop::finishSupportEscortUsage( lifeId, position, randomFloat( 360 ), "escort_airdrop" );
	else
		level doFlyBy( owner, position, randomFloat( 360 ), dropType );
}

/**********************************************************
*		 crate functions
***********************************************************/
initAirDropCrate()
{
	self.inUse = false;
	self hide();

	if ( IsDefined( self.target ) )
	{
		self.collision = getEnt( self.target, "targetname" );
		self.collision notSolid();
	}
	else
	{
		self.collision = undefined;
	}
}


deleteOnOwnerDeath( owner )
{
	wait ( 0.25 );
	self linkTo( owner, "tag_origin", (0,0,0), (0,0,0) );

	owner waittill ( "death" );
	
	self delete();
}


crateTeamModelUpdater() // self == crate team model (the logo)
{
	self endon ( "death" );

	self hide();
	foreach ( player in level.players )
	{
		if ( player.team != "spectator" )
			self ShowToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );
		
		self hide();
		foreach ( player in level.players )
		{
			if ( player.team != "spectator" )
				self ShowToPlayer( player );
		}
	}	
}


crateModelTeamUpdater( showForTeam ) // self == crate model (friendly or enemy)
{
	self endon ( "death" );

	self hide();

	foreach ( player in level.players )
	{
		// Freeroam spectator
		if ( player.team == "spectator" )
		{
			if ( showForTeam == "allies" )
				self ShowToPlayer( player );
		}
		// Spectating player or being part of the team
		else if( player.team == showForTeam )
			self ShowToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );
		
		self hide();
		foreach ( player in level.players )
		{
			// Freeroam spectator
			if ( player.team == "spectator" )
			{
				if ( showForTeam == "allies" )
					self ShowToPlayer( player );
			}
			// Spectating player or being part of the team
			else if( player.team == showForTeam )
				self ShowToPlayer( player );
		}
	}	
}

crateModelEnemyTeamsUpdater( ownerTeam ) // self == crate model (enemyTeams only)
{
	self endon ( "death" );

	self hide();

	foreach ( player in level.players )
	{
		if( player.team != ownerTeam )
			self ShowToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );
		
		self hide();
		foreach ( player in level.players )
		{
			if ( player.team != ownerTeam )
				self ShowToPlayer( player );
		}
	}	
}

// for FFA
crateModelPlayerUpdater( owner, friendly ) // self == crate model (friendly or enemy)
{
	self endon ( "death" );

	self hide();

	foreach ( player in level.players )
	{
		if( friendly && IsDefined( owner ) && player != owner )
			continue;
		if( !friendly && IsDefined( owner ) && player == owner )
			continue;

		self ShowToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );

		self hide();
		foreach ( player in level.players )
		{
			if( friendly && IsDefined( owner ) && player != owner )
				continue;
			if( !friendly && IsDefined( owner ) && player == owner )
				continue;

			self ShowToPlayer( player );
		}
	}	
}

crateUseTeamUpdater( team )
{
	self endon ( "death" );

	for ( ;; )
	{
		setUsableByTeam( team );

		level waittill ( "joined_team" );
	}	
}

crateUseTeamUpdater_multiTeams( team )
{
	self endon ( "death" );

	for ( ;; )
	{
		setUsableByOtherTeams( team );

		level waittill ( "joined_team" );
		
	}	
}

crateUseJuggernautUpdater()
{
	if ( !isSubStr( self.crateType, "juggernaut" ) )
		return;
	
	self endon( "death" );
	level endon( "game_ended" );
	
	for ( ;; )
	{
		level waittill ( "juggernaut_equipped", player );
		
		self disablePlayerUse( player );
		self thread crateUsePostJuggernautUpdater( player );
	}	
}

crateUsePostJuggernautUpdater( player )
{
	self endon( "death" );
	level endon( "game_ended" );
	player endon( "disconnect" );
	
	player waittill( "death" );
	self enablePlayerUse( player );	
}

createAirDropCrate( owner, dropType, crateType, startPos, dropPoint, crateColor )
{
	dropCrate = Spawn( "script_model", startPos );
	
	dropCrate.curProgress = 0;
	dropCrate.useTime = 0;
	dropCrate.useRate = 0;
	dropCrate.team = self.team;
	dropCrate.destination = dropPoint;
	dropCrate.id = "care_package";
	
	if ( IsDefined( owner ) )
		dropCrate.owner = owner;
	else
		dropCrate.owner = undefined;
	
	dropCrate.crateType = crateType;
	dropCrate.dropType = dropType;
	dropCrate.targetname = "care_package";
	
	dummy_model = DUMMY_CRATE_MODEL;
	if ( isDefined ( level.custom_dummy_crate_model ))
	    dummy_model = level.custom_dummy_crate_model;
	
	dropCrate SetModel( dummy_model );
	
	if ( crateType == "airdrop_jackpot" )
	{
		dropCrate.friendlyModel = Spawn( "script_model", startPos );
		dropCrate.friendlyModel SetModel( level.crateTypes[ dropType ][ crateType ].model_name_friendly );
		dropCrate.friendlyModel thread deleteOnOwnerDeath( dropCrate );
	}
	else
	{
		dropCrate.friendlyModel = Spawn( "script_model", startPos );
		dropCrate.friendlyModel SetModel( level.crateTypes[ dropType ][ crateType ].model_name_friendly );
		
		if( IsDefined(level.highLightAirDrop) && level.highLightAirDrop )
		{
			if( !IsDefined(crateColor) )
				crateColor = 2;
			
			dropCrate.friendlyModel HudOutlineEnable( crateColor, false );
			dropCrate.outlineColor = crateColor;
		}

		dropCrate.enemyModel = Spawn( "script_model", startPos );
		dropCrate.enemyModel SetModel( level.crateTypes[ dropType ][ crateType ].model_name_enemy );
	
		dropCrate.friendlyModel SetEntityOwner( dropCrate );
		dropCrate.enemyModel SetEntityOwner( dropCrate );
	
		dropCrate.friendlyModel thread deleteOnOwnerDeath( dropCrate );
		if( level.teambased )
			dropCrate.friendlyModel thread crateModelTeamUpdater( dropCrate.team );
		else
			dropCrate.friendlyModel thread crateModelPlayerUpdater( owner, true );
	
		dropCrate.enemyModel thread deleteOnOwnerDeath( dropCrate );
		if( level.multiTeambased )
			dropCrate.enemyModel thread crateModelEnemyTeamsUpdater( dropCrate.team );
		else if( level.teambased )
			dropCrate.enemyModel thread crateModelTeamUpdater( level.otherTeam[dropCrate.team] );
		else
			dropCrate.enemyModel thread crateModelPlayerUpdater( owner, false );
	}

	dropCrate.inUse = false;
	
	dropCrate CloneBrushmodelToScriptmodel( level.airDropCrateCollision );
	dropCrate thread entity_path_disconnect_thread( 1.0 );
	
	dropCrate.killCamEnt = Spawn( "script_model", dropCrate.origin + CRATE_KILLCAM_OFFSET, 0, true );
	dropCrate.killCamEnt SetScriptMoverKillCam( "explosive" );
	dropCrate.killCamEnt LinkTo( dropCrate );

	level.numDropCrates++;
	dropCrate thread dropCrateExistence(dropPoint);
	level notify("createAirDropCrate", dropCrate);

	return dropCrate;
}

dropCrateExistence(dropPoint)
{
	level endon( "game_ended" );
	
	self waittill( "death" );
	
	// SOTF - Needed for clearing the used position for the killed crate
	if(IsDefined(level.crateKill))
		[[level.crateKill]](dropPoint);
			
	level.numDropCrates--;
}

crateSetupForUse( hintString, icon )
{	
	self setCursorHint( "HINT_NOICON" );
	self setHintString( hintString );
	self makeUsable();

	friendlyShader 		= "compass_objpoint_ammo_friendly";
	enemyShader 		= "compass_objpoint_ammo_enemy";
	
	if( IsDefined(level.objVisAll) )
		enemyShader 	= "compass_objpoint_ammo_friendly";
	
	if( !IsDefined(self.objIdFriendly) )
		self.objIdFriendly = createObjective( friendlyShader, self.team, true );
	
	if( !IsDefined(self.objIdEnemy) )
		self.objIdEnemy = createObjective( enemyShader, level.otherTeam[ self.team ], false );
	
	self thread crateUseTeamUpdater();
	self thread crateUseJuggernautUpdater();
	
	if( isSubStr( self.crateType, "juggernaut" ) )
	{
		foreach ( player in level.players )
			if ( player isJuggernaut() )
				self thread crateUsePostJuggernautUpdater( player );
	}		

	headIcon = undefined;
	if( level.teamBased )
		headIcon = self maps\mp\_entityheadIcons::setHeadIcon( self.team, icon, (0,0,24), 14, 14, false, undefined, undefined, undefined, undefined, false );
	else if ( IsDefined( self.owner ) )
		headIcon = self maps\mp\_entityheadIcons::setHeadIcon( self.owner, icon, (0,0,24), 14, 14, false, undefined, undefined, undefined, undefined, false );
	if ( IsDefined( headIcon ) )
		headIcon.showInKillcam = false;

	// make sure the head icon for crates are visible to everyone
	if( IsDefined(level.iconVisAll) )
		[[level.iconVisAll]](self, icon);
	else
	{
		// MLG: make sure spectators can see this crate headicon as well
		foreach ( player in level.players )
		{
			if ( player.team == "spectator" )
				headIcon = self maps\mp\_entityheadIcons::setHeadIcon( player, icon, (0,0,24), 14, 14, false, undefined, undefined, undefined, undefined, false );
		}				
	}
}

createObjective( shaderName, team, friendly )
{
	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
	objective_add( curObjID, "invisible", (0,0,0) );
	if ( !IsDefined( self GetLinkedParent() ) )
		Objective_Position( curObjID, self.origin );
	else
		Objective_OnEntity( curObjID, self );
	objective_state( curObjID, "active" );

	objective_icon( curObjID, shaderName );

	if( !level.teamBased && IsDefined( self.owner ) )
		if( friendly )
			Objective_PlayerTeam( curObjId, self.owner GetEntityNumber() );
		else
			Objective_PlayerEnemyTeam( curObjId, self.owner GetEntityNumber() );
	else
		Objective_Team( curObjID, team );

	// SOTF - Make this objective visible to all
	if ( IsDefined( level.objVisAll ) )
		[[ level.objVisAll ]]( curObjID );	

	return curObjID;
}


setUsableByTeam( team )
{
	foreach ( player in level.players )
	{
		if ( isSubStr( self.crateType, "juggernaut" ) && player isJuggernaut() )
		{
			self DisablePlayerUse( player );
		}
		else if ( isSubStr( self.crateType, "lased" ) && IsDefined(player.hasSoflam) && player.hasSoflam )
		{
			self DisablePlayerUse( player );
		}
		else if ( !IsDefined( team ) || team == player.team )
			self EnablePlayerUse( player );
		else
			self DisablePlayerUse( player );
	}	
}

//adding reverse logic version for when there are more than two teams
setUsableByOtherTeams( team )
{
	foreach ( player in level.players )
	{
		if ( isSubStr( self.crateType, "juggernaut" ) && player isJuggernaut() )
		{
			self DisablePlayerUse( player );
		}
		else if ( !IsDefined( team ) || team != player.team )
			self EnablePlayerUse( player );
		else
			self DisablePlayerUse( player );
	}	
}



dropTheCrate( dropPoint, dropType, lbHeight, dropImmediately, crateOverride, startPos, dropImpulse, previousCrateTypes, tagName )
{
	dropCrate = [];
	self.owner endon ( "disconnect" );
	
	if ( !IsDefined( crateOverride ) )
	{
		//	verify emergency airdrops don't drop dupes
		if ( IsDefined( previousCrateTypes ) )
		{
			foundDupe = undefined;
			crateType = undefined;
			for ( i=0; i<100; i++ )
			{
				crateType = getCrateTypeForDropType( dropType );
				foundDupe = false;
				for ( j=0; j<previousCrateTypes.size; j++ )
				{
					if ( crateType == previousCrateTypes[j] )
					{
						foundDupe = true;
						break;
					}
				}
				if ( foundDupe == false )
					break;
			}
			//	if 100 attempts fail, just get whatever, we tried		
			if ( foundDupe == true )
			{
				crateType = getCrateTypeForDropType( dropType );
			}
		}
		else
			crateType = getCrateTypeForDropType( dropType );	
	}	
	else
		crateType = crateOverride;
		
	if ( !IsDefined( dropImpulse ) )
		dropImpulse = (RandomInt(50),RandomInt(50),RandomInt(50));
		
	dropCrate = createAirDropCrate( self.owner, dropType, crateType, startPos, dropPoint );
	
	switch( dropType )
	{
	case "airdrop_mega":
	case "nuke_drop":
	case "airdrop_juggernaut":
	case "airdrop_juggernaut_recon":
	case "airdrop_juggernaut_maniac":
		dropCrate LinkTo( self, "tag_ground" , (64,32,-128) , (0,0,0) );
		break;
	case "airdrop_escort":
	case "airdrop_osprey_gunner":
		dropCrate LinkTo( self, tagName, (0,0,0), (0,0,0) );
		break;
	default:
		dropCrate LinkTo( self, "tag_ground" , (32,0,5) , (0,0,0) );
		break;
	}

	dropCrate.angles = (0,0,0);
	dropCrate show();
	dropSpeed = self.veh_speed;
	
	// don't do a drop impulse if this is considered a juggernaut crate, this could happen for level killstreaks (predator, myers)
	if( IsSubStr( crateType, "juggernaut" ) )
		dropImpulse = (0,0,0);
		
	self thread waitForDropCrateMsg( dropCrate, dropImpulse, dropType, crateType );
	dropCrate.droppingToGround = true;
	
	return crateType;
}


killPlayerFromCrate_DoDamage( hitEnt )
{
	if( IsDefined(level.noAirDropKills) && level.noAirDropKills )
		return;
	
	hitEnt DoDamage( 1000, hitEnt.origin, self, self, "MOD_CRUSH" );
}


killPlayerFromCrate_FastVelocityPush()
{
	self endon( "death" );

	while( 1 )
	{
		self waittill( "player_pushed", hitEnt, platformMPH );
		if ( isPlayer( hitEnt ) || isAgent( hitEnt ) )
		{
			if ( platformMPH[2] < -20 )
			{
				self killPlayerFromCrate_DoDamage( hitEnt );
			}
		}
		wait 0.05;
	}
}

airdrop_override_death_moving_platform( data )
{
	// Put back in if ready to allow airdrop destroy.
	if ( IsDefined( data.lastTouchedPlatform.destroyAirdropOnCollision ) && data.lastTouchedPlatform.destroyAirdropOnCollision )
	{
		PlayFX( getfx( "airdrop_crate_destroy" ), self.origin );
		self deleteCrate();
	}
}

cleanup_crate_capture()
{
	children = self GetLinkedChildren( true );
	if ( !IsDefined( children ) )
	{
		return;
	}

	foreach ( player in children )
	{
		if( !IsPlayer( player ) )
			continue;

		if ( IsDefined( player.isCapturingCrate ) && player.isCapturingCrate )
		{
			parent = player GetLinkedParent();
			if ( IsDefined( parent ) )
			{
				player maps\mp\gametypes\_gameobjects::updateUIProgress( parent, false );
				player unlink();
			}

		    if ( isAlive( player ) )
				player _enableWeapon();

			player.isCapturingCrate = false;
		}
	}
}

airdrop_override_invalid_moving_platform( data )
{
	// Need to wait for parent to be gone.
	wait( 0.05 );

	self notify( "restarting_physics" );
	self cleanup_crate_capture();
	self PhysicsLaunchServer( (0,0,0), data.dropImpulse, data.airDrop_max_linear_velocity );		
	self thread physicsUpdater( data.dropType, data.crateType );
	self thread physicsWaiter( data.dropType, data.crateType, data.dropImpulse, data.airDrop_max_linear_velocity );
}

waitForDropCrateMsg( dropCrate, dropImpulse, dropType, crateType, optionalVelocity, dropImmediately )
{
	dropCrate endon("death");
	
	if( !IsDefined(dropImmediately) || !dropImmediately )
		self waittill ( "drop_crate" );

	airDrop_max_linear_velocity = 1200;
	
	/#
	airDrop_max_linear_velocity	= getdvarfloat( "scr_airDrop_max_linear_velocity", 	1200 );
	#/
	
	if( IsDefined(optionalVelocity) )
		airDrop_max_linear_velocity = optionalVelocity;
	
	dropCrate Unlink();
	dropCrate PhysicsLaunchServer( (0,0,0), dropImpulse, airDrop_max_linear_velocity );		
	dropCrate thread physicsUpdater( dropType, crateType );
	dropCrate thread physicsWaiter( dropType, crateType, dropImpulse, airDrop_max_linear_velocity );
	dropCrate thread killPlayerFromCrate_FastVelocityPush();
	dropCrate.unresolved_collision_func = ::killPlayerFromCrate_DoDamage;

	if( IsDefined( dropCrate.killCamEnt ) )
	{
		// Adding offset for Carestrike killcam to follow lobbed care packages
		if ( IsDefined( dropCrate.carestrike ) )
		{
			horizontal_offset = -2100;
		}
		else 
			horizontal_offset = 0;
		
		// calculate the time it takes to get from here to the ground
		dropCrate.killCamEnt Unlink();
		groundTrace = BulletTrace( dropCrate.origin, dropCrate.origin + ( 0, 0, -10000 ), false, dropCrate );
		travelDistance = Distance( dropCrate.origin, groundTrace[ "position" ] );
		//travelDistance *= 2;
		travelTime = travelDistance / GRAVITY_UNITS_PER_SECOND;
		//travleTime = sqrt( travelTime );
		dropCrate.killCamEnt MoveTo( groundTrace[ "position" ] + CRATE_KILLCAM_OFFSET + ( horizontal_offset, 0, 0 ), travelTime );
		//dropCrate.killCamEnt MoveGravity( ( 0, 0, -1 ), travelTime );
	}
}	

physicsUpdater( dropType, crateType )
{
	self endon( "restarting_physics" );
	self endon( "physics_finished" );

	// wait for airplane/helicopter to move out the way
	wait( 0.5 );

	while( true )
	{
		if ( !isDefined( self ) )
			return;
		
		// bullet cast down - don't use clipshot
		groundTrace = BulletTrace( self.origin, self.origin + ( 0, 0, -60 ), false, self, false, false, false, true );
		if ( groundTrace[ "fraction" ] < 1.0 )
		{
			airDrop_slowdown_max_linear_velocity	= 600;
			/#
			airDrop_slowdown_max_linear_velocity	= getdvarfloat( "scr_airDrop_slowdown_max_linear_velocity", 	600 );
			#/

			self PhysicsSetMaxLinVel( airDrop_slowdown_max_linear_velocity );
			self thread waitAndAnimate();
			return;	
		}

		// wait till next frame
		waitframe();
	}
}

waitAndAnimate() // self == care package
{
	self endon( "death" );
	
	wait( 0.035 );

	PlayFX( level._effect[ "airdrop_dust_kickup" ], self.origin + ( 0, 0, 5 ), ( 0, 0, 1 ) );
	self.friendlyModel ScriptModelPlayAnim( "juggernaut_carepackage" );
	self.enemyModel ScriptModelPlayAnim( "juggernaut_carepackage" );
}

physicsWaiter( dropType, crateType, dropImpulse, airDrop_max_linear_velocity )
{
	self endon( "restarting_physics" );
	self waittill( "physics_finished" );

//	ent = Spawn( "script_model", self.origin );
//	ent.angles = self.angles;
//	ent SetModel( "mp_juggernaut_carepackage" );
//	self Hide();
//	ent ScriptModelPlayAnim( "juggernaut_carepackage" );

	self.droppingToGround = false;
	self thread [[ level.crateTypes[ dropType ][ crateType ].func ]]( dropType );
	level thread dropTimeOut( self, self.owner, crateType );

	// Handle moving platform. 
	data = SpawnStruct();
	data.endonString = "restarting_physics";
	data.deathOverrideCallback = ::airdrop_override_death_moving_platform;
	data.invalidParentOverrideCallback = ::airdrop_override_invalid_moving_platform;
	data.dropType = dropType;
	data.crateType = crateType;
	data.dropImpulse = dropImpulse;
	data.airDrop_max_linear_velocity = airDrop_max_linear_velocity;
	self thread maps\mp\_movers::handle_moving_platforms( data );
			
	if ( self.friendlyModel touchingBadTrigger() )
	{
		self deleteCrate();
		return;
	}
	
	if( IsDefined(self.owner) && ( abs(self.origin[2] - self.owner.origin[2]) > 3000 ) )
	{
		self deleteCrate();	
	}
}

//deletes if crate wasnt used after 90 seconds
dropTimeOut( dropCrate, owner, crateType )
{
	if( IsDefined(level.noCrateTimeOut) && (level.noCrateTimeOut) )
		return;
	
	level endon ( "game_ended" );
	dropCrate endon( "death" );
	
	if ( dropCrate.dropType == "nuke_drop" )
		return;	
	
	timeOut = 90.0;
	if ( crateType == "supply" )
		timeOut = 20.0;
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( timeOut );
	
	while ( dropCrate.curProgress != 0 )
		wait 1;
	
	dropCrate deleteCrate();
}


getPathStart( coord, yaw )
{
	pathRandomness = 100;
	lbHalfDistance = 15000;

	direction = (0,yaw,0);

	startPoint = coord + ( AnglesToForward( direction ) * ( -1 * lbHalfDistance ) );
	startPoint += ( (randomfloat(2) - 1)*pathRandomness, (randomfloat(2) - 1)*pathRandomness, 0 );
	
	return startPoint;
}


getPathEnd( coord, yaw )
{
	pathRandomness = 150;
	lbHalfDistance = 15000;

	direction = (0,yaw,0);

	endPoint = coord + ( AnglesToForward( direction + ( 0, 90, 0 ) ) * lbHalfDistance );
	endPoint += ( (randomfloat(2) - 1)*pathRandomness  , (randomfloat(2) - 1)*pathRandomness  , 0 );
	
	return endPoint;
}


getFlyHeightOffset( dropSite )
{
	lbFlyHeight = 850;
	
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	
	if ( !IsDefined( heightEnt ) )//old system 
	{
		/#
		println( "NO DEFINED AIRSTRIKE HEIGHT SCRIPT_ORIGIN IN LEVEL" );
		#/
		if ( IsDefined( level.airstrikeHeightScale ) )
		{	
			if ( level.airstrikeHeightScale > 2 )
			{
				lbFlyHeight = 1500;
				return( lbFlyHeight * (level.airStrikeHeightScale ) );
			}
			
			return( lbFlyHeight * level.airStrikeHeightScale + 256 + dropSite[2] );
		}
		else
			return ( lbFlyHeight + dropsite[2] );	
	}
	else
	{
		return heightEnt.origin[2];
	}
	
}


/**********************************************************
*		 Helicopter Functions
***********************************************************/

doFlyBy( owner, dropSite, dropYaw, dropType, heightAdjustment, crateOverride )
{	
	if ( !IsDefined( owner ) ) 
		return;
		
	// safety check against script directly calling doFlyBy without propperly checking vehicle counts
	if( currentActiveVehicleCount() >= maxVehiclesAllowed() )
		return;
		
	flyHeight = self getFlyHeightOffset( dropSite );
	if ( IsDefined( heightAdjustment ) )
		flyHeight += heightAdjustment;	
	foreach( littlebird in level.littlebirds )
	{
		if ( IsDefined( littlebird.dropType ) )
			flyHeight += 128;
	}

	pathGoal = dropSite * (1,1,0) +  (0,0,flyHeight);	
	pathStart = getPathStart( pathGoal, dropYaw );
	pathEnd = getPathEnd( pathGoal, dropYaw );		
	
	pathGoal = pathGoal + ( AnglesToForward( ( 0, dropYaw, 0 ) ) * -50 );

	chopper = heliSetup( owner, pathStart, pathGoal );
	
	if( IsDefined(level.highLightAirDrop) && level.highLightAirDrop )
		chopper HudOutlineEnable( 3, false );
	
	assert ( IsDefined( chopper ) );
	
	chopper endon( "death" );	

/#
	if( GetDvar( "scr_crateOverride" ) != "" )
	{
		crateOverride = GetDvar( "scr_crateOverride" );
		dropType = GetDvar( "scr_crateTypeOverride" );
	}
#/

	chopper.dropType = dropType;
	
	chopper setVehGoalPos( pathGoal, 1 );
		
	chopper thread dropTheCrate( dropSite, dropType, flyHeight, false, crateOverride, pathStart );
	
	wait ( 2 );
	
	chopper Vehicle_SetSpeed( 75, 40 );
	chopper SetYawSpeed( 180, 180, 180, .3 );
	
	chopper waittill ( "goal" );
	wait( .10 );
	chopper notify( "drop_crate" );
	chopper setvehgoalpos( pathEnd, 1 );
	chopper Vehicle_SetSpeed( 300, 75 );
	chopper.leaving = true;
	chopper waittill ( "goal" );
	chopper notify( "leaving" );
	chopper notify( "delete" );

	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();

	chopper delete();
}

doMegaFlyBy( owner, dropSite, dropYaw, dropType )
{
	level thread doFlyBy( owner, dropSite, dropYaw, dropType, 0 );
	wait( RandomIntRange( 1,2 ) );
	level thread doFlyBy( owner, dropSite + (128,128,0), dropYaw, dropType, 128 );
	wait( RandomIntRange( 1,2 ) );
	level thread doFlyBy( owner, dropSite + (172,256,0), dropYaw, dropType, 256 );
	wait( RandomIntRange( 1,2 ) );
	level thread doFlyBy( owner, dropSite + (64,0,0), dropYaw, dropType, 0 );
}

doC130FlyBy( owner, dropSite, dropYaw, dropType )
{	
	planeHalfDistance = 18000;
	planeFlySpeed = 3000;
	yaw = VectorToYaw( dropsite - owner.origin );
	
	direction = ( 0, yaw, 0 );
	
	flyHeight = self getFlyHeightOffset( dropSite );
	
	pathStart = dropSite + ( AnglesToForward( direction ) * ( -1 * planeHalfDistance ) );
	pathStart = pathStart * ( 1, 1, 0 ) + ( 0, 0, flyHeight );

	pathEnd = dropSite + ( AnglesToForward( direction ) * planeHalfDistance );
	pathEnd = pathEnd * ( 1, 1, 0 ) + ( 0, 0, flyHeight );
	
	d = length( pathStart - pathEnd );
	flyTime = ( d / planeFlySpeed );
	
	c130 = c130Setup( owner, pathStart, pathEnd );
	c130.veh_speed = planeFlySpeed;
	c130.dropType = dropType;
 	c130 PlayLoopSound( "veh_ac130_dist_loop" );

	c130.angles = direction;
	forward = AnglesToForward( direction );
	c130 MoveTo( pathEnd, flyTime, 0, 0 ); 
	
	minDist = Distance2D( c130.origin, dropSite );
	boomPlayed = false;
	
	for(;;)
	{
		dist = Distance2D( c130.origin, dropSite );
		
		// handle missing our target
		if ( dist < minDist )
			minDist = dist;
		else if ( dist > minDist )
			break;
		
		if ( dist < 320 )
		{
			break;
		}
		else if ( dist < 768 )
		{
			earthquake( 0.15, 1.5, dropSite, 1500 );
			if ( !boomPlayed )
			{
				c130 playSound( "veh_ac130_sonic_boom" );
				//c130 thread stopLoopAfter( 0.5 );
				boomPlayed = true;
			}
		}	
		
		wait ( .05 );	
	}	
	wait( 0.05 );
	
	dropImpulse = (0,0,0);
	
	if ( !is_aliens() )
	{
		crateType[0] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart, dropImpulse );
	}
	wait ( 0.05 );
	c130 notify ( "drop_crate" );

	newPathEnd = dropSite + ( AnglesToForward( direction ) * (planeHalfDistance*1.5) );
	c130 MoveTo( newPathEnd, flyTime/2, 0, 0 ); 

	wait ( 6 );
	c130 delete();
}


doMegaC130FlyBy( owner, dropSite, dropYaw, dropType, forwardOffset )
{	
	planeHalfDistance = 24000;
	planeFlySpeed = 2000;
	yaw = VectorToYaw( dropsite - owner.origin );
	direction = ( 0, yaw, 0 );
	forward = AnglesToForward( direction );
	
	if ( IsDefined( forwardOffset ) )
		dropSite = dropSite + forward * forwardOffset;	
	
	flyHeight = self getFlyHeightOffset( dropSite );
	
	pathStart = dropSite + ( AnglesToForward( direction ) * ( -1 * planeHalfDistance ) );
	pathStart = pathStart * ( 1, 1, 0 ) + ( 0, 0, flyHeight );

	pathEnd = dropSite + ( AnglesToForward( direction ) * planeHalfDistance );
	pathEnd = pathEnd * ( 1, 1, 0 ) + ( 0, 0, flyHeight );
	
	d = length( pathStart - pathEnd );
	flyTime = ( d / planeFlySpeed );
	
	c130 = c130Setup( owner, pathStart, pathEnd );
	c130.veh_speed = planeFlySpeed;
	c130.dropType = dropType;
 	c130 PlayLoopSound( "veh_ac130_dist_loop" );

	c130.angles = direction;
	forward = AnglesToForward( direction );
	c130 MoveTo( pathEnd, flyTime, 0, 0 ); 
	
	minDist = Distance2D( c130.origin, dropSite );
	boomPlayed = false;
	
	for(;;)
	{
		dist = Distance2D( c130.origin, dropSite );
		
		// handle missing our target
		if ( dist < minDist )
			minDist = dist;
		else if ( dist > minDist )
			break;
		
		if ( dist < 256 )
		{
			break;
		}
		else if ( dist < 768 )
		{
			earthquake( 0.15, 1.5, dropSite, 1500 );
			if ( !boomPlayed )
			{
				c130 playSound( "veh_ac130_sonic_boom" );
				//c130 thread stopLoopAfter( 0.5 );
				boomPlayed = true;
			}
		}	
		
		wait ( .05 );	
	}	
	wait( 0.05 );
	
	crateType[0] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart );	
	wait ( 0.05 );
	c130 notify ( "drop_crate" );
	wait ( 0.05 );

	crateType[1] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart, undefined, crateType );
	wait ( 0.05 );
	c130 notify ( "drop_crate" );
	wait ( 0.05 );

	crateType[2] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart, undefined, crateType );
	wait ( 0.05 );
	c130 notify ( "drop_crate" );
	wait ( 0.05 );

	crateType[3] = c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, undefined, pathStart, undefined, crateType );	
	wait ( 0.05 );
	c130 notify ( "drop_crate" );

	wait ( 4 );
	c130 delete();
}


dropNuke( dropSite, owner, dropType )
{
	planeHalfDistance = 24000;
	planeFlySpeed = 2000;
	yaw = RandomInt( 360 );
	
	direction = ( 0, yaw, 0 );
	
	flyHeight = self getFlyHeightOffset( dropSite );
	
	pathStart = dropSite + ( AnglesToForward( direction ) * ( -1 * planeHalfDistance ) );
	pathStart = pathStart * ( 1, 1, 0 ) + ( 0, 0, flyHeight );

	pathEnd = dropSite + ( AnglesToForward( direction ) * planeHalfDistance );
	pathEnd = pathEnd * ( 1, 1, 0 ) + ( 0, 0, flyHeight );
	
	d = length( pathStart - pathEnd );
	flyTime = ( d / planeFlySpeed );
	
	c130 = c130Setup( owner, pathStart, pathEnd );
	c130.veh_speed = planeFlySpeed;
	c130.dropType = dropType;
 	c130 PlayLoopSound( "veh_ac130_dist_loop" );

	c130.angles = direction;
	forward = AnglesToForward( direction );
	c130 MoveTo( pathEnd, flyTime, 0, 0 ); 
	
	// TODO: fix this... it's bad.  if we miss our distance (which could happen if plane speed is changed in the future) we stick in this thread forever
	boomPlayed = false;
	minDist = Distance2D( c130.origin, dropSite );
	for(;;)
	{
		dist = Distance2D( c130.origin, dropSite );

		// handle missing our target
		if ( dist < minDist )
			minDist = dist;
		else if ( dist > minDist )
			break;
		
		if ( dist < 256 )
		{
			break;
		}
		else if ( dist < 768 )
		{
			earthquake( 0.15, 1.5, dropSite, 1500 );
			if ( !boomPlayed )
			{
				c130 playSound( "veh_ac130_sonic_boom" );
				//c130 thread stopLoopAfter( 0.5 );
				boomPlayed = true;
			}
		}	
		
		wait ( .05 );	
	}	
	
	c130 thread dropTheCrate( dropSite, dropType, flyHeight, false, "nuke", pathStart );
	wait ( 0.05 );
	c130 notify ( "drop_crate" );

	wait ( 4 );
	c130 delete();
}

stopLoopAfter( delay )
{
	self endon ( "death" );
	
	wait ( delay );
	self stoploopsound();
}


playloopOnEnt( alias )
{
	soundOrg = Spawn( "script_origin", ( 0, 0, 0 ) );
	soundOrg hide();
	soundOrg endon( "death" );
	thread delete_on_death( soundOrg );
	
	soundOrg.origin = self.origin;
	soundOrg.angles = self.angles;
	soundOrg linkto( self );
	
	soundOrg PlayLoopSound( alias );
	
	self waittill( "stop sound" + alias );
	soundOrg stoploopsound( alias );
	soundOrg delete();
}


// spawn C130 at a start node and monitors it
c130Setup( owner, pathStart, pathGoal )
{
	forward = vectorToAngles( pathGoal - pathStart );
	c130 = SpawnPlane( owner, "script_model", pathStart, "compass_objpoint_c130_friendly", "compass_objpoint_c130_enemy" );
	c130 SetModel( "vehicle_ac130_low_mp" );
	
	if ( !IsDefined( c130 ) )
		return;

	//chopper playLoopSound( "littlebird_move" );
	c130.owner = owner;
	c130.team = owner.team;
	level.c130 = c130;
	
	return c130;
}

// spawn helicopter at a start node and monitors it
heliSetup( owner, pathStart, pathGoal )
{
	
	forward = vectorToAngles( pathGoal - pathStart );
	
	vehicle = "littlebird_mp";
	
	// SOTF - Vehicle override so that compass marker always appears as friendly, no matter who the owner is
	if ( IsDefined( level.vehicleOverride ) )
		vehicle = level.vehicleOverride;	
	
	lb = SpawnHelicopter( owner, pathStart, forward, vehicle, level.littlebird_model );

	if ( !IsDefined( lb ) )
		return;

	lb maps\mp\killstreaks\_helicopter::addToLittleBirdList();
	lb thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();

	//lb playLoopSound( "littlebird_move" );

	lb.maxhealth = 500; // this is the health we'll check	
	lb.owner = owner;
	lb.team = owner.team;
	lb.isAirdrop = true;
	lb thread watchTimeOut();
	lb thread heli_existence();
	lb thread heliDestroyed();
	lb thread maps\mp\killstreaks\_helicopter::heli_damage_monitor( "airdrop" );
	lb SetMaxPitchRoll( 45, 85 );	
	lb Vehicle_SetSpeed( 250, 175 );
	lb.heliType = "airdrop";

	// hide the wings
	lb HidePart( "tag_wings" );
	
	return lb;
}

watchTimeOut()
{
	level endon( "game_ended" );
	self endon( "leaving" );	
	self endon( "helicopter_gone" );
	self endon( "death" );
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 25.0 );
	
	self notify( "death" );
}

heli_existence()
{
	self waittill_any( "crashing", "leaving" );
	
	self notify( "helicopter_gone" );
}

heliDestroyed()
{
	self endon( "leaving" );
	self endon( "helicopter_gone" );
	
	self waittill( "death" );
	
	if (! IsDefined(self) )
		return;
		
	self Vehicle_SetSpeed( 25, 5 );
	self thread lbSpin( RandomIntRange(180, 220) );
	
	wait( RandomFloatRange( .5, 1.5 ) );
	
	self notify( "drop_crate" );
	
	lbExplode();
}

// crash explosion
lbExplode()
{
	forward = ( self.origin + ( 0, 0, 1 ) ) - self.origin;
	playfx ( level.chopper_fx["explode"]["death"]["cobra"], self.origin, forward );
	
	// play heli explosion sound
	self playSound( "exp_helicopter_fuel" );
	self notify ( "explode" );

	// decrement the faux vehicle count right before it is deleted this way we know for sure it is gone
	decrementFauxVehicleCount();

	self delete();
}


lbSpin( speed )
{
	self endon( "explode" );
	
	// tail explosion that caused the spinning
	playfxontag( level.chopper_fx["explode"]["medium"], self, "tail_rotor_jnt" );
	playfxontag( level.chopper_fx["fire"]["trail"]["medium"], self, "tail_rotor_jnt" );
	
	self setyawspeed( speed, speed, speed );
	while ( isdefined( self ) )
	{
		self settargetyaw( self.angles[1]+(speed*0.9) );
		wait ( 1 );
	}
}

/**********************************************************
*		 crate trigger functions
***********************************************************/

nukeCaptureThink()
{
	while ( IsDefined( self ) )
	{
		self waittill ( "trigger", player );

		if ( !player isOnGround() )
			continue;
			
		if ( !useHoldThink( player ) )
			continue;
			
		self notify ( "captured", player );
	}
}

crateOtherCaptureThink( useText )
{
	self endon( "restarting_physics" );
	
	while ( IsDefined( self ) )
	{
		self waittill ( "trigger", player );

		if ( IsDefined( self.owner ) && player == self.owner )
			continue;
			
		if ( !self validateOpenConditions( player ) )
			continue;			
		
		if ( IsDefined( level.overrideCrateUseTime ) )
			useTime = level.overrideCrateUseTime;
		else
			useTime = undefined;

		player.isCapturingCrate = true;
		useEnt = self createUseEnt();
		result = useEnt useHoldThink( player, useTime, useText );
		
		if ( IsDefined( useEnt ) )
			useEnt delete();
		
		if ( !IsDefined( player ) )
			return;
		
		if ( !result )
		{
			player.isCapturingCrate = false;
			continue;
		}
			
		player.isCapturingCrate = false;
		self notify ( "captured", player );
	}
}

crateOwnerCaptureThink( useText )
{
	self endon( "restarting_physics" );
	
	while ( IsDefined( self ) )
	{
		self waittill ( "trigger", player );

		if ( IsDefined( self.owner ) && player != self.owner )
			continue;
				
		if ( !self validateOpenConditions( player ) )
			continue;

		player.isCapturingCrate = true;
		if ( !useHoldThink( player, CONST_CRATE_OWNER_USE_TIME, useText ) )
		{
			player.isCapturingCrate = false;
			continue;
		}
		
		player.isCapturingCrate = false;
		self notify ( "captured", player );
	}
}

crateAllCaptureThink( useText )
{
	// self == crate 
	self endon( "restarting_physics" );
	
	// This should be used in the case you want the crate to act as a neutral object,
	// where everyone can access it with the same use time
	self.crateUseEnts = [];
	
	while ( IsDefined( self ) )
	{
		self waittill ( "trigger", player );

		if ( !self validateOpenConditions( player ) )
			continue;
		
		if ( IsDefined( level.overrideCrateUseTime ) )
			useTime = level.overrideCrateUseTime;
		else
			useTime = undefined;
		
		self childthread crateAllUseLogic( player, useTime, useText );
	}
}

crateAllUseLogic( player, useTime, useText ) 
{
	player.isCapturingCrate = true;
	
	AssertEx( !IsDefined( self.crateUseEnts[ player.name ] ), "Crate already has useEnt for " + player.name );
	
	// Store the useEnts per crate, so we can check who is still using it later
	self.crateUseEnts[ player.name ] = self createUseEnt();
	
	// Store to remove the ent later
	useEntToRemove = self.crateUseEnts[ player.name ];
	
	// Wait until the player finishes using the crate 
	result = self.crateUseEnts[ player.name ] useHoldThink( player, useTime, useText, self );
	
	// No longer using the crate? Delete the ent
	if ( IsDefined( self.crateUseEnts ) && IsDefined( useEntToRemove ) )
	{
		self.crateUseEnts = array_remove_keep_index( self.crateUseEnts, useEntToRemove );	
		useEntToRemove delete();
	}
		
	if ( !IsDefined( player ) )
		return;
	
	player.isCapturingCrate = false;

	if ( result )
		self notify ( "captured", player );
}

updateCrateUseState()
{
	// self == crate
	self.inUse = false;
	
	// Check each existing useEnt linked to the crate, and see if they are in use
	foreach ( useEnt in self.crateUseEnts )
	{
		if ( useEnt.inUse )
		{
			self.inUse = true;
			break;
		}
	}
}

validateOpenConditions( opener )
{
	//if ( !opener isOnGround() )
		//return false;	
	
	// don't let a juggernaut pick up a juggernaut crate
	if ( ( self.crateType == "airdrop_juggernaut_recon" || self.crateType == "airdrop_juggernaut" || self.crateType == "airdrop_juggernaut_maniac" ) &&  opener isJuggernaut() )
		return false;
	
	//dont allow opening if the player is on a heli sniper
	if ( isDefined( opener.OnHeliSniper ) && opener.OnHeliSniper )
		return false;
	
	// don't let them open crates while using killstreaks, except being juggernaut
	currWeapon = opener GetCurrentWeapon();
	if( isKillstreakWeapon( currWeapon ) && !isJuggernautWeapon( currWeapon ) )
		return false;
	
	if( IsDefined( opener.changingWeapon ) && isKillstreakWeapon( opener.changingWeapon ) && !IsSubStr( opener.changingWeapon, "jugg_mp" ) )
		return false;

	return true;
}

killstreakCrateThink( dropType )
{
	self endon( "restarting_physics" );
	self endon ( "death" );
	
	if ( IsDefined( game["strings"][self.crateType + "_hint"] ) )
		crateHint = game["strings"][self.crateType + "_hint"];
	else 
		crateHint = &"PLATFORM_GET_KILLSTREAK";
	
	crateSetupForUse( crateHint, getKillstreakOverheadIcon( self.crateType ) );

	self thread crateOtherCaptureThink();
	self thread crateOwnerCaptureThink();

	for ( ;; )
	{
		self waittill ( "captured", player );
		
		if( IsPlayer( player ) )
		{
			player SetClientOmnvar( "ui_securing", 0 );
			player.ui_securing = undefined;	
		}
		
		if ( IsDefined( self.owner ) && player != self.owner )
		{
			if ( !level.teamBased || player.team != self.team )
			{
				switch( dropType )
				{
				case "airdrop_assault":
				case "airdrop_support":
				case "airdrop_escort":
				case "airdrop_osprey_gunner":
					player thread maps\mp\gametypes\_missions::genericChallenge( "hijacker_airdrop" );
					player thread hijackNotify( self, "airdrop" );
					break;
				case "airdrop_sentry_minigun":
					player thread maps\mp\gametypes\_missions::genericChallenge( "hijacker_airdrop" );
					player thread hijackNotify( self, "sentry" );
					break;
				case "airdrop_remote_tank":
					player thread maps\mp\gametypes\_missions::genericChallenge( "hijacker_airdrop" );
					player thread hijackNotify( self, "remote_tank" );
					break;
				case "airdrop_mega":
					player thread maps\mp\gametypes\_missions::genericChallenge( "hijacker_airdrop_mega" );
					player thread hijackNotify( self, "emergency_airdrop" );
					break;
				}
			}
			else
			{
				self.owner thread maps\mp\gametypes\_rank::giveRankXP( "killstreak_giveaway", Int(( maps\mp\killstreaks\_killstreaks::getStreakCost( self.crateType ) / 10 ) * 50) );
				//self.owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "giveaway_airdrop", player );
				self.owner thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "sharepackage", Int(( maps\mp\killstreaks\_killstreaks::getStreakCost( self.crateType ) / 10 ) * 50) );
			}
		}		
	
		player playLocalSound( "ammo_crate_use" );
		player thread maps\mp\killstreaks\_killstreaks::giveKillstreak( self.crateType, false, false, self.owner );

		player maps\mp\gametypes\_hud_message::killstreakSplashNotify( self.crateType, undefined );
		
		self deleteCrate();
	}
}

//NOT USED
lasedStrikeCrateThink( dropType )
{
	self endon( "restarting_physics" );
	self endon ( "death" );

	crateSetupForUse( game["strings"]["marker_hint"], getKillstreakOverheadIcon( self.crateType ) );

	level.lasedStrikeCrateActive = true;
	self thread crateOwnerCaptureThink();
	self thread crateOtherCaptureThink();

	numCount = 0;
	
	remote = self thread maps\mp\killstreaks\_lasedStrike::spawnRemote( self.owner );
	level.lasedStrikeDrone = remote;
	level.lasedStrikeActive = true;
	
	level.soflamCrate = self;
	
	for ( ;; )
	{
		self waittill ( "captured", player );

		if ( IsDefined( self.owner ) && player != self.owner )
		{
			if ( !level.teamBased || player.team != self.team )
			{
				self deleteCrate();
			}
		}
		
		//self DisablePlayerUse( player );
		self maps\mp\killstreaks\_airdrop::setUsableByTeam( self.team );
	
		player thread maps\mp\killstreaks\_lasedStrike::giveMarker();
		
		numCount++;
		
		if ( numCount >= 5 )
			self deleteCrate();
	}
}


nukeCrateThink( dropType )
{
	self endon( "restarting_physics" );
	self endon ( "death" );
	
	crateSetupForUse( &"PLATFORM_CALL_NUKE", getKillstreakOverheadIcon( self.crateType ) );

	self thread nukeCaptureThink();

	for ( ;; )
	{
		self waittill ( "captured", player );
		
		player thread [[ level.killstreakFuncs[ self.crateType ] ]]( level.gtnw );
		level notify( "nukeCaptured", player );
		
		if ( IsDefined( level.gtnw ) && level.gtnw )
			player.capturedNuke = 1;
		
		player playLocalSound( "ammo_crate_use" );
		self deleteCrate();
	}
}


juggernautCrateThink( dropType )
{
	self endon( "restarting_physics" );
	self endon ( "death" );

	crateSetupForUse( game["strings"][self.crateType + "_hint"], getKillstreakOverheadIcon( self.crateType ) );

	self thread crateOtherCaptureThink();
	self thread crateOwnerCaptureThink();

	for ( ;; )
	{
		self waittill ( "captured", player );
		
		if ( IsDefined( self.owner ) && player != self.owner )
		{
			if ( !level.teamBased || player.team != self.team )
			{
				if ( self.crateType == "airdrop_juggernaut_maniac" )
				{
					player thread hijackNotify( self, "maniac" );
				}
				else if ( isStrStart( self.crateType, "juggernaut_" ) )
				{
					player thread hijackNotify( self, self.crateType );
				}
				else
				{
					player thread hijackNotify( self, "juggernaut" );
				}
			}
			else
			{
				self.owner thread maps\mp\gametypes\_rank::giveRankXP( "killstreak_giveaway", Int( maps\mp\killstreaks\_killstreaks::getStreakCost( self.crateType ) / 10 ) * 50 );
				
				if ( self.crateType == "airdrop_juggernaut_maniac" )
				{
					self.owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "giveaway_juggernaut_maniac", player );
				}
				else if ( isStrStart( self.crateType, "juggernaut_" ) )
				{
					self.owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "giveaway_" + self.crateType, player );
				}
				else
				{
					self.owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "giveaway_juggernaut", player );
				}
			}
		}		
	
		player playLocalSound( "ammo_crate_use" );
		
		juggType = "juggernaut";
		switch( self.crateType )
		{
		case "airdrop_juggernaut":
			juggType = "juggernaut";
			break;
		case "airdrop_juggernaut_recon":
			juggType = "juggernaut_recon";
			break;
		case "airdrop_juggernaut_maniac":
			juggType = "juggernaut_maniac";
			break;
		default:
			if ( isStrStart( self.crateType, "juggernaut_" ) )
			{
				juggType = self.crateType;
			}
			break;
		}
		
		player thread maps\mp\killstreaks\_juggernaut::giveJuggernaut( juggType );
		
		self deleteCrate();
	}
}


sentryCrateThink( dropType )
{
	self endon ( "death" );

	crateSetupForUse( game["strings"]["sentry_hint"], getKillstreakOverheadIcon( self.crateType ) );

	self thread crateOtherCaptureThink();
	self thread crateOwnerCaptureThink();

	for ( ;; )
	{
		self waittill ( "captured", player );
		
		if ( IsDefined( self.owner ) && player != self.owner )
		{
			if ( !level.teamBased || player.team != self.team )
			{
				if ( isSubStr(dropType, "airdrop_sentry" ) )
					player thread hijackNotify( self, "sentry" );
				else
					player thread hijackNotify( self, "emergency_airdrop" );
			}
			else
			{
				self.owner thread maps\mp\gametypes\_rank::giveRankXP( "killstreak_giveaway", Int( maps\mp\killstreaks\_killstreaks::getStreakCost( "sentry" ) / 10 ) * 50 );
				self.owner maps\mp\gametypes\_hud_message::playerCardSplashNotify( "giveaway_sentry", player );
			}
		}		
	
		player playLocalSound( "ammo_crate_use" );
		player thread sentryUseTracker();
		
		self deleteCrate();
	}
}


deleteCrate()
{
	self notify( "crate_deleting" );
	
	if ( IsDefined( self.usedBy ) )
    {
		// Loop through all of the players still using this object, and make sure their omnvars are being reset properly
		foreach ( player in self.usedBy )
		{
			player SetClientOmnvar( "ui_securing", 0 );	
			player.ui_securing = undefined;
		}
    }
	
	if ( IsDefined( self.objIdFriendly ) )
		_objective_delete( self.objIdFriendly );

	if ( IsDefined( self.objIdEnemy ) )
	{
		if( level.multiTeamBased )
		{
			foreach( obj in self.objIdEnemy )
			{
				_objective_delete( obj );
			}
		}
		else
		{
			_objective_delete( self.objIdEnemy );
		}
	}

	if ( IsDefined( self.bomb ) && IsDefined( self.bomb.killcamEnt ) )
		self.bomb.killcamEnt delete();

	if ( IsDefined( self.bomb ) )
		self.bomb delete();

	if ( IsDefined( self.killCamEnt ) )
		self.killCamEnt delete();
	
	if ( IsDefined( self.dropType ) )
		PlayFX( getfx( "airdrop_crate_destroy" ), self.origin );
	

	self delete();
}

sentryUseTracker()
{
	if ( !self maps\mp\killstreaks\_autosentry::giveSentry( "sentry_minigun" ) )
		self maps\mp\killstreaks\_killstreaks::giveKillstreak( "sentry" );
}


hijackNotify( crate, crateType )
{
	self notify( "hijacker", crateType, crate.owner );
}


refillAmmo( refillEquipment )
{
	weaponList = self GetWeaponsListAll();
	
	if ( refillEquipment )
	{
		if ( self _hasPerk( "specialty_tacticalinsertion" ) && self getAmmoCount( "flare_mp" ) < 1 )
			self givePerkOffhand( "specialty_tacticalinsertion", false );	
	}
		
	foreach ( weaponName in weaponList )
	{
		if ( isSubStr( weaponName, "grenade" ) || ( GetSubStr( weaponName, 0, 2 ) == "gl" ) )
		{
			if ( !refillEquipment || self getAmmoCount( weaponName ) >= 1 )
				continue;
		} 
		
		self giveMaxAmmo( weaponName );
	}
}


/**********************************************************
*		 Capture crate functions
***********************************************************/
useHoldThink( player, useTime, useText, crate ) 
{	
	self maps\mp\_movers::script_mover_link_to_use_object( player );
    
    player _disableWeapon();
    
    self.curProgress = 0;
    self.inUse = true;
    self.useRate = 0;
    
    if( IsDefined( crate ) )
    	crate updateCrateUseState();
    
	if ( IsDefined( useTime ) )
		self.useTime = useTime;
	else
		self.useTime = CONST_CRATE_OTHER_USE_TIME;
    
    result = useHoldThinkLoop( player );
	assert ( IsDefined( result ) );
    
    if ( isAlive( player ) )
        player _enableWeapon();
    
    // Took this out of the above check, otherwise the player will not get unlinked from the crate they are using
    // This would cause an issue where the player's camera might rotate 90 degrees during their death animation, since they are still linked
    if ( IsDefined( player ) )
    {
    	maps\mp\_movers::script_mover_unlink_from_use_object( player );
    }
    
    if ( !IsDefined( self ) )
    	return false;
   
    self.inUse = false;
	self.curProgress = 0;

    if( IsDefined( crate ) )
    	crate updateCrateUseState();	

	return ( result );
}

useHoldThinkLoop( player )
{
	while( player maps\mp\killstreaks\_deployablebox::isPlayerUsingBox( self ) )
    {
		if ( !player maps\mp\_movers::script_mover_use_can_link( self ) )
		{
			player maps\mp\gametypes\_gameobjects::updateUIProgress( self, false );
			return false;
		}

        self.curProgress += (50 * self.useRate);
       
       	if ( IsDefined(self.objectiveScaler) )
        	self.useRate = 1 * self.objectiveScaler;
		else
			self.useRate = 1;

		player maps\mp\gametypes\_gameobjects::updateUIProgress( self, true );

		if ( self.curProgress >= self.useTime )
		{
			player maps\mp\gametypes\_gameobjects::updateUIProgress( self, false );
            return ( isReallyAlive( player ) );
		}
		
        wait 0.05;
    } 
    
	if ( isDefined(self) )
		player maps\mp\gametypes\_gameobjects::updateUIProgress( self, false );
   	
	return false;
}


createUseEnt()
{
	useEnt = Spawn( "script_origin", self.origin );
	useEnt.curProgress = 0;
	useEnt.useTime = 0;
	useEnt.useRate = 3000;
	useEnt.inUse = false;
	useEnt.id = self.id;
	useEnt linkto( self );
	
	useEnt thread deleteUseEnt( self );

	return ( useEnt );
}


deleteUseEnt( owner )
{
	self endon ( "death" );
	
	owner waittill ( "death" );
	
	if ( IsDefined( self.usedBy ) )
    {
		// Loop through all of the players still using this object, and make sure their omnvars are being reset properly
		foreach ( player in self.usedBy )
		{
			player SetClientOmnvar( "ui_securing", 0 );	
			player.ui_securing = undefined;
		}
    }
	
	self delete();
}


airdropDetonateOnStuck()
{
	self endon ( "death" );
	
	self waittill( "missile_stuck" );
	
	self detonate();
}

throw_linked_care_packages( animating_model, offset, throw_vec, delete_volume )
{
	if( IsDefined( level.carePackages ) )
	{
		foreach( carePackage in level.carePackages )
		{
			if( IsDefined(carePackage.inUse) && carePackage.inUse )
				continue;
			
			parent = carePackage GetLinkedParent();
			if( isdefined( parent ) && ( parent == animating_model ) )
			{					
				thread spawn_new_care_package( carePackage, offset, throw_vec );
				if( IsDefined( delete_volume ) )
				{
					delayThread( 1.0, ::remove_care_packages_in_volume, delete_volume );
				}
			}
		}
	}	
}

spawn_new_care_package( package, offset, throw_vec )
{					
		owner	  = package.owner;
		dropType  = package.dropType;
		crateType = package.crateType;
		origin	  = package.origin;
			
		package maps\mp\killstreaks\_airdrop::deleteCrate();		
		
		newCrate				  = owner maps\mp\killstreaks\_airdrop::createAirDropCrate( owner, dropType, crateType, origin + offset , origin + offset  );
		newCrate.droppingtoground = true;

		newCrate thread [[ level.crateTypes[ newCrate.dropType ][ newCrate.crateType ].func ]]( newCrate.dropType );
		
		waitframe();

		newCrate CloneBrushmodelToScriptmodel( level.airDropCrateCollision );
		newCrate thread entity_path_disconnect_thread( 1.0 );
		newCrate PhysicsLaunchServer( newCrate.origin, throw_vec );
		
		if ( IsBot( newCrate.owner ) )
		{
			wait( 0.1 );
			newCrate.owner notify( "new_crate_to_take" );
		}
}

remove_care_packages_in_volume( volume )
{
	if( IsDefined( level.carePackages ) )
	{
		foreach( carePackage in level.carePackages )
		{
			if( IsDefined( carePackage ) && IsDefined( carePackage.friendlyModel ) && ( carePackage.friendlyModel IsTouching( volume ) ) )
			{
				carePackage maps\mp\killstreaks\_airdrop::deleteCrate();
			}
		}
	}
}

get_dummy_crate_model()
{
	return DUMMY_CRATE_MODEL;
}

get_enemy_crate_model()
{
	return ENEMY_CRATE_MODEL;
}

get_friendly_crate_model()
{
	return FRIENDLY_CRATE_MODEL;
}

get_dummy_juggernaut_crate_model()
{
	return DUMMY_JUGGERNAUT_CRATE_MODEL;
}

get_enemy_juggernaut_crate_model()
{
	return ENEMY_JUGGERNAUT_CRATE_MODEL;
}

get_friendly_juggernaut_crate_model()
{
	return FRIENDLY_JUGGERNAUT_CRATE_MODEL;
}
