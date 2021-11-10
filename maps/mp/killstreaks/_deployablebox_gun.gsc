#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

BOX_TYPE = "deployable_ammo";

// we depend on deployablebox being init'd first
init ()
{
	boxConfig = SpawnStruct();
	boxConfig.id				= "deployable_weapon_crate";
	boxConfig.weaponInfo		= "deployable_weapon_crate_marker_mp";
	boxConfig.modelBase			= "mp_weapon_crate";
	boxConfig.modelBombSquad	= "mp_weapon_crate_bombsquad";
	boxConfig.hintString		= &"KILLSTREAKS_HINTS_DEPLOYABLE_AMMO_USE";	//
	boxConfig.capturingString	= &"KILLSTREAKS_DEPLOYABLE_AMMO_TAKING";		//
	boxConfig.event				= "deployable_ammo_taken";	//
	boxConfig.streakName		= BOX_TYPE;	//
	boxConfig.splashName		= "used_deployable_ammo";	//	
	boxConfig.shaderName		= "compass_objpoint_deploy_ammo_friendly";
	boxConfig.headIconOffset	= 20;
	boxConfig.lifeSpan			= 90.0;	
	boxConfig.voGone			= "ammocrate_gone";
	boxConfig.useXP				= 50;	
	boxConfig.xpPopup			= "destroyed_ammo";
	boxConfig.voDestroyed		= "ammocrate_destroyed";
	boxConfig.deployedSfx		= "mp_vest_deployed_ui";
	boxConfig.onUseSfx			= "ammo_crate_use";
	boxConfig.onUseCallback		= ::onUseDeployable;
	boxConfig.canUseCallback	= ::canUseDeployable;
	boxConfig.noUseKillstreak	= true;
	boxConfig.useTime			= 1000;
	boxConfig.maxHealth			= 150;
	boxConfig.damageFeedback	= "deployable_bag";
	boxConfig.deathVfx			= loadfx( "vfx/gameplay/mp/killstreaks/vfx_ballistic_vest_death" );
	boxConfig.allowMeleeDamage	= true;
	boxConfig.allowGrenadeDamage = false;	// this doesn't seem dependable, like with c-4. Why isn't this in an object description?
	boxConfig.maxUses			= 4;
	
	boxConfig.minigunChance		= 20;	// 1 in minigunChance
	// artificially increase the odds for development	
	/#
		boxConfig.miniGunChance = 10;
	#/
	
	boxConfig.minigunWeapon		= "iw6_minigun_mp";
	boxConfig.ammoRestockCheckFreq	= 0.5;	// how often we check for new players
	boxConfig.ammoRestockTime	= 10.0;	// how often players can get restocked
	boxConfig.triggerRadius		= 200;
	boxConfig.triggerHeight		= 64;
	boxConfig.onDeployCallback = ::onBoxDeployed;
	boxConfig.canUseOtherBoxes	= false;
	
	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	level.killStreakFuncs[ BOX_TYPE ] = ::tryUseDeployable;
	
	level.deployableGunBox_BonusInXUses = RandomIntRange(1, boxConfig.minigunChance + 1);

	level.deployable_box[ BOX_TYPE ] = []; // storing each created box in their own array
	
	maps\mp\gametypes\sotf::defineChestWeapons();
}

tryUseDeployable( lifeId, streakName ) // self == player
{
	result = self maps\mp\killstreaks\_deployablebox::beginDeployableViaMarker( lifeId, BOX_TYPE );

	if( ( !IsDefined( result ) || !result ) )
	{
		return false;
	}
	
	if( !is_aliens() )
	{
		self maps\mp\_matchdata::logKillstreakEvent( BOX_TYPE, self.origin );
	}

	return true;
}

onUseDeployable( boxEnt )	// self == player
{
	level.deployableGunBox_BonusInXUses--;
	
	if ( level.deployableGunBox_BonusInXUses == 0 )
	{
		boxConfig = level.boxSettings[ boxEnt.boxType ];
		
		// For when we want to replace the minigun with something else for a specific level (e.g. Venom-X in dome_ns )
		if ( IsDefined( level.deployableBoxGiveWeaponFunc ) )
			[[ level.deployableBoxGiveWeaponFunc ]]( true );
		else
			giveGun( self, boxConfig.minigunWeapon );
		
		self maps\mp\gametypes\_missions::processChallenge( "ch_guninabox" ); 
		
		// reset gun chance, but make it very unlikely to get a second one
		level.deployableGunBox_BonusInXUses = RandomIntRange(boxConfig.minigunChance, boxConfig.minigunChance + 1);
	}
	else
	{
		giveRandomGun( self );
	}
}

onBoxDeployed( config )	// self == box
{
	self thread restockAmmoAura( config );
}

giveRandomGun( player )
{
	// this is adapted from SOTF / Hunted
	
	// give the player a new gun, but make sure he's not carrying a variant of it in either slot
	baseWeapons = [];
	foreach ( gun in player GetWeaponsListPrimaries() )
	{
		baseWeapons[ baseWeapons.size ] = GetWeaponBaseName( gun );
	}
	
	newWeapon = undefined;
	while ( true )
	{
		// getRandomWeapon returns an array
		newWeapon = maps\mp\gametypes\sotf::getRandomWeapon( level.weaponArray );
		newBaseWeapon = newWeapon["name"];
		
		// make sure he's not carrying this weapon already
		if ( !array_contains( baseWeapons, newBaseWeapon ) )
			break;
	}
	
	// get randomAttachments returns a full weapon string
	newWeapon = maps\mp\gametypes\sotf::getRandomAttachments( newWeapon );
	
	giveGun( player, newWeapon );
	
}

giveGun( player, newWeapon )
{
	weaponList = player GetWeaponsListPrimaries();
	
	primaryCount = 0;
	foreach ( weap in weaponList )
	{
		if ( !maps\mp\gametypes\_weapons::isAltModeWeapon( weap ) )
		{
			primaryCount++;
		}
	}
	
	if ( primaryCount > 1 )
	{
		playerPrimary = player.lastDroppableWeapon;
		if ( IsDefined( playerPrimary ) && playerPrimary != "none" )
		{
			player DropItem( playerPrimary );
		}
	}
	
	player _giveWeapon( newWeapon );
	player SwitchToWeapon( newWeapon );
	player GiveStartAmmo( newWeapon );
}

restockAmmoAura( config )	// self == box
{
	self endon( "death" );
	level endon( "game_eneded" );
	
	trigger = Spawn( "trigger_radius", self.origin, 0, config.triggerRadius, config.triggerHeight );
	trigger.owner = self;
	self thread maps\mp\gametypes\_weapons::deleteOnDeath( trigger );
	
	if ( IsDefined( self.moving_platform ) )
	{
		trigger EnableLinkTo();
		trigger LinkTo( self.moving_platform );
	}

	rangeSq = config.triggerRadius * config.triggerRadius;
	player = undefined;
	while ( true )
	{
		// trigger waittill( "trigger", player );
		touchingPlayers = trigger GetIsTouchingEntities( level.players );
		
		
		foreach ( player in touchingPlayers )
		{
			if ( IsDefined( player ) 
			    && !(self.owner IsEnemy( player ))
			    && self shouldAddAmmo( player ) )
			{
				// self thread addAmmoOverTime( player, rangeSq, config.ammoRestockTime );
				self addAmmo( player, config.ammoRestockTime );
			}
		}
		
		wait ( config.ammoRestockCheckFreq );
	}
}

shouldAddAmmo( player )	// self == box
{
	return ( !IsDefined( player.deployableGunNextAmmoTime )
		    || GetTime() >= player.deployableGunNextAmmoTime );
}

addAmmo( player, freq )	// self == box
{
	player.deployableGunNextAmmoTime = GetTime() + (freq * 1000);
	maps\mp\gametypes\_weapons::scavengerGiveAmmo( player );
	
	player maps\mp\gametypes\_damagefeedback::hudIconType( "boxofguns" );
}

addAmmoOverTime( player, rangeSq, freq )	// self == box
{
	self endon( "death" );
	player endon( "death" );
	player endon( "disconnect" );
	level endon( "game_ended" );
	
	while ( true )
	{
		self addAmmo( player );
		
		wait ( freq );
		
		if ( DistanceSquared( player.origin, self.origin ) > rangeSq )
		{
			break;
		}
	}
}


canUseDeployable(boxEnt)	// self == player
{
	if( is_aliens() && isDefined( boxEnt ) && boxEnt.owner == self && !isdefined( boxEnt.air_dropped ) )
	{
		return false;
	}	
	if( !is_aliens() )
	   return ( !self isJuggernaut() );
	else
		return true;
}