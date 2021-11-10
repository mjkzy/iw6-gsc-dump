#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\alien\_utility;

//=======================================================
//				onPlayerKilled
//=======================================================
onPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, killId)
{	
	if ( level.gameEnded == true ) 
		return;

	if ( kill_trigger_event_was_processed() )
		return;
	
	set_kill_trigger_event_processed( self, true );
	
	maps\mp\alien\_laststand::Callback_PlayerLastStandAlien( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration, getKillTriggerSpawnLoc() );
}

kill_trigger_event_was_processed() { return is_true( self.kill_trigger_event_processed ); }
set_kill_trigger_event_processed( player, value ) { self.kill_trigger_event_processed = value; }

//=======================================================
//				onNormalDeath
//=======================================================
onNormalDeath( victim, attacker, lifeId )
{
	if ( game["state"] == "postgame" && game["teamScores"][attacker.team] > game["teamScores"][level.otherTeam[attacker.team]] )
		attacker.finalKill = true;
}


CONST_DANGEROUS_RADIUS = 256;
CONST_DANGEROUS_DURATION = 10;
CONST_DANGEROUS_DURATION_TRAP = 3;
CONST_KILLS_PER_TOKEN_AWARD = 300;

//=======================================================
//				onAlienAgentKilled
//=======================================================
onAlienAgentKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	// scene aliens suicide skips all regular alien dying logic
	if ( isdefined( sMeansOfDeath ) && sMeansOfDeath == "MOD_SUICIDE" && isdefined( self.scene ) && self.scene )
		return;
	
	self.isActive 	= false;
	self.hasDied 	= false;
	self.owner		= undefined;
	type 			= self.alien_type;
	pet_spawned 	= false;
	
	if ( !isDefined ( vDir ) )
		vDir = anglesToForward( self.angles );
	
	self maps\mp\alien\_alien_fx::disable_fx_on_death();
	
	if ( sMeansOfDeath == "MOD_TRIGGER_HURT" )
		return; // died by hurt trigger
		
	// Mark nearby nodes as dangerous - less for traps
	dangerous_duration = CONST_DANGEROUS_DURATION;
	if ( maps\mp\alien\_utility::is_trap( eInflictor ) )
	{
		dangerous_duration = CONST_DANGEROUS_DURATION_TRAP;
	}
	level thread maps\mp\alien\_utility::mark_dangerous_nodes( self.origin, CONST_DANGEROUS_RADIUS, dangerous_duration );
		
	isPetTrapKill = is_pettrap_kill( eInflictor );
	
	//if killed with a special weapon then turn the alien into a pet
	if ( sWeapon == "alienthrowingknife_mp" && sMeansofDeath == "MOD_IMPACT" || isPetTrapKill || is_true( self.hypnoknifed ) )
	{
		if ( self maps\mp\alien\_utility::can_hypno( eAttacker, isPetTrapKill ) )
		{
			thread maps\mp\gametypes\aliens::spawnAllyPet( type, 1, self.origin, eAttacker, self.angles , isPetTrapKill );
			pet_spawned = true;	
			if ( type == "elite" && isPetTrapKill && isDefined( level.update_achievement_hypno_trap_func ) )
				eAttacker [[level.update_achievement_hypno_trap_func]]();
		}
		//don't delete the pet trap!
		if ( !isPetTrapKill )
			eInflictor delete();
	}
	
	should_do_custom_death = false;
	if ( isDefined( level.custom_alien_death_func ) )
		should_do_custom_death = self [[level.custom_alien_death_func]]( eInflictor, eAttacker,iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc );

	if ( should_do_pipebomb_death( sWeapon ) )
	{
		self thread do_pipebomb_death();
	}
	else if ( self should_play_death() && sMeansOfDeath != "MOD_SUICIDE" && !pet_spawned && !should_do_custom_death )
		play_death_anim_and_ragdoll( eInflictor, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc );
		
	self on_alien_type_killed( pet_spawned );
	
	self maps\mp\agents\alien\_alien_think::OnEnterAnimState( self.currentAnimState, "death" );	// we don't need to enter death so much as exit currentAnimState.
	
	//notify for dlc vo
	eAttacker notify("dlc_vo_notify", get_alien_type() + "_killed", eAttacker);
	
	switch ( get_alien_type() )
	{
	case "mammoth":
		self PlaySoundOnMovingEnt( "queen_death" );
		break;		
	case "elite":
		self PlaySoundOnMovingEnt( "queen_death" );
		break;
	case "minion":
		self PlaySoundOnMovingEnt( "alien_minion_explode" );
		break;
	case "spitter":
		self PlaySoundOnMovingEnt( "spitter_death" );
		break;
	default:
		self PlaySoundOnMovingEnt( "alien_death" );
		break;	
	}
	
	// chopper reward
	if ( isdefined( level.attack_heli ) && eAttacker == level.attack_heli )
	{
		reward_point = self maps\mp\alien\_gamescore::get_reward_point_for_kill();
		
		assertex( isdefined( eAttacker.reward_pool ) );
		reward_unit = reward_point / eAttacker.reward_pool.size;
		
		// reset
		foreach ( player in eAttacker.reward_pool )
		{
			if ( isdefined( player ) )
				player.chopper_reward = 0;
		}
		
		// add
		foreach ( player in eAttacker.reward_pool )
		{
			if ( isdefined( player ) )
				player.chopper_reward += reward_unit;
		}

		// give
		foreach ( player in level.players )
		{
			if ( isdefined( player ) && isdefined( player.chopper_reward ) )
				maps\mp\alien\_gamescore::giveKillReward( player, int( player.chopper_reward ), "large" );
		}
	}
	else
	{
		if ( Isdefined( eAttacker.pet ) && ( eAttacker.pet == 1 ) )
		{
			maps\mp\alien\_gamescore::give_attacker_kill_rewards( eAttacker.owner );
		}
		else
		{
			maps\mp\alien\_gamescore::give_attacker_kill_rewards( eAttacker, sHitLoc );
		}	
		
		// weaponstats tracking: register weapon shot hit
		eAttacker thread maps\mp\alien\_persistence::update_weaponstats_kills( sWeapon, 1 );
	}
	
	//update any challenges related to aliens being killed 
	maps\mp\alien\_challenge_function::update_alien_death_challenges(  eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
	
	//update any achievements related to aliens being killed
	maps\mp\alien\_achievement::update_alien_kill_achievements( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
	
	//update alien session stats related to aliens being killed
	maps\mp\alien\_persistence::update_alien_kill_sessionStats( eInflictor, eAttacker );

	if ( is_chaos_mode() )
		maps\mp\alien\_chaos::update_alien_killed_event( get_alien_type(), self.origin, eAttacker );
	
	blackBox_alienKilled( eAttacker );
	
	attacker_as_player = get_attacker_as_player( eAttacker );
	
	if( IsDefined( attacker_as_player ) )
	{
		record_player_kills( attacker_as_player );
		check_award_token_for_kill( attacker_as_player );
	}
	
	level notify( "alien_killed",self.origin, sMeansOfDeath, eAttacker );
	
}

get_attacker_as_player( eAttacker )
{
	if( IsPlayer( eAttacker ) )
		return eAttacker;
	
	if ( IsDefined( eAttacker.owner ) && IsPlayer( eAttacker.owner ) )
		return eAttacker.owner;
	
	return undefined;
}

record_player_kills( player )
{
	player maps\mp\alien\_persistence::set_player_kills();
	
	player maps\mp\alien\_persistence::eog_player_update_stat( "kills", 1 );
}

check_award_token_for_kill( player )
{
	killCount = player maps\mp\alien\_persistence::get_player_kills();
	if ( killCount % CONST_KILLS_PER_TOKEN_AWARD == 0 )
	{
		player maps\mp\alien\_persistence::give_player_tokens( 1, true );
	}
}

on_alien_type_killed( pet_spawned )
{
	switch ( self get_alien_type() )
	{
		case "minion":
			level thread maps\mp\agents\alien\_alien_minion::minion_explode_on_death( self.origin );
			break;
			
		case "spitter":
			maps\mp\agents\alien\_alien_spitter::spitter_death();
			break;
	
		default:
		// Check for level specific overrides
		if( isDefined( level.dlc_alien_death_override_func ))
			self [[level.dlc_alien_death_override_func]]( pet_spawned );
		break;
	}
}

should_play_death()
{
	switch( get_alien_type() )
	{
		case "minion":
		case "seeder":
		case "bomber":
			return false;
		default:
			return true;
	}
}

play_death_anim_and_ragdoll( eInflictor, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc )
{
	ORIENTED_DEATH_OFFSET = 24;
	APEX_TRAVERSAL_DEATH_OFFSET = 30;
	
	if ( GetDvarInt( "alien_easter_egg" ) > 0 || ( isdefined( level.easter_egg_lodge_sign_active ) && level.easter_egg_lodge_sign_active ) )
	{
		PlayFX( level._effect[ "arcade_death" ], self.origin );
		//self thread alien_toy_death();
	}
	else
	{
		primary_animState = get_primary_death_anim_state();
		
		if ( !is_normal_upright( AnglesToUp( self.angles ) ) )
			move_away_from_surface( AnglesToUp( self.angles ), ORIENTED_DEATH_OFFSET );
		
		if ( isDefined( self.apexTraversalDeathVector ) )
			move_away_from_surface( self.apexTraversalDeathVector, APEX_TRAVERSAL_DEATH_OFFSET );
				
		play_death_anim_and_ragdoll_internal( primary_animState, eInflictor, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc );
	}
}

should_do_immediate_ragdoll( deathAnimState )
{
	if ( IsDefined( level.dlc_alien_should_immediate_ragdoll_on_death_override_func ) )
	{
		should_immediate_ragdoll = [[level.dlc_alien_should_immediate_ragdoll_on_death_override_func]]( deathAnimState );
		if ( IsDefined( should_immediate_ragdoll ) )
			return should_immediate_ragdoll;
	}
	
	switch ( deathAnimState )
	{
	case "jump":
	case "traverse":
		return true;
	default:
		return false;
	}
}

play_death_anim_and_ragdoll_internal( primary_animState, eInflictor, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc )
{	
	if ( is_special_death( primary_animState ) )
	{
		animState = "special_death";
		animIndex = self maps\mp\agents\alien\_alien_anim_utils::getSpecialDeathAnimIndex( primary_animState );
	}
	else
	{
		animState = self maps\mp\agents\alien\_alien_anim_utils::getDeathAnimState( ( primary_animState + "_death" ), iDamage );
		animIndex = self maps\mp\agents\alien\_alien_anim_utils::getDeathAnimIndex( primary_animState , vDir, sHitLoc );
	}
	
	do_immediate_ragdoll = should_do_immediate_ragdoll( primary_animState );
		
	self ScrAgentSetPhysicsMode( get_death_anim_physics_mode( animState ) ); 
	self SetAnimState( animState, animIndex );
	
	self.body = get_clone_agent( animState, animIndex );
	
	self thread handle_ragdoll( self.body, animState, do_immediate_ragdoll );
}

move_away_from_surface( direction, offset_length )
{	
	offsetLocation = self.origin + direction * offset_length;
	self SetOrigin( offsetLocation );
}

get_primary_death_anim_state()
{
	// special death case 
	if ( isdefined( self.shocked ) && self.shocked )   //for electric fence, shock backwards anim
		return "electric_shock_death";   
	
	switch ( self.currentAnimState )
	{
	case "scripted":
		{
			return "idle";
		}		
	case "move":
		{
			if ( self.trajectoryActive )
				return "jump";
			else
				return "run";
		}
	case "idle":
		{
			return "idle";
		}
	case "melee":
		{
			if ( self.trajectoryActive )
				return "jump";
			if ( self.melee_in_move_back || self.melee_in_posture )
				return "idle";
			else
				return "run";
		}
	case "traverse":
		{
			if ( self.trajectoryActive )
				return "jump";
			else
				return "traverse";
		}
	default:
		{
			AssertMsg( "currentAnimState: " + self.currentAnimState + " does not have a death anim mapping." );
		}
	}
}

is_special_death( primary_animState )
{
	switch ( primary_animState )
	{
	case "traverse":
	case "electric_shock_death":  
		return true;
	default:
		return false;
	}
}

get_death_anim_physics_mode( anim_state )
{
	switch ( anim_state )
	{
	case "electric_shock":   // so alien doesn't get stuck on electric fence geo
		return "noclip";  
	default:
		return "gravity";
	}
}

get_clone_agent( animState, animIndex )
{
	animEntry = self GetAnimEntry( animState, animIndex );
	animLength = GetAnimLength( animEntry );
	if ( AnimHasNotetrack( animEntry, "start_ragdoll" ) )
	{
		notetracks = GetNotetrackTimes( animEntry, "start_ragdoll" );
		assert( notetracks.size > 0 );
		animLength *= notetracks[0];
	}
	    		
	deathAnimDuration = int( animLength * 1000 ); // duration in milliseconds
	
	return ( self CloneAgent( deathAnimDuration ) );
}

handle_ragdoll( corpse, animState, do_immediate_ragdoll )
{
	deathAnim = corpse getcorpseanim();
	
	if ( !should_do_ragdoll( corpse, deathAnim ) )
		return;
	
	if ( do_immediate_ragdoll )
	{
		corpse startragdoll();
		
		if ( corpse isRagdoll() ) //Immediate ragdoll succeed
			return;
		
/#
		println( "Corpse failed immediate ragdoll at " + corpse.origin );
#/
	}
	
	delayStartRagdoll( corpse, deathAnim );

	if ( !isDefined( corpse ) )
		return;
	
	// electric fence shock does physics to send aliens flying
	// TODO: Remove once death animation for shock_death does this
	if ( animState == "shock_death" )
	{
		self notify( "in_ragdoll", corpse.origin );
	}
}

delayStartRagdoll( corpse, deathAnim )
{	
	totalAnimTime = getanimlength( deathAnim );
	if ( animhasnotetrack( deathAnim, "start_ragdoll" ) )
	{
		times = getnotetracktimes( deathAnim, "start_ragdoll" );
		startFrac = times[ 0 ];
		waitTime = startFrac * totalAnimTime;
	}
	else
	{
		waitTime = 0.2;
	}
	
	wait( waitTime );

	if ( !isDefined( corpse ) )  // Corpse can be deleted during host migration  
	{
		return;
	}
	else 
	{
		corpse startragdoll();
	
		if ( corpse isRagdoll() )
			return;
	}
	
/#
		println( "Corpse failed first ragdoll at " + corpse.origin );
#/
	
	// Ragdoll failed, do a final attempt
	if ( waitTime < totalAnimTime )
	{
		wait ( totalAnimTime - waitTime );
	
		if ( !isDefined( corpse ) )  // Corpse can be deleted during host migration  
		{
			return;
		}
		else 
		{
			corpse startragdoll();
		
			if ( corpse isRagdoll() )
				return;
		}
/#
		println( "Corpse failed second ragdoll at " + corpse.origin );
#/
	}

	// If final attempt failed, delete the corpse
	if ( isDefined( corpse ) )
		corpse delete();
}

should_do_ragdoll( ent, deathAnim )
{
	if ( ent isRagDoll() )
		return false;

	if ( animhasnotetrack( deathAnim, "ignore_ragdoll" ) )
		return false;
	
	if ( IsDefined( level.noRagdollEnts ) && level.noRagdollEnts.size )
	{
		foreach( noRag in level.noRagdollEnts )
		{
			if ( distanceSquared( ent.origin, noRag.origin ) <	65536 ) //256^2
				return false;
		}
	}
	
	return true;
}

blackBox_alienKilled( eAttacker )
{
	// black box data tracking
	if ( isPlayer( eAttacker ) 
	    || ( isDefined( eAttacker.pet ) && ( eAttacker.pet == 1 ) && isPlayer( eAttacker.petowner ) )
	    || ( IsDefined( eAttacker.owner ) && IsPlayer( eAttacker.owner ) ) 
	   )
	{
		level.alienBBData[ "aliens_killed" ]++;
	}
	
	self notify( "alien_killed" );
	
	// black box data tracking
	// =========================== blackbox print [START] ===========================
	// self is agent victim that died
	
	// attacker_is_agent
	attacker_is_agent = IsAgent( eAttacker );
	
	// attacker_alive_time, attacker_agent_type, attacker_name
	if ( attacker_is_agent )
	{
		attacker_alive_time = ( gettime() - eAttacker.birthtime ) / 1000;
		attacker_agent_type = "unknown agent";
		attacker_name 		= "none";
		
		if ( isdefined( eAttacker.agent_type ) )
		{
			attacker_agent_type = eAttacker.agent_type;
			if ( isdefined( eAttacker.alien_type ) )
				attacker_agent_type = eAttacker.alien_type;
		}
	}
	else
	{
		attacker_alive_time = 0;
		attacker_name 		= "none";
		
		if ( isplayer( eAttacker ) )
		{
			attacker_agent_type = "player";
			
			if ( isdefined( eAttacker.name ) )
				attacker_name = eAttacker.name;
		}
		else
		{
			attacker_agent_type = "nonagent";
		}
	}
	
	// attacker origin
	attackerx = 0.0;
	attackery = 0.0;
	attackerz = 0.0;
	if ( isdefined( eAttacker ) && ( IsAgent( eAttacker ) || isPlayer( eAttacker ) ) )
	{
		attackerx = eAttacker.origin[ 0 ];
		attackery = eAttacker.origin[ 1 ];
		attackerz = eAttacker.origin[ 2 ];
	}
	
	victim_alive_time = 0;
	if ( isdefined( self.birthtime ) )
		victim_alive_time = ( gettime() - self.birthtime ) / 1000;
	
	victim_spawn_origin = ( 0, 0, 0 );
	if ( isdefined( self.spawnorigin ) )
		victim_spawn_origin = self.spawnorigin;
	
	victim_dist_from_spawn = 0;
	if ( isdefined( self.spawnorigin ) )
		victim_dist_from_spawn = distance( self.origin, self.spawnorigin );
	
	victim_damage_done = 0;
	if ( isdefined( self.damage_done ) )
		victim_damage_done = self.damage_done;
	
	victim_agent_type = "unknown agent";
	if ( isdefined( self.agent_type ) )
	{
		victim_agent_type = self.agent_type;
		if ( isdefined( self.alien_type ) )
			victim_agent_type = self.alien_type;
	}
	
	current_enemy_population = 0;
	foreach ( agent in level.agentArray )
	{
		if ( !IsDefined( agent.isActive ) || !agent.isActive )
				continue;
		
		if ( isdefined( agent.team ) && agent.team == "axis" )
			current_enemy_population++;
	}
	
	current_player_population = 0;
	if ( isdefined( level.players ) )
		current_player_population = level.players.size;

	/#
	if ( GetDvarInt( "alien_bbprint_debug" ) > 0 )
	{
		IPrintLnBold( "^8bbprint: alienkilled (1/2)\n" +
					 " attackerisagent=" + attacker_is_agent +
					 " attackeralivetime=" + attacker_alive_time +
					 " attackeragenttype=" + attacker_agent_type +
					 " attackername=" + attacker_name +
					 " attackerx=" + eAttacker.origin[ 0 ] +
					 " attackery=" + eAttacker.origin[ 1 ] +
					 " attackerz=" + eAttacker.origin[ 2 ] +
					 " victimalivetime=" + victim_alive_time );
		
		IPrintLnBold( "^8bbprint: alienkilled (2/2)\n" +
					 " victimspawnoriginx=" + victim_spawn_origin[ 0 ] +
					 " victimspawnoriginy=" + victim_spawn_origin[ 1 ] +
					 " victimspawnoriginz=" + victim_spawn_origin[ 2 ] +
					 " victimdistfromspawn=" + victim_dist_from_spawn +
					 " victimdamagedone=" + victim_damage_done +
					 " victimagenttype=" + victim_agent_type +
					 " currentenemypopulation=" + current_enemy_population +
					 " currentplayerpopulation=" + current_player_population );
	}
	#/

	bbprint( "alienkilled",
		    "attackerisagent %i attackeralivetime %f attackeragenttype %s attackername %s attackerx %f attackery %f attackerz %f victimalivetime %f victimspawnoriginx %f victimspawnoriginy %f victimspawnoriginz %f victimdistfromspawn %i victimdamagedone %i victimagenttype %s currentenemypopulation %i currentplayerpopulation %i ", 
		    attacker_is_agent,
			attacker_alive_time,
			attacker_agent_type,
			attacker_name,
			eAttacker.origin[ 0 ],
			eAttacker.origin[ 1 ],
			eAttacker.origin[ 2 ],
			victim_alive_time,
			victim_spawn_origin[ 0 ],
			victim_spawn_origin[ 1 ],
			victim_spawn_origin[ 2 ],
			victim_dist_from_spawn,
			victim_damage_done,
			victim_agent_type,
			current_enemy_population,
			current_player_population );

	// =========================== [END] blackbox print ===========================
}

KILL_TRIGGER_SPAWN_STRUCT_TARGET_NAME = "respawn_edge";
kill_trigger_spawn_init()
{
	level.killTriggerSpawnLocs = getstructArray( KILL_TRIGGER_SPAWN_STRUCT_TARGET_NAME, "targetname" );
}

getKillTriggerSpawnLoc()
{
	AssertEx( level.killTriggerSpawnLocs.size > 0, "Need to put script struct around kill triggers with KVP: 'targetname', '" + KILL_TRIGGER_SPAWN_STRUCT_TARGET_NAME + "'" );
	
	return ( getClosest ( self.origin, level.killTriggerSpawnLocs ) );
}

should_do_pipebomb_death( sWeapon )
{
	alientype = self get_alien_type();
	
	//minions already explode, and the Rhino/Elite aliens shouldn't gib
	if ( alientype == "minion" || alientype == "elite" || alientype == "mammoth" )
		return false;
	
	return ( isDefined( sWeapon ) && sWeapon == "iw6_aliendlc22_mp" ); //pipe bomb
}

do_pipebomb_death()
{
	PlayFx( level._effect[ "alien_gib" ], self.origin + (0,0,32) );
}

is_pettrap_kill( eInflictor )
{
	return ( isDefined( eInflictor ) && isDefined( eInflictor.is_pet_trap ) );
}

general_alien_custom_death( eInflictor, eAttacker,iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc )
{
	is_player = IsDefined( eAttacker ) && isPlayer ( eAttacker );
	
	if ( is_player && isDefined ( sWeapon ) && weapon_has_alien_attachment( sWeapon ) && sMeansOfDeath != "MOD_MELEE"  && !is_true ( level.easter_egg_lodge_sign_active ) )
	{
		PlayFx( level._effect[ "alien_ark_gib" ], self.origin + (0,0,32) );
			
		return true;
	}
	else
		return false;		
}