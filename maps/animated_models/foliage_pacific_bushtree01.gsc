#include common_scripts\utility;

#using_animtree( "animated_props" );
main()
{
	if( !isdefined ( level.anim_prop_models ) )
		level.anim_prop_models = [];
		
	model = "foliage_pacific_bushtree01_animated";
	if ( isSp() )
	{
		level.anim_prop_models[ model ][ "sway" ] = %foliage_pacific_bushtree01_sway;
	}
	else
		level.anim_prop_models[ model ][ "sway" ] = "foliage_pacific_bushtree01_sway";
}
