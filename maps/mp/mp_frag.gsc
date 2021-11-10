#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

// DOOR STATES
STATE_DOOR_CLOSED  = 0;
STATE_DOOR_CLOSING = 1;
STATE_DOOR_OPEN	   = 2;
STATE_DOOR_OPENING = 3;
STATE_DOOR_PAUSED  = 4;

// ENT SPAWNFLAGS
SPAWNFLAG_DYNAMIC_PATH = 1;
SPAWNFLAG_AI_SIGHT_LINE = 2;

main()
{
	maps\mp\mp_frag_precache::main();
	maps\createart\mp_frag_art::main();
	maps\mp\mp_frag_fx::main();
	
	precache();
	
	level.dynamicSpawns = ::filter_spawn_point;
	
	maps\mp\_load::main();	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_frag" );
	setdvar("r_ssaoFadeDepth", 1024);
	
	if ( !level.console )
	{
		SetDvar( "r_lightGridEnableTweaks", 1 );
		SetDvar( "r_lightGridIntensity"	  , 1.33 );
				   //   dvar_name 			    current_gen_val    next_gen_val   
		setdvar_cg_ng( "r_diffuseColorScale" , 1.37				, 1 );
		setdvar_cg_ng( "r_specularcolorscale", 3				, 9 );
	}
	else
	{
		SetDvar( "r_lightGridEnableTweaks", 1 );
		SetDvar( "r_lightGridIntensity"	  , 1.33 );
		SetDvar( "r_diffuseColorScale"	  , 1.37 );
		SetDvar( "r_specularcolorscale"	  , 2 );   
	}
	
	if( !is_gen4() )
	{
		SetDvar( "sm_sunShadowScale", "0.8" );
	}
	
	game[ "attackers" ] = "allies";
	game[ "defenders" ] = "axis";
		
	flag_init( "chain_broken" );
	flag_init( "container_open" );
	flag_init( "warehouse_open" );
	flag_init( "drop_ladder" );
	flag_init( "ladder_down" );
 	// these next two could probably be combined, but I'm keeping them separate in case we find we want to do something with the middle condition (hopper neither open nor closed while moving)
	flag_init( "hopper_closed" );
	flag_init( "hopper_open" );
	flag_init( "pop_up_targets_ready" );
	flag_init( "hopper_open_initially" );
	
 	flag_set( "hopper_closed" );

	maps\mp\gametypes\_door::door_system_init( "door_switch" );

	level thread generic_shootable_double_doors( "left_gate", "left_gate", "j_prop_1", "right_gate", "j_prop_2", "lock", "gate_clip", "gate_trigger", "mp_frag_metal_door_closed_loop", "mp_frag_metal_door_open", "mp_frag_metal_door_open_out",
											    "mp_frag_metal_door_chain", "frag_gate_iron_open", undefined, undefined, "chain_gate_trigger_damage", "chain_broken", false, undefined );	
	level thread bot_underground_trapped_watch();
	level thread bot_shootable_target_watch( "gate_trigger", "near_gate_volume", "chain_broken" );

//	level thread generic_shootable_double_doors( "container_door_right", "container_door_right", "j_prop_1", "container_door_left", "j_prop_2", undefined, "container_door_clip", "container_door_trigger", undefined, "mp_frag_crate_open", "mp_frag_crate_open",
//											    undefined, "frag_gate_iron_open", "container_trigger_damage", "container_open", true );
//	level thread bot_shootable_target_watch( "container_door_trigger", "near_container_volume", "container_open" );
	
	level thread generic_shootable_double_doors( "warehouse_door_right", "warehouse_door_right", "j_prop_1", "warehouse_door_left", "j_prop_2", "warehouse_door_lock", "warehouse_door_clip", "warehouse_door_trigger", undefined, "mp_frag_large_door_open", "mp_frag_large_door_open",
											    "mp_frag_large_door_chain_idle", "scn_breach_swingindoor_left", "scn_breach_swingindoor_right", "scn_breach_swingindoor_lock", "warehouse_trigger_damage", "warehouse_open", true, "warehouse_door_handle" );
	level thread bot_shootable_target_watch( "warehouse_door_trigger", "near_warehouse_volume", "warehouse_open" );
	
	level thread shootable_ladder();
	level thread bot_shootable_target_watch( "ladder_damage_trigger", "near_ladder_volume", "ladder_down" );
	
	level thread sprinkler_watch();
	
	level initExtraCollision();
}

initExtraCollision()
{
	collision128 = GetEnt( "clip128x128x8", "targetname" );
	blocker = Spawn( "script_model", (832, 1938, 466) );
	blocker.angles = ( 0, 0, -90 );
	blocker CloneBrushmodelToScriptmodel( collision128 );
	
	//get on roof fix
	collision2 = GetEnt( "player128x128x8", "targetname" );
	collision2Ent = Spawn( "script_model", (1144, 1938, 466) );
	collision2Ent.angles = ( 0, 0, -90 );
	collision2Ent CloneBrushmodelToScriptmodel( collision2 );
	
	model1 = spawn( "script_model", (-571, 1414.5, 193) );
	model1 setModel( "mp_frag_pipe_4x128_metal_painted_01" );
	model1.angles = (90,0,0);
}

precache()
{
	PrecacheMpAnim( "mp_frag_metal_door_chain" );
	PrecacheMpAnim( "mp_frag_metal_door_closed_loop" );
	PrecacheMpAnim( "mp_frag_metal_door_open" );
	PrecacheMpAnim( "mp_frag_metal_door_open_loop" );
	PrecacheMpAnim( "mp_frag_metal_door_open_out" );
	PrecacheMpAnim( "mp_frag_metal_door_open_out_loop" );
	
	PrecacheMpAnim( "mp_frag_large_door_chain_idle" );
	PrecacheMpAnim( "mp_frag_large_door_open" );
	PrecacheMpAnim( "mp_frag_large_door_open_loop" );
	PrecacheMpAnim( "mp_frag_large_door_closed_loop" );
	PrecacheMpAnim( "mp_frag_crate_open" );
	PrecacheMpAnim( "mp_frag_crate_open_loop" );
	PrecacheMpAnim( "mp_frag_crate_closed_loop" );
	
	PrecacheMpAnim( "mp_frag_ladder_fall" );
	PrecacheMpAnim( "mp_frag_ladder_fall_start_loop" );	
}

trigger_wait_damage( trigger, damage_notify )
{
	self endon( damage_notify );
	trigger waittill( "damage", amount, attacker, direction_vec, point, type );	
	self notify( damage_notify, amount, attacker, direction_vec, point, type );
}

generic_shootable_double_doors( anim_node_targetname, left_gate_targetname, left_gate_tag, right_gate_targetname, right_gate_tag, lock_targetname, gate_clip_targetname, gate_triggers_targetname,
							   closed_loop_anim, open_in_anim, open_out_anim, lock_idle_anim, open_sound_left, open_sound_right, open_sound_lock, damage_notify, open_flag, affect_pathing, extra_delete )
{
	left_gate	 = GetEnt( left_gate_targetname, "targetname" );
	right_gate	 = GetEnt( right_gate_targetname, "targetname" );
	if( IsDefined( lock_targetname ) )
	{
		lock = GetEnt( lock_targetname, "targetname" );
	}
	else
	{
		lock = undefined;
	}
	gate_clip	 = GetEnt( gate_clip_targetname, "targetname" );
	gate_triggers = GetEntArray( gate_triggers_targetname, "targetname" );	

	anim_node_ref = GetEnt( anim_node_targetname, "targetname" );
	gate_anim_node = Spawn( "script_model", anim_node_ref.origin );
	if( IsDefined( anim_node_ref.angles ) )
	{
		gate_anim_node.angles = anim_node_ref.angles;
	}
	else
	{
		gate_anim_node.angles = (0, 0, 0);
	}
	gate_anim_node SetModel( "generic_prop_raven" );
	waitframe();
	if( IsDefined( closed_loop_anim ) )
	{
		gate_anim_node ScriptModelPlayAnim( closed_loop_anim );
	}
	waitframe();
	
	if( IsDefined( left_gate_tag ) )
	{
		left_gate LinkTo( gate_anim_node, left_gate_tag );
	}
	else
	{
		left_gate LinkTo( gate_anim_node, "j_prop_1" );
	}
	if( IsDefined( right_gate_tag ) )
	{
		right_gate LinkTo( gate_anim_node, right_gate_tag );
	}
	else
	{
		right_gate LinkTo( gate_anim_node, "j_prop_2" );
	}
	
	waitframe();
	
	if( affect_pathing )
	{
		gate_clip DisconnectPaths();
	}
	else
	{
		gate_clip ConnectPaths();
	}
	centerpoint = (0,0,0);
	num_trigs = 0;
	foreach( gate_trigger in gate_triggers )
	{
		if( IsDefined( gate_trigger.target ) )
		{
			add_to_bot_damage_targets( gate_trigger );
		}
		centerpoint += gate_trigger.origin;
		num_trigs++;
	}
	centerpoint = centerpoint/num_trigs;
	
	if( IsDefined( lock ) && IsDefined( lock_idle_anim ) )
	{
		lock ScriptModelPlayAnim( lock_idle_anim );
	}
	
	left_gate SetCanDamage( false );
	left_gate SetCanRadiusDamage( false );
	
	right_gate SetCanDamage( false );
	right_gate SetCanRadiusDamage( false );
	
	if( IsDefined( lock ) )
	{
		lock SetCanDamage( false );
		lock SetCanRadiusDamage( false );
	}
	
	gate_clip SetCanDamage( false );
	gate_clip SetCanRadiusDamage( false );
	
	foreach( gate_trigger in gate_triggers )
	{
		thread trigger_wait_damage( gate_trigger, damage_notify );
	}
	
	self waittill( damage_notify, amount, attacker, direction_vec, point, type );

	if ( IsExplosiveDamageMOD( type ) )
	{
		direction_vec = centerpoint - point;
	}
	open_in = ( direction_vec[ 1 ] < 0 );
		
	if( IsDefined( extra_delete ) )
	{
		delete_ents = GetEntArray( extra_delete, "targetname" );
		foreach( ent in delete_ents )
		{
			ent Delete();
		}
	}
	
	foreach( gate_trigger in gate_triggers )
	{
		remove_from_bot_damage_targets( gate_trigger );
		gate_trigger Delete();
	}
	flag_set( open_flag );
	
	if( IsDefined( open_sound_left ) )
	{
		left_gate PlaySound( open_sound_left );
	}
	if( IsDefined( open_sound_right ) )
	{
		right_gate PlaySound( open_sound_right );
	}
	if( IsDefined( lock ) && IsDefined( open_sound_lock ) )
	{
		playSoundAtPos( lock.origin, open_sound_lock );
	}	
	
	if ( open_in )
	{
		gate_anim_node ScriptModelPlayAnimDeltaMotion( open_in_anim );
	}
	else
	{
		gate_anim_node ScriptModelPlayAnimDeltaMotion( open_out_anim );
	}
	
	waitframe();
	
	if( IsDefined( lock ) )
	{
		lock Delete();
	}
	
	wait( 0.3 );

	if( affect_pathing )
	{
		gate_clip ConnectPaths();
	}
	
	waitframe();
	gate_clip Delete();
}

hide_ai_sight_brushes()
{
	ai_sight_brush_array = GetEntArray( "ai_sight_brush", "targetname" );
	
	foreach ( ai_sight_brush in ai_sight_brush_array )
	{
		ai_sight_brush NotSolid();
		ai_sight_brush Hide();
		ai_sight_brush SetAISightLineVisible( false );
	}
}

set_button( button_name, turn_on )
{
	if ( turn_on )
	{
		name = button_name + "_on";
	}
	else
	{
		name = button_name + "_off";
	}	
	
	self.in_use = turn_on;
	self SetModel( name );
		
	if ( IsDefined( self.fx_ent ) )
		self.fx_ent Delete();
	
	if ( IsDefined( level._effect[ name ] ) && IsDefined( self.fx_origin ) && IsDefined( self.fx_fwd ) )
	{
		self.fx_ent = SpawnFx( level._effect[ name ], self.fx_origin, self.fx_fwd );
		TriggerFX( self.fx_ent );
	}
}

pop_up_targets_set_buttons( on )
{
	if ( IsDefined( self.button_toggles ) )
	{
		foreach ( button in self.button_toggles )
		{
			button set_button( "mp_frag_button", on );
		}
	}
}

get_linked_structs()
{
	array = [];

	if ( IsDefined( self.script_linkTo ) )
	{
		linknames = get_links();
		for ( i	= 0; i < linknames.size; i++ )
		{
			ent = getstruct( linknames[ i ], "script_linkname" );
			if ( IsDefined( ent ) )
			{
				array[ array.size ] = ent;
			}
		}
	}

	return array;
}

notify_struct_on_use( wait_struct )
{
	self waittill( "trigger" );
	wait_struct notify( "trigger" );
}

hopper_wheel_init( triggerName )
{
	buttons = GetEntArray( triggerName, "targetname" );
	
	foreach ( button in buttons )
	{
		if( IsDefined( button.target ) )
		{
			doors = GetEntArray( button.target, "targetname" );
			
			foreach( door in doors )
			{
				if( IsDefined( door.script_noteworthy ) && IsSubStr( door.script_noteworthy, "wheel" ) )
				{
					door thread hopper_wheel_think( button );
				}
			}
		}
	}
}

hopper_wheel_think( button )
{
	wheel			   = self;
	rotation_direction = 1;
	
	if ( wheel.script_noteworthy == "counterclockwise_wheel" )
	{
		rotation_direction = -1;
	}	

	bigTime = 10000;
	
	wheel_moving = false;
	
	while ( 1 )
	{
		button waittill_any( "door_state_done", "door_state_interrupted" );
	
		if ( wheel_moving == false )
		{
			if ( ( button.statecurr == STATE_DOOR_OPEN ) || ( button.statecurr == STATE_DOOR_OPENING ) )
			{
				wheel RotateVelocity( ( 0, 0, rotation_direction * -706 ), bigTime ); // wheel diameter: 30; distance travelled is approx 185
			}
			else
			{
				wheel RotateVelocity( ( 0, 0, rotation_direction * 706 ), bigTime ); // wheel diameter: 30; distance travelled is approx 185
			}
			wheel_moving = true;
		}
		else
		{
			wheel RotateVelocity( ( 0, 0, 0 ), 0.1 ); // wheel diameter: 30; distance travelled is approx 185
			wheel_moving = false;
		}
	}
}

hopper_wheel( initially_clockwise, movetime )
{
	rotation_direction = 1;
	
	if ( initially_clockwise )
	{
		rotation_direction = -1;
	}

	self RotateRoll( rotation_direction * 706, movetime ); // wheel diameter: 30; distance travelled is approx 185
}

bot_underground_trapped_watch()
{	
	escape_triggers	   = GetEntArray( "gate_trigger", "targetname" );
	underground_volume = GetEnt( "underground_volume", "targetname" );
	
	while ( !flag( "chain_broken" ) )
	{
		while ( flag( "hopper_closed" ) && !flag( "chain_broken" ) )
		{			
			if ( IsDefined( level.participants ) )
			{
				foreach ( participant in level.participants )
				{
					if ( IsAI( participant ) && participant IsTouching( underground_volume ) )
					{
						escape_triggers[0] set_high_priority_target_for_bot( participant );
					}
				}
			}						
			wait( 0.5 );
		}
		while ( flag( "hopper_open" ) && !flag( "chain_broken" ) )
		{		
			wait( 0.5 );
		}
	}
}

filter_spawn_point( spawnPoints )
{
	underground_height = 32;
	
	valid_spawns = [];
	foreach ( spawnPoint in spawnPoints )
	{
		if ( flag( "hopper_closed" ) && ( spawnPoint.origin[ 2 ] < underground_height ) )
		{
			continue;
		}
		valid_spawns[ valid_spawns.size ] = spawnPoint;
	}
		
	return valid_spawns;
}

// special-case code for special cases...
special_hopper_open()
{
	hopper_trigger = GetEntArray( "hopper_triggers", "targetname" );
	
	flag_wait( "pop_up_targets_ready" );

	wait( 1 );
	
	flag_set( "hopper_open_initially" );
	
	hopper_trigger[ 0 ] notify( "trigger" );
	
	wait( 1 );
	
	flag_clear( "hopper_open_initially" );
	
}

shootable_ladder()
{
	//disconnect the ladder nodes
	bottom_node = GetNode( "ladder_bottom_node", "targetname" );
	top_node = GetNode( "ladder_top_node", "targetname" );
	DisconnectNodePair( top_node, bottom_node );	
	
	ladder_model = GetEnt( "scripted_ladder", "targetname" );
	ladder_brush = GetEnt( "ladder_brush_bottom", "targetname" );
	
//	ladder_brush.old_contents = ladder_brush SetContents( 0 );
	ladder_brush NotSolid();
	ladder_brush trigger_off();
//	ladder_model NotSolid();
	ladder_brush SetCanDamage( true );
	ladder_model SetCanDamage( true );
	
	ladder_down_pos = getstruct( "ladder_down_loc", "targetname" );
	ladder_up_pos	= getstruct( "ladder_up_loc", "targetname" );
	
	ladder_link = Spawn( "script_model", ladder_down_pos.origin );
	ladder_link SetModel( "tag_origin" );
	ladder_model LinkTo( ladder_link );

	waitframe();
	
	ladder_link MoveTo( ladder_up_pos.origin, 0.1, 0.0, 0.0 );	
	wait( 0.2 );
	
	ladder_model Unlink();
	
	ladder_anim_node = Spawn( "script_model", ladder_up_pos.origin );
	ladder_anim_node SetModel( "generic_prop_raven" );

	waitframe();
	
	ladder_link Delete();
	
	ladder_model LinkTo( ladder_anim_node, "j_prop_1" );

	waitframe();
	
	ladder_trigger = GetEnt( "ladder_damage_trigger", "targetname" );
	add_to_bot_damage_targets( ladder_trigger );
	
	damageable_array = [];
	damageable_array[0] = ladder_model;
	damageable_array[1] = ladder_trigger;

//	 ENABLE THIS BLOCK TO REPRO THE LADDER ANIM FAILING TO PLAY
/*	
	while( 1 )
	{
	
		waittill_any_of_these_take_damage( damageable_array, "drop_ladder" );
		waitframe();
		
		IPrintLnBold( " LADDER TRIGGER DAMAGED " );
		
		ladder_anim_node ScriptModelPlayAnimDeltaMotion( "mp_frag_ladder_fall" );
		
		wait( 3.0 );	
		ladder_anim_node ScriptModelPlayAnimDeltaMotion( "mp_frag_ladder_fall_start_loop" );	
		flag_clear( "drop_ladder" );
	}
*/
	
	waittill_any_of_these_take_damage( damageable_array, "drop_ladder" );

	ladder_anim_node ScriptModelPlayAnim( "mp_frag_ladder_fall" );
	
	remove_from_bot_damage_targets( ladder_trigger );
	ladder_trigger Delete();
	ladder_anim_node PlaySound( "detpack_explo_metal" );
	
	flag_set( "ladder_down" );	
	
	ConnectNodePair( top_node, bottom_node );
	
	// waiting until ladder area is clear before making solid to avoid players getting stuck.
	
	ladder_test_volume = GetEnt( "ladder_brush_volume", "targetname" );
	ladder_volume_occupied = true;
	
	while( ladder_volume_occupied )
	{
		ladder_volume_occupied = false;
		foreach( character in level.characters )
		{
			if( character IsTouching( ladder_test_volume ) )
			{
				ladder_volume_occupied = true;
				break;
			}
		}
		waitframe();
	}
	
	ladder_brush trigger_on();
	ladder_brush Solid();
//	ladder_brush SetContents( ladder_brush.old_contents );	
	
}

waittill_any_of_these_take_damage( damageable_array, flag_name )
{
	foreach( damageable_item in damageable_array )
	{
		damageable_item thread waittill_damage_flag_set( flag_name );
	}
	
	flag_wait( flag_name );
}

waittill_damage_flag_set( flag_name )
{
	level endon( "drop_ladder" );
	self waittill( "damage", amount, attacker, direction_vec, point, type );
	flag_set( "drop_ladder" );	
}

bot_shootable_target_watch( trigger_targetname, awareness_volume_targetname, endon_flag )
{	
	shootable_triggers = GetEntArray( trigger_targetname, "targetname" );
	awareness_volume  = GetEnt( awareness_volume_targetname, "targetname" );
	
	while ( !flag( endon_flag ) )
	{
		if ( IsDefined( level.participants ) )
		{
			foreach ( participant in level.participants )
			{
				if ( IsAI( participant ) && participant IsTouching( awareness_volume ) )
				{
					shootable_triggers[0] set_high_priority_target_for_bot( participant );
				}
			}
		}						
		wait( 1.0 );
	}
}

sprinkler_watch()
{
	underground_damage_triggers = GetEntArray( "underground_damage_trigger", "targetname" );

	sprinkler_type_one = GetEntArray( "sprinkler_type_one", "targetname" );
	sprinkler_type_two = GetEntArray( "sprinkler_type_two", "targetname" );	
	
	while( 1 )
	{
		waittill_any_ents( underground_damage_triggers[0], "trigger", underground_damage_triggers[1], "trigger" );
		exploder( 1 );		// sprinkler duration is about 11 seconds
		wait( 1.0 );
		foreach( sprinkler in sprinkler_type_one )
		{
			sprinkler PlayLoopSound( "emt_frag_water_spray_01_int_lp" );
		}
		foreach( sprinkler in sprinkler_type_two )
		{
			sprinkler PlayLoopSound( "emt_frag_water_spray_02_int_lp" );
		}		
		wait( 11 );
		foreach( sprinkler in sprinkler_type_one )
		{
			sprinkler StopLoopSound();
		}
		foreach( sprinkler in sprinkler_type_two )
		{
			sprinkler StopLoopSound();
		}
	}
}