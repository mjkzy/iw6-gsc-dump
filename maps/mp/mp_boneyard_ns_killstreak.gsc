#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

boneyard_killstreak_setup()
{
	// create killstreak struct
	level.ks_vertical				= SpawnStruct();
	level.ks_vertical.sfx			= GetEnt( "ks_vertical_org", "targetname" );
	level.ks_vertical.dam			= GetEnt( "ks_vertical_damage_vol", "targetname" );
	level.ks_vertical.destructibles = [ ( 481, -74, -100 ) ];
	level.ks_vertical.uses			= 0;
	level.ks_vertical.max_uses		= 1;
	level.ks_vertical.player		= undefined;
	level.ks_vertical.team			= undefined;
	
	level.ks_vertical.inflictor = GetEnt ( "vert_fire_ent", "targetname" );
	
	// setup minimap killstreak objective marker
	level.ks_vertical.ui_icon	   = [];
	level.ks_vertical.ui_icon[ 0 ] = "compass_icon_vf_idle";
	level.ks_vertical.ui_icon[ 1 ] = "compass_icon_vf_active";
	level.ks_vertical.ui_state	   = 0;
	level.ks_vertical.ui_elem	   = maps\mp\gametypes\_gameobjects::getNextObjID();
	Objective_Add( level.ks_vertical.ui_elem, "active", ( 381.5, 120, 254 ), level.ks_vertical.ui_icon[ 0 ] );
	Objective_PlayerMask_HideFromAll( level.ks_vertical.ui_elem );
	
	//level.alarm1_a = Spawn( "script_origin", (355, 397, 729) );
	level.alarm1_a	 = Spawn( "script_origin", ( 1936, 231, 221 ) );
	level.alarm1_b	 = Spawn( "script_origin", ( 520, -224, 199 ) );
	level.alarm1_c	 = Spawn( "script_origin", ( 346, 150, 246 ) );
	level.alarm1_cp1	 = Spawn( "script_origin", ( 346, 150, 246 ) );
	level.alarm1_cp2	 = Spawn( "script_origin", ( 346, 150, 246 ) );
	level.alarm1_d	 = Spawn( "script_origin", ( -1028, 534, 368 ) );
	level.fire_node1 = Spawn( "script_origin", ( 1063, 112, -177 ) );
	level.fire_node1end = Spawn( "script_origin", ( 1063, 112, -177 ) );
	level.fire_node2 = Spawn( "script_origin", ( 1320, -439, -133 ) );
	level.fire_node2end = Spawn( "script_origin", ( 1320, -439, -133 ) );
	level.fire_node3 = Spawn( "script_origin", ( -283, 97, 16 ) );
	level.fire_node3end = Spawn( "script_origin", ( -283, 97, 16 ) );
	
	// setup flags
	flag_init( "boneyard_killstreak_captured" );
	flag_init( "boneyard_killstreak_can_kill" );
	flag_init( "boneyard_killstreak_active" );
	flag_init( "ks_vertical_alarm_on" );
	flag_init( "ks_vertical_firing" );
	flag_init( "boneyard_killstreak_endgame" );
	flag_clear( "boneyard_killstreak_endgame" );
	
	thread ks_manage_spawns();
}

BONEYARD_KILLSTREAK_WEIGHT = 200;
BONEYARD_KILLSTREAK_MULTIPLE_WEIGHT = 100;

boneyardCustomCrateFunc()
{
	level.allow_level_killstreak = allowLevelKillstreaks();
	if ( !level.allow_level_killstreak )
		return;
	
	//"Hold [{+activate}] to Activate F-1 Engine Test Fire."
	maps\mp\killstreaks\_airdrop::addCrateType(	"airdrop_assault",	"f1_engine_fire",	BONEYARD_KILLSTREAK_WEIGHT,	maps\mp\killstreaks\_airdrop::killstreakCrateThink,	maps\mp\killstreaks\_airdrop::get_friendly_crate_model(), maps\mp\killstreaks\_airdrop::get_enemy_crate_model(), &"MP_BONEYARD_NS_F1_ENGINE_FIRE_PICKUP" );
	
	// if player has KS from previous round restart ui_watcher || otherwise start crate watcher
	if ( IsDefined( game[ "player_holding_level_killstreak" ] ) && IsAlive( game[ "player_holding_level_killstreak" ] ) )
	{
		level.ks_vertical.player = game[ "player_holding_level_killstreak" ];
		level.ks_vertical.team	 = game[ "player_holding_level_killstreak" ].pers[ "team" ];
		flag_set( "boneyard_killstreak_captured" );
		thread boneyard_killstreak_ui_watcher( level.ks_vertical, 0.1 );
	}
	else
	{
		level thread boneyard_killstreak_watch_for_crate();
	}
}

boneyard_killstreak_watch_for_crate()
{
	while ( 1 )
	{
		level waittill( "createAirDropCrate", dropCrate );
		if ( IsDefined( dropCrate ) && IsDefined( dropCrate.crateType ) && dropCrate.crateType == "f1_engine_fire" )
		{	
			boneyard_killstreak_disable();
			captured = wait_for_capture( dropCrate );
			if ( !IsDefined( captured ) )
			{
				// Crate expired. Reset to initial killstreak weight.
				boneyard_killstreak_enable( BONEYARD_KILLSTREAK_WEIGHT );
			}
			else
			{
				level.ks_vertical.player				  = captured;
				level.ks_vertical.team					  = captured.pers[ "team" ];
				game[ "player_holding_level_killstreak" ] = captured;
				flag_set( "boneyard_killstreak_captured" );
				thread boneyard_killstreak_ui_watcher( level.ks_vertical, 0.1 );
			}
		}
	}
}

wait_for_capture( dropCrate )
{
	result = watch_for_air_drop_death( dropCrate );
	return result;
}

watch_for_air_drop_death( dropCrate )
{
	dropCrate endon( "death" );
	
	dropCrate waittill( "captured", player );
	return player;
}

boneyard_killstreak_bot_use()
{
	// don't fire if inside damage volume
	if ( IsDefined( level.ks_vertical.player ) && level.ks_vertical.player IsTouching( level.ks_vertical.dam ) )
		return false;
	
	// only fire if enemies are inside damage volume
	return flag( "boneyard_killstreak_can_kill" );
}

boneyard_killstreak_enable( WEIGHT )
{
	// check if player is already holding killstreak
	if ( IsDefined( game[ "player_holding_level_killstreak" ] ) && IsAlive( game[ "player_holding_level_killstreak" ] ) )
		return false;
	
	maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", "f1_engine_fire", WEIGHT );
}

boneyard_killstreak_disable()
{
	maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", "f1_engine_fire", 0 );
}

boneyard_killstreak_endgame()
{
	// wait till the end of the game
	level waittill( "game_cleanup" );
	maps\mp\gametypes\_gamelogic::waittillFinalKillcamDone();
	
	// fire warning lights
	flag_set( "boneyard_killstreak_endgame" );
	thread ks_vertical_warning_lights();
	
	// fire the killsreak
	thread sound_fire_loop_logic();
	thread ks_vertical_firing_fx();
	
	// cleanup
	wait( 10 );
	flag_clear( "boneyard_killstreak_endgame" );
}

sound_fire_loop_logic()
{
	level.fire_node1 PlayloopSound( "scn_fire_event_02_fire1_lp" );
	level.fire_node2 PlayloopSound( "scn_fire_event_02_fire2_lp" );
	level.fire_node3 PlayloopSound( "scn_fire_event_02_fire1_lp" );
	wait 10.23;
	level.fire_node1end PlaySound( "scn_fire_event_02_fire1" );
	level.fire_node2end PlaySound( "scn_fire_event_02_fire2" );
	level.fire_node3end PlaySound( "scn_fire_event_02_fire1" );
	level.fire_node1 stoploopsound();
	level.fire_node2 stoploopsound();
	level.fire_node3 stoploopsound();
}

boneyard_killstreak_activate()
{
	level endon ( "game_ended" );
	
	while ( 1 )
	{
		// wait for killstreak trigger
		level waittill( "boneyard_killstreak_activate", player );
		
		// disable killstreak before starting
		thread boneyard_killstreak_disable();
		game[ "player_holding_level_killstreak" ] = undefined;
		
		// start killstreak
		flag_set( "boneyard_killstreak_active" );
		level.ks_vertical.player = player;
		level.ks_vertical.team	 = player.pers[ "team" ];
		
		// start warning & fire warmup fx
		wait( 0.5 );
		flag_set( "ks_vertical_alarm_on" );
		thread ks_vertical_warning_alarm();
		thread ks_vertical_warning_lights();
		thread ks_vertical_firing_fx();
		
		// give players a chance to escape
		wait 2;
		flag_clear( "ks_vertical_alarm_on" );
		
		// fire the killstreak
		ks_vertical_fire();
		
		// cleanup
		flag_clear( "boneyard_killstreak_active" );
		
		// check if killstreak count has re-set before re-enabling
		// final cleanup
		if ( level.ks_vertical.uses == 0 )
		{
			flag_clear( "boneyard_killstreak_captured" );
			Objective_PlayerMask_HideFromAll( level.ks_vertical.ui_elem );
			level.ks_vertical.player = undefined;
			level.ks_vertical.team	 = undefined;
			
			// Killstreak was used. Change weighting to be less than initial weighting.
			thread boneyard_killstreak_enable( BONEYARD_KILLSTREAK_MULTIPLE_WEIGHT );
		}
	}
}

boneyard_killstreak_ui_watcher( rocket, loop_time )
{
	level endon( "boneyard_killstreak_captured" );
	
	// turn on objective (init flag to idle)
	flag_clear( "boneyard_killstreak_can_kill" );
	thread boneyard_killstreak_ui_on( rocket );
	
	// update ui state (clear or kill)
	while ( 1 )
	{
		// get possible victims
		victims	= rocket.dam GetIsTouchingEntities( level.characters );
		
		// get state
		my_state = 0;		
		if ( level.teambased )
		{
			foreach ( victim in victims )
			{
				if ( isReallyAlive( victim ) && victim.pers[ "team" ] != rocket.team )
				{
					my_state = 1;
					break;
				}
			}
		}
		else // not team based
		{
			foreach ( victim in victims )
			{
				if ( isReallyAlive( victim ) && ( victim != rocket.player || ( IsDefined( victim.owner ) && victim.owner != rocket.player ) ) )
				{
					my_state = 1;
					break;
				}
			}
		}
		
		// compare and resolve state
		if ( rocket.ui_state != my_state )
		{
			rocket.ui_state = my_state;
			Objective_Icon( rocket.ui_elem, rocket.ui_icon[ my_state ] );
			
			// update flag (for bots)
			if( my_state > 0 )
				flag_set( "boneyard_killstreak_can_kill" );
			else
				flag_clear( "boneyard_killstreak_can_kill" );
		}
		
		wait( loop_time );
	}
}

boneyard_killstreak_ui_on( rocket )
{
	pid = rocket.player GetEntityNumber();
	
	// turn on and blink objective marker
	Objective_PlayerMask_ShowTo( rocket.ui_elem, pid );
	wait( 0.2 );
	Objective_PlayerMask_HideFromAll( level.ks_vertical.ui_elem );
	wait( 0.3 );
	Objective_PlayerMask_ShowTo( rocket.ui_elem, pid );
	wait( 0.2 );
	Objective_PlayerMask_HideFromAll( level.ks_vertical.ui_elem );
	wait( 0.3 );
	Objective_PlayerMask_ShowTo( rocket.ui_elem, pid );
}

//**************************************************************
//		Vertical Rocket Testing
//**************************************************************
ks_vertical_fire()
{
	level endon ( "game_ended" );
	
	// start rocket sfx, badplace) (fx started during warmup)
	flag_set( "ks_vertical_firing" );
	BadPlace_Brush( "bad_vert_fire", 10, level.ks_vertical.dam, "allies", "axis" );
	//level.ks_vertical.sfx PlaySound( "scn_fire_event_02" );
	
	// do damage
	for ( i = 0; i < 20; i++ )
	{
		// wait & check host migration
		wait 0.5;
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		
		// init attacker
		attacker = level.ks_vertical.player;
		if ( !IsDefined( level.ks_vertical.player ) || !IsPlayer( level.ks_vertical.player ) )
		   attacker = undefined;
		
		// damage targets
		thread damage_characters( level.ks_vertical, attacker, 90 );  
		thread damage_targets( level.ks_vertical, attacker	, level.remote_uav, 150 );
		thread damage_targets( level.ks_vertical, attacker	, level.placedIMS , 150 );
		thread damage_targets( level.ks_vertical, attacker	, level.uplinks	  , 150 );
		thread damage_targets( level.ks_vertical, attacker	, level.turrets	  , 150 );
		thread damage_targets( level.ks_vertical, attacker	, level.ballDrones, 150 );
		thread damage_targets( level.ks_vertical, attacker	, level.mines	  , 150 );
		thread damage_targets( level.ks_vertical, attacker	, level.deployable_box["deployable_vest"] , 150 );
		thread damage_targets( level.ks_vertical, attacker	, level.deployable_box["deployable_ammo"] , 150 );
		
		// damage destructibles
		foreach ( org in level.ks_vertical.destructibles )
			RadiusDamage( org, 1, 45, 45, attacker );
	}
	
	// 25 seconds of lingering fire fx (only play if previous lingering fires have gone out)
	if( !IsDefined( level.exploder_queue ) || !IsDefined( level.exploder_queue[ 108 ] ) || ( GetTime() - level.exploder_queue[108].time ) > 25000 )
	{
		maps\mp\mp_boneyard_ns::mp_exploder( 108 );
		thread sound_fire_loops();
	}
	
	//cleanup
	flag_clear( "ks_vertical_firing" );
}

sound_fire_loops()
{
	fire_small_1  = Spawn( "script_origin", (574, 228, -110) );
	fire_small_2  = Spawn( "script_origin", (533, -7, -118) );
	fire_small_3  = Spawn( "script_origin", (264, 221, -101) );
	fire_small_4  = Spawn( "script_origin", (299, 1, -109) );
	fire_small_out_1  = Spawn( "script_origin", (574, 228, -110) );
	fire_small_out_2  = Spawn( "script_origin", (533, -7, -118) );
	fire_small_out_3  = Spawn( "script_origin", (264, 221, -101) );
	fire_small_out_4  = Spawn( "script_origin", (299, 1, -109) );
	fire_small_1 PlayLoopSound( "fire_small_01" );
	fire_small_2 PlayLoopSound( "fire_small_01" );
	fire_small_3 PlayLoopSound( "fire_small_01" );
	fire_small_4 PlayLoopSound( "fire_small_01" );
	wait 24.8;
	fire_small_out_1 playsound( "fire_small_out" );
	fire_small_out_2 playsound( "fire_small_out" );
	fire_small_out_3 playsound( "fire_small_out" );
	fire_small_out_4 playsound( "fire_small_out" );
	wait 0.2;
	fire_small_1 stoploopsound();
	fire_small_2 stoploopsound();
	fire_small_3 stoploopsound();
	fire_small_4 stoploopsound();
	wait 0.1;
	fire_small_1 delete();
	fire_small_2 delete();
	fire_small_3 delete();
	fire_small_4 delete();
}

damage_characters( rocket, attacker, damage )
{
	// get victims
	victims	= rocket.dam GetIsTouchingEntities( level.characters );

	// damage characters
	foreach ( victim in victims )
	{
		if ( can_kill_character( rocket, victim ) )
		{
			if ( IsPlayer( victim ) )
				if ( IsDefined( rocket.player ) && victim == rocket.player )
					victim maps\mp\gametypes\_damage::finishPlayerDamageWrapper( rocket.inflictor, attacker, damage, 0, "MOD_EXPLOSIVE", "none", victim.origin, ( 0, 0, 1 ), "none", 0, 0 );
				else
					// victim maps\mp\gametypes\_damage::Callback_PlayerDamage( attacker, attacker, damage, 0, "MOD_EXPLOSIVE", "none", victim.origin, ( 0, 0, 1 ), "none", 0 );
					victim DoDamage ( damage, rocket.inflictor.origin, attacker, rocket.inflictor, "MOD_EXPLOSIVE" );
			else if( IsDefined( victim.owner ) && victim.owner == rocket.player )
				victim maps\mp\agents\_agents::on_agent_player_damaged( undefined, undefined, damage, 0, "MOD_EXPLOSIVE", "none", victim.origin, ( 0, 0, 1 ), "none", 0 );
			else
				victim maps\mp\agents\_agents::on_agent_player_damaged( rocket.inflictor, attacker, damage, 0, "MOD_EXPLOSIVE", "none", victim.origin, ( 0, 0, 1 ), "none", 0 );
		}
		else if ( IsDefined( victim ) && isReallyAlive( victim ) )
		{
			if ( IsPlayer( victim ) )
				victim maps\mp\gametypes\_damage::Callback_PlayerDamage( undefined, undefined, 1, 0, "MOD_EXPLOSIVE", "none", victim.origin, ( 0, 0, 1 ), "none", 0 );
			else
				victim maps\mp\agents\_agents::on_agent_player_damaged( undefined, undefined, 1, 0, "MOD_EXPLOSIVE", "none", victim.origin, ( 0, 0, 1 ), "none", 0 );
		}
		
		wait( 0.05 );
	}
	
}

can_kill_character( rocket, victim )
{
	// can't kill already dead characters
	if( !IsDefined( victim ) || !isReallyAlive( victim ) )
		return false;
	
	if ( level.teambased )
	{
		// can kill owner
		if ( IsDefined( rocket.player ) && victim == rocket.player )
			return true;
		// can kill characters parented to owner
		else if( IsDefined( rocket.player ) && IsDefined( victim.owner ) && victim.owner == rocket.player )
			return true;
		// can't kill teammates
		else if ( IsDefined( rocket.team ) && victim.team == rocket.team )
			return false;
	}
	
	// can kill everyone in ffa
	return true;
}

damage_targets( rocket, attacker, array_targets, damage )
{
	meansOfDeath  = "MOD_EXPLOSIVE";
	weapon		  = "none";
	direction_vec = ( 0, 0, 0 );
	point		  = ( 0, 0, 0 );
	modelName	  = "";
	tagName		  = "";
	partName	  = "";
	iDFlags		  = undefined;
	
	// get targets
	targets = rocket.dam GetIsTouchingEntities( array_targets );
	
	// damage targets
	foreach ( target in targets )
	{
		// check if target still exitsts
		if( !IsDefined( target ) )
		   continue;
		
		// damage your stuff
		if( IsDefined( target.owner ) && target.owner == attacker )
			target notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
		// skip your teammates' stuff
		else if( level.teamBased && IsDefined( rocket.team ) && IsDefined( target.team ) && target.team == rocket.team )
			continue;
		
		// damage your enemies' stuff
		target notify( "damage", damage, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
		wait( 0.05 );
	}
}

ks_vertical_warning_alarm()
{
	// loop alarm
	//while ( flag( "ks_vertical_alarm_on" ) )
	//{
		level.ks_vertical.sfx PlaySound( "emt_boneyard_ns_close_alarm_01" );
		//level.alarm1_c PlaySound( "emt_boneyard_ns_close_alarm_01" );
		//level.alarm1_d PlaySound( "emt_boneyard_ns_close_alarm_01" );
		thread sound_vertical_fire_logic();
		
		//level.fire_node1 playsound( "scn_fire_event_02_fire1" );
		//level.fire_node2 playsound( "scn_fire_event_02_fire2" );
		//level.fire_node3 playsound( "scn_fire_event_02_fire1" );
		//level.alarm1_b PlaySound( "emt_boneyard_ns_close_alarm_01" );
		//wait 3.36;
	//}
}

sound_vertical_fire_logic()
{
	level.alarm1_c PlaySound( "scn_fire_event_02" );
	wait 1.76;
	level.alarm1_cp1 playsound( "scn_fire_event_02b" );
	thread sound_fire_loop_logic();
	wait 10;
	level.alarm1_cp2 playsound( "scn_fire_event_02c" );	
}

ks_vertical_warning_lights()
{
	level endon ( "game_ended" );
	
	while ( flag( "boneyard_killstreak_active" ) || flag( "boneyard_killstreak_endgame" ) )
	{
		if ( level.teamBased && IsDefined( level.ks_vertical.team ) )
		{
			foreach ( player in level.players )
			{
				if ( player.pers[ "team" ] == level.ks_vertical.team )
					ActivateClientExploder( 19, player );
				else
					ActivateClientExploder( 18, player );
			}
		}
		else
		{
			maps\mp\mp_boneyard_ns::mp_exploder( 18 );
		}
		
		wait( 0.5 );
	}
}

ks_vertical_firing_fx()
{
	//trigger pre firing fx- lasts 2 seconds
	maps\mp\mp_boneyard_ns::mp_exploder( 91 );
	
	wait 2;
	
	//trigger fx toward ends of tunnels
	maps\mp\mp_boneyard_ns::mp_exploder( 90 );
	
	//trigger maing thrust fx loop
	for ( i = 0; i < 5; i++ )
	{
		maps\mp\mp_boneyard_ns::mp_exploder( 92 );
		wait 2;
	}
	
	//trigger post firing fx
	maps\mp\mp_boneyard_ns::mp_exploder( 93 );
}

ks_manage_spawns()
{
	while ( 1 )
	{
		flag_wait ( "boneyard_killstreak_captured" );
		level.dynamicSpawns = ::filter_spawn_points;
		flag_waitopen ( "boneyard_killstreak_captured" );
		level.dynamicSpawns = undefined;
	}
}

filter_spawn_points( spawnPoints )
{
	valid_spawns = [];
	foreach ( spawnPoint in spawnPoints )
	{
		if ( isDefined ( spawnpoint.script_noteworthy ) && spawnpoint.script_noteworthy == "ks_danger_spawn" )
		{
			continue;
		}
		valid_spawns[ valid_spawns.size ] = spawnPoint;
	}
		
	return valid_spawns;
}