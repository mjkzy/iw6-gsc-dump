#include maps\mp\_utility;
#include common_scripts\utility;

main()
{
	maps\mp\mp_flooded_precache::main();
	maps\createart\mp_flooded_art::main();
	maps\mp\mp_flooded_fx::main();
	maps\mp\_water::waterShallowFx();
	
	maps\mp\_load::main();
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_flooded" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );

	// SimonT Fixed this script and commented it out as we don't know if we need it
//	//Set bilinear mip for CurrentGen
	if ( !is_gen4() )
	{
		setdvar( "r_texFilterProbeBilinear", 1 );
	}
	
	if ( level.ps3 )
	{
		SetDvar( "sm_sunShadowScale", "0.55" ); // ps3 optimization
		SetDvar( "sm_sunsamplesizenear", ".15" );
	}
	else if ( level.xenon )
	{
		SetDvar( "sm_sunShadowScale", "0.85" ); //  optimization
		SetDvar( "sm_sunsamplesizenear", ".22" );
	}
	else
	{
		SetDvar( "sm_sunShadowScale", "0.9" ); // optimization
		SetDvar( "sm_sunsamplesizenear", ".27" );
	}
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	
	setdvar( "r_reactiveMotionWindAmplitudeScale", 1 );
	setdvar( "r_reactiveMotionWindAreaScale", 10);
	setdvar( "r_reactiveMotionWindDir", (0.3, -1, -.5) );
	setdvar( "r_reactiveMotionWindFrequencyScale", .25 );
	setdvar( "r_reactiveMotionWindStrength", 1 );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	maps\mp\_water::waterShallowInit( 205, 212 );
	
	movers = GetEntArray( "vehicle_movers", "targetname" );
	foreach ( moverTrigger in movers )
	{
		sinkingPlatform_Create( moverTrigger, 12, 12 );
	}
	
	level thread initExtraCollision();
	
	// moverCreate( "vehicle_floating" );
}

initExtraCollision()
{
	collision1 = GetEnt( "clip128x128x8", "targetname" );
	collision1Ent = spawn( "script_model", (1392, -584, 386) );
	collision1Ent.angles = ( 336, 0, 90);
	collision1Ent CloneBrushmodelToScriptmodel( collision1 );
}

// ---------------------------------------------------------
// Sinking Platforms
// A platform that lowers when a player stands on it;
// returns to rest position when no one is on it.
// trigger -> clip -> vehicle ent -> struct
// todo: make sink rate proportional to # of people on the platform
// ---------------------------------------------------------
sinkingPlatform_Create( triggerEnt, sinkTime, riseTime )
{
	// get the collision
	clip = GetEnt( triggerEnt.target, "targetname" );
	if ( !IsDefined( clip ) )
	{
		print( "Could not find clip named " + triggerEnt.target + "\n" );
		return;
	}
	
	// get the entity
	entName = clip.target;
	ent = GetEnt( entName, "targetname" );
	if ( !IsDefined( ent ) )
	{
		print( "Could not find entity named " + entName + "\n" );
		return;
	}
	
	ent.clip = clip;
	ent.trigger = triggerEnt;
	ent.clip.unresolved_collision_func = ::handleUnreslovedCollision;	// this prevents the bus from killing the player if you try to mantle onto th ebridge
	
	clip LinkTo( ent );
	
	// get path blockers
	pathBlock = GetEnt( ent.script_noteworthy, "targetname" );
	ent.pathBlock = pathBlock;
	ent thread sinkingPlatformEnablePathsOnStart();
	
	endStruct = getstruct( ent.target, "targetname" );
	if ( !IsDefined( endStruct ) )
	{
		print( "Could not find target struct named " + ent.target + "\n" );
		return;
	}
	ent.startPos = ent.origin;
	ent.startRot = ent.angles;
	
	ent.endPos = endStruct.origin;
	ent.endRot = endStruct.angles;
	
	moveDist = Distance( ent.endPos, ent.startPos);
	
	// these values are 1 / velocity so I can multiply future distances to derive moveTo times
	if ( IsDefined( endStruct.script_duration ) )
	{
		sinkTime = endStruct.script_duration;
	}
	
	if ( IsDefined( triggerEnt.script_duration ) )
	{
		riseTime = triggerEnt.script_duration;
	}
	
	ent.sinkRate = sinkTime / moveDist;
	ent.riseRate = riseTime / moveDist;
	
	// this array will track entities that enter the trigger
	ent.entsInTrigger = [];
	
	ent thread sinkingPlatform_WaitForEnter();
	
	return ent;
}

sinkingPlatform_WaitForEnter()	// self == platform
{
	level endon ( "game_ended" );
	
	while ( true )
	{
		self.trigger waittill( "trigger", other );
		
		if ( self canEntTriggerPlatform( other ) && isReallyAlive( other ) )
		{
			self.entsInTrigger[ other GetEntityNumber() ] = other;
			
			// update sink rate
			
			curSize = self.entsInTrigger.size;
			if ( curSize == 1 )
			{
				self sinkingPlatform_Start();
			}
			else if ( !IsDefined( self.reachedBottom ) )
			{
				// print( " ~* Extra body, increasing speed! " + curSize );
				self updateSinkRate( curSize );
			}
		}
	}
}

kMIN_ACCEL = 0.5;
sinkingPlatform_Start()	// self == platform
{
	self notify("platform_sink");
	
	t = Distance( self.endPos, self.origin ) * self.sinkRate;
	
	minAccel = min( 0.5 * t, kMIN_ACCEL );
	
	self MoveTo( self.endPos, t, minAccel, minAccel );
	self RotateTo( self.endRot, t, minAccel, minAccel );
	
	// self sinkingPlatformDisablePaths();
	
	self thread sinkingPlatformPlaySfxSequence( "scn_car_sinking_down_start",
				  "scn_car_sinking_down_loop",
				  "scn_car_sinking_down_end",
				  1,
				  0.25,
				  t
				 );
	
	self thread sinkingPlatform_WaitForExit();
	self thread sinkingPlatform_WaitForReachedBottom();
}

sinkingPlatform_WaitForExit()	// self == platform
{
	level endon ( "game_ended" );
	
	while ( self.entsInTrigger.size > 0 )
	{
		wait ( 0.1 );
		
		startSize = self.entsInTrigger.size;
		
		foreach ( index, player in self.entsInTrigger )
		{
			if	(	!IsDefined( player )
			    ||	!(player IsTouching( self.trigger ) )
			    ||	!isReallyAlive( player )
				)
			{
				self.entsInTrigger[ index ] = undefined;
			}
		}
		
		if ( !IsDefined( self.reachedBottom ) )
		{
			curSize = self.entsInTrigger.size;
			if ( curSize > 0 && curSize != startSize )
			{
				self updateSinkRate( curSize );
			}
		}
	}
	
	self sinkingPlatform_Return();
}

sinkingPlatform_WaitForReachedBottom()	// self == platform
{
	level endon ( "game_ended" );
	self endon ( "platform_return" );
	
	self waittill( "movedone" );
	
	self.reachedBottom = true;
	
	// self sinkingPlatformEnablePaths();
}

sinkingPlatform_WaitForReachedTop()
{
	level endon ( "game_ended" );
	self endon ( "platform_sink" );
	
	self waittill( "movedone" );
	
	//self sinkingPlatformEnablePaths();	
}

sinkingPlatform_Return()	// self == platform
{
	self notify ( "platform_return" );
	self.reachedBottom = undefined;
	
	//self sinkingPlatformDisablePaths();
	
	t = Distance( self.startPos, self.origin ) * self.riseRate;
	
	minAccel = min( 0.5 * t, kMIN_ACCEL );
	
	self MoveTo( self.startPos, t, minAccel, minAccel );
	self RotateTo( self.startRot, t, minAccel, minAccel );
	
	// self thread sinkingPlatform_WaitForEnter();
	
	self thread sinkingPlatformPlaySfxSequence( "scn_car_floating_up_start",
				  "scn_car_floating_up_loop",
				  "scn_car_floating_up_end",
				  .5,
				  0.25,
				  t
				 );
	
	self thread sinkingPlatform_WaitForReachedTop();
}

canEntTriggerPlatform( other )	// self == platform
{
	// we only want humans
	return ( (IsPlayer( other ) || ( IsAgent( other ) && IsDefined( other.agent_type ) && other.agent_type != "dog" ))
		    && !IsDefined( self.entsInTrigger[ other GetEntityNumber() ] )
		   );
}

updateSinkRate( numBodies )	// self == platform
{
	t = Distance( self.endPos, self.origin ) * self.sinkRate;
	t /= numBodies;
	
	if ( t > 0 )
	{
		minAccel = min( 0.5 * t, kMIN_ACCEL );
	
		self.clip MoveTo( self.endPos, t, minAccel, minAccel );
		self.clip RotateTo( self.endRot, t, minAccel, minAccel );
	}
	else
	{
		print( "Error! t = " + t * numBodies + " bodies: " + numBodies + "\n" );
	}
}

sinkingPlatformPlaySfxSequence( startSfx, loopSfx, endSfx, startTime, endTime, totalTime )
{
	// clean up previous sounds
	self notify("stopSinkingSfx");
	self StopSounds();
	self StopLoopSound();
	
	self endon("stopSinkingSfx");
	
	self PlaySound(startSfx);
	wait (startTime);
	
	actualLoopTime = totalTime - startTime - endTime;
	
	if (actualLoopTime > 0)
	{
		self PlayLoopSound(loopSfx);
		wait (actualLoopTime);
		self StopLoopSound();
	}
	
	self PlaySound( endSfx );
}

sinkingPlatformEnablePathsOnStart()
{
	wait (0.1);
	self sinkingPlatformEnablePaths();
}

sinkingPlatformEnablePaths()
{
	if ( IsDefined( self.pathBlock ) )
	{
		self.pathBlock ConnectPaths();
		self.pathBlock Hide();
	}
}

sinkingPlatformDisablePaths()
{
	if ( IsDefined( self.pathBlock ) )
	{
		self.pathBlock Show();
		self.pathBlock DisconnectPaths();
	}
}

// ---------------------------------------------------------
// Movers
// One-off moving platforms that players can use
// ex: the truck that players can kick and let drift downstream
// ---------------------------------------------------------
moverCreate( triggerName )
{
	// get trigger
	trigger = GetEnt( triggerName, "targetname" );
	if ( !IsDefined( trigger ) )
	{
		print( "Could not find trigger named " + triggerName + "\n" );
		return;
	}
	
	// get the brush
	clip = GetEnt( trigger.target, "targetname" );
	if ( !IsDefined( clip ) )
	{
		print( "Could not find brush named " + trigger.target + "\n" );
		return;
	}
	
	// get the model
	ent = GetEnt( clip.target, "targetname" );
	if ( !IsDefined( ent ) )
	{
		print( "Could not find entity named " + clip.target + "\n" );
		return;
	}
	ent.trigger = trigger;
	ent.clip = clip;
	
	clip LinkTo( ent );
	
	// get the positions
	ent.keyframes = [];
	keyframeName = ent.target;
	i = 0;
	while ( IsDefined( keyframeName ) )
	{
		struct = getstruct( keyframeName, "targetname" );
		if ( IsDefined( struct ) )
		{
			if ( !IsDefined( struct.script_duration ) )
			{
				print( "Keyframe " + keyframeName + " is missing a script_duration value!\n" );
				struct.script_duration = 6;
			}
			
			if ( !IsDefined( struct.script_accel) )
			{
				struct.script_accel = 0.5 * struct.script_duration;
			}
			
			if ( !IsDefined( struct.script_decel ) )
			{
				struct.script_decel = 0.25 * struct.script_duration;
			}
			
			struct.clipAngles = struct.angles - ent.angles + clip.angles;
			
			ent.keyframes[i] = struct;
			
			i++;
			keyframeName = struct.target;
		}
		else
		{
			break;
		}
	}
	
	// setup trigger
	ent.trigger SetHintString( &"PLATFORM_HOLD_TO_USE" );
	ent.trigger MakeUsable();
	ent thread moverWaitForUse();
	
	return ent;
}

moverWaitForUse()	// self == mover entity
{
	level endon ( "game_ended" );
	
	self.trigger waittill( "trigger" );
	
	self.trigger MakeUnusable();
	
	// trigger has been used
	
	// play sound
	
	// play animation
	self moverDoMove();
}

moverDoMove()	// self == mover entity
{
	level endon ( "game_ended" );
	
	for ( i = 0; i < self.keyframes.size; i++ )
	{
		kf = self.keyframes[i];
		
		self MoveTo( kf.origin, kf.script_duration, kf.script_accel, kf.script_decel );
		self RotateTo( kf.angles, kf.script_duration, kf.script_accel, kf.script_decel );
		
		self waittill( "movedone" );
		
		if ( IsDefined( kf.script_delay ) )
		{
			wait( kf.script_delay );
		}
	}
	
	// play another sound?
	
	// shake?
}

handleUnreslovedCollision( hitEnt )	// self == mover, hitEnt == player (usually)
{
	// return;
	
	// hitEnt DoDamage( 1000, hitEnt.origin, self, self, "MOD_CRUSH" );
}