#include common_scripts\utility;

bcs_location_trigs_init()
{
	ASSERT( !IsDefined( level.bcs_location_mappings ) );
	level.bcs_location_mappings = [];
	
	bcs_location_trigger_mapping();	
	bcs_trigs_assign_aliases();
	
	// now that the trigger ents have their aliases set on them, clear out our big array
	//  so we can save on script variables
	level.bcs_location_mappings = undefined;
	
	anim.locationLastCalloutTimes = [];
}

bcs_trigs_assign_aliases()
{
	ASSERT( !IsDefined( anim.bcs_locations ) );
	anim.bcs_locations = [];
	
	ents = GetEntArray();
	trigs = [];
	foreach( trig in ents )
	{
		if( IsDefined( trig.classname ) && IsSubStr( trig.classname, "trigger_multiple_bcs" ) )
		{
			trigs[ trigs.size ] = trig;
		}
	}
	
	foreach( trig in trigs )
	{
		if ( !IsDefined( level.bcs_location_mappings[ trig.classname ] ) )
		{
			/#
			// iPrintln( "^2" + "WARNING: Couldn't find bcs location mapping for battlechatter trigger with classname " + trig.classname );
			// do nothing since too many prints kills the command buffer
			#/
		}
		else
		{
			aliases = ParseLocationAliases( level.bcs_location_mappings[ trig.classname ] );
			if( aliases.size > 1 )
			{
				aliases = array_randomize( aliases );
			}
			
			trig.locationAliases = aliases;
		}
	}
	
	anim.bcs_locations = trigs;
}

// parses locationStr using a space as a token and returns an array of the data in that field
ParseLocationAliases( locationStr )
{
	locationAliases = StrTok( locationStr, " " );
	return locationAliases;
}

add_bcs_location_mapping( classname, alias )
{
	// see if we have to add to an existing entry
	if( IsDefined( level.bcs_location_mappings[ classname ] ) )
	{
		existing = level.bcs_location_mappings[ classname ];
		existingArr = ParseLocationAliases( existing );
		aliases = ParseLocationAliases( alias );
		
		foreach( a in aliases )
		{
			foreach( e in existingArr )
			{
				if( a == e )
				{
					return;
				}
			}
		}
		
		existing += " " + alias;
		level.bcs_location_mappings[ classname ] = existing;
		
		return;
	}
	
	// otherwise make a new entry
	level.bcs_location_mappings[ classname ] = alias;
}


// here's where we set up each kind of trigger and map them to their (partial) soundaliases
bcs_location_trigger_mapping()
{
	if ( isSP() )
	{
		generic_locations();
		
		// SP levels
		blackice_locations();
		carrier_locations();
		clockwork_locations();
		cornered_locations();
		enemyhq_locations();
		factory_locations();
		flood_locations();
		homecoming_locations();
		jungleghosts_locations();
		nml_locations();
		oilrocks_locations();
		vegas_locations();
	}
	else
	{
		prisonbreak();
		chasm();
		dart();
		farenheit();
		flooded();
		frag();
		hashima();
		lonestar();
		skeleton();
		snow();
		sovereign();
		strikezone();
		warhawk();
		zebra();
		
		red_river();
		rumble();
		swamp();
		boneyard();
		
		dome();
		impact();
		behemoth();
		battery();
		
		favela();
		pirate();
		zulu();
		dig();
		
		shipment();
		conflict();
		zerosub();
		mine();
	}
}

generic_locations()
{
/*QUAKED trigger_multiple_bcs_generic_doorway_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="doorway_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_doorway_generic", "doorway_generic" );

/*QUAKED trigger_multiple_bcs_generic_window_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="window_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_window_generic", "window_generic" );

/*QUAKED trigger_multiple_bcs_generic_1stfloor_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="1stfloor_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_1stfloor_generic", "1stfloor_generic" );

/*QUAKED trigger_multiple_bcs_generic_1stfloor_doorway (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="1stfloor_doorway"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_1stfloor_doorway", "1stfloor_doorway" );

/*QUAKED trigger_multiple_bcs_generic_1stfloor_window (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="1stfloor_window"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_1stfloor_window", "1stfloor_window" );

/*QUAKED trigger_multiple_bcs_generic_2ndfloor_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="2ndfloor_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_2ndfloor_generic", "2ndfloor_generic" );

/*QUAKED trigger_multiple_bcs_generic_2ndfloor_window (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="2ndfloor_window"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_2ndfloor_window", "2ndfloor_window" );

/*QUAKED trigger_multiple_bcs_generic_rooftop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rooftop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_rooftop", "rooftop" );

/*QUAKED trigger_multiple_bcs_generic_2ndfloor_balcony (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="2ndfloor_balcony"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_generic_2ndfloor_balcony", "2ndfloor_balcony" );
}

blackice_locations()
{
/*QUAKED trigger_multiple_bcs_blackice_airconditioner_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="airconditioner_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_airconditioner_generic", "airconditioner_generic" );

/*QUAKED trigger_multiple_bcs_blackice_crate_ammo (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crate_ammo"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_crate_ammo", "crate_ammo" );

/*QUAKED trigger_multiple_bcs_blackice_bar_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_bar_generic", "bar_generic" );

/*QUAKED trigger_multiple_bcs_blackice_barrels_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="barrels_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_barrels_generic", "barrels_generic" );

/*QUAKED trigger_multiple_bcs_blackice_bookshelf_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bookshelf_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_bookshelf_generic", "bookshelf_generic" );

/*QUAKED trigger_multiple_bcs_blackice_bridge_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_bridge_generic", "bridge_generic" );

/*QUAKED trigger_multiple_bcs_blackice_cart_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cart_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_cart_generic", "cart_generic" );

/*QUAKED trigger_multiple_bcs_blackice_couch_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="couch_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_couch_generic", "couch_generic" );

/*QUAKED trigger_multiple_bcs_blackice_crates_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crates_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_crates_generic", "crates_generic" );

/*QUAKED trigger_multiple_bcs_blackice_engine_left (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="engine_left"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_engine_left", "engine_left" );

/*QUAKED trigger_multiple_bcs_blackice_engine_right (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="engine_right"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_engine_right", "engine_right" );

/*QUAKED trigger_multiple_bcs_blackice_fence_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fence_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_fence_generic", "fence_generic" );

/*QUAKED trigger_multiple_bcs_blackice_forklift_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="forklift_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_forklift_generic", "forklift_generic" );

/*QUAKED trigger_multiple_bcs_blackice_generator_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="generator_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_generator_generic", "generator_generic" );

/*QUAKED trigger_multiple_bcs_blackice_loadingbay_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="loadingbay_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_loadingbay_generic", "loadingbay_generic" );

/*QUAKED trigger_multiple_bcs_blackice_pipes_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pipes_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_pipes_generic", "pipes_generic" );

/*QUAKED trigger_multiple_bcs_blackice_platform_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="platform_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_platform_generic", "platform_generic" );

/*QUAKED trigger_multiple_bcs_blackice_pooltable_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pooltable_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_pooltable_generic", "pooltable_generic" );

/*QUAKED trigger_multiple_bcs_blackice_porch_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="porch_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_porch_generic", "porch_generic" );

/*QUAKED trigger_multiple_bcs_blackice_ramp_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ramp_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_ramp_generic", "ramp_generic" );

/*QUAKED trigger_multiple_bcs_blackice_building_red (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="building_red"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_building_red", "building_red" );

/*QUAKED trigger_multiple_bcs_blackice_snowbank_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="snowbank_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_snowbank_generic", "snowbank_generic" );

/*QUAKED trigger_multiple_bcs_blackice_snowmobile_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="snowmobile_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_snowmobile_generic", "snowmobile_generic" );

/*QUAKED trigger_multiple_bcs_blackice_tank_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tank_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_tank_generic", "tank_generic" );

/*QUAKED trigger_multiple_bcs_blackice_tent_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tent_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_tent_generic", "tent_generic" );

/*QUAKED trigger_multiple_bcs_blackice_tires_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tires_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_tires_generic", "tires_generic" );

/*QUAKED trigger_multiple_bcs_blackice_catwalk_upper (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="catwalk_upper"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_catwalk_upper", "catwalk_upper" );

/*QUAKED trigger_multiple_bcs_blackice_deck_upper (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="deck_upper"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_blackice_deck_upper", "deck_upper" );
}

carrier_locations()
{
/*QUAKED trigger_multiple_bcs_carrier_plane_jet (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="plane_jet"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_carrier_plane_jet", "plane_jet" );

/*QUAKED trigger_multiple_bcs_carrier_plane_f18 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="plane_f18"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_carrier_plane_f18", "plane_f18" );

/*QUAKED trigger_multiple_bcs_carrier_towcart_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="towcart_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_carrier_towcart_generic", "towcart_generic" );

/*QUAKED trigger_multiple_bcs_carrier_forklift_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="forklift_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_carrier_forklift_generic", "forklift_generic" );

/*QUAKED trigger_multiple_bcs_carrier_ohelo_osprey (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ohelo_osprey"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_carrier_ohelo_osprey", "ohelo_osprey" );

/*QUAKED trigger_multiple_bcs_carrier_plane_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="plane_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_carrier_plane_generic", "plane_generic" );

/*QUAKED trigger_multiple_bcs_carrier_deck_outer (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="deck_outer"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_carrier_deck_outer", "deck_outer" );

/*QUAKED trigger_multiple_bcs_carrier_railing_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="railing_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_carrier_railing_generic", "railing_generic" );
}

clockwork_locations()
{
/*QUAKED trigger_multiple_bcs_clockwork_pillar_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pillar_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_pillar_generic", "pillar_generic" );

/*QUAKED trigger_multiple_bcs_clockwork_pool_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pool_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_pool_generic", "pool_generic" );

/*QUAKED trigger_multiple_bcs_clockwork_tram_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tram_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_tram_generic", "tram_generic" );

/*QUAKED trigger_multiple_bcs_clockwork_platform_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="platform_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_platform_generic", "platform_generic" );

/*QUAKED trigger_multiple_bcs_clockwork_platform_left (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="platform_left"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_platform_left", "platform_left" );

/*QUAKED trigger_multiple_bcs_clockwork_platform_right (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="platform_right"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_platform_right", "platform_right" );

/*QUAKED trigger_multiple_bcs_clockwork_stairs_left (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stairs_left"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_stairs_left", "stairs_left" );

/*QUAKED trigger_multiple_bcs_clockwork_stairs_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stairs_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_stairs_generic", "stairs_generic" );

/*QUAKED trigger_multiple_bcs_clockwork_stairs_right (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stairs_right"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_stairs_right", "stairs_right" );

/*QUAKED trigger_multiple_bcs_clockwork_walkway_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="walkway_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_walkway_generic", "walkway_generic" );

/*QUAKED trigger_multiple_bcs_clockwork_walkway_left (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="walkway_left"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_walkway_left", "walkway_left" );

/*QUAKED trigger_multiple_bcs_clockwork_walkway_right (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="walkway_right"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_walkway_right", "walkway_right" );

/*QUAKED trigger_multiple_bcs_clockwork_ramp_main (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ramp_main"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_ramp_main", "ramp_main" );

/*QUAKED trigger_multiple_bcs_clockwork_catwalk_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="catwalk_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_catwalk_generic", "catwalk_generic" );

/*QUAKED trigger_multiple_bcs_clockwork_pool_below (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pool_below"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_clockwork_pool_below", "pool_below" );


}

cornered_locations()
{
/*QUAKED trigger_multiple_bcs_cornered_balcony_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="balcony_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_cornered_balcony_generic", "balcony_generic" );

/*QUAKED trigger_multiple_bcs_cornered_windows_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="windows_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_cornered_windows_generic", "windows_generic" );

/*QUAKED trigger_multiple_bcs_cornered_planter_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="planter_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_cornered_planter_generic", "planter_generic" );

/*QUAKED trigger_multiple_bcs_cornered_wall_back (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="wall_back"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_cornered_wall_back", "wall_back" );

/*QUAKED trigger_multiple_bcs_cornered_tree_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tree_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_cornered_tree_generic", "tree_generic" );

/*QUAKED trigger_multiple_bcs_cornered_rocks_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rocks_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_cornered_rocks_generic", "rocks_generic" );

/*QUAKED trigger_multiple_bcs_cornered_aquarium_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="aquarium_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_cornered_aquarium_generic", "aquarium_generic" );
}

enemyhq_locations()
{
/*QUAKED trigger_multiple_bcs_enemyhq_conession_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="conession_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_conession_generic", "conession_generic" );

/*QUAKED trigger_multiple_bcs_enemyhq_counter_burgertown (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="counter_burgertown"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_counter_burgertown", "counter_burgertown" );

/*QUAKED trigger_multiple_bcs_enemyhq_concession_nate (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="concession_nate"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_concession_nate", "concession_nate" );

/*QUAKED trigger_multiple_bcs_enemyhq_stairs_top (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stairs_top"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_stairs_top", "stairs_top" );

/*QUAKED trigger_multiple_bcs_enemyhq_walkway_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="walkway_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_walkway_generic", "walkway_generic" );

/*QUAKED trigger_multiple_bcs_enemyhq_rubble_pile (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rubble_pile"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_rubble_pile", "rubble_pile" );

/*QUAKED trigger_multiple_bcs_enemyhq_statue_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="statue_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_statue_generic", "statue_generic" );

/*QUAKED trigger_multiple_bcs_enemyhq_counter_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="counter_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_counter_generic", "counter_generic" );

/*QUAKED trigger_multiple_bcs_enemyhq_pillar_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pillar_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_pillar_generic", "pillar_generic" );

/*QUAKED trigger_multiple_bcs_enemyhq_cart_trash (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cart_trash"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_enemyhq_cart_trash", "cart_trash" );
}

factory_locations()
{
/*QUAKED trigger_multiple_bcs_factory_lockerroom_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="lockerroom_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_factory_lockerroom_generic", "lockerroom_generic" );

/*QUAKED trigger_multiple_bcs_factory_server_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="server_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_factory_server_generic", "server_generic" );

/*QUAKED trigger_multiple_bcs_factory_secondfloor_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="secondfloor_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_factory_secondfloor_generic", "secondfloor_generic" );

/*QUAKED trigger_multiple_bcs_factory_catwalk_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="catwalk_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_factory_catwalk_generic", "catwalk_generic" );

/*QUAKED trigger_multiple_bcs_factory_acunit_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="acunit_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_factory_acunit_generic", "acunit_generic" );

/*QUAKED trigger_multiple_bcs_factory_airduct_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="airduct_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_factory_airduct_generic", "airduct_generic" );

}

flood_locations()
{
/*QUAKED trigger_multiple_bcs_flood_tank_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tank_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_tank_generic", "tank_generic" );

/*QUAKED trigger_multiple_bcs_flood_barrier_hesco (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="barrier_hesco"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_barrier_hesco", "barrier_hesco" );

/*QUAKED trigger_multiple_bcs_flood_planter_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="planter_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_planter_generic", "planter_generic" );

/*QUAKED trigger_multiple_bcs_flood_pillar_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pillar_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_pillar_generic", "pillar_generic" );

/*QUAKED trigger_multiple_bcs_flood_truck_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="truck_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_truck_generic", "truck_generic" );

/*QUAKED trigger_multiple_bcs_flood_crates_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crates_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_crates_generic", "crates_generic" );

/*QUAKED trigger_multiple_bcs_flood_duct_air (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="duct_air"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_duct_air", "duct_air" );

/*QUAKED trigger_multiple_bcs_flood_unit_ac (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="unit_ac"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_unit_ac", "unit_ac" );

/*QUAKED trigger_multiple_bcs_flood_walkway_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="walkway_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_walkway_generic", "walkway_generic" );

/*QUAKED trigger_multiple_bcs_flood_pit_rubble (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pit_rubble"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_pit_rubble", "pit_rubble" );

/*QUAKED trigger_multiple_bcs_flood_car_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="car_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_car_generic", "car_generic" );

/*QUAKED trigger_multiple_bcs_flood_van_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="van_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_flood_van_generic", "van_generic" );
}

homecoming_locations()
{
/*QUAKED trigger_multiple_bcs_homecoming_crate_ammo (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crate_ammo"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_crate_ammo", "crate_ammo" );

/*QUAKED trigger_multiple_bcs_homecoming_barrier_hesco (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="barrier_hesco"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_barrier_hesco", "barrier_hesco" );

/*QUAKED trigger_multiple_bcs_homecoming_shack_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="shack_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_shack_blue", "shack_blue" );

/*QUAKED trigger_multiple_bcs_homecoming_barrier_concrete (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="barrier_concrete"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_barrier_concrete", "barrier_concrete" );

/*QUAKED trigger_multiple_bcs_homecoming_statue_artemis (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="statue_artemis"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_statue_artemis", "statue_artemis" );

/*QUAKED trigger_multiple_bcs_homecoming_barrels_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="barrels_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_barrels_generic", "barrels_generic" );

/*QUAKED trigger_multiple_bcs_homecoming_crate_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crate_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_crate_generic", "crate_generic" );

/*QUAKED trigger_multiple_bcs_homecoming_bulldozer_geenric (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bulldozer_geenric"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_bulldozer_geenric", "bulldozer_geenric" );

/*QUAKED trigger_multiple_bcs_homecoming_towers_hesco (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="towers_hesco"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_towers_hesco", "towers_hesco" );

/*QUAKED trigger_multiple_bcs_homecoming_sandbags_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sandbags_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_sandbags_generic", "sandbags_generic" );

/*QUAKED trigger_multiple_bcs_homecoming_pillar_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pillar_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_homecoming_pillar_generic", "pillar_generic" );
}

jungleghosts_locations()
{
/*QUAKED trigger_multiple_bcs_jungleghosts_rocks_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rocks_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_jungleghosts_rocks_generic", "rocks_generic" );

/*QUAKED trigger_multiple_bcs_jungleghosts_bridge_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_jungleghosts_bridge_generic", "bridge_generic" );

/*QUAKED trigger_multiple_bcs_jungleghosts_fern_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fern_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_jungleghosts_fern_generic", "fern_generic" );

/*QUAKED trigger_multiple_bcs_jungleghosts_stream_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stream_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_jungleghosts_stream_generic", "stream_generic" );

/*QUAKED trigger_multiple_bcs_jungleghosts_log_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="log_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_jungleghosts_log_generic", "log_generic" );

/*QUAKED trigger_multiple_bcs_jungleghosts_rock_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rock_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_jungleghosts_rock_generic", "rock_generic" );

/*QUAKED trigger_multiple_bcs_jungleghosts_stump_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stump_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_jungleghosts_stump_generic", "stump_generic" );

/*QUAKED trigger_multiple_bcs_jungleghosts_tree_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tree_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_jungleghosts_tree_generic", "tree_generic" );
}

nml_locations()
{
/*QUAKED trigger_multiple_bcs_nml_dirt_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dirt_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_nml_dirt_generic", "dirt_generic" );

/*QUAKED trigger_multiple_bcs_nml_trailer_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="trailer_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_nml_trailer_generic", "trailer_generic" );

/*QUAKED trigger_multiple_bcs_nml_building_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="building_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_nml_building_blue", "building_blue" );

/*QUAKED trigger_multiple_bcs_nml_bridge_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_nml_bridge_generic", "bridge_generic" );

/*QUAKED trigger_multiple_bcs_nml_garage_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="garage_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_nml_garage_generic", "garage_generic" );

/*QUAKED trigger_multiple_bcs_nml_sandbags_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sandbags_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_nml_sandbags_generic", "sandbags_generic" );
}

oilrocks_locations()
{
/*QUAKED trigger_multiple_bcs_oilrocks_garage_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="garage_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_garage_generic", "garage_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_rooftop_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rooftop_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_rooftop_generic", "rooftop_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_catwalk_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="catwalk_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_catwalk_generic", "catwalk_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_trailer_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="trailer_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_trailer_generic", "trailer_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_stairway_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stairway_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_stairway_generic", "stairway_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_barrels_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="barrels_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_barrels_generic", "barrels_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_crate_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crate_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_crate_generic", "crate_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_can_trash (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="can_trash"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_can_trash", "can_trash" );

/*QUAKED trigger_multiple_bcs_oilrocks_roadblock_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="roadblock_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_roadblock_generic", "roadblock_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_pillar_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pillar_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_pillar_generic", "pillar_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_hallway_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hallway_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_hallway_generic", "hallway_generic" );

/*QUAKED trigger_multiple_bcs_oilrocks_forklift_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="forklift_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_forklift_generic", "forklift_generic" );
	
/*QUAKED trigger_multiple_bcs_oilrocks_can_oxygen (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="can_oxygen"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_oilrocks_can_oxygen", "can_oxygen" );
}

vegas_locations()
{
/*QUAKED trigger_multiple_bcs_vegas_planter_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="planter_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_planter_generic", "planter_generic" );

/*QUAKED trigger_multiple_bcs_vegas_fountain_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fountain_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_fountain_generic", "fountain_generic" );

/*QUAKED trigger_multiple_bcs_vegas_kiosk_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="kiosk_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_kiosk_generic", "kiosk_generic" );

/*QUAKED trigger_multiple_bcs_vegas_slotmachines_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="slotmachines_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_slotmachines_generic", "slotmachines_generic" );

/*QUAKED trigger_multiple_bcs_vegas_rubble_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rubble_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_rubble_generic", "rubble_generic" );

/*QUAKED trigger_multiple_bcs_vegas_pokertable_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pokertable_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_pokertable_generic", "pokertable_generic" );

/*QUAKED trigger_multiple_bcs_vegas_debris_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="debris_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_debris_generic", "debris_generic" );

/*QUAKED trigger_multiple_bcs_vegas_escalator_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="escalator_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_escalator_generic", "escalator_generic" );

/*QUAKED trigger_multiple_bcs_vegas_couch_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="couch_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_couch_generic", "couch_generic" );

/*QUAKED trigger_multiple_bcs_vegas_statue_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="statue_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_statue_generic", "statue_generic" );

/*QUAKED trigger_multiple_bcs_vegas_statue_left (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="statue_left"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_statue_left", "statue_left" );

/*QUAKED trigger_multiple_bcs_vegas_statue_right (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="statue_right"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_statue_right", "statue_right" );

/*QUAKED trigger_multiple_bcs_vegas_tram_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tram_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_tram_generic", "tram_generic" );

/*QUAKED trigger_multiple_bcs_vegas_wall_left (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="wall_left"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_wall_left", "wall_left" );

/*QUAKED trigger_multiple_bcs_vegas_wall_right (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="wall_right"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_wall_right", "wall_right" );

/*QUAKED trigger_multiple_bcs_vegas_tree_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tree_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_tree_generic", "tree_generic" );

/*QUAKED trigger_multiple_bcs_vegas_car_police (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="car_police"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_car_police", "car_police" );

/*QUAKED trigger_multiple_bcs_vegas_car_taxi (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="car_taxi"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_car_taxi", "car_taxi" );

/*QUAKED trigger_multiple_bcs_vegas_car_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="car_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_vegas_car_generic", "car_generic" );
}

//---------------------------------------------------------
// MP
//---------------------------------------------------------
prisonbreak()
{
/*QUAKED trigger_multiple_bcs_mp_prisonbreak_ridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ridge"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_ridge", "ridge" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_constructionyard (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="constructionyard"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_constructionyard", "constructionyard" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_guardtower_generic (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="guardtower_generic"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_guardtower_generic", "guardtower_generic" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_guardtower_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="guardtower_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_guardtower_2ndfloor", "guardtower_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_pipes_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pipes_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_pipes_blue", "pipes_blue" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_securitystation (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="securitystation"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_securitystation", "securitystation" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_trailer_red (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="trailer_red"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_trailer_red", "trailer_red" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_trailer_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="trailer_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_trailer_blue", "trailer_blue" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_road (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="road"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_road", "road" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_river (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="river"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_river", "river" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_loggingcamp (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="loggingcamp"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_loggingcamp", "loggingcamp" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_catwalk (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="catwalk"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_catwalk", "catwalk" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_logstack (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="logstack"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_logstack", "logstack" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_tirestack (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tirestack"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_tirestack", "tirestack" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_loggingtruck (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="loggingtruck"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_loggingtruck", "loggingtruck" );

/*QUAKED trigger_multiple_bcs_mp_prisonbreak_bridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_prisonbreak_bridge", "bridge" );


}

chasm()
{
/*QUAKED trigger_multiple_bcs_mp_chasm_garage_parking (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="garage_parking"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_garage_parking", "garage_parking" );

/*QUAKED trigger_multiple_bcs_mp_chasm_cubicles (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cubicles"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_cubicles", "cubicles" );

/*QUAKED trigger_multiple_bcs_mp_chasm_kitchen (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="kitchen"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_kitchen", "kitchen" );

/*QUAKED trigger_multiple_bcs_mp_chasm_elevator (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="elevator"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_elevator", "elevator" );

/*QUAKED trigger_multiple_bcs_mp_chasm_stairway (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stairway"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_stairway", "stairway" );

/*QUAKED trigger_multiple_bcs_mp_chasm_skybridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="skybridge"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_skybridge", "skybridge" );

/*QUAKED trigger_multiple_bcs_mp_chasm_diner (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="diner"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_diner", "diner" );

/*QUAKED trigger_multiple_bcs_mp_chasm_road_main (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="road_main"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_road_main", "road_main" );

/*QUAKED trigger_multiple_bcs_mp_chasm_rubble_pit (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rubble_pit"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_rubble_pit", "rubble_pit" );

/*QUAKED trigger_multiple_bcs_mp_chasm_restaurant (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="restaurant"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_restaurant", "restaurant" );

/*QUAKED trigger_multiple_bcs_mp_chasm_hotel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hotel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_hotel", "hotel" );

/*QUAKED trigger_multiple_bcs_mp_chasm_bar_hotel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar_hotel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_bar_hotel", "bar_hotel" );

/*QUAKED trigger_multiple_bcs_mp_chasm_underground (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="underground"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_underground", "underground" );

/*QUAKED trigger_multiple_bcs_mp_chasm_subway (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="subway"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_subway", "subway" );

/*QUAKED trigger_multiple_bcs_mp_chasm_waterpump (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="waterpump"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_chasm_waterpump", "waterpump" );
}

dart()
{
/*QUAKED trigger_multiple_bcs_mp_dart_gasstation (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="gasstation"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_gasstation", "gasstation" );

/*QUAKED trigger_multiple_bcs_mp_dart_autoshop_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="autoshop_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_autoshop_2ndfloor", "autoshop_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_dart_autoshop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="autoshop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_autoshop", "autoshop" );

/*QUAKED trigger_multiple_bcs_mp_dart_pinkeez (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pinkeez"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_pinkeez", "pinkeez" );

/*QUAKED trigger_multiple_bcs_mp_dart_pinkeez_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pinkeez_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_pinkeez_2ndfloor", "pinkeez_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_dart_alley_stripclub (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="alley_stripclub"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_alley_stripclub", "alley_stripclub" );

/*QUAKED trigger_multiple_bcs_mp_dart_pawnshop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pawnshop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_pawnshop", "pawnshop" );

/*QUAKED trigger_multiple_bcs_mp_dart_shed_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="shed_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_shed_blue", "shed_blue" );

/*QUAKED trigger_multiple_bcs_mp_dart_motel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="motel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_motel", "motel" );

/*QUAKED trigger_multiple_bcs_mp_dart_bus_stripclub (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bus_stripclub"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_bus_stripclub", "bus_stripclub" );

/*QUAKED trigger_multiple_bcs_mp_dart_bus_motel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bus_motel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_bus_motel", "bus_motel" );

/*QUAKED trigger_multiple_bcs_mp_dart_diner (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="diner"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_diner", "diner" );

/*QUAKED trigger_multiple_bcs_mp_dart_alley_convenience (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="alley_convenience"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_alley_convenience", "alley_convenience" );

/*QUAKED trigger_multiple_bcs_mp_dart_intersection (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="intersection"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_intersection", "intersection" );

/*QUAKED trigger_multiple_bcs_mp_dart_tank_gasstation (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tank_gasstation"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_tank_gasstation", "tank_gasstation" );

/*QUAKED trigger_multiple_bcs_mp_dart_tank_motel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tank_motel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dart_tank_motel", "tank_motel" );
}

farenheit()
{
/*QUAKED trigger_multiple_bcs_mp_farenheit_road_main (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="road_main"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_road_main", "road_main" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_library (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="library"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_library", "library" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_grass_tall (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="grass_tall"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_grass_tall", "grass_tall" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_monument (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="monument"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_monument", "monument" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_trailer_red (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="trailer_red"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_trailer_red", "trailer_red" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_restaurant (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="restaurant"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_restaurant", "restaurant" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_underground (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="underground"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_underground", "underground" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_garage_parking (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="garage_parking"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_garage_parking", "garage_parking" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_bar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_bar", "bar" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_escalators (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="escalators"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_escalators", "escalators" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_bridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_bridge", "bridge" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_bridge_under (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge_under"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_bridge_under", "bridge_under" );

/*QUAKED trigger_multiple_bcs_mp_farenheit_reception (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="reception"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_farenheit_reception", "reception" );
}

flooded()
{
/*QUAKED trigger_multiple_bcs_mp_flooded_garage_lower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="garage_lower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_garage_lower", "garage_lower" );

/*QUAKED trigger_multiple_bcs_mp_flooded_garage_upper (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="garage_upper"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_garage_upper", "garage_upper" );

/*QUAKED trigger_multiple_bcs_mp_flooded_courtyard (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="courtyard"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_courtyard", "courtyard" );

/*QUAKED trigger_multiple_bcs_mp_flooded_patio (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="patio"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_patio", "patio" );

/*QUAKED trigger_multiple_bcs_mp_flooded_restaurant (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="restaurant"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_restaurant", "restaurant" );

/*QUAKED trigger_multiple_bcs_mp_flooded_bar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_bar", "bar" );

/*QUAKED trigger_multiple_bcs_mp_flooded_kitchen (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="kitchen"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_kitchen", "kitchen" );

/*QUAKED trigger_multiple_bcs_mp_flooded_skybridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="skybridge"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_skybridge", "skybridge" );

/*QUAKED trigger_multiple_bcs_mp_flooded_storage_downstairs (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="storage_downstairs"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_storage_downstairs", "storage_downstairs" );

/*QUAKED trigger_multiple_bcs_mp_flooded_building_office (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="building_office"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_building_office", "building_office" );

/*QUAKED trigger_multiple_bcs_mp_flooded_breakroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="breakroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_breakroom", "breakroom" );

/*QUAKED trigger_multiple_bcs_mp_flooded_lobby (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="lobby"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_lobby", "lobby" );

/*QUAKED trigger_multiple_bcs_mp_flooded_newsstation (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="newsstation"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_flooded_newsstation", "newsstation" );
}

frag()
{
/*QUAKED trigger_multiple_bcs_mp_frag_lumberyard (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="lumberyard"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_lumberyard", "lumberyard" );

/*QUAKED trigger_multiple_bcs_mp_frag_containers (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="containers"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_containers", "containers" );

/*QUAKED trigger_multiple_bcs_mp_frag_traintracks (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="traintracks"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_traintracks", "traintracks" );

/*QUAKED trigger_multiple_bcs_mp_frag_distillery (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="distillery"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_distillery", "distillery" );

/*QUAKED trigger_multiple_bcs_mp_frag_distillery_south (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="distillery_south"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_distillery_south", "distillery_south" );

/*QUAKED trigger_multiple_bcs_mp_frag_distillery_north (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="distillery_north"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_distillery_north", "distillery_north" );

/*QUAKED trigger_multiple_bcs_mp_frag_distillery_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="distillery_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_distillery_2ndfloor", "distillery_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_frag_sign_porter (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sign_porter"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_sign_porter", "sign_porter" );

/*QUAKED trigger_multiple_bcs_mp_frag_owens (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="owens"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_owens", "owens" );

/*QUAKED trigger_multiple_bcs_mp_frag_owens_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="owens_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_owens_2ndfloor", "owens_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_frag_owens_3rdfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="owens_3rdfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_owens_3rdfloor", "owens_3rdfloor" );

/*QUAKED trigger_multiple_bcs_mp_frag_pipes_high (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pipes_high"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_pipes_high", "pipes_high" );

/*QUAKED trigger_multiple_bcs_mp_frag_junkyard (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="junkyard"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_junkyard", "junkyard" );

/*QUAKED trigger_multiple_bcs_mp_frag_warehouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="warehouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_warehouse", "warehouse" );

/*QUAKED trigger_multiple_bcs_mp_frag_warehouse_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="warehouse_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_warehouse_2ndfloor", "warehouse_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_frag_warehouse_3rdfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="warehouse_3rdfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_warehouse_3rdfloor", "warehouse_3rdfloor" );

/*QUAKED trigger_multiple_bcs_mp_frag_roof_broken (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="roof_broken"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_roof_broken", "roof_broken" );

/*QUAKED trigger_multiple_bcs_mp_frag_wall_broken (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="wall_broken"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_wall_broken", "wall_broken" );

/*QUAKED trigger_multiple_bcs_mp_frag_dumpster_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dumpster_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_dumpster_blue", "dumpster_blue" );

/*QUAKED trigger_multiple_bcs_mp_frag_dumpster_red (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dumpster_red"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_dumpster_red", "dumpster_red" );

/*QUAKED trigger_multiple_bcs_mp_frag_fence_metal (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fence_metal"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_fence_metal", "fence_metal" );

/*QUAKED trigger_multiple_bcs_mp_frag_window_broken (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="window_broken"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_frag_window_broken", "window_broken" );

}

hashima()
{
/*QUAKED trigger_multiple_bcs_mp_hashima_playground (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="playground"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_playground", "playground" );

/*QUAKED trigger_multiple_bcs_mp_hashima_hangar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hangar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_hangar", "hangar" );

/*QUAKED trigger_multiple_bcs_mp_hashima_sam (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sam"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_sam", "sam" );

/*QUAKED trigger_multiple_bcs_mp_hashima_mine (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="mine"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_mine", "mine" );

/*QUAKED trigger_multiple_bcs_mp_hashima_controlroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="controlroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_controlroom", "controlroom" );

/*QUAKED trigger_multiple_bcs_mp_hashima_traintracks (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="traintracks"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_traintracks", "traintracks" );

/*QUAKED trigger_multiple_bcs_mp_hashima_waterfall (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="waterfall"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_waterfall", "waterfall" );

/*QUAKED trigger_multiple_bcs_mp_hashima_docks (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="docks"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_docks", "docks" );

/*QUAKED trigger_multiple_bcs_mp_hashima_basement (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="basement"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_basement", "basement" );

/*QUAKED trigger_multiple_bcs_mp_hashima_tower_water (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tower_water"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_tower_water", "tower_water" );

/*QUAKED trigger_multiple_bcs_mp_hashima_tower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_tower", "tower" );

/*QUAKED trigger_multiple_bcs_mp_hashima_building_redbrick (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="building_redbrick"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_building_redbrick", "building_redbrick" );

/*QUAKED trigger_multiple_bcs_mp_hashima_building_redbrick_2ndflr (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="building_redbrick_2ndflr"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_building_redbrick_2ndflr", "building_redbrick_2ndflr" );

/*QUAKED trigger_multiple_bcs_mp_hashima_apartment (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="apartment"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_apartment", "apartment" );

/*QUAKED trigger_multiple_bcs_mp_hashima_apartment_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="apartment_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_hashima_apartment_2ndfloor", "apartment_2ndfloor" );

}

lonestar()
{
/*QUAKED trigger_multiple_bcs_mp_lonestar_helicopter_crashed (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="helicopter_crashed"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_helicopter_crashed", "helicopter_crashed" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_tent_fema (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tent_fema"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_tent_fema", "tent_fema" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_carwash (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="carwash"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_carwash", "carwash" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_gasmain (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="gasmain"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_gasmain", "gasmain" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_kiosk (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="kiosk"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_kiosk", "kiosk" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_parking_garage (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="parking_garage"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_parking_garage", "parking_garage" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_burned_building (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="burned_building"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_burned_building", "burned_building" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_gasstation (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="gasstation"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_gasstation", "gasstation" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_rehab (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rehab"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_rehab", "rehab" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_rehab_roof (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rehab_roof"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_rehab_roof", "rehab_roof" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_skybridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="skybridge"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_skybridge", "skybridge" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_office_1stfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="office_1stfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_office_1stfloor", "office_1stfloor" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_office_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="office_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_office_2ndfloor", "office_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_office_roof (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="office_roof"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_office_roof", "office_roof" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_ambulance_service_1stfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ambulance_service_1stfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_ambulance_service_1stfloor", "ambulance_service_1stfloor" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_ambulance_service_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ambulance_service_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_ambulance_service_2ndfloor", "ambulance_service_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_hospital_collapsed (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hospital_collapsed"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_hospital_collapsed", "hospital_collapsed" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_solarpanels (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="solarpanels"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_solarpanels", "solarpanels" );

/*QUAKED trigger_multiple_bcs_mp_lonestar_garage_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="garage_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_lonestar_garage_blue", "garage_blue" );

}

skeleton()
{
/*QUAKED trigger_multiple_bcs_mp_skeleton_castle (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="castle"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_skeleton_castle", "castle" );

/*QUAKED trigger_multiple_bcs_mp_skeleton_mansion (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="mansion"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_skeleton_mansion", "mansion" );

/*QUAKED trigger_multiple_bcs_mp_skeleton_well (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="well"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_skeleton_well", "well" );

/*QUAKED trigger_multiple_bcs_mp_skeleton_hill (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hill"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_skeleton_hill", "hill" );

}

snow()
{
/*QUAKED trigger_multiple_bcs_mp_snow_crashsite (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crashsite"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_crashsite", "crashsite" );

/*QUAKED trigger_multiple_bcs_mp_snow_canyon (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="canyon"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_canyon", "canyon" );

/*QUAKED trigger_multiple_bcs_mp_snow_sawmill (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sawmill"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_sawmill", "sawmill" );

/*QUAKED trigger_multiple_bcs_mp_snow_waterwheel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="waterwheel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_waterwheel", "waterwheel" );

/*QUAKED trigger_multiple_bcs_mp_snow_helicopter (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="helicopter"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_helicopter", "helicopter" );

/*QUAKED trigger_multiple_bcs_mp_snow_shipwreck (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="shipwreck"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_shipwreck", "shipwreck" );

/*QUAKED trigger_multiple_bcs_mp_snow_shipwreck_bow (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="shipwreck_bow"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_shipwreck_bow", "shipwreck_bow" );

/*QUAKED trigger_multiple_bcs_mp_snow_ridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ridge"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_ridge", "ridge" );

/*QUAKED trigger_multiple_bcs_mp_snow_road_main (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="road_main"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_road_main", "road_main" );

/*QUAKED trigger_multiple_bcs_mp_snow_totempole (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="totempole"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_totempole", "totempole" );

/*QUAKED trigger_multiple_bcs_mp_snow_cabin (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cabin"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_cabin", "cabin" );

/*QUAKED trigger_multiple_bcs_mp_snow_boathouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="boathouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_boathouse", "boathouse" );

/*QUAKED trigger_multiple_bcs_mp_snow_dock_fishing (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dock_fishing"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_snow_dock_fishing", "dock_fishing" );

}

sovereign()
{
/*QUAKED trigger_multiple_bcs_mp_sovereign_catwalk_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="catwalk_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_catwalk_blue", "catwalk_blue" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_catwalk_yellow (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="catwalk_yellow"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_catwalk_yellow", "catwalk_yellow" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_centralcommand (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="centralcommand"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_centralcommand", "centralcommand" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_cleanroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cleanroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_cleanroom", "cleanroom" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_warehouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="warehouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_warehouse", "warehouse" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_hologram (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hologram"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_hologram", "hologram" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_assemblyline (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="assemblyline"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_assemblyline", "assemblyline" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_commanddeck (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="commanddeck"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_commanddeck", "commanddeck" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_serverroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="serverroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_serverroom", "serverroom" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_breakroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="breakroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_breakroom", "breakroom" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_shaft (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="shaft"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_shaft", "shaft" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_research (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="research"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_research", "research" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_office_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="office_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_office_2ndfloor", "office_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_warehouse_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="warehouse_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_warehouse_2ndfloor", "warehouse_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_crate (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crate"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_crate", "crate" );

/*QUAKED trigger_multiple_bcs_mp_sovereign_halogen (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="halogen"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_sovereign_halogen", "halogen" );

}

strikezone()
{
/*QUAKED trigger_multiple_bcs_mp_strikezone_bar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_bar", "bar" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_bar_behind (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar_behind"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_bar_behind", "bar_behind" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_backentrance (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="backentrance"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_backentrance", "backentrance" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_Ronnies_01 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="Ronnies_01"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_Ronnies_01", "Ronnies_01" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_proshop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="proshop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_proshop", "proshop" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_statue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="statue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_statue", "statue" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_skywalk (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="skywalk"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_skywalk", "skywalk" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_concessions (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="concessions"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_concessions", "concessions" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_atrium (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="atrium"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_atrium", "atrium" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_concourse_upper (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="concourse_upper"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_concourse_upper", "concourse_upper" );

/*QUAKED trigger_multiple_bcs_mp_strikezone_concourse_lower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="concourse_lower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_strikezone_concourse_lower", "concourse_lower" );

}

warhawk()
{
/*QUAKED trigger_multiple_bcs_mp_warhawk_ambulancebay (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ambulancebay"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_ambulancebay", "ambulancebay" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_bar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_bar", "bar" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_bakery (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bakery"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_bakery", "bakery" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_loadingdock (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="loadingdock"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_loadingdock", "loadingdock" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_granary (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="granary"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_granary", "granary" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_icecream (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="icecream"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_icecream", "icecream" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_apartment (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="apartment"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_apartment", "apartment" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_loft (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="loft"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_loft", "loft" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_cityhall (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cityhall"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_cityhall", "cityhall" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_postoffice (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="postoffice"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_postoffice", "postoffice" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_alley_fence (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="alley_fence"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_alley_fence", "alley_fence" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_backlot (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="backlot"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_backlot", "backlot" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_carport (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="carport"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_carport", "carport" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_hardwarestore (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hardwarestore"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_hardwarestore", "hardwarestore" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_drugstore (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="drugstore"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_drugstore", "drugstore" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_trailer (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="trailer"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_trailer", "trailer" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_watertower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="watertower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_watertower", "watertower" );

/*QUAKED trigger_multiple_bcs_mp_warhawk_repairshop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="repairshop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_warhawk_repairshop", "repairshop" );

}

zebra()
{
/*QUAKED trigger_multiple_bcs_mp_zebra_sciencelab (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sciencelab"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zebra_sciencelab", "sciencelab" );

/*QUAKED trigger_multiple_bcs_mp_zebra_radiostation (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="radiostation"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zebra_radiostation", "radiostation" );

/*QUAKED trigger_multiple_bcs_mp_zebra_hangar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hangar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zebra_hangar", "hangar" );

/*QUAKED trigger_multiple_bcs_mp_zebra_guardtower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="guardtower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zebra_guardtower", "guardtower" );

/*QUAKED trigger_multiple_bcs_mp_zebra_bunker (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bunker"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zebra_bunker", "bunker" );

/*QUAKED trigger_multiple_bcs_mp_zebra_solarpanels (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="solarpanels"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zebra_solarpanels", "solarpanels" );

/*QUAKED trigger_multiple_bcs_mp_zebra_hill (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hill"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zebra_hill", "hill" );

}

/*     *
 * DLC *
 *     */
 
red_river()
{
/*QUAKED trigger_multiple_bcs_mp_red_river_church (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="church"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_church", "church" );

/*QUAKED trigger_multiple_bcs_mp_red_river_church_tower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="church_tower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_church_tower", "church_tower" );

/*QUAKED trigger_multiple_bcs_mp_red_river_pooltables (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pooltables"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_pooltables", "pooltables" );

/*QUAKED trigger_multiple_bcs_mp_red_river_bar_inside (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar_inside"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_bar_inside", "bar_inside" );

/*QUAKED trigger_multiple_bcs_mp_red_river_autoshop_near (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="autoshop_near"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_autoshop_near", "autoshop_near" );

/*QUAKED trigger_multiple_bcs_mp_red_river_autoshop_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="autoshop_2ndfloor_dlc1"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_autoshop_2ndfloor", "autoshop_2ndfloor_dlc1" );

/*QUAKED trigger_multiple_bcs_mp_red_river_grocery (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="grocery"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_grocery", "grocery" );

/*QUAKED trigger_multiple_bcs_mp_red_river_roof_bar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="roof_bar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_roof_bar", "roof_bar" );

/*QUAKED trigger_multiple_bcs_mp_red_river_parkinglot (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="parkinglot"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_red_river_parkinglot", "parkinglot" );
}

rumble()
{
/*QUAKED trigger_multiple_bcs_mp_rumble_giftshop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="giftshop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_giftshop", "giftshop" );

/*QUAKED trigger_multiple_bcs_mp_rumble_coffeeshop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="coffeeshop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_coffeeshop", "coffeeshop" );

/*QUAKED trigger_multiple_bcs_mp_rumble_coffeeshop_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="coffeeshop_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_coffeeshop_2ndfloor", "coffeeshop_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_rumble_lighthouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="lighthouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_lighthouse", "lighthouse" );

/*QUAKED trigger_multiple_bcs_mp_rumble_lighthouse_roof (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="lighthouse_roof"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_lighthouse_roof", "lighthouse_roof" );

/*QUAKED trigger_multiple_bcs_mp_rumble_pier_north (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pier_north"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_pier_north", "pier_north" );

/*QUAKED trigger_multiple_bcs_mp_rumble_pier_south (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pier_south"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_pier_south", "pier_south" );

/*QUAKED trigger_multiple_bcs_mp_rumble_aquarium (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="aquarium"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_aquarium", "aquarium" );

/*QUAKED trigger_multiple_bcs_mp_rumble_fishtank (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fishtank"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_fishtank", "fishtank" );

/*QUAKED trigger_multiple_bcs_mp_rumble_infocenter (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="infocenter"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_infocenter", "infocenter" );

/*QUAKED trigger_multiple_bcs_mp_rumble_museum (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="museum"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_museum", "museum" );

/*QUAKED trigger_multiple_bcs_mp_rumble_fountain (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fountain"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_fountain", "fountain" );

/*QUAKED trigger_multiple_bcs_mp_rumble_bakery_near (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bakery_near"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_bakery_near", "bakery_near" );

/*QUAKED trigger_multiple_bcs_mp_rumble_cablecar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cablecar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_rumble_cablecar", "cablecar" );
}

swamp()
{
/*QUAKED trigger_multiple_bcs_mp_swamp_campsite (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="campsite"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_campsite", "campsite" );

/*QUAKED trigger_multiple_bcs_mp_swamp_ruinedhouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="ruinedhouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_ruinedhouse", "ruinedhouse" );

/*QUAKED trigger_multiple_bcs_mp_swamp_hovercraft (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hovercraft"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_hovercraft", "hovercraft" );

/*QUAKED trigger_multiple_bcs_mp_swamp_cave (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cave"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_cave", "cave" );

/*QUAKED trigger_multiple_bcs_mp_swamp_granary (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="granary_dlc1"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_granary", "granary_dlc1" );

/*QUAKED trigger_multiple_bcs_mp_swamp_granary_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="granary_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_granary_2ndfloor", "granary_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_swamp_treeroots (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="treeroots"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_treeroots", "treeroots" );
	
/*QUAKED trigger_multiple_bcs_mp_swamp_camper (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="camper"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_camper", "camper" );

/*QUAKED trigger_multiple_bcs_mp_swamp_camper_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="camper_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_camper_2ndfloor", "camper_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_swamp_backshed (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="backshed"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_backshed", "backshed" );
	
/*QUAKED trigger_multiple_bcs_mp_swamp_marina (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="marina"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_marina", "marina" );

/*QUAKED trigger_multiple_bcs_mp_swamp_gaspumps (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="gaspumps"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_swamp_gaspumps", "gaspumps" );
}

dome()
{
/*QUAKED trigger_multiple_bcs_mp_dome_digger (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="digger"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_digger", "digger" );

/*QUAKED trigger_multiple_bcs_mp_dome_dig_site (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dig_site"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_dig_site", "dig_site" );

/*QUAKED trigger_multiple_bcs_mp_dome_crane (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crane"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_crane", "crane" );

/*QUAKED trigger_multiple_bcs_mp_dome_meteor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="meteor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_meteor", "meteor" );

/*QUAKED trigger_multiple_bcs_mp_dome_commandcenter (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="commandcenter"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_commandcenter", "commandcenter" );

/*QUAKED trigger_multiple_bcs_mp_dome_lockerroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="lockerroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_lockerroom", "lockerroom" );

/*QUAKED trigger_multiple_bcs_mp_dome_fabrictunnel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fabrictunnel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_fabrictunnel", "fabrictunnel" );

	/*QUAKED trigger_multiple_bcs_mp_dome_spotlight (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="spotlight"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_spotlight", "spotlight" );

/*QUAKED trigger_multiple_bcs_mp_dome_scaffolding (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="scaffolding"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dome_scaffolding", "scaffolding" );


}

boneyard()
{
/*QUAKED trigger_multiple_bcs_mp_boneyard_launchpad (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="launchpad"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_launchpad", "launchpad" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_missioncontrol (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="missioncontrol"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_missioncontrol", "missioncontrol" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_missioncontrol_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="missioncontrol_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_missioncontrol_2ndfloor", "missioncontrol_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_countdown (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="countdown"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_countdown", "countdown" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_fueltank_large (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fueltank_large"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_fueltank_large", "fueltank_large" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_crawler (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crawler"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_crawler", "crawler" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_crawler_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crawler_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_crawler_2ndfloor", "crawler_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_crawler_3rdfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crawler_3rdfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_crawler_3rdfloor", "crawler_3rdfloor" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_testplatform (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="testplatform"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_testplatform", "testplatform" );

/*QUAKED trigger_multiple_bcs_mp_boneyard_rockettest (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rockettest"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_boneyard_rockettest", "rockettest" );
}

impact()
{
/*QUAKED trigger_multiple_bcs_mp_impact_bunkroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bunkroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_bunkroom", "bunkroom" );

/*QUAKED trigger_multiple_bcs_mp_impact_kitchen (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="kitchen2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_kitchen", "kitchen2" );

/*QUAKED trigger_multiple_bcs_mp_impact_breakroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="breakroom2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_breakroom", "breakroom2" );

/*QUAKED trigger_multiple_bcs_mp_impact_bridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_bridge", "bridge2" );

/*QUAKED trigger_multiple_bcs_mp_impact_infirmary (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="infirmary"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_infirmary", "infirmary" );

/*QUAKED trigger_multiple_bcs_mp_impact_crane (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crane2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_crane", "crane2" );

/*QUAKED trigger_multiple_bcs_mp_impact_bridge_under (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge_under2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_bridge_under", "bridge_under2" );

/*QUAKED trigger_multiple_bcs_mp_impact_lowerhold (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="lowerhold"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_lowerhold", "lowerhold" );

/*QUAKED trigger_multiple_bcs_mp_impact_bathroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bathroom2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_bathroom", "bathroom2" );


/*QUAKED trigger_multiple_bcs_mp_impact_portside (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="portside"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_portside", "portside" );

/*QUAKED trigger_multiple_bcs_mp_impact_starboardside (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="starboardside"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_starboardside", "starboardside" );

/*QUAKED trigger_multiple_bcs_mp_impact_bridge_brooklyn (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge_brooklyn"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_impact_bridge_brooklyn", "bridge_brooklyn" );

}

behemoth()
{
/*QUAKED trigger_multiple_bcs_mp_behemoth_controltower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="controltower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_controltower", "controltower" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_commandroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="commandroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_commandroom", "commandroom" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_conveyor_upper (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="conveyor_upper"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_conveyor_upper", "conveyor_upper" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_conveyor_lower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="conveyor_lower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_conveyor_lower", "conveyor_lower" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_breakroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="breakroom2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_breakroom", "breakroom2" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_engineroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="engineroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_engineroom", "engineroom" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_fueltank (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fueltank"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_fueltank", "fueltank" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_cargocrates (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cargocrates"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_cargocrates", "cargocrates" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_bucketwheel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bucketwheel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_bucketwheel", "bucketwheel" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_conveyorcontrol (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="conveyorcontrol"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_conveyorcontrol", "conveyorcontrol" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_doghouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="doghouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_doghouse", "doghouse" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_generators (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="generators"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_generators", "generators" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_turntable_west (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="turntable_west"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_turntable_west", "turntable_west" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_turntable_east (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="turntable_east"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_turntable_east", "turntable_east" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_side_north (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="side_north"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_side_north", "side_north" );

/*QUAKED trigger_multiple_bcs_mp_behemoth_side_south (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="side_south"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_behemoth_side_south", "side_south" );

}

battery()
{
/*QUAKED trigger_multiple_bcs_mp_battery_scaffolding (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="scaffolding2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_scaffolding", "scaffolding2" );

/*QUAKED trigger_multiple_bcs_mp_battery_sundial (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sundial"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_sundial", "sundial" );

/*QUAKED trigger_multiple_bcs_mp_battery_statue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="statue2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_statue", "statue2" );

/*QUAKED trigger_multiple_bcs_mp_battery_stonehead (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="stonehead"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_stonehead", "stonehead" );

/*QUAKED trigger_multiple_bcs_mp_battery_truck (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="truck"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_truck", "truck" );

/*QUAKED trigger_multiple_bcs_mp_battery_tower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tower2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_tower", "tower2" );

/*QUAKED trigger_multiple_bcs_mp_battery_courtyard (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="courtyard2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_courtyard", "courtyard2" );

/*QUAKED trigger_multiple_bcs_mp_battery_pyramid (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pyramid"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_pyramid", "pyramid" );

/*QUAKED trigger_multiple_bcs_mp_battery_crypt (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crypt"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_crypt", "crypt" );

/*QUAKED trigger_multiple_bcs_mp_battery_altar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="altar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_altar", "altar" );

/*QUAKED trigger_multiple_bcs_mp_battery_bridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bridge2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_bridge", "bridge2" );

/*QUAKED trigger_multiple_bcs_mp_battery_aqueduct (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="aqueduct"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_aqueduct", "aqueduct" );

/*QUAKED trigger_multiple_bcs_mp_battery_waterfall (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="waterfall2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_waterfall", "waterfall2" );

/*QUAKED trigger_multiple_bcs_mp_battery_bathhouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bathhouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_bathhouse", "bathhouse" );

/*QUAKED trigger_multiple_bcs_mp_battery_fountain (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fountain2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_fountain", "fountain2" );

/*QUAKED trigger_multiple_bcs_mp_battery_woods (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="woods"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_woods", "woods" );

/*QUAKED trigger_multiple_bcs_mp_battery_cliff (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cliff"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_cliff", "cliff" );

/*QUAKED trigger_multiple_bcs_mp_battery_tunnels (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tunnels"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_tunnels", "tunnels" );

/*QUAKED trigger_multiple_bcs_mp_battery_trophyroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="trophyroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_trophyroom", "trophyroom" );

/*QUAKED trigger_multiple_bcs_mp_battery_armory (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="armory"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_battery_armory", "armory" );

}

favela()
{
/*QUAKED trigger_multiple_bcs_mp_favela_barber_shop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="barber_shop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_barber_shop", "barber_shop" );

/*QUAKED trigger_multiple_bcs_mp_favela_bus_stop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bus_stop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_bus_stop", "bus_stop" );

/*QUAKED trigger_multiple_bcs_mp_favela_graveyard (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="graveyard"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_graveyard", "graveyard" );

/*QUAKED trigger_multiple_bcs_mp_favela_bar2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_bar2", "bar2" );

/*QUAKED trigger_multiple_bcs_mp_favela_bar_rooftop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar_rooftop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_bar_rooftop", "bar_rooftop" );

/*QUAKED trigger_multiple_bcs_mp_favela_soccer_field (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="soccer_field"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_soccer_field", "soccer_field" );

/*QUAKED trigger_multiple_bcs_mp_favela_playground2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="playground2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_playground2", "playground2" );

/*QUAKED trigger_multiple_bcs_mp_favela_icecream_shop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="icecream_shop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_icecream_shop", "icecream_shop" );

/*QUAKED trigger_multiple_bcs_mp_favela_icecream_shop_2ndfloor (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="icecream_shop_2ndfloor"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_icecream_shop_2ndfloor", "icecream_shop_2ndfloor" );

/*QUAKED trigger_multiple_bcs_mp_favela_market (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="market"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_market", "market" );

/*QUAKED trigger_multiple_bcs_mp_favela_market_rooftop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="market_rooftop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_market_rooftop", "market_rooftop" );

/*QUAKED trigger_multiple_bcs_mp_favela_rooftop_garden (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="rooftop_garden"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_rooftop_garden", "rooftop_garden" );

/*QUAKED trigger_multiple_bcs_mp_favela_sodashop (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sodashop"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_sodashop", "sodashop" );

/*QUAKED trigger_multiple_bcs_mp_favela_safe_house (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="safe_house"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_safe_house", "safe_house" );

/*QUAKED trigger_multiple_bcs_mp_favela_shanties (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="shanties"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_shanties", "shanties" );

/*QUAKED trigger_multiple_bcs_mp_favela_dump_site (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dump_site"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_dump_site", "dump_site" );

/*QUAKED trigger_multiple_bcs_mp_favela_checkpoint (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="checkpoint"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_checkpoint", "checkpoint" );

/*QUAKED trigger_multiple_bcs_mp_favela_abandoned_apartments (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="abandoned_apartments"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_abandoned_apartments", "abandoned_apartments" );

/*QUAKED trigger_multiple_bcs_mp_favela_greenapartment (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="greenapartment"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_greenapartment", "greenapartment" );

/*QUAKED trigger_multiple_bcs_mp_favela_greenapartment_roof (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="greenapartment_roof"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_favela_greenapartment_roof", "greenapartment_roof" );
}

dig()
{
/*QUAKED trigger_multiple_bcs_mp_dig_shrine (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="shrine"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_shrine", "shrine" );

/*QUAKED trigger_multiple_bcs_mp_dig_kingstomb (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="kingstomb"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_kingstomb", "kingstomb" );

/*QUAKED trigger_multiple_bcs_mp_dig_balcony (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="balcony"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_balcony", "balcony" );

/*QUAKED trigger_multiple_bcs_mp_dig_mummytomb (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="mummytomb"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_mummytomb", "mummytomb" );

/*QUAKED trigger_multiple_bcs_mp_dig_anubishall (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="anubishall"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_anubishall", "anubishall" );

/*QUAKED trigger_multiple_bcs_mp_dig_digsite (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="digsite"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_digsite", "digsite" );

/*QUAKED trigger_multiple_bcs_mp_dig_platform (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="platform"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_platform", "platform" );

/*QUAKED trigger_multiple_bcs_mp_dig_dogstatues (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dogstatues"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_dogstatues", "dogstatues" );

/*QUAKED trigger_multiple_bcs_mp_dig_courtyard3 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="courtyard3"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_courtyard3", "courtyard3" );

/*QUAKED trigger_multiple_bcs_mp_dig_pharaohsgate (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="pharaohsgate"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_pharaohsgate", "pharaohsgate" );

/*QUAKED trigger_multiple_bcs_mp_dig_burialchamber (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="burialchamber"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_burialchamber", "burialchamber" );

/*QUAKED trigger_multiple_bcs_mp_dig_sphinxhead (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="sphinxhead"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_sphinxhead", "sphinxhead" );

/*QUAKED trigger_multiple_bcs_mp_dig_queenstomb (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="queenstomb"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_queenstomb", "queenstomb" );

/*QUAKED trigger_multiple_bcs_mp_dig_treasureroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="treasureroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_treasureroom", "treasureroom" );

/*QUAKED trigger_multiple_bcs_mp_dig_heiroglyphhall (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="heiroglyphhall"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_heiroglyphhall", "heiroglyphhall" );

/*QUAKED trigger_multiple_bcs_mp_dig_oasis (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="oasis"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_dig_oasis", "oasis" );
}

pirate()
{
/*QUAKED trigger_multiple_bcs_mp_pirate_overlook (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="overlook"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_overlook", "overlook" );

/*QUAKED trigger_multiple_bcs_mp_pirate_captainsquarters (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="captainsquarters"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_captainsquarters", "captainsquarters" );

/*QUAKED trigger_multiple_bcs_mp_pirate_shipprow (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="shipprow"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_shipprow", "shipprow" );

/*QUAKED trigger_multiple_bcs_mp_pirate_tavern (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tavern"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_tavern", "tavern" );

/*QUAKED trigger_multiple_bcs_mp_pirate_cellar (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cellar"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_cellar", "cellar" );

/*QUAKED trigger_multiple_bcs_mp_pirate_drawbridge (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="drawbridge"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_drawbridge", "drawbridge" );

/*QUAKED trigger_multiple_bcs_mp_pirate_inn (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="inn"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_inn", "inn" );

/*QUAKED trigger_multiple_bcs_mp_pirate_voodoohouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="voodoohouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_voodoohouse", "voodoohouse" );

/*QUAKED trigger_multiple_bcs_mp_pirate_courtyard3 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="courtyard3"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_courtyard3", "courtyard3" );

/*QUAKED trigger_multiple_bcs_mp_pirate_prisoncells (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="prisoncells"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_prisoncells", "prisoncells" );

/*QUAKED trigger_multiple_bcs_mp_pirate_undertakers (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="undertakers"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_undertakers", "undertakers" );

/*QUAKED trigger_multiple_bcs_mp_pirate_gallows (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="gallows"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_gallows", "gallows" );

/*QUAKED trigger_multiple_bcs_mp_pirate_brothel (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="brothel"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_brothel", "brothel" );

/*QUAKED trigger_multiple_bcs_mp_pirate_loadingdock2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="loadingdock2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_loadingdock2", "loadingdock2" );

/*QUAKED trigger_multiple_bcs_mp_pirate_watchtower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="watchtower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_pirate_watchtower", "watchtower" );
}

zulu()
{
/*QUAKED trigger_multiple_bcs_mp_zulu_cemetery (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cemetery"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_cemetery", "cemetery" );

/*QUAKED trigger_multiple_bcs_mp_zulu_statue3 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="statue3"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_statue3", "statue3" );

/*QUAKED trigger_multiple_bcs_mp_zulu_market (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="market"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_market", "market" );

/*QUAKED trigger_multiple_bcs_mp_zulu_apartments (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="apartments"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_apartments", "apartments" );

/*QUAKED trigger_multiple_bcs_mp_zulu_bar2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bar2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_bar2", "bar2" );

/*QUAKED trigger_multiple_bcs_mp_zulu_church2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="church2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_church2", "church2" );

/*QUAKED trigger_multiple_bcs_mp_zulu_tire_stack (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tire_stack"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_tire_stack", "tire_stack" );

/*QUAKED trigger_multiple_bcs_mp_zulu_loading_dock (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="loading_dock"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_loading_dock", "loading_dock" );

/*QUAKED trigger_multiple_bcs_mp_zulu_float (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="float"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_float", "float" );

/*QUAKED trigger_multiple_bcs_mp_zulu_scaffolding3 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="scaffolding3"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_scaffolding3", "scaffolding3" );

/*QUAKED trigger_multiple_bcs_mp_zulu_hotel2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hotel2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_hotel2", "hotel2" );

/*QUAKED trigger_multiple_bcs_mp_zulu_florist (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="florist"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_florist", "florist" );

/*QUAKED trigger_multiple_bcs_mp_zulu_hearse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hearse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_hearse", "hearse" );

/*QUAKED trigger_multiple_bcs_mp_zulu_butcher (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="butcher"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zulu_butcher", "butcher" );
}


shipment()
{
/*QUAKED trigger_multiple_bcs_mp_shipment_winnersstage (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="winnersstage"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_winnersstage", "winnersstage" );

/*QUAKED trigger_multiple_bcs_mp_shipment_broadcasterbooth (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="broadcasterbooth"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_broadcasterbooth", "broadcasterbooth" );

/*QUAKED trigger_multiple_bcs_mp_shipment_armory (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="armory"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_armory", "armory" );

/*QUAKED trigger_multiple_bcs_mp_shipment_bettingwindow (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="bettingwindow"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_bettingwindow", "bettingwindow" );

/*QUAKED trigger_multiple_bcs_mp_shipment_arena_red (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="arena_red"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_arena_red", "arena_red" );

/*QUAKED trigger_multiple_bcs_mp_shipment_arena_blue (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="arena_blue"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_arena_blue", "arena_blue" );

/*QUAKED trigger_multiple_bcs_mp_shipment_puzzlebox (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="puzzlebox"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_puzzlebox", "puzzlebox" );

/*QUAKED trigger_multiple_bcs_mp_shipment_walkoffame (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="walkoffame"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_walkoffame", "walkoffame" );

/*QUAKED trigger_multiple_bcs_mp_shipment_walkoffame_near (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="walkoffame_near"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_walkoffame_near", "walkoffame_near" );

/*QUAKED trigger_multiple_bcs_mp_shipment_tower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_tower", "tower" );

/*QUAKED trigger_multiple_bcs_mp_shipment_display (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="display"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_display", "display" );

/*QUAKED trigger_multiple_bcs_mp_shipment_car_green (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="car_green"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_car_green", "car_green" );

/*QUAKED trigger_multiple_bcs_mp_shipment_car_yellow (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="car_yellow"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_shipment_car_yellow", "car_yellow" );


}

conflict()
{
/*QUAKED trigger_multiple_bcs_mp_conflict_market_old (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="market_old"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_market_old", "market_old" );

/*QUAKED trigger_multiple_bcs_mp_conflict_market_new (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="market_new"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_market_new", "market_new" );

/*QUAKED trigger_multiple_bcs_mp_conflict_market_east (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="market_east"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_market_east", "market_east" );

/*QUAKED trigger_multiple_bcs_mp_conflict_market_west (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="market_west"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_market_west", "market_west" );

/*QUAKED trigger_multiple_bcs_mp_conflict_communityhall (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="communityhall"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_communityhall", "communityhall" );

/*QUAKED trigger_multiple_bcs_mp_conflict_fishingpier (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fishingpier"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_fishingpier", "fishingpier" );

/*QUAKED trigger_multiple_bcs_mp_conflict_dock (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dock"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_dock", "dock" );

/*QUAKED trigger_multiple_bcs_mp_conflict_waterside (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="waterside"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_waterside", "waterside" );

/*QUAKED trigger_multiple_bcs_mp_conflict_cliffside (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cliffside"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_cliffside", "cliffside" );

/*QUAKED trigger_multiple_bcs_mp_conflict_garden (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="garden"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_garden", "garden" );

/*QUAKED trigger_multiple_bcs_mp_conflict_temple (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="temple"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_temple", "temple" );

/*QUAKED trigger_multiple_bcs_mp_conflict_mansion2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="mansion2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_mansion2", "mansion2" );

/*QUAKED trigger_multiple_bcs_mp_conflict_fishinghuts (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fishinghuts"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_fishinghuts", "fishinghuts" );

/*QUAKED trigger_multiple_bcs_mp_conflict_alley (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="alley"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_alley", "alley" );

/*QUAKED trigger_multiple_bcs_mp_conflict_dragonstatues (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dragonstatues"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_dragonstatues", "dragonstatues" );

/*QUAKED trigger_multiple_bcs_mp_conflict_restaurant2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="restaurant2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_restaurant2", "restaurant2" );

/*QUAKED trigger_multiple_bcs_mp_conflict_kitchen3 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="kitchen3"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_kitchen3", "kitchen3" );

/*QUAKED trigger_multiple_bcs_mp_conflict_dojo (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="dojo"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_dojo", "dojo" );

/*QUAKED trigger_multiple_bcs_mp_conflict_greenhouse (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="greenhouse"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_conflict_greenhouse", "greenhouse" );


}


mine()
{
/*QUAKED trigger_multiple_bcs_mp_mine_train (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="train"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_train", "train" );

/*QUAKED trigger_multiple_bcs_mp_mine_trainstation (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="trainstation"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_trainstation", "trainstation" );

/*QUAKED trigger_multiple_bcs_mp_mine_watertower2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="watertower2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_watertower2", "watertower2" );

/*QUAKED trigger_multiple_bcs_mp_mine_platform (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="platform"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_platform", "platform" );

/*QUAKED trigger_multiple_bcs_mp_mine_elevator2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="elevator2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_elevator2", "elevator2" );

/*QUAKED trigger_multiple_bcs_mp_mine_refinery (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="refinery"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_refinery", "refinery" );

/*QUAKED trigger_multiple_bcs_mp_mine_cliffs (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="cliffs"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_cliffs", "cliffs" );

/*QUAKED trigger_multiple_bcs_mp_mine_mine2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="mine2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_mine2", "mine2" );

/*QUAKED trigger_multiple_bcs_mp_mine_refinerystairs (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="refinerystairs"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_refinerystairs", "refinerystairs" );

/*QUAKED trigger_multiple_bcs_mp_mine_waterfall3 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="waterfall3"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_waterfall3", "waterfall3" );

/*QUAKED trigger_multiple_bcs_mp_mine_staircase (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="staircase"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_staircase", "staircase" );

/*QUAKED trigger_multiple_bcs_mp_mine_tunnels2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tunnels2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_tunnels2", "tunnels2" );

/*QUAKED trigger_multiple_bcs_mp_mine_hotsprings (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hotsprings"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_hotsprings", "hotsprings" );

/*QUAKED trigger_multiple_bcs_mp_mine_car_rusty (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="car_rusty"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_car_rusty", "car_rusty" );

/*QUAKED trigger_multiple_bcs_mp_mine_redbuilding (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="redbuilding"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_mine_redbuilding", "redbuilding" );


}

zerosub()
{
/*QUAKED trigger_multiple_bcs_mp_zerosub_vents (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="vents"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_vents", "vents" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_missilefactory (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="missilefactory"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_missilefactory", "missilefactory" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_offices (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="offices"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_offices", "offices" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_hallway (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hallway"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_hallway", "hallway" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_controlroom2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="controlroom2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_controlroom2", "controlroom2" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_messhall (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="messhall"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_messhall", "messhall" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_hockeyrink (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="hockeyrink"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_hockeyrink", "hockeyrink" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_missilestorage (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="missilestorage"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_missilestorage", "missilestorage" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_snowbank (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="snowbank"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_snowbank", "snowbank" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_utilityroom (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="utilityroom"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_utilityroom", "utilityroom" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_lab (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="lab"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_lab", "lab" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_tent (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="tent"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_tent", "tent" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_submarine (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="submarine"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_submarine", "submarine" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_securitytower (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="securitytower"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_securitytower", "securitytower" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_crane2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="crane2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_crane2", "crane2" );

/*QUAKED trigger_multiple_bcs_mp_zerosub_fueltank2 (0 0.25 0.5) ?
defaulttexture="bcs"
soundalias="fueltank2"
*/
	add_bcs_location_mapping( "trigger_multiple_bcs_mp_zerosub_fueltank2", "fueltank2" );


}