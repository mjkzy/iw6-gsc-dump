#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;
#include maps\mp\bots\_bots_personality;

INFECTED_BOT_MELEE_DESPERATION_TIME = 3000;
INFECTED_BOT_MAX_NODE_DIST_SQ = (96*96);//larger to account for multiple bots grouping up on a node
INFECTED_BOT_MELEE_MIN_DIST_SQ = (48*48);

main()
{
	// This is called directly from native code on game startup after the _bots::main() is executed
	setup_callbacks();
	setup_bot_infect();
}

setup_callbacks()
{
	level.bot_funcs["gametype_think"] = ::bot_infect_think;
	level.bot_funcs["should_pickup_weapons"] = ::bot_should_pickup_weapons_infect;
}

setup_bot_infect()
{
	level.bots_gametype_handles_class_choice = true;
	level.bots_ignore_team_balance = true;
	level.bots_gametype_handles_team_choice = true;
	
	thread bot_infect_ai_director_update();
}

bot_should_pickup_weapons_infect()
{
	if ( level.infect_choseFirstInfected && self.team == "axis" )
		return false;	// An infected person was chosen and i'm on the infected team
	
	return maps\mp\bots\_bots::bot_should_pickup_weapons();
}

bot_infect_think()
{
	self notify( "bot_infect_think" );
	self endon(  "bot_infect_think" );

	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self childthread bot_infect_retrieve_knife();
	
	while ( true )
	{
		if ( level.infect_choseFirstInfected )
		{
			if ( self.team == "axis" && self BotGetPersonality() != "run_and_gun" )
			{
				// Infected bots should be run and gun
				self bot_set_personality("run_and_gun");
			}
		}
		
		if ( self.bot_team != self.team )
			self.bot_team = self.team;	// Bot became infected so update self.bot_team (needed in infect.gsc)
		
		if ( self.team == "axis" )
		{
			result = self bot_melee_tactical_insertion_check();
			if( !IsDefined( result ) || result )
				self BotClearScriptGoal();
		}
		
		self [[ self.personality_update_function ]]();
		
		wait(0.05);
	}
}

SCR_CONST_INFECT_HIDING_CHECK_TIME = 5000;

bot_infect_ai_director_update()
{
	level notify("bot_infect_ai_director_update");
	level endon("bot_infect_ai_director_update");
	level endon("game_ended");
	
	while(1)
	{
		infected_players = [];
		non_infected_players = [];
		foreach( player in level.players )
		{
			if ( !IsDefined(player.initial_spawn_time) && player.health > 0 && IsDefined(player.team) && (player.team == "allies" || player.team == "axis") )
				player.initial_spawn_time = GetTime();
			
			if ( IsDefined(player.initial_spawn_time) && GetTime() - player.initial_spawn_time > 5000 )
			{
				if ( !IsDefined( player.team ) )
					continue;
				
				if ( player.team == "axis" )
					infected_players[infected_players.size] = player;
				else if ( player.team == "allies" )
					non_infected_players[non_infected_players.size] = player;
			}
		}
		
		if ( infected_players.size > 0 && non_infected_players.size > 0 )
		{
			all_bots_are_infected = true;
			foreach( non_infected_player in non_infected_players )
			{
				if ( IsBot(non_infected_player) )
					all_bots_are_infected = false;
			}
			
			if ( all_bots_are_infected )
			{
				// Every player in non_infected_players is a human
				foreach ( player in non_infected_players )
				{
					if ( !IsDefined(player.last_infected_hiding_time) )
					{
						player.last_infected_hiding_time = GetTime();
						player.last_infected_hiding_loc = player.origin;
						player.time_spent_hiding = 0;
					}
					
					if ( GetTime() >= player.last_infected_hiding_time + SCR_CONST_INFECT_HIDING_CHECK_TIME )
					{
						player.last_infected_hiding_time = GetTime();
						dist_to_last_hiding_loc_sq = DistanceSquared(player.origin, player.last_infected_hiding_loc);
						player.last_infected_hiding_loc = player.origin;
						if ( dist_to_last_hiding_loc_sq < 300 * 300 )
						{
							player.time_spent_hiding += SCR_CONST_INFECT_HIDING_CHECK_TIME;
							if ( player.time_spent_hiding >= 20000 )
							{
								infected_players_sorted = get_array_of_closest(player.origin, infected_players );
								foreach ( infected_player in infected_players_sorted )
								{
									if ( IsBot(infected_player) )
									{
										goal_type = infected_player BotGetScriptGoalType();
										if ( goal_type != "tactical" && goal_type != "critical" )
										{
											infected_player thread hunt_human( player );
											break;
										}
									}
								}
							}
						}
						else
						{
							player.time_spent_hiding = 0;
							player.last_infected_hiding_loc = player.origin;
						}
					}
				}
			}
		}
				
		wait(1.0);
	}
}

hunt_human( player_hunting )
{
	self endon("disconnect");
	self endon("death");
	
	self BotSetScriptGoal( player_hunting.origin, 0, "critical" );
	self bot_waittill_goal_or_fail();
	self BotClearScriptGoal();
}

bot_infect_retrieve_knife()
{
	if ( self.team == "axis" )
	{
		self.can_melee_enemy_time = 0;
		self.melee_enemy = undefined;
		self.melee_enemy_node = undefined;
		self.melee_enemy_new_node_time = 0;
		self.melee_self_node = undefined;
		self.melee_self_new_node_time = 0;
		
		// In Infected mode, all bots should be capable of throwing a knife...
		throwKnifeChance = self BotGetDifficultySetting( "throwKnifeChance" );
		if ( throwKnifeChance < 0.25 )
		{
			self BotSetDifficultySetting( "throwKnifeChance", 0.25 );
		}
		self BotSetDifficultySetting( "allowGrenades", 1 );
		self BotSetFlag( "path_traverse_wait", true ); // use manners when using traversals
		
		// If an infected bot has been without his throwing knife for some time, magically give it back to him
		while ( true )
		{	
			if ( self HasWeapon( "throwingknife_mp" ) )
			{
				if ( IsGameParticipant( self.enemy ) )
				{
					time = GetTime();
					if ( !IsDefined( self.melee_enemy ) || self.melee_enemy != self.enemy )
					{
						// New melee enemy, reset tracking info on him
						self.melee_enemy = self.enemy;
						self.melee_enemy_node = self.enemy GetNearestNode();
						self.melee_enemy_new_node_time = time;
					}
					else
					{
						meleeDistSq = squared(self BotGetDifficultySetting( "meleeDist" ));
						// Track how long it's been since we were in melee range of the enemy
						if ( DistanceSquared( self.enemy.origin, self.origin ) <= meleeDistSq )
						{
							self.can_melee_enemy_time = time;
						}
						
						// Track how long you and the enemy have not changed nodes
						melee_enemy_node = self.enemy GetNearestNode();
						melee_self_node = self GetNearestNode();

						if ( !IsDefined( self.melee_enemy_node ) || self.melee_enemy_node != melee_enemy_node )
						{
							self.melee_enemy_new_node_time = time;
							self.melee_enemy_node = melee_enemy_node;
						}
						if ( !IsDefined( self.melee_self_node ) || self.melee_self_node != melee_self_node )
						{
							self.melee_self_new_node_time = time;
							self.melee_self_node = melee_self_node;
						}
						else if ( DistanceSquared( self.origin, self.melee_self_node.origin ) > INFECTED_BOT_MAX_NODE_DIST_SQ )
						{
							// Haven't actually reached the node
							self.melee_self_at_same_node_time = time;
						}
						
						// See if all conditions are met - can't reach the enemy and neither of you are moving
						if ( self.can_melee_enemy_time+INFECTED_BOT_MELEE_DESPERATION_TIME < time )
						{
							// Can't melee enemy right now
							if ( self.melee_self_new_node_time+INFECTED_BOT_MELEE_DESPERATION_TIME < time )
							{
								// I've been at the same node for a while
								if ( self.melee_enemy_new_node_time+INFECTED_BOT_MELEE_DESPERATION_TIME < time )
								{
									// Enemy has been at the same node for a while
									if ( bot_infect_angle_too_steep_for_knife_throw( self.origin, self.enemy.origin ) )
									{
										// Might be standing right above or below this guy, need to step back before we throw!
										self bot_queued_process( "find_node_can_see_ent", ::bot_infect_find_node_can_see_ent, self.enemy, self.melee_self_node );
									}
									if ( !(self GetAmmoCount( "throwingknife_mp" ) ) )
									{
										self SetWeaponAmmoClip( "throwingknife_mp", 1 );
									}
									// Don't do this again for a while or we get a new enemy
									self waitForTimeOrNotify( 30, "enemy" );
									self BotClearScriptGoal();
								}
							}
						}
					}
				}
			}
			wait(0.25);
		}
	}
}

bot_infect_angle_too_steep_for_knife_throw( testOrigin, testDest )
{
	if ( abs( testOrigin[2]-testDest[2] ) > 56.0 && Distance2DSquared( testOrigin, testDest ) < INFECTED_BOT_MELEE_MIN_DIST_SQ )
		return true;
	
	return false;
}

bot_infect_find_node_can_see_ent( targetEnt, startNode )
{
	if ( !IsDefined( targetEnt ) || !IsDefined( startNode ) )
		return;

	at_begin_node = false;
	if ( IsSubStr( startNode.type, "Begin" ) )
		at_begin_node = true;
	
	neighborNodes = GetLinkedNodes( startNode );
	if ( IsDefined( neighborNodes ) && neighborNodes.size )
	{
		neighborNodesRandom = array_randomize( neighborNodes );
		foreach( nNode in neighborNodesRandom )
		{
			if ( at_begin_node && IsSubStr( nNode.type, "End" ) )
			{
				// Don't try to go to my node's end node
				continue;
			}
			
			if ( bot_infect_angle_too_steep_for_knife_throw( nNode.origin, targetEnt.origin ) )
			{
				// Angle would be too steep from here, too (NOTE: we use origin compares here since that's how we got into this function above)
				continue;
			}

			eyeOfs = self GetEye()-self.origin;
			start = nNode.origin + eyeOfs;
			
			end = targetEnt.origin;
			if ( IsPlayer( targetEnt ) )
			{
				end = targetEnt getStanceCenter();
			}
			
			if ( SightTracePassed( start, end, false, self, targetEnt ) )
			{
				yaw = VectorToYaw( end-start );
				self BotSetScriptGoalNode( nNode, "critical", yaw );
				self bot_waittill_goal_or_fail( 3.0 );
				return;
			}
			wait( 0.05 );
		}
	}
}