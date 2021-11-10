#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

CINEMATIC_CAMERA_NUM_ATTACKER_FINAL_KILLCAM = 5;

init()
{
	level.killcam = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "allowkillcam" );
}


setCinematicCameraStyle( cameraStyle, leadingActorId, supportingActorId )
{
	// make sure this "cam_scene_name" has a corresponding file in "game/share/raw/mp/cinematic_camera/*.txt" and is added to common_mp.csv & ncsLuiStrings.txt
	self SetClientOmnvar( "cam_scene_name", cameraStyle );
	self SetClientOmnvar( "cam_scene_lead", leadingActorId );
	self SetClientOmnvar( "cam_scene_support", supportingActorId );
}


// self == client to show killcam
// in normal killcam, this is the eVictim
// in final killcam, this is your player and not necessarily the eVictim
setKillCameraStyle( eInflictor, inflictorAgentInfo, attackerNum, eVictim, killcamentityindex, killcamInfo )
{
	killcamInfo.cameraStyle = "unknown";
	
	if ( IsDefined( inflictorAgentInfo ) && IsDefined( inflictorAgentInfo.agent_type ) )
	{
		if ( inflictorAgentInfo.agent_type == "dog" || inflictorAgentInfo.agent_type == "wolf" )
		{
			self setCinematicCameraStyle( "killcam_dog", eInflictor GetEntityNumber(), eVictim GetEntityNumber() );
			killcamInfo.cameraStyle = "killcam_dog";
		}
		else if ( inflictorAgentInfo.agent_type == "beastmen" )
		{
			self setCinematicCameraStyle( "killcam_agent_firstperson", eInflictor GetEntityNumber(), eVictim GetEntityNumber() );
			killcamInfo.cameraStyle = "killcam_agent_firstperson";		
		}
		else
		{
			self setCinematicCameraStyle( "killcam_agent", eInflictor GetEntityNumber(), eVictim GetEntityNumber() );
			killcamInfo.cameraStyle = "killcam_agent";
		}
		return true;
	}
	else if ( killcamentityindex > 0 )
	{
		// use killcam entity camera rather than a "cinematic camera"
		self setCinematicCameraStyle( "unknown", -1, -1 );
		return false;
	}		
	else
	{
		// we decided to not do the cinematic killcam on the normal in-match killcam
		self setCinematicCameraStyle( "unknown", -1, -1 );
		return false;
	}

	return false;
}


trimKillCamTime( eInflictor, inflictorAgentInfo, attacker, victim, killcamentityindex, camtime, postdelay, predelay, maxtime )
{
	killcamlength = camtime + postdelay;
	
	//
	// don't let the killcam last past the end of the round.
	//
	if ( isdefined(maxtime) && killcamlength > maxtime )
	{
		// first trim postdelay down to a minimum of 1 second.
		// if that doesn't make it short enough, trim camtime down to a minimum of 1 second.
		// if that's still not short enough, cancel the killcam.
		if ( maxtime < 2 )
			return;

		if (maxtime - camtime >= 1) {
			// reduce postdelay so killcam ends at end of match
			postdelay = maxtime - camtime;
		}
		else {
			// distribute remaining time over postdelay and camtime
			postdelay = 1;
			camtime = maxtime - 1;
		}
		
		// recalc killcamlength
		killcamlength = camtime + postdelay;
	}
	
	killcamoffset = camtime + predelay;
	
	//
	// don't show killcam before attacker/inflictor spawns
	//
	if ( IsDefined( inflictorAgentInfo ) && IsDefined( inflictorAgentInfo.lastSpawnTime ) )
	{
		lastAttackerSpawnTime = inflictorAgentInfo.lastSpawnTime;
	}
	else
	{
		lastAttackerSpawnTime = attacker.lastSpawnTime;
		
		if ( IsDefined( attacker.deathTime ) )
		{
			// don't let the killcam last past the attacker death so that victim can see where attacker respawns in killcam
			if ( gettime() - attacker.deathTime < (postdelay * 1000.0) )
			{
				postdelay = 1.0; 	// time from death until respawn (or killcam)
				postdelay -= 0.05;	// shorten by 1 server frame so that you don't see attacker spawn for 1 frame
				
				// recalc killcamlength
				killcamlength = camtime + postdelay;
			}
		}
	}
	
	aliveTime = ( getTime() - lastAttackerSpawnTime ) / 1000.0;
	
	if ( (killcamoffset > aliveTime) && (aliveTime > predelay) )
	{
		trimmedCamtime = aliveTime - predelay;
		
		if ( camtime > trimmedCamtime )
		{
			camtime = trimmedCamtime;
			// recalc killcamlength & killcamoffset
			killcamlength = camtime + postdelay;
			killcamoffset = camtime + predelay;
		}
	}
	
	result = spawnStruct();
	result.camtime = camtime;
	result.postdelay = postdelay;
	result.killcamlength = killcamlength;
	result.killcamoffset = killcamoffset;

	return result;
}


preKillcamNotify( eInflictor, attacker )
{
	if( IsDefined(attacker) && !IsAgent(attacker) )
	{		
		self LoadCustomizationPlayerView( attacker );
	}

	// TODO: Could store the attacker spawn time here, before too much time passes?
}


killcam(
	eInflictor, // entity of the inflictor, can be the attacker
	inflictorAgentInfo, // if inflictor is agent, contains struct with cached agent_type, lastSpawnTime. undefined if not agent. needed because if agent inflictor dies before victim's killcam starts, eInflictor's script variables were cleared.
	attackerNum, // entity number of the attacker
	killcamentityindex, // entity number of the entity to view (grenade, airstrike, etc)
	killcamentitystarttime, // time at which the killcamentity came into being
	sWeapon, // killing weapon
	predelay, // time between player death and beginning of killcam
	offsetTime, // something to do with how far back in time the killer was seeing the world when he made the kill; latency related, sorta
	timeUntilRespawn, // will the player be allowed to respawn after the killcam?
	maxtime, // time remaining until map ends; the killcam will never last longer than this. undefined = no limit
	attacker, // entity object of attacker
	victim, // entity object of the victim
	sMeansOfDeath // the means of death
)
{
	// monitors killcam and hides HUD elements during killcam session
	//if ( !level.splitscreen )
	//	self thread killcam_HUD_off();
	
	self endon( "disconnect" );
	self endon( "spawned" );
	level endon( "game_ended" );
	
	if ( attackerNum < 0 || !IsDefined( attacker ) )
		return;
	
	//this is to track and amortize number of killcams per frame
	level.numPlayersWaitingToEnterKillcam++;
	if ( level.numPlayersWaitingToEnterKillcam > 1 )
	{
		/#
			println( "more than one client entering killcam this frame: " + level.numPlayersWaitingToEnterKillcam );
		#/
			
		wait 0.05 * ( level.numPlayersWaitingToEnterKillcam - 1 );
	}
	
	wait 0.05;	// Allow all players entering killcam to increment 'level.numPlayersWaitingToEnterKillcam'
	level.numPlayersWaitingToEnterKillcam--;

	// length from killcam start to killcam end
	if (getdvar("scr_killcam_time") == "")
	{
		if ( sWeapon == "artillery_mp" || sWeapon == "stealth_bomb_mp" || sWeapon == "warhawk_mortar_mp" )
			camtime = (gettime() - killcamentitystarttime) / 1000 - predelay - .1;
		else if( sWeapon == "remote_mortar_missile_mp" )
			camtime = 6.5;
		else if ( level.showingFinalKillcam	)
			camtime = 4.0;
		else if ( sWeapon == "apache_minigun_mp" )
			camtime = 3.0;
		else if ( sWeapon == "javelin_mp" )
			camtime = 8;
		else if ( issubstr( sWeapon, "remotemissile_" ) )
			camtime = 5;
		else if ( IsDefined( eInflictor.sentrytype ) && eInflictor.sentrytype == "multiturret" )  // shortening killcam time on mp_shipment mutliturrets.  Gives time for camera to set up
			camtime = 2.0;
		else if ( IsDefined( eInflictor.carestrike ) )
			camtime = 2.0;
		else if ( !timeUntilRespawn || timeUntilRespawn > 5.0 ) // if we're not going to respawn, we can take more time to watch what happened
			camtime = 5.0;
		else if ( sWeapon == "frag_grenade_mp" || sWeapon == "frag_grenade_short_mp" || sWeapon == "semtex_mp" || sWeapon == "semtexproj_mp" || sWeapon == "thermobaric_grenade_mp" || sWeapon == "mortar_shell__mp" )
			camtime = 4.25; // show long enough to see grenade thrown
		else
			camtime = 2.5;
	}
	else
		camtime = getdvarfloat("scr_killcam_time");

	if ( IsDefined( maxtime ) )
	{
		if ( camtime > maxtime )
			camtime = maxtime;
		if ( camtime < 0.05 )
			camtime = 0.05;
	}
	
	// time after player death that killcam continues for
	if (getdvar("scr_killcam_posttime") == "")
		postdelay = 2;
	else {
		postdelay = getdvarfloat("scr_killcam_posttime");
		if (postdelay < 0.05)
			postdelay = 0.05;
	}
	
	/* timeline:
	
	|        camtime       |      postdelay      |
	|                      |   predelay    |
	
	^ killcam start        ^ player death        ^ killcam end
	                                       ^ player starts watching killcam
	
	*/
	
	if ( attackerNum < 0 || !IsDefined( attacker ) )
		return;	// Need to check this again in case the attacker disconnected during the wait
	
	killcamTimes = trimKillCamTime( eInflictor, inflictorAgentInfo, attacker, victim, killcamentityindex, camtime, postdelay, predelay, maxtime );
	
	if ( !IsDefined( killcamTimes ) )
		return;
	
	assert( IsDefined( killcamTimes.camtime ) );
	assert( IsDefined( killcamTimes.postdelay ) );
	assert( IsDefined( killcamTimes.killcamlength ) );
	assert( IsDefined( killcamTimes.killcamoffset ) );

	// LUA: we need to reset this dvar so the killcam will reset if we come in here for the final killcam while you're watching a killcam
	self SetClientOmnvar( "ui_killcam_end_milliseconds", 0 );
	// END LUA

	// LUA: we need to show attacker info in the lua killcam
	assert( IsGameParticipant( attacker ) );
	
	if( IsPlayer( attacker ) )
	{
		self SetClientOmnvar( "ui_killcam_killedby_id", attacker GetEntityNumber() );
		self SetClientOmnvar( "ui_killcam_victim_id", victim GetEntityNumber() );
		self LoadCustomizationPlayerView( attacker );
	}
	
	if ( isKillstreakWeapon( sWeapon ) )
	{
		{
			if ( sMeansOfDeath == "MOD_MELEE" && maps\mp\killstreaks\_killstreaks::isAirdropMarker( sWeapon ) )
			{
			    weaponRowIdx = TableLookupRowNum( "mp/statsTable.csv", 4, "iw6_knifeonly" );
			    self SetClientOmnvar( "ui_killcam_killedby_weapon", weaponRowIdx );
				self SetClientOmnvar( "ui_killcam_killedby_killstreak", -1 );
			}
			else
			{
				killstreakRowIdx = getKillstreakRowNum( level.killstreakWeildWeapons[ sWeapon ] );
				self SetClientOmnvar( "ui_killcam_killedby_killstreak", killstreakRowIdx );
				self SetClientOmnvar( "ui_killcam_killedby_weapon", -1 );
				self SetClientOmnvar( "ui_killcam_killedby_attachment1", -1 );
				self SetClientOmnvar( "ui_killcam_killedby_attachment2", -1 );
				self SetClientOmnvar( "ui_killcam_killedby_attachment3", -1 );
				self SetClientOmnvar( "ui_killcam_killedby_attachment4", -1 );
			}	
		}
	}
	else
	{
		attachments = [];
		weaponName = GetWeaponBaseName( sWeapon );
		if( IsDefined( weaponName ) )
		{
			// set to knife only weapon to get knife image for lua
			if( sMeansOfDeath == "MOD_MELEE" && ( !maps\mp\gametypes\_weapons::isRiotShield( sWeapon ) ) )
			{
				weaponName = "iw6_knifeonly";
			}
			else
			{
				weaponName = weaponMap( weaponName );
				weaponName = strip_suffix( weaponName, "_mp" );
			}
			weaponRowIdx = TableLookupRowNum( "mp/statsTable.csv", 4, weaponName );
			self SetClientOmnvar( "ui_killcam_killedby_weapon", weaponRowIdx );
			self SetClientOmnvar( "ui_killcam_killedby_killstreak", -1 );
			
			if( weaponName != "iw6_knifeonly" )
				attachments = GetWeaponAttachments( sWeapon );
		}
		else
		{
			self SetClientOmnvar( "ui_killcam_killedby_weapon", -1 );
			self SetClientOmnvar( "ui_killcam_killedby_killstreak", -1 );
		}
		
		for( i = 0; i < 4; i++ )
		{
			if( IsDefined( attachments[ i ] ) )
			{
				attachmentRowIdx = TableLookupRowNum( "mp/attachmentTable.csv", 4, attachmentMap_toBase( attachments[ i ] ) );
				self SetClientOmnvar( "ui_killcam_killedby_attachment" + ( i + 1 ), attachmentRowIdx );
			}
			else
			{
				self SetClientOmnvar( "ui_killcam_killedby_attachment" + ( i + 1 ), -1 );
			}
		}
		
		// abilities, bit masking for lua
		bit_mask = [ 0, 0 ];
		pers_loadout_perks = attacker.pers[ "loadoutPerks" ];
		for( i = 0; i < pers_loadout_perks.size; i++ )
		{
			idx = int( TableLookup( "mp/killCamAbilitiesBitMaskTable.csv", 1, pers_loadout_perks[i], 0 ) );
			if( idx == 0 )
				continue;
			bitmaskIdx = int( ( idx - 1 ) / 24 );
			bit = 1 << ( ( idx - 1 ) % 24 );
			bit_mask[bitmaskIdx] |= bit;
		}
		self SetClientOmnvar( "ui_killcam_killedby_abilities1", bit_mask[0] );
		self SetClientOmnvar( "ui_killcam_killedby_abilities2", bit_mask[1] );
	}
	
	forceRespawn = GetDvarInt( "scr_player_forcerespawn" ); 
	if ( timeUntilRespawn && !level.gameEnded || ( isDefined( self ) && isDefined(self.battleBuddy) && !level.gameEnded ) 
	    || forceRespawn == false && !level.gameEnded )
	{
		//setLowerMessage( "kc_info", &"PLATFORM_PRESS_TO_SKIP", undefined, undefined, undefined, undefined, undefined, undefined, true );
		self SetClientOmnvar( "ui_killcam_text", "skip" );
	}
	else if ( !level.gameEnded )
	{
		//setLowerMessage( "kc_info", &"PLATFORM_PRESS_TO_RESPAWN", undefined, undefined, undefined, undefined, undefined, undefined, true );
		self SetClientOmnvar( "ui_killcam_text", "respawn" );	
	}
	else
	{
		self SetClientOmnvar( "ui_killcam_text", "none" );	
	}
	// END LUA
	
	startTime = getTime();
	self notify ( "begin_killcam", startTime );

	if ( !isAgent(attacker) && isDefined( attacker ) ) // attacker may have disconnected
		attacker visionsyncwithplayer( victim );
	
	self updateSessionState( "spectator", "hud_status_dead" );
	self.spectatekillcam = true;
	
	if( IsAgent( attacker ) || IsAgent( eInflictor ) )
	{
		attackerNum =  victim GetEntityNumber();
		// fix issue with victim disappearing for 1 snapshot when killcam is played via victim
		// subtract half a server frame time (50 / 2) that will be added in code when psoffsettime is set
		offsetTime -= 25;
	}

	self.forcespectatorclient = attackerNum;
	self.killcamentity = -1;
	
	usingCinematicKillCam = self setKillCameraStyle( eInflictor, inflictorAgentInfo, attackerNum, victim, killcamentityindex, killcamTimes );
	
	if ( !usingCinematicKillCam )
		self thread setKillCamEntity( killcamentityindex, killcamTimes.killcamoffset, killcamentitystarttime );

	self.archivetime = killcamTimes.killcamoffset;
	self.killcamlength = killcamTimes.killcamlength;
	self.psoffsettime = offsetTime;
	
	// ignore spectate permissions
	self allowSpectateTeam("allies", true);
	self allowSpectateTeam("axis", true);
	self allowSpectateTeam("freelook", true);
	self allowSpectateTeam("none", true);
	if( level.multiTeamBased )
	{
		foreach( teamname in level.teamNameList )
		{
			self allowSpectateTeam( teamname, true );
		}
	}

	self thread endedKillcamCleanup();

	// wait till the next server frame to allow code a chance to update archivetime if it needs trimming
	wait 0.05;	
	
	if( !isDefined( self ) )
		return;
	
	assertex( self.archivetime <= killcamTimes.killcamoffset + 0.0001, "archivetime: " + self.archivetime + ", killcamTimes.killcamoffset: " + killcamTimes.killcamoffset );
	if ( self.archivetime < killcamTimes.killcamoffset )
	{
		truncation_amount = killcamTimes.killcamoffset - self.archivetime;
		if ( game["truncated_killcams"] < 32 )
		{
			println( "Truncated killcam is being recorded. Count = " + game["truncated_killcams"] );
			setMatchData( "killcam", game["truncated_killcams"], truncation_amount );
			game["truncated_killcams"]++;
		}
		println( "WARNING: Code trimmed killcam time by " + truncation_amount + " seconds because it doesn't have enough game time recorded!" );
	}
	
	killcamTimes.camtime = self.archivetime - .05 - predelay;
	killcamTimes.killcamlength = killcamTimes.camtime + killcamTimes.postdelay;
	self.killcamlength = killcamTimes.killcamlength;

	if ( killcamTimes.camtime <= 0 ) // if we're not looking back in time far enough to even see the death, cancel
	{
		println( "Cancelling killcam because we don't even have enough recorded to show the death." );
		
		self updateSessionState( "dead" );
		self ClearKillcamState();
		
		self notify ( "killcam_ended" );
		
		return;
	}
	
	showFinalKillcamFX = level.showingFinalKillcam;

	// LUA: we need to show timer info in the lua killcam, this will tell the killcam to display and eveything else to hide
	self SetClientOmnvar( "ui_killcam_end_milliseconds", int( killcamTimes.killcamlength * 1000 ) + GetTime() );
	if ( showFinalKillcamFX )
		self SetClientOmnvar( "ui_killcam_victim_or_attacker", 1 );
	// END LUA

/#
	if ( getDvarInt( "scr_devfinalkillcam" ) != 0 )
		showFinalKillcamFX = !IsBot( victim ) && !IsAgent( victim );
#/
	if ( showFinalKillcamFX )
		self thread doFinalKillCamFX( killcamTimes, self.killcamentity, attacker, victim, sMeansOfDeath );
	
	self.killcam = true;

	if ( isDefined( self.battleBuddy ) && !level.gameEnded )
	{
		self.battleBuddyRespawnTimeStamp = GetTime();
	}
	
	self thread spawnedKillcamCleanup();
	
	if ( !level.showingFinalKillcam )
		self thread waitSkipKillcamButton( timeUntilRespawn );
	else
		self notify ( "showing_final_killcam" );
	
	self thread endKillcamIfNothingToShow();
	
	self waittillKillcamOver();
	
	if ( level.showingFinalKillcam )
	{
		self thread maps\mp\gametypes\_playerlogic::spawnEndOfGame();
		return;
	}
	
	self thread calculateKillCamTime( startTime );
	
	self thread killcamCleanup( true );
}


doFinalKillCamFX( killcamInfo, killcamentityindex, eAttacker, eVictim, sMeansOfDeath )
{
	self endon("killcam_ended");
	
	if ( isDefined( level.doingFinalKillcamFx ) )
		return;
	
	level.doingFinalKillcamFx = true;
	camTime = killcamInfo.camTime;

	accumTime = 0;

	victimNum = eVictim GetEntityNumber();

	// attacker cam
	//	we do killcamInfo here because it could be a dog or agent
	if( !IsDefined( killcamInfo.attackerNum ) )
		killcamInfo.attackerNum = eAttacker GetEntityNumber();
	
	// this is the final slowmo when the victim dies
	intoSlowMoTime = camTime;
	if ( intoSlowMoTime > 1.0 )
	{
		intoSlowMoTime = 1.0;
		accumTime += 1.0;
		wait( camTime - accumTime );
	}
	SetSlowMotion( 1.0, 0.25, intoSlowMoTime ); // start timescale, end timescale, lerp duration
	
	wait( intoSlowMoTime + .5 );
	
	// finally show the attacker in 3rd person
	SetSlowMotion( 0.25, 1, 1 );
	
	level.doingFinalKillcamFx = undefined;
}


calculateKillCamTime( startTime )
{
	watchedTime = int(getTime() - startTime);
	self incPlayerStat( "killcamtimewatched", watchedTime );
}

waittillKillcamOver()
{
	self endon("abort_killcam");
	
	wait(self.killcamlength - 0.05);
}

setKillCamEntity( killcamentityindex, killcamoffset, starttime )
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	killcamtime = (gettime() - killcamoffset * 1000);
	
	if ( starttime > killcamtime )
	{
		wait .05;
		// code may have trimmed archivetime after the first frame if we couldn't go back in time as far as requested.
		killcamoffset = self.archivetime;
		killcamtime = (gettime() - killcamoffset * 1000);
		
		if ( starttime > killcamtime )
			wait (starttime - killcamtime) / 1000;
	}
	self.killcamentity = killcamentityindex;
}

waitSkipKillcamButton( timeUntilRespawn )
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	if ( !IsAI( self ) )
	{
		self NotifyOnPlayerCommand( "kc_respawn", "+usereload" );
		self NotifyOnPlayerCommand( "kc_respawn", "+activate" );
		
		self waittill("kc_respawn");
		
		self.cancelKillcam = true;
		
		if ( !matchMakingGame() )
			self incPlayerStat( "killcamskipped", 1 );
	
		if ( timeUntilRespawn <= 0 )
			clearLowerMessage( "kc_info" );
		
		self notify("abort_killcam");
	}
}

endKillcamIfNothingToShow()
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	while(1)
	{
		// code may trim our archivetime to zero if there is nothing "recorded" to show.
		// this can happen when the person we're watching in our killcam goes into killcam himself.
		// in this case, end the killcam.
		if ( self.archivetime <= 0 )
			break;
		wait .05;
	}
	
	self notify("abort_killcam");
}

spawnedKillcamCleanup()
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	self waittill("spawned");
	self thread killcamCleanup( false );
}

endedKillcamCleanup()
{
	self endon("disconnect");
	self endon("killcam_ended");
	
	level waittill("game_ended");

	self thread killcamCleanup( true );
}

killcamCleanup( clearState )
{
	// LUA: we need to reset this dvar so the killcam will reset
	self SetClientOmnvar( "ui_killcam_end_milliseconds", 0 );
	// END LUA

	self.killcam = undefined;
	
	showingFinalKillcam = level.showingFinalKillcam;
/#
	if ( getDvarInt( "scr_devfinalkillcam" ) != 0 )
	{
		showingFinalKillcam = true;
		SetSlowMotion( 1.0, 1.0, 0.0 );
		level.doingFinalKillcamFx = undefined;
	}
#/
	if( !showingFinalKillcam ) 
		self setCinematicCameraStyle( "unknown", -1, -1 );

	if ( !level.gameEnded )
		self clearLowerMessage( "kc_info" );
	
	self thread maps\mp\gametypes\_spectating::setSpectatePermissions();
	
	self notify("killcam_ended"); // do this last, in case this function was called from a thread ending on it

	if ( !clearState )
		return;
			
	self updateSessionState( "dead" );
	self ClearKillcamState();
}

// 2013-06-26 wallace
// waitSkipKillcamButton does the same thing, no reason to do both
/*
cancelKillCamOnUse()
{
	self.cancelKillcam = false;
	self thread cancelKillCamOnUse_specificButton( "+usereload", ::cancelKillCamCallback );
	//self thread cancelKillCamOnUse_specificButton( "+frag", ::cancelKillCamSafeSpawnCallback );
}

cancelKillCamCallback()
{
	self.cancelKillcam = true;
}
cancelKillCamSafeSpawnCallback()
{
	self.cancelKillcam = true;
	self.wantSafeSpawn = true;
}

cancelKillCamOnUse_specificButton( inputFlag, finishedFunc )
{
	self endon ( "death_delay_finished" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	while ( true )
	{
		self waittill( inputFlag );
		
		self [[finishedFunc]]();
		return;
	}
}
*/
