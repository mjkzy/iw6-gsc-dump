#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\agents\_agent_utility;
#include maps\mp\gametypes\_damage;

//===========================================
// 				constants
//===========================================
CONST_MAX_ACTIVE_KILLSTREAK_DOGS_PER_GAME		= 5;
CONST_MAX_ACTIVE_KILLSTREAK_DOGS_PER_PLAYER 	= 1;
CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER 	= 2;

//===========================================
// 					init
//===========================================
init()
{
	level.killStreakFuncs["guard_dog"] = ::tryUseDog;
	
/#
	SetDevDvarIfUninitialized( "scr_devWolf", 0 );		// 0 == dog, 1 == wolf
	SetDevDvarIfUninitialized( "scr_devWolfType", 0 );	// 0 == wolfA, 1 == wolfB
#/
}


//===========================================
// 				setup_callbacks
//===========================================
setup_callbacks()
{
	level.agent_funcs["dog"] = level.agent_funcs["player"];
	
	level.agent_funcs["dog"]["spawn"]				= ::spawn_dog;
	level.agent_funcs["dog"]["on_killed"]			= ::on_agent_dog_killed;
	level.agent_funcs["dog"]["on_damaged"]			= maps\mp\agents\_agents::on_agent_generic_damaged;
	level.agent_funcs["dog"]["on_damaged_finished"] = ::on_damaged_finished;
	level.agent_funcs["dog"]["think"] 				= maps\mp\agents\dog\_dog_think::main;
	
}


//===========================================
// 				tryUseDog
//===========================================
tryUseDog( lifeId, streakName )
{
	return useDog();
}


//===========================================
// 				useDog
//===========================================
useDog()
{
	// limit the number of active "dog" agents allowed per player
	if( isDefined(self.hasDog) && self.hasDog )
	{
		dog_type = self GetCommonPlayerDataReservedInt( "mp_dog_type" );
		if( dog_type == 1 )
			self iPrintLnBold( &"KILLSTREAKS_ALREADY_HAVE_WOLF" );
		else
			self iPrintLnBold( &"KILLSTREAKS_ALREADY_HAVE_DOG" );
		return false;
	}
	
	// limit the number of active "dog" agents allowed per game
	if( getNumActiveAgents( "dog" ) >= CONST_MAX_ACTIVE_KILLSTREAK_DOGS_PER_GAME )
	{
		self iPrintLnBold( &"KILLSTREAKS_TOO_MANY_DOGS" );
		return false;
	}
	// limit the number of active agents allowed per player
	if( getNumOwnedActiveAgents( self ) >= CONST_MAX_ACTIVE_KILLSTREAK_AGENTS_PER_PLAYER )
	{
		self iPrintLnBold( &"KILLSTREAKS_AGENT_MAX" );
		return false;
	}
	
	// TODO: we should probably do a queue system for these, so the player can call it but it'll go into a queue for when an agent dies to open up a spot
	// limit the number of active agents allowed per player
	maxagents = GetMaxAgents();
	if( getNumActiveAgents() >= maxagents )
	{
		self iPrintLnBold( &"KILLSTREAKS_UNAVAILABLE" );
		return false;
	}
		
	// make sure the player is still alive before the agent trys to spawn on the player
	if( !isReallyAlive( self ) )
	{
		return false;
	}
	
	// try to spawn the agent on a path node near the player
	nearestPathNode = self getValidSpawnPathNodeNearPlayer( true );
	if( !IsDefined(nearestPathNode) )
	{
		return false;
	}

	// find an available agent
	agent = maps\mp\agents\_agent_common::connectNewAgent( "dog" , self.team );
	if( !IsDefined( agent ) )
	{
		return false;
	}
	
	self.hasDog = true;
	
	// set the agent to the player's team
	agent set_agent_team( self.team, self );
	
	spawnOrigin = nearestPathNode.origin;
	spawnAngles = VectorToAngles( self.origin - nearestPathNode.origin );

	agent thread [[ agent agentFunc("spawn") ]]( spawnOrigin, spawnAngles, self );
	
	agent _setNameplateMaterial( "player_name_bg_green_dog", "player_name_bg_red_dog" );
	
	if ( IsDefined( self.ballDrone ) && self.ballDrone.ballDroneType == "ball_drone_backup" )
	{
		self maps\mp\gametypes\_missions::processChallenge( "ch_twiceasdeadly" );
	}
	
	self maps\mp\_matchdata::logKillstreakEvent( "guard_dog", self.origin );
	
	return true;
}


//=======================================================
//				on_agent_dog_killed
//=======================================================
on_agent_dog_killed( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	self.isActive 	= false;
	self.hasDied 	= false;
	
	//agent dogs in safeguard do not have an owner.
	if( IsDefined( self.owner ) )
		self.owner.hasDog = false;

	eAttacker.lastKillDogTime = GetTime();
	
	if ( IsDefined( self.animCBs.OnExit[ self.aiState ] ) )
		self [[ self.animCBs.OnExit[ self.aiState ] ]] ();
	
	// award XP for killing agents
	if( isPlayer( eAttacker ) && IsDefined(self.owner) && (eAttacker != self.owner) )
	{
		self.owner leaderDialogOnPlayer( "dog_killed" );
		self maps\mp\gametypes\_damage::onKillstreakKilled( eAttacker, sWeapon, sMeansOfDeath, iDamage, "destroyed_guard_dog" );
		
		if ( IsPlayer( eAttacker ) )
		{
			eAttacker maps\mp\gametypes\_missions::processChallenge( "ch_notsobestfriend" );
			
			// assume jumping?
			if ( !self IsOnGround() )
			{
				eAttacker maps\mp\gametypes\_missions::processChallenge( "ch_hoopla" );
			}
		}
	}

	self SetAnimState( "death" );
	animEntry = self GetAnimEntry();
	animLength = GetAnimLength( animEntry );
	
	deathAnimDuration = int( animLength * 1000 ); // duration in milliseconds
	
	self.body = self CloneAgent( deathAnimDuration );

	self PlaySound( ter_op( self.bIsWolf, "anml_wolf_shot_death", "anml_dog_shot_death" ) );

	self maps\mp\agents\_agent_utility::deactivateAgent();

	self notify( "killanimscript" );
}


on_damaged_finished( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if( !IsDefined( self.playing_pain_sound ) )
		self thread play_pain_sound( 2.5 );

	// damage needs to be modified depending on the weapon and hit location because the head is really easy to hit when the dog is running at you
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
		self maps\mp\agents\dog\_dog_think::OnDamage( eInflictor, eAttacker, damageModified, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
	}
	
	// attack the player that has damaged them
	if( IsPlayer( eAttacker ) )
	{
		// is the dog already attacking?
		if ( IsDefined( self.attackState ) && self.attackState != "attacking" )
		{
			// is the attacker within the dog damaged range?
			if( DistanceSquared( self.origin, eAttacker.origin ) <= self.dogDamagedRadiusSq )
			{
				self.favoriteEnemy = eAttacker;
				self.forceAttack = true;
				self thread maps\mp\agents\dog\_dog_think::watchFavoriteEnemyDeath();
			}
		}
	}

	maps\mp\agents\_agents::agent_damage_finished( eInflictor, eAttacker, damageModified, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
}

play_pain_sound( delay ) // self == dog
{
	self endon( "death" );
	
	self PlaySound( ter_op( self.bIsWolf, "anml_wolf_shot_pain", "anml_dog_shot_pain" ) );
	self.playing_pain_sound = true;
	wait( delay );
	self.playing_pain_sound = undefined;
}

spawn_dog( optional_spawnOrigin, optional_spawnAngles, optional_owner ) // self == agent
{
	dog_type = 0;	// 0 == dog, 1 == wolf
	wolf_type = 0;	// 0 == wolfB, 1 == wolfC
	if( IsDefined( optional_owner ) )
	{
		if( IsDefined( optional_owner.squad_bot_dog_type ) )
		{
			dog_type = optional_owner.squad_bot_dog_type;
		}
		else
		{
			dog_type = optional_owner GetCommonPlayerDataReservedInt( "mp_dog_type" );
		}
	}

/#
	if( GetDvarInt( "scr_devWolf" ) != 0 )
	{
		dog_type = GetDvarInt( "scr_devWolf" );	
		wolf_type = GetDvarInt( "scr_devWolfType" );
	}
#/
	dog_model = "mp_fullbody_dog_a";
	if( dog_type == 1 )
	{
		if ( wolf_type == 0 )
			dog_model = "mp_fullbody_wolf_b";
		else
			dog_model = "mp_fullbody_wolf_c";
	}

	if( IsHairRunning() )
		dog_model = dog_model + "_fur";
		
	self SetModel( dog_model );

	self.species = "dog";

	self.OnEnterAnimState = maps\mp\agents\dog\_dog_think::OnEnterAnimState;

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

	self.bIsWolf = (dog_type == 1);
	
	self maps\mp\agents\dog\_dog_think::init();

	if ( dog_type == 1 )
		animclass = "wolf_animclass";
	else
		animclass = "dog_animclass";

	// called from code when an agent is done initializing after AddAgent is called
	// this should set up any state specific to this agent and game
	self SpawnAgent( spawnOrigin, spawnAngles, animclass, 15, 40, optional_owner );
	level notify( "spawned_agent", self );
	
	self maps\mp\agents\_agent_common::set_agent_health( 250 );
	
	// must set the team after SpawnAgent to fix a bug with weapon crosshairs and nametags
	if( IsDefined(optional_owner) )
	{
		self set_agent_team( optional_owner.team, optional_owner );
	}
	
	self SetThreatBiasGroup( "Dogs" );

	self TakeAllWeapons();

	// hide the dog, let the whistle happen, then show the dog
	if( IsDefined(self.owner) )
	{
		self Hide();
		wait( 1.0 ); // not sure what to endon for this
		
		// The dog could have died during the 1 second wait (for example if he spawned in a kill trigger), so if that happened,
		//  don't start thinking since it will cause SREs due to him missing a self.agent_type
		if ( !IsAlive(self) )
			return;
		
		self Show();
	}
	
	self thread [[ self agentFunc("think") ]]();

	wait( 0.1 );

	if ( IsHairRunning() )
	{
		if ( dog_type == 1 )
			furFX = level.wolfFurFX[ wolf_type ];
		else
			furFX = level.furFX;

		assert( IsDefined( furFX ) );
		PlayFXOnTag( furFX, self, "tag_origin" );
	}
}
