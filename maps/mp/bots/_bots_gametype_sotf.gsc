#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;
#include maps\mp\bots\_bots_personality;

//=======================================================
//						main
//=======================================================
main()
{
	// nothing for now...
	setup_callbacks();
	setup_bot_sotf();
}


setup_callbacks()
{
	level.bot_funcs["dropped_weapon_think"]				= ::sotf_bot_think_seek_dropped_weapons;
	level.bot_funcs["dropped_weapon_cancel"]			= ::sotf_should_stop_seeking_weapon;
	level.bot_funcs["crate_low_ammo_check"]				= ::sotf_crate_low_ammo_check;
	level.bot_funcs["crate_should_claim"]				= ::sotf_crate_should_claim;
	level.bot_funcs["crate_wait_use"]					= ::sotf_crate_wait_use;
	level.bot_funcs["crate_in_range"]					= ::sotf_crate_in_range;
	level.bot_funcs["crate_can_use"]					= ::sotf_crate_can_use;
}

setup_bot_sotf()
{
	level.bots_gametype_handles_class_choice = true;
}

sotf_should_stop_seeking_weapon( goal )
{
	// goal.object is the dropped weapon
	
	if ( self bot_get_total_gun_ammo() > 0 )
	{
		myWeapClass = getWeaponClass( self GetCurrentWeapon() );
		if ( IsDefined( goal.object ) )
		{
			dropped_weapon_name = goal.object.classname;
			if(string_starts_with( dropped_weapon_name, "weapon_" ) )
				dropped_weapon_name = getsubstr( dropped_weapon_name, 7 );
			weapClass = getWeaponClass( dropped_weapon_name );
			if ( !(self bot_weapon_is_better_class( myWeapClass, weapClass )) )
			{
				return true;
			}
		}
	}
	
	if ( !IsDefined( goal.object ) )
		return true;
	
	return false;
}


sotf_bot_think_seek_dropped_weapons()
{
	self notify( "bot_think_seek_dropped_weapons" );
	self endon(  "bot_think_seek_dropped_weapons" );
		
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );

	while( true )
	{
		still_seeking_weapon = false;
		
		if (  self [[level.bot_funcs["should_pickup_weapons"]]]() && !self bot_is_remote_or_linked() )
		{
			if ( self bot_out_of_ammo() )
			{
				dropped_weapons = GetEntArray("dropped_weapon","targetname");
				dropped_weapons_sorted = get_array_of_closest(self.origin,dropped_weapons);
				if ( dropped_weapons_sorted.size > 0 )
				{
					dropped_weapon = dropped_weapons_sorted[0];
					self maps\mp\bots\_bots::bot_seek_dropped_weapon( dropped_weapon );
				}
			}
			else
			{
				//go through all visible dropped weapons - if see one better than mine, go pick it up
				dropped_weapons = GetEntArray("dropped_weapon","targetname");
				dropped_weapons_sorted = get_array_of_closest(self.origin,dropped_weapons);
				if ( dropped_weapons_sorted.size > 0 )
				{
					// First check for the closest weapon the bot can see (ignoring current FOV)
					nearest_node_bot = self GetNearestNode();
					if ( IsDefined(nearest_node_bot) )
					{
						myWeapClass = getWeaponClass( self GetCurrentWeapon() );
						foreach( dropped_weapon in dropped_weapons_sorted )	
						{
							dropped_weapon_name = dropped_weapon.classname;
							if(string_starts_with( dropped_weapon_name, "weapon_" ) )
								dropped_weapon_name = getsubstr( dropped_weapon_name, 7 );
							weapClass = getWeaponClass( dropped_weapon_name );
							if ( self bot_weapon_is_better_class( myWeapClass, weapClass ) )
							{
							    if ( !IsDefined( dropped_weapon.calculated_nearest_node ) || !dropped_weapon.calculated_nearest_node )
								{
									dropped_weapon.nearest_node = GetClosestNodeInSight(dropped_weapon.origin);
									dropped_weapon.calculated_nearest_node = true;
								}
							    
							    if ( IsDefined( dropped_weapon.nearest_node ) && NodesVisible(nearest_node_bot, dropped_weapon.nearest_node, true) )
								{
									self maps\mp\bots\_bots::bot_seek_dropped_weapon( dropped_weapon );
									break;
								}
							}
						}
					}
				}
			}
		}
		
		wait( RandomFloatRange(0.25, 0.75) );
	}
}


bot_rank_weapon_class( weapClass )
{
	weapRank = 0;
	switch( weapClass )
	{
		// NOTE: these come from statstable.csv, which is where getWeaponClass looks up a weapon's class - NOT the class defined in the weapon's .gdt!
		case "weapon_other":
		case "weapon_projectile":
		case "weapon_explosive":
		case "weapon_grenade":
			break;
		case "weapon_pistol":
			weapRank = 1;
			break;
		case "weapon_sniper":
		case "weapon_dmr":
			weapRank = 2;
			break;
		case "weapon_shotgun":
		case "weapon_smg":
		case "weapon_assault":
		case "weapon_lmg":
			weapRank = 3;
			break;
	}
	return weapRank;
}


bot_weapon_is_better_class( oldWeapClass, newWeapClass )
{
	oldWeapRank = bot_rank_weapon_class( oldWeapClass );
	newWeapRank = bot_rank_weapon_class( newWeapClass );
	
	return (newWeapRank > oldWeapRank);
}


sotf_crate_low_ammo_check()
{
	// Ammo is extremely sparse in SOTF 
	// Only consider ourselves low on ammo when we are running out of our last clip
	myWeapon = self GetCurrentWeapon();
	ammoInClip = self GetWeaponAmmoClip( myWeapon );
	ammoInStock = self GetWeaponAmmoStock( myWeapon );
	maxClipSize = WeaponClipSize( myWeapon );
	
	return (ammoInClip + ammoInStock) < (maxClipSize * 0.25);
}


sotf_crate_should_claim()
{
	return false;
}


sotf_crate_wait_use()
{
	// clear the area before trying to use the crate
	bot_waittill_out_of_combat_or_time(5000);
}


sotf_crate_in_range( crate )
{
	return true;
}

sotf_crate_can_use( crate )
{
	if ( maps\mp\bots\_bots::crate_can_use_always( crate ) )
	{
		if ( IsDefined( crate ) && IsDefined( crate.bots_used ) && array_contains( crate.bots_used, self ) )
		{
			// Only use a crate once unless we are out of ammo
			if ( self bot_out_of_ammo() )
				return true;
			else
				return false;
		}

		// If we only have a pistol or worse
		myWeapClass = getWeaponClass( self GetCurrentWeapon() );
		if ( bot_rank_weapon_class( myWeapClass ) <= 1 )
			return true;

		// If we are getting pretty low on ammo		
		if ( self sotf_crate_low_ammo_check() )
			return true;
		
		// Otherwise just keep using what we have
		return false;
	}
	
	return false;	
}

