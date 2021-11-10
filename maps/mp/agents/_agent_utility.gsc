#include common_scripts\utility;
#include maps\mp\_utility;

//========================================================
//				agentFunc 
//========================================================
agentFunc( func_name )
{
	assert( IsAgent( self ) );
	assert( IsDefined(func_name) );
	assert( isDefined(self.agent_type) );
	assert( isDefined(level.agent_funcs[self.agent_type]) );
	assert( isDefined(level.agent_funcs[self.agent_type][func_name]) );
	
	return level.agent_funcs[self.agent_type][func_name];
}

//========================================================
//				set_agent_team 
//========================================================
set_agent_team( team, optional_owner )
{
	// since an agent entity has both a "sentient" and an "agent", we need both
	// these to understand the team the entity is on (much as client entities
	// have a "sentient" and a "client"). The "team" field sets the "sentient"
	// team and the "agentteam" field sets the "agent" team. 
	self.team 			= team;
	self.agentteam 		= team;
	self.pers["team"] 	= team;
	
	self.owner = optional_owner;
	self SetOtherEnt( optional_owner );
	self SetEntityOwner( optional_owner );
}


//=======================================================
//				initAgentScriptVariables
//=======================================================
initAgentScriptVariables()
{
	self.agent_type 			= "player"; // TODO: communicate this to code?
	self.pers 					= [];
	self.hasDied 				= false;
	self.isActive				= false;
	self.isAgent				= true;
	self.wasTI					= false;
	self.isSniper				= false;
	self.spawnTime				= 0;
	self.entity_number 			= self GetEntityNumber();	
	self.agent_teamParticipant 	= false;
	self.agent_gameParticipant 	= false;
	self.canPerformClientTraces = false;
	self.agentname 				= undefined;
	
	self DetachAll();

	self initPlayerScriptVariables( false );
}


//========================================================
//					initPlayerScriptVariables
//========================================================
initPlayerScriptVariables( asPlayer )
{
	if ( !asPlayer )
	{
		// Not as a player
		self.class							= undefined;
		self.lastClass						= undefined;
		self.moveSpeedScaler 				= undefined;
		self.avoidKillstreakOnSpawnTimer 	= undefined;
		self.guid 							= undefined;
		self.name							= undefined;
		self.saved_actionSlotData 			= undefined;		
		self.perks 							= undefined;
		self.weaponList 					= undefined;
		self.omaClassChanged 				= undefined;
		self.objectiveScaler 				= undefined;
		self.touchTriggers 					= undefined;
		self.carryObject 					= undefined;
		self.claimTrigger 					= undefined;
		self.canPickupObject 				= undefined;
		self.killedInUse 					= undefined;
		self.sessionteam					= undefined;
		self.sessionstate					= undefined;
		self.lastSpawnTime 					= undefined;
		self.lastspawnpoint 				= undefined;
		self.disabledWeapon					= undefined;
		self.disabledWeaponSwitch			= undefined;
		self.disabledOffhandWeapons			= undefined;
		self.disabledUsability				= undefined;
		self.shieldDamage 					= undefined;
		self.shieldBulletHits				= undefined;
		self.recentShieldXP					= undefined;
	}
	else
	{
		// As a player
		self.moveSpeedScaler 				= 1;
		self.avoidKillstreakOnSpawnTimer 	= 5;
		self.guid 							= self getUniqueId();
		self.name							= self.guid;
		self.sessionteam 					= self.team;
		self.sessionstate					= "playing";
		self.shieldDamage 					= 0;
		self.shieldBulletHits				= 0;
		self.recentShieldXP					= 0;
		self.agent_gameParticipant			= true;		// If initialized as a player, always make agent a game participant
		
		self maps\mp\gametypes\_playerlogic::setupSavedActionSlots();
		self thread maps\mp\perks\_perks::onPlayerSpawned();
		
		if ( IsGameParticipant( self ) )
		{
			self.objectiveScaler = 1;
			self maps\mp\gametypes\_gameobjects::init_player_gameobjects();
			self.disabledWeapon = 0;
			self.disabledWeaponSwitch = 0;
			self.disabledOffhandWeapons = 0;
		}
	}
	
	self.disabledUsability 		= 1;
}

//===========================================
// 				getFreeAgent
//===========================================
getFreeAgent( agent_type )
{
	freeAgent = undefined;
	
	if( IsDefined( level.agentArray ) )
	{
		foreach( agent in level.agentArray )
		{
			if( !IsDefined( agent.isActive ) || !agent.isActive )
			{
				if ( IsDefined(agent.waitingToDeactivate) && agent.waitingToDeactivate )
					continue;
				
				freeAgent = agent;
				
				freeAgent initAgentScriptVariables();
				
				if ( IsDefined( agent_type ) ) 
					freeAgent.agent_type = agent_type; // TODO: communicate this to code?
					
				break;
			}
		}
	}
	
	return freeAgent;
}


//=======================================================
//				activateAgent
//=======================================================
activateAgent()
{
/#
	if ( !self.isActive )
	{
		// Activating this agent, ensure that he has connected on the same frame
		AssertEx(self.connectTime == GetTime(), "Agent spawn took too long - there should be no waits in between connectNewAgent and spawning the agent");
	}
#/
	self.isActive = true;
}



//=======================================================
//				deactivateAgent
//=======================================================
deactivateAgent()
{
	self thread deactivateAgentDelayed();
}

//=======================================================
//				deactivateAgentDelayed
//=======================================================
deactivateAgentDelayed()
{
	self notify("deactivateAgentDelayed");
	self endon("deactivateAgentDelayed");
	
	// During the 0.05s wait in deactivateAgentDelayed, the agent's script variables are all cleared out
	// So we need to do this now while IsGameParticipant can still be checked
	if ( IsGameParticipant(self) )
		self maps\mp\gametypes\_spawnlogic::removeFromParticipantsArray();
	
	self maps\mp\gametypes\_spawnlogic::removeFromCharactersArray();
	
	// Wait till next frame before we "disconnect"
	// That way things waiting on "death" but have endon("disconnect") will still function
	// e.g. maps\mp\killstreaks\_juggernaut::juggRemover()
	wait 0.05;

	self.isActive 	= false;
	self.hasDied 	= false;
	self.owner		= undefined;
	self.connectTime = undefined;
	self.waitingToDeactivate = undefined;
	
	// Clear this agent from any other character's attackers array	
	foreach ( character in level.characters )
	{
		if ( IsDefined( character.attackers ) )
		{
			foreach ( index, attacker in character.attackers )
			{
				if ( attacker == self )
					character.attackers[index] = undefined;
			}
		}
	}

	if ( IsDefined( self.headModel ) )
	{
		self Detach( self.headModel );
		self.headModel = undefined;
	}
	
	self notify("disconnect");
}


//===========================================
// 			getNumActiveAgents
//===========================================
getNumActiveAgents( type )
{
	if ( !IsDefined(type) )
		type = "all";
	
	agents = getActiveAgentsOfType(type);
	return agents.size;
}


//===========================================
// 			getActiveAgentsOfType
//===========================================
getActiveAgentsOfType( type )
{
	Assert(IsDefined(type));
	agents = [];
	
	if ( !IsDefined( level.agentArray ) )
		return agents;
		
	foreach ( agent in level.agentArray )
	{
		if ( IsDefined( agent.isActive ) && agent.isActive )
		{
			if ( type == "all" || agent.agent_type == type )
				agents[agents.size] = agent;
		}
	}
	
	return agents;
}


//===========================================
// 			getNumOwnedActiveAgents
//===========================================
getNumOwnedActiveAgents( player )
{
	return getNumOwnedActiveAgentsByType( player, "all" );
}

//===========================================
// 			getNumOwnedActiveAgentsByType
//===========================================
getNumOwnedActiveAgentsByType( player, type )
{
	Assert(IsDefined(type));
	numOwnedActiveAgents = 0;

	if( !IsDefined(level.agentArray) )
	{
		return numOwnedActiveAgents;
	}

	foreach( agent in level.agentArray )
	{
		if( IsDefined( agent.isActive ) && agent.isActive )
		{
			if ( IsDefined(agent.owner) && (agent.owner == player) )
			{
				// Adding exclusion for "alien" type from a request for "all" to prevent the Seeker killstreak in mp_dome_ns from overloading the max allowable agents per player.
				if ( ( type == "all" && agent.agent_type != "alien" ) || agent.agent_type == type )
					numOwnedActiveAgents++;
			}
		}
	}

	return numOwnedActiveAgents;
}

//=======================================================
//				getValidSpawnPathNodeNearPlayer
//=======================================================
getValidSpawnPathNodeNearPlayer( bDoPhysicsTraceToPlayer, bDoPhysicsTraceToValidateNode ) // self = player
{
	assert( isPlayer( self ) );
	
	nodeArray 	= GetNodesInRadius( self.origin, 350, 64, 128, "Path" );
	
	if( !IsDefined(nodeArray) || (nodeArray.size == 0) )
	{
		return undefined;
	}
	
	if ( IsDefined(level.waterDeleteZ) && IsDefined(level.trigUnderWater) )
	{
		// Ignore any nodes where the agent would die immediately upon spawning	
		nodeArrayOld = nodeArray;
		nodeArray = [];
		foreach( node in nodeArrayOld )
		{
			if ( node.origin[ 2 ] > level.waterDeleteZ || !IsPointInVolume( node.origin, level.trigUnderWater ) )
				nodeArray[nodeArray.size] = node;
		}
	}
	
	playerDirection = AnglesToForward( self.angles );
	bestDot = -10;
	
	playerHeight = maps\mp\gametypes\_spawnlogic::getPlayerTraceHeight( self );
	zOffset = ( 0, 0, playerHeight );
	
	if ( !IsDefined(bDoPhysicsTraceToPlayer) )
		bDoPhysicsTraceToPlayer = false;
	
	if ( !IsDefined(bDoPhysicsTraceToValidateNode) )
		bDoPhysicsTraceToValidateNode = false;
	
	pathNodeSortedByDot = [];
	pathNodeDotValues = [];
	foreach( pathNode in nodeArray )
	{
		if ( !pathNode DoesNodeAllowStance("stand") || isDefined ( pathnode.no_agent_spawn) )
			continue;
		
		
		directionToNode = VectorNormalize( pathNode.origin - self.origin );
		dot = VectorDot( playerDirection, directionToNode );
		
		i = 0;
		for ( ; i < pathNodeDotValues.size; i++ )
		{
			if ( dot > pathNodeDotValues[i] )
			{
				for ( j = pathNodeDotValues.size; j > i; j-- )
				{
					pathNodeDotValues[j] = pathNodeDotValues[j-1];
					pathNodeSortedByDot[j] = pathNodeSortedByDot[j-1];
				}
				break;
			}
		}
		pathNodeSortedByDot[i] = pathNode;
		pathNodeDotValues[i] = dot;
	}
	
	// pick a path node in the player's view
	for ( i = 0; i < pathNodeSortedByDot.size; i++ )
	{
		pathNode = pathNodeSortedByDot[i];
		
		traceStart = self.origin + zOffset;
		traceEnd = pathNode.origin + zOffset;
		
		if ( i > 0 )
			wait(0.05);	// Spread out the traces across multiple frames
		
		// prevent selecting a node that the player cannot see
		if( !SightTracePassed( traceStart, traceEnd, false, self ) )
		{
			continue;
		}
		
		if ( bDoPhysicsTraceToValidateNode )
		{
			if ( i > 0 )
				wait(0.05);	// Spread out the traces across multiple frames
			
			hitPos = PlayerPhysicsTrace( pathNode.origin + zOffset, pathNode.origin );
			if ( DistanceSquared( hitPos, pathNode.origin ) > 1 )
				continue;
		}

		if ( bDoPhysicsTraceToPlayer )
		{
			if ( i > 0 )
				wait(0.05);	// Spread out the traces across multiple frames
			
			hitPos = PhysicsTrace( traceStart, traceEnd );
			if ( DistanceSquared( hitPos, traceEnd ) > 1 )
				continue;
		}
		
		return pathNode;
	}
	
	// always return a node for safeguard
	if( (pathNodeSortedByDot.size > 0) && IsDefined(level.isHorde) )
		return pathNodeSortedByDot[0];
}


//=======================================================
//					killAgent
//=======================================================
killAgent( agent ) 
{
	// do enough damage to kill the agent regardless of any damage mitigation  
 	agent DoDamage( agent.health + 500000, agent.origin );
}


//=======================================================
//					killDog
//=======================================================
killDog() // self == dog
{
	self [[ self agentFunc( "on_damaged" ) ]](
		level, // eInflictor The entity that causes the damage.(e.g. a turret)
		undefined, // eAttacker The entity that is attacking.
		self.health + 1, // iDamage Integer specifying the amount of damage done
		0, // iDFlags Integer specifying flags that are to be applied to the damage
		"MOD_CRUSH", // sMeansOfDeath Integer specifying the method of death
		"none", // sWeapon The weapon number of the weapon used to inflict the damage
		( 0, 0, 0 ), // vPoint The point the damage is from?
		(0, 0, 0), // vDir The direction of the damage
		"none", // sHitLoc The location of the hit
		0 // psOffsetTime The time offset for the damage
	);
}