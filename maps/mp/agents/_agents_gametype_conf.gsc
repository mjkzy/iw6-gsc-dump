#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;
#include maps\mp\bots\_bots_personality;

main()
{
	setup_callbacks();
}

setup_callbacks()
{
	level.agent_funcs["squadmate"]["gametype_update"] = ::agent_squadmember_conf_think;
	level.agent_funcs["player"]["think"] = ::agent_player_conf_think;
}

agent_player_conf_think()
{
	self thread maps\mp\bots\_bots_gametype_conf::bot_conf_think();
}

agent_squadmember_conf_think()
{
	// Returning true means the "think" was handled here.  "False" means use the default think
	
	if ( !IsDefined(self.tags_seen_by_owner) )
		self.tags_seen_by_owner = [];
	
	if ( !IsDefined(self.next_time_check_tags) )
		self.next_time_check_tags = GetTime() + 500;
		
	if ( GetTime() > self.next_time_check_tags )
	{
		self.next_time_check_tags = GetTime() + 500;
		
		current_player_fov = 0.78;	// approximation
		nearest_node_to_player = self.owner GetNearestNode();
		if ( IsDefined(nearest_node_to_player) )
		{
			new_visible_tags_to_player = self.owner maps\mp\bots\_bots_gametype_conf::bot_find_visible_tags( true, nearest_node_to_player, current_player_fov );
			self.tags_seen_by_owner = maps\mp\bots\_bots_gametype_conf::bot_combine_tag_seen_arrays( new_visible_tags_to_player, self.tags_seen_by_owner );
		}
	}
	
	self.tags_seen_by_owner = self maps\mp\bots\_bots_gametype_conf::bot_remove_invalid_tags( self.tags_seen_by_owner );
	best_tag = self maps\mp\bots\_bots_gametype_conf::bot_find_best_tag_from_array( self.tags_seen_by_owner, false );
	
	if ( IsDefined(best_tag) )
	{
		if ( !IsDefined(self.tag_getting) || DistanceSquared(best_tag.curorigin, self.tag_getting.curorigin) > 1 )
		{
			self.tag_getting = best_tag;
			self bot_defend_stop();
			self BotSetScriptGoal( self.tag_getting.curorigin, 0, "objective", undefined, level.bot_tag_obj_radius );
		}
		
		return true;
	}
	else if ( IsDefined(self.tag_getting) )
	{
		self BotClearScriptGoal();
		self.tag_getting = undefined;
	}
	
	return false;
}