#include common_scripts\utility;
#include maps\mp\agents\_scriptedAgents;

main()
{
	//IPrintLnBold ("Alien entering MOVE state");
	self endon( "killanimscript" );

	self.bLockGoalPos = false;
	self ScrAgentSetPhysicsMode( "gravity" );

	self StartMove();
	self ContinueMovement();
}

end_script()
{
	self.bLockGoalPos = false;
	self CancelAllBut( undefined );
	self ScrAgentSetAnimScale( 1, 1 );
}

SetupMovement()
{
	self thread WaitForRunWalkChange();
	self thread WaitForSharpTurn();
	self thread WaitForStop();
	//self thread WaitForStopEarly();
	//self thread HandleMoveLoopFootsteps();
}

ContinueMovement()
{
	self SetupMovement();

	self ScrAgentSetAnimMode( "code_move" );
	self ScrAgentSetOrientMode( "face motion" );
	self ScrAgentSetAnimScale( 1, 1 );
	self SetMoveAnim( self.moveMode );
}

SetMoveAnim( moveMode )
{
	self SetAnimState( moveMode );
}

WaitForRunWalkChange()
{
	self endon( "dogmove_endwait_runwalk" );
	curMovement = self.moveMode;
	while ( true )
	{
		if ( curMovement != self.moveMode )
		{
			self SetMoveAnim( self.moveMode );
			curMovement = self.moveMode;
		}
		wait( 0.1 );
	}
}

DoSharpTurn( newDir )
{
	lookaheadAngles = VectorToAngles( newDir );
	angleDiff = AngleClamp180( lookaheadAngles[1] - self.angles[1] );
	angleIndex = GetAngleIndex( angleDiff );

	if ( angleIndex == 4 )	// 4 means this turn wasn't sharp enough for me to care. (angle ~= 0)
	{
		ContinueMovement();
		return;
	}

	animState = "sharp_turn";

	turnAnim = self GetAnimEntry( animState, angleIndex );
	animAngleDelta = GetAngleDelta( turnAnim );

	self ScrAgentSetAnimMode( "anim deltas" );
	self ScrAgentSetOrientMode( "face angle abs", ( 0, AngleClamp180( lookaheadAngles[1] - animAngleDelta ), 0 ) );

	self PlayAnimNUntilNotetrack( animState, angleIndex, "sharp_turn" );

	self ContinueMovement();
}

WaitForSharpTurn()
{
	self endon( "dogmove_endwait_sharpturn" );

	self waittill( "path_dir_change", newDir );
	self CancelAllBut( "sharpturn" );

	self DoSharpTurn( newDir );
}

WaitForStop()
{
	self endon( "dogmove_endwait_stop" );

	self waittill( "stop_soon" );

	if ( IsDefined( self.bArrivalsEnabled ) && !self.bArrivalsEnabled )
	{
		self thread WaitForStop();
		return;
	}

	stopState = self GetStopAnimState();

	stopAnim = self GetAnimEntry( stopState.state, stopState.index );
	stopDelta = GetMoveDelta( stopAnim );
	stopAngleDelta = GetAngleDelta( stopAnim );

	goalPos = self GetPathGoalPos();
	assert( IsDefined( goalPos ) );

	meToStop = goalPos - self.origin;
	// not enough room left to play the animation.  abort. (i'm willing to squish/scale the anim up to 12 units.)
	if ( Length( meToStop ) + 12 < Length( stopDelta ) )
	{
		self thread WaitForStop();
		return;
	}

	stopData = self GetStopData();
	stopStartPos = self CalcAnimStartPos( stopData.pos, stopData.angles[1], stopDelta, stopAngleDelta );
	stopStartPosDropped = DropPosToGround( stopStartPos );

	if ( !IsDefined( stopStartPosDropped ) )
	{
		self thread WaitForStop();
		return;
	}

	if ( !self CanMovePointToPoint( stopData.pos, stopStartPosDropped ) )
	{
		self thread WaitForStop();
		return;
	}

	self CancelAllBut( "stop" );

	self thread WaitForPathSetWhileStopping();
	self thread WaitForSharpTurnWhileStopping();
	if ( DistanceSquared( stopStartPos, self.origin ) > 4 )
	{
		self ScrAgentSetWaypoint( stopStartPos );
		self thread WaitForBlockedWhileStopping();
		self waittill( "waypoint_reached" );
		self notify( "dogmove_endwait_blockedwhilestopping" );
	}

	facingDir = goalPos - self.origin;
	facingAngles = VectorToAngles( facingDir );
	facingYaw = ( 0, facingAngles[1] - stopAngleDelta, 0 );

	// scale the anim if necessary, to make sure we end up where we wanted to end up.
	scaleFactors = GetAnimScaleFactors( goalPos - self.origin, stopDelta );

	self ScrAgentSetAnimMode( "anim deltas" );
	self ScrAgentSetOrientMode( "face angle abs", facingYaw, ( 0, facingAngles[1], 0 ) );
	self ScrAgentSetAnimScale( scaleFactors.xy, scaleFactors.z );
	self PlayAnimNUntilNotetrack( stopState.state, stopState.index, "move_stop" );

	self ScrAgentSetGoalPos( self.origin );		// whether i got where i was going, get where i got.
}

WaitForPathSetWhileStopping()
{
	self endon( "killanimscript" );
	self endon( "dogmove_endwait_pathsetwhilestopping" );

	oldGoalPos = self ScrAgentGetGoalPos();

	self waittill( "path_set" );

	newGoalPos = self ScrAgentGetGoalPos();

	if ( DistanceSquared( oldGoalPos, newGoalPos ) < 1 )
	{
		self thread WaitForPathSetWhileStopping();
		return;
	}

	self notify( "dogmove_endwait_stop" );
	self notify( "dogmove_endwait_sharpturnwhilestopping" );

	self ContinueMovement();
}

WaitForSharpTurnWhileStopping()
{
	self endon( "killanimscript" );
	self endon( "dogmove_endwait_sharpturnwhilestopping" );

	self waittill( "path_dir_change", newDir );

	self notify( "dogmove_endwait_pathsetwhilestopping" );
	self notify( "dogmove_endwait_stop" );

	self DoSharpTurn( newDir );
}

WaitForBlockedWhileStopping()
{
	self endon( "killanimscript" );
	self endon( "dogmove_endwait_blockedwhilestopping" );

	self waittill( "path_blocked" );
	self notify( "dogmove_endwait_stop" );
	self ScrAgentSetWaypoint( undefined );
}

WaitForStopEarly()
{
	self endon( "killanimscript" );
	self endon( "dogmove_endwait_stopearly" );

	stopAnim = self GetAnimEntry( "move_stop_4", 0 );
	stopAnimTranslation = GetMoveDelta( stopAnim );
	stoppingDistance = Length( stopAnimTranslation );
	offset = self.preferredOffsetFromOwner + stoppingDistance;
	offsetSq = offset * offset;

	if ( DistanceSquared( self.origin, self.owner.origin ) <= offsetSq )
		return;

	while ( true )
	{
		if ( !IsDefined( self.owner ) )
			break;

		if ( DistanceSquared( self.origin, self.owner.origin ) < offsetSq )
		{
			stopPos = self LocalToWorldCoords( stopAnimTranslation );
			self ScrAgentSetGoalPos( stopPos );
			break;
		}

		wait( 0.1 );
	}
}

CancelAllBut( doNotCancel )
{
	cleanups = [ "runwalk", "sharpturn", "stop", "pathsetwhilestopping", "blockedwhilestopping", "sharpturnwhilestopping", "stopearly" ];

	bCheckDoNotCancel = IsDefined( doNotCancel );

	foreach ( cleanup in cleanups )
	{
		if ( bCheckDoNotCancel && cleanup == doNotCancel )
			continue;
		self notify( "dogmove_endwait_" + cleanup );
	}
}

StartMove()
{
	negStartNode = self GetNegotiationStartNode();
	if ( IsDefined( negStartNode ) )
		goalPos = negStartNode.origin;
	else
		goalPos = self GetPathGoalPos();

	// don't play start if i have no room for the start.
	if ( DistanceSquared( goalPos, self.origin ) < 100 * 100 )
		return;

	lookaheadDir = self GetLookaheadDir();
	lookaheadAngles = VectorToAngles( lookaheadDir );

	myVelocity = self GetVelocity();
	if ( Length2DSquared( myVelocity ) > 16 )
	{
		myVelocity = VectorNormalize( myVelocity );
		if ( VectorDot( myVelocity, lookaheadDir ) > 0.707 )
			return;		// don't need a start if i'm already moving in the direction i want to move.
	}

	angleDiff = AngleClamp180( lookaheadAngles[1] - self.angles[1] );
	angleIndex = GetAngleIndex( angleDiff );

	startAnim = self GetAnimEntry( "move_start", angleIndex );
	startAnimTranslation = GetMoveDelta( startAnim );

	endPos = RotateVector( startAnimTranslation, self.angles ) + self.origin;
	if ( !self CanMovePointToPoint( self.origin, endPos ) )
		return;

	startAnimAngles = GetAngleDelta3D( startAnim );

	self ScrAgentSetAnimMode( "anim deltas" );
	if ( 3 <= angleIndex && angleIndex <= 5 )
		self ScrAgentSetOrientMode( "face angle abs", ( 0, AngleClamp180( lookaheadAngles[1] - startAnimAngles[1] ), 0 ) );
	else
		self ScrAgentSetOrientMode( "face angle abs", self.angles );
	
	self.bLockGoalPos = true;

	self PlayAnimNUntilNotetrack( "move_start", angleIndex, "move_start" );
	
	self.bLockGoalPos = false;
}

GetStopData()
{
	stopData = SpawnStruct();

	if ( IsDefined( self.node ) )
	{
		stopData.pos = self.node.origin;
		stopData.angles = self.node.angles;
	}
	else
	{
		pathGoalPos = self GetPathGoalPos();
		assert( IsDefined( pathGoalPos ) );
		stopData.pos = pathGoalPos;
		//stopData.angles = self.angles;
		stopData.angles = VectorToAngles( self GetLookaheadDir() );
	}

	return stopData;
}

GetStopAnimState( angle )
{
	if ( IsDefined( self.node ) )
	{
		angleDiff = self.node.angles[1] - self.angles[1];
		angleIndex = GetAngleIndex( angleDiff );
	}
	else
	{
		angleIndex = 4;
	}

	result = SpawnStruct();
	result.state = "move_stop";
	result.index = angleIndex;

	return result;
}

CalcAnimStartPos( stopPos, stopAngle, animDelta, animAngleDelta )
{
	dAngle = stopAngle - animAngleDelta;
	angles = ( 0, dAngle, 0 );
	vForward = AnglesToForward( angles );
	vRight = AnglesToRight( angles );

	forward = vForward * animDelta[0];
	right = vRight * animDelta[1];

	return stopPos - forward + right;
}

Dog_AddLean()
{
	leanFrac = Clamp( self.leanAmount / 25.0, -1, 1 );
	if ( leanFrac > 0 )
	{
		// set lean left( leanFrac );
		// set lean right( 0 );
	}
	else
	{
		// set lean left( 0 );
		// set lean right( 0 - leanFrac );
	}
}


HandleFootstepNotetracks( note, animState, animIndex, animTime )
{
	if ( true )
		return false;

	switch ( note )
	{
	case "alien_footstep_r":
	case "alien_footstep_l":
	case "alien_footstep_small_r":
	case "alien_footstep_small_l":
		{
			surfaceType = undefined;
			if ( IsDefined( self.surfaceType ) )
			{
				surfaceType = self.surfaceType;
				self.lastSurfaceType = surfaceType;
			}
			else if ( IsDefined( self.lastSurfaceType ) )
			{
				surfaceType = self.lastSurfaceType;
			}
			else
			{
				surfaceType = "dirt";
			}

			if ( surfaceType != "dirt" && surfaceType != "concrete" && surfaceType != "wood" && surfaceType != "metal" )
				surfaceType = "dirt";

			if ( surfaceType == "concrete" )	// code == concrete, sound == cement.
				surfaceType = "cement";

			//moveType = self.sound_animMoveType;
			//if ( !IsDefined( moveType ) )
			//	moveType = "run";
			if ( self.aiState == "traverse" )
				moveType = "land";
			else if ( self.moveMode == "sprint" )
				moveType = "sprint";
			else if ( self.moveMode == "fastwalk" )
				moveType = "walk";
			else
				moveType = "run";

			self PlaySoundOnMovingEnt( "alien_minion_footstep" );
			/*
			if ( IsSubStr( note, "front_left" ) )
			{
				soundAlias1 = "anml_dog_mvmt_accent";
				soundAlias2 = "anml_dog_mvmt_vest";

				if ( moveType == "walk" )
					suffix = "_npc";
				else
					suffix = "_run_npc";

				self PlaySoundOnMovingEnt( soundAlias1 + suffix );
				self PlaySoundOnMovingEnt( soundAlias2 + suffix );
			}*/
		}

		return true;
	}

	return false;
}

DoHitReaction( hitAngle )
{
	self CancelAllBut( undefined );

	self.bLockGoalPos = true;
	self.stateLocked = true;

	// hitAngle is angle from me to damage
	angleDiff = AngleClamp180( hitAngle - self.angles[1] );

	if ( angleDiff > 0 )
		animIndex = 1;	// left
	else
		animIndex = 0;	// right

	self ScrAgentSetAnimMode( "anim deltas" );
	self ScrAgentSetOrientMode( "face angle abs", self.angles );

	self PlayAnimNUntilNotetrack( "run_pain", animIndex, "run_pain" );

	self.bLockGoalPos = false;
	self.stateLocked = false;

	self ContinueMovement();
}

OnDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if ( self.stateLocked )
		return;

	hitDirToAngles = VectorToAngles( vDir );
	hitAngle = hitDirToAngles[1] - 180;

	self DoHitReaction( hitAngle );
}

OnFlashbanged( origin, percent_distance, percent_angle, attacker, teamName, extraDuration )
{
	if ( self.stateLocked )
		return;

	DoHitReaction( self.angles[1] + 180 );
}