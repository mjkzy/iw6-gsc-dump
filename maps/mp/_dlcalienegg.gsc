#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

CONST_EGG_ID = "dlcEggStatus";
CONST_ALL_EGG_CHALLENGE = "ch_weekly_1";

init()
{
	// this is a terrible hack.
	// We are tracking all of the egg state in one 32-bit integer.
	// The lower 16 bits track whether the player has shot the egg for that level, 4-bits per map-pack.
	
	
	
	// the number of bits shifted should correspond to the order in mapNames.csv
	// we'll use this to check completion of player data
	level.dlcAlienEggs 							= [];
	// pack 1
	level.dlcAlienEggs[ "mp_boneyard_ns" ]		= 1 << 0;
	level.dlcAlienEggs[ "mp_swamp" ]			= 1 << 1;
	level.dlcAlienEggs[ "mp_ca_red_river" ]		= 1 << 2;
	level.dlcAlienEggs[ "mp_ca_rumble" ]		= 1 << 3;
	
	// pack 2
	level.dlcAlienEggs[ "mp_dome_ns" ]			= 1 << 4;
	level.dlcAlienEggs[ "mp_battery3" ]			= 1 << 5;
	level.dlcAlienEggs[ "mp_ca_impact" ]		= 1 << 6;
	level.dlcAlienEggs[ "mp_ca_behemoth" ]		= 1 << 7;
	
	// pack 3. bits 8-11
	level.dlcAlienEggs[ "mp_dig" ]				= 1 << 8;
	level.dlcAlienEggs[ "mp_favela_iw6" ]		= 1 << 9;
	level.dlcAlienEggs[ "mp_pirate" ]			= 1 << 10;
	level.dlcAlienEggs[ "mp_zulu" ]				= 1 << 11;
	
	// pack 4. bits 12-15
	level.dlcAlienEggs[ "mp_conflict" ]			= 1 << 12;
	level.dlcAlienEggs[ "mp_mine" ]				= 1 << 13;
	level.dlcAlienEggs[ "mp_zerosub" ]			= 1 << 14;
	level.dlcAlienEggs[ "mp_shipment_ns" ]		= 1 << 15;
	
	// Translate each map name to its pack number (0-based)
	level.dlcAliengEggMapToPack[ "mp_boneyard_ns" ]		= 0;
	level.dlcAliengEggMapToPack[ "mp_swamp" ]			= 0;
	level.dlcAliengEggMapToPack[ "mp_ca_red_river" ]	= 0;
	level.dlcAliengEggMapToPack[ "mp_ca_rumble" ]		= 0;
	
	level.dlcAliengEggMapToPack[ "mp_dome_ns" ]			= 1;
	level.dlcAliengEggMapToPack[ "mp_battery3" ]		= 1;
	level.dlcAliengEggMapToPack[ "mp_ca_impact" ]		= 1;
	level.dlcAliengEggMapToPack[ "mp_ca_behemoth" ]		= 1;
	
	level.dlcAliengEggMapToPack[ "mp_dig" ]				= 2;
	level.dlcAliengEggMapToPack[ "mp_favela_iw6" ]		= 2;
	level.dlcAliengEggMapToPack[ "mp_pirate" ]			= 2;
	level.dlcAliengEggMapToPack[ "mp_zulu" ]			= 2;
	
	// pack 4. bits 12-15
	level.dlcAliengEggMapToPack[ "mp_conflict" ]		= 3;
	level.dlcAliengEggMapToPack[ "mp_mine" ]			= 3;
	level.dlcAliengEggMapToPack[ "mp_zerosub" ]			= 3;
	level.dlcAliengEggMapToPack[ "mp_shipment_ns" ]		= 3;
	
	// # of set bits in 0 - 15
	// use to look up how many eggs have been achieved
	level.bitCounts = [ 0, 1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4 ];
	
	level._effect[ "vfx_alien_easter_egg_hit" ] = loadfx( "vfx/gameplay/alien/vfx_alien_easter_egg_hit" );
}

setupEggForMap( eggName )
{
	if ( level.rankedMatch )
	{
		init();
		
		flags = level.dlcAlienEggs[ getMapName() ];
		
		AssertEx( IsDefined( flags ), "dlcAlienEggs bit flag not set up for map: " + getMapName() );
		
		egg = GetEnt( eggName, "targetname" );
		if ( IsDefined( egg ) )
		{
			// add flags
			// playlistType = GetDvarInt( "scr_playlist_type", 0 );
			
			if ( egg.classname == "script_model" )
			{
				egg SetCanDamage( true );
			}
			
			egg thread eggTrackHits();
		}
		
		/#
			thread eggDebug();
		#/
	}
}

eggTrackHits()
{
	level endon( "game_ended" );
	self.health = 99999;
	
	level.eggHits = [];
	
	while ( true )
	{
		self waittill( "damage", damage, attacker, direction, point, damageType );
		
		// play a sound and effect?
		PlayFX( getfx( "vfx_alien_easter_egg_hit" ), point, AnglesToForward( direction ), AnglesToUp( direction ) );
		
		if ( IsPlayer( attacker ) && !IsAI( attacker ) )
		{
			attackerNum = attacker getUniqueId();
			// we have not hit this egg before
			if ( !IsDefined( level.eggHits[ attackerNum ] ) )
			{
				level.eggHits[ attackerNum ] = 1;
				self eggRegisterHit( damage, attacker, direction, point, damageType );
			}
		}
	}
	
}

eggRegisterHit( damage, attacker, direction, point, type )
{
	self.health += damage;	// don't let the health drop
	
	if ( !( attacker eggHasCompletedForMap( getMapName() ) ) )
	{
		attacker eggSetCompletedForMap( getMapName() );
	}
	else if ( attacker eggAllFound() 
		&& attacker ch_getState( CONST_ALL_EGG_CHALLENGE ) < 2
		)
	{
		attacker eggAwardPatch();
	}
}

eggHasCompletedForMap( mapName )	// self == player
{
	eggState = self GetRankedPlayerDataReservedInt( CONST_EGG_ID );
	
	bitFlag = level.dlcAlienEggs[ mapName ];
	if ( IsDefined( bitFlag ) &&
	    (eggState & bitFlag) != 0 )
	{
		return true;
	}
	
	return false;
}

eggSetCompletedForMap( mapName )	// self == player
{
	bitFlag = level.dlcAlienEggs[ mapName ];
	
	if ( IsDefined( bitFlag ) )
	{
		eggState = self GetRankedPlayerDataReservedInt( CONST_EGG_ID );
		
		eggState |= bitFlag;
		self SetRankedPlayerDataReservedInt( CONST_EGG_ID, eggState );
		
		packNum = level.dlcAliengEggMapToPack[ mapName ];
		AssertEx( IsDefined( packNum ), "MapPack ID not defined for " + mapName );
		
		numCompleted = eggCountCompletedEggsForPack( packNum, eggState );
		packNum++;	// the splashes are indexed 1-4, instead of 0-3
		if ( numCompleted < 4 )
		{
			self maps\mp\gametypes\_hud_message::playerCardSplashNotify( "dlc_eggFound_" + packNum, self, numCompleted );
		}
		else
		{
			// if all the eggs are found, give ultimate award
			if ( self eggAllFound() 
				 && ch_getState( CONST_ALL_EGG_CHALLENGE ) < 2
			   )
			{
				self eggAwardPatch();
			}
			// otherwise give award for this pack
			else
			{
				self maps\mp\gametypes\_hud_message::playerCardSplashNotify( "dlc_eggAllFound_" + packNum, self );
				self thread maps\mp\gametypes\_rank::giveRankXP( "dlc_egg_hunt" );
			}
			
			
		}
		
		self PlayLocalSound( "ui_extinction_egg_splash" );
	}
}

eggAwardPatch()
{
	self maps\mp\gametypes\_hud_message::playerCardSplashNotify( "dlc_eggAllFound", self );
	self thread maps\mp\gametypes\_rank::giveRankXP( "dlc_egg_hunt_all" );
				
	ch_setState( CONST_ALL_EGG_CHALLENGE, 2 );	// patch. Weekly challenges are unlocked with state set to 2.
}

eggCountCompletedEggsForPack( packNum, eggState )
{
	flags = eggState >> (packnum * 4);	// move the bits to the first set of 4
	flags &= 15;	// mask out everything but the first four bits
	
	return level.bitCounts[ flags ];
}

// packNum is 0-indexed
eggAllFoundForPack( packNum )
{
	eggState = self GetRankedPlayerDataReservedInt( CONST_EGG_ID );
	packEggState = (eggState >> (packnum *4)) & 15;
	
	return (packEggState != 0);
}

// all 16 eggs found
CONST_ALL_EGGS_MASK = (1 << 16) - 1;
eggAllFound()
{
	eggState = self GetRankedPlayerDataReservedInt( CONST_EGG_ID );
	
	return ( eggState == CONST_ALL_EGGS_MASK );
}

/#
eggDebug()
{
	level endon( "game_ended" );
	
	level waittill( "connected", player );
	
	player thread eggDebugPlayer();
}
	
eggDebugPlayer()	// self == player
{
	level endon( "game_ended" );
	
	SetDvarIfUninitialized( "scr_egg_set", "" );
	SetDvarIfUninitialized( "scr_egg_pack_set", 0 );
	SetDvarIfUninitialized( "scr_egg_clear", 0 );
	
	while ( true )
	{
		mapName = GetDvar( "scr_egg_set" );
		if ( mapName != "" )
		{
			self eggSetCompletedForMap( mapName );
			SetDvar( "scr_egg_set", "" );
		}
		
		if ( GetDvarInt( "scr_egg_clear" ) != 0 )
		{
			self SetRankedPlayerDataReservedInt( CONST_EGG_ID, 0 );
			SetDvar( "scr_egg_clear", 0 );
			level.eggHits = [];
			
			ch_setState( CONST_ALL_EGG_CHALLENGE, 0 );
		}
		
		// set all the flags for one pack
		targetPackNum = GetDvarInt( "scr_egg_pack_set" );
		if ( targetPackNum > 0 )
		{
			targetPackNum--;
			
			foreach ( mapName, packNum in level.dlcAliengEggMapToPack )
			{
				if ( packNum == targetPackNum && !( self eggHasCompletedForMap( mapName ) ) )
				{
					self eggSetCompletedForMap( mapName );
					wait (3.6);	// a little bit more than the duration of the splash
				}
			}
			
			SetDvar( "scr_egg_pack_set", "" );
		}
		
		wait ( 0.25 );
	}
}
#/
