#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

KS_NAME = "placeable_barrier";
init()
{
	//PreCacheModel( "portable_barrier" );
	//PreCacheModel( "portable_barrier_obj" );
	//PreCacheModel( "portable_barrier_obj_red" );
	
	config = spawnStruct();
	config.streakName				= KS_NAME;
	config.weaponInfo				= "ims_projectile_mp";
	// config.modelBase				= "ims_scorpion_body";
	config.modelBase				= "placeable_barrier";
	config.modelDestroyed			= "placeable_barrier_destroyed";
	config.modelPlacement			= "placeable_barrier_obj";
	config.modelPlacementFailed		= "placeable_barrier_obj_red";
	// config.modelDestroyed			= "ims_scorpion_body";	
	config.hintString				= &"KILLSTREAKS_HINTS_PLACEABLE_COVER_PICKUP";	
	config.placeString				= &"KILLSTREAKS_HINTS_PLACEABLE_COVER_PLACE";	
	config.cannotPlaceString		= &"KILLSTREAKS_HINTS_PLACEABLE_COVER_CANNOT_PLACE";	
	config.headIconHeight			= 75;
	config.splashName				= "used_placeable_barrier";	
	config.lifeSpan					= 60.0;
	// config.goneVO					= "ims_gone";
	config.maxHealth				= 500;
	config.allowMeleeDamage			= false;
	config.damageFeedback			= "ims";
	config.xpPopup					= "destroyed_ims";
	config.destroyedVO				= "ims_destroyed";
	//config.onCreateDelegate			= ::createObject;
	config.onPlacedDelegate			= ::onPlaced;
	config.onCarriedDelegate		= ::onCarried;
	config.placedSfx				= "ims_plant";
	config.onDamagedDelegate		= ::onDamaged;
	//config.onDestroyedDelegate		= ::onDestroyed;
	config.onDeathDelegate			= ::onDeath;
	config.deathVfx					= loadfx( "vfx/gameplay/mp/killstreaks/vfx_ballistic_vest_death" );
	// config.onDeactivateDelegate		= ::onDeactivated;
	// config.onActivateDelegate		= ::onActivated;
	config.colRadius				= 72;
	config.colHeight				= 36;
	
	level.placeableConfigs[ KS_NAME ] = config;
	
	setupBrushModel();
	
	level.killStreakFuncs[ KS_NAME ] 	= ::tryUsePlaceable;
}

tryUsePlaceable( lifeId, streakName ) // self == player
{
	result = self maps\mp\killstreaks\_placeable::givePlaceable( KS_NAME );
	
	if( result )
	{
		self maps\mp\_matchdata::logKillstreakEvent( KS_NAME, self.origin );
	}
	
	// we're done carrying for sure and sometimes this might not get reset
	// this fixes a bug where you could be carrying and have it in a place where it won't plant, get killed, now you can't scroll through killstreaks
	self.isCarrying = undefined;
	
	return result;
}

createObject( streakName )	// self == barrier
{
	
}

onPlaced( streakName )	// self == barrier
{
	config = level.placeableConfigs[ streakName ];
	self setModel( config.modelBase );
	
	// turn on collisions
	// self SetContents( 1 );
	
	collision = spawn_tag_origin();
	collision Show();
	collision.origin = self.origin;
	
	//AssertMsg( IsDefined( level.barrierCollision ), "missing barrier_collision brush model for placeable_barrier" );
	if ( !IsDefined( level.barrierCollision ) )
	{
		setupBrushModel();
	}
	collision CloneBrushmodelToScriptmodel( level.barrierCollision );
	
	otherTeam = getOtherTeam( self.owner.team );
	BadPlace_Cylinder( streakName + (self GetEntityNumber()), -1, self.origin, config.colRadius, config.colHeight, otherTeam );
	
	self.collision = collision;
}

onCarried( streakName )	// self == barrier
{
	self disableCollision( streakName );
}

onDamaged( streakname, attacker, owner, damage )
{
	return damage;
}

onDestroyed( streakName, attacker, owner, sMeansOfDeath )	// self == barrier / victim
{
	
}

onDeath( streakName )
{
	self disableCollision( streakName );
	
	config = level.placeableConfigs[ streakName ];
	if ( IsDefined( config.deathSfx ) )
	{
		self PlaySound( config.deathSfx );
	}
	
	PlayFX( config.deathVfx, self.origin );
	
	wait( 0.5 );
}

disableCollision( streakName )
{
	// turn off the path blocker
	if ( IsDefined( self.collision ) )
	{
		BadPlace_Delete( streakName + (self GetEntityNumber()) );	
		
		// self.collision ConnectPaths();
		self.collision Delete();
		
		self.collision = undefined;
	}
}

setupBrushModel()
{
	scriptModel = GetEnt( "barrier_collision", "targetname" );
	
	if ( IsDefined ( scriptmodel ) )
	{
		level.barrierCollision = GetEnt( scriptModel.target, "targetname" );	
		scriptModel Delete();
	}
	
	if ( !IsDefined( level.barrierCollision ) )
	{
		Print( "!!! level does not contain a barrier_collision script model, please add one!" );
		level.barrierCollision = level.airDropCrateCollision;
	}
}