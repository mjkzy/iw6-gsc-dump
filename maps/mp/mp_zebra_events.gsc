#include common_scripts\utility;
#include maps\mp\_utility;

////////////////////////
// solar panel
////////////////////////

#using_animtree( "animated_props" );

//solar_panels()
//{
//	solar_panels_precache();
//
//	wait 0.05;	
//	waitframe();
//	
//	//Init and collect relevant objects:	
//	flag_init( "solar_panel01_event" );
//	solar_panel01_moving_root = solar_panel_group( "solar_panel_01" );
//	solar_panel01_resting_root = solar_panel_group( "solar_panel01_rest_clip" );  // Trying to account for turning on any clipping where the panel lands.  Not sure if this is the right way to do it yet.
//	
//	eventTime = GetAnimLength( %mp_zebra_solar_panel_0_crash );
//	
//	//Hide post-crash stuff
//	if ( IsDefined( solar_panel01_resting_root ) )
//	{
//		foreach(ent in solar_panel01_resting_root.clip)
//		{
//			ent solar_panel_clip_hide();
//		}
//		
//		foreach(ent in solar_panel01_resting_root.linked)
//		{
//			ent Hide();
//		}
//	}
//
//
//	//Wait between 30% - 50% of match:
//	//solar_panel_wait( RandomFloatRange(.3, .5) );
//	
//	//For testing, only wait 5% of match:
//	solar_panel_wait( RandomFloatRange(.05, .06) );
//	
//	//
//	//Trigger event on solar panel01
//	//
//	//Kill players touching kill trigger:
//	kill_trigger = GetEnt("solar_panel_kill_trigger", "targetname");
//	if ( IsDefined( kill_trigger ) )
//	{
//		foreach ( character in level.characters )
//		{
//			if ( character IsTouching( kill_trigger ) )
//			{
//				character _suicide();
//			}
//		}
//	}
//	
//	foreach(ent in solar_panel01_moving_root.clip)
//	{
//		ent solar_panel_clip_hide();
//	}
//	
//	//Play animations on objects with animation defined:
//	foreach ( ent in solar_panel01_moving_root.linked )
//	{
//		if ( IsDefined( ent.animation ) )
//		{
//			ent ScriptModelPlayAnimDeltaMotion( ent.animation );
//		}
//	}
//	
//	//
//	//Wait for animation:
//	//
//	wait ( eventTime );
//	
//	//
//	//Hide moving model
//	//
//	foreach ( ent in solar_panel01_moving_root.linked )
//	{
//		ent Hide();
//	}	
//
//	//Show "final" model and clip:
//	if ( IsDefined( solar_panel01_resting_root ) )
//	{
//		foreach(ent in solar_panel01_resting_root.clip)
//		{
//			ent solar_panel_clip_show();
//		}
//		
//		foreach(ent in solar_panel01_resting_root.linked)
//		{
//			ent Show();
//		}
//	}
//}
//
//// 
//solar_panels_precache()
//{
//	//Precache animations here (must be precached in .csv also!)
//	PrecacheMpAnim( "mp_zebra_solar_panel_0_crash" );
//	PrecacheMpAnim( "mp_zebra_solar_panel_1_crash" );
//}
//
//solar_panel_group( targetname )
//{
//	//Return a parent entity, initialized with all the associated child objects:
//	struct = GetStruct(targetname, "targetname");
//	if(!IsDefined(struct))
//		return undefined;
//	
//	parent = Spawn("script_model", struct.origin);
//	parent SetModel("tag_origin");
//	
//	parent.clip = []; //brushmodels
//	parent.linked = []; //entities
//	
//	ents = GetEntArray(struct.target, "targetname");
//	foreach(ent in ents)
//	{
//		if(ent.classname == "script_brushmodel")
//		{			
//			parent.clip[parent.clip.size] = ent;
//		}
//		else
//		{
//			parent.linked[parent.linked.size] = ent;
//		}
//	}
//	
//	return parent;
//}
//
//solar_panel_clip_hide()
//{
//	if(self is_dynamic_path())
//		self ConnectPaths();
//	
//	if(self is_ai_sight_line())
//		self SetAISightLineVisible(false);
//	
//	self thread maps\mp\_movers::script_mover_attached_items_clear();
//	
//	self.old_contents = self SetContents(0);
//	self NotSolid();
//	self Hide();
//}
//
//solar_panel_clip_show()
//{
//	self Solid();
//	self SetContents(self.old_contents);
//	self Show();
//	
//	if(self is_dynamic_path())
//		self DisconnectPaths();
//	
//	if(self is_ai_sight_line())
//		self SetAISightLineVisible(true);
//}
//
//solar_panel_wait(game_frac)
//{
//	level endon("solar_panel01_event");
//	
//	if(IsDefined(game_frac) && !level.createFX_enabled)
//		level thread solar_panel_wait_time(game_frac);
//	level waittill("solar_panel01_event");
//}
//
//solar_panel_wait_time(game_frac)
//{
//	level endon("solar_panel01_event");
//	wait_game_percent_complete( game_frac );
//	level notify("solar_panel01_event");
//}

wait_game_percent_complete( time_percent, score_percent )
{
	if(!IsDefined(score_percent))
		score_percent = time_percent;

	gameFlagWait( "prematch_done" );
	
	score_limit = getScoreLimit();
	time_limit	= getTimeLimit() * 60;
	
	ignore_score = false;
	ignore_time = false;
	
	if( ( score_limit <= 0 ) && ( time_limit <= 0 ) )
	{
		ignore_score = true;
		time_limit = 10*60;
	}
	else if ( score_limit <= 0 )
	{
		ignore_score = true;
	}
	else if( time_limit <= 0 )
	{
		ignore_time = true;
	}
	
	time_threshold = time_percent * time_limit;
	score_threshold = score_percent * score_limit;

	higher_score = get_highest_score();
	timePassed = (getTime() - level.startTime) / 1000;
	
	if( ignore_score )
	{
		while( timePassed < time_threshold )
		{
			wait( 0.5 );
			timePassed = (getTime() - level.startTime) / 1000;
		}
	}
	else if( ignore_time )
	{
		while( higher_score < score_threshold )
		{
			wait( 0.5 );
			higher_score = get_highest_score();
		}
	}
	else
	{
		while( ( timePassed < time_threshold ) && ( higher_score < score_threshold ) )
		{
			wait( 0.5 );
			higher_score = get_highest_score();
			timePassed = (getTime() - level.startTime) / 1000;
		}		
	}
}

get_highest_score()
{
	highestScore = 0;
	if( level.teamBased )
	{
		if( isDefined( game[ "teamScores" ] ) )
		{
			highestScore = game["teamScores"]["allies"];
			if( game["teamScores"]["axis"] > highestScore )
			{
				highestScore = game["teamScores"]["axis"];
			}
		}
	}
	else
	{
		if(IsDefined(level.players))
		{
			foreach( player in level.players )
			{
				if( IsDefined( player.score ) && player.score > highestScore )
					highestScore = player.score;
			}
		}
	}
	return highestScore;
}

is_ai_sight_line()
{
	return IsDefined(self.spawnflags) && self.spawnflags&2;
}

is_dynamic_path()
{
	return IsDefined(self.spawnflags) && self.spawnflags&1;
}