#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\alien\_utility;
#include maps\mp\agents\_agent_utility;
#include maps\mp\alien\_persistence;
#include maps\mp\alien\_perk_utility;


COLLECTIBLES_TABLE			= "mp/alien/collectibles.csv";		// collectable itmes definition

TABLE_ITEM_INDEX			= 0;	// Indexing
TABLE_ITEM_REF				= 1;	// reference string
TABLE_ITEM_MODEL			= 2;	// xmodel string
TABLE_ITEM_NAME				= 3;	// localization name
TABLE_ITEM_DESC				= 4;	// localization desc, use hint
TABLE_ITEM_COUNT			= 5;	// count per spawn
TABLE_ITEM_PARTS			= 6;	// parts array
TABLE_ITEM_OWNERSHIP		= 7;	// ownership type, soulbound/shared/droppable
TABLE_ITEM_RESPAWN			= 8;	// respawn timer, 0 = no respawn, float value
TABLE_ITEM_RESPAWN_MAX		= 9;	// respawn times, 0 = always, 1 = respawns once
TABLE_ITEM_VIS				= 10;	// visibility condition string
TABLE_ITEM_UNLOCK			= 11;	// unlock requirement
TABLE_ITEM_PLAYER_MAX		= 12; 	// player inventory max carry count

TABLE_ITEM_PERSIST			= 13;	// Does not get removed from the world after use
TABLE_ITEM_XP				= 14;	// XP reward for collecting
TABLE_ITEM_COST				= 15;	// cost of pickup if it requires, 0 = no cost

ITEM_MIN_SPAWN_DISTANCE_SQR = 1024.0 * 1024.0;

DROP_TO_GROUND_UP_DIST                = 32;
DROP_TO_GROUND_DOWN_DIST              = -32;
DROP_TO_GROUND_PROPANE_TANK_DOWN_DIST = -500;

CONST_PISTOL_BEAST_AMMO_COST		=	1500;  //Cost for ammo at a weapon if player is running pistols only and earn your keep

pre_load()
{
	if ( !alien_mode_has( "collectible" ) )
		return;
	
	if ( !isdefined( level.alien_collectibles_table ) )
		level.alien_collectibles_table = COLLECTIBLES_TABLE;
	
	// precache item assets
	collectibles_model_precache();
	
	// setup fx
	level._effect[ "Fire_Cloud" ]	 = loadfx( "vfx/gameplay/alien/vfx_alien_gas_fire");
	level._effect[ "Propane_explosion" ] = loadfx( "vfx/gameplay/alien/vfx_alien_propane_tank_explosion" );
	level._effect[ "Propane_explosion_cheap" ] = loadfx( "vfx/gameplay/alien/vfx_alien_propane_tank_exp_cheaper" );
	level._effect[ "Propane_explosion_cheapest" ] = loadfx( "vfx/gameplay/alien/vfx_alien_propane_tank_exp_cheapest" );

	// init collectibles table
	level.collectibles 	= [];
	collectibles_table_init( 0, 99 );		// items
	collectibles_table_init( 100, 199 );	// weapons
	
	// precache collectible pickup strings ( must match [desc] of stringtable: mp/alien/collectibles.csv )
	all_hints_array = [[level.hintprecachefunc]]();
	
	foreach ( item in level.collectibles )
	{
		foreach ( key, hint in all_hints_array )
		{
			if ( item.desc == key )
			{
				item.desc = get_localized_hint( item, hint );
				break; // item.desc is now a localized string, can't compare to regular strings anymore
			}
		} 
	}
	
	level.pistol_ammo_cost = CONST_PISTOL_BEAST_AMMO_COST;
}

get_localized_hint( item, hint )
{
	if ( is_chaos_mode() && item.isWeapon )				
		return &"ALIEN_CHAOS_WEAPON_PICKUP_HINT";

	return hint;
}

collectibles_model_precache()
{
	PreCacheModel( "propane_tank_aliens_iw6" );
}


post_load()
{	
	if ( !alien_mode_has( "collectible" ) )
		return;
	
	// init collectibles in the world
	collectibles_world_init();
	
	level.collectibles_lootcount = 0;
	level.alien_loot_initialized = true;
}

// sets up player for loot collection - fresh start every spawn, lose everything!
player_loot_init()
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( !alien_mode_has( "loot" ) )
		return;
	
	self.lootbag = [];
	self.has_health_pack = false;

	self notify( "loot_initialized" );
	
	level.fireCloudDuration 			= getDvarInt( "scr_fireCloudDuration", 			"9"		);
	level.fireCloudRadius 				= getDvarInt( "scr_fireCloudRadius", 			"125"	);
	level.fireCloudHeight 				= getDvarInt( "scr_fireCloudHeight", 			"120"	);
	level.fireCloudTickDamage 			= getDvarInt( "scr_fireCloudTickDamage", 		"100"	); // alien tick is fixed to 1 second interval
	level.fireCloudHiveTickDamage		= getDvarInt( "scr_fireCloudHiveTickDamage", 	"100"	); // hive tick is fixed to 0.25 second interval
	level.fireCloudPlayerTickDamage 	= getDvarInt( "scr_fireCloudPlayerTickDamage", 	"3"		); // player tick is fixed to 1 second interval
	level.fireCloudLingerTime			= getDvarInt( "scr_fireCloudLingerTime",		"6"		); // seconds alien gets burned after touching fire
	
}

collectibles_world_init()
{
	assertex( isdefined( level.collectibles ), "Collectibles not initialized" );
	level.itemexplodethisframe = false;
	level.collectibles_worldcount = [];
	
	// grab all collectible items
	items = getstructarray( "item", "targetname" );
	
	if ( isDefined( level.additional_boss_weapon ) )
	{
		additional_boss_weapon = [[ level.additional_boss_weapon]]();
		if ( isDefined( additional_boss_weapon ) )
			items = array_add( items,additional_boss_weapon );
	}
	
	if ( is_chaos_mode() )
		items = maps\mp\alien\_chaos::swap_weapon_items( items );	
			
	level.world_items = items;
	
	foreach ( world_item in level.world_items )
	{
		assertex( isdefined( world_item.script_noteworthy ), "Item at " + world_item.origin + " is missing script_noteworthy as item type" );
		world_item.item_ref = world_item.script_noteworthy;
		assertex( item_exist( world_item.item_ref ), "Item: " + world_item.item_ref + " does not exist in collectibles, update collectibles.csv, and check if max_item_index is set to include number of items in table" );
		
		world_item setup_item_data();
		
		level.collectibles_worldcount[ world_item.item_ref ] = level.collectibles[ world_item.item_ref ].count;
	}
	
	init_throwableItems();
	
	area_name = get_current_area_name();
	if ( is_chaos_mode() )
		area_name = get_chaos_area();

	thread spawn_items_in_area( area_name );
	
	if ( isDefined( level.enter_area_func ) )
		[[level.enter_area_func]]( area_name );
}

init_throwableItems()
{
	level.thrown_entities = [];
	
	level.throwable_items = [];
	//                           weapon name
	level.throwable_items [ "alienpropanetank_mp" ] = init_throwable( 10000, "propane_tank_aliens_iw6", true, &"ALIEN_COLLECTIBLES_PICKUP_PROPANE_TANK", ::propaneTankWatchUse );
}

init_throwable( force, model, canBePickedUp, hintString, pickUpFunc )
{
	item_data = spawnStruct();
	item_data.force = force;   // the forward force that is applied when the item is thrown
	item_data.model = model;   // the item model
	item_data.canBePickedUp = canBePickedUp;  // boolean.  whether the item can be picked back up again
	item_data.hintString = hintString;        // if the item can be picked up back, the hint string that is applied
	item_data.pickUpFunc = pickUpFunc;        // if the item can be picked up back, call back function on the item
	
	return item_data;
}


spawn_items_in_area( area )
{
	randomized_items = array_randomize( level.world_items );
	
	foreach ( world_item in randomized_items )
	{
		if ( !world_item.data["persist"] && area != "all" && !array_contains( world_item.areas, area ) )
			continue;
		
		if ( level.collectibles_worldcount[ world_item.item_ref ] > 0 )
		{
			if ( isDefined( world_item.item_ent ) )
				continue;
			
			world_item spawn_item();
			world_item thread item_pickup_listener();
			level.collectibles_worldcount[ world_item.item_ref ]--;
		}
	}
}

remove_items_in_area( area )
{
	foreach( world_item in level.world_items )
	{
		if ( isDefined( world_item.item_ent ) )
		{
			if ( !world_item.data["persist"] && area != "all" && !array_contains( world_item.areas, area ) )
				continue;
			
			world_item remove_world_item();
			level.collectibles_worldcount[ world_item.item_ref ]++;
		}
	}
}


// this keeps track of data (such as count, respawn times etc) per item
setup_item_data( )
{
	self.override = SpawnStruct();
	
	if ( !isdefined( self.script_noteworthy ) )
		self.script_noteworthy = self.item_ref;

	self.isLoot		= is_collectible_loot( self.item_ref );
	self.isWeapon	= is_collectible_weapon( self.item_ref );
	self.isItem		= is_collectible_item( self.item_ref );
	
	self.areas		= self get_item_areas();
	
	// overrides
	if ( isdefined( self.script_parameters ) )
	{
		// parsing parameters
		// format: "key=value key=value"
		string_toks = StrTok( self.script_parameters, " " );
		foreach ( token in string_toks )
		{
			string_tok = StrTok( self.script_parameters, "=" );
			
			if ( string_tok.size == 0 )
				continue;
			
			assertex( string_tok.size == 2, "Incorrect format for override parameter, script_parameters 'key=value key=value ...'" );

			key 	= string_tok[ 0 ];
			value 	= string_tok[ 1 ];

			switch ( key )
			{
				case "respawn_max":
					self.override.respawn_max = int( value );
					break;

				case "unlock":
					self.override.unlock = int( value );
					break;
		
				default:
					AssertMsg( "You can not override: " + key + " on " + self.item_ref );
					break;
			}
		}
	}
	
	// init item data, tracker of item data
	self.data = [];
	self.data[ "count" ] 			= level.collectibles[ self.item_ref ].count;
	self.data[ "respawn_count" ]	= level.collectibles[ self.item_ref ].respawn_max;
	
	self.data[ "times_collected" ] 	= 0;
	self.data[ "last_collector" ] 	= undefined;
	self.data[ "vis" ]				= true;	// visibility
	self.data[ "unlock" ]			= 1;
	self.data[ "persist" ] 			= level.collectibles[ self.item_ref ].persist;
	self.data[ "cost" ] 			= level.collectibles[ self.item_ref ].cost;

	if ( isdefined( self.override ) )
	{
		if ( isdefined( self.override.respawn_max ) )
			self.data[ "respawn_count" ] = self.override.respawn_max;
		if ( isdefined( self.override.unlock ) )
			self.data[ "unlock" ] = self.override.unlock;
	}
}

get_item_areas()
{
	if ( !isDefined( level.world_areas ) )
	{
		return;
	}
	
	my_areas = [];
	
	foreach ( area_name, area_volume in level.world_areas )
	{
		if ( IsPointInVolume( self.origin, area_volume ) )
		{
			my_areas[ my_areas.size ] = area_name;
		}
	}
	
	return my_areas;
}

spawn_world_item( dropToGround, needPressXToUse )
{
	// self is world item struct	
	item_ref = self.item_ref;
	
	item_ent = spawn( "script_model", get_world_item_spawn_pos( dropToGround ) );
	item_ent SetModel( level.collectibles[ item_ref ].model );

	if ( is_chaos_mode() && is_true( self.isweapon ) )
		item_ent.weapon_ref = getsubstr( item_ref, 7 );	// to remove "weapon_"
	
	if ( IsDefined( self.angles ) )
	{
	   	item_ent.angles = self.angles;
	}
	else
	{
		item_ent.angles = (0, 0, 0);
	}
	
	self.item_ent = item_ent;
	
	if ( needPressXToUse )
	{
		make_item_ent_useable( self.item_ent, get_item_desc( item_ref ) );
		self.use_ent = self.item_ent;
	}
	else
	{
		self.use_ent = spawn( "trigger_radius", item_ent.origin, 0, 32, 32 );
	}
	
	if ( should_explode_on_damage ( item_ref ) )
		self.item_ent thread explodeOnDamage( false );
	
	self notify ( "spawned" );
	
/#  // debug
	if ( getdvarint( "debug_collectibles" ) == 1 )
		maps\mp\alien\_debug::debug_collectible( self );
#/
	if ( alien_mode_has( "outline" ) )
	{
		if ( GetSubStr( item_ref, 0, 6 ) == "weapon" )
		{
			maps\mp\alien\_outline_proto::add_to_outline_weapon_watch_list ( item_ent, self.data[ "cost" ] );
		}
		else
		{
			maps\mp\alien\_outline_proto::add_to_outline_watch_list ( item_ent, self.data[ "cost" ] );
		}
	}
}

get_world_item_spawn_pos( dropToGround )
{
	VERTICAL_OFFSET = ( 0, 0, 16 );
	
	if ( dropToGround )
		return ( drop_to_ground( self.origin, DROP_TO_GROUND_UP_DIST, DROP_TO_GROUND_DOWN_DIST ) + VERTICAL_OFFSET );
	else
		return self.origin;
}

make_item_ent_useable( item_ent, hintString )
{
	item_ent SetCursorHint( "HINT_NOICON" );
	item_ent SetHintString( hintString );
	item_ent MakeUsable();
}

should_explode_on_damage ( item_ref )
{
	switch ( item_ref )
	{
	case "item_alienpropanetank_mp":
		return true;
	default:
		return false;
	}
}

spawn_item()
{
	spawn_world_item( false, true );
}

spawn_loot( item_owner )
{
	spawn_world_item( true, false );
	
	self.item_ent.loot_owner = item_owner;
	level.collectibles_lootcount++;
	
	self thread loot_collection_timeout();
	// self thread item_fx();
}

loot_collection_timeout()
{
	self endon( "death" );
	self endon( "deleted" );

	self.loot_collection_timeout = 5;	// time out in seconds
	
	while ( self.loot_collection_timeout )
	{
		wait 1;
		self.loot_collection_timeout--;
	}
}


clear_item_pickup()
{
	self endon( "disconnect" );
	wait ( 1 );
	self.picking_up_item = false;	
}

// item_pickup_listener( touch pickup )
item_pickup_listener()
{
	self endon( "death" );
	self endon( "timedout" );	// only by loot items
	level endon ( "game_ended" );
		
	while ( true )
	{
		self.use_ent waittill( "trigger", owner );
		
		owner notify ( "cancel_watch" ); //cancel dpad listener
		owner notify( "kill_spendhint"); //kill the potential hint for throwing a deployable
		
		owner.picking_up_item = true;
		owner thread clear_item_pickup();		

		if ( owner [[ get_func_cangive( self.item_ref ) ]]( self ) )
		{
			// TODO: get new sound for MP
			//IPrintLnBold( self.item_ref );
			switch ( self.item_ref )
			{
			case "item_alienpropanetank_mp":
				//IPrintLnBold( "alien case" );
				owner playLocalSound( "weap_pickup_propanetank_plr" );
				break;
			default:
				//IPrintLnBold( "default case" );
				owner PlayLocalSound( "extinction_item_pickup" );
			}
			
			owner [[ get_func_give( self.item_ref ) ]]( self );
			
			self.data[ "last_collector" ] = owner;
			self.data[ "times_collected" ]++;
			level.collectibles_worldcount[ self.item_ref ]++;
			owner notify( "loot_pickup", self );
		}
		else
		{
			// failed to give
			wait 0.05;
			continue;
		}
		
		if ( self.data[ "persist" ] > 0 )
		{
			continue;
		}
		else
		{
			self remove_world_item();
	
			// if respawns for finite times
			if ( self.data[ "respawn_count" ] <= 0 )
			{
				return;
			}
			
			// wait for respawn
			//wait level.collectibles[ self.item_ref ].respawn;
			
			level waittill( "alien_cycle_ended" );
			
			self.data[ "respawn_count" ]--;
			// Disabling respawning
			//spawn_random_item( false, self.item_ref );
		}
		// end, no loop
		return;
	}
}

// touch or use
loot_pickup_listener( item_owner, touch )
{
	self endon( "death" );
	self endon( "timedout" );	// only by loot items
	level endon ( "game_ended" );
	
	isLoot = is_collectible_loot( self.item_ref );
	
	if( !isdefined( touch ) )
		touch = false;
	
	// if not touch based, we apply press (X) use based
	if ( !touch )
	{	
		make_item_ent_useable( self.item_ent, get_item_desc( self.item_ref ) );		
	}
	
	while ( true )
	{
		self.use_ent waittill( "trigger", owner );
		
		if ( !isdefined( owner ) || !isplayer( owner ) )
		{
			wait 0.05;
			continue;
		}
		
		if ( owner [[ get_func_cangive( self.item_ref ) ]]( self ) )
		{
			// TODO: get new sound for MP
			owner PlayLocalSound( "extinction_item_pickup" );

			owner thread [[ get_func_give( self.item_ref ) ]]( self );
			owner notify( "loot_pickup", self );
		}
		else
		{
			// failed to give
			wait 0.05;
			continue;
		}
		
		/#
			if ( getdvarint( "debug_collectibles" ) == 1
			    && isLoot
			    && isdefined( item_owner )
			    && item_owner != owner
			    && isplayer( item_owner )
			    && isplayer( owner ) )
			{
				IPrintLn( owner.name + " took " + item_owner.name + "'s loot [" + self.item_ref + "]" );
			}
		#/

		if ( self.data[ "persist" ] > 0 )
		{
			continue;
		}
		else
		{
			self remove_loot();
		}
		return;
	}
}

// removes loot if not picked up in time
loot_pickup_timeout( owner, loot_timeout )
{
	self endon( "death" );
	level endon ( "game_ended" );

	countdown = loot_timeout;
	while ( countdown )
	{
		wait 1;
		countdown--;
	}
	
	/#
		if ( getdvarint( "debug_collectibles" ) == 1 )
		{
			player_name = "unknown player";
			if ( isdefined( owner ) && isplayer( owner ) && isdefined( owner.name ) )
				player_name = owner.name;
			
			iprintln( player_name + "'s loot [" + self.item_ref + "] timed out" );
		}
	#/
	
	if ( self.data[ "persist" ] > 0 )
	{
		self notify( "timedout" );
		self remove_world_item();
	}
}

// remove loot, world model, and touch trigger
remove_loot()
{
	remove_world_item();
	level.collectibles_lootcount--;
}

remove_world_item()
{
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::remove_from_outline_watch_list ( self.item_ent );
	
	self.item_ent delete();
	
	if ( isdefined( self.use_ent ) )  // use_ent could be different from item_ent
		self.use_ent delete();
}

item_min_distance_from_players()
{
	return !any_player_nearby( self.origin, ITEM_MIN_SPAWN_DISTANCE_SQR );
}

is_item( ref )
{
	return IsSubStr( ref, "item" );
}


collectibles_table_init( index_start, index_end )
{
	// populate table
	for ( i = index_start; i < index_end; i++ )
	{
		ref = TableLookup( level.alien_collectibles_table, TABLE_ITEM_INDEX, i, TABLE_ITEM_REF );
		if ( ref == "" )
			break;
		
		item				= SpawnStruct();
		item.index			= i;
		item.ref			= ref;
		item.model			= TableLookup( level.alien_collectibles_table, TABLE_ITEM_INDEX, i, TABLE_ITEM_MODEL );
		item.name			= TableLookup( level.alien_collectibles_table, TABLE_ITEM_INDEX, i, TABLE_ITEM_NAME );
		item.desc			= TableLookup( level.alien_collectibles_table, TABLE_ITEM_INDEX, i, TABLE_ITEM_DESC );
		
		item.count			= int( TableLookup( level.alien_collectibles_table, 	TABLE_ITEM_INDEX, i, TABLE_ITEM_COUNT ) );
		item.ownership 		= TableLookup( level.alien_collectibles_table, 			TABLE_ITEM_INDEX, i, TABLE_ITEM_OWNERSHIP );
		item.respawn		= float( TableLookup( level.alien_collectibles_table, 	TABLE_ITEM_INDEX, i, TABLE_ITEM_RESPAWN ) );
		item.respawn_max	= int( TableLookup( level.alien_collectibles_table, 	TABLE_ITEM_INDEX, i, TABLE_ITEM_RESPAWN_MAX ) );
		item.vis			= int( TableLookup( level.alien_collectibles_table, 	TABLE_ITEM_INDEX, i, TABLE_ITEM_VIS ) );
		item.unlock			= int( TableLookup( level.alien_collectibles_table, 	TABLE_ITEM_INDEX, i, TABLE_ITEM_UNLOCK ) );
		item.player_max		= int( TableLookup( level.alien_collectibles_table, 	TABLE_ITEM_INDEX, i, TABLE_ITEM_PLAYER_MAX ) );
		item.persist		= int( TableLookup( level.alien_collectibles_table, TABLE_ITEM_INDEX, i, TABLE_ITEM_PERSIST ) );
		item.cost			= int( TableLookup( level.alien_collectibles_table, TABLE_ITEM_INDEX, i, TABLE_ITEM_COST ) );
		item.cost_display	= TableLookup( level.alien_collectibles_table, TABLE_ITEM_INDEX, i, TABLE_ITEM_COST );
		item.func_give		= get_func_give( item.ref );
		item.func_cangive	= get_func_cangive( item.ref );
		
		item.isLoot			= is_collectible_loot( item.ref );
		item.isWeapon		= is_collectible_weapon( item.ref );
		item.isItem			= is_collectible_item( item.ref );
		
		if ( is_chaos_mode() )
			item.cost = 0;
		
		// data structs, not world item structs
		level.collectibles[ item.ref ] = item;
	}
}

is_collectible_loot( item_ref )
{
	if ( isdefined( level.collectibles ) 
	    && isdefined( level.collectibles[ item_ref ] ) 
	    && isdefined( level.collectibles[ item_ref ].isLoot ) 
	)
	{
		return level.collectibles[ item_ref ].isLoot;		
	}
	else
	{
		return ( GetSubStr( item_ref, 0, 5 ) == "loot_" );
	}
}

is_collectible_weapon( item_ref )
{
	if ( isdefined( level.collectibles ) 
	    && isdefined( level.collectibles[ item_ref ] ) 
	    && isdefined( level.collectibles[ item_ref ].isWeapon ) 
	)
	{
		return level.collectibles[ item_ref ].isWeapon;		
	}
	else
	{
		return ( GetSubStr( item_ref, 0, 7 ) == "weapon_" );
	}
}

is_collectible_item( item_ref )
{
	if ( isdefined( level.collectibles ) 
	    && isdefined( level.collectibles[ item_ref ] ) 
	    && isdefined( level.collectibles[ item_ref ].isItem ) 
	)
	{
		return level.collectibles[ item_ref ].isItem;		
	}
	else
	{
		return ( GetSubStr( item_ref, 0, 5 ) == "item_" );
	}
}

item_exist( ref )
{
	return isdefined( level.collectibles[ ref ] );
}

get_item_desc( ref )
{
	return level.collectibles[ ref ].desc;
}

get_item_name( ref )
{
	return level.collectibles[ ref ].name;
}	

get_maxstock( ref )
{
	return level.collectibles[ ref ].player_max;
}

// ====================================
// 		give and cangive functions
// ====================================

give_default( item )
{
	return;	
}

cangive_default( item )
{
	return false;	
}

get_func_give( ref )
{
	AssertEx( IsDefined( ref ) && ref !="" , "The item ref name must be defined and not empty string." );
	
	if ( item_exist( ref ) )
		return level.collectibles[ ref ].func_give;

	func_give = ::give_default;
	
	switch ( ref )
	{

		case "item_alienpropanetank_mp":
			func_give = ::give_throwable_weapon;
			break;
		
			
		default:
			//AssertMsg( "Unhandled item: " + ref + " is looking for func_give" );
			break;
	}

	if ( strtok( ref, "_" )[ 0 ] == "weapon" )
	{
		func_give = ::give_weapon;
	}
	
	return func_give;
}

get_func_cangive( ref )
{	
	AssertEx( IsDefined( ref ) && ref !="" , "The item ref name must be defined and not empty string." );
	
	if ( item_exist( ref ) )
		return level.collectibles[ ref ].func_cangive;

	func_cangive = ::cangive_default;

	switch ( ref )
	{
			
		case "item_alienpropanetank_mp":
			func_cangive = ::cangive_throwable_weapon;
			break;

		default:
			//AssertMsg( "Unhandled item: " + ref + " is looking for func_give" );
			break;
	}
	
	if ( strtok( ref, "_" )[ 0 ] == "weapon" )
	{
		func_cangive = ::cangive_weapon;
	}
	
	return func_cangive;
}

// ====================================
// [weapons]
// ====================================
give_weapon( item, is_locker_weapon )
{
	should_take_weapon = undefined;
	ref = item.item_ref;
	weapon_ref = getsubstr( ref, 7 );	// to remove "weapon_"
	cost = item.data[ "cost" ];	
	
	if ( self perk_GetPistolOverkill() == false )
	{
		max_primaries = 2;
	}
	else
	{
		max_primaries = 3;
	}
	
	if ( isDefined( self.numAdditionalPrimaries ) ) //special primary weapnons that should not count towards max primaries
	{
		max_primaries += self.numAdditionalPrimaries;
	}
	
	base_weapon = getRawBaseWeaponName( weapon_ref );
	has_special_ammo = self player_has_specialized_ammo( base_weapon );
	current_attachments = [];
	
	if( !self has_weapon_variation( weapon_ref ) && !self has_pistols_only_relic_and_no_deployables() )
	{
		cur_primary_weapon 	= self get_replaceable_weapon();
		
		if ( IsDefined( cur_primary_weapon ) )
		{
			cur_primary_clip 	= self GetWeaponAmmoClip( cur_primary_weapon );
			cur_primary_stock 	= self GetWeaponAmmoStock( cur_primary_weapon );
			should_take_weapon = true;
			//Take current weapon from player
			if ( is_chaos_mode() )
			{
				replaceable_weapon = cur_primary_weapon;
				self TakeWeapon( replaceable_weapon );
			}
										
			if ( !self.hasRiotShieldequipped && cur_primary_weapon != "aliensoflam_mp"  )
			{
				if ( ( self hasweapon( "aliensoflam_mp" ) || self.hasRiotShield || self has_special_weapon() ) && self GetWeaponsListPrimaries().size < (max_primaries + 1 ) )
				{
					should_take_weapon = false;
				}

				if ( self hasweapon( "aliensoflam_mp" ) && self.hasRiotshield && self GetWeaponsListPrimaries().size < (max_primaries + 2 ) )
				{
					should_take_weapon = false;
				}
				
				if ( isDefined( level.custom_give_weapon_func ) )
				{
					should_take_weapon_test = [[level.custom_give_weapon_func]]( max_primaries );
					if ( isDefined( should_take_weapon_test ) )
						should_take_weapon = should_take_weapon_test;						
				}
				
				if ( should_take_weapon )
				{
					self TakeWeapon( cur_primary_weapon );
				}
			}
		}

		if( isDefined( cur_primary_weapon) && getWeaponClass( cur_primary_weapon ) != "weapon_pistol" && should_take_weapon == true )
			current_attachments = GetWeaponAttachments( cur_primary_weapon );
		// cost the purchaser
		self take_player_currency( cost, false, "weapon", weapon_ref );

		if ( is_chaos_mode() )
			maps\mp\alien\_chaos::update_weapon_pickup( self, weapon_ref );
		else if(!is_true(is_locker_weapon) && isDefined( cur_primary_weapon ) )
			weapon_ref = self return_weapon_with_like_attachments( weapon_ref, current_attachments );
		else if( is_true(is_locker_weapon) )
			weapon_ref = self ark_attachment_transfer_to_locker_weapon( weapon_ref, current_attachments, should_take_weapon );
		
		self giveweapon( weapon_ref );
		self SwitchToWeapon( weapon_ref );
		if ( !is_true( is_locker_weapon ) )
			self scale_ammo_based_on_nerf( weapon_ref );
		self give_pistol_ammo_if_nerf_active();		
		level notify( "new_weapon_purchased",self );
	}
	else
	{
		if ( !self HasWeapon ( weapon_ref ) ) // player has a variation of this weapon
			weapon_ref = get_weapon_ref ( weapon_ref );
		
		if ( self has_pistols_only_relic_and_no_deployables() )
			weapon_ref = get_current_pistol();		
		
		assert ( isDefined ( weapon_ref ) );
		
		max_ammo = WeaponMaxAmmo( weapon_ref );
		limited_ammo_scalar = self maps\mp\alien\_prestige::prestige_getMinAmmo();
		scaled_ammo = int( limited_ammo_scalar * max_ammo);
		current_ammo = self GetAmmoCount( weapon_ref );
		
		if ( current_ammo < scaled_ammo )
		{
			if ( has_special_ammo )
				return;
			self GiveMaxAmmo( weapon_ref );
			self SwitchToWeapon( weapon_ref );
			self SetWeaponAmmoStock( weapon_ref, scaled_ammo );	
			
			if ( !self has_pistols_only_relic_and_no_deployables() )
			{
				self give_pistol_ammo_if_nerf_active();
			}
			else
			{
				cost = level.pistol_ammo_cost;
			}
			self clearLowerMessage ( "ammo_warn" );
			self setLowerMessage( "ammo_taken",&"ALIEN_COLLECTIBLES_DEPLOYABLE_AMMO_TAKEN",3 );
				// cost the purchaser
			self take_player_currency( cost, false, "weapon", weapon_ref );
			
		}
		else 
		{
			if ( !has_special_ammo )
			{
				self clearLowerMessage ( "ammo_warn" );
				self setLowerMessage( "ammo_taken",&"ALIEN_COLLECTIBLES_AMMO_MAX",3 );
			}
		}
	}
}

scale_ammo_based_on_nerf( weapon_ref )
{
	//checks the nerf for min_ammo and returns the amount
	nerf_min_ammo_scalar = self maps\mp\alien\_deployablebox_functions::check_for_nerf_min_ammo();	
	if ( nerf_min_ammo_scalar != 1.0 )
	{
		max_stock = WeaponMaxAmmo( weapon_ref );
		self SetWeaponAmmoStock( weapon_ref, int( max_stock * nerf_min_ammo_scalar ) );	
	}
}

give_pistol_ammo_if_nerf_active( )
{
	//give .25 of max ammo to pistols since the player cant throw ammo crates down with this nerf
	if ( self maps\mp\alien\_prestige::prestige_getNoDeployables() == 1 )
	{
		weap_list = self GetWeaponsListPrimaries();
		foreach ( weap in weap_list )
		{
			weap_class = getWeaponClass( weap );
			if ( weap_class == "weapon_pistol" )
			{
				max_stock = WeaponMaxAmmo( weap );
				scaled_ammo = int( max_stock * 0.25 );
				cur_ammo = self GetAmmoCount( weap );
				if ( scaled_ammo > cur_ammo )
					self SetWeaponAmmoStock( weap, scaled_ammo );	//give .25 of max ammo to pistols since the player cant throw ammo crates down with this nerf
			}
		}
	}
}

get_replaceable_weapon()
{
	// if holding more than one weapon remove the current
	primary_weapons = self GetWeaponsListPrimaries();
	
	if ( is_chaos_mode() )
	{
		foreach ( weapon in primary_weapons )
		{
			weap_class = getWeaponClass( weapon );
			switch ( weap_class ) 
			{
				case "weapon_smg":
				case "weapon_assault":
				case "weapon_sniper":
				case "weapon_dmr":
				case "weapon_lmg":
				case "weapon_shotgun":
				case "weapon_projectile":
					return ( weapon );
			}
		}
	}
	
	if ( self perk_GetPistolOverkill() == false )
	{
		max_primaries = 2;
	}
	else
	{
		max_primaries = 3;
	}
	
	if ( isDefined( self.numAdditionalPrimaries ) ) //special primary weapnons that should not count towards max primaries
	{
		max_primaries += self.numAdditionalPrimaries;
	}
	
	if ( primary_weapons.size >= max_primaries )
	{
		current_weapon = self GetCurrentWeapon();
		if ( WeaponInventoryType( current_weapon ) == "altmode" )
		{
			current_weapon = get_weapon_name_from_alt( current_weapon ); 
		}
		// if current weapon held is a weapon that can be taken away
		if ( IsDefined( current_weapon ) && WeaponInventoryType( current_weapon ) == "primary" )
		{
			return current_weapon;
		}
		else
		{
			// find a primary weapon to take away
			weapon_list = self GetWeaponsList( "primary" );
			foreach ( weapon in weapon_list )
			{
				if ( WeaponClass( weapon ) != "item" && WeaponClass( weapon ) != "pistol" && WeaponType( weapon ) != "riotshield" ) 
					return weapon;
			}
		}
	}
	return undefined;
}

get_weapon_name_from_alt( weapon )
{
	if ( WeaponInventoryType( weapon ) != "altmode" )
	{
		assertmsg( "Get weapon name from alt called on non alt weapon." );
		return weapon;
	}
	
	// Assume alt weapon names are always in the format
	// of: "alt_iw5_scar_mp_m230"
	return GetSubStr( weapon, 4 );
}

cangive_weapon( item )
{
	ref = item.item_ref;	
	weapon_ref = getsubstr( ref, 7 );	// to remove "weapon_"
	
	cur_weapons = self GetWeaponsListPrimaries();
	currentweapon = self GetCurrentWeapon();
	currentweapon_class = self getWeaponClass( currentweapon );
	
	if ( is_chaos_mode() )
	{
		if ( maps\mp\alien\_chaos::is_weapon_recently_picked_up( self, weapon_ref ) || self has_special_weapon() )
		{
			self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
			return false;
		}
		else
			return true;
	}
		    
	//check for the pistol perk that allows 3 main weapons
	if (  self perk_GetPistolOverkill() == false )
	{
		max_primaries = 2;
	}
	else
	{
		max_primaries = 3;
	}
	
	if ( isDefined( self.numAdditionalPrimaries ) )
	{
		max_primaries += self.numAdditionalPrimaries;
	}
	
	//Begin Checks to allow weapons to be purchased
	if ( self  maps\mp\alien\_prestige::prestige_getPistolsOnly() == 1 )
	{
		if ( self  maps\mp\alien\_prestige::prestige_getNoDeployables() != 1 )
		{
			self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_NERFED", 3 );
			return false;
		}	
	}
	
	if ( self IsSwitchingWeapon() )
	{
		return false;
	}
	
	if ( currentweapon == "none"  ) //you should never be able to buy a weapon ( or anything ) when your current weapon is "none" 
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HOLDING", 3 );
		return false;
	}
	
	if ( isDefined ( level.custom_cangive_weapon_func ) )
	{
		if ( ![[level.custom_cangive_weapon_func]]( cur_weapons, currentweapon, currentweapon_class, max_primaries ) )
		{
			self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
			return false;
		}
	}
	
	
	if ( self has_special_weapon() )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}
	
	if ( currentweapon_class == "weapon_pistol" && cur_weapons.size >= max_primaries && !self.hasRiotShield && !self HasWeapon( "aliensoflam_mp" ) )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}
	
	if ( currentweapon_class == "weapon_pistol" && cur_weapons.size >= ( max_primaries + 1 ) && self.hasRiotShield && !self HasWeapon( "aliensoflam_mp" ) )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}
	
	if ( currentweapon_class == "weapon_pistol" && cur_weapons.size >= ( max_primaries + 1 ) && self hasweapon ( "aliensoflam_mp" ) && !self.hasRiotShield )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}
	
	if ( currentweapon_class == "weapon_pistol" && cur_weapons.size >= ( max_primaries + 2 ) && self.hasRiotShield && self HasWeapon( "aliensoflam_mp" ) )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}
	
	if ( currentweapon == "aliensoflam_mp" && cur_weapons.size >= ( max_primaries + 1 ) && !self.hasRiotShieldEquipped  )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}
		
	if ( currentweapon == "aliensoflam_mp" && cur_weapons.size >= ( max_primaries + 2 ) && self.hasRiotShieldEquipped  )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}
	
	if ( self.hasRiotShieldEquipped && cur_weapons.size >= ( max_primaries + 1 ) && !self HasWeapon( "aliensoflam_mp" ) )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}
	
	if ( self.hasRiotShieldEquipped && cur_weapons.size >= ( max_primaries + 1 ) && self HasWeapon( "aliensoflam_mp" ) )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HAS_SPECIALWEAPON", 3 );
		return false;
	}

	if  ( !self is_holding_deployable() )
	{
		if ( self has_pistols_only_relic_and_no_deployables() )
			has_enough = player_has_enough_currency( level.pistol_ammo_cost );
		else
			has_enough = player_has_enough_currency( item.data[ "cost" ] );
		
		if ( !has_enough )
		{
			self clearLowerMessage ( "ammo_warn" );
			self setLowerMessage( "no_money", &"ALIEN_COLLECTIBLES_NO_MONEY", 3 );
			return false;
		}
		return true;
	}
	else
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HOLDING", 3 );
		return false;
	}
	
	return false;
}

give_throwable_weapon( item )
{
	ref = item.item_ref;	
	item_ref = getsubstr( ref, 5 );	// to remove "item_"
	
	self _giveWeapon( item_ref );
	self SwitchToWeapon( item_ref );
	self DisableWeaponSwitch();
	self displayThrowMessage();
}

cangive_throwable_weapon( item )
{
	ref = item.item_ref;	
	weapon_ref = getsubstr( ref, 5 );	// to remove "item_"
	
	if ( self isChangingWeapon() ||  self is_holding_deployable() || self has_special_weapon() || self GetCurrentPrimaryWeapon() == "aliensoflam_mp" )
	{
		self setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HOLDING", 3 );
		return false;
	}
	if( !self HasWeapon( weapon_ref ) && !self is_holding_deployable() && !self has_special_weapon() )
	{
		return true;
	}
	else
	{
		return false;
	}
}


//==================================================================================
// 							PROPANE TANK WEAPON
//==================================================================================

watchThrowableItems()  //self = player
{
	level endon( "game_ended" );
	self endon( "death" );
	self endon( "disconnect" );
	
	itemTeam = self.pers["team"];
	
	while ( 1 )
	{
		self waittill( "grenade_fire",throwableitem, weapname );
		if ( isGrenade ( weapname ) )
			continue;

		forward_direction = anglesToForward( self getPlayerAngles() );
		spawnPos = bulletTrace( self geteye(), self geteye() + forward_direction * 64, true, self,false,false,true );
		
		spawnPos["position"] = self geteye() + forward_direction * 30;
		if ( spawnPos["fraction"] < 1 )
		{
			if ( weapname == "alienpropanetank_mp" )
			{
				spawnPos["position"] = self geteye() + forward_direction;
			}
		}
		if ( isThrowableItem( weapname ) )
		{
			self TakeWeapon( weapname );
			self EnableWeaponSwitch();
			throwableitem delete();			
			level thread watchThrowableItemStopped( weapname, itemTeam, self getEye(), self getPlayerAngles(), self , spawnPos );
		}
	}
}

watchThrowableItemStopped( weapname, itemTeam, playerEye, playerAngles, owner , spawnPos )
{
	level endon( "game_ended" );
	
	waitframe();  // wait for the grenade item to be deleted
	
	item_data = level.throwable_items[ weapname ];
	
	forward_direction = anglesToForward( playerAngles );
	spawnAngles = anglesToUp( playerAngles );   // temp. This is for the propane to fly out sideway. Need an university method
	
	physics_model = spawn( "script_model", spawnPos["position"] );
	physics_model.angles = vectorToAngles( spawnAngles );
	physics_model setmodel( item_data.model );
	physics_model.owner = owner;
	
	physics_model endon( "death" );
	
	add_to_thrown_entity_list( physics_model );
	physics_model thread clean_up_on_death();
	
	waitframe();  // wait for the angles to be set before applying physics
	
	force = item_data.force ;
	if ( spawnPos["fraction"] < 1 )
		force = 5;
	
	physics_model PhysicsLaunchServer( ( 0,0,0 ), forward_direction * force );

	wait ( 0.5 );  // There is no good notify to wait for.  "physics_finished" is too late.
	
	physics_model thread explodeOnDamage( true );
	
	if ( item_data.canBePickedUp )
	{
		make_item_ent_useable( physics_model, item_data.hintString );
		physics_model thread [[item_data.pickUpFunc]]( weapname );
	}
		
	//blow up if too close to an IMS - stupid hacks
	if ( !isDefined( level.placedIMS ) || level.placedIMS.size < 1 )
		return;
	
	distcheck = 24*24; // 24 unit check
	foreach ( ims in level.placedIMS )
	{
		if ( DistanceSquared( physics_model.origin, ims.origin ) < distcheck )
			physics_model notify( "damage", 100, physics_model.owner );
	}
}

add_to_thrown_entity_list( item )
{
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::add_to_outline_watch_list ( item, 0 );
	
	level.thrown_entities[ level.thrown_entities.size ] = item;
}

clean_up_on_death()
{
	level endon( "game_ended" );
	self waittill( "death" );
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::remove_from_outline_watch_list ( self );
	
	level.thrown_entities = array_remove( level.thrown_entities, self );
}

propaneTankWatchUse( weapname )
{
	level endon( "game_ended" );
	self endon( "death" );
	
	while ( true )
	{
		self waittill ( "trigger", player );
		
		player notify( "cancel_watch" );  //cancel dpad listener
		player notify( "kill_spendhint"); //kill the potential hint for throwing a deployable
		player.picking_up_item = true;
		player thread clear_item_pickup();
		
		if ( !isPlayer ( player ) || player hasweapon( weapname ) )
		{
			continue;
		}
		if ( player is_holding_deployable() || player has_special_weapon() )
		{
			player setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HOLDING", 3 );
			continue;
		}
		
		if ( player isChangingWeapon() ||  player GetCurrentPrimaryWeapon() == "aliensoflam_mp"  )
		{
			player setLowerMessage( "cant_buy", &"ALIEN_COLLECTIBLES_PLAYER_HOLDING", 3 );
			continue;
		}
		
		break;
	}
	
	player playLocalSound( "weap_pickup_propanetank_plr" );
	player _giveWeapon( weapname );
	player SwitchToWeapon( weapname );
	player DisableWeaponSwitch();
	player displayThrowMessage();
	self delete();
}

isThrowableItem( weaponName )
{
	return isDefined( level.throwable_items[ weaponName ] );
}

displayThrowMessage()
{
	self setLowerMessage( "throw_item", &"ALIEN_COLLECTIBLES_THROW_ITEM", 3 );
}

explodeOnDamage( should_explode_on_hive_explode )
{
	self endon( "death" );

	self setcandamage( true );
	self.maxhealth = 100000;
	self.health = self.maxhealth;
	
	hive_exploded_propane = false;
	while ( true )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon );
		
		if ( should_explode_on_hive_explode && is_hive_explosion( attacker, type ) )
		{
			hive_exploded_propane = true;
			break;
		}
		
		if ( !isPlayer ( attacker )  && !isplayer ( attacker.owner  ) )
			continue;
		
		if ( isDefined ( type ) && type == "MOD_MELEE" )
			continue;
	
		break;
	}

	if ( isDefined( attacker ) && isPlayer( attacker ) )
	    self.owner = attacker;
	else if ( isDefined( attacker.owner ) && isPlayer( attacker.owner ) ) //for grenade turrets
		self.owner = attacker.owner;

	if ( isdefined( level.recent_propane_explosions ) && level.recent_propane_explosions > 4 )
		PlayFx( level._effect[ "Propane_explosion_cheapest" ], drop_to_ground( self.origin, DROP_TO_GROUND_UP_DIST, DROP_TO_GROUND_PROPANE_TANK_DOWN_DIST ) );
	else if ( isdefined( level.recent_propane_explosions ) && level.recent_propane_explosions > 2 )
		PlayFx( level._effect[ "Propane_explosion_cheap" ], drop_to_ground( self.origin, DROP_TO_GROUND_UP_DIST, DROP_TO_GROUND_PROPANE_TANK_DOWN_DIST ) );
	else
		PlayFx( level._effect[ "Propane_explosion" ], drop_to_ground( self.origin, DROP_TO_GROUND_UP_DIST, DROP_TO_GROUND_PROPANE_TANK_DOWN_DIST ) );
	
	
	max_damage = 1000 * self.owner perk_GetTrapDamageScalar();
	min_damage = 1000 * self.owner perk_GetTrapDamageScalar();
	
	// rasing the damage origin so the propane tank model isn't blocking the damage it gives, propane model height is 21 units
	damage_origin = self.origin + ( 0, 0, 22 );
	damage_radius = 256;
	
	if ( hive_exploded_propane )
		RadiusDamage( damage_origin, damage_radius, max_damage, min_damage, attacker, "MOD_EXPLOSIVE", "alienpropanetank_mp" );
	else
		RadiusDamage( damage_origin, damage_radius, max_damage, min_damage, self.owner, "MOD_EXPLOSIVE", "alienpropanetank_mp" );
	
	self Playsound( "grenade_explode_metal" );
	
	level thread fireCloudMonitor( self.owner, level.fireCloudDuration, self.origin );
	
	level thread firecloudsfx( level.fireCloudDuration, self.origin );
	
	if ( alien_mode_has( "outline" ) )
		maps\mp\alien\_outline_proto::remove_from_outline_watch_list ( self );
	
	self delete();
}

is_hive_explosion( attacker, type )
{
	if ( !isDefined( attacker ) || !isDefined( attacker.classname ) )
		return false;
	
	return ( attacker.classname == "scriptable" && type == "MOD_EXPLOSIVE" );
}

firecloudsfx( duration, position )
{
	soundorg1 = spawn( "script_origin", position );
	soundorg2 = spawn( "script_origin", position );
	wait 0.01;
	soundorg1 PlayLoopSound( "fire_trap_fire_lp" );
	wait duration;
	soundorg2 playsound( "fire_trap_fire_end_lp" );
	wait 0.5;
	soundorg1 stoploopsound();
	wait 5;
	soundorg1 delete();
	soundorg2 delete();
}

fireCloudMonitor( attacker, duration, position )
{
	fireCloudRadius 			= level.fireCloudRadius;
	fireCloudHeight 			= level.fireCloudHeight;
	fireCloudTickDamage 		= level.fireCloudTickDamage * ( attacker full_damage_scaler() );
	fireCloudLingerTime			= level.fireCloudLingerTime;
	fireCloudPlayerTickDamage 	= level.fireCloudPlayerTickDamage;
	fireCloudHiveTickDamage 	= level.fireCloudHiveTickDamage * ( attacker full_damage_scaler() );
	
	// ==== init for tracking recent propane explosions  ====
	if ( !isdefined( level.recent_propane_explosions ) )
		level.recent_propane_explosions = 0;
	// add this to recent propane tank explosions
	level.recent_propane_explosions++;
	
	// spawn trigger radius for the effect areas
	fireEffectArea = spawn( "trigger_radius", position, 0, fireCloudRadius, fireCloudHeight );
	fireEffectArea.owner = attacker;

	gasFire = SpawnFx( level._effect[ "Fire_Cloud" ], position );
	triggerFx( gasFire );
	
	fireTotalTime 	= 0.0;		// keeps track of the total time the fire cloud has been "alive"
	fireTickTime 	= 0.25;		// sampling rate
	fireInitialWait = 1;		// wait this long before the cloud starts ticking for damage
	fireTickCounter = 0;		// just an internal counter to count fire damage ticks
	
	wait(fireInitialWait );
	fireTotalTime +=fireInitialWait;
	
	duration = duration * ( attacker perk_GetTrapDurationScalar() );
	level thread maps\mp\alien\_utility::mark_dangerous_nodes( position, fireCloudRadius, duration );

	while ( fireTotalTime < duration )
	{
		//apply damage to aliens in the fire cloud
		foreach ( agent in level.agentArray )
		{
			if ( IsDefined( agent.isActive ) 
			    && agent.isActive 
			    && isalive( agent ) 
			    && ( agent istouching( fireEffectArea ) ) 
			    && ( !isdefined( agent.burning ) || !agent.burning ) )
			{
				agent thread fire_cloud_burn_alien( fireCloudTickDamage, attacker, fireCloudLingerTime , fireEffectArea );
			}
		}
		
	    //apply damage to players in the fire cloud
	    // [IMPORTANT] Player's tick rate is 1 second fixed. Fixed due to excessive view kick of fast ticks
	    foreach ( player in level.players )
		{	
	    	if( isalive( player ) && player istouching( fireEffectArea ) && ( !isdefined( player.burning ) || !player.burning ) )
	    		player thread fire_cloud_burn_player( fireCloudPlayerTickDamage );
		}
	    
	    if ( isDefined( level.thrown_entities ) )
	    {
		    //apply damage to propane tanks in the fire cloud
		    foreach ( item in level.thrown_entities )
		    {
		    	if( isDefined( item ) && item istouching( fireEffectArea ) )
		    		item DoDamage ( fireCloudPlayerTickDamage, position, attacker );
		    }
	    }
	    
	    //apply damage to blocker hive
	    if ( isdefined( level.blocker_hives ) )
	    {
			foreach ( blocker_hive in level.blocker_hives )
			{
				blocker_hive_struct = maps\mp\alien\_spawnlogic::get_blocker_hive( blocker_hive );
				if ( !isdefined( blocker_hive_struct ) )
					continue;
				
				attackable_ent = blocker_hive_struct.attackable_ent;
				if( isDefined( attackable_ent ) && distance( attackable_ent.origin, position ) <= fireCloudRadius * 0.8 )
		    	{
					if ( IsDefined( attackable_ent.health ) && attackable_ent.health > 0 && ( !isdefined( attackable_ent.burn_mitigation ) || !attackable_ent.burn_mitigation ) )
		    		{
		    			attackable_ent thread burn_mitigation( 0.2 );
		    			attackable_ent DoDamage ( fireCloudHiveTickDamage, position, attacker );
		    		}
		    	}
			}
	    }
	    
		wait( fireTickTime );
		fireTotalTime += fireTickTime;
		fireTickCounter += 1;
	}
	
	// clear this from recent propane tank explosions
	level.recent_propane_explosions = int( max( 0, level.recent_propane_explosions - 1 ) ); // remove
	
	//clean up
	fireEffectArea delete();
	gasfire delete();
}

burn_mitigation( duration )
{
	self notify( "burn_mitigating" );
	self endon( "burn_mitigating" );
	
	self endon( "death" );
	self.burn_mitigation = true;
	wait duration;
	self.burn_mitigation = false;
}

full_damage_scaler()
{
	// self is player
	return ( self perk_GetTrapDamageScalar() ) * level.alien_health_per_player_scalar[ level.players.size ];
}

// tick is forced as 1 second interval to prevent spam of small damages
fire_cloud_burn_player( tick_damage )
{
	// self is victim player
	
	// only one instance of burn
	self notify( "fire_cloud_burning" );
	self endon( "fire_cloud_burning" );
	self endon( "last_stand" );
	
	self.burning = true;
	self thread reset_burn_on_death();

	if( !self maps\mp\alien\_perk_utility::has_perk( "perk_rigger", [ 0,1,2,3,4 ] ) )
		self DoDamage( tick_damage, self.origin );
	wait 1;
	self.burning = undefined;
}

fire_cloud_burn_alien( interval_damage, attacker, duration, fire_damage_trigger )
{
	// self is victim alien
	
	// only one instance of burn
	self notify( "fire_cloud_burning" );
	self endon( "fire_cloud_burning" );
	self endon( "death" );
	
	if ( !isdefined( duration ) )
		duration = 6;
	
	self.burning = true;
	self thread reset_burn_on_death();
	
	self maps\mp\alien\_alien_fx::alien_fire_on();
	
	elapsed_time = 0;
	while ( elapsed_time < duration )
	{
		// create marker for passing in damage type
		attacker.burning_victim = true;

		if ( isDefined ( fire_damage_trigger ) ) //in case the damage trigger gets deleted during this while loop
			self DoDamage( interval_damage, self.origin, attacker, fire_damage_trigger );
		else
			self DoDamage( interval_damage, self.origin, attacker );
		
		elapsed_time += 1;
		wait 1;
	}
	
	self maps\mp\alien\_alien_fx::alien_fire_off();
	
	self.burning = undefined;
}

reset_burn_on_death()
{
	self waittill_any( "death", "last_stand" );
	self.burning = undefined;
}


advance_to_next_area()
{
	current_area = get_current_area_name();
	remove_items_in_area( current_area );
	remove_thrown_entity_in_area( current_area );
	if ( isDefined( level.leave_area_func ) )
		[[level.leave_area_func]]( current_area );
	
	inc_current_area_index();
	next_area = get_current_area_name();
	spawn_items_in_area( next_area );
	if ( isDefined( level.enter_area_func ) )
		[[level.enter_area_func]]( next_area );
}

remove_thrown_entity_in_area( area )
{
	foreach( thrown_entity in level.thrown_entities )
	{
		entity_in_areas = thrown_entity get_item_areas();
		
		if ( array_contains( entity_in_areas, area ) )
		{
			level.thrown_entities = array_remove( level.thrown_entities, thrown_entity );
			if ( alien_mode_has( "outline" ) )
				maps\mp\alien\_outline_proto::remove_from_outline_watch_list ( thrown_entity );

			thrown_entity delete();
		}
	}
}

isGrenade( weapName )
{
	weapClass = weaponClass( weapName );
	weapType = weaponInventoryType( weapName );

	if ( weapClass != "grenade" )
		return false;
		
	if ( weapType != "offhand" )
		return false;
	
	return true;
}

has_weapon_variation( weapon_name )
{
	primaries = self GetWeaponsListPrimaries(); 
	
	foreach ( weapon in primaries )
	{
		baseweapon = get_base_weapon_name( weapon );
		if ( IsSubStr ( weapon_name,baseweapon ) )
		{
			return true;
		}
	}
	
	return false;
}

get_weapon_ref ( weapon_name )
{
	primaries = self GetWeaponsListPrimaries(); 
	
	foreach ( weapon in primaries )
	{
		baseweapon = get_base_weapon_name( weapon );
		if ( IsSubStr ( weapon_name,baseweapon ) )
		{
			return weapon;
		}
	}
	return undefined;
	
}

check_for_player_near_weapon()
{
	self endon( "disconnect" );
	check_distance = 145*145;
	
	while ( 1 )
	{
		if ( (isDefined ( self.inlaststand ) && self.inlaststand ) || isDefined ( self.usingRemote ) || is_true ( self.isCarrying ) )
		{
			wait ( .25 );
			continue;
		}
			
		foreach ( index, item in level.outline_weapon_watch_list )
		{
			if ( isDefined( item ) && distancesquared( item.origin, self.origin ) < check_distance  )
			{
				if ( !isDefined( item.targetname ) )
					self setLowerMessage( "ammo_warn",&"ALIENS_PRESTIGE_PISTOLS_ONLY_AMMO_DIST",undefined,10 );
				while( self player_should_see_ammo_message( item,check_distance,false ) )
				{
					wait ( .25 );
				}
			}
				self clearLowerMessage ( "ammo_warn" );	
		}
		wait 1;
	}
}
	
player_should_see_ammo_message( item ,check_distance, ignore_carrying_check )
{
	if ( distancesquared( item.origin, self.origin ) > check_distance )
		return false;	
	
	if ( self.inlaststand )
		return false;
	
	if ( isDefined ( self.usingRemote ) )
		return false;
	
	if ( is_true ( ignore_carrying_check ) )
		return true;
	else if ( is_true ( self.isCarrying ) )
		return false;
	
	return true;
}
