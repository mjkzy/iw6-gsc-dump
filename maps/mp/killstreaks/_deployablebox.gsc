#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

/*
	Deployable box killstreaks: the player will be able to place a box in the world and teammates can grab items from it
		this will be used on multiple killstreaks where you can place a box in the world with something in it
*/

BOX_TIMEOUT_UPDATE_INTERVAL = 1.0;
DEFAULT_USE_TIME = 3000;
BOX_DEFAULT_HEALTH = 999999;	// so that boxes aren't killed in code

init()
{
	if ( !IsDefined( level.boxSettings ) )
	{
		level.boxSettings = [];
	}
}

///////////////////////////////////////////////////
// MARKER FUNCTIONS
// 2012-06-21 wallace
// Stole an updated version from _uplink.gsc. Should probably unify all these funcs eventually
//////////////////////////////////////////////////
beginDeployableViaMarker( lifeId, boxType )
{
	self thread watchDeployableMarkerCancel( boxType );
	self thread watchDeployableMarkerPlacement( boxType, lifeId );
	
	while ( true )
	{
		result = self waittill_any_return( "deployable_canceled", "deployable_deployed", "death", "disconnect" );
		
		return ( result == "deployable_deployed" );
	}
}

tryUseDeployable( lifeId, boxType )	// self == player
{
	self thread watchDeployableMarkerCancel( boxType );
	self thread watchDeployableMarkerPlacement( boxType, lifeId );
	
	while ( true )
	{
		result = self waittill_any_return( "deployable_canceled", "deployable_deployed", "death", "disconnect" );
		
		return ( result == "deployable_deployed" );
	}
}

watchDeployableMarkerCancel( boxType )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "deployable_deployed" );
	
	boxConfig = level.boxSettings[ boxType ];
	currentWeapon = self getCurrentWeapon();

	while( currentWeapon == boxConfig.weaponInfo )
	{	
		self waittill( "weapon_change", currentWeapon );
	}
	
	self notify( "deployable_canceled" );
}

watchDeployableMarkerPlacement( boxType, lifeId )
{
	self endon( "spawned_player" ); // you shouldn't do endon( "death" ) here because this thread needs to run
	self endon( "disconnect" );
	self endon( "deployable_canceled" );
	
	while( true )
	{
		self waittill( "grenade_fire", marker, weaponName );
		
		if( isReallyAlive(self) )
		{
			break;
		}
		else
		{
			marker Delete();
		}
	}
	
	marker MakeCollideWithItemClip( true );
	
	self notify( "deployable_deployed" );
	
	marker.owner = self;
	marker.weaponName = weaponName;
	self.marker = marker;
	
	marker PlaySoundToPlayer( level.boxSettings[ boxType ].deployedSfx, self );
	
	marker thread markerActivate( lifeId, boxType, ::box_setActive );		
}

override_box_moving_platform_death( data )
{
	self notify( "death" ); // we're doing this here instead of letting the mover code just delete us so that we can run our necessary clean-up functionality (like removal of the objective marker from the minimap)
}

markerActivate( lifeId, boxType, usedCallback ) // self == marker
{	
	self notify( "markerActivate" );
	self endon( "markerActivate" );
	//self waittill( "explode", position );
	self waittill( "missile_stuck" );
	owner = self.owner;
	position = self.origin;

	if ( !isDefined( owner ) )
		return;

	box = createBoxForPlayer( boxType, position, owner );

	// For moving platforms. 
	data = SpawnStruct();
	data.linkParent = self GetLinkedParent();
	
	//fixes wall hack exploit with linked items
	if ( isDefined( data.linkParent ) && isDefined( data.linkParent.model ) && DeployableExclusion( data.linkParent.model ) )
	{
		box.origin = data.linkParent.origin;
			
		grandParent = data.linkParent GetLinkedParent();
		
		if ( isDefined( grandParent ) )
			data.linkParent = grandParent;
		else
			data.linkParent = undefined;
	}
				
	data.deathOverrideCallback = ::override_box_moving_platform_death;
	box thread maps\mp\_movers::handle_moving_platforms( data );
	
	box.moving_platform = data.linkParent;
	
	box SetOtherEnt(owner);

	// ES - 2/24/14 - This waitframe is causing an issue where, when deployed on a moving platform, the "death" notification is sent instantly, but is never caught.
	wait 0.05;

	//self playSound( "sentry_gun_beep" );
	box thread [[ usedCallback ]]();

	self delete();
	
	if( IsDefined(box) && (box touchingBadTrigger()) )
	{
		box notify( "death" );
	}
}

DeployableExclusion( parentModel )
{
	if ( parentModel == "mp_satcom" )
		return true;
	else if ( IsSubStr( parentModel, "paris_catacombs_iron" ) )
		return true;
	else if ( IsSubStr( parentModel, "mp_warhawk_iron_gate" ) )
		return true;

	return false;
}

isHoldingDeployableBox()
{
	curWeap = self GetCurrentWeapon();
	if ( IsDefined( curWeap ) )
	{
		foreach( deplBoxWeap in level.boxSettings )
		{
			if ( curWeap == deplBoxWeap.weaponInfo )
				return true;
		}
	}
	
	return false;
}
///////////////////////////////////////////////////
// END MARKER FUNCTIONS
//////////////////////////////////////////////////

///////////////////////////////////////////////////
// BOX HANDLER FUNCTIONS
//////////////////////////////////////////////////

createBoxForPlayer( boxType, position, owner )
{
	assertEx( isDefined( owner ), "createBoxForPlayer() called without owner specified" );
	
	boxConfig = level.boxSettings[ boxType ];

	box = Spawn( "script_model", position - (0,0,1) );
	box setModel( boxConfig.modelBase );
	box.health = BOX_DEFAULT_HEALTH;
	box.maxHealth = boxConfig.maxHealth;
	box.angles = owner.angles;
	box.boxType = boxType;
	box.owner = owner;
	box.team = owner.team;
	box.id = boxConfig.id;
	
	if ( IsDefined( boxConfig.dpadName ) )
	{
		box.dpadName = boxConfig.dpadName;
	}
	if ( IsDefined( boxConfig.maxUses ) )
	{
		box.usesRemaining = boxConfig.maxUses;
	}
	
	box box_setInactive();
	box thread box_handleOwnerDisconnect();
	box addBoxToLevelArray();
	
	return box;	
}

box_setActive( skipOwnerUse ) // self == box
{
	self setCursorHint( "HINT_NOICON" );
	boxConfig = level.boxSettings[ self.boxType ];
	self setHintString( boxConfig.hintString );

	self.inUse = false;

	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
	Objective_Add( curObjID, "invisible", (0,0,0) );
	
	if ( !IsDefined( self GetLinkedParent() ) )
		Objective_Position( curObjID, self.origin );
	else
		Objective_OnEntity( curObjID, self );
	
	Objective_State( curObjID, "active" );
	Objective_Icon( curObjID, boxConfig.shaderName );
	self.objIdFriendly = curObjID;
		
	if ( level.teamBased )
	{
		Objective_Team( curObjID, self.team );
		foreach ( player in level.players )
		{
			if ( self.team == player.team 
			    && (!IsDefined(boxConfig.canUseCallback) || player [[ boxConfig.canUseCallback ]](self) )
			   )
			{
				self box_SetIcon( player, boxConfig.streakName, boxConfig.headIconOffset );
			}
		}
	}
	else
	{
		Objective_Player( curObjID, self.owner GetEntityNumber() );

		if( !IsDefined(boxConfig.canUseCallback) || self.owner [[ boxConfig.canUseCallback ]](self) )
		{
			self box_SetIcon( self.owner, boxConfig.streakName, boxConfig.headIconOffset );
		}
	}

	self MakeUsable();
	self.isUsable = true;
	self SetCanDamage( true );
	self thread box_handleDamage();
	self thread box_handleDeath();
	self thread box_timeOut();
	self thread disableWhenJuggernaut();
	self make_entity_sentient_mp( self.team, true );
	if ( IsSentient( self ) )
	{
		self SetThreatBiasGroup( "DogsDontAttack" );
	}
	
	if ( IsDefined( self.owner ) )
		self.owner notify( "new_deployable_box", self );
	
	if (level.teamBased)
	{
		foreach ( player in level.participants )
		{
			_box_setActiveHelper( player, self.team == player.team, boxConfig.canUseCallback );
			
			// handle team switches for human players
			if ( !IsAI( player ) )
			{
				self thread box_playerJoinedTeam( player );
			}
		}
	}
	else
	{
		foreach ( player in level.participants )
		{
			_box_setActiveHelper( player, IsDefined( self.owner ) && self.owner == player, boxConfig.canUseCallback );
		}
	}

	level thread teamPlayerCardSplash( boxConfig.splashName, self.owner, self.team );

	self thread box_playerConnected();
	self thread box_agentConnected();
	
	if ( IsDefined( boxConfig.onDeployCallback ) )
	{
		self [[ boxConfig.onDeployCallback ]]( boxConfig );
	}
	
	self thread createBombSquadModel( self.boxType );
}

_box_setActiveHelper( player, bActivate, canUseFunc )
{
	if ( bActivate )
	{
		if ( !IsDefined( canUseFunc ) || player [[ canUseFunc ]](self) )
		{
			self box_enablePlayerUse( player );
		}
		else
		{
			self box_disablePlayerUse( player );
			// if this player is already a juggernaut then when they die, let them use the box
			self thread doubleDip( player );
		}
		self thread boxThink( player );
	}
	else
	{
		self box_disablePlayerUse( player );
	}
}

box_playerConnected() // self == box
{
	self endon( "death" );

	// when new players connect they need a boxthink thread run on them
	while( true )
	{
		level waittill( "connected", player );
		self childthread box_waittill_player_spawn_and_add_box( player );
	}
}

box_agentConnected() // self == box
{
	self endon( "death" );
	
	// when new agents connect they need a boxthink thread run on them
	while( true )
	{
		level waittill( "spawned_agent_player", agent );
		self box_addBoxForPlayer( agent );
	}
}

box_waittill_player_spawn_and_add_box( player ) // self == box
{
	player waittill( "spawned_player" );
	if ( level.teamBased )
	{
		self box_addBoxForPlayer( player );
		// handle team switches for late joins
		self thread box_playerJoinedTeam( player );
	}
}

box_playerJoinedTeam( player ) // self == box
{
	self endon( "death" );
	player endon( "disconnect" );

	// when new players connect they need a boxthink thread run on them
	while( true )
	{
		player waittill( "joined_team" );
		if ( level.teamBased )
		{
			self box_addBoxForPlayer( player );
		}
	}
}

box_addBoxForPlayer( player ) // self == box
{
	if ( self.team == player.team )
	{
		self box_enablePlayerUse( player );
		self thread boxThink( player );
		self box_SetIcon( player, level.boxSettings[ self.boxType ].streakName, level.boxSettings[ self.boxType ].headIconOffset );
	}
	else
	{
		self box_disablePlayerUse( player );
		self maps\mp\_entityheadIcons::setHeadIcon( player, "", (0,0,0) );
	}
}

box_SetIcon( player, streakName, vOffset )
{
	self maps\mp\_entityheadIcons::setHeadIcon( player, getKillstreakOverheadIcon( streakName ), (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
}

box_enablePlayerUse( player ) // self == box
{
	if ( IsPlayer(player) )
		self EnablePlayerUse( player );
	
	self.disabled_use_for[player GetEntityNumber()] = false;
}

box_disablePlayerUse( player ) // self == box
{
	if ( IsPlayer(player) )
		self DisablePlayerUse( player );
	
	self.disabled_use_for[player GetEntityNumber()] = true;
}

box_setInactive()
{
	self makeUnusable();
	self.isUsable = false;
	self maps\mp\_entityheadIcons::setHeadIcon( "none", "", (0,0,0) );
	if ( isDefined( self.objIdFriendly ) )
		_objective_delete( self.objIdFriendly );	
}

box_handleDamage()	// self == box
{
	boxConfig = level.boxSettings[ self.boxType ];
	
	self maps\mp\gametypes\_damage::monitorDamage(
		boxConfig.maxHealth,
		boxConfig.damageFeedback,
		::box_handleDeathDamage,
		::box_ModifyDamage,
		true	// isKillstreak
	);
}

box_ModifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
	
	boxConfig = level.boxSettings[ self.boxType ];
	if ( boxConfig.allowMeleeDamage )
	{
		modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	}
	
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleGrenadeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	return modifiedDamage;
}

box_handleDeathDamage( attacker, weapon, type, damage )
{
	boxConfig = level.boxSettings[ self.boxType ];
	notifyAttacker = self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, damage, boxconfig.xpPopup, boxConfig.voDestroyed );
	if ( notifyAttacker )
	{
		attacker notify( "destroyed_equipment" );
	}
	    
}

box_handleDeath()
{
	self waittill ( "death" );

	// this handles cases of deletion
	if ( !isDefined( self ) )
		return;

	self box_setInactive();
	self removeBoxFromLevelArray();

	boxConfig = level.boxSettings[ self.boxType ];
	PlayFX( boxConfig.deathVfx, self.origin );
	self PlaySound( "mp_killstreak_disappear" );	
	// 2013-03-08 wsh: whould probably validate all the used fields...
	if ( IsDefined( boxConfig.deathDamageMax ) )
	{
		owner = undefined;
		if ( IsDefined(self.owner) )
			owner = self.owner;
		
		// somewhat hacky:
		// shift the origin of the damage because it'll collide with the box otherwise
		// we could also apply the damage after we delete the item?
		RadiusDamage( self.origin + (0, 0, boxConfig.headIconOffset),
					 boxConfig.deathDamageRadius, 
					 boxConfig.deathDamageMax,
					 boxConfig.deathDamageMin,
					 owner,
					 "MOD_EXPLOSIVE",
					 boxConfig.deathWeaponInfo
					);
	}

	self notify( "deleting" );

	self delete();
}

box_handleOwnerDisconnect() // self == box
{
	self endon ( "death" );
	level endon ( "game_ended" );

	self notify ( "box_handleOwner" );
	self endon ( "box_handleOwner" );

	self.owner waittill( "killstreak_disowned" );

	self notify( "death" );
}

boxThink( player )
{	
	self endon ( "death" );

	self thread boxCaptureThink( player );
	
	if ( !IsDefined(player.boxes) )
	{
		player.boxes = [];
	}
	player.boxes[player.boxes.size] = self;
	
	boxConfig = level.boxSettings[ self.boxType ];

	for ( ;; )
	{
		self waittill ( "captured", capturer );
		
		if (capturer == player)
		{
			player PlayLocalSound( boxConfig.onUseSfx );
			
			if ( IsDefined( boxConfig.onuseCallback ) )
			{
				player [[ boxConfig.onUseCallback ]]( self );
			}
		
			// if this is not the owner then give the owner some xp
			if( IsDefined( self.owner ) && player != self.owner )
			{
				self.owner thread maps\mp\gametypes\_rank::xpEventPopup( boxConfig.event );
				self.owner thread maps\mp\gametypes\_rank::giveRankXP( "support", boxConfig.useXP );
			}
			
			if ( IsDefined( self.usesRemaining ) )
			{
				self.usesRemaining--;
				if ( self.usesRemaining == 0)
				{
					self box_leave();
					break;
				}
			}
			
			if ( IsDefined( boxConfig.canUseOtherBoxes ) && boxConfig.canUseOtherBoxes )
			{
				// don't let the player use any other boxes
				foreach( box in level.deployable_box[ boxConfig.streakName ] )
				{
					box maps\mp\killstreaks\_deployablebox::box_disablePlayerUse( self );
					box maps\mp\_entityheadIcons::setHeadIcon( self, "", (0,0,0) );
					box thread maps\mp\killstreaks\_deployablebox::doubleDip( self );
				}
			}
			else
			{
				self maps\mp\_entityheadIcons::setHeadIcon( player, "", (0,0,0) );
				self box_disablePlayerUse( player );
				self thread doubleDip( player );
			}
		}
	}
}

doubleDip( player ) // self == box
{
	self endon( "death" );
	player endon( "disconnect" );

	// once they die, let them take from the box again
	player waittill( "death" );

	if( level.teamBased )
	{
		if( self.team == player.team )
		{
			self box_SetIcon( player, level.boxSettings[ self.boxType ].streakName, level.boxSettings[ self.boxType ].headIconOffset );
			self box_enablePlayerUse( player );
		}
	}
	else
	{
		if( IsDefined( self.owner ) && self.owner == player )
		{
			self box_SetIcon( player, level.boxSettings[ self.boxType ].streakName, level.boxSettings[ self.boxType ].headIconOffset );
			self box_enablePlayerUse( player );
		}
	}
}

boxCaptureThink( player )	// self == box
{
	level endon( "game_ended" );
	
	while( isDefined( self ) )
	{
		self waittill( "trigger", tiggerer );
		if	(
				IsDefined( level.boxSettings[ self.boxType ].noUseKillstreak ) 
			&&	level.boxSettings[ self.boxType ].noUseKillstreak
			&&	isKillstreakWeapon( player GetCurrentWeapon() )
			)
		{
			continue;
		}
		
		if ( tiggerer == player && self useHoldThink( player, level.boxSettings[ self.boxType ].useTime ) )
		{
			self notify( "captured", player );
		}
	}
}

isFriendlyToBox( box )
{
	return ( level.teamBased 
		     && self.team == box.team );
}

box_timeOut() // self == box
{
	self endon( "death" );
	level endon ( "game_ended" );

	boxConfig = level.boxSettings[ self.boxType ];
	lifeSpan = boxConfig.lifeSpan;
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( lifeSpan );
	
	if ( IsDefined( boxConfig.voGone ) )
	{
		self.owner thread leaderDialogOnPlayer( boxConfig.voGone );
	}
	
	self box_leave();
}

box_leave()
{
	// TODO: get sound for this
	//if ( isDefined( self.owner ) )
	//	self.owner thread leaderDialogOnPlayer( "sentry_gone" );
	wait( 0.05 );

	self notify( "death" );
}

deleteOnOwnerDeath( owner ) // self == box.friendlyModel or box.enemyModel, owner == box
{
	wait ( 0.25 );
	self linkTo( owner, "tag_origin", (0,0,0), (0,0,0) );

	owner waittill ( "death" );

	box_leave();
}

box_ModelTeamUpdater( showForTeam ) // self == box model (enemy or friendly)
{
	self endon ( "death" );

	self hide();

	foreach ( player in level.players )
	{
		if ( player.team == showForTeam )
			self showToPlayer( player );
	}

	for ( ;; )
	{
		level waittill ( "joined_team" );

		self hide();
		foreach ( player in level.players )
		{
			if ( player.team == showForTeam )
				self showToPlayer( player );
		}
	}	
}

useHoldThink( player, useTime ) 
{
	self maps\mp\_movers::script_mover_link_to_use_object( player );

	player _disableWeapon();

	player.boxParams = SpawnStruct();
	player.boxParams.curProgress = 0;
	player.boxParams.inUse = true;
	player.boxParams.useRate = 0;
	player.boxParams.id = self.id;
	
	if ( isDefined( useTime ) )
	{
		player.boxParams.useTime = useTime;
	}
	else
	{
		player.boxParams.useTime = DEFAULT_USE_TIME;
	}

	result = useHoldThinkLoop( player );
	Assert( IsDefined( result ) );
	
	if ( isAlive( player ) )
	{
		player _enableWeapon();
		maps\mp\_movers::script_mover_unlink_from_use_object( player );
	}

	if ( !isDefined( self ) )
		return false;

	player.boxParams.inUse = false;
	player.boxParams.curProgress = 0;

	return ( result );
}

useHoldThinkLoop( player )
{
	config = player.boxParams;	
	while( player isPlayerUsingBox( config ) )
	{
		if ( !player maps\mp\_movers::script_mover_use_can_link( self ) )
		{
			player maps\mp\gametypes\_gameobjects::updateUIProgress( config, false );
			return false;
		}

		config.curProgress += (50 * config.useRate);

		if ( isDefined( player.objectiveScaler ) )
			config.useRate = 1 * player.objectiveScaler;
		else
			config.useRate = 1;

		player maps\mp\gametypes\_gameobjects::updateUIProgress( config, true );

		if ( config.curProgress >= config.useTime )
		{
			player maps\mp\gametypes\_gameobjects::updateUIProgress( config, false );
			return ( isReallyAlive( player ) );
		}

		wait 0.05;
	} 

	player maps\mp\gametypes\_gameobjects::updateUIProgress( config, false );
	return false;
}

disableWhenJuggernaut() // self == box
{
	level endon( "game_ended" );
	self endon( "death" );

	while( true )
	{
		level waittill( "juggernaut_equipped", player );
		self maps\mp\_entityheadIcons::setHeadIcon( player, "", (0,0,0) );
		self box_disablePlayerUse( player );
		self thread doubleDip( player );
	}
}

addBoxToLevelArray() // self == box
{
	// put the newly created box in the level array for the box type
	level.deployable_box[ self.boxType ][ self GetEntityNumber() ] = self;
}

removeBoxFromLevelArray() // self == box
{
	level.deployable_box[ self.boxType ][ self GetEntityNumber() ] = undefined;
}

createBombSquadModel( streakName ) // self == box
{
	config = level.boxSettings[ streakName ];
	
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

isPlayerUsingBox( box )	// self == player
{
	return ( !level.gameEnded 
		    && IsDefined( box ) 
		    && isReallyAlive( self ) && self UseButtonPressed()
		    && !( self IsOnLadder() )	// fix for 154828
		    && !( self MeleeButtonPressed() )	// from gameobjects.gsc
		    && !( IsDefined( self.throwingGrenade ) )	// from gameobjects.gsc
		    && box.curProgress < box.useTime 
		    && ( !IsDefined( self.teleporting ) || !self.teleporting ) 
		   );
}