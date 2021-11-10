#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\alien\_utility;

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
	if ( parentModel == "weapon_alien_laser_drill" )
		return true;
	else if ( IsSubStr( parentModel, "crafting" ) )
		return true;
	else if ( IsSubStr( parentModel, "scorpion_body" ) )
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
get_box_icon( resourceType, dpadName, upgrade_rank )
{
	return level.alien_combat_resources[ resourceType][ dpadName ].upgrades[upgrade_rank].dpad_icon;
}

get_resource_type( dpadName )
{
	if( !isDefined( dpadName ) )
		return undefined;
	
	foreach ( resource_type_name, resource_type in level.alien_combat_resources )
	{
		if ( IsDefined( resource_type[ dpadName ] ) )
		{
			return resource_type_name;
		}
	}
	
	return undefined;
}

createBoxForPlayer( boxType, position, owner )
{
	assertEx( isDefined( owner ), "createBoxForPlayer() called without owner specified" );
	
	boxConfig = level.boxSettings[ boxType ];

	box = Spawn( "script_model", position );
	box setModel( boxConfig.modelBase );
	box.health = BOX_DEFAULT_HEALTH;
	box.maxHealth = boxConfig.maxHealth;
	box.angles = owner.angles;
	box.boxType = boxType;
	box.owner = owner;
	box.team = owner.team;
	if ( IsDefined( boxConfig.dpadName ) )
	{
		box.dpadName = boxConfig.dpadName;
	}
	if ( IsDefined( boxConfig.maxUses ) )
	{
		box.usesRemaining = boxConfig.maxUses;
	}
	
	player = box.owner;
	resource_type = get_resource_type( box.dpadName );
	
	if ( is_combat_resource( resource_type ) )
	{
		box.upgrade_rank = player maps\mp\alien\_persistence::get_upgrade_level( resource_type );
		box.icon_name = get_box_icon( resource_type, box.dpadName, box.upgrade_rank );
	}
	else
	{
		AssertEx( isDefined( boxConfig.icon_name ), "For non-combat-resource box, the .icon_name must be specified in the boxConfig struct" );
		
		box.upgrade_rank = 0;
		box.icon_name = boxConfig.icon_name;
	}

	// black box data tracking
	level.alienBBData[ "team_item_deployed" ]++;
	player maps\mp\alien\_persistence::eog_player_update_stat( "deployables", 1 );
	
	/*
	ownername = "";
	if ( isdefined( owner.name ) )
		ownername = owner.name;
	
	itemname = boxType;
	if ( isdefined( box.dpadName ) )
		itemname = box.dpadName;
	
	/#
	if ( GetDvarInt( "alien_bbprint_debug" ) > 0 )
	{
		IPrintLnBold( "^8bbprint: aliendeployabledeployed \n" +
					 " itemname=" + itemname +
					 " itemlevel=" + box.upgrade_rank +
					 " itemx,y,z=" + position +
					 " ownername=" + ownername );
	}
	#/
	
	bbprint( "aliendeployabledeployed",
	    "itemname %s itemlevel %s itemx %f itemy %f itemz %f ownername %s ", 
	    itemname,
	    box.upgrade_rank,
	    position[0],
	    position[1],
	    position[2],
	    ownername );
	*/

	box box_setInactive();
	box thread box_handleOwnerDisconnect();
	box addBoxToLevelArray();
	
	return box;	
}

is_combat_resource( resource_type ) { return isDefined( resource_type ); }

box_setActive( skipOwnerUse ) // self == box
{
	self setCursorHint( "HINT_NOICON" );
	boxConfig = level.boxSettings[ self.boxType ];
	self setHintString( boxConfig.hintString );

	self.inUse = false;

	curObjID = maps\mp\gametypes\_gameobjects::getNextObjID();	
	Objective_Add( curObjID, "invisible", (0,0,0) );
	Objective_Position( curObjID, self.origin );
	Objective_State( curObjID, "active" );
	
	if( isDefined( boxConfig.shaderName ) )
		Objective_Icon( curObjID, boxConfig.shaderName );
	
	self.objIdFriendly = curObjID;
	
	// use the deployable on the owner once
	if ( ( !IsDefined( skipOwnerUse ) || !skipOwnerUse ) && IsDefined( boxConfig.onuseCallback )
	    && ( !IsDefined( boxconfig.canUseCallback ) || (self.owner [[ boxConfig.canUseCallback ]]() ) )
	   )
	{
		if( isReallyAlive( self.owner ) )
			self.owner [[ boxConfig.onUseCallback ]]( self );
	}	
	
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

	self make_entity_sentient_mp( self.team, true );
	
	if ( IsDefined( self.owner ) )
		self.owner notify( "new_deployable_box", self );
	
	if (level.teamBased)
	{
		foreach ( player in level.participants )
		{
			_box_setActiveHelper( player, self.team == player.team, boxConfig.canUseCallback );
		}
	}
	else
	{
		foreach ( player in level.participants )
		{
			_box_setActiveHelper( player, IsDefined( self.owner ) && self.owner == player, boxConfig.canUseCallback );
		}
	}

	if( ( !isdefined( self.air_dropped ) || !self.air_dropped ) && !isPlayingSolo() )
		level thread teamPlayerCardSplash( boxConfig.splashName, self.owner, self.team );

	self thread box_playerConnected();
	self thread box_agentConnected();
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
	self maps\mp\_entityheadIcons::setHeadIcon( player, self.icon_name, (0, 0, vOffset), 14, 14, undefined, undefined, undefined, undefined, undefined, false );
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
		::boxModifyDamage,
		::boxHandleDeathDamage,
		true	// isKillstreak
	);
}

boxModifyDamage( attacker, weapon, type, damage )
{
	modifiedDamage = damage;
	
	if( IsExplosiveDamageMOD( type ) )
	{
		modifiedDamage = damage * 1.5;
	}
	
	modifiedDamage = self maps\mp\gametypes\_damage::handleMeleeDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleMissileDamage( weapon, type, modifiedDamage );
	modifiedDamage = self maps\mp\gametypes\_damage::handleAPDamage( weapon, type, modifiedDamage, attacker );
	
	return modifiedDamage;
}

boxHandleDeathDamage( attacker, weapon, type, damage )
{
	boxConfig = level.boxSettings[ self.boxType ];
	self maps\mp\gametypes\_damage::onKillstreakKilled( attacker, weapon, type, damage, boxConfig.xpPopup, boxConfig.voDestroyed );
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
	PlayFX( getfx( "deployablebox_crate_destroy" ), self.origin );
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
	
	wait( 0.1 );

	self notify( "deleting" );

	self delete();
}

box_handleOwnerDisconnect() // self == box
{
	self endon ( "death" );
	level endon ( "game_ended" );

	self notify ( "box_handleOwner" );
	self endon ( "box_handleOwner" );
	
	old_owner = self.owner;
	self.owner waittill( "killstreak_disowned" );
	
	// special case for air dropped box to stay when fake owner leaves ( owner was randomly picked )
	if ( isdefined( self.air_dropped ) && self.air_dropped )
	{
		// reassign owner to next avaliable player
		foreach ( player in level.players )
		{
			if ( !isdefined( player ) || ( isdefined( old_owner ) && old_owner == player ) )
				continue;
			
			self.owner = player;
			self thread box_handleOwnerDisconnect(); // recurse
			return;
		}
	}
	
	// removed if not air dropped or if no host player found (which shouldn't happen)
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
				
				if ( maps\mp\alien\_utility::is_chaos_mode() )
					maps\mp\alien\_chaos::update_pickup_deployable_box_event();
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
	
			self maps\mp\_entityheadIcons::setHeadIcon( player, "", (0,0,0) );
			self box_disablePlayerUse( player );
			self thread doubleDip( player );
		}
	}
}

doubleDip( player ) // self == box
{
	self endon( "death" );
	player endon( "disconnect" );

	// air dropped rewards can not be double dipped
	if( isdefined( self.air_dropped ) && self.air_dropped )
		return;
	
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
	while( isDefined( self ) )
	{
		self waittill( "trigger", tiggerer );
		if ( is_aliens() )
		{
			if ( [[level.boxCaptureThink_alien_func]]( tiggerer ) )
				continue;
		}
		if ( is_chaos_mode() )
		{
			switch ( self.boxType )
			{
				case "medic_skill":
				case "specialist_skill":
				case "tank_skill":
				case "engineer_skill":
					if( is_true( tiggerer.hasChaosClassSkill ) )
					{
						tiggerer maps\mp\_utility::setLowerMessage( "cant_use", &"ALIEN_CHAOS_CANT_PICKUP_BONUS", 3 );
						continue;
					}
					else if ( is_true( tiggerer.chaosClassSkillInUse ) )
					{
						tiggerer maps\mp\_utility::setLowerMessage( "skill_in_use", &"ALIEN_CHAOS_SKILL_IN_USE", 3 );
						continue;
					}
					break;
				case "combo_freeze":
					if( is_true( tiggerer.hasComboFreeze ) )
					{
						tiggerer maps\mp\_utility::setLowerMessage( "cant_use", &"ALIEN_CHAOS_CANT_PICKUP_BONUS", 3 );
						continue;
					}
					break;	
				default:
					break;
			}
		}

		if (tiggerer == player
		    && self useHoldThink( player, level.boxSettings[ self.boxType ].useTime )
		   )
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
	
	if ( box_should_leave_immediately() )
	{
		wait 0.05;
	}
	else
	{
		lifeSpan = level.boxSettings[ self.boxType ].lifeSpan;
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( lifeSpan );
	}
	
	self box_leave();
}

box_should_leave_immediately()
{
	if ( ( self.boxtype == "deployable_ammo" && self.upgrade_rank == 4 ) || ( self.boxtype == "deployable_specialammo_comb" && self.upgrade_rank == 4 ) )  // stay to regen ammo
		return false;
	
	if ( maps\mp\alien\_utility::isPlayingSolo() && ( !isdefined( self.air_dropped ) || !self.air_dropped ) )
		return true;
	
	return false;
}

box_leave()
{
	// TODO: get sound for this
	//if ( isDefined( self.owner ) )
	//	self.owner thread leaderDialogOnPlayer( "sentry_gone" );
	PlayFX( getfx( "deployablebox_crate_destroy" ), self.origin );
	
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
	if ( IsPlayer(player) )
		player playerLinkTo( self );
	else
		player LinkTo( self );
	player playerLinkedOffsetEnable();

	player.boxParams = SpawnStruct();
	player.boxParams.curProgress = 0;
	player.boxParams.inUse = true;
	player.boxParams.useRate = 0;

	if ( isDefined( useTime ) )
	{
		player.boxParams.useTime = useTime;
	}
	else
	{
		player.boxParams.useTime = DEFAULT_USE_TIME;
	}

	//player _disableWeapon();
	player disable_weapon_timeout( ( useTime + 0.05 ), "deployable_weapon_management" );

	if ( IsPlayer(player) )
		player thread personalUseBar( self );

	result = useHoldThinkLoop( player );
	assert ( isDefined( result ) );

	if ( isAlive( player ) )
	{
		//player _enableWeapon();
		player enable_weapon_wrapper( "deployable_weapon_management" );
		player unlink();
	}

	if ( !isDefined( self ) )
		return false;

	player.boxParams.inUse = false;
	player.boxParams.curProgress = 0;

	return ( result );
}

personalUseBar( object ) // self == player
{
	self endon( "disconnect" );

	useBar = createPrimaryProgressBar( 0, 25 );
	useBarText = createPrimaryProgressBarText( 0, 25 );
	useBarText setText( level.boxSettings[ object.boxType ].capturingString );

	lastRate = -1;
	while ( isReallyAlive( self ) && isDefined( object ) && self.boxParams.inUse && object.isUsable && !level.gameEnded )
	{
		if ( lastRate != self.boxParams.useRate )
		{
			if( self.boxParams.curProgress > self.boxParams.useTime)
				self.boxParams.curProgress = self.boxParams.useTime;

			useBar updateBar( self.boxParams.curProgress / self.boxParams.useTime, (1000 / self.boxParams.useTime) * self.boxParams.useRate );

			if ( !self.boxParams.useRate )
			{
				useBar hideElem();
				useBarText hideElem();
			}
			else
			{
				useBar showElem();
				useBarText showElem();
			}
		}    
		lastRate = self.boxParams.useRate;
		wait ( 0.05 );
	}

	useBar destroyElem();
	useBarText destroyElem();
}

useHoldThinkLoop( player )
{
	while( !level.gameEnded && isDefined( self ) && isReallyAlive( player ) && player useButtonPressed() && player.boxParams.curProgress < player.boxParams.useTime )
	{
		player.boxParams.curProgress += (50 * player.boxParams.useRate);

		if ( isDefined( player.objectiveScaler ) )
			player.boxParams.useRate = 1 * player.objectiveScaler;
		else
			player.boxParams.useRate = 1;

		if ( player.boxParams.curProgress >= player.boxParams.useTime )
			return ( isReallyAlive( player ) );

		wait 0.05;
	} 

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


default_canUseDeployable( boxEnt )	// self == player
{
	if( ( isDefined( boxEnt ) && boxEnt.owner == self || self maps\mp\alien\_prestige::prestige_getNoDeployables() == 1.0  ) && !isdefined( boxEnt.air_dropped ) )
	{
		return false;
	}
	return true;	
}

default_OnUseDeployable( boxent ) //self =a player
{
	self thread maps\mp\alien\_persistence::deployablebox_used_track( boxEnt );	
	maps\mp\alien\_utility::deployable_box_onuse_message( boxent );
}

default_tryUseDeployable( lifeId, BOX_TYPE ) // self == player
{
	result = self maps\mp\alien\_combat_resources::alien_beginDeployableViaMarker( lifeId, BOX_TYPE );

	if( ( !IsDefined( result ) || !result ) )
	{
		return false;
	}
	return true;
}

init_deployable( BOX_TYPE, boxconfig )
{
	if ( !IsDefined( level.boxSettings ) )
	{ 	
	   	level.boxSettings = [];
	}
	
	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	if ( !IsDefined( level.killStreakFuncs ) )
	{ 	
	   	level.killStreakFuncs = [];
	}
	
	//level.killStreakFuncs[ BOX_TYPE ] = ::default_tryUseDeployable;

	level.deployable_box[ BOX_TYPE ] = []; // storing each created box in their own array
}