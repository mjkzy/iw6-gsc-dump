#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_damage;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\agents\_agent_utility;

//=======================================================================
//								main 
// This is functions is called directly from native code on game startup
// The particular gametype's main() is called from native code afterward
//=======================================================================
main()
{
	if( IsDefined( level.createFX_enabled ) && level.createFX_enabled )
		return;

	setup_callbacks();

	// Enable badplaces in destructibles
	level.badplace_cylinder_func 	= ::badplace_cylinder;
	level.badplace_delete_func 		= ::badplace_delete;
	
	/#
	level thread monitor_scr_agent_players();
	#/	
	
	level thread maps\mp\agents\_agent_common::init();
	level thread maps\mp\killstreaks\_agent_killstreak::init();
	level thread maps\mp\killstreaks\_dog_killstreak::init();
}


//========================================================
//					setup_callbacks 
//========================================================
setup_callbacks()
{
	if ( !IsDefined( level.agent_funcs ) )
		level.agent_funcs = [];
	
	level.agent_funcs["player"] = [];
	
	level.agent_funcs["player"]["spawn"] 				= ::spawn_agent_player;
	level.agent_funcs["player"]["think"] 				= maps\mp\bots\_bots_gametype_war::bot_war_think;
	level.agent_funcs["player"]["on_killed"]			= ::on_agent_player_killed;
	level.agent_funcs["player"]["on_damaged"]			= ::on_agent_player_damaged;
	level.agent_funcs["player"]["on_damaged_finished"]	= ::agent_damage_finished;
	
	maps\mp\killstreaks\_agent_killstreak::setup_callbacks();
	maps\mp\killstreaks\_dog_killstreak::setup_callbacks();
}

wait_till_agent_funcs_defined()
{
	while( !IsDefined(level.agent_funcs) )
		wait(0.05);	
}


/#
//=======================================================
//				new_scr_agent_team
//=======================================================
new_scr_agent_team()
{
	teamCounts = [];
	teamCounts["allies"] = 0;
	teamCounts["axis"] = 0;
	minTeam = undefined;
	foreach( player in level.participants )
	{
		if ( !IsDefined( teamCounts[player.team] ) )
			teamCounts[player.team] = 0;
		if ( IsTeamParticipant( player ) )
			teamCounts[player.team]++;
	}
	foreach ( team, count in teamCounts )
	{
		if ( (team != "spectator") && (!IsDefined(minTeam) || teamCounts[minTeam] > count) )
			minTeam = team;
	}
	
	return minTeam;
}

//=======================================================
//				monitor_scr_agent_players
//=======================================================
monitor_scr_agent_players()
{
	SetDevDvarIfUninitialized( "scr_agent_players_add", "0" );
	SetDevDvarIfUninitialized( "scr_agent_players_drop", "0" );
	
	while(level.players.size == 0)
		wait(0.05);		// Agents don't exist until a player connects
	
	for( ;; ) 
	{
		wait(0.1);
		
		add_agent_players = getdvarInt("scr_agent_players_add");
		drop_agent_players = getdvarInt("scr_agent_players_drop");

		if ( add_agent_players != 0 )
			SetDevDvar( "scr_agent_players_add", 0 );
		
		if ( drop_agent_players != 0 )
			SetDevDvar( "scr_agent_players_drop", 0 );
		
		for ( i = 0; i < add_agent_players; i++ )
		{
			agent = add_humanoid_agent( "player", new_scr_agent_team(), undefined, undefined, undefined, undefined, true, true );
			if ( IsDefined( agent ) )
				agent.agent_teamParticipant = true;
		}
		
		foreach ( agent in level.agentArray )
		{
			if ( !IsDefined( agent.isActive ) )
				continue;
			
			if ( IsDefined( agent.isActive ) && agent.isActive && agent.agent_type == "player" )
			{
				if ( drop_agent_players > 0 )
				{
					agent maps\mp\agents\_agent_utility::deactivateAgent();
					agent Suicide();
					drop_agent_players--;
				}
			}
		}
	}
}
#/

	
//=======================================================
//				add_humanoid_agent
//=======================================================
add_humanoid_agent( agent_type, team, class, optional_spawnOrigin, optional_spawnAngles, optional_owner, use_randomized_personality, respawn_on_death, difficulty )
{
	agent = maps\mp\agents\_agent_common::connectNewAgent( agent_type, team, class );
		
	if( IsDefined( agent ) )
	{
		agent thread [[ agent agentFunc("spawn") ]]( optional_spawnOrigin, optional_spawnAngles, optional_owner, use_randomized_personality, respawn_on_death, difficulty );
	}
	
	return agent;
}
	
	
//========================================================
//					spawn_agent_player
//========================================================
spawn_agent_player( optional_spawnOrigin, optional_spawnAngles, optional_owner, use_randomized_personality, respawn_on_death, difficulty )
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
	
	if ( IsDefined(use_randomized_personality) && use_randomized_personality )
	{
		/#
 		self maps\mp\bots\_bots::bot_set_personality_from_dev_dvar();
	 	#/
		self maps\mp\bots\_bots_personality::bot_assign_personality_functions();	// Randomized personality was already set, so just need to setup functions
	}
	else
	{
		self maps\mp\bots\_bots_util::bot_set_personality( "default" );
	}

	if ( IsDefined( difficulty ) )
		self maps\mp\bots\_bots_util::bot_set_difficulty( difficulty );

	self initPlayerClass();

	self maps\mp\agents\_agent_common::set_agent_health( 100 );
	if ( IsDefined(respawn_on_death) && respawn_on_death )
		self.respawn_on_death = true;
		
	// must set the team after SpawnAgent to fix a bug with weapon crosshairs and nametags
	if( IsDefined(optional_owner) )
		self set_agent_team( optional_owner.team, optional_owner );
		
	if( isDefined( self.owner ) )
		self thread destroyOnOwnerDisconnect( self.owner );

	self thread maps\mp\_flashgrenades::monitorFlash();
		
	// switch to agent bot mode and wipe all AI info clean	
	self EnableAnimState( false );
			
	self [[level.onSpawnPlayer]]();
	self maps\mp\gametypes\_class::giveLoadout( self.team, self.class, true );
	
	self thread maps\mp\bots\_bots::bot_think_watch_enemy( true );
	self thread maps\mp\bots\_bots::bot_think_crate();
	if ( self.agent_type == "player" )
		self thread maps\mp\bots\_bots::bot_think_level_actions();
	else if ( self.agent_type == "odin_juggernaut" )
		self thread maps\mp\bots\_bots::bot_think_level_actions( 128 );
	self thread maps\mp\bots\_bots_strategy::bot_think_tactical_goals();
	self thread [[ self agentFunc("think") ]]();
	
	if ( !self.hasDied )
		self maps\mp\gametypes\_spawnlogic::addToParticipantsArray();
	
	self.hasDied = false;
	
	self thread maps\mp\gametypes\_weapons::onPlayerSpawned();
	self thread maps\mp\gametypes\_healthoverlay::playerHealthRegen();
	self thread maps\mp\gametypes\_battlechatter_mp::onPlayerSpawned();
	
	level notify( "spawned_agent_player", self );
	level notify( "spawned_agent", self );
	self notify( "spawned_player" );
}


//========================================================
//				destroyOnOwnerDisconnect 
//========================================================
destroyOnOwnerDisconnect( owner )
{
	self endon( "death" );
	
	owner waittill( "killstreak_disowned" );
	
	self notify( "owner_disconnect" );

	// Wait till host migration finishes before suiciding
	if ( maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone() )
		wait 0.05;
	
	// kill the agent
	self Suicide();
}


//========================================================
//				agent_damage_finished 
//========================================================
agent_damage_finished( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
 	if( IsDefined( eInflictor ) || IsDefined( eAttacker ) )
 	{
	 	if( !IsDefined( eInflictor ) )
	 		eInflictor = eAttacker;
	 
	 	if( isdefined(self.allowVehicleDamage) && !self.allowVehicleDamage )
	 	{
		 	if( IsDefined( eInflictor.classname ) && eInflictor.classname == "script_vehicle" )
		 		return false;
	 	}
	 	
	 	if( IsDefined( eInflictor.classname ) && eInflictor.classname == "auto_turret" )
	 		eAttacker = eInflictor;
	 
	 	if( IsDefined( eAttacker ) && sMeansOfDeath != "MOD_FALLING" && sMeansOfDeath != "MOD_SUICIDE" )
	 	{
			if( level.teamBased )
			{
				if( IsDefined( eAttacker.team ) && eAttacker.team != self.team )
				{
	 				self SetAgentAttacker( eAttacker );
				}
			}
			else
			{
		 		self SetAgentAttacker( eAttacker );
			}
	 	}
 	}

 	Assert(IsDefined(self.isActive) && self.isActive);
	self FinishAgentDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, 0.0 );
	if ( !IsDefined(self.isActive) )
	{
		// Agent just died and cleared out all his script variables
		// So don't allow this agent to be freed up until he is properly deactivated in deactivateAgentDelayed
		self.waitingToDeactivate = true;
	}
	return true;
}


//=======================================================
//				on_agent_generic_damaged
//=======================================================
on_agent_generic_damaged( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	attckerIsOwner 		= IsDefined(eAttacker) && IsDefined(self.owner) && (self.owner == eAttacker);
	attackerIsTeammate 	= attackerIsHittingTeam( self.owner, eAttacker ) || attckerIsOwner;
		
	// ignore friendly fire damage for team based modes
	if( level.teambased && attackerIsTeammate && !level.friendlyfire )
		return false;
	
	// ignore damage from owner in non team based modes
	if( !level.teambased && attckerIsOwner )
		return false;
		
	// don't let helicopters and other vehicles crush a player, if we want it to then put in a special case here
	if( IsDefined( sMeansOfDeath ) && sMeansOfDeath == "MOD_CRUSH" && IsDefined( eInflictor ) && IsDefined( eInflictor.classname ) && eInflictor.classname == "script_vehicle" )
		return false;

	if ( !IsDefined( self ) || !isReallyAlive( self ) )
		return false;
	
	if ( IsDefined( eAttacker ) && eAttacker.classname == "script_origin" && IsDefined( eAttacker.type ) && eAttacker.type == "soft_landing" )
		return false;

	if ( sWeapon == "killstreak_emp_mp" )
		return false;

	if ( sWeapon == "bouncingbetty_mp" && !maps\mp\gametypes\_weapons::mineDamageHeightPassed( eInflictor, self ) )
		return false;
	
	// JC-ToDo: - Kept this here in case I bring back mine logic for the mk32
//	if ( sWeapon == "xm25_mp" && sMeansOfDeath == "MOD_IMPACT" )
//		iDamage = 95;
 
	// ensure throwing knife death
	if ( ( sWeapon == "throwingknife_mp" || sWeapon == "throwingknifejugg_mp" ) && sMeansOfDeath == "MOD_IMPACT" )
		iDamage = self.health + 1;

	// ensures stuck death
	if ( IsDefined( eInflictor ) && IsDefined( eInflictor.stuckEnemyEntity ) && eInflictor.stuckEnemyEntity == self ) 
		iDamage = self.health + 1;

	if( iDamage <= 0 )
 		return false;
 	
	if ( IsDefined( eAttacker ) && eAttacker != self && iDamage > 0 && ( !IsDefined( sHitLoc ) || sHitLoc != "shield" ) )
	{
		if( iDFlags & level.iDFLAGS_STUN )
			typeHit = "stun";
		else if( !shouldWeaponFeedback( sWeapon ) )
			typeHit = "none";
		else
			typeHit = ter_op( iDamage >= self.health, "hitkill" ,"standard" ); // adds final kill hitmarker to dogs
				
		eAttacker thread maps\mp\gametypes\_damagefeedback::updateDamageFeedback( typeHit );
	}
	
	if ( IsDefined( level.modifyPlayerDamage ) )	
		iDamage = [[level.modifyPlayerDamage]]( self, eAttacker, iDamage, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc );

	return self [[ self agentFunc( "on_damaged_finished" ) ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
}


//========================================================
//					on_agent_player_damaged 
//========================================================
on_agent_player_damaged( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	attckerIsOwner = IsDefined(eAttacker) && IsDefined(self.owner) && (self.owner == eAttacker);
	
	// ignore damage from owner in non team based modes
	if( !level.teambased && attckerIsOwner )
		return false;
	
	Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
}
	

//=======================================================
//					on_agent_player_killed
//=======================================================
on_agent_player_killed(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self on_humanoid_agent_killed_common(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration, true);
	
	// award XP for killing agents
	if( isPlayer( eAttacker ) && (!isDefined(self.owner) || eAttacker != self.owner) )
	{
		// TODO: should play vo for killing the agent
		self maps\mp\gametypes\_damage::onKillstreakKilled( eAttacker, sWeapon, sMeansOfDeath, iDamage, "destroyed_squad_mate" );
	}
	
	self maps\mp\gametypes\_weapons::dropScavengerForDeath( eAttacker );
	
	if ( self.isActive )
	{
		self.hasDied = true;
		
		if ( getGametypeNumLives() != 1 && ( IsDefined(self.respawn_on_death) && self.respawn_on_death ) )
		{
			self thread [[ self agentFunc("spawn") ]]();
		}
		else
		{
			self deactivateAgent();
		}
	}
}


//=======================================================
//			on_humanoid_agent_killed_common
//=======================================================
on_humanoid_agent_killed_common(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration, dropWeapons )
{
	// Things that happen on every type of humanoid agent that dies
	
	if ( self.hasRiotShieldEquipped )
	{
		self LaunchShield( iDamage, sMeansofDeath );
		
		if ( !dropWeapons )
		{
			// If not dropping weapons, need to make sure we at least drop the riot shield
			item = self dropItem( self GetCurrentWeapon() );
			
			if( IsDefined(item) )
			{
				item thread maps\mp\gametypes\_weapons::deletePickupAfterAWhile();
				item.owner = self;
				item.ownersattacker = eAttacker;
				item MakeUnusable();
			}
		}
	}
	
	if ( dropWeapons )
		self [[level.weaponDropFunction]]( eAttacker, sMeansOfDeath );
	
	// ragdoll
	self.body = self CloneAgent( deathAnimDuration );
	thread delayStartRagdoll( self.body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath );
	
	self riotShield_clear();
}


//===========================================
// 				initPlayerClass
//===========================================
initPlayerClass()
{
	// Must be called AFTER agent has been spawned as a bot agent
	if ( IsDefined(self.class_override) )
	{
		self.class = self.class_override;
	}
	else
	{
		if ( self maps\mp\bots\_bots_loadout::bot_setup_loadout_callback() )
			self.class = "callback";
		else
			self.class = "class1";
	}
}
