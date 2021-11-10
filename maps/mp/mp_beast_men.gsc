#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\gametypes\_hostmigration;
#include maps\mp\agents\_agent_utility;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;

CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME		= 5;
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER 	= 3;
CONST_AGENT_TYPE = "beastmen";
CONST_AGENT_HEALTH = 500;

// --------------------------------------------------------------
// Crate and general killstreak setup
// --------------------------------------------------------------
init()
{
	// TODO: Setup any FX related to the agents
}

setupCallbacks()
{
	level.agent_funcs[CONST_AGENT_TYPE] = level.agent_funcs["squadmate"];
	
	level.agent_funcs[CONST_AGENT_TYPE]["spawn"]	 = ::spawn_agent_beast;
	level.agent_funcs[CONST_AGENT_TYPE]["think"] 	 = ::squadmate_agent_think;
	level.agent_funcs[CONST_AGENT_TYPE]["on_killed"] = ::on_agent_squadmate_killed;
}

// create agent
tryUseAgentKillstreak( lifeId, streakName ) 
{	
	// self == player with killstreak
	
	setupCallbacks();
	
	self.beastCount = 0;
	
	self thread delayedSpawnBeast( 5 );
	
	return true;
}

spawnBeast()
{
	// self == player with killstreak 
	
	agent = createSquadmate();
	if ( IsDefined( agent ) )
	{
		self.beastCount++;
		
		if ( self.beastCount < CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER )
		{
			self thread delayedSpawnBeast( 0.5 );
		}
		
		return true;
	}
	
	return false;
}

delayedSpawnBeast( delayTime )
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	wait( delayTime );
	
	self spawnBeast();
}

createSquadmate( spawnOverride ) 
{
//	// limit the number of active "squadmate" agents allowed per game
//	if( getNumActiveAgents( "squadmate" ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME )
//	{
//		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
//		return undefined;
//	}
//	
//	// limit the number of active agents allowed per player
//	if( getNumOwnedActiveAgents( self ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER )
//	{
//		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
//		return undefined;
//	}
	
	// Find a spawn location from the provided structs
	spawnOrigin = findSpawnLocation();

	// This is used when we are teleporting the beast man to another position
	if ( IsDefined( spawnOverride ) )
		spawnOrigin = spawnOverride;
	
	spawnAngles = VectorToAngles( self.origin - spawnOrigin );
	
	agent = maps\mp\agents\_agents::add_humanoid_agent( CONST_AGENT_TYPE, self.team, "reconAgent", spawnOrigin, spawnAngles, self, false, false, "veteran" );
	if( !IsDefined( agent ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	agent.killStreakType = "agent";	
	
	return agent;
}

spawn_agent_beast( optional_spawnOrigin, optional_spawnAngles, optional_owner, use_randomized_personality, respawn_on_death, difficulty )
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

	self maps\mp\agents\_agent_common::set_agent_health( CONST_AGENT_HEALTH );
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
	self maps\mp\gametypes\_class::giveLoadout( self.team, self.class, true );
	self customizeSquadmate(); // use this to give loadout instead
	
	self thread maps\mp\bots\_bots::bot_think_watch_enemy( true );
	// self thread maps\mp\bots\_bots::bot_think_crate();
	//self thread maps\mp\bots\_bots::bot_think_level_actions();
	self thread maps\mp\bots\_bots_strategy::bot_think_tactical_goals();
	self thread [[ self agentFunc("think") ]]();
	
	if ( !self.hasDied )
		self maps\mp\gametypes\_spawnlogic::addToParticipantsArray();
	
	self.hasDied = false;
	
	self thread maps\mp\gametypes\_weapons::onPlayerSpawned();
	self thread maps\mp\gametypes\_healthoverlay::playerHealthRegen();
	
	level notify( "spawned_agent_player", self );
	level notify( "spawned_agent", self );
	self notify( "spawned_player" );
	
	// Start surrounding FX
	self.environmentState = "outdoors";
	self thread delaySoundFX( "zerosub_monster_breath_only_lp", 0.05 );
	self thread delaySoundFX( "zerosub_monster_steps_only_ext_lp", 0.10 );	
	self thread delayPlayFXOnTag( level._effect[ "vfx_yeti_snowcover_upflip" ], "tag_origin", 0.05, 0.5 );
	self playEyeFX();
	
	self thread watchBeastMovement();	
	self thread watchKillstreakEnd();
}

squadmate_agent_think()
{
	self endon( "death" );
	level endon( "game_ended" );
	
	if ( IsDefined( self.owner ) )
	{
		self endon( "owner_disconnect" );
	}
		
	self BotSetFlag( "force_sprint", true );
}

on_agent_squadmate_killed(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self maps\mp\agents\_agents::on_humanoid_agent_killed_common(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration, false);
	
	body = self GetCorpseEntity();
	
	// Play Despawn FX
	PlayFx( level._effect[ "vfx_yeti_snowcover_dissolve" ], self.origin );
	self PlaySound( "mp_zerosub_monster_death" );
	
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
		self maps\mp\gametypes\_damage::onKillstreakKilled( eAttacker, sWeapon, sMeansOfDeath, iDamage, "destroyed_ks_beast_man" );
	}
	
	body delete();
}

customizeSquadmate()
{
	// Set up visuals for squadmate
	self SetModel( "mp_fullbody_beast_man" );

	if( IsDefined( self.headModel ) )
	{
		self Detach( self.headModel, "" );
		self.headModel = undefined;
	}
	
	// Play Spawn FX
	PlayFx( level._effect[ "vfx_yeti_snowcover_upflip" ], self.origin );

	// Set up weapons
	mainWeapon = "iw6_knifeonlybeast_mp";
	
	self TakeAllWeapons();
	self GiveWeapon( mainWeapon );
	self SwitchToWeapon( mainWeapon );
	self BotSetFlag( "prefer_melee", true );
	
	// Set perks for squadmates so they don't show names, same as the player
	self givePerk( "specialty_spygame", false );
	self givePerk( "specialty_coldblooded", false );
	self givePerk( "specialty_noscopeoutline", false);
	self givePerk( "specialty_heartbreaker", false );
	self givePerk( "specialty_quieter", false );	// don't let ghosts rustle around
	
	// Regive Blind Eye after they are removed from the agent
	self thread watchRemovePerks();
	
	self.health = CONST_AGENT_HEALTH;
	
	// Make sure when they take melee damage, that they only take 100 max
	self.customMeleeDamageTaken = 100;
	
	self SetSurfaceType( "snow" );	// !!! Hack-ish. see fx/maps/mp_battery3/iw_impacts.csv
	
	maps\mp\gametypes\_battlechatter_mp::disableBattleChatter( self );
}

watchRemovePerks()
{
	self endon( "death" );
	level endon( "game_over" );
	
	self waittill( "starting_perks_unset" );
	
	self givePerk( "specialty_blindeye", false );
}

delaySoundFX( sound, delayTime )
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	wait ( delayTime );	
	
	self PlayLoopSound( sound );
	
}

delayPlayFXOnTag( FX, tag, delayTime, intervalTime )
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	wait ( delayTime );
	
	while ( true )
	{
		PlayFXOnTag( FX, self, tag );
		
		if ( IsDefined( intervalTime ) )
			wait( intervalTime ) ;
		else
			break;
	}
}

playEyeFX()
{
	forwardVector = AnglesToForward( self.angles ) * 30;
	rightVector = AnglesToRight( self.angles ) * 7;

	// Setup the left eye of the beast
	vertOffset = ( 0, 0, 65 );
	self thread createEyeFX( "left", self.origin + forwardVector + rightVector + vertOffset );
	
	// Setup the right eye of the beast 
	self thread createEyeFX( "right", self.origin + forwardVector - rightVector + vertOffset );
}

createEyeFX( eye, fxPos )
{
	self endon( "death" );
	level endon( "game_ended" );
	
	if ( eye == "left" )
	{
		self.leftEyeObj = Spawn( "script_model", fxPos );
		self.leftEyeObj SetModel( "tag_origin" );
		self.leftEyeObj LinkTo( self );
		self.leftEyeObj delayPlayFXOnTag( level.zerosub_fx[ "beast" ][ "eyeglow" ], "tag_origin", 0.05, 0.5 );
	}
	else
	{
		self.rightEyeObj = Spawn( "script_model", fxPos );
		self.rightEyeObj SetModel( "tag_origin" );
		self.rightEyeObj LinkTo( self );
		self.rightEyeObj delayPlayFXOnTag( level.zerosub_fx[ "beast" ][ "eyeglow" ], "tag_origin", 0.05, 0.5 );
	}
}

watchBeastMovement()
{
	level endon ( "game_ended" );
	level endon ( "frost_clear" );
	
	while ( true )
	{
		if ( !self maps\mp\mp_zerosub::isOutside() )
		{
			if ( !level.beastAllowedIndoors )
			{
				// Everytime to go inside, they will "die" and "respawn" in another location
				newSpawnLocation = findSpawnLocation( self.origin );
				
				if ( IsDefined( newSpawnLocation ) )
				{
					// Despawn
					self DoDamage( 10000, self.origin );
					
					wait ( 1 );
					
					// Respawn
					level.zerosub_killstreak_user createSquadmate( newSpawnLocation );
					break;
				}
			}

			// Make sure we stop all sounds on the beast, and play their interior sounds
			if ( self.environmentState != "indoors" )
			{
				self.environmentState = "indoors";
				self StopSounds();
			
				wait ( 0.3 );
			
				self thread delaySoundFX( "zerosub_monster_breath_only_lp", 0.05 );
				self thread delaySoundFX( "zerosub_monster_steps_only_int_lp", 0.10 );
			}
		}
		else 
		{
			// We only want to reset the beast sounds if they transition from indoors to outdoors
			if ( self.environmentState != "outdoors" )
			{
				self.environmentState = "outdoors";
				self StopSounds();
			
				wait ( 0.3 );
			
				self thread delaySoundFX( "zerosub_monster_breath_only_lp", 0.05 );
				self thread delaySoundFX( "zerosub_monster_steps_only_ext_lp", 0.10 );
			}
		}
		
		waitframe();
	}
}

findSpawnLocation( oldPosition )
{
	// Look through the structs of beast men spawn locations ( zerosub_beast_spawn ) and find the furthest one from its current location
	spawnPoint = undefined;
	locations = getStructArray( "zerosub_beast_spawn", "targetname" );
	
	if ( !IsDefined ( locations ) || locations.size == 0 )
	{
		AssertMsg( "This should never happen.  Locations should be defined for the beast men" );
		return undefined;
	}
	
	// If we already have an old location, that means the beast man hit the indoor area, which will reset them back outside to another spawn
	if ( isDefined ( oldPosition ) )
	{
		furthestDist = undefined;
		
		foreach ( loc in locations )
		{
			newDist = Distance2DSquared( oldPosition, loc.origin );
			
			if ( !IsDefined( furthestDist ) || furthestDist < newDist )
			{
				furthestDist = newDist;
				spawnPoint = loc.origin;
			}
		}
	}
	else
	{
		// If this is the first time spawning in, then randomly choose one of the available locations
		randomIndex = RandomInt( locations.size );
		spawnPoint	= locations[ randomIndex ].origin;
	}
		
	return spawnPoint;
}

watchKillstreakEnd()
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	level waittill ( "frost_clear" );
	
	self DoDamage( 10000, self.origin );
	self.leftEyeObj Delete();
	self.rightEyeObj Delete();
}