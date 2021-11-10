#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

/*
	I.M.S. (Intelligent Munitions System) killstreaks: the player will be able to place this in the world like a sentry gun, once deployed it'll protect a radius around it
		with a rain of explosives and it'll have more than one shot
*/
KS_ATTACH = "_attach";
CONST_NUM_LID_ON_MODEL = 4;

init()
{
	level.killStreakFuncs[ "ims" ] 	= ::tryUseIMS;
	
	level.imsSettings = [];
	
	config = spawnStruct();
	config.weaponInfo =				"ims_projectile_mp";
	config.modelBase =				"ims_scorpion_body_iw6";
	config.modelPlacement =			"ims_scorpion_body_iw6_placement";
	config.modelPlacementFailed =	"ims_scorpion_body_iw6_placement_failed";
	config.modelDestroyed =			"ims_scorpion_body_iw6";	
	config.modelBombSquad =			"ims_scorpion_body_iw6_bombsquad";	
	config.hintString =				&"KILLSTREAKS_HINTS_IMS_PICKUP_TO_MOVE";	
	config.placeString =			&"KILLSTREAKS_HINTS_IMS_PLACE";	
	config.cannotPlaceString =		&"KILLSTREAKS_HINTS_IMS_CANNOT_PLACE";	
	config.streakName =				"ims";	
	config.splashName =				"used_ims";	
	config.maxHealth				= 1000;
	config.lifeSpan =				90.0;	
	config.rearmTime				= 0.5;
	config.gracePeriod =			0.4; // time once triggered when it'll fire	
	config.numExplosives			= 4;
	config.explosiveModel			= "ims_scorpion_explosive_iw6";
	config.placementHeightTolerance	= 30.0;	// this is a little bigger than the other placed objects due to some slightly steep bumps in mp_snow.
	config.placementRadius			= 24.0;
	
	config.lidTagRoot				= "tag_lid";
	
	// I think anims 1 and 3 are flipped
	// config.lidOpenAnim				= "IMS_Scorpion_door_";
	config.lidOpenAnims				= [];
	config.lidOpenAnims[1]			= "IMS_Scorpion_door_1";
	config.lidOpenAnims[2]			= "IMS_Scorpion_door_2";
	config.lidOpenAnims[3]			= "IMS_Scorpion_door_3";
	config.lidOpenAnims[4]			= "IMS_Scorpion_door_4";
	// use these anims when switching models and we need the doors to already be opened
	config.lidSnapOpenAnims			= [];
	config.lidSnapOpenAnims[1]		= "IMS_Scorpion_1_opened";
	config.lidSnapOpenAnims[2]		= "IMS_Scorpion_2_opened";
	config.lidSnapOpenAnims[3]		= "IMS_Scorpion_3_opened";
	
	config.explTagRoot				= "tag_explosive";
	
	config.killCamOffset			= ( 0, 0, 12 );
	
	level.imsSettings[ "ims" ] = config;
	
	// tag_lid1_attach - joints for animating lids
	// tag_explosive1_attach
	
		// TODO: get fx for this
	level._effect[ "ims_explode_mp" ]		= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_ims_explosion" );
	level._effect[ "ims_smoke_mp" ]			= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_sg_damage_blacksmoke" );
	// level._effect[ "ims_sensor_trail" ]		= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_smoke_geotrail_sblade_main" );
	level._effect[ "ims_sensor_explode" ]	= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_ims_sparks" );
	level._effect[ "ims_antenna_light_mp" ]	= LoadFX( "vfx/gameplay/mp/killstreaks/vfx_light_detonator_blink" );
	
	level.placedIMS = [];

/#
	SetDevDvarIfUninitialized( "scr_ims_timeout", config.lifeSpan );
	SetDevDvarIfUninitialized( "scr_ims_debug_draw", "0" );
#/
}

/* ============================
	Killstreak Functions
   ============================ */

tryUseIMS( lifeId, streakName ) // self == player
{
	// need to get current ims list to compare later
	prevIMSList = [];
	if( IsDefined( self.imsList ) )
		prevIMSList = self.imsList;

	result = self giveIMS( "ims" );

	// result can come back as undefined if the player dies in a place where the ims can't plant, or plants it on death
	// this is different from the autosentry because it uses the same model for trying to place to when it is placed, this doesn't
	if( !IsDefined( result ) )
	{
		result = false;
		// check the current ims list against the previous, if this ims got placed return true so it'll be taken from the player's inventory
		if( IsDefined( self.imsList ) )
		{
			if( !prevIMSList.size && self.imsList.size )
				result = true;
			if( prevIMSList.size && prevIMSList[0] != self.imsList[0] )
				result = true;
		}
	}

	if( result )
	{
		self maps\mp\_matchdata::logKillstreakEvent( level.imsSettings[ "ims" ].streakName, self.origin );
	}
	
	// we're done carrying for sure and sometimes this might not get reset
	// this fixes a bug where you could be carrying and have it in a place where it won't plant, get killed, now you can't scroll through killstreaks
	self.isCarrying = false;

	return ( result );
}

giveIMS( imsType ) // self == player
{
	imsForPlayer = createIMSForPlayer( imsType, self );
	
	//	returning from this streak activation seems to strip this?
	//	manually removing and restoring
	self removePerks();		
	
	self.carriedIMS = imsForPlayer;
	imsForPlayer.firstPlacement = true;
	
	result = self setCarryingIMS( imsForPlayer, true );
	
	self.carriedIMS = undefined;
	
	self thread restorePerks();

	return result;
}


/* ============================
	Player Functions
   ============================ */

setCarryingIMS( imsForPlayer, allowCancel )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	assert( isReallyAlive( self ) );
	
	imsForPlayer thread ims_setCarried( self );
	
	self _disableWeapon();

	if ( !IsAI(self) )		// Bots handle these internally
	{
		self notifyOnPlayerCommand( "place_ims", "+attack" );
		self notifyOnPlayerCommand( "place_ims", "+attack_akimbo_accessible" ); // support accessibility control scheme
		self notifyOnPlayerCommand( "cancel_ims", "+actionslot 4" );
		if( !level.console )
		{
			self notifyOnPlayerCommand( "cancel_ims", "+actionslot 5" );
			self notifyOnPlayerCommand( "cancel_ims", "+actionslot 6" );
			self notifyOnPlayerCommand( "cancel_ims", "+actionslot 7" );
		}
	}
	
	for ( ;; )
	{
		if ( is_aliens() )
			result = waittill_any_return( "place_ims", "cancel_ims", "force_cancel_placement", "player_action_slot_restart" );
		else
			result = waittill_any_return( "place_ims", "cancel_ims", "force_cancel_placement" );

		if ( result == "cancel_ims" || result == "force_cancel_placement" || result ==  "player_action_slot_restart" )
		{
			if ( !allowCancel && result == "cancel_ims" )
				continue;
				
			// pc doesn't need to do this
			// NOTE: this actually might not be needed anymore because we figured out code was taking the weapon because it didn't have any ammo and the weapon was set up as clip only
			if( level.console )
			{
				// failsafe because something takes away the killstreak weapon on occasions where you have them stacked in the gimme slot
				//	for example, if you stack uav, sam turret, emp and then use the emp, then pull out the sam turret, the list item weapon gets taken away before you plant it
				//	so to "fix" this, if the user cancels then we give the weapon back to them only if the selected killstreak is the same and the item list is zero
				//	this is done for anything you can pull out and plant (ims, sentry, sam turret, remote turret, remote tank)
				killstreakWeapon = getKillstreakWeapon( level.imsSettings[ imsForPlayer.imsType ].streakName );
				if( IsDefined( self.killstreakIndexWeapon ) && 
					killstreakWeapon == getKillstreakWeapon( self.pers["killstreaks"][self.killstreakIndexWeapon].streakName ) &&
					!( self GetWeaponsListItems() ).size )
				{
					self _giveWeapon( killstreakWeapon, 0 );
					self _setActionSlot( 4, "weapon", killstreakWeapon );
				}
			}

			imsForPlayer ims_setCancelled( result == "force_cancel_placement" && !IsDefined( imsForPlayer.firstPlacement ) );
			return false;
		}

		if ( !imsForPlayer.canBePlaced )
			continue;
			
		imsForPlayer thread ims_setPlaced();
		self notify( "IMS_placed" );
		self _enableWeapon();		
		return true;
	}
}

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

waitRestorePerks()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	wait( 0.05 );
	self restorePerks();
}

/* ============================
	IMS Functions
   ============================ */

createIMSForPlayer( imsType, owner )
{
	assertEx( IsDefined( owner ), "createIMSForPlayer() called without owner specified" );
		
	// need to make sure we aren't already carrying, this fixes a bug where you could start to pull a new one out as you picked the old one up
	//	this resulted in you being able to plant one and then pull your gun out while having another one attached to you like you're carrying it
	if( IsDefined( owner.isCarrying ) && owner.isCarrying )
		return;

	ims = SpawnTurret( "misc_turret", owner.origin + ( 0, 0, 25 ), "sentry_minigun_mp" );

	ims.angles = owner.angles;
	ims.imsType = imsType;
	ims.owner = owner;
	
	ims SetModel( level.imsSettings[ imsType ].modelBase );

	ims MakeTurretInoperable();
	ims SetTurretModeChangeWait( true );
	ims SetMode( "sentry_offline" );
	ims MakeUnusable();
	ims SetSentryOwner( owner );

	return ims;
}

createIMS( carriedIMS )
{
	owner = carriedIMS.owner;
	imsType = carriedIMS.imsType;

	ims = Spawn( "script_model", carriedIMS.origin );
	ims SetModel( level.imsSettings[ imsType ].modelBase );
	ims.scale = 3;
	ims.angles = carriedIMS.angles;
	ims.imsType = imsType;
	ims.owner = owner;
	ims SetOtherEnt(owner);
	ims.team = owner.team;
	ims.shouldSplash = false;
	ims.hidden = false;
	ims.attacks = 1;	// due to the door anims, we need to count up
	
	ims DisableMissileStick();
	
	ims.hasExplosiveFired = [];
	ims.config = level.imsSettings[ imsType ];
	
	ims thread ims_handleUse();
	ims thread ims_timeOut();
	ims thread ims_createBombSquadModel();
	ims thread ims_onKillstreakDisowned();

	return ims;	
}

ims_createBombSquadModel() // self == ims
{
	bombSquadModel = spawn( "script_model", self.origin );
	bombSquadModel.angles = self.angles;
	bombSquadModel hide();

	bombSquadModel thread maps\mp\gametypes\_weapons::bombSquadVisibilityUpdater( self.owner );
	bombSquadModel SetModel( level.imsSettings[ self.imsType ].modelBombSquad );
	bombSquadModel LinkTo( self );
	bombSquadModel SetContents( 0 );
	self.bombSquadModel = bombSquadModel;

	self waittill ( "death" );

	// Could have been deleted when the player was carrying the ims and died
	if ( IsDefined( bombSquadModel ) )
	{
		bombSquadModel delete();
	}
}

ims_moving_platform_death( data )
{
	self.immediateDeath = true;
	self notify( "death" );
}

/* ============================
	IMS Handlers
   ============================ */

ims_handleDamage() // self == ims
{
	self endon ("carried");
	
	self maps\mp\gametypes\_damage::monitorDamage(
		self.config.maxHealth,
		"ims",
		::ims_HandleDeathDamage,
		::ims_ModifyDamage,
		true	// isKillstreak
	);
}

ims_ModifyDamage( attacker, weapon, type, damage )
{
	
	if ( self.hidden 
	    || weapon == "ims_projectile_mp" )	// shouldn't take damage from itself or another one
	{
		return -1;
	}
	
	modifiedDamage = damage;
	
	if( type == "MOD_MELEE" )
	{
		// make it take a few hits to kill
		modifiedDamage = self.maxhealth * 0.25; // four hits		
	}
	
	if( IsExplosiveDamageMOD( type ) )
	{
		modifiedDamage = damage * 1.5;
	}
	
	// modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	// modifiedDamage = self maps\mp\gametypes\_damage::handleEmpDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	return modifiedDamage;
}

ims_HandleDeathDamage( attacker, weapon, type, damage )
{
	notifyAttacker = self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, damage, "destroyed_ims", "ims_destroyed" );

	if ( notifyAttacker )
	{
		attacker notify( "destroyed_equipment" );
	}
}

ims_handleDeath()
{
	self endon ("carried");
	
	self waittill ( "death" );

	self removeFromIMSList();

	// this handles cases of deletion
	if ( !IsDefined( self ) )
		return;

	// iw6 - no destroyed model, and we don't want to replay all the open animations
	// self SetModel( level.imsSettings[ self.imsType ].modelDestroyed );

	self ims_setInactive();

	self PlaySound( "ims_destroyed" );
	
	if ( IsDefined( self.inUseBy ) )
	{
		PlayFX( getfx( "ims_explode_mp" ), self.origin + ( 0, 0, 10 ) );
		PlayFX( getfx( "ims_smoke_mp" ), self.origin );
		//playFxOnTag( getFx( "ims_explode_mp" ), self, "tag_origin" );
		//playFxOnTag( getFx( "ims_smoke_mp" ), self, "tag_origin" );

		self.inUseBy restorePerks();
		self.inUseBy restoreWeapons();				

		self notify( "deleting" );
		wait ( 1.0 );
		//StopFXOnTag( getFx( "ims_explode_mp" ), self, "tag_origin" );
		//StopFXOnTag( getFx( "ims_smoke_mp" ), self, "tag_origin" );
	}	
	else if ( IsDefined( self.immediateDeath ) )
	{
		PlayFX( getfx( "ims_explode_mp" ), self.origin + ( 0, 0, 10 ) );
		self notify( "deleting" );
	}
	else
	{		
		PlayFX( getfx( "ims_explode_mp" ), self.origin + ( 0, 0, 10 ) );
		//playFxOnTag( getFx( "ims_explode_mp" ), self, "tag_origin" );
		PlayFX( getfx( "ims_smoke_mp" ), self.origin );
		wait ( 3.0 );
		self PlaySound( "ims_fire" );
		
		self notify( "deleting" );
	}

	if ( IsDefined( self.objIdFriendly ) )
		_objective_delete( self.objIdFriendly );

	if ( IsDefined( self.objIdEnemy ) )
		_objective_delete( self.objIdEnemy );
	
	self maps\mp\gametypes\_weapons::equipmentDeleteVfx();
	
	self EnableMissileStick();

	self delete();
}

watchEMPDamage()
{
	self endon( "carried" );
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		// this handles any flash or concussion damage
		self waittill( "emp_damage", attacker, duration );

		// should the entity store the effects its playing?
		self maps\mp\gametypes\_weapons::stopBlinkingLight();
		
		PlayFX( getfx( "emp_stun" ), self.origin );
		PlayFX( getfx( "ims_smoke_mp" ), self.origin );
		
		wait( duration );
		
		self ims_Start();
	}
}

ims_handleUse() // self == ims
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		self waittill ( "trigger", player );
		
		assert( player == self.owner );
		assert( !IsDefined( self.carriedBy ) );

		if ( !isReallyAlive( player ) )
			continue;
		
		// do an extra health check here to make sure the ims hasn't been destroyed (the death notify might not make it within this frame)
		//	this fixes a bug where you can shoot the ims, pick it up, and now it'll be invincible next time you place it
		if ( self.damageTaken >= self.maxHealth )
			continue;
		
		if ( is_aliens() && IsDefined ( level.drill_carrier ) && player == level.drill_carrier )
			continue;

		imsForPlayer = createIMSForPlayer( self.imsType, player );
		// if this comes in undefined then they are already carrying an ims
		if( !IsDefined( imsForPlayer ) )
			continue;
		imsForPlayer.ims = self;
		self ims_setInactive();
		self ims_hideAllParts();

		if ( IsDefined( self GetLinkedParent() ) )
		{
			self Unlink();
		}

		player setCarryingIMS( imsForPlayer, false );
	}
}

/* ============================
	IMS Utility Functions
   ============================ */

ims_setPlaced() // self == imsForPlayer
{
	self endon( "death" );
	level endon( "game_ended" );

	if( IsDefined( self.carriedBy ) )
		self.carriedBy forceUseHintOff();
	self.carriedBy = undefined;

	if( IsDefined( self.owner ) )
		self.owner.isCarrying = false;
	
	self.firstPlacement = undefined;
	
	ims = undefined;
	if( IsDefined( self.ims ) )
	{
		ims = self.ims;
		ims endon ( "death" );
		ims.origin = self.origin;
		ims.angles = self.angles;
		ims.carriedBy = undefined;
		ims ims_showAllParts();
		if( IsDefined( ims.bombSquadModel ) )
		{
			ims.bombSquadModel Show();
			ims imsOpenAllDoors( ims.bombSquadModel, true );
			level notify( "update_bombsquad" );
		}
	}
	else
	{
		ims = createIMS( self );
	}
	
	ims addToIMSList();
	
	ims.isPlaced = true;
	
	ims thread ims_handleDamage();
	ims thread watchEmpDamage();
	ims thread ims_handleDeath();
	
	ims SetCanDamage( true );
	self PlaySound( "ims_plant" );

	self notify ( "placed" );
	ims thread ims_setActive();
	
	// Handle moving platform. 
	data = SpawnStruct();
	if ( IsDefined( self.moving_platform ) )
	{
		data.linkparent = self.moving_platform;
	}
	data.endonString = "carried";
	data.deathOverrideCallback = ::ims_moving_platform_death;
	ims thread maps\mp\_movers::handle_moving_platforms( data );

	self delete();
}

ims_setCancelled( playDestroyVfx )
{
	if( IsDefined( self.carriedBy ) )
	{
		owner = self.carriedBy;
		owner ForceUseHintOff();
		owner.isCarrying = undefined;
		
		owner.carriedItem = undefined;
	
		owner _enableWeapon();

		// this fixes a bug where the player can plant the ims, then pick it up and hold it in an unplaceable spot, then be killed and leave a ghost ims for the detectexplosives perk
		if( IsDefined( owner.imsList ) )
		{
			foreach( ims in owner.imsList )
			{
				 if( IsDefined( ims.bombSquadModel ) )
					 ims.bombSquadModel delete();
			}
		}
	}
	
	if ( IsDefined( playDestroyVfx ) && playDestroyVfx )
	{
		self maps\mp\gametypes\_weapons::equipmentDeleteVfx();
	}
	
	self delete();
}

ims_setCarried( carrier ) // self == imsForPlayer
{
	assert( isPlayer( carrier ) );
	assertEx( carrier == self.owner, "ims_setCarried() specified carrier does not own this ims" );

	self removeFromIMSList();
	
	self SetModel( level.imsSettings[ self.imsType ].modelPlacement );

	self SetSentryCarrier( carrier );
	self SetContents( 0 );
	self SetCanDamage( false );

	self.carriedBy = carrier;
	carrier.isCarrying = true;

	carrier thread updateIMSPlacement( self );
	
	self thread ims_onCarrierDeath( carrier );
	self thread ims_onCarrierDisconnect( carrier );
	self thread ims_onGameEnded();
	self thread ims_onEnterRide( carrier );
	if(is_aliens() && isdefined(level.drop_ims_when_grabbed_func))
		self thread [[level.drop_ims_when_grabbed_func]]( carrier );

	//self ims_setInactive();
	
	self notify ( "carried" );

	if( IsDefined( self.ims ) )
	{
		self.ims notify( "carried" );
		self.ims.carriedBy = carrier;
		self.ims.isPlaced = false;

		if( IsDefined( self.ims.bombSquadModel ) )
			self.ims.bombSquadModel Hide();
	}
}

updateIMSPlacement( ims )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	ims endon ( "placed" );
	ims endon ( "death" );
	
	ims.canBePlaced = true;
	lastCanPlaceIMS = -1; // force initial update
	
	config = level.imsSettings[ ims.imsType ];
	
	for( ;; )
	{
		placement = self CanPlayerPlaceSentry( true, config.placementRadius );

		ims.origin = placement[ "origin" ];
		ims.angles = placement[ "angles" ];
		ims.canBePlaced = self isOnGround() && placement[ "result" ] && ( abs(ims.origin[2]-self.origin[2]) < config.placementHeightTolerance );
	
		if ( isdefined( placement[ "entity" ] ) )
		{
			ims.moving_platform = placement[ "entity" ];
		}
		else 
		{
			ims.moving_platform = undefined;
		}

		if ( ims.canBePlaced != lastCanPlaceIMS )
		{
			// ims is the placement model
			// and ims.ims is actually the orignal world entity that will attack
			if ( ims.canBePlaced )
			{
				ims SetModel( level.imsSettings[ ims.imsType ].modelPlacement );
				self ForceUseHintOn( level.imsSettings[ ims.imsType ].placeString );
			}
			else
			{
				ims SetModel( level.imsSettings[ ims.imsType ].modelPlacementFailed );
				self ForceUseHintOn( level.imsSettings[ ims.imsType ].cannotPlaceString );
			}
			
			// can't open the doors on a turret?
			/*
			if ( IsDefined( ims.ims ) )
			{
				ims.ims imsOpenAllDoors( ims, true );
			}
			*/
		}
		
		lastCanPlaceIMS = ims.canBePlaced;		
		wait ( 0.05 );
	}
}

ims_onCarrierDeath( carrier ) // self == imsForPlayer
{
	self endon ( "placed" );
	self endon ( "death" );
	carrier endon( "disconnect" );

	carrier waittill ( "death" );
	
	// 2013-08-28 wallace: checking the spectator is a bit of a hack, due to the slightly weird way we are handling ims spawning
	if ( self.canBePlaced && carrier.team != "spectator" )
		self thread ims_setPlaced();
	else
		self ims_setCancelled();
}


ims_onCarrierDisconnect( carrier ) // self == imsForPlayer
{
	self endon ( "placed" );
	self endon ( "death" );

	carrier waittill ( "disconnect" );
	
	self ims_setCancelled();
}


ims_onEnterRide( carrier ) // self == imsForPlayer
{
	self endon ( "placed" );
	self endon ( "death" );

	for ( ;; )
	{
		if ( isDefined( self.carriedBy.OnHeliSniper ) && self.carriedBy.OnHeliSniper )
		{
			self notify( "death" );
		}
		wait 0.1;
	}
	
}


ims_onGameEnded( carrier ) // self == imsForPlayer
{
	self endon ( "placed" );
	self endon ( "death" );

	level waittill ( "game_ended" );
	
	self ims_setCancelled();
}


ims_setActive() // self == ims
{
	self setCursorHint( "HINT_NOICON" );
	self setHintString( level.imsSettings[ self.imsType ].hintString );

	owner = self.owner;
	owner ForceUseHintOff();
	if ( !is_aliens() )
	{
		if ( level.teamBased )
			self maps\mp\_entityheadicons::setTeamHeadIcon( self.team, (0,0,60) );
		else
			self maps\mp\_entityheadicons::setPlayerHeadIcon( owner, (0,0,60) );
	}
	self MakeUsable();
	self SetCanDamage( true );
	self maps\mp\gametypes\_weapons::makeExplosiveTargetableByAI();

	// destroy any other ims and put this one in the list
	if( IsDefined( owner.imsList ) )
	{
		foreach( ims in owner.imsList )
		{
			// make sure we aren't just picking up and placing the same one again
			if( ims == self )
				continue;

			ims notify( "death" );
		}
	}
	owner.imsList = [];
	owner.imsList[0] = self;

	foreach ( player in level.players )
	{
		if( player == owner )
			self enablePlayerUse( player );
		else
			self disablePlayerUse( player );
	}	

	if( self.shouldSplash )
	{
		level thread teamPlayerCardSplash( level.imsSettings[ self.imsType ].splashName, owner );
		self.shouldSplash = false;
	}

	// make sure we don't go too high if there's something above it
	// need to shoot bullet traces from each pod and pick the lowest, this way it'll minimize instances where the sensor won't shoot because it's under a hole in the ceiling
	positionOffset = ( 0, 0, 20 );
	traceOffset = ( 0, 0, 256 ) - positionOffset;
	results = [];
	
	self.killcam_ents = [];
	for ( i = 0; i < self.config.numExplosives; i++ )
	{
		if ( numExplosivesExceedModelCapacity() )
			TagIndex = shiftIndexForward( i + 1, self.config.numExplosives - CONST_NUM_LID_ON_MODEL );
		else
			TagIndex = i + 1;
		
		tag_origin = self GetTagOrigin( self.config.explTagRoot + TagIndex + KS_ATTACH );
		tag_origin_with_pos_offset = self GetTagOrigin( self.config.explTagRoot + TagIndex + KS_ATTACH ) + positionOffset;
		results[i] = BulletTrace( tag_origin_with_pos_offset, tag_origin_with_pos_offset + traceOffset, false, self );

		// we need to have the killcam ents created when the ims is created so the killcam will be correct
		//	if we don't do this then the killcam will be offset incorrectly when it takes more than one shot to kill someone
		//	NOTE: the code relies on the killcam entity to exist at the time it tries to play, so the entity has to exist the entire time
		
		if ( i < CONST_NUM_LID_ON_MODEL )
		{
			killcam_ent = Spawn( "script_model", tag_origin + self.config.killCamOffset );
			killcam_ent SetScriptMoverKillCam( "explosive" );
			self.killcam_ents[ self.killcam_ents.size ] = killcam_ent;
		}
	}
	
	lowestZ = results[0];
	for( i = 0; i < results.size; i++ )
	{
		if( results[i][ "position" ][2] < lowestZ[ "position" ][2] )
			lowestZ = results[i];
	}

	// minus some units on the z so this will work in cramped places like in a train
	self.attackHeightPos = lowestZ[ "position" ] - ( 0, 0, 20 ) - self.origin;
	// trigger height should be around 100 so you don't trigger it from the second floor
	attackTrigger = Spawn( "trigger_radius", self.origin, 0, 256, 100 );
	self.attackTrigger = attackTrigger;
	self.attackTrigger EnableLinkTo();
	self.attackTrigger LinkTo( self );
	// move at 200 units per second
	self.attackMoveTime = Length( self.attackHeightPos ) / 200;
	
	self imsCreateExplosiveWithKillCam();

	self ims_Start();
	self thread ims_WatchPlayerConnected();
	
	foreach( player in level.players )
		self thread ims_playerJoinedTeam( player );
	
/#
	self thread debug_draw();
#/
}

/#
debug_draw() // self == ims
{
	self endon( "death" );
	
	while( true )
	{
		if( GetDvarInt( "scr_ims_debug_draw" ) != 0 )
		{
			if( IsDefined( self.attackTrigger ) )
				draw_volume( self.attackTrigger, 1.0, ( 0, 0, 1 ) );
		
			foreach( player in level.players )
			{
				if( player.team == self.team )
					continue;
				
				start = self.attackHeightPos + self.origin;
				end = player.origin + ( 0, 0, 50 );
				result = BulletTrace( start, end, false, self );
				Print3d( start, result[ "surfacetype" ], ( 1, 1, 1 ), 1, 1, 10 );
				drawLine( start, end, 1.0, ( 1, 0, 0 ) );
			}
			
		}
		
		wait( 1.0 );
	}
}
#/
	
ims_WatchPlayerConnected() // self == ims
{
	self endon( "death" );

	while( true )
	{
		// when new players connect they need to not be able to use the planted ims
		level waittill( "connected", player );
		self ims_playerConnected( player );
	}
}

ims_playerConnected( player ) // self == ims
{
	self endon( "death" );
	player endon( "disconnect" );
	
	player waittill( "spawned_player" );

	// this can't possibly be the owner because the ims is destroyed if the owner leaves the game, so disable use for this player
	self DisablePlayerUse( player );
}

ims_playerJoinedTeam( player ) // self == ims
{
	self endon( "death" );
	player endon( "disconnect" );

	// when new players connect they need to not be able to use the planted ims
	while( true )
	{
		player waittill( "joined_team" );
		
		// this can't possibly be the owner because the ims is destroyed if the owner leaves the game, so disable use for this player
		self DisablePlayerUse( player );
	}
}

ims_onKillstreakDisowned() // self == ims
{
	self endon ( "death" );
	level endon ( "game_ended" );

	self.owner waittill ( "killstreak_disowned" );
	
	if ( IsDefined( self.isPlaced ) )
	{
		self notify( "death" );
	}
	else
	{
		self ims_setCancelled( false );
	}
}

// the ims is *on* and can attack targets
ims_Start()
{
	self thread maps\mp\gametypes\_weapons::doBlinkingLight( "tag_fx" );
	self thread ims_attackTargets();	
}


ims_setInactive()
{
	self MakeUnusable();
	self FreeEntitySentient();

	if ( level.teamBased )
		self maps\mp\_entityheadicons::setTeamHeadIcon( "none", ( 0, 0, 0 ) );
	else if ( IsDefined( self.owner ) )
		self maps\mp\_entityheadicons::setPlayerHeadIcon( undefined, ( 0, 0, 0 ) );

	if( IsDefined( self.attackTrigger ) )
		self.attackTrigger delete();
	
	if( IsDefined( self.killcam_ents ) )
	{
		foreach( ent in self.killcam_ents )
		{
			if( IsDefined( ent ) )
			{
				if( IsDefined( self.owner ) && IsDefined( self.owner.imsKillCamEnt ) && ent == self.owner.imsKillCamEnt )
					continue; // this killcam ent has been fired so let it clean itself up
				else
					ent Delete();
			}
		}
	}
	
	if ( IsDefined( self.explosive1 ) )
	{
		self.explosive1 Delete();
		self.explosive1 = undefined;
	}
	
	self maps\mp\gametypes\_weapons::stopBlinkingLight();
}

isFriendlyToIMS( ims )
{
	if ( level.teamBased && self.team == ims.team )
		return true;
		
	return false;
}

/* ============================
	IMS Logic Functions
   ============================ */

ims_attackTargets() // self == ims
{
	// do not need to end on carried, because the ims sends a death
	self endon ( "death" );
	self endon( "emp_damage" );
	level endon( "game_ended" );

	// watch the radius, if something enters, shot sensor up and drop bombs down
	while( true )
	{
		// checking for the attackTrigger will tell us if this has been set to inactive and is dying
		if( !IsDefined( self.attackTrigger ) )
			break;

		self.attackTrigger waittill( "trigger", targetEnt );

		if( IsPlayer( targetEnt ) )
		{
			// don't attack the owner
			if( IsDefined( self.owner ) && targetEnt == self.owner )
				continue;

			if( level.teambased && targetEnt.pers["team"] == self.team )
				continue;

			if( !isReallyAlive( targetEnt ) )
				continue;
		}
		else // things like the remote tank can trip this
		{
			if( IsDefined( targetEnt.owner ) )
			{
				// don't attack the owner
				if( IsDefined( self.owner ) && targetEnt.owner == self.owner )
					continue;

				if( level.teambased && targetEnt.owner.pers["team"] == self.team )
					continue;
			}
		}

		offsetPos = targetEnt.origin + (0, 0, 50);
		// make sure the sensor that shoots up in the air can see the target and the pods can see the target (using the lid tags on each pod)
		// this fixes an issue where the ims will kill someone who is on the other side of tall cover
		if ( !SightTracePassed( self.attackHeightPos + self.origin, offsetPos, false, self ) )
			continue;

		sightPassed = false;
		for ( i = 1; i <= self.config.numExplosives; i++ )
		{
			if ( i > CONST_NUM_LID_ON_MODEL )
				break;
			
			if ( SightTracePassed( self GetTagOrigin( self.config.lidTagRoot + i ), offsetPos, false, self ) )
			{
				sightPassed = true;
				break;
			}
		}
		
		if ( !sightPassed )
			continue;
		
		
		self playsound( "ims_trigger" );
		if ( is_aliens() && isDefined( level.ims_alien_grace_period_func ) && isDefined( self.owner ) )
		{
			grace_period = [[level.ims_alien_grace_period_func]]( level.imsSettings[ self.imsType ].gracePeriod, self.owner );
			self maps\mp\gametypes\_weapons::explosiveTrigger( targetEnt, grace_period, "ims" );
		}
		else
			self maps\mp\gametypes\_weapons::explosiveTrigger( targetEnt, level.imsSettings[ self.imsType ].gracePeriod, "ims" );

		// checking for the attackTrigger will tell us if this has been set to inactive and is dying
		if( !IsDefined( self.attackTrigger ) )
			break;
		
		if ( !IsDefined( self.hasExplosiveFired[ self.attacks ] ) )
		{
			self.hasExplosiveFired[ self.attacks ] = true;
			self thread fire_sensor( targetEnt, self.attacks );
			self.attacks++;			
		}
		
		if ( self.attacks > self.config.numExplosives )
			break;
		
		// create the next kill cam
		self imsCreateExplosiveWithKillCam();

		self waittill ( "sensor_exploded" );
		wait (self.config.rearmTime);	// wait a little extra so we don't attack a dying guy a second time.
	
		if( !IsDefined( self.owner ) )
			break;
	}

	// if the owner is carrying it, don't send death notify
	if( IsDefined( self.carriedBy ) && IsDefined( self.owner ) && self.carriedBy == self.owner )
		return;

	self notify( "death" );
}

fire_sensor( targetEnt, explNum )
{
	if ( numExplosivesExceedModelCapacity() )
		explNum = shiftIndexForward( explNum, self.config.numExplosives - CONST_NUM_LID_ON_MODEL );
		
	// sensor = self imsCreateExplosive( explNum );
	sensor = self.explosive1;
	self.explosive1 = undefined;	// so it doesn't get cleaned up if the player picks up the ims after sensor is fired
	
	lidName = self.config.lidTagRoot + explNum;
	PlayFXOnTag( level._effect[ "ims_sensor_explode" ], self, lidName );
	
	self imsOpenDoor( explNum, self.config );
	
	savedWeaponInfo = self.config.weaponInfo;
	savedOwner = self.owner;
	
	sensor Unlink();
	sensor RotateYaw( 3600, self.attackMoveTime );
	sensor MoveTo( self.attackHeightPos + self.origin, self.attackMoveTime, self.attackMoveTime * 0.25, self.attackMoveTime * 0.25 );
	
	if ( IsDefined( sensor.killCamEnt ) )
	{
		killCamEnt = sensor.killCamEnt;
		killCamEnt Unlink();
		
		// set the owner's kill cam ent here to make sure we always get the right kill cam for the latest sensor fired
		// this fixes a bug where you could place one ims, let it kill, then place a second, let it kill, and the kill cam would be wrong because we deleted the kill cam ent when the first one died
		if( IsDefined( self.owner ) )
			self.owner.imsKillCamEnt = killCamEnt;
		
		killCamEnt MoveTo( self.attackHeightPos + self.origin + self.config.killCamOffset, self.attackMoveTime, self.attackMoveTime * 0.25, self.attackMoveTime * 0.25 );
		
		if ( !numExplosivesExceedModelCapacity() )
			killCamEnt thread deleteAfterTime( 5.0 );
	}
	
	sensor playsound( "ims_launch" );
	// TODO: get fx for flying up
	//PlayFX( level._effect[ "ims_sensor_trail" ], sensorEnt.origin );
	sensor waittill( "movedone" );
	// TODO: get fx for blowing up in the air
	//StopFXOnTag( level._effect[ "ims_sensor_trail" ], sensorEnt, sensorEnt.tag );
	PlayFX( level._effect[ "ims_sensor_explode" ], sensor.origin );
	
	dropBombs = [];
	dropBombs[0] = targetEnt.origin;
	for( i = 0; i < dropBombs.size; i++ )
	{
		//level thread draw_line_for_time( self.origin, dropBombs[i], 1, 0, 0, 10 );
		if( IsDefined( savedOwner ) )
		{
			MagicBullet( savedWeaponInfo, sensor.origin, dropBombs[i], savedOwner );
			if( is_aliens() && isDefined( level.ims_alien_fire_func ) )
			{			
				self thread [[level.ims_alien_fire_func]]( dropBombs[i], savedOwner );
			}
		}
		else
			MagicBullet( savedWeaponInfo, sensor.origin, dropBombs[i] );
	}
	
	sensor Delete();
	self notify ( "sensor_exploded" );
}

deleteAfterTime( time )
{
	self endon( "death" );

	level maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( time );

	if( IsDefined( self ) )
		self delete();
}

ims_timeOut()
{
	self endon( "death" );
	level endon ( "game_ended" );
	
	lifeSpan = level.imsSettings[ self.imsType ].lifeSpan;
/#
	lifeSpan = GetDvarFloat( "scr_ims_timeout" );
#/
		
	while ( lifeSpan )
	{
		wait ( 1.0 );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		
		if ( !IsDefined( self.carriedBy ) )
			lifeSpan = max( 0, lifeSpan - 1.0 );
	}
	
	// TODO: get sound for this
	//if ( IsDefined( self.owner ) )
	//	self.owner thread leaderDialogOnPlayer( "ims_gone" );
	
	self notify ( "death" );
}

addToIMSList()
{
	entNum = self GetEntityNumber();
	level.placedIMS[entNum] = self;	
}

removeFromIMSList()
{
	entNum = self GetEntityNumber();
	level.placedIMS[entNum] = undefined;
}

ims_hideAllParts() // self == ims
{
	self Hide();
	self.hidden = true;
}

ims_showAllParts() // self == ims
{
	self Show();
	self.hidden = false;
	
	self imsOpenAllDoors( self, true );
}

imsCreateExplosive( explNum ) // self == ims
{
	Assert( explNum >= 1 && explNum <= self.config.numExplosives );
	
	expl = Spawn( "script_model", self GetTagOrigin( self.config.explTagRoot + explNum + KS_ATTACH ) );
	expl SetModel( self.config.explosiveModel );
	// expl.angles = self.angles + explNum * (0, 45, 0);
	expl.angles = self.angles;

	expl.killCamEnt = self.killcam_ents[ explNum - 1 ];
	expl.killCamEnt LinkTo( self );
		
	return expl;
}

imsCreateExplosiveWithKillCam() // self == ims
{
	i = 1;
	while ( i <= self.config.numExplosives && IsDefined( self.hasExplosiveFired[i] ) )
	{
		i++;
	}
	
	if ( i <= self.config.numExplosives )
	{
		if ( numExplosivesExceedModelCapacity() )
			i = shiftIndexForward( i, self.config.numExplosives - CONST_NUM_LID_ON_MODEL );
		
		expl = self imsCreateExplosive( i );
		expl LinkTo( self );
		self.explosive1 = expl;
	}
	// should send a warning otherwise
}

imsOpenDoor( explNum, config, immediate )
{
	lidName = config.lidTagRoot + explNum + KS_ATTACH;
	
	// play the lid animation
	// self HidePart( lidName );
	animName = undefined;
	if ( IsDefined( immediate ) )
	{
		animName = config.lidSnapOpenAnims[ explNum ];
	}
	else
	{
		animName = config.lidOpenAnims[ explNum ];
	}
	
	self ScriptModelPlayAnim( animName );
	// self ScriptModelPlayAnim( config.lidOpenAnim + explNum );
	
	// hide the built in explosive (probably did not need to model this)
	explName = config.explTagRoot + explNum + KS_ATTACH;
	self HidePart( explName );
}

// modelEnt - could be bombsquad model
// Since the anims open all the doors cumulatively, we only need to play one anim
imsOpenAllDoors( modelEnt, immediate )	// self == base ims
{
	numDoors = self.hasExplosiveFired.size;
	if ( numDoors > 0 )
	{
		if ( numExplosivesExceedModelCapacity() )
			numDoors = shiftIndexForward( numDoors, self.config.numExplosives - CONST_NUM_LID_ON_MODEL );
	
		modelEnt imsOpenDoor( numDoors, self.config, immediate );
	}
}

numExplosivesExceedModelCapacity()
{
	return ( self.config.numExplosives > CONST_NUM_LID_ON_MODEL );
}

shiftIndexForward( index, amount_to_shift )
{
	shifted_index = index - amount_to_shift;
	shifted_index = max( 1, shifted_index );
	return int( shifted_index );
}
