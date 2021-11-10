#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\alien\_utility;
#include maps\mp\alien\_hive;

/*QUAKED mp_alien_spawn_group0_start (0.5 0.0 1.0) (-16 -16 0) (16 16 72)
Team 0 players spawn at one of these positions at the start of a round.*/

/*QUAKED mp_alien_spawn_group1_start (0.5 0.0 1.0) (-16 -16 0) (16 16 72)
Team 1 players spawn at one of these positions at the start of a round.*/

/*QUAKED mp_alien_spawn_group2_start (0.5 0.0 1.0) (-16 -16 0) (16 16 72)
Team 2 players spawn at one of these positions at the start of a round.*/

/*QUAKED mp_alien_spawn_group3_start (0.5 0.0 1.0) (-16 -16 0) (16 16 72)
Team 3 players spawn at one of these positions at the start of a round.*/

main()
{
	level.additional_boss_weapon = ::update_weapon_placement; // <-- used to either spawn additional weapons, or replace exiting weapons
	//for introscreen text
	level.introscreen_line_1 = &"MP_ALIEN_TOWN_INTRO_LINE_1";
	level.introscreen_line_2 = &"MP_ALIEN_TOWN_INTRO_LINE_2";
	level.introscreen_line_3 = &"MP_ALIEN_TOWN_INTRO_LINE_3";
	level.introscreen_line_4 = &"MP_ALIEN_TOWN_INTRO_LINE_4";
	level.intro_dialogue_func = ::mp_alien_town_intro_dialog;
	level.postIntroscreenFunc = ::mp_alien_town_post_intro_func;
	level.custom_onStartGameTypeFunc = ::mp_alien_town_onStartGameTypeFunc;
	level.alien_character_cac_table = "mp/alien/alien_cac_presets.csv";
	level.initial_spawn_loc_override_func = ::player_initial_spawn_loc_override;
	level.custom_pillageInitFunc = ::mp_alien_town_pillage_init;
	level.tryUseDroneHive= ::mp_alien_town_try_use_drone_hive;

	//ark weapon alien gib death
	level._effect[ "alien_ark_gib" ]		  	= loadfx( "vfx/gameplay/alien/vfx_alien_ark_gib_01" );
	level.custom_alien_death_func = maps\mp\alien\_death::general_alien_custom_death;
	
	if ( is_chaos_mode() )
		level.adjust_spawnLocation_func = ::town_chaos_adjust_spawnLocation;
	
	//enables mist for this level, a level needs mist setup to work
	//level.alien_player_spawn_group = true;

    // switches for alien mode systems
    alien_mode_enable( "kill_resource", "wave", "airdrop", "lurker", "collectible", "loot", "pillage", "challenge", "outline", "scenes" );
    alien_areas = [ "lodge", "city", "lake" ];
    alien_area_init( alien_areas );
    level.alien_challenge_table = "mp/alien/mp_alien_town_challenges.csv";
    level.include_default_challenges = true;
    level.include_default_achievements = true;
    level.include_default_unlocks = true;
    level.escape_cycle = 15;
   
    //hardcore ricochet variables
    level.ricochetDamageMax = 10;
	level.hardcore_spawn_multiplier = 1.0;
	level.hardcore_damage_scalar = 1.0;
	level.hardcore_health_scalar = 1.0;
	level.hardcore_reward_scalar = 1.0;
	level.hardcore_score_scalar = 1.25;
	
	//casual gamemode settings
	level.casual_spawn_multiplier = 1.0;
	level.casual_damage_scalar = 0.45;
	level.casual_health_scalar = 0.45;
	level.casual_reward_scalar = 1.0;
	level.casual_score_scalar = 0.5;
	//level.casual_xp_scalar	  = 0.5;
	
	maps\mp\mp_alien_town_precache::main();
	maps\createart\mp_alien_town_art::main();
	maps\mp\mp_alien_town_fx::main();
	
	//reactive grass rates
	setdvar( "r_reactiveMotionWindAmplitudeScale", 0.15 );
	
	level.craftingEasy = 0;
	level.craftingMedium = 0;
	level.craftingHard = 0;
	
	maps\mp\_load::main();
	
	//Sun Shadows (orig=1 bmax=0.25)
	setdvar_cg_ng( "sm_sunShadowScale", 0.5, 1.0 );

	setdvar_cg_ng( "r_specularColorScale", 2.5, 9.01 );
	
	//Set Spec colorscale dvar to make up for differentials between CG and NG
    //setsaveddvar_cg_ng( "r_specularColorScale", 2.5, 9.01 );

//	AmbientPlay( "ambient_mp_setup_template" );
	
	//maps\mp\_compass::setupMiniMap( "compass_map_mp_alien_town" );
	
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "woodland";
 //   game[ "axis_outfit" ] = "desert";
 	
	// blocker hive cycle label
	blocker_hives = [];
	blocker_hives[ 5 ] = "lodge_lung_3";
	blocker_hives[ 9 ] = "city_lung_5";
	cycle_end_area_list = [ 5, 9 ];
	maps\mp\gametypes\aliens::setup_cycle_end_area_list( cycle_end_area_list );
	maps\mp\gametypes\aliens::setup_blocker_hives( blocker_hives );
	maps\mp\gametypes\aliens::setup_last_hive( "crater_lung" );

	
	// Turn on the player abilities
	thread maps\mp\alien\_alien_class_skills_main::main();
    level.custom_onSpawnPlayer_func = ::mp_alien_town_onSpawnPlayer_func;

	crater_dependencies = ["lake_lung_1", "lake_lung_2", "lake_lung_3", "lake_lung_4", "lake_lung_5", "lake_lung_6"];
	add_hive_dependencies( "crater_lung", crater_dependencies );
	lodge_lung_dependencies = [ "mini_lung" ];
	add_hive_dependencies( "lodge_lung_1", lodge_lung_dependencies );
	add_hive_dependencies( "lodge_lung_2", lodge_lung_dependencies );
	add_hive_dependencies( "lodge_lung_3", lodge_lung_dependencies );
	add_hive_dependencies( "lodge_lung_4", lodge_lung_dependencies );
	add_hive_dependencies( "lodge_lung_5", lodge_lung_dependencies );
	add_hive_dependencies( "lodge_lung_6", lodge_lung_dependencies );
	//thread test_meteoroid();	
	
	level.hintprecachefunc = ::town_hint_precache;
		
	// The time breakdown that determines the escape rank on the leaderboard
	TIME_LEFT_RANK_0 =  85000;   // in ms
	TIME_LEFT_RANK_1 =  95000;   // in ms
	TIME_LEFT_RANK_2 = 105000;   // in ms
	TIME_LEFT_RANK_3 = 240000;   // in ms
	maps\mp\alien\_persistence::register_LB_escape_rank( [ 0, TIME_LEFT_RANK_0, TIME_LEFT_RANK_1, TIME_LEFT_RANK_2, TIME_LEFT_RANK_3 ] );
	
	level.should_play_next_hive_vo_func =::should_play_next_hive_vo_func;
	
	register_encounters();
		
	restore_fog_setting();
	nuke_fog_setting();
	rescue_waypoint_setting();
	set_spawn_table();
	
	// ambient tremors
	amb_quakes();
	
	// =============================== TU FIXES ==============================
	
	// FIX: electric fence in city not high enough to shock aliens
	level thread TU_electric_fence_fix();

	//Change thermal to mp_alien_town_thermal
	game[ "thermal_vision" ] = "mp_alien_town_thermal";
	VisionSetThermal( game[ "thermal_vision" ] );

	game[ "thermal_vision_trinity" ] = "mp_alien_thermal_trinity";
	
	level thread initSpawnableCollision();
	level.skip_radius_damage_on_puddles = true;

	level thread maps\mp\alien\_lasedStrike_alien::init();
	level thread maps\mp\alien\_switchblade_alien::init();
	array_thread( getEntArray( "killstreak_attack_chopper", "targetname" ), ::attack_chopper_monitorUse );
}

register_encounters()
{
	if ( is_chaos_mode() )
	{
	/*0*/	maps\mp\gametypes\aliens::register_encounter( ::chaos_init               , undefined, undefined, 	undefined, ::chaos_init               , maps\mp\alien\_globallogic::blank );
	/*1*/   maps\mp\gametypes\aliens::register_encounter( maps\mp\alien\_chaos::chaos, undefined, undefined, 	undefined, maps\mp\alien\_chaos::chaos, maps\mp\alien\_globallogic::blank );
	return;
	}
	
	// Set up the encounter 
    /*0*/	maps\mp\gametypes\aliens::register_encounter( ::encounter_init, undefined, undefined, undefined,   ::encounter_init, maps\mp\alien\_globallogic::blank  );
	/*1*/   maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined, undefined,   ::skip_hive, ::jump_to_1st_area,	::beat_regular_hive );
	/*2*/   maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_lodge,	::beat_regular_hive );
	/*3*/   maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_lodge,	::beat_regular_hive );
	/*4*/   maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_lodge,	::beat_regular_hive );
	/*5*/   maps\mp\gametypes\aliens::register_encounter( ::blocker_hive,			1, 		   1,		 true, ::skip_hive, ::jump_to_lodge,	::beat_blocker_hive );
	/*6*/   maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_city,		::beat_regular_hive );
	/*7*/   maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_city,		::beat_regular_hive );
	/*8*/   maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_city,		::beat_regular_hive );
	/*9*/   maps\mp\gametypes\aliens::register_encounter( ::blocker_hive,			1, 		   1,		 true, ::skip_hive, ::jump_to_city,		::beat_blocker_hive );
	/*10*/  maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_cabin,	::beat_regular_hive );
	/*11*/  maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_cabin,	::beat_regular_hive );
	/*12*/  maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_cabin,	::beat_regular_hive );
	/*13*/  maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_cabin,	::beat_regular_hive );
	/*14*/  maps\mp\gametypes\aliens::register_encounter( ::regular_hive,			1, undefined,	undefined, ::skip_hive, ::jump_to_crater_hive,	::beat_regular_hive );
	/*15*/  maps\mp\gametypes\aliens::register_encounter( maps\mp\alien\_airdrop::escape   , undefined, undefined,	undefined, ::skip_escape,   ::jump_to_escape     );	
}

initSpawnableCollision()
{
	level waittill("spawn_nondeterministic_entities" );
	
	collision1 = GetEnt( "player512x512x8", "targetname" );
	collision1Ent = spawn( "script_model", (-5332.5, -4394, 774.5) );
	collision1Ent.angles = ( 90, 274, 7);
	collision1Ent CloneBrushmodelToScriptmodel( collision1 );
	
	//collision1Ent thread draw_entity_bounds( collision1Ent, 1000, (1,1,1 ) );
}


encounter_init()
{
	maps\mp\alien\_drill::init_drill();
	
	init_hives();
	
	maps\mp\alien\_airdrop::init_escape();
	
	maps\mp\alien\_gamescore::init_eog_score_components( ["hive", "escape", "relics"] );
	
	maps\mp\alien\_gamescore::init_encounter_score_components( ["challenge", "drill", "team", "team_blocker", "personal", "personal_blocker", "escape"] );
}

town_hint_precache()
{
	all_hints_array = [];
	
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_MAUL" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_MAUL";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_AK12" ]					= &"ALIEN_COLLECTIBLES_PICKUP_AK12";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_M27" ]					= &"ALIEN_COLLECTIBLES_PICKUP_M27";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_PROPANE_TANK" ] 		= &"ALIEN_COLLECTIBLES_PICKUP_PROPANE_TANK";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_MK32" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_MK32";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_HONEYBADGER" ] 			= &"ALIEN_COLLECTIBLES_PICKUP_HONEYBADGER";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_VKS" ] 					= &"ALIEN_COLLECTIBLES_PICKUP_VKS";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_FP6" ] 					= &"ALIEN_COLLECTIBLES_PICKUP_FP6";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_KRISS" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_KRISS";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_MICROTAR" ] 			= &"ALIEN_COLLECTIBLES_PICKUP_MICROTAR";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_P226" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_P226";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_L115A3" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_L115A3";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_SC2010" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_SC2010";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_KAC" ] 					= &"ALIEN_COLLECTIBLES_PICKUP_KAC";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_IMBEL" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_IMBEL";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_MTS255" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_MTS255";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_PANZERFAUST" ] 			= &"ALIEN_COLLECTIBLES_PICKUP_PANZERFAUST";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_CBJMS" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_CBJMS";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_PP19" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_PP19";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_VEPR" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_VEPR";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_BREN" ] 				= &"ALIEN_COLLECTIBLES_PICKUP_BREN";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_RGM" ] 					= &"ALIEN_COLLECTIBLES_PICKUP_RGM";
	all_hints_array[ "ALIEN_COLLECTIBLES_PICKUP_G28" ] 					= &"ALIEN_COLLECTIBLES_PICKUP_G28";

	return all_hints_array;
}

// for rescue chopper extraction waypoint hint locations, chained up
rescue_waypoint_setting()
{
	escape_ent = getent( "escape_zone", "targetname" );
	assertex( isdefined( escape_ent ), "Level missing escape_zone" );
	final_waypoint_loc = escape_ent.origin;
		
	level.rescue_waypoint_locs = [];
	level.rescue_waypoint_locs[ 0 ] = ( -3152, 1356, 610 );
	level.rescue_waypoint_locs[ 1 ] = ( -5081, -2715, 522 );
	level.rescue_waypoint_locs[ 2 ] = ( -1105, -1760, 831 );
	level.rescue_waypoint_locs[ 3 ] = final_waypoint_loc;
	level.rescue_waypoint_locs[ 4 ] = final_waypoint_loc;
}

restore_fog_setting()
{
	// values grabbed from mp_alien_town_art
	ent = SpawnStruct();
	
	ent.HDRColorIntensity 		= 1;
	ent.HDRSunColorIntensity 	= 1;
	ent.startDist   = 0;
	ent.halfwayDist = 2048;
	ent.red   = 0.206;
	ent.green = 0.255;
	ent.blue  = 0.317;
	ent.maxOpacity = 0.5;
	ent.transitionTime = 0;
	//Sun Fog
	ent.sunFogEnabled  = 1;
	ent.sunRed   = 0.791;
	ent.sunGreen = 0.435;
	ent.sunBlue  = 0.331;
	ent.sunDir   = (-0.893, 0.273, 0.35);
	ent.sunBeginFadeAngle = 8;
	ent.sunEndFadeAngle   = 64;
	ent.normalFogScale    = 0.06;
	//Sky Fog
	ent.skyFogIntensity = 1.0;
	ent.skyFogMinAngle  = 30;
	ent.skyFogMaxAngle  = 67;
	
	level.restore_fog_setting = ent;
}
nuke_fog_setting()
{
	// values grabbed from mp_alien_town_art
	ent = SpawnStruct();
	
	if (is_gen4())
	{
	//Alien Nuke_NG
	//NG_Fog
		ent.startDist   = 0;
		ent.halfwayDist = 2048;
		ent.red   = 0.498;
		ent.green = 0.343;
		ent.blue  = 0.192;
		ent.HDRColorIntensity = 1.25;
		ent.maxOpacity = 0.5;
		ent.transitionTime = 0;
	//NG_Sun Fog
		ent.sunFogEnabled  = 1;
		ent.sunRed   = 0.791;
		ent.sunGreen = 0.435;
		ent.sunBlue  = 0.331;
		ent.HDRSunColorIntensity = 1.25;
		ent.sunDir   = (-0.893, 0.273, 0.35);
		ent.sunBeginFadeAngle = 0;
		ent.sunEndFadeAngle   = 160;
		ent.normalFogScale    = 0.01;
	//NG_Sky Fog
		ent.skyFogIntensity = 0.9;
		ent.skyFogMinAngle  = 30;
		ent.skyFogMaxAngle  = 71;		
	} else {
	// current gen
	//Fog
		ent.startDist   = 0;
		ent.halfwayDist = 2048;
		ent.red   = 0.498;
		ent.green = 0.343;
		ent.blue  = 0.192;
		ent.maxOpacity = 0.5;
		ent.transitionTime = 0;
	//Sun Fog
		ent.sunFogEnabled  = 1;
		ent.sunRed   = 0.791;
		ent.sunGreen = 0.435;
		ent.sunBlue  = 0.331;
		ent.sunDir   = (-0.893, 0.273, 0.35);
		ent.sunBeginFadeAngle = 0;
		ent.sunEndFadeAngle   = 160;
		ent.normalFogScale    = 0.01;
	//Sky Fog
		ent.skyFogIntensity = 0.9;
		ent.skyFogMinAngle  = 30;
		ent.skyFogMaxAngle  = 71;
		ent.HDROverride = "alien_nuke_HDR";
	}	

	level.nuke_fog_setting = ent;
}

/#
test_meteoroid()
{
	wait 10;
	
	thread maps\mp\alien\_spawnlogic::spawn_alien_meteoroid( "minion" );
	wait 2;
	thread maps\mp\alien\_spawnlogic::spawn_alien_meteoroid( "minion" );
	wait 10;
	thread maps\mp\alien\_spawnlogic::spawn_alien_meteoroid( "minion" );
}
#/

	
// ambient quakes and tremors triggered by players in map
amb_quakes()
{
	level.quake_trigs = getentarray( "quake_trig", "targetname" );
	
	foreach ( quake_trig in level.quake_trigs )
		quake_trig thread run_quake_scene();
}

run_quake_scene()
{
	level endon( "game_ended" );
	// self is trig
	
	wait 5; // wait till players connects
		
	// setup
	self.movables = [];
	self.fx = [];
	
	if ( isdefined( self.target ) )
	{
		targeted_ents = getentarray( self.target, "targetname" );
		foreach ( targeted_ent in targeted_ents )
		{
			if ( !isdefined( targeted_ent.script_noteworthy ) )
				continue;
			
			if ( targeted_ent.script_noteworthy == "moveable" )
				self.movables[ self.movables.size ] = targeted_ent;
			
			if ( targeted_ent.script_noteworthy == "fx" )
				self.fx[ self.fx.size ] = targeted_ent;
		}
	}
	
	inner_radius = self.radius;
	outter_radius = self.script_radius;
	quake_origin = self.origin;
	
	// run main loop
	count = 1;
	while ( count )
	{
		foreach ( player in level.players )
		{
			if ( isalive( player ) && player IsTouching( self ) )
			{
				player PlaySound( "elm_quake_rumble" );
				wait 0.25;

				Earthquake( 0.3, 3, quake_origin, outter_radius );
				PhysicsJitter( quake_origin, outter_radius, inner_radius, 4.0, 6.0 );
				player PlayRumbleOnEntity( "heavy_3s" ); //heavy_3s //heavygun_fire
				
				foreach ( movable in self.movables )
					self thread quake_rotate( movable );
				
				count--;
				wait RandomIntRange( 20, 30 );
				break;
			}
		}
		
		wait 1; // slower sample rate
	}
}

quake_rotate( movable_ent )
{
	self notify( "moving" );
	self endon( "moving" );
	
	// self is trig
	// movable_ent has target struct as move/rotate to reference	
	
	moveto_ent 		= getstruct( movable_ent.target, "targetname" );
	assert( isdefined( moveto_ent ) );
	
	original_angles = movable_ent.angles;
	moveto_angles 	= moveto_ent.angles;
	oscillation 	= 5;
	move_interval 	= 0.8;
	
	// rotate
	for ( i = 0; i< oscillation; i++ )
	{
		angles 		= angles_frac( original_angles, moveto_angles,  1 - ( i / oscillation ) );
		interval 	= move_interval * ( ( i + 1 ) / oscillation );
		
		movable_ent rotateto( angles, interval );
		wait interval;
		movable_ent rotateto( original_angles, interval );
		wait interval;
	}
}

angles_frac( angles_1, angles_2, fraction )
{
	fraction *= fraction;
	
	pitch 	= angles_1[ 0 ] + ( angles_2[ 0 ] - angles_1[ 0 ] ) * fraction;
	yaw 	= angles_1[ 1 ] + ( angles_2[ 1 ] - angles_1[ 1 ] ) * fraction;
	roll 	= angles_1[ 2 ] + ( angles_2[ 2 ] - angles_1[ 2 ] ) * fraction;
	
	return ( pitch, yaw, roll );
}

mp_alien_town_intro_dialog()
{
	wait ( 2 );
	sound_ent = spawn( "script_origin",( 0,0,0 ) );	
	sound_ent thread maps\mp\alien\_music_and_dialog::play_pilot_vo ("so_alien_plt_introlastsquad");
	
	level waittill( "introscreen_over" );
	sound_ent delaythread (0.067, maps\mp\alien\_music_and_dialog::play_pilot_vo ,"so_alien_plt_introunearthed");
	sound_ent delaythread ( 4.667, maps\mp\alien\_music_and_dialog::play_pilot_vo,"so_alien_plt_introdrill");
	sound_ent delaythread ( 15.767, maps\mp\alien\_music_and_dialog::play_pilot_vo,"so_alien_goodluck");
	level delaythread( 17.5, maps\mp\alien\_music_and_dialog::PlayVOForIntro );	
	wait ( 20 );	
	sound_ent delete();
	
}

should_play_next_hive_vo_func()
{
	if ( level.cycle_count + 1 == 14 ) //no VO if this is the last hive
		return false;
	
	if ( flag_exist( "hives_cleared" ) && flag( "hives_cleared")  ) //no "post hive" VO after the last hive is destroyed
		return false;
	
	return ( !isDefined( level.blocker_hives[ level.cycle_count + 1 ] ) ); //test for the blocker hive being the next hive
	
}

//this gets run just as the intro screen is finishing , but before the fadein starts
mp_alien_town_post_intro_func()
{
	//force a weapon switch at this point for all players
	foreach ( player in level.players )
	{
		if ( isDefined ( player.default_starting_pistol ) )
			player SwitchToWeapon ( player.default_starting_pistol  );
	}
}

//for level specific functions that need to kick off on gametype startup
mp_alien_town_onStartGameTypeFunc()
{
	level mp_alien_town_pillage_modification(); 
	level alter_drill_locations();
}

mp_alien_town_pillage_modification()
{
	//fix broken pillage spots
	distcheck = 10*10; //within 10 units
	
	pillage_areas = getstructarray( "pillage_area","targetname" );
	foreach( index,area in pillage_areas)
	{
		pillage_spots = getstructarray( area.target,"targetname" );
		foreach ( spot in pillage_spots )
		{
			if ( DistanceSquared( spot.origin, (-3771, 1288, 830) ) <= distcheck ) //fixing a bug where one of the spots spawned the trophy in the wall with no use prompt.
			{
				spot.origin = spot.origin + ( 0, 15, -4 );
				return;
			}
		}
	}
}

// Move the drill locations in script to make sure they're in safe locations
alter_drill_locations()
{
	set_drill_location( "city_lung_4", ( -4285.85, -3098.1, 550.75 ), ( 2.87763, 77.0197, -2.07208 ) );
	set_drill_location( "lake_lung_1", ( -3286.2, 699.453, 671.517 ), ( 356.167, 249.913, 1.77588 ) );
	set_drill_location( "lake_lung_2", ( -1620.41, 1558.15, 758 ), ( 0, 161.813, 0 ) );
	set_drill_location( "lake_lung_3", ( -3542.69, 2058.54, 570.984 ), ( 0.647456, 186.237, -1.42968 ) );
	set_drill_location( "lake_lung_4", ( -2977.48, 1790.44, 565.36 ), ( 358.167, 184.775, -5.04523 ) );
	set_drill_location( "lake_lung_6", ( -2769.68, 3698.48, 419.95 ), ( 359.953, 22.833, -10.9619 ) );
	set_drill_location( "crater_lung", ( -4375.36, 3138.18, 285.152 ), ( 356.676, 249.752, 12.7989 ) );
}

set_drill_location( target_name, location, orientation )
{
	drillLocation = GetEnt( target_name, "target" );
	
	if ( IsDefined( drillLocation ) )
	{
		drillLocation.origin = location;
		drillLocation.angles = orientation;
	}
}


TU_electric_fence_fix()
{
	while ( !isdefined( level.electric_fences ) )
		wait 0.05;
	
	wait 5;
	
	foreach ( fence in level.electric_fences )
	{
		// parcing target name due to possibility of prefab prefixing to auto target labeler
		target_name = fence.generator.target;
		target_name_array = StrTok( fence.generator.target, "_" );
		if ( target_name_array.size > 0 )
		{
			foreach ( name in target_name_array )
			{
				if ( IsSubStr( name, "auto" ) )
					target_name = name;
			}
		}
		
		if ( isdefined( fence.generator.target ) && ( target_name == "auto92" ) )
			fence.shock_trig.origin += ( 0, 0, 30 );
		
		if ( isdefined( fence.generator.target ) && ( target_name == "auto3" ) )
		{
			fence.shock_trig.origin += ( 102, 64, 30 );
			fence.shock_damage = 800; // shock damage override because we can no longer adjust fence height in bsp to increase damage
		}
	}
}

player_initial_spawn_loc_override()
{
/#
	if ( alien_mode_has( "nogame" ) )
		return;
#/
	if ( is_chaos_mode() )
	{
		chaos_player_initial_spawn_loc_override();
		return;
	}	
		
	AFTER_NUKE_ACTIVATION_SPAWN_ORIGIN = ( -4297, 3215, 303 );
	AFTER_NUKE_ACTIVATION_SPAWN_ANGLES = ( 0, -6, 0 );
	
	if ( flag( "nuke_countdown" ) )
	{
		self.forceSpawnOrigin = AFTER_NUKE_ACTIVATION_SPAWN_ORIGIN;
		self.forceSpawnAngles = AFTER_NUKE_ACTIVATION_SPAWN_ANGLES;
	}
}

skip_escape()
{
}

chaos_player_initial_spawn_loc_override()
{
	location_list = [];
	angle_list	  = [];
	switch( get_chaos_area() )
	{
		case "lodge":
			location_list = [ ( 410, -1084, 708.838 ), ( 559, -1239, 705.007 ), ( 753, -1115, 709.901 ), ( 532, -930, 703.947 ) ];
			angle_list	  = [ ( 0, 210, 0 ), ( 0, 210, 0 ), ( 0, 345, 0 ), ( 0, 345, 0 ) ];
			break;
			
		case "city":
			location_list = [ ( -4449, -2801, 535.798 ), ( -4496, -3085, 539.619 ), ( -4300, -3088, 549.954 ), ( -4209, -3326, 552.298 ) ];
			angle_list	  = [ ( 0, 210, 0 ), ( 0, 210, 0 ), ( 0, 345, 0 ), ( 0, 345, 0 ) ];
			break;
			
		case "cabin":
			location_list = [ ( -2105, 2215, 580 ), ( -2029, 2103, 579 ), ( -3462, 1786, 573 ), ( -3451, 1892, 565 ) ];
			angle_list	= [ ( 0, 210, 0 ), ( 0, 210, 0 ), ( 0, 345, 0 ), ( 0, 345, 0 ) ];
			break;
	}
	
	self.forceSpawnOrigin = location_list[ level.players.size ];
	self.forceSpawnAngles = angle_list	 [ level.players.size ];
}

mp_alien_town_try_use_drone_hive( rank, num_missiles, missile_name, altitude, baby_missile_name )
{
	self maps\mp\alien\_switchblade_alien::tryUseDroneHive( rank, num_missiles, missile_name, altitude, baby_missile_name );
}

//*****************************************************************
//					Attack chopper use
//*****************************************************************

CONST_CHOPPER_COST 			= 6000;
CONST_CHOPPER_COST_SOLO 	= 3000;
CONST_CHOPPER_UNIT_COST 	= 1000;
CONST_CHOPPER_LOOPS			= 6;
CONST_CHOPPER_LOOPS_SOLO	= 4;

remove_upon_escape_sequence()
{
	level waittill( "all_players_using_nuke" );
	self delete();
}


attack_chopper_monitorUse()
{
	level endon( "game_ended" );
	level endon( "all_players_using_nuke" ); // can't use during ending escape! too easy and its double chopper
	
	self thread remove_upon_escape_sequence();
	self endon( "death" );
	
	self SetCursorHint( "HINT_NOICON" );
	self SetHintString( &"ALIEN_COLLECTIBLES_ACTIVATE_ATTACK_CHOPPER" );
	self MakeUsable();
	
	// wait before players are ready, we decide how to setup usage based on match type
	while ( !isdefined( level.players ) || level.players.size < 1 )
		wait 0.05;
	
	if ( isPlayingSolo() )
	{
		level.chopper_cost 	= CONST_CHOPPER_COST_SOLO;
		level.chopper_loops = CONST_CHOPPER_LOOPS_SOLO;
	}
	else
	{
		level.chopper_cost 	= CONST_CHOPPER_COST;
		level.chopper_loops = CONST_CHOPPER_LOOPS;
	}

	// wait till features are defined by level script
	wait 0.05;
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::add_to_outline_watch_list( self, CONST_CHOPPER_UNIT_COST );
	
	// shared between multiple chopper call nodes
	level.attack_chopper_pot 			= 0;
	level.attack_chopper_reward_pool 	= [];
	
	while ( true )
	{
		self waittill ( "trigger", player );
		
		if ( !isPlayer ( player ) )
		{
			wait 0.05;
			continue;
		}
		
		if ( level.attack_chopper_pot >= level.chopper_cost )
		{
			wait 0.05;
			continue;
		}
		
		if ( !chopper_active() )
		{
			if ( player can_purchase_chopper() )
			{
				player maps\mp\alien\_persistence::take_player_currency( CONST_CHOPPER_UNIT_COST, false, "trap" );
				
				level.attack_chopper_pot += CONST_CHOPPER_UNIT_COST;
				level.attack_chopper_reward_pool[ level.attack_chopper_reward_pool.size ] = player;
				
				if ( level.attack_chopper_pot >= level.chopper_cost )
				{	
					//reset
					level.attack_chopper_pot = 0; 
					
					level thread maps\mp\alien\_airdrop::call_in_attack_heli( level.chopper_loops, level.attack_chopper_reward_pool );
					
					level thread maps\mp\alien\_music_and_dialog::playVOforAttackChopper( player );
					
					level.attack_chopper_reward_pool = [];
					
					// incoming splash
					thread teamPlayerCardSplash( "attack_chopper_enroute", player, player.team );
					
					self SetHintString( "" );
					
					if ( alien_mode_has( "outline" ) )
						maps\mp\alien\_outline_proto::remove_from_outline_watch_list( self );
					
					while ( chopper_active() )
						wait 1;
					
					if ( alien_mode_has( "outline" ) )
						maps\mp\alien\_outline_proto::add_to_outline_watch_list( self, CONST_CHOPPER_UNIT_COST );
					
					self SetHintString( &"ALIEN_COLLECTIBLES_ACTIVATE_ATTACK_CHOPPER" );
				}
				else
				{
					if ( isPlayingSolo() )
						player thread maps\mp\gametypes\_hud_message::playerCardSplashNotify( "attack_chopper_pot_solo", player, level.attack_chopper_pot );
					else
						thread teamPlayerCardSplash( "attack_chopper_pot", player, player.team, level.attack_chopper_pot );
					
					if ( is_chaos_mode() )
						iprintlnBold( "$" + level.attack_chopper_pot + " / $" + level.chopper_cost );
					
					self MakeUnUsable();
					self SetHintString( "" );
					wait 0.5; // cooldown
					self MakeUsable();
					self SetHintString( &"ALIEN_COLLECTIBLES_ACTIVATE_ATTACK_CHOPPER" );
				}
			}
			else
			{
				player setLowerMessage( "no_money", &"ALIEN_COLLECTIBLES_NO_MONEY", 3 );
				//pot = "Not enough money! Pot: $" + level.attack_chopper_pot + "/$" + level.chopper_cost;
				//player iprintlnBold( pot );
			}
		}
		else
		{
			if ( isdefined( level.hive_heli ) )
				player setLowerMessage( "busy", &"ALIEN_COLLECTIBLES_ATTACK_CHOPPER_ACTIVE", 3 );
		}
	}
}

can_purchase_chopper()
{
	//can_purchase = ( ( level.chopper_cost - level.attack_chopper_pot ) >= CONST_CHOPPER_UNIT_COST );
		
	return self maps\mp\alien\_persistence::player_has_enough_currency( CONST_CHOPPER_UNIT_COST );
}

chopper_active()
{
	// self is player
	return isdefined( level.attack_heli ) || isdefined( level.hive_heli );
}

/////////////////////////////////////////////////////////////////
//                   Blocker hive encounter
/////////////////////////////////////////////////////////////////
blocker_hive()
{
	level endon( "game_ended" );
	
	selected_blocker_hives = select_hives( true );
	AssertEx( selected_blocker_hives.size == 1, "Not exactly one blocker hive is selected" );
	blocker_hive = selected_blocker_hives[0];
	
	level.encounter_name = blocker_hive.target;
	
	attackable_ent = create_attackable_ent( blocker_hive );
	blocker_hive.attackable_ent = attackable_ent;
	level.current_blocker_hive = blocker_hive;
	
	level thread maps\mp\alien\_spawnlogic::encounter_cycle_spawn( "blocker_hive_heli_inbound" );
	
	pre_heli_sequence( attackable_ent );
	
	heli_inbound( attackable_ent, blocker_hive );

	attackable_ent waittill( "death" );
	
	maps\mp\alien\_spawn_director::end_cycle();
	
	level.encounter_name = undefined;
	
	blocker_hive_explode_sequence( attackable_ent, blocker_hive );
	
	give_players_rewards( true, ::get_blocker_hive_score_component_name_list );
}

CONST_MESSAGE_DELAY      = 20; // sec
CHOPPER_STATE_INCOMING   = 3;
CONST_BLOCKER_HIVE_DELAY = 50;
pre_heli_sequence( attackable_ent )
{
	wait CONST_MESSAGE_DELAY;

	attackable_ent maps\mp\alien\_music_and_dialog::playVOForIncomingChopperBlockerHive();
	
	//screen message regarding the incoming helicopter
	level thread maps\mp\alien\_airdrop::inbound_chopper_text();
	
	SetOmnvar ( "ui_alien_boss_progression", 0 );		//set hive health to full
	SetOmnvar ( "ui_alien_chopper_state" , CHOPPER_STATE_INCOMING );
	
	// wait for intermission delay
	wait max( 5, CONST_BLOCKER_HIVE_DELAY - CONST_MESSAGE_DELAY );
}

HELI_INBOUND_EARTHQUAKE_INTENSITY = 0.4;
HELI_INBOUND_WARN_DELAY = 0.1;
heli_inbound( attackable_ent, blocker_hive )
{
	// calls in assault chopper to blocker hive
	thread maps\mp\alien\_airdrop::call_in_hive_heli( attackable_ent );	
	
	wait 1; // wait till hive heli is created
	
	// wait for chopper ready to assault
	if( isdefined( level.hive_heli ) )
	{
		if ( level.hive_heli ent_flag_exist( "assault_ready" ) && !level.hive_heli ent_flag( "assault_ready" ) )
			level.hive_heli ent_flag_wait( "assault_ready" );
		
		level notify( "blocker_hive_heli_inbound" );
	}
	
	attackable_ent show();
	attackable_ent SetCanDamage( true );
	attackable_ent thread maps\mp\alien\_hud::blocker_hive_hp_bar();
	attackable_ent thread monitor_attackable_ent_damage( blocker_hive );
	attackable_ent thread maps\mp\alien\_music_and_dialog::playVOForProvidingCoverAtBlockerHive();
	
	blocker_hive hive_play_drill_planted_animations();
	blocker_hive thread set_hive_icon( "waypoint_alien_blocker", 7000, 20, 20 );	

	//challenge widget to show the barrier hive intel
	level maps\mp\alien\_challenge_function::show_barrier_hive_intel();
	level.current_hive_name = blocker_hive.target;	
	level.blocker_hive_active = true;	
	
	/#
		thread debug_spitter_population();
	#/
	
	// reset hive score
	maps\mp\alien\_gamescore::reset_encounter_performance();
		
	thread warn_all_players( HELI_INBOUND_WARN_DELAY, HELI_INBOUND_EARTHQUAKE_INTENSITY );
}

/////////////////////////////////////////////////////////////
//         JUMP TO: mp_alien_town
/////////////////////////////////////////////////////////////
jump_to_1st_area()
{
/#
	PLAYER_SPAWN_POS_1 = ( 2623, -15, 549 );
	PLAYER_SPAWN_POS_2 = ( 2758, 276, 502 );
	PLAYER_SPAWN_POS_3 = ( 2453, 169, 526 );
	PLAYER_SPAWN_POS_4 = ( 2438, -211, 594 );
	DRILL_SPAWN_POS = ( 2843, -171, 572 );
	hives_to_remove = [];
	
	maps\mp\alien\_debug::common_hive_drill_jump_to( [ PLAYER_SPAWN_POS_1, PLAYER_SPAWN_POS_2, PLAYER_SPAWN_POS_3, PLAYER_SPAWN_POS_4 ], DRILL_SPAWN_POS, hives_to_remove );
#/
}

jump_to_lodge()
{
/#
	PLAYER_SPAWN_POS_1 = ( 353, -1121, 770 );
	PLAYER_SPAWN_POS_2 = ( 698, -991, 765 );
	PLAYER_SPAWN_POS_3 = ( 1129, -1114, 770 );
	PLAYER_SPAWN_POS_4 = ( 793, -1283, 765 );
	DRILL_SPAWN_POS = ( 669, -1107, 770 );
	hives_to_remove = [ "mini_lung" ];
	
	maps\mp\alien\_debug::common_hive_drill_jump_to( [ PLAYER_SPAWN_POS_1, PLAYER_SPAWN_POS_2, PLAYER_SPAWN_POS_3, PLAYER_SPAWN_POS_4 ], DRILL_SPAWN_POS, hives_to_remove );
	maps\mp\alien\_debug::delete_intro_heli_collision();
#/
}

jump_to_city()
{
/#
	PLAYER_SPAWN_POS_1 = ( -4357, -3089, 608 );
	PLAYER_SPAWN_POS_2 = ( -4550, -2805, 588 );
	PLAYER_SPAWN_POS_3 = ( -4212, -2527, 595 );
	PLAYER_SPAWN_POS_4 = ( -4086, -2845, 611 );
	DRILL_SPAWN_POS = ( -4196, -2715, 604 );
	hives_to_remove = [ "mini_lung", "lodge_lung_1", "lodge_lung_2", "lodge_lung_3", "lodge_lung_4", "lodge_lung_5", "lodge_lung_6" ];
	
	maps\mp\alien\_debug::common_hive_drill_jump_to( [ PLAYER_SPAWN_POS_1, PLAYER_SPAWN_POS_2, PLAYER_SPAWN_POS_3, PLAYER_SPAWN_POS_4 ], DRILL_SPAWN_POS, hives_to_remove );
	maps\mp\alien\_debug::delete_intro_heli_collision();
#/	
}

jump_to_cabin()
{
/#
	PLAYER_SPAWN_POS_1 = ( -2519, 1447, 639 );
	PLAYER_SPAWN_POS_2 = ( -2386, 1811, 642 );
	PLAYER_SPAWN_POS_3 = ( -2705, 1901, 628 );
	PLAYER_SPAWN_POS_4 = ( -2563, 1373, 646 );
	DRILL_SPAWN_POS = ( -2645, 1719, 636 );
	hives_to_remove = [ "mini_lung", "lodge_lung_1", "lodge_lung_2", "lodge_lung_3", "lodge_lung_4", "lodge_lung_5", "lodge_lung_6", "city_lung_1", "city_lung_2", "city_lung_3", "city_lung_4", "city_lung_5" ];
	
	maps\mp\alien\_debug::common_hive_drill_jump_to( [ PLAYER_SPAWN_POS_1, PLAYER_SPAWN_POS_2, PLAYER_SPAWN_POS_3, PLAYER_SPAWN_POS_4 ], DRILL_SPAWN_POS, hives_to_remove );
	maps\mp\alien\_debug::delete_intro_heli_collision();
#/	
}

jump_to_crater_hive()
{
/#
	PLAYER_SPAWN_POS_1 = ( -3855, 3083, 366 );
	PLAYER_SPAWN_POS_2 = ( -3818, 3344, 359 );
	PLAYER_SPAWN_POS_3 = ( -4171, 3380, 339 );
	PLAYER_SPAWN_POS_4 = ( -4194, 2899, 365 );
	DRILL_SPAWN_POS = ( -3899, 3037, 367 );
	hives_to_remove = [ "mini_lung", "lodge_lung_1", "lodge_lung_2", "lodge_lung_3", "lodge_lung_4", "lodge_lung_5", "lodge_lung_6", "city_lung_1", "city_lung_2", "city_lung_3", "city_lung_4", "city_lung_5", "lake_lung_1", "lake_lung_2", "lake_lung_3", "lake_lung_4", "lake_lung_6" ];
	
	maps\mp\alien\_debug::common_hive_drill_jump_to( [ PLAYER_SPAWN_POS_1, PLAYER_SPAWN_POS_2, PLAYER_SPAWN_POS_3, PLAYER_SPAWN_POS_4 ], DRILL_SPAWN_POS, hives_to_remove );
	maps\mp\alien\_debug::delete_intro_heli_collision();
#/	
}

jump_to_escape()
{
/#
	PLAYER_SPAWN_POS_1 = ( -3855, 3083, 366 );
	PLAYER_SPAWN_POS_2 = ( -3818, 3344, 359 );
	PLAYER_SPAWN_POS_3 = ( -4171, 3380, 339 );
	PLAYER_SPAWN_POS_4 = ( -4194, 2899, 365 );
	DRILL_SPAWN_POS = ( -3899, 3037, 367 );
	hives_to_remove = [ "mini_lung", "lodge_lung_1", "lodge_lung_2", "lodge_lung_3", "lodge_lung_4", "lodge_lung_5", "lodge_lung_6", "city_lung_1", "city_lung_2", "city_lung_3", "city_lung_4", "city_lung_5", "lake_lung_1", "lake_lung_2", "lake_lung_3", "lake_lung_4", "lake_lung_6", "crater_lung" ];
	
	maps\mp\alien\_debug::common_hive_drill_jump_to( [ PLAYER_SPAWN_POS_1, PLAYER_SPAWN_POS_2, PLAYER_SPAWN_POS_3, PLAYER_SPAWN_POS_4 ], DRILL_SPAWN_POS, hives_to_remove );
	maps\mp\alien\_debug::delete_intro_heli_collision();
	flag_set( "hives_cleared" );
#/		
}

mp_alien_town_pillage_init()
{
	level.pillageInfo = spawnstruct();
	level.pillageInfo.alienattachment_model		= "weapon_alien_muzzlebreak";
	level.pillageInfo.default_use_time 			= 1000;
	level.pillageInfo.money_stack				= "pb_money_stack_01";
	level.pillageInfo.attachment_model			= "has_spotter_scope";
	level.pillageInfo.maxammo_model 			= "mil_ammo_case_1_open";
	level.pillageInfo.flare_model				= "mil_emergency_flare_mp";
	level.pillageInfo.clip_model				= "weapon_baseweapon_clip";
	level.pillageInfo.soflam_model				= "weapon_soflam";
	level.pillageInfo.leash_model				= "weapon_knife_iw6";
	level.pillageInfo.trophy_model				= "mp_trophy_system_folded_iw6";
	level.pillageInfo.ui_searching				= 1;
	
	// % chance ( should equal 100% for each category )	 								   	
	level.pillageInfo.easy_attachment			= 32;   // 32% chance user finds an attachment
	level.pillageInfo.easy_money				= 20;	// 20% chance user finds $$
	level.pillageInfo.easy_clip					= 20;  	// 20% chance user finds a clip
	level.pillageInfo.easy_explosive			= 15;  	// 15% chance user finds an explosive ( only a grenade or flare )
	level.pillageInfo.easy_soflam				= 5;	// 5%  chance user finds the soflam
	level.pillageInfo.easy_specialammo			= 5;	// 5%  chance user finds specialty ammo
	level.pillageInfo.easy_leash				= 3;	// 3%  chance user finds the leash
	
	level.pillageInfo.medium_attachment			= 35;   // 35% chance user finds an attachment
	level.pillageInfo.medium_explosive			= 15;  	// 15% chance user finds an explosive
	level.pillageInfo.medium_money				= 15;	// 15% chance user finds $$
	level.pillageInfo.medium_clip				= 10;  	// 10% chance user finds a clip
	level.pillageInfo.medium_specialammo		= 10;	// 10% chance user finds specialty ammo
	level.pillageInfo.medium_leash				= 5;	// 5%  chance user finds the leash
	level.pillageInfo.medium_soflam				= 5;	// 10% chance user finds the soflam
	level.pillageInfo.medium_trophy				= 5;	// 5%  chance user finds trophy
	
	level.pillageInfo.hard_attachment			= 40;   // 40% chance user finds an attachment
	level.pillageInfo.hard_explosive			= 15;  	// 20% chance user finds an explosive
	level.pillageInfo.hard_leash				= 10;	// 10% chance user finds the leash
	level.pillageInfo.hard_maxammo				= 10;  	// 10% chance user finds max ammo
	level.pillageInfo.hard_specialammo			= 10;	// 10% chance user finds specialty ammo
	level.pillageInfo.hard_money				= 5;	// 5%  chance user finds $$
	level.pillageInfo.hard_soflam				= 5;	// 5%  chance user finds the soflam
	level.pillageInfo.hard_trophy				= 5;	// 5%  chance user finds trophy
	
	level.crafting_item_table					= "mp/alien/crafting_items.csv";		// craftable item names and omnvars
	level.crafting_table_item_index				= 0;	// omnvar
	level.crafting_table_item_ref				= 1;	// reference string
	level.crafting_table_item_name				= 2;	// 
	level.crafting_table_item_icon				= 3;	// localization name
	level.max_crafting_items					= 3;
	level.crafting_model						= "weapon_baseweapon_clip";

	level.pillageInfo.crafting_easy 			= 0;
	level.pillageInfo.crafting_medium 			= 0;
	level.pillageInfo.crafting_hard 			= 0;
}

set_spawn_table()
{
	if ( is_chaos_mode() )
	{
		set_chaos_spawn_table();
		return;
	}

	if ( is_hardcore_mode() )
		set_hardcore_extinction_spawn_table();
}

set_chaos_spawn_table()
{
	if ( isPlayingSolo() )
	{
		switch( get_chaos_area() )
		{
		case "lodge":
			level.alien_cycle_table = "mp/alien/chaos_spawn_town_lodge_sp.csv";
			break;
		
		case "city":
			level.alien_cycle_table	= "mp/alien/chaos_spawn_town_city_sp.csv";
			break;
			
		case "cabin":
			level.alien_cycle_table	= "mp/alien/chaos_spawn_town_cabin_sp.csv";
			break;
		}
	}
    else
    {
    	switch( get_chaos_area() )
		{
		case "lodge":
			level.alien_cycle_table = "mp/alien/chaos_spawn_town_lodge.csv";
			break;
		
		case "city":
			level.alien_cycle_table = "mp/alien/chaos_spawn_town_city.csv";
			break;
			
		case "cabin":
			level.alien_cycle_table = "mp/alien/chaos_spawn_town_cabin.csv";
			break;
		}
    }
}

chaos_init()
{
    init_hive_locs();
    
    maps\mp\alien\_airdrop::init_fx();
    
    level thread armory_chaos_nondeterministic_entity_handler();
    
    level.removed_hives[ level.removed_hives.size ] = "mini_lung";
    
    maps\mp\alien\_chaos::init();
    
    register_egg_default_loc();
    
    set_player_count_multiplier();
    
    set_end_cam_position();
}

armory_chaos_nondeterministic_entity_handler()
{
	level endon( "game_ended" );
	
	NONDETERMINISTIC_ENTITY_WAIT = 5;
	wait NONDETERMINISTIC_ENTITY_WAIT;
	
	delete_intro_heli_clip();
	
	move_clip_brush_cabin_to_city();
    
    move_clip_brush_cabin_to_lake();
    
	move_clip_to_cliffside();
	
	move_clip_brush_cliff_exploit();
}

town_chaos_adjust_spawnLocation( spawn_location )
{
	if ( spawn_location.origin == ( -5716, -2031, 524 ) )
	{
		spawn_location.origin = ( -6011.5, -1494.5, 415.5 );
		spawn_location.angles =  ( 0,0,0 );
		spawn_location.script_noteworthy = "cabin_spawn_ground";
	}
	return spawn_location;
}

move_clip_to_cliffside()
{
		clip		   = GetEnt ( "player256x256x8", "targetname" );
		clipEnt		   = Spawn( "script_model", ( -6294, -1282, 558 ) );
		clipEnt.angles = ( 270, 68, 3 );
        clipEnt CloneBrushmodelToScriptmodel( clip );
}

move_clip_brush_cliff_exploit()
{
		clip		= GetEnt ( "player512x512x8", "targetname" );
		clipEnt		= Spawn ( "script_model", ( -4320, 2120, 572 ) );
		clipEnt.angles = ( 270, 5, 1.28 );
		clipEnt CloneBrushmodelToScriptmodel( clip );
}

set_end_cam_position()
{
	points = getEntArray( "mp_global_intermission", "classname" );
	end_point = getClosest( level.eggs_default_loc,points );
	
	switch( get_chaos_area() )
	{
	case "lodge":
		end_point.origin = ( -3840, 1632, 1008 );
		end_point.angles = ( 25,0,0 );
		break;
	
	case "city":
		end_point.origin = ( -3840, 1632, 1008 );
		end_point.angles = ( 25,0,0 );
		break;
		
	case "cabin":
		end_point.origin = ( -3840, 1632, 1008 );
		end_point.angles = ( 25,0,0 );
		break;
	}	
}

set_player_count_multiplier()
{
	if ( isPlayingSolo() )
		level.base_player_count_multiplier = 1;
	else
		level.base_player_count_multiplier = .49;
}

register_egg_default_loc()
{
	switch( get_chaos_area() )
	{
	case "lodge":
		maps\mp\alien\_chaos::set_egg_default_loc( ( -2534, 1751, 421 ) );
		break;
	
	case "city":
		maps\mp\alien\_chaos::set_egg_default_loc( ( -2534, 1751, 421 ) );
		break;
		
	case "cabin":
		maps\mp\alien\_chaos::set_egg_default_loc( ( -2534, 1751, 421 ) );
		break;
	}
}

/*
 Leaving this here in case we bring it back
block_city_exit()
{
	meteor_model = "mp_ext_alien_meteor";
	meteor_org = ( -5692, -1988, 604 );
	meteor_angles = ( 0,180,0 );
	clip_model = getent("player128x128x8","targetname" );
	clip_org = ( -5659, -1915, 580.5 );
	clip_angles = ( 270, 245, -180 );
	city_exit_clip = spawn( "script_model",clip_org );	
	city_exit_clip.angles = clip_angles;
	city_exit_clip CloneBrushmodelToScriptmodel( clip_model );
	meteor = spawn( "script_model",meteor_org );
	meteor.angles = meteor_angles;
	meteor SetModel ( meteor_model );	
}
*/

move_clip_brush_cabin_to_city()
{
        clip = GetEnt ( "player256x256x256", "targetname" );
        clip.origin = ( -5374, -2662, 498 );
        clip.angles = ( 0, 248, 0 );
}

move_clip_brush_cabin_to_lake()
{
        clip = GetEnt ( "player128x128x256", "targetname" );
        clip.origin = ( -3448, 2256, 618 );
        clip.angles = ( 270, 344, -8.36695 );
}

delete_intro_heli_clip()
{	
	helibrush = GetEnt( "helicoptercoll", "targetname" );
	helibrush delete();
}

set_hardcore_extinction_spawn_table()
{
	if ( isPlayingSolo() )
    	level.alien_cycle_table_hardcore	= "mp/alien/cycle_spawn_town_hardcore_sp.csv";
    else
    	level.alien_cycle_table_hardcore 	= "mp/alien/cycle_spawn_town_hardcore.csv";
}

mp_alien_town_onSpawnPlayer_func()
{
	if( !IsDefined( level.setSkillsFlag ) )
	{
		level.setSkillsFlag = true;
		flag_set( "give_player_abilities" );
	}
	self thread maps\mp\alien\_alien_class_skills_main::assign_skills();
}

update_weapon_placement()
{
	items = getstructarray( "item", "targetname" );
	
	//replace the honeybadger with the ak12
	foreach ( world_item in items )
	{
		if ( !isDefined( world_item.script_noteworthy ) )
			continue;
		
		if ( world_item.script_noteworthy == "weapon_iw6_alienhoneybadger_mp" )
		{
			world_item.script_noteworthy = "weapon_iw6_alienak12_mp";
			world_item.origin = (-1503.68, 1942.12, 598.9);
			break; 
		}
	}
	return undefined;
}