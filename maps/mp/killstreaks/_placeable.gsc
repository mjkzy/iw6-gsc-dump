#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

init()
{
	if ( !IsDefined( level.placeableConfigs ) )
	{
		level.placeableConfigs = [];
	}
}

givePlaceable( streakName ) // self == player
{
	placeable = self createPlaceable( streakName );
	
	//	returning from this streak activation seems to strip this?
	//	manually removing and restoring
	self removePerks();
	
	self.carriedItem = placeable;
	
	result = self onBeginCarrying( streakName, placeable, true );
	
	self.carriedItem = undefined;
	
	self restorePerks();

	// if the placeable exist, then it was placed
	return ( IsDefined( placeable ) );
}

createPlaceable( streakName )
{
	if( IsDefined( self.isCarrying ) && self.isCarrying )
		return;
	
	config = level.placeableConfigs[ streakName ];
	
	obj = Spawn( "script_model", self.origin );
	obj SetModel( config.modelBase );
	obj.angles = self.angles;
	obj.owner = self;
	obj.team = self.team;
	obj.config = config;
	obj.firstPlacement = true;

	/*
	obj = SpawnTurret( "misc_turret", self.origin + ( 0, 0, 25 ), "sentry_minigun_mp" );

	obj.angles = self.angles;
	obj.owner = self;

	obj SetModel( config.modelBase );

	obj MakeTurretInoperable();
	obj SetTurretModeChangeWait( true );
	obj SetMode( "sentry_offline" );
	obj MakeUnusable();
	obj SetSentryOwner( self );
	*/
	
	// inits happen here
	if ( IsDefined( config.onCreateDelegate ) )
	{
		obj [[ config.onCreateDelegate ]]( streakName );
	}
	
	obj deactivate( streakName );
	
	obj thread timeOut( streakName );
	obj thread handleUse( streakName );
	
	obj thread onKillstreakDisowned( streakName );
	obj thread onGameEnded( streakName );
	
	obj thread createBombSquadModel( streakName );

	return obj;	
}


handleUse( streakName ) // self == placeable
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	while ( true )
	{
		self waittill ( "trigger", player );
		
		assert( player == self.owner );
		assert( !IsDefined( self.carriedBy ) );

		if ( !isReallyAlive( player ) )
			continue;
		
		if ( IsDefined( self GetLinkedParent() ) )
		{
			self Unlink();
		}
		
		// why does the IMS create a second one?
		
		player onBeginCarrying( streakName, self, false );
	}
}

// setCarrying
onBeginCarrying( streakName, placeable, allowCancel )	// self == player
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	assert( isReallyAlive( self ) );
	
	placeable thread onCarried( streakName, self );
	
	self _disableWeapon();

	if ( !IsAI(self) )		// Bots handle these internally
	{
		self notifyOnPlayerCommand( "placePlaceable", "+attack" );
		self notifyOnPlayerCommand( "placePlaceable", "+attack_akimbo_accessible" ); // support accessibility control scheme
		self notifyOnPlayerCommand( "cancelPlaceable", "+actionslot 4" );
		if( !level.console )
		{
			self notifyOnPlayerCommand( "cancelPlaceable", "+actionslot 5" );
			self notifyOnPlayerCommand( "cancelPlaceable", "+actionslot 6" );
			self notifyOnPlayerCommand( "cancelPlaceable", "+actionslot 7" );
		}
	}
	
	while (true)
	{
		result = waittill_any_return( "placePlaceable", "cancelPlaceable", "force_cancel_placement" );

		// object was deleted
		if ( !IsDefined( placeable ) )
		{
			self _enableWeapon();
			return true;
		}
		// !!! 2013-08-08 wallace: this force cancel problem is really ugly
		// it's also being used to indicate player wading in water, which we should use the "bad placement" model instead of canceling outright. But it's too late to fix now.
		else if ( (result == "cancelPlaceable" && allowCancel)
			  || result == "force_cancel_placement" )
		{
			placeable onCancel( streakName, result == "force_cancel_placement" && !IsDefined( placeable.firstPlacement ) );
			return false;
		}
		else if ( placeable.canBePlaced )
		{
			placeable thread onPlaced( streakName );
			self _enableWeapon();
			return true;
		}
	}
}

onCancel( streakName, playDestroyVfx )	// self == placeable
{
	if( IsDefined( self.carriedBy ) )
	{
		owner = self.carriedBy;
		owner ForceUseHintOff();
		owner.isCarrying = undefined;
		
		owner.carriedItem = undefined;
	
		owner _enableWeapon();
	}
	
	if( IsDefined( self.bombSquadModel ) )
	{
		self.bombSquadModel Delete();
	}
	
	if ( IsDefined( self.carriedObj ) )
	{
		self.carriedObj Delete();
	}
	
	config = level.placeableConfigs[ streakName ];
	if ( IsDefined( config.onCancelDelegate ) )
	{
		self [[ config.onCancelDelegate ]]( streakName );
	}

	if ( IsDefined( playDestroyVfx ) && playDestroyVfx )
	{
		self maps\mp\gametypes\_weapons::equipmentDeleteVfx();
	}
	
	self Delete();
}

onPlaced( streakName )	// self == placeable
{
	config = level.placeableConfigs[ streakName ];
	
	self.origin = self.placementOrigin;
	self.angles = self.carriedObj.angles;
	
	self PlaySound( config.placedSfx );
	
	self showPlacedModel( streakName );
	
	if ( IsDefined( config.onPlacedDelegate ) )
	{
		self [[ config.onPlacedDelegate ]]( streakName );
	}
	
	self setCursorHint( "HINT_NOICON" );
	self setHintString( config.hintString );

	owner = self.owner;
	owner ForceUseHintOff();
	owner.isCarrying = undefined;
	self.carriedBy = undefined;
	self.isPlaced = true;
	self.firstPlacement = undefined;

	if ( IsDefined( config.headIconHeight ) )
	{
		if ( level.teamBased )
		{
			self maps\mp\_entityheadicons::setTeamHeadIcon( self.team, (0,0,config.headIconHeight) );
		}
		else
		{
			self maps\mp\_entityheadicons::setPlayerHeadIcon( owner, (0,0,config.headIconHeight) );
		}
	}
	
	self thread handleDamage( streakName );
	self thread handleDeath( streakName );

	self MakeUsable();
	
	self make_entity_sentient_mp( self.owner.team );
	if ( IsSentient( self ) )
	{
		self SetThreatBiasGroup( "DogsDontAttack" );
	}

	foreach ( player in level.players )
	{
		if( player == owner )
			self EnablePlayerUse( player );
		else
			self DisablePlayerUse( player );
	}

	if( IsDefined( self.shouldSplash ) )
	{
		level thread teamPlayerCardSplash( config.splashName, owner );
		self.shouldSplash = false;
	}
	
	// Moving platforms. 
	data = SpawnStruct();
	data.linkParent = self.moving_platform;
	data.playDeathFx = true;
	data.endonString = "carried";
	if ( IsDefined( config.onMovingPlatformCollision ) )
	{
		data.deathOverrideCallback = config.onMovingPlatformCollision;
	}
	self thread maps\mp\_movers::handle_moving_platforms( data );
	
	self thread watchPlayerConnected();
	
	self notify ( "placed" );
	
	self.carriedObj Delete();
	self.carriedObj = undefined;
}

onCarried( streakName, carrier )	// self == placeable
{
	config = level.placeableConfigs[ streakName ];
	
	assert( isPlayer( carrier ) );
	assertEx( carrier == self.owner, "_placeable::onCarried: specified carrier does not own this ims" );
	
	self.carriedObj = carrier createCarriedObject( streakName );
	
	// self SetModel( config.modelPlacement );

	self.isPlaced = undefined;
	self.carriedBy = carrier;
	carrier.isCarrying = true;
	
	self deactivate( streakName );
	
	self hidePlacedModel( streakName );
	
	if ( IsDefined( config.onCarriedDelegate ) )
	{
		self [[ config.onCarriedDelegate ]]( streakName );
	}
	
	self thread updatePlacement( streakName, carrier );
	
	self thread onCarrierDeath( streakName, carrier );
	
	self notify ( "carried" );
}

updatePlacement( streakName, carrier )	// self == placeable
{
	carrier endon ( "death" );
	carrier endon ( "disconnect" );
	level endon ( "game_ended" );
	
	self endon ( "placed" );
	self endon ( "death" );
	
	self.canBePlaced = true;
	prevCanBePlaced = -1; // force initial update
	
	config = level.placeableConfigs[ streakName ];
	
	// allow the visuals be raised up slightly (e.g. iw6 Sat Com, so that player can see it)
	placementOffset = (0 ,0, 0);
	if ( IsDefined( config.placementOffsetZ ) )
	{
		placementOffset = (0 ,0 ,config.placementOffsetZ);
	}
	
	carriedObj = self.carriedObj;

	while ( true )
	{
		placement = carrier CanPlayerPlaceSentry( true, config.placementRadius );

		// NOTE TO SELF: Talk to Simon C about how to get vertical offset / additional rotation working with client prediction
		self.placementOrigin = placement[ "origin" ];
		carriedObj.origin = self.placementOrigin + placementOffset;
		carriedObj.angles = placement[ "angles" ];
		
		self.canBePlaced = carrier IsOnGround() 
			&& placement[ "result" ] 
			&& ( abs(self.placementOrigin[2] - carrier.origin[2]) < config.placementHeightTolerance );
		
		if ( isdefined( placement[ "entity" ] ) )
		{
			self.moving_platform = placement[ "entity" ];
		}
		else 
		{
			self.moving_platform = undefined;
		}
	
		if ( self.canBePlaced != prevCanBePlaced )
		{
			if ( self.canBePlaced )
			{
				carriedObj SetModel( config.modelPlacement );
				carrier ForceUseHintOn( config.placeString );
			}
			else
			{
				carriedObj SetModel( config.modelPlacementFailed );
				carrier ForceUseHintOn( config.cannotPlaceString );
			}
		}
		
		prevCanBePlaced = self.canBePlaced;		
		wait ( 0.05 );
	}
}

deactivate( streakName )	// self == placeable
{
	self MakeUnusable();

	self hideHeadIcons();
	
	self FreeEntitySentient();
	
	config = level.placeableConfigs[ streakName ];
	if ( IsDefined( config.onDeactiveDelegate ) )
	{
		self [[ config.onDeactiveDelegate ]]( streakName );
	}
}

hideHeadIcons()
{
	if ( level.teamBased )
	{
		self maps\mp\_entityheadicons::setTeamHeadIcon( "none", ( 0, 0, 0 ) );
	}
	else if ( IsDefined( self.owner ) )
	{
		self maps\mp\_entityheadicons::setPlayerHeadIcon( undefined, ( 0, 0, 0 ) );
	}	
}

// important callbacks:
// onDamagedDelegate - filter out or amplify damage based on specifics
// onDestroyedDelegate - any extra handling when the object is killed
handleDamage( streakName ) // self == placeable
{
	self endon( "carried" );
	
	config = level.placeableConfigs[ streakName ];
	
	self maps\mp\gametypes\_damage::monitorDamage(
		config.maxHealth,
		config.damageFeedback,
		::handleDeathDamage,
		::modifyDamage,
		true	// isKillstreak
	);
}

modifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
	
	config = self.config;
	if ( IsDefined( config.allowMeleeDamage ) && config.allowMeleeDamage )
	{
		modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	}
	
	if ( IsDefined( config.allowEmpDamage ) && config.allowEmpDamage )
	{
		modifiedDamage = self maps\mp\gametypes\_damage::handleEmpDamage( weapon, type, modifiedDamage );
	}
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleGrenadeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	if ( IsDefined( config.modifyDamage ) )
	{
		modifiedDamage = self [[ config.modifyDamage ]]( weapon, type, modifiedDamage );
	}
	
	return modifiedDamage;
}

handleDeathDamage( attacker, weapon, type, damage )
{
	config = self.config;
	
	notifyAttacker = self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, damage, config.xpPopup, config.destroyedVO );
	if ( notifyAttacker
	    && IsDefined( config.onDestroyedDelegate )
	   )
	{
		self [[ config.onDestroyedDelegate ]]( self.streakName, attacker, self.owner, type );
	}
}

handleDeath( streakName )
{
	self endon( "carried" );
	
	self waittill ( "death" );
	
	config = level.placeableConfigs[ streakName ];
	
	// this handles cases of deletion
	if ( IsDefined( self ) )
	{	
		// play sound
		
		self deactivate( streakName );
		
		// set destroyed model
		if ( IsDefined( config.modelDestroyed ) )
		{
			self SetModel( config.modelDestroyed );
		}
		
		// or do it in the callbacks?
		
		if ( IsDefined( config.onDeathDelegate ) )
		{
			self [[ config.onDeathDelegate ]]( streakName );
		}
		
		self Delete();
	}
}

//--------------------------------------------------------------------
onCarrierDeath( streakName, carrier ) // self == placeable
{
	self endon ( "placed" );
	self endon ( "death" );
	carrier endon( "disconnect" );

	carrier waittill ( "death" );
	
	if ( self.canBePlaced )
	{
		self thread onPlaced( streakName );
	}
	else
	{
		self onCancel( streakName );
	}
}


onKillstreakDisowned( streakName ) // self == placeable
{
	self endon ( "death" );
	level endon ( "game_ended" );

	self.owner waittill ( "killstreak_disowned" );
	
	self cleanup( streakName );
}

onGameEnded( streakName ) // self == placeable
{
	self endon ( "death" );

	level waittill ( "game_ended" );
	
	self cleanup( streakName );
}

cleanup( streakName ) 	// self == placeable
{
	if ( IsDefined( self.isPlaced ) )
	{
		self notify( "death" );
	}
	else
	{
		self onCancel( streakName );
	}
}

watchPlayerConnected() // self == ims
{
	self endon( "death" );

	while( true )
	{
		// when new players connect they need to not be able to use the planted ims
		level waittill( "connected", player );
		self thread onPlayerConnected( player );
	}
}

onPlayerConnected( owner ) // self == placeable
{
	self endon( "death" );
	owner endon( "disconnect" );

	owner waittill( "spawned_player" );

	// this can't possibly be the owner because the ims is destroyed if the owner leaves the game, so disable use for this player
	self DisablePlayerUse( owner );
}

timeOut( streakName )
{
	self endon( "death" );
	level endon ( "game_ended" );
	
	config = level.placeableConfigs[ streakName ];
	lifeSpan = config.lifeSpan;
	
	while ( lifeSpan > 0.0 )
	{
		wait ( 1.0 );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		
		if ( !IsDefined( self.carriedBy ) )
		{
			lifeSpan -= 1.0;
		}
	}
	
	if ( IsDefined( self.owner ) && IsDefined( config.goneVO ) )
	{
		self.owner thread leaderDialogOnPlayer( config.goneVO );
	}
	
	self notify ( "death" );
}

//--------------------------------------------------------------------
removeWeapons()
{
	if ( self HasWeapon( "iw6_riotshield_mp" ) )
	{
		self.restoreWeapon = "iw6_riotshield_mp";
		self takeWeapon( "iw6_riotshield_mp" );
	}	
}

removePerks()
{
	if ( self _hasPerk( "specialty_explosivebullets" ) )
	{
		self.restorePerk = "specialty_explosivebullets";
		self _unsetPerk( "specialty_explosivebullets" );
	}		
}

restoreWeapons()
{
	if ( IsDefined( self.restoreWeapon ) )	
	{
		self _giveWeapon( self.restoreWeapon );
		self.restoreWeapon = undefined;
	}	
}

restorePerks()
{
	if ( IsDefined( self.restorePerk ) )
	{
		self givePerk( self.restorePerk, false );	
		self.restorePerk = undefined;
	}	
}

createBombSquadModel( streakName ) // self == box
{
	config = level.placeableConfigs[ streakName ];
	
	if ( IsDefined( config.modelBombSquad ) )
	{
		bombSquadModel = Spawn( "script_model", self.origin );
		bombSquadModel.angles = self.angles;
		bombSquadModel Hide();
	
		bombSquadModel thread maps\mp\gametypes\_weapons::bombSquadVisibilityUpdater( self.owner );
		bombSquadModel SetModel( config.modelBombSquad );
		bombSquadModel LinkTo( self );
		bombSquadModel SetContents( 0 );
		self.bombSquadModel = bombSquadModel;
	
		self waittill ( "death" );
	
		// Could have been deleted when the player was carrying the ims and died
		if ( IsDefined( bombSquadModel ) )
		{
			bombSquadModel delete();
			self.bombSquadModel = undefined;
		}
	}
}

showPlacedModel( streakname )
{
	self Show();
	
	if ( IsDefined( self.bombSquadModel ) )
	{
		self.bombSquadModel Show();
		level notify( "update_bombsquad" );
	}
}

hidePlacedModel( streakName )
{
	self Hide();
	
	if ( IsDefined( self.bombSquadModel ) )
	{
		self.bombSquadModel Hide();
	}
}

createCarriedObject( streakName )
{
	assertEx( IsDefined( self ), "createIMSForPlayer() called without owner specified" );
		
	// need to make sure we aren't already carrying, this fixes a bug where you could start to pull a new one out as you picked the old one up
	//	this resulted in you being able to plant one and then pull your gun out while having another one attached to you like you're carrying it
	if( IsDefined( self.isCarrying ) && self.isCarrying )
		return;
	
	carriedObj = SpawnTurret( "misc_turret", self.origin + ( 0, 0, 25 ), "sentry_minigun_mp" );

	carriedObj.angles = self.angles;
	carriedObj.owner = self;
	
	config = level.placeableConfigs[ streakName ];
	carriedObj SetModel( config.modelBase );

	carriedObj MakeTurretInoperable();
	carriedObj SetTurretModeChangeWait( true );
	carriedObj SetMode( "sentry_offline" );
	carriedObj MakeUnusable();
	carriedObj SetSentryOwner( self );
	carriedObj SetSentryCarrier( self );
	
	carriedObj SetCanDamage( false );
	carriedObj SetContents( 0 );

	return carriedObj;
}