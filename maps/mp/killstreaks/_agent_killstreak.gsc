#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\agents\_agent_utility;
#include maps\mp\gametypes\_damage;
#include maps\mp\bots\_bots_util;
#include maps\mp\bots\_bots_strategy;

//===========================================
// 				constants
//===========================================
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME		= 5;
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER 	= 2;


//===========================================
// 					init
//===========================================
init()
{
	level.killStreakFuncs["agent"] 			= ::tryUseSquadmate;
	level.killStreakFuncs["recon_agent"] 	= ::tryUseReconSquadmate;
}


//===========================================
// 				setup_callbacks
//===========================================
setup_callbacks()
{
	level.agent_funcs["squadmate"] = level.agent_funcs["player"];
	
	level.agent_funcs["squadmate"]["think"] 		= ::squadmate_agent_think;
	level.agent_funcs["squadmate"]["on_killed"]		= ::on_agent_squadmate_killed;
	level.agent_funcs["squadmate"]["on_damaged"]	= maps\mp\agents\_agents::on_agent_player_damaged;
	level.agent_funcs["squadmate"]["gametype_update"]= ::no_gametype_update;
}

no_gametype_update()
{
	return false;
}

//===========================================
// 				tryUseSquadmate
//===========================================
tryUseSquadmate( lifeId, streakName )
{
	return useSquadmate( "agent" );
}


//===========================================
// 			tryUseReconSquadmate
//===========================================
tryUseReconSquadmate( lifeId, streakName )
{
	return useSquadmate( "reconAgent" );
}


//===========================================
// 				useSquadmate
//===========================================
useSquadmate( killStreakType )
{
	// limit the number of active "squadmate" agents allowed per game
	if( getNumActiveAgents( "squadmate" ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_GAME )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	// limit the number of active agents allowed per player
	if( getNumOwnedActiveAgents( self ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
		
	// try to spawn the agent on a path node near the player
	nearestPathNode = self getValidSpawnPathNodeNearPlayer( false, true );
	
	if( !IsDefined(nearestPathNode) )
	{
		return false;
	}

	// make sure the player is still alive before the agent trys to spawn on the player
	if( !isReallyAlive(self) )
	{
		return false;
	}
	
	spawnOrigin = nearestPathNode.origin;
	spawnAngles = VectorToAngles( self.origin - nearestPathNode.origin );
	
	agent = maps\mp\agents\_agents::add_humanoid_agent( "squadmate", self.team, undefined, spawnOrigin, spawnAngles, self, false, false, "veteran" );
	if( !IsDefined( agent ) )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	agent.killStreakType = killStreakType;	
	
	if ( agent.killStreakType == "reconAgent" )
	{
		// 2013-06-26 wallace
		// At the time of this comment, giveLoadout runs and finishes execution immediately
		// We run sendAgentWeaponNotify and finishReconAgentLoadout since they block until giveLoadout sends its notify
		agent thread sendAgentWeaponNotify( "iw6_riotshield_mp" );
		agent thread finishReconAgentLoadout();
		agent thread maps\mp\gametypes\_class::giveLoadout( self.pers["team"], "reconAgent", false );
		agent maps\mp\agents\_agent_common::set_agent_health( 250 ); 
		agent maps\mp\perks\_perkfunctions::setLightArmor();
	}
	else
	{
		agent maps\mp\perks\_perkfunctions::setLightArmor();
	}

	agent _setNameplateMaterial( "player_name_bg_green_agent", "player_name_bg_red_agent" );
	
	self maps\mp\_matchdata::logKillstreakEvent( agent.killStreakType, self.origin );
	
	return true;
}

finishReconAgentLoadout()
{
	self  endon( "death" );
	self  endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill( "giveLoadout" );
	
	self maps\mp\perks\_perkfunctions::setLightArmor();
	self givePerk( "specialty_quickswap", false );
	self givePerk( "specialty_regenfaster", false );
	
	// 2014-04-24 JC: Reduced accuracy on Squad Mate Support Streak
	self BotSetDifficultySetting( "minInaccuracy", 1.5 * self BotGetDifficultySetting( "minInaccuracy" ) );
	self BotSetDifficultySetting( "maxInaccuracy", 1.5 * self BotGetDifficultySetting( "maxInaccuracy" ) );
	// 2014-04-24 JC: Reduced fire rate on Squad Mate Support Streak
	// min: from 200 to 300
	// max: from 400 to 500
	self BotSetDifficultySetting( "minFireTime", 1.5 * self BotGetDifficultySetting( "minFireTime" ) );
	self BotSetDifficultySetting( "maxFireTime", 1.25 * self BotGetDifficultySetting( "maxFireTime" ) );
}


//===========================================
// 			sendAgentWeaponNotify
//===========================================
sendAgentWeaponNotify( weaponName )
{
	self  endon( "death" );
	self  endon( "disconnect" );
	level endon( "game_ended" );
	
	self waittill( "giveLoadout" );
	
	if( !IsDefined(weaponName) )
		weaponName = "iw6_riotshield_mp";
	
	self notify( "weapon_change", weaponName );
}


//=======================================================
//				squadmate_agent_think
//=======================================================
squadmate_agent_think()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "owner_disconnect" );
	
	level endon( "game_ended" );
		
	while(1)
	{	
		// Squad mate agent prefers to have shield out when not in combat and guarding player
		self BotSetFlag( "prefer_shield_out", true );

		handled_by_gametype = self [[ self agentFunc("gametype_update") ]]();
		if ( !handled_by_gametype )
		{
			if ( !self bot_is_guarding_player( self.owner ) )
				self bot_guard_player( self.owner, 350 );
		}
		
		wait(0.05);
	}
}


//=======================================================
//				on_agent_squadmate_killed
//=======================================================
on_agent_squadmate_killed(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration)
{
	self maps\mp\agents\_agents::on_humanoid_agent_killed_common(eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration, false);
		
	// award XP for killing agents
	if( IsPlayer( eAttacker ) && IsDefined(self.owner) && eAttacker != self.owner )
	{
		self.owner leaderDialogOnPlayer( "squad_killed" );
		self maps\mp\gametypes\_damage::onKillstreakKilled( eAttacker, sWeapon, sMeansOfDeath, iDamage, "destroyed_squad_mate" );
	}

	self maps\mp\agents\_agent_utility::deactivateAgent();
}
