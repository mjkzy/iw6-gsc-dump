#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\agents\_agent_utility;

main(allowed)
{
	allowed[ allowed.size ] = "airdrop_pallet";
	entitytypes = getentarray();
	for(i = 0; i < entitytypes.size; i++)
	{
		if(isdefined(entitytypes[i].script_gameobjectname))
		{
			dodelete = true;
			
			// allow a space-separated list of gameobjectnames
			gameobjectnames = strtok(entitytypes[i].script_gameobjectname, " ");
			
			for(j = 0; j < allowed.size; j++)
			{
				for (k = 0; k < gameobjectnames.size; k++)
				{
					if(gameobjectnames[k] == allowed[j])
					{	
						dodelete = false;
						break;
					}
				}
				if (!dodelete)
					break;
			}
			
			if(dodelete)
			{
				//println("DELETED: ", entitytypes[i].classname);
				entitytypes[i] delete();
			}
		}
	}
}


init()
{
	level.numGametypeReservedObjectives = 0;

	level thread onPlayerConnect();
}

/*
=============
onPlayerConnect

=============
*/
onPlayerConnect()
{
	level endon ( "game_ended" );

	for( ;; )
	{
		level waittill( "connected", player );
		
		player thread onPlayerSpawned();
		player thread onDisconnect();
	}
}


/*
=============
onPlayerSpawned

=============
*/
onPlayerSpawned()
{
	self endon( "disconnect" );
	level endon ( "game_ended" );
	
	for(;;)
	{
		self waittill( "spawned_player" );
		
		if ( IsDefined( self.gameObject_fauxSpawn ) )
		{
			self.gameObject_fauxSpawn = undefined;
		}
		else
		{
			self init_player_gameobjects();
		}
	}
}

/*
=============
init_player_gameobjects

Initializes variables for gameobjects
=============
*/
init_player_gameobjects()
{
	self thread onDeath();
	self.touchTriggers = [];
	self.carryObject = undefined;
	self.claimTrigger = undefined;
	self.canPickupObject = true;
	self.killedInUse = undefined;
	self.initialized_gameobject_vars = true;	// Needs to be the last line in init_player_gameobjects()
}


/*
=============
onDeath

Drops any carried object when the player dies
=============
*/
onDeath()
{
	level endon ( "game_ended" );

	self waittill ( "death" );
	
	if ( IsDefined( self.carryObject ) )
	{
		assert( self.carryObject.carrier == self );
		self.carryObject thread setDropped();
	}
}


/*
=============
onDisconnect

Drops any carried object when the player disconnects
=============
*/
onDisconnect()
{
	level endon ( "game_ended" );

	self waittill ( "disconnect" );

	if ( IsDefined( self.carryObject ) )
	{
		assert( self.carryObject.carrier == self );
		self.carryObject thread setDropped();
	}
}


/*
=============
createCarryObject

Creates and returns a carry object
=============
*/
createCarryObject( ownerTeam, trigger, visuals, offset )
{
	carryObject = spawnStruct();
	carryObject.type = "carryObject";
	carryObject.curOrigin = trigger.origin;
	carryObject.ownerTeam = ownerTeam;
	carryObject.entNum = trigger getEntityNumber();
	
	if ( isSubStr( trigger.classname, "use" ) )
		carryObject.triggerType = "use";
	else
		carryObject.triggerType = "proximity";
		
	// associated trigger
	trigger.baseOrigin = trigger.origin;
	carryObject.trigger = trigger;
	// assuming only CarryObjects can be dropped, and thus need this flag
	if ( !IsDefined( trigger.linkToEnabledFlag ) )
	{
		trigger.linkToEnabledFlag = true;
		trigger EnableLinkTo();
	}
	
	carryObject.useWeapon = undefined;
	
	if ( !IsDefined( offset ) )
		offset = (0,0,0);

	carryObject.offset3d = offset;
	
	// associated visual objects
	for ( index = 0; index < visuals.size; index++ )
	{
		visuals[index].baseOrigin = visuals[index].origin;
		visuals[index].baseAngles = visuals[index].angles;
	}
	carryObject.visuals = visuals;
	
	// compass objectives
	carryObject.compassIcons = [];
	
	carryObject.objIDPingFriendly = false;
	carryObject.objIDPingEnemy = false;

	foreach( teamName in level.teamNameList )
	{
		carryObject.teamObjIds[teamName] = getNextObjID();
		objective_add( carryObject.teamObjIds[teamName], "invisible", carryObject.curOrigin );
		objective_team( carryObject.teamObjIds[teamName], teamName );
		carryObject.objPoints[teamName] = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_" + teamName + "_" + carryObject.entNum, carryObject.curOrigin + offset, teamName, undefined );
		carryObject.objPoints[teamName].alpha = 0;
		
		// would have liked to use link the waypoint, instead of just setting positions
		// carryObject.objPoints[teamName] thread maps\mp\_entityheadicons::keepPositioned( visuals[0], offset, 0.05 );
	}

	// carrying player
	carryObject.carrier = undefined;
	
	// misc
	carryObject.isResetting = false;	
	carryObject.interactTeam = "none"; // "none", "any", "friendly", "enemy";
	carryObject.allowWeapons = false;
	
	// 3d world icons
	carryObject.worldIcons = [];
	carryObject.carrierVisible = false; // carryObject only
	carryObject.visibleTeam = "none"; // "none", "any", "friendly", "enemy";

	carryObject.carryIcon = undefined;

	// calbacks
	carryObject.onDrop = undefined;
	carryObject.onPickup = undefined;
	carryObject.onReset = undefined;
	
	if ( carryObject.triggerType == "use" )
	{
		carryObject thread carryObjectUseThink();
	}
	else
	{
		carryObject.curProgress = 0;

		carryObject.useTime = 0;
		carryObject.useRate = 0;

		carryObject.teamUseTimes = [];
		carryObject.teamUseTexts = [];

		carryObject.numTouching["neutral"] = 0;
		carryObject.touchList["neutral"] = [];
		
		carryObject.numTouching["none"] = 0;
		carryObject.touchList["none"] = [];

		foreach( name in level.teamnamelist )
		{
			carryObject.numTouching[name] = 0;
			carryObject.touchList[name] = [];
		}

		carryObject.claimTeam = "none";
		carryObject.claimPlayer = undefined;
		carryObject.lastClaimTeam = "none";
		carryObject.lastClaimTime = 0;
		
		carryObject thread carryObjectProxThink();
	}
		
	carryObject thread updateCarryObjectOrigin();

	return carryObject;
}


/*
=============
carryObjectUseThink

Think function for "use" type carry objects
=============
*/
carryObjectUseThink()
{
	level endon ( "game_ended" );

	while ( true )
	{
		self.trigger waittill ( "trigger", player );
		
		if ( self.isResetting )
			continue;
		
		if ( !isReallyAlive( player ) )
			continue;
			
		if ( !self canInteractWith( player.pers["team"] ) )
			continue;
		
		if ( !player.canPickupObject )
			continue;
		
		if ( !IsDefined(player.initialized_gameobject_vars) )
			continue;

		if ( IsDefined( player.throwingGrenade ) )
			continue;
			
		if ( IsDefined( self.carrier ) )
			continue;
			
		if ( player isUsingRemote() )
			continue;
			
		self setPickedUp( player );
	}
}


/*
=============
carryObjectProxThink

Think function for "proximity" type carry objects
=============
*/
carryObjectProxThink()
{
	//self thread carryObjectProxThinkInstant();
	self thread carryObjectProxThinkDelayed();
}

carryObjectProxThinkInstant()
{
	level endon ( "game_ended" );

	while ( true )
	{
		self.trigger waittill ( "trigger", player );
		
		if ( self.isResetting )
			continue;
		
		if ( !isReallyAlive( player ) )
			continue;
			
		if ( !self canInteractWith( player.pers["team"] ) )
			continue;
		
		if ( !player.canPickupObject )
			continue;
			
		if ( IsDefined( player.throwingGrenade ) )
			continue;
			
		if ( IsDefined( self.carrier ) )
			continue;
			
		self setPickedUp( player );
	}
}

carryObjectProxThinkDelayed()
{
	level endon ( "game_ended" );
	
	self thread Proxtriggerthink();
	
	while ( true )
	{
		if ( self.useTime && self.curProgress >= self.useTime )
		{
			self.curProgress = 0;
			
			creditPlayer = getEarliestClaimPlayer();

			if ( IsDefined( self.onEndUse ) )
				self [[self.onEndUse]]( self getClaimTeam(), creditPlayer, IsDefined( creditPlayer ) );
			
			if ( IsDefined( creditPlayer ) )
				self setPickedUp( creditPlayer );
			
			self setClaimTeam( "none" );
			self.claimPlayer = undefined;
		}
		
		if ( self.claimTeam != "none" )
		{
			if ( self.useTime )
			{
				if ( !self.numTouching[self.claimTeam] )
				{
					if ( IsDefined( self.onEndUse ) )
						self [[self.onEndUse]]( self getClaimTeam(), self.claimPlayer, false );
					
					self setClaimTeam( "none" );
					self.claimPlayer = undefined;
				}
				else
				{
					self.curProgress += (50 * self.useRate);
					if ( IsDefined( self.onUseUpdate ) )
						self [[self.onUseUpdate]]( self getClaimTeam(), self.curProgress / self.useTime, (50*self.useRate) / self.useTime );
				}
			}
			else
			{
				if ( isReallyAlive( self.claimPlayer ) )
					self setPickedUp( self.claimPlayer );
				
				self setClaimTeam( "none" );
				self.claimPlayer = undefined;	
			}
		}

		wait ( 0.05 );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	}
}



/*
=============
pickupObjectDelay

Temporarily disallows picking up of "proximity" type objects
=============
*/
pickupObjectDelay( origin )
{
	level endon ( "game_ended" );

	self endon("death");
	self endon("disconnect");
	
	self.canPickupObject = false;
	
	for( ;; )
	{
		if ( distanceSquared( self.origin, origin ) > 64*64 )
			break;

		wait 0.2;
	}
	
	self.canPickupObject = true;
}


/*
=============
setPickedUp

Sets this object as picked up by passed player
=============
*/
setPickedUp( player )
{
	assert( isReallyAlive( player ) );
	
	if ( IsAI(player) && IsDefined(player.owner) )
		return;
	
	if ( IsDefined( player.carryObject ) )
	{
		if ( IsDefined( self.onPickupFailed ) )
			self [[self.onPickupFailed]]( player );
			
		return;
	}
		
	player giveObject( self );
	
	self setCarrier( player );
	
	// unlink from moving platform
	if ( IsDefined( self.trigger GetLinkedParent() ) )
	{
		for ( index = 0; index < self.visuals.size; index++ )
		{
			self.visuals[index] Unlink();
		}
		
		self.trigger Unlink();
	}

	for ( index = 0; index < self.visuals.size; index++ )
		self.visuals[index] hide();
			
	self.trigger.origin += (0,0,10000);
	
	self.trigger maps\mp\_movers::stop_handling_moving_platforms();
	
	self notify ( "pickup_object" );
	if ( IsDefined( self.onPickup ) )
		self [[self.onPickup]]( player );
	
	self updateCompassIcons();
	self updateWorldIcons();
}


updateCarryObjectOrigin()
{
	level endon ( "game_ended" );
	
	objPingDelay = 5.0;
	for ( ;; )
	{
		if ( IsDefined( self.carrier ) )
		{
			
			self.curOrigin = self.carrier.origin + (0,0,75);
			foreach( teamname in level.teamNameList )
			{
				self.objPoints[teamname] maps\mp\gametypes\_objpoints::updateOrigin( self.curOrigin );
			}
		
			foreach( teamName in level.teamNameList )
			{
				if ( (self.visibleTeam == "friendly" || self.visibleTeam == "any") && self isFriendlyTeam( teamName ) && self.objIDPingFriendly )
				{
					if ( self.objPoints[teamName].isShown )
					{
						self.objPoints[teamName].alpha = self.objPoints[teamname].baseAlpha;
						self.objPoints[teamName] fadeOverTime( objPingDelay + 1.0 );
						self.objPoints[teamName].alpha = 0;
					}
					objective_position( self.teamObjIds[teamName], self.curOrigin );
				}
			}

			foreach( teamName in level.teamNameList )
			{
				if ( (self.visibleTeam == "enemy" || self.visibleTeam == "any") && !self isFriendlyTeam( teamName ) && self.objIDPingEnemy )
				{
					if ( self.objPoints[teamName].isShown )
					{
						self.objPoints[teamName].alpha = self.objPoints[teamname].baseAlpha;
						self.objPoints[teamName] fadeOverTime( objPingDelay + 1.0 );
						self.objPoints[teamName].alpha = 0;
					}
					objective_position( self.teamObjIds[teamName], self.curOrigin );
				}
			}

			self wait_endon( objPingDelay, "dropped", "reset" );
		}
		else
		{
			// 2013-07-02 wallace: this is an awful hack to get dropped bombs to update their icons while on amoving platforms
			// I can't link the objPoint struct, but I do link the trigger
			self.curOrigin = self.trigger.origin;
			
			//keep my objective position up to date with my entity position
			foreach( teamName in level.teamNameList )
			{
				self.objPoints[teamname] maps\mp\gametypes\_objpoints::updateOrigin( self.curOrigin + self.offset3d );
			}

			wait ( 0.05 );
		}
	}
}


hideCarryIconOnGameEnd()
{
	self endon ( "disconnect" );
	self endon ( "death" );
	self endon ( "drop_object" );	
	
	level waittill( "game_ended" );
	
	if ( IsDefined( self.carryIcon ) )
	{
		self.carryIcon.alpha = 0;
	}
}


/*
=============
giveObject

Set player as holding this object
Should only be called from setPickedUp
=============
*/
giveObject( object )
{
	assert( !IsDefined( self.carryObject ) );

	self.carryObject = object;
	self thread trackCarrier();
		
	if ( !object.allowWeapons )
	{
		self _disableWeapon();
		self thread manualDropThink();
	}

	if ( IsDefined( object.carryIcon ) )
	{
		if ( level.splitscreen )
		{
			self.carryIcon = createIcon( object.carryIcon, 33, 33 );
			self.carryIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -50, -78 );
		}
		else
		{
			self.carryIcon = createIcon( object.carryIcon, 50, 50 );
			self.carryIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -50, -65 );
		}		
		
		self.carryIcon.hidewheninmenu = true;
		self thread hideCarryIconOnGameEnd();		
	}
}


/*
=============
returnHome

Resets a carryObject to it's default home position
=============
*/
returnHome()
{
	self.isResetting = true;

	self notify ( "reset" );
	for ( index = 0; index < self.visuals.size; index++ )
	{
		self.visuals[index].origin = self.visuals[index].baseOrigin;
		self.visuals[index].angles = self.visuals[index].baseAngles;
		self.visuals[index] show();
	}
	self.trigger.origin = self.trigger.baseOrigin;
	
	self.curOrigin = self.trigger.origin;
	
	if ( IsDefined( self.onReset ) )
		self [[self.onReset]]();

	self clearCarrier();
	
	updateWorldIcons();
	updateCompassIcons();
	
	self.isResetting = false;
}


isHome()
{
	if ( IsDefined( self.carrier ) )
		return false;

	if ( self.curOrigin != self.trigger.baseOrigin )
		return false;
		
	return true;
}

/*
=============
setPosition

set a carryObject to a new position
=============
*/
setPosition( origin, angles )
{
	self.isResetting = true;

	for ( index = 0; index < self.visuals.size; index++ )
	{
		self.visuals[index].origin = origin;
		self.visuals[index].angles = angles;
		self.visuals[index] show();
	}
	self.trigger.origin = origin;
	
	self.curOrigin = self.trigger.origin;
	
	self clearCarrier();
	
	updateWorldIcons();
	updateCompassIcons();
	
	self.isResetting = false;
}

onPlayerLastStand()
{
	if ( IsDefined( self.carryObject ) )
	{
		assert( self.carryObject.carrier == self );
		self.carryObject thread setDropped();
	}
}

carryobject_overrideMovingPlatformDeath( data )
{
	for ( index = 0; index < data.carryobject.visuals.size; index++ )
	{
		data.carryobject.visuals[index] Unlink();
	}
	
	data.carryobject.trigger Unlink();
	
	data.carryobject notify( "stop_pickup_timeout" );
	
	data.carryobject returnHome();
}


/*
=============
setDropped

Sets this carry object as dropped and calculates dropped position
=============
*/
setDropped()
{
	self.isResetting = true;
	self.resetNow = undefined;
	
	self notify ( "dropped" );
	
	//Dont trace against the object(s) about to be dropped.
	foreach(visual in self.visuals)
	{
		visual.prev_contents = visual SetContents(0);
	}

//	trace = bulletTrace( self.safeOrigin + (0,0,20), self.safeOrigin - (0,0,20), false, undefined );
	if ( IsDefined( self.carrier ) && self.carrier.team != "spectator" )
	{
		trace = playerPhysicsTrace( self.carrier.origin + (0,0,20), self.carrier.origin - (0,0,2000), false, self.carrier.body );
		angleTrace = bulletTrace( self.carrier.origin + (0,0,20), self.carrier.origin - (0,0,2000), false, self.carrier.body, true, false, true );
	}
	else
	{
		trace = playerPhysicsTrace( self.safeOrigin + (0,0,20), self.safeOrigin - (0,0,20), false, undefined );
		angleTrace = bulletTrace( self.safeOrigin + (0,0,20), self.safeOrigin - (0,0,20), false, undefined, true, false, true  );
	}
	
	foreach(visual in self.visuals)
	{
		visual SetContents(visual.prev_contents);
	}
	
	droppingPlayer = self.carrier;
	touchingBadTrigger = false;
	
	if ( IsDefined( trace ) )
	{
		tempAngle = randomfloat( 360 );
		
		dropOrigin = trace;		
		if ( angleTrace["fraction"] < 1 && distance( angleTrace["position"], trace ) < 10.0 )
		{
			forward = (cos( tempAngle ), sin( tempAngle ), 0);
			forward = VectorNormalize( forward - ( angleTrace[ "normal" ] * VectorDot( forward, angleTrace[ "normal" ] ) ) );
			dropAngles = vectortoangles( forward );
		}
		else
		{
			dropAngles = (0,tempAngle,0);
		}
		
		for ( index = 0; index < self.visuals.size; index++ )
		{
			self.visuals[index].origin = dropOrigin;
			self.visuals[index].angles = dropAngles;
			self.visuals[index] show();
		}
		self.trigger.origin = dropOrigin;
		
		self.curOrigin = self.trigger.origin;
		
		// we hit something, link to it
		mover = angleTrace[ "entity" ];
		// 2014-01-29 wallace: bullet trace will hit IMS and other placeables, so we need to ignore them
		// Not sure what is the best way to detect this case?
		// TODO: should flag objects that could be destroyed so that we handle them explicitly
		if ( IsDefined( mover ) && IsDefined( mover.owner ) )
		{
			mover = mover GetLinkedParent();
		}
		
		if ( IsDefined( mover ) )
		{	
			if ( IsDefined( mover.invalid_gameobject_mover ) && mover.invalid_gameobject_mover == true )
			{
				//reset us instead!
				self.resetNow = true;	
			}
			else
			{
				for ( index = 0; index < self.visuals.size; index++ )
				{
					self.visuals[index] LinkTo( mover );
				}
				
				//Link the pick up trigger
				//May need to call EnableLinkTo() on the trigger, but it would have to be done somewhere else because it will error if called more than once.
				self.trigger LinkTo( mover );
				
				data = SpawnStruct();
				data.carryobject = self;
				data.deathOverrideCallback = ::carryobject_overrideMovingPlatformDeath;
				self.trigger thread maps\mp\_movers::handle_moving_platforms( data );
			}
		}

		self thread pickupTimeout();
	}
	else
	{
		for ( index = 0; index < self.visuals.size; index++ )
		{
			self.visuals[index].origin = self.visuals[index].baseOrigin;
			self.visuals[index].angles = self.visuals[index].baseAngles;
			self.visuals[index] show();
		}
		self.trigger.origin = self.trigger.baseOrigin;
		
		self.curOrigin = self.trigger.baseOrigin;
	}	
	
	if ( IsDefined( self.onDrop ) )
		self [[self.onDrop]]( droppingPlayer );
	
	self clearCarrier();
	
	self updateCompassIcons();
	self updateWorldIcons();
	
	self.isResetting = false;
}



setCarrier( carrier )
{
	self.carrier = carrier;
	
	self thread updateVisibilityAccordingToRadar();
}


clearCarrier()
{
	if ( !isdefined( self.carrier ) )
		return;
	
	self.carrier takeObject( self );
	
	self.carrier = undefined;
	
	self notify("carrier_cleared");
}


pickupTimeout()
{
	self endon ( "pickup_object" );
	self endon ( "stop_pickup_timeout" );
	
	wait ( 0.05 );
	
	if ( IsDefined( self.resetNow ) )
	{
		self.resetNow = undefined;
		self returnHome();	
		return;
	}
	
	mineTriggers = getEntArray( "minefield", "targetname" );
	hurtTriggers = getEntArray( "trigger_hurt", "classname" );
	radTriggers = getEntArray( "radiation", "targetname" );

	for ( index = 0; index < radTriggers.size; index++ )
	{
		if ( !self.visuals[0] isTouching( radTriggers[index] ) )
			continue;

		self returnHome();
		return;
	}

	for ( index = 0; index < mineTriggers.size; index++ )
	{
		if ( !self.visuals[0] isTouching( mineTriggers[index] ) )
			continue;

		self returnHome();
		return;
	}

	for ( index = 0; index < hurtTriggers.size; index++ )
	{
		if ( !self.visuals[0] isTouching( hurtTriggers[index] ) )
			continue;

		self returnHome();	
		return;
	}

	if ( IsDefined( self.autoResetTime ) )
	{
		wait ( self.autoResetTime );

		if ( !IsDefined( self.carrier ) )
			self returnHome();	
	}
}

/*
=============
takeObject

Set player as dropping this object
=============
*/
takeObject( object )
{
	if ( IsDefined( self.carryIcon ) )
		self.carryIcon destroyElem();

	if ( IsDefined( self ) )
		self.carryObject = undefined;
		
	self notify ( "drop_object" );
	
	if ( object.triggerType == "proximity" )
		self thread pickupObjectDelay( object.trigger.origin );

	if ( isReallyAlive( self ) && !object.allowWeapons )
	{
		self _enableWeapon();
	}
}


/*
=============
trackCarrier

Calculates and updates a safe drop origin for a carry object based on the current carriers position
=============
*/
trackCarrier()
{
	level endon ( "game_ended" );
	self endon ( "disconnect" );
	self endon ( "death" );
	self endon ( "drop_object" );
	
	while ( IsDefined( self.carryObject ) && isReallyAlive( self ) )
	{
		if ( self isOnGround() )
		{
			trace = bulletTrace( self.origin + (0,0,20), self.origin - (0,0,20), false, undefined );
			if ( trace["fraction"] < 1 ) // if there is ground at the player's origin (not necessarily true just because of isOnGround)
				self.carryObject.safeOrigin = trace["position"];
		}
		wait ( 0.05 );
	}
}


/*
=============
manualDropThink

Allows the player to manually drop this object by pressing the fire button
Does not allow drop if the use button is pressed
=============
*/
manualDropThink()
{
	level endon ( "game_ended" );

	self endon ( "disconnect" );
	self endon ( "death" );
	self endon ( "drop_object" );
	
	for( ;; )
	{
		while ( self attackButtonPressed() || self fragButtonPressed() || self secondaryOffhandButtonPressed() || self meleeButtonPressed() )
			wait .05;
	
		while ( !self attackButtonPressed() && !self fragButtonPressed() && !self secondaryOffhandButtonPressed() && !self meleeButtonPressed() )
			wait .05;
	
		if ( IsDefined( self.carryObject ) && !self useButtonPressed() )
			self.carryObject thread setDropped();
	}
}


deleteUseObject()
{
	foreach( teamname in level.teamNameList )
	{
		objective_delete( self.teamObjIds[teamname] );
		maps\mp\gametypes\_objpoints::deleteObjPoint( self.objPoints[teamname] );
	}
	
	self.trigger = undefined;
	
	self notify ( "deleted" );
}

/*
=============
createUseObject

Creates and returns a use object
=============
*/
createUseObject( ownerTeam, trigger, visuals, offset )
{
	useObject = spawnStruct();
	useObject.type = "useObject";
	useObject.curOrigin = trigger.origin;
	useObject.ownerTeam = ownerTeam;
	useObject.entNum = trigger getEntityNumber();
	useObject.keyObject = undefined;
	
	if ( isSubStr( trigger.classname, "use" ) )
		useObject.triggerType = "use";
	else
		useObject.triggerType = "proximity";
		
	// associated trigger
	useObject.trigger = trigger;
	
	// associated visual object
	for ( index = 0; index < visuals.size; index++ )
	{
		visuals[index].baseOrigin = visuals[index].origin;
		visuals[index].baseAngles = visuals[index].angles;
	}
	useObject.visuals = visuals;
	
	if ( !IsDefined( offset ) )
		offset = (0,0,0);

	useObject.offset3d = offset;
	
	// compass objectives
	useObject.compassIcons = [];
	foreach( teamname in level.teamNameList )
	{
		useObject.teamObjIds[teamname] = getNextObjID();
		objective_add( useObject.teamObjIds[teamname], "invisible", useObject.curOrigin );
		objective_team( useObject.teamObjIds[teamname], teamname );
		useObject.objPoints[teamname] = maps\mp\gametypes\_objpoints::createTeamObjpoint( "objpoint_" + teamname + "_" + useObject.entNum, useObject.curOrigin + offset, teamname, undefined );
		useObject.objPoints[teamname].alpha = 0;
	}
	
	// misc
	useObject.interactTeam = "none"; // "none", "any", "friendly", "enemy";
	
	// 3d world icons
	useObject.worldIcons = [];
	useObject.visibleTeam = "none"; // "none", "any", "friendly", "enemy";

	// calbacks
	useObject.onUse = undefined;
	useObject.onCantUse = undefined;

	useObject.useText = "default";
	useObject.useTime = 10000;
	useObject.curProgress = 0;

	if ( useObject.triggerType == "proximity" )
	{
		useObject.teamUseTimes = [];
		useObject.teamUseTexts = [];

		useObject.numTouching["neutral"] = 0;
		useObject.touchList["neutral"] = [];

		useObject.numTouching["none"] = 0;
		useObject.touchList["none"] = [];

		foreach( name in level.teamNameList )
		{
			useObject.numTouching[name] = 0;
			useObject.touchList[name] = [];
		}

		useObject.useRate = 0;
		useObject.claimTeam = "none";
		useObject.claimPlayer = undefined;
		useObject.lastClaimTeam = "none";
		useObject.lastClaimTime = 0;

		useObject thread useObjectProxThink();
	}
	else
	{
		useObject.useRate = 1;
		useObject thread useObjectUseThink();
	}
	
	return useObject;
}


/*
=============
setKeyObject

Sets this use object to require carry object
=============
*/
setKeyObject( object )
{
	self.keyObject = object;
}


/*
=============
useObjectUseThink

Think function for "use" type carry objects
=============
*/
useObjectUseThink()
{
	level endon ( "game_ended" );
	self endon ( "deleted" );
	
	while ( true )
	{
		self.trigger waittill ( "trigger", player );	
		
		if ( !isReallyAlive( player ) )
			continue;
			
		if ( !self canInteractWith( player.pers["team"] ) )
			continue;
		
		if ( !player isOnGround() )
			continue;
	
		if ( !player isJuggernaut() && isKillstreakWeapon( player GetCurrentWeapon() ) )
			continue;
		
		if ( IsDefined( self.useCondition ) )
		{
			if ( !self [[self.useCondition]]( player ) )
				continue;
		}
		
		if ( IsDefined( self.keyObject ) && (!IsDefined( player.carryObject ) || player.carryObject != self.keyObject ) )
		{
			if ( IsDefined( self.onCantUse ) )
				self [[self.onCantUse]]( player );
			continue;
		}

		if ( !player isWeaponEnabled() )
		{
			//player iPrintLnBold( "Action unavailable." );
			continue;
		}

		result = true;
		if ( self.useTime > 0 )
		{
			if ( IsDefined( self.onBeginUse ) )
			{
				// make sure we've reset the progress bar
				player updateUIProgress( self, false );
				self [[self.onBeginUse]]( player );
			}

			if ( !IsDefined( self.keyObject ) )
				self thread cantUseHintThink();

			team = player.pers["team"];
			
			result = self useHoldThink( player );
			
			self notify ( "finished_use" );
			
			if ( IsDefined( self.onEndUse ) )
				self [[self.onEndUse]]( team, player, result );	
		}

		if ( !result )
			continue;
		
		if ( IsDefined( self.onUse ) )
			self [[self.onUse]]( player );
	}
}


cantUseHintThink()
{
	level endon ( "game_ended" );
	self endon ( "deleted" );
	self endon ( "finished_use" );

	while ( true )
	{
		self.trigger waittill ( "trigger", player );

		if ( !isReallyAlive( player ) )
			continue;
			
		if ( !self canInteractWith( player.pers["team"] ) )
			continue;
		
		if ( IsDefined( self.onCantUse ) )
			self [[self.onCantUse]]( player );
	}
}


getEarliestClaimPlayer()
{
	assert( self.claimTeam != "none" );
	team = self.claimTeam;
	
	if ( isReallyAlive( self.claimPlayer ) )
		earliestPlayer = self.claimPlayer;
	else
		earliestPlayer = undefined;
	
	if ( self.touchList[team].size > 0 )
	{
		// find earliest touching player
		earliestTime = undefined;
		players = getArrayKeys( self.touchList[team] );
		for ( index = 0; index < players.size; index++ )
		{
			touchdata = self.touchList[team][players[index]];
			if ( isReallyAlive( touchdata.player ) && (!IsDefined( earliestTime ) || touchdata.starttime < earliestTime)  )
			{
				earliestPlayer = touchdata.player;
				earliestTime = touchdata.starttime;
			}
		}
	}

	return earliestPlayer;
}	


/*
=============
useObjectProxThink

Think function for "proximity" type carry objects
=============
*/
useObjectProxThink()
{
	level endon ( "game_ended" );
	self endon ( "deleted" );
	
	self thread proxTriggerThink();
	
	while ( true )
	{
		if ( self.useTime && self.curProgress >= self.useTime )
		{
			self.curProgress = 0;
			
			creditPlayer = getEarliestClaimPlayer();

			if ( IsDefined( self.onEndUse ) )
				self [[self.onEndUse]]( self getClaimTeam(), creditPlayer, IsDefined( creditPlayer ) );
			
			if ( IsDefined( creditPlayer ) && IsDefined( self.onUse ) )
				self [[self.onUse]]( creditPlayer );
			
			self setClaimTeam( "none" );
			self.claimPlayer = undefined;
		}
		
		if ( self.claimTeam != "none" )
		{
			if ( self.useTime )
			{
				if ( !self.numTouching[self.claimTeam] )
				{
					if ( IsDefined( self.onEndUse ) )
						self [[self.onEndUse]]( self getClaimTeam(), self.claimPlayer, false );
					
					self setClaimTeam( "none" );
					self.claimPlayer = undefined;
				}
				else
				{
					self.curProgress += (50 * self.useRate);
					if ( IsDefined( self.onUseUpdate ) )
						self [[self.onUseUpdate]]( self getClaimTeam(), self.curProgress / self.useTime, (50*self.useRate) / self.useTime );
				}
			}
			else
			{
				if ( IsDefined( self.onUse ) )
					self [[self.onUse]]( self.claimPlayer );
				
				self setClaimTeam( "none" );
				self.claimPlayer = undefined;	
			}
		}

		wait ( 0.05 );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	}
}


/*
=============
proxTriggerThink ("proximity" only)

Handles setting the current claiming team and player, as well as starting threads to track players touching the trigger
=============
*/
proxTriggerThink()
{
	level endon ( "game_ended" );
	self endon ( "deleted" );
	
	entityNumber = self.entNum;
	
	while ( true )
	{
		self.trigger waittill ( "trigger", player );
		
		if ( !isReallyAlive( player ) )
			continue;
		
		if ( !IsGameParticipant( player ) )
			continue;
			
		if ( IsDefined( self.carrier ) )
			continue;

		if ( player isUsingRemote() || IsDefined( player.spawningAfterRemoteDeath ) )
			continue;
			
		if ( IsDefined( player.classname ) && player.classname == "script_vehicle" )
			continue;
		
		if ( !IsDefined(player.initialized_gameobject_vars) )
			continue;

		if( level.gametype == "ctfpro" )
		{
			if ( IsDefined( self.type ) && self.type == "carryObject" && IsDefined( player.carryFlag ) )
				continue;			
		}
			
		if ( self canInteractWith( player.pers["team"], player ) && self.claimTeam == "none" )
		{
			if ( !IsDefined( self.keyObject ) || (IsDefined( player.carryObject ) && player.carryObject == self.keyObject ) )
			{
				//	do this in here so, at least, it only happens once for success
				if ( !self proxTriggerLOS( player ) )
					continue;				
				
				setClaimTeam( player.pers["team"] );
				self.claimPlayer = player;

				relativeTeam = self getRelativeTeam( player.pers["team"] );
				if ( IsDefined( self.teamUseTimes[relativeTeam] ) )
					self.useTime = self.teamUseTimes[relativeTeam];
					// TODO we don't store the base self.useTime setting... we should.
				
				if ( self.useTime && IsDefined( self.onBeginUse ) )
					self [[self.onBeginUse]]( self.claimPlayer );
			}
			else
			{
				if ( IsDefined( self.onCantUse ) )
					self [[self.onCantUse]]( player );
			}
		}
			
		if ( self.useTime && isReallyAlive( player ) && !IsDefined( player.touchTriggers[entityNumber] ) )
			player thread triggerTouchThink( self );
	}
}

proxTriggerLOS( player )
{
	if ( !IsDefined( self.requiresLOS ) )
		return true;
	
	traceStart = player getEye();
	traceEnd = self.trigger.origin + (0,0,32);
	trace = bulletTrace( traceStart, traceEnd, false, undefined );
	
	if ( trace["fraction"] != 1 )
	{
		traceEnd = self.trigger.origin + (0,0,16);
		trace = bulletTrace( traceStart, traceEnd, false, undefined );		
	}
	
	if ( trace["fraction"] != 1 )
	{
		traceEnd = self.trigger.origin + (0,0,0);
		trace = bulletTrace( traceStart, traceEnd, false, undefined );		
	}
	
	return ( trace["fraction"] == 1 );		
}


/*
=============
setClaimTeam ("proximity" only)

Sets this object as claimed by specified team including grace period to prevent 
object reset when claiming team leave trigger for short periods of time
=============
*/
setClaimTeam( newTeam )
{
	assert( newTeam != self.claimTeam );
	
	if ( self.claimTeam == "none" && getTime() - self.lastClaimTime > 1000 )
		self.curProgress = 0;
	else if ( newTeam != "none" && newTeam != self.lastClaimTeam )
		self.curProgress = 0;

	self.lastClaimTeam = self.claimTeam;
	self.lastClaimTime = getTime();
	self.claimTeam = newTeam;
	
	self updateUseRate();
}


getClaimTeam()
{
	return self.claimTeam;
}

/*
=============
triggerTouchThink ("proximity" only)

Updates use object while player is touching the trigger and updates the players visual use bar
=============
*/
triggerTouchThink( object ) // self == player
{
	team = self.pers["team"];

	object.numTouching[team]++;

	touchName = self.guid;
	struct = spawnstruct();
	struct.player = self;
	struct.starttime = gettime();
	object.touchList[team][touchName] = struct;
	
	if( !IsDefined( object.noUseBar ) )
		object.noUseBar = false;

	self.touchTriggers[object.entNum] = object.trigger;

	object updateUseRate();

	while ( isReallyAlive( self ) && IsDefined( object.trigger ) && self isTouching( object.trigger ) && !level.gameEnded && object.useTime )
	{
		if ( IsPlayer(self) )
		{
			self updateUIProgress( object, true );
			self updateProxBar( object, false );
		}
		wait ( 0.05 );
	}

	// disconnected player will skip this code
	if ( IsDefined( self ) )
	{
		if ( IsPlayer(self) )
		{
			self updateUIProgress( object, false );
			self updateProxBar( object, true );
		}
		self.touchTriggers[object.entNum] = undefined;
	}
	
	if ( level.gameEnded )
		return;
	
	object.touchList[team][touchName] = undefined;

	object.numTouching[team]--;
	object updateUseRate();
}


/*
=============
updateProxBar ("proximity" only)

Updates drawing of the players use bar when using a use object
to disable set noUseBar on object
=============
*/
updateProxBar( object, forceRemove ) // self == player
{
	self_pers_team = self.pers["team"];
	if ( forceRemove || !object canInteractWith( self_pers_team ) || self_pers_team != object.claimTeam || object.noUseBar )
	{
		if ( IsDefined( self.proxBar ) )
			self.proxBar hideElem();

		if ( IsDefined( self.proxBarText ) )
			self.proxBarText hideElem();
		return;
	}
	
	if ( !IsDefined( self.proxBar ) )
	{
		self.proxBar = createPrimaryProgressBar();
		self.proxBar.lastUseRate = -1;
		self.proxBar.lastHostMigrationState = false;
	}
	
	if ( self.proxBar.hidden )
	{
		self.proxBar showElem();
		self.proxBar.lastUseRate = -1;
		self.proxBar.lastHostMigrationState = false;
	}

	if ( !IsDefined( self.proxBarText ) )
	{
		self.proxBarText = createPrimaryProgressBarText();
		
		relativeTeam = object getRelativeTeam( self_pers_team );
		
		if ( IsDefined( object.teamUseTexts[relativeTeam] ) )
			self.proxBarText setText( object.teamUseTexts[relativeTeam] );
		else
			self.proxBarText setText( object.useText );
	}
	
	if ( self.proxBarText.hidden )
	{
		self.proxBarText showElem();

		relativeTeam = object getRelativeTeam( self_pers_team );
		
		if ( IsDefined( object.teamUseTexts[relativeTeam] ) )
			self.proxBarText setText( object.teamUseTexts[relativeTeam] );
		else
			self.proxBarText setText( object.useText );
	}
		
	if ( self.proxBar.lastUseRate != object.useRate || self.proxBar.lastHostMigrationState != IsDefined( level.hostMigrationTimer ) )
	{
		if( object.curProgress > object.useTime)
			object.curProgress = object.useTime;
		
		progress = object.curProgress / object.useTime;
		rate = (1000 / object.useTime) * object.useRate;
		if ( IsDefined( level.hostMigrationTimer ) )
			rate = 0;
		
		self.proxBar updateBar( progress, rate );
		
		self.proxBar.lastUseRate = object.useRate;
		
		self.proxBar.lastHostMigrationState = IsDefined( level.hostMigrationTimer );
	}
}

migrationCaptureReset( player )
{
	player.migrationCaptureReset = true;
	
	level waittill( "host_migration_begin" );
	
	if ( !isDefined ( player ) || !isDefined( self ) )
		return;
	
	player SetClientOmnvar( "ui_securing", 0 );
	player SetClientOmnvar( "ui_securing_progress", 0 );
	self.migrationCaptureReset = undefined;
}

/*
=============
updateUIProgress

Updates drawing of the players use bar when using a use object.
This is instead of the updateProxBar() hud elem, this is for the lua script.
=============
*/
updateUIProgress( object, securing ) // self == player
{
	if( !IsDefined( level.hostMigrationTimer ) )
	{
		if( object.curProgress > object.useTime )
			object.curProgress = object.useTime;

		progress = object.curProgress / object.useTime;

		if( hasDomFlags() && IsDefined( object.id ) && object.id == "domFlag" )
		{
			domFlagIdx = 0;
			if( object.label == "_a" )
				domFlagIdx = 1;
			else if( object.label == "_b" )
				domFlagIdx = 2;
			else if( object.label == "_c" )
				domFlagIdx = 3;
					
			// if we are on the point while an enemy is on the point, then don't show the progress yet
			if( securing && IsDefined( object.staleMate ) && object.staleMate )
			{
				if( !IsDefined( self.ui_dom_stalemate ) )
				{
					if( !IsDefined( self.ui_dom_securing ) )
					{
						self SetClientOmnvar( "ui_dom_securing", domFlagIdx );
						self.ui_dom_securing = true;
					}
					
					self SetClientOmnvar( "ui_dom_stalemate", 1 );
					self.ui_dom_stalemate = true;
				}
				progress = 0.01;
			}
			else
			{
				// this will clear the ui if you jump onto a contested point and leave
				if( !securing && IsDefined( self.ui_dom_stalemate ) )
				{
					self SetClientOmnvar( "ui_dom_securing", 0 );
					self.ui_dom_securing = undefined;
				}
				
				// this fixes a bug where the owner of the flag can get the ui stuck on screen
				//	this would happen if an enemy starts to cap, then the owner contests and the enemy leaves
				if( securing && !IsDefined( self.ui_dom_stalemate ) && object.ownerteam == self.team )
				{
					self SetClientOmnvar( "ui_dom_securing", 0 );
					self.ui_dom_securing = undefined;
				}
					
				// this will fix a bug where anyone who starts to cap after a teammate is already capping, then the ui won't show for them
				//	the issue was that we were doing this onBeginUse and that only happens for the first player to start capping
				if( securing && !IsDefined( self.ui_dom_securing ) && object.ownerteam != self.team )
				{
					self SetClientOmnvar( "ui_dom_securing", domFlagIdx );
					self.ui_dom_securing = true;
				}
				
				self SetClientOmnvar( "ui_dom_stalemate", 0 );
				self.ui_dom_stalemate = undefined;
			}

			// if we aren't securing then make sure to set the client dvar so we don't get artifacts if we re-enter the trigger
			if( !securing )
			{
				progress = 0.01;			
				// this will make sure that anyone that started capping and leaves the area will not have ui stuck on their screen
				self SetClientOmnvar( "ui_dom_securing", 0 );
				self.ui_dom_securing = undefined;
			}

			// HACK: FLT_MIN in code won't let you set a float to 0
			if( progress != 0 )
				self SetClientOmnvar( "ui_dom_progress", progress );
		}
		else if( ( level.gameType == "sd" || level.gameType == "sr" ) && 
			    IsDefined( object.id ) && ( object.id == "bomb_zone" || object.id == "defuse_object" ) )
		{
			if( securing )
			{			
				if( !IsDefined( self.ui_bomb_planting_defusing ) )
				{
					idx = 0;
					if( object.id == "bomb_zone" )
						idx = 1;
					else if( object.id == "defuse_object" )
						idx = 2;
					
					self SetClientOmnvar( "ui_bomb_planting_defusing", idx );
					self.ui_bomb_planting_defusing = true;
				}
			}
			else
			{
				self SetClientOmnvar( "ui_bomb_planting_defusing", 0 );
				self.ui_bomb_planting_defusing = undefined;
				progress = 0.01;
			}

			// HACK: FLT_MIN in code won't let you set a float to 0
			if( progress != 0 )
				self SetClientOmnvar( "ui_planting_defusing_progress", progress );
		}
		else if( IsDefined( object.id ) )
		{
			// doing the checks to keep things from overlapping
			// 1 = care package
			// 2 = intel
			// 3 = deployable vest
			// 4 = deployable weapon crate
			// 5 = last stand (reviving)
			// 6 = last stand (being revived)
			// 7 = breach
			idx = 0;
			switch( object.id )
			{
				case "care_package":
					idx = 1;
					break;
				case "intel":
					idx = 2;
					break;
				case "deployable_vest":
					idx = 3;
					break;
				case "deployable_weapon_crate":
					idx = 4;
					break;
				case "last_stand":
					idx = 5;
					if( IsDefined( self.inLastStand ) && self.inLastStand )
						idx = 6;
					break;
				case "breach":
					idx = 7;
					break;
				case "use":
					idx = 8;
					break;
			}
			updateUISecuring( progress, securing, idx, object );
		}
	}
}

hasDomFlags()
{
	if ( level.gametype == "dom" || level.gameType == "siege" )
		return true;
	
	return false;
}

updateUISecuring( progress, securing, idx, object ) // self == player
{
	if( securing )
	{	
		if ( !isDefined( object.usedBy ) )
			object.usedBy = [];
		
		if( !isDefined( self.migrationCaptureReset ) )
		{
			object thread migrationCaptureReset( self );
		}
		
		// Add this player to the list of people currently using this object
		if ( !existInArray( self, object.usedBy ) )
			object.usedBy[object.usedBy.size] = self;
		
		if( !IsDefined( self.ui_securing ) )
		{
			self SetClientOmnvar( "ui_securing", idx );
			self.ui_securing = true;
		}
	}
	else
	{
		// Remove the player from the array
		if ( isDefined(object.usedBy) && existInArray( self, object.usedBy ) )
			object.usedBy = array_remove( object.usedBy, self );
		
		self SetClientOmnvar( "ui_securing", 0 );
		self.ui_securing = undefined;
		progress = 0.01;
	}

	// HACK: FLT_MIN in code won't let you set a float to 0
	if( progress != 0 )
		self SetClientOmnvar( "ui_securing_progress", progress );	
}

existInArray( ent, array )
{
	// Check to see if this player is already using this object
	if ( array.size > 0 )
	{
		foreach(entity in array)
		{
			if ( entity == ent )
				return true;	
		}
	}

	return false;
}

/*
=============
updateUseRate ("proximity" only)

Handles the rate a which a use objects progress bar is filled based on the number of players touching the trigger
Stops updating if an enemy is touching the trigger
=============
*/
updateUseRate( )
{
	numClaimants = self.numTouching[self.claimTeam];
	numOther = 0;
	hasObjScale = 0;
	
	if( level.multiTeamBased )
	{
		foreach( teamName in level.teamNameList )
		{
			if( self.claimTeam != teamName )
			{
				numOther += self.numTouching[teamName];
			}
		}
	}
	else
	{
		if ( self.claimTeam != "axis" )
			numOther += self.numTouching["axis"];
		if ( self.claimTeam != "allies" )
			numOther += self.numTouching["allies"];
	}

	foreach (struct in self.touchList[self.claimteam])
	{
		if ( !IsDefined(struct.player) )	// struct.player could have disconnected, and this code can run before he gets removed from the touchList
			continue;
		
		if (struct.player.pers["team"] != self.claimteam)
			continue;
		
		if (struct.player.objectiveScaler == 1)
			continue;
		
		numClaimants *= struct.player.objectiveScaler;
		hasObjScale = struct.player.objectiveScaler;
	}
	
	self.useRate = 0;
	self.staleMate = numClaimants && numOther;

	if ( numClaimants && !numOther )
		self.useRate = min( numClaimants, 4 );
		
	if ( IsDefined( self.isArena ) && self.isArena && hasObjScale != 0 )
		self.useRate = 1 * hasObjScale;
	else if ( IsDefined( self.isArena ) && self.isArena )
		self.useRate = 1; 
}


/*
=============
useHoldThink

Claims the use trigger for player and displays a use bar
Returns true if the player sucessfully fills the use bar
=============
*/
useHoldThink( player )
{
	player notify ( "use_hold" );
	if ( IsPlayer(player) )
		player playerLinkTo( self.trigger );
	else
		player LinkTo( self.trigger );
	
	player PlayerLinkedOffsetEnable();
	player clientClaimTrigger( self.trigger );
	player.claimTrigger = self.trigger;

	useWeapon = self.useWeapon;
	lastWeapon = player getCurrentWeapon();
	
	if ( IsDefined( useWeapon ) )
	{
		assert( IsDefined( lastWeapon ) );
		if ( lastWeapon == useWeapon )
		{
			assert( isdefined( player.lastNonUseWeapon ) );
			lastWeapon = player.lastNonUseWeapon;
		}
		assert( lastWeapon != useWeapon );
		
		player.lastNonUseWeapon = lastWeapon;
		
		player _giveWeapon( useWeapon );
		player setWeaponAmmoStock( useWeapon, 0 );
		player setWeaponAmmoClip( useWeapon, 0 );
		player switchToWeapon( useWeapon );
	}
	else
	{
		player _disableWeapon();
	}
	
	self.curProgress = 0;
	self.inUse = true;
	self.useRate = 0;
	
	result = useHoldThinkLoop( player, lastWeapon );
	
	if ( IsDefined( player ) )
	{
		player detachUseModels();
		player notify( "done_using" );
	}
	
	// result may be undefined if useholdthinkloop hits an endon

	if ( IsDefined( useWeapon ) && IsDefined( player ) )
		player thread takeUseWeapon( useWeapon );
	
	if ( IsDefined( result ) && result )
		return true;
	
	if ( IsDefined( player ) )
	{
		player.claimTrigger = undefined;
		if ( IsDefined( useWeapon ) )
		{
			if ( lastWeapon != "none" )
				player switch_to_last_weapon( lastWeapon );
			else
				player takeWeapon( useWeapon );
	
//			while ( player getCurrentWeapon() == useWeapon && isReallyAlive( player ) )
//				wait ( 0.05 );
		}
		else
		{
			player _enableWeapon();
		}

		player unlink();
		
		if ( !isReallyAlive( player ) )
			player.killedInUse = true;
	}

	self.inUse = false;
	self.trigger releaseClaimedTrigger();
	return false;
}

detachUseModels()
{
	if ( IsDefined( self.attachedUseModel ) )
	{
		self detach( self.attachedUseModel, "tag_inhand" );
		self.attachedUseModel = undefined;
	}
}

takeUseWeapon( useWeapon )
{
	self endon( "use_hold" );
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while ( self getCurrentWeapon() == useWeapon && !IsDefined( self.throwingGrenade ) )
		wait ( 0.05 );
		
	self takeWeapon( useWeapon );
}


usetest( player, waitForWeapon, timedOut, maxWaitTime )
{
	if ( !isReallyAlive( player ) )
		return false;
	
	if ( !player isTouching( self.trigger ) )
		return false;
	
	if ( !player useButtonPressed() )
		return false;
	
	if ( IsDefined( player.throwingGrenade ) )
		return false;
	
	if ( player meleeButtonPressed() )
		return false;
	
	if ( self.curProgress >= self.useTime )
		return false;
	
	if ( !self.useRate && !waitForWeapon )
		return false;
	
	if ( waitForWeapon && timedOut > maxWaitTime )
		return false;
	
	return true;	
}

useHoldThinkLoop( player, lastWeapon )
{
	level endon ( "game_ended" );
	self endon("disabled");
	
	useWeapon = self.useWeapon;
	
	waitForWeapon = true;
	if ( IsDefined( self.waitForWeaponOnUse ) )
	{
		waitForWeapon = self.waitForWeaponOnUse;	
	}
	
	if ( !waitForWeapon )
	{
		self.useRate = 1 * player.objectiveScaler;
	}
	
	timedOut = 0;
	
	maxWaitTime = 1.5; // must be greater than the putaway timer for all weapons
	
	while( usetest( player, waitForWeapon, timedOut, maxWaitTime ) )//isReallyAlive( player ) && player isTouching( self.trigger ) && player useButtonPressed() && !IsDefined( player.throwingGrenade ) && !player meleeButtonPressed() && self.curProgress < self.useTime && (self.useRate || waitForWeapon) && !(waitForWeapon && timedOut > maxWaitTime) )
	{
		timedOut += 0.05;

		if ( !waitForWeapon || !IsDefined( useWeapon ) || player getCurrentWeapon() == useWeapon )
		{
			self.curProgress += (50 * self.useRate);
			self.useRate = 1 * player.objectiveScaler;
			waitForWeapon = false;
		}
		else
		{
			self.useRate = 0;
		}

		player updateUIProgress( self, true );
		
		if ( self.curProgress >= self.useTime )
		{
			self.inUse = false;
			player clientReleaseTrigger( self.trigger );
			player.claimTrigger = undefined;
			
			if ( IsDefined( useWeapon ) )
			{
				player setWeaponAmmoStock( useWeapon, 1 );
				player setWeaponAmmoClip( useWeapon, 1 );
				if ( lastWeapon != "none" )
					player switch_to_last_weapon( lastWeapon );
				else
					player takeWeapon( useWeapon );
			}
			else
			{
				player _enableWeapon();
			}
			player unlink();
			
			return isReallyAlive( player );
		}
		
		wait 0.05;
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	}
	
	player updateUIProgress( self, false );
	return false;
}

/*
=============
updateTrigger

Displays and updates a players use bar
=============
*/
updateTrigger()
{
	if ( self.triggerType != "use" )
		return;
	
	if ( self.interactTeam == "none" )
	{
		self.trigger.origin -= (0,0,50000);
	}	
	else if ( self.interactTeam == "any" )
	{
		self.trigger.origin = self.curOrigin;
		self.trigger setTeamForTrigger( "none" );
	}
	else if ( self.interactTeam == "friendly" )
	{
		self.trigger.origin = self.curOrigin;
		if ( self.ownerTeam == "allies" )
			self.trigger setTeamForTrigger( "allies" );
		else if ( self.ownerTeam == "axis" )
			self.trigger setTeamForTrigger( "axis" );
		else
			self.trigger.origin -= (0,0,50000);
	}
	else if ( self.interactTeam == "enemy" )
	{
		self.trigger.origin = self.curOrigin;
		if ( self.ownerTeam == "allies" )
			self.trigger setTeamForTrigger( "axis" );
		else if ( self.ownerTeam == "axis" )
			self.trigger setTeamForTrigger( "allies" );
		else
			self.trigger setTeamForTrigger( "none" );
	}
}


updateWorldIcons()
{
	if ( self.visibleTeam == "any" )
	{
		updateWorldIcon( "friendly", true );
		updateWorldIcon( "enemy", true );
	}
	else if ( self.visibleTeam == "friendly" )
	{
		updateWorldIcon( "friendly", true );
		updateWorldIcon( "enemy", false );
	}
	else if ( self.visibleTeam == "enemy" )
	{
		updateWorldIcon( "friendly", false );
		updateWorldIcon( "enemy", true );
	}
	else
	{
		updateWorldIcon( "friendly", false );
		updateWorldIcon( "enemy", false );
	}
}


updateWorldIcon( relativeTeam, showIcon )
{
	if ( !IsDefined( self.worldIcons[relativeTeam] ) )
		showIcon = false;
	
	updateTeams = getUpdateTeams( relativeTeam );
	
	for ( index = 0; index < updateTeams.size; index++ )
	{
		opName = "objpoint_" + updateTeams[index] + "_" + self.entNum;			
		objPoint = maps\mp\gametypes\_objpoints::getObjPointByName( opName );
		
		objPoint notify( "stop_flashing_thread" );
		objPoint thread maps\mp\gametypes\_objpoints::stopFlashing();
		
		if ( showIcon )
		{
			objPoint setShader( self.worldIcons[relativeTeam], level.objPointSize, level.objPointSize );
			objPoint fadeOverTime( 0.05 ); // overrides old fadeOverTime setting from flashing thread
			objPoint.alpha = objPoint.baseAlpha;
			objPoint.isShown = true;

			if ( IsDefined( self.compassIcons[relativeTeam] ) )
				objPoint setWayPoint( true, true );
			else
				objPoint setWayPoint( true, false );
				
			if ( self.type == "carryObject" )
			{
				if ( IsDefined( self.carrier ) && !shouldPingObject( relativeTeam ) )
					objPoint SetTargetEnt( self.carrier );
				else
					objPoint ClearTargetEnt();
			}
			else if ( IsDefined( self.objIconEnt ) )
			{
				objPoint SetTargetEnt( self.objIconEnt );
			}
		}
		else
		{
			objPoint fadeOverTime( 0.05 );
			objPoint.alpha = 0;
			objPoint.isShown = false;
			objPoint ClearTargetEnt();
		}
		
		objPoint thread hideWorldIconOnGameEnd();
	}
}


hideWorldIconOnGameEnd()
{
	self notify( "hideWorldIconOnGameEnd" );
	self endon( "hideWorldIconOnGameEnd" );
	self endon( "death" );
	
	level waittill("game_ended");
	
	if ( IsDefined( self ) )
		self.alpha = 0;	
}


updateTimer( seconds, showIcon )
{

}


updateCompassIcons()
{
	if ( self.visibleTeam == "any" )
	{
		updateCompassIcon( "friendly", true );
		updateCompassIcon( "enemy", true );
	}
	else if ( self.visibleTeam == "friendly" )
	{
		updateCompassIcon( "friendly", true );
		updateCompassIcon( "enemy", false );
	}
	else if ( self.visibleTeam == "enemy" )
	{
		updateCompassIcon( "friendly", false );
		updateCompassIcon( "enemy", true );
	}
	else
	{
		updateCompassIcon( "friendly", false );
		updateCompassIcon( "enemy", false );
	}
}


updateCompassIcon( relativeTeam, showIcon )
{
	updateTeams = getUpdateTeams( relativeTeam );
	
	for ( index = 0; index < updateTeams.size; index++ )
	{
		teamToUpdate = updateTeams[ index ];
		
		showIconThisTeam = showIcon;
		if ( !showIconThisTeam && shouldShowCompassDueToRadar( teamToUpdate ) )
			showIconThisTeam = true;

		objId = self.teamObjIds[teamToUpdate];
		
		if ( !IsDefined( self.compassIcons[relativeTeam] ) || !showIconThisTeam )
		{
			objective_state( objId, "invisible" );
			continue;
		}
		
		objective_icon( objId, self.compassIcons[relativeTeam] );
		objective_state( objId, "active" );
		
		if ( self.type == "carryObject" )
		{
			if ( isReallyAlive( self.carrier ) && !shouldPingObject( relativeTeam ) )
				Objective_OnEntity( objId, self.carrier );
			// 2013-12-02 wallace: handle cases where bomb is dropped on a moving platform
			else if ( IsDefined( self.visuals[0] ) && IsDefined( self.visuals[0] GetLinkedParent() ) )
				Objective_OnEntity( objId, self.visuals[0] );
			else
				objective_position( objId, self.curOrigin );
		}
		else if ( IsDefined( self.objIconEnt ) )
		{
			Objective_OnEntity( objId, self.objIconEnt );
		}
	}
}


shouldPingObject( relativeTeam )
{
	if ( relativeTeam == "friendly" && self.objIDPingFriendly )
		return true;
	else if ( relativeTeam == "enemy" && self.objIDPingEnemy )
		return true;
	
	return false;
}

getUpdateTeams( relativeTeam )
{
	updateTeams = [];

	foreach( teamname in level.teamnamelist )
	{
		if ( relativeTeam == "friendly" )
		{
			if ( self isFriendlyTeam( teamname ) )
				updateTeams[updateTeams.size] = teamname;
		}
		else if ( relativeTeam == "enemy" )
		{
			if ( !self isFriendlyTeam( teamname ) )
				updateTeams[updateTeams.size] = teamname;
		}	
	}

	return updateTeams;
}

shouldShowCompassDueToRadar( team )
{
	// the only case we return true in this function is when the enemy has UAV,
	// and an enemy visible on UAV is holding the object.
	
	if ( !isdefined( self.carrier ) )
		return false;
	
	if ( self.carrier _hasPerk( "specialty_gpsjammer" ) )
		return false;
	
	return getTeamRadar( team );
}

updateVisibilityAccordingToRadar()
{
	self endon("death");
	self endon("carrier_cleared");
	
	while(1)
	{
		level waittill("radar_status_change");
		self updateCompassIcons();
	}
}

setOwnerTeam( team )
{
	self.ownerTeam = team;
	self updateTrigger();	
	self updateCompassIcons();
	self updateWorldIcons();
	
	if( team != "neutral" )
		self.prevOwnerTeam = team;
}

getOwnerTeam()
{
	return self.ownerTeam;
}

setUseTime( time )
{
	
	self.useTime = int (time * 1000 );
}

// JC-01/13/14 - Allow use ents to not wait for the weapon switch to occur. This makes it so
// the defuse / plant time matches the time set in game rules. Changed spurred by MLG request.
// JC-ToDo: Next project look at doing this for all use objects, not just sd/sr
setWaitWeaponChangeOnUse( bool )
{
	self.waitForWeaponOnUse = bool;
}

setUseText( text )
{
	self.useText = text;
}

setTeamUseTime( relativeTeam, time )
{
	self.teamUseTimes[relativeTeam] = int( time * 1000 );
}

setTeamUseText( relativeTeam, text )
{
	self.teamUseTexts[relativeTeam] = text;
}

setUseHintText( text )
{
	self.trigger setHintString( text );
}

allowCarry( relativeTeam )
{
	self.interactTeam = relativeTeam;
}

allowUse( relativeTeam )
{
	self.interactTeam = relativeTeam;
	updateTrigger();
}

setVisibleTeam( relativeTeam )
{
	self.visibleTeam = relativeTeam;

	updateCompassIcons();
	updateWorldIcons();
}

setModelVisibility( visibility )
{
	if ( visibility )
	{
		for ( index = 0; index < self.visuals.size; index++ )
		{
			self.visuals[index] show();
			if ( self.visuals[index].classname == "script_brushmodel" || self.visuals[index].classname == "script_model" )
			{
				foreach ( player in level.players )
				{
					if ( player isTouching( self.visuals[index] ) )
						player _suicide();
				}
				self.visuals[index] thread makeSolid();
			}
		}
	}
	else
	{
		for ( index = 0; index < self.visuals.size; index++ )
		{
			self.visuals[index] hide();
			if ( self.visuals[index].classname == "script_brushmodel" || self.visuals[index].classname == "script_model" )
			{
				self.visuals[index] notify("changing_solidness");
				self.visuals[index] notsolid();
			}
		}
	}
}

makeSolid()
{
	self endon("death");
	self notify("changing_solidness");
	self endon("changing_solidness");
	
	while(1)
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			if ( level.players[i] isTouching( self ) )
				break;
		}
		if ( i == level.players.size )
		{
			self solid();
			break;
		}
		wait .05;
	}
}

setCarrierVisible( relativeTeam )
{
	self.carrierVisible = relativeTeam;
}

setCanUse( relativeTeam )
{
	self.useTeam = relativeTeam;
}

set2DIcon( relativeTeam, shader )
{
	self.compassIcons[relativeTeam] = shader;
	updateCompassIcons();
}

set3DIcon( relativeTeam, shader )
{
	self.worldIcons[relativeTeam] = shader;
	updateWorldIcons();
}

set3DUseIcon( relativeTeam, shader )
{
	self.worldUseIcons[relativeTeam] = shader;	
}

setCarryIcon( shader )
{
	self.carryIcon = shader;
}

disableObject()
{
	self notify("disabled");
	
	if ( self.type == "carryObject" )
	{
		if ( IsDefined( self.carrier ) )
			self.carrier takeObject( self );

		for ( index = 0; index < self.visuals.size; index++ )
		{
			self.visuals[index] hide();
		}
	}
	
	self.trigger common_scripts\utility::trigger_off();
	self setVisibleTeam( "none" );
}


enableObject()
{
	if ( self.type == "carryObject" )
	{
		for ( index = 0; index < self.visuals.size; index++ )
		{
			self.visuals[index] show();
		}
	}
	
	self.trigger common_scripts\utility::trigger_on();
	self setVisibleTeam( "any" );
}


getRelativeTeam( team )
{
	if ( team == self.ownerTeam )
		return "friendly";
	else
		return "enemy";
	//else
	//	return "neutral";
}


isFriendlyTeam( team )
{
	if ( self.ownerTeam == "any" )
		return true;
	
	if ( self.ownerTeam == team )
		return true;

	// this check is for dom, since we neutralize the point after it has been capped, this will make sure the icons stay correct for the team that was friendly to it
	if( self.ownerTeam == "neutral" && IsDefined( self.prevOwnerTeam ) && self.prevOwnerTeam == team )
		return true;

	return false;
}


canInteractWith( team, player )
{	
	switch( self.interactTeam )
	{
		case "none":
			return false;

		case "any":
			return true;

		case "friendly":
			if ( team == self.ownerTeam )
				return true;
			else
				return false;

		case "enemy":
			if ( team != self.ownerTeam )
				return true;
			else
				return false;

		default:
			assertEx( 0, "invalid interactTeam" );
			return false;
	}
}


isTeam( team )
{
	if ( team == "neutral" )
		return true;
	if ( team == "allies" )
		return true;
	if ( team == "axis" )
		return true;
	if ( team == "any" )
		return true;
	if ( team == "none" )
		return true;

	foreach( teamname in level.teamnamelist )
	{
		if( team == teamname )
		{
			return true;
		}
	}
	
	return false;
}

isRelativeTeam( relativeTeam )
{
	if ( relativeTeam == "friendly" )
		return true;
	if ( relativeTeam == "enemy" )
		return true;
	if ( relativeTeam == "any" )
		return true;
	if ( relativeTeam == "none" )
		return true;
	
	return false;
}


getEnemyTeam( team )
{
	if( level.multiteambased )
	{
		assert( "getEnemyTeam should not be called in multiteam settings" );
	}
	
	if ( team == "neutral" )
		return "none";
	else if ( team == "allies" )
		return "axis";
	else
		return "allies";
}

getNextObjID()
{
	if ( !IsDefined( level.reclaimedReservedObjectives ) || level.reclaimedReservedObjectives.size < 1 )
	{
		nextID = level.numGametypeReservedObjectives;
		level.numGametypeReservedObjectives++;
	}
	else 
	{
		nextId = level.reclaimedReservedObjectives[level.reclaimedReservedObjectives.size - 1];
		level.reclaimedReservedObjectives[level.reclaimedReservedObjectives.size - 1] = undefined;
	}
	
	if ( nextId > 31 )
		nextId = 31;
	
	return nextID;
}

getLabel()
{
	label = self.trigger.script_label;
	if ( !IsDefined( label ) )
	{
		label = "";
		return label;
	}
	
	if ( label[0] != "_" )
		return ("_" + label);
	
	return label;
}

initializeTagPathVariables()
{
	self.nearest_node = undefined;
	self.calculated_nearest_node = false;
	self.on_path_grid = undefined;
}
