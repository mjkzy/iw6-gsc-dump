#include maps\mp\_utility;
#include common_scripts\utility;

/////////////////////////////////
// CONSTANTS
/////////////////////////////////
CONST_KILLSTREAK_WEIGHT	   = 85;
CONST_KILLSTREAK_DURATION  = 40;
CONST_KILLSTREAK_KILL_TIME = 3;
CONST_FOG_FADE_TIME		   = 5;

// Exploders
EXPLODER_SNOW_DOORS_WINDOWS_ID  = 50;

// Debug
CONST_DEBUG_BEAST_PLAYER = "scr_beast_attack_player";
CONST_DEBUG_BEAST_OTHER = "scr_beast_attack_other"; 

main()
{
	maps\mp\mp_zerosub_precache::main();
	maps\createart\mp_zerosub_art::main();
	maps\mp\mp_zerosub_fx::main();
	
	// setup custom killstreak
	level.mapCustomCrateFunc		 = ::zeroSubCustomCrateFunc;
	level.mapCustomKillstreakFunc	 = ::zeroSubCustomKillstreakFunc;
	level.mapCustomBotKillstreakFunc = ::zeroSubCustomBotKillstreakFunc;
	
	maps\mp\_load::main();
	
//	AmbientPlay( "ambient_mp_setup_template" );
	
	maps\mp\_compass::setupMiniMap( "compass_map_mp_zerosub" );
	
	setdvar( "r_lightGridEnableTweaks", 1 );
	setdvar( "r_lightGridIntensity", 1.33 );
	SetDvar( "r_tessellationCutoffFalloffBase", 600 );
	SetDvar( "r_tessellationCutoffDistanceBase", 2000 );
	SetDvar( "r_tessellationCutoffFalloff", 600 );
	SetDvar( "r_tessellationCutoffDistance", 2000 );
	
	game["attackers"] = "allies";
	game["defenders"] = "axis";
	
	game[ "allies_outfit" ] = "urban";
	game[ "axis_outfit" ] = "woodland";
	
	// JC-10-28-13 - The door triggers were not lined up with the door script model
	// causing the door to push the player through the ground. Nudge both triggers
	// into position to fix this.
	tu_fix_door_trigger_positions();
	
	maps\mp\gametypes\_door::door_system_init( "door_switch" );
	
	thread maps\mp\_dlcalienegg::setupEggForMap( "alienEasterEgg" );
	thread tvs();
	
	level thread watchPlayerSpawn();	
	
	// 0 = The Beast - w/Juggs
	// 1 - The Beast - FX only 
	level.zerosub_killstreak = 0;
	level.zerosub_fog_on = false;
	
	// Allow beasts the go indoors
	level.beastAllowedIndoors = true;
	
	// Custom Death Effect to play when the killstreak kills a player
	level.custom_death_effect = ::playCustomDeathFX;
	level.custom_death_sound = ::playCustomDeathSound;

	// Setup the events for the map
	setupEvents( true );
	
	// Update the bot max distance when the fog comes rolling in
	level thread update_bot_maxsightdistsqrd();
	
	// Reset the fog ( in case someone calls in the killstreak just before a round transition )
	level thread resetFrostVisionSet();
	
	// Start another vision set when the nuke vision set rolls in, so it corrects how dark it gets
	level thread watchNukeVisionSet();
}

tu_fix_door_trigger_positions()
{
	names = [ "slide_door", "garage_door" ];
	
	foreach ( name in names )
	{
		door_ents = GetEntArray( name, "targetname" );
		
		foreach ( ent in door_ents )
		{
			if ( IsDefined( ent.classname ) && ent.classname == "trigger_multiple" )
			{
				if ( IsDefined( ent.script_parameters ) && IsSubStr( ent.script_parameters, "prone_only=true" ) )
				{
					continue;
				}
				
				if ( name == "slide_door" )
				{
					ent.origin = ( ent.origin[ 0 ] + 4, ent.origin[ 1 ], ent.origin[ 2 ] );
				}
				else if ( name == "garage_door" )
				{
					ent.origin = ( ent.origin[ 0 ] - 8.5, ent.origin[ 1 ], ent.origin[ 2 ] );
				}
			}
		}
	}
}

resetFrostVisionSet()
{	
	level endon ( "game_ended" );
	
	level waittill( "prematch_over" );
	
	stopFrostFog();
}

watchNukeVisionSet()
{
	level endon ( "game_ended" );
	
	level waittill( "nuke_aftermath_post_started" );
	
	foreach ( player in level.players )
	{
		player VisionSetStage( 1, 1 );
	}
}

update_bot_maxsightdistsqrd()
{
	fog_maxSightDist = 700;
	fog_maxSightDistSqrd = fog_maxSightDist * fog_maxSightDist;
	
	while ( !IsDefined( level.participants ) )
		waitframe();
	
	while ( true )
	{
		foreach ( participant in level.participants )
		{
			if ( !IsPlayer( participant ) )
				continue;
			
			if ( IsBot( participant ) )
			{
				if ( !IsDefined( participant.default_maxsightdistsqrd ) )
					participant.default_maxsightdistsqrd = participant.maxsightdistsqrd;
				
				if ( level.zerosub_fog_on )
				{
					participant.maxsightdistsqrd = fog_maxSightDistSqrd;
				}
				else
				{
					participant.maxsightdistsqrd = participant.default_maxsightdistsqrd;
				}
			}
		}
		
		waitframe();
	}
}

/////////////////////////////////
// EVENT SETUP
/////////////////////////////////

precacheItems()
{
	level.zerosub_fx[ "beast" ][ "snowcover_screen" ] = level._effect[ "vfx_yeti_snowcover_scr" ];
	level.zerosub_fx[ "beast" ][ "blood_explosion" ]  = level._effect[ "vfx_blood_explosion" ];	
	level.zerosub_fx[ "beast" ][ "shadow_screen" ] 	  = level._effect[ "vfx_yeti_shadow_scr" ];
	level.zerosub_fx[ "beast" ][ "snowcover" ] 		  = level._effect[ "vfx_yeti_snowcover" ];
	level.zerosub_fx[ "beast" ][ "eyeglow" ] 		  = level._effect[ "vfx_yeti_glowing_eye" ];
	level.zerosub_fx[ "breath" ][ "screen" ] 		  = level._effect[ "vfx_yeti_breath_scr" ];	
	level.zerosub_fx[ "frost" ][ "screen" ] 		  = level._effect[ "vfx_yeti_frost_scr" ];
	level.zerosub_fx[ "snow" ][ "screen" ] 			  = level._effect[ "vfx_yeti_snow_scr" ];
	level.zerosub_fx[ "snow" ][ "player" ] 			  = level._effect[ "vfx_playercentric_snowamb" ];
	level.zerosub_fx[ "dust" ][ "player" ] 			  = level._effect[ "vfx_playercentric_indoors" ];
	level.zerosub_fx[ "button"][ "green" ]			  = level._effect[ "vfx_button_light_green" ];
	level.zerosub_fx[ "button"][ "red" ]			  = level._effect[ "vfx_button_light_red" ];
}

setupEvents( setup )
{
	precacheItems();
	
	playEnvironmentAnims();
	playButtonFX();
	
	// Debug
	/#
		SetDvarIfUninitialized( CONST_DEBUG_BEAST_PLAYER, 0 );
		SetDvarIfUninitialized( CONST_DEBUG_BEAST_OTHER, 0 );
	
		AddDebugCommand( "bind o \"set " + CONST_DEBUG_BEAST_PLAYER + " 1\"\n" );
		AddDebugCommand( "bind p \"set " + CONST_DEBUG_BEAST_OTHER + " 1\"\n" );
		
		level thread debugDvarWatcher( CONST_DEBUG_BEAST_PLAYER );
		level thread debugDvarWatcher( CONST_DEBUG_BEAST_OTHER );
	#/
}

playEnvironmentAnims()
{
	fanObj01 = GetEnt( "zerosub_fan_01", "targetname" );		// Vent Fan 1
	fanObj02 = GetEnt( "zerosub_fan_02", "targetname" );		// Vent Fan 2
	radarObj = GetEnt( "zerosub_radar_dish", "targetname" );	// Radar Dish
	bushObj01 = GetEntArray( "zerosub_bush_01", "targetname" ); // Snowy Bush	
	treeObj02 = GetEntArray( "zerosub_tree_02", "targetname" ); // Tall Snowy Pine Tree
	treeObj03 = GetEntArray( "zerosub_tree_03", "targetname" ); // Medium Snowy Pine Tree
	treeObj04 = GetEntArray( "zerosub_tree_04", "targetname" );	// Short Snowy Pine tree
	treeObj05 = GetEntArray( "zerosub_tree_05", "targetname" );	// Dead Pine Tree
	treeObj06 = GetEntArray( "zerosub_tree_06", "targetname" ); // Small Dead Tree
	
	// 2 Big Fans on the main building
	if ( IsDefined( fanObj01 ) )
		fanObj01 ScriptModelPlayAnim( "mp_zerosub_fan_spin_1" );
	
	if ( IsDefined( fanObj02 ) )
		fanObj02 ScriptModelPlayAnim( "mp_zerosub_fan_spin_2" );
	
	// Big Radar Dish on the main building
	if ( IsDefined( radarObj ) )
		radarObj ScriptModelPlayAnim( "mp_zerosub_radar_spin" );
	
	// Bushes in the environment
	if ( IsDefined( bushObj01 ) )
	{
		foreach ( bush in bushObj01 )
		{
			randomDelay = RandomFloatRange( 1.0, 3.0 );
			bush thread playDelayAnim( "mp_zerosub_bush_tree", randomDelay );
		}
	}	

	// Trees in the environment
	if ( IsDefined( treeObj02 ) )
	{
		foreach ( tree in treeObj02 )
		{
			randomDelay = RandomFloatRange( 1.0, 2.0 );
			tree thread playDelayAnim( "mp_zerosub_spruce_tree_2", randomDelay );
		}
	}
	
	if ( IsDefined( treeObj03 ) )
	{
		foreach ( tree in treeObj03 )
		{
			randomDelay = RandomFloatRange( 2.0, 3.0 );
			tree thread playDelayAnim( "mp_zerosub_spruce_tree_3", randomDelay );
		}
	}
	
	if ( IsDefined( treeObj04 ) )
	{
		foreach ( tree in treeObj04 )
		{
			randomDelay = RandomFloatRange( 4.0, 5.0 );
			tree thread playDelayAnim( "mp_zerosub_spruce_tree_4", randomDelay );
		}
	}
	
	if ( IsDefined( treeObj05 ) )
	{
		foreach ( tree in treeObj05 )
		{
			randomDelay = RandomFloatRange( 5.0, 6.0 );
			tree thread playDelayAnim( "mp_zerosub_dead_pine", randomDelay );
		}
	}
	
	if ( IsDefined( treeObj06 ) )
	{
		foreach ( tree in treeObj06 )
		{
			randomDelay = RandomFloatRange( 6.0, 7.0 );
			tree thread playDelayAnim( "mp_zerosub_dead_tree", randomDelay );
		}
	}		
}

playButtonFX()
{
	greenButtons = getstructarray( "button_green", "targetname" );
	redButtons = getstructarray( "button_red", "targetname" );
	
	if ( IsDefined( greenButtons ) )
	{
		foreach ( button in greenButtons )
		{
			button.fxObj = SpawnFx( level.zerosub_fx[ "button"][ "green" ], button.origin );
			button.fxObj thread delayTriggerFX();
			button.fxObj thread cleanupFX();
		}
	}

	if ( IsDefined( redButtons ) )
	{
		foreach ( button in redButtons )
		{
			button.fxObj = SpawnFx( level.zerosub_fx[ "button"][ "red" ], button.origin );
			button.fxObj thread delayTriggerFX();
			button.fxObj thread cleanupFX();	
		}
	}	
}

delayTriggerFX()
{
	level endon ( "game_ended" );
	
	level waittill( "prematch_over" );
	
	TriggerFX( self );
}

cleanupFX()
{
	level waittill ( "game_ended" );
	
	self Delete();
}

playDelayAnim( animAlias, timeDelay )
{
	// self == animation entity
	
	level endon ( "game_ended" );
	
	wait( timeDelay );
	
	self ScriptModelPlayAnim( animAlias );
}

/#
debugDvarWatcher( DVAR )
{
	level endon ( "game_ended" );
	
	while ( true )
	{
		value = GetDvarInt( DVAR, 0 );
		
		if ( value > 0 )
		{
			switch ( DVAR )
			{
				case CONST_DEBUG_BEAST_PLAYER:
					
					foreach( player in level.players )
					{
						// Use the killstreak 
						player tryUseZeroSubKillstreak();
						break;
					}
					
				break;
				case CONST_DEBUG_BEAST_OTHER:
				
					if ( level.players.size > 1 ) 
					{
						foreach( player in level.players )
						{
							// Skip the first player ( you )
							if ( !IsDefined( level.debugfirstPlayer ) )
							{
							    level.debugfirstPlayer = true;
							 	continue;   
							}
							
							// Have the second player ( enemy ) to use the killstreak
							player tryUseZeroSubKillstreak();
							level.debugfirstPlayer = undefined;
							break;						
						}
					}
					else
						IPrintLnBold( "Need at least 1 enemy player to use this debug command" );
					
				break;		
			}
			SetDvar( DVAR, 0 );
		}
		
		wait ( 0.5 );
	}
}
#/

/////////////////////////////////
// LEVEL KILLSTREAK
/////////////////////////////////

zeroSubCustomCrateFunc()
{
	if(!IsDefined(game["player_holding_level_killstrek"]))
		game["player_holding_level_killstrek"] = false;
		
	if(!allowLevelKillstreaks() || game["player_holding_level_killstrek"])
		return;
	
	maps\mp\killstreaks\_airdrop::addCrateType(	"airdrop_assault", "zerosub_level_killstreak", CONST_KILLSTREAK_WEIGHT, maps\mp\killstreaks\_airdrop::killstreakCrateThink, maps\mp\killstreaks\_airdrop::get_friendly_crate_model(), maps\mp\killstreaks\_airdrop::get_enemy_crate_model(), &"MP_ZEROSUB_LEVEL_KILLSTREAK_ACTIVATE" );
	level thread zerosub_killstreak_watch_for_crate();
}

zeroSubCustomKillstreakFunc()
{
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Care Package/The Beast\" \"set scr_devgivecarepackage zerosub_level_killstreak; set scr_devgivecarepackagetype airdrop_assault\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/The Beast\" \"set scr_givekillstreak zerosub_level_killstreak\"\n");

	level.killStreakFuncs[ "zerosub_level_killstreak" ] = ::tryUseZeroSubKillstreak;
}

zeroSubCustomBotKillstreakFunc()
{
	AddDebugCommand("devgui_cmd  \"MP/Bots(Killstreak)/Level Events:5/The Beast\" \"set scr_testclients_givekillstreak zerosub_level_killstreak\"\n");
	maps\mp\bots\_bots_ks::bot_register_killstreak_func( "zerosub_level_killstreak", maps\mp\bots\_bots_ks::bot_killstreak_simple_use );
}

tryUseZeroSubKillstreak( lifeId, streakName )
{	
	// Announce to everyone that you used the killstreak
	level thread teamPlayerCardSplash( "used_zerosub_level_killstreak", self );
		
	level.zerosub_killstreak_user = self;
	
	// Environment Effects
	playFrostFog();
	
	// Play Environmental/Screen FX etc... when a player connects
	level thread watchPlayerConnect();
	
	// Play Environmental FX when a host migration happens
	level thread watchHostMigration();
	
	foreach ( player in level.players )
	{
		// The beast is coming!
		player PlayLocalSound( "mp_zero_monster_spawn" );
		
		if ( player.team != level.zerosub_killstreak_user.team )
			player thread watchRagDoll();
	}

	// Keep track of when this killstreak will end, so we know when to clear everything
	level thread watchKillstreakEnd();
		
	if ( level.zerosub_killstreak )
	{	
		// OLD KILLSTREAK LOGIC; this killstreak now uses the mp_beast_men::tryUseAgentKillstreak below
		//----------------------------------------------------------------------------------------------
		
		// Time to start the hunt
		level thread killRandomTargets();			

		game[ "player_holding_level_killstrek" ] = false;
		return true;
	}
	else
	{
		// Overwrite the agent weapon in the kill cam, so it will show the name of the killstreak instead
		level.killstreakWeildWeapons[ "beast_agent_mp" ] = "zerosub_level_killstreak";
		return maps\mp\mp_beast_men::tryUseAgentKillstreak();
	}
}

zerosub_killstreak_watch_for_crate()
{
	while ( true )
	{
		level waittill( "createAirDropCrate", dropCrate );

		if ( IsDefined( dropCrate ) && IsDefined( dropCrate.crateType ) && dropCrate.crateType == "zerosub_level_killstreak" )
		{	
			maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", "zerosub_level_killstreak", 0 );
			captured = wait_for_capture( dropCrate );
			
			if ( !captured )
			{
				maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", "zerosub_level_killstreak", CONST_KILLSTREAK_WEIGHT );
			}
			else
			{
				//Once its picked up it needs to remain off.
				game[ "player_holding_level_killstrek" ] = true;
				break;
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

watch_for_air_drop_death( dropCrate )
{
	dropCrate endon( "captured" );
	
	dropCrate waittill( "death" );
	waittillframeend;
	
	return true;
}

watchRagDoll()
{
	// self == victim
	
	self endon ( "disconnected" );
	level endon ( "game_ended" );
	level endon ( "frost_clear" );
	
	while ( true )
	{
		self waittill ( "start_instant_ragdoll", sMeansOfDeath, eInflictor );
		
		waitframe();
		
		// Cause the body to be thrown
		if ( isBeastMan( eInflictor ) )
			PhysicsExplosionSphere( eInflictor.origin + ( 0, 0, 50 ), 100, 90, 5.0 );
	}
}

watchKillstreakEnd()
{
	level endon ( "game_ended" );
	
	killstreakDuration = CONST_KILLSTREAK_DURATION;
	
	while ( killstreakDuration > 0 )
	{
		killstreakDuration -= 1;	
		maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( 1 );
	}
	
	// The following players can now be killed by the level killstreak again
	foreach ( player in level.players )
	{
		if ( IsDefined( player ) )
		{
			if ( IsDefined( player.killedByYeti ) )
				player.killedByYeti = undefined;
			
			if ( IsDefined( player.isBeingHunted ) )
				player.isBeingHunted = undefined;
			
			if ( IsDefined( player.beastKillCam ) )
				player.beastKillCam = undefined;
		}
	}
	
	// Only stop this if the nuke vision set isn't already in place
	if ( !IsDefined( level.nukeVisionInProgress ) || !level.nukeVisionInProgress )	
		stopFrostFog();
	
	level notify ( "frost_clear" );
}

killRandomTargets()
{
	level endon ( "game_ended" );
	level endon ( "frost_clear" );
	
	// Let the fog roll in first
	wait ( CONST_FOG_FADE_TIME + 3 );
	
	while ( true )
	{
		// Choose the target, and kill after a slight delay
		killTarget = getKillTarget();
		killInterval = RandomIntRange( 2, 4 );

		if ( IsDefined( killTarget ) )
			killTarget thread delayKill( CONST_KILLSTREAK_KILL_TIME );
		
		// Wait some more time before targeting the next player
		wait ( killInterval );		
	}
}

getKillTarget()
{
	killTargets = [];
	randomIndex = 0;
	
	foreach ( player in level.players )
	{
		// Only enemies that are alive, outside, are not already being hunted, can be killed by killstreaks, and not riding on a Heli Sniper should be added to this list
		if ( IsDefined( player ) && 
		     IsReallyAlive( player ) && 
		     player.team != level.zerosub_killstreak_user.team && 
		     player isOutside() && 
		     !player isBeingHunted() && 
		     player.avoidKillstreakOnSpawnTimer <= 0 &&
		     !player maps\mp\killstreaks\_killstreaks::isUsingHeliSniper() )
		{
			killTargets[ killTargets.size ] = player;
		}
	}
	
	if ( killTargets.size > 0 )
	{
		randomIndex = RandomInt( killTargets.size );
		
		// This person is now a marked target
		killTargets[ randomIndex ].isBeingHunted = true;

		return killTargets[ randomIndex ];
	}
}

delayKill( delayTime )
{
	// self == victim
	
	level endon ( "game_ended" );
	
	// Random Offset, where the explosion is going to come from
	randomOffset = [];
	randomOffset[ randomOffset.size ] = ( 0, 300, 0 );
	randomOffset[ randomOffset.size ] = ( 300, 0, 0 );
	randomOffset[ randomOffset.size ] = ( 300, 300, 0 );
	randomOffset[ randomOffset.size ] = ( 0, -300, 0 );
	randomOffset[ randomOffset.size ] = ( -300, 0, 0 );
	randomOffset[ randomOffset.size ] = ( -300, -300, 0 );
	randomOffset[ randomOffset.size ] = ( -300, 300, 0 );
	randomOffset[ randomOffset.size ] = ( 300, -300, 0 );
	
	randomIndex = RandomInt( randomOffset.size );
	
	// Sound FX for the growl etc...
	if ( !self isUsingRemote() )
		self PlayLocalSound( "mp_zerosub_monster_approach" );
	
	// Approaching FX Beast
	self thread playBeastFX();
	
	fXDelay = delayTime - 0.5;
	killDelay = delayTime - fXDelay;
	
	wait ( fXDelay );
	
	// Make sure we don't show the shadow unless they are really outside
	if ( IsDefined ( self ) && isReallyAlive( self ) && !self isUsingRemote() )
	{	
		if ( self isOutside() && !self maps\mp\killstreaks\_killstreaks::isUsingHeliSniper() )
		{	
			// What was that?!?!?! --- NOOOOOOOOOOOO!!!!!!!!
			shadow_effect_ent = SpawnFXForClient( level.zerosub_fx[ "beast" ][ "shadow_screen" ], self GetEye(), self );
			TriggerFX( shadow_effect_ent );
			shadow_effect_ent setfxkilldefondelete();
			self thread killFXOnPlayerDeath( shadow_effect_ent );
			
			snow_effect_ent = SpawnFXForClient( level.zerosub_fx[ "beast" ][ "snowcover_screen" ], self GetEye(), self );
			TriggerFX( snow_effect_ent );
			snow_effect_ent setfxkilldefondelete();
			self thread killFXOnPlayerDeath( snow_effect_ent );
		}
	}

	wait ( killDelay );
	
	// Since we have a slight delay before killing them, let's do one last check to see if they are a valid target
	if ( IsDefined ( self ) && isReallyAlive( self ) )
	{	
		if ( self isOutside() && !self maps\mp\killstreaks\_killstreaks::isUsingHeliSniper() )
		{
			// Sound FX for the roar/attack
			if ( !self isUsingRemote() )
				self PlayLocalSound( "mp_zero_plr_monster_attack" );
		
			self PlaySound( "mp_zero_npc_monster_attack" );
			
			// Explode the player in a bloody mess
			playerTagPos = self GetTagOrigin( "j_mainroot" );
			self.customDeath = true;
			self.killedByYeti = true;
			
			// Bloody Explosion - bllaarrggggghhhhh ( death sound )
			PlayFX( level.zerosub_fx[ "beast" ][ "blood_explosion" ], playerTagPos );
			self DoDamage( 10000, self.origin, level.zerosub_killstreak_user, self.beastKillCam, "MOD_CRUSH" );
			
			// Randomize the position from where the explosion is coming from
			PhysicsExplosionSphere( self.origin + randomOffset[ randomIndex ], 500, 400, 2.0 );
		}

		// Player was either killed, or escaped to inside the base before being attacked
		self.isBeingHunted = undefined;	
	}
}

playBeastFX()
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	multiplier = 100;
	
	while( true ) 
	{
		// Spawn the FX behind, and have it move through the player
		forwardVector = AnglesToForward( self.angles );
		fxOrigin = self.origin - ( forwardVector * multiplier );
		
		snow_cover_fx = SpawnFx( level.zerosub_fx[ "beast" ][ "snowcover" ], fxOrigin );
		TriggerFX( snow_cover_fx );	
		
		snow_cover_fx thread watchFXLifetime( 2 );
		
		multiplier -= 20;
		
		wait ( 0.5 );
	}
}

playFrostFog()
{
	level.zerosub_fog_on = true;
		
	foreach ( player in level.players )
	{
		player playFrostFogPlayer();
	}
}

playFrostFogPlayer( playImmediate )
{
	// self == player
	
	// Vision Set change, and exploders
	self VisionSetStage( 1, CONST_FOG_FADE_TIME );
	self thread playDoorWindowSnowCoverFX( playImmediate );
	
	// Screen effects
	self thread delayPlayLoopScreenFX( "frost", 4, CONST_FOG_FADE_TIME );
	self thread delayPlayLoopScreenFX( "snow", 1, CONST_FOG_FADE_TIME );
	self thread delayPlayLoopScreenFX( "breath", 3, CONST_FOG_FADE_TIME + 1 );		
}

stopFrostFog()
{
	level.zerosub_fog_on = false;	
	
	foreach ( player in level.players )
	{
		player VisionSetStage( 0, CONST_FOG_FADE_TIME );
	}	
}

watchPlayerConnect()
{
	level endon ( "game_ended" );
	level endon ( "frost_clear" );
	
	while ( true )
	{
		level waittill ( "connected", player );
		
		// Environment FX
		player playFrostFogPlayer( true );
		
		player thread startKillstreakWatchers();
	}
}

watchHostMigration()
{
	level endon ( "game_ended" );
	level endon ( "frost_clear" );
	
	while ( true )
	{
		level waittill ( "host_migration_end" );
		
		foreach ( player in level.players )
		{
			player VisionSetStage( 1, 0.1 );
		}
	}	
}

startKillstreakWatchers()
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	level endon ( "frost_clear" );

	self waittill ( "spawned_player" );
	
	// Watch the death ragdoll
	if ( self.team != level.zerosub_killstreak_user.team )
		self thread watchRagDoll();
}

playDoorWindowSnowCoverFX( playImmediate )
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	level endon ( "frost_clear" );
	
	if ( !IsDefined( playImmediate ) || !playImmediate )
	{
		// Make sure to only play this after the fog fades in
		wait ( CONST_FOG_FADE_TIME );
	}
	
	// Only show this to players indoors
	while ( true )
	{
		if ( !self isOutside() )
			exploder( EXPLODER_SNOW_DOORS_WINDOWS_ID, self );
		
		wait ( 0.5 );
	}
}

delayPlayLoopScreenFX( effectType, intervalTime, delayTime )
{
	// self == player
	
	self notify ( "playScreenFX_" + effectType );	
	self endon ( "playScreenFX_" + effectType );
	
	self endon ( "disconnect" );
	self endon ( "death" );
	level endon ( "game_ended" );
	level endon ( "frost_clear" );	
	
	// Replay the effect once they spawn back in
	self thread watchPlayerSpawnFX( effectType, intervalTime, 0.05 );	
	
	// We need to keep track of how long the effect will play, so we can delete it after it's done
	effectDuration = 0;
	
	switch ( effectType )
	{
		case "frost":
			effectDuration = 6;
		break;
		case "snow":
			effectDuration = 1;
		break;
		case "breath":	
			effectDuration = 1;
		break;
	}
	
	// The fog doesn't roll in right away, so we need to wait before playing this
	wait ( delayTime );
	
	while ( true )
	{
		// Play the screen effects under these conditions
		if ( ( !level.beastAllowedIndoors && self isOutside() ) ||							// Beasts are not allowed inside, and players are outside
		     ( level.beastAllowedIndoors && self isOutside() && effectType == "snow" ) || 	// Beast are allowed inside, and players are outside, and the effect type is "snow"	
		     ( level.beastAllowedIndoors && effectType != "snow" ) )						// Beast are allowed inside, and effect type is "frost" and "breath"
		{
			effect_ent = SpawnFXForClient( level.zerosub_fx[ effectType ][ "screen" ], self GetEye(), self );
			
			if ( IsDefined ( effect_ent ) )
			{
				TriggerFX( effect_ent );
				effect_ent setfxkilldefondelete();
				
				// Kill this previous effect on a delayed time, so it doesn't cut out right away
				effect_ent thread watchFXLifetime( effectDuration + 1 );
			}
		}	

		wait( intervalTime );
	}
}

isOutside()
{
	// self == player
	
	outside = true;
	
	if ( !IsDefined ( level.zerosub_inside_trigger ) )
		level.zerosub_inside_trigger = GetEnt ( "mp_zerosub_indoor_triggers", "targetname" );
	
	if ( IsDefined ( level.zerosub_inside_trigger ) )
	{
		if ( self IsTouching( level.zerosub_inside_trigger ) )
			outside = false;
	}
		
	return outside;
}

isBeingHunted()
{
	beingHunted = false;

	if ( IsDefined( self.isBeingHunted ) && self.isBeingHunted )
		beingHunted = true;
	
	return beingHunted;
}

watchFXLifetime( lifeTime )
{
	level endon ( "game_ended" );
	
	wait ( lifeTime );
		
	self delete();
}

killFXOnPlayerDeath( effect )
{
	level endon ( "game_ended" );
	
	self waittill_any ( "killed_player", "disconnect" );
	
	if ( IsDefined ( effect ) )
	{
		if ( IsArray( effect ) )
		{
			foreach ( fx in effect )
			{
				fx delete();
			}
		}
		else
			effect delete();
	}
}

watchPlayerSpawnFX( effectType, intervalTime, delayTime )
{
	// self == player
	
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	level endon ( "frost_clear" );
	
	self waittill ( "spawned_player" );
	
	self thread delayPlayLoopScreenFX( effectType, intervalTime, delayTime );
}

watchPlayerSpawn()
{
	level endon ( "game_ended" );
	
	while ( true )
	{		
		level waittill ( "player_spawned", player );
		
		if ( Isdefined( player.customDeath ) )
			player.customDeath = undefined;
		
		// Relink the killcam for the killstreak ( if it's still going )	
		if ( IsDefined( player.beastKillCam ) )
		{
			player.beastKillCam.origin = player.origin + ( 100, 100, 100 );
			player.beastKillCam LinkTo ( player );	
		}	
		
		// Let it Snow
		player thread playEnvironmentFX();
	}
}

playEnvironmentFX()
{
	// self == player
	
	self endon ( "disconnect" );
	self endon ( "death" );
	level endon ( "game_ended" );
	
	while ( true )
	{
		forwardVector = AnglesToForward( self.angles );
		
		// Play Snow if we are outside, and Dust particles while inside
		// Make sure we play it ahead of the player, so it keeps up with them as they are moving
		if ( self isOutside() )
		{	
			snowFX = SpawnFXForClient( level.zerosub_fx[ "snow" ][ "player" ], self.origin + ( forwardVector * 100 ), self );
			TriggerFX( snowFX );
			
			snowFX thread watchFXLifetime( 2 );
		}
		else
		{	
			dustFX = SpawnFXForClient( level.zerosub_fx[ "dust" ][ "player" ], self.origin + ( forwardVector * 100 ), self );
			TriggerFX( dustFX );
			
			dustFX thread watchFXLifetime( 2 );		
		}
		
		wait ( 1 );
	}
}

playCustomDeathFX( victim, sMeansOfDeath, eInflictor )
{	
	if ( isBeastMan( eInflictor ) )
	{
		// Make the victim do an instant ragdoll
		victim.customDeath = true;
		
		// Bloody Explosion - bllaarrggggghhhhh ( death sound )
		playerTagPos = victim GetTagOrigin( "j_mainroot" );			
		PlayFX( level.zerosub_fx[ "beast" ][ "blood_explosion" ], playerTagPos );				
	}
}

playCustomDeathSound( victim, sMeansOfDeath, eInflictor )
{
	if ( sMeansOfDeath == "MOD_MELEE" )
	{
		if ( isBeastMan( eInflictor ) )
		{
			type = "male";
			if ( victim hasFemaleCustomizationModel() )
				type = "female";
			
			victim PlaySound( "knife_death_"+ type );	
		}
	}
	else
		victim playDeathSound();
}

isBeastMan( eInflictor )
{
	beastMan = false;
	
	if ( IsDefined( eInflictor ) && IsAgent( eInflictor ) )
	{
		if ( eInflictor.agent_type == "beastmen" )
			beastMan = true;
	}
	
	return beastMan;
}

// Plays the hockey video on the TVs
tvs()
{
	foreach ( name in ["tv_hockey", "tv_hockey_scale1pt5"] ) {
		thread tvs_set(name);
	}
}

tvs_set(targetname)
{
	/# SetDevDvarIfUninitialized( "tv_debug", 0 ); #/
	if (!IsDefined(level._effect[targetname])) {
		error("level._effect["+targetname+"] not defined.");
	}
	num_tv_fx = 3;
	for (i=1; i<=num_tv_fx; i++) {
		if (!IsDefined(level._effect[targetname][i])) {
			error("level._effect["+targetname+"]["+i+"] not defined.");
		}
		if (!IsDefined(level.tv_info.effectLength[targetname][i])) {
			error("level.tv_info.effectLength["+targetname+"]["+i+"] not defined.");	
			level.tv_info.effectLength[targetname][i] = 1;			
		}
	}
	if (!IsDefined( level.tv_info.destroymodel[targetname] ) ) {
		error("level.tv_info.destroymodel["+targetname+"] not defined.");
		destroymodel = undefined;
	} else {
		destroymodel = level.tv_info.destroymodel[targetname];
	}
	
	tvs = GetEntArray(targetname, "targetname");
	if ( tvs.size == 0 ) {
		PrintLn( "^c * ERROR * No TVs found with targetname "+targetname+".");
	}
	foreach ( tv in tvs ) {
		tv setCanDamage(true);
		tv.isHealthy = true;
		tv.destroymodel = destroymodel;
		tv.fxtag = level.tv_info.tag[targetname];
		
		// Since the TVs are off for current gen, we are only going to play audio for next gen
		if ( IsDefined( tv.script_noteworthy ) )
		{
			tv thread playTVAudio( tv.script_noteworthy );
		}
		
		tv thread tv_death();
	}
	level.tv_fx_num = num_tv_fx;
	while (true) {
		prev_fx = level.tv_fx_num;
		level.tv_fx_num = RandomIntRange( 1, num_tv_fx );
		if (level.tv_fx_num >= prev_fx)
			level.tv_fx_num += 1;
		fx = level._effect[targetname][level.tv_fx_num];
		foreach ( tv in tvs ) {
			if ( tv.isHealthy ) {
				PlayFXOnTag( fx, tv, tv.fxtag );
				tv.currentFX = fx;
			}
		}
		wait level.tv_info.effectLength[targetname][level.tv_fx_num];
		
		/#tvs_remaining = false;
		foreach ( tv in tvs ) {
			if ( tv.isHealthy == true ) tvs_remaining = true;
		}
		if ( GetDvarInt( "tv_debug" ) ) {
			if (!tvs_remaining) {
				wait 1;
				thread tvs();
				return;
			}
		}#/
	}
}

playTVAudio( targetname )
{
	delay = 15;

	wait ( delay );
	
	if ( targetname == "tv_hockey_small_room" )
	{
		self PlayLoopSound( "mp_zerosub_tv_small_room" );
	}
	else
	{
		self PlayLoopSound( "mp_zerosub_tv_big_room" );
	}
}

tv_death()
{
	self endon("death");
	self.health = 10000;
	self waittill("damage");

	KillFXOnTag( self.currentFX, self, self.fxtag );
	self StopLoopSound();
	
	self SetModel( self.destroymodel );
	PlayFXOnTag( level._effect["tv_explode"], self, self.fxtag );
	playSoundAtPos(self.origin, "tv_shot_burst");
	
	self.isHealthy = false;
	self setCanDamage(false);
}

