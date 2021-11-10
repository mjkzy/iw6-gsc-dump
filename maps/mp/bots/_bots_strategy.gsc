// Common strategy functions for bots

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\bots\_bots_util;

/* 
=============
///ScriptDocBegin
"Name: bot_defend_get_random_entrance_point_for_current_area()"
"Summary: Gets a random entrance point for the bot's current defend area, using self.cur_defend_stance"
"Example: entrance_point = self bot_defend_get_random_entrance_point_for_current_area();"
///ScriptDocEnd
============
 */
bot_defend_get_random_entrance_point_for_current_area()
{
	all_cached_entrances = self bot_defend_get_precalc_entrances_for_current_area( self.cur_defend_stance );
	
	if ( IsDefined(all_cached_entrances) && all_cached_entrances.size > 0 )
	{
		return random(all_cached_entrances).origin;
	}
	
	return undefined;
}

/* 
=============
///ScriptDocBegin
"Name: bot_defend_get_precalc_entrances_for_current_area( <stance> )"
"Summary: Gets entrance points for the bot's current defend area, with the given stance"
"MandatoryArg: <stance> : "stand", "crouch", or "prone" "
"Example: all_cached_entrances = self bot_defend_get_precalc_entrances_for_current_area( self.cur_defend_stance );"
///ScriptDocEnd
============
 */
bot_defend_get_precalc_entrances_for_current_area( stance )
{
	if ( IsDefined( self.defend_entrance_index ) )
		return bot_get_entrances_for_stance_and_index(stance,self.defend_entrance_index);
	
	return [];
}

bot_setup_bombzone_bottargets()
{
	wait(1.0);		// Wait for Path_AutoDisconnectPaths to run
	
	bot_setup_bot_targets(level.bombZones);
	level.bot_set_bombzone_bottargets = true;
}

bot_setup_radio_bottargets()
{
	bot_setup_bot_targets(level.radios);
}

bot_setup_bot_targets(array)
{
	foreach ( element in array )
	{
		if ( !IsDefined( element.botTargets ) )
		{
			element.botTargets = [];
			nodes_in_trigger = GetNodesInTrigger( element.trigger );
			foreach( node in nodes_in_trigger )
			{
				if ( !node NodeIsDisconnected() )
					element.botTargets = array_add(element.botTargets, node);
			}
		}
	}
}

/* 
=============
///ScriptDocBegin
"Name: bot_get_ambush_trap_item( <purposePriority1>, <purposePriority1>, <purposePriority3> )"
"Summary: Returns array of options with "item_action" = "lethal" or "tactical" if bot has appropriate trap item in hand"
"CallOn: A bot player"
"MandatoryArg: <purposePriority1> : one of "trap_directional", "trap", or "c4"
"OptionalArg: <purposePriority2> : one of "trap_directional", "trap", or "c4"
"OptionalArg: <purposePriority3> : one of "trap_directional", "trap", or "c4"
"Example: trap_item = self bot_get_ambush_trap_item();"
///ScriptDocEnd
============
 */
bot_get_ambush_trap_item( purposePriority1, purposePriority2, purposePriority3 )
{
	result = [];
	
	purpose_priority = [];
	purpose_priority[purpose_priority.size] = purposePriority1;
	if ( IsDefined( purposePriority2 ) )
		purpose_priority[purpose_priority.size] = purposePriority2;
	if ( IsDefined( purposePriority2 ) )
		purpose_priority[purpose_priority.size] = purposePriority3;
	
	foreach ( purpose in purpose_priority )
	{
		result["purpose"] = purpose;
		result["item_action"] = self bot_get_grenade_for_purpose( purpose );
		if ( IsDefined( result["item_action"] ) )
		    return result;
	}
}

/* 
=============
///ScriptDocBegin
"Name: bot_set_ambush_trap( <trap_item>, <ambush_entrances>, <ambush_node>, <ambush_yaw>, <trap_node> )"
"Summary: Instructs the bot to place some hardware to protect a location. Returns true if goal was set in an attempt to set the trap."
"CallOn: A bot player"
"MandatoryArg: <trap_item> : Result of a previous call to self bot_get_ambush_trap_item()"
"MandatoryArg: <ambush_entrances> : The player to protect"
"MandatoryArg: <ambush_node> : The allowable radius around the player"
"OptionalArg: <ambush_yaw> : The direction the bot will be ambushing"
"OptionalArg: <trap_node> : If you already know where you want to place it"
"Example: self bot_set_optional_ambush_trap( self.ambush_entrances, self.node_ambushing_from, self.ambush_yaw );"
///ScriptDocEnd
============
 */
bot_set_ambush_trap( trap_item, ambush_entrances, ambush_node, ambush_yaw, trap_node )
{
	self notify("bot_set_ambush_trap");
	self endon("bot_set_ambush_trap");
			   
	if ( !isDefined( trap_item ) )
		return false;
	
	chosen_entrance = undefined;
	
	if ( !IsDefined( trap_node ) && isDefined( ambush_entrances ) && ambush_entrances.size > 0 )
	{		
		if ( !isDefined( ambush_node ) )
			return false;

		choose_set = [];

		fwd = undefined;
		if ( IsDefined( ambush_yaw ) )
			fwd = AnglesToForward( (0, ambush_yaw, 0) );

		foreach( entrance in ambush_entrances )
		{
			// If ambush_yaw is defined only choose entrances that are not right next to ambushing location and optionally not out in front of where we are facing
			if ( !isDefined( fwd ) )
			{
				choose_set[choose_set.size] = entrance;
			}
			else if ( DistanceSquared( entrance.origin, ambush_node.origin ) > 300*300 )			
			{
				if ( VectorDot( fwd, VectorNormalize( entrance.origin - ambush_node.origin ) ) < 0.4 )
				{
					choose_set[choose_set.size] = entrance;
				}
			}
		}

		if ( choose_set.size > 0 )
		{
			chosen_entrance = Random(choose_set);
			trap_choices = GetNodesInRadius( chosen_entrance.origin, 300, 50 );
			
			// Remove any nodes that are an ambush destination
			tempChoices = [];
			foreach( node in trap_choices )
			{
				if ( !IsDefined( node.bot_ambush_end ) )
					tempChoices[tempChoices.size] = node;
			}
			trap_choices = tempChoices;
			
			trap_node = self BotNodePick( trap_choices, min( trap_choices.size, 3 ), "node_trap", ambush_node, chosen_entrance );
		}
	}
	
	if ( isDefined( trap_node ) )
	{
		yaw = undefined;
		if ( trap_item["purpose"] == "trap_directional" && isDefined( chosen_entrance ) )
		{
			placeAngles = VectorToAngles( chosen_entrance.origin - trap_node.origin );
			yaw = placeAngles[1];
		}
		
		if ( (self BotHasScriptGoal()) && (self BotGetScriptGoalType() != "critical") && (self BotGetScriptGoalType() != "tactical") )
			self BotClearScriptGoal();
		
		goal_succeeded = self BotSetScriptGoalNode( trap_node, "guard", yaw );
		
		if ( goal_succeeded )
		{
			result = self bot_waittill_goal_or_fail();

			if ( result == "goal" )
			{
				self thread bot_force_stance_for_time( "stand", 5.0 );
				
				if ( !IsDefined( self.enemy ) || (false == (self BotCanSeeEntity( self.enemy ))) )
				{
					if ( IsDefined( yaw ) )
						self BotThrowGrenade( chosen_entrance.origin, trap_item["item_action"] );
					else
						self BotThrowGrenade( self.origin + (AnglesToForward(self.angles) * 50), trap_item["item_action"] );
					self.ambush_trap_ent = undefined;
					self thread bot_set_ambush_trap_wait_fire( "grenade_fire" );
					self thread bot_set_ambush_trap_wait_fire( "missile_fire" );
					timeToWait = 3.0;
					if ( trap_item["purpose"] == "tacticalinsertion" )
						timeToWait = 6.0;
					self waittill_any_timeout( timeToWait, "missile_fire", "grenade_fire" );
					wait 0.05;
					self notify( "ambush_trap_ent" );
					if ( IsDefined( self.ambush_trap_ent ) && trap_item["purpose"] == "c4" )
						self thread bot_watch_manual_detonate( self.ambush_trap_ent, trap_item["item_action"], 300 );
					self.ambush_trap_ent = undefined;
					wait RandomFloat( 0.25 );
					self BotSetStance( "none" );
				}
			}

			return true;
		}
	}
	
	return false;
}

bot_set_ambush_trap_wait_fire( waitingfor )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "bot_set_ambush_trap" );
	self endon( "ambush_trap_ent" );
	level endon( "game_ended" );

	self waittill( waitingFor, ent );
	
	self.ambush_trap_ent = ent;
}

/* 
=============
///ScriptDocBegin
"Name: bot_watch_manual_detonate( <grenade>, <item_action>, <range> )"
"Summary: If at any time we become aware of an enemy within range of this grenade, detonate it"
"CallOn: A bot player"
"MandatoryArg: <grenade> : The grenade ent"
"MandatoryArg: <item_action> : The BotThrowGrenade type to detonate "lethal" or "tactical" "
"MandatoryArg: <range> : The maximum range of detonation "
"Example: self thread bot_watch_manual_detonate( grenade, "lethal", 300 );"
///ScriptDocEnd
============
 */
bot_watch_manual_detonate( grenade, item_action, range )
{
	self endon( "death" );
	self endon( "disconnect" );	
	grenade endon( "death" );
	level endon( "game_ended" );

	rangeSq = range * range;

	while( 1 ) 
	{
		// Make sure we are out of range first
		if ( IsDefined( grenade.origin ) && DistanceSquared( self.origin, grenade.origin ) > rangeSq )
		{
			// If we see an enemy, see them on radar, hear of, or in any way know there is an enemy within range, detonate
			closestEnemySq = self GetClosestEnemySqDist( grenade.origin, 1.0 );
			if ( closestEnemySq < rangeSq )
			{
				self BotPressButton( item_action );
				return;
			}
		}

		wait RandomFloatRange( 0.25, 1.0 );
	}
}

/* 
=============
///ScriptDocBegin
"Name: bot_capture_point( <point>, <radius>, <optional_params> )"
"Summary: Instructs the bot to capture the point while staying within the radius"
"CallOn: A bot player"
"MandatoryArg: <point> : The point to capture"
"MandatoryArg: <radius> : The allowable radius around the point"
"OptionalArg: <optional_params> : For valid options, see bot_defend_think()
"Example: self bot_capture_point(flag.origin, 250);"
///ScriptDocEnd
============
 */
bot_capture_point( point, radius, optional_params )
{
	self thread bot_defend_think( point, radius, "capture", optional_params );
}

/* 
=============
///ScriptDocBegin
"Name: bot_capture_zone( <point>, <nodes>, <capture_trigger>, <optional_params> )"
"Summary: Instructs the bot to capture an area by sticking to a given set of points"
"CallOn: A bot player"
"MandatoryArg: <point> : The point to capture"
"MandatoryArg: <nodes> : The array of valid nodes to use"
"MandatoryArg: <capture_trigger> : The trigger to stay in
"OptionalArg: <optional_params> : For valid options, see bot_defend_think()
"Example: self bot_capture_zone( flag.origin, flag.nodes, flag, "flag" + flag.script_label );"
///ScriptDocEnd
============
 */
bot_capture_zone( point, nodes, capture_trigger, optional_params )
{
	Assert( IsDefined(nodes) && nodes.size > 0 );
	
/#
	if ( !IsDefined(nodes) || nodes.size == 0 )
		return;	// In non-ship, stop the defense to avoid SRE spam
#/
	
	optional_params["capture_trigger"] = capture_trigger;
	self thread bot_defend_think( point, nodes, "capture_zone", optional_params );
}

/* 
=============
///ScriptDocBegin
"Name: bot_protect_point( <point>, <radius>, <optional_params> )"
"Summary: Instructs the bot to protect the point while staying within the radius"
"CallOn: A bot player"
"MandatoryArg: <point> : The point to protect"
"MandatoryArg: <radius> : The allowable radius around the point"
"OptionalArg: <optional_params> : For valid options, see bot_defend_think()
"Example: self bot_protect_point(flag.origin, 250);"
///ScriptDocEnd
============
 */
bot_protect_point( point, radius, optional_params )
{
	if( !IsDefined(optional_params) || !IsDefined(optional_params["min_goal_time"]) )
		optional_params["min_goal_time"] = 12;
	
	if( !IsDefined(optional_params) || !IsDefined(optional_params["max_goal_time"]) )
		optional_params["max_goal_time"] = 18;
	
	self thread bot_defend_think( point, radius, "protect", optional_params );
}


/* 
=============
///ScriptDocBegin
"Name: bot_patrol_area( <point>, <radius>, <optional_params> )"
"Summary: Instructs the bot to patrol within a radius around a point"
"CallOn: A bot player"
"MandatoryArg: <point> : The point around which to patrol"
"MandatoryArg: <radius> : The allowable radius around the point"
"OptionalArg: <optional_params> : For valid options, see bot_defend_think()
"Example: self bot_patrol_area(flag.origin, 1000);"
///ScriptDocEnd
============
 */
bot_patrol_area( point, radius, optional_params )
{
	if( !IsDefined(optional_params) || !IsDefined(optional_params["min_goal_time"]) )
		optional_params["min_goal_time"] = 0.00;
	
	if( !IsDefined(optional_params) || !IsDefined(optional_params["max_goal_time"]) )
		optional_params["max_goal_time"] = 0.01;
	
	self thread bot_defend_think( point, radius, "patrol", optional_params );
}


/* 
=============
///ScriptDocBegin
"Name: bot_guard_player( <player>, <radius>, <optional_params> )"
"Summary: Instructs the bot to guard the player while staying within the radius"
"CallOn: A bot player"
"MandatoryArg: <player> : The player to guard"
"MandatoryArg: <radius> : The allowable radius around the player"
"OptionalArg: <optional_params> : For valid options, see bot_defend_think()
"Example: self bot_guard_player( level.bomb_carrier, 400 );"
///ScriptDocEnd
============
 */
bot_guard_player( player, radius, optional_params )
{
	if( !IsDefined(optional_params) || !IsDefined(optional_params["min_goal_time"]) )
		optional_params["min_goal_time"] = 15;
	
	if( !IsDefined(optional_params) || !IsDefined(optional_params["max_goal_time"]) )
		optional_params["max_goal_time"] = 20;
	
	self thread bot_defend_think( player, radius, "bodyguard", optional_params );
}

// Don't call this function directly, use the above accessor functions
bot_defend_think( defendCenter, defendRadius, defense_type, optional_params )
{
	// Valid options for optional_params:
	//
	// "entrance_points_index" : The index into level.entrance_points for the area
	// "override_entrances" : An array of nodes to force bot to use as entrances to the area
	// "override_goal_type" : The type of goal to use "guard", "critical", etc.
	// "override_origin_node" : If defined, this node will be used as the "origin" of the protect for calculation purposes (if the actual center is in solid, for example)
	// "nearest_node_to_center" : The nearest node to the center point.  If not defined, it will be calculated automatically.
	// "capture_trigger" : The trigger to use for capturing (set automatically in bot_capture_zone)
	// "min_goal_time" : Time in seconds
	// "max_goal_time" : Time in seconds
	// "score_flags" : Extra flags to pass into the scoring method
	
	self notify( "started_bot_defend_think" );
	self endon(  "started_bot_defend_think" );

	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	self endon( "defend_stop" );
	
/#
	if ( !IsAIGameParticipant(self) )
	{
		AssertMsg("Entity of type <" + self.classname + "> is calling bot_defend_think and is not an entity that can perform this (needs to be a bot or humanoid agent");
		return;
	}
#/
	
	self thread defense_death_monitor();

	if ( IsDefined(self.bot_defending) || self BotGetScriptGoalType() == "camp" )
	{
		// If we are already defending something, or we are currently camping, we should clear our current script goal
		self BotClearScriptGoal();
	}
	
	self.bot_defending = true;
	self.bot_defending_type = defense_type;

	if ( defense_type == "capture_zone" )
	{
		self.bot_defending_radius = undefined;
		self.bot_defending_nodes = defendRadius;
		self.bot_defending_trigger = optional_params["capture_trigger"];
		Assert(IsDefined(self.bot_defending_nodes) && self.bot_defending_nodes.size > 0);
		
/#
		if ( !IsDefined(self.bot_defending_nodes) || self.bot_defending_nodes.size == 0 )
			self bot_defend_stop();	// In non-ship, stop the defense to avoid SRE spam
#/
	}
	else
	{
/#
		if ( IsDefined(optional_params) )
			AssertEx(!IsDefined(optional_params["capture_trigger"]), "Only a defense of type 'capture_zone' should have a 'capture_trigger' defined");
#/
		self.bot_defending_radius = defendRadius;
		self.bot_defending_nodes = undefined;
		self.bot_defending_trigger = undefined;
	}
	
/#
	if ( !IsDefined(defendCenter) )
	{
		AssertMsg("Starting bot_defend_think with an undefined <defendCenter>");
		self bot_defend_stop();
	}
#/
	
	if ( IsGameParticipant(defendCenter) )
	{
		self.bot_defend_player_guarding = defendCenter;
		self childthread monitor_defend_player();
	}
	else
	{
		self.bot_defend_player_guarding = undefined;
		self.bot_defending_center = defendCenter;
	}
	
/#
	if ( self.bot_defending_type == "bodyguard" )
	{
		if ( !IsDefined(self.bot_defend_player_guarding) || !IsGameParticipant(self.bot_defend_player_guarding) )
			AssertMsg( "Bot <" + self.name + "> was told to guard an invalid player" );
	}
#/
	
	self BotSetStance("none");
	
	goal_type = undefined;
	min_goal_time = 6;
	max_goal_time = 10;
	if ( IsDefined(optional_params) )
	{
		self.defend_entrance_index = optional_params["entrance_points_index"];
		self.defense_score_flags = optional_params["score_flags"];
		self.bot_defending_override_origin_node = optional_params["override_origin_node"];
		
		if ( IsDefined(optional_params["override_goal_type"]) )
			goal_type = optional_params["override_goal_type"];
		
		if ( IsDefined(optional_params["min_goal_time"]) )
			min_goal_time = optional_params["min_goal_time"];
		
		if ( IsDefined(optional_params["max_goal_time"]) )
			max_goal_time = optional_params["max_goal_time"];
		
		if ( IsDefined(optional_params["override_entrances"]) && optional_params["override_entrances"].size > 0 )
		{
			self.defense_override_entrances = optional_params["override_entrances"];
			
			// Create a unique index for this bot's defense at this time, so that the visibility checks below will be unique to this defense
			self.defend_entrance_index = self.name + " " + GetTime();
			
			// need to calculate crouch and prone visibility
			foreach( entrance in self.defense_override_entrances )
			{
				entrance.prone_visible_from[self.defend_entrance_index] = entrance_visible_from( entrance.origin, self defend_valid_center(), "prone" );
				wait(0.05);
				entrance.crouch_visible_from[self.defend_entrance_index] = entrance_visible_from( entrance.origin, self defend_valid_center(), "crouch" );
				wait(0.05);
			}
		}
	}
	
	if ( !IsDefined(self.bot_defend_player_guarding) )
	{
		// In the case where we are guarding a player, the nearest node is set per frame, so its not done here
		
		nearest_node = undefined;
		
		// First priority is the specified nearest node that was passed in
		if ( IsDefined(optional_params) && IsDefined(optional_params["nearest_node_to_center"]) )
			nearest_node = optional_params["nearest_node_to_center"];
		
		// Next priority is the specified override origin node, since it is the center in this case and is a valid node
		if ( !IsDefined(nearest_node) && IsDefined( self.bot_defending_override_origin_node ) )
			nearest_node = self.bot_defending_override_origin_node;
		
		// Next priority would be the nearest node defined on the trigger that was pre-calculated and passed in
		if ( !IsDefined(nearest_node) && IsDefined(self.bot_defending_trigger) && IsDefined(self.bot_defending_trigger.nearest_node) )
			nearest_node = self.bot_defending_trigger.nearest_node;
		
		// If none of these succeeded, then find the nearest node in sight
		if ( !IsDefined(nearest_node) )
			nearest_node = GetClosestNodeInSight( self defend_valid_center() );
		
		// If we couldn't find the nearest node in sight, try to calculate it via nodes in radius and sight traces
		if ( !IsDefined(nearest_node) )
		{
			defend_center = self defend_valid_center();
			nodes = GetNodesInRadiusSorted( defend_center, 256, 0 );
			for ( i = 0; i < nodes.size; i++ )
			{
				// Try a sight trace extended out a third from the origin point
				center_to_node = VectorNormalize(nodes[i].origin - defend_center);
				trace_start = defend_center + center_to_node * 15;
				if ( SightTracePassed( trace_start, nodes[i].origin, false, undefined ) )
				{
					nearest_node = nodes[i];
					break;
				}
				
				wait(0.05);
				
				// Try a similar trace but at standing height
				if ( SightTracePassed( trace_start + (0,0,55), nodes[i].origin + (0,0,55), false, undefined ) )
				{
					nearest_node = nodes[i];
					break;
				}
				
				wait(0.05);
			}
		}
		
		self.node_closest_to_defend_center = nearest_node;
		AssertEx( IsDefined(self.node_closest_to_defend_center), "bot_defend_think: Could not calculate a nearest node to defense at origin " + self defend_valid_center() );
	}
	
	AssertEx( min_goal_time < max_goal_time, "bot_defend_think: <min_goal_time> must be less than <max_goal_time>" );
	
	find_node_function = level.bot_find_defend_node_func[defense_type];
	
	if ( !IsDefined(goal_type) )
	{
		goal_type = "guard";		// This is the default type
		if ( defense_type == "capture" || defense_type == "capture_zone" )
			goal_type = "objective";
	}
	
	random_stance_at_pathnode_dest = ( self bot_is_capturing() );
	
	if ( defense_type == "protect" )
	{
		self childthread protect_watch_allies();
	}

	for(;;)
	{
		self.prev_defend_node = self.cur_defend_node;
		self.cur_defend_node = undefined;
		self.cur_defend_angle_override = undefined;
		self.cur_defend_point_override = undefined;
				
		self.cur_defend_stance = calculate_defend_stance( random_stance_at_pathnode_dest );
		
		current_goal_type = self BotGetScriptGoalType();
		can_override_goal = bot_goal_can_override( goal_type, current_goal_type );
		if ( !can_override_goal )
		{
			// Don't allow defense to interrupt a critical move
			wait(0.25);
			continue;
		}
		
		cur_min_goal_time = min_goal_time;
		cur_max_goal_time = max_goal_time;
		can_plant_trap = true;
		
		if ( IsDefined( self.defense_investigate_specific_point ) )
		{
			self.cur_defend_point_override = self.defense_investigate_specific_point;
			self.defense_investigate_specific_point = undefined;
			can_plant_trap = false;
			cur_min_goal_time = 1.0;
			cur_max_goal_time = 2.0;
		}
		else if ( IsDefined( self.defense_force_next_node_goal ) )
		{
			self.cur_defend_node = self.defense_force_next_node_goal;
			self.defense_force_next_node_goal = undefined;
		}
		else
		{
			self [[find_node_function]]();
		}
		
		self BotClearScriptGoal();
		
		result = "";
		if ( IsDefined( self.cur_defend_node ) || IsDefined( self.cur_defend_point_override ) )
		{
			// If applicable, plant a trap to help defend the area first
			if ( can_plant_trap && (self bot_is_protecting()) && !IsPlayer( defendCenter ) && IsDefined( self.defend_entrance_index ) )
			{
				trap_item = self bot_get_ambush_trap_item( "trap_directional", "trap", "c4" );
				if ( IsDefined( trap_item ) )
				{
					entrances = self bot_get_entrances_for_stance_and_index( undefined, self.defend_entrance_index );
					self bot_set_ambush_trap( trap_item, entrances, self.node_closest_to_defend_center );
				}
			}

			if ( IsDefined( self.cur_defend_point_override ) )
		    {
				// If we have an override point (we couldn't find a node destination)
				yaw = undefined;
				if ( IsDefined(self.cur_defend_angle_override) )
					yaw = self.cur_defend_angle_override[1];
				
		    	self BotSetScriptGoal(self.cur_defend_point_override, 0, goal_type, yaw);
		    }
			else if ( !IsDefined( self.cur_defend_angle_override ) )
			{
				// If we have a node destination and we want to use the node's angles
				self BotSetScriptGoalNode( self.cur_defend_node, goal_type );
			}
			else
			{
				// If we have a node destination and we want to force the bot to face a different direction than the node's angles
				self BotSetScriptGoalNode(self.cur_defend_node, goal_type, self.cur_defend_angle_override[1]);
			}
			
			if ( random_stance_at_pathnode_dest )
			{
				if ( !IsDefined(self.prev_defend_node) || !IsDefined(self.cur_defend_node) || (self.prev_defend_node != self.cur_defend_node) )
				{
					// If we go prone at our destination, and we're not staying at the same location,
					// then we need to clear our stance (stand up) before we move
					self BotSetStance("none");
				}
			}
			
			previous_goal = self BotGetScriptGoal();
			self notify("new_defend_goal");
			self watch_nodes_stop();
			
			if ( goal_type == "objective" )
			{
				self defense_cautious_approach();	// intentionally not threaded - behavior needs to take over
				self BotSetAwareness( 1.0 );		// Reset to 1.0 when cautiousness finishes (regardless of how it finished)
				self BotSetFlag("cautious", false);
			}
			
			if ( self BotHasScriptGoal() )
			{
				current_goal = self BotGetScriptGoal();
				if ( bot_vectors_are_equal( current_goal, previous_goal ) )
				{
					// If the goal changed since we set it (like during a cautious approach) then we don't want to wait
					result = self bot_waittill_goal_or_fail( 20, "defend_force_node_recalculation" );
				}
			}
			
			if ( result == "goal" )
			{
				if ( random_stance_at_pathnode_dest )
				{
					self BotSetStance(self.cur_defend_stance);
				}
				
				self childthread defense_watch_entrances_at_goal();
			}
		}
		
		if ( result != "goal" )
		{
			wait 0.25;
		}
		else
		{
			wait_time = RandomFloatRange( cur_min_goal_time, cur_max_goal_time );
			result = self waittill_any_timeout( wait_time, "node_relinquished", "goal_changed", "script_goal_changed", "defend_force_node_recalculation", "bad_path" );
			if ( (result == "node_relinquished" || result == "bad_path" || result == "goal_changed" || result == "script_goal_changed" )
			    && (self.cur_defend_stance == "crouch" || self.cur_defend_stance == "prone") )
			{
				// If we were just kicked out of our spot, and we were crouching / going prone, then need to stand up
				self BotSetStance("none");
			}
		}
	}
}

calculate_defend_stance( random_stance_at_pathnode_dest )
{
	stance = "stand";
	if ( random_stance_at_pathnode_dest )
	{
		// Default values (for dumb bots)
		chance_to_stand = 100;
		chance_to_crouch = 0;
		chance_to_prone = 0;
		
		strategy_level = self BotGetDifficultySetting("strategyLevel");
		if ( strategy_level == 1 )
		{
			chance_to_stand = 20;
			chance_to_crouch = 25;
			chance_to_prone = 55;
		}
		else if ( strategy_level >= 2 )
		{
			chance_to_stand = 10;
			chance_to_crouch = 20;
			chance_to_prone = 70;
		}
		
		choice = RandomInt(100);
		if ( choice < chance_to_crouch )
		{
			stance = "crouch";
		}
		else if ( choice < chance_to_crouch + chance_to_prone )
		{
			stance = "prone";
		}
		
		if ( stance == "prone" )
		{
			// Check number of prone entrances to this zone
			entrances_to_this_zone_for_prone = self bot_defend_get_precalc_entrances_for_current_area( "prone" );
			
			// Check number of bots already wanting to be prone in this zone
			bots_prone_at_this_zone = self defend_get_ally_bots_at_zone_for_stance( "prone" );
			
			if ( bots_prone_at_this_zone.size >= entrances_to_this_zone_for_prone.size )
				stance = "crouch";
		}
		
		if ( stance == "crouch" )
		{
			// Check number of crouch entrances to this zone
			entrances_to_this_zone_for_crouch = self bot_defend_get_precalc_entrances_for_current_area( "crouch" );
			
			// Check number of bots already wanting to be crouched in this zone
			bots_crouched_at_this_zone = self defend_get_ally_bots_at_zone_for_stance( "crouch" );
			
			if ( bots_crouched_at_this_zone.size >= entrances_to_this_zone_for_crouch.size )
				stance = "stand";
		}
	}
	
	return stance;
}

SCR_CONST_frames_needed_visible = 18;

should_start_cautious_approach_default( firstCheck )
{
	distance_start_cautiousness = 1250;
	distance_start_cautiousness_sq = distance_start_cautiousness * distance_start_cautiousness;
	
	// If firstCheck is true, this is called to determine if the bot should even attempt to do a cautious approach
	// If firstCheck is false, this is called to determine if the bot should start his cautious approach, or keep waiting
	
	if ( firstCheck )
	{
		if ( self BotGetDifficultySetting("strategyLevel") == 0 )
			return false;
		
		if ( self.bot_defending_type == "capture_zone" && self IsTouching( self.bot_defending_trigger ) )
			return false;
		
		// Don't perform this behavior if we are starting within the radius
		return ( DistanceSquared(self.origin, self.bot_defending_center) > distance_start_cautiousness_sq * 0.75 * 0.75 );
	}
	else
	{
		// Wait until we are within the radius and are pathing toward our goal (vs chasing down enemies)
		if ( self BotPursuingScriptGoal() && DistanceSquared(self.origin, self.bot_defending_center) < distance_start_cautiousness_sq )
	    {
			bot_path_dist = self BotGetPathDist();
			return ( 0 <= bot_path_dist && bot_path_dist <= distance_start_cautiousness );
		}
		else
		{
			return false;
		}
	}
}

setup_investigate_location( node, optional_location )
{
	new_location = SpawnStruct();
	if ( IsDefined(optional_location) )
		new_location.origin = optional_location;
	else
		new_location.origin = node.origin;
	AssertEx( IsDefined(node), "Bot Investigation Location " + new_location.origin + " has no node" );
	new_location.node = node;
	new_location.frames_visible = 0;
	return new_location;
}

defense_cautious_approach()
{
	self notify( "defense_cautious_approach" );
	self endon(  "defense_cautious_approach" );
	
	level endon( "game_ended" );
	self endon( "defend_force_node_recalculation" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "defend_stop" );
	self endon( "started_bot_defend_think" );
	
	if ( ![[ level.bot_funcs["should_start_cautious_approach"] ]] ( true ) )
		return;

	original_script_goal = self BotGetScriptGoal();
	original_script_goal_node = self BotGetScriptGoalNode();
	
/#
	if ( IsDefined(original_script_goal_node) )
	{
		Assert(self.cur_defend_node == original_script_goal_node);
	}
	else
	{
		Assert(IsDefined(self.cur_defend_point_override));	// If we don't have a script goal node, we have to have an override point
		Assert(bot_vectors_are_equal(original_script_goal,self.cur_defend_point_override));
	}
#/
	
	should_continue_waiting = true;
	time_since_last_dist_check = 0.2;
	while( should_continue_waiting )
	{
		wait(0.25);
		
		if ( !self BotHasScriptGoal() )
		{
			// Lost our script goal, so bail
			return;
		}
		
		current_script_goal = self BotGetScriptGoal();
		if ( !bot_vectors_are_equal( original_script_goal, current_script_goal ) )
		{
			// Script goal has changed, so bail
			return;
		}
		
		time_since_last_dist_check += 0.25;
		if ( time_since_last_dist_check >= 0.5 )
		{
			// Debounce this since it can do an A* pathing search
			time_since_last_dist_check = 0.0;
			if ( [[ level.bot_funcs["should_start_cautious_approach"] ]] ( false ) )
				should_continue_waiting = false;
		}
	}
	
	self BotSetAwareness( 1.8 );
	self BotSetFlag("cautious", true);
	
	// **************************************************
	// * Step 1: Build list of locations to investigate *
	// **************************************************
	
	// Get the current path, we'll be using this to find nodes along the way to hide at
	current_path_to_goal = self BotGetNodesOnPath();
	if ( !IsDefined(current_path_to_goal) || current_path_to_goal.size <= 2 )
		return;

	self.locations_to_investigate = [];
	
	radius_around_point = 1000;
	if ( IsDefined(level.protect_radius) )
		radius_around_point = level.protect_radius;
	
	radius_around_point_sq = radius_around_point * radius_around_point;
	nodes_around_defend_center = GetNodesInRadius( self.bot_defending_center, radius_around_point, 0, 500 );
	if ( nodes_around_defend_center.size <= 0 )
		return;
	
	// Locations enemy might be hiding at while defending the point
	num_nodes_desired = 5 + ( self BotGetDifficultySetting("strategyLevel") * 2 );
	num_to_pick = INT(min(num_nodes_desired, nodes_around_defend_center.size ));
	possible_enemy_locations = self BotNodePickMultiple( nodes_around_defend_center, 15, num_to_pick, "node_protect", self defend_valid_center(), "ignore_occupancy" );
	for( i=0; i<possible_enemy_locations.size; i++ )
	{
		new_location = setup_investigate_location( possible_enemy_locations[i] );
		self.locations_to_investigate = array_add( self.locations_to_investigate, new_location );
	}
	
	// Locations this bot was recently killed from
	killer_locations = BotGetMemoryEvents( 0, GetTime() - 60000, 1, "death", 0, self );
	foreach ( location in killer_locations )
	{
		if ( DistanceSquared( location, self.bot_defending_center ) < radius_around_point_sq )
		{
			node_nearest_location = GetClosestNodeInSight( location );
			if ( IsDefined(node_nearest_location) )
			{
				new_location = setup_investigate_location( node_nearest_location, location );
				self.locations_to_investigate = array_add( self.locations_to_investigate, new_location );
			}
		}
	}
	
	if ( IsDefined(self.defend_entrance_index) )
	{
		entrances_to_watch = bot_get_entrances_for_stance_and_index("stand",self.defend_entrance_index);
		for( i=0; i<entrances_to_watch.size; i++ )
		{
			new_location = setup_investigate_location( entrances_to_watch[i] );
			self.locations_to_investigate = array_add( self.locations_to_investigate, new_location );
		}
	}
	
	if ( self.locations_to_investigate.size == 0 )
		return;
	
	// Watch those locations for when they come into view
	self childthread monitor_cautious_approach_dangerous_locations();
	
	goal_type = self BotGetScriptGoalType();
	final_goal_radius = self BotGetScriptGoalRadius();
	final_goal_yaw = self BotGetScriptGoalYaw();
	
	/* Keeping this here for debug purposes, in case I need it in the future
	println("***********************************************************");
	println( "Bot " + self.name + " starting cautious approach at time " + GetTime() );
	if ( IsDefined( goal_node ) )
		println( "goal_node = " + goal_node GetNodeNumber() );
	else
		println( "goal_node = undefined" );
	if ( IsDefined( self.cur_defend_point_override ) )
		println( "self.cur_defend_point_override = " + self.cur_defend_point_override[0] + " " + self.cur_defend_point_override[1] + " " + self.cur_defend_point_override[2] );
	else
		println( "self.cur_defend_point_override = undefined" );
	println("Bot has script goal = " + self BotHasScriptGoal() );
	println("***********************************************************");
	*/
	
	wait(0.05);	// Wait a frame after doing all the calculations, to avoid too much work being done on one frame
	
	for( current_path_section = 1; current_path_section < current_path_to_goal.size - 2; current_path_section++ )
	{
		// *******************************************************
		// * Step 2: Build list of possible locations to hide at *
		// *******************************************************
		
		self bot_waittill_out_of_combat_or_time();

		// Step 2a: Find all nodes linked to the current path node
		potential_hide_nodes = GetLinkedNodes( current_path_to_goal[current_path_section] );
		
		if ( potential_hide_nodes.size == 0 )
			continue;
		
		// Step 2b: Sort through these potential nodes and add any that have any visibility to a location to investigate
		potential_hide_nodes_with_visibility = [];
		for ( i = 0; i < potential_hide_nodes.size; i++ )
		{
			// Ignore nodes behind the bot
			if ( !within_fov( self.origin, self.angles, potential_hide_nodes[i].origin, 0 ) )
				continue;
			
			for ( j = 0; j < self.locations_to_investigate.size; j++ )
			{
				location = self.locations_to_investigate[j];
				if ( NodesVisible( location.node, potential_hide_nodes[i], true ) )
				{
					potential_hide_nodes_with_visibility = array_add( potential_hide_nodes_with_visibility, potential_hide_nodes[i] );
					j = self.locations_to_investigate.size;	// force inner loop to end
				}
			}
		}
		
		if ( potential_hide_nodes_with_visibility.size == 0 )
			continue;
		
		hide_node = self BotNodePick( potential_hide_nodes_with_visibility, 1 + (potential_hide_nodes_with_visibility.size * 0.15), "node_hide" );
		
		// ************************************************************************************
		// * Step 3: Path to the hide node and wait at the node, looking at visible locations *
		// ************************************************************************************

		if ( IsDefined( hide_node ) )
		{
			// Now we have a node to hide at, and we know that hide_node has some visibility to a location (from above)
			visible_locations_from_hide = [];
			for ( i = 0; i < self.locations_to_investigate.size; i++ )
			{
				if ( NodesVisible( self.locations_to_investigate[i].node, hide_node, true ) )
					visible_locations_from_hide = array_add( visible_locations_from_hide, self.locations_to_investigate[i] );
			}
		
			// Path to the hide node
			self BotClearScriptGoal();
			self BotSetScriptGoalNode( hide_node, "critical" );
			self childthread monitor_cautious_approach_early_out();
			result = self bot_waittill_goal_or_fail( undefined, "cautious_approach_early_out" );
			self notify("stop_cautious_approach_early_out_monitor"); // ensure that monitor_cautious_approach_early_out() ends
			
			if ( result == "cautious_approach_early_out" )
			{
				break;
			}
			if ( result == "goal" )
			{
				// Look at each visible node until it has been seen for long enough
				for ( i = 0; i < visible_locations_from_hide.size; i++ )
				{
					total_time_waited = 0;
					while( visible_locations_from_hide[i].frames_visible < SCR_CONST_frames_needed_visible && total_time_waited < (SCR_CONST_frames_needed_visible * 4 / 20) )
					{
						self BotLookAtPoint( visible_locations_from_hide[i].origin + (0,0,self GetPlayerViewHeight()), 0.25, "script_search" );
						wait(0.25);
						total_time_waited += 0.25;
					}
				}
			}
		}
		
		wait(0.05);
	}
	
	self notify( "stop_location_monitoring" );
	self BotClearScriptGoal();
	if ( IsDefined(original_script_goal_node) )
		self BotSetScriptGoalNode( original_script_goal_node, goal_type, final_goal_yaw );
	else
		self BotSetScriptGoal( self.cur_defend_point_override, final_goal_radius, goal_type, final_goal_yaw );
}

monitor_cautious_approach_early_out()
{
	self endon("cautious_approach_early_out");
	self endon("stop_cautious_approach_early_out_monitor");

	capture_radius_SQ = undefined;
	if ( IsDefined( self.bot_defending_radius ) )
		capture_radius_SQ = self.bot_defending_radius * self.bot_defending_radius;
	else if ( IsDefined( self.bot_defending_nodes ) )
	{
		zone_furthest_distance = self bot_capture_zone_get_furthest_distance();
		capture_radius_SQ = zone_furthest_distance * zone_furthest_distance;
	}
	
	wait(0.05);	// allow time for execution to reach the "waittill_any_return" line before calling this for the first time
	
	while(1)
	{
		if ( DistanceSquared(self.origin,self.bot_defending_center) < capture_radius_SQ )
		{
			self notify("cautious_approach_early_out");
		}
		wait(0.05);
	}
}

monitor_cautious_approach_dangerous_locations()
{
	self endon( "stop_location_monitoring" );
	too_close_dist_sq = 100 * 100;
	
	while(1)
	{
		closest_node_to_bot = self GetNearestNode();
		if ( IsDefined(closest_node_to_bot) )
		{
			bot_fov = self BotGetFovDot();
			for ( i = 0; i < self.locations_to_investigate.size; i++ )
			{
				//line( self.origin + (0,0,20), self.locations_to_investigate[i].origin, (1,0,0), 1.0, true, 1 );
				//bot_draw_cylinder(self.locations_to_investigate[i].origin, 10, 40, 0.05, undefined, (1,0,0), true, 4);
				if ( NodesVisible( closest_node_to_bot, self.locations_to_investigate[i].node, true ) )
				{
					node_within_fov = within_fov( self.origin, self.angles, self.locations_to_investigate[i].origin, bot_fov );
					
					should_check_dist = !node_within_fov || self.locations_to_investigate[i].frames_visible < SCR_CONST_frames_needed_visible-1;
					if ( should_check_dist && DistanceSquared( self.origin, self.locations_to_investigate[i].origin ) < too_close_dist_sq )
					{
						// Automatically "see" any close nodes immediately
						node_within_fov = true;
						self.locations_to_investigate[i].frames_visible = SCR_CONST_frames_needed_visible;
					}
	
					if ( node_within_fov )
					{
						self.locations_to_investigate[i].frames_visible++;
						if ( self.locations_to_investigate[i].frames_visible >= SCR_CONST_frames_needed_visible )
						{
							self.locations_to_investigate[i] = self.locations_to_investigate[self.locations_to_investigate.size-1];
							self.locations_to_investigate[self.locations_to_investigate.size-1] = undefined;
							i--;
						}
					}
				}
			}
		}
		
		wait(0.05);
	}
}

protect_watch_allies()
{
	self notify( "protect_watch_allies" );
	self endon(  "protect_watch_allies" );
	
	next_time_check_this_ally = [];
	minimap_radius = 1050; // rough estimate
	minimap_radius_sq = minimap_radius * minimap_radius;
	
	radius_around_point = 900;
	if ( IsDefined(level.protect_radius) )
		radius_around_point = level.protect_radius;
	
	while(1)
	{
		cur_time = GetTime();
		
		// Get all teammates in the radius around our defense point
		teammates_defending_this_point = self bot_get_teammates_in_radius( self.bot_defending_center, radius_around_point );
		foreach( teammate in teammates_defending_this_point )
		{
			teammate_entity_num = teammate.entity_number;
			if ( !IsDefined(teammate_entity_num) )
				teammate_entity_num = teammate GetEntityNumber();

			if ( !IsDefined( next_time_check_this_ally[teammate_entity_num] ) )
				next_time_check_this_ally[teammate_entity_num] = cur_time - 1;
			
			if ( !IsDefined(teammate.last_investigation_time) )
				teammate.last_investigation_time = cur_time - 10001;
			
			// First, check if teammate is dead and has died within the last five seconds
			if ( teammate.health == 0 && IsDefined(teammate.deathTime) && (cur_time - teammate.deathTime) < 5000 )
			{
				// Next, see if we are allowed to check on this ally
				if ( (cur_time - teammate.last_investigation_time) > 10000 && cur_time > next_time_check_this_ally[teammate_entity_num] )
				{
					// Finally, some sanity checks - check if teammate was last attacked by someone on the enemy team
					if ( IsDefined(teammate.lastAttacker) && IsDefined(teammate.lastAttacker.team) && teammate.lastAttacker.team == get_enemy_team(self.team) )
					{
						// We know that this teammate died protecting the same point that this bot is protecting
						// So finally, we need to check if this bot could have seen him on his minimap
						if ( DistanceSquared( teammate.origin, self.origin ) < minimap_radius_sq )
						{
							// Inform the bot that there might be an enemy here
							self BotGetImperfectEnemyInfo( teammate.lastAttacker, teammate.origin );
							
							// Force the bot to move to that location.  Once he gets close enough, the Enemy Search should take over
							nearest_node_to_teammate = GetClosestNodeInSight(teammate.origin);
							if ( IsDefined(nearest_node_to_teammate) )
							{
								self.defense_investigate_specific_point = nearest_node_to_teammate.origin;
								self notify("defend_force_node_recalculation");
							}
		
							// Make sure that only one bot can react to this death
							teammate.last_investigation_time = cur_time;
						}
						
						// Regardless of whether we chose to check this out or not, don't take any more actions regarding this guy for 10 seconds
						next_time_check_this_ally[teammate_entity_num] = cur_time + 10000;
					}
				}
			}
		}
		
		wait( (RandomInt(5)+1) * 0.05 );
	}
}

defense_get_initial_entrances()
{
	if ( IsDefined(self.defense_override_entrances) )
	{
		return self.defense_override_entrances;
	}
	else if ( self bot_is_capturing() )
	{
		// If capturing a point or zone, use the pre-calculated entrances for the point
		return self bot_defend_get_precalc_entrances_for_current_area( self.cur_defend_stance );
	}
	else if ( self bot_is_protecting() || self bot_is_bodyguarding() )
	{
		// If protecting a point, use entrances from the current position
		entrances = FindEntrances( self.origin );
/#		
		if ( IsDefined( self GetNearestNode() ) )
			AssertEx( entrances.size > 0, "Entrance points for bot at location " + self.origin + " could not be calculated.  Check pathgrid around that area" );
#/		
		return entrances;
	}
}

defense_watch_entrances_at_goal()
{
	self notify( "defense_watch_entrances_at_goal" );
	self endon(  "defense_watch_entrances_at_goal" );
	self endon("new_defend_goal");
	self endon("script_goal_changed");
	
	node_nearest_bot = self GetNearestNode();
	entrances_to_watch = undefined;
	if ( self bot_is_capturing() )
	{
		precalculated_entrances = self defense_get_initial_entrances();
		
		// Extra check to make sure the precalculated entrances are valid for the location this bot is currently at
		entrances_to_watch = [];
		if ( IsDefined(node_nearest_bot) )
		{
			foreach( entrance in precalculated_entrances )
			{
				if ( NodesVisible( node_nearest_bot, entrance, true ) )
					entrances_to_watch = array_add(entrances_to_watch, entrance );
			}
		}
	}
	else if ( self bot_is_protecting() || self bot_is_bodyguarding() )
	{
		entrances_to_watch = self defense_get_initial_entrances();
		
		// Add in node closest to the center (we should be watching that too)		
		if ( IsDefined(node_nearest_bot) && !IsSubStr( self GetCurrentWeapon(), "riotshield" ) )
		{
			if ( NodesVisible( node_nearest_bot, self.node_closest_to_defend_center, true ) )
				entrances_to_watch = array_add(entrances_to_watch, self.node_closest_to_defend_center);
		}
	}
	
	if ( IsDefined( entrances_to_watch ) )
	{
		self childthread bot_watch_nodes( entrances_to_watch );
		if ( self bot_is_bodyguarding() )
			self childthread bot_monitor_watch_entrances_bodyguard();
		else
			self childthread bot_monitor_watch_entrances_at_goal();
	}
}

bot_monitor_watch_entrances_at_goal()
{
	self notify( "bot_monitor_watch_entrances_at_goal" );
	self endon( "bot_monitor_watch_entrances_at_goal" );
	self notify( "bot_monitor_watch_entrances" );
	self endon( "bot_monitor_watch_entrances" );
	
	while(!IsDefined(self.watch_nodes))
		wait(0.05);
	
	watch_node_chance_func = level.bot_funcs["get_watch_node_chance"];
	
	while(1)
	{
		foreach( node in self.watch_nodes )
		{
			if ( node == self.node_closest_to_defend_center )
				node.watch_node_chance[self.entity_number] = 0.8;	// Node closest to the center starts out slightly lower priority
			else
				node.watch_node_chance[self.entity_number] = 1.0;
		}
		
		has_watch_node_chance_func = IsDefined(watch_node_chance_func);
		if ( !has_watch_node_chance_func )
		{
			// If the gametype doesn't want to do anything with this node chance, then generally ignore areas
			// that the bot predicts his allies are controlling
			prioritize_watch_nodes_toward_enemies(0.5);
		}
		
		foreach( node in self.watch_nodes )
		{
			if ( has_watch_node_chance_func )
			{
				gametype_scalar = self [[watch_node_chance_func]]( node );
				node.watch_node_chance[self.entity_number] *= gametype_scalar;
			}
			
			if ( self entrance_watched_by_ally( node ) )
				node.watch_node_chance[self.entity_number] *= 0.5;
		}

		wait(RandomFloatRange(0.5,0.75));
	}
}

bot_monitor_watch_entrances_bodyguard()
{
	self notify( "bot_monitor_watch_entrances_bodyguard" );
	self endon( "bot_monitor_watch_entrances_bodyguard" );
	self notify( "bot_monitor_watch_entrances" );
	self endon( "bot_monitor_watch_entrances" );
	
	while(!IsDefined(self.watch_nodes))
		wait(0.05);

	while(1)
	{
		player_guarding_forward = AnglesToForward(self.bot_defend_player_guarding.angles) * (1,1,0);
		player_guarding_forward = VectorNormalize(player_guarding_forward);
		
		foreach( node in self.watch_nodes )
		{
			node.watch_node_chance[self.entity_number] = 1.0;
			
			// Tend to not look at nodes that are visible to the player this bot is guarding
			player_to_node = node.origin - self.bot_defend_player_guarding.origin;
			player_to_node = VectorNormalize(player_to_node);
			
			player_dot_facing_to_node = VectorDot( player_guarding_forward, player_to_node );
			if ( player_dot_facing_to_node > 0.6 )
				node.watch_node_chance[self.entity_number] *= 0.33;	// node is in player's view
			else if ( player_dot_facing_to_node > 0 )
				node.watch_node_chance[self.entity_number] *= 0.66;	// node is not behind player
			
			if ( !self entrance_to_enemy_zone( node ) )
				node.watch_node_chance[self.entity_number] *= 0.5;
		}

		wait(RandomFloatRange(0.4,0.6));
	}	
}

entrance_to_enemy_zone( entrance )
{
	entrance_zone_index = GetNodeZone( entrance );
	bot_to_entrance = VectorNormalize( entrance.origin - self.origin );
	
	for ( z = 0; z < level.zoneCount; z++ )
	{
		if ( BotZoneGetCount( z, self.team, "enemy_predict" ) > 0 )
		{
			// We know that the zone has enemies
			if ( IsDefined(entrance_zone_index) && z == entrance_zone_index )
			{
				// and the entrance node is in this zone, then return true
				return true;
			}
			else
			{
				// and the entrance node is not in this zone, then compare the direction from the entrance zone to the entrance,
				// and the direction from the entrance zone to this zone.  If they are in the same direction, then consider
				// this entrance to be an entrance to an enemy zone
				bot_to_this_zone_origin = VectorNormalize( GetZoneOrigin(z) - self.origin );
				dot = VectorDot( bot_to_entrance, bot_to_this_zone_origin );
				if ( dot > 0.2 )
					return true;
			}
		}
	}
	
	return false;
}

prioritize_watch_nodes_toward_enemies( scalar )
{
	if ( self.watch_nodes.size <= 0 )
		return;
	
	nodes_testing = self.watch_nodes;
	
	for ( z = 0; z < level.zoneCount; z++ )
	{
		if ( BotZoneGetCount( z, self.team, "enemy_predict" ) <= 0 )
			continue;
		
		if ( nodes_testing.size == 0 )
			break;
		
		bot_to_this_zone_origin = VectorNormalize( GetZoneOrigin(z) - self.origin );
		
		for ( i = 0; i < nodes_testing.size; i++ )
		{
			node_zone_index = GetNodeZone( nodes_testing[i] );
			node_is_entrance_to_zone = false;
			
			// We know that the zone has enemies
			if ( IsDefined(node_zone_index) && z == node_zone_index )
			{
				// and the node is in this zone, then return true
				node_is_entrance_to_zone = true;
			}
			else
			{
				// and the entrance node is not in this zone, then compare the direction from the entrance zone to the entrance,
				// and the direction from the entrance zone to this zone.  If they are in the same direction, then consider
				// this entrance to be an entrance to an enemy zone
				bot_to_node = VectorNormalize( nodes_testing[i].origin - self.origin );
				dot = VectorDot( bot_to_node, bot_to_this_zone_origin );
				if ( dot > 0.2 )
					node_is_entrance_to_zone = true;
			}
			
			if ( node_is_entrance_to_zone )
			{
				nodes_testing[i].watch_node_chance[self.entity_number] *= scalar;
				nodes_testing[i] = nodes_testing[nodes_testing.size-1];
				nodes_testing[nodes_testing.size-1] = undefined;
				i--;
			}
		}
	}
}

entrance_watched_by_ally( entrance )
{
	teammates_defending_this_point = self bot_get_teammates_currently_defending_point( self.bot_defending_center );	
	foreach ( teammate in teammates_defending_this_point )
	{
		if ( entrance_watched_by_player( teammate, entrance ) )
			return true;
	}
	
	return false;
}

entrance_watched_by_player( player, entrance )
{
	player_forward = AnglesToForward(player.angles);
	player_to_node = VectorNormalize(entrance.origin - player.origin);
	
	player_dot_facing_to_node = VectorDot( player_forward, player_to_node );
	if ( player_dot_facing_to_node > 0.6 )
		return true;
	
	return false;
}

bot_get_teammates_currently_defending_point( point, radius_around_point )
{
	// A human player is considered defending this point if they are within the radius
	// A bot player is considered defending this point if they are within the radius, and have the location set as their defend target
	
	if ( !IsDefined(radius_around_point) )
	{
		// If no radius is defined, use 900 or the level.protect_radius
		if ( IsDefined(level.protect_radius) )
			radius_around_point = level.protect_radius;
		else
			radius_around_point = 900;
	}
	
	teammates_defending_point = [];
	teammates_in_radius = bot_get_teammates_in_radius( point, radius_around_point );
	foreach( teammate in teammates_in_radius )
	{
		if ( !IsAI( teammate ) || teammate bot_is_defending_point( point ) )
		{
			teammates_defending_point = array_add(teammates_defending_point, teammate);
		}
	}
	
	return teammates_defending_point;
}

bot_get_teammates_in_radius( point, radius_around_point )
{
	radius_around_point_sq = radius_around_point * radius_around_point;
	teammates_in_radius = [];
	for ( i = 0; i < level.participants.size; i++ )
	{
		other_player = level.participants[i];
		if ( (other_player != self) && IsDefined(other_player.team) && (other_player.team == self.team) && IsTeamParticipant(other_player) )
		{
			// other_player is on my team and is counted as a team participant
			if ( DistanceSquared( point, other_player.origin ) < radius_around_point_sq )
				teammates_in_radius = array_add(teammates_in_radius, other_player);
		}
	}
	
	return teammates_in_radius;
}

defense_death_monitor()
{
	level endon( "game_ended" );
	self endon( "started_bot_defend_think" );
	self endon( "defend_stop" );
	self endon( "disconnect" );
	
	self waittill("death");
	if ( IsDefined( self ) )
		self thread bot_defend_stop();
}

/* 
=============
///ScriptDocBegin
"Name: bot_defend_stop()"
"Summary: Stops any scripted defense the bot might be doing"
"CallOn: A bot player"
"Example: self bot_defend_stop();"
///ScriptDocEnd
============
 */
bot_defend_stop( )
{
	self notify( "defend_stop" );
	self.bot_defending = undefined;
	self.bot_defending_center = undefined;
	self.bot_defending_radius = undefined;
	self.bot_defending_nodes = undefined;
	self.bot_defending_type = undefined;
	self.bot_defending_trigger = undefined;
	self.bot_defending_override_origin_node = undefined;
	self.bot_defend_player_guarding = undefined;
	self.defense_score_flags = undefined;
	self.node_closest_to_defend_center = undefined;
	self.defense_investigate_specific_point = undefined;
	self.defense_force_next_node_goal = undefined;
	
	self.prev_defend_node = undefined;
	self.cur_defend_node = undefined;
	self.cur_defend_angle_override = undefined;
	self.cur_defend_point_override = undefined;
		
	self.defend_entrance_index = undefined;
	self.defense_override_entrances = undefined;
	
	self BotClearScriptGoal();
	self BotSetStance("none");
}

defend_get_ally_bots_at_zone_for_stance( stance )
{
	other_players_with_same_stance = [];
	
	foreach( other_player in level.participants )
	{
		if ( !IsDefined( other_player.team ) )
			continue;

		if ( other_player.team == self.team && other_player != self && IsAI(other_player) && other_player bot_is_defending() && other_player.cur_defend_stance == stance )
		{
			if ( other_player.bot_defending_type == self.bot_defending_type && self bot_is_defending_point( other_player.bot_defending_center ) )
			{
				other_players_with_same_stance = array_add(other_players_with_same_stance, other_player);
			}
		}
	}
	
	return other_players_with_same_stance;
}

monitor_defend_player()
{
	player_not_moving_time = 0;
	new_goal_radius = 175;		// If player moves this distance, then consider him moving and set a destination in front of him
	last_player_pos = self.bot_defend_player_guarding.origin;
	prev_player_velocity = 0;
	should_reset_player_base_pos_when_still = false;
	
	while(1)
	{
		if ( !IsDefined(self.bot_defend_player_guarding) )
			self thread bot_defend_stop();
		
		if ( self.bot_defend_player_guarding IsLinked() )
		{
			wait(0.05);
			continue;
		}
		
		self.bot_defending_center = self.bot_defend_player_guarding.origin;
		self.node_closest_to_defend_center = self.bot_defend_player_guarding GetNearestNode();
		if ( !IsDefined(self.node_closest_to_defend_center) )
			self.node_closest_to_defend_center = self GetNearestNode();
		Assert(IsDefined(self.node_closest_to_defend_center));
		
		if ( self BotGetScriptGoalType() != "none" )
		{
			script_goal = self BotGetScriptGoal();
			
			//bot_draw_cylinder( last_player_pos, new_goal_radius, 40, 0.05, undefined, (0,1,0), true, 15 );
			
			player_guarding_velocity = self.bot_defend_player_guarding GetVelocity();
			player_guarding_velocity_len_sq = LengthSquared(player_guarding_velocity);
			if ( player_guarding_velocity_len_sq > (10 * 10) )
			{
				// If player is moving, check that the node destination is still in front of the player
				player_not_moving_time = 0;
				
				if ( DistanceSquared( last_player_pos, self.bot_defend_player_guarding.origin ) > (new_goal_radius * new_goal_radius) )
				{
					last_player_pos = self.bot_defend_player_guarding.origin;
					should_reset_player_base_pos_when_still = true;
					
					player_to_script_goal = VectorNormalize( script_goal - self.bot_defend_player_guarding.origin );
					normalized_velocity = VectorNormalize(player_guarding_velocity);
					if ( VectorDot( player_to_script_goal, normalized_velocity ) < 0.1 )
					{
						self notify("defend_force_node_recalculation");	// force bot to pick a new spot
						wait(0.25);		// Defend script waits 0.25s after this notification before it can calculate a new goal
					}
				}
			}
			else
			{
				// If player is not moving, check that the node destination lies in the defending radius
				player_not_moving_time += 0.05;
				
				if ( prev_player_velocity > (10*10) && should_reset_player_base_pos_when_still )
				{
					// reset player "base" position if he just stopped moving
					last_player_pos = self.bot_defend_player_guarding.origin;
					should_reset_player_base_pos_when_still = false;
				}
				
				if ( player_not_moving_time > 0.5 )
				{
					distSQ = DistanceSquared(script_goal, self.bot_defending_center);
					if ( distSQ > self.bot_defending_radius * self.bot_defending_radius )
					{
						self notify("defend_force_node_recalculation");	// force bot to pick a new spot
						wait(0.25);		// Defend script waits 0.25s after this notification before it can calculate a new goal
					}
				}
			}
			
			prev_player_velocity = player_guarding_velocity_len_sq;
			
			if ( abs(self.bot_defend_player_guarding.origin[2] - script_goal[2]) >= 50 )
			{
				self notify("defend_force_node_recalculation");
				wait(0.25);		// Defend script waits 0.25s after this notification before it can calculate a new goal
			}
			
		}
		
		wait(0.05);
	}
}

find_defend_node_capture()
{
	entrance_point = self bot_defend_get_random_entrance_point_for_current_area();
	
	node = self bot_find_node_to_capture_point( self defend_valid_center(), self.bot_defending_radius, entrance_point );
	
	if ( IsDefined(node) )
    {
		if ( IsDefined(entrance_point) )
	    {
    		node_to_entrance = VectorNormalize(entrance_point - node.origin);
			self.cur_defend_angle_override = VectorToAngles(node_to_entrance);
		}
		else
		{
 			center_to_node = VectorNormalize(node.origin - self defend_valid_center());
			self.cur_defend_angle_override = VectorToAngles(center_to_node);
		}
		self.cur_defend_node = node;
    }
	else
	{
		if ( IsDefined(entrance_point) )
		{
			self bot_handle_no_valid_defense_node(entrance_point, undefined);
		}
		else
		{
			self bot_handle_no_valid_defense_node(undefined, self defend_valid_center());
		}
	}
}

find_defend_node_capture_zone()
{
	entrance_point = self bot_defend_get_random_entrance_point_for_current_area();
	
	node = self bot_find_node_to_capture_zone( self.bot_defending_nodes, entrance_point );
	
	if ( IsDefined(node) )
    {
		if ( IsDefined(entrance_point) )
	    {
	    	node_to_entrance = VectorNormalize(entrance_point - node.origin);
			self.cur_defend_angle_override = VectorToAngles(node_to_entrance);
		}
		else
		{
 			center_to_node = VectorNormalize(node.origin - self defend_valid_center());
			self.cur_defend_angle_override = VectorToAngles(center_to_node);
		}
		self.cur_defend_node = node;
    }
	else
	{
		if ( IsDefined(entrance_point) )
		{
			self bot_handle_no_valid_defense_node(entrance_point, undefined);
		}
		else
		{
			self bot_handle_no_valid_defense_node(undefined, self defend_valid_center());
		}
	}
}

find_defend_node_protect()
{
	node = self bot_find_node_that_protects_point( self defend_valid_center(), self.bot_defending_radius );

	if ( IsDefined( node ) ) 
	{
		node_to_center = VectorNormalize(self defend_valid_center() - node.origin);
		self.cur_defend_angle_override = VectorToAngles(node_to_center);
		self.cur_defend_node = node;
	}
	else
	{
		self bot_handle_no_valid_defense_node(self defend_valid_center(), undefined);
	}
}

find_defend_node_bodyguard()
{
	node = self bot_find_node_to_guard_player( self defend_valid_center(), self.bot_defending_radius );
	
	if ( IsDefined(node) )
    {
		self.cur_defend_node = node;
    }
	else
	{
		nearest_node_bot = self GetNearestNode();
		if ( IsDefined(nearest_node_bot) )
			self.cur_defend_node = nearest_node_bot;
		else
			self.cur_defend_point_override = self.origin;
	}
}

find_defend_node_patrol()
{
	// Get a random node within the radius tending to pick ones with highest traffic density
	node = undefined;
	nodes = GetNodesInRadius( self defend_valid_center(), self.bot_defending_radius, 0 );
	if ( IsDefined( nodes ) && nodes.size > 0 )
		node = self BotNodePick( nodes, 1 + (nodes.size * 0.5), "node_traffic" );
	
	if ( IsDefined(node) )
    {
		self.cur_defend_node = node;
    }
	else
	{
		self bot_handle_no_valid_defense_node(undefined, self defend_valid_center());
	}
}

bot_handle_no_valid_defense_node(face_towards_point, face_away_from_point)
{
	assert( (!IsDefined(face_towards_point) && IsDefined(face_away_from_point)) || (IsDefined(face_towards_point) && !IsDefined(face_away_from_point)) );
	
	if ( self.bot_defending_type == "capture_zone" )
		self.cur_defend_point_override = self bot_pick_random_point_from_set(self defend_valid_center(), self.bot_defending_nodes, ::bot_can_use_point_in_defend);
	else
		self.cur_defend_point_override = self bot_pick_random_point_in_radius(self defend_valid_center(), self.bot_defending_radius, ::bot_can_use_point_in_defend, 0.15, 0.9);
		
	// face towards / away from a point
	if ( IsDefined(face_towards_point) )
	{
		angle_dir = VectorNormalize(face_towards_point - self.cur_defend_point_override);
		self.cur_defend_angle_override = VectorToAngles(angle_dir);
	}
	else if ( IsDefined(face_away_from_point) )
	{
		angle_dir = VectorNormalize(self.cur_defend_point_override - face_away_from_point);
		self.cur_defend_angle_override = VectorToAngles(angle_dir);
	}
}

bot_can_use_point_in_defend(point)
{
	if ( self bot_check_team_is_using_position( point, true, true, true ) )
		return false;
	
	return true;
}

SCR_CONST_player_close_dist = 21;
SCR_CONST_player_close_dist_sq = SCR_CONST_player_close_dist * SCR_CONST_player_close_dist;

bot_check_team_is_using_position( position, check_human_player_near, check_bot_player_near, check_bot_destination_near )
{
	for ( i = 0; i < level.participants.size; i++ )
	{
		other_player = level.participants[i];
		if ( other_player.team == self.team && other_player != self )
		{
			if ( IsAI( other_player ) )
			{
				if ( check_bot_player_near )
				{
					// Check if a bot player is standing near this node
					if ( DistanceSquared(position,other_player.origin) < SCR_CONST_player_close_dist_sq )
					{
						return true;
					}
				}
				
				if ( check_bot_destination_near && other_player BotHasScriptGoal() )
				{
					// Check if bot player has a goal near this point
					bot_goal = other_player BotGetScriptGoal();
					if ( DistanceSquared(position,bot_goal) < SCR_CONST_player_close_dist_sq )
					{
						return true;
					}
				}
			}
			else
			{
				if ( check_human_player_near )
				{
					// Check if a human player is standing near this node
					if ( DistanceSquared(position,other_player.origin) < SCR_CONST_player_close_dist_sq )
					{
						return true;
					}
				}
			}
		}
	}
	
	return false;
}

bot_capture_zone_get_furthest_distance()
{
	furthest_dist = 0;
	if ( IsDefined(self.bot_defending_nodes) )
	{
		foreach( node in self.bot_defending_nodes )
		{
			dist_to_node = Distance(self.bot_defending_center,node.origin);
			furthest_dist = max(dist_to_node,furthest_dist);
		}
	}
		
	return furthest_dist;
}

// Tactical Goal Explanation
// =========================
// Mandatory args
// tactical_goal.type				The type of goal.  Used with bot_has_tactical_goal so different goals can check if they already exist in the list before trying to add a new one
// tactical_goal.goal_position		The position of the goal
// tactical_goal.priority			The priority of this goal.  0 to 100, with 100 being highest priority

// Optional Args
// tactical_goal.object				The object we are going after
// tactical_goal.goal_type			Type of goal pathing to use - "tactical", "critical", "guard", etc."
// tactical_goal.goal_yaw			The yaw of the goal
// tactical_goal.goal_radius		The radius of the goal
// tactical_goal.objective_radius	Radius to use when setting an objective goal (using the goal_type above)
// tactical_goal.start_thread		This function is called when the goal starts
// tactical_goal.end_thread			This function is called when the goal ends, regardless of it it was successful or not.
// tactical_goal.should_abort		This function is called every frame while the goal is active.  If it ever returns true, the goal is aborted.
// tactical_goal.action_thread		This function is called when the goal is reached.  It contains some action for the bot to perform.

				
bot_think_tactical_goals()
{
	self notify( "bot_think_tactical_goals" );
	self endon(  "bot_think_tactical_goals" );
		
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self.tactical_goals = [];
	while(1)
	{
		if ( self.tactical_goals.size > 0 && !self bot_is_remote_or_linked() )
		{
			new_goal = self.tactical_goals[0];
			
			if ( !IsDefined( new_goal.abort ) )
			{			
				self notify( "start_tactical_goal" );
				
				if ( IsDefined(new_goal.start_thread) )
				{
					self [[new_goal.start_thread]](new_goal);
				}
				
				self childthread watch_goal_aborted( new_goal );
				
				goal_type = "tactical";
				if ( IsDefined(new_goal.goal_type) )
				    goal_type = new_goal.goal_type;
				
				//PrintLn( GetTime() + " Bot <" + self.name + "> starting tactical goal of '" + new_goal.type + "' and goal_type of '" + goal_type + "'");
				self BotSetScriptGoal( new_goal.goal_position, new_goal.goal_radius, goal_type, new_goal.goal_yaw, new_goal.objective_radius);
				
				result = self bot_waittill_goal_or_fail( undefined, "stop_tactical_goal" );
				self notify("stop_goal_aborted_watch");
				
				//PrintLn( GetTime() + " Bot <" + self.name + "> moving toward tactical goal of '" + new_goal.type + "' got notify of '" + result + "'");
				
				if ( result == "goal" )
				{
					//PrintLn( GetTime() + " Bot <" + self.name + "> reached tactical goal of '" + new_goal.type + "' and goal_type of '" + goal_type + "'");
					
					if ( IsDefined(new_goal.action_thread) )
						self [[new_goal.action_thread]](new_goal);
				}
				
				if ( result != "script_goal_changed" )
				{
					self BotClearScriptGoal();
				}
				
				if ( IsDefined(new_goal.end_thread) )
				{
					self [[new_goal.end_thread]](new_goal);
				}
			}
			
			self.tactical_goals = array_remove(self.tactical_goals, new_goal);
		}
		
		wait(0.05);
	}
}

watch_goal_aborted( goal )
{
	self endon("stop_tactical_goal");
	self endon("stop_goal_aborted_watch");
	
	wait(0.05);	// allow time for execution to reach the "waittill_any_return" line before calling this for the first time
	
	while(1)
	{
		if ( IsDefined( goal.abort ) || (IsDefined(goal.should_abort) && self [[goal.should_abort]](goal)) )
			self notify("stop_tactical_goal");
		
		wait(0.05);
	}
}

/* 
=============
///ScriptDocBegin
"Name: bot_new_tactical_goal( <type>, <goal_position>, <priority>, <extra_params> )"
"Summary: Adds a new tactical goal for this bot"
"CallOn: A bot player"
"MandatoryArg: <type> : Type of tactical goal this is ("seek_dropped_weapon", etc.)"
"MandatoryArg: <goal_position> : Position of the goal"
"MandatoryArg: <priority> : The priority of this goal, from 0 to 100. 100 is the highest priority"
"OptionalArg: <extra_params> : A struct with optional parameters.  Listed below"
"Example: self bot_new_tactical_goal( "kill_tag", self.tag_getting.curorigin, 0, undefined, undefined, 25, self.tag_getting, undefined, ::tag_end, ::goal_tag_picked_up, undefined );"
"NoteLine: All of the "threads" listed below are actually function calls - they are not threaded"
"NoteLine: <extra_params.object> : The object of the tactical goal.  Used with bot_has_tactical_goal, to determine duplicate goals"
"NoteLine: <extra_params.script_goal_type> : Type of goal pathing to use - "tactical", "critical", "guard", etc."
"NoteLine: <extra_params.script_goal_yaw> : Goal yaw to use when pathing to this goal"
"NoteLine: <extra_params.script_goal_radius> : Goal radius to use when pathing to this goal"
"NoteLine: <extra_params.start_thread> : A function to execute when this tactical goal starts
"NoteLine: <extra_params.end_thread> : A function to execute when this tactical goals ends, regardless of it was successful or not"
"NoteLine: <extra_params.should_abort> : A function that is called to determine if the tactical goal should end early.  Should return true in that case"
"NoteLine: <extra_params.action_thread> : A function to execute if the bot reaches his tactical goal"
"NoteLine: <extra_params.objective_radius> : Radius to use when setting an objective goal"
///ScriptDocEnd
============
 */
bot_new_tactical_goal( type, goal_position, priority, extra_params )
{
	new_goal = SpawnStruct();
	new_goal.type = type;
	new_goal.goal_position = goal_position;
	
	if ( IsDefined(self.only_allowable_tactical_goals) )
	{
		if ( !array_contains(self.only_allowable_tactical_goals,type) )
			return;
	}

	assert( priority >= 0 && priority <= 100 );
	new_goal.priority = priority;
	
	new_goal.object = extra_params.object;
	
	new_goal.goal_type = extra_params.script_goal_type;
	new_goal.goal_yaw = extra_params.script_goal_yaw;
	new_goal.goal_radius = 0;
	if ( IsDefined( extra_params.script_goal_radius ) )
		new_goal.goal_radius = extra_params.script_goal_radius;
	
	new_goal.start_thread = extra_params.start_thread;
	new_goal.end_thread = extra_params.end_thread;
	new_goal.should_abort = extra_params.should_abort;
	new_goal.action_thread = extra_params.action_thread;
	new_goal.objective_radius = extra_params.objective_radius;
	
	// iterate through self.tactical_goals and place this goal in the correct priority
	for ( position_to_add=0; position_to_add<self.tactical_goals.size; position_to_add++ )
	{
		if ( new_goal.priority > self.tactical_goals[position_to_add].priority )
			break;
	}
	
	// insert tactical goal at self.tactical_goals[position_to_add], pushing everything (including the element already in position_to_add) back one element
	for ( i=self.tactical_goals.size-1; i>=position_to_add; i-- )
	{
		self.tactical_goals[i+1] = self.tactical_goals[i];
	}
	
	self.tactical_goals[position_to_add] = new_goal;
}

/* 
=============
///ScriptDocBegin
"Name: bot_has_tactical_goal( <goal_type>, <object> )"
"Summary: Checks if a bot already has a tactical goal of this type"
"CallOn: A bot player"
"OptionalArg: <type> : Type of tactical goal to check"
"OptionalArg: <object> : The object of the tactical goal.  Used to differentiate two different goals of the same type"
"Example: if ( self bot_has_tactical_goal( "seek_dropped_weapon", dropped_weapon ) == false )"
///ScriptDocEnd
============
 */
bot_has_tactical_goal( goal_type, object )
{
	if ( !IsDefined( self.tactical_goals ) )
		return false;
	
	if ( IsDefined( goal_type ) )
	{
		foreach( goal in self.tactical_goals )
		{
			if ( goal.type == goal_type )
			{
				if ( IsDefined(object) && IsDefined(goal.object) )
				{
					return (goal.object == object);
				}
				else
				{
					return true;
				}
			}
		}
		
		return false;
	}
	else
	{
		return (self.tactical_goals.size > 0);
	}
}


/* 
=============
///ScriptDocBegin
"Name: bot_abort_tactical_goal( <goal_type>, <object> )"
"Summary: Aborts any active tactical goal matching the type (and optionally specific object)"
"CallOn: A bot player"
"MandatoryArg: <type> : Type of tactical goal to check"
"OptionalArg: <object> : The object of the tactical goal.  Used to differentiate two different goals of the same type"
"Example: self bot_abort_tactical_goal( "seek_dropped_weapon" )"
///ScriptDocEnd
============
 */
bot_abort_tactical_goal( goal_type, object )
{
	assert( IsDefined( goal_type ) );

	if ( !IsDefined( self.tactical_goals ) )
		return;
		
	foreach( goal in self.tactical_goals )
	{
		if ( goal.type == goal_type )
		{
			if ( IsDefined(object) )
			{
				if ( IsDefined(goal.object) && (goal.object == object) )
					goal.abort = true;
			}
			else
			{
				goal.abort = true;
			}
		}
	}
}


/* 
=============
///ScriptDocBegin
"Name: bot_disable_tactical_goals()"
"Summary: Disables tactical goals for this bot, and clears out any current ones"
"CallOn: A bot player"
"Example: self bot_disable_tactical_goals())"
///ScriptDocEnd
============
 */
bot_disable_tactical_goals()
{
	self.only_allowable_tactical_goals[0] = "map_interactive_object";	// always allow these, otherwise pathing can get blocked
	foreach( goal in self.tactical_goals )
	{
		if ( goal.type != "map_interactive_object" )
			goal.abort = true;
	}
}

/* 
=============
///ScriptDocBegin
"Name: bot_enable_tactical_goals()"
"Summary: Enables tactical goals for this bot.  Note: Only needs to be called if bot_disable_tactical_goals was previously called on this bot."
"CallOn: A bot player"
"Example: self bot_enable_tactical_goals())"
///ScriptDocEnd
============
 */
bot_enable_tactical_goals()
{
	self.only_allowable_tactical_goals = undefined;
}


/* 
=============
///ScriptDocBegin
"Name: bot_melee_tactical_insertion_check()"
"Summary: Waits until enemies are nearby but not in view and drops a tac-insert."
"CallOn: A bot player"
"Example: self bot_melee_tactical_insertion_check();"
///ScriptDocEnd
============
 */
bot_melee_tactical_insertion_check() // self = bot
{
	now = GetTime();
	
	if ( !IsDefined( self.last_melee_ti_check ) || (now - self.last_melee_ti_check) > 1000 )
	{
		self.last_melee_ti_check = now;
		
		trap_item = self bot_get_ambush_trap_item( "tacticalinsertion" );
		
		if ( !IsDefined( trap_item ) )
			return false;

		if ( IsDefined( self.enemy ) && self BotCanSeeEntity( self.enemy ) )
			return false;

		myZone = GetZoneNearest( self.origin );
		if ( !IsDefined( myZone ) )
			return false;
		
		nearbyEnemyZone = BotZoneNearestCount( myZone, self.team, 1, "enemy_predict", ">", 0 );
		if ( !IsDefined( nearbyEnemyZone ) ) 
			return false;
		
		nodesAroundMe = GetNodesInRadius( self.origin, 500, 0 );
		if ( nodesAroundMe.size <= 0 )
			return false;
		
		place_node = self BotNodePick( nodesAroundMe, nodesAroundMe.size * 0.15, "node_hide" );
		if ( !IsDefined( place_node ) ) 
			return false;
		
		return self bot_set_ambush_trap( trap_item, undefined, undefined, undefined, place_node );
	}
	
	return false;
}