#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

//============================================
// 				constants
//============================================
CONST_AA_LAUNCHER_WEAPON		= "iw6_maaws_mp";
CONST_AA_LAUNCHER_WEAPON_CHILD	= "iw6_maawschild_mp";
CONST_AA_LAUNCHER_WEAPON_HOMING = "iw6_maawshoming_mp";
CONST_AA_LAUNCHER_WEAPON_AMMO	= 2;

//============================================
// 					init
//============================================
init()
{
	level.killstreakFuncs["aa_launcher"] = ::tryUseAALauncher;
	maps\mp\_laserGuidedLauncher::LGM_init( "vfx/gameplay/mp/killstreaks/vfx_maaws_split", "vfx/gameplay/mp/killstreaks/vfx_maaws_homing" );
}

//============================================
// 				Getters and Setters
//============================================
getAALauncherName()
{
	return CONST_AA_LAUNCHER_WEAPON;
}

getAALauncherChildName()
{
	return CONST_AA_LAUNCHER_WEAPON_CHILD;
}

getAALauncherHomingName()
{
	return CONST_AA_LAUNCHER_WEAPON_HOMING;
}

getAALauncherAmmo( player )
{
	AssertEx( IsDefined( player.pers[ "aaLauncherAmmo" ] ), "getAALauncherAmmo() called on player with no \"aaLauncherAmmo\" array key." );
	
	ksUniqueID = getAALauncherUniqueIndex( player );
	ammo = 0;
	if ( IsDefined( player.pers[ "aaLauncherAmmo" ][ ksUniqueID ] ) )
	{
		ammo = player.pers[ "aaLauncherAmmo" ][ ksUniqueID ];
	}
	return ammo;
}

clearAALauncherAmmo( player )
{
	ksUniqueID = getAALauncherUniqueIndex( player );
	player.pers[ "aaLauncherAmmo" ][ ksUniqueID ] = undefined;
}

setAALauncherAmmo( player, ammo, setAmmo )
{
	AssertEx( IsDefined( player.pers[ "aaLauncherAmmo" ] ), "setAALauncherAmmo() called on player with no \"aaLauncherAmmo\" array key." );
	
	// The player could also have two of the AA Launcher 
	// so ammo needs to be stored on a per killstreak instance
	ksUniqueID = getAALauncherUniqueIndex( player );	
	player.pers[ "aaLauncherAmmo" ][ ksUniqueID ] = ammo;
	
	if ( !IsDefined( setAmmo ) || setAmmo )
	{
		if ( player HasWeapon( getAALauncherName() ) )
		{
			player SetWeaponAmmoClip( getAALauncherName(), ammo );
		}
	}
}

getAALauncherUniqueIndex( player )
{
	AssertEx( IsDefined( player.killstreakIndexWeapon ), "getAALauncherAmmo() called on player with no killstreakIndexWeapon field" );
	
	return player.pers["killstreaks"][ player.killstreakIndexWeapon ].kID;
}

//============================================
// 				tryUseAALauncher
//============================================
tryUseAALauncher( lifeId, streakName )
{		
	return useAALauncher( self, lifeId );
}


//============================================
// 				useAALauncher - Returns true if the killstreak was used up
//============================================
useAALauncher( player, lifeId )
{
	// Ammo is persistent to handle round switching. If this is
	// the first use init the self.per[ "aaLauncherAmmo" ] array
	if ( !IsDefined( self.pers[ "aaLauncherAmmo" ] ) )
	{
		self.pers[ "aaLauncherAmmo" ] = [];
	}
	
	// The launcher persistent ammo count will only be empty in the
	// use function when the persistent ammo has yet to be set
	// so set it to the starting ammo
	if ( getAALauncherAmmo( player ) == 0 )
	{
		setAALauncherAmmo( self, CONST_AA_LAUNCHER_WEAPON_AMMO, false );
	}
	
	level thread monitorWeaponSwitch( player );
	level thread monitorLauncherAmmo( player );
	
	self thread maps\mp\_laserGuidedLauncher::LGM_firing_monitorMissileFire( getAALauncherName(), getAALauncherChildName(), getAALauncherHomingName() );
	
	result = false;
	msg = player waittill_any_return( "aa_launcher_switch", "aa_launcher_empty", "death", "disconnect" );
	
	if ( msg == "aa_launcher_empty" )
	{
		// The player is potentially still guiding the missiles at this point
		// so wait until the player switches out or the missiles are destroyed
		player waittill_any( "weapon_change", "LGM_player_allMissilesDestroyed", "death", "disconnect" );
		result = true;
 	}
	else
	{
		// In case death and aa_launcher_empty came on the same frame verify ammo
		if ( player HasWeapon( getAALauncherName() ) && player GetAmmoCount( getAALauncherName() ) == 0 )
		{
			clearAALauncherAmmo( player );
		}
		
		if ( getAALauncherAmmo( player ) == 0 )
		{
			result = true;
		}
	}
 	
	player notify( "aa_launcher_end" );
	
	self maps\mp\_laserGuidedLauncher::LGM_firing_endMissileFire();
	
	return result;
}


//============================================
// 			monitorWeaponSwitch
//============================================
monitorWeaponSwitch( player )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "aa_launcher_empty" );
	player endon( "aa_launcher_end" );
	
	currentWeapon = player GetCurrentWeapon();

	while( currentWeapon == getAALauncherName() )
	{	
		player waittill( "weapon_change", currentWeapon );
	}
	
	player notify( "aa_launcher_switch" );
}


//============================================
// 			monitorLauncherAmmo
//============================================
monitorLauncherAmmo( player )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "aa_launcher_switch" );
	player endon( "aa_launcher_end" );

	setAALauncherAmmo( player, getAALauncherAmmo( player ), true );
	
	while( true )
	{
		player waittill( "weapon_fired", weaponName );
		
		if ( weaponName != getAALauncherName() )
			continue;
		
		ammo = player GetAmmoCount( getAALauncherName() );
		setAALauncherAmmo( player, ammo, false );
		
		if( getAALauncherAmmo( player ) == 0 )
		{
			clearAALauncherAmmo( player );
			player notify( "aa_launcher_empty" );
			break;
		}
	}
}
