/*
 * How to use this script:
 * You need an exploder which creates the FX of the bats flying,
 * and an animation which moves "tag_attach" along the flight path (for the sound).
 * You need a trigger with a targetname, to detect if players are close to the bats spawn location.
 * Then, just call vfxBatCaveWaitInit() with all those things.
 */
#include common_scripts\utility;

VFX_BAT_COOLDOWN = 60;

/*
=============
///ScriptDocBegin
"Name: vfxBatCaveWaitInit( <triggername> , <exploderID> , <audioAnim> , <pos> , <emptyRoomCooldown> )"
"Summary: Sets up a bat colony to detect players and play a bat exploder when a player fires his/her weapon nearby."
"Module: "
"CallOn: "
"MandatoryArg: <triggername>: Targetname of a trigger that will detect players."
"MandatoryArg: <exploderID>: ID of the exploder to be triggered."
"OptionalArg: <audioAnim>: Animation with 'tag_attach' moving along the path of the EFX, for a sound to be attached to."
"OptionalArg: <pos>: Position of the exploder, for the animation to be placed at."
"OptionalArg: <emptyRoomCooldown>: Time the trigger must be undisturbed before the exploder can fire again. If undefined or 0, the exploder can fire periodically even the trigger has never been empty."
"Example: thread vfxBatCaveWaitInit( "bats_1", 1, "bats_flyaway_1", (-2028, 464, 413) );"
"SPMP: both"
///ScriptDocEnd
=============
*/

vfxBatCaveWaitInit( triggername, exploderID, audioAnim, pos, emptyRoomCooldown )
{
	if ( !IsDefined( emptyRoomCooldown ) )
		emptyRoomCooldown = 0;
	
	level endon( "game_ended" );
	
	// get the trigger
	trigger = GetEnt( triggername, "targetname" );
	if ( IsDefined( trigger ) )
	{
		trigger childthread vfxBatCaveTrigger( exploderID, audioAnim, pos );
		trigger childthread vfxBatCaveWatchForEmpty( emptyRoomCoolDown );
		
		while ( true )
		{
			trigger waittill( "trigger", player );
			
			trigger thread vfxBatCaveWatchPlayerState( player );
		}
	}
}

vfxBatCaveWatchPlayerState( player )	// self == bat trigger
{
	// if any other player starts the bats, stop checking 
	self endon( "batCaveTrigger" );
	
	player endon( "death" );
	player endon( "disconnect" );
	
	// make sure we aren't already runnning one
	player notify( "batCaveExit" );
	player endon( "batCaveExit" );
	
	self childthread vfxBatCaveWatchPlayerWeapons( player );
	
	// this detects if the player has exited the trigger
	while ( player IsTouching( self ) )
	{
		waitframe();
		self.lastTouchedTime = GetTime();
	}

	player notify( "batCaveExit" );
}

vfxBatCaveWatchPlayerWeapons( player )
{
	player waittill( "weapon_fired" );
	self notify ( "batCaveTrigger" );
}

vfxBatCaveWatchForEmpty( emptyRoomCoolDown )
{
	self.lastTouchedTime = GetTime();
	self.batCaveReset = true;
	while ( true )
	{
		waitframe();
		if ( self.lastTouchedTime + emptyRoomCoolDown <= GetTime() ) {
			self.batCaveReset = true;
		}
	}
}

vfxBatCaveTrigger( exploderID, audioAnim, pos )
{
	/#
	SetDvarIfUninitialized( "scr_dbg_batcave_cooldown", VFX_BAT_COOLDOWN );
	#/
	
	while ( true )
	{
		self waittill( "batCaveTrigger" );
		
		if ( self.batCaveReset ) {
			vfxBatsFly( exploderID, audioAnim, pos );
			self.batCaveReset = false;
			
			waitTime = VFX_BAT_COOLDOWN;
			/#
			waitTime = GetDvarInt( "scr_dbg_batcave_cooldown" );
			#/
			
			wait ( waitTime );
		}
	}
}

// Plays the bats effect and moving sound
vfxBatsFly(exploderID, audioAnim, pos) 
{
	exploder(exploderID);	// It's become pretty pointless to do these as exploders, but it works, so I'm leaving it for now.

	// Play a sound that moves with the bats as they fly.
	if ( IsDefined(audioAnim) && IsDefined(pos) ) {
		soundrig = Spawn( "script_model", pos );
		soundrig SetModel( "vulture_circle_rig" );
		soundrig ScriptModelPlayAnim( audioAnim );
		dummy = Spawn( "script_model", soundrig GetTagOrigin( "tag_attach" ) );
		dummy LinkTo( soundrig, "tag_attach" );
		wait(0.1); // Without this the sound won't play. Because the tag is inside the wall?
		dummy PlaySoundOnMovingEnt( "scn_mp_swamp_bat_cave_big" );
	}
}

