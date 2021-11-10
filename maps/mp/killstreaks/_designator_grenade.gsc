#include maps\mp\_utility;
#include common_scripts\utility;

// 2013-03-12 wsh
// shared utility for grenade-style designators
// init in your own ks script
// callbackFunc( killstreakName, designatorGrenadeEnt );
// We assume designator weapon can only be used once
designator_Start( killstreakName, designatorName, onTargetAcquiredCallback )
{
	AssertEx( IsDefined( onTargetAcquiredCallback ), "designator onTargetAcquiredCallback must be specified for " + designatorName );
	
	self endon ( "death" );
	self.marker = undefined;
	
	if ( self GetCurrentWeapon() == designatorName )
	{
		self thread designator_DisableUsabilityDuringGrenadePullback( designatorName );
		self thread designator_WaitForGrenadeFire( killstreakName, designatorName, onTargetAcquiredCallback );
		
		self designator_WaitForWeaponChange( designatorName );
		
		return ( !(self GetAmmoCount( designatorName ) && self HasWeapon( designatorName ) ) );
	}
	
	return false;
}

designator_DisableUsabilityDuringGrenadePullback( designatorName )	// self == player
{
	self endon( "death" );
	self endon( "disconnect" );
	
	usedWeaponName = "";
	while ( usedWeaponName != designatorName )
	{
		self waittill( "grenade_pullback", usedWeaponName );
	}
	
	self _disableUsability();
	self designator_EnableUsabilityWhenDesignatorFinishes();
}

designator_EnableUsabilityWhenDesignatorFinishes()	// self == player
{
	self endon( "death" );
	self endon( "disconnect" );
	// self notify( "beginMarkerTracking" );
	// self endon( "beginMarkerTracking" );

	self waittill_any( "grenade_fire", "weapon_change" );
	self _enableUsability();	
}

designator_WaitForGrenadeFire( killstreakName, designatorName, callbackFunc )	// self == player
{
	self endon( "designator_finished" );
	
	self endon( "spawned_player" );
	self endon( "disconnect" );
	
	designatorGrenade = undefined;
	usedWeaponName = "";
	while ( usedWeaponName != designatorName )
	{
		self waittill( "grenade_fire", designatorGrenade, usedWeaponName );
	}
	
	if ( IsAlive( self ) )
	{
		designatorGrenade.owner = self;
		designatorGrenade.weaponName = designatorName;

		self.marker = designatorGrenade;
		
		// maybe this should be in the callback?
		// marker PlaySoundToPlayer( "", self );
		
		self thread designator_OnTargetAcquired( killstreakName, designatorGrenade, callbackFunc );
	}
	else
	{
		designatorGrenade Delete();
	}
	
	self notify( "designator_finished" );
}

designator_WaitForWeaponChange( designatorName ) // self == player
{	
	self endon( "spawned_player" );
	self endon( "disconnect" );
	
	currentWeapon = self getCurrentWeapon();
	while ( currentWeapon == designatorName )
	{
		self waittill( "weapon_change", currentWeapon );
	}
	
	// this could have ended because we switched weapons normally
	// or because we used the killstreak
	if ( self GetAmmoCount( designatorName ) == 0 )
	{
		self designator_RemoveDesignatorAndRestorePreviousWeapon( designatorName );
	}
	
	self notify( "designator_finished" );
}

designator_RemoveDesignatorAndRestorePreviousWeapon( designatorName )
{
	if ( self HasWeapon( designatorName ) )
	{
		self TakeWeapon( designatorName );
		// self SwitchToWeapon( self getLastWeapon() );
	}
}

designator_OnTargetAcquired( killstreakName, designatorGrenade, onTargetAcquiredCallback )	// self == player
{
	designatorGrenade waittill( "missile_stuck", stuckTo );
	
	if ( IsDefined( designatorGrenade.owner ) )
	{
		self thread [[ onTargetAcquiredCallback ]]( killstreakName, designatorGrenade );
	}
	
	if ( IsDefined( designatorGrenade ) )
	{
		designatorGrenade Delete();
	}
}