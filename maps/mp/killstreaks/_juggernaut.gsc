#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

DECAP_SCALAR_X = 6000;
DECAP_SCALAR_Y = 10000;
DECAP_SCALAR_Z = 4000;

init()
{
	level.juggSettings = [];

	level.juggSettings[ "juggernaut" ] 								= SpawnStruct();
	level.juggSettings[ "juggernaut" ].splashUsedName 				= "used_juggernaut";

	level.juggSettings[ "juggernaut_recon" ] 						= SpawnStruct();
	level.juggSettings[ "juggernaut_recon" ].splashUsedName 		= "used_juggernaut_recon";

	level.juggSettings[ "juggernaut_maniac" ] 						= SpawnStruct();
	level.juggSettings[ "juggernaut_maniac" ].splashUsedName 		= "used_juggernaut_maniac";
	
	level thread watchJuggHostMigrationFinishedInit();
}

giveJuggernaut( juggType ) // self == player
{
	self endon( "death" );
	self endon( "disconnect" );

	// added this wait here because i think the disabling the weapons and re-enabling while getting the crate, 
	//	needs a little time or else we sometimes won't have a weapon in front of us after we get juggernaut
	wait(0.05); 

	//	remove light armor if equipped
	if ( IsDefined( self.lightArmorHP ) )
		self maps\mp\perks\_perkfunctions::unsetLightArmor();
	
	self maps\mp\gametypes\_weapons::disablePlantedEquipmentUse();
	
	//	remove explosive bullets if equipped
	if ( self _hasPerk( "specialty_explosivebullets" ) )
		self _unsetPerk( "specialty_explosivebullets" );

	// give 100% health to fix some issues
	//	first was if you are being damaged and pick up juggernaut then you could die very quickly as juggernaut, seems weird in practice
	self.health = self.maxHealth;
	
	defaultSetup = true;

	switch( juggType )
	{
	case "juggernaut":
		self.isJuggernaut = true;
		self.juggMoveSpeedScaler = .80;	// for unset perk juiced
		self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], juggType, false );
		self.moveSpeedScaler = .80;
		self givePerk( "specialty_scavenger", false );
		self givePerk( "specialty_quickdraw", false );
		self givePerk( "specialty_detectexplosive", false );
		self givePerk( "specialty_sharp_focus", false ); 	 // juggernauts are in heavy armor and shouldn't be flinching like crazy
		self givePerk( "specialty_radarjuggernaut", false ); // this shows the jugg on the minimap
		break;
	case "juggernaut_recon":
		self.isJuggernautRecon = true;
		self.juggMoveSpeedScaler = .80;	// for unset perk juiced
		self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], juggType, false );
		self.moveSpeedScaler = .80;	
		self givePerk( "specialty_scavenger", false );
		self givePerk( "specialty_coldblooded", false );
		self givePerk( "specialty_noscopeoutline", false);
		self givePerk( "specialty_detectexplosive", false );
		self givePerk( "specialty_sharp_focus", false );     // juggernauts are in heavy armor and shouldn't be flinching like crazy
		self givePerk( "specialty_radarjuggernaut", false ); // this shows the jugg on the minimap

		if( !IsAgent(self) )
		{
			self makePortableRadar( self );
			
			self maps\mp\gametypes\_missions::processChallenge( "ch_airdrop_juggernaut_recon" );
		}
		
		break;
	case "juggernaut_maniac":
		self.isJuggernautManiac = true;
		self.juggMoveSpeedScaler = 1.15;	// for unset perk juiced
		self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], juggType, false );
		//self maps\mp\killstreaks\_killstreaks::giveAllPerks();
		//self _unsetPerk( "specialty_lightweight" );
		//self _unsetPerk( "specialty_combat_speed" );
		//self givePerk( "specialty_delaymine", false );
		//self givePerk( "specialty_regenfaster", false );
		//self givePerk( "specialty_extendedmelee", false );
		self givePerk( "specialty_blindeye", false );
		self givePerk( "specialty_coldblooded", false );
		self givePerk( "specialty_noscopeoutline", false);
		self givePerk( "specialty_detectexplosive", false );
		self givePerk( "specialty_marathon", false );
		self givePerk( "specialty_falldamage", false );
		//self givePerk( "specialty_explosivedamage", false );
		//self givePerk( "specialty_fastermelee", false );
		//self givePerk( "specialty_radarjuggernaut", false );
		self.moveSpeedScaler = 1.15; // this needs to happen last because some perks change speed
		break;
	default:
		// we rely on self.isJuggernautLevelCustom == true
		// this would be better if the juggType had some kind of standard prefix, like "juggernaut_custom_swamp_slasher" or "juggernaut_custom_predator"	
		AssertEx( IsDefined( level.mapCustomJuggFunc ), "Juggernaut type " + juggType + " needs to have a level.mapCustomJuggFunc defined!" );
		defaultSetup = self [[ level.mapCustomJuggFunc ]]( juggType );
		break;
	}

	// make sure to give players hardline if they previously had it equipped
	// we are doing this instead of _hasPerk, because at this point all of the loadout perks would have been cleared by giveLoadout
	if ( self perkCheck( "specialty_hardline" ) )
		self givePerk( "specialty_hardline", false );
	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale();
	self disableWeaponPickup();

	if( !IsAgent(self) )
	{
		// TODO: no overlay yet but if we want one we can remove these if checks
		if( defaultSetup )
		{
			self SetClientOmnvar( "ui_juggernaut", 1 );
			self thread teamPlayerCardSplash( level.juggSettings[ juggType ].splashUsedName, self );
			self thread juggernautSounds();		
			self thread watchDisableJuggernaut();
			self thread watchEnableJuggernaut();
		}
	}

	
	// if we are using the specialist strike package then we need to clear it, or else players will think they have the perks while jugg
	if( self.streakType == "specialist" )
	{
		self thread maps\mp\killstreaks\_killstreaks::clearKillstreaks();
	}
	//	- giveLoadout() nukes action slot 4 (killstreak weapon)
	//	- it's usually restored after activating a killstreak but 
	//	  equipping juggernaut out of a box isn't part of killstreak activation flow
	//	- restore action slot 4 by re-updating killstreaks
	else
	{
		self thread maps\mp\killstreaks\_killstreaks::updateKillstreaks( true );
	}

	self thread juggRemover();

	//	- model change happens at the end of giveLoadout(), removing any attached models
	//	- re-apply flag if we were carrying one
	if ( IsDefined( self.carryFlag ) )
	{
		wait( 0.05 );
		self attach( self.carryFlag, "J_spine4", true );
	}

	level notify( "juggernaut_equipped", self );

	self maps\mp\_matchdata::logKillstreakEvent( juggType, self.origin );
}

perkCheck( perkToCheck )
{
	// self == player
	loadoutPerks = self.pers[ "loadoutPerks" ];
	
	foreach ( perk in loadoutPerks )
	{
		if ( perk == perkToCheck )
			return true;
	}
	
	return false;
}

juggernautSounds()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "jugg_removed" );

	while( true )
	{
		wait ( 3.0 );
		playPlayerAndNpcSounds( self, "juggernaut_breathing_player", "juggernaut_breathing_sound" );
	}
}

//============================================
// 		 watchHostMigrationFinishedInit
//============================================
watchJuggHostMigrationFinishedInit()
{
	level endon( "game_ended" );
	
	for (;;)
	{
		level waittill( "host_migration_end" );
		
		foreach( player in level.players )
		{
			if ( isAI( player ) )
				continue;
			else if ( player isJuggernaut() && !( IsDefined( player.isJuggernautLevelCustom ) && player.isJuggernautLevelCustom ) )
				player SetClientOmnvar( "ui_juggernaut", 1 );
			else
				player SetClientOmnvar( "ui_juggernaut", 0 );
		}
	}
}

juggRemover()
{
	level endon("game_ended");
	self endon( "disconnect" );
	self endon( "jugg_removed" );

	self thread juggRemoveOnGameEnded();
	self waittill_any( "death", "joined_team", "joined_spectators", "lost_juggernaut" );

	self enableWeaponPickup();
	self.isJuggernaut = false;
	self.isJuggernautDef = false;
	self.isJuggernautGL = false;
	self.isJuggernautRecon = false;
	self.isJuggernautManiac = false;
	self.isJuggernautLevelCustom = false;
	if ( IsPlayer(self) )
		self SetClientOmnvar( "ui_juggernaut", 0 );

	self unsetPerk( "specialty_radarjuggernaut", true );

	self notify( "jugg_removed" );
}

juggRemoveOnGameEnded()
{
	self endon( "disconnect" );
	self endon( "jugg_removed" );

	level waittill( "game_ended" );

	if( IsPlayer(self) )
		self SetClientOmnvar( "ui_juggernaut", 0 );
}

setJugg()
{
	if( IsDefined( self.headModel ) )
	{
		self Detach( self.headModel, "" );
		self.headModel = undefined;
	}
	self SetModel( "mp_fullbody_juggernaut_heavy_black" );
	self SetViewModel( "viewhands_juggernaut_ally" );
	self SetClothType( "vestheavy" );
}

setJuggManiac()
{
	if( IsDefined( self.headModel ) )
	{
		self Detach( self.headModel, "" );
		self.headModel = undefined;
	}
	self SetModel( "mp_body_juggernaut_light_black" );
	self SetViewModel( "viewhands_juggernaut_ally" );
	self Attach( "head_juggernaut_light_black", "", true );
	self.headModel = "head_juggernaut_light_black";
	self SetClothType( "nylon" );
}

disableJuggernaut() // self == player
{
	if( self isJuggernaut() )
	{
		self.juggernaut_disabled = true;
		self SetClientOmnvar( "ui_juggernaut", 0 );
	}
}

enableJuggernaut() // self == player
{
	if( self isJuggernaut() )
	{
		self.juggernaut_disabled = undefined;
		self SetClientOmnvar( "ui_juggernaut", 1 );
	}
}

watchDisableJuggernaut() // self == player
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "jugg_removed" );
	level endon( "game_ended" );

	while( true )
	{
		if( !IsDefined( self.juggernaut_disabled ) && self isUsingRemote() )
		{
			self waittill( "black_out_done" );
			disableJuggernaut();
		}
		wait( 0.05 );
	}
}

watchEnableJuggernaut() // self == player
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "jugg_removed" );
	level endon( "game_ended" );

	while( true )
	{
		if( IsDefined( self.juggernaut_disabled ) && !self isUsingRemote() )
			enableJuggernaut();
		wait( 0.05 );
	}
}

initLevelCustomJuggernaut( createFunc, loadoutFunc, modelFunc, useSplashStr )
{
	level.mapCustomJuggFunc			 = createFunc;
	level.mapCustomJuggSetClass		 = loadoutFunc;
	level.mapCustomJuggKilledSplash	 = useSplashStr;
	
	game[ "allies_model" ][ "JUGGERNAUT_CUSTOM" ] = modelFunc;
	game[ "axis_model" ][ "JUGGERNAUT_CUSTOM" ] = modelFunc;
}
