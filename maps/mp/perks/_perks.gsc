#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\perks\_perkfunctions;

PERK_STRING_TABLE =	"mp/perkTable.csv";
PERK_REF_COLUMN =	1;
PERK_NAME_COLUMN =	2;
PERK_ICON_COLUMN =	3;

THERMO_DEBUFF_DURATION = 5000;

init()
{
	level.perkFuncs = [];

	//level.spawnGlowSplat = loadfx( "fx/misc/flare_ambient_destroy" );

	level.spawnGlowModel["enemy"] = "emergency_flare_iw6";
	level.spawnGlowModel["friendly"] = "emergency_flare_iw6";
	level.spawnGlow["enemy"] = loadfx( "fx/misc/flare_ambient" );
	level.spawnGlow["friendly"] = loadfx( "fx/misc/flare_ambient_green" );
	//level.c4Death = loadfx( "fx/explosions/javelin_explosion" );

	level.spawnFire = loadfx( "fx/props/barrelexp" );

	level._effect["ricochet"] = loadfx( "fx/impacts/large_metalhit_1" );

	// perks that currently only exist in script: these will error if passed to "setPerk", etc... CASE SENSITIVE! must be lower
	level.scriptPerks = [];
	level.perkSetFuncs = [];
	level.perkUnsetFuncs = [];
	level.fauxPerks = [];

	level.scriptPerks[ "_specialty_blastshield"			] = true;
	level.scriptPerks[ "_specialty_onemanarmy"			] = true;
	level.scriptPerks[ "_specialty_rearview"			] = true;
	level.scriptPerks[ "specialty_ac130"				] = true;
	level.scriptPerks[ "specialty_akimbo"				] = true;
	level.scriptPerks[ "specialty_anytwo"				] = true;
	level.scriptPerks[ "specialty_armorpiercing"		] = true;
	level.scriptPerks[ "specialty_assists"				] = true;
	level.scriptPerks[ "specialty_autospot"				] = true;
	level.scriptPerks[ "specialty_blackbox"				] = true;
	level.scriptPerks[ "specialty_blastshield"			] = true;
	level.scriptPerks[ "specialty_bloodrush"			] = true;
	level.scriptPerks[ "specialty_boom"					] = true;
	level.scriptPerks[ "specialty_challenger"			] = true;
	level.scriptPerks[ "specialty_combat_speed"			] = true;
	level.scriptPerks[ "specialty_comexp"				] = true;
	level.scriptPerks[ "specialty_concussiongrenade"	] = true;
	level.scriptPerks[ "specialty_dangerclose"			] = true;
	level.scriptPerks[ "specialty_deadeye"				] = true;
	level.scriptPerks[ "specialty_delaymine"			] = true;
	level.scriptPerks[ "specialty_double_load"			] = true;
	level.scriptPerks[ "specialty_endgame"				] = true;
	level.scriptPerks[ "specialty_explosivedamage"		] = true;
	level.scriptPerks[ "specialty_extra_attachment"		] = true;
	level.scriptPerks[ "specialty_extra_deadly"			] = true;
	level.scriptPerks[ "specialty_extra_equipment"		] = true;
	level.scriptPerks[ "specialty_extraspecialduration" ] = true;
	level.scriptPerks[ "specialty_falldamage"			] = true;
	level.scriptPerks[ "specialty_fasterlockon"			] = true;
	level.scriptPerks[ "specialty_feigndeath"			] = true;
	level.scriptPerks[ "specialty_flashgrenade"			] = true;
	level.scriptPerks[ "specialty_gambler"				] = true;
	level.scriptPerks[ "specialty_gunsmith"				] = true;
	level.scriptPerks[ "specialty_hard_shell"			] = true;
	level.scriptPerks[ "specialty_hardjack"				] = true;
	level.scriptPerks[ "specialty_hardline"				] = true;
	level.scriptPerks[ "specialty_helicopter_minigun"	] = true;
	level.scriptPerks[ "specialty_incog"				] = true;
	level.scriptPerks[ "specialty_laststandoffhand"		] = true;
	level.scriptPerks[ "specialty_littlebird_support"	] = true;
	level.scriptPerks[ "specialty_localjammer"			] = true;
	level.scriptPerks[ "specialty_luckycharm"			] = true;
	level.scriptPerks[ "specialty_moreHealth"			] = true;
	level.scriptPerks[ "specialty_omaquickchange"		] = true;
	level.scriptPerks[ "specialty_onemanarmy"			] = true;
	level.scriptPerks[ "specialty_overkillpro"			] = true;
	level.scriptPerks[ "specialty_paint"				] = true;
	level.scriptPerks[ "specialty_paint_pro"			] = true;
	level.scriptPerks[ "specialty_pitcher"				] = true;
	level.scriptPerks[ "specialty_precision_airstrike"	] = true;
	level.scriptPerks[ "specialty_predator_missile"		] = true;
	level.scriptPerks[ "specialty_primarydeath"			] = true;
	level.scriptPerks[ "specialty_rearview"				] = true;
	level.scriptPerks[ "specialty_refill_ammo"			] = true;
	level.scriptPerks[ "specialty_refill_grenades"		] = true;
	level.scriptPerks[ "specialty_regenfaster"			] = true;
	level.scriptPerks[ "specialty_rollover"				] = true;
	level.scriptPerks[ "specialty_saboteur"				] = true;
	level.scriptPerks[ "specialty_secondarybling"		] = true;
	level.scriptPerks[ "specialty_sentry_minigun"		] = true;
	level.scriptPerks[ "specialty_shellshock"			] = true;
	level.scriptPerks[ "specialty_shield"				] = true;
	level.scriptPerks[ "specialty_smokegrenade"			] = true;
	level.scriptPerks[ "specialty_steadyaimpro"			] = true;
	level.scriptPerks[ "specialty_steelnerves"			] = true;
	level.scriptPerks[ "specialty_stun_resistance"		] = true;
	level.scriptPerks[ "specialty_tagger"				] = true;
	level.scriptPerks[ "specialty_tank"					] = true;
	level.scriptPerks[ "specialty_thermal"				] = true;
	level.scriptPerks[ "specialty_triggerhappy"			] = true;
	level.scriptPerks[ "specialty_twoprimaries"			] = true;
	level.scriptPerks[ "specialty_weaponlaser"			] = true;
		
	level.fauxPerks["specialty_shield"] = true;

	// weapon buffs
	level.scriptPerks["specialty_marksman"] = true;
	level.scriptPerks["specialty_sharp_focus"] = true;
	level.scriptPerks["specialty_bling"] = true;
	level.scriptPerks["specialty_moredamage"] = true;
	
	// weapon attachment perks
	level.scriptPerks["specialty_rshieldradar"] = true;
	level.scriptPerks["specialty_rshieldscrambler"] = true;

	// death streaks
	level.scriptPerks["specialty_combathigh"] = true;
	level.scriptPerks["specialty_finalstand"] = true;
	level.scriptPerks["specialty_c4death"] = true;
	level.scriptPerks["specialty_juiced"] = true;
	level.scriptPerks["specialty_revenge"] = true;
	level.scriptPerks["specialty_light_armor"] = true;
	level.scriptPerks["specialty_carepackage"] = true;
	level.scriptPerks["specialty_stopping_power"] = true;
	level.scriptPerks["specialty_uav"] = true;

	// equipment
	level.scriptPerks["bouncingbetty_mp"] = true;
	level.scriptPerks["c4_mp"] = true;
	level.scriptPerks["claymore_mp"] = true;
	level.scriptPerks["frag_grenade_mp"] = true;
	level.scriptPerks["semtex_mp"] = true;
	level.scriptPerks["throwingknife_mp"] = true;
	level.scriptPerks["throwingknifejugg_mp"] = true;
	level.scriptPerks["thermobaric_grenade_mp"] = true;
	level.scriptPerks["mortar_shell_mp"] = true;
	level.scriptPerks["proximity_explosive_mp"] = true;
	level.scriptPerks["mortar_shelljugg_mp"] = true;

	// special grenades
	level.scriptPerks["concussion_grenade_mp"] = true;
	level.scriptPerks["flash_grenade_mp"] = true;
	level.scriptPerks["smoke_grenade_mp"] = true;
	level.scriptPerks["smoke_grenadejugg_mp"] = true;
	level.scriptPerks["emp_grenade_mp"] = true;
	//level.scriptPerks["specialty_portable_radar"] = true;
	//level.scriptPerks["specialty_scrambler"] = true;
	level.scriptPerks["specialty_tacticalinsertion"] = true;
	level.scriptPerks["trophy_mp"] = true;
	level.scriptPerks["motion_sensor_mp"] = true;

	// specialty_null is assigned as a perk sometimes and it's not a code perk
	level.scriptPerks["specialty_null"] = true;

	level.perkSetFuncs["specialty_blastshield"] = ::setBlastShield;
	level.perkUnsetFuncs["specialty_blastshield"] = ::unsetBlastShield;

	level.perkSetFuncs["specialty_falldamage"] = ::setFreefall;
	level.perkUnsetFuncs["specialty_falldamage"] = ::unsetFreefall;

	level.perkSetFuncs["specialty_localjammer"] = ::setLocalJammer;
	level.perkUnsetFuncs["specialty_localjammer"] = ::unsetLocalJammer;

	level.perkSetFuncs["specialty_thermal"] = ::setThermal;
	level.perkUnsetFuncs["specialty_thermal"] = ::unsetThermal;

	level.perkSetFuncs["specialty_blackbox"] = ::setBlackBox;
	level.perkUnsetFuncs["specialty_blackbox"] = ::unsetBlackBox;

	level.perkSetFuncs["specialty_lightweight"] = ::setLightWeight;
	level.perkUnsetFuncs["specialty_lightweight"] = ::unsetLightWeight;

	level.perkSetFuncs["specialty_steelnerves"] = ::setSteelNerves;
	level.perkUnsetFuncs["specialty_steelnerves"] = ::unsetSteelNerves;

	level.perkSetFuncs["specialty_delaymine"] = ::setDelayMine;
	level.perkUnsetFuncs["specialty_delaymine"] = ::unsetDelayMine;

	level.perkSetFuncs["specialty_challenger"] = ::setChallenger;
	level.perkUnsetFuncs["specialty_challenger"] = ::unsetChallenger;

	level.perkSetFuncs["specialty_saboteur"] = ::setSaboteur;
	level.perkUnsetFuncs["specialty_saboteur"] = ::unsetSaboteur;

	level.perkSetFuncs["specialty_endgame"] = ::setEndGame;
	level.perkUnsetFuncs["specialty_endgame"] = ::unsetEndGame;

	level.perkSetFuncs["specialty_rearview"] = ::setRearView;
	level.perkUnsetFuncs["specialty_rearview"] = ::unsetRearView;

	level.perkSetFuncs["specialty_ac130"] = ::setAC130;
	level.perkUnsetFuncs["specialty_ac130"] = ::unsetAC130;

	level.perkSetFuncs["specialty_sentry_minigun"] = ::setSentryMinigun;
	level.perkUnsetFuncs["specialty_sentry_minigun"] = ::unsetSentryMinigun;

	level.perkSetFuncs["specialty_predator_missile"] = ::setPredatorMissile;
	level.perkUnsetFuncs["specialty_predator_missile"] = ::unsetPredatorMissile;

	level.perkSetFuncs["specialty_tank"] = ::setTank;
	level.perkUnsetFuncs["specialty_tank"] = ::unsetTank;

	level.perkSetFuncs["specialty_precision_airstrike"] = ::setPrecision_airstrike;
	level.perkUnsetFuncs["specialty_precision_airstrike"] = ::unsetPrecision_airstrike;

	level.perkSetFuncs["specialty_helicopter_minigun"] = ::setHelicopterMinigun;
	level.perkUnsetFuncs["specialty_helicopter_minigun"] = ::unsetHelicopterMinigun;

	level.perkSetFuncs["specialty_onemanarmy"] = ::setOneManArmy;
	level.perkUnsetFuncs["specialty_onemanarmy"] = ::unsetOneManArmy;

	level.perkSetFuncs["specialty_littlebird_support"] = ::setLittlebirdSupport;
	level.perkUnsetFuncs["specialty_littlebird_support"] = ::unsetLittlebirdSupport;

	level.perkSetFuncs["specialty_tacticalinsertion"] = ::setTacticalInsertion;
	level.perkUnsetFuncs["specialty_tacticalinsertion"] = ::unsetTacticalInsertion;

	//level.perkSetFuncs["specialty_scrambler"] = maps\mp\gametypes\_scrambler::setScrambler;
	//level.perkUnsetFuncs["specialty_scrambler"] = maps\mp\gametypes\_scrambler::unsetScrambler;

	//level.perkSetFuncs["specialty_portable_radar"] = maps\mp\gametypes\_portable_radar::setPortableRadar;
	//level.perkUnsetFuncs["specialty_portable_radar"] = maps\mp\gametypes\_portable_radar::unsetPortableRadar;

	level.perkSetFuncs["specialty_weaponlaser"] = ::setWeaponLaser;
	level.perkUnsetFuncs["specialty_weaponlaser"] = ::unsetWeaponLaser;
	
	level.perkSetFuncs["specialty_steadyaimpro"] = ::setSteadyAimPro;
	level.perkUnsetFuncs["specialty_steadyaimpro"] = ::unsetSteadyAimPro;

	level.perkSetFuncs["specialty_stun_resistance"] = ::setStunResistance;
	level.perkUnsetFuncs["specialty_stun_resistance"] = ::unsetStunResistance;

	level.perkSetFuncs["specialty_marksman"] = ::setMarksman;
	level.perkUnsetFuncs["specialty_marksman"] = ::unsetMarksman;
	
	level.perkSetFuncs["specialty_rshieldradar"] = ::setRShieldRadar;
	level.perkUnsetFuncs["specialty_rshieldradar"] = ::unsetRShieldRadar;
	
	level.perkSetFuncs["specialty_rshieldscrambler"] = ::setRShieldScrambler;
	level.perkUnsetFuncs["specialty_rshieldscrambler"] = ::unsetRShieldScrambler;

	level.perkSetFuncs["specialty_double_load"] = ::setDoubleLoad;
	level.perkUnsetFuncs["specialty_double_load"] = ::unsetDoubleLoad;

	level.perkSetFuncs["specialty_sharp_focus"] = ::setSharpFocus;
	level.perkUnsetFuncs["specialty_sharp_focus"] = ::unsetSharpFocus;

	level.perkSetFuncs["specialty_hard_shell"] = ::setHardShell;
	level.perkUnsetFuncs["specialty_hard_shell"] = ::unsetHardShell;

	level.perkSetFuncs["specialty_regenfaster"] = ::setRegenFaster;
	level.perkUnsetFuncs["specialty_regenfaster"] = ::unsetRegenFaster;

	level.perkSetFuncs["specialty_autospot"] = ::setAutoSpot;
	level.perkUnsetFuncs["specialty_autospot"] = ::unsetAutoSpot;

	level.perkSetFuncs["specialty_empimmune"] = ::setEmpImmune;
	level.perkUnsetFuncs["specialty_empimmune"] = ::unsetEmpImmune;

	level.perkSetFuncs["specialty_overkill_pro"] = ::setOverkillPro;
	level.perkUnsetFuncs["specialty_overkill_pro"] = ::unsetOverkillPro;
	
	level.perkSetFuncs["specialty_assists"] = ::setAssists;
	level.perkUnsetFuncs["specialty_assists"] = ::unsetAssists;	

	level.perkSetFuncs["specialty_refill_grenades"] = ::setRefillGrenades;
	level.perkUnsetFuncs["specialty_refill_grenades"] = ::unsetRefillGrenades;

	level.perkSetFuncs["specialty_refill_ammo"] = ::setRefillAmmo;
	level.perkUnsetFuncs["specialty_refill_ammo"] = ::unsetRefillAmmo;
	
	level.perkSetFuncs["specialty_combat_speed"] = ::setCombatSpeed;
	level.perkUnsetFuncs["specialty_combat_speed"] = ::unsetCombatSpeed;
	
	level.perkSetFuncs["specialty_gambler"] = ::setGambler;
	level.perkUnsetFuncs["specialty_gambler"] = ::unsetGambler;
	
	level.perkSetFuncs["specialty_comexp"] = ::setComExp;
	level.perkUnsetFuncs["specialty_comexp"] = ::unsetComExp;
	
	level.perkSetFuncs["specialty_gunsmith"] = ::setGunsmith;
	level.perkUnsetFuncs["specialty_gunsmith"] = ::unsetGunsmith;
	
	level.perkSetFuncs["specialty_tagger"] = ::setTagger;
	level.perkUnsetFuncs["specialty_tagger"] = ::unsetTagger;	
	
	level.perkSetFuncs["specialty_pitcher"] = ::setPitcher;
	level.perkUnsetFuncs["specialty_pitcher"] = ::unsetPitcher;	

	level.perkSetFuncs["specialty_boom"] = ::setBoom;
	level.perkUnsetFuncs["specialty_boom"] = ::unsetBoom;	

	level.perkSetFuncs["specialty_silentkill"] = ::setSilentkill;
	level.perkUnsetFuncs["specialty_silentkill"] = ::unsetSilentkill;		

	level.perkSetFuncs["specialty_bloodrush"] = ::setBloodrush;
	level.perkUnsetFuncs["specialty_bloodrush"] = ::unsetBloodrush;		
	
	level.perkSetFuncs["specialty_triggerhappy"] = ::setTriggerHappy;
	level.perkUnsetFuncs["specialty_triggerhappy"] = ::unsetTriggerHappy;		

	level.perkSetFuncs["specialty_deadeye"] = ::setDeadeye;
	level.perkUnsetFuncs["specialty_deadeye"] = ::unsetDeadeye;	
	
	level.perkSetFuncs["specialty_incog"] = ::setIncog;
	level.perkUnsetFuncs["specialty_incog"] = ::unsetIncog;		
	
	level.perkSetFuncs["specialty_blindeye"] = ::setBlindeye;
	level.perkUnsetFuncs["specialty_blindeye"] = ::unsetBlindeye;	

	level.perkSetFuncs["specialty_quickswap"] = ::setQuickswap;
	level.perkUnsetFuncs["specialty_quickswap"] = ::unsetQuickswap;			
	
	level.perkSetFuncs["specialty_extraammo"] = ::setExtraAmmo;
	level.perkUnsetFuncs["specialty_extraammo"] = ::unsetExtraAmmo;			
	
	level.perkSetFuncs["specialty_extra_equipment"] = ::setExtraEquipment;
	level.perkUnsetFuncs["specialty_extra_equipment"] = ::unsetExtraEquipment;		

	level.perkSetFuncs["specialty_extra_deadly"] = ::setExtraDeadly;
	level.perkUnsetFuncs["specialty_extra_deadly"] = ::unsetExtraDeadly;

	// death streaks
	level.perkSetFuncs["specialty_combathigh"] = ::setCombatHigh;
	level.perkUnsetFuncs["specialty_combathigh"] = ::unsetCombatHigh;

	level.perkSetFuncs["specialty_light_armor"] = ::setLightArmor;
	level.perkUnsetFuncs["specialty_light_armor"] = ::unsetLightArmor;

	level.perkSetFuncs["specialty_revenge"] = ::setRevenge;
	level.perkUnsetFuncs["specialty_revenge"] = ::unsetRevenge;

	level.perkSetFuncs["specialty_c4death"] = ::setC4Death;
	level.perkUnsetFuncs["specialty_c4death"] = ::unsetC4Death;

	level.perkSetFuncs["specialty_finalstand"] = ::setFinalStand;
	level.perkUnsetFuncs["specialty_finalstand"] = ::unsetFinalStand;

	level.perkSetFuncs["specialty_juiced"] = ::setJuiced;
	level.perkUnsetFuncs["specialty_juiced"] = ::unsetJuiced;

	level.perkSetFuncs["specialty_carepackage"] = ::setCarePackage;
	level.perkUnsetFuncs["specialty_carepackage"] = ::unsetCarePackage;

	level.perkSetFuncs["specialty_stopping_power"] = ::setStoppingPower;
	level.perkUnsetFuncs["specialty_stopping_power"] = ::unsetStoppingPower;

	level.perkSetFuncs["specialty_uav"] = ::setUAV;
	level.perkUnsetFuncs["specialty_uav"] = ::unsetUAV;	
	// end death streaks

	initPerkDvars();

	level thread onPlayerConnect();
}

// Note: This function should only be used to validate perks from
// the load out.
validateEquipment( equipmentName, isLethal, shouldAssert )
{
	shouldAssert = ter_op( IsDefined( shouldAssert ), shouldAssert, true );
	// Some game modes incorrectly set the equipment to "none" which causes
	// an assert below. -JC:09/18/13
	equipmentName = ter_op( equipmentName == "none", "specialty_null", equipmentName );
	
	if ( isLethal )
	{
		switch ( equipmentName )
		{
			// Default Loadout Lethal Equipment
			case "specialty_null":
			case "c4_mp":
			case "semtex_mp":
			case "frag_grenade_mp":
			case "throwingknife_mp":
			case "mortar_shell_mp":
			case "proximity_explosive_mp":
			// Juggernuat Lethal Equipment
			case "throwingknifejugg_mp":
			case "mortar_shelljugg_mp":
				break;
			default:
				AssertEx( !shouldAssert, "validateEquipment() found invalid lethal: " + equipmentName + " in load equipment. This should never happen." );
				equipmentName = "specialty_null";
				break;
		}
	}
	else
	{
		switch ( equipmentName )
		{
			// Default Loadout Tactical Equipment
			case "specialty_null":
			case "trophy_mp":
			case "flash_grenade_mp":
			case "smoke_grenade_mp":
			case "concussion_grenade_mp":
			case "motion_sensor_mp":
			case "thermobaric_grenade_mp":
			// Juggernuat Tactical Equipment
			case "smoke_grenadejugg_mp":
				break;
			default:
				AssertEx( !shouldAssert, "validateEquipment() found invalid tactical: " + equipmentName + " in load equipment. This should never happen." );
				equipmentName = "specialty_null";
				break;
		}
	}
	return equipmentName;
}

// Note: This function should only be used to validate perks from
// standard loadouts.
validatePerk( perkName )
{
	if ( !perksEnabled() )
	{
		perkName = "specialty_null";
	}
	else
	{
		switch ( perkName )
		{
			// Default Loadout Perks
			case "specialty_null":
			case "specialty_fastsprintrecovery":
			case "specialty_fastreload":
			case "specialty_lightweight":
			case "specialty_marathon":
			case "specialty_stalker":
			case "specialty_pitcher":
			case "specialty_sprintreload":
			case "specialty_quickswap":
			case "specialty_bulletaccuracy":
			case "specialty_quickdraw":
			case "specialty_silentkill":
			case "specialty_blindeye":
			case "specialty_quieter":
			case "specialty_incog":
			case "specialty_gpsjammer":
			case "specialty_paint":
			case "specialty_scavenger":
			case "specialty_detectexplosive":
			case "specialty_selectivehearing":
			case "specialty_comexp":
			case "specialty_falldamage":
			case "specialty_regenfaster":
			case "specialty_sharp_focus":
			case "specialty_stun_resistance":
			case "_specialty_blastshield":
			case "specialty_extra_equipment":
			case "specialty_extra_deadly":
			case "specialty_extraammo":
			case "specialty_extra_attachment":
			case "specialty_explosivedamage":
			case "specialty_gambler":
			case "specialty_hardline":
			case "specialty_boom":
			case "specialty_twoprimaries":
			case "specialty_deadeye":
				break;
			default:
				AssertMsg( "validatePerk() found invalid perk: " + perkName + " in load out perks. This should never happen." );
				perkName = "specialty_null";
				break;
		}
	}
	return perkName;
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon( "disconnect" );

	self.perks = [];
	self.perksPerkName = [];
	self.perksUseSlot = [];
	
	self.weaponList = [];
	self.omaClassChanged = false;

	for( ;; )
	{
		self waittill( "spawned_player" );

		self.omaClassChanged = false;
		self thread maps\mp\killstreaks\_portableAOEgenerator::generatorAOETracker();
	}
}

thermoDebuffWatcher()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	thermoDebuffEndTime = getTime() + THERMO_DEBUFF_DURATION;
	
	wait 0.05;
	self.thermoDebuffed = true;
	
	while( true )
	{
		if( self.health == self.maxhealth )
		{	
			self.thermoDebuffed = false;
			return;
		}
		
		//max debuff time of 5 seconds if a player keeps getting hurt
		if ( getTime() >= thermoDebuffEndTime )
		{
			self.thermoDebuffed = false;
			return;
		}
		
		wait ( 0.05 );
	}
}


cac_modified_damage( victim, attacker, damage, sMeansOfDeath, sWeapon, impactPoint, impactDir, sHitLoc, inflictor )
{
	assert( isPlayer( victim ) || isAgent( victim ) );
	assert( IsDefined( victim.team ) );
	
	//IW6 added for higher health playlist
	if ( matchMakingGame() && self.maxhealth > 100 )
	{
	    if( isDefined( sWeapon ) && weaponClass( sWeapon ) == "spread" )
			damage *= ( self.maxhealth/100 );
	}

	damageAdd = 0;
	
	locJugScale = 0;
	if( victim isJuggernaut() )
	{
		locJugScale = level.juggernautMod;
		if( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac )
		{
			locJugScale = level.juggernautManiacMod;
		}
	}

	if( isBulletDamage( sMeansOfDeath ) )
	{
		if ( isFMJDamage( sWeapon, sMeansOfDeath, attacker ) )
		{
			locJugScale *= level.armorPiercingMod;
		}
			
		// show the victim on the minimap for N seconds
		if( IsPlayer( attacker ) && attacker _hasPerk( "specialty_paint_pro" ) && !isKillstreakWeapon( sWeapon ) )
		{
			// make sure they aren't already painted before we process the challenge
			if( !victim isPainted() )
				attacker maps\mp\gametypes\_missions::processChallenge( "ch_bulletpaint" );

			victim thread maps\mp\perks\_perkfunctions::setPainted( attacker );
		}

		// stopping power and armor vest cancel each other out
		if( IsPlayer( attacker ) && 
			( attacker _hasPerk( "specialty_bulletdamage" ) && victim _hasPerk( "specialty_armorvest" ) ) )
		{
			// purposely left empty
		}
		// if the attacker has the stopping power or has the more damage weapon buff
		else if( IsPlayer( attacker ) && 
				 ( attacker _hasPerk( "specialty_bulletdamage" ) || attacker _hasPerk( "specialty_moredamage" ) ) ) 
		{
			damageAdd += damage * level.bulletDamageMod;
		}
		// if the victim has armor vest take some damage off
		else if ( victim _hasPerk( "specialty_armorvest" ) )
		{
			damageAdd -= damage * level.armorVestMod;
		}

		// let's handle juggernaut damaging here after all of the damageAdd math has happened
		if ( victim isJuggernaut() )
		{
			// JC-09/20/13: In hardcore prevent shotguns from killing juggernauts 
			// in 1 shotgun blast. Worst case:
				//	8 pellets at ( 25 dmg * juggScale ) = 2 dmg per pellet or 16 dmg total ( 53% of the 30 health )
			if ( level.hardcoreMode && IsDefined( sWeapon ) && WeaponClass( sWeapon ) == "spread" )
			{
				damage = Min( damage, 25 ) * locJugScale;
				damageAdd = Min( damage, 25 ) * locJugScale;
			}
			else
			{
				damage *= locJugScale;
				damageAdd *= locJugScale;
			}
		}
	}
	else if( IsExplosiveDamageMOD( sMeansOfDeath ) )
	{
		//proximity explosive damage via stance adjustments
		if ( sWeapon == "proximity_explosive_mp" && IsDefined( inflictor.origin ) )
		{
			if ( victim GetStance() == "prone" )
			{
				damage *= 0.65;
			}
			else if ( !victim IsOnGround() )
			{
				damage *= 0.80;
			}
			else if ( victim GetStance() == "crouch" )
			{
				damage *= 0.90;
			}
		}
		
		// show the victim on the minimap for N seconds
		if ( isPlayer(attacker) )
		{
			
			if( attacker != victim && 
				( attacker IsItemUnlocked( "specialty_paint" ) && attacker _hasPerk( "specialty_paint" ) )
				&& !isKillstreakWeapon( sWeapon ) )
			{
				if( !victim isPainted() )
					attacker maps\mp\gametypes\_missions::processChallenge( "ch_paint_pro" );		
	
				victim thread maps\mp\perks\_perkfunctions::setPainted( attacker );
			}
		}
		
		if ( isDefined( victim.thermoDebuffed ) && victim.thermoDebuffed )
		{
			damageAdd += int( damage * ( level.thermoDebuffMod ) );
		}
		
		if( sWeapon == "thermobaric_grenade_mp" )
		{
			// Thermos are 1HK in hardcore with a large blast radius. This reduces damage to 15/30 maxhealth, consistent with core 50/100
			if ( level.hardcoreMode )
			{
				damage *=.3;
			}
			
			victim thread thermoDebuffWatcher();
		}
		
		if( isPlayer( attacker ) && 
		    weaponInheritsPerks( sWeapon ) &&
			( attacker _hasPerk( "specialty_explosivedamage" ) && victim _hasPerk( "_specialty_blastshield" ) ) )
		{
			// purposely left empty
		}
		else if( isPlayer( attacker ) && 
				 weaponInheritsPerks( sWeapon ) &&
				 !isKillstreakWeapon( sWeapon ) &&
				 attacker _hasPerk( "specialty_explosivedamage" ) )
		{
			damageAdd += damage * level.explosiveDamageMod;
		}
		else if (	victim _hasPerk( "_specialty_blastshield" ) && !weaponIgnoresBlastShield( sWeapon ) &&
				( !IsDefined( inflictor ) || !IsDefined( inflictor.stuckEnemyEntity ) || inflictor.stuckEnemyEntity != victim ))
		{
			passedThroughDamage = int( damage * level.blastShieldMod );
			
			if ( maps\mp\gametypes\_weapons::isGrenade( sWeapon )
			    || isWeaponAffectedByBlastShield( sWeapon )
			    
			   )
			{
				passedThroughDamage = clamp( passedThroughDamage, 0, level.blastShieldClamp );
			}
			
			damageAdd -= damage - passedThroughDamage;
		}

		if( victim isJuggernaut() )
		{
			damageAdd *= locJugScale;

			// If the missile is more than 1000 damage kill the jug
			if( damage < 1000 )
			{
				damage *= locJugScale;
			}
		}
		
		// fix for grenade spam at start of round
		if ( !is_aliens() )
		{
			if ( ( 10 - ( level.gracePeriod - level.inGracePeriod ) ) > 0 )
			{
				damage *= level.gracePeriodGrenadeMod;
			}
		}
		
	}
	else if( sMeansOfDeath == "MOD_FALLING" )
	{
		if( victim _hasPerk( "specialty_falldamage" ) )
		{
			if( damage > 0 )
				victim maps\mp\gametypes\_missions::processChallenge( "ch_falldamage" );

			//eventually set a msg to do a roll
			damageAdd = 0;
			damage = 0;
		}
		else
		{
			if( victim isJuggernaut() )
			{
				damage *= locJugScale;
			}
		}
	}
	else if( sMeansOfDeath == "MOD_MELEE" )
	{
		if ( victim isJuggernaut() )
		{
			damage = 20;
			damageAdd = 0;
		}
		// Horde
		else if ( hasHeavyArmor( victim ) )
		{
			damage = 100;
		}
		else if ( IsDefined( victim.customMeleeDamageTaken ) && victim.customMeleeDamageTaken >= 0 )
		{
			damage = victim.customMeleeDamageTaken;	
		}
		else
		{
			if ( maps\mp\gametypes\_weapons::isRiotShield( sWeapon ) )
			{
				if ( level.hardcoreMode )
				{
					damage = Int( victim.maxHealth + 1 );
				}
				else
				{
					damage = Int( victim.maxHealth * 0.66 );
				}
			}
			else //knife
			{
				damage = victim.maxHealth + 1;
			}
		}
	}
	else if( sMeansOfDeath == "MOD_IMPACT" )
	{
		// let's handle juggernaut damaging here
		if( victim isJuggernaut() )
		{
			switch( sWeapon )
			{
			case "concussion_grenade_mp":
			case "flash_grenade_mp":
			case "smoke_grenade_mp":
			case "smoke_grenadejugg_mp":
			case "frag_grenade_mp":
			case "semtexproj_mp":
			case "semtex_mp":
			case "mortar_shell_mp":
			case "mortar_shelljugg_mp":
				damage = 5;
				break;
			
			default:
				if( damage < 1000 )
					damage = 25;
				break;
			}

			damageAdd = 0;
		}
	}
	else if( sMeansOfDeath == "MOD_UNKNOWN" || sMeansOfDeath == "MOD_MELEE_DOG" )
	{
		if( IsAgent( attacker ) && IsDefined( attacker.agent_type ) && attacker.agent_type == "dog" && victim isJuggernaut() )
		{
			victim ShellShock( "dog_bite", 2 );
			damage *= locJugScale;
		}
	}

	if ( victim _hasperk( "specialty_combathigh" ) )
	{
		if ( IsDefined( self.damageBlockedTotal ) && (!level.teamBased || (IsDefined( attacker ) && IsDefined( attacker.team ) && victim.team != attacker.team)) )
		{
			damageTotal = damage + damageAdd;
			damageBlocked = (damageTotal - ( damageTotal / 3 ));
			self.damageBlockedTotal += damageBlocked;

			if ( self.damageBlockedTotal >= 101 )
			{
				self notify( "combathigh_survived" );
				self.damageBlockedTotal = undefined;
			}
		}

		if ( sWeapon != "throwingknife_mp" && sWeapon != "throwingknifejugg_mp" )
		{
			switch ( sMeansOfDeath )
			{
				case "MOD_FALLING":
				case "MOD_MELEE":
					break;
				default:
					damage = Int( damage/3 );
					damageAdd = Int( damageAdd/3 );
					break;
			}
		}

	}

	// Handle armor damage
	if( IsDefined( victim.lightArmorHP ) )
	{
		switch( sWeapon )
		{
			case "throwingknife_mp":
			case "throwingknifejugg_mp":
			{
				damage = victim.health;
				damageAdd = 0;
				break;
			}
			case "semtexproj_mp":
			case "semtex_mp":
			{
				if( IsDefined( inflictor ) && IsDefined( inflictor.stuckEnemyEntity ) && inflictor.stuckEnemyEntity == victim )
				{
					damage = victim.health;
					damageAdd = 0;	
				}
				break;
			}
			default:
			{
				// Handle Armor Damage
				// no armor damage in case of falling, melee, fmj or head shots
				if	(	sMeansOfDeath != "MOD_FALLING" 
					&&	sMeansOfDeath != "MOD_MELEE"
					&&	!isHeadShot( sWeapon, sHitLoc, sMeansOfDeath, attacker )
					&&	!isFMJDamage( sWeapon, sMeansOfDeath, attacker )
					)
				{
					victim.lightArmorHP -= ( damage + damageAdd );
					damage	  = 0;
					damageAdd = 0;
					if ( victim.lightArmorHP <= 0 )
					{
						// since the light armor is gone, adjust the damage to be the excess damage that happens after the light armor hp is reduced
						damage = abs( victim.lightArmorHP );
						damageAdd = 0;
						unsetLightArmor();
					}
				}
				break;
			}
		}
	}
	
	// Horde
	if( hasHeavyArmor(victim) )
	{
		victim.heavyArmorHP -= (damage + damageAdd);
		damage = 0;
		
		if( victim.heavyArmorHP < 0 )
		{
			damage = abs( victim.heavyArmorHP );
		}
	}

	if ( !is_aliens() && ( damage <= 1 ) )
	{	
		damage = 1;
	}
	else
	{
		damage = int( damage + damageAdd );
	}
	return damage;
}

initPerkDvars()
{
	level.gracePeriodGrenadeMod = 	8/100;  // percentage of damage from grenades at the start of a game
	level.juggernautMod =			8/100;	// percentage of damage juggernaut takes
	level.juggernautManiacMod =		8/100;	// percentage of damage juggernaut takes
	level.armorPiercingMod =		1.5;	// increased bullet damage * this on vests, juggernauts and vehicles. IW6 Used by both specialty_armorpiercing and specialty_bulletpenetration
	level.regenFasterMod			= getIntProperty( "perk_fastRegenWaitMS", 500 )/1000;	// regen health will start at a percent of the normal speed
	level.regenFasterHealthMod		= getIntProperty( "perk_fastRegenRate",	2 );		// regen health multiplied times the normal speed

	level.bulletDamageMod			= getIntProperty( "perk_bulletDamage",	40 )/100;	// increased bullet damage by this %
	level.explosiveDamageMod		= getIntProperty( "perk_explosiveDamage", 40 )/100;	// increased explosive damage by this %
	level.blastShieldMod			= getIntProperty( "perk_blastShieldScale", 65 )/100;
	level.blastShieldClamp			= getIntProperty( "perk_blastShieldClampHP", 80 );
	level.thermoDebuffMod 			= getIntProperty( "weap_thermoDebuffMod", 185 )/100;
	level.riotShieldMod				= getIntProperty( "perk_riotShield",		100 )/100;
	level.armorVestMod				= getIntProperty( "perk_armorVest",		75 )/100;	// percentage of damage you take
	
	if( IsDefined( level.hardcoreMode ) && level.hardcoreMode )
	{
		level.blastShieldMod = getIntProperty( "perk_blastShieldScale_HC", 10 )/100;		// percentage of damage you take
		level.blastShieldClamp = getIntProperty( "perk_blastShieldClampHP_HC", 20 );
	}
}

// CAC: Selector function, calls the individual cac features according to player's class settings
// Info: Called every time player spawns during loadout stage
cac_selector()
{
	perks = self.specialty;

	/*
	self.detectExplosives = false;

	if ( self _hasPerk( "specialty_detectexplosive" ) )
		self.detectExplosives = true;

	maps\mp\gametypes\_weapons::setupBombSquad();
	*/
}


givePerksAfterSpawn()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	spawnPerks = [];

	// Perks to add on spawn
	if ( !self _hasPerk("specialty_blindeye" ) )
	{
		self givePerk( "specialty_blindeye", false );
		spawnPerks[spawnPerks.size] = "specialty_blindeye";
	}
	
	if ( !self _hasPerk( "specialty_gpsjammer" ) )
	{
		self givePerk( "specialty_gpsjammer", false );
		spawnPerks[spawnPerks.size] = "specialty_gpsjammer";
	}

	// Perks to remove after the spawn timer is up
	if ( spawnPerks.size > 0 )
	{
		self.spawnPerk = true;
			
		while( self.avoidKillstreakOnSpawnTimer > 0 )
		{
			self.avoidKillstreakOnSpawnTimer -= 0.05;
			wait( 0.05 );
		}

		foreach ( perk in spawnPerks ) 
		{
			self _unsetPerk( perk );
		}
		
		self.spawnPerk = false;
		self notify ( "starting_perks_unset" );		
	}
}

getPerkIcon( perkName )
{
	return TableLookup( PERK_STRING_TABLE, PERK_REF_COLUMN, perkName, PERK_ICON_COLUMN );
}

getPerkName( perkName )
{
	return TableLookupIString( PERK_STRING_TABLE, PERK_REF_COLUMN, perkName, PERK_NAME_COLUMN );
}

updateActivePerks( eInflictor, attacker, victim, iDamage, sMeansOfDeath )
{
	// Make sure the perks are not triggered by killstreaks (exceptions are player based ones - i.e. Juggernauts)
	if ( IsDefined ( eInflictor ) && IsPlayer( eInflictor ) && IsDefined( attacker ) && IsPlayer( attacker ) && attacker != victim )
	{
		// See if the attacker has the Trigger Happy ability
		if( attacker _hasPerk("specialty_triggerhappy") )
			attacker thread maps\mp\perks\_perkfunctions::setTriggerHappyInternal();
		
		// See if the attacker has the Boom ability
		if( attacker _hasPerk("specialty_boom") )
			victim thread maps\mp\perks\_perkfunctions::setBoomInternal( attacker );
		
		// See if the attacker has the Bloodrush ability
		if( attacker _hasPerk("specialty_bloodrush") )
			attacker thread maps\mp\perks\_perkfunctions::setBloodrushInternal();
				
		// See if the attacker has the Deadeye ability
		if( attacker _hasPerk("specialty_deadeye") )
			attacker.deadeyeKillCount++;
		
		// see if the attacker has the fastRecharge ability
		attacker_pers_abilityRecharging = attacker.pers[ "abilityRecharging" ];
		if( IsDefined( attacker_pers_abilityRecharging ) && attacker_pers_abilityRecharging )
			attacker notify( "abilityFastRecharge" );
		
		// see if the attacker has the extraTime ability
		attacker_pers_abilityOn = attacker.pers[ "abilityOn" ];
		if( IsDefined( attacker_pers_abilityOn ) && attacker_pers_abilityOn )
			attacker notify( "abilityExtraTime" );
	}
}

