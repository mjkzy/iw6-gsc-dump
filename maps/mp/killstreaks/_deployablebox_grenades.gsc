#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

BOX_TYPE = "deployable_grenades";

// we depend on deployablebox being init'd first
init ()
{
	boxConfig = SpawnStruct();
	boxConfig.weaponInfo		= "deployable_vest_marker_mp";
	boxConfig.modelBase			= "afr_mortar_ammo_01";
	boxConfig.hintString		= &"KILLSTREAKS_HINTS_DEPLOYABLE_GRENADES_PICKUP";	//
	boxConfig.capturingString	= &"KILLSTREAKS_DEPLOYABLE_GRENADES_TAKING";		//
	boxConfig.event				= "deployable_grenades_taken";	//
	boxConfig.streakName		= BOX_TYPE;	//
	boxConfig.splashName		= "used_deployable_grenades";	//	
	boxConfig.shaderName		= "compass_objpoint_deploy_grenades_friendly";
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
	boxConfig.maxHealth			= 150;
	boxConfig.damageFeedback	= "deployable_bag";
	boxConfig.deathWeaponInfo	= "deployable_grenades_mp";
	boxConfig.deathVfx			= loadfx( "fx/explosions/grenadeexp_default" );
	boxConfig.deathDamageRadius	= 256;	 // these params taken from frag_grenade
	boxConfig.deathDamageMax	= 150;
	boxconfig.deathDamageMin	= 50;
	boxConfig.allowMeleeDamage	= true;
	boxConfig.allowGrenadeDamage = true;	// this doesn't seem dependable, like with c-4. Why isn't this in an object description?
	boxConfig.maxUses			= 3;
	
	level.boxSettings[ BOX_TYPE ] = boxConfig;
	
	level.killStreakFuncs[ BOX_TYPE ] = ::tryUseDeployableGrenades;

	level.deployable_box[ BOX_TYPE ] = []; // storing each created box in their own array
}

tryUseDeployableGrenades( lifeId, streakName ) // self == player
{
	result = self maps\mp\killstreaks\_deployablebox::beginDeployableViaMarker( lifeId, BOX_TYPE );

	if( ( !IsDefined( result ) || !result ) )
	{
		return false;
	}

	self maps\mp\_matchdata::logKillstreakEvent( BOX_TYPE, self.origin );

	return true;
}

onUseDeployable( boxEnt )	// self == player
{
	self refillExplosiveWeapons();
}

refillExplosiveWeapons()
{
	weaponList = self GetWeaponsListAll();
	
	if ( IsDefined( weaponList ) )
	{
		foreach ( weaponName in weaponList )
		{
			if ( maps\mp\gametypes\_weapons::isGrenade( weaponName )
			    || maps\mp\gametypes\_weapons::isOffhandWeapon( weaponName )
			    // && !maps\mp\_utility::isKillstreakWeapon( weaponName )
			   )
			{
				// for some reason, tactical grenades are getting 2
				self GiveStartAmmo( weaponName );
			}
		}
	}
	
	if ( self _hasPerk( "specialty_tacticalinsertion" ) && self getAmmoCount( "flare_mp" ) < 1 )
		self givePerkOffhand( "specialty_tacticalinsertion", false );	
}

canUseDeployable(boxEnt)	// self == player
{
	if( is_aliens() && isDefined( boxEnt ) && boxEnt.owner == self && !isdefined( boxEnt.air_dropped ) )
	{
		return false;
	}	
	return ( !self isJuggernaut() );
}