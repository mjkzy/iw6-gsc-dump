#include common_scripts\utility;

intro_sequence_precache()
{
	flag_init( "intro_sequence_complete" );
	
	switch( level.script )
	{
	case "mp_alien_town":
		town_intro_precache();
		break;
	default:
		break;
	}
}

play_intro_sequence( player )
{
	switch( level.script )
	{
	case "mp_alien_town":
		level thread alien_town_intro( player );
		break;
	default:
		break;
	}
}

////////////////////////////////////////////////////////////
//                    mp_alien_town
////////////////////////////////////////////////////////////
town_intro_precache()
{
	alien_town_intro_precache_props();
	
	alien_town_intro_precache_characters();
}

#using_animtree("multiplayer");
alien_town_intro_precache_characters()
{
	PrecacheMpAnim( "alien_town_intro_boss" );
	PrecacheMpAnim( "alien_town_intro_pilot" );
}

#using_animtree("animated_props");
alien_town_intro_precache_props()
{
	PrecacheMpAnim( "alien_town_intro_chopper" );
	//PrecacheMpAnim( "alien_town_intro_chopper_idle" );
	//PrecacheMpAnim( "alien_town_intro_chopper_leave" );
	PrecacheMpAnim( "alien_town_intro_drill" );	
}

alien_town_intro( player )
{
	level waittill( "introscreen_over" );
	CHOPPER_START_POSITION = ( 2830.455, -398.027, 707.026 );  //<TODO J.C.> Maybe mark this position in map with script struct?
	                                                           //            Thay way, we can eliminate the need for helibrush.    
	//CHOPPER_IDLE_LOOP_TIMES = 1;
	
	//add helicopter collision
	helibrush = GetEnt( "helicoptercoll", "targetname" );
	
	heli = SpawnHelicopter( player, CHOPPER_START_POSITION, helibrush.angles + (0,180,0) , "nh90_alien_intro", "tag_origin_vehicle" );
	assert( IsDefined( heli ) );
	
	//spawn helicopter
	IntroHeli = spawn("script_model", CHOPPER_START_POSITION );
	IntroHeli.angles = helibrush.angles;
	IntroHeli SetModel( "vehicle_nh90_interior2" );
	thread sfx_intro_heli_takeoff(heli);
	heli setmodel( "tag_origin_vehicle" );
	
	level.intro_heli = IntroHeli;
	
	//spawn and setup models
	boss_model  = spawn_model( "mp_body_us_rangers_assault_a_urban", IntroHeli,  "TAG_GUY1", ( 0, 0, 0 ) );
	boss_model SetModel( "mp_body_us_rangers_assault_a_urban" );
	boss_head = spawn_model( "head_mp_head_a",    boss_model, "J_spine4", ( 0, 0, 0 ) );
	pilot_model = spawn_model( "mp_body_us_rangers_assault_a_urban", IntroHeli,  "tag_driver", ( 0, 0, 0 ) );
	pilot_head = spawn_model( "head_mp_head_a", pilot_model,  "J_spine4", ( 0, 0, 0 ) );
	drill_model = spawn_model( "mp_laser_drill",      IntroHeli,  "TAG_GUY1", ( 0, 0, 0 ) );

	thread sfx_intro_npc_foley(boss_model);

	//play helicopter intro animations
	IntroHeli   ScriptModelPlayAnimDeltaMotion("alien_town_intro_chopper");
	pilot_model ScriptModelPlayAnim("alien_town_intro_pilot");
	pilot_head ScriptModelPlayAnim("alien_town_intro_pilot");
	boss_model  ScriptModelPlayAnim("alien_town_intro_boss");
	boss_head  ScriptModelPlayAnim("alien_town_intro_boss");
	drill_model ScriptModelPlayAnim("alien_town_intro_drill");	

	thread sfx_intro_heli_drop_drill(drill_model);
	
	helibrush thread wait_to_delete();
	
	wait( GetAnimLength( %alien_town_intro_drill ) );
	
	drill_model ScriptModelClearAnim();
	drill_model Delete();

	level thread mp_alien_town_intro_drill_setup();

	//<TODO J.C.> Waiting for final asset here.  Will spawn the actual drill to match the end position of the drill anim.
	
	//play helicopter loop anim
	/*
	for( i = 0; i < CHOPPER_IDLE_LOOP_TIMES; i++ )
	{
		IntroHeli ScriptModelPlayAnimDeltaMotion("alien_town_intro_chopper_idle");
		wait( GetAnimLength( %alien_town_intro_chopper_idle ) );
	}
	*/
	
	//play helicopter leaving anim
	//IntroHeli ScriptModelPlayAnimDeltaMotion("alien_town_intro_chopper_leave");
	level thread kill_heli ( heli );
	wait( GetAnimLength( %alien_town_intro_chopper) );
	
	//clear the anim before deletion
	pilot_model ScriptModelClearAnim();
	pilot_head ScriptModelClearAnim();
	boss_model  ScriptModelClearAnim();
	boss_head  ScriptModelClearAnim();
	IntroHeli   ScriptModelClearAnim();
	
	//clean up
	boss_model  Delete();
	boss_head  Delete();
	pilot_model Delete();
	pilot_head Delete();
	IntroHeli   Delete();
}

wait_to_delete()
{
	level endon( "game_ended" );
	CONST_HELI_COLLISION_DELETE_TIME = 16.5;  // wait for heli to leave the ground high enough
	
	wait ( CONST_HELI_COLLISION_DELETE_TIME );  
	self delete();
}

kill_heli ( heli )
{
	wait ( 10 );
	heli Vehicle_SetSpeed( 50,10 );
	heli SetVehGoalPos ( heli.origin + (0,0,1600 ));	
	wait ( 10 );
	heli delete();
}


spawn_model( model_name, attach_to_entity, tag_name, spawn_angle_offset )
{
	new_model = spawn( "script_model", ( 0, 0, 0 ) );
	new_model SetModel( model_name );
	new_model.origin = attach_to_entity GetTagOrigin( tag_name );
	new_model.angles = attach_to_entity GetTagAngles( tag_name ) + spawn_angle_offset;
	new_model LinkTo( attach_to_entity, tag_name );	
	
	return new_model;
}

intro_sequence_enabled()
{
	/# 
	if ( maps\mp\alien\_debug::StartPointEnabled() )
		return false;
	#/
	if ( maps\mp\alien\_utility::is_chaos_mode() )
		return false;
			
	return ( getDvarInt( "scr_alien_intro", 1 ) == 1 );
}

mp_alien_town_intro_drill_setup()
{
	level.initial_drill_origin = ( 2834.272, -243.002, 524.068 );
	level.initial_drill_angles = ( 0.995, -103.877, 1.287 );
	
	level notify ( "spawn_intro_drill" );
	
	wait( 8 );
	
	flag_set( "intro_sequence_complete" );
}

sfx_intro_heli_takeoff(heli)
{	
	heli Vehicle_TurnEngineOff();
	heli PlaySound("alien_heli_intro_takeoff");
}

sfx_intro_heli_drop_drill(drill)
{
	//wait 8;
	wait( GetAnimLength( %alien_town_intro_drill ) - 0.5);
	//IPrintLnBold("Drill");
	drill PlaySound("alien_heli_drill_drop");
}

sfx_intro_npc_foley(npc)
{
	wait 2.53;
	npc PlaySound("alien_heli_npc_foley");
}
