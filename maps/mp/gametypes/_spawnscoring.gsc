#include maps\mp\gametypes\_spawnfactor;
#include common_scripts\utility;
#include maps\mp\_utility;


//===========================================
// 			getSpawnpoint_NearTeam
//===========================================
getSpawnpoint_NearTeam( spawnPoints )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	spawnChoices["primary"] 	= [];
	spawnChoices["secondary"] 	= [];
	spawnChoices["bad"] 		= [];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		result = criticalFactors_NearTeam( spawnPoint );
	
		spawnChoices[result][spawnChoices[result].size] = spawnPoint;
	}
	
	if( spawnChoices["primary"].size )
		return scoreSpawns_NearTeam( spawnChoices["primary"] );
	
	if( spawnChoices["secondary"].size )
		return scoreSpawns_NearTeam( spawnChoices["secondary"] );
	
	logBadSpawn( "Buddy Spawn" );
	return selectBestSpawnPoint( spawnPoints[0], spawnPoints );
}


//============================================
// 			scoreSpawns_NearTeam
//============================================
scoreSpawns_NearTeam( spawnPoints )
{
	bestSpawn = spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{	
		// calculates the total score of the spawn point
		scoreFactors_NearTeam( spawnPoint );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}


//============================================
// 			checkDynamicSpawns
//============================================
checkDynamicSpawns( spawnPoints )
{
	// a function callback that allows level script to adjust spawn points dynamically based on level specific events
	if( isDefined( level.dynamicSpawns ) )
	{
		spawnPoints = [[level.dynamicSpawns]]( spawnPoints );
	}
	
	return spawnPoints;
}


//============================================
// 			selectBestSpawnPoint
//============================================
selectBestSpawnPoint( highestScoringSpawn, spawnPoints )
{
	bestSpawn = highestScoringSpawn;
	numberOfPossibleSpawnChoices = 0;
	
	// calcualte the number of available spawns
	foreach( spawnPoint in spawnPoints )
	{
		if( spawnPoint.totalScore > 0 )
		{
			numberOfPossibleSpawnChoices++;
		}
	}
		
	// not enough avaliable spawns to guarantee a good spawn
	if( ( numberOfPossibleSpawnChoices == 0 ) || level.forceBuddySpawn )
	{
		// try to spawn on a buddy
		if( level.teamBased && level.supportBuddySpawn )
		{
			teamSpawnPoint = findBuddySpawn();

			if( teamSpawnPoint.buddySpawn )
			{
				bestSpawn = teamSpawnPoint;
			}
		}

		// if all spawn points are bad, pick randomly
		if( bestSpawn.totalScore == 0 )
		{
			logBadSpawn( "UNABLE TO BUDDY SPAWN. Extremely bad." );
			bestSpawn = spawnPoints[RandomInt( spawnPoints.size )];
		}
	}
	
	/#
	bestSpawn.numberOfPossibleSpawnChoices = numberOfPossibleSpawnChoices;
	#/
	
	return bestSpawn;
}


//============================================
// 		 	findSecondHighestSpawnScore
//============================================
findSecondHighestSpawnScore( highestScoringSpawn, spawnPoints )
{
	if( spawnPoints.size < 2 )
	{
		return highestScoringSpawn;
	}
	
	bestSpawn = spawnPoints[0];
	
	// exclude the highest scoring spawn
	if( bestSpawn == highestScoringSpawn )
	{
		bestSpawn = spawnPoints[1];
	}
	
	foreach( spawnPoint in spawnPoints )
	{
		// exclude the highest scoring spawn
		if( spawnPoint == highestScoringSpawn )
		{
			continue;
		}
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	return bestSpawn;
}


//============================================
// 				findBuddySpawn
//============================================
findBuddySpawn()
{
	spawnLocation = SpawnStruct();
	initScoreData( spawnLocation );
	
	teamMates = getTeamMatesOutOfCombat( self.team );
	
	trace = SpawnStruct();
	trace.maxTraceCount = 18;
	trace.currentTraceCount = 0;
	
	foreach( player in teamMates )
	{
		location = findSpawnLocationNearPlayer( player );
		
		if( !IsDefined( location ) )
		{
			continue;
		}
		
		if( isSafeToSpawnOn( player, location, trace ) )
		{
			spawnLocation.totalScore 	= 999;
			spawnLocation.buddySpawn	= true;
			spawnLocation.origin 		= location;
			spawnLocation.angles		= getBuddySpawnAngles( player, spawnLocation.origin );
			break;
		}
		
		if( trace.currentTraceCount == trace.maxTraceCount )
		{
			break;
		}
	}
	
	return spawnLocation;
}


//============================================
// 			getBuddySpawnAngles
//============================================
getBuddySpawnAngles( buddy, spawnLocation )
{
	// start with the buddy's angles
	spawnAngles = ( 0, buddy.angles[1], 0 );
	
	entranceNodes = FindEntrances( spawnLocation );
	
	// pick an angle that faces an entrace
	if( IsDefined(entranceNodes) && (entranceNodes.size > 0) )
	{
		spawnAngles = VectorToAngles( entranceNodes[0].origin - spawnLocation );
	}
	
	return spawnAngles;
}


//============================================
// 			getTeamMatesOutOfCombat
//============================================
getTeamMatesOutOfCombat( team )
{
	teamMates = [];
	
	foreach( player in level.players )
	{
		// only find teammates
		if( player.team != team )
		{
			continue;
		}
		
		// only find active teammates
		if( player.sessionstate != "playing" )
		{
			continue;
		}
		
		if( !isReallyAlive(player) )
		{
			continue;
		}
		
		if( player == self )
		{
			continue;
		}
		
		// only find players not in combat
		if( isPlayerInCombat( player ) )
		{
			continue;
		}
		
		teamMates[teamMates.size] = player;
	}

	return array_randomize( teamMates );
}


//============================================
// 			isPlayerInCombat
//============================================
DAMAGE_COOLDOWN = 3000;
isPlayerInCombat( player, bUseLessStrictHealthCheck )
{
	if( player IsSighted() )
	{
		debugCombatCheck( player, "IsSighted" );
		return true;
	}
		
	// player must be on the ground
	if( !player IsOnGround() )
	{
		debugCombatCheck( player, "IsOnGround" );
		return true;
	}
	
	if( player IsOnLadder() )
	{
		debugCombatCheck( player, "IsOnLadder" );
		return true;
	}
	
	if( player isFlashed() )
	{
		debugCombatCheck( player, "isFlashed" );
		return true;
	}
	
	if ( IsDefined( bUseLessStrictHealthCheck ) && bUseLessStrictHealthCheck )
	{
		// for battle buddy spawns, allow cases where the player has not been damaged recently
		if ( player.health < player.maxhealth
			&& (!IsDefined( player.lastDamagedTime ) || GetTime() < player.lastDamagedTime + DAMAGE_COOLDOWN )
	    )
		{
			debugCombatCheck( player, "RecentDamage" );
			return true;
		}
	}
	else
	{
		// for normal spawns, allow only full health players since there are many possible candidates
		if( player.health < player.maxhealth )
		{
			debugCombatCheck( player, "MaxHealth" );
			return true;
		}
	}
	
	// player cannot be near any grenades
	if( !avoidGrenades( player ) )
	{
		debugCombatCheck( player, "Grenades" );
		return true;
	}
	
	// player cannot be near any explosives
	if( !avoidMines( player ) )
	{
		debugCombatCheck( player, "Mines" );
		return true;
	}
	
	return false;
}

debugCombatCheck( player, reason )
{
	// IPrintLn( "InCombat: " + player.name + ": " + reason );
	buddyName = "none";
	if ( IsDefined( player.battleBuddy ) )
	{
		buddyName = player.battleBuddy.name;
	}
	bbprint( "battlebuddy_spawn", "player %s buddy %s reason %s", player.name, buddyName, reason );
}


//============================================
// 		findSpawnLocationNearPlayer
//============================================
findSpawnLocationNearPlayer( player )
{
	playerHeight = maps\mp\gametypes\_spawnlogic::getPlayerTraceHeight( player, true );
	// player's FOV is actually 65 degrees total, so 37.5 on each side
	// but we'll do a somewhat conservative 60 degrees
	buddyNode = findBuddyPathNode( player, playerHeight, 0.5 );
	
	if( IsDefined( buddyNode ) )
	{
		return buddyNode.origin;
	}
	
	return undefined;
}


//============================================
// 			findBuddyPathNode
//============================================
findBuddyPathNode( buddy, playerHeight, cosAngle )
{
	nodeArray 	= GetNodesInRadiusSorted( buddy.origin, 192, 64, playerHeight, "Path" );
	bestNode 	= undefined;
	
	if( IsDefined(nodeArray) && nodeArray.size > 0 )
	{
		buddyDir = AnglesToForward( buddy.angles );
		
		// loop to find a node that is not in the player's current FOV
		foreach( buddyNode in nodeArray )
		{
			directionToNode = VectorNormalize( buddyNode.origin - buddy.origin );
			dot = VectorDot( buddyDir, directionToNode );
			
			//Fixes bad buddy spawns in Fahrenheit. IW6 TU1
			if ( getMapName() == "mp_fahrenheit" )
			{
				//these are bad spawn pathnode locations
				if (buddyNode.origin == (1778.9,171.6,716) ||
					buddyNode.origin == (1772.1,271.4,716) ||
					buddyNode.origin == (1657.2,259.6,716) ||
					buddyNode.origin == (1633.7,333.9,716) ||
					buddyNode.origin == (1634.4,415.7,716) ||
					buddyNode.origin == (1537.3,419.3,716) ||
					buddyNode.origin == (1410.9,420.8,716) ||
					buddyNode.origin == (1315.6,416.6,716) ||
					buddyNode.origin == (1079.4,414.6,716) ||
					buddyNode.origin == (982.9,421.8,716)  ||
					buddyNode.origin == (896.9,423.8,716) )
						continue;
			}
			
			if( (dot <= cosAngle) && !positionWouldTelefrag( buddyNode.origin ) )
			{
				// trace from the buddy to the buddySpawnLocation at head level 
				// this check ensures players do not buddy spawn on the opposite side of a wall  
				if( sightTracePassed( buddy.origin + (0,0,playerHeight), buddyNode.origin + (0,0,playerHeight), false, buddy ) )
				{
					bestNode = buddyNode;
					
					// if we found a point that's behind the player, stop
					// but if it's out of FOV but in front, try to find a better candidate
					if ( dot <= 0.0 )
					{
						break;
					}
				}
			}
		}
	}
	
	return bestNode;
}

findDronePathNode( owner, spawnHeight, droneHalfSize, searchRadius )
{
	nodeArray 	= GetNodesInRadiusSorted( owner.origin, searchRadius, 32, spawnHeight, "Path" );
	bestNode 	= undefined;
	
	if( IsDefined(nodeArray) && nodeArray.size > 0 )
	{
		ownerDir = AnglesToForward( owner.angles );
		
		// loop to find a node that is not in the player's current FOV
		foreach( node in nodeArray )
		{
			spawnPoint = node.origin + (0, 0, spawnHeight);
			if ( CapsuleTracePassed( spawnPoint, droneHalfSize, droneHalfSize*2 + 0.01, undefined, true, true ) )
			{
				if ( BulletTracePassed( owner GetEye(), spawnPoint, false, owner ) )
				{
					bestNode = spawnPoint;
					break;
				}
			}
		}
	}
	
	return bestNode;
}


//============================================
// 			isSafeToSpawnOn
//============================================
isSafeToSpawnOn( teamMember, pointToSpawnCheck, trace )
{
	if( teamMember IsSighted() )
	{
		maps\mp\gametypes\_spawnscoring::debugCombatCheck( self, "IsSighted-2" );
		return false;
	}
	
	// Check to see if the point can see any enemies
	foreach( player in level.players )
	{
		if( trace.currentTraceCount == trace.maxTraceCount )
		{
			maps\mp\gametypes\_spawnscoring::debugCombatCheck( self, "TooManyTraces" );
			return false;
		}
				
		if( player.team == self.team )
		{
			continue;
		}
		
		if( player.sessionstate != "playing" )
		{
			continue;
		}
		
		if( !isReallyAlive(player) )
		{
			continue;
		}
		
		if( player == self )
		{
			continue;
		}
		
		trace.currentTraceCount++;
		playerHeight 		= maps\mp\gametypes\_spawnlogic::getPlayerTraceHeight( player );
		spawnTraceLocation 	= player GetEye();
		spawnTraceLocation 	= ( spawnTraceLocation[0], spawnTraceLocation[1], player.origin[2] + playerHeight );
		
		sightValue = SpawnSightTrace( trace, pointToSpawnCheck + (0,0,playerHeight), spawnTraceLocation );
		
		if( sightValue > 0 )
		{
			maps\mp\gametypes\_spawnscoring::debugCombatCheck( self, "lineOfSight" );
			// line( pointToSpawnCheck + (0,0,playerHeight), spawnTraceLocation, (1, 0, 0), 1, false, 100 );
			return false;
		}
	}
	
	return true;	
}


//===========================================
// 			initScoreData
//===========================================
initScoreData( spawnPoint )
{
	spawnPoint.totalScore = 0;
	spawnPoint.numberOfPossibleSpawnChoices = 0;
	spawnPoint.buddySpawn = false;
	
	/#
	spawnPoint.debugScoreData = [];
	spawnPoint.debugCriticalData = [];
	spawnPoint.totalPossibleScore = 0;
	#/
}


//===========================================
// 			criticalFactors_NearTeam
//===========================================
criticalFactors_NearTeam( spawnPoint )
{
	// never spawn with an enemy having a direct line of sight 
	if( !critical_factor( ::avoidFullVisibleEnemies, spawnPoint ) )
	{
		return "bad";
	}
	
	// never spawn on top of a grenade
	if( !critical_factor( ::avoidGrenades, spawnPoint ) )
	{
		return "bad";
	}
	
	// never spawn on top of a mine/claymore
	if( !critical_factor( ::avoidMines, spawnPoint ) )
	{
		return "bad";
	}
	
	// never spawn on an airstrike location
	if( !critical_factor( ::avoidAirStrikeLocations, spawnPoint ) )
	{
		return "bad";
	}
	
	// never spawn on top of a care package
	if( !critical_factor( ::avoidCarePackages, spawnPoint ) )
	{
		return "bad";
	}
	
	// never spawn inside another player
	if( !critical_factor( ::avoidTelefrag, spawnPoint ) )
	{
		return "bad";
	}
	
	// never spawn at a point where an enemy just spawned
	if( !critical_factor( ::avoidEnemySpawn, spawnPoint ) )
	{
		return "bad";
	}
	
	if( IsDefined( spawnPoint.forcedTeam ) && spawnPoint.forcedteam != self.team )
	{
		return "bad";
	}
	
	// spawns sighted with the around the corner trace are secondary spawns
	if( !critical_factor( ::avoidCornerVisibleEnemies, spawnPoint ) )
	{
		return "secondary";
	}
	
	// spawns very close to an enemy
	if( !critical_factor( ::avoidCloseEnemies, spawnPoint ) )
	{
		return "secondary";
	}
	
	return "primary";
}


//===========================================
// 			scoreFactors_NearTeam
//===========================================
scoreFactors_NearTeam( spawnPoint )
{
	// perfer nearby teammates
	scoreFactor = score_factor( 1.25, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by enemies
	scoreFactor = score_factor( 1.0, ::avoidRecentlyUsedByEnemies, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid nearby enemies
	scoreFactor = score_factor( 1.0, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.5, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.5, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.25, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by anyone
	scoreFactor = score_factor( 0.25, ::avoidRecentlyUsedByAnyone, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 			criticalFactors_DZ
//===========================================
criticalFactors_DZ( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}

//===========================================
// 			getSpawnpoint_DZ
//===========================================
getSpawnpoint_DZ( spawnPoints, preferedPointArray )
{
	
	AssertEx( isDefined( preferedPointArray ), "no preferedPointArray was passed into getSpawnpoint_DZ" );
	
	spawnPoints = checkDynamicSpawns( spawnPoints );
	spawnChoices["primary"] 	= [];
	spawnChoices["secondary"] 	= [];
	spawnChoices["bad"] 		= [];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		result = criticalFactors_DZ( spawnPoint );
		
		spawnChoices[result][spawnChoices[result].size] = spawnPoint;
	}
	
	if( spawnChoices["primary"].size )
		return scoreSpawns_DZ( spawnChoices["primary"], preferedPointArray );
	
	if( spawnChoices["secondary"].size )
		return scoreSpawns_DZ( spawnChoices["secondary"], preferedPointArray );
	
	return selectBestSpawnPoint( spawnPoints[0], spawnPoints );
}


//===========================================
// 			getSpawnpoint_Domination
//===========================================
getSpawnpoint_Domination( spawnPoints, perferdDomPointArray )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	spawnChoices["primary"] 	= [];
	spawnChoices["secondary"] 	= [];
	spawnChoices["bad"] 		= [];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		result = criticalFactors_Domination( spawnPoint );
		
		spawnChoices[result][spawnChoices[result].size] = spawnPoint;
	}
	
	if( spawnChoices["primary"].size )
		return scoreSpawns_Domination( spawnChoices["primary"], perferdDomPointArray );
	
	if( spawnChoices["secondary"].size )
		return scoreSpawns_Domination( spawnChoices["secondary"], perferdDomPointArray );
	
	logBadSpawn( "Buddy Spawn" );
	return selectBestSpawnPoint( spawnPoints[0], spawnPoints );
}

//============================================
// 			scoreSpawns_DZ
//============================================
scoreSpawns_DZ( spawnPoints, preferdDomPointArray )
{
	bestSpawn = spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{	
		// calculates the total score of the spawn point
		scoreFactors_DZ( spawnPoint, preferdDomPointArray );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}



//============================================
// 			scoreSpawns_NearTeam
//============================================
scoreSpawns_Domination( spawnPoints, perferdDomPointArray )
{
	bestSpawn = spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{	
		// calculates the total score of the spawn point
		scoreFactors_Domination( spawnPoint, perferdDomPointArray );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}

//===========================================
// 		criticalFactors_Domination
//===========================================
criticalFactors_Domination( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_DZ
//===========================================
scoreFactors_DZ( spawnPoint, preferdPointArray )
{
	// prefer spawns near dom points
	scoreFactor = score_factor( 2.5, ::preferClosePoints, spawnPoint, preferdPointArray );
	spawnPoint.totalScore += scoreFactor;
	
	// perfer nearby teammates
	scoreFactor = score_factor( 1.0, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by enemies
	scoreFactor = score_factor( 1.0, ::avoidRecentlyUsedByEnemies, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid nearby enemies
	scoreFactor = score_factor( 1.0, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.25, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.25, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.25, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by anyone
	scoreFactor = score_factor( 0.25, ::avoidRecentlyUsedByAnyone, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}

//===========================================
// 		scoreFactors_Domination
//===========================================
scoreFactors_Domination( spawnPoint, perferdDomPointArray )
{
	// prefer spawns near dom points
	scoreFactor = score_factor( 2.5, ::preferDomPoints, spawnPoint, perferdDomPointArray );
	spawnPoint.totalScore += scoreFactor;
	
	// perfer nearby teammates
	scoreFactor = score_factor( 1.0, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by enemies
	scoreFactor = score_factor( 1.0, ::avoidRecentlyUsedByEnemies, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid nearby enemies
	scoreFactor = score_factor( 1.0, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.25, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.25, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.25, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by anyone
	scoreFactor = score_factor( 0.25, ::avoidRecentlyUsedByAnyone, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 			getStartSpawnpoint_FreeForAll
//===========================================
getStartSpawnpoint_FreeForAll( spawnPoints )
{
	if( !IsDefined( spawnPoints ) )
	{
		return undefined;
	}

	selectedSpawnPoint 	= undefined;
	activePlayerList 	= maps\mp\gametypes\_spawnlogic::getActivePlayerList();
	spawnPoints 		= checkDynamicSpawns( spawnPoints );
	
	if( !IsDefined( activePlayerList ) || activePlayerList.size == 0 )
		return maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	
	furthestDistSq = 0;
	foreach( spawnPoint in spawnPoints )
	{
		if( CanSpawn( spawnPoint.origin ) && !PositionWouldTelefrag( spawnPoint.origin ) )
		{
			// Find the closest enemy to this spawn point
			distToClosestEnemySq = undefined;
			foreach( player in activePlayerList )
			{
				distToEnemySq = DistanceSquared( spawnpoint.origin, player.origin );
				if( !IsDefined( distToClosestEnemySq ) || distToEnemySq < distToClosestEnemySq )
				{
					distToClosestEnemySq = distToEnemySq;
				}
			}
			
			// Select the spawn point that is furthest away from enemies.
			if( !IsDefined( selectedSpawnPoint ) || distToClosestEnemySq > furthestDistSq )
			{
				selectedSpawnPoint = spawnPoint;
				furthestDistSq = distToClosestEnemySq;
			}
		}
	}
	
	if( !IsDefined( selectedSpawnPoint ) )
		return maps\mp\gametypes\_spawnlogic::getSpawnpoint_Random( spawnPoints );
	
	return selectedSpawnPoint;
}


//===========================================
// 			getSpawnpoint_FreeForAll
//===========================================
getSpawnpoint_FreeForAll( spawnPoints )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	spawnChoices["primary"] 	= [];
	spawnChoices["secondary"] 	= [];
	spawnChoices["bad"] 		= [];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		result = criticalFactors_FreeForAll( spawnPoint );
		
		spawnChoices[result][spawnChoices[result].size] = spawnPoint;
	}
	
	if( spawnChoices["primary"].size )
		return scoreSpawns_FreeForAll( spawnChoices["primary"] );
	
	if( spawnChoices["secondary"].size )
		return scoreSpawns_FreeForAll( spawnChoices["secondary"] );
	
	if( GetDvarInt("scr_altFFASpawns") == 1 && spawnChoices["bad"].size )
	{
		logBadSpawn( "Bad FFA Spawn" );
		return scoreSpawns_FreeForAll( spawnChoices["bad"] );
	}
	
	logBadSpawn( "FFA Random Spawn" );
	return selectBestSpawnPoint( spawnPoints[0], spawnPoints );
}


//============================================
// 			scoreSpawns_FreeForAll
//============================================
scoreSpawns_FreeForAll( spawnPoints )
{
	bestSpawn = spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{	
		// calculates the total score of the spawn point
		scoreFactors_FreeForAll( spawnPoint );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}

//===========================================
// 		criticalFactors_FreeForAll
//===========================================
criticalFactors_FreeForAll( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_FreeForAll
//===========================================
scoreFactors_FreeForAll( spawnPoint )
{
	avoidAllEnemiesWeight = 3.0;
	// avoid closest enemy
	if( GetDvarInt("scr_altFFASpawns") == 1 )
	{
		scoreFactor = score_factor( 3.0, ::avoidClosestEnemy, spawnPoint );
		spawnPoint.totalScore += scoreFactor;
		avoidAllEnemiesWeight = 2.0;
	}
	
	// avoid all enemies
	scoreFactor = score_factor( avoidAllEnemiesWeight, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by enemies
	scoreFactor = score_factor( 2.0, ::avoidRecentlyUsedByEnemies, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.5, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.5, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.5, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 		getSpawnpoint_SearchAndRescue
//===========================================
getSpawnpoint_SearchAndRescue( spawnPoints )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	spawnChoices["primary"] 	= [];
	spawnChoices["secondary"] 	= [];
	spawnChoices["bad"] 		= [];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		result = criticalFactors_SearchAndRescue( spawnPoint );
		
		spawnChoices[result][spawnChoices[result].size] = spawnPoint;
	}
	
	if( spawnChoices["primary"].size )
		return scoreSpawns_SearchAndRescue( spawnChoices["primary"] );
	
	if( spawnChoices["secondary"].size )
		return scoreSpawns_SearchAndRescue( spawnChoices["secondary"] );
	
	logBadSpawn( "Buddy Spawn" );
	return selectBestSpawnPoint( spawnPoints[0], spawnPoints );
}


//============================================
// 			scoreSpawns_SearchAndRescue
//============================================
scoreSpawns_SearchAndRescue( spawnPoints )
{
	bestSpawn = spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{	
		// calculates the total score of the spawn point
		scoreFactors_SearchAndRescue( spawnPoint );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}


//===========================================
// 		criticalFactors_SearchAndRescue
//===========================================
criticalFactors_SearchAndRescue( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_SearchAndRescue
//===========================================
scoreFactors_SearchAndRescue( spawnPoint )
{	
	// avoid nearby enemies
	scoreFactor = score_factor( 3.0, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// perfer nearby teammates
	scoreFactor = score_factor( 1.0, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.5, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 0.5, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 		getSpawnpoint_awayFromEnemies
//===========================================
getSpawnpoint_awayFromEnemies( spawnPoints, team, disallowBuddySpawn )
{
	if( !IsDefined( disallowBuddySpawn ) )
		disallowBuddySpawn = false;
	
	spawnPoints = checkDynamicSpawns( spawnPoints );
	spawnChoices["primary"] 	= [];
	spawnChoices["secondary"] 	= [];
	spawnChoices["bad"] 		= [];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		result = criticalFactors_awayFromEnemies( spawnPoint );
		
		spawnChoices[result][spawnChoices[result].size] = spawnPoint;
	}
	
	if( spawnChoices["primary"].size )
		return scoreSpawns_awayFromEnemies( spawnChoices["primary"], team );
	
	if( spawnChoices["secondary"].size )
		return scoreSpawns_awayFromEnemies( spawnChoices["secondary"], team );
	
	if( disallowBuddySpawn )
	{
		return undefined;
	}
	else
	{
		logBadSpawn( "Buddy Spawn" );
		return selectBestSpawnPoint( spawnPoints[0], spawnPoints );
	}
}


//============================================
// 		scoreSpawns_awayFromEnemies
//============================================
scoreSpawns_awayFromEnemies( spawnPoints, team )
{
	bestSpawn = spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{	
		// calculates the total score of the spawn point
		scoreFactors_awayFromEnemies( spawnPoint, team );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}


//===========================================
// 		criticalFactors_awayFromEnemies
//===========================================
criticalFactors_awayFromEnemies( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_awayFromEnemies
//===========================================
scoreFactors_awayFromEnemies( spawnPoint, team )
{	
	// avoid nearby enemies
	scoreFactor = score_factor( 2.0, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last attacker
	scoreFactor = score_factor( 1.0, ::avoidLastAttackerLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// perfer nearby teammates
	scoreFactor = score_factor( 1.0, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by enemies
	scoreFactor = score_factor( 1.0, ::avoidRecentlyUsedByEnemies, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawning near your last death location
	scoreFactor = score_factor( 0.25, ::avoidLastDeathLocation, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid choosing the same spawn twice in a row
	scoreFactor = score_factor( 0.25, ::avoidSameSpawn, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid spawns recently used by anyone
	scoreFactor = score_factor( 0.25, ::avoidRecentlyUsedByAnyone, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 		 getSpawnpoint_Safeguard
//===========================================
getSpawnpoint_Safeguard( spawnPoints )
{
	spawnPoints = checkDynamicSpawns( spawnPoints );
	spawnChoices["primary"] 	= [];
	spawnChoices["secondary"] 	= [];
	spawnChoices["bad"] 		= [];
	
	foreach( spawnPoint in spawnPoints )
	{
		initScoreData( spawnPoint );

		result = criticalFactors_Safeguard( spawnPoint );
		
		spawnChoices[result][spawnChoices[result].size] = spawnPoint;
	}
	
	if( spawnChoices["primary"].size )
		return scoreSpawns_Safeguard( spawnChoices["primary"] );
	
	if( spawnChoices["secondary"].size )
		return scoreSpawns_Safeguard( spawnChoices["secondary"] );
	
	logBadSpawn( "Buddy Spawn" );
	return selectBestSpawnPoint( spawnPoints[0], spawnPoints );
}


//============================================
// 			scoreSpawns_Safeguard
//============================================
scoreSpawns_Safeguard( spawnPoints )
{
	bestSpawn = spawnPoints[0];
	
	foreach( spawnPoint in spawnPoints )
	{	
		// calculates the total score of the spawn point
		scoreFactors_Safeguard( spawnPoint );
		
		// select the spawn point with the largest score
		if( spawnPoint.totalScore > bestSpawn.totalScore )
		{
			bestSpawn = spawnPoint;
		}
	}
	
	bestSpawn = selectBestSpawnPoint( bestSpawn, spawnPoints );
	
	return bestSpawn;
}

//===========================================
// 		criticalFactors_Safeguard
//===========================================
criticalFactors_Safeguard( spawnPoint )
{
	return criticalFactors_NearTeam( spawnPoint );
}


//===========================================
// 		scoreFactors_Safeguard
//===========================================
scoreFactors_Safeguard( spawnPoint )
{	
	// random score
	scoreFactor = score_factor( 1.0, ::randomSpawnScore, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// perfer nearby teammates
	scoreFactor = score_factor( 1.0, ::preferAlliesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
	
	// avoid nearby enemies
	scoreFactor = score_factor( 0.5, ::avoidEnemiesByDistance, spawnPoint );
	spawnPoint.totalScore += scoreFactor;
}


//===========================================
// 		logBadSpawn
//===========================================
logBadSpawn( typeString )
{
	if( !IsDefined( typeString ) )
		typeString = "";
	else
		typeString = "(" + typeString + ")";
	println( "^1 Spawn Error: Bad spawn used. " + typeString + "\n" );
	
	if( IsDefined( level.matchRecording_logEventMsg ) )
	{
		[[level.matchRecording_logEventMsg]]( "LOG_BAD_SPAWN", GetTime(), typeString );
	}
}

