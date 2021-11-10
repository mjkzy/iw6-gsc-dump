#include maps\mp\_utility;
#include common_scripts\utility;

SIDE_LEFT 	= 1;
SIDE_RIGHT 	= 2;
SIDE_NONE 	= 3;

main()
{
	maps\mp\mp_fahrenheit_precache::main();
	maps\createart\mp_fahrenheit_art::main();
	maps\mp\mp_fahrenheit_fx::main();
//	maps\mp\_water::waterShallowFx();
	
	precache();
	maps\mp\_load::main();
	
	flag_init( "stop_dynamic_events" );
	
	level.rainScriptables = [];
	level.rainScriptables = GetScriptableArray( "rain_scriptable", "targetname" );
	
	level.round_start_fraction = 0;
	level.round_end_fraction = 1;
	level.storm_stage = 0; // 0 is clear. 1 is light rain fx. 2 is heavy rain fx and audio
	level.stage_1_fraction = 0.4;
	level.stage_2_fraction= 0.7;
	round_time  = getTimeLimit() * 60;
	if ( round_time <= 0 )
	{
		round_time = 600; // 10 minutes
	}
	level.assumed_match_length = round_time;
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_fahrenheit" );
	
	setdvar("r_reactiveMotionWindAmplitudeScale", .5);
	setdvar("r_reactiveMotionWindFrequencyScale", .5);

  if( ( level.ps3 ) || ( level.xenon ) )
	{
		setdvar( "sm_sunShadowScale", "0.8" ); // optimization
	}

	setdvar_cg_ng( "r_specularColorScale", 3, 9 );
	setdvar_cg_ng( "r_diffuseColorScale", 1.6, 2.2 ); 
	setdvar( "r_ssaorejectdepth", 1500); 
    setdvar( "r_ssaofadedepth", 1200); 
	setdvar( "r_sky_fog_intensity","1" );
	setdvar( "r_sky_fog_min_angle","56.6766" ); 
	setdvar( "r_sky_fog_max_angle","75" );
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	
	game[ "attackers" ] = "allies";
	game[ "defenders" ] = "axis";

	flag_init( "begin_storm" );
	
//	maps\mp\_water::waterShallowInit();
	level thread plant_anims();
	
//	level thread visiontest();
	waitframe();
	if( isRoundBased() )
	{
		compute_round_based_percentages( round_time ); // sets level.round_start_fraction, level.round_end_fraction, level.assumed_match_length
	}
	
	level thread sky_and_visionsets( level.assumed_match_length, level.round_start_fraction, level.round_end_fraction );
	level thread connect_watch();
//	level thread fx_test();
	
	/#
		level thread exploder_test();
	#/
		
	//	elevator test
	thread setupElevator();
	level thread initExtraCollision();
}

initExtraCollision()
{
	collision1 = GetEnt( "clip128x128x8", "targetname" );
	collision1Ent = spawn( "script_model", (-2352, -1938, 512) );
	collision1Ent.angles = ( 0, 0, 0);
	collision1Ent CloneBrushmodelToScriptmodel( collision1 );
	
	collision2 = GetEnt( "clip32x32x256", "targetname" );
	collision2Ent = spawn( "script_model", (176, -2420, 848) );
	collision2Ent.angles = ( 0, 0, 0);
	collision2Ent CloneBrushmodelToScriptmodel( collision2 );
	
	collision3 = GetEnt( "clip32x32x256", "targetname" );
	collision3Ent = spawn( "script_model", (176, -2452, 848) );
	collision3Ent.angles = ( 0, 0, 0);
	collision3Ent CloneBrushmodelToScriptmodel( collision3 );
	
	collision4 = GetEnt( "clip32x32x256", "targetname" );
	collision4Ent = spawn( "script_model", (666, -1824, 868) );
	collision4Ent.angles = ( 0, 0, 0);
	collision4Ent CloneBrushmodelToScriptmodel( collision4 );
	
	//11/8/13
	collision5 = GetEnt( "clip256x256x8", "targetname" );
	collision5Ent = spawn( "script_model", (-1372, -3232, 784) );
	collision5Ent.angles = ( 0, 0, 0);
	collision5Ent CloneBrushmodelToScriptmodel( collision5 );
	
	//11/13/13
	collision6 = GetEnt( "clip64x64x256", "targetname" );
	collision6Ent = spawn( "script_model", (-1928, 624, 680) );
	collision6Ent.angles = ( 0, 0, -90 );
	collision6Ent CloneBrushmodelToScriptmodel( collision6 );
	
	//11/13/13
	collision7 = GetEnt( "clip256x256x8", "targetname" );
	collision7Ent = spawn( "script_model", (-1808, 760, 648) );
	collision7Ent.angles = ( 0, 0, 0 );
	collision7Ent CloneBrushmodelToScriptmodel( collision7 );
	
	//gryphon kill trigger
	gryphonTrig1Ent = spawn( "trigger_radius", (-1216, 80, 496), 0, 864, 110 );
	gryphonTrig1Ent.radius = 864;
	gryphonTrig1Ent.height = 110;
	gryphonTrig1Ent.angles = (0,0,0);
	gryphonTrig1Ent.targetname = "gryphonDeath";
	
	//gryphon kill trigger2
	gryphonTrig2Ent = spawn( "trigger_radius", (576, -3104, 312), 0, 2240, 75 );
	gryphonTrig2Ent.radius = 2240;
	gryphonTrig2Ent.height = 75;
	gryphonTrig2Ent.angles = (0,0,0);
	gryphonTrig2Ent.targetname = "gryphonDeath";
	
	//gryphon kill trigger 3
	gryphonTrig3Ent = spawn( "trigger_radius", (-1080, -4136, 520), 0, 176, 528 );
	gryphonTrig3Ent.radius = 176;
	gryphonTrig3Ent.height = 528;
	gryphonTrig3Ent.angles = (0,0,0);
	gryphonTrig3Ent.targetname = "gryphonDeath";
	
	//gryphon kill trigger 4
	gryphonTrig4Ent = spawn( "trigger_radius", (-1184, -3808, 416), 0, 176, 96 );
	gryphonTrig4Ent.radius = 176;
	gryphonTrig4Ent.height = 96;
	gryphonTrig4Ent.angles = (0,0,0);
	gryphonTrig4Ent.targetname = "gryphonDeath";
	
	//anti foliage trigger
	antiFoliageEnt = spawn( "trigger_radius", (448, -2144, 896), 0, 400, 128 );
	antiFoliageEnt.radius = 400;
	antiFoliageEnt.height = 128;
	antiFoliageEnt.angles = (0,0,0);
	antiFoliageEnt.targetname = "antiFoliage";
	level thread watchAntiFoliage( antiFoliageEnt );
	
	//player kill trigger
	level thread killTrigger( (-194, 198, 352), 700, 256 );
	
	level thread killTrigger( (-2148, -340, 718), 96, 6 );
}

watchAntiFoliage( trigger )
{
	level endon( "game_ended" );
	
	for( ;; )
	{
		foreach ( player in level.players )
		{
			wait( 0.05 );
			
			if( !isDefined( player ) )
				continue;
			
			if( player IsTouching( trigger ) )
			{
				if ( isDefined( player.wasInAntiFoliage ) && player.wasInAntiFoliage )
					continue;

				player SetIgnoreFoliageSightingMe( 1 );
				player.wasInAntiFoliage = true;
			}
			else if( isDefined( player.wasInAntiFoliage ) && player.wasInAntiFoliage )
			{	
				player SetIgnoreFoliageSightingMe( 0 );
				player.wasInAntiFoliage = false;
			}
		}
		
		wait( .1 );
	}
}

precache()
{
}

setupElevator()
{
	if( level.gametype == "horde" )
		return;
	
	elevatorCfg = SpawnStruct();
	elevatorCfg.name = "elevator";
	elevatorCfg.doors = [];
	elevatorCfg.doors[ "floor1" ] = [ "e_door_floor1_", "e_door_elevator_1_" ];
	elevatorCfg.doors[ "floor2" ] = [ "e_door_floor2_", "e_door_elevator_2_" ];
	// need to know which doors move with the elevator, but this does create a little extra data
	elevatorCfg.doors[ "elevator" ] = [ "e_door_elevator_1_", "e_door_elevator_2_" ];
	elevatorCfg.doorMoveDist = 35;
	elevatorCfg.buttons = "elevator_button";
	elevatorCfg.trigBlockName = "elevator_door_checker";
	
	maps\mp\_elevator::init_elevator( elevatorCfg );
}

compute_round_based_percentages( round_time )
{
	// In a gametype with a winlimit, we'll set the weather based on the leading team's score as a percentage of the winlimit
	// If the gametype doesn't have a winlimit, but has a roundlimit, we'll simply set the weather based on the percentage the current round is of the roundlimit.
	// If the game has neither, we'll just use timeLimit.

	round_limit = getWatchedDvar( "roundlimit" );
	win_limit = getWatchedDvar( "winlimit" );	
	
	if( win_limit > 0 )
	{
		level.assumed_match_length = win_limit * round_time;
		if( isFirstRound() )
		{
			winning_team_round = 0;
		}
		else
		{
			winning_team_round = max( game[ "roundsWon" ][ "allies" ], game[ "roundsWon" ][ "axis" ] );
		}
		level.round_start_fraction = ( winning_team_round / win_limit );
		level.round_end_fraction = ( winning_team_round + 1 ) / win_limit;			
	}
	else if( round_limit > 0 )
	{
		level.assumed_match_length = round_limit * round_time;
		level.round_start_fraction = game[ "roundsPlayed" ] / round_limit;
		level.round_end_fraction = ( game[ "roundsPlayed" ] + 1 ) / round_limit;	
	}
}

/#
exploder_test()
{
	while(1)
	{
		SetDevDvar("test_exploder", "-1");
		while(GetDvarInt("test_exploder")<0)
		{
			wait .05;
		}
		exploder(GetDvarInt("test_exploder"));
	}
}	
#/

plant_anims()
{
	level.plants = GetScriptableArray("storm_plant", "targetname");
	
	level waittill("storm_stage_1");
	plant_set_stage_directional("stage_1", 180, 6, 1);
}

plant_set_stage_directional(stage, angle, time, rand)
{
	
	forward = AnglesToForward((0,angle,0));
	right = AnglesToRight((0,angle,0));
	
	
	min_dist = undefined;
	max_dist = undefined;
	foreach(plant in level.plants)
	{
		dist = DistToLine(plant.origin, (0,0,0), right);
		
		if( LRTest(plant.origin, (0,0,0), right ) == SIDE_RIGHT )
			dist *= -1;
	
		if(!IsDefined(min_dist) || dist < min_dist )
			min_dist = dist;
		
		if(!IsDefined(max_dist) || dist > max_dist)
			max_dist = dist;
			
		plant.temp_dist = dist;
	}
	
	
	foreach(plant in level.plants)
	{
		frac = (plant.temp_dist - min_dist)/(max_dist - min_dist);
		
		delay = time*frac;
		if(IsDefined(rand) && rand>0)
			delay += RandomFloatRange(0,rand);
		
		level thread plant_set_stage(plant, stage, delay);
	}
	
}

plant_set_stage(plant, stage, delay)
{
	if(IsDefined(delay) && delay>0)
		wait delay;
	
	plant SetScriptablePartState("storm_plant", stage);
}

rainFXStage( number )
{
	if ( !IsDefined( number ) )
	{
		number = 0;
	}
	if ( number > 2 )
	{
		number = 0;
	}
	if ( IsDefined( level.rainscriptables ) )
	{
		foreach ( scriptable in level.rainscriptables )
		{
			scriptable SetScriptablePartState( 0, number );	
		}
	}
}

visiontest()
{
	
	wait( 20 );
	
	current_stage = 0;
	MAX_STAGES	  = 2;
	sign		  = -1;
	
//	level.sky = GetEnt( "sky", "targetname" );
	level.skydome = GetEnt( "skydome", "targetname" );
	
//	while ( true )
	{
		current_stage = current_stage + 1;
		if ( current_stage >= MAX_STAGES )
		{
			current_stage = 0;
		}

		IPrintLnBold( "CHANGING VISIONSETS to:" + current_stage );
		
		foreach ( player in level.players )
		{
			player VisionSetStage( Int( min( 1, current_stage ) ), 3 );
		}
		level.skydome RotatePitch( sign * 45, 3 ); // TODO: the current skydome isn't the final size. need to readjust it to fit when it's completed.
		sign = sign * -1;
		
		rainFXStage( 1 );
		
		wait 6;
	}
}
fx_test()
{
	scriptables = [];
	scriptables = GetScriptableArray( "rain_scriptable", "targetname" );

	while ( 1 )
	{
		scriptables[ 0 ] SetScriptablePartState( 0, 0 );
		wait( 5 );
		scriptables[ 0 ] SetScriptablePartState( 0, 1 );
		wait( 5 );
		scriptables[ 0 ] SetScriptablePartState( 0, 2 );
		wait( 5 );
		scriptables[ 0 ] SetScriptablePartState( 0, 3 );
		wait( 5 );	
	}
}

sky_and_visionsets( match_duration, start_fraction, end_fraction )
{
	level.volmods = [];
	
	if(flag("stop_dynamic_events"))
		return;
	
	level endon("stop_dynamic_events");
	
	/#
	// Was only used in development so lighters could test the different weather states - no longer enabled
	//level thread watch_storm_dvar();
	#/
		
	clear_stage		= 0;
	transition_time = 10;	
	
	gameFlagWait( "prematch_done" );
	
	level.storm_stage = 0;
	
	current_fraction = start_fraction;
	if( start_fraction < level.stage_1_fraction )
	{		
		foreach ( player in level.players )
		{
			player VisionSetStage( Int( min( 1, level.storm_stage ) ), 0.1 );
		}
		remaining_time = ( level.stage_1_fraction * match_duration ) - ( current_fraction * match_duration );
		wait( remaining_time );
		current_fraction = 	level.stage_1_fraction;	
	}
	
	if( start_fraction < level.stage_2_fraction )
	{
		level notify("storm_stage_1");	
		level.storm_stage = 1;
		exploder (1);
		
		level thread storm_sound_stage("storm_sound_stage_1");
		
		level.rainEmitEnt = Spawn( "script_origin", (0,0,0) ); 
		storm_sounds_volMod("scripted2", 0 , 0);
		
		wait (0.05);
		level.rainEmitEnt playLoopSound( "amb_fah_rain_light_loop" );
		storm_sounds_volMod("scripted2", 1 , 3);
		
		sun_scriptables = GetScriptableArray("sun_scriptable","targetname");
		foreach(sun in sun_scriptables)
		{
			sun SetScriptablePartState(0, "storm_stage_1");
		}
		
		foreach ( player in level.players )
		{
			player VisionSetStage( Int( min( 1, level.storm_stage ) ), transition_time );
		}
		wait( transition_time );	
		rainFXStage( level.storm_stage );
		
		remaining_time = ( level.stage_2_fraction * match_duration ) - ( ( current_fraction * match_duration ) + transition_time );
		wait( remaining_time );		
		current_fraction = 	level.stage_2_fraction;	
	}
	level notify("storm_stage_2");
	level.storm_stage = 2;
	exploder (1);
	level thread storm_sound_stage("storm_sound_stage_2");
	
	level.heavyRainEmitEnt = Spawn( "script_origin", (0,0,0) ); 
	
	storm_sounds_volMod("scripted3", 0 , 0);
	
	wait (0.05);	
	level.heavyRainEmitEnt playLoopSound( "amb_fah_rain_heavy_loop" );
	
	storm_sounds_volMod("scripted3", 1, 3);
	
	wait (0.05);
	storm_sounds_volMod("scripted2", 0 , 3);
	
	rainFXStage( level.storm_stage );
	if( start_fraction >= level.stage_2_fraction )
	{
		foreach ( player in level.players )
		{
			player VisionSetStage( Int( min( 1, level.storm_stage ) ), 0.1 );
		}		
	}
	else
	{
		foreach ( player in level.players )
		{
			player VisionSetStage( Int( min( 1, level.storm_stage ) ), transition_time );
		}	
	}
	
}

storm_sound_stage(origin_targetname)
{
	time_between_sounds = .9;
	
	sound_origins = GetEntArray(origin_targetname, "targetname");
	foreach(org in sound_origins)
	{
		sound_name = org.script_noteworthy;
		
		
		if(isDefined(sound_name))
		{
			org PlayLoopSound(sound_name);
		}
		else
		{
			AssertMsg("Storm Sound @"+ org.origin+" missing script_noteworthy sound name.");
		}
		
		wait time_between_sounds;
	}
}

storm_sounds_volMod(volmod, value, time)
{
	level.volmods[volmod] = value;
	
	foreach(player in level.players)
	{
		player SetVolMod(volmod, value, time);
	}
}

/#
watch_storm_dvar()
{	
	dvar_name = "storm_stage";
	default_stage = 0;
	SetDevDvarIfUninitialized( dvar_name, default_stage );
	while( 1 )
	{		
		value = GetDvarInt( dvar_name, default_stage );
		if( value == level.storm_stage )
		{
			waitframe();
		}
		else
		{
		
			if( ( value > 2 ) || (value < 0 ) )
			{
				println( "Invalid storm stage. Valid values are 0, 1, 2." );			
			}
			else
			{
				SetDvar( dvar_name, value );
				level.storm_stage = value;
				rainFXStage( level.storm_stage );
				foreach ( player in level.players )
				{
					player VisionSetStage( Int( min( 1, level.storm_stage ) ), 0.1 );
				}
				level notify( "stop_dynamic_events" ); // if you're messing with the storm value, we stop the game's natural progression			
			}
			waitframe();
		}
	}
}
#/

rotate_skydome( start_fraction, end_fraction, rotation_time )
{
	min_angle = 0;
	max_angle = -70;
	
	start_fraction = min( 1, start_fraction / level.stage_1_fraction );
	end_fraction = min( 1, end_fraction / level.stage_1_fraction );
	
	level.skydome RotatePitch( 180, 0.1 );
	wait( 0.1 );
	level.skydome RotatePitch( start_fraction * max_angle, 0.1 );
	gameFlagWait( "prematch_done" );
	
	level.skydome RotatePitch( ( end_fraction - start_fraction ) * max_angle, max( 0.1, ( end_fraction - start_fraction ) * rotation_time ) );
}

connect_watch()
{
	while ( 1 )
	{
		level waittill( "connected", player );
		if ( IsDefined( level.storm_stage ) )
		{
			player VisionSetStage( Int( min( 1, level.storm_stage ) ), 0.1 );
		}
		
		foreach(volmod,value in level.volmods)
		{
			player SetVolMod(volmod, value);
		}	
	}
}

////////////////////////////////////////////////////////////////////////////////////
// Area Of The Parallel Pipid (2D)
//
// Given two more points, this function calculates the area of the parallel pipid
// formed.
//
// Note: This function CAN return a negative "area" if (C) is above or right of
// (A) and (B)...  We do not take the abs because the sign of the "area" is needed
// for the left right test (see below)
//
//
//               ___---( ... )
//        (A)---/        /
//        /             /
//       /             /
//      /             /
//     /      ___---(B)
//    (C)---/
//
////////////////////////////////////////////////////////////////////////////////////
AreaParallelPipid(A, B, C)
{
	return ((A[0]*B[1] - A[1]*B[0]) + 
		    (B[0]*C[1] - C[0]*B[1]) + 
			(C[0]*A[1] - A[0]*C[1]));
}


////////////////////////////////////////////////////////////////////////////////////
// Area Of The Triangle (2D)
//
// Given two more points, this function calculates the area of the triangle formed.
//
//        (A)
//        /  \__
//       /      \__
//      /          \_
//     /      ___---(B)
//    (C)----/
//
////////////////////////////////////////////////////////////////////////////////////
AreaTriange(A, B, C)
{
	return (AreaParallelPipid(A, B, C) * 0.5);
}


////////////////////////////////////////////////////////////////////////////////////
// The Left Right Test (2D)
//
// Given a line segment (Start->End) and a tolerance for *right on*, this function
// evaluates which side the point is of the line.  (Side_Left in this example)
//
//
//
//          (Test)        ___---/(End)
//                 ___---/
//          ___---/
//  (Start)/
//  
////////////////////////////////////////////////////////////////////////////////////
LRTest(Test, Start, End, Tolerance)
{	
	if(!IsDefined(Tolerance))
	   Tolerance = 0.0;
	   
	Area = AreaParallelPipid(Start, End, Test);
	if (Area>Tolerance)
	{
		return SIDE_LEFT;
	}
	if (Area<(Tolerance*-1))
	{
		return SIDE_RIGHT;
	}
	return SIDE_NONE;
}

////////////////////////////////////////////////////////////////////////////////////
// Project
//
// Standard projection function.  Take (V) and project it onto the vector
// (U).  Imagine drawing a line perpendicular to U from the endpoint of the (V)
// Vector.  That then becomes the new vector.
//
// The values returned are the [NewVector, Scale]. The scale of the new vector with respect to 
// the one passed to the function.  If the scale is less than (1.0) then the new vector is 
// shorter than (U). If the scale is negative, then the vector is going in the opposite 
// direction of (U).
//
//               _  (U)
//               /|
//             /                                        _ (New)
//           /                      RESULTS->           /|
//         /                                          /
//       /    __\ (V)                          	    /
//     /___---  /                                 /
//
////////////////////////////////////////////////////////////////////////////////////
Project(V, U)
{
	Scale = (VectorDot(V,U) / LengthSquared(U));
	return [U*Scale, Scale];
}

////////////////////////////////////////////////////////////////////////////////////
// Project To Line
//
// This function takes two other points in space as the start and end of a line
// segment and projects the (this) point onto the line defined by (Start)->(Stop)
//
// RETURN VALUES:
//   (-INF, 0.0)  : (this) landed on the line before (Start)
//   (0.0, 1.0)   : (this) landed in the line segment between (Start) and (Stop)
//   (1.0, INF)   : (this) landed on the line beyond (End)
//
//             (Stop)
//               /
//             /
//           o _
//         /  |\
//       /     (Point)
//     / 
// (Start)
//
////////////////////////////////////////////////////////////////////////////////////
ProjectToLine(Point, Start, Stop)
{
	Point -= Start;
	[Point, Scale] = Project(Point, Stop - Start);
	Point += Start;
	return [Point, Scale];
}

////////////////////////////////////////////////////////////////////////////////////
// Project To Line Seg 
//
// Same As Project To Line, Except It Will Clamp To Start And Stop
////////////////////////////////////////////////////////////////////////////////////
ProjectToLineSeg(Point, Start, Stop)
{
	[Point, Scale] = ProjectToLine(Point, Start, Stop);
	if (Scale<0.0)
	{
		Point = Start;
	}
	else if (Scale>1.0)
	{
		Point = Stop;
	}
	return [Point, Scale];
}

////////////////////////////////////////////////////////////////////////////////////
// Distance To Line
//
// Uses project to line and than calculates distance to the new point
////////////////////////////////////////////////////////////////////////////////////
DistToLine(Point, Start, Stop)
{
	[PointOnLine, Scale] = ProjectToLine(Point, Start, Stop);

	return Distance(PointOnLine, Point);
}
