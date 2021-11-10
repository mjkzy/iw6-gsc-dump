#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\agents\_agent_utility;

main()
{
	maps\mp\mp_dome_ns_precache::main();
	anim_precache();
	maps\createart\mp_dome_ns_art::main();
	maps\mp\mp_dome_ns_fx::main();
	common_scripts\_pipes::main();
	
	level.mapCustomCrateFunc		  = ::dome_nsCustomCrateFunc;
	level.mapCustomKillstreakFunc	  = ::dome_nsCustomKillstreakFunc;
	level.mapCustomBotKillstreakFunc  = ::dome_nsCustomBotKillstreakFunc;
	level.deployableBoxGiveWeaponFunc = maps\mp\mp_alien_weapon::give_alien_weapon;
	
	maps\mp\_load::main();
	mp_dome_ns_flag_init();

	SetDvar("r_globalGenericMaterialScale",4.0);
	
	// maps\mp\mp_dome_ns_alien::setup_callbacks();
	maps\mp\_compass::setupMiniMap( "compass_map_mp_dome_ns" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	
	//reactive motion settings
	setdvar( "r_reactiveMotionWindAmplitudeScale", 0.4 );
	SetDvar( "r_reactiveMotionPlayerRadius", 20.0 );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	alien_weapon_setup();
	thread auto_door_setup();
	thread crane_platform();
	thread always_open_door();
	maps\mp\mp_alien_weapon::init();
	
	if ( level.ps3 )
	{
		SetDvar( "sm_sunShadowScale", "0.3" ); // ps3 optimization
		SetDvar( "sm_sunsamplesizenear", ".15" );
	}
	else if ( level.xenon )
	{
		SetDvar( "sm_sunShadowScale", "0.55" + "" ); //  optimization
		SetDvar( "sm_sunsamplesizenear", ".25" );
	}
	else
	{
		SetDvar( "sm_sunShadowScale", "1.0" ); // optimization
//		SetDvar( "sm_sunsamplesizenear", ".27" );
	}
		
	setdvar_cg_ng( "r_specularColorScale", 3.0, 7.5 );
	
	level.pipesDamage = false;
	
	thread maps\mp\_dlcalienegg::setupEggForMap( "alienEasterEgg" );
}

mp_dome_ns_flag_init()
{
	flag_init( "crane_usable" );
	flag_init( "misters_on" );
}

set_up_shootable_pipes()
{
	pipes = GetEntArray ( "pipe_shootable", "targetname" );
	foreach ( pipe in pipes )
	{
		pipe.script_noteworthy = "steam";
	}
}

anim_precache()
{
	PrecacheMpAnim ( "mp_dome_ns_crane_cargo_01" );
	PrecacheMpAnim ( "mp_dome_ns_crane_cargo_02" );
	PrecacheMpAnim ( "mp_dome_ns_crane_cargo_start" );
	PrecacheMpAnim ( "mp_dome_ns_crane_01" );
	PrecacheMpAnim ( "mp_dome_ns_crane_02" );
	PrecacheMpAnim ( "mp_dome_ns_crane_start" );
//	PrecacheMpAnim ( "mp_dome_ns_showerdoor_open" );
//	PrecacheMpAnim ( "mp_dome_ns_showerdoor_close" );
	PrecacheMpAnim ( "mp_dome_ns_showerdoor_open_l" );
	PrecacheMpAnim ( "mp_dome_ns_showerdoor_close_l" );
	PrecacheMpAnim ( "mp_dome_ns_showerdoor_open_r" );
	PrecacheMpAnim ( "mp_dome_ns_showerdoor_close_r" );
	PreCacheModel ( "mp_dns_crane_debris" );
}

alien_weapon_setup()
{
	// platform_origin = GetEnt( "platform_origin", "targetname" );
	trigger = GetEnt ( "alien_weapon_trigger", "targetname" );
	
//	trigger EnableLinkTo();
//	trigger LinkTo( platform_origin );
	
	thread alien_weapon_trigger_watcher ( trigger );

}

alien_weapon_trigger_watcher( trigger )
{
	trigger MakeUnusable();
	flag_wait ( "crane_usable" );
	platform_origin = GetEnt( "platform_origin", "targetname" );
	trigger MakeUsable();
	trigger EnableLinkTo();
	trigger LinkTo( platform_origin );
	trigger SetHintString ( &"MP_DOME_NS_GET_ALIEN_GUN" );
	
	while ( 1 )
	{
		if ( level.remaining_alien_weapons == 0 )
			break;
		trigger waittill ( "trigger", triggerer );
		
		triggerer maps\mp\mp_alien_weapon::give_alien_weapon();
	}
	
	alien_gun_model = GetEnt ( "alien_gun_model", "targetname" );
	alien_gun_model hide();
	
	trigger MakeUnusable();
	trigger SetHintString ( "" );
}

#using_animtree ( "animated_props_dlc2" );
crane_platform()
{	
	thread crane_available_check();
	
	test_bed = GetEnt ( "het_bed_proxy", "targetname" );
	test_bed delete();
	
	cooldown_time = 2;
	level.platform_lights = [];
	
	// Get all the Ents needed to make the basket happen
	platform_origin = GetEnt( "platform_origin", "targetname" );
	platform_model = GetEnt( "moving_platform_model", "targetname" );
	alien_gun_model = GetEnt ( "alien_gun_model", "targetname" );
	platform_sfx_origin = GetEnt( "platform_sfx_origin", "targetname" );
	platform_death_trigger = GetEnt ( "platform_death_trigger", "targetname" );
	crane = GetEnt ( "dome_crane", "targetname" );
	platforms = GetEntArray ( "moving_platform", "targetname" );
	// Because I can't just use a noteworthy on the models, it has to be manually added to the array
	platforms[platforms.size] = platform_model;
	platforms[platforms.size] = alien_gun_model;
	
	// Side blocker disconnects the paths that are blocked by the sides of the container when it's down
	side_blockerB = GetEnt ( "side_blockerB", "targetname" );
	
	// Attach collision for animated crane
	arm_base_jnt_collision = GetEnt( "arm_base_jnt_collision", "targetname" );
	arm_mid_jnt_collision = GetEnt( "arm_mid_jnt_collision", "targetname" );
	arm_end_jnt_collision = GetEnt( "arm_end_jnt_collision", "targetname" );
	operators_cab_jnt_collision = GetEnt( "operators_cab_jnt_collision", "targetname" );
	hook_jnt_collision = GetEnt( "hook_jnt_collision", "targetname" );
	
	arm_base_jnt_collision LinkTo( crane, "arm_base_jnt" );
	arm_mid_jnt_collision LinkTo( crane, "arm_mid_jnt" );
	arm_end_jnt_collision LinkTo( crane, "arm_end_jnt" );
	operators_cab_jnt_collision LinkTo( crane, "operators_cab_jnt" );
	hook_jnt_collision LinkTo( crane, "hook_jnt" );
	
	arm_base_jnt_collision.destroyAirdropOnCollision = true;
	arm_mid_jnt_collision.destroyAirdropOnCollision = true;
	arm_end_jnt_collision.destroyAirdropOnCollision = true;
	operators_cab_jnt_collision.destroyAirdropOnCollision = true;
	hook_jnt_collision.destroyAirdropOnCollision = true;
	
	arm_base_jnt_collision.no_moving_platfrom_death = true;
	arm_mid_jnt_collision.no_moving_platfrom_death = true;
	arm_end_jnt_collision.no_moving_platfrom_death = true;
	operators_cab_jnt_collision.no_moving_platfrom_death = true;
	hook_jnt_collision.no_moving_platfrom_death = true;
	
	// Set up and attach triggers
	gate_watchers = GetEntArray ( "gate_watcher", "targetname" );
	crane_occupied_watcher = GetEnt ( "crane_occupied_watcher", "targetname" );
	foreach ( gate_watcher in gate_watchers )
	{
		gate_watcher EnableLinkTo();
		gate_watcher LinkTo ( platform_origin );
	}

	platform_death_trigger EnableLinkTo();
	platform_death_trigger LinkTo ( platform_origin );
	
	crane_occupied_watcher EnableLinkTo();
	crane_occupied_watcher LinkTo ( platform_origin );
	thread disable_drones_watcher( crane_occupied_watcher );
	
	waitframe();
	
	// Initial positions for platform and crane
	platform_origin ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_cargo_start" );
	crane ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_start" );

	
	wait 1;

	foreach( platform in platforms )
	{				
		platform LinkTo( platform_origin, "tag_origin" );
		platform.destroyAirdropOnCollision = true;
	}
	platform_sfx_origin LinkTo( platform_origin, "tag_origin" );
	
	side_blockerB Solid();
	side_blockerB ConnectPaths();
	side_blockerB NotSolid();//iw6-depot/iw6-dlc/game/xanim_export/mp_dome_ns/mp_dome_ns_crane_cargo_02.XANIM_EXPORT

	crane_gate_blocker = GetEnt( "crane_gate_blocker", "targetname" );
	crane_gate_blocker LinkTo( platform_origin );
	crane_gate_blocker.no_moving_platfrom_death = true;
	
	crane_audio_org = GetEnt( "crane_audio_org", "targetname" );
	
	trip = 1;  // trip 1 is going from start to new location, trip -1 is going from new back to start location

	flag_wait ( "crane_usable" );
	
	// Set up the mini-map icon for the crane
	Objective_Add( 31, "active", platform_model.origin,"waypoint_man_basket" );
	Objective_OnEntityWithRotation( 31, platform_model );
	
	crane_gate_blocker Unlink();
	crane_gate_blocker NotSolid();
	//crane_gate_blocker MoveTo ( crane_gate_blocker.origin + (0,0,256), 0.05 );
	wait 0.1;
	crane_gate_blocker LinkTo( platform_origin );
	
	triggerA = GetEnt ( "platform_toggle_triggerA", "targetname" );
	triggerA SetHintString ( &"MP_DOME_NS_ACTIVATE_CRANE" );
	triggerA MakeUsable();
	triggerB = GetEnt ( "platform_toggle_triggerB", "targetname" );
	triggerB SetHintString ( &"MP_DOME_NS_ACTIVATE_CRANE" );
	triggerB MakeUnusable();
	
	thread gate_watcher( gate_watchers, triggerA );
	thread gate_watcher( gate_watchers, triggerB );
	
	while ( 1 )
	{
		// Wait for the player to push the button
		level waittill ( "crane_triggered" );
		
		thread fx_crane_light( platform_sfx_origin );
					
		crane_gate_move( crane_gate_blocker, platform_origin, "down" );
		
//		platform_origin ScriptModelClearAnim();
//		crane ScriptModelClearAnim();
			
		// Going from HET to excavator
		if (trip == 1)
		{
			triggerA PlaySound("scn_crane_button_activate");
			triggerA MakeUnusable();
				
			platform_origin ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_cargo_01" );
			platform_model ScriptModelPlayAnim ( "mp_dome_ns_crane_cargo_01_gate" );
			crane ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_01" );
			
			// Bit of a hack since notetrack utility functions do not seem to work in MP
			anim_length = GetAnimLength( %mp_dome_ns_crane_cargo_01_gate );
			percent = GetNotetrackTimes ( %mp_dome_ns_crane_cargo_01_gate, "gate_open" );
			time = anim_length * percent[0];
			
		}
		// Going from excavator to HET
		else
		{
			triggerB PlaySound("scn_crane_button_activate");
			triggerB MakeUnusable();
			
			platform_origin ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_cargo_02" );
			platform_model ScriptModelPlayAnim ( "mp_dome_ns_crane_cargo_02_gate" );
			crane ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_02" );
			
			// Bit of a hack since notetrack utility functions do not seem to work in MP
			percent = GetNotetrackTimes ( %mp_dome_ns_crane_cargo_02_gate, "gate_open" );
			anim_length = GetAnimLength( %mp_dome_ns_crane_cargo_02_gate );
			time = anim_length * percent[0];
			
			// Connect the side paths.
			side_blockerB Solid();
			side_blockerB ConnectPaths();
			side_blockerB NotSolid();
		}

		/* Sfx for bar lowering */
		thread sfx_crane_bar(trip, 0, "down");
		
		crane_audio_org thread sfx_crane_start();
		platform_sfx_origin thread sfx_crane_platform_start();
		// Activate unresolved collision handling
		foreach ( platform in platforms )
		{
			platform.unresolved_collision_func = ::crane_damage_manager;
			platform.unresolved_collision_notify_min = 1;
			platform.unresolved_collision_kill = true;
			platform.owner = level.triggerer;
		}
		
		/* Sfx for bar raising */
		thread sfx_crane_bar(trip, time, "up");
		
		// Wait until the notetrack
		wait time;
		
		// Rotate gate up
		crane_gate_move( crane_gate_blocker, platform_origin, "up" );
			
		// turn on the backup death trigger
		platform_death_trigger thread death_trigger_manager();
		
		// Landing at excavator	
		if (trip == 1)
		{
			// Manage the nodes around the landing area
			side_blockerB Solid();
			side_blockerB DisConnectPaths();
			side_blockerB NotSolid();
			
			sfx_time = anim_length - time;
			crane_audio_org thread sfx_crane_stop(sfx_time, 2);
			platform_sfx_origin thread sfx_crane_stop_impt(sfx_time, 0.2);
		}
		// Landing at HET
		else
		{
			sfx_time = anim_length - time;
			crane_audio_org thread sfx_crane_stop(sfx_time, 1.8);			
			platform_sfx_origin thread sfx_crane_stop_impt(sfx_time, 0.4);
			
		}
		
		// Wait the remainder of the anim
		wait (anim_length - time);

		wait cooldown_time;
		
		if (trip == 1)
		{
			triggerB SetHintString ( &"MP_DOME_NS_ACTIVATE_CRANE" );
			triggerB MakeUsable();
		}
		else
		{
			triggerA SetHintString ( &"MP_DOME_NS_ACTIVATE_CRANE" );
			triggerA MakeUsable();
		}
		
		// flip the trip variable
		trip = trip*(0-1);
		level notify ( "platform_move_done" );
	}
}

// This function serves as an emergency backup for when the unresolved collision handler fails.
death_trigger_manager()	
{
	level endon ( "platform_move_done" );
	while ( 1 )
	{
		// Reset array
		agents_in_trigger = [];
		// Get all the Players/Dogs/Squadmates/Juggernauts/Aliens
		agents = maps\mp\agents\_agent_utility::getActiveAgentsOfType( "all" );
		agents = array_combine ( agents, level.players );
		// agents = array_combine ( agents, level.remote_uav );
		
		// Remove spectators
		foreach ( agent in agents )
		{
			if( isPlayer(agent) && (agent.sessionstate == "intermission" || agent.sessionstate == "spectator" || !isReallyAlive ( agent )) )
				agents = array_remove ( agents, agent );
		}
		// waitframe();
		// How many agents are in the trigger?
		agents_in_trigger = self GetIsTouchingEntities(  agents );
		
		foreach ( agent in agents_in_trigger )
		{
			self crane_damage_manager( agent );
		}
		
		wait .1;
	}
}

disable_drones_watcher( trigger )
{
	while ( 1 )
	{
		// Wait until the game has started before checking against players
		if ( IsDefined ( level.players ))	
		{
		    break;
		}
		wait 1;
	}
	
	while ( 1 )
	{
		touchers = trigger GetIsTouchingEntities ( level.players );
		foreach ( toucher in touchers )
		{
			if ( isdefined ( toucher.drones_disabled ))
			    continue;
			toucher.drones_disabled = true;
			toucher.seekers_disabled = true;
			toucher thread enable_drones_watcher( trigger );
		}
		wait 0.05;
	}
}

enable_drones_watcher( trigger )
{
	if ( !isPlayer ( self ) )
		self endon ( "death" );
	self endon ( "disconnect" );
	while ( self isTouching( trigger ) )
		wait( 0.05 );
	self.drones_disabled = undefined;
	self.seekers_disabled = undefined;
}

gate_watcher( gate_triggers, crane_trigger )
{
	while ( 1 )
	{
		crane_trigger waittill ( "trigger", triggerer );
		
		players_in_trigger = [];
		players_in_this_trigger = [];
		
		players = level.players;
			
		// Remove spectators
		foreach ( player in players )
		{
			if( player.sessionstate == "intermission" || player.sessionstate == "spectator" || !isReallyAlive ( player ) )
				player = array_remove ( players, player );
		}
		
		// How many agents are in the triggers?
		foreach ( trigger in gate_triggers )
		{
			players_in_this_trigger = trigger GetIsTouchingEntities( players );
			players_in_trigger = array_combine ( players_in_trigger, players_in_this_trigger );
		}
		
		if ( players_in_trigger.size > 0 )
		{
			triggerer PlaySoundToPlayer ( "alien_miasma_alarm", triggerer );
		}
		else
		{
			level notify ( "crane_triggered" );
			level.triggerer = triggerer;
		}
	}
}

crane_gate_move( crane_gate_blocker, platform_origin, direction  )
{
		if ( direction == "up" )
		{	
			level notify ( "basket_descending" );
			crane_gate_blocker NotSolid();
		}
		else
		{
			crane_gate_blocker Solid();
		}
}

crane_available_check()
{
	platform_model= GetEnt( "moving_platform_model", "targetname" );
	platform_origin = GetEnt( "platform_origin", "targetname" );
	crane = GetEnt ( "dome_crane", "targetname" );
	
	level.crane_targets = 3;
	thread crane_target_setup( "crane_target_1", "arm_base_jnt", 5 );
	thread crane_target_setup( "crane_target_2", "arm_mid_jnt", 6 );
	thread crane_target_setup( "crane_target_3", "arm_end_jnt", 7 );
	
	while ( level.crane_targets == 3 )
	{
		if ( getdvarint( "scr_activateCrane" ) == 1 )
			break;
		wait 0.05;
	}
	platform_model playsound("scn_dome_crane_platform_01");
//	platform_origin ScriptModelClearAnim();
//	crane ScriptModelClearAnim();
	platform_origin ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_cargo_drop1" );
	platform_model ScriptModelPlayAnim ( "mp_dome_ns_crane_cargo_drop1_gate" );
	crane ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_drop1" );
			
	anim_length = GetAnimLength( %mp_dome_ns_crane_drop1 );
	wait anim_length;
	
	while ( level.crane_targets == 2 )
	{
		if ( getdvarint( "scr_activateCrane" ) == 1 )
			break;
		wait 0.05;
	}
	
	platform_model playsound("scn_dome_crane_platform_02");
//	platform_origin ScriptModelClearAnim();
//	crane ScriptModelClearAnim();
	platform_origin ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_cargo_drop2" );
	platform_model ScriptModelPlayAnim ( "mp_dome_ns_crane_cargo_drop2_gate" );
	crane ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_drop2" );
			
	anim_length = GetAnimLength( %mp_dome_ns_crane_drop2 );
	wait anim_length;
	
	while ( level.crane_targets == 1 )
	{
		if ( getdvarint( "scr_activateCrane" ) == 1 )
			break;
		wait 0.05;
	}
	
	platform_model playsound("scn_dome_crane_platform_03");
//	platform_origin ScriptModelClearAnim();
//	crane ScriptModelClearAnim();
	platform_origin ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_cargo_drop3" );
	platform_model ScriptModelPlayAnim( "mp_dome_ns_crane_cargo_drop3_gate" );
	crane ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_drop3" );
	platform_debris = spawn ( "script_model", crane.origin );
	platform_debris.angles = crane.angles;
	platform_debris SetModel ( "mp_dns_crane_debris" );
	platform_debris ScriptModelPlayAnimDeltaMotion( "mp_dome_ns_crane_drop3_debris" );
			
	anim_length = GetAnimLength( %mp_dome_ns_crane_drop3 );
	
	wait anim_length - .8;
	//play the crate impact fx
	exploder(4);
	wait .2;
	
	blockers = GetEntArray ( "crane_platform_blocker", "targetname" );
	nodes = GetNodeArray ( "traverse_platform", "targetname" );
	foreach ( node in nodes )
	{
		ConnectNodePair( node, GetNode( node.target, "targetname" ) );
	}
	
	// Disallow the nodes on the HET 
	bad_nodes = GetNodeArray ( "no_agent_spawn_node", "script_noteworthy" );
	bad_nodes array_combine ( bad_nodes, nodes );
	foreach ( node in bad_nodes )
	{
		node.no_agent_spawn = true;	
	}
	
	foreach ( blocker in blockers )
	{
		if ( blocker.classname == "script_brushmodel" )
			blocker ConnectPaths();
		blocker delete();
	}
	
	wait 1;
	
	flag_set ( "crane_usable" );
	
	platform_model man_cage_button_fx();
}

man_cage_button_fx()
{
	flag_wait("crane_usable");
	while(1)
	{		
		StopFXOnTag(level._effect[ "vfx_red_light" ], self, "tag_fx_red");
		PlayFXOnTag(level._effect[ "vfx_green_light" ], self, "tag_fx_green");
				
		// Wait for the player to push the button
		level waittill ( "crane_triggered" );
		
		PlayFXOnTag(level._effect[ "vfx_red_light" ], self, "tag_fx_red");
		StopFXOnTag(level._effect[ "vfx_green_light" ], self, "tag_fx_green");
		
		//stay red until done moving, then loop back to green
		level waittill ( "platform_move_done" );
	}		
}

crane_target_setup( targetname, joint, exploderID )
{
	crane_target = GetEnt ( targetname, "targetname" );
	crane = GetEnt ( "dome_crane", "targetname" );
	
	crane_target LinkTo( crane, joint );
	
	// disallow destruction of the locks if gametype has weapon restrictions
	if ( level.gameType == "oic" || level.gameType == "gun" || level.gameType == "infect" || level.gameType == "horde" || level.gameType == "sotf" || level.gameType == "sotf_ffa"|| isMLGMatch()  )
	{
		crane_target delete();
		return;	
	}
	
	crane_target SetCanDamage( true );
	crane_target.health = 100000;
	
	while ( 1 )
	{
		crane_target waittill ( "damage", damage, attacker, direction_vec, P, type );
		if ( damage >= 75  && ( type == "MOD_EXPLOSIVE" || type == "MOD_PROJECTILE_SPLASH" || type == "MOD_PROJECTILE" || type ==  "MOD_GRENADE_SPLASH" || type ==  "MOD_GRENADE" || type ==  "SPLASH" ))
		{
			crane_target playsound("scn_dome_crane_explo_01");
			crane_target delete();
			level.crane_targets --;
			exploder(exploderID);
			break;
		}
	}
}

crane_damage_manager( hitEnt )
{
	if ( isdefined ( level.triggerer) )
	{
		// Same Team
		if ( IsDefined (hitEnt.team) && hitEnt.team == level.triggerer.team )
			hitEnt DoDamage( 1000, hitEnt.origin, self, self, "MOD_CRUSH" );
		else			
			hitEnt DoDamage( 1000, hitEnt.origin, level.triggerer, self, "MOD_CRUSH" );
		// self RadiusDamage( hitEnt.origin, 1, 10000, 9999, level.triggerer, "MOD_CRUSH" );
	}
	else
	{
		hitEnt DoDamage( 1000, hitEnt.origin, undefined, undefined, "MOD_CRUSH" );
		// self RadiusDamage( hitEnt.origin, 1, 10000, 9999, undefined, "MOD_CRUSH" );
	}
}

clean_tube_watcher( )
{
	trigger = GetEnt ( "trigger_clean_tube_spray", "targetname" );
	while ( 1 )
	{
		// Reset array
		agents_in_trigger = [];
		// Get all the Players/Dogs/Squadmates/Juggernauts/Aliens
		agents = maps\mp\agents\_agent_utility::getActiveAgentsOfType( "all" );
		agents = array_combine ( agents, level.players );
		agents = array_combine ( agents, level.remote_uav );
		
		// Remove spectators
		foreach ( agent in agents )
		{
			if( isPlayer(agent) && (agent.sessionstate == "intermission" || agent.sessionstate == "spectator" || !isReallyAlive ( agent )) )
				agents = array_remove ( agents, agent );
		}
		waitframe();
		// How many agents are in the trigger?
		agents_in_trigger = trigger GetIsTouchingEntities(  agents );
		
		// Prevent spawning flying drones in the tube.
		foreach ( agent in agents_in_trigger )
		{
			if (IsPlayer(agent))
				agent.drones_disabled = true;
				agent thread enable_drones_watcher( trigger );
		}
		
		// Someone (or something) is in the tube.
		if ( agents_in_trigger.size > 0 )
		{
			ActivateClientExploder ( 70 );
			thread sfx_misters_on();
		}
		else
			thread sfx_misters_off();

		wait .75;
	}
}

door_trigger_watcher( trigger )
{
	while ( 1 )
	{
		// Get all the Players/Dogs/Squadmates/Juggernauts/Aliens
		agents = maps\mp\agents\_agent_utility::getActiveAgentsOfType( "all" );
		agents = array_combine ( agents, level.players );
		agents = array_combine ( agents, level.remote_uav );
		
		// Remove spectators
		foreach ( agent in agents )
		{
			if( isPlayer(agent) && (agent.sessionstate == "intermission" || agent.sessionstate == "spectator" || !isReallyAlive ( agent )) )
				agents = array_remove ( agents, agent );
		}
		waitframe();
		// How many agents are in the trigger?
		agents_in_trigger = trigger GetIsTouchingEntities(  agents );
		
		// If it's none, the door should close.
		if ( agents_in_trigger.size == 0 )
		{
			trigger notify ( "unoccupied" );
		}
		// Otherwise, it should open
		else
		{
			trigger notify ( "occupied" );
		}

		wait .25;
	}
}

// Auto Door scripts
// An auto door trigger should have the targetname of "trigger_automatic_door".
// Give the trigger a script_parameters value of "target=X;" where "X" is the targetname of all the door parts. X should be unique per door.

always_open_door()
{
	door_model_r = GetEnt ( "door_open_right", "targetname" );
	door_model_l = GetEnt ( "door_open_left", "targetname" );
	door_model_r ScriptModelPlayAnimDeltaMotion ( "mp_dome_ns_showerdoor_open_l" );
	door_model_l ScriptModelPlayAnimDeltaMotion ( "mp_dome_ns_showerdoor_open_r" );
}

auto_door_setup()
{
	while ( 1 )
	{
		// Wait until the game has started before checking against players
		if ( IsDefined ( level.players ))	
		{
		    break;
		}
		wait 1;
	}
	
	// Piggybacking off of the players existing check above to launch the clean tube stuff.
	thread clean_tube_watcher();
	
	triggers = GetEntArray( "trigger_automatic_door", "targetname" );
	foreach ( trigger in triggers )
	{
		thread door_trigger_watcher( trigger );	
		thread auto_door_manager( trigger );
	}
}

auto_door_manager( trigger )
{
	// Delay after opening fully until it checks to close
	close_delay = 2;

	door_entities = GetEntArray ( trigger.target, "targetname" );
	
	// For some reason, I have to define these variables before I can assign an entity to them, or else it doesn't work.
	left_door = 1;
	right_door = 1;
	closed_left = 1;
	closed_right = 1;
	open_left = 1;
	open_right = 1;
	door_animated_right = 1;
	door_animated_left = 1;
	
	foreach( piece in door_entities )
	{
		parameters = piece.script_parameters;
		
		if ( piece.script_parameters == "door_left;")
		    thing = piece;
	
		if ( !IsDefined( parameters ) )
			parameters = "";
		
		params = StrTok( parameters, ";" );
		foreach ( param in params )
		{
			
			if ( params[0] == "door_left" )
				left_door = piece;
			if ( params[0] == "door_right" )
				right_door = piece;
			if ( params[0] == "closed_left" )
				closed_left = piece;
			if ( params[0] == "closed_right" )
				closed_right = piece;
			if ( params[0] == "open_left" )
				open_left = piece;
			if ( params[0] == "open_right" )
				open_right = piece;
			if ( params[0] == "door_animated_right" )
				door_animated_right = piece;
			if ( params[0] == "door_animated_left" )
				door_animated_left = piece;
		}
	}
	
	// The door should never be blocked for AI, so they know they can go through it.
	waitframe();
	left_door ConnectPaths();
	right_door ConnectPaths();
	
	closed = closed_right.origin;
	
	left_door LinkTo( closed_left );
	right_door LinkTo( closed_right );

	while ( 1 )
	{
		// If the trigger state is defined, the door is open
		trigger waittill ( "occupied" );
		// if ( isdefined ( trigger.state ) )
	    {
			left_door maps\mp\_movers::notify_moving_platform_invalid();
			right_door maps\mp\_movers::notify_moving_platform_invalid();
			closed_left MoveTo( open_left.origin, .5 );
			closed_right MoveTo( open_right.origin, .5 );
			door_animated_left ScriptModelPlayAnimDeltaMotion ( "mp_dome_ns_showerdoor_open_r" );
			door_animated_right ScriptModelPlayAnimDeltaMotion ( "mp_dome_ns_showerdoor_open_l" );
			door_animated_left PlaySound("scn_dome_ns_glass_door_open");
			door_animated_right PlaySound("scn_dome_ns_glass_door_open");
			wait .5;
			wait close_delay;
	    }
		
		trigger waittill ( "unoccupied" );
		
		// else
		{	
			closed_left MoveTo( closed, .5 );
			closed_right MoveTo( closed, .5 );
			door_animated_left ScriptModelPlayAnimDeltaMotion ( "mp_dome_ns_showerdoor_close_r" );
			door_animated_right ScriptModelPlayAnimDeltaMotion ( "mp_dome_ns_showerdoor_close_l" );
			door_animated_left PlaySound("scn_dome_ns_glass_door_close");
			door_animated_right PlaySound("scn_dome_ns_glass_door_close");
			wait .5;
		}
		wait .1;
	}
}

fx_crane_light( platform_sfx_origin )
{

	PlayFXOnTag ( level._effect[ "vfx_dome_ns_man_cage_flare" ], platform_sfx_origin, "tag_origin" );

	level waittill ( "platform_move_done" );

	StopFXOnTag ( level._effect[ "vfx_dome_ns_man_cage_flare" ], platform_sfx_origin, "tag_origin" );
}

// Custom Killstreak functions
DOME_NS_ALIEN_DOG_WEIGHT = 200;

dome_nsCustomCrateFunc()
{
	if(!IsDefined(game["player_holding_level_killstreak"]))
		game["player_holding_level_killstreak"] = false;
		
	if(!allowLevelKillstreaks() || game["player_holding_level_killstreak"])
		return;
	
    // SEEKER ADDITION
    maps\mp\killstreaks\_airdrop::addCrateType( "airdrop_assault", "dome_seekers", DOME_NS_ALIEN_DOG_WEIGHT, maps\mp\killstreaks\_airdrop::killstreakCrateThink,    maps\mp\killstreaks\_airdrop::get_friendly_crate_model(), maps\mp\killstreaks\_airdrop::get_enemy_crate_model(), &"MP_DOME_NS_SEEKERS_PICKUP" );
    
	// level thread watch_for_dome_ns_meteor_crate();
	level thread watch_for_dome_ns_alien_dog_crate();
}

watch_for_dome_ns_alien_dog_crate()
{
	while(1)
	{
		level waittill("createAirDropCrate", dropCrate);

		if(IsDefined(dropCrate) && IsDefined(dropCrate.crateType) && dropCrate.crateType=="dome_seekers")
		{	
			maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", "dome_seekers", 0);
			captured = wait_for_capture(dropCrate);
			
			if(!captured)
			{
				//reEnable seeker care package if it expires with out anyone picking it up
				maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", "dome_seekers", DOME_NS_ALIEN_DOG_WEIGHT);
			}
			else
			{
				//Once it's picked up it needs to remain off.
				game["player_holding_level_killstreak"] = true;
				// break;
			}
		}
	}
}

//death and capture are sent on the same frame but death is processed first :(
wait_for_capture(dropCrate)
{
	result = watch_for_air_drop_death(dropCrate);
	return !IsDefined(result); //If !isdefined the captured notify was also sent.
}

watch_for_air_drop_death(dropCrate)
{
	dropCrate endon("captured");
	
	dropCrate waittill("death");
	waittillframeend;
	
	return true;
}

dome_nsCustomKillstreakFunc()
{
	// Create the debug menu entries for the player
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:7/Care Package/Seekers\" \"set scr_devgivecarepackage dome_seekers; set scr_devgivecarepackagetype airdrop_assault\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:7/Seekers\" \"set scr_givekillstreak dome_seekers\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:7/Seeker Debug Mode\" \"set scr_alienDebugMode 1\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:7/Activate Crane\" \"set scr_activateCrane 1\"\n");
	
	level.killstreakWeildWeapons["killstreak_level_event_mp"] 				= "dome_seekers";				// level killstreak for mp_dome_ns
	
	level.killStreakFuncs[ "dome_seekers" ] = ::tryUseAlien;
}

tryUseAlien( lifeId, streakName )
{
	// In debug mode, only one alien is spawned
	if ( getdvarint( "scr_alienDebugMode" ) == 1 )
	{
		number_of_aliens = 1;	
	}
	else{
		number_of_aliens = 3;	
	}
	 
	// limit the number of active "squadmate" agents allowed per game
	// Based on CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME, which is currently 5.
	if( getNumActiveAgents( ) + number_of_aliens >= 5 )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	// try to spawn the agent on a path node near the player
	nearestPathNode = self getValidSpawnPathNodeNearPlayer( true );
	if( !IsDefined(nearestPathNode) || IsDefined ( self.seekers_disabled ) )
	{
		self iPrintLnBold( &"MP_DOME_NS_SEEKERS_UNAVAILABLE" );
		return false;
	}

	thread maps\mp\mp_dome_ns_alien::useAlien( nearestPathNode, number_of_aliens );
	return true;
}

dome_nsCustomBotKillstreakFunc()
{
	AddDebugCommand("devgui_cmd  \"MP/Bots(Killstreak)/Level Events:5/Seekers\" \"set scr_testclients_givekillstreak dome_seekers\"\n");
	maps\mp\bots\_bots_ks::bot_register_killstreak_func( "dome_seekers",	maps\mp\bots\_bots_ks::bot_killstreak_simple_use );
}

/* Audio scripting */
sfx_misters_on()
{
	if (flag("misters_on"))
		return;
	
	flag_set("misters_on");
	
	if (!IsDefined( level.mister_01 ))
		level.mister_01 = Spawn( "script_origin", (1735, 1546, -133) );
	if (!IsDefined( level.mister_02 ))
		level.mister_02 = Spawn( "script_origin", (1745, 1707, -140) );
	if (!IsDefined( level.mister_03 ))
		level.mister_03 = Spawn( "script_origin", (1753, 1835, -140) );
	if (!IsDefined( level.mister_04 ))
		level.mister_04 = Spawn( "script_origin", (1698, 1952, -140) );
	if (!IsDefined( level.mister_05 ))
		level.mister_05 = Spawn( "script_origin", (1540, 1981, -133) );
	
	level.mister_01 PlayLoopSound("emt_dome_ns_mist_01");
	level.mister_02 PlayLoopSound("emt_dome_ns_mist_02");
	level.mister_03 PlayLoopSound("emt_dome_ns_mist_03");
	level.mister_04 PlayLoopSound("emt_dome_ns_mist_01");
	level.mister_05 PlayLoopSound("emt_dome_ns_mist_02");
}

sfx_misters_off()
{
	if (!flag("misters_on"))
		return;
	
	flag_clear("misters_on");
	
	level.mister_01 StopLoopSound();
	level.mister_02 StopLoopSound();
	level.mister_03 StopLoopSound();
	level.mister_04 StopLoopSound();
	level.mister_05 StopLoopSound();
}

sfx_crane_start()
{
	wait 0.3;
	self PlaySound("scn_crane_start");
	wait 2.4;
	self PlayLoopSound("scn_crane_mvmt_lp");
}

sfx_crane_platform_start()
{
	self PlaySound("scn_crane_platform_start");

	self thread sfx_crane_rattle();
}

sfx_crane_stop(time, mod)
{
	wait time - mod;
	//IPrintLnBold("Stopping");
	self PlaySound("scn_crane_stop");
	wait 0.3;
	self StopLoopSound("scn_crane_mvmt_lp");
}

sfx_crane_stop_impt(time, mod)
{
	//IPrintLnBold("7 - stopping");
	//self PlaySound("scn_crane_rattle");
	
	wait time - mod;
	//IPrintLnBold("Impt");
	self PlaySound("scn_crane_stop_impt");
}

sfx_crane_rattle()
{
	wait 3;
	//IPrintLnBold("1");
	//self PlaySound("scn_crane_rattle");

	wait RandomIntRange(3, 4);
	//IPrintLnBold("2");
	self PlaySound("scn_crane_rattle");
	
	wait RandomIntRange(9, 12);
	//IPrintLnBold("3");
	self PlaySound("scn_crane_rattle");
	
	wait RandomIntRange(9, 11);
	//IPrintLnBold("4");
	self PlaySound("scn_crane_rattle");
	
	wait 7.5;
	//IPrintLnBold("5");
	self PlaySound("scn_crane_rattle");
	
	//wait RandomIntRange(6, 8);
	//IPrintLnBold("6");
	//self PlaySound("scn_crane_rattle");
}

sfx_crane_bar( trip, sfx_time, direction  )
{
	if ( direction == "up" )
	{	
		wait sfx_time - 0.8;
		if (trip == 1)
		{
			//IPrintLnBold("Trip 1: Up");
			coord_01 = (-296, 1403, -200);
			coord_02 = (-362, 1285, -200);
		}
		else
		{
			//IPrintLnBold("Trip 2: Up");
			coord_01 = (970, 292, -245);
			coord_02 = (1086, 253, -245);
		}
			
		soundalias = "scn_crane_bar_up";
		soundalias2 = "scn_crane_bar_down";
	}
	else
	{
		wait 0.12;
		if (trip == 1)
		{
			//IPrintLnBold("Trip 1: Down");
			coord_01 = (970, 292, -250);
			coord_02 = (1090, 266, -250);
		}
		else
		{
			//IPrintLnBold("Trip 2: Down");
			coord_01 = (-281, 1391, -200);
			coord_02 = (-345, 1283, -200);
		}	
		
		soundalias = "scn_crane_bar_down";
		soundalias2 = "scn_crane_bar_up";
	}
	
	if (!IsDefined( level.sfx_crane_bar_01 ))
		level.sfx_crane_bar_01 = Spawn( "script_origin", coord_01 );
	if (!IsDefined( level.sfx_crane_bar_02 ))
		level.sfx_crane_bar_02 = Spawn( "script_origin", coord_02 );
	
	// Face towards truck
	level.sfx_crane_bar_01 PlaySound(soundalias);
	// Face away from truck
	level.sfx_crane_bar_02 PlaySound(soundalias2);
	wait 2;
	level.sfx_crane_bar_01 delete();
	level.sfx_crane_bar_02 delete();
}
