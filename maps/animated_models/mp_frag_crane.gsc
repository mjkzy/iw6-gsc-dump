#include common_scripts\utility;

#using_animtree( "animated_props" );
main()
{
	if( !isdefined ( level.anim_prop_models ) )
		level.anim_prop_models = [];
		
	model = "mp_frag_crane_anim";
	if ( isSP() )
	{
		level.anim_prop_models[ model ][ "idle" ] = %mp_frag_crane_sway;
	}
	else
		level.anim_prop_models[ model ][ "idle" ] = "mp_frag_crane_sway";
}
