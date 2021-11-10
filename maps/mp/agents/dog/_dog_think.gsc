#include common_scripts\utility;
#include maps\mp\agents\_scriptedAgents;
#include maps\mp\agents\_agent_utility;

main()
{
	self setupDogState();

	self thread think();
	self thread watchOwnerDamage();
	self thread watchOwnerDeath();
	self thread watchOwnerTeamChange();
	self thread WaitForBadPath();
	self thread WaitForPathSet();

/#
	self thread debug_dog();
#/
}

setupDogState()
{
	self.bLockGoalPos 				= false;
	self.ownerRadiusSq				= 144 * 144;
	self.meleeRadiusSq				= 128 * 128;
	self.attackOffset				= 25 + self.radius;
	self.attackRadiusSq				= 450 * 450;
	self.warningRadiusSq			= 550 * 550;
	self.warningZHeight				= 128 * 0.75;	//min floor to ceiling in a map is 128 units
	self.attackZHeight				= 54;			//how high we'll allow the dog to jump to attack his target.
	self.attackZHeightDown			= -64;			//how low we'll allow the dog to jump to attack his target.
	self.ownerDamagedRadiusSq		= 1500 * 1500;	//if the owner takes damage and the attacker is within this radius
	self.dogDamagedRadiusSq			= 1500 * 1500;	//if the dog takes damage and the attacker is within this radius
	self.keepPursuingTargetRadiusSq = 1000 * 1000;	//stop pursuing the target after the target gets this far away from my owner, unless he's my favorite enemy.
	self.preferredOffsetFromOwner	= 76;
	self.minOffsetFromOwner			= 50;			//need to keep this above owner.radius + self.radius.
	self.forceAttack				= false;		//if we want to send after a target
	self.ignoreCloseFoliage 		= true;
	self.moveMode 					= "run";
	self.enableExtendedKill			= true;
	self.attackState 				= "idle";		// self.aiState comes from code, so we need something to tell us what attack state we're in
	self.moveState 					= "idle";
	self.bHasBadPath				= false;
	self.timeOfLastDamage			= 0;

	self.allowCrouch				= true;

	self ScrAgentSetGoalRadius(24);		// dog will get real twitchy about stopping if this falls below 16.
}

init()
{
	self.animCBs = SpawnStruct();
	self.animCBs.OnEnter = [];
	self.animCBs.OnEnter[ "idle" ] = maps\mp\agents\dog\_dog_idle::main;
	self.animCBs.OnEnter[ "move" ] = maps\mp\agents\dog\_dog_move::main;
	self.animCBs.OnEnter[ "traverse" ] = maps\mp\agents\dog\_dog_traverse::main;
	self.animCBs.OnEnter[ "melee" ] = maps\mp\agents\dog\_dog_melee::main;

	self.animCBs.OnExit = [];
	self.animCBs.OnExit[ "idle" ] = maps\mp\agents\dog\_dog_idle::end_script;
	self.animCBs.OnExit[ "move" ] = maps\mp\agents\dog\_dog_move::end_script;
	self.animCBs.OnExit[ "melee" ] = maps\mp\agents\dog\_dog_melee::end_script;
	self.animCBs.OnExit[ "traverse" ] = maps\mp\agents\dog\_dog_traverse::end_script;
	
	self.watchAttackStateFunc = ::watchAttackState;

	self.aiState = "idle";
	self.moveMode = "fastwalk";

	self.radius = 15;
	self.height = 40;
}

onEnterAnimState( prevState, nextState )
{
	self notify( "killanimscript" );

	if ( !IsDefined( self.animCBs.OnEnter[ nextState ] ) )
		return;

	if ( prevState == nextState && ( nextState != "traverse" ) )
		return;

	if ( IsDefined( self.animCBs.OnExit[ prevState ] ) )
		self [[ self.animCBs.OnExit[ prevState ] ]] ();

	ExitAIState( self.aiState );

	self.aiState = nextState;

	EnterAIState( nextState );

	self [[ self.animCBs.OnEnter[ nextState ] ]]();
}

think()
{
	self endon( "death" );
	level endon( "game_ended" );

	if ( IsDefined( self.owner ) )
	{
		self endon( "owner_disconnect" );
		self thread destroyOnOwnerDisconnect( self.owner );
	}

	self thread [[self.watchAttackStateFunc]]();
	self thread MonitorFlash();

	while ( true )
	{
		/#
		if ( self ProcessDebugMode() )
			continue;
		#/

		if ( self.aiState != "melee" && !self.stateLocked && self readyToMeleeTarget() && !self DidPastMeleeFail() )
			self ScrAgentBeginMelee( self.curMeleeTarget );

		switch ( self.aiState )
		{
		case "idle":
			self updateIdle();
			break;
		case "move":
			self updateMove();
			break;
		case "melee":
			self updateMelee();
			break;
		}
		wait( 0.05 );
	}
}

DidPastPursuitFail( enemy )
{
	assert( IsDefined( enemy ) );

	if ( IsDefined( self.curMeleeTarget ) && enemy != self.curMeleeTarget )
		return false;

	if ( !IsDefined( self.lastPursuitFailedPos ) || !IsDefined( self.lastPursuitFailedMyPos ) )
		return false;

	if ( Distance2DSquared( enemy.origin, self.lastPursuitFailedPos ) > 4 )
		return false;
		
	if ( self.bLastPursuitFailedPosBad )
		return true;

	if ( DistanceSquared( self.origin, self.lastPursuitFailedMyPos ) > 64 * 64 && GetTime() - self.lastPursuitFailedTime > 2000 )
		return false;

	return true;
}

DidPastMeleeFail()
{
	assert( IsDefined( self.curMeleeTarget ) );

	if ( IsDefined( self.lastMeleeFailedPos ) && IsDefined( self.lastMeleeFailedMyPos )
		&& Distance2DSquared( self.curMeleeTarget.origin, self.lastMeleeFailedPos ) < 4 
		&& DistanceSquared( self.origin, self.lastMeleeFailedMyPos ) < 50 * 50 )
		return true;

	if ( self WantToAttackTargetButCant( false ) )
		return true;

	return false;
}

enterAIState( state )
{
	self ExitAIState( self.aiState );
	self.aiState = state;

	switch ( state )
	{
	case "idle":
		self.moveState = "idle";
		self.bHasBadPath = false;
		break;
	case "move":
		self.moveState = "follow";
		break;
	case "melee":
		break;
	default:
		break;
	}
}

ExitAIState( state )
{
	switch ( state )
	{
	case "move":
		self.ownerPrevPos = undefined;
		break;
	default:
		break;
	}
}


updateIdle()
{
	self UpdateMoveState();
}

updateMove()
{
	self UpdateMoveState();
}

updateMelee()
{
	self ScrAgentSetGoalPos( self.origin );
}

UpdateMoveState()
{
	if ( self.bLockGoalPos )
		return;

	self.prevMoveState = self.moveState;

	attackPoint = undefined;
	bRefreshGoal = false;
	bWantedPursuitButFollowInstead = false;

	cBadPathTimeOut = 500;
	if ( self.bHasBadPath && GetTime() - self.lastBadPathTime < cBadPathTimeOut )
	{
		self.moveState = "follow";
		bRefreshGoal = true;
	}
	else
	{
		self.moveState = self GetMoveState();
	}

	if ( self.moveState == "pursuit" )
	{
		attackPoint = self GetAttackPoint( self.enemy );
		bLastBadMeleeTarget = false;
		if ( IsDefined( self.lastBadPathTime ) && ( GetTime() - self.lastBadPathTime < 3000 ) )
		{
			if ( Distance2DSquared( attackPoint, self.lastBadPathGoal ) < 16 )
				bLastBadMeleeTarget = true;
			else if ( IsDefined( self.lastBadPathMoveState ) && self.lastBadPathMoveState == "pursuit" && Distance2DSquared( self.lastBadPathUltimateGoal, self.enemy.origin ) < 16 )
				bLastBadMeleeTarget = true;
		}
		if ( bLastBadMeleeTarget )
		{
			self.moveState = "follow";
			bWantedPursuitButFollowInstead = true;
		}
		else if ( self wantToAttackTargetButCant( true ) )
		{
			self.moveState = "follow";
			bWantedPursuitButFollowInstead = true;
		}
		else if ( self DidPastPursuitFail( self.enemy ) )
		{
			self.moveState = "follow";
			bWantedPursuitButFollowInstead = true;
		}
	}

	self SetPastPursuitFailed( bWantedPursuitButFollowInstead );

	if ( self.moveState == "follow" )
	{
		self.curMeleeTarget = undefined;
		self.moveMode = self GetFollowMoveMode( self.moveMode );
		self.bArrivalsEnabled = true;

		myPos = self GetPathGoalPos();
		if ( !IsDefined( myPos ) )
			myPos = self.origin;

		// make sure the owner isn't in free spectator leading the dog around, even if that is fun
		if ( self.owner.sessionstate == "spectator" )
			return;

		if ( GetTime() - self.timeOfLastDamage < 5000 )
			bRefreshGoal = true;
		
		// also take into account the owner's stance changes
		currStance = self.owner GetStance();
		if ( !IsDefined( self.owner.prevStance ) && IsDefined( self.owner ) )
			self.owner.prevStance = currStance;

		bOwnerHasMoved = !IsDefined( self.ownerPrevPos ) || Distance2DSquared( self.ownerPrevPos, self.owner.origin ) > 100;
		if ( bOwnerHasMoved )
			self.ownerPrevPos = self.owner.origin;

		distFromOwnerSq = Distance2DSquared( myPos, self.owner.origin );
		if ( bRefreshGoal || ( distFromOwnerSq > self.ownerRadiusSq && bOwnerHasMoved ) || self.owner.prevStance != currStance || (self.prevMoveState != "idle" && self.prevMoveState != self.moveState) )
		{
			self ScrAgentSetGoalPos( self findPointNearOwner() );
			self.owner.prevStance = currStance;
		}
	}
	else if ( self.moveState == "pursuit" )
	{
		self.curMeleeTarget = self.enemy;
		self.moveMode = "sprint";
		self.bArrivalsEnabled = false;

		assert( IsDefined( attackPoint ) );
		self ScrAgentSetGoalPos( attackPoint );
	}
}


GetMoveState( prevState )
{
	if ( IsDefined( self.enemy ) )
	{
		if ( IsDefined( self.favoriteEnemy ) && self.enemy == self.favoriteEnemy )
			return "pursuit";

		if ( abs( self.origin[2] - self.enemy.origin[2] ) < self.warningZHeight && Distance2DSquared( self.enemy.origin, self.origin ) < self.attackRadiusSq )
			return "pursuit";

		if ( IsDefined( self.curMeleeTarget ) && self.curMeleeTarget == self.enemy )
		{
			if ( Distance2DSquared( self.curMeleeTarget.origin, self.origin ) < self.keepPursuingTargetRadiusSq )
				return "pursuit";
		}
	}

	return "follow";
}


SetPastPursuitFailed( bWantedPursuitButFollowInstead )
{
	if ( bWantedPursuitButFollowInstead )
	{
		if ( !IsDefined( self.lastPursuitFailedPos ) )
		{
			self.lastPursuitFailedPos = self.enemy.origin;
			self.lastPursuitFailedMyPos = self.origin;
			groundPos = self DropPosToGround( self.enemy.origin );
			self.bLastPursuitFailedPosBad = !IsDefined( groundPos );
			self.lastPursuitFailedTime = GetTime();
		}
	}
	else
	{
		self.lastPursuitFailedPos = undefined;
		self.lastPursuitFailedMyPos = undefined;
		self.bLastPursuitFailedPosBad = undefined;
		self.lastPursuitFailedTime = undefined;
	}

}


WaitForBadPath()
{
	self endon( "death" );
	level endon( "game_ended" );

	while ( true )
	{
		self waittill( "bad_path", badGoalPos );
		self.bHasBadPath = true;
		self.lastBadPathTime = GetTime();
		self.lastBadPathGoal = badGoalPos;
		self.lastBadPathMoveState = self.moveState;
		if ( self.moveState == "follow" && IsDefined( self.owner ) )
			self.lastBadPathUltimateGoal = self.owner.origin;
		else if ( self.moveState == "pursuit" && IsDefined( self.enemy ) )
			self.lastBadPathUltimateGoal = self.enemy.origin;
	}
}

WaitForPathSet()
{
	self endon( "death" );
	level endon( "game_ended" );

	while ( true )
	{
		self waittill( "path_set" );
		self.bHasBadPath = false;
	}
}

GetFollowMoveMode( currentMoveMode )
{
	cRunToFastWalkDistSq = 200 * 200;
	cFastWalkToRunDistSq = 256 * 256;

	pathGoalPos = self GetPathGoalPos();
	if ( IsDefined( pathGoalPos ) )
	{
		distSq = DistanceSquared( pathGoalPos, self.origin );
		if ( currentMoveMode == "run" || currentMoveMode == "sprint" )
		{
			if ( distSq < cRunToFastWalkDistSq )
				return "fastwalk";
			else if ( currentMoveMode == "sprint" )
				return "run";
		}
		else if ( currentMoveMode == "fastwalk" )
		{
			if ( distSq > cFastWalkToRunDistSq )
				return "run";
		}
	}

	return currentMoveMode;
}


IsWithinAttackHeight( targetPos )
{
	zDiff = targetPos[2] - self.origin[2];

	return zDiff <= self.attackZHeight && zDiff >= self.attackZHeightDown;
}


WantToAttackTargetButCant( bCheckSight )
{
	if ( !IsDefined( self.curMeleeTarget ) )
		return false;

	return !self IsWithinAttackHeight( self.curMeleeTarget.origin )
		&& Distance2DSquared( self.origin, self.curMeleeTarget.origin ) < self.meleeRadiusSq * 0.75 * 0.75
		&& ( !bCheckSight || self AgentCanSeeSentient( self.curMeleeTarget ) );
}

readyToMeleeTarget()
{
	if ( !IsDefined( self.curMeleeTarget ) )
		return false;

	if ( !maps\mp\_utility::IsReallyAlive( self.curMeleeTarget ) )
		return false;

	if ( self.aiState == "traverse" )
		return false;

	if ( Distance2DSquared( self.origin, self.curMeleeTarget.origin ) > self.meleeRadiusSq )
		return false;

	if ( !self IsWithinAttackHeight( self.curMeleeTarget.origin ) )
		return false;

	return true;
}

//wantsToContinueRunningToTarget()
//{
//	if ( !IsDefined( self.curMeleeTarget ) || !IsDefined( self.enemy ) )
//		return false;
//
//	if ( self.curMeleeTarget != self.enemy )
//		return false;
//
//	if ( DistanceSquared( self.origin, self.curMeleeTarget.origin ) > self.warningRadiusSq )
//		return false;
//
//	if ( IsDefined( self.owner ) )
//	{
//		if ( !IsDefined( self.favoriteEnemy ) || self.curMeleeTarget != self.favoriteEnemy )
//		{
//			if ( DistanceSquared( self.owner.origin, self.curMeleeTarget.origin ) > self.keepPursuingTargetRadiusSq )
//				return false;
//		}
//	}
//
//	return true;
//}

//wantsToAttackTarget()
//{
//	if ( !IsDefined( self.enemy ) )
//		return false;
//
//	if( self.forceAttack )
//		return true;
//
//	// first make sure the enemy is within the same height as the dog
//	if( abs( self.origin[ 2 ] - self.enemy.origin[ 2 ] ) > self.warningZHeight )
//		return false;
//
//	if ( DistanceSquared( self.origin, self.enemy.origin ) > self.attackRadiusSq )
//		return false;
//
//	if ( IsDefined( self.owner ) )
//	{
//		if ( !IsDefined( self.favoriteEnemy ) || self.enemy != self.favoriteEnemy )
//		{
//			if ( DistanceSquared( self.owner.origin, self.enemy.origin ) > self.keepPursuingTargetRadiusSq )
//				return false;
//		}
//	}
//
//	return true;
//}

wantsToGrowlAtTarget()
{
	if ( !IsDefined( self.enemy ) )
		return false;

	// first make sure the enemy is within the same height as the dog, or i can see him (which means he's not on a different 'floor')
	if( abs( self.origin[ 2 ] - self.enemy.origin[ 2 ] ) <= self.warningZHeight || self AgentCanSeeSentient( self.enemy ) )
	{
		// now see if the enemy is within the warning radius
		distSq = Distance2DSquared( self.origin, self.enemy.origin );
		if ( distSq < self.warningRadiusSq )
			return true;
	}

	return false;
}

getAttackPoint( enemy )
{
	meToTarget = enemy.origin - self.origin;
	meToTarget = VectorNormalize( meToTarget );

	pathGoalPos = self GetPathGoalPos();
	closeEnough = self.attackOffset + 4;
	if ( IsDefined( pathGoalPos ) && Distance2DSquared( pathGoalPos, enemy.origin ) < closeEnough * closeEnough && self CanMovePointToPoint( enemy.origin, pathGoalPos ) )
		return pathGoalPos;

	attackPoint = enemy.origin - meToTarget * self.attackOffset;
	attackPoint = self DropPosToGround( attackPoint );

	if ( !IsDefined( attackPoint ) )
		return enemy.origin;

	if ( !self CanMovePointToPoint( enemy.origin, attackPoint ) )
	{
		enemyFacing = AnglesToForward( enemy.angles );
		attackPoint = enemy.origin + enemyFacing * self.attackOffset;

		if ( !self CanMovePointToPoint( enemy.origin, attackPoint ) )
			return enemy.origin;
	}

	return attackPoint;
}

// > 0 right
cross2D( a, b )
{
	return a[0] * b[1] - b[0] * a[1];
}

// finds a valid point near the owner with two traces (nearest node and ground trace) by finding
// a point on the pathgraph somewhere.  nodes and points on node links are pre-determined to be valid.
// except i might get in trouble if the player's closest node is a negotation begin node...
findPointNearOwner()
{
	assert( IsDefined( self.owner ) );

	ownerToMe = VectorNormalize( self.origin - self.owner.origin );
	ownerForward = AnglesToForward( self.owner.angles );
	ownerForward = ( ownerForward[0], ownerForward[1], 0 );
	ownerForward = VectorNormalize( ownerForward );
	currentDirFromOwner = cross2D( ownerToMe, ownerForward );

	nodeClosestToOwner = GetClosestNodeInSight( self.owner.origin );
	if ( !IsDefined( nodeClosestToOwner ) )
		return self.origin;

	links = GetLinkedNodes( nodeClosestToOwner );

	distanceWeight = 5;
	angleWeight = 10;
	sideWeight = 15;
	avoidWeight = -15;

	bDoAvoid = ( GetTime() - self.timeOfLastDamage ) < 5000;

	// prefer nodes to side which i'm already on (and slightly ahead).  else behind owner.  else in front of.
	bestScore = 0;
	bestLink = undefined;

	links[ links.size ] = nodeClosestToOwner;
	foreach ( link in links )
	{
		score = 0;

		ownerToLink = link.origin - self.owner.origin;
		ownerToLinkDist = Length( ownerToLink );
		if ( ownerToLinkDist >= self.preferredOffsetFromOwner )
			score += distanceWeight;
		else if ( ownerToLinkDist < self.minOffsetFromOwner )
		{
			scale = 1 - ( self.minOffsetFromOwner - ownerToLinkDist ) / self.minOffsetFromOwner;
			score += distanceWeight * scale * scale;
		}
		else
			score += distanceWeight * ownerToLinkDist / self.preferredOffsetFromOwner;

		if(ownerToLinkDist==0)
			ownerToLinkDist = 1;
		
		ownerToLink = ownerToLink / ownerToLinkDist;
		angleCos = VectorDot( ownerForward, ownerToLink );
		
		// situate the dog in position depending on the owner's stance
		//	standing == ahead
		//	crouching == next to
		//	prone == behind
		currStance = self.owner GetStance();
		switch ( currStance )
		{
		case "stand":
			if( angleCos < cos( 35 ) && angleCos > cos( 45 ) )
				score += angleWeight;
			break;
		case "crouch":
			if( angleCos < cos( 75 ) && angleCos > cos( 90 ) )
				score += angleWeight;
			break;
		case "prone":
			if( angleCos < cos( 125 ) && angleCos > cos( 135 ) )
				score += angleWeight;
			break;
		}
		
		dirFromOwner = cross2D( ownerToLink, ownerForward );
		if ( dirFromOwner * currentDirFromOwner > 0 )		// i.e. both the same sign
			score += sideWeight;

		if ( bDoAvoid )
		{
			assert( IsDefined( self.damagedOwnerToMe ) );
			avoid = VectorDot( self.damagedOwnerToMe, ownerToLink );
			score += avoid * avoidWeight;
		}

		if ( score > bestScore )
		{
			bestScore = score;
			bestLink = link;
		}
	}

	if ( !IsDefined( bestLink ) )
		return self.origin;

	ownerToNode = bestLink.origin - self.owner.origin;
	ownerToNodeDist = Length( ownerToNode );
	if ( ownerToNodeDist > self.preferredOffsetFromOwner )
	{
		ownerToOwnerNode = nodeClosestToOwner.origin - self.owner.origin;
		if ( VectorDot( ownerToOwnerNode, ownerToNode / ownerToNodeDist ) < 0 )	// owner is between nodeClosest and bestLink.
		{
			resultPos = bestLink.origin;
		}
		else
		{
			ownerNodeToNode = VectorNormalize( bestLink.origin - nodeClosestToOwner.origin );
			resultPos = nodeClosestToOwner.origin + ownerNodeToNode * self.preferredOffsetFromOwner;
		}
	}
	else
	{
		resultPos = bestLink.origin;
	}
	
	resultPos = self DropPosToGround( resultPos );

	if ( !IsDefined( resultPos ) )	// technically, we should probably go down through the list of nodes until we find a good one.
		return self.origin;

	if ( self.bHasBadPath && Distance2DSquared( resultPos, self.lastBadPathGoal ) < 4 )
		return self.origin;

	return resultPos;
}

destroyOnOwnerDisconnect( owner )
{
	self endon( "death" );
	owner waittill_any( "disconnect", "joined_team" );
	
	self notify( "owner_disconnect" );

	// Wait till host migration finishes before suiciding
	if ( maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone() )
		wait 0.05;
	
	self notify( "killanimscript" );
	if ( IsDefined( self.animCBs.OnExit[ self.aiState ] ) )
		self [[ self.animCBs.OnExit[ self.aiState ] ]] ();

	self Suicide();
}

watchAttackState() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while ( true )
	{
		if ( self.aiState == "melee" )
		{
			if ( self.attackState != "melee" )
			{
				self.attackState = "melee";
				self SetSoundState( undefined );
			}
		}
		else if ( self.moveState == "pursuit" ) //( self wantsToAttackTarget() )
		{
			if ( self.attackState != "attacking" )
			{
				self.attackState = "attacking";
				self SetSoundState( "bark", "attacking" );
			}
		}
		else //if( !self wantsToAttackTarget() )
		{
			if ( self.attackState != "warning" )
			{
				if ( self wantsToGrowlAtTarget() )
				{
					self.attackState = "warning";
					self SetSoundState( "growl", "warning" );
				}
				else
				{
					self.attackState = self.aiState;
					self SetSoundState( "pant" );
				}
			}
			else
			{
				if ( !self wantsToGrowlAtTarget() )
				{
					self.attackState = self.aiState;
					self SetSoundState( "pant" );
				}
			}
		}

		wait( 0.05 );
	}
}

SetSoundState( state, attackState )
{
	if ( !IsDefined( state ) )
	{
		self notify( "end_dog_sound" );
		self.soundState = undefined;
		return;
	}

	if ( !IsDefined( self.soundState ) || self.soundState != state )
	{
		self notify( "end_dog_sound" );
		self.soundState = state;

		if ( state == "bark" )
		{
			self thread playBark( attackState );
		}
		else if ( state == "growl" )
		{
			self thread playGrowl( attackState );
		}
		else if ( state == "pant" )
		{
			self thread playPanting();
		}
		else
		{
			assertmsg( "unknown sound state " + state );
		}
	}
}

playBark( state ) // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );
	self endon( "end_dog_sound" );

	if( !isDefined( self.barking_sound ) )
	{
		self PlaySoundOnMovingEnt( ter_op( self.bIsWolf, "anml_wolf_bark", "anml_dog_bark" ) );
		self.barking_sound = true;
		self thread watchBarking();
	}
}

watchBarking() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );
	self endon( "end_dog_sound" );

	wait( RandomIntRange( 5, 10 ) );
	self.barking_sound = undefined;
}

playGrowl( state ) // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );
	self endon( "end_dog_sound" );

	if ( IsDefined( self.lastGrowlPlayedTime ) && GetTime() - self.lastGrowlPlayedTime < 3000 )
		wait( 3 );

	// while the dog is in this state randomly play growl
	while ( true )
	{
		self.lastGrowlPlayedTime = GetTime();
		self PlaySoundOnMovingEnt( ter_op( self.bIsWolf, "anml_wolf_growl", "anml_dog_growl" ) );

		wait( RandomIntRange( 3, 6 ) );
	}
}

playPanting( state )
{
	self endon( "death" );
	level endon( "game_ended" );
	self endon( "end_dog_sound" );

	if ( IsDefined( self.lastPantPlayedTime ) && GetTime() - self.lastPantPlayedTime < 3000 )
		wait( 3 );

	self.lastPantPlayedTime = GetTime();

	while ( true )
	{
		// idle can handle panting on its own.  just check periodically.
		if ( self.aiState == "idle" )
		{
			wait ( 3 );
			continue;
		}

		self.lastPantPlayedTime = GetTime();
		if ( self.moveMode == "run" || self.moveMode == "sprint" )
			self PlaySoundOnMovingEnt( ter_op( self.bIsWolf, "anml_wolf_pants_mp_fast", "anml_dog_pants_mp_fast" ) );
		else
			self PlaySoundOnMovingEnt( ter_op( self.bIsWolf, "anml_wolf_pants_mp_med", "anml_dog_pants_mp_med" ) );

		wait( RandomIntRange( 6, 8 ) );
	}
}

watchOwnerDamage() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		if( !IsDefined( self.owner ) )
			return;
		
		self.owner waittill( "damage", damage, attacker );

		if ( IsPlayer( attacker ) && attacker != self.owner )
		{
			// is the dog already attacking?
			if ( self.attackState == "attacking" )
				continue;

			// is the dog close to the owner?
			if ( DistanceSquared( self.owner.origin, self.origin ) > self.ownerDamagedRadiusSq )
				continue;

			// is the attacker within the owner damaged range?
			if ( DistanceSquared( self.owner.origin, attacker.origin ) > self.ownerDamagedRadiusSq )
				continue;

			self.favoriteEnemy = attacker;
			self.forceAttack = true;
			self thread watchFavoriteEnemyDeath();
		}
	}
}

watchOwnerDeath() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		if( !IsDefined( self.owner ) )
			return;
		
		self.owner waittill( "death" );

		switch( level.gameType )
		{
			case "sd":
				// the dog needs to die when the owner dies because killstreaks go away when the owner dies in sd
				killDog();
				break;
			case "sr":
				// the dog needs to die when the owner is eliminated because killstreaks go away when the owner dies in sr
				result = level waittill_any_return( "sr_player_eliminated", "sr_player_respawned" );
				if( IsDefined( result ) && result == "sr_player_eliminated" )
					killDog();
				break;
		}
	}
}

watchOwnerTeamChange() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		if( !IsDefined( self.owner ) )
			return;
		
		result = self.owner waittill_any_return_no_endon_death( "joined_team", "joined_spectators" );

		if( IsDefined( result ) && ( result == "joined_team" || result == "joined_spectators" ) )
			killDog();
	}
}


watchFavoriteEnemyDeath() // self == dog
{
	self notify( "watchFavoriteEnemyDeath" );
	self endon( "watchFavoriteEnemyDeath" );

	self endon( "death" );

	self.favoriteEnemy waittill_any_timeout( 5.0, "death", "disconnect" );

	self.favoriteEnemy = undefined;
	self.forceAttack = false;
}

OnDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	self.timeOfLastDamage = GetTime();
	if ( IsDefined( self.owner ) )
		self.damagedOwnerToMe = VectorNormalize( self.origin - self.owner.origin );

	if ( self ShouldPlayHitReaction( iDamage, sWeapon, sMeansOfDeath ) )
	{
		switch ( self.aiState )
		{
		case "idle":
			self thread maps\mp\agents\dog\_dog_idle::OnDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
			break;
		case "move":
			self thread maps\mp\agents\dog\_dog_move::OnDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
			break;
		}
	}
}

ShouldPlayHitReaction( iDamage, sWeapon, sMeansOfDeath )
{
	// being specific on certain damage to do the damage reaction
	if ( IsDefined( sWeapon ) && WeaponClass( sWeapon ) == "sniper" )
		return true;
	if ( IsDefined( sMeansOfDeath ) && IsExplosiveDamageMOD( sMeansOfDeath ) && iDamage >= 10 )
		return true;
	if ( IsDefined( sMeansOfDeath ) && sMeansOfDeath == "MOD_MELEE" )
		return true;
	if ( IsDefined( sWeapon ) && sWeapon == "concussion_grenade_mp" )
		return true;
	// flash grenade is monitored using MonitorFlash()

	return false;		
}

MonitorFlash()
{
	self endon( "death" );

	while ( true )
	{
		self waittill( "flashbang", origin, percent_distance, percent_angle, attacker, teamName, extraDuration );

		if ( IsDefined( attacker ) && attacker == self.owner )
			continue;

		switch ( self.aiState )
		{
		case "idle":
			self maps\mp\agents\dog\_dog_idle::onFlashbanged();
			break;
		case "move":
			self maps\mp\agents\dog\_dog_move::onFlashbanged();
			break;
		}
	}
}

/#
debug_dog() // self == dog
{
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		if( GetDvarInt( "scr_debugdog" ) > 0 )
		{
			start = self.origin;
			end = self.origin;
			if( IsDefined( self.enemy ) )
				end = self.enemy.origin;
			color = [ 1, 1, 1 ];

			switch( self.attackState )
			{
			case "idle":
				color = [ 1, 1, 1 ];
				break;
			case "move":
				color = [ 0, 1, 0 ];
				break;
			case "traverse":
				color = [ 0.5, 0.5, 0.5 ];
				break;
			case "melee":
			case "attacking":
				color = [ 1, 0, 0 ];
				break;
			case "warning":
				color = [ 0.8, 0.8, 0 ];
				break;
			default:
				break;
			}
			
			Print3d( self.origin + ( 0, 0, 10 ), self.attackState, ( color[0], color[1], color[2] ) );
			Line( start, end, ( color[0], color[1], color[2] ) );
		}

		wait( 0.05 );
	}
}
#/

/#
ProcessDebugMode()
{
	if ( getdvarint( "scr_dogDebugMode" ) == 1 )
	{
		if ( !IsDefined( self.bDebugMode ) || !self.bDebugMode )
			self thread DoDebugMode();
		self.bDebugMode = true;
		wait( 0.05 );
		return true;
	}
	else
	{
		if ( IsDefined( self.bDebugMode ) && self.bDebugMode )
			self EndDebugMode();
		self.bDebugMode = false;
		return false;
	}
}

DoDebugPrint3D( str, color )
{
	self notify( "enddebugprint3D" );
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "enddebugprint3D" );

	nTimes = 0;
	while ( nTimes < 60 )
	{
		printPos = self.origin + (0,0,48);
		print3D( printPos, str, color, 1, 1 );
		nTimes++;
		wait( 0.05 );
	}
}

DebugDrawHitPos( pos, normal, color )
{
	self notify( "enddebugdrawhitpos" );
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "enddebugdrawhitpos" );

	lineEnd = pos + normal * 100;

	while ( true )
	{
		Line( pos, lineEnd, color, 1, true, 1 );
		wait( 0.05 );
	}
}

DoDebugMode()
{
	self endon( "death" );
	level endon( "game_ended" );
	self endon( "enddebugmode" );

	if ( IsDefined( self.owner ) && IsPlayer( self.owner ) )
		player = self.owner;
	else
		player = level.players[0];

	if ( IsAI( player ) )
		return;

	red = (255,0,0);
	green = (0,255,0);

	while ( true )
	{
		player NotifyOnPlayerCommand( "debug_setgoal", "+usereload" );
		player waittill( "debug_setgoal" );

		viewAngles = player GetPlayerAngles();
		viewEye = player GetEye();

		playerForward = AnglesToForward( viewAngles );
		traceEndPos = viewEye + playerForward * 2048;

		trace = self AIPhysicsTrace( viewEye, traceEndPos, 1, 2, true, true );

		if ( trace[ "fraction" ] < 1 )
		{
			hitNormal = trace[ "normal" ];
			hitPos = trace[ "position" ];
			drawColor = red;
			if ( hitNormal[2] > 0.707 )
			{
				goalPos = self DropPosToGround( hitPos );
				if ( IsDefined( goalPos ) )
				{
					closestNode = GetClosestNodeInSight( goalPos );
					if ( IsDefined( closestNode ) )
					{
						self ScrAgentSetGoalPos( goalPos );
						drawColor = green;
						self notify("enddebugprint3D");
						hitPos = goalPos;
					}
					else
					{
						thread DoDebugPrint3D( "unable to find closest node to pos. (cannot path.)", red );
						self ScrAgentSetGoalPos( self.origin );
					}
				}
				else
				{
					thread DoDebugPrint3D( "dog cannot stand there.", red );
					self ScrAgentSetGoalPos( self.origin );
				}
			}
			else
			{
				thread DoDebugPrint3D( "hit pos too steep.", red );
				self ScrAgentSetGoalPos( self.origin );
			}

			thread DebugDrawHitPos( hitPos, hitNormal, drawColor );
		}
		else
		{
			thread DoDebugPrint3D( "trace did not hit anything.", red );
			self ScrAgentSetGoalPos( self.origin );
			self notify( "enddebugdrawhitpos" );
		}
	}
}

EndDebugMode()
{
	self notify("enddebugprint3D");
	self notify("enddebugdrawhitpos");
	self notify("enddebugmode");
}
#/
