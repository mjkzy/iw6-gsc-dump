#include common_scripts\utility;
#include maps\mp\_utility;


HEALTH_PACK_MODEL = "paris_chase_pharmacie_sign_02";

player_healthbar_update()
{
	// player HP bar: rewrite with LUI for HUD
	self endon( "death" );
	
	waittillframeend;
	
	while ( true )
	{
		player_health_ratio = self.health / self.maxhealth;
		
		SetDvar( "alien_player_health", self.health / self.maxhealth );

		while ( player_health_ratio == ( self.health / self.maxhealth ) )
			wait 0.1;
		
		// best if regen notifies when health changes
		// self waittill( "damage" );
	}
}

/*
NONPLAYER_MELEE_DAMAGE = 100;

apply_damage( num_bar, source, apply_player_view_rip )
{
	if ( !isPlayer( self ) )
	{
		self DoDamage( NONPLAYER_MELEE_DAMAGE, source.origin, source );
		return;
	}
	
	self.last_alien_melee_time = GetTime();
	self playRumbleOnEntity ( "damage_light" );
	self PlaySound( "player_hit_sfx_alien" );
	self thread play_damage_overlay();
	damage_amount = ceil ( num_bar * level.health_amount_per_health_bar );
	
	if ( IsDefined( self.damagemultiplier ) )
	{
		damage_amount /= self.damagemultiplier;
	}
	enemy_blocked = self check_for_block( source );
	if ( enemy_blocked )
	{
		return;
	}
	else
	{
	self DoDamage( damage_amount, source.origin, source );
	GetDvarInt ( "enable_player_view_rip" );
		if ( GetDvarInt ( "enable_player_view_rip" ) == 1 )
		{
			if ( isDefined ( apply_player_view_rip ) && apply_player_view_rip == true )
			{
				source thread player_view_rip( self );
			}
		}
	}
}

check_for_block( source )
{
	enemy_blocked = false;
	currentweapon = self GetcurrentWeapon();
	player_is_ADS = isADS();
	enemy_in_front = false;
	melee_in_hand = false;
	melee_weapon_health = 0;
	playerForwardVector = anglesToForward( self.angles );
    playerToEnemyVector = VectorNormalize( source.origin - self.origin );
    dotProduct = VectorDot( playerToEnemyVector, playerForwardVector );
    if ( dotProduct > 0.5 )
    {
        enemy_in_front = true;
    }
    
    if ( currentweapon == "axe_alien" )
	{
		melee_weapon_health = self GetCurrentWeaponClipAmmo();
		melee_in_hand = true;
	}
    
    if ( melee_in_hand && player_is_ADS && enemy_in_front && ( melee_weapon_health > 0 ) )
	{
    	self SetWeaponAmmoClip( "axe_alien", ( melee_weapon_health - 1 ));
		self PlaySound( "crate_impact" );
    	Earthquake( 0.75,0.5,self.origin, 100 );
    	enemy_blocked = true;
    	if ( self GetCurrentWeaponClipAmmo() == 0 )
    	{
    		self TakeWeapon( currentweapon );
    		weapon_list = self GetWeaponsList( "primary" );
    		if ( weapon_list.size > 0 )
    		{
    			self SwitchToWeapon( weapon_list[0] );
    		}
		}
  	}
   	return enemy_blocked;
}

play_damage_overlay()
{
	self endon ( "death" );
	
	self.combatDamageOverlay.alpha = 1;
	self.combatDamageOverlay fadeOverTime( 0.5 );
	self.combatDamageOverlay.alpha = 0;	
}

player_view_rip( enemy )
{
	enemy endon ( "death" );
	enemy notify ( "kill previous player view rip" ); 
	enemy endon ( "kill previous player view rip" );
	
	AssertEx ( isPlayer ( enemy ), "Invalid player" );
	
	if ( !isAlive ( enemy ) )
	{
		return;
	}
	
	//These two values are assumed alien speed and the amount of time which the alien will take to land.  They are used to
	//determine roughly the landing location of the alien
	alien_speed = 200;
	time_after_melee = 1.5;
	
	alien_forward_vector = AnglesToForward ( self.angles );
	alien_position_after_melee = self.origin + alien_forward_vector * alien_speed * time_after_melee;
	//level thread draw_debugLine ( self.origin, alien_position_after_melee, ( 1, 0, 0), 3600 );
	
	player_to_alien_pos_vector = alien_position_after_melee - enemy.origin;
	player_to_alien_pos_yaw = VectorToYaw ( player_to_alien_pos_vector );
	player_forward_yaw = enemy.angles [ 1 ];
	yaw_difference = player_to_alien_pos_yaw - player_forward_yaw;
	yaw_difference = AngleClamp180 ( yaw_difference );
	rip_percent = ( GetDvarFloat ( "percent_player_view_rip" ) ) / 100;
	yaw_difference = yaw_difference * rip_percent;
	
	player_rig = spawn_anim_model( "player_rig", enemy.origin );
	player_rig hide();
	player_rig.angles = player_rig.angles * ( 1, 0, 1 );
	player_yaw = enemy.angles * ( 0, 1, 0 );
	player_rig.angles = player_rig.angles + player_yaw * ( 0, 1, 0 );
	enemy playerlinkto ( player_rig, "tag_origin", 1, 180, 180, 180, 180, true );
	player_rig RotateYaw ( yaw_difference, 0.3, 0, 0 );
	wait ( 0.3 );
	enemy unlink();
	player_rig delete();
}
*/

/*
=============
///ScriptDocBegin
"Name: enable_alien_scripted()"
"Summary: Puts the alien into a scripted state that allows level scripts to set their goals and control them directly"
"Module: Alien"
"CallOn: Alien actor"
"Example: alien enable_alien_scripted()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
enable_alien_scripted()
{
	self.alien_scripted = true;
	self notify( "alien_main_loop_restart" );
}

/*
=============
///ScriptDocBegin
"Name: disable_alien_scripted()"
"Summary: Clears the alien's scripted state"
"Module: Alien"
"CallOn: Alien actor"
"Example: alien disable_alien_scripted()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
disable_alien_scripted()
{
	self.alien_scripted = false;
}


/*
=============
///ScriptDocBegin
"Name: set_alien_emissive()"
"Summary: Sets alien glowiness."
"Module: Alien"
"MandatoryArg: <blend_duration> Duration of the blend to a new intensityvalue."
"MandatoryArg: <intensity> Emissive intensity, 0.0 - 1.0."
"Example: alien set_alien_emissive( 0.2, 1.0 );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
set_alien_emissive( blend_duration, intensity )
{
/#
	if ( GetDvarInt( "scr_useMaxEmissive", 0 ) == 1 )
	{
		self EmissiveBlend( 0.1, 1.0 );
		return;
	}
#/
	// Min and max actual intensity defined per alien type
	valid_range = self.maxEmissive - self.defaultEmissive;
	actual_intensity = intensity * valid_range + self.defaultEmissive;
	self EmissiveBlend( blend_duration, actual_intensity );
}

/*
=============
///ScriptDocBegin
"Name: set_alien_emissive_default()"
"Summary: Sets alien glowiness to default value."
"Module: Alien"
"MandatoryArg: <blend_duration> Duration of the blend to default intensity."
"Example: alien set_alien_emissive_default( 0.2 );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
set_alien_emissive_default( blend_duration )
{
/#
	if ( GetDvarInt( "scr_useMaxEmissive", 0 ) == 1 )
	{
		self EmissiveBlend( 0.1, 1.0 );
		return;
	}
#/	
	assert( IsDefined( self.defaultEmissive ) );
	self EmissiveBlend( blend_duration, self.defaultEmissive );
}

/*
=============
///ScriptDocBegin
"Name: get_players()"
"Summary: Returns connected players. Preparing for MP transition"
"Module: Alien"
"Example: foreach ( player in get_players() ){ ... }"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
get_players()
{
	return level.players;
}

/*
=============
///ScriptDocBegin
"Name: any_player_nearby()"
"Summary: Returns whether any player is within a certain distance."
"Module: Alien"
"MandatoryArg: <origin> The origin from which to check."
"MandatoryArg: <dist_sqr> Square of max distance."
"Example: result = any_player_nearby( self.origin, MAX_DISTANCE )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
any_player_nearby( origin, dist_sqr )
{
	foreach ( player in level.players )
	{
		if ( DistanceSquared( player.origin, origin ) < dist_sqr )
		{
			return true;
		}
	}
	return false;		
}



min_dist_from_all_locations( ent, location_array, min_dist )
{
	min_dist_sqr = min_dist * min_dist;
	foreach ( location in location_array )
	{
		if ( Distance2DSquared( ent.origin, location.origin ) < min_dist_sqr )
		{
			return false;
		}
	}
	
	return true;
}


/*
=============
///ScriptDocBegin
"Name: set_vision_set_player( <visionset> , <transition_time> )"
"Summary: Sets the vision set over time for a specific player in coop"
"Module: Utility"
"MandatoryArg: <visionset>: Visionset file to use"
"OptionalArg: <transition_time>: Time to transition to the new vision set. Defaults to 1 second."
"Example: level.player2 set_vision_set_player( "blackout_darkness", 0.5 );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
set_vision_set_player( visionset, transition_time )
{
	if ( init_vision_set( visionset ) )
		return;

	Assert( IsDefined( self ) );
	Assert( level != self );

	if ( !isdefined( transition_time ) )
		transition_time = 1;
	self VisionSetNakedForPlayer( visionset, transition_time );
}

init_vision_set( visionset )
{
	level.lvl_visionset = visionset;

	if ( !isdefined( level.vision_cheat_enabled ) )
		level.vision_cheat_enabled = false;

	return level.vision_cheat_enabled;
}

restore_client_fog( transition_time )
{
	if ( !isdefined( level.restore_fog_setting ) )
		return;
	
	ent = level.restore_fog_setting;

	self PlayerSetExpFog(
		ent.startDist,
		ent.halfwayDist,
		ent.red,
		ent.green,
		ent.blue,
		ent.HDRColorIntensity,
		ent.maxOpacity,
		transition_time,
		ent.sunRed,
		ent.sunGreen,
		ent.sunBlue,
		ent.HDRSunColorIntensity,
		ent.sunDir,
		ent.sunBeginFadeAngle,
		ent.sunEndFadeAngle,
		ent.normalFogScale,
		ent.skyFogIntensity,
		ent.skyFogMinAngle,
		ent.skyFogMaxAngle );
}

// TEMP: Resides here until flawless, then move to maps\mp\_utility
// Since ent_flag can be called on players who can disconnect, 
// TODO: make sure flag functions end well on player disconnect or game end
// =======================================================================
// 					ENTITY FLAG
// =======================================================================

/*
 =============
///ScriptDocBegin
"Name: ent_flag_wait( <flagname> )"
"Summary: Waits until the specified flag is set on self. Even handles some default flags for ai such as 'goal' and 'damage'"
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname> : name of the flag to wait on"
"Example: enemy ent_flag_wait( "goal" );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag_wait( msg )
{
	if ( isplayer( self ) )
		self endon( "disconnect" );
	
	AssertEx( ( !IsSentient( self ) && IsDefined( self ) ) || IsAlive( self ), "Attempt to check a flag on entity that is not alive or removed" );

	while ( IsDefined( self ) && !self.ent_flag[ msg ] )
		self waittill( msg );
}

 /*
 =============
///ScriptDocBegin
"Name: ent_flag_wait_either( <flagname1> , <flagname2> )"
"Summary: Waits until either of the the specified flags are set on self. Even handles some default flags for ai such as 'goal' and 'damage'"
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname1> : name of one flag to wait on"
"MandatoryArg: <flagname2> : name of the other flag to wait on"
"Example: enemy ent_flag_wait( "goal", "damage" );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag_wait_either( flag1, flag2 )
{
	if ( isplayer( self ) )
		self endon( "disconnect" );
		
	AssertEx( ( !IsSentient( self ) && IsDefined( self ) ) || IsAlive( self ), "Attempt to check a flag on entity that is not alive or removed" );

	while ( IsDefined( self ) )
	{
		if ( ent_flag( flag1 ) )
			return;
		if ( ent_flag( flag2 ) )
			return;

		self waittill_either( flag1, flag2 );
	}
}

 /*
 =============
///ScriptDocBegin
"Name: ent_flag_wait_or_timeout( <flagname> , <timer> )"
"Summary: Waits until either the flag gets set on self or the timer elapses. Even handles some default flags for ai such as 'goal' and 'damage'"
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname1: Name of one flag to wait on"
"MandatoryArg: <timer> : Amount of time to wait before continuing regardless of flag."
"Example: ent_flag_wait_or_timeout( "time_to_go", 3 );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag_wait_or_timeout( flagname, timer )
{
	if ( isplayer( self ) )
		self endon( "disconnect" );
		
	AssertEx( ( !IsSentient( self ) && IsDefined( self ) ) || IsAlive( self ), "Attempt to check a flag on entity that is not alive or removed" );

	start_time = GetTime();
	while ( IsDefined( self ) )
	{
		if ( self.ent_flag[ flagname ] )
			break;

		if ( GetTime() >= start_time + timer * 1000 )
			break;

		self ent_wait_for_flag_or_time_elapses( flagname, timer );
	}
}

ent_wait_for_flag_or_time_elapses( flagname, timer )
{
	self endon( flagname );
	wait( timer );
}

/*
=============
///ScriptDocBegin
"Name: ent_flag_waitopen( <msg> )"
"Summary: "
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <param1>: "
"OptionalArg: <param2>: "
"Example: "
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
ent_flag_waitopen( msg )
{
	AssertEx( ( !IsSentient( self ) && IsDefined( self ) ) || IsAlive( self ), "Attempt to check a flag on entity that is not alive or removed" );

	while ( IsDefined( self ) && self.ent_flag[ msg ] )
		self waittill( msg );
}

ent_flag_assert( msg )
{
	AssertEx( !self ent_flag( msg ), "Flag " + msg + " set too soon on entity" );
}


 /*
 =============
///ScriptDocBegin
"Name: ent_flag_waitopen_either( <flagname1> , <flagname2> )"
"Summary: Waits until either of the the specified flags are open on self. Even handles some default flags for ai such as 'goal' and 'damage'"
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname1> : name of one flag to waitopen on"
"MandatoryArg: <flagname2> : name of the other flag to waitopen on"
"Example: enemy ent_flag_waitopen_either( "goal", "damage" );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag_waitopen_either( flag1, flag2 )
{
	AssertEx( ( !IsSentient( self ) && IsDefined( self ) ) || IsAlive( self ), "Attempt to check a flag on entity that is not alive or removed" );

	while ( IsDefined( self ) )
	{
		if ( !ent_flag( flag1 ) )
			return;
		if ( !ent_flag( flag2 ) )
			return;

		self waittill_either( flag1, flag2 );
	}
}

 /*
 =============
///ScriptDocBegin
"Name: ent_flag_init( <flagname> )"
"Summary: Initialize a flag to be used. All flags must be initialized before using ent_flag_set or ent_flag_wait.  Some flags for ai are set by default such as 'goal', 'death', and 'damage'"
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname> : name of the flag to create"
"Example: enemy ent_flag_init( "hq_cleared" );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag_init( message )
{
	if ( !isDefined( self.ent_flag ) )
	{
		self.ent_flag = [];
		self.ent_flags_lock = [];
	}

	/#
	if ( IsDefined( level.first_frame ) && level.first_frame == -1 )
		AssertEx( !isDefined( self.ent_flag[ message ] ), "Attempt to reinitialize existing message: " + message + " on entity." );
	#/

	self.ent_flag[ message ] = false;
/#
	self.ent_flags_lock[ message ] = false;
#/
}

 /*
 =============
///ScriptDocBegin
"Name: ent_flag_exist( <flagname> )"
"Summary: checks to see if a flag exists"
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname> : name of the flag to check"
"Example: if( enemy ent_flag_exist( "hq_cleared" ) );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag_exist( message )
{
	if ( IsDefined( self.ent_flag ) && IsDefined( self.ent_flag[ message ] ) )
		return true;
	return false;
}

 /*
 =============
///ScriptDocBegin
"Name: ent_flag_set( <flagname> )"
"Summary: Sets the specified flag on self, all scripts using ent_flag_wait on self will now continue."
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname> : name of the flag to set"
"Example: enemy ent_flag_set( "hq_cleared" );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag_set( message )
{
/#
 	AssertEx( IsDefined( self ), "Attempt to set a flag on entity that is not defined" );
	AssertEx( IsDefined( self.ent_flag[ message ] ), "Attempt to set a flag before calling flag_init: " + message + " on entity." );
	Assert( self.ent_flag[ message ] == self.ent_flags_lock[ message ] );
	self.ent_flags_lock[ message ] = true;
#/
	self.ent_flag[ message ] = true;
	self notify( message );
}

 /*
 =============
///ScriptDocBegin
"Name: ent_flag_clear( <flagname> )"
"Summary: Clears the specified flag on self."
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname> : name of the flag to clear"
"OptionalArg: <remove> : free the flag completely, use this when you want to save a variable after you're never going to use the flag again."
"Example: enemy ent_flag_clear( "hq_cleared" );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag_clear( message, remove )
{
/#
 	AssertEx( IsDefined( self ), "Attempt to clear a flag on entity that is not defined" );
	AssertEx( IsDefined( self.ent_flag[ message ] ), "Attempt to set a flag before calling flag_init: " + message + " on entity." );
	Assert( self.ent_flag[ message ] == self.ent_flags_lock[ message ] );
	self.ent_flags_lock[ message ] = false;
#/
	//do this check so we don't unneccessarily send a notify
	if ( 	self.ent_flag[ message ] )
	{
		self.ent_flag[ message ] = false;
		self notify( message );
	}
	
	if ( IsDefined( remove ) && remove )
		self.ent_flag[ message ] = undefined;
}

 /*
 =============
///ScriptDocBegin
"Name: ent_flag( <flagname> )"
"Summary: Checks if the flag is set on self. Returns true or false."
"Module: Flag"
"CallOn: Any entity (script_origin, script_struct, ai, script_model, script_brushmodel, player)"
"MandatoryArg: <flagname> : name of the flag to check"
"Example: enemy ent_flag( "death" );"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
ent_flag( message )
{
	AssertEx( IsDefined( message ), "Tried to check flag but the flag was not defined." );
	AssertEx( IsDefined( self.ent_flag[ message ] ), "Tried to check flag " + message + " but the flag was not initialized." );

	return self.ent_flag[ message ];
}

 /*
 =============
///ScriptDocBegin
"Name: alien_mode_has( <feature_string> )"
"Summary: Checks to see if alien mode as a specific feature active. Returns true or false."
"Module: Alien"
"MandatoryArg: <feature_string> : airdrop, wave, lurker, collectible, loot (more coming!)"
"Example: if( !alien_mode_has( "airdrop" ) { return; }"
"SPMP: multiplayer"
///ScriptDocEnd
 =============
 */
alien_mode_has( feature_str )
{
	feature_str = toLower( feature_str );
	
	if ( !isdefined( level.alien_mode_feature ) )
		return false;

	if ( !isdefined( level.alien_mode_feature[ feature_str ] ) )
		return false;
	
	return level.alien_mode_feature[ feature_str ];
}

 /*
 =============
///ScriptDocBegin
"Name: alien_mode_enable( str_1, str_2, str_3, str_4, str_5, str_6, str_7, str_8, str_9, str_10 )"
"Summary: Enables features in alien mode."
"Module: Alien"
"MandatoryArg: <feature_string> : airdrop, wave, lurker, collectible, loot, mist (more coming!)"
"Example: alien_mode_enable( "airdrop" );"
"SPMP: Multiplayer"
///ScriptDocEnd
 =============
 */
alien_mode_enable( str_1, str_2, str_3, str_4, str_5, str_6, str_7, str_8, str_9, str_10 )
{
	assertex( isdefined( str_1 ), "alien_mode_enable() called without parameters!" );
	
	if ( !isdefined( level.alien_mode_feature ) )
		level.alien_mode_feature = [];
	
	// list of all supported features, also update: check_feature_dependencies();
	if ( !isdefined( level.alien_mode_feature_strings ) )
		level.alien_mode_feature_strings = [ "kill_resource", "nogame", "airdrop", "loot", "wave", "lurker", "collectible", "mist", "pillage", "challenge", "outline", "scenes" ];
	
	// ====== maybe not a good idea, people might not be aware of new features ===========
	if ( str_1 == "all" )
	{
		foreach ( param in level.alien_mode_feature_strings )
			alien_mode_enable_raw( param );
		
		return;
	}
	// ===================================================================================
	
	combined_param = [];
	
	if ( isdefined( str_1 ) )
		combined_param[ combined_param.size ] = toLower( str_1 );
	
	if ( isdefined( str_2 ) )
		combined_param[ combined_param.size ] = toLower( str_2 );

	if ( isdefined( str_3 ) )
		combined_param[ combined_param.size ] = toLower( str_3 );

	if ( isdefined( str_4 ) )
		combined_param[ combined_param.size ] = toLower( str_4 );

	if ( isdefined( str_5 ) )
		combined_param[ combined_param.size ] = toLower( str_5 );

	if ( isdefined( str_6 ) )
		combined_param[ combined_param.size ] = toLower( str_6 );
								
	if ( isdefined( str_7 ) )
		combined_param[ combined_param.size ] = toLower( str_7 );
									
	if ( isdefined( str_8 ) )
		combined_param[ combined_param.size ] = toLower( str_8 );
	
	if ( isdefined( str_9 ) )
		combined_param[ combined_param.size ] = toLower( str_9 );

	if ( isdefined( str_10 ) )
		combined_param[ combined_param.size ] = toLower( str_10 );
	
	check_feature_dependencies( combined_param );
	
	foreach ( param in combined_param )
		alien_mode_enable_raw( param );
}

check_feature_dependencies( combined_param )
{
	foreach ( param in combined_param )
	{
		if ( param == "loot" && !array_contains( combined_param, "collectible" ) )
			assertmsg( "Feature [loot] requires [collectible]" );
		
		if ( param == "airdrop" && !array_contains( combined_param, "wave" ) )
			assertmsg( "Feature [airdrop] requires feature [wave]" );
		
		if ( param == "lurker" && !array_contains( combined_param, "wave" ) )
			assertmsg( "Feature [lurker] requires feature [wave]" );
		
		if ( param == "mist" && !array_contains( combined_param, "wave" ) )
			assertmsg( "Feature [mist] requires feature [wave]" );
	}
}

alien_mode_enable_raw( feature_str )
{
	if ( !array_contains( level.alien_mode_feature_strings, feature_str ) )
	{
		supported_mode_strings = "";
		foreach ( feature in level.alien_mode_feature_strings )
			supported_mode_strings = supported_mode_strings + feature + " ";
	
		assertmsg( feature_str + " is not a supported feature. [ " + supported_mode_strings + "]" );
	}
	
	level.alien_mode_feature[ feature_str ] = true;
}

/*
=============
///ScriptDocBegin
"Name: alien_area_init()"
"Summary: Register distinct areas for item spawning management.  Call before _load"
"Module: Alien"
"Example: alien_area_init( areas )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
alien_area_init( area_array )
{
	AssertEx( !isDefined( level.world_areas ), "alien_area_init() is called multiple times in the same level" );
	
	level.world_areas = [];
	level.area_array = area_array;
	level.current_area_index = 0;
	
	foreach ( area in area_array )
	{
		area_volume = GetEnt( area, "targetname" );
		assert( IsDefined( area_volume ) );

		level.world_areas[ area ] = area_volume;
	}
}

get_current_area_name()
{
	return level.area_array[level.current_area_index];
}

inc_current_area_index()
{
	level.current_area_index++;
}

/*
=============
///ScriptDocBegin
"Name: store_weapons_status()"
"Summary: Store the weapon and the ammo status."
"Module: Alien"
"Example: player store_weapons_status()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
store_weapons_status( weapons_excluded )
{
	//weapons
	self.copy_fullweaponlist = self GetWeaponsListAll();
	self.copy_weapon_current = self GetCurrentWeapon();
	
	//ammo
	foreach( weapon in self.copy_fullweaponlist )
	{
		self.copy_weapon_ammo_clip[ weapon ] = self GetWeaponAmmoClip( weapon );
		self.copy_weapon_ammo_stock[ weapon ] = self GetWeaponAmmoStock( weapon );
	}
	
	//weapons not kept, ex: alienbomb_mp
	if ( isdefined( weapons_excluded ) )
	{
		//update fullweapon list to remove weapons not kept
		allowed_fullweaponlist = [];
		foreach ( weapon in self.copy_fullweaponlist )
		{
			skip = false;
			foreach ( not_allowed_weapon in weapons_excluded )
			{
				if ( weapon == not_allowed_weapon )
				{
					skip = true;
					break;
				}
			}
			
			if ( skip )
				continue;
			
			allowed_fullweaponlist[ allowed_fullweaponlist.size ] = weapon;
		}
		self.copy_fullweaponlist = allowed_fullweaponlist;
		
		//if current weapon was one not kept, reset to "none"
		foreach ( not_allowed_weapon in weapons_excluded )
		{
			if ( self.copy_weapon_current == not_allowed_weapon )
			{
				self.copy_weapon_current = "none";
				break;
			}
		}
	}
}

/*
=============
///ScriptDocBegin
"Name: restore_weapons_status()"
"Summary: Put the weapon and ammo status back to the last time store_weapons_status is called."
"Module: Alien"
"Example: player restore_weapons_status()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
restore_weapons_status( inclusion_list )
{
	if( !isDefined( self.copy_fullweaponlist )
	 || !isDefined( self.copy_weapon_current )
	 || !isDefined( self.copy_weapon_ammo_clip )
	 || !isDefined( self.copy_weapon_ammo_stock )
	  )
		AssertMsg( "Call store_weapons_status() before restore_weapons_status()" );
	 
	//weapons
	//remove any they didn't have
	myWeapons = self GetWeaponsListAll();
	foreach( weapon in myWeapons )
	{
		if ( !array_contains( self.copy_fullweaponlist, weapon ) && !in_inclusion_list( inclusion_list, weapon ) )
		{
			self TakeWeapon( weapon );
		}
	}
	
	//Give weapon and ammo back
	foreach( weapon in self.copy_fullweaponlist )
	{
		if ( !(self HasWeapon( weapon )) )
		{
			self GiveWeapon( weapon );
		}
		
		self SetWeaponAmmoClip( weapon, self.copy_weapon_ammo_clip[ weapon ]  );
		self SetWeaponAmmoStock( weapon, self.copy_weapon_ammo_stock[ weapon ]  );
	}

	WeaponToSwitch = self.copy_weapon_current;
	
	if ( !isDefined ( weaponToSwitch) || WeaponToSwitch == "none" )
		WeaponToSwitch = self.copy_fullweaponlist[ 0 ];
	
	self SwitchToWeapon( WeaponToSwitch );
	
	//clean up
	self.copy_fullweaponlist = undefined;
	self.copy_weapon_current = undefined;
	self.copy_weapon_ammo_clip = undefined;
	self.copy_weapon_ammo_stock = undefined;
}

in_inclusion_list( inclusion_list, item_name )
{
	if ( !isDefined ( inclusion_list ) )
		return false;
	
	return array_contains( inclusion_list, item_name );
}

/*
=============
///ScriptDocBegin
"Name: remove_weapons()"
"Summary: Removes each weapon from the player's primary weaponlist"
"Module: Alien"
"Example: player remove_weapons()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
remove_weapons()
{
	weaponlist = self GetWeaponsListPrimaries();
	
	// now take the weapons
	foreach( weapon in weaponlist )
	{
		weaponTokens = StrTok( weapon, "_" );
	
		if( weaponTokens[0] == "alt" )
			continue;
			
		self TakeWeapon( weapon );
	}
}

/*
=============
///ScriptDocBegin
"Name: get_alien_type()"
"Summary: Gets the type of this alien"
"Module: Alien"
"Example: alien get_alien_type()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
get_alien_type()
{
	AssertEx( isDefined ( self.alien_type ), "self.alien_type is not defined" );
	
	return self.alien_type;
}

/*
=============
///ScriptDocBegin
"Name: should_explode()"
"Summary: Returns whether the alien can explode"
"Module: Alien"
"Example: alien should_explode()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
should_explode()
{
    switch ( maps\mp\alien\_utility::get_alien_type() )
    {
        case "minion":
            return true;
        default:
            return false;
    }    
}


/*
=============
///ScriptDocBegin
"Name: is_normal_upright( normal )"
"Summary: Determines if passed in normal is facing up"
"Module: Alien"
"Example: is_normal_upright( upVector )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
is_normal_upright( normal )
{
	UPRIGHT_VECTOR = ( 0, 0, 1 );
	UPRIGHT_DOT = 0.85;
	return ( VectorDot( normal, UPRIGHT_VECTOR ) > UPRIGHT_DOT );
}

// TODO JW: Remove!  These notetracks should be in the animations
always_play_pain_sound( anime )
{
	if ( !AnimHasNotetrack( anime, "alien_pain_light" ) && !AnimHasNoteTrack( anime, "alien_pain_heavy" ) )
	{
		self PlaySoundOnMovingEnt( "alien_pain_light" );
	}
	
}

register_pain( anim_entry )
{
	/# AssertEx( !IsDefined( self.pain_registered ) || !self.pain_registered, "Shouldn't be able to register a pain when one already registered!" ); #/
	self.pain_registered = true;
	self thread pain_interval_monitor( anim_entry );
}

pain_interval_monitor( anim_entry )
{
	self endon ("death" );
	
	alienType = self get_alien_type();
	painInterval = level.alien_types[ alienType ].attributes[ "pain_interval" ];
	wait painInterval + GetAnimLength( anim_entry );
	self.pain_registered = false;
}

is_pain_available( attacker, sMeansOfDeath )
{	
	if ( IsDefined( self.pain_registered ) && self.pain_registered )
		return false;
	
	// Prevent pain when oriented in order to prevent stuck cases
	if( IsDefined( self.oriented ) && self.oriented )
		return false;

	if ( sMeansOfDeath == "MOD_MELEE" )
		return true;
	
	if ( isDefined ( attacker ) && isPlayer ( attacker ) && attacker has_stun_ammo() )
		return true;
	
	return true;
}

// MP ents clean up

mp_ents_clean_up()
{
	// wait for padding
	wait 0.5;
	
	// "heli_start" script origins removed
	heli_start_nodes 	= getEntArray( "heli_start", "targetname" );
	foreach( start_node in heli_start_nodes )
		get_linked_nodes_and_delete( start_node );
	
	// "heli_loop_start" script origins removed
	heli_loop_nodes 	= getEntArray( "heli_loop_start", "targetname" );
	foreach( loop_node in heli_loop_nodes )
		get_linked_nodes_and_delete( loop_node );
	
	// "heli_crash_start" script origins removed
	heli_crash_nodes 	= getEntArray( "heli_crash_start", "targetname" );
	foreach( crash_node in heli_crash_nodes )
		get_linked_nodes_and_delete( crash_node );

}

// grab all the nodes chained starting from start_node
get_linked_nodes_and_delete( start_node )
{
	cur_node = start_node;
	
	while ( isdefined( cur_node.target ) )
	{
		next_node = getent( cur_node.target, "targetname" );
		if ( isdefined( next_node ) )
		{
			cur_node delete();
			cur_node = next_node;
		}
		else
		{
			break;
		}
	}
	
	if ( isdefined( cur_node ) )
		cur_node delete();
}

/*
=============
///ScriptDocBegin
"Name: is_holding_deployable()"
"Summary: Returns if player is holding any deployables."
"Module: Alien"
"Example: return level.players[0] is_holding_deployable();"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
is_holding_deployable()
{
	return 	self.is_holding_deployable;
}

has_special_weapon()
{
	return 	self.has_special_weapon;
}
type_has_head_armor( type )
{
	switch( type )
	{
		case "brute1":
		case "brute2":
		case "brute3":
		case "brute4":
			return true;
		default:
			return false;
	}
	
	return false;
}

get_closest_living_player()
{
	closest_distance_sqr = 1073741824;
	closest_player = undefined;
	
	foreach ( player in level.players )
	{
		dist_sqr = DistanceSquared( self.origin, player.origin );
		if ( IsReallyAlive( player ) && dist_sqr < closest_distance_sqr )
		{
			closest_player = player;
			closest_distance_sqr = dist_sqr;
		}
	}
	
	return closest_player;
}


// this is called when a player grabs any of the specialized ammo types. 
// Make sure we don't store existing special ammo, but rather just replace it and zero out the previous special ammo for that weapon
should_store_ammo_check( exclude_type, special_ammo_weapon )
{
	should_store_ammo = true;
	switch ( exclude_type )
	{
		case "explosive": //check for AP, Incendiary & Stun & combined
			if ( isDefined ( self.special_ammocount ) && isDefined ( self.special_ammocount[special_ammo_weapon] ) && self.special_ammocount[special_ammo_weapon] > 0 )
			{
				self.special_ammocount[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_bulletdamage" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_ap ) && isDefined ( self.special_ammocount_ap[special_ammo_weapon] ) && self.special_ammocount_ap[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_ap[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_armorpiercing" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_in ) && isDefined ( self.special_ammocount_in[special_ammo_weapon] ) && self.special_ammocount_in[special_ammo_weapon] > 0 )
			{
				self.has_incendiary_ammo = undefined;
				self.special_ammocount_in[special_ammo_weapon] = 0;
				return false;
			}
			else if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[special_ammo_weapon] ) && self.special_ammocount_comb[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_comb[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_explosivebullets" );
				self _unsetPerk( "specialty_armorpiercing" );
				self _unsetPerk( "specialty_bulletdamage" );
				self.has_incendiary_ammo = undefined;
				return false;
			}
			return true;
			
		case "ap": //check for Explosive, Incendiary & Stun & combined
		case "piercing":
			if ( isDefined ( self.special_ammocount ) && isDefined ( self.special_ammocount[special_ammo_weapon] ) && self.special_ammocount[special_ammo_weapon] > 0 )
			{
				self.special_ammocount[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_bulletdamage" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_explo ) && isDefined ( self.special_ammocount_explo[special_ammo_weapon] ) && self.special_ammocount_explo[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_explo[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_explosivebullets" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_in ) && isDefined ( self.special_ammocount_in[special_ammo_weapon] ) && self.special_ammocount_in[special_ammo_weapon] > 0 )
			{
				self.has_incendiary_ammo = undefined;
				self.special_ammocount_in[special_ammo_weapon] = 0;
				return false;
			}
			else if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[special_ammo_weapon] ) && self.special_ammocount_comb[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_comb[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_explosivebullets" );
				self _unsetPerk( "specialty_armorpiercing" );
				self _unsetPerk( "specialty_bulletdamage" );
				self.has_incendiary_ammo = undefined;
				return false;
			}
			return true;
			
		case "stun": //check for AP, Incendiary & Explosive & combined
			if ( isDefined ( self.special_ammocount_explo ) && isDefined ( self.special_ammocount_explo[special_ammo_weapon] ) && self.special_ammocount_explo[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_explo[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_explosivebullets" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_ap ) && isDefined ( self.special_ammocount_ap[special_ammo_weapon] ) && self.special_ammocount_ap[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_ap[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_armorpiercing" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_in ) && isDefined ( self.special_ammocount_in[special_ammo_weapon] ) && self.special_ammocount_in[special_ammo_weapon] > 0 )
			{
				self.has_incendiary_ammo = undefined;
				self.special_ammocount_in[special_ammo_weapon] = 0;
				return false;
			}
			else if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[special_ammo_weapon] ) && self.special_ammocount_comb[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_comb[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_explosivebullets" );
				self _unsetPerk( "specialty_armorpiercing" );
				self _unsetPerk( "specialty_bulletdamage" );
				self.has_incendiary_ammo = undefined;
				return false;
			}
			return true;
			
		case "incendiary": ////check for AP, explosive & Stun & combined
			if ( isDefined ( self.special_ammocount ) && isDefined ( self.special_ammocount[special_ammo_weapon] ) && self.special_ammocount[special_ammo_weapon] > 0 )
			{
				self.special_ammocount[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_bulletdamage" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_ap ) && isDefined ( self.special_ammocount_ap[special_ammo_weapon] ) && self.special_ammocount_ap[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_ap[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_armorpiercing" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_explo ) && isDefined ( self.special_ammocount_explo[special_ammo_weapon] ) && self.special_ammocount_explo[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_explo[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_explosivebullets" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[special_ammo_weapon] ) && self.special_ammocount_comb[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_comb[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_explosivebullets" );
				self _unsetPerk( "specialty_armorpiercing" );
				self _unsetPerk( "specialty_bulletdamage" );
				self.has_incendiary_ammo = undefined;
				return false;
			}
			return true;
			
		case "combined": ////check for AP, explosive & Stun & incendiary
			if ( isDefined ( self.special_ammocount ) && isDefined ( self.special_ammocount[special_ammo_weapon] ) && self.special_ammocount[special_ammo_weapon] > 0 )
			{
				self.special_ammocount[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_bulletdamage" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_ap ) && isDefined ( self.special_ammocount_ap[special_ammo_weapon] ) && self.special_ammocount_ap[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_ap[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_armorpiercing" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_explo ) && isDefined ( self.special_ammocount_explo[special_ammo_weapon] ) && self.special_ammocount_explo[special_ammo_weapon] > 0 )
			{
				self.special_ammocount_explo[special_ammo_weapon] = 0;
				self _unsetPerk( "specialty_explosivebullets" );
				return false;
			}
			else if ( isDefined ( self.special_ammocount_in ) && isDefined ( self.special_ammocount_in[special_ammo_weapon] ) && self.special_ammocount_in[special_ammo_weapon] > 0 )
			{
				self.has_incendiary_ammo = undefined;
				self.special_ammocount_in[special_ammo_weapon] = 0;
				return false;
			}
			return true;
	}
	
}
/*
=============
///ScriptDocBegin
"Name: is_ammo_already_stored( <weaponName> )"
"Summary: Checks to see if a player already has ammo stored for this weapon"
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <weaponName>: "
"Example: "
"SPMP: coop"
///ScriptDocEnd
=============
*/

is_ammo_already_stored( weaponName )
{
	if ( isDefined ( self.stored_ammo[weaponName] ) )
	{
		return ( isDefined( self.stored_ammo[weaponName].clipammo ) && isDefined ( self.stored_ammo[weaponName].ammoStock ) );
	}
	return false;
}
	
		   
give_special_ammo_by_weaponclass( boxent , primary_weapon , pillage )
{
	if ( !isDefined ( primary_weapon ) )
	{
		primary_weapon = self GetCurrentPrimaryWeapon();
	}
	class = getWeaponClass( primary_weapon );	
	
	ratio = 0;
	if ( isDefined ( boxent ) )
	{
		if ( boxent.boxtype != "deployable_specialammo_comb" )
		{
			switch ( boxent.upgrade_rank )
			{
				case 0: ratio = .3; break;
				case 1:	ratio = .4; break;
				case 2:	ratio = .5; break;
				case 3:	ratio = .6; break;
				case 4:	ratio = .7; break;
			}
		}
		else
		{
			switch (boxEnt.upgrade_rank)
			{
				case 0:
					ratio = 0.4;
					break;
				case 1:
					ratio = 0.7;
					break;
				case 2:
					ratio = 1.0;
					break;
				case 3:
					ratio = 1.0;
					self maps\mp\alien\_deployablebox_functions::addFullCombinedClipToAllWeapons();
					break;
				case 4:
					ratio = 1.0;
					self maps\mp\alien\_deployablebox_functions::addFullCombinedClipToAllWeapons();
					break;			
			}	
		}
	}
	
	nerf_min_ammo_scalar = self maps\mp\alien\_deployablebox_functions::check_for_nerf_min_ammo();	
	if ( nerf_min_ammo_scalar != 1.0 )
	{
		ratio = nerf_min_ammo_scalar;
	}	
	
	switch( class )
	{
		case "weapon_smg": // 1 clip for SMG , assault or LMG			
		case "weapon_assault":
		case "weapon_shotgun": // 2 for the shotgun, pistol & sniper
		case "weapon_pistol":		
		case "weapon_sniper":
		case "weapon_lmg":			
		case "weapon_dmr":
			
			if ( isDefined ( pillage ) && pillage )
			{
				
				if ( level.use_alternate_specialammo_pillage_amounts )
				{
					clip = WeaponClipSize( primary_weapon );
					return ( int( clip * 2 ) );
				}
				
				return ( int ( WeaponMaxAmmo ( primary_weapon ) * 0.2 ) );//always finds 20% max 
				
			}
			else
			{
				return ( int ( WeaponMaxAmmo ( primary_weapon ) * ratio ) );
			}
		
		default:
			return 0;
	}
	
}

player_has_specialized_ammo(  special_ammo_weapon )
{

	has_special_ammo = false;
	//stun	
	if ( isDefined ( self.special_ammocount ) && isDefined ( self.special_ammocount[special_ammo_weapon] ) && self.special_ammocount[special_ammo_weapon] > 0 )
	{
		has_special_ammo = true;
	}
	
	//armor piercing
	if ( isDefined ( self.special_ammocount_ap ) && isDefined ( self.special_ammocount_ap[special_ammo_weapon] ) && self.special_ammocount_ap[special_ammo_weapon] > 0 )
	{
		has_special_ammo = true;
	}
	
	//incendiary
	if ( isDefined ( self.special_ammocount_in ) && isDefined ( self.special_ammocount_in[special_ammo_weapon] ) && self.special_ammocount_in[special_ammo_weapon] > 0 )
	{
		has_special_ammo = true;
	}
	
	//explosive
	if ( isDefined ( self.special_ammocount_explo ) && isDefined ( self.special_ammocount_explo[special_ammo_weapon] ) && self.special_ammocount_explo[special_ammo_weapon] > 0 )
	{
		has_special_ammo = true;
	}
	
	//combined
	if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[special_ammo_weapon] ) && self.special_ammocount_comb[special_ammo_weapon] > 0 )
	{
		has_special_ammo = true;
	}
	
	return has_special_ammo;
}

has_stun_ammo( weapon_to_check )
{
	if ( !isDefined ( weapon_to_check ) )
		weapon = self GetCurrentWeapon();
	else
		weapon = weapon_to_check;
	
	if ( weapon == "none" )
	{
		weapon = self GetWeaponsListPrimaries()[0];
	}
	
	base_weapon = getRawBaseWeaponName( weapon );
	
	if ( is_chaos_mode() && self HasPerk( "specialty_bulletdamage", true ) )
	    return true;
	
	if ( isDefined ( self.special_ammocount ) && isDefined ( self.special_ammocount[base_weapon] ) && self.special_ammocount[base_weapon] > 0 ) //player has stun ammo
		return true;
	
	if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[base_weapon] ) && self.special_ammocount_comb[base_weapon] > 0 ) //player has combined ammo
		return true;
	
	return false;	
}

has_ap_ammo( weapon_to_check )
{
	if ( !isDefined ( weapon_to_check ) )
		weapon = self GetCurrentWeapon();
	else
		weapon = weapon_to_check;	
	
	if ( weapon == "none" )
	{
		weapon = self GetWeaponsListPrimaries()[0];
	}
	
	base_weapon = getRawBaseWeaponName( weapon );
	if ( isDefined ( self.special_ammocount_ap ) && isDefined ( self.special_ammocount_ap[base_weapon] ) && self.special_ammocount_ap[base_weapon] > 0 ) //player has ap ammo
		return true;
	
	if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[base_weapon] ) && self.special_ammocount_comb[base_weapon] > 0 ) //player has combined ammo
		return true;
		
	return false;	
}

has_explosive_ammo( weapon_to_check )
{
	if ( !isDefined ( weapon_to_check ) )
		weapon = self GetCurrentWeapon();
	else
		weapon = weapon_to_check;	
	
	if ( weapon == "none" )
	{
		weapon = self GetWeaponsListPrimaries()[0];
	}
	
	base_weapon = getRawBaseWeaponName( weapon );
	if ( isDefined ( self.special_ammocount_explo ) && isDefined ( self.special_ammocount_explo[base_weapon] ) && self.special_ammocount_explo[base_weapon] > 0 ) //player has ap ammo
		return true;
	
	if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[base_weapon] ) && self.special_ammocount_comb[base_weapon] > 0 ) //player has combined ammo
		return true;
		
	return false;	
}

has_incendiary_ammo( weapon_to_check )
{
	if ( !isDefined ( weapon_to_check ) )
		weapon = self GetCurrentWeapon();
	else
		weapon = weapon_to_check;	
	
	if ( weapon == "none" )
	{
		weapon = self GetWeaponsListPrimaries()[0];
	}
	
	base_weapon = getRawBaseWeaponName( weapon );
	if ( isDefined ( self.special_ammocount_in ) && isDefined ( self.special_ammocount_in[base_weapon] ) && self.special_ammocount_in[base_weapon] > 0 ) //player has ap ammo
		return true;
	
	if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[base_weapon] ) && self.special_ammocount_comb[base_weapon] > 0 ) //player has combined ammo
		return true;
		
	return false;	
}

has_combined_ammo( weapon_to_check )
{
	if ( !isDefined ( weapon_to_check ) )
		weapon = self GetCurrentWeapon();
	else
		weapon = weapon_to_check;	
	
	if ( weapon == "none" )
	{
		weapon = self GetWeaponsListPrimaries()[0];
	}
	
	base_weapon = getRawBaseWeaponName( weapon );
	if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[base_weapon] ) && self.special_ammocount_comb[base_weapon] > 0 ) //player has combined ammo
		return true;
		
	return false;	
}

remove_specialized_ammo(  special_ammo_weapon )
{
	has_special_ammo = false;
	//stun	
	if ( isDefined ( self.special_ammocount ) && isDefined ( self.special_ammocount[special_ammo_weapon] ) && self.special_ammocount[special_ammo_weapon] > 0 )
	{
		self.special_ammocount[special_ammo_weapon] = 0;
	}
	
	//armor piercing
	if ( isDefined ( self.special_ammocount_ap ) && isDefined ( self.special_ammocount_ap[special_ammo_weapon] ) && self.special_ammocount_ap[special_ammo_weapon] > 0 )
	{
		self.special_ammocount_ap[special_ammo_weapon] = 0;
	}
	
	//incendiary
	if ( isDefined ( self.special_ammocount_in ) && isDefined ( self.special_ammocount_in[special_ammo_weapon] ) && self.special_ammocount_in[special_ammo_weapon] > 0 )
	{
		self.special_ammocount_in[special_ammo_weapon] = 0;
	}
	
	//explosive
	if ( isDefined ( self.special_ammocount_explo ) && isDefined ( self.special_ammocount_explo[special_ammo_weapon] ) && self.special_ammocount_explo[special_ammo_weapon] > 0 )
	{
		self.special_ammocount_explo[special_ammo_weapon] = 0;
	}
	
	//combined
	if ( isDefined ( self.special_ammocount_comb ) && isDefined ( self.special_ammocount_comb[special_ammo_weapon] ) && self.special_ammocount_comb[special_ammo_weapon] > 0 )
	{
		self.special_ammocount_comb[special_ammo_weapon] = 0;
	}
}

get_specialized_ammo_type()
{
	weapon = self GetCurrentWeapon();
	
	if ( weapon == "none" )
	{
		weapon = self GetWeaponsListPrimaries()[0];
	}
	
	base_weapon = getRawBaseWeaponName( weapon );

	has_special_ammo = false;
	//stun	
	if ( isDefined ( self.special_ammocount ) && isDefined ( self.special_ammocount[base_weapon] ) && self.special_ammocount[base_weapon] > 0 )
	{
		return "stun_ammo";
	}
	
	//armor piercing
	if ( isDefined ( self.special_ammocount_ap ) && isDefined ( self.special_ammocount_ap[base_weapon] ) && self.special_ammocount_ap[base_weapon] > 0 )
	{
		return "ap_ammo";
	}
	
	//incendiary
	if ( isDefined ( self.special_ammocount_in ) && isDefined ( self.special_ammocount_in[base_weapon] ) && self.special_ammocount_in[base_weapon] > 0 )
	{
		return "incendiary_ammo";
	}
	
	//explosive
	if ( isDefined ( self.special_ammocount_explo ) && isDefined ( self.special_ammocount_explo[base_weapon] ) && self.special_ammocount_explo[base_weapon] > 0 )
	{
		return "explosive_ammo";
	}
	
	return "none";
}



mark_dangerous_nodes( dangerous_origin, radius, duration )
{
	
	MarkDangerousNodes( dangerous_origin, radius, true );
	wait duration;
	MarkDangerousNodes( dangerous_origin, radius, false );
}

/*
catch_alien_on_fire( player )
{
	self endon( "death" );
	if ( isDefined( self.is_burning ) )
		return;
	
	BURN_TIME = 3.0;
	
	//self thread alien_on_fire( burn_time );
	self maps\mp\alien\_alien_fx::alien_fire_on();
	self thread damage_alien_over_time( BURN_TIME, player );
	
	wait BURN_TIME;
	self maps\mp\alien\_alien_fx::alien_fire_off();
}

//self = an alien
damage_alien_over_time( burn_time, player  )
{
	self endon( "death" );
	
	total_time = 0;
	while ( total_time <= burn_time )
	{
		self DoDamage( 10,self.origin, player, player, "MOD_UNKNOWN");
		total_time += 1;
		wait 1;
	}
}
*/

/*
=============
///ScriptDocBegin
"Name: is_in_laststand()"
"Summary: Returns true if the player is in last stand"
"Module: Alien"
"Example:  if ( self is_in_laststand() )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
is_in_laststand()
{
	return self.inLastStand;
}

is_hardcore_mode()
{
	return ( level.hardcoreMode );
}

is_ricochet_damage()
{
	return ( level.ricochetDamage );
}

is_chaos_mode()
{
	return ( level.isChaosMode == 1 );
}

is_casual_mode()
{
	return ( level.casualMode == 1 );
}

get_chaos_area()
{
	return level.chaos_area;
}

deployable_box_onuse_message( boxent )
{
	msg_text = "";
	if ( isDefined ( boxEnt ) && isDefined( boxEnt.boxType ) && isDefined ( level.boxSettings [ boxEnt.boxtype ].eventString ) )
		msg_text = level.boxSettings [ boxEnt.boxtype ].eventString;
	
	self thread setLowerMessage( "deployable_use",msg_text ,3 );
}

set_attack_sync_direction( offset_direction, enter_anim, looping_anim, exit_anim, attacker_anim_state, attacker_anim_label )
{
	attack_sync = [];
	
	attack_sync["enterAnim"] = enter_anim;
	attack_sync["loopAnim"] = looping_anim;
	attack_sync["exitAnim"] = exit_anim;
	attack_sync["attackerAnimState"] = attacker_anim_state;
	attack_sync["attackerAnimLabel"] = attacker_anim_label;
	attack_sync["offset_direction"] = offset_direction;
	
	return attack_sync;
}

set_synch_attack_setup( synch_directions, type_specific, end_notifies, can_synch_attack_func, begin_attack_func, loop_attack_func, end_attack_func, identifier )
{
	attackSetup = SpawnStruct();
	
	attackSetup.synch_directions = synch_directions;
	attackSetup.type_specific = type_specific;
	attackSetup.primary_attacker = undefined;
	attackSetup.can_synch_attack_func = can_synch_attack_func;
	attackSetup.begin_attack_func = begin_attack_func;
	attackSetup.end_attack_func = end_attack_func;
	attackSetup.loop_attack_func = loop_attack_func;
	attackSetup.end_notifies = end_notifies;
	attackSetup.identifier = identifier;
	
	self.synch_attack_setup = attackSetup;
}

get_synch_direction_list( synch_enemy )
{
	if ( !IsDefined( self.synch_attack_setup ) )
		return [];
	
	if ( !IsDefined( self.synch_attack_setup.synch_directions ) )
		return [];
	
	if ( !self.synch_attack_setup.type_specific )
		return self.synch_attack_setup.synch_directions;
	
	alienType = synch_enemy get_alien_type();
	
	if ( !IsDefined( self.synch_attack_setup.synch_directions[alienType] ) )
    {
    	msg = "Synch attack on " + self.synch_attack_setup.identifier + " doesn't handle type: " + alienType;
    	AssertMsg( msg );
    }
	
	return self.synch_attack_setup.synch_directions[alienType];
}

/*
=============
///ScriptDocBegin
"Name: is_alien_agent()"
"Summary: Returns whether self is an alien agent."
"Module: Alien"
"Example: ent is_alien_agent()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
is_alien_agent()
{
	return IsAgent( self ) && IsDefined( self.alien_type );
}

/*
=============
///ScriptDocBegin
"Name: isPlayingSolo()"
"Summary: Returns true if game is in Solo match."
"Module: Alien"
"Example: if ( isPlayingSolo() ) { IPrintLnBold( "I'm so lonely T_T" ); }"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
isPlayingSolo()
{
	
	if ( getDvarInt ( "sv_maxclients" ) == 1 )
		return true;
		
	return false;
	
}

/*
=============
///ScriptDocBegin
"Name: riotShieldName()"
"Summary: Returns the name of the riotshield the player is carrying"
"Module: Entity"
"CallOn: Player"
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

riotShieldName()
{
		weapons = self GetWeaponsList( "primary" );
		
		if ( !self.hasRiotShield )
			return;
		
		foreach( weapon in weapons )
		{
			if ( WeaponType( weapon ) == "riotshield" )
			{
				return weapon;
			}
		}
}

/*
=============
///ScriptDocBegin
"Name: get_array_of_valid_players( <get_closest> , <get_closest_org> )"
"Summary: Returns an array of valid ( alive and playing ) players. Can optionally return a sorted array closest to a point "
"Module: Entity"
"CallOn: An entity"
"OptionalArg: <get_closest>: "
"OptionalArg: <get_closest_org>: "
"Example: closest_players = get_array_of_valid_players( true, thing.origin )"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

get_array_of_valid_players( sort_by_closest, sort_by_closest_org )
{
	valid_players = [];
	
	foreach ( player in level.players )
	{
		if ( player is_valid_player() )
			valid_players[valid_players.size] = player;
	}
	
	if ( !isDefined ( sort_by_closest ) || !sort_by_closest )
		return valid_players;
	
	return get_array_of_closest( sort_by_closest_org, valid_players );
}

/*
=============
///ScriptDocBegin
"Name: is_valid_player()"
"Summary: Returns false if a player is not considered to be 'valid'  ( alive and playing )"
"Module: Entity"
"CallOn: An entity"
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

is_valid_player()
{
	if ( !isDefined ( self ) )
		return false;
	
	if ( self maps\mp\alien\_utility::is_in_laststand() )
		return false;
	
	if ( !isAlive ( self ) )
		return false;
	
	if ( self.sessionstate == "spectator" )
		return false;
	
	return true;	
}
/*
=============
///ScriptDocBegin
"Name: getRawBaseWeaponName( <weaponName> )"
"Summary: Returns only the name of the weapon.  iw6_alienp226_mp_akimbo will return alienp226"
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <weaponName>: "
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

getRawBaseWeaponName( weaponName )
{
	tokens = strTok( weaponName, "_" );
	
	if ( tokens[0] == "iw5" || tokens[0] == "iw6" )
	{
		weaponName = tokens[1];
	}
	else if( tokens[0] == "alt" )
	{
		weaponName = tokens[1] + "_" + tokens[2];
	}
	
	return weaponName;
}

/*
=============
///ScriptDocBegin
"Name: get_in_world_area()"
"Summary: Return the name for the FIRST world area which the entity is in"
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: none"
"Example: area_name = player get_in_world_area()"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/

get_in_world_area()
{
	assertEx( isDefined( level.world_areas ), "Register world area with alien_area_init()" );
	
	foreach( area_name, area_volumn in level.world_areas )
	{
		if ( self isTouching( area_volumn ) )
			return area_name;
	}
	
	return "none";	
}

/*
=============
///ScriptDocBegin
"Name: is_true( <arg> )"
"Summary: Returns true if a value is both defined & true. "
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <arg>: "
"Example: if ( is_true( level.somevalue ) ) "
"SPMP: coop"
///ScriptDocEnd
=============
*/

is_true( arg )
{
	if( IsDefined( arg ) && arg )
		return true;
	
	return false;
}

/*
=============
///ScriptDocBegin
"Name: is_akimbo_weapon( <weapon> )"
"Summary: Returns true if this weapon is one of the akimbo weapons used for Extinction"
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <weapon>: "
"Example: if ( is_akimbo_weapon ( weapon ) )"
"SPMP: coop"
///ScriptDocEnd
=============
*/

is_akimbo_weapon( weapon ) 
{
	
	switch ( weapon )
	{
		case "iw5_alienp226_mp_akimbo_barrelrange02_xmags":
		case "iw5_alienmagnum_mp_akimbo_barrelrange02_xmags":
		case "iw5_alienm9a1_mp_akimbo_barrelrange02_xmags":
		case "iw5_alienmp443_mp_akimbo_barrelrange02_xmags":
		return true;
	}
	
	if ( getWeaponClass ( weapon )  == "weapon_pistol" )
		return issubstr( weapon,"akimbo" );	
	
	return false;
	
}

/*
=============
///ScriptDocBegin
"Name: specialammo_weaponchange_monitor( <special_ammo_type> )"
"Summary: "
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <special_ammo_type>: "
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

special_ammo_weapon_change_monitor( special_ammo_type )
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	self notify ( "special_weapons_monitor" );
	self endon ( "special_weapons_monitor" );

	while ( 1 )
	{
		self waittill( "weapon_change", newWeapon );
		
		if ( newWeapon == "none" )
			continue;
		
		baseweapon = getRawBaseWeaponName( newWeapon );		
		
		has_special_ammo =  false;
		perk = undefined;
		icon_index = undefined;	
		
		switch ( special_ammo_type )
		{
			case "stun":
				has_special_ammo = self has_stun_ammo( baseweapon );
				perk = "specialty_bulletdamage";
				icon_index = 1;
				break;

			case "piercing":
				has_special_ammo = self has_ap_ammo( baseweapon );
				perk = "specialty_armorpiercing";
				icon_index = 4;
				break;
				
			case "incendiary":
				has_special_ammo = self has_incendiary_ammo ( baseweapon );
				icon_index = 2;
				break;
				
			case "explosive":
				has_special_ammo = self has_explosive_ammo ( baseweapon );
				perk =  "specialty_explosivebullets";
				icon_index = 3;
				break;
				
			case "combined":
				has_special_ammo = self has_combined_ammo ( baseweapon );
				icon_index = 5;
				break;
		}
		
		if ( is_true ( has_special_ammo ) )
		{
			if ( isDefined ( perk ) )
				self givePerk( perk, false );
			
			if ( special_ammo_type == "combined" ) 
			{
				self.has_incendiary_ammo = true;
				self giveperk( "specialty_bulletdamage", false );
				self giveperk( "specialty_armorpiercing", false );				
				self giveperk( "specialty_explosivebullets", false );
			}				
			
			if ( special_ammo_type == "incendiary" ) 
				self.has_incendiary_ammo = true;
			
			self SetClientOmnvar("ui_alien_specialammo", icon_index );
		}
		else
		{
			if ( isDefined ( perk ) )
			{
				if ( self _hasPerk ( perk ) )
					self _unsetPerk( perk );
			}
			
			if ( special_ammo_type == "combined" )
			{
				self.has_incendiary_ammo = undefined;
				if ( self _hasPerk ( "specialty_bulletdamage" ) )
					self _unsetPerk( "specialty_bulletdamage" );
				if ( self _hasPerk ( "specialty_armorpiercing" ) )
					self _unsetPerk( "specialty_armorpiercing" );
				if ( self _hasPerk ( "specialty_explosivebullets" ) )
					self _unsetPerk( "specialty_explosivebullets" );	
			}				
			
			if ( special_ammo_type == "incendiary" )
				self.has_incendiary_ammo = undefined;
			
			self SetClientOmnvar("ui_alien_specialammo", -1 );			
		}
	}
}

special_ammo_weapon_fire_monitor( special_ammo_type )
{
	self notify ( "weaponfire_monitor" );
	self endon ( "weaponfire_monitor" );
	
	while ( 1 )
	{
		self waittill( "weapon_fired",wpnName );
		baseweaponName = getRawBaseWeaponName( wpnName );
		
		has_special_ammo = false;
		perk = undefined;
		
		switch ( special_ammo_type )
		{
			case "stun":
				has_special_ammo = self has_stun_ammo( baseweaponName );
				perk = "specialty_bulletdamage";
				ammo_array = self.special_ammocount;
				break;

			case "piercing":
				has_special_ammo = self has_ap_ammo( baseweaponName );
				perk = "specialty_armorpiercing";
				ammo_array = self.special_ammocount_ap;
				break;
				
			case "incendiary":
				has_special_ammo = self has_incendiary_ammo ( baseweaponName );
				ammo_array = self.special_ammocount_in;
				break;
				
			case "explosive":
				has_special_ammo = self has_explosive_ammo ( baseweaponName );
				perk =  "specialty_explosivebullets";
				ammo_array = self.special_ammocount_explo;
				break;
			case "combined":
				has_special_ammo = self has_combined_ammo ( baseweaponName );
				ammo_array = self.special_ammocount_comb;
				break;			
		}
		
		
		if ( is_true ( has_special_ammo) )
		{
			
			weapon_clip = self GetWeaponAmmoClip( wpnName );
			weapon_stock = self GetWeaponAmmoStock( wpnName );
			
			if ( is_akimbo_weapon( wpnname )  )
			{
				weapon_clip_left = self GetWeaponAmmoClip( wpnName,"left" );
				weapon_clip_right = self GetWeaponAmmoClip ( wpnname,"right" );
				weapon_clip = weapon_clip_left + weapon_clip_right;
			}
			
			switch ( special_ammo_type )
			{
				case "stun":
					self.special_ammocount[baseweaponName] = weapon_clip + weapon_stock;
					break;
		
				case "piercing":
					self.special_ammocount_ap[baseweaponName]  = weapon_clip + weapon_stock;
					break;
					
				case "incendiary":
					self.special_ammocount_in[baseweaponName]  = weapon_clip + weapon_stock;
					break;
					
				case "explosive":
					self.special_ammocount_explo[baseweaponName] = weapon_clip + weapon_stock;
					break;
				case "combined":
					self.special_ammocount_comb[baseweaponName] = weapon_clip + weapon_stock;
					break;
			}

			if ( weapon_clip + weapon_stock < 1 )
			{
				self SetClientOmnvar("ui_alien_specialammo",-1 );
				
				if ( isDefined ( perk ) )
				{
					if ( self _hasPerk ( perk ) )
						self _unsetPerk( perk );
				}
				
				if ( special_ammo_type == "combined" )
				{
					self.has_incendiary_ammo = undefined;
					if ( self _hasPerk ( "specialty_bulletdamage" ) )
						self _unsetPerk( "specialty_bulletdamage" );
					if ( self _hasPerk ( "specialty_armorpiercing" ) )
						self _unsetPerk( "specialty_armorpiercing" );
					if ( self _hasPerk ( "specialty_explosivebullets" ) )
						self _unsetPerk( "specialty_explosivebullets" );	
				}
				
				if ( special_ammo_type == "incendiary" )
					self.has_incendiary_ammo = undefined;
				
				if ( isDefined( self.stored_ammo[baseweaponName] ) )
				{
					//add existing clip ammo to the stock, then set the clip to 0 so it forces a reload
					self.stored_ammo[baseweaponName].ammoStock += self.stored_ammo[baseweaponName].clipammo;					
					self setweaponammoclip( wpnName, 0);
					self setweaponammostock( wpnName,self.stored_ammo[baseweaponName].ammoStock );
					self.stored_ammo[baseweaponName] = undefined;
					self SwitchToWeapon( wpnName );
				}
				continue;
			}
		}
	}

}


/*
=============
///ScriptDocBegin
"Name: disable_special_ammo()"
"Summary: Disable any specialized ammo that the player has"
"Module: Entity"
"CallOn: An entity"
"Example: self disable_special_ammo() "
"SPMP: coop"
///ScriptDocEnd
=============
*/

disable_special_ammo()
{
	self endon( "disconnect" );

	//determine the type of special ammo to disable
	primaries = self GetWeaponsListPrimaries();
	foreach ( weapon in primaries )
	{
		baseweapon = getRawBaseWeaponName( weapon );
		
		special_ammo_type =  undefined;
		perk = undefined;
		icon_index = undefined;	
		
		if ( self has_stun_ammo( baseweapon ) )
		{
			perk = "specialty_bulletdamage";
			icon_index = 1;
			special_ammo_type = "stun";
		}
		else if ( self has_ap_ammo( baseweapon ) )
		{
			perk = "specialty_armorpiercing";
			icon_index = 4;
			special_ammo_type = "piercing";
		}
		else if( self has_incendiary_ammo ( baseweapon ) )
		{
			special_ammo_type = "incendiary";
			icon_index = 2;
		}
		else if (  self has_explosive_ammo ( baseweapon ) )
		{
			special_ammo_type = "explosive";
			perk =  "specialty_explosivebullets";
			icon_index = 3;
		}
		else if (  self has_combined_ammo ( baseweapon ) )
		{
			special_ammo_type = "combined";
			icon_index = 5;
		}

		if ( isDefined ( special_ammo_type ) )
		{
		
			if ( isDefined ( perk ) )
			{
				if ( self _hasPerk ( perk ) )
					self _unsetPerk( perk );
			}
			
			if ( special_ammo_type == "combined" )
			{
				self.has_incendiary_ammo = undefined;
				if ( self _hasPerk ( "specialty_bulletdamage" ) )
					self _unsetPerk( "specialty_bulletdamage" );
				if ( self _hasPerk ( "specialty_armorpiercing" ) )
					self _unsetPerk( "specialty_armorpiercing" );
				if ( self _hasPerk ( "specialty_explosivebullets" ) )
					self _unsetPerk( "specialty_explosivebullets" );	
			}
			
			if ( special_ammo_type == "incendiary" )
				self.has_incendiary_ammo = undefined;
			
			self SetClientOmnvar("ui_alien_specialammo", -1 );
			
			return;	//break out here since it's possible that not all weapons have specialized ammo, but not possible to have multiple types		
		}
	}
}
	
/*
=============
///ScriptDocBegin
"Name: enable_special_ammo()"
"Summary: Enables specialized ammo on the player"
"Module: Entity"
"CallOn: An entity"
"Example: self enable_special_ammo()"
"SPMP: coop"
///ScriptDocEnd
=============
*/

enable_special_ammo()
{
	self endon( "disconnect" );

	//determine the type of special ammo to enable
	weapon  = self GetCurrentPrimaryWeapon();
	baseweapon = getRawBaseWeaponName( weapon );
		
	special_ammo_type =  undefined;
	perk = undefined;
	icon_index = undefined;	
	
	if ( self has_stun_ammo( baseweapon ) )
	{
		perk = "specialty_bulletdamage";
		icon_index = 1;
		special_ammo_type = "stun";
	}
	else if ( self has_ap_ammo( baseweapon ) )
	{
		perk = "specialty_armorpiercing";
		icon_index = 4;
		special_ammo_type = "piercing";
	}
	else if( self has_incendiary_ammo ( baseweapon ) )
	{
		special_ammo_type = "incendiary";
		icon_index = 2;
	}
	else if (  self has_explosive_ammo ( baseweapon ) )
	{
		special_ammo_type = "explosive";
		perk =  "specialty_explosivebullets";
		icon_index = 3;
	}
	else if (  self has_combined_ammo ( baseweapon ) )
	{
		special_ammo_type = "combined";
		icon_index = 5;
	}

	if ( isDefined ( special_ammo_type ) )
	{
		if ( isDefined ( perk ) )
			self givePerk( perk, false );
		
		if ( special_ammo_type == "combined" ) 
		{
			self.has_incendiary_ammo = true;
			self giveperk( "specialty_bulletdamage", false );
			self giveperk( "specialty_armorpiercing", false );				
			self giveperk( "specialty_explosivebullets", false );
		}	
		
		if ( special_ammo_type == "incendiary" ) 
			self.has_incendiary_ammo = true;
		
		self SetClientOmnvar("ui_alien_specialammo", icon_index );		
		
	}

}

/*
=============
///ScriptDocBegin
"Name: show_turret_icon()"
"Summary: Shows the turret icon on the hud"
"Module: Entity"
"CallOn: An entity"
"Example: player show_turret_icon()"
"SPMP: coop"
///ScriptDocEnd
=============
*/
show_turret_icon( value )
{
	self SetClientOmnvar( "ui_alien_turret", value );
}

/*
=============
///ScriptDocBegin
"Name: hide_turret_icon()"
"Summary: Hides both the icon & the counter for the turrets"
"Module: Entity"
"CallOn: An entity"
"Example: player hide_turret_icon()"
"SPMP: coop"
///ScriptDocEnd
=============
*/
hide_turret_icon()
{
	self SetClientOmnvar( "ui_alien_turret", -1 );
	self SetClientOmnvar( "ui_alien_turret_ammo", -1 );
}

/*
=============
///ScriptDocBegin
"Name: set_turret_ammocount( <ammo> )"
"Summary: Sets the amount of ammo to display for the turret ammo counter"
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <ammo>: "
"Example: player set_turret_ammocount( 200 ) "
"SPMP: coop"
///ScriptDocEnd
=============
*/

set_turret_ammocount( ammo )
{
	self SetClientOmnvar( "ui_alien_turret_ammo", ammo );
}

/*
=============
///ScriptDocBegin
"Name: add_hive_dependencies()"
"Summary: The given hive will not be able to be planted until all dependent hives are destroyed."
"Module: Alien"
"MandatoryArg: <hive> The hive in question."
"MandatoryArg: <dependent_hives> All hives that hive is dependent on"
"Example: result = add_hive_dependencies( "crater_lung", [ "lake_lung_1", "lake_lung_2" ] )"
"SPMP: coop"
///ScriptDocEnd
=============
*/
add_hive_dependencies( hive, dependent_hives )
{
	if ( !isDefined( level.hive_dependencies ) )
		level.hive_dependencies = [];
	
	level.hive_dependencies[ hive ] = dependent_hives;
}


should_snare( player )
{
	if ( !self is_alien_agent() || is_chaos_mode() )
		return false;
	
	if ( player maps\mp\alien\_persistence::is_upgrade_enabled( "no_snare_upgrade" ) )
		return false;		
		
	type = self get_alien_type();
	if ( type == "brute" || type == "minion" )
		return true;
	else
		return false;
}


buildAlienWeaponName( baseName, attachment1, attachment2, attachment3, attachment4, camo, reticle )
{
	//hack for current menu bug - remove before ship
	if ( isDefined( reticle ) && reticle != 0 && getAttachmentType( attachment1 ) != "rail" && getAttachmentType( attachment2 ) != "rail" && getAttachmentType( attachment3 ) != "rail" && getAttachmentType( attachment4 ) != "rail" )
	{
		reticle = undefined;
	}
			
	if ( attachment1 == "alienvksscope" )
		attachment1 = "scope";
	else if ( attachment1 == "alienl115a3vzscope" )
		attachment1 = "vzscope";
	if ( attachment2 == "alienvksscope" )
		attachment2 = "scope";
	else if ( attachment2 == "alienl115a3vzscope" )
		attachment2 = "vzscope";
	if ( attachment3 == "alienvksscope" )
		attachment3 = "scope";
	else if ( attachment3 == "alienl115a3vzscope" )
		attachment3 = "vzscope";
	if ( attachment4 == "alienvksscope" )
		attachment4 = "scope";
	else if ( attachment4 == "alienl115a3vzscope" )
		attachment4 = "vzscope";
	
	attachment1 = attachmentMap_toUnique( attachment1, baseName );
	attachment2 = attachmentMap_toUnique( attachment2, baseName );
	attachment3 = attachmentMap_toUnique( attachment3, baseName );
	attachment4 = attachmentMap_toUnique( attachment4, baseName );
	
	bareWeaponName = "";
	
	if ( IsSubStr( baseName, "iw5" ) || IsSubStr( baseName, "iw6" ) )
	{
		weaponName = baseName + "_mp";
		endIndex = baseName.size;
		bareWeaponName = GetSubStr( baseName, 4, endIndex );
	}
	else
	{
		weaponName = baseName;
	}
	
	weapClass = getWeaponClass( baseName );
	needScope = weapClass == "weapon_sniper" || baseName == "aliendlc23";
	
	attachments = [];

	if ( attachment1 != "none" )
		attachments[ attachments.size ] = attachment1;
	
	if ( attachment2 != "none" )
		attachments[ attachments.size ] = attachment2;
	
	if ( attachment3 != "none" )
		attachments[ attachments.size ] = attachment3;
	
	if ( attachment4 != "none" )
		attachments[ attachments.size ] = attachment4;
	
	// If the gun needs a scope and doesn't have a rail attachment
	if ( needScope )
	{
		hasAttachRail = false;
		foreach ( attachment in attachments )
		{
			if ( getAttachmentType( attachment ) == "rail" )
			{
				hasAttachRail = true;
				break;
			}
		}
		
		if ( !hasAttachRail )
		{
			attachments[ attachments.size ] = bareWeaponName + "scope";
		}
	}
	
	if ( IsDefined( attachments.size ) && attachments.size )
	{
		attachments = alphabetize( attachments );
	}
	
	foreach ( attachment in attachments )
	{
		weaponName += "_" + attachment;
	}

	if ( IsSubStr( weaponName, "iw5" ) || IsSubStr( weaponName, "iw6" ) )
	{
		weaponName = buildAlienWeaponNameCamo( weaponName, camo );
		weaponName = buildAlienWeaponNameReticle( weaponName, reticle );
	}
	else if ( !isValidAlienWeapon( weaponName + "_mp" ) )
	{
		weaponName = baseName + "_mp";
	}
	else
	{
		weaponName = buildALienWeaponNameCamo( weaponName, camo );
		weaponName = buildAlienWeaponNameReticle( weaponName, reticle );
		weaponName += "_mp";
	}
	
	return weaponName;
}

buildALienWeaponNameCamo( weaponName, camo )
{
	if ( !IsDefined( camo ) )
		return weaponName;
	if ( camo <= 0 )
		return weaponName;

	if ( camo < 10 )
		weaponName += "_camo0";
	else
		weaponName += "_camo";
	weaponName += camo;

	return weaponName;
}

buildAlienWeaponNameReticle( weaponName, reticle )
{
	if ( !IsDefined( reticle ) )
	{
		return weaponName;
	}
	
	// 0 and 1 are none and default
	if ( reticle <= 1 )
	{
		return weaponName;
	}
	
	// The index in the reticleTable is offset up one
	// because of the default category
	reticle--;

	weaponName += "_scope";
	weaponName += reticle;

	return weaponName;
}

isValidAlienWeapon( refString )
{
	if ( !isDefined( level.weaponRefs ) )
	{
		level.weaponRefs = [];

		foreach ( weaponRef in level.weaponList )
			level.weaponRefs[ weaponRef ] = true;
	}

	if ( isDefined( level.weaponRefs[ refString ] ) )
		return true;

	assertMsg( "Replacing invalid weapon/attachment combo: " + refString );
	
	return false;
}



_detachAll()
{
	if ( isDefined( self.hasRiotShield ) && self.hasRiotShield )
	{
		if ( self.hasRiotShieldEquipped )
		{
			self DetachShieldModel( "weapon_riot_shield_iw6", "tag_weapon_right" );
			self.hasRiotShieldEquipped = false;
		}
		else
		{
			self DetachShieldModel( "weapon_riot_shield_iw6", "tag_shield_back" );
		}
		
		self.hasRiotShield = false;
	}
	
	self detachAll();
}



hasRiotShield()
{
	result = false;
	
	weaponList = self GetWeaponsListPrimaries();
	foreach ( weapon in weaponList )
	{
		if ( maps\mp\gametypes\_weapons::isRiotShield( weapon ) )
		{
			result = true;
			break;
		}
	}
	return result;
}

trackRiotShield()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	self endon ( "faux_spawn" );
	
	self.hasRiotShield = self hasRiotShield();
	curweapon = self GetCurrentWeapon();
	self.hasRiotShieldEquipped = maps\mp\gametypes\_weapons::isRiotShield( curweapon );
	
	// note this function must play nice with _detachAll().
	
	if ( self.hasRiotShield )
	{
		if ( maps\mp\gametypes\_weapons::isRiotShield( self.primaryWeapon ) && maps\mp\gametypes\_weapons::isRiotShield( self.secondaryWeapon ) )
		{
			self AttachShieldModel( "weapon_riot_shield_iw6", "tag_weapon_right" );
			self AttachShieldModel( "weapon_riot_shield_iw6", "tag_shield_back" );
		}
		else if ( self.hasRiotShieldEquipped )
		{
			self AttachShieldModel( "weapon_riot_shield_iw6", "tag_weapon_right" );
		}
		else
		{
			self AttachShieldModel( "weapon_riot_shield_iw6", "tag_shield_back" );
		}
	}
	
	for ( ;; )
	{
		self waittill ( "weapon_change", newWeapon );
		
		//	need to check both, player can be 'juggernaut' by game setup default class specification now, not only killstreak
		if ( maps\mp\gametypes\_weapons::isRiotShield( newWeapon ) )
		{
			// defensive check in case we somehow get an extra "weapon_change"
			if ( self.hasRiotShieldEquipped )
				continue;
			
			// Both weapons are riotshields so down't swap
			if ( maps\mp\gametypes\_weapons::isRiotShield( self.primaryWeapon ) && maps\mp\gametypes\_weapons::isRiotShield( self.secondaryWeapon ) )
			{
				continue;
			}
			else if ( self.hasRiotShield )
			{
				self MoveShieldModel( "weapon_riot_shield_iw6", "tag_shield_back", "tag_weapon_right" );
			}
			else
			{
				self AttachShieldModel( "weapon_riot_shield_iw6", "tag_weapon_right" );
			}
			
			self.hasRiotShield = true;
			self.hasRiotShieldEquipped = true;
		}
		else if ( ( self IsMantling() ) && ( newWeapon == "none" ) )
		{
			// Do nothing, we want to keep that weapon on their arm.
		}
		else if ( self.hasRiotShieldEquipped )
		{
			Assert( self.hasRiotShield );
			self.hasRiotShield = self hasRiotShield();
			
			if ( self.hasRiotShield )
				self MoveShieldModel( "weapon_riot_shield_iw6", "tag_weapon_right", "tag_shield_back" );
			else
				self DetachShieldModel( "weapon_riot_shield_iw6", "tag_weapon_right" );
			
			self.hasRiotShieldEquipped = false;
		}
		else if ( self.hasRiotShield && !self hasRiotShield() )
		{
			// we probably just lost all of our weapons (maybe switched classes)
			self DetachShieldModel( "weapon_riot_shield_iw6", "tag_shield_back" );
			self.hasRiotShield = false;
		}
		else if ( !self.hasRiotShield && self hasRiotShield() )
		{
			// we just acquired a riot shield but our current weapon is something else
			self AttachShieldModel( "weapon_riot_shield_iw6", "tag_shield_back" );
			self.hasRiotShield = true;
		}
	}
}

tryAttach( placement ) // deprecated; hopefully we won't need to bring this defensive function back
{
	if ( !isDefined( placement ) || placement != "back" )
		tag = "tag_inhand";
	else
		tag = "tag_shield_back";
	
	attachSize = self getAttachSize();
	
	for ( i = 0; i < attachSize; i++ )
	{
		attachedTag = self getAttachTagName( i );
		if ( attachedTag == tag &&  self getAttachModelName( i ) == "weapon_riot_shield_iw6" )
		{
			return;
		}
	}
	
	self AttachShieldModel( "weapon_riot_shield_iw6", tag );
}

weapon_change_monitor()
{
	self endon( "disconnect" );
	self.has_special_weapon = false;
	self.is_holding_deployable = false;
	self.is_holding_crate_marker = false;
	self.should_track_weapon_fired = true;
	
	while ( 1 )
	{
		self waittill( "weapon_change",wpn );
		
		switch( wpn )
		{
		case "none":
		case "alienbomb_mp":
		case "mortar_detonator_mp":
		case "switchblade_laptop_mp":
		case "aliendeployable_crate_marker_mp":
		case "iw5_alienriotshield_mp":
		case "iw5_alienriotshield1_mp":
		case "iw5_alienriotshield2_mp":
		case "iw5_alienriotshield3_mp":
		case "iw5_alienriotshield4_mp":
			self.should_track_weapon_fired = false;
			break;
			
		default:
			self.should_track_weapon_fired = true;
			break;
		}
		
		if ( wpn == "none" )
			continue;
		
		self.has_special_weapon = false;
		self.is_holding_deployable = false;
		self.is_holding_crate_marker = false;
		
		switch ( wpn )
		{
			case "iw6_alienminigun_mp":
			case "iw6_alienminigun1_mp":
			case "iw6_alienminigun2_mp":
			case "iw6_alienminigun3_mp":
			case "iw6_alienminigun4_mp":
			case "iw6_alienmk32_mp":
			case "iw6_alienmk321_mp":
			case "iw6_alienmk322_mp":
			case "iw6_alienmk323_mp":
			case "iw6_alienmk324_mp":
			case "iw6_alienmaaws_mp":
				self.has_special_weapon = true;
				break;
				
			case "alienbomb_mp":
			case "alienclaymore_mp":
			case "bouncingbetty_mp":
			case "alientrophy_mp":
			case "deployable_vest_marker_mp":
			case "alienpropanetank_mp":
			case "alien_turret_marker_mp":
			case "switchblade_laptop_mp":
			case "mortar_detonator_mp":
				self.is_holding_deployable = true;
				break;
				
			case "aliendeployable_crate_marker_mp":
				self.is_holding_deployable = true;
				self.is_holding_crate_marker = true;
				break;
		}
		//check to make sure we really don't have a special weapon stashed 
		if ( !self.has_special_weapon )
		{
			primaries =  self GetWeaponsListPrimaries();
			foreach ( weapon in primaries )
			{
				switch ( weapon )
				{
					case "iw6_alienminigun_mp":
					case "iw6_alienminigun1_mp":
					case "iw6_alienminigun2_mp":
					case "iw6_alienminigun3_mp":
					case "iw6_alienminigun4_mp":
					case "iw6_alienmk32_mp":
					case "iw6_alienmk321_mp":
					case "iw6_alienmk322_mp":
					case "iw6_alienmk323_mp":
					case "iw6_alienmk324_mp":
					case "iw6_alienmaaws_mp":
						self.has_special_weapon = true;
				}
				if ( self.has_special_weapon )
					break;
			}
		}
		
	}
	
}

is_trap( ent )
{
	if ( !isDefined( ent ) )
		return false;

	//tesla trap kills
	if( isDefined( ent.tesla_type ) )
		return true;	

	if ( !isDefined ( ent.script_noteworthy ) && !isDefined ( ent.targetname ) )
		return false;
	
	if( isDefined ( ent.targetname ) && ( ent.targetname == "fence_generator" || ent.targetname == "puddle_generator" ) )
		return true;
	
	if ( isDefined( ent.script_noteworthy ) && ent.script_noteworthy == "fire_trap" )
		return true;
	
	return false;	
}
	
/*
=============
///ScriptDocBegin
"Name: zero_out_specialammo_clip( <weapon> )"
"Summary: forces a reload when aquiring special ammo"
"Module: Player"
"CallOn: A player"
"MandatoryArg: <weapon>: "
"Example: self zero_out_specialammo_clip( weapon )"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

zero_out_specialammo_clip( weapon )
{
	if ( is_akimbo_weapon( weapon ) )
	{
		self SetWeaponAmmoClip( weapon, 0, "left" );	 //this forces a reload
		self SetWeaponAmmoClip( weapon,0, "right" );
	}
	else
	{
		self SetWeaponAmmoClip(weapon, 0 );	 //this forces a reload
	}
}

/*
=============
///ScriptDocBegin
"Name: handle_existing_ammo( <special_ammo_weapon> , <weapon> , <ammo_type> )"
"Summary: handle existing non-specialized ammo when a user picks up special ammo"
"Module: Player"
"CallOn: A player"
"MandatoryArg: <special_ammo_weapon>: "
"MandatoryArg: <weapon>: "
"MandatoryArg: <ammo_type>: "
"Example: "
"SPMP: coop"
///ScriptDocEnd
=============
*/

handle_existing_ammo( special_ammo_weapon , weapon, ammo_type )
{

	if ( !isDefined ( self.stored_ammo ) )
		self.stored_ammo = [];
	
	if ( !isDefined( self.stored_ammo[special_ammo_weapon] ) )
	{
		self.stored_ammo[special_ammo_weapon] = spawnstruct();
	}
	
	// check to see if the player already has another type of special ammo loaded for this weapon, if so just replace it 
	should_store_ammo = should_store_ammo_check( ammo_type, special_ammo_weapon ); 
	
	//store the ammo	
	if ( should_store_ammo && !is_ammo_already_stored( special_ammo_weapon ) )
	{
		clipAmmo_stored = self GetWeaponAmmoClip( weapon );
		ammoStock_stored = self GetWeaponAmmoStock( weapon );
		
		if ( is_akimbo_weapon( weapon ) )
		{
			weapon_clip_left = self GetWeaponAmmoClip( weapon,"left" );
			weapon_clip_right = self GetWeaponAmmoClip ( weapon,"right" );
			clipAmmo_stored = weapon_clip_left + weapon_clip_right;
		}
	
		self.stored_ammo[special_ammo_weapon].clipammo 	= clipAmmo_stored; 
		self.stored_ammo[special_ammo_weapon].ammoStock = ammoStock_stored;
	}	
}

wait_for_player_to_dismount_turret()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	self setLowerMessage( "disengage_turret", &"ALIEN_COLLECTIBLES_DISENGAGE_TURRET",0 );
	while ( self IsUsingTurret() )
		wait .5;
	
	self clearLowerMessage( "disengage_turret" );
}

/*
=============
///ScriptDocBegin
"Name: disable_weapon_timeout()"
"Summary: Disables weapon, and re-enables weapon after timeout."
"Module: Alien"
"MandatoryArg: <timeout> time in seconds (float)."
"MandatoryArg: <notify_msg> notify message that uniquely identifies this instance of weapon disable (string)."
"Example: player disable_weapon_timeout( useTime + 0.05, "drill_repair_weapon_management" );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
disable_weapon_timeout( timeout, notify_msg )
{
	assert( isdefined( timeout ) && isdefined( notify_msg ) );

	self thread enable_weapon_after_timeout( timeout, notify_msg );
	self _disableWeapon();
}

enable_weapon_after_timeout( timeout, notify_msg )
{
	self endon( "death" );
	self endon( notify_msg ); // ends on enable_weapon_wrapper() with same message
	
	wait timeout;
	
	/#
		IPrintLnBold( "^1[WARNING] Disable weapon timed out!" );
	#/
	self _enableWeapon();
	//self thread enable_weapon_wrapper_check();
}


//enable weapon doesn't handle enabling a weapon that was taken away while it was disabled.
//enable_weapon_wrapper_check()
//{
//	self endon( "disconnect" );
//	self endon( "death" );
//	
//	waittill_any_timeout( 2, "weapon_change" ); // necessary for the weapons to be re-enabled after _enableweapons has happened
//		
//	if ( self GetCurrentPrimaryWeapon() == "none" )
//	{
//		primaries = self GetWeaponsListPrimaries();
//		self SwitchToWeapon ( primaries[0] );
//	}
//}

/*
=============
///ScriptDocBegin
"Name: enable_weapon_wrapper()"
"Summary: Enables weapon and notifies."
"Module: Alien"
"MandatoryArg: <notify_msg> notify message that uniquely identifies this instance of weapon enable, to reset timeouts called earlier (string)."
"Example: player enable_weapon_wrapper( "drill_repair_weapon_management" );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
enable_weapon_wrapper( notify_msg )
{
	assert( isdefined( notify_msg ) );
	
	self notify( notify_msg ); // kills timeout with the same message
	self _enableWeapon();
	//self thread enable_weapon_wrapper_check();
}

/*
=============
///ScriptDocBegin
"Name: GetMultipleRandomIndex( <weights>, <num> )"
"Summary: Return an array of <num> random array index based on the probability weights assigned to each index."
"Module: Alien"
"MandatoryArg: <weights> Array of probability weights. <num> the number of index that are returned"
"Example: randIndexArray = GetMultipleRandomIndex( animWeights, 2 );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
GetMultipleRandomIndex( weights, numOfIndex )
{
	Assert( weights.size >= numOfIndex );
	result = [];
	
	for( i = 0; i < numOfIndex; i++ )
	{
		randomIndex = GetRandomIndex( weights );
		result[result.size] = randomIndex;
		
		weights = array_remove_index( weights, randomIndex, true );
	}
	
	return result;
}

/*
=============
///ScriptDocBegin
"Name: array_remove_index( <array> , <index>, <bKeepOriginalIndex> )"
"Summary: Removes the element in the array with this index, resulting array order is intact."
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <array>, <index> "
"OptionalArg: <bKeepOriginalIndex>: If true, the new array will keep all the original index from the old array "
"Example: locations = array_remove_index( locations, 3, true );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
array_remove_index( array, index, keepOriginalIndex )
{
	newArray = [];
	
	foreach ( arrayIndex, value in array )
	{
		if ( arrayIndex == index )
			continue;
		
		if ( is_true( keepOriginalIndex ) )
			newArray_index = arrayIndex;
		else
			newArray_index = newArray.size;
		
		newArray[newArray_index] = value;
	}
	
	return newArray;
}

/*
=============
///ScriptDocBegin
"Name: GetRandomIndex( <weights> )"
"Summary: Return a random array index based on the probability weights assigned to each index."
"Module: Alien"
"MandatoryArg: <weights> Array of probability weights"
"Example: randIndex = GetRandomIndex( animWeights );"
"SPMP: multiplayer"
///ScriptDocEnd
=============
*/
GetRandomIndex( weights )
{
	weightSum = 0;
	foreach ( weight in weights )
		weightSum += weight;
	randIndex = RandomIntRange( 0, weightSum );
	weightSum = 0;
	foreach ( i, weight in weights )
	{
		weightSum += weight;
		if ( randIndex <= weightSum )
			return i;
	}
	assertmsg( "should not get here." );
	return 0;
}

/*
=============
///ScriptDocBegin
"Name: _enableAdditionalPrimaryWeapon()"
"Summary: allows the player to carry an additional primary weapon "
"Module: Entity"
"CallOn: A Player"
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

_enableAdditionalPrimaryWeapon()
{
	if ( !IsDefined( self.numAdditionalPrimaries ) )
	{
		self.numAdditionalPrimaries = 0;
	}
	
	self.numAdditionalPrimaries++;
}


/*
=============
///ScriptDocBegin
"Name: is_incompatible_weapon( <weapon> )"
"Summary: check to see if this weapon is compatible with standard ammo types"
"Module: Entity"
"CallOn: An entity"
"MandatoryArg: <weapon>: "
"Example: "
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/

is_incompatible_weapon( weapon )
{
	//for special weapons ( i.e. unique weapons for each level )
	if ( isDefined( level.ammoIncompatibleWeaponsList ) )
	{
		if ( array_contains ( level.ammoIncompatibleWeaponsList, weapon ) )
			return true;
	}
	
	return false;
}

is_door()
{
	return self.targetname == "stronghold_door_loc";
}

is_door_hive()
{
	return is_true ( level.hive_is_really_a_door  );
}

has_tag( model, tag )
{
	partCount = GetNumParts( model );
	for ( i = 0; i < partCount; i++ )
	{
		if( toLower( GetPartName( model, i)) == toLower( tag ))
			return true;
	}
	return false;
}

level_uses_MAAWS()
{
	switch ( level.script )
	{
		case "mp_alien_beacon":
			return true;
	
		default:
			break;
	}
	return false;	
}

is_flaming_stowed_riotshield_damage( sMeansOfDeath, sWeapon, eInflictor )
{
	if( isDefined( einflictor ) && is_trap( eInflictor ) )
		return false;
	
	if ( sMeansOfDeath == "MOD_UNKNOWN" && sWeapon != "none" )
		return true;
	else
		return false;	
}

ark_attachment_transfer_to_locker_weapon( fullweaponname, current_attachments, should_take_weapon )
{
    has_ark_attachment = undefined;

    weaponAttachments = getWeaponAttachmentsBaseNames( fullweaponname );
	if(isdefined(weaponAttachments[0]))
		attachment1 = weaponAttachments[0];
	else
		attachment1 = "none";
	if(isdefined(weaponAttachments[1]))
		attachment2 = weaponAttachments[1];
	else
		attachment2 = "none";
	if(isdefined(weaponAttachments[2]))
		attachment3 = weaponAttachments[2];
	else
		attachment3 = "none";
	if(isdefined(weaponAttachments[3]))
		attachment4 = weaponAttachments[3];
	else
		attachment4 = "none";
	
 	if ( is_true( should_take_weapon ) )
	{
		foreach( piece in current_attachments )
	   	{
	  		piece = attachmentMap_toBase( piece );
			if ( piece == "alienmuzzlebrake"  )
			{
				has_ark_attachment = true;
				break;
			}
		}				
		if ( is_true( has_ark_attachment ) )
		{
			locker_weapon_attachments = getWeaponAttachments( fullweaponname );
			
			for ( i=0; i < locker_weapon_attachments.size; i++ )
		   	{
		 		locker_weapon_attachments[i] = replace_barrelrange_with_ark( locker_weapon_attachments[i] );
				if ( i == 0 )
		 			attachment1 = attachmentMap_toBase ( locker_weapon_attachments[i] );
		 		if ( i == 1 )
		 			attachment2 = attachmentMap_toBase ( locker_weapon_attachments[i] );
		 		if ( i == 2 )
		 			attachment3 = attachmentMap_toBase ( locker_weapon_attachments[i] );
		 		if ( i == 3 )
		 			attachment4 = attachmentMap_toBase ( locker_weapon_attachments[i] );
		   	}
		}
 	}
 	
 	baseweapon = GetWeaponBaseName( fullweaponname );
	weaponname = strip_suffix( baseweapon, "_mp" );

	camo = RandomIntRange( 1, 10 );
	
   	//new-type camos don't work for these guns
	if ( IsSubStr( baseweapon,"alienfp6" ) 
    || IsSubStr( baseweapon, "alienmts255" ) 
    || IsSubStr( baseweapon, "aliendlc12" ) 
    || IsSubStr( baseweapon, "aliendlc13" ) 
    || IsSubStr( baseweapon, "aliendlc14" )
    || IsSubStr( baseweapon, "aliendlc15" )
    || IsSubStr( baseweapon, "aliendlc23" ) 
    || IsSubStr( baseweapon, "altalienlsat" ) 
    || IsSubStr( baseweapon, "altaliensvu" ) 
    || IsSubStr( baseweapon, "altalienarx" )
   	|| IsSubStr( baseweapon, "arkalienr5rgp" )
   	|| IsSubStr( baseweapon, "arkaliendlc15" )
   	|| IsSubStr( baseweapon, "arkaliendlc23" )
   	|| IsSubStr( baseweapon, "arkalienk7" )
   	|| IsSubStr( baseweapon, "arkalienuts15" )
   	|| IsSubStr( baseweapon, "arkalienmaul" )
   	|| IsSubStr( baseweapon, "arkalienmk14" )
   	|| IsSubStr( baseweapon, "arkalienimbel" )
   	|| IsSubStr( baseweapon, "arkalienkac" )
   	|| IsSubStr( baseweapon, "arkalienameli" ) )	
		camo = 0;

	
	reticle = RandomIntRange( 1, 7 );
    
    weapon_string = undefined;
    
    if ( attachment1 != "thermal" &&
         attachment1 != "thermalsmg" &&
         attachment2 != "thermal" &&
         attachment2 != "thermalsmg" &&
         attachment3 != "thermal" &&
         attachment3 != "thermalsmg" &&
         attachment4 != "thermal" &&
		 attachment4 != "thermalsmg" &&
		 baseweapon != "iw6_aliendlc23_mp")
    	fullweaponname = maps\mp\alien\_utility::buildAlienWeaponName( weaponname, attachment1, attachment2, attachment3, attachment4, camo, reticle );
    else
		fullweaponname = maps\mp\alien\_utility::buildAlienWeaponName( weaponname, attachment1, attachment2, attachment3, attachment4, camo );

 	self.locker_weapon = fullweaponname;
	return fullweaponname;		
}

	
replace_barrelrange_with_ark( attachment )
{
	if( isDefined( attachment ) && string_starts_with( attachment, "barrelrange" ) )
	   return "alienmuzzlebrake";
	else
		return attachment;
}

return_weapon_with_like_attachments( fullweaponname, current_attachments )
{
    baseweapon = GetWeaponBaseName( fullweaponname );
    player = self;
    attachment1 = "none";
    attachment2 = "none";
    attachment3 = "none";
    attachment4 = "none";
    weaponclass = getWeaponClass( baseweapon );
    possible_attachments =  maps\mp\alien\_pillage::get_possible_attachments_by_weaponclass( weaponclass , baseweapon );

    valid_attachments = [];

  	foreach( piece in current_attachments )
   	{
  		piece = attachmentMap_toBase( piece );

  		if ( array_contains( possible_attachments, piece ) )
  		{
  			if ( player maps\mp\alien\_persistence::is_upgrade_enabled( "keep_attachments_upgrade" ) )  
  				valid_attachments = array_add( valid_attachments, piece );
  			else if ( piece == "alienmuzzlebrake"  )
  				valid_attachments = array_add( valid_attachments, piece );
  		}
   	} 
 	
   	if ( valid_attachments.size > 0 && valid_attachments.size < 5 )  //only allow 4 attachments
   	{
	   	for ( i=0; i < valid_attachments.size; i++ )
	   	{
	 		if ( i == 0 )
	 			attachment1 = valid_attachments[i];
	 		if ( i == 1 )
	 			attachment2 = valid_attachments[i];
	 		if ( i == 2 )
	 			attachment3 = valid_attachments[i];
	 		if ( i == 3 )
	 			attachment4 = valid_attachments[i];
	   	}
 	}
	   	
    weaponname = strip_suffix( baseweapon, "_mp" );    
	
   	base_scope_attachment = base_scope_weapon_attachment( weaponname );
   	
   	if( isDefined( base_scope_attachment ) )
   	{
   		switch( valid_attachments.size + 1 )
   		{
   			case 1:
   				attachment1 = base_scope_attachment;
   				break;
   			case 2:
   				attachment2 = base_scope_attachment;
   				break;
   			case 3:
   				attachment3 = base_scope_attachment;
   				break;
   			case 4:
   				attachment4 = base_scope_attachment;
   				break;   				
   		}
   	}
    
    newweapon = buildAlienWeaponName( weaponname, attachment1, attachment2, attachment3, attachment4 );

    return newweapon;
}


base_scope_weapon_attachment( weaponname )
{
	switch( weaponname )
	{
		case "iw6_arkalienvks":
		case "iw6_alienvks":	
			return "alienvksscope";
		case "iw6_arkalienusr":
		case "iw6_alienusr":	
			return "usrvzscope";
		case "iw6_arkaliendlc23":
		case "iw6_aliendlc23":	
			return "dlcweap02scope";
		case "iw6_alienl115a3":
			return "alienl115a3scope";
		default:
			break;
	}
	
}

can_hypno( attacker, petTrapKill, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, inflictor )
{
	if ( isDefined( self.cannotHypno ) && self.cannotHypno )
		return false;
	
	switch ( self.alien_type )
	{
		case "goon":
		case "brute":
		case "spitter":
		case "locust":
		case "seeder":
			return true;
		case "elite":
			if ( attacker maps\mp\alien\_persistence::is_upgrade_enabled( "hypno_rhino_upgrade" ) || petTrapKill ) 
				return true;
		default:
			return false;
	}
}


has_fragile_relic_and_is_sprinting()
{
	if ( self maps\mp\alien\_prestige::prestige_getSlowHealthRegenScalar() != 1.0 && self IsSprinting() )
		return true;
	else
		return false;	
}

update_player_initial_spawn_info( coordinate, angles )
{
/#  AssertEx( isDefined( coordinate) && isDefined( angles ), "Both coordinate and angles need to be defined" );  #/
	
	level.playerInitialSpawnOriginOverride = coordinate;
	level.playerInitialSpawnAnglesOverride = angles;	
}

get_player_initial_spawn_origin()
{
	return level.playerInitialSpawnOriginOverride;
}

get_player_initial_spawn_angles()
{
	return level.playerInitialSpawnAnglesOverride;
}

has_pistols_only_relic_and_no_deployables()
{
	if ( self  maps\mp\alien\_prestige::prestige_getPistolsOnly() == 1 && self maps\mp\alien\_prestige::prestige_getNoDeployables() == 1 )
		return true;
	else
		return false;	
}


get_current_pistol()
{
	primaries = self GetWeaponsListPrimaries();

	foreach ( weapon in primaries )
	{
		weap_class = getWeaponClass( weapon );
		if ( weap_class == "weapon_pistol" )
		{
			return weapon;
		}			
	}
}

is_idle_state_locked()
{
	return ( self.currentAnimState == "idle" && IsDefined( self.idle_state_locked ) && self.idle_state_locked );
}

return_nerf_scaled_ammo( new_weapon_string )
{
	//checks the nerf for min_ammo and returns the amount
	nerf_min_ammo_scalar = self maps\mp\alien\_deployablebox_functions::check_for_nerf_min_ammo();	
	max_stock = WeaponMaxAmmo( new_weapon_string );
	return int( max_stock * nerf_min_ammo_scalar );	
}

weapon_has_alien_attachment( weaponName, achievement_flag, eAttacker )
{
	if ( !IsDefined( weaponName ) 
		|| weaponName == "none" 
		|| WeaponInventoryType( weaponName ) != "primary" 
		|| weaponclass( weaponName ) == "item" 
		|| weaponclass( weaponName ) == "rocketlauncher" 
		|| weaponclass( weaponName ) == "none" 
	)
	{
		return false;
	}
	
	if ( is_true( achievement_flag ) && self is_holding_pistol( eAttacker ) )
		return false;
		
	weaponAttachments = getWeaponAttachmentsBaseNames( weaponName );
	foreach ( attachment in weaponAttachments )
	{
		if ( attachment == "alienmuzzlebrake" || attachment == "alienmuzzlebrakesg" || attachment == "alienmuzzlebrakesn" )
			return true;
	}
	return false;
}

is_holding_pistol( eAttacker )
{
	cur_weapon = eAttacker GetCurrentPrimaryWeapon();
	if ( getWeaponClass( cur_weapon ) == "weapon_pistol" )
		return true;
	else
		return false;
}


setup_class_nameplates()
{
	perk = self maps\mp\alien\_persistence::get_selected_perk_0();
	material = undefined;
	switch ( perk )
	{
		case "perk_bullet_damage":
			material = "player_name_bg_weapon_specialist";
			break;
		case "perk_health":
			material = "player_name_bg_tank";
			break;
		case "perk_rigger":
			material = "player_name_bg_engineer";
			break;
		case "perk_medic":
			material = "player_name_bg_medic";
			break;
		case "perk_none":
			material = "player_name_bg_mortal";
			break;
	}
	if( isDefined( material ) )
		self SetNameplateMaterial( material, material );	
}