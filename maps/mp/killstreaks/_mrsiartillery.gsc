#include maps\mp\_utility;
#include common_scripts\utility;

KILLSTREAK_NAME = "mrsiartillery";

init()
{
	level.killstreakFuncs[ KILLSTREAK_NAME ] = ::tryUseStrike;
	
	configData = SpawnStruct();
	configData.weaponName = "airdrop_marker_mp";
	configData.projectileName = "mrsiartillery_projectile_mp";
	// configData.explodeVfx = LoadFX( "fx/explosions/aerial_explosion" );
	// configData.model = "projectile_icbm_missile";
	// configData.model = "mil_ammo_case_1_open";
	//configData.impactVfx = LoadFX( "fx/explosions/wall_explosion_pm_a" );
	configData.numStrikes = 6;
	configData.initialDelay = 1.0;
	configData.minFireDelay = 0.375;
	configdata.maxFireDelay = 0.5;
	configData.strikeRadius = 150;
	
	if ( !IsDefined( level.killstreakConfigData ) )
	{
		level.killstreakConfigData = [];
	}
	level.killstreakConfigData[ KILLSTREAK_NAME ] = configData;
}

tryUseStrike( lifeId, streakName )
{
	configData = level.killStreakConfigData[ KILLSTREAK_NAME ];
	result = self maps\mp\killstreaks\_designator_grenade::designator_Start( KILLSTREAK_NAME, configData.weaponName, ::onTargetAcquired );

	if ( ( !IsDefined( result ) || !result ) )
	{
		return false;
	}
	else
	{
		// self maps\mp\_matchdata::logKillstreakEvent( BOX_TYPE, self.origin );
	
		return true;
	}
}

onTargetAcquired( killstreakName, designatorEnt )	// self == player
{
	configData = level.killStreakConfigData[ killstreakName ];
	
	owner = designatorEnt.owner;
	endPos = designatorEnt.origin;
	
	designatorEnt Detonate();
	
	doStrike( owner, killstreakName, owner.origin, endPos );
}

doStrike( owner, killstreakName, startPosition, endPosition )
{
	configData = level.killStreakConfigData[ killstreakName ];
	
	// play some firing sounds
	
	dir = endPosition - startPosition;
	xyDir = ( dir[0], dir[1], 0);
	dir = VectorNormalize( dir );
	
	strikeTarget = endPosition;
	// shift up slightly to not intersect with ground
	strikeOrigin = maps\mp\killstreaks\_killstreaks::findUnobstructedFiringPoint( owner, endPosition + (0, 0, 10), 10000 );
	
	if ( IsDefined( strikeOrigin ) )
	{
		IPrintLn( "Firing Motar!" );
		
		// play sounds
		
		wait( configData.initialDelay );
		
		// always hit the target directly once
		wait( RandomFloatRange( configData.minFireDelay, configData.maxFireDelay ) );
		projectile = MagicBullet( configData.projectileName, strikeOrigin, strikeTarget, owner );
		
		// then scatter around
		for ( i = 1; i < configData.numStrikes; i++ )
		{
			wait( RandomFloatRange( configData.minFireDelay, configData.maxFireDelay ) );
			
			// pick target points
			randomTarget = pickRandomTargetPoint( strikeTarget, configData.strikeRadius );
			
			projectile = MagicBullet( configData.projectileName, strikeOrigin, randomTarget, owner );
		}
	}
	else
	{
		IPrintLn( "Mortar LOS blocked!" );
	}
}

pickRandomTargetPoint( targetPoint, strikeRadius )
{
	x = RandomFloatRange( -1 * strikeRadius, strikeRadius );
	y = RandomFloatRange( -1 * strikeRadius, strikeRadius );
	return targetPoint + (x, y, 0);
}