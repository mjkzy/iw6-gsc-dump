#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\agents\_agent_utility;

//===========================================
// 				constants
//===========================================
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME		= 5;
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER 	= 2;

DEATH_MARIACHI_WEAPON = "iw6_mariachimagnum_mp_akimbo";


main()
{
	maps\mp\mp_zulu_precache::main();
	maps\createart\mp_zulu_art::main();
	maps\mp\mp_zulu_fx::main();
	
	maps\mp\_breach::main();
	
	maps\mp\_load::main();
	
	maps\mp\_barrels_leak::main();//shootable beer kegs leak
	
//	AmbientPlay( "ambient_mp_setup_template" );
	level.nukeDeathVisionFunc	 	 = ::nukeDeathVision;
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_zulu" );
	setdvar_cg_ng( "r_specularColorScale", 2.5, 7.5 );
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	
		if ( level.ps3 )
	{
		SetDvar( "sm_sunShadowScale", "0.45" ); // ps3 optimization
		SetDvar( "sm_sunsamplesizenear", ".35" );
	}
	else if ( level.xenon )
	{
		SetDvar( "sm_sunShadowScale", "0.55" + "" ); //  optimization
		SetDvar( "sm_sunsamplesizenear", ".35" );
	}
	else
	{
		SetDvar( "sm_sunShadowScale", "1.0" ); // optimization
		SetDvar( "sm_sunsamplesizenear", ".35" );
	}

	// Death Mariachi kill streak setup	
	level.mapCustomCrateFunc		 		= ::mariachiCustomCrateFunc;
	level.mapCustomKillstreakFunc	 		= ::mariachiCustomKillstreakFunc;
	level.mapCustomBotKillstreakFunc 		= ::mariachiCustomBotKillstreakFunc;

//	SetDvar( "sm_sunShadowScale", "0.55" + "" ); //  optimization
//	SetDvar( "sm_sunsamplesizenear", ".25" );
	
	maps\mp\killstreaks\_juggernaut::initLevelCustomJuggernaut( ::deathMariachiCreateFunc, ::setJuggDeathMariachiClass, ::setJuggDeathMariachi, "callout_killed_death_mariachi" );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "urban";
	game[ "axis_outfit" ] = "woodland";
	
	thread zulu_breach_init();
	
	thread maps\mp\_dlcalienegg::setupEggForMap( "alienEasterEgg" );
	
	thread precache_strings();
	
	thread nuke_custom_visionset();
	
	thread get_float_speaker_scriptables();
	
	thread setup_music_emitters();
}

precache_strings()
{
	PreCacheString( &"MP_ZULU_DEFAULT_TXT_01" );
	PreCacheString( &"MP_ZULU_DEFAULT_TXT_02" );
	PreCacheString( &"MP_ZULU_TESTREF" );
	PreCacheString( &"MP_ZULU_INSTRUCTION" );
}

setup_music_emitters()
{
	level.music_float_1 = play_loopsound_in_space("zulu_emt_mariachi_float", (320, 702, 151));
	level.float_music_enabled = 1;
	delayThread(2.0, maps\mp\gametypes\_music_and_dialog::disableMusic );
}

stop_ambient_music()
{
	level.music_float_1 StopLoopSound();
}

start_ambient_music()
{
	if( level.float_music_enabled == 1 )
	{
		level.music_float_1 PlayLoopSound("zulu_emt_mariachi_float");
	}
}

zulu_killstreak()  // self == player
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "jugg_removed" );
		
	level.muerto_active = true;
	
	while( 1 )
	{
		self IPrintLnBold( &"MP_ZULU_INSTRUCTION" );
		
		self thread giveSpiritVision();
		
		self thread createResurrectedSquadmate();
		
		thread stop_ambient_music();
		
		// Setting up perks to make player indistinguishable from his summoned squadmates
		self givePerk( "specialty_spygame", false );
		self givePerk( "specialty_coldblooded", false );
		self givePerk( "specialty_noscopeoutline", false);
		self givePerk( "specialty_heartbreaker", false );
		self givePerk( "specialty_fastreload", false );
		self givePerk( "specialty_scavenger", false );
		self givePerk( "specialty_sprintreload", false );
		self givePerk( "specialty_fastsprintrecovery", false );
		self givePerk( "specialty_marathon", false );
		self givePerk( "specialty_empimmune", false );
		self givePerk( "specialty_blindeye", false );
		
		//self thread play_mariachi_music_on_plr();
		
		// Manage creation of exploding corpses until player dies
		while( IsReallyAlive( self ) )
		{
			prev_kill_count = self.pers[ "kills" ];
			
			while( prev_kill_count == self.pers[ "kills" ] )
			{
				wait 0.1;
				
				if ( !isReallyAlive( self ) )
					break;
			}
		}
	}
}

play_mariachi_music_on_plr()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "jugg_removed" );

	while(1)
	{
		self PlayLocalSound("killstreak_mariachi_music_plr", "sounddone" );
		self waittill("sounddone");
	}
}

giveSpiritVision()
{
	self endon( "death" );

	while( IsReallyAlive( self ) )
	{
		self thread tryUse3DPing();
		
		wait level.uavSettings[ "uav_3dping" ].timeout;
	}
}

tryUse3DPing( lifeId, streakName ) // self == player
{
	uavType = "uav_3dping";

	self thread watch3DPing_spiritVision( uavType );
//	self thread watch3DPingTimeout( uavType );
//	level thread teamPlayerCardSplash( level.uavSettings[ uavType ].teamSplash, self );
	
	return true;
}

watch3DPing_spiritVision( uavType, uavEnt ) // self == player
{
	if( IsDefined( uavEnt ) )
		uavEnt endon( "death" );
	
	self endon( "leave" );
	self endon( "killstreak_disowned" );
	self endon( "death" );
	level endon( "game_ended" );

	// every N seconds do a ping of the world and show enemies in red
	pingTime = 2.0;

	if (level.teamBased)
	{
		level.activeUAVs[ self.team ]++;
	}
	else
	{
		level.activeUAVs[ self.guid ]++;
	}
	
	while( true )
	{
		// highlight all enemies in the world that can't be seen
		foreach( enemy in level.participants )
		{
			if( !isReallyAlive( enemy ) )
				continue;

			if ( !(self isEnemy( enemy ) ) )
				continue;

			if( enemy _hasPerk( "specialty_noplayertarget" ) || enemy _hasPerk( "specialty_incog" ) )
				continue;

			if ( getNumOwnedActiveAgents( self ) < 2 )
			{
				// do outline for this enemy 
				id = outlineEnableForPlayer( enemy, "red", self, false, "killstreak" );

				fadeTime = 2.0;
/#
//				fadeTime = GetDvarFloat( "scr_" + uavType + "_highlightFadeTime" );
				// host migration wipes out this dvar for some reason and causes the loop to continue when it shouldn't
//				if( fadeTime < 1 )
//					fadeTime = uavConfig.highlightFadeTime;
#/
				self thread watchHighlightFadeTime( id, enemy, fadeTime, uavEnt );
			}
		}

/#
//		pingTime = GetDvarFloat( "scr_" + uavType + "_pingTime" );
		// host migration wipes out this dvar for some reason and causes the loop to continue when it shouldn't
//		if( pingTime < 1 )
//			pingTime = uavConfig.pingTime;
#/
			
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( pingTime );
	}
}

watchHighlightFadeTime( id, ent, time, uavEnt ) // self == player
{
	if( IsDefined( uavEnt ) )
		uavEnt endon( "death" );

	self endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill_any_timeout_no_endon_death( time, "leave" );
	
	if( IsDefined( ent ) )
		outlineDisable( id, ent );
}

createResurrectedSquadmate() // self == player with killstreak
{
	self endon( "death" );
	
	while( true )
	{
		self waittill( "killed_enemy", victim, sWeapon );
		
		if ( sWeapon != "agent_support_mp" && sWeapon == DEATH_MARIACHI_WEAPON ) // TODO: Will likely be updated later based on weapon GDT entries for killstreak (current logic is a little redundant)
		{
//			maps\mp\killstreaks\_agent_killstreak::tryUseSquadmate();
			agent = useSquadmate( victim );
		
			if ( IsAgent( agent ) )
				agent customizeSquadmate( victim );			
		}
	}
}

customizeSquadmate( victim )
{
	// Variables
	self.agent_is_mariachi = true;
	
//	if ( cointoss() )
//		self.agentname = &"MP_ZULU_DEFAULT_TXT_01";
//	else
//		self.agentname = &"MP_ZULU_DEFAULT_TXT_02";
	
//	self.agentname = &"MP_DLC_10_TESTREF";
	
//	IPrintLnBold( &"MP_DLC_10_TESTREF", victim.name );

	// Set up visuals for squadmate
	if( IsDefined( self.headModel ) )
	{
		self Detach( self.headModel, "" );
		self.headModel = undefined;
	}

	self SetModel( "mp_mariachi" );
	
	// AUDIO: Play Mariachi spawn sound
	PlaySoundAtPos( self.origin, "zulu_mariachi_spawn" );
	
	self thread deathMariachiBotSounds();
	
	PlayFX( level._effect[ "vfx_squadmate_spawn_burst" ], self.origin );
	wait 0.05;
	PlayFXOnTag( level._effect[ "vfx_death_smoke_runner" ], self, "tag_origin" );
/*
	if(getNumOwnedActiveAgents( level.player ) == 2 )
	{
		IPrintLnBold("2");
		self play_loop_sound_on_entity("killstreak_mariachi_music_02");	
	}
	else
	{
		IPrintLnBold("1");
		self play_loop_sound_on_entity("killstreak_mariachi_music_01");		
	}
*/	
	// Set up weapons
	self TakeAllWeapons();
	self GiveWeapon( DEATH_MARIACHI_WEAPON);
	self SwitchToWeapon( DEATH_MARIACHI_WEAPON );
	
//	self _clearPerks();
	
	// Set perks for squadmates so they don't show names, same as the player
	self givePerk( "specialty_spygame", false );
	self givePerk( "specialty_coldblooded", false );
	self givePerk( "specialty_noscopeoutline", false);
	self givePerk( "specialty_heartbreaker", false );
	
	self givePerk( "specialty_scavenger", false );
	self givePerk( "specialty_sprintreload", false );
	self givePerk( "specialty_marathon", false );
	self givePerk( "specialty_empimmune", false );

	self thread post_killcam_perks();
	
	// Lower health on agents
	self.health = 25;
	
	/*
	instrument = spawn( "script_model", self.origin );
	instrument SetModel( "zu_guitar_case" );
//	self Attach( "zu_sombrero_02", "tag_shield_back" );  // zu_guitar_case, zu_sombrero_02
	instrument LinkTo( self, "tag_stowed_back", ( 0, 2, 0 ), ( 65, 0, -90 ) ); // self, "tag_stowed_back", ( 0, 0, 0 ), ( 0, 0, -90 ) ) <-- sombrero settings
	*/
	
	
	/*
	sombrero = spawn( "script_model", self.origin );
	sombrero SetModel( "zu_sombrero_02" );
	sombrero LinkTo( self, "tag_eye", ( -3, 0, 0 ), ( 0, 0, 0 ) );
	*/
	
	
	// Do some interesting stuff on death of the agent
	self thread agentDeathEvents();
}

// Adds perks that are being reset when going through killcam involving the Mariachi squadmates
post_killcam_perks()
{
	wait 5.0;
	
	self givePerk( "specialty_noplayertarget", false );
	self givePerk( "specialty_blindeye", false );
}

//===========================================
// 	Copied from _agent_killstreak.gsc.  
//   Can potentially be folded back into _agent_killstreak if it still does many of the same things
// KM - At this point it's quite different. 
//===========================================
useSquadmate( victim ) 
{
	level.agent_funcs["pirate"] = level.agent_funcs["squadmate"];
	
	// limit the number of active "squadmate" agents allowed per game
	if( getNumActiveAgents( "squadmate" ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	// limit the number of active agents allowed per player
	if( getNumOwnedActiveAgents( self ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER )
	{
		// self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	nearestPathNode = self getValidSpawnPathNodeNearPlayer( true );
	if( !IsDefined(nearestPathNode) )
	{
		return false;
	}
	spawnOrigin = nearestPathNode.origin;
	spawnAngles = nearestPathNode.angles;
	
	agent = maps\mp\agents\_agents::add_humanoid_agent( "pirate", self.team, "reconAgent", spawnOrigin, spawnAngles, self, false, false, "veteran" );
	if( !IsDefined( agent ) )
	{
		// self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	agent givePerk( "specialty_blindeye", false );
	agent.killStreakType = "agent";	
	
	return agent;
}

agentDeathEvents()
{
	self waittill( "death" );
	
	loc = self.origin;
	
	// AUDIO: Play Mariachi death sfx
	PlaySoundAtPos( loc, "zulu_mariachi_death" );
	
	PlayFX( level._effect[ "vfx_squadmate_spawn_burst" ], loc );
}

deathMariachiCreateFunc( juggType )
{
//	AssertEx( juggType == "juggernaut_death_mariachi" );
	
	self.isJuggernautLevelCustom = true;
	
	self thread deathMariachiSounds();
	
	self maps\mp\gametypes\_class::giveLoadout( self.pers["team"], juggType, false );
	
	self thread deathMariachiBeginMusic();
	self thread onJuggDeathMariachiEnemyKilled();
	self thread onJuggDeathMariachiDeath();
	self thread reaperSpiritWalking();
	
	self.canUseKillstreakCallback = ::juggDeathMariachiCanUseKillstreak;
	self.killstreakErrorMsg 	  	= ::juggDeathMariachiKillsteakErrorMsg;
	
	self.moveSpeedScaler = 1.05; // this needs to happen last because some perks change speed
	self.healthRegenDisabled = true;	// to disable health overlay sounds
	self.breathingStopTime = 0;
	
	self thread teamPlayerCardSplash( "used_juggernaut_death_mariachi", self );
	
	return false;
}

setJuggDeathMariachiClass( class )
{
	// rely on "none" defaults
	loadout = [];
	loadout[ "loadoutPrimary" ]				= "iw6_mariachimagnum";
	loadout[ "loadoutPrimaryBuff" ]			= "specialty_null";
	loadout[ "loadoutPrimaryAttachment" ] 	= "akimbo";
	loadout[ "loadoutSecondary" ]			= "none";
//	loadout[ "loadoutSecondaryBuff" ]		= "specialty_null";
//	loadout[ "loadoutSecondaryAttachment" ]	= "specialty_null";
	loadout[ "loadoutEquipment" ]			= "specialty_null";
	
	return loadout;
}

setJuggDeathMariachi()
{
	if( IsDefined( self.headModel ) )
	{
		self Detach( self.headModel, "" );
		self.headModel = undefined;
	}
	self SetModel( "mp_mariachi" );
	self SetViewModel( "viewhands_mp_mariachi" );
	self SetClothType( "nylon" );
}

juggDeathMariachiCanUseKillstreak( streakName )
{
	/*
	if ( streakName == "heli_sniper" || self isRideKillstreak( streakname ) )
		return false;
	
	return true;
	*/
	
	return false;
}

juggDeathMariachiKillsteakErrorMsg()
{
	self IPrintLnBold( &"MP_ZULU_NO_KILLSTREAKS" );	
}

reaperSpiritWalking()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "jugg_removed" );

	if ( self.isJuggernautLevelCustom )
	{	
		self thread zulu_killstreak(); // Exploding corpses when enemies are killed
		
		self.spiritwalking = true;
		
//		spirits = GetEntArray( "org_spirits", "targetname" );
		
		// Set up player model and effects
		self SetModel( "mp_mariachi" );
		self SetViewModel( "viewhands_mp_mariachi" );
		
		/*
		instrument = spawn( "script_model", self.origin );
		instrument SetModel( "zu_guitar_case" );
		instrument LinkTo( self, "tag_stowed_back", ( 0, 12, 0 ), ( 65, 0, -90 ) ); // self, "tag_stowed_back", ( 0, 0, 0 ), ( 0, 0, -90 ) ) <-- sombrero settings
		*/
		
		/*
		sombrero = spawn( "script_model", self.origin );
		sombrero SetModel( "zu_sombrero_02" );
		sombrero LinkTo( self, "tag_eye", ( -3, 0, 0 ), ( 0, 0, 0 ) );
		*/
		
		if( IsDefined( self.headModel ) )
		{
			self Detach( self.headModel, "" );
			self.headModel = undefined;
		}
		
		PlayFXOnTag( level._effect[ "vfx_death_smoke_runner" ], self, "tag_origin" );
		if ( issplitscreen() )
		{
			//scrnfx distortion and vignette fx
			createfx_originss = ( 235.004, 521.706, 1.95469 );
			createfx_anglesss = ( 270, 0, 0 );
			fx_upss = anglestoup(createfx_anglesss);
			fx_fwdss = anglestoforward(createfx_anglesss);
			level.scrnfxss = SpawnFXForClient( level._effect[ "vfx_scrnfx_spirit_vision_split" ], createfx_originss, self, fx_fwdss, fx_upss );
			TriggerFX( level.scrnfxss );
		}
		else
		{
			createfx_origin = ( 235.004, 521.706, 1.95469 );
			createfx_angles = ( 270, 0, 0 );
			fx_up = anglestoup(createfx_angles);
			fx_fwd = anglestoforward(createfx_angles);
			level.scrnfx = SpawnFXForClient( level._effect[ "vfx_scrnfx_spirit_vision" ], createfx_origin, self, fx_fwd, fx_up );
			TriggerFX( level.scrnfx );
		}

		self VisionSetNakedForPlayer( "mp_zulu_spiritwalk", 0.1 );  // black_ice_infil, carrier_fever_dream, carrier_interior_mask, clockwork_cat_walk, clockwork_pillar_room, prague_underwater
		
		self thread visionset_watcher_for_mariachi();
		
		/* TJS - Not going to do visionset change for other players 
		foreach( player in level.players )
		{
			if ( player != self )
			{
				player VisionSetNakedForPlayer( "mp_zulu_spiritwalk_nonplayer", 2.0 );
			}
		}
		*/
		
		self thread visionset_watcher_for_spectate();
//		self set_visionset_for_watching_players( "mp_zulu_spiritwalk", 0.1, 5 );
		
		self thread visionset_watcher_for_game_end();
	}
}

visionset_watcher_for_mariachi()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while( 1 )
	{
		level waittill( "emp_used" );
		
		wait 1.0;
		
		self VisionSetNakedForPlayer( "mp_zulu_spiritwalk", 0.1 );
	}
}

visionset_watcher_for_spectate()
{
	self endon( "death" );
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	while( 1 )
	{
		self set_visionset_for_watching_players( "mp_zulu_spiritwalk", 0.1, 5 );
		
		wait 0.2;
	}
}

visionset_watcher_for_game_end()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	level waittill( "game_ended" );

	self VisionSetNakedForPlayer( "mp_zulu", 0.1 );
	
	//kill scrnfx distortion and vignette fx
	if ( issplitscreen() )
	{
		if ( IsDefined ( level.scrnfxss ))
			level.scrnfxss delete();
	}
	else
	{
		if ( IsDefined ( level.scrnfx ))
			level.scrnfx delete();
	}
}

tryUseJuggernautDeathMariachi( lifeId, streakName )
{
	maps\mp\killstreaks\_juggernaut::giveJuggernaut( streakName );
	game[ "player_holding_level_killstrek" ] = false;
	return true;
}

DEATH_MARIACHI_WEIGHT = 85;
enable_level_killstreak()
{
	maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", "juggernaut_death_mariachi", DEATH_MARIACHI_WEIGHT );
}

disable_level_killstreak()
{
	maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", "juggernaut_death_mariachi", 0 );
}

mariachiCustomCrateFunc()
{
	if( !IsDefined( game["player_holding_level_killstrek"] ) )
		game[ "player_holding_level_killstrek" ] = false;
		
	if( !allowLevelKillstreaks() || game[ "player_holding_level_killstrek" ] )
		return;
	
	//"Press and hold [{+activate}] for Death Mariachi"
	maps\mp\killstreaks\_airdrop::addCrateType( 
		"airdrop_assault", 
		"juggernaut_death_mariachi",	
		DEATH_MARIACHI_WEIGHT, 
		maps\mp\killstreaks\_airdrop::juggernautCrateThink, 
		maps\mp\killstreaks\_airdrop::get_friendly_juggernaut_crate_model(), 
		maps\mp\killstreaks\_airdrop::get_enemy_juggernaut_crate_model(), 
		&"MP_ZULU_JUGGERNAUT_DEATH_PICKUP"
	);
	
	level thread watch_for_death_mariachi_crate();
}

watch_for_death_mariachi_crate()
{
	while( true )
	{
		level waittill( "createAirDropCrate", dropCrate );

		if( IsDefined( dropCrate ) && IsDefined( dropCrate.crateType ) && dropCrate.crateType == "juggernaut_death_mariachi" )
		{	
			disable_level_killstreak();
			captured = wait_for_capture( dropCrate );
			
			if( !captured )
			{
				enable_level_killstreak();
			}
			else
			{
				//Once its picked up it needs to remain off.
				game[ "player_holding_level_killstrek" ] = true;
				
				wait_for_killstreak_availability();
//				break;
			}
		}
	}
}

//death and capture are sent on the same frame but death is processed first :(
wait_for_capture( dropCrate )
{
	result = watch_for_air_drop_death( dropCrate );
	return !IsDefined( result ); //If !isdefined the captured notify was also sent.
}

watch_for_air_drop_death(dropCrate)
{
	dropCrate endon( "captured" );
	
	dropCrate waittill( "death" );
	waittillframeend;
	
	return true;
}

wait_for_killstreak_availability()
{
	level endon( "game_ended" );
	
	while( 1 )
	{
		// check if player is already holding killstreak
		if ( IsDefined( game[ "player_holding_level_killstrek" ] ) && !( game[ "player_holding_level_killstrek" ] ) && !level.muerto_active )
		{
			enable_level_killstreak();
			break;
		}
		
		wait 5.0;
	}
}


killstreak_lottery()
{
	level endon( "game_ended" );
	
	// Wait until there are actually players around to check
	while ( !IsDefined ( level.players) )
		wait 0.05;
	
	while ( level.players.size < 1 )
		wait 0.05;
	
	while( 1 )
	{
		wait 10;
		
		if( !IsDefined( game[ "player_holding_level_killstrek" ] ) )
			game[ "player_holding_level_killstrek" ] = false;
		
		winning_player = Random( level.players );
		
		if ( winning_player.hasdonecombat )
		{
			winning_player maps\mp\killstreaks\_juggernaut::giveJuggernaut( "juggernaut_death_mariachi" );

			while( IsAlive( winning_player ) )
			{
				wait 5.0;
			}
		}
	}
}

mariachiCustomKillstreakFunc()
{
	AddDebugCommand( "devgui_cmd \"MP/Killstreak/Level Event:5/Care Package/Death Mariachi\" \"set scr_devgivecarepackage juggernaut_death_mariachi; set scr_devgivecarepackagetype airdrop_assault\"\n");
	AddDebugCommand( "devgui_cmd \"MP/Killstreak/Level Event:5/Death Mariachi\" \"set scr_givekillstreak juggernaut_death_mariachi\"\n" );

	level.killStreakFuncs[ "juggernaut_death_mariachi" ] = ::tryUseJuggernautDeathMariachi;	
	level.killstreakWeildWeapons[ "pirate_agent_mp" ] = "juggernaut_death_mariachi";
}

mariachiCustomBotKillstreakFunc()
{
	AddDebugCommand( "devgui_cmd  \"MP/Bots(Killstreak)/Level Events:5/Death Mariachi\" \"set scr_testclients_givekillstreak juggernaut_death_mariachi\"\n" );
	maps\mp\bots\_bots_ks::bot_register_killstreak_func( "juggernaut_death_mariachi", maps\mp\bots\_bots_ks::bot_killstreak_simple_use );
}

deathMariachiSounds()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "jugg_removed" );
	
	self PlaylocalSound( "zulu_mariachi_activate" );
	
	while( true )
	{
		wait RandomIntRange(7, 10);
		
		playPlayerAndNpcSounds( self, "zulu_ghost_voice_plr", "zulu_ghost_voice_npc" );
	}
}

deathMariachiBotSounds()
{
	level endon ( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "jugg_removed" );

	while( true )
	{
		wait RandomIntRange(7, 10);	
		self PlaySoundOnMovingEnt( "zulu_ghost_voice_npc" );
	}
}

onJuggDeathMariachiEnemyKilled() // self == player
{
	self endon( "death" );
	
	while( true )
	{
		self waittill( "killed_enemy", victim, sWeapon );
		
		if ( sWeapon == DEATH_MARIACHI_WEAPON )
		{
			self thread deathMariachiKillEffect( victim );
		}
	}
}

deathMariachiKillEffect( victim )	// self == player
{
	pos = victim.origin + (0, 0, 50);
	
	wait(0.05);
	
	PlayFX( level._effect[ "vfx_squadmate_spawn_burst" ], pos );
}

onJuggDeathMariachiDeath() // self == player
{
	level endon( "game_ended" );
	
	self thread deathMariachiMusicEndOfLevel();
	
	self waittill_any( "death", "disconnect" );
	
	if ( IsDefined( self ) )
	{
		PlayFX( level._effect[ "vfx_mariachi_player_death" ], self.origin );
		
		//kill scrnfx distortion and vignette fx
		if ( issplitscreen() )
		{
			if ( IsDefined ( level.scrnfxss ))
				level.scrnfxss delete();
		}
		else
		{
			if ( IsDefined ( level.scrnfx ))
				level.scrnfx delete();
		}

		playPlayerAndNpcSounds( self, "zulu_mariachi_death_plr", "zulu_mariachi_death" );
		self.spiritwalking = false;
		self VisionSetNakedForPlayer( "mp_zulu", 0.1 );
		self.healthRegenDisabled = false;	
		
		/* TJS - Not going to do visionset change for other players 
		foreach( player in level.players )
		{
			if ( player != self )
			{
				player VisionSetNakedForPlayer( "mp_zulu", 2.0 );
			}
		}
		*/
	}
	
	// Killstreak availability management
	game[ "player_holding_level_killstrek" ] = false;
	level.muerto_active = false;
	
	// Kill off Mariachi squadmates
	foreach( agent in level.agentarray )
	{
		if ( !IsDefined( agent ) )
			continue;
		
		if( agent.agent_type == "pirate" && IsDefined( agent.agent_is_mariachi ) )
		{
//			agent maps\mp\agents\_agent_utility::deactivateAgent();
			agent Suicide();
		}
	}
	
	thread deathMariachiEndMusic();
}

// don't let the music keep playing after the game ends
deathMariachiMusicEndOfLevel()
{
	self endon( "death" );
	self endon( "disconnect" );

	level waittill( "game_ended" );
	
	thread deathMariachiEndMusic();
}

CONST_DEATH_MARIACHI_MUSIC_START = "killstreak_death_mariachi_music";
CONST_DEATH_MARIACHI_MUSIC_END = "killstreak_death_mariachi_music_end";
CONST_DEATH_MARIACHI_DRONE = "zulu_ghost_drone";
deathMariachiBeginMusic()
{
	wait 1.2;
	level.MariachiMusicEnt = Spawn( "script_origin", (0,0,0) );	
	level.MariachiMusicEnt playLoopSound( CONST_DEATH_MARIACHI_MUSIC_START );
	
	level.MariachiDroneEnt = Spawn( "script_origin", (0,0,0) );	
	level.MariachiDroneEnt playLoopSound( CONST_DEATH_MARIACHI_DRONE );
}

deathMariachiEndMusic()
{
	level.MariachiDroneEnt StopLoopSound();
	level.MariachiMusicEnt StopLoopSound();
	
	
	playSoundOnPlayers( CONST_DEATH_MARIACHI_MUSIC_END ); 	
	

	thread start_ambient_music(); 
	thread maps\mp\gametypes\_music_and_dialog::enableMusic();
	
	waitframe();
	level.MariachiDroneEnt Delete();
	level.MariachiDroneEnt = undefined;
	level.MariachiMusicEnt Delete();
	level.MariachiMusicEnt = undefined;	
}

// BREACHES
zulu_breach_init()
{
	wait 0.5;
	
	breaches = getstructarray( "breach", "targetname" );
	
	// disable all connected pathnodes
	foreach ( breach in breaches )
	{
		pathnodes = GetNodeArray(breach.target, "targetname");
		foreach( p in pathnodes )
			p DisconnectNode();
	}
	
	proxy = getstructarray( "breach_proxy", "targetname" );
	foreach ( p in proxy )
	{
		if ( !IsDefined( p.target ) )
			continue;
		breach = getstruct( p.target, "targetname" );
		if ( !IsDefined( breach ) )
			continue;
		breaches[ breaches.size ] = breach;			
	}
	array_thread( breaches, ::zulu_breach_update );
}

zulu_breach_update()
{
	// these game modes don't use breach doors, so skip the wait and explosion if it's one of these modes
	if(!(level.gameType == "gun") && !(level.gameType == "sotf_ffa") && !(level.gameType == "horde") && !(level.gameType == "sotf") && !(level.gameType == "infect"))
	{
		self waittill( "breach_activated" );
	
		eq_scale = 0.5;
		eq_duration = .5;
		eq_radius = 200;
	
		if( IsDefined( self.script_dot ) )
			eq_scale = self.script_dot;
		if( IsDefined( self.script_wait ) )
			eq_duration = self.script_wait;
		if( IsDefined( self.radius ) )
			eq_radius = self.radius;
		
		Earthquake( eq_scale, eq_duration, self.origin, eq_radius );
	}
	
	// find all the related pathnodes and connect them.
	pathnodes = GetNodeArray(self.target, "targetname");
	foreach( p in pathnodes )
		p ConnectNode();
}

// Remove this if _nuke.gsc gets a custom visionset fix
nuke_custom_visionset()
{
	level waittill( "nuke_death" );
	
	wait 1.3;
	
	level notify ( "nuke_death" );
	
//	level thread maps\mp\killstreaks\_nuke::updateNukeVisionOnHostMigration();
//	
//	level maps\mp\killstreaks\_nuke::setNukeAftermathVision( 5 );	
	
	thread nuke_custom_visionset();
}

nukeDeathVision()
{
	level.nukeVisionSet = "aftermath_mp_zulu";
	setExpFog(512, 4097, 0.578828, 0.802656, 1, 0.75, 0.75, 5, 0.382813,  0.350569, 0.293091, 3, (1, -0.109979, 0.267867), 0, 80, 1, 0.179688, 26, 180);
	VisionSetNaked( level.nukeVisionSet, 5 );
	VisionSetPain( level.nukeVisionSet );
	
//	wait 10;
//	level.nukeVisionSet = "";
//	VisionSetNaked("",5);
//	ClearFog(5);
}

get_float_speaker_scriptables()
{
	wait 3;
	//IPrintLnBold("get speaker scriptables");
	level.speakercount = 0;
	speakers = GetScriptableArray( "speakers", "targetname" );
	
	array_thread( speakers, ::wait_for_speaker_deaths );

}

wait_for_speaker_deaths()
{
	
	self waittill( "death" );
	//IPrintLnBold ("got speaker death");	
	level.speakercount++;
	
	//IPrintLnBold ( level.speakercount );
		
	if (level.speakercount >= 6)
	{
		thread stop_float_audio();
	}
}


stop_float_audio()
{
	//Josh- you can stop the music audio here 
	// IPrintLnBold ("stop float audio");
	level.float_music_enabled = 0;	
	thread play_sound_in_space("zulu_speaker_power_down",(304, 707, 103));
	stop_ambient_music();	
}
