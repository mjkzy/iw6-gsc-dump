#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_damage;
#include maps\mp\agents\_agent_utility;
#include common_scripts\utility;
#include maps\mp\alien\_utility;
#include maps\mp\alien\_collectibles;
#include maps\mp\alien\_perk_utility;

DEFAULT_REGEN_CAP = 1.0; //The max percent of player's max health that he is able to regen back up to
DEFAULT_REGEN_ACTIVATE_TIME = 3.0; //After player is damaged, the amount of time (in sec) before the health regen activates
DEFAULT_WAIT_TIME_BETWEEN_REGEN = 0.35; //When health regen is activated, the wait time between each health increase
DEFAULT_REGEN_HEALTH_AMOUNT = 1;  //The amount of health that is being added for each regen increases

//=======================================================
//				main
//=======================================================
main()
{
	if(getdvar("mapname") == "mp_background")
		return;
	
	maps\mp\alien\_globallogic::init();
	maps\mp\gametypes\_callbacksetup::SetupCallbacks();
	maps\mp\alien\_globallogic::SetupCallbacks();
	level.customprematchPeriod = ::alien_customprematchperiod;

	if ( isUsingMatchRulesData() )
	{
		level.initializeMatchRules = ::initializeMatchRules;
		[[level.initializeMatchRules]]();
		level thread reInitializeMatchRulesOnMigration();		
	}
	else
	{
		registerRoundSwitchDvar( level.gameType, 0, 0, 9 );
		registerTimeLimitDvar( level.gameType, 0 );
		registerScoreLimitDvar( level.gameType, 500 );
		registerRoundLimitDvar( level.gameType, 1 );
		registerWinLimitDvar( level.gameType, 1 );
		registerNumLivesDvar( level.gameType, 0 );
		registerHalfTimeDvar( level.gameType, 0 );
		
		level.matchRules_damageMultiplier = 0;
		level.matchRules_vampirism = 0;
		level.prematchPeriod = 0;
	}
	
	if ( level.matchRules_damageMultiplier || level.matchRules_vampirism )
		level.modifyPlayerDamage = maps\mp\gametypes\_damage::gamemodeModifyPlayerDamage;

	level.teamBased = true;
	level.getTeamAssignment = 					::getTeamAssignment;
	level.onPrecacheGameType = 					::onPrecacheGameType;
	level.killStreakInit =						::killStreakInit; 
	level.onStartGameType = 					::onStartGameType;
	level.onSpawnPlayer = 						::onSpawnPlayer;
	level.getSpawnPoint = 						::getSpawnPoint;
	level.endGame_Alien =                       ::AlienEndGame;
	level.forceEndGame_Alien =                  ::AlienForceEndGame;
	level.onNormalDeath = 						maps\mp\alien\_death::onNormalDeath;
	level.onPlayerKilled = 						maps\mp\alien\_death::onPlayerKilled;
	level.onTimeLimit = 						::onTimeLimit;
	level.onXPEvent = 							::onXPEvent;
	level.bypassClassChoiceFunc = 				::bypassClassChoiceFunc;
	level.callbackPlayerLastStand = 			maps\mp\alien\_laststand::Callback_PlayerLastStandAlien;
	level.callbackPlayerDamage = 				maps\mp\alien\_damage::Callback_AlienPlayerDamage;
	level.aliens_make_entity_sentient_func = 	::alien_make_entity_sentient;
	level.aliens_give_currency_func = 			maps\mp\alien\_persistence::give_player_currency;
	level.exploImpactMod =						.1;	// increased explosive ammo damage by this %	
	level.shotgunDamageMod =					.1;		// increased shotgun ammo damage by this %	
	level.armorPiercingMod =					.2;
	level.custom_giveloadout = 					::custom_giveloadout;
	level.boxCaptureThink_alien_func  =			::boxCaptureThink_alien_func;
	level.regenHealthMod = 						2; // Adrenaline Box will apply the fast regen perk
	level.damageFeedbackNoSound	=				true; // disables damage feedback sound
	level.isChaosMode =                         GetDvarInt( "scr_chaos_mode", 0 );
	level.hardcoreMode = 						GetDvarInt( "scr_aliens_hardcore" );
	level.ricochetDamage = 						GetDvarInt( "scr_aliens_ricochet" );
	level.infiniteMode = 						GetDvarInt( "scr_aliens_infinite" );
	level.casualMode = 							GetDvarInt( "scr_aliens_casual");
	level.playerMeleeStunRegenTime	=			4000;	//default time between melee stun events	
	
	SetDvarIfUninitialized( "alien_cover_node_retreat", 0 );
	SetDvarIfUninitialized( "alien_retreat_towards_spawn", 1 );
	
	if ( is_hardcore_mode() )
		SetOmnvar( "ui_aliens_hardcore", true );
	
	if ( is_chaos_mode() )
	{
		SetOmnvar( "ui_alien_chaos", true );
		maps\mp\alien\_chaos::set_chaos_area();
	}
	
	if ( !isDefined ( level.ricochetDamageMax ) )
  		level.ricochetDamageMax = 25;
	
	//used for alien_armory lockers
	level.getNodeArrayFunction 		= ::GetNodeArray;	
	
	// For the alien retreat node rating logic scheduled traces
	level.nodeFilterTracesTime = 0;
	level.nodeFilterTracesThisFrame = 0;	
	
	level.maxAlienAttackerDifficultyValue = 10.0;	// max value of aliens that can attack a given target
	setAlienLoadout();
	healthRegenInit();
	
	maps\mp\agents\alien\_alien_anim_utils::initAlienAnims();
	
	level thread onPlayerConnect();
	level thread maps\mp\alien\_music_and_dialog::init();	
	
	level thread maps\mp\alien\_deployablebox_functions::specialammo_init();
	level thread maps\mp\alien\_deployablebox_functions::deployables_init();
	
	level thread maps\mp\alien\_autosentry_alien::init();
	
	self maps\mp\alien\_outline_proto::outline_init();
	
	self maps\mp\alien\_ffotd::init();
	
	array_thread( getEntArray( "misc_turret", "classname" ), maps\mp\alien\_trap::turret_monitorUse );
}

healthRegenInit()
{
	level.healthRegenDisabled = false;
	level.healthRegenCap = GetDvarFloat( "alien_playerHealthRegenCap", DEFAULT_REGEN_CAP );
}

//=======================================================
//				getTeamAssignment
//=======================================================
getTeamAssignment()
{
	return "allies";
}


//=======================================================
//				initializeMatchRules
//=======================================================
initializeMatchRules()
{
	//	set common values
	setCommonRulesFromMatchRulesData();
	
	//	set everything else (private match options, default .cfg file values, and what normally is registered in the 'else' below)
	SetDynamicDvar( "scr_aliens_roundswitch", 0 );
	registerRoundSwitchDvar( "aliens", 0, 0, 9 );
	SetDynamicDvar( "scr_aliens_roundlimit", 1 );
	registerRoundLimitDvar( "aliens", 1 );		
	SetDynamicDvar( "scr_aliens_winlimit", 1 );
	registerWinLimitDvar( "aliens", 1 );			
	SetDynamicDvar( "scr_aliens_halftime", 0 );
	registerHalfTimeDvar( "aliens", 0 );
		
	SetDynamicDvar( "scr_aliens_promode", 0 );
}

//=======================================================
//				onPrecacheGameType
//=======================================================
onPrecacheGameType()
{
	precacheString( &"ALIEN_COLLECTIBLES_SELF_REVIVED" );
	
	// airdrop bomb strings
	precacheString( &"ALIEN_COLLECTIBLES_PLANT_BOMB" );		// Plant bomb.
	precacheString( &"ALIEN_COLLECTIBLES_NO_BOMB" );		// You don't have the bomb.
	precacheString( &"ALIEN_COLLECTIBLES_GO_PLANT_BOMB" );	// Plant the bomb at one of the Lungs.
	precacheString( &"ALIEN_COLLECTIBLES_PICKUP_BOMB" );	// (X) Carry Bomb
	precacheString( &"ALIEN_COLLECTIBLES_REPAIR_DRILL" );
	PreCacheString( &"ALIEN_COLLECTIBLES_ACTIVATE_NUKE" );
	PreCacheString( &"ALIEN_COLLECTIBLES_COUNTDOWN_NUKE" );
	precacheString( &"ALIEN_COLLECTIBLES_DRILL_DESTROYED" );
	
	// temp fx for teleportation
	level._effect[ "alien_teleport" ] 		= LoadFX( "vfx/test/vfx_alien_teleport" );
	level._effect[ "alien_teleport_dist" ] 	= LoadFX( "vfx/test/vfx_alien_teleport_dist" );
	
	//temp fx for Flaming Riotshield
	level._effect[ "Riotshield_fire" ]	 	= loadfx( "vfx/gameplay/alien/vfx_alien_on_fire");
	
	//arcade death for easter egg
	level._effect[ "arcade_death" ]	 		= loadfx( "vfx/moments/alien/vfx_alien_arcade_death" );
	
	// fx for Queen
	maps\mp\agents\alien\_alien_elite::load_queen_fx();
	
	// fx for spitter
	maps\mp\agents\alien\_alien_spitter::load_spitter_fx();
	
	// fx for escape climb out of ground
	level._effect[ "drone_ground_spawn" ]	= LoadFX( "vfx/gameplay/alien/vfx_alien_drone_ground_spawn" );
	
	//fx for deployablebox
	level._effect[ "deployablebox_crate_destroy" ] 	= LoadFX( "vfx/test/vfx_alien_teleport" );
	
	// fx for minion
	maps\mp\agents\alien\_alien_minion::load_minion_fx();
	
	level._effect[ "bomb_impact" ]	 				= loadfx( "vfx/ambient/sparks/electrical_sparks");
	level._effect[ "shield_impact" ]	 			= Loadfx( "fx/impacts/large_metalhit_1" );
	level._effect[ "airdrop_crate_destroy" ] 		= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_ims_explosion" );  //used by movers.gsc
	level._effect[ "melee_blood" ]					= LoadFx( "vfx/gameplay/impacts/small/impact_alien_flesh_hit_b_fatal" );

	//turret
	PreCacheTurret( "turret_minigun_alien" );
	
	if ( alien_mode_has( "airdrop" ) ) 
	{
		// airdrop supply chopper
		PrecacheVehicle( "littlebird_alien" );
		PrecacheVehicle( "nh90_alien" );
		
		// drill animations
		PrecacheMpAnim( "alien_drill_enter" ); // unfold
		PrecacheMpAnim( "alien_drill_loop" ); // runs
		PrecacheMpAnim( "alien_drill_end" ); // folds
		
		PrecacheMpAnim( "alien_drill_operate_enter" ); // breaking
		PrecacheMpAnim( "alien_drill_nonoperate" ); // broke
		PrecacheMpAnim( "alien_drill_operate_end" ); // repaired
		
		PrecacheMpAnim( "alien_drill_attack_drill_F_enter" );
		PrecacheMpAnim( "alien_drill_attack_drill_F_exit" );
		PrecacheMpAnim( "alien_drill_attack_drill_F_loop" );
		PrecacheMpAnim( "alien_drill_attack_drill_L_enter" );
		PrecacheMpAnim( "alien_drill_attack_drill_L_exit" );
		PrecacheMpAnim( "alien_drill_attack_drill_L_loop" );
		PrecacheMpAnim( "alien_drill_attack_drill_R_enter" );
		PrecacheMpAnim( "alien_drill_attack_drill_R_exit" );
		PrecacheMpAnim( "alien_drill_attack_drill_R_loop" );
		
		PrecacheMpAnim( "alien_goon_drill_attack_drill_F_enter" );
		PrecacheMpAnim( "alien_goon_drill_attack_drill_F_loop" );
		PrecacheMpAnim( "alien_goon_drill_attack_drill_F_exit" );
		PrecacheMpAnim( "alien_goon_drill_attack_drill_R_enter" );
		PrecacheMpAnim( "alien_goon_drill_attack_drill_R_loop" );
		PrecacheMpAnim( "alien_goon_drill_attack_drill_R_exit" );
		PrecacheMpAnim( "alien_goon_drill_attack_drill_L_enter" );
		PrecacheMpAnim( "alien_goon_drill_attack_drill_L_loop" );
		PrecacheMpAnim( "alien_goon_drill_attack_drill_L_exit" );
		
		PrecacheMpAnim( "alien_sentry_attack_sentry_front_enter" );
		PrecacheMpAnim( "alien_sentry_attack_sentry_front_exit" );
		PrecacheMpAnim( "alien_sentry_attack_sentry_front_loop" );
		PrecacheMpAnim( "alien_sentry_attack_sentry_side_r_enter" );
		PrecacheMpAnim( "alien_sentry_attack_sentry_side_r_exit" );
		PrecacheMpAnim( "alien_sentry_attack_sentry_side_r_loop" );
		PrecacheMpAnim( "alien_sentry_attack_sentry_side_l_enter" );
		PrecacheMpAnim( "alien_sentry_attack_sentry_side_l_exit" );
		PrecacheMpAnim( "alien_sentry_attack_sentry_side_l_loop" );
		
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_F_enter" );
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_F_exit" );
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_F_loop" );
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_L_enter" );
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_L_exit" );
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_L_loop" );
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_R_enter" );
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_R_exit" );
		PrecacheMpAnim( "alien_goon_sentry_attack_sentry_R_loop" );
	}
	
	if ( maps\mp\alien\_intro_sequence::intro_sequence_enabled() )
	{
		maps\mp\alien\_intro_sequence::intro_sequence_precache();
	}
}

//=======================================================
//				onStartGameType
//=======================================================
onStartGameType()
{
	
	if ( isDefined ( level.custom_onStartGameTypeFunc ) )
	{
		[[level.custom_onStartGameTypeFunc]]();
	}
	
	SetNoJIPTime( true );
	
	setClientNameMode("auto_change");

	thread mp_ents_clean_up();
	
/#
	level thread maps\mp\alien\_debug::runStartPoint();
	level thread maps\mp\alien\_debug::debugDvars();
#/
	
	level.disableForfeit = true;
	
	//Per alien, the size of the array that hold the recent damage info (self.recentDamages)
	level.damageListSize = 20;
	
	setObjectiveText( "allies", &"ALIEN_OBJECTIVES_ALIENS" );
	setObjectiveText( "axis", &"ALIEN_OBJECTIVES_ALIENS" );
	
	if ( level.splitscreen )
	{
		setObjectiveScoreText( "allies", &"ALIEN_OBJECTIVES_ALIENS" );
		setObjectiveScoreText( "axis", &"ALIEN_OBJECTIVES_ALIENS" );
	}
	else
	{
		setObjectiveScoreText( "allies", &"ALIEN_OBJECTIVES_ALIENS_SCORE" );
		setObjectiveScoreText( "axis", &"ALIEN_OBJECTIVES_ALIENS_SCORE" );
	}
	
	setObjectiveHintText( "allies", &"ALIEN_OBJECTIVES_ALIENS_HINT" );
	setObjectiveHintText( "axis", &"ALIEN_OBJECTIVES_ALIENS_HINT" );
	
	maps\mp\alien\_persistence::BBData_init();
	maps\mp\alien\_persistence::rank_init();
	maps\mp\alien\_persistence::register_EoG_to_LB_playerdata_mapping();
	maps\mp\alien\_progression::main();

	init_threatbiasgroups();
	
/#
	if ( GetDvarInt( "scr_aliennavtest" ) == 1 )
	{
		level thread maps\mp\alien\_debug::alienNavTest();
	}
	
	if ( maps\mp\alien\_debug::spawn_test_enable() )
	{
		level thread maps\mp\alien\_debug::run_spawn_test();
	}
	
	if ( maps\mp\alien\_debug::player_spawn_test_enable() )
	{
		level thread maps\mp\alien\_debug::player_spawn_test();
	}
	
	if ( GetDvarInt( "scr_aliennogame" ) == 1 )
	{
		maps\mp\alien\_utility::alien_mode_enable( "nogame" );
	}
	
	if ( GetDvarInt( "scr_alienkillresource" ) == 1 )
	{
		maps\mp\alien\_utility::alien_mode_enable( "kill_resource" );
	}
#/	
	// init collectibles system
	if ( alien_mode_has( "collectible" ) )
		maps\mp\alien\_collectibles::pre_load();	

	// init the deployable_currency amounts
	maps\mp\alien\_deployablebox_functions::pre_load();
	
	if ( alien_mode_has( "scenes" ) )
	{
	    // init scripte alien spawners and scene pathing
		maps\mp\alien\_spawnlogic::alien_scene_init();
	}
	
	// mist init and run
	maps\mp\alien\_alien_fx::main();
		
	maps\mp\alien\_spawnlogic::alien_health_per_player_init();
	
	initSpawns();
	
	allowed[0] = level.gameType;	
	maps\mp\gametypes\_gameobjects::main( allowed );
	
	// Init starting cycle
	level.current_cycle_num = 0;
	
	level.num_hive_destroyed = 0;
	
/#
	if ( GetDvarInt( "scr_startingcycle" ) > 0 )
	{
		level.current_cycle_num = GetDvarInt( "scr_startingcycle" );
	}
#/
	
/#
	if ( alien_mode_has( "nogame" ) )
	{
		thread maps\mp\alien\_debug::runAliens();
	}
#/		
		
	
/#
	if ( GetDvarInt( "debug_pet_alien", 0 ) > 0 )
	{
		// spawn ally pet alien
		thread spawnAllyPet( "goon", GetDvarInt( "debug_pet_alien", 0 ) );
	}
#/
	
	// Trap Inits 
	level thread maps\mp\alien\_trap::traps_init();
	
	// Team hive performance
	maps\mp\alien\_gamescore::init_gamescore();
	
	level.spitter_gas_cloud_count = 0;
	
	level.gameTweaks["spectatetype"].value = 1;
	
	// init pillage system
	if ( should_enable_pillage() )
		thread maps\mp\alien\_pillage::pillage_init();
	
	// init challenge system
	if ( alien_mode_has( "challenge" ) )
		maps\mp\alien\_challenge::init_challenge();
	
	// init special unlock system
	maps\mp\alien\_unlock::init_unlock();
	
	// init prestige nerf system
	maps\mp\alien\_prestige::init_prestige();
	
	maps\mp\alien\_hud::init();
	
	level.lowerMessageFont = "objective";
	if ( level.splitscreen  )
	{
		level.lowerTextFontSize = 1.35;
	}
	if ( !level.console )
		level.lowerTextFontSize = 1;
	
	level.teamTweaks["fftype"].value = 1;
	
	maps\mp\alien\_death::kill_trigger_spawn_init();
	
	//self thread test_challenge( "kill_leper" );
	
	level thread handle_nondeterministic_entities();
	
	level thread maps\mp\alien\_trap::easter_egg_lodge_sign();
	
	//XP Scalar
	level.xpScale = getDvarInt( "scr_aliens_xpscale" );
	level.xpScale = min( level.xpScale, 4 );
	level.xpScale = max( level.xpScale, 0 );

	maps\mp\alien\_alien_matchdata::start_game_type();
	
	maps\mp\alien\_ffotd::onStartGameType();	
	
	level thread run_encounters();
}

should_enable_pillage()
{
	if ( is_chaos_mode() )
		return false;
		
	return alien_mode_has( "pillage" );
}

// We need to spawn our nondeterministic entities a few seconds after the game starts
// In order to use the game's baseline state
// Any non-deterministic entities must be initially spawned or deleted here, not earlier
handle_nondeterministic_entities()
{
/#
	if ( maps\mp\alien\_debug::startPointEnabled() )
		return;
	
	if ( maps\mp\alien\_debug::spawn_test_enable() )
		return;
#/	
	wait 5;
	
	handle_nondeterministic_entities_internal();
	level notify( "spawn_nondeterministic_entities" );
}

handle_nondeterministic_entities_internal()
{
	// Spawn loot and collectibles
	if ( alien_mode_has( "collectible" ) )
		maps\mp\alien\_collectibles::post_load();
	
	// Remove unused hives
	if ( !alien_mode_has( "nogame" ) && alien_mode_has( "wave" ) && maps\mp\alien\_spawnlogic::use_spawn_director() )
	{
		maps\mp\alien\_hive::remove_unused_hives( level.removed_hives );
		level.removed_hives = undefined;
	}
	
	if ( is_chaos_mode() )
		maps\mp\alien\_chaos::create_alien_eggs();
}

/*
test_challenge( challenge_name )
{
	while ( level.players.size == 0 )
	{
		wait 1;
	}
	
	maps\mp\alien\_challenge::activate_new_challenge( challenge_name );
}
*/

//===========================================
// 			spawnAllyPet
//===========================================

spawnAllyPet( type, count, origin, owner, spawn_angles, isTrapPet  )
{
	wait 0.05; // padding
	
	spawnType = "wave " + type;
	for( i=0; i<count; i++ )
	{
		this_origin = origin;
		// Drop him to ground if he isn't in a scripted state
		if ( spawnType == "wave elite" )
		{
			results = BulletTrace( origin + ( 0,0,128 ), origin + (0,0,-128), false );
			if ( results["fraction"] == 0 || results["fraction"] == 1 )
				continue;

			this_origin = results["position"];
		}		
		
		ang 				= spawn_angles;
		loc					= this_origin;
		alien 				= maps\mp\gametypes\aliens::addAlienAgent( "allies", loc, ang, spawnType );
		alien.pet 			= true;
		alien.owner 		= owner;
		alien.petFollowDist = 1024;
		alien.threatbias	= -800;
			
		if ( type == "goon" )
		{
			alien.maxhealth 	= Int( 100 * level.alien_health_per_player_scalar[ level.players.size ] );
			alien.health 		= Int( 100 * level.alien_health_per_player_scalar[ level.players.size ] );
		}
		else if ( type == "brute" )
		{
			alien.maxhealth 	= Int( 200 * level.alien_health_per_player_scalar[ level.players.size ] );
			alien.health 		= Int( 200 * level.alien_health_per_player_scalar[ level.players.size ] );
		}
		else if ( type == "spitter" )		
		{
			alien.maxhealth 	= Int( 150 * level.alien_health_per_player_scalar[ level.players.size ] );
			alien.health 		= Int( 150 * level.alien_health_per_player_scalar[ level.players.size ] ) ;
		}
		else if ( type == "locust" )		
		{
			alien.maxhealth 	= Int( 250 * level.alien_health_per_player_scalar[ level.players.size ] );
			alien.health 		= Int( 250 * level.alien_health_per_player_scalar[ level.players.size ] ) ;
		}
		else if ( type == "elite" )		
		{
			alien.maxhealth 	= Int( 350 * level.alien_health_per_player_scalar[ level.players.size ] );
			alien.health 		= Int( 350 * level.alien_health_per_player_scalar[ level.players.size ] ) ;
		}
		
		if ( is_true( isTrapPet ) )
		{
			alien.maxhealth = int( alien.maxhealth * 1.25 );
			alien.health 	= int( alien.maxhealth * 1.25 );
		}
	
		alien set_alien_emissive( 0.5, 0.0 );
		
		if ( owner maps\mp\alien\_persistence::is_upgrade_enabled( "master_scavenger_upgrade" ) )
		{
			alien.upgraded = true;
			maps\mp\alien\_outline_proto::enable_outline( alien, 2, false );
		}
		else	
			maps\mp\alien\_outline_proto::enable_outline( alien, 3, false );
		
		alien SetScriptablePartState( "body", "pet" );
		
		if ( isDefined( self.entityHeadIcon ) )
			self.entityHeadIcon destroy();
		
		alien thread ally_pet_time_out( isTrapPet );
		alien thread kill_alien_on_owner_disconnect( owner );
	}
}

ally_pet_time_out( isTrapPet )
{
	level endon( "game_ended" );
	self endon( "death" );
	
	PET_TIME_OUT_SEC = 180;
	
	if ( is_true ( isTrapPet ) )
		PET_TIME_OUT_SEC = PET_TIME_OUT_SEC * 1.25;
	
	wait( PET_TIME_OUT_SEC );
	
	PlayFX( level._effect[ "alien_minion_explode" ], self.origin + ( 0, 0, 32 ) );
	self suicide();
}

kill_alien_on_owner_disconnect( owner )
{
	self endon( "death" );
	
	owner waittill( "disconnect" );
	
	PlayFX( level._effect[ "alien_minion_explode" ], self.origin + ( 0, 0, 32 ) );
	self suicide();
}

//===========================================
// 			onPlayerConnect
//===========================================
onPlayerConnect()
{
	while( true )
	{
		level waittill( "connected", player );
		
		if( !IsAI( player ) )
		{
			if ( is_chaos_mode() )
				maps\mp\alien\_chaos::chaos_onPlayerConnect( player );
			
			player maps\mp\alien\_alien_matchdata::on_player_connect();
			
			if ( isdefined( player.connecttime ) )
				player.connect_time = player.connecttime;
			else
				player.connect_time = gettime();
			
			player maps\mp\alien\_prestige::init_player_prestige();
			// init persistence data
			player maps\mp\alien\_persistence::player_persistence_init();
			
			player thread weapon_change_monitor();
			player thread threat_bias_grouping();
			player thread player_init_health_regen();
			player maps\mp\alien\_hud::init_player_hud_onconnect();
			player maps\mp\alien\_gamescore::init_player_score();
			player thread maps\mp\alien\_progression::player_setup();
			player maps\mp\alien\_achievement::init_player_achievement();
			player maps\mp\alien\_unlock::init_player_unlock();
			player thread maps\mp\alien\_persistence::play_time_monitor();
			player initial_spawn_pos_override();
			
			if ( !is_casual_mode() )
				player SetClientOmnvar( "allow_write_leaderboards", 1 );
			else
				player SetClientOmnvar( "allow_write_leaderboards", 0  );			
			
			// set player's threat to max during escape sequence, this is done to existing or joining players
			if ( flag_exist( "hives_cleared" ) && flag( "hives_cleared" ) )
			{
				player.threatbias = 100000;
				player thread maps\mp\alien\_persistence::set_game_state( "escaping" );
			}
			else
			{
				if ( !isdefined( level.cycle_count ) || level.cycle_count < 1 )
				{
					player thread maps\mp\alien\_persistence::set_game_state( "pregame" );
				}
				else if ( isdefined( level.cycle_count ) && level.cycle_count == 1 )
				{
					player thread maps\mp\alien\_persistence::set_game_state( "prehive" );
				}
				else
				{
					player thread maps\mp\alien\_persistence::set_game_state( "progressing" );
				}
			}
			
			if ( alien_mode_has( "kill_resource" ) )
			{
				player thread player_init_assist_bonus();
			}
			
			// catch up to other player's skill points
			hotjoin_skill_points = get_hotjoin_skill_points();
			if ( hotjoin_skill_points > 0 )
				player maps\mp\alien\_persistence::give_player_points( hotjoin_skill_points );
			
			player resetUIDvarsOnConnect();	

			if ( alien_mode_has( "outline" ) )
				player thread maps\mp\alien\_outline_proto::outline_monitor();
			
			if ( alien_mode_has ( "challenge" ) )
			{
				if ( maps\mp\alien\_challenge::current_challenge_exist() && alien_mode_has( "challenge" ) )
				{
					player thread maps\mp\alien\_challenge::handle_challenge_hotjoin ();
				}
			}
			
			//hint text for special weapons/items
			player thread special_weapon_hints();
			
			//handle the use button prompt when the player is holding a deployable
			player thread enable_disable_usability_monitor();	
			player thread monitorDisownKillstreaks();
			
			//show the hints when a player is near a hive to plant the drill
			if ( flag_exist( "drill_drilling" ) )
				player thread maps\mp\alien\_drill::check_for_player_near_hive_with_drill();
			
			//for the intro
			player thread maps\mp\alien\_hud::intro_black_screen();
			
			if ( is_true ( level.introscreen_done ) )
			{
				player thread player_hotjoin();
			}
			
			player maps\mp\alien\_ffotd::onPlayerConnect();
		}
	}
}

initial_spawn_pos_override()
{
	if ( isDefined( level.initial_spawn_loc_override_func ) )
		self [[level.initial_spawn_loc_override_func]]();
}

get_hotjoin_skill_points()
{
	if ( isDefined( level.hotjoin_skill_points_fun ) )
		return [[level.hotjoin_skill_points_fun]]();
	else
		return default_hotjoin_skill_points();
}

default_hotjoin_skill_points()
{
	HIVE_SKILL_POINT_PENALTY = 1;
	
	if ( is_hardcore_mode() )
		point_from_hive_destroyed = 0; // in hardcore mode, players are not earning any skill points from destroying hives
	else 
		point_from_hive_destroyed = max( 0, level.num_hive_destroyed - HIVE_SKILL_POINT_PENALTY );
	
	point_from_challenge_completed = maps\mp\alien\_challenge::get_num_challenge_completed();	
	return ( point_from_hive_destroyed + point_from_challenge_completed );
}

init_threatbiasgroups()
{
	CreateThreatBiasGroup( "players" );
	CreateThreatBiasGroup( "hive_heli" );
	CreateThreatBiasGroup( "other_aliens" );
	CreateThreatBiasGroup( "spitters" );
	CreateThreatBiasGroup( "dontattackdrill" ); // Currently elite and minions
	CreateThreatBiasGroup( "drill" );
	
	SetThreatBias( "hive_heli", "spitters", 10000 ); 		// spitters will be more likely to target the helicopter.
	SetIgnoreMeGroup( "hive_heli", "other_aliens" );		// other aliens never attach chopper, ever
	SetIgnoreMeGroup( "drill", "dontattackdrill" );
	SetIgnoreMeGroup( "hive_heli", "dontattackdrill" );
}

threat_bias_grouping()
{
	level endon( "game_ended" );
	
	while ( !ThreatBiasGroupExists( "players" ) )
		wait 0.05;
	
	// self is player
	self SetThreatBiasGroup( "players" );
}

player_hotjoin()
{
	self endon( "disconnect" );
	
	self notify( "intro_done" );	
	self waittill( "spawned" );

	self.pers["hotjoined"] = true;
	println( "Player Has HotJoined!*!*!*!*!**!*!*!*!*!*!**!*!*!*!*!**!*!*!*!*!*!*!*!*!*!*!*!**!*!*!*!" );
	
	//fade out the black screen
	self.introscreen_overlay FadeOverTime( 1 );
	wait ( 1 );
	self.introscreen_overlay destroy();
	
	//re-outline any pets that might have been created
	aliens = maps\mp\alien\_spawnlogic::get_alive_enemies();
	
	if ( !isDefined( aliens ) || aliens.size < 1 )
		return;
	
	foreach ( alien in aliens )
	{
		if ( isDefined( alien ) && is_true ( alien.pet ) )
			maps\mp\alien\_outline_proto::enable_outline_for_player( alien, self, 3, false, "high" );
	}
	
}

player_init_health_regen()
{
	self.healthRegenMaxPercent = level.healthRegenCap;
	self.regenSpeed = 1;
}

player_init_invulnerability()
{
	self.haveInvulnerabilityAvailable = true;
}

player_init_damageShield()
{
	self.damageShieldExpireTime = getTime();
}

player_init_assist_bonus()
{
	self.leftover_assist_bonus = 0;
}

//=======================================================
//				onSpawnPlayer
//=======================================================
onSpawnPlayer()
{
	// Use the initial alien loadout
	self.pers["gamemodeLoadout"] = level.alien_loadout;
	
	self.drillSpeedModifier = 1.0;
	self.fireShield = 0;
	self.isReviving = 0;
	self.isRepairing = 0;
	self.isCarrying = false;
	self.isBoosted = undefined;
	self.isHealthBoosted = undefined;	
	self.burning = undefined;
	self.shocked = undefined;
	self.player_action_disabled = undefined;
	
	if( self maps\mp\alien\_perk_utility::has_perk( "perk_health" ) )
	{
		self.maxhealth = self perk_GetMaxHealth();
		self.health = self.maxhealth;
	}
	// because self.lastdeathpos is not reliable
	self thread player_last_death_pos();
	self thread alienPlayerHealthHints();
	self player_init_invulnerability();
	self player_init_damageShield();
	self maps\mp\alien\_laststand::player_init_lastStand();
	
	if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "shock_melee_upgrade" ) )	
		self thread melee_strength_timer();
	
	if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "locker_key_upgrade" ) )
	{
		map = GetDvar( "ui_mapname" );
		if ( map == "mp_alien_armory" || map == "mp_alien_beacon" || map == "mp_alien_dlc3" || map == "mp_alien_last" ) //may need to add future maps that contain lockers
		{
			self thread init_locker_key_upgrade();
		}
	}
	
	if ( alien_mode_has( "loot" ) )
		self maps\mp\alien\_collectibles::player_loot_init();
	
	if ( alien_mode_has( "airdrop" ) )
		self thread maps\mp\alien\_drill::watchBomb();
		
	self thread maps\mp\alien\_collectibles::watchThrowableItems();
	self thread maps\mp\alien\_utility::trackRiotShield();
	
	// manages player mist
	//self thread maps\mp\alien\_mist::player_fog_think();
	self thread alienPlayerHealthRegen();
	self thread alienPlayerArmor();
		
	//self thread pistol_ammo_regen();
	//self thread melee_strength_timer();
	self thread maps\mp\alien\_perkfunctions::watchCombatSpeedScaler();
	
	// TODO: Get this working with a tag on the viewmodel
	//self thread maps\mp\alien\_perkfunctions::watchFlamingRiotShield();
	
	self.threatbias = maps\mp\alien\_prestige::prestige_getThreatbiasScalar();
	
	self resetUIDvarsOnSpawn();
	
	self thread maps\mp\alien\_trap::monitor_flare_use();
	
	self thread watchDisconnectEndGame();
	
	if ( is_chaos_mode() )
		maps\mp\alien\_chaos::chaos_onSpawnPlayer( self );
	
	if( isDefined( level.custom_onSpawnPlayer_func ) )
		self [[level.custom_onSpawnPlayer_func]]();
	
	if( isDefined( level.resetPlayerCraftingItemsOnRespawn ) )
		self [[level.resetPlayerCraftingItemsOnRespawn ]]();
	
	if ( self has_pistols_only_relic_and_no_deployables() )
		self thread check_for_player_near_weapon();
	
	self thread setup_class_nameplates();

	self thread kick_for_inactivity();
	
	self maps\mp\alien\_ffotd::onSpawnPlayer();
}

watchDisconnectEndGame()
{
	level endon( "game_ended" );
	
	self waittill( "disconnect" );
	
	if ( is_chaos_mode() )
		gameShouldEnd = maps\mp\alien\_chaos_laststand::chaos_gameShouldEnd( self );
	else  // regular Extinction
		gameShouldEnd = maps\mp\alien\_laststand::gameShouldEnd( self );
		
	if ( gameShouldEnd )
		level thread AlienEndGame( "axis", maps\mp\alien\_hud::get_end_game_string_index( "kia" ) );
}

kick_for_inactivity()
{
	level endon( "game_ended" );
	self endon( "disconnect" );

	//we only want to kick in matchmaking games
	isMatchedGame = ( level.onlineGame && !getDvarInt( "xblive_privatematch" ) );

	if ( isMatchedGame )
	{	
		prev_movement = self GetNormalizedMovement();
		inactivity_start_time = getTime();

		for( ;; )
		{
			wait 0.2;
			
			curr_movement = self GetNormalizedMovement();

			//has the state of movement changed
			if(	curr_movement[0] == prev_movement[0] && curr_movement[1] == prev_movement[1] )
			{
				//allow for 5 mins of inactivity before booting the player
				if ( getTime() - inactivity_start_time > ( 60 * 5 * 1000 ) && level.players.size > 1 )
				{
					kick( self getEntityNumber(), "EXE_PLAYERKICKED_INACTIVE" );
				}
			}
			else
			{
				//once a player moves we will no longer kick for inactivity...
				return;
			}
		}
	}
}

player_last_death_pos()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	
	self.last_death_pos = self.origin;
	
	while ( 1 )
	{
		self waittill( "damage" ); // safer to wait for damage than every frame
		self.last_death_pos = self.origin;
	}
}

alienPlayerHealthHints()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );
	
	while ( true )
	{
		regen_ratio_limit = 0.33; //REGEN_LIMIT_HEALTH_BAR_SEGMENT / GetDvarInt ( "player_health_bar_segments" );
		regen_ratio_limit = int( regen_ratio_limit * 100 )/100; // centi
		ratio = self.health / self.maxHealth;
		
		// no warning in last stand as you can not heal
		if ( isdefined( self.laststand ) && self.laststand )
		{
			wait 0.05;
			continue;
		}
		
		if ( ratio < regen_ratio_limit )
		{
			if ( self has_healthpack() )
			{
//				self setLowerMessage( "use_health", &"ALIEN_COLLECTIBLES_USE_HEALTH_PACK", 5 );
				//self delayThread( 0.05, ::display_hint, "use_health" );
			}
			else
			{
//				self setLowerMessage( "find_health", &"ALIEN_COLLECTIBLES_FIND_HEALTH_PACK", 5 );
//				//self delayThread( 0.05, ::display_hint, "find_health" );
			}
		}
		
		self waittill_any_timeout( 5, "health_regened", "damage" );
		
		waittillframeend;
	}	
}

has_healthpack()
{
	if ( isdefined( self.has_health_pack ) && self.has_health_pack )
		return true;
	
	return false;
	
	/*
	// does player already have item in dpad left
	override = self GetWeaponHudIconOverride( "actionslot3" );
	if ( isdefined( override ) && override != "none" )
		return true;
	
	return false;
	*/
}

//=======================================================
//				onTimeLimit
//=======================================================
onTimeLimit()
{
	maps\mp\gametypes\_gamelogic::default_onTimeLimit();
}


//=======================================================
//				onXPEvent
//=======================================================
onXPEvent( event )
{
	self maps\mp\alien\_globallogic::onXPEvent( event );
}


//=======================================================
//				getSpawnPoint
//=======================================================
getSpawnPoint()
{
	spawnteam = self.pers["team"];
	
	if( level.gracePeriod && isDefined( level.alien_player_spawn_group ) )
	{
		grouplist = [ "group0", "group1", "group2", "group3" ];
		grouplist = array_randomize( grouplist );
		level.group = grouplist[0];
		
		//use this for start spawn logic
		group = level.group;
		
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_alien_spawn_" + group + "_start" );
		//spawnPoint = spawnPoints[0];
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	}
	else
	{
		spawnPoints = maps\mp\gametypes\_spawnlogic::getSpawnpointArray( "mp_tdm_spawn_axis_start" );
		spawnPoint = maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );	
	}

	return spawnPoint;
}


//======================================================= 
//				initSpawns
//=======================================================
initSpawns()
{
	maps\mp\alien\_director::alien_attribute_table_init();
	
	// wave spawners
	if ( alien_mode_has( "wave" ) )
	{
		maps\mp\alien\_spawnlogic::alien_wave_init();
		
		// init locations for meteroid drops
		thread maps\mp\alien\_spawnlogic::setup_meteoroid_paths();
		
		// init lurker spawners and patrol loops
		maps\mp\alien\_spawnlogic::alien_lurker_init();
	}
	
	level.spawnMins = ( 0, 0, 0 );
	level.spawnMaxs = ( 0, 0, 0 );
	
	//maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_tdm_spawn_allies_start" );
	maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_tdm_spawn_axis_start" );
	
	if ( isDefined( level.alien_player_spawn_group ) )
	{
		maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_alien_spawn_group3_start");
		maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_alien_spawn_group1_start");
		//maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_alien_spawn_group2_start");
		maps\mp\gametypes\_spawnlogic::addStartSpawnPoints( "mp_alien_spawn_group0_start");
	}
	
	//maps\mp\gametypes\_spawnlogic::addSpawnPoints( "allies", "mp_tdm_spawn" );
	//maps\mp\gametypes\_spawnlogic::addSpawnPoints( "axis", "mp_tdm_spawn" );
	
	level.mapCenter = maps\mp\gametypes\_spawnlogic::findBoxCenter( level.spawnMins, level.spawnMaxs );
	
	// not setting this was causing ents spawned acting weird! it complains ents outside playable area
	setMapCenter( level.mapCenter );
}


//=======================================================
//				addAlienAgent
//=======================================================
addAlienAgent( team, spawnOrigin, spawnAngle, alienType, introVignetteAnim )
{
	agent = maps\mp\agents\_agent_common::connectNewAgent( "alien" , team );
	
	if ( IsDefined( agent ) )
	{		
		agent thread [[ agent agentFunc("spawn") ]]( spawnOrigin, spawnAngle, alienType, introVignetteAnim );
	}
	
	return agent;
}


//===========================================
// 			setAlienLoadout   TODO: Remove this as we now use an alien specific giveLoadout
//===========================================
setAlienLoadout()
{
	level.alien_loadout["loadoutPrimary"] 				= "none";
	level.alien_loadout["loadoutPrimaryAttachment"]		= "none";
	level.alien_loadout["loadoutPrimaryAttachment2"]	= "none";
	level.alien_loadout["loadoutPrimaryBuff"]			= "specialty_null";
	level.alien_loadout["loadoutPrimaryCamo"]			= "none";
	level.alien_loadout["loadoutPrimaryReticle"]		= "none";
	
	level.alien_loadout["loadoutSecondary"]				= "iw6_alienp226";	
	level.alien_loadout["loadoutSecondaryAttachment"]	= "none";
	level.alien_loadout["loadoutSecondaryAttachment2"]	= "none";
	level.alien_loadout["loadoutSecondaryBuff"]			= "specialty_null";
	level.alien_loadout["loadoutSecondaryCamo"]			= "none";
	level.alien_loadout["loadoutSecondaryReticle"]		= "none";
	
	level.alien_loadout["loadoutEquipment"]				= "none";
	level.alien_loadout["loadoutOffhand"]				= "none";
	
	level.alien_loadout["loadoutPerk1"]					= "specialty_pistoldeath";	// Last Stand
	level.alien_loadout["loadoutPerk2"]					= "specialty_null";
	level.alien_loadout["loadoutPerk3"]					= "specialty_null";
	
	level.alien_loadout["loadoutJuggernaut"] 			= false;
}

//===========================================
// 		  pistol_ammo_regen perk
//===========================================

pistol_ammo_regen( item )
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	// First ensure the player has at least a single clip of ammo for each weapon
	weapList = self GetWeaponsListPrimaries();
	
	foreach( weap in weapList )
	{
		baseweapon = GetWeaponBaseName( weap );
		if (baseweapon == "iw6_alienp226_mp" || baseweapon == "iw6_alienmagnum_mp" || baseweapon == "iw6_alienm9a1_mp" || baseweapon == "iw6_alienmp443_mp" )
		{
			clipSize = WeaponClipSize( weap );
			self SetWeaponAmmoClip( weap, clipSize );
		}
	}
		
	regen_interval = 0.2; // 5 bullets per second
	
	while( 1 )
	{
		if ( self perk_GetPistolRegen() == true )
		{
			if ( self player_has_specialized_ammo( "iw6_alienp226" ) || self player_has_specialized_ammo( "iw6_alienmagnum" ) || self player_has_specialized_ammo( "iw6_alienm9a1" ) || self player_has_specialized_ammo( "iw6_alienmp443" )  ) //don't regen the pistol ammo while the player has specialized ammo loaded
			{
				wait ( regen_interval );
				continue;
			}
			weapList = self GetWeaponsListPrimaries();
			foreach( weap in weapList )
			{
				baseweapon = GetWeaponBaseName( weap );
				if (baseweapon == "iw6_alienp226_mp" || baseweapon == "iw6_alienmagnum_mp" || baseweapon == "iw6_alienm9a1_mp" || baseweapon == "iw6_alienmp443_mp" )
				{
					ammoStock = self GetWeaponAmmoStock( weap );
					self SetWeaponAmmoStock( weap, ammoStock + 1 );
				}
			}
			wait( regen_interval );
		}
		wait 0.05;
	}
}

//===========================================
// 		bypassClassChoiceFunc
//===========================================
bypassClassChoiceFunc()
{
		// Players
	return "gamemode";
}

//===========================================
//       alienPlayerHealthRegen()
//===========================================
alienPlayerHealthRegen()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "joined_team" );
	self endon ( "joined_spectators" );
	self endon ( "faux_spawn" );
	level endon ( "game_ended" );
		
	self thread maps\mp\alien\_music_and_dialog::alienPlayerPainBreathingSound();
	
	while ( true ) 
	{	
		self waittill_any ( "damage", "health_perk_upgrade" );
		
		if ( !canRegenHealth() )
			continue;
		
		healthCap = getHealthCap();
		healthRatio = self.health / healthCap;
		
		self thread healthRegen( getTime(), healthRatio, healthCap );
		self thread maps\mp\gametypes\_healthoverlay::breathingManager( getTime(), healthRatio );
	}
}

alienPlayerArmor()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "joined_team" );
	self endon( "joined_spectators" );
	self endon( "faux_spawn" );
	self endon( "game_ended" );

	if ( !isDefined( self.bodyArmorHP ) )
	{
		self.bodyArmorHP = 0;
	}
	self SetCoopPlayerData( "alienSession", "armor", 0 );	
	previous_armor = 0;
	
	while ( true )
	{
		self waittill_any( "player_damaged", "enable_armor" );
		if ( !isDefined( self.bodyArmorHP ) )
		{
			if ( previous_armor > 0 )
			{
				self SetCoopPlayerData( "alienSession", "armor", 0 );
				previous_armor = 0;
			}
		}
		else if ( previous_armor != self.bodyArmorHP )
		{
			player_armor = int( self.bodyArmorHP );
			self SetCoopPlayerData( "alienSession", "armor", player_armor );
			previous_armor = self.bodyArmorHP;
		}
	}
}

//===========================================
//       getHealthCap()
//===========================================
getHealthCap()
{
	self.healthRegenMaxPercent = DEFAULT_REGEN_CAP;
	
	cap = clamp( self.maxhealth * self.healthRegenMaxPercent, 0, self.maxhealth );
	return int( cap );
}

//===========================================
//       canRegenHealth()
//===========================================
canRegenHealth()
{
	if ( isDefined ( self.inLastStand ) && self.inLastStand )
	{
		return false;
	}
	return true;
}

//===========================================
//       healthRegen()
//===========================================
healthRegen( hurtTime, healthRatio, healthCap )
{
	self notify( "healthRegeneration" );
	self endon ( "healthRegeneration" );
	
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "joined_team" );
	self endon ( "joined_spectators" );
	level endon ( "game_ended" );
	
	if ( isHealthRegenDisabled() )
		return;
	
	regenData = spawnStruct();
	getRegenData( regenData );
	
	wait ( regenData.activateTime );
	
	while ( true )
	{
		regenData = spawnStruct();
		getRegenData( regenData );
		if ( !self has_fragile_relic_and_is_sprinting() )
		{
			if ( self.health < Int ( healthCap ))
				if ( ( self.health + regenData.regenAmount ) > Int ( healthCap ) )
					self.health = Int ( healthCap );
				else
					self.health += regenData.regenAmount;
			else
				break;
		}
		wait( regenData.waitTimeBetweenRegen );
	}
		
	self notify( "healed" );
	
	player_init_invulnerability();
	
	//fully regenerated
	self maps\mp\gametypes\_damage::resetAttackerList();
}

//===========================================
//       getRegenData()
//===========================================
getRegenData( regenData )
{
	//<Note J.C.>Potentially based on self.regenSpeed or some buffs? Return default value for now
	self.prestigeHealthRegenNerfScalar = self maps\mp\alien\_prestige::prestige_getSlowHealthRegenScalar();
	
	if ( self.prestigeHealthRegenNerfScalar == 1.0 )
	{
		if ( IsDefined( self.isHealthBoosted ) )
		{
			regenData.activateTime = DEFAULT_REGEN_ACTIVATE_TIME * 0.75;
			regenData.waitTimeBetweenRegen = DEFAULT_WAIT_TIME_BETWEEN_REGEN * 0.75;
			regenData.regenAmount = DEFAULT_REGEN_HEALTH_AMOUNT;
		}
		else if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "faster_health_regen_upgrade" ) )
		{
			regenData.activateTime = DEFAULT_REGEN_ACTIVATE_TIME * 0.9;
			regenData.waitTimeBetweenRegen = DEFAULT_WAIT_TIME_BETWEEN_REGEN * 0.9;
			regenData.regenAmount = DEFAULT_REGEN_HEALTH_AMOUNT;	
		}
		else
		{
			regenData.activateTime = DEFAULT_REGEN_ACTIVATE_TIME;
			regenData.waitTimeBetweenRegen = DEFAULT_WAIT_TIME_BETWEEN_REGEN;
			regenData.regenAmount = DEFAULT_REGEN_HEALTH_AMOUNT;
		}
	}
	else
	{
			regenData.activateTime = DEFAULT_REGEN_ACTIVATE_TIME * self.prestigeHealthRegenNerfScalar ;
			regenData.waitTimeBetweenRegen = DEFAULT_WAIT_TIME_BETWEEN_REGEN * self.prestigeHealthRegenNerfScalar;
			regenData.regenAmount = DEFAULT_REGEN_HEALTH_AMOUNT ;
	}
}

//===========================================
//       isHealthRegenDisabled()
//===========================================
isHealthRegenDisabled()
{
	return (( IsDefined( level.healthRegenDisabled ) && level.healthRegenDisabled ) ||
	        ( IsDefined( self.healthRegenDisabled ) && self.healthRegenDisabled ));
}


//===========================================
//       uiDvars()
//===========================================
resetUIDvarsOnSpawn()
{

}

resetUIDvarsOnConnect()
{
	self SetClientOmnvar( "ui_alien_max_currency", self.maxCurrency );
	SetDvar( "cg_drawCrosshairNames", false );
}

resetUIDvarsOnSpectate()
{

}

//========================================================
//			alien_make_entity_sentient
//========================================================
alien_make_entity_sentient( team, expendable )
{
	if ( self should_make_entity_sentient() )
	{
		if ( IsDefined( expendable ) ) 
			return self MakeEntitySentient( team, expendable );	
		else
			return self MakeEntitySentient( team );	
	}
}

should_make_entity_sentient()
{
	// Sentry
	if ( IsDefined( self.sentryType ) )
	{
		return true;
	}
	
	
	// Drill
	if ( IsDefined( level.drill ) && self == level.drill )
	{
		return true;
	}
	
	if ( isDefined( self.flareType ) )
	{
		return true;
	}
	
	return false;	
}

//custom character model override for Extinction
// self = a player
custom_giveloadout( fakespawn )
{
	self takeAllWeapons();
	
	self.changingWeapon = undefined;

	self.loadoutPrimaryAttachments = []; // may not need these two arrays
	self.loadoutSecondaryAttachments = [];	
	
	// Action Slots
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

	// Perks
	self _clearPerks();
	self maps\mp\alien\_utility::_detachAll();
	
	self.spawnPerk = false;

	if ( isDefined ( self.headModel ) ) //the first time the player gets a model assigned to him
	{
		self.headModel = undefined;
	}
	
	self set_player_character_model();
	bodyindex = getPlayerModelIndex();
	modelFoleyType = self getPlayerFoleyType( bodyIndex );
	self SetClothType( modelFoleyType );
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	self.killstreaktype = "none";
	
	self.primaryWeapon = "none";
	
	pistol = self getcoopplayerdata( "alienPlayerLoadout", "perks", 1 );
	
	switch ( pistol )
	{
		case "perk_pistol_p226":
		case "perk_pistol_p226_1":
		case "perk_pistol_p226_2":
		case "perk_pistol_p226_3":
		case "perk_pistol_p226_4":
			self.default_starting_pistol = "iw6_alienp226_mp";
			break;
			
		case "perk_pistol_magnum":
		case "perk_pistol_magnum_1":
		case "perk_pistol_magnum_2":
		case "perk_pistol_magnum_3":
		case "perk_pistol_magnum_4":
			if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "magnum_acog_upgrade" ) )			
				self.default_starting_pistol = "iw6_alienmagnum_mp_acogpistol_scope5";
			else
				self.default_starting_pistol = "iw6_alienmagnum_mp";
			break;

		case "perk_pistol_m9a1":
		case "perk_pistol_m9a1_1":
		case "perk_pistol_m9a1_2":
		case "perk_pistol_m9a1_3":
		case "perk_pistol_m9a1_4":
			self.default_starting_pistol = "iw6_alienm9a1_mp";
			break;

		case "perk_pistol_mp443":
		case "perk_pistol_mp443_1":
		case "perk_pistol_mp443_2":
		case "perk_pistol_mp443_3":
		case "perk_pistol_mp443_4":
			self.default_starting_pistol = "iw6_alienmp443_mp";
			break;		
	}
	
	self notify ( "changed_kit" );
	self notify ( "giveLoadout" );
	
	
	self givePerk( "specialty_pistoldeath", false );
	self.moveSpeedScaler = self maps\mp\alien\_prestige::prestige_getMoveSlowScalar();
	
	if ( self.moveSpeedScaler == 1.0 )  //If they have the nerf move slower and dont reload while sprinting
	{
		self givePerk( "specialty_sprintreload", false );
	}
	
	if ( self maps\mp\alien\_prestige::prestige_getSlowHealthRegenScalar() == 1.0 )  //only give these perks to players without the slow_health_regen nerf
	{
		self givePerk( "specialty_falldamage", false );	
	}
	
	if ( isDefined ( fakespawn ) && fakespawn )
		return;
	
	if( is_chaos_mode() )
		self.default_starting_pistol = "iw6_alienp226_mp";
	
	self giveweapon ( self.default_starting_pistol );
	self scale_ammo_based_on_nerf( self.default_starting_pistol );	
	
    if ( IsSplitScreen() )
    {
        self thread wait_and_force_weapon_switch();
    }
    else
    {
    	self SetSpawnWeapon( self.default_starting_pistol );
        //self SwitchToWeapon( self.default_starting_pistol );
    }
    
    if ( self should_give_starting_flare())
    {
   		self setOffhandSecondaryClass( "flash" );
		self giveweapon( "alienflare_mp" );
		self SetWeaponAmmoClip( "alienflare_mp",1 );    	
    }
    
    if( is_chaos_mode() )
    	self maps\mp\alien\_chaos::chaos_custom_giveloadout( self );
}

getPlayerModelIndex()
{
	return self GetCoopPlayerData( "coopSquadMembers", 0, "body" );
}

getPlayerFoleyType( bodyIndex )
{
	return TableLookup( "mp/cac/bodies.csv", 0, bodyIndex, 5 );
}

wait_and_force_weapon_switch()
{
    self endon( "disconnect" );
    self endon( "death" );
    level endon( "game_ended" );
    
    wait( 0.5 );
	self SetSpawnWeapon( self.default_starting_pistol );
    //self SwitchToWeapon( self.default_starting_pistol );
}

//self = a player
set_player_character_model() 
{
	// JohnW: Comment this back in after code integration of transient customization changes
	self thread setModelFromCustomization();
	self SetVOPrefix();
}

setCharacterModels( bodyModelName, headModelName, viewModelName )
{
	if ( isDefined( self.headModel ) )
		self Detach( self.headModel );
	self SetModel( bodyModelName );
	self SetViewModel( viewModelName );
	self Attach( headModelName, "", true );
	self.headModel = headModelName;
}

setModelFromCustomization()
{
	wait 0.05;
	/# //dev builds need to wait longer or things won't be loaded up.
	wait 0.5;
	#/

	assert( IsDefined( self ) );
	assert( IsPlayer( self ) );

	bodyModelName = self GetCustomizationBody();
	headModelName = self GetCustomizationHead();
	viewModelName = self GetCustomizationViewmodel();

	setCharacterModels( bodyModelName, headModelName, viewModelName );
}

setVOPrefix()
{
	//the defaults are from alien town
	if(!IsDefined(level.cac_vo_male))
		level.cac_vo_male = array_randomize(["p2_","p4_","p3_"]);
	if(!IsDefined(level.cac_vo_female))
		level.cac_vo_female = array_randomize(["p1_"]);
	
	if(!IsDefined(level.male_index))
		level.male_index = 0;

	if(!IsDefined(level.female_index))
		level.female_index = 0;
	
	if(!IsDefined(self.vo_prefix))
	{
		if(self HasFemaleCustomizationModel())
		{
			if(level.female_index < level.cac_vo_female.size)
			{
				self.vo_prefix = level.cac_vo_female[level.female_index];
				level.female_index++;	
			}
			else
			{
				level.female_index = 0;
				self.vo_prefix = level.cac_vo_female[level.female_index];
				level.female_index++;
			}
		}
		else
		{
			if(level.male_index < level.cac_vo_male.size)
			{
				self.vo_prefix = level.cac_vo_male[level.male_index];
				level.male_index++;	
			}
			else
			{
				level.male_index = 0;
				self.vo_prefix = level.cac_vo_male[level.male_index];
				level.male_index++;
			}
		}
	}
}		

boxCaptureThink_alien_func( player ) 
{
	return ( player is_holding_deployable() );
}

special_weapon_hints()
{
	self endon( "disconnect" );
	
	self.flare_tutorial_given = false;
	self.pet_tutorial_given = false;
	self.claymore_tutorial_given = false;
	self.betty_tutorial_given = false;
	self.deployable_tutorial_given = false;
	self.semtex_tutorial_given = false;	
	self.mortar_tutorial_given = false;	
	self.trophy_tutorial_given = false;	
	self.soflam_tutorial_given = false;	
	self.drill_tutorial_given = false;
	
	
	self thread show_weapon_switch_hints(); //hints shown when a weapon is switched to
	
	while ( 1 )
	{
		weapons = self GetWeaponsListAll();
		foreach ( weapon in weapons )
		{
			if ( weapon == "alienbetty_mp"  )
			{
				self thread show_tutorial_text ( weapon );
			}
			else if ( weapon == "alienclaymore_mp" )
			{
				self thread show_tutorial_text ( weapon );
			}
			else if ( weapon == "alienflare_mp"  )
			{
				self thread show_tutorial_text ( weapon );
			}
			else if ( weapon == "aliensemtex_mp"  )
			{
				if( !is_chaos_mode() )
					self thread show_tutorial_text ( weapon );
			}
			else if ( weapon == "alienthrowingknife_mp" )
			{
				self thread show_tutorial_text ( weapon );
			}
			else if ( weapon == "alienmortar_shell_mp" )
			{
				self thread show_tutorial_text ( weapon );
			}
			else if ( weapon == "alientrophy_mp" )
			{
				self thread show_tutorial_text ( weapon );
			}
			else if ( weapon == "alienbomb_mp" )
			{
				self thread show_tutorial_text ( weapon );
			}
			
		}
		wait ( 1 );		
	}	
}

show_weapon_switch_hints()
{
	self endon("disconnect" );
	
	while ( 1 )
	{
		self waittill( "weapon_change",wpn );
		if ( wpn == "aliendeployable_crate_marker_mp" || wpn == "aliensoflam_mp" )
		{
			self thread show_tutorial_text ( wpn );
		}
		if ( is_true( self.hasRiotShield ) || is_true ( self.hasRiotshieldequipped ) )
		{
			self setclientomnvar ( "ui_alien_riotshield_equipped",1 );
			wait 0.05;  //riotshield checks seem timing specific as they aren't 100% accurate during weapon changes
			if ( !self.hasRiotShieldEquipped && self.hasRiotShield  )
			{
				riot_shield_name = self riotShieldName();	
				
				if ( !isDefined( riot_shield_name ) )
					continue;
				
				riotshield_ammo = self GetAmmoCount( riot_shield_name );
				self setclientomnvar ( "ui_alien_riotshield_equipped",2 );
				self SetClientOmnvar ( "ui_alien_stowed_riotshield_ammo", riotshield_ammo );
			}
		}
		else 
			self setclientomnvar ( "ui_alien_riotshield_equipped",-1 );	
	}
	
}

show_tutorial_text ( weapon )
{
	self endon( "disconnect" );
	
	switch ( weapon )
	{
		case "alienbetty_mp":
			if ( !self.betty_tutorial_given )
			{
				self.betty_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_BETTY",3.5 );
			}
			break;			

		case "alienclaymore_mp":
			if ( !self.claymore_tutorial_given )
			{
				self.claymore_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_CLAYMORE",3.5 );
			}
			break;
			
		case "alienthrowingknife_mp":
			if ( !self.pet_tutorial_given )
			{
				self.pet_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_PET",3.5 );
			}
			break;
			
		case "alienflare_mp":
			if ( !self.flare_tutorial_given )
			{
				self.flare_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_FLARE",3.5 );
			}
			break;
	/*	///// We are using a general message for all combat resources so this is not needed
		case "aliendeployable_crate_marker_mp":
			if ( !self.deployable_tutorial_given )
			{
				self.deployable_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_DEPLOYABLE",3.5 );
			}
			break;
	*/	
		case "aliensemtex_mp":
			if ( !self.semtex_tutorial_given )
			{
				self.semtex_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_SEMTEX",3.5 );
			}
			break;	
			
		case "alienmortar_shell_mp":
			if ( !self.mortar_tutorial_given )
			{
				self.mortar_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_MORTARSHELL",3.5 );
			}
			break;	
		
		case "aliensoflam_mp":
			if ( !self.soflam_tutorial_given )
			{
				self.soflam_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_SOFLAM",3.5 );
			}
			break;	
			
		case "alientrophy_mp":
			if ( !self.trophy_tutorial_given )
			{
				self.trophy_tutorial_given = true;
				self setLowerMessage( "tutorial",&"ALIEN_COLLECTIBLES_TUTORIAL_TROPHY",3.5 );
			}
			break;	
		case "alienbomb_mp":
			if ( !self.drill_tutorial_given )
			{
				self.drill_tutorial_given = true;
				self setLowerMessage( "go_plant", get_drill_tutorial_text(), 3.5 );
			}			
	}
}

get_drill_tutorial_text()
{
	if ( isDefined( level.drill_tutorial_text ) )
		return level.drill_tutorial_text;
	
	return &"ALIEN_COLLECTIBLES_GO_PLANT_BOMB";
}

enable_disable_usability_monitor()
{
	self endon( "disconnect" );
	
	while ( 1 )
	{
		if ( self is_holding_deployable() )
		{
			self _disableUsability();
			while ( self is_holding_deployable() ) // TODO - possibly add || self has_special_weapon()
			{
				wait ( .05 );
			}
			self _enableUsability();
		}
		wait ( 0.05 );
	}
}

// Killstreaks

killstreakInit()
{	
	maps\mp\killstreaks\_killstreaks::initKillstreakData();

	level.killstreakFuncs = [];
	level.killstreakSetupFuncs = [];
	level.killstreakWeapons = [];

	thread maps\mp\killstreaks\_uav::init();
	thread maps\mp\killstreaks\_airstrike::init();
	thread maps\mp\killstreaks\_plane::init();	// eventually, move this above airstrike and simplify the existing killstreaks
	thread maps\mp\killstreaks\_helicopter::init();
	thread maps\mp\alien\_nuke::init();
	//thread maps\mp\killstreaks\_a10::init();
	thread maps\mp\killstreaks\_portableAOEgenerator::init();
	//thread maps\mp\gametypes\_scrambler::init();  //REMOVE SCRAMBLER FROM MP HOPE YOU GUYS DIDNT WANT IT
	//thread maps\mp\gametypes\_portable_radar::init();
	thread maps\mp\killstreaks\_ims::init();
	thread maps\mp\killstreaks\_perkstreaks::init();
	thread maps\mp\killstreaks\_remoteuav::init();
	//thread maps\mp\killstreaks\_remotetank::init();
	thread maps\mp\killstreaks\_juggernaut::init();
	thread maps\mp\killstreaks\_ball_drone::init();
	thread maps\mp\killstreaks\_vanguard::init();
	thread maps\mp\killstreaks\_droneHive::init();
	thread maps\mp\killstreaks\_air_superiority::init();
	
	level.teamEMPed["allies"] = false;
	level.teamEMPed["axis"] = false;
	
	//	all killstreak weapons that kill, this is used for weapon to killstreak association
	level.killstreakWeildWeapons = [];
	level.killstreakWeildWeapons["artillery_mp"] = 					"precision_airstrike";		// Precision Airstrike
	level.killstreakWeildWeapons["stealth_bomb_mp"] = 				"stealth_airstrike";		// Stealth Bomber
	level.killstreakWeildWeapons["pavelow_minigun_mp"] = 			"helicopter_flares";		// Pave Low
	level.killstreakWeildWeapons["sentry_minigun_mp"] = 			"sentry";					// Sentry Gun
	level.killstreakWeildWeapons["ac130_105mm_mp"] = 				"ac130";					// AC130
	level.killstreakWeildWeapons["ac130_40mm_mp"] = 				"ac130";					// AC130
	level.killstreakWeildWeapons["ac130_25mm_mp"] = 				"ac130";					// AC130
	level.killstreakWeildWeapons["remotemissile_projectile_mp"] = 	"predator_missile";			// Predator Missile
	level.killstreakWeildWeapons["cobra_ffar_mp"] = 				"helicopter";				// Attack Helicopter, Missile
	level.killstreakWeildWeapons["hind_bomb_mp"] = 					"helicopter";				// Attack Helicopter, Missile
	level.killstreakWeildWeapons["cobra_20mm_mp"] = 				"helicopter";				// Attack Helicopter
	level.killstreakWeildWeapons["nuke_mp"] = 						"nuke";						// Nuke		
	level.killstreakWeildWeapons["littlebird_guard_minigun_mp"] = 	"littlebird_support";		// littlebird guard/support
	level.killstreakWeildWeapons["osprey_minigun_mp"] = 			"escort_airdrop";			// escort airdrop
	level.killstreakWeildWeapons["remote_mortar_missile_mp"] = 		"remote_mortar";			// remote mortar
	level.killstreakWeildWeapons["manned_littlebird_sniper_mp"] = 	"heli_sniper";				// heli sniper	
	level.killstreakWeildWeapons["iw5_mp412jugg_mp"] = 				"airdrop_juggernaut";		// juggernaut assault secondary	
	level.killstreakWeildWeapons["mortar_shelljugg_mp"] = 			"airdrop_juggernaut";		// juggernaut assault equipment
	level.killstreakWeildWeapons["iw6_riotshieldjugg_mp"] = 		"airdrop_juggernaut_recon";	// juggernaut support primary
	level.killstreakWeildWeapons["iw5_usp45jugg_mp"] = 				"airdrop_juggernaut_recon";	// juggernaut support secondary	
	level.killstreakWeildWeapons["smoke_grenadejugg_mp"] = 			"airdrop_juggernaut_recon";	// juggernaut support offhand
	level.killstreakWeildWeapons["iw6_knifeonlyjugg_mp"] = 			"airdrop_juggernaut_maniac";// juggernaut maniac primary
	level.killstreakWeildWeapons["throwingknifejugg_mp"] = 			"airdrop_juggernaut_maniac";// juggernaut maniac equipment
	level.killstreakWeildWeapons["remote_turret_mp"] = 				"remote_mg_turret";			// remote turret
	level.killstreakWeildWeapons["osprey_player_minigun_mp"] = 		"osprey_gunner";			// osprey gunner
	level.killstreakWeildWeapons["deployable_vest_marker_mp"] = 	"deployable_vest";			// deployable vest
	level.killstreakWeildWeapons["ugv_turret_mp"] = 				"remote_tank";				// remote tank turret
	level.killstreakWeildWeapons["ugv_gl_turret_mp"] = 				"remote_tank";				// remote tank gl turret
	level.killstreakWeildWeapons["remote_tank_projectile_mp"] = 	"vanguard";					// vanguard missile
	level.killstreakWeildWeapons["uav_remote_mp"] = 				"remote_uav";				// remote uav and vanguard
	level.killstreakWeildWeapons["heli_pilot_turret_mp"] = 			"heli_pilot";				// heli pilot
	level.killstreakWeildWeapons["lasedstrike_missile_mp"] = 		"lasedStrike";				// lased Strike
	level.killstreakWeildWeapons["agent_mp"] = 						"agent";					// agent
	level.killstreakWeildWeapons["guard_dog_mp"] = 					"guard_dog";				// guard dog
	// level.killstreakWeildWeapons["kineticbombardment_mp"] = 		"??";						// thor / kinetic bomboardment
	// level.killstreakWeildWeapons["mrsiartillery_mp"] = 				"mrsiartillery";			// mortar strike
	level.killstreakWeildWeapons["ims_projectile_mp"] = 			"ims";						// ims
	level.killstreakWeildWeapons["ball_drone_gun_mp"] = 			"ball_drone_backup";		// backup buddy
	level.killstreakWeildWeapons["drone_hive_projectile_mp"] = 		"drone_hive";				// drone hive
	level.killstreakWeildWeapons["switch_blade_child_mp"] = 		"drone_hive";				// drone hive
	level.killstreakWeildWeapons["iw6_maaws_mp"] = 					"aa_launcher";				// aa launcher
	level.killstreakWeildWeapons["killstreak_uplink_mp"] = 			"uplink";					// uplink
	level.killstreakWeildWeapons["gas_strike_mp"] = 				"gas_airstrike";			// gas_airstrike
	level.killstreakWeildWeapons["a10_30mm_mp"] = 					"a10_strafe";				// a10
	level.killstreakWeildWeapons["maverick_projectile_mp"] = 		"a10_strafe";				// a10
	level.killstreakWeildWeapons["odin_projectile_large_rod_mp"] = 	"odin_assault";				// odin assault
	level.killstreakWeildWeapons["odin_projectile_small_rod_mp"] = 	"odin_assault";				// odin assault
	level.killstreakWeildWeapons["iw5_barrettexp_mp_barrettscope"] ="heli_sniper";				// heli sniper
	level.killstreakWeildWeapons["airdrop_marker_mp"] =		        "airdrop_assault";			// airdrop marker
	
	if(IsDefined(level.mapCustomKillstreakFunc))
		[[ level.mapCustomKillstreakFunc ]]();
	
	level.killstreakRoundDelay = getIntProperty( "scr_game_killstreakdelay", 8 );

	//level thread onPlayerConnect();
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

AlienForceEndGame()
{
	level thread AlienEndGame( "axis", maps\mp\alien\_hud::get_end_game_string_index( "host_end" ) );
}

////////////////////////////////////////////////////////////////
//                End Game 
////////////////////////////////////////////////////////////////
AlienEndGame( winner, endReasonTextIndex )
{	
	end_game_scoreboard_wait_time = 11.0;
	
	if ( gameAlreadyEnded() )
		return;
	
	game["state"] = "postgame";
	
	level.gameEnded = true;
	level.gameEndTime = getTime();
	level.inGracePeriod = false;
	
	level notify ( "game_ended", winner );
	waitframe(); // give "game_ended" notifies time to process
	
	levelFlagSet( "game_over" );
	levelFlagSet( "block_notifies" );
		
	SetOmnvar( "ui_pause_menu_show", false );  // Make sure we tell the menu to close if the player is still in it
	
	SetDvar( "ui_game_state", "postgame" );
	setDvar( "g_deadChat", 1 );
	setDvar( "ui_allow_teamchange", 0 );
	SetDvar( "bg_compassShowEnemies", 0 );
	SetDvar( "scr_gameended", 1 );
	
	setGameEndTime( 0 ); // stop/hide the timers

	maps\mp\gametypes\_gamescore::updateTeamScore( "axis" );
	maps\mp\gametypes\_gamescore::updateTeamScore( "allies" );
	maps\mp\gametypes\_gamescore::updatePlacement();

	maps\mp\gametypes\_gamelogic::freezeAllPlayers( 1.0, "cg_fovScale", 1 );
	foreach ( player in level.players )
	{
		player notify ( "reset_outcome" );
		player.pers["stats"] = player.stats;	
		player maps\mp\killstreaks\_killstreaks::clearKillstreaks();  // since the game is over, clear their killstreaks so they don't carry over to another game
		player.ignoreme = true; // Aliens will stop attacking me
		
		//clear out the lower messages
		player clearLowerMessages();
	}
	
	foreach ( agent in level.agentArray )
	{
		if ( IsDefined( agent.isActive ) && agent.isActive )
		{
			agent.ignoreall = true;
			agent enable_alien_scripted();
		}	    
	}
		
	/#
	sendScriptUsageAnalysisData( 1, 1 );
	#/	
	
	maps\mp\alien\_gamescore::calculate_players_total_end_game_score();
	
	level.intermission = true;
	
	if ( isDefined( level.pre_end_game_display_func ) )
		[[level.pre_end_game_display_func]]();
	
	maps\mp\alien\_hud::displayAlienGameEnd( winner, endReasonTextIndex );
	
	levelFlagClear( "block_notifies" );
	
	level notify ( "spawning_intermission" );
	
	intermission_func = maps\mp\gametypes\_playerlogic::spawnIntermission;
	
	if ( isDefined( level.custom_intermission_func ) )
		intermission_func = level.custom_intermission_func;
	
	foreach ( player in level.players )
	{
		
		player thread [[intermission_func]]();
		
		player thread blackBox_EndGame_Score();
		
		player setClientDvar( "ui_opensummary", 1 );

		player setRoundGameMode();
	}
	
	end_condition = get_end_condition( endReasonTextIndex );
	play_time     = get_play_time();
	
	blackBox_EndGame( end_condition, play_time );
	
	maps\mp\alien\_alien_matchdata::EndGame( end_condition, play_time );
	
	if ( isDefined( level.end_game_scoreboard_wait_time ) )
		end_game_scoreboard_wait_time = level.end_game_scoreboard_wait_time;
	
	wait ( end_game_scoreboard_wait_time );
	
	SetNoJIPTime( false );
	
	level notify( "exitLevel_called" );
	exitLevel( false );
}

gameAlreadyEnded()
{
	return ( game[ "state" ] == "postgame" || level.gameEnded );
}

setRoundGameMode()
{
	//AAR needs an indication of the mode for the last game; chaos or extinction.
	if ( !is_chaos_mode() )
	{
		self setCommonPlayerData( "round", "gameMode", "aliens" );
	}
	else
	{
		//using mugger to indicate aliens games
		self setCommonPlayerData( "round", "gameMode", "mugger" );
	}

	//outro videos need and indication of the last map played.
	self setCommonPlayerData( "round", "map", ToLower( GetDvar( "mapname" ) ) );
}

blackBox_EndGame_Score()
{
	// ============ BBPRINT for final score =============
	
	cyclenum = -1; 
	if ( isdefined( level.current_cycle_num ) )
		cyclenum = level.current_cycle_num;
	
	player_name = "unknown";
	if ( isdefined( self.name ) )
		player_name = self.name;
	
	hive_name = "unknown";
	if ( isdefined( level.current_hive_name ) )
		hive_name = level.current_hive_name;
	
	final_score = 0;
	if ( isdefined( self.end_game_score ) && isdefined( self.end_game_score[ "total_score" ] ) )
		final_score = self.end_game_score[ "total_score" ];
	
	total_xp = self maps\mp\alien\_persistence::get_player_session_xp();	

	/#
	if ( GetDvarInt( "alien_bbprint_debug" ) > 0 )
	{
		IPrintLnBold( "^8bbprint: alienfinalscore\n" +
					" playername="		+ player_name +
					" cyclenum=" 		+ cyclenum +
					" hivename="		+ hive_name +
					" playerfinalscore="+ final_score +
					" playerxpearned="	+ total_xp );
	}
	#/

	bbprint( "alienfinalscore",
		    "playername %s cyclenum %i hivename %s playerfinalscore %i playerxpearned %i ", 
			player_name,
			cyclenum,
			hive_name,
			final_score,
			total_xp );
	
	// ============ BBPRINT for final score [END] =============
}

blackBox_EndGame( endcondition, playtime )
{
	// =========================== blackbox print [START] ===========================
	// TODO: split this per player
	
	assertex( isdefined( level.alienBBData ), "BBData tracking is not initialized in script!" );
	
	player0rank	= -1;
	if ( isdefined( level.players[ 0 ] ) )
		player0rank = int( level.players[ 0 ] maps\mp\alien\_persistence::get_player_rank() );
	
	player1rank	= -1;
	if ( isdefined( level.players[ 1 ] ) )
		player1rank = int( level.players[ 1 ] maps\mp\alien\_persistence::get_player_rank() );
	
	player2rank	= -1;
	if ( isdefined( level.players[ 2 ] ) )
		player2rank = int( level.players[ 2 ] maps\mp\alien\_persistence::get_player_rank() );
	
	player3rank	= -1;
	if ( isdefined( level.players[ 3 ] ) )
		player3rank = int( level.players[ 3 ] maps\mp\alien\_persistence::get_player_rank() );
	
	hivescleared = 0;
	if ( isdefined( level.current_cycle_num ) )
		hivescleared = level.current_cycle_num;
	
	hivename = "unknown";
	if ( isdefined( level.current_hive_name ) )
		hivename = level.current_hive_name;
	
	timesdowned			= level.alienBBData[ "times_downed" ];
	timesdied			= level.alienBBData[ "times_died" ];
	timesdrillstuck		= level.alienBBData[ "times_drill_stuck" ];
	alienskilled		= level.alienBBData[ "aliens_killed" ];
	teamitemdeployed	= level.alienBBData[ "team_item_deployed" ];
	teamitemused		= level.alienBBData[ "team_item_used" ];
	bulletsshot			= level.alienBBData[ "bullets_shot" ];
	damagetaken			= level.alienBBData[ "damage_taken" ];
	damagedone			= level.alienBBData[ "damage_done" ];
	trapsused			= level.alienBBData[ "traps_used" ];
	
	/#
	if ( GetDvarInt( "alien_bbprint_debug" ) > 0 )
	{
		playerranks = player0rank + " "+ player1rank + " "+ player2rank + " "+ player3rank;
		
		IPrintLnBold( "^8bbprint: alienendgame (1/2)\n" +
					 " endcondition=" + endcondition +
					 " playerranks=" + playerranks +
					 " playtime=" + playtime +
					 " hivescleared=" + hivescleared +
					 " hivename=" + hivename +
					 " timesdowned=" + timesdowned +
					 " timesdied=" + timesdied );
					 
		IPrintLnBold( "^8bbprint: alienendgame (2/2)\n" +
					 " timesdrillstuck=" + timesdrillstuck +
					 " alienskilled=" + alienskilled +
					 " teamitemdeployed=" + teamitemdeployed +
					 " teamitemused=" + teamitemused +
					 " bulletsshot=" + bulletsshot +
					 " damagetaken=" + damagetaken +
					 " damagedone=" + damagedone +
					 " trapsused=" + trapsused );
	}
	#/

	bbprint( "alienendgame",
		    "endcondition %s player0rank %i player1rank %i player2rank %i player3rank %i playtime %f hivescleared %i hivename %s timesdowned %i timesdied %i timesdrillstuck %i alienskilled %i teamitemused %i teamitemdeployed %i bulletsshot %i damagedone %i damagetaken %i trapsused %i ", 
			endcondition,
			player0rank,
			player1rank,
			player2rank,
			player3rank,
			playtime,
			hivescleared,
			hivename,
			timesdowned,
			timesdied,
			timesdrillstuck,
			alienskilled,
			teamitemdeployed,
			teamitemused,
			bulletsshot,
			damagetaken,
			damagedone,
			trapsused );

	// =========================== [END] blackbox print ===========================
	
	// store team total stats on playerdata on each player
	
	foreach ( player in level.players )
	{		
		// these values are totals, regardless if players come and go
		player SetCoopPlayerData( "alienSession", "team_shots", level.alienBBData[ "bullets_shot" ] );
		player SetCoopPlayerData( "alienSession", "team_kills", level.alienBBData[ "aliens_killed" ] );
		player SetCoopPlayerData( "alienSession", "team_hives", level.num_hive_destroyed );
		
		// =========================== blackbox print [START] ===========================
		
		// end of game bbprint per player:
		player_ent_number 		= int( player GetEntityNumber() );
		player_ref 				= "EoGPlayer" + player_ent_number;
		
		if ( isdefined( player.name ) )
			player_name			= player.name;
		else
			player_name			= "-error";
		
		player_play_time	    = getTime() - player.connect_time;
		
		player_kills 			= player getcoopplayerdata( player_ref, "kills" );
		player_score 			= player getcoopplayerdata( player_ref, "score" );
		player_assists 			= player getcoopplayerdata( player_ref, "assists" );
		player_revives 			= player getcoopplayerdata( player_ref, "revives" );
		player_drill_restarts 	= player getcoopplayerdata( player_ref, "drillrestarts" );
		player_deaths 			= player getcoopplayerdata( player_ref, "deaths" );
		player_hives 			= player getcoopplayerdata( player_ref, "hivesdestroyed" );
		player_traps			= player getcoopplayerdata( player_ref, "traps" );
		player_deployables		= player getcoopplayerdata( player_ref, "deployables" );
		player_deployables_used	= player getcoopplayerdata( player_ref, "deployablesused" );
		player_currency_spent	= player getcoopplayerdata( player_ref, "currencyspent" );
		player_currency_total	= player getcoopplayerdata( player_ref, "currencytotal" );;
		
		player_bbprint_ref 		= "alienendgame_player" + player_ent_number;
		
		/#
		if ( GetDvarInt( "alien_bbprint_debug" ) > 0 )
		{
			IPrintLnBold( "^8bbprint: " + player_bbprint_ref + " (1/2)\n" +
						 " playername=" + player_name +
						 " playerplaytime=" + player_play_time +
						 " playerkills=" + player_kills +
						 " playerscore=" + player_score +
						 " playerassists=" + player_assists +
						 " playerrevives=" + player_revives + 
						 " playerdrillrestarts=" + player_drill_restarts );
						 
			IPrintLnBold( "^8bbprint: " + player_bbprint_ref + " (2/2)\n" +			 
						 " playerdeaths=" + player_deaths +
						 " playerhives=" + player_hives +
						 " playertraps=" + player_traps +
						 " playertotalcurrency=" + player_currency_total +
						 " playercurrencyspent=" + player_currency_spent +
						 " playerdeployables=" + player_deployables +
						 " playerdeployablesused=" + player_deployables_used );
		}
		#/
		
		bbprint( player_bbprint_ref,
			    "playername %s playerplaytime %f playerkills %i playerscore %i playerassists %i playerrevives %i playerdrillrestarts %i playerdeaths %i playerhives %i playertraps %i playertotalcurrency %i playercurrencyspent %i playerdeployables %i playerdeployablesused %i ",
				player_name,   
				player_play_time, 
				player_kills,	
				player_score,  
				player_assists,  
				player_revives,  
				player_drill_restarts, 
				player_deaths,	
				player_hives,
				player_traps,
				player_currency_total,
				player_currency_spent,
				player_deployables,
				player_deployables_used );
		// =========================== [END] blackbox print ===========================
	}
}

get_end_condition( endReasonTextIndex )
{
	// The index is mapped in maps\mp\alien\_hud::get_end_game_string_index()
	switch( endReasonTextIndex )
	{
	case 1:
		return "all_escape";

	case 2:
		return "some_escape";
		
	case 3: 
		return "fail_escape";
		
	case 4:
	case 8:
		return "drill destroyed";
		
	case 5:
		return "died";
		
	case 6:
		return "host_quit";
	
	case 7:
		return "gas_fail";
		
	default:
		AssertMsg( "Unknown endReasonTextIndex: " + endReasonTextIndex );
	}
}

get_play_time()
{
	playtime = 0; // pregame counts as 0 play time
	
	if ( isdefined( level.startTime ) )
		playtime = getTime() - level.startTime;
	
	return playtime;
}

alien_customprematchperiod()
{
	if ( !is_true ( level.introscreen_done ) )
		level.prematchPeriod = 10;
	
	if ( !maps\mp\alien\_intro_sequence::intro_sequence_enabled() )
	{
		wait_time = 3;
		if ( maps\mp\alien\_utility::is_chaos_mode() )
		{
			wait_time = 6;
		}
		wait ( wait_time );
		level notify( "introscreen_over");
		level.introscreen_done = true;
		level notify( "spawn_intro_drill" );
		
		if ( is_true ( level.intermission ) ) //game ended before it started, lets not unfreeze anyone
		{
			return;
		}
		
		for ( index = 0; index < level.players.size; index++ )
		{
			level.players[index] freezeControlsWrapper( false );
			level.players[index] enableWeapons();
			
			if( !isDefined( level.players[index].pers["team"] ) )
				continue;
		}	
		
		return;
	}
	
	if ( level.prematchPeriod > 0 )
	{
		player = level wait_for_first_player_connect();
		
		if ( maps\mp\alien\_intro_sequence::intro_sequence_enabled() )
			level thread maps\mp\alien\_intro_sequence::play_intro_sequence( player );
	
		level thread show_introscreen_text();//show intro screen
		if ( isDefined ( level.intro_dialogue_func ) )
			level thread [[level.intro_dialogue_func]]();
		
		wait ( level.prematchPeriod - 3 );
		if( isDefined ( level.postIntroscreenFunc ) )
		{
			[[level.postIntroscreenFunc]]();
		}

		// PC stuff goes here
		level notify( "introscreen_over");
		level.introscreen_done = true;
		
	}
	else 
	{
		wait ( 1 );
		level notify( "introscreen_over");
	}
	
	if ( is_true ( level.intermission ) ) //game ended before it started, lets not unfreeze anyone
	{
		return;
	}
	
	for ( index = 0; index < level.players.size; index++ )
	{
		level.players[index] freezeControlsWrapper( false );
		level.players[index] enableWeapons();
		
		if( !isDefined( level.players[index].pers["team"] ) )
			continue;
	}
	
}

wait_for_first_player_connect()
{
	player = undefined;
	
	if ( level.players.size == 0 )
	{
		level waittill( "connected", player );
	}
	else
	{
		player = level.players[0];
	}
	
	return player;
}

show_introscreen_text()
{
	wait ( 2 );
	
	line1 = maps\mp\alien\_hud::introscreen_corner_line( level.introscreen_line_1 , 1 );
	wait( 1 );
	line2 = maps\mp\alien\_hud::introscreen_corner_line( level.introscreen_line_2 , 2 );
	wait( 1 );
	line3 = maps\mp\alien\_hud::introscreen_corner_line( level.introscreen_line_3 , 3 );
	wait( 1 );
	line4 = maps\mp\alien\_hud::introscreen_corner_line( level.introscreen_line_4 , 4 );
	
	level waittill( "introscreen_over" );
	
	line1 FadeOverTime(3);
	line2 FadeOverTime(3);
	line3 FadeOverTime(3);
	line4 FadeOverTime(3);
	wait ( 3.1);
	line1.alpha = 0;
	line2.alpha = 0;
	line3.alpha = 0;
	line4.alpha = 0;
	
	line1 destroy();
	line2 destroy();
	line3 destroy();
	line4 destroy();
	
}

// Call these before onStartGameType()
setup_blocker_hives( blocker_hives_array )
{
	level.blocker_hives = blocker_hives_array;
}

setup_cycle_end_area_list( cycle_end_area_list )
{
	level.cycle_end_area_list = cycle_end_area_list;
}

setup_last_hive( last_hive_name )
{
	level.last_hive = last_hive_name;
}

register_encounter( encounter_func, skill_point_reward, hardcore_skill_point_reward, advance_to_next_area, debug_skip_func, debug_pre_encounter_func, debug_force_end_func )
{
	if ( !isDefined( level.encounters ) )
		level.encounters = [];
	
	encounter_info = spawnStruct();
	encounter_info.func = encounter_func;
	
	if ( isDefined( hardcore_skill_point_reward ) )
		encounter_info.hardcore_skill_point = hardcore_skill_point_reward;
	
	if ( isDefined( skill_point_reward ) )
		encounter_info.skill_point = skill_point_reward;
	
	if ( isDefined( advance_to_next_area ) )
		encounter_info.go_next_area = advance_to_next_area;
	
	if ( isDefined( debug_skip_func ) )
		encounter_info.skip_func = debug_skip_func;
	
	if ( isDefined( debug_pre_encounter_func ) )
		encounter_info.pre_encounter_func = debug_pre_encounter_func;
	
	if ( isDefined( debug_force_end_func ) )
		encounter_info.force_end_func = debug_force_end_func;
	
	level.encounters[level.encounters.size] = encounter_info;
}

run_encounters()
{
	level endon( "game_ended" );

/#
	if ( alien_mode_has( "nogame" ) )
		return;
	
	if ( maps\mp\alien\_debug::spawn_test_enable() )
		return;
#/
	// Run level specific version of this func - Used in "Last Stand" map for non-linear progression
	if( isDefined( level.dlc_run_encounters_override ))
	{
		[[level.dlc_run_encounters_override]]();
		return;
	}

	if ( !isDefined( level.encounters ) )
		return;
	
	start_point_enable = is_start_point_enable();
	encounter_index    = 0;
	start_point_index  = get_start_point_index( start_point_enable );
	
	foreach( encounter_info in level.encounters )
	{		
		level.current_encounter_info = encounter_info;
		
		if ( should_run_pre_encounter_func( start_point_enable, encounter_index, start_point_index ) )
			[[encounter_info.pre_encounter_func]]();
		
		if ( should_skip_encounter( start_point_enable, encounter_index, start_point_index ) )
		{
			[[encounter_info.skip_func]]();
			
			if ( isDefined( encounter_info.skill_point ) )
				inc_starting_skill_point( encounter_info.skill_point );
				
			if ( is_true( encounter_info.go_next_area ) )
				inc_current_area_index();
		}
		else
		{
			[[encounter_info.func]]();
			
			if ( !is_hardcore_mode() )
			{
				if ( isDefined( encounter_info.skill_point ) )
					give_players_points( encounter_info.skill_point );
			}
			else
			{
				if ( isDefined( encounter_info.hardcore_skill_point ) )
					give_players_points( encounter_info.hardcore_skill_point );		
			}
			
			if ( is_true( encounter_info.go_next_area ) )
				maps\mp\alien\_collectibles::advance_to_next_area();
		}
		
		encounter_index++;
	}
}

init_locker_key_upgrade()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	wait 5.0;
	
	if(!isdefined(level.starting_locker_key_names))
		level.starting_locker_key_names = [];
	
	player_name = self getxuid();
	
	if ( is_true( level.onlineGame ) )
	{
		for ( i = 0; i < level.starting_locker_key_names.size; i++ )
		{
			if ( level.starting_locker_key_names[ i ] == player_name )
				return;
		}
	}
	
	level.starting_locker_key_names[level.starting_locker_key_names.size] = player_name;
	
	self.locker_key = true;
	self SetClientOmnvar( "ui_alien_locker_key", 1 );  //1 sets to visible state in LUA
}

should_give_starting_flare()
{
	if(!(self has_perk("perk_health", [0,1,2,3,4])))
		return false;
	
	if(!isdefined(level.starting_flare_names))
		level.starting_flare_names = [];
	
	player_name = self getxuid();
	
	if ( is_true( level.onlineGame ) )
	{
		for ( i = 0; i < level.starting_flare_names.size; i++ )
		{
			if ( level.starting_flare_names[ i ] == player_name )
				return false;
		}
	}

	level.starting_flare_names[level.starting_flare_names.size] = player_name;
	return true;	
}

is_start_point_enable()
{
/#
	if ( maps\mp\alien\_debug::startPointEnabled() )
		return true;	
#/
	return false;
}

get_start_point_index( start_point_enable )
{
/#
	if ( start_point_enable )
		return maps\mp\alien\_debug::getStartPointIndex();
#/	
	return 0;
}

should_run_pre_encounter_func( start_point_enable, encounter_index, start_point_index )
{
/#
	if ( start_point_enable )
		return ( encounter_index == start_point_index );
#/
	return false;	
}

should_skip_encounter( start_point_enable, encounter_index, start_point_index )
{
/#
	if ( start_point_enable )
		return ( encounter_index < start_point_index );
#/
	return false;
}

give_players_points( skill_point )
{
	foreach ( player in level.players )
		player maps\mp\alien\_persistence::give_player_points ( int( skill_point ) );
}

inc_starting_skill_point( skill_point )
{
/#
	if ( !isDefined( level.debug_starting_skill_point ) )
		level.debug_starting_skill_point = 0;

	level.debug_starting_skill_point += skill_point;
#/
}

//========================================================================
// 		   Melee Strength Timer()
//     self = a player
//     Initiates a timestamp when the player first
//     melees and then runs a timer on him, watching the melee button.
//========================================================================

melee_strength_timer ()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self.meleeStrength = 1.0;
	melee_button_released = true;
	
	self.meleeStrength = 0;
	last_Time = GetTime();
	
	while ( true )
	{
		current_time = Gettime();
		if ( current_time - last_time >=  ( level.playerMeleeStunRegenTime  ) )
		{
			self.meleeStrength = 1.0;
		}
		else
			self.meleeStrength = 0;
		
		if ( self MeleeButtonPressed() && !self IsReloading() && !self UseButtonPressed() )
		{	
			last_time = Gettime();
			if ( melee_button_released == true )
			{
				melee_button_released = false;
			}
		}
		else if ( !self MeleeButtonPressed() )
			melee_button_released = true;
		else 
			melee_button_released = false;
		wait 0.05;
	}
}


