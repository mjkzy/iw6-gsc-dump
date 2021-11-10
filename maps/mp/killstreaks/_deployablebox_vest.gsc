#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

BOX_TYPE = "deployable_vest";

// we depend on deployablebox being init'd first
init ()
{
	boxConfig = SpawnStruct();
	boxConfig.id				= "deployable_vest";
	boxConfig.weaponInfo		= "deployable_vest_marker_mp";
	boxConfig.modelBase			= "prop_ballistic_vest_iw6";
	boxConfig.modelBombSquad	= "prop_ballistic_vest_iw6_bombsquad";
	boxConfig.hintString		= &"KILLSTREAKS_HINTS_LIGHT_ARMOR_PICKUP";	
	boxConfig.capturingString	= &"KILLSTREAKS_BOX_GETTING_VEST";	
	boxConfig.event				= "deployable_vest_taken";	
	boxConfig.streakName		= BOX_TYPE;	
	boxConfig.splashName		= "used_deployable_vest";	
	boxConfig.shaderName		= "compass_objpoint_deploy_friendly";
	boxConfig.headIconOffset	= 20;
	boxConfig.lifeSpan			= 90.0;	
	boxConfig.useXP				= 50;	
	boxConfig.xpPopup			= "destroyed_vest";
	boxConfig.voDestroyed		= "ballistic_vest_destroyed";
	boxConfig.deployedSfx		= "mp_vest_deployed_ui";
	boxConfig.onUseSfx			= "ammo_crate_use";
	boxConfig.onUseCallback		= ::onUseDeployable;
	boxConfig.canUseCallback	= ::canUseDeployable;
	boxConfig.useTime			= 1000;
	boxConfig.maxHealth			= 300;
	boxConfig.damageFeedback	= "deployable_bag";
	boxConfig.deathVfx			= loadfx( "vfx/gameplay/mp/killstreaks/vfx_ballistic_vest_death" );
	boxConfig.allowMeleeDamage	= true;
	boxConfig.allowGrenadeDamage = false;	// this doesn't seem dependable, like with c-4. Why isn't this in an object description?
	boxConfig.maxUses			= 4;
	boxConfig.canUseOtherBoxes	= false;
	
	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	level.killStreakFuncs[ BOX_TYPE ] = ::tryUseDeployableVest;
	
	level.deployable_box[ BOX_TYPE ] = []; // storing each created box in their own array
}

tryUseDeployableVest( lifeId, streakName ) // self == player
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

	// we used to give the player a vest/health after we deployed the box
	// instead, we automatically call onUseCallback once in _deployabox.gsc
	// (because we don't want the player to be able to manually use vest again until he dies
	
	return true;
}

canUseDeployable(boxEnt)	// self == player
{
	if(!is_aliens() )
	{
		return ( !(self maps\mp\perks\_perkfunctions::hasLightArmor()) && !self isJuggernaut() );
	}
	if( isDefined( boxEnt ) && boxEnt.owner == self && !isdefined( boxEnt.air_dropped ) )
	{
		return false;
	}
	return !self isJuggernaut();
	
}

onUseDeployable( boxEnt )	// self == player
{
	if ( is_aliens() )
	{
		existing_armor = 0;
		if( isDefined( self.lightArmorHP ))
		{
			existing_armor = self.lightArmorHP;
		}
		
		assertex ( isDefined( boxEnt.upgrade_rank ), "No upgrade rank defined for deployable armor" );
		
		armor_to_give = get_adjusted_armor(existing_armor,boxEnt.upgrade_rank );
		self maps\mp\perks\_perkfunctions::setLightArmor( armor_to_give );
		
		self notify( "enable_armor" );
	}		
	else
	{
		self maps\mp\perks\_perkfunctions::setLightArmor();
	}
}

get_adjusted_armor( existing_armor,rank)
{
	if( existing_armor + level.deployablebox_vest_rank[rank] > level.deployablebox_vest_max)
	{
		return level.deployablebox_vest_max;
	}
	
	return existing_armor + level.deployablebox_vest_rank[rank];
}