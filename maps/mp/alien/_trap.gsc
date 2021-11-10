#include common_scripts\utility;
#include maps\mp\alien\_persistence;
#include maps\mp\_utility;
#include maps\mp\alien\_perk_utility;
#include maps\mp\alien\_utility;

CONST_TRAP_OUTLINE_COLOR_INDEX = 3;
CONST_TRAP_OUTLINE_RED_COLOR_INDEX = 1;
CONST_FLARE_THREATBIAS = 1000;
CONST_FLARE_TIME = 20;
CONST_UPGRADED_FLARE_TIME = 30;
CONST_FLARE_HEALTH = 900000;
CONST_TURRET_OVERHEAT_TIME = 2;
CONST_TURRET_COOLDOWN_TIME = 1;


// traps go here!
traps_init()
{
	// setup parameter of fire that burns aliens when crossed
	level.outline_switch[ "traps_fire" ] 	= true;
	level thread fire_trap_init();	
	
	// electrofied puddles that shocks aliens when stepped into
	level.outline_switch[ "traps_puddle" ] 	= true;
	level thread electric_puddle_init();
	
	// electric fences that shocks aliens when climbing
	level.outline_switch[ "traps_fence" ] 	= true;
	level thread electric_fence_init();
	level.spawnGlow["enemy"] = loadfx( "fx/misc/flare_ambient" );
	
}

// global trap activation condition
can_activate_trap( trap )
{
	assertex( isdefined( trap ) && isdefined( trap.cost ), "[int] trap_struct.cost is not defined" );
	
	// self is player	
	return self player_has_enough_currency( int( trap.cost ) );
}

	
	

//*****************************************************************
//					FIRE TRAP
//*****************************************************************

CONST_FIRE_TRAP_DURATION			= 50;	// seconds fire last
CONST_FIRE_TRAP_DURATION_SMALL		= 50;	// seconds fire last(custom)
CONST_FIRE_TRAP_DURATION_MED		= 80;	// seconds fire last(custom)
CONST_FIRE_TRAP_DURATION_LARGE		= 110;	// seconds fire last(custom)
CONST_FIRE_TRAP_DAMAGE_SMALL		= 400; 	// total damage
CONST_FIRE_TRAP_DAMAGE_MED			= 600; 	// total damage
CONST_FIRE_TRAP_DAMAGE_LARGE		= 800; 	// total damage
	
CONST_FIRE_TRAP_DAMAGE_TIME			= 6;	// total time for said damage to be applied
CONST_FIRE_TRAP_DAMAGE_PLAYER 		= 33; 	// total damage
CONST_FIRE_TRAP_DAMAGE_TIME_PLAYER	= 3;	// total time for said damage to be applied

CONST_FIRE_TRAP_COST				= 750; 	// currency cost to enable fence
CONST_FIRE_TRAP_COST_SMALL			= 300;	// small
CONST_FIRE_TRAP_COST_MED			= 750;	// med
CONST_FIRE_TRAP_COST_LARGE			= 1000; // large

CONST_POURING_TIME					= 2.5; 	// time it takes to pour the gas after buying

fire_trap_init()
{
	barrels = getentarray( "fire_trap_barrel", "targetname" );
	if ( !isdefined( barrels ) || barrels.size == 0 )
		return;
	
	// wait before players are ready, we decide how to setup usage based on match type
	while ( !isdefined( level.players ) || level.players.size < 1 )
		wait 0.05;
	
	level.fire_traps = [];	
	foreach ( barrel in barrels )
	{
		barrel.damagefeedback = false;
		fire_trap = fire_trap_setup( barrel );
		level.fire_traps[ level.fire_traps.size ] = fire_trap;
		fire_trap thread fire_trap_think();
	}
}

// per trap setup ( 3 entities involved per trap )
// barrel_xmodel -> gas_scriptmodel -> activation_trigger -> damage_trigger -> fire_link_struct_1 -> fire_link_struct_2 etc...
fire_trap_setup( barrel )
{
	fire_trap = SpawnStruct();
	fire_trap.trap_type = "traps_fire";
	
	// setup barrel for use
	fire_trap.barrel = barrel;

	// setup damage trigger
	fire_trap.burn_trig	= getent( fire_trap.barrel.target, "targetname" );
	
	//needed for tracking kills with the fire trap
	fire_trap.burn_trig.script_noteworthy = "fire_trap";
	
	// setup fire fx locations
	fire_link_structs 	= [];
	cur_loc 			= fire_trap.burn_trig;
	
	while ( isdefined( cur_loc ) && isdefined( cur_loc.target ) )
	{
		fire_loc = getstruct( cur_loc.target, "targetname" );
		
		if ( !isdefined( fire_loc ) )
			break;
		
		// break once we have gone full circle
		if ( isdefined( fire_link_structs[ 0 ] ) && fire_loc == fire_link_structs[ 0 ] )
		{
			assertmsg( "Looping fire location structs is not allowed" );
			break;
		}
		
		fire_link_structs[ fire_link_structs.size ] = fire_loc;
		cur_loc = fire_loc;
	}
	
	// setup points betweenlinked fire location structs to play actual fire fx with defined spacing
	interval_dist 	= 45;	// fx spacing
	max_fire_fx 	= 15;	// leak safe, max fx allowed per trap
	fire_fx_array 	= []; 	// list of fx spawned
	
	for ( i = 0; i < fire_link_structs.size - 1; i++ )
	{
		dist_to_next = distance( fire_link_structs[ i ].origin, fire_link_structs[ i + 1 ].origin );
		for ( j = 0; j < int( dist_to_next / interval_dist ); j++ )
		{
			// position calculated between the next fire link struct
			position = VectorLerp( fire_link_structs[ i ].origin, fire_link_structs[ i + 1 ].origin, j/int( dist_to_next / interval_dist ) );

			// track spawned fx for clean up later
			fire_fx_array[ fire_fx_array.size ] = position;
			
			// leak safe
			if ( fire_fx_array.size > max_fire_fx ) { break; }
		}
		// leak safe
		if ( fire_fx_array.size > max_fire_fx ) { break; }
	}
	
	// array of vectors where fire fx will play
	fire_trap.fire_fx_locs = fire_fx_array;
	
	// structs where fire fx will play
	fire_trap.fire_link_structs = fire_link_structs;
	
	// setup fire fx
	fire_trap.fire_fx = LoadFX( "vfx/gameplay/alien/vfx_alien_trap_fire" );

	// setup fire trap initial values
	fire_trap.burning			 = false;
	fire_trap.duration			 = CONST_FIRE_TRAP_DURATION;
	fire_trap.base_duration		 = CONST_FIRE_TRAP_DURATION;
	fire_trap.DoT				 = CONST_FIRE_TRAP_DAMAGE_MED;
	fire_trap.damage_time		 = CONST_FIRE_TRAP_DAMAGE_TIME;
	fire_trap.DoT_player		 = CONST_FIRE_TRAP_DAMAGE_PLAYER;
	fire_trap.damage_time_player = CONST_FIRE_TRAP_DAMAGE_TIME_PLAYER;
	
	// setup different sizes that costs different
	fire_trap fire_trap_setup_sizes();
	
	fire_trap.barrel SetCursorHint( "HINT_NOICON" );
	fire_trap.barrel SetHintString( fire_trap.hintString );
	fire_trap.barrel MakeUsable();

	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::add_to_outline_watch_list ( barrel, fire_trap.cost );
	
	return fire_trap;
}

// cost override from radiant setup
fire_trap_setup_sizes()
{
	sizes = [ "small", "medium", "large" ];
	custom_lifespan_array = [];
	custom_lifespan_array["small"] = CONST_FIRE_TRAP_DURATION_SMALL;
	custom_lifespan_array["medium"] = CONST_FIRE_TRAP_DURATION_MED;
	custom_lifespan_array["large"] = CONST_FIRE_TRAP_DURATION_LARGE;
	
	size_index = 1; // default medium
	if ( isdefined( self.barrel.script_noteworthy ) )
	{
		if ( self.barrel.script_noteworthy == "small" )
			size_index = 0;
		if ( self.barrel.script_noteworthy == "large" )
			size_index = 2;
		//ex: "custom small large" for small cost, large lifespan
		if(IsSubStr( self.barrel.script_noteworthy, "custom"))
		{
			tokens = strtok(self.barrel.script_noteworthy, " ");
			switch ( tokens[1] )
			{
				case "small":
					size_index = 0;
					break;
				case "medium":
					size_index = 1;
					break;
				case "large":
					size_index = 2;
					break;					
				default:
					break;
			}
			
			self.custom = tokens[2];
		}
	}
	
	if ( isPlayingSolo() )
		size_index = int( max( 0, size_index - 1 ) );

	if ( sizes[ size_index ] == "small" )
	{
		self.DoT = CONST_FIRE_TRAP_DAMAGE_SMALL;
		self.cost = CONST_FIRE_TRAP_COST_SMALL;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_FIRE_TRAP_SMALL";
	}
	if ( sizes[ size_index ] == "medium" )
	{
		self.DoT = CONST_FIRE_TRAP_DAMAGE_MED;
		self.cost = CONST_FIRE_TRAP_COST_MED;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_FIRE_TRAP_MED";
	}
	if ( sizes[ size_index ] == "large" )
	{
		self.DoT = CONST_FIRE_TRAP_DAMAGE_LARGE;
		self.cost = CONST_FIRE_TRAP_COST_LARGE;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_FIRE_TRAP_LARGE";
	}
	
	if(IsDefined(self.custom))
	{
		self.base_duration = custom_lifespan_array[self.custom];
	}
}

trap_BBprint( trap_type, owner, loc )
{
	// =========================== blackbox print [START] ===========================
	level.alienBBData[ "traps_used" ]++;
	owner maps\mp\alien\_persistence::eog_player_update_stat( "traps", 1 );
	
	trapx = loc[ 0 ];
	trapy = loc[ 1 ];
	trapz = loc[ 2 ];
	traptype = trap_type;
	ownername = "";
	if ( isdefined( owner.name ) )
		ownername = owner.name;
	
	/#
	if ( GetDvarInt( "alien_bbprint_debug" ) > 0 )
	{
		IPrintLnBold( "^8bbprint: alientrap \n" +
					 " traptype=" + traptype +
					 " trapx,y,z=" + loc +
					 " ownername=" + ownername );
	}
	#/

	bbprint( "alientrap",
		    "traptype %s trapx %f trapy %f trapz %f ownername %s ", 
		    traptype,
		    trapx,
		    trapy,
		    trapz,
		    ownername );
	// =========================== [END] blackbox print ===========================
}

// main loop
fire_trap_think()
{
	// self is fire_trap struct
	self 	endon( "disable_fire_trap" );
	level 	endon( "game_ended" );

	while ( isdefined( self ) )
	{
		// [off] - wait for activate
		while ( !self.burning )
		{
			self.barrel waittill( "trigger", owner );

			if ( owner can_activate_trap( self ) )
			{
				thread trap_BBprint( "fire", owner, self.barrel.origin );
				
				level thread maps\mp\alien\_music_and_dialog::playVOForTrapActivation( owner, self.trap_type);
				
				self.owner = owner;
				
				self.barrel SetHintString( "" );
				self.barrel MakeUnUsable();

				// cost the activator
				price =  int( self.cost * ( owner perk_GetTrapCostScalar() ));
				discount = ( self.cost - price );
				owner take_player_currency( price, false, "trap" );
								
				self.duration = int( self.base_duration * ( owner perk_GetTrapDurationScalar() ) );

				//self thread fire_trap_burn( impact_loc );
				self thread sounds_fire_trap( self.barrel.origin );

				self thread fire_trap_burn( self.barrel.origin );
				owner thread stop_firetrap_on_disconnect( self );
				
				// break into [on]
				break;
			}
			else
			{
				wait 0.05;
				owner setLowerMessage( "no_money", &"ALIEN_COLLECTIBLES_NO_MONEY", 3 );
				//owner iprintlnBold( "Fire Trap costs $" + self.cost );
				continue;
			}
		}
		
		if ( alien_mode_has( "outline" ) )
			maps\mp\alien\_outline_proto::remove_from_outline_watch_list( self.barrel );
		
		self waittill( "fire_trap_exhausted" );
		
		// padding
		wait 0.5;

		//self.owner = undefined;
		MarkDangerousNodesInTrigger( self.burn_trig, false );
		self.burning = false;
		self.barrel SetHintString( self.hintString );
		self.barrel MakeUsable();
		
		if ( alien_mode_has( "outline" ) )
			maps\mp\alien\_outline_proto::add_to_outline_watch_list( self.barrel, self.cost );
		
		// ^ loop ^
	}
}

sounds_fire_trap( barrel )
{
	sound_flame_burst = spawn( "script_origin", barrel );
	sound_flame_burst playsound( "alien_incendiary_impact" );
				
	self.sound_flames = spawn( "script_origin", barrel );
	self.sound_flames playloopsound( "fire_trap_fire_lp" );
}

// wait for trap ignition
fire_trap_wait_for_impact()
{
	level endon( "game_ended" );
	self endon( "fire_trap_exhausted" );
	
	while ( 1 )
	{
		// wait for player activation by igniting the fire
		self.activation_trig waittill( "damage", damage, attacker, direction_vec, impact_loc, damage_type );
		
		if ( !isPlayer( attacker ) )
		{
			if ( isdefined( attacker.owner ) && isPlayer( attacker.owner ) )
			{
				attacker = attacker.owner;
			}
			else
			{
				wait 0.05;
				continue;
			}
		}
		
		if ( !isdefined( damage_type ) )
		{
			wait 0.05;
			continue;
		}
		
		// skip no fire igniting damages
		type = ToLower( damage_type );
		switch( type )
		{
			case "unknown":
			case "mod_impact":
			case "mod_melee":
			case "mod_crush":
			case "melee":
				wait 0.05;
				continue;
			default:
				return impact_loc;
		}
		
		return impact_loc;
	}
	
	return undefined;
}

// burn and do damage
fire_trap_burn( fire_start_loc )
{
	level endon( "game_ended" );
	self endon( "fire_trap_exhausted" );

	self thread monitor_fire_trap_exhausted( fire_start_loc );
	MarkDangerousNodesInTrigger( self.burn_trig, true );
	
	wait 2; // padding so players don't get burned
	
	while ( true )
	{
		// waittill someone touches fire
		self.burn_trig waittill( "trigger", victim );

		if ( !isdefined( victim ) 
		    || !isReallyAlive( victim )
		    || ( !isplayer( victim ) && !IsAgent( victim ) )
		    || ( isDefined( victim.burning ) && victim.burning ) )
		{
			continue;
		}
		
		self thread do_damage_over_time( victim );
	}
}

do_damage_over_time( victim )
{
	// self is fire trap struct
	level endon( "game_ended" );
	victim endon( "death" );
	
	if( !isDefined( self.owner ) )
		return;
	
	// only one instance of burn
	victim notify( "fire_trap_burning" );
	victim endon( "fire_trap_burning" );
	
	victim.burning = true;
	
	if ( isplayer( victim ) )
	{
		duration 	= self.damage_time_player;
		DoT			= self.DoT_player;
	}
	else
	{		
		duration 	= self.damage_time * ( self.owner perk_GetTrapDamageScalar() );
		DoT			= self.DoT * level.alien_health_per_player_scalar[ level.players.size ] * ( self.owner perk_GetTrapDamageScalar() );
	}

	should_use_fire_fx = victim is_alien_agent();
		
	if ( should_use_fire_fx )
		victim maps\mp\alien\_alien_fx::alien_fire_on();
	
	interval_time 		= 1;
	damage_per_interval = DoT / ( duration / interval_time );	

	victim do_damage_until_timeout( damage_per_interval, duration, interval_time, self );	
	if ( should_use_fire_fx )
	{
		victim maps\mp\alien\_alien_fx::alien_fire_off();
	}
	victim.burning = undefined;
}

do_damage_until_timeout( damage, duration, interval, attacker )
{
	self endon( "death" );
	attacker.owner endon( "disconnect" );
	elapsed_time = 0;
	while ( elapsed_time < duration && isDefined( attacker.owner ) )
	{
		// create marker for passing in damage type
		attacker.owner.burning_victim = true;
		
		if ( isplayer( self ) )
			self DoDamage( damage, self.origin, undefined, attacker.burn_trig  );
		else if ( IsDefined( attacker ) && isDefined( attacker.owner ) )
			self DoDamage( damage, self.origin, attacker.owner, attacker.burn_trig );
	
		elapsed_time += 1.0;		
		wait interval;
	}
}


// notifies when fire burns out, in predefined time
monitor_fire_trap_exhausted( fire_start_loc )
{
	level endon( "game_ended" );
	self endon( "owner_disconnected" );

	// sort fire fx locs array by closest to fire start loc
	// this is to start fire chain originated from point of fire start, ex: bullet impact location
	fire_fx_locs 	= sort_vectors_by_distance( self.fire_fx_locs, fire_start_loc );
	fx_interval 	= 0.25; // fx interval timing
	
	// play fx in sequence
	self.fire_fx_array = play_fire( fire_fx_locs, fx_interval );

	// wait total burn duration
	wait self.duration;
	
	// end it
	self notify( "fire_trap_exhausted" );
	if( isDefined( self.fire_fx_array ) )
		self kill_fire( self.fire_fx_array );
}

sort_vectors_by_distance( array, vec )
{
	sorted_array = [];
	
	while ( array.size )
	{
		idx = get_closest_vec_index( array, vec );
		sorted_array[ sorted_array.size ] = array[ idx ];
		array = array_remove( array, array[idx] );
	}
	
	return sorted_array;
}

get_closest_vec_index( array, vec )
{
	closest_key = 0;
	closest_element = array[ 0 ];
	foreach ( key, element in array )
	{
		if ( distance( element, vec ) <= distance( closest_element, vec ) )
		{
			closest_key = key;
			closest_element = element;
		}
	}
	return closest_key;
}

// param 1 = array of locations to play fx, param 2 = delay per fx
play_fire( fire_fx_locs, fx_interval )
{
	fire_fx_array = []; // list of fx spawned
	for ( i = 0; i < fire_fx_locs.size; i++ )
	{
		// spawn fire fx per spacing
		gasFire = SpawnFx( self.fire_fx, fire_fx_locs[ i ] );
		triggerFx( gasFire );
		
		// track spawned fx for clean up later
		fire_fx_array[ fire_fx_array.size ] = gasFire;
		
		// wait delay between fx
		wait fx_interval;
	}
	
	return fire_fx_array;
}

// kill all fire fx
kill_fire( fire_fx_array )
{
	if ( isDefined( self.sound_flames ) )
		self thread sounds_kill_flames();
	//clean up list of fx spawned
	if ( isDefined( fire_fx_array ) )
	{
		foreach ( gasFire in fire_fx_array )
		{	
			if ( isDefined( gasFire ) )
				gasFire delete();
		}
	}
}

sounds_kill_flames()
{
	self.sound_flames endon( "death" );
	
	flames_end = spawn( "script_origin", self.sound_flames.origin );
	flames_end playsound( "fire_trap_fire_end_lp" );
	
	wait 0.5;
	
	self.sound_flames stopsounds();
	wait 0.1;
	self.sound_flames delete();	
}

//*****************************************************************
//					ELECTRIC TRAPS: COMMON
//*****************************************************************

CONST_SHOCK_INTERVAL			= 0.35; // time delay between shocks
CONST_GENERATOR_POWER 			= 20; 	// number of shock attacks for max capacity

// run electric generator
run_generator()
{
	self notify( "electric_trap_turned_on" );
	
	self eletric_trap_asserts();
	
	self.running 	= true;
	self.capacity 	= self.max_capacity;
	self.generator 	SetHintString( "" );
	self.generator 	MakeUnUsable();
}

// shocks victim!
trap_shock( victim, damage_override, use_capacity )
{
	self endon( "electric_trap_turned_off" );
	victim endon( "death" );
	
	if( !isDefined( self.owner ) )
		return;

	self eletric_trap_asserts();

	shock_damage = self.shock_damage * level.alien_health_per_player_scalar[ level.players.size ] * (self.owner perk_GetTrapDamageScalar() );
	if ( isdefined( damage_override ) )
		shock_damage = damage_override;
	
	// self is trap struct
	victim.shocked = true;
	if ( !isalive( victim ) )
		return;

	// fx on victim
	playfx( self.shock_fx[ "shock" ], 	victim.origin + ( 0, 0, 32 ) );
	playfx( self.shock_fx[ "sparks" ], 	victim.origin + ( 0, 0, 32 ) );	
	
	debug_electric_trap_print( victim.origin, "hp:" + victim.health, ( 0.5, 0.5, 1 ), 0.75, 2, 1 );
	
	victim.pain_registered = true; // no pain logic when shocked, for now
	wait 0.05;
	
	// allow damage of self if victim is player
	owner = self.owner;
	if ( isplayer( victim ) )
		owner = self.generator;
	
	if ( isdefined( use_capacity ) && use_capacity )
	{
		// remove one shock amount from total shock capacity
		self.capacity--;
	}

	victim DoDamage( shock_damage, victim.origin, owner, self.generator, "MOD_EXPLOSIVE" );
	
	// sfx for trap shock
	playSoundAtPos( victim.origin, "alien_fence_shock" );
	
	if ( !isalive( victim ) && IsAgent( victim ) )
	{
		pos = victim wait_for_ragdoll_pos();
		if ( isdefined( pos ) )
		{
			wait 0.1;
			PhysicsExplosionSphere( pos, 300, 150, 5 );
			playfx( self.shock_fx[ "shock" ], 	pos );
			playfx( self.shock_fx[ "sparks" ], 	pos );
		}
	}
	
	random_delay = RandomFloatRange( self.shock_interval/2, self.shock_interval*1.5 );
	victim thread time_out_shocked_state( random_delay );
}

// this will catch shock state reset in case trap times out during shock and kills trap_shock()
time_out_shocked_state( delay )
{
	self endon( "death" );
	self endon( "disconnect" );
	wait delay;
	self.shocked = false;
}

wait_for_ragdoll_pos()
{
	self endon( "ragdoll_timed_out" );
	self thread ragdoll_timeout( 1 );
	self waittill( "in_ragdoll", pos );
	return pos;
}

ragdoll_timeout( time )
{
	wait time;
	if ( isdefined( self ) )
		self notify( "ragdoll_timed_out" );
}

debug_electric_trap_print( pos, string, color, alpha, scale, time )
{
	/#
	if ( GetDvarInt( "debug_trap" ) == 1 )
		thread debug_electric_trap_print_raw( pos, string, color, alpha, scale, time );
	#/
}

debug_electric_trap_print_raw( pos, string, color, alpha, scale, time )
{
	level endon ( "game_ended" );
	while ( time > 0 )
	{
		Print3d( pos, string, color, alpha, scale, 1 );
		time -= 0.05;
		wait( 0.05 );
	}
}

// global electric trap think
run_electric_trap( play_trap_on_fx, play_trap_off_fx, play_ambient_shocks )
{
	// self is trap struct
	self 	endon( "death" );
	level 	endon( "game_ended" );
	
	self eletric_trap_asserts();
	
	// shows health of trap
	if ( IsDefined( play_ambient_shocks ) )
		self thread [[ play_ambient_shocks ]]();
	
	while ( isdefined( self ) )
	{
		// [off] - wait for activate
		while ( !self.running )
		{
			self.generator waittill( "trigger", owner );

			if ( owner can_activate_trap( self ) )
			{
				thread trap_BBprint( "electric", owner, self.generator.origin );
				
				level thread maps\mp\alien\_music_and_dialog::playVOForTrapActivation( owner, self.trap_type );
				
				self.owner = owner;
				owner thread stop_electric_trap_on_disconnect( self );

				if ( isdefined( play_trap_on_fx ) )
					self thread [[ play_trap_on_fx ]]();

				// sfx loop for trap ambient hum
				self.shock_trig playLoopSound( "alien_fence_hum_lp" );
				
				// sfx loop for generator running
				self.generator playLoopSound( "alien_fence_gen_lp" );
				
				// cost the activator
				price = int( self.cost * ( owner perk_GetTrapCostScalar() ) );
				discount = self.cost - price;
				owner take_player_currency( price, false, "trap" );
				
				self.capacity = int( CONST_GENERATOR_POWER * owner perk_GetTrapDurationScalar() );		
				// break into [on]
				break;
			}
			else
			{
				wait 0.05;
				owner setLowerMessage( "no_money", &"ALIEN_COLLECTIBLES_NO_MONEY", 3 );
				//owner iprintlnBold( trap_cost_string );
				continue;
			}
		}
		
		if ( alien_mode_has( "outline" ) )
			maps\mp\alien\_outline_proto::remove_from_outline_watch_list( self.generator );
		
		// run generator visuals
		self thread run_generator();
		
		on_time = gettime();
		
		// [on] - wait for victim
		while ( self.running && self.capacity > 0 && isDefined( self.owner ) && IsSentient( self.owner ) )
		{
			elapsed_time = max( 0, ( GetTime() - on_time ) / 1000 );
			time_left = max( 5, self.life_span - elapsed_time ); // 5 seconds linger time for consecutive shocks
			
			victim = self wait_for_trigger_timeout( time_left * ( self.owner perk_GetTrapDurationScalar() ) );

			// undefined if above wait earlied out due to time out
			if ( !isdefined( victim ) && ( isdefined( self.trap_timed_out ) && self.trap_timed_out ) )
				break;
			
			if ( self.capacity <= 0 || !isDefined( self.owner )  )
			{
				// break into [off]
				break;
			}
			
			if ( isAgent( victim ) && isalive( victim ) && !( isdefined( victim.shocked ) && victim.shocked ) )
				self thread trap_shock( victim, undefined, true );
			
			if ( isdefined( self.player_damage ) && isPlayer( victim ) && isAlive( victim ) && !( isdefined( victim.shocked ) && victim.shocked )  )
				self thread trap_shock( victim, self.player_damage, false );
		}
		
		if ( alien_mode_has( "outline" ) )
			maps\mp\alien\_outline_proto::add_to_outline_watch_list( self.generator, self.cost );
		
		self notify( "electric_trap_turned_off" );
		
		if( isDefined( self.owner ) && isALive( self.owner ) )
		{
			if ( self.trap_type == "traps_fence" )
				self.owner setLowerMessage( "electric_fence_offline", &"ALIEN_COLLECTIBLES_ELECTRIC_FENCE_OFFLINE", 3 );	
			else
				self.owner setLowerMessage( "electric_fence_offline", &"ALIENS_PATCH_ELECTRIC_TRAP_OFFLINE", 3 );
		}
			
		// padding
		wait 0.5;
		
		if ( isdefined( play_trap_off_fx ) )
			self thread [[ play_trap_off_fx ]]();
		
		self.owner = undefined;
		self.running = false;
		self.generator SetHintString( self.hintString );
		self.generator MakeUsable();
		self.generator stopLoopSound( "alien_fence_gen_lp" );
		self.generator playSound( "alien_fence_gen_off" );
		self.shock_trig stopLoopSound( "alien_fence_hum_lp" );
		
		// ^ loop ^
	}
}

//self = the player who activatged the trap
stop_electric_trap_on_disconnect( trap )
{
	trap endon( "electric_trap_turned_off" );
	trap endon( "timed_out" );
	
	self waittill( "disconnect" );
	trap notify ( "electric_trap_turned_off" );
	
}
stop_firetrap_on_disconnect( trap )
{
	trap endon( "timed_out" );
	trap endon( "fire_trap_exhausted" );
	self waittill( "disconnect" );
	
	trap thread kill_fire( trap.fire_fx_array );
	trap notify ( "owner_disconnected" );
	trap notify( "fire_trap_exhausted" );
}

wait_for_trigger_timeout( timeout )
{
	self endon( "electric_trap_turned_off" );
	self thread timeout_watch( timeout );
	
	self endon( "timed_out" );
	
	self.shock_trig waittill( "trigger", victim );
	return victim;
}

timeout_watch( timeout )
{
	self endon( "electric_trap_turned_off" );
	self.trap_timed_out = false;
	
	wait timeout;
	
	self notify( "timed_out" );
	self.trap_timed_out = true;
}

eletric_trap_asserts()
{
	generic_msg = " is not defined in eletric trap setup function.";

	assertex( isdefined( self.cost ), 			"trap_struct.cost" 			+ generic_msg );
	assertex( isdefined( self.hintString ), 	"trap_struct.hintString" 	+ generic_msg );	
	assertex( isdefined( self.running ), 		"trap_struct.running" 		+ generic_msg );
	assertex( isdefined( self.generator ), 		"trap_struct.generator" 	+ generic_msg );
	
	assertex( isdefined( self.shock_fx ), 		"trap_struct.shock_fx" 		+ generic_msg );
	assertex( isdefined( self.shock_interval ), "trap_struct.shock_interval"+ generic_msg );
	assertex( isdefined( self.shock_damage ), 	"trap_struct.shock_damage" 	+ generic_msg );
	assertex( isdefined( self.shock_trig ), 	"trap_struct.shock_trig" 	+ generic_msg );
	
	assertex( isdefined( self.capacity ), 		"trap_struct.capacity" 		+ generic_msg );
	assertex( isdefined( self.max_capacity ), 	"trap_struct.max_capacity" 	+ generic_msg );
	assertex( isdefined( self.trap_type ), 		"trap_struct.trap_type" 	+ generic_msg );
}

//*****************************************************************
//					ELECTRIC TRAPS: PUDDLE
//*****************************************************************

CONST_PUDDLE_COST				= 750; 	// currency cost to enable trap
CONST_PUDDLE_COST_SMALL			= 300;
CONST_PUDDLE_COST_MED			= 500;
CONST_PUDDLE_COST_LARGE			= 750;

CONST_PUDDLE_LIFE_SPAN_SMALL	= 90;	// time out
CONST_PUDDLE_LIFE_SPAN_MED		= 120;
CONST_PUDDLE_LIFE_SPAN_LARGE	= 150;

CONST_PUDDLE_SHOCK_DAMAGE 		= 200; 	// damage per shock
CONST_PUDDLE_PLAYER_DAMAGE		= 3;	// damage done to player

electric_puddle_init()
{
	generators = getentarray( "puddle_generator", "targetname" );
	if ( !isdefined( generators ) || generators.size == 0 )
		return;

	// wait before players are ready, we decide how to setup usage based on match type
	while ( !isdefined( level.players ) || level.players.size < 1 )
		wait 0.05;
	
	level.electric_puddles = [];
	foreach ( generator in generators )
	{
		generator.damagefeedback = false;
		puddle = setup_electric_puddle( generator );
		level.electric_puddles[ level.electric_puddles.size ] = puddle;
		puddle thread run_electric_trap( ::play_puddle_on_fx, ::play_puddle_off_fx, ::ambient_puddle_shocks );
	}
}

setup_electric_puddle( generator )
{
	puddle = SpawnStruct();
	puddle.trap_type = "traps_puddle";
	
	// setup generator for use
	puddle.generator = generator;
	
	// setup damage trigger
	puddle.shock_trig = getent( generator.target, "targetname" );
	
	// setup electro contact point between wire and puddle
	puddle.contact_points = [];
	cur_contact_point = getstruct( puddle.shock_trig.target, "targetname" );
	puddle.contact_points[ 0 ] = cur_contact_point;
	while ( isdefined( cur_contact_point.target ) )
	{
		contact_point = getstruct( cur_contact_point.target, "targetname" );
		puddle.contact_points[ puddle.contact_points.size ] = contact_point;
		cur_contact_point = contact_point;
	}
	
	// setup shock fx
	puddle.shock_fx[ "shock" ]			= LoadFX( "vfx/moments/alien/fence_lightning_shock" );
	puddle.shock_fx[ "ambient_flash" ]	= LoadFX( "vfx/moments/alien/fence_lightning_turn_on" );
	puddle.shock_fx[ "sparks" ]			= loadfx( "fx/explosions/transformer_sparks_f_sound" );
	puddle.shock_fx[ "sparks_sm" ]		= loadfx( "fx/explosions/transformer_sparks_b_sound" );

	// setup electric trap initial values
	puddle.running 			= false;
	puddle.capacity			= CONST_GENERATOR_POWER;
	puddle.max_capacity		= CONST_GENERATOR_POWER;

	puddle.player_damage 	= CONST_PUDDLE_PLAYER_DAMAGE;
	puddle puddle_trap_setup_sizes();
	
	puddle.generator SetCursorHint( "HINT_NOICON" );
	puddle.generator SetHintString( puddle.hintString );
	puddle.generator MakeUsable();

	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::add_to_outline_watch_list ( generator, puddle.cost );
	
	return puddle;
}

puddle_trap_setup_sizes()
{
	sizes = [ "small", "medium", "large" ];
	custom_lifespan_array = [];
	custom_lifespan_array["small"] = CONST_PUDDLE_LIFE_SPAN_SMALL;
	custom_lifespan_array["medium"] = CONST_PUDDLE_LIFE_SPAN_MED;
	custom_lifespan_array["large"] = CONST_PUDDLE_LIFE_SPAN_LARGE;
	
	size_index = 1; // default medium
	if ( isdefined( self.generator.script_noteworthy ) )
	{
		if ( self.generator.script_noteworthy == "small" )
			size_index = 0;
		if ( self.generator.script_noteworthy == "large" )
			size_index = 2;
		//ex: "custom small large" for small cost, large lifespan
		if(IsSubStr( self.generator.script_noteworthy, "custom"))
		{
			tokens = strtok(self.generator.script_noteworthy, " ");
			switch ( tokens[1] )
			{
				case "small":
					size_index = 0;
					break;
				case "medium":
					size_index = 1;
					break;
				case "large":
					size_index = 2;
					break;					
				default:
					break;
			}
			
			self.custom = tokens[2];
		}
	}

	if ( isPlayingSolo() )
		size_index = int( max( 0, size_index - 1 ) );

	self.shock_damage	= CONST_PUDDLE_SHOCK_DAMAGE;
	self.shock_interval	= CONST_SHOCK_INTERVAL;
	
	if ( sizes[ size_index ] == "small" )
	{
		self.cost = CONST_PUDDLE_COST_SMALL;
		self.life_span = CONST_PUDDLE_LIFE_SPAN_SMALL;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_PUDDLE_SMALL";
	}
	if ( sizes[ size_index ] == "medium" )
	{
		self.cost = CONST_PUDDLE_COST_MED;
		self.life_span = CONST_PUDDLE_LIFE_SPAN_MED;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_PUDDLE_MED";
	}
	if ( sizes[ size_index ] == "large" )
	{
		self.cost = CONST_PUDDLE_COST_LARGE;
		self.life_span = CONST_PUDDLE_LIFE_SPAN_LARGE;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_PUDDLE_LARGE";
	}
	
	if(IsDefined(self.custom))
	{
		self.life_span = custom_lifespan_array[self.custom];
	}
}

play_puddle_off_fx()
{
	//playfx( self.shock_fx[ "shock" ], 	self.contact_points[ 0 ].origin );
	playfx( self.shock_fx[ "sparks" ], 	self.contact_points[ 0 ].origin );
	
	count = 3;
	while ( count > 0 )
	{
		//playfx( self.shock_fx[ "shock" ], 	self.generator.origin );
		playfx( self.shock_fx[ "sparks" ], 	self.generator.origin );
		
		count--;
		wait 0.2;
	}
}

play_puddle_on_fx()
{
	//playfx( self.shock_fx[ "shock" ], 	self.contact_points[ 0 ].origin );
	playfx( self.shock_fx[ "sparks" ], 	self.contact_points[ 0 ].origin );
}

ambient_puddle_shocks()
{
	// self is fence struct
	self 	endon( "death" );
	level 	endon( "game_ended" );	

	shock	= SpawnFx( self.shock_fx[ "sparks" ], self.contact_points[ 0 ].origin );
	
	sparks = [];
	foreach ( contact_point in self.contact_points )
		sparks[ sparks.size ] = SpawnFx( self.shock_fx[ "sparks" ], contact_point.origin );
	
	ambient_on = false;
	
	while ( 1 )
	{
		while ( !self.running )
		{
			ambient_on = false;
			self waittill( "electric_trap_turned_on" );
		}
		
		if ( !ambient_on )
			ambient_on = true;
		
		triggerFx( shock );
		wait 0.25;
		triggerFx( shock );
		
		foreach ( idx, spark in sparks )
		{
			// always play contact point spark, which is index 0
			if ( idx == 0 )
			{
				triggerFx( spark );
				continue;
			}
			
			// 1/4th chance of playing extra sparks
			if( cointoss() )
				triggerFx( spark );
		}
		
		if ( !is_true ( level.skip_radius_damage_on_puddles ) )
			RadiusDamage( self.contact_points[ 0 ].origin, 80, 20, 5 );
		waittill_any_timeout( RandomIntRange( 3, 5 ), "electric_trap_turned_off" );
	}
}

//*****************************************************************
//					ELECTRIC TRAPS: FENCE
//*****************************************************************

// <NOTE JC> These costs are likely to be replaced by some table lookup through some kind of init process that Colin is setting up
CONST_FENCE_COST				= 750; // currency cost to enable fence
CONST_FENCE_COST_SMALL			= 300;
CONST_FENCE_COST_MED			= 500;
CONST_FENCE_COST_LARGE			= 750;

CONST_FENCE_LIFE_SPAN			= 120;	// time out
CONST_FENCE_LIFE_SPAN_SMALL		= 90;
CONST_FENCE_LIFE_SPAN_MED		= 120;
CONST_FENCE_LIFE_SPAN_LARGE		= 150;

CONST_FENCE_SHOCK_DAMAGE 		= 200; 	// damage per shock
CONST_FENCE_PLAYER_DAMAGE		= 2;

electric_fence_init()
{
	generators = getentarray( "fence_generator", "targetname" );
	
	if ( !isdefined( generators ) || generators.size == 0 )
		return;
	
	// wait before players are ready, we decide how to setup usage based on match type
	while ( !isdefined( level.players ) || level.players.size < 1 )
		wait 0.05;
	
	level.electric_fences = [];
	foreach ( generator in generators )
	{
		generator.damagefeedback = false;
		fence = setup_electric_fence( generator );
		level.electric_fences[ level.electric_fences.size ] = fence;
		
		fence thread run_electric_trap( ::play_fence_on_fx, ::play_fence_off_fx, ::ambient_fence_shocks );
	}
}

setup_electric_fence( generator )
{
	fence = SpawnStruct();
	fence.trap_type = "traps_fence";
	
	// setup generator for use
	fence.generator = generator;

	// setup fence corners
	generator_targets			= getstructarray( generator.target,	"targetname" );
	fence_sparks				= [];
	top_left					= generator_targets[ 0 ];
	foreach ( generator_target in generator_targets )
	{
		if ( isdefined( generator_target.script_noteworthy ) && generator_target.script_noteworthy == "fence_sparks" )
			fence_sparks[ fence_sparks.size ] = generator_target;
		
		if ( isdefined( generator_target.script_noteworthy ) && generator_target.script_noteworthy == "fence_area" )
			top_left = generator_target;
	}
	bottom_left 				= getstruct( top_left.target, 		"targetname" );
	bottom_right 				= getstruct( bottom_left.target, 	"targetname" );
	top_right					= getstruct( bottom_right.target, 	"targetname" );
	
	fence.fence_top_left_angles	= top_left.angles;
	fence.fence_top_left 		= top_left.origin;
	fence.fence_top_right 		= top_right.origin;
	fence.fence_bottom_left 	= bottom_left.origin;
	fence.fence_bottom_right 	= bottom_right.origin;
	fence.fence_height 			= fence.fence_top_left[ 2 ] - fence.fence_bottom_left[ 2 ];
	fence.fence_center			= get_center( top_left.origin, top_right.origin, bottom_left.origin, bottom_right.origin );
	fence.fence_sparks			= fence_sparks;
	
	// setup damage trigger
	fence.shock_trig			= getent( top_right.target, "targetname" );
	fence.optimal_height		= 100; // should be tweaked based on geo
	
	// setup fence fx
	fence.shock_fx[ "ambient" ]		= LoadFX( "vfx/moments/alien/fence_lightning_ambient" );
	fence.shock_fx[ "shock" ]		= LoadFX( "vfx/moments/alien/fence_lightning_shock" );
	fence.shock_fx[ "turn_on" ]		= LoadFX( "vfx/moments/alien/fence_lightning_turn_on" );
	
	fence.shock_fx[ "sparks" ]		= loadfx( "fx/explosions/transformer_sparks_b_sound" );
	fence.shock_fx[ "sparks_sm" ]	= loadfx( "fx/explosions/transformer_sparks_f_sound" );
	//fence.shock_fx[ "bar" ]		= LoadFX( "vfx/gameplay/alien/vfx_alien_fence_bolt_horizontal" );
	
	fence.shock_bar_fx_ent		= spawn( "script_origin", fence.fence_center );
	fence.shock_bar_fx_ent 		setmodel( "tag_origin" );

	// setup fence initial values
	fence.running 				= false;
	fence.capacity				= CONST_GENERATOR_POWER;
	fence.max_capacity			= CONST_GENERATOR_POWER;
	
	fence.player_damage 		= CONST_FENCE_PLAYER_DAMAGE;
	fence fence_trap_setup_sizes();	
	
	fence.generator SetCursorHint( "HINT_NOICON" );
	fence.generator SetHintString( fence.hintString );
	fence.generator MakeUsable();

	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::add_to_outline_watch_list ( generator, fence.cost );	
	
	return fence;
}

fence_trap_setup_sizes()
{
	sizes = [ "small", "medium", "large" ];
	custom_lifespan_array = [];
	custom_lifespan_array["small"] = CONST_FENCE_LIFE_SPAN_SMALL;
	custom_lifespan_array["medium"] = CONST_FENCE_LIFE_SPAN_MED;
	custom_lifespan_array["large"] = CONST_FENCE_LIFE_SPAN_LARGE;
	
	
	size_index = 1; // default medium
	if ( isdefined( self.generator.script_noteworthy ) )
	{
		if ( self.generator.script_noteworthy == "small" )
			size_index = 0;
		if ( self.generator.script_noteworthy == "large" )
			size_index = 2;
		//ex: "custom small large" for small cost, large lifespan
		if(IsSubStr( self.generator.script_noteworthy, "custom"))
		{
			tokens = strtok(self.generator.script_noteworthy, " ");
			switch ( tokens[1] )
			{
				case "small":
					size_index = 0;
					break;
				case "medium":
					size_index = 1;
					break;
				case "large":
					size_index = 2;
					break;					
				default:
					break;
			}
			
			self.custom = tokens[2];
		}
	}

	if ( isPlayingSolo() )
		size_index = int( max( 0, size_index - 1 ) );

	// scaled based on height, shorter the fence the stronger the shock, sinse aliens touch it less
	self.shock_damage		= int( min( 800, CONST_FENCE_SHOCK_DAMAGE * max ( 1, ( self.optimal_height / self.fence_height ) ) ) );
	self.shock_interval		= CONST_SHOCK_INTERVAL;
	
	if ( sizes[ size_index ] == "small" )
	{
		self.cost = CONST_FENCE_COST_SMALL;
		self.life_span = CONST_FENCE_LIFE_SPAN_SMALL;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_FENCE_SMALL";
		
		if ( isDefined( level.generic_electric_trap_check ) && self [[level.generic_electric_trap_check]]() )
			self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_PUDDLE_SMALL";			
	}
	if ( sizes[ size_index ] == "medium" )
	{
		self.cost = CONST_FENCE_COST_MED;
		self.life_span = CONST_FENCE_LIFE_SPAN_MED;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_FENCE_MED";
		
		if ( isDefined( level.generic_electric_trap_check ) && self [[level.generic_electric_trap_check]]() )
			self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_PUDDLE_MED";
	}
	if ( sizes[ size_index ] == "large" )
	{
		self.cost = CONST_FENCE_COST_LARGE;
		self.life_span = CONST_FENCE_LIFE_SPAN_LARGE;
		self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_FENCE_LARGE";
		
		if ( isDefined( level.generic_electric_trap_check ) && self [[level.generic_electric_trap_check]]() )
			self.hintString = &"ALIEN_COLLECTIBLES_ACTIVATE_PUDDLE_LARGE";
	}
	
	if(IsDefined(self.custom))
	{
		self.life_span = custom_lifespan_array[self.custom];
	}	
}

get_center( vec0, vec1, vec2, vec3 )
{
	x = ( vec0[ 0 ] + vec1[ 0 ] + vec2[ 0 ] + vec3[ 0 ] ) / 4;
	y = ( vec0[ 1 ] + vec1[ 1 ] + vec2[ 1 ] + vec3[ 1 ] ) / 4;
	z = ( vec0[ 2 ] + vec1[ 2 ] + vec2[ 2 ] + vec3[ 2 ] ) / 4;
	
	return ( x, y, z );
}

ambient_fence_shocks()
{
	// self is fence struct
	self 	endon( "death" );
	level 	endon( "game_ended" );	
	
	ambient_on = false;
	
	while ( 1 )
	{
		while ( !self.running )
		{
			ambient_on = false;
			StopFXOnTag( self.shock_fx[ "ambient" ], self.shock_bar_fx_ent, "tag_origin" );
			self waittill( "electric_trap_turned_on" );
		}
		
		if ( !ambient_on )
		{
			PlayFXOnTag( self.shock_fx[ "ambient" ], self.shock_bar_fx_ent, "tag_origin" );
			ambient_on = true;
		}
		
		fence_hp_ratio 	= self.capacity / self.max_capacity;
		height 			= self.fence_height * fence_hp_ratio;
		end_pos_left	= self.fence_bottom_left + ( 0, 0, height );
		end_pos_right	= self.fence_bottom_right + ( 0, 0, height );
		end_pos_center 	= ( self.fence_center[ 0 ], self.fence_center[ 1 ], end_pos_right[ 2 ] );
		
		playfx( self.shock_fx[ "sparks_sm" ], end_pos_left );
		wait 0.3;
		playfx( self.shock_fx[ "sparks_sm" ], end_pos_center );
		wait 0.3;
		playfx( self.shock_fx[ "sparks_sm" ], end_pos_right );
		
		if ( isdefined( self.fence_sparks ) )
		{
			foreach ( spark in self.fence_sparks )
			{
				playfx( self.shock_fx[ "sparks_sm" ], spark.origin );
				wait 0.3;
			}
		}
		
		debug_electric_trap_print( self.generator.origin, "Power: " + fence_hp_ratio, ( 0.5, 0.5, 1 ), 0.75, 3, 3 );
		waittill_any_timeout( RandomIntRange( 2, 3 ), "electric_trap_turned_off" );
	}
}

play_fence_off_fx()
{
	playfx( self.shock_fx[ "shock" ], 	self.fence_top_left );
	playfx( self.shock_fx[ "sparks" ], 	self.fence_top_left );
	
	playfx( self.shock_fx[ "shock" ], 	self.fence_top_right );
	playfx( self.shock_fx[ "sparks" ], 	self.fence_top_right );
	
	count = 3;
	while ( count > 0 )
	{
		playfx( self.shock_fx[ "shock" ], 	self.generator.origin );
		playfx( self.shock_fx[ "sparks" ], 	self.generator.origin );
		
		count--;
		wait 0.2;
	}
}

play_fence_on_fx()
{
	playfx( self.shock_fx[ "shock" ], 	self.fence_top_left );
	playfx( self.shock_fx[ "sparks" ], 	self.fence_top_left );

	playfx( self.shock_fx[ "shock" ], 	self.fence_top_right );
	playfx( self.shock_fx[ "sparks" ], 	self.fence_top_right );
}
	
//*****************************************************************
//					Turrets
//*****************************************************************

CONST_TURRET_COST			= 750; // currency cost to use a turret
CONST_TURRET_BULLET_LIMIT   = 300; // turret will be disabled after this many bullets fired

turret_monitorUse()
{
	level endon( "game_ended" );
		
	self SetCursorHint( "HINT_NOICON" );
	self MakeUsable();

	// wait till features are defined by level script
	wait 0.05;
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::add_to_outline_watch_list ( self, CONST_TURRET_COST );
	
	disable_turret();
	
	while ( true )
	{
		self waittill ( "trigger", player );
		
		if ( !isPlayer ( player ) )
			continue;
		
		if ( player is_holding_deployable()  )
		{
			player setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HOLDING", 3 );
			continue;
		}
		
		turret_cost = int( CONST_TURRET_COST * ( player perk_GetTrapCostScalar() ) );
		
		if ( !is_turret_enabled() )  // player tries to buy the turret
		{
			if ( player can_activate_turret() )
			{
				player take_player_currency( turret_cost, false, "trap" );
				enable_turret();
				level thread maps\mp\alien\_music_and_dialog::playVOForSentry( player, "minigun" );
				self thread monitor_player_use(); // handles the ammo counter hud				
			}
			else
			{
				player setLowerMessage( "no_money", &"ALIEN_COLLECTIBLES_NO_MONEY", 3 );
				//player iprintlnBold( "Turret costs $" + turret_cost );
			}
		}
		else   // player uses the turret
		{
			self.owner = player;
			wait_for_disable_turret();
			disable_turret();
		}
	}
}

wait_for_disable_turret()
{
	thread watch_bullet_fired();

	self waittill ( "disable_turret" );
}

watch_bullet_fired()
{
	self endon ( "disable_turret" );
	self notify( "stop_fire_monitor" );
	self endon( "stop_fire_monitor" );
	
	bullet_fired = 0;
	turret_ammo = int( CONST_TURRET_BULLET_LIMIT * self.owner perk_GetTrapDurationScalar() );
	self.turret_ammo = turret_ammo;	
	fireTime = weaponFireTime( self.weaponinfo );
	while ( true )
	{
		self waittill ( "turret_fire" );
		self getturretowner() notify( "turret_fire" );
		self.heatLevel += fireTime;
		bullet_fired++;
		self.cooldownWaitTime = fireTime;
		self.turret_ammo = ( turret_ammo - bullet_fired );
		if ( bullet_fired > turret_ammo )
		{
			self.turret_ammo = 0;
			break;
		}
		self.owner set_turret_ammocount( self.turret_ammo  );
	}	
	if ( isDefined( self.owner ) && isAlive ( self.owner ) ) 
		self.owner thread wait_for_player_to_dismount_turret();

	self notify ( "disable_turret" );
}

is_turret_enabled()
{
	return self.enabled;
}

disable_turret()
{
	self.enabled = false;
	self SetHintString( &"ALIEN_COLLECTIBLES_ACTIVATE_TURRET" );
	self TurretFireDisable();
	self makeTurretInoperable();
}

enable_turret()
{
	self.enabled = true;
	self SetHintString( "" );
	self TurretFireEnable();
	self makeTurretOperable();
}

can_activate_turret()
{
	// self is player
	return self player_has_enough_currency( CONST_TURRET_COST );
}

//wait for players to jump on the turret and handle the ammo counter hud
monitor_player_use()
{
	self endon ( "turret_disabled" );
	while ( 1 )
	{
		self waittill( "trigger",user );
		
		if ( !isDefined ( user ) || !isAlive ( user ) )
			continue;
		
		if ( user is_holding_deployable()  )
		{
			user setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HOLDING", 3 );
			continue;
		}
		
		if ( user IsUsingTurret() )
		{
			self.owner = user;
			while ( !isDefined ( self.turret_ammo ) ) //wait for the ammo to be set on the turret
			{
				wait ( 0.05 );
			}
			if( !is_chaos_mode() )
				user disable_special_ammo();
			user show_turret_icon( 2 );
			user set_turret_ammocount( self.turret_ammo );
			user SetClientOmnvar( "ui_alien_turret_overheat",0 );
			self thread turret_overheat_monitor( user );
			self thread turret_cooldown_monitor();
			self thread clear_turret_ammo_counter_on_dismount( user );
			self thread clear_turret_ammo_counter_on_death( user );
			user setLowerMessage( "disengage_turret", &"ALIEN_COLLECTIBLES_DISENGAGE_TURRET", 4 );
		}
		else 
		{
			user hide_turret_icon();
			if( !is_chaos_mode() )
				user enable_special_ammo();
			self.owner = undefined;
			user SetClientOmnvar( "ui_alien_turret_overheat",-1 );
			user clearLowerMessage( "disengage_turret" );
		}
	}
}

//self = a turret
turret_cooldown_monitor()
{
	self endon ( "death" );	
	self notify( "stop_cooldown_monitor" );
	self endon( "stop_cooldown_monitor" );
	self endon( "turret_disabled" );
	
	while( true )
	{
		if( self.heatLevel > 0 )
		{
			if( self.cooldownWaitTime <= 0 )
			{
				self.heatLevel = max( 0, self.heatLevel - 0.05 );
			}
			else
			{
				self.cooldownWaitTime = max( 0, self.cooldownWaitTime - 0.05 );
			}
		}

		wait( 0.05 );
	}
}


//self = a turret
turret_overheat_monitor( player )
{
	self notify( "overheat_monitor" );
	self endon( "overheat_monitor" );
	self endon( "turret_disabled" );
	self.heatLevel = 0;
	self.cooldownWaitTime = CONST_TURRET_COOLDOWN_TIME;
	
	player endon( "disconnect" );
	
	submitted_overheat_value = 0;
	for( ;; )
	{
		//	exceptions
		if ( !isReallyAlive( player ) )
		{	self.inUseBy = undefined;
			player SetClientOmnvar( "ui_alien_turret_overheat",-1 );
			break;	
		}					
		if ( !player IsUsingTurret() )
		{
			player SetClientOmnvar( "ui_alien_turret_overheat",-1 );				
			break;
		}
								
		if ( self.heatLevel >= CONST_TURRET_OVERHEAT_TIME )
			barFrac = 1;
		else
			barFrac = self.heatLevel/CONST_TURRET_OVERHEAT_TIME;

		// omnvar throttle 
		throttle = 5;
		new_value = int( barFrac * 100 );
		if ( submitted_overheat_value != new_value )
		{
			if ( new_value <= throttle || ( abs( abs( submitted_overheat_value ) - abs( new_value ) ) > throttle ) )
			{
				player SetClientOmnvar( "ui_alien_turret_overheat" , new_value );
				submitted_overheat_value = new_value;
			}
		}

		wait( 0.05 );
	}

	player SetClientOmnvar( "ui_alien_turret_overheat",-1 );	
}

clear_turret_ammo_counter_on_death( user )
{
	self notify ( "clearammocounterondeath" );
	self endon( "clearammocounterondeath" );

	user endon( "disconnect" );
	
	self waittill( "turret_disabled" );
	user hide_turret_icon();
	user clearLowerMessage( "disengage_turret" );
}

clear_turret_ammo_counter_on_dismount( user )
{
	self notify( "dimountammocounter" );
	self endon ( "dismountammocounter" );
	user endon( "disconnect" );
	while ( user IsUsingTurret() ) //wait for the player to get off the turret before clearing it's owner
	{
		wait ( .1 );
	}
	user hide_turret_icon();
	self.owner  = undefined;
	user clearLowerMessage( "disengage_turret" );
	
	//restore his wepon if he happened to have a riotshield that got destroyed
	if ( user GetCurrentWeapon() == "none" )
	{
		user thread restore_last_valid_weapon();
	}
	
}

//self = a player
restore_last_valid_weapon()
{
	weapons = self GetWeaponsListPrimaries();
	foreach ( weapon in weapons )
	{
		if ( isDefined ( weapon ) && weapon != "none" )
		{
			self SwitchToWeapon ( weapon );
			break;
		}
	}

}


//*****************************************************************
//					Flare Attractor
//*****************************************************************
//self = a player
monitor_flare_use()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	self endon ( "end_monitor_flare_use" );
	
	for ( ;; )
	{
		self waittill( "grenade_fire", flare, weapName );
		
		if ( weapName == "iw6_aliendlc21_mp" ) //sticky flare
		{
			flare thread sticky_flare( self );
			continue;
		}
			
		if ( weapName != "alienflare_mp" )
			continue;
		
		flare make_entity_sentient_mp("allies"); 
		flare.threatbias = CONST_FLARE_THREATBIAS;
	
		msg = flare waittill_notify_or_timeout_return("missile_stuck",7);
		if ( IsDefined( msg ) && msg == "timeout" )
		{
			if ( isDefined( flare ) )
			{
				flare delete();
			}
			continue;
		}
		
		glowStick = spawn( "script_model", flare.origin );
		
		flare delete();
		glowstick setmodel("mil_emergency_flare_mp");
		glowStick.angles = self.angles;
		glowStick.owner = self;
		if ( self maps\mp\alien\_persistence::is_upgrade_enabled( "master_scavenger_upgrade" ) )
			glowStick thread create_flare(level.spawnGlow["enemy"] , self );
		else
			glowStick thread create_flare(level.spawnGlow["friendly"] , self );
		self TakeWeapon( "alienflare_mp" );

	}
}

//self is the thrown flare
sticky_flare( player )
{
	self endon( "death" );
	
	self make_entity_sentient_mp("allies"); 
	self.threatbias = CONST_FLARE_THREATBIAS;	
	self.owner = player;	
	self thread flare_out_of_playable_monitor();
	
	//play the fx while flying through the air
	self thread create_flare( level._effect["sticky_flare"]  , player );
	
	// Play flare sfx
	self thread sfx_flare_lp( player );
	
	self waittill ("missile_stuck", stuckto );
	
	if ( isDefined( stuckto ) &&  stuckto is_alien_agent()  ) //TODO - how to handle when this happens to a pet , or stuck to a friendly ?
	{
		stuckto enable_alien_scripted();
		stuckto.stuck_by_flare = true;
		stuckto SetOrigin( stuckto.origin );
		level thread wait_for_flare_finished( stuckto,self );
	}
	else//play sticky loop if on static surface, not a an alien agent
	{
		//self thread create_flare( level._effect["sticky_flare_loop"] , player );
		alien = undefined;
		level thread wait_for_flare_finished( alien ,self );
	}
}

//self is a flare
flare_out_of_playable_monitor()
{
	self endon( "death" );
	self endon ( "missile_stuck" );
	
	wait ( 7 );

	if ( isDefined( self ) )
	{
		self delete();
	}
}
//self is an alien
wait_for_flare_finished( alien, flare )
{
	damageowner = flare.owner;
	flare waittill( "deleting_flare" , org);
	
	config = level.placeableConfigs[ "fuse_resin_tnt" ]; //sticky flare config
	
	//do explosion
	playfx ( level._effect[ "sticky_explode" ] ,org );
	PlaySoundAtPos( org, "flare_explode_default" );
	RadiusDamage( org,config.item_damage_radius,config.item_damage,config.item_damage_falloff,damageowner,"MOD_EXPLOSIVE","iw6_aliendlc22_mp" );
	Earthquake( .35,.5,org,512 );
	
	if ( isDefined( alien )  )
	{
		alien disable_alien_scripted();
		alien.stuck_by_flare = false;		
	}
}

create_flare(  showEffect, owner )
{
	self endon ( "death" );
	
	// PlayFXOnTag fails if run on the same frame the parent entity was created
	wait ( 0.5 );
	
	angles = self getTagAngles( "tag_fire_fx" );
	PlayFXOnTag( showEffect, self, "tag_fire_fx" );	
	self playLoopSound( "emt_road_flare_burn" );
	self.flareType = true;
	
	if ( owner maps\mp\alien\_persistence::is_upgrade_enabled( "master_scavenger_upgrade" ) )
	{
		self thread flare_attract_aliens( CONST_UPGRADED_FLARE_TIME, owner );
		wait( CONST_UPGRADED_FLARE_TIME );
	}
	else 
	{
		self thread flare_attract_aliens( CONST_FLARE_TIME, owner );
		wait( CONST_FLARE_TIME );
	}
	self notify( "deleting_flare", self.origin );
	self delete();
}

sfx_flare_lp( player )
{	
	self endon( "death" );
	
	beep_interval = 0.163;

	if ( player maps\mp\alien\_persistence::is_upgrade_enabled( "master_scavenger_upgrade" ) )
		FlareEndTime = GetTime() + ( (CONST_UPGRADED_FLARE_TIME ) - 1.4) * 1000;
	else 
		FlareEndTime = GetTime() + ( (CONST_FLARE_TIME ) - 1.4) * 1000;
	
	wait 0.2;
	
	while ( GetTime() < FlareEndTime && IsDefined( self ) )
	{
		PlaySoundAtPos(self.origin, "flare_beep");
		wait beep_interval;
	}
	
	// Final Beeps
	PlaySoundAtPos(self.origin, "flare_beep_end");
}

FLARE_AFFECT_RADIUS = 512;
FLARE_MAX_NUM_ALIEN_AFFECTED = 6;

flare_attract_aliens( flare_time, owner )
{
	attractEndTime = GetTime() + flare_time * 1000;
	affectedAliens = [];
	
	while ( GetTime() < attractEndTime && IsDefined( self ) )
	{
		currentAffectedAliens = [];
		foreach( alien in affectedAliens )
		{
			if ( IsDefined( alien ) && IsAlive( alien ) )
				currentAffectedAliens[currentAffectedAliens.size] = alien;
		}
		
		affectedAliens = currentAffectedAliens;
		if ( IsDefined( owner ) )
			focal_point = owner.origin;
		else
			focal_point = self.origin;
		
		possibleFlareVictims = self get_possible_flare_victims( focal_point );
		
		for ( alienIndex = 0; alienIndex < possibleFlareVictims.size && affectedAliens.size < FLARE_MAX_NUM_ALIEN_AFFECTED; alienIndex++ )
		{
			alien = possibleFlareVictims[alienIndex];

			if ( !alien should_attract_alien() )
				continue;
			
			if ( IsDefined( alien.attractor_flare ) )
				continue;
			
			alien maps\mp\agents\alien\_alien_think::handle_attractor_flare( self, true );
			affectedAliens[affectedAliens.size] = alien;
		}	
		
		wait 0.2;
	}
	
	foreach ( alien in affectedAliens )
		alien maps\mp\agents\alien\_alien_think::handle_attractor_flare( self, false );
}

get_possible_flare_victims( focal_point )
{
	maxOwnerVictimsPriorityRangeSq = FLARE_AFFECT_RADIUS * FLARE_AFFECT_RADIUS * 0.5;
	
	aliens =  maps\mp\agents\_agent_utility::getActiveAgentsOfType( "alien" );
	victimsAroundOwner = get_array_of_closest( focal_point, aliens, undefined, undefined, FLARE_AFFECT_RADIUS );
	victimsAroundFlare = get_array_of_closest( self.origin, aliens, undefined, undefined, FLARE_AFFECT_RADIUS );
	possibleVictims = [];
	
	for ( ownerRangeIndex = 0; ownerRangeIndex < victimsAroundOwner.size; ownerRangeIndex++ )
	{
		victim = victimsAroundOwner[ownerRangeIndex];
		if ( array_contains( possibleVictims, victim ) )
			continue;
		
		distanceToOwner = DistanceSquared( focal_point, victim.origin );
		if ( distanceToOwner <= maxOwnerVictimsPriorityRangeSq )
			possibleVictims[possibleVictims.size] = victim;
		else
			break;
	}
	
	flareRangeIndex = 0;
	
	while ( ownerRangeIndex < victimsAroundOwner.size || flareRangeIndex < victimsAroundFlare.size )
	{
		ownerDistance = undefined;
		ownerVictim = undefined;
		while ( ownerRangeIndex < victimsAroundOwner.size )
		{
			ownerVictim = victimsAroundOwner[ownerRangeIndex];
			if ( !array_contains( possibleVictims, ownerVictim ) )
			{
				ownerDistance = DistanceSquared( focal_point, ownerVictim.origin );
				break;
			}

			ownerRangeIndex++;	
		}	
	
		while ( flareRangeIndex < victimsAroundFlare.size )
		{
			flareVictim = victimsAroundFlare[flareRangeIndex];
			if ( array_contains( possibleVictims, flareVictim ) )
			{
				flareRangeIndex++;
				continue;
			}
			
			flareDistance = DistanceSquared( self.origin, flareVictim.origin );
			if ( !IsDefined( ownerDistance ) || flareDistance < ownerDistance )
				possibleVictims[possibleVictims.size] = flareVictim;
			else
				break;
			
			flareRangeIndex++;
		}
		
		if ( IsDefined( ownerDistance ) )
		{
			possibleVictims[possibleVictims.size] = ownerVictim;
			ownerRangeIndex++;
		}
	}
	
	return possibleVictims;
}

should_attract_alien()
{
	if ( is_true ( self.stuck_by_flare  ) ) //don't attract this guy to himself ( ! )
		return false;
	
	switch ( self maps\mp\alien\_utility::get_alien_type() )
	{
		case "elite":
		case "mammoth":
		case "gargoyle":
			return false;
		default:
			return true;
	}
}

deleteOnDeath( ent )
{
	self waittill( "death" );
	
	if ( IsDefined( ent ) )
		ent delete();
}

// ========= EASTER EGG ACTIVATION =========

// via shooting the lodge sign spelling "lol" in under 3 seconds

CONST_EASTER_EGG_LODGE_SIGN_ACTIVE_TIME 		= 120; 	// seconds for easter egg to last
CONST_EASTER_EGG_LODGE_SIGN_TIMER 				= 5000;	// miliseconds to complete the activation
CONST_EASTER_EGG_LODGE_SIGN_ACTIVATOR_WEAPON	= "iw6_alienvks_mp_alienvksscope"; // weapon used to activate

easter_egg_lodge_sign()
{
	level endon( "game_ended" );
	
	level notify( "easter_egg_lodge_sign_reset" );
	level endon( "easter_egg_lodge_sign_reset" );
			    
	letter_l 		= getent( "easter_egg_letter_l", 		"targetname" );
	letter_o 		= getent( "easter_egg_letter_o", 		"targetname" );
	letter_reset 	= getent( "easter_egg_letter_reset", 	"targetname" );
	
	if ( !isdefined( letter_l ) || !isdefined( letter_o ) || !isdefined( letter_reset ) )
		return;
	
	letter_reset thread watch_for_letter_reset();
	
	while ( 1 )
	{
		letter_l waittill( "damage", damage, attacker, direction_vec, point, type );
		timer = gettime();
		if ( !is_letter_valid_hit( attacker, type ) )
			continue;
		//iprintlnBold( "^5L" );
		
		letter_o waittill( "damage", damage, attacker, direction_vec, point, type );
		if ( !is_letter_valid_hit( attacker, type ) )
			continue;
		//iprintlnBold( "^6O" );
		
		letter_l waittill( "damage", damage, attacker, direction_vec, point, type );
		if ( !is_letter_valid_hit( attacker, type ) || ( gettime() - timer ) > CONST_EASTER_EGG_LODGE_SIGN_TIMER )
			continue;
		//iprintlnBold( "^5L" );
		
		wait 1;
		
		iprintlnBold( "^5L^6O^5L" );
		
		level.easter_egg_lodge_sign_active = true;
		wait CONST_EASTER_EGG_LODGE_SIGN_ACTIVE_TIME; // time for easter egg to stay active
		level.easter_egg_lodge_sign_active = false;
	}
}

is_letter_valid_hit( attacker, type )
{
	// self is sign letter
	if ( !isdefined( attacker ) || !isPlayer( attacker ) )
		return false;
	
	attacker_weapon = attacker GetCurrentWeapon();
	if ( !isdefined( attacker_weapon ) || attacker_weapon != CONST_EASTER_EGG_LODGE_SIGN_ACTIVATOR_WEAPON )
		return false;
	
	type = ToLower( type );
	if ( !isdefined( type ) || type != "mod_rifle_bullet" )
		return false;
	
	return true;
}

watch_for_letter_reset()
{
	while ( 1 )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon );
		
		if ( !isdefined( attacker ) || !isPlayer( attacker ) )
			continue;
		
		if ( isdefined( level.easter_egg_lodge_sign_active ) && level.easter_egg_lodge_sign_active )
			continue;
		
		//iprintlnBold( "^5>_<" );
		wait 1;
		return easter_egg_lodge_sign();
	}
}
