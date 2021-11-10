#include maps\mp\_utility;
#include common_scripts\utility;

// DOOR STATS
DEFAULT_DOOR_MOVE_TIME_SEC	= 3.0;
DEFAULT_DOOR_PAUSE_TIME_SEC = 1.0;

// WHEEL "DOOR" STATS
DEFAULT_WHEEL_DIAMETER = 30.0;

// DOOR STATES
STATE_DOOR_CLOSED  = 0;
STATE_DOOR_CLOSING = 1;
STATE_DOOR_OPEN	   = 2;
STATE_DOOR_OPENING = 3;
STATE_DOOR_PAUSED  = 4;

// ENT SPAWNFLAGS
SPAWNFLAG_DYNAMIC_PATH	= 1;
SPAWNFLAG_AI_SIGHT_LINE = 2;


// DOOR SYSTEM DOCUMENTATION
// 
//	- door button trigger ent
//		- The button trigger targetname is passed to the door system in door_system_init( buttonName )
//			- Break this trigger into multiple pieces to support multiple doors.
//			- target all pieces of the door from this trigger by giving them the corresponding targetname
//				- set script_index to a time in MILLISECONDS on a button if you want to override the default move time for the corresponding doors
//			- add the script_parameters open_interrupt=true KVP to the button trigger to allow the doors to be interrupted while opening as well as while closing
//		- targeted script_origin
//			- assumed to be the sound entity. If no sound entity is given one of the doors is used as the sound origin
//		- targeted entity with classname that has substring "trigger"
//			- this is assumed to be the blocking trigger for the door setup. When this trigger goes off the door will stop / change state
//		- targeted script_models and script_brushmodels
//			- targeted entity with script_noteworthy substring "light"
//				- script_noteworthy "light_on" entities will be shown when the door is useable
//				- script_noteworthy "light_off" entities will be shown when the door is unuseable
//			- all other targetted script_model and script_brushmodel are assumed to be the door entities
//				- door entities assume their starting position to be their closed state for lighting reasons
//				- door entities should target a script_struct placed at the doors open position
//				- door entites with script_noteworthy "counterclockwise_wheel" or "clockwise_wheel" will rotate as well as translate
//
// DOOR SYSTEM FUTURE FEATURE FUN
//	- doors need to support entites being in the way
//		- things like killstreaks, equipment, etc. Potentially this is the trigger setup?
//	- have the button triggers target the button model(s)
//		- this script_model or script_brushmodel has animations on it which can be played according to state
//	- have door buttons have a default state according to gametypes
//		- this way a door ent can start open in DOM or start close in S&R
//		- game modes should also have a way to set the door state through a function call
//			- this function call could call a change state on the door and pop the doors into position
//	- have doors support movement through animation
//		- script would need to make animations pause mid movement and ease in and out of that pause state
//		- collision would have to be linked to the animations to keep players from running through the door
//	- support multiple wheel sizes

/*
=============
///ScriptDocBegin
"Name: door_system_init( <triggerName> )"
"Summary: Initialize function for the door finite state machine. Takes a trigger to be used to activate the door. This trigger can be broken into multiple pieces to support multiple buttons. See above documentation for door setup directions."
"Module: Utility"
"MandatoryArg: <triggerName>: The targetname of the door triggers in the level. To support multiple buttons for one door simply create a trigger made of multiple pieces, one piece for each button."
"Example: level thread door_system_init( "zebraDoorButton" )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

door_system_init( triggerName )
{
	buttons = GetEntArray( triggerName, "targetname" );
	
	foreach ( button in buttons )
	{
		if ( IsDefined( button.script_parameters ) )
		{
			button button_parse_parameters( button.script_parameters );
		}
		button door_setup();		
	}
	
	foreach ( button in buttons )
	{
		button thread door_think();
	}
}

door_setup()
{
	button = self;
	
	// Setup door references
	AssertEx( IsDefined( button.target ), "door_setup() found switch without at least one door target." );
	
	button.doors = [];
	
	if ( IsDefined( button.script_index ) )
	{
		button.doorMoveTime = max( 0.1, Float( button.script_index ) / 1000 );
	}
	
	targetEnts = GetEntArray( button.target, "targetname" );
	foreach ( ent in targetEnts )
	{
		if ( IsSubStr( ent.classname, "trigger" ) )
		{
			if ( !IsDefined( button.trigBlock ) )
			{
				button.trigBlock = [];
			}
			if ( IsDefined( ent.script_parameters ) )
			{
				ent trigger_parse_parameters( ent.script_parameters );
			}
			if ( IsDefined( ent.script_linkTo ) )
			{
				linked_door = GetEnt( ent.script_linkTo, "script_linkname" );
				ent EnableLinkTo();
				ent LinkTo( linked_door );
			}
						
			button.trigBlock[ button.trigBlock.size ] = ent;
		}
		else if ( ent.classname == "script_brushmodel" || ent.classname == "script_model" )
		{
			if ( IsDefined( ent.script_noteworthy ) && IsSubStr( ent.script_noteworthy, "light" ) )
			{
				if ( IsSubStr( ent.script_noteworthy, "light_on" ) )
				{
					if ( !IsDefined( button.lights_on ) )
					{
						button.lights_on = [];
					}
					
					ent Hide();
					button.lights_on[ button.lights_on.size ] = ent;
				}
				else if ( IsSubStr( ent.script_noteworthy, "light_off" ) )
				{
					if ( !IsDefined( button.lights_off ) )
					{
						button.lights_off = [];
					}
					
					ent Hide();
					button.lights_off[ button.lights_off.size ] = ent;
				}
				else
				{
					AssertMsg( "Invalid light ent with script_noteworthy of: " + ent.script_noteworthy );
				}
			}
			else if ( ent.spawnflags & SPAWNFLAG_AI_SIGHT_LINE )
			{
				if ( !IsDefined( button.ai_sight_brushes ) )
				{
					button.ai_sight_brushes = [];	
				}
				
				ent NotSolid();
				ent Hide();
				ent SetAISightLineVisible( false );
				button.ai_sight_brushes[ button.ai_sight_brushes.size ] = ent;
			}
			else
			{
				button.doors[ button.doors.size ] = ent;
			}
		}
		else if ( ent.classname == "script_origin" )
		{
			button.entSound = ent;
		}
	}
	
	if ( !IsDefined( button.entSound ) && button.doors.size )
	{
		button.entSound = SortByDistance( button.doors, button.origin )[ 0 ];
	}
	
	foreach ( door in button.doors )
	{
		AssertEx( IsDefined( door.target ), "door_setup() found door without a close position struct target." );
		door.posClosed = door.origin;
		door.posOpen   = getstruct( door.target, "targetname" ).origin;
		door.distMove  = Distance( door.posOpen, door.posClosed );
		door.origin = door.posOpen;
		door.no_moving_unresolved_collisions = false;
		
		if( IsDefined( door.script_parameters ) )
		{
			door door_parse_parameters( door.script_parameters );
		}
	}
}

door_think()
{
	button = self;
	
	button door_state_change( STATE_DOOR_OPEN, true );
	
	while ( 1 )
	{
		button.stateDone		= undefined;
		button.stateInterrupted = undefined;
		
		button waittill_any( "door_state_done", "door_state_interrupted" );
		
		// Prefer state done over state interrupted
		if ( IsDefined( button.stateDone ) && button.stateDone )
		{
			stateNext = button door_state_next( button.stateCurr );
			button door_state_change( stateNext, false );
		}
		else if ( IsDefined( button.stateInterrupted ) && button.stateInterrupted )
		{
			button door_state_change( STATE_DOOR_PAUSED, false );
		}
		else
		{
			AssertMsg( "state finished without being flagged as done or interrupted." );
		}
	}
}

door_state_next( state )
{
	button	  = self;
	stateNext = undefined;
	
	if ( state == STATE_DOOR_CLOSED )
	{
		stateNext = STATE_DOOR_OPENING;
	}
	else if ( state == STATE_DOOR_OPEN )
	{
		stateNext = STATE_DOOR_CLOSING;
	}
	else if ( state == STATE_DOOR_CLOSING )
	{
		stateNext = STATE_DOOR_CLOSED;
	}
	else if ( state == STATE_DOOR_OPENING )
	{
		stateNext = STATE_DOOR_OPEN;
	}
	else if ( state == STATE_DOOR_PAUSED )
	{
		AssertEx( IsDefined( button.statePrev ), "door_state_next() was passed STATE_DOOR_PAUSED without a previous state to go to." );
		stateNext = button.statePrev;
	}
	else
	{
		AssertMsg( "Unhandled state value of: " + state );
	}
	
	return stateNext;
}

door_state_update( noSound )
{
	button = self;
	
	button endon( "door_state_interrupted" );
	
	button.stateDone = undefined;
	
	if ( button.stateCurr == STATE_DOOR_CLOSED || button.stateCurr == STATE_DOOR_OPEN )
	{
		if ( !noSound )
		{
			foreach ( door in button.doors )
			{
				if( IsDefined( door.stop_sound ) )
				{
					door StopLoopSound();
					door PlaySoundOnMovingEnt( door.stop_sound );
				}
			}
		}

		if ( IsDefined( button.lights_on ) )
		{
			foreach ( light in button.lights_on )
			{
				light Show();
			}
		}
		
		foreach ( door in button.doors )
		{
			if ( button.stateCurr == STATE_DOOR_CLOSED )
			{
				if ( IsDefined( button.ai_sight_brushes ) )
				{
					foreach ( ai_sight_brush in button.ai_sight_brushes )
					{
						ai_sight_brush Show();
						ai_sight_brush SetAISightLineVisible( true );
					}
				}

				if ( door.spawnflags & SPAWNFLAG_DYNAMIC_PATH )
				{
					door DisconnectPaths();
				}
			}
			else // button.stateCurr == STATE_DOOR_OPEN
			{
				if ( IsDefined( button.ai_sight_brushes ) )
				{
					foreach ( ai_sight_brush in button.ai_sight_brushes )
					{
						ai_sight_brush Hide();
						ai_sight_brush SetAISightLineVisible( false );
					}
				}
				
				if ( door.spawnflags & SPAWNFLAG_DYNAMIC_PATH )
				{
					if( IsDefined( door.script_noteworthy ) && ( door.script_noteworthy == "always_disconnect" ) )
					{
						door DisconnectPaths();
					}
					else
					{
						door ConnectPaths();
					}
				}
			}

			if ( IsDefined( door.script_noteworthy ) )
			{
				if ( ( door.script_noteworthy == "clockwise_wheel" ) || ( door.script_noteworthy == "counterclockwise_wheel" ) )
				{
					door RotateVelocity( ( 0, 0, 0 ), 0.1 );
				}
			}
			
			if(door.no_moving_unresolved_collisions)
			{
				door.unresolved_collision_func = undefined;
			}
		}
		
		//"Press and hold [{+activate}] to open door"
		//"Press and hold [{+activate}] to close door"
		hintString = ter_op( button.stateCurr == STATE_DOOR_CLOSED, &"MP_DOOR_USE_OPEN", &"MP_DOOR_USE_CLOSE" );			
		button SetHintString( hintString );
		button MakeUsable();
		button waittill( "trigger" );
		if( IsDefined( button.button_sound ) )
		{
			button PlaySound( button.button_sound );
		}
	}
	else if ( button.stateCurr == STATE_DOOR_CLOSING || button.stateCurr == STATE_DOOR_OPENING )
	{
		if ( IsDefined( button.lights_off ) )
		{
			foreach ( light in button.lights_off )
			{
				light Show();
			}
		}
		
		button MakeUnusable();
		
		if ( button.stateCurr == STATE_DOOR_CLOSING )
		{
			button thread door_state_on_interrupt();
			
			foreach ( door in button.doors )
			{
				if ( IsDefined( door.script_noteworthy ) )
				{
					timeMove = ter_op( IsDefined( button.doorMoveTime ), button.doorMoveTime, DEFAULT_DOOR_MOVE_TIME_SEC );
					posGoal		  = ter_op( button.stateCurr == STATE_DOOR_CLOSING, door.posClosed, door.posOpen );
					distRemaining = Distance( door.origin, posGoal );
					time		  = max( 0.1, distRemaining / door.distMove * timeMove );
					timeEase	  = max( time * 0.25, 0.05 );
					
					angularDistance = 360 * distRemaining / ( 3.14 * DEFAULT_WHEEL_DIAMETER );
					
					if ( door.script_noteworthy == "clockwise_wheel" )
					{
						door RotateVelocity( ( 0, 0, -1 * angularDistance / time ), time, timeEase, timeEase );
					}
					else if ( door.script_noteworthy == "counterclockwise_wheel" )
					{
						door RotateVelocity( ( 0, 0, angularDistance / time ), time, timeEase, timeEase );
					}
				}
			}
		}
		else if ( button.stateCurr == STATE_DOOR_OPENING )
		{
			if ( IsDefined( button.open_interrupt ) && ( button.open_interrupt ) )
			{
				button thread door_state_on_interrupt();
			}
			
			foreach ( door in button.doors )
			{
				if ( IsDefined( door.script_noteworthy ) )
				{
					timeMove = ter_op( IsDefined( button.doorMoveTime ), button.doorMoveTime, DEFAULT_DOOR_MOVE_TIME_SEC );
					posGoal		  = ter_op( button.stateCurr == STATE_DOOR_CLOSING, door.posClosed, door.posOpen );
					distRemaining = Distance( door.origin, posGoal );
					time		  = max( 0.1, distRemaining / door.distMove * timeMove );
					timeEase	  = max( time * 0.25, 0.05 );
					
					angularDistance = 360 * distRemaining / ( 3.14 * DEFAULT_WHEEL_DIAMETER );
					
					if ( door.script_noteworthy == "clockwise_wheel" )
					{
						door RotateVelocity( ( 0, 0, angularDistance / time ), time, timeEase, timeEase );
					}
					else if ( door.script_noteworthy == "counterclockwise_wheel" )
					{
						door RotateVelocity( ( 0, 0, -1 * angularDistance / time ), time, timeEase, timeEase );
					}
				}
			}			
		}
		
		// Give the interrupt thread time to stop the door before a move starts
		wait 0.1;
		
		button childthread door_state_update_sound( "garage_door_start", "garage_door_loop" );
		
		timeMove = ter_op( IsDefined( button.doorMoveTime ), button.doorMoveTime, DEFAULT_DOOR_MOVE_TIME_SEC );
		timeMax	 = undefined;
		foreach ( door in button.doors )
		{
			posGoal = ter_op( button.stateCurr == STATE_DOOR_CLOSING, door.posClosed, door.posOpen );
			
			if ( door.origin != posGoal )
			{
				time	 = max( 0.1, Distance( door.origin, posGoal ) / door.distMove * timeMove );
				timeEase = max( time * 0.25, 0.05 );
				door MoveTo( posGoal, time,	timeEase, timeEase );
				door maps\mp\_movers::notify_moving_platform_invalid();
				
				if(door.no_moving_unresolved_collisions)
				{
					door.unresolved_collision_func = maps\mp\_movers::unresolved_collision_void;
				}
				
				if ( !IsDefined( timeMax ) || time > timeMax )
				{
					timeMax = time;
				}
			}
		}
		
		if ( IsDefined( timeMax ) )
		{
			wait timeMax;
		}
	}
	else if ( button.stateCurr == STATE_DOOR_PAUSED )
	{
		foreach ( door in button.doors )
		{
			door MoveTo( door.origin, 0.05, 0.0, 0.0 );
			door maps\mp\_movers::notify_moving_platform_invalid();
			
			if(door.no_moving_unresolved_collisions)
			{
				door.unresolved_collision_func = undefined;
			}
				
			if ( IsDefined( door.script_noteworthy ) )
			{
				if ( ( door.script_noteworthy == "clockwise_wheel" ) || ( door.script_noteworthy == "counterclockwise_wheel" ) )
				{
					door RotateVelocity( ( 0, 0, 0 ), 0.05 );
				}
			}
			
		}
		
		AssertEx( IsDefined( button.statePrev ) && ( button.statePrev == STATE_DOOR_CLOSING || button.statePrev == STATE_DOOR_OPENING ), "door_state_init() called with pause state without a valid previous state." );
		
		// Make sure the light's off state remains on during pause
		if ( IsDefined( button.lights_off ) )
		{
			foreach ( light in button.lights_off )
			{
				light Show();
			}
		}
		
		button.entSound StopLoopSound();
//		playSoundAtPos( button.entSound.origin, "garage_door_interupt" );
		foreach( door in button.doors )
		{
			if( IsDefined( door.interrupt_sound ) )
			{
				door PlaySound( door.interrupt_sound );
			}
		}
		
		wait DEFAULT_DOOR_PAUSE_TIME_SEC;
	}
	else
	{
		AssertMsg( "Unhandled state value of: " + button.stateCurr );
	}
	
	button.stateDone = true;
	foreach ( door in button.doors )
	{
		door.stateDone = true; // for sub-members like the hopper wheels in mp_frag
	}
	button notify( "door_state_done" );
}

door_state_update_sound( default_soundStart, default_soundLoop )
{
	button = self;
	
	use_default_start_sound = true;
	use_default_loop_sound = true;
	
	sound_length = 0;
	
	if( ( button.stateCurr == STATE_DOOR_OPENING ) || ( button.stateCurr == STATE_DOOR_CLOSING ) )
	{
		foreach( door in button.doors )
		{
			if( IsDefined( door.start_sound ) )
			{
				door PlaySoundOnMovingEnt( door.start_sound );
				sound_length = LookupSoundLength( door.start_sound ) / 1000;
				use_default_start_sound = false;
			}
		}
		
		if( use_default_start_sound )
		{
			sound_length = LookupSoundLength( default_soundStart ) / 1000;
			playSoundAtPos( button.entSound.origin, default_soundStart );
		}		
	}
	
	wait( sound_length * 0.3 ); // fraction of the sound so it blends better with the looping sound
	
	if( ( button.stateCurr == STATE_DOOR_OPENING ) || ( button.stateCurr == STATE_DOOR_CLOSING ) )
	{
		foreach( door in button.doors )
		{
			if( IsDefined( door.loop_sound ) )
			{
				if( door.loop_sound != "none" )
				{
					door PlayLoopSound( door.loop_sound );
				}
				use_default_loop_sound = false;
			}
		}
		
		if( use_default_loop_sound )
		{
			button.entSound PlayLoopSound( default_soundLoop );
		}
	}
}

door_state_change( state, noSound )
{
	button = self;
	if ( IsDefined( button.stateCurr ) )
	{
		door_state_exit( button.stateCurr );
		button.statePrev = button.stateCurr;
	}
	
	button.stateCurr = state;
	
	button thread door_state_update( noSound );
}

door_state_exit( state )
{
	button = self;
	
	if ( state == STATE_DOOR_CLOSED || state == STATE_DOOR_OPEN )
	{
		if ( IsDefined( button.lights_on ) )
		{
			foreach ( light in button.lights_on )
			{
				light Hide();
			}
		}
	}
	else if ( state == STATE_DOOR_CLOSING || state == STATE_DOOR_OPENING )
	{
		if ( IsDefined( button.lights_off ) )
		{
			foreach ( light in button.lights_off )
			{
				light Hide();
			}
		}

		button.entSound StopLoopSound();
		
		foreach( door in button.doors )
		{
			if( IsDefined( door.loop_sound ) )
			{
				door StopLoopSound();
			}
		}		
	}				
	else if ( state == STATE_DOOR_PAUSED )
	{
	}
	else
	{
		AssertMsg( "Unhandled state value of: " + state );
	}
}

door_state_on_interrupt()
{
	button = self;
	
	button endon( "door_state_done" );
	
	filtered_triggers = [];
	
	foreach ( trigger in button.trigBlock )
	{
		if ( button.stateCurr == STATE_DOOR_CLOSING )
		{
			if ( IsDefined( trigger.not_closing ) && ( trigger.not_closing == true ) )
			{
				continue;
			}
		}
		else if ( button.stateCurr == STATE_DOOR_OPENING )
		{
			if ( IsDefined( trigger.not_opening ) && ( trigger.not_opening == true ) )
			{
				continue;
			}
		}	
		
		filtered_triggers[ filtered_triggers.size ] = trigger;
	}
	
	if ( filtered_triggers.size > 0 )
	{
		interrupter = button waittill_any_triggered_return_triggerer( filtered_triggers );
		
		if ( !IsDefined( interrupter.fauxDead ) || ( interrupter.fauxDead == false ) )
		{
			button.stateInterrupted = true;
			button notify( "door_state_interrupted" );
		}
	}	
}

waittill_any_triggered_return_triggerer( triggers )
{
	button = self;
	foreach ( trigger in triggers )
	{
		button thread return_triggerer( trigger );
	}

	button waittill( "interrupted" );
	return button.interrupter;
}

return_triggerer( trigger )
{
	button = self;
	
	button endon( "door_state_done" );
	button endon( "interrupted" );
	
	while ( 1 )
	{
		trigger waittill( "trigger", ent );
	
		// This prone_only business is to account for the fact that the player's prone bounding box, which the trigger uses, actually only encompasses approximately his head to his waist. This can result in a prone player's
		// legs getting caught in the door (note: he should still be able to get out of the stuck spot by changing stance to crouch or stand). To alleviate that we add a second trigger (the prone_only trigger) which is much
		// wider (32 units on either side of the door), resulting int he doors staying open for the prone player. We also check the player's facing so that the doors don't stop for a prone player whose legs are NOT between the doors, to prevent sliver shooting.
		
		if ( IsDefined( trigger.prone_only ) && ( trigger.prone_only == true ) )
		{
			if ( IsPlayer( ent ) )
			{
				stance = ent GetStance();
				if ( stance != "prone" )
				{
					continue;
				}
				else
				{
					norm_facing_vec	 = VectorNormalize( AnglesToForward( ent.angles ) );
					norm_vec_to_trig = VectorNormalize( trigger.origin - ent.origin );
					dot				 = VectorDot( norm_facing_vec, norm_vec_to_trig );
					
					if ( dot > 0 )
					{
						continue;
					}
				}
			}
		}

		break;
	}
		
	button.interrupter = ent;
	button notify( "interrupted" );	
}

button_parse_parameters( parameters )
{
	button = self;
	button.button_sound = undefined;
	
	if ( !IsDefined( parameters ) )
		parameters = "";
	
	params = StrTok( parameters, ";" );
	foreach ( param in params )
	{
		toks = StrTok( param, "=" );
		if ( toks.size!= 2 )
			continue;
		
		if ( toks[ 1 ] == "undefined" || toks[ 1 ] == "default" )
		{
			button.params[ toks[ 0 ]] = undefined;
			continue;
		}
		
		switch( toks[ 0 ] )
		{
			case "open_interrupt":
				button.open_interrupt = string_to_bool( toks[ 1 ] );
				break;
			case "button_sound":
				button.button_sound = toks[1];
				break;
			default:
				break;
		}
	}	
}

door_parse_parameters( parameters )
{
	door = self;
	door.start_sound = undefined;
	door.stop_sound = undefined;
	door.loop_sound = undefined;
	door.interrupt_sound = undefined;	
	
	if ( !IsDefined( parameters ) )
		parameters = "";
	
	params = StrTok( parameters, ";" );
	foreach ( param in params )
	{
		toks = StrTok( param, "=" );
		if ( toks.size!= 2 )
			continue;
		
		if ( toks[ 1 ] == "undefined" || toks[ 1 ] == "default" )
		{
			door.params[ toks[ 0 ]] = undefined;
			continue;
		}
		
		switch( toks[ 0 ] )
		{
			case "stop_sound":
				door.stop_sound = toks[1];
				break;
			case "interrupt_sound":
				door.interrupt_sound = toks[1];
				break;
			case "loop_sound":
				door.loop_sound = toks[1];
				break;
			case "open_interrupt":
				door.open_interrupt = string_to_bool( toks[ 1 ] );
				break;
			case "start_sound":
				door.start_sound = toks[1];
				break;
			case "unresolved_collision_nodes":
				door.unresolved_collision_nodes = GetNodeArray(toks[ 1 ], "targetname");
				break;
			case "no_moving_unresolved_collisions":
				door.no_moving_unresolved_collisions = string_to_bool(toks[1]);
				break;	
			default:
				break;
		}
	}	
}

trigger_parse_parameters( parameters )
{
	trigger = self;
	
	if ( !IsDefined( parameters ) )
		parameters = "";
	
	params = StrTok( parameters, ";" );
	foreach ( param in params )
	{
		toks = StrTok( param, "=" );
		if ( toks.size!= 2 )
			continue;
		
		if ( toks[ 1 ] == "undefined" || toks[ 1 ] == "default" )
		{
			trigger.params[ toks[ 0 ]] = undefined;
			continue;
		}
		
		switch( toks[ 0 ] )
		{
			case "not_opening":
				trigger.not_opening = string_to_bool( toks[ 1 ] );
				break;
			case "not_closing":
				trigger.not_closing = string_to_bool( toks[ 1 ] );
				break;
			case "prone_only":
				trigger.prone_only = string_to_bool( toks[ 1 ] );
				break;				
			default:
				break;
		}
	}
}

string_to_bool( the_string )
{
	retVal = undefined;
	switch( the_string )
	{
		case "1":
		case "true":
			retVal = true;
			break;
		case "0":
		case "false":
			retVal = false;
			break;
		default:
			AssertMsg( "Invalid string to bool convert attempted." );
			break;
	}
	
	return retVal;
}