#include maps\mp\_utility;
#include common_scripts\utility;

// replacement for EMP
// only affects aircraft
// remarkably similar to aastrike, should probably get rid of that...
KS_NAME = "gas_airstrike";

init()
{
	precacheLocationSelector( "map_artillery_selector" );
	
	config = SpawnStruct();
	config.modelNames = [];
	config.modelNames[ "allies" ] = "vehicle_mig29_desert";
	config.modelNames[ "axis" ] = "vehicle_mig29_desert";
	config.inboundSfx = "veh_mig29_dist_loop";
	//config.inboundSfx = "veh_aastrike_flyover_loop";
	//config.outboundSfx = "veh_aastrike_flyover_outgoing_loop";
	config.compassIconFriendly = "compass_objpoint_airstrike_friendly";
	config.compassIconEnemy = "compass_objpoint_airstrike_busy";
	// sonic boom?
	config.speed = 5000;
	config.halfDistance = 15000;
	config.heightRange = 500;
	//config.attackTime = 2.0;
	config.outboundFlightAnim = "airstrike_mp_roll";
	config.onAttackDelegate = ::dropBombs;
	config.onFlybyCompleteDelegate = ::cleanupFlyby;
	config.chooseDirection = true;
	config.selectLocationVO = "KS_hqr_airstrike";
	config.inboundVO = "KS_ast_inbound";
	config.bombModel = "projectile_cbu97_clusterbomb";
	config.numBombs = 3;
	// should be 2x the effect radius to have no gaps/overlap
	config.distanceBetweenBombs = 350;
	config.effectRadius = 200;
	config.effectHeight = 120;
	// this should be something else
	// remember to precache this
	//config.effectVFX = LoadFX( "fx/smoke/poisonous_gas_linger_medium_thick_killer_pulse");
	config.effectVFX = LoadFX( "fx/smoke/poisonous_gas_linger_medium_thick_killer_instant");
	config.effectMinDelay = 0.25;
	config.effectMaxDelay = 0.5;
	config.effectLifeSpan = 13;
	config.effectCheckFrequency = 1.0;
	config.effectDamage = 10;
	config.obitWeapon = "gas_strike_mp";
	config.killCamOffset = (0, 0, 60);
	
	level.planeConfigs[ KS_NAME ] = config;
	
	level.killstreakFuncs[KS_NAME] = ::onUse;
}

onUse( lifeId, streakName )
{
	assert( isDefined( self ) );
	
	// check for active air_superiority strikes
	otherTeam = getOtherTeam( self.team );
	
	if ( IsDefined( level.numGasStrikeActive ) )
	{
		self IPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}
	else
	{
		result = maps\mp\killstreaks\_plane::selectAirstrikeLocation( lifeId, KS_NAME, ::doStrike );
		
		return ( IsDefined( result ) && result );
	}
}

doStrike( lifeId, location, directionYaw, streakName )
{
	level.numGasStrikeActive = 0;
	
	wait ( 1 );
	
	planeFlyHeight = maps\mp\killstreaks\_plane::getPlaneFlyHeight();
	
	dirVector = AnglesToForward( (0, directionYaw, 0) );
	
	doOneFlyby( streakName, lifeId, location, dirVector, planeFlyHeight );
	
	self waittill( "gas_airstrike_flyby_complete" );
	
	// play outbound vo
}

doOneFlyby( streakName, lifeId, targetPos, dir, flyHeight )
{
	config = level.planeConfigs[ streakName ];
	
	// absolute height should be derived from the heightEnt
	flightPath = maps\mp\killstreaks\_plane::getFlightPath( targetPos, dir, config.halfDistance, true, flyHeight, config.speed, 0, streakName );
	
	// Box( targetPos, dir[1], (0, 0, 1), false, 200);
	
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

cleanupFlyby( owner, plane, streakName )
{
	owner notify( "gas_airstrike_flyby_complete" );
}


dropBombs( pathEnd, flyTime, beginAttackTime, owner, streakName )	// self == plane
{
	self endon( "death" );
	
	wait (beginAttackTime);
	
	config = level.planeConfigs[ streakName ];
	
	numBombsLeft = config.numBombs;
	timeBetweenBombs = config.distanceBetweenBombs / config.speed;
	
	while (numBombsLeft > 0)
	{
		self thread dropOneBomb( owner, streakName );
		
		numBombsLeft--;
		wait ( timeBetweenBombs );
	}
	
}

dropOneBomb( owner, streakName )	// self == plane
{
	level.numGasStrikeActive++;
	
	plane = self;
	
	config = level.planeConfigs[ streakName ];
	
	planeDir = AnglesToForward( plane.angles );
		
	bomb = spawnBomb( config.bombModel, plane.origin, plane.angles );
	bomb MoveGravity( ( planeDir  * ( config.speed / 1.5 ) ), 3.0 );

	// bomb.lifeId = requiredDeathCount;
	
	newBomb = Spawn( "script_model", bomb.origin );
 	newBomb SetModel( "tag_origin" );
  	newBomb.origin = bomb.origin;
  	newBomb.angles = bomb.angles;

	bomb SetModel( "tag_origin" );
	wait (0.10);  // wait two server frames before playing fx
	
	bombOrigin = newBomb.origin;
	bombAngles = newBomb.angles;
	if ( level.splitscreen )
	{
		playfxontag( level.airstrikessfx, newBomb, "tag_origin" );
	}
	else
	{
		playfxontag( level.airstrikefx, newBomb, "tag_origin" );
	}
	
	wait ( 1.0 );
	
	trace = BulletTrace(newBomb.origin, newBomb.origin + (0,0,-1000000), false, undefined);
	impactPosition = trace["position"];
	
	// Line( newBomb.origin, impactPosition, (1, 0, 0), 1, true, 20 * config.effectLifeSpan);
	
	// artillery damage center?
	
	// set up kill cam?
	
	// need to wait the right amount of time before
	
	bomb onBombImpact( owner, impactPosition, streakName );
	
	newBomb delete();
	bomb delete();
	
	level.numGasStrikeActive--;
	if (level.numGasStrikeActive == 0)
	{
		level.numGasStrikeActive = undefined;
	}
}


spawnBomb( modelName, origin, angles )
{
	bomb = Spawn( "script_model", origin );
	bomb.angles = angles;
	bomb SetModel( modelname );

	return bomb;
}

onBombImpact( owner, position, streakName )	// self == bomb?
{
	config = level.planeConfigs[ streakName ];
	
	// position = self.origin;
	
	effectArea = Spawn( "trigger_radius", position, 0, config.effectRadius, config.effectHeight );
	effectArea.owner = owner;
	
	effectRadius = config.effectRadius;
	vfx = SpawnFx( config.effectVFX, position );
	TriggerFX( vfx );
	
	wait ( RandomFloatRange( config.effectMinDelay, config.effectMaxDelay ) );
	
	timeRemaining = config.effectLifeSpan;
	
	// self.primaryWeapon = config.obitWeapon;
	
	killCamEnt = Spawn( "script_model", position + config.killCamOffset );
	killCamEnt LinkTo( effectArea );
	self.killCamEnt = killCamEnt;
	//self.killCamEnt SetScriptMoverKillCam( "explosive" );
	
	while ( timeRemaining > 0.0 )
	{
		foreach ( character in level.characters )
		{	
	    	character applyGasEffect( owner, position, effectArea, self, config.effectDamage );
		}
		
		wait ( config.effectCheckFrequency );
		timeRemaining -= config.effectCheckFrequency;
	}
	
	self.killCamEnt Delete();
	
	effectArea Delete();
	vfx Delete();
}

applyGasEffect( attacker, position, trigger, inflictor, damage )	// self == target
{
	if( (attacker isEnemy( self )) && IsAlive( self ) && self IsTouching( trigger ) )
	{
		// rumble
		inflictor RadiusDamage( self.origin, 1, damage, damage, attacker, "MOD_RIFLE_BULLET", "gas_strike_mp");
		// self DoDamage( damage, position, attacker, inflictor, "MOD_UNKNOWN" );
		
		if ( !(self isUsingRemote()) )
		{
			duration = maps\mp\perks\_perkfunctions::applyStunResistence( 2.0 );
			self ShellShock( "default", duration );
		}
	}
}