#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

kHeliSniperAirTime = 45;
KS_NAME = "heli_gunner";

init()
{	
	//sets level.air_start_nodes
	self maps\mp\killstreaks\_helicopter_guard::lbSupport_setAirStartNodes();
	
	//sets level.air_node_mesh
	self maps\mp\killstreaks\_helicopter_guard::lbSupport_setAirNodeMesh();
	
	level.killstreakWeildWeapons["iw6_cabehemothminigun_mp"] = KS_NAME;	
	
}


tryUseHeliGunner( lifeId, streakName ) //self = player
{
	config = SpawnStruct();
	config.xpPopup = "destroyed_heli_gunner";
	config.callout = "callout_destroyed_heli_gunner";
	config.samDamageScale = 0.09;
	config.engineVFXtag = "tag_engine_right";
	config.helicopter_model = "vehicle_ca_blackhawk";
	// xpval = 200
	level.heliConfigs[KS_NAME] = config;
	
	level.killstreakWeildWeapons["iw6_cabehemothminigun_mp"] = KS_NAME;	
	
	closestStart = getClosestStartNode( self.origin );
	closestNode = getClosestNode( self.origin ); 	
	startAng = VectorToAngles( closestNode.origin - closestStart.origin );	
	
	if ( IsDefined( self.underWater ) && self.underWater )
	{
		return false;
	}
//	context fail cases
	else if ( !IsDefined( level.air_node_mesh ) ||
		 !IsDefined( closestStart ) ||
		 !IsDefined( closestNode ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_UNAVAILABLE_IN_LEVEL" );
		return false;		
	}
	
	numIncomingVehicles = 1;

	if ( exceededMaxHeliSnipers() )
	{
		self iPrintLnBold( &"KILLSTREAKS_AIR_SPACE_TOO_CROWDED" );
		return false;
	}

	if( currentActiveVehicleCount() >= maxVehiclesAllowed() || level.fauxVehicleCount + numIncomingVehicles >= maxVehiclesAllowed() )
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_VEHICLES" );
		return false;
	}
	
	// cannot use while capturing a crate
	if( IsDefined(self.isCapturingCrate) && self.isCapturingCrate )
		return false;
	
	// cannot use while reviving a player
	if( IsDefined(self.isReviving) && self.isReviving )
		return false;
	
	//	create heli	
	chopper = createHeli( self, closestStart, closestNode, startAng, streakName, lifeId );
	
	if ( !IsDefined( chopper ) )
		return false;
	
	//	this is where the heli starts
	usedStreak = self heliPickup( chopper, streakName );
	
	if ( isDefined( usedStreak ) && usedStreak == "fail" )
		return false;

	return true;
}

exceededMaxHeliSnipers()
{
	return ( IsDefined( level.lbSniper ) );
}

getClosestStartNode( pos )
{
	// gets the start node that is closest to the position passed in
	closestNode = undefined;
	closestDistance = 999999;

	foreach( loc in level.air_start_nodes )
	{ 	
		nodeDistance = Distance( loc.origin, pos );
		if ( nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}

	return closestNode;
}

createHeli( owner, startNode, closestNode, startAng, streakName, lifeId )
{
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	pathGoal = closestNode.origin;
	
	forward = AnglesToForward( startAng );
	startPos = startNode.origin;
	
	config = level.heliConfigs[streakName];
	
	chopper = spawnHelicopter( owner, startPos, forward, "attack_littlebird_mp" , config.helicopter_model  );
	
	if ( !IsDefined( chopper ) )
		return;
		
	//find best z for closest node (some maps have nodes under the mesh)
	traceOffset = getHeliPilotTraceOffset();
	traceStart = ( pathGoal ) + ( getHeliPilotMeshOffset() + traceOffset );
	traceEnd = ( pathGoal ) + ( getHeliPilotMeshOffset() - traceOffset );
	tracePos = BulletTrace( traceStart, traceEnd, false, false, false, false, true );
		
	if ( IsDefined( tracePos["entity"] ) && tracePos[ "normal" ][2] > .1 )
	{
		pathGoal = tracePos[ "position" ] - getHeliPilotMeshOffset() + (0,0,384);
	}
	
	chopper maps\mp\killstreaks\_helicopter::addToLittleBirdList( "heli_gunner" );
	chopper thread maps\mp\killstreaks\_helicopter::removeFromLittleBirdListOnDeath();
	chopper thread waitForDeath();

	chopper.lifeId = lifeId;
		
	chopper.forward = forward;
	chopper.pathStart = startPos;
	chopper.pathGoal = pathGoal;
	chopper.pathEnd = startNode.origin;
	chopper.flyHeight = pathGoal[2];
	chopper.maxHeight = heightEnt.origin;
	chopper.onGroundPos = startNode.origin;
	chopper.pickupPos = chopper.onGroundPos+(0,0,300);
	chopper.hoverPos = chopper.onGroundPos+(0,0,600);
	
	chopper.forwardYaw = forward[1];
	chopper.backwardYaw = forward[1] + 180;
	if ( chopper.backwardYaw > 360 )
		chopper.backwardYaw-= 360;
	
	chopper.heliType = "littlebird";
	chopper.heli_type = "littlebird";
	chopper.locIndex = startNode.orgin;
	chopper.allowSafeEject = true;
	
	//	ownership
	chopper.streakName = KS_NAME;
	chopper.owner = owner;
	chopper.team = owner.team;
	chopper thread leaveOnOwnerDisconnect();
	
	//	damage / existence
	chopper.attractor = Missile_CreateAttractorEnt( chopper, level.heli_attract_strength, level.heli_attract_range );
	chopper.isDestroyed = false;	
	chopper.maxhealth = 10000;
	chopper thread maps\mp\killstreaks\_flares::flares_monitor( 1 );
	chopper thread maps\mp\killstreaks\_helicopter::heli_damage_monitor( KS_NAME, true );
	chopper thread heliDeathCleanup( KS_NAME );
	
	//	params	
	//this is for off case trophy
	chopper.speed = 100;
	chopper.ammo = 100;
	chopper.followSpeed = 40;
	chopper setCanDamage( true );
	chopper SetMaxPitchRoll( 45, 45 );	
	chopper Vehicle_SetSpeed( chopper.speed, 100, 40 );
	chopper SetYawSpeed( 120, 60 );
	chopper SetHoverParams( 10, 10, 60 );
	chopper setneargoalnotifydist( 512 );
	chopper.killCount = 0;
	
	chopper.allowBoard = false;
	chopper.ownerBoarded = true;
	
	// hide the wings
	//chopper HidePart( "tag_wings" );
	
	return chopper;
}

getBestHeight( centerPoint )
{
	self endon ( "death" );
	self endon ( "crashing" );
	self endon ( "helicopter_removed" );
	self endon ( "heightReturned" );
	
	heightEnt = GetEnt( "airstrikeheight", "targetname" );
	
	if ( IsDefined( heightEnt ) )
		trueHeight = heightEnt.origin[2];
	else if( IsDefined( level.airstrikeHeightScale ) )
		trueHeight = 850 * level.airstrikeHeightScale;
	else
		trueHeight = 850;
	
	bestHeightPoint = BulletTrace( centerPoint, centerPoint - (0, 0,10000), false, self, false, false, false, false );	
	bestHeight = bestHeightPoint["position"][2];
	offset = 0;
	offset2 = 0;
	
	for( i = 0; i < 30; i++ )
	{
		wait( 0.05 );
		
		turn = i % 8; 
		
		globalOffset = i*7;
		
		switch ( turn )
		{
		case 0:
			offset = globalOffset;
			offset2 = globalOffset;
			break;
		case 1:
			offset = globalOffset * -1;
			offset2 = globalOffset * -1;
			break;
		case 2:
			offset = globalOffset * -1;
			offset2 = globalOffset;
			break;
		case 3:
			offset = globalOffset;
			offset2 = globalOffset * -1;
			break;
		case 4:
			offset = 0;
			offset2 = globalOffset * -1;
			break;
		case 5:
			offset = globalOffset * -1;
			offset2 = 0;
			break;
		case 6:
			offset = globalOffset;
			offset2 = 0;
			break;
		case 7:
			offset = 0;
			offset2 = globalOffset;
			break;	
		
		default:
			break;
		}
		
		trace = BulletTrace( centerPoint + (offset, offset2, 1000), centerPoint - (offset, offset2,10000), false, self, false, false, false, false, false );		
		
		//trace can hit the helicopter or other flying ents
		if ( isDefined( trace["entity"] ) )
			continue;
		
		if ( trace["position"][2] + 145 > bestHeight )
		{
			bestHeight = trace["position"][2] + 145;
			//self thread drawLine( centerPoint + (offset, offset2, 1000), centerPoint - (offset, offset2,10000), 120, (0,0,1) );
		}
	}
	
	//endPoint = centerPoint * (1,1,0);
	//endPoint += (0,0,bestHeight);
	//self thread drawLine( centerPoint , endPoint , 120, (1,0,1) );
	
	return bestHeight;
}


heliPickup( chopper, streakName )
{	
	level endon( "game_ended" );
	chopper endon( "death" );
	chopper endon( "crashing" );
	chopper endon( "owner_disconnected" );
	chopper endon( "killstreakExit" );
	
	closestStartNode = getClosestStartNode( self.origin );	
	level thread teamPlayerCardSplash( "used_heli_gunner", self, self.team );
	
	if( IsDefined( closestStartNode.angles ) )
		startAng = closestStartNode.angles;
	else
		startAng = ( 0, 0, 0);
	
	self _disableUsability();
	
	flyHeight = chopper.flyHeight;
	
	if ( isDefined( closestStartNode.neighbors[0] ) )
		closestNode = closestStartNode.neighbors[0];
	else
		closestNode = getClosestNode( self.origin );
	
	forward = anglesToForward( self.angles );
	
	targetPos = ( closestNode.origin*(1,1,0) ) + ( (0,0,1)*flyHeight ) + ( forward * -100 );
	chopper.targetPos = targetPos;
	chopper.currentNode = closestNode;
	
	result = self movePlayerToChopper(chopper);
	
	//player died while being warped in
	if( isDefined( result ) && result == "fail" )
	{
		chopper thread heliLeave();
		return result;
	}
	else 
	{
		self thread onHeli( chopper );
		return result;
	}
}

chopperSelfDamageWatchter()
{
	level endon( "game_ended" );
	self endon("death");
	self endon("crashing");
	self endon("owner_disconnected");
	self endon("killstreakExit");
	
	while(1)
	{
		self waittill("damage", damage, attacker, direction, point, type);
		if(attacker == self.owner)
		{
			self.owner iPrintlnBold("stop hitting yourself!");
			self.health += damage;
		}
	}	
	
}

onHeli( chopper )
{
	level endon( "game_ended" );
	chopper endon( "death" );
	chopper endon( "crashing" );
	chopper endon( "owner_disconnected" );
	chopper endon( "killstreakExit" );
	
	if ( isDefined ( self.imsList ) )
		self destroyCarriedIms();
	
	chopper thread giveCoolAssGun();
	
	chopper SetYawSpeed( 1, 1, 1, 0.1 );

	chopper notify("picked_up_passenger");
	self _enableUsability();
	
	chopper Vehicle_SetSpeed( chopper.speed, 100, 40 );
	
	self.OnHeliSniper = true;
	self.heliSniper = chopper;

	//	only now end and leave if owner dies (since they can't get back on)
	chopper endon( "owner_death" );
	chopper thread pushCorpseOnOwnerDeath();
	chopper thread leaveOnOwnerDeath();
	//chopper thread chopperSelfDamageWatchter();
	
	chopper.owner ThermalVisionFOFOverlayOn();
	
	chopper setVehGoalPos( chopper.targetPos, 1 );
	
	chopper thread heliCreateLookAtEnt();
	
	self giveGunnerPerks();
	
	chopper thread restockPlayerHealth();

	chopper waittill ( "near_goal" );

	chopper thread heliMovementControl();
	
	self thread watchEarlyExit( chopper );
	
	wait( kHeliSniperAirTime );
	
	self notify( "heli_sniper_timeout" );
	
	self doDropff( chopper );
	self takeGunnerPerks();
	
}

restockPlayerHealth()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "owner_disconnected" );
	self endon( "killstreakExit" );
	self endon( "dropping" );
	
	//self.owner IPrintLnBold("Player Max Health = " + self.owner.maxhealth);
	
	while(1)
	{
		self.owner waittill("damage");
		
		self.owner.health = 100;
	}
	
}

giveGunnerPerks()
{
	gunnerPerks = [];
	gunnerPerks[0] = "specialty_quickdraw";
	gunnerPerks[1] = "specialty_fastreload";
	gunnerPerks[2] = "specialty_holdbreath";
	gunnerPerks[3] = "specialty_autospot";
	gunnerPerks[4] = "specialty_bulletpenetration";
	gunnerPerks[5] = "specialty_marksman";
	gunnerPerks[6] = "specialty_sharp_focus";
	gunnerPerks[7] = "specialty_armorpiercing";	
	gunnerPerks[8] = "specialty_blindeye";	
	gunnerPerks[9] = "specialty_incog";
	self.givenPerks = [];
	
	self ThermalVisionFOFOverlayOn();
	
	for ( i=0; i < gunnerPerks.size; i++ )
	{
		if ( !self _hasPerk( gunnerPerks[i] ) )
		{
			self givePerk( gunnerPerks[i], false );
			self.givenPerks[self.givenPerks.size] = gunnerPerks[i];			
		}
	}		
	
}

takeGunnerPerks()
{
	self ThermalVisionFOFOverlayOff();

	for ( i=0; i < self.givenPerks.size; i++ )
	{
		self _unsetPerk( self.givenPerks[i] );
	}
	self.givenPerks = [];	
}

doDropff( chopper )
{
	chopper notify( "dropping" );
	chopper thread heliReturnToDropsite();
	chopper waittill( "at_dropoff" );
	
	chopper Vehicle_SetSpeed( 60 );
	chopper SetYawSpeed( 180, 180, 180, .3 );

	wait( 1 );
	
	if ( !isReallyAlive(self) )
		return;
	
	//remove all cool stuff
	self thread setTempNoFallDamage();
	self StopRidingVehicle();		
	self allowJump( true );
	self setStance( "stand" );
	self.OnHeliSniper = false;
	self.heliSniper = undefined;
	chopper.ownerBoarded = false;
	self takeWeapon( level.heli_gunner_weapon );
	self enableWeaponSwitch();
	
	self takeGunnerPerks();
	
	chopper.owner notify( "dropping" );
	
	lastWeapon = self getLastWeapon();
	
	if( !self HasWeapon( lastWeapon) )
		lastWeapon = self maps\mp\killstreaks\_killstreaks::getFirstPrimaryWeapon();	
	
	self switch_to_last_weapon( lastWeapon );
	
	wait( 1 );
	
	chopper thread heliLeave();
}

watchEarlyExit( chopper )	// self == player
{
	self endon( "heli_sniper_timeout" );
	
	chopper thread maps\mp\killstreaks\_killstreaks::allowRideKillstreakPlayerExit( "dropping" );
	
	chopper waittill("killstreakExit");
	
	self doDropff( chopper );
}

movePlayerToChopper( chopper )
{
	self endon( "disconnect" );
	
	self VisionSetNakedForPlayer( "black_bw", 0.50 );
	self set_visionset_for_watching_players( "black_bw", 0.50, 1.0 );
	
	blackOutWait = self waittill_any_timeout( 0.50, "death" );
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	
	if ( blackOutWait == "death" )
	{
		self thread maps\mp\killstreaks\_killstreaks::clearRideIntro( 1.0 );
		return "fail";
	}
	
	//needed for warping in the player
	self CancelMantle();
	
	if ( blackOutWait != "disconnect" ) 
	{
		self thread maps\mp\killstreaks\_killstreaks::clearRideIntro( 1.0, .75 );
		
		if ( self.team == "spectator" )
			return "fail";
	}
	
	//Warping In Player
	chopper attachPlayerToChopper();
	
	if ( !isAlive( self ) )
		return "fail";
	
	// 2013-08-27 wallace: give sniper's team eyes on. 
	// We don't use the lbSniper variable because it has a much longer lifespan; we want to only give the benefit while the player is in the heli
	level.heliSniperEyesOn = chopper;
	level notify( "update_uplink" );
}


destroyCarriedIms()
{
	//carrying an IMS
	foreach ( ims in self.imsList)
	{
		if ( isDefined ( ims.carriedby ) && ims.carriedby == self )
		{
			self ForceUseHintOff();
			self.isCarrying = undefined;
			self.carriedItem = undefined;

			if( IsDefined( ims.bombSquadModel ) )
				 ims.bombSquadModel delete();
			
			ims delete();
			self enableWeapons();
		}
	}
}

heliCreateLookAtEnt()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "leaving" );
	self.owner endon( "death" );
	
	placementOrigin = self.origin + AnglesToRight( self.owner.angles ) * 1000;
		
	self.LookAtEnt = Spawn( "script_origin", placementOrigin );
	self SetLookAtEnt( self.LookAtEnt );
	self SetYawSpeed( 360, 120 );
	
	for( ;; )
	{
		wait( .25 );
		placementOrigin = self.origin + AnglesToRight( self.owner.angles ) * 1000;
		self.LookatEnt.origin = placementOrigin;
	}
}

attachPlayerToChopper()
{
	//	stow any carry items
	self.owner notify( "force_cancel_sentry" );
	self.owner notify( "force_cancel_ims" );
	self.owner notify( "force_cancel_placement" );
	self.owner notify( "cancel_carryRemoteUAV" );	
	
	self.owner setPlayerAngles( self getTagAngles( "TAG_RIDER" ) );
	self.owner RideVehicle( self, 40, 70, 5, 70, true );
	self.owner setStance( "crouch" );
	self.owner allowJump( false );
	
	self thread reEquipLightArmor();
	
	self.ownerBoarded = true;
	self notify( "boarded" );
		
	self.owner.chopper = self;
}


heliReturnToDropsite()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "owner_disconnected" );
	self endon( "owner_death" );
	
	DropOffNode = undefined;
	closestNode = undefined;
	closestDistance = undefined;
	closestNodeIsHigh = false;
	
	foreach( loc in level.air_node_mesh )
	{ 	
		if ( !isDefined( loc.script_parameters ) || !isSubStr( loc.script_parameters, "pickupNode" ) )
			continue;
		
		nodeDistance = DistanceSquared( loc.origin, self.origin );
		if ( !isDefined ( closestDistance ) || nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
			
			if( loc.script_parameters == "pickupNodehigh" )
				closestNodeIsHigh = true;
			else
				closestNodeIsHigh = false;
		}
	}

	//fixes heli from dropping player on lamp in chasm
	if ( getMapName() == "mp_chasm" )
	{
		if ( closestNode.origin == ( -224,-1056,2376 ) )
			closestNode.origin = ( -304,-896,2376 );
	}
	
	if ( closestNodeIsHigh && !BulletTracePassed( self.origin, closestNode.origin, false, self ) )
	{
	
		self setVehGoalPos( self.origin+(0,0,2300), 1 );
		self waittill_msg_or_timeout( "near_goal", "goal", 5 );
		
		DropOffNodeOrig = closestNode.origin;
		DropOffNodeOrig += ( 0, 0, 1500 );

	}
	else if ( closestNode.origin[2] > self.origin[2] )
	{
		DropOffNodeOrig = closestNode.origin;
	}
	else
	{
		DropOffNodeOrig = closestNode.origin * (1, 1, 0);
		DropOffNodeOrig += ( 0, 0, self.origin[2] );
	}
	
	self setVehGoalPos( DropOffNodeOrig, 1 );
	
	lowTempHeight = self getBestHeight( DropOffNodeOrig );
	lowHeightPos = DropOffNodeOrig * (1,1,0);
	groundPosition = lowHeightPos + (0,0,lowTempHeight);
	
	self waittill_msg_or_timeout( "near_goal", "goal", 5 );
	self.movedLow = false;
	
	self setVehGoalPos( groundPosition + (0,0,200), 1 );
	self.droppingOff = true;
		
	self waittill_msg_or_timeout( "near_goal", "goal", 5 );
	
	self.movedLow = true;
	
	self notify( "at_dropoff" );
}

waittill_msg_or_timeout( msg1, msg2, timer )
{
	level endon( "game_ended" );

	self endon( msg1 );
	self endon( msg2 );
	wait timer;
}

heliMovementControl()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	
	self Vehicle_SetSpeed( 60, 45, 20 );
	self setneargoalnotifydist( 8 );
		
	for ( ;; )
	{
		movementDirection = self.owner GetNormalizedMovement();
		
		if ( movementDirection[0] >= 0.15 || movementDirection[1] >= 0.15 || movementDirection[0] <= -0.15 || movementDirection[1] <= -0.15 )
			self thread manualMove( movementDirection );
		
		wait 0.05;
	}
	
}


heliFreeMovementControl()
{
	self Vehicle_SetSpeed( 80, 60, 20 );
	self setneargoalnotifydist( 8 );
	
	for ( ;; )
	{
		movementDirection = self.owner GetNormalizedMovement();
		
		if ( movementDirection[0] >= 0.15 || movementDirection[1] >= 0.15 || movementDirection[0] <= -0.15 || movementDirection[1] <= -0.15 )
			self thread manualMoveFree( movementDirection );
		
		wait 0.05;
	}
	
}


manualMoveFree( direction )
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	
	self notify ( "manualMove" );
	self endon ( "manualMove" );
	
	fwrd = AnglesToForward( self.owner.angles ) * ( 350 * direction[0] );
	rght = AnglesToRight( self.owner.angles ) * ( 250 * direction[1] );
	vec = fwrd + rght;
	
	moveToPoint = self.origin + vec;
	
	moveToPoint *= (1,1,0);
	moveToPoint += (0,0,self.maxHeight[2]);
	
	if ( Distance2DSquared( (0,0,0), moveToPoint ) > 8000000 )
		return;
		
	self SetVehGoalPos( moveToPoint, 1 );
	self waittill( "goal" );
}


manualMove( direction )
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	
	self notify ( "manualMove" );
	self endon ( "manualMove" );
	
	fwrd = AnglesToForward( self.owner.angles ) * ( 250 * direction[0] );
	rght = AnglesToRight( self.owner.angles ) * ( 250 * direction[1] );
	vec = fwrd + rght;
	heightOffset = 256;
	
	moveToPoint = self.origin + vec;
	
	traceOffset = getHeliPilotTraceOffset();
	traceStart = ( moveToPoint ) + ( getHeliPilotMeshOffset() + traceOffset );
	traceEnd = ( moveToPoint ) + ( getHeliPilotMeshOffset() - traceOffset );
	
	//This will force the helisniper on the vehicle mesh until outside its bounds.
	tracePos = BulletTrace( traceStart, traceEnd, false, false, false, false, true );
		
	if ( IsDefined( tracePos["entity"] ) && tracePos[ "normal" ][2] > .1 )
	{
		moveToPoint = tracePos[ "position" ] - getHeliPilotMeshOffset() + (0,0,heightOffset);
		zDelta =  moveToPoint[2] - self.origin[2];
		
		//this is to handle high vertical collision
		if ( zDelta > 1000 )
			return;
		
		self SetVehGoalPos( moveToPoint, 1 );
		self waittill( "goal" );
	}
}


heliLeave()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self notify( "end_disconnect_check" );
	self notify( "end_death_check" );
	self notify( "leaving" );
	
	if ( IsDefined( self.ladder ) )
		self.ladder delete();
	if ( IsDefined( self.trigger ) )
		self.trigger delete();
	if ( IsDefined( self.turret ) )
		self.turret delete();		
	if ( IsDefined( self.msg ) )
		self.msg destroyElem();		
	if ( IsDefined( self.switchMsg ) )
		self.switchMsg destroyElem();
	if ( IsDefined( self.moveMsg ) )
		self.moveMsg destroyElem();
	
	self ClearLookAtEnt();
	
	// 2013-08-27 wallace: remove eyes on
	level.heliSniperEyesOn = undefined;
	level notify( "update_uplink" );
	
	//	rise to leave
	self SetYawSpeed( 220, 220, 220, .3 );
	self Vehicle_SetSpeed( 120, 60 );
	
	self SetVehGoalPos( self.origin + (0,0,1200),1);
	self waittill( "goal" );
	
	farPathEnd = (self.pathEnd - self.pathGoal ) * 5000;
	
	//	leave
	self setvehgoalpos( farPathEnd, 1 );
	self Vehicle_SetSpeed( 300, 75 );
	self.leaving = true;
	
	self waittill_any_timeout ( 5, "goal" );
	
	if ( IsDefined( level.lbSniper ) && level.lbSniper == self )
	{
		level.lbSniper = undefined;
	}
	
	self notify( "delete" );
	self delete();
}


heliDeathCleanup( streakName )
{
	level endon( "game_ended" );
	self endon( "leaving" );
	
	self waittill( "death" );
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	
	self thread maps\mp\killstreaks\_helicopter::lbOnKilled();
	
	//	cleanup
	if ( IsDefined( self.ladder ) )
		self.ladder delete();
	if ( IsDefined( self.trigger ) )
		self.trigger delete();	
	if ( IsDefined( self.turret ) )
		self.turret delete();	
	if ( IsDefined( self.msg ) )
		self.msg destroyElem();
	if ( IsDefined( self.switchMsg ) )
		self.switchMsg destroyElem();	
	if ( IsDefined( self.moveMsg ) )
		self.moveMsg destroyElem();
	
	//	what to do with player?
	if ( IsDefined( self.owner ) && isAlive( self.owner ) && self.ownerBoarded == true )
	{		
		self.owner StopRidingVehicle();
		
		bestAttacker = undefined;
		bestAttackerObj = undefined;
		
		if ( isDefined( self.attackers ) )
		{
			mostDamage = 0;
			foreach ( key, value in self.attackers )
			{
				if ( value >= mostDamage )
				{
					mostDamage = value;
					bestAttacker = key;
				}
			}
		}
		
		if ( isDefined( bestAttacker ) )
		{
			foreach( player in level.participants )
			{
				if ( player getUniqueId() == bestAttacker )
					bestAttackerObj = player;
			}
		}
		
		//Special handling of reflective damage
		ffType = GetDvarInt( "scr_team_fftype" );
			
		if ( IsDefined( bestAttackerObj ) && fftype != 2 )
		{
			RadiusDamage( self.owner.origin, 200, 2600, 2600, bestAttackerObj );
		}
		else if ( fftype == 2 && IsDefined( bestAttackerObj ) && attackerIsHittingTeam( bestAttackerObj, self.owner ) )
		{
			RadiusDamage( self.owner.origin, 200, 2600, 2600, bestAttackerObj );
			RadiusDamage( self.owner.origin, 200, 2600, 2600 );
		}
		else
		{
			RadiusDamage( self.owner.origin, 200, 2600, 2600 );
		}
		
		self.owner.OnHeliSniper = false;
		self.owner.heliSniper = undefined;
	}
}


setTempNoFallDamage()
{	
	if ( !self _hasPerk( "specialty_falldamage" ) )
	{
		level endon( "game_ended" );
		self  endon( "death" );		
		self  endon( "disconnect" );
		
		self givePerk( "specialty_falldamage", false );
		wait ( 2 );
		self _unsetPerk( "specialty_falldamage" );
	}	
}


reEquipLightArmor()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	
	timesReEquipped = 0;
	
	for( ;; )
	{
		wait( 0.05 );
		if ( !IsDefined( self.owner.lightArmorHP ) && !self.owner isJuggernaut() )
		{
			self.owner maps\mp\perks\_perkfunctions::setLightArmor();
			timesReEquipped++;
			if ( timesReEquipped >= 2 )
				break;
		}
	}
}


keepCrouched()
{
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self  endon( "dropping" );
	
	for( ;; )
	{
		if ( self.owner GetStance() != "crouch") 
		{
			self.owner setStance( "crouch" );
		}
		wait( 0.05 );
	}
}

giveCoolAssGun()
{
	level.heli_gunner_weapon = "iw6_cabehemothminigun_mp";
	
	level endon( "game_ended" );
	self  endon( "death" );
	self  endon( "crashing" );
	self  endon( "dropping" );
	self.owner endon( "disconnect" );
	
	
	//TODO Turn this back on if we want scripted audio/hitfx
	//self thread monitor_gun_audio();
	
	weapon_given = false;
	i = 0;
	while(self.owner GetCurrentPrimaryWeapon() != level.heli_gunner_weapon)
	{
		if ( !isAlive(self.owner) )
			return "fail";
		
		if ( self.owner GetCurrentPrimaryWeapon() != level.heli_gunner_weapon )
		{
			self.owner GiveWeapon( level.heli_gunner_weapon );
			self.owner SwitchToWeaponImmediate( level.heli_gunner_weapon );
			self.owner disableWeaponSwitch();
			self.owner GiveMaxAmmo( level.heli_gunner_weapon );
			self.owner thread restockOwnerAmmo();
			weapon_given = true;
			i += 1;
		}
		
		wait( 0.05 );
		
	}

}

restockOwnerAmmo()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "dropping" );
	
	while(1)
	{
		self waittill ("weapon_fired");
		
		self GiveStartAmmo(level.heli_gunner_weapon);
	}
}

update_hit_fx()
{
	self endon("a10_cannon_stop");
	
	while(true)
	{
	
		eye = self geteye();
		angles = self getplayerangles();
		
		forward = anglestoforward( angles );
		end = eye + ( forward * 7000 );
		trace = bullettrace( eye, end, true, self);
		PlayFX(level._effect["vfx_heli_gunner_impact"], trace["position"]);
		wait 0.15;
	}
}

monitor_gun_audio()
{
	level endon( "game_ended" );
	self.owner endon( "death" );
	self.owner endon( "disconnect" );
	self.owner endon( "dropping" );
	self endon( "crashing" );
	
	self.owner NotifyOnPlayerCommand( "a10_cannon_start", "+attack" );
	self.owner NotifyOnPlayerCommand( "a10_cannon_stop", "-attack" );
	
	self thread gun_audio_cutoff_master();
	
	fire_sound = "veh_a10_npc_fire_gatling_lp";
	while(1)
	{
		// IsFiringVehicleTurret
		if ( !(self.owner AttackButtonPressed()) )
		{
			self.owner waittill( "a10_cannon_start" );
		}
		
		self.owner thread update_hit_fx();
		
		self PlayLoopSound( fire_sound );
		
		self.owner waittill( "a10_cannon_stop" );
	
		self StopLoopSound( fire_sound );
	}
}

gun_audio_cutoff_master()
{
	self thread gun_audio_cutoff("death", self.owner);
	self thread gun_audio_cutoff("game_ended", level);
	self thread gun_audio_cutoff("disconnect", self.owner);
	self thread gun_audio_cutoff("dropping", self.owner);
	self thread gun_audio_cutoff("crashing", self);
}

gun_audio_cutoff(condition, listen_ent)
{
	self endon("audio_end");
	
	listen_ent waittill(condition);
	
	//self StopLoopSound("veh_a10_npc_fire_gatling_lp");
	
	self notify("audio_end");
}

pushCorpseOnOwnerDeath()
{
	level endon( "game_ended" );
	self.owner endon( "disconnect" );
	self  endon( "death" );
	self  endon( "crashing" );
	
	self.owner waittill( "death" );
	self.owner.OnHeliSniper = false;
	self.owner.heliSniper = undefined;
	self.ownerBoarded = false;

	//race condition can cause undefined origin here
	if ( isDefined ( self.origin ) )	
		PhysicsExplosionSphere( self.origin, 200, 200, 1 );
}


leaveOnOwnerDisconnect()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "end_disconnect_check" );

	self.owner waittill( "disconnect" );
	
	self notify ( "owner_disconnected" );
	
	self thread heliLeave();		
}


leaveOnOwnerDeath()
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "crashing" );
	self endon( "end_death_check" );

	self.owner waittill( "death" );
	
	self notify ( "owner_death" );
	
	self thread heliLeave();		
}


getClosestNode( pos )
{
	// gets the closest node to the position passed in, regardless of link
	closestNode = undefined;
	closestDistance = 999999;
	
	foreach( loc in level.air_node_mesh )
	{ 	
		nodeDistance = distance( loc.origin, pos );
		if ( nodeDistance < closestDistance )
		{
			closestNode = loc;
			closestDistance = nodeDistance;
		}
	}
	
	return closestNode;
}

waitForDeath()
{
	entNum = self GetEntityNumber();
	
	self waittill ( "death" );

	level.lbSniper = undefined;
	
	// 2013-08-27 wallace: remove eyes on
	if ( IsDefined( level.heliSniperEyesOn ) )
	{
		level.heliSniperEyesOn = undefined;
		level notify( "update_uplink" );
	}
}
