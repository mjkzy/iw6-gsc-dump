#include common_scripts\utility;
#include maps\mp\_utility;

// the nuke ended the game in MW2, for MW3 it will be an MOAB, not end the game but kill the other team and emp them for 60 seconds, it will also change the visionset for the level

init()
{
	level.nukeVisionSet = "alien_nuke";
	level.nukeVisionSetFailed = "alien_nuke_blast";
	
	if ( level.script == "mp_alien_last" )
	{
		level._effect[ "nuke_flash" ] = loadfx( "vfx/moments/alien/player_nuke_flash_alien_last" );
	}
	else
	{
		level._effect[ "nuke_flash" ] = loadfx( "fx/explosions/player_death_nuke_flash_alien" );
	}
	
	SetDvarIfUninitialized( "scr_nukeTimer", 10 );
	SetDvarIfUninitialized( "scr_nukeCancelMode", 0 );
	
	level.nukeTimer = getDvarInt( "scr_nukeTimer" );
	level.cancelMode = getDvarInt( "scr_nukeCancelMode" );

	level.nukeInfo = spawnStruct();
	level.nukeInfo.xpScalar = 2;
	level.nukeDetonated = undefined;

	level thread onPlayerConnect();
}

delaythread_nuke( delay, func )
{
	level endon ( "nuke_cancelled" );

	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( delay );
	
	thread [[ func ]]();
}

// used in aliens mode
doNukeSimple()
{
	level.nukeInfo.player = self;
	level.nukeInfo.team = self.pers["team"];
	level.nukeIncoming = true;

	level thread delaythread_nuke( (level.nukeTimer - 3.3), ::nukeSoundIncoming );
	level thread delaythread_nuke( level.nukeTimer, ::nukeSoundExplosion );
	level thread delaythread_nuke( level.nukeTimer, ::nukeSlowMo );
	level thread delaythread_nuke( level.nukeTimer, ::nukeEffects );
	level thread delaythread_nuke( (level.nukeTimer + 0.25), ::nukeVision );
	level thread delaythread_nuke( (level.nukeTimer + 1.5), ::nukeDeath );
	//level thread delaythread_nuke( (level.nukeTimer + 1.5), ::nukeEarthquake );
	
	// need objects to play sound off of, i'm keeping them on level so we don't spawn them more than once if multiple nukes get called in a match
	if( !IsDefined( level.nuke_soundObject ) )
	{
		level.nuke_soundObject = Spawn( "script_origin", (0,0,1) );
		level.nuke_soundObject hide();
	}
}

nukeDeath()
{
	level notify( "nuke_death" );
}

nukeSoundIncoming()
{
	level endon ( "nuke_cancelled" );

	if( IsDefined( level.nuke_soundObject ) )
		level.nuke_soundObject PlaySound( "nuke_incoming" );
}

nukeSoundExplosion()
{
	level endon ( "nuke_cancelled" );

	if( IsDefined( level.nuke_soundObject ) )
	{
		level.nuke_soundObject PlaySound( "nuke_explosion" );
		level.nuke_soundObject PlaySound( "nuke_wave" );
	}
}

nukeEffects()
{
	level endon ( "nuke_cancelled" );

	level.nukeDetonated = true;

	foreach( player in level.players )
	{
		playerForward = anglestoforward( player.angles );
		playerForward = ( playerForward[0], playerForward[1], 0 );
		playerForward = VectorNormalize( playerForward );
	
		nukeDistance = 5000;

		nukeLoc = player.origin + ( playerForward * nukeDistance );
		// nuke location override: from aliens
		if ( isdefined( level.nukeLoc ) )
			nukeLoc = level.nukeLoc;
		
		nukeAngles = ( 0, (player.angles[1] + 180), 90 );
		// nuke angle override: from aliens
		if ( IsDefined( level.nukeAngles ) )
			nukeAngles = level.nukeAngles;
		
		nukeEnt = Spawn( "script_model", nukeLoc );
		nukeEnt setModel( "tag_origin" );
		nukeEnt.angles = nukeAngles;
		
		nukeEnt thread nukeEffect( player );
	}
}

nukeEffect( player )
{
	level endon ( "nuke_cancelled" );

	player endon( "disconnect" );

	waitframe();
	PlayFXOnTagForClients( level._effect[ "nuke_flash" ], self, "tag_origin", player );
}

nukeSlowMo()
{
	level endon ( "nuke_cancelled" );

	//SetSlowMotion( <startTimescale>, <endTimescale>, <deltaTime> )
	SetSlowMotion( 1.0, 0.25, 0.5 );
	level waittill( "nuke_death" );
	SetSlowMotion( 0.25, 1, 2.0 );
}

nukeVision()
{
	level endon ( "nuke_cancelled" );

	level.nukeVisionInProgress = true;
	
	// level waittill( "nuke_death" );

	transition_time = 0.75;
	foreach ( player in level.players )
	{
		// if spectating player is spectating someone who escaped
		if ( isdefined( player.sessionstate ) && player.sessionstate == "spectator" )
		{
			spectated_player = player GetSpectatingPlayer();
			if ( isdefined( spectated_player ) )
			{
				// go with what spectated player is using
				if ( ( isdefined( spectated_player.nuke_escaped ) && spectated_player.nuke_escaped ) )
					player set_vision_for_nuke_escaped( transition_time );
				else
					player set_vision_for_nuke_failed( transition_time );
			}
			else
			{
				// use failed vision if player isnt spectating anyone, meaning he could be looking at nuke from bad angle
				player set_vision_for_nuke_failed( transition_time );
			}
		}
		else
		{
			if ( ( isdefined( player.nuke_escaped ) && player.nuke_escaped ) )
				player set_vision_for_nuke_escaped( transition_time );
			else
				player set_vision_for_nuke_failed( transition_time );
		}
	}
	
	fog_nuke(transition_time);
	// restore_fog( 0 );
	// VisionSetPain( level.nukeVisionSet );
}

// Julian - Kyle, you may use the following functions to replace vision change with your fx
set_vision_for_nuke_escaped( transition_time )
{
	self VisionSetNakedForPlayer( level.nukeVisionSet, transition_time );
	self VisionSetPainForPlayer( level.nukeVisionSet );
}

set_vision_for_nuke_failed( transition_time )
{
	PlayFXOnTagForClients( level._effect[ "vfx/moments/alien/nuke_fail_screen_flash" ], self, "tag_eye",self);
	self VisionSetNakedForPlayer( level.nukeVisionSetFailed, transition_time );
	self VisionSetPainForPlayer( level.nukeVisionSetFailed );
}


fog_nuke(transition_time)
{
	if ( !isdefined( level.nuke_fog_setting ) )
		return;
	
	ent = level.nuke_fog_setting;

	SetExpFog(
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

restore_fog( transition_time )
{
	if ( !isdefined( level.restore_fog_setting ) )
		return;
	
	ent = level.restore_fog_setting;

	SetExpFog(
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

nukeEarthquake()
{
	level endon ( "nuke_cancelled" );

	level waittill( "nuke_death" );

	// TODO: need to get a different position to call this on
	//earthquake( 0.6, 10, nukepos, 100000 );

	//foreach( player in level.players )
		//player PlayRumbleOnEntity( "damage_heavy" );
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill( "spawned_player" );

		// make sure the vision set stays on between deaths
		if( IsDefined( level.nukeDetonated ) )
			self VisionSetNakedForPlayer( level.nukeVisionSet, 0 );
	}
}