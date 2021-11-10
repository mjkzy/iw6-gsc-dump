#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_horde_util;

CONST_LAST_STAND_TIME 				= 25;
CONST_LAST_STAND_COLOR 				= (0.804, 0.804, 0.035);
CONST_REVIVE_ENT_VERTICAL_OFFSET	= ( 0, 0, 20 );

/#
CONST_FORCE_LAST_STAND = false;
#/
	
Callback_PlayerLastStandHorde( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self registerLastStandParameter( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc );
	
	if( gameShouldEnd( self ) )
	{
		self.useLastStandParams = true;
		self _suicide();
		hordeEndGame();
		return;
	}
	
	if( !mayDoLastStandHorde( self ) )
	{
		self.useLastStandParams = true;
		self _suicide();
		return;
	}
	
	self.inLastStand 		= true;
	self.lastStand 			= true;
	self.ignoreme			= true;
	self.health 			= 1;
	
	self HudOutlineEnable( 1, false );
	self _disableUsability();
	self thread lastStandReviveHorde();
}

gameShouldEnd( player )
{
	/#
	if( CONST_FORCE_LAST_STAND )
		return false;
	#/
		
	isAnyPlayerStillActive = false;
	
	foreach( activePlayer in level.participants )
	{
		if( (player == activePlayer) && !hasAgentSquadMember(player) )
			continue;
		
		if( !isOnHumanTeam(activePlayer) )
			continue;
		
		if( isPlayerInLastStand(activePlayer) && !hasAgentSquadMember(activePlayer))
			continue;
		
		if( !IsDefined(activePlayer.sessionstate) || (activePlayer.sessionstate != "playing") )
			continue;
		
		isAnyPlayerStillActive = true;
		break;
	}
	
	return !isAnyPlayerStillActive;
}
	
hordeEndGame()
{
	level.finalKillCam_winner = level.enemyTeam;
	level thread maps\mp\gametypes\_gamelogic::endGame( level.enemyTeam , game[ "end_reason" ][ level.playerTeam+"_eliminated" ] );	
}
	
mayDoLastStandHorde( player )
{
	/#
	if( CONST_FORCE_LAST_STAND )
		return true;
	#/
		
	if( player touchingBadTrigger() )
		return false;	

	return true;
}

registerLastStandParameter( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc )
{
	lastStandParams 					= spawnStruct();
	lastStandParams.eInflictor 			= eInflictor;
	lastStandParams.attacker 			= attacker;
	lastStandParams.iDamage 			= iDamage;
	lastStandParams.attackerPosition 	= attacker.origin;
	lastStandParams.sMeansOfDeath 		= sMeansOfDeath;
	lastStandParams.sWeapon 			= sWeapon;
	lastStandParams.vDir 				= vDir;
	lastStandParams.sHitLoc 			= sHitLoc;
	lastStandParams.lastStandStartTime 	= getTime();
	
	if( IsDefined( attacker ) && IsPlayer( attacker ) && (attacker getCurrentPrimaryWeapon() != "none") )
		lastStandParams.sPrimaryWeapon = attacker getCurrentPrimaryWeapon();
	else
		lastStandParams.sPrimaryWeapon = undefined;
	
	self.lastStandParams = lastStandParams;
}

lastStandReviveHorde()
{
	self  endon( "death" );
	self  endon( "disconnect" );
	self  endon( "revive");
	level endon( "game_ended" );
	
	level notify ( "player_last_stand" );
	self notify( "force_cancel_placement" );
	
	level thread playSoundToAllPlayers( "mp_safe_team_last_stand" );
	level thread leaderDialog( "ally_down", level.playerTeam, "status" );
	level thread perkPenalty( self );
	
	self thread lastStandWaittillDeathHorde();
	self thread lastStandAmmoWacher();
	self thread lastStandKeepOverlayHorde();
	
	// create revive ent
	reviveEnt = spawn( "script_model", self.origin );
	reviveEnt setModel( "tag_origin" );
	reviveEnt setCursorHint( "HINT_NOICON" );
	reviveEnt setHintString( &"PLATFORM_REVIVE" );
	reviveEnt makeUsable();
	reviveEnt.inUse = false;
	reviveEnt.curProgress = 0;
	reviveEnt.useTime = level.lastStandUseTime;
	reviveEnt.useRate = 1;
	reviveEnt.id = "last_stand";
	reviveEnt.targetname = "revive_trigger";
	reviveEnt.owner = self;
	reviveEnt linkTo( self, "tag_origin", CONST_REVIVE_ENT_VERTICAL_OFFSET, (0,0,0) );
	reviveEnt thread maps\mp\gametypes\_damage::deleteOnReviveOrDeathOrDisconnect();
	
	// create revive HUD icon
	reviveIcon = newTeamHudElem( self.team );
	reviveIcon setShader( "waypoint_revive", 8, 8 );
	reviveIcon setWaypoint( true, true );
	reviveIcon SetTargetEnt( self );
	reviveIcon.color = (0.33, 0.75, 0.24);
	reviveIcon thread maps\mp\gametypes\_damage::destroyOnReviveEntDeath( reviveEnt );
	self thread lastStandUpdateReviveIconColorHorde( reviveEnt, reviveIcon, CONST_LAST_STAND_TIME );
	
	// create the bleed out timer
	self thread lastStandTimerHorde( CONST_LAST_STAND_TIME, reviveEnt );
	
	// wait to be revived
	reviveEnt thread reviveTriggerThinkHorde();
	reviveEnt thread lastStandWaittillLifeRecived();
	
	reviveEnt endon ( "death" );
	
	wait( CONST_LAST_STAND_TIME );
	
	while( IsDefined(reviveEnt.inUse) && reviveEnt.inUse )
	{
		waitframe();
	}
	
	level thread leaderDialog( "ally_dead", level.playerTeam, "status" );
	
	self HudOutlineDisable();
	self _suicide();
}

reviveTriggerThinkHorde()
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	while( true )
	{
		self makeUsable();
		self waittill ( "trigger", player );
		self makeUnUsable();
		
		self.curProgress = 0;
		self.inUse = true;
		self.owner.beingRevived = true;
		
		player freezecontrols( true );
		player _disableWeapon();
		player.isReviving = true;
		
		result = maps\mp\gametypes\_damage::useHoldThinkLoop( player );
		
		self.inUse = false;
		if( IsDefined( self.owner ) ) // self.owner could be undefined if the player being revived disconnects during the revive
		{
			self.owner.beingRevived = false;
		}
		
		if( IsDefined( player ) && isReallyAlive( player ) )
		{
			player freezecontrols( false );
			player _enableWeapon();
			player.isReviving = false;
			
			if( IsDefined( result ) && result ) // result will be undefined if the player being revived disconnected
			{
				player thread maps\mp\gametypes\_hud_message::SplashNotifyDelayed( "horde_reviver" );
				player thread maps\mp\perks\_perkfunctions::setLightArmor( 850 );
				
				if( IsPlayer(player) )
				{
					awardHordeRevive( player );
				}
				else if( IsDefined(player.owner) && IsPlayer(player.owner) && (player.owner != self.owner) )
				{
					// increment a player's revive stat when his agent revives another player
					awardHordeRevive( player.owner );
				}
			}
			
			if( !IsDefined( result ) )
			{
				player maps\mp\gametypes\_gameobjects::updateUIProgress( self, false ); // clear the "reviving" bar because that player disconnected
			}
			
		}
		
		if( IsDefined( result ) && result )
		{
			self.owner notify ( "revive_trigger", player );
			break;
		}
	}
}

lastStandWaittillLifeRecived()
{
	self endon( "death" );
	self endon( "game_ended" );
	
	player = self.owner;
	
	player waittill( "revive_trigger", reviver );
	
	if ( IsDefined( reviver ) && IsPlayer( reviver ) && reviver != player )
		player thread maps\mp\gametypes\_hud_message::playerCardSplashNotify( "revived", reviver );

	player lastStandRespawnPlayerHorde( self );
}

lastStandRespawnPlayerHorde( reviveEnt )
{
	self notify ( "revive" );
	
	self.lastStand 			= undefined;
	self.inLastStand		= false;
	self.headicon 			= "";
	self.health 			= self.maxHealth;
	self.moveSpeedScaler 	= 1;
	self.ignoreme			= false;
	self.beingRevived 		= false;
	
	if( self _hasPerk( "specialty_lightweight" ) )
	{
		self.moveSpeedScaler = lightWeightScalar();
	}
	
	self HudOutlineDisable();
	self LastStandRevive();
	self setStance( "crouch" );
	self _enableUsability();
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();	
	self clearLowerMessage( "last_stand" );
	self givePerk( "specialty_pistoldeath", false );
	
	if( !CanSpawn(self.origin) )
	{
		maps\mp\_movers::unresolved_collision_nearest_node( self, false );
	}
	
	reviveEnt delete();
}

lastStandWaittillDeathHorde()
{
	self  endon( "disconnect" );
	self  endon( "revive" );
	level endon( "game_ended" );
	
	self waittill( "death" );

	self.lastStand 			= undefined;
	self.inLastStand 		= false;
	self.ignoreme			= false;
}

lastStandKeepOverlayHorde()
{
	self  endon( "death" );
	self  endon( "disconnect" );
	self  endon( "revive" );
	level endon( "game_ended" );
	
	// keep the health overlay going by making code think the player is getting damaged
	while( true )
	{
		self.health = 2;
		waitframe();
		self.health = 1;
		waitframe();
	}
}

lastStandUpdateReviveIconColorHorde( reviveEnt, reviveIcon, bleedOutTime )
{
	self  endon( "death" );
	self  endon( "disconnect" );
	self  endon( "revive" );
	level endon( "game_ended" );
	reviveEnt endon( "death" );
	
	self playDeathSound();

	wait bleedOutTime / 3;
	reviveIcon.color = (1.0, 0.64, 0.0);
	
	while ( reviveEnt.inUse )
		wait ( 0.05 );
	
	self playDeathSound();	
	
	wait bleedOutTime / 3;
	reviveIcon.color = (1.0, 0.0, 0.0);

	while ( reviveEnt.inUse )
		wait ( 0.05 );

	self playDeathSound();
}

lastStandTimerHorde( bleedOutTime, reviveEnt )
{	
	self endon( "disconnect" );
	
	timer_offset = 90;
	if ( !issplitscreen() )
		timer_offset = 135;

	timer = self maps\mp\gametypes\_hud_util::createTimer( "hudsmall", 1.0 );
	timer maps\mp\gametypes\_hud_util::setPoint( "CENTER", undefined, 0, timer_offset );
	timer.label = &"MP_HORDE_BLEED_OUT";
	timer.color = CONST_LAST_STAND_COLOR;
	timer.archived = false;
	timer.showInKillcam = false;
	timer setTimer( bleedOutTime - 1 );
	
	reviveEnt waittill ( "death" );
		
	if( !IsDefined(timer) )
		return;
		
	timer notify( "destroying" );
	timer destroyElem();
}

lastStandAmmoWacher()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "revive" );
	level endon( "game_ended" );
	
	while( true )
	{
		wait( 1.5 );
		
		currentWeapon = self GetCurrentPrimaryWeapon();
		
		if( !maps\mp\gametypes\_weapons::isPrimaryWeapon( currentWeapon ) )
			continue;
		
		ammoStock = self GetWeaponAmmoStock( currentWeapon );
		clipSize = WeaponClipSize( currentWeapon );
		
		if( ammoStock < clipSize )
			self setWeaponAmmoStock( currentWeapon, clipSize );
	}
}

perkPenalty( player )
{
	player  endon( "disconnect" );
	level endon( "game_ended" );
	
	if( !IsPlayer(player) )
		return;
	
	while( isPlayerInLastStand(player) && (player.horde_perks.size > 0) )
	{	
		// Grab the perk name and index
		perkName  = player.horde_perks[player.horde_perks.size - 1]["name"];
		perkTableIndex = player.horde_perks[player.horde_perks.size - 1]["index"];
		
		player thread flashPerk( perkTableIndex ); 
		
		result = player waittill_any_return_no_endon_death( "remove_perk", "death", "revive" );
		
		if( result == "death" )
			return;
		
		if( result == "revive" )
		{	
			if ( IsDefined( player.flashingPerkIndex ) )
			{
				// See if we are already flashing the perk before we tell it to stop
				if( player.flashingPerkIndex == perkTableIndex )
				{			
					// Sending the index tells LUI to stop flashing the perk, if it was previously flashing
					player SetClientOmnvar( "ui_horde_update_perk", perkTableIndex );
					player.flashingPerkIndex = undefined;
				}
			}

			return;
		}
		
		if( result == "remove_perk" )
		{
			// Sending back a negative index tells LUI to remove the existing perk
			player SetClientOmnvar( "ui_horde_update_perk", perkTableIndex * -1 );
			player _unsetPerk( perkName );
			
			// Make sure we remove it from the array
			player.horde_perks = array_remove_perk( player.horde_perks, perkName );
		}
	}
}

array_remove_perk ( perkArray, perkName )
{
	newPerkArray = [];
	
	foreach( subArray in perkArray )
	{
		if ( subArray["name"] != perkName )
			newPerkArray[ newPerkArray.size ] = subArray;
	}

	return newPerkArray;	
}

flashPerk( perkTableIndex )
{
	self endon ("death");
	self endon ("revive");
	
	wait(0.5);

	// Sending the index tells LUI to start flashing, if it was previously created
	self SetClientOmnvar( "ui_horde_update_perk", perkTableIndex );
	self.flashingPerkIndex = perkTableIndex;
	
	wait(8);
	
	self notify( "remove_perk" );
}
