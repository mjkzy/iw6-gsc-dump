#include maps\mp\killstreaks\_killstreaks;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{	
	initKillstreakData();

	level.killstreakFuncs = [];
	level.killstreakSetupFuncs = [];
	level.killstreakWeapons = [];

	thread maps\mp\killstreaks\_uav::init();
	// thread maps\mp\killstreaks\_airstrike::init();	// not using airstrikes for iw6
	thread maps\mp\killstreaks\_plane::init();	// eventually, move this above airstrike and simplify the existing killstreaks
	thread maps\mp\killstreaks\_airdrop::init();
	thread maps\mp\killstreaks\_helicopter::init();
	
	thread maps\mp\killstreaks\_nuke::init();
	thread maps\mp\killstreaks\_a10::init();
	thread maps\mp\killstreaks\_portableAOEgenerator::init();
	thread maps\mp\killstreaks\_ims::init();
	thread maps\mp\killstreaks\_perkstreaks::init();
	thread maps\mp\killstreaks\_juggernaut::init();
	thread maps\mp\killstreaks\_ball_drone::init();
	thread maps\mp\killstreaks\_autosentry::init();
	thread maps\mp\killstreaks\_remotemissile::init();
	thread maps\mp\killstreaks\_deployablebox::init();
	thread maps\mp\killstreaks\_deployablebox_vest::init();
	thread maps\mp\killstreaks\_deployablebox_gun::init();	// careful, _gun and _ammo use the same setup
	thread maps\mp\killstreaks\_heliSniper::init();
	thread maps\mp\killstreaks\_helicopter_pilot::init();
	thread maps\mp\killstreaks\_vanguard::init();
	thread maps\mp\killstreaks\_uplink::init();
	thread maps\mp\killstreaks\_droneHive::init();
	thread maps\mp\killstreaks\_jammer::init();
	thread maps\mp\killstreaks\_air_superiority::init();
	thread maps\mp\killstreaks\_odin::init();
	thread maps\mp\killstreaks\_highValueTarget::init();
	thread maps\mp\killstreaks\_AALauncher::init();
	
	//	all killstreak weapons that kill, this is used for weapon to killstreak association
	level.killstreakWeildWeapons = [];
	level.killstreakWeildWeapons["sentry_minigun_mp"]				= "sentry";						// Sentry Gun
	level.killstreakWeildWeapons["hind_bomb_mp"]					= "helicopter";					// Attack Helicopter, Missile
	level.killstreakWeildWeapons["hind_missile_mp"]					= "helicopter";					// Attack Helicopter, Missile
	level.killstreakWeildWeapons["cobra_20mm_mp"]					= "helicopter";					// Attack Helicopter
	level.killstreakWeildWeapons["nuke_mp"]							= "nuke";						// Nuke		
	level.killstreakWeildWeapons["manned_littlebird_sniper_mp"]		= "heli_sniper";				// heli sniper	
	level.killstreakWeildWeapons["iw6_minigunjugg_mp"]				= "airdrop_juggernaut";			// juggernaut assault primary	
	level.killstreakWeildWeapons["iw6_p226jugg_mp"]					= "airdrop_juggernaut";			// juggernaut assault secondary	
	level.killstreakWeildWeapons["mortar_shelljugg_mp"]				= "airdrop_juggernaut";			// juggernaut assault equipment
	level.killstreakWeildWeapons["iw6_riotshieldjugg_mp"]			= "airdrop_juggernaut_recon";	// juggernaut support primary
	level.killstreakWeildWeapons["iw6_magnumjugg_mp"]				= "airdrop_juggernaut_recon";	// juggernaut support secondary	
	level.killstreakWeildWeapons["smoke_grenadejugg_mp"]			= "airdrop_juggernaut_recon";	// juggernaut support offhand
	level.killstreakWeildWeapons["iw6_knifeonlyjugg_mp"]			= "airdrop_juggernaut_maniac";	// juggernaut maniac primary
	level.killstreakWeildWeapons["throwingknifejugg_mp"]			= "airdrop_juggernaut_maniac";	// juggernaut maniac equipment
	level.killstreakWeildWeapons["deployable_vest_marker_mp"]		= "deployable_vest";			// deployable vest
	level.killstreakWeildWeapons["deployable_weapon_crate_marker_mp"] = 	"deployable_ammo";			// deployable vest
	level.killstreakWeildWeapons["heli_pilot_turret_mp"]			= "heli_pilot";					// heli pilot
	level.killstreakWeildWeapons["guard_dog_mp"]					= "guard_dog";					// guard dog
	level.killstreakWeildWeapons["ims_projectile_mp"]				= "ims";						// ims
	level.killstreakWeildWeapons["ball_drone_gun_mp"]				= "ball_drone_backup";			// backup buddy
	level.killstreakWeildWeapons["drone_hive_projectile_mp"]		= "drone_hive";					// drone hive
	level.killstreakWeildWeapons["switch_blade_child_mp"]			= "drone_hive";					// drone hive
	level.killstreakWeildWeapons["iw6_maaws_mp"]					= "aa_launcher";				// aa launcher
	level.killstreakWeildWeapons["iw6_maawschild_mp"]				= "aa_launcher";				// aa launcher
	level.killstreakWeildWeapons["iw6_maawshoming_mp"]				= "aa_launcher";				// aa launcher
	level.killstreakWeildWeapons["killstreak_uplink_mp"]			= "uplink";						// uplink
	level.killstreakWeildWeapons["odin_projectile_large_rod_mp"]	= "odin_assault";				// odin assault
	level.killstreakWeildWeapons["odin_projectile_small_rod_mp"]	= "odin_assault";				// odin assault
	level.killstreakWeildWeapons["iw6_gm6helisnipe_mp"]				= "heli_sniper";				// heli sniper (Extra entry for stat tracking)
	level.killstreakWeildWeapons["iw6_gm6helisnipe_mp_gm6scope"]	= "heli_sniper";				// heli sniper
	level.killstreakWeildWeapons["aamissile_projectile_mp"]			= "air_superiority";			// air superiority
	level.killstreakWeildWeapons["airdrop_marker_mp"]				= "airdrop_assault";			// airdrop marker
	level.killstreakWeildWeapons["remote_tank_projectile_mp"]		= "vanguard";					// vanguard
	level.killstreakWeildWeapons["killstreak_vanguard_mp"]			= "vanguard";					// vanguard
	level.killstreakWeildWeapons["agent_mp"]						= "agent";						// squad member, even jugg from odin and loki
	level.killstreakWeildWeapons["agent_support_mp"] 				= "recon_agent";				// support squad member (recon agent)
	level.killstreakWeildWeapons[ "iw6_axe_mp" ] 					= "juggernaut_swamp_slasher";	// level killstreak for mp_swamp
	level.killstreakWeildWeapons[ "venomxgun_mp" ] 					= "venom_x_gun";				// Extinction gun for mp_dome_ns. Not technically a killstreak
	level.killstreakWeildWeapons[ "venomxproj_mp" ] 				= "venom_x_projectile";			// Projectile for Extinction gun
	level.killstreakWeildWeapons[ "iw6_predatorcannon_mp" ]			= "juggernaut_predator";		// level killstreak for mp_battery3
	level.killstreakWeildWeapons[ "iw6_predatorsuicide_mp" ]		= "juggernaut_predator";		// level killstreak for mp_battery3
	level.killstreakWeildWeapons[ "volcano_rock_mp" ]				= "volcano";					// level killstreak for mp_battery3
	level.killstreakWeildWeapons["ac130_105mm_mp"]					= "ac130";						// AC130 level killstreak for mp_favela_iw6
	level.killstreakWeildWeapons["ac130_40mm_mp"]					= "ac130";						// AC130 level killstreak for mp_favela_iw6
	level.killstreakWeildWeapons["ac130_25mm_mp"] 					= "ac130";						// AC130 level killstreak for mp_favela_iw6
	level.killstreakWeildWeapons[ "iw6_mariachimagnum_mp_akimbo" ] 	= "juggernaut_death_mariachi";	// level killstreak for mp_zulu
	level.killstreakWeildWeapons[ "harrier_20mm_mp" ]				= "harrier_airstrike";					// level killstreak for mp_conflict
	level.killstreakWeildWeapons[ "artillery_mp" ]					= "harrier_airstrike";					// level killstreak for mp_conflict
	
	if(IsDefined(level.mapCustomKillstreakFunc))
		[[ level.mapCustomKillstreakFunc ]]();
	
	level.killstreakRoundDelay = getIntProperty( "scr_game_killstreakdelay", 8 );

	level thread onPlayerConnect();
}
