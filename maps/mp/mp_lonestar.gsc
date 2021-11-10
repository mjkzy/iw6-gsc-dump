#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_lonestar_precache::main();
	maps\createart\mp_lonestar_art::main();
	maps\mp\mp_lonestar_fx::main();
	
	level thread maps\mp\_movers::main();
	level thread maps\mp\_movable_cover::init();
	level thread quakes();
	
	maps\mp\_load::main();
	thread maps\mp\_fx::func_glass_handler(); // Text on glass
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_lonestar" );

  // SSAO Optimization  
  SetDvar( "r_ssaofadedepth", 384 );
  SetDvar( "r_ssaorejectdepth", 1152 );

	//           dvar_name 			    current_gen_val    next_gen_val   
	setdvar_cg_ng( "r_specularColorScale", 3				, 15 );
	setdvar_cg_ng( "r_diffuseColorScale" , 1.25				, 3.5 );

	SetDvar( "r_lightGridEnableTweaks", 1 );
	SetDvar( "r_lightGridIntensity"	  , 1.33 );
	
	if ( level.ps3 )
	{
		SetDvar( "sm_sunShadowScale", "0.5" ); // ps3 optimization
		SetDvar( "sm_sunsamplesizenear", ".19" );
	}
	else if ( level.xenon )
	{
		SetDvar( "sm_sunShadowScale", "0.8" ); // ps3 optimization
		SetDvar( "sm_sunsamplesizenear", ".25" );
	}
	else
	{
		SetDvar( "sm_sunShadowScale", "0.9" ); // optimization
	}
		
	game[ "attackers" ] = "allies";
	game[ "defenders" ] = "axis";
	
	level thread exploder_triggers();
	
	/#
		level thread exploder_test();
	#/
	
	//level thread location_callouts();
	level thread initExtraCollision();
}

initExtraCollision()
{
	collision1 = GetEnt( "clip128x128x128", "targetname" );
	collision1Ent = spawn( "script_model", (-714, -2022, 102) );
	collision1Ent.angles = ( 0, 0, 0);
	collision1Ent CloneBrushmodelToScriptmodel( collision1 );
	
	collision2 = GetEnt( "clip128x128x128", "targetname" );
	collision2Ent = spawn( "script_model", (-828, -2160, 80) );
	collision2Ent.angles = ( 0, 0, 0);
	collision2Ent CloneBrushmodelToScriptmodel( collision2 );
	
	collision3 = GetEnt( "clip256x256x256", "targetname" );
	collision3Ent = spawn( "script_model", (-2048, -336, 112) );
	collision3Ent.angles = ( 0, 0, 0);
	collision3Ent CloneBrushmodelToScriptmodel( collision3 );
	
	collision4 = GetEnt( "player32x32x256", "targetname" );
	collision4Ent = spawn( "script_model", (-572, -822, 276) );
	collision4Ent.angles = ( 0, 0, 0);
	collision4Ent CloneBrushmodelToScriptmodel( collision4 );
	
	collision5 = GetEnt( "clip64x64x128", "targetname" );
	collision5Ent = spawn( "script_model", (-990, -209.5, 323) );
	collision5Ent.angles = ( 90, 0, 0);
	collision5Ent CloneBrushmodelToScriptmodel( collision5 );
}

/#
exploder_test()
{
	dvar_name	  = "test_exploder";
	default_value = -1;
	SetDevDvarIfUninitialized( dvar_name, default_value );
	while ( 1 )
	{
		value = GetDvarInt( dvar_name, default_value );
		if ( value < 0 )
		{
			waitframe();
		}
		else
		{
			exploder( value );
			SetDvar( dvar_name, default_value );
		}
	}
}	
#/

exploder_triggers()
{
	triggers = GetEntArray( "exploder_trigger", "targetname" );
	foreach ( trigger in triggers )
	{
		if ( !IsDefined( trigger.script_index ) )
			continue;
		
		trigger thread exploder_trigger_run();
	}
}

exploder_trigger_run()
{
	self endon( "death" );

	sounds_for_exploder = [];
	sounds_for_exploder[3] = "scn_mp_lonestar_bat";
	sounds_for_exploder[4] = "scn_mp_lonestar_bat";
	
	while ( 1 )
	{
		self waittill( "trigger" );
		exploder( self.script_index );
		
		if(IsDefined(sounds_for_exploder[self.script_index]) && IsDefined(self.target))
		{
			sound_origins = getstructarray(self.target, "targetname");
			foreach(org in sound_origins)
			{
				playSoundAtPos(org.origin, sounds_for_exploder[self.script_index]);
			}
		}
		
		wait RandomFloatRange( 60 * 1, 60 * 2 );
	}
}

#using_animtree( "animated_props" );
quakes()
{
	/#
	if ( GetDvar( "r_reflectionProbeGenerate" ) == "1" )
	{
		return;
	}
	#/
		
	//precache
	PrecacheMpAnim( "mp_lonestar_bat_effect_path" );
	level._effect[ "bats" ] = LoadFX( "fx/animals/bats_swarm" );
	
	level._effect[ "gas_leak" ]		 = LoadFX( "fx/fire/heat_lamp_distortion" );
	level._effect[ "gas_leak_fire" ] = LoadFX( "fx/maps/mp_lonestar/mp_ls_gaspipe_fire" );
	
	level.quake_anims								  = [];
	level.quake_anims[ "ground_collapse"			] = "mp_lonestar_road_slab_quake";
	level.quake_anims[ "ground_collapse_start_idle" ] = "mp_lonestar_road_slab_quake_idle";
	level.quake_anims[ "pole_fall_on_police_car"	] = "mp_lonestar_police_car_crush_pole";
	level.quake_anims[ "police_car_hit_by_pole"		] = "mp_lonestar_police_car_crush_car";
	level.quake_anims[ "wire_shake"					] = "mp_lonestar_earthquake_wire_shake";
	level.quake_anims[ "hanging_cable_loop"			] = "mp_lonestar_hanging_wire_loop";
	level.quake_anims[ "hanging_cable"				] = "mp_lonestar_hanging_wire_earthquake";
	
	level.quake_anims_ref					 = [];
	level.quake_anims_ref[ "hanging_cable" ] = %mp_lonestar_hanging_wire_earthquake;
	
	foreach ( key, value in level.quake_anims )
	{
		PrecacheMpAnim( value );
	}
	
	level.pre_quake_scriptables = [];
	level.quake_scriptables		= [];
	add_quake_scriptable( "qauke_script_hanging_wire", GetAnimLength( %mp_lonestar_hanging_wire_earthquake ), false );
	add_quake_scriptable( "qauke_script_telephone_wire", GetAnimLength( %mp_lonestar_earthquake_wire_shake ), true );
	
	level.quake_anim_funcs[ "police_car_hit_by_pole" ]		= [];
	level.quake_anim_funcs[ "police_car_hit_by_pole" ][ 0 ] = ::quake_event_pole_fall_on_car;
	
	level.quake_anim_init_funcs[ "police_car_hit_by_pole" ]		 = [];
	level.quake_anim_init_funcs[ "police_car_hit_by_pole" ][ 0 ] = ::quake_event_pole_fall_on_car_init;
	
	waitframe();
	
	if ( level.createFX_enabled )
		return;
	
	start_time	 = GetTime();
	quake_events = quake_events();
	
	quake = getstruct( "quake", "targetname" );
	
	num_quakes = 3;
	
	
	quake_event_lists = [];
	list_order		  = [];
	for ( i = 0;i < num_quakes;i++ )
	{
		quake_event_lists[ i ] = [];
		list_order[ i ]		   = i;
	}
	
	quake_events = array_randomize( quake_events );
	foreach ( event in quake_events )
	{
		if ( event.count > 0 )
		{
			list_order = array_shift( list_order );
		}
		for ( i = 0;i < list_order.size && event.count!= 0;i++ )
		{
			o													  = list_order[ i ];
			quake_event_lists[ o ][ quake_event_lists[ o ].size ] = event;
			event.count--;
		}
	}
	quake_event_lists = array_randomize( quake_event_lists );
	
	time_limit = max( 5, getTimeLimit() ); //Handle short or forever matches
	quake_times = [];
	for ( i = 0;i < num_quakes;i++ )
	{
		min_time = ( 1 / num_quakes ) * ( i + 0.2 );
		max_time = ( 1 / num_quakes ) * ( i + 0.8 );				
		quake_times[ i ] = RandomFloatRange( min_time, max_time ) * time_limit * 60;
	}
	
	for ( i = 0;i < num_quakes;i++ )
	{
		time = quake_times[ i ];
		earthqauke_wait( time );
		quake thread quake_run( quake_event_lists[ i ] );
	}
}

earthqauke_wait( time )
{
	level endon( "earthquake_start" );
	/#
		level thread earthqauke_wait_dvar();
	#/
	
	wait time;
	level notify( "earthquake_start" );
}

/#
earthqauke_wait_dvar()
{
	level endon( "earthquake_start" );
	
	dvar_name	  = "trigger_earthquake";
	default_value = 0;
	SetDevDvarIfUninitialized( dvar_name, default_value );
	while ( 1 )
	{
		
		value = GetDvarInt( dvar_name, default_value );
		if ( value == default_value )
		{
			waitframe();
		}
		else
		{
			SetDvar( dvar_name, default_value );
			level notify( "earthquake_start" );
		}
	}
}

#/

array_shift( array )
{
	new_array = [];
	for ( i = 0;i < array.size - 1;i++ )
	{
		new_array[ i ] = array[ i + 1 ];
	}
	new_array[ new_array.size ] = array[ 0 ];
	return new_array;
}

add_quake_scriptable( targetname, animTime, is_pre_quake )
{
	scriptables = GetScriptableArray( targetname, "targetname" );
	
	foreach ( thing in scriptables )
	{
		thing.quake_scriptable_time = animTime;
	}
	
	if ( is_pre_quake )
	{
		level.pre_quake_scriptables = array_combine( level.pre_quake_scriptables, scriptables );
	}
	else
	{
		level.quake_scriptables = array_combine( level.quake_scriptables, scriptables );
	}
	
}

quake_run_scriptables( scriptables )
{
	foreach ( scriptable in scriptables )
	{
		scriptable SetScriptablePartState( "main", "quake" );
		
		scriptable delayCall( scriptable.quake_scriptable_time, ::SetScriptablePartState, "main", "idle" );
	}
}

quake_run( quake_events )
{
	quake_run_scriptables( level.pre_quake_scriptables );
	
	// start the wire shake 4 seconds before the screen shake
	wire_event = undefined;
	foreach ( event in quake_events )
	{
		if ( IsDefined( event.script_noteworthy ) && ( event.script_noteworthy == "wires" ) )
		{
			wire_event = event;
			wire_event thread quake_event_trigger( 0, wire_event quake_event_wait() );
			break;
		}
	}
	
	wait( 4.0 );
	
	quake_run_scriptables( level.quake_scriptables );

	duration = RandomFloatRange( 7, 9 );
	
	playSoundAtPos( ( 0, 0, 0 ), "mp_earthquake_lr" );
	Earthquake( 0.3, duration, self.origin, self.radius );
	
	//VFX Trigger
	exploder( 1 );
	
	foreach ( event in quake_events )
	{
		if ( !IsDefined( wire_event ) || event != wire_event )
		{
			event thread quake_event_trigger( duration, event quake_event_wait() );
		}
	}
}

quake_event_trigger( duration, waitTime )
{
	if ( IsDefined( waitTime ) && waitTime > 0 )
		wait waitTime;
	
	self notify( "trigger", duration );
}

quake_event_wait()
{
	if ( IsDefined( self.script_wait ) )
		return self.script_wait;
	else if ( IsDefined( self.script_wait_min ) && IsDefined( self.script_wait_max ) )
		return RandomFloatRange( self.script_wait_min, self.script_wait_max );
	
	return 0;
}

quake_event_trigger_wait( func, var1, var2, var3, var4, var5, var6 )
{
	while ( 1 )
	{
		self waittill( "trigger", quakeTime );
		if ( IsDefined( var6 ) )
			self thread [[ func ]]( quakeTime, var1, var2, var3, var4, var5, var6 );
		else if ( IsDefined( var5 ) )
			self thread [[ func ]]( quakeTime, var1, var2, var3, var4, var5 );
		else if ( IsDefined( var4 ) )
			self thread [[ func ]]( quakeTime, var1, var2, var3, var4 );
		else if ( IsDefined( var3 ) )
			self thread [[ func ]]( quakeTime, var1, var2, var3 );
		else if ( IsDefined( var2 ) )
			self thread [[ func ]]( quakeTime, var1, var2 );
		else if ( IsDefined( var1 ) )
			self thread [[ func ]]( quakeTime, var1 );
		else
			self thread [[ func ]]( quakeTime );
	}
}

quake_events()
{
	events = getstructarray( "quake_event", "targetname" );
	array_thread( events, ::quake_event_init );
	return events;
}

quake_event_init()
{
	ents = GetEntArray( self.target, "targetname" );
	
	if(IsDefined(self.script_noteworthy))
	{
		extra_targets = StrTok( self.script_noteworthy, "," );
		foreach(script_noteworthy_target in extra_targets)
		{
			extra_target_ents = GetEntArray(script_noteworthy_target, "targetname");
			ents = array_combine(ents, extra_target_ents);
		}
	}
	
	foreach ( ent in ents )
	{
		if ( ent maps\mp\_movers::script_mover_is_script_mover() )
		{
			self thread quake_event_trigger_wait( ::quake_event_send_notify, ent, "trigger" );
			continue;
		}
		
		quake_event_init_ent( ent );
		
		if ( !IsDefined( ent.script_noteworthy ) )
			continue;
	
		tokens = StrTok( ent.script_noteworthy, "," );
		
		foreach ( token in tokens )
		{
			switch ( token )
			{
				case "ground_collapse":
					self thread quake_event_trigger_wait( ::quake_event_move_to, ent, 1, undefined, 1, 0, true );
					break;
				case "shake":
					self thread quake_event_trigger_wait( ::quake_event_shake, ent );
					break;
				case "hurt":
					if ( !IsDefined( ent.script_damage ) )
						ent.script_damage = 25;
					if ( !IsDefined( ent.script_delay ) )
						ent.script_delay = 1;
					self thread quake_event_trigger_wait( ::quake_event_hurt, ent, ent.script_delay, ent.script_damage );
					break;
				case "hurt_fire":
					self thread quake_event_trigger_wait( ::quake_event_hurt, ent, 1, 25 );
					break;
				case "delete":
					self thread quake_event_trigger_wait( ::quake_event_delete, ent );
					break;
				case "animate":
					if ( IsDefined( ent.script_animation ) )
					{
						if ( IsDefined( level.quake_anim_init_funcs[ ent.script_animation ] ) )
						{
							foreach ( func in level.quake_anim_init_funcs[ ent.script_animation ] )
							{
								level thread [[ func ]]( ent );
							}
						}
						
						if ( IsDefined( level.quake_anims[ ent.script_animation + "_start_idle" ] ) )
						{
							ent ScriptModelPlayAnim( level.quake_anims[ ent.script_animation + "_start_idle" ]  );
						}
						
						if ( IsDefined( level.quake_anims[ ent.script_animation + "_loop" ] ) )
						{
							ent ScriptModelPlayAnim( level.quake_anims[ ent.script_animation + "_loop" ]  );
						}
							
						if ( IsDefined( level.quake_anims[ ent.script_animation ] ) )
						{
							self thread quake_event_trigger_wait( ::quake_event_animate, ent, ent.script_animation );
						}
					}
					break;
				case "show":
					ent Hide();
					self thread quake_event_trigger_wait( ::quake_event_show, ent );
					break;
				case "move_to_end":
					move_time = 1;
					if ( IsDefined( ent.script_parameters ) )
						move_time = Float( ent.script_parameters );
					self thread quake_event_trigger_wait( ::quake_event_move_to, ent, .5, ent.script_delay );
					break;
				case "gas_leak":
					if ( IsDefined( self.target ) )
					{
						ent.fx_location	 = getstruct( ent.target, "targetname" );
						ent.hurt_trigger = GetEnt( ent.target, "targetname" );
						
						self thread quake_event_trigger_wait( ::quake_event_gas_leak, ent );
					}
					break;
				case "sound":
					self thread quake_event_trigger_wait( ::quake_event_playSound, ent );
					break;
				default:
					break;
			}
		}
	}
	
	structs = getstructarray( self.target, "targetname" );
	foreach ( struct in structs )
	{
		if ( !IsDefined( struct.script_noteworthy ) )
			continue;
	
		switch ( struct.script_noteworthy )
		{
			case "fx":
				if ( !IsDefined( struct.script_parameters ) )
					struct.script_parameters = "gas_leak";
				if ( !IsDefined( struct.angles ) )
					struct.angles = ( 0, 0, 0 );
				
				fx_ent = SpawnFx( level._effect[ struct.script_parameters ], struct.origin, AnglesToForward( struct.angles ) );
				self thread quake_event_trigger_wait( ::quake_event_fx, fx_ent );
				break;
			case "exploder":
				exploder_id = struct.script_prefab_exploder;
				if ( !IsDefined( exploder_id ) )
					exploder_id = struct.script_exploder;
				if ( IsDefined( exploder_id ) )
				{
					self thread quake_event_trigger_wait( ::quake_event_exploder, exploder_id );
				}
				break;
			case "sound":
				self thread quake_event_trigger_wait( ::quake_event_playSound, struct );
				break;
			default:
				break;
		}
	}
	
	nodes = GetVehicleNodeArray( self.target, "targetname" );
	foreach ( node in nodes )
	{
		if ( !IsDefined( node.script_noteworthy ) )
			continue;
	
		switch ( node.script_noteworthy )
		{
			case "bats":
				self thread quake_event_trigger_wait( ::quake_event_bats, node );
			default:
				break;
		}
	}
	
	linked_nodes = getLinknameNodes();
	foreach ( node in linked_nodes )
	{
		if ( !IsDefined( node.script_noteworthy ) )
			continue;
	
		switch ( node.script_noteworthy )
		{
			case "connect_traverse":
				disconnect_traverse( node );
				self thread quake_event_trigger_wait( ::quake_event_connect_traverse, node );
				break;
			case "disconnect_traverse":
				self thread quake_event_trigger_wait( ::quake_event_disconnect_traverse, node );
				break;
			case "connect":
				node DisconnectNode();
				self thread quake_event_trigger_wait( ::quake_event_connect_node, node );
				break;
			case "disconnect":
				self thread quake_event_trigger_wait( ::quake_event_disconnect_node, node );
				break;
			default:
				break;
		}
	}
	
	if ( !IsDefined( self.count ) )
		self.count = 1;
}

is_dynamic_path()
{
	return IsDefined(self.spawnflags) && self.spawnflags&1;
}

quake_event_init_ent( ent )
{
	ent.move_ent = ent;
	
	if ( !IsDefined( ent.target ) )
		return;
	
	structs = getstructarray( ent.target, "targetname" );
	ents	= GetEntArray( ent.target, "targetname" );
	
	targets = array_combine( structs, ents );

	foreach ( target in targets )
	{
		if ( !IsDefined( target.script_noteworthy ) )
			continue;
		
		switch ( target.script_noteworthy )
		{
			case "link":
				target LinkTo( ent );
				break;
			case "origin":
				ent.move_ent		= Spawn( "script_model", target.origin );
				ent.move_ent.angles = ( 0, 0, 0 );
				if ( IsDefined( target.angles ) )
					ent.move_ent.angles = target.angles;
				ent.move_ent SetModel( "tag_origin" );
				ent LinkTo( ent.move_ent );
				break;
			case "end":
				ent.end_location = target;
				break;
			case "start":
				if( ent is_dynamic_path())
					ent ConnectPaths();
				ent.origin = target.origin;
				if ( IsDefined( target.angles ) )
					ent.angles = target.angles;
				break;
			default:
				break;
		}
	}
}

quake_event_move_to( quakeTime, ent, time, delay, accel, decel, delete_at_end )
{
	if ( !IsDefined( ent.end_location ) )
		return;
	
	if ( !IsDefined( accel ) )
		accel = 0;
	if ( !IsDefined( decel ) )
		decel = 0;
	if ( !IsDefined( delete_at_end ) )
		delete_at_end = false;
	
	if ( IsDefined( delay ) && delay > 0 )
		wait delay;
	
	if ( ent.end_location.origin != ent.origin )
	{
		ent.move_ent MoveTo( ent.end_location.origin, time, accel, decel );
	}
	
	if ( IsDefined( ent.end_location.angles ) && ent.end_location.angles != ent.angles )
	{
		ent.move_ent RotateTo( ent.end_location.angles, time, accel, decel );
	}
	
	wait time;
	
	if( ent is_dynamic_path() )
	{
		ent DisconnectPaths();
	}
	
	if ( delete_at_end )
	{
		ent.move_ent Delete();
		if ( IsDefined( ent ) ) //Need to check becasue ent.move_ent might be the same as ent
			ent Delete();
	}
	
}

quake_event_shake( quakeTime, ent )
{
//	shakeTime = int(quakeTime) + RandomFloatRange(4,6);
//	
  //  period	= RandomFloatRange(.9,1.1);
  //  max_angle = RandomFloatRange(7,10);
//	
//	num_shakes = shakeTime/period;
//	
//	for(i=0;i<num_shakes;i++)
//	{
//		angle = max_angle * (1.0 - (i/num_shakes));
//		ent.move_ent RotatePitch(angle, period/2, period/4, period/4);
//		wait period/2;
//		ent.move_ent RotatePitch(-1*angle, period/2, period/4, period/4);
//		wait period/2;
//	}
}

#using_animtree( "animated_props" );
quake_event_bats( quakeTime, start_node )
{
	bat_origin = (752, -3536, 132);
	bat_model		 = Spawn( "script_model", bat_origin );
	bat_model.angles = ( 0, 0, 0 );
	bat_model SetModel( "generic_prop_raven" );	
	
	waitframe();
	
	bat_sound_ent = Spawn( "script_model", bat_origin );
	bat_sound_ent SetModel("tag_origin");
	bat_sound_ent LinkTo( bat_model, "j_prop_2" );	
	
	waitframe();
	
	PlayFXOnTag( level._effect[ "bats" ], bat_model, "j_prop_2" );
	
	bat_model ScriptModelPlayAnimDeltaMotion( "mp_lonestar_bat_effect_path" );
	bat_sound_ent PlayLoopSound( "mp_quake_bat_lp" );

	
	wait( GetAnimLength( %mp_lonestar_bat_effect_path ) );
	
	bat_sound_ent Delete();
	bat_model Delete();
}

quake_event_hurt( quakeTime, hurt_trigger, damage_rate, damage )
{
	thread quake_hurt_trigger( hurt_trigger, damage_rate, damage );
}

quake_hurt_trigger( hurt_trigger, damage_rate, damage )
{
	self endon( "stop_hurt_trigger" );
	
	ent_num		   = hurt_trigger GetEntityNumber();
	damage_rate_ms = damage_rate * 1000;
	
	while ( 1 )
	{
		hurt_trigger waittill( "trigger", player );
		
		if ( !IsDefined( player.quake_hurt_time ) )
			player.quake_hurt_time = [];
		
		if ( !IsDefined( player.quake_hurt_time[ ent_num ] ) )
		   player.quake_hurt_time[ ent_num ] = -1 * damage_rate_ms;
		  
		if ( player.quake_hurt_time[ ent_num ] + damage_rate_ms > GetTime() )
			continue;
		
		player.quake_hurt_time[ ent_num ] = GetTime();
		
		player DoDamage( damage, hurt_trigger.origin );
		//RadiusDamage( ( hurt_trigger.origin + ( 0, 0, 50 ) ), 10, damage, damage );
	}
}

quake_event_show( quakeTime, ent )
{
	ent Show();
}

quake_event_delete( quakeTime, ent )
{
	ent Delete();
}

quake_event_fx( quakeTime, fx_ent )
{
	TriggerFX( fx_ent );
}

quake_event_exploder( quakeTime, exploder_id )
{
	exploder( exploder_id );
}

quake_event_send_notify( quakeTime, ent, note )
{
	ent notify( note );
}

quake_event_animate( quakeTime, ent, anim_name )
{
	ent ScriptModelPlayAnimDeltaMotion( level.quake_anims[ anim_name ] );
	
	if ( IsDefined( level.quake_anim_funcs[ anim_name ] ) )
	{
		foreach ( func in level.quake_anim_funcs[ anim_name ] )
		{
			level thread [[ func ]]( quakeTime, ent );
		}
	}
	
	//restart loop after quake anim
	if ( IsDefined( level.quake_anims[ anim_name + "_loop" ] ) && IsDefined( level.quake_anims_ref[ anim_name ] ) )
	{
		anim_length = GetAnimLength( level.quake_anims_ref[ anim_name ] );
		wait anim_length;
		ent ScriptModelPlayAnim( level.quake_anims[ ent.script_animation + "_loop" ]  );
	}
}

quake_event_gas_leak( quakeTime, ent )
{
	
	//ent SetCanDamage( true );
	
	while ( 1 )
	{
		fire_fx = SpawnFx( level._effect[ "gas_leak_fire" ], ent.fx_location.origin, AnglesToForward( ent.fx_location.angles ) );
		TriggerFX( fire_fx );
		ent PlayLoopSound( "emt_lone_gas_pipe_fire_lp" );
	
		self thread quake_hurt_trigger( ent.hurt_trigger, .25, 10 );
		
		wait 30;
		
		self notify( "stop_hurt_trigger" );
		fire_fx Delete();
		ent StopLoopSound( "emt_lone_gas_pipe_fire_lp" );
		
		gas_fx = SpawnFx( level._effect[ "gas_leak" ], ent.fx_location.origin, AnglesToForward( ent.fx_location.angles ) );
		TriggerFX( gas_fx );
		
		ent waittill_notify_or_timeout( "trigger", 30 );
		
		gas_fx Delete();
	}
}

quake_event_pole_unlink_nodes()
{
	nodes = getnodearray( "dog_pole_vault", "script_noteworthy" );
	if ( IsDefined( nodes ) )
	{
		assert( nodes.size == 2 );
		DisconnectNodePair( nodes[0], nodes[1] );
	}

	nodes2 = getnodearray( "dog_pole_vault2", "script_noteworthy" );
	if ( IsDefined( nodes2 ) )
	{
		assert( nodes2.size == 2 );
		DisconnectNodePair( nodes2[0], nodes2[1] );
	}
}

quake_event_pole_link_nodes()
{
	nodes = getnodearray( "dog_pole_vault", "script_noteworthy" );
	if ( IsDefined( nodes ) )
	{
		assert( nodes.size == 2 );
		if ( IsDefined( nodes[0].target ) && IsDefined( nodes[1].targetname ) && nodes[0].target == nodes[1].targetname )
			ConnectNodePair( nodes[0], nodes[1], true );
		else
			ConnectNodePair( nodes[1], nodes[0], true );
	}

	nodes2 = getnodearray( "dog_pole_vault2", "script_noteworthy" );
	if ( IsDefined( nodes2 ) )
	{
		assert( nodes2.size == 2 );
		if ( IsDefined( nodes2[0].target ) && IsDefined( nodes2[1].targetname ) && nodes2[0].target == nodes2[1].targetname )
			ConnectNodePair( nodes2[0], nodes2[1], true );
		else
			ConnectNodePair( nodes2[1], nodes2[0], true );
	}
}

//Ent is the cop car
quake_event_pole_fall_on_car_init( ent )
{
	broken_base = GetEnt("pole_that_falls_on_cop_car_base", "targetname");
	if(IsDefined(broken_base))
		broken_base hide();
	
	pole = GetEnt( "pole_that_falls_on_cop_car", "targetname" );
	if ( !IsDefined( pole ) )
		return;
	
	clips = GetEntArray( pole.target, "targetname" );
	foreach ( clip in clips )
	{
		if ( clip.script_noteworthy == "clip_up" )
		{
			clip LinkTo( pole );
			pole.clip_up = clip;
		}
		else if ( clip.script_noteworthy == "clip_down" )
		{
			clip ConnectPaths();
			clip trigger_off();
			pole.clip_down = clip;
		}
	}

	quake_event_pole_unlink_nodes();
}

//Ent is the cop car
//Need to get the cop car, its a hard coded target name so I dont have to stamp the prefabs
quake_event_pole_fall_on_car( quakeTime, ent )
{
	broken_base = GetEnt("pole_that_falls_on_cop_car_base", "targetname");
	if(IsDefined(broken_base))
		broken_base Show();
	
	pole = GetEnt( "pole_that_falls_on_cop_car", "targetname" );
	if ( !IsDefined( pole ) )
		return;
	
	pole SetModel("ls_telephone_pole_snap");
	
	pole PlaySound( "scn_pole_fall" );
	
	animated_prop = Spawn( "script_model", pole.origin );
	animated_prop SetModel( "generic_prop_raven" );
	animated_prop.angles = pole.angles;
	
	pole LinkTo( animated_prop, "j_prop_1" );
	
	animated_prop ScriptModelPlayAnimDeltaMotion( "mp_lonestar_police_car_crush_pole" );
	
	car_swap	= GetNotetrackTimes( %mp_lonestar_police_car_crush_pole, "car_swap" );
	anim_length = GetAnimLength( %mp_lonestar_police_car_crush_pole );
	
	wait car_swap[ 0 ] * anim_length;
	
	ent PlaySound( "scn_police_car_crush" );
	
	exploder( 7 );
	
	pole.clip_down trigger_on();
	pole.clip_down DisconnectPaths();
	quake_event_pole_link_nodes();
	pole.clip_up Delete();
	ent SetModel( "ls_police_sedan_smashed" );
	
	foreach ( character in level.characters )
	{
		if ( character IsTouching( pole.clip_down ) )
		{
			character maps\mp\_movers::mover_suicide();
		}
	}
	
}

quake_event_playSound( quakeTime, ent )
{
	if ( !IsDefined( ent.script_sound ) )
		return;
	playSoundAtPos( ent.origin, ent.script_sound );
}

quake_event_disconnect_node( quakeTime, node )
{
	node DisconnectNode();
}

quake_event_connect_node( quakeTime, node )
{
	node ConnectNode();
}

quake_event_disconnect_traverse( quakeTime, begin_node )
{
	disconnect_traverse( begin_node );
}

disconnect_traverse( begin_node )
{
	if ( !IsDefined( begin_node.end_nodes ) )
	{
		begin_node.end_nodes = GetNodeArray( begin_node.target, "targetname" );
	}
	
	foreach ( end_node in begin_node.end_nodes )
	{
		DisconnectNodePair( begin_node, end_node, true );
	}
}

quake_event_connect_traverse( quakeTime, begin_node )
{
	connect_traverse( begin_node );
}

connect_traverse( begin_node )
{
	if ( !IsDefined( begin_node.end_nodes ) )
	{
		begin_node.end_nodes = GetNodeArray( begin_node.target, "targetname" );
	}
	
	foreach ( end_node in begin_node.end_nodes )
	{
		ConnectNodePair( begin_node, end_node, true );
	}
}

//location_callouts()
//{
  //  level.location_callouts							  = [];
  //  level.location_callouts["car_wash"]				  = &"MP_LONESTAR_CALLOUT_CAR_WASH";
  //  level.location_callouts["heli_crash"]				  = &"MP_LONESTAR_CALLOUT_HELI_CRASH";
  //  level.location_callouts["fema_tent"]				  = &"MP_LONESTAR_CALLOUT_FEMA_TENT";
  //  level.location_callouts["gas_main"]				  = &"MP_LONESTAR_CALLOUT_GAS_MAIN";
  //  level.location_callouts["kiosks"]					  = &"MP_LONESTAR_CALLOUT_KIOSKS";
  //  level.location_callouts["parking_garage"]			  = &"MP_LONESTAR_CALLOUT_PARKING_GARAGE";
  //  level.location_callouts["burned"]					  = &"MP_LONESTAR_CALLOUT_BURNED";
  //  level.location_callouts["gas_station"]			  = &"MP_LONESTAR_CALLOUT_GAS_STATION";
  //  level.location_callouts["rehab_south"]			  = &"MP_LONESTAR_CALLOUT_REHAB_SOUTH";
  //  level.location_callouts["rehab_north"]			  = &"MP_LONESTAR_CALLOUT_REHAB_NOTH";
  //  level.location_callouts["rehab_roof"]				  = &"MP_LONESTAR_CALLOUT_REHAB_ROOF";
  //  level.location_callouts["insurance"]				  = &"MP_LONESTAR_CALLOUT_INSURANCE";
  //  level.location_callouts["insurance_roof"]			  = &"MP_LONESTAR_CALLOUT_INSURANCE_ROOF";
  //  level.location_callouts["solar"]					  = &"MP_LONESTAR_CALLOUT_SOLAR";
  //  level.location_callouts["service"]				  = &"MP_LONESTAR_CALLOUT_AMBULANCE_SERVICE";
  //  level.location_callouts["hog_garage"]				  = &"MP_LONESTAR_CALLOUT_HOG_GARAGE";
  //  level.location_callouts["childrens_hospital"]		  = &"MP_LONESTAR_CALLOUT_CHILD_HOSP";
  //  level.location_callouts["childrens_hospital_lobby"] = &"MP_LONESTAR_CALLOUT_CHILD_HOSP_LOBBY";
  //  level.location_callouts["emergency_entrance"]		  = &"MP_LONESTAR_CALLOUT_EMERGENCY";
  //  level.location_callouts["treatment"]				  = &"MP_LONESTAR_CALLOUT_TREATMENT";
  //  level.location_callouts["trash"]					  = &"MP_LONESTAR_CALLOUT_TRASH";
  //  level.location_callouts["courtyard"]				  = &"MP_LONESTAR_CALLOUT_COURTYARD";
  //  level.location_callouts["skybridge"]				  = &"MP_LONESTAR_CALLOUT_SKYBIRDGE";
//	
//	location_trigger = GetEntArray("location_callout", "targetname");
//	
//	array_thread(location_trigger, ::location_callouts_init);
//	level thread location_callouts_update_players();
//	
//}
//
//location_callouts_init()
//{
//	
//	if(!IsDefined(self.script_noteworthy))
//	{
//		Print("Location callout trigger at " + self.origin + " missing script_noteworthy\n");
//		return;
//	}
//	
//	self.callout_name = level.location_callouts[self.script_noteworthy];
//	if(!IsDefined(self.callout_name))
//	{
//		Print("Location callout trigger at " + self.origin + " has script_noteworthy ('" +self.script_noteworthy + "') not defined in level.location_callouts\n");
//	}
//	
//	self.priority = self.script_index;
//	if(!IsDefined(self.priority))
//		self.priority = 1;
//	
//	self thread location_callout_run();
//}
//
//location_callout_run()
//{
//	while(1)
//	{
//		self waittill("trigger", player);
//		
//		if(!IsPlayer(player))
//			continue;
//		
//		if(isAI(player))
//			continue;
//		
//		new = player.location_callout_new;
//		if(!IsDefined(new) || self.priority>new.priority)
//		{
//			player.location_callout_new = self;
//		}
//	}
//}
//
//location_callouts_update_players()
//{
//	while(!IsDefined(level.players))
//		waitframe();
//	
//	while(1)
//	{
//		foreach(player in level.players)
//		{
//			player.location_callout_new = undefined;		
//		}
//		
//		waittillframeend; //player.location_callout_new will be updated in location_callout_run(), if there are any
//		
//		foreach(player in level.players)
//		{
//			if(isAI(player))
//				continue;
//			
//			location_callouts_set_player_trigger(player, player.location_callout_new);
//		}
//		waitframe();
//	}
//}
//
//location_callouts_set_player_trigger(player, new_trigger)
//{
//	old_trigger = player.location_callout_current;
//	
//	if(!IsDefined(old_trigger) && !IsDefined(new_trigger))
//		return;
//	
//	if(IsDefined(old_trigger) && IsDefined(new_trigger) && old_trigger==new_trigger)
//		return;
//	
//	player.location_callout_current = new_trigger;
//	if(IsDefined(new_trigger))
//	{
//		if(!IsDefined(player.location_callout_hud))
//		{
  //		  player.location_callout_hud		= location_callouts_hud_create(player);
  //		  player.location_callout_hud.alpha = 0;
//		}
//		
//		player.location_callout_hud thread location_callouts_hud_set_text(new_trigger.callout_name);
//	}
//	else if(IsDefined(old_trigger))
//	{
//		if(IsDefined(player.location_callout_hud))
//		{
//			player.location_callout_hud notify("end_visible_time");
//		}
//	}
//}
//
//location_callouts_hud_create(player)
//{
  //  fontElem			 = newClientHudElem( player );
  //  fontElem.elemType	 = "font";
  //  fontElem.font		 = "default";
  //  fontElem.fontscale = 1.2;
  //  fontElem.width	 = 0;
  //  fontElem.height	 = int( level.fontHeight * fontElem.fontscale );
  //  fontElem.children	 = [];
//	fontElem maps\mp\gametypes\_hud_util::setParent( level.uiParent );
//	
//	fontElem maps\mp\gametypes\_hud_util::SetPoint("TOPLEFT", undefined, 10, 110);
//
//	return fontElem;
//}
//	
//location_callouts_hud_set_text(callout_str)
//{
//	self notify("location_callouts_hud_set_text");
//	
//	self endon("location_callouts_hud_set_text");
//	self endon("death");
//
  //  default_fade_in_time	= .5;
  //  default_visiable_time = 3;
  //  default_fade_out_time = 1.0;
//	
//	self SetText(callout_str);
//	
//	scaled_fade_in_time = (1-self.alpha)*default_fade_in_time;
//	if(scaled_fade_in_time>0)
//	{
//		self FadeOverTime(scaled_fade_in_time);
//		self.alpha = 1;
//		wait scaled_fade_in_time;	
//	}
//	
//	location_callouts_hud_visible_wait(default_visiable_time);
//	
//	self FadeOverTime(default_fade_out_time);
//	self.alpha = 0;
//	wait default_fade_out_time;
//	
//	self Destroy();
//}
//
//location_callouts_hud_visible_wait(waitTime)
//{
//	self endon("end_visible_time");
//	
//	wait waitTime;
//}