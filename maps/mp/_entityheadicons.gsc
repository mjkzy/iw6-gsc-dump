#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	if (isdefined(level.initedEntityHeadIcons))
		return;
	level.initedEntityHeadIcons = true;

	if( level.multiTeamBased )
	{
		foreach ( teamName in level.teamNameList )
		{
			str_team_headicon = "entity_headicon_" + teamName;
			game[ str_team_headicon ] = maps\mp\gametypes\_teams::MT_getTeamHeadIcon( teamName );
			precacheShader( game[ str_team_headicon ] );
		}
	}
	else
	{
		game["entity_headicon_allies"] = maps\mp\gametypes\_teams::getTeamHeadIcon( "allies" );
		game["entity_headicon_axis"] = maps\mp\gametypes\_teams::getTeamHeadIcon( "axis" );

		precacheShader( game["entity_headicon_allies"] );
		precacheShader( game["entity_headicon_axis"] );
	}
}

// This can show to single players or to teams.  Showing to a single player destroys instances of 
// the icon that are shown to their team.  Showing to a team destroys instances of the icon that 
// are shown to players on that team
setHeadIcon( showTo, icon, offset, width, height, archived, delay, constantSize, pinToScreenEdge, fadeOutPinnedIcon, is3D )
{
	if ( IsGameParticipant( showTo ) && !IsPlayer( showTo ) )
	    return;	// Doesn't work for Agents, etc.
	
	if ( !isDefined( self.entityHeadIcons ) )
		self.entityHeadIcons = [];

	if( !IsDefined( archived ) )
		archived = true;

	if( !IsDefined( delay ) )
		delay = 0.05;

	if( !IsDefined( constantSize ) )
		constantSize = true;

	if( !IsDefined( pinToScreenEdge ) )
		pinToScreenEdge = true;

	if( !IsDefined( fadeOutPinnedIcon ) )
		fadeOutPinnedIcon = false;

	if( !IsDefined( is3D ) )
		is3D = true;

	if ( !isPlayer( showTo ) && showTo == "none" )
	{
		foreach ( key, headIcon in self.entityHeadIcons )
		{
			// TODO: remove and fix properly after ship
			if ( isDefined( headIcon ) )
				headIcon destroy();
				
			self.entityHeadIcons[ key ] = undefined;
		}
		
		return;
	}

	if ( isPlayer( showTo ) )
	{
		if ( isDefined( self.entityHeadIcons[ showTo.guid ] ) )
		{		
			self.entityHeadIcons[ showTo.guid ] destroy();
			self.entityHeadIcons[ showTo.guid ] = undefined;
		}

		if ( icon == "" )
			return;

		if ( isDefined(showTo.team) )
		{
			// remove from team or we'd have two icons
			if ( isDefined( self.entityHeadIcons[ showTo.team ] ) )
			{
				self.entityHeadIcons[ showTo.team ] destroy();
				self.entityHeadIcons[ showTo.team ] = undefined;
			}
		}

		headIcon = newClientHudElem( showTo );
		self.entityHeadIcons[ showTo.guid ] = headIcon;
	}
	else
	{
		assert( showTo == "axis" || showTo == "allies" || isSubStr( showTo, "team_" ));
		assert( level.teamBased );
		
		if ( isDefined( self.entityHeadIcons[ showTo ] ) )
		{
			self.entityHeadIcons[ showTo ] destroy();
			self.entityHeadIcons[ showTo ] = undefined;
		}

		if ( icon == "" )
			return;

		foreach ( key, hudIcon in self.entityHeadIcons )
		{
			if ( key == "axis" || key == "allies" )
				continue;
			
			player = getPlayerForGuid( key );
			if ( player.team == showTo )
			{
				self.entityHeadIcons[ key ] destroy();
				self.entityHeadIcons[ key ] = undefined;
			}
		}

		headIcon = newTeamHudElem( showTo );
		self.entityHeadIcons[ showTo ] = headIcon;
	}

	if ( !isDefined( width ) || !isDefined( height ) )
	{
		width = 10;
		height = 10;
	}

	headIcon.archived = archived;
	headIcon.x = self.origin[0] + offset[0];
	headIcon.y = self.origin[1] + offset[1];
	headIcon.z = self.origin[2] + offset[2];
	headIcon.alpha = 0.85;
	headIcon setShader( icon, width, height );
	headIcon setWaypoint( constantSize, pinToScreenEdge, fadeOutPinnedIcon, is3D );
	
	headIcon thread keepPositioned( self, offset, delay );
	self thread destroyIconsOnDeath();
	if ( isPlayer( showTo ) )
		headIcon thread destroyOnOwnerDisconnect( showTo );
	if ( isPlayer( self ) )
		headIcon thread destroyOnOwnerDisconnect( self );
		
	return headIcon;
}


destroyOnOwnerDisconnect( owner )
{
	self endon ( "death" );
	
	owner waittill ( "disconnect" );
	
	self destroy();
}


destroyIconsOnDeath()
{
	self notify ( "destroyIconsOnDeath" );
	self endon ( "destroyIconsOnDeath" );
	
	self waittill ( "death" );
	
	if ( !isDefined( self.entityHeadIcons ) )
		return;
	
	foreach ( key, headIcon in self.entityHeadIcons )
	{	
		// TODO: remove and fix properly after ship
		if( !isDefined(headIcon) ) //needed for FFA host migration (when host has active head icons)
			continue;
		
		headIcon destroy();
	}
}


keepPositioned( owner, offset, delay )
{
	self endon ( "death" );
	owner endon ( "death" );
	owner endon ( "disconnect" );
	
	allowCodeLink = ( IsDefined(owner.classname) && !isOwnerCarePakage(owner) );

	if( allowCodeLink )
	{
		self LinkWaypointToTargetWithOffset( owner, offset );
	}
	
	for ( ;; )
	{
		if( !IsDefined( owner ) )
			return;
		
		if( !allowCodeLink ) 
		{
			pos = owner.origin;

			self.x = pos[0] + offset[0];
			self.y = pos[1] + offset[1];
			self.z = pos[2] + offset[2];
		}

		if ( delay > 0.05 )
		{
			self.alpha = 0.85;
			self FadeOverTime( delay );
			self.alpha = 0;
		}

		wait delay;
	}	
}

isOwnerCarePakage( owner )
{
	return ( IsDefined(owner.targetname) && ( owner.targetname == "care_package" ) );
}

setTeamHeadIcon( team, offset ) // "allies", "axis", "all", "none"
{
	if ( !level.teamBased )
		return;

	if ( !isDefined( self.entityHeadIconTeam ) ) 
	{
		self.entityHeadIconTeam = "none";
		self.entityHeadIcon = undefined;
	}

	shader = game["entity_headicon_" + team];	

	self.entityHeadIconTeam = team;
	
	if ( isDefined( offset ) )
		self.entityHeadIconOffset = offset;
	else
		self.entityHeadIconOffset = (0,0,0);

	self notify( "kill_entity_headicon_thread" );

	if ( team == "none" )
	{
		if ( isDefined( self.entityHeadIcon ) )
			self.entityHeadIcon destroy();
		return;
	}
	
	headIcon = newTeamHudElem( team );
	headIcon.archived = true;
	headIcon.x = self.origin[0] + self.entityHeadIconOffset[0];
	headIcon.y = self.origin[1] + self.entityHeadIconOffset[1];
	headIcon.z = self.origin[2] + self.entityHeadIconOffset[2];
	headIcon.alpha = .8;
	headIcon setShader( shader, 10, 10 );
	headIcon setWaypoint( false, false, false, true );
	self.entityHeadIcon = headIcon; 

	self thread keepIconPositioned();
	self thread destroyHeadIconsOnDeath();
}

setPlayerHeadIcon( player, offset ) // "allies", "axis", "all", "none"
{
	if ( level.teamBased )
		return;
	
	if ( !isDefined( self.entityHeadIconTeam ) ) 
	{
		self.entityHeadIconTeam = "none";
		self.entityHeadIcon = undefined;
	}

	self notify( "kill_entity_headicon_thread" );

	if ( !isDefined( player ) )
	{
		if ( isDefined( self.entityHeadIcon ) )
			self.entityHeadIcon destroy();
		return;
	}

	team = player.team;		
	self.entityHeadIconTeam = team;
	
	if ( isDefined( offset ) )
		self.entityHeadIconOffset = offset;
	else
		self.entityHeadIconOffset = (0,0,0);

	shader = game["entity_headicon_" + team];	
	
	headIcon = newClientHudElem( player );
	headIcon.archived = true;
	headIcon.x = self.origin[0] + self.entityHeadIconOffset[0];
	headIcon.y = self.origin[1] + self.entityHeadIconOffset[1];
	headIcon.z = self.origin[2] + self.entityHeadIconOffset[2];
	headIcon.alpha = .8;
	headIcon setShader( shader, 10, 10 );
	headIcon setWaypoint( false, false, false, true );
	self.entityHeadIcon = headIcon; 

	self thread keepIconPositioned();
	self thread destroyHeadIconsOnDeath();
}

keepIconPositioned()
{
	self.entityHeadIcon LinkWaypointToTargetWithOffset( self, self.entityHeadIconOffset );
}

destroyHeadIconsOnDeath()
{
	self endon( "kill_entity_headicon_thread" );
	self waittill ( "death" );

	// TODO: remove and fix properly after ship
	if( !isDefined(self.entityHeadIcon) )
		return;

	self.entityHeadIcon destroy();
}


