#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

// _plane.gsc
// a modular component intended to control a plane flying overhead
// adapted from _airstrike.gsc
kPlaneHealth = 800;

init()
{
	if ( !IsDefined( level.planes ) )
	{
		level.planes = [];
	}
	
	if ( !IsDefined( level.planeConfigs ) )
	{
		level.planeConfigs = [];
	}
	
	level.fighter_deathfx = LoadFX( "vfx/gameplay/explosions/vehicle/hind_mp/vfx_x_mphnd_primary" );
	level.fx_airstrike_afterburner = loadfx ("vfx/gameplay/mp/killstreaks/vfx_air_superiority_afterburner");
	level.fx_airstrike_contrail = loadfx ("vfx/gameplay/mp/killstreaks/vfx_aircraft_contrail");
	level.fx_airstrike_wingtip_light_green = LoadFX ( "vfx/gameplay/mp/killstreaks/vfx_acraft_light_wingtip_green" );
	level.fx_airstrike_wingtip_light_red = LoadFX ( "vfx/gameplay/mp/killstreaks/vfx_acraft_light_wingtip_red" );
	
	/*
	 * streakName
	 * modelNames[]	// alllied, axis
	 * halfDistance
	 * speed
	 * initialHeight
	 * flightSound
	 * flyTime
	 * attackTime
	 * inboundFlightAnim?
	 * outboundFlightAnim = "airstrike_mp"
	 * onAttackDelegate
	 * killcam stuff?
	 * planeFX?
	 */
}

getFlightPath( coord, directionVector, planeHalfDistance, absoluteHeight, planeFlyHeight, planeFlySpeed, attackDistance, streakName )
{
	// stealth_airstrike moves this a lot more
	startPoint = coord + ( directionVector * ( -1 * planeHalfDistance ) );
	endPoint = coord + ( directionVector * planeHalfDistance );
	
	if ( absoluteHeight ) // used in the new height system
	{
		startPoint *= (1, 1, 0);
		endPoint *= (1, 1, 0);
	}
	
	startPoint += ( 0, 0, planeFlyHeight );
	endPoint += ( 0, 0, planeFlyHeight );
		
	// Make the plane fly by
	d = length( startPoint - endPoint );
	flyTime = ( d / planeFlySpeed );
	
	// bomb explodes planeBombExplodeDistance after the plane passes the center
	d = abs( 0.5 * d + attackDistance  );
	attackTime = ( d / planeFlySpeed );
	
	assert( flyTime > attackTime );

	flightPath["startPoint"] = startPoint;
	flightPath["endPoint"] = endPoint;
	flightPath["attackTime"] = attackTime;
	flightPath["flyTime"] = flyTime;
	
	return flightPath;
}

//doPlaneStrike( lifeId, owner, requiredDeathCount, bombsite, startPoint, endPoint, bombTime, flyTime, direction, streakName )
doFlyby( lifeId, owner, requiredDeathCount, startPoint, endPoint, attackTime, flyTime, directionVector, streakName )
{
	plane = planeSpawn( lifeId, owner, startPoint, directionVector, streakName );
	
	plane endon( "death" );
	
	// plane spawning randomness = up to 125 units, biased towards 0
	// radius of bomb damage is 512
	endPathRandomness = 150;
	pathEnd  = endPoint + ( (RandomFloat(2) - 1) * endPathRandomness, (RandomFloat(2) - 1) * endPathRandomness, 0 );
	
	plane planeMove( pathEnd, flyTime, attackTime, streakName );
	
	plane planecleanup();
}

planeSpawn( lifeId, owner, startPoint, directionVector, streakName )
{
	if ( !isDefined( owner ) ) 
		return;
	
	startPathRandomness = 100;
	pathStart = startPoint + ( (RandomFloat(2) - 1) * startPathRandomness,	(RandomFloat(2) - 1) * startPathRandomness, 0 );
	
	//self thread DrawLine(pathStart, (AnglesToForward( direction ) * 200000), 120, (1,0,1) );
	
	configData = level.planeConfigs[ streakName ];
	
	plane = undefined;
	
	plane = Spawn( "script_model", pathStart );
	plane.team = owner.team;
	plane.origin = pathStart;
	plane.angles = VectorToAngles( directionVector );
	plane.lifeId = lifeId;
	plane.streakName = streakName;
	plane.owner = owner;
	
	plane SetModel( configData.modelNames[ owner.team ] );
	
	if ( IsDefined( configData.compassIconFriendly ) )
	{
		plane setObjectiveIcons(configData.compassIconFriendly, configData.compassIconEnemy );
	}
	
	plane thread handleDamage();
	plane thread handleDeath();
	// handle the nuke instead?
	// plane thread handleEMP( owner );
	
	startTrackingPlane( plane );
	
	// stealth bomber doesn't have effects
	if ( !IsDefined( configData.noLightFx ) )
	{
		plane thread playPlaneFx();
	}
	plane PlayLoopSound( configData.inboundSfx );
	
	plane createKillCam( streakName );
	
	return plane;
}

planeMove( destination, flyTime, attackTime, streakName )	// self == plane
{
	configData = level.planeConfigs[ streakName ];
	
	// begin flight
	self MoveTo( destination, flyTime, 0, 0 ); 
	
	// begin attack
	//thread callStrike_planeSound( plane, bombsite );
	// hmm, don't like the timing of these flybys
	if ( IsDefined( configData.onAttackDelegate ) )
	{
		self thread [[ configData.onAttackDelegate ]]( destination, flyTime, attackTime, self.owner, streakName );
	}
	
	if ( IsDefined( configData.sonicBoomSfx ) )
	{
		self thread playSonicBoom( configData.sonicBoomSfx, 0.5 * flyTime );
	}
	
	// fly away
	wait( 0.65 * flyTime );
	
	if ( IsDefined( configData.outboundSfx ) )
	{
		self StopLoopSound();
		self PlayLoopSound( configData.outboundSfx );
	}
	
	if ( IsDefined( configData.outboundFlightAnim ) )
	{
		self ScriptModelPlayAnimDeltaMotion( configData.outboundFlightAnim );
	}
	
	wait ( 0.35 * flyTime );
}

planeCleanup()	// self == plane
{
	configData = level.planeConfigs[ self.streakName ];
	
	if ( IsDefined( configData.onFlybyCompleteDelegate ) )
	{
		thread [[ configData.onFlybyCompleteDelegate ]]( self.owner, self, self.streakName );
	}
	
	if ( IsDefined( self.friendlyTeamId ) )
	{
		_objective_delete( self.friendlyTeamId );
		_objective_delete( self.enemyTeamID );
	}
	
	if ( IsDefined( self.killCamEnt ) )
	{
		self.killCamEnt Delete();
	}
	
	stopTrackingPlane( self );
	
	self notify( "delete" );
	self delete();
}

handleEMP( owner ) // self == plane
{
	self endon ( "death" );

	while ( true )
	{
		if ( owner isEMPed() )
		{
			self notify( "death" );
			return;
		}
		
		level waittill ( "emp_update" );
	}
}

handleDeath() // self == plane
{
	level endon( "game_ended" );
	self endon( "delete" );

	self waittill( "death" );
	
	forward = AnglesToForward( self.angles ) * 200;
	PlayFX( level.fighter_deathfx, self.origin, forward );
	
	self thread planeCleanup();
}

handleDamage()
{
	self  endon( "end_remote" );
	
	self maps\mp\gametypes\_damage::monitorDamage(
		kPlaneHealth,	// should be defined elsewhere
		"helicopter",	// should there be a death one?
		::handleDeathDamage,
		::modifyDamage,
		true	// isKillstreak
	);
}

modifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
		
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	return modifiedDamage;
}

handleDeathDamage( attacker, weapon, type, damage )	// self == plane
{
	config = level.planeConfigs[ self.streakName ];
	// !!! need VO
	self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, damage, config.xpPopup, config.destroyedVO, config.callout );
	
	maps\mp\gametypes\_missions::checkAAChallenges( attacker, self, weapon );
}

playPlaneFX()
{
	self endon ( "death" );

	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_afterburner, self, "tag_engine_right" );
	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_afterburner, self, "tag_engine_left" );
	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_contrail, self, "tag_right_wingtip" );
	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_contrail, self, "tag_left_wingtip" );
	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_wingtip_light_red, self, "tag_right_wingtip" );
	wait( 0.5);
	PlayFXOnTag( level.fx_airstrike_wingtip_light_green, self, "tag_left_wingtip" );
}

getPlaneFlyHeight()
{
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	if ( IsDefined( heightEnt ) )
	{
		return heightEnt.origin[2];
	}
	else
	{
		println( "NO DEFINED AIRSTRIKE HEIGHT SCRIPT_ORIGIN IN LEVEL" );
		planeFlyHeight = 950;
		if ( isdefined( level.airstrikeHeightScale ) )
			planeFlyHeight *= level.airstrikeHeightScale;
		
		return planeFlyHeight;
	}
}

// getPlaneFlightPlan
// Summary: On certain levels, we use airstrikeheight's position and orientation to indicate a safe flight path. The entity must have script_noteworthy="fixedposition" and have angles set.
// If not specified, we create one that across the player's current field of view.
getPlaneFlightPlan( distFromPlayer )	// self == player
{
	result = SpawnStruct();
	result.height = getPlaneFlyHeight();
	
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	if ( IsDefined( heightEnt ) 
	    && IsDefined( heightEnt.script_noteworthy )
	    && heightEnt.script_noteworthy == "fixedposition"
	   )
	{
		result.targetPos = heightEnt.origin;
		result.flightDir = AnglesToForward( heightEnt.angles );
		if ( RandomInt(2) == 0 )
			result.flightDir *= -1;
	}
	else
	{
		forwardVec = AnglesToForward( self.angles );
		rightVec = AnglesToRight( self.angles );
		result.targetPos = self.origin + distFromPlayer * forwardVec;
		result.flightDir = -1 * rightVec;
	}
	
	return result;
}

getExplodeDistance( height )
{
	standardHeight = 850;
	standardDistance = 1500;
	distanceFrac = standardHeight/height;
	
	newDistance = distanceFrac * standardDistance;
	
	return newDistance;
}

startTrackingPlane( obj )
{
	entNum = obj GetEntityNumber();
	level.planes[ entNum ] = obj;
}

stopTrackingPlane( obj )
{
	entNum = obj GetEntityNumber();
	level.planes[ entNum ] = undefined;
}

selectAirstrikeLocation( lifeId, streakname, doStrikeFn )
{
	targetSize = level.mapSize / 6.46875; // 138 in 720
	if ( level.splitscreen )
		targetSize *= 1.5;
	
	config = level.planeConfigs[ streakname ];
	if ( IsDefined( config.selectLocationVO ) )
	{
		self PlayLocalSound( game[ "voice" ][ self.team ] + config.selectLocationVO );
	}
	
	self _beginLocationSelection( streakname, "map_artillery_selector", config.chooseDirection, targetSize );
	
	self endon( "stop_location_selection" );

	// wait for the selection. randomize the yaw if we're not doing a precision airstrike.
	self waittill( "confirm_location", location, directionYaw );
	
	if ( !config.chooseDirection )
	{
		directionYaw = randomint(360);
	}

	self setblurforplayer( 0, 0.3 );
	
	if ( IsDefined( config.inboundVO ) )
	{
		self PlayLocalSound( game[ "voice" ][ self.team ] + config.inboundVO );
	}
	
	// turn off logging for DLC killstreaks (no shipped ks uses this)
//	self maps\mp\_matchdata::logKillstreakEvent( streakName, location );

	self thread [[ doStrikeFn ]]( lifeId, location, directionYaw, streakName );
	
	return true;
}

setObjectiveIcons( friendlyIcon, enemyIcon )	// self == plane
{
	friendlyTeamId = maps\mp\gametypes\_gameobjects::getNextObjID();
	Objective_Add( friendlyTeamId, "active", (0,0,0), friendlyIcon );
	Objective_OnEntityWithRotation( friendlyTeamId, self );
	self.friendlyTeamId = friendlyTeamId;
	
	enemyTeamID = maps\mp\gametypes\_gameobjects::getNextObjID();
	Objective_Add( enemyTeamID, "active", (0,0,0), enemyIcon );
	Objective_OnEntityWithRotation( enemyTeamID, self );
	self.enemyTeamID = enemyTeamID;
	
	if (level.teamBased)
	{
		Objective_Team( friendlyTeamId, self.team );
		Objective_Team( enemyTeamID, getOtherTeam(self.team) );
	}
	else
	{
		ownerEntityNum = self.owner GetEntityNumber();
		Objective_PlayerTeam( friendlyTeamId, ownerEntityNum );
		Objective_PlayerEnemyTeam( enemyTeamID, ownerEntityNum );
	}
}

playSonicBoom( soundName, delay )
{
	self endon ("death");
	
	wait ( delay );
	
	self PlaySoundOnMovingEnt( soundName );
}

createKillCam( streakName )	// self == plane
{
	configData = level.planeConfigs[ streakName ];
	
	if ( IsDefined( configData.killCamOffset ) )
	{
		planedir = AnglesToForward( self.angles );
		
		killCamEnt = Spawn( "script_model", self.origin + (0,0,100) - planedir * 200 );
		killCamEnt.startTime = GetTime();
		killCamEnt SetScriptMoverKillCam( "airstrike" );
		killCamEnt LinkTo( self, "tag_origin", configData.killCamOffset, ( 0,0,0 ) );
		
		self.killCamEnt = killCamEnt;
	}
}