#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\bots\_bots_util;

/*
 * TODO:
 * Client .exe:
 * 	O Need to be able to see all info for bots you're spectating (killstreaks, ammo, etc.)
 * 	X For others, draw name/rank/etc of bot you're controlling, not your own name/rank/etc.
 * 	? Obit should use name of bot you're controlling, not your own name?
 * 
 * Script
 * 	? Maybe stay in control for 5 seconds in tactics menu for quick changes, if stay in the menu or cycle, then give up control to bot?
 * 	O Highlight player's Buddy with in-game waypoint in Buddy System
 * 	~ need to copy over onto bot/player entering the game the status of all active perks - and end those on the bot/player being subbed out (FIXME: perks are restarting their threads on each switch...)
 * 	! Disallow starting in unsupported gametypes (only bot-supported team modes)
 * 	! Disallow joining spectators or switching teams
 * 	! Give player their own kills, assists, etc - duplicate to the bots?
 * 	!! killstreaks set UI clientdvars directly on the clients, so you don't see the effects when spectating that client and you don't get it copied to you when you take them over...
 * 	!! Player who earns a killstreak while controlling a bot, loses that killstreak when they die/respawn (same for bots?) - only sometimes, not every time... ?  Maybe if you lived for a while after earning it, it stays?
 * 	
 * 
 *	! Need to treat a player disconnecting/leaving the game as end of game and a win for the remaining player
 * 
 * 	!! Entering commander mode sometimes can't find a bot to replace you - dead?  Using killstreak?  Wrong team???
 *	!! Ended up controlling other team's bots?  Need to check every time and assert.
 * 
 * 	!! trying to give unearnable killstreak with givekillstreak() deployable_vest - but callstack shows we reached this through a giveAdrenaline( "kill" ) call...?
 * 
 * 	!! infinite loop in giveRankXP - _rank.gsc line 512 - self == self.owner?  Or...?  From Airstrike.  Buddy system?  Players owned each other?  Actual player owned by same actual player?
 * 	if ( IsDefined(self.owner) && !IsBot( self ) )
	{
		// Call this function on the player's owner instead
		self.owner giveRankXP( type, value, weapon, sMeansOfDeath, challengeName, victim );
	}

[   1328122] Error: called from:
[   1328123] Error: (file 'maps/mp/gametypes/_weapons.gsc', line 3005)
[   1328123] Error:   self.entity thread [[ level.callbackPlayerDamage ]](
[   1328123] Error:                               *
[   1328123] Error: called from:
[   1328123] Error: (file 'maps/mp/killstreaks/_airstrike.gsc', line 426)
[   1328123] Error:    ent maps\mp\gametypes\_weapons::damageEnt(
[   1328123] Error:        *
[   1328123] Error: called from:
[   1328123] Error: (file 'maps/mp/killstreaks/_airstrike.gsc', line 405)
[   1328123] Error:  thread airstrikeDamageEntsThread( sWeapon );
[   1328124] Error:         *
[   1328124] Error: called from:
[   1328124] Error: (file 'maps/mp/killstreaks/_airstrike.gsc', line 940)
[   1328124] Error:   thread losRadiusDamage( traceHit + (0,0,16), 512, 200, 30, owner, bomb, "artillery_mp" ); // targetpos, radius, maxdamage, mindamage, player causing damage, entity that player used to cause damage
[   1328124] Error:          *
[   1328124] Error: started from:
[   1328124] Error: (file 'maps/mp/killstreaks/_airstrike.gsc', line 948)
[   1328124] Error:   wait ( 0.05 );

 
 * !! xpeventpopup infinite loop - from multikill?  Self.owner == self?  Buddy system? Players owned each other?  Actual player owned by same actual player?  Maybe through jumping from bot to bot during buddy system.
	if ( IsDefined(self.owner) )
	{
		// Call this function on the player's owner instead
		self.owner xpEventPopup( event, hudColor, glowAlpha );
	}

 * [   1329389] Error: (file 'maps/mp/gametypes/_rank.gsc', line 1466)
[   1329389] Error:   self.owner xpEventPopup( event, hudColor, glowAlpha );
[   1329389] Error:              *
[   1329389] Error: called from:
[   1329390] Error: (file 'maps/mp/gametypes/_rank.gsc', line 1466)
[   1329390] Error:   self.owner xpEventPopup( event, hudColor, glowAlpha );
[   1329390] Error:              *
[   1329390] Error: called from:
[   1329390] Error: (file 'maps/mp/gametypes/_rank.gsc', line 1466)
[   1329390] Error:   self.owner xpEventPopup( event, hudColor, glowAlpha );
[   1329391] Error:              *
[   1329391] Error: called from:
[   1329391] Error: (file 'maps/mp/_events.gsc', line 630)
[   1329391] Error:   self thread maps\mp\gametypes\_rank::xpEventPopup( &"SPLASHES_DOUBLEKILL" );
[   1329391] Error:               *
[   1329391] Error: called from:
[   1329391] Error: (file 'maps/mp/_events.gsc', line 747)
[   1329391] Error:   self multiKill( killId, self.recentKillCount );
[   1329391] Error:        *
[   1329391] Error: started from:
[   1329392] Error: (file 'maps/mp/_events.gsc', line 744)
[   1329392] Error:  wait ( 1.0 );

 * ? Tried changing class in-game (worked?  bot kept it?  kinda cool, maybe...)
 * 
 * X Client not getting custom classes?
 * X View roll accumulated on you if you jumped in and out of the bot really quick, reset on death (need debounce anyway?)
 * X Keep running visual chart of ownership and assert if get in a recursion.
 * X Drop out of bot while holding placable ballistic vest causes script error
 * 
 * 
 * 

 * UI
 * 	~ Show name of Bot you're spectating on your HUD (UI notification issue with forced spectators?) (do in menu, not HUD)
 * 	~ Always show current tactic on HUD, below mini-map (when tactics menu not up) (do in menu, not HUD)
 * 	X Need to still see score when spectating
 *  X When spectating, killstreak info on HUD is still the player's, not the current bot's... maybe copy it over when you switch to spectating them?
 * 
 * Tactics
 * TDM:
 * 	- Every Man For Himself (nobody follows anyone, default behavior)
 * 		- Run & Gun - everyone runs & fires
 * 		- Check Those Corners - Everyone moves cautiously and uses cover
 * 	- 2 Man Teams (split into 2-man teams - bot will follow player)
 * 	- As A Unit (all 6 stick together, all will follow player)
 * 	- 2 Teams (split into two 3-man teams, try to attack from different directions)
 * 	- Defend this position (everyone hunkers down in an area and plays defense)
 * 
 * DOM:
 * 	- Capture All Points
 * 	- Capture A
 * 	- Capture B
 * 	- Capture C
 * 	- Capture A & B
 * 	- Capture B & C
 * 	- Capture A & C
 *
 */

/*
 * =============================================
 * INITIALIZING
 * =============================================
 */
init()
{
	if ( bot_is_fireteam_mode() )
	{
		level.tactic_notifies = [];

		level.tactic_notifies[0] = "tactics_exit";//deprecated
		level.tactic_notifies[1] = "tactic_none";
		if ( level.gametype == "dom" )
		{
			level.tactic_notifies[2] = "tactic_dom_holdA";
			level.tactic_notifies[3] = "tactic_dom_holdB";
			level.tactic_notifies[4] = "tactic_dom_holdC";
			level.tactic_notifies[5] = "tactic_dom_holdAB";
			level.tactic_notifies[6] = "tactic_dom_holdAC";
			level.tactic_notifies[7] = "tactic_dom_holdBC";
			level.tactic_notifies[8] = "tactic_dom_holdABC";
		}
		else if ( level.gametype == "war" )
		{
			level.tactic_notifies[2] = "tactic_war_hyg";//hold your ground
			level.tactic_notifies[3] = "tactic_war_buddy";//buddy system - 3 two-man teams
			level.tactic_notifies[4] = "tactic_war_hp";//hunting party
			//NOT USED
			level.tactic_notifies[5] = "tactic_war_pincer";//pincer - 2 three-man teams
			level.tactic_notifies[6] = "tactic_war_ctc";//check those corners - free, but cautious, use cover
			level.tactic_notifies[7] = "tactic_war_rg";//run & gun - totally free
		}
		else
		{//TODO: support all team-based modes
			Assert( 0 && "Fireteam mode does not currently support gametype " + level.gametype );
			return;
		}
	
		level.fireteam_commander = [];
        level.fireteam_commander["axis"] = undefined;
        level.fireteam_commander["allies"] = undefined;
        
        level.fireteam_hunt_leader = [];
        level.fireteam_hunt_leader["axis"] = undefined;
        level.fireteam_hunt_leader["allies"] = undefined;

        level.fireteam_hunt_target_zone = [];
        level.fireteam_hunt_target_zone["axis"] = undefined;
        level.fireteam_hunt_target_zone["allies"] = undefined;
        
		//level thread commander_watch_players_connecting();
		//level thread onPlayerConnect();
		level thread commander_wait_connect();
		level thread commander_aggregate_score_on_game_end();
	}
}

commander_aggregate_score_on_game_end()
{
	level waittill( "game_ended" );
	
	if ( IsDefined( level.fireteam_commander["axis"] ) )
	{
		aggScore = 0;
		foreach( player in level.players )
		{
			if ( IsBot( player ) && player.team == "axis" )
			{
				aggScore += player.pers["score"];
			}
		}
		level.fireteam_commander["axis"].pers["score"] = aggScore;
		level.fireteam_commander["axis"].score = aggScore;
		level.fireteam_commander["axis"] maps\mp\gametypes\_persistence::statAdd( "score", aggScore );
		level.fireteam_commander["axis"] maps\mp\gametypes\_persistence::statSetChild( "round", "score", aggScore );
	}

	if ( IsDefined( level.fireteam_commander["allies"] ) )
	{
		aggScore = 0;
		foreach( player in level.players )
		{
			if ( IsBot( player ) && player.team == "allies" )
			{
				aggScore += player.pers["score"];
			}
		}
		level.fireteam_commander["allies"].pers["score"] = aggScore;
		level.fireteam_commander["allies"].score = aggScore;
		level.fireteam_commander["allies"] maps\mp\gametypes\_persistence::statAdd( "score", aggScore );
		level.fireteam_commander["allies"] maps\mp\gametypes\_persistence::statSetChild( "round", "score", aggScore );
	}
}

commander_create_dom_obj( domPointLetter )
{
	Assert( level.gameType == "dom" );
	if ( !IsDefined( self.fireteam_dom_point_obj[domPointLetter] ) )
	{
		//create the objective
		self.fireteam_dom_point_obj[domPointLetter] = maps\mp\gametypes\_gameobjects::getNextObjID();	
		
		//get the right flag position
		pos = (0,0,0);
		foreach( domFlag in level.domFlags )
		{
			if ( domFlag.label == "_"+domPointLetter )
			{
				pos = domFlag.curOrigin;
				break;
			}
		}
		//FIXME: assert if didn't find it...
		
		//add the objective at the pos, but start hidden
		objective_add( self.fireteam_dom_point_obj[domPointLetter], "invisible", pos, "compass_obj_fireteam" );//"waypoint_capture_"+domPointLetter//compass_objpoint_enemy_target//compass_objpoint_mortar_target//TODO: custom fireteam objective icon?
		Objective_PlayerTeam( self.fireteam_dom_point_obj[domPointLetter], self GetEntityNumber() );
	}
}

commander_initialize_gametype()
{
	if ( IsDefined( self.commander_gametype_initialized ) )
		return;
	
	self.commander_gametype_initialized = true;

	self.commander_last_tactic_applied = "tactic_none";
	self.commander_last_tactic_selected = "tactic_none";
	
	switch( level.gameType )
	{
		case "war":
			//nothing to do yet
			break;
		case "dom":
			//create a hidden 2d map objective for each point that we can turn on/off based on the current tactic
			self.fireteam_dom_point_obj = [];
			commander_create_dom_obj("a");
			commander_create_dom_obj("b");
			commander_create_dom_obj("c");
			break;
	}
}


/*
 * =============================================
 * MENU
 * =============================================
 */
commander_monitor_tactics()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	
	//monitor tactics changes and apply all non-bot AI effects
	while( 1 )
	{
		self waittill( "luinotifyserver", channel, index );
		/*
 		//Old pause menu
		if ( channel != "tactic_select" )
		{
			if ( channel == "specator" || channel == "playing" )
			{
				commander_handle_notify( channel, false );
			}
			continue;
		}
		*/
		//new quick menu
		if ( channel != "tactic_select" )
		{
			if ( channel == "bot_select" )
			{
				if ( index > 0 )
				{
					commander_handle_notify_quick( "bot_next" );
				}
				else if ( index < 0 )
				{
					commander_handle_notify_quick( "bot_prev" );
				}
			}
			else if ( channel == "tactics_menu" )
			{
				if ( index > 0 )
				{
					commander_handle_notify_quick( "tactics_menu" );
				}
				else if ( index <= 0 )
				{
					commander_handle_notify_quick( "tactics_close" );
				}
			}
			continue;
		}
		/*
		//old pause menu
		apply = true;
 		if ( index < 0 )
		{
			apply = false;
			index = int(abs( index ));
		}
		*/
		if ( index >= level.tactic_notifies.size )
		{
			assertex( index < level.tactic_notifies.size, "Fireteam Tactical Menu choice index (" + index + ") out of range (" + level.tactic_notifies.size + ")" );
			continue;
		}
		response = level.tactic_notifies[index];
		//old pause menu
		//commander_handle_notify( response, apply );
		commander_handle_notify_quick( response );
	}
}

/*
commander_handle_notify( response, applyChoice )
{
	if ( !IsDefined( response ) )
		return;

	switch( response )
	{
	case "spectator":
		//NOTE: already in spectator mode, all this should do is close the menu
		//self notify( "commander_mode" );
		//self closeMenus();
		if ( IsDefined( self.last_commanded_bot ) )
		{
			//TODO: if we go into full spectate mode (or cycle away from them), let them move freely again
			//self.last_commanded_bot BotSetFlag( "disable_movement", false );
		}
		break;
	case "back":
	case "playing":
		self notify( "takeover_bot" );
		//NOTE: purposely falls through
		//break;
	case "tactic_exit":
		if ( self.commander_last_tactic_applied != self.commander_last_tactic_selected )
		{//selected a tactic we didn't actually apply
			//revert to original choice - the last one applied
			self commander_handle_notify( self.commander_last_tactic_applied, true );
		}
		break;
	case "tactic_none":
		if ( level.gameType == "dom" )
		{
			Objective_State( self.fireteam_dom_point_obj["a"], "invisible" );
			Objective_State( self.fireteam_dom_point_obj["b"], "invisible" );
			Objective_State( self.fireteam_dom_point_obj["c"], "invisible" );
		}
		self.commander_last_tactic_selected = response;
		break;
	//DOMINATION
	case "tactic_dom_holdA":
		Objective_State( self.fireteam_dom_point_obj["a"], "active" );
		Objective_State( self.fireteam_dom_point_obj["b"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["c"], "invisible" );
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_dom_holdB":
		Objective_State( self.fireteam_dom_point_obj["a"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["b"], "active" );
		Objective_State( self.fireteam_dom_point_obj["c"], "invisible" );
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_dom_holdC":
		Objective_State( self.fireteam_dom_point_obj["a"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["b"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["c"], "active" );
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_dom_holdAB":
		Objective_State( self.fireteam_dom_point_obj["a"], "active" );
		Objective_State( self.fireteam_dom_point_obj["b"], "active" );
		Objective_State( self.fireteam_dom_point_obj["c"], "invisible" );
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_dom_holdAC":
		Objective_State( self.fireteam_dom_point_obj["a"], "active" );
		Objective_State( self.fireteam_dom_point_obj["b"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["c"], "active" );
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_dom_holdBC":
		Objective_State( self.fireteam_dom_point_obj["a"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["b"], "active" );
		Objective_State( self.fireteam_dom_point_obj["c"], "active" );
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_dom_holdABC":
		Objective_State( self.fireteam_dom_point_obj["a"], "active" );
		Objective_State( self.fireteam_dom_point_obj["b"], "active" );
		Objective_State( self.fireteam_dom_point_obj["c"], "active" );
		self.commander_last_tactic_selected = response;
		break;
	//TDM
	case "tactic_war_rg"://run & gun - totally free
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_war_ctc"://check those corners - free, but cautious, use cover
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_war_hp"://hunting party
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_war_buddy"://buddy system - 3 two-man teams
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_war_pincer"://pincer - 2 three-man teams
		self.commander_last_tactic_selected = response;
		break;
	case "tactic_war_hyg"://hold your ground
		self.commander_last_tactic_selected = response;
		break;
	//TODO: other modes
	}
	
	if ( applyChoice && response != "tactic_exit" )
	{
		self PlayLocalSound( "earn_superbonus" );
		if ( self.commander_last_tactic_applied != response )
		{//applying a new tactic
			self.commander_last_tactic_applied = response;
		    if ( IsDefined(level.bot_funcs["commander_gametype_tactics"]) )
		    {
		        self [[level.bot_funcs["commander_gametype_tactics"]]](response);
		    }
		}
	}
}
*/

/* Quick select version of the Tactics menu */
commander_handle_notify_quick( response, sendToBotAI )
{
	if ( !IsDefined( response ) )
		return;

	//if ( !IsAlive( self ) )
	//{
		//FIXME: menu should auto-close on death and should not be able to be opened while dead
	//	return;
	//}
	
	switch( response )
	{
	case "bot_prev":
		commander_spectate_next_bot(true);
		break;
	case "bot_next":
		commander_spectate_next_bot(false);
		break;
	case "tactics_menu":
		self notify( "commander_mode" );
		if ( IsDefined( self.forcespectatorent ) )
		{//just to get rid of the hint
			self.forcespectatorent notify( "commander_mode" );
		}
		break;
	case "tactics_close":
		self.commander_closed_menu_time = GetTime();
		self notify( "takeover_bot" );
		break;
	case "tactic_none":
		if ( level.gameType == "dom" )
		{
			Objective_State( self.fireteam_dom_point_obj["a"], "invisible" );
			Objective_State( self.fireteam_dom_point_obj["b"], "invisible" );
			Objective_State( self.fireteam_dom_point_obj["c"], "invisible" );
		}
		break;
	//DOMINATION
	case "tactic_dom_holdA":
		Objective_State( self.fireteam_dom_point_obj["a"], "active" );
		Objective_State( self.fireteam_dom_point_obj["b"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["c"], "invisible" );
		break;
	case "tactic_dom_holdB":
		Objective_State( self.fireteam_dom_point_obj["a"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["b"], "active" );
		Objective_State( self.fireteam_dom_point_obj["c"], "invisible" );
		break;
	case "tactic_dom_holdC":
		Objective_State( self.fireteam_dom_point_obj["a"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["b"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["c"], "active" );
		break;
	case "tactic_dom_holdAB":
		Objective_State( self.fireteam_dom_point_obj["a"], "active" );
		Objective_State( self.fireteam_dom_point_obj["b"], "active" );
		Objective_State( self.fireteam_dom_point_obj["c"], "invisible" );
		break;
	case "tactic_dom_holdAC":
		Objective_State( self.fireteam_dom_point_obj["a"], "active" );
		Objective_State( self.fireteam_dom_point_obj["b"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["c"], "active" );
		break;
	case "tactic_dom_holdBC":
		Objective_State( self.fireteam_dom_point_obj["a"], "invisible" );
		Objective_State( self.fireteam_dom_point_obj["b"], "active" );
		Objective_State( self.fireteam_dom_point_obj["c"], "active" );
		break;
	case "tactic_dom_holdABC":
		Objective_State( self.fireteam_dom_point_obj["a"], "active" );
		Objective_State( self.fireteam_dom_point_obj["b"], "active" );
		Objective_State( self.fireteam_dom_point_obj["c"], "active" );
		break;
	//TDM
	case "tactic_war_rg"://run & gun - totally free
		break;
	case "tactic_war_ctc"://check those corners - free, but cautious, use cover
		break;
	case "tactic_war_hp"://hunting party
		break;
	case "tactic_war_buddy"://buddy system - 3 two-man teams
		break;
	case "tactic_war_pincer"://pincer - 2 three-man teams
		break;
	case "tactic_war_hyg"://hold your ground
		break;
	//TODO: other modes
	}
	
	if ( string_starts_with( response, "tactic_" ) )
	{//applying a new tactic
		self PlayLocalSound( "earn_superbonus" );
		if ( self.commander_last_tactic_applied != response )
		{
			self.commander_last_tactic_applied = response;
			self thread commander_order_ack();
			if ( IsDefined(level.bot_funcs["commander_gametype_tactics"]) )
		    {
		        self [[level.bot_funcs["commander_gametype_tactics"]]](response);
		    }
		}
	}
}

commander_order_ack()
{
	self notify( "commander_order_ack" );
	self endon( "commander_order_ack" );
	
	self endon( "disconnect" );
	
	maxDistSq = (600*600);
	bestDistSq = maxDistSq;
	closestBotAlly = undefined;
	while(1)
	{
		wait(0.5);
		
		bestDistSq = maxDistSq;
		closestBotAlly = undefined;
		
		org = self.origin;
		spectatedBot = self GetSpectatingPlayer();
		if ( IsDefined( spectatedBot ) )
			org = spectatedBot.origin;
		
		foreach( player in level.players )
		{
			if ( IsDefined( player ) && IsAlive( player ) && IsBot( player ) && IsDefined( player.team ) && player.team == self.team )
			{
				distSq = DistanceSquared( org, player.origin );
				if ( distSq < bestDistSq )
				{
					closestBotAlly = player;
				}
			}
		}
		if ( IsDefined( closestBotAlly ) )
		{
			prefix = closestBotAlly.pers["voicePrefix"];
			newAlias = prefix + level.bcSounds[ "callout_response_generic" ];
			closestBotAlly thread maps\mp\gametypes\_battlechatter_mp::doSound( newAlias, true, true );
			return;
		}
	}
}

commander_hint_fade(time)
{
	if ( !IsDefined( self ) )
		return;
	
	self notify( "commander_hint_fade_out" );
	if ( isDefined( self.commanderHintElem ) )
	{
		hud = self.commanderHintElem;
		if ( time > 0 )
		{
			hud ChangeFontScaleOvertime( time );
			hud.fontScale = hud.fontScale * 1.5;
			hud.glowColor = ( 0.3, 0.6, 0.3 );
			hud.glowAlpha = 1;
			hud FadeOverTime( time );
			hud.color = ( 0, 0, 0 );
			hud.alpha = 0;
			wait( time );
		}
		hud maps\mp\gametypes\_hud_util::destroyElem();
	}
}

commander_hint()
{
	self endon( "disconnect" );
	self endon( "commander_mode" );

	self.commander_gave_hint = true;
	
	wait(1);
	if ( !IsDefined( self ) )
		return;
	
	self.commanderHintElem = self maps\mp\gametypes\_hud_util::createFontString( "default", 3 );
	self.commanderHintElem.color = ( 1, 1, 1 );
	self.commanderHintElem setText( &"MPUI_COMMANDER_HINT" );
	self.commanderHintElem.x = 0;
	self.commanderHintElem.y = 20;
	self.commanderHintElem.alignX = "center";
	self.commanderHintElem.alignY = "middle";
	self.commanderHintElem.horzAlign = "center";
	self.commanderHintElem.vertAlign = "middle";
	self.commanderHintElem.foreground = true;
	self.commanderHintElem.alpha = 1;
	self.commanderHintElem.hidewhendead = true;
	self.commanderHintElem.sort = -1;
	self.commanderHintElem endon( "death" );

	self thread commander_hint_delete_on_commander_menu();
	
	wait( 4.0 );
	thread commander_hint_fade(0.5);
}
 
commander_hint_delete_on_commander_menu()
{
	self endon( "disconnect" );
	self endon( "commander_hint_fade_out" );
	
	self waittill( "commander_mode" );
	thread commander_hint_fade(0);
}

hud_monitorPlayerOwnership()
{
	self endon( "disconnect" );
	
	self.ownerShipString = [];
	for ( s=0;s<16;s++)
	{
		self.ownerShipString[s] = self maps\mp\gametypes\_hud_util::createFontString( "default", 1);
		self.ownerShipString[s].color = ( 1, 1, 1 );
		self.ownerShipString[s].x = 0;
		self.ownerShipString[s].y = 30+s*12;
		self.ownerShipString[s].alignX = "center";
		self.ownerShipString[s].alignY = "top";
		self.ownerShipString[s].horzAlign = "center";
		self.ownerShipString[s].vertAlign = "top";
		self.ownerShipString[s].foreground = true;
		self.ownerShipString[s].alpha = 1;
		self.ownerShipString[s].sort = -1;
		self.ownerShipString[s].archived = false;
	}

	while(1)
	{
		i = 0;
		linked_players = [];
		foreach( hudelem in self.ownerShipString )
		{
			hudelem SetDevText( "" );
		}
		
		foreach( player in level.players )
		{
			no_line = false;
			if ( IsDefined( player ) && player.team == self.team )
			{
				if ( IsDefined( player.owner ) )
				{
					if ( array_contains( linked_players, player ) )
					{
						self.ownerShipString[i] SetDevText( player.name + " already linked, but is owned by: " + player.owner.name );
						self.ownerShipString[i].color = ( 1, 0, 0 );
					}
					else
					{
						linked_players = array_add(linked_players, player );
					}
					if ( player != player.owner && array_contains( linked_players, player.owner ) )
					{
						self.ownerShipString[i] SetDevText( player.name + " owned by already linked: " + player.owner.name );
						self.ownerShipString[i].color = ( 1, 0, 0 );
					}
					else
					{
						linked_players = array_add(linked_players, player.owner );
					}
					
					if ( player == self )
					{
						self.ownerShipString[i] SetDevText( player.name + " is the commander, but is owned by: " + player.owner.name );
						self.ownerShipString[i].color = ( 1, 0, 0 );
					}
					else if ( player.owner == player )
					{
						self.ownerShipString[i] SetDevText( player.name + " owned by self!" );
						self.ownerShipString[i].color = ( 1, 0, 0 );
					}
					else if ( player.owner == self )
					{
						self.ownerShipString[i] SetDevText( player.name + " owned by commander: " + player.owner.name );
						self.ownerShipString[i].color = ( 0, 1, 0 );
					}
					else
					{
						self.ownerShipString[i] SetDevText( player.name + " owned by " + player.owner.name );
						self.ownerShipString[i].color = ( 1, 1, 1 );
					}
				}
				else
				{//not owned
					if ( IsDefined(player.bot_fireteam_follower) )
					{//they have a follower, so they're a leader
						no_line = true;
					}
					else
					{
						self.ownerShipString[i] SetDevText( player.name + " unowned!" );
						self.ownerShipString[i].color = ( 1, 1, 0 );
					}
				}
			}
			else
			{
				no_line = true;
			}
			if ( !no_line )
			{
				i++;
			}
		}
		wait(0.1);
	}
}

/*
 * =============================================
 * CONNECTING
 * =============================================
 */
/*
commander_watch_players_connecting()
{
	//NOTE: this is messy, but this function is needed when running from ScriptDevelop
    while(1)
    {
        foreach(player in level.players)
        {
            if ( !IsAI( player ) && !IsDefined(player.fireteam_connected) )
            {
                player.fireteam_connected = true;
                level notify("fireteam_connected",player);
            }
        }
        
        wait(0.05);
    }
}


onPlayerConnect()
{
	//...And this function is used in the normal case
	for(;;)
	{
		level waittill( "connected", player );
        if ( !IsAI( player ) && !IsDefined(player.fireteam_connected) )
        {
            player.fireteam_connected = true;
	        level notify("fireteam_connected",player);
        }
	}
}
*/
	
commander_wait_connect()
{
	//wait for one of the two methods above to let us know a real player has joined the game
	//for(;;)
	//{
	//	level waittill( "fireteam_connected", player );

    while(1)
    {
        foreach(player in level.players)
        {
            if ( !IsAI( player ) && !IsDefined(player.fireteam_connected) )
            {
                player.fireteam_connected = true;
                player SetClientOmnvar( "ui_options_menu", 0 ); // Force this to zero which means don’t open the options menu on connect
		
				player.classCallback = ::commander_loadout_class_callback;
				
				//automagically pick a team and default class
				teamChoice = "allies";
				if ( !isDefined( player.team ) )
				{
					if ( level.teamcount["axis"] < level.teamcount["allies"] )
					{
						teamChoice = "axis";
					}
					else if ( level.teamcount["allies"] < level.teamcount["axis"] )
					{
						teamChoice = "allies";
					}
				}
				player maps\mp\gametypes\_menus::addToTeam( teamChoice );
                level.fireteam_commander[player.team] = player;
				
				player maps\mp\gametypes\_menus::bypassClassChoice();
				player.class_num = 0;//HACK
				player.waitingToSelectClass = false;

				//get ready to start
				player thread onFirstSpawnedPlayer();
				player thread commander_monitor_tactics();
				
				//player thread hud_monitorPlayerOwnership();//debugging tool only - for Buddy System ownership visualization
            }
        }
        wait(0.05);
	}
}


/*
 * =============================================
 * SPAWNING
 * =============================================
 */

onFirstSpawnedPlayer()
{
	self endon("disconnect");

	for(;;)
	{
		//NOTE: can't wait for this - sometimes this has already happened before this thread is even started...
//		self waittill( "spawned" );//"spawned_player"
		if ( self.team != "spectator" && self.sessionstate == "spectator" )
		{
			//initialize stuff for your team
			self thread commander_initialize_gametype();
			//initialize commander mode
			self thread wait_commander_takeover_bot();
			self thread commander_spectate_first_available_bot();
			//self thread commander_takeover_first_available_bot();
			return;
		}
	    wait(0.05);
	}
}


/*
 * =============================================
 * SPECTATING
 * =============================================
 */
commander_spectate_first_available_bot()
{
	self endon("disconnect");
	self endon( "joined_team" );
	self endon( "spectating_cycle" );
	
	while(1)
	{
		foreach( player in level.players )
		{
			if ( isbot( player ) && player.team == self.team )
			{
				self thread commander_spectate_bot( player );
				player thread commander_hint();
				return;
			}
		}
		wait(0.1);
	}
}

monitor_enter_commander_mode()
{
	self endon("disconnect");
	self endon( "joined_spectators" );

	//self NotifyOnPlayerCommand( "commander_mode", "togglemenu" );

	while(1)
	{
		//"start" button
		self waittill( "commander_mode" );
	
		bUsingKillstreak = self maps\mp\killstreaks\_killstreaks::is_using_killstreak();
		bUsingDeployableBox = self maps\mp\killstreaks\_deployablebox::isHoldingDeployableBox();

		if ( !IsAlive( self ) || bUsingKillstreak || bUsingDeployableBox )
		{
			continue;
		}
		break;
	}

	//self closeMenus();
	
	if( self.team == "spectator" )
	{
		assertex(0,"Fireteam: Player tried to go into commander mode when already a spectator!");
		return;
	}

	self thread wait_commander_takeover_bot();

	self PlayLocalSound( "mp_card_slide" );
	
	//bot needs to take over my place
	foundBotReplacement = false;
	foreach( otherPlayer in level.players )
	{
		if ( IsDefined( otherPlayer ) && otherPlayer != self && IsBot( otherPlayer ) && IsDefined( otherPlayer.team ) && otherPlayer.team == self.team && IsDefined( otherPlayer.sidelinedByCommander ) && otherPlayer.sidelinedByCommander == true )
		{
			otherPlayer thread spectator_takeover_other( self );
			foundBotReplacement = true;
			break;
		}
	}
	if ( !foundBotReplacement )
	{//should only happen on first spawn
		assertex(0,"Fireteam: Player could not find a bot to take over for him in spectator mode!");
		self thread maps\mp\gametypes\_playerlogic::spawnSpectator();//force into spectator mode
	}
}

commander_can_takeover_bot( bot )
{
	if ( !IsDefined( bot ) )
		return false;
	
	if ( !IsBot( bot ) )
		return false;
	
	if ( !IsAlive( bot ) )
		return false;
	
	if ( !bot.connected )
		return false;
	
	if ( bot.team != self.team )
		return false;
	
	botUsingKillstreak = bot maps\mp\killstreaks\_killstreaks::is_using_killstreak();
	if ( botUsingKillstreak )
		return false;
	
	botUsingDeployableBox = self maps\mp\killstreaks\_deployablebox::isHoldingDeployableBox();
	if ( botUsingDeployableBox )
		return false;
	
	return true;
}

player_get_player_index()
{
	for( i = 0; i < level.players.size; i++ )
	{
		if ( level.players[i] == self )
			return i;
	}
	return -1;
}

commander_spectate_next_bot( searchBackwards )
{
	currentBot = self GetSpectatingPlayer();
	newBot = undefined;
	start = 0;
	search_direction = 1;
	
	if ( IsDefined( searchBackwards ) && searchBackwards == true )
	{
		search_direction = -1;
	}
	
	if ( IsDefined( currentBot ) )
	{
		start = currentBot player_get_player_index();
	}

	num_checked = 1;
	for( i = start+search_direction; num_checked < level.players.size; i += search_direction )
	{
		num_checked++;
		if ( i < 0 )
		{
			i = level.players.size - 1;
		}
		else if ( i >= level.players.size )
		{
			i = 0;
		}
		
		if ( !IsDefined( level.players[i] ) )
			continue;
		
		if ( IsDefined( currentBot ) && level.players[i] == currentBot )
		{//looped around, nothing else found
			break;
		}

		canCommandeerBot = self commander_can_takeover_bot( level.players[i] );
		if ( canCommandeerBot )
		{
			newBot = level.players[i];
			break;
		}
	}
	
	if ( IsDefined( newBot ) && (!IsDefined( currentBot ) || newBot != currentBot) )
	{
		self thread commander_spectate_bot( newBot );
		self PlayLocalSound( "oldschool_return" );//earn_perk//mp_suitcase_pickup
		newBot thread takeover_flash();
		//TODO: if we go into full spectate mode (or cycle away from them), let them move freely again
		if ( IsDefined( currentBot ) )
		{
			currentBot bot_free_to_move();
		}
	}
	else
	{//failed
		self PlayLocalSound( "counter_uav_deactivate" );
	}
}

commander_spectate_bot( bot )
{//this keeps getting cleared by the executable for some reason
	self notify( "commander_spectate_bot" );
	
	self endon( "commander_spectate_bot" );
	self endon( "commander_spectate_stop" );
	self endon( "disconnect" );
	
	while( IsDefined( bot ) )
	{
		if ( !self.spectatekillcam && bot.sessionstate == "playing" )
		{
			botNum = bot GetEntityNumber();
			if ( self.forcespectatorclient != botNum )
			{
				self allowSpectateTeam( "none", false );
				self allowSpectateTeam( "freelook", false );
				self.forcespectatorclient = botNum;
				self.forcespectatorent = bot;

				self maps\mp\killstreaks\_killstreaks::copy_killstreak_status( bot, true );
			}
			else if ( !IsDefined( self.adrenaline ) || (IsDefined( bot.adrenaline ) && self.adrenaline != bot.adrenaline) )
			{
				self maps\mp\killstreaks\_killstreaks::copy_adrenaline( bot );
			}
		}
		wait(0.05);
	}
}

/*
commander_temp_spectate_bot( bot, time )
{
	self allowSpectateTeam( "none", false );
	self allowSpectateTeam( "freelook", false );
	self.forcespectatorclient = bot GetEntityNumber();
	self.forcespectatorent = bot;
	self delayThread( time, ::commander_can_cycle_spectator_client );
}

commander_can_cycle_spectator_client()
{
	self.forcespectatorclient = -1;
	self.forcespectatorent = undefined;
//	self allowSpectateTeam( "freelook", true );//in Fireteam mode, you can get a bird's eye view of the action...
//	self allowSpectateTeam( "none", true );
}
*/

get_spectated_player()
{
	spectatedPlayer = undefined;
	if ( IsDefined( self.forcespectatorent ) )
	{
		spectatedPlayer = self.forcespectatorent;
	}
	else
	{
		spectatedPlayer = self GetSpectatingPlayer();
	}
	return spectatedPlayer;
}


/*
 * =============================================
 * COMMANDEERING
 * =============================================
 */
commander_takeover_first_available_bot()
{
	self endon("disconnect");
	self endon( "joined_team" );
	self endon( "spectating_cycle" );
	
	while(1)
	{
		foreach( player in level.players )
		{
			if ( isbot( player ) && player.team == self.team )
			{
				self spectator_takeover_other( player );
				return;
			}
		}
		wait(0.1);
	}
}
 
spectator_takeover_other( other )
{
	//make the magic happen here
	
	//Take their origin and angles
	self.forceSpawnOrigin = other.origin;
	viewAngles = other GetPlayerAngles();
	viewAngles = (viewAngles[0], viewAngles[1], 0.0);//don't inherit the roll, accumulates otherwise!
	self.forceSpawnAngles = ( 0, other.angles[1], 0 );
	
	//Take their stance
	self SetStance( other GetStance() );
	
	//Take their complete loadout
	self.botLastLoadout = other.botLastLoadout;
	self.bot_class = other.bot_class;
	self commander_or_bot_change_class( self.bot_class );
	
	//Take their health
	self.health = other.health;

	//TODO:
	//Take their animation?  Maybe not necessary.
	//Copy velocity?
	self.velocity = other.velocity;

	self store_weapons_status( other );
	other maps\mp\gametypes\_weapons::transfer_grenade_ownership( self );
	//Force the other to spectator
	other thread maps\mp\gametypes\_playerlogic::spawnSpectator();//force into spectator mode
	if ( IsBot( other ) )
	{//player taking over bot
		other.sidelinedByCommander = true;
		//allow them to move freely again
		other bot_free_to_move();
		self PlayerCommandBot(other);
		self notify( "commander_spectate_stop" );
		other notify( "commander_took_over" );
	}
	else
	{//player relinquishing control of bot
	}
	
	//Spawn me
	self thread maps\mp\gametypes\_playerlogic::spawnClient();
	self SetPlayerAngles( viewAngles );

	//copy their current weapons, not the ones in their loadout
	self apply_weapons_status();
	self maps\mp\killstreaks\_killstreaks::copy_killstreak_status( other );
	//TODO: any way to take over a bot using a killstreak?  Like carrying a sentry turret or driving a remote take or ac130?
	
	BotSentientSwap( self, other );
	
	if ( IsBot( self ) )
	{//player dropping to spectator mode
		other thread commander_spectate_bot( self );
		other PlayerCommandBot(undefined);
		
		self.sidelinedByCommander = false;
		other PlayLocalSound( "counter_uav_activate" );
		self thread takeover_flash();
		other.commanding_bot = undefined;
		//TODO: commander in spectator mode needs to be able to see Bot's full HUD - ammo, killstreaks, etc.
		
		//Make the bot hang around until we come back in or go into full spectate mode
		other.last_commanded_bot = self;
		//don't let them run off when we're in the tactics menu
		self bot_wait_here();
	}
	else
	{//player taking over bot
		//watch for player going back to commander mode
		self thread monitor_enter_commander_mode();
		self playSound( "copycat_steal_class" );
		self thread takeover_flash();
		self.commanding_bot = other;

		self.last_commanded_bot = undefined;
		if ( !IsDefined( self.commander_gave_hint ) )
		{
			self thread commander_hint();
		}
	}
}

takeover_flash()
{
	if ( !IsDefined( self.takeoverFlashOverlay ) )
	{
		self.takeoverFlashOverlay = newClientHudElem( self );
		self.takeoverFlashOverlay.x = 0;
		self.takeoverFlashOverlay.y = 0;
		self.takeoverFlashOverlay.alignX = "left";
		self.takeoverFlashOverlay.alignY = "top";
		self.takeoverFlashOverlay.horzAlign = "fullscreen";
		self.takeoverFlashOverlay.vertAlign = "fullscreen";
		self.takeoverFlashOverlay setshader ( "combathigh_overlay", 640, 480 );
		self.takeoverFlashOverlay.sort = -10;
		self.takeoverFlashOverlay.archived = true;
	}

	self.takeoverFlashOverlay.alpha = 0.0;	
	self.takeoverFlashOverlay fadeOverTime( 0.25 );
	self.takeoverFlashOverlay.alpha = 1.0;

	wait( 0.75 );

	self.takeoverFlashOverlay fadeOverTime( 0.5 );
	self.takeoverFlashOverlay.alpha = 0.0;
}

wait_commander_takeover_bot()
{
	self endon("disconnect");
	self endon( "joined_team" );

	//just in case: avoid dupe threads
	self notify( "takeover_wait_start" );
	self endon( "takeover_wait_start" );
	
	//TODO: show X button "Take Over Bot" choice on Spectator HUD
	//self NotifyOnPlayerCommand( "takeover_bot", "+usereload" );
	while( 1 )
	{
		//"X" button
		self waittill( "takeover_bot" );
		
		spectatedPlayer = get_spectated_player();
		
		canCommandeerBot = self commander_can_takeover_bot( spectatedPlayer );
		if ( !canCommandeerBot )
		{
			self commander_spectate_next_bot( false );
			spectatedPlayer = get_spectated_player();
			canCommandeerBot = self commander_can_takeover_bot( spectatedPlayer );
		}
		
		if ( canCommandeerBot )
		{
			self thread spectator_takeover_other( spectatedPlayer );
			break;
		}
		self PlayLocalSound( "counter_uav_deactivate" );
	}
}

bot_wait_here()
{
	if ( !IsDefined( self ) || !IsPlayer( self ) || !IsBot( self ) )
		return;

	self notify( "wait_here" );

	self BotSetFlag( "disable_movement", true );

	self.badplacename = "bot_waiting_"+self.team+"_"+self.name;
	BadPlace_Cylinder( self.badplacename, 5, self.origin, 32, 72, self.team );
	
	self thread bot_delete_badplace_on_death();
	self thread bot_wait_free_to_move();
}

bot_delete_badplace_on_death( bot )
{
	self endon( "freed_to_move" );
	self endon( "disconnect" );
	
	self waittill( "death" );
	
	self bot_free_to_move();
}

bot_wait_free_to_move()
{
	self endon( "wait_here" );

	wait(5);
	
	self thread bot_free_to_move();
}

bot_free_to_move()
{
	if ( !IsDefined( self ) || !IsPlayer( self ) || !IsBot( self ) )
		return;
	
	self BotSetFlag( "disable_movement", false );

	if ( IsDefined( self.badplacename ) )
		BadPlace_Delete( self.badplacename );
	
	self notify( "freed_to_move" );
}

/*
 * =============================================
 * WEAPONS/EQUIPMENT
 * =============================================
 */
commander_loadout_class_callback( bot )
{
	return self.botLastLoadout;
}

commander_or_bot_change_class( newClass )
{
	self.pers["class"] = newClass;
	self.class = newClass;

	self maps\mp\gametypes\_class::setClass( newClass );
	self.tag_stowed_back = undefined;
	self.tag_stowed_hip = undefined;
}

store_weapons_status( from )
{
	//weapons
	self.copy_fullweaponlist = from GetWeaponsListAll();
	self.copy_weapon_current = from GetCurrentWeapon();
	
	//ammo
	foreach( weapon in self.copy_fullweaponlist )
	{
		self.copy_weapon_ammo_clip[ weapon ] = from GetWeaponAmmoClip( weapon );
		self.copy_weapon_ammo_stock[ weapon ] = from GetWeaponAmmoStock( weapon );
	}
}

apply_weapons_status()
{
	//weapons
	//get any weapons we don't have
	foreach( weapon in self.copy_fullweaponlist )
	{
		if ( !(self HasWeapon( weapon )) )
		{
			self GiveWeapon( weapon );
		}
	}

	//remove any they didn't have
	myWeapons = self GetWeaponsListAll();
	foreach( weapon in myWeapons )
	{
		if ( !array_contains( self.copy_fullweaponlist, weapon ) )
		{
			self TakeWeapon( weapon );
		}
	}

	//ammo
	foreach( weapon in self.copy_fullweaponlist )
	{
		if ( self HasWeapon( weapon ) )
		{
			self SetWeaponAmmoClip( weapon, self.copy_weapon_ammo_clip[ weapon ]  );
			self SetWeaponAmmoStock( weapon, self.copy_weapon_ammo_stock[ weapon ]  );
		}
		else
		{
			Assert( 0 && "tried to set copy ammo on a weapon we didn't copy: "+weapon+"!" );
		}
	}

	//change to their weapon
	if ( self GetCurrentWeapon() != self.copy_weapon_current )
	{
		self SwitchToWeapon( self.copy_weapon_current );
	}
}