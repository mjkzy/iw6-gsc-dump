#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;


//============================================
// 				constants
//============================================
CONST_UPLINK_WEAPON 	= "killstreak_uplink_mp";
CONST_UPLINK_TIME		= 30;
CONST_UPLINK_MIN 		= 0;
CONST_EYES_ON 			= 1;
CONST_UPLINK_FULL_RADAR	= 2;
CONST_UPLINK_FAST_PING	= 3;
CONST_DIRECTIONAL		= 4;
CONST_UPLINK_MAX 		= 4;
CONST_FAST_SWEEP		= "fast_radar";
CONST_NORMAL_SWEEP		= "normal_radar";
CONST_HEAD_ICON_OFFSET	= 42;
CONST_EMP_VFX			= "emp_stun";
CONST_EMP_VFX_TAG		= "tag_origin";

//============================================
// 				init
//============================================
init()
{		
	level.uplinks = [];
	level.killstreakFuncs["uplink"] 		= ::tryUseUpLink;
	level.killstreakFuncs["uplink_support"] = ::tryUseUpLink;
	
	level.comExpFuncs = [];
	level.comExpFuncs[ "giveComExpBenefits" ]      = ::giveComExpBenefits;
	level.comExpFuncs[ "removeComExpBenefits" ]    = ::removeComExpBenefits;
	level.comExpFuncs[ "getRadarStrengthForTeam" ] = ::getRadarStrengthForTeam;
	level.comExpFuncs[ "getRadarStrengthForPlayer" ] = ::getRadarStrengthForPlayer;
	
	unblockTeamRadar( "axis" );
	unblockTeamRadar( "allies" );
	
	level thread upLinkTracker();
	level thread uplinkUpdateEyesOn();
	
	config = spawnStruct();
	config.streakName				= "uplink";
	config.weaponInfo				= "ims_projectile_mp";
	config.modelBase				= "mp_satcom";
	// config.modelDestroyed			= "placeable_barrier_destroyed";
	config.modelPlacement			= "mp_satcom_obj";
	config.modelPlacementFailed		= "mp_satcom_obj_red";
	config.modelBombSquad			= "mp_satcom_bombsquad";
	config.hintString				= &"KILLSTREAKS_HINTS_UPLINK_PICKUP";	
	config.placeString				= &"KILLSTREAKS_HINTS_UPLINK_PLACE";	
	config.cannotPlaceString		= &"KILLSTREAKS_HINTS_UPLINK_CANNOT_PLACE";
	config.headIconHeight			= CONST_HEAD_ICON_OFFSET;
	config.splashName				= "used_uplink";	
	config.lifeSpan					= CONST_UPLINK_TIME;
	// config.goneVO					= "satcom_gone";
	config.maxHealth				= 500;
	config.allowMeleeDamage			= true;
	config.allowEmpDamage			= true;
	config.damageFeedback			= "trophy";
	config.xpPopup					= "destroyed_uplink";
	config.destroyedVO				= "satcom_destroyed";
	//config.onCreateDelegate			= ::createObject;
	config.placementHeightTolerance	= 30.0;
	config.placementRadius			= 16.0;
	config.placementOffsetZ			= 16;
	config.onPlacedDelegate			= ::onPlaced;
	config.onCarriedDelegate		= ::onCarried;
	config.placedSfx				= "mp_killstreak_satcom_deploy";
	config.activeSfx				= "mp_killstreak_satcom_loop";
	config.onMovingPlatformCollision = ::uplink_override_moving_platform_death;
	// config.onDamagedDelegate		= ::onDamaged;
	config.onDeathDelegate			= ::onDeath;
	config.onDestroyedDelegate		= ::onDestroyed;	// when killed by a player
	config.deathVfx					= loadfx( "vfx/gameplay/mp/killstreaks/vfx_ballistic_vest_death" );
	// config.onDeactivateDelegate		= ::onDeactivated;
	// config.onActivateDelegate		= ::onActivated;
	
	level.placeableConfigs[ "uplink" ] = config;
	level.placeableConfigs[ "uplink_support" ] = config;
}	


//============================================
// 				upLinkTracker
//============================================
upLinkTracker()
{
	level endon ( "game_ended" );
	
	while( true )
	{
		level waittill( "update_uplink" );
		level childthread updateAllUplinkThreads();
	}
}

// 2013-08-27 wallace: I wonder if it would be ok to just update the uplink strength for a particular player/team on notify
// since the uplinks know who they belong to
updateAllUplinkThreads()
{
	self notify("updateAllUplinkThreads");
	self endon("updateAllUplinkThreads");

	level childthread comExpNotifyWatcher();
	
	if( level.teamBased )
	{
		level childthread updateTeamUpLink( "axis" );
		level childthread updateTeamUpLink( "allies" );
	}
	else
	{
		level childthread updatePlayerUpLink();
	}
	
	// Update the the UpLink for Com Specialist players
	level childthread updateComExpUpLink();
}

comExpNotifyWatcher()
{
	// Guarantee that the previous update functions have finished before we proceed into updating com exp
	teamsFinished = [];
	
	if ( !level.teamBased )
		level waittill ( "radar_status_change_players" );
	else
	{
		while ( teamsFinished.size < 2 )
		{
			level waittill ( "radar_status_change", team );
			teamsFinished[ teamsFinished.size ] = team;
		}
	}
	
	level notify ( "start_com_exp" );
}

	
//============================================
// 				updateTeamUpLink
//============================================
updateTeamUpLink( team )
{
	currentStrengthForTeam	= getRadarStrengthForTeam( team );
	shouldBeEyesOn			= ( currentStrengthForTeam == CONST_EYES_ON );
	shouldBeFullRadar		= ( currentStrengthForTeam >= CONST_UPLINK_FULL_RADAR );
	shouldBeFastSweep		= ( currentStrengthForTeam >= CONST_UPLINK_FAST_PING );
	shouldBeDirectional 	= ( currentStrengthForTeam >= CONST_DIRECTIONAL );
	
	if( shouldBeFullRadar )
	{
		unblockTeamRadar( team );
	}
	
	if( shouldBeFastSweep )
	{
		level.radarMode[team] = CONST_FAST_SWEEP;
	}
	else
	{
		level.radarMode[team] = CONST_NORMAL_SWEEP;
	}
	
	foreach( player in level.participants )
	{
		if ( !IsDefined(player) )
			continue;
		
		if( player.team != team )
			continue;
		
		player.shouldBeEyesOn = shouldBeEyesOn;
		player SetEyesOnUplinkEnabled( shouldBeEyesOn );
		player.radarMode = level.radarMode[player.team];
		player.radarShowEnemyDirection = shouldBeDirectional;				
		player updateSatcomActiveOmnvar( team );
			
		wait(0.05);		// Setting all these player variables can get expensive, so spread it out over multiple frames
	}
	
	setTeamRadar( team, shouldBeFullRadar );
	level notify( "radar_status_change", team );
}


//============================================
// 				updatePlayerUpLink
//============================================
updatePlayerUpLink()
{
	foreach ( player in level.participants )
	{
		if ( !IsDefined(player) )
			continue;
		
		currentStrengthForSelf	= getRadarStrengthForPlayer( player );
		setPlayerRadarEffect( player, currentStrengthForSelf );
		player updateSatcomActiveOmnvar();
		
		wait(0.05);		// Setting all these player variables can get expensive, so spread it out over multiple frames
	}
	
	level notify( "radar_status_change_players" );
}


//============================================
// 				updateComExpUpLink
//============================================
updateComExpUpLink()
{
	level waittill ( "start_com_exp" );
	
	foreach ( player in level.participants )
	{
		if ( !IsDefined(player) )
			continue;
		
		player giveComExpBenefits();
		
		wait(0.05);		// Setting all these player variables can get expensive, so spread it out over multiple frames
	}
}

// give/remove ComExpBenefits
// encapsulate the innerworkings of uplink system for the perk's set/unset functions
giveComExpBenefits()	// self == player
{
	if( ( self _hasPerk( "specialty_comexp" ) ) )
	{
		radarStrength = getRadarStrengthForComExp( self );
		setPlayerRadarEffect( self, radarStrength );
		self updateSatcomActiveOmnvar();
	}
}

// since multiple functions are trying to set the ui_satcom_active omnvar, I've made it one function that will handle the wiretap perk functionality
//	this will make sure we always get it right and get the correct amount of radar
updateSatcomActiveOmnvar( team ) // self == player
{
	radarStrength = 0;
	if( IsDefined( team ) )
		radarStrength = getRadarStrengthForTeam( team );
	else
		radarStrength = getRadarStrengthForPlayer( self );
	
	if( self _hasPerk( "specialty_comexp" ) )
		radarStrength = getRadarStrengthForComExp( self );
		
	if( radarStrength > CONST_UPLINK_MIN )
		self SetClientOmnvar( "ui_satcom_active", true );
	else
		self SetClientOmnvar( "ui_satcom_active", false );
}

removeComExpBenefits()	// self == player
{
	// mainly for clearing out radarMode, the other stuff will get set by the appropriate update function
	self.shouldBeEyesOn = false;
	self SetEyesOnUplinkEnabled( false );	
	self.radarShowEnemyDirection = false;
	self.radarMode = CONST_NORMAL_SWEEP;
	self.hasRadar = false;
	self.isRadarBlocked = false;
}

setPlayerRadarEffect( player, radarStrength )
{
	shouldBeEyesOn		= ( radarStrength == CONST_EYES_ON );
	shouldBeFullRadar	= ( radarStrength >= CONST_UPLINK_FULL_RADAR );
	shouldBeFastSweep	= ( radarStrength >= CONST_UPLINK_FAST_PING );
	shouldBeDirectional = ( radarStrength >= CONST_DIRECTIONAL );

	player.shouldBeEyesOn = shouldBeEyesOn;
	player SetEyesOnUplinkEnabled( shouldBeEyesOn );	
	player.radarShowEnemyDirection = shouldBeDirectional;
	player.radarMode = CONST_NORMAL_SWEEP;
	player.hasRadar = shouldBeFullRadar;
	player.isRadarBlocked = false;
	
	if( shouldBeFastSweep )
	{
		player.radarMode = CONST_FAST_SWEEP;
	}
}

//============================================
// 				tryUseUpLink
//============================================
tryUseUpLink( lifeId, streakName )
{
	result = self maps\mp\killstreaks\_placeable::givePlaceable( streakName );
	
	if( result )
	{
		// we want both to log to the same event?
		self maps\mp\_matchdata::logKillstreakEvent( "uplink", self.origin );
	}
	
	// we're done carrying for sure and sometimes this might not get reset
	// this fixes a bug where you could be carrying and have it in a place where it won't plant, get killed, now you can't scroll through killstreaks
	self.isCarrying = undefined;
	
	return result;
}

onCarried( streakName )	// self == obj
{
	entNum = self GetEntityNumber();
	if ( IsDefined( level.uplinks[ entNum ] ) )
	{
		self stopUplink();
	}
}

onPlaced( streakName )	// self == obj
{
	config = level.placeableConfigs[ streakName ];
	
	self.owner notify( "uplink_deployed" );
	
	self SetModel( config.modelBase );
	
	self.immediateDeath	= false;
	self SetOtherEnt(self.owner);
	self make_entity_sentient_mp( self.owner.team, true );
	self.config = config;
	
	self startUplink( true );

	self thread watchEMPDamage();

	// 2013-07-25 wallace: not sure if we need this still
	/*
	wait( 0.75 );
	
	if( IsDefined(self) && (self touchingBadTrigger()) )
		self notify( "death" );
	*/
}

// Operations that need to be done when the uplink is first spawned
// AND when it resumes from 
startUplink( playOpenAnim )
{
	addUplinkToLevelList( self );
	
	self thread playUplinkAnimations( playOpenAnim );
		
	// play operation sound
	self PlayLoopSound( self.config.activeSfx );
}

stopUplink()
{
	self maps\mp\gametypes\_weapons::stopBlinkingLight();
	
	self ScriptModelClearAnim();
	
	if ( IsDefined( self.bombSquadModel ) )
	{
		self.bombSquadModel ScriptModelClearAnim();
	}
	
	removeUplinkFromLevelList( self );
	
	self StopLoopSound();
}

#using_animtree( "animated_props" );

//============================================
// 			playUplinkAnimations
//============================================
playUplinkAnimations( playOpenAnim )	// self = uplink
{
	self endon( "emp_damage" );
	self endon( "death" );
	self endon( "carried" );
	
	if ( playOpenAnim )
	{
		waitTime	= GetNotetrackTimes( %Satcom_killStreak, "stop anim" );
		animLength 	= GetAnimLength( %Satcom_killStreak );
		
		self ScriptModelPlayAnim( "Satcom_killStreak" );
		if ( IsDefined( self.bombSquadModel ) )
		{
			self.bombSquadModel ScriptModelPlayAnim( "Satcom_killStreak" );
		}
		
		wait( waitTime[0] * animLength );
	}
	
	self ScriptModelPlayAnim( "Satcom_killStreak_idle" );
	if ( IsDefined( self.bombSquadModel ) )
	{
		self.bombSquadModel ScriptModelPlayAnim( "Satcom_killStreak_idle" );
	}
	
	// play vfx
	self thread maps\mp\gametypes\_weapons::doBlinkingLight( "tag_fx" );
}

onDestroyed( streakName, attacker, owner, sMeansOfDeath )
{
	attacker notify( "destroyed_equipment" );
}

onDeath( streakName, attacker, owner, sMeansOfDeath )
{
	self maps\mp\gametypes\_weapons::stopBlinkingLight();
	
	self maps\mp\gametypes\_weapons::equipmentDeathVfx();
	
	removeUplinkFromLevelList( self );
	
	self ScriptModelClearAnim();
	
	if(!self.immediateDeath)
	{
		wait( 3.0 );
	}
	
	self maps\mp\gametypes\_weapons::equipmentDeleteVfx();
}

//============================================
// 			addUplinkToLevelList
//============================================
addUplinkToLevelList( obj )
{
	entNum = obj GetEntityNumber();
	level.uplinks[entNum] = obj;
	level notify( "update_uplink" );
}


//============================================
// 			removeUplinkFromLevelList
//============================================
removeUplinkFromLevelList( obj )
{
	entNum = obj GetEntityNumber();
	level.uplinks[ entNum ] = undefined;
	level notify( "update_uplink" );
}


//============================================
// 			getRadarStrengthForTeam
//============================================
getRadarStrengthForTeam( team )
{
	currentRadarStrength = 0;
	
	foreach( satellite in level.uplinks )
	{
		if( IsDefined(satellite) && (satellite.team == team) )
			currentRadarStrength++;
	}
	
	// give eyes-on when heli sniper is in the air
	if ( currentRadarStrength == 0
	    && IsDefined( level.heliSniperEyesOn )
	    && level.heliSniperEyesOn.team == team
	   )
	{
		currentRadarStrength++;
	}
	
	return clamp( currentRadarStrength, CONST_UPLINK_MIN, CONST_UPLINK_MAX );
}

//============================================
// 			getRadarStrengthForPlayer
//============================================
getRadarStrengthForPlayer( player )
{
	currentRadarStrength = 0;
	
	foreach( satellite in level.uplinks )
	{
		if( IsDefined( satellite ) )
		{
			// not sure if it's safe to remove an item while we're iterating through it
			if ( IsDefined( satellite.owner ) )
			{
				if ( satellite.owner.guid == player.guid)
					currentRadarStrength++;
			}
			else
			{
				// if the owner has disconnected, stop tracking this satellite
				entNum = satellite GetEntityNumber();
				level.uplinks[ entNum ] = undefined;
			}
		}
	}
	
	// in FFA, eyes-on is useless, so automatically bump the benefit to tier 2
	if ( !level.teamBased && currentRadarStrength > 0 )
		currentRadarStrength++;
	
	return clamp( currentRadarStrength, CONST_UPLINK_MIN, CONST_UPLINK_MAX );
}


//============================================
// 			getRadarStrengthForComExp
//============================================
getRadarStrengthForComExp( player )
{
	currentRadarStrength = 0;
	
	// Add to the radar strength regardless of which team places down the SAT COM
	foreach( satellite in level.uplinks )
	{
		if( IsDefined(satellite) )
			currentRadarStrength++;
	}
	
	// in FFA, eyes-on is useless, so automatically bump the benefit to tier 2
	if ( !level.teamBased && currentRadarStrength > 0 )
		currentRadarStrength++;
	
	return clamp( currentRadarStrength, CONST_UPLINK_MIN, CONST_UPLINK_MAX );
}

uplink_override_moving_platform_death( data )
{
	self.immediateDeath = true;
	self notify( "death" );
}

watchEMPDamage()
{
	// self endon( "carried" );
	self endon( "death" );
	level endon( "game_ended" );

	while( true )
	{
		// this handles any flash or concussion damage
		self waittill( "emp_damage", attacker, duration );
		
		self maps\mp\gametypes\_weapons::equipmentEmpStunVfx();
		
		self stopUplink();
		
		wait( duration );
		
		self startUplink( false );
	}
}

uplinkUpdateEyesOn()
{
	level endon( "game_ended" );
	
	while (true)
	{
		level waittill( "player_spawned", player );
		
		eyesOn = ( IsDefined( player.shouldBeEyesOn ) && player.shouldBeEyesOn );
		player SetEyesOnUplinkEnabled( eyesOn );
	}
}