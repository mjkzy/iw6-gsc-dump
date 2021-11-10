#include maps\mp\_utility;
#include common_scripts\utility;

// replacement for EMP
// only affects aircraft
// remarkably similar to aastrike, should probably get rid of that...
KS_NAME = "air_superiority";
kProjectileName = "aamissile_projectile_mp";

init()
{
	config = SpawnStruct();
	config.modelNames = [];
	config.modelNames[ "allies" ] = "vehicle_a10_warthog_iw6_mp";
	config.modelNames[ "axis" ] = "vehicle_a10_warthog_iw6_mp";
	config.inboundSfx = "veh_mig29_dist_loop";
	//config.inboundSfx = "veh_aastrike_flyover_loop";
	//config.outboundSfx = "veh_aastrike_flyover_outgoing_loop";
	config.compassIconFriendly = "compass_objpoint_airstrike_friendly";
	config.compassIconEnemy = "compass_objpoint_airstrike_busy";
	// sonic boom?
	config.speed = 4000;
	config.halfDistance = 20000;
	config.distFromPlayer = 4000;
	config.heightRange = 250;
	//config.attackTime = 2.0;
	config.numMissileVolleys = 3;
	config.outboundFlightAnim = "airstrike_mp_roll";
	config.sonicBoomSfx = "veh_mig29_sonic_boom";
	config.onAttackDelegate = ::attackEnemyAircraft;
	config.onFlybyCompleteDelegate = ::cleanupFlyby;
	config.xpPopup = "destroyed_air_superiority";
	config.callout = "callout_destroyed_air_superiority";
	config.voDestroyed = undefined;
	config.killCamOffset = (-800, 0, 200);
	
	level.planeConfigs[ KS_NAME ] = config;
	
	level.killstreakFuncs[KS_NAME] = ::onUse;
	
	level.teamAirDenied["axis"] = false;
	level.teamAirDenied["allies"] = false;
}

onUse( lifeId, streakName )
{
	assert( isDefined( self ) );
	
	// check for active air_superiority strikes
	otherTeam = getOtherTeam( self.team );
	if ( (level.teamBased && level.teamAirDenied[ otherTeam] )
		|| (!level.teamBased && IsDefined( level.airDeniedPlayer ) && level.airDeniedPlayer == self )
		)
	{
		self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}
	else
	{
		// scramble the fighters
		self thread doStrike( lifeId, KS_NAME );
	
		self maps\mp\_matchdata::logKillstreakEvent( "air_superiority", self.origin );
		self thread teamPlayerCardSplash( "used_air_superiority", self );
	
		return true;	
	}
	    
}

doStrike( lifeId, streakName )
{
	config = level.planeConfigs[ streakName ];
	
	flightPlan = self maps\mp\killstreaks\_plane::getPlaneFlightPlan( config.distFromPlayer );

	// play inbound vo
	
	wait( 1 );
	
	targetTeam = getOtherTeam(self.team);
	
	level.teamAirDenied[targetTeam] = true;
	level.airDeniedPlayer = self;
	
	doOneFlyby( streakName, lifeId, flightPlan.targetPos, flightPlan.flightDir, flightPlan.height);
	
	self waittill( "aa_flyby_complete" );
	
	// coming back around vo
	wait( 2 );
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	
	// don't do second flyby if owner has disconnected
	if ( IsDefined( self ) )
	{
		doOneFlyby( streakName, lifeId, flightPlan.targetPos, -1 * flightPlan.flightDir, flightPlan.height );
		
		self waittill( "aa_flyby_complete" );
	}
	
	level.teamAirDenied[targetTeam] = false;
	level.airDeniedPlayer = undefined;
	
	// play outbound vo
	// should check if there are still enemy aircraft in the air and play appropriate vo
}

doOneFlyby( streakName, lifeId, targetPos, dir, flyHeight )
{
	config = level.planeConfigs[ streakName ];
	
	// absolute height should be derived from the heightEnt
	flightPath = maps\mp\killstreaks\_plane::getFlightPath( targetPos, dir, config.halfDistance, true, flyHeight, config.speed, -0.5 * config.halfDistance, streakName );
	
	// may want to break this up into spawn, move, cleanup components
	// so that we can reuse the plane
	level thread maps\mp\killstreaks\_plane::doFlyby( lifeId, self, lifeId, 
													 flightPath["startPoint"] + (0, 0, randomInt(config.heightRange) ), 
													 flightPath["endPoint"] + (0, 0, randomInt(config.heightRange) ), 
													 flightPath["attackTime"],
													 flightPath["flyTime"],
													 dir, 
													 streakName );
}


attackEnemyAircraft( pathEnd, flyTime, beginAttackTime, owner, streakName )	// self == plane
{
	self endon( "death" );
	self.owner endon( "killstreak_disowned" );
	level endon( "game_ended" );
	
	wait (beginAttackTime);
	
	targets = findAllTargets( self.owner, self.team );
	config = level.planeConfigs[ streakName ];
	numVolleys = config.numMissileVolleys;
	targetIndex = targets.size - 1;
	
	while (targetIndex >= 0
		   && numVolleys > 0
		  )
	{
		target = targets[ targetIndex ];
		if ( IsDefined( target ) && IsAlive( target ) )
		{
			self fireAtTarget( target );
			numVolleys--;
			wait ( 1 );
		}
		targetIndex--;
	}
}

cleanupFlyby( owner, plane, streakName )
{
	owner notify( "aa_flyby_complete" );
}

// curTargetsStruct is a struct that holds the array of targets
// !!! use this hack since arrays are passed by value, while structs are passed by reference
findTargetsOfType( attacker, victimTeam, checkFunc, candidateList, curTargetsStruct )
{
	if ( IsDefined( candidateList ) )
	{
		foreach ( target in candidateList )
		{
			if ( [[ checkFunc ]]( attacker, victimTeam, target ) )
			{
				curTargetsStruct.targets[ curTargetsStruct.targets.size ] = target;
			}
		}
	}
	
	return curTargetsStruct;
}

// unlike the aa strike, we only search for targets once
// because we block new air strikes from behing launched
// also: probably could flip the order that targets are acquired if we want
// the jets to go after low-cost killstreaks first
findAllTargets( attacker, attackerTeam )
{
	wrapper = SpawnStruct();
	wrapper.targets = [];
	
	// ok, I'm sorry for function pointers, but it makes me sad to do unnecessary if checks all the time
	// isEnemyFunc will test if the target belongs to an enemy
	isEnemyFunc = undefined;
	if ( level.teamBased )
	{
		isEnemyFunc = ::isValidTeamTarget;
	}
	else
	{
		isEnemyFunc = ::isValidFFATarget;
	}
	victimTeam = undefined;
	if ( IsDefined( attackerTeam ) )
	{
		victimTeam = getOtherTeam( attackerTeam );
	}
	
	// 2013-09-02 wallace: Since arrays are passed by value (or so JoeC tells me)
	// we will wrap up the targets array in a struct that is past by reference
	// this means that each call to findTargetsOfType is adding targets to the SAME array, not a copy
	// Destroy player controlled and higher level-KS's last, so put them in the front of the arraw
	findTargetsOfType( attacker, victimTeam, isEnemyFunc, level.heli_pilot, wrapper );
	if ( IsDefined( level.lbSniper ) )
	{
		if ( [[ isEnemyFunc ]]( attacker, victimTeam, level.lbSniper ) )
		{
			wrapper.targets[ wrapper.targets.size ] = level.lbSniper;
		}
	}
	
	findTargetsOfType( attacker, victimTeam, isEnemyFunc, level.planes, wrapper );
	// 2013-09-03 wallace: ugh, this is stupid. Vanguard puts itself in both remote_uav and littlebird arrays. So, don't use remote_uav as possible targets
	// findTargetsOfType( attacker, victimTeam, checkFunc, level.remote_uav, wrapper );
	findTargetsOfType( attacker, victimTeam, isEnemyFunc, level.littleBirds, wrapper );
	findTargetsOfType( attacker, victimTeam, isEnemyFunc, level.helis, wrapper );
	
	return wrapper.targets;
}

fireAtTarget( curTarget )	// self == plane
{
	if ( !isDefined(curTarget) )
		return;
	
	// do this check in case the plane's owner disconnects mid flight
	// we still want this pass to finish
	owner = undefined;
	if ( IsDefined( self.owner ) )
		owner = self.owner;
	
	forwardVec = 384 * AnglesToForward( self.angles );
	
	startpoint = self GetTagOrigin( "tag_missile_1" ) + forwardVec;
	rocket1 = MagicBullet( kProjectileName, startPoint, startPoint + forwardVec, owner );
	rocket1.vehicle_fired_from = self;
	
	startpoint = self GetTagOrigin( "tag_missile_2" ) + forwardVec;
	rocket2 = MagicBullet( kProjectileName, startPoint, startPoint + forwardVec, owner );
	rocket2.vehicle_fired_from = self;
	
	missiles = [ rocket1, rocket2 ];
	curTarget notify( "targeted_by_incoming_missile", missiles );
	
	self thread startMissileGuidance( curTarget, 0.25, missiles );
}

startMissileGuidance( curTarget, igniteTime, missileArray )
{
	wait( igniteTime );
	
	if ( IsDefined( curTarget ) )
	{
		targetPoint = undefined;
		//AH: HACK: The harrier doesn't have the tag_missile_target, but it does have a tag_body.
		//			The code works fine without this check, but GetTagOrigin throws an SRE if the tag does not exist.
		if ( curTarget.model != "vehicle_av8b_harrier_jet_mp" )
			targetPoint = curTarget GetTagOrigin( "tag_missile_target" );
		if ( !IsDefined( targetPoint ) )
		{
			targetPoint = curTarget GetTagOrigin( "tag_body" );
		}
		targetOffset = targetPoint - curTarget.origin;
		
		foreach ( missile in missileArray )
		{
			if ( IsValidMissile( missile ) )
			{
				missile Missile_SetTargetEnt( curTarget, targetOffset );
				missile Missile_SetFlightmodeDirect();
			}
		}
	}
}

destroyActiveVehicles( attacker, victimTeam )
{
	// thread all of the things that need to get destroyed, this way we can put frame waits in between each destruction so we don't hit the server with a lot at one time
	maps\mp\killstreaks\_killstreaks::destroyTargetArray( attacker, victimTeam, "aamissile_projectile_mp", level.helis );
	maps\mp\killstreaks\_killstreaks::destroyTargetArray( attacker, victimTeam, "aamissile_projectile_mp", level.littleBirds );
	maps\mp\killstreaks\_killstreaks::destroyTargetArray( attacker, victimTeam, "aamissile_projectile_mp", level.heli_pilot );
	if ( IsDefined( level.lbSniper ) )
	{
		// kind of hack, but destroyTargets does a lot of needed setup
		tempArray = [];
		tempArray[0] = level.lbSniper;
		maps\mp\killstreaks\_killstreaks::destroyTargetArray( attacker, victimTeam, "aamissile_projectile_mp", tempArray );
	}
	
	maps\mp\killstreaks\_killstreaks::destroyTargetArray( attacker, victimTeam, "aamissile_projectile_mp", level.remote_uav );
	maps\mp\killstreaks\_killstreaks::destroyTargetArray( attacker, victimTeam, "aamissile_projectile_mp", level.planes );
}
