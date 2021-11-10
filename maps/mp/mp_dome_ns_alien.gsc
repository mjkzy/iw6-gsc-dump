#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\agents\_agent_utility;
#include maps\mp\gametypes\_damage;

//===========================================
// 				constants
//===========================================
CONST_MAX_ACTIVE_KILLSTREAK_ALIENS_PER_GAME		= 3;
CONST_MAX_ACTIVE_KILLSTREAK_ALIENS_PER_PLAYER 	= 3;
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER 	= 2;
CONST_ALIEN_HEALTH 	= 350;

//===========================================
// 				setup_callbacks
//===========================================
setup_callbacks()
{
	// level.agent_funcs["alien"] = level.agent_funcs["player"];
	
	level.agent_funcs["alien"]["spawn"]			= ::spawn_alien;
	level.agent_funcs["alien"]["on_killed"]			= ::on_agent_alien_killed;
	level.agent_funcs["alien"]["on_damaged"]			= maps\mp\agents\_agents::on_agent_generic_damaged;
	level.agent_funcs["alien"]["on_damaged_finished"] = ::on_damaged_finished;
	level.agent_funcs["alien"]["think"] 				= maps\mp\mp_dome_ns_alien_think::main;
	
}

//===========================================
// 				useAlienMinion
//===========================================

useAlien( spawn_point, number_of_aliens )
{
	self endon ( "disconnect");
	self endon ( "joined_team");
	self endon ( "joined_spectators" );
	// self endon ( "death");
	
	setup_callbacks();
	
	// try to spawn the agent on a path node near the player
	nearestPathNode = self getValidSpawnPathNodeNearPlayer( true );
	if( !IsDefined(nearestPathNode) )
	{
		return false;
	}
	
	thread sfx_seeker_quake(spawn_point);
	
	for( i = 0; i < number_of_aliens; i++ )
	{
		// find an available agent
		agent = maps\mp\agents\_agent_common::connectNewAgent( "alien" , self.team );
		if( !IsDefined( agent ) )
		{
			return false;
		}
		
		// set the agent to the player's team
		agent set_agent_team( self.team, self );
		
		if ( i == 0 )
			PathNodeArray = getstructarray ( "seeker_path_01", "script_noteworthy" );
		else if( i == 1 )
			PathNodeArray = getstructarray ( "seeker_path_02", "script_noteworthy" );
		else 
			PathNodeArray = getstructarray ( "seeker_path_03", "script_noteworthy" );
		
		agent thread spawn_alien ( spawn_point.origin, spawn_point.angles, self, PathNodeArray );
		
		// debug aliens do not time out
		if ( getdvarint( "scr_alienDebugMode" ) != 1 )
		{
			agent thread alien_timeout ( 60 );	
		}
		
		wait .5;
	}
	
	return true;
}

alien_timeout( duration )
{
	self endon ( "death" );
	wait duration;
	self maps\mp\mp_dome_ns_alien_think::mp_dome_ns_alien_explode( );
}


//=======================================================
//				on_agent_alien_killed
//=======================================================
on_agent_alien_killed( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	self.isActive 	= false;
	self.hasDied 	= false;
	
	if ( IsDefined( self.animCBs.OnExit[ self.aiState ] ) )
		self [[ self.animCBs.OnExit[ self.aiState ] ]] ();
	
	// award XP for killing agents
	if( isPlayer( eAttacker ) && IsDefined(self.owner) && (eAttacker != self.owner) )
	{
		// create an animated corpse for the seeker
		self SetAnimState( "explode", 0, 1 );
		self.body = self CloneAgent( deathAnimDuration );
		
		// If the alien was killed by a player, it should explode. Wrap the check in here to prevent it from exploding twice (killed by its own explosion)
		self maps\mp\mp_dome_ns_alien_think::mp_dome_ns_alien_explode( undefined, 150, 128, eAttacker );
		
		// self.owner leaderDialogOnPlayer( "dog_killed" );
		self maps\mp\gametypes\_damage::onKillstreakKilled( eAttacker, sWeapon, sMeansOfDeath, iDamage );
		
		// clean up the corpse
		wait deathAnimDuration;
		body = self GetCorpseEntity();
		body delete();
	}
	
	self maps\mp\agents\_agent_utility::deactivateAgent();
	

}


on_damaged_finished( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if( !IsDefined( self.playing_pain_sound ) )
		self thread play_pain_sound( 2.5 );

	// damage needs to be modified depending on the weapon and hit location because the head is really easy to hit when the alien is running at you
	//	assuming 1.4 modifier for head shots
	damageModified = iDamage;
	if( IsDefined( sHitLoc ) && sHitLoc == "head" && level.gametype != "horde" )
	{
		damageModified = int( damageModified * 0.6 );
		if ( iDamage > 0 && damageModified <= 0 )
			damageModified = 1;
	}
	
	if ( self.health - damageModified > 0 )
	{
		self maps\mp\mp_dome_ns_alien_think::OnDamage( eInflictor, eAttacker, damageModified, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
	}
	
	// attack the player that has damaged them
	if( IsPlayer( eAttacker ) )
	{
		// is the alien already attacking?
		if ( IsDefined( self.attackState ) && self.attackState != "attacking" )
		{
			// is the attacker within the alien damaged range?
			if( DistanceSquared( self.origin, eAttacker.origin ) <= self.dogDamagedRadiusSq )
			{
				self.favoriteEnemy = eAttacker;
				self.forceAttack = true;
				self thread maps\mp\mp_dome_ns_alien_think::watchFavoriteEnemyDeath();
			}
		}
	}

	maps\mp\agents\_agents::agent_damage_finished( eInflictor, eAttacker, damageModified, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
}

play_pain_sound( delay ) // self == alien
{
	self endon( "death" );
	
	//self PlaySound( "anml_dog_shot_pain" );
	self.playing_pain_sound = true;
	wait( delay );
	self.playing_pain_sound = undefined;
}

spawn_alien( optional_spawnOrigin, optional_spawnAngles, optional_owner, PathNodeArray ) // self == agent
{
	self SetModel( "alien_minion" );

	// creating VFX that 'follow' the alien
	self thread mp_dome_ns_alien_glow();
	self thread mp_dome_ns_alien_vfx();
	self.species = "alien";

	self.OnEnterAnimState = maps\mp\mp_dome_ns_alien_think::OnEnterAnimState;

	spawnOrigin = optional_spawnOrigin;
	spawnAngles = optional_spawnAngles;
	// allow killstreaks to pass in specific spawn locations
	if( IsDefined(optional_spawnOrigin) && IsDefined(optional_spawnAngles) )
	{
		spawnOrigin = optional_spawnOrigin;
		spawnAngles = optional_spawnAngles;
	}
	else
	{
		spawnPoint 	= self [[level.getSpawnPoint]]();
		spawnOrigin = spawnpoint.origin;
		spawnAngles = spawnpoint.angles;
	}
	self activateAgent();
	self.spawnTime 	= GetTime();
	self.lastSpawnTime = GetTime();

	self maps\mp\mp_dome_ns_alien_think::init();

	// called from code when an agent is done initializing after AddAgent is called
	// this should set up any state specific to this agent and game

	self SpawnAgent( spawnOrigin, spawnAngles, "mp_dome_ns_alien_animclass", 15, 40, optional_owner );
	level notify( "spawned_agent", self );
	
	self maps\mp\agents\_agent_common::set_agent_health( CONST_ALIEN_HEALTH );
	
	// must set the team after SpawnAgent to fix a bug with weapon crosshairs and nametags
	if( IsDefined(optional_owner) )
	{
		self set_agent_team( optional_owner.team, optional_owner );
	}
	
	self SetThreatBiasGroup( "Dogs" );
	self TakeAllWeapons();
	
	self playsound( "alien_seeker_spawn" );
	playfx (level._effect[ "vfx_alien_minion_spawn_dome" ], self.origin  );
	
	self.PathNodeArray = PathNodeArray;
	
	self thread maps\mp\mp_dome_ns_alien_think::main();
}

mp_dome_ns_alien_glow()
{
	wait 2.0;
	// make aliens glow
	self EmissiveBlend( 0.5, 1.0 );
}

mp_dome_alien_light(vfx_offset)
{
	self endon( "death" );
	level endon( "game_ended" );

	// we loop this separately because the light lasts for 1 second,
	// and we were spawning too many of them and they were stacking 4-5 light at a time... booo.

	while (1)
	{
		playfx (level._effect[ "vfx_alien_minion_preexplosion" ], self.origin + vfx_offset);
		wait 1.0;
	}
}

mp_dome_ns_alien_vfx()
{
	self endon( "death" );
	level endon( "game_ended" );

	vfx_offset = (0,0,16);

	self thread mp_dome_alien_light(vfx_offset);
	
	//while (IsAlive (self))
	while (1)
	{
		// this is the particle effect, not the light.
		playfx (level._effect[ "vfx_alien_minion_glow_trail_noloop" ], self.origin + vfx_offset);
		wait RandomFloatRange(0.05,0.2);
	}
}

sfx_seeker_quake(spawn_point)
{
	if (!IsDefined( level.rumble_sfx ))
	{
		level.rumble_sfx = Spawn( "script_origin", spawn_point.origin );
		level.rumble_sfx PlaySound("alien_seeker_quake");
		wait 6.5;
		level.rumble_sfx delete();
	}
}
