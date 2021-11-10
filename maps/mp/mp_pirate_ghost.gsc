#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\gametypes\_hostmigration;
#include maps\mp\agents\_agent_utility;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;

CONST_KILLSTREAK_NAME = "pirate_ghostcrew";
CONST_DEBUG_NAME = "Pirate Ghosts";
CONST_CRATE_WEIGHT = 85;
CONST_AGENT_TYPE = "pirate";

CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME		= 5;
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER 	= 2;

CONST_GHOST_HAT_MODEL = "pirate_hat_iw6_ghost";
CONST_GHOST_HEALTH = 300;

CONST_MAX_GHOSTS = 10;
CONST_GHOST_RESPAWN_TIMER = 1;	// in seconds

// add to csv
// this script
// vehicle
// vehicle model
// ghost effect

// add killstreak and crate functions

// --------------------------------------------------------------
// Crate and general killstreak setup
// --------------------------------------------------------------
init()
{
	level._effect[ "ghost_spawn" ] = LoadFX( "vfx/moments/mp_pirate/vfx_pirate_ghost_vapor" );
	level._effect[ "ghost_trail" ] = LoadFX( "vfx/moments/mp_pirate/vfx_pirate_ghost_vapor_trail" );
	level._effect[ "ghost_blink" ] = LoadFX( "vfx/moments/mp_pirate/vfx_ghost_power_drain" );
}

setupCallbacks()
{
	level.agent_funcs[CONST_AGENT_TYPE] = level.agent_funcs["squadmate"];
	
	level.agent_funcs[CONST_AGENT_TYPE]["spawn"]			= ::spawn_agent_ghost;
	level.agent_funcs[CONST_AGENT_TYPE]["think"] 			= ::squadmate_agent_think;
	level.agent_funcs[CONST_AGENT_TYPE]["on_killed"]		= ::on_agent_squadmate_killed;
}

customCrateFunc()
{
	if(!IsDefined(game["player_holding_level_killstrek"]))
		game["player_holding_level_killstrek"] = false;
		
	if(!allowLevelKillstreaks() || game["player_holding_level_killstrek"])
		return;
	
	maps\mp\killstreaks\_airdrop::addCrateType(	"airdrop_assault", 
											   CONST_KILLSTREAK_NAME,
											   CONST_CRATE_WEIGHT,
											   maps\mp\killstreaks\_airdrop::killstreakCrateThink,
											   maps\mp\killstreaks\_airdrop::get_friendly_crate_model(), 
											   maps\mp\killstreaks\_airdrop::get_enemy_crate_model(),
											   &"MP_PIRATE_GHOSTCREW_USE"
											  );
	level thread watchForCrateUse();
}

watchForCrateUse()
{
	while( true )
	{
		level waittill("createAirDropCrate", dropCrate);

		if( IsDefined( dropCrate ) && IsDefined( dropCrate.crateType ) && dropCrate.crateType == CONST_KILLSTREAK_NAME )
		{	
			maps\mp\killstreaks\_airdrop::changeCrateWeight("airdrop_assault", CONST_KILLSTREAK_NAME, 0);
			captured = wait_for_capture(dropCrate);
			
			if(!captured)
			{
				//reEnable warhawk mortars care packages if it expires with out anyone picking it up
				maps\mp\killstreaks\_airdrop::changeCrateWeight( "airdrop_assault", CONST_KILLSTREAK_NAME, CONST_CRATE_WEIGHT );
			}
			else
			{
				//Once its picked up it needs to remain off.
				game["player_holding_level_killstrek"] = true;
				break;
			}
		}
	}
}

//death and capture are sent on the same frame but death is processed first :(
wait_for_capture(dropCrate)
{
	result = watch_for_air_drop_death(dropCrate);
	return !IsDefined(result); //If !isdefined the captured notify was also sent.
}

watch_for_air_drop_death(dropCrate)
{
	dropCrate endon("captured");
	
	dropCrate waittill("death");
	waittillframeend;
	
	return true;
}

customKillstreakFunc()
{
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/Care Package/" + CONST_DEBUG_NAME + "\" \"set scr_devgivecarepackage " + CONST_KILLSTREAK_NAME + "; set scr_devgivecarepackagetype airdrop_assault\"\n");
	AddDebugCommand("devgui_cmd \"MP/Killstreak/Level Event:5/" + CONST_DEBUG_NAME + "\" \"set scr_givekillstreak " + CONST_KILLSTREAK_NAME + "\"\n");
	
	level.killStreakFuncs[ CONST_KILLSTREAK_NAME ] = ::tryUseAgentKillstreak;
	
	level.killstreakWeildWeapons[ "pirate_agent_mp" ] = CONST_KILLSTREAK_NAME;
}

cusomBotKillstreakFunc()
{
	AddDebugCommand("devgui_cmd \"MP/Bots(Killstreak)/Level Events:5/" + CONST_DEBUG_NAME + "\" \"set scr_testclients_givekillstreak " + CONST_KILLSTREAK_NAME + "\"\n");
	maps\mp\bots\_bots_ks::bot_register_killstreak_func( CONST_KILLSTREAK_NAME,	maps\mp\bots\_bots_ks::bot_killstreak_simple_use );
}

// create agent
tryUseAgentKillstreak( lifeId, streakName ) // self == player with killstreak
{	
	setupCallbacks();
	
	self.ghostCount = 0;
	if ( self spawnGhost() )
	{
		thread playGhostMusic();
		
		// give the player 2 to start
		self thread delayedSpawnGhost();
		
		self thread teamPlayerCardSplash( "used_" + streakName, self );
		
		return true;
	}
	else 
	{
		return false;
	}
}

// this is almost identical to the version in agent_killstreak, except we use a different "pirate" type because we need different responses in the callbacks.
createSquadmate( victim ) 
{
	// limit the number of active "squadmate" agents allowed per game
	if( getNumActiveAgents( "squadmate" ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return undefined;
	}
	
	// limit the number of active agents allowed per player
	if( getNumOwnedActiveAgents( self ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return undefined;
	}
		
	nearestPathNode = self getValidSpawnPathNodeNearPlayer( false, true );
	if( !IsDefined(nearestPathNode) )
	{
		return undefined;
	}
	
	spawnOrigin = nearestPathNode.origin;
	spawnAngles = VectorToAngles( self.origin - nearestPathNode.origin );
	
	agent = maps\mp\agents\_agents::add_humanoid_agent( CONST_AGENT_TYPE, self.team, "reconAgent", spawnOrigin, spawnAngles, self, false, false, "veteran" );
	if( !IsDefined( agent ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	agent.killStreakType = "agent";	
	
	return agent;
}

// This is adapted from _agents.gsc::spawn_agent_player, except:
// 1. don't go through normal class / loadout pipeline, because that adds lots of random perks
// 2. force cqb personality
// 3. increase default health
// 4. don't allow crate usage
spawn_agent_ghost( optional_spawnOrigin, optional_spawnAngles, optional_owner, use_randomized_personality, respawn_on_death, difficulty )
{
	self endon("disconnect");
	
	while( !IsDefined(level.getSpawnPoint) )
	{
		waitframe();
	}
		
	if( self.hasDied )
	{
		wait( RandomIntRange(6, 10) );
	}
	
	self initPlayerScriptVariables( true );

	// allow killstreaks to pass in specific spawn locations
	if( IsDefined(optional_spawnOrigin) && IsDefined(optional_spawnAngles) )
	{
		spawnOrigin = optional_spawnOrigin;
		spawnAngles = optional_spawnAngles;
		
		self.lastSpawnPoint = SpawnStruct();
		self.lastSpawnPoint.origin = spawnOrigin;
		self.lastSpawnPoint.angles = spawnAngles;
	}
	else
	{
		spawnPoint 	= self [[level.getSpawnPoint]]();
		spawnOrigin = spawnpoint.origin;
		spawnAngles = spawnpoint.angles;
		
		// Player specific variables needed in damage processing
		self.lastSpawnPoint = spawnpoint;
	}
	self activateAgent();
	self.lastSpawnTime = GetTime();
	self.spawnTime = GetTime();
	
	phys_trace_start = spawnOrigin + (0,0,25);
	phys_trace_end = spawnOrigin;
	newSpawnOrigin = PlayerPhysicsTrace(phys_trace_start, phys_trace_end);
	if ( DistanceSquared( newSpawnOrigin, phys_trace_start ) > 1 )
	{
		// If the result from the physics trace wasn't immediately in solid, then use it instead
		spawnOrigin = newSpawnOrigin;
	}
	
	// called from code when an agent is done initializing after AddAgent is called
	// this should set up any state specific to this agent and game
	self SpawnAgent( spawnOrigin, spawnAngles );
	
	self maps\mp\bots\_bots_util::bot_set_personality( "cqb" );

	if ( IsDefined( difficulty ) )
		self maps\mp\bots\_bots_util::bot_set_difficulty( difficulty );
	
	// ?
	self maps\mp\agents\_agents::initPlayerClass();

	self maps\mp\agents\_agent_common::set_agent_health( 200 );
	if ( IsDefined(respawn_on_death) && respawn_on_death )
		self.respawn_on_death = true;
		
	// must set the team after SpawnAgent to fix a bug with weapon crosshairs and nametags
	if( IsDefined(optional_owner) )
		self set_agent_team( optional_owner.team, optional_owner );
		
	if( isDefined( self.owner ) )
		self thread maps\mp\agents\_agents::destroyOnOwnerDisconnect( self.owner );

	self thread maps\mp\_flashgrenades::monitorFlash();
		
	// switch to agent bot mode and wipe all AI info clean	
	self EnableAnimState( false );
			
	self [[level.onSpawnPlayer]]();
	// give this perk before the loadout, because we don't want it to be taken away later (all spawned players have a few seconds of immunity from killstreaks)
	self givePerk( "specialty_blindeye", false );
	self maps\mp\gametypes\_class::giveLoadout( self.team, self.class, true );
	isMelee = IsDefined( self.owner ) && IsDefined( self.owner.ghostCount ) && self.owner.ghostCount % 2 != 0;
	self customizeSquadmate( isMelee ); // use this to give loadout instead
	
	self thread maps\mp\bots\_bots::bot_think_watch_enemy( true );
//	self thread maps\mp\bots\_bots::bot_think_crate();	// don't allow ghosts to use crates
//	self thread maps\mp\bots\_bots::bot_think_level_actions();
	self thread maps\mp\bots\_bots_strategy::bot_think_tactical_goals();
	self thread [[ self agentFunc("think") ]]();
	
	if ( !self.hasDied )
		self maps\mp\gametypes\_spawnlogic::addToParticipantsArray();
	
	self.hasDied = false;
	
	self thread maps\mp\gametypes\_weapons::onPlayerSpawned();
	self thread maps\mp\gametypes\_healthoverlay::playerHealthRegen();
	// no battle chatter from ghost
//	self thread maps\mp\gametypes\_battlechatter_mp::onPlayerSpawned();
	
	level notify( "spawned_agent_player", self );
	level notify( "spawned_agent", self );
	self notify( "spawned_player" );
}

squadmate_agent_think()
{
	self endon( "death" );
	level endon( "game_ended" );
	
	if ( IsDefined( self.owner ) )
	{
		self endon( "owner_disconnect" );
	}
		
	while(1)
	{
		self BotSetFlag( "cautious", true );
		handled_by_gametype = self [[ self agentFunc("gametype_update") ]]();
		if ( !handled_by_gametype )
		{
			if ( !self bot_is_guarding_player( self.owner ) )
				self bot_guard_player( self.owner, 350 );
		}
		
		wait(0.05);
	}
}

on_agent_squadmate_killed(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self maps\mp\agents\_agents::on_humanoid_agent_killed_common(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration, false);
		
	// award XP for killing agents
	/*
	if( IsPlayer( eAttacker ) && IsDefined(self.owner) && eAttacker != self.owner )
	{
		self.owner leaderDialogOnPlayer( "squad_killed" );
		self maps\mp\gametypes\_damage::onKillstreakKilled( eAttacker, sWeapon, sMeansOfDeath, iDamage, "destroyed_squad_mate" );
	}
	*/
	
	pos = self GetTagOrigin( "j_mainroot" );
	angles = AnglesToForward( self.angles );
	body = self GetCorpseEntity();
	
	if ( sMeansOfDeath == "MOD_MELEE" )	// for some reason, I can't delete the body right away on a melee death
	{
		wait (0.75);
	}
	else
	{
		wait (0.5);
	}
	
	self maps\mp\agents\_agent_utility::deactivateAgent();
	
	// award XP for killing agents
	if( IsPlayer( eAttacker ) && IsDefined(self.owner) && eAttacker != self.owner )
	{
		self maps\mp\gametypes\_damage::onKillstreakKilled( eAttacker, sWeapon, sMeansOfDeath, iDamage );
	}
	
	
	if ( IsDefined( self.hat ) )
	{
		self.hat Delete();
	}
	
	PlayFx( getfx( "ghost_spawn" ), pos, angles );
	body PlaySound( "pir_ghost_death" );
	
	body delete();
}

customizeSquadmate( isMelee )
{
	// Set up visuals for squadmate
	if ( isMelee )
	{
		self SetModel( "pirate_ghost_2" );
	}
	else
	{
		self SetModel( "pirate_ghost_1" );
	}
	
	if( IsDefined( self.headModel ) )
	{
		self Detach( self.headModel, "" );
		self.headModel = undefined;
	}
	
	self PlaySound( "pir_ghost_reappear" );
	pos = self GetTagOrigin( "j_mainroot" );
	PlayFx( getfx( "ghost_spawn" ), pos, AnglesToForward( self.angles ) );
	
	self thread playTrailFx();
	
	// Set up weapons
	self TakeAllWeapons();
	if ( isMelee )
	{
		self GiveWeapon( "iw6_piratehook_mp" );
		self SwitchToWeapon( "iw6_piratehook_mp" );
		self BotSetFlag( "prefer_melee", true );
	}
	else
	{
		self GiveWeapon( "iw6_pirategun_mp_akimbo" );
		self SwitchToWeapon( "iw6_pirategun_mp_akimbo" );
	}
	
	// Set perks for squadmates so they don't show names, same as the player
	self givePerk( "specialty_spygame", false );
	self givePerk( "specialty_coldblooded", false );
	self givePerk( "specialty_noscopeoutline", false);
	self givePerk( "specialty_heartbreaker", false );
	self givePerk( "specialty_quieter", false );	// don't let ghosts rustle around
	
	self giveHat();
	
	self.health = CONST_GHOST_HEALTH;
	
	self SetSurfaceType( "snow" );	// !!! Hack-ish. see fx/maps/mp_battery3/iw_impacts.csv
	
	maps\mp\gametypes\_battlechatter_mp::disableBattleChatter( self );
	
	self thread watchBlink2();
	self thread ghostPlayVO( self.owner.ghostCount );
}

giveHat()
{
	hat = Spawn( "script_model", self.origin );
	hat SetModel( CONST_GHOST_HAT_MODEL );
	hat LinkTo( self, "j_head", (4, 0, 0), (90, 0, 0) );
	// hat LinkTo( self, "j_helmet" );
	self.hat = hat;
}

playTrailFx()
{
	self endon ( "death" );
	level endon( "game_ended" );
	
	wait ( 0.25 );
	PlayFXOnTag( getfx( "ghost_trail" ), self, "j_mainroot" );
}

playGhostMusic()
{
	PlaySoundAtPos( (878.641, 1408.98, 203), "mus_drunk_sailor" );
}

spawnGhost()
{
	agent = createSquadmate( self );
	if ( IsDefined( agent ) )
	{
		self.ghostCount++;
		
		if ( self.ghostCount >= CONST_MAX_GHOSTS )
		{
			level notify( "ghost_end" );
		}
		
		return true;
	}
	
	return false;
}

delayedSpawnGhost()
{
	wait( 0.5 );
	
	self spawnGhost();
}

ghostCloak()
{
	self.isCloaked = true;
	
	// play effect
	pos = self GetTagOrigin( "j_mainroot" );
	PlayFx( getfx( "ghost_blink" ), pos, AnglesToForward( self.angles ) );
	
	// play sound
	self PlaySound( "pir_ghost_disappear" );
	
	// store old model
	self.oldModel = self.model;
	
	// swap model
	self SetModel( self.oldModel + "_cloak" );
	
	// fix hat
	self.hat SetModel( CONST_GHOST_HAT_MODEL + "_cloak" );
}

ghostUncloak()
{
	// play effect
	pos = self GetTagOrigin( "j_mainroot" );
	PlayFx( getfx( "ghost_blink" ), pos, AnglesToForward( self.angles ) );
	
	// play sound
	self PlaySound( "pir_ghost_reappear" );
	
	// swap model
	self SetModel( self.oldModel );
	
	// fix hat
	self.hat SetModel( CONST_GHOST_HAT_MODEL );
	
	self.isCloaked = undefined;
}

watchBlink2()
{
	self endon( "death" );
	
	while ( true )
	{
		self waittill( "damage" );
		
		if ( !IsDefined( self.isCloaked ) )
		{
			self ghostCloak();
		}
		
		self thread ghostWaitForUncloak();
	}
}

ghostWaitForUncloak()
{
	self notify( "ghostDamageTimer" );
	self endon( "ghostDamageTimer" );
	self endon( "death" );
	
	wait( 4.0 );
	
	self ghostUncloak();
}

GHOST_VO_COOLDOWN = 2000;	// in ms INCREASE IN SHIP
ghostPlayVO( voIndex )
{
	self endon( "death" );
	level endon( "game_ended" );
	
	// want to try to make sure each line is unique
	voSets = [ "mp_pirate_prt1_ghost", "mp_pirate_prt2_ghost", "mp_pirate_cpt_ghost" ];
	if ( !IsDefined( voIndex ) )
	{
		voIndex = RandomInt( 0, voSets.size );
	}
	else
	{
		voIndex = voIndex % voSets.size;
	}
	voAlias = voSets[ voIndex ];
	
	self.owner.ghostVoTimeStamp = GetTime() + 1000;	// make sure the ghosts don't speak right away
	
	while ( IsDefined( self.owner ) )
	{
		self.owner waittill( "killed_enemy", victim, sWeapon, sMeansOfDeath );
		
		if ( sWeapon == "pirate_agent_mp" && GetTime() > self.owner.ghostVoTimeStamp )
		{
			self.owner.ghostVoTimeStamp = GetTime() + GHOST_VO_COOLDOWN;
			
			self PlaySound( voAlias );
		}
	}
}

// debug
/*
testGhost()
{
	level endon( "game_ended" );
	
	while ( true )
	{
		level waittill ( "connected", player );
		if ( player IsHost() )
		{
			break;
		}
	}
	
	player waittill( "spawned_player" );
	
	wait( 1 );
	
	player thread maps\mp\killstreaks\_killstreaks::giveKillstreak( CONST_KILLSTREAK_NAME, false, false, player );
}
*/