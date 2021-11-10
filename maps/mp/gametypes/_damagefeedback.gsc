init()
{
}

updateDamageFeedback( typeHit )
{
	noSound = false;
	if( isdefined( level.damageFeedbackNoSound ) && level.damageFeedbackNoSound )
	   noSound = true;
	   
	if( !IsPlayer( self ) )
		return;

	switch( typeHit )
	{
	case "thermobaric_debuff":
	case "hitblastshield":
	case "hitlightarmor":
	case "hitjuggernaut":
	case "hitmorehealth":
	case "hitmotionsensor":
	case "hitcritical":
	case "hitalienarmor":
	case "hitaliensoft":
	case "hitkill":
	case "hitkilljugg":
	case "hitdeadeyekill":
	case "hitkillblast":
	case "thermodebuff_kill":
		if ( !noSound )
			self PlayLocalSound( "MP_hit_alert" );	
		self SetClientOmnvar( "damage_feedback", typeHit );
		break;
	case "none":
		break;
	
	case "meleestun":				
		if ( !Isdefined( self.meleestun ) )
		{
			if ( !noSound )
				self PlayLocalSound( "crate_impact" );
			self.meleestun = true;
		}
		self SetClientOmnvar( "damage_feedback", "hitcritical" );
		wait 0.2;
		self.meleestun = undefined;
		break;

	default:
		if ( !noSound )
			self PlayLocalSound( "MP_hit_alert" );	
		self SetClientOmnvar( "damage_feedback", "standard" );
		break;
	}
}

hudIconType( typeHit )
{
	noSound = false;
	if( isdefined( level.damageFeedbackNoSound ) && level.damageFeedbackNoSound )
	   noSound = true;
	   
	if( !IsPlayer( self ) )
		return;

	switch( typeHit )
	{
	case "scavenger":
	case "throwingknife":
		if ( !noSound )
			self PlayLocalSound( "scavenger_pack_pickup" );		
		if( !level.hardcoreMode )
			self SetClientOmnvar( "damage_feedback_other", typeHit );
		break;
	case "boxofguns":
		if ( !noSound )
			self PlayLocalSound( "mp_box_guns_ammo" );
		if( !level.hardcoreMode )
			self SetClientOmnvar( "damage_feedback_other", typeHit );
		break;
	case "oracle":
		if ( !noSound )
			self PlayLocalSound( "oracle_radar_pulse_plr" );
		if( !level.hardcoreMode )
			self SetClientOmnvar( "damage_feedback_other", typeHit );
		break;
	}
}
