#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;
#include maps\mp\bots\_bots_personality;

//=======================================================
//						main
//=======================================================
main()
{
	// This is called directly from native code on game startup after the _bots::main() is executed
	setup_callbacks();
	setup_bot_conf();
}


/#
empty_function_to_force_script_dev_compile() {}
#/


//=======================================================
//					setup_callbacks
//=======================================================
setup_callbacks()
{
	level.bot_funcs["gametype_think"] = ::bot_conf_think;
}


setup_bot_conf()
{
	// Needs to occur regardless of whether bots are enabled / in play, because it is used with the Squad Member
	level.bot_tag_obj_radius = 200;
	
	// If a tag is this distance above the bot's eyes, he will try to jump for it
	level.bot_tag_allowable_jump_height = 38;
	
/#
	thread bot_conf_debug();
#/
}


/#
SCR_CONST_DEBUG_SHOW_ALL_TAGS_NAME = "bot_DrawDebugShowAllTagsSeen";
bot_conf_debug()
{
	bot_waittill_bots_enabled();
	
	SetDevDvarIfUninitialized( SCR_CONST_DEBUG_SHOW_ALL_TAGS_NAME, "0" );
	SetDevDvarIfUninitialized( "bot_DrawDebugTagNearestNodes", "0" );
	while(1)
	{
		if ( GetDvar("bot_DrawDebugGametype") == "conf" )
		{
			if ( GetDvar(SCR_CONST_DEBUG_SHOW_ALL_TAGS_NAME) == "0" )
			{
				foreach( tag in level.dogtags )
				{
					if ( tag maps\mp\gametypes\_gameobjects::canInteractWith("allies") || tag maps\mp\gametypes\_gameobjects::canInteractWith("axis") )
					{
						bot_draw_circle( tag.curorigin, level.bot_tag_obj_radius, (1,0,0), false, 16 );
					}
				}
			}
			else
			{
				foreach( tag in level.dogtags )
				{
					if ( tag maps\mp\gametypes\_gameobjects::canInteractWith("allies") || tag maps\mp\gametypes\_gameobjects::canInteractWith("axis") )
					{
						bot_draw_circle( tag.curorigin, 10, (0,1,0), true, 16 );
					}
				}
				
				foreach( player in level.participants )
				{
					if ( !IsDefined( player.team ) )
						continue;

					if ( IsAlive(player) && IsDefined(player.tags_seen) )
					{
						foreach( tag in player.tags_seen )
						{
							if ( tag.tag maps\mp\gametypes\_gameobjects::canInteractWith(player.team) )
							{
								// Red line means its an enemy tag, blue line means an ally tag
								lineColor = undefined;
								if ( player.team != tag.tag.victim.team )
									lineColor = (1,0,0);
								else
									lineColor = (0,0,1);
								line( tag.tag.curorigin, player.origin + (0,0,20), lineColor, 1.0, true );
							}
						}
					}
				}	
			}
		}
		
		if ( GetDvar("bot_DrawDebugTagNearestNodes") == "1" )
		{
			foreach( tag in level.dogtags )
			{
				if ( tag maps\mp\gametypes\_gameobjects::canInteractWith("allies") || tag maps\mp\gametypes\_gameobjects::canInteractWith("axis") )
				{
					if ( IsDefined(tag.nearest_node) )
					{
						bot_draw_cylinder(tag.nearest_node.origin, 10, 10, 0.05, undefined, (0,0,1), true, 4);
						line(tag.curorigin, tag.nearest_node.origin, (0,0,1), 1.0, true);
					}
				}
			}
		}
		
		wait(0.05);
	}
}
#/

//=======================================================
//					bot_conf_think
//=======================================================
bot_conf_think()
{
	self notify( "bot_conf_think" );
	self endon(  "bot_conf_think" );

	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self.next_time_check_tags = GetTime() + 500;
	self.tags_seen = [];
	
	self childthread bot_watch_new_tags();
	
	if ( self.personality == "camper" )
	{
		self.conf_camper_camp_tags = false;
		if ( !IsDefined( self.conf_camping_tag ) )
			self.conf_camping_tag = false;
	}
	
	while ( true )
	{
		has_curr_tag = IsDefined(self.tag_getting);
		
		needs_to_sprint = false;
		if ( has_curr_tag && self BotHasScriptGoal() )
		{
			script_goal = self BotGetScriptGoal();
			if ( bot_vectors_are_equal( self.tag_getting.curorigin, script_goal ) )
			{
				// Script goal is this tag
				if ( self BotPursuingScriptGoal() )
				{
					needs_to_sprint = true;
				}
			}
			else if ( self bot_has_tactical_goal( "kill_tag" ) && self.tag_getting maps\mp\gametypes\_gameobjects::canInteractWith(self.team) )
			{
				// The bot has a goal to grab a tag, but yet his current script goal is not at the tag he's supposed to get
				// this can happen if the bot is heading toward a tag, and the tag's owner dies in his sight.  Now the tag has moved locations, but since he
				// died onscreen, the tag remains in the bot's visible list and so the bot doesn't know he has to switch destinations
				self.tag_getting = undefined;
				has_curr_tag = false;
			}
		}
		
		self BotSetFlag( "force_sprint", needs_to_sprint );
		
		self.tags_seen = self bot_remove_invalid_tags( self.tags_seen );
		best_tag = self bot_find_best_tag_from_array( self.tags_seen, true );
		
		desired_tag_exists = IsDefined(best_tag);
		if ( (has_curr_tag && !desired_tag_exists) || (!has_curr_tag && desired_tag_exists) || (has_curr_tag && desired_tag_exists && self.tag_getting != best_tag) )
		{
			// We're either setting self.tag_getting, clearing it, or changing it from one tag to a new one
			self.tag_getting = best_tag;
			self BotClearScriptGoal();
			self notify("stop_camping_tag");
			self clear_camper_data();
			self bot_abort_tactical_goal( "kill_tag" );
		}
		
		if ( IsDefined(self.tag_getting) )
		{
			self.conf_camping_tag = false;
			if ( self.personality == "camper" && self.conf_camper_camp_tags )
			{
				// Camp this tag instead of grabbing it
				self.conf_camping_tag = true;
				if ( self should_select_new_ambush_point() )
				{
					if ( find_ambush_node( self.tag_getting.curorigin, 1000 ) )
					{
						self childthread bot_camp_tag( self.tag_getting, "camp" );
					}
					else
					{
						self.conf_camping_tag = false;
					}
				}
			}

			if ( !self.conf_camping_tag )
			{
				if ( !self bot_has_tactical_goal( "kill_tag" ) )
				{
					extra_params = SpawnStruct();
					extra_params.script_goal_type = "objective";
					extra_params.objective_radius = level.bot_tag_obj_radius;
					self bot_new_tactical_goal( "kill_tag", self.tag_getting.curorigin, 25, extra_params );
				}
			}
		}
		
		did_something_else = false;
		if ( IsDefined( self.additional_tactical_logic_func ) )
		{
			did_something_else = self [[ self.additional_tactical_logic_func ]]();
		}
		
		if ( !IsDefined(self.tag_getting) )
		{
			if ( !did_something_else )
			{
				self [[ self.personality_update_function ]]();
			}
		}
		
		if ( GetTime() > self.next_time_check_tags )
		{
			self.next_time_check_tags = GetTime() + 500;
			new_visible_tags = self bot_find_visible_tags( true );
			self.tags_seen = bot_combine_tag_seen_arrays( new_visible_tags, self.tags_seen );
		}
		
/#
		if ( GetDvar("bot_DrawDebugGametype") == "conf" && GetDvar(SCR_CONST_DEBUG_SHOW_ALL_TAGS_NAME) == "0" )
		{
			if ( IsDefined(self.tag_getting) && self.health > 0 )
			{
				// Red line means the bot is camping the tag.  Otherwise the line colors don't mean anything, just slightly different shades to distinguish between teams
				color = (0.5,0,0.5);
				if ( self.team == "allies" )
					color = (1,0,1);
				if ( IsDefined(self.conf_camper_camp_tags) && self.conf_camper_camp_tags )
					color = (1,0,0);
				Line( self.origin + (0,0,40), self.tag_getting.curorigin + (0,0,10), color, 1.0, true, 1 );
			}
		}
#/
			
		wait(0.05);
	}
}

bot_check_tag_above_head( tag )
{
	if ( IsDefined(tag.on_path_grid) && tag.on_path_grid )
	{
		self_eye_pos = self.origin + (0,0,55);
		if ( Distance2DSquared(tag.curorigin, self_eye_pos) < 12 * 12 )
		{
			tag_height_over_bot_head = tag.curorigin[2] - self_eye_pos[2];
			if ( tag_height_over_bot_head > 0 )
			{
				if ( tag_height_over_bot_head < level.bot_tag_allowable_jump_height )
				{
					if ( !IsDefined(self.last_time_jumped_for_tag) )
						self.last_time_jumped_for_tag = 0;
					
					if ( GetTime() - self.last_time_jumped_for_tag > 3000 )
					{
						self.last_time_jumped_for_tag = GetTime();
						self thread bot_jump_for_tag();
					}
				}
				else
				{
					tag.on_path_grid = false;
					return true;
				}
			}
		}
	}
	
	return false;
}

bot_jump_for_tag()
{
	self endon("death");
	self endon("disconnect");
	
	self BotSetStance("stand");
	wait(1.0);
	self BotPressButton("jump");
	wait(1.0);
	self BotSetStance("none");
}

bot_watch_new_tags()
{
	while( 1 )
	{
		level waittill( "new_tag_spawned", newTag );
		// When a new tag spawns, look for them right away
		self.next_time_check_tags = -1;
		// If I was involved in this tag spawning (as victim or attacker), I automatically know about it
		if ( IsDefined( newTag ) )
		{
		    if ( (IsDefined( newTag.victim ) && newTag.victim == self) || (IsDefined( newTag.attacker ) && newTag.attacker == self) )
		    {
				if ( !IsDefined(newTag.on_path_grid) && !IsDefined(newTag.calculations_in_progress) )
				{
					thread calculate_tag_on_path_grid( newTag );
					waittill_tag_calculated_on_path_grid( newTag );
					
					if ( newTag.on_path_grid )
					{
						new_tag_struct = SpawnStruct();
						new_tag_struct.origin = newTag.curorigin;
						new_tag_struct.tag = newTag;
						new_tag_fake_array[0] = new_tag_struct;
						self.tags_seen = bot_combine_tag_seen_arrays( new_tag_fake_array, self.tags_seen );
					}
				}
		    }
		}
	}
}

bot_combine_tag_seen_arrays( new_tag_seen_array, old_tag_seen_array )
{
	new_array = old_tag_seen_array;
	foreach ( new_tag in new_tag_seen_array )
	{
		tag_already_exists_in_old_array = false;
		foreach ( old_tag in old_tag_seen_array )
		{
			if ( (new_tag.tag == old_tag.tag) && bot_vectors_are_equal( new_tag.origin, old_tag.origin ) )
			{
				tag_already_exists_in_old_array = true;
				break;
			}
		}
		
		if ( !tag_already_exists_in_old_array )
			new_array = array_add( new_array, new_tag );
	}
	
	return new_array;
}

bot_is_tag_visible( tag, nearest_node_self, fov_self )
{
	if ( !tag.calculated_nearest_node )
	{
		tag.nearest_node = GetClosestNodeInSight(tag.curorigin);
		tag.calculated_nearest_node = true;
	}
	
	if ( IsDefined(tag.calculations_in_progress) )
		return false;		// ignore this tag while another bot is calculating for it
	
	nearest_node_to_tag = tag.nearest_node;
	tag_first_time_ever_seen = !IsDefined(tag.on_path_grid);
	if ( IsDefined( nearest_node_to_tag ) && (tag_first_time_ever_seen || tag.on_path_grid) )
    {
		node_visible = (nearest_node_to_tag == nearest_node_self) || NodesVisible( nearest_node_to_tag, nearest_node_self, true );
		if ( node_visible )
		{
			node_within_fov = within_fov( self.origin, self.angles, tag.curorigin, fov_self );
			if ( node_within_fov )
			{
				if ( tag_first_time_ever_seen )
				{
					thread calculate_tag_on_path_grid( tag );
					waittill_tag_calculated_on_path_grid( tag );
					if ( !tag.on_path_grid )
						return false;		// Subsequent checks will just return immediately at the top since this is now defined
				}
				
				return true;
			}
		}
    }
	return false;
}

bot_find_visible_tags( require_los, optional_nearest_node_self, optional_fov_self )
{
	nearest_node_self = undefined;
	if ( IsDefined(optional_nearest_node_self) )
		nearest_node_self = optional_nearest_node_self;
	else
		nearest_node_self = self GetNearestNode();
	
	fov_self = undefined;
	if ( IsDefined(optional_fov_self) )
		fov_self = optional_fov_self;
	else
		fov_self = self BotGetFovDot();
	
	visible_tags = [];
	
	if ( IsDefined(nearest_node_self) )
	{
		foreach( tag in level.dogtags )
		{
			if ( tag maps\mp\gametypes\_gameobjects::canInteractWith(self.team) )
			{
				add_tag = false;
				if ( !require_los )
				{
					if ( !IsDefined(tag.calculations_in_progress) )	// if the tag is still being calculated, then ignore it
					{
						if ( !IsDefined(tag.on_path_grid) )
						{
							level thread calculate_tag_on_path_grid( tag );
							waittill_tag_calculated_on_path_grid( tag );
						}
						
						add_tag = (DistanceSquared(self.origin, tag.curorigin) < 1000 * 1000) && tag.on_path_grid;
					}
				}
				else if ( bot_is_tag_visible( tag, nearest_node_self, fov_self ) )
				{
					add_tag = true;
				}
				
				if ( add_tag )
				{
					new_tag_struct = SpawnStruct();
					new_tag_struct.origin = tag.curorigin;
					new_tag_struct.tag = tag;
					visible_tags = array_add( visible_tags, new_tag_struct );
				}
			}
		}
	}
	
	return visible_tags;
}

calculate_tag_on_path_grid( tag )
{
	tag endon("reset");
	
	tag.calculations_in_progress = true;
	tag.on_path_grid = bot_point_is_on_pathgrid(tag.curorigin, undefined, level.bot_tag_allowable_jump_height + 55);
	tag.calculations_in_progress = undefined;
}

waittill_tag_calculated_on_path_grid(tag)
{
	while( !IsDefined(tag.on_path_grid) )
		wait(0.05);
}

bot_find_best_tag_from_array( tag_array, check_allies_getting_tag )
{
	best_tag = undefined;
	if ( tag_array.size > 0 )
	{
		// find best tag
		best_tag_dist_sq = 99999 * 99999;
		foreach( tag_struct in tag_array )
		{
			num_allies_getting_tag = self get_num_allies_getting_tag( tag_struct.tag );
			if ( !check_allies_getting_tag || num_allies_getting_tag < 2 )
			{
				dist_self_to_tag_sq = DistanceSquared( tag_struct.tag.curorigin, self.origin );
				if ( dist_self_to_tag_sq < best_tag_dist_sq )
				{
					best_tag = tag_struct.tag;
					best_tag_dist_sq = dist_self_to_tag_sq;
				}
			}
		}
	}
	
	return best_tag;
}

bot_remove_invalid_tags( tags )
{
	valid_tags = [];
	foreach ( tag_struct in tags )
	{
		// Need to check if the tag can still be interacted with and if it is in the same place as where we originally saw it
		// This is because the tags are reused in the game, so this is to check if the tag has already been picked up, or if the player whose tag it is
		// died again in a different spot, moving the tag to that location
		if ( tag_struct.tag maps\mp\gametypes\_gameobjects::canInteractWith(self.team) && bot_vectors_are_equal( tag_struct.tag.curorigin, tag_struct.origin ) )
		{
			if ( !self bot_check_tag_above_head( tag_struct.tag ) && tag_struct.tag.on_path_grid )
				valid_tags = array_add( valid_tags, tag_struct );
		}
	}
	
	return valid_tags;
}

get_num_allies_getting_tag( tag )
{
	num = 0;
	foreach( player in level.participants )
	{
		if ( !IsDefined( player.team ) )
			continue;

		if ( player.team == self.team && player != self )
		{
			if ( IsAI( player ) )
			{
				if ( IsDefined(player.tag_getting) && player.tag_getting == tag )
					num++;
			}
			else
			{
				// If player is within 400 distance from a tag, consider him to be going for it
				if ( DistanceSquared( player.origin, tag.curorigin ) < 400 * 400 )
					num++;
			}
		}
	}
	
	return num;
}

bot_camp_tag( tag, goal_type, optional_endon )
{
	self notify("bot_camp_tag");
	self endon("bot_camp_tag");
	self endon("stop_camping_tag");
	if ( IsDefined(optional_endon) )
		self endon(optional_endon);
	
	self BotSetScriptGoalNode( self.node_ambushing_from, goal_type, self.ambush_yaw );
	result = self bot_waittill_goal_or_fail();
	
	if ( result == "goal" )
	{
		nearest_node_to_tag = tag.nearest_node;
		if ( IsDefined( nearest_node_to_tag ) )
		{
			nodes_to_watch = FindEntrances( self.origin );
			nodes_to_watch = array_add( nodes_to_watch, nearest_node_to_tag );
			self childthread bot_watch_nodes( nodes_to_watch );
		}
	}
}