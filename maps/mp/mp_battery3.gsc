#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_battery3_precache::main();
	maps\createart\mp_battery3_art::main();
	maps\mp\mp_battery3_fx::main();
	
	maps\mp\_load::main();
	
//	AmbientPlay( "ambient_mp_setup_template" );
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_battery3" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	setdvar_cg_ng("r_specularColorScale", 2.5, 15);
	SetDvar_cg_ng( "r_reactiveMotionWindFrequencyScale", 0, 0.1);
	SetDvar_cg_ng( "r_reactiveMotionWindAmplitudeScale", 0, 0.5);
	SetDvar_cg_ng( "sm_sunSampleSizeNear", .25, .55);

	//Turning HQ DOF off, because it turns off the bloom modifier on the lava

	setdvar("r_dof_hq",0);	
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "urban";
	game[ "axis_outfit" ] = "woodland";
	
	setupLevelKillstreak();
	
	// setupTemple();
	
	thread watersheet_trig_setup();
	
	/#
		debugEvents();
	#/
}

setupLevelKillstreak()
{
	config = SpawnStruct();
	config.crateWeight		= 85;
	config.crateHint		= &"MP_BATTERY3_VOLCANO_HINT";
	config.debugName		= "Volcano";
	config.id				= "volcano";
	config.weaponName		= "warhawk_mortar_mp";
	config.sourceStructs	= "volcano_source";
	// config.targetStructs	= "volcano_target";
	config.targetStructs	= "volcano_small_target";
	
	// launch delay
	config.launchDelay		= 3;
	
	config.projectilePerLoop	= 12;
	
	// air time
	
	// projectile model
	config.model			= "ruins_volcano_rock_03";
	
	// warning sfx, played in environment
//	config.warningSfxEntName	= "mortar_siren";
//	config.warningSfx			= "mortar_siren";
//	config.warningSfxDuration	= 10;
	
	// launch parameters
	// min delay, max delay, max air time
	// launch sfx
	// config.launchSfx		= "mortar_launch";
	config.launchDelayMin	= 0.05;
	config.launchDelayMax	= 0.2;
	config.launchAirTimeMin	= 6;
	config.launchAirTimeMax	= 8;
	config.strikeDuration	= 0.5;
	
	config.rotateProjectiles = true;
	config.minRotatation = -90;
	config.maxRotation = 90;
	
	// incoming sfx
	config.incomingSfx		= "volcano_incoming";
	config.trailVfx			= "med_meteor_trail";
	
	// impact
	config.impactVfx		= "med_meteor_impact";
	config.impactSfx		= "volcano_explosion_dirt";
	
	// level._effect[ "explode" ] 								= loadfx("fx/maps/mp_warhawk/mortar_impact"); 
	level._effect[ "med_meteor_impact" ] 					= loadfx("vfx/moments/mp_battery3/vfx_ground_impact_medium");
	level._effect[ "med_meteor_trail" ] 					= loadfx("vfx/moments/mp_battery3/vfx_smoketrail_meteor_med");
	level._effect[ "large_meteor_impact" ] 					= loadfx("vfx/moments/mp_battery3/vfx_ground_impact_large");
	level._effect[ "large_meteor_trail" ] 					= loadfx("vfx/moments/mp_battery3/vfx_smoketrail_meteor_large");
	
	maps\mp\killstreaks\_mortarstrike::createMortar( config );
	
	maps\mp\killstreaks\_juggernaut_predator::juggPredatorInit();
	thread waitForPredatorDeath();
	
	// predator init will overwrite the mortar custom killstreak stuff, so we need our own function
	level.mapCustomKillstreakFunc = ::battery3CustomKillstreak;
	level.mapCustomCrateFunc = ::battery3CustomCrate;
	level.mapCustomBotKillstreakFunc = ::battery3CustomBotKillstreakFunc;
	
	level thread volcanoWaitForUse( config.sourceStructs );
	// level thread volcano_activate_at_end_of_match();
	
	thread maps\mp\_dlcalienegg::setupEggForMap( "alienEasterEgg" );
}

battery3CustomKillstreak()
{
	maps\mp\killstreaks\_mortarstrike::mortarCustomKillstreakFunc();
	maps\mp\killstreaks\_juggernaut_predator::customKillstreakFunc();
}

battery3CustomCrate()
{
	// temporarily make sure that the volcano has zero weight, so that the predator will get triggered first
	tempVolcanoWeight = level.mortarConfig.crateWeight;
	level.mortarConfig.crateWeight = 0;
	maps\mp\killstreaks\_mortarstrike::mortarCustomCrateFunc();
	level.mortarConfig.crateWeight = tempVolcanoWeight;
	
	maps\mp\killstreaks\_juggernaut_predator::customCrateFunc();
}

battery3CustomBotKillstreakFunc()
{
	maps\mp\killstreaks\_mortarstrike::mortarCustomBotKillstreakFunc();
	maps\mp\killstreaks\_juggernaut_predator::customBotKillstreakFunc();
}

waitForPredatorDeath()
{
	// start the volcano when the predator dies
	
	level waittill( "jugg_predator_killed", predator );
	
	// enable the volcano killstreak
	// I wish I had written an interface for this, instead of calling the function directly
	maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", level.mortarConfig.id, level.mortarConfig.crateWeight );
}

// volcano
VOLCANO_RUMBLE_RADIUS = 15000;
volcanoWaitForUse( volcanoSourceName )
{
	level endon( "game_ended" );
	
	volcanoSource = getstruct( volcanoSourceName, "targetname" );
	
//	volcanoInitLargeChunks();
	
	while ( true )
	{
		level waittill( "mortar_killstreak_used", owner );
		
		wait (1.0);
		
		PlaySoundAtPos( volcanosource.origin, "volcano_rumble_start" );
		Earthquake( 0.1, 5.0, level.mapCenter, VOLCANO_RUMBLE_RADIUS );
		
		// start effects, sounds
		level waittill( "mortar_killstreak_start" );
		
		smallDebrisCfg = level.mortarConfig;
		
		PlaySoundAtPos( volcanoSource.origin, "volcano_eruption_primary" );
		exploder( 1 );
		Earthquake( 0.3, 2.0, level.mapCenter, VOLCANO_RUMBLE_RADIUS );
		playRumble( "artillery_rumble" );
		
		delay = RandomFloatRange(2, 3);
		wait( delay );
		
//		thread volcanoDoLargeChunks( 3, owner );
		
		volcanoSounds[0] = "volcano_eruption_second";
		volcanoSounds[1] = "volcano_eruption_third";
		volcanoSounds[2] = "volcano_eruption_fourth";
		
		for ( i = 0; i < 3; i++ )
		{
			smallDebrisCfg maps\mp\killstreaks\_mortarstrike::mortar_fire( smallDebrisCfg.launchDelayMin, smallDebrisCfg.launchDelayMax,
					     smallDebrisCfg.launchAirTimeMin, smallDebrisCfg.launchAirTimeMax,
					     smallDebrisCfg.strikeDuration,
					     owner 
					    );
			PlaySoundAtPos( volcanoSource.origin, volcanoSounds[i] );
			exploder( 1 );
			Earthquake( 0.3, 2.0, level.mapCenter, VOLCANO_RUMBLE_RADIUS );
			playRumble( "damage_light" );
			
			delay = RandomFloatRange(1.0, 2.0);
			wait( delay );
		}
		
		// vision set
		// thread maps\mp\killstreaks\_nuke::setNukeAftermathVision(10);
	}
}

// volcano large chunks
volcanoInitLargeChunks()
{
	level.volcanoLargeChunks = GetEntArray( "volcano_bigchunk", "targetname" );
	
	foreach ( chunk in level.volcanoLargeChunks )
	{
		chunk clearPath();
	}
}

volcanoDoLargeChunks( numChunks, owner )
{
	if ( level.volcanoLargeChunks.size == 0 )
		return;
	
	assert( numChunks <= level.volcanoLargeChunks.size );
	
	selectedChunks = [];
	
	volcanoSource = getstruct( level.mortarConfig.sourceStructs, "targetname" );
	
	for ( i = 0; i < numChunks; i++ )
	{
		
		index = RandomInt( level.volcanoLargeChunks.size );
		while ( IsDefined( selectedChunks[ index ] ) )
		{
			index = RandomInt( level.volcanoLargeChunks.size );
		}
		
		selectedChunks[ index ] = true;
		
		level.volcanoLargeChunks[ index] thread volcanoLaunchLargeChunk( volcanoSource.origin, owner );
		
		// wait 0-2 frames
		delay = RandomIntRange(0, 3) * 0.05;
		wait( delay );
	}
}

volcanoLaunchLargeChunk( startPos, owner )	// self == chunk model in world
{
	gravity = (0,0,-800);
	
	air_time = RandomFloatRange( 9.0, 12.0 );
	launch_dir = TrajectoryCalculateInitialVelocity( startPos, self.origin, gravity, air_time);
	
	self.weaponName = level.mortarConfig.weaponName;
//	self.incomingSfx = "";
	// self.trailVfx = "large_meteor_trail";
	self.impactVfx = "large_meteor_impact";
	self.rotateProjectiles = true;
	self.minRotatation = -150;
	self.maxRotation = 150;
	
	self maps\mp\killstreaks\_mortarstrike::random_mortars_fire_run( startPos, self.origin, air_time, owner, launch_dir, true );
	
	self blockPath();
	
	RadiusDamage( self.origin, 80, 1000, 1000, undefined, "MOD_CRUSH" );
	crushAllObjects( self.origin, 80 );
	
//	Sphere( self.origin, 80, (0, 1, 0), false, 1000 );
}

volcano_activate_at_end_of_match()
{
	level endon( "mortar_killstreak_used" );
	level waittill ( "spawning_intermission" );
	level.ending_flourish = true;
	
	// this should come from the config somewhere
	level.mortarConfig maps\mp\killstreaks\_mortarstrike::mortar_fire(0.1, 0.3, 2.5, 2.5, 6, level.players[0]);
	volcanoSource = getstruct( level.mortarConfig.sourceStructs, "targetname" );
	
	effectFwd = AnglesToForward( VectorNormalize( volcanoSource.origin - level.mapCenter ) );
	effectUp = AnglesToUp( (0, 0, 0) );
		
	PlayFX( getfx( "volcano_explode_01" ), volcanoSource.origin, effectUp, effectFwd );
	Earthquake( 0.3, 2.0, level.mapCenter, VOLCANO_RUMBLE_RADIUS );
	playRumble( "artillery_rumble" );
}

volcanoRumble( sourcePos, magnitude, duration )
{
	level endon( "mortar_killstreak_start" );
	level endon( "mortar_killstreak_end" );
	
	timeStamp = GetTime() + duration * 1000;
	
	while ( GetTime() < timeStamp )
	{
		rumbleDuration = RandomFloatRange( 0.5, 1.0 );
		Earthquake( magnitude, rumbleDuration, sourcePos, VOLCANO_RUMBLE_RADIUS );
		
		playRumble( "damage_light" );
		
		wait ( 2.0 * rumbleDuration );
	}
}

// animated temple collapse
setupTemple()
{
	pre = GetEntArray( "temple_pre", "targetname" );
	
	post = GetEntArray( "temple_post", "targetname" );
	foreach ( model in post )
	{
		model clearPath();
	}
	
	animModels = GetEntArray( "temple_anim", "targetname" );
	foreach ( animModel in animModels )
	{
		animModel Hide();
	}
	
	temple = SpawnStruct();
	temple.postCollapse = post;
	temple.preCollapse = pre;
	temple.animModels = animModels;
		
	temple thread templeCollapse();
}

#using_animtree( "vfx_dlc2" );
CONST_TEMPLE_DAMAGE_RADIUS = 500;
templeCollapse()
{
	level waittill( "mortar_killstreak_start" );
	
	wait ( 2.0 );
	
	exploder( 55 );
	wait( 2.0 );	// this delay is built into the exploder effect)
	
	foreach ( chunk in self.preCollapse )
	{
		chunk clearPath();
	}
	
	
	animLength = 7.5;
	if( ( level.ps3 ) || ( level.xenon ) )
	{
		animLength = GetAnimLength( %mp_ruins_td_01_cg_anim );
	}
	else
	{
		animLength = GetAnimLength( %mp_ruins_temple_debris_01_anim );
	}
	
	foreach ( animModel in self.animModels )
	{
		animModel Show();
		
		// AssertEx( IsDefined( animModel.script_noteworthy ) );
		animName = animModel.script_noteworthy;
		if ( !IsDefined( animName ) )
		{
			animName = "mp_ruins_td_01_cg_anim";
			
			// raise an error
		}
		
		animModel ScriptModelPlayAnim( animName );
	}
	
	
	PlaySoundAtPos( self.preCollapse[0].origin, "scn_battery3_temple_collapse" );
	
	// PlaySoundAtPos( impactPos, CONST_COLUMN_IMPACT_SFX );
	
	wait ( 1.5 );
	
	// kill people as the pieces fall so they aren't trapped inside
	impactPoint = undefined;
	foreach ( rubble in self.postCollapse )
	{
		if ( IsDefined( rubble.clip ) )
		{
			impactPoint = rubble.clip.origin;
			break;
		}
	}
	
	Earthquake( 0.25, 0.5, impactPoint, CONST_TEMPLE_DAMAGE_RADIUS );
	RadiusDamage( impactPoint, CONST_TEMPLE_DAMAGE_RADIUS, 500, 500, undefined, "MOD_CRUSH" );
	crushAllObjects( impactPoint, CONST_TEMPLE_DAMAGE_RADIUS );
	
	wait ( 2 );
	
	foreach ( model in self.postCollapse )
	{
		model blockPath();
	}
	
	wait ( animLength - 3.5 );	// 3.5 for the two previous waits
	
	// PlaySoundAtPos( impactPos, CONST_COLUMN_IMPACT_SFX );
	// exploder( CONST_COLUMN_IMPACT_VFX_EXPLODER_ID );
	
	foreach ( animModel in self.animModels )
	{
		animModel Hide();
	}
	
	// do I need to free the struct?
}

// helpers
playRumble( rumbleType )
{
	foreach ( player in level.players )
	{
		player PlayRumbleOnEntity( rumbleType );
	}
}

clearPath()	// self == blockingEnt
{	
	self Hide();
	self NotSolid();
	
	if ( IsDefined( self.target ) )
	{
		clip = GetEnt( self.target, "targetname" );
		self.clip = clip;
		
		clip ConnectPaths();
		clip NotSolid();
		clip Hide();
	}
}

blockPath()
{
	self Show();
	self Solid();
	
	if ( IsDefined( self.clip ) )
	{
		self.clip Show();
		self.clip Solid();
		self.clip DisconnectPaths();
	}
}

crushAllObjects( refPos, radius )
{
	radiusSq = radius * radius;
	
	crushObjects( refPos, radiusSq, "death", level.turrets );
	crushObjects( refPos, radiusSq, "death", level.placedIMS );
	crushObjects( refPos, radiusSq, "death", level.uplinks );
	crushObjects( refPos, radiusSq, "detonateExplosive", level.mines );
	
	foreach ( boxList in level.deployable_box )
	{
		crushObjects( refPos, radiusSq, "death",  boxList );
	}
}

crushObjects( refPos, radiusSq, notifyStr, targets )
{
	foreach ( target in targets )
	{
		if ( DistanceSquared( refPos, target.origin ) < radiusSq )
		{
			target notify( notifyStr );
			// target notify( "damage", 5000 );
			// target notify( "death" );
		}
	}
}

watersheet_trig_setup()
{
	level endon( "game_ended" );
	
	trig = GetEnt("watersheet", "targetname" );	
	
	while( true )
	{
		trig waittill("trigger", player );
		
		// IsPlayer to reject gryphon
		// !IsAI for only human controlled objects
		// inWater so that we don't start the thread multiple times
		if ( IsPlayer( player ) && !IsAI(player) && !(IsDefined( player.inWater ) && player.inWater ) )
		{
			player thread playerTrackWaterSheet( trig );
		}
	}	
}

playerTrackWaterSheet( waterTrig )	// self == player
{
	self endon( "disconnect" );
	// level endon( "game_ended" );
	
	self.inWater = true;
	
	// this should probably send a more generic water notify
	self notify( "predator_force_uncloak" );
	
	self SetWaterSheeting( 1 );
	// waterTrig PlayLoopSound( "scn_jungle_under_falls_plr" );
	
	while ( isReallyAlive( self ) && self IsTouching( waterTrig ) && !level.gameEnded )
	{
		wait ( 0.5 );
	}
	
	self SetWaterSheeting( 0 );
	// waterTrig StopLoopSound();
	
	self.inWater = false;
}

/#
debugEvents()
{
	SetDvarIfUninitialized( "scr_dbg_fx", 0 );
	SetDvarIfUninitialized( "scr_dbg_temple", 0 );
	
	while ( true )
	{
		checkDbgDvar( "scr_dbg_fx", ::dbgFireFx, undefined );
		checkDbgDvar( "scr_dbg_temple", ::dbgTemple, undefined );
		
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

dbgTemple( repeats )
{
	level endon( "game_ended" );
	
	while ( repeats != 0 )
	{
		pre = GetEntArray( "temple_pre", "targetname" );
		foreach ( chunk in pre )
		{
			if ( IsDefined( chunk.clip ) )
				chunk blockPath();
		}
		
		setupTemple();
		
		level notify( "mortar_killstreak_start" );
		
		wait ( 12 );
		repeats--;
	}
}
#/