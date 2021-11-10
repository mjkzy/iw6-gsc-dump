#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\bots\_bots_strategy;

main()
{
	setup_callbacks();
	thread bot_siege_manager_think();
	setup_bot_siege();
	
	/#
	thread bot_siege_debug();
	#/
}

setup_callbacks()
{
	level.bot_funcs["gametype_think"]					= ::bot_siege_think;
}

setup_bot_siege()
{

	level.bot_gametype_precaching_done = true;
}

/#
bot_siege_debug()
{
	while( !IsDefined(level.bot_gametype_precaching_done) )
		wait(0.05);
	
	while(1)
	{
		if ( GetDvarInt("bot_debugSiege", 0) == 1 )
		{
			foreach ( player in level.participants )
			{
				if ( IsAI(player) && IsDefined( player.goalFlag ) && isReallyAlive(player) )
				{
					line( player.origin, player.goalFlag.origin, (0, 255, 0), 1, false, 1 );
				}
			}
		}
		
		wait(0.05);
	}
}
#/

bot_siege_manager_think()
{
	level.siege_bot_team_need_flags = [];
	
	gameFlagWait( "prematch_done" );
		
	for( ;; )
	{
		// Check for dead team mates
		level.siege_bot_team_need_flags = [];
		foreach( player in level.players )
		{
			if( !isReallyAlive( player ) && player.hasSpawned )
			{
				// If there are any dead team mates, we need to cap a flag.
				if( player.team != "spectator" && player.team != "neutral" )
				{
					level.siege_bot_team_need_flags[ player.team ] = true;
				}
			}
		}
		
		// Check flag status
		flagCounts = [];
		foreach( flag in level.flags )
		{
			team = flag.useObj maps\mp\gametypes\_gameobjects::getOwnerTeam();
			if( team != "neutral" )
			{
				if( !IsDefined( flagCounts[ team ] ) )
					flagCounts[ team ] = 1;
				else
					flagCounts[ team ]++;
			}
		}
		
		foreach( team, count in flagCounts )
		{
			if( count >= 2 )
			{
				// If we have 2 flags, let the enemy team know it needs to cap flags
				enemyTeam = getOtherTeam( team );
				level.siege_bot_team_need_flags[ enemyTeam ] = true;
			}
		}
		
		
		
		wait( 1.0 );
	}
}

bot_siege_think()
{
	self notify( "bot_siege_think" );
	self endon(  "bot_siege_think" );

	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while( !IsDefined(level.bot_gametype_precaching_done) )
		wait(0.05);
	while( !IsDefined(level.siege_bot_team_need_flags) )
		wait(0.05);
	
	self BotSetFlag("separation",0);	// don't slow down when we get close to other bots
	self BotSetFlag("use_obj_path_style", true);

	for( ;; )
	{
		
		if( IsDefined( level.siege_bot_team_need_flags[ self.team ] ) && level.siege_bot_team_need_flags[ self.team ] )
		{
			self bot_choose_flag();
		}
		else
		{
			if( IsDefined( self.goalFlag ) )
			{
				if( self maps\mp\bots\_bots_util::bot_is_defending() )
					self bot_defend_stop();
				self.goalFlag = undefined;
			}
		}
		
		wait( 1.0 );
	}
}

bot_choose_flag()
{
	goalFlag = undefined;
	shortestDistSq = undefined;
	// Find the nearest flag not owned by the bot's team.
	foreach( flag in level.flags )
	{
		team = flag.useObj maps\mp\gametypes\_gameobjects::getOwnerTeam();
		if( team != self.team )
		{
			distToFlagSq = DistanceSquared( self.origin, flag.origin );
			if( !IsDefined( shortestDistSq ) || distToFlagSq < shortestDistSq )
			{
				shortestDistSq = distToFlagSq;
				goalFlag = flag;
			}
		}
	}
	
	// Assign the flag as the goal
	if( IsDefined( goalFlag ) )
	{
		if( !IsDefined( self.goalFlag ) || self.goalFlag != goalFlag )
		{
			self.goalFlag = goalFlag;
			bot_capture_point( goalFlag.origin, 100 );
		}
	}
}