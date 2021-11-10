#include common_scripts\utility;

/*

Handles Old-School exploders.  This is coupled with _createfx and _fx since a Radiant Created "exploder" can trigger a createfx created effect.

This Script is legacy, tried and true, It eats up entites when using script_brushmodel swapping and a lot of script_models and the damage triggers.

We should in a future game consider some entiity optimization in code.  A way to Join models and brushes as one entity would be key.

 */

setup_individual_exploder( ent )
{
	exploder_num = ent.script_exploder;
	if ( !IsDefined( level.exploders[ exploder_num ] ) )
	{
		level.exploders[ exploder_num ] = [];
	}

	targetname = ent.targetname;
	if ( !IsDefined( targetname ) )
		targetname = "";

	level.exploders[ exploder_num ][ level.exploders[ exploder_num ].size ] = ent;
	if ( exploder_model_starts_hidden( ent ) )
	{
		ent Hide();
		return;
	}

	if ( exploder_model_is_damaged_model( ent ) )
	{
		ent Hide();
		ent NotSolid();
		if ( IsDefined( ent.spawnflags ) && ( ent.spawnflags & 1 ) )
		{
			if ( IsDefined( ent.script_disconnectpaths ) )
			{
				ent ConnectPaths();
			}
		}
		return;
	}

	if ( exploder_model_is_chunk( ent ) )
	{
		ent Hide();
		ent NotSolid();
		if ( IsDefined( ent.spawnflags ) && ( ent.spawnflags & 1 ) )
			ent ConnectPaths();
		return;
	}
}

setupExploders()
{
	level.exploders = [];

	// Hide exploder models.
	ents = GetEntArray( "script_brushmodel", "classname" );
	smodels = GetEntArray( "script_model", "classname" );
	for ( i = 0; i < smodels.size; i++ )
		ents[ ents.size ] = smodels[ i ];

	foreach ( ent in ents )
	{
		if ( IsDefined( ent.script_prefab_exploder ) )
			ent.script_exploder = ent.script_prefab_exploder;
			
        if ( IsDefined( ent.masked_exploder ) )
            continue;
            
		if ( IsDefined( ent.script_exploder ) )
		{
			setup_individual_exploder( ent );
		}
	}

	script_exploders = [];

	potentialExploders = GetEntArray( "script_brushmodel", "classname" );
	for ( i = 0; i < potentialExploders.size; i++ )
	{
		if ( IsDefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( IsDefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}

	potentialExploders = GetEntArray( "script_model", "classname" );
	for ( i = 0; i < potentialExploders.size; i++ )
	{
		if ( IsDefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( IsDefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}

	potentialExploders = GetEntArray( "item_health", "classname" );
	for ( i = 0; i < potentialExploders.size; i++ )
	{
		if ( IsDefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( IsDefined( potentialExploders[ i ].script_exploder ) )
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];
	}
	
	
	potentialExploders = level.struct;
	for ( i = 0; i < potentialExploders.size; i++ )
	{
		if ( !IsDefined( potentialExploders[ i ] ) )
			continue; // these must be getting deleted somewhere else?
		if ( IsDefined( potentialExploders[ i ].script_prefab_exploder ) )
			potentialExploders[ i ].script_exploder = potentialExploders[ i ].script_prefab_exploder;

		if ( IsDefined( potentialExploders[ i ].script_exploder ) )
		{
			if ( !IsDefined( potentialExploders[ i ].angles ) )
				potentialExploders[ i ].angles = ( 0, 0, 0 );
			script_exploders[ script_exploders.size ] = potentialExploders[ i ];

		}
	}	
	

	if ( !IsDefined( level.createFXent ) )
		level.createFXent = [];

	acceptableTargetnames							 = [];
	acceptableTargetnames[ "exploderchunk visible" ] = true;
	acceptableTargetnames[ "exploderchunk"		   ] = true;
	acceptableTargetnames[ "exploder"			   ] = true;

	thread setup_flag_exploders();

	for ( i = 0; i < script_exploders.size; i++ )
	{
		exploder = script_exploders[ i ];
		
		
		ent						 = createExploder( exploder.script_fxid );
		ent.v					 = [];
		ent.v[ "origin"		   ] = exploder.origin;
		ent.v[ "angles"		   ] = exploder.angles;
		ent.v[ "delay"		   ] = exploder.script_delay;
		ent.v[ "delay_post"	   ] = exploder.script_delay_post;
		ent.v[ "firefx"		   ] = exploder.script_firefx;
		ent.v[ "firefxdelay"   ] = exploder.script_firefxdelay;
		ent.v[ "firefxsound"   ] = exploder.script_firefxsound;
		ent.v[ "earthquake"	   ] = exploder.script_earthquake;
		ent.v[ "rumble"		   ] = exploder.script_rumble;
		ent.v[ "damage"		   ] = exploder.script_damage;
		ent.v[ "damage_radius" ] = exploder.script_radius;
		ent.v[ "soundalias"	   ] = exploder.script_soundalias;
		ent.v[ "repeat"		   ] = exploder.script_repeat;
		ent.v[ "delay_min"	   ] = exploder.script_delay_min;
		ent.v[ "delay_max"	   ] = exploder.script_delay_max;
		ent.v[ "target"		   ] = exploder.target;
		ent.v[ "ender"		   ] = exploder.script_ender;
		ent.v[ "physics"	   ] = exploder.script_physics;
		ent.v[ "type"		   ]  = "exploder";
// 		ent.v[ "worldfx" ] = true;
		if ( !IsDefined( exploder.script_fxid ) )
			ent.v[ "fxid" ] = "No FX";
		else
			ent.v[ "fxid"	  ]	 = exploder.script_fxid;
		ent.v	 [ "exploder" ]	 = exploder.script_exploder;
		AssertEx( IsDefined( exploder.script_exploder ), "Exploder at origin " + exploder.origin + " has no script_exploder" );
		if ( IsDefined( level.createFXexploders ) )
		{	// if we're using the optimized lookup, add it in the proper place
			ary = level.createFXexploders[ ent.v[ "exploder" ] ];
			if ( !IsDefined( ary ) )
				ary = [];
			ary[ ary.size ]								   = ent;
			level.createFXexploders[ ent.v[ "exploder" ] ] = ary;
		}

		if ( !IsDefined( ent.v[ "delay" ] ) )
			ent.v[ "delay" ] = 0;

		if ( IsDefined( exploder.target ) )
		{
			get_ent = GetEntArray( ent.v[ "target" ], "targetname" )[ 0 ];
			if ( IsDefined( get_ent ) )
			{
				org				  = get_ent.origin;
				ent.v[ "angles" ] = VectorToAngles( org - ent.v[ "origin" ] );
			}
			else
			{
				get_ent = get_target_ent( ent.v[ "target" ] );
				if ( IsDefined( get_ent ) )
				{
					org				  = get_ent.origin;
					ent.v[ "angles" ] = VectorToAngles( org - ent.v[ "origin" ] );
				}
			}
		}
		
		// this basically determines if its a brush / model exploder or not
		if ( !IsDefined( exploder.code_classname ) )
		{
			//I assume everything that doesn't have a code_classname is a struct that needs a script_modelname to make its way into the game
			ent.model = exploder;
			if ( IsDefined( ent.model.script_modelname ) )
			{
				PreCacheModel( ent.model.script_modelname );
			}
		}
		else if ( exploder.code_classname == "script_brushmodel" || IsDefined( exploder.model ) )
		{
			ent.model				   = exploder;
			ent.model.disconnect_paths = exploder.script_disconnectpaths;
		}

		if ( IsDefined( exploder.targetname ) && IsDefined( acceptableTargetnames[ exploder.targetname ] ) )
			ent.v[ "exploder_type" ] = exploder.targetname;
		else
			ent.v[ "exploder_type" ] = "normal";
        
        if ( IsDefined( exploder.masked_exploder ) )
        {
			ent.v[ "masked_exploder"						] = exploder.model;
			ent.v[ "masked_exploder_spawnflags"				] = exploder.spawnflags;
			ent.v[ "masked_exploder_script_disconnectpaths" ] = exploder.script_disconnectpaths;
            exploder Delete();
        }
		ent common_scripts\_createfx::post_entity_creation_function();
	}
}

setup_flag_exploders()
{
	// createfx has to do 2 waittillframeends so we have to do 3 to make sure this comes after
	// createfx is all done setting up. Who will raise the gambit to 4? 
	waittillframeend;
	waittillframeend;
	waittillframeend;
	exploder_flags = [];

	foreach ( ent in level.createFXent )
	{
		if ( ent.v[ "type" ] != "exploder" )
			continue;
		theFlag = ent.v[ "flag" ];

		if ( !IsDefined( theFlag ) )
		{
			continue;
		}

		if ( theFlag == "nil" )
		{
			ent.v[ "flag" ] = undefined;
		}

		exploder_flags[ theFlag ] = true;
	}

	foreach ( msg, _ in exploder_flags )
	{
		thread exploder_flag_wait( msg );
	}
}

exploder_flag_wait( msg )
{
	if ( !flag_exist( msg ) )
		flag_init( msg );
	flag_wait( msg );

	foreach ( ent in level.createFXent )
	{
		if ( ent.v[ "type" ] != "exploder" )
			continue;
		theFlag = ent.v[ "flag" ];

		if ( !IsDefined( theFlag ) )
		{
			continue;
		}

		if ( theFlag != msg )
			continue;
		ent activate_individual_exploder();
	}
}

exploder_model_is_damaged_model( ent )
{
	return( IsDefined( ent.targetname ) ) && ( ent.targetname == "exploder" );
}

exploder_model_starts_hidden( ent )
{
	return( ent.model == "fx" ) && ( ( !IsDefined( ent.targetname ) ) || ( ent.targetname != "exploderchunk" ) );
}

exploder_model_is_chunk( ent )
{
	return( IsDefined( ent.targetname ) ) && ( ent.targetname == "exploderchunk" );
}

show_exploder_models_proc( num )
{
	num += "";

	//prof_begin( "hide_exploder" );
	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				//pre exploded geo.  don't worry about deleted exploder geo..
				if ( ! exploder_model_starts_hidden( ent.model )
				         && ! exploder_model_is_damaged_model( ent.model )
				         && !exploder_model_is_chunk( ent.model ) )
				{
						ent.model Show();
				}
	
				//exploded geo and should be shown
				if ( IsDefined( ent.brush_shown ) )
					ent.model Show();
			}
		}
	}
	else
	{
		for ( i = 0; i < level.createFXent.size; i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
			if ( IsDefined( ent.model ) )
			{
	
				//pre exploded geo.  don't worry about deleted exploder geo..
				if ( ! exploder_model_starts_hidden( ent.model ) && ! exploder_model_is_damaged_model( ent.model ) && !exploder_model_is_chunk( ent.model ) )
				{
						ent.model Show();
				}
	
				//exploded geo and should be shown
				if ( IsDefined( ent.brush_shown ) )
					ent.model Show();
	
			}
		}
	}
	//prof_end( "hide_exploder" );
}

stop_exploder_proc( num )
{
	num += "";

	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				if ( !IsDefined( ent.looper ) )
					continue;
		
				ent.looper Delete();
			}
		}
	}
	else
	{
		for ( i = 0; i < level.createFXent.size; i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
			if ( !IsDefined( ent.looper ) )
				continue;
	
			ent.looper Delete();
		}
	}
}

get_exploder_array_proc( msg )
{
	msg += "";
	array = [];
	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ msg ];
		if ( IsDefined( exploders ) )
		{
			array = exploders;
		}
	}
	else
	{
		foreach ( ent in level.createFXent )
		{
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != msg )
				continue;
	
			array[ array.size ] = ent;
		}
	}
	return array;
}

hide_exploder_models_proc( num )
{
	num += "";

	//prof_begin( "hide_exploder" );

	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				if ( IsDefined( ent.model ) )
					ent.model Hide();
			}
		}
	}
	else
	{
		for ( i = 0; i < level.createFXent.size; i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
	
			if ( IsDefined( ent.model ) )
					ent.model Hide();
	
		}
	}
	//prof_end( "hide_exploder" );
}

delete_exploder_proc( num )
{
	num += "";

	//prof_begin( "delete_exploder" );
	if ( IsDefined( level.createFXexploders ) )
	{	// do optimized flavor if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				if ( IsDefined( ent.model ) )
					ent.model Delete();
			}
		}
	}
	else
	{
		for ( i = 0; i < level.createFXent.size; i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
			if ( IsDefined( ent.model ) )
				ent.model Delete();
		}
	}
	//ends trigger threads.
	level notify( "killexplodertridgers" + num );

	//prof_end( "delete_exploder" );
}

exploder_damage()
{
	if ( IsDefined( self.v[ "delay" ] ) )
		delay = self.v[ "delay" ];
	else
		delay = 0;

	if ( IsDefined( self.v[ "damage_radius" ] ) )
		radius = self.v[ "damage_radius" ];
	else
		radius = 128;

	damage = self.v[ "damage" ];
	origin = self.v[ "origin" ];

	wait( delay );
	
	if ( IsDefined( level.custom_radius_damage_for_exploders ) )
		[[ level.custom_radius_damage_for_exploders ]]( origin, radius, damage );
	else
		// Range, max damage, min damage
		RadiusDamage( origin, radius, damage, damage );
}

activate_individual_exploder_proc()
{
	if ( IsDefined( self.v[ "firefx" ] ) )
		self thread fire_effect();

	if ( IsDefined( self.v[ "fxid" ] ) && self.v[ "fxid" ] != "No FX" )
		self thread cannon_effect();
	else
	if ( IsDefined( self.v[ "soundalias" ] ) && self.v[ "soundalias" ] != "nil" )
		self thread sound_effect();

	if ( IsDefined( self.v[ "loopsound" ] ) && self.v[ "loopsound" ] != "nil" )
		self thread effect_loopsound();

	if ( IsDefined( self.v[ "damage" ] ) )
		self thread exploder_damage();

	if ( IsDefined( self.v[ "earthquake" ] ) )
		self thread exploder_earthquake();

	if ( IsDefined( self.v[ "rumble" ] ) )
		self thread exploder_rumble();

	if ( self.v[ "exploder_type" ] == "exploder" )
		self thread brush_show();
	else
	if ( ( self.v[ "exploder_type" ] == "exploderchunk" ) || ( self.v[ "exploder_type" ] == "exploderchunk visible" ) )
		self thread brush_throw();
	else
		self thread brush_delete();
}

brush_delete()
{
// 		if( ent.v[ "exploder_type" ] != "normal" && !isdefined( ent.v[ "fxid" ] ) && !isdefined( ent.v[ "soundalias" ] ) )
// 		if( !isdefined( ent.script_fxid ) )

	num = self.v[ "exploder" ];
	if ( IsDefined( self.v[ "delay" ] ) )
		wait( self.v[ "delay" ] );
	else
		wait( 0.05 ); // so it disappears after the replacement appears

	if ( !IsDefined( self.model ) )
		return;


	Assert( IsDefined( self.model ) );

	if ( IsDefined( self.model.classname ) ) // script_struct support - Nate -- self is always a struct so it will never have a classname, using self.model instead -Carlos
		if ( isSP() && ( self.model.spawnflags & 1 ) )
			self.model call [[ level.connectPathsFunction ]]();

	if ( level.createFX_enabled )
	{
		if ( IsDefined( self.exploded ) )
			return;

		self.exploded = true;
		self.model Hide();
		self.model NotSolid();

		wait( 3 );
		self.exploded = undefined;
		self.model Show();
		self.model Solid();
		return;
	}

	if ( !IsDefined( self.v[ "fxid" ] ) || self.v[ "fxid" ] == "No FX" )
		self.v[ "exploder" ] = undefined;

	waittillframeend;// so it hides stuff after it shows the new stuff
	
//	if ( IsDefined( self.classname ) ) // script_struct support nate --- self is always a struct so it will never have a classname, using self.model instead -Carlos
		if ( IsDefined( self.model ) && IsDefined( self.model.classname ) )
		{
			self.model Delete();
		}
}

brush_throw()
{
	if ( IsDefined( self.v[ "delay" ] ) )
		wait( self.v[ "delay" ] );

	ent = undefined;
	if ( IsDefined( self.v[ "target" ] ) )
		ent = get_target_ent( self.v[ "target" ] );

	if ( !IsDefined( ent ) )
	{
		self.model Delete();
		return;
	}

	self.model Show();

	if ( IsDefined( self.v[ "delay_post" ] ) )
		wait( self.v[ "delay_post" ] );

	startorg = self.v[ "origin" ];
	startang = self.v[ "angles" ];
	org		 = ent.origin;

	temp_vec = ( org - self.v[ "origin" ] );
	x		 = temp_vec[ 0 ];
	y		 = temp_vec[ 1 ];
	z		 = temp_vec[ 2 ];

	physics = IsDefined( self.v[ "physics" ] );
	if ( physics )
	{
		target = undefined;
		if ( IsDefined( ent.target ) )
			target = ent get_target_ent();

		if ( !IsDefined( target ) )
		{
			contact_point = startorg; // no spin just push it.
			throw_vec	  = ent.origin;
		}
		else
		{
			contact_point = ent.origin;
			throw_vec	  = ( ( target.origin - ent.origin ) * self.v[ "physics" ] );

		}
		self.model PhysicsLaunchClient( contact_point, throw_vec );
		return;
	}
	else
	{
		self.model RotateVelocity( ( x, y, z ), 12 );
		self.model MoveGravity( ( x, y, z ), 12 );
	}

	if ( level.createFX_enabled )
	{
		if ( IsDefined( self.exploded ) )
			return;

		self.exploded = true;
		wait( 3 );
		self.exploded	   = undefined;
		self.v[ "origin" ] = startorg;
		self.v[ "angles" ] = startang;
		self.model Hide();
		return;
	}

	self.v[ "exploder" ] = undefined;
	wait( 6 );
	self.model Delete();
}

brush_show()
{
	if ( IsDefined( self.v[ "delay" ] ) )
		wait( self.v[ "delay" ] );

	Assert( IsDefined( self.model ) );

	if ( !IsDefined( self.model.script_modelname ) )
	{
		self.model Show();
		self.model Solid();
	}
	else // script_structs don't pass in their .model value SO use script_modelname on them saves an entity.
	{
		model = self.model spawn_tag_origin();
		if ( IsDefined( self.model.script_linkname ) )
			model.script_linkname = self.model.script_linkname;
		model SetModel( self.model.script_modelname );
		model Show();
	}

	self.brush_shown = true; // used for hiding an exploder.

	if ( isSP() && !IsDefined( self.model.script_modelname ) && ( self.model.spawnflags & 1 ) )
	{
		if ( !IsDefined( self.model.disconnect_paths ) )
			self.model call [[ level.connectPathsFunction ]]();
		else
			self.model call [[ level.disconnectPathsFunction ]]();
	}

	if ( level.createFX_enabled )
	{
		if ( IsDefined( self.exploded ) )
			return;

		self.exploded = true;
		wait( 3 );
		self.exploded = undefined;
		
		if ( !IsDefined( self.model.script_modelname ) )
		{
			self.model Hide();
			self.model NotSolid();
		}
	}
}

exploder_rumble()
{
	if ( !isSP() )
		return;
	
	self exploder_delay();
	level.player PlayRumbleOnEntity( self.v[ "rumble" ] );
}

exploder_delay()
{
	if ( !IsDefined( self.v[ "delay" ] ) )
		self.v[ "delay" ] = 0;

	min_delay = self.v[ "delay" ];
	max_delay = self.v[ "delay" ] + 0.001; // cant randomfloatrange on the same #
	if ( IsDefined( self.v[ "delay_min" ] ) )
		min_delay = self.v[ "delay_min" ];

	if ( IsDefined( self.v[ "delay_max" ] ) )
		max_delay = self.v[ "delay_max" ];

	if ( min_delay > 0 )
		wait( RandomFloatRange( min_delay, max_delay ) );
}

effect_loopsound()
{
	if ( IsDefined( self.loopsound_ent ) )
	{
		self.loopsound_ent Delete();
	}
	// save off this info in case we delete the effect
	origin = self.v[ "origin" ];
	alias  = self.v[ "loopsound" ];
	self exploder_delay();

	self.loopsound_ent = play_loopsound_in_space( alias, origin );
}

sound_effect()
{
	self effect_soundalias();
}

effect_soundalias()
{
	// save off this info in case we delete the effect
	origin = self.v[ "origin" ];
	alias  = self.v[ "soundalias" ];
	self exploder_delay();
	play_sound_in_space( alias, origin );
}

exploder_earthquake()
{
	self exploder_delay();
	do_earthquake( self.v[ "earthquake" ], self.v[ "origin" ] );
}

exploder_playSound()
{
	if ( !IsDefined( self.v[ "soundalias" ] ) || self.v[ "soundalias" ] == "nil" )
		return;

	play_sound_in_space( self.v[ "soundalias" ], self.v[ "origin" ] );
}

fire_effect()
{
	forward = self.v[ "forward" ];
	up		= self.v[ "up" ];

	org = undefined;

	firefxSound = self.v[ "firefxsound" ];
	origin		= self.v[ "origin" ];
	firefx		= self.v[ "firefx" ];
	ender		= self.v[ "ender" ];
	if ( !IsDefined( ender ) )
		ender = "createfx_effectStopper";

	fireFxDelay = 0.5;
	if ( IsDefined( self.v[ "firefxdelay" ] ) )
		fireFxDelay = self.v[ "firefxdelay" ];

	self exploder_delay();

	if ( IsDefined( firefxSound ) )
		loop_fx_sound( firefxSound, origin, 1, ender );

	PlayFX( level._effect[ firefx ], self.v[ "origin" ], forward, up );
}

cannon_effect()
{
	if ( IsDefined( self.v[ "repeat" ] ) )
	{
		thread exploder_playSound();
		for ( i = 0; i < self.v[ "repeat" ]; i++ )
		{
			PlayFX( level._effect[ self.v[ "fxid" ] ], self.v[ "origin" ], self.v[ "forward" ], self.v[ "up" ] );
			self exploder_delay();
		}
		return;
	}
	self exploder_delay();

	if ( IsDefined( self.looper ) )
		self.looper Delete();

	self.looper = SpawnFx( getfx( self.v[ "fxid" ] ), self.v[ "origin" ], self.v[ "forward" ], self.v[ "up" ] );
	TriggerFX( self.looper );
	exploder_playSound();
}

activate_exploder( num, players, startTime )
{
	num += "";
	//prof_begin( "activate_exploder" );

	//here's a hook so you can know when a certain number of an exploder is going off
	level notify( "exploding_" + num );
	
	found_server_exploder = false;
	
	if ( IsDefined( level.createFXexploders ) && !level.createFX_enabled )
	{	// do optimized form if available
		exploders = level.createFXexploders[ num ];
		if ( IsDefined( exploders ) )
		{
			foreach ( ent in exploders )
			{
				ent activate_individual_exploder();
				found_server_exploder = true;
			}
		}
	}
	else
	{
		for ( i = 0;i < level.createFXent.size;i++ )
		{
			ent = level.createFXent[ i ];
			if ( !IsDefined( ent ) )
				continue;
	
			if ( ent.v[ "type" ] != "exploder" )
				continue;
	
			// make the exploder actually removed the array instead?
			if ( !IsDefined( ent.v[ "exploder" ] ) )
				continue;
	
			if ( ent.v[ "exploder" ] + "" != num )
				continue;
	
			ent activate_individual_exploder();
			found_server_exploder = true;
		}
	}
	
	if ( !shouldRunServerSideEffects() && !found_server_exploder )
		activate_clientside_exploder( num, players, startTime );

	//prof_end( "activate_exploder" );
}

activate_clientside_exploder( exploderName, players, startTime  )
{
	if ( !is_valid_clientside_exploder_name( exploderName ) )
	{
		PrintLn( "^1ERROR: Exploder Index '" + exploderName + "' is not a valid exploder index >= 0" );
		return;
	}
	
	exploder_num = Int( exploderName );
	ActivateClientExploder( exploder_num, players, startTime );
}

is_valid_clientside_exploder_name( exploderName )
{
	if ( !IsDefined( exploderName ) )
		return false;
	
	exploder_num = exploderName;
	if ( IsString( exploderName ) )
	{
		exploder_num = Int( exploderName );
		if ( exploder_num == 0 && exploderName != "0" )
			return false;
	}
	
	return exploder_num >= 0;
}

shouldRunServerSideEffects()
{
	if ( isSP() )
		return true;
		
	if ( !IsDefined( level.createFX_enabled ) )
		level.createFX_enabled = ( GetDvar( "createfx" ) != "" );
	
	if ( level.createFX_enabled )
		return true;
	else
		return GetDvar( "clientSideEffects" ) != "1";
}

exploder_before_load( num, players, startTime  )
{
	// gotta wait twice because the createfx_init function waits once then inits all exploders. This guarentees
	// that if an exploder is run on the first frame, it happens after the fx are init.
	waittillframeend;
	waittillframeend;
	activate_exploder( num, players, startTime  );
}

exploder_after_load( num, players, startTime  )
{
	activate_exploder( num, players, startTime  );
}