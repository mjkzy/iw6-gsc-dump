#include maps\mp\_utility;
#include common_scripts\utility;
#include common_scripts\_fx;

#using_animtree("animated_props");


bridge_main()
{
	bridge_precache();
	
	waitframe();
	
	if ( GetDvar( "r_reflectionProbeGenerate" ) == "1" )
		return;

	//Create and initialize the device:
	level.bridge_device = SpawnStruct();
	level.bridge_device maps\mp\mp_ca_red_river_bridge_device::bridge_device_init();
	
	maps\mp\mp_ca_red_river_bridge_device::bridge_extras_init( level.bridge_device );
	
	level.bridge = SpawnStruct();
	level.bridge bridge_init();
	
	level.bridge thread bridge_wait_explode();
	
	/#
	debugEvents();
	#/
}

bridge_precache()
{	
	PrecacheMpAnim("mp_ca_red_river_bridge_01");
	PrecacheMpAnim("mp_ca_red_river_bridge_02");
	PrecacheMpAnim("mp_ca_red_river_bridge_03");
}

bridge_init()
{
	self.bridge_anim_time = 0.0;
	self.bridge_anim_time = max( self.bridge_anim_time, GetAnimLength( %mp_ca_red_river_bridge_01 ) );
	self.bridge_anim_time = max( self.bridge_anim_time, GetAnimLength( %mp_ca_red_river_bridge_02 ) );
	self.bridge_anim_time = max( self.bridge_anim_time, GetAnimLength( %mp_ca_red_river_bridge_03 ) );
	
	self.bridge_wholeEnts = GetEntArray( "bridge_whole", "targetname" );
	self.bridge_destroyedEnts = GetEntArray( "bridge_destroyed", "targetname" );
	
	bridge_hideParts( self.bridge_destroyedEnts );
	
	level.bridge_animated_models = GetEntArray( "bridge_animated_model", "targetname" );
	bridge_hideParts( level.bridge_animated_models );
	
	level.bridge_scriptables = GetScriptableArray( "bridge_animated_model", "targetname" );
	foreach ( part in level.bridge_scriptables )
	{
		part Hide();
	}
	
	// set up path node blockers
	level.bridgePathNodes = GetEnt( "bridgePathNodes", "targetname" );
	clearPath( level.bridgePathNodes );
	
	level.destroyPathNodes = GetEnt( "destroyPathNodes", "targetname" );
	blockPath( level.destroyPathNodes );
}

bridge_showParts( partArray )
{
	foreach ( part in partArray )
	{
		part Show();
		part Solid();
	}
}

bridge_hideParts( partArray )
{
	foreach ( part in partArray )
	{
		part Hide();
		part NotSolid();
		part maps\mp\_movers::notify_moving_platform_invalid();
	}
}

bridge_wait_explode()
{
	level waittill( "bridge_trigger_explode" );

	level.bridge_device notify("bridge_exploded");
	
	//thread sfx here
	playSoundOnPlayers ("scn_bridge_explo_2d");	
	thread play_sound_in_space ("scn_bridge_explo_boom_left", (-484, -733, 90));
	thread play_sound_in_space ("scn_bridge_explo_boom_right", (143, -824, 60));	
	
	bridge_play_fx();
	
	wait 0.15;
	
	//Show the destroyed state
	if (IsDefined(self.bridge_destroyedEnts))
	{
		bridge_showParts( self.bridge_destroyedEnts );
	}
	
	//Hide the whole state:
	if (IsDefined(self.bridge_wholeEnts))
	{
		bridge_hideParts( self.bridge_wholeEnts );
	}
	
	// block path nodes
	clearPath( level.destroyPathNodes );
	blockPath( level.bridgePathNodes );
	
	//Show the animated model(s) and play the animation(s)
	foreach( animated_model in level.bridge_animated_models )
	{	
		animated_model Show();
		animated_model Solid();
		
		if ( IsDefined( animated_model.animation ) )
		{
			animated_model ScriptModelPlayAnim( animated_model.animation );
		}
	}
	
	foreach( scriptable in level.bridge_scriptables )
	{
		scriptable Show();
		scriptable SetScriptablePartState( 0, "destroyed" );
	}
	
	//Wait for animation to complete.
	wait ( self.bridge_anim_time );
}

CONST_BRIDGE_EXPLODER_ONE_SHOT_ID = 12;
CONST_BRIDGE_EXPLODER_LOOPING_ID = 11;
bridge_play_fx()
{
	// "explosion trigger" = id #11
	exploder( CONST_BRIDGE_EXPLODER_LOOPING_ID ); // 
	exploder( CONST_BRIDGE_EXPLODER_ONE_SHOT_ID );
	
	playLoopSoundAtPos( (-941.022, -712.704, -133.546), "emt_red_fire_explo_med1_lp" );
	playLoopSoundAtPos( (-389.143, -886.295, -174.497), "emt_red_fire_explo_med2_lp" );
	playLoopSoundAtPos( (-283.364, -531.226, 73.5775), "emt_red_fire_explo_med3_lp" );
	playLoopSoundAtPos( (103.789, -379.687, 116.523), "emt_red_fire_explo_lrg_pole_lp" );
	playLoopSoundAtPos( (244.235, -335.982, 33.3856), "emt_red_fire_explo_lrg_pole_lp" );
	playLoopSoundAtPos( (-371.551, -1141.23, 27.313), "emt_red_fire_explo_sm_lp" );
	
	level thread bridge_fx_waitForConnections();
}

// this is bad; would be better to just have the effect and attach the sound to it;
playLoopSoundAtPos( pos, sound )
{
	play_loopsound_in_space( sound, pos );
}

bridge_fx_waitForConnections()
{
	level endon ( "game_ended" );
	
	while ( true )
	{
		level waittill( "connected", player );
		
		player childthread bridge_fx_playOnConnection();
	}
}

bridge_fx_playOnConnection()
{
	self endon ( "disconnect" );
	
	// wait till ready
	self waittill_any( "joined_team", "luinotifyserver" );
	
	// start the effect in the past, to skip past the initial explosion
	exploder( CONST_BRIDGE_EXPLODER_LOOPING_ID, self, 0 );	// not sure why this is not working? using example from boneyard_ns
	
	// these values are copied over from mp_ca_red_river_bridge_device.gsc
	if( IsDefined( level.nukeDetonated ) )
	{
		self VisionSetNakedForPlayer( "", 0 );
		maps\mp\killstreaks\_nuke::setNukeAftermathVision( 0 );
	}
	else
	{
		self VisionSetNakedForPlayer( "mp_ca_red_river_exploded", 0 );
	}
}

clearPath( blocker )	// self == elevator
{
	if ( IsDefined( blocker ) )
	{
		blocker ConnectPaths();
		blocker Hide();
		blocker NotSolid();
	}
}

blockPath( blocker )
{
	if ( IsDefined( blocker ) )
	{
		blocker Show();
		blocker Solid();
		blocker DisconnectPaths();
	}
}

/#
debugEvents()
{
	SetDvarIfUninitialized( "scr_dbg_tremor_interval", 0 );
	SetDvarIfUninitialized( "scr_dbg_fx", 0 );
	SetDvarIfUninitialized( "scr_dbg_bridge", 0 );
	
	while ( true )
	{
		checkDbgDvar( "scr_dbg_fx", ::dbgFireFx, undefined );
		checkDbgDvar( "scr_dbg_bridge", undefined, "bridge_trigger_explode" );
		
		wait ( 0.1 );
	}
}

checkDbgDvar( dvarName, callback, notifyStr )
{
	if ( GetDvarInt( dvarName ) > 0 )
	{
		if ( IsDefined( callback ) )
			[[ callback ]]( GetDvarInt( dvarName ) );
		
		if ( IsDefined( notifyStr ) )
			level notify( notifyStr );
		
		SetDvar( dvarName, 0 );
	}
}

dbgFireFx( fxId )
{
	exploder( fxId );
}
#/