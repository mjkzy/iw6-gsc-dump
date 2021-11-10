#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\alien\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\agents\_agent_utility;
#include maps\mp\alien\_perk_utility;

CONST_DRILL_HEALTH 				= 150;	// health: of planted bomb to withstand alien attack
CONST_DRILL_HEALTH_HARDCORE		= 1250;	// bomb health in hardcore mode
CONST_DRILL_HEALTH_HARDCORE_SOLO= 2000;	// bomb health in hardcore mode
CONST_HEALTH_INVULNERABLE		= 20000;

CONST_DRILL_THREATBIAS_MIN		= -3000;// min threat - starting threat, threat while players are in range
CONST_DRILL_THREATBIAS_MAX		= -1000;	// max threat
CONST_DRILL_THREAT_RADIUS_MIN	= 1000;	// radius before threat is increased based on distance
CONST_DRILL_THREAT_RADIUS_MAX	= 2500;	// radius where threat increased is maxed

CONST_DRILL_MODEL				= "mp_laser_drill";
CONST_DRILL_MODEL_OBJ			= "mp_laser_drill";

CONST_DRILL_OUTLINE_COLOR_INDEX	= 3;

// drill overheat constants
CONST_DRILL_OVERHEAT_TIMER 			= 45; // seconds
CONST_DRILL_OVERHEAT_TIMER_DECREASE = 5;
CONST_DRILL_OVERHEAT_TIMER_MIN 		= 25;
CONST_DRILL_OVERHEAT_TIMER_WARN_1 	= 20;
CONST_DRILL_OVERHEAT_TIMER_WARN_2	= 10;

init_drill()
{
	// state flags
	flag_init( "drill_detonated" );
	flag_init( "drill_destroyed" );
	flag_init ( "drill_drilling" );
	
	level.drill_use_trig = getent( "drill_pickup_trig", "targetname" ); // needs to exist in map, and needs to be placed in an unreachable location
	if ( isdefined( level.drill_use_trig ) )
		level.drill_use_trig.original_origin = level.drill_use_trig.origin;
	
	level.drill_id 			= 0;
	level.drill_marker_id 	= 1;
	
	// carried drill
	level.drill 			= undefined;
	level.drill_carrier 	= undefined;

	// inits
	init_fx();				// fx
	init_drill_drop_loc();	// drill start location
	
	// drill device loop
	thread drill_think();
	
	//drill gets dropped out of playable area
	level thread drill_out_of_playable();
}
	
drill_out_of_playable()
{
	level endon( "game_ended" );
	out_of_playable_areas = getentarray( "trigger_hurt","classname" );
	while ( 1 )
	{
		if ( !isDefined ( level.drill ) )
		{
			wait ( .5 );
			continue;
		}
		
		foreach ( area in out_of_playable_areas )
		{
			if ( !isDefined ( area.script_noteworthy ) || area.script_noteworthy !=  "out_of_playable" )
				continue;
				
			if ( level.drill istouching ( area ) )
			{
				level.drill delete();
				
				//AssertEx ( isDefined ( level.last_drill_pickup_origin ) && isDefined (  level.last_drill_pickup_angles ),"Last drill pickup spot was not defined" );
				playfx( level._effect[ "alien_teleport" ] , level.last_drill_pickup_origin );
				playfx ( level._effect[ "alien_teleport_dist" ], level.last_drill_pickup_origin );
				
				drop_drill ( level.last_drill_pickup_origin, level.last_drill_pickup_angles );
				
				foreach ( player in level.players )
				{
					player setLowerMessage( "drill_overboard",&"ALIEN_COLLECTIBLES_DRILL_OUTOFPLAY",4 );
				}
			}
		}
		wait( 0.1 );
		
	}
	
}


//=======================================================
//		Inits
//=======================================================

init_drill_drop_loc()
{
	level.drill_locs = [];
	level.drill_locs = getstructarray( "bomb_drop_loc", "targetname" );
}

init_fx()
{
	// fx
	level._effect[ "drill_laser_contact" ] 		= loadfx( "vfx/gameplay/alien/vfx_alien_drill_laser_contact" );
	level._effect[ "drill_laser" ] 				= loadfx( "vfx/gameplay/alien/vfx_alien_drill_laser" );
	level._effect[ "stronghold_explode_med" ] 	= loadfx( "vfx/gameplay/mp/killstreaks/vfx_sentry_gun_explosion" );
	level._effect[ "stronghold_explode_large" ] = loadfx( "fx/explosions/aerial_explosion" );
	level._effect[ "alien_hive_explode" ] 		= loadfx( "fx/explosions/alien_hive_explosion" );

	level.spawnGlowModel["friendly"] 			= "mil_emergency_flare_mp";
	level.spawnGlow["friendly"] 				= loadfx( "fx/misc/flare_ambient_green" );
}

//=======================================================
//	Drill object loop
//=======================================================

// loop to respawn drill object
drill_think()
{
	level endon( "game_ended" );
	
	//wait 1;
	while ( !isdefined( level.players ) || level.players.size < 1 )
		wait 0.05;
	
	level.drill_health_hardcore = CONST_DRILL_HEALTH_HARDCORE;
	if ( isPlayingSolo() )
		level.drill_health_hardcore = CONST_DRILL_HEALTH_HARDCORE_SOLO;
	
	level thread drill_threat_think();
	
	// drill initial drop location
	//drop_loc = ( 2801, -117, 595 ); 	// default for "mp_alien_town"
	drop_loc = ( 2822.27, -196, 524.068 ); 	// default to match drill animation in "mp_alien_town"
	drop_loc_struct = getstruct( "drill_loc", "targetname" );
	
	if ( isdefined( drop_loc_struct ) )
		drop_loc = drop_loc_struct.origin;
	
	//drop_angles = ( 0, 0, 0 );
	drop_angles = ( 1.287, 0.995, -103.877 );   //default to match drill animation in "mp_alien_town"
	if ( isdefined( drop_loc_struct ) && isdefined( drop_loc_struct.angles ) )
		drop_angles = drop_loc_struct.angles;
	
/#
	drop_loc = maps\mp\alien\_debug::adjust_drill_loc( drop_loc );
#/
		
	level waittill( "spawn_intro_drill" ,spawnpos,spawnang );
	
	// overrides of drill origin and angles, ex: intro animation end frame
	drop_to_ground = true;
	if ( isdefined( level.initial_drill_origin ) && isdefined( level.initial_drill_angles ) )
	{
		drop_loc 	= level.initial_drill_origin;
		drop_angles = level.initial_drill_angles;
		drop_to_ground = false;
	}
	
	if ( isDefined( spawnpos ) && isDefined( spawnang ) )
	{
		drop_loc 	= spawnpos;
		drop_angles = spawnang;
		drop_to_ground = false;
	}
	
	// TODO: remove after new model is in, and carry object is setup, 
	// currently is to remove the vest model dropped on ground when dropping drill
	marker = undefined;
	
	while ( true )
	{
		spawn_drill_raw( CONST_DRILL_MODEL_OBJ, drop_loc, drop_angles, marker, drop_to_ground );
		drop_to_ground = true;
		level waittill( "new_drill", drop_loc, drop_angles, marker );
		assertex( isdefineD( drop_loc ), "Drill dropped at invalid position" );
		
		wait 0.05;
	}
}

// drop drill spawns new drill
drop_drill( pos, angles, marker )
{
	level notify( "new_drill", pos, angles, marker );
}

// spawns the drill and listens for pickup
spawn_drill_raw( model, pos, angles, marker, drop_to_ground )
{
	if ( !isdefined( drop_to_ground ) )
		drop_to_ground = true;
	
	level.drill_carrier = undefined; // means no one is carrying drill as drill is spawned
	
	// remove previous version, <safe>
	if ( isdefined( level.drill ) )
	{
		level.drill delete();	
		level.drill = undefined;
	}
	
	// drill object
	level.drill = spawn( "script_model", pos );
	level.drill setmodel( model );
	level.drill set_drill_icon();
	level.drill.state = "idle"; // idle meaning it can be picked up/planted
	if ( drop_to_ground )
		level.drill thread angles_to_ground( pos, angles, ( 0, 0, -4 ) );
	else
		level.drill.angles = angles;
	
	// wait until intro sequence is complete
	if ( flag_exist( "intro_sequence_complete" ) && !flag( "intro_sequence_complete" ) )
		flag_wait( "intro_sequence_complete" );
	
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::add_to_drill_preplant_watch_list( level.drill );
	
	//using marker to kill the dropped alien drill model.  
	//TODO: remove "marker" when we get a proper drill model and the tags are correct for makeusable
	if ( !is_true( level.automatic_drill ) )
		level.drill thread drill_pickup_listener( marker );
	
	level notify( "drill_spawned" );
	
}

enable_alt_drill_pickup( drill )
{	
	assert( isdefined( level.drill_use_trig ) );
	level.drill_use_trig.origin = drill.origin + ( 0, 0, 24 );
}

disable_alt_drill_pickup()
{
	assert( isdefined( level.drill_use_trig ) );
	level.drill_use_trig.origin = level.drill_use_trig.original_origin;
}

// listen for pickup, updates icon from drill to carrier
drill_pickup_listener( marker )
{
	// self is level.drill, the script model
	self endon( "death" );
	
	level endon( "game_ended" );
	level endon( "new_drill" );
	
	if ( isdefined( level.drill_use_trig ) )
	    use_trig = level.drill_use_trig;
	 else
	 	use_trig= self;
	
	if ( !is_true( level.prevent_drill_pickup ) )
	{
		// ======= SETUP FOR PICKUP =======
		if ( isdefined( level.drill_use_trig ) )
		{	
			level.drill_use_trig enable_alt_drill_pickup( self );
		}
		else
		{
			use_trig MakeUsable();
		}
	}
	
	use_trig SetCursorHint( "HINT_ACTIVATE" );	
	use_trig SetHintString( &"ALIEN_COLLECTIBLES_PICKUP_BOMB" );
		
	// ======= WAIT FOR PICKUP =======
	while( true )
	{
		use_trig waittill( "trigger", owner );

		if ( owner is_holding_deployable() )
		{
			owner setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HOLDING", 3 );
			continue;
		}
		
		if ( owner GetStance() == "prone" || owner GetStance() == "crouch" )
		{
			owner setLowerMessage( "change_stance", &"ALIENS_PATCH_CHANGE_STANCE", 3 );
			continue;
		}
		if ( is_true ( owner.picking_up_item ) )
			continue;
		
		if ( is_true ( owner.isCarrying ) )
			continue;
		
		owner.has_special_weapon = true;
		
		owner _disableUsability();
		owner thread delayed_enable_usability();
		
		if( isPlayer( owner ) )
			break;
	}
	
	// ======= PICKED UP =======
	// tell the world who picked up the drill
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::remove_from_drill_preplant_watch_list( level.drill );
	
	// move alternate drill pickup trigger far away
	if ( isdefined( level.drill_use_trig ) )
		level.drill_use_trig disable_alt_drill_pickup();

	level notify( "drill_pickedup", owner );
	self PlaySound( "extinction_item_pickup" );
	
	level.drill_carrier = owner;
	level.last_drill_pickup_origin = drop_to_ground( self.origin, 16, -32 ); // trace to ground, to prevent cascading offset
	level.last_drill_pickup_angles = self.angles;
	level.drill_carrier set_drill_icon( true );
	self.state = "carried";
	
	// player setup
	owner thread drop_drill_on_death();
	owner thread drop_drill_on_disconnect();
	
	owner.lastweapon = owner GetCurrentWeapon();
	owner _giveWeapon( "alienbomb_mp" );
	
	owner SwitchToWeapon( "alienbomb_mp" );
	owner DisableWeaponSwitch();
	owner _disableOffhandWeapons();
	
	// ======= CLEAN UP =======
	// clean up drill marker model after pickup
	if (IsDefined (marker) )
		marker delete();
	
	owner notify( "kill_spendhint" );
	owner notify( "dpad_cancel" );
	// removed from the world, also ends threads running on the pickupable object
	self delete();
	
}

delayed_enable_usability()
{
	self endon( "death" );
	self endon( "disconnect" );
	wait ( 1 );
	self _enableUsability();
}


// drop drill when player so others can pick it up
drop_drill_on_death()
{
	// self is player
	level endon( "game_ended" );
	level endon( "new_drill" );			// new drill was requested, old drill will be removed
	level endon( "drill_planted" );		// drill left hand of owner
	level endon( "drill_dropping" );	// drill left hand of owner
	
	// only one instance of this per player
	self notify( "watching_drop_drill_on_death" );
	self endon( "watching_drop_drill_on_death" );
	
	// either death or last stand mode
	self waittill_either( "death", "last_stand" );

	self Takeweapon( "alienbomb_mp" );
	self EnableWeaponSwitch();
	self SwitchToWeapon( self.lastWeapon );
	self _enableOffhandWeapons();
	level.drill_carrier = undefined;

	assert( isdefined( self.last_death_pos ) );
	
	//make sure the last_death_pos is actually on the ground
	groundpos = GetGroundPosition( self.last_death_pos + (0,0,4 ),8 );
	angles = self.angles;

	if ( is_true ( self.kill_trigger_event_processed ) ) //player killed by kill trigger, don't drop the drill here
	{
		drill_spot = getClosest ( self.origin, level.killTriggerSpawnLocs );	
		groundpos = GetGroundPosition ( drill_spot.origin + ( 0,0,4 ),8 );
		if ( !isDefined( drill_spot.angles ) )
			drill_spot.angles = ( 0,0,0 );
		angles = drill_spot.angles;
	}
	drop_drill( groundpos, angles );	
}

//drop the drill when the owner disconnects while holding it
drop_drill_on_disconnect()
{
	level endon( "drill_dropping" );
	level endon( "game_ended" );
	self endon( "death" );
	self endon ( "last_stand" );

	self waittill( "disconnect" );
	
	playfx( level._effect[ "alien_teleport" ] , level.last_drill_pickup_origin );
	playfx ( level._effect[ "alien_teleport_dist" ], level.last_drill_pickup_origin );
	drop_drill ( level.last_drill_pickup_origin, level.last_drill_pickup_angles );		
	
	foreach ( player in level.players )
	{
		if ( !isAlive ( player ) )
			continue;
		
		if ( player == self ) 
			continue;
		
		player setLowerMessage( "drill_overboard",&"ALIEN_COLLECTIBLES_DRILL_OUTOFPLAY",4 );
	}		
	
}

// teleport the drill if not near blocker
CONST_DRILL_TELEPORT_RANGE = 1250;

teleport_drill( pos )
{
	wait 5; // padding, so hive destruction fx can finish
	
	// only if drill is not carried and out of set range
	if ( isdefined( level.drill ) && !isdefined( level.drill_carrier ) && ( distance( pos, level.drill.origin ) > CONST_DRILL_TELEPORT_RANGE ) )
	{
		pos = drop_to_ground( pos, 16, -64 ); // in case the struct is floating
		level.drill angles_to_ground( pos, level.drill.angles, ( 0, 0, -4 ) ); // spawn drill oriented to ground normal
		level.drill set_drill_icon();
		enable_alt_drill_pickup( level.drill );
	}
}

// loops until drilling is complete, handles being offline
drilling( pos, owner )
{
	if ( isDefined( level.set_drill_state_drilling_override ) )
	{
		self thread [[level.set_drill_state_drilling_override]]( pos,owner );
		return;
	}
	
	// self is hive location struct drill is drilling
	self endon( "stop_listening" );
	self endon( "drill_complete" );
		
	// =======[STATE: PLANT]======= //
	self thread set_drill_state_plant( pos, owner );
	
	level.drill 			endon( "death" );
	level.drill.owner 		= owner;
	level.encounter_name 	= self.target;
	level.drill.start_time = gettime();	// initial start time, in case drill is killed before it started
	
	flag_set( "drill_drilling" );
	
	// wait till unfold animation completes
	level.drill waittill_any_timeout( 5, "drill_finished_plant_anim" );
	
	// set timing parameters ( ex. depth, layers etc. )
	self init_drilling_parameters();
	
	// =======[STATE: RUN]======= //
	level.drill.start_time = gettime(); // updated start time
	self thread set_drill_state_run( owner );
	
	self maps\mp\alien\_hive::hive_play_drill_planted_animations();
	
	// wait till offline
	level.drill waittill( "offline", attacker, damage );
	
	// =======[STATE: OFF]======= //
	self thread set_drill_state_offline();
	
	flag_set( "drill_destroyed" );

	wait 2;
	maps\mp\gametypes\aliens::AlienEndGame( "axis", maps\mp\alien\_hud::get_end_game_string_index( "drill_destroyed" ) );
	return;
}

set_drill_attack_setup()
{
	synchDirections = [];
	synchDirections["brute"][0] = set_attack_sync_direction( ( 0, 1, 0 ), "alien_drill_attack_drill_F_enter", "alien_drill_attack_drill_F_loop", "alien_drill_attack_drill_F_exit", "attack_drill_front", "attack_drill" );
	synchDirections["brute"][1] = set_attack_sync_direction( ( -1, 0, 0 ), "alien_drill_attack_drill_R_enter", "alien_drill_attack_drill_R_loop", "alien_drill_attack_drill_R_exit", "attack_drill_right", "attack_drill" );
	synchDirections["brute"][2] = set_attack_sync_direction( ( 1, 0, 0 ), "alien_drill_attack_drill_L_enter", "alien_drill_attack_drill_L_loop", "alien_drill_attack_drill_L_exit", "attack_drill_left", "attack_drill" );
	synchDirections["goon"][0] = set_attack_sync_direction( ( 0, 1, 0 ), "alien_goon_drill_attack_drill_F_enter", "alien_goon_drill_attack_drill_F_loop", "alien_goon_drill_attack_drill_F_exit", "attack_drill_front", "attack_drill" );
	synchDirections["goon"][1] = set_attack_sync_direction( ( -1, 0, 0 ), "alien_goon_drill_attack_drill_R_enter", "alien_goon_drill_attack_drill_R_loop", "alien_goon_drill_attack_drill_R_exit", "attack_drill_right", "attack_drill" );
	synchDirections["goon"][2] = set_attack_sync_direction( ( 1, 0, 0 ), "alien_goon_drill_attack_drill_L_enter", "alien_goon_drill_attack_drill_L_loop", "alien_goon_drill_attack_drill_L_exit", "attack_drill_left", "attack_drill" );
	
	endNotifies[0] = "offline";
	endNotifies[1] = "death";
	endNotifies[2] = "drill_complete";
	endNotifies[3] = "destroyed";

	self set_synch_attack_setup( synchDirections, true, endNotifies, undefined, ::drill_synch_attack_play_anim, ::drill_synch_attack_play_anim, ::drill_synch_attack_exit, "drill" );
}

drill_synch_attack_play_anim( anim_name )
{
	level.drill ScriptModelClearAnim();
	level.drill ScriptModelPlayAnim( anim_name );
}

drill_synch_attack_exit( anim_name, anim_length )
{
	if ( IsDefined( anim_name ) )
	{
		level.drill ScriptModelClearAnim();
		level.drill ScriptModelPlayAnim( anim_name );
		wait anim_length;
	}
	
	if ( IsAlive( level.drill ) && !flag( "drill_detonated" ) )
	{	
		level.drill ScriptModelClearAnim();
		level.drill ScriptModelPlayAnim( "alien_drill_loop" );	
	}
}

use_alternate_drill()
{
	return true;
}

watch_to_repair( hive_struct )
{
	self endon( "drill_complete" );
	self endon( "death" );
	hive_struct endon( "hive_dying" );

	wait 5.0;
	
	self MakeUnUsable();
	
	CONST_DRILL_REPAIR_PAYMENT = 100;
	CONST_DRILL_HEALTH_REPAIRED = 1000;
	CONST_DRILL_REPAIR_BASE_TIME = 4000;  // Time in ms for solo mode to repair drill
	CONST_DRILL_PER_PLAYER_ADDITIONAL_TIME = 2000; //10 seconds total for 4 players
	while ( 1 )
	{
		self MakeUnusable();

		while ( 1 )
		{
			drill_health = ( self.health - CONST_HEALTH_INVULNERABLE ) / level.drill_health_hardcore;
			
			if ( drill_health < 0.75 )
				break;
			
			wait ( 1 );
		}
		
		self MakeUsable();
		
		if ( isDefined( level.drill_repair ) )
			self SetHintString( level.drill_repair );
		else
			self SetHintString( &"ALIEN_COLLECTIBLES_DRILL_REPAIR" );
		self waittill( "trigger", player );
		
		if ( is_true ( player.iscarrying ) )
			continue;
		
		self SetHintString( "" );
		
		player_count = level.players.size;
		player.isRepairing = true;	
		level notify ("dlc_vo_notify","drill_repair", player);
		use_time = int( CONST_DRILL_REPAIR_BASE_TIME * player perk_GetDrillTimeScalar() * player.drillSpeedModifier );
			
		if( player_count > 1 )
			use_time = int( ( CONST_DRILL_REPAIR_BASE_TIME + (( player_count - 1 ) * CONST_DRILL_PER_PLAYER_ADDITIONAL_TIME ) ) * player perk_GetDrillTimeScalar() * player.drillSpeedModifier );
			
		
		result = self useHoldThink( player, use_time );
		
		if( !result )
		{
			player.isRepairing = false;
			continue;
		}
		
		if ( isdefined( level.drill_sfx_lp ) )
		{
			if ( isdefined( level.drill_overheat_lp_02 ))
				level.drill_overheat_lp_02 StopLoopSound();

			if ( !hive_struct is_door() && !hive_struct is_door_hive() && level.script != "mp_alien_dlc3" )
			{
				if( level.script == "mp_alien_last" )
					level.drill_sfx_lp PlayLoopSound( "alien_conduit_on_lp" );
				else
					level.drill_sfx_lp PlayLoopSound( "alien_laser_drill_lp" );
			}
		}
		
		level notify( "dlc_vo_notify","drill_repaired" , player);
		level notify( "drill_repaired");
		player.isRepairing = false;
		
		// black box print
		hive_struct thread drill_reset_BBPrint( player );
		
        player maps\mp\alien\_persistence::give_player_currency( CONST_DRILL_REPAIR_PAYMENT );
		self.health = level.drill_health_hardcore + CONST_HEALTH_INVULNERABLE;       
		level.drill_last_health = level.drill_health_hardcore + CONST_HEALTH_INVULNERABLE;
		
		update_drill_health_HUD();
		
		player.isRepairing = false;
	
		// EoG tracking: drill restarts
		player maps\mp\alien\_persistence::eog_player_update_stat( "drillrestarts", 1 );
		
		wait 1.0;
	}
	
}

// [!] function not to be used to reset drills not yet planted
set_drill_state_plant( pos, owner )
{
	// self is hive location struct
	// reset drill
	if ( isdefined( level.drill ) )
	{
		level.drill delete();	
		level.drill = undefined;
	}
	
	// TODO: Replace with animated drill model
	level.drill = spawn( "script_model", pos );
	level.drill setmodel( CONST_DRILL_MODEL ); 
	level.drill.state = "planted";
	level.drill.angles = self.angles;
	
	// Only allow synced attack when drilling a hive
	if( !is_door())
		level.drill set_drill_attack_setup();

	if ( isDefined( level.drill_attack_setup_override ) ) //for overriding the default sync animations if necessary
		 level.drill [[level.drill_attack_setup_override ]]();	
	
	//level.drill thread angles_to_ground( pos, self.angles, ( 0, 0, 0 ) );
	
	health = CONST_DRILL_HEALTH;
	if ( use_alternate_drill() )
	{
		health = level.drill_health_hardcore;
		level.drill thread watch_to_repair( self );
	}
	level.drill.maxhealth 			= CONST_HEALTH_INVULNERABLE + health;
	level.drill.health 				= int( CONST_HEALTH_INVULNERABLE +  ( health * owner perk_GetDrillHealthScalar() ) );
	level.drill thread watch_drill_health_for_challenge();		
	
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::add_to_outline_drill_watch_list ( level.drill, 0 );
	
	thread sfx_drill_plant();
	
	// init depth marker
	self.depth_marker = gettime();
	
	level thread maps\mp\alien\_music_and_dialog::playVOForBombPlant(owner );

	// remove drill icon
	destroy_drill_icon();

	// Normal drill enter anim
	if( !is_door() && !is_door_hive() )
	{
		level.drill ScriptModelPlayAnim( "alien_drill_enter" );
		wait 4;
	}
	else 
	{
		//small wait here since there isn't a seperate unfolding/folding animation for the door drilling
		wait .5;
	}

	level.drill notify( "drill_finished_plant_anim" );
}
watch_drill_health_for_challenge()
{
	self endon( "drill_complete" );
	self endon( "death" );
	while ( 1 )
	{
		drill_health = ( level.drill.health - CONST_HEALTH_INVULNERABLE ) / level.drill_health_hardcore;
			
		if ( drill_health < 0.5 )
		{
			maps\mp\alien\_challenge::update_challenge ( "no_stuck_drill" , false);
			break;
		}
		wait ( 1 );
	}
}
drill_threat_think()
{
	// self is stronghold_loc struct
	level endon( "game_ended" );

	
	interval = 1; // seconds
	while ( 1 )
	{
		if ( !isdefined( level.drill ) || !IsSentient( level.drill ) || !isAlive( level.drill ) )
		{
			wait interval;
			continue;
		}
		
		if ( use_alternate_drill() )
		{
			self.drill.threatbias = -1000;
			wait interval;
			continue;
		}
		
		total_dist = 0;
		players_available = 0;
		foreach ( player in level.players )
		{
			if ( isdefined( player ) &&  isalive( player ) )
			{
				players_available++;
				total_dist += distance2D( player.origin, level.drill.origin );
			}
		}
		
		// not enough players
		if ( players_available == 0 )
		{
			// reset
			level.drill.threatbias = int( CONST_DRILL_THREATBIAS_MIN );
			wait interval;
			continue;
		}
		
		average_dist = total_dist / max( 1, players_available );
		
		if ( average_dist < CONST_DRILL_THREAT_RADIUS_MIN )
		{
			level.drill.threatbias = int( CONST_DRILL_THREATBIAS_MIN );
		}
		else if ( average_dist > CONST_DRILL_THREAT_RADIUS_MAX )
		{
			level.drill.threatbias = int( CONST_DRILL_THREATBIAS_MAX );
		}
		else
		{
			radius_value_range	= CONST_DRILL_THREAT_RADIUS_MAX - CONST_DRILL_THREAT_RADIUS_MIN;
			threat_value_range 	= CONST_DRILL_THREATBIAS_MAX - CONST_DRILL_THREATBIAS_MIN;

			dist_ratio 			= ( average_dist - CONST_DRILL_THREAT_RADIUS_MIN ) / radius_value_range;
			threat_delta 		= dist_ratio * threat_value_range;
			
			level.drill.threatbias = int( CONST_DRILL_THREATBIAS_MIN + threat_delta );
		}
		
		wait interval;
	}
}

set_drill_state_run( owner )
{
	if ( isDefined( level.set_drill_state_run_override ) )
	{
		self thread [[level.set_drill_state_run_override]]( owner );
		return;
	}
	// self is stronghold_loc struct
	self endon( "death" );
	self endon( "stop_listening" );
	
	level.drill.state = "online";
	level.drill notify( "online" );
	
	// setup for attackable
	level.drill setCanDamage( true );
	level.drill MakeUnUsable();
	level.drill SetHintString( "" );
	
	health = CONST_DRILL_HEALTH;
	if ( use_alternate_drill() )
	{
		health = level.drill_health_hardcore;
	}
	
	// reset attributes
	level.drill.maxhealth 			= CONST_HEALTH_INVULNERABLE + health;
	level.drill.health 				= int( CONST_HEALTH_INVULNERABLE +  ( health * level.drill.owner perk_GetDrillHealthScalar() ) );
	level.drill.threatbias 			= CONST_DRILL_THREATBIAS_MIN;
	level.drill MakeEntitySentient( "allies" );
	level.drill SetThreatBiasGroup( "drill" );

	update_drill_health_HUD();
	
	// tell aliens drill is up for attack!
	foreach ( agent in level.agentArray )
	{
		if ( isdefined( agent.wave_spawned ) && agent.wave_spawned )
			agent GetEnemyInfo( level.drill );
	}
	// play fx on drill when armed
	laser_fx_tag_angles = level.drill GetTagAngles( "tag_laser" );
	laser_fx_dir_forward = AnglesToForward( laser_fx_tag_angles );
	laser_fx_dir_up = AnglesToUp( laser_fx_tag_angles );
	
	laser_offset_dir = VectorCross(laser_fx_dir_forward,(0,0,1));
	fx_loc = level.drill GetTagOrigin( "tag_laser_end" ) - ( 0, 0, 16 ) + (laser_offset_dir * 4 * -1) + (laser_fx_dir_forward * 1.0 * -1 );
	laser_fx_loc = level.drill GetTagOrigin( "tag_laser" ) - ( 0, 0, 8 ) ;

	level.drill.fxEnt = SpawnFx( level._effect[ "drill_laser_contact" ], fx_loc );
	level.drill.fxLaserEnt = SpawnFx( level._effect[ "drill_laser" ], laser_fx_loc, laser_fx_dir_forward, laser_fx_dir_up );
	// play loop sfx
	door = ( self is_door() || self is_door_hive() );
	thread sfx_drill_on(door);
	
	// Play door drilling anim
	if( is_door())
	{
		level notify( "drill_start_door_fx" );
		level.drill ScriptModelPlayAnim( "alien_drill_open_door" ); // Door drilling anim
	}
	else if ( isDefined( level.custom_hive_logic ) )
	{
		level [[level.custom_hive_logic]]();
	}
	
	// Play drilling loop anim
	else
	{
		TriggerFx( level.drill.fxEnt );
		TriggerFx( level.drill.fxLaserEnt );
		level.drill ScriptModelPlayAnim( "alien_drill_loop" );
	}
	
	// friendly fire and offline catch
	self thread handle_bomb_damage();

	// update time marker, to track running time, so it can be subtracted from total when it runs again
	self.depth_marker = gettime();
		
	// thread to watch for end of drilling
	self thread monitor_drill_complete( self.depth );
	self thread maps\mp\alien\_hive::hive_pain_monitor();
	
	// set waypoint to defend location
	self thread maps\mp\alien\_hive::set_hive_icon( "waypoint_alien_defend" );
	
	// remove drill icon
	destroy_drill_icon();
	
	maps\mp\alien\_hud::turn_on_drill_meter_HUD( self.depth );
	
	level thread watch_drill_depth_for_vo( self.depth );
}

watch_drill_depth_for_vo ( time )
{
	level endon( "drill_detonated");
	level endon( "game_ended" );
	wait ( time/2 );
	level thread maps\mp\alien\_music_and_dialog::playVOForDrillHalfway();	
}

monitor_drill_complete( depth )
{
	// self is stronghold_loc struct
	self endon( "death" );
	self endon( "stop_listening" );
	
	level.drill endon( "offline" );
	
	while ( self.layers.size > 0 )
	{
		layer_depth = self.layers[ self.layers.size - 1 ];
		is_last_layer = self.layers.size == 1;
		
		remaining_depth_to_layer = depth - layer_depth;
		
		if ( is_last_layer )
			self childthread maps\mp\alien\_music_and_dialog::playMusicBeforeReachLayer( remaining_depth_to_layer );
		
		msg = "remaining_depth_to_layer is negative, ";
		msg = msg + "[depth=" + depth + "][layer_depth="+ layer_depth +"][layer index="+ (self.layers.size - 1) +"]";
		msg = msg + "[hive.origin=" + self.origin + "]";
		assertex( remaining_depth_to_layer >= 0, msg );
		
		self waittill_any_timeout( remaining_depth_to_layer, "force_drill_complete" );
		
		// layer is reached
		self.layer_completed++;
		SetOmnvar( "ui_alien_drill_layer_completed", self.layer_completed );
		self.layers = array_remove( self.layers, layer_depth );
		depth = layer_depth;
		reach_layer_earthquake();
		if ( !self is_door() )
		{
			reach_layer_spawn_event( is_last_layer );
		}
	}

	self notify( "drill_complete" );
	level.drill notify( "drill_complete" );
	level.encounter_name = undefined;
	
	flag_clear( "drill_drilling" );
	flag_set( "drill_detonated" );
	//clear any repair progress bars leftover on the players
	foreach ( player in level.players )
	{
		//ignore players who are in the process of reviving
		if ( !isAlive ( player ) || is_true ( player.isReviving ) || is_true( player.being_revived ) )
			continue;
		
		player SetClientOmnvar( "ui_securing_progress",0 );
   	 	player SetClientOmnvar( "ui_securing",0);
	}
	SetOmnvar( "ui_alien_drill_state", 0 );
}

reach_layer_earthquake()
{
	earthquake_intensity = 0.4;
	warn_delay = 1.75;
		
	if ( self is_door() )
	{
		earthquake_intensity = 0.15;
	}
	
	thread maps\mp\alien\_hive::warn_all_players( warn_delay, earthquake_intensity );
}

reach_layer_spawn_event( is_last_layer )
{
	if ( is_last_layer )
		return;
	
	notify_msg = "reached_layer_" + self.layer_completed;
	
	//TODO: re-enable when table tweaked
	maps\mp\alien\_spawn_director::activate_spawn_event( notify_msg );
		
/#
	if ( GetDvarInt( "alien_debug_director" ) > 0 )
		IPrintLnBold( "activate_spawn_event: " + notify_msg );
#/
}

init_drilling_parameters()
{
	if ( self is_door() )
	{
		//layers_info 		 = level.cycle_data.cycle_drill_layers[level.current_cycle_num + 1];
		self.depth 			 = 30;//layers_info[ layers_info.size - 1 ];  // last entry in the layers
		self.total_depth     = self.depth;   // .depth changes as we drill, total_depth never changes
		self.layer_completed = 0;
		
		self.layers[0]       = 0;
		
		// Send the table line info to LUA
		SetOmnvar( "ui_alien_drill_layers_table_line", ( 599 + level.current_cycle_num + 1 ) );
		SetOmnvar( "ui_alien_drill_layer_completed", self.layer_completed );
	}
	else 
	{
		// init depths and layers
		layers_info 		 = level.cycle_data.cycle_drill_layers[level.current_cycle_num + 1];
		self.depth 			 = layers_info[ layers_info.size - 1 ];  // last entry in the layers
		self.total_depth     = self.depth;   // .depth changes as we drill, total_depth never changes
		self.layer_completed = 0;
		
		self.layers[0]       = 0;
		for ( i = 0; i <= layers_info.size - 2; i++ )
			self.layers[ self.layers.size ] = layers_info[ i ];
		
		// Send the table line info to LUA
		SetOmnvar( "ui_alien_drill_layers_table_line", ( 599 + level.current_cycle_num + 1 ) );
		SetOmnvar( "ui_alien_drill_layer_completed", self.layer_completed );
	}
}

set_drill_state_offline()
{
	// self is stronghold_loc struct
	self endon( "death" );
	self endon( "stop_listening" );

	level.drill.state = "offline";
	//level.drill notify( "offline" ); // already notified by damage monitor
	
	// delete flare fx
	if ( Isdefined( level.drill.fxEnt) )
		level.drill.fxEnt Delete();

	if ( Isdefined( level.drill.fxLaserEnt) )
		level.drill.fxLaserEnt Delete();
	
	if( is_door())
	{
		level notify( "drill_stop_door_fx" );
	}

	// stop sfx loop
	thread sfx_drill_offline();
	
	// mark time
	depth_delta = ( gettime() - self.depth_marker )/1000;
	self.depth = max( 0, self.depth - depth_delta );

	// plays non operate anim
	level.drill ScriptModelPlayAnim( "alien_drill_operate_end" );
	wait 1.4;
	level.drill ScriptModelPlayAnim( "alien_drill_nonoperate" );
	
	level.drill MakeUsable();
	level.drill SetCursorHint( "HINT_ACTIVATE" );	
	level.drill SetHintString( &"ALIEN_COLLECTIBLES_PLANT_BOMB" );
	
	level.drill setCanDamage( false );
	level.drill FreeEntitySentient();
	
	// rid the defend icon
	self maps\mp\alien\_hive::destroy_hive_icon();
	
	// set drill icon to signal player for reactivation
	level.drill set_drill_icon();
	
	// Make drill meter stop
	SetOmnvar( "ui_alien_drill_state", 2 );
}

handle_bomb_damage()
{
	// self is stronghold_loc struct
	self endon( "death" );
	self endon( "stop_listening" );
	level endon( "hives_cleared" );
	
	level.drill endon( "death" ); 
	level.drill endon( "offline" ); // no need to monitor damages if offline
	
	//setting this to 0 since it conflicts with the delay in the vo script itself
	DRILL_HEALTH_VO_SPAM_DELAY = 0;
	
	last_damage_time = GetTime();
	level.drill_last_health  = level.drill.health;
	repair_hint1_given = false;
	repair_hint2_given = false;
	repair_hint3_given = false;
	
	while ( 1 )
	{
		level.drill waittill( "damage", amount, attacker, direction_vec, point, meansOfDeath, modelName, tagName, partName, iDFlags, weapon );
		
		if ( isDefined ( attacker ) && isAi( attacker ) )
			{
			level.drill_last_health = level.drill_last_health - amount;
		}
		else if ( isDefined ( weapon ) && weapon == "alien_minion_explosion" )
		{
			level.drill_last_health = level.drill_last_health - amount;
		}
		else 
		{
			 level.drill.health = level.drill_last_health;
			continue;
		}
		
		if ( IsDefined( level.level_drill_damage_adjust_function ))
			[[ level.level_drill_damage_adjust_function ]]( amount, attacker, weapon );
		
		level.drill.health = level.drill_last_health;
		
/#
		if ( GetDvarInt( "scr_debugdrilldamage", 0 ) == 1 )
		{
			if ( !isdefined( meansOfDeath ) )
				meansOfDeath = "MOD_NONE";
			
			if ( !isDefined( weapon ) )
				weapon = "weapon_none";
			
			if ( !isDefined( attacker ) )
				atkr = "no_atkr";
			else if ( isDefined( attacker ) && isDefined( attacker.model ) )
				atkr = attacker.model;
			else
				atkr = "no_model";
			
			println( "Drill damaged. MOD: " + meansOfDeath + " Wpn: " + weapon + " atkr: " + atkr + " dmg: " + amount + " remain: " + level.drill.health );
		}
#/

		//PlayFxOnTag( level._effect[ "bomb_impact" ], level.drill, "tag_origin" );
		
		maps\mp\alien\_gamescore::update_team_encounter_performance( maps\mp\alien\_gamescore::get_drill_score_component_name(), "drill_damage_taken", amount );
		
		maps\mp\alien\_alien_matchdata::inc_drill_heli_damages( amount );
		

		// Play alien hit sound for DLC4 conduits [IWSIX-186485]
		//if( IsDefined( attacker.team ) && attacker.team == "allies" )
		if( level.script == "mp_alien_last" )
		{
			if( isDefined( attacker ) && (( !IsDefined( attacker.team ) || attacker.team == "axis" )))
			{
				//level notify("dlc_vo_notify", "conduit_attack");
				self PlaySound("scn_dscnt_alien_pod_hit");
			}
		}

		if ( level.drill.health < CONST_HEALTH_INVULNERABLE )
		{
			maps\mp\alien\_hud::update_drill_health( 0 );
			// offline
			level.drill notify( "offline", attacker, amount ); // this call ends this thread! aka return;
		}
		else
		{
			if ( !isdefined( self.icon ) )
			{
				continue;
			}
			
			// color scales to red when health is low
			health_ratio 	= ( level.drill.health - CONST_HEALTH_INVULNERABLE ) / CONST_DRILL_HEALTH;
			health_ratio 	= max( 0, min( 1, health_ratio ) );
			health_ratio_sqr= health_ratio * health_ratio; // shows red earlier
			green 			= health_ratio_sqr;
			blue 			= green;
			self.icon.color = ( 1, green, blue );
			
			if ( use_alternate_drill() )
			{
				hardcore_ratio = ( level.drill.health - CONST_HEALTH_INVULNERABLE ) / level.drill_health_hardcore;
				update_drill_health_HUD();
				//maps\mp\alien\_hud::update_drill_health( int( hardcore_ratio * 100 ) );
				if ( hardcore_ratio <= 0.75 && !repair_hint1_given )
				{
					if ( isDefined( level.drill_repair_hint ) )
						IPrintLnBold ( level.drill_repair_hint );
					else 
						iprintlnbold( &"ALIEN_COLLECTIBLES_DRILL_REPAIR_HINT" );
					
					repair_hint1_given = true;
				}
				else if ( hardcore_ratio <= 0.5 && !repair_hint2_given )
				{
					if ( isDefined( level.drill_repair_hint ) )
						IPrintLnBold ( level.drill_repair_hint );
					else
						iprintlnbold( &"ALIEN_COLLECTIBLES_DRILL_REPAIR_HINT" );
					
					repair_hint2_given = true;
				}
				else if ( hardcore_ratio <= 0.25 && !repair_hint3_given)
				{
					if ( isDefined( level.drill_repair_hint_urgent ) )
						IPrintLnBold ( level.drill_repair_hint_urgent );
					else
						IPrintLnbold( &"ALIEN_COLLECTIBLES_REACT_DRILL" );
					
					repair_hint3_given = true;
				}
				
				if ( hardcore_ratio <= 0.25 )
					self thread sfx_overheat();
				
				if ( hardcore_ratio < 0.5 && ( GetTime() - last_damage_time > DRILL_HEALTH_VO_SPAM_DELAY ) )
					level thread maps\mp\alien\_music_and_dialog::playVOforDrillHot();
				else if ( GetTime() - last_damage_time > DRILL_HEALTH_VO_SPAM_DELAY ) 
					level thread maps\mp\alien\_music_and_dialog::playVOForDrillDamaged();
				
				last_damage_time = GetTime();
				
			}
		}
	}
}

sfx_overheat()
{
	if ( !is_door() && !is_door_hive() && level.script != "mp_alien_dlc3")
		level.drill_sfx_lp StopLoopSound( "alien_laser_drill_lp" );
						
	if (!IsDefined(level.drill_overheat_lp_02))
	{
		level.drill_overheat_lp_02 = Spawn( "script_origin", level.drill.origin );
		level.drill_overheat_lp_02 LinkTo(level.drill);

		// Turn off the normal loop, and play the damaged loop
		if( level.script == "mp_alien_last" )
		{
			level.drill_sfx_lp StopLoopSound( "alien_conduit_on_lp" );
			level.drill_overheat_lp_02 PlayLoopSound( "alien_conduit_damaged_lp" );
			return;
		}
	}

	// FIXME: These should probably be moved up into the above if, but I dont want to modify previous levels
	if ( level.script == "mp_alien_dlc3" ) 
		level.drill_overheat_lp_02 PlayLoopSound( "alien_drill_scanner_overheat_lp" );
	else
		level.drill_overheat_lp_02 PlayLoopSound( "alien_laser_drill_overheat_lp" );
}

drill_detonate()
{
	if ( isDefined( level.drill_detonate_override ) )
	{
		self thread [[level.drill_detonate_override]]();
		return;
	}
	// rid hive icon if active
	self maps\mp\alien\_hive::destroy_hive_icon();

	self MakeUnusable();
	self SetHintString( "" );
	
	// to stop monitoring of drill layers
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::remove_from_outline_drill_watch_list ( level.drill );	

	if ( !is_door() && !is_door_hive() ) //only play the death FX for normal hives
	{
		// Stop SFX
		thread sfx_drill_off(false);
		// final kill sequence
		self thread kill_sequence();
	}
		
	// delete flare fx
	if ( Isdefined( level.drill.fxEnt) )
		level.drill.fxEnt Delete();
	// delete laser fx
	if ( Isdefined( level.drill.fxLaserEnt) )
		level.drill.fxLaserEnt Delete();
	
	if( is_door())
	{
		level notify( "drill_stop_door_fx" );
	}
	
	// plays non operate anim
	level.drill ScriptModelClearAnim();
	
	if( !is_door())
	{
		level.drill ScriptModelPlayAnim( "alien_drill_end" );
		wait 3.8;
	}
	
	if ( !isdefined( self.last_hive ) || !self.last_hive )
	{
		org = level.drill.origin + ( 0, 0, 8 ); // this is the make sure drill trace starts above the ground
		drop_drill( org, self.angles - ( 0, 90, 0 ) ); // rotation offset because static model is not the same orientation as the animated model... why?
	}
	
	if ( is_door() || is_door_hive() )
	{
		self delaythread( 3,::open_door );
	}
	else 
		self thread maps\mp\alien\_hive::delete_removables();
	
	self thread remove_spawner();
	self thread fx_ents_playfx();
	
	self maps\mp\alien\_hive::show_dead_hive_model();
	
	self thread do_radius_damage(); // To clean up any items stuck on top of hive
	
	// drill self destruct if last hive
	if ( isdefined( self.last_hive ) && self.last_hive )
	{
		flag_set( "hives_cleared" );
		level thread detonate_drill_when_nuke_goes_off( self );
	}
	
	flag_clear( "drill_detonated" );
	wait 8;		
	level thread maps\mp\alien\_music_and_dialog::playVOForBombDetonate( self );
}

do_radius_damage()
{
	HIVE_EXPLODE_DAMAGE_RADIUS = 300;

	foreach ( scriptable in self.scriptables )
	{
		RadiusDamage( scriptable.origin, HIVE_EXPLODE_DAMAGE_RADIUS, 0, 0, scriptable );
		waitframe();
	}
}

detonate_drill_when_nuke_goes_off( hive )
{
	if ( isdefined( level.drill ) )
	{
		level.drill setCanDamage( false );
		level.drill FreeEntitySentient();
		level.drill MakeUnusable();
	}
	
	level waittill( "nuke_went_off" );
	wait 1.5; // padding
	
	// drill destroyed fx
	destroyed_fx = level._effect[ "stronghold_explode_med" ];
	fx_loc = hive.origin;
	if ( isdefined( level.drill ) )
		fx_loc = level.drill.origin;
	
	playfx( destroyed_fx, fx_loc );
	
	if ( isdefined( level.drill ) )
	{
		level.drill_carrier = undefined;
		level.drill delete();
	}
}

kill_sequence()
{
	PlayFX( level._effect[ "stronghold_explode_large" ], self.origin );
	if (!is_door())
	{
		self thread maps\mp\alien\_hive::sfx_destroy_hive();
	}
	
	if ( isAlive( level.drill ) )
	{		
		foreach ( scriptable in self.scriptables )
		{
			scriptable thread maps\mp\alien\_hive::hive_explode(1);
			waitframe();
		}
	}
}


createUseEnt()
{
	useEnt = Spawn( "script_origin", self.origin );
	useEnt.curProgress = 0;
	useEnt.useTime = 0;
	useEnt.useRate = 1;
	useEnt.inUse = false;
	useEnt thread deleteUseEnt( self );
	return useEnt;
}

deleteUseEnt( owner )
{
	self endon ( "death" );
	owner waittill( "death" );
	self delete();
}

cancel_repair_on_hive_death( player )
{
	player endon( "disconnect" );
	
	self notify ( "cancel_repair_on_hive_death" );
	self endon( "cancel_repair_on_hive_death" );	
	level endon ( "drill_repaired" );

	self waittill( "drill_complete" );
	
	
	if ( isAlive( player ) )
    {
		player notify( "drill_repair_weapon_management" );
		
		if ( player.disabledWeapon > 0 )
			player _enableWeapon();
		
		if ( is_true ( 	player.hasprogressbar ) )
				player.hasprogressbar = false;
		
		player.isRepairing = false;
    }
	
}

DRILL_USE_DISTANCE = 18496; // 136*136
useHoldThink( player, useTime ) 
{
//	if ( IsPlayer( player ) )
//		player playerLinkTo( self );
//	else
//		player LinkTo( self );
//	player playerLinkedOffsetEnable();
    
	self thread cancel_repair_on_hive_death( player );
	
    self.curProgress = 0;
    self.inUse = true;
    self.useRate = 1;
    
	if ( IsDefined( useTime ) )
		self.useTime = useTime;
	else
		self.useTime = 3000;
	
	//player _disableWeapon();
	
	if( !player maps\mp\alien\_perk_utility::has_perk( "perk_rigger", [ 0,1,2,3,4 ] ) )
		player disable_weapon_timeout( ( useTime + 0.05 ), "drill_repair_weapon_management" );
    
	player thread personalUseBar( self );
	
   	player.hasprogressbar = true;
   	
	result = useHoldThinkLoop( player, self, DRILL_USE_DISTANCE );
		
	assert ( IsDefined( result ) );

    if ( isAlive( player ) )
    {
    	player.hasprogressbar = false;
	    if( !player maps\mp\alien\_perk_utility::has_perk( "perk_rigger", [ 0,1,2,3,4 ] ) )	
	   		player enable_weapon_wrapper( "drill_repair_weapon_management" );
    }
    
    if ( !IsDefined( self ) )
    	return false;

    self.inUse = false;
	self.curProgress = 0;

	return ( result );
}

personalUseBar( object )
{
	UI_DRILL_REPAIR = 2;
	if ( level.script == "mp_alien_last" )
		UI_DRILL_REPAIR = 7; //indexes defined & explained in AlienCapturingHud.lua
	
    self endon( "disconnect" );    
	self SetClientOmnvar( "ui_securing",UI_DRILL_REPAIR );
	
    lastRate = -1;
    while ( isReallyAlive( self ) && IsDefined( object ) && object.inUse && !level.gameEnded )
    {
        if ( lastRate != object.useRate )
        {
            if( object.curProgress > object.useTime)
                object.curProgress = object.useTime;
        } 
        
        lastRate = object.useRate;
        self SetClientOmnvar( "ui_securing_progress",object.curProgress / object.useTime );
        wait ( 0.05 );
    }
    
    self SetClientOmnvar( "ui_securing_progress",0 );
    self SetClientOmnvar( "ui_securing",0);
}

useHoldThinkLoop( player,ent, dist_check )
{
	while( !level.gameEnded && IsDefined( self ) && isReallyAlive( player ) && player useButtonPressed() && ( !isdefined( player.lastStand ) || !player.lastStand ) && self.curProgress < self.useTime )
    {
		drill_health = ( self.health - CONST_HEALTH_INVULNERABLE ) / level.drill_health_hardcore;
		if ( drill_health <= 0 )
			return false;
		
		if ( isDefined ( ent ) && isDefined ( dist_check) )
		{
			if ( distancesquared ( player.origin,ent.origin ) > dist_check )
			{
				return false;
			}
		}
        self.curProgress += (50 * self.useRate);
		self.useRate = 1;

        if ( self.curProgress >= self.useTime )
            return ( isReallyAlive( player ) );
       
        wait 0.05;
    } 
    
    return false;
}


// ================= utilities ==================

draw_line( from, to, color, frames )
{
	//level endon( "helicopter_done" );
	if( isdefined( frames ) )
	{
		for( i=0; i<frames; i++ )
		{
			line( from, to, color );
			wait 0.05;
		}		
	}
	else
	{
		for( ;; )
		{
			line( from, to, color );
			wait 0.05;
		}
	}
}

angles_to_ground( pos, ang, offset )
{
	start = pos + ( 0, 0, 16 );
	end = pos - ( 0, 0, 64 );
	trace = BulletTrace( start, end, false, self );
	trace_vec = trace[ "normal" ] * ( -1 ); // face up
	
	trace_angles = VectorToAngles( trace_vec );
	angle_delta = VectorToAngles( AnglesToUp( trace_angles ) )[ 1 ] - VectorToAngles( AnglesToForward( ang ) )[ 1 ];
	
	// rotate around entity's local Z axis
	up 		= VectorNormalize( trace_vec );
	forward = VectorNormalize( AnglesToUp( VectorToAngles( trace_vec ) ) );
	right	= VectorNormalize( AnglesToRight( VectorToAngles( trace_vec ) ) );
	forward = RotatePointAroundVector( up, forward, angle_delta - 90 ); // -90 for the drill
	right	= RotatePointAroundVector( up, right, angle_delta - 90 );
	
	/*
	/#
	thread draw_line( pos, pos + forward*32, (1,0,0), 20000 );
	thread draw_line( pos, pos + right*32, (0,1,0), 20000 );
	#/
	*/
		
	self.angles = AxisToAngles( forward, right, up );
	if ( abs ( self.angles[2] ) > 45 )
	{
		self.angles = ( self.angles[0], self.angles[1], 0 );
	}
	if ( abs ( self.angles[0] ) > 45 )
	{
		self.angles = ( 0, self.angles[1], self.angles[2] );
	}
	
	
	self.origin = pos + offset;
}

//==============================================================================
//		Bomb viewmodel carry and replace weapons when bomb is planted or dropped
//==============================================================================
//
watchBomb()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	
	// remove bomb on player spawn, no way they can spawn with one by default currently
	if ( self hasweapon( "alienbomb_mp" ) )
	{
		self TakeWeapon( "alienbomb_mp" );
		self EnableWeaponSwitch();
	}
		
	while ( 1 )
	{
		self waittill( "grenade_fire", alienbomb, weapname );
		if ( weapname == "alienbomb" || weapname == "alienbomb_mp" )
		{
			alienbomb.owner = self;
			alienbomb SetOtherEnt(self);
			alienbomb.team = self.team;

			alienbomb thread watchBombStuck( self );

		}
	}
}

//Watcher for the dropped bomb to stick then spawns a new script_model bomb at the location of the dropped bomb
watchBombStuck( owner ) 
{
	// self == alienbomb projectile
	level endon( "game_ended" );
	//self endon( "death" ); // if deleted or died
	
	owner endon( "death" );
	owner endon( "disconnect" );
	
	self Hide();
	self waittill_any_timeout( .05, "missile_stuck" );
	
	//try to put it on the ground
	//secTrace = bulletTrace( owner.origin + (0,0,8 ) , owner.origin - (0, 0, 16 ), false, self , true ,false, true );
	secTrace = self AIPhysicsTrace ( owner.origin + ( 0,0,8 ),owner.origin - ( 0,0,12 ),undefined,undefined,true,true );
	if( secTrace["fraction"] == 1 )
	{
		owner TakeWeapon( "alienbomb_mp" );
		owner GiveWeapon( "alienbomb_mp" );
		// there's nothing under us so don't place the drill up in the air
		owner SetWeaponAmmoStock( "alienbomb_mp", owner GetWeaponAmmoStock( "alienbomb_mp" ) + 1 );
		owner SwitchToWeapon( "alienbomb_mp" );
		self delete();
		return;
	}
	else
	{
		self.origin = secTrace["position"];
		parent = secTrace["entity"];
	}
	
	self.angles *= (0,1,1);
	//self.origin = self.origin;
	level notify( "drill_dropping" );
		
	// auto plant if dropped close to target
	foreach ( destroy_loc in level.stronghold_hive_locs )
	{
		if ( destroy_loc maps\mp\alien\_hive::is_blocker_hive() )
			continue;
		
		if ( !destroy_loc maps\mp\alien\_hive::dependent_hives_removed() )
			continue;
		
		if ( distance( destroy_loc.origin, self.origin ) < 80 )
		{
			// auto plant
			destroy_loc notify( "trigger", owner );
			Earthquake( .25,.5,self.origin,128 );
			owner TakeWeapon( "alienbomb_mp" );
			if ( !owner has_special_weapon() )
				owner EnableWeaponSwitch();
			
			owner restore_last_weapon();
			owner _enableOffhandWeapons();
			
			self delete();
			return;
		}
	}
	
	if ( isDefined( level.watch_bomb_stuck_override ) ) //for checking when the drill is dropped near *other* things that may not be a hive struct ( like the platform bot in Beacon )
	{
		if ( [[level.watch_bomb_stuck_override]]( owner ) )
			return;
	}
				   
	drop_drill( self.origin, self.angles, self );	
	Earthquake( .25,.5,self.origin,128 );

	owner TakeWeapon( "alienbomb_mp" );
	if ( !owner has_special_weapon() )
		owner EnableWeaponSwitch();
	
	owner restore_last_weapon();
	owner _enableOffhandWeapons();
	
	level thread maps\mp\alien\_outline_proto::update_drill_outline();
	
	self delete();	

}

restore_last_weapon()
{
	if ( self.lastweapon != "aliendeployable_crate_marker_mp" )
		self SwitchToWeapon( self.lastweapon );
	else 
		self SwitchToWeapon ( self GetWeaponsListPrimaries()[0] );
}

//=======================================================
//		HUD - Icons
//=======================================================

// player bomb carry init on player spawn - No longer used  TODO : Remove this
player_carry_bomb_init()
{
	// self is player
	if ( !isdefined( self.carryIcon ) )
	{
		if ( level.splitscreen )
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 33, 33 );
			self.carryIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -50, -78 );
		}
		else
		{
			self.carryIcon = createIcon( "hud_suitcase_bomb", 50, 50 );
			self.carryIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -50, -65 );
		}
		
		self.carryIcon.hidewheninmenu = true;
		self thread hideCarryIconOnGameEnd();
	}
	
	self.carryIcon.alpha = 0;
}

hideCarryIconOnGameEnd()
{
	self endon( "disconnect" );
	
	level waittill( "game_ended" );
	
	if ( isDefined( self.carryIcon ) )
		self.carryIcon.alpha = 0;
}

set_drill_icon( link )
{
	level notify( "new_bomb_icon" );
	
	// destroy in case we used to link
	destroy_drill_icon( self );
	
	if ( !isDefined ( link ) || !link )
	{	
		level.drill_icon = NewHudElem();
		level.drill_icon SetShader( "waypoint_alien_drill", 14, 14 );
		level.drill_icon.color = ( 1, 1, 1 );
		level.drill_icon SetWayPoint( true, true );
		level.drill_icon.sort = 1;
		level.drill_icon.foreground = true;
		level.drill_icon.alpha = 0.5;
		level.drill_icon.x = self.origin[ 0 ];
		level.drill_icon.y = self.origin[ 1 ];
		level.drill_icon.z = self.origin[ 2 ] + 72;
	}	
	else
	{		
		self maps\mp\_entityheadIcons::setHeadIcon( self.team, "waypoint_alien_drill", (0,0,72), 4, 4, undefined, undefined, undefined, true, undefined, false );
	}
}

destroy_drill_icon( ent )
{
	if ( isdefined( level.drill_icon ) )
		level.drill_icon Destroy();
	
	if ( !isDefined ( ent ) )
		return;
	
	remove_headicons_from_players();	
}

remove_headicons_from_players()
{
	foreach ( player in level.players )
	{
		if ( isDefined ( player.entityHeadIcons ) )
		{
			foreach ( key, headIcon in player.entityHeadIcons ) //remove any head icons
			{	
				// TODO: remove and fix properly after ship
				if( !isDefined(headIcon) ) //needed for FFA host migration (when host has active head icons)
					continue;
				
				headIcon destroy();
			}
		}
	}
	
}

//=======================================================
//		Helpers
//=======================================================

remove_spawner()
{
	if ( IsDefined( self.script_linkto ) )
		maps\mp\alien\_spawn_director::remove_spawn_location( self.script_linkto );
}

fx_ents_playfx()
{
	// self is stronghold_loc script model
	assert( isdefined( self.fx_ents ) );
	
	foreach ( fx_ent in self.fx_ents )
	{
		playfx( level._effect[ "stronghold_explode_med" ], fx_ent.origin );
		fx_ent delete();
	}
}

//=======================================================
//		Audio
//=======================================================
sfx_drill_plant()
{
	drill = get_drill_entity();
	//wait 0.1;
	drill PlaySound( "alien_laser_drill_plant" );
}

sfx_drill_on(door)
{
	wait 0.1;

	drill = get_drill_entity();
	
	if (!IsDefined(level.drill_sfx_lp))
	{
		level.drill_sfx_lp = Spawn( "script_origin", drill.origin );
		level.drill_sfx_lp LinkTo(drill);
	}
	
	if (!IsDefined(level.drill_sfx_dist_lp))
	{
		level.drill_sfx_dist_lp = Spawn( "script_origin", drill.origin );
		level.drill_sfx_dist_lp LinkTo( drill );
	}

	wait 0.1;
	
	if (door)
	{
		wait 3.76;
		//IPrintLnBold("Drilling a door");
		if ( isDefined ( level.drill_sfx_lp ) )
			level.drill_sfx_lp PlayLoopSound("alien_laser_drill_door_lp");
		
		if ( isDefined ( level.drill_sfx_dist_lp ) )
			level.drill_sfx_dist_lp PlayLoopSound("alien_laser_drill_door_dist_lp");
	}
	else
	{
		//IPrintLnBold("Drilling a hive");
		if ( isDefined ( level.drill_sfx_lp ) )
			level.drill_sfx_lp PlayLoopSound("alien_laser_drill_lp");
		
		if ( isDefined ( level.drill_sfx_dist_lp ) )
			level.drill_sfx_dist_lp PlayLoopSound("alien_laser_drill_dist_lp");
	}
}

sfx_drill_off(door)
{
	drill = get_drill_entity();
	coord = drill.origin;
	
	if (!door)
		drill PlaySound("alien_laser_drill_stop");
	else
		playSoundAtPos( coord, "alien_laser_drill_stop");
	
	if (IsDefined(level.drill_sfx_lp))
		level.drill_sfx_lp delete();
	
	if (IsDefined(level.drill_sfx_dist_lp))
		level.drill_sfx_dist_lp delete();
	
	if (IsDefined(level.drill_overheat_lp))
		level.drill_overheat_lp delete();

	if (IsDefined(level.drill_overheat_lp_02))
		level.drill_overheat_lp_02 delete();
	
	if (door)
	{
		wait 2.7;
		playSoundAtPos( coord, "alien_laser_drill_door_open");
	}
}

sfx_drill_offline()
{
	drill = get_drill_entity();	
	
	if ( level.script == "mp_alien_dlc3" )
		level.drill PlaySound("alien_drill_scanner_shutdown");
	else
		drill PlaySound("alien_laser_drill_shutdown");
	
	if (IsDefined(level.drill_sfx_lp))
		level.drill_sfx_lp delete();
	
	if (IsDefined(level.drill_sfx_dist_lp))
		level.drill_sfx_dist_lp delete();
		
	if (IsDefined(level.drill_overheat_lp_02))
		level.drill_overheat_lp_02 delete();
}

// ===============================================================================
//							Black box prints for drill
// ===============================================================================

drill_plant_BBprint( player )
{
	// self is hive struct
	self drill_generic_BBPrint( "aliendrillplant", player );
}

drill_reset_BBPrint( player )
{
	// self is hive struct
	self drill_generic_BBPrint( "aliendrillreset", player );
}

drill_generic_BBPrint( BBprint_string, player )
{
	// self is hive struct
	cyclenum = level.current_cycle_num;

	hivename = "unknown hive";
	if ( isdefined( self.target ) )
		hivename = self.target;
	
	playtime = gettime() - level.startTime;
	
	planter = "unknown player";
	if ( isdefined( player.name ) )
		planter = player.name;
	
	playernum 			= level.players.size;
	
	planterperk0 		= player maps\mp\alien\_persistence::get_selected_perk_0();
	planterperk0level 	= player maps\mp\alien\_persistence::get_perk_0_level();
	
	planterperk1 		= player maps\mp\alien\_persistence::get_selected_perk_1();
	planterperk1level 	= player maps\mp\alien\_persistence::get_perk_1_level();
	
	healthratio = -1;
	if ( isdefined( level.drill ) && isdefined( level.drill.health ) && isdefined( level.drill_health_hardcore ) )
		healthratio  = ( level.drill.health - CONST_HEALTH_INVULNERABLE ) / level.drill_health_hardcore;
	
	/#
	if ( GetDvarInt( "alien_bbprint_debug" ) > 0 )
	{
		IPrintLnBold( "^8bbprint: " + BBprint_string + "\n" +
					 " cyclenum=" + cyclenum +
					 " hivename=" + hivename +
					 " playtime=" + playtime + 
					 " drillhealth=" + healthratio +
					 " repairer=" + planter + 
					 " repairerperk0=" + planterperk0 +
					 " repairerperk1=" + planterperk1 +
					 " repairerperk0level=" + planterperk0level +
					 " repairerperk1level=" + planterperk1level +
					 " playernum=" + playernum );
	}
	#/

	bbprint( BBprint_string,
		    "cyclenum %i hivename %s playtime %f drillhealth %f repairer %s repairerperk0 %s repairerperk1 %s repairerperk0level %s repairerperk1level %s playernum %i ", 
			cyclenum,
			hivename,
			playtime,
			healthratio,
			planter,
			planterperk0,
			planterperk1,
			planterperk0level,
			planterperk1level,
			playernum );
}

check_for_player_near_hive_with_drill()
{
/#
	if ( alien_mode_has( "nogame" ) )
		return;
#/
		
	if ( is_true ( level.automatic_drill ) ) //break out of this if not needed
		return;
	
	self endon( "disconnect" );
	check_distance = 80*80;
	while ( 1 )
	{
		while ( !flag( "drill_drilling" ) )
		{
			if ( ( isDefined ( self.inlaststand ) && self.inlaststand ) || flag ( "drill_drilling" ) || isDefined ( self.usingRemote ) || is_true ( self.isCarrying ) )
			{
				wait ( .05 );
				continue;
			}
			
			foreach ( destroy_loc in level.stronghold_hive_locs )
			{
				if ( destroy_loc maps\mp\alien\_hive::is_blocker_hive() )
					continue;
				
					if ( !destroy_loc maps\mp\alien\_hive::dependent_hives_removed() )
				    continue;
				    
				if ( distancesquared( destroy_loc.origin, self.origin ) < check_distance  )
				{
					if ( ( !isDefined ( level.drill_carrier ) ) || isDefined ( level.drill_carrier ) && level.drill_carrier != self )
					{
						self setLowerMessage( "need_drill",&"ALIEN_COLLECTIBLES_NEED_DRILL",undefined,10 );
						while( player_should_see_drill_hint( destroy_loc,check_distance,true ) )
						{
							wait ( .05 );
						}
						self clearLowerMessage ( "need_drill" );
					}
					else
					{
						self setLowerMessage( "plant_drill",&"ALIEN_COLLECTIBLES_PLANT_BOMB",undefined,10 );
						while( player_should_see_drill_hint( destroy_loc,check_distance,false ) )
						{
							wait ( .05 );
						}
						self clearLowerMessage( "plant_drill" );
					}				
				}
			}
		wait ( .05 );
		}
		
		flag_waitopen( "drill_drilling" );
	}
}

player_should_see_drill_hint( destroy_loc,check_distance, ignore_carrying_check )
{
	if ( distancesquared( destroy_loc.origin, self.origin ) > check_distance )
		return false;
	
	if ( flag ( "drill_drilling" ) )
		return false;
	
	if ( self.inlaststand )
		return false;
	
	if ( isDefined ( self.usingRemote ) )
		return false;
	
	if ( is_true ( ignore_carrying_check ) )
		return true;
	else if ( is_true ( self.isCarrying ) )
		return false;
	
	return true;
}

get_drill_entity()
{

	if ( isDefined( level.drill.vehicle ) )
		 return level.drill.vehicle;
	else
		return level.drill;
}

open_door()
{
	level notify( "door_opening" , self.target );
	foreach ( ent in self.removeables )
	{
		if ( isdefined( ent ) )
		{
			if( ent.classname == "script_model" )
			{
				ent thread slide_open();
			}
			else 
			{
				if( ent.classname == "script_brushmodel" )
				{
					ent ConnectPaths();
				}
				ent delete();
			}
		}
	}
}

slide_open()
{
	if ( !isDefined( self.script_angles ) )
		self delete();
	else 
		self moveto ( self.origin + self.script_angles, 1 );	
}

wait_for_drill_plant()
{
	// self is hive location struct, where we allow planting of drill
	self endon( "stop_listening" );
	
	//self MakeUsable();
	//self SetCursorHint( "HINT_NOICON" );	
	//self SetHintString( "" );
	
	while( true )
	{
		self waittill( "trigger", player );
		
		if ( !is_true ( level.automatic_drill ) && ( !isdefined( level.drill_carrier ) || level.drill_carrier != player ) )
		{
			player setLowerMessage( "no_bomb", &"ALIEN_COLLECTIBLES_NO_BOMB", 5 );
			wait 0.05;
			continue;
		}
		
		if( isPlayer( player ) )
		{
			if( !is_true ( level.automatic_drill ) )
			{
				// clear lower message hint to plant bomb
				player clearLowerMessage( "go_plant" );
				
				// remove the bomb and give the player back his last weapon
				player TakeWeapon( "alienbomb_mp" );
				if ( !player has_special_weapon() )
				{
					player EnableWeaponSwitch();
				}
				
				if(!isdefined(level.non_player_drill_plant_check) || ![[level.non_player_drill_plant_check]]())
				{
					player SwitchToWeapon( player.lastweapon ); 
				}
				
				self MakeUnusable();
				self SetHintString( "" );
				maps\mp\alien\_drill::remove_headicons_from_players();
			}
			
			earthquake_intensity = 0.4;
			warn_delay = 1.75;
			thread maps\mp\alien\_hive::warn_all_players( warn_delay, earthquake_intensity );
			
			// EoG tracking: drill plants
			player maps\mp\alien\_persistence::eog_player_update_stat( "drillplants", 1 );
			
			level notify( "drill_planted", player, self );
			
			return player;
		}
	}
}

update_drill_health_HUD()
{
	drill_health = int( ( level.drill.health - CONST_HEALTH_INVULNERABLE ) / level.drill_health_hardcore * 100 );
	maps\mp\alien\_hud::update_drill_health( drill_health );
}