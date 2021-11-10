#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

BOX_TYPE = "deployable_juicebox";

// we depend on deployablebox being init'd first
init ()
{
	boxConfig = SpawnStruct();
	boxConfig.weaponInfo		= "deployable_vest_marker_mp";
	boxConfig.modelBase			= "afr_mortar_ammo_01";
	boxConfig.hintString		= &"KILLSTREAKS_HINTS_DEPLOYABLE_JUICEBOX_PICKUP";	//
	boxConfig.capturingString	= &"KILLSTREAKS_DEPLOYABLE_JUICEBOX_TAKING";		//
	boxConfig.event				= "deployable_juicebox_taken";	//
	boxConfig.streakName		= BOX_TYPE;	//
	boxConfig.splashName		= "used_deployable_juicebox";	//	
	boxConfig.shaderName		= "compass_objpoint_deploy_juiced_friendly";
	boxConfig.headIconOffset	= 25;
	boxConfig.lifeSpan			= 90.0;	
	boxConfig.useXP				= 50;	
	boxConfig.xpPopup			= "destroyed_vest";
	boxConfig.voDestroyed		= "ballistic_vest_destroyed";
	boxConfig.deployedSfx		= "mp_vest_deployed_ui";
	boxConfig.onUseSfx			= "ammo_crate_use";
	boxConfig.onUseCallback		= ::onUseDeployable;
	boxConfig.canUseCallback	= ::canUseDeployable;
	boxConfig.useTime			= 500;
	boxConfig.maxHealth			= 300;
	boxConfig.damageFeedback	= "deployable_bag";
	boxConfig.deathWeaponInfo	= "deployable_ammo_mp";
	boxConfig.deathVfx			= loadfx( "vfx/gameplay/mp/killstreaks/vfx_ballistic_vest_death" );
	boxConfig.allowMeleeDamage	= true;
	boxConfig.allowGrenadeDamage = false;	// this doesn't seem dependable, like with c-4. Why isn't this in an object description?
	boxConfig.maxUses			= 4;
	
	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	level.killStreakFuncs[ BOX_TYPE ] = ::tryUseDeployableJuiced;

	level.deployable_box[ BOX_TYPE ] = []; // storing each created box in their own array
}

tryUseDeployableJuiced( lifeId, streakName ) // self == player
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
	if ( is_aliens() )
	{
		assert(  isDefined( boxEnt.upgrade_rank) , "No rank specified for deployable juicebox" );
		self thread maps\mp\perks\_perkfunctions::setJuiced( level.deployablebox_juicebox_rank[boxEnt.upgrade_rank] );
	}
	else
	{
		self thread maps\mp\perks\_perkfunctions::setJuiced( 15 );
	}
}

canUseDeployable(boxEnt)	// self == player
{
	if( is_aliens() && isDefined( boxEnt ) && boxEnt.owner == self && !isdefined( boxEnt.air_dropped ) )
	{
		return false;
	}	
	
	return ( !(self isJuggernaut()) && !(self maps\mp\perks\_perkfunctions::hasJuiced()) );
}


