#include common_scripts\utility;
//#include common_scripts\shared;
#include maps\mp\_utility;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\bots\_bots_ks;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;
#include maps\mp\bots\_bots_personality;
#include maps\mp\bots\_bots_fireteam;

//========================================================
//					main 
//========================================================
main()
{
	if ( is_aliens() )
		return;
	
	if( IsDefined( level.createFX_enabled ) && level.createFX_enabled )
		return;

	if ( level.script == "mp_character_room" )
		return;

	// This is called directly from native code on game startup
	// The particular gametype's main() is called from native code afterward
		
	setup_callbacks();
	setup_personalities();

	// Enable badplaces in destructibles
	level.badplace_cylinder_func = ::badplace_cylinder;
	level.badplace_delete_func = ::badplace_delete;
	
	// Init bot killstreak script
	maps\mp\bots\_bots_ks::bot_killstreak_setup();

	// Init bot loadout data
	// Needs to be after _bots_ks::bot_killstreak_setup
	maps\mp\bots\_bots_loadout::init();
	
	// Needs to be after _bots_loadout::init()
	level thread init();
/*
/#
	maps\mp\bots\_bots_gametype_dom::empty_function_to_force_script_dev_compile();
	maps\mp\bots\_bots_gametype_sr::empty_function_to_force_script_dev_compile();
	maps\mp\bots\_bots_gametype_mugger::empty_function_to_force_script_dev_compile();
	maps\mp\bots\_bots_gametype_conf::empty_function_to_force_script_dev_compile();
	maps\mp\bots\_bots_gametype_sd::empty_function_to_force_script_dev_compile();
	maps\mp\bots\_bots_gametype_blitz::empty_function_to_force_script_dev_compile();
#/
*/
}


//========================================================
//					setup_callbacks 
//========================================================
setup_callbacks()
{
	// Setup level.bot_funcs callback function table
	level.bot_funcs = [];
	
	// Bot System functions
	level.bot_funcs["bots_spawn"]						= ::spawn_bots;
	level.bot_funcs["bots_add_scavenger_bag"]			= ::bot_add_scavenger_bag;
	level.bot_funcs["bots_add_to_level_targets"]		= ::bot_add_to_bot_level_targets;
	level.bot_funcs["bots_remove_from_level_targets"] 	= ::bot_remove_from_bot_level_targets;
	level.bot_funcs["bots_make_entity_sentient"]		= ::bot_make_entity_sentient;

	// Bot entity functions
	level.bot_funcs["think"]							= ::bot_think;
	level.bot_funcs["on_killed"]						= ::on_bot_killed;
	level.bot_funcs["should_do_killcam"]				= ::bot_should_do_killcam;
	level.bot_funcs["get_attacker_ent"]					= ::bot_get_known_attacker;
	level.bot_funcs["should_pickup_weapons"]			= ::bot_should_pickup_weapons;
	level.bot_funcs["on_damaged"]						= ::bot_damage_callback;
	level.bot_funcs["gametype_think"]					= ::default_gametype_think;
	level.bot_funcs["leader_dialog"]					= ::bot_leader_dialog;
	level.bot_funcs["player_spawned"]					= ::bot_player_spawned;
	level.bot_funcs["should_start_cautious_approach"]	= ::should_start_cautious_approach_default;
	level.bot_funcs["know_enemies_on_start"]			= ::bot_know_enemies_on_start;
	level.bot_funcs["bot_get_rank_xp"]					= ::bot_get_rank_xp;
	level.bot_funcs["ai_3d_sighting_model"]				= ::bot_3d_sighting_model;
	level.bot_funcs["dropped_weapon_think"]				= ::bot_think_seek_dropped_weapons;
	level.bot_funcs["dropped_weapon_cancel"]			= ::should_stop_seeking_weapon;
	level.bot_funcs["crate_can_use"]					= ::crate_can_use_always;
	level.bot_funcs["crate_low_ammo_check"]				= ::crate_low_ammo_check;
	level.bot_funcs["crate_should_claim"]				= ::crate_should_claim;
	level.bot_funcs["crate_wait_use"]					= ::crate_wait_use;
	level.bot_funcs["crate_in_range"]					= ::crate_in_range;
	level.bot_funcs["post_teleport"]					= ::bot_post_teleport;
	
	level.bot_random_path_function = [];
	level.bot_random_path_function["allies"]			= ::bot_random_path_default;
	level.bot_random_path_function["axis"]				= ::bot_random_path_default;
	
	level.bot_can_use_box_by_type["deployable_vest"]	= ::bot_should_use_ballistic_vest_crate;
	level.bot_can_use_box_by_type["deployable_ammo"]	= ::bot_should_use_ammo_crate;
	level.bot_can_use_box_by_type["scavenger_bag"]		= ::bot_should_use_scavenger_bag;
	level.bot_can_use_box_by_type["deployable_grenades"]= ::bot_should_use_grenade_crate;
	level.bot_can_use_box_by_type["deployable_juicebox"]= ::bot_should_use_juicebox_crate;
	
	level.bot_pre_use_box_of_type["deployable_ammo"]	= ::bot_pre_use_ammo_crate;
	level.bot_post_use_box_of_type["deployable_ammo"]	= ::bot_post_use_ammo_crate;
	
	level.bot_find_defend_node_func["capture"]			= ::find_defend_node_capture;
	level.bot_find_defend_node_func["capture_zone"]		= ::find_defend_node_capture_zone;
	level.bot_find_defend_node_func["protect"]			= ::find_defend_node_protect;
	level.bot_find_defend_node_func["bodyguard"]		= ::find_defend_node_bodyguard;
	level.bot_find_defend_node_func["patrol"]			= ::find_defend_node_patrol;
	
	// War (TDM) gametype serves as the default, so we use it to setup default gametype callbacks
	maps\mp\bots\_bots_gametype_war::setup_callbacks();
	
	// Should be after everything else, so fireteam mode can override specific callbacks if necessary
	if ( bot_is_fireteam_mode() )
	{
		bot_fireteam_setup_callbacks();
	}
}


//========================================================
//					CodeCallback_LeaderDialog 
//========================================================
CodeCallback_LeaderDialog( dialog, location )
{
	if ( IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["leader_dialog"] ) )
	{
		self [[ level.bot_funcs["leader_dialog"] ]]( dialog, location );
	}
}


//========================================================
//					init 
//========================================================
init()
{
	thread monitor_smoke_grenades();
	thread bot_triggers();
	
	initBotLevelVariables();
	
	/#
    level thread bot_debug_drawing();
    #/

    if( !shouldSpawnBots() )
		return;

	refresh_existing_bots();
	
	botAutoConnectValue = BotAutoConnectEnabled();
	if ( botAutoConnectValue > 0 )
	{
		setMatchData( "hasBots", true );

		if ( bot_is_fireteam_mode() )
		{
			// Fireteam mode : spawn bots on each team with specific loadouts
			level thread bot_fireteam_init();
			// Init Fireteam commander logic - this needs to be called after Callback_StartGameType's init() functions.
			level thread maps\mp\bots\_bots_fireteam_commander::init();
		}
		else// if ( botAutoConnectValue == 1 )
		{
			// "fill_open" : drop and spawn bots as needed
	    	level thread bot_connect_monitor();
		}
	} 
}


//========================================================
//					initVariables 
//========================================================
initBotLevelVariables()
{
	if ( !IsDefined(level.crateOwnerUseTime) )
	{
		level.crateOwnerUseTime = 500;
	}
	
	if ( !IsDefined(level.crateNonOwnerUseTime) )
	{
		level.crateNonOwnerUseTime	= 3000;
	}
	
	// Time it takes (after losing track of an enemy) for a bot to consider himself "out of combat"
	level.bot_out_of_combat_time = 3000;
	
	// Weapon that bots will use to shoot down helicopters
	level.bot_respawn_launcher_name = "iw6_panzerfaust3";
	
	// Weapon to use as absolute fallback
	level.bot_fallback_weapon = "iw6_knifeonly";

	level.zoneCount = GetZoneCount();
	
	initBotMapExtents();
}


initBotMapExtents()
{
	if ( IsDefined(level.teleportGetActiveNodesFunc) )
		all_nodes = [[level.teleportGetActiveNodesFunc]]();
	else
		all_nodes = GetAllNodes();
	
	level.bot_map_min_x = 0;
	level.bot_map_max_x = 0;
	level.bot_map_min_y = 0;
	level.bot_map_max_y = 0;
	level.bot_map_min_z = 0;
	level.bot_map_max_z = 0;
	if ( all_nodes.size > 1 )
	{
		level.bot_map_min_x = all_nodes[0].origin[0];
		level.bot_map_max_x = all_nodes[0].origin[0];
		level.bot_map_min_y = all_nodes[0].origin[1];
		level.bot_map_max_y = all_nodes[0].origin[1];
		level.bot_map_min_z = all_nodes[0].origin[2];
		level.bot_map_max_z = all_nodes[0].origin[2];
		
		for ( i = 1; i < all_nodes.size; i++ )
		{
			node_origin = all_nodes[i].origin;
			
			if ( node_origin[0] < level.bot_map_min_x )
				level.bot_map_min_x = node_origin[0];
			
			if ( node_origin[0] > level.bot_map_max_x )
				level.bot_map_max_x = node_origin[0];
			
			if ( node_origin[1] < level.bot_map_min_y )
				level.bot_map_min_y = node_origin[1];
			
			if ( node_origin[1] > level.bot_map_max_y )
				level.bot_map_max_y = node_origin[1];
							   
			if ( node_origin[2] < level.bot_map_min_z )
				level.bot_map_min_z = node_origin[2];
			
			if ( node_origin[2] > level.bot_map_max_z )
				level.bot_map_max_z = node_origin[2];
		}
	}
	
	level.bot_map_center = ( (level.bot_map_min_x + level.bot_map_max_x)/2 , (level.bot_map_min_y + level.bot_map_max_y)/2 , (level.bot_map_min_z + level.bot_map_max_z)/2 );
	
	// Needs to be the last line of initBotLevelVariables
	level.bot_variables_initialized = true;
}


bot_post_teleport()
{
	level.bot_variables_initialized = undefined;
	level.bot_initialized_remote_vehicles = undefined;
	
	initBotMapExtents();
	maps\mp\bots\_bots_ks_remote_vehicle::remote_vehicle_setup();
}


//========================================================
//					shouldSpawnBots 
//========================================================
shouldSpawnBots()
{
	return true;
}


refresh_existing_bots()
{
	wait 1; // give level.players a chance to initialize between rounds

	// If we switched sides, the bots will still exist in game but will have lost their think threads.  So we need to restart them
	foreach ( player in level.players )
	{
		if ( IsBot( player ) )
		{
 			player.equipment_enabled = true;
 			player.bot_team = player.team;
 			player.bot_spawned_before = true;
 			player thread [[ level.bot_funcs["think"] ]]();	
		}
	}
}

/#
bot_debug_drawing()
{
	level endon( "game_ended" );
	
	while( !bot_bots_enabled_or_added() )
		wait(1.0);
	
	level.defense_debug_structs = [];
	for( i=0; i<10; i++ )
	{
		level.defense_debug_structs[level.defense_debug_structs.size] = SpawnStruct();
	}
	level.cur_num_defense_debug_structs = 0;
	
	SetDevDvarIfUninitialized("bot_DebugPathToPlayer","");

	for(;;)
	{
		draw_debug_type = GetDvar("bot_DrawDebugSpecial");
		
		clear_defense_draw();
		if ( draw_debug_type == "defend" )
		{
			bot_debug_draw_defense();
		}
		else if ( draw_debug_type == "entrances" )
		{
			bot_debug_draw_watch_nodes();
		}
		else if ( draw_debug_type == "defend_with_entrances" )
		{
			bot_debug_draw_defense();
			bot_debug_draw_watch_nodes();
		}
		else if ( draw_debug_type == "key_entry_points" )
		{
			bot_debug_draw_cached_entrances();
		}
		else if ( draw_debug_type == "key_cached_paths" )
		{
			bot_debug_draw_cached_paths();
		}
		
		if ( GetDvar( "bot_DebugPathToPlayer" ) != "" && level.gameType == "war" )
		{
			SetDevDvar( "bot_DebugPathToPlayer", "" );
			
			human = get_all_humans()[0];
			if ( IsAlive(human) && human.team != "spectator" )
			{
				level.bot_debug_force_path_location = human.origin;
			}
		}
		
		/*
		// For testing bullet trace collision
		if ( IsDefined(level.players[0]) && IsAlive(level.players[0]) )
		{
			start = level.players[0] GetEye();
			player_forward = AnglesToForward(level.players[0] GetPlayerAngles());
			player_right = AnglesToRight(level.players[0] GetPlayerAngles());
			player_up = AnglesToUp(level.players[0] GetPlayerAngles());
			end = start + player_forward * 100;
			traceResult = BulletTrace( start, end, false, level.players[0], false, false, true );
			
			bot_draw_cylinder(end - (0,0,2.5), 4, 5, 0.05, undefined, (0,1,0), true, 4);
			
			// draw line from start to frac as blue, and frac to end as red
			line_start = start - player_up;
			line_end = end - player_up;
			line_midpoint = line_start + (line_end - line_start) * traceResult["fraction"];
			
			Line( line_start, line_midpoint, (0,0,1), 1.0, false );
			Line( line_midpoint, line_end, (1,0,0), 1.0, false );
		}
		*/
		
		wait(0.05);
	}
}

clear_defense_draw()
{
	for( i=0; i<level.cur_num_defense_debug_structs; i++ )
	{
		struct = level.defense_debug_structs[i];
		if ( IsDefined(struct.defense_trigger) && struct.defense_trigger.classname != "trigger_radius" )
			BotDebugDrawTrigger( false, level.defense_debug_structs[i].defense_trigger );
	}
	
	level.cur_num_defense_debug_structs = 0;
}

bot_debug_draw_defense()
{
	assert(level.cur_num_defense_debug_structs == 0);
	foreach( player in level.participants )
	{
		if ( !IsDefined( player.team ) )
			continue;
		
		if ( player.health > 0 && IsAI( player ) && player bot_is_defending() )
		{
			struct_for_defense = undefined;
			for( i=0; i<level.cur_num_defense_debug_structs; i++ )
			{
				struct = level.defense_debug_structs[i];
				same_defense_type = struct.defense_type == player.bot_defending_type;
				same_defense_radius = IsDefined(struct.defense_radius) && IsDefined(player.bot_defending_radius) && (struct.defense_radius == player.bot_defending_radius);
				same_defense_trigger = IsDefined(struct.defense_trigger) && IsDefined(player.bot_defending_trigger) && (struct.defense_trigger == player.bot_defending_trigger);
				if ( same_defense_type && (same_defense_radius || same_defense_trigger) )
				{
					if ( bot_vectors_are_equal( struct.defense_center, player.bot_defending_center ) )
					{
						struct_for_defense = struct;
						break;
					}
				}
			}
			
			if ( IsDefined(struct_for_defense) )
			{
				if ( struct_for_defense.defense_team != player.team )
				{
					struct_for_defense.cylinder_color = (1,0,1);
				}
				
				struct_for_defense.bots = array_add( struct_for_defense.bots, player );
			}
			else
			{
				new_defense_struct = level.defense_debug_structs[level.cur_num_defense_debug_structs];
				level.cur_num_defense_debug_structs++;
				
				// Create a struct for this defense type
				if ( player.team == "allies" )
				{
					new_defense_struct.cylinder_color = (0,0,1); // allies are blue
				}
				else if ( player.team == "axis" )
				{
					new_defense_struct.cylinder_color = (1,0,0); // axis are red
				}
				
				new_defense_struct.defense_team = player.team;
				new_defense_struct.defense_type = player.bot_defending_type;
				new_defense_struct.defense_radius = player.bot_defending_radius;
				new_defense_struct.defense_trigger = player.bot_defending_trigger;
				new_defense_struct.defense_center = player.bot_defending_center;
				new_defense_struct.defense_nodes = player.bot_defending_nodes;
				new_defense_struct.bots = [];
				new_defense_struct.bots = array_add( new_defense_struct.bots, player );
			}
		}
	}
	
	for( i=0; i<level.cur_num_defense_debug_structs; i++ )
	{
		struct = level.defense_debug_structs[i];
		
		if ( IsDefined(struct.defense_nodes) )
		{
			// Draw nodes
			foreach( node in struct.defense_nodes )
				bot_draw_cylinder(node.origin, 10, 10, 0.05, undefined, struct.cylinder_color, true, 4);
		}
		
		if ( IsDefined(struct.defense_trigger) )
		{
			// Draw trigger
			if ( struct.defense_trigger.classname != "trigger_radius" )
				BotDebugDrawTrigger(true, level.defense_debug_structs[i].defense_trigger, struct.cylinder_color, true);
			else
				bot_draw_cylinder(struct.defense_center, struct.defense_trigger.radius, struct.defense_trigger.height, 0.05, undefined, struct.cylinder_color, true);
		}
		
		if ( IsDefined(struct.defense_radius) )
		{
			// Draw cylinder
			bot_draw_cylinder(struct.defense_center, struct.defense_radius, 75, 0.05, undefined, struct.cylinder_color, true);
		}
		
		foreach( bot in struct.bots )
		{
			lineStart = struct.defense_center + (0,0,25);
			lineEnd = bot.origin + (0,0,25);
			
			line_color = undefined;
			if ( bot.team == "allies" )
				line_color = (0,0,1);
			else if ( bot.team == "axis" )
				line_color = (1,0,0);
			
			line( lineStart, lineEnd, line_color, 1, true );
			
			if ( IsDefined(bot.bot_defending_override_origin_node) )
			{
				node_line_color = (max(line_color[0],0.3),max(line_color[1],0.3),max(line_color[2],0.3));
				bot_draw_cylinder(bot.bot_defending_override_origin_node.origin, 10, 10, 0.05, undefined, node_line_color, true, 4);
				line( bot.bot_defending_override_origin_node.origin, lineEnd, node_line_color, 1, true );
			}
		}
	}	
}

bot_debug_draw_watch_nodes()
{
	foreach( player in level.participants )
	{
		if ( player.health > 0 && IsAI( player ) && IsDefined(player.watch_nodes)  )
		{
			node_offset = (0,0,player GetPlayerViewHeight());
			foreach( node in player.watch_nodes )
			{
				// green means "high priority watch"
				// white means "low priority watch"
				// color lerps between the two
				entrance_color = (1 - node.watch_node_chance[player.entity_number], 1, 1 - node.watch_node_chance[player.entity_number]);
				
				line( player.origin + node_offset, node.origin + (0,0,30), entrance_color, 1, true );
				bot_draw_cylinder(node.origin + (0,0,30), 10, 10, 0.05, undefined, entrance_color, true, 4);
			}
		}
	}
}

bot_debug_draw_cached_entrances()
{
	if ( !IsDefined( level.entrance_indices ) || !IsDefined(level.entrance_points) )
		return;
	
	node_offset = (0,0,11);
	standing_offset = (0,0,55);
	crouching_offset = (0,0,40);
	prone_offset = (0,0,15);
	color_visible = (0,1,0);
	color_not_visible = (1,0,0);
	node_height = 13;
	for ( i = 0; i < level.entrance_indices.size; i++ )
	{
		entrance_collection = level.entrance_points[level.entrance_indices[i]];
		for ( j = 0; j < entrance_collection.size; j++ )
		{
			bot_draw_cylinder(entrance_collection[j].origin + node_offset, 10, node_height, 0.05, undefined, (0,1,0), true, 4);
			
			// standing
			line( level.entrance_origin_points[i] + standing_offset, entrance_collection[j].origin + node_offset + (0,0,node_height/2), color_visible, 1, true );
			
			// crouching
			color_to_use = color_not_visible;
			if ( entrance_collection[j].crouch_visible_from[level.entrance_indices[i]] )
				color_to_use = color_visible;
			line( level.entrance_origin_points[i] + crouching_offset, entrance_collection[j].origin + node_offset + (0,0,node_height/2), color_to_use, 1, true );
			
			// prone
			color_to_use = color_not_visible;
			if ( entrance_collection[j].prone_visible_from[level.entrance_indices[i]] )
				color_to_use = color_visible;
			line( level.entrance_origin_points[i] + prone_offset, entrance_collection[j].origin + node_offset + (0,0,node_height/2), color_to_use, 1, true );
		}
		
		// Note: this white cylinder is the botTarget, if it exists
		bot_draw_cylinder(level.entrance_origin_points[i], 10, 75, 0.05, undefined, (1,1,1), true, 8);
	}
}

bot_debug_draw_cached_paths()
{
	if ( !IsDefined( level.entrance_indices ) )
		return;
	
	node_colors = [ (1,0,0), (0,1,0), (0,0,1), (1,0,1), (1,1,0), (0,1,1), (1,0.6,0.6), (0.6,1,0.6), (0.6,0.6,1), (0.1,0.1,0.1) ];

	if ( !IsDefined(level.next_path_time) )
	{
		level.bot_debug_cur_first_index = level.entrance_indices.size - 2;
		level.bot_debug_cur_second_index = level.entrance_indices.size - 1;
		level.next_path_time = GetTime() - 1;
	}

	if ( GetTime() > level.next_path_time )
	{
		keep_trying = true;
		while(keep_trying)
		{
			if ( level.bot_debug_cur_second_index == level.entrance_indices.size - 1 )
			{
				if ( level.bot_debug_cur_first_index == level.entrance_indices.size - 2 )
				{
					level.bot_debug_cur_first_index = 0;
					level.bot_debug_cur_node_color = -1;
				}
				else
				{
					level.bot_debug_cur_first_index++;
				}
				level.bot_debug_cur_second_index = level.bot_debug_cur_first_index + 1;
			}
			else
			{
				level.bot_debug_cur_second_index++;
			}
			
			keep_trying = !IsDefined(level.precalculated_paths[level.entrance_indices[level.bot_debug_cur_first_index]][level.entrance_indices[level.bot_debug_cur_second_index]]);
		}
		
		level.bot_debug_cur_node_color = (level.bot_debug_cur_node_color + 1) % node_colors.size;
		level.next_path_time = GetTime() + (15 * 1000);
	}
	
	// Note: these white cylinders are the botTargets, if they exist
	bot_draw_cylinder(level.entrance_origin_points[level.bot_debug_cur_first_index], 10, 75, 0.05, undefined, (1,1,1), true, 8);
	bot_draw_cylinder(level.entrance_origin_points[level.bot_debug_cur_second_index], 10, 75, 0.05, undefined, (1,1,1), true, 8);
	foreach( node in level.precalculated_paths[level.entrance_indices[level.bot_debug_cur_first_index]][level.entrance_indices[level.bot_debug_cur_second_index]] )
	{
		bot_draw_cylinder(node.origin, 10, 13, 0.05, undefined, node_colors[level.bot_debug_cur_node_color], true, 4);
	}
}
#/

//========================================================
//				bot_player_spawned 
//========================================================
bot_player_spawned()
{
	self bot_set_loadout_class();
	
	if( IsDefined( self.prev_personality ) )
	{
		self bot_set_personality( self.prev_personality );
		self.prev_personality = undefined;
	}
}

bot_set_loadout_class()
{
	if ( !IsDefined( self.bot_class ) ) 
	{
		if ( !bot_gametype_chooses_class() )
		{
			while( !IsDefined(level.bot_loadouts_initialized) )
				wait(0.05);
			
			/#
			debugClass = GetDvar( "bot_debugClass", "" );
			if ( IsDefined( debugClass ) && debugClass != "" )
			{
				self.bot_class = debugClass;
				return;
			}
			#/
			
			if ( IsDefined( self.override_class_function ) )
			{
		 		self.bot_class = [[ self.override_class_function ]]();
			}
		 	else
		 	{
		 		self.bot_class = bot_setup_callback_class();
			}
		}
		else
		{
			self.bot_class = self.class;
		}
    }
}

watch_players_connecting()
{
	while(1)
	{
		level waittill("connected", player);
		if ( !IsAI( player ) && (level.players.size > 0) )	// If playing a local listen server, ignore this for the first player to join
		{
			level.players_waiting_to_join = array_add(level.players_waiting_to_join, player);
			childthread bots_notify_on_spawn(player);
			childthread bots_notify_on_disconnect(player);
			childthread bots_remove_from_array_on_notify(player);
		}
	}
}

bots_notify_on_spawn(player)
{
	player endon("bots_human_disconnected");
	while( !array_contains(level.players,player) )
	{
		wait(0.05);
	}
	player notify("bots_human_spawned");
}

bots_notify_on_disconnect(player)
{
	player endon("bots_human_spawned");
	player waittill("disconnect");
	player notify("bots_human_disconnected");
}

bots_remove_from_array_on_notify(player)
{
	player waittill_any("bots_human_spawned","bots_human_disconnected");
	level.players_waiting_to_join = array_remove(level.players_waiting_to_join,player);
}

monitor_pause_spawning()
{
	// The purpose of this function (and all the childthreads) is to pause bot spawning while a human player is in the process of joining the game
	// So when a human connects, we add him to the "waiting" array, and he stays in there until he spawns in the game or disconnects
	// As long as there are any humans in the queue, we don't want bots to be spawning and taking up the human players' spots
	
	level.players_waiting_to_join = [];
	childthread watch_players_connecting();
	
	while(1)
	{
		if ( level.players_waiting_to_join.size > 0 )
			level.pausing_bot_connect_monitor = true;
		else
			level.pausing_bot_connect_monitor = false;
		
		wait(0.5);
	}
}

//========================================================
//				bot_can_join_team 
//========================================================
bot_can_join_team( team )
{
	// Checks ahead of time if _menus.gsc::setTeam() is going to approve of the bot's team choice
	// Only necessary to return false if we are in a private match with team balancing (or SS/SL) and game mode has team limits active

	if ( matchMakingGame() )
		return true;
	
	if( GetDvar( "squad_vs_squad" ) == "1" )
		return true;

	if ( !level.teamBased )
		return true;
	
	if ( maps\mp\gametypes\_teams::getJoinTeamPermissions( team ) )
		return true;
	
	return false;
}

//========================================================
//				bot_connect_monitor 
//========================================================
bot_connect_monitor( num_ally_bots, num_enemy_bots )
{
	level endon( "game_ended" );
	
	self notify( "bot_connect_monitor" );
	self endon( "bot_connect_monitor" );

	level.pausing_bot_connect_monitor = false;
	childthread monitor_pause_spawning();
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 0.5 );
	bot_connect_monitor_update_time = 1.5;
	
	if ( !IsDefined( level.bot_cm_spawned_bots ) )
		level.bot_cm_spawned_bots = false;

	if ( !IsDefined( level.bot_cm_waited_players_time ) )
		level.bot_cm_waited_players_time = 0;
	
	if ( !IsDefined( level.bot_cm_human_picked ) )
		level.bot_cm_human_picked = false;

	if( ( GetDvar( "squad_vs_squad" ) == "1" ) )
    {
		while ( !( isDefined( level.squad_vs_squad_allies_client ) && isDefined( level.squad_vs_squad_axis_client ) ) )
		{
			wait 0.05;
		}
		wait 2.0; // wait a bit for additional humans to connect
    }
	
	if( ( GetDvar( "squad_match" ) == "1" ) )
    {
   		while ( !isDefined( level.squad_match_client ) )
		{
			wait 0.05;
		}
		wait 2.0; // wait a bit for additional humans to connect
    }

	if( ( GetDvar( "squad_use_hosts_squad" ) == "1" ) )
    {
   		while ( !isDefined( level.wargame_client ) )
		{
			wait 0.05;
		}
		wait 2.0; // wait a bit for additional humans to connect
    }

	for(;;)
	{
		if ( level.pausing_bot_connect_monitor )
		{
			maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( bot_connect_monitor_update_time );
			continue;
		}

		ignore_team_balance = IsDefined(level.bots_ignore_team_balance) || !level.teamBased;
		
		// NOTE: if level.bots_ignore_team_balance is defined, these variables don't control the number of bots per team,
		// but combined they do control the absolute number of bots.  For example if level.bots_ignore_team_balance is defined, and 
		// max_ally_bots_absolute is 2 and max_enemy_bots_absolute is 8, the total number of bots you can have in the match is 10, but the
		// ally team could have all 10 of them.
		max_ally_bots_absolute = BotGetTeamLimit( 0 );
		max_enemy_bots_absolute = BotGetTeamLimit( 1 );
		
		difficultyAlly = BotGetTeamDifficulty( 0 );
		difficultyEnemy = BotGetTeamDifficulty( 1 );

		/#
		// dont kick/spawn bots for team balance while this is on (for example if test clients have been added via the scr_testclients dvar)
		if ( GetDvarInt("bot_DisableAutoConnect") )
		{
			maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( bot_connect_monitor_update_time );
			continue;
		}
		#/
					
		team_ally = "allies";	// team_ally is the team that the human player is on
		team_enemy = "axis";	// team_enemy is the enemy team (opposed to the team the human player is on)
		clientCounts = bot_client_counts();
		numHumans = cat_array_get( clientCounts, "humans" );
		
		if ( numHumans > 1 )
		{
			hostPlayerTeam = bot_get_host_team();
			if ( !matchMakingGame() && IsDefined(hostPlayerTeam) && hostPlayerTeam != "spectator" )
			{
				team_ally = hostPlayerTeam;
				team_enemy = getOtherTeam( hostPlayerTeam );
			}
			else
			{
				cur_num_allies_players = cat_array_get( clientCounts, "humans_" + "allies");
				cur_num_axis_players = cat_array_get( clientCounts, "humans_" + "axis");
				if ( cur_num_axis_players > cur_num_allies_players )
				{
					// If there are more axis players, consider that to be team_ally (team that human players are on)
					team_ally = "axis";
					team_enemy = "allies";
				}
			}
		}
		else
		{
			humanPlayer = get_human_player();
			if ( IsDefined( humanPlayer ) )
			{
				humanPlayer_team = humanPlayer bot_get_player_team();
				if ( IsDefined(humanPlayer_team) && humanPlayer_team != "spectator" )
				{
					team_ally = humanPlayer_team;
					team_enemy = getOtherTeam( humanPlayer_team );
				}
			}
		}
		
		// Count the max size of each team (in terms of client limits)
		ally_team_size = bot_get_team_limit();
		enemy_team_size = bot_get_team_limit();
		if ( ally_team_size + enemy_team_size < bot_get_client_limit() )
		{
			// The client limit is odd, so add 1 to a team so we are still at the client limit
			if ( ally_team_size < max_ally_bots_absolute )
				ally_team_size++;
			else if ( enemy_team_size < max_enemy_bots_absolute )
				enemy_team_size++;
		}
				
		// Count current number of humans
		cur_num_ally_humans = cat_array_get( clientCounts, "humans_" + team_ally);
		cur_num_enemy_humans = cat_array_get( clientCounts, "humans_" + team_enemy);
		cur_num_humans = cur_num_ally_humans + cur_num_enemy_humans;
		
		// Count current number of spectators and try predict which team they will join
		cur_num_spectators = cat_array_get( clientCounts, "spectator" );
		cur_num_ally_spectators = 0;
		cur_num_enemy_spectators = 0;
		while( cur_num_spectators > 0 )
		{
			ally_team_has_room_for_another_spectator = (cur_num_ally_humans + cur_num_ally_spectators + 1 <= ally_team_size);
			enemy_team_has_room_for_another_spectator = (cur_num_enemy_humans + cur_num_enemy_spectators + 1 <= enemy_team_size);
			
			if ( ally_team_has_room_for_another_spectator && !enemy_team_has_room_for_another_spectator )
			{
				cur_num_ally_spectators++;
			}
			else if ( !ally_team_has_room_for_another_spectator && enemy_team_has_room_for_another_spectator )
			{
				cur_num_enemy_spectators++;
			}
			else if ( ally_team_has_room_for_another_spectator && enemy_team_has_room_for_another_spectator )
			{
				if ( (cur_num_spectators % 2) == 1 )
					cur_num_ally_spectators++;
				else
					cur_num_enemy_spectators++;
			}
			
			cur_num_spectators--;
		}
		
		// Count current number of bots
		cur_num_ally_bots = cat_array_get( clientCounts, "bots_" + team_ally);
		cur_num_enemy_bots = cat_array_get( clientCounts, "bots_" + team_enemy);
		cur_num_bots = cur_num_ally_bots + cur_num_enemy_bots;
		if ( cur_num_bots > 0 )
			level.bot_cm_spawned_bots = true;
		
		waitingForHumanToChoose = false;
		
		if ( !level.bot_cm_human_picked )
		{
			waitingForHumanToChoose = !bot_get_human_picked_team();
			
			/#
			// Exception for developer dvar bot_autoconnectdefault which is used to get default BotAutoConnectEnabled() in command line runs
			if ( GetDvarInt( "bot_autoconnectdefault" ) && waitingForHumanToChoose )
				waitingForHumanToChoose = false;
			#/
			
			if ( !waitingForHumanToChoose )
				level.bot_cm_human_picked = true;
		}
		
		if ( waitingForHumanToChoose )
		{
			// In split screen mode (Local Play as its called now) never spawn in until a human has made a choice
			splitScreenWait = !getDvarInt( "systemlink" ) && !getDvarInt( "onlinegame" );

			// With lopsided team sizes dont spawn ANY bots until a human has picked their team or 10 seconds has passed and prematch is over
			lopsidedWait = !ignore_team_balance && (max_enemy_bots_absolute != max_ally_bots_absolute) && !level.bot_cm_spawned_bots && ((level.bot_cm_waited_players_time < 10) || !gameFlag("prematch_done"));
			
			if ( splitScreenWait || lopsidedWait )
			{				
				level.bot_cm_waited_players_time += bot_connect_monitor_update_time;
				maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( bot_connect_monitor_update_time );
				continue;
			}
		}
		
		// Open bot slots per team is either the number of available spots (team size - number of humans) or the hard limit, whichever is lower
		ally_bot_slots = INT(min(ally_team_size - cur_num_ally_humans - cur_num_ally_spectators,max_ally_bots_absolute));
		enemy_bot_slots = INT(min(enemy_team_size - cur_num_enemy_humans - cur_num_enemy_spectators,max_enemy_bots_absolute));
		
		// Make sure we are not leaving one team short because of reduced absolute limits being imbalanced
		fillTeam = 1;
		slotCount = (ally_bot_slots + enemy_bot_slots + numHumans);
		slotLimit = (max_ally_bots_absolute + max_enemy_bots_absolute + numHumans);
		lastSlotCount = [-1, -1];
		while ( (slotCount < bot_get_client_limit()) && (slotCount < slotLimit) )
		{
			if ( fillTeam && (ally_bot_slots < max_ally_bots_absolute) && bot_can_join_team( team_ally ) )
				ally_bot_slots++;
			else if ( !fillTeam && (enemy_bot_slots < max_enemy_bots_absolute) && bot_can_join_team( team_enemy ) )
				enemy_bot_slots++;
			slotCount = (ally_bot_slots + enemy_bot_slots + numHumans);
			
			// if we have come back to the same team again and not added any new slots we are done
			if ( lastSlotCount[fillTeam] == slotCount )
				break;
			
			lastSlotCount[fillTeam] = slotCount;		
			fillTeam = !fillTeam;
		}
				
		// When teams are not deliberately unbalanced by request, keep waiting up to 10 seconds for human to pick a team before spawning last bot when there is only one human playing
		if ( (max_ally_bots_absolute == max_enemy_bots_absolute) && !ignore_team_balance && (cur_num_ally_spectators == 1) && (cur_num_enemy_spectators == 0) && (enemy_bot_slots > 0) )
		{
			if ( !IsDefined( level.bot_prematchDoneTime ) && gameFlag("prematch_done") )
				level.bot_prematchDoneTime = GetTime();
			if ( waitingForHumanToChoose && (!IsDefined( level.bot_prematchDoneTime ) || ((GetTime() - level.bot_prematchDoneTime) < 10000)) )
				enemy_bot_slots--;
	    }	

		// Number of bots wanted right now is the number of available slots (from above) minus the number of bots currently in the game
		ally_bots_wanted = ally_bot_slots - cur_num_ally_bots;
		enemy_bots_wanted = enemy_bot_slots - cur_num_enemy_bots;
		
		need_to_spawn_or_drop = true;
		if ( ignore_team_balance )
		{
			// Don't move bots between teams, but maybe spawn or drop them if necessary
			total_team_size = ally_team_size + enemy_team_size;
			max_total_bots_absolute = max_ally_bots_absolute + max_enemy_bots_absolute;
			cur_num_total_humans = cur_num_ally_humans + cur_num_enemy_humans;
			cur_num_total_bots = cur_num_ally_bots + cur_num_enemy_bots;
			total_bot_slots_open = INT(min(total_team_size - cur_num_total_humans,max_total_bots_absolute));
			
			total_num_bots_wanted = total_bot_slots_open - cur_num_total_bots;
			if ( total_num_bots_wanted == 0 )
			{
				// No changes needed
				need_to_spawn_or_drop = false;
			}
			else if ( total_num_bots_wanted > 0 )
			{
				// Need to add bots.  Just even them out between teams (doesn't really matter though)
				ally_bots_wanted = INT(total_num_bots_wanted/2) + (total_num_bots_wanted % 2 );
				enemy_bots_wanted = INT(total_num_bots_wanted/2);
			}
			else if ( total_num_bots_wanted < 0 )
			{
				// Need to remove bots.  First try to remove them from the ally team, then if that doesn't do it, the enemy team as well
				num_of_bots_to_drop = total_num_bots_wanted * -1;
							
				ally_bots_wanted = -1 * INT(min(num_of_bots_to_drop,cur_num_ally_bots));
				enemy_bots_wanted = -1 * (num_of_bots_to_drop + ally_bots_wanted);
			}
		}
		else if ( !matchMakingGame() && (ally_bots_wanted * enemy_bots_wanted < 0 && gameFlag("prematch_done") && !IsDefined(level.bots_disable_team_switching)) )
		{
			// ally_bots_wanted and enemy_bots_wanted are both nonzero and have opposite signs.
			// This means one team needs to gain players and one needs to lose them.  So move bots from one team to the other.
			difference = INT(min(abs(ally_bots_wanted),abs(enemy_bots_wanted)));
			
			if ( ally_bots_wanted > 0 )
				move_bots_from_team_to_team( difference, team_enemy, team_ally, difficultyAlly );
			else if ( enemy_bots_wanted > 0 )
				move_bots_from_team_to_team( difference, team_ally, team_enemy, difficultyEnemy );
			
			need_to_spawn_or_drop = false;
		}
		
		if ( need_to_spawn_or_drop )
		{
			// Spawn or drop bots for teams that are under / over the limit
			if ( enemy_bots_wanted < 0 )
				drop_bots( enemy_bots_wanted * -1, team_enemy );
			if ( ally_bots_wanted < 0 )
				drop_bots( ally_bots_wanted * -1, team_ally );
			
			if ( enemy_bots_wanted > 0 )
				level thread spawn_bots( enemy_bots_wanted, team_enemy, undefined, undefined, "spawned_enemies", difficultyEnemy );
			if ( ally_bots_wanted > 0 )
				level thread spawn_bots( ally_bots_wanted, team_ally, undefined, undefined, "spawned_allies", difficultyAlly );
			
			if ( enemy_bots_wanted > 0 && ally_bots_wanted > 0 )
				level waittill_multiple( "spawned_enemies", "spawned_allies" );
			else if ( enemy_bots_wanted > 0 )
				level waittill( "spawned_enemies" );
			else if ( ally_bots_wanted > 0 )
				level waittill( "spawned_allies" );
		}
		
		if ( difficultyEnemy != difficultyAlly )
		{
			bots_update_difficulty( team_enemy, difficultyEnemy );
			bots_update_difficulty( team_ally, difficultyAlly );
		}
	
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( bot_connect_monitor_update_time );
	}
}

bot_get_player_team()
{
	if ( IsDefined(self.team) )
		return self.team;
	
	if ( IsDefined(self.pers["team"]) )
		return self.pers["team"];
	
	return undefined;
}

bot_get_host_team()
{
	foreach( player in level.players )
	{
		if ( !isAI( player ) && player isHost() )
			return player bot_get_player_team();
	}

	return "spectator";
}

bot_get_human_picked_team()
{
	haveHost = false;
	humanChose = false;
	hostChose = false;
	
	foreach ( player in level.players )
	{
		if ( !isAI( player ) )
		{
			if ( player isHost() )
				haveHost = true;
			
			if ( player_picked_team( player ) )
			{
				humanChose = true;
				
				if ( player IsHost() )
					hostChose = true;
			}
		}
	}
	
	return ( hostChose || (humanChose && !haveHost) );
}

player_picked_team( player )
{
	if ( IsDefined( player.team ) && player.team != "spectator" )
		return true;
	
	if ( IsDefined( player.spectating_actively ) && player.spectating_actively )
		return true;

	if ( player IsMLGSpectator() && IsDefined( player.team ) && player.team == "spectator" )
		return true;
	
	return false;
}

bot_client_counts()
{
	clientCounts = [];
	
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];
		if ( IsDefined(player) && IsDefined(player.team) )
		{
			clientCounts = cat_array_add( clientCounts, "all" );
			clientCounts = cat_array_add( clientCounts, player.team );
			if ( IsBot( player ) )
			{
				clientCounts = cat_array_add( clientCounts, "bots" );
				clientCounts = cat_array_add( clientCounts, "bots_" + player.team );
			}
			else
			{
				clientCounts = cat_array_add( clientCounts, "humans" );
				clientCounts = cat_array_add( clientCounts, "humans_" + player.team );
			}
		}
	}
	
	return clientCounts;
}

cat_array_add( arrayCounts, category )
{
	if ( !IsDefined( arrayCounts ) )
	{
		arrayCounts = [];
	}
	
	if ( !IsDefined( arrayCounts[ category ] ) )
	{
		arrayCounts[ category ] = 0;
	}

	arrayCounts[ category ] = arrayCounts[ category ] + 1;
	
	return arrayCounts;
}

cat_array_get( arrayCounts, category )
{
	if ( !IsDefined( arrayCounts ) )
	{
		return 0;
	}
	
	if ( !IsDefined( arrayCounts[ category ] ) )
	{
		return 0;
	}

	return arrayCounts[ category ];
}

//========================================================
//				move_bots_from_team_to_team 
//========================================================
move_bots_from_team_to_team( count, teamFrom, teamTo, difficulty )
{
	foreach ( player in level.players )
	{
		if ( !IsDefined( player.team ) )
			continue;

		if ( IsDefined( player.connected ) && player.connected && IsBot( player ) && player.team == teamFrom )
		{
			player.bot_team = teamTo;
			if ( IsDefined( difficulty ) )
				player bot_set_difficulty( difficulty );

			player notify( "luinotifyserver", "team_select", bot_lui_convert_team_to_int(teamTo) );
			wait(0.05);	// Wait for the team change
			player notify( "luinotifyserver", "class_select", player.bot_class );
						
			count--;
			
			if ( count <= 0 )
				break;
			else
				wait(0.1);
		}
	}
}

//========================================================
//				bots_update_difficulty 
//========================================================
bots_update_difficulty( team, difficulty )
{
	foreach ( player in level.players )
	{
		if ( !IsDefined( player.team ) )
			continue;

		if ( IsDefined( player.connected ) && player.connected && IsBot( player ) && player.team == team )
		{
			if ( difficulty != (player BotGetDifficulty()) )
				player bot_set_difficulty( difficulty );
		}
	}
}


//========================================================
//				bot_drop 
//========================================================
bot_drop() // self = bot
{
	assert( isBot( self ) );
	assert( self.connected );

	kick( self.entity_number, "EXE_PLAYERKICKED_BOT_BALANCE" );
	
	wait 0.1;
}


//========================================================
//				drop_bots 
//========================================================
drop_bots( count, team )
{
	bots = [];

	foreach ( player in level.players )
	{
		if ( IsDefined( player.connected ) && player.connected && IsBot( player ) && (!IsDefined( team ) || (IsDefined( player.team ) && player.team == team)) )
			bots[bots.size] = player;
	}
	
	// First try to drop any bots who are dead (to avoid distrupting a game of S&R for example)
	for ( i = bots.size - 1; i >= 0; i-- )
	{
		if ( count <= 0 )
			break;

		if ( !isReallyAlive( bots[i] ) )
		{
			bots[i] bot_drop();
			bots = array_remove( bots, bots[i] );
			count--;
		}
	}

	// Then drop any who are still remaining
	for ( i = bots.size - 1; i >= 0; i-- )
	{
		if ( count <= 0 )
			break;

		bots[i] bot_drop();
		count--;
	}
}


bot_lui_convert_team_to_int( team_name )
{
	if ( team_name == "axis" )
		return 0;
	else if ( team_name == "allies" )
		return 1;
	else if ( team_name == "autoassign" || team_name == "random" )
		return 2;
	else // if ( team_name == "spectator" )
		return 3;
}


spawn_bot_latent( team, botCallback, connecting )
{		
	function_wait_time = GetTime() + 60000;

	// Wait for spawn to be allowed. This is typically an indication that the models need to be streamed in.
	// This loop could be enhanced by adding all the test clients first, then waiting on the spawn, or threading off the wait

	while ( !self CanSpawnTestClient() )
	{
		// This could block forever in cases when some client's can't sync. Ideally the client itself would be
		// dropped, this is temporary until such a system is implemented.
		if ( GetTime() >= function_wait_time )
		{ 
			kick( self.entity_number, "EXE_PLAYERKICKED_BOT_BALANCE" );
			connecting.abort = true;
			return;
		}

		wait( 0.05 );
		
		// Entity may have been removed in the meantime

		if ( !IsDefined( self ) )
		{
			connecting.abort = true;
			return;
		}
	}
	
	// Randomize a bit to simulate bot selecting team/loadout
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause ( RandomFloatRange( 0.25, 2.0 ) );
		
	if ( !IsDefined( self ) )
	{
		connecting.abort = true;
		return;
	}
	
	self SpawnTestClient();

    self.pers["isBot"] = true;
 	self.equipment_enabled = true;
 	self.bot_team = team;
 	
 	if ( IsDefined( connecting.difficulty ) )
 		self bot_set_difficulty( connecting.difficulty );
 		
 	if( IsDefined( botCallback ) )
 	{
 		self [[botCallback]]();
 	}
 		
 	self thread [[ level.bot_funcs["think"] ]]();
 	
 	connecting.ready = true;
}


find_squad_member_index( client, team )
{
	active_squad_member = client GetRankedPlayerData( "activeSquadMember" );
	found = false;
	count = 0;
	
	while ( count < 10 )	//this needs to be kept in sync with max squads in player data
	{
		found = false;
		index = client GetRankedPlayerData( "squadHQ", "aiSquadMembers", count );

		if ( index == active_squad_member )
		{
			count++;
			continue;
		}
		
		if ( !IsDefined( level.human_team_bot_added ) || !IsDefined( level.human_team_bot_added[ index ] ) || level.human_team_bot_added[ index ] == false )
		{
			return index;
		}

		count++;
	}
	
	return -1;
}


//========================================================
//					spawn_bots 
//========================================================
spawn_bots( num_bots, team, botCallback, haltWhenFull, notifyWhenDone, difficulty )
{
	function_wait_time = GetTime() + 10000;

	connectingArray = [];
	
	squad_index = connectingArray.size;
	
	// First get all the bots connected
	while ( (level.players.size < bot_get_client_limit()) && (connectingArray.size < num_bots) && (GetTime() < function_wait_time) ) // don't want to be stuck in this function forever
 	{
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 0.05 );

		bot = undefined;
		
		if( ( GetDvar( "squad_vs_squad" ) == "1" ) )
		{
			leader = level.squad_vs_squad_axis_client;
			if ( team == "allies" )
			{
				leader = level.squad_vs_squad_allies_client;
			}

			if ( IsDefined( leader ) )
			{
				index_needed = squad_index;
				active_squad_member = leader GetRankedPlayerData( "activeSquadMember" );
				slot = 0;
				index = 0;

				for ( squad_member = 0; squad_member < bot_get_team_limit(); squad_member++ )
				{
					index = leader GetRankedPlayerData( "squadHQ", "aiSquadMembers", squad_member );
					
					if ( index == active_squad_member )
						continue;

					if ( index_needed == slot )
						break;
					
					slot++;
				}

				name = leader GetRankedPlayerData( "squadMembers", index, "name" );
				head = leader GetRankedPlayerData( "squadMembers", index, "head" );
				body = leader GetRankedPlayerData( "squadMembers", index, "body" );
				helmet = leader GetRankedPlayerData( "squadMembers", index, "helmet" );

				bot = AddBot( name, head, body, helmet );
				if ( IsDefined( bot ) )
				{
					bot.pers[ "squadSlot" ] = index;
				}
			}
			else
			{
				if ( !IsDefined( level.squad_vs_squad_has_forfeited ) )
				{
					if ( IsDefined( level.squad_vs_squad_axis_client ) )
					{
						level.finalKillCam_winner = "axis";
						thread maps\mp\gametypes\_gamelogic::endGame( "axis", game[ "end_reason" ][ "allies_forfeited" ] );
					}
					else
					{
						level.finalKillCam_winner = "allies";
						thread maps\mp\gametypes\_gamelogic::endGame( "allies", game[ "end_reason" ][ "axis_forfeited" ] );
					}
					
					level.squad_vs_squad_has_forfeited = true;
				}
			}
		}
		else if( ( GetDvar( "squad_use_hosts_squad" ) == "1" ) )
		{
			if ( level.wargame_client.team == team )
			{
				if ( matchMakingGame() )
				{
					index = find_squad_member_index( level.wargame_client, team );

					name = level.wargame_client GetRankedPlayerData( "squadMembers", index, "name" );
					head = level.wargame_client GetRankedPlayerData( "squadMembers", index, "head" );
					body = level.wargame_client GetRankedPlayerData( "squadMembers", index, "body" );
					helmet = level.wargame_client GetRankedPlayerData( "squadMembers", index, "helmet" );

					bot = AddBot( name, head, body, helmet );
					if ( IsDefined( bot ) )
					{
						level.human_team_bot_added[ index ] = true;
						bot.pers[ "squadSlot" ] = index;
					}
				}
				else
				{
					index_needed = squad_index;
					active_squad_member = level.wargame_client GetPrivatePlayerData( "privateMatchActiveSquadMember" );
					slot = 0;
					index = 0;

					for ( squad_member = 0; squad_member < bot_get_team_limit(); squad_member++ )
					{
						index = squad_member;
						if ( squad_member == active_squad_member )
							continue;

						if ( index_needed == slot )
							break;
					
						slot++;
					}

					name = level.wargame_client GetPrivatePlayerData( "privateMatchSquadMembers", index, "name" );
					head = level.wargame_client GetPrivatePlayerData( "privateMatchSquadMembers", index, "head" );
					body = level.wargame_client GetPrivatePlayerData( "privateMatchSquadMembers", index, "body" );
					helmet = level.wargame_client GetPrivatePlayerData( "privateMatchSquadMembers", index, "helmet" );

					bot = AddBot( name, head, body, helmet );
					if ( IsDefined( bot ) )
					{
						bot.pers[ "squadSlot" ] = index;
					}
				}
			}
			else
			{
				bot = AddBot( "", 0, 0, 0 );
			}
		}
		else if( ( GetDvar( "squad_match" ) == "1" ) )
		{
			if ( team == "axis" )
			{
				index = GetEnemySquadData( "squadHQ", "aiSquadMembers", squad_index );

				name = GetEnemySquadData( "squadMembers", index, "name" );
				head = GetEnemySquadData( "squadMembers", index, "head" );
				body = GetEnemySquadData( "squadMembers", index, "body" );
				helmet = GetEnemySquadData( "squadMembers", index, "helmet" );
				
				bot = AddBot( name, head, body, helmet );
				if ( IsDefined( bot ) )
				{
					bot.pers[ "squadSlot" ] = index;
				}
			}
			else
			{
				index = find_squad_member_index( level.squad_match_client, team );

				if ( index > -1 )	// no spare slots at the moment
				{
					name = level.squad_match_client GetRankedPlayerData( "squadMembers", index, "name" );
					head = level.squad_match_client GetRankedPlayerData( "squadMembers", index, "head" );
					body = level.squad_match_client GetRankedPlayerData( "squadMembers", index, "body" );
					helmet = level.squad_match_client GetRankedPlayerData( "squadMembers", index, "helmet" );
	
					bot = AddBot( name, head, body, helmet );
					if ( IsDefined( bot ) )
					{
						level.human_team_bot_added[ index ] = true;
						bot.pers[ "squadSlot" ] = index;
					}
				}
			}
		}
		else
		{
			bot = AddBot( "", 0, 0, 0 );
		}

 		if ( !IsDefined( bot ) )
 		{
 			if ( IsDefined( haltWhenFull ) && haltWhenFull )
 			{
				if ( IsDefined( notifyWhenDone ) )
					self notify( notifyWhenDone );
				
 				return;
 			}
 			
	 		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 1 );	
 			continue;
 		}
 		else
 		{
 			connecting = SpawnStruct();
 			connecting.bot = bot;
 			connecting.ready = false;
 			connecting.abort = false;
			connecting.index = squad_index;
 			connecting.difficulty = difficulty;
 			
 			connectingArray[connectingArray.size] = connecting;

			connecting.bot thread spawn_bot_latent( team, botCallback, connecting );
			
			squad_index++;
 		}
  	}

	// Wait for all the bots to complete their spawn process before returning
	connectedComplete = 0;
	function_wait_time = GetTime() + 60000;
	while ( (connectedComplete < connectingArray.size) && (GetTime() < function_wait_time) )
	{
		connectedComplete = 0;
		
		foreach ( connecting in connectingArray )
		{
			if ( connecting.ready || connecting.abort )
				connectedComplete++;
		}
		
		wait 0.05;
	}
	
	if ( IsDefined( notifyWhenDone ) )
		self notify( notifyWhenDone );
}

bot_gametype_chooses_team()
{
	if ( !level.teamBased ) 
		return true;
	
	if ( IsDefined(level.bots_gametype_handles_team_choice) && level.bots_gametype_handles_team_choice )
		return true;
	
	return false;
}

bot_gametype_chooses_class()
{
	return ( IsDefined(level.bots_gametype_handles_class_choice) && level.bots_gametype_handles_class_choice );
}

//========================================================
//					bot_think 
//========================================================
bot_think( )
{
	self notify( "bot_think" );
	self endon( "bot_think" );
	self endon( "disconnect" );
	
	while( !IsDefined( self.pers["team"] ) )
	{
		wait( 0.05 );
	}
	
	level.hasbots = true;
	
	if ( bot_gametype_chooses_team() )
		self.bot_team = self.pers["team"];
	
	team = self.bot_team;
	if ( !IsDefined( team ) )
		team = self.pers["team"];

	maps\mp\bots\_bots_ks::bot_killstreak_setup();
		
	self.entity_number = self GetEntityNumber();
		
	firstSpawn = false;
	
	if ( !isDefined( self.bot_spawned_before ) )
	{
		firstSpawn = true;
		self.bot_spawned_before = true;
		
		if ( !bot_gametype_chooses_team() )
		{
			self notify( "luinotifyserver", "team_select", bot_lui_convert_team_to_int(team) );
			
			wait( 0.5 );
			
			// if we are still on team spectator something is preventing us from joining the team we want to be on. Drop and try to reconnect again later.
			if ( self.pers["team"] == "spectator" ) 
			{
				self bot_drop();
				return;
			}
		}
	}

	while( true )
	{
		// Make sure we pick a difficulty if its set to "default"
		self bot_set_difficulty( self BotGetDifficulty() );
		
		// Balance personalities unless we are restricting them based on difficulty
		allowAdvPersonality = self BotGetDifficultySetting( "advancedPersonality" );
		if ( firstSpawn && IsDefined( allowAdvPersonality ) && allowAdvPersonality != 0 )
	 		self bot_balance_personality();

 		/#
 		self bot_set_personality_from_dev_dvar();
	 	#/
	 		
		self bot_assign_personality_functions();

 		if ( firstSpawn )
		{
 			self bot_set_loadout_class();
 			if ( !bot_gametype_chooses_class() )
				self notify( "luinotifyserver", "class_select", self.bot_class );
 			if ( self.health == 0 )
 				self waittill( "spawned_player" );	// Don't wait here if we have health (i.e. we've already spawned)
			if ( IsDefined( level.bot_funcs ) && IsDefined( level.bot_funcs["know_enemies_on_start"] ) )
				self thread [[ level.bot_funcs["know_enemies_on_start"] ]]();
			firstSpawn = false;
		}
				
		self bot_restart_think_threads();
		
		wait( 0.10 );
				
		self waittill( "death" );
		
		self respawn_watcher();
		
		self waittill( "spawned_player" );
	}
}

/#
bot_set_personality_from_dev_dvar()
{
	debug_personality = GetDvar( "bot_debugPersonality", "default" );
	 		
	if( debug_personality != "default" )
		self bot_set_personality( debug_personality );
}
#/

respawn_watcher()
{
	self endon( "started_spawnPlayer" );		// If for whatever reason spawnPlayer starts, then immediately end this
	
	// First wait till the bot is actually waiting to spawn
	while( !self.waitingToSpawn )
		wait(0.05);
	
	// Now that he is waiting to spawn, push the Respawn button if necessary
	if ( self maps\mp\gametypes\_playerlogic::needsButtonToRespawn() )
	{
		while( self.waitingToSpawn )
		{
			if ( self.sessionstate == "spectator" )
			{
				// Can attempt to spawn if the gamemode has unlimited lives or if the bot has lives remaining
				if ( GetDvarInt("numlives") == 0 || self.pers["lives"] > 0 )
					self BotPressButton( "use", 0.5 );
			}
			
			wait(1.0);
		}
	}
}


bot_get_rank_xp()
{
	if ( self bot_israndom() == false )
	{
		if ( !IsDefined(self.pers[ "rankxp" ]) )
			self.pers[ "rankxp" ] = 0;
		
		return self.pers[ "rankxp" ];
	}
	
	difficulty = self BotGetDifficulty();
	persName = "bot_rank_" + difficulty;
	
	if ( IsDefined(self.pers[persName]) && self.pers[persName] > 0 )
		return self.pers[persName];
	
	desiredRanks = bot_random_ranks_for_difficulty( difficulty );

	rank = desiredRanks[ "rank" ];
	prestige = desiredRanks[ "prestige" ];	
	
	minXP = maps\mp\gametypes\_rank::getRankInfoMinXP( rank );
	maxXP = minXP + maps\mp\gametypes\_rank::getRankInfoXPAmt( rank ) ;
	rankXP = RandomIntRange( minXP, maxXP + 1 );
	self.pers[persName] = rankXP;
	
	return rankXP;
}

bot_3d_sighting_model( associatedEnt )
{
	self thread bot_3d_sighting_model_thread( associatedEnt );
}

bot_3d_sighting_model_thread( associatedEnt )
{
	associatedEnt endon("disconnect");	
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while( 1 )
	{
		if ( IsAlive( self ) && !(self BotCanSeeEntity( associatedEnt )) && within_fov( self.origin, self.angles, associatedEnt.origin, self BotGetFovDot() ) )
			self BotGetImperfectEnemyInfo( associatedEnt, associatedEnt.origin );
		
		wait 0.1;
	}
}

bot_random_ranks_for_difficulty( difficulty )
{
	result = [];
	result["rank"] = 0;
	result["prestige"] = 0;
	
	if ( difficulty == "default" )
		return result;
	
	// Rank: 1 - 8, 10 - 38, 40 - 58, 60 (never set to N9 so there is no chance of jumping bracket by gained XP during the match)
	if ( !isDefined( level.bot_rnd_rank ) )
	{
		level.bot_rnd_rank = [];
		level.bot_rnd_rank["recruit"][0] = 	 0;
		level.bot_rnd_rank["recruit"][1] = 	 7;
		level.bot_rnd_rank["regular"][0] = 	 9;
		level.bot_rnd_rank["regular"][1] = 	37;
		level.bot_rnd_rank["hardened"][0] =	39;
		level.bot_rnd_rank["hardened"][1] = 57;
		level.bot_rnd_rank["veteran"][0] = 	59;
		level.bot_rnd_rank["veteran"][1] = 	59;
	}

	// Prestige: 2 - 9 only at veteran
	if ( !isDefined( level.bot_rnd_prestige ) )
	{
		level.bot_rnd_prestige = [];
		level.bot_rnd_prestige["recruit"][0] = 	0;
		level.bot_rnd_prestige["recruit"][1] = 	0;
		level.bot_rnd_prestige["regular"][0] = 	0;
		level.bot_rnd_prestige["regular"][1] = 	0;
		level.bot_rnd_prestige["hardened"][0] =	0;
		level.bot_rnd_prestige["hardened"][1] =	0;
		level.bot_rnd_prestige["veteran"][0] = 	0;
		level.bot_rnd_prestige["veteran"][1] = 	9;
	}

	if ( IsDefined( level.bot_rnd_rank[difficulty][0] ) && IsDefined( level.bot_rnd_rank[difficulty][1] ) )
	    result["rank"] = RandomIntRange( level.bot_rnd_rank[difficulty][0], level.bot_rnd_rank[difficulty][1] + 1 );

	if ( IsDefined( level.bot_rnd_prestige[difficulty][0] ) && IsDefined( level.bot_rnd_prestige[difficulty][1] ) )
	    result["prestige"] = RandomIntRange( level.bot_rnd_prestige[difficulty][0], level.bot_rnd_prestige[difficulty][1] + 1 );

	return result;
}

crate_can_use_always( crate )
{
	// Agents can only pickup boxes normally
	if ( IsAgent(self) && !IsDefined( crate.boxType ) )
		return false;

	return true;
}

//========================================================
//					get_human_player 
//========================================================
get_human_player()
{
	result = undefined;
	
	players = getEntArray( "player", "classname" );

	if ( IsDefined( players ) )
	{
		for( index = 0; index < players.size; index++ )
		{
			if( IsDefined( players[index] ) && IsDefined( players[index].connected ) && players[index].connected &&
			    !IsAI( players[index] ) && (!IsDefined( result ) || result.team == "spectator") )
			{
				result = players[index];
			}
		}
	}
	
	return result;
}

/#
get_all_humans()
{
	humans = [];
	
	foreach ( player in level.players )
	{
		if ( player.connected && !IsAI( player ) )
			humans = array_add( humans, player );
	}
	
	return humans;
}

spectators_exist()
{
	humans = get_all_humans();
	
	foreach( player in humans )
	{
		if ( player.team == "spectator" )
			return true;
	}
	
	return false;
}
#/

//========================================================
//					bot_damage_callback 
//========================================================
bot_damage_callback( eAttacker, iDamage, sMeansOfDeath, sWeapon, eInflictor, sHitLoc )
{
 	if( !IsDefined( self ) || !IsAlive( self ) )
 	{
 		return;
 	}
 
 	if( sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_SUICIDE" )
 	{
 		return;
 	}
 
 	if( iDamage <= 0 )
 	{
 		return;
 	}
 
 	if ( !IsDefined( eInflictor ) )
 	{
 		if ( !IsDefined( eAttacker ) )
 			return;
 		
 		eInflictor = eAttacker;
 	}
  
 	if ( IsDefined( eInflictor ) )
 	{
 		if ( level.teamBased )
 		{
 			if ( IsDefined( eInflictor.team ) && eInflictor.team == self.team )
 				return;
 			else if ( IsDefined( eAttacker ) && IsDefined( eAttacker.team ) && eAttacker.team == self.team )
 				return;
 		}
 
 		attacker_ent = bot_get_known_attacker( eAttacker, eInflictor );
 		if ( IsDefined(attacker_ent) )
 			self BotSetAttacker( attacker_ent );
 	}
}


//========================================================
//					on_bot_killed 
//========================================================
on_bot_killed( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, killId )
{
	self BotClearScriptEnemy();
	self BotClearScriptGoal();
	
	attacker_ent = bot_get_known_attacker( attacker, eInflictor );
	if ( !bot_is_fireteam_mode() && GetDvar( "squad_match" ) != "1" && GetDvar( "squad_vs_squad" ) != "1" && IsDefined(attacker_ent) && attacker_ent.classname == "script_vehicle" && IsDefined(attacker_ent.helitype) )
	{
		respawn_chance = self BotGetDifficultySetting("launcherRespawnChance");
		if ( RandomFloat(1.0) < respawn_chance )
			self.respawn_with_launcher = true;
	}
}


//========================================================
//					bot_should_do_killcam 
//========================================================
bot_should_do_killcam()
{
/#
	if ( GetDvar("scr_game_spectatetype") == "2" )
	{
		if ( spectators_exist() )
		{
			return false;
		}
	}
#/
	if ( bot_is_fireteam_mode() )
		return false;
	
	skip_killcam_chance = 0.0;
	bot_difficulty = self BotGetDifficulty();
	
	if ( bot_difficulty == "recruit" )
	{
		skip_killcam_chance = 0.1;
	}
	else if ( bot_difficulty == "regular" )
	{
		skip_killcam_chance = 0.4;
	}
	else if ( bot_difficulty == "hardened" )
	{
		skip_killcam_chance = 0.7;
	}   
	else if ( bot_difficulty == "veteran" )
	{
		skip_killcam_chance = 1.0;
	}
	
	return (RandomFloat(1.0) < (1.0-skip_killcam_chance));
}


//========================================================
//					bot_should_pickup_weapons 
//========================================================
bot_should_pickup_weapons()
{
	if ( self isJuggernaut() )
		return false;
	
	return true;
}


//========================================================
//					bot_restart_think_threads 
//========================================================
bot_restart_think_threads()
{
	self thread bot_think_watch_enemy();
	self thread bot_think_tactical_goals();
	self thread [[ level.bot_funcs["dropped_weapon_think"] ]]();
	self thread bot_think_level_actions();
	self thread bot_think_crate();
	self thread bot_think_crate_blocking_path();
	//self thread bot_think_revive();
	self thread bot_think_killstreak();
	self thread bot_think_watch_aerial_killstreak();
	self thread bot_think_gametype();
/#
	self thread bot_think_debug();
#/
}

/#
bot_think_debug()
{
	self notify( "bot_think_debug" );
	self endon(  "bot_think_debug" );
		
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while(1)
	{
		if ( IsDefined(level.bot_debug_force_path_location) )
		{
			self bot_disable_tactical_goals();
			self.ignoreall = true;
			self BotSetStance("stand");
			
			if ( !self BotHasScriptGoal() )
			{
				self BotSetScriptGoal(level.bot_debug_force_path_location,0,"tactical");
			}
			else
			{
				goal = self BotGetScriptGoal();
				if ( !bot_vectors_are_equal(goal, level.bot_debug_force_path_location) )
					self BotSetScriptGoal(level.bot_debug_force_path_location,0,"tactical");
			}
		}
		
		wait(0.05);
	}
}
#/

//========================================================
//					bot_think_watch_enemy 
//========================================================
bot_think_watch_enemy( bEndOnDeath )
{
	endMessage = "spawned_player";
	
	if( IsDefined(bEndOnDeath) && bEndOnDeath )
		endMessage = "death";
	
	self notify( "bot_think_watch_enemy" );
	self endon(  "bot_think_watch_enemy" );

	self endon( endMessage );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	// This function is for any logic that needs to be updated each frame regarding the enemy
	self.last_enemy_sight_time = GetTime();
	
	while( true )
	{
		if ( IsDefined( self.enemy ) )
		{
			if ( self BotCanSeeEntity( self.enemy ) )
			{
				self.last_enemy_sight_time = GetTime();
			}
		}
		
		wait(0.05);
	}
}

//========================================================
//					bot_think_dropped_weapons 
//========================================================
bot_think_seek_dropped_weapons()
{
	self notify( "bot_think_seek_dropped_weapons" );
	self endon(  "bot_think_seek_dropped_weapons" );
		
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	throwing_knife_name = "throwingknife_mp";
	throwing_knife_jugg_name = "throwingknifejugg_mp";

	while( true )
	{
		still_seeking_weapon = false;
		
		if ( self bot_out_of_ammo() && self [[level.bot_funcs["should_pickup_weapons"]]]() && !self bot_is_remote_or_linked() )
		{
			dropped_weapons = GetEntArray("dropped_weapon","targetname");
			dropped_weapons_sorted = get_array_of_closest(self.origin,dropped_weapons);
			if ( dropped_weapons_sorted.size > 0 )
			{
				dropped_weapon = dropped_weapons_sorted[0];
				self bot_seek_dropped_weapon( dropped_weapon );
			}
		}
		
		if ( !self bot_in_combat() && !self bot_is_remote_or_linked() && self BotGetDifficultySetting("strategyLevel") > 0 )
		{
			has_knife_normal = self HasWeapon( throwing_knife_name );
			has_knife_jugg = self HasWeapon( throwing_knife_jugg_name );
			
			knife_thrown = (has_knife_normal && self GetAmmoCount( throwing_knife_name ) == 0) || (has_knife_jugg && self GetAmmoCount( throwing_knife_jugg_name ) == 0);
			if ( knife_thrown )
			{
				if ( IsDefined(self.going_for_knife) )
				{
					wait(5.0);	// Already set a knife destination
					continue;
				}
				
				dropped_knives = GetEntArray("dropped_knife","targetname");
				dropped_knives_sorted = get_array_of_closest(self.origin,dropped_knives);
				foreach( knife in dropped_knives_sorted )
				{
					if ( !IsDefined(knife) )
					{
						// May have been deleted while we were waiting for the bot_queued_process below on the previous knife in the array
						continue;
					}
					
					if ( !IsDefined(knife.calculated_closest_point) )
					{
						result = bot_queued_process( "BotGetClosestNavigablePoint", ::func_bot_get_closest_navigable_point, knife.origin, 32, self );
						
						// since bot_queued_process waits, it's possible that the knife gets removed
						if ( IsDefined( knife ) )
						{
							knife.closest_point_on_grid = result;
							knife.calculated_closest_point = true;
						}
						else
						{
							continue;
						}
					}
					
					if ( IsDefined(knife.closest_point_on_grid) )
					{
						self.going_for_knife = true;
						self bot_seek_dropped_weapon( knife );
					}
				}
			}
			else if ( has_knife_normal || has_knife_jugg )
			{
				// Has a knife and has not thrown it yet
				self.going_for_knife = undefined;
			}
		}
		
		wait( RandomFloatRange(0.25, 0.75) );
	}
}
				
	
bot_seek_dropped_weapon( dropped_weapon )
{
	if ( self bot_has_tactical_goal( "seek_dropped_weapon", dropped_weapon ) == false )
	{
		action_thread = undefined;
		if ( dropped_weapon.targetname == "dropped_weapon" )
		{
			needs_to_pickup_weapon = true;
			heldweapons = self GetWeaponsListPrimaries();
			foreach ( held_weapon in heldweapons )
			{
				if ( dropped_weapon.model == GetWeaponModel(held_weapon) )
					needs_to_pickup_weapon = false;
			}
			
			if ( needs_to_pickup_weapon )
				action_thread = ::bot_pickup_weapon;
		}
		
		extra_params = SpawnStruct();
		extra_params.object = dropped_weapon;
		extra_params.script_goal_radius = 12;
		extra_params.should_abort = level.bot_funcs["dropped_weapon_cancel"];
		extra_params.action_thread = action_thread;
		self bot_new_tactical_goal( "seek_dropped_weapon", dropped_weapon.origin, 100, extra_params );
	}
}
		

bot_pickup_weapon( goal )
{
	self BotPressButton( "use", 2 );
	wait(2);	
}

should_stop_seeking_weapon( goal )
{
	// goal.object is the dropped weapon
	
	if ( !IsDefined( goal.object ) )
		return true;
	
	if ( goal.object.targetname == "dropped_weapon" )
	{
		if ( self bot_get_total_gun_ammo() > 0 )
			return true;
	}
	else if ( goal.object.targetname == "dropped_knife" )
	{
		if ( self bot_in_combat() )
		{
			self.going_for_knife = undefined;
			return true;
		}
	}
	
	return false;
}


//========================================================
//				bot_think_level_actions 
//========================================================
bot_think_level_actions( override_radius )
{
	self notify( "bot_think_level_actions" );
	self endon(  "bot_think_level_actions" );
		
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while( true )
	{
		waittill_notify_or_timeout( "calculate_new_level_targets", randomfloatrange( 2, 10 ) );
		
		if ( !IsDefined(level.level_specific_bot_targets) || level.level_specific_bot_targets.size == 0 )
			continue;
		
		if ( self bot_has_tactical_goal( "map_interactive_object" ) )
		    continue;
		
		if ( self bot_in_combat() || self bot_is_remote_or_linked() )
			continue;
			
		target_picked = undefined;
		foreach( level_target in level.level_specific_bot_targets )
		{
			if ( array_contains( level_target.high_priority_for, self ) )
			{
				target_picked = level_target;
				break;
			}
		}
		
		if ( !IsDefined(target_picked) )
		{
			if ( RandomInt(100) > 25 )
				continue;
			
			level_triggers_sorted = get_array_of_closest( self.origin, level.level_specific_bot_targets );
			max_dist = 256;
			if ( IsDefined(override_radius) )
				max_dist = override_radius;
			else if ( self BotGetScriptGoalType() == "hunt" && self BotPursuingScriptGoal() )
				max_dist = 512;
			
			// If bot is not hunting, or bot is hunting but has an enemy targeted,
			// then only use one of these if the bot is relatively close to it
			if ( DistanceSquared( self.origin, level_triggers_sorted[0].origin ) > max_dist*max_dist )
				continue;
			
			target_picked = level_triggers_sorted[0];
		}
		
		assert( IsDefined(target_picked) );
		
		should_melee_target = false;
		if ( target_picked.bot_interaction_type == "damage" )
		{
			should_melee_target = self bot_should_melee_level_damage_target( target_picked );
			if ( should_melee_target )
			{
				height_diff_to_node_0 = target_picked.origin[2] - (target_picked.bot_targets[0].origin[2] + 55);
				height_diff_to_node_1 = target_picked.origin[2] - (target_picked.bot_targets[1].origin[2] + 55);
				
				if ( (height_diff_to_node_0 > 55 && height_diff_to_node_1 > 55) )
				{
					if ( array_contains( target_picked.high_priority_for, self ) )
						target_picked.high_priority_for = array_remove(target_picked.high_priority_for, self);
					continue;
				}
			}
			
			weapon_class = WeaponClass( self GetCurrentWeapon() );
			if ( weapon_class == "spread" )
			{
				vec_to_node_0 = target_picked.bot_targets[0].origin - target_picked.origin;
				vec_to_node_1 = target_picked.bot_targets[1].origin - target_picked.origin;
				
				dist_to_node_0_sq = LengthSquared(vec_to_node_0);
				dist_to_node_1_sq = LengthSquared(vec_to_node_1);
				if ( (dist_to_node_0_sq > 150*150 && dist_to_node_1_sq > 150*150) )
				{
					if ( array_contains( target_picked.high_priority_for, self ) )
						target_picked.high_priority_for = array_remove(target_picked.high_priority_for, self);
					continue;
				}
			}
		}
		
		extra_params = SpawnStruct();
		extra_params.object = target_picked;
		
		if ( target_picked.bot_interaction_type == "damage" )
		{
			if ( should_melee_target )
				extra_params.should_abort = ::level_trigger_should_abort_melee;
			else
				extra_params.should_abort = ::level_trigger_should_abort_ranged;
		}
		
		if ( target_picked.bot_interaction_type == "use" )
		{
			extra_params.action_thread = ::use_use_trigger;
			extra_params.should_abort = ::level_trigger_should_abort;
			extra_params.script_goal_yaw = VectorToAngles(target_picked.origin - target_picked.bot_target.origin)[1];
			self bot_new_tactical_goal( "map_interactive_object", target_picked.bot_target.origin, 10, extra_params );
		}
		else if ( target_picked.bot_interaction_type == "damage" )
		{
			Assert(target_picked.bot_targets.size == 2);
			
			if ( should_melee_target )
			{
				extra_params.action_thread = ::melee_damage_trigger;
				extra_params.script_goal_radius = 20;
			}
			else
			{
				extra_params.action_thread = ::attack_damage_trigger;
				extra_params.script_goal_radius = 50;
			}
			
			node_target = undefined;
			
			path_dist_0 = bot_queued_process( "GetPathDistLevelAction", ::func_get_path_dist, self.origin, target_picked.bot_targets[0].origin );
			path_dist_1 = bot_queued_process( "GetPathDistLevelAction", ::func_get_path_dist, self.origin, target_picked.bot_targets[1].origin );
			
			if ( !IsDefined(target_picked) )
				continue;		// Could have gone undefined during the queued process wait
			
			if ( path_dist_0 <= 0 && path_dist_1 <= 0 )
				continue;
			
			if ( path_dist_0 > 0 )
			{
				Assert(IsDefined(target_picked.bot_targets[0]));
				if ( path_dist_1 < 0 || path_dist_0 <= path_dist_1 )
					node_target = target_picked.bot_targets[0];
			}
			
			if ( path_dist_1 > 0 )
			{
				Assert(IsDefined(target_picked.bot_targets[1]));
				if ( path_dist_0 < 0 || path_dist_1 <= path_dist_0 )
					node_target = target_picked.bot_targets[1];
			}
			
			Assert(IsDefined(node_target));
/#
			if ( !IsDefined(node_target) )
				continue;	// In non-ship, bail to avoid SRE spam
#/
			if ( !should_melee_target )
				self childthread monitor_node_visible( node_target );
			self bot_new_tactical_goal( "map_interactive_object", node_target.origin, 10, extra_params );
		}
	}
}

bot_should_melee_level_damage_target( level_target )
{
	Assert(level_target.bot_interaction_type == "damage" );
	
	current_weapon = self GetCurrentWeapon();
	should_melee_target = self bot_out_of_ammo() || self.hasRiotShieldEquipped || ( IsDefined( self.isJuggernautManiac ) && self.isJuggernautManiac == true )
		|| WeaponClass(current_weapon) == "grenade" || current_weapon == "iw6_knifeonly_mp" || current_weapon == "iw6_knifeonlyfast_mp";
/#
	should_melee_target = should_melee_target || (GetDvarInt("bot_SimulateNoAmmo") == 1);
#/
	return should_melee_target;
}

monitor_node_visible( node_target )
{
	self endon("goal");
	
	wait(0.1);	// give two frames for the tactical goal to start before we are allowed to notify "goal"
	
	while(1)
	{
		if ( WeaponClass( self GetCurrentWeapon() ) == "spread" )
		{
			if ( DistanceSquared(self.origin,node_target.origin) > 300 * 300 )
			{
				wait(0.05);
				continue;
			}
		}
		
		nearest_node_self = self GetNearestNode();
		if ( IsDefined(nearest_node_self) )
		{
			if ( NodesVisible( nearest_node_self, node_target ) )
			{
				if ( SightTracePassed( self.origin + (0,0,55), node_target.origin + (0,0,55), false, self ) )
					self notify("goal");
			}
		}
		
		wait(0.05);
	}
}

SCR_CONST_DAMAGE_TRIGGER_TIMEOUT_TIME = 5000;

attack_damage_trigger( goal )
{
	// goal.object is the trigger
	Assert(goal.object.bot_interaction_type == "damage" );
	
	if ( goal.object.origin[2] - self GetEye()[2] > 55 )
	{
		// Object is a lot higher than me, don't target it if I end up directly under it
		if ( Distance2DSquared(goal.object.origin, self.origin) < 15*15 )
			return;
	}
	
	self BotSetFlag("disable_movement", true);
	self look_at_damage_trigger( goal.object, 0.30 );
	self BotPressButton( "ads", 0.30 );
	wait(0.25);
	
	time_started = GetTime();
	while( IsDefined( goal.object ) && !IsDefined(goal.object.already_used) && GetTime() - time_started < SCR_CONST_DAMAGE_TRIGGER_TIMEOUT_TIME )
	{
		self look_at_damage_trigger( goal.object, 0.15 );
		self BotPressButton( "ads", 0.15 );
		self BotPressButton( "attack" );
		wait(0.1);
	}
	self BotSetFlag("disable_movement", false);
}

melee_damage_trigger( goal )
{
	// goal.object is the trigger
	Assert(goal.object.bot_interaction_type == "damage" );
	
	self BotSetFlag("disable_movement", true);
	self look_at_damage_trigger( goal.object, 0.30 );
	wait(0.25);
	
	time_started = GetTime();
	while( IsDefined( goal.object ) && !IsDefined(goal.object.already_used) && GetTime() - time_started < SCR_CONST_DAMAGE_TRIGGER_TIMEOUT_TIME )
	{
		self look_at_damage_trigger( goal.object, 0.15 );
		self BotPressButton( "melee" );
		wait(0.1);
	}
	self BotSetFlag("disable_movement", false);
}

look_at_damage_trigger( damage_trigger, time )
{
	look_origin = damage_trigger.origin;
	if ( Distance2DSquared( self.origin, look_origin ) < 10*10 )
		look_origin = ( look_origin[0], look_origin[1], self GetEye()[2] );	// Ensure we're still looking forward when really close to the object, so we don't try to look directly up or down
	self BotLookAtPoint( look_origin, time, "script_forced" );
}

use_use_trigger( goal )
{
	// goal.object is the trigger
	Assert(goal.object.bot_interaction_type == "use" );
	
	if ( IsAgent(self) )
	{
		self _enableUsability();
		goal.object EnablePlayerUse( self );
		wait(0.05);
	}
	
	time = goal.object.use_time;
	self BotPressButton( "use", time );
	wait( time );
	
	if ( IsAgent(self) )
	{
		self _disableUsability();
		if ( IsDefined(goal.object) )
			goal.object DisablePlayerUse( self );
	}
}

level_trigger_should_abort_melee( goal )
{
	// goal.object is the damage_trigger
	Assert( !IsDefined( goal.object ) || goal.object.bot_interaction_type == "damage" );
	
	if ( level_trigger_should_abort(goal) )
		return true;
	
	if ( !self bot_should_melee_level_damage_target(goal.object) )
		return true;
	
	return false;
}

level_trigger_should_abort_ranged( goal )
{
	// goal.object is the damage_trigger
	Assert( !IsDefined( goal.object ) || goal.object.bot_interaction_type == "damage" );
	
	if ( level_trigger_should_abort(goal) )
		return true;
	
	if ( self bot_should_melee_level_damage_target(goal.object) )
		return true;
	
	return false;
}

level_trigger_should_abort( goal )
{
	// goal.object is the trigger
	
	if ( !IsDefined( goal.object ) )
		return true;
	
	if ( IsDefined( goal.object.already_used ) )
		return true;

	if ( self bot_in_combat() )
		return true;

	return false;
}

crate_in_range( crate )
{
	if ( !IsDefined( crate.owner ) || (crate.owner != self) )
	{
		// I didn't call in this crate...
		// Ignore it if it is greater than 2048 distance away
		if ( DistanceSquared( self.origin, crate.origin ) > 2048 * 2048 )
			return false;
	}
	return true;
}

bot_crate_valid( crate )
{
	if ( !IsDefined( crate ) )
		return false;

	if ( !(self [[ level.bot_funcs["crate_can_use"] ]]( crate )) )
		return false;
	
	if ( !crate_landed_and_on_path_grid( crate ) )
		return false;
	
	// Ignore any crate that is a trap for the other team
	if ( level.teamBased && IsDefined( crate.bomb ) && IsDefined( crate.team ) && (crate.team == self.team) )
		return false;
	
	if ( !( self [[ level.bot_funcs["crate_in_range"] ]]( crate ) ) )
	{
		return false;
	}
	
	if ( IsDefined(crate.boxType) )
	{
		if ( IsDefined( level.boxSettings[crate.boxType] ) && ![[level.boxSettings[crate.boxType].canUseCallback]]() )
			return false;
		
		if ( IsDefined( crate.disabled_use_for ) && IsDefined(crate.disabled_use_for[self GetEntityNumber()]) && crate.disabled_use_for[self GetEntityNumber()] )
			return false;
/#				
		if ( !IsDefined(level.bot_can_use_box_by_type[crate.boxType]) )
		{
			AssertMsg( "Crate type <" + crate.boxType + "> is not supported for bots" );
			return false;
		}
#/				
		if ( !self [[level.bot_can_use_box_by_type[crate.boxType]]]( crate ) )
			return false;
	}
	
	return isDefined( crate );
}

crate_landed_and_on_path_grid( crate )
{
	Assert(IsDefined(crate));
	if ( !crate_has_landed(crate) )
		return false;
	
	Assert(IsDefined(crate));
	if ( !crate_is_on_path_grid(crate) )
		return false;
	
	return isDefined( crate );
}

crate_has_landed( crate )
{
	if ( IsDefined(crate.boxType) )
	{
		return ( GetTime() > (crate.birthtime + 1000) );
	}
	else
	{
		return (IsDefined(crate.droppingToGround) && !crate.droppingToGround);
	}
}

crate_is_on_path_grid( crate )
{
	Assert( crate_has_landed(crate) );	// This can't be called on a crate still in the air
	
	if ( !IsDefined(crate.on_path_grid) )
		crate_calculate_on_path_grid( crate );
	
	return (IsDefined(crate) && crate.on_path_grid);
}

node_within_use_radius_of_crate( node, crate )
{
	if ( IsDefined(crate.boxtype) && crate.boxtype == "scavenger_bag" )
	{
		return ( abs(node.origin[0] - crate.origin[0]) < 36 && abs(node.origin[0] - crate.origin[0]) < 36 && abs(node.origin[0] - crate.origin[0]) < 18 );
	}
	else
	{
		player_use_radius = GetDvarFloat( "player_useRadius" );
		dist_to_nearest_node_sq = DistanceSquared(crate.origin, node.origin + (0,0,40));	// Assume crouched at node
		return ( dist_to_nearest_node_sq <= (player_use_radius*player_use_radius) );
	}
}

crate_calculate_on_path_grid( crate )
{
	Assert(!IsDefined(crate.nearest_nodes));
	Assert(!IsDefined(crate.on_path_grid));
	
	crate thread crate_monitor_position();
	
	crate.on_path_grid = false;
	
	prev_forceDisconnectUntil = undefined;
	time_to_disconnect_until = undefined;
	if ( IsDefined(crate.forceDisconnectUntil) )
	{
		prev_forceDisconnectUntil = crate.forceDisconnectUntil;
		time_to_disconnect_until = GetTime() + 30000;
		crate.forceDisconnectUntil = time_to_disconnect_until;
		crate notify( "path_disconnect" );
	}
	
	wait(0.05);	// Wait for the disconnect to happen
	if ( !IsDefined( crate ) )
		return;

	nearest_nodes = crate_get_nearest_valid_nodes( crate );
	
	if ( !IsDefined( crate ) )
		return;
	
	if ( IsDefined(nearest_nodes) && nearest_nodes.size > 0 )
	{
		crate.nearest_nodes = nearest_nodes;
		crate.on_path_grid = true;
	}
	else
	{
		player_use_radius = GetDvarFloat( "player_useRadius" );
		closest_node = GetNodesInRadiusSorted( crate.origin, player_use_radius * 2, 0 )[0];
		crate_loc_on_ground = crate GetPointInBounds(0,0,-1);	//	get the point on the ground (where the pathnode origin would be)
		
		nearest_point = undefined;
		if ( IsDefined(crate.boxtype) && crate.boxtype == "scavenger_bag" )
		{
			if ( bot_point_is_on_pathgrid(crate.origin) )
				nearest_point = crate.origin;
		}
		else
		{
			nearest_point = BotGetClosestNavigablePoint(crate.origin, player_use_radius);
		}
		
		if ( IsDefined(closest_node) && !closest_node NodeIsDisconnected() && IsDefined(nearest_point) && abs(closest_node.origin[2] - crate_loc_on_ground[2]) < 30 )
		{
			crate.nearest_points = [nearest_point];
			crate.nearest_nodes = [closest_node];	// Needed for vis checks even though its not our destination
			crate.on_path_grid = true;
		}
	}
	
	if ( IsDefined(crate.forceDisconnectUntil) )
	{
		if ( crate.forceDisconnectUntil == time_to_disconnect_until )
			crate.forceDisconnectUntil = prev_forceDisconnectUntil;
	}
}

crate_get_nearest_valid_nodes( crate )
{
	nodes = GetNodesInRadiusSorted( crate.origin, 256, 0 );
	for ( i = nodes.size; i > 0; i-- )
		nodes[i] = nodes[i-1];
	nodes[0] = GetClosestNodeInSight( crate.origin );
	
	all_nodes = undefined;
	if ( IsDefined(crate.forceDisconnectUntil) )
		all_nodes = GetAllNodes();
	
	nodes_to_return = [];
	nodes_wanted = 1;
	if ( !IsDefined(crate.boxType) )
		nodes_wanted = 2;
	
	for ( i = 0; i < nodes.size; i++ )
	{
		node = nodes[i];
		if ( !IsDefined(node) || !IsDefined( crate ) )
			continue;
		
		if ( node NodeIsDisconnected() )
			continue;
		
		if ( !node_within_use_radius_of_crate( node, crate ) )
		{
			// If i > 0, then we know the nodes are sorted by distance, so if this node is not within the radius than none of the rest will be either
			if ( i == 0 )
				continue;
			else
				break;
		}
		
		wait(0.05);	// Wait a frame in between sight traces
		if ( !IsDefined( crate ) )
			break;
	
		if ( SightTracePassed( crate.origin, node.origin + (0,0,55), false, crate ) )
		{
			wait(0.05);	// Wait a frame in between path generations
			if ( !IsDefined( crate ) )
				break;
			
			if ( !IsDefined(crate.forceDisconnectUntil) )
			{
				// If this is not defined, then this crate doesn't disconnect paths and we don't need to check for that
				nodes_to_return[nodes_to_return.size] = node;
				if ( nodes_to_return.size == nodes_wanted )
					return nodes_to_return;
				else
					continue;
			}
			
			// Find another node relatively far away and test path to that node
			other_node_to_test = undefined;
			num_tested = 0;
			while( !IsDefined(other_node_to_test) && num_tested < 100 )
			{
				num_tested++;
				node_trying = Random(all_nodes);
				if ( DistanceSquared( node.origin, node_trying.origin ) > 500 * 500 )
					other_node_to_test = node_trying;
			}
			
			if ( IsDefined(other_node_to_test) )
			{
				path = bot_queued_process( "GetNodesOnPathCrate", ::func_get_nodes_on_path, node.origin, other_node_to_test.origin );
				if ( IsDefined(path) )
				{
					nodes_to_return[nodes_to_return.size] = node;
					if ( nodes_to_return.size == nodes_wanted )
						return nodes_to_return;
					else
						continue;
				}
			}		
		}
	}
	
	return undefined;
}

crate_get_bot_target( crate )
{
	if ( IsDefined(crate.nearest_points) )
		return crate.nearest_points[0];
	
	// ESU - 5/9/14 - If only one node exists it will cause an assert, since BotNodeScoreMultiple will return undefined.  So we just return that single node origin directly.
	if ( IsDefined(crate.nearest_nodes) )
	{
		if ( crate.nearest_nodes.size > 1 )
		{
			nodes_sorted = array_reverse(self BotNodeScoreMultiple( crate.nearest_nodes, "node_exposed" ));
			return random_weight_sorted(nodes_sorted).origin;
		}
		else
			return crate.nearest_nodes[0].origin;
	}
	
	AssertMsg("unreachable");
}

crate_get_bot_target_check_distance( crate, use_radius )
{
	crateStandPos = crate_get_bot_target( crate );
	
	testRadiusSq = use_radius * 0.9;
	testRadiusSq *= testRadiusSq;
	if ( DistanceSquared( crate.origin, crateStandPos ) <= testRadiusSq )
		return crateStandPos;
	else
		return undefined;
}

//========================================================
//					bot_think_crate 
//========================================================
bot_think_crate()
{
	self notify( "bot_think_crate" );
	self endon(  "bot_think_crate" );
		
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	player_use_radius = GetDvarFloat( "player_useRadius" );

	while( true )
	{
		wait_time = RandomFloatRange(2,4);
		self waittill_notify_or_timeout("new_crate_to_take", wait_time);
		
		if ( IsDefined( self.boxes ) && self.boxes.size == 0 )
			self.boxes = undefined;
		
		all_crates = level.carePackages;
		
		if ( !(self bot_in_combat()) && IsDefined(self.boxes) )
			all_crates = array_combine(all_crates, self.boxes);

		if ( IsDefined( level.bot_scavenger_bags ) && self _hasPerk( "specialty_scavenger" ) )
			all_crates = array_combine(all_crates, level.bot_scavenger_bags);
		
		// Early out if we didn't find any crates
		all_crates = array_removeUndefined( all_crates );
		if ( all_crates.size == 0 )
			continue;
		
		if ( bot_has_tactical_goal( "airdrop_crate" ) || self BotGetScriptGoalType() == "tactical" || self bot_is_remote_or_linked() )
		{
			continue;
		}
		
		all_valid_crates = [];
		foreach ( crate in all_crates )
		{
			if ( self bot_crate_valid( crate ) )
				all_valid_crates[all_valid_crates.size] = crate;
		}

		// bot_crate_valid() has a wait in it and crates could have been removed after being added to all_valid_crates
		all_valid_crates = array_remove_duplicates( all_valid_crates );
		
		// We didn't find any valid crates to take
		if ( all_valid_crates.size == 0 )
			continue;
		
		// Sort the array
		all_valid_crates = get_array_of_closest( self.origin, all_valid_crates );
		
		// First check for the closest crate the bot can see (ignoring current FOV)
		nearest_node_bot = self GetNearestNode();
		if ( !IsDefined(nearest_node_bot) )
			continue;
		
		ammoLow = self [[ level.bot_funcs["crate_low_ammo_check"] ]]();
		can_take_any_crate_on_radar = (ammoLow || (RandomInt(100) < 50)) && !(self isEMPed());
		
		crate_to_take = undefined;
		foreach ( crate in all_valid_crates )
		{
			player_has_claimed_crate = false;
			if ( ( !IsDefined(crate.owner) || crate.owner != self ) && !IsDefined(crate.boxType) )
			{
				human_allies_near_crate = [];
				foreach( player in level.players )
				{
					if ( !IsDefined( player.team ) )
						continue;
					if ( !IsAI(player) && level.teamBased && player.team == self.team )
					{
						if ( DistanceSquared(player.origin,crate.origin) < 700*700 )
							human_allies_near_crate[human_allies_near_crate.size] = player;
					}
				}
				
				if ( human_allies_near_crate.size > 0 )
				{
					// Check if the human ally has a line of sight to the crate
					nearest_node_human = human_allies_near_crate[0] GetNearestNode();
					if ( IsDefined(nearest_node_human) )
					{
						player_has_claimed_crate = false;
						foreach ( node in crate.nearest_nodes )
						{
							player_has_claimed_crate = player_has_claimed_crate | NodesVisible( nearest_node_human, node, true );
						}
					}
				}
			}
				
			if ( !player_has_claimed_crate )
			{
				bot_has_claimed_crate = IsDefined( crate.bots ) && IsDefined( crate.bots[self.team] ) && crate.bots[self.team] > 0;
				i_can_see_crate = false;
				foreach ( node in crate.nearest_nodes )
				{
					i_can_see_crate = i_can_see_crate | NodesVisible( nearest_node_bot, node, true );
				}
				
				// Either take a crate that I can see, or 50% chance to take the closest one pointed out on HUD to me that isnt claimed
				if ( i_can_see_crate || (can_take_any_crate_on_radar && !bot_has_claimed_crate) )
				{
					crate_to_take = crate;
					break;
				}
			}
		}
		
		if ( IsDefined( crate_to_take ) )
		{
			// Claim this crate
			if ( self [[ level.bot_funcs["crate_should_claim"] ]] () )
			{
				if ( !IsDefined(crate_to_take.boxType) )
				{
				    if ( !IsDefined( crate_to_take.bots ) )
					{
						crate_to_take.bots = [];
					}
					crate_to_take.bots[self.team] = 1;
				}
			}
			
			extra_params = SpawnStruct();
			extra_params.object = crate_to_take;
			extra_params.start_thread = ::watch_bot_died_during_crate;
			extra_params.should_abort = ::crate_picked_up;
			crate_dest = undefined;
			
			if ( IsDefined(crate_to_take.boxType) )
			{
				if ( IsDefined( crate_to_take.boxTouchOnly ) && crate_to_take.boxTouchOnly )
				{
					extra_params.script_goal_radius = 16;
					extra_params.action_thread = undefined;
					crate_dest = crate_to_take.origin;
				}
				else
				{
					extra_params.script_goal_radius = 50;
					extra_params.action_thread = ::use_box;
					
					vec_crate_to_nearest_node = self crate_get_bot_target_check_distance( crate_to_take, player_use_radius );
					if ( !IsDefined( vec_crate_to_nearest_node ) )
					{
						continue;
					}
					
					vec_crate_to_nearest_node -= crate_to_take.origin;
					scale = Length(vec_crate_to_nearest_node) * RandomFloat(1.0);
					crate_dest = (crate_to_take.origin + VectorNormalize(vec_crate_to_nearest_node) * scale) + (0,0,12);
				}
			}
			else
			{
				extra_params.action_thread = ::use_crate;
				extra_params.end_thread = ::stop_using_crate;
				crate_dest = self crate_get_bot_target_check_distance(crate_to_take, player_use_radius );
				if ( !IsDefined( crate_dest ) )
				{
					continue;
				}
				extra_params.script_goal_radius = (player_use_radius - Distance(crate_to_take.origin, crate_dest + (0,0,40)));
				crate_dest = crate_dest + (0,0,24);
			}

			if ( IsDefined(extra_params.script_goal_radius) )
				Assert(extra_params.script_goal_radius >= 0);

			crate_to_take notify( "path_disconnect" );
			wait 0.05;
			
			if ( !IsDefined( crate_to_take ) )
				continue;
			
			self bot_new_tactical_goal( "airdrop_crate", crate_dest, 30, extra_params );
		}
	}
}

bot_should_use_ballistic_vest_crate( crate )
{
	return true;
}

crate_should_claim()
{
	return true;
}
	
crate_low_ammo_check()
{
	return false;
}

bot_should_use_ammo_crate( crate )
{
	if ( self GetCurrentWeapon() == level.boxSettings[crate.boxType].minigunWeapon )
		return false;
	
	return true;
}

bot_pre_use_ammo_crate( crate )
{
	self SwitchToWeapon(self.secondaryWeapon);
	wait(1.0);
}

bot_post_use_ammo_crate( crate )
{
	self SwitchToWeapon("none");
	self.secondaryWeapon = self GetCurrentWeapon();		// Make sure we're only ever switching out our secondary from gun boxes, not our primary
}

bot_should_use_scavenger_bag( crate )
{
	if ( self bot_get_low_on_ammo( 0.66 ) )
	{
		// Scavenger bag must be in sight 
		nearest_node_bot = self GetNearestNode();
		if ( IsDefined( crate.nearest_nodes ) && IsDefined( crate.nearest_nodes[0] ) && IsDefined( nearest_node_bot ) )
		{
			if ( NodesVisible(nearest_node_bot, crate.nearest_nodes[0], true) )
			{
				if ( within_fov( self.origin, self.angles, crate.origin, self BotGetFovDot() ) )
				    return true;
			}
		}
	}
	
	return false;
}

bot_should_use_grenade_crate( crate )
{
	offhand_list = self GetWeaponsListOffhands();
	foreach( weapon in offhand_list )
	{
		if ( self GetWeaponAmmoStock(weapon) == 0 )
			return true;
	}
	
	return false;
}

bot_should_use_juicebox_crate( crate )
{
	return true;
}

crate_monitor_position()
{
	self notify("crate_monitor_position");
	self endon("crate_monitor_position");
	
	self endon("death");
	level endon("game_ended");
	
	while(1)
	{
		lastPos = self.origin;
		wait(0.5);
		if ( !IsAlive( self ) )
			return;
		if ( !bot_vectors_are_equal( self.origin, lastPos ) )
		{
			self.on_path_grid = undefined;
			self.nearest_nodes = undefined;
			self.nearest_points = undefined;
		}
	}
}

crate_wait_use()
{
}

crate_picked_up( goal )
{
	// goal.object is the crate
	
	if ( !IsDefined( goal.object ) )
		return true;

	return false;
}

use_crate( goal )
{
	// goal.object is the crate
	
	if ( IsAgent(self) )
	{
		self _enableUsability();
		goal.object EnablePlayerUse( self );
		wait(0.05);
	}

	self [[ level.bot_funcs["crate_wait_use"] ]]();
	
	// crate.owner doesn't have to exist.  But if it does, and this bot is the owner, use the shorter amount of time
	if ( IsDefined(goal.object.owner) && goal.object.owner == self )
	{
		time = level.crateOwnerUseTime / 1000 + 0.5;
	}
	else
	{
		time = level.crateNonOwnerUseTime / 1000 + 1.0;
	}
	
	self BotPressButton( "use", time );
	wait( time );

	if ( IsAgent(self) )
	{
		self _disableUsability();
		if ( IsDefined(goal.object) )
			goal.object DisablePlayerUse( self );
	}
	
	if( isDefined( goal.object ) )
	{
		if ( !IsDefined( goal.object.bots_used ) )
			goal.object.bots_used = [];
		
		goal.object.bots_used[goal.object.bots_used.size] = self;
	}
}

use_box( goal )
{
	// goal.object is the box
	
	if ( IsAgent(self) )
	{
		self _enableUsability();
		goal.object EnablePlayerUse( self );
		wait(0.05);
	}
	
	if ( isDefined( goal.object ) && isDefined( goal.object.boxType ) )
	{
		boxType = goal.object.boxType;
		if ( IsDefined(level.bot_pre_use_box_of_type[boxType]) )
			self [[ level.bot_pre_use_box_of_type[boxType] ]](goal.object);
		
		if ( IsDefined(goal.object) )	// Might have been picked up during a wait in the pre_use function
		{
			time = (level.boxSettings[goal.object.boxType].useTime / 1000) + 0.5;
			self BotPressButton( "use", time );
			wait( time );
			
			if ( IsDefined(level.bot_post_use_box_of_type[boxType]) )
				self [[ level.bot_post_use_box_of_type[boxType] ]](goal.object);
		}
	}
	
	if ( IsAgent(self) )
	{
		self _disableUsability();
		if ( IsDefined(goal.object) )
			goal.object DisablePlayerUse( self );
	}
}

watch_bot_died_during_crate( goal )
{
	// goal.object is the crate
	
	self thread bot_watch_for_death( goal.object );
}

stop_using_crate( goal )
{
	// goal.object is the crate
	
	if ( IsDefined( goal.object ) )
	{
		goal.object.bots[self.team] = 0;
	}
}

//========================================================
//				bot_watch_for_death 
//========================================================
bot_watch_for_death( object )
{
	object endon( "death" );
	object endon( "revived" );
	object endon( "disconnect" );

	level endon( "game_ended" );

	prev_team = self.team;
	self waittill_any( "death", "disconnect" );
	if ( IsDefined(object) )
	{
		object.bots[prev_team] = 0;
	}
}


//========================================================
//			bot_think_crate_blocking_path 
//========================================================
bot_think_crate_blocking_path()
{
	self notify( "bot_think_crate_blocking_path" );
	self endon(  "bot_think_crate_blocking_path" );

	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	radius = GetDvarFloat( "player_useRadius" );

	// ensure bots don't get stuck on crates
	while( true )
	{
		wait( 3 );

		if( self UseButtonPressed() )
		{
			continue;
		}

		if ( self isUsingRemote() )
			continue;
		
		crates = level.carePackages;

		for ( i = 0; i < crates.size; i++ )
		{
			crate = crates[i];
			if ( !IsDefined( crate ) )
				continue;

			if( DistanceSquared( self.origin, crate.origin ) < radius * radius )
			{
				if ( crate.owner == self )
				{
					self BotPressButton( "use", level.crateOwnerUseTime / 1000 + 0.5 );
				}
				else
				{
					self BotPressButton( "use", level.crateNonOwnerUseTime / 1000 + 0.5 );
				}
			}
		}
	}
}

//========================================================
//					bot_think_revive 
//========================================================
bot_think_revive()
{
	self notify( "bot_think_revive" );
	self endon(  "bot_think_revive" );

	self endon( "death" );
	self endon( "disconnect" );
	level endon ( "game_ended" );

	if( !level.teamBased )
	{
		return;
	}

	while( true )
	{
		waitTime = 2.0;
		revive_triggers = GetEntArray( "revive_trigger", "targetname" );
		
		if( revive_triggers.size > 0 )
			waitTime = 0.05;
		
		level waittill_notify_or_timeout( "player_last_stand", waitTime );
		
		if( !self bot_can_revive() )
		{
			continue;
		}

		revive_triggers = GetEntArray( "revive_trigger", "targetname" );
		
		// sort the players in last stand
		if( revive_triggers.size > 1 )
		{
			revive_triggers = SortByDistance( revive_triggers, self.origin );
			
			// put the agent's owner at the begining of the list
			if( IsDefined(self.owner) )
			{
				for( i = 0; i < revive_triggers.size; i++ )
				{			
					if( revive_triggers[i].owner != self.owner )
						continue;
					
					// agent's owner is already at the front of the array
					if( i == 0 )
						break;
					
					agent_owner_trigger = revive_triggers[i];
					revive_triggers[i] 	= revive_triggers[0];
					revive_triggers[0] 	= agent_owner_trigger;
					break;
				}	
			}
		}
		
		for( i = 0; i < revive_triggers.size; i++ )
		{
			revive_trigger = revive_triggers[i];
			player = revive_trigger.owner;

			if( !IsDefined( player) )
			{
				continue;
			}

			if( player == self )
			{
				continue;
			}

			if( !IsAlive( player ) )
			{
				continue;
			}

			if( player.team != self.team )
			{
				continue;
			}

			if( !IsDefined( player.inLastStand ) || !player.inLastStand )
			{
				continue;
			}

			if ( IsDefined( player.bots ) && IsDefined( player.bots[self.team] ) && player.bots[self.team] > 0 )
			{
				continue;
			}
			
			if( DistanceSquared( self.origin, player.origin ) < 2048 * 2048 )
			{
				extra_params = SpawnStruct();
				extra_params.object = revive_trigger;
				extra_params.script_goal_radius = 64;
				if ( IsDefined(self.last_revive_fail_time) && GetTime() - self.last_revive_fail_time < 1000 )
					extra_params.script_goal_radius = 32;				
				extra_params.start_thread = ::watch_bot_died_during_revive;
				extra_params.end_thread = ::stop_reviving;
				extra_params.should_abort = ::player_revived_or_dead;
				extra_params.action_thread = ::revive_player;
				self bot_new_tactical_goal( "revive", player.origin, 60, extra_params );
				break;
			}
		}
	}
}

watch_bot_died_during_revive( goal )
{
	// goal.object is the revive trigger of the player to revive
	
	self thread bot_watch_for_death( goal.object.owner );
}

stop_reviving( goal )
{
	// goal.object is the revive trigger of the player to revive
	
	if ( IsDefined( goal.object.owner ) )
	{
		goal.object.owner.bots[self.team] = 0;
	}
}

player_revived_or_dead( goal )
{
	// goal.object is the revive trigger of the player to revive
	
	if ( !IsDefined( goal.object.owner ) || goal.object.owner.health <= 0 )
		return true;
	
	if ( !IsDefined( goal.object.owner.inLastStand ) || !goal.object.owner.inLastStand )
		return true;

	return false;
}

revive_player( goal )
{
	// goal.object is the revive trigger of the player to revive
	
	if ( DistanceSquared(self.origin,goal.object.owner.origin) > 64 * 64 )
	{
		self.last_revive_fail_time = GetTime();
		return;	// player crawled away, try again
	}
	
	if ( IsAgent(self) )
	{
		self _enableUsability();
		goal.object EnablePlayerUse( self );
		wait(0.05);
	}
	
	prev_team = self.team;
	self BotPressButton( "use", level.lastStandUseTime / 1000 + 0.5 );
	
	wait( level.lastStandUseTime / 1000 + 1.5 );
	
	if ( IsDefined(goal.object.owner) )
		goal.object.bots[prev_team] = 0;
	
	if ( IsAgent(self) )
	{
		self _disableUsability();
		if ( IsDefined(goal.object) )
			goal.object DisablePlayerUse( self );
	}
}


//========================================================
//					bot_can_revive 
//========================================================
bot_can_revive()
{
	if ( IsDefined( self.laststand ) && self.laststand == true )
		return false;
	
	if ( self bot_has_tactical_goal( "revive" ) )
		return false;
	
	if ( self bot_is_remote_or_linked() )
		return false;
	
	// Bodyguards can always revive no matter what their goal type is
	if ( self bot_is_bodyguarding() )
		return true;
	
	goalType = self BotGetScriptGoalType();
	if ( goalType == "none" || goalType == "hunt" || goalType == "guard" )
		return true;
	
	return false;
}


//========================================================
//				revive_watch_for_finished 
//========================================================
revive_watch_for_finished( player )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "bad_path" );
	self endon( "goal" );

	player waittill_any( "death", "revived" );
	self notify( "bad_path" );
}

//========================================================
//			bot_know_enemies_on_start
//========================================================
bot_know_enemies_on_start()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	// Wait till grace period is over, then let this bot know where enemies are
	// (this is intended for the beginning of a match to get them seeking out enemies based on "knowledge" of the map start spots)
	if ( GetTime() > 15000 ) 
		return;
	
	while ( !gameHasStarted() || !gameFlag( "prematch_done" ) )
	{
		wait 0.05;
	}

	chosenEnemy = undefined;	
	chosenEnemyKnowSelf = undefined;

	for ( enemyIdx = 0; enemyIdx < level.players.size; enemyIdx++ )
	{
		otherPlayer = level.players[enemyIdx];
		if ( IsDefined( otherPlayer ) && IsDefined( self.team ) && IsDefined( otherPlayer.team ) && IsEnemyTeam( self.team, otherPlayer.team ) )
		{
			if ( !IsDefined( otherPlayer.bot_start_known_by_enemy ) )
				chosenEnemy = otherPlayer;
			
			if ( IsAI( otherPlayer ) && !IsDefined( otherPlayer.bot_start_know_enemy ) )
				chosenEnemyKnowSelf = otherPlayer;
		}
	}
	
	if ( IsDefined( chosenEnemy ) )
	{
		self.bot_start_know_enemy = true;
		chosenEnemy.bot_start_known_by_enemy = true;
		self GetEnemyInfo( chosenEnemy );		
	}
	
	if ( IsDefined( chosenEnemyKnowSelf ) )
	{
		chosenEnemyKnowSelf.bot_start_know_enemy = true;
		self.bot_start_known_by_enemy = true;
		chosenEnemyKnowSelf GetEnemyInfo( self );		
	}
}

//========================================================
//			bot_make_entity_sentient
//========================================================
bot_make_entity_sentient( team, expendable )
{
	if ( IsDefined(expendable) )
		return self MakeEntitySentient( team, expendable );
	else
		return self MakeEntitySentient( team );
}

//========================================================
//			bot_think_gametype
//========================================================
bot_think_gametype()
{
	self notify( "bot_think_gametype" );
	self endon(  "bot_think_gametype" );
	
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	gameFlagWait( "prematch_done" );
	
	self thread [[ level.bot_funcs["gametype_think"] ]]();
}

default_gametype_think()
{
	// do nothing
}


monitor_smoke_grenades()
{
	while(1)
	{
		level waittill("smoke", smoke_grenade, smoke_grenade_weaponName);
		
		if ( smoke_grenade_weaponName == "smoke_grenade_mp" || smoke_grenade_weaponName == "smoke_grenadejugg_mp" || smoke_grenade_weaponName == "odin_projectile_smoke_mp" )
			smoke_grenade thread handle_smoke( 9.0 );
		else if ( smoke_grenade_weaponName == "odin_projectile_large_rod_mp" )
			smoke_grenade thread handle_smoke( 2.5 );
	}
}

handle_smoke( final_wait_time )
{
	self waittill("explode", explosion_location );
	
	new_sight_clip_origin = spawn_tag_origin();
	new_sight_clip_origin show();
	new_sight_clip_origin.origin = explosion_location;
	next_wait_time = 0.8;
	
	wait(next_wait_time);
	next_wait_time = 0.5;
	smoke_sight_clip_collision_64_short = GetEnt( "smoke_grenade_sight_clip_64_short", "targetname" );
	if ( IsDefined(smoke_sight_clip_collision_64_short) )
	{
		new_sight_clip_origin CloneBrushmodelToScriptmodel( smoke_sight_clip_collision_64_short );
		//draw_entity_bounds( new_sight_clip_origin, next_wait_time, (1,0,0) );
	}
	
	wait(next_wait_time);
	next_wait_time = 0.6;
	smoke_sight_clip_collision_64_tall = GetEnt( "smoke_grenade_sight_clip_64_tall", "targetname" );
	if ( IsDefined(smoke_sight_clip_collision_64_tall) )
	{
		new_sight_clip_origin CloneBrushmodelToScriptmodel( smoke_sight_clip_collision_64_tall );
		//draw_entity_bounds( new_sight_clip_origin, next_wait_time, (1,0,0) );
	}

	wait(next_wait_time);
	next_wait_time = final_wait_time;
	smoke_sight_clip_collision_256 = GetEnt( "smoke_grenade_sight_clip_256", "targetname" );
	if ( IsDefined(smoke_sight_clip_collision_256) )
	{
		new_sight_clip_origin CloneBrushmodelToScriptmodel( smoke_sight_clip_collision_256 );
		//draw_entity_bounds( new_sight_clip_origin, next_wait_time, (1,0,0) );
	}
	
	wait(next_wait_time);
	new_sight_clip_origin delete();
}

bot_add_scavenger_bag( dropBag )
{
	added = false;
	
	dropBag.boxType = "scavenger_bag";
	dropBag.boxTouchOnly = true;
	
	if ( !IsDefined( level.bot_scavenger_bags ) )
		level.bot_scavenger_bags = [];

	// First fill any empty slot found	
	foreach( index, existingBag in level.bot_scavenger_bags )
	{
		if ( !IsDefined( existingBag ) )
		{
			added = true;
			level.bot_scavenger_bags[index] = dropBag;
			break;
		}
	}

	if ( !added )
		level.bot_scavenger_bags[level.bot_scavenger_bags.size] = dropBag;

	// Notify all scavengers that this bag is now available
	foreach( participant in level.participants )
	{
		if ( isAI( participant ) && participant _hasPerk( "specialty_scavenger" ) )
			participant notify( "new_crate_to_take" );
	}
}

//========================================================
//			bot_triggers
//========================================================
bot_triggers()
{
	bot_flag_set_triggers = GetEntArray("bot_flag_set", "targetname");
	foreach(trigger in bot_flag_set_triggers)
	{
		if(!IsDefined(trigger.script_noteworthy))
		{
			AssertMsg("Bot Flag trigger at " + trigger.origin + " is missing script_noteworthy flag name.");
			continue;
		}
		trigger thread bot_flag_trigger(trigger.script_noteworthy);
	}
}

bot_flag_trigger(flag_name)
{
	self endon("death");
	
	while(1)
	{
		self waittill("trigger", bot);
		
		if(IsAIGameParticipant(bot))
		{
			bot notify("flag_trigger_set_" + flag_name);
			bot BotSetFlag(flag_name, true);
			bot thread bot_flag_trigger_clear(flag_name);
		}
	}
}

bot_flag_trigger_clear(flag_name)
{
	self endon("flag_trigger_set_" + flag_name);
	self endon("death");
	self endon("disconnect");
	level endon("game_ended");
	
	waitframe();
	waittillframeend;
	
	self BotSetFlag(flag_name, false);
}
