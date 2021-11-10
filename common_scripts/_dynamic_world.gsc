#include common_scripts\utility;

/*QUAKED trigger_multiple_dyn_metal_detector (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Comments to be added.*/

/*QUAKED trigger_multiple_dyn_creaky_board (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Comments to be added.*/

/*QUAKED trigger_multiple_dyn_photo_copier (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Comments to be added.*/

/*QUAKED trigger_multiple_dyn_copier_no_light (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Comments to be added.*/

/*QUAKED trigger_radius_dyn_motion_light (0.12 0.23 1.0) (-16 -16 -16) (16 16 16)
Comments to be added.*/

/*QUAKED trigger_radius_dyn_motion_dlight (0.12 0.23 1.0) (-16 -16 -16) (16 16 16)
Comments to be added.*/

/*QUAKED trigger_multiple_dog_bark (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
Comments to be added.*/

/*QUAKED trigger_radius_bird_startle (0.12 0.23 1.0) (-16 -16 -16) (16 16 16)
Comments to be added.*/

/*QUAKED trigger_multiple_dyn_motion_light (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Comments to be added.*/

/*QUAKED trigger_multiple_dyn_door (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Comments to be added.*/

/*QUAKED trigger_multiple_freefall (0.12 0.23 1.0) ? AI_AXIS AI_ALLIES AI_NEUTRAL NOTPLAYER VEHICLE TRIGGER_SPAWN TOUCH_ONCE
defaulttexture="flag"
Player free falling with animation and screaming of doom.*/

// Crouch Speed 5.7-6.0
// Run Speed 8.7-9.2
// Sprint Speed 13.0-14.0


// ========================= Constants ==========================

// Vending Machine
CONST_vending_machine_health = 400;
CONST_soda_pop_time			 = 0.2;	 //seconds
CONST_soda_count			 = 12;	 //number of soda per machine
CONST_soda_launch_force		 = 1000; //soda shoot out force
CONST_soda_random_factor	 = 0.3;	 //in percentage 0.2 = 20%
CONST_soda_splash_dmg_scaler = 3;	 //splash damage multiplier

// Metal Detector
CONST_alarm_tolerance	= 0; //number of alarm sounds before silenced, 0 disables silencing
CONST_alarm_interval	= 7; //alarm interval time in seconds
CONST_alarm_interval_sp = 2; //alarm interval time in seconds for single player

// Civilian Jet
CONST_jet_speed	 = 2000;  //jet while landing is 130 - 160mph( 2292inch / sec - 2820inch / sec ), emergency landing is 110mph
CONST_jet_extend = 20000; //units, each jet and flyto origin will extend from each other by

init()
{

	//rotate fan blades in mp_highrise
	array_thread( GetEntArray( "com_wall_fan_blade_rotate_slow", "targetname" ), ::fan_blade_rotate, "veryslow" );
	array_thread( GetEntArray( "com_wall_fan_blade_rotate", "targetname" ), ::fan_blade_rotate, "slow" );
	array_thread( GetEntArray( "com_wall_fan_blade_rotate_fast", "targetname" ), ::fan_blade_rotate, "fast" );

	trigger_classes											  = [];
	trigger_classes[ "trigger_multiple_dyn_metal_detector"	] = ::metal_detector;
	trigger_classes[ "trigger_multiple_dyn_creaky_board"	] = ::creaky_board;
	trigger_classes[ "trigger_multiple_dyn_photo_copier"	] = ::photo_copier;
	trigger_classes[ "trigger_multiple_dyn_copier_no_light" ] = ::photo_copier_no_light;
	trigger_classes[ "trigger_radius_motion_light"			] = ::motion_light;
	trigger_classes[ "trigger_radius_dyn_motion_dlight"		] = ::outdoor_motion_dlight;
	trigger_classes[ "trigger_multiple_dog_bark"			] = ::dog_bark;
	trigger_classes[ "trigger_radius_bird_startle"			] = ::bird_startle;
	trigger_classes[ "trigger_multiple_dyn_motion_light"	] = ::motion_light;
	trigger_classes[ "trigger_multiple_dyn_door"			] = ::trigger_door;
  //trigger_classes[ "trigger_multiple_freefall" ]			= ::freefall;

	player_init();

	foreach ( classname, function in trigger_classes )
	{
		triggers = GetEntArray( classname, "classname" );
				  //   entities    process 			   
		array_thread( triggers	, ::triggerTouchThink );
		array_thread( triggers	, function );
	}

	array_thread( GetEntArray( "vending_machine", "targetname" ), ::vending_machine );
	array_thread( GetEntArray( "toggle", "targetname" ), ::use_toggle );

	level thread onPlayerConnect();

	civilian_jet = GetEnt( "civilian_jet_origin", "targetname" );
	if ( IsDefined( civilian_jet ) )
		civilian_jet thread civilian_jet_flyby();
			
	thread interactive_tv();
}

onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connecting", player );
		player thread movementTracker();
	}
}

player_init()
{
	if ( isSP() )
	{
		foreach ( player in level.players )
		{
			player.touchTriggers = [];
			player thread movementTracker();
		}
	}
}

ai_init()
{
	/*if ( !isdefined( level.registeredAI ) )
		level.registeredAI = [];
		
	level.registeredAI[ level.registeredAI.size ] = self;
	*/

	// self is AI
	self.touchTriggers = [];
	self thread movementTracker();
}

// ================================================================================ //
// 									Civilian Jet 									//
// ================================================================================ //

civilian_jet_flyby()
{
	level endon( "game_ended" );

	self jet_init();

	level waittill( "prematch_over" );

	while ( 1 )
	{
		self thread jet_timer();
		self waittill( "start_flyby" );

		self thread jet_flyby();
		self waittill( "flyby_done" );

		self jet_reset();
	}
}

jet_init()
{
	// move jet plane and flyto origin out of the map and hide on level load
	self.jet_parts	= GetEntArray( self.target, "targetname" );
	self.jet_flyto	= GetEnt( "civilian_jet_flyto", "targetname" );
	self.engine_fxs = GetEntArray( "engine_fx", "targetname" );
	self.flash_fxs	= GetEntArray( "flash_fx", "targetname" );

	self.jet_engine_fx		= LoadFX( "fx/fire/jet_afterburner" );
	self.jet_flash_fx_red	= LoadFX( "fx/misc/aircraft_light_wingtip_red" );
	self.jet_flash_fx_green = LoadFX( "fx/misc/aircraft_light_wingtip_green" );
	self.jet_flash_fx_blink = LoadFX( "fx/misc/aircraft_light_red_blink" );

	level.civilianJetFlyBy	= undefined;		// priority with air supremacies

	AssertEx( IsDefined( self.jet_parts ), 		"Missing cilivian jet model" );
	AssertEx( IsDefined( self.jet_flyto ), 		"Missing cilivian jet flyto script_origin: civilian_jet_flyto" );
	AssertEx( IsDefined( self.engine_fxs ), 	"Missing cilivian jet engine fxs script_origins: engine_fx" );
	AssertEx( IsDefined( self.flash_fxs ), 		"Missing cilivian jet signal light script_origins: flash_fxs" );

	// extending vector to place jet and flyto origin outside sky box
	negative_vec = ( VectorNormalize( self.origin - self.jet_flyto.origin ) * CONST_jet_extend );

	// extend flyto origin
	self.jet_flyto.origin -= negative_vec;

	// extend jet
	self.origin += negative_vec;
	foreach ( part in self.jet_parts )
	{
		part.origin += negative_vec;
		part.old_origin = part.origin;
		part Hide();
	}

	// extend jet's engine fx origins
	foreach ( engine_fx in self.engine_fxs )
		engine_fx.origin += negative_vec;

	foreach ( flash_fx in self.flash_fxs )
		flash_fx.origin += negative_vec;

	// -------------- flight time and vector calculation -------------
	jet_origin		 = self.origin; // origin is the nose of the jet
	jet_flyto_pos	 = self.jet_flyto.origin;
	self.jet_fly_vec = jet_flyto_pos - jet_origin;

	jet_speed			 = CONST_jet_speed;
	jet_flight_dist		 = abs( Distance( jet_origin, jet_flyto_pos ) );
	self.jet_flight_time = jet_flight_dist / jet_speed;
}

jet_reset()
{
	foreach ( part in self.jet_parts )
	{
		part.origin = part.old_origin;
		part Hide();
	}
}

jet_timer()
{
	level endon( "game_ended" );

	match_timelimit	= getTimeInterval();
	Assert( IsDefined( match_timelimit ) );
	timelimit = max( 10		  , match_timelimit );
	timelimit = min( timelimit, 100 );

	if ( GetDvar( "jet_flyby_timer" ) != "" )
		level.civilianJetFlyBy_timer = 5 + GetDvarInt( "jet_flyby_timer" );
	else
		level.civilianJetFlyBy_timer = ( 0.25 + RandomFloatRange( 0.3, 0.7 ) ) * 60 * timeLimit;	// seconds into the match when jet flys by

	wait level.civilianJetFlyBy_timer;

	// wait till all the airborne kill streaks are done
	while ( IsDefined( level.airstrikeInProgress ) || IsDefined( level.ac130player ) || IsDefined( level.chopper ) || IsDefined( level.remoteMissileInProgress ) )
		wait 0.05;

	// start flyby
	self notify( "start_flyby" );

	// blocks out all airborne kill streaks
	level.civilianJetFlyBy = true;
	self waittill( "flyby_done" );
	level.civilianJetFlyBy = undefined;
}

getTimeInterval()
{
	if ( isSP() )
		return 10.0;

	if ( IsDefined( game[ "status" ] ) && game[ "status" ] == "overtime" )
		return 1.0;
	else
		return getWatchedDvar( "timelimit" );
}

getWatchedDvar( dvarString )
{
	dvarString = "scr_" + level.gameType + "_" + dvarString;
	
	if ( IsDefined( level.overrideWatchDvars ) && IsDefined( level.overrideWatchDvars[ dvarString ] ) )
	{
		return level.overrideWatchDvars[ dvarString ];
	}	
	
	return( level.watchDvars[ dvarString ].value );
}

jet_flyby()
{
	// show plane
	foreach ( part in self.jet_parts )
		part Show();

	engine_fx_array = [];
	flash_fx_array	= [];

	foreach ( engine_fx in self.engine_fxs )
	{
		engine_fx_ent = Spawn( "script_model", engine_fx.origin );
		engine_fx_ent SetModel( "tag_origin" );
		engine_fx_ent.angles					= engine_fx.angles;
		engine_fx_array[ engine_fx_array.size ] = engine_fx_ent;
	}

	foreach ( flash_fx in self.flash_fxs )
	{
		flash_fx_ent = Spawn( "script_model", flash_fx.origin );
		flash_fx_ent SetModel( "tag_origin" );
		flash_fx_ent.color					  = flash_fx.script_noteworthy;
		flash_fx_ent.angles					  = flash_fx.angles;
		flash_fx_array[ flash_fx_array.size ] = flash_fx_ent;
	}

	AssertEx( IsDefined( level.mapcenter ), "Calling for civilian jet flyby when level.mapcenter is not yet defined." );
	self thread jet_planeSound( self.jet_parts[ 0 ], level.mapcenter );

	wait 0.05;

	// play engine fx on fx ents
	foreach ( engine_fx_ent in engine_fx_array )
		PlayFXOnTag( self.jet_engine_fx, engine_fx_ent, "tag_origin" );

	// play flash fx on fx ents
	foreach ( flash_fx_ent in flash_fx_array )
	{
		if ( IsDefined( flash_fx_ent.color ) && flash_fx_ent.color == "blink" )
			PlayFXOnTag( self.jet_flash_fx_blink, flash_fx_ent, "tag_origin" );
		else if ( IsDefined( flash_fx_ent.color ) && flash_fx_ent.color == "red" )
			PlayFXOnTag( self.jet_flash_fx_red, flash_fx_ent, "tag_origin" );
		else
			PlayFXOnTag( self.jet_flash_fx_green, flash_fx_ent, "tag_origin" );
	}

	// move plane
	foreach ( part in self.jet_parts )
		part MoveTo( part.origin + self.jet_fly_vec, self.jet_flight_time );

	// move fx ents
	foreach ( engine_fx_ent in engine_fx_array )
		engine_fx_ent MoveTo( engine_fx_ent.origin + self.jet_fly_vec, self.jet_flight_time );
	foreach ( flash_fx_ent in flash_fx_array )
		flash_fx_ent MoveTo( flash_fx_ent.origin + self.jet_fly_vec, self.jet_flight_time );

	wait( self.jet_flight_time + 1 );

	// delete fxs
	foreach ( engine_fx_ent in engine_fx_array )
		engine_fx_ent Delete();
	foreach ( flash_fx_ent in flash_fx_array )
		flash_fx_ent Delete();

	self notify( "flyby_done" );
}

jet_planeSound( plane, bombsite )
{
	plane thread playsound_loop_on_ent( "veh_mig29_dist_loop" );
	while ( !targetisclose( plane, bombsite ) )
		wait 0.05;

	plane thread playsound_loop_on_ent( "veh_mig29_close_loop" );
	while ( targetisinfront( plane, bombsite ) )
		wait 0.05;
	wait 0.5;

	plane thread playsound_float( "veh_mig29_sonic_boom" );
	while ( targetisclose( plane, bombsite ) )
		wait 0.05;

	plane notify( "stop sound" + "veh_mig29_close_loop" );
	self waittill( "flyby_done" );

	plane notify( "stop sound" + "veh_mig29_dist_loop" );
}

playsound_float( alias, origin, master )
{
	org = Spawn( "script_origin", ( 0, 0, 1 ) );
	org Hide();
	if ( !IsDefined( origin ) )
		origin = self.origin;
	org.origin = origin;
	if ( IsDefined( master ) && master )
		org PlaySoundAsMaster( alias );
	else
		org PlaySound( alias );
	wait( 10.0 );
	org Delete();
}

playsound_loop_on_ent( alias, offset )
{
	org = Spawn( "script_origin", ( 0, 0, 0 ) );
	org Hide();
	org endon( "death" );
	thread delete_on_death( org );
	if ( IsDefined( offset ) )
	{
		org.origin = self.origin + offset;
		org.angles = self.angles;
		org LinkTo( self );
	}
	else
	{
		org.origin = self.origin;
		org.angles = self.angles;
		org LinkTo( self );
	}
//	org endon ("death");
	org PlayLoopSound( alias );
//	println ("playing loop sound ", alias," on entity at origin ", self.origin, " at ORIGIN ", org.origin);
	self waittill( "stop sound" + alias );
	org StopLoopSound( alias );
	org Delete();
}

targetisinfront( other, target )
{
	forwardvec = AnglesToForward( flat_angle( other.angles ) );
	normalvec  = VectorNormalize( flat_origin( target ) - other.origin );
	dot		   = VectorDot( forwardvec, normalvec );

	if ( dot > 0 )
		return true;
	else
		return false;
}

targetisclose( other, target )
{
	infront = targetisinfront( other, target );

	if ( infront )
		dir = 1;
	else
		dir = -1;

	a	  = flat_origin( other.origin );
	b	  = a + ( AnglesToForward( flat_angle( other.angles ) ) * ( dir * 100000 ) );
	point = PointOnSegmentNearestToPoint( a, b, target );
	dist  = Distance( a, point );

	if ( dist < 3000 )
		return true;
	else
		return false;
}

// ================================================================================ //
// 									Vending Machine									//
// ================================================================================ //

vending_machine()
{
	level endon( "game_ended" );
	self endon( "death" );

	// self is use trigger
	self SetCursorHint( "HINT_ACTIVATE" );

	self.vm_normal		= GetEnt( self.target, "targetname" );
	AssertEx( IsDefined( self.vm_normal ), "Vending machine use trigger is missing target to the normal vending machine script_model" );
	vm_soda_start		= GetEnt( self.vm_normal.target, "targetname" );
	AssertEx( IsDefined( vm_soda_start ), "Vending machine normal script_model is missing target to the start-soda can script_model" );
	vm_soda_stop		= GetEnt( vm_soda_start.target, "targetname" );
	AssertEx( IsDefined( vm_soda_start ), "Start-soda can script_model is missing target to the end-soda can script_model" );
	vm_launch_from = GetEnt( vm_soda_stop.target, "targetname" );
	AssertEx( IsDefined( vm_launch_from ), "End-soda can script_model is missing target to the physics launch-from script_origin" );
	self.vm_launch_from = vm_launch_from.origin;
	vm_launch_to		= GetEnt( vm_launch_from.target, "targetname" );
	AssertEx( IsDefined( vm_launch_to ), "launch-from can script_origin is missing target to the physics launch-to script_origin" );
	self.vm_launch_to	= vm_launch_to.origin;

	if ( IsDefined( vm_launch_to.target ) )
		self.vm_fx_loc	= GetEnt( vm_launch_to.target, "targetname" ).origin;
		
	//assertex( isdefined( self.vm_launch_to ), "launch-to can script_origin is missing target to the fx location script_origin" );

	self.vm_normal SetCanDamage( true );

	self.vm_normal_model  = self.vm_normal.model;
	self.vm_damaged_model = self.vm_normal.script_noteworthy;
	self.vm_soda_model	  = vm_soda_start.model;

	self.vm_soda_start_pos	 = vm_soda_start.origin;
	self.vm_soda_start_angle = vm_soda_start.angles;
	self.vm_soda_stop_pos	 = vm_soda_stop.origin;
	self.vm_soda_stop_angle	 = vm_soda_stop.angles;

	// precache damage model
	PreCacheModel( self.vm_damaged_model );

	// ride the no longer needed models
	vm_soda_start Delete();
	vm_soda_stop Delete();
	vm_launch_from Delete();
	vm_launch_to Delete();

	self.soda_array = [];
	self.soda_count = CONST_soda_count;
	self.soda_slot	= undefined; // the soda can thats resting in the slot
	self.hp			= CONST_vending_machine_health;

	self thread vending_machine_damage_monitor( self.vm_normal );
	self PlayLoopSound( "vending_machine_hum" );

	while ( 1 )
	{
		self waittill( "trigger", player );
		//level.players[0] iprintln( "used" );

		self PlaySound( "vending_machine_button_press" );
		if ( !self.soda_count )
			continue;

		// drop a can, and shoot out the previous one if in slot
		if ( IsDefined( self.soda_slot ) )
			self soda_can_eject();
		soda_can_drop( spawn_soda() );
		wait 0.05;
	}
}

vending_machine_damage_monitor( vending_machine )
{
	level endon( "game_ended" );

	exp_dmg	  = "mod_grenade mod_projectile mod_explosive mod_grenade_splash mod_projectile_splash splash";
	sparks_fx = LoadFX( "fx/explosions/tv_explosion" );

	while ( 1 )
	{
		damage		  = undefined;
		other		  = undefined;
		direction_vec = undefined;
		P			  = undefined;
		type		  = undefined;
		vending_machine waittill( "damage", damage, other, direction_vec, P, type );

		if ( IsDefined( type ) )
		{
			if ( IsSubStr( exp_dmg, ToLower( type ) ) )
				damage *= CONST_soda_splash_dmg_scaler;	// multiply explosive dmg

			self.hp -= damage;
			if ( self.hp > 0 )
				continue;
			
			// vending machine is now dead, button usage is disabled
			self notify( "death" );
			
			// disable use trigger
			self.origin += ( 0, 0, 10000 );

			if ( !IsDefined( self.vm_fx_loc ) )
				playfx_loc = self.vm_normal.origin + ( ( 17, -13, 52 ) - ( -20, 18, 0 ) );
			else
				playfx_loc = self.vm_fx_loc;
				
			PlayFX( sparks_fx, playfx_loc );

			// when vending machine is explosively damaged, shoots out soda cans
			self.vm_normal SetModel( self.vm_damaged_model );

			while ( self.soda_count > 0 )
			{
				// drop a can, and shoot out the previous one if in slot
				if ( IsDefined( self.soda_slot ) )
					self soda_can_eject();
				soda_can_drop( spawn_soda() );
				wait 0.05;
			}

			self StopLoopSound( "vending_machine_hum" );
			return;
		}
	}
}

spawn_soda()
{
	soda = Spawn( "script_model", self.vm_soda_start_pos );
	soda SetModel( self.vm_soda_model );
	soda.origin = self.vm_soda_start_pos;
	soda.angles = self.vm_soda_start_angle;
	return soda;
}

soda_can_drop( soda )
{
	soda MoveTo( self.vm_soda_stop_pos, CONST_soda_pop_time );
	soda PlaySound( "vending_machine_soda_drop" );	// soda can drop sound
	wait CONST_soda_pop_time;

	self.soda_slot = soda;
	self.soda_count--;
}

soda_can_eject()
{
	self endon( "death" );

	if ( IsDefined( self.soda_slot.ejected ) && self.soda_slot.ejected == true )
		return;
	
	// physics launch
	force_max = 1;
	force_min = force_max * ( 1 - CONST_soda_launch_force );
	
	random_offset		 = Int( 40 * CONST_soda_launch_force );
	random_launch_offset = ( Int( random_offset / 2 ), Int( random_offset / 2 ), 0 ) - ( RandomInt( random_offset ), RandomInt( random_offset ), 0 );
	
	launch_vec		 = VectorNormalize( self.vm_launch_to - self.vm_launch_from + random_launch_offset );
	launch_force_vec = ( launch_vec * RandomFloatRange( force_min, force_max ) );
	
	self.soda_slot PhysicsLaunchClient( self.vm_launch_from, launch_force_vec );
	self.soda_slot.ejected = true;
}

// ================================================================================ //
// 									Free Fall										//
// ================================================================================ //

freefall()
{
	level endon( "game_ended" );

	freefall_weapon = "briefcase_bomb_mp";
	PreCacheItem( freefall_weapon );

	while ( 1 )
	{
		self waittill( "trigger_enter", player );

		if ( !( player HasWeapon( freefall_weapon ) ) )
		{
			player PlaySound( "freefall_death" );

			player GiveWeapon( freefall_weapon );
			player SetWeaponAmmoStock( freefall_weapon, 0 );
			player SetWeaponAmmoClip( freefall_weapon, 0 );
			player SwitchToWeapon( freefall_weapon );
		}
	}
}

// ================================================================================ //
// 									Metal Detector 									//
// ================================================================================ //

metal_detector()
{
	// self is trigger: trigger_multiple_dyn_metal_detector

	level endon( "game_ended" );
	AssertEx( IsDefined( self.target ), "trigger_multiple_dyn_metal_detector is missing target damage trigger used for detecting entities other than players" );

	damage_trig = GetEnt( self.target, "targetname" );
	damage_trig EnableGrenadeTouchDamage();

	bound_org_1 = GetEnt( damage_trig.target, "targetname" );
	bound_org_2 = GetEnt( bound_org_1.target, "targetname" );

	AssertEx( IsDefined( bound_org_1 ) && IsDefined( bound_org_2 ), "Metal detector missing bound origins for claymore test" );

	detector_1 = GetEnt( bound_org_2.target, "targetname" );
	detector_2 = GetEnt( detector_1.target, "targetname" );

	AssertEx( IsDefined( detector_1 ) && IsDefined( detector_2 ), "Recompile the bsp to fix this, metal detector prefab changed." );

	bounds		= [];
	bound_x_min = min( bound_org_1.origin[ 0 ], bound_org_2.origin[ 0 ] );	bounds[ 0 ] = bound_x_min;
	bound_x_max = max( bound_org_1.origin[ 0 ], bound_org_2.origin[ 0 ] );	bounds[ 1 ] = bound_x_max;
	bound_y_min = min( bound_org_1.origin[ 1 ], bound_org_2.origin[ 1 ] );	bounds[ 2 ] = bound_y_min;
	bound_y_max = max( bound_org_1.origin[ 1 ], bound_org_2.origin[ 1 ] );	bounds[ 3 ] = bound_y_max;
	bound_z_min = min( bound_org_1.origin[ 2 ], bound_org_2.origin[ 2 ] );	bounds[ 4 ] = bound_z_min;
	bound_z_max = max( bound_org_1.origin[ 2 ], bound_org_2.origin[ 2 ] );	bounds[ 5 ] = bound_z_max;

	bound_org_1 Delete();
	bound_org_2 Delete();

	if ( !isSP() )
		self.alarm_interval = CONST_alarm_interval;
	else
		self.alarm_interval = CONST_alarm_interval_sp;

	self.alarm_playing	 = 0;
	self.alarm_annoyance = 0;
	self.tolerance		 = CONST_alarm_tolerance;

	self thread metal_detector_dmg_monitor( damage_trig );
	self thread metal_detector_touch_monitor();
	self thread metal_detector_weapons( bounds, "weapon_claymore", "weapon_c4" );

	light_pos1 = ( detector_1.origin[ 0 ], detector_1.origin[ 1 ], bound_z_max );
	light_pos2 = ( detector_2.origin[ 0 ], detector_2.origin[ 1 ], bound_z_max );

  //light_pos1 = ( bound_x_min,	 bound_y_min, bound_z_max );
  //light_pos2 = ( bound_x_max,	 bound_y_max, bound_z_max );
	md_light	 = LoadFX( "fx/props/metal_detector_light" );

	while ( 1 )
	{
		self waittill_any( "dmg_triggered", "touch_triggered", "weapon_triggered" );
		self thread playsound_and_light( "alarm_metal_detector", md_light, light_pos1, light_pos2 );
	}
}

playsound_and_light( sound, light, light_pos1, light_pos2 )
{
	level endon( "game_ended" );

	if ( !self.alarm_playing )
	{
		self.alarm_playing = 1;
		self thread annoyance_tracker();

		if ( !self.alarm_annoyance )
			self PlaySound( sound );

		// 1000ms red light fx
		PlayFX( light, light_pos1 );
		PlayFX( light, light_pos2 );

		wait self.alarm_interval;
		self.alarm_playing = 0;
	}
}

annoyance_tracker()
{
	level endon( "game_ended" );

	if ( !self.tolerance )
		return;

	interval = self.alarm_interval + 0.15;
	if ( self.tolerance )
		self.tolerance--;
	else
		self.alarm_annoyance = 1;

	current_time = GetTime(); // ms

	alarm_timeout = CONST_alarm_interval;
	if ( isSP() )
		alarm_timeout = CONST_alarm_interval_sp;

	self waittill_any_or_timeout( "dmg_triggered", "touch_triggered", "weapon_triggered", ( alarm_timeout + 2 ) );

	time_delta = ( GetTime() - current_time );
	if ( time_delta > ( ( alarm_timeout * 1000 ) + 1150 ) )
	{
		self.alarm_annoyance = 0;
		self.tolerance		 = CONST_alarm_tolerance;
	}
}

waittill_any_or_timeout( msg1, msg2, msg3, timer )
{
	level endon( "game_ended" );

	self endon( msg1 );
	self endon( msg2 );
	self endon( msg3 );
	wait timer;
}

metal_detector_weapons( bounds, weapon_1, weapon_2 )
{
	level endon( "game_ended" );
	while ( 1 )
	{
		self waittill_weapon_placed();

		all_grenades = GetEntArray( "grenade", "classname" );
		foreach ( grenade in all_grenades )
		{
			if ( IsDefined( grenade.model ) && ( grenade.model == weapon_1 || grenade.model == weapon_2 ) )
			{
				if ( isInBound( grenade, bounds ) )
					self thread weapon_notify_loop( grenade, bounds );
			}
		}
	}
}

waittill_weapon_placed()
{
	level endon( "game_ended" );
	self endon( "dmg_triggered" );
	self waittill( "touch_triggered" );
}

weapon_notify_loop( grenade, bounds )
{
	grenade endon( "death" );

	while ( isInBound( grenade, bounds ) )
	{
		self notify( "weapon_triggered" );
		wait self.alarm_interval;
	}
}

isInBound( ent, bounds )
{
	bound_x_min = bounds[ 0 ]; bound_x_max = bounds[ 1 ];
	bound_y_min = bounds[ 2 ]; bound_y_max = bounds[ 3 ];
	bound_z_min = bounds[ 4 ]; bound_z_max = bounds[ 5 ];

	ent_x = ent.origin[ 0 ];
	ent_y = ent.origin[ 1 ];
	ent_z = ent.origin[ 2 ];

	if ( isInBound_single( ent_x, bound_x_min, bound_x_max ) )
	{
		if ( isInBound_single( ent_y, bound_y_min, bound_y_max ) )
		{
			if ( isInBound_single( ent_z, bound_z_min, bound_z_max ) )
				return true;
		}
	}
	return false;
}

isInBound_single( var, v_min, v_max )
{
	if ( var > v_min && var < v_max )
		return true;
	return false;
}

metal_detector_dmg_monitor( damage_trig )
{
	level endon( "game_ended" );
	while ( 1 )
	{
		damage_trig waittill( "damage", damage, other, direction_vec, P, type );
		if ( IsDefined( type ) && alarm_validate_damage( type ) )
			self notify( "dmg_triggered" );
	}
}

metal_detector_touch_monitor()
{
	level endon( "game_ended" );
	while ( 1 )
	{
		self waittill( "trigger_enter" );
		while ( anythingTouchingTrigger( self ) )
		{
			self notify( "touch_triggered" );
			wait self.alarm_interval;
		}
	}
}

alarm_validate_damage( damageType )
{
  //disallowed_dmg		 = "mod_pistol_bullet mod_rifle_bullet bullet mod_crush mod_grenade_splash mod_projectile_splash splash unknown";
  //disallowed_dmg_array = strtok( disallowed_damage, " " );

	allowed_dmg		  = "mod_melee melee mod_grenade mod_projectile mod_explosive mod_impact";
	allowed_dmg_array = StrTok( allowed_dmg, " " );

	foreach ( dmg in allowed_dmg_array )
	{
		if ( ToLower( dmg ) == ToLower( damageType ) )
			return true;
	}
	return false;
}

// ================================================================================ //


creaky_board()
{
	level endon( "game_ended" );

	for ( ;; )
	{
		self waittill( "trigger_enter", player );
		player thread do_creak( self );
	}
}

do_creak( trigger )
{
	self endon( "disconnect" );
	self endon( "death" );

	self PlaySound( "step_walk_plr_woodcreak_on" );

	for ( ;; )
	{
		self waittill( "trigger_leave", leftTrigger );
		if ( trigger != leftTrigger )
			continue;

		self PlaySound( "step_walk_plr_woodcreak_off" );
		return;
	}
}

motion_light()
{
	level endon( "game_ended" );
	self.moveTracker = true;

	self.lightsOn = false;
	lights		  = GetEntArray( self.target, "targetname" );
	AssertEx( lights.size, "ERROR: trigger_ * _motion_light with no targets at " + self.origin );

	noself_array_call( [ "com_two_light_fixture_off", "com_two_light_fixture_on" ], ::PreCacheModel );

	foreach ( light in lights )
	{
		light.lightRigs = [];
		infoNull		= GetEnt( light.target, "targetname" );
		if ( !IsDefined( infoNull.target ) )
			continue;

		light.lightRigs = GetEntArray( infoNull.target, "targetname" );
	}


	for ( ;; )
	{
		self waittill( "trigger_enter" );

		while ( anythingTouchingTrigger( self ) )
		{
			objectMoved = false;
			foreach ( object in self.touchList )
			{
				if ( IsDefined( object.distMoved ) && object.distMoved > 5.0 )
					objectMoved = true;
			}

			if ( objectMoved )
			{
				if ( !self.lightsOn )
				{
					self.lightsOn = true;
					lights[ 0 ] PlaySound( "switch_auto_lights_on" );

					foreach ( light in lights )
					{
						light SetLightIntensity( 1.0 );

						if ( IsDefined( light.lightRigs ) )
						{
							foreach ( rig in light.lightRigs )
								rig SetModel( "com_two_light_fixture_on" );
						}
					}
				}
				self thread motion_light_timeout( lights, 10.0 );
			}

			wait( 0.05 );
		}
	}
}

motion_light_timeout( lights, timeout )
{
	self notify( "motion_light_timeout" );
	self endon( "motion_light_timeout" );

	wait( timeout );

	foreach ( light in lights )
	{
		light SetLightIntensity( 0 );
		if ( IsDefined( light.lightRigs ) )
		{
			foreach ( rig in light.lightRigs )
				rig SetModel( "com_two_light_fixture_off" );
		}
	}

	lights[ 0 ] PlaySound( "switch_auto_lights_off" );

	self.lightsOn = false;
}

outdoor_motion_dlight()
{
	if ( !IsDefined( level.outdoor_motion_light ) )
		level.outdoor_motion_light = LoadFX( "fx/misc/outdoor_motion_light" );
	
	level endon( "game_ended" );
	self.moveTracker = true;

	self.lightsOn = false;
	lightRig	  = GetEnt( self.target, "targetname" );
	AssertEx( lightRig.size, "ERROR: trigger_ * _motion_light with no targets at " + self.origin );
	lights = GetEntArray( lightRig.target, "targetname" );
	AssertEx( lights.size, "ERROR: trigger_ * _motion_light model target with no light targets at " + lightRig.origin );
	noself_array_call( [ "com_two_light_fixture_off", "com_two_light_fixture_on" ], ::PreCacheModel );
	for ( ;; )
	{
		self waittill( "trigger_enter" );

		while ( anythingTouchingTrigger( self ) )
		{
			objectMoved = false;
			foreach ( object in self.touchList )
			{
				if ( IsDefined( object.distMoved ) && object.distMoved > 5.0 )
					objectMoved = true;
			}

			if ( objectMoved )
			{
				if ( !self.lightsOn )
				{
					self.lightsOn = true;
					lightRig PlaySound( "switch_auto_lights_on" );
					lightRig SetModel( "com_two_light_fixture_on" );

					foreach ( light in lights )
					{
						Assert( !IsDefined( light.lightEnt ) );
						light.lightEnt = Spawn( "script_model", light.origin );
						light.lightEnt SetModel( "tag_origin" );
						PlayFXOnTag( level.outdoor_motion_light, light.lightEnt, "tag_origin" );
					}
				}
				self thread outdoor_motion_dlight_timeout( lightRig, lights, 10.0 );
			}

			wait( 0.05 );
		}
	}
}

outdoor_motion_dlight_timeout( lightRig, lights, timeout )
{
	self notify( "motion_light_timeout" );
	self endon( "motion_light_timeout" );

	wait( timeout );

	foreach ( light in lights )
	{
		Assert( IsDefined( light.lightEnt ) );
		light.lightEnt Delete();
	}

	lightRig PlaySound( "switch_auto_lights_off" );
	lightRig SetModel( "com_two_light_fixture_off" );

	self.lightsOn = false;
}

dog_bark()
{
	level endon( "game_ended" );
	self.moveTracker = true;

	dogOrigin = GetEnt( self.target, "targetname" );
	AssertEx( IsDefined( dogOrigin ), "ERROR: trigger_multiple_dog_bark with no target at " + self.origin );

	for ( ;; )
	{
		self waittill( "trigger_enter", player );

		while ( anythingTouchingTrigger( self ) )
		{
			maxDistMoved = 0;
			foreach ( object in self.touchList )
			{
				if ( IsDefined( object.distMoved ) && object.distMoved > maxDistMoved )
					maxDistMoved = object.distMoved;
			}

			if ( maxDistMoved > 6.0 )
			{
				dogOrigin PlaySound( "dyn_anml_dog_bark" );
				wait( RandomFloatRange( 16 / maxDistMoved, 16 / maxDistMoved + RandomFloat( 1.0 ) ) );
			}
			else
			{
				wait( 0.05 );
			}
		}
	}
}

trigger_door()
{
	doorEnt = GetEnt( self.target, "targetname" );
	AssertEx( IsDefined( doorEnt ), "ERROR: trigger_multiple_dyn_door with no door brush at " + self.origin );

	self.doorEnt	= doorEnt;
	self.doorAngle	= getVectorRightAngle( VectorNormalize( self GetOrigin() - doorEnt GetOrigin() ) );
	doorEnt.baseYaw = doorEnt.angles[ 1 ];
	openTime		= 1.0;

	for ( ;; )
	{
		self waittill( "trigger_enter", player );

		doorEnt thread doorOpen( openTime, self getDoorSide( player ) );

		if ( anythingTouchingTrigger( self ) )
			self waittill( "trigger_empty" );

		wait( 3.0 );

		if ( anythingTouchingTrigger( self ) )
			self waittill( "trigger_empty" );

		doorEnt thread doorClose( openTime );
	}
}

doorOpen( openTime, doorSide )
{
	if ( doorSide )
		self RotateTo( ( 0, self.baseYaw + 90, 1 ), openTime, 0.1, 0.75 );
	else
		self RotateTo( ( 0, self.baseYaw - 90, 1 ), openTime, 0.1, 0.75 );

	self PlaySound( "door_generic_house_open" );

	wait( openTime + 0.05 );
}

doorClose( openTime )
{
	self RotateTo( ( 0, self.baseYaw, 1 ), openTime );
	self PlaySound( "door_generic_house_close" );

	wait( openTime + 0.05 );
}

getDoorSide( player )
{
	return( VectorDot( self.doorAngle, VectorNormalize( player.origin - self.doorEnt GetOrigin() ) ) > 0 );
}

getVectorRightAngle( vDir )
{
	return( vDir[ 1 ], 0 - vDir[ 0 ], vDir[ 2 ] );
}

use_toggle()
{
	if ( self.classname != "trigger_use_touch" )
		return;

	lights = GetEntArray( self.target, "targetname" );
	Assert( lights.size );

	self.lightsOn = 1;
	foreach ( light in lights )
		light SetLightIntensity( 1.5 * self.lightsOn );


	for ( ;; )
	{
		self waittill( "trigger" );

		self.lightsOn = !self.lightsOn;
		if ( self.lightsOn )
		{
			foreach ( light in lights )
				light SetLightIntensity( 1.5 );

			self PlaySound( "switch_auto_lights_on" );
		}
		else
		{
			foreach ( light in lights )
				light SetLightIntensity( 0 );

			self PlaySound( "switch_auto_lights_off" );
		}
	}
}

bird_startle()
{
}

photo_copier_init( trigger )
{
	// self is trigger
	
	self.copier = get_photo_copier( trigger );
	AssertEx( self.copier.classname == "script_model", "Photocopier at " + trigger.origin + " doesn't target a photo copier" );

	copy_bar = GetEnt( self.copier.target, "targetname" );
	AssertEx( copy_bar.classname == "script_brushmodel", "Photocopier at " + trigger.origin + " doesn't target a photo copier" );

	light = GetEnt( copy_bar.target, "targetname" );
	AssertEx( light.classname == "light_spot" || light.classname == "light", "Photocopier at " + trigger.origin + " doesn't have a light" );

	light.intensity = light GetLightIntensity();
	light SetLightIntensity( 0 );
	trigger.copy_bar  = copy_bar;
	trigger.start_pos = copy_bar.origin;
	trigger.light	  = light;

	angles			= self.copier.angles + ( 0, 90, 0 );
	forward			= AnglesToForward( angles );
	trigger.end_pos = trigger.start_pos + ( forward * 30 );
}

get_photo_copier( trigger )
{
	if ( !IsDefined( trigger.target ) )
	{
		//cant target directly to a destructible toy, so we are grabing the nearest one, since primary light requires them to be far anyway
		toys   = GetEntArray( "destructible_toy", "targetname" );
		copier = toys[ 0 ];
		foreach ( toy in toys )
		{
			if ( IsDefined( toy.destructible_type ) && toy.destructible_type == "toy_copier" )
			{
				if ( Distance( trigger.origin, copier.origin ) > Distance( trigger.origin, toy.origin ) )
					copier = toy;
			}
		}
		AssertEx( Distance( trigger.origin, copier.origin ) < 128, "Photocopier at " + trigger.origin + " doesn't contain a photo copier" );
	}
	else
	{
		copier = GetEnt( trigger.target, "targetname" );
		AssertEx( IsDefined( copier ), "Photocopier at " + trigger.origin + " doesn't target a photo copier" );
		copier SetCanDamage( true );
	}	
	
	return copier;
}

waittill_copier_copies()
{
	self.copier endon( "FX_State_Change0" );
	self.copier endon( "death" );

	self waittill( "trigger_enter" );
}

photo_copier()
{
	level endon( "game_ended" );
	photo_copier_init( self );

	self.copier endon( "FX_State_Change0" );	// this is when copier breaks
	self thread photo_copier_stop();			// monitor copier for quick stop

	for ( ;; )
	{
		waittill_copier_copies();

		self PlaySound( "mach_copier_run" );

		if ( IsDefined( self.copy_bar ) )
		{
			reset_copier( self );
			thread photo_copier_copy_bar_goes();
			thread photo_copier_light_on();
		}
		wait( 3 );
	}
}

photo_copier_no_light()
{
	level endon( "game_ended" );
	self endon ( "death" );

	if ( get_template_level() == "hamburg" )
		return; // I don't need no stinking copies. // masking is not friendly for this - Nate

	self.copier = get_photo_copier( self );
	
	AssertEx( self.copier.classname == "script_model", "Photocopier at " + self.origin + " doesn't target or contain a photo copier" );
	
	self.copier endon( "FX_State_Change0" );	// this is when copier breaks

	for ( ;; )
	{
		waittill_copier_copies();
		self PlaySound( "mach_copier_run" );
		wait( 3 );
	}
}

// reset light and copy bar position, interruptes previous copy in progress
reset_copier( trigger )
{
	trigger.copy_bar MoveTo( trigger.start_pos, 0.2 );	// reset position
	trigger.light SetLightIntensity( 0 );
}

photo_copier_copy_bar_goes()
{
	self.copier notify( "bar_goes" );
	self.copier endon( "bar_goes" );
	self.copier endon( "FX_State_Change0" );
	self.copier endon( "death" );

	copy_bar = self.copy_bar;
	wait( 2.0 );
	copy_bar MoveTo( self.end_pos, 1.6 );
	wait( 1.8 );
	copy_bar MoveTo( self.start_pos, 1.6 );
	wait( 1.6 );	// wait( 13.35 );

	light = self.light;
	timer = 0.2;
	steps = timer / 0.05;

	for ( i = 0; i < steps; i++ )
	{
		intensity = i * 0.05;
		intensity /= timer;
		intensity = 1 - ( intensity * light.intensity );
		if ( intensity > 0 )
			light SetLightIntensity( intensity );
		wait( 0.05 );
	}
}

photo_copier_light_on()
{
	self.copier notify( "light_on" );
	self.copier endon( "light_on" );
	self.copier endon( "FX_State_Change0" );
	self.copier endon( "death" );

	light = self.light;
	timer = 0.2;
	steps = timer / 0.05;

	for ( i = 0; i < steps; i++ )
	{
		intensity = i * 0.05;
		intensity /= timer;
		light SetLightIntensity( intensity * light.intensity );
		wait( 0.05 );
	}

	photo_light_flicker( light );
}

// stopping light and bar move on death
photo_copier_stop()
{
	self.copier waittill( "FX_State_Change0" );
	self.copier endon( "death" );

	reset_copier( self );
}

photo_light_flicker( light )
{
	// flicker
	light SetLightIntensity( 1 );
	wait( 0.05 );
	light SetLightIntensity( 0 );
	wait( 0.10 );
	light SetLightIntensity( 1 );
	wait( 0.05 );
	light SetLightIntensity( 0 );
	wait( 0.10 );
	light SetLightIntensity( 1 );
}

fan_blade_rotate( type )
{
	Assert( IsDefined( type ) );

	speed = 0;
	time  = 20000;

	speed_multiplier = 1.0;
	if ( IsDefined( self.speed ) )
	{
		speed_multiplier = self.speed;
	}
	
	if ( type == "slow" )
	{
			if ( IsDefined( self.script_noteworthy ) && ( self.script_noteworthy == "lockedspeed" ) )
				speed = 180;
			else
				speed = RandomFloatRange( 100 * speed_multiplier, 360 * speed_multiplier );
	}
	else if ( type == "fast" )
		speed = RandomFloatRange( 720 * speed_multiplier, 1000 * speed_multiplier );
	else if ( type == "veryslow" )
		speed = RandomFloatRange( 1 * speed_multiplier, 2 * speed_multiplier );	// use the speed to really tune
	else
		AssertMsg( "Type must be fast, slow, or veryslow" );

	if ( IsDefined( self.script_noteworthy ) && ( self.script_noteworthy == "lockedspeed" ) )
		wait 0;
	else
		wait RandomFloatRange( 0, 1 );

	fan_angles = self.angles;
	fan_vec	   = ( AnglesToRight( self.angles ) * 100 ); // assures normalized vector is length of "1"
	fan_vec	   = VectorNormalize( fan_vec );

    while ( true )
    {
		dot_x = abs( VectorDot( fan_vec, ( 1, 0, 0 ) ) );
		dot_y = abs( VectorDot( fan_vec, ( 0, 1, 0 ) ) );
		dot_z = abs( VectorDot( fan_vec, ( 0, 0, 1 ) ) );

    	if ( dot_x > 0.9 )
        	self RotateVelocity( ( speed, 0, 0 ), time );
        else if ( dot_y > 0.9 )
        	self RotateVelocity( ( speed, 0, 0 ), time );
        else if ( dot_z > 0.9 )
        	self RotateVelocity( ( 0, speed, 0 ), time );
        else
        	self RotateVelocity( ( 0, speed, 0 ), time );

        wait time;
    }
}

triggerTouchThink( enterFunc, exitFunc )
{
	level endon( "game_ended" );

	self.entNum = self GetEntityNumber();

	while ( true )
	{
		self waittill( "trigger", player );

		if ( !IsPlayer( player ) && !IsDefined( player.finished_spawning ) )
			continue;

		if ( !IsAlive( player ) )
			continue;

		if ( !IsDefined( player.touchTriggers[ self.entNum ] ) )
			player thread playerTouchTriggerThink( self, enterFunc, exitFunc );
	}
}

playerTouchTriggerThink( trigger, enterFunc, exitFunc )
{
	if ( !IsPlayer( self ) )
		self endon( "death" );

	if ( !isSP() )
		touchName = self.guid;	// generate GUID
	else
		touchName = "player" + GetTime();		// generate GUID

	trigger.touchList[ touchName ] = self;
	if ( IsDefined( trigger.moveTracker ) )
		self.moveTrackers++;

	trigger notify( "trigger_enter", self );
	self notify( "trigger_enter", trigger );

	if ( IsDefined( enterFunc ) )
		self thread [[ enterFunc ]]( trigger );

	self.touchTriggers[ trigger.entNum ] = trigger;

	while ( IsAlive( self ) && self IsTouching( trigger ) && ( isSP() || !level.gameEnded ) )
		wait( 0.05 );

	// disconnected player will skip this code
	if ( IsDefined( self ) )
	{
		self.touchTriggers[ trigger.entNum ] = undefined;
		if ( IsDefined( trigger.moveTracker ) )
			self.moveTrackers--;

		self notify( "trigger_leave", trigger );

		if ( IsDefined( exitFunc ) )
			self thread [[ exitFunc ]]( trigger );
	}

	if ( !isSP() && level.gameEnded )
		return;

	trigger.touchList[ touchName ] = undefined;
	trigger notify( "trigger_leave", self );

	if ( !anythingTouchingTrigger( trigger ) )
		trigger notify( "trigger_empty" );
}

movementTracker()
{
	if ( IsDefined( level.DisablemovementTracker ) )
		return;
	self endon( "disconnect" );

	if ( !IsPlayer( self ) )
		self endon( "death" );

	self.moveTrackers = 0;
	self.distMoved	  = 0;

	for ( ;; )
	{
		self waittill( "trigger_enter" );

		lastOrigin = self.origin;
		while ( self.moveTrackers )
		{
			self.distMoved = Distance( lastOrigin, self.origin );
			lastOrigin	   = self.origin;
			wait( 0.05 );
		}

		self.distMoved = 0;
	}
}

anythingTouchingTrigger( trigger )
{
	return( trigger.touchList.size );
}

playerTouchingTrigger( player, trigger )
{
	Assert( IsDefined( trigger.entNum ) );
	return( IsDefined( player.touchTriggers[ trigger.entNum ] ) );
}

interactive_tv()
{
	tv_array = GetEntArray( "interactive_tv", "targetname" );
	if ( tv_array.size )
	{
		noself_array_call( [ "com_tv2_d", "com_tv1_d", "com_tv1", "com_tv2", "com_tv1_testpattern", "com_tv2_testpattern" ], ::PreCacheModel );
		level.breakables_fx[ "tv_explode" ] = LoadFX( "fx/explosions/tv_explosion" );
	}
	level.tv_lite_array = GetEntArray( "interactive_tv_light", "targetname" );
	array_thread( GetEntArray( "interactive_tv", "targetname" ), ::tv_logic );
}

tv_logic()
{
	self SetCanDamage( true );
	self.damagemodel = undefined;
	self.offmodel	 = undefined;

	self.damagemodel = "com_tv2_d";
	self.offmodel	 = "com_tv2";
	self.onmodel	 = "com_tv2_testpattern";
	if ( IsSubStr( self.model, "1" ) )
	{
		self.offmodel = "com_tv1";
		self.onmodel  = "com_tv1_testpattern";
	}

	if ( IsDefined( self.target ) )
	{
		if ( IsDefined( level.disable_interactive_tv_use_triggers ) )
		{
			usetrig = GetEnt( self.target, "targetname" );
			if ( IsDefined( usetrig ) )
				usetrig Delete();
		}
		else
		{
			self.usetrig = GetEnt( self.target, "targetname" );
			self.usetrig UseTriggerRequireLookAt();
			self.usetrig SetCursorHint( "HINT_NOICON" );
		}
	}
		
	array = get_array_of_closest( self.origin, level.tv_lite_array, undefined, undefined, 64 );
	
	if ( array.size )
	{
		self.lite			= array[ 0 ];
		level.tv_lite_array = array_remove( level.tv_lite_array, self.lite );
		self.liteintensity	= self.lite GetLightIntensity();
	}	
	
	self thread tv_damage();

	if ( IsDefined( self.usetrig ) )
		self thread tv_off();
}

tv_off()
{
	self.usetrig endon( "death" );
	
	while ( 1 )
	{		
		wait 0.2;
		self.usetrig waittill( "trigger" );
		// it would be nice to play a sound here
		
		self notify( "off" );
		
		if ( self.model == self.offmodel )
		{
			self SetModel( self.onmodel );
			if ( IsDefined( self.lite ) )
				self.lite SetLightIntensity( self.liteintensity );
		}
		else
		{
			self SetModel( self.offmodel );
			if ( IsDefined( self.lite ) )
				self.lite SetLightIntensity( 0 );
		}
	}
}

tv_damage()
{
	self waittill( "damage", damage, other, direction_vec, P, type );
		
	self notify( "off" );
	if ( IsDefined( self.usetrig ) )
		self.usetrig notify( "death" );
		
	self SetModel( self.damagemodel );
	
	if ( IsDefined( self.lite ) )
		self.lite SetLightIntensity( 0 );

	PlayFXOnTag( level.breakables_fx[ "tv_explode" ], self, "tag_fx" );
	
	self PlaySound( "tv_shot_burst" );
	if ( IsDefined( self.usetrig ) )
		self.usetrig Delete();
}
