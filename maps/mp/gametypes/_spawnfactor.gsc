#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_gameobjects;


//===========================================
// 				constants
//===========================================
CONST_SCORE_FACTOR_MIN				= 0;
CONST_SCORE_FACTOR_MAX 				= 100;
CONST_PLAYER_DISTANCE_SQ_MAX		= 1800 * 1800;
CONST_NEARBY_DISTANCE_SQ			= 500 * 500;
CONST_EXPLOSIVE_RANGE_SQUARDED		= 350 * 350;
CONST_CARE_PACKAGE_RADIUS_SQUARED	= 150 * 150;
CONST_REVENGE_DISTANCE_SQUARED		= 1800 * 1800;
CONST_ENEMY_SPAWN_TIME_LIMIT		= 500;
CONST_RECENT_SPAWN_TIME_LIMIT		= 4000;
CONST_DIST_TO_HOMOGENIZATION		= 1024 * 1024;
CONST_TIME_TO_WAIT_FOR_SPAWN_CORRECTION = 25;
CONST_DOM_CONTESTED_FLAG_PENALTY	= 0.5;

//===========================================
// 				init
//===========================================
init_spawn_factors()
{
	if( !IsDefined( level.spawn_closeEnemyDistSq ) )
	{
		level.spawn_closeEnemyDistSq = CONST_NEARBY_DISTANCE_SQ;
	}
}


//===========================================
// 				score_factor
//===========================================
score_factor( weight, spawnFactorFunction, spawnPoint, optionalParam )
{
	if( IsDefined( optionalParam ) )
	{
		scoreFactor = [[spawnFactorFunction]]( spawnPoint, optionalParam );
	}
	else
	{
		scoreFactor = [[spawnFactorFunction]]( spawnPoint );
	}
	
	scoreFactor = clamp( scoreFactor, CONST_SCORE_FACTOR_MIN, CONST_SCORE_FACTOR_MAX );
	scoreFactor *= weight;
	
	/#
	spawnPoint.debugScoreData[spawnPoint.debugScoreData.size] = scoreFactor;
	spawnPoint.totalPossibleScore += CONST_SCORE_FACTOR_MAX * weight;
	#/
		
	return scoreFactor;
}


//===========================================
// 				critical_factor
//===========================================
critical_factor( spawnFactorFunction, spawnPoint )
{
	scoreFactor = [[spawnFactorFunction]]( spawnPoint );
	
	scoreFactor = clamp( scoreFactor, CONST_SCORE_FACTOR_MIN, CONST_SCORE_FACTOR_MAX );
	
	/#
	spawnPoint.debugCriticalData[spawnPoint.debugCriticalData.size] = scoreFactor;
	#/
		
	return scoreFactor;
}


//===========================================
// 			avoidCarePackages
//===========================================
avoidCarePackages( spawnPoint )
{	
	foreach( carePackage in level.carePackages )
	{
		if( !isdefined( carePackage ) )
			continue;
		
		if( DistanceSquared( spawnPoint.origin, carePackage.origin) < CONST_CARE_PACKAGE_RADIUS_SQUARED )
		{
			return CONST_SCORE_FACTOR_MIN;
		}
	}
	
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 				avoidGrenades
//===========================================
avoidGrenades( spawnPoint )
{
	foreach( grenade in level.grenades )
	{
		if( !isdefined( grenade ) 
			|| !(grenade isExplosiveDangerousToPlayer( spawnPoint ) )
		  )
		{
			continue;
		}
		
		if( DistanceSquared( spawnPoint.origin, grenade.origin) < CONST_EXPLOSIVE_RANGE_SQUARDED )
		{
			return CONST_SCORE_FACTOR_MIN;
		}
	}
	
	return CONST_SCORE_FACTOR_MAX;
}



//===========================================
// 				avoidMines
//===========================================
avoidMines( spawnPoint )
{
	explosiveArray = array_combine( level.mines, level.placedIMS );
	
	// For custom traps like scarabs in dig
	if ( IsDefined( level.traps ) && level.traps.size > 0 )
		explosiveArray = array_combine( explosiveArray, level.traps );
		
	foreach( explosive in explosiveArray )
	{
		if( !isdefined( explosive ) 
			|| !(explosive isExplosiveDangerousToPlayer( spawnPoint ) )
		  )
		{
			continue;
		}
		
		if( DistanceSquared( spawnPoint.origin, explosive.origin) < CONST_EXPLOSIVE_RANGE_SQUARDED )
		{
			return CONST_SCORE_FACTOR_MIN;
		}
	}
	
	return CONST_SCORE_FACTOR_MAX;
}

isExplosiveDangerousToPlayer( player )	// self == explosive
{
	if ( !level.teamBased
	    || level.friendlyfire 
	    || !IsDefined( player.team )
	   )
	{
		return true;
	}
	else
	{
		explosiveTeam = undefined;
		if ( IsDefined( self.owner ) )
		{
			explosiveTeam = self.owner.team;
		}
		
		if ( IsDefined( explosiveTeam ) )
		{
			return ( explosiveTeam != player.team );
		}
		else
		{
			return true;
		}
	}
}


//===========================================
// 		avoidAirStrikeLocations
//===========================================
avoidAirStrikeLocations( spawnPoint )
{
	if( !isDefined( level.artilleryDangerCenters ) )
		return CONST_SCORE_FACTOR_MAX;
	
	// spawn points located inside are good
	if( !spawnPoint.outside )
		return CONST_SCORE_FACTOR_MAX;
	
	// 0 = none, 1 = full, might be > 1 for more than 1 airstrike
	airstrikeDanger = maps\mp\killstreaks\_airstrike::getAirstrikeDanger( spawnPoint.origin ); 
		
	if( airstrikeDanger > 0 )
	{
		return CONST_SCORE_FACTOR_MIN;
	}
	
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidCornerVisibleEnemies
//===========================================
avoidCornerVisibleEnemies( spawnPoint )
{
	enemyTeam = "all";
	if( level.teambased )
	{
		enemyTeam = getEnemyTeam( self.team );
	}
	
	if( spawnPoint.cornerSights[enemyTeam] > 0 )
		return CONST_SCORE_FACTOR_MIN;
	
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidFullVisibleEnemies
//===========================================
avoidFullVisibleEnemies( spawnPoint )
{
	enemyTeam = "all";
	if( level.teambased )
	{
		enemyTeam = getEnemyTeam( self.team );
	}
	
	if( spawnPoint.fullSights[enemyTeam] > 0 )
		return CONST_SCORE_FACTOR_MIN;
	
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidCloseEnemies
//===========================================
avoidCloseEnemies( spawnPoint )
{
	enemyTeams = [];
	activeEnemyTeams = [];
	
	if( level.teambased )
	{
		enemyTeams[0] = getEnemyTeam( self.team );
	}
	else
	{
		enemyTeams[enemyTeams.size] = "all";
	}
	
	foreach( enemyTeam in enemyTeams )
	{
		// no enemies on this team were alive when this spawn point updated
		if( spawnpoint.totalPlayers[ enemyTeam ] == 0 )
		{
			continue;
		}
		
		activeEnemyTeams[activeEnemyTeams.size] = enemyTeam;
	}

	if( activeEnemyTeams.size == 0 )
	{
		return CONST_SCORE_FACTOR_MAX;
	}
	
	// there is an enemy in close proximity
	foreach( enemyTeam in activeEnemyTeams )
	{
		if( spawnpoint.minDistSquared[enemyTeam] < level.spawn_closeEnemyDistSq )
		{
			return CONST_SCORE_FACTOR_MIN;
		}
	}
	
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 				avoidTelefrag
//===========================================
avoidTelefrag( spawnPoint )
{
	if( isDefined( self.allowTelefrag ) )
		return CONST_SCORE_FACTOR_MAX;
	
	if( PositionWouldTelefrag( spawnPoint.origin ) )
	{
		foreach( alternate in spawnpoint.alternates )
		{
			if( !PositionWouldTelefrag( alternate ) )
			{
				return CONST_SCORE_FACTOR_MAX;
			}
		}
		
		return CONST_SCORE_FACTOR_MIN; 
	}
	
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidSameSpawn
//===========================================
avoidSameSpawn( spawnPoint )
{
	if( IsDefined( self.lastspawnpoint ) && ( self.lastspawnpoint == spawnPoint ) )
	{
		return CONST_SCORE_FACTOR_MIN;
	}
		
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidEnemySpawn
//===========================================
avoidEnemySpawn( spawnPoint )
{
	// the enemy team was the last team to use this spawn point
	if( IsDefined( spawnpoint.lastspawnteam ) && ( !level.teamBased || (spawnpoint.lastspawnteam != self.team) ) )
	{
		allowSpawnTime = spawnpoint.lastspawntime + CONST_ENEMY_SPAWN_TIME_LIMIT;
		
		if( GetTime() < allowSpawnTime )
		{
			return CONST_SCORE_FACTOR_MIN;
		}
	}
		
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidRecentlyUsedByEnemies
//===========================================
avoidRecentlyUsedByEnemies( spawnPoint )
{
	wasUsedByEnemy = !level.teamBased || ( IsDefined( spawnPoint.lastspawnteam ) && self.team != spawnPoint.lastspawnteam );
	if( wasUsedByEnemy && IsDefined(spawnpoint.lastspawntime) )
	{
		timePassed = GetTime() - spawnpoint.lastspawntime;
		
		if( timePassed > CONST_RECENT_SPAWN_TIME_LIMIT )
			return CONST_SCORE_FACTOR_MAX;
		
		return (timePassed / CONST_RECENT_SPAWN_TIME_LIMIT) * CONST_SCORE_FACTOR_MAX;
	}
	
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidRecentlyUsedByAnyone
//===========================================
avoidRecentlyUsedByAnyone( spawnPoint )
{
	if( IsDefined(spawnpoint.lastspawntime) )
	{
		timePassed = GetTime() - spawnpoint.lastspawntime;
		
		if( timePassed > CONST_RECENT_SPAWN_TIME_LIMIT )
			return CONST_SCORE_FACTOR_MAX;
		
		return (timePassed / CONST_RECENT_SPAWN_TIME_LIMIT) * CONST_SCORE_FACTOR_MAX;
	}
	
	return CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidLastDeathLocation
//===========================================
avoidLastDeathLocation( spawnPoint )
{
	if( !isDefined( self.lastDeathPos ) )
	{
	   	return CONST_SCORE_FACTOR_MAX;
	}
	
	distsq = DistanceSquared( spawnpoint.origin, self.lastDeathPos );
	
	if( distsq > CONST_REVENGE_DISTANCE_SQUARED )
	{
		return CONST_SCORE_FACTOR_MAX;
	}
	
	// high distance away is good
	percentDist = ( distsq / CONST_REVENGE_DISTANCE_SQUARED );
		
	return percentDist * CONST_SCORE_FACTOR_MAX;
}


//===========================================
// 			avoidLastAttackerLocation
//===========================================
avoidLastAttackerLocation( spawnPoint )
{
	if ( !isDefined( self.lastAttacker ) || !isDefined( self.lastAttacker.origin ) )
	{
	   	return CONST_SCORE_FACTOR_MAX;
	}
	
	if( !isReallyAlive(self.lastAttacker) )
	{
		return CONST_SCORE_FACTOR_MAX;
	}
	
	distsq = DistanceSquared( spawnpoint.origin, self.lastAttacker.origin );
	
	if( distsq > CONST_REVENGE_DISTANCE_SQUARED )
	{
		return CONST_SCORE_FACTOR_MAX;
	}
	
	// high distance away is good
	percentDist = ( distsq / CONST_REVENGE_DISTANCE_SQUARED );
		
	return percentDist * CONST_SCORE_FACTOR_MAX;
}


CONST_FRONTLINE_UPDATE_SCALE = 10;
CONST_FRONTLINE_EVALUATE_TIME = 0.05 * CONST_FRONTLINE_UPDATE_SCALE;
CONST_FRONTLINE_ROT_SPEED = 0.4 * CONST_FRONTLINE_UPDATE_SCALE;
CONST_FRONTLINE_SPEED = 10 * CONST_FRONTLINE_UPDATE_SCALE;
CONST_FRONTLINE_MIN_SPAWNS = 3;
CONST_FRONTLINE_TRAPPED_SPAWN_PERCENT = 0.5;


//===========================================
// 			spawnFrontLineThink
// The intent of the "Front Line" behavior is to attempt to create a 'front line' between the two teams
// by splitting the spawns into two sections, one that belongs to each team. Where the split occurs
// is determined by taking the average position of the two teams, finding the midpoint between them, and
// creating a line perpendicular to the line that connects each team 'center'.
//===========================================
spawnFrontLineThink()
{
	if( !level.teamBased )
		return;
	
	while( !isDefined( level.spawnpoints ) )
		wait .05;
	
	frontLineTeamDiffYaw = undefined;
	frontLineMidpoint = undefined;
	
	useLog = IsDefined( level.matchRecording_logEvent ) && IsDefined( level.matchRecording_generateID );
	useDebugDraw = GetDvarInt( "scr_draw_frontline" ) == 1;
	
	minUsableSpawns = GetDvarInt( "scr_frontline_min_spawns", 0 );
	if( minUsableSpawns == 0)
		minUsableSpawns = CONST_FRONTLINE_MIN_SPAWNS;
	
	checkSpawnRatio = GetDvarInt( "scr_frontline_disable_ratio_check", 0 ) != 1;
	
	for( ;; )
	{
		wait( CONST_FRONTLINE_EVALUATE_TIME );
		
		axisTeam = [];
		alliesTeam = [];
		
		// Gather the list of players to evaluate
		foreach ( player in level.players )
		{
			if( !isDefined( player )  )
				continue;
			
			if( !isReallyAlive( player ) )
				continue;
			
			if ( player.team == "axis" )
				axisTeam[ axisTeam.size ] = player;
			else
				alliesTeam[ alliesTeam.size ] = player;
			
		}
		
		// Get the team centers
		alliesAverage = getAverageOrigin(alliesTeam);
		if ( !IsDefined( alliesAverage ) )
		{
			wait 0.05;
			continue;
		}
		alliesAverage = ( alliesAverage[0], alliesAverage[1], 0 );
		
		axisAverage = getAverageOrigin(axisTeam);
		if ( !IsDefined( axisAverage ) )
		{
			wait 0.05;
			continue;
		}
		axisAverage = ( axisAverage[0], axisAverage[1], 0 );
		
		// Convert the vector between the two spawns for this frame to a yaw angle so that we can control it's rotation
		idealTeamDiff = axisAverage - alliesAverage;
		idealTeamDiffYaw = VectorToYaw( idealTeamDiff );
		
		if( !IsDefined( frontLineTeamDiffYaw ) )
			frontLineTeamDiffYaw = idealTeamDiffYaw;
		
		// Update our stored "frontline" to move towards the frontline calculated for this frame.
		
		// Rotate the frontline angle towards this frame's angle.
		rotSpeed = CONST_FRONTLINE_ROT_SPEED;
		yawDelta = idealTeamDiffYaw - frontLineTeamDiffYaw;
		if( yawDelta > 180 )
			yawDelta = yawDelta - 360;
		else if( yawDelta < -180 )
			yawDelta = 360 + yawDelta;
		rotSpeed = clamp( yawDelta, rotSpeed * -1, rotSpeed );
		frontLineTeamDiffYaw += rotSpeed;
		
		// Move the frontline midpoint towards the current midpoint
		idealMidpoint = alliesAverage + ( idealTeamDiff * 0.5 );
		if( !IsDefined( frontLineMidpoint ) )
			frontLineMidpoint = idealMidpoint;
		
		midpointDelta = idealMidpoint - frontLineMidpoint;
		midpointDeltaDist = Length2D( midpointDelta );
		midpointMoveDist = min( midpointDeltaDist, CONST_FRONTLINE_SPEED );
		if( midpointMoveDist > 0 )
		{
			midpointDelta = midpointDelta * ( midpointMoveDist / midpointDeltaDist );
			frontLineMidpoint = frontLineMidpoint + midpointDelta;
		}
		
		
		// Convert the frontline's angle back into a vector for us in assigning spawns.
		frontLineTeamDiff = AnglesToForward( (0, frontLineTeamDiffYaw, 0 ) );
		
		// Go through all of the spawns and assign them to a team
		usableSpawnCounts = [];
		usableSpawnCounts[ "allies" ] = 0;
		usableSpawnCounts[ "axis" ] = 0;
		spawnPoints = level.spawnpoints;
		spawnPoints = maps\mp\gametypes\_spawnscoring::checkDynamicSpawns( spawnPoints );
		foreach( spawnPoint in spawnPoints )
		{
			assignedTeam = undefined;
			// Calculate if the spawnpoint is in front or behind the frontline.
			spawnToMidpoint = frontLineMidpoint - spawnPoint.origin;
			dotValue = VectorDot( spawnToMidpoint, frontLineTeamDiff );
			if( dotValue > 0 )
			{
				assignedTeam = "allies";
				spawnPoint.forcedTeam = assignedTeam;
			}
			else
			{
				assignedTeam = "axis";
				spawnPoint.forcedTeam = assignedTeam;
			}
			
			// Only count this spawn if it is not in-sight of a player
			// NOTE: This is only checking if enemies can directly see this spawn point. It doesn't check for other critical factors that would
			// make this a bad spawn (such as an explosive being too close). We could potentially add checks for this, but it would be more computationally
			// expensive, and potentially unnecessary.
			enemyTeam = getOtherTeam( assignedTeam );
			if( !IsDefined( spawnPoint.fullSights ) || !IsDefined( spawnPoint.fullSights[ enemyTeam ] ) || spawnPoint.fullSights[ enemyTeam ] <= 0 )
				usableSpawnCounts[ assignedTeam ]++;
		}
		
		// Check to see if there are too few (usable) spawns so that we can avoid potential spawn trapping.
		lessSpawnsTeam = ter_op( usableSpawnCounts[ "allies" ] < usableSpawnCounts[ "axis" ], "allies", "axis" );
		moreSpawnsTeam = getOtherTeam( lessSpawnsTeam );
		spawnCountsAreUnbalanced = usableSpawnCounts[ lessSpawnsTeam ] < usableSpawnCounts[ moreSpawnsTeam ] * CONST_FRONTLINE_TRAPPED_SPAWN_PERCENT;
		if( usableSpawnCounts[ lessSpawnsTeam ] <= minUsableSpawns || ( checkSpawnRatio && spawnCountsAreUnbalanced ) )
		{
			// Clear all the team assignments
			foreach( spawnPoint in spawnPoints )
			{
				spawnPoint.forcedTeam = undefined;
			}
			
			// Clear the frontline so that it is constantly recalculated
			frontLineMidpoint = undefined;
			frontLineTeamDiffYaw = undefined;
		}
		
		if( ( useLog || useDebugDraw ) )
		{
			if( useLog && !IsDefined( level.frontlineLogIDs ) )
			{
				level.frontlineLogIDs = [];
				level.frontlineLogIDs["line" ] = [[ level.matchRecording_generateID ]]();
				level.frontlineLogIDs["alliesCenter"] = [[ level.matchRecording_generateID ]]();
				level.frontlineLogIDs["axisCenter"] = [[ level.matchRecording_generateID ]]();
			}
			
			if( IsDefined( frontLineMidpoint ) && IsDefined( frontLineTeamDiffYaw ) )
			{
				drawMidpoint = ( frontLineMidpoint[0], frontLineMidpoint[1], level.mapCenter[2] );
				bisectLine = AnglesToRight( (0, frontLineTeamDiffYaw, 0 ) );
				bisectLineStart = drawMidpoint + ( bisectLine * 5000 );
				bisectLineEnd = drawMidpoint - ( bisectLine * 5000 );
				
				/#
				if( useDebugDraw )
				{
					Line( drawMidpoint, bisectLineEnd, ( 0, 1, 1 ), 0, false, CONST_FRONTLINE_UPDATE_SCALE );
					Line( bisectLineStart, drawMidpoint, ( 0, 0.5, 0.5 ), 0, false, CONST_FRONTLINE_UPDATE_SCALE );
				}
				#/
				
				if( useLog )
					[[ level.matchRecording_logEvent ]]( level.frontlineLogIDs["line"], "allies", "FRONT_LINE", bisectLineStart[0], bisectLineStart[1], GetTime(), undefined, bisectLineEnd[0], bisectLineEnd[1] );
				
				/#
				drawMidpoint = ( idealMidpoint[0], idealMidpoint[1], level.mapCenter[2] );
				idealLine = AnglesToRight( (0, idealTeamDiffYaw, 0 ) );
				idealLineStart = drawMidpoint + ( idealLine * 5000 );
				idealLineEnd = drawMidpoint - ( idealLine * 5000 );
				if( useDebugDraw )
				{
					Line( drawMidpoint, idealLineEnd, ( 0, 1, 0 ), 0, false, CONST_FRONTLINE_UPDATE_SCALE );
					Line( idealLineStart, drawMidpoint, ( 0, 0.5, 0 ), 0, false, CONST_FRONTLINE_UPDATE_SCALE );
				}
				#/
			}
			else
			{
				if( useLog )
					[[ level.matchRecording_logEvent ]]( level.frontlineLogIDs["line" ], "allies", "FRONT_LINE", 0, 0, GetTime(), undefined, 0, 0 );
			}
			
			// Draw Team Centers
			if( useLog )
			{
				[[ level.matchRecording_logEvent ]]( level.frontlineLogIDs["alliesCenter"], "axis", "ANCHOR", axisAverage[ 0 ], axisAverage[ 1 ], GetTime() );
				[[ level.matchRecording_logEvent ]]( level.frontlineLogIDs["axisCenter"], "allies", "ANCHOR", alliesAverage[ 0 ], alliesAverage[ 1 ], GetTime() );
			}
		}
	}
	
}

//===========================================
// 	 		correctHomogenization
//
//	level.axisWeight & level.alliesWeight
//	is only defined if they should be used
//	used in _spawnlogic.gsc added to distance
//	ents.
//
//===========================================
correctHomogenization()
{
	level notify( "correctHomogenization" );
	level endon( "correctHomogenization" );
	
	if( !level.teamBased )
		return;
	
	//each cycle is 40 seconds long
	cyclesToFlip = 2;
	numCyclesStuck = 0;	
	
	alliesStartSpawns = [];
	axisStartSpawns = [];
	zoneOnePoints = [];
	zoneTwoPoints = [];
	sortedPoints = [];
	UsableEdges = [];
	
	alliesStartSpawns = GetSpawnArray( "mp_tdm_spawn_allies_start");
	axisStartSpawns = GetSpawnArray( "mp_tdm_spawn_axis_start");
	lastAlliesAnchorOriginHistory = [];
	
	while( !isDefined( level.spawnpoints ) )
		wait .05;
	
	mapname = ToLower( getDvar( "mapname" ) );
	
	if( mapname == "mp_strikezone" )
	{
		foreach ( point in level.spawnpoints)
		{
			if ( point.origin[2] < 20000 )
				zoneOnePoints[zoneOnePoints.size] = point;
			else
				zoneTwoPoints[zoneTwoPoints.size] = point;
		}
		
		if( level.teleport_zone_current == "start" )
			sortedPoints = SortByDistance( zoneOnePoints, level.mapCenter );
		else
			sortedPoints = SortByDistance( zoneTwoPoints, level.mapCenter );
		
		for( i = 0; i < 8; i++ )
		{
			usableEdges[i] = sortedPoints[sortedPoints.size - (i+1)];
		}
	}
	else
	{
		sortedPoints = SortByDistance( level.spawnpoints, level.mapCenter );
		
		for( i = 0; i < 8; i++ )
		{
			usableEdges[i] = sortedPoints[sortedPoints.size - (i+1)];
		}
		
		usableEdges[usableEdges.size] = alliesStartSpawns[0];
		usableEdges[usableEdges.size] = axisStartSpawns[0];
	}
	
	anchorSpawnType = Int( GetDvar( "scr_anchorSpawns" ) );
	
	for( ;; )
	{
		wait( 5 );
		
		axisTeam = [];
		alliesTeam = [];
		foreach ( player in level.players )
		{
			if( !isDefined( player )  )
				continue;
			
			if( !isReallyAlive( player ) )
				continue;
			
			if ( player.team == "axis" )
				axisTeam[ axisTeam.size ] = player;
			else
				alliesTeam[ alliesTeam.size ] = player;
		}
		
		alliesAverage = getAverageOrigin(alliesTeam);
		
		if ( !IsDefined( alliesAverage ) )
		{
			wait 0.05;
			continue;
		}
	
		//add friendly weight to either end of the map
		alliesBestAnchors = [];
		alliesBestAnchors = SortByDistance( usableEdges, alliesAverage );
		anchor = alliesBestAnchors[ 0 ];
		
		stuckThisCycle = false;
		alliesAnchorToUse = undefined;
		
		for ( i = 0; i < lastAlliesAnchorOriginHistory.size; i++)
		{
			if( anchor == lastAlliesAnchorOriginHistory[i] )
			{
				stuckThisCycle = true;
			}
			else
			{
				stuckThisCycle = false;
				break;
			}
		}
		
		if( stuckThisCycle )
		{
			numCyclesStuck += 1;
			
			//flipping spawn anchor
			if( numCyclesStuck >= cyclesToFlip )
			{
				//IPrintLnBold( "SPAWNS FLIPPED" );
				alliesAnchorToUse = alliesBestAnchors[alliesBestAnchors.size-1];
				lastAlliesAnchorOriginHistory[lastAlliesAnchorOriginHistory.size] = alliesAnchorToUse;
			}
		}
		
		if( !IsDefined(alliesAnchorToUse) )
		{
			alliesAnchorToUse = anchor;
			lastAlliesAnchorOriginHistory[lastAlliesAnchorOriginHistory.size] = alliesAnchorToUse;
		}
		
		axisBestAnchors = [];
		axisBestAnchors = SortByDistance( usableEdges, alliesAnchorToUse.origin );
		axisAnchorToUse = axisBestAnchors[axisBestAnchors.size-1];
		
		//self thread drawLine( alliesAnchorToUse.origin+(0,0,45), alliesAverage+(0,0,45), 4, (0,0,1) );
		//self thread drawLine( axisAnchorToUse.origin+(0,0,45), alliesAverage+(0,0,45), 4, (1,0,0) );
		
		level.alliesWeightOrg = alliesAnchorToUse.origin;
		level.axisWeightOrg = axisAnchorToUse.origin;
		
	}
	
}


//=====================================================================
// 	 		detectPlayerHomogenization  UNUSED PART OF ANCHOR SPAWNING
//=====================================================================
detectHomogenization()
{
	axisTeam = [];
	alliesTeam = [];
	
	if ( level.teamBased )
	{
		foreach ( player in level.players )
		{
			if( !isDefined( player )  )
				continue;
			
			if( !isReallyAlive( player ) )
				continue;
			
			if ( player.team == "axis" )
				axisTeam[ axisTeam.size ] = player;
			else
				alliesTeam[ alliesTeam.size ] = player;
		}
		
		averageAxisLocation = getAverageOrigin( axisTeam );
		averageAlliesLocation = getAverageOrigin( alliesTeam );
		
		if ( !isDefined( averageAlliesLocation ) || !isDefined( averageAxisLocation ) )
			return false;
	
		if ( distance_2d_squared ( averageAlliesLocation, averageAxisLocation ) < CONST_DIST_TO_HOMOGENIZATION )
			return true;
		else
			return false;
	}
	else
	{
		return false;
	}
	
}


//===========================================
// 	 		preferAlliesByDistance
//===========================================
preferAlliesByDistance( spawnPoint )
{
	// no teammates where alive when this spawn point updated
	if( spawnpoint.totalPlayers[ self.team ] == 0 )
	{
		return CONST_SCORE_FACTOR_MIN;
	}
	
	// average ally distance away from spawn point
	allyAverageDist = spawnPoint.distSumSquared[self.team] / spawnpoint.totalPlayers[self.team];
	allyAverageDist = min( allyAverageDist, CONST_PLAYER_DISTANCE_SQ_MAX );
	
	// high ally distance is bad
	scoringPercentage = 1 - ( allyAverageDist / CONST_PLAYER_DISTANCE_SQ_MAX );
	
	return scoringPercentage * CONST_SCORE_FACTOR_MAX;
}
	
	
//===========================================
// 	   		avoidEnemiesByDistance
// This returns a score based on the average
// distance from all enemies.
//===========================================
avoidEnemiesByDistance( spawnPoint )
{
	enemyTeams = [];
	activeEnemyTeams = [];
	
	if( level.teambased )
	{
		enemyTeams[0] = getEnemyTeam( self.team );
	}
	else
	{
		enemyTeams[enemyTeams.size] = "all";
	}
	
	foreach( enemyTeam in enemyTeams )
	{
		// no enemies on this team were alive when this spawn point updated
		if( spawnpoint.totalPlayers[ enemyTeam ] == 0 )
		{
			continue;
		}
		
		activeEnemyTeams[activeEnemyTeams.size] = enemyTeam;
	}

	if( activeEnemyTeams.size == 0 )
	{
		return CONST_SCORE_FACTOR_MAX;
	}
	
	// there is an enemy in close proximity
	foreach( enemyTeam in activeEnemyTeams )
	{
		if( spawnpoint.minDistSquared[enemyTeam] < CONST_NEARBY_DISTANCE_SQ )
		{
			return CONST_SCORE_FACTOR_MIN;
		}
	}
	
	totalDistance 	= 0;
	totalEnemies 	= 0;
	
	foreach( enemyTeam in activeEnemyTeams )
	{
		totalDistance 	+= spawnPoint.distSumSquaredCapped[enemyTeam];
		totalEnemies 	+= spawnpoint.totalPlayers[enemyTeam];
	}
	
	// average enemy distance away from spawn point
	enemeyAverageDist = totalDistance / totalEnemies;
	
	// high enemy distance is good
	enemeyAverageDist = min( enemeyAverageDist, CONST_PLAYER_DISTANCE_SQ_MAX );
	scoringPercentage = ( enemeyAverageDist / CONST_PLAYER_DISTANCE_SQ_MAX );	
	
	return scoringPercentage * CONST_SCORE_FACTOR_MAX;
}
	
	
//===========================================
// 	   		avoidClosestEnemy
// This returns a score based on how close the
// closest enemy is.
//===========================================
avoidClosestEnemy( spawnPoint )
{
	enemyTeams = [];
	activeEnemyTeams = [];
	
	if( level.teambased )
	{
		enemyTeams[0] = getEnemyTeam( self.team );
	}
	else
	{
		enemyTeams[enemyTeams.size] = "all";
	}
	
	foreach( enemyTeam in enemyTeams )
	{
		// no enemies on this team were alive when this spawn point updated
		if( spawnpoint.totalPlayers[ enemyTeam ] == 0 )
		{
			continue;
		}
		
		activeEnemyTeams[activeEnemyTeams.size] = enemyTeam;
	}

	if( activeEnemyTeams.size == 0 )
	{
		return CONST_SCORE_FACTOR_MAX;
	}
	
	scoreTotal = 0;
	foreach( enemyTeam in activeEnemyTeams )
	{
		if( spawnpoint.minDistSquared[enemyTeam] < CONST_NEARBY_DISTANCE_SQ )
		{
			return CONST_SCORE_FACTOR_MIN;
		}
		
		minEnemyDistSquared = min( spawnpoint.minDistSquared[enemyTeam], CONST_PLAYER_DISTANCE_SQ_MAX );
		scoringPercentage = ( minEnemyDistSquared / CONST_PLAYER_DISTANCE_SQ_MAX );
		scoreTotal += scoringPercentage * CONST_SCORE_FACTOR_MAX;
	}
	
	return scoreTotal / activeEnemyTeams.size;
}


//===========================================
// 	   			scoreDomPoint
//===========================================
scoreDomPoint( domPointNumber )
{
	domFlag = undefined;
	foreach( flag in level.domFlags )
	{
		if( IsDefined( flag.domPointNumber ) && flag.domPointNumber == domPointNumber )
		{
			domFlag = flag;
			break;
		}
	}
	
	if( !IsDefined( domFlag ) )
	{
		AssertMsg( "Could not find domFlag with domPointNumber " + domPointNumber );
		return CONST_SCORE_FACTOR_MAX;
	}
	
	claimTeam = domFlag maps\mp\gametypes\_gameobjects::getClaimTeam();
	if( claimTeam == "none" )
		return CONST_SCORE_FACTOR_MAX;
	else
		return CONST_SCORE_FACTOR_MAX * CONST_DOM_CONTESTED_FLAG_PENALTY;
}


//===========================================
// 	   			preferDomPoints
//===========================================
preferDomPoints( spawnPoint, perferdDomPointArray )
{
	if( perferdDomPointArray[0] && spawnPoint.domPointA )
	{
		return scoreDomPoint( 0 );
	}
	
	if( perferdDomPointArray[1] && spawnPoint.domPointB )
	{
		return scoreDomPoint( 1 );
	}
		
	if( perferdDomPointArray[2] && spawnPoint.domPointC )
	{
		return scoreDomPoint( 2 );
	}
	
	return CONST_SCORE_FACTOR_MIN;
}


//===========================================
// 	   			preferClosePoints
//===========================================
preferClosePoints( spawnPoint, preferdPointArray )
{
	foreach ( point in preferdPointArray)
	{
		if( spawnPoint == point )
			return CONST_SCORE_FACTOR_MAX;
	}
	
	return CONST_SCORE_FACTOR_MIN;
}

//===========================================
// 	   		preferByTeamBase
//===========================================
preferByTeamBase( spawnPoint, team )
{
	if( IsDefined(spawnPoint.teamBase) &&  (spawnPoint.teamBase == team) )
	{
		return CONST_SCORE_FACTOR_MAX;
	}
	
	return CONST_SCORE_FACTOR_MIN;
}


//===========================================
// 	   		randomSpawnScore
//===========================================
randomSpawnScore( spawnPoint )
{
	return( RandomIntRange(CONST_SCORE_FACTOR_MIN, CONST_SCORE_FACTOR_MAX - 1) );
}


//===========================================
// 	   		maxPlayerSpawnInfluenceDistSquared
//===========================================
maxPlayerSpawnInfluenceDistSquared( spawnPoint )
{
	return CONST_REVENGE_DISTANCE_SQUARED;
}
